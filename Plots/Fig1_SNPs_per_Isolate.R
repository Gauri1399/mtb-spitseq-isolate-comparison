library(dplyr)
library(ggplot2)

# -------------------------
# Read TB-Profiler variants
# -------------------------
tbp_variants <- read.csv(
  "tbprofiler.variants.csv",
  header = TRUE,
  stringsAsFactors = FALSE
)

# -------------------------
# Classify SNPs
# -------------------------
snp_counts <- tbp_variants %>%
  mutate(
    snp_type = case_when(
      freq == 1 ~ "Fixed SNP",
      freq < 1 ~ "Mixed SNP",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(snp_type)) %>%
  group_by(sample, snp_type) %>%
  summarise(
    count = n(),
    .groups = "drop"
  )

# -------------------------
# Order isolates numerically
# -------------------------
isolate_order <- tbp_variants %>%
  distinct(sample) %>%
  mutate(
    isolate_number = as.numeric(
      gsub("Isolate_", "", sample)
    )
  ) %>%
  arrange(isolate_number) %>%
  pull(sample)

snp_counts <- snp_counts %>%
  mutate(
    sample = factor(
      sample,
      levels = isolate_order
    ),
    snp_type = factor(
      snp_type,
      levels = c("Mixed SNP", "Fixed SNP")
    )
  )

# -------------------------
# Plot
# -------------------------
ggplot(
  snp_counts,
  aes(
    x = sample,
    y = count,
    fill = snp_type
  )
) +
  geom_bar(
    stat = "identity"
  ) +
  scale_fill_manual(
    values = c(
      "Fixed SNP" = "#4C78A8",
      "Mixed SNP" = "#A9D1E3"
    )
  ) +
  labs(
    title = "SNP Counts per MTB Isolate",
    x = "Isolate",
    y = "Number of SNPs",
    fill = "SNP Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(
      angle = 60,
      hjust = 1,
      vjust = 1,
      size = 8
    ),
    panel.grid.minor = element_blank(),
    plot.title = element_text(
      size = 16,
      face = "plain"
    ),
    legend.position = "right"
  )