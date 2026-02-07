# HawkTab AI - Single Table Validation
# Table: a3
# Generated: 2026-02-07T05:52:05.709Z

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
# Table: a3 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a3"]] <- tryCatch({

  # Row 1: A3 == 1,2,3,4
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) %in% c(1, 2, 3, 4), na.rm = TRUE)
  # Row 2: A3 == 1
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 1, na.rm = TRUE)
  # Row 3: A3 == 2
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 2, na.rm = TRUE)
  # Row 4: A3 == 3
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 3, na.rm = TRUE)
  # Row 5: A3 == 4
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 4, na.rm = TRUE)
  # Row 6: A3 == 5,6,7
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) %in% c(5, 6, 7), na.rm = TRUE)
  # Row 7: A3 == 5
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 5, na.rm = TRUE)
  # Row 8: A3 == 6
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 6, na.rm = TRUE)
  # Row 9: A3 == 7
  if (!("A3" %in% names(data))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(data[["A3"]]) == 7, na.rm = TRUE)

  list(success = TRUE, tableId = "a3", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "a3", error = conditionMessage(e))
})

print(paste("Validated:", "a3", "-", if(validation_results[["a3"]]$success) "PASS" else paste("FAIL:", validation_results[["a3"]]$error)))

write_json(validation_results, "validation/single-a3-result.json", pretty = TRUE, auto_unbox = TRUE)