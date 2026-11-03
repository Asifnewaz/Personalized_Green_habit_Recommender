# ==============================================================================
# Script: 01_generate_synthetic_data.R
# Ticket: HEC-66 (Data & R Analytics - Sprint 1)
# Description: Generates realistic synthetic user profiles, habit commitments,
#              and simulated check-in logs based on Stromspiegel 2025, UBA,
#              and REFIT distribution rules.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(lubridate)
})

set.seed(42)

# Ensure output directory exists
dir.create("data/synthetic", recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Define Habit Catalogue Subset (Prerequisites & Carbon Factors)
# ------------------------------------------------------------------------------
habit_catalogue <- tibble::tribble(
  ~habit_id, ~name, ~type, ~requires_appliance, ~co2_saved_kg,
  1,  "Laundry in Green Hours",   "timing",    "washing_machine", 0.40,
  2,  "Dishwasher in Green Hours","timing",    "dishwasher",      0.25,
  3,  "Charge Devices Clean Hours","timing",   "none",            0.10,
  4,  "Lower Heating by 1C",      "reduction", "none",            0.80,
  5,  "Stoßlüften (Shock Vent)",  "reduction", "none",            0.50,
  6,  "Shorter Showers (5 min)",  "reduction", "none",            0.60,
  7,  "Wash at 30C",              "reduction", "washing_machine", 0.35,
  8,  "Standby Power Off",        "reduction", "none",            0.15,
  9,  "LED Bulbs Installed",      "one_time",  "none",            5.00,
  10, "Radiator Bleeding",        "one_time",  "none",            3.50
)

# ------------------------------------------------------------------------------
# 2. Generate Synthetic User Profiles (N = 300)
# ------------------------------------------------------------------------------
n_users <- 300

user_ids <- sprintf("usr_%04d", 1:n_users)

# Split: 70% WG (shared flats), 30% single-person flats
flat_types <- sample(c("WG", "Single"), size = n_users, replace = TRUE, prob = c(0.70, 0.30))

profiles <- tibble(
  user_id = user_ids,
  flat_type = flat_types
) %>%
  mutate(
    # Flatmate counts
    num_flatmates = if_else(flat_type == "Single", 1L, sample(2:5, size = n(), replace = TRUE, prob = c(0.4, 0.35, 0.15, 0.1))),
    
    # Floor size in sqm (approximate distribution)
    flat_size_sqm = if_else(
      flat_type == "Single",
      round(rnorm(n(), mean = 35, sd = 8)),
      round(rnorm(n(), mean = 25 * num_flatmates, sd = 12))
    ),
    flat_size_sqm = pmax(20, flat_size_sqm),
    
    # Heating infrastructure
    heating_type = sample(c("gas", "district", "electric"), size = n(), replace = TRUE, prob = c(0.55, 0.35, 0.10)),
    hot_water_type = sample(c("central", "electric_boiler"), size = n(), replace = TRUE, prob = c(0.75, 0.25)),
    
    # Appliance availability
    has_washing_machine = sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.85, 0.15)),
    has_dishwasher = if_else(flat_type == "Single",
                             sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.30, 0.70)),
                             sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.65, 0.35))),
    
    # Baseline Stromspiegel 2025 consumption bands (kWh/year per flat)
    baseline_annual_kwh = case_when(
      num_flatmates == 1 ~ round(rnorm(n(), 1400, 150)),
      num_flatmates == 2 ~ round(rnorm(n(), 2300, 200)),
      num_flatmates == 3 ~ round(rnorm(n(), 3100, 250)),
      TRUE               ~ round(rnorm(n(), 3900, 300))
    ),
    
    # 24x7 Schedule representation (168-bit binary string: 1 = home, 0 = away)
    # Students typically home evenings/weekends
    home_schedule = map_chr(seq_len(n()), function(x) {
      weekday_prob <- c(rep(0.9, 8), rep(0.3, 9), rep(0.85, 7)) # 0:00 - 23:00
      weekend_prob <- c(rep(0.9, 9), rep(0.7, 9), rep(0.9, 6))
      week_probs <- c(rep(weekday_prob, 5), rep(weekend_prob, 2))
      paste0(as.integer(runif(168) < week_probs), collapse = "")
    })
  )

# ------------------------------------------------------------------------------
# 3. Simulate Commitments and Check-Ins (4-Week Horizon)
# ------------------------------------------------------------------------------
start_date <- as.Date("2026-10-05")
end_date   <- as.Date("2026-11-02")
sim_days   <- seq(start_date, end_date, by = "day")

commitments_list <- list()
checkins_list    <- list()

for (i in seq_len(nrow(profiles))) {
  u <- profiles[i, ]
  
  # Eligible habits based on flat appliances
  eligible <- habit_catalogue %>%
    filter(
      (requires_appliance == "none") |
      (requires_appliance == "washing_machine" & u$has_washing_machine) |
      (requires_appliance == "dishwasher" & u$has_dishwasher)
    )
  
  # Pick 1 to 3 habits to commit to
  chosen_habits <- eligible %>% slice_sample(n = sample(1:3, 1))
  
  # User baseline adherence probability (between 50% and 90%)
  user_adherence <- runif(1, min = 0.50, max = 0.90)
  
  for (h in seq_len(nrow(chosen_habits))) {
    cur_habit <- chosen_habits[h, ]
    comm_id <- sprintf("comm_%s_%d", u$user_id, cur_habit$habit_id)
    
    commitments_list[[length(commitments_list) + 1]] <- tibble(
      commitment_id = comm_id,
      user_id = u$user_id,
      habit_id = cur_habit$habit_id,
      start_date = start_date,
      target_frequency_per_week = sample(2:4, 1),
      status = "active"
    )
    
    # Simulate check-in events across the 28 days
    active_days <- sample(sim_days, size = round(length(sim_days) * (user_adherence * 0.4)))
    
    if (length(active_days) > 0) {
      user_checkins <- tibble(
        checkin_id = sprintf("chk_%s_%d_%02d", u$user_id, cur_habit$habit_id, seq_along(active_days)),
        user_id = u$user_id,
        habit_id = cur_habit$habit_id,
        timestamp = as.POSIXct(paste(active_days, sprintf("%02d:00:00", sample(10:21, length(active_days), replace = TRUE))), tz = "Europe/Berlin"),
        co2_saved_kg = cur_habit$co2_saved_kg,
        completed = runif(length(active_days)) < user_adherence
      )
      checkins_list[[length(checkins_list) + 1]] <- user_checkins
    }
  }
}

commitments_df <- bind_rows(commitments_list)
checkins_df    <- bind_rows(checkins_list)

# ------------------------------------------------------------------------------
# 4. Export CSV Deliverables
# ------------------------------------------------------------------------------
write.csv(profiles,       "data/synthetic/synthetic_users.csv",       row.names = FALSE)
write.csv(commitments_df, "data/synthetic/synthetic_commitments.csv", row.names = FALSE)
write.csv(checkins_df,    "data/synthetic/synthetic_checkins.csv",    row.names = FALSE)

cat("\n[SUCCESS] Synthetic data generation complete:\n")
cat(" - Users generated:      ", nrow(profiles), " -> data/synthetic/synthetic_users.csv\n")
cat(" - Commitments recorded: ", nrow(commitments_df), " -> data/synthetic/synthetic_commitments.csv\n")
cat(" - Check-in rows:        ", nrow(checkins_df), " -> data/synthetic/synthetic_checkins.csv\n\n")