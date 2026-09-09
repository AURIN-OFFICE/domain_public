# Shared utilities for the Domain API Phase 2 training notebooks (R version).
#
# Provides authentication, API call tracking, and spatial helper functions used
# across all five notebooks. Source this file at the top of each notebook:
#
#     source("utils.R")
#
# Exports:
#   PROXY_BASE                   -- base URL for the AURIN proxy
#   AURIN_USERNAME               -- your AURIN login, read from .env
#   make_tracker()               -- builds a tracker that wraps httr2 and counts calls
#   body_text()                  -- response body as text, "" when the body is empty
#   probe_count()                -- 1-credit density probe for the listings endpoint
#   field()                      -- NULL-safe accessor for nested API records
#   geojson_file_to_api_polygon  -- GeoJSON exterior ring to API polygon points
#   geojson_bbox_to_api_box      -- GeoJSON bounding box to API geoWindow.box
#   validate_australia_coords    -- pre-flight check that points fall within Australia

library(httr2)
library(jsonlite)
# purrr is used via purrr::pluck() rather than library(purrr), because attaching
# purrr masks jsonlite::flatten and prints a confusing startup message.


# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------

# Find the .env file by walking up from the working directory. This means the
# notebooks work whether you run them from phase-2/, from the project root, or
# from an RStudio session whose working directory is somewhere in between.
find_dotenv <- function(start = getwd(), max_levels = 5L) {
  dir <- normalizePath(start, mustWork = FALSE)
  for (i in seq_len(max_levels)) {
    candidate <- file.path(dir, ".env")
    if (file.exists(candidate)) return(candidate)
    parent <- dirname(dir)
    if (identical(parent, dir)) break  # reached the filesystem root
    dir <- parent
  }
  NULL
}

.dotenv_path <- find_dotenv()

# readRenviron is part of base R: it reads a file of NAME=value lines and sets
# them as environment variables. No extra package is needed to read a .env file.
if (!is.null(.dotenv_path)) {
  readRenviron(.dotenv_path)
}

AURIN_USERNAME <- Sys.getenv("AURIN_USERNAME")
AURIN_PASSWORD <- Sys.getenv("AURIN_PASSWORD")

if (!nzchar(AURIN_USERNAME) || !nzchar(AURIN_PASSWORD)) {
  stop(
    "AURIN_USERNAME / AURIN_PASSWORD not found in .env\n",
    if (is.null(.dotenv_path)) {
      paste0("  No .env file was found at or above: ", getwd(), "\n")
    } else {
      paste0("  Read .env from: ", .dotenv_path, "\n")
    },
    "  The file needs these two lines (no quotes, no spaces around the '='):\n",
    "    AURIN_USERNAME=your.email@institution.edu.au\n",
    "    AURIN_PASSWORD=your_aurin_password",
    call. = FALSE
  )
}

PROXY_BASE <- "https://domain.api.aurin.org.au"


# ---------------------------------------------------------------------------
# Request building
# ---------------------------------------------------------------------------
# Two things are handled centrally here so notebook code cannot get them wrong:
#
# 1. GET requests must NOT carry a content-type header. The Domain API returns
#    HTTP 200 with an empty body if a GET request carries one, which is the same
#    silent symptom as querying a suburb name that does not exist. httr2 only
#    sets content-type when a body is attached, so a GET built below has none.
#
# 2. POST bodies are serialised with auto_unbox = TRUE. R has no scalar type, so
#    without it `pageSize = 200` is sent as `[200]` and `includeSurroundingSuburbs
#    = FALSE` as `[false]`. The API's answer to a malformed body is, again, a
#    silent empty result. See Gotcha 8 in the phase-1 API Gotchas guide.

.base_request <- function(url) {
  request(url) |>
    req_headers(accept = "application/json") |>
    req_auth_basic(AURIN_USERNAME, AURIN_PASSWORD) |>
    # Return 4xx/5xx responses as values instead of raising an R error, so the
    # notebooks can inspect status codes and explain them.
    req_error(is_error = function(resp) FALSE)
}


#' Read a response body as text, returning "" when the response has no body.
#'
#' httr2's resp_body_string() raises "Can't retrieve empty body." when the
#' response carries no content at all. That is exactly the case the Domain API
#' produces for a misspelled suburb name (HTTP 200 with nothing attached), so
#' calling resp_body_string() directly turns the silent-empty failure into an R
#' error instead of something the notebooks can inspect and explain.
#'
#' @param resp an httr2 response.
#' @return the body as a character string, or "" if there is no body.
body_text <- function(resp) {
  if (resp_has_body(resp)) resp_body_string(resp) else ""
}


# ---------------------------------------------------------------------------
# API call tracker
# ---------------------------------------------------------------------------

#' Build a tracker that wraps GET and POST, logging every call made.
#'
#' Usage:
#'   tracker <- make_tracker()
#'   r <- tracker$post(url, json_body = list(...))
#'   tracker$checkpoint("Section label")
#'   tracker$summary()
#'
#' Returns an environment holding the log plus the functions above. An
#' environment is used because it is mutable: calls recorded inside tracker$get()
#' are visible afterwards without reassigning the tracker.
make_tracker <- function() {
  self <- new.env(parent = emptyenv())

  self$log <- list()
  self$checkpoints <- integer(0)  # named vector: label -> cumulative call count

  self$record <- function(method, url, status_code, params = NULL, body = NULL) {
    self$log[[length(self$log) + 1L]] <- list(
      timestamp   = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
      method      = method,
      url         = url,
      params      = params,
      body        = body,
      status_code = status_code
    )
    invisible(NULL)
  }

  self$get <- function(url, params = NULL) {
    req <- .base_request(url)
    if (length(params)) {
      req <- do.call(req_url_query, c(list(req), params))
    }
    resp <- req_perform(req)
    self$record("GET", url, resp_status(resp), params = params)
    resp
  }

  self$post <- function(url, json_body = NULL) {
    resp <- .base_request(url) |>
      req_body_json(json_body, auto_unbox = TRUE, digits = NA) |>
      req_perform()
    self$record("POST", url, resp_status(resp), body = json_body)
    resp
  }

  # Record how many calls have been made up to this point. Re-using a label
  # overwrites the earlier value rather than adding a second row.
  self$checkpoint <- function(label) {
    self$checkpoints[[label]] <- length(self$log)
    invisible(NULL)
  }

  self$total <- function() length(self$log)

  # Print a breakdown of calls consumed per checkpoint section.
  self$summary <- function() {
    bar <- strrep("=", 62)
    cat("\n", bar, "\n", sep = "")
    cat(sprintf("  TOTAL API CALLS: %d\n", self$total()))
    cat(bar, "\n", sep = "")
    prev <- 0L
    for (label in names(self$checkpoints)) {
      cumulative <- self$checkpoints[[label]]
      cat(sprintf("  %-42s %4d calls\n", label, cumulative - prev))
      prev <- cumulative
    }
    remaining <- self$total() - prev
    if (remaining > 0L) {
      cat(sprintf("  %-42s %4d calls\n", "(unlabelled)", remaining))
    }
    cat(bar, "\n\n", sep = "")
    invisible(NULL)
  }

  self
}


# ---------------------------------------------------------------------------
# Reading nested API records
# ---------------------------------------------------------------------------

#' Pull a value out of a nested API record, returning NA if any level is missing.
#'
#' The API returns deeply nested records and omits fields it has no value for.
#' In R a missing element reads back as NULL, which breaks data frame building,
#' so this returns NA instead.
#'
#'   field(item, "propertyDetails", "suburb")
#'   field(item, "soldData", "soldPrice")
#'
#' @param x   one listing record (a list, from resp_body_json).
#' @param ... the chain of names to follow.
#' @param .default value to return when the path is missing (default NA).
field <- function(x, ..., .default = NA) {
  value <- purrr::pluck(x, ..., .default = .default)
  if (is.null(value) || length(value) == 0L) return(.default)
  value
}


# ---------------------------------------------------------------------------
# Density probe
# ---------------------------------------------------------------------------

#' Send a 1-credit density probe to the listings search endpoint.
#'
#' Merges pageSize = 1 and pageNumber = 1 into base_payload, then reads the
#' X-Total-Count response header. Returns the integer count, or NULL on a
#' non-200 response.
#'
#' @param base_payload list with listingType and at least one of locations,
#'                     geoWindow$polygon, or geoWindow$box.
#' @param tracker      tracker created by make_tracker(), used for the request.
probe_count <- function(base_payload, tracker) {
  probe <- modifyList(base_payload, list(pageSize = 1L, pageNumber = 1L))
  r <- tracker$post(
    paste0(PROXY_BASE, "/v1/listings/residential/_search"),
    json_body = probe
  )
  if (resp_status(r) == 200) {
    total <- resp_header(r, "X-Total-Count")
    return(if (is.null(total)) 0L else as.integer(total))
  }
  cat(sprintf("  Probe failed -- HTTP %d: %s\n",
              resp_status(r), substr(body_text(r), 1, 200)))
  NULL
}


# ---------------------------------------------------------------------------
# Spatial helpers
# ---------------------------------------------------------------------------

# Read the first feature's geometry out of a GeoJSON file.
# simplifyVector = FALSE keeps the nested list structure, which is predictable;
# the default would coerce coordinates into matrices of varying shape.
.geojson_geometry <- function(path) {
  gj <- jsonlite::read_json(path, simplifyVector = FALSE)
  gj$features[[1]]$geometry
}

#' Read a GeoJSON file and return the exterior ring as API polygon points.
#'
#' GeoJSON coordinates are [longitude, latitude]. The Domain API expects a list
#' of list(lat = , lon = ). Only the exterior ring of the first feature is used;
#' interior rings (holes) are ignored.
#'
#' @param path path to a .geojson file with a Polygon or MultiPolygon feature.
#' @return list of list(lat = numeric, lon = numeric).
geojson_file_to_api_polygon <- function(path) {
  geom <- .geojson_geometry(path)

  if (geom$type == "Polygon") {
    ring <- geom$coordinates[[1]]
  } else if (geom$type == "MultiPolygon") {
    # Pick the largest exterior ring (most points = mainland, not an island)
    exterior_rings <- lapply(geom$coordinates, function(poly) poly[[1]])
    ring <- exterior_rings[[which.max(lengths(exterior_rings))]]
  } else {
    stop("Unsupported geometry type: ", geom$type, call. = FALSE)
  }

  lapply(ring, function(coord) list(lat = coord[[2]], lon = coord[[1]]))
}

#' Read a GeoJSON file and return a Domain API geoWindow$box.
#'
#' Computes the bounding box across all coordinates in the first feature.
#'
#' @param path path to a .geojson file with a Polygon or MultiPolygon feature.
#' @return list with topLeft and bottomRight, ready to use as the value of a
#'         "box" element inside a geoWindow list.
geojson_bbox_to_api_box <- function(path) {
  geom <- .geojson_geometry(path)

  if (geom$type == "Polygon") {
    # coordinates is a list of rings; flatten one level to get coordinate pairs
    all_coords <- unlist(geom$coordinates, recursive = FALSE)
  } else if (geom$type == "MultiPolygon") {
    # coordinates is a list of polygons, each a list of rings; flatten twice
    all_rings  <- unlist(geom$coordinates, recursive = FALSE)
    all_coords <- unlist(all_rings, recursive = FALSE)
  } else {
    stop("Unsupported geometry type: ", geom$type, call. = FALSE)
  }

  lons <- vapply(all_coords, function(c) as.numeric(c[[1]]), numeric(1))
  lats <- vapply(all_coords, function(c) as.numeric(c[[2]]), numeric(1))

  list(
    topLeft     = list(lat = max(lats), lon = min(lons)),
    bottomRight = list(lat = min(lats), lon = max(lons))
  )
}

#' Check that API-format points fall within Australia's bounding box.
#'
#' Catches the most common mistake: sending GeoJSON [lon, lat] order straight to
#' the API without swapping. Costs no credits.
#'
#' Australia bounding box (approximate):
#'   lat: -44.0 (south Tasmania) to -10.0 (north Queensland)
#'   lon: 113.0 (west WA)        to 154.0 (east QLD)
#'
#' @param points list of list(lat = , lon = ) (Domain API format).
#' @param label  string shown in the printed message.
#' @return TRUE if all points are within Australia, FALSE otherwise.
validate_australia_coords <- function(points, label = "coordinates") {
  AUS_LAT <- c(-44.0, -10.0)
  AUS_LON <- c(113.0, 154.0)

  lats <- vapply(points, function(p) as.numeric(p$lat), numeric(1))
  lons <- vapply(points, function(p) as.numeric(p$lon), numeric(1))

  lat_ok <- all(lats >= AUS_LAT[1] & lats <= AUS_LAT[2])
  lon_ok <- all(lons >= AUS_LON[1] & lons <= AUS_LON[2])

  if (lat_ok && lon_ok) {
    cat(sprintf(
      "OK  %s: all points within Australia (lat %.3f to %.3f, lon %.3f to %.3f)\n",
      label, min(lats), max(lats), min(lons), max(lons)
    ))
    return(TRUE)
  }

  # Would the values pass if lat and lon were the other way around?
  swap_lat_ok <- all(lons >= AUS_LAT[1] & lons <= AUS_LAT[2])
  swap_lon_ok <- all(lats >= AUS_LON[1] & lats <= AUS_LON[2])

  cat(sprintf("WARNING  %s: coordinates do not appear to be within Australia.\n", label))
  cat(sprintf("  lat values in data : %.3f to %.3f  (expected %s to %s)\n",
              min(lats), max(lats), AUS_LAT[1], AUS_LAT[2]))
  cat(sprintf("  lon values in data : %.3f to %.3f  (expected %s to %s)\n",
              min(lons), max(lons), AUS_LON[1], AUS_LON[2]))

  if (swap_lat_ok && swap_lon_ok) {
    cat("\n")
    cat("  The values look correct if lat and lon are swapped.\n")
    cat("  Your coordinates are likely in GeoJSON [lon, lat] order.\n")
    cat("  Use geojson_file_to_api_polygon() to convert, or swap manually:\n")
    cat("    points <- lapply(points, \\(p) list(lat = p$lon, lon = p$lat))\n")
  }

  FALSE
}


# ---------------------------------------------------------------------------
# Self-test: runs only when this file is executed directly (Rscript utils.R),
# not when it is sourced from a notebook.
# ---------------------------------------------------------------------------

if (sys.nframe() == 0L) {
  cat("Credentials loaded for:", AURIN_USERNAME, "\n")
  t <- make_tracker()
  t$summary()
  cat("utils.R OK\n")
}
