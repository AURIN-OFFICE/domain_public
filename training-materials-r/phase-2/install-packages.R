# Install everything the phase-2 notebooks need.
#
# Run this once, before opening the notebooks. In RStudio: open this file and
# click "Source". From a terminal:
#
#     Rscript install-packages.R
#
# It takes a few minutes the first time. If a package is already installed it is
# skipped, so it is safe to re-run.

packages <- c(
  "httr2",      # sends requests to the API and receives responses
  "jsonlite",   # reads and writes JSON, the format the API speaks
  "dplyr",      # filters, sorts, and summarises tables
  "purrr",      # builds tables from the API's nested records
  "tibble",     # the table type used throughout the notebooks
  "readr",      # writes your results to CSV
  "ggplot2",    # draws the charts in Notebook 2
  "leaflet",    # draws the interactive map in Notebook 4
  "knitr",      # runs the notebooks
  "rmarkdown"   # turns the notebooks into HTML reports
)

missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) == 0L) {
  cat("All", length(packages), "packages are already installed. Nothing to do.\n")
} else {
  cat("Installing", length(missing), "package(s):", paste(missing, collapse = ", "), "\n\n")
  install.packages(missing, repos = "https://cloud.r-project.org")

  # Report anything that still failed, so the problem is visible rather than silent
  still_missing <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
  cat("\n")
  if (length(still_missing) == 0L) {
    cat("Done. All packages installed successfully.\n")
  } else {
    cat("These packages failed to install:", paste(still_missing, collapse = ", "), "\n")
    cat("Read the messages above for the reason, then try installing them one at a time.\n")
  }
}
