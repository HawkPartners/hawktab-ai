# HawkTab AI — master R (deterministic)
# Session: output-2025-08-08T21-49-52-983Z
# Generated: 2025-08-08T21:53:46.658Z

library(haven)
library(jsonlite)
data <- read_sav('temp-outputs/output-2025-08-08T21-49-52-983Z/dataFile.sav')

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
cut_role_hcp <- tryCatch({ with(data, S2b %in% c(1,2,3)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'HCP', ':', e$message)); NULL })
# Cut: NP/PA
cut_role_np_pa <- tryCatch({ with(data, S2b %in% c(2,3)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'NP/PA', ':', e$message)); NULL })
# Cut: Higher
cut_volume_of_adult_ascvd_patients_higher <- tryCatch({ with(data, !is.na(S11) & S11 >= median(S11, na.rm = TRUE)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Higher', ':', e$message)); NULL })
# Cut: Lower
cut_volume_of_adult_ascvd_patients_lower <- tryCatch({ with(data, !is.na(S11) & S11 < median(S11, na.rm = TRUE)) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Lower', ':', e$message)); NULL })
# Cut: Tier 1
cut_tiers_tier_1 <- tryCatch({ with(data, qLIST_TIER == 1) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 1', ':', e$message)); NULL })
# Cut: Tier 2
cut_tiers_tier_2 <- tryCatch({ with(data, qLIST_TIER == 2) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 2', ':', e$message)); NULL })
# Cut: Tier 3
cut_tiers_tier_3 <- tryCatch({ with(data, qLIST_TIER == 3) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 3', ':', e$message)); NULL })
# Cut: Tier 4
cut_tiers_tier_4 <- tryCatch({ with(data, qLIST_TIER == 4) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Tier 4', ':', e$message)); NULL })
# Cut: Segment A
cut_segments_segment_a <- tryCatch({ with(data, (Segment == "Segment A")) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment A', ':', e$message)); NULL })
# Cut: Segment B
cut_segments_segment_b <- tryCatch({ with(data, (Segment == "Segment B")) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment B', ':', e$message)); NULL })
# Cut: Segment C
cut_segments_segment_c <- tryCatch({ with(data, (Segment == "Segment C")) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment C', ':', e$message)); NULL })
# Cut: Segment D
cut_segments_segment_d <- tryCatch({ with(data, (Segment == "Segment D")) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', 'Segment D', ':', e$message)); NULL })
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

dir.create('temp-outputs/output-2025-08-08T21-49-52-983Z/results', recursive = TRUE, showWarnings = FALSE)
write_table <- function(data, var_name, levels_df, table_id) {
  v <- tryCatch({ data[[var_name]] }, error = function(e) { warnings <<- c(warnings, paste0('var:', var_name, ':', e$message)); return(NULL) })
  if (is.null(v)) { return(invisible(NULL)) }
  if (!is.null(levels_df)) {
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
  out <- data.frame(Level = rownames(counts), counts, perc, check.names = FALSE)
  write.csv(out, sprintf('temp-outputs/output-2025-08-08T21-49-52-983Z/results/%s.csv', table_id), row.names = FALSE)
}

preflight_vars <- list()
preflight <- list(cuts = preflight_cuts, vars = preflight_vars, warnings = warnings)
write_json(preflight, 'temp-outputs/output-2025-08-08T21-49-52-983Z/r/preflight.json', auto_unbox = TRUE, pretty = TRUE)
