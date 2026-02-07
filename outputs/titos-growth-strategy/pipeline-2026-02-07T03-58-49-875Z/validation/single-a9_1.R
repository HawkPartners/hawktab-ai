# HawkTab AI - Single Table Validation
# Table: a9_1
# Generated: 2026-02-07T04:25:06.999Z

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
# Table: a9_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a9_1"]] <- tryCatch({

  # Row 1: Category header - Who was with you when you had this drink: (skip validation)
  # Row 2: A9r1 == 1
  if (!("A9r1" %in% names(data))) stop("Variable 'A9r1' not found")
  test_val <- sum(as.numeric(data[["A9r1"]]) == 1, na.rm = TRUE)
  # Row 3: NET - Not alone (NET)
  if (!("A9r2" %in% names(data))) stop("NET component variable 'A9r2' not found")
  if (!("A9r3" %in% names(data))) stop("NET component variable 'A9r3' not found")
  if (!("A9r4" %in% names(data))) stop("NET component variable 'A9r4' not found")
  if (!("A9r5" %in% names(data))) stop("NET component variable 'A9r5' not found")
  if (!("A9r6" %in% names(data))) stop("NET component variable 'A9r6' not found")
  if (!("A9r7" %in% names(data))) stop("NET component variable 'A9r7' not found")
  # Row 4: A9r2 == 1
  if (!("A9r2" %in% names(data))) stop("Variable 'A9r2' not found")
  test_val <- sum(as.numeric(data[["A9r2"]]) == 1, na.rm = TRUE)
  # Row 5: A9r3 == 1
  if (!("A9r3" %in% names(data))) stop("Variable 'A9r3' not found")
  test_val <- sum(as.numeric(data[["A9r3"]]) == 1, na.rm = TRUE)
  # Row 6: A9r4 == 1
  if (!("A9r4" %in% names(data))) stop("Variable 'A9r4' not found")
  test_val <- sum(as.numeric(data[["A9r4"]]) == 1, na.rm = TRUE)
  # Row 7: A9r5 == 1
  if (!("A9r5" %in% names(data))) stop("Variable 'A9r5' not found")
  test_val <- sum(as.numeric(data[["A9r5"]]) == 1, na.rm = TRUE)
  # Row 8: A9r6 == 1
  if (!("A9r6" %in% names(data))) stop("Variable 'A9r6' not found")
  test_val <- sum(as.numeric(data[["A9r6"]]) == 1, na.rm = TRUE)
  # Row 9: A9r7 == 1
  if (!("A9r7" %in% names(data))) stop("Variable 'A9r7' not found")
  test_val <- sum(as.numeric(data[["A9r7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a9_1", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_1", error = conditionMessage(e))
})

print(paste("Validated:", "a9_1", "-", if(validation_results[["a9_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_1"]]$error)))

write_json(validation_results, "validation/single-a9_1-result.json", pretty = TRUE, auto_unbox = TRUE)