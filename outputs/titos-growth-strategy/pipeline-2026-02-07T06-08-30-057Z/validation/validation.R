# HawkTab AI - R Validation Script
# Generated: 2026-02-07T06:24:48.247Z
# Tables to validate: 61

# Load required libraries
library(haven)
library(dplyr)
library(jsonlite)

# Load SPSS data file
data <- read_sav("dataFile.sav")
print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))

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
,  `Total` = with(stacked_loop_1, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_1, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_1, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_1, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_1, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_1, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_1, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_1, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_1, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_1, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_1, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_1, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_1, S9r4 == 1)
,  `Dining` = with(stacked_loop_1, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_1, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_1, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_1, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_1, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_1, S9r16 == 1)
,  `Other` = with(stacked_loop_1, S9r99 == 1)
)


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
,  `Total` = with(stacked_loop_2, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_2, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_2, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_2, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_2, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_2, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_2, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_2, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_2, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_2, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_2, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_2, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_2, S9r4 == 1)
,  `Dining` = with(stacked_loop_2, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_2, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_2, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_2, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_2, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_2, S9r16 == 1)
,  `Other` = with(stacked_loop_2, S9r99 == 1)
)


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
,  `Total` = with(stacked_loop_3, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_3, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_3, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_3, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_3, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_3, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_3, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_3, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_3, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_3, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_3, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_3, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_3, S9r4 == 1)
,  `Dining` = with(stacked_loop_3, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_3, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_3, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_3, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_3, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_3, S9r16 == 1)
,  `Other` = with(stacked_loop_3, S9r99 == 1)
)


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
,  `Total` = with(stacked_loop_4, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_4, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_4, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_4, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_4, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_4, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_4, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_4, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_4, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_4, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_4, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_4, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_4, S9r4 == 1)
,  `Dining` = with(stacked_loop_4, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_4, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_4, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_4, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_4, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_4, S9r16 == 1)
,  `Other` = with(stacked_loop_4, S9r99 == 1)
)


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
,  `Total` = with(stacked_loop_5, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_5, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_5, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_5, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_5, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_5, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_5, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_5, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_5, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_5, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_5, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_5, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_5, S9r4 == 1)
,  `Dining` = with(stacked_loop_5, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_5, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_5, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_5, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_5, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_5, S9r16 == 1)
,  `Other` = with(stacked_loop_5, S9r99 == 1)
)


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
,  `Total` = with(stacked_loop_6, rep(TRUE, nrow(data)))
,  `Connection / Belonging` = with(stacked_loop_6, (S10a == 1 | S11a == 1))
,  `Status / Image` = with(stacked_loop_6, (S10a == 2 | S11a == 2))
,  `Exploration / Discovery` = with(stacked_loop_6, (S10a == 3 | S11a == 3))
,  `Celebration` = with(stacked_loop_6, (S10a == 4 | S11a == 4))
,  `Indulgence` = with(stacked_loop_6, (S10a == 5 | S11a == 5))
,  `Escape / Relief` = with(stacked_loop_6, (S10a == 6 | S11a == 6))
,  `Performance` = with(stacked_loop_6, (S10a == 7 | S11a == 7))
,  `Tradition` = with(stacked_loop_6, (S10a == 8 | S11a == 8))
,  `Own Home` = with(stacked_loop_6, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_6, S9r2 == 1)
,  `Work / Office` = with(stacked_loop_6, S9r3 == 1)
,  `College Dorm` = with(stacked_loop_6, S9r4 == 1)
,  `Dining` = with(stacked_loop_6, (S9r5 == 1 | S9r6 == 1 | S9r7 == 1))
,  `Bar / Nightclub` = with(stacked_loop_6, (S9r8 == 1 | S9r9 == 1 | S9r10 == 1 | S9r11 == 1))
,  `Hotel / Motel` = with(stacked_loop_6, S9r12 == 1)
,  `Recreation / Entertainment / Concession` = with(stacked_loop_6, (S9r13 == 1 | S9r14 == 1))
,  `Outdoor Gathering` = with(stacked_loop_6, S9r15 == 1)
,  `Airport / Transit Location` = with(stacked_loop_6, S9r16 == 1)
,  `Other` = with(stacked_loop_6, S9r99 == 1)
)


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

# Initialize validation results
validation_results <- list()

# =============================================================================
# Table Validation (each wrapped in tryCatch)
# =============================================================================

# -----------------------------------------------------------------------------
# Table: s1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s1"]] <- tryCatch({

  # Row 1: NET - Any sensitive industry (NET)
  if (!("S1r1" %in% names(data))) stop("NET component variable 'S1r1' not found")
  if (!("S1r2" %in% names(data))) stop("NET component variable 'S1r2' not found")
  if (!("S1r3" %in% names(data))) stop("NET component variable 'S1r3' not found")
  if (!("S1r4" %in% names(data))) stop("NET component variable 'S1r4' not found")
  if (!("S1r5" %in% names(data))) stop("NET component variable 'S1r5' not found")
  if (!("S1r6" %in% names(data))) stop("NET component variable 'S1r6' not found")
  if (!("S1r7" %in% names(data))) stop("NET component variable 'S1r7' not found")
  # Row 2: S1r1 == 1
  if (!("S1r1" %in% names(data))) stop("Variable 'S1r1' not found")
  test_val <- sum(as.numeric(data[["S1r1"]]) == 1, na.rm = TRUE)
  # Row 3: S1r2 == 1
  if (!("S1r2" %in% names(data))) stop("Variable 'S1r2' not found")
  test_val <- sum(as.numeric(data[["S1r2"]]) == 1, na.rm = TRUE)
  # Row 4: S1r3 == 1
  if (!("S1r3" %in% names(data))) stop("Variable 'S1r3' not found")
  test_val <- sum(as.numeric(data[["S1r3"]]) == 1, na.rm = TRUE)
  # Row 5: S1r4 == 1
  if (!("S1r4" %in% names(data))) stop("Variable 'S1r4' not found")
  test_val <- sum(as.numeric(data[["S1r4"]]) == 1, na.rm = TRUE)
  # Row 6: S1r5 == 1
  if (!("S1r5" %in% names(data))) stop("Variable 'S1r5' not found")
  test_val <- sum(as.numeric(data[["S1r5"]]) == 1, na.rm = TRUE)
  # Row 7: S1r6 == 1
  if (!("S1r6" %in% names(data))) stop("Variable 'S1r6' not found")
  test_val <- sum(as.numeric(data[["S1r6"]]) == 1, na.rm = TRUE)
  # Row 8: S1r7 == 1
  if (!("S1r7" %in% names(data))) stop("Variable 'S1r7' not found")
  test_val <- sum(as.numeric(data[["S1r7"]]) == 1, na.rm = TRUE)
  # Row 9: S1r8 == 1
  if (!("S1r8" %in% names(data))) stop("Variable 'S1r8' not found")
  test_val <- sum(as.numeric(data[["S1r8"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "s1", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "s1", error = conditionMessage(e))
})

print(paste("Validated:", "s1", "-", if(validation_results[["s1"]]$success) "PASS" else paste("FAIL:", validation_results[["s1"]]$error)))

# -----------------------------------------------------------------------------
# Table: s2 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s2"]] <- tryCatch({

  # Row 1: S2 (mean)
  if (!("S2" %in% names(data))) stop("Variable 'S2' not found")
  test_vals <- data[["S2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S2' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s2", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "s2", error = conditionMessage(e))
})

print(paste("Validated:", "s2", "-", if(validation_results[["s2"]]$success) "PASS" else paste("FAIL:", validation_results[["s2"]]$error)))

# -----------------------------------------------------------------------------
# Table: s3 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s3"]] <- tryCatch({

  # Row 1: S3 == 1
  if (!("S3" %in% names(data))) stop("Variable 'S3' not found")
  test_val <- sum(as.numeric(data[["S3"]]) == 1, na.rm = TRUE)
  # Row 2: S3 == 2
  if (!("S3" %in% names(data))) stop("Variable 'S3' not found")
  test_val <- sum(as.numeric(data[["S3"]]) == 2, na.rm = TRUE)
  # Row 3: S3 == 3
  if (!("S3" %in% names(data))) stop("Variable 'S3' not found")
  test_val <- sum(as.numeric(data[["S3"]]) == 3, na.rm = TRUE)
  # Row 4: S3 == 4
  if (!("S3" %in% names(data))) stop("Variable 'S3' not found")
  test_val <- sum(as.numeric(data[["S3"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "s3", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "s3", error = conditionMessage(e))
})

print(paste("Validated:", "s3", "-", if(validation_results[["s3"]]$success) "PASS" else paste("FAIL:", validation_results[["s3"]]$error)))

# -----------------------------------------------------------------------------
# Table: s5 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s5"]] <- tryCatch({

  # Row 1: S5 == 1
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 1, na.rm = TRUE)
  # Row 2: S5 == 2
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 2, na.rm = TRUE)
  # Row 3: S5 == 3
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 3, na.rm = TRUE)
  # Row 4: S5 == 4
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 4, na.rm = TRUE)
  # Row 5: S5 == 5
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 5, na.rm = TRUE)
  # Row 6: S5 == 6
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 6, na.rm = TRUE)
  # Row 7: S5 == 7
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 7, na.rm = TRUE)
  # Row 8: S5 == 8
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 8, na.rm = TRUE)
  # Row 9: S5 == 9
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 9, na.rm = TRUE)
  # Row 10: S5 == 10
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) == 10, na.rm = TRUE)
  # Row 11: S5 == 1,2,3,4
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) %in% c(1, 2, 3, 4), na.rm = TRUE)
  # Row 12: S5 == 5,6,7,8,9
  if (!("S5" %in% names(data))) stop("Variable 'S5' not found")
  test_val <- sum(as.numeric(data[["S5"]]) %in% c(5, 6, 7, 8, 9), na.rm = TRUE)

  list(success = TRUE, tableId = "s5", rowCount = 12)

}, error = function(e) {
  list(success = FALSE, tableId = "s5", error = conditionMessage(e))
})

print(paste("Validated:", "s5", "-", if(validation_results[["s5"]]$success) "PASS" else paste("FAIL:", validation_results[["s5"]]$error)))

# -----------------------------------------------------------------------------
# Table: s6 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s6"]] <- tryCatch({

  # Row 1: S6 == 1
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 1, na.rm = TRUE)
  # Row 2: S6 == 2
  if (!("S6" %in% names(data))) stop("Variable 'S6' not found")
  test_val <- sum(as.numeric(data[["S6"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "s6", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "s6", error = conditionMessage(e))
})

print(paste("Validated:", "s6", "-", if(validation_results[["s6"]]$success) "PASS" else paste("FAIL:", validation_results[["s6"]]$error)))

# -----------------------------------------------------------------------------
# Table: s6a (frequency)
# -----------------------------------------------------------------------------

validation_results[["s6a"]] <- tryCatch({

  # Row 1: NET - Any Hispanic / Latino origin (NET)
  if (!("S6ar1" %in% names(data))) stop("NET component variable 'S6ar1' not found")
  if (!("S6ar2" %in% names(data))) stop("NET component variable 'S6ar2' not found")
  if (!("S6ar3" %in% names(data))) stop("NET component variable 'S6ar3' not found")
  if (!("S6ar4" %in% names(data))) stop("NET component variable 'S6ar4' not found")
  if (!("S6ar5" %in% names(data))) stop("NET component variable 'S6ar5' not found")
  if (!("S6ar6" %in% names(data))) stop("NET component variable 'S6ar6' not found")
  if (!("S6ar7" %in% names(data))) stop("NET component variable 'S6ar7' not found")
  if (!("S6ar8" %in% names(data))) stop("NET component variable 'S6ar8' not found")
  # Row 2: S6ar1 == 1
  if (!("S6ar1" %in% names(data))) stop("Variable 'S6ar1' not found")
  test_val <- sum(as.numeric(data[["S6ar1"]]) == 1, na.rm = TRUE)
  # Row 3: S6ar2 == 1
  if (!("S6ar2" %in% names(data))) stop("Variable 'S6ar2' not found")
  test_val <- sum(as.numeric(data[["S6ar2"]]) == 1, na.rm = TRUE)
  # Row 4: S6ar3 == 1
  if (!("S6ar3" %in% names(data))) stop("Variable 'S6ar3' not found")
  test_val <- sum(as.numeric(data[["S6ar3"]]) == 1, na.rm = TRUE)
  # Row 5: S6ar4 == 1
  if (!("S6ar4" %in% names(data))) stop("Variable 'S6ar4' not found")
  test_val <- sum(as.numeric(data[["S6ar4"]]) == 1, na.rm = TRUE)
  # Row 6: S6ar5 == 1
  if (!("S6ar5" %in% names(data))) stop("Variable 'S6ar5' not found")
  test_val <- sum(as.numeric(data[["S6ar5"]]) == 1, na.rm = TRUE)
  # Row 7: S6ar6 == 1
  if (!("S6ar6" %in% names(data))) stop("Variable 'S6ar6' not found")
  test_val <- sum(as.numeric(data[["S6ar6"]]) == 1, na.rm = TRUE)
  # Row 8: S6ar7 == 1
  if (!("S6ar7" %in% names(data))) stop("Variable 'S6ar7' not found")
  test_val <- sum(as.numeric(data[["S6ar7"]]) == 1, na.rm = TRUE)
  # Row 9: S6ar8 == 1
  if (!("S6ar8" %in% names(data))) stop("Variable 'S6ar8' not found")
  test_val <- sum(as.numeric(data[["S6ar8"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "s6a", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "s6a", error = conditionMessage(e))
})

print(paste("Validated:", "s6a", "-", if(validation_results[["s6a"]]$success) "PASS" else paste("FAIL:", validation_results[["s6a"]]$error)))

# -----------------------------------------------------------------------------
# Table: s7 (frequency)
# -----------------------------------------------------------------------------

validation_results[["s7"]] <- tryCatch({

  # Row 1: S7r1 == 1
  if (!("S7r1" %in% names(data))) stop("Variable 'S7r1' not found")
  test_val <- sum(as.numeric(data[["S7r1"]]) == 1, na.rm = TRUE)
  # Row 2: S7r2 == 1
  if (!("S7r2" %in% names(data))) stop("Variable 'S7r2' not found")
  test_val <- sum(as.numeric(data[["S7r2"]]) == 1, na.rm = TRUE)
  # Row 3: S7r3 == 1
  if (!("S7r3" %in% names(data))) stop("Variable 'S7r3' not found")
  test_val <- sum(as.numeric(data[["S7r3"]]) == 1, na.rm = TRUE)
  # Row 4: S7r4 == 1
  if (!("S7r4" %in% names(data))) stop("Variable 'S7r4' not found")
  test_val <- sum(as.numeric(data[["S7r4"]]) == 1, na.rm = TRUE)
  # Row 5: S7r5 == 1
  if (!("S7r5" %in% names(data))) stop("Variable 'S7r5' not found")
  test_val <- sum(as.numeric(data[["S7r5"]]) == 1, na.rm = TRUE)
  # Row 6: S7r6 == 1
  if (!("S7r6" %in% names(data))) stop("Variable 'S7r6' not found")
  test_val <- sum(as.numeric(data[["S7r6"]]) == 1, na.rm = TRUE)
  # Row 7: NET - Two or more races (NET)
  if (!("S7r1" %in% names(data))) stop("NET component variable 'S7r1' not found")
  if (!("S7r2" %in% names(data))) stop("NET component variable 'S7r2' not found")
  if (!("S7r3" %in% names(data))) stop("NET component variable 'S7r3' not found")
  if (!("S7r4" %in% names(data))) stop("NET component variable 'S7r4' not found")
  if (!("S7r5" %in% names(data))) stop("NET component variable 'S7r5' not found")
  if (!("S7r6" %in% names(data))) stop("NET component variable 'S7r6' not found")

  list(success = TRUE, tableId = "s7", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "s7", error = conditionMessage(e))
})

print(paste("Validated:", "s7", "-", if(validation_results[["s7"]]$success) "PASS" else paste("FAIL:", validation_results[["s7"]]$error)))

# -----------------------------------------------------------------------------
# Table: s8 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s8"]] <- tryCatch({

  # Row 1: S8 (mean)
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_vals <- data[["S8"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S8' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s8", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "s8", error = conditionMessage(e))
})

print(paste("Validated:", "s8", "-", if(validation_results[["s8"]]$success) "PASS" else paste("FAIL:", validation_results[["s8"]]$error)))

# -----------------------------------------------------------------------------
# Table: s8_binned (frequency)
# -----------------------------------------------------------------------------

validation_results[["s8_binned"]] <- tryCatch({

  # Row 1: S8 == 0
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) == 0, na.rm = TRUE)
  # Row 2: S8 == 1-2
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) >= 1 & as.numeric(data[["S8"]]) <= 2, na.rm = TRUE)
  # Row 3: S8 == 3-5
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) >= 3 & as.numeric(data[["S8"]]) <= 5, na.rm = TRUE)
  # Row 4: S8 == 6-10
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) >= 6 & as.numeric(data[["S8"]]) <= 10, na.rm = TRUE)
  # Row 5: S8 == 11-20
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) >= 11 & as.numeric(data[["S8"]]) <= 20, na.rm = TRUE)
  # Row 6: S8 == 21-50
  if (!("S8" %in% names(data))) stop("Variable 'S8' not found")
  test_val <- sum(as.numeric(data[["S8"]]) >= 21 & as.numeric(data[["S8"]]) <= 50, na.rm = TRUE)

  list(success = TRUE, tableId = "s8_binned", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "s8_binned", error = conditionMessage(e))
})

print(paste("Validated:", "s8_binned", "-", if(validation_results[["s8_binned"]]$success) "PASS" else paste("FAIL:", validation_results[["s8_binned"]]$error)))

# -----------------------------------------------------------------------------
# Table: s9 (mean_rows)
# -----------------------------------------------------------------------------

validation_results[["s9"]] <- tryCatch({

  # Row 1: S9r1 (mean)
  if (!("S9r1" %in% names(data))) stop("Variable 'S9r1' not found")
  test_vals <- data[["S9r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 2: S9r2 (mean)
  if (!("S9r2" %in% names(data))) stop("Variable 'S9r2' not found")
  test_vals <- data[["S9r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 3: S9r3 (mean)
  if (!("S9r3" %in% names(data))) stop("Variable 'S9r3' not found")
  test_vals <- data[["S9r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 4: S9r4 (mean)
  if (!("S9r4" %in% names(data))) stop("Variable 'S9r4' not found")
  test_vals <- data[["S9r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r4' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 5: S9r5 (mean)
  if (!("S9r5" %in% names(data))) stop("Variable 'S9r5' not found")
  test_vals <- data[["S9r5"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r5' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 6: S9r6 (mean)
  if (!("S9r6" %in% names(data))) stop("Variable 'S9r6' not found")
  test_vals <- data[["S9r6"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r6' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 7: S9r7 (mean)
  if (!("S9r7" %in% names(data))) stop("Variable 'S9r7' not found")
  test_vals <- data[["S9r7"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r7' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 8: S9r8 (mean)
  if (!("S9r8" %in% names(data))) stop("Variable 'S9r8' not found")
  test_vals <- data[["S9r8"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r8' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 9: S9r9 (mean)
  if (!("S9r9" %in% names(data))) stop("Variable 'S9r9' not found")
  test_vals <- data[["S9r9"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r9' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 10: S9r10 (mean)
  if (!("S9r10" %in% names(data))) stop("Variable 'S9r10' not found")
  test_vals <- data[["S9r10"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r10' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 11: S9r11 (mean)
  if (!("S9r11" %in% names(data))) stop("Variable 'S9r11' not found")
  test_vals <- data[["S9r11"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r11' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 12: S9r12 (mean)
  if (!("S9r12" %in% names(data))) stop("Variable 'S9r12' not found")
  test_vals <- data[["S9r12"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r12' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 13: S9r13 (mean)
  if (!("S9r13" %in% names(data))) stop("Variable 'S9r13' not found")
  test_vals <- data[["S9r13"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r13' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 14: S9r14 (mean)
  if (!("S9r14" %in% names(data))) stop("Variable 'S9r14' not found")
  test_vals <- data[["S9r14"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r14' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 15: S9r15 (mean)
  if (!("S9r15" %in% names(data))) stop("Variable 'S9r15' not found")
  test_vals <- data[["S9r15"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r15' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 16: S9r16 (mean)
  if (!("S9r16" %in% names(data))) stop("Variable 'S9r16' not found")
  test_vals <- data[["S9r16"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r16' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 17: S9r99 (mean)
  if (!("S9r99" %in% names(data))) stop("Variable 'S9r99' not found")
  test_vals <- data[["S9r99"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'S9r99' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 18: NET - On-premise (Total) (sum of component means)
  if (!("S9r5" %in% names(data))) stop("NET component variable 'S9r5' not found")
  test_vals <- data[["S9r5"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r5' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r6" %in% names(data))) stop("NET component variable 'S9r6' not found")
  test_vals <- data[["S9r6"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r6' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r7" %in% names(data))) stop("NET component variable 'S9r7' not found")
  test_vals <- data[["S9r7"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r7' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r8" %in% names(data))) stop("NET component variable 'S9r8' not found")
  test_vals <- data[["S9r8"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r8' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r9" %in% names(data))) stop("NET component variable 'S9r9' not found")
  test_vals <- data[["S9r9"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r9' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r10" %in% names(data))) stop("NET component variable 'S9r10' not found")
  test_vals <- data[["S9r10"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r10' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r11" %in% names(data))) stop("NET component variable 'S9r11' not found")
  test_vals <- data[["S9r11"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r11' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r12" %in% names(data))) stop("NET component variable 'S9r12' not found")
  test_vals <- data[["S9r12"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r12' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r13" %in% names(data))) stop("NET component variable 'S9r13' not found")
  test_vals <- data[["S9r13"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r13' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r14" %in% names(data))) stop("NET component variable 'S9r14' not found")
  test_vals <- data[["S9r14"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r14' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r16" %in% names(data))) stop("NET component variable 'S9r16' not found")
  test_vals <- data[["S9r16"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r16' is not numeric (type: ", class(test_vals)[1], ")")
  }
  # Row 19: NET - Off-premise (Total) (sum of component means)
  if (!("S9r1" %in% names(data))) stop("NET component variable 'S9r1' not found")
  test_vals <- data[["S9r1"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r1' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r2" %in% names(data))) stop("NET component variable 'S9r2' not found")
  test_vals <- data[["S9r2"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r2' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r3" %in% names(data))) stop("NET component variable 'S9r3' not found")
  test_vals <- data[["S9r3"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r3' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r4" %in% names(data))) stop("NET component variable 'S9r4' not found")
  test_vals <- data[["S9r4"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r4' is not numeric (type: ", class(test_vals)[1], ")")
  }
  if (!("S9r15" %in% names(data))) stop("NET component variable 'S9r15' not found")
  test_vals <- data[["S9r15"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("NET component 'S9r15' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "s9", rowCount = 19)

}, error = function(e) {
  list(success = FALSE, tableId = "s9", error = conditionMessage(e))
})

print(paste("Validated:", "s9", "-", if(validation_results[["s9"]]$success) "PASS" else paste("FAIL:", validation_results[["s9"]]$error)))

# -----------------------------------------------------------------------------
# Table: s10a (frequency)
# -----------------------------------------------------------------------------

validation_results[["s10a"]] <- tryCatch({

  # Row 1: S10a == 1
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 1, na.rm = TRUE)
  # Row 2: S10a == 2
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 2, na.rm = TRUE)
  # Row 3: S10a == 3
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 3, na.rm = TRUE)
  # Row 4: S10a == 4
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 4, na.rm = TRUE)
  # Row 5: S10a == 5
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 5, na.rm = TRUE)
  # Row 6: S10a == 6
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 6, na.rm = TRUE)
  # Row 7: S10a == 7
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 7, na.rm = TRUE)
  # Row 8: S10a == 8
  if (!("S10a" %in% names(data))) stop("Variable 'S10a' not found")
  test_val <- sum(as.numeric(data[["S10a"]]) == 8, na.rm = TRUE)

  list(success = TRUE, tableId = "s10a", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "s10a", error = conditionMessage(e))
})

print(paste("Validated:", "s10a", "-", if(validation_results[["s10a"]]$success) "PASS" else paste("FAIL:", validation_results[["s10a"]]$error)))

# -----------------------------------------------------------------------------
# Table: s10b (frequency)
# -----------------------------------------------------------------------------

validation_results[["s10b"]] <- tryCatch({

  # Row 1: S10b == 1
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 1, na.rm = TRUE)
  # Row 2: S10b == 2
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 2, na.rm = TRUE)
  # Row 3: S10b == 3
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 3, na.rm = TRUE)
  # Row 4: S10b == 4
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 4, na.rm = TRUE)
  # Row 5: S10b == 6
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 6, na.rm = TRUE)
  # Row 6: S10b == 7
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 7, na.rm = TRUE)
  # Row 7: S10b == 8
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 8, na.rm = TRUE)
  # Row 8: S10b == 9
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 9, na.rm = TRUE)
  # Row 9: S10b == 11
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 11, na.rm = TRUE)
  # Row 10: S10b == 12
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 12, na.rm = TRUE)
  # Row 11: S10b == 13
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 13, na.rm = TRUE)
  # Row 12: S10b == 14
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 14, na.rm = TRUE)
  # Row 13: S10b == 16
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 16, na.rm = TRUE)
  # Row 14: S10b == 17
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 17, na.rm = TRUE)
  # Row 15: S10b == 19
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 19, na.rm = TRUE)
  # Row 16: S10b == 21
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 21, na.rm = TRUE)
  # Row 17: S10b == 24
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 24, na.rm = TRUE)
  # Row 18: S10b == 26
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 26, na.rm = TRUE)
  # Row 19: S10b == 27
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 27, na.rm = TRUE)
  # Row 20: S10b == 28
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 28, na.rm = TRUE)
  # Row 21: S10b == 29
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 29, na.rm = TRUE)
  # Row 22: S10b == 31
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 31, na.rm = TRUE)
  # Row 23: S10b == 32
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 32, na.rm = TRUE)
  # Row 24: S10b == 34
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 34, na.rm = TRUE)
  # Row 25: S10b == 36
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 36, na.rm = TRUE)
  # Row 26: S10b == 37
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 37, na.rm = TRUE)
  # Row 27: S10b == 38
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 38, na.rm = TRUE)
  # Row 28: S10b == 39
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 39, na.rm = TRUE)
  # Row 29: S10b == 40
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 40, na.rm = TRUE)
  # Row 30: S10b == 100
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 100, na.rm = TRUE)
  # Row 31: S10b == 101
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 101, na.rm = TRUE)
  # Row 32: S10b == 102
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 102, na.rm = TRUE)
  # Row 33: S10b == 103
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 103, na.rm = TRUE)
  # Row 34: S10b == 104
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 104, na.rm = TRUE)
  # Row 35: S10b == 105
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 105, na.rm = TRUE)
  # Row 36: S10b == 106
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 106, na.rm = TRUE)
  # Row 37: S10b == 107
  if (!("S10b" %in% names(data))) stop("Variable 'S10b' not found")
  test_val <- sum(as.numeric(data[["S10b"]]) == 107, na.rm = TRUE)

  list(success = TRUE, tableId = "s10b", rowCount = 37)

}, error = function(e) {
  list(success = FALSE, tableId = "s10b", error = conditionMessage(e))
})

print(paste("Validated:", "s10b", "-", if(validation_results[["s10b"]]$success) "PASS" else paste("FAIL:", validation_results[["s10b"]]$error)))

# -----------------------------------------------------------------------------
# Table: s10c (frequency)
# -----------------------------------------------------------------------------

validation_results[["s10c"]] <- tryCatch({

  # Row 1: S10c == 1
  if (!("S10c" %in% names(data))) stop("Variable 'S10c' not found")
  test_val <- sum(as.numeric(data[["S10c"]]) == 1, na.rm = TRUE)
  # Row 2: S10c == 2
  if (!("S10c" %in% names(data))) stop("Variable 'S10c' not found")
  test_val <- sum(as.numeric(data[["S10c"]]) == 2, na.rm = TRUE)
  # Row 3: S10c == 3
  if (!("S10c" %in% names(data))) stop("Variable 'S10c' not found")
  test_val <- sum(as.numeric(data[["S10c"]]) == 3, na.rm = TRUE)
  # Row 4: S10c == 4
  if (!("S10c" %in% names(data))) stop("Variable 'S10c' not found")
  test_val <- sum(as.numeric(data[["S10c"]]) == 4, na.rm = TRUE)
  # Row 5: S10c == 5
  if (!("S10c" %in% names(data))) stop("Variable 'S10c' not found")
  test_val <- sum(as.numeric(data[["S10c"]]) == 5, na.rm = TRUE)

  list(success = TRUE, tableId = "s10c", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "s10c", error = conditionMessage(e))
})

print(paste("Validated:", "s10c", "-", if(validation_results[["s10c"]]$success) "PASS" else paste("FAIL:", validation_results[["s10c"]]$error)))

# -----------------------------------------------------------------------------
# Table: s11a (frequency)
# -----------------------------------------------------------------------------

validation_results[["s11a"]] <- tryCatch({

  # Row 1: S11a == 1
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 1, na.rm = TRUE)
  # Row 2: S11a == 2
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 2, na.rm = TRUE)
  # Row 3: S11a == 3
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 3, na.rm = TRUE)
  # Row 4: S11a == 4
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 4, na.rm = TRUE)
  # Row 5: S11a == 5
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 5, na.rm = TRUE)
  # Row 6: S11a == 6
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 6, na.rm = TRUE)
  # Row 7: S11a == 7
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 7, na.rm = TRUE)
  # Row 8: S11a == 8
  if (!("S11a" %in% names(data))) stop("Variable 'S11a' not found")
  test_val <- sum(as.numeric(data[["S11a"]]) == 8, na.rm = TRUE)

  list(success = TRUE, tableId = "s11a", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "s11a", error = conditionMessage(e))
})

print(paste("Validated:", "s11a", "-", if(validation_results[["s11a"]]$success) "PASS" else paste("FAIL:", validation_results[["s11a"]]$error)))

# -----------------------------------------------------------------------------
# Table: s11b (frequency)
# -----------------------------------------------------------------------------

validation_results[["s11b"]] <- tryCatch({

  # Row 1: S11b == 1
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 1, na.rm = TRUE)
  # Row 2: S11b == 2
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 2, na.rm = TRUE)
  # Row 3: S11b == 3
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 3, na.rm = TRUE)
  # Row 4: S11b == 4
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 4, na.rm = TRUE)
  # Row 5: S11b == 6
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 6, na.rm = TRUE)
  # Row 6: S11b == 7
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 7, na.rm = TRUE)
  # Row 7: S11b == 8
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 8, na.rm = TRUE)
  # Row 8: S11b == 9
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 9, na.rm = TRUE)
  # Row 9: S11b == 11
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 11, na.rm = TRUE)
  # Row 10: S11b == 12
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 12, na.rm = TRUE)
  # Row 11: S11b == 13
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 13, na.rm = TRUE)
  # Row 12: S11b == 14
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 14, na.rm = TRUE)
  # Row 13: S11b == 16
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 16, na.rm = TRUE)
  # Row 14: S11b == 17
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 17, na.rm = TRUE)
  # Row 15: S11b == 19
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 19, na.rm = TRUE)
  # Row 16: S11b == 21
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 21, na.rm = TRUE)
  # Row 17: S11b == 24
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 24, na.rm = TRUE)
  # Row 18: S11b == 26
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 26, na.rm = TRUE)
  # Row 19: S11b == 27
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 27, na.rm = TRUE)
  # Row 20: S11b == 28
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 28, na.rm = TRUE)
  # Row 21: S11b == 29
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 29, na.rm = TRUE)
  # Row 22: S11b == 31
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 31, na.rm = TRUE)
  # Row 23: S11b == 32
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 32, na.rm = TRUE)
  # Row 24: S11b == 34
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 34, na.rm = TRUE)
  # Row 25: S11b == 36
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 36, na.rm = TRUE)
  # Row 26: S11b == 37
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 37, na.rm = TRUE)
  # Row 27: S11b == 38
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 38, na.rm = TRUE)
  # Row 28: S11b == 39
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 39, na.rm = TRUE)
  # Row 29: S11b == 40
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 40, na.rm = TRUE)
  # Row 30: S11b == 100
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 100, na.rm = TRUE)
  # Row 31: S11b == 101
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 101, na.rm = TRUE)
  # Row 32: S11b == 102
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 102, na.rm = TRUE)
  # Row 33: S11b == 103
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 103, na.rm = TRUE)
  # Row 34: S11b == 104
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 104, na.rm = TRUE)
  # Row 35: S11b == 105
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 105, na.rm = TRUE)
  # Row 36: S11b == 106
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 106, na.rm = TRUE)
  # Row 37: S11b == 107
  if (!("S11b" %in% names(data))) stop("Variable 'S11b' not found")
  test_val <- sum(as.numeric(data[["S11b"]]) == 107, na.rm = TRUE)

  list(success = TRUE, tableId = "s11b", rowCount = 37)

}, error = function(e) {
  list(success = FALSE, tableId = "s11b", error = conditionMessage(e))
})

print(paste("Validated:", "s11b", "-", if(validation_results[["s11b"]]$success) "PASS" else paste("FAIL:", validation_results[["s11b"]]$error)))

# -----------------------------------------------------------------------------
# Table: s11c (frequency)
# -----------------------------------------------------------------------------

validation_results[["s11c"]] <- tryCatch({

  # Row 1: S11c == 1
  if (!("S11c" %in% names(data))) stop("Variable 'S11c' not found")
  test_val <- sum(as.numeric(data[["S11c"]]) == 1, na.rm = TRUE)
  # Row 2: S11c == 2
  if (!("S11c" %in% names(data))) stop("Variable 'S11c' not found")
  test_val <- sum(as.numeric(data[["S11c"]]) == 2, na.rm = TRUE)
  # Row 3: S11c == 3
  if (!("S11c" %in% names(data))) stop("Variable 'S11c' not found")
  test_val <- sum(as.numeric(data[["S11c"]]) == 3, na.rm = TRUE)
  # Row 4: S11c == 4
  if (!("S11c" %in% names(data))) stop("Variable 'S11c' not found")
  test_val <- sum(as.numeric(data[["S11c"]]) == 4, na.rm = TRUE)
  # Row 5: S11c == 5
  if (!("S11c" %in% names(data))) stop("Variable 'S11c' not found")
  test_val <- sum(as.numeric(data[["S11c"]]) == 5, na.rm = TRUE)
  # Row 6: NET - Spirits / Liquor (NET)
  if (!("S11c" %in% names(data))) stop("NET component variable 'S11c' not found")

  list(success = TRUE, tableId = "s11c", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "s11c", error = conditionMessage(e))
})

print(paste("Validated:", "s11c", "-", if(validation_results[["s11c"]]$success) "PASS" else paste("FAIL:", validation_results[["s11c"]]$error)))

# -----------------------------------------------------------------------------
# Table: a2 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a2"]] <- tryCatch({

  # Row 1: A2 == 1
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 1, na.rm = TRUE)
  # Row 2: A2 == 2
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 2, na.rm = TRUE)
  # Row 3: A2 == 3
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 3, na.rm = TRUE)
  # Row 4: A2 == 4
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 4, na.rm = TRUE)
  # Row 5: A2 == 5
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 5, na.rm = TRUE)
  # Row 6: A2 == 6
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 6, na.rm = TRUE)
  # Row 7: A2 == 7
  if (!("A2" %in% names(stacked_loop_1))) stop("Variable 'A2' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A2"]]) == 7, na.rm = TRUE)

  list(success = TRUE, tableId = "a2", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a2", error = conditionMessage(e))
})

print(paste("Validated:", "a2", "-", if(validation_results[["a2"]]$success) "PASS" else paste("FAIL:", validation_results[["a2"]]$error)))

# -----------------------------------------------------------------------------
# Table: a3 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a3"]] <- tryCatch({

  # Row 1: A3 == 1,2,3,4
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) %in% c(1, 2, 3, 4), na.rm = TRUE)
  # Row 2: A3 == 1
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 1, na.rm = TRUE)
  # Row 3: A3 == 2
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 2, na.rm = TRUE)
  # Row 4: A3 == 3
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 3, na.rm = TRUE)
  # Row 5: A3 == 4
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 4, na.rm = TRUE)
  # Row 6: A3 == 5,6,7
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) %in% c(5, 6, 7), na.rm = TRUE)
  # Row 7: A3 == 5
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 5, na.rm = TRUE)
  # Row 8: A3 == 6
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 6, na.rm = TRUE)
  # Row 9: A3 == 7
  if (!("A3" %in% names(stacked_loop_1))) stop("Variable 'A3' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A3"]]) == 7, na.rm = TRUE)

  list(success = TRUE, tableId = "a3", rowCount = 9)

}, error = function(e) {
  list(success = FALSE, tableId = "a3", error = conditionMessage(e))
})

print(paste("Validated:", "a3", "-", if(validation_results[["a3"]]$success) "PASS" else paste("FAIL:", validation_results[["a3"]]$error)))

# -----------------------------------------------------------------------------
# Table: a4 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a4"]] <- tryCatch({

  # Row 1: A4 == 1
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 1, na.rm = TRUE)
  # Row 2: A4 == 2
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 2, na.rm = TRUE)
  # Row 3: A4 == 3
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 3, na.rm = TRUE)
  # Row 4: A4 == 4
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 4, na.rm = TRUE)
  # Row 5: A4 == 5
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 5, na.rm = TRUE)
  # Row 6: A4 == 6
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 6, na.rm = TRUE)
  # Row 7: A4 == 7
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 7, na.rm = TRUE)
  # Row 8: A4 == 8
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 8, na.rm = TRUE)
  # Row 9: A4 == 9
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 9, na.rm = TRUE)
  # Row 10: A4 == 10
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 10, na.rm = TRUE)
  # Row 11: A4 == 11
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 11, na.rm = TRUE)
  # Row 12: A4 == 12
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 12, na.rm = TRUE)
  # Row 13: A4 == 13
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 13, na.rm = TRUE)
  # Row 14: A4 == 14
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 14, na.rm = TRUE)
  # Row 15: A4 == 15
  if (!("A4" %in% names(stacked_loop_1))) stop("Variable 'A4' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A4"]]) == 15, na.rm = TRUE)

  list(success = TRUE, tableId = "a4", rowCount = 15)

}, error = function(e) {
  list(success = FALSE, tableId = "a4", error = conditionMessage(e))
})

print(paste("Validated:", "a4", "-", if(validation_results[["a4"]]$success) "PASS" else paste("FAIL:", validation_results[["a4"]]$error)))

# -----------------------------------------------------------------------------
# Table: a5 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a5"]] <- tryCatch({

  # Row 1: A5 == 1
  if (!("A5" %in% names(stacked_loop_1))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A5"]]) == 1, na.rm = TRUE)
  # Row 2: A5 == 2
  if (!("A5" %in% names(stacked_loop_1))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A5"]]) == 2, na.rm = TRUE)
  # Row 3: A5 == 3
  if (!("A5" %in% names(stacked_loop_1))) stop("Variable 'A5' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A5"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "a5", rowCount = 3)

}, error = function(e) {
  list(success = FALSE, tableId = "a5", error = conditionMessage(e))
})

print(paste("Validated:", "a5", "-", if(validation_results[["a5"]]$success) "PASS" else paste("FAIL:", validation_results[["a5"]]$error)))

# -----------------------------------------------------------------------------
# Table: a6 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a6"]] <- tryCatch({

  # Row 1: A6 == 1
  if (!("A6" %in% names(stacked_loop_1))) stop("Variable 'A6' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A6"]]) == 1, na.rm = TRUE)
  # Row 2: A6 == 2
  if (!("A6" %in% names(stacked_loop_1))) stop("Variable 'A6' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A6"]]) == 2, na.rm = TRUE)
  # Row 3: A6 == 3
  if (!("A6" %in% names(stacked_loop_1))) stop("Variable 'A6' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A6"]]) == 3, na.rm = TRUE)
  # Row 4: A6 == 4
  if (!("A6" %in% names(stacked_loop_1))) stop("Variable 'A6' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A6"]]) == 4, na.rm = TRUE)
  # Row 5: A6 == 5
  if (!("A6" %in% names(stacked_loop_1))) stop("Variable 'A6' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A6"]]) == 5, na.rm = TRUE)

  list(success = TRUE, tableId = "a6", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a6", error = conditionMessage(e))
})

print(paste("Validated:", "a6", "-", if(validation_results[["a6"]]$success) "PASS" else paste("FAIL:", validation_results[["a6"]]$error)))

# -----------------------------------------------------------------------------
# Table: a8 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a8"]] <- tryCatch({

  # Row 1: A8 == 1,2
  if (!("A8" %in% names(stacked_loop_1))) stop("Variable 'A8' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A8"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A8 == 1
  if (!("A8" %in% names(stacked_loop_1))) stop("Variable 'A8' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A8"]]) == 1, na.rm = TRUE)
  # Row 3: A8 == 2
  if (!("A8" %in% names(stacked_loop_1))) stop("Variable 'A8' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A8"]]) == 2, na.rm = TRUE)
  # Row 4: A8 == 3
  if (!("A8" %in% names(stacked_loop_1))) stop("Variable 'A8' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A8"]]) == 3, na.rm = TRUE)

  list(success = TRUE, tableId = "a8", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "a8", error = conditionMessage(e))
})

print(paste("Validated:", "a8", "-", if(validation_results[["a8"]]$success) "PASS" else paste("FAIL:", validation_results[["a8"]]$error)))

# -----------------------------------------------------------------------------
# Table: a10 (mean_rows) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a10"]] <- tryCatch({

  # Row 1: A10 (mean)
  if (!("A10" %in% names(stacked_loop_1))) stop("Variable 'A10' not found")
  test_vals <- stacked_loop_1[["A10"]]
  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {
    stop("Variable 'A10' is not numeric (type: ", class(test_vals)[1], ")")
  }

  list(success = TRUE, tableId = "a10", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "a10", error = conditionMessage(e))
})

print(paste("Validated:", "a10", "-", if(validation_results[["a10"]]$success) "PASS" else paste("FAIL:", validation_results[["a10"]]$error)))

# -----------------------------------------------------------------------------
# Table: a10_bins (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a10_bins"]] <- tryCatch({

  # Row 1: A10 == 2
  if (!("A10" %in% names(stacked_loop_1))) stop("Variable 'A10' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A10"]]) == 2, na.rm = TRUE)
  # Row 2: A10 == 3-4
  if (!("A10" %in% names(stacked_loop_1))) stop("Variable 'A10' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A10"]]) >= 3 & as.numeric(stacked_loop_1[["A10"]]) <= 4, na.rm = TRUE)
  # Row 3: A10 == 5-7
  if (!("A10" %in% names(stacked_loop_1))) stop("Variable 'A10' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A10"]]) >= 5 & as.numeric(stacked_loop_1[["A10"]]) <= 7, na.rm = TRUE)
  # Row 4: A10 == 8-30
  if (!("A10" %in% names(stacked_loop_1))) stop("Variable 'A10' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A10"]]) >= 8 & as.numeric(stacked_loop_1[["A10"]]) <= 30, na.rm = TRUE)

  list(success = TRUE, tableId = "a10_bins", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "a10_bins", error = conditionMessage(e))
})

print(paste("Validated:", "a10_bins", "-", if(validation_results[["a10_bins"]]$success) "PASS" else paste("FAIL:", validation_results[["a10_bins"]]$error)))

# -----------------------------------------------------------------------------
# Table: a11 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a11"]] <- tryCatch({

  # Row 1: A11 == 4,5
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A11 == 5
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) == 5, na.rm = TRUE)
  # Row 3: A11 == 4
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) == 4, na.rm = TRUE)
  # Row 4: A11 == 3
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) == 3, na.rm = TRUE)
  # Row 5: A11 == 1,2
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A11 == 2
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) == 2, na.rm = TRUE)
  # Row 7: A11 == 1
  if (!("A11" %in% names(stacked_loop_1))) stop("Variable 'A11' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A11"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a11", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a11", error = conditionMessage(e))
})

print(paste("Validated:", "a11", "-", if(validation_results[["a11"]]$success) "PASS" else paste("FAIL:", validation_results[["a11"]]$error)))

# -----------------------------------------------------------------------------
# Table: a13 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a13"]] <- tryCatch({

  # Row 1: Category header - Brand list (skip validation)
  # Row 2: A13 == 1
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 1, na.rm = TRUE)
  # Row 3: A13 == 2
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 2, na.rm = TRUE)
  # Row 4: A13 == 3
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 3, na.rm = TRUE)
  # Row 5: A13 == 4
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 4, na.rm = TRUE)
  # Row 6: A13 == 5
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 5, na.rm = TRUE)
  # Row 7: A13 == 6
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 6, na.rm = TRUE)
  # Row 8: A13 == 7
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 7, na.rm = TRUE)
  # Row 9: A13 == 8
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 8, na.rm = TRUE)
  # Row 10: A13 == 9
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 9, na.rm = TRUE)
  # Row 11: A13 == 10
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 10, na.rm = TRUE)
  # Row 12: A13 == 11
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 11, na.rm = TRUE)
  # Row 13: A13 == 12
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 12, na.rm = TRUE)
  # Row 14: A13 == 13
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 13, na.rm = TRUE)
  # Row 15: A13 == 14
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 14, na.rm = TRUE)
  # Row 16: A13 == 15
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 15, na.rm = TRUE)
  # Row 17: A13 == 16
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 16, na.rm = TRUE)
  # Row 18: A13 == 17
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 17, na.rm = TRUE)
  # Row 19: A13 == 18
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 18, na.rm = TRUE)
  # Row 20: A13 == 19
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 19, na.rm = TRUE)
  # Row 21: A13 == 20
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 20, na.rm = TRUE)
  # Row 22: A13 == 21
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 21, na.rm = TRUE)
  # Row 23: A13 == 22
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 22, na.rm = TRUE)
  # Row 24: A13 == 23
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 23, na.rm = TRUE)
  # Row 25: A13 == 24
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 24, na.rm = TRUE)
  # Row 26: A13 == 25
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 25, na.rm = TRUE)
  # Row 27: A13 == 26
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 26, na.rm = TRUE)
  # Row 28: A13 == 27
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 27, na.rm = TRUE)
  # Row 29: A13 == 28
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 28, na.rm = TRUE)
  # Row 30: A13 == 29
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 29, na.rm = TRUE)
  # Row 31: A13 == 30
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 30, na.rm = TRUE)
  # Row 32: A13 == 31
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 31, na.rm = TRUE)
  # Row 33: A13 == 32
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 32, na.rm = TRUE)
  # Row 34: A13 == 33
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 33, na.rm = TRUE)
  # Row 35: A13 == 34
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 34, na.rm = TRUE)
  # Row 36: A13 == 35
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 35, na.rm = TRUE)
  # Row 37: A13 == 36
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 36, na.rm = TRUE)
  # Row 38: A13 == 37
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 37, na.rm = TRUE)
  # Row 39: A13 == 38
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 38, na.rm = TRUE)
  # Row 40: A13 == 39
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 39, na.rm = TRUE)
  # Row 41: A13 == 40
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 40, na.rm = TRUE)
  # Row 42: A13 == 41
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 41, na.rm = TRUE)
  # Row 43: A13 == 42
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 42, na.rm = TRUE)
  # Row 44: A13 == 43
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 43, na.rm = TRUE)
  # Row 45: A13 == 44
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 44, na.rm = TRUE)
  # Row 46: A13 == 45
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 45, na.rm = TRUE)
  # Row 47: A13 == 46
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 46, na.rm = TRUE)
  # Row 48: A13 == 47
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 47, na.rm = TRUE)
  # Row 49: A13 == 48
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 48, na.rm = TRUE)
  # Row 50: A13 == 49
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 49, na.rm = TRUE)
  # Row 51: A13 == 50
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 50, na.rm = TRUE)
  # Row 52: A13 == 51
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 51, na.rm = TRUE)
  # Row 53: A13 == 52
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 52, na.rm = TRUE)
  # Row 54: A13 == 53
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 53, na.rm = TRUE)
  # Row 55: A13 == 54
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 54, na.rm = TRUE)
  # Row 56: A13 == 55
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 55, na.rm = TRUE)
  # Row 57: A13 == 56
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 56, na.rm = TRUE)
  # Row 58: A13 == 57
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 57, na.rm = TRUE)
  # Row 59: A13 == 58
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 58, na.rm = TRUE)
  # Row 60: A13 == 59
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 59, na.rm = TRUE)
  # Row 61: A13 == 60
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 60, na.rm = TRUE)
  # Row 62: A13 == 61
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 61, na.rm = TRUE)
  # Row 63: A13 == 62
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 62, na.rm = TRUE)
  # Row 64: A13 == 63
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 63, na.rm = TRUE)
  # Row 65: A13 == 64
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 64, na.rm = TRUE)
  # Row 66: A13 == 65
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 65, na.rm = TRUE)
  # Row 67: A13 == 66
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 66, na.rm = TRUE)
  # Row 68: A13 == 67
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 67, na.rm = TRUE)
  # Row 69: A13 == 68
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 68, na.rm = TRUE)
  # Row 70: A13 == 69
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 69, na.rm = TRUE)
  # Row 71: A13 == 70
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 70, na.rm = TRUE)
  # Row 72: A13 == 98
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 98, na.rm = TRUE)
  # Row 73: A13 == 99
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 99, na.rm = TRUE)
  # Row 74: A13 == 100
  if (!("A13" %in% names(stacked_loop_1))) stop("Variable 'A13' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A13"]]) == 100, na.rm = TRUE)

  list(success = TRUE, tableId = "a13", rowCount = 74)

}, error = function(e) {
  list(success = FALSE, tableId = "a13", error = conditionMessage(e))
})

print(paste("Validated:", "a13", "-", if(validation_results[["a13"]]$success) "PASS" else paste("FAIL:", validation_results[["a13"]]$error)))

# -----------------------------------------------------------------------------
# Table: a15 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a15"]] <- tryCatch({

  # Row 1: A15 == 1
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 1, na.rm = TRUE)
  # Row 2: A15 == 2
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 2, na.rm = TRUE)
  # Row 3: A15 == 3
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 3, na.rm = TRUE)
  # Row 4: A15 == 4
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 4, na.rm = TRUE)
  # Row 5: A15 == 5
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 5, na.rm = TRUE)
  # Row 6: A15 == 6
  if (!("A15" %in% names(stacked_loop_1))) stop("Variable 'A15' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A15"]]) == 6, na.rm = TRUE)

  list(success = TRUE, tableId = "a15", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "a15", error = conditionMessage(e))
})

print(paste("Validated:", "a15", "-", if(validation_results[["a15"]]$success) "PASS" else paste("FAIL:", validation_results[["a15"]]$error)))

# -----------------------------------------------------------------------------
# Table: a18 (frequency) [loop: stacked_loop_1]
# -----------------------------------------------------------------------------

validation_results[["a18"]] <- tryCatch({

  # Row 1: A18 == 1
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 1, na.rm = TRUE)
  # Row 2: A18 == 2
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 2, na.rm = TRUE)
  # Row 3: A18 == 3
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 3, na.rm = TRUE)
  # Row 4: A18 == 4
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 4, na.rm = TRUE)
  # Row 5: A18 == 5
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 5, na.rm = TRUE)
  # Row 6: A18 == 6
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 6, na.rm = TRUE)
  # Row 7: A18 == 7
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 7, na.rm = TRUE)
  # Row 8: A18 == 8
  if (!("A18" %in% names(stacked_loop_1))) stop("Variable 'A18' not found")
  test_val <- sum(as.numeric(stacked_loop_1[["A18"]]) == 8, na.rm = TRUE)

  list(success = TRUE, tableId = "a18", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a18", error = conditionMessage(e))
})

print(paste("Validated:", "a18", "-", if(validation_results[["a18"]]$success) "PASS" else paste("FAIL:", validation_results[["a18"]]$error)))

# -----------------------------------------------------------------------------
# Table: a20 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a20"]] <- tryCatch({

  # Row 1: A20 == 1
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 1, na.rm = TRUE)
  # Row 2: A20 == 2
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 2, na.rm = TRUE)
  # Row 3: A20 == 3
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 3, na.rm = TRUE)
  # Row 4: A20 == 4
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 4, na.rm = TRUE)
  # Row 5: A20 == 5
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 5, na.rm = TRUE)

  list(success = TRUE, tableId = "a20", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a20", error = conditionMessage(e))
})

print(paste("Validated:", "a20", "-", if(validation_results[["a20"]]$success) "PASS" else paste("FAIL:", validation_results[["a20"]]$error)))

# -----------------------------------------------------------------------------
# Table: a20__nets (frequency)
# -----------------------------------------------------------------------------

validation_results[["a20__nets"]] <- tryCatch({

  # Row 1: A20 == 1,2
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 2: A20 == 1
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 1, na.rm = TRUE)
  # Row 3: A20 == 2
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 2, na.rm = TRUE)
  # Row 4: A20 == 3
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 3, na.rm = TRUE)
  # Row 5: A20 == 4,5
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 6: A20 == 4
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 4, na.rm = TRUE)
  # Row 7: A20 == 5
  if (!("A20" %in% names(data))) stop("Variable 'A20' not found")
  test_val <- sum(as.numeric(data[["A20"]]) == 5, na.rm = TRUE)

  list(success = TRUE, tableId = "a20__nets", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a20__nets", error = conditionMessage(e))
})

print(paste("Validated:", "a20__nets", "-", if(validation_results[["a20__nets"]]$success) "PASS" else paste("FAIL:", validation_results[["a20__nets"]]$error)))

# -----------------------------------------------------------------------------
# Table: a21 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a21"]] <- tryCatch({

  # Row 1: NET - Any brand (NET)
  if (!("A21r1" %in% names(data))) stop("NET component variable 'A21r1' not found")
  if (!("A21r2" %in% names(data))) stop("NET component variable 'A21r2' not found")
  if (!("A21r3" %in% names(data))) stop("NET component variable 'A21r3' not found")
  if (!("A21r4" %in% names(data))) stop("NET component variable 'A21r4' not found")
  if (!("A21r5" %in% names(data))) stop("NET component variable 'A21r5' not found")
  if (!("A21r6" %in% names(data))) stop("NET component variable 'A21r6' not found")
  # Row 2: A21r1 == 1
  if (!("A21r1" %in% names(data))) stop("Variable 'A21r1' not found")
  test_val <- sum(as.numeric(data[["A21r1"]]) == 1, na.rm = TRUE)
  # Row 3: A21r2 == 1
  if (!("A21r2" %in% names(data))) stop("Variable 'A21r2' not found")
  test_val <- sum(as.numeric(data[["A21r2"]]) == 1, na.rm = TRUE)
  # Row 4: A21r3 == 1
  if (!("A21r3" %in% names(data))) stop("Variable 'A21r3' not found")
  test_val <- sum(as.numeric(data[["A21r3"]]) == 1, na.rm = TRUE)
  # Row 5: A21r4 == 1
  if (!("A21r4" %in% names(data))) stop("Variable 'A21r4' not found")
  test_val <- sum(as.numeric(data[["A21r4"]]) == 1, na.rm = TRUE)
  # Row 6: A21r5 == 1
  if (!("A21r5" %in% names(data))) stop("Variable 'A21r5' not found")
  test_val <- sum(as.numeric(data[["A21r5"]]) == 1, na.rm = TRUE)
  # Row 7: A21r6 == 1
  if (!("A21r6" %in% names(data))) stop("Variable 'A21r6' not found")
  test_val <- sum(as.numeric(data[["A21r6"]]) == 1, na.rm = TRUE)
  # Row 8: A21r7 == 1
  if (!("A21r7" %in% names(data))) stop("Variable 'A21r7' not found")
  test_val <- sum(as.numeric(data[["A21r7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a21", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a21", error = conditionMessage(e))
})

print(paste("Validated:", "a21", "-", if(validation_results[["a21"]]$success) "PASS" else paste("FAIL:", validation_results[["a21"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_approachable (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_approachable"]] <- tryCatch({

  # Row 1: A22r2c1 == 1
  if (!("A22r2c1" %in% names(data))) stop("Variable 'A22r2c1' not found")
  test_val <- sum(as.numeric(data[["A22r2c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r2c2 == 1
  if (!("A22r2c2" %in% names(data))) stop("Variable 'A22r2c2' not found")
  test_val <- sum(as.numeric(data[["A22r2c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r2c3 == 1
  if (!("A22r2c3" %in% names(data))) stop("Variable 'A22r2c3' not found")
  test_val <- sum(as.numeric(data[["A22r2c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r2c4 == 1
  if (!("A22r2c4" %in% names(data))) stop("Variable 'A22r2c4' not found")
  test_val <- sum(as.numeric(data[["A22r2c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r2c5 == 1
  if (!("A22r2c5" %in% names(data))) stop("Variable 'A22r2c5' not found")
  test_val <- sum(as.numeric(data[["A22r2c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r2c6 == 1
  if (!("A22r2c6" %in% names(data))) stop("Variable 'A22r2c6' not found")
  test_val <- sum(as.numeric(data[["A22r2c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r2c7 == 1
  if (!("A22r2c7" %in% names(data))) stop("Variable 'A22r2c7' not found")
  test_val <- sum(as.numeric(data[["A22r2c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_approachable", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_approachable", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_approachable", "-", if(validation_results[["a22_attribute_approachable"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_approachable"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_authentic (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_authentic"]] <- tryCatch({

  # Row 1: A22r3c1 == 1
  if (!("A22r3c1" %in% names(data))) stop("Variable 'A22r3c1' not found")
  test_val <- sum(as.numeric(data[["A22r3c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r3c2 == 1
  if (!("A22r3c2" %in% names(data))) stop("Variable 'A22r3c2' not found")
  test_val <- sum(as.numeric(data[["A22r3c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r3c3 == 1
  if (!("A22r3c3" %in% names(data))) stop("Variable 'A22r3c3' not found")
  test_val <- sum(as.numeric(data[["A22r3c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r3c4 == 1
  if (!("A22r3c4" %in% names(data))) stop("Variable 'A22r3c4' not found")
  test_val <- sum(as.numeric(data[["A22r3c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r3c5 == 1
  if (!("A22r3c5" %in% names(data))) stop("Variable 'A22r3c5' not found")
  test_val <- sum(as.numeric(data[["A22r3c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r3c6 == 1
  if (!("A22r3c6" %in% names(data))) stop("Variable 'A22r3c6' not found")
  test_val <- sum(as.numeric(data[["A22r3c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r3c7 == 1
  if (!("A22r3c7" %in% names(data))) stop("Variable 'A22r3c7' not found")
  test_val <- sum(as.numeric(data[["A22r3c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_authentic", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_authentic", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_authentic", "-", if(validation_results[["a22_attribute_authentic"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_authentic"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_bold (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_bold"]] <- tryCatch({

  # Row 1: A22r7c1 == 1
  if (!("A22r7c1" %in% names(data))) stop("Variable 'A22r7c1' not found")
  test_val <- sum(as.numeric(data[["A22r7c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r7c2 == 1
  if (!("A22r7c2" %in% names(data))) stop("Variable 'A22r7c2' not found")
  test_val <- sum(as.numeric(data[["A22r7c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r7c3 == 1
  if (!("A22r7c3" %in% names(data))) stop("Variable 'A22r7c3' not found")
  test_val <- sum(as.numeric(data[["A22r7c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r7c4 == 1
  if (!("A22r7c4" %in% names(data))) stop("Variable 'A22r7c4' not found")
  test_val <- sum(as.numeric(data[["A22r7c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r7c5 == 1
  if (!("A22r7c5" %in% names(data))) stop("Variable 'A22r7c5' not found")
  test_val <- sum(as.numeric(data[["A22r7c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r7c6 == 1
  if (!("A22r7c6" %in% names(data))) stop("Variable 'A22r7c6' not found")
  test_val <- sum(as.numeric(data[["A22r7c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r7c7 == 1
  if (!("A22r7c7" %in% names(data))) stop("Variable 'A22r7c7' not found")
  test_val <- sum(as.numeric(data[["A22r7c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_bold", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_bold", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_bold", "-", if(validation_results[["a22_attribute_bold"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_bold"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_downtoearth (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_downtoearth"]] <- tryCatch({

  # Row 1: A22r9c1 == 1
  if (!("A22r9c1" %in% names(data))) stop("Variable 'A22r9c1' not found")
  test_val <- sum(as.numeric(data[["A22r9c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r9c2 == 1
  if (!("A22r9c2" %in% names(data))) stop("Variable 'A22r9c2' not found")
  test_val <- sum(as.numeric(data[["A22r9c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r9c3 == 1
  if (!("A22r9c3" %in% names(data))) stop("Variable 'A22r9c3' not found")
  test_val <- sum(as.numeric(data[["A22r9c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r9c4 == 1
  if (!("A22r9c4" %in% names(data))) stop("Variable 'A22r9c4' not found")
  test_val <- sum(as.numeric(data[["A22r9c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r9c5 == 1
  if (!("A22r9c5" %in% names(data))) stop("Variable 'A22r9c5' not found")
  test_val <- sum(as.numeric(data[["A22r9c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r9c6 == 1
  if (!("A22r9c6" %in% names(data))) stop("Variable 'A22r9c6' not found")
  test_val <- sum(as.numeric(data[["A22r9c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r9c7 == 1
  if (!("A22r9c7" %in% names(data))) stop("Variable 'A22r9c7' not found")
  test_val <- sum(as.numeric(data[["A22r9c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_downtoearth", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_downtoearth", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_downtoearth", "-", if(validation_results[["a22_attribute_downtoearth"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_downtoearth"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_edgy (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_edgy"]] <- tryCatch({

  # Row 1: A22r5c1 == 1
  if (!("A22r5c1" %in% names(data))) stop("Variable 'A22r5c1' not found")
  test_val <- sum(as.numeric(data[["A22r5c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r5c2 == 1
  if (!("A22r5c2" %in% names(data))) stop("Variable 'A22r5c2' not found")
  test_val <- sum(as.numeric(data[["A22r5c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r5c3 == 1
  if (!("A22r5c3" %in% names(data))) stop("Variable 'A22r5c3' not found")
  test_val <- sum(as.numeric(data[["A22r5c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r5c4 == 1
  if (!("A22r5c4" %in% names(data))) stop("Variable 'A22r5c4' not found")
  test_val <- sum(as.numeric(data[["A22r5c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r5c5 == 1
  if (!("A22r5c5" %in% names(data))) stop("Variable 'A22r5c5' not found")
  test_val <- sum(as.numeric(data[["A22r5c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r5c6 == 1
  if (!("A22r5c6" %in% names(data))) stop("Variable 'A22r5c6' not found")
  test_val <- sum(as.numeric(data[["A22r5c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r5c7 == 1
  if (!("A22r5c7" %in% names(data))) stop("Variable 'A22r5c7' not found")
  test_val <- sum(as.numeric(data[["A22r5c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_edgy", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_edgy", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_edgy", "-", if(validation_results[["a22_attribute_edgy"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_edgy"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_generous (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_generous"]] <- tryCatch({

  # Row 1: A22r4c1 == 1
  if (!("A22r4c1" %in% names(data))) stop("Variable 'A22r4c1' not found")
  test_val <- sum(as.numeric(data[["A22r4c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r4c2 == 1
  if (!("A22r4c2" %in% names(data))) stop("Variable 'A22r4c2' not found")
  test_val <- sum(as.numeric(data[["A22r4c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r4c3 == 1
  if (!("A22r4c3" %in% names(data))) stop("Variable 'A22r4c3' not found")
  test_val <- sum(as.numeric(data[["A22r4c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r4c4 == 1
  if (!("A22r4c4" %in% names(data))) stop("Variable 'A22r4c4' not found")
  test_val <- sum(as.numeric(data[["A22r4c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r4c5 == 1
  if (!("A22r4c5" %in% names(data))) stop("Variable 'A22r4c5' not found")
  test_val <- sum(as.numeric(data[["A22r4c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r4c6 == 1
  if (!("A22r4c6" %in% names(data))) stop("Variable 'A22r4c6' not found")
  test_val <- sum(as.numeric(data[["A22r4c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r4c7 == 1
  if (!("A22r4c7" %in% names(data))) stop("Variable 'A22r4c7' not found")
  test_val <- sum(as.numeric(data[["A22r4c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_generous", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_generous", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_generous", "-", if(validation_results[["a22_attribute_generous"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_generous"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_independent (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_independent"]] <- tryCatch({

  # Row 1: A22r6c1 == 1
  if (!("A22r6c1" %in% names(data))) stop("Variable 'A22r6c1' not found")
  test_val <- sum(as.numeric(data[["A22r6c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r6c2 == 1
  if (!("A22r6c2" %in% names(data))) stop("Variable 'A22r6c2' not found")
  test_val <- sum(as.numeric(data[["A22r6c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r6c3 == 1
  if (!("A22r6c3" %in% names(data))) stop("Variable 'A22r6c3' not found")
  test_val <- sum(as.numeric(data[["A22r6c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r6c4 == 1
  if (!("A22r6c4" %in% names(data))) stop("Variable 'A22r6c4' not found")
  test_val <- sum(as.numeric(data[["A22r6c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r6c5 == 1
  if (!("A22r6c5" %in% names(data))) stop("Variable 'A22r6c5' not found")
  test_val <- sum(as.numeric(data[["A22r6c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r6c6 == 1
  if (!("A22r6c6" %in% names(data))) stop("Variable 'A22r6c6' not found")
  test_val <- sum(as.numeric(data[["A22r6c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r6c7 == 1
  if (!("A22r6c7" %in% names(data))) stop("Variable 'A22r6c7' not found")
  test_val <- sum(as.numeric(data[["A22r6c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_independent", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_independent", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_independent", "-", if(validation_results[["a22_attribute_independent"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_independent"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_premium (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_premium"]] <- tryCatch({

  # Row 1: A22r1c1 == 1
  if (!("A22r1c1" %in% names(data))) stop("Variable 'A22r1c1' not found")
  test_val <- sum(as.numeric(data[["A22r1c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r1c2 == 1
  if (!("A22r1c2" %in% names(data))) stop("Variable 'A22r1c2' not found")
  test_val <- sum(as.numeric(data[["A22r1c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r1c3 == 1
  if (!("A22r1c3" %in% names(data))) stop("Variable 'A22r1c3' not found")
  test_val <- sum(as.numeric(data[["A22r1c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r1c4 == 1
  if (!("A22r1c4" %in% names(data))) stop("Variable 'A22r1c4' not found")
  test_val <- sum(as.numeric(data[["A22r1c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r1c5 == 1
  if (!("A22r1c5" %in% names(data))) stop("Variable 'A22r1c5' not found")
  test_val <- sum(as.numeric(data[["A22r1c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r1c6 == 1
  if (!("A22r1c6" %in% names(data))) stop("Variable 'A22r1c6' not found")
  test_val <- sum(as.numeric(data[["A22r1c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r1c7 == 1
  if (!("A22r1c7" %in% names(data))) stop("Variable 'A22r1c7' not found")
  test_val <- sum(as.numeric(data[["A22r1c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_premium", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_premium", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_premium", "-", if(validation_results[["a22_attribute_premium"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_premium"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_reliable (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_reliable"]] <- tryCatch({

  # Row 1: A22r8c1 == 1
  if (!("A22r8c1" %in% names(data))) stop("Variable 'A22r8c1' not found")
  test_val <- sum(as.numeric(data[["A22r8c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r8c2 == 1
  if (!("A22r8c2" %in% names(data))) stop("Variable 'A22r8c2' not found")
  test_val <- sum(as.numeric(data[["A22r8c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r8c3 == 1
  if (!("A22r8c3" %in% names(data))) stop("Variable 'A22r8c3' not found")
  test_val <- sum(as.numeric(data[["A22r8c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r8c4 == 1
  if (!("A22r8c4" %in% names(data))) stop("Variable 'A22r8c4' not found")
  test_val <- sum(as.numeric(data[["A22r8c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r8c5 == 1
  if (!("A22r8c5" %in% names(data))) stop("Variable 'A22r8c5' not found")
  test_val <- sum(as.numeric(data[["A22r8c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r8c6 == 1
  if (!("A22r8c6" %in% names(data))) stop("Variable 'A22r8c6' not found")
  test_val <- sum(as.numeric(data[["A22r8c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r8c7 == 1
  if (!("A22r8c7" %in% names(data))) stop("Variable 'A22r8c7' not found")
  test_val <- sum(as.numeric(data[["A22r8c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_reliable", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_reliable", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_reliable", "-", if(validation_results[["a22_attribute_reliable"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_reliable"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_attribute_sophisticated (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_attribute_sophisticated"]] <- tryCatch({

  # Row 1: A22r10c1 == 1
  if (!("A22r10c1" %in% names(data))) stop("Variable 'A22r10c1' not found")
  test_val <- sum(as.numeric(data[["A22r10c1"]]) == 1, na.rm = TRUE)
  # Row 2: A22r10c2 == 1
  if (!("A22r10c2" %in% names(data))) stop("Variable 'A22r10c2' not found")
  test_val <- sum(as.numeric(data[["A22r10c2"]]) == 1, na.rm = TRUE)
  # Row 3: A22r10c3 == 1
  if (!("A22r10c3" %in% names(data))) stop("Variable 'A22r10c3' not found")
  test_val <- sum(as.numeric(data[["A22r10c3"]]) == 1, na.rm = TRUE)
  # Row 4: A22r10c4 == 1
  if (!("A22r10c4" %in% names(data))) stop("Variable 'A22r10c4' not found")
  test_val <- sum(as.numeric(data[["A22r10c4"]]) == 1, na.rm = TRUE)
  # Row 5: A22r10c5 == 1
  if (!("A22r10c5" %in% names(data))) stop("Variable 'A22r10c5' not found")
  test_val <- sum(as.numeric(data[["A22r10c5"]]) == 1, na.rm = TRUE)
  # Row 6: A22r10c6 == 1
  if (!("A22r10c6" %in% names(data))) stop("Variable 'A22r10c6' not found")
  test_val <- sum(as.numeric(data[["A22r10c6"]]) == 1, na.rm = TRUE)
  # Row 7: A22r10c7 == 1
  if (!("A22r10c7" %in% names(data))) stop("Variable 'A22r10c7' not found")
  test_val <- sum(as.numeric(data[["A22r10c7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_attribute_sophisticated", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_attribute_sophisticated", error = conditionMessage(e))
})

print(paste("Validated:", "a22_attribute_sophisticated", "-", if(validation_results[["a22_attribute_sophisticated"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_attribute_sophisticated"]]$error)))

# -----------------------------------------------------------------------------
# Table: a22_overview_excluded (frequency)
# -----------------------------------------------------------------------------

validation_results[["a22_overview_excluded"]] <- tryCatch({

  # Row 1: A22r1c1 == 1
  if (!("A22r1c1" %in% names(data))) stop("Variable 'A22r1c1' not found")
  test_val <- sum(as.numeric(data[["A22r1c1"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a22_overview_excluded", rowCount = 1)

}, error = function(e) {
  list(success = FALSE, tableId = "a22_overview_excluded", error = conditionMessage(e))
})

print(paste("Validated:", "a22_overview_excluded", "-", if(validation_results[["a22_overview_excluded"]]$success) "PASS" else paste("FAIL:", validation_results[["a22_overview_excluded"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_casamigos (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_casamigos"]] <- tryCatch({

  # Row 1: A23r5 == 4,5
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r5 == 5
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) == 5, na.rm = TRUE)
  # Row 3: A23r5 == 4
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) == 4, na.rm = TRUE)
  # Row 4: A23r5 == 3
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) == 3, na.rm = TRUE)
  # Row 5: A23r5 == 1,2
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r5 == 2
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) == 2, na.rm = TRUE)
  # Row 7: A23r5 == 1
  if (!("A23r5" %in% names(data))) stop("Variable 'A23r5' not found")
  test_val <- sum(as.numeric(data[["A23r5"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_casamigos", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_casamigos", error = conditionMessage(e))
})

print(paste("Validated:", "a23_casamigos", "-", if(validation_results[["a23_casamigos"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_casamigos"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_don_julio (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_don_julio"]] <- tryCatch({

  # Row 1: A23r6 == 4,5
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r6 == 5
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) == 5, na.rm = TRUE)
  # Row 3: A23r6 == 4
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) == 4, na.rm = TRUE)
  # Row 4: A23r6 == 3
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) == 3, na.rm = TRUE)
  # Row 5: A23r6 == 1,2
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r6 == 2
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) == 2, na.rm = TRUE)
  # Row 7: A23r6 == 1
  if (!("A23r6" %in% names(data))) stop("Variable 'A23r6' not found")
  test_val <- sum(as.numeric(data[["A23r6"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_don_julio", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_don_julio", error = conditionMessage(e))
})

print(paste("Validated:", "a23_don_julio", "-", if(validation_results[["a23_don_julio"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_don_julio"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_grey_goose (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_grey_goose"]] <- tryCatch({

  # Row 1: A23r2 == 4,5
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r2 == 4
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) == 4, na.rm = TRUE)
  # Row 3: A23r2 == 5
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) == 5, na.rm = TRUE)
  # Row 4: A23r2 == 3
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) == 3, na.rm = TRUE)
  # Row 5: A23r2 == 1,2
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r2 == 2
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) == 2, na.rm = TRUE)
  # Row 7: A23r2 == 1
  if (!("A23r2" %in% names(data))) stop("Variable 'A23r2' not found")
  test_val <- sum(as.numeric(data[["A23r2"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_grey_goose", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_grey_goose", error = conditionMessage(e))
})

print(paste("Validated:", "a23_grey_goose", "-", if(validation_results[["a23_grey_goose"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_grey_goose"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_ketel_one (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_ketel_one"]] <- tryCatch({

  # Row 1: A23r3 == 4,5
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r3 == 5
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) == 5, na.rm = TRUE)
  # Row 3: A23r3 == 4
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) == 4, na.rm = TRUE)
  # Row 4: A23r3 == 3
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) == 3, na.rm = TRUE)
  # Row 5: A23r3 == 1,2
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r3 == 2
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) == 2, na.rm = TRUE)
  # Row 7: A23r3 == 1
  if (!("A23r3" %in% names(data))) stop("Variable 'A23r3' not found")
  test_val <- sum(as.numeric(data[["A23r3"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_ketel_one", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_ketel_one", error = conditionMessage(e))
})

print(paste("Validated:", "a23_ketel_one", "-", if(validation_results[["a23_ketel_one"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_ketel_one"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_maker_s_mark (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_maker_s_mark"]] <- tryCatch({

  # Row 1: A23r4 == 4,5
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r4 == 5
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) == 5, na.rm = TRUE)
  # Row 3: A23r4 == 4
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) == 4, na.rm = TRUE)
  # Row 4: A23r4 == 3
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) == 3, na.rm = TRUE)
  # Row 5: A23r4 == 1,2
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r4 == 2
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) == 2, na.rm = TRUE)
  # Row 7: A23r4 == 1
  if (!("A23r4" %in% names(data))) stop("Variable 'A23r4' not found")
  test_val <- sum(as.numeric(data[["A23r4"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_maker_s_mark", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_maker_s_mark", error = conditionMessage(e))
})

print(paste("Validated:", "a23_maker_s_mark", "-", if(validation_results[["a23_maker_s_mark"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_maker_s_mark"]]$error)))

# -----------------------------------------------------------------------------
# Table: a23_tito_s_handmade_vodka (frequency)
# -----------------------------------------------------------------------------

validation_results[["a23_tito_s_handmade_vodka"]] <- tryCatch({

  # Row 1: A23r1 == 4,5
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) %in% c(4, 5), na.rm = TRUE)
  # Row 2: A23r1 == 5
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) == 5, na.rm = TRUE)
  # Row 3: A23r1 == 4
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) == 4, na.rm = TRUE)
  # Row 4: A23r1 == 3
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) == 3, na.rm = TRUE)
  # Row 5: A23r1 == 1,2
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) %in% c(1, 2), na.rm = TRUE)
  # Row 6: A23r1 == 2
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) == 2, na.rm = TRUE)
  # Row 7: A23r1 == 1
  if (!("A23r1" %in% names(data))) stop("Variable 'A23r1' not found")
  test_val <- sum(as.numeric(data[["A23r1"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a23_tito_s_handmade_vodka", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a23_tito_s_handmade_vodka", error = conditionMessage(e))
})

print(paste("Validated:", "a23_tito_s_handmade_vodka", "-", if(validation_results[["a23_tito_s_handmade_vodka"]]$success) "PASS" else paste("FAIL:", validation_results[["a23_tito_s_handmade_vodka"]]$error)))

# -----------------------------------------------------------------------------
# Table: c3 (frequency)
# -----------------------------------------------------------------------------

validation_results[["c3"]] <- tryCatch({

  # Row 1: NET - Employed (Total)
  if (!("C3r2" %in% names(data))) stop("NET component variable 'C3r2' not found")
  if (!("C3r3" %in% names(data))) stop("NET component variable 'C3r3' not found")
  if (!("C3r4" %in% names(data))) stop("NET component variable 'C3r4' not found")
  # Row 2: C3r2 == 1
  if (!("C3r2" %in% names(data))) stop("Variable 'C3r2' not found")
  test_val <- sum(as.numeric(data[["C3r2"]]) == 1, na.rm = TRUE)
  # Row 3: C3r3 == 1
  if (!("C3r3" %in% names(data))) stop("Variable 'C3r3' not found")
  test_val <- sum(as.numeric(data[["C3r3"]]) == 1, na.rm = TRUE)
  # Row 4: C3r4 == 1
  if (!("C3r4" %in% names(data))) stop("Variable 'C3r4' not found")
  test_val <- sum(as.numeric(data[["C3r4"]]) == 1, na.rm = TRUE)
  # Row 5: NET - Out of work (Total)
  if (!("C3r6" %in% names(data))) stop("NET component variable 'C3r6' not found")
  if (!("C3r7" %in% names(data))) stop("NET component variable 'C3r7' not found")
  # Row 6: C3r6 == 1
  if (!("C3r6" %in% names(data))) stop("Variable 'C3r6' not found")
  test_val <- sum(as.numeric(data[["C3r6"]]) == 1, na.rm = TRUE)
  # Row 7: C3r7 == 1
  if (!("C3r7" %in% names(data))) stop("Variable 'C3r7' not found")
  test_val <- sum(as.numeric(data[["C3r7"]]) == 1, na.rm = TRUE)
  # Row 8: C3r1 == 1
  if (!("C3r1" %in% names(data))) stop("Variable 'C3r1' not found")
  test_val <- sum(as.numeric(data[["C3r1"]]) == 1, na.rm = TRUE)
  # Row 9: C3r5 == 1
  if (!("C3r5" %in% names(data))) stop("Variable 'C3r5' not found")
  test_val <- sum(as.numeric(data[["C3r5"]]) == 1, na.rm = TRUE)
  # Row 10: C3r8 == 1
  if (!("C3r8" %in% names(data))) stop("Variable 'C3r8' not found")
  test_val <- sum(as.numeric(data[["C3r8"]]) == 1, na.rm = TRUE)
  # Row 11: C3r9 == 1
  if (!("C3r9" %in% names(data))) stop("Variable 'C3r9' not found")
  test_val <- sum(as.numeric(data[["C3r9"]]) == 1, na.rm = TRUE)
  # Row 12: C3r10 == 1
  if (!("C3r10" %in% names(data))) stop("Variable 'C3r10' not found")
  test_val <- sum(as.numeric(data[["C3r10"]]) == 1, na.rm = TRUE)
  # Row 13: C3r11 == 1
  if (!("C3r11" %in% names(data))) stop("Variable 'C3r11' not found")
  test_val <- sum(as.numeric(data[["C3r11"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "c3", rowCount = 13)

}, error = function(e) {
  list(success = FALSE, tableId = "c3", error = conditionMessage(e))
})

print(paste("Validated:", "c3", "-", if(validation_results[["c3"]]$success) "PASS" else paste("FAIL:", validation_results[["c3"]]$error)))

# -----------------------------------------------------------------------------
# Table: a13a_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a13a_1"]] <- tryCatch({

  # Row 1: A13a_1 == 1
  if (!("A13a_1" %in% names(data))) stop("Variable 'A13a_1' not found")
  test_val <- sum(as.numeric(data[["A13a_1"]]) == 1, na.rm = TRUE)
  # Row 2: A13a_1 == 2
  if (!("A13a_1" %in% names(data))) stop("Variable 'A13a_1' not found")
  test_val <- sum(as.numeric(data[["A13a_1"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "a13a_1", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a13a_1", error = conditionMessage(e))
})

print(paste("Validated:", "a13a_1", "-", if(validation_results[["a13a_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a13a_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a13a_2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a13a_2"]] <- tryCatch({

  # Row 1: A13a_2 == 1
  if (!("A13a_2" %in% names(data))) stop("Variable 'A13a_2' not found")
  test_val <- sum(as.numeric(data[["A13a_2"]]) == 1, na.rm = TRUE)
  # Row 2: A13a_2 == 2
  if (!("A13a_2" %in% names(data))) stop("Variable 'A13a_2' not found")
  test_val <- sum(as.numeric(data[["A13a_2"]]) == 2, na.rm = TRUE)

  list(success = TRUE, tableId = "a13a_2", rowCount = 2)

}, error = function(e) {
  list(success = FALSE, tableId = "a13a_2", error = conditionMessage(e))
})

print(paste("Validated:", "a13a_2", "-", if(validation_results[["a13a_2"]]$success) "PASS" else paste("FAIL:", validation_results[["a13a_2"]]$error)))

# -----------------------------------------------------------------------------
# Table: a13b_1 (frequency) [loop: stacked_loop_5]
# -----------------------------------------------------------------------------

validation_results[["a13b_1"]] <- tryCatch({

  # Row 1: NET - Any other drinks (NET)
  if (!("A13br1" %in% names(stacked_loop_5))) stop("NET component variable 'A13br1' not found")
  if (!("A13br2" %in% names(stacked_loop_5))) stop("NET component variable 'A13br2' not found")
  if (!("A13br3" %in% names(stacked_loop_5))) stop("NET component variable 'A13br3' not found")
  if (!("A13br4" %in% names(stacked_loop_5))) stop("NET component variable 'A13br4' not found")
  if (!("A13br5" %in% names(stacked_loop_5))) stop("NET component variable 'A13br5' not found")
  # Row 2: A13br1 == 1
  if (!("A13br1" %in% names(stacked_loop_5))) stop("Variable 'A13br1' not found")
  test_val <- sum(as.numeric(stacked_loop_5[["A13br1"]]) == 1, na.rm = TRUE)
  # Row 3: A13br2 == 1
  if (!("A13br2" %in% names(stacked_loop_5))) stop("Variable 'A13br2' not found")
  test_val <- sum(as.numeric(stacked_loop_5[["A13br2"]]) == 1, na.rm = TRUE)
  # Row 4: A13br3 == 1
  if (!("A13br3" %in% names(stacked_loop_5))) stop("Variable 'A13br3' not found")
  test_val <- sum(as.numeric(stacked_loop_5[["A13br3"]]) == 1, na.rm = TRUE)
  # Row 5: A13br4 == 1
  if (!("A13br4" %in% names(stacked_loop_5))) stop("Variable 'A13br4' not found")
  test_val <- sum(as.numeric(stacked_loop_5[["A13br4"]]) == 1, na.rm = TRUE)
  # Row 6: A13br5 == 1
  if (!("A13br5" %in% names(stacked_loop_5))) stop("Variable 'A13br5' not found")
  test_val <- sum(as.numeric(stacked_loop_5[["A13br5"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a13b_1", rowCount = 6)

}, error = function(e) {
  list(success = FALSE, tableId = "a13b_1", error = conditionMessage(e))
})

print(paste("Validated:", "a13b_1", "-", if(validation_results[["a13b_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a13b_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a14a_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a14a_1"]] <- tryCatch({

  # Row 1: A14a_1 == 1
  if (!("A14a_1" %in% names(data))) stop("Variable 'A14a_1' not found")
  test_val <- sum(as.numeric(data[["A14a_1"]]) == 1, na.rm = TRUE)
  # Row 2: A14a_1 == 2
  if (!("A14a_1" %in% names(data))) stop("Variable 'A14a_1' not found")
  test_val <- sum(as.numeric(data[["A14a_1"]]) == 2, na.rm = TRUE)
  # Row 3: A14a_1 == 3
  if (!("A14a_1" %in% names(data))) stop("Variable 'A14a_1' not found")
  test_val <- sum(as.numeric(data[["A14a_1"]]) == 3, na.rm = TRUE)
  # Row 4: A14a_1 == 4
  if (!("A14a_1" %in% names(data))) stop("Variable 'A14a_1' not found")
  test_val <- sum(as.numeric(data[["A14a_1"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a14a_1", rowCount = 4)

}, error = function(e) {
  list(success = FALSE, tableId = "a14a_1", error = conditionMessage(e))
})

print(paste("Validated:", "a14a_1", "-", if(validation_results[["a14a_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a14a_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a14a_2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a14a_2"]] <- tryCatch({

  # Row 1: NET - Purchaser (NET)
  if (!("A14a_2" %in% names(data))) stop("NET component variable 'A14a_2' not found")
  if (!("A14a_2" %in% names(data))) stop("NET component variable 'A14a_2' not found")
  # Row 2: A14a_2 == 1
  if (!("A14a_2" %in% names(data))) stop("Variable 'A14a_2' not found")
  test_val <- sum(as.numeric(data[["A14a_2"]]) == 1, na.rm = TRUE)
  # Row 3: A14a_2 == 2
  if (!("A14a_2" %in% names(data))) stop("Variable 'A14a_2' not found")
  test_val <- sum(as.numeric(data[["A14a_2"]]) == 2, na.rm = TRUE)
  # Row 4: A14a_2 == 3
  if (!("A14a_2" %in% names(data))) stop("Variable 'A14a_2' not found")
  test_val <- sum(as.numeric(data[["A14a_2"]]) == 3, na.rm = TRUE)
  # Row 5: A14a_2 == 4
  if (!("A14a_2" %in% names(data))) stop("Variable 'A14a_2' not found")
  test_val <- sum(as.numeric(data[["A14a_2"]]) == 4, na.rm = TRUE)

  list(success = TRUE, tableId = "a14a_2", rowCount = 5)

}, error = function(e) {
  list(success = FALSE, tableId = "a14a_2", error = conditionMessage(e))
})

print(paste("Validated:", "a14a_2", "-", if(validation_results[["a14a_2"]]$success) "PASS" else paste("FAIL:", validation_results[["a14a_2"]]$error)))

# -----------------------------------------------------------------------------
# Table: a14b_1 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a14b_1"]] <- tryCatch({

  # Row 1: A14b_1 == 1,2,3,4,12
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) %in% c(1, 2, 3, 4, 12), na.rm = TRUE)
  # Row 2: A14b_1 == 1
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 1, na.rm = TRUE)
  # Row 3: A14b_1 == 2
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 2, na.rm = TRUE)
  # Row 4: A14b_1 == 3
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 3, na.rm = TRUE)
  # Row 5: A14b_1 == 4
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 4, na.rm = TRUE)
  # Row 6: A14b_1 == 12
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 12, na.rm = TRUE)
  # Row 7: A14b_1 == 5,6
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) %in% c(5, 6), na.rm = TRUE)
  # Row 8: A14b_1 == 5
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 5, na.rm = TRUE)
  # Row 9: A14b_1 == 6
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 6, na.rm = TRUE)
  # Row 10: A14b_1 == 7,8,9
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) %in% c(7, 8, 9), na.rm = TRUE)
  # Row 11: A14b_1 == 7
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 7, na.rm = TRUE)
  # Row 12: A14b_1 == 8
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 8, na.rm = TRUE)
  # Row 13: A14b_1 == 9
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 9, na.rm = TRUE)
  # Row 14: A14b_1 == 10
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 10, na.rm = TRUE)
  # Row 15: A14b_1 == 11
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 11, na.rm = TRUE)
  # Row 16: A14b_1 == 13
  if (!("A14b_1" %in% names(data))) stop("Variable 'A14b_1' not found")
  test_val <- sum(as.numeric(data[["A14b_1"]]) == 13, na.rm = TRUE)

  list(success = TRUE, tableId = "a14b_1", rowCount = 16)

}, error = function(e) {
  list(success = FALSE, tableId = "a14b_1", error = conditionMessage(e))
})

print(paste("Validated:", "a14b_1", "-", if(validation_results[["a14b_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a14b_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a14b_2 (frequency)
# -----------------------------------------------------------------------------

validation_results[["a14b_2"]] <- tryCatch({

  # Row 1: A14b_2 == 1,2,3,4,12
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) %in% c(1, 2, 3, 4, 12), na.rm = TRUE)
  # Row 2: A14b_2 == 1
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 1, na.rm = TRUE)
  # Row 3: A14b_2 == 2
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 2, na.rm = TRUE)
  # Row 4: A14b_2 == 3
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 3, na.rm = TRUE)
  # Row 5: A14b_2 == 4
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 4, na.rm = TRUE)
  # Row 6: A14b_2 == 5
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 5, na.rm = TRUE)
  # Row 7: A14b_2 == 6
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 6, na.rm = TRUE)
  # Row 8: A14b_2 == 7
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 7, na.rm = TRUE)
  # Row 9: A14b_2 == 8
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 8, na.rm = TRUE)
  # Row 10: A14b_2 == 9
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 9, na.rm = TRUE)
  # Row 11: A14b_2 == 10
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 10, na.rm = TRUE)
  # Row 12: A14b_2 == 11
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 11, na.rm = TRUE)
  # Row 13: A14b_2 == 12
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 12, na.rm = TRUE)
  # Row 14: A14b_2 == 13
  if (!("A14b_2" %in% names(data))) stop("Variable 'A14b_2' not found")
  test_val <- sum(as.numeric(data[["A14b_2"]]) == 13, na.rm = TRUE)

  list(success = TRUE, tableId = "a14b_2", rowCount = 14)

}, error = function(e) {
  list(success = FALSE, tableId = "a14b_2", error = conditionMessage(e))
})

print(paste("Validated:", "a14b_2", "-", if(validation_results[["a14b_2"]]$success) "PASS" else paste("FAIL:", validation_results[["a14b_2"]]$error)))

# -----------------------------------------------------------------------------
# Table: a16_1 (frequency) [loop: stacked_loop_4]
# -----------------------------------------------------------------------------

validation_results[["a16_1"]] <- tryCatch({

  # Row 1: NET - Any purchase reason (NET)
  if (!("A16r1" %in% names(stacked_loop_4))) stop("NET component variable 'A16r1' not found")
  if (!("A16r2" %in% names(stacked_loop_4))) stop("NET component variable 'A16r2' not found")
  if (!("A16r3" %in% names(stacked_loop_4))) stop("NET component variable 'A16r3' not found")
  if (!("A16r4" %in% names(stacked_loop_4))) stop("NET component variable 'A16r4' not found")
  if (!("A16r5" %in% names(stacked_loop_4))) stop("NET component variable 'A16r5' not found")
  if (!("A16r6" %in% names(stacked_loop_4))) stop("NET component variable 'A16r6' not found")
  if (!("A16r7" %in% names(stacked_loop_4))) stop("NET component variable 'A16r7' not found")
  if (!("A16r8" %in% names(stacked_loop_4))) stop("NET component variable 'A16r8' not found")
  if (!("A16r9" %in% names(stacked_loop_4))) stop("NET component variable 'A16r9' not found")
  if (!("A16r10" %in% names(stacked_loop_4))) stop("NET component variable 'A16r10' not found")
  # Row 2: A16r1 == 1
  if (!("A16r1" %in% names(stacked_loop_4))) stop("Variable 'A16r1' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r1"]]) == 1, na.rm = TRUE)
  # Row 3: A16r2 == 1
  if (!("A16r2" %in% names(stacked_loop_4))) stop("Variable 'A16r2' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r2"]]) == 1, na.rm = TRUE)
  # Row 4: A16r3 == 1
  if (!("A16r3" %in% names(stacked_loop_4))) stop("Variable 'A16r3' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r3"]]) == 1, na.rm = TRUE)
  # Row 5: A16r4 == 1
  if (!("A16r4" %in% names(stacked_loop_4))) stop("Variable 'A16r4' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r4"]]) == 1, na.rm = TRUE)
  # Row 6: A16r5 == 1
  if (!("A16r5" %in% names(stacked_loop_4))) stop("Variable 'A16r5' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r5"]]) == 1, na.rm = TRUE)
  # Row 7: A16r6 == 1
  if (!("A16r6" %in% names(stacked_loop_4))) stop("Variable 'A16r6' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r6"]]) == 1, na.rm = TRUE)
  # Row 8: A16r7 == 1
  if (!("A16r7" %in% names(stacked_loop_4))) stop("Variable 'A16r7' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r7"]]) == 1, na.rm = TRUE)
  # Row 9: A16r8 == 1
  if (!("A16r8" %in% names(stacked_loop_4))) stop("Variable 'A16r8' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r8"]]) == 1, na.rm = TRUE)
  # Row 10: A16r9 == 1
  if (!("A16r9" %in% names(stacked_loop_4))) stop("Variable 'A16r9' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r9"]]) == 1, na.rm = TRUE)
  # Row 11: A16r10 == 1
  if (!("A16r10" %in% names(stacked_loop_4))) stop("Variable 'A16r10' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A16r10"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a16_1", rowCount = 11)

}, error = function(e) {
  list(success = FALSE, tableId = "a16_1", error = conditionMessage(e))
})

print(paste("Validated:", "a16_1", "-", if(validation_results[["a16_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a16_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a17_1 (frequency) [loop: stacked_loop_4]
# -----------------------------------------------------------------------------

validation_results[["a17_1"]] <- tryCatch({

  # Row 1: NET - Any reason (NET)
  if (!("A17r1" %in% names(stacked_loop_4))) stop("NET component variable 'A17r1' not found")
  if (!("A17r2" %in% names(stacked_loop_4))) stop("NET component variable 'A17r2' not found")
  if (!("A17r3" %in% names(stacked_loop_4))) stop("NET component variable 'A17r3' not found")
  if (!("A17r4" %in% names(stacked_loop_4))) stop("NET component variable 'A17r4' not found")
  if (!("A17r5" %in% names(stacked_loop_4))) stop("NET component variable 'A17r5' not found")
  if (!("A17r6" %in% names(stacked_loop_4))) stop("NET component variable 'A17r6' not found")
  if (!("A17r7" %in% names(stacked_loop_4))) stop("NET component variable 'A17r7' not found")
  if (!("A17r8" %in% names(stacked_loop_4))) stop("NET component variable 'A17r8' not found")
  if (!("A17r9" %in% names(stacked_loop_4))) stop("NET component variable 'A17r9' not found")
  # Row 2: A17r1 == 1
  if (!("A17r1" %in% names(stacked_loop_4))) stop("Variable 'A17r1' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r1"]]) == 1, na.rm = TRUE)
  # Row 3: A17r2 == 1
  if (!("A17r2" %in% names(stacked_loop_4))) stop("Variable 'A17r2' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r2"]]) == 1, na.rm = TRUE)
  # Row 4: A17r3 == 1
  if (!("A17r3" %in% names(stacked_loop_4))) stop("Variable 'A17r3' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r3"]]) == 1, na.rm = TRUE)
  # Row 5: A17r4 == 1
  if (!("A17r4" %in% names(stacked_loop_4))) stop("Variable 'A17r4' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r4"]]) == 1, na.rm = TRUE)
  # Row 6: A17r5 == 1
  if (!("A17r5" %in% names(stacked_loop_4))) stop("Variable 'A17r5' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r5"]]) == 1, na.rm = TRUE)
  # Row 7: A17r6 == 1
  if (!("A17r6" %in% names(stacked_loop_4))) stop("Variable 'A17r6' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r6"]]) == 1, na.rm = TRUE)
  # Row 8: A17r7 == 1
  if (!("A17r7" %in% names(stacked_loop_4))) stop("Variable 'A17r7' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r7"]]) == 1, na.rm = TRUE)
  # Row 9: A17r8 == 1
  if (!("A17r8" %in% names(stacked_loop_4))) stop("Variable 'A17r8' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r8"]]) == 1, na.rm = TRUE)
  # Row 10: A17r9 == 1
  if (!("A17r9" %in% names(stacked_loop_4))) stop("Variable 'A17r9' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A17r9"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a17_1", rowCount = 10)

}, error = function(e) {
  list(success = FALSE, tableId = "a17_1", error = conditionMessage(e))
})

print(paste("Validated:", "a17_1", "-", if(validation_results[["a17_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a17_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a19_1 (frequency) [loop: stacked_loop_4]
# -----------------------------------------------------------------------------

validation_results[["a19_1"]] <- tryCatch({

  # Row 1: Category header - Reasons for choosing the brand: (skip validation)
  # Row 2: NET - Any reason (NET)
  if (!("A19r1" %in% names(stacked_loop_4))) stop("NET component variable 'A19r1' not found")
  if (!("A19r2" %in% names(stacked_loop_4))) stop("NET component variable 'A19r2' not found")
  if (!("A19r3" %in% names(stacked_loop_4))) stop("NET component variable 'A19r3' not found")
  if (!("A19r4" %in% names(stacked_loop_4))) stop("NET component variable 'A19r4' not found")
  if (!("A19r5" %in% names(stacked_loop_4))) stop("NET component variable 'A19r5' not found")
  if (!("A19r6" %in% names(stacked_loop_4))) stop("NET component variable 'A19r6' not found")
  if (!("A19r7" %in% names(stacked_loop_4))) stop("NET component variable 'A19r7' not found")
  if (!("A19r8" %in% names(stacked_loop_4))) stop("NET component variable 'A19r8' not found")
  if (!("A19r9" %in% names(stacked_loop_4))) stop("NET component variable 'A19r9' not found")
  if (!("A19r10" %in% names(stacked_loop_4))) stop("NET component variable 'A19r10' not found")
  if (!("A19r11" %in% names(stacked_loop_4))) stop("NET component variable 'A19r11' not found")
  # Row 3: A19r1 == 1
  if (!("A19r1" %in% names(stacked_loop_4))) stop("Variable 'A19r1' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r1"]]) == 1, na.rm = TRUE)
  # Row 4: A19r2 == 1
  if (!("A19r2" %in% names(stacked_loop_4))) stop("Variable 'A19r2' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r2"]]) == 1, na.rm = TRUE)
  # Row 5: A19r3 == 1
  if (!("A19r3" %in% names(stacked_loop_4))) stop("Variable 'A19r3' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r3"]]) == 1, na.rm = TRUE)
  # Row 6: A19r4 == 1
  if (!("A19r4" %in% names(stacked_loop_4))) stop("Variable 'A19r4' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r4"]]) == 1, na.rm = TRUE)
  # Row 7: A19r5 == 1
  if (!("A19r5" %in% names(stacked_loop_4))) stop("Variable 'A19r5' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r5"]]) == 1, na.rm = TRUE)
  # Row 8: A19r6 == 1
  if (!("A19r6" %in% names(stacked_loop_4))) stop("Variable 'A19r6' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r6"]]) == 1, na.rm = TRUE)
  # Row 9: A19r7 == 1
  if (!("A19r7" %in% names(stacked_loop_4))) stop("Variable 'A19r7' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r7"]]) == 1, na.rm = TRUE)
  # Row 10: A19r8 == 1
  if (!("A19r8" %in% names(stacked_loop_4))) stop("Variable 'A19r8' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r8"]]) == 1, na.rm = TRUE)
  # Row 11: A19r9 == 1
  if (!("A19r9" %in% names(stacked_loop_4))) stop("Variable 'A19r9' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r9"]]) == 1, na.rm = TRUE)
  # Row 12: A19r10 == 1
  if (!("A19r10" %in% names(stacked_loop_4))) stop("Variable 'A19r10' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r10"]]) == 1, na.rm = TRUE)
  # Row 13: A19r11 == 1
  if (!("A19r11" %in% names(stacked_loop_4))) stop("Variable 'A19r11' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r11"]]) == 1, na.rm = TRUE)
  # Row 14: A19r12 == 1
  if (!("A19r12" %in% names(stacked_loop_4))) stop("Variable 'A19r12' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A19r12"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a19_1", rowCount = 14)

}, error = function(e) {
  list(success = FALSE, tableId = "a19_1", error = conditionMessage(e))
})

print(paste("Validated:", "a19_1", "-", if(validation_results[["a19_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a19_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a7_1 (frequency) [loop: stacked_loop_4]
# -----------------------------------------------------------------------------

validation_results[["a7_1"]] <- tryCatch({

  # Row 1: NET - Any other substance (NET)
  if (!("A7r1" %in% names(stacked_loop_4))) stop("NET component variable 'A7r1' not found")
  if (!("A7r2" %in% names(stacked_loop_4))) stop("NET component variable 'A7r2' not found")
  if (!("A7r3" %in% names(stacked_loop_4))) stop("NET component variable 'A7r3' not found")
  if (!("A7r4" %in% names(stacked_loop_4))) stop("NET component variable 'A7r4' not found")
  if (!("A7r5" %in% names(stacked_loop_4))) stop("NET component variable 'A7r5' not found")
  # Row 2: A7r1 == 1
  if (!("A7r1" %in% names(stacked_loop_4))) stop("Variable 'A7r1' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r1"]]) == 1, na.rm = TRUE)
  # Row 3: A7r2 == 1
  if (!("A7r2" %in% names(stacked_loop_4))) stop("Variable 'A7r2' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r2"]]) == 1, na.rm = TRUE)
  # Row 4: A7r3 == 1
  if (!("A7r3" %in% names(stacked_loop_4))) stop("Variable 'A7r3' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r3"]]) == 1, na.rm = TRUE)
  # Row 5: A7r4 == 1
  if (!("A7r4" %in% names(stacked_loop_4))) stop("Variable 'A7r4' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r4"]]) == 1, na.rm = TRUE)
  # Row 6: A7r5 == 1
  if (!("A7r5" %in% names(stacked_loop_4))) stop("Variable 'A7r5' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r5"]]) == 1, na.rm = TRUE)
  # Row 7: A7r6 == 1
  if (!("A7r6" %in% names(stacked_loop_4))) stop("Variable 'A7r6' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A7r6"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a7_1", rowCount = 7)

}, error = function(e) {
  list(success = FALSE, tableId = "a7_1", error = conditionMessage(e))
})

print(paste("Validated:", "a7_1", "-", if(validation_results[["a7_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a7_1"]]$error)))

# -----------------------------------------------------------------------------
# Table: a9_1 (frequency) [loop: stacked_loop_4]
# -----------------------------------------------------------------------------

validation_results[["a9_1"]] <- tryCatch({

  # Row 1: NET - Any companion (NET)
  if (!("A9r2" %in% names(stacked_loop_4))) stop("NET component variable 'A9r2' not found")
  if (!("A9r3" %in% names(stacked_loop_4))) stop("NET component variable 'A9r3' not found")
  if (!("A9r4" %in% names(stacked_loop_4))) stop("NET component variable 'A9r4' not found")
  if (!("A9r5" %in% names(stacked_loop_4))) stop("NET component variable 'A9r5' not found")
  if (!("A9r6" %in% names(stacked_loop_4))) stop("NET component variable 'A9r6' not found")
  if (!("A9r7" %in% names(stacked_loop_4))) stop("NET component variable 'A9r7' not found")
  # Row 2: A9r1 == 1
  if (!("A9r1" %in% names(stacked_loop_4))) stop("Variable 'A9r1' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r1"]]) == 1, na.rm = TRUE)
  # Row 3: A9r2 == 1
  if (!("A9r2" %in% names(stacked_loop_4))) stop("Variable 'A9r2' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r2"]]) == 1, na.rm = TRUE)
  # Row 4: A9r3 == 1
  if (!("A9r3" %in% names(stacked_loop_4))) stop("Variable 'A9r3' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r3"]]) == 1, na.rm = TRUE)
  # Row 5: A9r4 == 1
  if (!("A9r4" %in% names(stacked_loop_4))) stop("Variable 'A9r4' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r4"]]) == 1, na.rm = TRUE)
  # Row 6: A9r5 == 1
  if (!("A9r5" %in% names(stacked_loop_4))) stop("Variable 'A9r5' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r5"]]) == 1, na.rm = TRUE)
  # Row 7: A9r6 == 1
  if (!("A9r6" %in% names(stacked_loop_4))) stop("Variable 'A9r6' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r6"]]) == 1, na.rm = TRUE)
  # Row 8: A9r7 == 1
  if (!("A9r7" %in% names(stacked_loop_4))) stop("Variable 'A9r7' not found")
  test_val <- sum(as.numeric(stacked_loop_4[["A9r7"]]) == 1, na.rm = TRUE)

  list(success = TRUE, tableId = "a9_1", rowCount = 8)

}, error = function(e) {
  list(success = FALSE, tableId = "a9_1", error = conditionMessage(e))
})

print(paste("Validated:", "a9_1", "-", if(validation_results[["a9_1"]]$success) "PASS" else paste("FAIL:", validation_results[["a9_1"]]$error)))

# =============================================================================
# Write Validation Results
# =============================================================================

write_json(validation_results, "validation/validation-results.json", pretty = TRUE, auto_unbox = TRUE)
print(paste("Validation results written to:", "validation/validation-results.json"))

# Summary
success_count <- sum(sapply(validation_results, function(x) x$success))
fail_count <- length(validation_results) - success_count
print(paste("Validation complete:", success_count, "passed,", fail_count, "failed"))