# HawkTab AI — master R (deterministic)
# Session: output-2025-08-11T15-30-20-762Z
# Generated: 2025-08-11T15:51:49.005Z

library(haven)
library(jsonlite)
library(dplyr)
data <- read_sav('temp-outputs/output-2025-08-11T15-30-20-762Z/dataFile.sav')

# Load preflight statistics if available
preflight_path <- 'temp-outputs/output-2025-08-11T15-30-20-762Z/r/preflight.json'
preflight_stats <- NULL
if (file.exists(preflight_path)) {
  preflight_stats <- fromJSON(preflight_path)
  cat("Loaded preflight statistics\n")
} else {
  cat("No preflight statistics found, using defaults\n")
}

warnings <- character()

# Cut: Cards
cut_specialty_cards <- tryCatch({ with(data, (S2 == 1 & S2a == 1)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Cards', ':', e$message)); NULL })
# Cut: PCPs
cut_specialty_pcps <- tryCatch({ with(data, S2 == 2) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'PCPs', ':', e$message)); NULL })
# Cut: Nephs
cut_specialty_nephs <- tryCatch({ with(data, S2 == 3) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Nephs', ':', e$message)); NULL })
# Cut: Endos
cut_specialty_endos <- tryCatch({ with(data, S2 == 4) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Endos', ':', e$message)); NULL })
# Cut: Lipids
cut_specialty_lipids <- tryCatch({ with(data, S2 == 5) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Lipids', ':', e$message)); NULL })
# Cut: HCP
cut_role_hcp <- tryCatch({ with(data, S2b == 1) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'HCP', ':', e$message)); NULL })
# Cut: NP/PA
cut_role_np_pa <- tryCatch({ with(data, S2b %in% c(2,3)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'NP/PA', ':', e$message)); NULL })
# Cut: Higher
cut_volume_of_adult_ascvd_patients_higher <- tryCatch({ with(data, S11 >= median(S11, na.rm = TRUE)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Higher', ':', e$message)); NULL })
# Cut: Lower
cut_volume_of_adult_ascvd_patients_lower <- tryCatch({ with(data, S11 < median(S11, na.rm = TRUE)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Lower', ':', e$message)); NULL })
# Cut: Tier 1
cut_tiers_tier_1 <- tryCatch({ with(data, qLIST_TIER == 1) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 1', ':', e$message)); NULL })
# Cut: Tier 2
cut_tiers_tier_2 <- tryCatch({ with(data, qLIST_TIER == 2) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 2', ':', e$message)); NULL })
# Cut: Tier 3
cut_tiers_tier_3 <- tryCatch({ with(data, qLIST_TIER == 3) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 3', ':', e$message)); NULL })
# Cut: Tier 4
cut_tiers_tier_4 <- tryCatch({ with(data, qLIST_TIER == 4) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 4', ':', e$message)); NULL })
# Cut: Segment A
cut_segments_segment_a <- tryCatch({ with(data, Segment == "A") }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment A', ':', e$message)); NULL })
# Cut: Segment B
cut_segments_segment_b <- tryCatch({ with(data, Segment == "B") }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment B', ':', e$message)); NULL })
# Cut: Segment C
cut_segments_segment_c <- tryCatch({ with(data, Segment == "C") }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment C', ':', e$message)); NULL })
# Cut: Segment D
cut_segments_segment_d <- tryCatch({ with(data, Segment == "D") }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment D', ':', e$message)); NULL })
# Cut: Priority Account
cut_priority_accounts_priority_account <- tryCatch({ with(data, qLIST_PRIORITY_ACCOUNT == 1) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Priority Account', ':', e$message)); NULL })
# Cut: Non-Priority Account
cut_priority_accounts_non_priority_account <- tryCatch({ with(data, qLIST_PRIORITY_ACCOUNT == 2) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Non-Priority Account', ':', e$message)); NULL })
# Cut: Total
cut_total_total <- tryCatch({ with(data, status == 3) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Total', ':', e$message)); NULL })

cuts <- list()
if (!is.null(cut_specialty_cards) && is.logical(cut_specialty_cards)) { cuts[['Cards']] <- cut_specialty_cards } else { warnings <- c(warnings, paste0('cut_invalid:', 'Cards')) }
if (!is.null(cut_specialty_pcps) && is.logical(cut_specialty_pcps)) { cuts[['PCPs']] <- cut_specialty_pcps } else { warnings <- c(warnings, paste0('cut_invalid:', 'PCPs')) }
if (!is.null(cut_specialty_nephs) && is.logical(cut_specialty_nephs)) { cuts[['Nephs']] <- cut_specialty_nephs } else { warnings <- c(warnings, paste0('cut_invalid:', 'Nephs')) }
if (!is.null(cut_specialty_endos) && is.logical(cut_specialty_endos)) { cuts[['Endos']] <- cut_specialty_endos } else { warnings <- c(warnings, paste0('cut_invalid:', 'Endos')) }
if (!is.null(cut_specialty_lipids) && is.logical(cut_specialty_lipids)) { cuts[['Lipids']] <- cut_specialty_lipids } else { warnings <- c(warnings, paste0('cut_invalid:', 'Lipids')) }
if (!is.null(cut_role_hcp) && is.logical(cut_role_hcp)) { cuts[['HCP']] <- cut_role_hcp } else { warnings <- c(warnings, paste0('cut_invalid:', 'HCP')) }
if (!is.null(cut_role_np_pa) && is.logical(cut_role_np_pa)) { cuts[['NP/PA']] <- cut_role_np_pa } else { warnings <- c(warnings, paste0('cut_invalid:', 'NP/PA')) }
if (!is.null(cut_volume_of_adult_ascvd_patients_higher) && is.logical(cut_volume_of_adult_ascvd_patients_higher)) { cuts[['Higher']] <- cut_volume_of_adult_ascvd_patients_higher } else { warnings <- c(warnings, paste0('cut_invalid:', 'Higher')) }
if (!is.null(cut_volume_of_adult_ascvd_patients_lower) && is.logical(cut_volume_of_adult_ascvd_patients_lower)) { cuts[['Lower']] <- cut_volume_of_adult_ascvd_patients_lower } else { warnings <- c(warnings, paste0('cut_invalid:', 'Lower')) }
if (!is.null(cut_tiers_tier_1) && is.logical(cut_tiers_tier_1)) { cuts[['Tier 1']] <- cut_tiers_tier_1 } else { warnings <- c(warnings, paste0('cut_invalid:', 'Tier 1')) }
if (!is.null(cut_tiers_tier_2) && is.logical(cut_tiers_tier_2)) { cuts[['Tier 2']] <- cut_tiers_tier_2 } else { warnings <- c(warnings, paste0('cut_invalid:', 'Tier 2')) }
if (!is.null(cut_tiers_tier_3) && is.logical(cut_tiers_tier_3)) { cuts[['Tier 3']] <- cut_tiers_tier_3 } else { warnings <- c(warnings, paste0('cut_invalid:', 'Tier 3')) }
if (!is.null(cut_tiers_tier_4) && is.logical(cut_tiers_tier_4)) { cuts[['Tier 4']] <- cut_tiers_tier_4 } else { warnings <- c(warnings, paste0('cut_invalid:', 'Tier 4')) }
if (!is.null(cut_segments_segment_a) && is.logical(cut_segments_segment_a)) { cuts[['Segment A']] <- cut_segments_segment_a } else { warnings <- c(warnings, paste0('cut_invalid:', 'Segment A')) }
if (!is.null(cut_segments_segment_b) && is.logical(cut_segments_segment_b)) { cuts[['Segment B']] <- cut_segments_segment_b } else { warnings <- c(warnings, paste0('cut_invalid:', 'Segment B')) }
if (!is.null(cut_segments_segment_c) && is.logical(cut_segments_segment_c)) { cuts[['Segment C']] <- cut_segments_segment_c } else { warnings <- c(warnings, paste0('cut_invalid:', 'Segment C')) }
if (!is.null(cut_segments_segment_d) && is.logical(cut_segments_segment_d)) { cuts[['Segment D']] <- cut_segments_segment_d } else { warnings <- c(warnings, paste0('cut_invalid:', 'Segment D')) }
if (!is.null(cut_priority_accounts_priority_account) && is.logical(cut_priority_accounts_priority_account)) { cuts[['Priority Account']] <- cut_priority_accounts_priority_account } else { warnings <- c(warnings, paste0('cut_invalid:', 'Priority Account')) }
if (!is.null(cut_priority_accounts_non_priority_account) && is.logical(cut_priority_accounts_non_priority_account)) { cuts[['Non-Priority Account']] <- cut_priority_accounts_non_priority_account } else { warnings <- c(warnings, paste0('cut_invalid:', 'Non-Priority Account')) }
if (!is.null(cut_total_total) && is.logical(cut_total_total)) { cuts[['Total']] <- cut_total_total } else { warnings <- c(warnings, paste0('cut_invalid:', 'Total')) }

preflight_cuts <- lapply(names(cuts), function(nm) list(name = nm, valid = TRUE, error = NA))

dir.create('temp-outputs/output-2025-08-11T15-30-20-762Z/results', recursive = TRUE, showWarnings = FALSE)

# Enhanced write_table with preflight statistics
write_table <- function(data, var_name, levels_df, table_id, table_meta = NULL) {
  v <- tryCatch({ data[[var_name]] }, error = function(e) { warnings <<- c(warnings, paste0('var:', var_name, ':', e$message)); return(NULL) })
  if (is.null(v)) { return(invisible(NULL)) }
  
  # Check for preflight stats for this variable
  var_stats <- NULL
  bucket_edges <- NULL
  if (!is.null(preflight_stats) && !is.null(preflight_stats$variables[[var_name]])) {
    var_stats <- preflight_stats$variables[[var_name]]
    bucket_edges <- var_stats$bucketEdges
  }
  
  # Use bucketing for numeric variables if available
  if (!is.null(bucket_edges) && is.numeric(v) && is.null(levels_df)) {
    # Create buckets using preflight edges
    v_bucketed <- cut(v, breaks = bucket_edges, include.lowest = TRUE, right = FALSE)
    levels(v_bucketed) <- paste0("[", head(bucket_edges, -1), "-", tail(bucket_edges, -1), ")")
    v <- v_bucketed
  } else if (!is.null(levels_df)) {
    v <- factor(v, levels = levels_df$value, labels = levels_df$label)
  }
  
  count_list <- lapply(cuts, function(idx) {
    tab <- table(v[idx], useNA = 'no')
    if (is.factor(v)) {
      lv <- levels(v)
      res <- as.integer(tab[lv])
      res[is.na(res)] <- 0
      res
    } else {
      as.integer(tab)
    }
  })
  counts <- do.call(cbind, count_list)
  colnames(counts) <- names(cuts)
  rn <- if (is.factor(v)) levels(v) else rownames(table(v))
  rownames(counts) <- rn
  col_totals <- colSums(counts)
  denom <- ifelse(col_totals == 0, 1, col_totals)
  perc <- sweep(counts, 2, denom, "/") * 100
  
  # Add numeric statistics if requested
  out <- data.frame(Level = rownames(counts), counts, perc, check.names = FALSE)
  
  # Append statistics row for numeric variables
  if (!is.null(var_stats) && !is.null(table_meta$numericMetrics)) {
    if (table_meta$numericMetrics$mean || table_meta$numericMetrics$median || table_meta$numericMetrics$sd) {
      stats_row <- data.frame(Level = "Statistics", matrix(NA, nrow = 1, ncol = ncol(out) - 1), check.names = FALSE)
      if (table_meta$numericMetrics$mean) {
        stats_row$Level <- paste0(stats_row$Level, " Mean=", round(var_stats$mean, 2))
      }
      if (table_meta$numericMetrics$median) {
        stats_row$Level <- paste0(stats_row$Level, " Median=", round(var_stats$median, 2))
      }
      if (table_meta$numericMetrics$sd) {
        stats_row$Level <- paste0(stats_row$Level, " SD=", round(var_stats$sd, 2))
      }
      out <- rbind(out, stats_row)
    }
  }
  
  write.csv(out, sprintf('temp-outputs/output-2025-08-11T15-30-20-762Z/results/%s.csv', table_id), row.names = FALSE)
}

write_multi_table <- function(data, items_df, cuts_list, table_id, title) {
  build_item <- function(row) { var <- row[['var']]; label <- row[['label']]; pos <- row[['positiveValue']];
    v <- tryCatch({ data[[var]] }, error = function(e) { warnings <<- c(warnings, paste0('var:', var, ':', e$message)); return(NULL) })
    if (is.null(v)) { return(NULL) }
    res_list <- lapply(cuts_list, function(idx) { sum(v[idx] == pos, na.rm = TRUE) })
    counts <- as.integer(unlist(res_list))
    names(counts) <- names(cuts_list)
    total <- sapply(cuts_list, function(idx) sum(!is.na(v[idx])))
    denom <- ifelse(total == 0, 1, total)
    perc <- (counts / denom) * 100
    data.frame(Item = label, t(counts), t(perc), check.names = FALSE)
  }
  rows <- lapply(seq_len(nrow(items_df)), function(i) build_item(items_df[i, ]))
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0) { warnings <<- c(warnings, paste0('multi_empty:', table_id)); return(invisible(NULL)) }
  out <- do.call(rbind, rows)
  write.csv(out, sprintf('temp-outputs/output-2025-08-11T15-30-20-762Z/results/%s.csv', table_id), row.names = FALSE)
}

preflight_vars <- list()
ok <- tryCatch({ data[['S1']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S1', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S1', valid=ok)))
if (ok) write_table(data, 'S1', NULL, 's1', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S2b']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S2b', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S2b', valid=ok)))
if (ok) write_table(data, 'S2b', NULL, 's2b', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S2']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S2', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S2', valid=ok)))
if (ok) write_table(data, 'S2', NULL, 's2', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S2a']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S2a', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S2a', valid=ok)))
if (ok) write_table(data, 'S2a', NULL, 's2a', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['qCARD_SPECIALTY']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qCARD_SPECIALTY', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qCARD_SPECIALTY', valid=ok)))
if (ok) write_table(data, 'qCARD_SPECIALTY', data.frame(value=c(1,2), label=c('CARD','NEPH/ENDO/LIP')), 'qcard-specialty', NULL)
ok <- tryCatch({ data[['qSPECIALTY']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qSPECIALTY', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qSPECIALTY', valid=ok)))
if (ok) write_table(data, 'qSPECIALTY', NULL, 'qspecialty', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S3a']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S3a', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S3a', valid=ok)))
if (ok) write_table(data, 'S3a', NULL, 's3a', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['qTYPE_OF_CARD']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qTYPE_OF_CARD', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qTYPE_OF_CARD', valid=ok)))
if (ok) write_table(data, 'qTYPE_OF_CARD', NULL, 'qtype-of-card', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['qON_LIST_OFF_LIST']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qON_LIST_OFF_LIST', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qON_LIST_OFF_LIST', valid=ok)))
if (ok) write_table(data, 'qON_LIST_OFF_LIST', NULL, 'qon-list-off-list', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['qLIST_TIER']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qLIST_TIER', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qLIST_TIER', valid=ok)))
if (ok) write_table(data, 'qLIST_TIER', data.frame(value=c(1,2,3,4), label=c('TIER 1','TIER 2','TIER 3','TIER 4')), 'qlist-tier', NULL)
ok <- tryCatch({ data[['qLIST_PRIORITY_ACCOUNT']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'qLIST_PRIORITY_ACCOUNT', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='qLIST_PRIORITY_ACCOUNT', valid=ok)))
if (ok) write_table(data, 'qLIST_PRIORITY_ACCOUNT', data.frame(value=c(1,2), label=c('PRIORITY','NOT PRIORITY')), 'qlist-priority-account', NULL)
ok <- tryCatch({ data[['S4']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S4', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S4', valid=ok)))
if (ok) write_table(data, 'S4', NULL, 's4', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S6']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S6', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S6', valid=ok)))
if (ok) write_table(data, 'S6', NULL, 's6', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S7']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S7', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S7', valid=ok)))
if (ok) write_table(data, 'S7', data.frame(value=c(1,2), label=c('Full-Time','Part-Time')), 's7', NULL)
ok <- tryCatch({ data[['S9']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S9', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S9', valid=ok)))
if (ok) write_table(data, 'S9', NULL, 's9', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S10']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S10', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S10', valid=ok)))
if (ok) write_table(data, 'S10', NULL, 's10', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['S11']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'S11', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='S11', valid=ok)))
if (ok) write_table(data, 'S11', NULL, 's11', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['A2a']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'A2a', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='A2a', valid=ok)))
if (ok) write_table(data, 'A2a', NULL, 'a2a', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['A2b']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'A2b', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='A2b', valid=ok)))
if (ok) write_table(data, 'A2b', NULL, 'a2b', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['A5']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'A5', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='A5', valid=ok)))
if (ok) write_table(data, 'A5', data.frame(value=c(1,2,3,4), label=c('Within 3 months','4-6 months','7-12 months','Over a year')), 'a5', NULL)
ok <- tryCatch({ data[['US_State']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'US_State', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='US_State', valid=ok)))
if (ok) write_table(data, 'US_State', NULL, 'us-state', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['Region']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'Region', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='Region', valid=ok)))
if (ok) write_table(data, 'Region', NULL, 'region', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['B3']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'B3', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='B3', valid=ok)))
if (ok) write_table(data, 'B3', NULL, 'b3', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['B4']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'B4', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='B4', valid=ok)))
if (ok) write_table(data, 'B4', NULL, 'b4', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
ok <- tryCatch({ data[['QCONSENT']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', 'QCONSENT', ':', e$message)); FALSE })
preflight_vars <- append(preflight_vars, list(list(var='QCONSENT', valid=ok)))
if (ok) write_table(data, 'QCONSENT', NULL, 'qconsent', list(numericMetrics=list(mean=TRUE, median=TRUE, sd=TRUE)))
items_df <- data.frame(var=c('S5r1','S5r2','S5r3','S5r4','S5r5','S5r6','S5r7'), label=c('Advertising Agency','Marketing/Market Research Firm','Public Relations Firm','Any media company (Print, Radio, TV, Internet)','Pharmaceutical Drug / Device Manufacturer (outside of clinical trials)','Governmental Regulatory Agency (e.g., Food & Drug Administration (FDA))','None of these'), positiveValue=c(1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 's5', 'S5: Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following?')
items_df <- data.frame(var=c('S8r1','S8r2','S8r3','S8r4'), label=c('Treating/Managing patients','Performing academic functions (e.g., teaching, publishing)','Participating in clinical research','Performing other functions'), positiveValue=c(1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 's8', 'S8: Approximately what percentage of your professional time is spent performing each of the following activities?')
items_df <- data.frame(var=c('S12r1','S12r2','S12r3','S12r4'), label=c('Over 5 years ago','Within the last 3-5 years','Within the last 1-2 years','Within the last year'), positiveValue=c(1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 's12', 'S12: Of those, how many patients have had an event (MI, CAD, coronary revascularization, stent placement, etc.) �')
items_df <- data.frame(var=c('A1r1','A1r2','A1r3','A1r4'), label=c('Leqvio (inclisiran)','Praluent (alirocumab)','Repatha (evolocumab)','Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)'), positiveValue=c(1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a1', 'A1: To the best of your knowledge, which statement below best describes the current indication for each of the following treatments?')
items_df <- data.frame(var=c('A3r1','A3r2','A3r3','A3r4','A3r5','A3r6','A3r7'), label=c('Statin only (i.e., no additional therapy)','Leqvio (inclisiran)','Praluent (alirocumab)','Repatha (evolocumab)','Zetia (ezetimibe) or generic ezetimibe','Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)','Other'), positiveValue=c(1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a3', 'A3: For your LAST 100 [res PatientHoverover] with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?')
items_df <- data.frame(var=c('A3ar1c1','A3ar1c2','A3ar2c1','A3ar2c2','A3ar3c1','A3ar3c2','A3ar4c1','A3ar4c2','A3ar5c1','A3ar5c2'), label=c('In addition to statin','Without a statin','In addition to statin','Without a statin','In addition to statin','Without a statin','In addition to statin','Without a statin','In addition to statin','Without a statin'), positiveValue=c(1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a3a', 'A3ar1: Leqvio (inclisiran) - For each treatment, approximately what % of those LAST 100 [res PatientHoverover] received that therapy in addition to a statin vs. without a statin?')
items_df <- data.frame(var=c('A3br1c1','A3br1c2','A3br2c1','A3br2c2','A3br3c1','A3br3c2','A3br4c1','A3br4c2','A3br5c1','A3br5c2'), label=c('BEFORE any other lipid-lowering therapy (i.e., first line)','AFTER trying another lipid-lowering therapy','BEFORE any other lipid-lowering therapy (i.e., first line)','AFTER trying another lipid-lowering therapy','BEFORE any other lipid-lowering therapy (i.e., first line)','AFTER trying another lipid-lowering therapy','BEFORE any other lipid-lowering therapy (i.e., first line)','AFTER trying another lipid-lowering therapy','BEFORE any other lipid-lowering therapy (i.e., first line)','AFTER trying another lipid-lowering therapy'), positiveValue=c(1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a3b', 'A3br1: Leqvio (inclisiran) - For each treatment you just indicated that you prescribe without a statin, approximately what % of those [res PatientHoverover] who received that therapy without a statin did so�')
items_df <- data.frame(var=c('A4r1c1','A4r2c1','A4r3c1','A4r4c1','A4r5c1','A4r6c1','A4r7c1','A4r1c2','A4r2c2','A4r3c2','A4r4c2','A4r5c2','A4r6c2','A4r7c2'), label=c('Statin only (i.e., no additional therapy)','Leqvio (inclisiran)','Praluent (alirocumab)','Repatha (evolocumab)','Zetia (ezetimibe) or generic ezetimibe','Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)','Other','Statin only (i.e., no additional therapy)','Leqvio (inclisiran)','Praluent (alirocumab)','Repatha (evolocumab)','Zetia (ezetimibe) or generic ezetimibe','Nexletol (bempedoic acid) or Nexlizet (bempedoic acid and ezetimibe)','Other'), positiveValue=c(1,1,1,1,1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a4', 'A4c1: LAST 100 [res PatientHoverover2] with Uncontrolled LDL-C - Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data, but without any new clinical data beyond what is already available today. In that future state, for your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.')
items_df <- data.frame(var=c('A4ar1c1','A4ar1c2','A4ar2c1','A4ar2c2','A4ar3c1','A4ar3c2','A4ar4c1','A4ar4c2','A4ar5c1','A4ar5c2'), label=c('NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C','NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C'), positiveValue=c(1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a4a', 'A4ar1: Leqvio (inclisiran) - For each treatment, for approximately what % of those NEXT 100 [res PatientHoverover] would you expect to prescribe that therapy in addition to a statin vs. without a statin? Your responses from the previous question are included for reference. If you do not believe this would impact your prescribing, it is fine to input the same responses.')
items_df <- data.frame(var=c('A4br1c1','A4br1c2','A4br2c1','A4br2c2','A4br3c1','A4br3c2','A4br4c1','A4br4c2','A4br5c1','A4br5c2'), label=c('Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation','Next treatment allocation'), positiveValue=c(1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a4b', 'A4br1: Leqvio (inclisiran) - For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those [res PatientHoverover] who would receive that therapy without a statin would do so�')
items_df <- data.frame(var=c('A6r1','A6r2','A6r3','A6r4','A6r5','A6r6','A6r7','A6r8'), label=c('Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed','Start statin and ezetimibe or Nexletol/Nexlizet at the same time','Start ezetimibe or Nexletol/Nexlizet, no statin','Start statin first, add/switch to PCSK9i if needed','Start statin and PCSK9i at the same time','Start PCSK9i, no statin','Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed, add/switch to PCSK9i if needed after that','Other'), positiveValue=c(1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a6', 'A6: Again, please assume that the FDA decides that all PCSK9 inhibitors (Repatha, Praluent, Leqvio) will now be indicated for use as an adjunct to diet and exercise, alone or in combination with other LDL-C-lowering therapies, in adults with primary hyperlipidemia � and that this change is being made after reviewing existing data but without any new clinical data beyond what is already available today. For your NEXT 100 [res PatientHoverover] with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow?')
items_df <- data.frame(var=c('A7r1','A7r2','A7r3','A7r4','A7r5'), label=c('Makes PCSK9s easier to get covered by insurance / get patients on the medication','Offers an option to patients who can�t or won�t take a statin','Enables me to use PCSK9s sooner for patients','Allows me to better customize treatment plans for patients','Other (Specify)'), positiveValue=c(1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a7', 'A7: How might being able to use PCKS9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing?')
items_df <- data.frame(var=c('A8r1c1','A8r1c2','A8r1c3','A8r2c1','A8r2c2','A8r2c3','A8r3c1','A8r3c2','A8r3c3','A8r4c1','A8r4c2','A8r4c3','A8r5c1','A8r5c2','A8r5c3'), label=c('Repatha','Praluent','Leqvio','Repatha','Praluent','Leqvio','Repatha','Praluent','Leqvio','Repatha','Praluent','Leqvio','Repatha','Praluent','Leqvio'), positiveValue=c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a8', 'A8r1: With established CVD - For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin, ezetimibe or Nexletol/Nexlizet)?')
items_df <- data.frame(var=c('A9c1','A9c2','A9c3'), label=c('Repatha','Praluent','Leqvio'), positiveValue=c(1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a9', 'A9: To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today?')
items_df <- data.frame(var=c('A10r1','A10r2','A10r3','A10r4','A10r5','A10r6'), label=c('Patient failed statins prior to starting PCSK9i','Patient is statin intolerant','Patient refused statins','Statins are contraindicated for patient','Patient not or unlikely to be compliant on statins','Haven�t prescribed PCSK9s without a statin'), positiveValue=c(1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'a10', 'A10: For what reasons are you using PCSK9 inhibitors without a statin today?')
items_df <- data.frame(var=c('B1r1','B1r2','B1r3','B1r4','B1r5','B1r6','B1r7','B1r8'), label=c('Not insured','Private insurance provided by employer / purchased in exchange','Traditional Medicare (Medicare Part B Fee for Service)','Traditional Medicare with supplemental insurance','Private Medicare (Medicare Advantage / Part C managed through Private payer)','Medicaid','Veterans Administration (VA)','Other'), positiveValue=c(1,1,1,1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'b1', 'B1: What percentage of your current [res PatientHoverover] are covered by each type of insurance?')
items_df <- data.frame(var=c('B5r1','B5r2','B5r3','B5r4','B5r5'), label=c('Internal Medicine','General Practitioner','Primary Care','Family Practice','Doctor of Osteopathic Medicine (DO)'), positiveValue=c(1,1,1,1,1), stringsAsFactors=FALSE)
write_multi_table(data, items_df, cuts, 'b5', 'B5: How would you describe your specialty/training?')
preflight <- list(cuts = preflight_cuts, vars = preflight_vars, warnings = warnings)
write_json(preflight, 'temp-outputs/output-2025-08-11T15-30-20-762Z/r/preflight.json', auto_unbox = TRUE, pretty = TRUE)
