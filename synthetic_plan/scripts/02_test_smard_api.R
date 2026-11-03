# ==============================================================================
# Script: 02_test_smard_api.R
# Ticket: HEC-66 / SMARD Ingestion Test (Sprint 1)
# Description: Connects to the SMARD public API and downloads sample
#              German electricity generation data.
# ==============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
})

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

# 1223 = Total generation, DE = Germany, index_hour.json = Available timestamps
index_url <- "https://www.smard.de/app/chart_data/1223/DE/index_hour.json"

cat("Fetching SMARD timestamp index from:", index_url, "\n")

req <- request(index_url) %>%
  req_headers("User-Agent" = "HomeEnergyCoach/1.0 (Student Project; Frankfurt UAS)")

resp <- req_perform(req)

if (resp_status(resp) == 200) {
  index_data <- resp_body_json(resp)
  raw_ts <- tail(index_data$timestamps, 1)[[1]]
  
  # Format as exact full integer string to avoid scientific notation (e.g. 1.79e+12)
  latest_timestamp <- sprintf("%.0f", raw_ts)
  
  cat("Successfully fetched index. Latest timestamp:", latest_timestamp, "\n")
  
  # Fetch generation records for the latest timestamp
  data_url <- sprintf("https://www.smard.de/app/chart_data/1223/DE/1223_DE_hour_%s.json", latest_timestamp)
  cat("Fetching generation records from:", data_url, "\n")
  
  data_req <- request(data_url) %>%
    req_headers("User-Agent" = "HomeEnergyCoach/1.0")
  data_resp <- req_perform(data_req)
  
  if (resp_status(data_resp) == 200) {
    writeBin(resp_body_raw(data_resp), "data/raw/sample_smard_actual.json")
    
    sample_data <- fromJSON("data/raw/sample_smard_actual.json")
    cat("\n[SUCCESS] SMARD download verified!\n")
    cat(" - Output file: data/raw/sample_smard_actual.json\n")
    cat(" - Series records downloaded:", nrow(sample_data$series), "timestamps\n\n")
  } else {
    stop("Failed to fetch SMARD time-series records.")
  }
} else {
  stop("Failed to connect to SMARD index endpoint.")
}