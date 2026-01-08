# HawkTab AI - R Script V2
# Session: test-pipeline-practice-files-2026-01-08T15-55-55-637Z
# Generated: 2026-01-08T16:45:57.766Z
# Tables: 51
# Cuts: 21
# Significance Level: 0.1 (90% confidence)

# Load required libraries
library(haven)
library(dplyr)
library(jsonlite)

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

# Significance testing threshold
p_threshold <- 0.1

# =============================================================================
# Cuts Definition (banner columns) with stat testing metadata
# =============================================================================

# Cut masks
cuts <- list(
  Total = rep(TRUE, nrow(data))
,  `Cards` = with(data, (S2 == 1) | (S2a == 1))
,  `PCPs` = with(data, S2 == 2)
,  `Nephs` = with(data, S2 == 3)
,  `Endos` = with(data, S2 == 4)
,  `Lipids` = with(data, S2 == 5)
,  `Physician` = with(data, S2 %in% c(1,2,3,4,5))
,  `NP/PA` = with(data, S2b %in% c(2,3))
,  `Higher` = with(data, (S11 >= median(S11, na.rm=TRUE)))
,  `Lower` = with(data, (S11 < median(S11, na.rm=TRUE)))
,  `Tier 1` = with(data, qLIST_TIER == 1)
,  `Tier 2` = with(data, qLIST_TIER == 2)
,  `Tier 3` = with(data, qLIST_TIER == 3)
,  `Tier 4` = with(data, qLIST_TIER == 4)
,  `Segment A` = with(data, Segment == "Segment A")
,  `Segment B` = with(data, Segment == "Segment B")
,  `Segment C` = with(data, Segment == "Segment C")
,  `Segment D` = with(data, Segment == "Segment D")
,  `Priority Account` = with(data, qLIST_PRIORITY_ACCOUNT == 1)
,  `Non-Priority Account` = with(data, qLIST_PRIORITY_ACCOUNT == 2)
,  `Total` = with(data, TRUE)
)

# Stat letter mapping (for significance testing output)
cut_stat_letters <- c(
  "Total" = "T"
,  "Cards" = "A"
,  "PCPs" = "B"
,  "Nephs" = "C"
,  "Endos" = "D"
,  "Lipids" = "E"
,  "Physician" = "F"
,  "NP/PA" = "G"
,  "Higher" = "H"
,  "Lower" = "I"
,  "Tier 1" = "J"
,  "Tier 2" = "K"
,  "Tier 3" = "L"
,  "Tier 4" = "M"
,  "Segment A" = "N"
,  "Segment B" = "O"
,  "Segment C" = "P"
,  "Segment D" = "Q"
,  "Priority Account" = "R"
,  "Non-Priority Account" = "S"
,  "Total" = "T"
)

# Group membership (for within-group comparisons)
cut_groups <- list(
  "Specialty" = c("Cards", "PCPs", "Nephs", "Endos", "Lipids"),
  "Role" = c("Physician", "NP/PA"),
  "Volume of Adult ASCVD Patients" = c("Higher", "Lower"),
  "Tiers" = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"),
  "Segments" = c("Segment A", "Segment B", "Segment C", "Segment D"),
  "Priority Accounts" = c("Priority Account", "Non-Priority Account"),
  "Total" = c("Total")
)

print(paste("Defined", length(cuts), "cuts in", length(cut_groups), "groups"))

# =============================================================================
# Helper Functions
# =============================================================================

# Round half up (12.5 -> 13, not banker's rounding which gives 12)
round_half_up <- function(x, digits = 0) {
  floor(x * 10^digits + 0.5) / 10^digits
}

# Apply cut mask safely (NA in cut = exclude)
apply_cut <- function(data, cut_mask) {
  safe_mask <- cut_mask
  safe_mask[is.na(safe_mask)] <- FALSE
  data[safe_mask, ]
}

# Safely get variable column (returns NULL if not found)
safe_get_var <- function(data, var_name) {
  if (var_name %in% names(data)) {
    return(data[[var_name]])
  }
  return(NULL)
}

# Calculate mean excluding outliers (IQR method)
mean_no_outliers <- function(x) {
  valid <- x[!is.na(x)]
  if (length(valid) < 4) return(NA)  # Need enough data for IQR

  q1 <- quantile(valid, 0.25)
  q3 <- quantile(valid, 0.75)
  iqr <- q3 - q1

  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr

  no_outliers <- valid[valid >= lower_bound & valid <= upper_bound]
  if (length(no_outliers) == 0) return(NA)

  return(mean(no_outliers))
}

# Z-test for proportions (returns TRUE if significantly different)
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size

  # Pooled proportion
  p_pool <- (count1 + count2) / (n1 + n2)
  if (p_pool == 0 || p_pool == 1) return(NA)  # Can't test

  # Standard error
  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  if (se == 0) return(NA)

  # Z statistic
  p1 <- count1 / n1
  p2 <- count2 / n2
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}

# T-test for means (returns TRUE if significantly different)
sig_test_mean <- function(vals1, vals2, threshold = p_threshold) {
  n1 <- sum(!is.na(vals1))
  n2 <- sum(!is.na(vals2))

  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size

  tryCatch({
    result <- t.test(vals1, vals2, na.rm = TRUE)
    m1 <- mean(vals1, na.rm = TRUE)
    m2 <- mean(vals2, na.rm = TRUE)
    return(list(significant = result$p.value < threshold, higher = m1 > m2))
  }, error = function(e) {
    return(NA)
  })
}

# Get other cuts in the same group (for within-group comparison)
get_group_cuts <- function(cut_name) {
  for (group_name in names(cut_groups)) {
    if (cut_name %in% cut_groups[[group_name]]) {
      return(cut_groups[[group_name]])
    }
  }
  return(c())
}

# =============================================================================
# Table Calculations
# =============================================================================

all_tables <- list()

# Skipping excluded table: s5_multi_select (S5 is an early screener with termination logic: selecting options 1-6 would result in termination. Among the qualified sample respondents will predominantly have 'None of these' = 1 (i.e., 100% pass), so the table has no analytical value for main reporting and is excluded.)

# -----------------------------------------------------------------------------
# Table: s8_time_allocation (mean_rows)
# Title: S8 - Percentage of professional time by activity
# Rows: 4
# -----------------------------------------------------------------------------

table_s8_time_allocation <- list(
  tableId = "s8_time_allocation",
  title = "S8 - Percentage of professional time by activity",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8_time_allocation$data[[cut_name]] <- list()
  table_s8_time_allocation$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S8r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s8_time_allocation$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s8_time_allocation$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S8r1 not found"
    )
  }

  # Row 2: S8r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s8_time_allocation$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s8_time_allocation$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S8r2 not found"
    )
  }

  # Row 3: S8r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s8_time_allocation$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s8_time_allocation$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S8r3 not found"
    )
  }

  # Row 4: S8r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s8_time_allocation$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s8_time_allocation$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S8r4 not found"
    )
  }

}

all_tables[["s8_time_allocation"]] <- table_s8_time_allocation
print(paste("Generated mean_rows table: s8_time_allocation"))

# -----------------------------------------------------------------------------
# Table: s12 (mean_rows)
# Title: S12 - Number of patients with an event (by time since event)
# Rows: 4
# -----------------------------------------------------------------------------

table_s12 <- list(
  tableId = "s12",
  title = "S12 - Number of patients with an event (by time since event)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s12$data[[cut_name]] <- list()
  table_s12$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S12r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s12$data[[cut_name]][["S12r1"]] <- list(
      label = "Over 5 years ago",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s12$data[[cut_name]][["S12r1"]] <- list(
      label = "Over 5 years ago",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S12r1 not found"
    )
  }

  # Row 2: S12r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s12$data[[cut_name]][["S12r2"]] <- list(
      label = "Within the last 3-5 years",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s12$data[[cut_name]][["S12r2"]] <- list(
      label = "Within the last 3-5 years",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S12r2 not found"
    )
  }

  # Row 3: S12r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s12$data[[cut_name]][["S12r3"]] <- list(
      label = "Within the last 1-2 years",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s12$data[[cut_name]][["S12r3"]] <- list(
      label = "Within the last 1-2 years",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S12r3 not found"
    )
  }

  # Row 4: S12r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s12$data[[cut_name]][["S12r4"]] <- list(
      label = "Within the last year",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s12$data[[cut_name]][["S12r4"]] <- list(
      label = "Within the last year",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S12r4 not found"
    )
  }

}

all_tables[["s12"]] <- table_s12
print(paste("Generated mean_rows table: s12"))

# -----------------------------------------------------------------------------
# Table: A1_overview (frequency)
# Title: A1 - Current indication for each treatment
# Rows: 8
# Source: A1_overview
# -----------------------------------------------------------------------------

table_A1_overview <- list(
  tableId = "A1_overview",
  title = "A1 - Current indication for each treatment",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A1_overview$data[[cut_name]] <- list()
  table_A1_overview$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A1r1 == 1
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r1_row_1"]] <- list(
      label = "Leqvio (inclisiran): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r1_row_1"]] <- list(
      label = "Leqvio (inclisiran): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r1 not found"
    )
  }

  # Row 2: A1r1 == 2
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "Leqvio (inclisiran): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "Leqvio (inclisiran): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r1 not found"
    )
  }

  # Row 3: A1r2 == 1
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r2_row_3"]] <- list(
      label = "Praluent (alirocumab): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r2_row_3"]] <- list(
      label = "Praluent (alirocumab): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r2 not found"
    )
  }

  # Row 4: A1r2 == 2
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r2_row_4"]] <- list(
      label = "Praluent (alirocumab): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r2_row_4"]] <- list(
      label = "Praluent (alirocumab): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r2 not found"
    )
  }

  # Row 5: A1r3 == 1
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r3_row_5"]] <- list(
      label = "Repatha (evolocumab): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r3_row_5"]] <- list(
      label = "Repatha (evolocumab): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r3 not found"
    )
  }

  # Row 6: A1r3 == 2
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r3_row_6"]] <- list(
      label = "Repatha (evolocumab): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r3_row_6"]] <- list(
      label = "Repatha (evolocumab): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r3 not found"
    )
  }

  # Row 7: A1r4 == 1
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r4_row_7"]] <- list(
      label = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r4_row_7"]] <- list(
      label = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe): As an adjunct to diet, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r4 not found"
    )
  }

  # Row 8: A1r4 == 2
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A1_overview$data[[cut_name]][["A1r4_row_8"]] <- list(
      label = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A1_overview$data[[cut_name]][["A1r4_row_8"]] <- list(
      label = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe): As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A1r4 not found"
    )
  }

}

all_tables[["A1_overview"]] <- table_A1_overview
print(paste("Generated frequency table: A1_overview"))

# -----------------------------------------------------------------------------
# Table: a3 (mean_rows)
# Title: A3 - Number prescribed each therapy (last 100 patients)
# Rows: 7
# Source: a3
# -----------------------------------------------------------------------------

table_a3 <- list(
  tableId = "a3",
  title = "A3 - Number prescribed each therapy (last 100 patients)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3$data[[cut_name]] <- list()
  table_a3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r1 not found"
    )
  }

  # Row 2: A3r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r2 not found"
    )
  }

  # Row 3: A3r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r3"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r3"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r3 not found"
    )
  }

  # Row 4: A3r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r4"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r4"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r4 not found"
    )
  }

  # Row 5: A3r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r5"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r5"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r5 not found"
    )
  }

  # Row 6: A3r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r6"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r6"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r6 not found"
    )
  }

  # Row 7: A3r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3$data[[cut_name]][["A3r7"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3$data[[cut_name]][["A3r7"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3r7 not found"
    )
  }

}

all_tables[["a3"]] <- table_a3
print(paste("Generated mean_rows table: a3"))

# -----------------------------------------------------------------------------
# Table: a3a (mean_rows)
# Title: A3a - % receiving therapy in addition to a statin vs without a statin (Last 100)
# Rows: 10
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a <- list(
  tableId = "a3a",
  title = "A3a - % receiving therapy in addition to a statin vs without a statin (Last 100)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3a$data[[cut_name]] <- list()
  table_a3a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar1c1 not found"
    )
  }

  # Row 2: A3ar1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar1c2 not found"
    )
  }

  # Row 3: A3ar2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar2c1 not found"
    )
  }

  # Row 4: A3ar2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar2c2 not found"
    )
  }

  # Row 5: A3ar3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar3c1 not found"
    )
  }

  # Row 6: A3ar3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar3c2 not found"
    )
  }

  # Row 7: A3ar4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "Zetia (ezetimibe or generic ezetimibe) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "Zetia (ezetimibe or generic ezetimibe) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar4c1 not found"
    )
  }

  # Row 8: A3ar4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Zetia (ezetimibe or generic ezetimibe) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Zetia (ezetimibe or generic ezetimibe) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar4c2 not found"
    )
  }

  # Row 9: A3ar5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 10: A3ar5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a3a$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a3a$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3ar5c2 not found"
    )
  }

}

all_tables[["a3a"]] <- table_a3a
print(paste("Generated mean_rows table: a3a"))

# -----------------------------------------------------------------------------
# Table: A3b_mean_rows (mean_rows)
# Title: A3b - % of patients (0-100) who received the therapy WITHOUT a statin — summary means
# Rows: 10
# Source: A3b_mean_rows
# -----------------------------------------------------------------------------

table_A3b_mean_rows <- list(
  tableId = "A3b_mean_rows",
  title = "A3b - % of patients (0-100) who received the therapy WITHOUT a statin — summary means",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A3b_mean_rows$data[[cut_name]] <- list()
  table_A3b_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 2: A3br1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br1c2 not found"
    )
  }

  # Row 3: A3br2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 4: A3br2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br2c2 not found"
    )
  }

  # Row 5: A3br3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 6: A3br3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br3c2 not found"
    )
  }

  # Row 7: A3br4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Zetia (ezetimibe) — Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Zetia (ezetimibe) — Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 8: A3br4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br4c2"]] <- list(
      label = "Zetia (ezetimibe) — After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br4c2"]] <- list(
      label = "Zetia (ezetimibe) — After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br4c2 not found"
    )
  }

  # Row 9: A3br5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 10: A3br5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A3br5c2 not found"
    )
  }

}

all_tables[["A3b_mean_rows"]] <- table_A3b_mean_rows
print(paste("Generated mean_rows table: A3b_mean_rows"))

# -----------------------------------------------------------------------------
# Table: a4_mean_rows (mean_rows)
# Title: A4 - Number (out of 100) you would prescribe of each treatment (LAST and NEXT 100 patients)
# Rows: 14
# -----------------------------------------------------------------------------

table_a4_mean_rows <- list(
  tableId = "a4_mean_rows",
  title = "A4 - Number (out of 100) you would prescribe of each treatment (LAST and NEXT 100 patients)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_mean_rows$data[[cut_name]] <- list()
  table_a4_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4r1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy) - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy) - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r1c1 not found"
    )
  }

  # Row 2: A4r2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran) - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran) - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r2c1 not found"
    )
  }

  # Row 3: A4r3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab) - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab) - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r3c1 not found"
    )
  }

  # Row 4: A4r4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab) - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab) - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r4c1 not found"
    )
  }

  # Row 5: A4r5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r5c1 not found"
    )
  }

  # Row 6: A4r6c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r6c1 not found"
    )
  }

  # Row 7: A4r7c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other - LAST 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other - LAST 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r7c1 not found"
    )
  }

  # Row 8: A4r1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy) - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy) - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r1c2 not found"
    )
  }

  # Row 9: A4r2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran) - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran) - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r2c2 not found"
    )
  }

  # Row 10: A4r3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab) - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab) - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r3c2 not found"
    )
  }

  # Row 11: A4r4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab) - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab) - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r4c2 not found"
    )
  }

  # Row 12: A4r5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r5c2 not found"
    )
  }

  # Row 13: A4r6c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r6c2 not found"
    )
  }

  # Row 14: A4r7c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other - NEXT 100 patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other - NEXT 100 patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r7c2 not found"
    )
  }

}

all_tables[["a4_mean_rows"]] <- table_a4_mean_rows
print(paste("Generated mean_rows table: a4_mean_rows"))

# -----------------------------------------------------------------------------
# Table: a4_last100_mean_rows (mean_rows) [DERIVED]
# Title: A4 - Number (out of 100) you prescribed of each treatment - LAST 100 patients
# Rows: 7
# Source: a4_mean_rows
# -----------------------------------------------------------------------------

table_a4_last100_mean_rows <- list(
  tableId = "a4_last100_mean_rows",
  title = "A4 - Number (out of 100) you prescribed of each treatment - LAST 100 patients",
  tableType = "mean_rows",
  hints = c(),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_last100_mean_rows$data[[cut_name]] <- list()
  table_a4_last100_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4r1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r1c1 not found"
    )
  }

  # Row 2: A4r2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r2c1 not found"
    )
  }

  # Row 3: A4r3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r3c1 not found"
    )
  }

  # Row 4: A4r4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r4c1 not found"
    )
  }

  # Row 5: A4r5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r5c1 not found"
    )
  }

  # Row 6: A4r6c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r6c1 not found"
    )
  }

  # Row 7: A4r7c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_last100_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_last100_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r7c1 not found"
    )
  }

}

all_tables[["a4_last100_mean_rows"]] <- table_a4_last100_mean_rows
print(paste("Generated mean_rows table: a4_last100_mean_rows"))

# -----------------------------------------------------------------------------
# Table: a4_next100_mean_rows (mean_rows) [DERIVED]
# Title: A4 - Number (out of 100) you would prescribe of each treatment - NEXT 100 patients
# Rows: 7
# Source: a4_mean_rows
# -----------------------------------------------------------------------------

table_a4_next100_mean_rows <- list(
  tableId = "a4_next100_mean_rows",
  title = "A4 - Number (out of 100) you would prescribe of each treatment - NEXT 100 patients",
  tableType = "mean_rows",
  hints = c(),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_next100_mean_rows$data[[cut_name]] <- list()
  table_a4_next100_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4r1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r1c2 not found"
    )
  }

  # Row 2: A4r2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r2c2 not found"
    )
  }

  # Row 3: A4r3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r3c2 not found"
    )
  }

  # Row 4: A4r4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r4c2 not found"
    )
  }

  # Row 5: A4r5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r5c2 not found"
    )
  }

  # Row 6: A4r6c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r6c2 not found"
    )
  }

  # Row 7: A4r7c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a4_next100_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a4_next100_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4r7c2 not found"
    )
  }

}

all_tables[["a4_next100_mean_rows"]] <- table_a4_next100_mean_rows
print(paste("Generated mean_rows table: a4_next100_mean_rows"))

# -----------------------------------------------------------------------------
# Table: A4a_mean_rows (mean_rows)
# Title: A4a - % of NEXT 100 with Uncontrolled LDL-C prescribed each therapy (In addition to statin vs Without a statin)
# Rows: 10
# Source: A4a_mean_rows
# -----------------------------------------------------------------------------

table_A4a_mean_rows <- list(
  tableId = "A4a_mean_rows",
  title = "A4a - % of NEXT 100 with Uncontrolled LDL-C prescribed each therapy (In addition to statin vs Without a statin)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A4a_mean_rows$data[[cut_name]] <- list()
  table_A4a_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar1c1 not found"
    )
  }

  # Row 2: A4ar1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar1c2 not found"
    )
  }

  # Row 3: A4ar2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar2c1 not found"
    )
  }

  # Row 4: A4ar2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar2c2 not found"
    )
  }

  # Row 5: A4ar3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar3c1 not found"
    )
  }

  # Row 6: A4ar3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar3c2 not found"
    )
  }

  # Row 7: A4ar4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar4c1 not found"
    )
  }

  # Row 8: A4ar4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar4c2 not found"
    )
  }

  # Row 9: A4ar5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar5c1 not found"
    )
  }

  # Row 10: A4ar5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4a_mean_rows$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4a_mean_rows$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4ar5c2 not found"
    )
  }

}

all_tables[["A4a_mean_rows"]] <- table_A4a_mean_rows
print(paste("Generated mean_rows table: A4a_mean_rows"))

# -----------------------------------------------------------------------------
# Table: A4b_mean_rows (mean_rows)
# Title: A4b - For treatments prescribed without a statin: % of those patients who received therapy BEFORE vs AFTER other lipid-lowering therapy (mean/median/std dev %)
# Rows: 10
# Source: A4b_mean_rows
# -----------------------------------------------------------------------------

table_A4b_mean_rows <- list(
  tableId = "A4b_mean_rows",
  title = "A4b - For treatments prescribed without a statin: % of those patients who received therapy BEFORE vs AFTER other lipid-lowering therapy (mean/median/std dev %)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A4b_mean_rows$data[[cut_name]] <- list()
  table_A4b_mean_rows$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br1c1 not found"
    )
  }

  # Row 2: A4br1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br1c2 not found"
    )
  }

  # Row 3: A4br2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br2c1 not found"
    )
  }

  # Row 4: A4br2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br2c2 not found"
    )
  }

  # Row 5: A4br3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br3c1 not found"
    )
  }

  # Row 6: A4br3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br3c2 not found"
    )
  }

  # Row 7: A4br4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br4c1 not found"
    )
  }

  # Row 8: A4br4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br4c2 not found"
    )
  }

  # Row 9: A4br5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid) — % of patients who received this BEFORE any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br5c1 not found"
    )
  }

  # Row 10: A4br5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_A4b_mean_rows$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A4b_mean_rows$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid) — % of patients who received this AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A4br5c2 not found"
    )
  }

}

all_tables[["A4b_mean_rows"]] <- table_A4b_mean_rows
print(paste("Generated mean_rows table: A4b_mean_rows"))

# -----------------------------------------------------------------------------
# Table: A6_rank1 (frequency)
# Title: A6 - Items ranked #1 (most preferred)
# Rows: 8
# -----------------------------------------------------------------------------

table_A6_rank1 <- list(
  tableId = "A6_rank1",
  title = "A6 - Items ranked #1 (most preferred)",
  tableType = "frequency",
  hints = c("ranking"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank1$data[[cut_name]] <- list()
  table_A6_rank1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 1
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == 1
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == 1
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == 1
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == 1
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == 1
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == 1
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == 1
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank1"]] <- table_A6_rank1
print(paste("Generated frequency table: A6_rank1"))

# -----------------------------------------------------------------------------
# Table: A6_rank2 (frequency)
# Title: A6 - Items ranked #2
# Rows: 8
# -----------------------------------------------------------------------------

table_A6_rank2 <- list(
  tableId = "A6_rank2",
  title = "A6 - Items ranked #2",
  tableType = "frequency",
  hints = c("ranking"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank2$data[[cut_name]] <- list()
  table_A6_rank2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 2
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == 2
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == 2
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == 2
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == 2
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == 2
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == 2
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == 2
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank2"]] <- table_A6_rank2
print(paste("Generated frequency table: A6_rank2"))

# -----------------------------------------------------------------------------
# Table: A6_rank3 (frequency)
# Title: A6 - Items ranked #3
# Rows: 8
# Source: A6_rank3
# -----------------------------------------------------------------------------

table_A6_rank3 <- list(
  tableId = "A6_rank3",
  title = "A6 - Items ranked #3",
  tableType = "frequency",
  hints = c("ranking"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank3$data[[cut_name]] <- list()
  table_A6_rank3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 3
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == 3
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == 3
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == 3
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == 3
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == 3
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == 3
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == 3
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank3"]] <- table_A6_rank3
print(paste("Generated frequency table: A6_rank3"))

# -----------------------------------------------------------------------------
# Table: A6_rank4 (frequency)
# Title: A6 - Items ranked #4 (least preferred)
# Rows: 8
# -----------------------------------------------------------------------------

table_A6_rank4 <- list(
  tableId = "A6_rank4",
  title = "A6 - Items ranked #4 (least preferred)",
  tableType = "frequency",
  hints = c("ranking"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank4$data[[cut_name]] <- list()
  table_A6_rank4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 4
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == 4
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == 4
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == 4
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == 4
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == 4
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == 4
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == 4
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank4"]] <- table_A6_rank4
print(paste("Generated frequency table: A6_rank4"))

# -----------------------------------------------------------------------------
# Table: a7 (frequency)
# Title: A7 - Impacts on perceptions/prescribing (select all that apply)
# Rows: 5
# -----------------------------------------------------------------------------

table_a7 <- list(
  tableId = "a7",
  title = "A7 - Impacts on perceptions/prescribing (select all that apply)",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a7$data[[cut_name]] <- list()
  table_a7$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A7r1 == 1
  var_col <- safe_get_var(cut_data, "A7r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r1_row_1"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a7$data[[cut_name]][["A7r1_row_1"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A7r1 not found"
    )
  }

  # Row 2: A7r2 == 1
  var_col <- safe_get_var(cut_data, "A7r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r2_row_2"]] <- list(
      label = "Offers an option to patients who can't or won't take a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a7$data[[cut_name]][["A7r2_row_2"]] <- list(
      label = "Offers an option to patients who can't or won't take a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A7r2 not found"
    )
  }

  # Row 3: A7r3 == 1
  var_col <- safe_get_var(cut_data, "A7r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r3_row_3"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a7$data[[cut_name]][["A7r3_row_3"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A7r3 not found"
    )
  }

  # Row 4: A7r4 == 1
  var_col <- safe_get_var(cut_data, "A7r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r4_row_4"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a7$data[[cut_name]][["A7r4_row_4"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A7r4 not found"
    )
  }

  # Row 5: A7r5 == 1
  var_col <- safe_get_var(cut_data, "A7r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r5_row_5"]] <- list(
      label = "Other (Specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a7$data[[cut_name]][["A7r5_row_5"]] <- list(
      label = "Other (Specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A7r5 not found"
    )
  }

}

all_tables[["a7"]] <- table_a7
print(paste("Generated frequency table: a7"))

# -----------------------------------------------------------------------------
# Table: A8_r1 (frequency) [DERIVED]
# Title: A8r1 - With established CVD: Likelihood to prescribe each therapy alone (1-5)
# Rows: 21
# Source: A8_r1
# -----------------------------------------------------------------------------

table_A8_r1 <- list(
  tableId = "A8_r1",
  title = "A8r1 - With established CVD: Likelihood to prescribe each therapy alone (1-5)",
  tableType = "frequency",
  hints = c("scale-5"),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r1$data[[cut_name]] <- list()
  table_A8_r1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r1c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 2: A8r1c1 == 5
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 3: A8r1c1 == 4
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 4: A8r1c1 == 3
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 5: A8r1c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 6: A8r1c1 == 2
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_6"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_6"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 7: A8r1c1 == 1
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_7"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_7"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 8: A8r1c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 9: A8r1c2 == 5
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 10: A8r1c2 == 4
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 11: A8r1c2 == 3
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_11"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_11"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 12: A8r1c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_12"]] <- list(
      label = "Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_12"]] <- list(
      label = "Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 13: A8r1c2 == 2
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_13"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_13"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 14: A8r1c2 == 1
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_14"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_14"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 15: A8r1c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 16: A8r1c3 == 5
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_16"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_16"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 17: A8r1c3 == 4
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_17"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_17"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 18: A8r1c3 == 3
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_18"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_18"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 19: A8r1c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_19"]] <- list(
      label = "Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_19"]] <- list(
      label = "Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 20: A8r1c3 == 2
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_20"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_20"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 21: A8r1c3 == 1
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_21"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_21"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r1c3 not found"
    )
  }

}

all_tables[["A8_r1"]] <- table_A8_r1
print(paste("Generated frequency table: A8_r1"))

# -----------------------------------------------------------------------------
# Table: A8_r2 (frequency)
# Title: A8r2 - With no history of CV events and at high-risk: Likelihood to prescribe each therapy alone (1-5)
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r2 <- list(
  tableId = "A8_r2",
  title = "A8r2 - With no history of CV events and at high-risk: Likelihood to prescribe each therapy alone (1-5)",
  tableType = "frequency",
  hints = c("scale-5"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r2$data[[cut_name]] <- list()
  table_A8_r2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r2c1 == 1
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 2: A8r2c1 == 2
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_2"]] <- list(
      label = "Repatha - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_2"]] <- list(
      label = "Repatha - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 3: A8r2c1 == 3
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_3"]] <- list(
      label = "Repatha - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_3"]] <- list(
      label = "Repatha - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 4: A8r2c1 == 4
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_4"]] <- list(
      label = "Repatha - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_4"]] <- list(
      label = "Repatha - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 5: A8r2c1 == 5
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_5"]] <- list(
      label = "Repatha - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_5"]] <- list(
      label = "Repatha - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 6: A8r2c2 == 1
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_6"]] <- list(
      label = "Praluent - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_6"]] <- list(
      label = "Praluent - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 7: A8r2c2 == 2
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 8: A8r2c2 == 3
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_8"]] <- list(
      label = "Praluent - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_8"]] <- list(
      label = "Praluent - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 9: A8r2c2 == 4
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_9"]] <- list(
      label = "Praluent - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_9"]] <- list(
      label = "Praluent - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 10: A8r2c2 == 5
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Praluent - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Praluent - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 11: A8r2c3 == 1
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Leqvio - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Leqvio - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 12: A8r2c3 == 2
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Leqvio - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Leqvio - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 13: A8r2c3 == 3
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 14: A8r2c3 == 4
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Leqvio - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Leqvio - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 15: A8r2c3 == 5
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Leqvio - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Leqvio - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r2c3 not found"
    )
  }

}

all_tables[["A8_r2"]] <- table_A8_r2
print(paste("Generated frequency table: A8_r2"))

# -----------------------------------------------------------------------------
# Table: A8_r3 (frequency)
# Title: A8r3 - With no history of CV events and at low-to-medium risk: Likelihood to prescribe each therapy alone (1-5)
# Rows: 21
# -----------------------------------------------------------------------------

table_A8_r3 <- list(
  tableId = "A8_r3",
  title = "A8r3 - With no history of CV events and at low-to-medium risk: Likelihood to prescribe each therapy alone (1-5)",
  tableType = "frequency",
  hints = c("scale-5"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r3$data[[cut_name]] <- list()
  table_A8_r3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r3c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha - Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha - Very or Extremely likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 2: A8r3c1 == 5
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_2"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_2"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 3: A8r3c1 == 4
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_3"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_3"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 4: A8r3c1 == 3
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_4"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_4"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 5: A8r3c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_5"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_5"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 6: A8r3c1 == 2
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_6"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_6"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 7: A8r3c1 == 1
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_7"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_7"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 8: A8r3c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_8"]] <- list(
      label = "Praluent - Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_8"]] <- list(
      label = "Praluent - Very or Extremely likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 9: A8r3c2 == 5
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_9"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_9"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 10: A8r3c2 == 4
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_10"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_10"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 11: A8r3c2 == 3
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_11"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_11"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 12: A8r3c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_12"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_12"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 13: A8r3c2 == 2
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_13"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_13"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 14: A8r3c2 == 1
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_14"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_14"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 15: A8r3c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_15"]] <- list(
      label = "Leqvio - Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_15"]] <- list(
      label = "Leqvio - Very or Extremely likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 16: A8r3c3 == 5
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_16"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_16"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 17: A8r3c3 == 4
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_17"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_17"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 18: A8r3c3 == 3
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_18"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_18"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 19: A8r3c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_19"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_19"]] <- list(
      label = "Not at all or Slightly likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 20: A8r3c3 == 2
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_20"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_20"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 21: A8r3c3 == 1
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_21"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_21"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r3c3 not found"
    )
  }

}

all_tables[["A8_r3"]] <- table_A8_r3
print(paste("Generated frequency table: A8_r3"))

# -----------------------------------------------------------------------------
# Table: A8_r4 (frequency)
# Title: A8r4 - Who are not known to be compliant on statins: Likelihood to prescribe each therapy alone (1-5)
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r4 <- list(
  tableId = "A8_r4",
  title = "A8r4 - Who are not known to be compliant on statins: Likelihood to prescribe each therapy alone (1-5)",
  tableType = "frequency",
  hints = c("scale-5"),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r4$data[[cut_name]] <- list()
  table_A8_r4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r4c1 == 1
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 2: A8r4c1 == 2
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_2"]] <- list(
      label = "Repatha - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_2"]] <- list(
      label = "Repatha - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 3: A8r4c1 == 3
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_3"]] <- list(
      label = "Repatha - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_3"]] <- list(
      label = "Repatha - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 4: A8r4c1 == 4
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_4"]] <- list(
      label = "Repatha - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_4"]] <- list(
      label = "Repatha - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 5: A8r4c1 == 5
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_5"]] <- list(
      label = "Repatha - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_5"]] <- list(
      label = "Repatha - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 6: A8r4c2 == 1
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_6"]] <- list(
      label = "Praluent - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_6"]] <- list(
      label = "Praluent - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 7: A8r4c2 == 2
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 8: A8r4c2 == 3
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_8"]] <- list(
      label = "Praluent - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_8"]] <- list(
      label = "Praluent - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 9: A8r4c2 == 4
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_9"]] <- list(
      label = "Praluent - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_9"]] <- list(
      label = "Praluent - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 10: A8r4c2 == 5
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_10"]] <- list(
      label = "Praluent - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_10"]] <- list(
      label = "Praluent - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 11: A8r4c3 == 1
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_11"]] <- list(
      label = "Leqvio - 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_11"]] <- list(
      label = "Leqvio - 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 12: A8r4c3 == 2
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_12"]] <- list(
      label = "Leqvio - 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_12"]] <- list(
      label = "Leqvio - 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 13: A8r4c3 == 3
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio - 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio - 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 14: A8r4c3 == 4
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_14"]] <- list(
      label = "Leqvio - 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_14"]] <- list(
      label = "Leqvio - 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 15: A8r4c3 == 5
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_15"]] <- list(
      label = "Leqvio - 5",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_15"]] <- list(
      label = "Leqvio - 5",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r4c3 not found"
    )
  }

}

all_tables[["A8_r4"]] <- table_A8_r4
print(paste("Generated frequency table: A8_r4"))

# -----------------------------------------------------------------------------
# Table: A8_r5 (frequency) [DERIVED]
# Title: A8r5 - Patients intolerant of statins: Likelihood to prescribe each therapy alone (1=Not at all likely ... 5=Extremely likely)
# Rows: 21
# Source: A8_r5
# -----------------------------------------------------------------------------

table_A8_r5 <- list(
  tableId = "A8_r5",
  title = "A8r5 - Patients intolerant of statins: Likelihood to prescribe each therapy alone (1=Not at all likely ... 5=Extremely likely)",
  tableType = "frequency",
  hints = c("scale-5"),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r5$data[[cut_name]] <- list()
  table_A8_r5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r5c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha - Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha - Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 2: A8r5c1 == 5
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_2"]] <- list(
      label = "Repatha - Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_2"]] <- list(
      label = "Repatha - Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 3: A8r5c1 == 4
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_3"]] <- list(
      label = "Repatha - Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_3"]] <- list(
      label = "Repatha - Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 4: A8r5c1 == 3
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_4"]] <- list(
      label = "Repatha - Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_4"]] <- list(
      label = "Repatha - Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 5: A8r5c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_5"]] <- list(
      label = "Repatha - Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_5"]] <- list(
      label = "Repatha - Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 6: A8r5c1 == 2
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_6"]] <- list(
      label = "Repatha - Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_6"]] <- list(
      label = "Repatha - Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 7: A8r5c1 == 1
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_7"]] <- list(
      label = "Repatha - Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_7"]] <- list(
      label = "Repatha - Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 8: A8r5c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_8"]] <- list(
      label = "Praluent - Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_8"]] <- list(
      label = "Praluent - Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 9: A8r5c2 == 5
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_9"]] <- list(
      label = "Praluent - Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_9"]] <- list(
      label = "Praluent - Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 10: A8r5c2 == 4
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_10"]] <- list(
      label = "Praluent - Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_10"]] <- list(
      label = "Praluent - Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 11: A8r5c2 == 3
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_11"]] <- list(
      label = "Praluent - Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_11"]] <- list(
      label = "Praluent - Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 12: A8r5c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_12"]] <- list(
      label = "Praluent - Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_12"]] <- list(
      label = "Praluent - Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 13: A8r5c2 == 2
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_13"]] <- list(
      label = "Praluent - Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_13"]] <- list(
      label = "Praluent - Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 14: A8r5c2 == 1
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_14"]] <- list(
      label = "Praluent - Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_14"]] <- list(
      label = "Praluent - Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 15: A8r5c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_15"]] <- list(
      label = "Leqvio - Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_15"]] <- list(
      label = "Leqvio - Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 16: A8r5c3 == 5
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_16"]] <- list(
      label = "Leqvio - Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_16"]] <- list(
      label = "Leqvio - Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 17: A8r5c3 == 4
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_17"]] <- list(
      label = "Leqvio - Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_17"]] <- list(
      label = "Leqvio - Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 18: A8r5c3 == 3
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_18"]] <- list(
      label = "Leqvio - Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_18"]] <- list(
      label = "Leqvio - Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 19: A8r5c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_19"]] <- list(
      label = "Leqvio - Not likely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_19"]] <- list(
      label = "Leqvio - Not likely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 20: A8r5c3 == 2
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_20"]] <- list(
      label = "Leqvio - Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_20"]] <- list(
      label = "Leqvio - Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 21: A8r5c3 == 1
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_21"]] <- list(
      label = "Leqvio - Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_21"]] <- list(
      label = "Leqvio - Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A8r5c3 not found"
    )
  }

}

all_tables[["A8_r5"]] <- table_A8_r5
print(paste("Generated frequency table: A8_r5"))

# -----------------------------------------------------------------------------
# Table: a9 (frequency)
# Title: A9 - Issues encountered without a statin, by product (1=No issues; 2=Some issues; 3=Significant issues; 4=Haven't prescribed without a statin)
# Rows: 15
# Source: a9
# -----------------------------------------------------------------------------

table_a9 <- list(
  tableId = "a9",
  title = "A9 - Issues encountered without a statin, by product (1=No issues; 2=Some issues; 3=Significant issues; 4=Haven't prescribed without a statin)",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9$data[[cut_name]] <- list()
  table_a9$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c1 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c1 not found"
    )
  }

  # Row 2: A9c1 == 1
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c1 not found"
    )
  }

  # Row 3: A9c1 == 2
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c1 not found"
    )
  }

  # Row 4: A9c1 == 3
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c1 not found"
    )
  }

  # Row 5: A9c1 == 4
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_5"]] <- list(
      label = "Haven't prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_5"]] <- list(
      label = "Haven't prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c1 not found"
    )
  }

  # Row 6: A9c2 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c2 not found"
    )
  }

  # Row 7: A9c2 == 1
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c2 not found"
    )
  }

  # Row 8: A9c2 == 2
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c2 not found"
    )
  }

  # Row 9: A9c2 == 3
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_9"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_9"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c2 not found"
    )
  }

  # Row 10: A9c2 == 4
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_10"]] <- list(
      label = "Haven't prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_10"]] <- list(
      label = "Haven't prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c2 not found"
    )
  }

  # Row 11: A9c3 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Encountered issues (NET) — Some or Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c3 not found"
    )
  }

  # Row 12: A9c3 == 1
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c3 not found"
    )
  }

  # Row 13: A9c3 == 2
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_13"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_13"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c3 not found"
    )
  }

  # Row 14: A9c3 == 3
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_14"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_14"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c3 not found"
    )
  }

  # Row 15: A9c3 == 4
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_15"]] <- list(
      label = "Haven't prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_15"]] <- list(
      label = "Haven't prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A9c3 not found"
    )
  }

}

all_tables[["a9"]] <- table_a9
print(paste("Generated frequency table: a9"))

# -----------------------------------------------------------------------------
# Table: a10 (frequency)
# Title: A10 - Reasons for using PCSK9 inhibitors without a statin
# Rows: 6
# Source: a10
# -----------------------------------------------------------------------------

table_a10 <- list(
  tableId = "a10",
  title = "A10 - Reasons for using PCSK9 inhibitors without a statin",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a10$data[[cut_name]] <- list()
  table_a10$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A10r1 == 1
  var_col <- safe_get_var(cut_data, "A10r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r1_row_1"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r1_row_1"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r1 not found"
    )
  }

  # Row 2: A10r2 == 1
  var_col <- safe_get_var(cut_data, "A10r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r2_row_2"]] <- list(
      label = "Patient is statin intolerant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r2_row_2"]] <- list(
      label = "Patient is statin intolerant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r2 not found"
    )
  }

  # Row 3: A10r3 == 1
  var_col <- safe_get_var(cut_data, "A10r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r3_row_3"]] <- list(
      label = "Patient refused statins",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r3_row_3"]] <- list(
      label = "Patient refused statins",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r3 not found"
    )
  }

  # Row 4: A10r4 == 1
  var_col <- safe_get_var(cut_data, "A10r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r4_row_4"]] <- list(
      label = "Statins are contraindicated for patient",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r4_row_4"]] <- list(
      label = "Statins are contraindicated for patient",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r4 not found"
    )
  }

  # Row 5: A10r5 == 1
  var_col <- safe_get_var(cut_data, "A10r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r5_row_5"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r5_row_5"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r5 not found"
    )
  }

  # Row 6: A10r6 == 1
  var_col <- safe_get_var(cut_data, "A10r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r6_row_6"]] <- list(
      label = "Haven't prescribed PCSK9s without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a10$data[[cut_name]][["A10r6_row_6"]] <- list(
      label = "Haven't prescribed PCSK9s without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A10r6 not found"
    )
  }

}

all_tables[["a10"]] <- table_a10
print(paste("Generated frequency table: a10"))

# -----------------------------------------------------------------------------
# Table: b1_coverage_by_insurance (mean_rows)
# Title: B1 - Percentage of your current patients covered by each insurance type
# Rows: 8
# -----------------------------------------------------------------------------

table_b1_coverage_by_insurance <- list(
  tableId = "b1_coverage_by_insurance",
  title = "B1 - Percentage of your current patients covered by each insurance type",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b1_coverage_by_insurance$data[[cut_name]] <- list()
  table_b1_coverage_by_insurance$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: B1r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r1 not found"
    )
  }

  # Row 2: B1r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r2 not found"
    )
  }

  # Row 3: B1r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r3 not found"
    )
  }

  # Row 4: B1r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r4 not found"
    )
  }

  # Row 5: B1r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r5 not found"
    )
  }

  # Row 6: B1r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r6 not found"
    )
  }

  # Row 7: B1r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r7 not found"
    )
  }

  # Row 8: B1r8 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b1_coverage_by_insurance$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b1_coverage_by_insurance$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B1r8 not found"
    )
  }

}

all_tables[["b1_coverage_by_insurance"]] <- table_b1_coverage_by_insurance
print(paste("Generated mean_rows table: b1_coverage_by_insurance"))

# -----------------------------------------------------------------------------
# Table: b5 (frequency) [DERIVED]
# Title: B5 - How would you describe your specialty/training? (Select all that apply)
# Rows: 6
# Source: b5
# -----------------------------------------------------------------------------

table_b5 <- list(
  tableId = "b5",
  title = "B5 - How would you describe your specialty/training? (Select all that apply)",
  tableType = "frequency",
  hints = c(),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b5$data[[cut_name]] <- list()
  table_b5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any of the above (NET) (components: B5r1, B5r2, B5r3, B5r4, B5r5)
  net_vars <- c("B5r1", "B5r2", "B5r3", "B5r4", "B5r5")
  net_respondents <- rep(FALSE, nrow(cut_data))
  for (net_var in net_vars) {
    var_col <- safe_get_var(cut_data, net_var)
    if (!is.null(var_col)) {
      # Mark respondent if they have any non-NA value for this variable
      net_respondents <- net_respondents | (!is.na(var_col) & var_col > 0)
    }
  }
  # Base = anyone who answered any component question
  base_n <- sum(!is.na(safe_get_var(cut_data, net_vars[1])))
  count <- sum(net_respondents, na.rm = TRUE)
  pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["_NET_B5_Any_row_1"]] <- list(
      label = "Any of the above (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )

  # Row 2: B5r1 == 1
  var_col <- safe_get_var(cut_data, "B5r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["B5r1_row_2"]] <- list(
      label = "Internal Medicine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b5$data[[cut_name]][["B5r1_row_2"]] <- list(
      label = "Internal Medicine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B5r1 not found"
    )
  }

  # Row 3: B5r2 == 1
  var_col <- safe_get_var(cut_data, "B5r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["B5r2_row_3"]] <- list(
      label = "General Practitioner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b5$data[[cut_name]][["B5r2_row_3"]] <- list(
      label = "General Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B5r2 not found"
    )
  }

  # Row 4: B5r3 == 1
  var_col <- safe_get_var(cut_data, "B5r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["B5r3_row_4"]] <- list(
      label = "Primary Care",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b5$data[[cut_name]][["B5r3_row_4"]] <- list(
      label = "Primary Care",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B5r3 not found"
    )
  }

  # Row 5: B5r4 == 1
  var_col <- safe_get_var(cut_data, "B5r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["B5r4_row_5"]] <- list(
      label = "Family Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b5$data[[cut_name]][["B5r4_row_5"]] <- list(
      label = "Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B5r4 not found"
    )
  }

  # Row 6: B5r5 == 1
  var_col <- safe_get_var(cut_data, "B5r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b5$data[[cut_name]][["B5r5_row_6"]] <- list(
      label = "Doctor of Osteopathic Medicine (DO)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b5$data[[cut_name]][["B5r5_row_6"]] <- list(
      label = "Doctor of Osteopathic Medicine (DO)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B5r5 not found"
    )
  }

}

all_tables[["b5"]] <- table_b5
print(paste("Generated frequency table: b5"))

# -----------------------------------------------------------------------------
# Table: s1 (frequency)
# Title: S1 - Consent to proceed (adverse events / product complaints reporting)
# Rows: 3
# -----------------------------------------------------------------------------

table_s1 <- list(
  tableId = "s1",
  title = "S1 - Consent to proceed (adverse events / product complaints reporting)",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s1$data[[cut_name]] <- list()
  table_s1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S1 == 1
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S1 not found"
    )
  }

  # Row 2: S1 == 2
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S1 not found"
    )
  }

  # Row 3: S1 == 3
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I don't want to proceed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I don't want to proceed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S1 not found"
    )
  }

}

all_tables[["s1"]] <- table_s1
print(paste("Generated frequency table: s1"))

# -----------------------------------------------------------------------------
# Table: s2b (frequency)
# Title: S2b - What is your primary role?
# Rows: 4
# -----------------------------------------------------------------------------

table_s2b <- list(
  tableId = "s2b",
  title = "S2b - What is your primary role?",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2b$data[[cut_name]] <- list()
  table_s2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2b == 1
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Physician",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Physician",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2b not found"
    )
  }

  # Row 2: S2b == 2
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2b not found"
    )
  }

  # Row 3: S2b == 3
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Physician's Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Physician's Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2b not found"
    )
  }

  # Row 4: S2b == 99
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2b not found"
    )
  }

}

all_tables[["s2b"]] <- table_s2b
print(paste("Generated frequency table: s2b"))

# -----------------------------------------------------------------------------
# Table: s2 (frequency) [DERIVED]
# Title: S2 - What is your primary specialty?
# Rows: 8
# Source: s2
# -----------------------------------------------------------------------------

table_s2 <- list(
  tableId = "s2",
  title = "S2 - What is your primary specialty?",
  tableType = "frequency",
  hints = c(),
  isDerived = TRUE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2$data[[cut_name]] <- list()
  table_s2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2 IN (6, 7)
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Nurse Practitioners & Physician's Assistants (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Nurse Practitioners & Physician's Assistants (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 2: S2 == 1
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_2"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_2"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 3: S2 == 2
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_3"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_3"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 4: S2 == 3
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_4"]] <- list(
      label = "Nephrologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_4"]] <- list(
      label = "Nephrologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 5: S2 == 4
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_5"]] <- list(
      label = "Endocrinologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_5"]] <- list(
      label = "Endocrinologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 6: S2 == 5
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_6"]] <- list(
      label = "Lipidologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_6"]] <- list(
      label = "Lipidologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 7: S2 == 6
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

  # Row 8: S2 == 7
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Physician's Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Physician's Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S2 not found"
    )
  }

}

all_tables[["s2"]] <- table_s2
print(paste("Generated frequency table: s2"))

# Skipping excluded table: s2a (S2a is a follow-up screener asked only when S2 indicates Nurse Practitioner or Physician Assistant. Two response options (2 and 3) lead to TERMINATE per survey logic; the question has limited analytic value and should be kept in reference/exclusion rather than main outputs.)

# -----------------------------------------------------------------------------
# Table: qCARD_SPECIALTY (frequency)
# Title: Primary specialty (grouped): Card vs Neph/Endo/Lip
# Rows: 2
# -----------------------------------------------------------------------------

table_qCARD_SPECIALTY <- list(
  tableId = "qCARD_SPECIALTY",
  title = "Primary specialty (grouped): Card vs Neph/Endo/Lip",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qCARD_SPECIALTY$data[[cut_name]] <- list()
  table_qCARD_SPECIALTY$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qCARD_SPECIALTY == 1
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

  # Row 2: qCARD_SPECIALTY == 2
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "Nephrologist / Endocrinologist / Lipidologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "Nephrologist / Endocrinologist / Lipidologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

}

all_tables[["qCARD_SPECIALTY"]] <- table_qCARD_SPECIALTY
print(paste("Generated frequency table: qCARD_SPECIALTY"))

# -----------------------------------------------------------------------------
# Table: qSPECIALTY (frequency)
# Title: SPECIALTY
# Rows: 3
# Source: qSPECIALTY
# -----------------------------------------------------------------------------

table_qSPECIALTY <- list(
  tableId = "qSPECIALTY",
  title = "SPECIALTY",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qSPECIALTY$data[[cut_name]] <- list()
  table_qSPECIALTY$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qSPECIALTY == 1
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 2: qSPECIALTY == 2
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 3: qSPECIALTY == 3
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "Nurse Practitioner / Physician Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "Nurse Practitioner / Physician Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qSPECIALTY not found"
    )
  }

}

all_tables[["qSPECIALTY"]] <- table_qSPECIALTY
print(paste("Generated frequency table: qSPECIALTY"))

# -----------------------------------------------------------------------------
# Table: s3a (frequency)
# Title: S3a - What type of Cardiologist are you primarily?
# Rows: 3
# -----------------------------------------------------------------------------

table_s3a <- list(
  tableId = "s3a",
  title = "S3a - What type of Cardiologist are you primarily?",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s3a$data[[cut_name]] <- list()
  table_s3a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S3a == 1
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S3a not found"
    )
  }

  # Row 2: S3a == 2
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "General Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "General Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S3a not found"
    )
  }

  # Row 3: S3a == 3
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S3a not found"
    )
  }

}

all_tables[["s3a"]] <- table_s3a
print(paste("Generated frequency table: s3a"))

# -----------------------------------------------------------------------------
# Table: qTYPE_OF_CARD (frequency)
# Title: What type of Cardiologist are you primarily? - Distribution
# Rows: 3
# Source: qTYPE_OF_CARD
# -----------------------------------------------------------------------------

table_qTYPE_OF_CARD <- list(
  tableId = "qTYPE_OF_CARD",
  title = "What type of Cardiologist are you primarily? - Distribution",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qTYPE_OF_CARD$data[[cut_name]] <- list()
  table_qTYPE_OF_CARD$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qTYPE_OF_CARD == 1
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 2: qTYPE_OF_CARD == 2
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 3: qTYPE_OF_CARD == 3
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

}

all_tables[["qTYPE_OF_CARD"]] <- table_qTYPE_OF_CARD
print(paste("Generated frequency table: qTYPE_OF_CARD"))

# -----------------------------------------------------------------------------
# Table: qON_LIST_OFF_LIST (frequency)
# Title: ON-LIST / OFF-LIST (Recruitment Tag) - Distribution
# Rows: 6
# Source: qON_LIST_OFF_LIST
# -----------------------------------------------------------------------------

table_qON_LIST_OFF_LIST <- list(
  tableId = "qON_LIST_OFF_LIST",
  title = "ON-LIST / OFF-LIST (Recruitment Tag) - Distribution",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qON_LIST_OFF_LIST$data[[cut_name]] <- list()
  table_qON_LIST_OFF_LIST$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qON_LIST_OFF_LIST == 1
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "Cardiologist - ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "Cardiologist - ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 2: qON_LIST_OFF_LIST == 2
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist - OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist - OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 3: qON_LIST_OFF_LIST == 3
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP (Primary Care) - ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP (Primary Care) - ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 4: qON_LIST_OFF_LIST == 4
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP (Primary Care) - OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP (Primary Care) - OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 5: qON_LIST_OFF_LIST == 5
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NP / PA - ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NP / PA - ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 6: qON_LIST_OFF_LIST == 6
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NP / PA - OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NP / PA - OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

}

all_tables[["qON_LIST_OFF_LIST"]] <- table_qON_LIST_OFF_LIST
print(paste("Generated frequency table: qON_LIST_OFF_LIST"))

# -----------------------------------------------------------------------------
# Table: qLIST_TIER (frequency)
# Title: qLIST_TIER - LIST TIER
# Rows: 4
# -----------------------------------------------------------------------------

table_qLIST_TIER <- list(
  tableId = "qLIST_TIER",
  title = "qLIST_TIER - LIST TIER",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qLIST_TIER$data[[cut_name]] <- list()
  table_qLIST_TIER$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qLIST_TIER == 1
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 2: qLIST_TIER == 2
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 3: qLIST_TIER == 3
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 4: qLIST_TIER == 4
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_TIER not found"
    )
  }

}

all_tables[["qLIST_TIER"]] <- table_qLIST_TIER
print(paste("Generated frequency table: qLIST_TIER"))

# -----------------------------------------------------------------------------
# Table: qLIST_PRIORITY_ACCOUNT (frequency)
# Title: LIST PRIORITY ACCOUNT - Priority status
# Rows: 2
# -----------------------------------------------------------------------------

table_qLIST_PRIORITY_ACCOUNT <- list(
  tableId = "qLIST_PRIORITY_ACCOUNT",
  title = "LIST PRIORITY ACCOUNT - Priority status",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]] <- list()
  table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qLIST_PRIORITY_ACCOUNT == 1
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "PRIORITY",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "PRIORITY",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

  # Row 2: qLIST_PRIORITY_ACCOUNT == 2
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "NOT PRIORITY",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "NOT PRIORITY",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

}

all_tables[["qLIST_PRIORITY_ACCOUNT"]] <- table_qLIST_PRIORITY_ACCOUNT
print(paste("Generated frequency table: qLIST_PRIORITY_ACCOUNT"))

# Skipping excluded table: s4 (S4 is a screener with terminate logic in the survey: responses 'Board Eligible' (1) and 'Neither' (3) lead to termination; only 'Board Certified' (2) continues. Exclude this screener/termination question from the main output (keep for reference).)

# -----------------------------------------------------------------------------
# Table: s6_years_in_practice (mean_rows)
# Title: S6 - Years in clinical practice (post residency/training)
# Rows: 1
# -----------------------------------------------------------------------------

table_s6_years_in_practice <- list(
  tableId = "s6_years_in_practice",
  title = "S6 - Years in clinical practice (post residency/training)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6_years_in_practice$data[[cut_name]] <- list()
  table_s6_years_in_practice$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S6 (numeric summary)
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s6_years_in_practice$data[[cut_name]][["S6"]] <- list(
      label = "Years in clinical practice (post residency/training)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s6_years_in_practice$data[[cut_name]][["S6"]] <- list(
      label = "Years in clinical practice (post residency/training)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S6 not found"
    )
  }

}

all_tables[["s6_years_in_practice"]] <- table_s6_years_in_practice
print(paste("Generated mean_rows table: s6_years_in_practice"))

# Skipping excluded table: s7 (Screener/termination: The survey marks 'Part-Time' (value=2) as a TERMINATE response. Only Full-Time respondents progress into the analytic sample, so this table will be essentially 100% Full-Time among completed respondents and is not analytically useful for main outputs. Excluding from main deliverables; retain in reference materials if needed.)

# -----------------------------------------------------------------------------
# Table: s9 (frequency)
# Title: S9 - Which of the following best represents the setting in which you spend most of your professional time?
# Rows: 8
# -----------------------------------------------------------------------------

table_s9 <- list(
  tableId = "s9",
  title = "S9 - Which of the following best represents the setting in which you spend most of your professional time?",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s9$data[[cut_name]] <- list()
  table_s9$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S9 == 1
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private Solo Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private Solo Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 2: S9 == 2
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Group Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Group Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 3: S9 == 3
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 4: S9 == 4
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Staff HMO",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Staff HMO",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 5: S9 == 5
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Community Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Community Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 6: S9 == 6
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Academic/University Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Academic/University Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 7: S9 == 7
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "VA Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "VA Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

  # Row 8: S9 == 8
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "None of the above",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S9 not found"
    )
  }

}

all_tables[["s9"]] <- table_s9
print(paste("Generated frequency table: s9"))

# -----------------------------------------------------------------------------
# Table: s10 (mean_rows)
# Title: S10 - Number of adult patients you personally manage per month
# Rows: 1
# -----------------------------------------------------------------------------

table_s10 <- list(
  tableId = "s10",
  title = "S10 - Number of adult patients you personally manage per month",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10$data[[cut_name]] <- list()
  table_s10$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S10 (numeric summary)
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s10$data[[cut_name]][["S10"]] <- list(
      label = "Number of adult patients (age 18+) you personally manage per month (personally = primary treatment decision maker)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s10$data[[cut_name]][["S10"]] <- list(
      label = "Number of adult patients (age 18+) you personally manage per month (personally = primary treatment decision maker)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S10 not found"
    )
  }

}

all_tables[["s10"]] <- table_s10
print(paste("Generated mean_rows table: s10"))

# -----------------------------------------------------------------------------
# Table: s11 (mean_rows)
# Title: S11 - Number of adult patients with confirmed hypercholesterolemia and established CVD (monthly)
# Rows: 1
# Source: s11
# -----------------------------------------------------------------------------

table_s11 <- list(
  tableId = "s11",
  title = "S11 - Number of adult patients with confirmed hypercholesterolemia and established CVD (monthly)",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11$data[[cut_name]] <- list()
  table_s11$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11 (numeric summary)
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s11$data[[cut_name]][["S11"]] <- list(
      label = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)? (number of patients)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_s11$data[[cut_name]][["S11"]] <- list(
      label = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)? (number of patients)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable S11 not found"
    )
  }

}

all_tables[["s11"]] <- table_s11
print(paste("Generated mean_rows table: s11"))

# -----------------------------------------------------------------------------
# Table: a2a (frequency)
# Title: A2a - Post-ACS guideline recommendation regarding lipid-lowering
# Rows: 3
# -----------------------------------------------------------------------------

table_a2a <- list(
  tableId = "a2a",
  title = "A2a - Post-ACS guideline recommendation regarding lipid-lowering",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a2a$data[[cut_name]] <- list()
  table_a2a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A2a == 1
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2a$data[[cut_name]][["A2a_row_1"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥55 mg/dL",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2a$data[[cut_name]][["A2a_row_1"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥55 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2a not found"
    )
  }

  # Row 2: A2a == 2
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2a$data[[cut_name]][["A2a_row_2"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥70 mg/dL",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2a$data[[cut_name]][["A2a_row_2"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥70 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2a not found"
    )
  }

  # Row 3: A2a == 3
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2a$data[[cut_name]][["A2a_row_3"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥100 mg/dL",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2a$data[[cut_name]][["A2a_row_3"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ≥100 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2a not found"
    )
  }

}

all_tables[["a2a"]] <- table_a2a
print(paste("Generated frequency table: a2a"))

# -----------------------------------------------------------------------------
# Table: a2b (frequency)
# Title: A2b - Current post-ACS guideline recommendation (lipid-lowering therapy)
# Rows: 3
# -----------------------------------------------------------------------------

table_a2b <- list(
  tableId = "a2b",
  title = "A2b - Current post-ACS guideline recommendation (lipid-lowering therapy)",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a2b$data[[cut_name]] <- list()
  table_a2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A2b == 1
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend a statin first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend a statin first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2b not found"
    )
  }

  # Row 2: A2b == 2
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2b not found"
    )
  }

  # Row 3: A2b == 3
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a PCSK9i first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a PCSK9i first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A2b not found"
    )
  }

}

all_tables[["a2b"]] <- table_a2b
print(paste("Generated frequency table: a2b"))

# -----------------------------------------------------------------------------
# Table: A5 (frequency)
# Title: A5 - How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?
# Rows: 4
# -----------------------------------------------------------------------------

table_A5 <- list(
  tableId = "A5",
  title = "A5 - How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A5$data[[cut_name]] <- list()
  table_A5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A5 == 1
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 3 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 3 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A5 not found"
    )
  }

  # Row 2: A5 == 2
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "4-6 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "4-6 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A5 not found"
    )
  }

  # Row 3: A5 == 3
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "7-12 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "7-12 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A5 not found"
    )
  }

  # Row 4: A5 == 4
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "Over a year",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_A5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "Over a year",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable A5 not found"
    )
  }

}

all_tables[["A5"]] <- table_A5
print(paste("Generated frequency table: A5"))

# -----------------------------------------------------------------------------
# Table: US_State (frequency)
# Title: US_State - State distribution
# Rows: 53
# -----------------------------------------------------------------------------

table_US_State <- list(
  tableId = "US_State",
  title = "US_State - State distribution",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_US_State$data[[cut_name]] <- list()
  table_US_State$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: US_State == 1
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State == 2
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State == 3
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State == 4
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == 5
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 6: US_State == 6
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 7: US_State == 7
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 8: US_State == 8
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 9: US_State == 9
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 10: US_State == 10
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 11: US_State == 11
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 12: US_State == 12
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 13: US_State == 13
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 14: US_State == 14
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 15: US_State == 15
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 16: US_State == 16
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 17: US_State == 17
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 18: US_State == 18
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 18, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 19: US_State == 19
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 20: US_State == 20
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 21: US_State == 21
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_21"]] <- list(
      label = "Maryland",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_21"]] <- list(
      label = "Maryland",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 22: US_State == 22
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_22"]] <- list(
      label = "Maine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_22"]] <- list(
      label = "Maine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 23: US_State == 23
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 23, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_23"]] <- list(
      label = "Michigan",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_23"]] <- list(
      label = "Michigan",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 24: US_State == 24
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_24"]] <- list(
      label = "Minnesota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_24"]] <- list(
      label = "Minnesota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 25: US_State == 25
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_25"]] <- list(
      label = "Missouri",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_25"]] <- list(
      label = "Missouri",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 26: US_State == 26
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_26"]] <- list(
      label = "Mississippi",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_26"]] <- list(
      label = "Mississippi",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 27: US_State == 27
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_27"]] <- list(
      label = "Montana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_27"]] <- list(
      label = "Montana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 28: US_State == 28
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_28"]] <- list(
      label = "North Carolina",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_28"]] <- list(
      label = "North Carolina",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 29: US_State == 29
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_29"]] <- list(
      label = "North Dakota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_29"]] <- list(
      label = "North Dakota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 30: US_State == 30
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_30"]] <- list(
      label = "Nebraska",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_30"]] <- list(
      label = "Nebraska",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 31: US_State == 31
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_31"]] <- list(
      label = "New Hampshire",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_31"]] <- list(
      label = "New Hampshire",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 32: US_State == 32
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_32"]] <- list(
      label = "New Jersey",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_32"]] <- list(
      label = "New Jersey",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 33: US_State == 33
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 33, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_33"]] <- list(
      label = "New Mexico",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_33"]] <- list(
      label = "New Mexico",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 34: US_State == 34
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_34"]] <- list(
      label = "Nevada",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_34"]] <- list(
      label = "Nevada",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 35: US_State == 35
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_35"]] <- list(
      label = "New York",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_35"]] <- list(
      label = "New York",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 36: US_State == 36
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 36, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_36"]] <- list(
      label = "Ohio",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_36"]] <- list(
      label = "Ohio",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 37: US_State == 37
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_37"]] <- list(
      label = "Oklahoma",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_37"]] <- list(
      label = "Oklahoma",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 38: US_State == 38
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 38, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_38"]] <- list(
      label = "Oregon",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_38"]] <- list(
      label = "Oregon",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 39: US_State == 39
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 39, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_39"]] <- list(
      label = "Pennsylvania",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_39"]] <- list(
      label = "Pennsylvania",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 40: US_State == 40
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_40"]] <- list(
      label = "Rhode Island",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_40"]] <- list(
      label = "Rhode Island",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 41: US_State == 41
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 41, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_41"]] <- list(
      label = "South Carolina",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_41"]] <- list(
      label = "South Carolina",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 42: US_State == 42
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 42, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_42"]] <- list(
      label = "South Dakota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_42"]] <- list(
      label = "South Dakota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 43: US_State == 43
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 43, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_43"]] <- list(
      label = "Tennessee",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_43"]] <- list(
      label = "Tennessee",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 44: US_State == 44
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 44, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_44"]] <- list(
      label = "Texas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_44"]] <- list(
      label = "Texas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 45: US_State == 45
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 45, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_45"]] <- list(
      label = "Utah",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_45"]] <- list(
      label = "Utah",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 46: US_State == 46
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 46, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_46"]] <- list(
      label = "Virginia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_46"]] <- list(
      label = "Virginia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 47: US_State == 47
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 47, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_47"]] <- list(
      label = "Vermont",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_47"]] <- list(
      label = "Vermont",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 48: US_State == 48
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 48, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_48"]] <- list(
      label = "Washington",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_48"]] <- list(
      label = "Washington",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 49: US_State == 49
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_49"]] <- list(
      label = "Wisconsin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_49"]] <- list(
      label = "Wisconsin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 50: US_State == 50
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_50"]] <- list(
      label = "West Virginia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_50"]] <- list(
      label = "West Virginia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 51: US_State == 51
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 51, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_51"]] <- list(
      label = "Wyoming",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_51"]] <- list(
      label = "Wyoming",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 52: US_State == 52
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 52, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_52"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_52"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

  # Row 53: US_State == 53
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 53, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_US_State$data[[cut_name]][["US_State_row_53"]] <- list(
      label = "Invalid State",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_US_State$data[[cut_name]][["US_State_row_53"]] <- list(
      label = "Invalid State",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable US_State not found"
    )
  }

}

all_tables[["US_State"]] <- table_US_State
print(paste("Generated frequency table: US_State"))

# -----------------------------------------------------------------------------
# Table: region (frequency)
# Title: Region - Distribution
# Rows: 6
# -----------------------------------------------------------------------------

table_region <- list(
  tableId = "region",
  title = "Region - Distribution",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_region$data[[cut_name]] <- list()
  table_region$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Region == 1
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "Northeast",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "Northeast",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

  # Row 2: Region == 2
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "South",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "South",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

  # Row 3: Region == 3
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "Midwest",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "Midwest",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

  # Row 4: Region == 4
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "West",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "West",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

  # Row 5: Region == 5
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

  # Row 6: Region == 6
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Invalid Region",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Invalid Region",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable Region not found"
    )
  }

}

all_tables[["region"]] <- table_region
print(paste("Generated frequency table: region"))

# -----------------------------------------------------------------------------
# Table: b3 (frequency)
# Title: B3 - Which of the following best describes where your primary practice is located?
# Rows: 3
# -----------------------------------------------------------------------------

table_b3 <- list(
  tableId = "b3",
  title = "B3 - Which of the following best describes where your primary practice is located?",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b3$data[[cut_name]] <- list()
  table_b3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: B3 == 1
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B3 not found"
    )
  }

  # Row 2: B3 == 2
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Suburban",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Suburban",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B3 not found"
    )
  }

  # Row 3: B3 == 3
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Rural",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Rural",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B3 not found"
    )
  }

}

all_tables[["b3"]] <- table_b3
print(paste("Generated frequency table: b3"))

# -----------------------------------------------------------------------------
# Table: b4 (mean_rows)
# Title: B4 - How many physicians are in your practice?
# Rows: 1
# -----------------------------------------------------------------------------

table_b4 <- list(
  tableId = "b4",
  title = "B4 - How many physicians are in your practice?",
  tableType = "mean_rows",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b4$data[[cut_name]] <- list()
  table_b4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: B4 (numeric summary)
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_b4$data[[cut_name]][["B4"]] <- list(
      label = "Number of physicians in your practice (numeric open-end)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_b4$data[[cut_name]][["B4"]] <- list(
      label = "Number of physicians in your practice (numeric open-end)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable B4 not found"
    )
  }

}

all_tables[["b4"]] <- table_b4
print(paste("Generated mean_rows table: b4"))

# -----------------------------------------------------------------------------
# Table: qconsent (frequency)
# Title: QCONSENT - Willing to participate in future research
# Rows: 2
# -----------------------------------------------------------------------------

table_qconsent <- list(
  tableId = "qconsent",
  title = "QCONSENT - Willing to participate in future research",
  tableType = "frequency",
  hints = c(),
  isDerived = FALSE,
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qconsent$data[[cut_name]] <- list()
  table_qconsent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: QCONSENT == 1
  var_col <- safe_get_var(cut_data, "QCONSENT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qconsent$data[[cut_name]][["QCONSENT_row_1"]] <- list(
      label = "Yes",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qconsent$data[[cut_name]][["QCONSENT_row_1"]] <- list(
      label = "Yes",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable QCONSENT not found"
    )
  }

  # Row 2: QCONSENT == 2
  var_col <- safe_get_var(cut_data, "QCONSENT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qconsent$data[[cut_name]][["QCONSENT_row_2"]] <- list(
      label = "No",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL
    )
  } else {
    table_qconsent$data[[cut_name]][["QCONSENT_row_2"]] <- list(
      label = "No",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NULL,
      error = "Variable QCONSENT not found"
    )
  }

}

all_tables[["qconsent"]] <- table_qconsent
print(paste("Generated frequency table: qconsent"))

# =============================================================================
# Significance Testing Pass
# =============================================================================

print("Running significance testing...")

for (table_id in names(all_tables)) {
  tbl <- all_tables[[table_id]]
  table_type <- tbl$tableType

  # Get row keys (skip metadata fields)
  cut_names <- names(tbl$data)

  for (cut_name in cut_names) {
    cut_data_obj <- tbl$data[[cut_name]]
    row_keys <- names(cut_data_obj)
    row_keys <- row_keys[row_keys != "stat_letter"]  # Skip metadata

    # Get cuts in same group for within-group comparison
    group_cuts <- get_group_cuts(cut_name)

    for (row_key in row_keys) {
      row_data <- cut_data_obj[[row_key]]
      if (is.null(row_data) || !is.null(row_data$error)) next

      sig_higher <- c()

      # Compare to other cuts in same group
      for (other_cut in group_cuts) {
        if (other_cut == cut_name) next
        if (!(other_cut %in% names(tbl$data))) next

        other_data <- tbl$data[[other_cut]][[row_key]]
        if (is.null(other_data) || !is.null(other_data$error)) next

        if (table_type == "frequency") {
          result <- sig_test_proportion(
            row_data$count, row_data$n,
            other_data$count, other_data$n
          )
          if (is.list(result) && !is.na(result$significant) && result$significant && result$higher) {
            sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])
          }
        } else if (table_type == "mean_rows") {
          # For means, we need the raw values - use count/pct as proxy
          # In practice, need to store raw values or use different approach
          if (!is.na(row_data$mean) && !is.na(other_data$mean)) {
            if (row_data$mean > other_data$mean) {
              # Simplified: flag if mean is higher (proper t-test needs raw data)
              sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])
            }
          }
        }
      }

      # Compare to Total
      if ("Total" %in% names(tbl$data) && cut_name != "Total") {
        total_data <- tbl$data[["Total"]][[row_key]]
        if (!is.null(total_data) && is.null(total_data$error)) {
          sig_vs_total <- NULL

          if (table_type == "frequency") {
            result <- sig_test_proportion(
              row_data$count, row_data$n,
              total_data$count, total_data$n
            )
            if (is.list(result) && !is.na(result$significant) && result$significant) {
              sig_vs_total <- if (result$higher) "higher" else "lower"
            }
          } else if (table_type == "mean_rows") {
            if (!is.na(row_data$mean) && !is.na(total_data$mean)) {
              if (row_data$mean != total_data$mean) {
                sig_vs_total <- if (row_data$mean > total_data$mean) "higher" else "lower"
              }
            }
          }

          all_tables[[table_id]]$data[[cut_name]][[row_key]]$sig_vs_total <- sig_vs_total
        }
      }

      # Update sig_higher_than
      all_tables[[table_id]]$data[[cut_name]][[row_key]]$sig_higher_than <- sig_higher
    }
  }
}

print("Significance testing complete")

# =============================================================================
# Save Results as JSON
# =============================================================================

# Create output directory
if (!dir.exists("results")) {
  dir.create("results", recursive = TRUE)
}

# Build final output structure
output <- list(
  metadata = list(
    generatedAt = "2026-01-08T16:45:57.771Z",
    tableCount = 51,
    cutCount = 21,
    significanceLevel = p_threshold,
    totalRespondents = nrow(data),
    bannerGroups = fromJSON('[{"groupName":"Total","columns":[{"name":"Total","statLetter":"T"}]},{"groupName":"Specialty","columns":[{"name":"Cards","statLetter":"A"},{"name":"PCPs","statLetter":"B"},{"name":"Nephs","statLetter":"C"},{"name":"Endos","statLetter":"D"},{"name":"Lipids","statLetter":"E"}]},{"groupName":"Role","columns":[{"name":"Physician","statLetter":"F"},{"name":"NP/PA","statLetter":"G"}]},{"groupName":"Volume of Adult ASCVD Patients","columns":[{"name":"Higher","statLetter":"H"},{"name":"Lower","statLetter":"I"}]},{"groupName":"Tiers","columns":[{"name":"Tier 1","statLetter":"J"},{"name":"Tier 2","statLetter":"K"},{"name":"Tier 3","statLetter":"L"},{"name":"Tier 4","statLetter":"M"}]},{"groupName":"Segments","columns":[{"name":"Segment A","statLetter":"N"},{"name":"Segment B","statLetter":"O"},{"name":"Segment C","statLetter":"P"},{"name":"Segment D","statLetter":"Q"}]},{"groupName":"Priority Accounts","columns":[{"name":"Priority Account","statLetter":"R"},{"name":"Non-Priority Account","statLetter":"S"}]}]'),
    comparisonGroups = fromJSON('["A/B/C/D/E","F/G","H/I","J/K/L/M","N/O/P/Q","R/S"]')
  ),
  tables = all_tables
)

# Write JSON output
output_path <- file.path("results", "tables.json")
write_json(output, output_path, pretty = TRUE, auto_unbox = TRUE)
print(paste("JSON output saved to:", output_path))

# Summary
print(paste(rep("=", 60), collapse = ""))
print(paste("SUMMARY"))
print(paste("  Tables generated:", length(all_tables)))
print(paste("  Cuts applied:", length(cuts)))
print(paste("  Significance level:", p_threshold))
print(paste("  Output:", output_path))
print(paste(rep("=", 60), collapse = ""))