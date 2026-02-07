# HawkTab AI - Single Table Validation
# Table: a13b_1
# Generated: 2026-02-07T04:21:25.629Z

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
# Table: a13b_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a13b_1"]] <- tryCatch({

  # Row 1: NET - Any other drinks (NET)
  if (!("A13br1" %in% names(data))) stop("NET component variable 'A13br1' not found")
  if (!("A13br2" %in% names(data))) stop("NET component variable 'A13br2' not found")
  if (!("A13br3" %in% names(data))) stop("NET component variable 'A13br3' not found")
  if (!("A13br4" %in% names(data))) stop("NET component variable 'A13br4' not found")
  if (!("A13br5" %in% names(data))) stop("NET component variable 'A13br5' not found")
  # Row 2: A13br1 == 1
  if (!("A13br1" %in% names(data))) stop("Variable 'A13br1' not found")
  test_val <- sum(as.numeric(data[["A13br1"]]) == 1, na.rm = TRUE)
  # Row 3: A13br2 == 1
  if (!("A13br2" %in% names(data))) stop("Variable 'A13br2' not found")
  test_val <- sum(as.numeric(data[["A13br2"]]) == 1, na.rm = TRUE)
  # Row 4: A13br3 == 1
  if (!("A13br3" %in% names(data))) stop("Variable 'A13br3' not found")
  test_val <- sum(as.numeric(data[["A13br3"]]) == 1, na.rm = TRUE)
  # Row 5: A13br4 == 1
  if (!("A13br4" %in% names(data))) stop("Variable 'A13br4' not found")
  test_val <- sum(as.numeric(data[["A13br4"]]) == 1, na.rm = TRUE)
  # Row 6: A13br5 == 1
  if (!("A13br5" %in% names(data))) stop("Variable 'A13br5' not found")
  test_val <- sum(as.numeric(data[["A13br5"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a13b_1", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "a13b_1", error = conditionMessage(e))
})

print(paste("Validated:", "a13b_1", "-", if(validation_results[["a13b_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a13b_1"]]$error)))

write_json(validation_results, "validation/single-a13b_1-result.json", pretty = TRUE, auto_unbox = TRUE)