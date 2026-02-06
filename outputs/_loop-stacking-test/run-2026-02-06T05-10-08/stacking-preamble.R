# =============================================================================
# Loop Stacking: Create stacked data frames for looped questions
# 6 loop group(s) detected
# =============================================================================

# --- stacked_loop_1: 12 variables x 2 iterations ---
# Skeleton: A-N-_-N
# Iterations: 1, 2

stacked_loop_1 <- dplyr::bind_rows(
  data %>% dplyr::rename(A10 = A10_1, A11 = A11_1, A13 = A13_1, A15 = A15_1, A18 = A18_1, A1 = A1_1, A2 = A2_1, A3 = A3_1, A4 = A4_1, A5 = A5_1, A6 = A6_1, A8 = A8_1) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(A10 = A10_2, A11 = A11_2, A13 = A13_2, A15 = A15_2, A18 = A18_2, A1 = A1_2, A2 = A2_2, A3 = A3_2, A4 = A4_2, A5 = A5_2, A6 = A6_2, A8 = A8_2) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_1:", nrow(stacked_loop_1), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_1
cuts_stacked_loop_1 <- list(
  Total = rep(TRUE, nrow(stacked_loop_1))
,  `Male` = with(stacked_loop_1, gender == 1)
,  `Female` = with(stacked_loop_1, gender == 2)
)

cut_stat_letters_stacked_loop_1 <- cut_stat_letters

# --- stacked_loop_2: 6 variables x 2 iterations ---
# Skeleton: A-N-_-N-r-N-oe
# Iterations: 1, 2

stacked_loop_2 <- dplyr::bind_rows(
  data %>% dplyr::rename(A13r99oe = A13_1r99oe, A16r10oe = A16_1r10oe, A17r9oe = A17_1r9oe, A18r8oe = A18_1r8oe, A19r11oe = A19_1r11oe, A4r15oe = A4_1r15oe) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(A13r99oe = A13_2r99oe, A16r10oe = A16_2r10oe, A17r9oe = A17_2r9oe, A18r8oe = A18_2r8oe, A19r11oe = A19_2r11oe, A4r15oe = A4_2r15oe) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_2:", nrow(stacked_loop_2), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_2
cuts_stacked_loop_2 <- list(
  Total = rep(TRUE, nrow(stacked_loop_2))
,  `Male` = with(stacked_loop_2, gender == 1)
,  `Female` = with(stacked_loop_2, gender == 2)
)

cut_stat_letters_stacked_loop_2 <- cut_stat_letters

# --- stacked_loop_3: 5 variables x 2 iterations ---
# Skeleton: hCHANNEL-_-N-r-N
# Iterations: 1, 2

stacked_loop_3 <- dplyr::bind_rows(
  data %>% dplyr::rename(hCHANNELr1 = hCHANNEL_1r1, hCHANNELr2 = hCHANNEL_1r2, hCHANNELr3 = hCHANNEL_1r3, hCHANNELr4 = hCHANNEL_1r4, hCHANNELr5 = hCHANNEL_1r5) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(hCHANNELr1 = hCHANNEL_2r1, hCHANNELr2 = hCHANNEL_2r2, hCHANNELr3 = hCHANNEL_2r3, hCHANNELr4 = hCHANNEL_2r4, hCHANNELr5 = hCHANNEL_2r5) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_3:", nrow(stacked_loop_3), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_3
cuts_stacked_loop_3 <- list(
  Total = rep(TRUE, nrow(stacked_loop_3))
,  `Male` = with(stacked_loop_3, gender == 1)
,  `Female` = with(stacked_loop_3, gender == 2)
)

cut_stat_letters_stacked_loop_3 <- cut_stat_letters

# --- stacked_loop_4: 44 variables x 2 iterations ---
# Skeleton: A-N-_-N-r-N
# Iterations: 1, 2

stacked_loop_4 <- dplyr::bind_rows(
  data %>% dplyr::rename(A16r1 = A16_1r1, A16r10 = A16_1r10, A16r2 = A16_1r2, A16r3 = A16_1r3, A16r4 = A16_1r4, A16r5 = A16_1r5, A16r6 = A16_1r6, A16r7 = A16_1r7, A16r8 = A16_1r8, A16r9 = A16_1r9, A17r1 = A17_1r1, A17r2 = A17_1r2, A17r3 = A17_1r3, A17r4 = A17_1r4, A17r5 = A17_1r5, A17r6 = A17_1r6, A17r7 = A17_1r7, A17r8 = A17_1r8, A17r9 = A17_1r9, A19r1 = A19_1r1, A19r10 = A19_1r10, A19r11 = A19_1r11, A19r12 = A19_1r12, A19r2 = A19_1r2, A19r3 = A19_1r3, A19r4 = A19_1r4, A19r5 = A19_1r5, A19r6 = A19_1r6, A19r7 = A19_1r7, A19r8 = A19_1r8, A19r9 = A19_1r9, A7r1 = A7_1r1, A7r2 = A7_1r2, A7r3 = A7_1r3, A7r4 = A7_1r4, A7r5 = A7_1r5, A7r6 = A7_1r6, A9r1 = A9_1r1, A9r2 = A9_1r2, A9r3 = A9_1r3, A9r4 = A9_1r4, A9r5 = A9_1r5, A9r6 = A9_1r6, A9r7 = A9_1r7) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(A16r1 = A16_2r1, A16r10 = A16_2r10, A16r2 = A16_2r2, A16r3 = A16_2r3, A16r4 = A16_2r4, A16r5 = A16_2r5, A16r6 = A16_2r6, A16r7 = A16_2r7, A16r8 = A16_2r8, A16r9 = A16_2r9, A17r1 = A17_2r1, A17r2 = A17_2r2, A17r3 = A17_2r3, A17r4 = A17_2r4, A17r5 = A17_2r5, A17r6 = A17_2r6, A17r7 = A17_2r7, A17r8 = A17_2r8, A17r9 = A17_2r9, A19r1 = A19_2r1, A19r10 = A19_2r10, A19r11 = A19_2r11, A19r12 = A19_2r12, A19r2 = A19_2r2, A19r3 = A19_2r3, A19r4 = A19_2r4, A19r5 = A19_2r5, A19r6 = A19_2r6, A19r7 = A19_2r7, A19r8 = A19_2r8, A19r9 = A19_2r9, A7r1 = A7_2r1, A7r2 = A7_2r2, A7r3 = A7_2r3, A7r4 = A7_2r4, A7r5 = A7_2r5, A7r6 = A7_2r6, A9r1 = A9_2r1, A9r2 = A9_2r2, A9r3 = A9_2r3, A9r4 = A9_2r4, A9r5 = A9_2r5, A9r6 = A9_2r6, A9r7 = A9_2r7) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_4:", nrow(stacked_loop_4), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_4
cuts_stacked_loop_4 <- list(
  Total = rep(TRUE, nrow(stacked_loop_4))
,  `Male` = with(stacked_loop_4, gender == 1)
,  `Female` = with(stacked_loop_4, gender == 2)
)

cut_stat_letters_stacked_loop_4 <- cut_stat_letters

# --- stacked_loop_5: 5 variables x 2 iterations ---
# Skeleton: A-N-b-_-N-r-N
# Iterations: 1, 2

stacked_loop_5 <- dplyr::bind_rows(
  data %>% dplyr::rename(A13br1 = A13b_1r1, A13br2 = A13b_1r2, A13br3 = A13b_1r3, A13br4 = A13b_1r4, A13br5 = A13b_1r5) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(A13br1 = A13b_2r1, A13br2 = A13b_2r2, A13br3 = A13b_2r3, A13br4 = A13b_2r4, A13br5 = A13b_2r5) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_5:", nrow(stacked_loop_5), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_5
cuts_stacked_loop_5 <- list(
  Total = rep(TRUE, nrow(stacked_loop_5))
,  `Male` = with(stacked_loop_5, gender == 1)
,  `Female` = with(stacked_loop_5, gender == 2)
)

cut_stat_letters_stacked_loop_5 <- cut_stat_letters

# --- stacked_loop_6: 17 variables x 2 iterations ---
# Skeleton: pagetimeA-N-_-N
# Iterations: 1, 2

stacked_loop_6 <- dplyr::bind_rows(
  data %>% dplyr::rename(pagetimeA10 = pagetimeA10_1, pagetimeA11 = pagetimeA11_1, pagetimeA13 = pagetimeA13_1, pagetimeA15 = pagetimeA15_1, pagetimeA16 = pagetimeA16_1, pagetimeA17 = pagetimeA17_1, pagetimeA18 = pagetimeA18_1, pagetimeA19 = pagetimeA19_1, pagetimeA1 = pagetimeA1_1, pagetimeA2 = pagetimeA2_1, pagetimeA3 = pagetimeA3_1, pagetimeA4 = pagetimeA4_1, pagetimeA5 = pagetimeA5_1, pagetimeA6 = pagetimeA6_1, pagetimeA7 = pagetimeA7_1, pagetimeA8 = pagetimeA8_1, pagetimeA9 = pagetimeA9_1) %>% dplyr::mutate(.loop_iter = 1),
  data %>% dplyr::rename(pagetimeA10 = pagetimeA10_2, pagetimeA11 = pagetimeA11_2, pagetimeA13 = pagetimeA13_2, pagetimeA15 = pagetimeA15_2, pagetimeA16 = pagetimeA16_2, pagetimeA17 = pagetimeA17_2, pagetimeA18 = pagetimeA18_2, pagetimeA19 = pagetimeA19_2, pagetimeA1 = pagetimeA1_2, pagetimeA2 = pagetimeA2_2, pagetimeA3 = pagetimeA3_2, pagetimeA4 = pagetimeA4_2, pagetimeA5 = pagetimeA5_2, pagetimeA6 = pagetimeA6_2, pagetimeA7 = pagetimeA7_2, pagetimeA8 = pagetimeA8_2, pagetimeA9 = pagetimeA9_2) %>% dplyr::mutate(.loop_iter = 2)
)
print(paste("Created stacked_loop_6:", nrow(stacked_loop_6), "rows (", nrow(data), "x", 2, "iterations)"))

# Cuts for stacked_loop_6
cuts_stacked_loop_6 <- list(
  Total = rep(TRUE, nrow(stacked_loop_6))
,  `Male` = with(stacked_loop_6, gender == 1)
,  `Female` = with(stacked_loop_6, gender == 2)
)

cut_stat_letters_stacked_loop_6 <- cut_stat_letters
