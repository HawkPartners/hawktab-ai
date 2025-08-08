# HawkTab AI — master R (deterministic)
# Session: output-2025-08-08T20-43-32-687Z
# Generated: 2025-08-08T20:47:03.910Z

library(haven)
data <- read_sav('temp-outputs/output-2025-08-08T20-43-32-687Z/dataFile.sav')

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

cuts <- list(
  'Cards' = cut_specialty_cards,
  'PCPs' = cut_specialty_pcps,
  'Nephs' = cut_specialty_nephs,
  'Endos' = cut_specialty_endos,
  'Lipids' = cut_specialty_lipids
)

dir.create('temp-outputs/output-2025-08-08T20-43-32-687Z/results', recursive = TRUE, showWarnings = FALSE)
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
  write.csv(out, sprintf('temp-outputs/output-2025-08-08T20-43-32-687Z/results/%s.csv', table_id), row.names = FALSE)
}

write_table(data, 'status', data.frame(value=c(1,2,3,4), label=c('Terminated','Overquota','Qualified','Partial')), 'status')
write_table(data, 'S1', data.frame(value=c(1,2,3), label=c('I would like to proceed and protect my identity','I would like to proceed and give permission for my contact details to be passed on to the Drug Safety department of the company if an adverse event is mentioned by me during the survey','I don�t want to proceed')), 's1')
write_table(data, 'S2b', data.frame(value=c(1,2,3,99), label=c('Physician','Nurse Practitioner','Physician�s Assistant','Other')), 's2b')
write_table(data, 'S2', data.frame(value=c(1,2,3,4,5,6,7,99), label=c('Cardiologist','Internal Medicine / General Practitioner / Primary Care / Family Practice','Nephrologist','Endocrinologist','Lipidologist','Nurse Practitioner','Physician�s Assistant','Other')), 's2')
write_table(data, 'S2a', data.frame(value=c(1,2,3), label=c('Cardiologist','Internal Medicine / General Practitioner / Primary Care / Family Practice','Other')), 's2a')
write_table(data, 'qCARD_SPECIALTY', data.frame(value=c(1,2), label=c('CARD','NEPH/ENDO/LIP')), 'qcard-specialty')
write_table(data, 'qSPECIALTY', data.frame(value=c(1,2,3), label=c('CARD','PCP','NPPA')), 'qspecialty')
write_table(data, 'S3a', data.frame(value=c(1,2,3), label=c('Interventional Cardiologist','General Cardiologist','Preventative Cardiologist')), 's3a')
write_table(data, 'qTYPE_OF_CARD', data.frame(value=c(1,2,3), label=c('Interventional Card','General Card','Preventative Card')), 'qtype-of-card')
write_table(data, 'qON_LIST_OFF_LIST', data.frame(value=c(1,2,3,4,5,6), label=c('CARD ON-LIST','CARD OFF-LIST','PCP ON-LIST','PCP OFF-LIST','NPPA ON-LIST','NPPA OFF-LIST')), 'qon-list-off-list')
write_table(data, 'qLIST_TIER', data.frame(value=c(1,2,3,4), label=c('TIER 1','TIER 2','TIER 3','TIER 4')), 'qlist-tier')
write_table(data, 'qLIST_PRIORITY_ACCOUNT', data.frame(value=c(1,2), label=c('PRIORITY','NOT PRIORITY')), 'qlist-priority-account')
write_table(data, 'S4', data.frame(value=c(1,2,3), label=c('Board Eligible','Board Certified','Neither')), 's4')
write_table(data, 'S7', data.frame(value=c(1,2), label=c('Full-Time','Part-Time')), 's7')
write_table(data, 'S9', data.frame(value=c(1,2,3,4,5,6,7,8), label=c('Private Solo Practice','Private Group Practice','Multi-specialty Practice / Comprehensive Care','Staff HMO','Community Hospital','Academic/University Hospital','VA Hospital','None of the above')), 's9')
write_table(data, 'A2a', data.frame(value=c(1,2,3), label=c('Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?55 mg/dL','Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?70 mg/dL','Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with LDL-C levels ?100 mg/dL')), 'a2a')
write_table(data, 'A2b', data.frame(value=c(1,2,3), label=c('Recommend a statin first','Recommend a statin + ezetimibe first','Recommend a PCSK9i first')), 'a2b')
write_table(data, 'A5', data.frame(value=c(1,2,3,4), label=c('Within 3 months','4-6 months','7-12 months','Over a year')), 'a5')
write_table(data, 'Region', data.frame(value=c(1,2,3,4,5,6), label=c('Northeast','South','Midwest','West','Other','Invalid Region')), 'region')
write_table(data, 'B3', data.frame(value=c(1,2,3), label=c('Urban','Suburban','Rural')), 'b3')
write_table(data, 'QCONSENT', data.frame(value=c(1,2), label=c('Yes','No')), 'qconsent')
