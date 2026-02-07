# HawkTab AI - R Script V2
# Session: pipeline-2026-02-07T13-38-58-276Z
# Generated: 2026-02-07T13:49:36.391Z
# Tables: 63 (0 skipped due to validation errors)
# Cuts: 20
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
# Loop Stacking: Create stacked data frames for looped questions
# 1 loop group(s) detected
# =============================================================================

# --- stacked_loop_1: 89 variables x 2 iterations ---
# Skeleton: A-N-_-N + A-N-_-N-r-N-oe + hCHANNEL-_-N-r-N + A-N-_-N-r-N + A-N-b-_-N-r-N + pagetimeA-N-_-N
# Iterations: 1, 2

stacked_loop_1 <- dplyr::bind_rows(
  data %>% dplyr::rename(A10 = A10_1, A11 = A11_1, A13 = A13_1, A15 = A15_1, A18 = A18_1, A1 = A1_1, A2 = A2_1, A3 = A3_1, A4 = A4_1, A5 = A5_1, A6 = A6_1, A8 = A8_1, A13r99oe = A13_1r99oe, A16r10oe = A16_1r10oe, A17r9oe = A17_1r9oe, A18r8oe = A18_1r8oe, A19r11oe = A19_1r11oe, A4r15oe = A4_1r15oe, hCHANNELr1 = hCHANNEL_1r1, hCHANNELr2 = hCHANNEL_1r2, hCHANNELr3 = hCHANNEL_1r3, hCHANNELr4 = hCHANNEL_1r4, hCHANNELr5 = hCHANNEL_1r5, A16r1 = A16_1r1, A16r10 = A16_1r10, A16r2 = A16_1r2, A16r3 = A16_1r3, A16r4 = A16_1r4, A16r5 = A16_1r5, A16r6 = A16_1r6, A16r7 = A16_1r7, A16r8 = A16_1r8, A16r9 = A16_1r9, A17r1 = A17_1r1, A17r2 = A17_1r2, A17r3 = A17_1r3, A17r4 = A17_1r4, A17r5 = A17_1r5, A17r6 = A17_1r6, A17r7 = A17_1r7, A17r8 = A17_1r8, A17r9 = A17_1r9, A19r1 = A19_1r1, A19r10 = A19_1r10, A19r11 = A19_1r11, A19r12 = A19_1r12, A19r2 = A19_1r2, A19r3 = A19_1r3, A19r4 = A19_1r4, A19r5 = A19_1r5, A19r6 = A19_1r6, A19r7 = A19_1r7, A19r8 = A19_1r8, A19r9 = A19_1r9, A7r1 = A7_1r1, A7r2 = A7_1r2, A7r3 = A7_1r3, A7r4 = A7_1r4, A7r5 = A7_1r5, A7r6 = A7_1r6, A9r1 = A9_1r1, A9r2 = A9_1r2, A9r3 = A9_1r3, A9r4 = A9_1r4, A9r5 = A9_1r5, A9r6 = A9_1r6, A9r7 = A9_1r7, A13br1 = A13b_1r1, A13br2 = A13b_1r2, A13br3 = A13b_1r3, A13br4 = A13b_1r4, A13br5 = A13b_1r5, pagetimeA10 = pagetimeA10_1, pagetimeA11 = pagetimeA11_1, pagetimeA13 = pagetimeA13_1, pagetimeA15 = pagetimeA15_1, pagetimeA16 = pagetimeA16_1, pagetimeA17 = pagetimeA17_1, pagetimeA18 = pagetimeA18_1, pagetimeA19 = pagetimeA19_1, pagetimeA1 = pagetimeA1_1, pagetimeA2 = pagetimeA2_1, pagetimeA3 = pagetimeA3_1, pagetimeA4 = pagetimeA4_1, pagetimeA5 = pagetimeA5_1, pagetimeA6 = pagetimeA6_1, pagetimeA7 = pagetimeA7_1, pagetimeA8 = pagetimeA8_1, pagetimeA9 = pagetimeA9_1) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(A10 = A10_2, A11 = A11_2, A13 = A13_2, A15 = A15_2, A18 = A18_2, A1 = A1_2, A2 = A2_2, A3 = A3_2, A4 = A4_2, A5 = A5_2, A6 = A6_2, A8 = A8_2, A13r99oe = A13_2r99oe, A16r10oe = A16_2r10oe, A17r9oe = A17_2r9oe, A18r8oe = A18_2r8oe, A19r11oe = A19_2r11oe, A4r15oe = A4_2r15oe, hCHANNELr1 = hCHANNEL_2r1, hCHANNELr2 = hCHANNEL_2r2, hCHANNELr3 = hCHANNEL_2r3, hCHANNELr4 = hCHANNEL_2r4, hCHANNELr5 = hCHANNEL_2r5, A16r1 = A16_2r1, A16r10 = A16_2r10, A16r2 = A16_2r2, A16r3 = A16_2r3, A16r4 = A16_2r4, A16r5 = A16_2r5, A16r6 = A16_2r6, A16r7 = A16_2r7, A16r8 = A16_2r8, A16r9 = A16_2r9, A17r1 = A17_2r1, A17r2 = A17_2r2, A17r3 = A17_2r3, A17r4 = A17_2r4, A17r5 = A17_2r5, A17r6 = A17_2r6, A17r7 = A17_2r7, A17r8 = A17_2r8, A17r9 = A17_2r9, A19r1 = A19_2r1, A19r10 = A19_2r10, A19r11 = A19_2r11, A19r12 = A19_2r12, A19r2 = A19_2r2, A19r3 = A19_2r3, A19r4 = A19_2r4, A19r5 = A19_2r5, A19r6 = A19_2r6, A19r7 = A19_2r7, A19r8 = A19_2r8, A19r9 = A19_2r9, A7r1 = A7_2r1, A7r2 = A7_2r2, A7r3 = A7_2r3, A7r4 = A7_2r4, A7r5 = A7_2r5, A7r6 = A7_2r6, A9r1 = A9_2r1, A9r2 = A9_2r2, A9r3 = A9_2r3, A9r4 = A9_2r4, A9r5 = A9_2r5, A9r6 = A9_2r6, A9r7 = A9_2r7, A13br1 = A13b_2r1, A13br2 = A13b_2r2, A13br3 = A13b_2r3, A13br4 = A13b_2r4, A13br5 = A13b_2r5, pagetimeA10 = pagetimeA10_2, pagetimeA11 = pagetimeA11_2, pagetimeA13 = pagetimeA13_2, pagetimeA15 = pagetimeA15_2, pagetimeA16 = pagetimeA16_2, pagetimeA17 = pagetimeA17_2, pagetimeA18 = pagetimeA18_2, pagetimeA19 = pagetimeA19_2, pagetimeA1 = pagetimeA1_2, pagetimeA2 = pagetimeA2_2, pagetimeA3 = pagetimeA3_2, pagetimeA4 = pagetimeA4_2, pagetimeA5 = pagetimeA5_2, pagetimeA6 = pagetimeA6_2, pagetimeA7 = pagetimeA7_2, pagetimeA8 = pagetimeA8_2, pagetimeA9 = pagetimeA9_2) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_1:", nrow(stacked_loop_1), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_1
cuts_stacked_loop_1 <- list(
  Total = rep(TRUE, nrow(stacked_loop_1))
,  `Total` = with(stacked_loop_1, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_1, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_1, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_1, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_1, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_1, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_1, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_1, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_1, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_1, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_1, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_1, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_1, S9r4 == 1)
,  `Dining` = with(stacked_loop_1, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_1, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_1, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_1, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_1, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_1, S9r16 == 1)
,  `Other` = with(stacked_loop_1, S9r99 == 1)
)


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
,  `Connection / Belonging` = with(data, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(data, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(data, (S10a == 3 | S11a == 3))
,  `Celebration` = with(data, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(data, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(data, (S10a == 6 | S11a == 6))
,  `Performance` = with(data, (S10a == 7 | S11a == 7))
,  `Tradition` = with(data, (S10a == 8 | S11a == 8))
,  `Own Home` = with(data, S9r1 == 1)
,  `Others' Home` = with(data, S9r2 == 1)
,  `Work / Office` = with(data, S9r3 == 1)
,  `College Dorm` = with(data, S9r4 == 1)
,  `Dining` = with(data, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(data, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(data, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(data, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(data, S9r15 == 1)
,  `Airport / Transit Location` = with(data, S9r16 == 1)
,  `Other` = with(data, S9r99 == 1)
)

# Stat letter mapping (for significance testing output)
cut_stat_letters <- c(
  "Total" = "T"
,  "Total" = "T"
,  "Connection / Belonging" = "A"
,  "Status / Image" = "B"
,  "Exploration / Discovery" = "C"
,  "Celebration" = "D"
,  "Indulgence" = "E"
,  "Escape / Relief" = "F"
,  "Performance" = "G"
,  "Tradition" = "H"
,  "Own Home" = "I"
,  "Others' Home" = "J"
,  "Work / Office" = "K"
,  "College Dorm" = "L"
,  "Dining" = "M"
,  "Bar / Nightclub" = "N"
,  "Hotel / Motel" = "O"
,  "Recreation / Entertainment / Concession" = "P"
,  "Outdoor Gathering" = "Q"
,  "Airport / Transit Location" = "R"
,  "Other" = "S"
)

# Group membership (for within-group comparisons)
cut_groups <- list(
  "Total" = c("Total"),
  "Needs State" = c("Connection / Belonging", "Status / Image", "Exploration / Discovery", "Celebration", "Indulgence", "Escape / Relief", "Performance", "Tradition"),
  "Location" = c("Own Home", "Others' Home", "Work / Office", "College Dorm", "Dining", "Bar / Nightclub", "Hotel / Motel", "Recreation / Entertainment / Concession", "Outdoor Gathering", "Airport / Transit Location", "Other")
)

print(paste("Defined", length(cuts), "cuts in", length(cut_groups), "groups"))

cut_stat_letters_stacked_loop_1 <- cut_stat_letters

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

  # Row: Connection / Belonging (Needs State)
  row_cut_mask <- cuts[["Connection / Belonging"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_2_A"]] <- list(
      label = "Connection / Belonging",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Status / Image (Needs State)
  row_cut_mask <- cuts[["Status / Image"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_3_B"]] <- list(
      label = "Status / Image",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Exploration / Discovery (Needs State)
  row_cut_mask <- cuts[["Exploration / Discovery"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_4_C"]] <- list(
      label = "Exploration / Discovery",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Celebration (Needs State)
  row_cut_mask <- cuts[["Celebration"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_5_D"]] <- list(
      label = "Celebration",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Indulgence (Needs State)
  row_cut_mask <- cuts[["Indulgence"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_6_E"]] <- list(
      label = "Indulgence",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Escape / Relief (Needs State)
  row_cut_mask <- cuts[["Escape / Relief"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_7_F"]] <- list(
      label = "Escape / Relief",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Performance (Needs State)
  row_cut_mask <- cuts[["Performance"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_8_G"]] <- list(
      label = "Performance",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Tradition (Needs State)
  row_cut_mask <- cuts[["Tradition"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_9_H"]] <- list(
      label = "Tradition",
      groupName = "Needs State",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Own Home (Location)
  row_cut_mask <- cuts[["Own Home"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_10_I"]] <- list(
      label = "Own Home",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Others' Home (Location)
  row_cut_mask <- cuts[["Others' Home"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_11_J"]] <- list(
      label = "Others' Home",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Work / Office (Location)
  row_cut_mask <- cuts[["Work / Office"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_12_K"]] <- list(
      label = "Work / Office",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: College Dorm (Location)
  row_cut_mask <- cuts[["College Dorm"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_13_L"]] <- list(
      label = "College Dorm",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Dining (Location)
  row_cut_mask <- cuts[["Dining"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_14_M"]] <- list(
      label = "Dining",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Bar / Nightclub (Location)
  row_cut_mask <- cuts[["Bar / Nightclub"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_15_N"]] <- list(
      label = "Bar / Nightclub",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Hotel / Motel (Location)
  row_cut_mask <- cuts[["Hotel / Motel"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_16_O"]] <- list(
      label = "Hotel / Motel",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Recreation / Entertainment / Concession (Location)
  row_cut_mask <- cuts[["Recreation / Entertainment / Concession"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_17_P"]] <- list(
      label = "Recreation / Entertainment / Concession",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Outdoor Gathering (Location)
  row_cut_mask <- cuts[["Outdoor Gathering"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_18_Q"]] <- list(
      label = "Outdoor Gathering",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Airport / Transit Location (Location)
  row_cut_mask <- cuts[["Airport / Transit Location"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_19_R"]] <- list(
      label = "Airport / Transit Location",
      groupName = "Location",
      n = base_n,
      count = row_count,
      pct = row_pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  }

  # Row: Other (Location)
  row_cut_mask <- cuts[["Other"]]
  if (!is.null(row_cut_mask)) {
    # Count respondents in this column who also match this banner cut
    combined_mask <- cuts[[cut_name]] & row_cut_mask
    combined_mask[is.na(combined_mask)] <- FALSE
    row_count <- sum(combined_mask)
    row_pct <- if (base_n > 0) round_half_up(row_count / base_n * 100) else 0

    table__demo_banner_x_banner$data[[cut_name]][["row_20_S"]] <- list(
      label = "Other",
      groupName = "Location",
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
# Table: s1 (frequency) [DERIVED]
# Question: Do you, or is any family member, currently working in one of the following industries?
# Rows: 9
# Source: s1
# -----------------------------------------------------------------------------

table_s1 <- list(
  tableId = "s1",
  questionId = "S1",
  questionText = "Do you, or is any family member, currently working in one of the following industries?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s1",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s1$data[[cut_name]] <- list()
  table_s1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any listed industry (NET) (components: S1r1, S1r2, S1r3, S1r4, S1r5, S1r6, S1r7)
  net_vars <- c("S1r1", "S1r2", "S1r3", "S1r4", "S1r5", "S1r6", "S1r7")
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

    table_s1$data[[cut_name]][["_NET_S1_AnyListedIndustry_row_1"]] <- list(
      label = "Any listed industry (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: S1r1 == 1
  var_col <- safe_get_var(cut_data, "S1r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r1_row_2"]] <- list(
      label = "Advertising",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r1_row_2"]] <- list(
      label = "Advertising",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r1 not found"
    )
  }

  # Row 3: S1r2 == 1
  var_col <- safe_get_var(cut_data, "S1r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r2_row_3"]] <- list(
      label = "Journalism",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r2_row_3"]] <- list(
      label = "Journalism",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r2 not found"
    )
  }

  # Row 4: S1r3 == 1
  var_col <- safe_get_var(cut_data, "S1r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r3_row_4"]] <- list(
      label = "Marketing or Market Research",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r3_row_4"]] <- list(
      label = "Marketing or Market Research",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r3 not found"
    )
  }

  # Row 5: S1r4 == 1
  var_col <- safe_get_var(cut_data, "S1r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r4_row_5"]] <- list(
      label = "Travel and Tourism",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r4_row_5"]] <- list(
      label = "Travel and Tourism",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r4 not found"
    )
  }

  # Row 6: S1r5 == 1
  var_col <- safe_get_var(cut_data, "S1r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r5_row_6"]] <- list(
      label = "Food and Beverage (manufacturing or distribution)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r5_row_6"]] <- list(
      label = "Food and Beverage (manufacturing or distribution)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r5 not found"
    )
  }

  # Row 7: S1r6 == 1
  var_col <- safe_get_var(cut_data, "S1r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r6_row_7"]] <- list(
      label = "Finance, Banking, or Insurance",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r6_row_7"]] <- list(
      label = "Finance, Banking, or Insurance",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r6 not found"
    )
  }

  # Row 8: S1r7 == 1
  var_col <- safe_get_var(cut_data, "S1r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r7_row_8"]] <- list(
      label = "Retail (hypermarkets or supermarket)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r7_row_8"]] <- list(
      label = "Retail (hypermarkets or supermarket)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r7 not found"
    )
  }

  # Row 9: S1r8 == 1
  var_col <- safe_get_var(cut_data, "S1r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s1$data[[cut_name]][["S1r8_row_9"]] <- list(
      label = "None of the above (exclusive)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s1$data[[cut_name]][["S1r8_row_9"]] <- list(
      label = "None of the above (exclusive)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S1r8 not found"
    )
  }

}

all_tables[["s1"]] <- table_s1
print(paste("Generated frequency table: s1"))

# -----------------------------------------------------------------------------
# Table: s2 (mean_rows)
# Question: What is your age?
# Rows: 1
# Source: s2
# -----------------------------------------------------------------------------

table_s2 <- list(
  tableId = "s2",
  questionId = "S2",
  questionText = "What is your age?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s2",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Entered as whole years; respondents under 21 or 75+ were terminated)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2$data[[cut_name]] <- list()
  table_s2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s2$data[[cut_name]][["S2"]] <- list(
      label = "Age (years)",
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
    table_s2$data[[cut_name]][["S2"]] <- list(
      label = "Age (years)",
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
      error = "Variable S2 not found"
    )
  }

}

all_tables[["s2"]] <- table_s2
print(paste("Generated mean_rows table: s2"))

# -----------------------------------------------------------------------------
# Table: s2_bins (frequency) [DERIVED]
# Question: What is your age?
# Rows: 6
# Source: s2
# -----------------------------------------------------------------------------

table_s2_bins <- list(
  tableId = "s2_bins",
  questionId = "S2",
  questionText = "What is your age?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s2",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned distribution created to mirror hAge census balancing groups)",
  tableSubtitle = "Age distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s2_bins$data[[cut_name]] <- list()
  table_s2_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S2 in range [21-24]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 21 & as.numeric(var_col) <= 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_1"]] <- list(
      label = "21-24",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_1"]] <- list(
      label = "21-24",
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

  # Row 2: S2 in range [25-34]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 25 & as.numeric(var_col) <= 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_2"]] <- list(
      label = "25-34",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_2"]] <- list(
      label = "25-34",
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

  # Row 3: S2 in range [35-44]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 35 & as.numeric(var_col) <= 44, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_3"]] <- list(
      label = "35-44",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_3"]] <- list(
      label = "35-44",
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

  # Row 4: S2 in range [45-54]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 45 & as.numeric(var_col) <= 54, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_4"]] <- list(
      label = "45-54",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_4"]] <- list(
      label = "45-54",
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

  # Row 5: S2 in range [55-64]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 55 & as.numeric(var_col) <= 64, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_5"]] <- list(
      label = "55-64",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_5"]] <- list(
      label = "55-64",
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

  # Row 6: S2 in range [65-74]
  var_col <- safe_get_var(cut_data, "S2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 65 & as.numeric(var_col) <= 74, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s2_bins$data[[cut_name]][["S2_row_6"]] <- list(
      label = "65-74",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s2_bins$data[[cut_name]][["S2_row_6"]] <- list(
      label = "65-74",
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

all_tables[["s2_bins"]] <- table_s2_bins
print(paste("Generated frequency table: s2_bins"))

# -----------------------------------------------------------------------------
# Table: s3 (frequency)
# Question: How would you describe your gender?
# Rows: 4
# Source: s3
# -----------------------------------------------------------------------------

table_s3 <- list(
  tableId = "s3",
  questionId = "S3",
  questionText = "How would you describe your gender?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s3",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Single select)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s3$data[[cut_name]] <- list()
  table_s3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S3 == 1
  var_col <- safe_get_var(cut_data, "S3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3$data[[cut_name]][["S3_row_1"]] <- list(
      label = "Male",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3$data[[cut_name]][["S3_row_1"]] <- list(
      label = "Male",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3 not found"
    )
  }

  # Row 2: S3 == 2
  var_col <- safe_get_var(cut_data, "S3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3$data[[cut_name]][["S3_row_2"]] <- list(
      label = "Female",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3$data[[cut_name]][["S3_row_2"]] <- list(
      label = "Female",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3 not found"
    )
  }

  # Row 3: S3 == 3
  var_col <- safe_get_var(cut_data, "S3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3$data[[cut_name]][["S3_row_3"]] <- list(
      label = "In another way",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3$data[[cut_name]][["S3_row_3"]] <- list(
      label = "In another way",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3 not found"
    )
  }

  # Row 4: S3 == 4
  var_col <- safe_get_var(cut_data, "S3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s3$data[[cut_name]][["S3_row_4"]] <- list(
      label = "Prefer not to answer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s3$data[[cut_name]][["S3_row_4"]] <- list(
      label = "Prefer not to answer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S3 not found"
    )
  }

}

all_tables[["s3"]] <- table_s3
print(paste("Generated frequency table: s3"))

# -----------------------------------------------------------------------------
# Table: s5 (frequency)
# Question: Which category includes your total annual household income before taxes in 2024?
# Rows: 13
# Source: s5
# -----------------------------------------------------------------------------

table_s5 <- list(
  tableId = "s5",
  questionId = "S5",
  questionText = "Which category includes your total annual household income before taxes in 2024?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s5",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s5$data[[cut_name]] <- list()
  table_s5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S5 IN (1, 2)
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_1"]] <- list(
      label = "Lower income (Under $50,000) (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_1"]] <- list(
      label = "Lower income (Under $50,000) (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 2: S5 == 1
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_2"]] <- list(
      label = "Less than $30,000",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_2"]] <- list(
      label = "Less than $30,000",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 3: S5 == 2
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_3"]] <- list(
      label = "$30,000 - $49,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_3"]] <- list(
      label = "$30,000 - $49,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 4: S5 IN (3, 4)
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(3, 4), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_4"]] <- list(
      label = "Middle income ($50,000 - $99,999) (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_4"]] <- list(
      label = "Middle income ($50,000 - $99,999) (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 5: S5 == 3
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_5"]] <- list(
      label = "$50,000 - $74,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_5"]] <- list(
      label = "$50,000 - $74,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 6: S5 == 4
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_6"]] <- list(
      label = "$75,000 - $99,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_6"]] <- list(
      label = "$75,000 - $99,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 7: S5 IN (5, 6, 7, 8, 9)
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(5, 6, 7, 8, 9), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_7"]] <- list(
      label = "Higher income ($100,000 or greater) (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_7"]] <- list(
      label = "Higher income ($100,000 or greater) (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 8: S5 == 5
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_8"]] <- list(
      label = "$100,000 - $124,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_8"]] <- list(
      label = "$100,000 - $124,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 9: S5 == 6
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_9"]] <- list(
      label = "$125,000 - $149,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_9"]] <- list(
      label = "$125,000 - $149,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 10: S5 == 7
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_10"]] <- list(
      label = "$150,000 - $174,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_10"]] <- list(
      label = "$150,000 - $174,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 11: S5 == 8
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_11"]] <- list(
      label = "$175,000 - $199,999",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_11"]] <- list(
      label = "$175,000 - $199,999",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 12: S5 == 9
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_12"]] <- list(
      label = "$200,000 or greater",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_12"]] <- list(
      label = "$200,000 or greater",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

  # Row 13: S5 == 10
  var_col <- safe_get_var(cut_data, "S5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s5$data[[cut_name]][["S5_row_13"]] <- list(
      label = "Prefer not to answer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s5$data[[cut_name]][["S5_row_13"]] <- list(
      label = "Prefer not to answer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S5 not found"
    )
  }

}

all_tables[["s5"]] <- table_s5
print(paste("Generated frequency table: s5"))

# -----------------------------------------------------------------------------
# Table: s6 (frequency)
# Question: Are you of Hispanic or Latino origin?
# Rows: 2
# Source: s6
# -----------------------------------------------------------------------------

table_s6 <- list(
  tableId = "s6",
  questionId = "S6",
  questionText = "Are you of Hispanic or Latino origin?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s6",
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
  table_s6$data[[cut_name]] <- list()
  table_s6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S6 == 1
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_1"]] <- list(
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
    table_s6$data[[cut_name]][["S6_row_1"]] <- list(
      label = "Yes",
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

  # Row 2: S6 == 2
  var_col <- safe_get_var(cut_data, "S6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6$data[[cut_name]][["S6_row_2"]] <- list(
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
    table_s6$data[[cut_name]][["S6_row_2"]] <- list(
      label = "No",
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
# Table: s6a (frequency) [DERIVED]
# Question: Which of the following best describes your family’s country or region of origin?
# Rows: 9
# Source: s6a
# -----------------------------------------------------------------------------

table_s6a <- list(
  tableId = "s6a",
  questionId = "S6a",
  questionText = "Which of the following best describes your family’s country or region of origin?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s6a",
  surveySection = "SCREENER",
  baseText = "Respondents who answered Yes to S6 (Are you of Hispanic or Latino origin?)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "S6 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_s6a$data[[cut_name]] <- list()
  table_s6a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any country/region listed (NET) (components: S6ar1, S6ar2, S6ar3, S6ar4, S6ar5, S6ar6, S6ar7, S6ar8)
  net_vars <- c("S6ar1", "S6ar2", "S6ar3", "S6ar4", "S6ar5", "S6ar6", "S6ar7", "S6ar8")
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

    table_s6a$data[[cut_name]][["_NET_S6a_Any_row_1"]] <- list(
      label = "Any country/region listed (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: S6ar1 == 1
  var_col <- safe_get_var(cut_data, "S6ar1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar1_row_2"]] <- list(
      label = "Mexico",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar1_row_2"]] <- list(
      label = "Mexico",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar1 not found"
    )
  }

  # Row 3: S6ar2 == 1
  var_col <- safe_get_var(cut_data, "S6ar2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar2_row_3"]] <- list(
      label = "Puerto Rico",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar2_row_3"]] <- list(
      label = "Puerto Rico",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar2 not found"
    )
  }

  # Row 4: S6ar3 == 1
  var_col <- safe_get_var(cut_data, "S6ar3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar3_row_4"]] <- list(
      label = "Cuba",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar3_row_4"]] <- list(
      label = "Cuba",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar3 not found"
    )
  }

  # Row 5: S6ar4 == 1
  var_col <- safe_get_var(cut_data, "S6ar4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar4_row_5"]] <- list(
      label = "Dominican Republic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar4_row_5"]] <- list(
      label = "Dominican Republic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar4 not found"
    )
  }

  # Row 6: S6ar5 == 1
  var_col <- safe_get_var(cut_data, "S6ar5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar5_row_6"]] <- list(
      label = "Central America (e.g., El Salvador, Guatemala, Honduras)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar5_row_6"]] <- list(
      label = "Central America (e.g., El Salvador, Guatemala, Honduras)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar5 not found"
    )
  }

  # Row 7: S6ar6 == 1
  var_col <- safe_get_var(cut_data, "S6ar6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar6_row_7"]] <- list(
      label = "South America (e.g., Colombia, Venezuela, Argentina)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar6_row_7"]] <- list(
      label = "South America (e.g., Colombia, Venezuela, Argentina)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar6 not found"
    )
  }

  # Row 8: S6ar7 == 1
  var_col <- safe_get_var(cut_data, "S6ar7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar7_row_8"]] <- list(
      label = "Spain",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar7_row_8"]] <- list(
      label = "Spain",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar7 not found"
    )
  }

  # Row 9: S6ar8 == 1
  var_col <- safe_get_var(cut_data, "S6ar8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s6a$data[[cut_name]][["S6ar8_row_9"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s6a$data[[cut_name]][["S6ar8_row_9"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S6ar8 not found"
    )
  }

}

all_tables[["s6a"]] <- table_s6a
print(paste("Generated frequency table: s6a"))

# -----------------------------------------------------------------------------
# Table: s7 (frequency) [DERIVED]
# Question: What is your race? (Select all that apply.)
# Rows: 7
# Source: s7
# -----------------------------------------------------------------------------

table_s7 <- list(
  tableId = "s7",
  questionId = "S7",
  questionText = "What is your race? (Select all that apply.)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s7",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s7$data[[cut_name]] <- list()
  table_s7$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any race selected (NET) (components: S7r1, S7r2, S7r3, S7r4, S7r5, S7r6)
  net_vars <- c("S7r1", "S7r2", "S7r3", "S7r4", "S7r5", "S7r6")
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

    table_s7$data[[cut_name]][["_NET_AnyRace_row_1"]] <- list(
      label = "Any race selected (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: S7r1 == 1
  var_col <- safe_get_var(cut_data, "S7r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r1_row_2"]] <- list(
      label = "White or Caucasian",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r1_row_2"]] <- list(
      label = "White or Caucasian",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r1 not found"
    )
  }

  # Row 3: S7r2 == 1
  var_col <- safe_get_var(cut_data, "S7r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r2_row_3"]] <- list(
      label = "Black, African American, or Caribbean American",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r2_row_3"]] <- list(
      label = "Black, African American, or Caribbean American",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r2 not found"
    )
  }

  # Row 4: S7r3 == 1
  var_col <- safe_get_var(cut_data, "S7r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r3_row_4"]] <- list(
      label = "American Indian or Alaska Native",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r3_row_4"]] <- list(
      label = "American Indian or Alaska Native",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r3 not found"
    )
  }

  # Row 5: S7r4 == 1
  var_col <- safe_get_var(cut_data, "S7r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r4_row_5"]] <- list(
      label = "Asian",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r4_row_5"]] <- list(
      label = "Asian",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r4 not found"
    )
  }

  # Row 6: S7r5 == 1
  var_col <- safe_get_var(cut_data, "S7r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r5_row_6"]] <- list(
      label = "Pacific Islander",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r5_row_6"]] <- list(
      label = "Pacific Islander",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r5 not found"
    )
  }

  # Row 7: S7r6 == 1
  var_col <- safe_get_var(cut_data, "S7r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s7$data[[cut_name]][["S7r6_row_7"]] <- list(
      label = "Some other race",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s7$data[[cut_name]][["S7r6_row_7"]] <- list(
      label = "Some other race",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S7r6 not found"
    )
  }

}

all_tables[["s7"]] <- table_s7
print(paste("Generated frequency table: s7"))

# -----------------------------------------------------------------------------
# Table: s8 (mean_rows)
# Question: How many alcoholic drinks, if any, have you consumed in the past week? For example, if you had 3 beers and 2 different cocktails, that would be 5 alcoholic drinks. Please provide an honest, best-estimate.
# Rows: 1
# Source: s8
# -----------------------------------------------------------------------------

table_s8 <- list(
  tableId = "s8",
  questionId = "S8",
  questionText = "How many alcoholic drinks, if any, have you consumed in the past week? For example, if you had 3 beers and 2 different cocktails, that would be 5 alcoholic drinks. Please provide an honest, best-estimate.",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s8",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Enter whole number; respondents reporting 0 drinks were terminated)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8$data[[cut_name]] <- list()
  table_s8$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S8 (numeric summary)
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s8$data[[cut_name]][["S8"]] <- list(
      label = "Number of alcoholic drinks in the past week (raw numeric)",
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
    table_s8$data[[cut_name]][["S8"]] <- list(
      label = "Number of alcoholic drinks in the past week (raw numeric)",
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
      error = "Variable S8 not found"
    )
  }

}

all_tables[["s8"]] <- table_s8
print(paste("Generated mean_rows table: s8"))

# -----------------------------------------------------------------------------
# Table: s8_binned (frequency) [DERIVED]
# Question: How many alcoholic drinks, if any, have you consumed in the past week? (Binned distribution)
# Rows: 6
# Source: s8
# -----------------------------------------------------------------------------

table_s8_binned <- list(
  tableId = "s8_binned",
  questionId = "S8",
  questionText = "How many alcoholic drinks, if any, have you consumed in the past week? (Binned distribution)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "s8",
  surveySection = "SCREENER",
  baseText = "",
  userNote = "(Binned view derived from numeric responses; bins chosen for readability)",
  tableSubtitle = "Distribution (binned)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s8_binned$data[[cut_name]] <- list()
  table_s8_binned$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Number of alcoholic drinks in the past week — distribution (binned)
  table_s8_binned$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Number of alcoholic drinks in the past week — distribution (binned)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: S8 == 1
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8_row_2"]] <- list(
      label = "1 drink",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8_row_2"]] <- list(
      label = "1 drink",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8 not found"
    )
  }

  # Row 3: S8 in range [2-4]
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 2 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8_row_3"]] <- list(
      label = "2-4 drinks (Low)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8_row_3"]] <- list(
      label = "2-4 drinks (Low)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8 not found"
    )
  }

  # Row 4: S8 in range [5-9]
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8_row_4"]] <- list(
      label = "5-9 drinks (Moderate)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8_row_4"]] <- list(
      label = "5-9 drinks (Moderate)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8 not found"
    )
  }

  # Row 5: S8 in range [10-19]
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8_row_5"]] <- list(
      label = "10-19 drinks (High)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8_row_5"]] <- list(
      label = "10-19 drinks (High)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8 not found"
    )
  }

  # Row 6: S8 in range [20-50]
  var_col <- safe_get_var(cut_data, "S8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 20 & as.numeric(var_col) <= 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s8_binned$data[[cut_name]][["S8_row_6"]] <- list(
      label = "20 or more drinks (Very high)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s8_binned$data[[cut_name]][["S8_row_6"]] <- list(
      label = "20 or more drinks (Very high)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S8 not found"
    )
  }

}

all_tables[["s8_binned"]] <- table_s8_binned
print(paste("Generated frequency table: s8_binned"))

# -----------------------------------------------------------------------------
# Table: s9 (mean_rows)
# Question: Of the alcoholic drinks you had in the past week, how many were consumed at each of the following locations? (Enter a whole number for each location.)
# Rows: 19
# Source: s9
# -----------------------------------------------------------------------------

table_s9 <- list(
  tableId = "s9",
  questionId = "S9",
  questionText = "Of the alcoholic drinks you had in the past week, how many were consumed at each of the following locations? (Enter a whole number for each location.)",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "s9",
  surveySection = "SCREENER",
  baseText = "Respondents who consumed at least one alcoholic drink in the past week",
  userNote = "(Enter whole numbers for each location; responses across locations sum to total drinks in the past week)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s9$data[[cut_name]] <- list()
  table_s9$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - On-premise (NET) (sum of component means)
  net_vars <- c("S9r5", "S9r6", "S9r7", "S9r8", "S9r9", "S9r10", "S9r11", "S9r12", "S9r13", "S9r14", "S9r16")
  component_means <- sapply(net_vars, function(v) {
    col <- safe_get_var(cut_data, v)
    if (!is.null(col)) mean(col, na.rm = TRUE) else NA
  })
  # Sum component means (valid for allocation/share questions)
  net_mean <- if (all(is.na(component_means))) NA else round_half_up(sum(component_means, na.rm = TRUE), 1)
  # Use n from first component as representative base
  first_col <- safe_get_var(cut_data, net_vars[1])
  n <- if (!is.null(first_col)) sum(!is.na(first_col)) else 0

  table_s9$data[[cut_name]][["_NET_OnPremise"]] <- list(
    label = "On-premise (NET)",
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

  # Row 2: S9r5 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r5")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r5"]] <- list(
      label = "At a casual dining restaurant (e.g., Applebee's, Chili's)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r5"]] <- list(
      label = "At a casual dining restaurant (e.g., Applebee's, Chili's)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r5 not found"
    )
  }

  # Row 3: S9r6 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r6")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r6"]] <- list(
      label = "At an upscale casual dining restaurant (e.g., Hillstone, Seasons 52, North Italia)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r6"]] <- list(
      label = "At an upscale casual dining restaurant (e.g., Hillstone, Seasons 52, North Italia)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r6 not found"
    )
  }

  # Row 4: S9r7 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r7")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r7"]] <- list(
      label = "At a fine dining restaurant (e.g., Mastro's, Capital Grille, Nick & Sam's)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r7"]] <- list(
      label = "At a fine dining restaurant (e.g., Mastro's, Capital Grille, Nick & Sam's)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r7 not found"
    )
  }

  # Row 5: S9r8 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r8")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r8"]] <- list(
      label = "At a local sports bar or pub (e.g., Irish pub, Dave & Buster's)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r8"]] <- list(
      label = "At a local sports bar or pub (e.g., Irish pub, Dave & Buster's)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r8 not found"
    )
  }

  # Row 6: S9r9 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r9")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r9"]] <- list(
      label = "At a craft cocktail bar",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r9"]] <- list(
      label = "At a craft cocktail bar",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r9 not found"
    )
  }

  # Row 7: S9r10 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r10")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r10"]] <- list(
      label = "At a premium bar or upscale lounge",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r10"]] <- list(
      label = "At a premium bar or upscale lounge",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r10 not found"
    )
  }

  # Row 8: S9r11 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r11")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r11"]] <- list(
      label = "At a nightclub",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r11"]] <- list(
      label = "At a nightclub",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r11 not found"
    )
  }

  # Row 9: S9r12 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r12")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r12"]] <- list(
      label = "At a hotel or motel",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r12"]] <- list(
      label = "At a hotel or motel",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r12 not found"
    )
  }

  # Row 10: S9r13 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r13")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r13"]] <- list(
      label = "At a recreation or entertainment venue (e.g., country club, casino, private club)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r13"]] <- list(
      label = "At a recreation or entertainment venue (e.g., country club, casino, private club)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r13 not found"
    )
  }

  # Row 11: S9r14 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r14")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r14"]] <- list(
      label = "At a concession stand or festival (e.g., stadium, live music event, food festival)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r14"]] <- list(
      label = "At a concession stand or festival (e.g., stadium, live music event, food festival)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r14 not found"
    )
  }

  # Row 12: S9r16 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r16")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r16"]] <- list(
      label = "At an airport or other transit location",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r16"]] <- list(
      label = "At an airport or other transit location",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r16 not found"
    )
  }

  # Row 13: NET - Off-premise (NET) (sum of component means)
  net_vars <- c("S9r1", "S9r2", "S9r3", "S9r4", "S9r15")
  component_means <- sapply(net_vars, function(v) {
    col <- safe_get_var(cut_data, v)
    if (!is.null(col)) mean(col, na.rm = TRUE) else NA
  })
  # Sum component means (valid for allocation/share questions)
  net_mean <- if (all(is.na(component_means))) NA else round_half_up(sum(component_means, na.rm = TRUE), 1)
  # Use n from first component as representative base
  first_col <- safe_get_var(cut_data, net_vars[1])
  n <- if (!is.null(first_col)) sum(!is.na(first_col)) else 0

  table_s9$data[[cut_name]][["_NET_OffPremise"]] <- list(
    label = "Off-premise (NET)",
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

  # Row 14: S9r1 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r1")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r1"]] <- list(
      label = "At your home",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r1"]] <- list(
      label = "At your home",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r1 not found"
    )
  }

  # Row 15: S9r2 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r2")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r2"]] <- list(
      label = "At someone else's home",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r2"]] <- list(
      label = "At someone else's home",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r2 not found"
    )
  }

  # Row 16: S9r3 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r3")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r3"]] <- list(
      label = "At work/office",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r3"]] <- list(
      label = "At work/office",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r3 not found"
    )
  }

  # Row 17: S9r4 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r4")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r4"]] <- list(
      label = "At a college/university dorm or apartment",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r4"]] <- list(
      label = "At a college/university dorm or apartment",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r4 not found"
    )
  }

  # Row 18: S9r15 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r15")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r15"]] <- list(
      label = "At an outdoor gathering (e.g., BBQ, picnic, tailgate)",
      n = n,
      mean = mean_val,
      mean_label = "Mean (overall)",
      median = median_val,
      median_label = "Median (overall)",
      sd = sd_val,
      mean_no_outliers = mean_no_out,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s9$data[[cut_name]][["S9r15"]] <- list(
      label = "At an outdoor gathering (e.g., BBQ, picnic, tailgate)",
      n = 0,
      mean = NA,
      mean_label = "Mean (overall)",
      median = NA,
      median_label = "Median (overall)",
      sd = NA,
      mean_no_outliers = NA,
      mean_no_outliers_label = "Mean (minus outliers)",
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S9r15 not found"
    )
  }

  # Row 19: S9r99 (numeric summary)
  var_col <- safe_get_var(cut_data, "S9r99")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_s9$data[[cut_name]][["S9r99"]] <- list(
      label = "Other (specify)",
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
    table_s9$data[[cut_name]][["S9r99"]] <- list(
      label = "Other (specify)",
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
      error = "Variable S9r99 not found"
    )
  }

}

all_tables[["s9"]] <- table_s9
print(paste("Generated mean_rows table: s9"))

# -----------------------------------------------------------------------------
# Table: s10a (frequency)
# Question: Which best describes the reason for having a drink in the past week?
# Rows: 8
# Source: s10a
# -----------------------------------------------------------------------------

table_s10a <- list(
  tableId = "s10a",
  questionId = "S10a",
  questionText = "Which best describes the reason for having a drink in the past week?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s10a",
  surveySection = "OCCASION LOOP",
  baseText = "Asked about the drink at the selected location",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10a$data[[cut_name]] <- list()
  table_s10a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S10a == 1
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_1"]] <- list(
      label = "A way to feel closer to others and strengthen bonds",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_1"]] <- list(
      label = "A way to feel closer to others and strengthen bonds",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 2: S10a == 2
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_2"]] <- list(
      label = "A way to demonstrate that you have good taste",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_2"]] <- list(
      label = "A way to demonstrate that you have good taste",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 3: S10a == 3
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_3"]] <- list(
      label = "A chance to try something new",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_3"]] <- list(
      label = "A chance to try something new",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 4: S10a == 4
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_4"]] <- list(
      label = "A way to celebrate or mark a moment / achievement",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_4"]] <- list(
      label = "A way to celebrate or mark a moment / achievement",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 5: S10a == 5
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_5"]] <- list(
      label = "A source of indulgence",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_5"]] <- list(
      label = "A source of indulgence",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 6: S10a == 6
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_6"]] <- list(
      label = "An escape from stress or routine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_6"]] <- list(
      label = "An escape from stress or routine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 7: S10a == 7
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_7"]] <- list(
      label = "A way to keep the night going",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_7"]] <- list(
      label = "A way to keep the night going",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

  # Row 8: S10a == 8
  var_col <- safe_get_var(cut_data, "S10a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10a$data[[cut_name]][["S10a_row_8"]] <- list(
      label = "A way to honor customs",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10a$data[[cut_name]][["S10a_row_8"]] <- list(
      label = "A way to honor customs",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10a not found"
    )
  }

}

all_tables[["s10a"]] <- table_s10a
print(paste("Generated frequency table: s10a"))

# -----------------------------------------------------------------------------
# Table: s10b (frequency)
# Question: You said your reason for having a drink in the past week was best described as [pipe: S10a lower]. More specifically, what best describes that moment?
# Rows: 46
# Source: s10b
# -----------------------------------------------------------------------------

table_s10b <- list(
  tableId = "s10b",
  questionId = "S10b",
  questionText = "You said your reason for having a drink in the past week was best described as [pipe: S10a lower]. More specifically, what best describes that moment?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s10b",
  surveySection = "OCCASION LOOP",
  baseText = "Asked of respondents in the occasion loop about the moment corresponding to the reason they selected in S10a",
  userNote = "(Shown based on S10a selection; single-select)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10b$data[[cut_name]] <- list()
  table_s10b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Connection / Belonging
  table_s10b$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Connection / Belonging",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: S10b == 1
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_2"]] <- list(
      label = "A drink to bring everyone together at the start of the night",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_2"]] <- list(
      label = "A drink to bring everyone together at the start of the night",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 3: S10b == 2
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_3"]] <- list(
      label = "Something to sip while catching up with friends",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_3"]] <- list(
      label = "Something to sip while catching up with friends",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 4: S10b == 3
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_4"]] <- list(
      label = "A drink that feels appropriate for the situation at a social gathering",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_4"]] <- list(
      label = "A drink that feels appropriate for the situation at a social gathering",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 5: S10b == 4
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_5"]] <- list(
      label = "A go-to choice for reconnecting with someone after time apart",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_5"]] <- list(
      label = "A go-to choice for reconnecting with someone after time apart",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 6: Category header - Status / Image
  table_s10b$data[[cut_name]][["_CAT__row_6"]] <- list(
    label = "Status / Image",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 7: S10b == 6
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_7"]] <- list(
      label = "A drink that makes me feel confident and put-together in social settings",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_7"]] <- list(
      label = "A drink that makes me feel confident and put-together in social settings",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 8: S10b == 7
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_8"]] <- list(
      label = "Something that looks elevated or premium when served",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_8"]] <- list(
      label = "Something that looks elevated or premium when served",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 9: S10b == 8
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_9"]] <- list(
      label = "A drink that feels on-trend or buzzworthy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_9"]] <- list(
      label = "A drink that feels on-trend or buzzworthy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 10: S10b == 9
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_10"]] <- list(
      label = "A drink I'd be proud to post or share on social media",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_10"]] <- list(
      label = "A drink I'd be proud to post or share on social media",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 11: Category header - Exploration / Discovery
  table_s10b$data[[cut_name]][["_CAT__row_11"]] <- list(
    label = "Exploration / Discovery",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 12: S10b == 11
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_12"]] <- list(
      label = "A drink I've never tried before that sparks curiosity",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_12"]] <- list(
      label = "A drink I've never tried before that sparks curiosity",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 13: S10b == 12
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_13"]] <- list(
      label = "Something with a surprising twist—flavor",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_13"]] <- list(
      label = "Something with a surprising twist—flavor",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 14: S10b == 13
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_14"]] <- list(
      label = "A limited-edition or seasonal release I want to experience before it's gone",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_14"]] <- list(
      label = "A limited-edition or seasonal release I want to experience before it's gone",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 15: S10b == 14
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_15"]] <- list(
      label = "A drink that transports me somewhere new—culturally or emotionally",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_15"]] <- list(
      label = "A drink that transports me somewhere new—culturally or emotionally",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 16: Category header - Celebration
  table_s10b$data[[cut_name]][["_CAT__row_16"]] <- list(
    label = "Celebration",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 17: S10b == 16
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_17"]] <- list(
      label = "A drink to toast a personal win or milestone",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_17"]] <- list(
      label = "A drink to toast a personal win or milestone",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 18: S10b == 17
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_18"]] <- list(
      label = "Something festive to share when good news hits",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_18"]] <- list(
      label = "Something festive to share when good news hits",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 19: S10b == 19
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_19"]] <- list(
      label = "A way to make an ordinary day or night feel a little more special",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_19"]] <- list(
      label = "A way to make an ordinary day or night feel a little more special",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 20: Category header - Indulgence
  table_s10b$data[[cut_name]][["_CAT__row_20"]] <- list(
    label = "Indulgence",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 21: S10b == 21
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_21"]] <- list(
      label = "A drink I reach for when I just want what I want",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_21"]] <- list(
      label = "A drink I reach for when I just want what I want",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 22: S10b == 24
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_22"]] <- list(
      label = "A drink that feels rich",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_22"]] <- list(
      label = "A drink that feels rich",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 23: S10b == 40
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_23"]] <- list(
      label = "A drink that feels like I'm treating myself",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_23"]] <- list(
      label = "A drink that feels like I'm treating myself",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 24: Category header - Escape / Relief
  table_s10b$data[[cut_name]][["_CAT__row_24"]] <- list(
    label = "Escape / Relief",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 25: S10b == 26
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_25"]] <- list(
      label = "A drink to help me unwind after a long or stressful day",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_25"]] <- list(
      label = "A drink to help me unwind after a long or stressful day",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 26: S10b == 27
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_26"]] <- list(
      label = "Something I reach for when I need a mental reset",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_26"]] <- list(
      label = "Something I reach for when I need a mental reset",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 27: S10b == 28
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_27"]] <- list(
      label = "A drink that helps me slow down and be present",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_27"]] <- list(
      label = "A drink that helps me slow down and be present",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 28: S10b == 29
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_28"]] <- list(
      label = "A go-to when I want to escape the usual and feel transported",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_28"]] <- list(
      label = "A go-to when I want to escape the usual and feel transported",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 29: Category header - Performance
  table_s10b$data[[cut_name]][["_CAT__row_29"]] <- list(
    label = "Performance",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 30: S10b == 31
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_30"]] <- list(
      label = "A drink that helps me feel confident and socially on-point for a night out",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_30"]] <- list(
      label = "A drink that helps me feel confident and socially on-point for a night out",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 31: S10b == 32
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_31"]] <- list(
      label = "Something I choose when I want to bring my A-game to socialize",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_31"]] <- list(
      label = "Something I choose when I want to bring my A-game to socialize",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 32: S10b == 34
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_32"]] <- list(
      label = "A go-to when I want to stay in control and keep the night flowing smoothly",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_32"]] <- list(
      label = "A go-to when I want to stay in control and keep the night flowing smoothly",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 33: Category header - Tradition
  table_s10b$data[[cut_name]][["_CAT__row_33"]] <- list(
    label = "Tradition",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 34: S10b == 36
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 36, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_34"]] <- list(
      label = "A drink that's always part of our holiday or seasonal celebrations",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_34"]] <- list(
      label = "A drink that's always part of our holiday or seasonal celebrations",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 35: S10b == 37
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_35"]] <- list(
      label = "Something I serve because it's what we've always had at family gatherings",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_35"]] <- list(
      label = "Something I serve because it's what we've always had at family gatherings",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 36: S10b == 38
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 38, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_36"]] <- list(
      label = "A drink that helps keep a cultural or regional tradition alive",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_36"]] <- list(
      label = "A drink that helps keep a cultural or regional tradition alive",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 37: S10b == 39
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 39, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_37"]] <- list(
      label = "Something I choose because it reminds me of home or loved ones",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_37"]] <- list(
      label = "Something I choose because it reminds me of home or loved ones",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 38: Category header - Other (open-ends)
  table_s10b$data[[cut_name]][["_CAT__row_38"]] <- list(
    label = "Other (open-ends)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 39: S10b == 100
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_39"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_39"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 40: S10b == 101
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 101, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_40"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_40"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 41: S10b == 102
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 102, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_41"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_41"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 42: S10b == 103
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 103, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_42"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_42"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 43: S10b == 104
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 104, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_43"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_43"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 44: S10b == 105
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 105, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_44"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_44"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 45: S10b == 106
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 106, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_45"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_45"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

  # Row 46: S10b == 107
  var_col <- safe_get_var(cut_data, "S10b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 107, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10b$data[[cut_name]][["S10b_row_46"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10b$data[[cut_name]][["S10b_row_46"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10b not found"
    )
  }

}

all_tables[["s10b"]] <- table_s10b
print(paste("Generated frequency table: s10b"))

# -----------------------------------------------------------------------------
# Table: s10c (frequency)
# Question: What type of drink did you have?
# Rows: 5
# Source: s10c
# -----------------------------------------------------------------------------

table_s10c <- list(
  tableId = "s10c",
  questionId = "S10c",
  questionText = "What type of drink did you have?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s10c",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s10c$data[[cut_name]] <- list()
  table_s10c$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S10c == 1
  var_col <- safe_get_var(cut_data, "S10c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10c$data[[cut_name]][["S10c_row_1"]] <- list(
      label = "Beer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10c$data[[cut_name]][["S10c_row_1"]] <- list(
      label = "Beer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10c not found"
    )
  }

  # Row 2: S10c == 2
  var_col <- safe_get_var(cut_data, "S10c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10c$data[[cut_name]][["S10c_row_2"]] <- list(
      label = "Wine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10c$data[[cut_name]][["S10c_row_2"]] <- list(
      label = "Wine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10c not found"
    )
  }

  # Row 3: S10c == 3
  var_col <- safe_get_var(cut_data, "S10c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10c$data[[cut_name]][["S10c_row_3"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails / Hard seltzers",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10c$data[[cut_name]][["S10c_row_3"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails / Hard seltzers",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10c not found"
    )
  }

  # Row 4: S10c == 4
  var_col <- safe_get_var(cut_data, "S10c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10c$data[[cut_name]][["S10c_row_4"]] <- list(
      label = "Liquor (mixed drink, neat, on the rocks, etc.)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10c$data[[cut_name]][["S10c_row_4"]] <- list(
      label = "Liquor (mixed drink, neat, on the rocks, etc.)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10c not found"
    )
  }

  # Row 5: S10c == 5
  var_col <- safe_get_var(cut_data, "S10c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s10c$data[[cut_name]][["S10c_row_5"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s10c$data[[cut_name]][["S10c_row_5"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S10c not found"
    )
  }

}

all_tables[["s10c"]] <- table_s10c
print(paste("Generated frequency table: s10c"))

# -----------------------------------------------------------------------------
# Table: s11a (frequency)
# Question: Which best describes the reason for having a drink in the past week?
# Rows: 8
# Source: s11a
# -----------------------------------------------------------------------------

table_s11a <- list(
  tableId = "s11a",
  questionId = "S11a",
  questionText = "Which best describes the reason for having a drink in the past week?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s11a",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11a$data[[cut_name]] <- list()
  table_s11a$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11a == 1
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_1"]] <- list(
      label = "A way to feel closer to others and strengthen bonds",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_1"]] <- list(
      label = "A way to feel closer to others and strengthen bonds",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 2: S11a == 2
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_2"]] <- list(
      label = "A way to demonstrate that you have good taste",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_2"]] <- list(
      label = "A way to demonstrate that you have good taste",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 3: S11a == 3
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_3"]] <- list(
      label = "A chance to try something new",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_3"]] <- list(
      label = "A chance to try something new",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 4: S11a == 4
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_4"]] <- list(
      label = "A way to celebrate or mark a moment / achievement",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_4"]] <- list(
      label = "A way to celebrate or mark a moment / achievement",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 5: S11a == 5
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_5"]] <- list(
      label = "A source of pleasure/indulgence",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_5"]] <- list(
      label = "A source of pleasure/indulgence",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 6: S11a == 6
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_6"]] <- list(
      label = "An escape from stress or routine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_6"]] <- list(
      label = "An escape from stress or routine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 7: S11a == 7
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_7"]] <- list(
      label = "A way to keep the night going",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_7"]] <- list(
      label = "A way to keep the night going",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

  # Row 8: S11a == 8
  var_col <- safe_get_var(cut_data, "S11a")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11a$data[[cut_name]][["S11a_row_8"]] <- list(
      label = "A way to honor customs, rituals, or family traditions",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11a$data[[cut_name]][["S11a_row_8"]] <- list(
      label = "A way to honor customs, rituals, or family traditions",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11a not found"
    )
  }

}

all_tables[["s11a"]] <- table_s11a
print(paste("Generated frequency table: s11a"))

# -----------------------------------------------------------------------------
# Table: s11b (frequency)
# Question: You said your reason for having a drink in the past week was primarily described as [pipe: S11a lower]. More specifically, how would you describe that moment?
# Rows: 37
# Source: s11b
# -----------------------------------------------------------------------------

table_s11b <- list(
  tableId = "s11b",
  questionId = "S11b",
  questionText = "You said your reason for having a drink in the past week was primarily described as [pipe: S11a lower]. More specifically, how would you describe that moment?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s11b",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents shown based on their selected primary reason (S11a) for the occasion",
  userNote = "(Select one; shown within the occasion loop — responses depend on S11a)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11b$data[[cut_name]] <- list()
  table_s11b$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11b == 1
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_1"]] <- list(
      label = "A drink to bring everyone together at the start of the night",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_1"]] <- list(
      label = "A drink to bring everyone together at the start of the night",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 2: S11b == 2
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_2"]] <- list(
      label = "Something to sip while catching up with close friends",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_2"]] <- list(
      label = "Something to sip while catching up with close friends",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 3: S11b == 3
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_3"]] <- list(
      label = "A drink that feels appropriate for the situation at a social gathering",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_3"]] <- list(
      label = "A drink that feels appropriate for the situation at a social gathering",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 4: S11b == 4
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_4"]] <- list(
      label = "A go-to choice for reconnecting with someone after time apart",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_4"]] <- list(
      label = "A go-to choice for reconnecting with someone after time apart",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 5: S11b == 6
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_5"]] <- list(
      label = "A drink that makes me feel confident and put-together in social settings",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_5"]] <- list(
      label = "A drink that makes me feel confident and put-together in social settings",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 6: S11b == 7
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_6"]] <- list(
      label = "Something that looks elevated or premium when served",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_6"]] <- list(
      label = "Something that looks elevated or premium when served",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 7: S11b == 8
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_7"]] <- list(
      label = "A drink that feels on-trend or buzzworthy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_7"]] <- list(
      label = "A drink that feels on-trend or buzzworthy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 8: S11b == 9
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_8"]] <- list(
      label = "A drink I'd be proud to post or share on social media",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_8"]] <- list(
      label = "A drink I'd be proud to post or share on social media",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 9: S11b == 11
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_9"]] <- list(
      label = "A drink I've never tried before that sparks curiosity",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_9"]] <- list(
      label = "A drink I've never tried before that sparks curiosity",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 10: S11b == 12
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_10"]] <- list(
      label = "Something with a surprising twist—flavor",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_10"]] <- list(
      label = "Something with a surprising twist—flavor",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 11: S11b == 13
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_11"]] <- list(
      label = "A limited-edition or seasonal release I want to experience before it's gone",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_11"]] <- list(
      label = "A limited-edition or seasonal release I want to experience before it's gone",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 12: S11b == 14
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_12"]] <- list(
      label = "A drink that transports me somewhere new—culturally or emotionally",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_12"]] <- list(
      label = "A drink that transports me somewhere new—culturally or emotionally",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 13: S11b == 16
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_13"]] <- list(
      label = "A drink to toast a personal win or milestone",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_13"]] <- list(
      label = "A drink to toast a personal win or milestone",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 14: S11b == 17
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_14"]] <- list(
      label = "Something festive to share when good news hits",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_14"]] <- list(
      label = "Something festive to share when good news hits",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 15: S11b == 19
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_15"]] <- list(
      label = "A way to make an ordinary day or night feel a little more special",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_15"]] <- list(
      label = "A way to make an ordinary day or night feel a little more special",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 16: S11b == 21
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_16"]] <- list(
      label = "A drink I reach for when I just want what I want",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_16"]] <- list(
      label = "A drink I reach for when I just want what I want",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 17: S11b == 24
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_17"]] <- list(
      label = "A drink that feels rich",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_17"]] <- list(
      label = "A drink that feels rich",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 18: S11b == 26
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_18"]] <- list(
      label = "A drink to help me unwind after a long or stressful day",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_18"]] <- list(
      label = "A drink to help me unwind after a long or stressful day",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 19: S11b == 27
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_19"]] <- list(
      label = "Something I reach for when I need a mental reset",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_19"]] <- list(
      label = "Something I reach for when I need a mental reset",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 20: S11b == 28
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_20"]] <- list(
      label = "A drink that helps me slow down and be present",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_20"]] <- list(
      label = "A drink that helps me slow down and be present",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 21: S11b == 29
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_21"]] <- list(
      label = "A go-to when I want to escape the usual and feel transported",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_21"]] <- list(
      label = "A go-to when I want to escape the usual and feel transported",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 22: S11b == 31
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_22"]] <- list(
      label = "A drink that helps me feel confident and socially on-point for a night out",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_22"]] <- list(
      label = "A drink that helps me feel confident and socially on-point for a night out",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 23: S11b == 32
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_23"]] <- list(
      label = "Something I choose when I want to bring my A-game to socialize",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_23"]] <- list(
      label = "Something I choose when I want to bring my A-game to socialize",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 24: S11b == 34
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_24"]] <- list(
      label = "A go-to when I want to stay in control and keep the night flowing smoothly",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_24"]] <- list(
      label = "A go-to when I want to stay in control and keep the night flowing smoothly",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 25: S11b == 36
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 36, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_25"]] <- list(
      label = "A drink that's always part of our holiday or seasonal celebrations",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_25"]] <- list(
      label = "A drink that's always part of our holiday or seasonal celebrations",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 26: S11b == 37
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_26"]] <- list(
      label = "Something I serve because it's what we've always had at family gatherings",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_26"]] <- list(
      label = "Something I serve because it's what we've always had at family gatherings",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 27: S11b == 38
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 38, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_27"]] <- list(
      label = "A drink that helps keep a cultural or regional tradition alive",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_27"]] <- list(
      label = "A drink that helps keep a cultural or regional tradition alive",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 28: S11b == 39
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 39, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_28"]] <- list(
      label = "Something I choose because it reminds me of home or loved ones",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_28"]] <- list(
      label = "Something I choose because it reminds me of home or loved ones",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 29: S11b == 40
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_29"]] <- list(
      label = "A drink that feels like I'm treating myself",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_29"]] <- list(
      label = "A drink that feels like I'm treating myself",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 30: S11b == 100
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_30"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_30"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 31: S11b == 101
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 101, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_31"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_31"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 32: S11b == 102
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 102, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_32"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_32"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 33: S11b == 103
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 103, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_33"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_33"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 34: S11b == 104
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 104, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_34"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_34"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 35: S11b == 105
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 105, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_35"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_35"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 36: S11b == 106
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 106, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_36"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_36"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

  # Row 37: S11b == 107
  var_col <- safe_get_var(cut_data, "S11b")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 107, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11b$data[[cut_name]][["S11b_row_37"]] <- list(
      label = "Other (Specify:)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11b$data[[cut_name]][["S11b_row_37"]] <- list(
      label = "Other (Specify:)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11b not found"
    )
  }

}

all_tables[["s11b"]] <- table_s11b
print(paste("Generated frequency table: s11b"))

# -----------------------------------------------------------------------------
# Table: s11c (frequency)
# Question: What type of drink did you have?
# Rows: 5
# Source: s11c
# -----------------------------------------------------------------------------

table_s11c <- list(
  tableId = "s11c",
  questionId = "S11c",
  questionText = "What type of drink did you have?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "s11c",
  surveySection = "OCCASION LOOP",
  baseText = "Asked about the drink at the occasion loop (e.g., Location 2 when in looped questions)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_s11c$data[[cut_name]] <- list()
  table_s11c$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: S11c == 1
  var_col <- safe_get_var(cut_data, "S11c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11c$data[[cut_name]][["S11c_row_1"]] <- list(
      label = "Beer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11c$data[[cut_name]][["S11c_row_1"]] <- list(
      label = "Beer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11c not found"
    )
  }

  # Row 2: S11c == 2
  var_col <- safe_get_var(cut_data, "S11c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11c$data[[cut_name]][["S11c_row_2"]] <- list(
      label = "Wine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11c$data[[cut_name]][["S11c_row_2"]] <- list(
      label = "Wine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11c not found"
    )
  }

  # Row 3: S11c == 3
  var_col <- safe_get_var(cut_data, "S11c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11c$data[[cut_name]][["S11c_row_3"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails / Hard seltzers",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11c$data[[cut_name]][["S11c_row_3"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails / Hard seltzers",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11c not found"
    )
  }

  # Row 4: S11c == 4
  var_col <- safe_get_var(cut_data, "S11c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11c$data[[cut_name]][["S11c_row_4"]] <- list(
      label = "Liquor (mixed drink, neat, on the rocks, etc.)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11c$data[[cut_name]][["S11c_row_4"]] <- list(
      label = "Liquor (mixed drink, neat, on the rocks, etc.)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11c not found"
    )
  }

  # Row 5: S11c == 5
  var_col <- safe_get_var(cut_data, "S11c")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_s11c$data[[cut_name]][["S11c_row_5"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_s11c$data[[cut_name]][["S11c_row_5"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable S11c not found"
    )
  }

}

all_tables[["s11c"]] <- table_s11c
print(paste("Generated frequency table: s11c"))

# -----------------------------------------------------------------------------
# Table: a2 (frequency) [LOOP: stacked_loop_1]
# Question: What time of day did you have this drink? (As a reminder, we’re asking about the drink you described for this occasion.)
# Rows: 9
# Source: a2
# -----------------------------------------------------------------------------

table_a2 <- list(
  tableId = "a2",
  questionId = "A2",
  questionText = "What time of day did you have this drink? (As a reminder, we’re asking about the drink you described for this occasion.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a2",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a2$data[[cut_name]] <- list()
  table_a2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A2 IN (1, 2, 3)
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_1"]] <- list(
      label = "Daytime (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_1"]] <- list(
      label = "Daytime (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 2: A2 == 1
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_2"]] <- list(
      label = "During Breakfast",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_2"]] <- list(
      label = "During Breakfast",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 3: A2 == 2
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_3"]] <- list(
      label = "Between Breakfast and Lunch",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_3"]] <- list(
      label = "Between Breakfast and Lunch",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 4: A2 == 3
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_4"]] <- list(
      label = "During Lunch",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_4"]] <- list(
      label = "During Lunch",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 5: A2 IN (4, 5, 6, 7)
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5, 6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_5"]] <- list(
      label = "Evening / Night (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_5"]] <- list(
      label = "Evening / Night (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 6: A2 == 4
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_6"]] <- list(
      label = "Before dinner / happy hour",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_6"]] <- list(
      label = "Before dinner / happy hour",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 7: A2 == 5
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_7"]] <- list(
      label = "During Dinner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_7"]] <- list(
      label = "During Dinner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 8: A2 == 6
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_8"]] <- list(
      label = "After Dinner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_8"]] <- list(
      label = "After Dinner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

  # Row 9: A2 == 7
  var_col <- safe_get_var(cut_data, "A2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a2$data[[cut_name]][["A2_row_9"]] <- list(
      label = "Late Night",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a2$data[[cut_name]][["A2_row_9"]] <- list(
      label = "Late Night",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A2 not found"
    )
  }

}

all_tables[["a2"]] <- table_a2
print(paste("Generated frequency table: a2"))

# -----------------------------------------------------------------------------
# Table: a3 (frequency) [LOOP: stacked_loop_1]
# Question: Which day of the week was this drink? As a reminder, we’re asking about the drink.
# Rows: 9
# Source: a3
# -----------------------------------------------------------------------------

table_a3 <- list(
  tableId = "a3",
  questionId = "A3",
  questionText = "Which day of the week was this drink? As a reminder, we’re asking about the drink.",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a3",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Weekday = Mon–Thu; Weekend = Fri–Sun)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a3$data[[cut_name]] <- list()
  table_a3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A3 IN (1, 2, 3, 4)
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3, 4), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_1"]] <- list(
      label = "Weekday (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_1"]] <- list(
      label = "Weekday (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 2: A3 == 1
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_2"]] <- list(
      label = "Monday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_2"]] <- list(
      label = "Monday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 3: A3 == 2
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_3"]] <- list(
      label = "Tuesday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_3"]] <- list(
      label = "Tuesday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 4: A3 == 3
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_4"]] <- list(
      label = "Wednesday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_4"]] <- list(
      label = "Wednesday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 5: A3 == 4
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_5"]] <- list(
      label = "Thursday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_5"]] <- list(
      label = "Thursday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 6: A3 IN (5, 6, 7)
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(5, 6, 7), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_6"]] <- list(
      label = "Weekend (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_6"]] <- list(
      label = "Weekend (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 7: A3 == 5
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_7"]] <- list(
      label = "Friday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_7"]] <- list(
      label = "Friday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 8: A3 == 6
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_8"]] <- list(
      label = "Saturday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_8"]] <- list(
      label = "Saturday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

  # Row 9: A3 == 7
  var_col <- safe_get_var(cut_data, "A3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a3$data[[cut_name]][["A3_row_9"]] <- list(
      label = "Sunday",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a3$data[[cut_name]][["A3_row_9"]] <- list(
      label = "Sunday",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A3 not found"
    )
  }

}

all_tables[["a3"]] <- table_a3
print(paste("Generated frequency table: a3"))

# -----------------------------------------------------------------------------
# Table: a4 (frequency) [LOOP: stacked_loop_1]
# Question: What type of drink did you have? (As a reminder, we're asking about the drink at the selected location.)
# Rows: 17
# Source: a4
# -----------------------------------------------------------------------------

table_a4 <- list(
  tableId = "a4",
  questionId = "A4",
  questionText = "What type of drink did you have? (As a reminder, we're asking about the drink at the selected location.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a4",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a4$data[[cut_name]] <- list()
  table_a4$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A4 == 1
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_1"]] <- list(
      label = "Beer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_1"]] <- list(
      label = "Beer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 2: A4 == 3
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_2"]] <- list(
      label = "Wine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_2"]] <- list(
      label = "Wine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 3: A4 == 4
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_3"]] <- list(
      label = "Sparkling Wine / Champagne",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_3"]] <- list(
      label = "Sparkling Wine / Champagne",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 4: A4 == 2
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_4"]] <- list(
      label = "Cider",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_4"]] <- list(
      label = "Cider",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 5: A4 == 5
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_5"]] <- list(
      label = "Hard Seltzer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_5"]] <- list(
      label = "Hard Seltzer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 6: A4 == 6
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_6"]] <- list(
      label = "Ready-to-Drink (RTD) Cocktail",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_6"]] <- list(
      label = "Ready-to-Drink (RTD) Cocktail",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 7: NET - Hard Seltzer / RTD (NET) (components: A4, A4)
  net_vars <- c("A4", "A4")
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

    table_a4$data[[cut_name]][["A4_row_7"]] <- list(
      label = "Hard Seltzer / RTD (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 8: A4 == 7
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_8"]] <- list(
      label = "Vodka",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_8"]] <- list(
      label = "Vodka",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 9: A4 == 8
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_9"]] <- list(
      label = "Whiskey / Bourbon",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_9"]] <- list(
      label = "Whiskey / Bourbon",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 10: A4 == 9
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_10"]] <- list(
      label = "Tequila / Mezcal",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_10"]] <- list(
      label = "Tequila / Mezcal",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 11: A4 == 10
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_11"]] <- list(
      label = "Rum",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_11"]] <- list(
      label = "Rum",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 12: A4 == 11
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_12"]] <- list(
      label = "Gin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_12"]] <- list(
      label = "Gin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 13: A4 == 12
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_13"]] <- list(
      label = "Cordial / Liqueur",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_13"]] <- list(
      label = "Cordial / Liqueur",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 14: A4 == 13
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_14"]] <- list(
      label = "Cognac",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_14"]] <- list(
      label = "Cognac",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 15: A4 == 14
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_15"]] <- list(
      label = "Aperol (aperitif)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_15"]] <- list(
      label = "Aperol (aperitif)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 16: A4 == 15
  var_col <- safe_get_var(cut_data, "A4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a4$data[[cut_name]][["A4_row_16"]] <- list(
      label = "Other type of liquor (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a4$data[[cut_name]][["A4_row_16"]] <- list(
      label = "Other type of liquor (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A4 not found"
    )
  }

  # Row 17: NET - Spirits (NET) (components: A4, A4, A4, A4, A4, A4, A4, A4, A4)
  net_vars <- c("A4", "A4", "A4", "A4", "A4", "A4", "A4", "A4", "A4")
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

    table_a4$data[[cut_name]][["A4_row_17"]] <- list(
      label = "Spirits (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

}

all_tables[["a4"]] <- table_a4
print(paste("Generated frequency table: a4"))

# -----------------------------------------------------------------------------
# Table: a5 (frequency) [LOOP: stacked_loop_1]
# Question: When you had the drink, which of the following reflects the form of the drink?
# Rows: 3
# Source: a5
# -----------------------------------------------------------------------------

table_a5 <- list(
  tableId = "a5",
  questionId = "A5",
  questionText = "When you had the drink, which of the following reflects the form of the drink?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a5",
  surveySection = "OCCASION LOOP",
  baseText = "Those who selected A4 = 7, 8, 9, 10, 11, 12, or 13 (the specified A4 types)",
  userNote = "(Select one. As a reminder, this refers to the specified drink for the occasion/location you were asked about.)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4 %in% c(7, 8, 9, 10, 11, 12, 13)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a5$data[[cut_name]] <- list()
  table_a5$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A5 == 1
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "By itself (neat, straight up, on the rocks, in a glass, etc.)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_1"]] <- list(
      label = "By itself (neat, straight up, on the rocks, in a glass, etc.)",
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

  # Row 2: A5 == 2
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "Within a cocktail",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a5$data[[cut_name]][["A5_row_2"]] <- list(
      label = "Within a cocktail",
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

  # Row 3: A5 == 3
  var_col <- safe_get_var(cut_data, "A5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
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
    table_a5$data[[cut_name]][["A5_row_3"]] <- list(
      label = "Other",
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
# Table: a6 (frequency) [LOOP: stacked_loop_1]
# Question: Which of the following reflect why you drank [pipe: A4_1]? As a reminder, we’re asking about the drink.
# Rows: 5
# Source: a6
# -----------------------------------------------------------------------------

table_a6 <- list(
  tableId = "a6",
  questionId = "A6",
  questionText = "Which of the following reflect why you drank [pipe: A4_1]? As a reminder, we’re asking about the drink.",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a6",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents for whom Location 1 is coded as on‑premise",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "hPREMISE1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a6$data[[cut_name]] <- list()
  table_a6$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A6 == 1
  var_col <- safe_get_var(cut_data, "A6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6_row_1"]] <- list(
      label = "I always order this drink when at this location",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6_row_1"]] <- list(
      label = "I always order this drink when at this location",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6 not found"
    )
  }

  # Row 2: A6 == 2
  var_col <- safe_get_var(cut_data, "A6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6_row_2"]] <- list(
      label = "After viewing the menu",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6_row_2"]] <- list(
      label = "After viewing the menu",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6 not found"
    )
  }

  # Row 3: A6 == 3
  var_col <- safe_get_var(cut_data, "A6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6_row_3"]] <- list(
      label = "A friend/family member recommended I try this drink",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6_row_3"]] <- list(
      label = "A friend/family member recommended I try this drink",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6 not found"
    )
  }

  # Row 4: A6 == 4
  var_col <- safe_get_var(cut_data, "A6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6_row_4"]] <- list(
      label = "The bartender/waiter recommended I try this drink",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6_row_4"]] <- list(
      label = "The bartender/waiter recommended I try this drink",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6 not found"
    )
  }

  # Row 5: A6 == 5
  var_col <- safe_get_var(cut_data, "A6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a6$data[[cut_name]][["A6_row_5"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a6$data[[cut_name]][["A6_row_5"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A6 not found"
    )
  }

}

all_tables[["a6"]] <- table_a6
print(paste("Generated frequency table: a6"))

# -----------------------------------------------------------------------------
# Table: a8 (frequency) [LOOP: stacked_loop_1]
# Question: Was this drink planned or unplanned?
# Rows: 4
# -----------------------------------------------------------------------------

table_a8 <- list(
  tableId = "a8",
  questionId = "A8",
  questionText = "Was this drink planned or unplanned?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents answering about a specific drinking occasion (Location 1 or Location 2 in the occasion loop)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a8$data[[cut_name]] <- list()
  table_a8$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A8 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8_row_1"]] <- list(
      label = "Planned (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8_row_1"]] <- list(
      label = "Planned (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8 not found"
    )
  }

  # Row 2: A8 == 1
  var_col <- safe_get_var(cut_data, "A8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8_row_2"]] <- list(
      label = "Planned to have a drink — knew ahead of time what it was",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8_row_2"]] <- list(
      label = "Planned to have a drink — knew ahead of time what it was",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8 not found"
    )
  }

  # Row 3: A8 == 2
  var_col <- safe_get_var(cut_data, "A8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8_row_3"]] <- list(
      label = "Planned to have a drink — planned but didn't know what it would be",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8_row_3"]] <- list(
      label = "Planned to have a drink — planned but didn't know what it would be",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8 not found"
    )
  }

  # Row 4: A8 == 3
  var_col <- safe_get_var(cut_data, "A8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a8$data[[cut_name]][["A8_row_4"]] <- list(
      label = "Did not plan to have a drink (decided in the moment)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a8$data[[cut_name]][["A8_row_4"]] <- list(
      label = "Did not plan to have a drink (decided in the moment)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A8 not found"
    )
  }

}

all_tables[["a8"]] <- table_a8
print(paste("Generated frequency table: a8"))

# -----------------------------------------------------------------------------
# Table: a10 (mean_rows) [LOOP: stacked_loop_1]
# Question: Including yourself, how many people were with you when you had this drink?
# Rows: 1
# -----------------------------------------------------------------------------

table_a10 <- list(
  tableId = "a10",
  questionId = "A10",
  questionText = "Including yourself, how many people were with you when you had this drink?",
  tableType = "mean_rows",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "Those who did NOT indicate they were alone (A9: 'I was alone' not selected)",
  userNote = "(Enter whole number; valid answers 2–30)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A9r1 == 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a10$data[[cut_name]] <- list()
  table_a10$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A10 (numeric summary)
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    # Get valid (non-NA) values
    valid_vals <- var_col[!is.na(var_col)]
    n <- length(valid_vals)

    # Calculate summary statistics (all rounded to 1 decimal)
    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA

    table_a10$data[[cut_name]][["A10"]] <- list(
      label = "Number of people present (including respondent)",
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
    table_a10$data[[cut_name]][["A10"]] <- list(
      label = "Number of people present (including respondent)",
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
      error = "Variable A10 not found"
    )
  }

}

all_tables[["a10"]] <- table_a10
print(paste("Generated mean_rows table: a10"))

# -----------------------------------------------------------------------------
# Table: a10_dist_bins (frequency) [DERIVED] [LOOP: stacked_loop_1]
# Question: Including yourself, how many people were with you when you had this drink?
# Rows: 5
# Source: a10
# -----------------------------------------------------------------------------

table_a10_dist_bins <- list(
  tableId = "a10_dist_bins",
  questionId = "A10",
  questionText = "Including yourself, how many people were with you when you had this drink?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a10",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "Those who did NOT indicate they were alone (A9: 'I was alone' not selected)",
  userNote = "(Binned distribution of number of people present; original variable is numeric 2–30)",
  tableSubtitle = "Number of people present: binned distribution",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A9r1 == 0")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a10_dist_bins$data[[cut_name]] <- list()
  table_a10_dist_bins$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A10 == 2
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10_dist_bins$data[[cut_name]][["A10_row_1"]] <- list(
      label = "2 (Just you + 1 other)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10_dist_bins$data[[cut_name]][["A10_row_1"]] <- list(
      label = "2 (Just you + 1 other)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10 not found"
    )
  }

  # Row 2: A10 in range [3-4]
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 3 & as.numeric(var_col) <= 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10_dist_bins$data[[cut_name]][["A10_row_2"]] <- list(
      label = "3-4 people",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10_dist_bins$data[[cut_name]][["A10_row_2"]] <- list(
      label = "3-4 people",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10 not found"
    )
  }

  # Row 3: A10 in range [5-6]
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 5 & as.numeric(var_col) <= 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10_dist_bins$data[[cut_name]][["A10_row_3"]] <- list(
      label = "5-6 people",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10_dist_bins$data[[cut_name]][["A10_row_3"]] <- list(
      label = "5-6 people",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10 not found"
    )
  }

  # Row 4: A10 in range [7-10]
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 7 & as.numeric(var_col) <= 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10_dist_bins$data[[cut_name]][["A10_row_4"]] <- list(
      label = "7-10 people",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10_dist_bins$data[[cut_name]][["A10_row_4"]] <- list(
      label = "7-10 people",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10 not found"
    )
  }

  # Row 5: A10 in range [11-30]
  var_col <- safe_get_var(cut_data, "A10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) >= 11 & as.numeric(var_col) <= 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a10_dist_bins$data[[cut_name]][["A10_row_5"]] <- list(
      label = "11 or more people",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a10_dist_bins$data[[cut_name]][["A10_row_5"]] <- list(
      label = "11 or more people",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A10 not found"
    )
  }

}

all_tables[["a10_dist_bins"]] <- table_a10_dist_bins
print(paste("Generated frequency table: a10_dist_bins"))

# -----------------------------------------------------------------------------
# Table: a11 (frequency) [LOOP: stacked_loop_1]
# Question: How satisfied were you with the drink you chose? (As a reminder, we’re asking about the drink at the specified location.)
# Rows: 7
# Source: a11
# -----------------------------------------------------------------------------

table_a11 <- list(
  tableId = "a11",
  questionId = "A11",
  questionText = "How satisfied were you with the drink you chose? (As a reminder, we’re asking about the drink at the specified location.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a11",
  surveySection = "OCCASION LOOP",
  baseText = "Asked about the specific drink at the respondent's Location 1 or Location 2 (looped question).",
  userNote = "(5-point satisfaction scale; Top 2 Box = 4–5, Middle = 3, Bottom 2 Box = 1–2)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a11$data[[cut_name]] <- list()
  table_a11$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A11 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_1"]] <- list(
      label = "Satisfied (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_1"]] <- list(
      label = "Satisfied (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 2: A11 == 5
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_2"]] <- list(
      label = "5 Extremely Satisfied",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_2"]] <- list(
      label = "5 Extremely Satisfied",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 3: A11 == 4
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_3"]] <- list(
      label = "4",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_3"]] <- list(
      label = "4",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 4: A11 == 3
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_4"]] <- list(
      label = "Neither satisfied nor dissatisfied",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_4"]] <- list(
      label = "Neither satisfied nor dissatisfied",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 5: A11 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_5"]] <- list(
      label = "Dissatisfied (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_5"]] <- list(
      label = "Dissatisfied (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 6: A11 == 2
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_6"]] <- list(
      label = "2",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_6"]] <- list(
      label = "2",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

  # Row 7: A11 == 1
  var_col <- safe_get_var(cut_data, "A11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a11$data[[cut_name]][["A11_row_7"]] <- list(
      label = "1 Not At All Satisfied",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a11$data[[cut_name]][["A11_row_7"]] <- list(
      label = "1 Not At All Satisfied",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A11 not found"
    )
  }

}

all_tables[["a11"]] <- table_a11
print(paste("Generated frequency table: a11"))

# -----------------------------------------------------------------------------
# Table: a13 (frequency) [LOOP: stacked_loop_1]
# Question: What brand of the drink did you have? As a reminder, we’re asking about the drink.
# Rows: 73
# -----------------------------------------------------------------------------

table_a13 <- list(
  tableId = "a13",
  questionId = "A13",
  questionText = "What brand of the drink did you have? As a reminder, we’re asking about the drink.",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "OCCASION LOOP",
  baseText = "Those whose A4 (type of drink) is one of: 4, 5, 7, 8, 9, 10, 11, 12, or 13",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A4 %in% c(4, 5, 7, 8, 9, 10, 11, 12, 13)")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a13$data[[cut_name]] <- list()
  table_a13$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A13 == 1
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_1"]] <- list(
      label = "Tito’s",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_1"]] <- list(
      label = "Tito’s",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 2: A13 == 2
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_2"]] <- list(
      label = "Smirnoff",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_2"]] <- list(
      label = "Smirnoff",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 3: A13 == 3
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_3"]] <- list(
      label = "New Amsterdam (code 3)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_3"]] <- list(
      label = "New Amsterdam (code 3)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 4: A13 == 4
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_4"]] <- list(
      label = "Svedka",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_4"]] <- list(
      label = "Svedka",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 5: A13 == 5
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_5"]] <- list(
      label = "Absolut",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_5"]] <- list(
      label = "Absolut",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 6: A13 == 6
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_6"]] <- list(
      label = "Grey Goose",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_6"]] <- list(
      label = "Grey Goose",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 7: A13 == 7
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_7"]] <- list(
      label = "Ketel One",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_7"]] <- list(
      label = "Ketel One",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 8: A13 == 8
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_8"]] <- list(
      label = "Platinum 7X",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_8"]] <- list(
      label = "Platinum 7X",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 9: A13 == 9
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_9"]] <- list(
      label = "Deep Eddy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_9"]] <- list(
      label = "Deep Eddy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 10: A13 == 10
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_10"]] <- list(
      label = "Skyy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_10"]] <- list(
      label = "Skyy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 11: A13 == 11
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_11"]] <- list(
      label = "Crown Royal",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_11"]] <- list(
      label = "Crown Royal",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 12: A13 == 12
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_12"]] <- list(
      label = "Jack Daniel’s",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_12"]] <- list(
      label = "Jack Daniel’s",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 13: A13 == 13
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_13"]] <- list(
      label = "Fireball (code 13)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_13"]] <- list(
      label = "Fireball (code 13)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 14: A13 == 14
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 14, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_14"]] <- list(
      label = "Jim Beam",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_14"]] <- list(
      label = "Jim Beam",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 15: A13 == 15
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 15, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_15"]] <- list(
      label = "Jameson",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_15"]] <- list(
      label = "Jameson",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 16: A13 == 16
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 16, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_16"]] <- list(
      label = "Evan Williams",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_16"]] <- list(
      label = "Evan Williams",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 17: A13 == 17
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 17, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_17"]] <- list(
      label = "Maker’s Mark",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_17"]] <- list(
      label = "Maker’s Mark",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 18: A13 == 18
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 18, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_18"]] <- list(
      label = "Bulleit",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_18"]] <- list(
      label = "Bulleit",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 19: A13 == 19
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 19, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_19"]] <- list(
      label = "Wild Turkey",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_19"]] <- list(
      label = "Wild Turkey",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 20: A13 == 20
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 20, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_20"]] <- list(
      label = "Knob Creek",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_20"]] <- list(
      label = "Knob Creek",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 21: A13 == 21
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 21, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_21"]] <- list(
      label = "Jose Cuervo",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_21"]] <- list(
      label = "Jose Cuervo",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 22: A13 == 22
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 22, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_22"]] <- list(
      label = "Casamigos",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_22"]] <- list(
      label = "Casamigos",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 23: A13 == 23
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 23, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_23"]] <- list(
      label = "Don Julio",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_23"]] <- list(
      label = "Don Julio",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 24: A13 == 24
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 24, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_24"]] <- list(
      label = "1800",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_24"]] <- list(
      label = "1800",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 25: A13 == 25
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 25, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_25"]] <- list(
      label = "Hornitos",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_25"]] <- list(
      label = "Hornitos",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 26: A13 == 26
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 26, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_26"]] <- list(
      label = "Espolòn",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_26"]] <- list(
      label = "Espolòn",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 27: A13 == 27
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 27, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_27"]] <- list(
      label = "Lunazul",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_27"]] <- list(
      label = "Lunazul",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 28: A13 == 28
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 28, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_28"]] <- list(
      label = "El Jimador",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_28"]] <- list(
      label = "El Jimador",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 29: A13 == 29
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 29, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_29"]] <- list(
      label = "Cazadores",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_29"]] <- list(
      label = "Cazadores",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 30: A13 == 30
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 30, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_30"]] <- list(
      label = "Milagro",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_30"]] <- list(
      label = "Milagro",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 31: A13 == 31
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 31, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_31"]] <- list(
      label = "Bacardi",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_31"]] <- list(
      label = "Bacardi",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 32: A13 == 32
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 32, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_32"]] <- list(
      label = "Captain Morgan",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_32"]] <- list(
      label = "Captain Morgan",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 33: A13 == 33
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 33, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_33"]] <- list(
      label = "Malibu",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_33"]] <- list(
      label = "Malibu",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 34: A13 == 34
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 34, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_34"]] <- list(
      label = "Admiral Nelson",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_34"]] <- list(
      label = "Admiral Nelson",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 35: A13 == 35
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 35, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_35"]] <- list(
      label = "Kraken",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_35"]] <- list(
      label = "Kraken",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 36: A13 == 36
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 36, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_36"]] <- list(
      label = "Sailor Jerry",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_36"]] <- list(
      label = "Sailor Jerry",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 37: A13 == 37
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 37, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_37"]] <- list(
      label = "Goslings",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_37"]] <- list(
      label = "Goslings",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 38: A13 == 38
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 38, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_38"]] <- list(
      label = "Flor de Caña",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_38"]] <- list(
      label = "Flor de Caña",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 39: A13 == 39
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 39, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_39"]] <- list(
      label = "Mt Gay",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_39"]] <- list(
      label = "Mt Gay",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 40: A13 == 40
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 40, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_40"]] <- list(
      label = "Appleton Estate",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_40"]] <- list(
      label = "Appleton Estate",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 41: A13 == 41
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 41, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_41"]] <- list(
      label = "Tanqueray",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_41"]] <- list(
      label = "Tanqueray",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 42: A13 == 42
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 42, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_42"]] <- list(
      label = "Bombay Sapphire",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_42"]] <- list(
      label = "Bombay Sapphire",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 43: A13 == 43
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 43, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_43"]] <- list(
      label = "Gordon’s",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_43"]] <- list(
      label = "Gordon’s",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 44: A13 == 44
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 44, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_44"]] <- list(
      label = "New Amsterdam (code 44)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_44"]] <- list(
      label = "New Amsterdam (code 44)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 45: A13 == 45
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 45, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_45"]] <- list(
      label = "Beefeater",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_45"]] <- list(
      label = "Beefeater",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 46: A13 == 46
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 46, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_46"]] <- list(
      label = "Seagram’s",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_46"]] <- list(
      label = "Seagram’s",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 47: A13 == 47
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 47, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_47"]] <- list(
      label = "Hendrick’s",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_47"]] <- list(
      label = "Hendrick’s",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 48: A13 == 48
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 48, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_48"]] <- list(
      label = "Aviation",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_48"]] <- list(
      label = "Aviation",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 49: A13 == 49
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 49, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_49"]] <- list(
      label = "Roku",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_49"]] <- list(
      label = "Roku",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 50: A13 == 50
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 50, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_50"]] <- list(
      label = "Monkey 47",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_50"]] <- list(
      label = "Monkey 47",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 51: A13 == 51
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 51, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_51"]] <- list(
      label = "Fireball (code 51)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_51"]] <- list(
      label = "Fireball (code 51)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 52: A13 == 52
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 52, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_52"]] <- list(
      label = "Baileys",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_52"]] <- list(
      label = "Baileys",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 53: A13 == 53
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 53, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_53"]] <- list(
      label = "Jägermeister",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_53"]] <- list(
      label = "Jägermeister",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 54: A13 == 54
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 54, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_54"]] <- list(
      label = "DeKuyper",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_54"]] <- list(
      label = "DeKuyper",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 55: A13 == 55
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 55, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_55"]] <- list(
      label = "RumChata",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_55"]] <- list(
      label = "RumChata",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 56: A13 == 56
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 56, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_56"]] <- list(
      label = "Kahlúa",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_56"]] <- list(
      label = "Kahlúa",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 57: A13 == 57
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 57, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_57"]] <- list(
      label = "Grand Marnier",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_57"]] <- list(
      label = "Grand Marnier",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 58: A13 == 58
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 58, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_58"]] <- list(
      label = "Southern Comfort",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_58"]] <- list(
      label = "Southern Comfort",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 59: A13 == 59
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 59, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_59"]] <- list(
      label = "Aperol",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_59"]] <- list(
      label = "Aperol",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 60: A13 == 60
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 60, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_60"]] <- list(
      label = "Goldschläger",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_60"]] <- list(
      label = "Goldschläger",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 61: A13 == 61
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 61, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_61"]] <- list(
      label = "Hennessy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_61"]] <- list(
      label = "Hennessy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 62: A13 == 62
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 62, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_62"]] <- list(
      label = "Rémy Martin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_62"]] <- list(
      label = "Rémy Martin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 63: A13 == 63
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 63, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_63"]] <- list(
      label = "Courvoisier",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_63"]] <- list(
      label = "Courvoisier",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 64: A13 == 64
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 64, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_64"]] <- list(
      label = "D’Ussé",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_64"]] <- list(
      label = "D’Ussé",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 65: A13 == 65
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 65, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_65"]] <- list(
      label = "Martell",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_65"]] <- list(
      label = "Martell",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 66: A13 == 66
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 66, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_66"]] <- list(
      label = "Camus",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_66"]] <- list(
      label = "Camus",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 67: A13 == 67
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 67, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_67"]] <- list(
      label = "Pierre Ferrand",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_67"]] <- list(
      label = "Pierre Ferrand",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 68: A13 == 68
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 68, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_68"]] <- list(
      label = "Hine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_68"]] <- list(
      label = "Hine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 69: A13 == 69
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 69, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_69"]] <- list(
      label = "Hardy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_69"]] <- list(
      label = "Hardy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 70: A13 == 70
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 70, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_70"]] <- list(
      label = "Frapin",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_70"]] <- list(
      label = "Frapin",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 71: A13 == 98
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 98, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_71"]] <- list(
      label = "Store brand",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_71"]] <- list(
      label = "Store brand",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 72: A13 == 99
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 99, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_72"]] <- list(
      label = "Other (specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_72"]] <- list(
      label = "Other (specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

  # Row 73: A13 == 100
  var_col <- safe_get_var(cut_data, "A13")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 100, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13$data[[cut_name]][["A13_row_73"]] <- list(
      label = "Don't know",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13$data[[cut_name]][["A13_row_73"]] <- list(
      label = "Don't know",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13 not found"
    )
  }

}

all_tables[["a13"]] <- table_a13
print(paste("Generated frequency table: a13"))

# -----------------------------------------------------------------------------
# Table: a15 (frequency) [LOOP: stacked_loop_1]
# Question: What size was the bottle of vodka you purchased at [pipe: hA14b_1]?
# Rows: 6
# Source: a15
# -----------------------------------------------------------------------------

table_a15 <- list(
  tableId = "a15",
  questionId = "A15",
  questionText = "What size was the bottle of vodka you purchased at [pipe: hA14b_1]?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a15",
  surveySection = "OCCASION LOOP",
  baseText = "Respondent is reporting about a location coded as OFF-PREMISE; Respondents who had Vodka (A4 = 7) at the relevant location and who purchased it themselves (A14a_1 = 1).",
  userNote = "(Asked only if respondent purchased the drink themselves; select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "hPREMISE1 == 2 | hPREMISE2 == 2 & A4 == 7 & A14a_1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a15$data[[cut_name]] <- list()
  table_a15$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A15 == 1
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_1"]] <- list(
      label = "Miniature (50 ml)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a15$data[[cut_name]][["A15_row_1"]] <- list(
      label = "Miniature (50 ml)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

  # Row 2: A15 == 2
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_2"]] <- list(
      label = "Small bottle (200 or 375 ml)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a15$data[[cut_name]][["A15_row_2"]] <- list(
      label = "Small bottle (200 or 375 ml)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

  # Row 3: A15 == 3
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_3"]] <- list(
      label = "Standard bottle (750 ml)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a15$data[[cut_name]][["A15_row_3"]] <- list(
      label = "Standard bottle (750 ml)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

  # Row 4: A15 == 4
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_4"]] <- list(
      label = "Liter bottle (1 L)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a15$data[[cut_name]][["A15_row_4"]] <- list(
      label = "Liter bottle (1 L)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

  # Row 5: A15 == 5
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_5"]] <- list(
      label = "Handle (1.75 L)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a15$data[[cut_name]][["A15_row_5"]] <- list(
      label = "Handle (1.75 L)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

  # Row 6: A15 == 6
  var_col <- safe_get_var(cut_data, "A15")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a15$data[[cut_name]][["A15_row_6"]] <- list(
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
    table_a15$data[[cut_name]][["A15_row_6"]] <- list(
      label = "Other",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A15 not found"
    )
  }

}

all_tables[["a15"]] <- table_a15
print(paste("Generated frequency table: a15"))

# -----------------------------------------------------------------------------
# Table: a18 (frequency) [LOOP: stacked_loop_1]
# Question: Which of the following best describes why you chose to buy the drink you had instead of another type of alcohol?
# Rows: 8
# -----------------------------------------------------------------------------

table_a18 <- list(
  tableId = "a18",
  questionId = "A18",
  questionText = "Which of the following best describes why you chose to buy the drink you had instead of another type of alcohol?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "OCCASION LOOP",
  baseText = "Respondent is reporting about a location coded as OFF-PREMISE; Respondents who said they purchased the drink themselves (A14a = 1)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "hPREMISE1 == 2 | hPREMISE2 == 2 & A14a_1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a18$data[[cut_name]] <- list()
  table_a18$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A18 == 1
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_1"]] <- list(
      label = "I needed it for a specific cocktail or recipe",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_1"]] <- list(
      label = "I needed it for a specific cocktail or recipe",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 2: A18 == 2
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_2"]] <- list(
      label = "It’s my usual go-to type of alcohol",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_2"]] <- list(
      label = "It’s my usual go-to type of alcohol",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 3: A18 == 3
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_3"]] <- list(
      label = "It was the best fit for the occasion or event",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_3"]] <- list(
      label = "It was the best fit for the occasion or event",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 4: A18 == 4
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_4"]] <- list(
      label = "I prefer the taste of the drink",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_4"]] <- list(
      label = "I prefer the taste of the drink",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 5: A18 == 5
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_5"]] <- list(
      label = "It was on sale or had a special promotion",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_5"]] <- list(
      label = "It was on sale or had a special promotion",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 6: A18 == 6
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_6"]] <- list(
      label = "It was recommended to me",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_6"]] <- list(
      label = "It was recommended to me",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 7: A18 == 7
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_7"]] <- list(
      label = "I needed to refill my current supply/stock",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_7"]] <- list(
      label = "I needed to refill my current supply/stock",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

  # Row 8: A18 == 8
  var_col <- safe_get_var(cut_data, "A18")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a18$data[[cut_name]][["A18_row_8"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a18$data[[cut_name]][["A18_row_8"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A18 not found"
    )
  }

}

all_tables[["a18"]] <- table_a18
print(paste("Generated frequency table: a18"))

# -----------------------------------------------------------------------------
# Table: a20 (frequency)
# Question: Much earlier, you mentioned having alcoholic drinks in the past week. How does this compare to a typical week for you?
# Rows: 7
# Source: a20
# -----------------------------------------------------------------------------

table_a20 <- list(
  tableId = "a20",
  questionId = "A20",
  questionText = "Much earlier, you mentioned having alcoholic drinks in the past week. How does this compare to a typical week for you?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a20",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Asked once; outside the loops)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a20$data[[cut_name]] <- list()
  table_a20$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A20 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_1"]] <- list(
      label = "Top 2 Box (T2B): I usually have somewhat more or much more than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_1"]] <- list(
      label = "Top 2 Box (T2B): I usually have somewhat more or much more than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 2: A20 == 5
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_2"]] <- list(
      label = "I usually have much more than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_2"]] <- list(
      label = "I usually have much more than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 3: A20 == 4
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_3"]] <- list(
      label = "I usually have somewhat more than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_3"]] <- list(
      label = "I usually have somewhat more than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 4: A20 == 3
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_4"]] <- list(
      label = "Neither more nor less (This was a very typical week for me)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_4"]] <- list(
      label = "Neither more nor less (This was a very typical week for me)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 5: A20 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_5"]] <- list(
      label = "Bottom 2 Box (B2B): I usually have somewhat less or much less than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_5"]] <- list(
      label = "Bottom 2 Box (B2B): I usually have somewhat less or much less than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 6: A20 == 2
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_6"]] <- list(
      label = "I usually have somewhat less than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_6"]] <- list(
      label = "I usually have somewhat less than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

  # Row 7: A20 == 1
  var_col <- safe_get_var(cut_data, "A20")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a20$data[[cut_name]][["A20_row_7"]] <- list(
      label = "I usually have much less than this",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a20$data[[cut_name]][["A20_row_7"]] <- list(
      label = "I usually have much less than this",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A20 not found"
    )
  }

}

all_tables[["a20"]] <- table_a20
print(paste("Generated frequency table: a20"))

# -----------------------------------------------------------------------------
# Table: a21 (frequency) [DERIVED]
# Question: Which of the following liquor/spirits brands are you aware of?
# Rows: 8
# Source: a21
# -----------------------------------------------------------------------------

table_a21 <- list(
  tableId = "a21",
  questionId = "A21",
  questionText = "Which of the following liquor/spirits brands are you aware of?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a21",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a21$data[[cut_name]] <- list()
  table_a21$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any brand (NET) (components: A21r1, A21r2, A21r3, A21r4, A21r5, A21r6)
  net_vars <- c("A21r1", "A21r2", "A21r3", "A21r4", "A21r5", "A21r6")
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

    table_a21$data[[cut_name]][["_NET_AnyBrand_row_1"]] <- list(
      label = "Any brand (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A21r1 == 1
  var_col <- safe_get_var(cut_data, "A21r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r1_row_2"]] <- list(
      label = "Tito's Handmade Vodka",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r1_row_2"]] <- list(
      label = "Tito's Handmade Vodka",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r1 not found"
    )
  }

  # Row 3: A21r2 == 1
  var_col <- safe_get_var(cut_data, "A21r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r2_row_3"]] <- list(
      label = "Grey Goose",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r2_row_3"]] <- list(
      label = "Grey Goose",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r2 not found"
    )
  }

  # Row 4: A21r3 == 1
  var_col <- safe_get_var(cut_data, "A21r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r3_row_4"]] <- list(
      label = "Ketel One",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r3_row_4"]] <- list(
      label = "Ketel One",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r3 not found"
    )
  }

  # Row 5: A21r4 == 1
  var_col <- safe_get_var(cut_data, "A21r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r4_row_5"]] <- list(
      label = "Maker's Mark",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r4_row_5"]] <- list(
      label = "Maker's Mark",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r4 not found"
    )
  }

  # Row 6: A21r5 == 1
  var_col <- safe_get_var(cut_data, "A21r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r5_row_6"]] <- list(
      label = "Casamigos",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r5_row_6"]] <- list(
      label = "Casamigos",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r5 not found"
    )
  }

  # Row 7: A21r6 == 1
  var_col <- safe_get_var(cut_data, "A21r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r6_row_7"]] <- list(
      label = "Don Julio",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a21$data[[cut_name]][["A21r6_row_7"]] <- list(
      label = "Don Julio",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r6 not found"
    )
  }

  # Row 8: A21r7 == 1
  var_col <- safe_get_var(cut_data, "A21r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a21$data[[cut_name]][["A21r7_row_8"]] <- list(
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
    table_a21$data[[cut_name]][["A21r7_row_8"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A21r7 not found"
    )
  }

}

all_tables[["a21"]] <- table_a21
print(paste("Generated frequency table: a21"))

# -----------------------------------------------------------------------------
# Table: a22_casamigos_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22_casamigos_column_
# -----------------------------------------------------------------------------

table_a22_casamigos_column_ <- list(
  tableId = "a22_casamigos_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22_casamigos_column_",
  surveySection = "OCCASION LOOP",
  baseText = "Show Casamigos (brand column) only for respondents who selected Casamigos in A21",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r5 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_casamigos_column_$data[[cut_name]] <- list()
  table_a22_casamigos_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c5 == 1
  var_col <- safe_get_var(cut_data, "A22r1c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r1c5_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r1c5_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c5 not found"
    )
  }

  # Row 2: A22r2c5 == 1
  var_col <- safe_get_var(cut_data, "A22r2c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r2c5_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r2c5_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c5 not found"
    )
  }

  # Row 3: A22r3c5 == 1
  var_col <- safe_get_var(cut_data, "A22r3c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r3c5_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r3c5_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c5 not found"
    )
  }

  # Row 4: A22r4c5 == 1
  var_col <- safe_get_var(cut_data, "A22r4c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r4c5_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r4c5_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c5 not found"
    )
  }

  # Row 5: A22r5c5 == 1
  var_col <- safe_get_var(cut_data, "A22r5c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r5c5_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r5c5_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c5 not found"
    )
  }

  # Row 6: A22r6c5 == 1
  var_col <- safe_get_var(cut_data, "A22r6c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r6c5_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r6c5_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c5 not found"
    )
  }

  # Row 7: A22r7c5 == 1
  var_col <- safe_get_var(cut_data, "A22r7c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r7c5_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r7c5_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c5 not found"
    )
  }

  # Row 8: A22r8c5 == 1
  var_col <- safe_get_var(cut_data, "A22r8c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r8c5_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r8c5_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c5 not found"
    )
  }

  # Row 9: A22r9c5 == 1
  var_col <- safe_get_var(cut_data, "A22r9c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r9c5_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r9c5_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c5 not found"
    )
  }

  # Row 10: A22r10c5 == 1
  var_col <- safe_get_var(cut_data, "A22r10c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_$data[[cut_name]][["A22r10c5_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_$data[[cut_name]][["A22r10c5_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c5 not found"
    )
  }

}

all_tables[["a22_casamigos_column_"]] <- table_a22_casamigos_column_
print(paste("Generated frequency table: a22_casamigos_column_"))

# -----------------------------------------------------------------------------
# Table: a22_casamigos_column_c5_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22_casamigos_column_c5_
# -----------------------------------------------------------------------------

table_a22_casamigos_column_c5_ <- list(
  tableId = "a22_casamigos_column_c5_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22_casamigos_column_c5_",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Casamigos (A21r5 == 1)",
  userNote = "(Select all that apply)",
  tableSubtitle = "Casamigos (brand column)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r5 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_casamigos_column_c5_$data[[cut_name]] <- list()
  table_a22_casamigos_column_c5_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c5 == 1
  var_col <- safe_get_var(cut_data, "A22r1c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r1c5_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r1c5_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c5 not found"
    )
  }

  # Row 2: A22r2c5 == 1
  var_col <- safe_get_var(cut_data, "A22r2c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r2c5_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r2c5_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c5 not found"
    )
  }

  # Row 3: A22r3c5 == 1
  var_col <- safe_get_var(cut_data, "A22r3c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r3c5_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r3c5_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c5 not found"
    )
  }

  # Row 4: A22r4c5 == 1
  var_col <- safe_get_var(cut_data, "A22r4c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r4c5_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r4c5_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c5 not found"
    )
  }

  # Row 5: A22r5c5 == 1
  var_col <- safe_get_var(cut_data, "A22r5c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r5c5_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r5c5_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c5 not found"
    )
  }

  # Row 6: A22r6c5 == 1
  var_col <- safe_get_var(cut_data, "A22r6c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r6c5_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r6c5_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c5 not found"
    )
  }

  # Row 7: A22r7c5 == 1
  var_col <- safe_get_var(cut_data, "A22r7c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r7c5_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r7c5_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c5 not found"
    )
  }

  # Row 8: A22r8c5 == 1
  var_col <- safe_get_var(cut_data, "A22r8c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r8c5_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r8c5_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c5 not found"
    )
  }

  # Row 9: A22r9c5 == 1
  var_col <- safe_get_var(cut_data, "A22r9c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r9c5_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r9c5_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c5 not found"
    )
  }

  # Row 10: A22r10c5 == 1
  var_col <- safe_get_var(cut_data, "A22r10c5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r10c5_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_casamigos_column_c5_$data[[cut_name]][["A22r10c5_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c5 not found"
    )
  }

}

all_tables[["a22_casamigos_column_c5_"]] <- table_a22_casamigos_column_c5_
print(paste("Generated frequency table: a22_casamigos_column_c5_"))

# -----------------------------------------------------------------------------
# Table: a22_don_julio_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 11
# Source: a22_don_julio_column_
# -----------------------------------------------------------------------------

table_a22_don_julio_column_ <- list(
  tableId = "a22_don_julio_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22_don_julio_column_",
  surveySection = "OCCASION LOOP",
  baseText = "Show Don Julio (brand column) only for respondents who selected Don Julio in A21",
  userNote = "(Select all that apply)",
  tableSubtitle = "Don Julio",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r6 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_don_julio_column_$data[[cut_name]] <- list()
  table_a22_don_julio_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Attributes (asked for each brand)
  table_a22_don_julio_column_$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Attributes (asked for each brand)",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A22r1c6 == 1
  var_col <- safe_get_var(cut_data, "A22r1c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r1c6_row_2"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r1c6_row_2"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c6 not found"
    )
  }

  # Row 3: A22r2c6 == 1
  var_col <- safe_get_var(cut_data, "A22r2c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r2c6_row_3"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r2c6_row_3"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c6 not found"
    )
  }

  # Row 4: A22r3c6 == 1
  var_col <- safe_get_var(cut_data, "A22r3c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r3c6_row_4"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r3c6_row_4"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c6 not found"
    )
  }

  # Row 5: A22r4c6 == 1
  var_col <- safe_get_var(cut_data, "A22r4c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r4c6_row_5"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r4c6_row_5"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c6 not found"
    )
  }

  # Row 6: A22r5c6 == 1
  var_col <- safe_get_var(cut_data, "A22r5c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r5c6_row_6"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r5c6_row_6"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c6 not found"
    )
  }

  # Row 7: A22r6c6 == 1
  var_col <- safe_get_var(cut_data, "A22r6c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r6c6_row_7"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r6c6_row_7"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c6 not found"
    )
  }

  # Row 8: A22r7c6 == 1
  var_col <- safe_get_var(cut_data, "A22r7c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r7c6_row_8"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r7c6_row_8"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c6 not found"
    )
  }

  # Row 9: A22r8c6 == 1
  var_col <- safe_get_var(cut_data, "A22r8c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r8c6_row_9"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r8c6_row_9"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c6 not found"
    )
  }

  # Row 10: A22r9c6 == 1
  var_col <- safe_get_var(cut_data, "A22r9c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r9c6_row_10"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r9c6_row_10"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c6 not found"
    )
  }

  # Row 11: A22r10c6 == 1
  var_col <- safe_get_var(cut_data, "A22r10c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_$data[[cut_name]][["A22r10c6_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_$data[[cut_name]][["A22r10c6_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c6 not found"
    )
  }

}

all_tables[["a22_don_julio_column_"]] <- table_a22_don_julio_column_
print(paste("Generated frequency table: a22_don_julio_column_"))

# -----------------------------------------------------------------------------
# Table: a22_don_julio_column_c6_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 11
# Source: a22
# -----------------------------------------------------------------------------

table_a22_don_julio_column_c6_ <- list(
  tableId = "a22_don_julio_column_c6_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Don Julio (A21r6 == 1)",
  userNote = "(Select all that apply)",
  tableSubtitle = "Don Julio",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r6 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_don_julio_column_c6_$data[[cut_name]] <- list()
  table_a22_don_julio_column_c6_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any attribute associated with Don Julio (NET) (components: A22r1c6, A22r2c6, A22r3c6, A22r4c6, A22r5c6, A22r6c6, A22r7c6, A22r8c6, A22r9c6, A22r10c6)
  net_vars <- c("A22r1c6", "A22r2c6", "A22r3c6", "A22r4c6", "A22r5c6", "A22r6c6", "A22r7c6", "A22r8c6", "A22r9c6", "A22r10c6")
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

    table_a22_don_julio_column_c6_$data[[cut_name]][["_NET_DonJulio_AnyAttribute_row_1"]] <- list(
      label = "Any attribute associated with Don Julio (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A22r1c6 == 1
  var_col <- safe_get_var(cut_data, "A22r1c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r1c6_row_2"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r1c6_row_2"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c6 not found"
    )
  }

  # Row 3: A22r2c6 == 1
  var_col <- safe_get_var(cut_data, "A22r2c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r2c6_row_3"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r2c6_row_3"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c6 not found"
    )
  }

  # Row 4: A22r3c6 == 1
  var_col <- safe_get_var(cut_data, "A22r3c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r3c6_row_4"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r3c6_row_4"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c6 not found"
    )
  }

  # Row 5: A22r4c6 == 1
  var_col <- safe_get_var(cut_data, "A22r4c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r4c6_row_5"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r4c6_row_5"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c6 not found"
    )
  }

  # Row 6: A22r5c6 == 1
  var_col <- safe_get_var(cut_data, "A22r5c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r5c6_row_6"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r5c6_row_6"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c6 not found"
    )
  }

  # Row 7: A22r6c6 == 1
  var_col <- safe_get_var(cut_data, "A22r6c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r6c6_row_7"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r6c6_row_7"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c6 not found"
    )
  }

  # Row 8: A22r7c6 == 1
  var_col <- safe_get_var(cut_data, "A22r7c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r7c6_row_8"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r7c6_row_8"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c6 not found"
    )
  }

  # Row 9: A22r8c6 == 1
  var_col <- safe_get_var(cut_data, "A22r8c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r8c6_row_9"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r8c6_row_9"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c6 not found"
    )
  }

  # Row 10: A22r9c6 == 1
  var_col <- safe_get_var(cut_data, "A22r9c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r9c6_row_10"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r9c6_row_10"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c6 not found"
    )
  }

  # Row 11: A22r10c6 == 1
  var_col <- safe_get_var(cut_data, "A22r10c6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r10c6_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_don_julio_column_c6_$data[[cut_name]][["A22r10c6_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c6 not found"
    )
  }

}

all_tables[["a22_don_julio_column_c6_"]] <- table_a22_don_julio_column_c6_
print(paste("Generated frequency table: a22_don_julio_column_c6_"))

# -----------------------------------------------------------------------------
# Table: a22_grey_goose_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22
# -----------------------------------------------------------------------------

table_a22_grey_goose_column_ <- list(
  tableId = "a22_grey_goose_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Show Grey Goose (brand column) only for respondents who selected Grey Goose in A21",
  userNote = "(Select all that apply)",
  tableSubtitle = "Grey Goose",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r2 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_grey_goose_column_$data[[cut_name]] <- list()
  table_a22_grey_goose_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c2 == 1
  var_col <- safe_get_var(cut_data, "A22r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r1c2_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r1c2_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c2 not found"
    )
  }

  # Row 2: A22r2c2 == 1
  var_col <- safe_get_var(cut_data, "A22r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r2c2_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r2c2_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c2 not found"
    )
  }

  # Row 3: A22r3c2 == 1
  var_col <- safe_get_var(cut_data, "A22r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r3c2_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r3c2_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c2 not found"
    )
  }

  # Row 4: A22r4c2 == 1
  var_col <- safe_get_var(cut_data, "A22r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r4c2_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r4c2_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c2 not found"
    )
  }

  # Row 5: A22r5c2 == 1
  var_col <- safe_get_var(cut_data, "A22r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r5c2_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r5c2_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c2 not found"
    )
  }

  # Row 6: A22r6c2 == 1
  var_col <- safe_get_var(cut_data, "A22r6c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r6c2_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r6c2_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c2 not found"
    )
  }

  # Row 7: A22r7c2 == 1
  var_col <- safe_get_var(cut_data, "A22r7c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r7c2_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r7c2_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c2 not found"
    )
  }

  # Row 8: A22r8c2 == 1
  var_col <- safe_get_var(cut_data, "A22r8c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r8c2_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r8c2_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c2 not found"
    )
  }

  # Row 9: A22r9c2 == 1
  var_col <- safe_get_var(cut_data, "A22r9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r9c2_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r9c2_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c2 not found"
    )
  }

  # Row 10: A22r10c2 == 1
  var_col <- safe_get_var(cut_data, "A22r10c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_$data[[cut_name]][["A22r10c2_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_$data[[cut_name]][["A22r10c2_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c2 not found"
    )
  }

}

all_tables[["a22_grey_goose_column_"]] <- table_a22_grey_goose_column_
print(paste("Generated frequency table: a22_grey_goose_column_"))

# -----------------------------------------------------------------------------
# Table: a22_grey_goose_column_c2_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 11
# Source: a22
# -----------------------------------------------------------------------------

table_a22_grey_goose_column_c2_ <- list(
  tableId = "a22_grey_goose_column_c2_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Grey Goose (A21r2 == 1)",
  userNote = "(Select all that apply; this view is the Grey Goose column — one row per attribute)",
  tableSubtitle = "Grey Goose",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r2 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_grey_goose_column_c2_$data[[cut_name]] <- list()
  table_a22_grey_goose_column_c2_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Grey Goose
  table_a22_grey_goose_column_c2_$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Grey Goose",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A22r1c2 == 1
  var_col <- safe_get_var(cut_data, "A22r1c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r1c2_row_2"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r1c2_row_2"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c2 not found"
    )
  }

  # Row 3: A22r2c2 == 1
  var_col <- safe_get_var(cut_data, "A22r2c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r2c2_row_3"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r2c2_row_3"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c2 not found"
    )
  }

  # Row 4: A22r3c2 == 1
  var_col <- safe_get_var(cut_data, "A22r3c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r3c2_row_4"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r3c2_row_4"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c2 not found"
    )
  }

  # Row 5: A22r4c2 == 1
  var_col <- safe_get_var(cut_data, "A22r4c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r4c2_row_5"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r4c2_row_5"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c2 not found"
    )
  }

  # Row 6: A22r5c2 == 1
  var_col <- safe_get_var(cut_data, "A22r5c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r5c2_row_6"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r5c2_row_6"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c2 not found"
    )
  }

  # Row 7: A22r6c2 == 1
  var_col <- safe_get_var(cut_data, "A22r6c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r6c2_row_7"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r6c2_row_7"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c2 not found"
    )
  }

  # Row 8: A22r7c2 == 1
  var_col <- safe_get_var(cut_data, "A22r7c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r7c2_row_8"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r7c2_row_8"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c2 not found"
    )
  }

  # Row 9: A22r8c2 == 1
  var_col <- safe_get_var(cut_data, "A22r8c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r8c2_row_9"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r8c2_row_9"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c2 not found"
    )
  }

  # Row 10: A22r9c2 == 1
  var_col <- safe_get_var(cut_data, "A22r9c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r9c2_row_10"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r9c2_row_10"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c2 not found"
    )
  }

  # Row 11: A22r10c2 == 1
  var_col <- safe_get_var(cut_data, "A22r10c2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r10c2_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_grey_goose_column_c2_$data[[cut_name]][["A22r10c2_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c2 not found"
    )
  }

}

all_tables[["a22_grey_goose_column_c2_"]] <- table_a22_grey_goose_column_c2_
print(paste("Generated frequency table: a22_grey_goose_column_c2_"))

# -----------------------------------------------------------------------------
# Table: a22_ketel_one_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute? (asked for brands selected in A21)
# Rows: 10
# Source: a22
# -----------------------------------------------------------------------------

table_a22_ketel_one_column_ <- list(
  tableId = "a22_ketel_one_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute? (asked for brands selected in A21)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Show Ketel One (brand column) only for respondents who selected Ketel One in A21",
  userNote = "(Select all that apply; only brands the respondent selected in A21 were shown)",
  tableSubtitle = "Ketel One (brand)",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r3 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_ketel_one_column_$data[[cut_name]] <- list()
  table_a22_ketel_one_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c3 == 1
  var_col <- safe_get_var(cut_data, "A22r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r1c3_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r1c3_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c3 not found"
    )
  }

  # Row 2: A22r2c3 == 1
  var_col <- safe_get_var(cut_data, "A22r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r2c3_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r2c3_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c3 not found"
    )
  }

  # Row 3: A22r3c3 == 1
  var_col <- safe_get_var(cut_data, "A22r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r3c3_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r3c3_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c3 not found"
    )
  }

  # Row 4: A22r4c3 == 1
  var_col <- safe_get_var(cut_data, "A22r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r4c3_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r4c3_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c3 not found"
    )
  }

  # Row 5: A22r5c3 == 1
  var_col <- safe_get_var(cut_data, "A22r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r5c3_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r5c3_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c3 not found"
    )
  }

  # Row 6: A22r6c3 == 1
  var_col <- safe_get_var(cut_data, "A22r6c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r6c3_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r6c3_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c3 not found"
    )
  }

  # Row 7: A22r7c3 == 1
  var_col <- safe_get_var(cut_data, "A22r7c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r7c3_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r7c3_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c3 not found"
    )
  }

  # Row 8: A22r8c3 == 1
  var_col <- safe_get_var(cut_data, "A22r8c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r8c3_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r8c3_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c3 not found"
    )
  }

  # Row 9: A22r9c3 == 1
  var_col <- safe_get_var(cut_data, "A22r9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r9c3_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r9c3_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c3 not found"
    )
  }

  # Row 10: A22r10c3 == 1
  var_col <- safe_get_var(cut_data, "A22r10c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_$data[[cut_name]][["A22r10c3_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_$data[[cut_name]][["A22r10c3_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c3 not found"
    )
  }

}

all_tables[["a22_ketel_one_column_"]] <- table_a22_ketel_one_column_
print(paste("Generated frequency table: a22_ketel_one_column_"))

# -----------------------------------------------------------------------------
# Table: a22_ketel_one_column_c3_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 11
# Source: a22
# -----------------------------------------------------------------------------

table_a22_ketel_one_column_c3_ <- list(
  tableId = "a22_ketel_one_column_c3_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Ketel One (A21r3 == 1)",
  userNote = "(Select all that apply)",
  tableSubtitle = "Ketel One",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r3 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_ketel_one_column_c3_$data[[cut_name]] <- list()
  table_a22_ketel_one_column_c3_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any attribute (NET) (components: A22r1c3, A22r2c3, A22r3c3, A22r4c3, A22r5c3, A22r6c3, A22r7c3, A22r8c3, A22r9c3, A22r10c3)
  net_vars <- c("A22r1c3", "A22r2c3", "A22r3c3", "A22r4c3", "A22r5c3", "A22r6c3", "A22r7c3", "A22r8c3", "A22r9c3", "A22r10c3")
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

    table_a22_ketel_one_column_c3_$data[[cut_name]][["_NET_A22_KetelOne_row_1"]] <- list(
      label = "Any attribute (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A22r1c3 == 1
  var_col <- safe_get_var(cut_data, "A22r1c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r1c3_row_2"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r1c3_row_2"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c3 not found"
    )
  }

  # Row 3: A22r2c3 == 1
  var_col <- safe_get_var(cut_data, "A22r2c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r2c3_row_3"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r2c3_row_3"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c3 not found"
    )
  }

  # Row 4: A22r3c3 == 1
  var_col <- safe_get_var(cut_data, "A22r3c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r3c3_row_4"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r3c3_row_4"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c3 not found"
    )
  }

  # Row 5: A22r4c3 == 1
  var_col <- safe_get_var(cut_data, "A22r4c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r4c3_row_5"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r4c3_row_5"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c3 not found"
    )
  }

  # Row 6: A22r5c3 == 1
  var_col <- safe_get_var(cut_data, "A22r5c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r5c3_row_6"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r5c3_row_6"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c3 not found"
    )
  }

  # Row 7: A22r6c3 == 1
  var_col <- safe_get_var(cut_data, "A22r6c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r6c3_row_7"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r6c3_row_7"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c3 not found"
    )
  }

  # Row 8: A22r7c3 == 1
  var_col <- safe_get_var(cut_data, "A22r7c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r7c3_row_8"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r7c3_row_8"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c3 not found"
    )
  }

  # Row 9: A22r8c3 == 1
  var_col <- safe_get_var(cut_data, "A22r8c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r8c3_row_9"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r8c3_row_9"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c3 not found"
    )
  }

  # Row 10: A22r9c3 == 1
  var_col <- safe_get_var(cut_data, "A22r9c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r9c3_row_10"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r9c3_row_10"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c3 not found"
    )
  }

  # Row 11: A22r10c3 == 1
  var_col <- safe_get_var(cut_data, "A22r10c3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r10c3_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_ketel_one_column_c3_$data[[cut_name]][["A22r10c3_row_11"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c3 not found"
    )
  }

}

all_tables[["a22_ketel_one_column_c3_"]] <- table_a22_ketel_one_column_c3_
print(paste("Generated frequency table: a22_ketel_one_column_c3_"))

# -----------------------------------------------------------------------------
# Table: a22_maker_s_mark_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22_maker_s_mark_column_
# -----------------------------------------------------------------------------

table_a22_maker_s_mark_column_ <- list(
  tableId = "a22_maker_s_mark_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22_maker_s_mark_column_",
  surveySection = "OCCASION LOOP",
  baseText = "Show Maker's Mark (brand column) only for respondents who selected Maker's Mark in A21",
  userNote = "(Select all that apply; brands shown are those selected in A21)",
  tableSubtitle = "Maker's Mark",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r4 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_maker_s_mark_column_$data[[cut_name]] <- list()
  table_a22_maker_s_mark_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c4 == 1
  var_col <- safe_get_var(cut_data, "A22r1c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r1c4_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r1c4_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c4 not found"
    )
  }

  # Row 2: A22r2c4 == 1
  var_col <- safe_get_var(cut_data, "A22r2c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r2c4_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r2c4_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c4 not found"
    )
  }

  # Row 3: A22r3c4 == 1
  var_col <- safe_get_var(cut_data, "A22r3c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r3c4_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r3c4_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c4 not found"
    )
  }

  # Row 4: A22r4c4 == 1
  var_col <- safe_get_var(cut_data, "A22r4c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r4c4_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r4c4_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c4 not found"
    )
  }

  # Row 5: A22r5c4 == 1
  var_col <- safe_get_var(cut_data, "A22r5c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r5c4_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r5c4_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c4 not found"
    )
  }

  # Row 6: A22r6c4 == 1
  var_col <- safe_get_var(cut_data, "A22r6c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r6c4_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r6c4_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c4 not found"
    )
  }

  # Row 7: A22r7c4 == 1
  var_col <- safe_get_var(cut_data, "A22r7c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r7c4_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r7c4_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c4 not found"
    )
  }

  # Row 8: A22r8c4 == 1
  var_col <- safe_get_var(cut_data, "A22r8c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r8c4_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r8c4_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c4 not found"
    )
  }

  # Row 9: A22r9c4 == 1
  var_col <- safe_get_var(cut_data, "A22r9c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r9c4_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r9c4_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c4 not found"
    )
  }

  # Row 10: A22r10c4 == 1
  var_col <- safe_get_var(cut_data, "A22r10c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r10c4_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_$data[[cut_name]][["A22r10c4_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c4 not found"
    )
  }

}

all_tables[["a22_maker_s_mark_column_"]] <- table_a22_maker_s_mark_column_
print(paste("Generated frequency table: a22_maker_s_mark_column_"))

# -----------------------------------------------------------------------------
# Table: a22_maker_s_mark_column_c4_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22
# -----------------------------------------------------------------------------

table_a22_maker_s_mark_column_c4_ <- list(
  tableId = "a22_maker_s_mark_column_c4_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Maker's Mark (A21r4 == 1)",
  userNote = "(Select all that apply)",
  tableSubtitle = "Maker's Mark",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r4 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_maker_s_mark_column_c4_$data[[cut_name]] <- list()
  table_a22_maker_s_mark_column_c4_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c4 == 1
  var_col <- safe_get_var(cut_data, "A22r1c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r1c4_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r1c4_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c4 not found"
    )
  }

  # Row 2: A22r2c4 == 1
  var_col <- safe_get_var(cut_data, "A22r2c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r2c4_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r2c4_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c4 not found"
    )
  }

  # Row 3: A22r3c4 == 1
  var_col <- safe_get_var(cut_data, "A22r3c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r3c4_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r3c4_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c4 not found"
    )
  }

  # Row 4: A22r4c4 == 1
  var_col <- safe_get_var(cut_data, "A22r4c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r4c4_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r4c4_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c4 not found"
    )
  }

  # Row 5: A22r5c4 == 1
  var_col <- safe_get_var(cut_data, "A22r5c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r5c4_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r5c4_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c4 not found"
    )
  }

  # Row 6: A22r6c4 == 1
  var_col <- safe_get_var(cut_data, "A22r6c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r6c4_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r6c4_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c4 not found"
    )
  }

  # Row 7: A22r7c4 == 1
  var_col <- safe_get_var(cut_data, "A22r7c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r7c4_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r7c4_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c4 not found"
    )
  }

  # Row 8: A22r8c4 == 1
  var_col <- safe_get_var(cut_data, "A22r8c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r8c4_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r8c4_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c4 not found"
    )
  }

  # Row 9: A22r9c4 == 1
  var_col <- safe_get_var(cut_data, "A22r9c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r9c4_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r9c4_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c4 not found"
    )
  }

  # Row 10: A22r10c4 == 1
  var_col <- safe_get_var(cut_data, "A22r10c4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r10c4_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_maker_s_mark_column_c4_$data[[cut_name]][["A22r10c4_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c4 not found"
    )
  }

}

all_tables[["a22_maker_s_mark_column_c4_"]] <- table_a22_maker_s_mark_column_c4_
print(paste("Generated frequency table: a22_maker_s_mark_column_c4_"))

# -----------------------------------------------------------------------------
# Table: a22_none_of_the_above_column_c7_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22_none_of_the_above_column_c7_
# -----------------------------------------------------------------------------

table_a22_none_of_the_above_column_c7_ <- list(
  tableId = "a22_none_of_the_above_column_c7_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22_none_of_the_above_column_c7_",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents who selected 'None of the above' at A21 (A21r7 == 1)",
  userNote = "(Select all that apply; asked once per attribute — \"None of the above\" flag shown here)",
  tableSubtitle = "None-of-the-above responses by attribute",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r7 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_none_of_the_above_column_c7_$data[[cut_name]] <- list()
  table_a22_none_of_the_above_column_c7_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c7 == 1
  var_col <- safe_get_var(cut_data, "A22r1c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r1c7_row_1"]] <- list(
      label = "None of the above (Premium)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r1c7_row_1"]] <- list(
      label = "None of the above (Premium)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c7 not found"
    )
  }

  # Row 2: A22r2c7 == 1
  var_col <- safe_get_var(cut_data, "A22r2c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r2c7_row_2"]] <- list(
      label = "None of the above (Approachable)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r2c7_row_2"]] <- list(
      label = "None of the above (Approachable)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c7 not found"
    )
  }

  # Row 3: A22r3c7 == 1
  var_col <- safe_get_var(cut_data, "A22r3c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r3c7_row_3"]] <- list(
      label = "None of the above (Authentic)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r3c7_row_3"]] <- list(
      label = "None of the above (Authentic)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c7 not found"
    )
  }

  # Row 4: A22r4c7 == 1
  var_col <- safe_get_var(cut_data, "A22r4c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r4c7_row_4"]] <- list(
      label = "None of the above (Generous)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r4c7_row_4"]] <- list(
      label = "None of the above (Generous)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c7 not found"
    )
  }

  # Row 5: A22r5c7 == 1
  var_col <- safe_get_var(cut_data, "A22r5c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r5c7_row_5"]] <- list(
      label = "None of the above (Edgy)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r5c7_row_5"]] <- list(
      label = "None of the above (Edgy)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c7 not found"
    )
  }

  # Row 6: A22r6c7 == 1
  var_col <- safe_get_var(cut_data, "A22r6c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r6c7_row_6"]] <- list(
      label = "None of the above (Independent)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r6c7_row_6"]] <- list(
      label = "None of the above (Independent)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c7 not found"
    )
  }

  # Row 7: A22r7c7 == 1
  var_col <- safe_get_var(cut_data, "A22r7c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r7c7_row_7"]] <- list(
      label = "None of the above (Bold)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r7c7_row_7"]] <- list(
      label = "None of the above (Bold)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c7 not found"
    )
  }

  # Row 8: A22r8c7 == 1
  var_col <- safe_get_var(cut_data, "A22r8c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r8c7_row_8"]] <- list(
      label = "None of the above (Reliable)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r8c7_row_8"]] <- list(
      label = "None of the above (Reliable)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c7 not found"
    )
  }

  # Row 9: A22r9c7 == 1
  var_col <- safe_get_var(cut_data, "A22r9c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r9c7_row_9"]] <- list(
      label = "None of the above (Down-to-Earth)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r9c7_row_9"]] <- list(
      label = "None of the above (Down-to-Earth)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c7 not found"
    )
  }

  # Row 10: A22r10c7 == 1
  var_col <- safe_get_var(cut_data, "A22r10c7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r10c7_row_10"]] <- list(
      label = "None of the above (Sophisticated / Refined)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_none_of_the_above_column_c7_$data[[cut_name]][["A22r10c7_row_10"]] <- list(
      label = "None of the above (Sophisticated / Refined)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c7 not found"
    )
  }

}

all_tables[["a22_none_of_the_above_column_c7_"]] <- table_a22_none_of_the_above_column_c7_
print(paste("Generated frequency table: a22_none_of_the_above_column_c7_"))

# -----------------------------------------------------------------------------
# Table: a22_tito_s_column_ (frequency)
# Question: Which of the following brands do you associate with the following attribute? (Select all that apply.)
# Rows: 10
# Source: a22
# -----------------------------------------------------------------------------

table_a22_tito_s_column_ <- list(
  tableId = "a22_tito_s_column_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute? (Select all that apply.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Show Tito's (brand column) only for respondents who selected Tito's in A21",
  userNote = "(Select all that apply; values are binary flags where 1 = selected)",
  tableSubtitle = "Tito’s Handmade Vodka",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_tito_s_column_$data[[cut_name]] <- list()
  table_a22_tito_s_column_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c1 == 1
  var_col <- safe_get_var(cut_data, "A22r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r1c1_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r1c1_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c1 not found"
    )
  }

  # Row 2: A22r2c1 == 1
  var_col <- safe_get_var(cut_data, "A22r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r2c1_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r2c1_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c1 not found"
    )
  }

  # Row 3: A22r3c1 == 1
  var_col <- safe_get_var(cut_data, "A22r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r3c1_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r3c1_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c1 not found"
    )
  }

  # Row 4: A22r4c1 == 1
  var_col <- safe_get_var(cut_data, "A22r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r4c1_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r4c1_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c1 not found"
    )
  }

  # Row 5: A22r5c1 == 1
  var_col <- safe_get_var(cut_data, "A22r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r5c1_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r5c1_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c1 not found"
    )
  }

  # Row 6: A22r6c1 == 1
  var_col <- safe_get_var(cut_data, "A22r6c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r6c1_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r6c1_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c1 not found"
    )
  }

  # Row 7: A22r7c1 == 1
  var_col <- safe_get_var(cut_data, "A22r7c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r7c1_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r7c1_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c1 not found"
    )
  }

  # Row 8: A22r8c1 == 1
  var_col <- safe_get_var(cut_data, "A22r8c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r8c1_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r8c1_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c1 not found"
    )
  }

  # Row 9: A22r9c1 == 1
  var_col <- safe_get_var(cut_data, "A22r9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r9c1_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r9c1_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c1 not found"
    )
  }

  # Row 10: A22r10c1 == 1
  var_col <- safe_get_var(cut_data, "A22r10c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_$data[[cut_name]][["A22r10c1_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_$data[[cut_name]][["A22r10c1_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c1 not found"
    )
  }

}

all_tables[["a22_tito_s_column_"]] <- table_a22_tito_s_column_
print(paste("Generated frequency table: a22_tito_s_column_"))

# -----------------------------------------------------------------------------
# Table: a22_tito_s_column_c1_ (frequency)
# Question: Which of the following brands do you associate with the following attribute?
# Rows: 10
# Source: a22
# -----------------------------------------------------------------------------

table_a22_tito_s_column_c1_ <- list(
  tableId = "a22_tito_s_column_c1_",
  questionId = "A22",
  questionText = "Which of the following brands do you associate with the following attribute?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a22",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents aware of Tito's (A21r1 == 1)",
  userNote = "(Select all that apply; brands shown are those selected in A21)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a22_tito_s_column_c1_$data[[cut_name]] <- list()
  table_a22_tito_s_column_c1_$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A22r1c1 == 1
  var_col <- safe_get_var(cut_data, "A22r1c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r1c1_row_1"]] <- list(
      label = "Premium",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r1c1_row_1"]] <- list(
      label = "Premium",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r1c1 not found"
    )
  }

  # Row 2: A22r2c1 == 1
  var_col <- safe_get_var(cut_data, "A22r2c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r2c1_row_2"]] <- list(
      label = "Approachable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r2c1_row_2"]] <- list(
      label = "Approachable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r2c1 not found"
    )
  }

  # Row 3: A22r3c1 == 1
  var_col <- safe_get_var(cut_data, "A22r3c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r3c1_row_3"]] <- list(
      label = "Authentic",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r3c1_row_3"]] <- list(
      label = "Authentic",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r3c1 not found"
    )
  }

  # Row 4: A22r4c1 == 1
  var_col <- safe_get_var(cut_data, "A22r4c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r4c1_row_4"]] <- list(
      label = "Generous",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r4c1_row_4"]] <- list(
      label = "Generous",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r4c1 not found"
    )
  }

  # Row 5: A22r5c1 == 1
  var_col <- safe_get_var(cut_data, "A22r5c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r5c1_row_5"]] <- list(
      label = "Edgy",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r5c1_row_5"]] <- list(
      label = "Edgy",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r5c1 not found"
    )
  }

  # Row 6: A22r6c1 == 1
  var_col <- safe_get_var(cut_data, "A22r6c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r6c1_row_6"]] <- list(
      label = "Independent",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r6c1_row_6"]] <- list(
      label = "Independent",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r6c1 not found"
    )
  }

  # Row 7: A22r7c1 == 1
  var_col <- safe_get_var(cut_data, "A22r7c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r7c1_row_7"]] <- list(
      label = "Bold",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r7c1_row_7"]] <- list(
      label = "Bold",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r7c1 not found"
    )
  }

  # Row 8: A22r8c1 == 1
  var_col <- safe_get_var(cut_data, "A22r8c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r8c1_row_8"]] <- list(
      label = "Reliable",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r8c1_row_8"]] <- list(
      label = "Reliable",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r8c1 not found"
    )
  }

  # Row 9: A22r9c1 == 1
  var_col <- safe_get_var(cut_data, "A22r9c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r9c1_row_9"]] <- list(
      label = "Down-to-Earth",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r9c1_row_9"]] <- list(
      label = "Down-to-Earth",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r9c1 not found"
    )
  }

  # Row 10: A22r10c1 == 1
  var_col <- safe_get_var(cut_data, "A22r10c1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r10c1_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a22_tito_s_column_c1_$data[[cut_name]][["A22r10c1_row_10"]] <- list(
      label = "Sophisticated / Refined",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A22r10c1 not found"
    )
  }

}

all_tables[["a22_tito_s_column_c1_"]] <- table_a22_tito_s_column_c1_
print(paste("Generated frequency table: a22_tito_s_column_c1_"))

# -----------------------------------------------------------------------------
# Table: a23_casamigos (frequency) [DERIVED]
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_casamigos <- list(
  tableId = "a23_casamigos",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a23",
  surveySection = "OCCASION LOOP",
  baseText = "Those who indicated awareness of Casamigos (A21r5 = 1)",
  userNote = "(Scale: 1 = Very Unlikely, 5 = Very Likely)",
  tableSubtitle = "Casamigos",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r5 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_casamigos$data[[cut_name]] <- list()
  table_a23_casamigos$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r5 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_1"]] <- list(
      label = "Consider Casamigos (Top 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_1"]] <- list(
      label = "Consider Casamigos (Top 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 2: A23r5 == 5
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_2"]] <- list(
      label = "Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_2"]] <- list(
      label = "Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 3: A23r5 == 4
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_3"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_3"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 4: A23r5 == 3
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 5: A23r5 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_5"]] <- list(
      label = "Not Likely (Bottom 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_5"]] <- list(
      label = "Not Likely (Bottom 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 6: A23r5 == 2
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

  # Row 7: A23r5 == 1
  var_col <- safe_get_var(cut_data, "A23r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_casamigos$data[[cut_name]][["A23r5_row_7"]] <- list(
      label = "Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_casamigos$data[[cut_name]][["A23r5_row_7"]] <- list(
      label = "Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r5 not found"
    )
  }

}

all_tables[["a23_casamigos"]] <- table_a23_casamigos
print(paste("Generated frequency table: a23_casamigos"))

# -----------------------------------------------------------------------------
# Table: a23_don_julio (frequency) [DERIVED]
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_don_julio <- list(
  tableId = "a23_don_julio",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a23",
  surveySection = "OCCASION LOOP",
  baseText = "Those who indicated awareness of Don Julio (A21r6 = 1)",
  userNote = "(Asked for each brand a respondent selected in A21)",
  tableSubtitle = "Don Julio",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r6 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_don_julio$data[[cut_name]] <- list()
  table_a23_don_julio$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r6 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_1"]] <- list(
      label = "Consider (Top 2 Box, T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_1"]] <- list(
      label = "Consider (Top 2 Box, T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 2: A23r6 == 5
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_2"]] <- list(
      label = "Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_2"]] <- list(
      label = "Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 3: A23r6 == 4
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_3"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_3"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 4: A23r6 == 3
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 5: A23r6 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_5"]] <- list(
      label = "Not Consider (Bottom 2 Box, B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_5"]] <- list(
      label = "Not Consider (Bottom 2 Box, B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 6: A23r6 == 2
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

  # Row 7: A23r6 == 1
  var_col <- safe_get_var(cut_data, "A23r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_don_julio$data[[cut_name]][["A23r6_row_7"]] <- list(
      label = "Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_don_julio$data[[cut_name]][["A23r6_row_7"]] <- list(
      label = "Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r6 not found"
    )
  }

}

all_tables[["a23_don_julio"]] <- table_a23_don_julio
print(paste("Generated frequency table: a23_don_julio"))

# -----------------------------------------------------------------------------
# Table: a23_grey_goose (frequency) [DERIVED]
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_grey_goose <- list(
  tableId = "a23_grey_goose",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a23",
  surveySection = "OCCASION LOOP",
  baseText = "Those who indicated awareness of Grey Goose (A21r2 = 1)",
  userNote = "(Select one)",
  tableSubtitle = "Grey Goose",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r2 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_grey_goose$data[[cut_name]] <- list()
  table_a23_grey_goose$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r2 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_1"]] <- list(
      label = "Consider (T2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_1"]] <- list(
      label = "Consider (T2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 2: A23r2 == 4
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_2"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_2"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 3: A23r2 == 5
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_3"]] <- list(
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
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_3"]] <- list(
      label = "Very likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 4: A23r2 == 3
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_4"]] <- list(
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
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_4"]] <- list(
      label = "Neither likely nor unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 5: A23r2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_5"]] <- list(
      label = "Not consider (B2B)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_5"]] <- list(
      label = "Not consider (B2B)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 6: A23r2 == 2
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

  # Row 7: A23r2 == 1
  var_col <- safe_get_var(cut_data, "A23r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_grey_goose$data[[cut_name]][["A23r2_row_7"]] <- list(
      label = "Very unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_grey_goose$data[[cut_name]][["A23r2_row_7"]] <- list(
      label = "Very unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r2 not found"
    )
  }

}

all_tables[["a23_grey_goose"]] <- table_a23_grey_goose
print(paste("Generated frequency table: a23_grey_goose"))

# -----------------------------------------------------------------------------
# Table: a23_ketel_one (frequency)
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_ketel_one <- list(
  tableId = "a23_ketel_one",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a23",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "Those who indicated awareness of Ketel One (A21r3 = 1)",
  userNote = "(Select one)",
  tableSubtitle = "Ketel One",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r3 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_ketel_one$data[[cut_name]] <- list()
  table_a23_ketel_one$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r3 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_1"]] <- list(
      label = "Likely (Top 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_1"]] <- list(
      label = "Likely (Top 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 2: A23r3 == 5
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_2"]] <- list(
      label = "Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_2"]] <- list(
      label = "Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 3: A23r3 == 4
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_3"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_3"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 4: A23r3 == 3
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 5: A23r3 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_5"]] <- list(
      label = "Unlikely (Bottom 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_5"]] <- list(
      label = "Unlikely (Bottom 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 6: A23r3 == 2
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

  # Row 7: A23r3 == 1
  var_col <- safe_get_var(cut_data, "A23r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_ketel_one$data[[cut_name]][["A23r3_row_7"]] <- list(
      label = "Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_ketel_one$data[[cut_name]][["A23r3_row_7"]] <- list(
      label = "Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r3 not found"
    )
  }

}

all_tables[["a23_ketel_one"]] <- table_a23_ketel_one
print(paste("Generated frequency table: a23_ketel_one"))

# -----------------------------------------------------------------------------
# Table: a23_maker_s_mark (frequency)
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_maker_s_mark <- list(
  tableId = "a23_maker_s_mark",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a23",
  surveySection = "OCCASION LOOP",
  baseText = "Those who indicated awareness of Maker's Mark (A21r4 = 1)",
  userNote = "(5-point likelihood scale; Top 2 Box and Bottom 2 Box added)",
  tableSubtitle = "Maker's Mark",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r4 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_maker_s_mark$data[[cut_name]] <- list()
  table_a23_maker_s_mark$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r4 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_1"]] <- list(
      label = "Likely (Top 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_1"]] <- list(
      label = "Likely (Top 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 2: A23r4 == 5
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_2"]] <- list(
      label = "Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_2"]] <- list(
      label = "Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 3: A23r4 == 4
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_3"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_3"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 4: A23r4 == 3
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 5: A23r4 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_5"]] <- list(
      label = "Unlikely (Bottom 2 Box)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_5"]] <- list(
      label = "Unlikely (Bottom 2 Box)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 6: A23r4 == 2
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

  # Row 7: A23r4 == 1
  var_col <- safe_get_var(cut_data, "A23r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_7"]] <- list(
      label = "Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_maker_s_mark$data[[cut_name]][["A23r4_row_7"]] <- list(
      label = "Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r4 not found"
    )
  }

}

all_tables[["a23_maker_s_mark"]] <- table_a23_maker_s_mark
print(paste("Generated frequency table: a23_maker_s_mark"))

# -----------------------------------------------------------------------------
# Table: a23_tito_s_handmade_vodka (frequency) [DERIVED]
# Question: How likely are you to consider the following brands the next time you have a drink?
# Rows: 7
# Source: a23
# -----------------------------------------------------------------------------

table_a23_tito_s_handmade_vodka <- list(
  tableId = "a23_tito_s_handmade_vodka",
  questionId = "A23",
  questionText = "How likely are you to consider the following brands the next time you have a drink?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a23",
  surveySection = "OCCASION LOOP",
  baseText = "Those who indicated awareness of Tito's Handmade Vodka (A21r1 = 1)",
  userNote = "(Single-select 5-point likelihood scale; Top/Bottom 2 Box rollups added)",
  tableSubtitle = "Tito’s Handmade Vodka",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # Apply table-specific filter (skip logic)
  additional_mask <- with(cut_data, eval(parse(text = "A21r1 == 1")))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
  table_a23_tito_s_handmade_vodka$data[[cut_name]] <- list()
  table_a23_tito_s_handmade_vodka$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A23r1 IN (4, 5)
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(4, 5), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_1"]] <- list(
      label = "Top 2 Box (T2B): Likely or Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_1"]] <- list(
      label = "Top 2 Box (T2B): Likely or Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 2: A23r1 == 5
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_2"]] <- list(
      label = "Very Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_2"]] <- list(
      label = "Very Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 3: A23r1 == 4
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_3"]] <- list(
      label = "Likely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_3"]] <- list(
      label = "Likely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 4: A23r1 == 3
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_4"]] <- list(
      label = "Neither Likely nor Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 5: A23r1 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_5"]] <- list(
      label = "Bottom 2 Box (B2B): Unlikely or Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_5"]] <- list(
      label = "Bottom 2 Box (B2B): Unlikely or Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 6: A23r1 == 2
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_6"]] <- list(
      label = "Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_6"]] <- list(
      label = "Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

  # Row 7: A23r1 == 1
  var_col <- safe_get_var(cut_data, "A23r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_7"]] <- list(
      label = "Very Unlikely",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a23_tito_s_handmade_vodka$data[[cut_name]][["A23r1_row_7"]] <- list(
      label = "Very Unlikely",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A23r1 not found"
    )
  }

}

all_tables[["a23_tito_s_handmade_vodka"]] <- table_a23_tito_s_handmade_vodka
print(paste("Generated frequency table: a23_tito_s_handmade_vodka"))

# -----------------------------------------------------------------------------
# Table: c3 (frequency)
# Question: What is your current employment status?
# Rows: 13
# Source: c3
# -----------------------------------------------------------------------------

table_c3 <- list(
  tableId = "c3",
  questionId = "C3",
  questionText = "What is your current employment status?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "c3",
  surveySection = "DEMOGRAPHICS AND PROFILING",
  baseText = "",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_c3$data[[cut_name]] <- list()
  table_c3$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Employed (NET) (components: C3r2, C3r3, C3r4)
  net_vars <- c("C3r2", "C3r3", "C3r4")
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

    table_c3$data[[cut_name]][["_NET_Employed_row_1"]] <- list(
      label = "Employed (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: C3r2 == 1
  var_col <- safe_get_var(cut_data, "C3r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r2_row_2"]] <- list(
      label = "Employed full-time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r2_row_2"]] <- list(
      label = "Employed full-time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r2 not found"
    )
  }

  # Row 3: C3r3 == 1
  var_col <- safe_get_var(cut_data, "C3r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r3_row_3"]] <- list(
      label = "Employed part-time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r3_row_3"]] <- list(
      label = "Employed part-time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r3 not found"
    )
  }

  # Row 4: C3r4 == 1
  var_col <- safe_get_var(cut_data, "C3r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r4_row_4"]] <- list(
      label = "Self-employed",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r4_row_4"]] <- list(
      label = "Self-employed",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r4 not found"
    )
  }

  # Row 5: NET - Out of work (NET) (components: C3r6, C3r7)
  net_vars <- c("C3r6", "C3r7")
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

    table_c3$data[[cut_name]][["_NET_OutOfWork_row_5"]] <- list(
      label = "Out of work (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 6: C3r6 == 1
  var_col <- safe_get_var(cut_data, "C3r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r6_row_6"]] <- list(
      label = "Out of work for 1 year or more, but not retired",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r6_row_6"]] <- list(
      label = "Out of work for 1 year or more, but not retired",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r6 not found"
    )
  }

  # Row 7: C3r7 == 1
  var_col <- safe_get_var(cut_data, "C3r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r7_row_7"]] <- list(
      label = "Out of work for less than 1 year, but not retired",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r7_row_7"]] <- list(
      label = "Out of work for less than 1 year, but not retired",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r7 not found"
    )
  }

  # Row 8: C3r1 == 1
  var_col <- safe_get_var(cut_data, "C3r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r1_row_8"]] <- list(
      label = "Full-time student",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r1_row_8"]] <- list(
      label = "Full-time student",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r1 not found"
    )
  }

  # Row 9: C3r5 == 1
  var_col <- safe_get_var(cut_data, "C3r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r5_row_9"]] <- list(
      label = "Full-time homemaker",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r5_row_9"]] <- list(
      label = "Full-time homemaker",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r5 not found"
    )
  }

  # Row 10: C3r8 == 1
  var_col <- safe_get_var(cut_data, "C3r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r8_row_10"]] <- list(
      label = "Retired",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r8_row_10"]] <- list(
      label = "Retired",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r8 not found"
    )
  }

  # Row 11: C3r9 == 1
  var_col <- safe_get_var(cut_data, "C3r9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r9_row_11"]] <- list(
      label = "Unable to work",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r9_row_11"]] <- list(
      label = "Unable to work",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r9 not found"
    )
  }

  # Row 12: C3r10 == 1
  var_col <- safe_get_var(cut_data, "C3r10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r10_row_12"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r10_row_12"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r10 not found"
    )
  }

  # Row 13: C3r11 == 1
  var_col <- safe_get_var(cut_data, "C3r11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_c3$data[[cut_name]][["C3r11_row_13"]] <- list(
      label = "Prefer not to answer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_c3$data[[cut_name]][["C3r11_row_13"]] <- list(
      label = "Prefer not to answer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable C3r11 not found"
    )
  }

}

all_tables[["c3"]] <- table_c3
print(paste("Generated frequency table: c3"))

# -----------------------------------------------------------------------------
# Table: a13a_1 (frequency)
# Question: In addition to the drink you indicated, did you have any other drinks during that visit to this location? (As a reminder, we’re asking about the drink at this location.)
# Rows: 2
# Source: a13a_1
# -----------------------------------------------------------------------------

table_a13a_1 <- list(
  tableId = "a13a_1",
  questionId = "A13a_1",
  questionText = "In addition to the drink you indicated, did you have any other drinks during that visit to this location? (As a reminder, we’re asking about the drink at this location.)",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a13a_1",
  surveySection = "OCCASION LOOP",
  baseText = "Asked about the drink at a specific location (e.g., Location 1 or Location 2 within the occasion loop)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a13a_1$data[[cut_name]] <- list()
  table_a13a_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A13a_1 == 1
  var_col <- safe_get_var(cut_data, "A13a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13a_1$data[[cut_name]][["A13a_1_row_1"]] <- list(
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
    table_a13a_1$data[[cut_name]][["A13a_1_row_1"]] <- list(
      label = "Yes",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13a_1 not found"
    )
  }

  # Row 2: A13a_1 == 2
  var_col <- safe_get_var(cut_data, "A13a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13a_1$data[[cut_name]][["A13a_1_row_2"]] <- list(
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
    table_a13a_1$data[[cut_name]][["A13a_1_row_2"]] <- list(
      label = "No",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13a_1 not found"
    )
  }

}

all_tables[["a13a_1"]] <- table_a13a_1
print(paste("Generated frequency table: a13a_1"))

# -----------------------------------------------------------------------------
# Table: a13a_2 (frequency)
# Question: In addition to the drink you indicated (A4), did you have any other drinks at this location?
# Rows: 2
# Source: a13a_2
# -----------------------------------------------------------------------------

table_a13a_2 <- list(
  tableId = "a13a_2",
  questionId = "A13a_2",
  questionText = "In addition to the drink you indicated (A4), did you have any other drinks at this location?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a13a_2",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents thinking about the drink at Location 2",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a13a_2$data[[cut_name]] <- list()
  table_a13a_2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A13a_2 == 1
  var_col <- safe_get_var(cut_data, "A13a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13a_2$data[[cut_name]][["A13a_2_row_1"]] <- list(
      label = "Yes, I had one or more drinks in addition to the drink I described",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13a_2$data[[cut_name]][["A13a_2_row_1"]] <- list(
      label = "Yes, I had one or more drinks in addition to the drink I described",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13a_2 not found"
    )
  }

  # Row 2: A13a_2 == 2
  var_col <- safe_get_var(cut_data, "A13a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13a_2$data[[cut_name]][["A13a_2_row_2"]] <- list(
      label = "No, I only had the drink I described",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13a_2$data[[cut_name]][["A13a_2_row_2"]] <- list(
      label = "No, I only had the drink I described",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13a_2 not found"
    )
  }

}

all_tables[["a13a_2"]] <- table_a13a_2
print(paste("Generated frequency table: a13a_2"))

# -----------------------------------------------------------------------------
# Table: a13b_1 (frequency) [DERIVED] [LOOP: stacked_loop_1]
# Question: What other drinks did you have in addition to the drink you selected? (Select all that apply)
# Rows: 6
# Source: a13b_1
# -----------------------------------------------------------------------------

table_a13b_1 <- list(
  tableId = "a13b_1",
  questionId = "A13b_1",
  questionText = "What other drinks did you have in addition to the drink you selected? (Select all that apply)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a13b_1",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents who had one or more additional drinks at the same location (A13a = \"Yes\")",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a13b_1$data[[cut_name]] <- list()
  table_a13b_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any other drink (NET) (components: A13br1, A13br2, A13br3, A13br4, A13br5)
  net_vars <- c("A13br1", "A13br2", "A13br3", "A13br4", "A13br5")
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

    table_a13b_1$data[[cut_name]][["_NET_A13b_AnyOther_row_1"]] <- list(
      label = "Any other drink (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A13br1 == 1
  var_col <- safe_get_var(cut_data, "A13br1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13b_1$data[[cut_name]][["A13br1_row_2"]] <- list(
      label = "Beer",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13b_1$data[[cut_name]][["A13br1_row_2"]] <- list(
      label = "Beer",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13br1 not found"
    )
  }

  # Row 3: A13br2 == 1
  var_col <- safe_get_var(cut_data, "A13br2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13b_1$data[[cut_name]][["A13br2_row_3"]] <- list(
      label = "Wine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13b_1$data[[cut_name]][["A13br2_row_3"]] <- list(
      label = "Wine",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13br2 not found"
    )
  }

  # Row 4: A13br3 == 1
  var_col <- safe_get_var(cut_data, "A13br3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13b_1$data[[cut_name]][["A13br3_row_4"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13b_1$data[[cut_name]][["A13br3_row_4"]] <- list(
      label = "Canned cocktails / Ready-to-drink (RTD) cocktails",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13br3 not found"
    )
  }

  # Row 5: A13br4 == 1
  var_col <- safe_get_var(cut_data, "A13br4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13b_1$data[[cut_name]][["A13br4_row_5"]] <- list(
      label = "Liquor",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13b_1$data[[cut_name]][["A13br4_row_5"]] <- list(
      label = "Liquor",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13br4 not found"
    )
  }

  # Row 6: A13br5 == 1
  var_col <- safe_get_var(cut_data, "A13br5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a13b_1$data[[cut_name]][["A13br5_row_6"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a13b_1$data[[cut_name]][["A13br5_row_6"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A13br5 not found"
    )
  }

}

all_tables[["a13b_1"]] <- table_a13b_1
print(paste("Generated frequency table: a13b_1"))

# -----------------------------------------------------------------------------
# Table: a14a_1 (frequency)
# Question: When you recently had a drink, which of the following best describes your role in the original purchase of the drink for it?
# Rows: 4
# Source: a14a_1
# -----------------------------------------------------------------------------

table_a14a_1 <- list(
  tableId = "a14a_1",
  questionId = "A14a_1",
  questionText = "When you recently had a drink, which of the following best describes your role in the original purchase of the drink for it?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a14a_1",
  surveySection = "OCCASION LOOP",
  baseText = "Asked of respondents whose occasion was off-premise (when the drink was purchased off-premise).",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a14a_1$data[[cut_name]] <- list()
  table_a14a_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A14a_1 == 1
  var_col <- safe_get_var(cut_data, "A14a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_1$data[[cut_name]][["A14a_1_row_1"]] <- list(
      label = "I went to the store / made the purchase myself",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_1$data[[cut_name]][["A14a_1_row_1"]] <- list(
      label = "I went to the store / made the purchase myself",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_1 not found"
    )
  }

  # Row 2: A14a_1 == 2
  var_col <- safe_get_var(cut_data, "A14a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_1$data[[cut_name]][["A14a_1_row_2"]] <- list(
      label = "Someone else went to the store / made the purchase for me",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_1$data[[cut_name]][["A14a_1_row_2"]] <- list(
      label = "Someone else went to the store / made the purchase for me",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_1 not found"
    )
  }

  # Row 3: A14a_1 == 3
  var_col <- safe_get_var(cut_data, "A14a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_1$data[[cut_name]][["A14a_1_row_3"]] <- list(
      label = "Someone gave it to me as a gift",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_1$data[[cut_name]][["A14a_1_row_3"]] <- list(
      label = "Someone gave it to me as a gift",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_1 not found"
    )
  }

  # Row 4: A14a_1 == 4
  var_col <- safe_get_var(cut_data, "A14a_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_1$data[[cut_name]][["A14a_1_row_4"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_1$data[[cut_name]][["A14a_1_row_4"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_1 not found"
    )
  }

}

all_tables[["a14a_1"]] <- table_a14a_1
print(paste("Generated frequency table: a14a_1"))

# -----------------------------------------------------------------------------
# Table: a14a_2 (frequency)
# Question: When you recently had a drink, which of the following best describes your role in the original purchase of the drink?
# Rows: 6
# Source: a14a_2
# -----------------------------------------------------------------------------

table_a14a_2 <- list(
  tableId = "a14a_2",
  questionId = "A14a_2",
  questionText = "When you recently had a drink, which of the following best describes your role in the original purchase of the drink?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a14a_2",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "Asked of respondents whose occasion was off-premise (when A14a applied)",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a14a_2$data[[cut_name]] <- list()
  table_a14a_2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A14a_2 IN (1, 2)
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_1"]] <- list(
      label = "Purchased (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_1"]] <- list(
      label = "Purchased (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

  # Row 2: A14a_2 == 1
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_2"]] <- list(
      label = "I went to the store/made the purchase myself",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_2"]] <- list(
      label = "I went to the store/made the purchase myself",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

  # Row 3: A14a_2 == 2
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_3"]] <- list(
      label = "Someone else went to the store/made the purchase for me",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_3"]] <- list(
      label = "Someone else went to the store/made the purchase for me",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

  # Row 4: A14a_2 IN (3, 4)
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(3, 4), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_4"]] <- list(
      label = "Received/Gift or Other (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_4"]] <- list(
      label = "Received/Gift or Other (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

  # Row 5: A14a_2 == 3
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_5"]] <- list(
      label = "Someone gave it to me as a gift",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_5"]] <- list(
      label = "Someone gave it to me as a gift",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

  # Row 6: A14a_2 == 4
  var_col <- safe_get_var(cut_data, "A14a_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14a_2$data[[cut_name]][["A14a_2_row_6"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14a_2$data[[cut_name]][["A14a_2_row_6"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14a_2 not found"
    )
  }

}

all_tables[["a14a_2"]] <- table_a14a_2
print(paste("Generated frequency table: a14a_2"))

# -----------------------------------------------------------------------------
# Table: a14b_1 (frequency) [DERIVED]
# Question: Given you purchased the [pipe: A4_1] for the drink you recently had, where did you originally make the purchase?
# Rows: 15
# Source: a14b_1
# -----------------------------------------------------------------------------

table_a14b_1 <- list(
  tableId = "a14b_1",
  questionId = "A14b_1",
  questionText = "Given you purchased the [pipe: A4_1] for the drink you recently had, where did you originally make the purchase?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a14b_1",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents who purchased the drink themselves",
  userNote = "(Select one)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a14b_1$data[[cut_name]] <- list()
  table_a14b_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A14b_1 IN (1, 2, 3, 4, 12)
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3, 4, 12), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_1"]] <- list(
      label = "Supermarket (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_1"]] <- list(
      label = "Supermarket (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 2: A14b_1 == 1
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_2"]] <- list(
      label = "Grocery Chain (e.g., Safeway or Kroger)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_2"]] <- list(
      label = "Grocery Chain (e.g., Safeway or Kroger)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 3: A14b_1 == 2
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_3"]] <- list(
      label = "Specialty Grocery Store (e.g., Whole Foods, Sprouts, Trader Joe's)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_3"]] <- list(
      label = "Specialty Grocery Store (e.g., Whole Foods, Sprouts, Trader Joe's)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 4: A14b_1 == 3
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_4"]] <- list(
      label = "Discount Grocery Store (e.g., ALDI, Lidl)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_4"]] <- list(
      label = "Discount Grocery Store (e.g., ALDI, Lidl)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 5: A14b_1 == 4
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_5"]] <- list(
      label = "Ethnic Grocery Store (e.g., Supermercado Latino)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_5"]] <- list(
      label = "Ethnic Grocery Store (e.g., Supermercado Latino)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 6: A14b_1 == 12
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_6"]] <- list(
      label = "Other Retail Store (e.g., corner store, bodega, home improvement stores)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_6"]] <- list(
      label = "Other Retail Store (e.g., corner store, bodega, home improvement stores)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 7: A14b_1 IN (7, 8, 9)
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(7, 8, 9), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_7"]] <- list(
      label = "Convenience / Gas (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_7"]] <- list(
      label = "Convenience / Gas (NET)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 8: A14b_1 == 7
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_8"]] <- list(
      label = "Dollar Store (e.g., Dollar General, Dollar Tree or Family Dollar)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_8"]] <- list(
      label = "Dollar Store (e.g., Dollar General, Dollar Tree or Family Dollar)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 9: A14b_1 == 8
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_9"]] <- list(
      label = "Drug Store (e.g., CVS, Rite Aid or Walgreens)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_9"]] <- list(
      label = "Drug Store (e.g., CVS, Rite Aid or Walgreens)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 10: A14b_1 == 9
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_10"]] <- list(
      label = "Convenience Store / Gas Station (e.g., 7-Eleven, Wawa, QuikTrip, Circle K)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_10"]] <- list(
      label = "Convenience Store / Gas Station (e.g., 7-Eleven, Wawa, QuikTrip, Circle K)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 11: A14b_1 == 5
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_11"]] <- list(
      label = "Superstore / Mass Merchandiser (e.g., Meijer, Target, Walmart)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_11"]] <- list(
      label = "Superstore / Mass Merchandiser (e.g., Meijer, Target, Walmart)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 12: A14b_1 == 6
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_12"]] <- list(
      label = "Warehouse Club (e.g., BJ's, Costco, Sam's Club)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_12"]] <- list(
      label = "Warehouse Club (e.g., BJ's, Costco, Sam's Club)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 13: A14b_1 == 10
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_13"]] <- list(
      label = "Online Only Store (e.g., Amazon)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_13"]] <- list(
      label = "Online Only Store (e.g., Amazon)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 14: A14b_1 == 11
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_14"]] <- list(
      label = "Liquor / Package Store (e.g., local liquor store, BevMo, Total Wine)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_14"]] <- list(
      label = "Liquor / Package Store (e.g., local liquor store, BevMo, Total Wine)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

  # Row 15: A14b_1 == 13
  var_col <- safe_get_var(cut_data, "A14b_1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_1$data[[cut_name]][["A14b_1_row_15"]] <- list(
      label = "Other (specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_1$data[[cut_name]][["A14b_1_row_15"]] <- list(
      label = "Other (specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_1 not found"
    )
  }

}

all_tables[["a14b_1"]] <- table_a14b_1
print(paste("Generated frequency table: a14b_1"))

# -----------------------------------------------------------------------------
# Table: a14b_2 (frequency)
# Question: Given you purchased the [pipe: A4_2] for the drink you recently had, where did you originally make the purchase?
# Rows: 16
# Source: a14b_2
# -----------------------------------------------------------------------------

table_a14b_2 <- list(
  tableId = "a14b_2",
  questionId = "A14b_2",
  questionText = "Given you purchased the [pipe: A4_2] for the drink you recently had, where did you originally make the purchase?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a14b_2",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents who purchased the drink themselves",
  userNote = "(Asked only of respondents who purchased the drink themselves)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])
  table_a14b_2$data[[cut_name]] <- list()
  table_a14b_2$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: A14b_2 IN (1, 2, 3, 4, 12)
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(1, 2, 3, 4, 12), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_1"]] <- list(
      label = "Supermarket (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_1"]] <- list(
      label = "Supermarket (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 2: A14b_2 == 1
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_2"]] <- list(
      label = "Grocery Chain (e.g., Safeway or Kroger)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_2"]] <- list(
      label = "Grocery Chain (e.g., Safeway or Kroger)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 3: A14b_2 == 2
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 2, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_3"]] <- list(
      label = "Specialty Grocery Store (e.g., Whole Foods, Sprout’s or Trader Joe’s)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_3"]] <- list(
      label = "Specialty Grocery Store (e.g., Whole Foods, Sprout’s or Trader Joe’s)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 4: A14b_2 == 3
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 3, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_4"]] <- list(
      label = "Discount Grocery Store (e.g., ALDI, or Lidl)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_4"]] <- list(
      label = "Discount Grocery Store (e.g., ALDI, or Lidl)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 5: A14b_2 == 4
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 4, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_5"]] <- list(
      label = "Ethnic Grocery Store (e.g., Supermercado Latino)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_5"]] <- list(
      label = "Ethnic Grocery Store (e.g., Supermercado Latino)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 6: A14b_2 == 12
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 12, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_6"]] <- list(
      label = "Other Retail Store (e.g., corner store, bodega, or home improvement stores)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_6"]] <- list(
      label = "Other Retail Store (e.g., corner store, bodega, or home improvement stores)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 7: A14b_2 IN (5, 6)
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(5, 6), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_7"]] <- list(
      label = "Mass merch / Supercenter (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_7"]] <- list(
      label = "Mass merch / Supercenter (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 8: A14b_2 == 5
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 5, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_8"]] <- list(
      label = "Superstore / Mass Merchandiser (e.g., Meijer, Target or Walmart)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_8"]] <- list(
      label = "Superstore / Mass Merchandiser (e.g., Meijer, Target or Walmart)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 9: A14b_2 == 6
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 6, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_9"]] <- list(
      label = "Warehouse Club (e.g., BJ’s, Costco, or Sam’s Club)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_9"]] <- list(
      label = "Warehouse Club (e.g., BJ’s, Costco, or Sam’s Club)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 10: A14b_2 IN (7, 8, 9)
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) %in% c(7, 8, 9), na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_10"]] <- list(
      label = "Convenience / Drug / Dollar (Total)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_10"]] <- list(
      label = "Convenience / Drug / Dollar (Total)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 11: A14b_2 == 7
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 7, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_11"]] <- list(
      label = "Dollar Store (e.g., Dollar General, Dollar Tree or Family Dollar)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_11"]] <- list(
      label = "Dollar Store (e.g., Dollar General, Dollar Tree or Family Dollar)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 12: A14b_2 == 8
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 8, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_12"]] <- list(
      label = "Drug Store (e.g., CVS, Rite Aid or Walgreens)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_12"]] <- list(
      label = "Drug Store (e.g., CVS, Rite Aid or Walgreens)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 13: A14b_2 == 9
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 9, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_13"]] <- list(
      label = "Convenience Store / Gas Station (e.g., 7-Eleven, Wawa, QuikTrip or Circle K)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_13"]] <- list(
      label = "Convenience Store / Gas Station (e.g., 7-Eleven, Wawa, QuikTrip or Circle K)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 14: A14b_2 == 10
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 10, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_14"]] <- list(
      label = "Online Only Store (e.g., Amazon)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_14"]] <- list(
      label = "Online Only Store (e.g., Amazon)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 15: A14b_2 == 11
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 11, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_15"]] <- list(
      label = "Liquor / Package Store (e.g., local liquor store, BevMo, Total Wine, ABC Stores)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_15"]] <- list(
      label = "Liquor / Package Store (e.g., local liquor store, BevMo, Total Wine, ABC Stores)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

  # Row 16: A14b_2 == 13
  var_col <- safe_get_var(cut_data, "A14b_2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 13, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a14b_2$data[[cut_name]][["A14b_2_row_16"]] <- list(
      label = "Other (specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a14b_2$data[[cut_name]][["A14b_2_row_16"]] <- list(
      label = "Other (specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A14b_2 not found"
    )
  }

}

all_tables[["a14b_2"]] <- table_a14b_2
print(paste("Generated frequency table: a14b_2"))

# -----------------------------------------------------------------------------
# Table: a16_1 (frequency) [DERIVED] [LOOP: stacked_loop_1]
# Question: Which of the following best describes why you decided to purchase [INSERT A4]?
# Rows: 11
# Source: a16_1
# -----------------------------------------------------------------------------

table_a16_1 <- list(
  tableId = "a16_1",
  questionId = "A16_1",
  questionText = "Which of the following best describes why you decided to purchase [INSERT A4]?",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a16_1",
  surveySection = "OCCASION LOOP",
  baseText = "Asked of respondents who purchased the drink (those who selected that they purchased the drink)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a16_1$data[[cut_name]] <- list()
  table_a16_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any purchase reason (NET) (components: A16r1, A16r2, A16r3, A16r4, A16r5, A16r6, A16r7, A16r8, A16r9, A16r10)
  net_vars <- c("A16r1", "A16r2", "A16r3", "A16r4", "A16r5", "A16r6", "A16r7", "A16r8", "A16r9", "A16r10")
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

    table_a16_1$data[[cut_name]][["_NET_A16_Any_row_1"]] <- list(
      label = "Any purchase reason (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A16r1 == 1
  var_col <- safe_get_var(cut_data, "A16r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r1_row_2"]] <- list(
      label = "I needed to stock up on / refill my alcohol supply",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r1_row_2"]] <- list(
      label = "I needed to stock up on / refill my alcohol supply",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r1 not found"
    )
  }

  # Row 3: A16r2 == 1
  var_col <- safe_get_var(cut_data, "A16r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r2_row_3"]] <- list(
      label = "While shopping for groceries, I decided to pick up alcohol",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r2_row_3"]] <- list(
      label = "While shopping for groceries, I decided to pick up alcohol",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r2 not found"
    )
  }

  # Row 4: A16r3 == 1
  var_col <- safe_get_var(cut_data, "A16r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r3_row_4"]] <- list(
      label = "I wanted to browse the place’s alcohol selection and ended up purchasing",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r3_row_4"]] <- list(
      label = "I wanted to browse the place’s alcohol selection and ended up purchasing",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r3 not found"
    )
  }

  # Row 5: A16r4 == 1
  var_col <- safe_get_var(cut_data, "A16r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r4_row_5"]] <- list(
      label = "I wanted to add a new bottle to my at-home bar",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r4_row_5"]] <- list(
      label = "I wanted to add a new bottle to my at-home bar",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r4 not found"
    )
  }

  # Row 6: A16r5 == 1
  var_col <- safe_get_var(cut_data, "A16r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r5_row_6"]] <- list(
      label = "I needed it for a specific gathering, party, or event",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r5_row_6"]] <- list(
      label = "I needed it for a specific gathering, party, or event",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r5 not found"
    )
  }

  # Row 7: A16r6 == 1
  var_col <- safe_get_var(cut_data, "A16r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r6_row_7"]] <- list(
      label = "I saw it on social media and wanted to try",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r6_row_7"]] <- list(
      label = "I saw it on social media and wanted to try",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r6 not found"
    )
  }

  # Row 8: A16r7 == 1
  var_col <- safe_get_var(cut_data, "A16r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r7_row_8"]] <- list(
      label = "Someone told me I needed to try it",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r7_row_8"]] <- list(
      label = "Someone told me I needed to try it",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r7 not found"
    )
  }

  # Row 9: A16r8 == 1
  var_col <- safe_get_var(cut_data, "A16r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r8_row_9"]] <- list(
      label = "I bought it to make a specific cocktail",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r8_row_9"]] <- list(
      label = "I bought it to make a specific cocktail",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r8 not found"
    )
  }

  # Row 10: A16r9 == 1
  var_col <- safe_get_var(cut_data, "A16r9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r9_row_10"]] <- list(
      label = "I thought my visiting family/friends would enjoy it",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r9_row_10"]] <- list(
      label = "I thought my visiting family/friends would enjoy it",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r9 not found"
    )
  }

  # Row 11: A16r10 == 1
  var_col <- safe_get_var(cut_data, "A16r10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a16_1$data[[cut_name]][["A16r10_row_11"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a16_1$data[[cut_name]][["A16r10_row_11"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A16r10 not found"
    )
  }

}

all_tables[["a16_1"]] <- table_a16_1
print(paste("Generated frequency table: a16_1"))

# -----------------------------------------------------------------------------
# Table: a17_1 (frequency) [DERIVED] [LOOP: stacked_loop_1]
# Question: Which of the following best describes why you purchased from the store? (Select all that apply.)
# Rows: 10
# Source: a17_1
# -----------------------------------------------------------------------------

table_a17_1 <- list(
  tableId = "a17_1",
  questionId = "A17_1",
  questionText = "Which of the following best describes why you purchased from the store? (Select all that apply.)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a17_1",
  surveySection = "OCCASION LOOP",
  baseText = "Respondents who purchased the drink (asked of those who purchased the drink)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a17_1$data[[cut_name]] <- list()
  table_a17_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any reason (NET) (components: A17r1, A17r2, A17r3, A17r4, A17r5, A17r6, A17r7, A17r8, A17r9)
  net_vars <- c("A17r1", "A17r2", "A17r3", "A17r4", "A17r5", "A17r6", "A17r7", "A17r8", "A17r9")
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

    table_a17_1$data[[cut_name]][["_NET_A17_AnyReason_row_1"]] <- list(
      label = "Any reason (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A17r1 == 1
  var_col <- safe_get_var(cut_data, "A17r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r1_row_2"]] <- list(
      label = "It’s convenient / close to home or work",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r1_row_2"]] <- list(
      label = "It’s convenient / close to home or work",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r1 not found"
    )
  }

  # Row 3: A17r2 == 1
  var_col <- safe_get_var(cut_data, "A17r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r2_row_3"]] <- list(
      label = "It offers the best prices or promotions",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r2_row_3"]] <- list(
      label = "It offers the best prices or promotions",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r2 not found"
    )
  }

  # Row 4: A17r3 == 1
  var_col <- safe_get_var(cut_data, "A17r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r3_row_4"]] <- list(
      label = "It has the best selection / variety",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r3_row_4"]] <- list(
      label = "It has the best selection / variety",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r3 not found"
    )
  }

  # Row 5: A17r4 == 1
  var_col <- safe_get_var(cut_data, "A17r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r4_row_5"]] <- list(
      label = "It’s where I do my regular shopping (groceries, errands, etc.)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r4_row_5"]] <- list(
      label = "It’s where I do my regular shopping (groceries, errands, etc.)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r4 not found"
    )
  }

  # Row 6: A17r5 == 1
  var_col <- safe_get_var(cut_data, "A17r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r5_row_6"]] <- list(
      label = "It was the only store open / available at the time",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r5_row_6"]] <- list(
      label = "It was the only store open / available at the time",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r5 not found"
    )
  }

  # Row 7: A17r6 == 1
  var_col <- safe_get_var(cut_data, "A17r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r6_row_7"]] <- list(
      label = "It’s my go‑to place to purchase alcohol",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r6_row_7"]] <- list(
      label = "It’s my go‑to place to purchase alcohol",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r6 not found"
    )
  }

  # Row 8: A17r7 == 1
  var_col <- safe_get_var(cut_data, "A17r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r7_row_8"]] <- list(
      label = "It was my only option due to state or local laws",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r7_row_8"]] <- list(
      label = "It was my only option due to state or local laws",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r7 not found"
    )
  }

  # Row 9: A17r8 == 1
  var_col <- safe_get_var(cut_data, "A17r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r8_row_9"]] <- list(
      label = "It was the only place I could buy this type of drink",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r8_row_9"]] <- list(
      label = "It was the only place I could buy this type of drink",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r8 not found"
    )
  }

  # Row 10: A17r9 == 1
  var_col <- safe_get_var(cut_data, "A17r9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a17_1$data[[cut_name]][["A17r9_row_10"]] <- list(
      label = "Other (specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a17_1$data[[cut_name]][["A17r9_row_10"]] <- list(
      label = "Other (specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A17r9 not found"
    )
  }

}

all_tables[["a17_1"]] <- table_a17_1
print(paste("Generated frequency table: a17_1"))

# -----------------------------------------------------------------------------
# Table: a19_1 (frequency) [DERIVED] [LOOP: stacked_loop_1]
# Question: When you purchased the drink, which of the following describes why you chose that brand? (Select all that apply)
# Rows: 13
# Source: a19_1
# -----------------------------------------------------------------------------

table_a19_1 <- list(
  tableId = "a19_1",
  questionId = "A19_1",
  questionText = "When you purchased the drink, which of the following describes why you chose that brand? (Select all that apply)",
  tableType = "frequency",
  isDerived = TRUE,
  sourceTableId = "a19_1",
  surveySection = "SECTION A: OCCASION LOOP",
  baseText = "Respondents asked about the drink at the occasion (loop instance)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a19_1$data[[cut_name]] <- list()
  table_a19_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any reason (NET) (components: A19r1, A19r2, A19r3, A19r4, A19r5, A19r6, A19r7, A19r8, A19r9, A19r10, A19r11)
  net_vars <- c("A19r1", "A19r2", "A19r3", "A19r4", "A19r5", "A19r6", "A19r7", "A19r8", "A19r9", "A19r10", "A19r11")
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

    table_a19_1$data[[cut_name]][["_NET_A19_AnyReason_row_1"]] <- list(
      label = "Any reason (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 2: A19r1 == 1
  var_col <- safe_get_var(cut_data, "A19r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r1_row_2"]] <- list(
      label = "It's the brand I always get",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r1_row_2"]] <- list(
      label = "It's the brand I always get",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r1 not found"
    )
  }

  # Row 3: A19r2 == 1
  var_col <- safe_get_var(cut_data, "A19r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r2_row_3"]] <- list(
      label = "It was the best price for the quality I wanted",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r2_row_3"]] <- list(
      label = "It was the best price for the quality I wanted",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r2 not found"
    )
  }

  # Row 4: A19r3 == 1
  var_col <- safe_get_var(cut_data, "A19r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r3_row_4"]] <- list(
      label = "It was the cheapest",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r3_row_4"]] <- list(
      label = "It was the cheapest",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r3 not found"
    )
  }

  # Row 5: A19r4 == 1
  var_col <- safe_get_var(cut_data, "A19r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r4_row_5"]] <- list(
      label = "I liked the packaging (e.g., design, colors)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r4_row_5"]] <- list(
      label = "I liked the packaging (e.g., design, colors)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r4 not found"
    )
  }

  # Row 6: A19r5 == 1
  var_col <- safe_get_var(cut_data, "A19r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r5_row_6"]] <- list(
      label = "The store had it on display (e.g., end cap or table)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r5_row_6"]] <- list(
      label = "The store had it on display (e.g., end cap or table)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r5 not found"
    )
  }

  # Row 7: A19r6 == 1
  var_col <- safe_get_var(cut_data, "A19r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r6_row_7"]] <- list(
      label = "It had a special promotion / discount",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r6_row_7"]] <- list(
      label = "It had a special promotion / discount",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r6 not found"
    )
  }

  # Row 8: A19r7 == 1
  var_col <- safe_get_var(cut_data, "A19r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r7_row_8"]] <- list(
      label = "It was the first one I saw",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r7_row_8"]] <- list(
      label = "It was the first one I saw",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r7 not found"
    )
  }

  # Row 9: A19r8 == 1
  var_col <- safe_get_var(cut_data, "A19r8")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r8_row_9"]] <- list(
      label = "I liked the product description on the packaging",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r8_row_9"]] <- list(
      label = "I liked the product description on the packaging",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r8 not found"
    )
  }

  # Row 10: A19r9 == 1
  var_col <- safe_get_var(cut_data, "A19r9")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r9_row_10"]] <- list(
      label = "The store had a note describing the flavor / ways to drink it",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r9_row_10"]] <- list(
      label = "The store had a note describing the flavor / ways to drink it",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r9 not found"
    )
  }

  # Row 11: A19r10 == 1
  var_col <- safe_get_var(cut_data, "A19r10")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r10_row_11"]] <- list(
      label = "It was recommended to me by a store associate",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r10_row_11"]] <- list(
      label = "It was recommended to me by a store associate",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r10 not found"
    )
  }

  # Row 12: A19r11 == 1
  var_col <- safe_get_var(cut_data, "A19r11")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r11_row_12"]] <- list(
      label = "Other (please specify)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a19_1$data[[cut_name]][["A19r11_row_12"]] <- list(
      label = "Other (please specify)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r11 not found"
    )
  }

  # Row 13: A19r12 == 1
  var_col <- safe_get_var(cut_data, "A19r12")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a19_1$data[[cut_name]][["A19r12_row_13"]] <- list(
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
    table_a19_1$data[[cut_name]][["A19r12_row_13"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A19r12 not found"
    )
  }

}

all_tables[["a19_1"]] <- table_a19_1
print(paste("Generated frequency table: a19_1"))

# -----------------------------------------------------------------------------
# Table: a7_1 (frequency) [LOOP: stacked_loop_1]
# Question: Did you consume any of the following products/substances at the same time as the drink you were describing?
# Rows: 7
# -----------------------------------------------------------------------------

table_a7_1 <- list(
  tableId = "a7_1",
  questionId = "A7_1",
  questionText = "Did you consume any of the following products/substances at the same time as the drink you were describing?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "",
  surveySection = "OCCASION LOOP",
  baseText = "Asked about the drink at the selected location (refer to the first drink at that location)",
  userNote = "(Select all that apply)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a7_1$data[[cut_name]] <- list()
  table_a7_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: NET - Any substance (NET) (components: A7r1, A7r2, A7r3, A7r4, A7r5)
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

    table_a7_1$data[[cut_name]][["_NET_AnySubstances_row_1"]] <- list(
      label = "Any substance (NET)",
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

    table_a7_1$data[[cut_name]][["A7r1_row_2"]] <- list(
      label = "Cannabis / THC",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7_1$data[[cut_name]][["A7r1_row_2"]] <- list(
      label = "Cannabis / THC",
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

    table_a7_1$data[[cut_name]][["A7r2_row_3"]] <- list(
      label = "Nicotine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7_1$data[[cut_name]][["A7r2_row_3"]] <- list(
      label = "Nicotine",
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

    table_a7_1$data[[cut_name]][["A7r3_row_4"]] <- list(
      label = "Magic mushrooms (e.g., psilocybin)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7_1$data[[cut_name]][["A7r3_row_4"]] <- list(
      label = "Magic mushrooms (e.g., psilocybin)",
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

    table_a7_1$data[[cut_name]][["A7r4_row_5"]] <- list(
      label = "Caffeine",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7_1$data[[cut_name]][["A7r4_row_5"]] <- list(
      label = "Caffeine",
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

    table_a7_1$data[[cut_name]][["A7r5_row_6"]] <- list(
      label = "Other substance",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a7_1$data[[cut_name]][["A7r5_row_6"]] <- list(
      label = "Other substance",
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

  # Row 7: A7r6 == 1
  var_col <- safe_get_var(cut_data, "A7r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a7_1$data[[cut_name]][["A7r6_row_7"]] <- list(
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
    table_a7_1$data[[cut_name]][["A7r6_row_7"]] <- list(
      label = "None of the above",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A7r6 not found"
    )
  }

}

all_tables[["a7_1"]] <- table_a7_1
print(paste("Generated frequency table: a7_1"))

# -----------------------------------------------------------------------------
# Table: a9_1 (frequency) [LOOP: stacked_loop_1]
# Question: Who was with you when you had this drink?
# Rows: 9
# Source: a9_1
# -----------------------------------------------------------------------------

table_a9_1 <- list(
  tableId = "a9_1",
  questionId = "A9_1",
  questionText = "Who was with you when you had this drink?",
  tableType = "frequency",
  isDerived = FALSE,
  sourceTableId = "a9_1",
  surveySection = "OCCASION LOOP",
  baseText = "",
  userNote = "(Select all that apply; “I was alone” was an anchor and mutually exclusive with other options)",
  tableSubtitle = "",
  excluded = FALSE,
  excludeReason = "",
  data = list()
)

for (cut_name in names(cuts_stacked_loop_1)) {
  cut_data <- apply_cut(stacked_loop_1, cuts_stacked_loop_1[[cut_name]])
  table_a9_1$data[[cut_name]] <- list()
  table_a9_1$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]

  # Row 1: Category header - Occasion companions:
  table_a9_1$data[[cut_name]][["_CAT__row_1"]] <- list(
    label = "Occasion companions:",
    n = NA,
    count = NA,
    pct = NA,
    isNet = FALSE,
    indent = 0,
    isCategoryHeader = TRUE,
    sig_higher_than = c(),
    sig_vs_total = NA
  )

  # Row 2: A9r1 == 1
  var_col <- safe_get_var(cut_data, "A9r1")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r1_row_2"]] <- list(
      label = "I was alone (mutually exclusive)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r1_row_2"]] <- list(
      label = "I was alone (mutually exclusive)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r1 not found"
    )
  }

  # Row 3: NET - Any other person (NET) (components: A9r2, A9r3, A9r4, A9r5, A9r6, A9r7)
  net_vars <- c("A9r2", "A9r3", "A9r4", "A9r5", "A9r6", "A9r7")
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

    table_a9_1$data[[cut_name]][["_NET_A9_Others_row_3"]] <- list(
      label = "Any other person (NET)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = TRUE,
      indent = 0,
      sig_higher_than = c(),
      sig_vs_total = NA
    )

  # Row 4: A9r2 == 1
  var_col <- safe_get_var(cut_data, "A9r2")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r2_row_4"]] <- list(
      label = "My spouse/partner",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r2_row_4"]] <- list(
      label = "My spouse/partner",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r2 not found"
    )
  }

  # Row 5: A9r3 == 1
  var_col <- safe_get_var(cut_data, "A9r3")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r3_row_5"]] <- list(
      label = "My parents",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r3_row_5"]] <- list(
      label = "My parents",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r3 not found"
    )
  }

  # Row 6: A9r4 == 1
  var_col <- safe_get_var(cut_data, "A9r4")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r4_row_6"]] <- list(
      label = "My child/children",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r4_row_6"]] <- list(
      label = "My child/children",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r4 not found"
    )
  }

  # Row 7: A9r5 == 1
  var_col <- safe_get_var(cut_data, "A9r5")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r5_row_7"]] <- list(
      label = "My friend(s)",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r5_row_7"]] <- list(
      label = "My friend(s)",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r5 not found"
    )
  }

  # Row 8: A9r6 == 1
  var_col <- safe_get_var(cut_data, "A9r6")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r6_row_8"]] <- list(
      label = "Other relatives",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r6_row_8"]] <- list(
      label = "Other relatives",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r6 not found"
    )
  }

  # Row 9: A9r7 == 1
  var_col <- safe_get_var(cut_data, "A9r7")
  if (!is.null(var_col)) {
    base_n <- sum(!is.na(var_col))
    count <- sum(as.numeric(var_col) == 1, na.rm = TRUE)
    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0

    table_a9_1$data[[cut_name]][["A9r7_row_9"]] <- list(
      label = "Colleagues / co-workers",
      n = base_n,
      count = count,
      pct = pct,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA
    )
  } else {
    table_a9_1$data[[cut_name]][["A9r7_row_9"]] <- list(
      label = "Colleagues / co-workers",
      n = 0,
      count = 0,
      pct = 0,
      isNet = FALSE,
      indent = 1,
      sig_higher_than = c(),
      sig_vs_total = NA,
      error = "Variable A9r7 not found"
    )
  }

}

all_tables[["a9_1"]] <- table_a9_1
print(paste("Generated frequency table: a9_1"))

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
    generatedAt = "2026-02-07T13:49:36.395Z",
    tableCount = 63,
    cutCount = 20,
    significanceTest = "unpooled z-test for column proportions",
    meanSignificanceTest = "two-sample t-test",
    significanceThresholds = c(0.1),
    significanceLevel = 0.1,
    totalRespondents = nrow(data),
    bannerGroups = fromJSON('[{"groupName":"Total","columns":[{"name":"Total","statLetter":"T"}]},{"groupName":"Needs State","columns":[{"name":"Connection / Belonging","statLetter":"A"},{"name":"Status / Image","statLetter":"B"},{"name":"Exploration / Discovery","statLetter":"C"},{"name":"Celebration","statLetter":"D"},{"name":"Indulgence","statLetter":"E"},{"name":"Escape / Relief","statLetter":"F"},{"name":"Performance","statLetter":"G"},{"name":"Tradition","statLetter":"H"}]},{"groupName":"Location","columns":[{"name":"Own Home","statLetter":"I"},{"name":"Others\' Home","statLetter":"J"},{"name":"Work / Office","statLetter":"K"},{"name":"College Dorm","statLetter":"L"},{"name":"Dining","statLetter":"M"},{"name":"Bar / Nightclub","statLetter":"N"},{"name":"Hotel / Motel","statLetter":"O"},{"name":"Recreation / Entertainment / Concession","statLetter":"P"},{"name":"Outdoor Gathering","statLetter":"Q"},{"name":"Airport / Transit Location","statLetter":"R"},{"name":"Other","statLetter":"S"}]}]'),
    comparisonGroups = fromJSON('["A/B/C/D/E/F/G/H","I/J/K/L/M/N/O/P/Q/R/S"]')
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