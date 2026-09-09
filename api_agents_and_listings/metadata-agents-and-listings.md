# Domain API: Agents and Listings via AURIN


## Table of Contents
- [About the AURIN API](#about-the-aurin-api)
- [Dataset Overview](#dataset-overview)
- [Coverage Summary](#coverage-summary)
- [Geographic Correspondences](#geographic-correspondences)
- [Group 1: Agents and Listings](#group-1-agents-and-listings)
  - [Listings](#listings)
    - [`POST /v1/listings/residential/_search`](#post-v1listingsresidential_search)
    - [`POST /v1/listings/commercial/_search`](#post-v1listingscommercial_search)
    - [`POST /v1/listings/business/_search`](#post-v1listingsbusiness_search)
    - [`GET /v1/listings/{id}`](#get-v1listingsid)
    - [`GET /v1/listings/locations`](#get-v1listingslocations)
  - [Agencies](#agencies)
    - [`GET /v1/agencies`](#get-v1agencies)
    - [`HEAD /v1/agencies`](#head-v1agencies)
    - [`GET /v1/agencies/{id}`](#get-v1agenciesid)
    - [`GET /v1/agencies/{id}/listings`](#get-v1agenciesidlistings)
  - [Agents](#agents)
    - [`GET /v1/agents/search`](#get-v1agentssearch)
    - [`GET /v1/agents/{id}`](#get-v1agentsid)
    - [`GET /v1/agents/{id}/listings`](#get-v1agentsidlistings)
  - [Projects (New Developments)](#projects-new-developments)
    - [`GET /v1/projects`](#get-v1projects)
    - [`GET /v1/projects/{id}`](#get-v1projectsid)
    - [`GET /v1/projects/{id}/listings`](#get-v1projectsidlistings)
  - [Account and Enquiries](#account-and-enquiries)
    - [`GET /v1/me`](#get-v1me)
    - [`GET /v1/me/agencies`](#get-v1meagencies)
    - [`POST /v1/enquiries`](#post-v1enquiries)
    - [`POST /v1/statistics/{event}`](#post-v1statisticsevent)
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
| **Documented here** | Agents & Listings (Group 1). Properties & Locations is documented in `metadata-properties-and-locations.md` |
| **Credits** | 1,000/month per researcher; 1 credit per call |
| **Last reviewed** | 2026-05-22 |

For setup, authentication, credit budgeting, and known API quirks see the training guides in `training-materials/`.


## Coverage Summary

Offerings covered by this document (Group 1):

| Offering | Geography model | Temporal depth | Key constraints |
|---|---|---|---|
| Residential listings search | Suburb + postcode, or GeoJSON polygon | ~2000 to present; sparse before 2018 | Max 1,000 records per query |
| Commercial listings search | Suburb + postcode, or GeoJSON polygon | Current and recent listings | Max 1,000 records per query |
| Business listings search | Suburb + postcode, or GeoJSON polygon | Current and recent listings | Max 1,000 records per query |
| New development projects | Agency filter | Current and active | Child listings retrieved separately |

Offerings in the companion document (Group 2): weekly auction results, suburb performance statistics, demographics, property records, and location profiles.


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
## Group 1: Agents and Listings

*Access data on agents and listings directly from Domain.*

### Listings

---

#### `POST /v1/listings/residential/_search`
Search residential properties (sold, for-sale, for-rent).

**Data metadata**

| Category | Detail |
|---|---|
| Update frequency | Daily |
| Temporal coverage | Current and past listings; goes back to year 2000. Sold listings are limited to properties that were advertised on Domain's platform, not a complete record of all market transactions.|
| Data source | domain.com.au |
| Result cap | First 1,000 results only; refine search parameters if the result set exceeds this limit |

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `listingType` | string | optional | Whether the listing is offered for sale, for rent, share accommodation, represents a completed sale, or is a new-homes project | Allowed: `Sale`, `Rent`, `Share`, `Sold`, `NewHomes` |
| `propertyTypes` | array | optional | One or more property categories to filter by (e.g. house, apartment, townhouse) | See property type enum |
| `propertyFeatures` | array | optional | Specific amenities or attributes the property must have (e.g. pool, garage, air conditioning) | Allowed: `AirConditioning`, `BuiltInWardrobes`, `CableOrSatellite`, `Ensuite`, `Floorboards`, `Gas`, `InternalLaundry`, `PetsAllowed`, `SecureParking`, `SwimmingPool`, `Furnished`, `GroundFloor`, `WaterViews`, `NorthFacing`, `CityViews`, `IndoorSpa`, `Gym`, `AlarmSystem`, `Intercom`, `BroadbandInternetAccess`, `Bath`, `Fireplace`, `SeparateDiningRoom`, `Heating`, `Dishwasher`, `Study`, `TennisCourt`, `Shed`, `FullyFenced`, `BalconyDeck`, `GardenCourtyard`, `OutdoorSpa`, `DoubleGlazedWindows`, `EnergyEfficientAppliances`, `WaterEfficientAppliances`, `WallCeilingInsulation`, `RainwaterStorageTank`, `GreywaterSystem`, `WaterEfficientFixtures`, `SolarHotWater`, `SolarPanels` |
| `listingAttributes` | array | optional | Additional listing-level flags or tags applied by the advertiser | |
| `propertyEstablishedType` | string | optional | Whether to return new builds, established (previously owned) properties, or both | Allowed: `Any`, `New`, `Established` |
| `minBedrooms` | number | optional | Minimum number of bedrooms the property must have | |
| `maxBedrooms` | number | optional | Maximum number of bedrooms the property may have | |
| `minBathrooms` | number | optional | Minimum number of bathrooms the property must have | |
| `maxBathrooms` | number | optional | Maximum number of bathrooms the property may have | |
| `minCarspaces` | integer | optional | Minimum number of off-street parking spaces the property must have | |
| `maxCarspaces` | integer | optional | Maximum number of off-street parking spaces the property may have | |
| `minPrice` | integer | optional | Lower bound of the advertised price range in Australian dollars | |
| `maxPrice` | integer | optional | Upper bound of the advertised price range in Australian dollars | |
| `minLandArea` | integer | optional | Minimum land parcel size in square metres | |
| `maxLandArea` | integer | optional | Maximum land parcel size in square metres | |
| `advertiserIds` | array | optional | Filter results to listings posted by these specific agency or agent IDs | |
| `adIds` | array | optional | Filter results to this explicit set of listing IDs | |
| `excludeAdIds` | array | optional | Exclude these listing IDs from results | |
| `locations` | array | optional | Geographic scope for the search, specified as suburb/postcode objects or a GeoJSON polygon | Suburb+postcode objects or polygon |
| `schoolCatchments` | array | optional | School zones whose catchment boundaries define the search area | |
| `locationTerms` | string | optional | Free-text suburb or region name for a looser geographic match | |
| `keywords` | array | optional | Words or phrases that must appear in the listing description or headline | |
| `newDevOnly` | boolean | optional | Restrict results to new development listings only | |
| `inspectionFrom` | date-time | optional | Earliest date/time for open-home inspections to include | |
| `inspectionTo` | date-time | optional | Latest date/time for open-home inspections to include | |
| `auctionFrom` | date-time | optional | Earliest scheduled auction date to include | |
| `auctionTo` | date-time | optional | Latest scheduled auction date to include | |
| `dateAvailableFrom` | date-time | optional | Earliest date the property is available to move in or take possession | |
| `dateAvailableTo` | date-time | optional | Latest date the property is available to move in or take possession | |
| `ruralOnly` | boolean | optional | Restrict results to rural or acreage properties only | |
| `excludePriceWithheld` | boolean | optional | Omit listings where the advertiser has chosen not to display the price | |
| `excludeDepositTaken` | boolean | optional | Omit listings that have already had a deposit paid | |
| `topspotKeywords` | array | optional | Keywords used for premium placement logic in Domain search results | |
| `customSort` | object | optional | User-defined sort criteria object (fields and direction) | |
| `sort` | object | optional | Predefined sort order for the result set | |
| `pageSize` | integer | optional | Number of results to return per page | |
| `geoWindow` | object | optional | GeoJSON polygon defining a custom spatial search boundary | Polygon for spatial query |
| `updatedSince` | date-time | optional | Return only listings modified on or after this date/time | |
| `listedSince` | date-time | optional | Return only listings that were first advertised on or after this date | Filters by listing date, not sale date |
| `includeInspectionAggregations` | boolean | optional | Whether to include summarised inspection schedule data in the response | |
| `aggregations` | array | optional | Facets or counts to compute alongside the main search results | |
| `tags` | array | optional | Arbitrary tags applied to listings for filtering | |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | |

**Response fields**

Each result contains a `type` field (`PropertyListing` or `Project`) and a `listing` or `project` object.

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `type` | string | Indicates whether this result represents an individual property listing or a new-development project | `PropertyListing`, `Project` |
| `listing.promoLevel` | string | Advertising promotion tier purchased by the advertiser, affecting placement and visual prominence | `Standard`, `StandardPP`, `Elite`, `ElitePP`, `PremiumPlus` |
| `listing.listingType` | string | Market context of this listing (sale, rent, share, sold, or new homes) | `Sale`, `Rent`, `Share`, `Sold`, `NewHomes` |
| `listing.id` | integer | Unique Domain identifier for this listing | |
| `listing.projectId` | integer | ID of the parent development project this listing belongs to, if applicable | |
| `listing.advertiser.type` | string | Whether the listing is posted by a licensed agency or a private seller | `Agency`, `Private` |
| `listing.advertiser.id` | integer | Unique identifier for the advertising agency or private seller | |
| `listing.advertiser.name` | string | Trading name of the advertising agency or private seller | |
| `listing.advertiser.logoUrl` | string | URL of the advertiser's logo image | |
| `listing.advertiser.preferredColourHex` | string | Brand colour of the advertiser in hexadecimal format | |
| `listing.advertiser.bannerUrl` | string | URL of the advertiser's banner image | |
| `listing.advertiser.contacts[].name` | string | Full name of the individual agent contact for this listing | |
| `listing.advertiser.contacts[].photoUrl` | string | URL of the agent contact's profile photo | |
| `listing.priceDetails.price` | integer | Exact advertised price in Australian dollars | |
| `listing.priceDetails.priceFrom` | integer | Lower end of the advertised price range in Australian dollars | |
| `listing.priceDetails.priceTo` | integer | Upper end of the advertised price range in Australian dollars | |
| `listing.priceDetails.displayPrice` | string | Human-readable price string formatted for display (e.g. "$850,000 – $900,000") | |
| `listing.media[].category` | string | Type of media asset attached to the listing | `Image` |
| `listing.media[].url` | string | URL of the media asset | |
| `listing.propertyDetails.state` | string | Australian state or territory where the property is located | `ACT`, `NSW`, `QLD`, `VIC`, `SA`, `WA`, `NT`, `TAS` |
| `listing.propertyDetails.features` | array[string] | List of amenities or attributes the property has (e.g. pool, dishwasher) | |
| `listing.propertyDetails.propertyType` | string | Primary property category (e.g. house, apartment, townhouse) | See property type enum |
| `listing.propertyDetails.allPropertyTypes` | array[string] | All applicable property categories, including secondary types | |
| `listing.propertyDetails.bathrooms` | number | Number of bathrooms in the property | |
| `listing.propertyDetails.bedrooms` | number | Number of bedrooms in the property | |
| `listing.propertyDetails.carspaces` | integer | Number of off-street car parking spaces | |
| `listing.propertyDetails.unitNumber` | string | Unit or apartment number within a multi-dwelling building | |
| `listing.propertyDetails.streetNumber` | string | Street number component of the property address | |
| `listing.propertyDetails.street` | string | Street name component of the property address | |
| `listing.propertyDetails.area` | string | Broader geographic area name the suburb belongs to | |
| `listing.propertyDetails.region` | string | Regional grouping name for the suburb | |
| `listing.propertyDetails.suburb` | string | Suburb name where the property is located | |
| `listing.propertyDetails.suburbId` | integer | Domain's internal numeric identifier for the suburb | |
| `listing.propertyDetails.postcode` | string | Four-digit Australian postcode for the property | |
| `listing.propertyDetails.displayableAddress` | string | Formatted address string ready for display in a UI | |
| `listing.propertyDetails.latitude` | number | Geographic latitude coordinate of the property | |
| `listing.propertyDetails.longitude` | number | Geographic longitude coordinate of the property | |
| `listing.propertyDetails.mapCertainty` | integer | Confidence score indicating how accurately the coordinates match the physical address | |
| `listing.propertyDetails.landArea` | number | Total land parcel area in square metres | |
| `listing.propertyDetails.buildingArea` | number | Internal floor area of the building in square metres | |
| `listing.propertyDetails.onlyShowProperties` | array[string] | Restrictions on which properties within a complex should be displayed | |
| `listing.propertyDetails.displayAddressType` | string | Level of address detail that should be shown publicly | |
| `listing.propertyDetails.isRural` | boolean | Whether the property is classified as rural or acreage | |
| `listing.propertyDetails.topSpotKeywords` | array[string] | Keywords associated with premium placement in search results | |
| `listing.propertyDetails.isNew` | boolean | Whether the property is a newly constructed dwelling | |
| `listing.propertyDetails.tags` | array[string] | Arbitrary classification tags attached to the property record | |
| `listing.headline` | string | Short marketing headline written by the advertiser | |
| `listing.summaryDescription` | string | Brief marketing description of the property | |
| `listing.hasFloorplan` | boolean | Whether a floorplan image is attached to this listing | |
| `listing.hasVideo` | boolean | Whether a video tour is attached to this listing | |
| `listing.labels` | array[string] | Promotional or status labels applied to the listing (e.g. "Open for Inspection") | |
| `listing.auctionSchedule.time` | date-time | Date and time when the property auction is scheduled to take place | |
| `listing.auctionSchedule.auctionLocation` | string | Address or venue where the auction will be conducted | |
| `listing.dateAvailable` | date-time | Date from which the property is available to occupy or take possession | |
| `listing.dateListed` | date-time | Date the listing was first published on Domain | |
| `listing.inspectionSchedule.byAppointment` | boolean | Whether viewings are arranged individually rather than at fixed open-home times | |
| `listing.inspectionSchedule.recurring` | boolean | Whether the open-home inspection repeats on a regular schedule | |
| `listing.inspectionSchedule.times[].openingTime` | date-time | Date and time when an open-home inspection session begins | |
| `listing.inspectionSchedule.times[].closingTime` | date-time | Date and time when an open-home inspection session ends | |
| `listing.soldData.source` | string | Origin of the sold-price data (reported by the agency or sourced from APM records) | `Agency`, `Apm` |
| `listing.soldData.saleMethod` | string | How the sale was conducted (auction, private treaty, withdrawn, etc.) | `NotStated`, `SoldByAuction`, `SoldByPrivateTreaty`, `Withdrawn`, `SoldPriorToAuction` |
| `listing.soldData.soldDate` | date-time | Date on which the property sale was completed | |
| `listing.soldData.soldPrice` | integer | Final sale price in Australian dollars | |
| `listing.listingSlug` | string | URL-friendly identifier for this listing used in Domain page URLs | |
| `project.promoLevel` | string | Advertising promotion tier for the development project | `Standard`, `Premium` |
| `project.state` | string | Australian state where the development project is located | |
| `project.id` | integer | Unique Domain identifier for the development project | |
| `project.name` | string | Marketing name of the development project | |
| `project.bannerUrl` | string | URL of the project's banner image | |
| `project.preferredColorHex` | string | Brand colour for the project in hexadecimal format | |
| `project.logoUrl` | string | URL of the developer's or project's logo image | |
| `project.labels` | array[string] | Status or promotional labels applied to the project listing | |
| `project.displayableAddress` | string | Formatted address of the project site ready for display | |
| `project.suburb` | string | Suburb where the development project is located | |
| `project.suburbId` | integer | Domain's internal numeric identifier for the project's suburb | |
| `project.features` | array[string] | List of features or inclusions offered across the development | |
| `project.media[].category` | string | Type of media asset attached to the project | |
| `project.media[].url` | string | URL of the media asset | |
| `project.projectSlug` | string | URL-friendly identifier for this project used in Domain page URLs | |

**`propertyType` enum:** `Unknown`, `AcreageSemiRural`, `ApartmentUnitFlat`, `BlockOfUnits`, `CarSpace`, `DevelopmentSite`, `Duplex`, `Farm`, `House`, `NewHouseLand`, `NewLand`, `NewApartments`, `Penthouse`, `RetirementVillage`, `Rural`, `SemiDetached`, `Studio`, `Terrace`, `Townhouse`, `VacantLand`, `Villa`, `RuralLifestyle` (and others for rural/farming categories)

---

#### `POST /v1/listings/commercial/_search`
Search commercial real estate listings.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | |
| `advertiserId` | integer | optional | Filter results to listings posted by this specific agency ID | Agency ID |
| `pageSize` | integer | optional | Number of results to return per page | |
| `propertyTypes` | array | optional | One or more commercial property categories to filter by (e.g. office, retail, industrial) | |
| `price` | object | optional | Price range filter object with minimum and/or maximum values in Australian dollars | Min/max price |
| `locations` | array | optional | Geographic scope for the search as suburb/postcode objects or a polygon | |
| `keywords` | array | optional | Words or phrases that must appear in the listing description | |
| `geoWindow` | object | optional | GeoJSON polygon defining a custom spatial search boundary | Polygon |
| `landAreaMin` | integer | optional | Minimum land parcel size in square metres | |
| `landAreaMax` | integer | optional | Maximum land parcel size in square metres | |
| `buildingSizeMin` | integer | optional | Minimum building floor area in square metres | |
| `buildingSizeMax` | integer | optional | Maximum building floor area in square metres | |
| `searchMode` | string | optional | Whether to search for properties currently for sale, for lease, or completed transactions | `forSale`, `forLease`, `sold`, `leased` |
| `occupancy` | string | optional | Tenancy status of the commercial property (e.g. vacant, tenanted) | |
| `sort` | string | optional | Sort order applied to the result set | `default`, `newestFirst`, `cheapestTotalFirst`, `cheapestPerSqmFirst`, `mostExpensiveTotalFirst`, `mostExpensivePerSqmFirst`, `suburbAsc`, `suburbDesc`, `buildingSizeAsc`, `buildingSizeDesc` |
| `saleType` | string | optional | Method by which the property is being sold or offered | `standardSale`, `auction`, `expressionOfInterest`, `tender` |
| `propertyTitle` | string | optional | Nature of the land or building title (freehold, strata, etc.) | `freehold`, `strata`, `noBuilding` |
| `parking` | object | optional | Parking availability filter object | |
| `exclusionTypes` | array | optional | Property sub-types to exclude from results | |
| `annualReturn` | integer | optional | Minimum expected annual investment return as a percentage | Minimum annual return (%) |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `ad.adType` | string | Product category or placement tier for this commercial advertisement | Product type |
| `ad.url` | string | URL to the full commercial property details page on Domain | Property details URL |
| `price` | string | Formatted price string for display (e.g. "$2,500,000" or "$450/sqm") | Formatted listing price |
| `advertiser.address` | string | Street address of the advertising agency's office | |
| `advertiser.id` | integer | Unique identifier for the advertising agency | Agency ID |
| `advertiser.name` | string | Trading name of the advertising agency | |
| `advertiser.preferredColorHex` | string | Brand colour of the advertising agency in hexadecimal format | |
| `advertiser.images.agencyBannerImageUrl` | string | URL of the agency's standard banner image | |
| `advertiser.images.agencyBannerWideImageUrl` | string | URL of the agency's wide-format banner image | |
| `advertiser.images.logoUrl` | string | URL of the agency's logo image | |
| `advertiser.contacts[].id` | integer | Unique identifier for this agent contact | |
| `advertiser.contacts[].firstName` | string | Agent contact's first name | |
| `advertiser.contacts[].lastName` | string | Agent contact's last name | |
| `advertiser.contacts[].imageUrl` | string | URL of the agent contact's profile photo | |
| `advertiser.contacts[].displayFullName` | string | Agent's full name formatted for display | |
| `advertiser.contacts[].phoneNumbers[].displayLabel` | string | Human-readable label for this phone number (e.g. "Mobile", "Office") | |
| `advertiser.contacts[].phoneNumbers[].type` | string | Classification of the phone number | `fax`, `mobile`, `telephone` |
| `advertiser.contacts[].phoneNumbers[].number` | string | The phone number string | |
| `advertiser.contacts[].emailAddress` | string | Agent contact's email address | |
| `advertiser.contacts[].address` | string | Agent contact's office or business address | |
| `advertiser.isConjunctional` | boolean | Whether the listing is being marketed jointly by more than one agency | |
| `geoLocation.latitude` | number | Geographic latitude coordinate of the property | |
| `geoLocation.longitude` | number | Geographic longitude coordinate of the property | |
| `propertyArea` | string | Building floor area formatted as a display string (e.g. "450 sqm") | Building size display |
| `propertyType` | string | Commercial property category (e.g. office, retail, industrial) | |
| `address` | string | Full formatted street address of the property | Full address |
| `headline` | string | Short marketing headline written by the advertiser | |
| `hasVideo` | boolean | Whether a video tour is attached to this listing | |
| `media[].dateCreated` | date-time | Date and time when this media asset was uploaded | |
| `media[].imageUrl` | string | URL of the image asset | |
| `media[].mediaType` | string | Broad classification of the media asset (image or video) | `image`, `video` |
| `media[].type` | string | Specific format or hosting platform of the video asset | `youtube`, `vimeo`, `mp4` |
| `media[].videoUrl` | string | URL of the video asset | |
| `auctionDate` | string | Scheduled date of the property auction | |
| `id` | integer | Unique Domain identifier for this commercial listing | Ad ID |
| `metadata.addressComponents.area` | string | Broader geographic area name the suburb belongs to | |
| `metadata.addressComponents.district` | string | District name for the property's location | |
| `metadata.addressComponents.postcode` | string | Four-digit Australian postcode for the property | |
| `metadata.addressComponents.region` | string | Regional grouping name for the suburb | |
| `metadata.addressComponents.stateShort` | string | Abbreviated state or territory code | 2-3 character state abbreviation |
| `metadata.addressComponents.street` | string | Street name component of the property address | |
| `metadata.addressComponents.streetNumber` | string | Street number component of the property address | |
| `metadata.addressComponents.suburb` | string | Suburb name where the property is located | |
| `metadata.addressComponents.unitNumber` | string | Unit or suite number within a multi-tenancy building | |
| `carspaceCount` | integer | Number of car parking spaces included with the commercial property | |

---

#### `POST /v1/listings/business/_search`
Search business-for-sale listings.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | |
| `advertiserId` | integer | optional | Filter results to listings posted by this specific agency ID | Agency ID |
| `propertyTypes` | array | optional | Business categories to filter by (e.g. retail, hospitality, franchise) | |
| `keywords` | array | optional | Words or phrases that must appear in the business listing description | |
| `brandId` | integer | optional | Filter by a specific franchise brand identifier | Franchise brand ID |
| `franchiseGroupId` | integer | optional | Filter by a specific franchise group identifier | Franchise group ID |
| `locations` | array | optional | Geographic scope for the search as suburb/postcode objects | |
| `pageSize` | integer | optional | Number of results to return per page | |
| `price` | object | optional | Price range filter object with minimum and/or maximum values in Australian dollars | Min/max price |
| `sort` | string | optional | Sort order applied to the result set | `default`, `newestFirst`, `lowTotalPriceFirst`, `hightTotalPriceFirst`, `suburbAsc`, `suburbDesc` |
| `searchMode` | string | optional | Whether to search active for-sale listings, franchise opportunities, or franchise brands | `forSale`, `franchiseOpportunity`, `franchiseBrand` |

**Response fields:** Same structure as `/v1/listings/commercial/_search` response.

---

#### `GET /v1/listings/{id}`
Retrieve full details of a single listing.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain listing identifier for the specific property listing to retrieve | Domain listing ID |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `objective` | string | Whether the listing intent is to sell or rent the property | `sale`, `rent` |
| `status` | string | Current lifecycle state of the listing on the Domain platform | `unknown`, `archived`, `underOffer`, `sold`, `leased`, `newDevelopment`, `recentlyUpdated`, `new`, `live`, `pending`, `depositTaken` |
| `saleMode` | string | Broad market channel the listing belongs to | `buy`, `rent`, `share`, `sold`, `leased`, `archived` |
| `channel` | string | Property sector the listing is classified under | `residential`, `commercial`, `business` |
| `id` | integer | Unique Domain numeric identifier for this listing | Listing identifier |
| `addressParts.stateAbbreviation` | string | Two- or three-letter abbreviation for the Australian state or territory | `nsw`, `vic`, `sa`, `nt`, `tas`, `act`, `qld`, `wa` |
| `addressParts.displayType` | string | Level of address detail publicly visible for this listing | `fullAddress`, `streetAndSuburb`, `suburbOnly`, `regionOnly`, `areaOnly`, `stateOnly` |
| `addressParts.streetNumber` | string | Street number component of the property address | |
| `addressParts.unitNumber` | string | Unit or apartment number within a multi-dwelling building | |
| `addressParts.street` | string | Street name component of the property address | |
| `addressParts.suburb` | string | Suburb name where the property is located | |
| `addressParts.suburbId` | integer | Domain's internal numeric identifier for the suburb | Domain suburb identifier |
| `addressParts.postcode` | string | Four-digit Australian postcode for the property | |
| `addressParts.displayAddress` | string | Formatted address string ready for display in a UI | |
| `advertiserIdentifiers.advertiserType` | string | Whether the listing is posted by a licensed agency or a private seller | `agency`, `private` |
| `advertiserIdentifiers.advertiserId` | integer | Unique identifier for the advertising agency or private seller | |
| `advertiserIdentifiers.contactIds` | array[integer] | Internal IDs of the agent contacts associated with this listing | |
| `advertiserIdentifiers.agentIds` | array[string] | String-format agent identifiers associated with this listing | |
| `advertiserIdentifiers.conjunctionContactIds` | array[integer] | Contact IDs for co-advertising agents from another agency | |
| `advertiserIdentifiers.conjunctionAgentIds` | array[string] | Agent IDs for co-advertising agents from another agency | |
| `apmIdentifiers.addressId` | integer | APM (Australian Property Monitors) internal address identifier | APM address identifier |
| `apmIdentifiers.streetId` | integer | APM internal street identifier | |
| `apmIdentifiers.suburbId` | integer | APM internal suburb identifier | |
| `apmIdentifiers.cadastreId` | integer | APM land cadastre record identifier | |
| `apmIdentifiers.postcodeId` | integer | APM internal postcode identifier | |
| `apmIdentifiers.stateId` | integer | APM internal state identifier | |
| `apmIdentifiers.state` | string | State abbreviation as used in APM records | |
| `apmIdentifiers.propertyTypeId` | integer | APM numeric code for the property type | |
| `apmIdentifiers.propertyTypeCategoryId` | integer | APM numeric code for the broad property category | |
| `apmIdentifiers.streetNumber` | string | Street number as standardised and stored in APM records | Standardised street number |
| `bathrooms` | number | Number of bathrooms in the property | |
| `bedrooms` | number | Number of bedrooms in the property (studio apartments carry a value of 0) | Studio apartments have value 0 |
| `buildingArea` | string | Internal floor area of the building formatted as a human-readable string | Display string e.g. "160 sqm" |
| `buildingAreaSqm` | number | Internal floor area of the building in square metres as a numeric value | |
| `carspaces` | number | Number of off-street car parking spaces | |
| `dateAvailable` | date-time | Date from which the property is available to occupy or take possession | |
| `dateCreated` | date-time | Date and time when the listing was first created on the Domain platform | AEST/AEDT |
| `dateUpdated` | date-time | Date and time when the listing was last meaningfully updated | AEST/AEDT |
| `dateMinorUpdated` | date-time | Date and time when the listing last received a minor or administrative update | AEST/AEDT |
| `datePurged` | date-time | Date and time when an archived listing was permanently removed from the platform | Only for archived listings |
| `dateListed` | date-time | Date and time when the listing was first published on Domain | AEST/AEDT |
| `description` | string | Full marketing description of the property written by the advertiser | Long description |
| `devProjectId` | integer | ID of the parent new-development project this listing is part of | Associated development project ID |
| `energyEfficiencyRating` | integer | ACT government energy efficiency star rating for the property | ACT properties only |
| `features` | array[string] | List of amenities and attributes the property has (e.g. pool, dishwasher, air conditioning) | |
| `geoLocation.latitude` | number | Geographic latitude coordinate of the property | |
| `geoLocation.longitude` | number | Geographic longitude coordinate of the property | |
| `headline` | string | Short marketing headline written by the advertiser | Short description |
| `inspectionDetails.inspections[].recurrence` | string | Whether this inspection session is a one-off or repeats weekly | `none`, `weekly` |
| `inspectionDetails.inspections[].openingDateTime` | date-time | Date and time when an upcoming inspection session begins | |
| `inspectionDetails.inspections[].closingDateTime` | date-time | Date and time when an upcoming inspection session ends | |
| `inspectionDetails.inspections[].description` | string | Free-text description of the inspection, used for bulk-uploaded listings | Used for bulk-uploaded listings |
| `inspectionDetails.pastInspections[].recurrence` | string | Whether the past inspection was a one-off or recurring session | |
| `inspectionDetails.pastInspections[].openingDateTime` | date-time | Date and time when the past inspection session began | |
| `inspectionDetails.pastInspections[].closingDateTime` | date-time | Date and time when the past inspection session ended | |
| `inspectionDetails.pastInspections[].description` | string | Free-text description of the past inspection session | |
| `inspectionDetails.isByAppointmentOnly` | boolean | Whether all viewings for this listing are arranged individually by appointment | |
| `isNewDevelopment` | boolean | Whether this listing is part of a new-development project | |
| `isWithdrawn` | boolean | Whether the listing has been taken off the market without completing a sale or lease | Taken off market without sale/lease |
| `landArea` | string | Total land parcel area formatted as a human-readable string | Display string |
| `landAreaSqm` | number | Total land parcel area in square metres as a numeric value | |
| `media[].category` | string | Broad classification of the attached media asset | `image`, `video`, `others` |
| `media[].type` | string | Specific format or hosting platform of the media asset | `photo`, `mp4`, `youtube`, `floorplan`, `vimeo`, `notSpecified` |
| `media[].url` | string | URL to access the media asset | |
| `numberOfDwellings` | integer | Number of separate dwellings contained on the property | |
| `highlights` | array[string] | Curated key features or selling points highlighted by the advertiser | |
| `homepassEnabled` | boolean | Whether the property supports the Homepass digital open-home check-in product | |
| `priceDetails.gstOption` | string | How GST applies to the commercial listing price | `na`, `inc`, `ex` |
| `priceDetails.priceType` | string | Whether the commercial price is quoted as a gross or net figure | `gross`, `net` |
| `priceDetails.priceUnit` | string | Whether the price applies to the total property or per square metre | `totalAmount`, `perSqm` |
| `priceDetails.price` | number | Exact advertised price in Australian dollars | |
| `priceDetails.priceFrom` | integer | Lower end of the advertised price range in Australian dollars | |
| `priceDetails.priceTo` | integer | Upper end of the advertised price range in Australian dollars | |
| `priceDetails.pricePrefix` | string | Text prefix displayed before the price (e.g. "From", "Offers above") | |
| `priceDetails.canDisplayPrice` | boolean | Whether the advertiser has permitted the price to be shown publicly | |
| `priceDetails.hiddenReasons` | array[string] | Reasons why the price is not being displayed publicly | |
| `priceDetails.displayPrice` | string | Human-readable price string formatted for display | Use this field for display |
| `priceDetails.bond` | number | Rental bond amount in Australian dollars | Rental bond |
| `priceDetails.priceReduction` | boolean | Whether the listed price has been reduced from an earlier advertised price | |
| `propertyId` | string | Domain's alphanumeric property record identifier (links the listing to a permanent property record) | Domain property identifier |
| `propertyTypes` | array[string] | All property type categories that apply to this listing | |
| `providerDetails.providerSystem` | string | Identifier for the data feed system that submitted this listing | Feed provider ID |
| `providerDetails.providerAdID` | string | Listing ID as assigned by the third-party feed provider | |
| `rentalDetails.rentalMethod` | string | How the rental agreement is structured (standard rent, share, holiday let, or lease) | `notStated`, `rent`, `share`, `holiday`, `lease` |
| `rentalDetails.source` | string | Whether rental details were entered internally or supplied by an external data feed | `internal`, `external` |
| `rentalDetails.leasedDate` | date-time | Date on which the rental agreement was signed and the property became leased | |
| `rentalDetails.leasedPrice` | integer | Weekly rent agreed at the time of leasing in Australian dollars | |
| `rentalDetails.canDisplayPrice` | boolean | Whether the advertiser has permitted the rent price to be shown publicly | |
| `rentalDetails.leasedMonths` | integer | Duration of the lease in months | |
| `rentalDetails.termOfLeaseFrom` | integer | Minimum lease term offered in months | |
| `rentalDetails.termOfLeaseTo` | integer | Maximum lease term offered in months | |
| `rentalDetails.leaseOutgoings` | integer | Annual outgoings payable by the lessee in Australian dollars | |
| `saleDetails.saleMethod` | string | Method by which the property is being offered for sale | `notStated`, `auction`, `privateTreaty`, `tender`, `expressionOfInterest` |
| `saleDetails.soldDetails.soldAction` | string | How the sale was ultimately concluded | `notStated`, `auction`, `privateTreaty`, `withdrawn`, `soldPriorToAuction` |
| `saleDetails.soldDetails.source` | string | Whether the sale data was recorded internally or sourced externally | `internal`, `external` |
| `saleDetails.soldDetails.soldPrice` | integer | Final agreed sale price in Australian dollars | |
| `saleDetails.soldDetails.governmentRecordedSoldPrice` | integer | Sale price as recorded in official government title transfer records | Sourced from APM |
| `saleDetails.soldDetails.soldDate` | date-time | Date on which the property sale was completed | |
| `saleDetails.soldDetails.canDisplayPrice` | boolean | Whether the sold price may be displayed publicly | |
| `saleDetails.auctionDetails.auctionSchedule.locationDescription` | string | Address or venue description for the auction event | |
| `saleDetails.auctionDetails.auctionSchedule.openingDateTime` | date-time | Scheduled date and time for the start of the auction | |
| `saleDetails.auctionDetails.auctionSchedule.terms` | string | Terms and conditions that apply to bidding at this auction | |
| `saleDetails.auctionDetails.auctionSchedule.url` | string | URL to additional information about the auction event | |
| `saleDetails.auctionDetails.auctionedPrice` | integer | Price achieved or highest bid recorded at auction | |
| `saleDetails.auctionDetails.auctionedDate` | date-time | Date on which the property was auctioned | |
| `saleDetails.tenderDetails.tenderRecipientName` | string | Name of the party to whom tender submissions should be addressed | |
| `saleDetails.tenderDetails.tenderAddress` | string | Address to which sealed tender documents must be submitted | |
| `saleDetails.tenderDetails.tenderEndDate` | date-time | Closing date and time by which all tender submissions must be received | |
| `saleDetails.tenantDetails.leaseDateVariable` | boolean | Whether the lease commencement date is flexible or subject to negotiation | |
| `saleDetails.tenantDetails.leaseOptions` | string | Description of any renewal or extension options available under the lease | |
| `saleDetails.tenantDetails.tenantInfoTermOfLeaseFrom` | integer | Minimum remaining lease term in months as disclosed by the vendor | |
| `saleDetails.tenantDetails.tenantInfoTermOfLeaseTo` | integer | Maximum remaining lease term in months as disclosed by the vendor | |
| `saleDetails.tenantDetails.tenantName` | string | Name of the current tenant occupying the investment property | |
| `saleDetails.tenantDetails.tenantRentDetails` | string | Description of the current rental income or rent schedule | |
| `saleDetails.tenantDetails.leaseStartDate` | date-time | Date on which the existing tenancy agreement commenced | |
| `saleDetails.tenantDetails.leaseEndDate` | date-time | Date on which the existing tenancy agreement is due to expire | |
| `saleDetails.annualReturn` | integer | Expected annual investment yield for the property as a percentage | |
| `saleDetails.saleTerms` | string | Special conditions or terms attached to the sale of the property | |
| `seoUrl` | string | Search-engine-optimised URL path for this listing on Domain | |
| `virtualTourUrl` | string | URL to an interactive 3D or 360-degree virtual tour of the property | |
| `statementOfInformation.estimatedPrice.from` | integer | Lower bound of the vendor's estimated price range as declared in the statement of information | |
| `statementOfInformation.estimatedPrice.to` | integer | Upper bound of the vendor's estimated price range as declared in the statement of information | |
| `statementOfInformation.comparableData.comparableProperty[].unitNumber` | string | Unit number of a comparable recently sold property used as a price reference | |
| `statementOfInformation.comparableData.comparableProperty[].streetNumber` | string | Street number of a comparable recently sold property | |
| `statementOfInformation.comparableData.comparableProperty[].street` | string | Street name of a comparable recently sold property | |
| `statementOfInformation.comparableData.comparableProperty[].suburb` | string | Suburb of a comparable recently sold property | |
| `statementOfInformation.comparableData.comparableProperty[].postcode` | string | Postcode of a comparable recently sold property | |
| `statementOfInformation.comparableData.comparableProperty[].state` | string | State of a comparable recently sold property | |
| `statementOfInformation.comparableData.comparableProperty[].displayAddress` | string | Formatted address of the comparable property for display | |
| `statementOfInformation.comparableData.comparableProperty[].dateOfSale` | string | Date on which the comparable property was sold | |
| `statementOfInformation.comparableData.comparableProperty[].soldPrice` | integer | Price achieved when the comparable property was sold | |
| `statementOfInformation.comparableData.declarationText` | string | Statutory declaration text used when fewer than three comparable sales are available | When fewer than 3 comparable sales |
| `statementOfInformation.suburbMedianPrice.priceType` | string | Property category used to calculate the reported suburb median price | `house`, `apartmentUnitFlat`, `vacantLand` |
| `statementOfInformation.suburbMedianPrice.suburb` | string | Suburb for which the median price is reported | |
| `statementOfInformation.suburbMedianPrice.postcode` | string | Postcode of the suburb for which the median price is reported | |
| `statementOfInformation.suburbMedianPrice.medianPrice` | integer | Median sale price for properties of this type in this suburb | |
| `statementOfInformation.suburbMedianPrice.source` | string | Data provider that supplied the median price figure | |
| `statementOfInformation.suburbMedianPrice.sourceDateFrom` | string | Start of the period over which the median price was calculated | |
| `statementOfInformation.suburbMedianPrice.sourceDateTo` | string | End of the period over which the median price was calculated | |
| `statementOfInformation.suburbMedianPrice.sourceCollectionDate` | string | Date on which the source data was collected or published | |
| `statementOfInformation.documentationUrl` | string | URL to the full Statement of Information PDF document | |

---

#### `GET /v1/listings/locations`
Suggest suburb, area, or region names and postcodes for use as search inputs.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `terms` | string | optional | Suburb name prefix or postcode digits to search for matching location suggestions | Suburb name prefix or postcode |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `name` | string | Display name of the matched suburb, area, or region | |
| `state` | string | Australian state or territory the location belongs to | |
| `postcode` | string | Four-digit Australian postcode for the location | |
| `area` | string | Broader geographic area grouping the location belongs to | |
| `region` | string | Regional grouping the location belongs to | |
| `type` | string | Classification of the matched result (suburb, area, or region) | |



### Agencies

---

#### `GET /v1/agencies`
Search agencies.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `q` | string | optional | Search phrase to match against agency names and details | Search phrase, e.g. `name:"Agency XYZ"` |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | Default: 1 |
| `pageSize` | integer | optional | Number of results to return per page | Default: 20 |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `inSuburb` | boolean | Whether the agency's office is physically located in the suburb that was searched | Whether agency office is in the queried suburb |
| `querySuburb` | string | The suburb name that was used in the search query | |
| `hasRecentlySold` | boolean | Whether the agency has recent sold listings in the searched suburb | |
| `id` | integer | Unique Domain identifier for the agency | |
| `name` | string | Trading name of the real estate agency | |
| `suburb` | string | Suburb where the agency's office is located | |
| `logoUrl` | string | URL of the agency's logo image | |
| `baseUrl` | string | Base URL path for the agency's profile on Domain | |
| `address1` | string | First line of the agency's street address | First line of street address |
| `address2` | string | Second line of the agency's street address | Second line of street address |
| `telephone` | string | Agency's primary telephone number | |
| `rentalTelephone` | string | Agency's dedicated rental department telephone number | |
| `mobile` | string | Agency's mobile phone number | |
| `fax` | string | Agency's fax number | |
| `state` | string | Australian state or territory where the agency operates | |
| `description` | string | Marketing description of the agency and its services | |
| `email` | string | Agency's primary email address | |
| `rentalEmail` | string | Agency's dedicated rental department email address | |
| `homePageSearchOptions` | string | Configuration options for the agency's search preferences on its homepage | |
| `accountType` | integer | Numeric code representing the agency's Domain subscription tier | Numerical code |
| `numberForSale` | integer | Number of residential properties the agency currently has listed for sale | |
| `numberForRent` | integer | Number of residential properties the agency currently has listed for rent | |
| `domainUrl` | string | URL path fragment linking to the agency's profile page on Domain | URL fragment within Domain |
| `showTabSoldLastYear` | boolean | Whether to display a tab showing the agency's properties sold in the past year | |

---

#### `HEAD /v1/agencies`
Check agency search result count without retrieving bodies.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `q` | string | optional | Search phrase to match against agency names | Search phrase |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | Default: 1 |
| `pageSize` | integer | optional | Number of results counted per page | Default: 20 |

**Response:** HTTP headers only. Result count in `X-Total-Count` header.

---

#### `GET /v1/agencies/{id}`
Retrieve full profile of a specific agency.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain numeric identifier for the agency to retrieve | Agency identifier |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | integer | Unique Domain identifier for the agency | |
| `creId` | integer | Commercial Real Estate (CRE) identifier for the agency | |
| `name` | string | Trading name of the real estate agency | |
| `accountType` | string | The agency's Domain subscription account category | `none`, `residential`, `commercialLight`, `commercialFull`, `developer`, `holiday`, `business` |
| `dateUpdated` | date-time | Date and time when the agency profile was last updated | |
| `welcomeMessage` | string | Personalised welcome message shown on the agency's profile page | |
| `adFormat` | string | Advertisement display format preference for the agency | |
| `providerAgencyId` | string | Agency identifier as assigned by the third-party data feed provider | |
| `homepassEnabled` | boolean | Whether the agency uses the Homepass digital open-home product | |
| `suburbsServed` | string | List of suburbs where the agency actively operates | |
| `subscribedToAgencyPerformanceReport` | boolean | Whether the agency receives automated performance report emails | |
| `profile.agencyPhotos[].url` | string | URL of a photo in the agency's profile gallery | |
| `profile.profileWebsite` | string | URL of the agency's Domain profile page | |
| `profile.agencyBanner` | string | URL of the agency's profile banner image | |
| `profile.agencyWebsite` | string | URL of the agency's own external website | |
| `profile.agencyLogoStandard` | string | URL of the agency's standard-resolution logo image | |
| `profile.agencyLogoSmall` | string | URL of the agency's small-resolution logo image | |
| `profile.logoColour` | string | Primary brand colour for the agency logo in hexadecimal format | Hex code |
| `profile.primaryAgencyColour` | string | Primary brand colour used across the agency's Domain presence | |
| `profile.backgroundColour` | string | Background colour for the agency's Domain profile in hexadecimal format | Hex code |
| `profile.mapLatitude` | string | Latitude coordinate used to pin the agency's office on a map | |
| `profile.mapLongitude` | string | Longitude coordinate used to pin the agency's office on a map | |
| `profile.mapCertainty` | integer | Confidence score for the accuracy of the agency's map location | |
| `profile.agencyVideoUrl` | string | URL of a promotional video for the agency | |
| `profile.agencyDescription` | string | Full description of the agency and its services, which may contain HTML markup | May include HTML |
| `profile.agencyDescriptionCre` | string | Agency description tailored to commercial real estate context | |
| `profile.creProfileWebsite` | string | URL of the agency's CRE-specific profile page | |
| `profile.agencyCreBanner` | string | URL of the agency's CRE-specific banner image | |
| `profile.agencyCreWebsite` | string | URL of the agency's CRE-specific external website | |
| `profile.agencyCreLogoStandard` | string | URL of the agency's CRE-specific standard logo image | |
| `profile.numberForSale` | integer | Number of residential properties the agency currently has for sale | Residential for sale |
| `profile.numberForRent` | integer | Number of residential properties the agency currently has for rent | Residential for rent |
| `profile.numberForSaleCommercial` | integer | Number of commercial properties the agency currently has for sale | |
| `profile.numberForRentCommercial` | integer | Number of commercial properties the agency currently has for lease | |
| `profile.creAgencyVideoUrl` | string | URL of a promotional video focused on the agency's commercial activities | |
| `details.streetAddress1` | string | First line of the agency's registered street address | |
| `details.streetAddress2` | string | Second line of the agency's registered street address | |
| `details.suburb` | string | Suburb where the agency's office is registered | |
| `details.state` | string | Australian state where the agency is registered | |
| `details.postcode` | string | Postcode of the agency's registered address | |
| `details.agencyWebsite` | string | URL of the agency's own external website | |
| `details.principalName` | string | Name of the principal or licensee-in-charge of the agency | |
| `details.principalEmail` | string | Email address of the agency's principal or licensee-in-charge | |
| `details.showPastSalesPrices` | boolean | Whether the agency has opted to display historical sale prices on its profile | |
| `details.isAgencyReportEnabled` | boolean | Whether the agency performance report feature is active for this agency | |
| `details.salesEmail` | string | Email address for the agency's residential sales team | |
| `details.rentalEmail` | string | Email address for the agency's residential rentals team | |
| `details.isPromotionalTelephoneActive` | boolean | Whether the agency is using a tracked promotional phone number | |
| `details.hideMarketPriceEstimate` | boolean | Whether the agency has opted to hide automated price estimates on its listings | |
| `details.limitEmailDomain` | boolean | Whether the agency restricts incoming enquiry emails to specific domains | |
| `details.showTabSoldLastYear` | boolean | Whether to display a sold-in-the-last-year tab on the agency's profile | |
| `agents[].agencyId` | integer | ID of the agency this agent is associated with | |
| `agents[].id` | integer | Unique Domain identifier for the agent | |
| `agents[].email` | string | Agent's primary email address | |
| `agents[].firstName` | string | Agent's first name | |
| `agents[].lastName` | string | Agent's last name | |
| `agents[].mobile` | string | Agent's mobile phone number | |
| `agents[].photo` | string | URL of the agent's profile photograph | |
| `agents[].phone` | string | Agent's office or direct phone number | |
| `agents[].fax` | string | Agent's fax number | |
| `agents[].isActiveProfilePage` | string | Whether the agent currently has an active public profile page | |
| `agents[].saleActive` | boolean | Whether the agent is currently accepting sales enquiries | |
| `agents[].rentalActive` | boolean | Whether the agent is currently handling rental enquiries | |
| `agents[].secondaryEmail` | string | Agent's secondary or alternate email address | |
| `agents[].facebookUrl` | string | URL of the agent's Facebook profile page | |
| `agents[].twitterUrl` | string | URL of the agent's Twitter/X profile page | |
| `agents[].linkedInUrl` | string | URL of the agent's LinkedIn profile page | |
| `agents[].googlePlusUrl` | string | URL of the agent's Google+ profile (legacy) | |
| `agents[].personalWebsiteUrl` | string | URL of the agent's personal professional website | |
| `agents[].agentVideo` | string | URL of a promotional video for the agent | |
| `agents[].profileText` | string | Biographical or marketing text for the agent's public profile | |
| `agents[].isHideSoldLeasedListings` | boolean | Whether the agent has opted to hide their past sold and leased listings | |
| `agents[].contactTypeCode` | integer | Numeric code representing the agent's role or contact classification | |
| `agents[].receivesRequests` | boolean | Whether the agent accepts property enquiry submissions | |
| `agents[].creAgentVideoURL` | string | URL of a promotional video for the agent's commercial activities | |
| `agents[].receiveScheduledReportEmail` | boolean | Whether the agent receives automated performance report emails | |
| `agents[].mugShotNew` | string | URL of the agent's updated profile headshot image | |
| `contactDetails.general.email` | string | Agency's general-purpose contact email address | |
| `contactDetails.general.fax` | string | Agency's general-purpose fax number | |
| `contactDetails.general.phone` | string | Agency's general-purpose phone number | |
| `contactDetails.general.mobile` | string | Agency's general-purpose mobile number | |
| `contactDetails.residentialSale.email` | string | Email address for residential sales enquiries | |
| `contactDetails.residentialSale.phone` | string | Phone number for residential sales enquiries | |
| `contactDetails.residentialRent.email` | string | Email address for residential rental enquiries | |
| `contactDetails.residentialRent.phone` | string | Phone number for residential rental enquiries | |
| `contactDetails.commercialSale.email` | string | Email address for commercial sales enquiries | |
| `contactDetails.commercialSale.phone` | string | Phone number for commercial sales enquiries | |
| `contactDetails.commercialLease.email` | string | Email address for commercial lease enquiries | |
| `contactDetails.commercialLease.phone` | string | Phone number for commercial lease enquiries | |
| `contactDetails.businessSale.email` | string | Email address for business-for-sale enquiries | |
| `contactDetails.businessSale.phone` | string | Phone number for business-for-sale enquiries | |
| `contactDetails.businessRent.email` | string | Email address for business-for-rent enquiries | |
| `contactDetails.businessRent.phone` | string | Phone number for business-for-rent enquiries | |
| `contactDetails.emailDomains[].domain` | string | Approved email domain used to limit inbound enquiries to known senders | |
| `agencyOptions.saleListingsGstOption` | integer | Default GST treatment applied to the agency's sale listing prices | |
| `agencyOptions.leaseListingsGstOption` | integer | Default GST treatment applied to the agency's lease listing prices | |
| `agencyOptions.receiveLookForPropertyRequests` | boolean | Whether the agency accepts "find me a property" buyer requests | |
| `agencyOptions.receiveSellPropertyRequests` | boolean | Whether the agency accepts "appraise my property" vendor requests | |
| `agencyOptions.receivePropertyValuationRequests` | boolean | Whether the agency accepts automated valuation report requests | |
| `agencyOptions.agentDirectoryListing` | boolean | Whether the agency appears in Domain's public agent directory | |

---

#### `GET /v1/agencies/{id}/listings`
Retrieve all active listings for a specific agency.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain identifier for the agency whose listings to retrieve | Agency ID |
| `listingStatusFilter` | string | optional | Whether to return only live listings or include archived ones as well | `live` (default), `liveAndArchived` |
| `dateUpdatedSince` | date-time | optional | Return only listings modified on or after this date and time | |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | Default: 1 |
| `pageSize` | integer | optional | Number of listings to return per page | Default: 20, max: 200 |

**Response fields:** Full listing objects, see `GET /v1/listings/{id}` response fields.



### Agents

---

#### `GET /v1/agents/search`
Search for agents by name.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `query` | string | required | Agent name or partial name to search for | Name or partial name |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | |
| `pageSize` | integer | optional | Number of results to return per page | Max: 20 |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `agentId` | integer | Unique Domain numeric identifier for the agent | |
| `name` | string | Agent's full name as displayed publicly | |
| `agencyName` | string | Name of the agency the agent is currently affiliated with | |
| `suburb` | string | Suburb where the agent primarily operates | |
| `state` | string | Australian state where the agent primarily operates | |
| `profileUrl` | string | URL to the agent's public profile page on Domain | |
| `thumbnail` | string | URL of the agent's profile thumbnail image | |

---

#### `GET /v1/agents/{id}`
Retrieve full profile of a specific agent.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain identifier for the agent whose profile to retrieve | Agent identifier |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `agentId` | integer | Unique Domain numeric identifier for the agent | |
| `agencyId` | integer | Unique Domain identifier for the agency the agent is affiliated with | |
| `firstName` | string | Agent's first name | |
| `lastName` | string | Agent's last name | |
| `email` | string | Agent's primary email address | |
| `secondaryEmail` | string | Agent's secondary or alternate email address | |
| `mobile` | string | Agent's mobile phone number | |
| `phone` | string | Agent's office or direct phone number | |
| `fax` | string | Agent's fax number | |
| `photo` | string | URL of the agent's profile photograph | |
| `mugShotURL` | string | URL of a legacy profile headshot image | |
| `mugShotNew` | string | URL of the agent's current updated headshot image | |
| `saleActive` | boolean | Whether the agent is currently active in residential sales | |
| `rentalActive` | boolean | Whether the agent is currently active in property rentals | |
| `isActiveProfilePage` | string | Whether the agent has an active public-facing profile page on Domain | |
| `profileText` | string | Biographical and marketing description written for the agent's public profile | |
| `profileUrl` | string | URL to the agent's public profile page on Domain | |
| `jobPosition` | string | Agent's job title or role within the agency | |
| `dateUpdated` | date-time | Date and time when the agent's profile was last updated | |
| `isHideSoldLeasedListings` | boolean | Whether the agent has chosen to suppress their past sold and leased listings from their profile | |
| `receivesRequests` | boolean | Whether the agent accepts property enquiry submissions via Domain | |
| `receiveScheduledReportEmail` | boolean | Whether the agent receives automated performance summary emails | |
| `facebookUrl` | string | URL of the agent's Facebook profile | |
| `twitterUrl` | string | URL of the agent's Twitter/X profile | |
| `linkedInUrl` | string | URL of the agent's LinkedIn profile | |
| `googlePlusUrl` | string | URL of the agent's Google+ profile (legacy) | |
| `personalWebsiteUrl` | string | URL of the agent's personal professional website | |
| `agentVideo` | string | URL of a promotional video for the agent | |
| `creAgentVideoURL` | string | URL of a promotional video focused on the agent's commercial real estate work | |
| `contactTypeCode` | integer | Numeric code identifying the agent's role or contact type classification | |

---

#### `GET /v1/agents/{id}/listings`
Retrieve listings associated with a specific agent.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain identifier for the agent whose listings to retrieve | Agent (contact) ID |
| `dateUpdatedSince` | date-time | optional | Return only listings modified on or after this date and time | |
| `includedArchivedListings` | boolean | optional | Whether to include listings that are no longer active | Default: false |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | Default: 1 |
| `pageSize` | integer | optional | Number of listings to return per page | Default: 20 |

**Response fields:** Full listing objects, see `GET /v1/listings/{id}` response fields.



### Projects (New Developments)

---

#### `GET /v1/projects`
Search new development projects.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `agencyId` | integer | optional | Filter results to projects posted by this specific agency | |
| `pageNumber` | integer | optional | Which page of results to retrieve (1-based) | Default: 1 |
| `pageSize` | integer | optional | Number of results to return per page | Default: 20, max: 100 |
| `projectStatus` | string | optional | Whether to return live active projects or inactive ones | `live`, `inActive` |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | integer | Unique Domain identifier for the development project | |
| `name` | string | Marketing name of the development project | |
| `projectProfileType` | string | Promotional tier for the project's Domain profile page | `noProfile`, `projectProfileStandard`, `projectProfilePremium` |
| `estimatedCompletionTertile` | string | Approximate part of the year when the project is expected to be completed | `early`, `mid`, `late` |
| `category` | string | Broad category classifying the nature of the development | `houseAndLand`, `apartment`, `retirement` |
| `startDate` | date-time | Date when the project officially commenced marketing or construction | |
| `endDate` | date-time | Date when the project is expected to complete or marketing concludes | |
| `address.stateAbbreviation` | string | Abbreviated state or territory code for the project's location | |
| `address.streetNumber` | string | Street number of the development site | |
| `address.unitNumber` | string | Unit or suite number for the development site if within a larger complex | |
| `address.street` | string | Street name of the development site address | |
| `address.street2` | string | Second line of the development site's street address | |
| `address.suburb` | string | Suburb where the development is located | |
| `address.suburbId` | integer | Domain's internal numeric identifier for the project suburb | |
| `address.postcode` | string | Four-digit Australian postcode for the development site | |
| `address.displayAddress` | string | Formatted address of the development site ready for display | |
| `address.latitude` | number | Geographic latitude coordinate of the development site | |
| `address.longitude` | number | Geographic longitude coordinate of the development site | |
| `displayableAddress.stateAbbreviation` | string | Abbreviated state or territory code for the display address | Lowercase enum: `nsw`, `vic`, `qld`, `sa`, `wa`, `tas`, `nt`, `act` |
| `displayableAddress.streetNumber` | string | Street number of the display address | |
| `displayableAddress.unitNumber` | string | Unit or suite number of the display address | |
| `displayableAddress.street` | string | Street name of the display address | |
| `displayableAddress.street2` | string | Second line of the display address | |
| `displayableAddress.suburb` | string | Suburb of the display address | |
| `displayableAddress.suburbId` | integer | Domain's internal numeric identifier for the display address suburb | |
| `displayableAddress.postcode` | string | Postcode of the display address | |
| `displayableAddress.displayAddress` | string | Formatted display address string ready for display in a UI | |
| `displayableAddress.latitude` | number | Geographic latitude coordinate of the display address | |
| `displayableAddress.longitude` | number | Geographic longitude coordinate of the display address | |
| `propertyTypes` | array[string] | Types of dwellings included in this development (e.g. apartments, townhouses) | |
| `enquiryEmailAddress` | string | Email address to which buyer enquiries for the project are sent | |
| `viewingAddress.stateAbbreviation` | string | Abbreviated state or territory code for the viewing/display address | Lowercase enum: `nsw`, `vic`, `qld`, `sa`, `wa`, `tas`, `nt`, `act` |
| `viewingAddress.streetNumber` | string | Street number of the viewing address | |
| `viewingAddress.unitNumber` | string | Unit or suite number of the viewing address | |
| `viewingAddress.street` | string | Street name of the viewing address | |
| `viewingAddress.street2` | string | Second line of the viewing address | |
| `viewingAddress.suburb` | string | Suburb of the viewing address | |
| `viewingAddress.suburbId` | integer | Domain's internal numeric identifier for the viewing address suburb | |
| `viewingAddress.postcode` | string | Postcode of the viewing address | |
| `viewingAddress.displayAddress` | string | Formatted viewing address string ready for display | |
| `viewingAddress.latitude` | number | Geographic latitude coordinate of the viewing address | |
| `viewingAddress.longitude` | number | Geographic longitude coordinate of the viewing address | |
| `providerDetails` | object | Identifiers from the third-party data feed system that submitted this project | |
| `advertiserIdentifiers` | object | Identifiers linking the project to its advertising agency and agent contacts | Same structure as in listings |
| `media[].category` | string | Broad classification of the attached media asset | `image`, `video`, `others` |
| `media[].type` | string | Specific format of the media asset | `photo`, `poster`, `video`, `virtualTour`, `webLink` |
| `media[].url` | string | URL of the media asset | |
| `media[].description` | string | Caption or description for this media asset | |
| `projectUrl` | string | URL to the project's profile page on Domain | |
| `headline` | string | Short marketing headline for the development project | |
| `tagline` | string | Brief tagline or strapline for the development project | |
| `description` | string | Full marketing description of the development project | |
| `backgroundColour` | string | Background colour for the project's branding display in hexadecimal format | |
| `bannerUrl` | string | URL of the project's standard banner image | |
| `bigBannerUrl` | string | URL of the project's large-format banner image | |
| `smallBannerUrl` | string | URL of the project's small-format banner image | |
| `logoUrl` | string | URL of the developer's or project's logo image | |
| `pdfs[].type` | string | Classification of this PDF document (e.g. brochure, floorplan, masterplan) | `commercialPdf`, `newDevBrochurePdf`, `floorplanPdf`, `devProjectPdf`, `devProjectMasterplanPdf` |
| `pdfs[].url` | string | URL to download or view the PDF document | |
| `pdfs[].filename` | string | File name of the PDF document | |
| `pdfs[].fileDescription` | string | Human-readable description of the PDF document's contents | |
| `inspectionDetails.inspections[].recurrence` | string | Whether this project inspection is a one-off or repeats weekly | `none`, `weekly` |
| `inspectionDetails.inspections[].openingDateTime` | date-time | Date and time when an upcoming project inspection begins | |
| `inspectionDetails.inspections[].closingDateTime` | date-time | Date and time when an upcoming project inspection ends | |
| `inspectionDetails.isByAppointmentOnly` | boolean | Whether site visits are arranged individually rather than at open times | |
| `appointmentRequired` | boolean | Whether prospective buyers must book an appointment before visiting the site | |
| `features` | array[string] | List of features and inclusions offered across the development | |
| `priceFrom` | number | Lowest starting price across all dwellings in the development in Australian dollars | |
| `priceTo` | number | Highest price across all dwellings in the development in Australian dollars | |
| `numberOfFloors` | integer | Number of floors in the primary building of the development | |
| `minNumberOfFloors` | integer | Minimum number of floors across all buildings in the development | |
| `minBuildingHeight` | integer | Minimum height of the buildings in the development (in levels or metres) | |
| `maxBuildingHeight` | integer | Maximum height of the buildings in the development (in levels or metres) | |
| `numberOfBuildings` | integer | Total number of separate buildings in the development | |
| `numberOfApartments` | integer | Total number of apartments or dwellings in the development | |
| `estimatedCompletionDate` | date-time | Expected date when construction of the development will be finished | |
| `startingPrice` | number | Lowest individual child listing price currently available in the project | Lowest child listing price |
| `childListingIds` | array[integer] | List of individual unit or lot listing IDs that belong to this project | |
| `linkedProjectIds` | array[integer] | IDs of related or associated development projects | |
| `displayAsLastUpdated` | date-time | Date and time shown publicly as the project's last update | |
| `modifiedBy` | string | Username or identifier of who last modified the project record | |
| `modifiedDate` | date-time | Date and time when the project record was last modified | |
| `createdBy` | string | Username or identifier of who created the project record | |
| `createdDate` | date-time | Date and time when the project record was first created | |

---

#### `GET /v1/projects/{id}`
Retrieve full details of a specific project.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain identifier for the project to retrieve | Project ID |

**Response fields:** Same as `GET /v1/projects` response fields.

---

#### `GET /v1/projects/{id}/listings`
Retrieve individual unit or lot listings within a project.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `id` | integer | required (path) | Unique Domain identifier for the project whose child listings to retrieve | Project ID |

**Response fields:** Full listing objects, see `GET /v1/listings/{id}` response fields.



### Account and Enquiries

---

#### `GET /v1/me`
Verify authentication and retrieve current client identity.

**Input parameters:** None.

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `authenticated` | boolean | Whether the current API request was successfully authenticated | True if request was successfully authenticated |
| `clientId` | string | API client key or application identifier used to authenticate the request | Client ID or API key used |
| `subjectId` | string | Unique identifier for the individual user account making the request | Unique user ID (user-context only) |
| `subjectEmail` | string | Email address associated with the authenticated user account | User email address |

---

#### `GET /v1/me/agencies`
List agencies associated with the currently authenticated client.

**Input parameters:** None.

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `id` | integer | Unique Domain identifier for the agency linked to the authenticated client | Agency ID |
| `name` | string | Trading name of the linked agency | Agency name |
| `admin` | boolean | Whether the authenticated user has administrative permissions for this agency | True if this user is an admin of this agency |

---

#### `POST /v1/enquiries`
Submit an enquiry for a listing, agency, or agent.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `deliveryMethod` | string | optional | How the enquiry message should be delivered to the advertiser | `email`, `sms` |
| `enquiryType` | string | optional | Context or target of the enquiry (which entity or listing type is being contacted) | `listing`, `devProject`, `newDevLanding`, `agencyProfile`, `agentProfile`, `contractRequest`, `vendorEnquiry`, `prePortalListing` |
| `referenceId` | integer | optional | ID of the specific listing or entity the enquiry relates to | Listing identifier |
| `id` | string | optional | Unique identifier assigned to this enquiry submission | Enquiry identifier |
| `sender` | object | optional | Object containing the contact details of the person submitting the enquiry | Sender details |
| `subject` | string | optional | Subject line of the enquiry message | |
| `message` | string | optional | Body text of the enquiry message | |
| `metaData` | object | optional | Additional contextual data attached to the enquiry for tracking or routing purposes | |

**Response fields**

| Field | Type | Glossary | Notes |
|---|---|---|---|
| `s3Key` | string | Storage key identifying where the enquiry record was saved internally | |
| `message` | string | Confirmation message returned upon successful submission | |
| `enquiryReceiptTimestamp` | date-time | Date and time when the enquiry was received and processed by the platform | |
| `warnings` | array[string] | Any non-fatal warnings generated during enquiry processing | |

---

#### `POST /v1/statistics/{event}`
Record a user interaction event.

**Input parameters**

| Parameter | Type | Required | Glossary | Notes |
|---|---|---|---|---|
| `event` | string | required (path) | Type of user interaction event to record (e.g. view, click, enquiry) | Event type |
| (body) | object | optional | Contextual metadata associated with the recorded event | Associated event metadata |

**Response:** Confirmation only (no documented response schema).


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
| **Companion document — Group 2 endpoints** | `metadata-properties-and-locations.md` |

