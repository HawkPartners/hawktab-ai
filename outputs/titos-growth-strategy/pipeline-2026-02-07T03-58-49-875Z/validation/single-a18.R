# HawkTab AI - Single Table Validation
# Table: a18
# Generated: 2026-02-07T04:20:52.195Z

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
# Table: a18 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a18"]] <- tryCatch({

  # Row 1: A18 == 1
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 1, na.rm = TRUE)
  # Row 2: A18 == 2
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 2, na.rm = TRUE)
  # Row 3: A18 == 3
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 3, na.rm = TRUE)
  # Row 4: A18 == 4
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 4, na.rm = TRUE)
  # Row 5: A18 == 5
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 5, na.rm = TRUE)
  # Row 6: A18 == 6
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 6, na.rm = TRUE)
  # Row 7: A18 == 7
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 7, na.rm = TRUE)
  # Row 8: A18 == 8
  if (!("A18" %in% names(data))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(data[["A18"]]) == 8, na.rm = TRUE)

  list(success = TRUE, tableId = "a18", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a18", error = conditionMessage(e))
})

print(paste("Validated:", "a18", "-", if(validation_results[["a18"]]$success) "PASS" else paste("FAIL:", validation_results[["a18"]]$error)))

write_json(validation_results, "validation/single-a18-result.json", pretty = TRUE, auto_unbox = TRUE)