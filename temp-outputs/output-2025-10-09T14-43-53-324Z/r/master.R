# HawkTab AI - Generated R Script
# Session: output-2025-10-09T14-43-53-324Z
# Generated: 2025-10-09T14:43:54.849Z
# Tables: 42
# Cuts: 0

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
)

# Helper function for percentage calculation
calc_pct <- function(x, base) {
  if (base == 0) return(0)
  round(100 * x / base, 1)
}

# Generate crosstab tables
results <- list()

# Table: You are about to enter a market research survey. We are being asked to pass on to our client details of adverse events about individual patients or groups of patients and / or product complaints that are raised during the course of market research surveys. Although this is a market research survey, and what is contributed is treated in confidence, should you raise an adverse event and / or product complaint, we will need to report this even if it has already been reported by you directly to the company or the regulatory authorities. In such a situation you will be contacted to ask whether or not you are willing to waive the confidentiality given to you under the market research codes of conduct specifically in relation to that adverse event and / or product complaint. Everything else you contribute during the course of the survey will continue to remain confidential. Are you happy to proceed on this basis?
# Variable: S1
tryCatch({
  if ("S1" %in% names(data)) {
    table_s1 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S1`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S1`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S1`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S1`, na.rm = TRUE), 2)
      table_s1[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s2b <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S2b`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S2b`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S2b`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S2b`, na.rm = TRUE), 2)
      table_s2b[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s2 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S2`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S2`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S2`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S2`, na.rm = TRUE), 2)
      table_s2[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s2a <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S2a`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S2a`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S2a`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S2a`, na.rm = TRUE), 2)
      table_s2a[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_qcard-specialty <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qCARD_SPECIALTY` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(counts, " (", pcts, "%)")
      table_qcard-specialty[[cut_name]] <- col_data
    }
    results[["qcard-specialty"]] <- table_qcard-specialty
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
    table_qspecialty <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`qSPECIALTY`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`qSPECIALTY`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`qSPECIALTY`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`qSPECIALTY`, na.rm = TRUE), 2)
      table_qspecialty[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s3a <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S3a`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S3a`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S3a`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S3a`, na.rm = TRUE), 2)
      table_s3a[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_qtype-of-card <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`qTYPE_OF_CARD`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`qTYPE_OF_CARD`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`qTYPE_OF_CARD`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`qTYPE_OF_CARD`, na.rm = TRUE), 2)
      table_qtype-of-card[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
    }
    results[["qtype-of-card"]] <- table_qtype-of-card
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
    table_qon-list-off-list <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`qON_LIST_OFF_LIST`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`qON_LIST_OFF_LIST`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`qON_LIST_OFF_LIST`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`qON_LIST_OFF_LIST`, na.rm = TRUE), 2)
      table_qon-list-off-list[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
    }
    results[["qon-list-off-list"]] <- table_qon-list-off-list
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
    table_qlist-tier <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qLIST_TIER` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(counts, " (", pcts, "%)")
      table_qlist-tier[[cut_name]] <- col_data
    }
    results[["qlist-tier"]] <- table_qlist-tier
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
    table_qlist-priority-account <- data.frame(Level = levels, stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`qLIST_PRIORITY_ACCOUNT` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(counts, " (", pcts, "%)")
      table_qlist-priority-account[[cut_name]] <- col_data
    }
    results[["qlist-priority-account"]] <- table_qlist-priority-account
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
    table_s4 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S4`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S4`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S4`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S4`, na.rm = TRUE), 2)
      table_s4[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s6 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S6`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S6`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S6`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S6`, na.rm = TRUE), 2)
      table_s6[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`S7` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(counts, " (", pcts, "%)")
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
    table_s9 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S9`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S9`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S9`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S9`, na.rm = TRUE), 2)
      table_s9[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s10 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S10`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S10`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S10`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S10`, na.rm = TRUE), 2)
      table_s10[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_s11 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`S11`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`S11`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`S11`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`S11`, na.rm = TRUE), 2)
      table_s11[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_a2a <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`A2a`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`A2a`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`A2a`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`A2a`, na.rm = TRUE), 2)
      table_a2a[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_a2b <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`A2b`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`A2b`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`A2b`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`A2b`, na.rm = TRUE), 2)
      table_a2b[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      counts <- numeric(length(values))
      for (i in seq_along(values)) {
        counts[i] <- sum(cut_data$`A5` == values[i], na.rm = TRUE)
      }
      pcts <- sapply(counts, calc_pct, base = base_n)
      col_data <- paste0(counts, " (", pcts, "%)")
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
    table_us-state <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`US_State`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`US_State`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`US_State`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`US_State`, na.rm = TRUE), 2)
      table_us-state[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
    }
    results[["us-state"]] <- table_us-state
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
    table_region <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`Region`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`Region`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`Region`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`Region`, na.rm = TRUE), 2)
      table_region[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_b3 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`B3`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`B3`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`B3`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`B3`, na.rm = TRUE), 2)
      table_b3[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_b4 <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`B4`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`B4`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`B4`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`B4`, na.rm = TRUE), 2)
      table_b4[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
    table_qconsent <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)
    for (cut_name in names(cuts)) {
      cut_data <- data[cuts[[cut_name]], ]
      base_n <- nrow(cut_data)
      valid_n <- sum(!is.na(cut_data$`QCONSENT`), na.rm = TRUE)
      mean_val <- round(mean(cut_data$`QCONSENT`, na.rm = TRUE), 2)
      median_val <- round(median(cut_data$`QCONSENT`, na.rm = TRUE), 2)
      sd_val <- round(sd(cut_data$`QCONSENT`, na.rm = TRUE), 2)
      table_qconsent[[cut_name]] <- c(
        paste0("N = ", valid_n),
        paste0("Mean = ", mean_val),
        paste0("Median = ", median_val),
        paste0("SD = ", sd_val)
      )
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
tryCatch({
  item_labels <- c("Advertising Agency", "Marketing/Market Research Firm", "Public Relations Firm", "Any media company (Print, Radio, TV, Internet)", "Pharmaceutical Drug / Device Manufacturer (outside of clinical trials)", "Governmental Regulatory Agency (e.g., Food & Drug Administration (FDA))", "None of these")
  table_s5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("S5r1" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r2" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r3" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r4" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r5" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r6" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S5r7" %in% names(cut_data)) {
      count <- sum(cut_data$`S5r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
tryCatch({
  item_labels <- c("Treating/Managing patients", "Performing academic functions (e.g., teaching, publishing)", "Participating in clinical research", "Performing other functions")
  table_s8 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("S8r1" %in% names(cut_data)) {
      count <- sum(cut_data$`S8r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r2" %in% names(cut_data)) {
      count <- sum(cut_data$`S8r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r3" %in% names(cut_data)) {
      count <- sum(cut_data$`S8r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S8r4" %in% names(cut_data)) {
      count <- sum(cut_data$`S8r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
tryCatch({
  item_labels <- c("Over 5 years ago", "Within the last 3-5 years", "Within the last 1-2 years", "Within the last year")
  table_s12 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("S12r1" %in% names(cut_data)) {
      count <- sum(cut_data$`S12r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r2" %in% names(cut_data)) {
      count <- sum(cut_data$`S12r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r3" %in% names(cut_data)) {
      count <- sum(cut_data$`S12r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("S12r4" %in% names(cut_data)) {
      count <- sum(cut_data$`S12r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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

# Multi-sub Table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments?
# Items: 4
tryCatch({
  item_labels <- c("Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)")
  table_a1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A1r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A1r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A1r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a1[[cut_name]] <- col_values
  }
  results[["a1"]] <- table_a1
  print(paste("✓ Generated multi-sub table: A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments?':", e$message))
})

# Multi-sub Table: A3: For your LAST 100 [res PatientHoverover] with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?
# Items: 7
tryCatch({
  item_labels <- c("Statin only (i.e., no additional therapy)", "Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Zetia (ezetimibe) or generic ezetimibe", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)", "Other")
  table_a3 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A3r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A3r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
# Items: 10
tryCatch({
  item_labels <- c("In addition to statin", "Without a statin", "In addition to statin", "Without a statin", "In addition to statin", "Without a statin", "In addition to statin", "Without a statin", "In addition to statin", "Without a statin")
  table_a3a <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A3ar1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3ar5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3ar5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3a[[cut_name]] <- col_values
  }
  results[["a3a"]] <- table_a3a
  print(paste("✓ Generated multi-sub table: A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?':", e$message))
})

# Multi-sub Table: A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�
# Items: 10
tryCatch({
  item_labels <- c("BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy", "BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy", "BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy", "BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy", "BEFORE any other lipid-lowering therapy (i.e., first line)", "AFTER trying another lipid-lowering therapy")
  table_a3b <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A3br1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A3br5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A3br5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a3b[[cut_name]] <- col_values
  }
  results[["a3b"]] <- table_a3b
  print(paste("✓ Generated multi-sub table: A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�':", e$message))
})

# Multi-sub Table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 14
tryCatch({
  item_labels <- c("Statin only (i.e., no additional therapy)", "Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Zetia (ezetimibe) or generic ezetimibe", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)", "Other", "Statin only (i.e., no additional therapy)", "Leqvio (inclisiran)", "Praluent (alirocumab)", "Repatha (evolocumab)", "Zetia (ezetimibe) or generic ezetimibe", "Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)", "Other")
  table_a4 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A4r1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r6c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r6c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r7c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r7c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r6c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r6c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4r7c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4r7c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4[[cut_name]] <- col_values
  }
  results[["a4"]] <- table_a4
  print(paste("✓ Generated multi-sub table: A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.
# Items: 10
tryCatch({
  item_labels <- c("NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C", "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C")
  table_a4a <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A4ar1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4ar5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4ar5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4a[[cut_name]] <- col_values
  }
  results[["a4a"]] <- table_a4a
  print(paste("✓ Generated multi-sub table: A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses."))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.':", e$message))
})

# Multi-sub Table: A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�
# Items: 10
tryCatch({
  item_labels <- c("Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation", "Next treatment allocation")
  table_a4b <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A4br1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A4br5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A4br5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a4b[[cut_name]] <- col_values
  }
  results[["a4b"]] <- table_a4b
  print(paste("✓ Generated multi-sub table: A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�':", e$message))
})

# Multi-sub Table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow?
# Items: 8
tryCatch({
  item_labels <- c("Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed", "Start statin and ezetimibe or Nexletol/Nexlizet at the same time", "Start ezetimibe or Nexletol/Nexlizet, no statin", "Start statin first, add/switch to PCSK9i if needed", "Start statin and PCSK9i at the same time", "Start PCSK9i, no statin", "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that", "Other")
  table_a6 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A6r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r7" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A6r8" %in% names(cut_data)) {
      count <- sum(cut_data$`A6r8` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a6[[cut_name]] <- col_values
  }
  results[["a6"]] <- table_a6
  print(paste("✓ Generated multi-sub table: A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow?':", e$message))
})

# Multi-sub Table: A7: How might being able to use PCKS9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?
# Items: 5
tryCatch({
  item_labels <- c("Makes PCSK9s easier to get covered by insurance / get patients on the medication", "Offers an option to patients who can�t or won�t take a statin", "Enables me to use PCSK9s sooner for patients", "Allows me to better customize treatment plans for patients", "Other (Specify)")
  table_a7 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A7r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A7r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A7r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
# Items: 15
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio", "Repatha", "Praluent", "Leqvio", "Repatha", "Praluent", "Leqvio", "Repatha", "Praluent", "Leqvio", "Repatha", "Praluent", "Leqvio")
  table_a8 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A8r1c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r1c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r1c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r1c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r2c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r2c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r2c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r2c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r3c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r3c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r3c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r3c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r4c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r4c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r4c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r4c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r5c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r5c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A8r5c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A8r5c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a8[[cut_name]] <- col_values
  }
  results[["a8"]] <- table_a8
  print(paste("✓ Generated multi-sub table: A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?':", e$message))
})

# Multi-sub Table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?
# Items: 3
tryCatch({
  item_labels <- c("Repatha", "Praluent", "Leqvio")
  table_a9 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A9c1" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c2" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A9c3" %in% names(cut_data)) {
      count <- sum(cut_data$`A9c3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    table_a9[[cut_name]] <- col_values
  }
  results[["a9"]] <- table_a9
  print(paste("✓ Generated multi-sub table: A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?"))
}, error = function(e) {
  print(paste("✗ Error generating multi-sub table 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?':", e$message))
})

# Multi-sub Table: A10: For what reasons are you using PCSK9 inhibitors without a statin today?
# Items: 6
tryCatch({
  item_labels <- c("Patient failed statins prior to starting PCSK9i", "Patient is statin intolerant", "Patient refused statins", "Statins are contraindicated for patient", "Patient not or unlikely to be compliant on statins", "Haven�t prescribed PCSK9s without a statin")
  table_a10 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("A10r1" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r2" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r3" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r4" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r5" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("A10r6" %in% names(cut_data)) {
      count <- sum(cut_data$`A10r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
tryCatch({
  item_labels <- c("Not insured", "Private insurance provided by employer / purchased in exchange", "Traditional Medicare (Medicare Part B Fee for Service)", "Traditional Medicare with supplemental insurance", "Private Medicare (Medicare Advantage / Part C managed through Private payer)", "Medicaid", "Veterans Administration (VA)", "Other")
  table_b1 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("B1r1" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r2" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r3" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r4" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r5" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r6" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r6` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r7" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r7` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B1r8" %in% names(cut_data)) {
      count <- sum(cut_data$`B1r8` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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
tryCatch({
  item_labels <- c("Internal Medicine", "General Practitioner", "Primary Care", "Family Practice", "Doctor of Osteopathic Medicine (DO)")
  table_b5 <- data.frame(Item = item_labels, stringsAsFactors = FALSE)
  for (cut_name in names(cuts)) {
    cut_data <- data[cuts[[cut_name]], ]
    base_n <- nrow(cut_data)
    col_values <- character(0)
    if ("B5r1" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r1` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r2" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r2` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r3" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r3` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r4" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r4` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
    } else {
      col_values <- c(col_values, "N/A")
    }
    if ("B5r5" %in% names(cut_data)) {
      count <- sum(cut_data$`B5r5` == 1, na.rm = TRUE)
      pct <- calc_pct(count, base_n)
      col_values <- c(col_values, paste0(count, " (", pct, "%)"))
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