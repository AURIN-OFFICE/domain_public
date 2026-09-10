# Australian Property Data via the Domain API (through AURIN)

This repository helps researchers use **live Australian property data** from Domain, accessed
through AURIN. It gives you three things:

- **Step-by-step guides and hands-on notebooks** that take you from zero to running your own
  queries, in either Python or R.
- **Reference material** describing both API groups: their endpoints, parameters and response fields.
- **Geography lookup tables** that connect Domain's own suburbs and regions to ABS boundaries.

You do not need to be a programmer to get value from it. Start with the plain-language guides, then,
if the data fits your research, follow the setup path below.

> The data covers property listings (sold, for-sale, for-rent), suburb-level market statistics
> (median prices, days on market, and more), suburb demographics, and individual property details.
> It is Australia-wide.


## 1. Who this is for, and what you will need

This material is aimed at researchers studying Australian property, housing, or urban topics. To go
beyond reading the guides and actually run your own queries, you will need:

- **An institutional AURIN affiliation.** Access requires a university or research organisation login.
- **A research question in mind.** Every query costs one credit from a limited monthly allowance,
  so it pays to know what you are looking for before you start pulling data.
- **A willingness to run notebooks, in either Python or R.** No prior programming experience needed.
  The material comes in two parallel tracks that teach the same things, so pick whichever language you
  already work in: [`training-materials-python/`](training-materials-python/) or
  [`training-materials-r/`](training-materials-r/). Each track's phase-1 guides walk you through every
  step, including installing the language for the first time.


## 2. How access works (in plain terms)

You do not connect to Domain directly. Instead, your code sends each query to an **AURIN proxy**, which
checks your credentials and your remaining credits, then forwards the request to Domain and returns the
data to you.

```
You (Python or R)  ->  AURIN proxy (domain.api.aurin.org.au)  ->  Domain API
     <-  data (minus 1 credit)  <-
```

Two things are important to understand up front:

- **Your credentials are your AURIN username and password** (your institutional email and AURIN
  password), used as an HTTP Basic login. There is no separate "API key" to generate.
- **Every query costs 1 credit.** Each account gets **1,000 credits per month**, which reset
  automatically on the 1st of each month. Treat this like a monthly budget: design your question first,
  then query. The Credit Calculator guide
  ([Python](training-materials-python/phase-1/03-credit-calculator.md) /
  [R](training-materials-r/phase-1/03-credit-calculator.md)) shows how to estimate a query's cost
  before you run it.


## 3. Setup: from zero to your first query

**First, choose your language.** Both tracks teach exactly the same concepts in the same order.

| | Python track | R track |
|---|---|---|
| Guides and notebooks | [`training-materials-python/`](training-materials-python/) | [`training-materials-r/`](training-materials-r/) |
| Notebook format | Jupyter (`.ipynb`) | R Markdown (`.Rmd`), open in RStudio |
| Beginner checklist | [Data Access Guide](training-materials-python/phase-1/01-data-access-guide.md) | [Data Access Guide](training-materials-r/phase-1/01-data-access-guide.md) |

Then follow these steps in order.

1. **Install your language.**
   - *Python:* version 3.12 or newer from
     [python.org/downloads](https://www.python.org/downloads/). On Windows, tick "Add Python to PATH"
     during installation.
   - *R:* version 4.1 or newer from [cran.r-project.org](https://cran.r-project.org/), plus
     [RStudio Desktop](https://posit.co/download/rstudio-desktop/) for running the notebooks.

2. **Get this project onto your computer.** Either clone it with git, or download it as a ZIP from the
   repository page and unzip it.

3. **Install the required packages.**
   - *Python:* install the packages the notebooks import, for example with
     `pip install requests pandas python-dotenv geopandas`.
   - *R:* open [`training-materials-r/phase-2/install-packages.R`](training-materials-r/phase-2/install-packages.R)
     in RStudio and click **Source**, or run `Rscript install-packages.R` from that folder.

4. **Sign the AURIN Domain agreement and find your credentials.** This is a one-time online step inside
   the AURIN Data Provider. The Data Access Guide for your track
   ([Python](training-materials-python/phase-1/01-data-access-guide.md) /
   [R](training-materials-r/phase-1/01-data-access-guide.md))
   walks you through it with screenshots, and shows where to see your credit balance.

5. **Create a `.env` file for your credentials.** In the folder you run the notebooks from, create a
   file named `.env` containing your AURIN login:

   ```
   AURIN_USERNAME=your.email@institution.edu.au
   AURIN_PASSWORD=your_aurin_password
   ```

   > This file keeps your password out of your code. Never commit it to git.

6. **Run your first notebook.** Open notebook 0 for your track:
   [Python](training-materials-python/phase-2/notebook-0-getting-started.ipynb) in Jupyter, or
   [R](training-materials-r/phase-2/notebook-0-getting-started.Rmd) in RStudio.
   Run the cells (Python) or chunks (R). A successful test query returns a status of `200`, confirming
   your setup works.


## 4. A learning path

Work through the material roughly in this order, in whichever language track you chose above.

| Start here when...                              | Python                                                                            | R                                                                            |
|-------------------------------------------------|-----------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| You are brand new and want the big picture      | [00 Getting Started](training-materials-python/phase-1/00-getting-started.md)      | [00 Getting Started](training-materials-r/phase-1/00-getting-started.md)      |
| You are setting up access for the first time    | [01 Data Access Guide](training-materials-python/phase-1/01-data-access-guide.md)  | [01 Data Access Guide](training-materials-r/phase-1/01-data-access-guide.md)  |
| You previously used APM data through AURIN      | [02 Paradigm Shift](training-materials-python/phase-1/02-paradigm-shift.md)        | [02 Paradigm Shift](training-materials-r/phase-1/02-paradigm-shift.md)        |
| You want to budget your credits before a big run| [03 Credit Calculator](training-materials-python/phase-1/03-credit-calculator.md)  | [03 Credit Calculator](training-materials-r/phase-1/03-credit-calculator.md)  |
| You are about to write extraction code          | [04 API Gotchas](training-materials-python/phase-1/04-api-gotchas.md)              | [04 API Gotchas](training-materials-r/phase-1/04-api-gotchas.md)              |
| You are ready for hands-on examples             | [phase-2 notebooks](training-materials-python/phase-2/)                            | [phase-2 notebooks](training-materials-r/phase-2/)                            |

The **phase-2 notebooks** are practical, runnable examples covering the same five topics in both tracks
(differing only in extension): a first end-to-end query, listings search, suburb statistics over time,
retrieving more than 1,000 records past the API's per-response cap, and spatial querying by map area.
Each track also has a shared helpers file, `utils.py` or `utils.R`, which loads your credentials, counts
credits used, and converts map boundaries into the format the API expects.


## 5. What's in this repository

```
domain_public/
├── api_agents_and_listings/     # GROUP 1: listings, agencies, agents, projects
│   ├── documentation.md         #   -> overview of the group and what it covers
│   └── metadata-agents-and-listings.md       #   -> full endpoint reference
├── api_property_data/           # GROUP 2: property records, suburb statistics, auctions
│   ├── documentation.md         #   -> overview of the group and what it covers
│   └── metadata-properties-and-locations.md  #   -> full endpoint reference
├── correspondence/              # Geography lookups: Domain suburbs -> ABS boundaries (.xlsx)
├── training-materials-python/   # PYTHON TRACK
│   ├── phase-1/                 # Plain-language guides: read these first
│   │   ├── 00-getting-started.md         03-credit-calculator.md
│   │   ├── 01-data-access-guide.md       04-api-gotchas.md
│   │   └── 02-paradigm-shift.md
│   └── phase-2/                 # Hands-on Jupyter notebooks
│       ├── notebook-0-getting-started.ipynb    notebook-3-pagination-tricks.ipynb
│       ├── notebook-1-listings-search.ipynb    notebook-4-spatial-querying.ipynb
│       ├── notebook-2-suburb-statistics.ipynb
│       └── utils.py
├── training-materials-r/        # R TRACK (same content, same order)
│   ├── phase-1/                 # Same five guides, with R code and an R setup checklist
│   │   └── ...                  #   -> 04-api-gotchas.md has one extra R gotcha (no. 8)
│   └── phase-2/                 # Hands-on R Markdown notebooks, open in RStudio
│       ├── notebook-0-getting-started.Rmd
│       ├── ...
│       ├── utils.R              #   -> the R port of utils.py
│       └── install-packages.R   #   -> run once to install the R dependencies
└── datatale/                    # Worked data stories built from this API (in preparation)
```


## 6. Reference materials

The API is split into two groups. Each has a short overview and a full endpoint reference.

**Group 1, Agents & Listings**, the active market as advertised on Domain: residential, commercial and
business listings, plus the agencies, agents and development projects behind them.

- [`api_agents_and_listings/documentation.md`](api_agents_and_listings/documentation.md), what the
  group covers, how often it refreshes, and its limits.
- [`api_agents_and_listings/metadata-agents-and-listings.md`](api_agents_and_listings/metadata-agents-and-listings.md),
  every endpoint with parameters, response fields and known limitations.

**Group 2, Properties & Locations**, property-level records and area-level market intelligence: sales
and listing history, price estimates, suburb performance statistics, demographics and auction results.

- [`api_property_data/documentation.md`](api_property_data/documentation.md), what the group covers
  and the constraints to plan around.
- [`api_property_data/metadata-properties-and-locations.md`](api_property_data/metadata-properties-and-locations.md),
  every endpoint with parameters, response fields and required disclaimers.

**Geography lookups.** Domain uses its own suburb, region and location IDs, which do not map directly
onto ABS statistical geographies. The tables in [`correspondence/`](correspondence/) connect them to
GCCSA, SA2, SA3 and SA4 (2021) boundaries, so results can be joined to standard Australian areas or
compared with Census and other AURIN datasets.
