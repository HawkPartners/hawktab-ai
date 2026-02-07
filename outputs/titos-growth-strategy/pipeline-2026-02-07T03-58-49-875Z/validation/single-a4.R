# HawkTab AI - Single Table Validation
# Table: a4
# Generated: 2026-02-07T04:11:35.034Z

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
# Table: a4 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a4"]] <- tryCatch({

  # Row 1: A4 == 1
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 1, na.rm = TRUE)
  # Row 2: A4 == 2
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 2, na.rm = TRUE)
  # Row 3: A4 == 3
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 3, na.rm = TRUE)
  # Row 4: A4 == 4
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 4, na.rm = TRUE)
  # Row 5: A4 == 5,6
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) %in% c(5, 6), na.rm = TRUE)
  # Row 6: A4 == 5
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 5, na.rm = TRUE)
  # Row 7: A4 == 6
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 6, na.rm = TRUE)
  # Row 8: A4 == 7,8,9,10,11,12,13,14
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) %in% c(7, 8, 9, 10, 11, 12, 13, 14), na.rm = TRUE)
  # Row 9: A4 == 7
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 7, na.rm = TRUE)
  # Row 10: A4 == 8
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 8, na.rm = TRUE)
  # Row 11: A4 == 9
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 9, na.rm = TRUE)
  # Row 12: A4 == 10
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 10, na.rm = TRUE)
  # Row 13: A4 == 11
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 11, na.rm = TRUE)
  # Row 14: A4 == 12
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 12, na.rm = TRUE)
  # Row 15: A4 == 13
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 13, na.rm = TRUE)
  # Row 16: A4 == 14
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 14, na.rm = TRUE)
  # Row 17: A4 == 15
  if (!("A4" %in% names(data))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(data[["A4"]]) == 15, na.rm = TRUE)

  list(success = TRUE, tableId = "a4", rowCount = 17)

}, error = function(e) {
  list(success = FALSE, tableId = "a4", error = conditionMessage(e))
})

print(paste("Validated:", "a4", "-", if(validation_results[["a4"]]$success) "PASS" else paste("FAIL:", validation_results[["a4"]]$error)))

write_json(validation_results, "validation/single-a4-result.json", pretty = TRUE, auto_unbox = TRUE)