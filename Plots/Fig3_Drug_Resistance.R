library(ggplot2)
library(dplyr)
library(tidyr)
library(here)

# ---------------------------------------------------------
# Read TB-Profiler variant results
# ---------------------------------------------------------
# Build the input path relative to the project root.
tbp_variants <- read.csv(
  here(
    "results",
    "isolate",
    "tbprofiler",
    "tbprofiler.variants.csv"
  ),
  header = TRUE,
  stringsAsFactors = FALSE
)

# Define column names used in the analysis
sample_col <- "sample"
drug_col   <- "drugs"

# ---------------------------------------------------------
# Identify drug-associated mutations
# ---------------------------------------------------------
# Keep variants associated with a specific drug.
# Variants with "-" or an empty drug field are excluded.
resistant_pairs <- tbp_variants %>%
  filter(
    .data[[drug_col]] != "-",
    .data[[drug_col]] != ""
  ) %>%
  select(
    Sample = all_of(sample_col),
    Drug = all_of(drug_col)
  ) %>%
  separate_rows(
    Drug,
    sep = "[,;]\\s*"
  ) %>%
  distinct(Sample, Drug) %>%
  mutate(
    Resistant = "Yes"
  )

# ---------------------------------------------------------
# Create complete sample × drug combinations
# ---------------------------------------------------------
all_drugs <- sort(unique(resistant_pairs$Drug))

# Order isolates numerically rather than alphabetically
all_samples <- unique(tbp_variants[[sample_col]])

all_samples <- all_samples[
  order(
    as.numeric(
      gsub("\\D", "", all_samples)
    )
  )
]

# Create a complete grid of all drug × isolate combinations
full_grid <- expand.grid(
  Drug = all_drugs,
  Sample = all_samples,
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------
# Assign resistance status
# ---------------------------------------------------------
# Combinations identified by TB-Profiler as drug-associated
# are marked "Yes"; all other combinations are marked "No".
df <- full_grid %>%
  left_join(
    resistant_pairs,
    by = c("Drug", "Sample")
  ) %>%
  mutate(
    Resistant = ifelse(
      is.na(Resistant),
      "No",
      Resistant
    )
  )

# ---------------------------------------------------------
# Set plotting order
# ---------------------------------------------------------
df$Drug <- factor(
  df$Drug,
  levels = rev(sort(unique(df$Drug)))
)

df$Sample <- factor(
  df$Sample,
  levels = all_samples
)

df$Resistant <- factor(
  df$Resistant,
  levels = c("No", "Yes")
)

# ---------------------------------------------------------
# Plot drug resistance by isolate
# ---------------------------------------------------------
ggplot(
  df,
  aes(
    x = Sample,
    y = Drug,
    color = Resistant
  )
) +
  geom_point(size = 5) +
  scale_color_manual(
    name = "Resistant?",
    values = c(
      "Yes" = "#E8140B",
      "No" = "#2ECC40"
    )
  ) +
  labs(
    title = "Drug Resistance by Isolate Sample",
    x = "Sample",
    y = "Drug"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major = element_line(
      color = "grey90"
    ),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size = 8
    ),
    axis.text.y = element_text(
      size = 9
    ),
    plot.title = element_text(
      face = "plain",
      size = 16,
      hjust = 0
    ),
    legend.position = "right"
  )