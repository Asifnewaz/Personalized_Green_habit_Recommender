# ==============================================================================
# Module: r_service/R/forecast_co2.R
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Engine)
# Description: Performs multi-seasonal MSTL decomposition (24h daily + 168h
#              weekly cycles), benchmarks STL+ETS, Harmonic ARIMA, and SNAIVE
#              on a 24h holdout via RMSE/MAE, and forecasts the next 24 hours
#              of German grid CO2 intensity (gCO2/kWh) to identify Green Hours.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(readr)
  library(forecast)
  library(here)
})

# ------------------------------------------------------------------------------
# 1. Load & Prepare Gap-Free Multi-Seasonal Time Series (msts: 24h & 168h)
# ------------------------------------------------------------------------------
prepare_grid_series <- function(input_path = here::here("r_service", "data", "smard_uba_hourly.csv")) {
  if (!file.exists(input_path)) {
    stop("SMARD UBA hourly CSV not found at: ", input_path, " — run smard_uba_ingest.R first.")
  }
  
  raw_df <- read_csv(input_path, show_col_types = FALSE) %>%
    mutate(datetime = with_tz(as_datetime(datetime), tzone = "Europe/Berlin")) %>%
    arrange(datetime) %>%
    distinct(datetime, .keep_all = TRUE)
  
  # Build complete hourly sequence and linearly interpolate any rare API gaps
  full_grid <- tibble(
    datetime = seq(min(raw_df$datetime), max(raw_df$datetime), by = "1 hour")
  ) %>%
    left_join(raw_df, by = "datetime") %>%
    mutate(
      co2_g_per_kwh = approx(
        x    = seq_along(co2_g_per_kwh),
        y    = co2_g_per_kwh,
        xout = seq_along(co2_g_per_kwh),
        rule = 2
      )$y
    )
  
  # Multi-seasonal ts object capturing both 24-hour (daily) and 168-hour (weekly) cycles
  co2_msts <- msts(full_grid$co2_g_per_kwh, seasonal.periods = c(24, 168))
  
  return(list(df = full_grid, msts = co2_msts))
}

# ------------------------------------------------------------------------------
# 2. Fit & Forecast Candidate Models (STL+ETS, Harmonic ARIMA, SNAIVE)
# ------------------------------------------------------------------------------
generate_candidate_forecasts <- function(train_msts, h = 24) {
  # Model 1: Multi-Seasonal STL Decomposition + ETS on seasonally adjusted series
  fc_stl_ets <- stlf(train_msts, method = "ets", h = h, level = 80, robust = TRUE)
  
  # Model 2: Dynamic Harmonic Regression (24h & 168h Fourier terms) + Auto-ARIMA
  xreg_train <- fourier(train_msts, K = c(4, 3))
  xreg_fut   <- fourier(train_msts, K = c(4, 3), h = h)
  fit_arima  <- auto.arima(train_msts, xreg = xreg_train, seasonal = FALSE, stepwise = TRUE, approximation = TRUE)
  fc_arima   <- forecast(fit_arima, xreg = xreg_fut, h = h, level = 80)
  
  # Model 3: 24-Hour Seasonal Naive Baseline
  ts_24h     <- ts(as.numeric(train_msts), frequency = 24)
  fc_snaive  <- snaive(ts_24h, h = h, level = 80)
  
  return(list(
    stl_ets        = fc_stl_ets,
    harmonic_arima = fc_arima,
    snaive_24h     = fc_snaive
  ))
}

# ------------------------------------------------------------------------------
# 3. Main Forecasting & Green-Window Ranking Pipeline
# ------------------------------------------------------------------------------
run_co2_forecast <- function(horizon_hours = 24, save_outputs = TRUE) {
  prep     <- prepare_grid_series()
  grid_df  <- prep$df
  co2_msts <- prep$msts
  n_total  <- length(co2_msts)
  
  if (n_total < 336) {
    stop("Need at least 2 weeks (336 hours) of data for weekly STL seasonality; found: ", n_total)
  }
  
  # --- A. Multi-Seasonal STL Decomposition Export (24h & 168h components) ---
  mstl_fit <- mstl(co2_msts, robust = TRUE)
  stl_components <- tibble(
    datetime      = grid_df$datetime,
    co2_g_per_kwh = round(as.numeric(mstl_fit[, "Data"]), 2),
    trend         = round(as.numeric(mstl_fit[, "Trend"]), 2),
    season_24h    = round(as.numeric(mstl_fit[, "Seasonal24"]), 2),
    season_168h   = round(as.numeric(mstl_fit[, "Seasonal168"]), 2),
    remainder     = round(as.numeric(mstl_fit[, "Remainder"]), 2)
  )
  
  # --- B. 24-Hour Holdout Evaluation (Train vs Last 24 Hours) ---
  train_vec <- as.numeric(co2_msts)[1:(n_total - horizon_hours)]
  test_vec  <- as.numeric(co2_msts)[(n_total - horizon_hours + 1):n_total]
  train_msts <- msts(train_vec, seasonal.periods = c(24, 168))
  
  cv_fcs <- generate_candidate_forecasts(train_msts, h = horizon_hours)
  
  eval_metrics <- bind_rows(lapply(names(cv_fcs), function(mname) {
    preds <- as.numeric(cv_fcs[[mname]]$mean)
    err   <- test_vec - preds
    tibble(
      model = mname,
      RMSE  = round(sqrt(mean(err^2)), 2),
      MAE   = round(mean(abs(err)), 2),
      MAPE  = round(mean(abs(err / test_vec)) * 100, 2)
    )
  })) %>%
    arrange(RMSE)
  
  best_model_name <- eval_metrics$model[1]
  message("Holdout benchmark complete. Best model by RMSE: ", best_model_name,
          " (RMSE = ", eval_metrics$RMSE[1], " gCO2/kWh, MAE = ", eval_metrics$MAE[1], ")")
  
  # --- C. Refit on 100% of History & Forecast Next 24 Hours ---
  full_fcs  <- generate_candidate_forecasts(co2_msts, h = horizon_hours)
  winner_fc <- full_fcs[[best_model_name]]
  
  future_times <- seq(max(grid_df$datetime) + hours(1), by = "1 hour", length.out = horizon_hours)
  
  forecast_df <- tibble(
    datetime        = future_times,
    hour_of_day     = hour(future_times),
    day_of_week     = as.character(wday(future_times, label = TRUE, week_start = 1)),
    model_used      = best_model_name,
    forecast_co2_g  = round(pmax(15, as.numeric(winner_fc$mean)), 2),
    ci80_lower_g    = round(pmax(10, as.numeric(winner_fc$lower[, 1])), 2),
    ci80_upper_g    = round(as.numeric(winner_fc$upper[, 1]), 2)
  ) %>%
    mutate(
      clean_rank      = rank(forecast_co2_g, ties.method = "first"),
      is_green_window = clean_rank <= 4 | forecast_co2_g < 250
    )
  
  if (save_outputs) {
    out_dir <- here::here("r_service", "outputs")
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    
    write_csv(eval_metrics,   file.path(out_dir, "forecast_model_metrics.csv"))
    write_csv(stl_components, file.path(out_dir, "stl_decomposition_components.csv"))
    write_csv(forecast_df,    file.path(out_dir, "co2_forecast_24h.csv"))
    
    message("[SUCCESS] Forecast outputs saved to: ", out_dir)
  }
  
  return(list(
    metrics    = eval_metrics,
    forecast   = forecast_df,
    components = stl_components
  ))
}

# Standalone CLI execution
if (sys.nframe() == 0) {
  res <- run_co2_forecast(horizon_hours = 24, save_outputs = TRUE)
  cat("\n--- Model Comparison (24h Holdout) ---\n")
  print(res$metrics)
  cat("\n--- Next 24h Forecast & Top Green Windows ---\n")
  print(res$forecast %>% select(datetime, hour_of_day, forecast_co2_g, clean_rank, is_green_window), n = 24)
}