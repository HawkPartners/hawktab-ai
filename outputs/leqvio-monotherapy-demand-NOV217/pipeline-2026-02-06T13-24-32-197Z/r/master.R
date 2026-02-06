# HawkTab AI - R Script V2
# Session: pipeline-2026-02-06T13-24-32-197Z
# Generated: 2026-02-06T14:28:08.636Z
# Tables: 94 (0 skipped due to validation errors)
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
,  `APP` = with(data, S2a == 1)
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
# Table: s1 (frequency)
# Question: You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential. Are you happy to proceed on this basis?
# Rows: 4
# Source: s1
# -----------------------------------------------------------------------------

table_s1 <- list(
  tableId = "s1",
  questionId = "S1",
  questionText = "You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential.\n\nAre you happy to proceed on this basis?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s1",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Selecting \"I don't want to proceed\" terminates the survey.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s1$data[[cut_name]] <- list()
  table_s1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "Proceed (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_1"]] <- list(
      label = "Proceed (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1 not found"
    )
  }

  # Row 2: S1 == 1
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_2"]] <- list(
      label = "I would like to proceed and protect my identity",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1 not found"
    )
  }

  # Row 3: S1 == 2
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_3"]] <- list(
      label = "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1 not found"
    )
  }

  # Row 4: S1 == 3
  var_col <- safe_get_var(cut_data, "S1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1_row_4"]] <- list(
      label = "I don't want to proceed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1_row_4"]] <- list(
      label = "I don't want to proceed",
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
  userNote = "(Select one; certain responses trigger routing or termination of the survey.)",
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
# Question: In what type of doctor’s office do you work?
# Rows: 3
# Source: s2a
# -----------------------------------------------------------------------------

table_s2a <- list(
  tableId = "s2a",
  questionId = "S2a",
  questionText = "In what type of doctor’s office do you work?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s2a",
  surveySection = "SCREENER",
  baseText = "Asked of respondents who indicated their primary role was Nurse Practitioner or Physician’s Assistant",
  userNote = "(Asked only if S2 = Nurse Practitioner or Physician’s Assistant)",
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
# Table: s2b (frequency)
# Question: What is your primary role?
# Rows: 4
# Source: s2b
# -----------------------------------------------------------------------------

table_s2b <- list(
  tableId = "s2b",
  questionId = "S2b",
  questionText = "What is your primary role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s2b",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Single response; 'Physician' groups physician specialties)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      label = "Physician’s Assistant",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2b$data[[cut_name]][["S2b_row_3"]] <- list(
      label = "Physician’s Assistant",
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
      sig_vs_total = NA
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
# Rows: 4
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
  baseText = "Those who indicated their primary specialty is Cardiologist (S2 = 1)",
  userNote = "",
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

  # Row 2: S3a IN (2, 3)
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "Non-interventional Cardiologists (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_2"]] <- list(
      label = "Non-interventional Cardiologists (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3a not found"
    )
  }

  # Row 3: S3a == 2
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "General Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_3"]] <- list(
      label = "General Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3a not found"
    )
  }

  # Row 4: S3a == 3
  var_col <- safe_get_var(cut_data, "S3a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3a$data[[cut_name]][["S3a_row_4"]] <- list(
      label = "Preventative Cardiologist",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3a$data[[cut_name]][["S3a_row_4"]] <- list(
      label = "Preventative Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3a not found"
    )
  }

}

all_tables[["s3a"]] <- table_s3a
print(paste("Generated frequency table: s3a"))

# -----------------------------------------------------------------------------
# Table: s4 (frequency) [DERIVED]
# Question: Are you currently board certified or eligible in your specialty?
# Rows: 4
# Source: s4
# -----------------------------------------------------------------------------

table_s4 <- list(
  tableId = "s4",
  questionId = "S4",
  questionText = "Are you currently board certified or eligible in your specialty?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s4",
  surveySection = "SCREENER",
  baseText = "Asked of respondents whose primary specialty was Cardiologist, Internal Medicine/Primary Care/Family Practice, Nephrologist, Endocrinologist, or Lipidologist (S2 = 1-5).",
  userNote = "(Asked only of the specialties listed above; note that selecting 'Board Eligible' or 'Neither' triggered termination of the survey—only 'Board Certified' respondents continued.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 %in% c(1,2,3,4,5)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_s4$data[[cut_name]] <- list()
  table_s4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S4 IN (1, 2)
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board certified or eligible (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_1"]] <- list(
      label = "Board certified or eligible (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

  # Row 2: S4 == 1
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Eligible",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_2"]] <- list(
      label = "Board Eligible",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

  # Row 3: S4 == 2
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Board Certified",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s4$data[[cut_name]][["S4_row_3"]] <- list(
      label = "Board Certified",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S4 not found"
    )
  }

  # Row 4: S4 == 3
  var_col <- safe_get_var(cut_data, "S4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s4$data[[cut_name]][["S4_row_4"]] <- list(
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
    table_s4$data[[cut_name]][["S4_row_4"]] <- list(
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

# -----------------------------------------------------------------------------
# Table: s6 (frequency)
# Question: How many years have you been in clinical practice, post residency/training?
# Rows: 33
# Source: s6
# -----------------------------------------------------------------------------

table_s6 <- list(
  tableId = "s6",
  questionId = "S6",
  questionText = "How many years have you been in clinical practice, post residency/training?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s6",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Integer years in practice; respondents with <3 or >35 years were screened out)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6$data[[cut_name]] <- list()
  table_s6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S6 == 3
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_1"]] <- list(
      label = "3 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_1"]] <- list(
      label = "3 years",
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

  # Row 2: S6 == 4
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_2"]] <- list(
      label = "4 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_2"]] <- list(
      label = "4 years",
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

  # Row 3: S6 == 5
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_3"]] <- list(
      label = "5 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_3"]] <- list(
      label = "5 years",
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

  # Row 4: S6 == 6
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_4"]] <- list(
      label = "6 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_4"]] <- list(
      label = "6 years",
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

  # Row 5: S6 == 7
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_5"]] <- list(
      label = "7 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_5"]] <- list(
      label = "7 years",
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

  # Row 6: S6 == 8
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_6"]] <- list(
      label = "8 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_6"]] <- list(
      label = "8 years",
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

  # Row 7: S6 == 9
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_7"]] <- list(
      label = "9 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_7"]] <- list(
      label = "9 years",
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

  # Row 8: S6 == 10
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_8"]] <- list(
      label = "10 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_8"]] <- list(
      label = "10 years",
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

  # Row 9: S6 == 11
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_9"]] <- list(
      label = "11 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_9"]] <- list(
      label = "11 years",
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

  # Row 10: S6 == 12
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_10"]] <- list(
      label = "12 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_10"]] <- list(
      label = "12 years",
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

  # Row 11: S6 == 13
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_11"]] <- list(
      label = "13 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_11"]] <- list(
      label = "13 years",
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

  # Row 12: S6 == 14
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_12"]] <- list(
      label = "14 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_12"]] <- list(
      label = "14 years",
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

  # Row 13: S6 == 15
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_13"]] <- list(
      label = "15 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_13"]] <- list(
      label = "15 years",
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

  # Row 14: S6 == 16
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_14"]] <- list(
      label = "16 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_14"]] <- list(
      label = "16 years",
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

  # Row 15: S6 == 17
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_15"]] <- list(
      label = "17 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_15"]] <- list(
      label = "17 years",
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

  # Row 16: S6 == 18
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 18, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_16"]] <- list(
      label = "18 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_16"]] <- list(
      label = "18 years",
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

  # Row 17: S6 == 19
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_17"]] <- list(
      label = "19 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_17"]] <- list(
      label = "19 years",
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

  # Row 18: S6 == 20
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_18"]] <- list(
      label = "20 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_18"]] <- list(
      label = "20 years",
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

  # Row 19: S6 == 21
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_19"]] <- list(
      label = "21 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_19"]] <- list(
      label = "21 years",
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

  # Row 20: S6 == 22
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_20"]] <- list(
      label = "22 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_20"]] <- list(
      label = "22 years",
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

  # Row 21: S6 == 23
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 23, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_21"]] <- list(
      label = "23 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_21"]] <- list(
      label = "23 years",
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

  # Row 22: S6 == 24
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_22"]] <- list(
      label = "24 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_22"]] <- list(
      label = "24 years",
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

  # Row 23: S6 == 25
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_23"]] <- list(
      label = "25 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_23"]] <- list(
      label = "25 years",
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

  # Row 24: S6 == 26
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_24"]] <- list(
      label = "26 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_24"]] <- list(
      label = "26 years",
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

  # Row 25: S6 == 27
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_25"]] <- list(
      label = "27 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_25"]] <- list(
      label = "27 years",
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

  # Row 26: S6 == 28
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_26"]] <- list(
      label = "28 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_26"]] <- list(
      label = "28 years",
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

  # Row 27: S6 == 29
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_27"]] <- list(
      label = "29 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_27"]] <- list(
      label = "29 years",
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

  # Row 28: S6 == 30
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_28"]] <- list(
      label = "30 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_28"]] <- list(
      label = "30 years",
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

  # Row 29: S6 == 31
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_29"]] <- list(
      label = "31 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_29"]] <- list(
      label = "31 years",
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

  # Row 30: S6 == 32
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_30"]] <- list(
      label = "32 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_30"]] <- list(
      label = "32 years",
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

  # Row 31: S6 == 33
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 33, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_31"]] <- list(
      label = "33 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_31"]] <- list(
      label = "33 years",
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

  # Row 32: S6 == 34
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_32"]] <- list(
      label = "34 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_32"]] <- list(
      label = "34 years",
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

  # Row 33: S6 == 35
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_33"]] <- list(
      label = "35 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6$data[[cut_name]][["S6_row_33"]] <- list(
      label = "35 years",
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

all_tables[["s6"]] <- table_s6
print(paste("Generated frequency table: s6"))

# -----------------------------------------------------------------------------
# Table: s6_binned (frequency) [DERIVED]
# Question: How many years have you been in clinical practice, post residency/training?
# Rows: 10
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
  userNote = "(Integer years in practice; respondents with <3 or >35 years were screened out)",
  tableSubtitle = "Years in practice: Binned distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s6_binned$data[[cut_name]] <- list()
  table_s6_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S6 in range [3-10]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 3 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_1"]] <- list(
      label = "Early career (3-10 years)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_1"]] <- list(
      label = "Early career (3-10 years)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 2: S6 in range [3-5]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 3 & as.numeric(var_col) <= 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_2"]] <- list(
      label = "3-5 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_2"]] <- list(
      label = "3-5 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 3: S6 in range [6-10]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 6 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_3"]] <- list(
      label = "6-10 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_3"]] <- list(
      label = "6-10 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 4: S6 in range [11-20]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_4"]] <- list(
      label = "Mid career (11-20 years)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_4"]] <- list(
      label = "Mid career (11-20 years)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 5: S6 in range [11-15]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_5"]] <- list(
      label = "11-15 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_5"]] <- list(
      label = "11-15 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 6: S6 in range [16-20]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_6"]] <- list(
      label = "16-20 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_6"]] <- list(
      label = "16-20 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 7: S6 in range [21-35]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 21 & as.numeric(var_col) <= 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_7"]] <- list(
      label = "Late career (21-35 years)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_7"]] <- list(
      label = "Late career (21-35 years)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 8: S6 in range [21-25]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 21 & as.numeric(var_col) <= 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_8"]] <- list(
      label = "21-25 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_8"]] <- list(
      label = "21-25 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 9: S6 in range [26-30]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 26 & as.numeric(var_col) <= 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_9"]] <- list(
      label = "26-30 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_9"]] <- list(
      label = "26-30 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

  # Row 10: S6 in range [31-35]
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 31 & as.numeric(var_col) <= 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6_binned$data[[cut_name]][["S6_row_10"]] <- list(
      label = "31-35 years",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6_binned$data[[cut_name]][["S6_row_10"]] <- list(
      label = "31-35 years",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6 not found"
    )
  }

}

all_tables[["s6_binned"]] <- table_s6_binned
print(paste("Generated frequency table: s6_binned"))

# -----------------------------------------------------------------------------
# Table: s8 (mean_rows)
# Question: Approximately what percentage of your professional time is spent performing each of the following activities? (Responses across rows must sum to 100%)
# Rows: 4
# Source: s8
# -----------------------------------------------------------------------------

table_s8 <- list(
  tableId = "s8",
  questionId = "S8",
  questionText = "Approximately what percentage of your professional time is spent performing each of the following activities? (Responses across rows must sum to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s8",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Responses must autosum to 100% across rows; respondents with <70% on Treating/Managing patients were screened out of the study)",
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
# Table: s8_S8r1_distribution (frequency) [DERIVED]
# Question: Treating/Managing patients — distribution of percent time spent
# Rows: 3
# Source: s8
# -----------------------------------------------------------------------------

table_s8_S8r1_distribution <- list(
  tableId = "s8_S8r1_distribution",
  questionId = "S8",
  questionText = "Treating/Managing patients — distribution of percent time spent",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s8",
  surveySection = "SCREENER",
  baseText = "Those who spend at least 70% of their professional time treating/managing patients (screener requirement)",
  userNote = "(Binned distribution for S8r1; helpful because the distribution is highly skewed toward 100%)",
  tableSubtitle = "S8r1: Percent time treating/managing patients (binned distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8_S8r1_distribution$data[[cut_name]] <- list()
  table_s8_S8r1_distribution$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S8r1 in range [70-89]
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 70 & as.numeric(var_col) <= 89, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_1"]] <- list(
      label = "70-89% of time (Low-to-Moderate)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_1"]] <- list(
      label = "70-89% of time (Low-to-Moderate)",
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

  # Row 2: S8r1 in range [90-99]
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 90 & as.numeric(var_col) <= 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_2"]] <- list(
      label = "90-99% of time (High)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_2"]] <- list(
      label = "90-99% of time (High)",
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

  # Row 3: S8r1 == 100
  var_col <- safe_get_var(cut_data, "S8r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_3"]] <- list(
      label = "100% of time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_S8r1_distribution$data[[cut_name]][["S8r1_row_3"]] <- list(
      label = "100% of time",
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

}

all_tables[["s8_S8r1_distribution"]] <- table_s8_S8r1_distribution
print(paste("Generated frequency table: s8_S8r1_distribution"))

# -----------------------------------------------------------------------------
# Table: s9 (frequency)
# Question: Which of the following best represents the setting in which you spend most of your professional time?
# Rows: 10
# Source: s9
# -----------------------------------------------------------------------------

table_s9 <- list(
  tableId = "s9",
  questionId = "S9",
  questionText = "Which of the following best represents the setting in which you spend most of your professional time?",
  tableType = "frequency",
  isDerived = FALSE,
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

  # Row 5: S9 IN (4, 5, 6, 7)
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5, 6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Hospital / Health system (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_5"]] <- list(
      label = "Hospital / Health system (NET)",
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

  # Row 6: S9 == 4
  var_col <- safe_get_var(cut_data, "S9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Staff HMO",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9_row_6"]] <- list(
      label = "Staff HMO",
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
# -----------------------------------------------------------------------------

table_s10 <- list(
  tableId = "s10",
  questionId = "S10",
  questionText = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Respondents managing fewer than 50 adult patients per month were screened out.)",
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
      label = "Number of adult patients (age 18+) personally managed per month",
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
      label = "Number of adult patients (age 18+) personally managed per month",
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
# Table: s10_binned (frequency) [DERIVED]
# Question: Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.
# Rows: 4
# Source: s10
# -----------------------------------------------------------------------------

table_s10_binned <- list(
  tableId = "s10_binned",
  questionId = "S10",
  questionText = "Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By ‘personally’, we mean patients for whom you are a primary treatment decision maker.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s10",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Bins based on sample quartiles: Q1=250, median=350, Q3=450; respondents managing fewer than 50 adult patients/month were screened out.)",
  tableSubtitle = "Patients managed per month — quartile-based distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10_binned$data[[cut_name]] <- list()
  table_s10_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S10 in range [56-249]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 56 & as.numeric(var_col) <= 249, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_binned$data[[cut_name]][["S10_row_1"]] <- list(
      label = "56-249 patients per month",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_binned$data[[cut_name]][["S10_row_1"]] <- list(
      label = "56-249 patients per month",
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

  # Row 2: S10 in range [250-349]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 250 & as.numeric(var_col) <= 349, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_binned$data[[cut_name]][["S10_row_2"]] <- list(
      label = "250-349 patients per month",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_binned$data[[cut_name]][["S10_row_2"]] <- list(
      label = "250-349 patients per month",
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

  # Row 3: S10 in range [350-449]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 350 & as.numeric(var_col) <= 449, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_binned$data[[cut_name]][["S10_row_3"]] <- list(
      label = "350-449 patients per month",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_binned$data[[cut_name]][["S10_row_3"]] <- list(
      label = "350-449 patients per month",
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

  # Row 4: S10 in range [450-999]
  var_col <- safe_get_var(cut_data, "S10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 450 & as.numeric(var_col) <= 999, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10_binned$data[[cut_name]][["S10_row_4"]] <- list(
      label = "450-999 patients per month",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10_binned$data[[cut_name]][["S10_row_4"]] <- list(
      label = "450-999 patients per month",
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

all_tables[["s10_binned"]] <- table_s10_binned
print(paste("Generated frequency table: s10_binned"))

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
  baseText = "Respondents who qualified and reached this screener question (passed prior screener criteria)",
  userNote = "(Numeric open-end; respondents with <10 patients were screened out during qualification)",
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
      label = "Number of adult patients (age 18+) you personally manage, with hypercholesterolemia and established CVD (count)",
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
      label = "Number of adult patients (age 18+) you personally manage, with hypercholesterolemia and established CVD (count)",
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
# Table: s11_binned (frequency) [DERIVED]
# Question: Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?
# Rows: 4
# Source: s11
# -----------------------------------------------------------------------------

table_s11_binned <- list(
  tableId = "s11_binned",
  questionId = "S11",
  questionText = "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s11",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned distribution using quartiles from survey responses; ranges inclusive)",
  tableSubtitle = "Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11_binned$data[[cut_name]] <- list()
  table_s11_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11 in range [20-74]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 20 & as.numeric(var_col) <= 74, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_binned$data[[cut_name]][["S11_row_1"]] <- list(
      label = "20-74 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_binned$data[[cut_name]][["S11_row_1"]] <- list(
      label = "20-74 patients",
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

  # Row 2: S11 in range [75-124]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 75 & as.numeric(var_col) <= 124, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_binned$data[[cut_name]][["S11_row_2"]] <- list(
      label = "75-124 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_binned$data[[cut_name]][["S11_row_2"]] <- list(
      label = "75-124 patients",
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

  # Row 3: S11 in range [125-213]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 125 & as.numeric(var_col) <= 213, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_binned$data[[cut_name]][["S11_row_3"]] <- list(
      label = "125-213 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_binned$data[[cut_name]][["S11_row_3"]] <- list(
      label = "125-213 patients",
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

  # Row 4: S11 in range [214-900]
  var_col <- safe_get_var(cut_data, "S11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 214 & as.numeric(var_col) <= 900, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11_binned$data[[cut_name]][["S11_row_4"]] <- list(
      label = "214-900 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11_binned$data[[cut_name]][["S11_row_4"]] <- list(
      label = "214-900 patients",
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

all_tables[["s11_binned"]] <- table_s11_binned
print(paste("Generated frequency table: s11_binned"))

# -----------------------------------------------------------------------------
# Table: s12 (mean_rows)
# Question: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...
# Rows: 4
# Source: s12
# -----------------------------------------------------------------------------

table_s12 <- list(
  tableId = "s12",
  questionId = "S12",
  questionText = "Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s12",
  surveySection = "SCREENER",
  baseText = "Those who reported managing ≥10 adult patients with hypercholesterolemia and established CVD (S11 ≥ 10)",
  userNote = "(Enter numeric counts of patients in each time window; rows auto-sum and must be ≤ total patients reported in S11)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S11 >= 10")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
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
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
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
      label = "Within the last 3-5 years",
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
      label = "Within the last 3-5 years",
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
      label = "Within the last 1-2 years",
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
      label = "Within the last 1-2 years",
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
      label = "Within the last year",
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
      label = "Within the last year",
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
# Table: s12_total (mean_rows) [DERIVED]
# Question: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...
# Rows: 1
# Source: s12
# -----------------------------------------------------------------------------

table_s12_total <- list(
  tableId = "s12_total",
  questionId = "S12",
  questionText = "Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "s12",
  surveySection = "SCREENER",
  baseText = "Qualified respondents (manage ≥10 adult patients with hypercholesterolemia and established CVD)",
  userNote = "(Derived: sum of the four S12 time-window counts per respondent; system will compute mean/median/std dev for this row)",
  tableSubtitle = "Total (sum of time windows)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s12_total$data[[cut_name]] <- list()
  table_s12_total$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Total patients with an event (sum across the four time windows) (sum of component means)
  net_vars <- c("S12r1", "S12r2", "S12r3", "S12r4")
  component_means <- sapply(net_vars, function(v) {
    col <- safe_get_var(cut_data, v)
    if (!is.null(col)) mean(col, na.rm = TRUE) else NA
  })
  # Sum component means (valid for allocation/share questions)
  net_mean <- if (all(is.na(component_means))) NA else round_half_up(sum(component_means, na.rm = TRUE), 1)
  # Use n from first component as representative base
  first_col <- safe_get_var(cut_data, net_vars[1])
  n <- if (!is.null(first_col)) sum(!is.na(first_col)) else 0

  table_s12_total$data[[cut_name]][["_NET_S12_TOTAL"]] <- list(
    label = "Total patients with an event (sum across the four time windows)",
    n = n,
    mean = net_mean,
    mean_label = "Mean (sum of components)",
    median = NA,
    median_label = "",
    sd = NA,
    mean_no_outliers = NA,
    mean_no_outliers_label = "",
    isNet = TRUE,
    indent = 0,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

}

all_tables[["s12_total"]] <- table_s12_total
print(paste("Generated mean_rows table: s12_total"))

# -----------------------------------------------------------------------------
# Table: s12_total_binned (frequency) [DERIVED]
# Question: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...
# Rows: 4
# Source: s12
# -----------------------------------------------------------------------------

table_s12_total_binned <- list(
  tableId = "s12_total_binned",
  questionId = "S12",
  questionText = "Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) ...",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s12",
  surveySection = "SCREENER",
  baseText = "Qualified respondents (manage 60;10 adult patients with hypercholesterolemia and established CVD)",
  userNote = "(Derived distribution of total patients with an event; bins chosen using sample quartiles: Q1920, Q370)",
  tableSubtitle = "Total patients with an event: Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s12_total_binned$data[[cut_name]] <- list()
  table_s12_total_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - None (0 patients) (components: S12r1, S12r2, S12r3, S12r4)
  net_vars <- c("S12r1", "S12r2", "S12r3", "S12r4")
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

    table_s12_total_binned$data[[cut_name]][["_NET_S12_TOTAL_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: NET - Low (1-20 patients) (components: S12r1, S12r2, S12r3, S12r4)
  net_vars <- c("S12r1", "S12r2", "S12r3", "S12r4")
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

    table_s12_total_binned$data[[cut_name]][["_NET_S12_TOTAL_row_2"]] <- list(
      label = "Low (1-20 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 3: NET - Moderate (21-70 patients) (components: S12r1, S12r2, S12r3, S12r4)
  net_vars <- c("S12r1", "S12r2", "S12r3", "S12r4")
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

    table_s12_total_binned$data[[cut_name]][["_NET_S12_TOTAL_row_3"]] <- list(
      label = "Moderate (21-70 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 4: NET - High (71-500 patients) (components: S12r1, S12r2, S12r3, S12r4)
  net_vars <- c("S12r1", "S12r2", "S12r3", "S12r4")
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

    table_s12_total_binned$data[[cut_name]][["_NET_S12_TOTAL_row_4"]] <- list(
      label = "High (71-500 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

}

all_tables[["s12_total_binned"]] <- table_s12_total_binned
print(paste("Generated frequency table: s12_total_binned"))

# -----------------------------------------------------------------------------
# Table: a1 (frequency)
# Question: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? Check one box per row.
# Rows: 12
# Source: a1
# -----------------------------------------------------------------------------

table_a1 <- list(
  tableId = "a1",
  questionId = "A1",
  questionText = "To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? Check one box per row.",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a1",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one per row)",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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

  # Row 10: Category header - Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe)
  table_a1$data[[cut_name]][["_CAT__row_10"]] <- list(
    label = "Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe)",
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
      label = "As an adjunct to diet",
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
      label = "As an adjunct to diet",
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
  baseText = "",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 655 mg/dL",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 655 mg/dL",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 670 mg/dL",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 670 mg/dL",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 6100 mg/dL",
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
      label = "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels 6100 mg/dL",
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
# Table: a2b (frequency) [DERIVED]
# Question: And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?
# Rows: 4
# Source: a2b
# -----------------------------------------------------------------------------

table_a2b <- list(
  tableId = "a2b",
  questionId = "A2b",
  questionText = "And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a2b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "Statin-first (NET)",
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
      label = "Statin-first approaches (NET)",
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
      label = "Statin-first approaches (NET)",
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
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 7
# Source: a3
# -----------------------------------------------------------------------------

table_a3 <- list(
  tableId = "a3",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Respondents entered number of patients out of their last 100; rows can add to more than 100)",
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
# Table: a3_A3r1_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r1_bins <- list(
  tableId = "a3_A3r1_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Statin only (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r1_bins$data[[cut_name]] <- list()
  table_a3_A3r1_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r1 == 0
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r1 in range [1-25]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_2"]] <- list(
      label = "1-25 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_2"]] <- list(
      label = "1-25 patients",
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

  # Row 3: A3r1 in range [26-50]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 26 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_3"]] <- list(
      label = "26-50 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_3"]] <- list(
      label = "26-50 patients",
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

  # Row 4: A3r1 in range [51-75]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 75, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_4"]] <- list(
      label = "51-75 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_4"]] <- list(
      label = "51-75 patients",
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

  # Row 5: A3r1 in range [76-100]
  var_col <- safe_get_var(cut_data, "A3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 76 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_5"]] <- list(
      label = "76-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r1_bins$data[[cut_name]][["A3r1_row_5"]] <- list(
      label = "76-100 patients",
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

all_tables[["a3_A3r1_bins"]] <- table_a3_A3r1_bins
print(paste("Generated frequency table: a3_A3r1_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r2_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r2_bins <- list(
  tableId = "a3_A3r2_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Leqvio (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r2_bins$data[[cut_name]] <- list()
  table_a3_A3r2_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r2 == 0
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r2 in range [1-11]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_2"]] <- list(
      label = "1-11 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_2"]] <- list(
      label = "1-11 patients",
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

  # Row 3: A3r2 in range [12-22]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 12 & as.numeric(var_col) <= 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_3"]] <- list(
      label = "12-22 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_3"]] <- list(
      label = "12-22 patients",
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

  # Row 4: A3r2 in range [23-33]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 23 & as.numeric(var_col) <= 33, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_4"]] <- list(
      label = "23-33 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_4"]] <- list(
      label = "23-33 patients",
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

  # Row 5: A3r2 in range [34-45]
  var_col <- safe_get_var(cut_data, "A3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 34 & as.numeric(var_col) <= 45, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_5"]] <- list(
      label = "34-45 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r2_bins$data[[cut_name]][["A3r2_row_5"]] <- list(
      label = "34-45 patients",
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

all_tables[["a3_A3r2_bins"]] <- table_a3_A3r2_bins
print(paste("Generated frequency table: a3_A3r2_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r3_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r3_bins <- list(
  tableId = "a3_A3r3_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Praluent (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r3_bins$data[[cut_name]] <- list()
  table_a3_A3r3_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r3 == 0
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r3 in range [1-25]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_2"]] <- list(
      label = "1-25 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_2"]] <- list(
      label = "1-25 patients",
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

  # Row 3: A3r3 in range [26-50]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 26 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_3"]] <- list(
      label = "26-50 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_3"]] <- list(
      label = "26-50 patients",
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

  # Row 4: A3r3 in range [51-75]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 75, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_4"]] <- list(
      label = "51-75 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_4"]] <- list(
      label = "51-75 patients",
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

  # Row 5: A3r3 in range [76-100]
  var_col <- safe_get_var(cut_data, "A3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 76 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_5"]] <- list(
      label = "76-100 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r3_bins$data[[cut_name]][["A3r3_row_5"]] <- list(
      label = "76-100 patients",
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

all_tables[["a3_A3r3_bins"]] <- table_a3_A3r3_bins
print(paste("Generated frequency table: a3_A3r3_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r4_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r4_bins <- list(
  tableId = "a3_A3r4_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Repatha (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r4_bins$data[[cut_name]] <- list()
  table_a3_A3r4_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r4 == 0
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r4 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_2"]] <- list(
      label = "1-15 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_2"]] <- list(
      label = "1-15 patients",
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

  # Row 3: A3r4 in range [16-30]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_3"]] <- list(
      label = "16-30 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_3"]] <- list(
      label = "16-30 patients",
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

  # Row 4: A3r4 in range [31-45]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 31 & as.numeric(var_col) <= 45, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_4"]] <- list(
      label = "31-45 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_4"]] <- list(
      label = "31-45 patients",
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

  # Row 5: A3r4 in range [46-60]
  var_col <- safe_get_var(cut_data, "A3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 46 & as.numeric(var_col) <= 60, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_5"]] <- list(
      label = "46-60 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r4_bins$data[[cut_name]][["A3r4_row_5"]] <- list(
      label = "46-60 patients",
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

all_tables[["a3_A3r4_bins"]] <- table_a3_A3r4_bins
print(paste("Generated frequency table: a3_A3r4_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r5_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r5_bins <- list(
  tableId = "a3_A3r5_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Zetia / Ezetimibe (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r5_bins$data[[cut_name]] <- list()
  table_a3_A3r5_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r5 == 0
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r5 in range [1-23]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 23, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_2"]] <- list(
      label = "1-23 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_2"]] <- list(
      label = "1-23 patients",
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

  # Row 3: A3r5 in range [24-47]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 24 & as.numeric(var_col) <= 47, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_3"]] <- list(
      label = "24-47 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_3"]] <- list(
      label = "24-47 patients",
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

  # Row 4: A3r5 in range [48-71]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 48 & as.numeric(var_col) <= 71, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_4"]] <- list(
      label = "48-71 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_4"]] <- list(
      label = "48-71 patients",
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

  # Row 5: A3r5 in range [72-95]
  var_col <- safe_get_var(cut_data, "A3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 72 & as.numeric(var_col) <= 95, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_5"]] <- list(
      label = "72-95 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r5_bins$data[[cut_name]][["A3r5_row_5"]] <- list(
      label = "72-95 patients",
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

all_tables[["a3_A3r5_bins"]] <- table_a3_A3r5_bins
print(paste("Generated frequency table: a3_A3r5_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r6_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r6_bins <- list(
  tableId = "a3_A3r6_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Nexletol / Nexlizet (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r6_bins$data[[cut_name]] <- list()
  table_a3_A3r6_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r6 == 0
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r6 in range [1-12]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_2"]] <- list(
      label = "1-12 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_2"]] <- list(
      label = "1-12 patients",
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

  # Row 3: A3r6 in range [13-25]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 13 & as.numeric(var_col) <= 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_3"]] <- list(
      label = "13-25 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_3"]] <- list(
      label = "13-25 patients",
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

  # Row 4: A3r6 in range [26-37]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 26 & as.numeric(var_col) <= 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_4"]] <- list(
      label = "26-37 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_4"]] <- list(
      label = "26-37 patients",
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

  # Row 5: A3r6 in range [38-50]
  var_col <- safe_get_var(cut_data, "A3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 38 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_5"]] <- list(
      label = "38-50 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r6_bins$data[[cut_name]][["A3r6_row_5"]] <- list(
      label = "38-50 patients",
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

all_tables[["a3_A3r6_bins"]] <- table_a3_A3r6_bins
print(paste("Generated frequency table: a3_A3r6_bins"))

# -----------------------------------------------------------------------------
# Table: a3_A3r7_bins (frequency) [DERIVED]
# Question: For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.
# Rows: 5
# Source: a3
# -----------------------------------------------------------------------------

table_a3_A3r7_bins <- list(
  tableId = "a3_A3r7_bins",
  questionId = "A3",
  questionText = "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Binned distribution of counts out of last 100 patients)",
  tableSubtitle = "Other (Distribution)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a3_A3r7_bins$data[[cut_name]] <- list()
  table_a3_A3r7_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3r7 == 0
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_1"]] <- list(
      label = "None (0 patients)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_1"]] <- list(
      label = "None (0 patients)",
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

  # Row 2: A3r7 in range [1-5]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_2"]] <- list(
      label = "1-5 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_2"]] <- list(
      label = "1-5 patients",
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

  # Row 3: A3r7 in range [6-10]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 6 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_3"]] <- list(
      label = "6-10 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_3"]] <- list(
      label = "6-10 patients",
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

  # Row 4: A3r7 in range [11-15]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_4"]] <- list(
      label = "11-15 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_4"]] <- list(
      label = "11-15 patients",
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

  # Row 5: A3r7 in range [16-20]
  var_col <- safe_get_var(cut_data, "A3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_5"]] <- list(
      label = "16-20 patients",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3_A3r7_bins$data[[cut_name]][["A3r7_row_5"]] <- list(
      label = "16-20 patients",
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

all_tables[["a3_A3r7_bins"]] <- table_a3_A3r7_bins
print(paste("Generated frequency table: a3_A3r7_bins"))

# -----------------------------------------------------------------------------
# Table: a3a_leqvio (mean_rows)
# Question: For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_leqvio <- list(
  tableId = "a3a_leqvio",
  questionId = "A3a",
  questionText = "For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Leqvio to at least one of their last 100 patients.",
  userNote = "(Percent of last 100 patients; for each therapy the two columns sum to 100%)",
  tableSubtitle = "",
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
  table_a3a_leqvio$data[[cut_name]] <- list()
  table_a3a_leqvio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_leqvio$data[[cut_name]][["A3ar1c1"]] <- list(
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
    table_a3a_leqvio$data[[cut_name]][["A3ar1c1"]] <- list(
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

    table_a3a_leqvio$data[[cut_name]][["A3ar1c2"]] <- list(
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
    table_a3a_leqvio$data[[cut_name]][["A3ar1c2"]] <- list(
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
      error = "Variable A3ar1c2 not found"
    )
  }

}

all_tables[["a3a_leqvio"]] <- table_a3a_leqvio
print(paste("Generated mean_rows table: a3a_leqvio"))

# -----------------------------------------------------------------------------
# Table: a3a_praluent (mean_rows)
# Question: For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_praluent <- list(
  tableId = "a3a_praluent",
  questionId = "A3a",
  questionText = "For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Praluent to at least one of their last 100 patients.",
  userNote = "(Percent of last 100 patients; for each therapy the two columns sum to 100%)",
  tableSubtitle = "",
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
  table_a3a_praluent$data[[cut_name]] <- list()
  table_a3a_praluent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_praluent$data[[cut_name]][["A3ar2c1"]] <- list(
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
    table_a3a_praluent$data[[cut_name]][["A3ar2c1"]] <- list(
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

    table_a3a_praluent$data[[cut_name]][["A3ar2c2"]] <- list(
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
    table_a3a_praluent$data[[cut_name]][["A3ar2c2"]] <- list(
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
      error = "Variable A3ar2c2 not found"
    )
  }

}

all_tables[["a3a_praluent"]] <- table_a3a_praluent
print(paste("Generated mean_rows table: a3a_praluent"))

# -----------------------------------------------------------------------------
# Table: a3a_repatha (mean_rows)
# Question: For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_repatha <- list(
  tableId = "a3a_repatha",
  questionId = "A3a",
  questionText = "For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Repatha to at least one of their last 100 patients.",
  userNote = "(Percent of last 100 patients; for each therapy the two columns sum to 100%)",
  tableSubtitle = "",
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
  table_a3a_repatha$data[[cut_name]] <- list()
  table_a3a_repatha$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_repatha$data[[cut_name]][["A3ar3c1"]] <- list(
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
    table_a3a_repatha$data[[cut_name]][["A3ar3c1"]] <- list(
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

    table_a3a_repatha$data[[cut_name]][["A3ar3c2"]] <- list(
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
    table_a3a_repatha$data[[cut_name]][["A3ar3c2"]] <- list(
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
      error = "Variable A3ar3c2 not found"
    )
  }

}

all_tables[["a3a_repatha"]] <- table_a3a_repatha
print(paste("Generated mean_rows table: a3a_repatha"))

# -----------------------------------------------------------------------------
# Table: a3a_zetia (mean_rows)
# Question: For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_zetia <- list(
  tableId = "a3a_zetia",
  questionId = "A3a",
  questionText = "For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Zetia (ezetimibe) to at least one of their last 100 patients.",
  userNote = "(Percent of last 100 patients; for each therapy the two columns sum to 100%)",
  tableSubtitle = "",
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
  table_a3a_zetia$data[[cut_name]] <- list()
  table_a3a_zetia$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_zetia$data[[cut_name]][["A3ar4c1"]] <- list(
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
    table_a3a_zetia$data[[cut_name]][["A3ar4c1"]] <- list(
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

    table_a3a_zetia$data[[cut_name]][["A3ar4c2"]] <- list(
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
    table_a3a_zetia$data[[cut_name]][["A3ar4c2"]] <- list(
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
      error = "Variable A3ar4c2 not found"
    )
  }

}

all_tables[["a3a_zetia"]] <- table_a3a_zetia
print(paste("Generated mean_rows table: a3a_zetia"))

# -----------------------------------------------------------------------------
# Table: a3a_nexletol (mean_rows)
# Question: For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.
# Rows: 2
# Source: a3a
# -----------------------------------------------------------------------------

table_a3a_nexletol <- list(
  tableId = "a3a_nexletol",
  questionId = "A3a",
  questionText = "For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Nexletol/Nexlizet to at least one of their last 100 patients.",
  userNote = "(Percent of last 100 patients; for each therapy the two columns sum to 100%)",
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
  table_a3a_nexletol$data[[cut_name]] <- list()
  table_a3a_nexletol$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3a_nexletol$data[[cut_name]][["A3ar5c1"]] <- list(
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
    table_a3a_nexletol$data[[cut_name]][["A3ar5c1"]] <- list(
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

    table_a3a_nexletol$data[[cut_name]][["A3ar5c2"]] <- list(
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
    table_a3a_nexletol$data[[cut_name]][["A3ar5c2"]] <- list(
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
      error = "Variable A3ar5c2 not found"
    )
  }

}

all_tables[["a3a_nexletol"]] <- table_a3a_nexletol
print(paste("Generated mean_rows table: a3a_nexletol"))

# -----------------------------------------------------------------------------
# Table: a3b_leqvio (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_leqvio <- list(
  tableId = "a3b_leqvio",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Leqvio (inclisiran) without a statin.",
  userNote = "(Percent of patients; values 0–100. Question shown only for therapies respondents reported prescribing without a statin.)",
  tableSubtitle = "",
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
  table_a3b_leqvio$data[[cut_name]] <- list()
  table_a3b_leqvio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_leqvio$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
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
    table_a3b_leqvio$data[[cut_name]][["A3br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
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

    table_a3b_leqvio$data[[cut_name]][["A3br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
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
    table_a3b_leqvio$data[[cut_name]][["A3br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
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

all_tables[["a3b_leqvio"]] <- table_a3b_leqvio
print(paste("Generated mean_rows table: a3b_leqvio"))

# -----------------------------------------------------------------------------
# Table: a3b_praluent (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_praluent <- list(
  tableId = "a3b_praluent",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Praluent (alirocumab) without a statin.",
  userNote = "(Percent of patients; values 0–100. Question shown only for therapies respondents reported prescribing without a statin.)",
  tableSubtitle = "",
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
  table_a3b_praluent$data[[cut_name]] <- list()
  table_a3b_praluent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_praluent$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
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
    table_a3b_praluent$data[[cut_name]][["A3br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
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

    table_a3b_praluent$data[[cut_name]][["A3br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
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
    table_a3b_praluent$data[[cut_name]][["A3br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
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

all_tables[["a3b_praluent"]] <- table_a3b_praluent
print(paste("Generated mean_rows table: a3b_praluent"))

# -----------------------------------------------------------------------------
# Table: a3b_repatha (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_repatha <- list(
  tableId = "a3b_repatha",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Repatha (evolocumab) without a statin.",
  userNote = "(Percent of patients; values 0–100. Question shown only for therapies respondents reported prescribing without a statin.)",
  tableSubtitle = "",
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
  table_a3b_repatha$data[[cut_name]] <- list()
  table_a3b_repatha$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_repatha$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
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
    table_a3b_repatha$data[[cut_name]][["A3br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
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

    table_a3b_repatha$data[[cut_name]][["A3br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
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
    table_a3b_repatha$data[[cut_name]][["A3br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
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

all_tables[["a3b_repatha"]] <- table_a3b_repatha
print(paste("Generated mean_rows table: a3b_repatha"))

# -----------------------------------------------------------------------------
# Table: a3b_zetia (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_zetia <- list(
  tableId = "a3b_zetia",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Zetia (ezetimibe) without a statin.",
  userNote = "(Percent of patients; values 0–100. Question shown only for therapies respondents reported prescribing without a statin.)",
  tableSubtitle = "",
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
  table_a3b_zetia$data[[cut_name]] <- list()
  table_a3b_zetia$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_zetia$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Zetia (ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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
    table_a3b_zetia$data[[cut_name]][["A3br4c1"]] <- list(
      label = "Zetia (ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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

    table_a3b_zetia$data[[cut_name]][["A3br4c2"]] <- list(
      label = "Zetia (ezetimibe) — After trying another lipid‑lowering therapy",
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
    table_a3b_zetia$data[[cut_name]][["A3br4c2"]] <- list(
      label = "Zetia (ezetimibe) — After trying another lipid‑lowering therapy",
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

all_tables[["a3b_zetia"]] <- table_a3b_zetia
print(paste("Generated mean_rows table: a3b_zetia"))

# -----------------------------------------------------------------------------
# Table: a3b_nexletol (mean_rows)
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 2
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_nexletol <- list(
  tableId = "a3b_nexletol",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who reported prescribing Nexletol / Nexlizet (bempedoic acid ± ezetimibe) without a statin.",
  userNote = "(Percent of patients; values 0–100. Question shown only for therapies respondents reported prescribing without a statin.)",
  tableSubtitle = "",
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
  table_a3b_nexletol$data[[cut_name]] <- list()
  table_a3b_nexletol$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a3b_nexletol$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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
    table_a3b_nexletol$data[[cut_name]][["A3br5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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

    table_a3b_nexletol$data[[cut_name]][["A3br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After trying another lipid‑lowering therapy",
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
    table_a3b_nexletol$data[[cut_name]][["A3br5c2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After trying another lipid‑lowering therapy",
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

all_tables[["a3b_nexletol"]] <- table_a3b_nexletol
print(paste("Generated mean_rows table: a3b_nexletol"))

# -----------------------------------------------------------------------------
# Table: a3b_leqvio_dist (frequency) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 8
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_leqvio_dist <- list(
  tableId = "a3b_leqvio_dist",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who reported prescribing Leqvio to at least some patients without a statin.",
  userNote = "(Binned distribution of percent of patients; 0–100. Bins chosen to highlight many zeros and low values: 0, 1–15, 16–50, 51–100.)",
  tableSubtitle = "Leqvio (inclisiran): Distribution (Before vs After)",
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
  table_a3b_leqvio_dist$data[[cut_name]] <- list()
  table_a3b_leqvio_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br1c1 == 0
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_1"]] <- list(
      label = "Leqvio (inclisiran) — Before: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_1"]] <- list(
      label = "Leqvio (inclisiran) — Before: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 2: A3br1c1 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_2"]] <- list(
      label = "Leqvio (inclisiran) — Before: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_2"]] <- list(
      label = "Leqvio (inclisiran) — Before: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 3: A3br1c1 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_3"]] <- list(
      label = "Leqvio (inclisiran) — Before: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_3"]] <- list(
      label = "Leqvio (inclisiran) — Before: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 4: A3br1c1 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_4"]] <- list(
      label = "Leqvio (inclisiran) — Before: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c1_row_4"]] <- list(
      label = "Leqvio (inclisiran) — Before: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c1 not found"
    )
  }

  # Row 5: A3br1c2 == 0
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_5"]] <- list(
      label = "Leqvio (inclisiran) — After: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_5"]] <- list(
      label = "Leqvio (inclisiran) — After: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c2 not found"
    )
  }

  # Row 6: A3br1c2 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_6"]] <- list(
      label = "Leqvio (inclisiran) — After: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_6"]] <- list(
      label = "Leqvio (inclisiran) — After: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c2 not found"
    )
  }

  # Row 7: A3br1c2 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_7"]] <- list(
      label = "Leqvio (inclisiran) — After: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_7"]] <- list(
      label = "Leqvio (inclisiran) — After: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c2 not found"
    )
  }

  # Row 8: A3br1c2 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_8"]] <- list(
      label = "Leqvio (inclisiran) — After: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_leqvio_dist$data[[cut_name]][["A3br1c2_row_8"]] <- list(
      label = "Leqvio (inclisiran) — After: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br1c2 not found"
    )
  }

}

all_tables[["a3b_leqvio_dist"]] <- table_a3b_leqvio_dist
print(paste("Generated frequency table: a3b_leqvio_dist"))

# -----------------------------------------------------------------------------
# Table: a3b_nexletol_dist (frequency) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 8
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_nexletol_dist <- list(
  tableId = "a3b_nexletol_dist",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated >0% for Nexletol/Nexlizet in A3a (i.e., those who reported prescribing Nexletol without a statin).",
  userNote = "(Binned distribution of percent of patients; 0–100. Bins chosen to highlight many zeros and low values: 0, 1–15, 16–50, 51–100.)",
  tableSubtitle = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe): Distribution (Before vs After)",
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
  table_a3b_nexletol_dist$data[[cut_name]] <- list()
  table_a3b_nexletol_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br5c1 == 0
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 2: A3br5c1 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_2"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 3: A3br5c1 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_3"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_3"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 4: A3br5c1 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_4"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c1_row_4"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — Before: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c1 not found"
    )
  }

  # Row 5: A3br5c2 == 0
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_5"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_5"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c2 not found"
    )
  }

  # Row 6: A3br5c2 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_6"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_6"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c2 not found"
    )
  }

  # Row 7: A3br5c2 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_7"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_7"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c2 not found"
    )
  }

  # Row 8: A3br5c2 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_8"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_nexletol_dist$data[[cut_name]][["A3br5c2_row_8"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — After: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br5c2 not found"
    )
  }

}

all_tables[["a3b_nexletol_dist"]] <- table_a3b_nexletol_dist
print(paste("Generated frequency table: a3b_nexletol_dist"))

# -----------------------------------------------------------------------------
# Table: a3b_praluent_dist (frequency) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 8
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_praluent_dist <- list(
  tableId = "a3b_praluent_dist",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated they prescribe Praluent (alirocumab) without a statin.",
  userNote = "(Binned distribution of percent of patients; 0–100. Bins chosen to highlight many zeros and low values: 0, 1–15, 16–50, 51–100.)",
  tableSubtitle = "Praluent (alirocumab): Distribution (Before vs After)",
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
  table_a3b_praluent_dist$data[[cut_name]] <- list()
  table_a3b_praluent_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br2c1 == 0
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_1"]] <- list(
      label = "Praluent (alirocumab) — Before: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_1"]] <- list(
      label = "Praluent (alirocumab) — Before: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 2: A3br2c1 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_2"]] <- list(
      label = "Praluent (alirocumab) — Before: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_2"]] <- list(
      label = "Praluent (alirocumab) — Before: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 3: A3br2c1 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_3"]] <- list(
      label = "Praluent (alirocumab) — Before: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_3"]] <- list(
      label = "Praluent (alirocumab) — Before: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 4: A3br2c1 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_4"]] <- list(
      label = "Praluent (alirocumab) — Before: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c1_row_4"]] <- list(
      label = "Praluent (alirocumab) — Before: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c1 not found"
    )
  }

  # Row 5: A3br2c2 == 0
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_5"]] <- list(
      label = "Praluent (alirocumab) — After: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_5"]] <- list(
      label = "Praluent (alirocumab) — After: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c2 not found"
    )
  }

  # Row 6: A3br2c2 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_6"]] <- list(
      label = "Praluent (alirocumab) — After: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_6"]] <- list(
      label = "Praluent (alirocumab) — After: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c2 not found"
    )
  }

  # Row 7: A3br2c2 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_7"]] <- list(
      label = "Praluent (alirocumab) — After: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_7"]] <- list(
      label = "Praluent (alirocumab) — After: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c2 not found"
    )
  }

  # Row 8: A3br2c2 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_8"]] <- list(
      label = "Praluent (alirocumab) — After: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_praluent_dist$data[[cut_name]][["A3br2c2_row_8"]] <- list(
      label = "Praluent (alirocumab) — After: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br2c2 not found"
    )
  }

}

all_tables[["a3b_praluent_dist"]] <- table_a3b_praluent_dist
print(paste("Generated frequency table: a3b_praluent_dist"))

# -----------------------------------------------------------------------------
# Table: a3b_repatha_dist (frequency) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 8
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_repatha_dist <- list(
  tableId = "a3b_repatha_dist",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who reported prescribing Repatha without a statin (reported >0% in A3a 'Without a statin').",
  userNote = "(Binned distribution of percent of patients; 0–100. Bins chosen to highlight many zeros and low values: 0, 1–15, 16–50, 51–100.)",
  tableSubtitle = "Repatha (evolocumab): Distribution (Before vs After)",
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
  table_a3b_repatha_dist$data[[cut_name]] <- list()
  table_a3b_repatha_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br3c1 == 0
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_1"]] <- list(
      label = "Repatha (evolocumab) — Before: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_1"]] <- list(
      label = "Repatha (evolocumab) — Before: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 2: A3br3c1 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_2"]] <- list(
      label = "Repatha (evolocumab) — Before: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_2"]] <- list(
      label = "Repatha (evolocumab) — Before: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 3: A3br3c1 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_3"]] <- list(
      label = "Repatha (evolocumab) — Before: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_3"]] <- list(
      label = "Repatha (evolocumab) — Before: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 4: A3br3c1 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_4"]] <- list(
      label = "Repatha (evolocumab) — Before: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c1_row_4"]] <- list(
      label = "Repatha (evolocumab) — Before: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c1 not found"
    )
  }

  # Row 5: A3br3c2 == 0
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_5"]] <- list(
      label = "Repatha (evolocumab) — After: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_5"]] <- list(
      label = "Repatha (evolocumab) — After: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c2 not found"
    )
  }

  # Row 6: A3br3c2 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_6"]] <- list(
      label = "Repatha (evolocumab) — After: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_6"]] <- list(
      label = "Repatha (evolocumab) — After: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c2 not found"
    )
  }

  # Row 7: A3br3c2 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_7"]] <- list(
      label = "Repatha (evolocumab) — After: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_7"]] <- list(
      label = "Repatha (evolocumab) — After: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c2 not found"
    )
  }

  # Row 8: A3br3c2 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_8"]] <- list(
      label = "Repatha (evolocumab) — After: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_repatha_dist$data[[cut_name]][["A3br3c2_row_8"]] <- list(
      label = "Repatha (evolocumab) — After: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br3c2 not found"
    )
  }

}

all_tables[["a3b_repatha_dist"]] <- table_a3b_repatha_dist
print(paste("Generated frequency table: a3b_repatha_dist"))

# -----------------------------------------------------------------------------
# Table: a3b_zetia_dist (frequency) [DERIVED]
# Question: For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…
# Rows: 8
# Source: a3b
# -----------------------------------------------------------------------------

table_a3b_zetia_dist <- list(
  tableId = "a3b_zetia_dist",
  questionId = "A3b",
  questionText = "For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so…",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a3b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who indicated they prescribe Zetia (ezetimibe) without a statin (A3a 'Without a statin' > 0).",
  userNote = "(Binned distribution of percent of patients; 0–100. Bins chosen to highlight many zeros and low values: 0, 1–15, 16–50, 51–100.)",
  tableSubtitle = "Zetia (ezetimibe): Distribution (Before vs After)",
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
  table_a3b_zetia_dist$data[[cut_name]] <- list()
  table_a3b_zetia_dist$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3br4c1 == 0
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_1"]] <- list(
      label = "Zetia (ezetimibe) — Before: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_1"]] <- list(
      label = "Zetia (ezetimibe) — Before: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 2: A3br4c1 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_2"]] <- list(
      label = "Zetia (ezetimibe) — Before: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_2"]] <- list(
      label = "Zetia (ezetimibe) — Before: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 3: A3br4c1 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_3"]] <- list(
      label = "Zetia (ezetimibe) — Before: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_3"]] <- list(
      label = "Zetia (ezetimibe) — Before: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 4: A3br4c1 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_4"]] <- list(
      label = "Zetia (ezetimibe) — Before: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c1_row_4"]] <- list(
      label = "Zetia (ezetimibe) — Before: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c1 not found"
    )
  }

  # Row 5: A3br4c2 == 0
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_5"]] <- list(
      label = "Zetia (ezetimibe) — After: None (0%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_5"]] <- list(
      label = "Zetia (ezetimibe) — After: None (0%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c2 not found"
    )
  }

  # Row 6: A3br4c2 in range [1-15]
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_6"]] <- list(
      label = "Zetia (ezetimibe) — After: Low (1–15%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_6"]] <- list(
      label = "Zetia (ezetimibe) — After: Low (1–15%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c2 not found"
    )
  }

  # Row 7: A3br4c2 in range [16-50]
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 16 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_7"]] <- list(
      label = "Zetia (ezetimibe) — After: Moderate (16–50%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_7"]] <- list(
      label = "Zetia (ezetimibe) — After: Moderate (16–50%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c2 not found"
    )
  }

  # Row 8: A3br4c2 in range [51-100]
  var_col <- safe_get_var(cut_data, "A3br4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 51 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_8"]] <- list(
      label = "Zetia (ezetimibe) — After: High (51–100%)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3b_zetia_dist$data[[cut_name]][["A3br4c2_row_8"]] <- list(
      label = "Zetia (ezetimibe) — After: High (51–100%)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3br4c2 not found"
    )
  }

}

all_tables[["a3b_zetia_dist"]] <- table_a3b_zetia_dist
print(paste("Generated frequency table: a3b_zetia_dist"))

# -----------------------------------------------------------------------------
# Table: a4_last100 (mean_rows) [DERIVED]
# Question: Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)
# Rows: 7
# Source: a4
# -----------------------------------------------------------------------------

table_a4_last100 <- list(
  tableId = "a4_last100",
  questionId = "A4",
  questionText = "Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Reference counts from A3: counts out of 100 shown for LAST 100 patients)",
  tableSubtitle = "LAST 100 patients (reference from A3)",
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
# Question: Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)
# Rows: 7
# Source: a4
# -----------------------------------------------------------------------------

table_a4_next100 <- list(
  tableId = "a4_next100",
  questionId = "A4",
  questionText = "Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)",
  tableType = "mean_rows",
  isDerived = TRUE,
  sourceTableId = "a4",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Counts out of 100 under the assumed FDA indication change; values may sum to greater than 100)",
  tableSubtitle = "NEXT 100 patients (after assumed indication change)",
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
# Table: a4a_leqvio (mean_rows)
# Question: For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_leqvio <- list(
  tableId = "a4a_leqvio",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who said they would prescribe Leqvio to at least one of the NEXT 100 patients (A4r2c2 > 0)",
  userNote = "(Responses are percentages of NEXT 100 patients; for each therapy the two columns should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4r2c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4a_leqvio$data[[cut_name]] <- list()
  table_a4a_leqvio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4a_leqvio$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to a statin",
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
    table_a4a_leqvio$data[[cut_name]][["A4ar1c1"]] <- list(
      label = "Leqvio (inclisiran) — In addition to a statin",
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

    table_a4a_leqvio$data[[cut_name]][["A4ar1c2"]] <- list(
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
    table_a4a_leqvio$data[[cut_name]][["A4ar1c2"]] <- list(
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

}

all_tables[["a4a_leqvio"]] <- table_a4a_leqvio
print(paste("Generated mean_rows table: a4a_leqvio"))

# -----------------------------------------------------------------------------
# Table: a4a_praluent (mean_rows)
# Question: For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_praluent <- list(
  tableId = "a4a_praluent",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who said they would prescribe Praluent to at least one of the NEXT 100 patients (A4r3c2 > 0)",
  userNote = "(Responses are percentages of NEXT 100 patients; for each therapy the two columns should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4r3c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4a_praluent$data[[cut_name]] <- list()
  table_a4a_praluent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar2c1 (numeric summary)
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

    table_a4a_praluent$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to a statin",
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
    table_a4a_praluent$data[[cut_name]][["A4ar2c1"]] <- list(
      label = "Praluent (alirocumab) — In addition to a statin",
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

    table_a4a_praluent$data[[cut_name]][["A4ar2c2"]] <- list(
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
    table_a4a_praluent$data[[cut_name]][["A4ar2c2"]] <- list(
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

}

all_tables[["a4a_praluent"]] <- table_a4a_praluent
print(paste("Generated mean_rows table: a4a_praluent"))

# -----------------------------------------------------------------------------
# Table: a4a_repatha (mean_rows)
# Question: For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_repatha <- list(
  tableId = "a4a_repatha",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who said they would prescribe Repatha to at least one of the NEXT 100 patients (A4r4c2 > 0)",
  userNote = "(Responses are percentages of NEXT 100 patients; for each therapy the two columns should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4r4c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4a_repatha$data[[cut_name]] <- list()
  table_a4a_repatha$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar3c1 (numeric summary)
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

    table_a4a_repatha$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to a statin",
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
    table_a4a_repatha$data[[cut_name]][["A4ar3c1"]] <- list(
      label = "Repatha (evolocumab) — In addition to a statin",
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

  # Row 2: A4ar3c2 (numeric summary)
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

    table_a4a_repatha$data[[cut_name]][["A4ar3c2"]] <- list(
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
    table_a4a_repatha$data[[cut_name]][["A4ar3c2"]] <- list(
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

}

all_tables[["a4a_repatha"]] <- table_a4a_repatha
print(paste("Generated mean_rows table: a4a_repatha"))

# -----------------------------------------------------------------------------
# Table: a4a_zetia (mean_rows)
# Question: For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_zetia <- list(
  tableId = "a4a_zetia",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who said they would prescribe Zetia to at least one of the NEXT 100 patients (A4r5c2 > 0)",
  userNote = "(Responses are percentages of NEXT 100 patients; for each therapy the two columns should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4r5c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4a_zetia$data[[cut_name]] <- list()
  table_a4a_zetia$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar4c1 (numeric summary)
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

    table_a4a_zetia$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to a statin",
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
    table_a4a_zetia$data[[cut_name]][["A4ar4c1"]] <- list(
      label = "Zetia (ezetimibe) — In addition to a statin",
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

  # Row 2: A4ar4c2 (numeric summary)
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

    table_a4a_zetia$data[[cut_name]][["A4ar4c2"]] <- list(
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
    table_a4a_zetia$data[[cut_name]][["A4ar4c2"]] <- list(
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

}

all_tables[["a4a_zetia"]] <- table_a4a_zetia
print(paste("Generated mean_rows table: a4a_zetia"))

# -----------------------------------------------------------------------------
# Table: a4a_nexletol (mean_rows)
# Question: For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)
# Rows: 2
# Source: a4a
# -----------------------------------------------------------------------------

table_a4a_nexletol <- list(
  tableId = "a4a_nexletol",
  questionId = "A4a",
  questionText = "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? (Each row must add to 100%)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4a",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who said they would prescribe Nexletol/Nexlizet to at least one of the NEXT 100 patients (A4r6c2 > 0)",
  userNote = "(Responses are percentages of NEXT 100 patients; for each therapy the two columns should sum to 100%)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4r6c2 > 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a4a_nexletol$data[[cut_name]] <- list()
  table_a4a_nexletol$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4ar5c1 (numeric summary)
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

    table_a4a_nexletol$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to a statin",
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
    table_a4a_nexletol$data[[cut_name]][["A4ar5c1"]] <- list(
      label = "Nexletol / Nexlizet (bempedoic acid ± ezetimibe) — In addition to a statin",
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

  # Row 2: A4ar5c2 (numeric summary)
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

    table_a4a_nexletol$data[[cut_name]][["A4ar5c2"]] <- list(
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
    table_a4a_nexletol$data[[cut_name]][["A4ar5c2"]] <- list(
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

all_tables[["a4a_nexletol"]] <- table_a4a_nexletol
print(paste("Generated mean_rows table: a4a_nexletol"))

# -----------------------------------------------------------------------------
# Table: a4b_leqvio (mean_rows)
# Question: For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_leqvio <- list(
  tableId = "a4b_leqvio",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who indicated they would prescribe Leqvio without a statin (selected >0% in the A4a “Without a statin” column).",
  userNote = "(Percent values; for each therapy the 'Before' + 'After' percentages sum to 100% — only shown when respondent indicated they would prescribe that therapy without a statin.)",
  tableSubtitle = "",
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
  table_a4b_leqvio$data[[cut_name]] <- list()
  table_a4b_leqvio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_leqvio$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
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
    table_a4b_leqvio$data[[cut_name]][["A4br1c1"]] <- list(
      label = "Leqvio (inclisiran) — Before any other lipid‑lowering therapy (first line)",
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

    table_a4b_leqvio$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
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
    table_a4b_leqvio$data[[cut_name]][["A4br1c2"]] <- list(
      label = "Leqvio (inclisiran) — After trying another lipid‑lowering therapy",
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

all_tables[["a4b_leqvio"]] <- table_a4b_leqvio
print(paste("Generated mean_rows table: a4b_leqvio"))

# -----------------------------------------------------------------------------
# Table: a4b_praluent (mean_rows)
# Question: For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_praluent <- list(
  tableId = "a4b_praluent",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who indicated they would prescribe Praluent without a statin (selected >0% in the A4a “Without a statin” column).",
  userNote = "(Percent values; for each therapy the 'Before' + 'After' percentages sum to 100% — only shown when respondent indicated they would prescribe that therapy without a statin.)",
  tableSubtitle = "",
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
  table_a4b_praluent$data[[cut_name]] <- list()
  table_a4b_praluent$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_praluent$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
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
    table_a4b_praluent$data[[cut_name]][["A4br2c1"]] <- list(
      label = "Praluent (alirocumab) — Before any other lipid‑lowering therapy (first line)",
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

    table_a4b_praluent$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
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
    table_a4b_praluent$data[[cut_name]][["A4br2c2"]] <- list(
      label = "Praluent (alirocumab) — After trying another lipid‑lowering therapy",
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

all_tables[["a4b_praluent"]] <- table_a4b_praluent
print(paste("Generated mean_rows table: a4b_praluent"))

# -----------------------------------------------------------------------------
# Table: a4b_repatha (mean_rows)
# Question: For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_repatha <- list(
  tableId = "a4b_repatha",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who indicated they would prescribe Repatha without a statin (selected >0% in the A4a “Without a statin” column).",
  userNote = "(Percent values; for each therapy the 'Before' + 'After' percentages sum to 100% — only shown when respondent indicated they would prescribe that therapy without a statin.)",
  tableSubtitle = "",
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
  table_a4b_repatha$data[[cut_name]] <- list()
  table_a4b_repatha$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_repatha$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
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
    table_a4b_repatha$data[[cut_name]][["A4br3c1"]] <- list(
      label = "Repatha (evolocumab) — Before any other lipid‑lowering therapy (first line)",
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

    table_a4b_repatha$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
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
    table_a4b_repatha$data[[cut_name]][["A4br3c2"]] <- list(
      label = "Repatha (evolocumab) — After trying another lipid‑lowering therapy",
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

all_tables[["a4b_repatha"]] <- table_a4b_repatha
print(paste("Generated mean_rows table: a4b_repatha"))

# -----------------------------------------------------------------------------
# Table: a4b_zetia (mean_rows)
# Question: For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_zetia <- list(
  tableId = "a4b_zetia",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who indicated they would prescribe Zetia (ezetimibe) without a statin (selected >0% in the A4a “Without a statin” column).",
  userNote = "(Percent values; for each therapy the 'Before' + 'After' percentages sum to 100% — only shown when respondent indicated they would prescribe that therapy without a statin.)",
  tableSubtitle = "",
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
  table_a4b_zetia$data[[cut_name]] <- list()
  table_a4b_zetia$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_zetia$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — Before any other lipid‑lowering therapy (first line)",
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
    table_a4b_zetia$data[[cut_name]][["A4br4c1"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — Before any other lipid‑lowering therapy (first line)",
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

    table_a4b_zetia$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — After trying another lipid‑lowering therapy",
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
    table_a4b_zetia$data[[cut_name]][["A4br4c2"]] <- list(
      label = "Zetia (ezetimibe) or generic ezetimibe — After trying another lipid‑lowering therapy",
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

all_tables[["a4b_zetia"]] <- table_a4b_zetia
print(paste("Generated mean_rows table: a4b_zetia"))

# -----------------------------------------------------------------------------
# Table: a4b_nexletol (mean_rows)
# Question: For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?
# Rows: 2
# Source: a4b
# -----------------------------------------------------------------------------

table_a4b_nexletol <- list(
  tableId = "a4b_nexletol",
  questionId = "A4b",
  questionText = "For each treatment you indicated you would expect to prescribe without a statin, approximately what percentage of those patients who would receive that therapy without a statin did so before any other lipid‑lowering therapy (i.e., first line) or after trying another lipid‑lowering therapy?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "a4b",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Those who indicated they would prescribe Nexletol/Nexlizet without a statin (selected >0% in the A4a “Without a statin” column).",
  userNote = "(Percent values; for each therapy the 'Before' + 'After' percentages sum to 100% — only shown when respondent indicated they would prescribe that therapy without a statin.)",
  tableSubtitle = "",
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
  table_a4b_nexletol$data[[cut_name]] <- list()
  table_a4b_nexletol$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_a4b_nexletol$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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
    table_a4b_nexletol$data[[cut_name]][["A4br5c1"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — Before any other lipid‑lowering therapy (first line)",
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

    table_a4b_nexletol$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — After trying another lipid‑lowering therapy",
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
    table_a4b_nexletol$data[[cut_name]][["A4br5c2"]] <- list(
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — After trying another lipid‑lowering therapy",
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

all_tables[["a4b_nexletol"]] <- table_a4b_nexletol
print(paste("Generated mean_rows table: a4b_nexletol"))

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
  baseText = "Respondents who reported a change in their prescribing for Leqvio, Repatha, or Praluent (i.e., prescribing in A4 differed from A3 for any of these three therapies).",
  userNote = "(Select one; asked only of respondents who reported a prescribing change for Leqvio, Repatha, or Praluent.)",
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
      label = "Change prescribing within 6 months (NET)",
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
      label = "Change prescribing within 6 months (NET)",
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
# Table: a6_detail_A6r1 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r1 <- list(
  tableId = "a6_detail_A6r1",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r1$data[[cut_name]] <- list()
  table_a6_detail_A6r1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r1 == 1
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r1 not found"
    )
  }

  # Row 3: A6r1 == 2
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r1 not found"
    )
  }

  # Row 4: A6r1 == 3
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r1 == 4
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r1$data[[cut_name]][["A6r1_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r1"]] <- table_a6_detail_A6r1
print(paste("Generated frequency table: a6_detail_A6r1"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r2 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r2 <- list(
  tableId = "a6_detail_A6r2",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r2$data[[cut_name]] <- list()
  table_a6_detail_A6r2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r2 == 1
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r2 not found"
    )
  }

  # Row 3: A6r2 == 2
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r2 not found"
    )
  }

  # Row 4: A6r2 == 3
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r2 == 4
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r2$data[[cut_name]][["A6r2_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r2"]] <- table_a6_detail_A6r2
print(paste("Generated frequency table: a6_detail_A6r2"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r3 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r3 <- list(
  tableId = "a6_detail_A6r3",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start ezetimibe or Nexletol/Nexlizet, no statin",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r3$data[[cut_name]] <- list()
  table_a6_detail_A6r3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r3 == 1
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r3 not found"
    )
  }

  # Row 3: A6r3 == 2
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r3 not found"
    )
  }

  # Row 4: A6r3 == 3
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r3 == 4
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r3$data[[cut_name]][["A6r3_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r3"]] <- table_a6_detail_A6r3
print(paste("Generated frequency table: a6_detail_A6r3"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r4 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r4 <- list(
  tableId = "a6_detail_A6r4",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start statin first, add/switch to PCSK9i if needed",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r4$data[[cut_name]] <- list()
  table_a6_detail_A6r4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r4 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r4 == 1
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r4 not found"
    )
  }

  # Row 3: A6r4 == 2
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r4 not found"
    )
  }

  # Row 4: A6r4 == 3
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r4 == 4
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r4$data[[cut_name]][["A6r4_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r4"]] <- table_a6_detail_A6r4
print(paste("Generated frequency table: a6_detail_A6r4"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r5 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C                                                                                                                                                                         
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r5 <- list(
  tableId = "a6_detail_A6r5",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C                                                                                                                                                                         ",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start statin and PCSK9i at the same time",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r5$data[[cut_name]] <- list()
  table_a6_detail_A6r5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r5 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r5 == 1
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r5 not found"
    )
  }

  # Row 3: A6r5 == 2
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r5 not found"
    )
  }

  # Row 4: A6r5 == 3
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r5 == 4
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r5$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r5"]] <- table_a6_detail_A6r5
print(paste("Generated frequency table: a6_detail_A6r5"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r6 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r6 <- list(
  tableId = "a6_detail_A6r6",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start PCSK9i, no statin",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r6$data[[cut_name]] <- list()
  table_a6_detail_A6r6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r6 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r6 == 1
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r6 not found"
    )
  }

  # Row 3: A6r6 == 2
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r6 not found"
    )
  }

  # Row 4: A6r6 == 3
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r6 == 4
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r6$data[[cut_name]][["A6r6_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r6"]] <- table_a6_detail_A6r6
print(paste("Generated frequency table: a6_detail_A6r6"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r7 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r7 <- list(
  tableId = "a6_detail_A6r7",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r7$data[[cut_name]] <- list()
  table_a6_detail_A6r7$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r7 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r7 == 1
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r7 not found"
    )
  }

  # Row 3: A6r7 == 2
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r7 not found"
    )
  }

  # Row 4: A6r7 == 3
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r7 == 4
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r7$data[[cut_name]][["A6r7_row_5"]] <- list(
      label = "Rank 4",
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

}

all_tables[["a6_detail_A6r7"]] <- table_a6_detail_A6r7
print(paste("Generated frequency table: a6_detail_A6r7"))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r8 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6_detail_A6r8 <- list(
  tableId = "a6_detail_A6r8",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Other (Specify)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_detail_A6r8$data[[cut_name]] <- list()
  table_a6_detail_A6r8$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r8 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_1"]] <- list(
      label = "Top 2 (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_1"]] <- list(
      label = "Top 2 (NET)",
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

  # Row 2: A6r8 == 1
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_2"]] <- list(
      label = "Rank 1 (Top choice)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r8 not found"
    )
  }

  # Row 3: A6r8 == 2
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_3"]] <- list(
      label = "Rank 2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_3"]] <- list(
      label = "Rank 2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6r8 not found"
    )
  }

  # Row 4: A6r8 == 3
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_4"]] <- list(
      label = "Rank 3",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_4"]] <- list(
      label = "Rank 3",
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

  # Row 5: A6r8 == 4
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_5"]] <- list(
      label = "Rank 4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_detail_A6r8$data[[cut_name]][["A6r8_row_5"]] <- list(
      label = "Rank 4",
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

all_tables[["a6_detail_A6r8"]] <- table_a6_detail_A6r8
print(paste("Generated frequency table: a6_detail_A6r8"))

# -----------------------------------------------------------------------------
# Table: a6_rank1 (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 8
# Source: a6
# -----------------------------------------------------------------------------

table_a6_rank1 <- list(
  tableId = "a6_rank1",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "Rank 1 (Top choice)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_rank1$data[[cut_name]] <- list()
  table_a6_rank1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 1
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
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

    table_a6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r2_row_2"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
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

    table_a6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r3_row_3"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
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

    table_a6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r4_row_4"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
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

    table_a6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r5_row_5"]] <- list(
      label = "Start statin and PCSK9i at the same time",
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

    table_a6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r6_row_6"]] <- list(
      label = "Start PCSK9i, no statin",
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

    table_a6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
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

    table_a6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (Specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_rank1$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (Specify)",
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

all_tables[["a6_rank1"]] <- table_a6_rank1
print(paste("Generated frequency table: a6_rank1"))

# -----------------------------------------------------------------------------
# Table: a6_top2_comparison (frequency) [DERIVED]
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 8
# Source: a6
# -----------------------------------------------------------------------------

table_a6_top2_comparison <- list(
  tableId = "a6_top2_comparison",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a6",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Top 2 = ranked 1 or 2)",
  tableSubtitle = "Top 2 (NET) Comparison",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6_top2_comparison$data[[cut_name]] <- list()
  table_a6_top2_comparison$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6_top2_comparison$data[[cut_name]][["A6r1_row_1"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r1_row_1"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r2_row_2"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r2_row_2"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r3_row_3"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r3_row_3"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r4_row_4"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r4_row_4"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r5_row_5"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r5_row_5"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r6_row_6"]] <- list(
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
    table_a6_top2_comparison$data[[cut_name]][["A6r6_row_6"]] <- list(
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

    table_a6_top2_comparison$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2_comparison$data[[cut_name]][["A6r7_row_7"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that (Top 2)",
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

    table_a6_top2_comparison$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (Specify) (Top 2)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6_top2_comparison$data[[cut_name]][["A6r8_row_8"]] <- list(
      label = "Other (Specify) (Top 2)",
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

all_tables[["a6_top2_comparison"]] <- table_a6_top2_comparison
print(paste("Generated frequency table: a6_top2_comparison"))

# -----------------------------------------------------------------------------
# Table: a7 (frequency) [DERIVED]
# Question: How might being able to use PCSK9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing? (Select all that apply)
# Rows: 6
# Source: a7
# -----------------------------------------------------------------------------

table_a7 <- list(
  tableId = "a7",
  questionId = "A7",
  questionText = "How might being able to use PCSK9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing? (Select all that apply)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a7",
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

    table_a7$data[[cut_name]][["_NET_A7_AnyImpact_row_1"]] <- list(
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
# Table: a8_r1_full (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 18
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r1_full <- list(
  tableId = "a8_r1_full",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Full 5-point distribution for products in this patient situation; T2B = 4-5.)",
  tableSubtitle = "With established CVD — Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r1_full$data[[cut_name]] <- list()
  table_a8_r1_full$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r1c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 2: A8r1c1 == 5
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_2"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_2"]] <- list(
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

  # Row 3: A8r1c1 == 4
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_3"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_3"]] <- list(
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

  # Row 4: A8r1c1 == 3
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_4"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_4"]] <- list(
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

  # Row 5: A8r1c1 == 2
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_5"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_5"]] <- list(
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

  # Row 6: A8r1c1 == 1
  var_col <- safe_get_var(cut_data, "A8r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_6"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c1_row_6"]] <- list(
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

  # Row 7: A8r1c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r1c2 == 5
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_8"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_8"]] <- list(
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

  # Row 9: A8r1c2 == 4
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_9"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_9"]] <- list(
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

  # Row 10: A8r1c2 == 3
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_10"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_10"]] <- list(
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

  # Row 11: A8r1c2 == 2
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_11"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_11"]] <- list(
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

  # Row 12: A8r1c2 == 1
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_12"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c2_row_12"]] <- list(
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

  # Row 13: A8r1c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 14: A8r1c3 == 5
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_14"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_14"]] <- list(
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

  # Row 15: A8r1c3 == 4
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_15"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_15"]] <- list(
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

  # Row 16: A8r1c3 == 3
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_16"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_16"]] <- list(
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

  # Row 17: A8r1c3 == 2
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_17"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_17"]] <- list(
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

  # Row 18: A8r1c3 == 1
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_18"]] <- list(
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
    table_a8_r1_full$data[[cut_name]][["A8r1c3_row_18"]] <- list(
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

}

all_tables[["a8_r1_full"]] <- table_a8_r1_full
print(paste("Generated frequency table: a8_r1_full"))

# -----------------------------------------------------------------------------
# Table: a8_r2_full (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 18
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r2_full <- list(
  tableId = "a8_r2_full",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Full 5-point distribution for products in this patient situation; T2B = 4-5.)",
  tableSubtitle = "With no history of CV events and at high-risk — Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r2_full$data[[cut_name]] <- list()
  table_a8_r2_full$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r2c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 2: A8r2c1 == 5
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_2"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_2"]] <- list(
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

  # Row 3: A8r2c1 == 4
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_3"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_3"]] <- list(
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

  # Row 4: A8r2c1 == 3
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_4"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_4"]] <- list(
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

  # Row 5: A8r2c1 == 2
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_5"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_5"]] <- list(
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

  # Row 6: A8r2c1 == 1
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_6"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c1_row_6"]] <- list(
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

  # Row 7: A8r2c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r2c2 == 5
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_8"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_8"]] <- list(
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

  # Row 9: A8r2c2 == 4
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_9"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_9"]] <- list(
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

  # Row 10: A8r2c2 == 3
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_10"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_10"]] <- list(
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

  # Row 11: A8r2c2 == 2
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_11"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_11"]] <- list(
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

  # Row 12: A8r2c2 == 1
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_12"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c2_row_12"]] <- list(
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

  # Row 13: A8r2c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 14: A8r2c3 == 5
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_14"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_14"]] <- list(
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

  # Row 15: A8r2c3 == 4
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_15"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_15"]] <- list(
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

  # Row 16: A8r2c3 == 3
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_16"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_16"]] <- list(
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

  # Row 17: A8r2c3 == 2
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_17"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_17"]] <- list(
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

  # Row 18: A8r2c3 == 1
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_18"]] <- list(
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
    table_a8_r2_full$data[[cut_name]][["A8r2c3_row_18"]] <- list(
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

}

all_tables[["a8_r2_full"]] <- table_a8_r2_full
print(paste("Generated frequency table: a8_r2_full"))

# -----------------------------------------------------------------------------
# Table: a8_r3_full (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 18
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r3_full <- list(
  tableId = "a8_r3_full",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Full 5-point distribution for products in this patient situation; T2B = 4-5.)",
  tableSubtitle = "With no history of CV events and at low-to-medium risk — Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r3_full$data[[cut_name]] <- list()
  table_a8_r3_full$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r3c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 2: A8r3c1 == 5
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_2"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_2"]] <- list(
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

  # Row 3: A8r3c1 == 4
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_3"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_3"]] <- list(
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

  # Row 4: A8r3c1 == 3
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_4"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_4"]] <- list(
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

  # Row 5: A8r3c1 == 2
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_5"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_5"]] <- list(
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

  # Row 6: A8r3c1 == 1
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_6"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c1_row_6"]] <- list(
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

  # Row 7: A8r3c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r3c2 == 5
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_8"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_8"]] <- list(
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

  # Row 9: A8r3c2 == 4
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_9"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_9"]] <- list(
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

  # Row 10: A8r3c2 == 3
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_10"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_10"]] <- list(
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

  # Row 11: A8r3c2 == 2
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_11"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_11"]] <- list(
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

  # Row 12: A8r3c2 == 1
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_12"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c2_row_12"]] <- list(
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

  # Row 13: A8r3c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 14: A8r3c3 == 5
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_14"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_14"]] <- list(
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

  # Row 15: A8r3c3 == 4
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_15"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_15"]] <- list(
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

  # Row 16: A8r3c3 == 3
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_16"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_16"]] <- list(
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

  # Row 17: A8r3c3 == 2
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_17"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_17"]] <- list(
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

  # Row 18: A8r3c3 == 1
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_18"]] <- list(
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
    table_a8_r3_full$data[[cut_name]][["A8r3c3_row_18"]] <- list(
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

}

all_tables[["a8_r3_full"]] <- table_a8_r3_full
print(paste("Generated frequency table: a8_r3_full"))

# -----------------------------------------------------------------------------
# Table: a8_r4_full (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 18
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r4_full <- list(
  tableId = "a8_r4_full",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Full 5-point distribution for products in this patient situation; T2B = 4-5.)",
  tableSubtitle = "Who are not known to be compliant on statins — Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r4_full$data[[cut_name]] <- list()
  table_a8_r4_full$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r4c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 2: A8r4c1 == 5
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_2"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_2"]] <- list(
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

  # Row 3: A8r4c1 == 4
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_3"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_3"]] <- list(
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

  # Row 4: A8r4c1 == 3
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_4"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_4"]] <- list(
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

  # Row 5: A8r4c1 == 2
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_5"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_5"]] <- list(
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

  # Row 6: A8r4c1 == 1
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_6"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c1_row_6"]] <- list(
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

  # Row 7: A8r4c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r4c2 == 5
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_8"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_8"]] <- list(
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

  # Row 9: A8r4c2 == 4
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_9"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_9"]] <- list(
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

  # Row 10: A8r4c2 == 3
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_10"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_10"]] <- list(
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

  # Row 11: A8r4c2 == 2
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_11"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_11"]] <- list(
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

  # Row 12: A8r4c2 == 1
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_12"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c2_row_12"]] <- list(
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

  # Row 13: A8r4c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 14: A8r4c3 == 5
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_14"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_14"]] <- list(
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

  # Row 15: A8r4c3 == 4
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_15"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_15"]] <- list(
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

  # Row 16: A8r4c3 == 3
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_16"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_16"]] <- list(
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

  # Row 17: A8r4c3 == 2
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_17"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_17"]] <- list(
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

  # Row 18: A8r4c3 == 1
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_18"]] <- list(
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
    table_a8_r4_full$data[[cut_name]][["A8r4c3_row_18"]] <- list(
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

}

all_tables[["a8_r4_full"]] <- table_a8_r4_full
print(paste("Generated frequency table: a8_r4_full"))

# -----------------------------------------------------------------------------
# Table: a8_r5_full (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 18
# Source: a8
# -----------------------------------------------------------------------------

table_a8_r5_full <- list(
  tableId = "a8_r5_full",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Full 5-point distribution for products in this patient situation; T2B = 4-5.)",
  tableSubtitle = "Who are intolerant of statins — Full distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_r5_full$data[[cut_name]] <- list()
  table_a8_r5_full$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8r5c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_1"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 2: A8r5c1 == 5
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_2"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_2"]] <- list(
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

  # Row 3: A8r5c1 == 4
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_3"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_3"]] <- list(
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

  # Row 4: A8r5c1 == 3
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_4"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_4"]] <- list(
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

  # Row 5: A8r5c1 == 2
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_5"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_5"]] <- list(
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

  # Row 6: A8r5c1 == 1
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_6"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c1_row_6"]] <- list(
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

  # Row 7: A8r5c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r5c2 == 5
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_8"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_8"]] <- list(
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

  # Row 9: A8r5c2 == 4
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_9"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_9"]] <- list(
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

  # Row 10: A8r5c2 == 3
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_10"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_10"]] <- list(
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

  # Row 11: A8r5c2 == 2
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_11"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_11"]] <- list(
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

  # Row 12: A8r5c2 == 1
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_12"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c2_row_12"]] <- list(
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

  # Row 13: A8r5c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_13"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 14: A8r5c3 == 5
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_14"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_14"]] <- list(
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

  # Row 15: A8r5c3 == 4
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_15"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_15"]] <- list(
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

  # Row 16: A8r5c3 == 3
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_16"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_16"]] <- list(
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

  # Row 17: A8r5c3 == 2
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_17"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_17"]] <- list(
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

  # Row 18: A8r5c3 == 1
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_18"]] <- list(
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
    table_a8_r5_full$data[[cut_name]][["A8r5c3_row_18"]] <- list(
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

}

all_tables[["a8_r5_full"]] <- table_a8_r5_full
print(paste("Generated frequency table: a8_r5_full"))

# -----------------------------------------------------------------------------
# Table: a8_t2b_by_situation (frequency) [DERIVED]
# Question: For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Rows: 20
# Source: a8
# -----------------------------------------------------------------------------

table_a8_t2b_by_situation <- list(
  tableId = "a8_t2b_by_situation",
  questionId = "A8",
  questionText = "For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a8",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(5‑point likelihood scale: 1=Not at all likely; 5=Extremely likely. Top 2 Box (T2B) = 4-5.)",
  tableSubtitle = "T2B Comparison (Very or Extremely likely)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a8_t2b_by_situation$data[[cut_name]] <- list()
  table_a8_t2b_by_situation$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - With established CVD
  table_a8_t2b_by_situation$data[[cut_name]][["_CAT__row_1"]] <- list(
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

    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c1_row_2"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 3: A8r1c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c2_row_3"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c2_row_3"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 4: A8r1c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c3_row_4"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r1c3_row_4"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 5: Category header - With no history of CV events and at high-risk
  table_a8_t2b_by_situation$data[[cut_name]][["_CAT__row_5"]] <- list(
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

  # Row 6: A8r2c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c1_row_6"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c1_row_6"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 7: A8r2c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c2_row_7"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 8: A8r2c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c3_row_8"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r2c3_row_8"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 9: Category header - With no history of CV events and at low-to-medium risk
  table_a8_t2b_by_situation$data[[cut_name]][["_CAT__row_9"]] <- list(
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

  # Row 10: A8r3c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c1_row_10"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c1_row_10"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 11: A8r3c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c2_row_11"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c2_row_11"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 12: A8r3c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c3_row_12"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r3c3_row_12"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 13: Category header - Who are not known to be compliant on statins
  table_a8_t2b_by_situation$data[[cut_name]][["_CAT__row_13"]] <- list(
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

  # Row 14: A8r4c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c1_row_14"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c1_row_14"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 15: A8r4c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c2_row_15"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c2_row_15"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 16: A8r4c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c3_row_16"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r4c3_row_16"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

  # Row 17: Category header - Who are intolerant of statins
  table_a8_t2b_by_situation$data[[cut_name]][["_CAT__row_17"]] <- list(
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

  # Row 18: A8r5c1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c1_row_18"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c1_row_18"]] <- list(
      label = "Repatha — Very or Extremely likely (T2B)",
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

  # Row 19: A8r5c2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c2_row_19"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c2_row_19"]] <- list(
      label = "Praluent — Very or Extremely likely (T2B)",
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

  # Row 20: A8r5c3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A8r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c3_row_20"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8_t2b_by_situation$data[[cut_name]][["A8r5c3_row_20"]] <- list(
      label = "Leqvio — Very or Extremely likely (T2B)",
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

all_tables[["a8_t2b_by_situation"]] <- table_a8_t2b_by_situation
print(paste("Generated frequency table: a8_t2b_by_situation"))

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
  userNote = "(Any issues = Some issues or Significant issues; Select one for each product)",
  tableSubtitle = "Any issues (Some or Significant) - Comparison",
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
      label = "Repatha — Any issues (NET)",
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
      label = "Repatha — Any issues (NET)",
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
      label = "Praluent — Any issues (NET)",
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
      label = "Praluent — Any issues (NET)",
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
      label = "Leqvio — Any issues (NET)",
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
      label = "Leqvio — Any issues (NET)",
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
  userNote = "(Any issues = Some issues or Significant issues; Select one for each product)",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
  userNote = "(Any issues = Some issues or Significant issues; Select one for each product)",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
  userNote = "(Any issues = Some issues or Significant issues; Select one for each product)",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
# Table: a10 (frequency) [DERIVED]
# Question: For what reasons are you using PCSK9 inhibitors without a statin today?
# Rows: 7
# Source: a10
# -----------------------------------------------------------------------------

table_a10 <- list(
  tableId = "a10",
  questionId = "A10",
  questionText = "For what reasons are you using PCSK9 inhibitors without a statin today?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a10",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "Respondents who qualified for the main survey (passed screener)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a10$data[[cut_name]] <- list()
  table_a10$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any reason for prescribing PCSK9s without a statin (NET) (components: A10r1, A10r2, A10r3, A10r4, A10r5)
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
      label = "Any reason for prescribing PCSK9s without a statin (NET)",
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
      label = "Haven't prescribed PCSK9s without a statin",
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
      label = "Haven't prescribed PCSK9s without a statin",
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
# Table: b1_binned (frequency) [DERIVED]
# Question: What percentage of your current patients are covered by each type of insurance?
# Rows: 47
# Source: b1
# -----------------------------------------------------------------------------

table_b1_binned <- list(
  tableId = "b1_binned",
  questionId = "B1",
  questionText = "What percentage of your current patients are covered by each type of insurance?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "b1",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Bins show percent of respondents reporting that range for each insurance type. Respondents were instructed that percentages across insurance types should sum to 100%.)",
  tableSubtitle = "Distribution (binned ranges)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b1_binned$data[[cut_name]] <- list()
  table_b1_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Not insured
  table_b1_binned$data[[cut_name]][["B1r1_row_1"]] <- list(
    label = "Not insured",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: B1r1 == 0
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r1_row_2"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r1_row_2"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r1 not found"
    )
  }

  # Row 3: B1r1 in range [1-4]
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r1_row_3"]] <- list(
      label = "1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r1_row_3"]] <- list(
      label = "1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r1 not found"
    )
  }

  # Row 4: B1r1 in range [5-9]
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r1_row_4"]] <- list(
      label = "5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r1_row_4"]] <- list(
      label = "5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r1 not found"
    )
  }

  # Row 5: B1r1 in range [10-15]
  var_col <- safe_get_var(cut_data, "B1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r1_row_5"]] <- list(
      label = "10-15%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r1_row_5"]] <- list(
      label = "10-15%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r1 not found"
    )
  }

  # Row 6: Category header - Private insurance provided by employer / purchased in exchange
  table_b1_binned$data[[cut_name]][["B1r2_row_6"]] <- list(
    label = "Private insurance provided by employer / purchased in exchange",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 7: B1r2 == 0
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_7"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_7"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 8: B1r2 in range [1-9]
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_8"]] <- list(
      label = "1-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_8"]] <- list(
      label = "1-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 9: B1r2 in range [10-24]
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_9"]] <- list(
      label = "10-24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_9"]] <- list(
      label = "10-24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 10: B1r2 in range [25-49]
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_10"]] <- list(
      label = "25-49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_10"]] <- list(
      label = "25-49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 11: B1r2 in range [50-74]
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 74, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_11"]] <- list(
      label = "50-74%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_11"]] <- list(
      label = "50-74%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 12: B1r2 in range [75-100]
  var_col <- safe_get_var(cut_data, "B1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 75 & as.numeric(var_col) <= 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r2_row_12"]] <- list(
      label = "75-100%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r2_row_12"]] <- list(
      label = "75-100%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r2 not found"
    )
  }

  # Row 13: Category header - Traditional Medicare (Medicare Part B Fee for Service)
  table_b1_binned$data[[cut_name]][["B1r3_row_13"]] <- list(
    label = "Traditional Medicare (Medicare Part B Fee for Service)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 14: B1r3 == 0
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r3_row_14"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r3_row_14"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 15: B1r3 in range [1-9]
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r3_row_15"]] <- list(
      label = "1-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r3_row_15"]] <- list(
      label = "1-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 16: B1r3 in range [10-24]
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r3_row_16"]] <- list(
      label = "10-24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r3_row_16"]] <- list(
      label = "10-24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 17: B1r3 in range [25-49]
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r3_row_17"]] <- list(
      label = "25-49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r3_row_17"]] <- list(
      label = "25-49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 18: B1r3 in range [50-80]
  var_col <- safe_get_var(cut_data, "B1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 80, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r3_row_18"]] <- list(
      label = "50-80%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r3_row_18"]] <- list(
      label = "50-80%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r3 not found"
    )
  }

  # Row 19: Category header - Traditional Medicare with supplemental insurance
  table_b1_binned$data[[cut_name]][["B1r4_row_19"]] <- list(
    label = "Traditional Medicare with supplemental insurance",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 20: B1r4 == 0
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r4_row_20"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r4_row_20"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 21: B1r4 in range [1-9]
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r4_row_21"]] <- list(
      label = "1-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r4_row_21"]] <- list(
      label = "1-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 22: B1r4 in range [10-24]
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r4_row_22"]] <- list(
      label = "10-24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r4_row_22"]] <- list(
      label = "10-24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 23: B1r4 in range [25-49]
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r4_row_23"]] <- list(
      label = "25-49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r4_row_23"]] <- list(
      label = "25-49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 24: B1r4 in range [50-60]
  var_col <- safe_get_var(cut_data, "B1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 60, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r4_row_24"]] <- list(
      label = "50-60%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r4_row_24"]] <- list(
      label = "50-60%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r4 not found"
    )
  }

  # Row 25: Category header - Private Medicare (Medicare Advantage / Part C managed through Private payer)
  table_b1_binned$data[[cut_name]][["B1r5_row_25"]] <- list(
    label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 26: B1r5 == 0
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r5_row_26"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r5_row_26"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 27: B1r5 in range [1-9]
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r5_row_27"]] <- list(
      label = "1-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r5_row_27"]] <- list(
      label = "1-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 28: B1r5 in range [10-24]
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r5_row_28"]] <- list(
      label = "10-24%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r5_row_28"]] <- list(
      label = "10-24%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 29: B1r5 in range [25-49]
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r5_row_29"]] <- list(
      label = "25-49%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r5_row_29"]] <- list(
      label = "25-49%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 30: B1r5 in range [50-60]
  var_col <- safe_get_var(cut_data, "B1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 50 & as.numeric(var_col) <= 60, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r5_row_30"]] <- list(
      label = "50-60%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r5_row_30"]] <- list(
      label = "50-60%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r5 not found"
    )
  }

  # Row 31: Category header - Medicaid
  table_b1_binned$data[[cut_name]][["B1r6_row_31"]] <- list(
    label = "Medicaid",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 32: B1r6 == 0
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r6_row_32"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r6_row_32"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 33: B1r6 in range [1-9]
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r6_row_33"]] <- list(
      label = "1-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r6_row_33"]] <- list(
      label = "1-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 34: B1r6 in range [10-19]
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r6_row_34"]] <- list(
      label = "10-19%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r6_row_34"]] <- list(
      label = "10-19%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 35: B1r6 in range [20-29]
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 20 & as.numeric(var_col) <= 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r6_row_35"]] <- list(
      label = "20-29%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r6_row_35"]] <- list(
      label = "20-29%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 36: B1r6 in range [30-40]
  var_col <- safe_get_var(cut_data, "B1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 30 & as.numeric(var_col) <= 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r6_row_36"]] <- list(
      label = "30-40%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r6_row_36"]] <- list(
      label = "30-40%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r6 not found"
    )
  }

  # Row 37: Category header - Veterans Administration (VA)
  table_b1_binned$data[[cut_name]][["B1r7_row_37"]] <- list(
    label = "Veterans Administration (VA)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 38: B1r7 == 0
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r7_row_38"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r7_row_38"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r7 not found"
    )
  }

  # Row 39: B1r7 in range [1-4]
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r7_row_39"]] <- list(
      label = "1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r7_row_39"]] <- list(
      label = "1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r7 not found"
    )
  }

  # Row 40: B1r7 in range [5-9]
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r7_row_40"]] <- list(
      label = "5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r7_row_40"]] <- list(
      label = "5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r7 not found"
    )
  }

  # Row 41: B1r7 in range [10-15]
  var_col <- safe_get_var(cut_data, "B1r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r7_row_41"]] <- list(
      label = "10-15%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r7_row_41"]] <- list(
      label = "10-15%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r7 not found"
    )
  }

  # Row 42: Category header - Other
  table_b1_binned$data[[cut_name]][["B1r8_row_42"]] <- list(
    label = "Other",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 43: B1r8 == 0
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 0, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r8_row_43"]] <- list(
      label = "0%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r8_row_43"]] <- list(
      label = "0%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

  # Row 44: B1r8 in range [1-4]
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 1 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r8_row_44"]] <- list(
      label = "1-4%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r8_row_44"]] <- list(
      label = "1-4%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

  # Row 45: B1r8 in range [5-9]
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r8_row_45"]] <- list(
      label = "5-9%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r8_row_45"]] <- list(
      label = "5-9%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

  # Row 46: B1r8 in range [10-14]
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r8_row_46"]] <- list(
      label = "10-14%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r8_row_46"]] <- list(
      label = "10-14%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

  # Row 47: B1r8 in range [15-20]
  var_col <- safe_get_var(cut_data, "B1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 15 & as.numeric(var_col) <= 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b1_binned$data[[cut_name]][["B1r8_row_47"]] <- list(
      label = "15-20%",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b1_binned$data[[cut_name]][["B1r8_row_47"]] <- list(
      label = "15-20%",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B1r8 not found"
    )
  }

}

all_tables[["b1_binned"]] <- table_b1_binned
print(paste("Generated frequency table: b1_binned"))

# -----------------------------------------------------------------------------
# Table: b1_mean (mean_rows)
# Question: What percentage of your current patients are covered by each type of insurance?
# Rows: 8
# Source: b1
# -----------------------------------------------------------------------------

table_b1_mean <- list(
  tableId = "b1_mean",
  questionId = "B1",
  questionText = "What percentage of your current patients are covered by each type of insurance?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "b1",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Respondents allocated percentages across insurance types; totals should sum to 100% per respondent.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_b1_mean$data[[cut_name]] <- list()
  table_b1_mean$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

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

    table_b1_mean$data[[cut_name]][["B1r1"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r1"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r2"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r2"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r3"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r3"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r4"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r4"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
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
    table_b1_mean$data[[cut_name]][["B1r5"]] <- list(
      label = "Private Medicare (Medicare Advantage / Part C managed through Private payer)",
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

    table_b1_mean$data[[cut_name]][["B1r6"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r6"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r7"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r7"]] <- list(
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

    table_b1_mean$data[[cut_name]][["B1r8"]] <- list(
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
    table_b1_mean$data[[cut_name]][["B1r8"]] <- list(
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

all_tables[["b1_mean"]] <- table_b1_mean
print(paste("Generated mean_rows table: b1_mean"))

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
  userNote = "(Select one)",
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
# -----------------------------------------------------------------------------

table_b4 <- list(
  tableId = "b4",
  questionId = "B4",
  questionText = "How many physicians are in your practice?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Numeric open-end: enter number of physicians in your practice)",
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
      label = "Number of physicians in practice",
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
      label = "Number of physicians in practice",
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
# Rows: 6
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
  baseText = "",
  userNote = "(Binned distribution using sample quartiles)",
  tableSubtitle = "Distribution (binned)",
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
      label = "Solo practice (1 physician)",
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
      label = "Solo practice (1 physician)",
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

  # Row 2: B4 in range [2-1000]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 2 & as.numeric(var_col) <= 1000, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_2"]] <- list(
      label = "Multi-physician (2+ physicians) (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_2"]] <- list(
      label = "Multi-physician (2+ physicians) (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 3: B4 in range [2-3]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 2 & as.numeric(var_col) <= 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_3"]] <- list(
      label = "2-3 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_3"]] <- list(
      label = "2-3 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 4: B4 in range [4-7]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 4 & as.numeric(var_col) <= 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_4"]] <- list(
      label = "4-7 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_4"]] <- list(
      label = "4-7 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 5: B4 in range [8-22]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 8 & as.numeric(var_col) <= 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_5"]] <- list(
      label = "8-22 physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_5"]] <- list(
      label = "8-22 physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable B4 not found"
    )
  }

  # Row 6: B4 in range [23-1000]
  var_col <- safe_get_var(cut_data, "B4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 23 & as.numeric(var_col) <= 1000, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_b4_binned$data[[cut_name]][["B4_row_6"]] <- list(
      label = "23 or more physicians",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_b4_binned$data[[cut_name]][["B4_row_6"]] <- list(
      label = "23 or more physicians",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
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
  baseText = "Asked of respondents who indicated Internal Medicine / General Practitioner / Primary Care / Family Practice as their specialty",
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

  # Row 1: NET - Any of the following (NET) (components: B5r1, B5r2, B5r3, B5r4, B5r5)
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
      label = "Any of the following (NET)",
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
# Source: qcard_specialty
# -----------------------------------------------------------------------------

table_qcard_specialty <- list(
  tableId = "qcard_specialty",
  questionId = "qCARD_SPECIALTY",
  questionText = "What is your primary specialty/role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qcard_specialty",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Grouped variable: original specialty list collapsed into two categories in the datamap)",
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
      label = "Cardiologist (CARD)",
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
      label = "Cardiologist (CARD)",
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
      label = "Nephrologist / Endocrinologist / Lipidologist (NEPH/ENDO/LIP)",
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
      label = "Nephrologist / Endocrinologist / Lipidologist (NEPH/ENDO/LIP)",
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
  surveySection = "FINAL SCREEN",
  baseText = "",
  userNote = "(Select one)",
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
      label = "Yes, I would be willing to participate in a follow-up interview for additional compensation",
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
      label = "Yes, I would be willing to participate in a follow-up interview for additional compensation",
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
      label = "No, I am not interested in participating in a follow-up interview for additional compensation",
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
      label = "No, I am not interested in participating in a follow-up interview for additional compensation",
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
# Table: qon_list_off_list_by_provider (frequency) [DERIVED]
# Question: ON-LIST/OFF-LIST
# Rows: 9
# Source: qon_list_off_list
# -----------------------------------------------------------------------------

table_qon_list_off_list_by_provider <- list(
  tableId = "qon_list_off_list_by_provider",
  questionId = "qON_LIST_OFF_LIST",
  questionText = "ON-LIST/OFF-LIST",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "qon_list_off_list",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Recruitment list membership — 'ON-LIST' indicates priority account)",
  tableSubtitle = "By provider type (Totals)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qon_list_off_list_by_provider$data[[cut_name]] <- list()
  table_qon_list_off_list_by_provider$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qON_LIST_OFF_LIST IN (1, 2)
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "Cardiologist (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "Cardiologist (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 2: qON_LIST_OFF_LIST == 1
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 3: qON_LIST_OFF_LIST == 2
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "Cardiologist — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "Cardiologist — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 4: qON_LIST_OFF_LIST IN (3, 4)
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(3, 4), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "Primary care physician (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "Primary care physician (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 5: qON_LIST_OFF_LIST == 3
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "Primary care physician — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "Primary care physician — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 6: qON_LIST_OFF_LIST == 4
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "Primary care physician — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "Primary care physician — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 7: qON_LIST_OFF_LIST IN (5, 6)
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(5, 6), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_7"]] <- list(
      label = "NP/PA (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_7"]] <- list(
      label = "NP/PA (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 8: qON_LIST_OFF_LIST == 5
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_8"]] <- list(
      label = "NP/PA — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_8"]] <- list(
      label = "NP/PA — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 9: qON_LIST_OFF_LIST == 6
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_9"]] <- list(
      label = "NP/PA — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_by_provider$data[[cut_name]][["qON_LIST_OFF_LIST_row_9"]] <- list(
      label = "NP/PA — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

}

all_tables[["qon_list_off_list_by_provider"]] <- table_qon_list_off_list_by_provider
print(paste("Generated frequency table: qon_list_off_list_by_provider"))

# -----------------------------------------------------------------------------
# Table: qon_list_off_list_on_vs_off (frequency) [DERIVED]
# Question: ON-LIST/OFF-LIST
# Rows: 8
# Source: qon_list_off_list
# -----------------------------------------------------------------------------

table_qon_list_off_list_on_vs_off <- list(
  tableId = "qon_list_off_list_on_vs_off",
  questionId = "qON_LIST_OFF_LIST",
  questionText = "ON-LIST/OFF-LIST",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "qon_list_off_list",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Recruitment list membership — 'ON-LIST' indicates priority account)",
  tableSubtitle = "On-list vs Off-list (Totals)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_qon_list_off_list_on_vs_off$data[[cut_name]] <- list()
  table_qon_list_off_list_on_vs_off$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: qON_LIST_OFF_LIST IN (1, 3, 5)
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 3, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "On-list (Priority accounts) (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_1"]] <- list(
      label = "On-list (Priority accounts) (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 2: qON_LIST_OFF_LIST == 1
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_2"]] <- list(
      label = "Cardiologist — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
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

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "Primary care physician — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_3"]] <- list(
      label = "Primary care physician — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 4: qON_LIST_OFF_LIST == 5
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "NP/PA — On-list (Priority account)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_4"]] <- list(
      label = "NP/PA — On-list (Priority account)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 5: qON_LIST_OFF_LIST IN (2, 4, 6)
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 4, 6), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "Off-list (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_5"]] <- list(
      label = "Off-list (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 6: qON_LIST_OFF_LIST == 2
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "Cardiologist — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_6"]] <- list(
      label = "Cardiologist — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 7: qON_LIST_OFF_LIST == 4
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_7"]] <- list(
      label = "Primary care physician — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_7"]] <- list(
      label = "Primary care physician — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

  # Row 8: qON_LIST_OFF_LIST == 6
  var_col <- safe_get_var(cut_data, "qON_LIST_OFF_LIST")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_8"]] <- list(
      label = "NP/PA — Off-list",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qon_list_off_list_on_vs_off$data[[cut_name]][["qON_LIST_OFF_LIST_row_8"]] <- list(
      label = "NP/PA — Off-list",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qON_LIST_OFF_LIST not found"
    )
  }

}

all_tables[["qon_list_off_list_on_vs_off"]] <- table_qon_list_off_list_on_vs_off
print(paste("Generated frequency table: qon_list_off_list_on_vs_off"))

# -----------------------------------------------------------------------------
# Table: qspecialty (frequency)
# Question: What is your primary specialty/role?
# Rows: 4
# Source: qspecialty
# -----------------------------------------------------------------------------

table_qspecialty <- list(
  tableId = "qspecialty",
  questionId = "qSPECIALTY",
  questionText = "What is your primary specialty/role?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qspecialty",
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

  # Row 1: qSPECIALTY IN (1, 2)
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
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
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_1"]] <- list(
      label = "Physicians (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 2: qSPECIALTY == 1
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
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
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_2"]] <- list(
      label = "Cardiologist",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 3: qSPECIALTY == 2
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
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
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_3"]] <- list(
      label = "Internal Medicine / General Practitioner / Primary Care / Family Practice",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable qSPECIALTY not found"
    )
  }

  # Row 4: qSPECIALTY == 3
  var_col <- safe_get_var(cut_data, "qSPECIALTY")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_4"]] <- list(
      label = "Nurse Practitioner / Physician Assistant (NP/PA)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_qspecialty$data[[cut_name]][["qSPECIALTY_row_4"]] <- list(
      label = "Nurse Practitioner / Physician Assistant (NP/PA)",
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
  baseText = "Asked only of respondents who identified their primary specialty as Cardiologist (S2 = Cardiologist).",
  userNote = "",
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
# Table: region (frequency)
# Question: Region
# Rows: 6
# Source: region
# -----------------------------------------------------------------------------

table_region <- list(
  tableId = "region",
  questionId = "Region",
  questionText = "Region",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "region",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Derived from main practice ZIP code; hidden field)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
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
      sig_vs_total = NA
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
      sig_vs_total = NA,
      error = "Variable Region not found"
    )
  }

}

all_tables[["region"]] <- table_region
print(paste("Generated frequency table: region"))

# -----------------------------------------------------------------------------
# Table: us_state (frequency)
# Question: State of main practice location (derived from zip code provided in B2)
# Rows: 53
# -----------------------------------------------------------------------------

table_us_state <- list(
  tableId = "us_state",
  questionId = "US_State",
  questionText = "State of main practice location (derived from zip code provided in B2)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Derived from practice zip code provided in B2; state and region are system-derived fields.)",
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

# -----------------------------------------------------------------------------
# Table: us_state_region (frequency) [DERIVED]
# Question: State of main practice location (derived from zip code provided in B2)
# Rows: 6
# Source: us_state
# -----------------------------------------------------------------------------

table_us_state_region <- list(
  tableId = "us_state_region",
  questionId = "US_State",
  questionText = "State of main practice location (derived from zip code provided in B2)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "us_state",
  surveySection = "CLASSIFICATION INFORMATION",
  baseText = "",
  userNote = "(Derived from practice zip code provided in B2; regions follow U.S. Census definitions.)",
  tableSubtitle = "Region summary (Census regions)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_us_state_region$data[[cut_name]] <- list()
  table_us_state_region$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: US_State IN (7, 20, 22, 31, 32, 35, 39, 40, 47)
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(7, 20, 22, 31, 32, 35, 39, 40, 47), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Northeast (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state_region$data[[cut_name]][["US_State_row_1"]] <- list(
      label = "Northeast (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 2: US_State IN (13, 15, 16, 17, 23, 24, 25, 29, 30, 36, 42, 49)
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(13, 15, 16, 17, 23, 24, 25, 29, 30, 36, 42, 49), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Midwest (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state_region$data[[cut_name]][["US_State_row_2"]] <- list(
      label = "Midwest (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 3: US_State IN (2, 3, 8, 9, 10, 11, 18, 19, 21, 26, 28, 37, 41, 43, 44, 46, 50)
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(2, 3, 8, 9, 10, 11, 18, 19, 21, 26, 28, 37, 41, 43, 44, 46, 50), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "South (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state_region$data[[cut_name]][["US_State_row_3"]] <- list(
      label = "South (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 4: US_State IN (1, 4, 5, 6, 12, 14, 27, 33, 34, 38, 45, 48, 51)
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 4, 5, 6, 12, 14, 27, 33, 34, 38, 45, 48, 51), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "West (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_us_state_region$data[[cut_name]][["US_State_row_4"]] <- list(
      label = "West (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable US_State not found"
    )
  }

  # Row 5: US_State == 52
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 52, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_5"]] <- list(
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
    table_us_state_region$data[[cut_name]][["US_State_row_5"]] <- list(
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

  # Row 6: US_State == 53
  var_col <- safe_get_var(cut_data, "US_State")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 53, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_us_state_region$data[[cut_name]][["US_State_row_6"]] <- list(
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
    table_us_state_region$data[[cut_name]][["US_State_row_6"]] <- list(
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

all_tables[["us_state_region"]] <- table_us_state_region
print(paste("Generated frequency table: us_state_region"))

# Table: s5 (excluded: Screener question — options 1–6 were disqualifying/termination criteria during screening. Among qualified respondents this question is expected to be trivial (virtually all 'None of these'), so move to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: s5 (frequency) [DERIVED]
# Question: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?
# Rows: 7
# Source: s5
# -----------------------------------------------------------------------------

table_s5 <- list(
  tableId = "s5",
  questionId = "S5",
  questionText = "Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s5",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select all that apply — selecting any of the listed affiliations led to termination during screening)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Screener question — options 1–6 were disqualifying/termination criteria during screening. Among qualified respondents this question is expected to be trivial (virtually all 'None of these'), so move to reference sheet.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s5$data[[cut_name]] <- list()
  table_s5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S5r1 == 1
  var_col <- safe_get_var(cut_data, "S5r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r1_row_1"]] <- list(
      label = "Advertising Agency",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r1_row_1"]] <- list(
      label = "Advertising Agency",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r1 not found"
    )
  }

  # Row 2: S5r2 == 1
  var_col <- safe_get_var(cut_data, "S5r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r2_row_2"]] <- list(
      label = "Marketing / Market Research Firm",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r2_row_2"]] <- list(
      label = "Marketing / Market Research Firm",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r2 not found"
    )
  }

  # Row 3: S5r3 == 1
  var_col <- safe_get_var(cut_data, "S5r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r3_row_3"]] <- list(
      label = "Public Relations Firm",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r3_row_3"]] <- list(
      label = "Public Relations Firm",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r3 not found"
    )
  }

  # Row 4: S5r4 == 1
  var_col <- safe_get_var(cut_data, "S5r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r4_row_4"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r4_row_4"]] <- list(
      label = "Any media company (Print, Radio, TV, Internet)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r4 not found"
    )
  }

  # Row 5: S5r5 == 1
  var_col <- safe_get_var(cut_data, "S5r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r5_row_5"]] <- list(
      label = "Pharmaceutical drug / device manufacturer (outside of clinical trials)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r5_row_5"]] <- list(
      label = "Pharmaceutical drug / device manufacturer (outside of clinical trials)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r5 not found"
    )
  }

  # Row 6: S5r6 == 1
  var_col <- safe_get_var(cut_data, "S5r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r6_row_6"]] <- list(
      label = "Governmental regulatory agency (e.g., Food & Drug Administration (FDA))",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5r6_row_6"]] <- list(
      label = "Governmental regulatory agency (e.g., Food & Drug Administration (FDA))",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5r6 not found"
    )
  }

  # Row 7: S5r7 == 1
  var_col <- safe_get_var(cut_data, "S5r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5r7_row_7"]] <- list(
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
    table_s5$data[[cut_name]][["S5r7_row_7"]] <- list(
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

# Table: s7 (excluded: Screener qualification question (Part-Time responses were set to terminate); administrative qualification variable not needed in main results—moved to reference sheet.) - still calculating for reference

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
  userNote = "(Screener question; Part-Time respondents were terminated per survey design)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Screener qualification question (Part-Time responses were set to terminate); administrative qualification variable not needed in main results—moved to reference sheet.",
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

# Table: a4 (excluded: Split into two derived mean_rows tables (LAST 100 and NEXT 100) for readability; overview moved to reference sheet.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a4 (mean_rows)
# Question: Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)
# Rows: 14
# -----------------------------------------------------------------------------

table_a4 <- list(
  tableId = "a4",
  questionId = "A4",
  questionText = "Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? (Responses are counts out of 100 and may sum to more than 100. Your responses from the previous question are included for reference.)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Overview table; LAST 100 values are from A3 shown for reference; NEXT 100 are under the assumed FDA change)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Split into two derived mean_rows tables (LAST 100 and NEXT 100) for readability; overview moved to reference sheet.",
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
      label = "Statin only (i.e., no additional therapy) — LAST 100 (reference)",
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
      label = "Statin only (i.e., no additional therapy) — LAST 100 (reference)",
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
      label = "Leqvio (inclisiran) — LAST 100 (reference)",
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
      label = "Leqvio (inclisiran) — LAST 100 (reference)",
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
      label = "Praluent (alirocumab) — LAST 100 (reference)",
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
      label = "Praluent (alirocumab) — LAST 100 (reference)",
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
      label = "Repatha (evolocumab) — LAST 100 (reference)",
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
      label = "Repatha (evolocumab) — LAST 100 (reference)",
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
      label = "Zetia (ezetimibe) or generic ezetimibe — LAST 100 (reference)",
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
      label = "Zetia (ezetimibe) or generic ezetimibe — LAST 100 (reference)",
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
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — LAST 100 (reference)",
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
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — LAST 100 (reference)",
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
      label = "Other — LAST 100 (reference)",
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
      label = "Other — LAST 100 (reference)",
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
      label = "Statin only (i.e., no additional therapy) — NEXT 100 (after assumed indication change)",
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
      label = "Statin only (i.e., no additional therapy) — NEXT 100 (after assumed indication change)",
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
      label = "Leqvio (inclisiran) — NEXT 100 (after assumed indication change)",
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
      label = "Leqvio (inclisiran) — NEXT 100 (after assumed indication change)",
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
      label = "Praluent (alirocumab) — NEXT 100 (after assumed indication change)",
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
      label = "Praluent (alirocumab) — NEXT 100 (after assumed indication change)",
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
      label = "Repatha (evolocumab) — NEXT 100 (after assumed indication change)",
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
      label = "Repatha (evolocumab) — NEXT 100 (after assumed indication change)",
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
      label = "Zetia (ezetimibe) or generic ezetimibe — NEXT 100 (after assumed indication change)",
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
      label = "Zetia (ezetimibe) or generic ezetimibe — NEXT 100 (after assumed indication change)",
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
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — NEXT 100 (after assumed indication change)",
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
      label = "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) — NEXT 100 (after assumed indication change)",
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
      label = "Other — NEXT 100 (after assumed indication change)",
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
      label = "Other — NEXT 100 (after assumed indication change)",
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

# Table: a6 (excluded: Overview ranking table (flat) moved to reference; split into derived ranking views (Rank 1 comparison, Top-2 comparison, and per-item detail tables) for readability.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: a6 (frequency)
# Question: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.
# Rows: 29
# -----------------------------------------------------------------------------

table_a6 <- list(
  tableId = "a6",
  questionId = "A6",
  questionText = "Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C‑lowering therapies, in adults with primary hyperlipidemia – and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank which treatment paths you might be most likely to follow. You can rank your top 4 paths.",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS",
  baseText = "",
  userNote = "(Rank up to 4; 1 = most preferred)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview ranking table (flat) moved to reference; split into derived ranking views (Rank 1 comparison, Top-2 comparison, and per-item detail tables) for readability.",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a6$data[[cut_name]] <- list()
  table_a6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6r1 == 1
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r1_row_1"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
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

  # Row 2: A6r1 == 2
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r1_row_2"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r1_row_2"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
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

  # Row 3: A6r1 == 3
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r1_row_3"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r1_row_3"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
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

  # Row 4: A6r1 == 4
  var_col <- safe_get_var(cut_data, "A6r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r1_row_4"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r1_row_4"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed",
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

  # Row 5: A6r2 == 1
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r2_row_5"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r2_row_5"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
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

  # Row 6: A6r2 == 2
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r2_row_6"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r2_row_6"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
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

  # Row 7: A6r2 == 3
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r2_row_7"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r2_row_7"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
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

  # Row 8: A6r2 == 4
  var_col <- safe_get_var(cut_data, "A6r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r2_row_8"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r2_row_8"]] <- list(
      label = "Start statin and ezetimibe or Nexletol/Nexlizet at the same time",
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

  # Row 9: A6r3 == 1
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r3_row_9"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r3_row_9"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
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

  # Row 10: A6r3 == 2
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r3_row_10"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r3_row_10"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
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

  # Row 11: A6r3 == 3
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r3_row_11"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r3_row_11"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
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

  # Row 12: A6r3 == 4
  var_col <- safe_get_var(cut_data, "A6r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r3_row_12"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r3_row_12"]] <- list(
      label = "Start ezetimibe or Nexletol/Nexlizet, no statin",
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

  # Row 13: A6r4 == 1
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r4_row_13"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r4_row_13"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
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

  # Row 14: A6r4 == 2
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r4_row_14"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r4_row_14"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
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

  # Row 15: A6r4 == 3
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r4_row_15"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r4_row_15"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
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

  # Row 16: A6r4 == 4
  var_col <- safe_get_var(cut_data, "A6r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r4_row_16"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r4_row_16"]] <- list(
      label = "Start statin first, add/switch to PCSK9i if needed",
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

  # Row 17: A6r5 == 1
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r5_row_17"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r5_row_17"]] <- list(
      label = "Start statin and PCSK9i at the same time",
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

  # Row 18: A6r5 == 2
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r5_row_18"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r5_row_18"]] <- list(
      label = "Start statin and PCSK9i at the same time",
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

  # Row 19: A6r5 == 3
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r5_row_19"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r5_row_19"]] <- list(
      label = "Start statin and PCSK9i at the same time",
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

  # Row 20: A6r5 == 4
  var_col <- safe_get_var(cut_data, "A6r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r5_row_20"]] <- list(
      label = "Start statin and PCSK9i at the same time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r5_row_20"]] <- list(
      label = "Start statin and PCSK9i at the same time",
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

  # Row 21: A6r6 == 1
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r6_row_21"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r6_row_21"]] <- list(
      label = "Start PCSK9i, no statin",
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

  # Row 22: A6r6 == 2
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r6_row_22"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r6_row_22"]] <- list(
      label = "Start PCSK9i, no statin",
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

  # Row 23: A6r6 == 3
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r6_row_23"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r6_row_23"]] <- list(
      label = "Start PCSK9i, no statin",
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

  # Row 24: A6r6 == 4
  var_col <- safe_get_var(cut_data, "A6r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r6_row_24"]] <- list(
      label = "Start PCSK9i, no statin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r6_row_24"]] <- list(
      label = "Start PCSK9i, no statin",
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

  # Row 25: A6r7 == 1
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r7_row_25"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r7_row_25"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
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

  # Row 26: A6r7 == 2
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r7_row_26"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r7_row_26"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
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

  # Row 27: A6r7 == 3
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r7_row_27"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r7_row_27"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
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

  # Row 28: A6r7 == 4
  var_col <- safe_get_var(cut_data, "A6r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r7_row_28"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r7_row_28"]] <- list(
      label = "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that",
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

  # Row 29: A6r8 == 3
  var_col <- safe_get_var(cut_data, "A6r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6r8_row_29"]] <- list(
      label = "Other (Specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6r8_row_29"]] <- list(
      label = "Other (Specify)",
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

all_tables[["a6"]] <- table_a6
print(paste("Generated frequency table: a6"))

# Table: a8 (excluded: Overview flat grid excluded and replaced by a T2B comparison table and per-situation detail tables for readability) - still calculating for reference

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
  userNote = "(Original flat grid excluded; see derived T2B and per-situation detail tables)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview flat grid excluded and replaced by a T2B comparison table and per-situation detail tables for readability",
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

# Table: a9 (excluded: Overview moved to reference sheet — split into a comparison (Any issues NET) and three product-level detail tables for readability) - still calculating for reference

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
  userNote = "",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview moved to reference sheet — split into a comparison (Any issues NET) and three product-level detail tables for readability",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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
      label = "Haven't prescribed without a statin",
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

# Table: qlist_priority_account (excluded: Administrative recruitment tag (sampling segmentation). This variable identifies whether a respondent came from the priority account list and is a study/sample control variable; move to the reference sheet rather than the main report.) - still calculating for reference

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
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Administrative recruitment flag used for sampling; see reference sheet)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative recruitment tag (sampling segmentation). This variable identifies whether a respondent came from the priority account list and is a study/sample control variable; move to the reference sheet rather than the main report.",
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
      label = "PRIORITY",
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
      label = "PRIORITY",
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
      label = "NOT PRIORITY",
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
      label = "NOT PRIORITY",
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

# Table: qlist_tier (excluded: Administrative variable (recruitment/list tier). Not a substantive survey question; move to reference sheet for analysts.) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qlist_tier (frequency)
# Question: qLIST_TIER: LIST TIER
# Rows: 4
# Source: qlist_tier
# -----------------------------------------------------------------------------

table_qlist_tier <- list(
  tableId = "qlist_tier",
  questionId = "qLIST_TIER",
  questionText = "qLIST_TIER: LIST TIER",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qlist_tier",
  surveySection = "",
  baseText = "",
  userNote = "(Administrative: respondent recruitment/list tier — reference only)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Administrative variable (recruitment/list tier). Not a substantive survey question; move to reference sheet for analysts.",
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

# Table: qon_list_off_list (excluded: Overview excluded and moved to reference sheet; split into clearer derived views (provider-type totals and On-list vs Off-list).) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qon_list_off_list (frequency)
# Question: ON-LIST/OFF-LIST
# Rows: 6
# Source: qon_list_off_list
# -----------------------------------------------------------------------------

table_qon_list_off_list <- list(
  tableId = "qon_list_off_list",
  questionId = "qON_LIST_OFF_LIST",
  questionText = "ON-LIST/OFF-LIST",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "qon_list_off_list",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Recruitment list membership — 'ON-LIST' indicates priority account)",
  tableSubtitle = "",
  excluded = TRUE,
  excludeReason = "Overview excluded and moved to reference sheet; split into clearer derived views (provider-type totals and On-list vs Off-list).",
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
      label = "Cardiologist — On-list (Priority account)",
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
      label = "Cardiologist — On-list (Priority account)",
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
      label = "Cardiologist — Off-list",
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
      label = "Cardiologist — Off-list",
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
      label = "Primary care physician — On-list (Priority account)",
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
      label = "Primary care physician — On-list (Priority account)",
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
      label = "Primary care physician — Off-list",
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
      label = "Primary care physician — Off-list",
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
      label = "NP/PA — On-list (Priority account)",
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
      label = "NP/PA — On-list (Priority account)",
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
      label = "NP/PA — Off-list",
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
      label = "NP/PA — Off-list",
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

# Table: qtype_of_card_reference (excluded: Reference row for datamap mapping; not for publication display) - still calculating for reference

# -----------------------------------------------------------------------------
# Table: qtype_of_card_reference (frequency) [DERIVED]
# Question: Variable metadata (reference)
# Rows: 1
# Source: qtype_of_card
# -----------------------------------------------------------------------------

table_qtype_of_card_reference <- list(
  tableId = "qtype_of_card_reference",
  questionId = "qTYPE_OF_CARD",
  questionText = "Variable metadata (reference)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "qtype_of_card",
  surveySection = "SCREENER",
  baseText = "Those who indicated their primary specialty is Cardiologist (S2 = 1)",
  userNote = "(Reference: datamap value labels)",
  tableSubtitle = "Datamap Mapping",
  excluded = TRUE,
  excludeReason = "Reference row for datamap mapping; not for publication display",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S2 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_qtype_of_card_reference$data[[cut_name]] <- list()
  table_qtype_of_card_reference$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Datamap values: 1=Interventional Card, 2=General Card, 3=Preventative Card
  table_qtype_of_card_reference$data[[cut_name]][["qTYPE_OF_CARD_row_1"]] <- list(
    label = "Datamap values: 1=Interventional Card, 2=General Card, 3=Preventative Card",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

}

all_tables[["qtype_of_card_reference"]] <- table_qtype_of_card_reference
print(paste("Generated frequency table: qtype_of_card_reference"))

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
    generatedAt = "2026-02-06T14:28:08.641Z",
    tableCount = 104,
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