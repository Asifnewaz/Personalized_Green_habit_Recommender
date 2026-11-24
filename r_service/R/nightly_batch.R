# ==============================================================================
# Module: r_service/R/nightly_batch.R
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Engine)
# Description: End-to-end nightly batch orchestrator invoked by plumber.R
#              (and CLI/cron). Executes SMARD+UBA ingestion, 24h grid CO2
#              forecasting, and personalized 22-habit recommendations.
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(lubridate)
})

source(here::here("r_service", "R", "smard_uba_ingest.R"), local = TRUE)
source(here::here("r_service", "R", "forecast_co2.R"),     local = TRUE)
source(here::here("r_service", "R", "recommend_habits.R"), local = TRUE)

execute_nightly_batch <- function(n_weeks = 4, horizon_hours = 24, top_n = 3) {
  started_at <- Sys.time()
  message("=== [HEC Nightly Batch] Started at ", format(started_at, "%Y-%m-%d %H:%M:%S %Z"), " ===")
  
  # Step 1: Ingest hourly German electricity mix from SMARD & weight by UBA gCO2/kWh
  grid_df <- ingest_smard_uba_series(n_weeks = n_weeks, save_csv = TRUE)
  
  # Step 2: Benchmark STL+ETS vs Harmonic ARIMA vs SNAIVE & forecast next 24h
  fc_res <- run_co2_forecast(horizon_hours = horizon_hours, save_outputs = TRUE)
  
  # Step 3: Run Collaborative Filtering + Apriori + 168-bit schedule matching
  rec_res <- run_habit_recommender(top_n = top_n, save_outputs = TRUE)
  
  finished_at <- Sys.time()
  duration_sec <- round(as.numeric(difftime(finished_at, started_at, units = "secs")), 2)
  
  message("=== [HEC Nightly Batch] Completed in ", duration_sec, "s ===")
  
  list(
    status              = "success",
    started_at          = format(started_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    finished_at         = format(finished_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    duration_seconds    = duration_sec,
    smard_hours_ingested = nrow(grid_df),
    winning_forecast_model = fc_res$metrics$model[1],
    forecast_rmse_gco2  = fc_res$metrics$RMSE[1],
    green_windows_next_24h = sum(fc_res$forecast$is_green_window),
    winning_cf_model    = rec_res$cv_metrics$model[1],
    apriori_rules_mined = nrow(rec_res$rules),
    users_scored        = length(unique(rec_res$recommendations$user_id)),
    recommendations_generated = nrow(rec_res$recommendations)
  )
}

if (sys.nframe() == 0) {
  summary_payload <- execute_nightly_batch()
  cat("\n--- Batch Summary Payload ---\n")
  print(summary_payload)
}