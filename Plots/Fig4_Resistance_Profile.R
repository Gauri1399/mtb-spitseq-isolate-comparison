library(dplyr)
library(tidyr)
library(ggplot2)

# -------------------------
# Read table
# -------------------------
# -------------------------
# Read table
# -------------------------
tbp_variants <- read.csv(
  "tbprofiler.variants.csv",
  header = TRUE,
  stringsAsFactors = FALSE
)

tbp_variants <- tbp_variants %>%
  rename(drug = drugs)

# Remove variants that are not associated with a drug
tbp_variants <- tbp_variants %>%
  filter(
    !is.na(drug),
    drug != "-",
    drug != ""
  )

# Separate multiple drugs if any
tbp_variants <- tbp_variants %>%
  separate_rows(drug, sep = ";")

# Create mutation label
tbp_variants <- tbp_variants %>%
  mutate(
    mutation_label = paste0(gene_name, " ", change)
  )
# -------------------------
# WHO drug classes
# -------------------------
drug_class_df <- data.frame(
  drug = c(
    "isoniazid",
    "rifampicin",
    "ethambutol",
    "bedaquiline",
    "linezolid",
    "moxifloxacin",
    "levofloxacin",
    "clofazimine",
    "cycloserine",
    "delamanid",
    "pretomanid",
    "amikacin",
    "streptomycin",
    "ethionamide",
    "para-aminosalicylic_acid",
    "pyrazinamide",
    "kanamycin",
    "capreomycin"
  ),
  drug_class = c(
    rep("First-line", 3),
    rep("Group A", 4),
    rep("Group B", 2),
    rep("Group C", 7),
    rep("No longer recommended", 2)
  ),
  stringsAsFactors = FALSE
)

tbp_variants <- tbp_variants %>%
  left_join(drug_class_df, by = "drug")

# -------------------------
# Remove duplicates
# -------------------------
heatmap_long <- tbp_variants %>%
  distinct(
    sample,
    drug,
    mutation_label,
    drug_class
  )

# -------------------------
# Order isolates numerically
# -------------------------
isolate_order <- heatmap_long %>%
  distinct(sample) %>%
  mutate(
    isolate_number = as.numeric(
      gsub("Isolate_", "", sample)
    )
  ) %>%
  arrange(isolate_number) %>%
  pull(sample)

heatmap_long <- heatmap_long %>%
  mutate(
    sample = factor(
      sample,
      levels = isolate_order
    ),
    drug_class = factor(
      drug_class,
      levels = c(
        "First-line",
        "Group A",
        "Group B",
        "Group C",
        "No longer recommended"
      )
    )
  )

# -------------------------
# Create mutation order
# -------------------------
y_order <- heatmap_long %>%
  distinct(
    drug_class,
    drug,
    mutation_label
  ) %>%
  arrange(
    drug_class,
    drug,
    mutation_label
  ) %>%
  pull(mutation_label) %>%
  unique()

heatmap_long$mutation_label <- factor(
  heatmap_long$mutation_label,
  levels = rev(y_order)
)

# -------------------------
# Create right-side drug labels
# -------------------------
drug_labels <- heatmap_long %>%
  mutate(
    y_numeric = as.numeric(mutation_label)
  ) %>%
  group_by(drug) %>%
  summarise(
    y = mean(y_numeric),
    .groups = "drop"
  )

# -------------------------
# FINAL PLOT
# -------------------------
ggplot(
  heatmap_long,
  aes(
    x = sample,
    y = mutation_label,
    fill = drug_class
  )
) +
  geom_tile(color = "grey85") +
  
  # Right-side drug labels
  geom_text(
    data = drug_labels,
    aes(
      x = Inf,
      y = y,
      label = drug
    ),
    inherit.aes = FALSE,
    hjust = -0.1,
    size = 3.5,
    fontface = "bold"
  ) +
  
  scale_fill_manual(
    values = c(
      "First-line" = "#1b9e77",
      "Group A" = "#d95f02",
      "Group B" = "#7570b3",
      "Group C" = "#e7298a",
      "No longer recommended" = "#66a61e"
    )
  ) +
  
  scale_x_discrete(
    expand = expansion(
      mult = c(0.01, 0.2)
    )
  ) +
  
  theme_minimal(base_size = 12) +
  
  theme(
    axis.text.x = element_text(
      angle = 90,
      vjust = 0.5,
      hjust = 1,
      size = 8
    ),
    axis.text.y = element_text(size = 6),
    panel.grid = element_blank(),
    plot.margin = margin(
      5.5, 40, 5.5, 5.5
    )
  ) +
  
  labs(
    x = "Isolate",
    y = "Mutation",
    fill = "Drug Class",
    title = "Drug Resistance Mutation Landscape"
  )

# -------------------------
# Create mutation/drug table
# -------------------------
drug_table_long <- tbp_variants %>%
  dplyr::select(
    drug_class,
    drug,
    mutation_label
  ) %>%
  dplyr::arrange(
    drug_class,
    drug
  ) %>%
  dplyr::distinct() %>%
  dplyr::ungroup()