# ==============================================================================
# Script: 01_generate_22habit_data.R
# Sprint: Sprint 3 (Production R Analytics Engine - Home Energy Coach)
# Description: Generates the full 22-habit catalogue, N=300 synthetic student
#              households (WG & Single), persona-correlated commitments (for
#              recommenderlab & arules), and 4 weeks of check-ins.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(lubridate)
  library(readr)
  library(here)
})

set.seed(42)

# Output to Sprint 3 r_service/data directory (keeps Sprint 1/2 files untouched)
out_dir <- here::here("r_service", "data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Full 22-Habit Catalogue (Prerequisites, Personas & Carbon Factors)
# ------------------------------------------------------------------------------
habit_catalogue <- tibble::tribble(
  ~habit_id, ~name,                              ~category,       ~type,       ~requires_appliance, ~co2_saved_kg, ~bundle_affinity,
  1,  "Laundry in Green Hours",                  "Load-Shifting", "timing",    "washing_machine",   0.40,          "green_hours",
  2,  "Dishwasher in Green Hours",               "Load-Shifting", "timing",    "dishwasher",        0.25,          "green_hours",
  3,  "Charge Devices in Clean Hours",           "Load-Shifting", "timing",    "none",              0.10,          "green_hours",
  4,  "Run Dryer in Green Hours",                "Load-Shifting", "timing",    "dryer",             0.65,          "green_hours",
  5,  "Batch-Cook / Bake in Green Hours",        "Load-Shifting", "timing",    "none",              0.30,          "green_hours",
  6,  "Lower Room Heating by 1C",                "Heating",       "reduction", "none",              0.80,          "heating_water",
  7,  "Stoßlüften (5-Min Shock Vent)",           "Heating",       "reduction", "none",              0.50,          "heating_water",
  8,  "Night Heating Setback (17C)",             "Heating",       "reduction", "none",              0.65,          "heating_water",
  9,  "Close Blinds/Curtains at Dusk",           "Heating",       "reduction", "none",              0.25,          "heating_water",
  10, "Keep Furniture Clear of Radiators",       "Heating",       "one_time",  "none",              2.20,          "heating_water",
  11, "Radiator Bleeding (Air Purge)",           "Heating",       "one_time",  "none",              3.50,          "heating_water",
  12, "Shorter Showers (Under 5 Min)",           "Hot Water",     "reduction", "none",              0.60,          "heating_water",
  13, "Wash Laundry at 30C (Cold Cycle)",        "Appliances",    "reduction", "washing_machine",   0.35,          "appliance_eco",
  14, "Eco-Mode on Dishwasher",                  "Appliances",    "reduction", "dishwasher",        0.20,          "appliance_eco",
  15, "Air-Dry Laundry (Skip Dryer)",            "Appliances",    "reduction", "dryer",             0.75,          "appliance_eco",
  16, "Full-Load Only (Washer/Dishwasher)",      "Appliances",    "reduction", "washing_machine",   0.30,          "appliance_eco",
  17, "Kettle: Boil Only Needed Water",          "Kitchen",       "reduction", "none",              0.12,          "kitchen_standby",
  18, "Lids on Pots While Cooking",              "Kitchen",       "reduction", "none",              0.18,          "kitchen_standby",
  19, "Fridge at 7C / Freezer at -18C",          "Kitchen",       "one_time",  "none",              2.80,          "kitchen_standby",
  20, "Defrost Freezer Compartment",             "Kitchen",       "one_time",  "none",              3.10,          "kitchen_standby",
  21, "Standby Power Strip Off Overnight",       "Standby",       "reduction", "none",              0.15,          "kitchen_standby",
  22, "Replace Halogen/Old Bulbs with LEDs",     "Lighting",      "one_time",  "none",              5.00,          "kitchen_standby"
)

write_csv(habit_catalogue, file.path(out_dir, "habit_catalogue_22.csv"))

# ------------------------------------------------------------------------------
# 2. Generate Synthetic User Profiles (N = 300)
# ------------------------------------------------------------------------------
n_users  <- 300
user_ids <- sprintf("usr_%04d", 1:n_users)

flat_types <- sample(c("WG", "Single"), size = n_users, replace = TRUE, prob = c(0.70, 0.30))

# Latent behavioral archetype drives realistic habit co-occurrence for arules/UBCF
personas <- sample(
  c("green_hours", "heating_water", "appliance_eco", "kitchen_standby"),
  size = n_users,
  replace = TRUE,
  prob = c(0.30, 0.28, 0.22, 0.20)
)

profiles <- tibble(
  user_id   = user_ids,
  flat_type = flat_types,
  persona   = personas
) %>%
  mutate(
    num_flatmates = if_else(
      flat_type == "Single",
      1L,
      sample(2:5, size = n(), replace = TRUE, prob = c(0.40, 0.35, 0.15, 0.10))
    ),
    flat_size_sqm = if_else(
      flat_type == "Single",
      round(rnorm(n(), mean = 35, sd = 8)),
      round(rnorm(n(), mean = 25 * num_flatmates, sd = 12))
    ),
    flat_size_sqm = pmax(20, flat_size_sqm),
    
    heating_type   = sample(c("gas", "district", "electric"), size = n(), replace = TRUE, prob = c(0.55, 0.35, 0.10)),
    hot_water_type = sample(c("central", "electric_boiler"), size = n(), replace = TRUE, prob = c(0.75, 0.25)),
    
    has_washing_machine = sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.85, 0.15)),
    has_dishwasher = if_else(
      flat_type == "Single",
      sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.30, 0.70)),
      sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.65, 0.35))
    ),
    has_dryer = if_else(
      has_washing_machine,
      sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.25, 0.75)),
      FALSE
    ),
    
    baseline_annual_kwh = case_when(
      num_flatmates == 1 ~ round(rnorm(n(), 1400, 150)),
      num_flatmates == 2 ~ round(rnorm(n(), 2300, 200)),
      num_flatmates == 3 ~ round(rnorm(n(), 3100, 250)),
      TRUE               ~ round(rnorm(n(), 3900, 300))
    ),
    
    home_schedule = map_chr(seq_len(n()), function(x) {
      weekday_prob <- c(rep(0.90, 8), rep(0.30, 9), rep(0.85, 7))
      weekend_prob <- c(rep(0.90, 9), rep(0.70, 9), rep(0.90, 6))
      week_probs   <- c(rep(weekday_prob, 5), rep(weekend_prob, 2))
      paste0(as.integer(runif(168) < week_probs), collapse = "")
    })
  )

# ------------------------------------------------------------------------------
# 3. Simulate Persona-Correlated Commitments & Check-Ins (4-Week Horizon)
# ------------------------------------------------------------------------------
start_date <- as.Date("2026-10-05")
end_date   <- as.Date("2026-11-02")
sim_days   <- seq(start_date, end_date, by = "day")

commitments_list <- list()
checkins_list    <- list()

for (i in seq_len(nrow(profiles))) {
  u <- profiles[i, ]
  
  eligible <- habit_catalogue %>%
    filter(
      (requires_appliance == "none") |
      (requires_appliance == "washing_machine" & u$has_washing_machine) |
      (requires_appliance == "dishwasher" & u$has_dishwasher) |
      (requires_appliance == "dryer" & u$has_dryer)
    ) %>%
    mutate(
      sample_weight = if_else(bundle_affinity == u$persona, 4.5, 1.0)
    )
  
  n_choose <- min(nrow(eligible), sample(3:6, 1, prob = c(0.25, 0.35, 0.25, 0.15)))
  chosen_habits <- eligible %>%
    slice_sample(n = n_choose, weight_by = sample_weight, replace = FALSE)
  
  user_adherence <- runif(1, min = 0.50, max = 0.90)
  
  for (h in seq_len(nrow(chosen_habits))) {
    cur_habit   <- chosen_habits[h, ]
    comm_id     <- sprintf("comm_%s_%02d", u$user_id, cur_habit$habit_id)
    target_freq <- if_else(cur_habit$type == "one_time", 1L, sample(2:5, 1))
    
    commitments_list[[length(commitments_list) + 1]] <- tibble(
      commitment_id             = comm_id,
      user_id                   = u$user_id,
      habit_id                  = cur_habit$habit_id,
      start_date                = start_date,
      target_frequency_per_week = target_freq,
      status                    = "active"
    )
    
    if (cur_habit$type == "one_time") {
      active_days <- sample(sim_days[1:14], size = 1)
    } else {
      n_events    <- max(2, round(length(sim_days) * (user_adherence * 0.45)))
      active_days <- sort(sample(sim_days, size = min(length(sim_days), n_events)))
    }
    
    user_checkins <- tibble(
      checkin_id   = sprintf("chk_%s_%02d_%02d", u$user_id, cur_habit$habit_id, seq_along(active_days)),
      user_id      = u$user_id,
      habit_id     = cur_habit$habit_id,
      timestamp    = as.POSIXct(
        paste(active_days, sprintf("%02d:00:00", sample(10:21, length(active_days), replace = TRUE))),
        tz = "Europe/Berlin"
      ),
      co2_saved_kg = cur_habit$co2_saved_kg,
      completed    = runif(length(active_days)) < user_adherence
    )
    checkins_list[[length(checkins_list) + 1]] <- user_checkins
  }
}

commitments_df  <- bind_rows(commitments_list)
checkins_df     <- bind_rows(checkins_list)
profiles_export <- profiles %>% select(-persona)

# ------------------------------------------------------------------------------
# 4. Export CSV Deliverables
# ------------------------------------------------------------------------------
write_csv(profiles_export, file.path(out_dir, "users_300.csv"))
write_csv(commitments_df,  file.path(out_dir, "commitments_22h.csv"))
write_csv(checkins_df,     file.path(out_dir, "checkins_22h.csv"))

cat("\n[SUCCESS] Sprint 3 22-Habit dataset generated in r_service/data/:\n")
cat(" - Habit catalogue: ", nrow(habit_catalogue), " habits\n")
cat(" - Users:           ", nrow(profiles_export), " households\n")
cat(" - Commitments:     ", nrow(commitments_df),  " records\n")
cat(" - Check-ins:       ", nrow(checkins_df),     " events\n\n")