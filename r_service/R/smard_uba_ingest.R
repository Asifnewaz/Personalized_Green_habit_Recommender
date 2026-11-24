# ==============================================================================
# Module: r_service/R/smard_uba_ingest.R
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Engine)
# Description: Fetches hourly German electricity generation by energy source
#              from the Bundesnetzagentur SMARD REST API, weights each source
#              by Umweltbundesamt (UBA) gCO2/kWh emission factors, and outputs
#              an hourly carbon intensity time series for forecasting.
# ==============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(lubridate)
  library(readr)
  library(here)
})

# ------------------------------------------------------------------------------
# 1. SMARD Filter IDs & Umweltbundesamt (UBA) Emission Factors (gCO2eq / kWh)
# ------------------------------------------------------------------------------
smard_uba_lookup <- tibble::tribble(
  ~filter_id, ~source_name,         ~category,     ~uba_gco2_per_kwh,
  1223L,      "lignite",            "fossil",      1075,
  4069L,      "hard_coal",          "fossil",      830,
  4071L,      "natural_gas",        "fossil",      400,
  1228L,      "other_conventional", "fossil",      700,
  4066L,      "biomass",            "renewable",   230,
  1226L,      "hydro",              "renewable",   24,
  1225L,      "wind_offshore",      "renewable",   9,
  4067L,      "wind_onshore",       "renewable",   11,
  4068L,      "solar",              "renewable",   33,
  1227L,      "other_renewables",   "renewable",   30
)

# ------------------------------------------------------------------------------
# 2. Fetch Single SMARD Filter Series Across Recent Weekly Chunks
# ------------------------------------------------------------------------------
fetch_smard_filter <- function(filter_id, source_name, n_weeks = 4, region = "DE", resolution = "hour") {
  base_url  <- "https://www.smard.de/app/chart_data"
  index_url <- sprintf("%s/%d/%s/index_%s.json", base_url, filter_id, region, resolution)
  
  idx_resp <- request(index_url) %>%
    req_timeout(15) %>%
    req_retry(max_tries = 3) %>%
    req_perform() %>%
    resp_body_json()
  
  timestamps <- unlist(idx_resp$timestamps)
  if (length(timestamps) == 0) {
    stop(sprintf("No SMARD index timestamps returned for filter %d (%s)", filter_id, source_name))
  }
  
  # Take the most recent n_weeks weekly chunk timestamps
  target_ts <- tail(sort(timestamps), n_weeks)
  
  chunk_dfs <- map(target_ts, function(ts) {
    data_url <- sprintf("%s/%d/%s/%d_%s_%s_%.0f.json", base_url, filter_id, region, filter_id, region, resolution, ts)
    
    raw_series <- request(data_url) %>%
      req_timeout(15) %>%
      req_retry(max_tries = 3) %>%
      req_perform() %>%
      resp_body_json() %>%
      purrr::pluck("series")
    
    # Convert list of [timestamp_ms, value] pairs cleanly even when value is NULL
    tibble(
      timestamp_ms = map_dbl(raw_series, ~ as.numeric(.x[[1]])),
      gen_mwh      = map_dbl(raw_series, ~ if (is.null(.x[[2]])) NA_real_ else as.numeric(.x[[2]]))
    )
  })
  
  bind_rows(chunk_dfs) %>%
    distinct(timestamp_ms, .keep_all = TRUE) %>%
    mutate(
      source_name = source_name,
      gen_mwh     = pmax(0, gen_mwh) # Guard against tiny negative pumped/aux noise
    )
}

# ------------------------------------------------------------------------------
# 3. Main Ingestion & UBA Weighted Intensity Pipeline
# ------------------------------------------------------------------------------
ingest_smard_uba_series <- function(n_weeks = 4, save_csv = TRUE) {
  message("Fetching ", n_weeks, " weeks of hourly generation across ", nrow(smard_uba_lookup), " SMARD sources...")
  
  all_sources_long <- pmap_dfr(
    list(smard_uba_lookup$filter_id, smard_uba_lookup$source_name),
    function(fid, sname) {
      message("  -> Fetching filter ", fid, " (", sname, ")...")
      Sys.sleep(0.15) # Polite rate-limit pause for Bundesnetzagentur API
      fetch_smard_filter(filter_id = fid, source_name = sname, n_weeks = n_weeks)
    }
  )
  
  # Join UBA emission factors and aggregate per hour
  hourly_grid <- all_sources_long %>%
    left_join(smard_uba_lookup, by = "source_name") %>%
    filter(!is.na(gen_mwh)) %>%
    group_by(timestamp_ms) %>%
    summarise(
      n_sources_reported = n(),
      total_gen_mwh      = sum(gen_mwh, na.rm = TRUE),
      renewable_gen_mwh  = sum(gen_mwh[category == "renewable"], na.rm = TRUE),
      total_co2_kg       = sum(gen_mwh * uba_gco2_per_kwh, na.rm = TRUE), # MWh * g/kWh = kg CO2
      .groups            = "drop"
    ) %>%
    filter(total_gen_mwh > 0, n_sources_reported >= 7) %>% # Drop incomplete trailing hours
    mutate(
      datetime         = as_datetime(timestamp_ms / 1000, tz = "Europe/Berlin"),
      renewable_share  = round((renewable_gen_mwh / total_gen_mwh) * 100, 2),
      co2_g_per_kwh    = round(total_co2_kg / total_gen_mwh, 2),
      # Classify clean windows: green (<250 g), moderate (250-400 g), high (>400 g)
      grid_status      = case_when(
        co2_g_per_kwh < 250 ~ "green",
        co2_g_per_kwh <= 400 ~ "moderate",
        TRUE ~ "high"
      )
    ) %>%
    arrange(datetime) %>%
    select(datetime, total_gen_mwh, renewable_gen_mwh, renewable_share, co2_g_per_kwh, grid_status)
  
  if (save_csv) {
    out_path <- here::here("r_service", "data", "smard_uba_hourly.csv")
    write_csv(hourly_grid, out_path)
    message("[SUCCESS] Saved ", nrow(hourly_grid), " hourly UBA-weighted records to: ", out_path)
  }
  
  return(hourly_grid)
}

# Allow standalone execution via Rscript while remaining source()-able by batch scripts
if (sys.nframe() == 0) {
  grid_df <- ingest_smard_uba_series(n_weeks = 4, save_csv = TRUE)
  print(tail(grid_df, 10))
  cat("\nSummary of UBA-Weighted Grid Intensity (gCO2/kWh):\n")
  print(summary(grid_df$co2_g_per_kwh))
}