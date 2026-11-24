# ==============================================================================
# Home Energy Coach - Sprint 2 Exploratory Data Analysis (EDA)
# Authors: Madhusudan Ambulkar & Tanvir
# Course: High Integrity Systems (WS 2026/27) - FUAS
# Description:
#   1. Analyzes synthetic student household consumption & appliance distributions.
#   2. Evaluates diurnal & seasonal German grid CO2 intensity (SMARD API data).
#   3. Decodes 168-bit home schedules & evaluates appliance load-shifting overlap.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(lubridate)
  library(jsonlite)
  library(ggplot2)
})

# --- 0. Directory Setup & Strict Schema Ingestion ---------------------------
# --- 0. Directory Setup & Strict Schema Ingestion ---------------------------
# Automatically resolves repo root via .here / .git across Windows & Linux Docker
repo_root <- here::here()
fig_dir   <- here::here("eda", "outputs", "figures")
tab_dir   <- here::here("eda", "outputs", "tables")

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

# Helper to recursively locate any file inside synthetic_plan/
resolve_data_path <- function(filename) {
  matches <- list.files(
    path       = here::here("synthetic_plan"),
    pattern    = paste0("^", filename, "$"),
    recursive  = TRUE,
    full.names = TRUE
  )
  if (length(matches) == 0) {
    stop(paste("File not found anywhere under synthetic_plan/:", filename))
  }
  return(matches[1])
}

# CRITICAL: Force home_schedule as character so 168-bit string never casts to numeric
users <- read_csv(
  resolve_data_path("synthetic_users.csv"),
  col_types = cols(
    user_id       = col_character(),
    flat_type     = col_character(),
    home_schedule = col_character(),
    .default      = col_guess()
  )
)

commitments <- read_csv(resolve_data_path("synthetic_commitments.csv"), show_col_types = FALSE)
checkins    <- read_csv(resolve_data_path("synthetic_checkins.csv"), show_col_types = FALSE)

# Standardize column names dynamically in case minor suffix variations exist
names(users)    <- str_replace(names(users), "^num_flatm.*", "num_flatmates")
names(users)    <- str_replace(names(users), "^flat_size_s.*", "flat_size_sqm")
names(users)    <- str_replace(names(users), "^heating_ty.*", "heating_type")
names(users)    <- str_replace(names(users), "^hot_water_.*", "hot_water_type")
names(users)    <- str_replace(names(users), "^has_washi.*", "has_washing_machine")
names(users)    <- str_replace(names(users), "^has_dishw.*", "has_dishwasher")
names(users)    <- str_replace(names(users), "^baseline_a.*", "baseline_annual_kwh")
names(checkins) <- str_replace(names(checkins), "^co2_saved.*", "co2_saved_kg")

# Defensive Assertion (High Integrity Systems check)
stopifnot(
  nrow(users) == 300,
  all(nchar(users$home_schedule) == 168),
  !any(is.na(users$baseline_annual_kwh))
)

theme_hec <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "grey35", size = 10),
    legend.position = "bottom"
  )

# ==============================================================================
# PART 1: Household Consumption, Appliance Ownership & Baseline Habit Adoption
# ==============================================================================

# 1A. Summary Table by Flat Type & Heating Type
summary_households <- users %>%
  group_by(flat_type, heating_type) %>%
  summarise(
    n_users          = n(),
    share_pct        = round(n() / nrow(users) * 100, 1),
    mean_flatmates   = round(mean(num_flatmates), 2),
    mean_sqm         = round(mean(flat_size_sqm), 1),
    mean_kwh         = round(mean(baseline_annual_kwh), 1),
    sd_kwh           = round(sd(baseline_annual_kwh), 1),
    median_kwh       = round(median(baseline_annual_kwh), 1),
    iqr_kwh          = round(IQR(baseline_annual_kwh), 1),
    washing_mach_pct = round(mean(has_washing_machine) * 100, 1),
    dishwasher_pct   = round(mean(has_dishwasher) * 100, 1),
    .groups = "drop"
  )

write_csv(summary_households, file.path(tab_dir, "01_household_consumption_summary.csv"))

# 1B. Plot: Annual Electricity Consumption Distribution (WG vs Single)
p1 <- ggplot(users, aes(x = baseline_annual_kwh, fill = flat_type)) +
  geom_histogram(aes(y = after_stat(density)), bins = 25, alpha = 0.55, position = "identity") +
  geom_density(aes(color = flat_type), linewidth = 1, fill = NA) +
  geom_vline(xintercept = c(1105, 4702), linetype = "dashed", color = "grey30") +
  scale_fill_manual(values = c("Single" = "#2b8cbe", "WG" = "#31a354")) +
  scale_color_manual(values = c("Single" = "#08519c", "WG" = "#006d2c")) +
  labs(
    title    = "Baseline Annual Electricity Demand by Household Type (N = 300)",
    subtitle = "Calibrated against Stromspiegel 2025 bounds (dashed lines: 1,105 - 4,702 kWh/yr)",
    x        = "Baseline Annual Consumption (kWh/year)",
    y        = "Density",
    fill     = "Housing Type",
    color    = "Housing Type"
  ) +
  theme_hec

ggsave(file.path(fig_dir, "01_kwh_distribution_by_flat_type.png"), p1, width = 8.5, height = 5, dpi = 300)

# 1C. User Check-in Completion & CO2 Savings Summary (Feature prep for Sprint 3 time series analysis)
user_adoption <- checkins %>%
  group_by(user_id) %>%
  summarise(
    total_checkins     = n(),
    completed_checkins = sum(completed, na.rm = TRUE),
    completion_rate    = round(mean(completed, na.rm = TRUE), 3),
    total_co2_saved_kg = round(sum(ifelse(completed, co2_saved_kg, 0), na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  right_join(users %>% select(user_id, flat_type, baseline_annual_kwh), by = "user_id") %>%
  replace_na(list(total_checkins = 0, completed_checkins = 0, completion_rate = 0, total_co2_saved_kg = 0))

write_csv(user_adoption, file.path(tab_dir, "02_user_baseline_adoption_metrics.csv"))

# ==============================================================================
# PART 2: German Grid CO2 Intensity Curve (Diurnal & Seasonal Shape - SMARD)
# ==============================================================================

smard_file <- resolve_data_path("sample_smard_actual.json")
smard_raw  <- fromJSON(smard_file)

# Parse SMARD series ([timestamp_ms, value_mwh] matrix inside $series)
if ("series" %in% names(smard_raw)) {
  smard_mat <- as.data.frame(smard_raw$series)
  colnames(smard_mat) <- c("timestamp_ms", "total_gen_mwh")
} else {
  stop("Unexpected SMARD JSON structure: missing 'series' array.")
}

smard_df <- smard_mat %>%
  filter(!is.na(total_gen_mwh)) %>%
  mutate(
    datetime   = as_datetime(timestamp_ms / 1000, tz = "Europe/Berlin"),
    hour       = hour(datetime),
    wday_label = wday(datetime, label = TRUE, week_start = 1),
    day_type   = if_else(wday(datetime, week_start = 1) >= 6, "Weekend", "Weekday"),
    month_num  = month(datetime),
    season     = case_when(
      month_num %in% c(12, 1, 2) ~ "Winter",
      month_num %in% c(3, 4, 5)  ~ "Spring",
      month_num %in% c(6, 7, 8)  ~ "Summer",
      TRUE                       ~ "Autumn"
    ),
    # Inverse-generation normalized proxy anchored to UBA 344 g CO2/kWh mean
    norm_factor       = mean(total_gen_mwh, na.rm = TRUE) / total_gen_mwh,
    est_co2_g_per_kwh = round(344 * pmin(pmax(norm_factor, 0.45), 1.65), 1)
  )

diurnal_co2 <- smard_df %>%
  group_by(day_type, hour) %>%
  summarise(
    n_obs        = n(),
    mean_gen_mwh = round(mean(total_gen_mwh, na.rm = TRUE), 1),
    mean_co2_g   = round(mean(est_co2_g_per_kwh, na.rm = TRUE), 1),
    sd_co2_g     = round(sd(est_co2_g_per_kwh, na.rm = TRUE), 1),
    .groups = "drop"
  )

write_csv(diurnal_co2, file.path(tab_dir, "03_smard_diurnal_co2_profile.csv"))

p2 <- ggplot(diurnal_co2, aes(x = hour, y = mean_co2_g, color = day_type)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  geom_hline(yintercept = 344, linetype = "dotted", color = "grey40") +
  annotate("rect", xmin = 11, xmax = 15, ymin = -Inf, ymax = Inf, alpha = 0.12, fill = "#31a354") +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  scale_color_manual(values = c("Weekday" = "#d95f02", "Weekend" = "#1b9e77")) +
  labs(
    title    = "Diurnal German Grid CO2 Intensity Curve (SMARD Filter 1223)",
    subtitle = "Shaded zone (11:00-15:00): optimal solar load-shifting window | Dotted: UBA 344 g/kWh baseline",
    x        = "Hour of Day (Europe/Berlin)",
    y        = "Estimated Grid Carbon Intensity (g CO2 / kWh)",
    color    = "Day Type"
  ) +
  theme_hec

ggsave(file.path(fig_dir, "02_diurnal_co2_intensity_curve.png"), p2, width = 8.5, height = 5, dpi = 300)

seasonal_co2 <- smard_df %>%
  group_by(season, hour) %>%
  summarise(mean_co2_g = round(mean(est_co2_g_per_kwh, na.rm = TRUE), 1), .groups = "drop")

write_csv(seasonal_co2, file.path(tab_dir, "04_smard_seasonal_co2_profile.csv"))

# ==============================================================================
# PART 3: 168-Bit Schedule Decoding & Appliance Run-Time Load-Shifting Overlap
# ==============================================================================

day_names <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

schedule_matrix <- users %>%
  select(user_id, flat_type, has_washing_machine, has_dishwasher, home_schedule) %>%
  mutate(bits = str_split(home_schedule, "")) %>%
  select(-home_schedule) %>%
  unnest(bits) %>%
  group_by(user_id) %>%
  mutate(
    slot_idx    = row_number() - 1, # 0 to 167
    day_idx     = (slot_idx %/% 24) + 1,
    day_of_week = factor(day_names[day_idx], levels = rev(day_names)),
    hour        = slot_idx %% 24,
    is_home     = as.integer(bits)
  ) %>%
  ungroup()

# 3A. Aggregate 7x24 Home Availability Heatmap
heatmap_df <- schedule_matrix %>%
  group_by(day_of_week, hour) %>%
  summarise(
    pct_students_home = round(mean(is_home) * 100, 1),
    .groups = "drop"
  )

write_csv(heatmap_df, file.path(tab_dir, "05_weekly_home_availability_heatmap.csv"))

p3 <- ggplot(heatmap_df, aes(x = hour, y = day_of_week, fill = pct_students_home)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "YlGnBu", direction = 1, name = "% Students Home") +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  labs(
    title    = "Student Weekly Home Availability Heatmap (Decoded 168-Bit Schedules)",
    subtitle = "Percentage of N = 300 student households available for manual/delayed appliance starts",
    x        = "Hour of Day",
    y        = "Day of Week"
  ) +
  theme_hec

ggsave(file.path(fig_dir, "03_student_home_availability_heatmap.png"), p3, width = 9, height = 4.8, dpi = 300)

# 3B. Appliance Run-Time & Clean-Window Overlap Analysis (REFIT Priors)
# Typical REFIT appliance cycle durations:
#   - Washing Machine: ~2.0 hours (2 consecutive home slots needed)
#   - Dishwasher:      ~2.5 hours (3 consecutive home slots needed)
# Target clean solar window: 11:00 - 15:00 (hours 11, 12, 13, 14)

clean_window_overlap <- schedule_matrix %>%
  filter(hour %in% 11:14) %>%
  group_by(user_id, flat_type, has_washing_machine, has_dishwasher, day_idx) %>%
  summarise(
    clean_home_hours = sum(is_home),
    can_run_washer   = has_washing_machine[1] & (sum(is_home) >= 2),
    can_run_dishw    = has_dishwasher[1] & (sum(is_home) >= 3),
    .groups = "drop"
  ) %>%
  group_by(flat_type) %>%
  summarise(
    avg_clean_home_hrs_per_day = round(mean(clean_home_hours), 2),
    washer_shiftable_days_wk   = round(mean(can_run_washer) * 7, 2),
    dishw_shiftable_days_wk    = round(mean(can_run_dishw) * 7, 2),
    .groups = "drop"
  )

write_csv(clean_window_overlap, file.path(tab_dir, "06_appliance_load_shifting_potential.csv"))

message("Sprint 2 EDA complete! Outputs saved to: ", file.path(repo_root, "eda", "outputs"))