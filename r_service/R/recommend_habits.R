# ==============================================================================
# Module: r_service/R/recommend_habits.R
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Engine)
# Description: Combines Collaborative Filtering (recommenderlab: UBCF/IBCF),
#              Association Rule Mining (arules: Apriori habit bundles),
#              appliance eligibility filtering, and 168-bit schedule matching
#              against forecasted Green Hours to output top-3 personalized
#              habit recommendations + best load-shifting windows per user.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
  library(readr)
  library(recommenderlab)
  library(arules)
  library(here)
})

# ------------------------------------------------------------------------------
# 1. Decode 168-Bit Schedule & Match Tomorrow's Forecasted Green Windows
# ------------------------------------------------------------------------------
compute_user_green_windows <- function(users_df, forecast_df) {
  day_names <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  
  # Identify forecasted green hours for the upcoming 24h horizon
  green_slots <- forecast_df %>%
    filter(is_green_window) %>%
    select(datetime, day_of_week, hour_of_day, forecast_co2_g, clean_rank)
  
  # Decode 168-bit strings into (user_id, day_of_week, hour_of_day, is_home)
  sched_long <- users_df %>%
    select(user_id, home_schedule) %>%
    mutate(bits = str_split(home_schedule, "")) %>%
    select(-home_schedule) %>%
    unnest(bits) %>%
    group_by(user_id) %>%
    mutate(
      slot_idx    = row_number() - 1L,
      day_of_week = day_names[(slot_idx %/% 24L) + 1L],
      hour_of_day = slot_idx %% 24L,
      is_home     = as.integer(bits)
    ) %>%
    ungroup()
  
  # Intersect user availability (is_home == 1) with forecasted green hours
  user_windows <- sched_long %>%
    inner_join(green_slots, by = c("day_of_week", "hour_of_day")) %>%
    filter(is_home == 1L) %>%
    group_by(user_id) %>%
    arrange(clean_rank, .by_group = TRUE) %>%
    summarise(
      available_green_hours = n(),
      best_green_hour       = first(hour_of_day),
      best_green_datetime   = first(datetime),
      best_green_co2_g      = first(forecast_co2_g),
      .groups               = "drop"
    )
  
  users_df %>%
    select(user_id) %>%
    left_join(user_windows, by = "user_id") %>%
    mutate(available_green_hours = replace_na(available_green_hours, 0L))
}

# ------------------------------------------------------------------------------
# 2. Train Collaborative Filtering (UBCF vs IBCF) & Association Rules (Apriori)
# ------------------------------------------------------------------------------
run_habit_recommender <- function(top_n = 3, save_outputs = TRUE) {
  data_dir <- here::here("r_service", "data")
  out_dir  <- here::here("r_service", "outputs")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  catalogue   <- read_csv(file.path(data_dir, "habit_catalogue_22.csv"), show_col_types = FALSE)
  users       <- read_csv(file.path(data_dir, "users_300.csv"),
                          col_types = cols(user_id = col_character(), home_schedule = col_character(), .default = col_guess()))
  commitments <- read_csv(file.path(data_dir, "commitments_22h.csv"), show_col_types = FALSE)
  checkins    <- read_csv(file.path(data_dir, "checkins_22h.csv"), show_col_types = FALSE)
  forecast_df <- read_csv(file.path(out_dir,  "co2_forecast_24h.csv"), show_col_types = FALSE) %>%
    mutate(datetime = with_tz(as_datetime(datetime), tzone = "Europe/Berlin"))
  
  # --- A. Build User x Habit Implicit Affinity Matrix (1 to 5 scale) ---
  # Score = 2.0 base commitment + up to 3.0 from actual check-in completion rate
  adherence_df <- checkins %>%
    group_by(user_id, habit_id) %>%
    summarise(completion_rate = mean(completed, na.rm = TRUE), .groups = "drop")
  
  ratings_long <- commitments %>%
    left_join(adherence_df, by = c("user_id", "habit_id")) %>%
    mutate(
      completion_rate = replace_na(completion_rate, 0.5),
      rating          = round(2.0 + 3.0 * completion_rate, 2)
    ) %>%
    select(user_id, habit_id, rating)
  
  # Pivot into complete 300 x 22 matrix
  rating_mat_df <- expand_grid(user_id = users$user_id, habit_id = catalogue$habit_id) %>%
    left_join(ratings_long, by = c("user_id", "habit_id")) %>%
    pivot_wider(names_from = habit_id, values_from = rating, names_prefix = "H_")
  
  mat <- as.matrix(rating_mat_df %>% select(-user_id))
  rownames(mat) <- rating_mat_df$user_id
  rrm <- as(mat, "realRatingMatrix")
  
  # --- B. Evaluate UBCF vs IBCF via 5-Fold Cross-Validation ---
  set.seed(42)
  eval_scheme <- evaluationScheme(rrm, method = "cross-validation", k = 5, given = 2, goodRating = 3.5)
  
  cf_models <- list(
    UBCF_cosine = list(name = "UBCF", param = list(method = "Cosine", nn = 25)),
    IBCF_cosine = list(name = "IBCF", param = list(method = "Cosine", k = 15))
  )
  
eval_res <- evaluate(eval_scheme, cf_models, type = "ratings")
  cf_metrics <- bind_rows(lapply(names(eval_res), function(mname) {
    avg_scores <- avg(eval_res[[mname]])
    tibble(
      model = mname,
      RMSE  = round(avg_scores[, "RMSE"], 3),
      MSE   = round(avg_scores[, "MSE"], 3),
      MAE   = round(avg_scores[, "MAE"], 3)
    )
  })) %>%
    arrange(RMSE)
  
  best_cf_name   <- cf_metrics$model[1]
  best_cf_method <- if_else(grepl("^UBCF", best_cf_name), "UBCF", "IBCF")
  message("Recommender CV complete. Best CF model: ", best_cf_name, " (RMSE = ", cf_metrics$RMSE[1], ")")
  
  # Train winning CF model on full 300 x 22 matrix & predict ratings for unrated items
  rec_fit  <- Recommender(rrm, method = best_cf_method, param = list(method = "Cosine"))
  pred_mat <- as(predict(rec_fit, rrm, type = "ratings"), "matrix")
  
  cf_preds_long <- as_tibble(pred_mat, rownames = "user_id") %>%
    pivot_longer(-user_id, names_to = "habit_col", values_to = "cf_score") %>%
    mutate(
      habit_id = as.integer(str_remove(habit_col, "^H_")),
      cf_score = replace_na(cf_score, 3.0)
    ) %>%
    select(user_id, habit_id, cf_score)
  
  # --- C. Mine Habit Co-Occurrence Rules via Apriori (arules) ---
  baskets <- split(paste0("H_", commitments$habit_id), commitments$user_id)
  trans   <- as(baskets, "transactions")
  
  rules <- apriori(
    trans,
    parameter = list(supp = 0.03, conf = 0.30, minlen = 2, maxlen = 2),
    control   = list(verbose = FALSE)
  )
  rules_filtered <- subset(rules, lift > 1.15)
  
  rules_df <- if (length(rules_filtered) > 0) {
    as(rules_filtered, "data.frame") %>%
      as_tibble() %>%
      separate(rules, into = c("lhs", "rhs"), sep = " => ") %>%
      mutate(
        lhs_habit_id = as.integer(str_remove_all(lhs, "[\\{\\}H_]")),
        rhs_habit_id = as.integer(str_remove_all(rhs, "[\\{\\}H_]"))
      ) %>%
      select(lhs_habit_id, rhs_habit_id, support, confidence, lift) %>%
      arrange(desc(lift))
  } else {
    tibble(lhs_habit_id = integer(), rhs_habit_id = integer(), support = numeric(), confidence = numeric(), lift = numeric())
  }
  
  # Calculate per-user Apriori companion boost for candidate habits
  apriori_boosts <- commitments %>%
    select(user_id, lhs_habit_id = habit_id) %>%
    inner_join(rules_df, by = "lhs_habit_id", relationship = "many-to-many") %>%
    group_by(user_id, habit_id = rhs_habit_id) %>%
    summarise(
      max_lift       = round(max(lift), 2),
      paired_with_id = first(lhs_habit_id),
      .groups        = "drop"
    )
  
  # --- D. Fuse CF + Apriori + Appliance Constraints + 168-Bit Green Windows ---
  user_green <- compute_user_green_windows(users, forecast_df)
  
  already_committed <- commitments %>%
    select(user_id, habit_id) %>%
    mutate(is_committed = TRUE)
  
  recommendations <- expand_grid(user_id = users$user_id, habit_id = catalogue$habit_id) %>%
    left_join(already_committed, by = c("user_id", "habit_id")) %>%
    filter(is.na(is_committed)) %>% # Only recommend new habits not yet active
    left_join(users %>% select(user_id, flat_type, has_washing_machine, has_dishwasher, has_dryer), by = "user_id") %>%
    left_join(catalogue, by = "habit_id") %>%
    # Enforce hard physical appliance prerequisites
    filter(
      (requires_appliance == "none") |
      (requires_appliance == "washing_machine" & has_washing_machine) |
      (requires_appliance == "dishwasher" & has_dishwasher) |
      (requires_appliance == "dryer" & has_dryer)
    ) %>%
    left_join(cf_preds_long,  by = c("user_id", "habit_id")) %>%
    left_join(apriori_boosts, by = c("user_id", "habit_id")) %>%
    left_join(user_green,     by = "user_id") %>%
    mutate(
      max_lift        = replace_na(max_lift, 1.0),
      apriori_bonus   = pmin(1.0, (max_lift - 1.0) * 0.5),
      # Boost load-shifting habits if user is actually home during tomorrow's green window
      schedule_bonus  = if_else(type == "timing" & available_green_hours >= 2, 0.45, 0.0),
      final_score     = round(cf_score + apriori_bonus + schedule_bonus, 3),
      reason_tag      = case_when(
        type == "timing" & available_green_hours >= 2 ~
          sprintf("Clean grid window at %02d:00 (%g gCO2/kWh) matches your home schedule", best_green_hour, best_green_co2_g),
        max_lift > 1.2 ~
          sprintf("Frequently paired with Habit #%d (Lift %.2fx)", paired_with_id, max_lift),
        TRUE ~
          sprintf("Popular among similar %s households (CF score %.2f)", flat_type, cf_score)
      )
    ) %>%
    group_by(user_id) %>%
    arrange(desc(final_score), desc(co2_saved_kg), .by_group = TRUE) %>%
    slice_head(n = top_n) %>%
    mutate(rank = row_number()) %>%
    ungroup() %>%
    select(
      user_id, rank, habit_id, habit_name = name, category, type,
      co2_saved_kg, cf_score, max_lift, available_green_hours,
      best_green_datetime, final_score, reason_tag
    )
  
  if (save_outputs) {
    write_csv(cf_metrics,      file.path(out_dir, "recommender_cv_metrics.csv"))
    write_csv(rules_df,        file.path(out_dir, "apriori_habit_rules.csv"))
    write_csv(recommendations, file.path(out_dir, "user_recommendations_top3.csv"))
    message("[SUCCESS] Generated ", nrow(recommendations), " personalized recommendations across ",
            n_distinct(recommendations$user_id), " users in: ", out_dir)
  }
  
  return(list(
    cv_metrics      = cf_metrics,
    rules           = rules_df,
    recommendations = recommendations
  ))
}

# Standalone CLI execution
if (sys.nframe() == 0) {
  rec_out <- run_habit_recommender(top_n = 3, save_outputs = TRUE)
  cat("\n--- Collaborative Filtering CV Metrics ---\n")
  print(rec_out$cv_metrics)
  cat("\n--- Top Association Rules (Apriori) ---\n")
  print(head(rec_out$rules, 10))
  cat("\n--- Sample Top-3 Recommendations (usr_0001 - usr_0003) ---\n")
  print(rec_out$recommendations %>% filter(user_id %in% c("usr_0001", "usr_0002", "usr_0003")) %>%
          select(user_id, rank, habit_name, final_score, reason_tag), n = 9)
}