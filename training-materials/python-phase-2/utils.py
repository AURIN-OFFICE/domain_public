"""
Shared utilities for the Domain API Phase 2 training notebooks.

Provides authentication, API call tracking, and spatial helper functions
used across all four notebooks. Import this module at the top of each
notebook after adding the phase-2 directory to sys.path.

Exports:
  PROXY_BASE    -- base URL for the AURIN proxy
  PROXY_AUTH    -- HTTPBasicAuth object built from .env credentials
  GET_HEADERS   -- headers for GET requests (no Content-Type)
  POST_HEADERS  -- headers for POST requests (includes Content-Type)
  APICallTracker -- class that wraps requests and counts calls
  probe_count   -- 1-credit density probe for the listings endpoint
  geojson_file_to_api_polygon  -- GeoJSON exterior ring to API polygon points
  geojson_bbox_to_api_box      -- GeoJSON bounding box to API geoWindow.box
  validate_australia_coords    -- pre-flight check that points fall within Australia
"""

import os
import json
import requests
from datetime import datetime
from pathlib import Path
from requests.auth import HTTPBasicAuth
from dotenv import load_dotenv

# Locate the project root .env two levels above this file:
# domain_api/training-materials/phase-2/utils.py -> domain_api/.env
_project_root = Path(__file__).resolve().parent.parent.parent
load_dotenv(dotenv_path=_project_root / ".env")

AURIN_USERNAME = os.getenv("AURIN_USERNAME")
AURIN_PASSWORD = os.getenv("AURIN_PASSWORD")
assert AURIN_USERNAME, "AURIN_USERNAME not found in .env"
assert AURIN_PASSWORD, "AURIN_PASSWORD not found in .env"

PROXY_BASE = "https://domain.api.aurin.org.au"
PROXY_AUTH = HTTPBasicAuth(AURIN_USERNAME, AURIN_PASSWORD)

# Keep GET and POST headers in separate dicts. The Domain API returns
# HTTP 200 with an empty body if a GET request carries Content-Type --
# the same silent symptom as querying a non-existent suburb name.
GET_HEADERS = {
    "accept": "application/json",
}
POST_HEADERS = {
    "accept": "application/json",
    "content-type": "application/json",
}


class APICallTracker:
    """Wraps requests.get and requests.post, logging every call made.

    Usage:
        tracker = APICallTracker()
        r = tracker.post(url, json_body={...})
        tracker.checkpoint("Section label")
        tracker.summary()
    """

    def __init__(self):
        self.log = []
        self._checkpoints = {}

    def _record(self, method, url, status_code, params=None, body=None):
        self.log.append({
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "method": method,
            "url": url,
            "params": params,
            "body": body,
            "status_code": status_code,
        })

    def get(self, url, params=None, **kwargs):
        r = requests.get(
            url, params=params, headers=GET_HEADERS, auth=PROXY_AUTH, **kwargs
        )
        self._record("GET", url, r.status_code, params=params)
        return r

    def post(self, url, json_body=None, **kwargs):
        r = requests.post(
            url, json=json_body, headers=POST_HEADERS, auth=PROXY_AUTH, **kwargs
        )
        self._record("POST", url, r.status_code, body=json_body)
        return r

    def checkpoint(self, label):
        """Record how many calls have been made up to this point."""
        self._checkpoints[label] = len(self.log)

    @property
    def total(self):
        return len(self.log)

    def summary(self):
        """Print a breakdown of calls consumed per checkpoint section."""
        print(f"\n{'=' * 62}")
        print(f"  TOTAL API CALLS: {self.total}")
        print(f"{'=' * 62}")
        prev = 0
        for label, cumulative in self._checkpoints.items():
            delta = cumulative - prev
            print(f"  {label:<42} {delta:>4} calls")
            prev = cumulative
        remaining = self.total - prev
        if remaining:
            print(f"  {'(unlabelled)':<42} {remaining:>4} calls")
        print(f"{'=' * 62}\n")


def probe_count(base_payload, tracker):
    """Send a 1-credit density probe to the listings search endpoint.

    Merges pageSize=1 and pageNumber=1 into base_payload, then reads
    X-Total-Count from the response header. Returns the integer count,
    or None on a non-200 response.

    Args:
        base_payload: dict with listingType and at least one of
                      locations, geoWindow.polygon, or geoWindow.box.
        tracker: APICallTracker instance used for the request.
    """
    probe = {**base_payload, "pageSize": 1, "pageNumber": 1}
    r = tracker.post(
        f"{PROXY_BASE}/v1/listings/residential/_search",
        json_body=probe,
    )
    if r.status_code == 200:
        return int(r.headers.get("X-Total-Count", 0))
    print(f"  Probe failed -- HTTP {r.status_code}: {r.text[:200]}")
    return None


def geojson_file_to_api_polygon(path):
    """Read a GeoJSON file and return the exterior ring as API polygon points.

    GeoJSON coordinates are [longitude, latitude]. The Domain API expects
    a list of {"lat": ..., "lon": ...} dicts. Only the exterior ring of
    the first feature is used; interior rings (holes) are ignored.

    Args:
        path: path to a .geojson file with a Polygon or MultiPolygon feature.

    Returns:
        list of {"lat": float, "lon": float} dicts.
    """
    with open(path) as f:
        gj = json.load(f)

    geom = gj["features"][0]["geometry"]

    if geom["type"] == "Polygon":
        ring = geom["coordinates"][0]
    elif geom["type"] == "MultiPolygon":
        # Pick the largest exterior ring (most points = mainland, not an island)
        ring = max((poly[0] for poly in geom["coordinates"]), key=len)
    else:
        raise ValueError(f"Unsupported geometry type: {geom['type']}")

    return [{"lat": lat, "lon": lon} for lon, lat in ring]


def geojson_bbox_to_api_box(path):
    """Read a GeoJSON file and return a Domain API geoWindow.box dict.

    Computes the bounding box across all coordinates in the first feature.

    Args:
        path: path to a .geojson file with a Polygon or MultiPolygon feature.

    Returns:
        dict with topLeft and bottomRight keys, ready to embed as the value
        of a "box" key inside a geoWindow payload dict.
    """
    with open(path) as f:
        gj = json.load(f)

    geom = gj["features"][0]["geometry"]

    if geom["type"] == "Polygon":
        all_coords = [c for ring in geom["coordinates"] for c in ring]
    elif geom["type"] == "MultiPolygon":
        all_coords = [
            c
            for polygon in geom["coordinates"]
            for ring in polygon
            for c in ring
        ]
    else:
        raise ValueError(f"Unsupported geometry type: {geom['type']}")

    lons = [c[0] for c in all_coords]
    lats = [c[1] for c in all_coords]

    return {
        "topLeft":     {"lat": max(lats), "lon": min(lons)},
        "bottomRight": {"lat": min(lats), "lon": max(lons)},
    }


def validate_australia_coords(points, label='coordinates'):
    """Check that API-format points [{lat, lon}, ...] fall within Australia's bounding box.

    Catches the most common mistake: sending GeoJSON [lon, lat] order directly to the
    API without swapping. Returns True if the coordinates look correct, False otherwise.

    Australia bounding box (approximate):
      lat: -44.0 (south Tasmania) to -10.0 (north Queensland)
      lon: 113.0 (west WA)        to 154.0 (east QLD)

    Args:
        points: list of {"lat": float, "lon": float} dicts (Domain API format).
        label:  optional string shown in the printed message (default 'coordinates').

    Returns:
        True if all points are within Australia, False otherwise.
    """
    AUS_LAT = (-44.0, -10.0)
    AUS_LON = (113.0, 154.0)

    lats = [p['lat'] for p in points]
    lons = [p['lon'] for p in points]

    lat_ok = all(AUS_LAT[0] <= v <= AUS_LAT[1] for v in lats)
    lon_ok = all(AUS_LON[0] <= v <= AUS_LON[1] for v in lons)

    if lat_ok and lon_ok:
        print(f'OK  {label}: all points within Australia '
              f'(lat {min(lats):.3f}–{max(lats):.3f}, lon {min(lons):.3f}–{max(lons):.3f})')
        return True

    swap_lat_ok = all(AUS_LAT[0] <= v <= AUS_LAT[1] for v in lons)
    swap_lon_ok = all(AUS_LON[0] <= v <= AUS_LON[1] for v in lats)

    print(f'WARNING  {label}: coordinates do not appear to be within Australia.')
    print(f'  lat values in data : {min(lats):.3f} to {max(lats):.3f}  '
          f'(expected {AUS_LAT[0]} to {AUS_LAT[1]})')
    print(f'  lon values in data : {min(lons):.3f} to {max(lons):.3f}  '
          f'(expected {AUS_LON[0]} to {AUS_LON[1]})')

    if swap_lat_ok and swap_lon_ok:
        print()
        print('  The values look correct if lat and lon are swapped.')
        print('  Your coordinates are likely in GeoJSON [lon, lat] order.')
        print('  Use geojson_file_to_api_polygon() to convert, or swap manually:')
        print('    points = [{"lat": p["lon"], "lon": p["lat"]} for p in points]')

    return False


if __name__ == "__main__":
    print(f"Credentials loaded for: {AURIN_USERNAME}")
    t = APICallTracker()
    t.summary()
    print("utils.py OK")
