library(dplyr)
library(ggplot2)

# ---------------------------------------------------------
# Read TB-Profiler variant results
# ---------------------------------------------------------
tbp_variants <- read.csv(
  file.path(
    "..",
    "results",
    "isolate",
    "tbprofiler",
    "tbprofiler.variants.csv"
  ),
  header = TRUE,
  stringsAsFactors = FALSE
)

# -------------------------
# Convert variant type into mutation category
# -------------------------
tbp_variants <- tbp_variants %>%
  mutate(
    mutation_category = case_when(
      
      # Silent mutations
      type %in% c(
        "synonymous_variant"
      ) ~ "Silent",
      
      # Missense mutations
      type %in% c(
        "missense_variant"
      ) ~ "Missense",
      
      # Protein-disrupting mutations
      type %in% c(
        "frameshift_variant",
        "stop_gained",
        "stop_lost",
        "start_lost",
        "splice_acceptor_variant",
        "splice_donor_variant"
      ) ~ "Protein Disrupting",
      
      # In-frame insertions/deletions
      type %in% c(
        "inframe_insertion",
        "inframe_deletion"
      ) ~ "Inframe indels",
      
      # Everything else
      TRUE ~ "Other"
    )
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

# -------------------------
# Count mutations per isolate
# -------------------------
mutation_counts <- tbp_variants %>%
  group_by(sample, mutation_category) %>%
  summarise(
    count = n(),
    .groups = "drop"
  ) %>%
  mutate(
    sample = factor(
      sample,
      levels = isolate_order
    ),
    mutation_category = factor(
      mutation_category,
      levels = c(
        "Inframe indels",
        "Missense",
        "Other",
        "Protein Disrupting",
        "Silent"
      )
    )
  )

# -------------------------
# Plot
# -------------------------
ggplot(
  mutation_counts,
  aes(
    x = sample,
    y = count,
    fill = mutation_category
  )
) +
  geom_bar(
    stat = "identity",
    width = 0.9
  ) +
  
  geom_text(
    aes(label = count),
    position = position_stack(vjust = 0.5),
    size = 3.5
  ) +
  
  scale_fill_manual(
    values = c(
      "Inframe indels" = "#ff7f0e",
      "Missense" = "#1f77b4",
      "Other" = "#9467bd",
      "Protein Disrupting" = "#d62728",
      "Silent" = "#2ca02c"
    )
  ) +
  
  labs(
    x = "Sample",
    y = "Number of Mutations",
    fill = "Mutation Category",
    title = "Mutation counts per Isolate sample"
  ) +
  
  theme_minimal(base_size = 12) +
  
  theme(
    axis.text.x = element_text(
      angle = 90,
      vjust = 0.5,
      hjust = 1,
      size = 8
    ),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(
      color = "grey90"
    ),
    legend.position = "right"
  )