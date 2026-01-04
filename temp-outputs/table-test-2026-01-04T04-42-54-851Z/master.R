# HawkTab AI - R Script V2
# Session: 2026-01-04T05-30-47-694Z
# Generated: 2026-01-04T05:30:47.695Z
# Tables: 51
# Cuts: 9

# Load required libraries
library(haven)
library(dplyr)
library(jsonlite)

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

# Define cuts (banner columns)
cuts <- list(
  Total = rep(TRUE, nrow(data))
,  `Male` = with(data, S2 == 1)
,  `Female` = with(data, S2 == 2)
,  `Cardiology` = with(data, S6 == 1)
,  `Endocrinology` = with(data, S6 == 2)
,  `Primary Care` = with(data, S6 == 3)
,  `Years in Practice: <10` = with(data, S3 < 10)
,  `Years in Practice: 10-20` = with(data, S3 >= 10 & S3 <= 20)
,  `Years in Practice: >20` = with(data, S3 > 20)
)

print(paste("Defined", length(cuts), "cuts"))

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

# =============================================================================
# Table Calculations
# =============================================================================

all_tables <- list()

# -----------------------------------------------------------------------------
# Table: s5 (frequency)
# Title: S5 - Employment / commercial affiliation (selected = 1)
# Rows: 7
# -----------------------------------------------------------------------------

table_s5 <- list(
  tableId = "s5",
  title = "S5 - Employment / commercial affiliation (selected = 1)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s5$data[[cut_name]] <- list()

  # Row 1: S5r1 == "1"
  var_col <- safe_get_var(cut_data, "S5r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r1_row_1"]] <- list(
      label = "Advertising Agency",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r1_row_1"]] <- list(
      label = "Advertising Agency",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r1 not found"
    )
  }

  # Row 2: S5r2 == "1"
  var_col <- safe_get_var(cut_data, "S5r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r2_row_2"]] <- list(
      label = "Marketing/Market Research Firm",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r2_row_2"]] <- list(
      label = "Marketing/Market Research Firm",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r2 not found"
    )
  }

  # Row 3: S5r3 == "1"
  var_col <- safe_get_var(cut_data, "S5r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r3_row_3"]] <- list(
      label = "Public Relations Firm",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r3_row_3"]] <- list(
      label = "Public Relations Firm",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r3 not found"
    )
  }

  # Row 4: S5r4 == "1"
  var_col <- safe_get_var(cut_data, "S5r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r4_row_4"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r4_row_4"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r4 not found"
    )
  }

  # Row 5: S5r5 == "1"
  var_col <- safe_get_var(cut_data, "S5r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r5_row_5"]] <- list(
      label = "Pharmaceutical Drug / Device Manufacturer (outside of clinical trials)",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r5_row_5"]] <- list(
      label = "Pharmaceutical Drug / Device Manufacturer (outside of clinical trials)",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r5 not found"
    )
  }

  # Row 6: S5r6 == "1"
  var_col <- safe_get_var(cut_data, "S5r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r6_row_6"]] <- list(
      label = "Governmental Regulatory Agency (e.g., Food & Drug Administration (FDA))",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r6_row_6"]] <- list(
      label = "Governmental Regulatory Agency (e.g., Food & Drug Administration (FDA))",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r6 not found"
    )
  }

  # Row 7: S5r7 == "1"
  var_col <- safe_get_var(cut_data, "S5r7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r7_row_7"]] <- list(
      label = "None of these",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s5$data[[cut_name]][["S5r7_row_7"]] <- list(
      label = "None of these",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S5r7 not found"
    )
  }

}

all_tables[["s5"]] <- table_s5
print(paste("Generated frequency table: s5"))

# -----------------------------------------------------------------------------
# Table: S8_mean_rows (mean_rows)
# Title: S8 - Percentage of professional time by activity (mean / median / std dev)
# Rows: 4
# -----------------------------------------------------------------------------

table_S8_mean_rows <- list(
  tableId = "S8_mean_rows",
  title = "S8 - Percentage of professional time by activity (mean / median / std dev)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_S8_mean_rows$data[[cut_name]] <- list()

  # Row 1: S8r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_S8_mean_rows$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_S8_mean_rows$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S8r1 not found"
    )
  }

  # Row 2: S8r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_S8_mean_rows$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_S8_mean_rows$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S8r2 not found"
    )
  }

  # Row 3: S8r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_S8_mean_rows$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_S8_mean_rows$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S8r3 not found"
    )
  }

  # Row 4: S8r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_S8_mean_rows$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_S8_mean_rows$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S8r4 not found"
    )
  }

}

all_tables[["S8_mean_rows"]] <- table_S8_mean_rows
print(paste("Generated mean_rows table: S8_mean_rows"))

# -----------------------------------------------------------------------------
# Table: s12_mean_rows (mean_rows)
# Title: S12 - Number of patients with an event (mean/median/stddev)
# Rows: 4
# -----------------------------------------------------------------------------

table_s12_mean_rows <- list(
  tableId = "s12_mean_rows",
  title = "S12 - Number of patients with an event (mean/median/stddev)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s12_mean_rows$data[[cut_name]] <- list()

  # Row 1: S12r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s12_mean_rows$data[[cut_name]][["S12r1"]] <- list(
      label = "Over 5 years ago",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s12_mean_rows$data[[cut_name]][["S12r1"]] <- list(
      label = "Over 5 years ago",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S12r1 not found"
    )
  }

  # Row 2: S12r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s12_mean_rows$data[[cut_name]][["S12r2"]] <- list(
      label = "Within the last 3-5 years",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s12_mean_rows$data[[cut_name]][["S12r2"]] <- list(
      label = "Within the last 3-5 years",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S12r2 not found"
    )
  }

  # Row 3: S12r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s12_mean_rows$data[[cut_name]][["S12r3"]] <- list(
      label = "Within the last 1-2 years",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s12_mean_rows$data[[cut_name]][["S12r3"]] <- list(
      label = "Within the last 1-2 years",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S12r3 not found"
    )
  }

  # Row 4: S12r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "S12r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s12_mean_rows$data[[cut_name]][["S12r4"]] <- list(
      label = "Within the last year",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s12_mean_rows$data[[cut_name]][["S12r4"]] <- list(
      label = "Within the last year",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S12r4 not found"
    )
  }

}

all_tables[["s12_mean_rows"]] <- table_s12_mean_rows
print(paste("Generated mean_rows table: s12_mean_rows"))

# -----------------------------------------------------------------------------
# Table: a1_overview (frequency)
# Title: A1 - Current indication by treatment
# Rows: 8
# -----------------------------------------------------------------------------

table_a1_overview <- list(
  tableId = "a1_overview",
  title = "A1 - Current indication by treatment",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a1_overview$data[[cut_name]] <- list()

  # Row 1: A1r1 == "1"
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r1_row_1"]] <- list(
      label = "Leqvio (inclisiran) - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r1_row_1"]] <- list(
      label = "Leqvio (inclisiran) - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r1 not found"
    )
  }

  # Row 2: A1r1 == "2"
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "Leqvio (inclisiran) - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "Leqvio (inclisiran) - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r1 not found"
    )
  }

  # Row 3: A1r2 == "1"
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r2_row_3"]] <- list(
      label = "Praluent (alirocumab) - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r2_row_3"]] <- list(
      label = "Praluent (alirocumab) - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r2 not found"
    )
  }

  # Row 4: A1r2 == "2"
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r2_row_4"]] <- list(
      label = "Praluent (alirocumab) - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r2_row_4"]] <- list(
      label = "Praluent (alirocumab) - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r2 not found"
    )
  }

  # Row 5: A1r3 == "1"
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r3_row_5"]] <- list(
      label = "Repatha (evolocumab) - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r3_row_5"]] <- list(
      label = "Repatha (evolocumab) - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r3 not found"
    )
  }

  # Row 6: A1r3 == "2"
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r3_row_6"]] <- list(
      label = "Repatha (evolocumab) - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r3_row_6"]] <- list(
      label = "Repatha (evolocumab) - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r3 not found"
    )
  }

  # Row 7: A1r4 == "1"
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r4_row_7"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid / bempedoic + ezetimibe) - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r4_row_7"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid / bempedoic + ezetimibe) - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r4 not found"
    )
  }

  # Row 8: A1r4 == "2"
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1_overview$data[[cut_name]][["A1r4_row_8"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid / bempedoic + ezetimibe) - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a1_overview$data[[cut_name]][["A1r4_row_8"]] <- list(
      label = "Nexletol/Nexlizet (bempedoic acid / bempedoic + ezetimibe) - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A1r4 not found"
    )
  }

}

all_tables[["a1_overview"]] <- table_a1_overview
print(paste("Generated frequency table: a1_overview"))

# -----------------------------------------------------------------------------
# Table: A3_mean_rows (mean_rows)
# Title: A3 - Number prescribed per 100 patients by therapy (mean/median/stddev)
# Rows: 7
# -----------------------------------------------------------------------------

table_A3_mean_rows <- list(
  tableId = "A3_mean_rows",
  title = "A3 - Number prescribed per 100 patients by therapy (mean/median/stddev)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A3_mean_rows$data[[cut_name]] <- list()

  # Row 1: A3r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r1 not found"
    )
  }

  # Row 2: A3r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r2 not found"
    )
  }

  # Row 3: A3r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r3"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r3"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r3 not found"
    )
  }

  # Row 4: A3r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r4"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r4"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r4 not found"
    )
  }

  # Row 5: A3r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r5"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r5"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r5 not found"
    )
  }

  # Row 6: A3r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r6"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r6"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r6 not found"
    )
  }

  # Row 7: A3r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3_mean_rows$data[[cut_name]][["A3r7"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3_mean_rows$data[[cut_name]][["A3r7"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3r7 not found"
    )
  }

}

all_tables[["A3_mean_rows"]] <- table_A3_mean_rows
print(paste("Generated mean_rows table: A3_mean_rows"))

# -----------------------------------------------------------------------------
# Table: A3a_mean (mean_rows)
# Title: A3a - % of last 100 who received therapy with vs without a statin (mean/median)
# Rows: 10
# -----------------------------------------------------------------------------

table_A3a_mean <- list(
  tableId = "A3a_mean",
  title = "A3a - % of last 100 who received therapy with vs without a statin (mean/median)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A3a_mean$data[[cut_name]] <- list()

  # Row 1: A3ar1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "Leqvio (inclisiran) - In addition to statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar1c1 not found"
    )
  }

  # Row 2: A3ar1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Leqvio (inclisiran) - Without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar1c2 not found"
    )
  }

  # Row 3: A3ar2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "Praluent (alirocumab) - In addition to statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar2c1 not found"
    )
  }

  # Row 4: A3ar2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Praluent (alirocumab) - Without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar2c2 not found"
    )
  }

  # Row 5: A3ar3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "Repatha (evolocumab) - In addition to statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar3c1 not found"
    )
  }

  # Row 6: A3ar3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Repatha (evolocumab) - Without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar3c2 not found"
    )
  }

  # Row 7: A3ar4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "Zetia (ezetimibe) - In addition to statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "Zetia (ezetimibe) - In addition to statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar4c1 not found"
    )
  }

  # Row 8: A3ar4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Zetia (ezetimibe) - Without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Zetia (ezetimibe) - Without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar4c2 not found"
    )
  }

  # Row 9: A3ar5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid) - In addition to statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid) - In addition to statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 10: A3ar5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3a_mean$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid) - Without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3a_mean$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid) - Without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

}

all_tables[["A3a_mean"]] <- table_A3a_mean
print(paste("Generated mean_rows table: A3a_mean"))

# -----------------------------------------------------------------------------
# Table: A3b_mean_rows (mean_rows)
# Title: A3b - % of patients receiving therapy without a statin (by timing and drug)
# Rows: 10
# -----------------------------------------------------------------------------

table_A3b_mean_rows <- list(
  tableId = "A3b_mean_rows",
  title = "A3b - % of patients receiving therapy without a statin (by timing and drug)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A3b_mean_rows$data[[cut_name]] <- list()

  # Row 1: A3br1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br1c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br1c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 2: A3br1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br1c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br1c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br1c2 not found"
    )
  }

  # Row 3: A3br2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br2c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br2c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 4: A3br2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br2c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br2c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br2c2 not found"
    )
  }

  # Row 5: A3br3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br3c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br3c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 6: A3br3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br3c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br3c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br3c2 not found"
    )
  }

  # Row 7: A3br4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br4c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br4c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 8: A3br4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br4c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br4c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br4c2 not found"
    )
  }

  # Row 9: A3br5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br5c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br5c1"]] <- list(
      label = "BEFORE any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 10: A3br5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A3b_mean_rows$data[[cut_name]][["A3br5c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A3b_mean_rows$data[[cut_name]][["A3br5c2"]] <- list(
      label = "AFTER trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A3br5c2 not found"
    )
  }

}

all_tables[["A3b_mean_rows"]] <- table_A3b_mean_rows
print(paste("Generated mean_rows table: A3b_mean_rows"))

# -----------------------------------------------------------------------------
# Table: a4_mean_rows (mean_rows)
# Title: A4 - Number (out of 100) prescribed for each treatment (mean/median/stddev)
# Rows: 14
# -----------------------------------------------------------------------------

table_a4_mean_rows <- list(
  tableId = "a4_mean_rows",
  title = "A4 - Number (out of 100) prescribed for each treatment (mean/median/stddev)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_mean_rows$data[[cut_name]] <- list()

  # Row 1: A4r1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r1c1 not found"
    )
  }

  # Row 2: A4r2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r2c1 not found"
    )
  }

  # Row 3: A4r3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r3c1 not found"
    )
  }

  # Row 4: A4r4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r4c1 not found"
    )
  }

  # Row 5: A4r5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r5c1 not found"
    )
  }

  # Row 6: A4r6c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r6c1 not found"
    )
  }

  # Row 7: A4r7c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r7c1 not found"
    )
  }

  # Row 8: A4r1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r1c2 not found"
    )
  }

  # Row 9: A4r2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r2c2 not found"
    )
  }

  # Row 10: A4r3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r3c2 not found"
    )
  }

  # Row 11: A4r4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r4c2 not found"
    )
  }

  # Row 12: A4r5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r5c2 not found"
    )
  }

  # Row 13: A4r6c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r6c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r6c2 not found"
    )
  }

  # Row 14: A4r7c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4r7c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_a4_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_a4_mean_rows$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4r7c2 not found"
    )
  }

}

all_tables[["a4_mean_rows"]] <- table_a4_mean_rows
print(paste("Generated mean_rows table: a4_mean_rows"))

# -----------------------------------------------------------------------------
# Table: A4a_mean (mean_rows)
# Title: A4a - % of NEXT 100 patients expected to be prescribed each therapy (mean/median)
# Rows: 10
# -----------------------------------------------------------------------------

table_A4a_mean <- list(
  tableId = "A4a_mean",
  title = "A4a - % of NEXT 100 patients expected to be prescribed each therapy (mean/median)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A4a_mean$data[[cut_name]] <- list()

  # Row 1: A4ar1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "A4ar1: Leqvio (inclisiran) - in addition to a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "A4ar1: Leqvio (inclisiran) - in addition to a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar1c1 not found"
    )
  }

  # Row 2: A4ar1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "A4ar1: Leqvio (inclisiran) - without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "A4ar1: Leqvio (inclisiran) - without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar1c2 not found"
    )
  }

  # Row 3: A4ar2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "A4ar2: Praluent (alirocumab) - in addition to a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "A4ar2: Praluent (alirocumab) - in addition to a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar2c1 not found"
    )
  }

  # Row 4: A4ar2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "A4ar2: Praluent (alirocumab) - without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "A4ar2: Praluent (alirocumab) - without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar2c2 not found"
    )
  }

  # Row 5: A4ar3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "A4ar3: Repatha (evolocumab) - in addition to a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "A4ar3: Repatha (evolocumab) - in addition to a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar3c1 not found"
    )
  }

  # Row 6: A4ar3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "A4ar3: Repatha (evolocumab) - without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "A4ar3: Repatha (evolocumab) - without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar3c2 not found"
    )
  }

  # Row 7: A4ar4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "A4ar4: Zetia (ezetimibe) - in addition to a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "A4ar4: Zetia (ezetimibe) - in addition to a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar4c1 not found"
    )
  }

  # Row 8: A4ar4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "A4ar4: Zetia (ezetimibe) - without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "A4ar4: Zetia (ezetimibe) - without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar4c2 not found"
    )
  }

  # Row 9: A4ar5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "A4ar5: Nexletol/Nexlizet (bempedoic acid) - in addition to a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "A4ar5: Nexletol/Nexlizet (bempedoic acid) - in addition to a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar5c1 not found"
    )
  }

  # Row 10: A4ar5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4ar5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4a_mean$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "A4ar5: Nexletol/Nexlizet (bempedoic acid) - without a statin",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4a_mean$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "A4ar5: Nexletol/Nexlizet (bempedoic acid) - without a statin",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4ar5c2 not found"
    )
  }

}

all_tables[["A4a_mean"]] <- table_A4a_mean
print(paste("Generated mean_rows table: A4a_mean"))

# -----------------------------------------------------------------------------
# Table: A4b_mean (mean_rows)
# Title: A4b - Next treatment allocation (percent, 0-100)
# Rows: 10
# -----------------------------------------------------------------------------

table_A4b_mean <- list(
  tableId = "A4b_mean",
  title = "A4b - Next treatment allocation (percent, 0-100)",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A4b_mean$data[[cut_name]] <- list()

  # Row 1: A4br1c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br1c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) - column c1",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) - column c1",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br1c1 not found"
    )
  }

  # Row 2: A4br1c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br1c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) - column c2",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) - column c2",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br1c2 not found"
    )
  }

  # Row 3: A4br2c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br2c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) - column c1",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) - column c1",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br2c1 not found"
    )
  }

  # Row 4: A4br2c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br2c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) - column c2",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) - column c2",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br2c2 not found"
    )
  }

  # Row 5: A4br3c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br3c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) - column c1",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) - column c1",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br3c1 not found"
    )
  }

  # Row 6: A4br3c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br3c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) - column c2",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) - column c2",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br3c2 not found"
    )
  }

  # Row 7: A4br4c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br4c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - column c1",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - column c1",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br4c1 not found"
    )
  }

  # Row 8: A4br4c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br4c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - column c2",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - column c2",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br4c2 not found"
    )
  }

  # Row 9: A4br5c1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br5c1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - column c1",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - column c1",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br5c1 not found"
    )
  }

  # Row 10: A4br5c2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A4br5c2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_A4b_mean$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - column c2",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_A4b_mean$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) - column c2",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable A4br5c2 not found"
    )
  }

}

all_tables[["A4b_mean"]] <- table_A4b_mean
print(paste("Generated mean_rows table: A4b_mean"))

# -----------------------------------------------------------------------------
# Table: A6_rank1 (frequency)
# Title: A6 - Items ranked #1
# Rows: 8
# -----------------------------------------------------------------------------

table_A6_rank1 <- list(
  tableId = "A6_rank1",
  title = "A6 - Items ranked #1",
  tableType = "frequency",
  hints = c("ranking"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank1$data[[cut_name]] <- list()

  # Row 1: A6r1 == "1"
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == "1"
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == "1"
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == "1"
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == "1"
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == "1"
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == "1"
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == "1"
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank2$data[[cut_name]] <- list()

  # Row 1: A6r1 == "2"
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == "2"
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == "2"
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == "2"
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == "2"
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == "2"
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == "2"
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == "2"
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
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
# -----------------------------------------------------------------------------

table_A6_rank3 <- list(
  tableId = "A6_rank3",
  title = "A6 - Items ranked #3",
  tableType = "frequency",
  hints = c("ranking"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank3$data[[cut_name]] <- list()

  # Row 1: A6r1 == "3"
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == "3"
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == "3"
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == "3"
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == "3"
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == "3"
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == "3"
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == "3"
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank3$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank3$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank3"]] <- table_A6_rank3
print(paste("Generated frequency table: A6_rank3"))

# -----------------------------------------------------------------------------
# Table: A6_rank4 (frequency)
# Title: A6 - Items ranked #4
# Rows: 8
# -----------------------------------------------------------------------------

table_A6_rank4 <- list(
  tableId = "A6_rank4",
  title = "A6 - Items ranked #4",
  tableType = "frequency",
  hints = c("ranking"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A6_rank4$data[[cut_name]] <- list()

  # Row 1: A6r1 == "4"
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == "4"
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == "4"
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == "4"
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == "4"
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == "4"
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == "4"
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == "4"
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A6_rank4$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A6_rank4$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["A6_rank4"]] <- table_A6_rank4
print(paste("Generated frequency table: A6_rank4"))

# -----------------------------------------------------------------------------
# Table: a7_multi_select (frequency)
# Title: A7 - Impacts on perceptions/prescribing (select all that apply)
# Rows: 5
# -----------------------------------------------------------------------------

table_a7_multi_select <- list(
  tableId = "a7_multi_select",
  title = "A7 - Impacts on perceptions/prescribing (select all that apply)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a7_multi_select$data[[cut_name]] <- list()

  # Row 1: A7r1 == "1"
  var_col <- safe_get_var(cut_data, "A7r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_multi_select$data[[cut_name]][["A7r1_row_1"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a7_multi_select$data[[cut_name]][["A7r1_row_1"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A7r1 not found"
    )
  }

  # Row 2: A7r2 == "1"
  var_col <- safe_get_var(cut_data, "A7r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_multi_select$data[[cut_name]][["A7r2_row_2"]] <- list(
      label = "Offers an option to patients who can’t or won’t take a statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a7_multi_select$data[[cut_name]][["A7r2_row_2"]] <- list(
      label = "Offers an option to patients who can’t or won’t take a statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A7r2 not found"
    )
  }

  # Row 3: A7r3 == "1"
  var_col <- safe_get_var(cut_data, "A7r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_multi_select$data[[cut_name]][["A7r3_row_3"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a7_multi_select$data[[cut_name]][["A7r3_row_3"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A7r3 not found"
    )
  }

  # Row 4: A7r4 == "1"
  var_col <- safe_get_var(cut_data, "A7r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_multi_select$data[[cut_name]][["A7r4_row_4"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a7_multi_select$data[[cut_name]][["A7r4_row_4"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A7r4 not found"
    )
  }

  # Row 5: A7r5 == "1"
  var_col <- safe_get_var(cut_data, "A7r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_multi_select$data[[cut_name]][["A7r5_row_5"]] <- list(
      label = "Other (Specify)",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a7_multi_select$data[[cut_name]][["A7r5_row_5"]] <- list(
      label = "Other (Specify)",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A7r5 not found"
    )
  }

}

all_tables[["a7_multi_select"]] <- table_a7_multi_select
print(paste("Generated frequency table: a7_multi_select"))

# -----------------------------------------------------------------------------
# Table: A8_r1 (frequency)
# Title: A8r1 - With established CVD: likelihood to prescribe each therapy alone
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r1 <- list(
  tableId = "A8_r1",
  title = "A8r1 - With established CVD: likelihood to prescribe each therapy alone",
  tableType = "frequency",
  hints = c("scale-5"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r1$data[[cut_name]] <- list()

  # Row 1: A8r1c1 == "1"
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 2: A8r1c1 == "2"
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 3: A8r1c1 == "3"
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 4: A8r1c1 == "4"
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 5: A8r1c1 == "5"
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 6: A8r1c2 == "1"
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 7: A8r1c2 == "2"
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 8: A8r1c2 == "3"
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 9: A8r1c2 == "4"
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 10: A8r1c2 == "5"
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 11: A8r1c3 == "1"
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 12: A8r1c3 == "2"
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 13: A8r1c3 == "3"
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 14: A8r1c3 == "4"
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 15: A8r1c3 == "5"
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r1$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r1$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r1c3 not found"
    )
  }

}

all_tables[["A8_r1"]] <- table_A8_r1
print(paste("Generated frequency table: A8_r1"))

# -----------------------------------------------------------------------------
# Table: A8_r2 (frequency)
# Title: A8r2 - With no history of CV events and at high-risk: likelihood to prescribe each therapy alone
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r2 <- list(
  tableId = "A8_r2",
  title = "A8r2 - With no history of CV events and at high-risk: likelihood to prescribe each therapy alone",
  tableType = "frequency",
  hints = c("scale-5"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r2$data[[cut_name]] <- list()

  # Row 1: A8r2c1 == "1"
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 2: A8r2c1 == "2"
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 3: A8r2c1 == "3"
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 4: A8r2c1 == "4"
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 5: A8r2c1 == "5"
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 6: A8r2c2 == "1"
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 7: A8r2c2 == "2"
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 8: A8r2c2 == "3"
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 9: A8r2c2 == "4"
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 10: A8r2c2 == "5"
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 11: A8r2c3 == "1"
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 12: A8r2c3 == "2"
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 13: A8r2c3 == "3"
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 14: A8r2c3 == "4"
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 15: A8r2c3 == "5"
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r2$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r2$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r2c3 not found"
    )
  }

}

all_tables[["A8_r2"]] <- table_A8_r2
print(paste("Generated frequency table: A8_r2"))

# -----------------------------------------------------------------------------
# Table: A8_r3 (frequency)
# Title: A8r3 - With no history of CV events and at low-to-medium risk: likelihood to prescribe each therapy alone
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r3 <- list(
  tableId = "A8_r3",
  title = "A8r3 - With no history of CV events and at low-to-medium risk: likelihood to prescribe each therapy alone",
  tableType = "frequency",
  hints = c("scale-5"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r3$data[[cut_name]] <- list()

  # Row 1: A8r3c1 == "1"
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 2: A8r3c1 == "2"
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 3: A8r3c1 == "3"
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 4: A8r3c1 == "4"
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 5: A8r3c1 == "5"
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 6: A8r3c2 == "1"
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 7: A8r3c2 == "2"
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 8: A8r3c2 == "3"
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 9: A8r3c2 == "4"
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 10: A8r3c2 == "5"
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 11: A8r3c3 == "1"
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 12: A8r3c3 == "2"
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 13: A8r3c3 == "3"
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 14: A8r3c3 == "4"
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 15: A8r3c3 == "5"
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r3$data[[cut_name]][["A8r3c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r3$data[[cut_name]][["A8r3c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r3c3 not found"
    )
  }

}

all_tables[["A8_r3"]] <- table_A8_r3
print(paste("Generated frequency table: A8_r3"))

# -----------------------------------------------------------------------------
# Table: A8_r4 (frequency)
# Title: A8r4 - Who are not known to be compliant on statins: likelihood to prescribe each therapy alone
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r4 <- list(
  tableId = "A8_r4",
  title = "A8r4 - Who are not known to be compliant on statins: likelihood to prescribe each therapy alone",
  tableType = "frequency",
  hints = c("scale-5"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r4$data[[cut_name]] <- list()

  # Row 1: A8r4c1 == "1"
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 2: A8r4c1 == "2"
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 3: A8r4c1 == "3"
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 4: A8r4c1 == "4"
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 5: A8r4c1 == "5"
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 6: A8r4c2 == "1"
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 7: A8r4c2 == "2"
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 8: A8r4c2 == "3"
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 9: A8r4c2 == "4"
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 10: A8r4c2 == "5"
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 11: A8r4c3 == "1"
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 12: A8r4c3 == "2"
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 13: A8r4c3 == "3"
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 14: A8r4c3 == "4"
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 15: A8r4c3 == "5"
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r4$data[[cut_name]][["A8r4c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r4$data[[cut_name]][["A8r4c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r4c3 not found"
    )
  }

}

all_tables[["A8_r4"]] <- table_A8_r4
print(paste("Generated frequency table: A8_r4"))

# -----------------------------------------------------------------------------
# Table: A8_r5 (frequency)
# Title: A8r5 - Who are intolerant of statins: likelihood to prescribe each therapy alone
# Rows: 15
# -----------------------------------------------------------------------------

table_A8_r5 <- list(
  tableId = "A8_r5",
  title = "A8r5 - Who are intolerant of statins: likelihood to prescribe each therapy alone",
  tableType = "frequency",
  hints = c("scale-5"),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A8_r5$data[[cut_name]] <- list()

  # Row 1: A8r5c1 == "1"
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 2: A8r5c1 == "2"
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_2"]] <- list(
      label = "Repatha - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 3: A8r5c1 == "3"
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_3"]] <- list(
      label = "Repatha - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 4: A8r5c1 == "4"
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_4"]] <- list(
      label = "Repatha - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 5: A8r5c1 == "5"
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c1_row_5"]] <- list(
      label = "Repatha - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 6: A8r5c2 == "1"
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_6"]] <- list(
      label = "Praluent - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 7: A8r5c2 == "2"
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_7"]] <- list(
      label = "Praluent - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 8: A8r5c2 == "3"
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_8"]] <- list(
      label = "Praluent - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 9: A8r5c2 == "4"
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_9"]] <- list(
      label = "Praluent - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 10: A8r5c2 == "5"
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c2_row_10"]] <- list(
      label = "Praluent - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 11: A8r5c3 == "1"
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_11"]] <- list(
      label = "Leqvio - Response 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 12: A8r5c3 == "2"
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_12"]] <- list(
      label = "Leqvio - Response 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 13: A8r5c3 == "3"
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_13"]] <- list(
      label = "Leqvio - Response 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 14: A8r5c3 == "4"
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_14"]] <- list(
      label = "Leqvio - Response 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 15: A8r5c3 == "5"
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A8_r5$data[[cut_name]][["A8r5c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A8_r5$data[[cut_name]][["A8r5c3_row_15"]] <- list(
      label = "Leqvio - Response 5",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A8r5c3 not found"
    )
  }

}

all_tables[["A8_r5"]] <- table_A8_r5
print(paste("Generated frequency table: A8_r5"))

# -----------------------------------------------------------------------------
# Table: a9 (frequency)
# Title: A9 - Issues encountered (distribution by response value) for each product
# Rows: 12
# -----------------------------------------------------------------------------

table_a9 <- list(
  tableId = "a9",
  title = "A9 - Issues encountered (distribution by response value) for each product",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9$data[[cut_name]] <- list()

  # Row 1: A9c1 == "1"
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Repatha - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Repatha - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c1 not found"
    )
  }

  # Row 2: A9c1 == "2"
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Repatha - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Repatha - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c1 not found"
    )
  }

  # Row 3: A9c1 == "3"
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Repatha - Value 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Repatha - Value 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c1 not found"
    )
  }

  # Row 4: A9c1 == "4"
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Repatha - Value 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Repatha - Value 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c1 not found"
    )
  }

  # Row 5: A9c2 == "1"
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "Praluent - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "Praluent - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c2 not found"
    )
  }

  # Row 6: A9c2 == "2"
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Praluent - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Praluent - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c2 not found"
    )
  }

  # Row 7: A9c2 == "3"
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "Praluent - Value 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "Praluent - Value 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c2 not found"
    )
  }

  # Row 8: A9c2 == "4"
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Praluent - Value 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Praluent - Value 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c2 not found"
    )
  }

  # Row 9: A9c3 == "1"
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_9"]] <- list(
      label = "Leqvio - Value 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_9"]] <- list(
      label = "Leqvio - Value 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c3 not found"
    )
  }

  # Row 10: A9c3 == "2"
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_10"]] <- list(
      label = "Leqvio - Value 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_10"]] <- list(
      label = "Leqvio - Value 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c3 not found"
    )
  }

  # Row 11: A9c3 == "3"
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Leqvio - Value 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Leqvio - Value 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c3 not found"
    )
  }

  # Row 12: A9c3 == "4"
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "Leqvio - Value 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "Leqvio - Value 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A9c3 not found"
    )
  }

}

all_tables[["a9"]] <- table_a9
print(paste("Generated frequency table: a9"))

# -----------------------------------------------------------------------------
# Table: a10 (frequency)
# Title: A10 - Reasons for using PCSK9 inhibitors without a statin (multi-select)
# Rows: 6
# -----------------------------------------------------------------------------

table_a10 <- list(
  tableId = "a10",
  title = "A10 - Reasons for using PCSK9 inhibitors without a statin (multi-select)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a10$data[[cut_name]] <- list()

  # Row 1: A10r1 == "1"
  var_col <- safe_get_var(cut_data, "A10r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r1_row_1"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r1_row_1"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r1 not found"
    )
  }

  # Row 2: A10r2 == "1"
  var_col <- safe_get_var(cut_data, "A10r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r2_row_2"]] <- list(
      label = "Patient is statin intolerant",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r2_row_2"]] <- list(
      label = "Patient is statin intolerant",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r2 not found"
    )
  }

  # Row 3: A10r3 == "1"
  var_col <- safe_get_var(cut_data, "A10r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r3_row_3"]] <- list(
      label = "Patient refused statins",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r3_row_3"]] <- list(
      label = "Patient refused statins",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r3 not found"
    )
  }

  # Row 4: A10r4 == "1"
  var_col <- safe_get_var(cut_data, "A10r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r4_row_4"]] <- list(
      label = "Statins are contraindicated for patient",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r4_row_4"]] <- list(
      label = "Statins are contraindicated for patient",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r4 not found"
    )
  }

  # Row 5: A10r5 == "1"
  var_col <- safe_get_var(cut_data, "A10r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r5_row_5"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r5_row_5"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r5 not found"
    )
  }

  # Row 6: A10r6 == "1"
  var_col <- safe_get_var(cut_data, "A10r6")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r6_row_6"]] <- list(
      label = "Haven’t prescribed PCSK9s without a statin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a10$data[[cut_name]][["A10r6_row_6"]] <- list(
      label = "Haven’t prescribed PCSK9s without a statin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A10r6 not found"
    )
  }

}

all_tables[["a10"]] <- table_a10
print(paste("Generated frequency table: a10"))

# -----------------------------------------------------------------------------
# Table: b1_mean_rows (mean_rows)
# Title: B1 - Percentage covered by each insurance type
# Rows: 8
# -----------------------------------------------------------------------------

table_b1_mean_rows <- list(
  tableId = "b1_mean_rows",
  title = "B1 - Percentage covered by each insurance type",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b1_mean_rows$data[[cut_name]] <- list()

  # Row 1: B1r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r1 not found"
    )
  }

  # Row 2: B1r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 3: B1r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 4: B1r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 5: B1r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 6: B1r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 7: B1r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r7 not found"
    )
  }

  # Row 8: B1r8 (numeric summary)
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b1_mean_rows$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b1_mean_rows$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B1r8 not found"
    )
  }

}

all_tables[["b1_mean_rows"]] <- table_b1_mean_rows
print(paste("Generated mean_rows table: b1_mean_rows"))

# -----------------------------------------------------------------------------
# Table: B5_multi (frequency)
# Title: B5 - Specialty/Training (selected = 1)
# Rows: 5
# -----------------------------------------------------------------------------

table_B5_multi <- list(
  tableId = "B5_multi",
  title = "B5 - Specialty/Training (selected = 1)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_B5_multi$data[[cut_name]] <- list()

  # Row 1: B5r1 == "1"
  var_col <- safe_get_var(cut_data, "B5r1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_B5_multi$data[[cut_name]][["B5r1_row_1"]] <- list(
      label = "Internal Medicine",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_B5_multi$data[[cut_name]][["B5r1_row_1"]] <- list(
      label = "Internal Medicine",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B5r1 not found"
    )
  }

  # Row 2: B5r2 == "1"
  var_col <- safe_get_var(cut_data, "B5r2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_B5_multi$data[[cut_name]][["B5r2_row_2"]] <- list(
      label = "General Practitioner",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_B5_multi$data[[cut_name]][["B5r2_row_2"]] <- list(
      label = "General Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B5r2 not found"
    )
  }

  # Row 3: B5r3 == "1"
  var_col <- safe_get_var(cut_data, "B5r3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_B5_multi$data[[cut_name]][["B5r3_row_3"]] <- list(
      label = "Primary Care",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_B5_multi$data[[cut_name]][["B5r3_row_3"]] <- list(
      label = "Primary Care",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B5r3 not found"
    )
  }

  # Row 4: B5r4 == "1"
  var_col <- safe_get_var(cut_data, "B5r4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_B5_multi$data[[cut_name]][["B5r4_row_4"]] <- list(
      label = "Family Practice",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_B5_multi$data[[cut_name]][["B5r4_row_4"]] <- list(
      label = "Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B5r4 not found"
    )
  }

  # Row 5: B5r5 == "1"
  var_col <- safe_get_var(cut_data, "B5r5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_B5_multi$data[[cut_name]][["B5r5_row_5"]] <- list(
      label = "Doctor of Osteopathic Medicine (DO)",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_B5_multi$data[[cut_name]][["B5r5_row_5"]] <- list(
      label = "Doctor of Osteopathic Medicine (DO)",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B5r5 not found"
    )
  }

}

all_tables[["B5_multi"]] <- table_B5_multi
print(paste("Generated frequency table: B5_multi"))

# -----------------------------------------------------------------------------
# Table: s1 (frequency)
# Title: S1 - Consent to proceed / report adverse events
# Rows: 3
# -----------------------------------------------------------------------------

table_s1 <- list(
  tableId = "s1",
  title = "S1 - Consent to proceed / report adverse events",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s1$data[[cut_name]] <- list()

  # Row 1: S1 == "1"
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S1 not found"
    )
  }

  # Row 2: S1 == "2"
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S1 not found"
    )
  }

  # Row 3: S1 == "3"
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I don�t want to proceed",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I don�t want to proceed",
      n = 0,
      count = 0,
      pct = 0,
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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2b$data[[cut_name]] <- list()

  # Row 1: S2b == "1"
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Physician",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Physician",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2b not found"
    )
  }

  # Row 2: S2b == "2"
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2b not found"
    )
  }

  # Row 3: S2b == "3"
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Physician’s Assistant",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Physician’s Assistant",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2b not found"
    )
  }

  # Row 4: S2b == "99"
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "99", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2b not found"
    )
  }

}

all_tables[["s2b"]] <- table_s2b
print(paste("Generated frequency table: s2b"))

# -----------------------------------------------------------------------------
# Table: s2 (frequency)
# Title: S2 - What is your primary specialty?
# Rows: 8
# -----------------------------------------------------------------------------

table_s2 <- list(
  tableId = "s2",
  title = "S2 - What is your primary specialty?",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2$data[[cut_name]] <- list()

  # Row 1: S2 == "1"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 2: S2 == "2"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 3: S2 == "3"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_3"]] <- list(
      label = "Nephrologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_3"]] <- list(
      label = "Nephrologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 4: S2 == "4"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_4"]] <- list(
      label = "Endocrinologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_4"]] <- list(
      label = "Endocrinologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 5: S2 == "5"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_5"]] <- list(
      label = "Lipidologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_5"]] <- list(
      label = "Lipidologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 6: S2 == "6"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "6", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_6"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_6"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 7: S2 == "7"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "7", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Physician�s Assistant",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Physician�s Assistant",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

  # Row 8: S2 == "99"
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "99", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2 not found"
    )
  }

}

all_tables[["s2"]] <- table_s2
print(paste("Generated frequency table: s2"))

# -----------------------------------------------------------------------------
# Table: s2a (frequency)
# Title: S2a - In what type of doctor's office do you work?
# Rows: 3
# -----------------------------------------------------------------------------

table_s2a <- list(
  tableId = "s2a",
  title = "S2a - In what type of doctor's office do you work?",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2a$data[[cut_name]] <- list()

  # Row 1: S2a == "1"
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2a not found"
    )
  }

  # Row 2: S2a == "2"
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2a not found"
    )
  }

  # Row 3: S2a == "3"
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_3"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_3"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S2a not found"
    )
  }

}

all_tables[["s2a"]] <- table_s2a
print(paste("Generated frequency table: s2a"))

# -----------------------------------------------------------------------------
# Table: qCARD_SPECIALTY (frequency)
# Title: CARD SPECIALTY - Distribution
# Rows: 2
# -----------------------------------------------------------------------------

table_qCARD_SPECIALTY <- list(
  tableId = "qCARD_SPECIALTY",
  title = "CARD SPECIALTY - Distribution",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qCARD_SPECIALTY$data[[cut_name]] <- list()

  # Row 1: qCARD_SPECIALTY == "1"
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "CARD",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "CARD",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

  # Row 2: qCARD_SPECIALTY == "2"
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "NEPH/ENDO/LIP",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qCARD_SPECIALTY$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "NEPH/ENDO/LIP",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

}

all_tables[["qCARD_SPECIALTY"]] <- table_qCARD_SPECIALTY
print(paste("Generated frequency table: qCARD_SPECIALTY"))

# -----------------------------------------------------------------------------
# Table: qSPECIALTY (frequency)
# Title: qSPECIALTY - SPECIALTY distribution
# Rows: 3
# -----------------------------------------------------------------------------

table_qSPECIALTY <- list(
  tableId = "qSPECIALTY",
  title = "qSPECIALTY - SPECIALTY distribution",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qSPECIALTY$data[[cut_name]] <- list()

  # Row 1: qSPECIALTY == "1"
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "CARD",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "CARD",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 2: qSPECIALTY == "2"
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "PCP",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "PCP",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 3: qSPECIALTY == "3"
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "NPPA",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qSPECIALTY$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "NPPA",
      n = 0,
      count = 0,
      pct = 0,
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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s3a$data[[cut_name]] <- list()

  # Row 1: S3a == "1"
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S3a not found"
    )
  }

  # Row 2: S3a == "2"
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "General Cardiologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "General Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S3a not found"
    )
  }

  # Row 3: S3a == "3"
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S3a not found"
    )
  }

}

all_tables[["s3a"]] <- table_s3a
print(paste("Generated frequency table: s3a"))

# -----------------------------------------------------------------------------
# Table: qTYPE_OF_CARD (frequency)
# Title: qTYPE_OF_CARD - TYPE OF CARD
# Rows: 3
# -----------------------------------------------------------------------------

table_qTYPE_OF_CARD <- list(
  tableId = "qTYPE_OF_CARD",
  title = "qTYPE_OF_CARD - TYPE OF CARD",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qTYPE_OF_CARD$data[[cut_name]] <- list()

  # Row 1: qTYPE_OF_CARD == "1"
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Card",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Card",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 2: qTYPE_OF_CARD == "2"
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Card",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Card",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 3: qTYPE_OF_CARD == "3"
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Card",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qTYPE_OF_CARD$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Card",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

}

all_tables[["qTYPE_OF_CARD"]] <- table_qTYPE_OF_CARD
print(paste("Generated frequency table: qTYPE_OF_CARD"))

# -----------------------------------------------------------------------------
# Table: qON_LIST_OFF_LIST (frequency)
# Title: ON-LIST/OFF-LIST - Distribution
# Rows: 6
# -----------------------------------------------------------------------------

table_qON_LIST_OFF_LIST <- list(
  tableId = "qON_LIST_OFF_LIST",
  title = "ON-LIST/OFF-LIST - Distribution",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qON_LIST_OFF_LIST$data[[cut_name]] <- list()

  # Row 1: qON_LIST_OFF_LIST == "1"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "CARD ON-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "CARD ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 2: qON_LIST_OFF_LIST == "2"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "CARD OFF-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "CARD OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 3: qON_LIST_OFF_LIST == "3"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP ON-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 4: qON_LIST_OFF_LIST == "4"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP OFF-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 5: qON_LIST_OFF_LIST == "5"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NPPA ON-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NPPA ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 6: qON_LIST_OFF_LIST == "6"
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "6", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NPPA OFF-LIST",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qON_LIST_OFF_LIST$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NPPA OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qLIST_TIER$data[[cut_name]] <- list()

  # Row 1: qLIST_TIER == "1"
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 2: qLIST_TIER == "2"
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 3: qLIST_TIER == "3"
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 4: qLIST_TIER == "4"
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_TIER$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_TIER not found"
    )
  }

}

all_tables[["qLIST_TIER"]] <- table_qLIST_TIER
print(paste("Generated frequency table: qLIST_TIER"))

# -----------------------------------------------------------------------------
# Table: qLIST_PRIORITY_ACCOUNT (frequency)
# Title: qLIST_PRIORITY_ACCOUNT - LIST PRIORITY ACCOUNT
# Rows: 2
# -----------------------------------------------------------------------------

table_qLIST_PRIORITY_ACCOUNT <- list(
  tableId = "qLIST_PRIORITY_ACCOUNT",
  title = "qLIST_PRIORITY_ACCOUNT - LIST PRIORITY ACCOUNT",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]] <- list()

  # Row 1: qLIST_PRIORITY_ACCOUNT == "1"
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "PRIORITY",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "PRIORITY",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

  # Row 2: qLIST_PRIORITY_ACCOUNT == "2"
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "NOT PRIORITY",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qLIST_PRIORITY_ACCOUNT$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "NOT PRIORITY",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

}

all_tables[["qLIST_PRIORITY_ACCOUNT"]] <- table_qLIST_PRIORITY_ACCOUNT
print(paste("Generated frequency table: qLIST_PRIORITY_ACCOUNT"))

# -----------------------------------------------------------------------------
# Table: s4 (frequency)
# Title: S4 - Are you currently board certified or eligible in your specialty?
# Rows: 3
# -----------------------------------------------------------------------------

table_s4 <- list(
  tableId = "s4",
  title = "S4 - Are you currently board certified or eligible in your specialty?",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s4$data[[cut_name]] <- list()

  # Row 1: S4 == "1"
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board Eligible",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board Eligible",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S4 not found"
    )
  }

  # Row 2: S4 == "2"
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Certified",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Certified",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S4 not found"
    )
  }

  # Row 3: S4 == "3"
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Neither",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Neither",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S4 not found"
    )
  }

}

all_tables[["s4"]] <- table_s4
print(paste("Generated frequency table: s4"))

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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6_years_in_practice$data[[cut_name]] <- list()

  # Row 1: S6 (numeric summary)
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s6_years_in_practice$data[[cut_name]][["S6"]] <- list(
      label = "Years in clinical practice (post residency/training)",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s6_years_in_practice$data[[cut_name]][["S6"]] <- list(
      label = "Years in clinical practice (post residency/training)",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S6 not found"
    )
  }

}

all_tables[["s6_years_in_practice"]] <- table_s6_years_in_practice
print(paste("Generated mean_rows table: s6_years_in_practice"))

# -----------------------------------------------------------------------------
# Table: s7 (frequency)
# Title: S7 - Current practice: Full-Time or Part-Time
# Rows: 2
# -----------------------------------------------------------------------------

table_s7 <- list(
  tableId = "s7",
  title = "S7 - Current practice: Full-Time or Part-Time",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s7$data[[cut_name]] <- list()

  # Row 1: S7 == "1"
  var_col <- safe_get_var(cut_data, "S7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7_row_1"]] <- list(
      label = "Full-Time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s7$data[[cut_name]][["S7_row_1"]] <- list(
      label = "Full-Time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S7 not found"
    )
  }

  # Row 2: S7 == "2"
  var_col <- safe_get_var(cut_data, "S7")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7_row_2"]] <- list(
      label = "Part-Time",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s7$data[[cut_name]][["S7_row_2"]] <- list(
      label = "Part-Time",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S7 not found"
    )
  }

}

all_tables[["s7"]] <- table_s7
print(paste("Generated frequency table: s7"))

# -----------------------------------------------------------------------------
# Table: s9 (frequency)
# Title: S9 - Setting where you spend most professional time
# Rows: 8
# -----------------------------------------------------------------------------

table_s9 <- list(
  tableId = "s9",
  title = "S9 - Setting where you spend most professional time",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s9$data[[cut_name]] <- list()

  # Row 1: S9 == "1"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private Solo Practice",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private Solo Practice",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 2: S9 == "2"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Group Practice",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Group Practice",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 3: S9 == "3"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 4: S9 == "4"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Staff HMO",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Staff HMO",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 5: S9 == "5"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Community Hospital",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Community Hospital",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 6: S9 == "6"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "6", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Academic/University Hospital",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Academic/University Hospital",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 7: S9 == "7"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "7", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "VA Hospital",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "VA Hospital",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

  # Row 8: S9 == "8"
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "8", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "None of the above",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable S9 not found"
    )
  }

}

all_tables[["s9"]] <- table_s9
print(paste("Generated frequency table: s9"))

# -----------------------------------------------------------------------------
# Table: s10 (mean_rows)
# Title: S10 - Number of adult patients personally managed per month
# Rows: 1
# -----------------------------------------------------------------------------

table_s10 <- list(
  tableId = "s10",
  title = "S10 - Number of adult patients personally managed per month",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10$data[[cut_name]] <- list()

  # Row 1: S10 (numeric summary)
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s10$data[[cut_name]][["S10"]] <- list(
      label = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By �personally�, we mean patients for whom you are a primary treatment decision maker.",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s10$data[[cut_name]][["S10"]] <- list(
      label = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By �personally�, we mean patients for whom you are a primary treatment decision maker.",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S10 not found"
    )
  }

}

all_tables[["s10"]] <- table_s10
print(paste("Generated mean_rows table: s10"))

# -----------------------------------------------------------------------------
# Table: s11_mean (mean_rows)
# Title: S11 - Number of adult patients with hypercholesterolemia and CVD
# Rows: 1
# -----------------------------------------------------------------------------

table_s11_mean <- list(
  tableId = "s11_mean",
  title = "S11 - Number of adult patients with hypercholesterolemia and CVD",
  tableType = "mean_rows",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11_mean$data[[cut_name]] <- list()

  # Row 1: S11 (numeric summary)
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_s11_mean$data[[cut_name]][["S11"]] <- list(
      label = "Number of adult patients with hypercholesterolemia and CVD",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_s11_mean$data[[cut_name]][["S11"]] <- list(
      label = "Number of adult patients with hypercholesterolemia and CVD",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable S11 not found"
    )
  }

}

all_tables[["s11_mean"]] <- table_s11_mean
print(paste("Generated mean_rows table: s11_mean"))

# -----------------------------------------------------------------------------
# Table: A2a (frequency)
# Title: A2a - Post-ACS guideline recommendation regarding lipid-lowering
# Rows: 3
# -----------------------------------------------------------------------------

table_A2a <- list(
  tableId = "A2a",
  title = "A2a - Post-ACS guideline recommendation regarding lipid-lowering",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_A2a$data[[cut_name]] <- list()

  # Row 1: A2a == "1"
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A2a$data[[cut_name]][["A2a_row_1"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 5 mg/dL",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A2a$data[[cut_name]][["A2a_row_1"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 5 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2a not found"
    )
  }

  # Row 2: A2a == "2"
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A2a$data[[cut_name]][["A2a_row_2"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 70 mg/dL",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A2a$data[[cut_name]][["A2a_row_2"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 70 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2a not found"
    )
  }

  # Row 3: A2a == "3"
  var_col <- safe_get_var(cut_data, "A2a")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_A2a$data[[cut_name]][["A2a_row_3"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 100 mg/dL",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_A2a$data[[cut_name]][["A2a_row_3"]] <- list(
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 100 mg/dL",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2a not found"
    )
  }

}

all_tables[["A2a"]] <- table_A2a
print(paste("Generated frequency table: A2a"))

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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a2b$data[[cut_name]] <- list()

  # Row 1: A2b == "1"
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend a statin first",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend a statin first",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2b not found"
    )
  }

  # Row 2: A2b == "2"
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2b not found"
    )
  }

  # Row 3: A2b == "3"
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a PCSK9i first",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a PCSK9i first",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A2b not found"
    )
  }

}

all_tables[["a2b"]] <- table_a2b
print(paste("Generated frequency table: a2b"))

# -----------------------------------------------------------------------------
# Table: a5 (frequency)
# Title: A5 - How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?
# Rows: 4
# -----------------------------------------------------------------------------

table_a5 <- list(
  tableId = "a5",
  title = "A5 - How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a5$data[[cut_name]] <- list()

  # Row 1: A5 == "1"
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 3 months",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 3 months",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A5 not found"
    )
  }

  # Row 2: A5 == "2"
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "4-6 months",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "4-6 months",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A5 not found"
    )
  }

  # Row 3: A5 == "3"
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "7-12 months",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "7-12 months",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A5 not found"
    )
  }

  # Row 4: A5 == "4"
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "Over a year",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "Over a year",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable A5 not found"
    )
  }

}

all_tables[["a5"]] <- table_a5
print(paste("Generated frequency table: a5"))

# -----------------------------------------------------------------------------
# Table: us_state_1 (frequency)
# Title: US_State (part 1 of 3)
# Rows: 20
# -----------------------------------------------------------------------------

table_us_state_1 <- list(
  tableId = "us_state_1",
  title = "US_State (part 1 of 3)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_us_state_1$data[[cut_name]] <- list()

  # Row 1: US_State == "1"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State == "2"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State == "3"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State == "4"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == "5"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 6: US_State == "6"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "6", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 7: US_State == "7"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "7", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 8: US_State == "8"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "8", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 9: US_State == "9"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "9", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 10: US_State == "10"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "10", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 11: US_State == "11"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "11", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 12: US_State == "12"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "12", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 13: US_State == "13"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "13", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 14: US_State == "14"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "14", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 15: US_State == "15"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "15", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 16: US_State == "16"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "16", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 17: US_State == "17"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "17", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 18: US_State == "18"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "18", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 19: US_State == "19"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "19", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 20: US_State == "20"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "20", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_1$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_1$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

}

all_tables[["us_state_1"]] <- table_us_state_1
print(paste("Generated frequency table: us_state_1"))

# -----------------------------------------------------------------------------
# Table: us_state_2 (frequency)
# Title: US_State (part 2 of 3)
# Rows: 20
# -----------------------------------------------------------------------------

table_us_state_2 <- list(
  tableId = "us_state_2",
  title = "US_State (part 2 of 3)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_us_state_2$data[[cut_name]] <- list()

  # Row 1: US_State == "21"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "21", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Maryland",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Maryland",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State == "22"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "22", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Maine",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Maine",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State == "23"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "23", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Michigan",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Michigan",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State == "24"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "24", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Minnesota",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Minnesota",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == "25"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "25", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "Missouri",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "Missouri",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 6: US_State == "26"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "26", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Mississippi",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Mississippi",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 7: US_State == "27"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "27", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Montana",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Montana",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 8: US_State == "28"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "28", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "North Carolina",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "North Carolina",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 9: US_State == "29"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "29", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "North Dakota",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "North Dakota",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 10: US_State == "30"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "30", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Nebraska",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Nebraska",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 11: US_State == "31"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "31", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "New Hampshire",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "New Hampshire",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 12: US_State == "32"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "32", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "New Jersey",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "New Jersey",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 13: US_State == "33"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "33", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "New Mexico",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "New Mexico",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 14: US_State == "34"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "34", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Nevada",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Nevada",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 15: US_State == "35"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "35", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "New York",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "New York",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 16: US_State == "36"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "36", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Ohio",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Ohio",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 17: US_State == "37"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "37", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Oklahoma",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Oklahoma",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 18: US_State == "38"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "38", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Oregon",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Oregon",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 19: US_State == "39"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "39", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Pennsylvania",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Pennsylvania",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 20: US_State == "40"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "40", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_2$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Rhode Island",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_2$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Rhode Island",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

}

all_tables[["us_state_2"]] <- table_us_state_2
print(paste("Generated frequency table: us_state_2"))

# -----------------------------------------------------------------------------
# Table: us_state_3 (frequency)
# Title: US_State (part 3 of 3)
# Rows: 13
# -----------------------------------------------------------------------------

table_us_state_3 <- list(
  tableId = "us_state_3",
  title = "US_State (part 3 of 3)",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_us_state_3$data[[cut_name]] <- list()

  # Row 1: US_State == "41"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "41", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "South Carolina",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "South Carolina",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State == "42"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "42", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "South Dakota",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "South Dakota",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State == "43"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "43", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Tennessee",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Tennessee",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State == "44"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "44", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Texas",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Texas",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == "45"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "45", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "Utah",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "Utah",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 6: US_State == "46"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "46", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Virginia",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Virginia",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 7: US_State == "47"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "47", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Vermont",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Vermont",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 8: US_State == "48"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "48", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "Washington",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "Washington",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 9: US_State == "49"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "49", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Wisconsin",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Wisconsin",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 10: US_State == "50"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "50", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "West Virginia",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "West Virginia",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 11: US_State == "51"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "51", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Wyoming",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Wyoming",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 12: US_State == "52"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "52", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

  # Row 13: US_State == "53"
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "53", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_3$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Invalid State",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_us_state_3$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Invalid State",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable US_State not found"
    )
  }

}

all_tables[["us_state_3"]] <- table_us_state_3
print(paste("Generated frequency table: us_state_3"))

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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_region$data[[cut_name]] <- list()

  # Row 1: Region == "1"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "Northeast",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "Northeast",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

  # Row 2: Region == "2"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "South",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "South",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

  # Row 3: Region == "3"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "Midwest",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "Midwest",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

  # Row 4: Region == "4"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "4", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "West",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "West",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

  # Row 5: Region == "5"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "5", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

  # Row 6: Region == "6"
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "6", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Invalid Region",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Invalid Region",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable Region not found"
    )
  }

}

all_tables[["region"]] <- table_region
print(paste("Generated frequency table: region"))

# -----------------------------------------------------------------------------
# Table: b3 (frequency)
# Title: B3 - Primary practice location
# Rows: 3
# -----------------------------------------------------------------------------

table_b3 <- list(
  tableId = "b3",
  title = "B3 - Primary practice location",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b3$data[[cut_name]] <- list()

  # Row 1: B3 == "1"
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B3 not found"
    )
  }

  # Row 2: B3 == "2"
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Suburban",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Suburban",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable B3 not found"
    )
  }

  # Row 3: B3 == "3"
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "3", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Rural",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Rural",
      n = 0,
      count = 0,
      pct = 0,
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
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b4$data[[cut_name]] <- list()

  # Row 1: B4 (numeric summary)
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA

    table_b4$data[[cut_name]][["B4"]] <- list(
      label = "How many physicians are in your practice?",
      n = n,
      mean = mean_val,
      median = median_val,
      sd = sd_val
    )
  } else {
    table_b4$data[[cut_name]][["B4"]] <- list(
      label = "How many physicians are in your practice?",
      n = 0,
      mean = NA,
      median = NA,
      sd = NA,
      error = "Variable B4 not found"
    )
  }

}

all_tables[["b4"]] <- table_b4
print(paste("Generated mean_rows table: b4"))

# -----------------------------------------------------------------------------
# Table: qconsent (frequency)
# Title: QCONSENT - Willingness to participate in future research
# Rows: 2
# -----------------------------------------------------------------------------

table_qconsent <- list(
  tableId = "qconsent",
  title = "QCONSENT - Willingness to participate in future research",
  tableType = "frequency",
  hints = c(),
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qconsent$data[[cut_name]] <- list()

  # Row 1: QCONSENT == "1"
  var_col <- safe_get_var(cut_data, "QCONSENT")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "1", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qconsent$data[[cut_name]][["QCONSENT_row_1"]] <- list(
      label = "Yes",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qconsent$data[[cut_name]][["QCONSENT_row_1"]] <- list(
      label = "Yes",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable QCONSENT not found"
    )
  }

  # Row 2: QCONSENT == "2"
  var_col <- safe_get_var(cut_data, "QCONSENT")
  if (!is.null(var_col)) {
    # CRITICAL: Base = respondents who answered this question (non-NA)
    base_n <- sum(!is.na(var_col))
    count <- sum(var_col == "2", na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qconsent$data[[cut_name]][["QCONSENT_row_2"]] <- list(
      label = "No",
      n = base_n,
      count = count,
      pct = pct
    )
  } else {
    table_qconsent$data[[cut_name]][["QCONSENT_row_2"]] <- list(
      label = "No",
      n = 0,
      count = 0,
      pct = 0,
      error = "Variable QCONSENT not found"
    )
  }

}

all_tables[["qconsent"]] <- table_qconsent
print(paste("Generated frequency table: qconsent"))

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
    generatedAt = "2026-01-04T05:30:47.696Z",
    tableCount = 51,
    cutCount = 9
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
print(paste("  Output:", output_path))
print(paste(rep("=", 60), collapse = ""))