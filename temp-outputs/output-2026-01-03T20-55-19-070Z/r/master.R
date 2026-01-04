# HawkTab AI - Generated R Script
# Session: output-2026-01-03T20-55-19-070Z
# Generated: 2026-01-03T20:58:06.237Z
# Tables: 75
# Cuts: 20

# Load required libraries
library(haven)
library(dplyr)
# library(tidyr) # Optional - not used in current implementation

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

# Define cuts
cuts <- list(
  Total = rep(TRUE, nrow(data))
,  `Cards` = with(data, (S2 == 1 | S2a == 1))
,  `PCPs` = with(data, S2 == 2)
,  `Nephs` = with(data, S2 == 3)
,  `Endos` = with(data, S2 == 4)
,  `Lipids` = with(data, S2 == 5)
,  `Physician` = with(data, S2b == 1)
,  `NP/PA` = with(data, S2b %in% c(2, 3))
,  `Higher` = with(data, S11 >= median(S11, na.rm = TRUE))
,  `Lower` = with(data, S11 < median(S11, na.rm = TRUE))
,  `Tier 1` = with(data, qLIST_TIER == 1)
,  `Tier 2` = with(data, qLIST_TIER == 2)
,  `Tier 3` = with(data, qLIST_TIER == 3)
,  `Tier 4` = with(data, qLIST_TIER == 4)
,  `Segment A` = with(data, Segment == "Segment A")
,  `Segment B` = with(data, Segment == "Segment B")
,  `Segment C` = with(data, Segment == "Segment C")
,  `Segment D` = with(data, Segment == "Segment D")
,  `Priority Account` = with(data, qLIST_PRIORITY_ACCOUNT == 1)
,  `Non-Priority Account` = with(data, qLIST_PRIORITY_ACCOUNT == 2)
,  `Total` = with(data, TRUE)
)

# Helper function for percentage calculation (rounded to whole number, half up)
calc_pct <- function(x, base) {
  if (base == 0) return(0)
  floor(100 * x / base + 0.5)  # Round half up (12.5 -> 13)
}

# Helper function for rounding (half up: 12.5 -> 13, not banker's rounding)
round_half_up <- function(x, digits = 0) {
  floor(x * 10^digits + 0.5) / 10^digits
}

# Helper function to safely apply cuts (NA in cut expression = exclude)
apply_cut <- function(data, cut_mask) {
  safe_mask <- cut_mask
  safe_mask[is.na(safe_mask)] <- FALSE
  data[safe_mask, ]
}

# Generate crosstab tables
results <- list()

# Table: You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential. Are you happy to proceed on this basis?
# Variable: S1
tryCatch({
  if ("S1" %in% names(data)) {
    levels <- c("I would like to proceed and protect my identity", "I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey", "I don�t want to proceed")
    values <- c(1, 2, 3)
    table_s1 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S1`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S1` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s1[[cut_name]] <- col_data
    }
    results[["s1"]] <- table_s1
    print(paste("✓ Generated table: You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential. Are you happy to proceed on this basis?"))
  } else {
    print(paste("⚠ Warning: Variable 'S1' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential. Are you happy to proceed on this basis?':", e$message))
})

# Table: What is your primary role?
# Variable: S2b
tryCatch({
  if ("S2b" %in% names(data)) {
    levels <- c("Physician", "Nurse Practitioner", "Physician�s Assistant", "Other")
    values <- c(1, 2, 3, 99)
    table_s2b <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S2b`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S2b` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s2b[[cut_name]] <- col_data
    }
    results[["s2b"]] <- table_s2b
    print(paste("✓ Generated table: What is your primary role?"))
  } else {
    print(paste("⚠ Warning: Variable 'S2b' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'What is your primary role?':", e$message))
})

# Table: What is your primary specialty?
# Variable: S2
tryCatch({
  if ("S2" %in% names(data)) {
    levels <- c("Cardiologist", "Internal Medicine / General Practitioner / Primary Care / Family Practice", "Nephrologist", "Endocrinologist", "Lipidologist", "Nurse Practitioner", "Physician�s Assistant", "Other")
    values <- c(1, 2, 3, 4, 5, 6, 7, 99)
    table_s2 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S2`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S2` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s2[[cut_name]] <- col_data
    }
    results[["s2"]] <- table_s2
    print(paste("✓ Generated table: What is your primary specialty?"))
  } else {
    print(paste("⚠ Warning: Variable 'S2' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'What is your primary specialty?':", e$message))
})

# Table: In what type of doctor�s office do you work?
# Variable: S2a
tryCatch({
  if ("S2a" %in% names(data)) {
    levels <- c("Cardiologist", "Internal Medicine / General Practitioner / Primary Care / Family Practice", "Other")
    values <- c(1, 2, 3)
    table_s2a <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S2a`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S2a` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s2a[[cut_name]] <- col_data
    }
    results[["s2a"]] <- table_s2a
    print(paste("✓ Generated table: In what type of doctor�s office do you work?"))
  } else {
    print(paste("⚠ Warning: Variable 'S2a' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'In what type of doctor�s office do you work?':", e$message))
})

# Table: CARD SPECIALTY
# Variable: qCARD_SPECIALTY
tryCatch({
  if ("qCARD_SPECIALTY" %in% names(data)) {
    levels <- c("CARD", "NEPH/ENDO/LIP")
    values <- c(1, 2)
    table_qcard_specialty <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qCARD_SPECIALTY`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qCARD_SPECIALTY` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qcard_specialty[[cut_name]] <- col_data
    }
    results[["qcard_specialty"]] <- table_qcard_specialty
    print(paste("✓ Generated table: CARD SPECIALTY"))
  } else {
    print(paste("⚠ Warning: Variable 'qCARD_SPECIALTY' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'CARD SPECIALTY':", e$message))
})

# Table: SPECIALTY
# Variable: qSPECIALTY
tryCatch({
  if ("qSPECIALTY" %in% names(data)) {
    levels <- c("CARD", "PCP", "NPPA")
    values <- c(1, 2, 3)
    table_qspecialty <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qSPECIALTY`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qSPECIALTY` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qspecialty[[cut_name]] <- col_data
    }
    results[["qspecialty"]] <- table_qspecialty
    print(paste("✓ Generated table: SPECIALTY"))
  } else {
    print(paste("⚠ Warning: Variable 'qSPECIALTY' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'SPECIALTY':", e$message))
})

# Table: What type of Cardiologist are you primarily?
# Variable: S3a
tryCatch({
  if ("S3a" %in% names(data)) {
    levels <- c("Interventional Cardiologist", "General Cardiologist", "Preventative Cardiologist")
    values <- c(1, 2, 3)
    table_s3a <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S3a`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S3a` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s3a[[cut_name]] <- col_data
    }
    results[["s3a"]] <- table_s3a
    print(paste("✓ Generated table: What type of Cardiologist are you primarily?"))
  } else {
    print(paste("⚠ Warning: Variable 'S3a' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'What type of Cardiologist are you primarily?':", e$message))
})

# Table: TYPE OF CARD
# Variable: qTYPE_OF_CARD
tryCatch({
  if ("qTYPE_OF_CARD" %in% names(data)) {
    levels <- c("Interventional Card", "General Card", "Preventative Card")
    values <- c(1, 2, 3)
    table_qtype_of_card <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qTYPE_OF_CARD`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qTYPE_OF_CARD` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qtype_of_card[[cut_name]] <- col_data
    }
    results[["qtype_of_card"]] <- table_qtype_of_card
    print(paste("✓ Generated table: TYPE OF CARD"))
  } else {
    print(paste("⚠ Warning: Variable 'qTYPE_OF_CARD' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'TYPE OF CARD':", e$message))
})

# Table: ON-LIST/OFF-LIST
# Variable: qON_LIST_OFF_LIST
tryCatch({
  if ("qON_LIST_OFF_LIST" %in% names(data)) {
    levels <- c("CARD ON-LIST", "CARD OFF-LIST", "PCP ON-LIST", "PCP OFF-LIST", "NPPA ON-LIST", "NPPA OFF-LIST")
    values <- c(1, 2, 3, 4, 5, 6)
    table_qon_list_off_list <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qON_LIST_OFF_LIST`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qON_LIST_OFF_LIST` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qon_list_off_list[[cut_name]] <- col_data
    }
    results[["qon_list_off_list"]] <- table_qon_list_off_list
    print(paste("✓ Generated table: ON-LIST/OFF-LIST"))
  } else {
    print(paste("⚠ Warning: Variable 'qON_LIST_OFF_LIST' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'ON-LIST/OFF-LIST':", e$message))
})

# Table: LIST TIER
# Variable: qLIST_TIER
tryCatch({
  if ("qLIST_TIER" %in% names(data)) {
    levels <- c("TIER 1", "TIER 2", "TIER 3", "TIER 4")
    values <- c(1, 2, 3, 4)
    table_qlist_tier <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qLIST_TIER`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qLIST_TIER` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qlist_tier[[cut_name]] <- col_data
    }
    results[["qlist_tier"]] <- table_qlist_tier
    print(paste("✓ Generated table: LIST TIER"))
  } else {
    print(paste("⚠ Warning: Variable 'qLIST_TIER' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'LIST TIER':", e$message))
})

# Table: LIST PRIORITY ACCOUNT
# Variable: qLIST_PRIORITY_ACCOUNT
tryCatch({
  if ("qLIST_PRIORITY_ACCOUNT" %in% names(data)) {
    levels <- c("PRIORITY", "NOT PRIORITY")
    values <- c(1, 2)
    table_qlist_priority_account <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`qLIST_PRIORITY_ACCOUNT`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qLIST_PRIORITY_ACCOUNT` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qlist_priority_account[[cut_name]] <- col_data
    }
    results[["qlist_priority_account"]] <- table_qlist_priority_account
    print(paste("✓ Generated table: LIST PRIORITY ACCOUNT"))
  } else {
    print(paste("⚠ Warning: Variable 'qLIST_PRIORITY_ACCOUNT' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'LIST PRIORITY ACCOUNT':", e$message))
})

# Table: Are you currently board certified or eligible in your specialty?
# Variable: S4
tryCatch({
  if ("S4" %in% names(data)) {
    levels <- c("Board Eligible", "Board Certified", "Neither")
    values <- c(1, 2, 3)
    table_s4 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S4`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S4` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s4[[cut_name]] <- col_data
    }
    results[["s4"]] <- table_s4
    print(paste("✓ Generated table: Are you currently board certified or eligible in your specialty?"))
  } else {
    print(paste("⚠ Warning: Variable 'S4' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Are you currently board certified or eligible in your specialty?':", e$message))
})

# Table: How many years have you been in clinical practice, post residency/training?
# Variable: S6
tryCatch({
  if ("S6" %in% names(data)) {
    # Smart bucketing for numeric variable S6
    var_data <- data$`S6`[!is.na(data$`S6`)]
    if (length(var_data) > 0) {
      var_min <- min(var_data)
      var_max <- max(var_data)
      var_median <- median(var_data)
      var_range <- var_max - var_min
      
      # Determine nice rounding unit based on range
      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100
      
      # Round midpoint to nice number
      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit
      
      # Create 4 bucket boundaries (2 below midpoint, 2 above)
      lower_half_size <- midpoint - var_min
      upper_half_size <- var_max - midpoint
      
      # Calculate sub-bucket boundaries
      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit
      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit
      
      # Ensure boundaries are distinct
      if (lower_mid <= var_min) lower_mid <- var_min + round_unit
      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit
      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit
      if (upper_mid >= var_max) upper_mid <- var_max - round_unit
      
      # Create bucket labels
      bucket_labels <- c(
        paste0(midpoint, " or Less (Total)"),
        paste0("  ", var_min, " - ", lower_mid - 1),
        paste0("  ", lower_mid, " - ", midpoint),
        paste0("More Than ", midpoint, " (Total)"),
        paste0("  ", midpoint + 1, " - ", upper_mid),
        paste0("  ", upper_mid + 1, "+"),
        "Mean (overall)",
        "Mean (minus outliers)",
        "Median (overall)"
      )
      
      table_s6 <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)
      
      for (cut_name in names(cuts)) {
        cut_data <- apply_cut(data, cuts[[cut_name]])
        cut_var <- cut_data$`S6`
        valid_n <- sum(!is.na(cut_var))
        
        # Calculate bucket counts
        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)
        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)
        lower_total <- bucket1_count + bucket2_count
        
        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)
        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)
        upper_total <- bucket3_count + bucket4_count
        
        # Calculate percentages
        lower_total_pct <- calc_pct(lower_total, valid_n)
        bucket1_pct <- calc_pct(bucket1_count, valid_n)
        bucket2_pct <- calc_pct(bucket2_count, valid_n)
        upper_total_pct <- calc_pct(upper_total, valid_n)
        bucket3_pct <- calc_pct(bucket3_count, valid_n)
        bucket4_pct <- calc_pct(bucket4_count, valid_n)
        
        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 1)
        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 1)
        
        # Calculate mean minus outliers using IQR method
        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)
        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]
        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 1) else mean_val
        
        table_s6[[cut_name]] <- c(
          paste0(lower_total_pct, "% (", lower_total, ")"),
          paste0(bucket1_pct, "% (", bucket1_count, ")"),
          paste0(bucket2_pct, "% (", bucket2_count, ")"),
          paste0(upper_total_pct, "% (", upper_total, ")"),
          paste0(bucket3_pct, "% (", bucket3_count, ")"),
          paste0(bucket4_pct, "% (", bucket4_count, ")"),
          mean_val,
          mean_minus_outliers,
          median_val
        )
      }
    } else {
      # Fallback if no valid data
      table_s6 <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)
      for (cut_name in names(cuts)) {
        table_s6[[cut_name]] <- c("0", "N/A", "N/A")
      }
    }
    results[["s6"]] <- table_s6
    print(paste("✓ Generated table: How many years have you been in clinical practice, post residency/training?"))
  } else {
    print(paste("⚠ Warning: Variable 'S6' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'How many years have you been in clinical practice, post residency/training?':", e$message))
})

# Table: And to confirm, are you currently practicing full-time (i.e. 40+ hours weekly across all settings) or part-time?
# Variable: S7
tryCatch({
  if ("S7" %in% names(data)) {
    levels <- c("Full-Time", "Part-Time")
    values <- c(1, 2)
    table_s7 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S7`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S7` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s7[[cut_name]] <- col_data
    }
    results[["s7"]] <- table_s7
    print(paste("✓ Generated table: And to confirm, are you currently practicing full-time (i.e. 40+ hours weekly across all settings) or part-time?"))
  } else {
    print(paste("⚠ Warning: Variable 'S7' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'And to confirm, are you currently practicing full-time (i.e. 40+ hours weekly across all settings) or part-time?':", e$message))
})

# Table: Which of the following best represents the setting in which you spend most of your professional time?
# Variable: S9
tryCatch({
  if ("S9" %in% names(data)) {
    levels <- c("Private Solo Practice", "Private Group Practice", "Multi-specialty Practice / Comprehensive Care", "Staff HMO", "Community Hospital", "Academic/University Hospital", "VA Hospital", "None of the above")
    values <- c(1, 2, 3, 4, 5, 6, 7, 8)
    table_s9 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`S9`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S9` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_s9[[cut_name]] <- col_data
    }
    results[["s9"]] <- table_s9
    print(paste("✓ Generated table: Which of the following best represents the setting in which you spend most of your professional time?"))
  } else {
    print(paste("⚠ Warning: Variable 'S9' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Which of the following best represents the setting in which you spend most of your professional time?':", e$message))
})

# Table: Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By �personally�, we mean patients for whom you are a primary treatment decision maker.
# Variable: S10
tryCatch({
  if ("S10" %in% names(data)) {
    # Smart bucketing for numeric variable S10
    var_data <- data$`S10`[!is.na(data$`S10`)]
    if (length(var_data) > 0) {
      var_min <- min(var_data)
      var_max <- max(var_data)
      var_median <- median(var_data)
      var_range <- var_max - var_min
      
      # Determine nice rounding unit based on range
      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100
      
      # Round midpoint to nice number
      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit
      
      # Create 4 bucket boundaries (2 below midpoint, 2 above)
      lower_half_size <- midpoint - var_min
      upper_half_size <- var_max - midpoint
      
      # Calculate sub-bucket boundaries
      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit
      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit
      
      # Ensure boundaries are distinct
      if (lower_mid <= var_min) lower_mid <- var_min + round_unit
      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit
      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit
      if (upper_mid >= var_max) upper_mid <- var_max - round_unit
      
      # Create bucket labels
      bucket_labels <- c(
        paste0(midpoint, " or Less (Total)"),
        paste0("  ", var_min, " - ", lower_mid - 1),
        paste0("  ", lower_mid, " - ", midpoint),
        paste0("More Than ", midpoint, " (Total)"),
        paste0("  ", midpoint + 1, " - ", upper_mid),
        paste0("  ", upper_mid + 1, "+"),
        "Mean (overall)",
        "Mean (minus outliers)",
        "Median (overall)"
      )
      
      table_s10 <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)
      
      for (cut_name in names(cuts)) {
        cut_data <- apply_cut(data, cuts[[cut_name]])
        cut_var <- cut_data$`S10`
        valid_n <- sum(!is.na(cut_var))
        
        # Calculate bucket counts
        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)
        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)
        lower_total <- bucket1_count + bucket2_count
        
        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)
        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)
        upper_total <- bucket3_count + bucket4_count
        
        # Calculate percentages
        lower_total_pct <- calc_pct(lower_total, valid_n)
        bucket1_pct <- calc_pct(bucket1_count, valid_n)
        bucket2_pct <- calc_pct(bucket2_count, valid_n)
        upper_total_pct <- calc_pct(upper_total, valid_n)
        bucket3_pct <- calc_pct(bucket3_count, valid_n)
        bucket4_pct <- calc_pct(bucket4_count, valid_n)
        
        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 1)
        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 1)
        
        # Calculate mean minus outliers using IQR method
        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)
        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]
        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 1) else mean_val
        
        table_s10[[cut_name]] <- c(
          paste0(lower_total_pct, "% (", lower_total, ")"),
          paste0(bucket1_pct, "% (", bucket1_count, ")"),
          paste0(bucket2_pct, "% (", bucket2_count, ")"),
          paste0(upper_total_pct, "% (", upper_total, ")"),
          paste0(bucket3_pct, "% (", bucket3_count, ")"),
          paste0(bucket4_pct, "% (", bucket4_count, ")"),
          mean_val,
          mean_minus_outliers,
          median_val
        )
      }
    } else {
      # Fallback if no valid data
      table_s10 <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)
      for (cut_name in names(cuts)) {
        table_s10[[cut_name]] <- c("0", "N/A", "N/A")
      }
    }
    results[["s10"]] <- table_s10
    print(paste("✓ Generated table: Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By �personally�, we mean patients for whom you are a primary treatment decision maker."))
  } else {
    print(paste("⚠ Warning: Variable 'S10' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Using your best estimate, how many adult patients, age 18 or older, do you personally manage in your practice in a month? By �personally�, we mean patients for whom you are a primary treatment decision maker.':", e$message))
})

# Table: Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?
# Variable: S11
tryCatch({
  if ("S11" %in% names(data)) {
    # Smart bucketing for numeric variable S11
    var_data <- data$`S11`[!is.na(data$`S11`)]
    if (length(var_data) > 0) {
      var_min <- min(var_data)
      var_max <- max(var_data)
      var_median <- median(var_data)
      var_range <- var_max - var_min
      
      # Determine nice rounding unit based on range
      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100
      
      # Round midpoint to nice number
      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit
      
      # Create 4 bucket boundaries (2 below midpoint, 2 above)
      lower_half_size <- midpoint - var_min
      upper_half_size <- var_max - midpoint
      
      # Calculate sub-bucket boundaries
      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit
      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit
      
      # Ensure boundaries are distinct
      if (lower_mid <= var_min) lower_mid <- var_min + round_unit
      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit
      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit
      if (upper_mid >= var_max) upper_mid <- var_max - round_unit
      
      # Create bucket labels
      bucket_labels <- c(
        paste0(midpoint, " or Less (Total)"),
        paste0("  ", var_min, " - ", lower_mid - 1),
        paste0("  ", lower_mid, " - ", midpoint),
        paste0("More Than ", midpoint, " (Total)"),
        paste0("  ", midpoint + 1, " - ", upper_mid),
        paste0("  ", upper_mid + 1, "+"),
        "Mean (overall)",
        "Mean (minus outliers)",
        "Median (overall)"
      )
      
      table_s11 <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)
      
      for (cut_name in names(cuts)) {
        cut_data <- apply_cut(data, cuts[[cut_name]])
        cut_var <- cut_data$`S11`
        valid_n <- sum(!is.na(cut_var))
        
        # Calculate bucket counts
        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)
        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)
        lower_total <- bucket1_count + bucket2_count
        
        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)
        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)
        upper_total <- bucket3_count + bucket4_count
        
        # Calculate percentages
        lower_total_pct <- calc_pct(lower_total, valid_n)
        bucket1_pct <- calc_pct(bucket1_count, valid_n)
        bucket2_pct <- calc_pct(bucket2_count, valid_n)
        upper_total_pct <- calc_pct(upper_total, valid_n)
        bucket3_pct <- calc_pct(bucket3_count, valid_n)
        bucket4_pct <- calc_pct(bucket4_count, valid_n)
        
        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 1)
        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 1)
        
        # Calculate mean minus outliers using IQR method
        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)
        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]
        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 1) else mean_val
        
        table_s11[[cut_name]] <- c(
          paste0(lower_total_pct, "% (", lower_total, ")"),
          paste0(bucket1_pct, "% (", bucket1_count, ")"),
          paste0(bucket2_pct, "% (", bucket2_count, ")"),
          paste0(upper_total_pct, "% (", upper_total, ")"),
          paste0(bucket3_pct, "% (", bucket3_count, ")"),
          paste0(bucket4_pct, "% (", bucket4_count, ")"),
          mean_val,
          mean_minus_outliers,
          median_val
        )
      }
    } else {
      # Fallback if no valid data
      table_s11 <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)
      for (cut_name in names(cuts)) {
        table_s11[[cut_name]] <- c("0", "N/A", "N/A")
      }
    }
    results[["s11"]] <- table_s11
    print(paste("✓ Generated table: Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?"))
  } else {
    print(paste("⚠ Warning: Variable 'S11' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?':", e$message))
})

# Table: To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?
# Variable: A2a
tryCatch({
  if ("A2a" %in% names(data)) {
    levels <- c("Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?55 mg/dL", "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?70 mg/dL", "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?100 mg/dL")
    values <- c(1, 2, 3)
    table_a2a <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`A2a`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`A2a` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_a2a[[cut_name]] <- col_data
    }
    results[["a2a"]] <- table_a2a
    print(paste("✓ Generated table: To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?"))
  } else {
    print(paste("⚠ Warning: Variable 'A2a' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?':", e$message))
})

# Table: And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?
# Variable: A2b
tryCatch({
  if ("A2b" %in% names(data)) {
    levels <- c("Recommend a statin first", "Recommend a statin + ezetimibe first", "Recommend a PCSK9i first")
    values <- c(1, 2, 3)
    table_a2b <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`A2b`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`A2b` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_a2b[[cut_name]] <- col_data
    }
    results[["a2b"]] <- table_a2b
    print(paste("✓ Generated table: And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?"))
  } else {
    print(paste("⚠ Warning: Variable 'A2b' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?':", e$message))
})

# Table: How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?
# Variable: A5
tryCatch({
  if ("A5" %in% names(data)) {
    levels <- c("Within 3 months", "4-6 months", "7-12 months", "Over a year")
    values <- c(1, 2, 3, 4)
    table_a5 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`A5`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`A5` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_a5[[cut_name]] <- col_data
    }
    results[["a5"]] <- table_a5
    print(paste("✓ Generated table: How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?"))
  } else {
    print(paste("⚠ Warning: Variable 'A5' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?':", e$message))
})

# Table: US_State
# Variable: US_State
tryCatch({
  if ("US_State" %in% names(data)) {
    # Smart bucketing for numeric variable US_State
    var_data <- data$`US_State`[!is.na(data$`US_State`)]
    if (length(var_data) > 0) {
      var_min <- min(var_data)
      var_max <- max(var_data)
      var_median <- median(var_data)
      var_range <- var_max - var_min
      
      # Determine nice rounding unit based on range
      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100
      
      # Round midpoint to nice number
      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit
      
      # Create 4 bucket boundaries (2 below midpoint, 2 above)
      lower_half_size <- midpoint - var_min
      upper_half_size <- var_max - midpoint
      
      # Calculate sub-bucket boundaries
      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit
      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit
      
      # Ensure boundaries are distinct
      if (lower_mid <= var_min) lower_mid <- var_min + round_unit
      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit
      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit
      if (upper_mid >= var_max) upper_mid <- var_max - round_unit
      
      # Create bucket labels
      bucket_labels <- c(
        paste0(midpoint, " or Less (Total)"),
        paste0("  ", var_min, " - ", lower_mid - 1),
        paste0("  ", lower_mid, " - ", midpoint),
        paste0("More Than ", midpoint, " (Total)"),
        paste0("  ", midpoint + 1, " - ", upper_mid),
        paste0("  ", upper_mid + 1, "+"),
        "Mean (overall)",
        "Mean (minus outliers)",
        "Median (overall)"
      )
      
      table_us_state <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)
      
      for (cut_name in names(cuts)) {
        cut_data <- apply_cut(data, cuts[[cut_name]])
        cut_var <- cut_data$`US_State`
        valid_n <- sum(!is.na(cut_var))
        
        # Calculate bucket counts
        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)
        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)
        lower_total <- bucket1_count + bucket2_count
        
        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)
        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)
        upper_total <- bucket3_count + bucket4_count
        
        # Calculate percentages
        lower_total_pct <- calc_pct(lower_total, valid_n)
        bucket1_pct <- calc_pct(bucket1_count, valid_n)
        bucket2_pct <- calc_pct(bucket2_count, valid_n)
        upper_total_pct <- calc_pct(upper_total, valid_n)
        bucket3_pct <- calc_pct(bucket3_count, valid_n)
        bucket4_pct <- calc_pct(bucket4_count, valid_n)
        
        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 1)
        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 1)
        
        # Calculate mean minus outliers using IQR method
        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)
        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]
        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 1) else mean_val
        
        table_us_state[[cut_name]] <- c(
          paste0(lower_total_pct, "% (", lower_total, ")"),
          paste0(bucket1_pct, "% (", bucket1_count, ")"),
          paste0(bucket2_pct, "% (", bucket2_count, ")"),
          paste0(upper_total_pct, "% (", upper_total, ")"),
          paste0(bucket3_pct, "% (", bucket3_count, ")"),
          paste0(bucket4_pct, "% (", bucket4_count, ")"),
          mean_val,
          mean_minus_outliers,
          median_val
        )
      }
    } else {
      # Fallback if no valid data
      table_us_state <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)
      for (cut_name in names(cuts)) {
        table_us_state[[cut_name]] <- c("0", "N/A", "N/A")
      }
    }
    results[["us_state"]] <- table_us_state
    print(paste("✓ Generated table: US_State"))
  } else {
    print(paste("⚠ Warning: Variable 'US_State' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'US_State':", e$message))
})

# Table: Region
# Variable: Region
tryCatch({
  if ("Region" %in% names(data)) {
    levels <- c("Northeast", "South", "Midwest", "West", "Other", "Invalid Region")
    values <- c(1, 2, 3, 4, 5, 6)
    table_region <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`Region`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`Region` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_region[[cut_name]] <- col_data
    }
    results[["region"]] <- table_region
    print(paste("✓ Generated table: Region"))
  } else {
    print(paste("⚠ Warning: Variable 'Region' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Region':", e$message))
})

# Table: Which of the following best describes where your primary practice is located?
# Variable: B3
tryCatch({
  if ("B3" %in% names(data)) {
    levels <- c("Urban", "Suburban", "Rural")
    values <- c(1, 2, 3)
    table_b3 <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`B3`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`B3` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_b3[[cut_name]] <- col_data
    }
    results[["b3"]] <- table_b3
    print(paste("✓ Generated table: Which of the following best describes where your primary practice is located?"))
  } else {
    print(paste("⚠ Warning: Variable 'B3' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'Which of the following best describes where your primary practice is located?':", e$message))
})

# Table: How many physicians are in your practice?
# Variable: B4
tryCatch({
  if ("B4" %in% names(data)) {
    # Smart bucketing for numeric variable B4
    var_data <- data$`B4`[!is.na(data$`B4`)]
    if (length(var_data) > 0) {
      var_min <- min(var_data)
      var_max <- max(var_data)
      var_median <- median(var_data)
      var_range <- var_max - var_min
      
      # Determine nice rounding unit based on range
      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100
      
      # Round midpoint to nice number
      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit
      
      # Create 4 bucket boundaries (2 below midpoint, 2 above)
      lower_half_size <- midpoint - var_min
      upper_half_size <- var_max - midpoint
      
      # Calculate sub-bucket boundaries
      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit
      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit
      
      # Ensure boundaries are distinct
      if (lower_mid <= var_min) lower_mid <- var_min + round_unit
      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit
      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit
      if (upper_mid >= var_max) upper_mid <- var_max - round_unit
      
      # Create bucket labels
      bucket_labels <- c(
        paste0(midpoint, " or Less (Total)"),
        paste0("  ", var_min, " - ", lower_mid - 1),
        paste0("  ", lower_mid, " - ", midpoint),
        paste0("More Than ", midpoint, " (Total)"),
        paste0("  ", midpoint + 1, " - ", upper_mid),
        paste0("  ", upper_mid + 1, "+"),
        "Mean (overall)",
        "Mean (minus outliers)",
        "Median (overall)"
      )
      
      table_b4 <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)
      
      for (cut_name in names(cuts)) {
        cut_data <- apply_cut(data, cuts[[cut_name]])
        cut_var <- cut_data$`B4`
        valid_n <- sum(!is.na(cut_var))
        
        # Calculate bucket counts
        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)
        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)
        lower_total <- bucket1_count + bucket2_count
        
        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)
        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)
        upper_total <- bucket3_count + bucket4_count
        
        # Calculate percentages
        lower_total_pct <- calc_pct(lower_total, valid_n)
        bucket1_pct <- calc_pct(bucket1_count, valid_n)
        bucket2_pct <- calc_pct(bucket2_count, valid_n)
        upper_total_pct <- calc_pct(upper_total, valid_n)
        bucket3_pct <- calc_pct(bucket3_count, valid_n)
        bucket4_pct <- calc_pct(bucket4_count, valid_n)
        
        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 1)
        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 1)
        
        # Calculate mean minus outliers using IQR method
        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)
        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        lower_bound <- q1 - 1.5 * iqr
        upper_bound <- q3 + 1.5 * iqr
        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]
        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 1) else mean_val
        
        table_b4[[cut_name]] <- c(
          paste0(lower_total_pct, "% (", lower_total, ")"),
          paste0(bucket1_pct, "% (", bucket1_count, ")"),
          paste0(bucket2_pct, "% (", bucket2_count, ")"),
          paste0(upper_total_pct, "% (", upper_total, ")"),
          paste0(bucket3_pct, "% (", bucket3_count, ")"),
          paste0(bucket4_pct, "% (", bucket4_count, ")"),
          mean_val,
          mean_minus_outliers,
          median_val
        )
      }
    } else {
      # Fallback if no valid data
      table_b4 <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)
      for (cut_name in names(cuts)) {
        table_b4[[cut_name]] <- c("0", "N/A", "N/A")
      }
    }
    results[["b4"]] <- table_b4
    print(paste("✓ Generated table: How many physicians are in your practice?"))
  } else {
    print(paste("⚠ Warning: Variable 'B4' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'How many physicians are in your practice?':", e$message))
})

# Table: If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below:
# Variable: QCONSENT
tryCatch({
  if ("QCONSENT" %in% names(data)) {
    levels <- c("Yes", "No")
    values <- c(1, 2)
    table_qconsent <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- apply_cut(data, cuts[[cut_name]])
      # Base = number of valid responses (non-NA) for this question in this cut
      base_n <- sum(!is.na(cut_data$`QCONSENT`))
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`QCONSENT` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(pcts, "% (", counts, ")")
      table_qconsent[[cut_name]] <- col_data
    }
    results[["qconsent"]] <- table_qconsent
    print(paste("✓ Generated table: If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below:"))
  } else {
    print(paste("⚠ Warning: Variable 'QCONSENT' not found in data"))
  }
}, error = function(e) {
  print(paste("✗ Error generating table 'If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below:':", e$message))
})

# Multi-sub Table: S5: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?
# Items: 7
# Normalized Type: binary_flag
tryCatch({
  item_labels <- c("Advertising Agency", "Marketing/Market Research Firm", "Public Relations Firm", "Any media company (Print, Radio, TV, Internet)", "Pharmaceutical Drug / Device Manufacturer (outside of clinical trials)", "Governmental Regulatory Agency (e.g., Food & Drug Administration (FDA))", "None of these")
  table_s5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`S5r1`))
    col_values <- character(0)
    if ("S5r1" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r2" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r3" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r4" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r5" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r6" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r7" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_s5[[cut_name]] <- col_values
  }
  results[["s5"]] <- table_s5
  print(paste("✓ Generated multi-sub table: S5: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'S5: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?':", e$message))
})

# Multi-sub Table: S8: Approximately what percentage of your professional time is spent performing each of the following activities?
# Items: 4
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Treating/Managing patients", "Performing academic functions (e.g., teaching, publishing)", "Participating in clinical research", "Performing other functions")
  table_s8 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("S8r1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S8r1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S8r2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r3" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S8r3`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r4" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S8r4`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_s8[[cut_name]] <- col_values
  }
  results[["s8"]] <- table_s8
  print(paste("✓ Generated multi-sub table: S8: Approximately what percentage of your professional time is spent performing each of the following activities?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'S8: Approximately what percentage of your professional time is spent performing each of the following activities?':", e$message))
})

# Multi-sub Table: S12: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) �
# Items: 4
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Over 5 years ago", "Within the last 3-5 years", "Within the last 1-2 years", "Within the last year")
  table_s12 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("S12r1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S12r1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S12r2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r3" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S12r3`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r4" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`S12r4`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_s12[[cut_name]] <- col_values
  }
  results[["s12"]] <- table_s12
  print(paste("✓ Generated multi-sub table: S12: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) �"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'S12: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) �':", e$message))
})

# Multi-sub Table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 1
# Items: 4
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)")
  table_a1_value_1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A1r1`))
    col_values <- character(0)
    if ("A1r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a1_value_1[[cut_name]] <- col_values
  }
  results[["a1_value_1"]] <- table_a1_value_1
  print(paste("✓ Generated multi-sub table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 1"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 1':", e$message))
})

# Multi-sub Table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 2
# Items: 4
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)")
  table_a1_value_2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A1r1`))
    col_values <- character(0)
    if ("A1r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r1` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r2` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r3` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r4` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a1_value_2[[cut_name]] <- col_values
  }
  results[["a1_value_2"]] <- table_a1_value_2
  print(paste("✓ Generated multi-sub table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 2"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? - 2':", e$message))
})

# Multi-sub Table: A3: For your LAST 100 [res PatientHoverover] with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?
# Items: 7
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Statin only (i.e., no additional therapy)", "Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Zetia (ezetimibe) or generic ezetimibe", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)", "Other")
  table_a3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3r1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r3" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r3`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r4" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r4`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r5" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r5`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r6" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r6`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r7" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A3r7`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3[[cut_name]] <- col_values
  }
  results[["a3"]] <- table_a3
  print(paste("✓ Generated multi-sub table: A3: For your LAST 100 [res PatientHoverover] with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3: For your LAST 100 [res PatientHoverover] with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?':", e$message))
})

# Multi-sub Table: A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin")
  table_a3ar1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3ar1c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r2 > 0
      base_filtered <- cut_data[cut_data$`A3r2` > 0 & !is.na(cut_data$`A3r2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar1c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar1c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r2 > 0
      base_filtered <- cut_data[cut_data$`A3r2` > 0 & !is.na(cut_data$`A3r2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar1c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3ar1[[cut_name]] <- col_values
  }
  results[["a3ar1"]] <- table_a3ar1
  print(paste("✓ Generated multi-sub table: A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3ar2: Praluent (alirocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin")
  table_a3ar2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3ar2c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r3 > 0
      base_filtered <- cut_data[cut_data$`A3r3` > 0 & !is.na(cut_data$`A3r3`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar2c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar2c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r3 > 0
      base_filtered <- cut_data[cut_data$`A3r3` > 0 & !is.na(cut_data$`A3r3`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar2c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3ar2[[cut_name]] <- col_values
  }
  results[["a3ar2"]] <- table_a3ar2
  print(paste("✓ Generated multi-sub table: A3ar2: Praluent (alirocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar2: Praluent (alirocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3ar3: Repatha (evolocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin")
  table_a3ar3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3ar3c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r4 > 0
      base_filtered <- cut_data[cut_data$`A3r4` > 0 & !is.na(cut_data$`A3r4`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar3c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar3c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r4 > 0
      base_filtered <- cut_data[cut_data$`A3r4` > 0 & !is.na(cut_data$`A3r4`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar3c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3ar3[[cut_name]] <- col_values
  }
  results[["a3ar3"]] <- table_a3ar3
  print(paste("✓ Generated multi-sub table: A3ar3: Repatha (evolocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar3: Repatha (evolocumab) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin")
  table_a3ar4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3ar4c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r5 > 0
      base_filtered <- cut_data[cut_data$`A3r5` > 0 & !is.na(cut_data$`A3r5`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar4c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar4c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r5 > 0
      base_filtered <- cut_data[cut_data$`A3r5` > 0 & !is.na(cut_data$`A3r5`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar4c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3ar4[[cut_name]] <- col_values
  }
  results[["a3ar4"]] <- table_a3ar4
  print(paste("✓ Generated multi-sub table: A3ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin")
  table_a3ar5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3ar5c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r6 > 0
      base_filtered <- cut_data[cut_data$`A3r6` > 0 & !is.na(cut_data$`A3r6`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar5c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar5c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3r6 > 0
      base_filtered <- cut_data[cut_data$`A3r6` > 0 & !is.na(cut_data$`A3r6`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3ar5c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3ar5[[cut_name]] <- col_values
  }
  results[["a3ar5"]] <- table_a3ar5
  print(paste("✓ Generated multi-sub table: A3ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3br1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3br1c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar1c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar1c2` > 0 & !is.na(cut_data$`A3ar1c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br1c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br1c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar1c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar1c2` > 0 & !is.na(cut_data$`A3ar1c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br1c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3br1[[cut_name]] <- col_values
  }
  results[["a3br1"]] <- table_a3br1
  print(paste("✓ Generated multi-sub table: A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A3br2: Praluent (alirocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3br2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3br2c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar2c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar2c2` > 0 & !is.na(cut_data$`A3ar2c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br2c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br2c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar2c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar2c2` > 0 & !is.na(cut_data$`A3ar2c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br2c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3br2[[cut_name]] <- col_values
  }
  results[["a3br2"]] <- table_a3br2
  print(paste("✓ Generated multi-sub table: A3br2: Praluent (alirocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br2: Praluent (alirocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A3br3: Repatha (evolocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3br3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3br3c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar3c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar3c2` > 0 & !is.na(cut_data$`A3ar3c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br3c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br3c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar3c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar3c2` > 0 & !is.na(cut_data$`A3ar3c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br3c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3br3[[cut_name]] <- col_values
  }
  results[["a3br3"]] <- table_a3br3
  print(paste("✓ Generated multi-sub table: A3br3: Repatha (evolocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br3: Repatha (evolocumab) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A3br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3br4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3br4c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar4c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar4c2` > 0 & !is.na(cut_data$`A3ar4c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br4c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br4c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar4c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar4c2` > 0 & !is.na(cut_data$`A3ar4c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br4c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3br4[[cut_name]] <- col_values
  }
  results[["a3br4"]] <- table_a3br4
  print(paste("✓ Generated multi-sub table: A3br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A3br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3br5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A3br5c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar5c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar5c2` > 0 & !is.na(cut_data$`A3ar5c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br5c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br5c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A3ar5c2 > 0
      base_filtered <- cut_data[cut_data$`A3ar5c2` > 0 & !is.na(cut_data$`A3ar5c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A3br5c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3br5[[cut_name]] <- col_values
  }
  results[["a3br5"]] <- table_a3br5
  print(paste("✓ Generated multi-sub table: A3br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Statin only (i.e., no additional therapy)", "Statin only (i.e., no additional therapy)")
  table_a4r1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r1c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r1c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r1c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r1c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r1[[cut_name]] <- col_values
  }
  results[["a4r1"]] <- table_a4r1
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Leqvio (inclisiran)", "Leqvio (inclisiran)")
  table_a4r2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r2c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r2c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r2c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r2c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r2[[cut_name]] <- col_values
  }
  results[["a4r2"]] <- table_a4r2
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Praluent (alirocumab)", "Praluent (alirocumab)")
  table_a4r3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r3c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r3c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r3c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r3c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r3[[cut_name]] <- col_values
  }
  results[["a4r3"]] <- table_a4r3
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Repatha (evolocumab)", "Repatha (evolocumab)")
  table_a4r4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r4c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r4c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r4c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r4c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r4[[cut_name]] <- col_values
  }
  results[["a4r4"]] <- table_a4r4
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Zetia (ezetimibe) or generic ezetimibe", "Zetia (ezetimibe) or generic ezetimibe")
  table_a4r5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r5c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r5c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r5c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r5c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r5[[cut_name]] <- col_values
  }
  results[["a4r5"]] <- table_a4r5
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)")
  table_a4r6 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r6c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r6c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r6c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r6c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r6[[cut_name]] <- col_values
  }
  results[["a4r6"]] <- table_a4r6
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Other", "Other")
  table_a4r7 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4r7c1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r7c1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r7c2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`A4r7c2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4r7[[cut_name]] <- col_values
  }
  results[["a4r7"]] <- table_a4r7
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4ar1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4ar1c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r2 > 0
      base_filtered <- cut_data[cut_data$`A4r2` > 0 & !is.na(cut_data$`A4r2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar1c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar1c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r2 > 0
      base_filtered <- cut_data[cut_data$`A4r2` > 0 & !is.na(cut_data$`A4r2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar1c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4ar1[[cut_name]] <- col_values
  }
  results[["a4ar1"]] <- table_a4ar1
  print(paste("✓ Generated multi-sub table: A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar2: Praluent (alirocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4ar2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4ar2c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r3 > 0
      base_filtered <- cut_data[cut_data$`A4r3` > 0 & !is.na(cut_data$`A4r3`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar2c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar2c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r3 > 0
      base_filtered <- cut_data[cut_data$`A4r3` > 0 & !is.na(cut_data$`A4r3`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar2c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4ar2[[cut_name]] <- col_values
  }
  results[["a4ar2"]] <- table_a4ar2
  print(paste("✓ Generated multi-sub table: A4ar2: Praluent (alirocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar2: Praluent (alirocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar3: Repatha (evolocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4ar3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4ar3c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r4 > 0
      base_filtered <- cut_data[cut_data$`A4r4` > 0 & !is.na(cut_data$`A4r4`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar3c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar3c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r4 > 0
      base_filtered <- cut_data[cut_data$`A4r4` > 0 & !is.na(cut_data$`A4r4`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar3c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4ar3[[cut_name]] <- col_values
  }
  results[["a4ar3"]] <- table_a4ar3
  print(paste("✓ Generated multi-sub table: A4ar3: Repatha (evolocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar3: Repatha (evolocumab) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4ar4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4ar4c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r5 > 0
      base_filtered <- cut_data[cut_data$`A4r5` > 0 & !is.na(cut_data$`A4r5`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar4c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar4c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r5 > 0
      base_filtered <- cut_data[cut_data$`A4r5` > 0 & !is.na(cut_data$`A4r5`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar4c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4ar4[[cut_name]] <- col_values
  }
  results[["a4ar4"]] <- table_a4ar4
  print(paste("✓ Generated multi-sub table: A4ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar4: Zetia (ezetimibe) or generic ezetimibe - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4ar5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4ar5c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r6 > 0
      base_filtered <- cut_data[cut_data$`A4r6` > 0 & !is.na(cut_data$`A4r6`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar5c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar5c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4r6 > 0
      base_filtered <- cut_data[cut_data$`A4r6` > 0 & !is.na(cut_data$`A4r6`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4ar5c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4ar5[[cut_name]] <- col_values
  }
  results[["a4ar5"]] <- table_a4ar5
  print(paste("✓ Generated multi-sub table: A4ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation")
  table_a4br1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4br1c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar1c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar1c2` > 0 & !is.na(cut_data$`A4ar1c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br1c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br1c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar1c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar1c2` > 0 & !is.na(cut_data$`A4ar1c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br1c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4br1[[cut_name]] <- col_values
  }
  results[["a4br1"]] <- table_a4br1
  print(paste("✓ Generated multi-sub table: A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A4br2: Praluent (alirocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation")
  table_a4br2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4br2c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar2c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar2c2` > 0 & !is.na(cut_data$`A4ar2c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br2c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br2c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar2c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar2c2` > 0 & !is.na(cut_data$`A4ar2c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br2c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4br2[[cut_name]] <- col_values
  }
  results[["a4br2"]] <- table_a4br2
  print(paste("✓ Generated multi-sub table: A4br2: Praluent (alirocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br2: Praluent (alirocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A4br3: Repatha (evolocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation")
  table_a4br3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4br3c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar3c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar3c2` > 0 & !is.na(cut_data$`A4ar3c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br3c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br3c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar3c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar3c2` > 0 & !is.na(cut_data$`A4ar3c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br3c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4br3[[cut_name]] <- col_values
  }
  results[["a4br3"]] <- table_a4br3
  print(paste("✓ Generated multi-sub table: A4br3: Repatha (evolocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br3: Repatha (evolocumab) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A4br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation")
  table_a4br4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4br4c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar4c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar4c2` > 0 & !is.na(cut_data$`A4ar4c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br4c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br4c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar4c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar4c2` > 0 & !is.na(cut_data$`A4ar4c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br4c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4br4[[cut_name]] <- col_values
  }
  results[["a4br4"]] <- table_a4br4
  print(paste("✓ Generated multi-sub table: A4br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br4: Zetia (ezetimibe) or generic ezetimibe - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A4br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 2
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation")
  table_a4br5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("A4br5c1" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar5c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar5c2` > 0 & !is.na(cut_data$`A4ar5c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br5c1`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br5c2" %in% names(cut_data)) {
      # Base filter: only include respondents where A4ar5c2 > 0
      base_filtered <- cut_data[cut_data$`A4ar5c2` > 0 & !is.na(cut_data$`A4ar5c2`), ]
      mean_val <- if (nrow(base_filtered) > 0) round_half_up(mean(base_filtered$`A4br5c2`, na.rm = TRUE), 1) else NA
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4br5[[cut_name]] <- col_values
  }
  results[["a4br5"]] <- table_a4br5
  print(paste("✓ Generated multi-sub table: A4br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br5: Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 1
# Items: 8
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed", "Start statin and ezetimibe or Nexletol/Nexlizet at the same time", "Start ezetimibe or Nexletol/Nexlizet, no statin", "Start statin first, add/switch to PCSK9i if needed", "Start statin and PCSK9i at the same time", "Start PCSK9i, no statin", "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that", "Other")
  table_a6_value_1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A6r1`))
    col_values <- character(0)
    if ("A6r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r8" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r8` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a6_value_1[[cut_name]] <- col_values
  }
  results[["a6_value_1"]] <- table_a6_value_1
  print(paste("✓ Generated multi-sub table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 1"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 1':", e$message))
})

# Multi-sub Table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 2
# Items: 8
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed", "Start statin and ezetimibe or Nexletol/Nexlizet at the same time", "Start ezetimibe or Nexletol/Nexlizet, no statin", "Start statin first, add/switch to PCSK9i if needed", "Start statin and PCSK9i at the same time", "Start PCSK9i, no statin", "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that", "Other")
  table_a6_value_2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A6r1`))
    col_values <- character(0)
    if ("A6r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r1` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r2` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r3` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r4` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r5` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r6` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r7` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r8" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r8` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a6_value_2[[cut_name]] <- col_values
  }
  results[["a6_value_2"]] <- table_a6_value_2
  print(paste("✓ Generated multi-sub table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 2"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 2':", e$message))
})

# Multi-sub Table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 3
# Items: 8
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed", "Start statin and ezetimibe or Nexletol/Nexlizet at the same time", "Start ezetimibe or Nexletol/Nexlizet, no statin", "Start statin first, add/switch to PCSK9i if needed", "Start statin and PCSK9i at the same time", "Start PCSK9i, no statin", "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that", "Other")
  table_a6_value_3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A6r1`))
    col_values <- character(0)
    if ("A6r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r1` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r2` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r3` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r4` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r5` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r6` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r7` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r8" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r8` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a6_value_3[[cut_name]] <- col_values
  }
  results[["a6_value_3"]] <- table_a6_value_3
  print(paste("✓ Generated multi-sub table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 3"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 3':", e$message))
})

# Multi-sub Table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 4
# Items: 8
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed", "Start statin and ezetimibe or Nexletol/Nexlizet at the same time", "Start ezetimibe or Nexletol/Nexlizet, no statin", "Start statin first, add/switch to PCSK9i if needed", "Start statin and PCSK9i at the same time", "Start PCSK9i, no statin", "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that", "Other")
  table_a6_value_4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A6r1`))
    col_values <- character(0)
    if ("A6r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r1` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r2` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r3` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r4` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r5` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r6` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r7` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r8" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r8` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a6_value_4[[cut_name]] <- col_values
  }
  results[["a6_value_4"]] <- table_a6_value_4
  print(paste("✓ Generated multi-sub table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 4"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? - 4':", e$message))
})

# Multi-sub Table: A7: How might being able to use PCKS9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?
# Items: 5
# Normalized Type: binary_flag
tryCatch({
  item_labels <- c("Makes PCSK9s easier to get covered by insurance / get patients on the medication", "Offers an option to patients who can�t or won�t take a statin", "Enables me to use PCSK9s sooner for patients", "Allows me to better customize treatment plans for patients", "Other (Specify)")
  table_a7 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A7r1`))
    col_values <- character(0)
    if ("A7r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a7[[cut_name]] <- col_values
  }
  results[["a7"]] <- table_a7
  print(paste("✓ Generated multi-sub table: A7: How might being able to use PCKS9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A7: How might being able to use PCKS9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?':", e$message))
})

# Multi-sub Table: A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a8r1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A8r1c1`))
    col_values <- character(0)
    if ("A8r1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r1c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8r1[[cut_name]] <- col_values
  }
  results[["a8r1"]] <- table_a8r1
  print(paste("✓ Generated multi-sub table: A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A8r2: With no history of CV events and at high-risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a8r2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A8r2c1`))
    col_values <- character(0)
    if ("A8r2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r2c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8r2[[cut_name]] <- col_values
  }
  results[["a8r2"]] <- table_a8r2
  print(paste("✓ Generated multi-sub table: A8r2: With no history of CV events and at high-risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r2: With no history of CV events and at high-risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A8r3: With no history of CV events and at low-to-medium risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a8r3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A8r3c1`))
    col_values <- character(0)
    if ("A8r3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r3c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8r3[[cut_name]] <- col_values
  }
  results[["a8r3"]] <- table_a8r3
  print(paste("✓ Generated multi-sub table: A8r3: With no history of CV events and at low-to-medium risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r3: With no history of CV events and at low-to-medium risk - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A8r4: Who are not known to be compliant on statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a8r4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A8r4c1`))
    col_values <- character(0)
    if ("A8r4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r4c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8r4[[cut_name]] <- col_values
  }
  results[["a8r4"]] <- table_a8r4
  print(paste("✓ Generated multi-sub table: A8r4: Who are not known to be compliant on statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r4: Who are not known to be compliant on statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A8r5: Who are intolerant of statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a8r5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A8r5c1`))
    col_values <- character(0)
    if ("A8r5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r5c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8r5[[cut_name]] <- col_values
  }
  results[["a8r5"]] <- table_a8r5
  print(paste("✓ Generated multi-sub table: A8r5: Who are intolerant of statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r5: Who are intolerant of statins - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 1
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a9_value_1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A9c1`))
    col_values <- character(0)
    if ("A9c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a9_value_1[[cut_name]] <- col_values
  }
  results[["a9_value_1"]] <- table_a9_value_1
  print(paste("✓ Generated multi-sub table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 1"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 1':", e$message))
})

# Multi-sub Table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 2
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a9_value_2 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A9c1`))
    col_values <- character(0)
    if ("A9c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c1` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c2` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c3` == 2, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a9_value_2[[cut_name]] <- col_values
  }
  results[["a9_value_2"]] <- table_a9_value_2
  print(paste("✓ Generated multi-sub table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 2"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 2':", e$message))
})

# Multi-sub Table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 3
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a9_value_3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A9c1`))
    col_values <- character(0)
    if ("A9c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c1` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c2` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c3` == 3, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a9_value_3[[cut_name]] <- col_values
  }
  results[["a9_value_3"]] <- table_a9_value_3
  print(paste("✓ Generated multi-sub table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 3"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 3':", e$message))
})

# Multi-sub Table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 4
# Items: 3
# Normalized Type: categorical_select
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a9_value_4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A9c1`))
    col_values <- character(0)
    if ("A9c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c1` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c2` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c3` == 4, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a9_value_4[[cut_name]] <- col_values
  }
  results[["a9_value_4"]] <- table_a9_value_4
  print(paste("✓ Generated multi-sub table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 4"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? - 4':", e$message))
})

# Multi-sub Table: A10: For what reasons are you using PCSK9 inhibitors without a statin today?
# Items: 6
# Normalized Type: binary_flag
tryCatch({
  item_labels <- c("Patient failed statins prior to starting PCSK9i", "Patient is statin intolerant", "Patient refused statins", "Statins are contraindicated for patient", "Patient not or unlikely to be compliant on statins", "Haven�t prescribed PCSK9s without a statin")
  table_a10 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`A10r1`))
    col_values <- character(0)
    if ("A10r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a10[[cut_name]] <- col_values
  }
  results[["a10"]] <- table_a10
  print(paste("✓ Generated multi-sub table: A10: For what reasons are you using PCSK9 inhibitors without a statin today?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A10: For what reasons are you using PCSK9 inhibitors without a statin today?':", e$message))
})

# Multi-sub Table: B1: What percentage of your current [res PatientHoverover] are covered by each type of insurance?
# Items: 8
# Normalized Type: numeric_range
tryCatch({
  item_labels <- c("Not insured", "Private insurance provided by employer / purchased in exchange", "Traditional Medicare (Medicare Part B Fee for Service)", "Traditional Medicare with supplemental insurance", "Private Medicare (Medicare Advantage / Part C managed through Private payer)", "Medicaid", "Veterans Administration (VA)", "Other")
  table_b1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    col_values <- character(0)
    if ("B1r1" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r1`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r2" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r2`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r3" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r3`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r4" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r4`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r5" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r5`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r6" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r6`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r7" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r7`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r8" %in% names(cut_data)) {
      mean_val <- round_half_up(mean(cut_data$`B1r8`, na.rm = TRUE), 1)
      col_values <- c(col_values, as.character(mean_val))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_b1[[cut_name]] <- col_values
  }
  results[["b1"]] <- table_b1
  print(paste("✓ Generated multi-sub table: B1: What percentage of your current [res PatientHoverover] are covered by each type of insurance?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'B1: What percentage of your current [res PatientHoverover] are covered by each type of insurance?':", e$message))
})

# Multi-sub Table: B5: How would you describe your specialty/training?
# Items: 5
# Normalized Type: binary_flag
tryCatch({
  item_labels <- c("Internal Medicine", "General Practitioner", "Primary Care", "Family Practice", "Doctor of Osteopathic Medicine (DO)")
  table_b5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- apply_cut(data, cuts[[cut_name]])
    # Base = respondents who were asked this question (use first item to check, all share same skip logic)
    base_n <- sum(!is.na(cut_data$`B5r1`))
    col_values <- character(0)
    if ("B5r1" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r2" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r3" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r4" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r5" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(pct, "% (", count, ")"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_b5[[cut_name]] <- col_values
  }
  results[["b5"]] <- table_b5
  print(paste("✓ Generated multi-sub table: B5: How would you describe your specialty/training?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'B5: How would you describe your specialty/training?':", e$message))
})

# Create results directory and save CSV files
if (!dir.exists("results")) {
  dir.create("results")
}

# Save individual table CSVs
for (name in names(results)) {
  tryCatch({
    filename <- paste0("results/", name, ".csv")
    write.csv(results[[name]], filename, row.names = FALSE)
    print(paste("✓ Saved:", filename))
  }, error = function(e) {
    print(paste("✗ Error saving", name, ":", e$message))
  })
}

# Create combined workbook with all tables
tryCatch({
  combined <- data.frame()
  row_offset <- 1
  
  # Create metadata for table locations
  table_index <- data.frame(
    Table = character(),
    StartRow = integer(),
    EndRow = integer(),
    stringsAsFactors = FALSE
  )
  
  # Combine all tables with spacing
  all_lines <- list()
  current_row <- 1
  
  for (name in names(results)) {
    # Add table title
    all_lines[[length(all_lines) + 1]] <- c(paste0("TABLE: ", name), rep("", ncol(results[[name]]) - 1))
    current_row <- current_row + 1
    
    # Add table data
    table_data <- results[[name]]
    for (i in 1:nrow(table_data)) {
      row_data <- as.character(table_data[i, ])
      all_lines[[length(all_lines) + 1]] <- row_data
    }
    
    # Record table location
    table_index <- rbind(table_index, data.frame(
      Table = name,
      StartRow = current_row,
      EndRow = current_row + nrow(table_data) - 1,
      stringsAsFactors = FALSE
    ))
    current_row <- current_row + nrow(table_data)
    
    # Add spacing between tables
    all_lines[[length(all_lines) + 1]] <- rep("", ncol(results[[name]]))
    all_lines[[length(all_lines) + 1]] <- rep("", ncol(results[[name]]))
    current_row <- current_row + 2
  }
  
  # Convert to data frame and save
  max_cols <- max(sapply(all_lines, length))
  combined_df <- as.data.frame(do.call(rbind, lapply(all_lines, function(x) {
    c(x, rep("", max_cols - length(x)))
  })))
  
  write.csv(combined_df, "results/COMBINED_TABLES.csv", row.names = FALSE)
  write.csv(table_index, "results/TABLE_INDEX.csv", row.names = FALSE)
  print(paste("✓ Created combined workbook: results/COMBINED_TABLES.csv"))
  print(paste("✓ Created table index: results/TABLE_INDEX.csv"))
}, error = function(e) {
  print(paste("✗ Error creating combined workbook:", e$message))
})

print(paste(rep("=", 50), collapse=""))
print(paste("SUMMARY: Generated", length(results), "tables"))
print(paste("Results saved in:", getwd(), "/results"))
print(paste("Combined workbook: COMBINED_TABLES.csv"))
print(paste("Table index: TABLE_INDEX.csv"))