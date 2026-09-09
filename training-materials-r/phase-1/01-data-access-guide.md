# Navigating AURIN Data Access

This guide walks you through everything you need to get from zero to a working connection to the Domain API, including what to do when things go wrong.

```mermaid
flowchart LR
    S1["Sign agreement\n(Using AURIN Data Provider)"]
    S2["Retrieve credentials\n(Using AURIN Data Provider)"]
    S3["Create .env file\n(Using Text Editor)"]
    S4["Run test query\n(Using R Console)"]
    S5["Confirm 200 OK\n(Using R Console)"]

    S1 --> S2 --> S3 --> S4 --> S5
```


## Before You Start

You will need three things:

- **An academic or institutional affiliation**, AURIN access requires an institutional login (university or research organisation)
- **R installed on your computer**, if you have never used R before, jump to the [R setup checklist](#r-setup-checklist-for-first-time-users) at the bottom of this guide first, then come back here
- **A signed Domain API access agreement**, this is a short online form inside the AURIN Data Provider; Step 1 below walks you through it


## Step 1: Sign the Access Agreement

The Domain data is provided by AURIN under a specific data licence. AURIN requires you to accept this licence before your account can make any API calls. This is a one-time step, once signed, it stays active on your account.

**How to sign it:**

1. Browse to [data.aurin.org.au](https://data.aurin.org.au) and log in
2. From the top menu, hover over **Manage Access**
3. Select **My Agreements** from the dropdown
4. Under *Available Agreements*, find the **Domain API** agreement and click **Open**
5. Read through the data transfer agreement and, if you agree, click **Accept**

<img src="images/my_agreements.gif" alt="My Agreements" width="80%">


> ⚠️ **What happens if you skip this:**
> Your API calls will fail with an error that says *"To gain access, you would need to sign the Domain API agreement below."* Confusingly, you will see this same message if your monthly credit balance runs out, not just when the agreement is unsigned. If you see this error at any point, the first thing to do is check your credit balance (Step 5 below), not try to re-sign the agreement.


## Step 2: Find Your Access Credentials

Think of the AURIN Data Provider as a library card system. Your AURIN username (your institutional email) and password are your library card. Every time your code queries the API, it shows that card automatically, you don't need to log in each time, but your credentials need to be available to your code.

Your credentials are the same ones you use to log into the AURIN Data Provider. To confirm them and see your credit quota:

1. Log in to [data.aurin.org.au](https://data.aurin.org.au)
2. From the top menu, hover over **Manage Access** and click **API Access**
3. This is where you see your AURIN credentials (basically your AURIN username and password).
4. Moreover, you will see two other sections on this page:
   - **AURIN Data Access (WFS)**, for accessing AURIN-hosted datasets (not relevant here).
   - **Domain Access**, this shows your Domain data quota, credit balance, and the proxy URL to use in your code.

<img src="images/API_access.gif" alt="My Agreements" width="80%">

The proxy URL shown on that page is:
```
https://domain.api.aurin.org.au
```

All your API calls go to this address, not directly to Domain's website. AURIN's server sits in between, checks your credentials and credit balance, then forwards the request. This is why your AURIN username and password are what matter, not a Domain account.



## Step 3: Store Your Credentials Safely

> 💡 **New to R?** Steps 3 and onwards require R to be installed and a few packages available. If you haven't set this up yet, jump to the [R setup checklist](#r-setup-checklist-for-first-time-users) at the bottom of this page, then come back here.

It is best practice to avoid typing your password directly into a notebook or R script, because if you ever share the file, your credentials could become visible to others. The recommended approach is to store them in a separate private file called a `.env` file.

> 💡 **If this feels like too many steps for now:** you can temporarily type your credentials directly into your script while you are working locally on your own computer. Just be careful not to share that file with anyone. The `.env` approach is worth setting up properly once you are comfortable.

**What is a `.env` file?**
It is a plain text file (like a Notepad or TextEdit document) that sits in your project folder and holds sensitive values such as passwords. Your R code reads from this file automatically when it starts up, so your credentials stay out of your scripts.

**How to create it:**

1. Open the folder where your notebooks or R scripts live
2. Create a new plain text file called `.env` (the dot at the start is required; there is no `.txt` extension)
3. Paste the following two lines into it, replacing the example values with your real AURIN email and password:

```
AURIN_USERNAME=your.email@institution.edu.au
AURIN_PASSWORD=your_aurin_password
```

4. Save the file and close it

> 💡 On Windows, Notepad works fine. On Mac, use TextEdit, but switch it to plain text mode first (Format → Make Plain Text) before saving.

**If you are using git for version control**, make sure git ignores this file so it is never accidentally uploaded. Open the file called `.gitignore` in your project folder (or create one if it doesn't exist) and add this line:
```
.env
```

**How your code reads the credentials:**

At the top of your notebook or R script, include these lines. You only need to do this once per file:

```r
library(httr2)

setwd("PATH TO THE FOLDER WHERE YOUR .env FILE RESIDES") # setting the working directory

readRenviron(".env")  # reads your .env file and makes its values available

AURIN_USERNAME <- Sys.getenv("AURIN_USERNAME")  # retrieves your email from .env
AURIN_PASSWORD <- Sys.getenv("AURIN_PASSWORD")  # retrieves your password from .env

PROXY_BASE_URL <- "https://domain.api.aurin.org.au"  # the AURIN proxy address
```

What this does in plain terms:
- `setwd(...)`, points R at the folder your `.env` file lives in, so the next line can find it. Use the full path to that folder.
- `readRenviron(".env")`, opens your `.env` file and reads the values into memory. This is built into R, so no extra package is needed to read a `.env` file
- `Sys.getenv("AURIN_USERNAME")`, retrieves the value you stored under that label
- `PROXY_BASE_URL`, the web address all your queries will be sent to

Your credentials get attached to each request with `req_auth_basic()`, shown in the test call in Step 4. That is the step that bundles them into the format the API expects, like attaching a signed permission slip to every query.

> 💡 **Watch out when you copy and paste a folder path.** Paths look different depending on the operating system you are using. Windows file manager gives you backslashes (`C:\Users\you\project`), while Mac and Linux give you forward slashes (`/Users/you/project`). Pasting a Windows path straight into R causes an error, because a single backslash has a special meaning inside quotes. Either double each backslash (`"C:\\Users\\you\\project"`) or swap them for forward slashes (`"C:/Users/you/project"`), which R understands on every operating system. On Mac and Linux, the path you copy already uses forward slashes, so it works as is.

> 💡 **If `.env` is not in the same folder** as your script, give `readRenviron()` the path to it, for example `readRenviron("../../.env")`. The phase-2 notebooks handle this for you: `utils.R` searches the current folder and each folder above it until it finds a `.env`.

> 💡 **First time only:** If you see an error saying `there is no package called 'httr2'`, you need to install the required packages. In the R console, run:
> ```r
> install.packages(c("httr2", "jsonlite"))
> ```
> Then re-run the code block above.



## Step 4: Test That Everything Works

Once your `.env` file is set up and your code has loaded the credentials, run this short test to confirm the connection is working. Open a new notebook chunk or R script and copy this code exactly:

```r
url <- paste0(PROXY_BASE_URL, "/v2/suburbPerformanceStatistics/VIC/Carlton/3053")

r <- request(url) |>
  req_url_query(
    propertyCategory = "House",
    periodSize       = "quarters",
    totalPeriods     = 1
  ) |>
  req_headers(accept = "application/json") |>
  req_auth_basic(AURIN_USERNAME, AURIN_PASSWORD) |>
  # return error responses as values so we can print the status code below
  req_error(is_error = function(resp) FALSE) |>
  req_perform()

cat("Status:", resp_status(r), "\n")
cat("Body length:", nchar(resp_body_string(r)), "chars\n")
```

This asks the API for one quarter (a three-month period) of suburb statistics for Carlton, VIC. It costs 1 credit.

**What a successful result looks like:**
```
Status: 200
Body length: #### chars
```
A status of `200` means success. A body length greater than zero confirms data came back.

**What a failure looks like:**
- `Status: 200` but `Body length: 0` → your credentials are fine but something is wrong with the query (suburb name, postcode, or a GET header issue). See the troubleshooting section below.
- `Status: 401` → credentials not accepted. Check your `.env` file values.
- `Status: 403` → either agreement not signed or credit balance at zero. Check the dashboard (Step 5).


## Step 5: Check Your Credit Balance Before Every Large Run

Your account has **1,000 API calls per month**. These refill automatically on the 1st of each calendar month, you do not need to do anything to reset them.

There is no way to check your remaining balance programmatically. The only place to see it is inside the AURIN Data Provider:

1. Log in to [data.aurin.org.au](https://data.aurin.org.au)
2. Hover over **Manage Access** → click **API Access**
3. Look at the **Domain Access** section, it shows your current usage and monthly limit

**Check your credit balance before every large run.** If your code loops over 50 suburbs and you only have 30 credits left, it will run until the credits run out, with no warning, and you will be left with an incomplete dataset that you cannot cheaply re-run.

<img src="images/monthly-credit.png" alt="Credit Balance View" width="80%">


## Troubleshooting: What the Error Messages Mean

### "Status: 200 but Body length: 0" (empty response, no error)
Your request reached the server successfully, but it returned nothing. This usually means:
- The suburb name is misspelled (try Carlton, not Carltn)
- The postcode does not match the suburb.
- Less commonly: your code is sending a `Content-Type` header on a GET request, this silently breaks the response. See the [Gotchas guide](./04-api-gotchas.md) for details. In R, `httr2` only sets that header when you attach a request body, so a GET built as shown above will not have this problem.

### "Status: 400" (bad request)
Your request contained an invalid parameter, for example, typing `"four"` where the API expects the number `4`. Fix the parameter and try again. 
**Note: this still consumed 1 credit**, even though it failed. See [Gotcha 4](./04-api-gotchas.md#gotcha-4-malformed-requests-http-400-still-consume-a-credit).

### "Status: 401" (not authorised)
Your credentials were not accepted. Check:
- Is your `.env` file in the same folder as your notebook/script?
- Did you call `readRenviron(".env")` before trying to use the credentials?
- Does `Sys.getenv("AURIN_USERNAME")` print your email, or an empty string? An empty string means the `.env` file was not found or not read.
- Is the email and password in `.env` identical to what you received on AURIN Data Provider(e.g., no extra spaces and no missing characters at the beginning or end of the long password)?

### "Status: 403, To gain access, you would need to sign the Domain API agreement"
This message is confusing because it is used for **two completely different problems**:

1. **You haven't signed the access agreement yet** → go to the AURIN Data Provider → Manage Access → My Agreements and sign it
2. **Your monthly credit balance has reached zero** → check the Dashboard (Step 5). If the counter shows 0, wait until the 1st of the month for the automatic refill, or contact AURIN if you need an urgent top-up

Always check the credit balance first before concluding something is wrong with your account setup.



## R Setup Checklist for First-Time Users

If you have never used R before, work through this list first:

1. **Install R**, download R 4.1 or later from [cran.r-project.org](https://cran.r-project.org/). Follow the installer instructions for your operating system. Version 4.1 is the minimum because the notebooks use R's native pipe (`|>`), which was introduced in that version.

2. **Install RStudio** (recommended for running notebooks), download RStudio Desktop from [posit.co/download/rstudio-desktop](https://posit.co/download/rstudio-desktop/). It gives you a Run button for each chunk of code and a Knit button to turn a notebook into an HTML report.

3. **Install the packages this guide needs.** Open RStudio and type this in the console (the pane titled *Console*), then press Enter:
   ```r
   install.packages(c("httr2", "jsonlite"))
   ```

   For the phase-2 notebooks you will need a few more. Rather than typing them out, open `training-materials-r/phase-2/install-packages.R` and click **Source**, which installs the whole set in one go.

4. **Create your `.env` file** as described in Step 3 above

6. **Run the verification code** in Step 4

4. **Open a notebook.** In RStudio, use File, Open File and choose
   `training-materials-r/phase-2/notebook-0-getting-started.Rmd`. Run one chunk at a time
   with the green arrow at its top-right corner, or click **Knit** to run the whole
   notebook and produce an HTML report.

Once the verification test shows `Status: 200` with a non-zero body length, you are ready to move on to the [Credit Calculator](./03-credit-calculator.md).