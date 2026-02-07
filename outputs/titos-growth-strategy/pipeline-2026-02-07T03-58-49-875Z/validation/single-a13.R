# HawkTab AI - Single Table Validation
# Table: a13
# Generated: 2026-02-07T04:19:41.857Z

library(haven)
library(dplyr)
library(jsonlite)

data <- read_sav("dataFile.sav")

# Cuts Definition (minimal for validation)
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
,  `Own Home` = with(data, hLOCATION1 == 1)
,  `Others' Home` = with(data, hLOCATION1 == 2)
,  `Work / Office` = with(data, hLOCATION1 == 3)
,  `College Dorm` = with(data, hLOCATION1 == 4)
,  `Dining` = with(data, hLOCATION1 %in% c(5,6,7))
,  `Bar / Nightclub` = with(data, hLOCATION1 %in% c(8,9,10,11))
,  `Hotel / Motel` = with(data, hLOCATION1 == 12)
,  `Recreation / Entertainment / Concession` = with(data, hLOCATION1 %in% c(13,14))
,  `Outdoor Gathering` = with(data, hLOCATION1 == 15)
,  `Airport / Transit Location` = with(data, hLOCATION1 == 16)
,  `Other` = with(data, hLOCATION1 == 99)
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

validation_results <- list()

# -----------------------------------------------------------------------------
# Table: a13 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a13"]] <- tryCatch({

  # Row 1: A13 == 1
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 1, na.rm = TRUE)
  # Row 2: A13 == 2
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 2, na.rm = TRUE)
  # Row 3: A13 == 3
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 3, na.rm = TRUE)
  # Row 4: A13 == 4
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 4, na.rm = TRUE)
  # Row 5: A13 == 5
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 5, na.rm = TRUE)
  # Row 6: A13 == 6
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 6, na.rm = TRUE)
  # Row 7: A13 == 7
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 7, na.rm = TRUE)
  # Row 8: A13 == 8
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 8, na.rm = TRUE)
  # Row 9: A13 == 9
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 9, na.rm = TRUE)
  # Row 10: A13 == 10
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 10, na.rm = TRUE)
  # Row 11: A13 == 11
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 11, na.rm = TRUE)
  # Row 12: A13 == 12
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 12, na.rm = TRUE)
  # Row 13: A13 == 13
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 13, na.rm = TRUE)
  # Row 14: A13 == 14
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 14, na.rm = TRUE)
  # Row 15: A13 == 15
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 15, na.rm = TRUE)
  # Row 16: A13 == 16
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 16, na.rm = TRUE)
  # Row 17: A13 == 17
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 17, na.rm = TRUE)
  # Row 18: A13 == 18
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 18, na.rm = TRUE)
  # Row 19: A13 == 19
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 19, na.rm = TRUE)
  # Row 20: A13 == 20
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 20, na.rm = TRUE)
  # Row 21: A13 == 21
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 21, na.rm = TRUE)
  # Row 22: A13 == 22
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 22, na.rm = TRUE)
  # Row 23: A13 == 23
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 23, na.rm = TRUE)
  # Row 24: A13 == 24
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 24, na.rm = TRUE)
  # Row 25: A13 == 25
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 25, na.rm = TRUE)
  # Row 26: A13 == 26
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 26, na.rm = TRUE)
  # Row 27: A13 == 27
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 27, na.rm = TRUE)
  # Row 28: A13 == 28
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 28, na.rm = TRUE)
  # Row 29: A13 == 29
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 29, na.rm = TRUE)
  # Row 30: A13 == 30
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 30, na.rm = TRUE)
  # Row 31: A13 == 31
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 31, na.rm = TRUE)
  # Row 32: A13 == 32
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 32, na.rm = TRUE)
  # Row 33: A13 == 33
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 33, na.rm = TRUE)
  # Row 34: A13 == 34
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 34, na.rm = TRUE)
  # Row 35: A13 == 35
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 35, na.rm = TRUE)
  # Row 36: A13 == 36
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 36, na.rm = TRUE)
  # Row 37: A13 == 37
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 37, na.rm = TRUE)
  # Row 38: A13 == 38
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 38, na.rm = TRUE)
  # Row 39: A13 == 39
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 39, na.rm = TRUE)
  # Row 40: A13 == 40
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 40, na.rm = TRUE)
  # Row 41: A13 == 41
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 41, na.rm = TRUE)
  # Row 42: A13 == 42
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 42, na.rm = TRUE)
  # Row 43: A13 == 43
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 43, na.rm = TRUE)
  # Row 44: A13 == 44
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 44, na.rm = TRUE)
  # Row 45: A13 == 45
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 45, na.rm = TRUE)
  # Row 46: A13 == 46
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 46, na.rm = TRUE)
  # Row 47: A13 == 47
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 47, na.rm = TRUE)
  # Row 48: A13 == 48
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 48, na.rm = TRUE)
  # Row 49: A13 == 49
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 49, na.rm = TRUE)
  # Row 50: A13 == 50
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 50, na.rm = TRUE)
  # Row 51: A13 == 51
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 51, na.rm = TRUE)
  # Row 52: A13 == 52
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 52, na.rm = TRUE)
  # Row 53: A13 == 53
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 53, na.rm = TRUE)
  # Row 54: A13 == 54
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 54, na.rm = TRUE)
  # Row 55: A13 == 55
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 55, na.rm = TRUE)
  # Row 56: A13 == 56
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 56, na.rm = TRUE)
  # Row 57: A13 == 57
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 57, na.rm = TRUE)
  # Row 58: A13 == 58
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 58, na.rm = TRUE)
  # Row 59: A13 == 59
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 59, na.rm = TRUE)
  # Row 60: A13 == 60
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 60, na.rm = TRUE)
  # Row 61: A13 == 61
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 61, na.rm = TRUE)
  # Row 62: A13 == 62
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 62, na.rm = TRUE)
  # Row 63: A13 == 63
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 63, na.rm = TRUE)
  # Row 64: A13 == 64
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 64, na.rm = TRUE)
  # Row 65: A13 == 65
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 65, na.rm = TRUE)
  # Row 66: A13 == 66
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 66, na.rm = TRUE)
  # Row 67: A13 == 67
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 67, na.rm = TRUE)
  # Row 68: A13 == 68
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 68, na.rm = TRUE)
  # Row 69: A13 == 69
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 69, na.rm = TRUE)
  # Row 70: A13 == 70
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 70, na.rm = TRUE)
  # Row 71: A13 == 98
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 98, na.rm = TRUE)
  # Row 72: A13 == 99
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 99, na.rm = TRUE)
  # Row 73: A13 == 100
  if (!("A13" %in% names(data))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(data[["A13"]]) == 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a13", rowCount = 73)

}, error = function(e) {
  list(success = FALSE, tableId = "a13", error = conditionMessage(e))
})

print(paste("Validated:", "a13", "-", if(validation_results[["a13"]]$success) "PASS" else paste("FAIL:", validation_results[["a13"]]$error)))

write_json(validation_results, "validation/single-a13-result.json", pretty = TRUE, auto_unbox = TRUE)