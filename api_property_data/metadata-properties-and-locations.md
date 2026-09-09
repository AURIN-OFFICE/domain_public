# Domain API: Properties and Locations via AURIN


## Table of Contents
- [About the AURIN API](#about-the-aurin-api)
- [Dataset Overview](#dataset-overview)
- [Coverage Summary](#coverage-summary)
- [Geographic Correspondences](#geographic-correspondences)
- [Group 2: Properties and Locations](#group-2-properties-and-locations)
  - [Property Records](#property-records)
    - [`GET /v1/properties/{id}`](#get-v1propertiesid)
    - [`GET /v1/addressLocators`](#get-v1addresslocators)
  - [Market Statistics](#market-statistics)
    - [`GET /v2/suburbPerformanceStatistics/{state}/{suburb}/{postcode}`](#get-v2suburbperformancestatisticsstatesuburbpostcode)
    - [`GET /v2/suburbPerformanceStatistics/{state}/{suburb}`](#get-v2suburbperformancestatisticsstatesuburb)
    - [`GET /v2/demographics/{state}/{suburb}/{postcode}`](#get-v2demographicsstatesuburbpostcode)
  - [Weekly Auction Results](#weekly-auction-results)
    - [`GET /v1/salesResults/{city}`](#get-v1salesresultscity)
    - [`GET /v1/salesResults/_head`](#get-v1salesresults_head)
    - [`GET /v1/salesResults/{city}/listings`](#get-v1salesresultscitylistings)
  - [Location Intelligence](#location-intelligence)
    - [`GET /v1/locations/profiles/{domainLocationId}`](#get-v1locationsprofilesdomainlocationid)
  - [Disclaimers](#disclaimers)
    - [`GET /v1/disclaimers`](#get-v1disclaimers)
    - [`GET /v1/disclaimers/product/{product}`](#get-v1disclaimersproductproduct)
- [Related Resources](#related-resources)


## About the AURIN API

The AURIN API (`https://domain.api.aurin.org.au`) is a **transparent reverse proxy** to the Domain public API (`https://api.domain.com.au`). Every request is forwarded verbatim, the path, method, query parameters, and request body are unchanged, and the response payload is identical to what Domain returns directly.

In principle, any endpoint available on the Domain API can be called via the AURIN base URL. In practice, AURIN only grants access to the **subscribed endpoint groups**. Calls to endpoints outside the subscription will be rejected at the proxy layer before reaching Domain. The endpoints documented below are the ones covered by the current AURIN subscription (Agents & Listings; Properties & Locations).

Authentication, credit counting, and rate limiting are enforced by AURIN; the Domain API is unaware of individual AURIN users.

## Dataset Overview

| Field | Value |
|---|---|
| **Title** | Domain API: Property Data Offerings |
| **Publisher** | Domain.com.au, accessed via AURIN proxy |
| **Access URL** | `https://domain.api.aurin.org.au` |
| **Authentication** | AURIN institutional credentials via HTTP Basic Auth |
| **Geographic coverage** | Australia |
| **License / Terms** | Domain API access agreement (signed via AURIN Data Provider) |
| **Update frequency** | Real-time / live query |
| **Subscription scope** | Agents & Listings; Properties & Locations |
| **Documented here** | Properties & Locations (Group 2). Agents & Listings is documented in `metadata-agents-and-listings.md` |
| **Credits** | 1,000/month per researcher; 1 credit per call |
| **Last reviewed** | 2026-05-22 |

For setup, authentication, credit budgeting, and known API quirks see the training guides in `training-materials/`.


## Coverage Summary

Offerings covered by this document (Group 2):

| Offering | Geography model | Temporal depth | Key constraints |
|---|---|---|---|
| Weekly auction results | City | Current week only | Not a historical archive |
| Suburb performance statistics | Suburb + postcode, or suburb only | Rolling 10-year window | Hard cap of 45 periods; House and Unit queried separately |
| Demographics | Suburb + postcode | 2011, 2016, 2021 Census years | Tied to Census release years. Fine for a single-suburb lookup (1 credit per call). For broad multi-suburb coverage, ABS is more efficient |
| Property record | Domain property ID | Current snapshot + history | One property per call |
| Location profile | Domain location ID | Current | Aggregate summary only |

Offerings in the companion document (Group 1): residential, commercial, and business listings search, plus new-development projects.


## Geographic Correspondences

The Domain API identifies locations using its own suburb name + postcode model. It does not natively expose ASGS (Australian Statistical Geography Standard) boundaries such as SA2, SA3, SA4, or GCCSA. Researchers who need to aggregate or spatially join Domain data against ABS Census geographies can use the following correspondence files, stored in `metadata/correspondance/`.

### File summary

| File | Census year | Mappings provided |
|---|---|---|
| `Correspondance: Suburb to GCCSA, SA2, SA3, SA4 (2021).xlsx` | 2016 | Suburb + postcode → SA2, SA3, SA4, GCCSA | 
| `Correspondance: Suburb to GCCSA (2021).xlsx` | 2021 | Suburb + postcode → GCCSA only |
| `Correspondance: Domain's Regions and Areas.xlsx` | n/a | Domain area/region → state hierarchy |

---

### `Correspondance: Suburb to GCCSA, SA2, SA3, SA4 (2021).xlsx`


| Column | Description |
|---|---|
| `SUBURB` | Suburb name |
| `POSTCODE_STR` | Four-digit postcode as a string (use this for joins to avoid leading-zero loss) |
| `POSTCODE_INT` | Postcode as an integer |
| `STATE` | State abbreviation (e.g. `NSW`) |
| `STATE_FULL` | Full state name (e.g. `New South Wales`) |
| `SA2_CODE` | ABS SA2 code |
| `SA2_NAME` | SA2 name |
| `SA3_CODE` | ABS SA3 code |
| `SA3_NAME` | SA3 name |
| `SA4_CODE` | ABS SA4 code |
| `SA4_NAME` | SA4 name |
| `GCCSA_NAME` | Greater Capital City Statistical Area name |
| `GCCSA_CODE` | GCCSA code (e.g. `1GSYD`) |
| `OVERLAP_PERCENTAGE` | Fractional proportion of the suburb's area that falls within the assigned SA2 (0–1, not a percentage). Suburbs that straddle SA2 boundaries appear as multiple rows, one per SA2. |

Join key: `SUBURB` + `POSTCODE_STR` pair.

When a suburb appears more than once (different `SA2_CODE` values), the row with the highest `OVERLAP_PERCENTAGE` represents the dominant SA2 for that suburb.

---

### `Correspondance: Suburb to GCCSA (2021).xlsx`

Updated correspondence for the 2021 ABS Census classification. GCCSA-level only does not include SA2/SA3/SA4.

| Column | Description |
|---|---|
| `STATE` | State abbreviation |
| `GCCSA2021NAME` | Greater Capital City Statistical Area name (2021 ASGS edition) |
| `SUBURB` | Suburb name |
| `POSTCODE` | Four-digit postcode |

Join key: `SUBURB` + `POSTCODE` pair.

Use this file when your analysis needs to align with 2021 Census data (e.g., the Demographics endpoint, which supports `year=2021`).

---

### `Correspondance: Domain's Regions and Areas.xlsx`

Maps Domain's proprietary geographic hierarchy (areas and regions, as returned in `listing.propertyDetails.area` and `listing.propertyDetails.region` response fields) to Australian states. This is not an ASGS mapping, it reflects Domain's own editorial grouping of suburbs.

| Column | Description |
|---|---|
| `Category` | `Area` or `Region` (Domain classification level) |
| `DisplayName` | Name of the area or region |
| `State` | Australian state the area/region belongs to |
| `Contained within Region` | Parent region for rows where Category is `Area` |

Use this file to understand how Domain groups suburbs under region labels, or to filter listings by Domain region without specifying individual suburb + postcode pairs.

---
## Group 2: Properties and Locations

*Explore auction results and property datasets. Access market performance and demographic stats.*

### Property Records

---

#### `GET /v1/properties/{id}`
Retrieve a full property record using its Domain property ID.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | string | required (path) | Domain's alphanumeric property identifier for the specific property record to retrieve | Domain property ID |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | string | Domain's unique alphanumeric identifier for this property record | |
| `canonicalUrl` | string | Permanent URL for this property's page on Domain | |
| `status` | string | Whether the property is currently listed on the market or off market | `OffMarket`, `OnMarket` |
| `onMarketTypes` | array[string] | List of market channels this property is currently active on | |
| `address` | string | Full formatted street address of the property | Full formatted address |
| `addressCoordinate.lat` | number | Geographic latitude coordinate of the property | |
| `addressCoordinate.lon` | number | Geographic longitude coordinate of the property | |
| `addressId` | integer | Internal Domain identifier for the address record | |
| `streetAddress` | string | Street-level portion of the property address | |
| `streetName` | string | Name of the street the property is on | |
| `streetNumber` | string | Street number of the property | |
| `streetType` | string | Abbreviated form of the street type (e.g. "St", "Ave") | Short form |
| `streetTypeLong` | string | Full unabbreviated form of the street type (e.g. "Street", "Avenue") | Full form |
| `flatNumber` | string | Unit or flat number for properties within a multi-dwelling building | |
| `suburb` | string | Suburb where the property is located | |
| `suburbId` | integer | Domain's internal numeric identifier for the suburb | |
| `postcode` | string | Four-digit Australian postcode for the property | |
| `state` | string | Australian state or territory where the property is located | |
| `propertyCategory` | string | Broad category classifying the property (e.g. house, unit) | |
| `propertyCategoryId` | integer | Numeric code for the property's broad category | |
| `propertyType` | string | More specific classification of the property type (e.g. house, apartment) | |
| `propertyTypeId` | integer | Numeric code for the specific property type | |
| `isResidential` | boolean | Whether the property is classified as a residential dwelling | |
| `bedrooms` | integer | Number of bedrooms in the property | |
| `bathrooms` | integer | Number of bathrooms in the property | |
| `carSpaces` | integer | Number of off-street car parking spaces at the property | |
| `internalArea` | string | Internal floor area of the building as a formatted display string | |
| `areaSize` | integer | Total land parcel area in square metres | Total land area (sqm) |
| `yearBuilt` | integer | Year the property was originally constructed | |
| `zone` | string | Government zoning classification applied to the land | Zoning classification |
| `features` | array[string] | List of amenities and physical attributes the property has | |
| `lotNumber` | string | Lot number on the deposited plan for the property | |
| `planNumber` | string | Deposited or survey plan number associated with the property | |
| `storeys` | string | Number of storeys or levels in the building | |
| `title` | string | Type of land title for the property (e.g. Torrens, strata) | |
| `landUse` | string | Designated land use category as determined by local planning controls | |
| `cadastreType` | string | GeoJSON geometry type used to represent the property's land boundary | GeoJSON geometry type |
| `claim.claimant` | string | Relationship of the person who has claimed ownership of this property profile | `Owner`, `Tenant`, `Investor`, `Unspecified` |
| `urlSlug` | string | URL-friendly string identifier for the property's page on Domain | |
| `urlSlugShort` | string | Shortened URL-friendly identifier for the property's page | |
| `created` | string | Date when the property record was first created in the Domain database | |
| `updated` | date | Date when the property record was last updated | |
| `adverts[].advertId` | integer | Unique identifier for an advertisement linked to this property | |
| `adverts[].agency` | string | Name of the agency that placed this advertisement | |
| `adverts[].agencyId` | integer | Unique identifier for the agency that placed this advertisement | |
| `adverts[].onMarketTypes` | array[string] | Market channels the associated advertisement is active on | |
| `adverts[].url` | string | URL to the advertisement on Domain | |
| `photos[].imageType` | string | Classification of the image (property photo, floorplan, or street view) | `Property`, `Floorplan`, `GoogleStreetView` |
| `photos[].advertId` | integer | Identifier of the advertisement this photo is associated with | |
| `photos[].date` | date | Date the photo was taken or uploaded | |
| `photos[].fullUrl` | string | URL to the full-resolution version of the image | |
| `photos[].rank` | integer | Display ordering rank for this image within the listing's photo gallery | |
| `gnafIds[].gnafPID` | string | G-NAF (Geocoded National Address File) persistent identifier for the address | GNAF identifier |
| `gnafIds[].monthNo` | integer | Month number associated with this G-NAF record's validity period | |
| `gnafIds[].yearNo` | integer | Year associated with this G-NAF record's validity period | |
| `history.sales[].id` | integer(int64) | Unique identifier for this sale event in the property's history | 64-bit integer |
| `history.sales[].advertId` | string | Domain advertisement identifier associated with this sale event | |
| `history.sales[].type` | string | Description of how the sale was conducted (e.g. "Private Treaty - Sold") | e.g. "Private Treaty - Sold" |
| `history.sales[].price` | integer | Final sale price achieved in Australian dollars | |
| `history.sales[].date` | date | Date on which the property sale was completed | |
| `history.sales[].agency` | string | Name of the agency that represented the sale | |
| `history.sales[].agencyId` | integer | Unique Domain identifier for the agency that conducted the sale | |
| `history.sales[].agencyUrl` | string | URL to the agency's Domain profile page at time of sale | |
| `history.sales[].apmAgencyId` | integer | APM system identifier for the agency involved in the sale | |
| `history.sales[].daysOnMarket` | number | Number of days the property was listed before the sale was agreed | |
| `history.sales[].documentedAsSold` | boolean | Whether there is documentary evidence confirming this sale | |
| `history.sales[].reportedAsSold` | boolean | Whether this sale was reported by the agent rather than drawn from official records | |
| `history.sales[].suppressDetails` | boolean | Whether the full details of this sale are suppressed from public display | |
| `history.sales[].suppressPrice` | boolean | Whether the price for this sale is suppressed from public display | |
| `history.sales[].url` | string | URL to the original listing associated with this sale | |
| `history.sales[].first.advertisedDate` | date-time | Date when the property was first advertised for this sale campaign | |
| `history.sales[].first.advertisedPrice` | integer | Asking price when the property was first listed for this sale | |
| `history.sales[].first.agency` | string | Name of the agency that first advertised the property | |
| `history.sales[].first.agencyId` | integer | Unique identifier for the agency that first advertised the property | |
| `history.sales[].first.source` | string | Origin of the first advertisement data record | |
| `history.sales[].first.type` | string | Listing type classification when the property was first advertised | |
| `history.sales[].first.listingId` | integer | Domain listing ID for the first advertisement in this sale campaign | |
| `history.sales[].first.url` | string | URL of the Domain listing page for the first advertisement in this sale campaign | |
| `history.sales[].last.advertisedDate` | date-time | Date when the property was most recently advertised in this sale campaign | |
| `history.sales[].last.advertisedPrice` | integer | Asking price at the most recent advertisement in this sale campaign | |
| `history.sales[].last.agency` | string | Name of the agency that placed the most recent advertisement | |
| `history.sales[].last.agencyId` | integer | Unique identifier for the agency that placed the most recent advertisement | |
| `history.sales[].last.source` | string | Origin of the most recent advertisement data record | |
| `history.sales[].last.type` | string | Listing type classification at the most recent advertisement | |
| `history.sales[].last.listingId` | integer | Domain listing ID for the most recent advertisement in this sale campaign | |
| `history.sales[].last.url` | string | URL of the Domain listing page for the most recent advertisement in this sale campaign | |
| `history.sales[].propertyType` | string | Property category classification recorded at the time of this sale | |
| `history.rentals[].id` | integer(int64) | Unique identifier for this rental listing event in the property's history | 64-bit integer |
| `history.rentals[].propertyType` | string | Property category classification recorded at the time of this rental | |
| `history.rentals[].first.advertisedDate` | date-time | Date when the property was first advertised for this rental campaign | |
| `history.rentals[].first.advertisedPrice` | integer | Weekly asking rent when the property was first advertised for this campaign | |
| `history.rentals[].first.agency` | string | Name of the agency that first advertised the rental | |
| `history.rentals[].first.agencyId` | integer | Unique identifier for the agency that first advertised the rental | |
| `history.rentals[].first.source` | string | Origin of the first rental advertisement data record | |
| `history.rentals[].first.suppressDetails` | boolean | Whether the details of this first rental listing are suppressed from public display | |
| `history.rentals[].first.suppressPrice` | boolean | Whether the rent price for this first rental listing is suppressed from public display | |
| `history.rentals[].first.type` | string | Listing type classification when the rental was first advertised | |
| `history.rentals[].first.url` | string | URL to the original rental listing | |
| `history.rentals[].first.listingId` | integer | Domain listing ID for the first advertisement in this rental campaign | |
| `history.rentals[].last` | object | Object containing the same fields as .first but for the most recent advertisement in this rental campaign | Same structure as `.first` |

---

#### `GET /v1/addressLocators`
Resolve a street address to Domain internal IDs at multiple geographic hierarchy levels.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `searchLevel` | string | required | Whether to resolve the input to a specific address or to suburb level | `Address`, `Suburb` |
| `suburb` | string | required | Suburb name component of the address to resolve | |
| `state` | string | required | State abbreviation for the address to resolve | State abbreviation |
| `unitNumber` | string | optional | Unit or apartment number component of the address to resolve | |
| `streetNumber` | string | optional | Street number component of the address to resolve | |
| `streetName` | string | optional | Street name component of the address to resolve | |
| `streetType` | string | optional | Street type component of the address (short or long form accepted) | Short or long form |
| `postcode` | string | optional | Postcode component of the address to resolve | |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `types[]` | array[string] | List of location hierarchy levels that were successfully matched for the input address | Matched location types (e.g., "Address") |
| `addressComponents[].component` | string | Name of the address component (e.g. StreetNumber, Suburb) | `StreetNumber`, `StreetName`, `StreetType`, `Suburb`, `Postcode`, `State` |
| `addressComponents[].shortName` | string | Resolved value for this address component | Value of the component |
| `ids[].level` | string | Geographic hierarchy level of this identifier (Address, Street, Suburb, Postcode) | `Address`, `Street`, `Suburb`, `Postcode` |
| `ids[].id` | integer | Domain's internal numeric identifier at this geographic hierarchy level | Internal ID at that hierarchy level |



### Market Statistics

---

#### `GET /v2/suburbPerformanceStatistics/{state}/{suburb}/{postcode}`
Time-series aggregated market statistics for a suburb (with postcode).

**Data metadata**

| Category | Detail |
|---|---|
| Update frequency | Monthly, on the 25th of each month |
| Temporal coverage | Past 10 years (rolling window) |
| Data sources | domain.com.au; States and Territories Valuer General departments |
| Quirk | A wrong suburb-postcode combination may still return HTTP 200 with no data in the response body |

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `state` | string | required (path) | Australian state or territory for the suburb to query | `NSW`, `VIC`, `QLD`, `SA`, `WA`, `TAS`, `NT`, `ACT` |
| `suburb` | string | required (path) | Name of the suburb whose market statistics to retrieve | |
| `postcode` | string | required (path) | Four-digit postcode to disambiguate suburbs with the same name in different locations | |
| `propertyCategory` | string | optional | Whether to return statistics for houses or units (queried separately) | `House`, `Unit`. Default: `house` |
| `bedrooms` | integer | optional | Filter statistics to properties with this specific bedroom count | Filter by bedroom count |
| `periodSize` | string | optional | Time interval for each statistical period in the series | `quarters`, `halfYears`, `years`. Default: `quarters` |
| `startingPeriodRelativeToCurrent` | integer | optional | Offset from the current period to start the series (1 = start from the current period) | 1 = current period. Default: 1 |
| `totalPeriods` | integer | optional | Total number of historical periods to return in the time series | Max: 45. Default: 4. **Always request 45.** |

**`propertyCategory` mapping**

`House` and `Unit` are the only two categories returned. Each domain-level property type maps to one of them as follows. Vacant land (no residential improvements) is excluded from both categories.

| Property type | Category |
|---|---|
| House | `House` |
| Townhouse | `House` |
| Duplex | `House` |
| Triplex | `House` |
| Terrace | `House` |
| Cottage | `House` |
| Semi-Detached | `House` |
| Apartment | `Unit` |
| Unit | `Unit` |
| Flat | `Unit` |
| Studio | `Unit` |
| Villa | `Unit` |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `header.suburb` | string | Suburb name as resolved and confirmed by the API | |
| `header.state` | string | State abbreviation for the returned suburb | |
| `header.propertyCategory` | string | Property category (House or Unit) for which statistics are reported | |
| `series.seriesInfo[].year` | integer | Calendar year of this statistical period | |
| `series.seriesInfo[].month` | integer | Starting month of this statistical period | |
| `series.seriesInfo[].values.medianSoldPrice` | integer | Median sale price of properties sold in this suburb during this period | |
| `series.seriesInfo[].values.numberSold` | integer | Total number of properties sold in this suburb during this period | |
| `series.seriesInfo[].values.highestSoldPrice` | integer | Highest sale price recorded in this suburb during this period | |
| `series.seriesInfo[].values.lowestSoldPrice` | integer | Lowest sale price recorded in this suburb during this period | |
| `series.seriesInfo[].values.5thPercentileSoldPrice` | integer | Sale price at the 5th percentile for properties sold in this period | |
| `series.seriesInfo[].values.25thPercentileSoldPrice` | integer | Sale price at the 25th percentile (lower quartile) for properties sold in this period | |
| `series.seriesInfo[].values.75thPercentileSoldPrice` | integer | Sale price at the 75th percentile (upper quartile) for properties sold in this period | |
| `series.seriesInfo[].values.95thPercentileSoldPrice` | integer | Sale price at the 95th percentile for properties sold in this period | |
| `series.seriesInfo[].values.medianSaleListingPrice` | integer | Median asking price of properties listed for sale during this period | |
| `series.seriesInfo[].values.numberSaleListing` | integer | Total number of properties listed for sale during this period | |
| `series.seriesInfo[].values.highestSaleListingPrice` | integer | Highest asking price among properties listed for sale during this period | |
| `series.seriesInfo[].values.lowestSaleListingPrice` | integer | Lowest asking price among properties listed for sale during this period | |
| `series.seriesInfo[].values.auctionNumberAuctioned` | integer | Total number of properties taken to auction during this period | |
| `series.seriesInfo[].values.auctionNumberSold` | integer | Number of properties sold at or after auction during this period | |
| `series.seriesInfo[].values.auctionNumberWithdrawn` | integer | Number of properties withdrawn from auction during this period | |
| `series.seriesInfo[].values.daysOnMarket` | integer | Median number of days properties were listed before sale during this period | |
| `series.seriesInfo[].values.discountPercentage` | number | Median percentage reduction between the first advertised price and the final sale price | |
| `series.seriesInfo[].values.meanRentYield` | number | Mean gross rental yield as a percentage for properties in this suburb during this period | |
| `series.seriesInfo[].values.medianRentListingPrice` | integer | Median weekly asking rent for properties listed for rent during this period | |
| `series.seriesInfo[].values.numberRentListing` | integer | Total number of properties listed for rent during this period | |
| `series.seriesInfo[].values.highestRentListingPrice` | integer | Highest weekly asking rent among properties listed for rent during this period | |
| `series.seriesInfo[].values.lowestRentListingPrice` | integer | Lowest weekly asking rent among properties listed for rent during this period | |

---

#### `GET /v2/suburbPerformanceStatistics/{state}/{suburb}`
Same as above but suburb identified without a postcode.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `state` | string | required (path) | Australian state or territory for the suburb to query | `NSW`, `VIC`, `QLD`, `SA`, `WA`, `TAS`, `NT`, `ACT` |
| `suburb` | string | required (path) | Name of the suburb whose market statistics to retrieve | |
| `propertyCategory` | string | optional | Whether to return statistics for houses or units (queried separately) | `House`, `Unit`. Default: `house` |
| `bedrooms` | integer | optional | Filter statistics to properties with this specific bedroom count | |
| `periodSize` | string | optional | Time interval for each statistical period in the series | `quarters`, `halfYears`, `years`. Default: `quarters` |
| `startingPeriodRelativeToCurrent` | integer | optional | Offset from the current period to start the series (1 = start from the current period) | Default: 1 |
| `totalPeriods` | integer | optional | Total number of historical periods to return in the time series | Max: 45. Default: 4. **Always request 45.** |

**Response fields:** Same as `GET /v2/suburbPerformanceStatistics/{state}/{suburb}/{postcode}`.

---

#### `GET /v2/demographics/{state}/{suburb}/{postcode}`
Census demographic profile for a suburb.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `state` | string | required (path) | Australian state or territory for the suburb to query | |
| `suburb` | string | required (path) | Name of the suburb whose demographic profile to retrieve | |
| `postcode` | string | required (path) | Four-digit postcode to disambiguate suburb names | |
| `year` | integer | optional | Census year for which to retrieve demographic data | `2011`, `2016`, `2021` |
| `types` | string | optional | Demographic categories to include in the response | Comma-separated: `AgeGroupOfPopulation`, `CountryOfBirth`, `NatureOfOccupancy`, `Occupation`, `GeographicalPopulation`, `DwellingStructure`, `EducationAttendance`, `HousingLoanRepayment`, `MaritalStatus`, `Religion`, `TransportToWork`, `FamilyComposition`, `HouseholdIncome`, `Rent`, `LabourForceStatus` |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `demographics[].type` | string | Name of the demographic category being reported | Category name (e.g., `TransportToWork`) |
| `demographics[].year` | integer | Census year in which this demographic data was collected | Census year |
| `demographics[].total` | integer | Total number of respondents counted in this demographic category | Total respondents for this category |
| `demographics[].items[].label` | string | Name of a specific sub-category or response option within this demographic type | Category item label (e.g., "Car (driver)", "No Religion") |
| `demographics[].items[].value` | integer | Count of respondents who selected or were recorded under this label | Count for this label |
| `demographics[].items[].composition` | string | The unit or basis on which the count is measured (e.g. Persons or total households) | Unit/basis: `"Persons"` or `"Total"` (not a percentage) |



### Weekly Auction Results

---

#### `GET /v1/salesResults/{city}`
Weekly auction summary statistics for a city.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `city` | string | required (path) | Name of the city for which to retrieve weekly auction results | City name |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `auctionedDate` | date | The Saturday date on which the reported auctions were conducted | Date of the auction event |
| `lastModifiedDateTime` | date-time | Date and time when the auction results data was last updated | When results were last modified |
| `numberListedForAuction` | number | Total number of properties that were scheduled for auction this week | |
| `numberWithdrawn` | number | Number of properties that were withdrawn from auction before being offered | |
| `numberUnreported` | number | Number of properties auctioned for which no result has yet been reported | |
| `numberSold` | number | Number of properties that achieved a successful sale outcome through auction | |
| `totalSales` | number | Combined total value of all successful sales during this auction week in Australian dollars | Total sales value (dollars) |
| `median` | number | Median sale price achieved across all sold properties during this auction week | Median sale price |
| `adjClearanceRate` | number | Proportion of auctioned properties that sold, adjusted to exclude unreported results | Adjusted clearance rate (sold / auctioned, excluding unreported) |

---

#### `GET /v1/salesResults/_head`
Retrieve publication date and last-modified timestamp for the current week's results.

**Input parameters:** None.

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `auctionedDate` | date | The Saturday date on which the current week's auctions were conducted | Date of auction event |
| `lastModifiedDateTime` | date-time | Date and time when the current week's auction results were last published | When results were published |

---

#### `GET /v1/salesResults/{city}/listings`
Individual property records from the current week's auction results.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `city` | string | required (path) | Name of the city for which to retrieve individual auction property records | City name |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `unitNumber` | string | Unit or apartment number for properties within a multi-dwelling building | |
| `streetNumber` | string | Street number of the auctioned property | |
| `streetName` | string | Street name of the auctioned property | |
| `streetType` | string | Abbreviated street type designation (e.g. "Cr" for Crescent) | Abbreviated (e.g., `"Cr"` for Crescent) |
| `suburb` | string | Suburb where the auctioned property is located | |
| `postcode` | string | Four-digit Australian postcode for the auctioned property | |
| `state` | string | Australian state or territory where the auctioned property is located | |
| `geoLocation.latitude` | number | Geographic latitude coordinate of the auctioned property | |
| `geoLocation.longitude` | number | Geographic longitude coordinate of the auctioned property | |
| `propertyType` | string | Category of the auctioned property (e.g. house, apartment) | |
| `bedrooms` | number | Number of bedrooms in the auctioned property | |
| `bathrooms` | number | Number of bathrooms in the auctioned property | |
| `carspaces` | number | Number of off-street car parking spaces at the auctioned property | |
| `price` | number | Sale price or highest bid achieved at auction in Australian dollars | Sale price (where applicable; see result codes) |
| `result` | string | Code indicating the outcome of the auction for this property | Auction result code (see table below) |
| `agent` | string | Name of the agent or agency who conducted the sale | Agent or agency name |
| `id` | number | Domain listing identifier for this auction property record | Listing ID |
| `agencyId` | number | Unique Domain identifier for the agency that marketed the property | |
| `agencyName` | string | Trading name of the agency that marketed the property | |
| `agencyProfilePageUrl` | string | URL to the agency's profile page on Domain | |
| `propertyDetailsUrl` | string | URL to the property details page on Domain | |

**Auction result codes (`result` field)**

| Code | Meaning | Price field value |
|---|---|---|
| AUSD / AUSN | Auction: Sold | Sale price |
| AUSA / AUSS | Auction: Sold After | Sale price |
| AUPN / AUSP | Auction: Sold Prior | Sale price |
| PTSD | Private Treaty: Sold | Sale price |
| PTSW | Private Treaty: Sold (Warning) | Potentially unreliable price |
| PTLA | Private Treaty: Related Parties | Price between known parties |
| AUHB | Auction: Highest Bid (below reserve) | Highest bid amount |
| AUPI | Auction: Passed In | N/A |
| AUVB | Auction: Vendor Bid | Last vendor bid |
| AUWD | Auction: Withdrawn | N/A |



### Location Intelligence

---

#### `GET /v1/locations/profiles/{domainLocationId}`
Aggregate suburb-level profile: market pricing, property availability, and demographic indicators.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `domainLocationId` | string | required (path) | Domain's unique identifier for the suburb or location whose profile to retrieve | Domain location ID |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `domainLocationId` | integer | Domain's unique numeric identifier for this suburb location | |
| `suburbName` | string | Official name of the suburb | |
| `postcode` | string | Four-digit Australian postcode for the suburb | |
| `state` | string | Australian state or territory the suburb is in | |
| `urlSlug` | string | SEO-friendly URL identifier for the suburb's profile page | SEO-friendly URL (e.g., `"sydney-nsw-2000"`) |
| `pfLocationId` | string | Property Feed system location identifier for this suburb | Property Feed location ID |
| `apmLocationId` | integer | APM (Australian Property Monitors) location identifier for this suburb | APM location ID |
| `locationId` | integer | Alternative internal location identifier used within Domain's systems | |
| `areaName` | string | Name of the broader geographic area this suburb belongs to | |
| `regionName` | string | Name of the regional grouping this suburb belongs to | |
| `surroundingSuburbs[].name` | string | Name of a neighbouring suburb | |
| `surroundingSuburbs[].urlSlug` | string | URL-friendly identifier for the neighbouring suburb's profile page | |
| `data.population` | number | Estimated resident population of the suburb | |
| `data.mostCommonAgeBracket` | string | Age range that represents the largest share of the suburb's population | e.g., `"20 to 39"` |
| `data.singlePercentage` | number | Proportion of residents who are single or not in a registered relationship | |
| `data.marriedPercentage` | number | Proportion of residents who are married or in a registered relationship | |
| `data.ownerOccupierPercentage` | number | Proportion of dwellings occupied by their owners | |
| `data.renterPercentage` | number | Proportion of dwellings occupied by renters | |
| `data.studiosForSale` | integer | Number of studio apartments currently listed for sale in the suburb | |
| `data.studiosForRent` | integer | Number of studio apartments currently listed for rent in the suburb | |
| `data.apartmentsAndUnitsForSale` | integer | Number of apartments and units currently listed for sale in the suburb | |
| `data.apartmentsAndUnitsForRent` | integer | Number of apartments and units currently listed for rent in the suburb | |
| `data.townhousesForSale` | integer | Number of townhouses currently listed for sale in the suburb | |
| `data.townhousesForRent` | integer | Number of townhouses currently listed for rent in the suburb | |
| `data.semiDetachedHousesForSale` | integer | Number of semi-detached houses currently listed for sale in the suburb | |
| `data.semiDetachedHousesForRent` | integer | Number of semi-detached houses currently listed for rent in the suburb | |
| `data.terracedHousesForSale` | integer | Number of terraced houses currently listed for sale in the suburb | |
| `data.terracedHousesForRent` | integer | Number of terraced houses currently listed for rent in the suburb | |
| `data.housesForSale` | integer | Number of standalone houses currently listed for sale in the suburb | |
| `data.housesForRent` | integer | Number of standalone houses currently listed for rent in the suburb | |
| `data.villasForSale` | integer | Number of villas currently listed for sale in the suburb | |
| `data.villasForRent` | integer | Number of villas currently listed for rent in the suburb | |
| `data.duplexesForSale` | integer | Number of duplexes currently listed for sale in the suburb | |
| `data.duplexesForRent` | integer | Number of duplexes currently listed for rent in the suburb | |
| `data.penthousesForSale` | integer | Number of penthouses currently listed for sale in the suburb | |
| `data.penthousesForRent` | integer | Number of penthouses currently listed for rent in the suburb | |
| `data.blockOfUnitsForSale` | integer | Number of residential unit blocks currently listed for sale in the suburb | |
| `data.propertyCategories[].propertyCategory` | string | Broad property category (House or Unit) for this statistical breakdown | `House`, `Unit` |
| `data.propertyCategories[].bedrooms` | integer | Bedroom count for this statistical breakdown within the category | |
| `data.propertyCategories[].forSale` | integer | Number of properties in this category currently listed for sale | |
| `data.propertyCategories[].forRent` | integer | Number of properties in this category currently listed for rent | |
| `data.propertyCategories[].medianSoldPrice` | number | Median sale price for properties in this category in this suburb | |
| `data.propertyCategories[].entryLevelPrice` | number | Lower-end market price representing the entry point for buyers in this category | Lower-end market price |
| `data.propertyCategories[].luxuryLevelPrice` | number | Upper-end market price representing the premium segment for this category | Upper-end market price |
| `data.propertyCategories[].medianRentPrice` | number | Median weekly rental price for properties in this category | Median weekly rent |
| `data.propertyCategories[].estimatedRepayments` | number | Estimated monthly mortgage repayments based on the median sale price | Monthly mortgage repayments |
| `data.propertyCategories[].daysOnMarket` | number | Typical number of days properties in this category take to sell | |
| `data.propertyCategories[].auctionClearanceRate` | number | Proportion of auctioned properties in this category that successfully sold | |
| `data.propertyCategories[].mostRecentSale` | string | Date or description of the most recent sale recorded in this category | |
| `data.propertyCategories[].numberSold` | integer | Total number of properties sold in this category over the reported period | |
| `data.propertyCategories[].salesGrowthList[].year` | integer | Calendar year for this historical sales growth data point | |
| `data.propertyCategories[].salesGrowthList[].medianSoldPrice` | number | Median sale price in this category for this year | |
| `data.propertyCategories[].salesGrowthList[].annualGrowth` | number | Year-on-year percentage change in median sale price for this category | |
| `data.propertyCategories[].salesGrowthList[].numberSold` | integer | Number of properties sold in this category during this year | |



### Disclaimers

---

#### `GET /v1/disclaimers`
Retrieve legal disclaimer text by ID.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `ids` | string | required | Comma-separated list of disclaimer authority identifiers to retrieve | Comma-separated IDs, e.g. `"APM,NSWVG,VICVG"` |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | string | Authority or data-source identifier for the disclaimer (e.g. "APM", "NSWVG") | Authority/source identifier (e.g., `"APM"`) |
| `version` | string | Version number of the disclaimer text | Disclaimer version |
| `text` | string | Full legal disclaimer text as required to be displayed alongside this data source's content | Full legal disclaimer text |
| `imageurl` | string | URL of the logo or branding image associated with the data authority | Logo or image URL for the authority |
| `authorityname` | string | Official name of the data authority or government body that owns the disclaimer | Authority name (e.g., `"APM"`, `"State of Victoria"`) |

---

#### `GET /v1/disclaimers/product/{product}`
Retrieve disclaimer text for a specific Domain product type.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `product` | string | required (path) | Domain product type for which to retrieve the applicable disclaimer text | `PropertyData`, `AURIN`, `HomePriceGuide` |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | string | Identifier for this disclaimer record | |
| `version` | string | Version number of the disclaimer text | |
| `text` | string | Full disclaimer text for this Domain product type | Full disclaimer text |
| `imageurl` | string | URL of the logo or image associated with this disclaimer | |
| `authorityname` | string | Official name of the data provider associated with this disclaimer | Official name of the data provider |


## Related Resources

| Resource | Path |
|---|---|
| Getting started overview | `training-materials/phase-1/00-getting-started.md` |
| Data access and setup | `training-materials/phase-1/01-data-access-guide.md` |
| Comparison with APM data model | `training-materials/phase-1/02-paradigm-shift.md` |
| Credit cost estimation | `training-materials/phase-1/03-credit-calculator.md` |
| Known API quirks and defensive patterns | `training-materials/phase-1/04-api-gotchas.md` |
| Listings search notebook | `training-materials/phase-2/notebook-1-listings-search.ipynb` |
| Suburb statistics notebook | `training-materials/phase-2/notebook-2-suburb-statistics.ipynb` |
| Pagination and cursor advancement | `training-materials/phase-2/notebook-3-pagination-tricks.ipynb` |
| Spatial and polygon queries | `training-materials/phase-2/notebook-4-spatial-querying.ipynb` |
| Full endpoint JSON schemas | `domain-data-schema/` (one file per endpoint) |
| Agents & Listings field dictionary | `metadata/Agents & Listings API - Data Dictionary.xlsx` |
| Properties & Locations field dictionary | `metadata/Properties & Locations API - Data Dictionary.xlsx` |
| Suburb → SA2/SA3/SA4/GCCSA correspondence (2021) | `metadata/correspondance/Correspondance - Suburb  to GCCSA, SA2, SA3, SA4 (2021).xlsx` |
| Suburb → GCCSA correspondence (2021) | `metadata/correspondance/Correspondance - Suburb to GCCSA (2021).xlsx` |
| Domain areas and regions hierarchy | `metadata/correspondance/Correspondance - Domain's Regions and Areas.xlsx` |
| **Companion document — Group 1 endpoints** | `metadata-agents-and-listings.md` |

