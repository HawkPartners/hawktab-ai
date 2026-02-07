# HawkTab AI - Single Table Validation
# Table: a2
# Generated: 2026-02-07T04:10:12.200Z

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
# Table: a2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a2"]] <- tryCatch({

  # Row 1: A2 == 1,2
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A2 == 1
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 1, na.rm = TRUE)
  # Row 3: A2 == 2
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 2, na.rm = TRUE)
  # Row 4: A2 == 3,4
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) %in% c(3, 4), na.rm = TRUE)
  # Row 5: A2 == 3
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 3, na.rm = TRUE)
  # Row 6: A2 == 4
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 4, na.rm = TRUE)
  # Row 7: A2 == 5,6,7
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) %in% c(5, 6, 7), na.rm = TRUE)
  # Row 8: A2 == 5
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 5, na.rm = TRUE)
  # Row 9: A2 == 6
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 6, na.rm = TRUE)
  # Row 10: A2 == 7
  if (!("A2" %in% names(data))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(data[["A2"]]) == 7, na.rm = TRUE)

  list(success = TRUE, tableId = "a2", rowCount = 10)

}, error = function(e) {
  list(success = FALSE, tableId = "a2", error = conditionMessage(e))
})

print(paste("Validated:", "a2", "-", if(validation_results[["a2"]]$success) "PASS" else paste("FAIL:", validation_results[["a2"]]$error)))

write_json(validation_results, "validation/single-a2-result.json", pretty = TRUE, auto_unbox = TRUE)