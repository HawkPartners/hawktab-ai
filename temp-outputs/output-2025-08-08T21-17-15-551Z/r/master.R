# HawkTab AI — master R (deterministic)
# Session: output-2025-08-08T21-17-15-551Z
# Generated: 2025-08-08T21:21:14.566Z

library(haven)
data <- read_sav('temp-outputs/output-2025-08-08T21-17-15-551Z/dataFile.sav')

# Cut: Cards
cut_specialty_cards <- with(data, (S2 == 1 & S2a == 1))
# Cut: PCPs
cut_specialty_pcps <- with(data, S2 == 2)
# Cut: Nephs
cut_specialty_nephs <- with(data, S2 == 3)
# Cut: Endos
cut_specialty_endos <- with(data, S2 == 4)
# Cut: Lipids
cut_specialty_lipids <- with(data, S2 == 5)
# Cut: HCP
cut_role_hcp <- with(data, S2b == 1)
# Cut: NP/PA
cut_role_np_pa <- with(data, S2b %in% c(2,3))
# Cut: Higher
cut_volume_of_adult_ascvd_patients_higher <- with(data, S11 >= median(S11, na.rm = TRUE))
# Cut: Lower
cut_volume_of_adult_ascvd_patients_lower <- with(data, S11 < median(S11, na.rm = TRUE))
# Cut: Tier 1
cut_tiers_tier_1 <- with(data, qLIST_TIER == 1)
# Cut: Tier 2
cut_tiers_tier_2 <- with(data, qLIST_TIER == 2)
# Cut: Tier 3
cut_tiers_tier_3 <- with(data, qLIST_TIER == 3)
# Cut: Tier 4
cut_tiers_tier_4 <- with(data, qLIST_TIER == 4)
# Cut: Segment A
cut_segments_segment_a <- with(data, Segment == "Segment A")
# Cut: Segment B
cut_segments_segment_b <- with(data, Segment == "Segment B")
# Cut: Segment C
cut_segments_segment_c <- with(data, Segment == "Segment C")
# Cut: Segment D
cut_segments_segment_d <- with(data, Segment == "Segment D")
# Cut: Priority Account
cut_priority_accounts_priority_account <- with(data, qLIST_PRIORITY_ACCOUNT == 1)
# Cut: Non-Priority Account
cut_priority_accounts_non_priority_account <- with(data, qLIST_PRIORITY_ACCOUNT == 2)
# Cut: Total
cut_total_total <- with(data, status == 3)

cuts <- list(
  'Cards' = cut_specialty_cards,
  'PCPs' = cut_specialty_pcps,
  'Nephs' = cut_specialty_nephs,
  'Endos' = cut_specialty_endos,
  'Lipids' = cut_specialty_lipids,
  'HCP' = cut_role_hcp,
  'NP/PA' = cut_role_np_pa,
  'Higher' = cut_volume_of_adult_ascvd_patients_higher,
  'Lower' = cut_volume_of_adult_ascvd_patients_lower,
  'Tier 1' = cut_tiers_tier_1,
  'Tier 2' = cut_tiers_tier_2,
  'Tier 3' = cut_tiers_tier_3,
  'Tier 4' = cut_tiers_tier_4,
  'Segment A' = cut_segments_segment_a,
  'Segment B' = cut_segments_segment_b,
  'Segment C' = cut_segments_segment_c,
  'Segment D' = cut_segments_segment_d,
  'Priority Account' = cut_priority_accounts_priority_account,
  'Non-Priority Account' = cut_priority_accounts_non_priority_account,
  'Total' = cut_total_total
)

dir.create('temp-outputs/output-2025-08-08T21-17-15-551Z/results', recursive = TRUE, showWarnings = FALSE)
write_table <- function(data, var_name, levels_df, table_id) {
  v <- data[[var_name]]
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
  write.csv(out, sprintf('temp-outputs/output-2025-08-08T21-17-15-551Z/results/%s.csv', table_id), row.names = FALSE)
}

