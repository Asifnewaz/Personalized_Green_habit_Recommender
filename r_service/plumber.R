# ==============================================================================
# API: r_service/plumber.R
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Microservice)
# Description: Strictly thin HTTP transport & JSON serialization layer.
#              Contains ZERO domain ML/analytics logic; delegates all compute
#              to r_service/R/nightly_batch.R.
# ==============================================================================

library(plumber)
library(jsonlite)
library(here)

source(here::here("r_service", "R", "nightly_batch.R"))

#* @apiTitle Home Energy Coach - R Analytics Microservice
#* @apiDescription Decoupled R 4.6.2 batch analytics engine (SMARD+UBA ingestion, time-series CO2 forecasting, and habit recommendations).

#* Health check endpoint for Docker / FastAPI readiness probes
#* @get /health
#* @serializer unboxedJSON
function() {
  list(
    status    = "healthy",
    service   = "hec-r-analytics",
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
}

#* Trigger the nightly analytics batch pipeline
#* @param n_weeks:int Number of historical SMARD weeks to ingest (default: 4)
#* @param horizon_hours:int Forecast horizon in hours (default: 24)
#* @param top_n:int Top recommendations per user (default: 3)
#* @post /run-nightly-batch
#* @serializer unboxedJSON
function(res, n_weeks = 4, horizon_hours = 24, top_n = 3) {
  tryCatch({
    result <- execute_nightly_batch(
      n_weeks       = as.integer(n_weeks),
      horizon_hours = as.integer(horizon_hours),
      top_n         = as.integer(top_n)
    )
    res$status <- 200L
    return(result)
  }, error = function(e) {
    res$status <- 500L
    list(
      status  = "error",
      message = conditionMessage(e)
    )
  })
}