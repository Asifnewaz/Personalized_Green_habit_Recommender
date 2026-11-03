# Synthetic Data Generation Plan (HEC-66)

## 1. Objective
Establish a realistic synthetic dataset to address the cold-start problem prior to collecting real user adoption data from the survey and pilot. This dataset will be used to build and validate the recommendation engine (collaborative filtering), persona clustering, and habit association mining in R.

---

## 2. Target Volume
* **Profiles (Users)**: 300 synthetic profiles
  * 70% WG residents (shared flats of 2 to 5 members)
  * 30% Single-person renter apartments
* **Time Horizon**: 4 simulated weeks (28 days)
* **Check-In History**: ~2,500 – 4,000 logged habit interactions across the user base, simulating varying adherence rates (50% to 90%).

---

## 3. Data Schema & Field Definitions

### A. Synthetic User Profiles (`synthetic_users.csv`)
* `user_id` (UUID): Unique pseudonymous identifier.
* `flat_type` (Enum): `WG` or `Single`.
* `flat_size_sqm` (Integer): Total floor area (e.g., 25–120 sqm).
* `num_flatmates` (Integer): Number of flatmates (1 for Single; 2 to 5 for WG).
* `heating_type` (Enum): `gas`, `district`, `electric`.
* `hot_water_type` (Enum): `central`, `electric_boiler`.
* `has_washing_machine` (Boolean): Access to an in-flat washing machine.
* `has_dishwasher` (Boolean): Access to a dishwasher.
* `home_schedule` (String / Bitstring): $24 \times 7$ binary representation of hours present at home (1 = home, 0 = away).
* `baseline_annual_kwh` (Float): Estimated annual consumption derived from flat size and occupants.

### B. Habit Commitments (`synthetic_commitments.csv`)
* `commitment_id` (UUID): Unique commitment record.
* `user_id` (UUID): Foreign key to user.
* `habit_id` (Integer): ID referencing the 22-habit catalogue.
* `start_date` (Date): When the commitment began.
* `target_frequency_per_week` (Integer): e.g., 2 times/week.
* `status` (Enum): `active`, `paused`, `completed`.

### C. Simulated Habit Check-Ins (`synthetic_checkins.csv`)
* `checkin_id` (UUID): Unique check-in identifier.
* `user_id` (UUID): Foreign key to user.
* `habit_id` (Integer): Referenced habit.
* `timestamp` (POSIXct): Execution timestamp (Europe/Berlin).
* `co2_saved_kg` (Float): Calculated saving per execution.
* `completed` (Boolean): Whether the user performed the habit.

---

## 4. Benchmark Data Sources & Distribution Rules

1. **Stromspiegel 2025 (co2online)**:
   * Provides electricity consumption baseline distributions across household sizes (Single: ~1,400 kWh/yr; 2-person: ~2,300 kWh/yr; 3-person: ~3,100 kWh/yr; 4+ person: ~3,800+ kWh/yr).
2. **Umweltbundesamt (UBA)**:
   * Proportions of household end use: space heating (>68%), hot water (~14%), appliances/cooking (~18%).
   * Default German electricity carbon intensity: 344 g CO2/kWh.
3. **REFIT Dataset**:
   * Hourly start-time distributions for washing machines and dishwashers to simulate realistic execution times (concentrated on weekends and weekday evenings).
4. **Prerequisite Filtering**:
   * Habits requiring specific appliances (e.g., laundry timing, dishwasher eco-mode) are assigned only to users whose profiles indicate appliance availability.

---

## 5. Implementation Strategy in R
* **Library Stack**: `dplyr`, `tidyr`, `purrr`, `lubridate`.
* **Output**: Generated CSV files placed in `data/synthetic/` for ingestion testing in PostgreSQL and R plumber endpoints.