# HawkTab AI - R Validation Script
# Generated: 2026-02-06T14:36:45.909Z
# Tables to validate: 106

# Load required libraries
library(haven)
library(dplyr)
library(jsonlite)

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

# Cuts Definition (minimal for validation)
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

# Apply cut mask safely
apply_cut <- function(data, cut_mask) {
  safe_mask <- cut_mask
  safe_mask[is.na(safe_mask)] <- FALSE
  data[safe_mask, ]
}

# Safely get variable column
safe_get_var <- function(data, var_name) {
  if (var_name %in% names(data)) return(data[[var_name]])
  return(NULL)
}

# Initialize validation results
validation_results <- list()

# =============================================================================
# Table Validation (each wrapped in tryCatch)
# =============================================================================

# -----------------------------------------------------------------------------
# Table: s1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s1"]] <- tryCatch({

  # Row 1: S1 == 1,2
  if (!("S1" %in% names(data))) stop("Variable 'S1' not found")
  test_val <- sum(as.numeric(data[["S1"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: S1 == 1
  if (!("S1" %in% names(data))) stop("Variable 'S1' not found")
  test_val <- sum(as.numeric(data[["S1"]]) == 1, na.rm = TRUE)
  # Row 3: S1 == 2
  if (!("S1" %in% names(data))) stop("Variable 'S1' not found")
  test_val <- sum(as.numeric(data[["S1"]]) == 2, na.rm = TRUE)
  # Row 4: S1 == 3
  if (!("S1" %in% names(data))) stop("Variable 'S1' not found")
  test_val <- sum(as.numeric(data[["S1"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "s1", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s1", error = conditionMessage(e))
})

print(paste("Validated:", "s1", "-", if(validation_results[["s1"]]$success) "PASS" else paste("FAIL:", validation_results[["s1"]]$error)))

# -----------------------------------------------------------------------------
# Table: s2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s2"]] <- tryCatch({

  # Row 1: S2 == 1,2,3,4,5
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) %in% c(1, 2, 3, 4, 5), na.rm = TRUE)
  # Row 2: S2 == 1
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 1, na.rm = TRUE)
  # Row 3: S2 == 2
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 2, na.rm = TRUE)
  # Row 4: S2 == 3
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 3, na.rm = TRUE)
  # Row 5: S2 == 4
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 4, na.rm = TRUE)
  # Row 6: S2 == 5
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 5, na.rm = TRUE)
  # Row 7: S2 == 6,7
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) %in% c(6, 7), na.rm = TRUE)
  # Row 8: S2 == 6
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 6, na.rm = TRUE)
  # Row 9: S2 == 7
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 7, na.rm = TRUE)
  # Row 10: S2 == 99
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_val <- sum(as.numeric(data[["S2"]]) == 99, na.rm = TRUE)

  list(success = TRUE, tableId = "s2", rowCount = 10)

}, error = function(e) {
  list(success = FALSE, tableId = "s2", error = conditionMessage(e))
})

print(paste("Validated:", "s2", "-", if(validation_results[["s2"]]$success) "PASS" else paste("FAIL:", validation_results[["s2"]]$error)))

# -----------------------------------------------------------------------------
# Table: s2a (frequency)
# -----------------------------------------------------------------------------

validation_results[["s2a"]] <- tryCatch({

  # Row 1: S2a == 1
  if (!("S2a" %in% names(data))) stop("Variable 'S2a' not found")
  test_val <- sum(as.numeric(data[["S2a"]]) == 1, na.rm = TRUE)
  # Row 2: S2a == 2
  if (!("S2a" %in% names(data))) stop("Variable 'S2a' not found")
  test_val <- sum(as.numeric(data[["S2a"]]) == 2, na.rm = TRUE)
  # Row 3: S2a == 3
  if (!("S2a" %in% names(data))) stop("Variable 'S2a' not found")
  test_val <- sum(as.numeric(data[["S2a"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "s2a", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "s2a", error = conditionMessage(e))
})

print(paste("Validated:", "s2a", "-", if(validation_results[["s2a"]]$success) "PASS" else paste("FAIL:", validation_results[["s2a"]]$error)))

# -----------------------------------------------------------------------------
# Table: s2b (frequency)
# -----------------------------------------------------------------------------

validation_results[["s2b"]] <- tryCatch({

  # Row 1: S2b == 1
  if (!("S2b" %in% names(data))) stop("Variable 'S2b' not found")
  test_val <- sum(as.numeric(data[["S2b"]]) == 1, na.rm = TRUE)
  # Row 2: S2b == 2
  if (!("S2b" %in% names(data))) stop("Variable 'S2b' not found")
  test_val <- sum(as.numeric(data[["S2b"]]) == 2, na.rm = TRUE)
  # Row 3: S2b == 3
  if (!("S2b" %in% names(data))) stop("Variable 'S2b' not found")
  test_val <- sum(as.numeric(data[["S2b"]]) == 3, na.rm = TRUE)
  # Row 4: S2b == 99
  if (!("S2b" %in% names(data))) stop("Variable 'S2b' not found")
  test_val <- sum(as.numeric(data[["S2b"]]) == 99, na.rm = TRUE)

  list(success = TRUE, tableId = "s2b", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s2b", error = conditionMessage(e))
})

print(paste("Validated:", "s2b", "-", if(validation_results[["s2b"]]$success) "PASS" else paste("FAIL:", validation_results[["s2b"]]$error)))

# -----------------------------------------------------------------------------
# Table: s3a (frequency)
# -----------------------------------------------------------------------------

validation_results[["s3a"]] <- tryCatch({

  # Row 1: S3a == 1
  if (!("S3a" %in% names(data))) stop("Variable 'S3a' not found")
  test_val <- sum(as.numeric(data[["S3a"]]) == 1, na.rm = TRUE)
  # Row 2: S3a == 2,3
  if (!("S3a" %in% names(data))) stop("Variable 'S3a' not found")
  test_val <- sum(as.numeric(data[["S3a"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 3: S3a == 2
  if (!("S3a" %in% names(data))) stop("Variable 'S3a' not found")
  test_val <- sum(as.numeric(data[["S3a"]]) == 2, na.rm = TRUE)
  # Row 4: S3a == 3
  if (!("S3a" %in% names(data))) stop("Variable 'S3a' not found")
  test_val <- sum(as.numeric(data[["S3a"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "s3a", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s3a", error = conditionMessage(e))
})

print(paste("Validated:", "s3a", "-", if(validation_results[["s3a"]]$success) "PASS" else paste("FAIL:", validation_results[["s3a"]]$error)))

# -----------------------------------------------------------------------------
# Table: s4 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s4"]] <- tryCatch({

  # Row 1: S4 == 1,2
  if (!("S4" %in% names(data))) stop("Variable 'S4' not found")
  test_val <- sum(as.numeric(data[["S4"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: S4 == 1
  if (!("S4" %in% names(data))) stop("Variable 'S4' not found")
  test_val <- sum(as.numeric(data[["S4"]]) == 1, na.rm = TRUE)
  # Row 3: S4 == 2
  if (!("S4" %in% names(data))) stop("Variable 'S4' not found")
  test_val <- sum(as.numeric(data[["S4"]]) == 2, na.rm = TRUE)
  # Row 4: S4 == 3
  if (!("S4" %in% names(data))) stop("Variable 'S4' not found")
  test_val <- sum(as.numeric(data[["S4"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "s4", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s4", error = conditionMessage(e))
})

print(paste("Validated:", "s4", "-", if(validation_results[["s4"]]$success) "PASS" else paste("FAIL:", validation_results[["s4"]]$error)))

# -----------------------------------------------------------------------------
# Table: s5 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s5"]] <- tryCatch({

  # Row 1: S5r1 == 1
  if (!("S5r1" %in% names(data))) stop("Variable 'S5r1' not found")
  test_val <- sum(as.numeric(data[["S5r1"]]) == 1, na.rm = TRUE)
  # Row 2: S5r2 == 1
  if (!("S5r2" %in% names(data))) stop("Variable 'S5r2' not found")
  test_val <- sum(as.numeric(data[["S5r2"]]) == 1, na.rm = TRUE)
  # Row 3: S5r3 == 1
  if (!("S5r3" %in% names(data))) stop("Variable 'S5r3' not found")
  test_val <- sum(as.numeric(data[["S5r3"]]) == 1, na.rm = TRUE)
  # Row 4: S5r4 == 1
  if (!("S5r4" %in% names(data))) stop("Variable 'S5r4' not found")
  test_val <- sum(as.numeric(data[["S5r4"]]) == 1, na.rm = TRUE)
  # Row 5: S5r5 == 1
  if (!("S5r5" %in% names(data))) stop("Variable 'S5r5' not found")
  test_val <- sum(as.numeric(data[["S5r5"]]) == 1, na.rm = TRUE)
  # Row 6: S5r6 == 1
  if (!("S5r6" %in% names(data))) stop("Variable 'S5r6' not found")
  test_val <- sum(as.numeric(data[["S5r6"]]) == 1, na.rm = TRUE)
  # Row 7: S5r7 == 1
  if (!("S5r7" %in% names(data))) stop("Variable 'S5r7' not found")
  test_val <- sum(as.numeric(data[["S5r7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "s5", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "s5", error = conditionMessage(e))
})

print(paste("Validated:", "s5", "-", if(validation_results[["s5"]]$success) "PASS" else paste("FAIL:", validation_results[["s5"]]$error)))

# -----------------------------------------------------------------------------
# Table: s6 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s6"]] <- tryCatch({

  # Row 1: S6 == 3
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 3, na.rm = TRUE)
  # Row 2: S6 == 4
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 4, na.rm = TRUE)
  # Row 3: S6 == 5
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 5, na.rm = TRUE)
  # Row 4: S6 == 6
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 6, na.rm = TRUE)
  # Row 5: S6 == 7
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 7, na.rm = TRUE)
  # Row 6: S6 == 8
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 8, na.rm = TRUE)
  # Row 7: S6 == 9
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 9, na.rm = TRUE)
  # Row 8: S6 == 10
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 10, na.rm = TRUE)
  # Row 9: S6 == 11
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 11, na.rm = TRUE)
  # Row 10: S6 == 12
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 12, na.rm = TRUE)
  # Row 11: S6 == 13
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 13, na.rm = TRUE)
  # Row 12: S6 == 14
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 14, na.rm = TRUE)
  # Row 13: S6 == 15
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 15, na.rm = TRUE)
  # Row 14: S6 == 16
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 16, na.rm = TRUE)
  # Row 15: S6 == 17
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 17, na.rm = TRUE)
  # Row 16: S6 == 18
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 18, na.rm = TRUE)
  # Row 17: S6 == 19
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 19, na.rm = TRUE)
  # Row 18: S6 == 20
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 20, na.rm = TRUE)
  # Row 19: S6 == 21
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 21, na.rm = TRUE)
  # Row 20: S6 == 22
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 22, na.rm = TRUE)
  # Row 21: S6 == 23
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 23, na.rm = TRUE)
  # Row 22: S6 == 24
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 24, na.rm = TRUE)
  # Row 23: S6 == 25
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 25, na.rm = TRUE)
  # Row 24: S6 == 26
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 26, na.rm = TRUE)
  # Row 25: S6 == 27
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 27, na.rm = TRUE)
  # Row 26: S6 == 28
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 28, na.rm = TRUE)
  # Row 27: S6 == 29
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 29, na.rm = TRUE)
  # Row 28: S6 == 30
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 30, na.rm = TRUE)
  # Row 29: S6 == 31
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 31, na.rm = TRUE)
  # Row 30: S6 == 32
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 32, na.rm = TRUE)
  # Row 31: S6 == 33
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 33, na.rm = TRUE)
  # Row 32: S6 == 34
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 34, na.rm = TRUE)
  # Row 33: S6 == 35
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 35, na.rm = TRUE)

  list(success = TRUE, tableId = "s6", rowCount = 33)

}, error = function(e) {
  list(success = FALSE, tableId = "s6", error = conditionMessage(e))
})

print(paste("Validated:", "s6", "-", if(validation_results[["s6"]]$success) "PASS" else paste("FAIL:", validation_results[["s6"]]$error)))

# -----------------------------------------------------------------------------
# Table: s6_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["s6_binned"]] <- tryCatch({

  # Row 1: S6 == 3-10
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 3 & as.numeric(data[["S6"]]) <= 10, na.rm = TRUE)
  # Row 2: S6 == 3-5
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 3 & as.numeric(data[["S6"]]) <= 5, na.rm = TRUE)
  # Row 3: S6 == 6-10
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 6 & as.numeric(data[["S6"]]) <= 10, na.rm = TRUE)
  # Row 4: S6 == 11-20
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 11 & as.numeric(data[["S6"]]) <= 20, na.rm = TRUE)
  # Row 5: S6 == 11-15
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 11 & as.numeric(data[["S6"]]) <= 15, na.rm = TRUE)
  # Row 6: S6 == 16-20
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 16 & as.numeric(data[["S6"]]) <= 20, na.rm = TRUE)
  # Row 7: S6 == 21-35
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 21 & as.numeric(data[["S6"]]) <= 35, na.rm = TRUE)
  # Row 8: S6 == 21-25
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 21 & as.numeric(data[["S6"]]) <= 25, na.rm = TRUE)
  # Row 9: S6 == 26-30
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 26 & as.numeric(data[["S6"]]) <= 30, na.rm = TRUE)
  # Row 10: S6 == 31-35
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) >= 31 & as.numeric(data[["S6"]]) <= 35, na.rm = TRUE)

  list(success = TRUE, tableId = "s6_binned", rowCount = 10)

}, error = function(e) {
  list(success = FALSE, tableId = "s6_binned", error = conditionMessage(e))
})

print(paste("Validated:", "s6_binned", "-", if(validation_results[["s6_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["s6_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: s7 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s7"]] <- tryCatch({

  # Row 1: S7 == 1
  if (!("S7" %in% names(data))) stop("Variable 'S7' not found")
  test_val <- sum(as.numeric(data[["S7"]]) == 1, na.rm = TRUE)
  # Row 2: S7 == 2
  if (!("S7" %in% names(data))) stop("Variable 'S7' not found")
  test_val <- sum(as.numeric(data[["S7"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "s7", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "s7", error = conditionMessage(e))
})

print(paste("Validated:", "s7", "-", if(validation_results[["s7"]]$success) "PASS" else paste("FAIL:", validation_results[["s7"]]$error)))

# -----------------------------------------------------------------------------
# Table: s8 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s8"]] <- tryCatch({

  # Row 1: S8r1 (mean)
  if (!("S8r1" %in% names(data))) stop("Variable 'S8r1' not found")
  test_vals <- data[["S8r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S8r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: S8r2 (mean)
  if (!("S8r2" %in% names(data))) stop("Variable 'S8r2' not found")
  test_vals <- data[["S8r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S8r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: S8r3 (mean)
  if (!("S8r3" %in% names(data))) stop("Variable 'S8r3' not found")
  test_vals <- data[["S8r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S8r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: S8r4 (mean)
  if (!("S8r4" %in% names(data))) stop("Variable 'S8r4' not found")
  test_vals <- data[["S8r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S8r4' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s8", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s8", error = conditionMessage(e))
})

print(paste("Validated:", "s8", "-", if(validation_results[["s8"]]$success) "PASS" else paste("FAIL:", validation_results[["s8"]]$error)))

# -----------------------------------------------------------------------------
# Table: s8_S8r1_distribution (frequency)
# -----------------------------------------------------------------------------

validation_results[["s8_S8r1_distribution"]] <- tryCatch({

  # Row 1: S8r1 == 70-89
  if (!("S8r1" %in% names(data))) stop("Variable 'S8r1' not found")
  test_val <- sum(as.numeric(data[["S8r1"]]) >= 70 & as.numeric(data[["S8r1"]]) <= 89, na.rm = TRUE)
  # Row 2: S8r1 == 90-99
  if (!("S8r1" %in% names(data))) stop("Variable 'S8r1' not found")
  test_val <- sum(as.numeric(data[["S8r1"]]) >= 90 & as.numeric(data[["S8r1"]]) <= 99, na.rm = TRUE)
  # Row 3: S8r1 == 100
  if (!("S8r1" %in% names(data))) stop("Variable 'S8r1' not found")
  test_val <- sum(as.numeric(data[["S8r1"]]) == 100, na.rm = TRUE)

  list(success = TRUE, tableId = "s8_S8r1_distribution", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "s8_S8r1_distribution", error = conditionMessage(e))
})

print(paste("Validated:", "s8_S8r1_distribution", "-", if(validation_results[["s8_S8r1_distribution"]]$success) "PASS" else paste("FAIL:", validation_results[["s8_S8r1_distribution"]]$error)))

# -----------------------------------------------------------------------------
# Table: s9 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s9"]] <- tryCatch({

  # Row 1: S9 == 1,2
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: S9 == 1
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 1, na.rm = TRUE)
  # Row 3: S9 == 2
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 2, na.rm = TRUE)
  # Row 4: S9 == 3
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 3, na.rm = TRUE)
  # Row 5: S9 == 4,5,6,7
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) %in% c(4, 5, 6, 7), na.rm = TRUE)
  # Row 6: S9 == 4
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 4, na.rm = TRUE)
  # Row 7: S9 == 5
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 5, na.rm = TRUE)
  # Row 8: S9 == 6
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 6, na.rm = TRUE)
  # Row 9: S9 == 7
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 7, na.rm = TRUE)
  # Row 10: S9 == 8
  if (!("S9" %in% names(data))) stop("Variable 'S9' not found")
  test_val <- sum(as.numeric(data[["S9"]]) == 8, na.rm = TRUE)

  list(success = TRUE, tableId = "s9", rowCount = 10)

}, error = function(e) {
  list(success = FALSE, tableId = "s9", error = conditionMessage(e))
})

print(paste("Validated:", "s9", "-", if(validation_results[["s9"]]$success) "PASS" else paste("FAIL:", validation_results[["s9"]]$error)))

# -----------------------------------------------------------------------------
# Table: s10 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s10"]] <- tryCatch({

  # Row 1: S10 (mean)
  if (!("S10" %in% names(data))) stop("Variable 'S10' not found")
  test_vals <- data[["S10"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S10' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s10", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "s10", error = conditionMessage(e))
})

print(paste("Validated:", "s10", "-", if(validation_results[["s10"]]$success) "PASS" else paste("FAIL:", validation_results[["s10"]]$error)))

# -----------------------------------------------------------------------------
# Table: s10_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["s10_binned"]] <- tryCatch({

  # Row 1: S10 == 56-249
  if (!("S10" %in% names(data))) stop("Variable 'S10' not found")
  test_val <- sum(as.numeric(data[["S10"]]) >= 56 & as.numeric(data[["S10"]]) <= 249, na.rm = TRUE)
  # Row 2: S10 == 250-349
  if (!("S10" %in% names(data))) stop("Variable 'S10' not found")
  test_val <- sum(as.numeric(data[["S10"]]) >= 250 & as.numeric(data[["S10"]]) <= 349, na.rm = TRUE)
  # Row 3: S10 == 350-449
  if (!("S10" %in% names(data))) stop("Variable 'S10' not found")
  test_val <- sum(as.numeric(data[["S10"]]) >= 350 & as.numeric(data[["S10"]]) <= 449, na.rm = TRUE)
  # Row 4: S10 == 450-999
  if (!("S10" %in% names(data))) stop("Variable 'S10' not found")
  test_val <- sum(as.numeric(data[["S10"]]) >= 450 & as.numeric(data[["S10"]]) <= 999, na.rm = TRUE)

  list(success = TRUE, tableId = "s10_binned", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s10_binned", error = conditionMessage(e))
})

print(paste("Validated:", "s10_binned", "-", if(validation_results[["s10_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["s10_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: s11 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s11"]] <- tryCatch({

  # Row 1: S11 (mean)
  if (!("S11" %in% names(data))) stop("Variable 'S11' not found")
  test_vals <- data[["S11"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S11' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s11", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "s11", error = conditionMessage(e))
})

print(paste("Validated:", "s11", "-", if(validation_results[["s11"]]$success) "PASS" else paste("FAIL:", validation_results[["s11"]]$error)))

# -----------------------------------------------------------------------------
# Table: s11_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["s11_binned"]] <- tryCatch({

  # Row 1: S11 == 20-74
  if (!("S11" %in% names(data))) stop("Variable 'S11' not found")
  test_val <- sum(as.numeric(data[["S11"]]) >= 20 & as.numeric(data[["S11"]]) <= 74, na.rm = TRUE)
  # Row 2: S11 == 75-124
  if (!("S11" %in% names(data))) stop("Variable 'S11' not found")
  test_val <- sum(as.numeric(data[["S11"]]) >= 75 & as.numeric(data[["S11"]]) <= 124, na.rm = TRUE)
  # Row 3: S11 == 125-213
  if (!("S11" %in% names(data))) stop("Variable 'S11' not found")
  test_val <- sum(as.numeric(data[["S11"]]) >= 125 & as.numeric(data[["S11"]]) <= 213, na.rm = TRUE)
  # Row 4: S11 == 214-900
  if (!("S11" %in% names(data))) stop("Variable 'S11' not found")
  test_val <- sum(as.numeric(data[["S11"]]) >= 214 & as.numeric(data[["S11"]]) <= 900, na.rm = TRUE)

  list(success = TRUE, tableId = "s11_binned", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s11_binned", error = conditionMessage(e))
})

print(paste("Validated:", "s11_binned", "-", if(validation_results[["s11_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["s11_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: s12 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s12"]] <- tryCatch({

  # Row 1: S12r1 (mean)
  if (!("S12r1" %in% names(data))) stop("Variable 'S12r1' not found")
  test_vals <- data[["S12r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S12r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: S12r2 (mean)
  if (!("S12r2" %in% names(data))) stop("Variable 'S12r2' not found")
  test_vals <- data[["S12r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S12r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: S12r3 (mean)
  if (!("S12r3" %in% names(data))) stop("Variable 'S12r3' not found")
  test_vals <- data[["S12r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S12r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: S12r4 (mean)
  if (!("S12r4" %in% names(data))) stop("Variable 'S12r4' not found")
  test_vals <- data[["S12r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S12r4' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s12", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s12", error = conditionMessage(e))
})

print(paste("Validated:", "s12", "-", if(validation_results[["s12"]]$success) "PASS" else paste("FAIL:", validation_results[["s12"]]$error)))

# -----------------------------------------------------------------------------
# Table: s12_total (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s12_total"]] <- tryCatch({

  # Row 1: NET - Total patients with an event (sum across the four time windows) (sum of component means)
  if (!("S12r1" %in% names(data))) stop("NET component variable 'S12r1' not found")
  test_vals <- data[["S12r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S12r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S12r2" %in% names(data))) stop("NET component variable 'S12r2' not found")
  test_vals <- data[["S12r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S12r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S12r3" %in% names(data))) stop("NET component variable 'S12r3' not found")
  test_vals <- data[["S12r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S12r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S12r4" %in% names(data))) stop("NET component variable 'S12r4' not found")
  test_vals <- data[["S12r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S12r4' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s12_total", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "s12_total", error = conditionMessage(e))
})

print(paste("Validated:", "s12_total", "-", if(validation_results[["s12_total"]]$success) "PASS" else paste("FAIL:", validation_results[["s12_total"]]$error)))

# -----------------------------------------------------------------------------
# Table: s12_total_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["s12_total_binned"]] <- tryCatch({

  # Row 1: NET - None (0 patients)
  if (!("S12r1" %in% names(data))) stop("NET component variable 'S12r1' not found")
  if (!("S12r2" %in% names(data))) stop("NET component variable 'S12r2' not found")
  if (!("S12r3" %in% names(data))) stop("NET component variable 'S12r3' not found")
  if (!("S12r4" %in% names(data))) stop("NET component variable 'S12r4' not found")
  # Row 2: NET - Low (1-20 patients)
  if (!("S12r1" %in% names(data))) stop("NET component variable 'S12r1' not found")
  if (!("S12r2" %in% names(data))) stop("NET component variable 'S12r2' not found")
  if (!("S12r3" %in% names(data))) stop("NET component variable 'S12r3' not found")
  if (!("S12r4" %in% names(data))) stop("NET component variable 'S12r4' not found")
  # Row 3: NET - Moderate (21-70 patients)
  if (!("S12r1" %in% names(data))) stop("NET component variable 'S12r1' not found")
  if (!("S12r2" %in% names(data))) stop("NET component variable 'S12r2' not found")
  if (!("S12r3" %in% names(data))) stop("NET component variable 'S12r3' not found")
  if (!("S12r4" %in% names(data))) stop("NET component variable 'S12r4' not found")
  # Row 4: NET - High (71-500 patients)
  if (!("S12r1" %in% names(data))) stop("NET component variable 'S12r1' not found")
  if (!("S12r2" %in% names(data))) stop("NET component variable 'S12r2' not found")
  if (!("S12r3" %in% names(data))) stop("NET component variable 'S12r3' not found")
  if (!("S12r4" %in% names(data))) stop("NET component variable 'S12r4' not found")

  list(success = TRUE, tableId = "s12_total_binned", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s12_total_binned", error = conditionMessage(e))
})

print(paste("Validated:", "s12_total_binned", "-", if(validation_results[["s12_total_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["s12_total_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: a1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a1"]] <- tryCatch({

  # Row 1: Category header - Leqvio (inclisiran) (skip validation)
  # Row 2: A1r1 == 1
  if (!("A1r1" %in% names(data))) stop("Variable 'A1r1' not found")
  test_val <- sum(as.numeric(data[["A1r1"]]) == 1, na.rm = TRUE)
  # Row 3: A1r1 == 2
  if (!("A1r1" %in% names(data))) stop("Variable 'A1r1' not found")
  test_val <- sum(as.numeric(data[["A1r1"]]) == 2, na.rm = TRUE)
  # Row 4: Category header - Praluent (alirocumab) (skip validation)
  # Row 5: A1r2 == 1
  if (!("A1r2" %in% names(data))) stop("Variable 'A1r2' not found")
  test_val <- sum(as.numeric(data[["A1r2"]]) == 1, na.rm = TRUE)
  # Row 6: A1r2 == 2
  if (!("A1r2" %in% names(data))) stop("Variable 'A1r2' not found")
  test_val <- sum(as.numeric(data[["A1r2"]]) == 2, na.rm = TRUE)
  # Row 7: Category header - Repatha (evolocumab) (skip validation)
  # Row 8: A1r3 == 1
  if (!("A1r3" %in% names(data))) stop("Variable 'A1r3' not found")
  test_val <- sum(as.numeric(data[["A1r3"]]) == 1, na.rm = TRUE)
  # Row 9: A1r3 == 2
  if (!("A1r3" %in% names(data))) stop("Variable 'A1r3' not found")
  test_val <- sum(as.numeric(data[["A1r3"]]) == 2, na.rm = TRUE)
  # Row 10: Category header - Nexletol (bempedoic acid) / Nexlizet (bempedoic acid + ezetimibe) (skip validation)
  # Row 11: A1r4 == 1
  if (!("A1r4" %in% names(data))) stop("Variable 'A1r4' not found")
  test_val <- sum(as.numeric(data[["A1r4"]]) == 1, na.rm = TRUE)
  # Row 12: A1r4 == 2
  if (!("A1r4" %in% names(data))) stop("Variable 'A1r4' not found")
  test_val <- sum(as.numeric(data[["A1r4"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "a1", rowCount = 12)

}, error = function(e) {
  list(success = FALSE, tableId = "a1", error = conditionMessage(e))
})

print(paste("Validated:", "a1", "-", if(validation_results[["a1"]]$success) "PASS" else paste("FAIL:", validation_results[["a1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a2a (frequency)
# -----------------------------------------------------------------------------

validation_results[["a2a"]] <- tryCatch({

  # Row 1: A2a == 1
  if (!("A2a" %in% names(data))) stop("Variable 'A2a' not found")
  test_val <- sum(as.numeric(data[["A2a"]]) == 1, na.rm = TRUE)
  # Row 2: A2a == 2
  if (!("A2a" %in% names(data))) stop("Variable 'A2a' not found")
  test_val <- sum(as.numeric(data[["A2a"]]) == 2, na.rm = TRUE)
  # Row 3: A2a == 3
  if (!("A2a" %in% names(data))) stop("Variable 'A2a' not found")
  test_val <- sum(as.numeric(data[["A2a"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "a2a", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "a2a", error = conditionMessage(e))
})

print(paste("Validated:", "a2a", "-", if(validation_results[["a2a"]]$success) "PASS" else paste("FAIL:", validation_results[["a2a"]]$error)))

# -----------------------------------------------------------------------------
# Table: a2b (frequency)
# -----------------------------------------------------------------------------

validation_results[["a2b"]] <- tryCatch({

  # Row 1: A2b == 1,2
  if (!("A2b" %in% names(data))) stop("Variable 'A2b' not found")
  test_val <- sum(as.numeric(data[["A2b"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A2b == 1
  if (!("A2b" %in% names(data))) stop("Variable 'A2b' not found")
  test_val <- sum(as.numeric(data[["A2b"]]) == 1, na.rm = TRUE)
  # Row 3: A2b == 2
  if (!("A2b" %in% names(data))) stop("Variable 'A2b' not found")
  test_val <- sum(as.numeric(data[["A2b"]]) == 2, na.rm = TRUE)
  # Row 4: A2b == 3
  if (!("A2b" %in% names(data))) stop("Variable 'A2b' not found")
  test_val <- sum(as.numeric(data[["A2b"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "a2b", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "a2b", error = conditionMessage(e))
})

print(paste("Validated:", "a2b", "-", if(validation_results[["a2b"]]$success) "PASS" else paste("FAIL:", validation_results[["a2b"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3"]] <- tryCatch({

  # Row 1: A3r1 (mean)
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_vals <- data[["A3r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3r2 (mean)
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_vals <- data[["A3r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: A3r3 (mean)
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_vals <- data[["A3r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: A3r4 (mean)
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_vals <- data[["A3r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r4' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: A3r5 (mean)
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_vals <- data[["A3r5"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r5' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: A3r6 (mean)
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_vals <- data[["A3r6"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r6' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: A3r7 (mean)
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_vals <- data[["A3r7"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3r7' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a3", error = conditionMessage(e))
})

print(paste("Validated:", "a3", "-", if(validation_results[["a3"]]$success) "PASS" else paste("FAIL:", validation_results[["a3"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r1_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r1_bins"]] <- tryCatch({

  # Row 1: A3r1 == 0
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_val <- sum(as.numeric(data[["A3r1"]]) == 0, na.rm = TRUE)
  # Row 2: A3r1 == 1-25
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_val <- sum(as.numeric(data[["A3r1"]]) >= 1 & as.numeric(data[["A3r1"]]) <= 25, na.rm = TRUE)
  # Row 3: A3r1 == 26-50
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_val <- sum(as.numeric(data[["A3r1"]]) >= 26 & as.numeric(data[["A3r1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3r1 == 51-75
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_val <- sum(as.numeric(data[["A3r1"]]) >= 51 & as.numeric(data[["A3r1"]]) <= 75, na.rm = TRUE)
  # Row 5: A3r1 == 76-100
  if (!("A3r1" %in% names(data))) stop("Variable 'A3r1' not found")
  test_val <- sum(as.numeric(data[["A3r1"]]) >= 76 & as.numeric(data[["A3r1"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r1_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r1_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r1_bins", "-", if(validation_results[["a3_A3r1_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r1_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r2_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r2_bins"]] <- tryCatch({

  # Row 1: A3r2 == 0
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_val <- sum(as.numeric(data[["A3r2"]]) == 0, na.rm = TRUE)
  # Row 2: A3r2 == 1-11
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_val <- sum(as.numeric(data[["A3r2"]]) >= 1 & as.numeric(data[["A3r2"]]) <= 11, na.rm = TRUE)
  # Row 3: A3r2 == 12-22
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_val <- sum(as.numeric(data[["A3r2"]]) >= 12 & as.numeric(data[["A3r2"]]) <= 22, na.rm = TRUE)
  # Row 4: A3r2 == 23-33
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_val <- sum(as.numeric(data[["A3r2"]]) >= 23 & as.numeric(data[["A3r2"]]) <= 33, na.rm = TRUE)
  # Row 5: A3r2 == 34-45
  if (!("A3r2" %in% names(data))) stop("Variable 'A3r2' not found")
  test_val <- sum(as.numeric(data[["A3r2"]]) >= 34 & as.numeric(data[["A3r2"]]) <= 45, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r2_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r2_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r2_bins", "-", if(validation_results[["a3_A3r2_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r2_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r3_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r3_bins"]] <- tryCatch({

  # Row 1: A3r3 == 0
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_val <- sum(as.numeric(data[["A3r3"]]) == 0, na.rm = TRUE)
  # Row 2: A3r3 == 1-25
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_val <- sum(as.numeric(data[["A3r3"]]) >= 1 & as.numeric(data[["A3r3"]]) <= 25, na.rm = TRUE)
  # Row 3: A3r3 == 26-50
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_val <- sum(as.numeric(data[["A3r3"]]) >= 26 & as.numeric(data[["A3r3"]]) <= 50, na.rm = TRUE)
  # Row 4: A3r3 == 51-75
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_val <- sum(as.numeric(data[["A3r3"]]) >= 51 & as.numeric(data[["A3r3"]]) <= 75, na.rm = TRUE)
  # Row 5: A3r3 == 76-100
  if (!("A3r3" %in% names(data))) stop("Variable 'A3r3' not found")
  test_val <- sum(as.numeric(data[["A3r3"]]) >= 76 & as.numeric(data[["A3r3"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r3_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r3_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r3_bins", "-", if(validation_results[["a3_A3r3_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r3_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r4_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r4_bins"]] <- tryCatch({

  # Row 1: A3r4 == 0
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_val <- sum(as.numeric(data[["A3r4"]]) == 0, na.rm = TRUE)
  # Row 2: A3r4 == 1-15
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_val <- sum(as.numeric(data[["A3r4"]]) >= 1 & as.numeric(data[["A3r4"]]) <= 15, na.rm = TRUE)
  # Row 3: A3r4 == 16-30
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_val <- sum(as.numeric(data[["A3r4"]]) >= 16 & as.numeric(data[["A3r4"]]) <= 30, na.rm = TRUE)
  # Row 4: A3r4 == 31-45
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_val <- sum(as.numeric(data[["A3r4"]]) >= 31 & as.numeric(data[["A3r4"]]) <= 45, na.rm = TRUE)
  # Row 5: A3r4 == 46-60
  if (!("A3r4" %in% names(data))) stop("Variable 'A3r4' not found")
  test_val <- sum(as.numeric(data[["A3r4"]]) >= 46 & as.numeric(data[["A3r4"]]) <= 60, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r4_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r4_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r4_bins", "-", if(validation_results[["a3_A3r4_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r4_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r5_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r5_bins"]] <- tryCatch({

  # Row 1: A3r5 == 0
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_val <- sum(as.numeric(data[["A3r5"]]) == 0, na.rm = TRUE)
  # Row 2: A3r5 == 1-23
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_val <- sum(as.numeric(data[["A3r5"]]) >= 1 & as.numeric(data[["A3r5"]]) <= 23, na.rm = TRUE)
  # Row 3: A3r5 == 24-47
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_val <- sum(as.numeric(data[["A3r5"]]) >= 24 & as.numeric(data[["A3r5"]]) <= 47, na.rm = TRUE)
  # Row 4: A3r5 == 48-71
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_val <- sum(as.numeric(data[["A3r5"]]) >= 48 & as.numeric(data[["A3r5"]]) <= 71, na.rm = TRUE)
  # Row 5: A3r5 == 72-95
  if (!("A3r5" %in% names(data))) stop("Variable 'A3r5' not found")
  test_val <- sum(as.numeric(data[["A3r5"]]) >= 72 & as.numeric(data[["A3r5"]]) <= 95, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r5_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r5_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r5_bins", "-", if(validation_results[["a3_A3r5_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r5_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r6_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r6_bins"]] <- tryCatch({

  # Row 1: A3r6 == 0
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_val <- sum(as.numeric(data[["A3r6"]]) == 0, na.rm = TRUE)
  # Row 2: A3r6 == 1-12
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_val <- sum(as.numeric(data[["A3r6"]]) >= 1 & as.numeric(data[["A3r6"]]) <= 12, na.rm = TRUE)
  # Row 3: A3r6 == 13-25
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_val <- sum(as.numeric(data[["A3r6"]]) >= 13 & as.numeric(data[["A3r6"]]) <= 25, na.rm = TRUE)
  # Row 4: A3r6 == 26-37
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_val <- sum(as.numeric(data[["A3r6"]]) >= 26 & as.numeric(data[["A3r6"]]) <= 37, na.rm = TRUE)
  # Row 5: A3r6 == 38-50
  if (!("A3r6" %in% names(data))) stop("Variable 'A3r6' not found")
  test_val <- sum(as.numeric(data[["A3r6"]]) >= 38 & as.numeric(data[["A3r6"]]) <= 50, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r6_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r6_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r6_bins", "-", if(validation_results[["a3_A3r6_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r6_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3_A3r7_bins (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3_A3r7_bins"]] <- tryCatch({

  # Row 1: A3r7 == 0
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_val <- sum(as.numeric(data[["A3r7"]]) == 0, na.rm = TRUE)
  # Row 2: A3r7 == 1-5
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_val <- sum(as.numeric(data[["A3r7"]]) >= 1 & as.numeric(data[["A3r7"]]) <= 5, na.rm = TRUE)
  # Row 3: A3r7 == 6-10
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_val <- sum(as.numeric(data[["A3r7"]]) >= 6 & as.numeric(data[["A3r7"]]) <= 10, na.rm = TRUE)
  # Row 4: A3r7 == 11-15
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_val <- sum(as.numeric(data[["A3r7"]]) >= 11 & as.numeric(data[["A3r7"]]) <= 15, na.rm = TRUE)
  # Row 5: A3r7 == 16-20
  if (!("A3r7" %in% names(data))) stop("Variable 'A3r7' not found")
  test_val <- sum(as.numeric(data[["A3r7"]]) >= 16 & as.numeric(data[["A3r7"]]) <= 20, na.rm = TRUE)

  list(success = TRUE, tableId = "a3_A3r7_bins", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a3_A3r7_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a3_A3r7_bins", "-", if(validation_results[["a3_A3r7_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a3_A3r7_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3a_leqvio (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3a_leqvio"]] <- tryCatch({

  # Row 1: A3ar1c1 (mean)
  if (!("A3ar1c1" %in% names(data))) stop("Variable 'A3ar1c1' not found")
  test_vals <- data[["A3ar1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3ar1c2 (mean)
  if (!("A3ar1c2" %in% names(data))) stop("Variable 'A3ar1c2' not found")
  test_vals <- data[["A3ar1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3a_leqvio", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3a_leqvio", error = conditionMessage(e))
})

print(paste("Validated:", "a3a_leqvio", "-", if(validation_results[["a3a_leqvio"]]$success) "PASS" else paste("FAIL:", validation_results[["a3a_leqvio"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3a_praluent (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3a_praluent"]] <- tryCatch({

  # Row 1: A3ar2c1 (mean)
  if (!("A3ar2c1" %in% names(data))) stop("Variable 'A3ar2c1' not found")
  test_vals <- data[["A3ar2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3ar2c2 (mean)
  if (!("A3ar2c2" %in% names(data))) stop("Variable 'A3ar2c2' not found")
  test_vals <- data[["A3ar2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3a_praluent", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3a_praluent", error = conditionMessage(e))
})

print(paste("Validated:", "a3a_praluent", "-", if(validation_results[["a3a_praluent"]]$success) "PASS" else paste("FAIL:", validation_results[["a3a_praluent"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3a_repatha (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3a_repatha"]] <- tryCatch({

  # Row 1: A3ar3c1 (mean)
  if (!("A3ar3c1" %in% names(data))) stop("Variable 'A3ar3c1' not found")
  test_vals <- data[["A3ar3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3ar3c2 (mean)
  if (!("A3ar3c2" %in% names(data))) stop("Variable 'A3ar3c2' not found")
  test_vals <- data[["A3ar3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3a_repatha", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3a_repatha", error = conditionMessage(e))
})

print(paste("Validated:", "a3a_repatha", "-", if(validation_results[["a3a_repatha"]]$success) "PASS" else paste("FAIL:", validation_results[["a3a_repatha"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3a_zetia (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3a_zetia"]] <- tryCatch({

  # Row 1: A3ar4c1 (mean)
  if (!("A3ar4c1" %in% names(data))) stop("Variable 'A3ar4c1' not found")
  test_vals <- data[["A3ar4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3ar4c2 (mean)
  if (!("A3ar4c2" %in% names(data))) stop("Variable 'A3ar4c2' not found")
  test_vals <- data[["A3ar4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3a_zetia", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3a_zetia", error = conditionMessage(e))
})

print(paste("Validated:", "a3a_zetia", "-", if(validation_results[["a3a_zetia"]]$success) "PASS" else paste("FAIL:", validation_results[["a3a_zetia"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3a_nexletol (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3a_nexletol"]] <- tryCatch({

  # Row 1: A3ar5c1 (mean)
  if (!("A3ar5c1" %in% names(data))) stop("Variable 'A3ar5c1' not found")
  test_vals <- data[["A3ar5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3ar5c2 (mean)
  if (!("A3ar5c2" %in% names(data))) stop("Variable 'A3ar5c2' not found")
  test_vals <- data[["A3ar5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3ar5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3a_nexletol", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3a_nexletol", error = conditionMessage(e))
})

print(paste("Validated:", "a3a_nexletol", "-", if(validation_results[["a3a_nexletol"]]$success) "PASS" else paste("FAIL:", validation_results[["a3a_nexletol"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_leqvio (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3b_leqvio"]] <- tryCatch({

  # Row 1: A3br1c1 (mean)
  if (!("A3br1c1" %in% names(data))) stop("Variable 'A3br1c1' not found")
  test_vals <- data[["A3br1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3br1c2 (mean)
  if (!("A3br1c2" %in% names(data))) stop("Variable 'A3br1c2' not found")
  test_vals <- data[["A3br1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3b_leqvio", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_leqvio", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_leqvio", "-", if(validation_results[["a3b_leqvio"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_leqvio"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_praluent (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3b_praluent"]] <- tryCatch({

  # Row 1: A3br2c1 (mean)
  if (!("A3br2c1" %in% names(data))) stop("Variable 'A3br2c1' not found")
  test_vals <- data[["A3br2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3br2c2 (mean)
  if (!("A3br2c2" %in% names(data))) stop("Variable 'A3br2c2' not found")
  test_vals <- data[["A3br2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3b_praluent", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_praluent", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_praluent", "-", if(validation_results[["a3b_praluent"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_praluent"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_repatha (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3b_repatha"]] <- tryCatch({

  # Row 1: A3br3c1 (mean)
  if (!("A3br3c1" %in% names(data))) stop("Variable 'A3br3c1' not found")
  test_vals <- data[["A3br3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3br3c2 (mean)
  if (!("A3br3c2" %in% names(data))) stop("Variable 'A3br3c2' not found")
  test_vals <- data[["A3br3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3b_repatha", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_repatha", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_repatha", "-", if(validation_results[["a3b_repatha"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_repatha"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_zetia (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3b_zetia"]] <- tryCatch({

  # Row 1: A3br4c1 (mean)
  if (!("A3br4c1" %in% names(data))) stop("Variable 'A3br4c1' not found")
  test_vals <- data[["A3br4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3br4c2 (mean)
  if (!("A3br4c2" %in% names(data))) stop("Variable 'A3br4c2' not found")
  test_vals <- data[["A3br4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3b_zetia", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_zetia", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_zetia", "-", if(validation_results[["a3b_zetia"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_zetia"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_nexletol (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a3b_nexletol"]] <- tryCatch({

  # Row 1: A3br5c1 (mean)
  if (!("A3br5c1" %in% names(data))) stop("Variable 'A3br5c1' not found")
  test_vals <- data[["A3br5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A3br5c2 (mean)
  if (!("A3br5c2" %in% names(data))) stop("Variable 'A3br5c2' not found")
  test_vals <- data[["A3br5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A3br5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a3b_nexletol", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_nexletol", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_nexletol", "-", if(validation_results[["a3b_nexletol"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_nexletol"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_leqvio_dist (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3b_leqvio_dist"]] <- tryCatch({

  # Row 1: A3br1c1 == 0
  if (!("A3br1c1" %in% names(data))) stop("Variable 'A3br1c1' not found")
  test_val <- sum(as.numeric(data[["A3br1c1"]]) == 0, na.rm = TRUE)
  # Row 2: A3br1c1 == 1-15
  if (!("A3br1c1" %in% names(data))) stop("Variable 'A3br1c1' not found")
  test_val <- sum(as.numeric(data[["A3br1c1"]]) >= 1 & as.numeric(data[["A3br1c1"]]) <= 15, na.rm = TRUE)
  # Row 3: A3br1c1 == 16-50
  if (!("A3br1c1" %in% names(data))) stop("Variable 'A3br1c1' not found")
  test_val <- sum(as.numeric(data[["A3br1c1"]]) >= 16 & as.numeric(data[["A3br1c1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3br1c1 == 51-100
  if (!("A3br1c1" %in% names(data))) stop("Variable 'A3br1c1' not found")
  test_val <- sum(as.numeric(data[["A3br1c1"]]) >= 51 & as.numeric(data[["A3br1c1"]]) <= 100, na.rm = TRUE)
  # Row 5: A3br1c2 == 0
  if (!("A3br1c2" %in% names(data))) stop("Variable 'A3br1c2' not found")
  test_val <- sum(as.numeric(data[["A3br1c2"]]) == 0, na.rm = TRUE)
  # Row 6: A3br1c2 == 1-15
  if (!("A3br1c2" %in% names(data))) stop("Variable 'A3br1c2' not found")
  test_val <- sum(as.numeric(data[["A3br1c2"]]) >= 1 & as.numeric(data[["A3br1c2"]]) <= 15, na.rm = TRUE)
  # Row 7: A3br1c2 == 16-50
  if (!("A3br1c2" %in% names(data))) stop("Variable 'A3br1c2' not found")
  test_val <- sum(as.numeric(data[["A3br1c2"]]) >= 16 & as.numeric(data[["A3br1c2"]]) <= 50, na.rm = TRUE)
  # Row 8: A3br1c2 == 51-100
  if (!("A3br1c2" %in% names(data))) stop("Variable 'A3br1c2' not found")
  test_val <- sum(as.numeric(data[["A3br1c2"]]) >= 51 & as.numeric(data[["A3br1c2"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3b_leqvio_dist", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_leqvio_dist", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_leqvio_dist", "-", if(validation_results[["a3b_leqvio_dist"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_leqvio_dist"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_nexletol_dist (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3b_nexletol_dist"]] <- tryCatch({

  # Row 1: A3br5c1 == 0
  if (!("A3br5c1" %in% names(data))) stop("Variable 'A3br5c1' not found")
  test_val <- sum(as.numeric(data[["A3br5c1"]]) == 0, na.rm = TRUE)
  # Row 2: A3br5c1 == 1-15
  if (!("A3br5c1" %in% names(data))) stop("Variable 'A3br5c1' not found")
  test_val <- sum(as.numeric(data[["A3br5c1"]]) >= 1 & as.numeric(data[["A3br5c1"]]) <= 15, na.rm = TRUE)
  # Row 3: A3br5c1 == 16-50
  if (!("A3br5c1" %in% names(data))) stop("Variable 'A3br5c1' not found")
  test_val <- sum(as.numeric(data[["A3br5c1"]]) >= 16 & as.numeric(data[["A3br5c1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3br5c1 == 51-100
  if (!("A3br5c1" %in% names(data))) stop("Variable 'A3br5c1' not found")
  test_val <- sum(as.numeric(data[["A3br5c1"]]) >= 51 & as.numeric(data[["A3br5c1"]]) <= 100, na.rm = TRUE)
  # Row 5: A3br5c2 == 0
  if (!("A3br5c2" %in% names(data))) stop("Variable 'A3br5c2' not found")
  test_val <- sum(as.numeric(data[["A3br5c2"]]) == 0, na.rm = TRUE)
  # Row 6: A3br5c2 == 1-15
  if (!("A3br5c2" %in% names(data))) stop("Variable 'A3br5c2' not found")
  test_val <- sum(as.numeric(data[["A3br5c2"]]) >= 1 & as.numeric(data[["A3br5c2"]]) <= 15, na.rm = TRUE)
  # Row 7: A3br5c2 == 16-50
  if (!("A3br5c2" %in% names(data))) stop("Variable 'A3br5c2' not found")
  test_val <- sum(as.numeric(data[["A3br5c2"]]) >= 16 & as.numeric(data[["A3br5c2"]]) <= 50, na.rm = TRUE)
  # Row 8: A3br5c2 == 51-100
  if (!("A3br5c2" %in% names(data))) stop("Variable 'A3br5c2' not found")
  test_val <- sum(as.numeric(data[["A3br5c2"]]) >= 51 & as.numeric(data[["A3br5c2"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3b_nexletol_dist", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_nexletol_dist", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_nexletol_dist", "-", if(validation_results[["a3b_nexletol_dist"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_nexletol_dist"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_praluent_dist (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3b_praluent_dist"]] <- tryCatch({

  # Row 1: A3br2c1 == 0
  if (!("A3br2c1" %in% names(data))) stop("Variable 'A3br2c1' not found")
  test_val <- sum(as.numeric(data[["A3br2c1"]]) == 0, na.rm = TRUE)
  # Row 2: A3br2c1 == 1-15
  if (!("A3br2c1" %in% names(data))) stop("Variable 'A3br2c1' not found")
  test_val <- sum(as.numeric(data[["A3br2c1"]]) >= 1 & as.numeric(data[["A3br2c1"]]) <= 15, na.rm = TRUE)
  # Row 3: A3br2c1 == 16-50
  if (!("A3br2c1" %in% names(data))) stop("Variable 'A3br2c1' not found")
  test_val <- sum(as.numeric(data[["A3br2c1"]]) >= 16 & as.numeric(data[["A3br2c1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3br2c1 == 51-100
  if (!("A3br2c1" %in% names(data))) stop("Variable 'A3br2c1' not found")
  test_val <- sum(as.numeric(data[["A3br2c1"]]) >= 51 & as.numeric(data[["A3br2c1"]]) <= 100, na.rm = TRUE)
  # Row 5: A3br2c2 == 0
  if (!("A3br2c2" %in% names(data))) stop("Variable 'A3br2c2' not found")
  test_val <- sum(as.numeric(data[["A3br2c2"]]) == 0, na.rm = TRUE)
  # Row 6: A3br2c2 == 1-15
  if (!("A3br2c2" %in% names(data))) stop("Variable 'A3br2c2' not found")
  test_val <- sum(as.numeric(data[["A3br2c2"]]) >= 1 & as.numeric(data[["A3br2c2"]]) <= 15, na.rm = TRUE)
  # Row 7: A3br2c2 == 16-50
  if (!("A3br2c2" %in% names(data))) stop("Variable 'A3br2c2' not found")
  test_val <- sum(as.numeric(data[["A3br2c2"]]) >= 16 & as.numeric(data[["A3br2c2"]]) <= 50, na.rm = TRUE)
  # Row 8: A3br2c2 == 51-100
  if (!("A3br2c2" %in% names(data))) stop("Variable 'A3br2c2' not found")
  test_val <- sum(as.numeric(data[["A3br2c2"]]) >= 51 & as.numeric(data[["A3br2c2"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3b_praluent_dist", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_praluent_dist", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_praluent_dist", "-", if(validation_results[["a3b_praluent_dist"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_praluent_dist"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_repatha_dist (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3b_repatha_dist"]] <- tryCatch({

  # Row 1: A3br3c1 == 0
  if (!("A3br3c1" %in% names(data))) stop("Variable 'A3br3c1' not found")
  test_val <- sum(as.numeric(data[["A3br3c1"]]) == 0, na.rm = TRUE)
  # Row 2: A3br3c1 == 1-15
  if (!("A3br3c1" %in% names(data))) stop("Variable 'A3br3c1' not found")
  test_val <- sum(as.numeric(data[["A3br3c1"]]) >= 1 & as.numeric(data[["A3br3c1"]]) <= 15, na.rm = TRUE)
  # Row 3: A3br3c1 == 16-50
  if (!("A3br3c1" %in% names(data))) stop("Variable 'A3br3c1' not found")
  test_val <- sum(as.numeric(data[["A3br3c1"]]) >= 16 & as.numeric(data[["A3br3c1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3br3c1 == 51-100
  if (!("A3br3c1" %in% names(data))) stop("Variable 'A3br3c1' not found")
  test_val <- sum(as.numeric(data[["A3br3c1"]]) >= 51 & as.numeric(data[["A3br3c1"]]) <= 100, na.rm = TRUE)
  # Row 5: A3br3c2 == 0
  if (!("A3br3c2" %in% names(data))) stop("Variable 'A3br3c2' not found")
  test_val <- sum(as.numeric(data[["A3br3c2"]]) == 0, na.rm = TRUE)
  # Row 6: A3br3c2 == 1-15
  if (!("A3br3c2" %in% names(data))) stop("Variable 'A3br3c2' not found")
  test_val <- sum(as.numeric(data[["A3br3c2"]]) >= 1 & as.numeric(data[["A3br3c2"]]) <= 15, na.rm = TRUE)
  # Row 7: A3br3c2 == 16-50
  if (!("A3br3c2" %in% names(data))) stop("Variable 'A3br3c2' not found")
  test_val <- sum(as.numeric(data[["A3br3c2"]]) >= 16 & as.numeric(data[["A3br3c2"]]) <= 50, na.rm = TRUE)
  # Row 8: A3br3c2 == 51-100
  if (!("A3br3c2" %in% names(data))) stop("Variable 'A3br3c2' not found")
  test_val <- sum(as.numeric(data[["A3br3c2"]]) >= 51 & as.numeric(data[["A3br3c2"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3b_repatha_dist", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_repatha_dist", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_repatha_dist", "-", if(validation_results[["a3b_repatha_dist"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_repatha_dist"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3b_zetia_dist (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3b_zetia_dist"]] <- tryCatch({

  # Row 1: A3br4c1 == 0
  if (!("A3br4c1" %in% names(data))) stop("Variable 'A3br4c1' not found")
  test_val <- sum(as.numeric(data[["A3br4c1"]]) == 0, na.rm = TRUE)
  # Row 2: A3br4c1 == 1-15
  if (!("A3br4c1" %in% names(data))) stop("Variable 'A3br4c1' not found")
  test_val <- sum(as.numeric(data[["A3br4c1"]]) >= 1 & as.numeric(data[["A3br4c1"]]) <= 15, na.rm = TRUE)
  # Row 3: A3br4c1 == 16-50
  if (!("A3br4c1" %in% names(data))) stop("Variable 'A3br4c1' not found")
  test_val <- sum(as.numeric(data[["A3br4c1"]]) >= 16 & as.numeric(data[["A3br4c1"]]) <= 50, na.rm = TRUE)
  # Row 4: A3br4c1 == 51-100
  if (!("A3br4c1" %in% names(data))) stop("Variable 'A3br4c1' not found")
  test_val <- sum(as.numeric(data[["A3br4c1"]]) >= 51 & as.numeric(data[["A3br4c1"]]) <= 100, na.rm = TRUE)
  # Row 5: A3br4c2 == 0
  if (!("A3br4c2" %in% names(data))) stop("Variable 'A3br4c2' not found")
  test_val <- sum(as.numeric(data[["A3br4c2"]]) == 0, na.rm = TRUE)
  # Row 6: A3br4c2 == 1-15
  if (!("A3br4c2" %in% names(data))) stop("Variable 'A3br4c2' not found")
  test_val <- sum(as.numeric(data[["A3br4c2"]]) >= 1 & as.numeric(data[["A3br4c2"]]) <= 15, na.rm = TRUE)
  # Row 7: A3br4c2 == 16-50
  if (!("A3br4c2" %in% names(data))) stop("Variable 'A3br4c2' not found")
  test_val <- sum(as.numeric(data[["A3br4c2"]]) >= 16 & as.numeric(data[["A3br4c2"]]) <= 50, na.rm = TRUE)
  # Row 8: A3br4c2 == 51-100
  if (!("A3br4c2" %in% names(data))) stop("Variable 'A3br4c2' not found")
  test_val <- sum(as.numeric(data[["A3br4c2"]]) >= 51 & as.numeric(data[["A3br4c2"]]) <= 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a3b_zetia_dist", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a3b_zetia_dist", error = conditionMessage(e))
})

print(paste("Validated:", "a3b_zetia_dist", "-", if(validation_results[["a3b_zetia_dist"]]$success) "PASS" else paste("FAIL:", validation_results[["a3b_zetia_dist"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4"]] <- tryCatch({

  # Row 1: A4r1c1 (mean)
  if (!("A4r1c1" %in% names(data))) stop("Variable 'A4r1c1' not found")
  test_vals <- data[["A4r1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4r2c1 (mean)
  if (!("A4r2c1" %in% names(data))) stop("Variable 'A4r2c1' not found")
  test_vals <- data[["A4r2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: A4r3c1 (mean)
  if (!("A4r3c1" %in% names(data))) stop("Variable 'A4r3c1' not found")
  test_vals <- data[["A4r3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: A4r4c1 (mean)
  if (!("A4r4c1" %in% names(data))) stop("Variable 'A4r4c1' not found")
  test_vals <- data[["A4r4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: A4r5c1 (mean)
  if (!("A4r5c1" %in% names(data))) stop("Variable 'A4r5c1' not found")
  test_vals <- data[["A4r5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: A4r6c1 (mean)
  if (!("A4r6c1" %in% names(data))) stop("Variable 'A4r6c1' not found")
  test_vals <- data[["A4r6c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r6c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: A4r7c1 (mean)
  if (!("A4r7c1" %in% names(data))) stop("Variable 'A4r7c1' not found")
  test_vals <- data[["A4r7c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r7c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 8: A4r1c2 (mean)
  if (!("A4r1c2" %in% names(data))) stop("Variable 'A4r1c2' not found")
  test_vals <- data[["A4r1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 9: A4r2c2 (mean)
  if (!("A4r2c2" %in% names(data))) stop("Variable 'A4r2c2' not found")
  test_vals <- data[["A4r2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 10: A4r3c2 (mean)
  if (!("A4r3c2" %in% names(data))) stop("Variable 'A4r3c2' not found")
  test_vals <- data[["A4r3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 11: A4r4c2 (mean)
  if (!("A4r4c2" %in% names(data))) stop("Variable 'A4r4c2' not found")
  test_vals <- data[["A4r4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 12: A4r5c2 (mean)
  if (!("A4r5c2" %in% names(data))) stop("Variable 'A4r5c2' not found")
  test_vals <- data[["A4r5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 13: A4r6c2 (mean)
  if (!("A4r6c2" %in% names(data))) stop("Variable 'A4r6c2' not found")
  test_vals <- data[["A4r6c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r6c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 14: A4r7c2 (mean)
  if (!("A4r7c2" %in% names(data))) stop("Variable 'A4r7c2' not found")
  test_vals <- data[["A4r7c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r7c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4", rowCount = 14)

}, error = function(e) {
  list(success = FALSE, tableId = "a4", error = conditionMessage(e))
})

print(paste("Validated:", "a4", "-", if(validation_results[["a4"]]$success) "PASS" else paste("FAIL:", validation_results[["a4"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4_last100 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4_last100"]] <- tryCatch({

  # Row 1: A4r1c1 (mean)
  if (!("A4r1c1" %in% names(data))) stop("Variable 'A4r1c1' not found")
  test_vals <- data[["A4r1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4r2c1 (mean)
  if (!("A4r2c1" %in% names(data))) stop("Variable 'A4r2c1' not found")
  test_vals <- data[["A4r2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: A4r3c1 (mean)
  if (!("A4r3c1" %in% names(data))) stop("Variable 'A4r3c1' not found")
  test_vals <- data[["A4r3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: A4r4c1 (mean)
  if (!("A4r4c1" %in% names(data))) stop("Variable 'A4r4c1' not found")
  test_vals <- data[["A4r4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: A4r5c1 (mean)
  if (!("A4r5c1" %in% names(data))) stop("Variable 'A4r5c1' not found")
  test_vals <- data[["A4r5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: A4r6c1 (mean)
  if (!("A4r6c1" %in% names(data))) stop("Variable 'A4r6c1' not found")
  test_vals <- data[["A4r6c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r6c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: A4r7c1 (mean)
  if (!("A4r7c1" %in% names(data))) stop("Variable 'A4r7c1' not found")
  test_vals <- data[["A4r7c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r7c1' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4_last100", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a4_last100", error = conditionMessage(e))
})

print(paste("Validated:", "a4_last100", "-", if(validation_results[["a4_last100"]]$success) "PASS" else paste("FAIL:", validation_results[["a4_last100"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4_next100 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4_next100"]] <- tryCatch({

  # Row 1: A4r1c2 (mean)
  if (!("A4r1c2" %in% names(data))) stop("Variable 'A4r1c2' not found")
  test_vals <- data[["A4r1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4r2c2 (mean)
  if (!("A4r2c2" %in% names(data))) stop("Variable 'A4r2c2' not found")
  test_vals <- data[["A4r2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: A4r3c2 (mean)
  if (!("A4r3c2" %in% names(data))) stop("Variable 'A4r3c2' not found")
  test_vals <- data[["A4r3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: A4r4c2 (mean)
  if (!("A4r4c2" %in% names(data))) stop("Variable 'A4r4c2' not found")
  test_vals <- data[["A4r4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: A4r5c2 (mean)
  if (!("A4r5c2" %in% names(data))) stop("Variable 'A4r5c2' not found")
  test_vals <- data[["A4r5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: A4r6c2 (mean)
  if (!("A4r6c2" %in% names(data))) stop("Variable 'A4r6c2' not found")
  test_vals <- data[["A4r6c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r6c2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: A4r7c2 (mean)
  if (!("A4r7c2" %in% names(data))) stop("Variable 'A4r7c2' not found")
  test_vals <- data[["A4r7c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4r7c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4_next100", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a4_next100", error = conditionMessage(e))
})

print(paste("Validated:", "a4_next100", "-", if(validation_results[["a4_next100"]]$success) "PASS" else paste("FAIL:", validation_results[["a4_next100"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4a_leqvio (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4a_leqvio"]] <- tryCatch({

  # Row 1: A4ar1c1 (mean)
  if (!("A4ar1c1" %in% names(data))) stop("Variable 'A4ar1c1' not found")
  test_vals <- data[["A4ar1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4ar1c2 (mean)
  if (!("A4ar1c2" %in% names(data))) stop("Variable 'A4ar1c2' not found")
  test_vals <- data[["A4ar1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4a_leqvio", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4a_leqvio", error = conditionMessage(e))
})

print(paste("Validated:", "a4a_leqvio", "-", if(validation_results[["a4a_leqvio"]]$success) "PASS" else paste("FAIL:", validation_results[["a4a_leqvio"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4a_praluent (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4a_praluent"]] <- tryCatch({

  # Row 1: A4ar2c1 (mean)
  if (!("A4ar2c1" %in% names(data))) stop("Variable 'A4ar2c1' not found")
  test_vals <- data[["A4ar2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4ar2c2 (mean)
  if (!("A4ar2c2" %in% names(data))) stop("Variable 'A4ar2c2' not found")
  test_vals <- data[["A4ar2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4a_praluent", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4a_praluent", error = conditionMessage(e))
})

print(paste("Validated:", "a4a_praluent", "-", if(validation_results[["a4a_praluent"]]$success) "PASS" else paste("FAIL:", validation_results[["a4a_praluent"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4a_repatha (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4a_repatha"]] <- tryCatch({

  # Row 1: A4ar3c1 (mean)
  if (!("A4ar3c1" %in% names(data))) stop("Variable 'A4ar3c1' not found")
  test_vals <- data[["A4ar3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4ar3c2 (mean)
  if (!("A4ar3c2" %in% names(data))) stop("Variable 'A4ar3c2' not found")
  test_vals <- data[["A4ar3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4a_repatha", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4a_repatha", error = conditionMessage(e))
})

print(paste("Validated:", "a4a_repatha", "-", if(validation_results[["a4a_repatha"]]$success) "PASS" else paste("FAIL:", validation_results[["a4a_repatha"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4a_zetia (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4a_zetia"]] <- tryCatch({

  # Row 1: A4ar4c1 (mean)
  if (!("A4ar4c1" %in% names(data))) stop("Variable 'A4ar4c1' not found")
  test_vals <- data[["A4ar4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4ar4c2 (mean)
  if (!("A4ar4c2" %in% names(data))) stop("Variable 'A4ar4c2' not found")
  test_vals <- data[["A4ar4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4a_zetia", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4a_zetia", error = conditionMessage(e))
})

print(paste("Validated:", "a4a_zetia", "-", if(validation_results[["a4a_zetia"]]$success) "PASS" else paste("FAIL:", validation_results[["a4a_zetia"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4a_nexletol (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4a_nexletol"]] <- tryCatch({

  # Row 1: A4ar5c1 (mean)
  if (!("A4ar5c1" %in% names(data))) stop("Variable 'A4ar5c1' not found")
  test_vals <- data[["A4ar5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4ar5c2 (mean)
  if (!("A4ar5c2" %in% names(data))) stop("Variable 'A4ar5c2' not found")
  test_vals <- data[["A4ar5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4ar5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4a_nexletol", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4a_nexletol", error = conditionMessage(e))
})

print(paste("Validated:", "a4a_nexletol", "-", if(validation_results[["a4a_nexletol"]]$success) "PASS" else paste("FAIL:", validation_results[["a4a_nexletol"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4b_leqvio (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4b_leqvio"]] <- tryCatch({

  # Row 1: A4br1c1 (mean)
  if (!("A4br1c1" %in% names(data))) stop("Variable 'A4br1c1' not found")
  test_vals <- data[["A4br1c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br1c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4br1c2 (mean)
  if (!("A4br1c2" %in% names(data))) stop("Variable 'A4br1c2' not found")
  test_vals <- data[["A4br1c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br1c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4b_leqvio", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4b_leqvio", error = conditionMessage(e))
})

print(paste("Validated:", "a4b_leqvio", "-", if(validation_results[["a4b_leqvio"]]$success) "PASS" else paste("FAIL:", validation_results[["a4b_leqvio"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4b_praluent (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4b_praluent"]] <- tryCatch({

  # Row 1: A4br2c1 (mean)
  if (!("A4br2c1" %in% names(data))) stop("Variable 'A4br2c1' not found")
  test_vals <- data[["A4br2c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br2c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4br2c2 (mean)
  if (!("A4br2c2" %in% names(data))) stop("Variable 'A4br2c2' not found")
  test_vals <- data[["A4br2c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br2c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4b_praluent", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4b_praluent", error = conditionMessage(e))
})

print(paste("Validated:", "a4b_praluent", "-", if(validation_results[["a4b_praluent"]]$success) "PASS" else paste("FAIL:", validation_results[["a4b_praluent"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4b_repatha (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4b_repatha"]] <- tryCatch({

  # Row 1: A4br3c1 (mean)
  if (!("A4br3c1" %in% names(data))) stop("Variable 'A4br3c1' not found")
  test_vals <- data[["A4br3c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br3c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4br3c2 (mean)
  if (!("A4br3c2" %in% names(data))) stop("Variable 'A4br3c2' not found")
  test_vals <- data[["A4br3c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br3c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4b_repatha", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4b_repatha", error = conditionMessage(e))
})

print(paste("Validated:", "a4b_repatha", "-", if(validation_results[["a4b_repatha"]]$success) "PASS" else paste("FAIL:", validation_results[["a4b_repatha"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4b_zetia (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4b_zetia"]] <- tryCatch({

  # Row 1: A4br4c1 (mean)
  if (!("A4br4c1" %in% names(data))) stop("Variable 'A4br4c1' not found")
  test_vals <- data[["A4br4c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br4c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4br4c2 (mean)
  if (!("A4br4c2" %in% names(data))) stop("Variable 'A4br4c2' not found")
  test_vals <- data[["A4br4c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br4c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4b_zetia", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4b_zetia", error = conditionMessage(e))
})

print(paste("Validated:", "a4b_zetia", "-", if(validation_results[["a4b_zetia"]]$success) "PASS" else paste("FAIL:", validation_results[["a4b_zetia"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4b_nexletol (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["a4b_nexletol"]] <- tryCatch({

  # Row 1: A4br5c1 (mean)
  if (!("A4br5c1" %in% names(data))) stop("Variable 'A4br5c1' not found")
  test_vals <- data[["A4br5c1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br5c1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: A4br5c2 (mean)
  if (!("A4br5c2" %in% names(data))) stop("Variable 'A4br5c2' not found")
  test_vals <- data[["A4br5c2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A4br5c2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a4b_nexletol", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a4b_nexletol", error = conditionMessage(e))
})

print(paste("Validated:", "a4b_nexletol", "-", if(validation_results[["a4b_nexletol"]]$success) "PASS" else paste("FAIL:", validation_results[["a4b_nexletol"]]$error)))

# -----------------------------------------------------------------------------
# Table: a5 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a5"]] <- tryCatch({

  # Row 1: A5 == 1,2
  if (!("A5" %in% names(data))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(data[["A5"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A5 == 1
  if (!("A5" %in% names(data))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(data[["A5"]]) == 1, na.rm = TRUE)
  # Row 3: A5 == 2
  if (!("A5" %in% names(data))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(data[["A5"]]) == 2, na.rm = TRUE)
  # Row 4: A5 == 3
  if (!("A5" %in% names(data))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(data[["A5"]]) == 3, na.rm = TRUE)
  # Row 5: A5 == 4
  if (!("A5" %in% names(data))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(data[["A5"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a5", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a5", error = conditionMessage(e))
})

print(paste("Validated:", "a5", "-", if(validation_results[["a5"]]$success) "PASS" else paste("FAIL:", validation_results[["a5"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6"]] <- tryCatch({

  # Row 1: A6r1 == 1
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 1, na.rm = TRUE)
  # Row 2: A6r1 == 2
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 2, na.rm = TRUE)
  # Row 3: A6r1 == 3
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 3, na.rm = TRUE)
  # Row 4: A6r1 == 4
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 4, na.rm = TRUE)
  # Row 5: A6r2 == 1
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 1, na.rm = TRUE)
  # Row 6: A6r2 == 2
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 2, na.rm = TRUE)
  # Row 7: A6r2 == 3
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 3, na.rm = TRUE)
  # Row 8: A6r2 == 4
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 4, na.rm = TRUE)
  # Row 9: A6r3 == 1
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 1, na.rm = TRUE)
  # Row 10: A6r3 == 2
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 2, na.rm = TRUE)
  # Row 11: A6r3 == 3
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 3, na.rm = TRUE)
  # Row 12: A6r3 == 4
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 4, na.rm = TRUE)
  # Row 13: A6r4 == 1
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 1, na.rm = TRUE)
  # Row 14: A6r4 == 2
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 2, na.rm = TRUE)
  # Row 15: A6r4 == 3
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 3, na.rm = TRUE)
  # Row 16: A6r4 == 4
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 4, na.rm = TRUE)
  # Row 17: A6r5 == 1
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 1, na.rm = TRUE)
  # Row 18: A6r5 == 2
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 2, na.rm = TRUE)
  # Row 19: A6r5 == 3
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 3, na.rm = TRUE)
  # Row 20: A6r5 == 4
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 4, na.rm = TRUE)
  # Row 21: A6r6 == 1
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 1, na.rm = TRUE)
  # Row 22: A6r6 == 2
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 2, na.rm = TRUE)
  # Row 23: A6r6 == 3
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 3, na.rm = TRUE)
  # Row 24: A6r6 == 4
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 4, na.rm = TRUE)
  # Row 25: A6r7 == 1
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 1, na.rm = TRUE)
  # Row 26: A6r7 == 2
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 2, na.rm = TRUE)
  # Row 27: A6r7 == 3
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 3, na.rm = TRUE)
  # Row 28: A6r7 == 4
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 4, na.rm = TRUE)
  # Row 29: A6r8 == 3
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "a6", rowCount = 29)

}, error = function(e) {
  list(success = FALSE, tableId = "a6", error = conditionMessage(e))
})

print(paste("Validated:", "a6", "-", if(validation_results[["a6"]]$success) "PASS" else paste("FAIL:", validation_results[["a6"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r1"]] <- tryCatch({

  # Row 1: A6r1 == 1,2
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r1 == 1
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 1, na.rm = TRUE)
  # Row 3: A6r1 == 2
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 2, na.rm = TRUE)
  # Row 4: A6r1 == 3
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 3, na.rm = TRUE)
  # Row 5: A6r1 == 4
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r1", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r1", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r1", "-", if(validation_results[["a6_detail_A6r1"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r2"]] <- tryCatch({

  # Row 1: A6r2 == 1,2
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r2 == 1
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 1, na.rm = TRUE)
  # Row 3: A6r2 == 2
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 2, na.rm = TRUE)
  # Row 4: A6r2 == 3
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 3, na.rm = TRUE)
  # Row 5: A6r2 == 4
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r2", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r2", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r2", "-", if(validation_results[["a6_detail_A6r2"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r2"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r3 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r3"]] <- tryCatch({

  # Row 1: A6r3 == 1,2
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r3 == 1
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 1, na.rm = TRUE)
  # Row 3: A6r3 == 2
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 2, na.rm = TRUE)
  # Row 4: A6r3 == 3
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 3, na.rm = TRUE)
  # Row 5: A6r3 == 4
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r3", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r3", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r3", "-", if(validation_results[["a6_detail_A6r3"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r3"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r4 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r4"]] <- tryCatch({

  # Row 1: A6r4 == 1,2
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r4 == 1
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 1, na.rm = TRUE)
  # Row 3: A6r4 == 2
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 2, na.rm = TRUE)
  # Row 4: A6r4 == 3
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 3, na.rm = TRUE)
  # Row 5: A6r4 == 4
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r4", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r4", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r4", "-", if(validation_results[["a6_detail_A6r4"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r4"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r5 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r5"]] <- tryCatch({

  # Row 1: A6r5 == 1,2
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r5 == 1
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 1, na.rm = TRUE)
  # Row 3: A6r5 == 2
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 2, na.rm = TRUE)
  # Row 4: A6r5 == 3
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 3, na.rm = TRUE)
  # Row 5: A6r5 == 4
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r5", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r5", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r5", "-", if(validation_results[["a6_detail_A6r5"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r5"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r6 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r6"]] <- tryCatch({

  # Row 1: A6r6 == 1,2
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r6 == 1
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 1, na.rm = TRUE)
  # Row 3: A6r6 == 2
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 2, na.rm = TRUE)
  # Row 4: A6r6 == 3
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 3, na.rm = TRUE)
  # Row 5: A6r6 == 4
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r6", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r6", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r6", "-", if(validation_results[["a6_detail_A6r6"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r6"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r7 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r7"]] <- tryCatch({

  # Row 1: A6r7 == 1,2
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r7 == 1
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 1, na.rm = TRUE)
  # Row 3: A6r7 == 2
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 2, na.rm = TRUE)
  # Row 4: A6r7 == 3
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 3, na.rm = TRUE)
  # Row 5: A6r7 == 4
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r7", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r7", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r7", "-", if(validation_results[["a6_detail_A6r7"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r7"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_detail_A6r8 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_detail_A6r8"]] <- tryCatch({

  # Row 1: A6r8 == 1,2
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r8 == 1
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 1, na.rm = TRUE)
  # Row 3: A6r8 == 2
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 2, na.rm = TRUE)
  # Row 4: A6r8 == 3
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 3, na.rm = TRUE)
  # Row 5: A6r8 == 4
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_detail_A6r8", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_detail_A6r8", error = conditionMessage(e))
})

print(paste("Validated:", "a6_detail_A6r8", "-", if(validation_results[["a6_detail_A6r8"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_detail_A6r8"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_rank1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_rank1"]] <- tryCatch({

  # Row 1: A6r1 == 1
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) == 1, na.rm = TRUE)
  # Row 2: A6r2 == 1
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) == 1, na.rm = TRUE)
  # Row 3: A6r3 == 1
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) == 1, na.rm = TRUE)
  # Row 4: A6r4 == 1
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) == 1, na.rm = TRUE)
  # Row 5: A6r5 == 1
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) == 1, na.rm = TRUE)
  # Row 6: A6r6 == 1
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) == 1, na.rm = TRUE)
  # Row 7: A6r7 == 1
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) == 1, na.rm = TRUE)
  # Row 8: A6r8 == 1
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a6_rank1", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_rank1", error = conditionMessage(e))
})

print(paste("Validated:", "a6_rank1", "-", if(validation_results[["a6_rank1"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_rank1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6_top2_comparison (frequency)
# -----------------------------------------------------------------------------

validation_results[["a6_top2_comparison"]] <- tryCatch({

  # Row 1: A6r1 == 1,2
  if (!("A6r1" %in% names(data))) stop("Variable 'A6r1' not found")
  test_val <- sum(as.numeric(data[["A6r1"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A6r2 == 1,2
  if (!("A6r2" %in% names(data))) stop("Variable 'A6r2' not found")
  test_val <- sum(as.numeric(data[["A6r2"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 3: A6r3 == 1,2
  if (!("A6r3" %in% names(data))) stop("Variable 'A6r3' not found")
  test_val <- sum(as.numeric(data[["A6r3"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 4: A6r4 == 1,2
  if (!("A6r4" %in% names(data))) stop("Variable 'A6r4' not found")
  test_val <- sum(as.numeric(data[["A6r4"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 5: A6r5 == 1,2
  if (!("A6r5" %in% names(data))) stop("Variable 'A6r5' not found")
  test_val <- sum(as.numeric(data[["A6r5"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A6r6 == 1,2
  if (!("A6r6" %in% names(data))) stop("Variable 'A6r6' not found")
  test_val <- sum(as.numeric(data[["A6r6"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 7: A6r7 == 1,2
  if (!("A6r7" %in% names(data))) stop("Variable 'A6r7' not found")
  test_val <- sum(as.numeric(data[["A6r7"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 8: A6r8 == 1,2
  if (!("A6r8" %in% names(data))) stop("Variable 'A6r8' not found")
  test_val <- sum(as.numeric(data[["A6r8"]]) %in% c(1, 2), na.rm = TRUE)

  list(success = TRUE, tableId = "a6_top2_comparison", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a6_top2_comparison", error = conditionMessage(e))
})

print(paste("Validated:", "a6_top2_comparison", "-", if(validation_results[["a6_top2_comparison"]]$success) "PASS" else paste("FAIL:", validation_results[["a6_top2_comparison"]]$error)))

# -----------------------------------------------------------------------------
# Table: a7 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a7"]] <- tryCatch({

  # Row 1: NET - Any impact (NET)
  if (!("A7r1" %in% names(data))) stop("NET component variable 'A7r1' not found")
  if (!("A7r2" %in% names(data))) stop("NET component variable 'A7r2' not found")
  if (!("A7r3" %in% names(data))) stop("NET component variable 'A7r3' not found")
  if (!("A7r4" %in% names(data))) stop("NET component variable 'A7r4' not found")
  if (!("A7r5" %in% names(data))) stop("NET component variable 'A7r5' not found")
  # Row 2: A7r1 == 1
  if (!("A7r1" %in% names(data))) stop("Variable 'A7r1' not found")
  test_val <- sum(as.numeric(data[["A7r1"]]) == 1, na.rm = TRUE)
  # Row 3: A7r2 == 1
  if (!("A7r2" %in% names(data))) stop("Variable 'A7r2' not found")
  test_val <- sum(as.numeric(data[["A7r2"]]) == 1, na.rm = TRUE)
  # Row 4: A7r3 == 1
  if (!("A7r3" %in% names(data))) stop("Variable 'A7r3' not found")
  test_val <- sum(as.numeric(data[["A7r3"]]) == 1, na.rm = TRUE)
  # Row 5: A7r4 == 1
  if (!("A7r4" %in% names(data))) stop("Variable 'A7r4' not found")
  test_val <- sum(as.numeric(data[["A7r4"]]) == 1, na.rm = TRUE)
  # Row 6: A7r5 == 1
  if (!("A7r5" %in% names(data))) stop("Variable 'A7r5' not found")
  test_val <- sum(as.numeric(data[["A7r5"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a7", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "a7", error = conditionMessage(e))
})

print(paste("Validated:", "a7", "-", if(validation_results[["a7"]]$success) "PASS" else paste("FAIL:", validation_results[["a7"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8"]] <- tryCatch({

  # Row 1: A8r1c1 == 1
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 1, na.rm = TRUE)
  # Row 2: A8r1c1 == 2
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 2, na.rm = TRUE)
  # Row 3: A8r1c1 == 3
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 3, na.rm = TRUE)
  # Row 4: A8r1c1 == 4
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 4, na.rm = TRUE)
  # Row 5: A8r1c1 == 5
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 5, na.rm = TRUE)
  # Row 6: A8r1c2 == 1
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 1, na.rm = TRUE)
  # Row 7: A8r1c2 == 2
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 2, na.rm = TRUE)
  # Row 8: A8r1c2 == 3
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 3, na.rm = TRUE)
  # Row 9: A8r1c2 == 4
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r1c2 == 5
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 5, na.rm = TRUE)
  # Row 11: A8r1c3 == 1
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 1, na.rm = TRUE)
  # Row 12: A8r1c3 == 2
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 2, na.rm = TRUE)
  # Row 13: A8r1c3 == 3
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 3, na.rm = TRUE)
  # Row 14: A8r1c3 == 4
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 4, na.rm = TRUE)
  # Row 15: A8r1c3 == 5
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 5, na.rm = TRUE)
  # Row 16: A8r2c1 == 1
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 1, na.rm = TRUE)
  # Row 17: A8r2c1 == 2
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 2, na.rm = TRUE)
  # Row 18: A8r2c1 == 3
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 3, na.rm = TRUE)
  # Row 19: A8r2c1 == 4
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 4, na.rm = TRUE)
  # Row 20: A8r2c1 == 5
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 5, na.rm = TRUE)
  # Row 21: A8r2c2 == 1
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 1, na.rm = TRUE)
  # Row 22: A8r2c2 == 2
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 2, na.rm = TRUE)
  # Row 23: A8r2c2 == 3
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 3, na.rm = TRUE)
  # Row 24: A8r2c2 == 4
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 4, na.rm = TRUE)
  # Row 25: A8r2c2 == 5
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 5, na.rm = TRUE)
  # Row 26: A8r2c3 == 1
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 1, na.rm = TRUE)
  # Row 27: A8r2c3 == 2
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 2, na.rm = TRUE)
  # Row 28: A8r2c3 == 3
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 3, na.rm = TRUE)
  # Row 29: A8r2c3 == 4
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 4, na.rm = TRUE)
  # Row 30: A8r2c3 == 5
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 5, na.rm = TRUE)
  # Row 31: A8r3c1 == 1
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 1, na.rm = TRUE)
  # Row 32: A8r3c1 == 2
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 2, na.rm = TRUE)
  # Row 33: A8r3c1 == 3
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 3, na.rm = TRUE)
  # Row 34: A8r3c1 == 4
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 4, na.rm = TRUE)
  # Row 35: A8r3c1 == 5
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 5, na.rm = TRUE)
  # Row 36: A8r3c2 == 1
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 1, na.rm = TRUE)
  # Row 37: A8r3c2 == 2
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 2, na.rm = TRUE)
  # Row 38: A8r3c2 == 3
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 3, na.rm = TRUE)
  # Row 39: A8r3c2 == 4
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 4, na.rm = TRUE)
  # Row 40: A8r3c2 == 5
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 5, na.rm = TRUE)
  # Row 41: A8r3c3 == 1
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 1, na.rm = TRUE)
  # Row 42: A8r3c3 == 2
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 2, na.rm = TRUE)
  # Row 43: A8r3c3 == 3
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 3, na.rm = TRUE)
  # Row 44: A8r3c3 == 4
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 4, na.rm = TRUE)
  # Row 45: A8r3c3 == 5
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 5, na.rm = TRUE)
  # Row 46: A8r4c1 == 1
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 1, na.rm = TRUE)
  # Row 47: A8r4c1 == 2
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 2, na.rm = TRUE)
  # Row 48: A8r4c1 == 3
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 3, na.rm = TRUE)
  # Row 49: A8r4c1 == 4
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 4, na.rm = TRUE)
  # Row 50: A8r4c1 == 5
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 5, na.rm = TRUE)
  # Row 51: A8r4c2 == 1
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 1, na.rm = TRUE)
  # Row 52: A8r4c2 == 2
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 2, na.rm = TRUE)
  # Row 53: A8r4c2 == 3
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 3, na.rm = TRUE)
  # Row 54: A8r4c2 == 4
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 4, na.rm = TRUE)
  # Row 55: A8r4c2 == 5
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 5, na.rm = TRUE)
  # Row 56: A8r4c3 == 1
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 1, na.rm = TRUE)
  # Row 57: A8r4c3 == 2
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 2, na.rm = TRUE)
  # Row 58: A8r4c3 == 3
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 3, na.rm = TRUE)
  # Row 59: A8r4c3 == 4
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 4, na.rm = TRUE)
  # Row 60: A8r4c3 == 5
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 5, na.rm = TRUE)
  # Row 61: A8r5c1 == 1
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 1, na.rm = TRUE)
  # Row 62: A8r5c1 == 2
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 2, na.rm = TRUE)
  # Row 63: A8r5c1 == 3
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 3, na.rm = TRUE)
  # Row 64: A8r5c1 == 4
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 4, na.rm = TRUE)
  # Row 65: A8r5c1 == 5
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 5, na.rm = TRUE)
  # Row 66: A8r5c2 == 1
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 1, na.rm = TRUE)
  # Row 67: A8r5c2 == 2
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 2, na.rm = TRUE)
  # Row 68: A8r5c2 == 3
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 3, na.rm = TRUE)
  # Row 69: A8r5c2 == 4
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 4, na.rm = TRUE)
  # Row 70: A8r5c2 == 5
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 5, na.rm = TRUE)
  # Row 71: A8r5c3 == 1
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 1, na.rm = TRUE)
  # Row 72: A8r5c3 == 2
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 2, na.rm = TRUE)
  # Row 73: A8r5c3 == 3
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 3, na.rm = TRUE)
  # Row 74: A8r5c3 == 4
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 4, na.rm = TRUE)
  # Row 75: A8r5c3 == 5
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 5, na.rm = TRUE)

  list(success = TRUE, tableId = "a8", rowCount = 75)

}, error = function(e) {
  list(success = FALSE, tableId = "a8", error = conditionMessage(e))
})

print(paste("Validated:", "a8", "-", if(validation_results[["a8"]]$success) "PASS" else paste("FAIL:", validation_results[["a8"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_r1_full (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_r1_full"]] <- tryCatch({

  # Row 1: A8r1c1 == 4,5
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A8r1c1 == 5
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 5, na.rm = TRUE)
  # Row 3: A8r1c1 == 4
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 4, na.rm = TRUE)
  # Row 4: A8r1c1 == 3
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 3, na.rm = TRUE)
  # Row 5: A8r1c1 == 2
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 2, na.rm = TRUE)
  # Row 6: A8r1c1 == 1
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) == 1, na.rm = TRUE)
  # Row 7: A8r1c2 == 4,5
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r1c2 == 5
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 5, na.rm = TRUE)
  # Row 9: A8r1c2 == 4
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r1c2 == 3
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 3, na.rm = TRUE)
  # Row 11: A8r1c2 == 2
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 2, na.rm = TRUE)
  # Row 12: A8r1c2 == 1
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) == 1, na.rm = TRUE)
  # Row 13: A8r1c3 == 4,5
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 14: A8r1c3 == 5
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 5, na.rm = TRUE)
  # Row 15: A8r1c3 == 4
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 4, na.rm = TRUE)
  # Row 16: A8r1c3 == 3
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 3, na.rm = TRUE)
  # Row 17: A8r1c3 == 2
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 2, na.rm = TRUE)
  # Row 18: A8r1c3 == 1
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a8_r1_full", rowCount = 18)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_r1_full", error = conditionMessage(e))
})

print(paste("Validated:", "a8_r1_full", "-", if(validation_results[["a8_r1_full"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_r1_full"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_r2_full (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_r2_full"]] <- tryCatch({

  # Row 1: A8r2c1 == 4,5
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A8r2c1 == 5
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 5, na.rm = TRUE)
  # Row 3: A8r2c1 == 4
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 4, na.rm = TRUE)
  # Row 4: A8r2c1 == 3
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 3, na.rm = TRUE)
  # Row 5: A8r2c1 == 2
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 2, na.rm = TRUE)
  # Row 6: A8r2c1 == 1
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) == 1, na.rm = TRUE)
  # Row 7: A8r2c2 == 4,5
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r2c2 == 5
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 5, na.rm = TRUE)
  # Row 9: A8r2c2 == 4
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r2c2 == 3
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 3, na.rm = TRUE)
  # Row 11: A8r2c2 == 2
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 2, na.rm = TRUE)
  # Row 12: A8r2c2 == 1
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) == 1, na.rm = TRUE)
  # Row 13: A8r2c3 == 4,5
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 14: A8r2c3 == 5
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 5, na.rm = TRUE)
  # Row 15: A8r2c3 == 4
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 4, na.rm = TRUE)
  # Row 16: A8r2c3 == 3
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 3, na.rm = TRUE)
  # Row 17: A8r2c3 == 2
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 2, na.rm = TRUE)
  # Row 18: A8r2c3 == 1
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a8_r2_full", rowCount = 18)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_r2_full", error = conditionMessage(e))
})

print(paste("Validated:", "a8_r2_full", "-", if(validation_results[["a8_r2_full"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_r2_full"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_r3_full (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_r3_full"]] <- tryCatch({

  # Row 1: A8r3c1 == 4,5
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A8r3c1 == 5
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 5, na.rm = TRUE)
  # Row 3: A8r3c1 == 4
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 4, na.rm = TRUE)
  # Row 4: A8r3c1 == 3
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 3, na.rm = TRUE)
  # Row 5: A8r3c1 == 2
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 2, na.rm = TRUE)
  # Row 6: A8r3c1 == 1
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) == 1, na.rm = TRUE)
  # Row 7: A8r3c2 == 4,5
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r3c2 == 5
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 5, na.rm = TRUE)
  # Row 9: A8r3c2 == 4
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r3c2 == 3
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 3, na.rm = TRUE)
  # Row 11: A8r3c2 == 2
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 2, na.rm = TRUE)
  # Row 12: A8r3c2 == 1
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) == 1, na.rm = TRUE)
  # Row 13: A8r3c3 == 4,5
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 14: A8r3c3 == 5
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 5, na.rm = TRUE)
  # Row 15: A8r3c3 == 4
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 4, na.rm = TRUE)
  # Row 16: A8r3c3 == 3
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 3, na.rm = TRUE)
  # Row 17: A8r3c3 == 2
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 2, na.rm = TRUE)
  # Row 18: A8r3c3 == 1
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a8_r3_full", rowCount = 18)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_r3_full", error = conditionMessage(e))
})

print(paste("Validated:", "a8_r3_full", "-", if(validation_results[["a8_r3_full"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_r3_full"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_r4_full (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_r4_full"]] <- tryCatch({

  # Row 1: A8r4c1 == 4,5
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A8r4c1 == 5
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 5, na.rm = TRUE)
  # Row 3: A8r4c1 == 4
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 4, na.rm = TRUE)
  # Row 4: A8r4c1 == 3
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 3, na.rm = TRUE)
  # Row 5: A8r4c1 == 2
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 2, na.rm = TRUE)
  # Row 6: A8r4c1 == 1
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) == 1, na.rm = TRUE)
  # Row 7: A8r4c2 == 4,5
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r4c2 == 5
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 5, na.rm = TRUE)
  # Row 9: A8r4c2 == 4
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r4c2 == 3
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 3, na.rm = TRUE)
  # Row 11: A8r4c2 == 2
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 2, na.rm = TRUE)
  # Row 12: A8r4c2 == 1
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) == 1, na.rm = TRUE)
  # Row 13: A8r4c3 == 4,5
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 14: A8r4c3 == 5
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 5, na.rm = TRUE)
  # Row 15: A8r4c3 == 4
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 4, na.rm = TRUE)
  # Row 16: A8r4c3 == 3
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 3, na.rm = TRUE)
  # Row 17: A8r4c3 == 2
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 2, na.rm = TRUE)
  # Row 18: A8r4c3 == 1
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a8_r4_full", rowCount = 18)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_r4_full", error = conditionMessage(e))
})

print(paste("Validated:", "a8_r4_full", "-", if(validation_results[["a8_r4_full"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_r4_full"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_r5_full (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_r5_full"]] <- tryCatch({

  # Row 1: A8r5c1 == 4,5
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A8r5c1 == 5
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 5, na.rm = TRUE)
  # Row 3: A8r5c1 == 4
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 4, na.rm = TRUE)
  # Row 4: A8r5c1 == 3
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 3, na.rm = TRUE)
  # Row 5: A8r5c1 == 2
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 2, na.rm = TRUE)
  # Row 6: A8r5c1 == 1
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) == 1, na.rm = TRUE)
  # Row 7: A8r5c2 == 4,5
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r5c2 == 5
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 5, na.rm = TRUE)
  # Row 9: A8r5c2 == 4
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 4, na.rm = TRUE)
  # Row 10: A8r5c2 == 3
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 3, na.rm = TRUE)
  # Row 11: A8r5c2 == 2
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 2, na.rm = TRUE)
  # Row 12: A8r5c2 == 1
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) == 1, na.rm = TRUE)
  # Row 13: A8r5c3 == 4,5
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 14: A8r5c3 == 5
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 5, na.rm = TRUE)
  # Row 15: A8r5c3 == 4
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 4, na.rm = TRUE)
  # Row 16: A8r5c3 == 3
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 3, na.rm = TRUE)
  # Row 17: A8r5c3 == 2
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 2, na.rm = TRUE)
  # Row 18: A8r5c3 == 1
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a8_r5_full", rowCount = 18)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_r5_full", error = conditionMessage(e))
})

print(paste("Validated:", "a8_r5_full", "-", if(validation_results[["a8_r5_full"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_r5_full"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8_t2b_by_situation (frequency)
# -----------------------------------------------------------------------------

validation_results[["a8_t2b_by_situation"]] <- tryCatch({

  # Row 1: Category header - With established CVD (skip validation)
  # Row 2: A8r1c1 == 4,5
  if (!("A8r1c1" %in% names(data))) stop("Variable 'A8r1c1' not found")
  test_val <- sum(as.numeric(data[["A8r1c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 3: A8r1c2 == 4,5
  if (!("A8r1c2" %in% names(data))) stop("Variable 'A8r1c2' not found")
  test_val <- sum(as.numeric(data[["A8r1c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 4: A8r1c3 == 4,5
  if (!("A8r1c3" %in% names(data))) stop("Variable 'A8r1c3' not found")
  test_val <- sum(as.numeric(data[["A8r1c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 5: Category header - With no history of CV events and at high-risk (skip validation)
  # Row 6: A8r2c1 == 4,5
  if (!("A8r2c1" %in% names(data))) stop("Variable 'A8r2c1' not found")
  test_val <- sum(as.numeric(data[["A8r2c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 7: A8r2c2 == 4,5
  if (!("A8r2c2" %in% names(data))) stop("Variable 'A8r2c2' not found")
  test_val <- sum(as.numeric(data[["A8r2c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 8: A8r2c3 == 4,5
  if (!("A8r2c3" %in% names(data))) stop("Variable 'A8r2c3' not found")
  test_val <- sum(as.numeric(data[["A8r2c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 9: Category header - With no history of CV events and at low-to-medium risk (skip validation)
  # Row 10: A8r3c1 == 4,5
  if (!("A8r3c1" %in% names(data))) stop("Variable 'A8r3c1' not found")
  test_val <- sum(as.numeric(data[["A8r3c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 11: A8r3c2 == 4,5
  if (!("A8r3c2" %in% names(data))) stop("Variable 'A8r3c2' not found")
  test_val <- sum(as.numeric(data[["A8r3c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 12: A8r3c3 == 4,5
  if (!("A8r3c3" %in% names(data))) stop("Variable 'A8r3c3' not found")
  test_val <- sum(as.numeric(data[["A8r3c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 13: Category header - Who are not known to be compliant on statins (skip validation)
  # Row 14: A8r4c1 == 4,5
  if (!("A8r4c1" %in% names(data))) stop("Variable 'A8r4c1' not found")
  test_val <- sum(as.numeric(data[["A8r4c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 15: A8r4c2 == 4,5
  if (!("A8r4c2" %in% names(data))) stop("Variable 'A8r4c2' not found")
  test_val <- sum(as.numeric(data[["A8r4c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 16: A8r4c3 == 4,5
  if (!("A8r4c3" %in% names(data))) stop("Variable 'A8r4c3' not found")
  test_val <- sum(as.numeric(data[["A8r4c3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 17: Category header - Who are intolerant of statins (skip validation)
  # Row 18: A8r5c1 == 4,5
  if (!("A8r5c1" %in% names(data))) stop("Variable 'A8r5c1' not found")
  test_val <- sum(as.numeric(data[["A8r5c1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 19: A8r5c2 == 4,5
  if (!("A8r5c2" %in% names(data))) stop("Variable 'A8r5c2' not found")
  test_val <- sum(as.numeric(data[["A8r5c2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 20: A8r5c3 == 4,5
  if (!("A8r5c3" %in% names(data))) stop("Variable 'A8r5c3' not found")
  test_val <- sum(as.numeric(data[["A8r5c3"]]) %in% c(4, 5), na.rm = TRUE)

  list(success = TRUE, tableId = "a8_t2b_by_situation", rowCount = 20)

}, error = function(e) {
  list(success = FALSE, tableId = "a8_t2b_by_situation", error = conditionMessage(e))
})

print(paste("Validated:", "a8_t2b_by_situation", "-", if(validation_results[["a8_t2b_by_situation"]]$success) "PASS" else paste("FAIL:", validation_results[["a8_t2b_by_situation"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9"]] <- tryCatch({

  # Row 1: A9c1 == 1
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 1, na.rm = TRUE)
  # Row 2: A9c1 == 2
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 2, na.rm = TRUE)
  # Row 3: A9c1 == 3
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 3, na.rm = TRUE)
  # Row 4: A9c1 == 4
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 4, na.rm = TRUE)
  # Row 5: A9c2 == 1
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 1, na.rm = TRUE)
  # Row 6: A9c2 == 2
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 2, na.rm = TRUE)
  # Row 7: A9c2 == 3
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 3, na.rm = TRUE)
  # Row 8: A9c2 == 4
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 4, na.rm = TRUE)
  # Row 9: A9c3 == 1
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 1, na.rm = TRUE)
  # Row 10: A9c3 == 2
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 2, na.rm = TRUE)
  # Row 11: A9c3 == 3
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 3, na.rm = TRUE)
  # Row 12: A9c3 == 4
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a9", rowCount = 12)

}, error = function(e) {
  list(success = FALSE, tableId = "a9", error = conditionMessage(e))
})

print(paste("Validated:", "a9", "-", if(validation_results[["a9"]]$success) "PASS" else paste("FAIL:", validation_results[["a9"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9_any_issues_comparison (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9_any_issues_comparison"]] <- tryCatch({

  # Row 1: A9c1 == 2,3
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 2: A9c2 == 2,3
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 3: A9c3 == 2,3
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) %in% c(2, 3), na.rm = TRUE)

  list(success = TRUE, tableId = "a9_any_issues_comparison", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_any_issues_comparison", error = conditionMessage(e))
})

print(paste("Validated:", "a9_any_issues_comparison", "-", if(validation_results[["a9_any_issues_comparison"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_any_issues_comparison"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9_leqvio_detail (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9_leqvio_detail"]] <- tryCatch({

  # Row 1: A9c3 == 2,3
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 2: A9c3 == 2
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 2, na.rm = TRUE)
  # Row 3: A9c3 == 3
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 3, na.rm = TRUE)
  # Row 4: A9c3 == 1
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 1, na.rm = TRUE)
  # Row 5: A9c3 == 4
  if (!("A9c3" %in% names(data))) stop("Variable 'A9c3' not found")
  test_val <- sum(as.numeric(data[["A9c3"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a9_leqvio_detail", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_leqvio_detail", error = conditionMessage(e))
})

print(paste("Validated:", "a9_leqvio_detail", "-", if(validation_results[["a9_leqvio_detail"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_leqvio_detail"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9_praluent_detail (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9_praluent_detail"]] <- tryCatch({

  # Row 1: A9c2 == 2,3
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 2: A9c2 == 2
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 2, na.rm = TRUE)
  # Row 3: A9c2 == 3
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 3, na.rm = TRUE)
  # Row 4: A9c2 == 1
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 1, na.rm = TRUE)
  # Row 5: A9c2 == 4
  if (!("A9c2" %in% names(data))) stop("Variable 'A9c2' not found")
  test_val <- sum(as.numeric(data[["A9c2"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a9_praluent_detail", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_praluent_detail", error = conditionMessage(e))
})

print(paste("Validated:", "a9_praluent_detail", "-", if(validation_results[["a9_praluent_detail"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_praluent_detail"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9_repatha_detail (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9_repatha_detail"]] <- tryCatch({

  # Row 1: A9c1 == 2,3
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) %in% c(2, 3), na.rm = TRUE)
  # Row 2: A9c1 == 2
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 2, na.rm = TRUE)
  # Row 3: A9c1 == 3
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 3, na.rm = TRUE)
  # Row 4: A9c1 == 1
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 1, na.rm = TRUE)
  # Row 5: A9c1 == 4
  if (!("A9c1" %in% names(data))) stop("Variable 'A9c1' not found")
  test_val <- sum(as.numeric(data[["A9c1"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a9_repatha_detail", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_repatha_detail", error = conditionMessage(e))
})

print(paste("Validated:", "a9_repatha_detail", "-", if(validation_results[["a9_repatha_detail"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_repatha_detail"]]$error)))

# -----------------------------------------------------------------------------
# Table: a10 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a10"]] <- tryCatch({

  # Row 1: NET - Any reason for prescribing PCSK9s without a statin (NET)
  if (!("A10r1" %in% names(data))) stop("NET component variable 'A10r1' not found")
  if (!("A10r2" %in% names(data))) stop("NET component variable 'A10r2' not found")
  if (!("A10r3" %in% names(data))) stop("NET component variable 'A10r3' not found")
  if (!("A10r4" %in% names(data))) stop("NET component variable 'A10r4' not found")
  if (!("A10r5" %in% names(data))) stop("NET component variable 'A10r5' not found")
  # Row 2: A10r1 == 1
  if (!("A10r1" %in% names(data))) stop("Variable 'A10r1' not found")
  test_val <- sum(as.numeric(data[["A10r1"]]) == 1, na.rm = TRUE)
  # Row 3: A10r2 == 1
  if (!("A10r2" %in% names(data))) stop("Variable 'A10r2' not found")
  test_val <- sum(as.numeric(data[["A10r2"]]) == 1, na.rm = TRUE)
  # Row 4: A10r3 == 1
  if (!("A10r3" %in% names(data))) stop("Variable 'A10r3' not found")
  test_val <- sum(as.numeric(data[["A10r3"]]) == 1, na.rm = TRUE)
  # Row 5: A10r4 == 1
  if (!("A10r4" %in% names(data))) stop("Variable 'A10r4' not found")
  test_val <- sum(as.numeric(data[["A10r4"]]) == 1, na.rm = TRUE)
  # Row 6: A10r5 == 1
  if (!("A10r5" %in% names(data))) stop("Variable 'A10r5' not found")
  test_val <- sum(as.numeric(data[["A10r5"]]) == 1, na.rm = TRUE)
  # Row 7: A10r6 == 1
  if (!("A10r6" %in% names(data))) stop("Variable 'A10r6' not found")
  test_val <- sum(as.numeric(data[["A10r6"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a10", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a10", error = conditionMessage(e))
})

print(paste("Validated:", "a10", "-", if(validation_results[["a10"]]$success) "PASS" else paste("FAIL:", validation_results[["a10"]]$error)))

# -----------------------------------------------------------------------------
# Table: b1_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["b1_binned"]] <- tryCatch({

  # Row 1: Category header - Not insured (skip validation)
  # Row 2: B1r1 == 0
  if (!("B1r1" %in% names(data))) stop("Variable 'B1r1' not found")
  test_val <- sum(as.numeric(data[["B1r1"]]) == 0, na.rm = TRUE)
  # Row 3: B1r1 == 1-4
  if (!("B1r1" %in% names(data))) stop("Variable 'B1r1' not found")
  test_val <- sum(as.numeric(data[["B1r1"]]) >= 1 & as.numeric(data[["B1r1"]]) <= 4, na.rm = TRUE)
  # Row 4: B1r1 == 5-9
  if (!("B1r1" %in% names(data))) stop("Variable 'B1r1' not found")
  test_val <- sum(as.numeric(data[["B1r1"]]) >= 5 & as.numeric(data[["B1r1"]]) <= 9, na.rm = TRUE)
  # Row 5: B1r1 == 10-15
  if (!("B1r1" %in% names(data))) stop("Variable 'B1r1' not found")
  test_val <- sum(as.numeric(data[["B1r1"]]) >= 10 & as.numeric(data[["B1r1"]]) <= 15, na.rm = TRUE)
  # Row 6: Category header - Private insurance provided by employer / purchased in exchange (skip validation)
  # Row 7: B1r2 == 0
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) == 0, na.rm = TRUE)
  # Row 8: B1r2 == 1-9
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) >= 1 & as.numeric(data[["B1r2"]]) <= 9, na.rm = TRUE)
  # Row 9: B1r2 == 10-24
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) >= 10 & as.numeric(data[["B1r2"]]) <= 24, na.rm = TRUE)
  # Row 10: B1r2 == 25-49
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) >= 25 & as.numeric(data[["B1r2"]]) <= 49, na.rm = TRUE)
  # Row 11: B1r2 == 50-74
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) >= 50 & as.numeric(data[["B1r2"]]) <= 74, na.rm = TRUE)
  # Row 12: B1r2 == 75-100
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_val <- sum(as.numeric(data[["B1r2"]]) >= 75 & as.numeric(data[["B1r2"]]) <= 100, na.rm = TRUE)
  # Row 13: Category header - Traditional Medicare (Medicare Part B Fee for Service) (skip validation)
  # Row 14: B1r3 == 0
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_val <- sum(as.numeric(data[["B1r3"]]) == 0, na.rm = TRUE)
  # Row 15: B1r3 == 1-9
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_val <- sum(as.numeric(data[["B1r3"]]) >= 1 & as.numeric(data[["B1r3"]]) <= 9, na.rm = TRUE)
  # Row 16: B1r3 == 10-24
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_val <- sum(as.numeric(data[["B1r3"]]) >= 10 & as.numeric(data[["B1r3"]]) <= 24, na.rm = TRUE)
  # Row 17: B1r3 == 25-49
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_val <- sum(as.numeric(data[["B1r3"]]) >= 25 & as.numeric(data[["B1r3"]]) <= 49, na.rm = TRUE)
  # Row 18: B1r3 == 50-80
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_val <- sum(as.numeric(data[["B1r3"]]) >= 50 & as.numeric(data[["B1r3"]]) <= 80, na.rm = TRUE)
  # Row 19: Category header - Traditional Medicare with supplemental insurance (skip validation)
  # Row 20: B1r4 == 0
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_val <- sum(as.numeric(data[["B1r4"]]) == 0, na.rm = TRUE)
  # Row 21: B1r4 == 1-9
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_val <- sum(as.numeric(data[["B1r4"]]) >= 1 & as.numeric(data[["B1r4"]]) <= 9, na.rm = TRUE)
  # Row 22: B1r4 == 10-24
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_val <- sum(as.numeric(data[["B1r4"]]) >= 10 & as.numeric(data[["B1r4"]]) <= 24, na.rm = TRUE)
  # Row 23: B1r4 == 25-49
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_val <- sum(as.numeric(data[["B1r4"]]) >= 25 & as.numeric(data[["B1r4"]]) <= 49, na.rm = TRUE)
  # Row 24: B1r4 == 50-60
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_val <- sum(as.numeric(data[["B1r4"]]) >= 50 & as.numeric(data[["B1r4"]]) <= 60, na.rm = TRUE)
  # Row 25: Category header - Private Medicare (Medicare Advantage / Part C managed through Private payer) (skip validation)
  # Row 26: B1r5 == 0
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_val <- sum(as.numeric(data[["B1r5"]]) == 0, na.rm = TRUE)
  # Row 27: B1r5 == 1-9
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_val <- sum(as.numeric(data[["B1r5"]]) >= 1 & as.numeric(data[["B1r5"]]) <= 9, na.rm = TRUE)
  # Row 28: B1r5 == 10-24
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_val <- sum(as.numeric(data[["B1r5"]]) >= 10 & as.numeric(data[["B1r5"]]) <= 24, na.rm = TRUE)
  # Row 29: B1r5 == 25-49
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_val <- sum(as.numeric(data[["B1r5"]]) >= 25 & as.numeric(data[["B1r5"]]) <= 49, na.rm = TRUE)
  # Row 30: B1r5 == 50-60
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_val <- sum(as.numeric(data[["B1r5"]]) >= 50 & as.numeric(data[["B1r5"]]) <= 60, na.rm = TRUE)
  # Row 31: Category header - Medicaid (skip validation)
  # Row 32: B1r6 == 0
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_val <- sum(as.numeric(data[["B1r6"]]) == 0, na.rm = TRUE)
  # Row 33: B1r6 == 1-9
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_val <- sum(as.numeric(data[["B1r6"]]) >= 1 & as.numeric(data[["B1r6"]]) <= 9, na.rm = TRUE)
  # Row 34: B1r6 == 10-19
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_val <- sum(as.numeric(data[["B1r6"]]) >= 10 & as.numeric(data[["B1r6"]]) <= 19, na.rm = TRUE)
  # Row 35: B1r6 == 20-29
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_val <- sum(as.numeric(data[["B1r6"]]) >= 20 & as.numeric(data[["B1r6"]]) <= 29, na.rm = TRUE)
  # Row 36: B1r6 == 30-40
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_val <- sum(as.numeric(data[["B1r6"]]) >= 30 & as.numeric(data[["B1r6"]]) <= 40, na.rm = TRUE)
  # Row 37: Category header - Veterans Administration (VA) (skip validation)
  # Row 38: B1r7 == 0
  if (!("B1r7" %in% names(data))) stop("Variable 'B1r7' not found")
  test_val <- sum(as.numeric(data[["B1r7"]]) == 0, na.rm = TRUE)
  # Row 39: B1r7 == 1-4
  if (!("B1r7" %in% names(data))) stop("Variable 'B1r7' not found")
  test_val <- sum(as.numeric(data[["B1r7"]]) >= 1 & as.numeric(data[["B1r7"]]) <= 4, na.rm = TRUE)
  # Row 40: B1r7 == 5-9
  if (!("B1r7" %in% names(data))) stop("Variable 'B1r7' not found")
  test_val <- sum(as.numeric(data[["B1r7"]]) >= 5 & as.numeric(data[["B1r7"]]) <= 9, na.rm = TRUE)
  # Row 41: B1r7 == 10-15
  if (!("B1r7" %in% names(data))) stop("Variable 'B1r7' not found")
  test_val <- sum(as.numeric(data[["B1r7"]]) >= 10 & as.numeric(data[["B1r7"]]) <= 15, na.rm = TRUE)
  # Row 42: Category header - Other (skip validation)
  # Row 43: B1r8 == 0
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_val <- sum(as.numeric(data[["B1r8"]]) == 0, na.rm = TRUE)
  # Row 44: B1r8 == 1-4
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_val <- sum(as.numeric(data[["B1r8"]]) >= 1 & as.numeric(data[["B1r8"]]) <= 4, na.rm = TRUE)
  # Row 45: B1r8 == 5-9
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_val <- sum(as.numeric(data[["B1r8"]]) >= 5 & as.numeric(data[["B1r8"]]) <= 9, na.rm = TRUE)
  # Row 46: B1r8 == 10-14
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_val <- sum(as.numeric(data[["B1r8"]]) >= 10 & as.numeric(data[["B1r8"]]) <= 14, na.rm = TRUE)
  # Row 47: B1r8 == 15-20
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_val <- sum(as.numeric(data[["B1r8"]]) >= 15 & as.numeric(data[["B1r8"]]) <= 20, na.rm = TRUE)

  list(success = TRUE, tableId = "b1_binned", rowCount = 47)

}, error = function(e) {
  list(success = FALSE, tableId = "b1_binned", error = conditionMessage(e))
})

print(paste("Validated:", "b1_binned", "-", if(validation_results[["b1_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["b1_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: b1_mean (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["b1_mean"]] <- tryCatch({

  # Row 1: B1r1 (mean)
  if (!("B1r1" %in% names(data))) stop("Variable 'B1r1' not found")
  test_vals <- data[["B1r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: B1r2 (mean)
  if (!("B1r2" %in% names(data))) stop("Variable 'B1r2' not found")
  test_vals <- data[["B1r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: B1r3 (mean)
  if (!("B1r3" %in% names(data))) stop("Variable 'B1r3' not found")
  test_vals <- data[["B1r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: B1r4 (mean)
  if (!("B1r4" %in% names(data))) stop("Variable 'B1r4' not found")
  test_vals <- data[["B1r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r4' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: B1r5 (mean)
  if (!("B1r5" %in% names(data))) stop("Variable 'B1r5' not found")
  test_vals <- data[["B1r5"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r5' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: B1r6 (mean)
  if (!("B1r6" %in% names(data))) stop("Variable 'B1r6' not found")
  test_vals <- data[["B1r6"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r6' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: B1r7 (mean)
  if (!("B1r7" %in% names(data))) stop("Variable 'B1r7' not found")
  test_vals <- data[["B1r7"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r7' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 8: B1r8 (mean)
  if (!("B1r8" %in% names(data))) stop("Variable 'B1r8' not found")
  test_vals <- data[["B1r8"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B1r8' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "b1_mean", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "b1_mean", error = conditionMessage(e))
})

print(paste("Validated:", "b1_mean", "-", if(validation_results[["b1_mean"]]$success) "PASS" else paste("FAIL:", validation_results[["b1_mean"]]$error)))

# -----------------------------------------------------------------------------
# Table: b3 (frequency)
# -----------------------------------------------------------------------------

validation_results[["b3"]] <- tryCatch({

  # Row 1: B3 == 1,2
  if (!("B3" %in% names(data))) stop("Variable 'B3' not found")
  test_val <- sum(as.numeric(data[["B3"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: B3 == 1
  if (!("B3" %in% names(data))) stop("Variable 'B3' not found")
  test_val <- sum(as.numeric(data[["B3"]]) == 1, na.rm = TRUE)
  # Row 3: B3 == 2
  if (!("B3" %in% names(data))) stop("Variable 'B3' not found")
  test_val <- sum(as.numeric(data[["B3"]]) == 2, na.rm = TRUE)
  # Row 4: B3 == 3
  if (!("B3" %in% names(data))) stop("Variable 'B3' not found")
  test_val <- sum(as.numeric(data[["B3"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "b3", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "b3", error = conditionMessage(e))
})

print(paste("Validated:", "b3", "-", if(validation_results[["b3"]]$success) "PASS" else paste("FAIL:", validation_results[["b3"]]$error)))

# -----------------------------------------------------------------------------
# Table: b4 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["b4"]] <- tryCatch({

  # Row 1: B4 (mean)
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_vals <- data[["B4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'B4' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "b4", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "b4", error = conditionMessage(e))
})

print(paste("Validated:", "b4", "-", if(validation_results[["b4"]]$success) "PASS" else paste("FAIL:", validation_results[["b4"]]$error)))

# -----------------------------------------------------------------------------
# Table: b4_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["b4_binned"]] <- tryCatch({

  # Row 1: B4 == 1
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) == 1, na.rm = TRUE)
  # Row 2: B4 == 2-1000
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) >= 2 & as.numeric(data[["B4"]]) <= 1000, na.rm = TRUE)
  # Row 3: B4 == 2-3
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) >= 2 & as.numeric(data[["B4"]]) <= 3, na.rm = TRUE)
  # Row 4: B4 == 4-7
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) >= 4 & as.numeric(data[["B4"]]) <= 7, na.rm = TRUE)
  # Row 5: B4 == 8-22
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) >= 8 & as.numeric(data[["B4"]]) <= 22, na.rm = TRUE)
  # Row 6: B4 == 23-1000
  if (!("B4" %in% names(data))) stop("Variable 'B4' not found")
  test_val <- sum(as.numeric(data[["B4"]]) >= 23 & as.numeric(data[["B4"]]) <= 1000, na.rm = TRUE)

  list(success = TRUE, tableId = "b4_binned", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "b4_binned", error = conditionMessage(e))
})

print(paste("Validated:", "b4_binned", "-", if(validation_results[["b4_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["b4_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: b5 (frequency)
# -----------------------------------------------------------------------------

validation_results[["b5"]] <- tryCatch({

  # Row 1: NET - Any of the following (NET)
  if (!("B5r1" %in% names(data))) stop("NET component variable 'B5r1' not found")
  if (!("B5r2" %in% names(data))) stop("NET component variable 'B5r2' not found")
  if (!("B5r3" %in% names(data))) stop("NET component variable 'B5r3' not found")
  if (!("B5r4" %in% names(data))) stop("NET component variable 'B5r4' not found")
  if (!("B5r5" %in% names(data))) stop("NET component variable 'B5r5' not found")
  # Row 2: B5r1 == 1
  if (!("B5r1" %in% names(data))) stop("Variable 'B5r1' not found")
  test_val <- sum(as.numeric(data[["B5r1"]]) == 1, na.rm = TRUE)
  # Row 3: B5r2 == 1
  if (!("B5r2" %in% names(data))) stop("Variable 'B5r2' not found")
  test_val <- sum(as.numeric(data[["B5r2"]]) == 1, na.rm = TRUE)
  # Row 4: B5r3 == 1
  if (!("B5r3" %in% names(data))) stop("Variable 'B5r3' not found")
  test_val <- sum(as.numeric(data[["B5r3"]]) == 1, na.rm = TRUE)
  # Row 5: B5r4 == 1
  if (!("B5r4" %in% names(data))) stop("Variable 'B5r4' not found")
  test_val <- sum(as.numeric(data[["B5r4"]]) == 1, na.rm = TRUE)
  # Row 6: B5r5 == 1
  if (!("B5r5" %in% names(data))) stop("Variable 'B5r5' not found")
  test_val <- sum(as.numeric(data[["B5r5"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "b5", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "b5", error = conditionMessage(e))
})

print(paste("Validated:", "b5", "-", if(validation_results[["b5"]]$success) "PASS" else paste("FAIL:", validation_results[["b5"]]$error)))

# -----------------------------------------------------------------------------
# Table: qcard_specialty (frequency)
# -----------------------------------------------------------------------------

validation_results[["qcard_specialty"]] <- tryCatch({

  # Row 1: qCARD_SPECIALTY == 1
  if (!("qCARD_SPECIALTY" %in% names(data))) stop("Variable 'qCARD_SPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qCARD_SPECIALTY"]]) == 1, na.rm = TRUE)
  # Row 2: qCARD_SPECIALTY == 2
  if (!("qCARD_SPECIALTY" %in% names(data))) stop("Variable 'qCARD_SPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qCARD_SPECIALTY"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "qcard_specialty", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "qcard_specialty", error = conditionMessage(e))
})

print(paste("Validated:", "qcard_specialty", "-", if(validation_results[["qcard_specialty"]]$success) "PASS" else paste("FAIL:", validation_results[["qcard_specialty"]]$error)))

# -----------------------------------------------------------------------------
# Table: qcard_specialty (frequency)
# -----------------------------------------------------------------------------

validation_results[["qcard_specialty"]] <- tryCatch({

  # Row 1: qCARD_SPECIALTY == 1
  if (!("qCARD_SPECIALTY" %in% names(data))) stop("Variable 'qCARD_SPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qCARD_SPECIALTY"]]) == 1, na.rm = TRUE)
  # Row 2: qCARD_SPECIALTY == 2
  if (!("qCARD_SPECIALTY" %in% names(data))) stop("Variable 'qCARD_SPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qCARD_SPECIALTY"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "qcard_specialty", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "qcard_specialty", error = conditionMessage(e))
})

print(paste("Validated:", "qcard_specialty", "-", if(validation_results[["qcard_specialty"]]$success) "PASS" else paste("FAIL:", validation_results[["qcard_specialty"]]$error)))

# -----------------------------------------------------------------------------
# Table: qconsent (frequency)
# -----------------------------------------------------------------------------

validation_results[["qconsent"]] <- tryCatch({

  # Row 1: QCONSENT == 1
  if (!("QCONSENT" %in% names(data))) stop("Variable 'QCONSENT' not found")
  test_val <- sum(as.numeric(data[["QCONSENT"]]) == 1, na.rm = TRUE)
  # Row 2: QCONSENT == 2
  if (!("QCONSENT" %in% names(data))) stop("Variable 'QCONSENT' not found")
  test_val <- sum(as.numeric(data[["QCONSENT"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "qconsent", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "qconsent", error = conditionMessage(e))
})

print(paste("Validated:", "qconsent", "-", if(validation_results[["qconsent"]]$success) "PASS" else paste("FAIL:", validation_results[["qconsent"]]$error)))

# -----------------------------------------------------------------------------
# Table: qlist_priority_account (frequency)
# -----------------------------------------------------------------------------

validation_results[["qlist_priority_account"]] <- tryCatch({

  # Row 1: qLIST_PRIORITY_ACCOUNT == 1
  if (!("qLIST_PRIORITY_ACCOUNT" %in% names(data))) stop("Variable 'qLIST_PRIORITY_ACCOUNT' not found")
  test_val <- sum(as.numeric(data[["qLIST_PRIORITY_ACCOUNT"]]) == 1, na.rm = TRUE)
  # Row 2: qLIST_PRIORITY_ACCOUNT == 2
  if (!("qLIST_PRIORITY_ACCOUNT" %in% names(data))) stop("Variable 'qLIST_PRIORITY_ACCOUNT' not found")
  test_val <- sum(as.numeric(data[["qLIST_PRIORITY_ACCOUNT"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "qlist_priority_account", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "qlist_priority_account", error = conditionMessage(e))
})

print(paste("Validated:", "qlist_priority_account", "-", if(validation_results[["qlist_priority_account"]]$success) "PASS" else paste("FAIL:", validation_results[["qlist_priority_account"]]$error)))

# -----------------------------------------------------------------------------
# Table: qlist_priority_account (frequency)
# -----------------------------------------------------------------------------

validation_results[["qlist_priority_account"]] <- tryCatch({

  # Row 1: qLIST_PRIORITY_ACCOUNT == 1
  if (!("qLIST_PRIORITY_ACCOUNT" %in% names(data))) stop("Variable 'qLIST_PRIORITY_ACCOUNT' not found")
  test_val <- sum(as.numeric(data[["qLIST_PRIORITY_ACCOUNT"]]) == 1, na.rm = TRUE)
  # Row 2: qLIST_PRIORITY_ACCOUNT == 2
  if (!("qLIST_PRIORITY_ACCOUNT" %in% names(data))) stop("Variable 'qLIST_PRIORITY_ACCOUNT' not found")
  test_val <- sum(as.numeric(data[["qLIST_PRIORITY_ACCOUNT"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "qlist_priority_account", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "qlist_priority_account", error = conditionMessage(e))
})

print(paste("Validated:", "qlist_priority_account", "-", if(validation_results[["qlist_priority_account"]]$success) "PASS" else paste("FAIL:", validation_results[["qlist_priority_account"]]$error)))

# -----------------------------------------------------------------------------
# Table: qlist_tier (frequency)
# -----------------------------------------------------------------------------

validation_results[["qlist_tier"]] <- tryCatch({

  # Row 1: qLIST_TIER == 1
  if (!("qLIST_TIER" %in% names(data))) stop("Variable 'qLIST_TIER' not found")
  test_val <- sum(as.numeric(data[["qLIST_TIER"]]) == 1, na.rm = TRUE)
  # Row 2: qLIST_TIER == 2
  if (!("qLIST_TIER" %in% names(data))) stop("Variable 'qLIST_TIER' not found")
  test_val <- sum(as.numeric(data[["qLIST_TIER"]]) == 2, na.rm = TRUE)
  # Row 3: qLIST_TIER == 3
  if (!("qLIST_TIER" %in% names(data))) stop("Variable 'qLIST_TIER' not found")
  test_val <- sum(as.numeric(data[["qLIST_TIER"]]) == 3, na.rm = TRUE)
  # Row 4: qLIST_TIER == 4
  if (!("qLIST_TIER" %in% names(data))) stop("Variable 'qLIST_TIER' not found")
  test_val <- sum(as.numeric(data[["qLIST_TIER"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "qlist_tier", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "qlist_tier", error = conditionMessage(e))
})

print(paste("Validated:", "qlist_tier", "-", if(validation_results[["qlist_tier"]]$success) "PASS" else paste("FAIL:", validation_results[["qlist_tier"]]$error)))

# -----------------------------------------------------------------------------
# Table: qon_list_off_list (frequency)
# -----------------------------------------------------------------------------

validation_results[["qon_list_off_list"]] <- tryCatch({

  # Row 1: qON_LIST_OFF_LIST == 1
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 1, na.rm = TRUE)
  # Row 2: qON_LIST_OFF_LIST == 2
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 2, na.rm = TRUE)
  # Row 3: qON_LIST_OFF_LIST == 3
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 3, na.rm = TRUE)
  # Row 4: qON_LIST_OFF_LIST == 4
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 4, na.rm = TRUE)
  # Row 5: qON_LIST_OFF_LIST == 5
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 5, na.rm = TRUE)
  # Row 6: qON_LIST_OFF_LIST == 6
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 6, na.rm = TRUE)

  list(success = TRUE, tableId = "qon_list_off_list", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "qon_list_off_list", error = conditionMessage(e))
})

print(paste("Validated:", "qon_list_off_list", "-", if(validation_results[["qon_list_off_list"]]$success) "PASS" else paste("FAIL:", validation_results[["qon_list_off_list"]]$error)))

# -----------------------------------------------------------------------------
# Table: qon_list_off_list_by_provider (frequency)
# -----------------------------------------------------------------------------

validation_results[["qon_list_off_list_by_provider"]] <- tryCatch({

  # Row 1: qON_LIST_OFF_LIST == 1,2
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: qON_LIST_OFF_LIST == 1
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 1, na.rm = TRUE)
  # Row 3: qON_LIST_OFF_LIST == 2
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 2, na.rm = TRUE)
  # Row 4: qON_LIST_OFF_LIST == 3,4
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) %in% c(3, 4), na.rm = TRUE)
  # Row 5: qON_LIST_OFF_LIST == 3
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 3, na.rm = TRUE)
  # Row 6: qON_LIST_OFF_LIST == 4
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 4, na.rm = TRUE)
  # Row 7: qON_LIST_OFF_LIST == 5,6
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) %in% c(5, 6), na.rm = TRUE)
  # Row 8: qON_LIST_OFF_LIST == 5
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 5, na.rm = TRUE)
  # Row 9: qON_LIST_OFF_LIST == 6
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 6, na.rm = TRUE)

  list(success = TRUE, tableId = "qon_list_off_list_by_provider", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "qon_list_off_list_by_provider", error = conditionMessage(e))
})

print(paste("Validated:", "qon_list_off_list_by_provider", "-", if(validation_results[["qon_list_off_list_by_provider"]]$success) "PASS" else paste("FAIL:", validation_results[["qon_list_off_list_by_provider"]]$error)))

# -----------------------------------------------------------------------------
# Table: qon_list_off_list_on_vs_off (frequency)
# -----------------------------------------------------------------------------

validation_results[["qon_list_off_list_on_vs_off"]] <- tryCatch({

  # Row 1: qON_LIST_OFF_LIST == 1,3,5
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) %in% c(1, 3, 5), na.rm = TRUE)
  # Row 2: qON_LIST_OFF_LIST == 1
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 1, na.rm = TRUE)
  # Row 3: qON_LIST_OFF_LIST == 3
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 3, na.rm = TRUE)
  # Row 4: qON_LIST_OFF_LIST == 5
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 5, na.rm = TRUE)
  # Row 5: qON_LIST_OFF_LIST == 2,4,6
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) %in% c(2, 4, 6), na.rm = TRUE)
  # Row 6: qON_LIST_OFF_LIST == 2
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 2, na.rm = TRUE)
  # Row 7: qON_LIST_OFF_LIST == 4
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 4, na.rm = TRUE)
  # Row 8: qON_LIST_OFF_LIST == 6
  if (!("qON_LIST_OFF_LIST" %in% names(data))) stop("Variable 'qON_LIST_OFF_LIST' not found")
  test_val <- sum(as.numeric(data[["qON_LIST_OFF_LIST"]]) == 6, na.rm = TRUE)

  list(success = TRUE, tableId = "qon_list_off_list_on_vs_off", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "qon_list_off_list_on_vs_off", error = conditionMessage(e))
})

print(paste("Validated:", "qon_list_off_list_on_vs_off", "-", if(validation_results[["qon_list_off_list_on_vs_off"]]$success) "PASS" else paste("FAIL:", validation_results[["qon_list_off_list_on_vs_off"]]$error)))

# -----------------------------------------------------------------------------
# Table: qspecialty (frequency)
# -----------------------------------------------------------------------------

validation_results[["qspecialty"]] <- tryCatch({

  # Row 1: qSPECIALTY == 1,2
  if (!("qSPECIALTY" %in% names(data))) stop("Variable 'qSPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qSPECIALTY"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: qSPECIALTY == 1
  if (!("qSPECIALTY" %in% names(data))) stop("Variable 'qSPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qSPECIALTY"]]) == 1, na.rm = TRUE)
  # Row 3: qSPECIALTY == 2
  if (!("qSPECIALTY" %in% names(data))) stop("Variable 'qSPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qSPECIALTY"]]) == 2, na.rm = TRUE)
  # Row 4: qSPECIALTY == 3
  if (!("qSPECIALTY" %in% names(data))) stop("Variable 'qSPECIALTY' not found")
  test_val <- sum(as.numeric(data[["qSPECIALTY"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "qspecialty", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "qspecialty", error = conditionMessage(e))
})

print(paste("Validated:", "qspecialty", "-", if(validation_results[["qspecialty"]]$success) "PASS" else paste("FAIL:", validation_results[["qspecialty"]]$error)))

# -----------------------------------------------------------------------------
# Table: qtype_of_card (frequency)
# -----------------------------------------------------------------------------

validation_results[["qtype_of_card"]] <- tryCatch({

  # Row 1: qTYPE_OF_CARD == 1
  if (!("qTYPE_OF_CARD" %in% names(data))) stop("Variable 'qTYPE_OF_CARD' not found")
  test_val <- sum(as.numeric(data[["qTYPE_OF_CARD"]]) == 1, na.rm = TRUE)
  # Row 2: qTYPE_OF_CARD == 2
  if (!("qTYPE_OF_CARD" %in% names(data))) stop("Variable 'qTYPE_OF_CARD' not found")
  test_val <- sum(as.numeric(data[["qTYPE_OF_CARD"]]) == 2, na.rm = TRUE)
  # Row 3: qTYPE_OF_CARD == 3
  if (!("qTYPE_OF_CARD" %in% names(data))) stop("Variable 'qTYPE_OF_CARD' not found")
  test_val <- sum(as.numeric(data[["qTYPE_OF_CARD"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "qtype_of_card", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "qtype_of_card", error = conditionMessage(e))
})

print(paste("Validated:", "qtype_of_card", "-", if(validation_results[["qtype_of_card"]]$success) "PASS" else paste("FAIL:", validation_results[["qtype_of_card"]]$error)))

# -----------------------------------------------------------------------------
# Table: qtype_of_card_reference (frequency)
# -----------------------------------------------------------------------------

validation_results[["qtype_of_card_reference"]] <- tryCatch({

  # Row 1: Category header - Datamap values: 1=Interventional Card, 2=General Card, 3=Preventative Card (skip validation)

  list(success = TRUE, tableId = "qtype_of_card_reference", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "qtype_of_card_reference", error = conditionMessage(e))
})

print(paste("Validated:", "qtype_of_card_reference", "-", if(validation_results[["qtype_of_card_reference"]]$success) "PASS" else paste("FAIL:", validation_results[["qtype_of_card_reference"]]$error)))

# -----------------------------------------------------------------------------
# Table: region (frequency)
# -----------------------------------------------------------------------------

validation_results[["region"]] <- tryCatch({

  # Row 1: Region == 1
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 1, na.rm = TRUE)
  # Row 2: Region == 2
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 2, na.rm = TRUE)
  # Row 3: Region == 3
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 3, na.rm = TRUE)
  # Row 4: Region == 4
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 4, na.rm = TRUE)
  # Row 5: Region == 5
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 5, na.rm = TRUE)
  # Row 6: Region == 6
  if (!("Region" %in% names(data))) stop("Variable 'Region' not found")
  test_val <- sum(as.numeric(data[["Region"]]) == 6, na.rm = TRUE)

  list(success = TRUE, tableId = "region", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "region", error = conditionMessage(e))
})

print(paste("Validated:", "region", "-", if(validation_results[["region"]]$success) "PASS" else paste("FAIL:", validation_results[["region"]]$error)))

# -----------------------------------------------------------------------------
# Table: us_state (frequency)
# -----------------------------------------------------------------------------

validation_results[["us_state"]] <- tryCatch({

  # Row 1: US_State == 1
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 1, na.rm = TRUE)
  # Row 2: US_State == 2
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 2, na.rm = TRUE)
  # Row 3: US_State == 3
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 3, na.rm = TRUE)
  # Row 4: US_State == 4
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 4, na.rm = TRUE)
  # Row 5: US_State == 5
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 5, na.rm = TRUE)
  # Row 6: US_State == 6
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 6, na.rm = TRUE)
  # Row 7: US_State == 7
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 7, na.rm = TRUE)
  # Row 8: US_State == 8
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 8, na.rm = TRUE)
  # Row 9: US_State == 9
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 9, na.rm = TRUE)
  # Row 10: US_State == 10
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 10, na.rm = TRUE)
  # Row 11: US_State == 11
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 11, na.rm = TRUE)
  # Row 12: US_State == 12
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 12, na.rm = TRUE)
  # Row 13: US_State == 13
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 13, na.rm = TRUE)
  # Row 14: US_State == 14
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 14, na.rm = TRUE)
  # Row 15: US_State == 15
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 15, na.rm = TRUE)
  # Row 16: US_State == 16
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 16, na.rm = TRUE)
  # Row 17: US_State == 17
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 17, na.rm = TRUE)
  # Row 18: US_State == 18
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 18, na.rm = TRUE)
  # Row 19: US_State == 19
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 19, na.rm = TRUE)
  # Row 20: US_State == 20
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 20, na.rm = TRUE)
  # Row 21: US_State == 21
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 21, na.rm = TRUE)
  # Row 22: US_State == 22
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 22, na.rm = TRUE)
  # Row 23: US_State == 23
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 23, na.rm = TRUE)
  # Row 24: US_State == 24
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 24, na.rm = TRUE)
  # Row 25: US_State == 25
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 25, na.rm = TRUE)
  # Row 26: US_State == 26
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 26, na.rm = TRUE)
  # Row 27: US_State == 27
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 27, na.rm = TRUE)
  # Row 28: US_State == 28
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 28, na.rm = TRUE)
  # Row 29: US_State == 29
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 29, na.rm = TRUE)
  # Row 30: US_State == 30
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 30, na.rm = TRUE)
  # Row 31: US_State == 31
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 31, na.rm = TRUE)
  # Row 32: US_State == 32
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 32, na.rm = TRUE)
  # Row 33: US_State == 33
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 33, na.rm = TRUE)
  # Row 34: US_State == 34
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 34, na.rm = TRUE)
  # Row 35: US_State == 35
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 35, na.rm = TRUE)
  # Row 36: US_State == 36
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 36, na.rm = TRUE)
  # Row 37: US_State == 37
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 37, na.rm = TRUE)
  # Row 38: US_State == 38
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 38, na.rm = TRUE)
  # Row 39: US_State == 39
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 39, na.rm = TRUE)
  # Row 40: US_State == 40
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 40, na.rm = TRUE)
  # Row 41: US_State == 41
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 41, na.rm = TRUE)
  # Row 42: US_State == 42
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 42, na.rm = TRUE)
  # Row 43: US_State == 43
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 43, na.rm = TRUE)
  # Row 44: US_State == 44
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 44, na.rm = TRUE)
  # Row 45: US_State == 45
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 45, na.rm = TRUE)
  # Row 46: US_State == 46
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 46, na.rm = TRUE)
  # Row 47: US_State == 47
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 47, na.rm = TRUE)
  # Row 48: US_State == 48
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 48, na.rm = TRUE)
  # Row 49: US_State == 49
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 49, na.rm = TRUE)
  # Row 50: US_State == 50
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 50, na.rm = TRUE)
  # Row 51: US_State == 51
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 51, na.rm = TRUE)
  # Row 52: US_State == 52
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 52, na.rm = TRUE)
  # Row 53: US_State == 53
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 53, na.rm = TRUE)

  list(success = TRUE, tableId = "us_state", rowCount = 53)

}, error = function(e) {
  list(success = FALSE, tableId = "us_state", error = conditionMessage(e))
})

print(paste("Validated:", "us_state", "-", if(validation_results[["us_state"]]$success) "PASS" else paste("FAIL:", validation_results[["us_state"]]$error)))

# -----------------------------------------------------------------------------
# Table: us_state_region (frequency)
# -----------------------------------------------------------------------------

validation_results[["us_state_region"]] <- tryCatch({

  # Row 1: US_State == 7,20,22,31,32,35,39,40,47
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) %in% c(7, 20, 22, 31, 32, 35, 39, 40, 47), na.rm = TRUE)
  # Row 2: US_State == 13,15,16,17,23,24,25,29,30,36,42,49
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) %in% c(13, 15, 16, 17, 23, 24, 25, 29, 30, 36, 42, 49), na.rm = TRUE)
  # Row 3: US_State == 2,3,8,9,10,11,18,19,21,26,28,37,41,43,44,46,50
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) %in% c(2, 3, 8, 9, 10, 11, 18, 19, 21, 26, 28, 37, 41, 43, 44, 46, 50), na.rm = TRUE)
  # Row 4: US_State == 1,4,5,6,12,14,27,33,34,38,45,48,51
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) %in% c(1, 4, 5, 6, 12, 14, 27, 33, 34, 38, 45, 48, 51), na.rm = TRUE)
  # Row 5: US_State == 52
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 52, na.rm = TRUE)
  # Row 6: US_State == 53
  if (!("US_State" %in% names(data))) stop("Variable 'US_State' not found")
  test_val <- sum(as.numeric(data[["US_State"]]) == 53, na.rm = TRUE)

  list(success = TRUE, tableId = "us_state_region", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "us_state_region", error = conditionMessage(e))
})

print(paste("Validated:", "us_state_region", "-", if(validation_results[["us_state_region"]]$success) "PASS" else paste("FAIL:", validation_results[["us_state_region"]]$error)))

# =============================================================================
# Write Validation Results
# =============================================================================

write_json(validation_results, "validation/validation-results.json", pretty = TRUE, auto_unbox = TRUE)
print(paste("Validation results written to:", "validation/validation-results.json"))

# Summary
success_count <- sum(sapply(validation_results, function(x) x$success))
fail_count <- length(validation_results) - success_count
print(paste("Validation complete:", success_count, "passed,", fail_count, "failed"))