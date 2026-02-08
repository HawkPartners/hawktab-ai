# HawkTab AI - R Script V2
# Session: pipeline-2026-02-08T06-21-32-461Z
# Generated: 2026-02-08T06:42:08.961Z
# Tables: 79 (0 skipped due to validation errors)
# Cuts: 18
#
# STATISTICAL TESTING:
#   Threshold: p<0.1 (90% confidence)
#   Proportion test: Unpooled z-test
#   Mean test: Welch's t-test
#   Minimum base: None (testing all cells)
#   Comparisons: Within-group + vs Total

# Load required libraries
library(haven)
library(dplyr)
library(jsonlite)

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

# =============================================================================
# Statistical Testing Configuration
# =============================================================================

# Significance thresholds
p_threshold <- 0.1

# Minimum base size for significance testing (0 = no minimum)
stat_min_base <- 0

# Test methodology
# Proportion test: Unpooled z-test (WinCross default)
# Mean test: Welch's t-test (unequal variances)

# =============================================================================
# Cuts Definition (banner columns) with stat testing metadata
# =============================================================================

# Cut masks
cuts <- list(
  Total = rep(TRUE, nrow(data))
,  `Total` = with(data, rep(TRUE, nrow(data)))
,  `Cards` = with(data, (S2 == 1 | S2a == 1))
,  `PCPs` = with(data, S2 == 2)
,  `Other` = with(data, S2 %in% c(3,4,5))
,  `Physician` = with(data, S2 %in% c(1,2,3,4,5))
,  `APP` = with(data, S2b %in% c(2,3))
,  `150+ (Higher)` = with(data, S11 >= 150)
,  `20-149 (Lower)` = with(data, (S11 >= 20 & S11 <= 149))
,  `Tier 1` = with(data, qLIST_TIER == 1)
,  `Tier 2` = with(data, qLIST_TIER == 2)
,  `Tier 3` = with(data, qLIST_TIER == 3)
,  `Tier 4` = with(data, qLIST_TIER == 4)
,  `Yes` = with(data, (A3ar1c2 > 0 & A3br1c1 > 0))
,  `No` = with(data, !(A3ar1c2 > 0 & A3br1c1 > 0))
,  `All Leqvio Prescribing` = with(data, A4r2c2 > A4r2c1)
,  `Leqvio Rx'ing without a Statin & Before Other Therapies` = with(data, (A3ar1c2 > 0 & A4ar1c2 > 0 & A4br1c1 > A3br1c1))
,  `Academic / Univ. Hospital` = with(data, S9 == 6)
,  `Total Community` = with(data, S9 %in% c(1,2,3,4,5))
)

# Stat letter mapping (for significance testing output)
cut_stat_letters <- c(
  "Total" = "T"
,  "Total" = "T"
,  "Cards" = "A"
,  "PCPs" = "B"
,  "Other" = "C"
,  "Physician" = "D"
,  "APP" = "E"
,  "150+ (Higher)" = "F"
,  "20-149 (Lower)" = "G"
,  "Tier 1" = "H"
,  "Tier 2" = "I"
,  "Tier 3" = "J"
,  "Tier 4" = "K"
,  "Yes" = "L"
,  "No" = "M"
,  "All Leqvio Prescribing" = "N"
,  "Leqvio Rx'ing without a Statin & Before Other Therapies" = "O"
,  "Academic / Univ. Hospital" = "P"
,  "Total Community" = "Q"
)

# Group membership (for within-group comparisons)
cut_groups <- list(
  "Total" = c("Total"),
  "HCP Specialty" = c("Cards", "PCPs", "Other"),
  "HCP Role" = c("Physician", "APP"),
  "Volume of ASCVD Patients" = c("150+ (Higher)", "20-149 (Lower)"),
  "Tiers" = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"),
  "Currently Prescribe Leqvio without a Statin and Before Other Therapies" = c("Yes", "No"),
  "Leqvio Rx'ing Would Increase with New PCSK9s Indication" = c("All Leqvio Prescribing", "Leqvio Rx'ing without a Statin & Before Other Therapies"),
  "Primary Practice Setting" = c("Academic / Univ. Hospital", "Total Community")
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

# Z-test for proportions (unpooled formula - WinCross default)
# No minimum sample size - WinCross tests all data
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  # Calculate proportions
  p1 <- count1 / n1
  p2 <- count2 / n2

  # Edge case: can't test if either proportion is undefined
  if (is.na(p1) || is.na(p2)) return(NA)

  # Edge case: can't test if both are 0% or both are 100%
  if ((p1 == 0 && p2 == 0) || (p1 == 1 && p2 == 1)) return(NA)

  # Standard error (unpooled formula)
  se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  if (is.na(se) || se == 0) return(NA)

  # Z statistic
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}

# Welch's t-test for means using summary statistics (n, mean, sd)
# Returns list(p_value, higher) or NA if cannot compute
sig_test_mean_summary <- function(n1, mean1, sd1, n2, mean2, sd2, min_base = 0) {
  # Check minimum base size
  if (!is.na(min_base) && min_base > 0) {
    if (n1 < min_base || n2 < min_base) return(NA)
  }

  # Need at least 2 observations for SD and variance
  if (is.na(n1) || is.na(n2) || n1 < 2 || n2 < 2) return(NA)
  if (is.na(mean1) || is.na(mean2)) return(NA)
  if (is.na(sd1) || is.na(sd2)) return(NA)

  # Handle zero variance (SD = 0)
  if (sd1 == 0 && sd2 == 0) {
    # Both have no variance - cannot compute t-test
    # If means are exactly equal, not significant
    # If means differ, technically infinite t-stat but we return NA
    return(NA)
  }

  # Welch's t-test formula
  var1 <- sd1^2
  var2 <- sd2^2

  # Standard error of the difference
  se <- sqrt(var1/n1 + var2/n2)
  if (se == 0) return(NA)  # Cannot divide by zero

  # t statistic
  t_stat <- (mean1 - mean2) / se

  # Welch-Satterthwaite degrees of freedom
  df_num <- (var1/n1 + var2/n2)^2
  df_denom <- (var1/n1)^2/(n1-1) + (var2/n2)^2/(n2-1)
  df <- df_num / df_denom

  # Two-tailed p-value
  p_value <- 2 * pt(-abs(t_stat), df)

  return(list(p_value = p_value, higher = mean1 > mean2))
}

# T-test for means using raw data (legacy, for backward compatibility)
sig_test_mean <- function(vals1, vals2, threshold = p_threshold) {
  n1 <- sum(!is.na(vals1))
  n2 <- sum(!is.na(vals2))

  if (n1 < 2 || n2 < 2) return(NA)  # Insufficient sample size

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

# -----------------------------------------------------------------------------
# Demo Table: Banner Profile (respondent distribution across cuts)
# -----------------------------------------------------------------------------

table__demo_banner_x_banner <- list(
  tableId = "_demo_banner_x_banner",
  questionId = "",
  questionText = "Banner Profile",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "DEMO",
  baseText = "All qualified respondents",
  userNote = "Auto-generated banner profile showing respondent distribution",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table__demo_banner_x_banner$data[[cut_name]] <- list()
  table__demo_banner_x_banner$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row: Total
  total_count <- nrow(cut_data)
  base_n <- nrow(cut_data)
  pct <- if (base_n > 0) round_half_up(total_count / base_n * 100) else 0

  table__demo_banner_x_banner$data[[cut_name]][["row_0_Total"]] <- list(
    label = "Total",
    groupName = "Total",
    n = base_n,
    count = total_count,
    pct = pct,
    isNet = FALSE,
    indent = 0,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row: Total (Total)
  row_cut_mask <- cuts[["Total"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_1_T"]] <- list(
      label = "Total",
      groupName = "Total",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Cards (HCP Specialty)
  row_cut_mask <- cuts[["Cards"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_2_A"]] <- list(
      label = "Cards",
      groupName = "HCP Specialty",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: PCPs (HCP Specialty)
  row_cut_mask <- cuts[["PCPs"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_3_B"]] <- list(
      label = "PCPs",
      groupName = "HCP Specialty",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Other (HCP Specialty)
  row_cut_mask <- cuts[["Other"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_4_C"]] <- list(
      label = "Other",
      groupName = "HCP Specialty",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Physician (HCP Role)
  row_cut_mask <- cuts[["Physician"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_5_D"]] <- list(
      label = "Physician",
      groupName = "HCP Role",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: APP (HCP Role)
  row_cut_mask <- cuts[["APP"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_6_E"]] <- list(
      label = "APP",
      groupName = "HCP Role",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: 150+ (Higher) (Volume of ASCVD Patients)
  row_cut_mask <- cuts[["150+ (Higher)"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_7_F"]] <- list(
      label = "150+ (Higher)",
      groupName = "Volume of ASCVD Patients",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: 20-149 (Lower) (Volume of ASCVD Patients)
  row_cut_mask <- cuts[["20-149 (Lower)"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_8_G"]] <- list(
      label = "20-149 (Lower)",
      groupName = "Volume of ASCVD Patients",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Tier 1 (Tiers)
  row_cut_mask <- cuts[["Tier 1"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_9_H"]] <- list(
      label = "Tier 1",
      groupName = "Tiers",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Tier 2 (Tiers)
  row_cut_mask <- cuts[["Tier 2"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_10_I"]] <- list(
      label = "Tier 2",
      groupName = "Tiers",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Tier 3 (Tiers)
  row_cut_mask <- cuts[["Tier 3"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_11_J"]] <- list(
      label = "Tier 3",
      groupName = "Tiers",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Tier 4 (Tiers)
  row_cut_mask <- cuts[["Tier 4"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_12_K"]] <- list(
      label = "Tier 4",
      groupName = "Tiers",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Yes (Currently Prescribe Leqvio without a Statin and Before Other Therapies)
  row_cut_mask <- cuts[["Yes"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_13_L"]] <- list(
      label = "Yes",
      groupName = "Currently Prescribe Leqvio without a Statin and Before Other Therapies",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: No (Currently Prescribe Leqvio without a Statin and Before Other Therapies)
  row_cut_mask <- cuts[["No"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_14_M"]] <- list(
      label = "No",
      groupName = "Currently Prescribe Leqvio without a Statin and Before Other Therapies",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: All Leqvio Prescribing (Leqvio Rx'ing Would Increase with New PCSK9s Indication)
  row_cut_mask <- cuts[["All Leqvio Prescribing"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_15_N"]] <- list(
      label = "All Leqvio Prescribing",
      groupName = "Leqvio Rx'ing Would Increase with New PCSK9s Indication",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Leqvio Rx'ing without a Statin & Before Other Therapies (Leqvio Rx'ing Would Increase with New PCSK9s Indication)
  row_cut_mask <- cuts[["Leqvio Rx'ing without a Statin & Before Other Therapies"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_16_O"]] <- list(
      label = "Leqvio Rx'ing without a Statin & Before Other Therapies",
      groupName = "Leqvio Rx'ing Would Increase with New PCSK9s Indication",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Academic / Univ. Hospital (Primary Practice Setting)
  row_cut_mask <- cuts[["Academic / Univ. Hospital"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_17_P"]] <- list(
      label = "Academic / Univ. Hospital",
      groupName = "Primary Practice Setting",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Total Community (Primary Practice Setting)
  row_cut_mask <- cuts[["Total Community"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_18_Q"]] <- list(
      label = "Total Community",
      groupName = "Primary Practice Setting",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

}

all_tables[["_demo_banner_x_banner"]] <- table__demo_banner_x_banner
print("Generated demo table: _demo_banner_x_banner")

# -----------------------------------------------------------------------------
# Table: s2 (frequency)
# Question: What is your primary specialty/role?
# Rows: 10
# Source: s2
# -----------------------------------------------------------------------------

table_s2 <- list(
  tableId = "s2",
  questionId = "S2",
  questionText = "What is your primary specialty/role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s2",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2$data[[cut_name]] <- list()
  table_s2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2 IN (1, 2, 3, 4, 5)
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3, 4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Physicians (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_1"]] <- list(
      label = "Physicians (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_2"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_3"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_4"]] <- list(
      label = "Nephrologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_5"]] <- list(
      label = "Endocrinologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_6"]] <- list(
      label = "Lipidologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2 not found"
    )
  }

  # Row 7: S2 IN (6, 7)
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Advanced Practice Providers (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_7"]] <- list(
      label = "Advanced Practice Providers (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2 not found"
    )
  }

  # Row 8: S2 == 6
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_8"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2 not found"
    )
  }

  # Row 9: S2 == 7
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_9"]] <- list(
      label = "Physician’s Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_9"]] <- list(
      label = "Physician’s Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2 not found"
    )
  }

  # Row 10: S2 == 99
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2$data[[cut_name]][["S2_row_10"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2$data[[cut_name]][["S2_row_10"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2 not found"
    )
  }

}

all_tables[["s2"]] <- table_s2
print(paste("Generated frequency table: s2"))

# -----------------------------------------------------------------------------
# Table: s2a (frequency)
# Question: In what type of doctor's office do you work?
# Rows: 3
# Source: s2a
# -----------------------------------------------------------------------------

table_s2a <- list(
  tableId = "s2a",
  questionId = "S2a",
  questionText = "In what type of doctor's office do you work?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s2a",
  surveySection = "SCREENER",
  baseText = "Respondents who selected Nurse Practitioner (S2 = 6) or Physician’s Assistant (S2 = 7)",
  userNote = "(Asked only if respondent selected Nurse Practitioner or Physician's Assistant in the screener; selecting 'Internal Medicine / General Practitioner / Primary Care / Family Practice' or 'Other' leads to termination.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 %in% c(6, 7)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_s2a$data[[cut_name]] <- list()
  table_s2a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2a == 1
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2a not found"
    )
  }

  # Row 2: S2a == 2
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2a not found"
    )
  }

  # Row 3: S2a == 3
  var_col <- safe_get_var(cut_data, "S2a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2a$data[[cut_name]][["S2a_row_3"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2a$data[[cut_name]][["S2a_row_3"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2a not found"
    )
  }

}

all_tables[["s2a"]] <- table_s2a
print(paste("Generated frequency table: s2a"))

# -----------------------------------------------------------------------------
# Table: s2b (frequency) [DERIVED]
# Question: What is your primary role?
# Rows: 5
# Source: s2b
# -----------------------------------------------------------------------------

table_s2b <- list(
  tableId = "s2b",
  questionId = "S2b",
  questionText = "What is your primary role?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s2b",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2b$data[[cut_name]] <- list()
  table_s2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2b IN (1, 2, 3)
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Clinician (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_1"]] <- list(
      label = "Clinician (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2b not found"
    )
  }

  # Row 2: S2b == 1
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Physician",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_2"]] <- list(
      label = "Physician",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2b not found"
    )
  }

  # Row 3: S2b == 2
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Nurse Practitioner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Nurse Practitioner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2b not found"
    )
  }

  # Row 4: S2b == 3
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Physician’s Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_4"]] <- list(
      label = "Physician’s Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2b not found"
    )
  }

  # Row 5: S2b == 99
  var_col <- safe_get_var(cut_data, "S2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2b$data[[cut_name]][["S2b_row_5"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_5"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S2b not found"
    )
  }

}

all_tables[["s2b"]] <- table_s2b
print(paste("Generated frequency table: s2b"))

# -----------------------------------------------------------------------------
# Table: s3a (frequency)
# Question: What type of Cardiologist are you primarily?
# Rows: 3
# Source: s3a
# -----------------------------------------------------------------------------

table_s3a <- list(
  tableId = "s3a",
  questionId = "S3a",
  questionText = "What type of Cardiologist are you primarily?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s3a",
  surveySection = "SCREENER",
  baseText = "Respondents who selected 'Cardiologist' at S2",
  userNote = "(Asked only if respondent selected \"Cardiologist\" for primary specialty in S2.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
      error = "Variable S3a not found"
    )
  }

}

all_tables[["s3a"]] <- table_s3a
print(paste("Generated frequency table: s3a"))

# -----------------------------------------------------------------------------
# Table: s5 (frequency)
# Question: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?
# Rows: 8
# Source: s5
# -----------------------------------------------------------------------------

table_s5 <- list(
  tableId = "s5",
  questionId = "S5",
  questionText = "Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s5",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select all that apply. In this study, selecting any option 1–6 would have screened the respondent out.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s5$data[[cut_name]] <- list()
  table_s5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any affiliation (NET) (components: S5r1, S5r2, S5r3, S5r4, S5r5, S5r6)
  net_vars <- c("S5r1", "S5r2", "S5r3", "S5r4", "S5r5", "S5r6")
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

    table_s5$data[[cut_name]][["_NET_S5_AnyAffiliation_row_1"]] <- list(
      label = "Any affiliation (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: S5r1 == 1
  var_col <- safe_get_var(cut_data, "S5r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r1_row_2"]] <- list(
      label = "Advertising agency",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r1_row_2"]] <- list(
      label = "Advertising agency",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r1 not found"
    )
  }

  # Row 3: S5r2 == 1
  var_col <- safe_get_var(cut_data, "S5r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r2_row_3"]] <- list(
      label = "Marketing / Market research firm",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r2_row_3"]] <- list(
      label = "Marketing / Market research firm",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r2 not found"
    )
  }

  # Row 4: S5r3 == 1
  var_col <- safe_get_var(cut_data, "S5r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r3_row_4"]] <- list(
      label = "Public relations firm",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r3_row_4"]] <- list(
      label = "Public relations firm",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r3 not found"
    )
  }

  # Row 5: S5r4 == 1
  var_col <- safe_get_var(cut_data, "S5r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r4_row_5"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r4_row_5"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r4 not found"
    )
  }

  # Row 6: S5r5 == 1
  var_col <- safe_get_var(cut_data, "S5r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r5_row_6"]] <- list(
      label = "Pharmaceutical drug / device manufacturer (outside of clinical trials)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r5_row_6"]] <- list(
      label = "Pharmaceutical drug / device manufacturer (outside of clinical trials)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r5 not found"
    )
  }

  # Row 7: S5r6 == 1
  var_col <- safe_get_var(cut_data, "S5r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r6_row_7"]] <- list(
      label = "Governmental regulatory agency (e.g., FDA)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r6_row_7"]] <- list(
      label = "Governmental regulatory agency (e.g., FDA)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r6 not found"
    )
  }

  # Row 8: S5r7 == 1
  var_col <- safe_get_var(cut_data, "S5r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r7_row_8"]] <- list(
      label = "None of these",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r7_row_8"]] <- list(
      label = "None of these",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r7 not found"
    )
  }

}

all_tables[["s5"]] <- table_s5
print(paste("Generated frequency table: s5"))

# -----------------------------------------------------------------------------
# Table: s6 (mean_rows)
# Question: How many years have you been in clinical practice, post residency/training?
# Rows: 1
# Source: s6
# -----------------------------------------------------------------------------

table_s6 <- list(
  tableId = "s6",
  questionId = "S6",
  questionText = "How many years have you been in clinical practice, post residency/training?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s6",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Responses constrained by screener to 3-35 years; summary statistics (mean, median, etc.) are provided downstream)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6$data[[cut_name]] <- list()
  table_s6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_s6$data[[cut_name]][["S6"]] <- list(
      label = "How many years have you been in clinical practice, post residency/training?",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6"]] <- list(
      label = "How many years have you been in clinical practice, post residency/training?",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

}

all_tables[["s6"]] <- table_s6
print(paste("Generated mean_rows table: s6"))

# -----------------------------------------------------------------------------
# Table: s6_binned (frequency) [DERIVED]
# Question: How many years have you been in clinical practice, post residency/training?
# Rows: 6
# Source: s6
# -----------------------------------------------------------------------------

table_s6_binned <- list(
  tableId = "s6_binned",
  questionId = "S6",
  questionText = "How many years have you been in clinical practice, post residency/training?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s6",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Responses constrained by screener to 3-35 years; bins chosen to show distribution)",
  tableSubtitle = "Years in practice: Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6_binned$data[[cut_name]] <- list()
  table_s6_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S6 in range [3-5]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 3 & as.numeric(var_col) <= 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_1"]] <- list(
      label = "3-5 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_1"]] <- list(
      label = "3-5 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 2: S6 in range [6-10]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 6 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_2"]] <- list(
      label = "6-10 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_2"]] <- list(
      label = "6-10 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 3: S6 in range [11-15]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_3"]] <- list(
      label = "11-15 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_3"]] <- list(
      label = "11-15 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 4: S6 in range [16-20]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_4"]] <- list(
      label = "16-20 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_4"]] <- list(
      label = "16-20 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 5: S6 in range [21-30]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 21 & as.numeric(var_col) <= 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_5"]] <- list(
      label = "21-30 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_5"]] <- list(
      label = "21-30 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 6: S6 in range [31-35]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 31 & as.numeric(var_col) <= 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_6"]] <- list(
      label = "31-35 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_6"]] <- list(
      label = "31-35 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

}

all_tables[["s6_binned"]] <- table_s6_binned
print(paste("Generated frequency table: s6_binned"))

# -----------------------------------------------------------------------------
# Table: s7 (frequency)
# Question: And to confirm, are you currently practicing full-time (i.e. 40+ hours weekly across all settings) or part-time?
# Rows: 2
# Source: s7
# -----------------------------------------------------------------------------

table_s7 <- list(
  tableId = "s7",
  questionId = "S7",
  questionText = "And to confirm, are you currently practicing full-time (i.e. 40+ hours weekly across all settings) or part-time?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s7",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Part-time respondents were terminated during screening; only full-time respondents continued in the survey.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s7$data[[cut_name]] <- list()
  table_s7$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S7 == 1
  var_col <- safe_get_var(cut_data, "S7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7_row_1"]] <- list(
      label = "Full-Time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7_row_1"]] <- list(
      label = "Full-Time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7 not found"
    )
  }

  # Row 2: S7 == 2
  var_col <- safe_get_var(cut_data, "S7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7_row_2"]] <- list(
      label = "Part-Time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7_row_2"]] <- list(
      label = "Part-Time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7 not found"
    )
  }

}

all_tables[["s7"]] <- table_s7
print(paste("Generated frequency table: s7"))

# -----------------------------------------------------------------------------
# Table: s8 (mean_rows)
# Question: Approximately what percentage of your professional time is spent performing each of the following activities?
# Rows: 4
# -----------------------------------------------------------------------------

table_s8 <- list(
  tableId = "s8",
  questionId = "S8",
  questionText = "Approximately what percentage of your professional time is spent performing each of the following activities?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Responses must sum to 100%; respondents were required to spend ≥70% of time on Treating/Managing patients to qualify)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8$data[[cut_name]] <- list()
  table_s8$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_s8$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8$data[[cut_name]][["S8r1"]] <- list(
      label = "Treating/Managing patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_s8$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8$data[[cut_name]][["S8r2"]] <- list(
      label = "Performing academic functions (e.g., teaching, publishing)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_s8$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8$data[[cut_name]][["S8r3"]] <- list(
      label = "Participating in clinical research",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_s8$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8$data[[cut_name]][["S8r4"]] <- list(
      label = "Performing other functions",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r4 not found"
    )
  }

}

all_tables[["s8"]] <- table_s8
print(paste("Generated mean_rows table: s8"))

# -----------------------------------------------------------------------------
# Table: s8_binned (frequency) [DERIVED]
# Question: Approximately what percentage of your professional time is spent performing each of the following activities?
# Rows: 15
# Source: s8
# -----------------------------------------------------------------------------

table_s8_binned <- list(
  tableId = "s8_binned",
  questionId = "S8",
  questionText = "Approximately what percentage of your professional time is spent performing each of the following activities?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s8",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned distribution of reported percentages; responses sum to 100%)",
  tableSubtitle = "Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8_binned$data[[cut_name]] <- list()
  table_s8_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S8r1 in range [70-79]
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 70 & as.numeric(var_col) <= 79, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r1_row_1"]] <- list(
      label = "Treating/Managing patients: 70-79%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r1_row_1"]] <- list(
      label = "Treating/Managing patients: 70-79%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r1 not found"
    )
  }

  # Row 2: S8r1 in range [80-89]
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 80 & as.numeric(var_col) <= 89, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r1_row_2"]] <- list(
      label = "Treating/Managing patients: 80-89%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r1_row_2"]] <- list(
      label = "Treating/Managing patients: 80-89%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r1 not found"
    )
  }

  # Row 3: S8r1 in range [90-100]
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 90 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r1_row_3"]] <- list(
      label = "Treating/Managing patients: 90-100%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r1_row_3"]] <- list(
      label = "Treating/Managing patients: 90-100%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r1 not found"
    )
  }

  # Row 4: S8r2 == 0
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r2_row_4"]] <- list(
      label = "Performing academic functions: 0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r2_row_4"]] <- list(
      label = "Performing academic functions: 0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r2 not found"
    )
  }

  # Row 5: S8r2 in range [1-4]
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r2_row_5"]] <- list(
      label = "Performing academic functions: 1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r2_row_5"]] <- list(
      label = "Performing academic functions: 1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r2 not found"
    )
  }

  # Row 6: S8r2 in range [5-9]
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r2_row_6"]] <- list(
      label = "Performing academic functions: 5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r2_row_6"]] <- list(
      label = "Performing academic functions: 5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r2 not found"
    )
  }

  # Row 7: S8r2 in range [10-20]
  var_col <- safe_get_var(cut_data, "S8r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r2_row_7"]] <- list(
      label = "Performing academic functions: 10-20%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r2_row_7"]] <- list(
      label = "Performing academic functions: 10-20%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r2 not found"
    )
  }

  # Row 8: S8r3 == 0
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r3_row_8"]] <- list(
      label = "Participating in clinical research: 0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r3_row_8"]] <- list(
      label = "Participating in clinical research: 0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r3 not found"
    )
  }

  # Row 9: S8r3 in range [1-4]
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r3_row_9"]] <- list(
      label = "Participating in clinical research: 1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r3_row_9"]] <- list(
      label = "Participating in clinical research: 1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r3 not found"
    )
  }

  # Row 10: S8r3 in range [5-9]
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r3_row_10"]] <- list(
      label = "Participating in clinical research: 5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r3_row_10"]] <- list(
      label = "Participating in clinical research: 5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r3 not found"
    )
  }

  # Row 11: S8r3 in range [10-15]
  var_col <- safe_get_var(cut_data, "S8r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r3_row_11"]] <- list(
      label = "Participating in clinical research: 10-15%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r3_row_11"]] <- list(
      label = "Participating in clinical research: 10-15%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r3 not found"
    )
  }

  # Row 12: S8r4 == 0
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r4_row_12"]] <- list(
      label = "Performing other functions: 0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r4_row_12"]] <- list(
      label = "Performing other functions: 0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r4 not found"
    )
  }

  # Row 13: S8r4 in range [1-4]
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r4_row_13"]] <- list(
      label = "Performing other functions: 1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r4_row_13"]] <- list(
      label = "Performing other functions: 1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r4 not found"
    )
  }

  # Row 14: S8r4 in range [5-9]
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r4_row_14"]] <- list(
      label = "Performing other functions: 5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r4_row_14"]] <- list(
      label = "Performing other functions: 5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r4 not found"
    )
  }

  # Row 15: S8r4 in range [10-20]
  var_col <- safe_get_var(cut_data, "S8r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8r4_row_15"]] <- list(
      label = "Performing other functions: 10-20%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8r4_row_15"]] <- list(
      label = "Performing other functions: 10-20%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8r4 not found"
    )
  }

}

all_tables[["s8_binned"]] <- table_s8_binned
print(paste("Generated frequency table: s8_binned"))

# -----------------------------------------------------------------------------
# Table: s9 (frequency) [DERIVED]
# Question: Which of the following best represents the setting in which you spend most of your professional time?
# Rows: 10
# Source: s9
# -----------------------------------------------------------------------------

table_s9 <- list(
  tableId = "s9",
  questionId = "S9",
  questionText = "Which of the following best represents the setting in which you spend most of your professional time?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s9",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s9$data[[cut_name]] <- list()
  table_s9$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S9 IN (1, 2)
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private practice (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_1"]] <- list(
      label = "Private practice (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 2: S9 == 1
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Solo Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_2"]] <- list(
      label = "Private Solo Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 3: S9 == 2
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Private Group Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_3"]] <- list(
      label = "Private Group Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 4: S9 == 3
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_4"]] <- list(
      label = "Multi-specialty Practice / Comprehensive Care",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 5: S9 == 4
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Staff HMO",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Staff HMO",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 6: S9 IN (5, 6, 7)
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(5, 6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Hospital (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Hospital (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 7: S9 == 5
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "Community Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_7"]] <- list(
      label = "Community Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 8: S9 == 6
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "Academic/University Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_8"]] <- list(
      label = "Academic/University Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 9: S9 == 7
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_9"]] <- list(
      label = "VA Hospital",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_9"]] <- list(
      label = "VA Hospital",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

  # Row 10: S9 == 8
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_10"]] <- list(
      label = "None of the above",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_10"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9 not found"
    )
  }

}

all_tables[["s9"]] <- table_s9
print(paste("Generated frequency table: s9"))

# -----------------------------------------------------------------------------
# Table: s10 (mean_rows)
# Question: Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.
# Rows: 1
# Source: s10
# -----------------------------------------------------------------------------

table_s10 <- list(
  tableId = "s10",
  questionId = "S10",
  questionText = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s10",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Responses are counts of adult patients managed per month; respondents with <50 patients were screened out)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      label = "Patients managed per month (count)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10$data[[cut_name]][["S10"]] <- list(
      label = "Patients managed per month (count)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10 not found"
    )
  }

}

all_tables[["s10"]] <- table_s10
print(paste("Generated mean_rows table: s10"))

# -----------------------------------------------------------------------------
# Table: s10_distribution (frequency) [DERIVED]
# Question: Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.
# Rows: 4
# Source: s10
# -----------------------------------------------------------------------------

table_s10_distribution <- list(
  tableId = "s10_distribution",
  questionId = "S10",
  questionText = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s10",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned distribution to show counts of respondents by number of adult patients managed per month; bins chosen using observed range and study screening criteria)",
  tableSubtitle = "Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10_distribution$data[[cut_name]] <- list()
  table_s10_distribution$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S10 in range [50-99]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_distribution$data[[cut_name]][["S10_row_1"]] <- list(
      label = "50-99 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_distribution$data[[cut_name]][["S10_row_1"]] <- list(
      label = "50-99 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10 not found"
    )
  }

  # Row 2: S10 in range [100-199]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 100 & as.numeric(var_col) <= 199, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_distribution$data[[cut_name]][["S10_row_2"]] <- list(
      label = "100-199 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_distribution$data[[cut_name]][["S10_row_2"]] <- list(
      label = "100-199 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10 not found"
    )
  }

  # Row 3: S10 in range [200-499]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 200 & as.numeric(var_col) <= 499, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_distribution$data[[cut_name]][["S10_row_3"]] <- list(
      label = "200-499 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_distribution$data[[cut_name]][["S10_row_3"]] <- list(
      label = "200-499 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10 not found"
    )
  }

  # Row 4: S10 in range [500-999]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 500 & as.numeric(var_col) <= 999, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_distribution$data[[cut_name]][["S10_row_4"]] <- list(
      label = "500+ patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_distribution$data[[cut_name]][["S10_row_4"]] <- list(
      label = "500+ patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10 not found"
    )
  }

}

all_tables[["s10_distribution"]] <- table_s10_distribution
print(paste("Generated frequency table: s10_distribution"))

# -----------------------------------------------------------------------------
# Table: s11 (mean_rows)
# Question: Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?
# Rows: 1
# Source: s11
# -----------------------------------------------------------------------------

table_s11 <- list(
  tableId = "s11",
  questionId = "S11",
  questionText = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s11",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Numeric open-ended: number of adult patients with hypercholesterolemia and established CVD personally managed; respondents with fewer than 10 were screened out)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      label = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11$data[[cut_name]][["S11"]] <- list(
      label = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

}

all_tables[["s11"]] <- table_s11
print(paste("Generated mean_rows table: s11"))

# -----------------------------------------------------------------------------
# Table: s11_dist (frequency) [DERIVED]
# Question: Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?
# Rows: 5
# Source: s11
# -----------------------------------------------------------------------------

table_s11_dist <- list(
  tableId = "s11_dist",
  questionId = "S11",
  questionText = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s11",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned distribution to aid interpretation; bins chosen based on expected clinic panel sizes and survey screening criteria)",
  tableSubtitle = "Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11_dist$data[[cut_name]] <- list()
  table_s11_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11 in range [10-24]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_dist$data[[cut_name]][["S11_row_1"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_dist$data[[cut_name]][["S11_row_1"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

  # Row 2: S11 in range [25-49]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_dist$data[[cut_name]][["S11_row_2"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_dist$data[[cut_name]][["S11_row_2"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

  # Row 3: S11 in range [50-99]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_dist$data[[cut_name]][["S11_row_3"]] <- list(
      label = "50-99 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_dist$data[[cut_name]][["S11_row_3"]] <- list(
      label = "50-99 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

  # Row 4: S11 in range [100-199]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 100 & as.numeric(var_col) <= 199, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_dist$data[[cut_name]][["S11_row_4"]] <- list(
      label = "100-199 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_dist$data[[cut_name]][["S11_row_4"]] <- list(
      label = "100-199 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

  # Row 5: S11 in range [200-999]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 200 & as.numeric(var_col) <= 999, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_dist$data[[cut_name]][["S11_row_5"]] <- list(
      label = "200 or more patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_dist$data[[cut_name]][["S11_row_5"]] <- list(
      label = "200 or more patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11 not found"
    )
  }

}

all_tables[["s11_dist"]] <- table_s11_dist
print(paste("Generated frequency table: s11_dist"))

# -----------------------------------------------------------------------------
# Table: s12 (mean_rows)
# Question: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.)
# Rows: 4
# Source: s12
# -----------------------------------------------------------------------------

table_s12 <- list(
  tableId = "s12",
  questionId = "S12",
  questionText = "Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s12",
  surveySection = "SCREENER",
  baseText = "Among the adult patients you reported in the previous question (those with confirmed hypercholesterolemia and established CVD).",
  userNote = "(Enter counts; autosum must be less than or equal to the number reported previously.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      label = "Over 5 years ago — number of patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s12$data[[cut_name]][["S12r1"]] <- list(
      label = "Over 5 years ago — number of patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      label = "Within the last 3-5 years — number of patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s12$data[[cut_name]][["S12r2"]] <- list(
      label = "Within the last 3-5 years — number of patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      label = "Within the last 1-2 years — number of patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s12$data[[cut_name]][["S12r3"]] <- list(
      label = "Within the last 1-2 years — number of patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      label = "Within the last year — number of patients",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s12$data[[cut_name]][["S12r4"]] <- list(
      label = "Within the last year — number of patients",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S12r4 not found"
    )
  }

}

all_tables[["s12"]] <- table_s12
print(paste("Generated mean_rows table: s12"))

# -----------------------------------------------------------------------------
# Table: a1 (frequency)
# Question: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? (Check one box per row.)
# Rows: 12
# Source: a1
# -----------------------------------------------------------------------------

table_a1 <- list(
  tableId = "a1",
  questionId = "A1",
  questionText = "To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? (Check one box per row.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a1",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Check one box per row)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a1$data[[cut_name]] <- list()
  table_a1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Leqvio (inclisiran)
  table_a1$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Leqvio (inclisiran)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A1r1 == 1
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r1_row_2"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r1 not found"
    )
  }

  # Row 3: A1r1 == 2
  var_col <- safe_get_var(cut_data, "A1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r1_row_3"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r1_row_3"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r1 not found"
    )
  }

  # Row 4: Category header - Praluent (alirocumab)
  table_a1$data[[cut_name]][["_CAT__row_4"]] <- list(
    label = "Praluent (alirocumab)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 5: A1r2 == 1
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r2_row_5"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r2_row_5"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r2 not found"
    )
  }

  # Row 6: A1r2 == 2
  var_col <- safe_get_var(cut_data, "A1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r2_row_6"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r2_row_6"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r2 not found"
    )
  }

  # Row 7: Category header - Repatha (evolocumab)
  table_a1$data[[cut_name]][["_CAT__row_7"]] <- list(
    label = "Repatha (evolocumab)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 8: A1r3 == 1
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r3_row_8"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r3_row_8"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r3 not found"
    )
  }

  # Row 9: A1r3 == 2
  var_col <- safe_get_var(cut_data, "A1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r3_row_9"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r3_row_9"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r3 not found"
    )
  }

  # Row 10: Category header - Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)
  table_a1$data[[cut_name]][["_CAT__row_10"]] <- list(
    label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 11: A1r4 == 1
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r4_row_11"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r4_row_11"]] <- list(
      label = "As an adjunct to diet, alone or in combination with other LDL‑C‑lowering therapies, in adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r4 not found"
    )
  }

  # Row 12: A1r4 == 2
  var_col <- safe_get_var(cut_data, "A1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a1$data[[cut_name]][["A1r4_row_12"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a1$data[[cut_name]][["A1r4_row_12"]] <- list(
      label = "As an adjunct to diet and statin therapy for the treatment of adults with primary hyperlipidemia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A1r4 not found"
    )
  }

}

all_tables[["a1"]] <- table_a1
print(paste("Generated frequency table: a1"))

# -----------------------------------------------------------------------------
# Table: a2a (frequency)
# Question: To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?
# Rows: 3
# Source: a2a
# -----------------------------------------------------------------------------

table_a2a <- list(
  tableId = "a2a",
  questionId = "A2a",
  questionText = "To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a2a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified respondents (those who passed the screener)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
      error = "Variable A2a not found"
    )
  }

}

all_tables[["a2a"]] <- table_a2a
print(paste("Generated frequency table: a2a"))

# -----------------------------------------------------------------------------
# Table: a2b (frequency)
# Question: And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?
# Rows: 4
# Source: a2b
# -----------------------------------------------------------------------------

table_a2b <- list(
  tableId = "a2b",
  questionId = "A2b",
  questionText = "And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a2b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a2b$data[[cut_name]] <- list()
  table_a2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A2b IN (1, 2)
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend statin-first approach (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_1"]] <- list(
      label = "Recommend statin-first approach (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2b not found"
    )
  }

  # Row 2: A2b == 1
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_2"]] <- list(
      label = "Recommend a statin first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2b not found"
    )
  }

  # Row 3: A2b == 2
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_3"]] <- list(
      label = "Recommend a statin + ezetimibe first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2b not found"
    )
  }

  # Row 4: A2b == 3
  var_col <- safe_get_var(cut_data, "A2b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2b$data[[cut_name]][["A2b_row_4"]] <- list(
      label = "Recommend a PCSK9i first",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2b$data[[cut_name]][["A2b_row_4"]] <- list(
      label = "Recommend a PCSK9i first",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2b not found"
    )
  }

}

all_tables[["a2b"]] <- table_a2b
print(paste("Generated frequency table: a2b"))

# -----------------------------------------------------------------------------
# Table: a3 (mean_rows)
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?
# Rows: 7
# -----------------------------------------------------------------------------

table_a3 <- list(
  tableId = "a3",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Enter number of patients out of your last 100; responses for the therapies can sum to more than 100)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      label = "Statin only (no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3r1"]] <- list(
      label = "Statin only (no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3r6"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

}

all_tables[["a3"]] <- table_a3
print(paste("Generated mean_rows table: a3"))

# -----------------------------------------------------------------------------
# Table: a3_dist_leqvio (frequency) [DERIVED]
# Question: Leqvio (inclisiran) — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_leqvio <- list(
  tableId = "a3_dist_leqvio",
  questionId = "A3",
  questionText = "Leqvio (inclisiran) — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Leqvio (inclisiran): Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_leqvio$data[[cut_name]] <- list()
  table_a3_dist_leqvio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r2 == 0
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r2 not found"
    )
  }

  # Row 2: A3r2 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r2 not found"
    )
  }

  # Row 3: A3r2 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r2 not found"
    )
  }

  # Row 4: A3r2 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r2 not found"
    )
  }

  # Row 5: A3r2 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_leqvio$data[[cut_name]][["A3r2_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r2 not found"
    )
  }

}

all_tables[["a3_dist_leqvio"]] <- table_a3_dist_leqvio
print(paste("Generated frequency table: a3_dist_leqvio"))

# -----------------------------------------------------------------------------
# Table: a3_dist_nexletol (frequency) [DERIVED]
# Question: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe) — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_nexletol <- list(
  tableId = "a3_dist_nexletol",
  questionId = "A3",
  questionText = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe) — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Nexletol / Nexlizet: Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_nexletol$data[[cut_name]] <- list()
  table_a3_dist_nexletol$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r6 == 0
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r6 not found"
    )
  }

  # Row 2: A3r6 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r6 not found"
    )
  }

  # Row 3: A3r6 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r6 not found"
    )
  }

  # Row 4: A3r6 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r6 not found"
    )
  }

  # Row 5: A3r6 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_nexletol$data[[cut_name]][["A3r6_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r6 not found"
    )
  }

}

all_tables[["a3_dist_nexletol"]] <- table_a3_dist_nexletol
print(paste("Generated frequency table: a3_dist_nexletol"))

# -----------------------------------------------------------------------------
# Table: a3_dist_other (frequency) [DERIVED]
# Question: Other therapies — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_other <- list(
  tableId = "a3_dist_other",
  questionId = "A3",
  questionText = "Other therapies — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Other: Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_other$data[[cut_name]] <- list()
  table_a3_dist_other$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r7 == 0
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_other$data[[cut_name]][["A3r7_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_other$data[[cut_name]][["A3r7_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

  # Row 2: A3r7 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_other$data[[cut_name]][["A3r7_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_other$data[[cut_name]][["A3r7_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

  # Row 3: A3r7 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_other$data[[cut_name]][["A3r7_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_other$data[[cut_name]][["A3r7_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

  # Row 4: A3r7 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_other$data[[cut_name]][["A3r7_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_other$data[[cut_name]][["A3r7_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

  # Row 5: A3r7 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_other$data[[cut_name]][["A3r7_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_other$data[[cut_name]][["A3r7_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r7 not found"
    )
  }

}

all_tables[["a3_dist_other"]] <- table_a3_dist_other
print(paste("Generated frequency table: a3_dist_other"))

# -----------------------------------------------------------------------------
# Table: a3_dist_praluent (frequency) [DERIVED]
# Question: Praluent (alirocumab) — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_praluent <- list(
  tableId = "a3_dist_praluent",
  questionId = "A3",
  questionText = "Praluent (alirocumab) — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Praluent (alirocumab): Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_praluent$data[[cut_name]] <- list()
  table_a3_dist_praluent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r3 == 0
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r3 not found"
    )
  }

  # Row 2: A3r3 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r3 not found"
    )
  }

  # Row 3: A3r3 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r3 not found"
    )
  }

  # Row 4: A3r3 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r3 not found"
    )
  }

  # Row 5: A3r3 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_praluent$data[[cut_name]][["A3r3_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r3 not found"
    )
  }

}

all_tables[["a3_dist_praluent"]] <- table_a3_dist_praluent
print(paste("Generated frequency table: a3_dist_praluent"))

# -----------------------------------------------------------------------------
# Table: a3_dist_repatha (frequency) [DERIVED]
# Question: Repatha (evolocumab) — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_repatha <- list(
  tableId = "a3_dist_repatha",
  questionId = "A3",
  questionText = "Repatha (evolocumab) — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Repatha (evolocumab): Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_repatha$data[[cut_name]] <- list()
  table_a3_dist_repatha$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r4 == 0
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r4 not found"
    )
  }

  # Row 2: A3r4 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r4 not found"
    )
  }

  # Row 3: A3r4 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r4 not found"
    )
  }

  # Row 4: A3r4 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r4 not found"
    )
  }

  # Row 5: A3r4 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_repatha$data[[cut_name]][["A3r4_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r4 not found"
    )
  }

}

all_tables[["a3_dist_repatha"]] <- table_a3_dist_repatha
print(paste("Generated frequency table: a3_dist_repatha"))

# -----------------------------------------------------------------------------
# Table: a3_dist_statins (frequency) [DERIVED]
# Question: Statin only (no additional therapy) — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_statins <- list(
  tableId = "a3_dist_statins",
  questionId = "A3",
  questionText = "Statin only (no additional therapy) — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Statin only: Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_statins$data[[cut_name]] <- list()
  table_a3_dist_statins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r1 == 0
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_statins$data[[cut_name]][["A3r1_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_statins$data[[cut_name]][["A3r1_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r1 not found"
    )
  }

  # Row 2: A3r1 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_statins$data[[cut_name]][["A3r1_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_statins$data[[cut_name]][["A3r1_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r1 not found"
    )
  }

  # Row 3: A3r1 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_statins$data[[cut_name]][["A3r1_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_statins$data[[cut_name]][["A3r1_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r1 not found"
    )
  }

  # Row 4: A3r1 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_statins$data[[cut_name]][["A3r1_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_statins$data[[cut_name]][["A3r1_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r1 not found"
    )
  }

  # Row 5: A3r1 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_statins$data[[cut_name]][["A3r1_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_statins$data[[cut_name]][["A3r1_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r1 not found"
    )
  }

}

all_tables[["a3_dist_statins"]] <- table_a3_dist_statins
print(paste("Generated frequency table: a3_dist_statins"))

# -----------------------------------------------------------------------------
# Table: a3_dist_zetia (frequency) [DERIVED]
# Question: Zetia (ezetimibe) or generic ezetimibe — distribution of counts for your LAST 100 patients
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_dist_zetia <- list(
  tableId = "a3_dist_zetia",
  questionId = "A3",
  questionText = "Zetia (ezetimibe) or generic ezetimibe — distribution of counts for your LAST 100 patients",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified clinicians who met the screener (respondents with eligible practice and patient volumes)",
  userNote = "(Binned distribution of counts out of 100 patients)",
  tableSubtitle = "Zetia (ezetimibe): Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_dist_zetia$data[[cut_name]] <- list()
  table_a3_dist_zetia$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r5 == 0
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_1"]] <- list(
      label = "0 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_1"]] <- list(
      label = "0 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r5 not found"
    )
  }

  # Row 2: A3r5 in range [1-9]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_2"]] <- list(
      label = "1-9 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_2"]] <- list(
      label = "1-9 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r5 not found"
    )
  }

  # Row 3: A3r5 in range [10-24]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_3"]] <- list(
      label = "10-24 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_3"]] <- list(
      label = "10-24 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r5 not found"
    )
  }

  # Row 4: A3r5 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_4"]] <- list(
      label = "25-49 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_4"]] <- list(
      label = "25-49 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r5 not found"
    )
  }

  # Row 5: A3r5 in range [50-100]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_5"]] <- list(
      label = "50-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_dist_zetia$data[[cut_name]][["A3r5_row_5"]] <- list(
      label = "50-100 patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3r5 not found"
    )
  }

}

all_tables[["a3_dist_zetia"]] <- table_a3_dist_zetia
print(paste("Generated frequency table: a3_dist_zetia"))

# -----------------------------------------------------------------------------
# Table: a3a_leqvio_inclisiran_ (mean_rows)
# Question: For each treatment, approximately what percent of your LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_leqvio_inclisiran_ <- list(
  tableId = "a3a_leqvio_inclisiran_",
  questionId = "A3a",
  questionText = "For each treatment, approximately what percent of your LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Leqvio (inclisiran) to more than 0 of their last 100 patients",
  userNote = "(Percent of last 100 patients; each row must total 100%)",
  tableSubtitle = "Leqvio (inclisiran)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3a_leqvio_inclisiran_$data[[cut_name]] <- list()
  table_a3a_leqvio_inclisiran_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_leqvio_inclisiran_$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "In addition to a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_leqvio_inclisiran_$data[[cut_name]][["A3ar1c1"]] <- list(
      label = "In addition to a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a3a_leqvio_inclisiran_$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_leqvio_inclisiran_$data[[cut_name]][["A3ar1c2"]] <- list(
      label = "Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar1c2 not found"
    )
  }

}

all_tables[["a3a_leqvio_inclisiran_"]] <- table_a3a_leqvio_inclisiran_
print(paste("Generated mean_rows table: a3a_leqvio_inclisiran_"))

# -----------------------------------------------------------------------------
# Table: a3a_nexletol_nexlizet (mean_rows)
# Question: For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin?
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_nexletol_nexlizet <- list(
  tableId = "a3a_nexletol_nexlizet",
  questionId = "A3a",
  questionText = "For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Nexletol/Nexlizet (bempedoic acid or combination) to more than 0 of their last 100 patients",
  userNote = "(Percent of last 100 patients; responses 0–100. For each therapy, the two values should sum to 100%.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r6 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3a_nexletol_nexlizet$data[[cut_name]] <- list()
  table_a3a_nexletol_nexlizet$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar5c1 (numeric summary)
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

    table_a3a_nexletol_nexlizet$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "In addition to a statin — Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_nexletol_nexlizet$data[[cut_name]][["A3ar5c1"]] <- list(
      label = "In addition to a statin — Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 2: A3ar5c2 (numeric summary)
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

    table_a3a_nexletol_nexlizet$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Without a statin — Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_nexletol_nexlizet$data[[cut_name]][["A3ar5c2"]] <- list(
      label = "Without a statin — Nexletol (bempedoic acid) or Nexlizet (bempedoic acid + ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

}

all_tables[["a3a_nexletol_nexlizet"]] <- table_a3a_nexletol_nexlizet
print(paste("Generated mean_rows table: a3a_nexletol_nexlizet"))

# -----------------------------------------------------------------------------
# Table: a3a_praluent_alirocumab_ (mean_rows)
# Question: For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a3a_praluent_alirocumab_
# -----------------------------------------------------------------------------

table_a3a_praluent_alirocumab_ <- list(
  tableId = "a3a_praluent_alirocumab_",
  questionId = "A3a",
  questionText = "For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a_praluent_alirocumab_",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Praluent (alirocumab) to more than 0 of their last 100 patients",
  userNote = "(Responses sum to 100%; percentages refer to the respondent's LAST 100 patients)",
  tableSubtitle = "Praluent (alirocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r3 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3a_praluent_alirocumab_$data[[cut_name]] <- list()
  table_a3a_praluent_alirocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar2c1 (numeric summary)
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

    table_a3a_praluent_alirocumab_$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "In addition to a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_praluent_alirocumab_$data[[cut_name]][["A3ar2c1"]] <- list(
      label = "In addition to a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar2c1 not found"
    )
  }

  # Row 2: A3ar2c2 (numeric summary)
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

    table_a3a_praluent_alirocumab_$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_praluent_alirocumab_$data[[cut_name]][["A3ar2c2"]] <- list(
      label = "Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar2c2 not found"
    )
  }

}

all_tables[["a3a_praluent_alirocumab_"]] <- table_a3a_praluent_alirocumab_
print(paste("Generated mean_rows table: a3a_praluent_alirocumab_"))

# -----------------------------------------------------------------------------
# Table: a3a_repatha_evolocumab_ (mean_rows)
# Question: For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_repatha_evolocumab_ <- list(
  tableId = "a3a_repatha_evolocumab_",
  questionId = "A3a",
  questionText = "For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Repatha (evolocumab) to more than 0 of their last 100 patients",
  userNote = "(Enter percentage 0-100; each row must sum to 100% for that treatment)",
  tableSubtitle = "Repatha (evolocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r4 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3a_repatha_evolocumab_$data[[cut_name]] <- list()
  table_a3a_repatha_evolocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar3c1 (numeric summary)
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

    table_a3a_repatha_evolocumab_$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "In addition to a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_repatha_evolocumab_$data[[cut_name]][["A3ar3c1"]] <- list(
      label = "In addition to a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar3c1 not found"
    )
  }

  # Row 2: A3ar3c2 (numeric summary)
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

    table_a3a_repatha_evolocumab_$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_repatha_evolocumab_$data[[cut_name]][["A3ar3c2"]] <- list(
      label = "Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar3c2 not found"
    )
  }

}

all_tables[["a3a_repatha_evolocumab_"]] <- table_a3a_repatha_evolocumab_
print(paste("Generated mean_rows table: a3a_repatha_evolocumab_"))

# -----------------------------------------------------------------------------
# Table: a3a_zetia_ezetimibe_ (mean_rows) [DERIVED]
# Question: For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_zetia_ezetimibe_ <- list(
  tableId = "a3a_zetia_ezetimibe_",
  questionId = "A3a",
  questionText = "For each treatment, approximately what percentage of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Zetia (ezetimibe) to more than 0 of their last 100 patients",
  userNote = "(Percentages refer to the LAST 100 patients and each row must sum to 100% — In addition to a statin vs. Without a statin)",
  tableSubtitle = "Zetia (ezetimibe)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r5 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3a_zetia_ezetimibe_$data[[cut_name]] <- list()
  table_a3a_zetia_ezetimibe_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar4c1 (numeric summary)
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

    table_a3a_zetia_ezetimibe_$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "In addition to a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_zetia_ezetimibe_$data[[cut_name]][["A3ar4c1"]] <- list(
      label = "In addition to a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar4c1 not found"
    )
  }

  # Row 2: A3ar4c2 (numeric summary)
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

    table_a3a_zetia_ezetimibe_$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3a_zetia_ezetimibe_$data[[cut_name]][["A3ar4c2"]] <- list(
      label = "Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar4c2 not found"
    )
  }

}

all_tables[["a3a_zetia_ezetimibe_"]] <- table_a3a_zetia_ezetimibe_
print(paste("Generated mean_rows table: a3a_zetia_ezetimibe_"))

# -----------------------------------------------------------------------------
# Table: a3ar5c1_distribution (frequency) [DERIVED]
# Question: Distribution of responses: % of LAST 100 patients who received Nexletol in addition to a statin (binned)
# Rows: 5
# Source: a3a_nexletol_nexlizet
# -----------------------------------------------------------------------------

table_a3ar5c1_distribution <- list(
  tableId = "a3ar5c1_distribution",
  questionId = "A3a",
  questionText = "Distribution of responses: % of LAST 100 patients who received Nexletol in addition to a statin (binned)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3a_nexletol_nexlizet",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Nexletol/Nexlizet (bempedoic acid or combination) to more than 0 of their last 100 patients",
  userNote = "(Binned distribution of percentage responses; original values 0–100.)",
  tableSubtitle = "In addition to statin: Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r6 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3ar5c1_distribution$data[[cut_name]] <- list()
  table_a3ar5c1_distribution$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar5c1 == 0
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_1"]] <- list(
      label = "0% (None)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_1"]] <- list(
      label = "0% (None)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 2: A3ar5c1 in range [1-24]
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_2"]] <- list(
      label = "1–24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_2"]] <- list(
      label = "1–24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 3: A3ar5c1 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_3"]] <- list(
      label = "25–49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_3"]] <- list(
      label = "25–49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 4: A3ar5c1 in range [50-74]
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 74, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_4"]] <- list(
      label = "50–74%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_4"]] <- list(
      label = "50–74%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

  # Row 5: A3ar5c1 in range [75-100]
  var_col <- safe_get_var(cut_data, "A3ar5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 75 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_5"]] <- list(
      label = "75–100%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c1_distribution$data[[cut_name]][["A3ar5c1_row_5"]] <- list(
      label = "75–100%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c1 not found"
    )
  }

}

all_tables[["a3ar5c1_distribution"]] <- table_a3ar5c1_distribution
print(paste("Generated frequency table: a3ar5c1_distribution"))

# -----------------------------------------------------------------------------
# Table: a3ar5c2_distribution (frequency) [DERIVED]
# Question: Distribution of responses: % of LAST 100 patients who received Nexletol without a statin (binned)
# Rows: 5
# Source: a3a_nexletol_nexlizet
# -----------------------------------------------------------------------------

table_a3ar5c2_distribution <- list(
  tableId = "a3ar5c2_distribution",
  questionId = "A3a",
  questionText = "Distribution of responses: % of LAST 100 patients who received Nexletol without a statin (binned)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3a_nexletol_nexlizet",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who prescribed Nexletol/Nexlizet (bempedoic acid or combination) to more than 0 of their last 100 patients",
  userNote = "(Binned distribution of percentage responses; original values 0–100.)",
  tableSubtitle = "Without statin: Distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3r6 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3ar5c2_distribution$data[[cut_name]] <- list()
  table_a3ar5c2_distribution$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3ar5c2 == 0
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_1"]] <- list(
      label = "0% (None)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_1"]] <- list(
      label = "0% (None)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

  # Row 2: A3ar5c2 in range [1-24]
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_2"]] <- list(
      label = "1–24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_2"]] <- list(
      label = "1–24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

  # Row 3: A3ar5c2 in range [25-49]
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_3"]] <- list(
      label = "25–49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_3"]] <- list(
      label = "25–49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

  # Row 4: A3ar5c2 in range [50-74]
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 74, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_4"]] <- list(
      label = "50–74%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_4"]] <- list(
      label = "50–74%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

  # Row 5: A3ar5c2 in range [75-100]
  var_col <- safe_get_var(cut_data, "A3ar5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 75 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_5"]] <- list(
      label = "75–100%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3ar5c2_distribution$data[[cut_name]][["A3ar5c2_row_5"]] <- list(
      label = "75–100%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3ar5c2 not found"
    )
  }

}

all_tables[["a3ar5c2_distribution"]] <- table_a3ar5c2_distribution
print(paste("Generated frequency table: a3ar5c2_distribution"))

# -----------------------------------------------------------------------------
# Table: a3b_leqvio_inclisiran_ (mean_rows) [DERIVED]
# Question: For each treatment you indicated you prescribe without a statin, approximately what percentage of those patients who received that therapy without a statin did so:
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_leqvio_inclisiran_ <- list(
  tableId = "a3b_leqvio_inclisiran_",
  questionId = "A3b",
  questionText = "For each treatment you indicated you prescribe without a statin, approximately what percentage of those patients who received that therapy without a statin did so:",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Show Leqvio (inclisiran) row when A3a (Leqvio) 'Without a statin' > 0",
  userNote = "(Percent of patients; values 0–100. Rows for a given therapy should sum to 100%)",
  tableSubtitle = "Leqvio (inclisiran)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3ar1c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3b_leqvio_inclisiran_$data[[cut_name]] <- list()
  table_a3b_leqvio_inclisiran_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_leqvio_inclisiran_$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_inclisiran_$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a3b_leqvio_inclisiran_$data[[cut_name]][["A3br1c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_inclisiran_$data[[cut_name]][["A3br1c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c2 not found"
    )
  }

}

all_tables[["a3b_leqvio_inclisiran_"]] <- table_a3b_leqvio_inclisiran_
print(paste("Generated mean_rows table: a3b_leqvio_inclisiran_"))

# -----------------------------------------------------------------------------
# Table: a3b_nexletol_bempedoic_acid_ (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_nexletol_bempedoic_acid_ <- list(
  tableId = "a3b_nexletol_bempedoic_acid_",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Show Nexletol (bempedoic acid) row when A3a (Nexletol) 'Without a statin' > 0",
  userNote = "(Values are percentages, 0–100; the rows represent the distribution of patients prescribed the therapy without a statin and should sum to ~100% per treatment)",
  tableSubtitle = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3ar5c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3b_nexletol_bempedoic_acid_$data[[cut_name]] <- list()
  table_a3b_nexletol_bempedoic_acid_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br5c1 (numeric summary)
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

    table_a3b_nexletol_bempedoic_acid_$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_bempedoic_acid_$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 2: A3br5c2 (numeric summary)
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

    table_a3b_nexletol_bempedoic_acid_$data[[cut_name]][["A3br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_bempedoic_acid_$data[[cut_name]][["A3br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c2 not found"
    )
  }

}

all_tables[["a3b_nexletol_bempedoic_acid_"]] <- table_a3b_nexletol_bempedoic_acid_
print(paste("Generated mean_rows table: a3b_nexletol_bempedoic_acid_"))

# -----------------------------------------------------------------------------
# Table: a3b_praluent_alirocumab_ (mean_rows) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_praluent_alirocumab_ <- list(
  tableId = "a3b_praluent_alirocumab_",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Show Praluent (alirocumab) row when A3a (Praluent) 'Without a statin' > 0",
  userNote = "(Percentages 0-100; rows shown only for respondents who reported prescribing Praluent without a statin)",
  tableSubtitle = "Praluent (alirocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3ar2c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3b_praluent_alirocumab_$data[[cut_name]] <- list()
  table_a3b_praluent_alirocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br2c1 (numeric summary)
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

    table_a3b_praluent_alirocumab_$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_alirocumab_$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 2: A3br2c2 (numeric summary)
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

    table_a3b_praluent_alirocumab_$data[[cut_name]][["A3br2c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_alirocumab_$data[[cut_name]][["A3br2c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c2 not found"
    )
  }

}

all_tables[["a3b_praluent_alirocumab_"]] <- table_a3b_praluent_alirocumab_
print(paste("Generated mean_rows table: a3b_praluent_alirocumab_"))

# -----------------------------------------------------------------------------
# Table: a3b_repatha_evolocumab_ (mean_rows) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so (split by whether it was prescribed before any other lipid-lowering therapy or after trying another therapy)
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_repatha_evolocumab_ <- list(
  tableId = "a3b_repatha_evolocumab_",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so (split by whether it was prescribed before any other lipid-lowering therapy or after trying another therapy)",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Show Repatha (evolocumab) row when A3a (Repatha) 'Without a statin' > 0",
  userNote = "(Percent distribution of those patients prescribed Repatha without a statin; responses range 0–100 and should sum to 100% across the two rows per respondent)",
  tableSubtitle = "Repatha (evolocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3ar3c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3b_repatha_evolocumab_$data[[cut_name]] <- list()
  table_a3b_repatha_evolocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br3c1 (numeric summary)
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

    table_a3b_repatha_evolocumab_$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_evolocumab_$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 2: A3br3c2 (numeric summary)
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

    table_a3b_repatha_evolocumab_$data[[cut_name]][["A3br3c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_evolocumab_$data[[cut_name]][["A3br3c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c2 not found"
    )
  }

}

all_tables[["a3b_repatha_evolocumab_"]] <- table_a3b_repatha_evolocumab_
print(paste("Generated mean_rows table: a3b_repatha_evolocumab_"))

# -----------------------------------------------------------------------------
# Table: a3b_zetia_ezetimibe_ (mean_rows) [DERIVED]
# Question: For each treatment you indicated you prescribe without a statin, approximately what percentage of those patients who received that therapy without a statin did so:
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_zetia_ezetimibe_ <- list(
  tableId = "a3b_zetia_ezetimibe_",
  questionId = "A3b",
  questionText = "For each treatment you indicated you prescribe without a statin, approximately what percentage of those patients who received that therapy without a statin did so:",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Show Zetia (ezetimibe) row when A3a (Zetia) 'Without a statin' > 0",
  userNote = "(Percent responses, 0-100; for each respondent these two values must sum to 100%)",
  tableSubtitle = "Zetia (ezetimibe)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A3ar4c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a3b_zetia_ezetimibe_$data[[cut_name]] <- list()
  table_a3b_zetia_ezetimibe_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br4c1 (numeric summary)
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

    table_a3b_zetia_ezetimibe_$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_ezetimibe_$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 2: A3br4c2 (numeric summary)
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

    table_a3b_zetia_ezetimibe_$data[[cut_name]][["A3br4c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_ezetimibe_$data[[cut_name]][["A3br4c2"]] <- list(
      label = "After trying another lipid‑lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c2 not found"
    )
  }

}

all_tables[["a3b_zetia_ezetimibe_"]] <- table_a3b_zetia_ezetimibe_
print(paste("Generated mean_rows table: a3b_zetia_ezetimibe_"))

# -----------------------------------------------------------------------------
# Table: a4_last100 (mean_rows) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies. Your answer can add to greater than 100.
# Rows: 7
# Source: a4
# -----------------------------------------------------------------------------

table_a4_last100 <- list(
  tableId = "a4_last100",
  questionId = "A4",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies. Your answer can add to greater than 100.",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Enter number of patients out of 100; responses can sum to more than 100.)",
  tableSubtitle = "LAST 100 Patients (Reference)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_last100$data[[cut_name]] <- list()
  table_a4_last100$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4_last100$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_last100$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_last100$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4r7c1 not found"
    )
  }

}

all_tables[["a4_last100"]] <- table_a4_last100
print(paste("Generated mean_rows table: a4_last100"))

# -----------------------------------------------------------------------------
# Table: a4_next100 (mean_rows) [DERIVED]
# Question: In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your answer can add to greater than 100.
# Rows: 7
# Source: a4
# -----------------------------------------------------------------------------

table_a4_next100 <- list(
  tableId = "a4_next100",
  questionId = "A4",
  questionText = "In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your answer can add to greater than 100.",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Enter number of patients out of 100; responses can sum to more than 100.)",
  tableSubtitle = "NEXT 100 Patients (Assuming indication change)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4_next100$data[[cut_name]] <- list()
  table_a4_next100$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4_next100$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4_next100$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4_next100$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4r7c2 not found"
    )
  }

}

all_tables[["a4_next100"]] <- table_a4_next100
print(paste("Generated mean_rows table: a4_next100"))

# -----------------------------------------------------------------------------
# Table: a4a (mean_rows)
# Question: For each treatment, for approximately what percentage of your NEXT 100 patients with uncontrolled LDL-C would you expect to prescribe that therapy in addition to a statin vs. without a statin?
# Rows: 10
# -----------------------------------------------------------------------------

table_a4a <- list(
  tableId = "a4a",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what percentage of your NEXT 100 patients with uncontrolled LDL-C would you expect to prescribe that therapy in addition to a statin vs. without a statin?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Percent of NEXT 100 patients; values are percentages and can sum to more than 100% across therapies)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4a$data[[cut_name]] <- list()
  table_a4a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4a$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4a$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar5c2 not found"
    )
  }

}

all_tables[["a4a"]] <- table_a4a
print(paste("Generated mean_rows table: a4a"))

# -----------------------------------------------------------------------------
# Table: a4a_in_addition_comparison (mean_rows) [DERIVED]
# Question: Mean percent of your NEXT 100 patients expected to receive each treatment in addition to a statin
# Rows: 5
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_in_addition_comparison <- list(
  tableId = "a4a_in_addition_comparison",
  questionId = "A4a",
  questionText = "Mean percent of your NEXT 100 patients expected to receive each treatment in addition to a statin",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Comparison of mean % across products; percent of NEXT 100 patients expected to receive the product in addition to a statin)",
  tableSubtitle = "In addition to statin (Mean % Comparison)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4a_in_addition_comparison$data[[cut_name]] <- list()
  table_a4a_in_addition_comparison$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar1c1 not found"
    )
  }

  # Row 2: A4ar2c1 (numeric summary)
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

    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar2c1 not found"
    )
  }

  # Row 3: A4ar3c1 (numeric summary)
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

    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar3c1 not found"
    )
  }

  # Row 4: A4ar4c1 (numeric summary)
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

    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar4c1 not found"
    )
  }

  # Row 5: A4ar5c1 (numeric summary)
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

    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_in_addition_comparison$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar5c1 not found"
    )
  }

}

all_tables[["a4a_in_addition_comparison"]] <- table_a4a_in_addition_comparison
print(paste("Generated mean_rows table: a4a_in_addition_comparison"))

# -----------------------------------------------------------------------------
# Table: a4a_without_statins_comparison (mean_rows) [DERIVED]
# Question: Mean percent of your NEXT 100 patients expected to receive each treatment without a statin
# Rows: 5
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_without_statins_comparison <- list(
  tableId = "a4a_without_statins_comparison",
  questionId = "A4a",
  questionText = "Mean percent of your NEXT 100 patients expected to receive each treatment without a statin",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Comparison of mean % across products; percent of NEXT 100 patients expected to receive the product without a statin)",
  tableSubtitle = "Without a statin (Mean % Comparison)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4a_without_statins_comparison$data[[cut_name]] <- list()
  table_a4a_without_statins_comparison$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar1c2 (numeric summary)
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

    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar1c2"]] <- list(
      label = "Leqvio (inclisiran) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar1c2 not found"
    )
  }

  # Row 2: A4ar2c2 (numeric summary)
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

    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar2c2"]] <- list(
      label = "Praluent (alirocumab) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar2c2 not found"
    )
  }

  # Row 3: A4ar3c2 (numeric summary)
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

    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar3c2"]] <- list(
      label = "Repatha (evolocumab) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar3c2 not found"
    )
  }

  # Row 4: A4ar4c2 (numeric summary)
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

    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar4c2"]] <- list(
      label = "Zetia (ezetimibe) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar4c2 not found"
    )
  }

  # Row 5: A4ar5c2 (numeric summary)
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

    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Without a statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4a_without_statins_comparison$data[[cut_name]][["A4ar5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Without a statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4ar5c2 not found"
    )
  }

}

all_tables[["a4a_without_statins_comparison"]] <- table_a4a_without_statins_comparison
print(paste("Generated mean_rows table: a4a_without_statins_comparison"))

# -----------------------------------------------------------------------------
# Table: a4b_leqvio_inclisiran_ (mean_rows) [DERIVED]
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin did so…
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_leqvio_inclisiran_ <- list(
  tableId = "a4b_leqvio_inclisiran_",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Leqvio in A4a",
  userNote = "(Percent of patients; responses 0-100. Columns reflect % who received the therapy before other lipid-lowering therapy [first line] vs after trying another therapy.)",
  tableSubtitle = "Leqvio (inclisiran)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar1c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_leqvio_inclisiran_$data[[cut_name]] <- list()
  table_a4b_leqvio_inclisiran_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_leqvio_inclisiran_$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_leqvio_inclisiran_$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4b_leqvio_inclisiran_$data[[cut_name]][["A4br1c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_leqvio_inclisiran_$data[[cut_name]][["A4br1c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br1c2 not found"
    )
  }

}

all_tables[["a4b_leqvio_inclisiran_"]] <- table_a4b_leqvio_inclisiran_
print(paste("Generated mean_rows table: a4b_leqvio_inclisiran_"))

# -----------------------------------------------------------------------------
# Table: a4b_nexletol_bempedoic_acid_after (mean_rows) [DERIVED]
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…
# Rows: 1
# Source: a4b_nexletol_bempedoic_acid_
# -----------------------------------------------------------------------------

table_a4b_nexletol_bempedoic_acid_after <- list(
  tableId = "a4b_nexletol_bempedoic_acid_after",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4b_nexletol_bempedoic_acid_",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Nexletol in A4a",
  userNote = "(Percent, 0–100; 'Before' + 'After' sum to 100% per respondent for Nexletol/Nexlizet)",
  tableSubtitle = "After (Following other therapy)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar5c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_nexletol_bempedoic_acid_after$data[[cut_name]] <- list()
  table_a4b_nexletol_bempedoic_acid_after$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br5c2 (numeric summary)
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

    table_a4b_nexletol_bempedoic_acid_after$data[[cut_name]][["A4br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_nexletol_bempedoic_acid_after$data[[cut_name]][["A4br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br5c2 not found"
    )
  }

}

all_tables[["a4b_nexletol_bempedoic_acid_after"]] <- table_a4b_nexletol_bempedoic_acid_after
print(paste("Generated mean_rows table: a4b_nexletol_bempedoic_acid_after"))

# -----------------------------------------------------------------------------
# Table: a4b_nexletol_bempedoic_acid_before (mean_rows) [DERIVED]
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…
# Rows: 1
# Source: a4b_nexletol_bempedoic_acid_
# -----------------------------------------------------------------------------

table_a4b_nexletol_bempedoic_acid_before <- list(
  tableId = "a4b_nexletol_bempedoic_acid_before",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4b_nexletol_bempedoic_acid_",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Nexletol in A4a",
  userNote = "(Percent, 0–100; 'Before' + 'After' sum to 100% per respondent for Nexletol/Nexlizet)",
  tableSubtitle = "Before (First line)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar5c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_nexletol_bempedoic_acid_before$data[[cut_name]] <- list()
  table_a4b_nexletol_bempedoic_acid_before$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br5c1 (numeric summary)
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

    table_a4b_nexletol_bempedoic_acid_before$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (First line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_nexletol_bempedoic_acid_before$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (First line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br5c1 not found"
    )
  }

}

all_tables[["a4b_nexletol_bempedoic_acid_before"]] <- table_a4b_nexletol_bempedoic_acid_before
print(paste("Generated mean_rows table: a4b_nexletol_bempedoic_acid_before"))

# -----------------------------------------------------------------------------
# Table: a4b_praluent_alirocumab_ (mean_rows)
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin did so…
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_praluent_alirocumab_ <- list(
  tableId = "a4b_praluent_alirocumab_",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Praluent in A4a",
  userNote = "(Enter %; rows for a given therapy must sum to 100%)",
  tableSubtitle = "Praluent (alirocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar2c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_praluent_alirocumab_$data[[cut_name]] <- list()
  table_a4b_praluent_alirocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br2c1 (numeric summary)
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

    table_a4b_praluent_alirocumab_$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_praluent_alirocumab_$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Before any other lipid-lowering therapy (i.e., first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br2c1 not found"
    )
  }

  # Row 2: A4br2c2 (numeric summary)
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

    table_a4b_praluent_alirocumab_$data[[cut_name]][["A4br2c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_praluent_alirocumab_$data[[cut_name]][["A4br2c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br2c2 not found"
    )
  }

}

all_tables[["a4b_praluent_alirocumab_"]] <- table_a4b_praluent_alirocumab_
print(paste("Generated mean_rows table: a4b_praluent_alirocumab_"))

# -----------------------------------------------------------------------------
# Table: a4b_repatha_evolocumab_ (mean_rows)
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin would do so: BEFORE any other lipid-lowering therapy (i.e., first line) / AFTER trying another lipid-lowering therapy.
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_repatha_evolocumab_ <- list(
  tableId = "a4b_repatha_evolocumab_",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin would do so: BEFORE any other lipid-lowering therapy (i.e., first line) / AFTER trying another lipid-lowering therapy.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Repatha in A4a",
  userNote = "(Percent distribution of patients; columns should sum to 100% per respondent / responses are percentages)",
  tableSubtitle = "Repatha (evolocumab)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar3c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_repatha_evolocumab_$data[[cut_name]] <- list()
  table_a4b_repatha_evolocumab_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br3c1 (numeric summary)
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

    table_a4b_repatha_evolocumab_$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Before any other lipid-lowering therapy (first line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_repatha_evolocumab_$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Before any other lipid-lowering therapy (first line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br3c1 not found"
    )
  }

  # Row 2: A4br3c2 (numeric summary)
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

    table_a4b_repatha_evolocumab_$data[[cut_name]][["A4br3c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_repatha_evolocumab_$data[[cut_name]][["A4br3c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br3c2 not found"
    )
  }

}

all_tables[["a4b_repatha_evolocumab_"]] <- table_a4b_repatha_evolocumab_
print(paste("Generated mean_rows table: a4b_repatha_evolocumab_"))

# -----------------------------------------------------------------------------
# Table: a4b_zetia_ezetimibe_ (mean_rows)
# Question: For each treatment you indicated you would prescribe without a statin, approximately what percentage of those patients received that therapy before trying any other lipid‑lowering therapy versus after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_zetia_ezetimibe_ <- list(
  tableId = "a4b_zetia_ezetimibe_",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would prescribe without a statin, approximately what percentage of those patients received that therapy before trying any other lipid‑lowering therapy versus after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Zetia in A4a",
  userNote = "(Percent; respondents only saw this if they indicated prescribing Zetia without a statin. 'Before' + 'After' should sum to 100% per respondent.)",
  tableSubtitle = "Zetia (ezetimibe)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar4c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_zetia_ezetimibe_$data[[cut_name]] <- list()
  table_a4b_zetia_ezetimibe_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br4c1 (numeric summary)
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

    table_a4b_zetia_ezetimibe_$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (prescribed as first‑line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_zetia_ezetimibe_$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Before any other lipid‑lowering therapy (prescribed as first‑line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br4c1 not found"
    )
  }

  # Row 2: A4br4c2 (numeric summary)
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

    table_a4b_zetia_ezetimibe_$data[[cut_name]][["A4br4c2"]] <- list(
      label = "After trying another lipid‑lowering therapy (prescribed following other therapy)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_zetia_ezetimibe_$data[[cut_name]][["A4br4c2"]] <- list(
      label = "After trying another lipid‑lowering therapy (prescribed following other therapy)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br4c2 not found"
    )
  }

}

all_tables[["a4b_zetia_ezetimibe_"]] <- table_a4b_zetia_ezetimibe_
print(paste("Generated mean_rows table: a4b_zetia_ezetimibe_"))

# -----------------------------------------------------------------------------
# Table: a5 (frequency)
# Question: How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?
# Rows: 5
# Source: a5
# -----------------------------------------------------------------------------

table_a5 <- list(
  tableId = "a5",
  questionId = "A5",
  questionText = "How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a5",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents whose prescribing in A4 differs from A3 for at least one PCSK9 therapy (Leqvio, Praluent, or Repatha).",
  userNote = "(Asked only of respondents who indicated their prescribing of PCSK9 inhibitors would change between the prior questions)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "(A4r2c2 != A3r2) | (A4r3c2 != A3r3) | (A4r4c2 != A3r4)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a5$data[[cut_name]] <- list()
  table_a5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A5 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 6 months (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "Within 6 months (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A5 not found"
    )
  }

  # Row 2: A5 == 1
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "Within 3 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "Within 3 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A5 not found"
    )
  }

  # Row 3: A5 == 2
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "4-6 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "4-6 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A5 not found"
    )
  }

  # Row 4: A5 == 3
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "7-12 months",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_4"]] <- list(
      label = "7-12 months",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A5 not found"
    )
  }

  # Row 5: A5 == 4
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_5"]] <- list(
      label = "Over a year",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_5"]] <- list(
      label = "Over a year",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A5 not found"
    )
  }

}

all_tables[["a5"]] <- table_a5
print(paste("Generated frequency table: a5"))

# -----------------------------------------------------------------------------
# Table: a6 (mean_rows)
# Question: For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Rank up to 4.)
# Rows: 8
# -----------------------------------------------------------------------------

table_a6 <- list(
  tableId = "a6",
  questionId = "A6",
  questionText = "For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Rank up to 4.)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified respondents (see screener)",
  userNote = "(Rank up to 4; 1 = most likely)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6$data[[cut_name]] <- list()
  table_a6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 (numeric summary)
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a6$data[[cut_name]][["A6r8"]] <- list(
      label = "Other (please specify)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r8"]] <- list(
      label = "Other (please specify)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["a6"]] <- table_a6
print(paste("Generated mean_rows table: a6"))

# -----------------------------------------------------------------------------
# Table: a6_top1 (frequency) [DERIVED]
# Question: For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Top-1 share shown.)
# Rows: 8
# Source: a6
# -----------------------------------------------------------------------------

table_a6_top1 <- list(
  tableId = "a6_top1",
  questionId = "A6",
  questionText = "For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Top-1 share shown.)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified respondents (see screener)",
  userNote = "(Share ranked #1)",
  tableSubtitle = "Top-1 Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_top1$data[[cut_name]] <- list()
  table_a6_top1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 1
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 == 1
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 == 1
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 == 1
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 == 1
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 == 1
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 == 1
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 == 1
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (please specify) (Ranked #1)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (please specify) (Ranked #1)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["a6_top1"]] <- table_a6_top1
print(paste("Generated frequency table: a6_top1"))

# -----------------------------------------------------------------------------
# Table: a6_top2 (frequency) [DERIVED]
# Question: For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Top-2 share shown.)
# Rows: 8
# Source: a6
# -----------------------------------------------------------------------------

table_a6_top2 <- list(
  tableId = "a6_top2",
  questionId = "A6",
  questionText = "For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow. (Top-2 share shown.)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Qualified respondents (see screener)",
  userNote = "(Share ranked #1 or #2)",
  tableSubtitle = "Top-2 Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_top2$data[[cut_name]] <- list()
  table_a6_top2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r1 not found"
    )
  }

  # Row 2: A6r2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r4 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r4 not found"
    )
  }

  # Row 5: A6r5 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r5 not found"
    )
  }

  # Row 6: A6r6 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r6 not found"
    )
  }

  # Row 7: A6r7 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, then add/switch to PCSK9i if needed (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r7 not found"
    )
  }

  # Row 8: A6r8 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (please specify) (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (please specify) (Top 2)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r8 not found"
    )
  }

}

all_tables[["a6_top2"]] <- table_a6_top2
print(paste("Generated frequency table: a6_top2"))

# -----------------------------------------------------------------------------
# Table: a7 (frequency) [DERIVED]
# Question: How might being able to use PCSK9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?
# Rows: 6
# Source: a7
# -----------------------------------------------------------------------------

table_a7 <- list(
  tableId = "a7",
  questionId = "A7",
  questionText = "How might being able to use PCSK9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a7",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a7$data[[cut_name]] <- list()
  table_a7$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any impact (NET) (components: A7r1, A7r2, A7r3, A7r4, A7r5)
  net_vars <- c("A7r1", "A7r2", "A7r3", "A7r4", "A7r5")
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

    table_a7$data[[cut_name]][["_NET_A7Any_row_1"]] <- list(
      label = "Any impact (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A7r1 == 1
  var_col <- safe_get_var(cut_data, "A7r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r1_row_2"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7$data[[cut_name]][["A7r1_row_2"]] <- list(
      label = "Makes PCSK9s easier to get covered by insurance / get patients on the medication",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r1 not found"
    )
  }

  # Row 3: A7r2 == 1
  var_col <- safe_get_var(cut_data, "A7r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r2_row_3"]] <- list(
      label = "Offers an option to patients who can’t or won’t take a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7$data[[cut_name]][["A7r2_row_3"]] <- list(
      label = "Offers an option to patients who can’t or won’t take a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r2 not found"
    )
  }

  # Row 4: A7r3 == 1
  var_col <- safe_get_var(cut_data, "A7r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r3_row_4"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7$data[[cut_name]][["A7r3_row_4"]] <- list(
      label = "Enables me to use PCSK9s sooner for patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r3 not found"
    )
  }

  # Row 5: A7r4 == 1
  var_col <- safe_get_var(cut_data, "A7r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r4_row_5"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7$data[[cut_name]][["A7r4_row_5"]] <- list(
      label = "Allows me to better customize treatment plans for patients",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r4 not found"
    )
  }

  # Row 6: A7r5 == 1
  var_col <- safe_get_var(cut_data, "A7r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7$data[[cut_name]][["A7r5_row_6"]] <- list(
      label = "Other (Specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7$data[[cut_name]][["A7r5_row_6"]] <- list(
      label = "Other (Specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r5 not found"
    )
  }

}

all_tables[["a7"]] <- table_a7
print(paste("Generated frequency table: a7"))

# -----------------------------------------------------------------------------
# Table: a8_leqvio_detail (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 40
# Source: a8
# -----------------------------------------------------------------------------

table_a8_leqvio_detail <- list(
  tableId = "a8_leqvio_detail",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Respondents rated each product × patient situation on a 5-point likelihood scale: 1=Not at all likely; 5=Extremely likely)",
  tableSubtitle = "Leqvio: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_leqvio_detail$data[[cut_name]] <- list()
  table_a8_leqvio_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - With established CVD
  table_a8_leqvio_detail$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "With established CVD",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A8r1c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_2"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_2"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 3: A8r1c3 == 5
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_3"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_3"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 4: A8r1c3 == 4
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_4"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_4"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 5: A8r1c3 == 3
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 6: A8r1c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 7: A8r1c3 == 2
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_7"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_7"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 8: A8r1c3 == 1
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_8"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r1c3_row_8"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 9: Category header - With no history of CV events and at high-risk
  table_a8_leqvio_detail$data[[cut_name]][["_CAT__row_9"]] <- list(
    label = "With no history of CV events and at high-risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 10: A8r2c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_10"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_10"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 11: A8r2c3 == 5
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_11"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 12: A8r2c3 == 4
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_12"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 13: A8r2c3 == 3
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 14: A8r2c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 15: A8r2c3 == 2
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_15"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 16: A8r2c3 == 1
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_16"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r2c3_row_16"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 17: Category header - With no history of CV events and at low-to-medium risk
  table_a8_leqvio_detail$data[[cut_name]][["_CAT__row_17"]] <- list(
    label = "With no history of CV events and at low-to-medium risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 18: A8r3c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_18"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_18"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 19: A8r3c3 == 5
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_19"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_19"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 20: A8r3c3 == 4
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_20"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_20"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 21: A8r3c3 == 3
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 22: A8r3c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 23: A8r3c3 == 2
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_23"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_23"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 24: A8r3c3 == 1
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_24"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r3c3_row_24"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 25: Category header - Who are not known to be compliant on statins
  table_a8_leqvio_detail$data[[cut_name]][["_CAT__row_25"]] <- list(
    label = "Who are not known to be compliant on statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 26: A8r4c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_26"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_26"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 27: A8r4c3 == 5
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_27"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_27"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 28: A8r4c3 == 4
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_28"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_28"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 29: A8r4c3 == 3
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 30: A8r4c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 31: A8r4c3 == 2
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_31"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_31"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 32: A8r4c3 == 1
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_32"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r4c3_row_32"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 33: Category header - Who are intolerant of statins
  table_a8_leqvio_detail$data[[cut_name]][["_CAT__row_33"]] <- list(
    label = "Who are intolerant of statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 34: A8r5c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_34"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_34"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 35: A8r5c3 == 5
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_35"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_35"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 36: A8r5c3 == 4
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_36"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_36"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 37: A8r5c3 == 3
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 38: A8r5c3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 39: A8r5c3 == 2
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_39"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_39"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 40: A8r5c3 == 1
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_40"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_leqvio_detail$data[[cut_name]][["A8r5c3_row_40"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

}

all_tables[["a8_leqvio_detail"]] <- table_a8_leqvio_detail
print(paste("Generated frequency table: a8_leqvio_detail"))

# -----------------------------------------------------------------------------
# Table: a8_praluent_detail (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 40
# Source: a8
# -----------------------------------------------------------------------------

table_a8_praluent_detail <- list(
  tableId = "a8_praluent_detail",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Respondents rated each product × patient situation on a 5-point likelihood scale: 1=Not at all likely; 5=Extremely likely)",
  tableSubtitle = "Praluent: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_praluent_detail$data[[cut_name]] <- list()
  table_a8_praluent_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - With established CVD
  table_a8_praluent_detail$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "With established CVD",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A8r1c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_2"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_2"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 3: A8r1c2 == 5
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_3"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_3"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 4: A8r1c2 == 4
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_4"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_4"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 5: A8r1c2 == 3
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 6: A8r1c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 7: A8r1c2 == 2
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 8: A8r1c2 == 1
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 9: Category header - With no history of CV events and at high-risk
  table_a8_praluent_detail$data[[cut_name]][["_CAT__row_9"]] <- list(
    label = "With no history of CV events and at high-risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 10: A8r2c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_10"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 11: A8r2c2 == 5
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_11"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_11"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 12: A8r2c2 == 4
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_12"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_12"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 13: A8r2c2 == 3
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 14: A8r2c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 15: A8r2c2 == 2
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_15"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_15"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 16: A8r2c2 == 1
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_16"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r2c2_row_16"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 17: Category header - With no history of CV events and at low-to-medium risk
  table_a8_praluent_detail$data[[cut_name]][["_CAT__row_17"]] <- list(
    label = "With no history of CV events and at low-to-medium risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 18: A8r3c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_18"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_18"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 19: A8r3c2 == 5
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_19"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_19"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 20: A8r3c2 == 4
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_20"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_20"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 21: A8r3c2 == 3
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 22: A8r3c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 23: A8r3c2 == 2
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_23"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_23"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 24: A8r3c2 == 1
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_24"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r3c2_row_24"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 25: Category header - Who are not known to be compliant on statins
  table_a8_praluent_detail$data[[cut_name]][["_CAT__row_25"]] <- list(
    label = "Who are not known to be compliant on statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 26: A8r4c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_26"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_26"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 27: A8r4c2 == 5
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_27"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_27"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 28: A8r4c2 == 4
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_28"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_28"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 29: A8r4c2 == 3
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 30: A8r4c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 31: A8r4c2 == 2
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_31"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_31"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 32: A8r4c2 == 1
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_32"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r4c2_row_32"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 33: Category header - Who are intolerant of statins
  table_a8_praluent_detail$data[[cut_name]][["_CAT__row_33"]] <- list(
    label = "Who are intolerant of statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 34: A8r5c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_34"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_34"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 35: A8r5c2 == 5
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_35"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_35"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 36: A8r5c2 == 4
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_36"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_36"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 37: A8r5c2 == 3
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 38: A8r5c2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 39: A8r5c2 == 2
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_39"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_39"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 40: A8r5c2 == 1
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_40"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_praluent_detail$data[[cut_name]][["A8r5c2_row_40"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

}

all_tables[["a8_praluent_detail"]] <- table_a8_praluent_detail
print(paste("Generated frequency table: a8_praluent_detail"))

# -----------------------------------------------------------------------------
# Table: a8_r1_t2b (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 3
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r1_t2b <- list(
  tableId = "a8_r1_t2b",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 Box = Very or Extremely likely)",
  tableSubtitle = "With established CVD — T2B Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r1_t2b$data[[cut_name]] <- list()
  table_a8_r1_t2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r1c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_t2b$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_t2b$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 2: A8r1c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_t2b$data[[cut_name]][["A8r1c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_t2b$data[[cut_name]][["A8r1c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 3: A8r1c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_t2b$data[[cut_name]][["A8r1c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_t2b$data[[cut_name]][["A8r1c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

}

all_tables[["a8_r1_t2b"]] <- table_a8_r1_t2b
print(paste("Generated frequency table: a8_r1_t2b"))

# -----------------------------------------------------------------------------
# Table: a8_r2_t2b (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 3
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r2_t2b <- list(
  tableId = "a8_r2_t2b",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 Box = Very or Extremely likely)",
  tableSubtitle = "With no history of CV events and at high-risk — T2B Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r2_t2b$data[[cut_name]] <- list()
  table_a8_r2_t2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r2c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_t2b$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_t2b$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 2: A8r2c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_t2b$data[[cut_name]][["A8r2c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_t2b$data[[cut_name]][["A8r2c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 3: A8r2c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_t2b$data[[cut_name]][["A8r2c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_t2b$data[[cut_name]][["A8r2c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

}

all_tables[["a8_r2_t2b"]] <- table_a8_r2_t2b
print(paste("Generated frequency table: a8_r2_t2b"))

# -----------------------------------------------------------------------------
# Table: a8_r3_t2b (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 3
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r3_t2b <- list(
  tableId = "a8_r3_t2b",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 Box = Very or Extremely likely)",
  tableSubtitle = "With no history of CV events and at low-to-medium risk — T2B Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r3_t2b$data[[cut_name]] <- list()
  table_a8_r3_t2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r3c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_t2b$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_t2b$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 2: A8r3c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_t2b$data[[cut_name]][["A8r3c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_t2b$data[[cut_name]][["A8r3c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 3: A8r3c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_t2b$data[[cut_name]][["A8r3c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_t2b$data[[cut_name]][["A8r3c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

}

all_tables[["a8_r3_t2b"]] <- table_a8_r3_t2b
print(paste("Generated frequency table: a8_r3_t2b"))

# -----------------------------------------------------------------------------
# Table: a8_r4_t2b (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 3
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r4_t2b <- list(
  tableId = "a8_r4_t2b",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 Box = Very or Extremely likely)",
  tableSubtitle = "Who are not known to be compliant on statins — T2B Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r4_t2b$data[[cut_name]] <- list()
  table_a8_r4_t2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r4c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_t2b$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_t2b$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 2: A8r4c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_t2b$data[[cut_name]][["A8r4c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_t2b$data[[cut_name]][["A8r4c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 3: A8r4c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_t2b$data[[cut_name]][["A8r4c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_t2b$data[[cut_name]][["A8r4c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

}

all_tables[["a8_r4_t2b"]] <- table_a8_r4_t2b
print(paste("Generated frequency table: a8_r4_t2b"))

# -----------------------------------------------------------------------------
# Table: a8_r5_t2b (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 3
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r5_t2b <- list(
  tableId = "a8_r5_t2b",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 Box = Very or Extremely likely)",
  tableSubtitle = "Who are intolerant of statins — T2B Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r5_t2b$data[[cut_name]] <- list()
  table_a8_r5_t2b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r5c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_t2b$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_t2b$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 2: A8r5c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_t2b$data[[cut_name]][["A8r5c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_t2b$data[[cut_name]][["A8r5c2_row_2"]] <- list(
      label = "Praluent (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 3: A8r5c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_t2b$data[[cut_name]][["A8r5c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_t2b$data[[cut_name]][["A8r5c3_row_3"]] <- list(
      label = "Leqvio (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

}

all_tables[["a8_r5_t2b"]] <- table_a8_r5_t2b
print(paste("Generated frequency table: a8_r5_t2b"))

# -----------------------------------------------------------------------------
# Table: a8_repatha_detail (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 40
# Source: a8
# -----------------------------------------------------------------------------

table_a8_repatha_detail <- list(
  tableId = "a8_repatha_detail",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Respondents rated each product × patient situation on a 5-point likelihood scale: 1=Not at all likely; 5=Extremely likely)",
  tableSubtitle = "Repatha: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_repatha_detail$data[[cut_name]] <- list()
  table_a8_repatha_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - With established CVD
  table_a8_repatha_detail$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "With established CVD",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A8r1c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 3: A8r1c1 == 5
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 4: A8r1c1 == 4
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 5: A8r1c1 == 3
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 6: A8r1c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_6"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 7: A8r1c1 == 2
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_7"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_7"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 8: A8r1c1 == 1
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_8"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r1c1_row_8"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 9: Category header - With no history of CV events and at high-risk
  table_a8_repatha_detail$data[[cut_name]][["_CAT__row_9"]] <- list(
    label = "With no history of CV events and at high-risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 10: A8r2c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_10"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_10"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 11: A8r2c1 == 5
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_11"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_11"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 12: A8r2c1 == 4
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_12"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_12"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 13: A8r2c1 == 3
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_13"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 14: A8r2c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_14"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 15: A8r2c1 == 2
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_15"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_15"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 16: A8r2c1 == 1
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_16"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r2c1_row_16"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 17: Category header - With no history of CV events and at low-to-medium risk
  table_a8_repatha_detail$data[[cut_name]][["_CAT__row_17"]] <- list(
    label = "With no history of CV events and at low-to-medium risk",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 18: A8r3c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_18"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_18"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 19: A8r3c1 == 5
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_19"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_19"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 20: A8r3c1 == 4
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_20"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_20"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 21: A8r3c1 == 3
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_21"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 22: A8r3c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_22"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 23: A8r3c1 == 2
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_23"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_23"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 24: A8r3c1 == 1
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_24"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r3c1_row_24"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 25: Category header - Who are not known to be compliant on statins
  table_a8_repatha_detail$data[[cut_name]][["_CAT__row_25"]] <- list(
    label = "Who are not known to be compliant on statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 26: A8r4c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_26"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_26"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 27: A8r4c1 == 5
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_27"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_27"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 28: A8r4c1 == 4
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_28"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_28"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 29: A8r4c1 == 3
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_29"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 30: A8r4c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_30"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 31: A8r4c1 == 2
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_31"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_31"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 32: A8r4c1 == 1
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_32"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r4c1_row_32"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 33: Category header - Who are intolerant of statins
  table_a8_repatha_detail$data[[cut_name]][["_CAT__row_33"]] <- list(
    label = "Who are intolerant of statins",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 34: A8r5c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_34"]] <- list(
      label = "Likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_34"]] <- list(
      label = "Likely (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 35: A8r5c1 == 5
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_35"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_35"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 36: A8r5c1 == 4
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_36"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_36"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 37: A8r5c1 == 3
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_37"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 38: A8r5c1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_38"]] <- list(
      label = "Unlikely (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 39: A8r5c1 == 2
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_39"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_39"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 40: A8r5c1 == 1
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_40"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_repatha_detail$data[[cut_name]][["A8r5c1_row_40"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

}

all_tables[["a8_repatha_detail"]] <- table_a8_repatha_detail
print(paste("Generated frequency table: a8_repatha_detail"))

# -----------------------------------------------------------------------------
# Table: a9_any_issues_comparison (frequency) [DERIVED]
# Question: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Rows: 3
# Source: a9
# -----------------------------------------------------------------------------

table_a9_any_issues_comparison <- list(
  tableId = "a9_any_issues_comparison",
  questionId = "A9",
  questionText = "To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a9",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one for each product)",
  tableSubtitle = "Any issues (NET) Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9_any_issues_comparison$data[[cut_name]] <- list()
  table_a9_any_issues_comparison$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c1 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_any_issues_comparison$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Repatha - Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_any_issues_comparison$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Repatha - Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 2: A9c2 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_any_issues_comparison$data[[cut_name]][["A9c2_row_2"]] <- list(
      label = "Praluent - Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_any_issues_comparison$data[[cut_name]][["A9c2_row_2"]] <- list(
      label = "Praluent - Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 3: A9c3 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_any_issues_comparison$data[[cut_name]][["A9c3_row_3"]] <- list(
      label = "Leqvio - Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_any_issues_comparison$data[[cut_name]][["A9c3_row_3"]] <- list(
      label = "Leqvio - Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

}

all_tables[["a9_any_issues_comparison"]] <- table_a9_any_issues_comparison
print(paste("Generated frequency table: a9_any_issues_comparison"))

# -----------------------------------------------------------------------------
# Table: a9_leqvio_detail (frequency) [DERIVED]
# Question: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Rows: 5
# Source: a9
# -----------------------------------------------------------------------------

table_a9_leqvio_detail <- list(
  tableId = "a9_leqvio_detail",
  questionId = "A9",
  questionText = "To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a9",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one for each product)",
  tableSubtitle = "Leqvio: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9_leqvio_detail$data[[cut_name]] <- list()
  table_a9_leqvio_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c3 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_1"]] <- list(
      label = "Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_1"]] <- list(
      label = "Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 2: A9c3 == 2
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_2"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_2"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 3: A9c3 == 3
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_3"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_3"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 4: A9c3 == 1
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_4"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_4"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 5: A9c3 == 4
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_leqvio_detail$data[[cut_name]][["A9c3_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

}

all_tables[["a9_leqvio_detail"]] <- table_a9_leqvio_detail
print(paste("Generated frequency table: a9_leqvio_detail"))

# -----------------------------------------------------------------------------
# Table: a9_praluent_detail (frequency) [DERIVED]
# Question: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Rows: 5
# Source: a9
# -----------------------------------------------------------------------------

table_a9_praluent_detail <- list(
  tableId = "a9_praluent_detail",
  questionId = "A9",
  questionText = "To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a9",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one for each product)",
  tableSubtitle = "Praluent: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9_praluent_detail$data[[cut_name]] <- list()
  table_a9_praluent_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c2 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_1"]] <- list(
      label = "Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_1"]] <- list(
      label = "Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 2: A9c2 == 2
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_2"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_2"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 3: A9c2 == 3
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_3"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_3"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 4: A9c2 == 1
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_4"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_4"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 5: A9c2 == 4
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_praluent_detail$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

}

all_tables[["a9_praluent_detail"]] <- table_a9_praluent_detail
print(paste("Generated frequency table: a9_praluent_detail"))

# -----------------------------------------------------------------------------
# Table: a9_repatha_detail (frequency) [DERIVED]
# Question: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Rows: 5
# Source: a9
# -----------------------------------------------------------------------------

table_a9_repatha_detail <- list(
  tableId = "a9_repatha_detail",
  questionId = "A9",
  questionText = "To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a9",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one for each product)",
  tableSubtitle = "Repatha: Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9_repatha_detail$data[[cut_name]] <- list()
  table_a9_repatha_detail$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c1 IN (2, 3)
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Any issues (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "Any issues (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 2: A9c1 == 2
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 3: A9c1 == 3
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 4: A9c1 == 1
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 5: A9c1 == 4
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_repatha_detail$data[[cut_name]][["A9c1_row_5"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

}

all_tables[["a9_repatha_detail"]] <- table_a9_repatha_detail
print(paste("Generated frequency table: a9_repatha_detail"))

# -----------------------------------------------------------------------------
# Table: a10 (frequency)
# Question: For what reasons are you using PCSK9 inhibitors without a statin today?
# Rows: 7
# Source: a10
# -----------------------------------------------------------------------------

table_a10 <- list(
  tableId = "a10",
  questionId = "A10",
  questionText = "For what reasons are you using PCSK9 inhibitors without a statin today?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a10",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select all that apply; responses can sum to more than 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a10$data[[cut_name]] <- list()
  table_a10$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any reason for prescribing PCSK9 without a statin (NET) (components: A10r1, A10r2, A10r3, A10r4, A10r5)
  net_vars <- c("A10r1", "A10r2", "A10r3", "A10r4", "A10r5")
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

    table_a10$data[[cut_name]][["_NET_A10_AnyReason_row_1"]] <- list(
      label = "Any reason for prescribing PCSK9 without a statin (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A10r1 == 1
  var_col <- safe_get_var(cut_data, "A10r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r1_row_2"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r1_row_2"]] <- list(
      label = "Patient failed statins prior to starting PCSK9i",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r1 not found"
    )
  }

  # Row 3: A10r2 == 1
  var_col <- safe_get_var(cut_data, "A10r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r2_row_3"]] <- list(
      label = "Patient is statin intolerant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r2_row_3"]] <- list(
      label = "Patient is statin intolerant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r2 not found"
    )
  }

  # Row 4: A10r3 == 1
  var_col <- safe_get_var(cut_data, "A10r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r3_row_4"]] <- list(
      label = "Patient refused statins",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r3_row_4"]] <- list(
      label = "Patient refused statins",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r3 not found"
    )
  }

  # Row 5: A10r4 == 1
  var_col <- safe_get_var(cut_data, "A10r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r4_row_5"]] <- list(
      label = "Statins are contraindicated for patient",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r4_row_5"]] <- list(
      label = "Statins are contraindicated for patient",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r4 not found"
    )
  }

  # Row 6: A10r5 == 1
  var_col <- safe_get_var(cut_data, "A10r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r5_row_6"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r5_row_6"]] <- list(
      label = "Patient not or unlikely to be compliant on statins",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r5 not found"
    )
  }

  # Row 7: A10r6 == 1
  var_col <- safe_get_var(cut_data, "A10r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10$data[[cut_name]][["A10r6_row_7"]] <- list(
      label = "Haven’t prescribed PCSK9s without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10$data[[cut_name]][["A10r6_row_7"]] <- list(
      label = "Haven’t prescribed PCSK9s without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10r6 not found"
    )
  }

}

all_tables[["a10"]] <- table_a10
print(paste("Generated frequency table: a10"))

# -----------------------------------------------------------------------------
# Table: b1 (mean_rows)
# Question: What percentage of your current patients are covered by each type of insurance?
# Rows: 8
# Source: b1
# -----------------------------------------------------------------------------

table_b1 <- list(
  tableId = "b1",
  questionId = "B1",
  questionText = "What percentage of your current patients are covered by each type of insurance?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "b1",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Responses should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b1$data[[cut_name]] <- list()
  table_b1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_b1$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r1"]] <- list(
      label = "Not insured",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r2"]] <- list(
      label = "Private insurance provided by employer / purchased in exchange",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r3"]] <- list(
      label = "Traditional Medicare (Medicare Part B Fee for Service)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r4"]] <- list(
      label = "Traditional Medicare with supplemental insurance",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through private payer)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through private payer)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r6"]] <- list(
      label = "Medicaid",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r7"]] <- list(
      label = "Veterans Administration (VA)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_b1$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1$data[[cut_name]][["B1r8"]] <- list(
      label = "Other",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

}

all_tables[["b1"]] <- table_b1
print(paste("Generated mean_rows table: b1"))

# -----------------------------------------------------------------------------
# Table: b3 (frequency)
# Question: Which of the following best describes where your primary practice is located?
# Rows: 4
# Source: b3
# -----------------------------------------------------------------------------

table_b3 <- list(
  tableId = "b3",
  questionId = "B3",
  questionText = "Which of the following best describes where your primary practice is located?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "b3",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b3$data[[cut_name]] <- list()
  table_b3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: B3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban or Suburban (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_1"]] <- list(
      label = "Urban or Suburban (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B3 not found"
    )
  }

  # Row 2: B3 == 1
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Urban",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_2"]] <- list(
      label = "Urban",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B3 not found"
    )
  }

  # Row 3: B3 == 2
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Suburban",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_3"]] <- list(
      label = "Suburban",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B3 not found"
    )
  }

  # Row 4: B3 == 3
  var_col <- safe_get_var(cut_data, "B3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b3$data[[cut_name]][["B3_row_4"]] <- list(
      label = "Rural",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b3$data[[cut_name]][["B3_row_4"]] <- list(
      label = "Rural",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B3 not found"
    )
  }

}

all_tables[["b3"]] <- table_b3
print(paste("Generated frequency table: b3"))

# -----------------------------------------------------------------------------
# Table: b4 (mean_rows)
# Question: How many physicians are in your practice?
# Rows: 1
# Source: b4
# -----------------------------------------------------------------------------

table_b4 <- list(
  tableId = "b4",
  questionId = "B4",
  questionText = "How many physicians are in your practice?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "b4",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "Respondents with primary specialty of Cardiologist, Internal Medicine/General Practitioner/Primary Care/Family Practice, Nephrologist, Endocrinologist, or Lipidologist.",
  userNote = "(Numeric open-end response; summary statistics—mean, median, standard deviation, min, max—are generated downstream.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      label = "How many physicians are in your practice?",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4$data[[cut_name]][["B4"]] <- list(
      label = "How many physicians are in your practice?",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

}

all_tables[["b4"]] <- table_b4
print(paste("Generated mean_rows table: b4"))

# -----------------------------------------------------------------------------
# Table: b4_binned (frequency) [DERIVED]
# Question: How many physicians are in your practice?
# Rows: 7
# Source: b4
# -----------------------------------------------------------------------------

table_b4_binned <- list(
  tableId = "b4_binned",
  questionId = "B4",
  questionText = "How many physicians are in your practice?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "b4",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "Respondents with primary specialty of Cardiologist, Internal Medicine/General Practitioner/Primary Care/Family Practice, Nephrologist, Endocrinologist, or Lipidologist.",
  userNote = "(Binned distribution derived for readability. Bins are inclusive and chosen for analytical clarity.)",
  tableSubtitle = "Binned distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b4_binned$data[[cut_name]] <- list()
  table_b4_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: B4 == 1
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_1"]] <- list(
      label = "1 physician",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_1"]] <- list(
      label = "1 physician",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 2: B4 in range [2-5]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 2 & as.numeric(var_col) <= 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_2"]] <- list(
      label = "2-5 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_2"]] <- list(
      label = "2-5 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 3: B4 in range [6-10]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 6 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_3"]] <- list(
      label = "6-10 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_3"]] <- list(
      label = "6-10 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 4: B4 in range [11-25]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_4"]] <- list(
      label = "11-25 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_4"]] <- list(
      label = "11-25 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 5: B4 in range [26-50]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 26 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_5"]] <- list(
      label = "26-50 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_5"]] <- list(
      label = "26-50 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 6: B4 in range [51-200]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 200, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_6"]] <- list(
      label = "51-200 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_6"]] <- list(
      label = "51-200 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 7: B4 in range [201-1000]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 201 & as.numeric(var_col) <= 1000, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_7"]] <- list(
      label = "201-1000 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_7"]] <- list(
      label = "201-1000 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

}

all_tables[["b4_binned"]] <- table_b4_binned
print(paste("Generated frequency table: b4_binned"))

# -----------------------------------------------------------------------------
# Table: b5 (frequency) [DERIVED]
# Question: How would you describe your specialty/training?
# Rows: 6
# Source: b5
# -----------------------------------------------------------------------------

table_b5 <- list(
  tableId = "b5",
  questionId = "B5",
  questionText = "How would you describe your specialty/training?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "b5",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "Respondents who selected Internal Medicine / General Practitioner / Primary Care / Family Practice at S2",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 == 2")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_b5$data[[cut_name]] <- list()
  table_b5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any of the following specialties (NET) (components: B5r1, B5r2, B5r3, B5r4, B5r5)
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

    table_b5$data[[cut_name]][["_NET_B5_SpecialtyAny_row_1"]] <- list(
      label = "Any of the following specialties (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
      error = "Variable B5r5 not found"
    )
  }

}

all_tables[["b5"]] <- table_b5
print(paste("Generated frequency table: b5"))

# -----------------------------------------------------------------------------
# Table: qcard_specialty (frequency)
# Question: What is your primary specialty/role?
# Rows: 2
# -----------------------------------------------------------------------------

table_qcard_specialty <- list(
  tableId = "qcard_specialty",
  questionId = "qCARD_SPECIALTY",
  questionText = "What is your primary specialty/role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Derived segmentation: cardiology vs nephrology/endocrinology/lipidology)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qcard_specialty$data[[cut_name]] <- list()
  table_qcard_specialty$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qCARD_SPECIALTY == 1
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qcard_specialty$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qcard_specialty$data[[cut_name]][["qCARD_SPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

  # Row 2: qCARD_SPECIALTY == 2
  var_col <- safe_get_var(cut_data, "qCARD_SPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qcard_specialty$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "Nephrologist / Endocrinologist / Lipidologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qcard_specialty$data[[cut_name]][["qCARD_SPECIALTY_row_2"]] <- list(
      label = "Nephrologist / Endocrinologist / Lipidologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qCARD_SPECIALTY not found"
    )
  }

}

all_tables[["qcard_specialty"]] <- table_qcard_specialty
print(paste("Generated frequency table: qcard_specialty"))

# -----------------------------------------------------------------------------
# Table: qconsent (frequency)
# Question: If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below:
# Rows: 2
# Source: qconsent
# -----------------------------------------------------------------------------

table_qconsent <- list(
  tableId = "qconsent",
  questionId = "QCONSENT",
  questionText = "If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below:",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qconsent",
  surveySection = "CONSENT",
  baseText = "",
  userNote = "(Select one; 'Yes' indicates willingness to be contacted for follow-up research)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
      error = "Variable QCONSENT not found"
    )
  }

}

all_tables[["qconsent"]] <- table_qconsent
print(paste("Generated frequency table: qconsent"))

# -----------------------------------------------------------------------------
# Table: qspecialty (frequency)
# Question: What is your primary specialty/role?
# Rows: 3
# -----------------------------------------------------------------------------

table_qspecialty <- list(
  tableId = "qspecialty",
  questionId = "qSPECIALTY",
  questionText = "What is your primary specialty/role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qspecialty$data[[cut_name]] <- list()
  table_qspecialty$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qSPECIALTY == 1
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 2: qSPECIALTY == 2
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 3: qSPECIALTY == 3
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "Nurse Practitioner / Physician Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "Nurse Practitioner / Physician Assistant",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

}

all_tables[["qspecialty"]] <- table_qspecialty
print(paste("Generated frequency table: qspecialty"))

# -----------------------------------------------------------------------------
# Table: qtype_of_card (frequency)
# Question: What type of Cardiologist are you primarily?
# Rows: 3
# Source: qtype_of_card
# -----------------------------------------------------------------------------

table_qtype_of_card <- list(
  tableId = "qtype_of_card",
  questionId = "qTYPE_OF_CARD",
  questionText = "What type of Cardiologist are you primarily?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qtype_of_card",
  surveySection = "SCREENER",
  baseText = "Cardiologists",
  userNote = "(Asked only of respondents who identified their primary specialty as Cardiologist)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qtype_of_card$data[[cut_name]] <- list()
  table_qtype_of_card$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qTYPE_OF_CARD == 1
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
      label = "Interventional Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 2: qTYPE_OF_CARD == 2
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_2"]] <- list(
      label = "General Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

  # Row 3: qTYPE_OF_CARD == 3
  var_col <- safe_get_var(cut_data, "qTYPE_OF_CARD")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qtype_of_card$data[[cut_name]][["qTYPE_OF_CARD_row_3"]] <- list(
      label = "Preventative Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qTYPE_OF_CARD not found"
    )
  }

}

all_tables[["qtype_of_card"]] <- table_qtype_of_card
print(paste("Generated frequency table: qtype_of_card"))

# -----------------------------------------------------------------------------
# Table: region (frequency) [DERIVED]
# Question: Region
# Rows: 7
# Source: region
# -----------------------------------------------------------------------------

table_region <- list(
  tableId = "region",
  questionId = "Region",
  questionText = "Region",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "region",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Administrative: respondent region. Codes 1-4 are standard U.S. regions; code 6 indicates an invalid/missing region code.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_region$data[[cut_name]] <- list()
  table_region$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Region IN (1, 2, 3, 4)
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3, 4), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "U.S. Regions (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_1"]] <- list(
      label = "U.S. Regions (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 2: Region == 1
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "Northeast",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_2"]] <- list(
      label = "Northeast",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 3: Region == 2
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "South",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_3"]] <- list(
      label = "South",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 4: Region == 3
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "Midwest",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_4"]] <- list(
      label = "Midwest",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 5: Region == 4
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "West",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_5"]] <- list(
      label = "West",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 6: Region == 5
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_6"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

  # Row 7: Region == 6
  var_col <- safe_get_var(cut_data, "Region")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_region$data[[cut_name]][["Region_row_7"]] <- list(
      label = "Invalid Region",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_region$data[[cut_name]][["Region_row_7"]] <- list(
      label = "Invalid Region",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

}

all_tables[["region"]] <- table_region
print(paste("Generated frequency table: region"))

# -----------------------------------------------------------------------------
# Table: us_state (frequency)
# Question: State of main practice location (derived from ZIP code)
# Rows: 53
# Source: us_state
# -----------------------------------------------------------------------------

table_us_state <- list(
  tableId = "us_state",
  questionId = "US_State",
  questionText = "State of main practice location (derived from ZIP code)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "us_state",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Derived from ZIP code)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_us_state$data[[cut_name]] <- list()
  table_us_state$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: US_State == 1
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Alaska",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State == 2
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Alabama",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State == 3
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "Arkansas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State == 4
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "Arizona",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == 5
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_5"]] <- list(
      label = "California",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 6: US_State == 6
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_6"]] <- list(
      label = "Colorado",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 7: US_State == 7
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_7"]] <- list(
      label = "Connecticut",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 8: US_State == 8
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_8"]] <- list(
      label = "District of Columbia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 9: US_State == 9
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_9"]] <- list(
      label = "Delaware",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 10: US_State == 10
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_10"]] <- list(
      label = "Florida",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 11: US_State == 11
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_11"]] <- list(
      label = "Georgia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 12: US_State == 12
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_12"]] <- list(
      label = "Hawaii",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 13: US_State == 13
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_13"]] <- list(
      label = "Iowa",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 14: US_State == 14
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_14"]] <- list(
      label = "Idaho",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 15: US_State == 15
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_15"]] <- list(
      label = "Illinois",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 16: US_State == 16
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_16"]] <- list(
      label = "Indiana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 17: US_State == 17
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_17"]] <- list(
      label = "Kansas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 18: US_State == 18
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 18, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_18"]] <- list(
      label = "Kentucky",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 19: US_State == 19
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_19"]] <- list(
      label = "Louisiana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 20: US_State == 20
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_20"]] <- list(
      label = "Massachusetts",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 21: US_State == 21
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_21"]] <- list(
      label = "Maryland",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_21"]] <- list(
      label = "Maryland",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 22: US_State == 22
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_22"]] <- list(
      label = "Maine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_22"]] <- list(
      label = "Maine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 23: US_State == 23
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 23, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_23"]] <- list(
      label = "Michigan",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_23"]] <- list(
      label = "Michigan",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 24: US_State == 24
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_24"]] <- list(
      label = "Minnesota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_24"]] <- list(
      label = "Minnesota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 25: US_State == 25
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_25"]] <- list(
      label = "Missouri",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_25"]] <- list(
      label = "Missouri",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 26: US_State == 26
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_26"]] <- list(
      label = "Mississippi",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_26"]] <- list(
      label = "Mississippi",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 27: US_State == 27
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_27"]] <- list(
      label = "Montana",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_27"]] <- list(
      label = "Montana",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 28: US_State == 28
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_28"]] <- list(
      label = "North Carolina",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_28"]] <- list(
      label = "North Carolina",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 29: US_State == 29
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_29"]] <- list(
      label = "North Dakota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_29"]] <- list(
      label = "North Dakota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 30: US_State == 30
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_30"]] <- list(
      label = "Nebraska",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_30"]] <- list(
      label = "Nebraska",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 31: US_State == 31
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_31"]] <- list(
      label = "New Hampshire",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_31"]] <- list(
      label = "New Hampshire",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 32: US_State == 32
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_32"]] <- list(
      label = "New Jersey",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_32"]] <- list(
      label = "New Jersey",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 33: US_State == 33
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 33, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_33"]] <- list(
      label = "New Mexico",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_33"]] <- list(
      label = "New Mexico",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 34: US_State == 34
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_34"]] <- list(
      label = "Nevada",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_34"]] <- list(
      label = "Nevada",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 35: US_State == 35
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_35"]] <- list(
      label = "New York",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_35"]] <- list(
      label = "New York",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 36: US_State == 36
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 36, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_36"]] <- list(
      label = "Ohio",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_36"]] <- list(
      label = "Ohio",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 37: US_State == 37
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_37"]] <- list(
      label = "Oklahoma",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_37"]] <- list(
      label = "Oklahoma",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 38: US_State == 38
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 38, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_38"]] <- list(
      label = "Oregon",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_38"]] <- list(
      label = "Oregon",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 39: US_State == 39
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 39, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_39"]] <- list(
      label = "Pennsylvania",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_39"]] <- list(
      label = "Pennsylvania",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 40: US_State == 40
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_40"]] <- list(
      label = "Rhode Island",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_40"]] <- list(
      label = "Rhode Island",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 41: US_State == 41
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 41, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_41"]] <- list(
      label = "South Carolina",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_41"]] <- list(
      label = "South Carolina",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 42: US_State == 42
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 42, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_42"]] <- list(
      label = "South Dakota",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_42"]] <- list(
      label = "South Dakota",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 43: US_State == 43
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 43, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_43"]] <- list(
      label = "Tennessee",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_43"]] <- list(
      label = "Tennessee",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 44: US_State == 44
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 44, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_44"]] <- list(
      label = "Texas",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_44"]] <- list(
      label = "Texas",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 45: US_State == 45
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 45, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_45"]] <- list(
      label = "Utah",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_45"]] <- list(
      label = "Utah",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 46: US_State == 46
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 46, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_46"]] <- list(
      label = "Virginia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_46"]] <- list(
      label = "Virginia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 47: US_State == 47
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 47, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_47"]] <- list(
      label = "Vermont",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_47"]] <- list(
      label = "Vermont",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 48: US_State == 48
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 48, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_48"]] <- list(
      label = "Washington",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_48"]] <- list(
      label = "Washington",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 49: US_State == 49
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_49"]] <- list(
      label = "Wisconsin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_49"]] <- list(
      label = "Wisconsin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 50: US_State == 50
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_50"]] <- list(
      label = "West Virginia",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_50"]] <- list(
      label = "West Virginia",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 51: US_State == 51
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 51, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_51"]] <- list(
      label = "Wyoming",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_51"]] <- list(
      label = "Wyoming",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 52: US_State == 52
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 52, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_52"]] <- list(
      label = "Other",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_52"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 53: US_State == 53
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 53, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state$data[[cut_name]][["US_State_row_53"]] <- list(
      label = "Invalid State",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state$data[[cut_name]][["US_State_row_53"]] <- list(
      label = "Invalid State",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

}

all_tables[["us_state"]] <- table_us_state
print(paste("Generated frequency table: us_state"))

# Table: s1 (excluded: Administrative screener / consent question (used to determine eligibility/termination). Move to reference sheet; not included in main analytic outputs.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: s1 (frequency)
# Question: You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and/or product complaints that are raised during the course of market research surveys. Are you happy to proceed on this basis?
# Rows: 3
# Source: s1
# -----------------------------------------------------------------------------

table_s1 <- list(
  tableId = "s1",
  questionId = "S1",
  questionText = "You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and/or product complaints that are raised during the course of market research surveys. Are you happy to proceed on this basis?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s1",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Consent/permission regarding reporting adverse events; respondents selecting \"I don’t want to proceed\" were terminated)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative screener / consent question (used to determine eligibility/termination). Move to reference sheet; not included in main analytic outputs.",
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      label = "I don’t want to proceed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I don’t want to proceed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1 not found"
    )
  }

}

all_tables[["s1"]] <- table_s1
print(paste("Generated frequency table: s1"))

# Table: s4 (excluded: Screener variable with termination: selections 'Board Eligible' (1) or 'Neither' (3) triggered screen-out; only 'Board Certified' (2) respondents continued. Variable is therefore effectively trivial among the study sample and moved to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: s4 (frequency)
# Question: Are you currently board certified or eligible in your specialty?
# Rows: 3
# Source: s4
# -----------------------------------------------------------------------------

table_s4 <- list(
  tableId = "s4",
  questionId = "S4",
  questionText = "Are you currently board certified or eligible in your specialty?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s4",
  surveySection = "SCREENER",
  baseText = "Respondents whose primary specialty (S2) is one of: Cardiologist (1), Internal Medicine/GP/Primary Care (2), Nephrologist (3), Endocrinologist (4), or Lipidologist (5).",
  userNote = "(Responses of 'Board Eligible' or 'Neither' triggered screen-out; only 'Board Certified' respondents continued)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Screener variable with termination: selections 'Board Eligible' (1) or 'Neither' (3) triggered screen-out; only 'Board Certified' (2) respondents continued. Variable is therefore effectively trivial among the study sample and moved to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 %in% c(1, 2, 3, 4, 5)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_s4$data[[cut_name]] <- list()
  table_s4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S4 == 1
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board Eligible",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board Eligible",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

  # Row 2: S4 == 2
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Certified",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Certified",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

  # Row 3: S4 == 3
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Neither",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Neither",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

}

all_tables[["s4"]] <- table_s4
print(paste("Generated frequency table: s4"))

# Table: a4 (excluded: Original combined mean_rows (LAST + NEXT 100) split into two clearer mean_rows tables (a4_last100 and a4_next100) for readability. The original is moved to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a4 (mean_rows)
# Question: In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Includes LAST 100 as reference)
# Rows: 14
# -----------------------------------------------------------------------------

table_a4 <- list(
  tableId = "a4",
  questionId = "A4",
  questionText = "In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Includes LAST 100 as reference)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Combined table split into separate LAST and NEXT 100 views for publication; filterValue is ignored for mean_rows.)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Original combined mean_rows (LAST + NEXT 100) split into two clearer mean_rows tables (a4_last100 and a4_next100) for readability. The original is moved to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a4$data[[cut_name]] <- list()
  table_a4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy) - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r1c1"]] <- list(
      label = "Statin only (i.e., no additional therapy) - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran) - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r2c1"]] <- list(
      label = "Leqvio (inclisiran) - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab) - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r3c1"]] <- list(
      label = "Praluent (alirocumab) - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab) - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r4c1"]] <- list(
      label = "Repatha (evolocumab) - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r5c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r6c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other - LAST 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r7c1"]] <- list(
      label = "Other - LAST 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy) - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r1c2"]] <- list(
      label = "Statin only (i.e., no additional therapy) - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran) - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r2c2"]] <- list(
      label = "Leqvio (inclisiran) - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab) - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r3c2"]] <- list(
      label = "Praluent (alirocumab) - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab) - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r4c2"]] <- list(
      label = "Repatha (evolocumab) - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r5c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r6c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
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

    table_a4$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other - NEXT 100",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4r7c2"]] <- list(
      label = "Other - NEXT 100",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4r7c2 not found"
    )
  }

}

all_tables[["a4"]] <- table_a4
print(paste("Generated mean_rows table: a4"))

# Table: a4b_nexletol_bempedoic_acid_ (excluded: Overview combined table excluded from main sheet — split into two derived mean_rows tables (Before / After) for readability) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a4b_nexletol_bempedoic_acid_ (mean_rows)
# Question: For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…
# Rows: 2
# -----------------------------------------------------------------------------

table_a4b_nexletol_bempedoic_acid_ <- list(
  tableId = "a4b_nexletol_bempedoic_acid_",
  questionId = "A4b",
  questionText = "For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated > 0% 'Without a statin' for Nexletol in A4a",
  userNote = "(Excluded from main sheet; moved to reference sheet)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview combined table excluded from main sheet — split into two derived mean_rows tables (Before / After) for readability",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4ar5c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4b_nexletol_bempedoic_acid_$data[[cut_name]] <- list()
  table_a4b_nexletol_bempedoic_acid_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4br5c1 (numeric summary)
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

    table_a4b_nexletol_bempedoic_acid_$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (First line)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_nexletol_bempedoic_acid_$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Before any other lipid-lowering therapy (First line)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br5c1 not found"
    )
  }

  # Row 2: A4br5c2 (numeric summary)
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

    table_a4b_nexletol_bempedoic_acid_$data[[cut_name]][["A4br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4b_nexletol_bempedoic_acid_$data[[cut_name]][["A4br5c2"]] <- list(
      label = "After trying another lipid-lowering therapy",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4br5c2 not found"
    )
  }

}

all_tables[["a4b_nexletol_bempedoic_acid_"]] <- table_a4b_nexletol_bempedoic_acid_
print(paste("Generated mean_rows table: a4b_nexletol_bempedoic_acid_"))

# Table: a8 (excluded: Overview grid split into T2B comparison tables and per-product detail tables for readability.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a8 (frequency)
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 75
# -----------------------------------------------------------------------------

table_a8 <- list(
  tableId = "a8",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Original grid excluded; see derived T2B comparison tables and per-product detail tables.)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview grid split into T2B comparison tables and per-product detail tables for readability.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8$data[[cut_name]] <- list()
  table_a8$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r1c1 == 1
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 2: A8r1c1 == 2
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 3: A8r1c1 == 3
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c1_row_3"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 4: A8r1c1 == 4
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c1_row_4"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 5: A8r1c1 == 5
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c1_row_5"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c1 not found"
    )
  }

  # Row 6: A8r1c2 == 1
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c2_row_6"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 7: A8r1c2 == 2
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 8: A8r1c2 == 3
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c2_row_8"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 9: A8r1c2 == 4
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c2_row_9"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 10: A8r1c2 == 5
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c2_row_10"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c2 not found"
    )
  }

  # Row 11: A8r1c3 == 1
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c3_row_11"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c3_row_11"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 12: A8r1c3 == 2
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c3_row_12"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c3_row_12"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 13: A8r1c3 == 3
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 14: A8r1c3 == 4
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c3_row_14"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c3_row_14"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 15: A8r1c3 == 5
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r1c3_row_15"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r1c3 not found"
    )
  }

  # Row 16: A8r2c1 == 1
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c1_row_16"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c1_row_16"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 17: A8r2c1 == 2
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c1_row_17"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c1_row_17"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 18: A8r2c1 == 3
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c1_row_18"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c1_row_18"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 19: A8r2c1 == 4
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c1_row_19"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c1_row_19"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 20: A8r2c1 == 5
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c1_row_20"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c1_row_20"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c1 not found"
    )
  }

  # Row 21: A8r2c2 == 1
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c2_row_21"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c2_row_21"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 22: A8r2c2 == 2
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c2_row_22"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c2_row_22"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 23: A8r2c2 == 3
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c2_row_23"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c2_row_23"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 24: A8r2c2 == 4
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c2_row_24"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c2_row_24"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 25: A8r2c2 == 5
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c2_row_25"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c2_row_25"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c2 not found"
    )
  }

  # Row 26: A8r2c3 == 1
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c3_row_26"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c3_row_26"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 27: A8r2c3 == 2
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c3_row_27"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c3_row_27"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 28: A8r2c3 == 3
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c3_row_28"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c3_row_28"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 29: A8r2c3 == 4
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c3_row_29"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c3_row_29"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 30: A8r2c3 == 5
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r2c3_row_30"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r2c3_row_30"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r2c3 not found"
    )
  }

  # Row 31: A8r3c1 == 1
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c1_row_31"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c1_row_31"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 32: A8r3c1 == 2
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c1_row_32"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c1_row_32"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 33: A8r3c1 == 3
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c1_row_33"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c1_row_33"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 34: A8r3c1 == 4
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c1_row_34"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c1_row_34"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 35: A8r3c1 == 5
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c1_row_35"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c1_row_35"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c1 not found"
    )
  }

  # Row 36: A8r3c2 == 1
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c2_row_36"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c2_row_36"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 37: A8r3c2 == 2
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c2_row_37"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c2_row_37"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 38: A8r3c2 == 3
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c2_row_38"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c2_row_38"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 39: A8r3c2 == 4
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c2_row_39"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c2_row_39"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 40: A8r3c2 == 5
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c2_row_40"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c2_row_40"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c2 not found"
    )
  }

  # Row 41: A8r3c3 == 1
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c3_row_41"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c3_row_41"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 42: A8r3c3 == 2
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c3_row_42"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c3_row_42"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 43: A8r3c3 == 3
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c3_row_43"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c3_row_43"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 44: A8r3c3 == 4
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c3_row_44"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c3_row_44"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 45: A8r3c3 == 5
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r3c3_row_45"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r3c3_row_45"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r3c3 not found"
    )
  }

  # Row 46: A8r4c1 == 1
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c1_row_46"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c1_row_46"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 47: A8r4c1 == 2
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c1_row_47"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c1_row_47"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 48: A8r4c1 == 3
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c1_row_48"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c1_row_48"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 49: A8r4c1 == 4
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c1_row_49"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c1_row_49"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 50: A8r4c1 == 5
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c1_row_50"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c1_row_50"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c1 not found"
    )
  }

  # Row 51: A8r4c2 == 1
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c2_row_51"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c2_row_51"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 52: A8r4c2 == 2
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c2_row_52"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c2_row_52"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 53: A8r4c2 == 3
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c2_row_53"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c2_row_53"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 54: A8r4c2 == 4
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c2_row_54"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c2_row_54"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 55: A8r4c2 == 5
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c2_row_55"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c2_row_55"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c2 not found"
    )
  }

  # Row 56: A8r4c3 == 1
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c3_row_56"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c3_row_56"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 57: A8r4c3 == 2
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c3_row_57"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c3_row_57"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 58: A8r4c3 == 3
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c3_row_58"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c3_row_58"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 59: A8r4c3 == 4
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c3_row_59"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c3_row_59"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 60: A8r4c3 == 5
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r4c3_row_60"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r4c3_row_60"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r4c3 not found"
    )
  }

  # Row 61: A8r5c1 == 1
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c1_row_61"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c1_row_61"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 62: A8r5c1 == 2
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c1_row_62"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c1_row_62"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 63: A8r5c1 == 3
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c1_row_63"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c1_row_63"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 64: A8r5c1 == 4
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c1_row_64"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c1_row_64"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 65: A8r5c1 == 5
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c1_row_65"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c1_row_65"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c1 not found"
    )
  }

  # Row 66: A8r5c2 == 1
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c2_row_66"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c2_row_66"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 67: A8r5c2 == 2
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c2_row_67"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c2_row_67"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 68: A8r5c2 == 3
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c2_row_68"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c2_row_68"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 69: A8r5c2 == 4
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c2_row_69"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c2_row_69"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 70: A8r5c2 == 5
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c2_row_70"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c2_row_70"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c2 not found"
    )
  }

  # Row 71: A8r5c3 == 1
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c3_row_71"]] <- list(
      label = "Not at all likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c3_row_71"]] <- list(
      label = "Not at all likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 72: A8r5c3 == 2
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c3_row_72"]] <- list(
      label = "Slightly likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c3_row_72"]] <- list(
      label = "Slightly likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 73: A8r5c3 == 3
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c3_row_73"]] <- list(
      label = "Somewhat likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c3_row_73"]] <- list(
      label = "Somewhat likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 74: A8r5c3 == 4
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c3_row_74"]] <- list(
      label = "Very likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c3_row_74"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

  # Row 75: A8r5c3 == 5
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8r5c3_row_75"]] <- list(
      label = "Extremely likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8r5c3_row_75"]] <- list(
      label = "Extremely likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8r5c3 not found"
    )
  }

}

all_tables[["a8"]] <- table_a8
print(paste("Generated frequency table: a8"))

# Table: a9 (excluded: Overview split into product-level detail tables and an 'Any issues (NET)' comparison table for clarity.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a9 (frequency)
# Question: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Rows: 12
# -----------------------------------------------------------------------------

table_a9 <- list(
  tableId = "a9",
  questionId = "A9",
  questionText = "To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one for each product)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview split into product-level detail tables and an 'Any issues (NET)' comparison table for clarity.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a9$data[[cut_name]] <- list()
  table_a9$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A9c1 == 1
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_1"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 2: A9c1 == 2
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_2"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 3: A9c1 == 3
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_3"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 4: A9c1 == 4
  var_col <- safe_get_var(cut_data, "A9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c1_row_4"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c1 not found"
    )
  }

  # Row 5: A9c2 == 1
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_5"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 6: A9c2 == 2
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_6"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 7: A9c2 == 3
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_7"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 8: A9c2 == 4
  var_col <- safe_get_var(cut_data, "A9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c2_row_8"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c2 not found"
    )
  }

  # Row 9: A9c3 == 1
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_9"]] <- list(
      label = "No issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_9"]] <- list(
      label = "No issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 10: A9c3 == 2
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_10"]] <- list(
      label = "Some issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_10"]] <- list(
      label = "Some issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 11: A9c3 == 3
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Significant issues",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_11"]] <- list(
      label = "Significant issues",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

  # Row 12: A9c3 == 4
  var_col <- safe_get_var(cut_data, "A9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9$data[[cut_name]][["A9c3_row_12"]] <- list(
      label = "Haven’t prescribed without a statin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9c3 not found"
    )
  }

}

all_tables[["a9"]] <- table_a9
print(paste("Generated frequency table: a9"))

# Table: qlist_priority_account (excluded: Administrative recruitment/segmentation flag (priority account). This is not a substantive survey question — move to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qlist_priority_account (frequency)
# Question: LIST PRIORITY ACCOUNT
# Rows: 2
# Source: qlist_priority_account
# -----------------------------------------------------------------------------

table_qlist_priority_account <- list(
  tableId = "qlist_priority_account",
  questionId = "qLIST_PRIORITY_ACCOUNT",
  questionText = "LIST PRIORITY ACCOUNT",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qlist_priority_account",
  surveySection = "SPECIFICATIONS",
  baseText = "",
  userNote = "(Administrative recruitment tag used for quotas/segmentation — excluded from main outputs)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative recruitment/segmentation flag (priority account). This is not a substantive survey question — move to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qlist_priority_account$data[[cut_name]] <- list()
  table_qlist_priority_account$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qLIST_PRIORITY_ACCOUNT == 1
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_priority_account$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "Priority account",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_priority_account$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_1"]] <- list(
      label = "Priority account",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

  # Row 2: qLIST_PRIORITY_ACCOUNT == 2
  var_col <- safe_get_var(cut_data, "qLIST_PRIORITY_ACCOUNT")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_priority_account$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "Not priority account",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_priority_account$data[[cut_name]][["qLIST_PRIORITY_ACCOUNT_row_2"]] <- list(
      label = "Not priority account",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_PRIORITY_ACCOUNT not found"
    )
  }

}

all_tables[["qlist_priority_account"]] <- table_qlist_priority_account
print(paste("Generated frequency table: qlist_priority_account"))

# Table: qlist_tier (excluded: Administrative segmentation variable (sampling/list tier) — not substantive survey content; move to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qlist_tier (frequency)
# Question: LIST TIER
# Rows: 4
# Source: qlist_tier
# -----------------------------------------------------------------------------

table_qlist_tier <- list(
  tableId = "qlist_tier",
  questionId = "qLIST_TIER",
  questionText = "LIST TIER",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qlist_tier",
  surveySection = "",
  baseText = "",
  userNote = "(Administrative sampling variable used for recruitment; exclude from main reporting)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative segmentation variable (sampling/list tier) — not substantive survey content; move to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qlist_tier$data[[cut_name]] <- list()
  table_qlist_tier$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qLIST_TIER == 1
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_1"]] <- list(
      label = "TIER 1",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 2: qLIST_TIER == 2
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_2"]] <- list(
      label = "TIER 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 3: qLIST_TIER == 3
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_3"]] <- list(
      label = "TIER 3",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_TIER not found"
    )
  }

  # Row 4: qLIST_TIER == 4
  var_col <- safe_get_var(cut_data, "qLIST_TIER")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qlist_tier$data[[cut_name]][["qLIST_TIER_row_4"]] <- list(
      label = "TIER 4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qLIST_TIER not found"
    )
  }

}

all_tables[["qlist_tier"]] <- table_qlist_tier
print(paste("Generated frequency table: qlist_tier"))

# Table: qon_list_off_list (excluded: Administrative / recruitment metadata (ON-LIST / OFF-LIST tag). Not a survey question asked of respondents; move to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qon_list_off_list (frequency)
# Question: qON_LIST_OFF_LIST: ON-LIST/OFF-LIST
# Rows: 6
# Source: qon_list_off_list
# -----------------------------------------------------------------------------

table_qon_list_off_list <- list(
  tableId = "qon_list_off_list",
  questionId = "qON_LIST_OFF_LIST",
  questionText = "qON_LIST_OFF_LIST: ON-LIST/OFF-LIST",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qon_list_off_list",
  surveySection = "",
  baseText = "",
  userNote = "(Recruitment/source tag indicating whether respondent was on a client priority list or off-list; administrative variable — exclude from main publication tables)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative / recruitment metadata (ON-LIST / OFF-LIST tag). Not a survey question asked of respondents; move to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qon_list_off_list$data[[cut_name]] <- list()
  table_qon_list_off_list$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qON_LIST_OFF_LIST == 1
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "CARD ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "CARD ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 2: qON_LIST_OFF_LIST == 2
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "CARD OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "CARD OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 3: qON_LIST_OFF_LIST == 3
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "PCP ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 4: qON_LIST_OFF_LIST == 4
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "PCP OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 5: qON_LIST_OFF_LIST == 5
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NPPA ON-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "NPPA ON-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 6: qON_LIST_OFF_LIST == 6
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NPPA OFF-LIST",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "NPPA OFF-LIST",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

}

all_tables[["qon_list_off_list"]] <- table_qon_list_off_list
print(paste("Generated frequency table: qon_list_off_list"))

# =============================================================================
# Significance Testing Pass
# =============================================================================

print("Running significance testing...")

# Check for dual threshold mode (uppercase = high conf, lowercase = low conf)
has_dual_thresholds <- exists("p_threshold_high") && exists("p_threshold_low")

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

        other_letter <- cut_stat_letters[[other_cut]]

        if (table_type == "frequency") {
          # Skip category headers and rows with null values (e.g., visual grouping rows)
          if (is.null(row_data$n) || is.null(row_data$count) ||
              is.null(other_data$n) || is.null(other_data$count)) next

          # Calculate p-value directly for dual threshold support
          p1 <- row_data$count / row_data$n
          p2 <- other_data$count / other_data$n
          n1 <- row_data$n
          n2 <- other_data$n

          # Skip if both proportions are same or undefined
          if (is.na(p1) || is.na(p2)) next
          if ((p1 == 0 && p2 == 0) || (p1 == 1 && p2 == 1)) next

          # Calculate p-value (unpooled z-test)
          se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
          if (is.na(se) || se == 0) next
          z <- (p1 - p2) / se
          p_value <- 2 * (1 - pnorm(abs(z)))

          # Only add letter if this column is higher
          if (p1 > p2) {
            if (has_dual_thresholds) {
              # Dual mode: uppercase for high confidence, lowercase for low-only
              if (p_value < p_threshold_high) {
                sig_higher <- c(sig_higher, toupper(other_letter))
              } else if (p_value < p_threshold_low) {
                sig_higher <- c(sig_higher, tolower(other_letter))
              }
            } else {
              # Single threshold mode
              if (p_value < p_threshold) {
                sig_higher <- c(sig_higher, other_letter)
              }
            }
          }
        } else if (table_type == "mean_rows") {
          # Welch's t-test using summary statistics (n, mean, sd)
          # These are stored in each row during mean_rows table generation
          if (!is.na(row_data$mean) && !is.na(other_data$mean) &&
              !is.null(row_data$n) && !is.null(other_data$n) &&
              !is.null(row_data$sd) && !is.null(other_data$sd)) {

            # Get minimum base from config (defaults to 0 = no minimum)
            min_base <- if (exists("stat_min_base")) stat_min_base else 0

            result <- sig_test_mean_summary(
              row_data$n, row_data$mean, row_data$sd,
              other_data$n, other_data$mean, other_data$sd,
              min_base
            )

            if (is.list(result) && !is.na(result$p_value) && result$higher) {
              if (has_dual_thresholds) {
                if (result$p_value < p_threshold_high) {
                  sig_higher <- c(sig_higher, toupper(other_letter))
                } else if (result$p_value < p_threshold_low) {
                  sig_higher <- c(sig_higher, tolower(other_letter))
                }
              } else {
                if (result$p_value < p_threshold) {
                  sig_higher <- c(sig_higher, other_letter)
                }
              }
            }
          }
        }
      }

      # Compare to Total
      if ("Total" %in% names(tbl$data) && cut_name != "Total") {
        total_data <- tbl$data[["Total"]][[row_key]]
        if (!is.null(total_data) && is.null(total_data$error)) {
          sig_vs_total <- NA

          if (table_type == "frequency") {
            # Skip category headers and rows with null values
            if (is.null(row_data$n) || is.null(row_data$count) ||
                is.null(total_data$n) || is.null(total_data$count)) {
              sig_vs_total <- NA
            } else {
              p1 <- row_data$count / row_data$n
              p2 <- total_data$count / total_data$n
              n1 <- row_data$n
              n2 <- total_data$n

              if (!is.na(p1) && !is.na(p2) && !((p1 == 0 && p2 == 0) || (p1 == 1 && p2 == 1))) {
                se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
                if (!is.na(se) && se > 0) {
                  z <- (p1 - p2) / se
                  p_value <- 2 * (1 - pnorm(abs(z)))
                  threshold_to_use <- if (has_dual_thresholds) p_threshold_high else p_threshold
                  if (p_value < threshold_to_use) {
                    sig_vs_total <- if (p1 > p2) "higher" else "lower"
                  }
                }
              }
            }
          } else if (table_type == "mean_rows") {
            # Welch's t-test vs Total using summary statistics
            if (!is.na(row_data$mean) && !is.na(total_data$mean) &&
                !is.null(row_data$n) && !is.null(total_data$n) &&
                !is.null(row_data$sd) && !is.null(total_data$sd)) {

              min_base <- if (exists("stat_min_base")) stat_min_base else 0

              result <- sig_test_mean_summary(
                row_data$n, row_data$mean, row_data$sd,
                total_data$n, total_data$mean, total_data$sd,
                min_base
              )

              if (is.list(result) && !is.na(result$p_value)) {
                threshold_to_use <- if (has_dual_thresholds) p_threshold_high else p_threshold
                if (result$p_value < threshold_to_use) {
                  sig_vs_total <- if (result$higher) "higher" else "lower"
                }
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
    generatedAt = "2026-02-08T06:42:08.966Z",
    tableCount = 88,
    cutCount = 18,
    significanceTest = "unpooled z-test for column proportions",
    meanSignificanceTest = "two-sample t-test",
    significanceThresholds = c(0.1),
    significanceLevel = 0.1,
    totalRespondents = nrow(data),
    bannerGroups = fromJSON('[{"groupName":"Total","columns":[{"name":"Total","statLetter":"T"}]},{"groupName":"HCP Specialty","columns":[{"name":"Cards","statLetter":"A"},{"name":"PCPs","statLetter":"B"},{"name":"Other","statLetter":"C"}]},{"groupName":"HCP Role","columns":[{"name":"Physician","statLetter":"D"},{"name":"APP","statLetter":"E"}]},{"groupName":"Volume of ASCVD Patients","columns":[{"name":"150+ (Higher)","statLetter":"F"},{"name":"20-149 (Lower)","statLetter":"G"}]},{"groupName":"Tiers","columns":[{"name":"Tier 1","statLetter":"H"},{"name":"Tier 2","statLetter":"I"},{"name":"Tier 3","statLetter":"J"},{"name":"Tier 4","statLetter":"K"}]},{"groupName":"Currently Prescribe Leqvio without a Statin and Before Other Therapies","columns":[{"name":"Yes","statLetter":"L"},{"name":"No","statLetter":"M"}]},{"groupName":"Leqvio Rx\'ing Would Increase with New PCSK9s Indication","columns":[{"name":"All Leqvio Prescribing","statLetter":"N"},{"name":"Leqvio Rx\'ing without a Statin & Before Other Therapies","statLetter":"O"}]},{"groupName":"Primary Practice Setting","columns":[{"name":"Academic / Univ. Hospital","statLetter":"P"},{"name":"Total Community","statLetter":"Q"}]}]'),
    comparisonGroups = fromJSON('["A/B/C","D/E","F/G","H/I/J/K","L/M","N/O","P/Q"]')
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