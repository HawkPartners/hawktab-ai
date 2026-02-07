# HawkTab AI - Single Table Validation
# Table: a16_1
# Generated: 2026-02-07T04:22:10.789Z

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
# Table: a16_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a16_1"]] <- tryCatch({

  # Row 1: NET - Any purchase reason (NET)
  if (!("A16r1" %in% names(data))) stop("NET component variable 'A16r1' not found")
  if (!("A16r2" %in% names(data))) stop("NET component variable 'A16r2' not found")
  if (!("A16r3" %in% names(data))) stop("NET component variable 'A16r3' not found")
  if (!("A16r4" %in% names(data))) stop("NET component variable 'A16r4' not found")
  if (!("A16r5" %in% names(data))) stop("NET component variable 'A16r5' not found")
  if (!("A16r6" %in% names(data))) stop("NET component variable 'A16r6' not found")
  if (!("A16r7" %in% names(data))) stop("NET component variable 'A16r7' not found")
  if (!("A16r8" %in% names(data))) stop("NET component variable 'A16r8' not found")
  if (!("A16r9" %in% names(data))) stop("NET component variable 'A16r9' not found")
  if (!("A16r10" %in% names(data))) stop("NET component variable 'A16r10' not found")
  # Row 2: A16r1 == 1
  if (!("A16r1" %in% names(data))) stop("Variable 'A16r1' not found")
  test_val <- sum(as.numeric(data[["A16r1"]]) == 1, na.rm = TRUE)
  # Row 3: A16r2 == 1
  if (!("A16r2" %in% names(data))) stop("Variable 'A16r2' not found")
  test_val <- sum(as.numeric(data[["A16r2"]]) == 1, na.rm = TRUE)
  # Row 4: A16r3 == 1
  if (!("A16r3" %in% names(data))) stop("Variable 'A16r3' not found")
  test_val <- sum(as.numeric(data[["A16r3"]]) == 1, na.rm = TRUE)
  # Row 5: A16r4 == 1
  if (!("A16r4" %in% names(data))) stop("Variable 'A16r4' not found")
  test_val <- sum(as.numeric(data[["A16r4"]]) == 1, na.rm = TRUE)
  # Row 6: A16r5 == 1
  if (!("A16r5" %in% names(data))) stop("Variable 'A16r5' not found")
  test_val <- sum(as.numeric(data[["A16r5"]]) == 1, na.rm = TRUE)
  # Row 7: A16r6 == 1
  if (!("A16r6" %in% names(data))) stop("Variable 'A16r6' not found")
  test_val <- sum(as.numeric(data[["A16r6"]]) == 1, na.rm = TRUE)
  # Row 8: A16r7 == 1
  if (!("A16r7" %in% names(data))) stop("Variable 'A16r7' not found")
  test_val <- sum(as.numeric(data[["A16r7"]]) == 1, na.rm = TRUE)
  # Row 9: A16r8 == 1
  if (!("A16r8" %in% names(data))) stop("Variable 'A16r8' not found")
  test_val <- sum(as.numeric(data[["A16r8"]]) == 1, na.rm = TRUE)
  # Row 10: A16r9 == 1
  if (!("A16r9" %in% names(data))) stop("Variable 'A16r9' not found")
  test_val <- sum(as.numeric(data[["A16r9"]]) == 1, na.rm = TRUE)
  # Row 11: A16r10 == 1
  if (!("A16r10" %in% names(data))) stop("Variable 'A16r10' not found")
  test_val <- sum(as.numeric(data[["A16r10"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a16_1", rowCount = 11)

}, error = function(e) {
  list(success = FALSE, tableId = "a16_1", error = conditionMessage(e))
})

print(paste("Validated:", "a16_1", "-", if(validation_results[["a16_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a16_1"]]$error)))

write_json(validation_results, "validation/single-a16_1-result.json", pretty = TRUE, auto_unbox = TRUE)