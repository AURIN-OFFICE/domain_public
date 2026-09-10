# Known API Gotchas & How to Defend Against Them

The Domain API has several behaviours that are either undocumented or not immediately obvious in practice. Each entry below outlines what you are likely to observe, why it matters, and what to do about it. The gotchas here are specific to the two main research endpoints: the **listings search** (`/v1/listings/residential/_search`) and **suburb performance statistics** (`/v2/suburbPerformanceStatistics`). These are also the endpoints where a silent failure or a parameter mistake is most likely to waste credits at scale.


## Gotcha 1: A Typo in the Suburb Name Returns Nothing, No Warning

**What happens:** If you query `suburb statistics` with a misspelled suburb name, the API responds as if the request succeeded but returns a completely empty result. There is no error message, no warning, and the credit is still consumed.

For example, querying "Cralton" instead of "Carlton" returns a success signal from the server with no data attached.

**Why it matters:** If you are running queries across a list of suburbs and one name is misspelled, you will silently collect empty results for that suburb without knowing anything went wrong. Credits are still spent on each failed query.

**What to do:** Before running any multi-suburb extraction, verify your suburb list manually against a reliable reference. Cross-check suburb names and postcodes on the Domain website or the ABS suburb lookup before putting them in your code. Test your query on a single known suburb first before scaling to a full list.

In your code, always check that the response has actual content before treating it as a valid result:

```python
r = requests.get(url, params=params, auth=PROXY_AUTH, headers=headers)
if r.status_code == 200 and not r.text.strip():
    print(f"[{suburb}] Request succeeded but returned no data. Check the suburb name and postcode.")
    continue
data = r.json()
```

What this does: after making the request, it checks whether the response has any content. If the server said "success" but sent back nothing, it prints a warning and skips to the next suburb instead of silently recording an empty result.


## Gotcha 2: Queries Matching More Than 1,000 Records Are Silently Truncated

**What happens:** The listings search returns at most 1,000 records per request. If your query matches more than 1,000 records, the API returns the first 1,000 and stops, with no error, no warning, and no sign that records were cut off.

If you then try to retrieve records beyond position 1,000 by asking for a later page, the API returns an error message:

```
"Cannot page beyond 1000 results"
```

**Why it matters:** A study area with 5,500 matching records will silently return only 1,000. Over 80% of the data is missing with no indication anything went wrong. Inner-city Melbourne suburbs regularly exceed 1,000 records for even a 2-year window.

**What to do:** Before running a full extraction, always run a 1-credit test query first to check how many records exist in your study area. The [Credit Calculator guide](./03-credit-calculator.md) covers exactly how to do this. If the total exceeds 1,000, you will need to retrieve records in multiple sequential batches, adjusting your query to step through the full dataset in chunks.


## Gotcha 3: Your Start Date Filters by Listing Date, Not Sale Date

**What happens:** When you set a start date for your listings search, the API filters by when the property was first listed on Domain, not by when it sold. A property listed in January 2020 may have sold in December 2019. A property that sold in February 2020 but was listed in December 2019 will not appear in your results at all.

There is also no end-date filter. You cannot tell the API to return only listings sold before a certain date. This has been confirmed through testing.

**Why it matters:** If your study covers a specific sales window (for example, 2020 to 2022), setting a start date of January 2020 will not cleanly capture that window. Some records will have sale dates outside the window, and some genuine sales from within the window will be excluded entirely.

**What to do:** Set your start date slightly earlier than your intended study window to cast a wider net, retrieve all matching records, and then filter the results yourself to keep only those sold within your actual study period. This filtering happens on your computer and costs no additional credits.

```python
df_filtered = df[
    (df["sold_date"] >= "2020-01-01") &
    (df["sold_date"] <= "2022-12-31")
]
```

What this does: from your full dataset, it keeps only the rows where the sale date falls within your chosen window. Everything outside that range is discarded.

Validate your date coverage by checking the earliest and latest sale dates in the filtered results before proceeding with analysis.


## Gotcha 4: A Badly Formed Request Can Still Cost a Credit

**What happens:** If a request contains an invalid parameter (for example, a value that should be a number but is sent as text), the API returns an error and the request fails. However, the credit is still charged.

**Why it matters:** If you are running a loop over many suburbs and there is a parameter error in your code, every single iteration of that loop will fail and consume a credit. A loop of 140 suburb and bedroom combinations with one bad parameter wastes 140 credits before you even look at any data.

**What to do:** Always run a single test query outside your loop before committing to a full run. If the first query fails, fix the problem before the loop begins. Check that any numeric parameters (such as the number of periods) are actually numbers and not text, and that category values are spelt exactly as the API expects ("House" and "Unit", not "house" or "Houses").


## Gotcha 5: Copying Query Code Between Request Types Can Return Nothing

**What happens:** The listings search and the suburb statistics query are two different types of request. Each requires a slightly different set of settings in your code. If the settings for one type are accidentally included in the other (most commonly by copy-pasting code from one query type and adapting it for the other), the API returns a success signal with a completely empty result. There is no error and no warning.

**Why it matters:** The symptom is identical to Gotcha 1 (invalid suburb name). If you have already verified your suburb names and are still getting empty responses, this is the next thing to check.

**What to do:** Keep the settings for listings searches and suburb statistics queries separate in your code. Do not copy-paste between them without checking which settings apply to each type. If you see an unexpected empty response and the suburb name is correct, compare your settings against a working example for that specific query type.


## Gotcha 6: The House/Unit Split Covers More Property Types Than the Labels Suggest

**What happens:** The `Suburb Statistics API` accepts only two property categories: `House` and `Unit`. These are broader groupings than the names imply. Domain's documented mapping is:

| `House` includes | `Unit` includes |
|---|---|
| House, Townhouse, Duplex, Triplex, Terrace, Cottage, Semi-Detached | Apartment, Unit, Flat, Studio, Villa |

Vacant land (no residential improvements) is excluded from both categories.

**Why it matters:** Research that segments by property type is working with broader groupings than the labels suggest. Querying `House` returns detached houses alongside townhouses, terraces, duplexes, and semi-detached homes. Querying `Unit` returns apartments alongside studios and villas.

**What to do:** Treat the House/Unit split as a broad grouping rather than a precise physical classification. The categories are well-suited to most market analyses. If your research depends on a finer distinction, such as separating townhouses from detached houses, the Suburb Statistics API cannot support it and you would need to use the individual listings endpoint instead, which will be costly.


## Gotcha 7: `includeSurroundingSuburbs: true` Quietly Expands the Study Area

**What happens:** The `listings` search accepts an `includeSurroundingSuburbs` parameter. When set to `true`, the API silently adds records from neighbouring suburbs to your results. The response contains no field indicating which records came from the target suburb and which came from neighbours.

**Why it matters:** A study targeting one suburb may unknowingly contain records from several surrounding ones. The `X-Total-Count` header reflects this inflated count, so even a probe query will overestimate the size of the target area. This is a particularly easy mistake when adapting code from an example that had the flag set to `true`.

**What to do:** Always set `includeSurroundingSuburbs` to `false` for suburb-specific studies. If you want to capture surrounding areas deliberately, treat the result as a regional dataset rather than a suburb-specific one, and filter by the `suburb` field after retrieval to separate records by location.

---

Now that you know the pitfalls, you are ready to write extraction code. The [Phase 2 notebooks](../phase-2/) provide working, reusable implementations that already handle all of the above, starting from a notebook is safer and faster than writing extraction code from scratch.
