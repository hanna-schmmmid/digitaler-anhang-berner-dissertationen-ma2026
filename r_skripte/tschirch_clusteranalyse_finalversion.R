# ============================================================
# TSCHIRCH-DISSERTATIONEN: CLUSTERANALYSE
# ============================================================

library(tidyverse)
library(cluster)
library(ggdendro)
library(patchwork)
library(ggrepel)
library(scales)
library(tidytext)

# ============================================================
# PFADE  –  vor dem Ausfuehren ggf. BASE_DIR anpassen
# ============================================================
# Alle CSV-Dateien werden relativ zu BASE_DIR erwartet, und zwar in
# der Unterstruktur, die auch in der Arbeit dokumentiert ist:
#   BASE_DIR/
#     ├── cluster_analyse/
#     │     └── clustering_tschirch_diss_tschirch_clusteranalysis_2026-03-30_17-15.csv
#     └── csv_daten/
#           ├── Getting Started - diss_tschirch (diss_tschirch_historisch) 2026-04-14_16-57.csv
#           └── Getting Started - tschirch_top_personen (tschirch_top_personen) 2026-04-15_10-36.csv
#
# Standardmaessig wird das Arbeitsverzeichnis von R verwendet (getwd()).
# Wer die Daten woanders liegen hat, setzt BASE_DIR einmalig auf den
# entsprechenden Ordner, z. B.:
#   BASE_DIR <- "C:/Users/hanna/Masterarbeit/auswertung"
BASE_DIR <- getwd()

CSV_CLUSTER  <- file.path(BASE_DIR, "cluster_analyse",
  "clustering_tschirch_diss_tschirch_clusteranalysis_2026-03-30_17-15.csv")
CSV_HIST     <- file.path(BASE_DIR, "csv_daten",
  "Getting Started - diss_tschirch (diss_tschirch_historisch) 2026-04-14_16-57.csv")
CSV_PERSREF  <- file.path(BASE_DIR, "csv_daten",
  "Getting Started - tschirch_top_personen (tschirch_top_personen) 2026-04-15_10-36.csv")
OUT_DIR      <- "output_cluster_v2"

dir.create(OUT_DIR, showWarnings = FALSE)

# ============================================================
# FARBEN
# ============================================================
CLUSTER_COLORS <- c(A = "#B0C4DE", B = "#7EB8A0", C = "#E8A87C", D = "#C97B8A")

stellenwert_farben <- c(
  "1 – gering"  = "#F7E3D8",
  "2 – mittel"  = "#E8B79F",
  "3 – zentral" = "#D78663"
)

epochen_farben <- c(
  "Mythisch / Frühgeschichte" = "#E8D5A3",   # Warmgelb
  "Altertum"                  = "#A8C5E0",   # Hellblau
  "Mittelalter"               = "#C4A8D4",   # Lavendel
  "Frühe Neuzeit"             = "#A8C5A0",   # Salbeigrün
  "19. Jahrhundert"           = "#F0BC82",   # Orange
  "Frühes 20. Jahrhundert"    = "#E8A0B4"    # Rosa
)

tradition_farben <- c(
  "Griechisch-römische Antike"       = "#A8C5E0",   # Hellblau
  "Arabisch-islamische Medizin"      = "#E8C870",   # Goldgelb
  "Byzantinische Medizin"            = "#C4A8D4",   # Lavendel
  "Frühneuzeitliche Botanik"         = "#A8C5A0",   # Salbeigrün
  "Frühneuzeitliche Pharmakochemie"  = "#F0BC82",   # Orange
  "Chemie & Pharmazie 19. Jh."       = "#E8A0B4",   # Rosa
  "Botanik & Pharmakognosie 19. Jh." = "#7DB8B0",   # Petrol
  "Geographie & Handelswege"         = "#C8D48C",   # Gelbgrün
  "Mythisch / Frühgeschichte"        = "#E8D5A3"    # Warmgelb
)

zeitkontext_farben <- c(
  "1. Weltkrieg"       = "#E8A0B4",   # Rosa
  "Hochimperialismus"  = "#7DB8B0",   # Petrol
  "Zwischenkriegszeit" = "#C4A8D4"    # Lavendel
)

quellen_farben <- c(
  "Historisch"          = "#E8C870",   # Goldgelb
  "Naturwiss./Fachlich" = "#7DB8B0"    # Petrol
)

hk_farben_fix <- c(
  "Deutsches Reich"                  = "#E8A0B4",   # Rosa
  "Schweizerische Eidgenossenschaft" = "#A8C5A0",   # Salbeigrün
  "Österreich-Ungarn"                = "#A8C5E0",   # Hellblau
  "Russisches Reich"                 = "#E8C870",   # Goldgelb
  "Vereinigte Staaten von Amerika"   = "#F0BC82",   # Orange
  "Königreich Polen"                 = "#C4A8D4",   # Lavendel
  "Königreich Norwegen"              = "#7DB8B0",   # Petrol
  "Königreich der Niederlande"       = "#C8D48C",   # Gelbgrün
  "unbekannt"                        = "#CCCCCC"    # Grau
)

stoff_farben_fix <- c(
  "Harze"                    = "#A8C5E0",   # Hellblau
  "Balsame"                  = "#A8C5A0",   # Salbeigrün
  "Gummiharze"               = "#F0BC82",   # Orange
  "Gummi"                    = "#C4A8D4",   # Lavendel
  "Alkaloide und Glykoside"  = "#E8C870",   # Goldgelb
  "Anthrachinon-Drogen"      = "#E8A0B4",   # Rosa
  "Gewürze und Genussmittel" = "#7DB8B0",   # Petrol
  "Botanische Pflanzenteile" = "#C8D48C",   # Gelbgrün
  "Gerüststoffe"             = "#D4A8A0",   # Altrosa/Terrakotta
  "Systematische Gruppen"    = "#B8C8E8",   # Lavendelblau
  "Sonstige"                 = "#CCCCCC"    # Grau
)

register_farben <- c(
  "wertend-positiv"       = "#A8C5A0",   # Salbeigrün
  "deskriptiv-neutral"    = "#A8C5E0",   # Hellblau
  "wertend-kritisch"      = "#F0BC82",   # Orange
  "autoritativ-kanonisch" = "#C4A8D4"    # Lavendel
)

funktion_farben <- c(
  "legitimierend" = "#F0BC82",   # Orange
  "kanonbildend"  = "#7DB8B0",   # Petrol
  "ornamental"    = "#E8C870",   # Goldgelb
  "abgrenzend"    = "#C4A8D4"    # Lavendel
)

narrativ_farben <- c(
  "thematisch-systematisch" = "#A8C5A0",   # Salbeigrün
  "chronologisch"           = "#F0BC82",   # Orange
  "personenzentriert"       = "#E8A0B4",   # Rosa
  "teleologisch"            = "#C8D48C"    # Gelbgrün
)

save_plot <- function(p, name, w = 14, h = 8) {
  path <- file.path(OUT_DIR, paste0(name, ".png"))
  ggsave(path, plot = p, width = w, height = h, dpi = 300, bg = "white")
  message("✓ ", name)
}

# ============================================================
# HILFSFUNKTIONEN
# ============================================================

as_bool_strict <- function(x) tolower(trimws(as.character(x))) == "true"

clean_zeitkontext <- function(x) {
  case_when(
    str_detect(replace_na(x,""), "Russische Revolution") ~ "1. Weltkrieg",
    x %in% c("1. Weltkrieg","Hochimperialismus","Zwischenkriegszeit") ~ x,
    TRUE ~ NA_character_
  )
}

HIST_QUELLEN <- c(
  "Historische Sekundärquellen","Historische Wissensliteratur",
  "Kräuterbuch","Arzneibuch","Antidotarius","Religiöse Schriften",
  "Reiseberichte","Historische Zeitschrift","Apothekeninventar","Taxen, Listen"
)

EPOCH_ALL <- c(
  "Frühgeschichte","Altertum","Frühmittelalter","Mittelalter",
  "Frühe Neuzeit","Anfang 19. Jahrhundert","Mitte 19. Jahrhundert",
  "Gesamtes 19. Jahrhundert","Übergang 19. Jahrhundert","Ende 19. Jahrhundert"
)

EPOCH_PRE19 <- c(
  "Frühgeschichte","Altertum","Frühmittelalter","Mittelalter","Frühe Neuzeit"
)

count_matches <- function(text, patterns) {
  if (is.na(text) || text == "") return(0L)
  sum(str_detect(text, fixed(patterns)))
}

count_items <- function(text) {
  if (is.na(text) || str_trim(text) == "") return(0L)
  length(str_split(text, ",")[[1]] |> str_trim() |> (\(x) x[x != ""])())
}

# p-Wert Formatierung für Plots
pval_label <- function(p) {
  case_when(
    p < 0.001 ~ "p < .001 ***",
    p < 0.01  ~ sprintf("p = %.3f **", p),
    p < 0.05  ~ sprintf("p = %.3f *", p),
    TRUE      ~ sprintf("p = %.3f (n.s.)", p)
  )
}

fix_person_names <- function(x) {
  x %>%
    str_trim() %>%
    recode(
      "Jöns Jakob Berzellius" = "Jöns Jakob Berzelius",
      "Berzellius" = "Berzelius"
    )
}

# ============================================================
# 1. DATEN LADEN & FEATURES BERECHNEN
# ============================================================

raw <- read_csv(CSV_CLUSTER, show_col_types = FALSE)
names(raw)[1] <- "id1"

df_hist_extra <- read_csv(CSV_HIST, show_col_types = FALSE)
names(df_hist_extra)[1] <- "id1"

df_personen_ref <- read_csv(CSV_PERSREF, show_col_types = FALSE) |>
  mutate(
    person = str_trim(person),
    person = recode(person,
                    "Jöns Jakob Berzellius" = "Jöns Jakob Berzelius",
                    "Berzellius"            = "Berzelius"
    )
  )

df_personen <- df_hist_extra |>
  filter(!is.na(wichtige_historische_personen_im_text),
         wichtige_historische_personen_im_text != "") |>
  mutate(person_list = str_split(wichtige_historische_personen_im_text, ",")) |>
  unnest(person_list) |>
  mutate(person = str_trim(person_list),
         person = recode(person,
                         "Jöns Jakob Berzellius" = "Jöns Jakob Berzelius",
                         "Berzellius"            = "Berzelius")) |>
  filter(person != "") |>
  left_join(df_personen_ref |> select(person, tradition), by = "person")

# Hauptvariablen berechnen
df <- raw |>
  mutate(
    anteil_hist_clean = as.numeric(anteil_historisch) |> replace_na(0),
    n_hist_quellen    = map_int(quellentypen, \(x) count_matches(x, HIST_QUELLEN)),
    n_epochen         = map_int(vorkommende_epochen, \(x) count_matches(x, EPOCH_ALL)),
    n_pre19           = map_int(vorkommende_epochen, \(x) count_matches(x, EPOCH_PRE19)),
    n_personen        = map_int(wichtige_historische_personen_im_text, count_items),
    hat_altertum      = as.integer(str_detect(replace_na(vorkommende_epochen,""),
                                              fixed("Altertum"))),
    hat_mittelalter   = as.integer(str_detect(replace_na(vorkommende_epochen,""),
                                              fixed("Mittelalter"))),
    hat_fruehneuzeit  = as.integer(str_detect(replace_na(vorkommende_epochen,""),
                                              fixed("Frühe Neuzeit"))),
    fokus_allg        = as.integer(str_detect(replace_na(fokus_historischer_teil,""),
                                              "Allgemeine Pharmaziegeschichte")),
    fokus_f           = factor(case_when(
      str_detect(replace_na(fokus_historischer_teil,""),
                 "Allgemeine Pharmaziegeschichte") ~ "allgemein",
      str_detect(replace_na(fokus_historischer_teil,""),
                 "Naturwissenschafts")              ~ "naturwiss",
      str_trim(replace_na(fokus_historischer_teil,"")) == "" ~ "kein",
      TRUE ~ "andere"
    )),
    sw_ord       = factor(historie_stellenwert_skala, levels = 1:3, ordered = TRUE),
    stoffklasse_f = factor(stoffklasse)
  )

# Ohne "Sonstige" für Clustering
df_main <- df |> filter(stoffklasse != "Sonstige")

# Zusatzvariablen aus Haupt-CSV joinen
df_extra <- df_hist_extra |>
  select(id1, herkunftsland, sprachregister, narrative_form, wozu_dient_geschichte,
         zaesuren_zeitkontext, methoden_typ, spache, zitiert_tschirch,
         tschirch_werke, seiten_gesamt, untersuchungsgegenstand) |>
  mutate(
    tschirch_zit      = as_bool_strict(zitiert_tschirch),
    zeitkontext_clean = clean_zeitkontext(zaesuren_zeitkontext),
    zeitkontext_clean = factor(
      zeitkontext_clean,
      levels = c("Hochimperialismus", "1. Weltkrieg", "Zwischenkriegszeit")),
    seiten_gesamt     = as.numeric(seiten_gesamt)
  )


# ============================================================
# 2. GOWER-DISTANZ & HIERARCHISCHES CLUSTERING
# ============================================================

cluster_vars <- df_main |>
  select(sw_ord, anteil_hist_clean, n_pre19, n_hist_quellen,
         n_personen, stoffklasse_f, fokus_f)

weights_vec <- c(0.28, 0.14, 0.19, 0.19, 0.09, 0.05, 0.06)
gower_dist  <- daisy(cluster_vars, metric = "gower", weights = weights_vec)
hc          <- hclust(gower_dist, method = "ward.D2")
print(round(sort(hc$height, decreasing = TRUE)[1:6], 4))
cat("cut_height =", round(mean(sort(hc$height, decreasing = TRUE)[3:4]), 4), "\n")

df_main <- df_main |>
  mutate(cluster_raw = cutree(hc, k = 4))

cluster_profile <- df_main |>
  group_by(cluster_raw) |>
  summarise(sw_mean = mean(as.numeric(as.character(sw_ord))),
            pre19_mean = mean(n_pre19), .groups = "drop") |>
  arrange(sw_mean, pre19_mean) |>
  mutate(cluster = LETTERS[1:n()])

df_main <- df_main |>
  left_join(cluster_profile |> select(cluster_raw, cluster), by = "cluster_raw") |>
  mutate(cluster = factor(cluster, levels = c("A","B","C","D"))) |>
  left_join(df_extra, by = "id1")

cat("\nCluster-Verteilung:\n")
print(table(df_main$cluster))

CLUSTER_DESC <- c(
  A = "Einleitend-funktional",
  B = "Personengestützt, quellenarm",
  C = "Multiperspektivisch, quellenreich",
  D = "Historiographisch umfassend"
)

cluster_n   <- df_main |> count(cluster)
CLUSTER_LABELS <- setNames(
  mapply(function(cl, desc) {
    n_val <- cluster_n$n[cluster_n$cluster == cl]
    sprintf("Typ %s – %s\n(n=%d)", cl, desc, n_val)
  }, names(CLUSTER_DESC), CLUSTER_DESC),
  names(CLUSTER_DESC)
)

# Kennzahlen-Tabelle
kennzahlen <- df_main |>
  group_by(cluster) |>
  summarise(
    n                 = n(),
    sw_mean           = round(mean(as.numeric(as.character(sw_ord))), 2),
    anteil_mean_pct   = round(mean(anteil_hist_clean) * 100, 1),
    pre19_mean        = round(mean(n_pre19), 2),
    hist_quellen_mean = round(mean(n_hist_quellen), 2),
    personen_mean     = round(mean(n_personen), 1),
    pct_altertum      = round(mean(hat_altertum) * 100, 0),
    pct_mittelalter   = round(mean(hat_mittelalter) * 100, 0),
    pct_fruehneuzeit  = round(mean(hat_fruehneuzeit) * 100, 0),
    .groups = "drop"
  )

cat("\n=== Kennzahlen ===\n")
print(kennzahlen)

# ============================================================
# 3. KERN-VISUALISIERUNGEN (01–07)
# ============================================================

## 01 – Dendrogramm
dend_data   <- dendro_data(hc, type = "rectangle")
leaf_order  <- hc$order
leaf_colors <- CLUSTER_COLORS[df_main$cluster[leaf_order]]
cut_height  <- mean(c(sort(hc$height, decreasing = TRUE)[3],
                      sort(hc$height, decreasing = TRUE)[4]))

p_dend <- ggplot() +
  geom_segment(data = segment(dend_data),
               aes(x=x, y=y, xend=xend, yend=yend),
               colour = "#AAAAAA", linewidth = 0.4) +
  geom_point(data = label(dend_data), aes(x=x, y=0),
             colour = leaf_colors, size = 2, shape = 16) +
  geom_hline(yintercept = cut_height, linetype = "dashed",
             colour = "#333333", linewidth = 0.8) +
  annotate("text", x = 5, y = cut_height * 1.07,
           label = "← Schnittlinie: 4 Cluster", size = 3, colour = "#333333") +
  scale_y_continuous(expand = expansion(mult = c(0.01, 0.08))) +
  labs(x = "Dissertationen (Farbe = Cluster)", y = "Fusionsdistanz") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        panel.grid = element_blank())

save_plot(p_dend, "01_dendrogramm", w = 14, h = 6)

## 02 – Boxplots
df_plot <- df_main |>
  mutate(sw_num = as.numeric(as.character(sw_ord)),
         anteil_pct = anteil_hist_clean * 100)

p_sw <- ggplot(df_plot, aes(x = cluster, y = sw_num, fill = cluster)) +
  geom_boxplot(width = 0.55, outlier.shape = 21, outlier.fill = "white",
               colour = "#555555") +
  stat_summary(fun = mean, geom = "point", shape = 23,
               fill = "white", colour = "black", size = 2.5) +
  scale_fill_manual(values = CLUSTER_COLORS, guide = "none") +
  scale_y_continuous(breaks = 1:3, labels = c("1\neinleitend","2\nsubstantiell","3\nzentral")) +
  labs(x = NULL, y = "Stellenwert (1–3)") +
  theme_minimal(base_size = 10) + theme(panel.grid.major.x = element_blank())

p_ant <- ggplot(df_plot, aes(x = cluster, y = anteil_pct, fill = cluster)) +
  geom_boxplot(width = 0.55, outlier.shape = 21, outlier.fill = "white",
               colour = "#555555") +
  stat_summary(fun = mean, geom = "point", shape = 23,
               fill = "white", colour = "black", size = 2.5) +
  scale_fill_manual(values = CLUSTER_COLORS, guide = "none") +
  scale_y_continuous(labels = percent_format(scale = 1)) +
  labs(x = NULL, y = "Anteil (%)") +
  theme_minimal(base_size = 10) + theme(panel.grid.major.x = element_blank())

epoch_long <- df_main |>
  group_by(cluster) |>
  summarise(`Vor-19.-Jh.-Epochen` = mean(n_pre19),
            `19.-Jh.-Epochen`     = mean(n_epochen) - mean(n_pre19),
            .groups = "drop") |>
  pivot_longer(-cluster, names_to = "epoche", values_to = "mean_n") |>
  mutate(epoche = factor(epoche, levels = c("19.-Jh.-Epochen","Vor-19.-Jh.-Epochen")))

epoch_totals <- df_main |>
  group_by(cluster) |> summarise(total = mean(n_epochen), .groups = "drop")

p_ep <- ggplot(epoch_long, aes(x = cluster, y = mean_n, fill = epoche)) +
  geom_col(width = 0.55, colour = "white") +
  geom_text(data = epoch_totals,
            aes(x = cluster, y = total, label = sprintf("Ø %.1f", total), fill = NULL),
            vjust = -0.4, size = 3.2, fontface = "bold") +
  scale_fill_manual(values = c("Vor-19.-Jh.-Epochen" = "#C6A486",
                               "19.-Jh.-Epochen"     = "#F1E2D4"), name = NULL) +
  labs(x = NULL, y = "Ø Anzahl Epochen") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.major.x = element_blank())

save_plot(p_sw + p_ant + p_ep, "02_boxplots_epochen", w = 16, h = 5)

## 03 – Epochenpräsenz Heatmap
epoch_heatmap <- df_main |>
  group_by(cluster) |>
  summarise(Altertum        = mean(hat_altertum)    * 100,
            Mittelalter     = mean(hat_mittelalter)  * 100,
            `Frühe Neuzeit` = mean(hat_fruehneuzeit) * 100,
            .groups = "drop") |>
  pivot_longer(-cluster, names_to = "epoche", values_to = "pct") |>
  mutate(epoche = factor(epoche, levels = c("Altertum","Mittelalter","Frühe Neuzeit")))

p_hm <- ggplot(epoch_heatmap, aes(x = epoche, y = cluster, fill = pct)) +
  geom_tile(colour = "white", linewidth = 1.5) +
  geom_text(aes(label = sprintf("%.0f%%", pct),
                colour = pct > 55), size = 4.5, fontface = "bold") +
  scale_fill_gradient(low = "#FFF8EE", high = "#C6A486",
                      name = "% Diss.", limits = c(0, 100)) +
  scale_colour_manual(values = c("FALSE" = "#333333","TRUE" = "white"), guide = "none") +
  scale_y_discrete(limits = rev) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(), axis.text = element_text(size = 10))

save_plot(p_hm, "03_epochen_heatmap", w = 8, h = 5)

## 04 – Top-Personen pro Cluster
persons_long <- df_main |>
  select(cluster, wichtige_historische_personen_im_text) |>
  filter(!is.na(wichtige_historische_personen_im_text),
         wichtige_historische_personen_im_text != "") |>
  mutate(person = str_split(wichtige_historische_personen_im_text, ",")) |>
  unnest(person) |>
  mutate(person = str_trim(person)) |>
  filter(person != "") |>
  left_join(df_personen_ref |> select(person, tradition), by = "person")

top_persons <- persons_long |>
  count(cluster, person, name = "n_nennungen") |>
  # Tradition separat, pro Person (aus df_pers_ref, wo sie sicher gesetzt ist)
  left_join(df_personen_ref |> select(person, tradition), by = "person") |>
  mutate(tradition = replace_na(tradition, "Nicht zugeordnet")) |>
  group_by(cluster) |>
  slice_max(n_nennungen, n = 5, with_ties = FALSE) |>
  ungroup()

p_pers <- ggplot(top_persons,
                 aes(x = n_nennungen,
                     y = reorder_within(person, n_nennungen, cluster),
                     fill = tradition)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = n_nennungen), hjust = -0.2, size = 3, fontface = "bold") +
  scale_fill_manual(values = c(tradition_farben, "Nicht zugeordnet" = "#CCCCCC"),
                    name = "Tradition") +
  scale_y_reordered() +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  facet_wrap(
    ~cluster, scales = "free_y", ncol = 4) +
  labs(x = "Nennungen", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.major.y = element_blank(),
    strip.text = element_text(face = "bold", size = 8, lineheight = 1.0)
  )

save_plot(p_pers, "04_top_personen", w = 18, h = 7.5)


## 05 – Quellentypen pro Cluster
quellen_long <- df_main |>
  select(cluster, quellentypen) |>
  filter(!is.na(quellentypen), quellentypen != "") |>
  mutate(quelle = str_split(quellentypen, ",")) |>
  unnest(quelle) |>
  mutate(quelle = str_trim(quelle),
         quelle_short = case_when(
           quelle == "Historische Sekundärquellen"  ~ "Hist. Sekundärq.",
           quelle == "Historische Wissensliteratur" ~ "Hist. Wissensliter.",
           quelle == "Wissenschaftliche Berichte"   ~ "Wiss. Berichte",
           TRUE ~ quelle),
         ist_historisch = quelle %in% HIST_QUELLEN) |>
  filter(quelle != "")

top_quellen <- quellen_long |>
  count(cluster, quelle_short, ist_historisch, name = "n_nennungen") |>
  group_by(cluster) |>
  slice_max(n_nennungen, n = 5, with_ties = FALSE) |>
  ungroup()

p_quellen <- ggplot(top_quellen,
                    aes(x = n_nennungen,
                        y = reorder_within(quelle_short, n_nennungen, cluster),
                        fill = interaction(cluster, ist_historisch))) +
  geom_col(width = 0.7) +
  geom_text(aes(label = n_nennungen), hjust = -0.2, size = 3, fontface = "bold") +
  scale_fill_manual(values = c(
    "A.FALSE" = "#D6E4F0","A.TRUE" = "#B0C4DE",
    "B.FALSE" = "#C8E6DA","B.TRUE" = "#7EB8A0",
    "C.FALSE" = "#F5D5B8","C.TRUE" = "#E8A87C",
    "D.FALSE" = "#EAC0CC","D.TRUE" = "#C97B8A"), guide = "none") +
  scale_y_reordered() +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  facet_wrap(~cluster, scales = "free_y", ncol = 4) +
  labs(x = "Nennungen", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold", size = 10))

save_plot(p_quellen, "05_quellentypen", w = 16, h = 6)

## 06 – Streudiagramm mit konvexen Hüllen
hulls <- df_main |>
  group_by(cluster) |>
  slice(chull(n_hist_quellen, n_personen)) |>
  ungroup()

p_scatter <- ggplot(df_main,
                    aes(x = n_hist_quellen, y = n_personen,
                        colour = cluster, fill = cluster)) +
  geom_polygon(data = hulls, aes(fill = cluster), alpha = 0.12, colour = NA) +
  geom_polygon(data = hulls, aes(colour = cluster), fill = NA,
               linewidth = 0.8, linetype = "dashed") +
  geom_point(size = 3.5, alpha = 0.9, shape = 21, colour = "white",
             stroke = 0.5, aes(fill = cluster)) +
  geom_text_repel(aes(label = paste0(nachname, " (", jahr, ")"),
                      colour = cluster),
                  size = 2.8, max.overlaps = 25, box.padding = 0.4,
                  point.padding = 0.3, segment.size = 0.3,
                  segment.alpha = 0.5, show.legend = FALSE) +
  scale_fill_manual(values = CLUSTER_COLORS, name = "Cluster",
                    labels = CLUSTER_LABELS) +
  scale_colour_manual(values = CLUSTER_COLORS, name = "Cluster",
                      labels = CLUSTER_LABELS) +
  labs(x = "Anzahl historischer Quellentypen",
       y = "Anzahl genannter historischer Personen") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", legend.text = element_text(size = 8),
        panel.grid.minor = element_blank()) +
  guides(fill = guide_legend(nrow = 2), colour = guide_legend(nrow = 2))

save_plot(p_scatter, "06_scatter_quellen_personen", w = 12, h = 9)

## 07 – Übersicht kombiniert
save_plot(
  ((p_sw + p_ant + p_ep) / p_hm) +
    plot_annotation(
      tag_levels = "A",
      theme = theme(plot.title = element_text(face = "bold", size = 14))
    ),
  "07_uebersicht_kennzahlen", w = 16, h = 10
)

# ============================================================
# 4. NEUE KORRELATIONSANALYSEN (08–17)
# ============================================================

# --- 08: SPRACHREGISTER × CLUSTER ---
# Chi-Quadrat-Test: Sprachregister (Einzelnennungen) nach Cluster
register_long <- df_main |>
  filter(!is.na(sprachregister), sprachregister != "") |>
  mutate(reg = str_split(sprachregister, ",")) |>
  unnest(reg) |>
  mutate(register = str_trim(reg)) |>
  filter(register != "")

# Kreuztabelle für Chi-Quadrat
reg_cross <- register_long |>
  count(cluster, register) |>
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0)

reg_mat <- reg_cross |> select(-register) |> as.matrix()
rownames(reg_mat) <- reg_cross$register

chi_reg <- chisq.test(reg_mat)
cat(sprintf("\nChi-Quadrat Sprachregister × Cluster: X²=%.2f, df=%d, p=%.4f\n",
            chi_reg$statistic, chi_reg$parameter, chi_reg$p.value))

# Anteil pro Cluster (100% gestapelt)
reg_plot_data <- register_long |>
  count(cluster, register) |>
  group_by(cluster) |>
  mutate(pct = n / sum(n),
         cl_label = paste0("Typ ", cluster, "\n(n=",
                           cluster_n$n[cluster_n$cluster == cluster[1]], ")"))

p_register <- ggplot(reg_plot_data,
                     aes(x = cl_label, y = pct, fill = register)) +
  geom_col(position = "fill", width = 0.6) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = register_farben, name = "Sprachregister") +
  annotate("text", x = 4.4, y = 1.02,
           label = pval_label(chi_reg$p.value),
           hjust = 1, size = 3.2, color = "#555555") +
  labs(x = NULL, y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_register, "08_sprachregister_cluster")

# --- 09: NARRATIVE FORM × CLUSTER ---
narrativ_long <- df_main |>
  filter(!is.na(narrative_form), narrative_form != "") |>
  mutate(form = str_split(narrative_form, ",")) |>
  unnest(form) |>
  mutate(narrative = str_trim(form)) |>
  filter(narrative != "")

narr_cross <- narrativ_long |>
  count(cluster, narrative) |>
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0)

narr_mat <- narr_cross |> select(-narrative) |> as.matrix()
rownames(narr_mat) <- narr_cross$narrative

chi_narr <- chisq.test(narr_mat)
cat(sprintf("Chi-Quadrat Narrative Form × Cluster: X²=%.2f, df=%d, p=%.4f\n",
            chi_narr$statistic, chi_narr$parameter, chi_narr$p.value))

narr_plot_data <- narrativ_long |>
  count(cluster, narrative) |>
  group_by(cluster) |>
  mutate(pct = n / sum(n),
         cl_label = paste0("Typ ", cluster, "\n(n=",
                           cluster_n$n[cluster_n$cluster == cluster[1]], ")"))

p_narrativ <- ggplot(narr_plot_data,
                     aes(x = cl_label, y = pct, fill = narrative)) +
  geom_col(position = "fill", width = 0.6) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = narrativ_farben, name = "Narrative Form") +
  labs(x = NULL, y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_narrativ, "09_narrative_form_cluster")

# --- 10: TSCHIRCH-ZITATION × CLUSTER (Fisher's Exact) ---
tschirch_cross <- df_main |>
  count(cluster, tschirch_zit) |>
  pivot_wider(names_from = tschirch_zit, values_from = n, values_fill = 0)

tschirch_mat <- tschirch_cross |> select(-cluster) |> as.matrix()
rownames(tschirch_mat) <- tschirch_cross$cluster

fisher_tschirch <- fisher.test(tschirch_mat)
cat(sprintf("Fisher's Exact Tschirch-Zitation × Cluster: p=%.4f\n",
            fisher_tschirch$p.value))

tschirch_rate <- df_main %>%
  group_by(cluster) %>%
  summarise(
    n_total = n(),
    n_zit   = sum(tschirch_zit, na.rm = TRUE),   # dein Variablenname
    pct    = n_zit / n_total,
    .groups = "drop"
  ) %>%
  mutate(
    cluster = factor(cluster, levels = c("A","B","C","D")),
    cl_label = paste0("Typ ", cluster, " (n=", n_total, ")")
  )


p_tschirch_rate <- ggplot(tschirch_rate,
                          aes(x = cl_label, y = pct, fill = cluster)) +
  geom_col(width = 0.6, alpha = 0.85) +
  geom_text(aes(label = paste0(n_zit, "/", n_total, "\n(",
                               percent(pct, accuracy = 1), ")")),
            vjust = -0.3, size = 3.5) +
  scale_y_continuous(labels = percent, limits = c(0, 1.05)) +
  scale_fill_manual(values = CLUSTER_COLORS, guide = "none") +
  labs(x = NULL, y = "Anteil mit Tschirch-Zitation") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_tschirch_rate, "10_tschirch_zitation_cluster")

# --- 11: ZEITKONTEXT × CLUSTER ---
ztk_cross <- df_main |>
  filter(!is.na(zeitkontext_clean)) |>
  count(cluster, zeitkontext_clean) |>
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0)

if (nrow(ztk_cross) > 1) {
  ztk_mat  <- ztk_cross |> select(-zeitkontext_clean) |> as.matrix()
  rownames(ztk_mat) <- ztk_cross$zeitkontext_clean
  chi_ztk  <- chisq.test(ztk_mat, simulate.p.value = TRUE)
  cat(sprintf("Chi-Quadrat Zeitkontext × Cluster: p=%.4f\n", chi_ztk$p.value))
  ztk_p <- chi_ztk$p.value
} else {
  ztk_p <- NA
}

ztk_plot <- df_main |>
  filter(!is.na(zeitkontext_clean)) |>
  count(cluster, zeitkontext_clean) |>
  group_by(cluster) |>
  mutate(pct = n / sum(n),
         cl_label = paste0("Typ ", cluster))

p_zeitkontext <- ggplot(ztk_plot,
                        aes(x = cl_label, y = pct, fill = zeitkontext_clean)) +
  geom_col(position = "fill", width = 0.6) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = zeitkontext_farben, name = "Zeitkontext") +
  labs(x = NULL, y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_zeitkontext, "11_zeitkontext_cluster")

# --- 12: DEKADEN-VERTEILUNG NACH CLUSTER ---
# Zeigt ob bestimmte Typen eher früh oder spät entstanden
p_dekaden <- df_main |>
  mutate(dekade = floor(jahr / 10) * 10) |>
  count(cluster, dekade) |>
  group_by(dekade) |>
  mutate(pct = n / sum(n)) |>
  ggplot(aes(x = dekade, y = pct, fill = cluster)) +
  geom_col(position = "fill", width = 7) +
  geom_text(aes(label = ifelse(n >= 2, n, "")),
            position = position_fill(vjust = 0.5),
            size = 3, color = "white", fontface = "bold") +
  scale_y_continuous(labels = percent) +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  scale_fill_manual(values = CLUSTER_COLORS, name = "Cluster") +
  labs(x = "Dekade", y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_dekaden, "12_dekaden_cluster")

# --- 13: SEITENUMFANG × CLUSTER (Kruskal-Wallis) ---
kw_seiten <- kruskal.test(seiten_gesamt ~ cluster, data = df_main)
cat(sprintf("Kruskal-Wallis Seitenumfang × Cluster: H=%.2f, p=%.4f\n",
            kw_seiten$statistic, kw_seiten$p.value))

n_cl_seiten <- df_main |>
  filter(!is.na(seiten_gesamt)) |>
  group_by(cluster) |>
  summarise(n = n(), .groups = "drop")

p_seiten <- df_main |>
  filter(!is.na(seiten_gesamt)) |>
  left_join(n_cl_seiten, by = "cluster") |>
  mutate(cl_label = paste0("Typ ", cluster, "\n(n=", n, ")")) |>
  ggplot(aes(x = cl_label, y = seiten_gesamt, fill = cluster)) +
  geom_boxplot(width = 0.55, outlier.shape = 21, outlier.fill = "white",
               colour = "#555555", alpha = 0.8) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 23,
               fill = "white", colour = "black", size = 3) +
  scale_fill_manual(values = CLUSTER_COLORS, guide = "none") +
  labs(x = NULL, y = "Seitenanzahl gesamt") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.major.x = element_blank())

save_plot(p_seiten, "13_seitenumfang_cluster")

# --- 14: HERKUNFTSLAND × CLUSTER ---
hk_cross <- df_main |>
  filter(!is.na(herkunftsland)) |>
  filter(herkunftsland != "unbekannt") %>%
  count(cluster, herkunftsland) |>
  group_by(herkunftsland) |>
  mutate(hk_total = sum(n)) |>
  ungroup() |>
  filter(hk_total >= 3) |>  # nur Länder mit ≥3 Diss.
  group_by(herkunftsland) |>
  mutate(pct = n / sum(n),
         hk_label = paste0(herkunftsland, " (n=", hk_total, ")"),
         hk_label = fct_reorder(hk_label, hk_total, .desc = TRUE))

# Fisher's Exact (simuliert, da kleine Zellenzahlen)
hk_mat_raw <- df_main |>
  filter(!is.na(herkunftsland)) |>
  count(cluster, herkunftsland) |>
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0) |>
  select(-herkunftsland) |> as.matrix()

fisher_hk <- fisher.test(hk_mat_raw, simulate.p.value = TRUE, B = 10000)
cat(sprintf("Fisher's Exact Herkunftsland × Cluster (simuliert): p=%.4f\n",
            fisher_hk$p.value))

p_herkunft <- ggplot(hk_cross, aes(x = pct, y = hk_label, fill = cluster)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.85) +
  geom_text(aes(label = ifelse(n >= 2, n, "")),
            position = position_stack(vjust = 0.5),
            size = 3, color = "white", fontface = "bold") +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = CLUSTER_COLORS, name = "Cluster") +
  labs(x = "Anteil", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_herkunft, "14_herkunftsland_cluster", w = 12, h = 7)

# --- 15: KRUSKAL-WALLIS ÜBERSICHT (alle metrischen Variablen) ---
# Systematischer Test aller metrischen Variablen gegen Cluster-Zugehörigkeit
kw_vars <- list(
  "Anteil historisch (%)"        = df_main$anteil_hist_clean * 100,
  "Stellenwert (1–3)"            = as.numeric(as.character(df_main$sw_ord)),
  "Vor-19.-Jh.-Epochen"         = df_main$n_pre19,
  "Hist. Quellentypen"           = df_main$n_hist_quellen,
  "Hist. Personen"               = df_main$n_personen,
  "Gesamt-Epochen"               = df_main$n_epochen,
  "Seitenumfang gesamt"          = df_main$seiten_gesamt,
  "Erscheinungsjahr"             = df_main$jahr
)

kw_results <- map_dfr(names(kw_vars), function(nm) {
  vals <- kw_vars[[nm]]
  test <- kruskal.test(vals ~ df_main$cluster)
  tibble(
    variable = nm,
    H        = round(test$statistic, 2),
    df       = test$parameter,
    p_value  = test$p.value,
    signif   = case_when(
      test$p.value < 0.001 ~ "***",
      test$p.value < 0.01  ~ "**",
      test$p.value < 0.05  ~ "*",
      TRUE                 ~ "n.s."
    )
  )
})

cat("\n=== Kruskal-Wallis Ergebnisse ===\n")
print(kw_results)

p_kw <- ggplot(kw_results,
               aes(x = fct_reorder(variable, H), y = H,
                   fill = signif)) +
  geom_col(width = 0.65, alpha = 0.85) +
  geom_text(aes(label = paste0("H=", H, " (", signif, ")")),
            hjust = -0.1, size = 3.5) +
  geom_hline(yintercept = qchisq(0.95, df = 3), linetype = "dashed",
             color = "#C97B8A", linewidth = 0.8) +
  annotate("text", x = 0.6, y = qchisq(0.95, df = 3) + 0.5,
           label = "p = .05 Schwelle", hjust = 0, size = 3, color = "#C97B8A") +
  coord_flip() +
  scale_fill_manual(values = c("***" = "#C97B8A","**" = "#E8A87C",
                               "*"   = "#EBC46A","n.s." = "#C8C5CC"),
                    name = "Signifikanz") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = "H-Statistik (Kruskal-Wallis)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_kw, "15_kruskal_wallis_uebersicht", w = 12, h = 7)

# --- 16: WOZU DIENT GESCHICHTE X CLUSTER ---
# (ohne "kontextualisierend" — diese Funktion ist in ~96% aller Diss. kodiert
#  und überlagert die analytisch interessanten Unterschiede zwischen Clustern)

# df_wozu aufbauen: Cluster-Zuordnung + wozu_dient_geschichte aus df_main
df_wozu <- df_main |>
  select(id1, cluster, wozu_dient_geschichte)

wozu_long <- df_wozu |>
  filter(!is.na(wozu_dient_geschichte), wozu_dient_geschichte != "") |>
  mutate(funktion = str_split(wozu_dient_geschichte, ",")) |>
  unnest(funktion) |>
  mutate(wozulabel = str_trim(funktion)) |>
  filter(wozulabel %in% c("legitimierend", "kanonbildend",
                          "ornamental", "abgrenzend"),
         !is.na(cluster))

# Kontingenztafel Cluster × Funktion
wozu_cross <- wozu_long |>
  count(cluster, wozulabel) |>
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0)

wozu_mat <- wozu_cross |>
  select(-wozulabel) |>
  as.matrix()
rownames(wozu_mat) <- wozu_cross$wozulabel

chi_wozu <- chisq.test(wozu_mat, simulate.p.value = TRUE, B = 10000)
cat(sprintf(
  "Chi-Quadrat Wozu dient Geschichte × Cluster (ohne kontextualisierend): X² = %.3f, p = %.4f\n",
  as.numeric(chi_wozu$statistic), chi_wozu$p.value
))

wozu_long_plot <- wozu_long |>
  count(cluster, wozulabel, name = "n") |>
  group_by(cluster) |>
  mutate(pct = n / sum(n)) |>
  ungroup() |>
  mutate(wozulabel = factor(wozulabel,
                            levels = c("ornamental","abgrenzend",
                                       "kanonbildend","legitimierend")))

p_wozu_bar <- ggplot(wozu_long_plot,
                     aes(x = cluster, y = pct, fill = wozulabel)) +
  geom_col(width = 0.6, position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = funktion_farben, name = "Funktion") +
  guides(fill = guide_legend(reverse = TRUE)) +
  labs(x = "Cluster", y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_wozu_bar, "16_wozu_cluster_balken", w = 10, h = 6)


# --- 17: ÜBERSICHTSMATRIX: Cluster × alle kategorialen Variablen ---
# Heatmap der standardisierten Residuen aus Chi-Quadrat-Tests

make_residuals <- function(var_long, var_name) {
  cross <- var_long |>
    filter(!is.na(cluster), !is.na(value)) |>
    count(cluster, value) |>
    pivot_wider(names_from = cluster, values_from = n, values_fill = 0) |>
    column_to_rownames("value") |>
    as.matrix()
  
  if (nrow(cross) < 2) return(NULL)
  
  ct <- suppressWarnings(chisq.test(cross))
  std_res <- as.data.frame(ct$stdres) |>
    rownames_to_column("category") |>
    pivot_longer(-category, names_to = "cluster", values_to = "std_res") |>
    mutate(variable = var_name)
  
  return(std_res)
}

cat_data <- bind_rows(
  make_residuals(
    register_long |> rename(value = register),
    "Sprachregister"
  ),
  make_residuals(
    narrativ_long |> rename(value = narrative),
    "Narrative Form"
  ),
  make_residuals(
    wozu_long |> rename(value = wozulabel) |> select(cluster, value),
    "Wozu dient Geschichte"
  )
)

if (!is.null(cat_data) && nrow(cat_data) > 0) {
  
  cat_data <- cat_data |>
    mutate(cluster = factor(cluster, levels = c("A","B","C","D")))
  
  order_wozu     <- c("legitimierend","kanonbildend","ornamental","abgrenzend")
  order_register <- c("autoritativ-kanonisch","deskriptiv-neutral",
                      "wertend-kritisch","wertend-positiv")
  order_narrativ <- c("chronologisch","personenzentriert",
                      "teleologisch","thematisch-systematisch")
  
  all_levels <- c(order_wozu, order_register, order_narrativ)
  
  cat_data <- cat_data |>
    mutate(category = factor(category, levels = all_levels))
  
  p_residuals <- ggplot(cat_data,
                        aes(x = cluster, y = category, fill = std_res)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%.1f", std_res),
                  color = abs(std_res) > 1.5), size = 3.2) +
    scale_fill_gradient2(low = "#B0C4DE", mid = "white", high = "#C97B8A",
                         midpoint = 0, name = "Std.\nResiduum",
                         limits = c(-4, 4), oob = scales::squish) +
    scale_color_manual(values = c("FALSE" = "#999999","TRUE" = "#111111"),
                       guide = "none") +
    facet_wrap(~variable, scales = "free_y", ncol = 1) +
    labs(x = "Cluster", y = NULL) +
    theme_minimal(base_size = 11) +
    theme(plot.title    = element_text(face = "bold"),
          panel.grid    = element_blank(),
          strip.text    = element_text(face = "bold", size = 10),
          axis.text.y   = element_text(size = 9))
  
  save_plot(p_residuals, "17_standardisierte_residuen", w = 10, h = 11)
}

# --- 18: STOFFKLASSEN NACH CLUSTER (Chi-Quadrat / Fisher) ---

# Kreuztabelle Stoffklasse × Cluster
stoff_tab <- table(df_main$stoffklasse, df_main$cluster)

# Überblick ausgeben
cat("\n=== Stoffklassen × Cluster ===\n")
print(stoff_tab)

# Erster Versuch: Chi-Quadrat-Test
stoff_chisq <- suppressWarnings(chisq.test(stoff_tab))
cat(sprintf("Chi-Quadrat Stoffklasse × Cluster: X²=%.2f, df=%d, p=%.4f\n",
            stoff_chisq$statistic, stoff_chisq$parameter, stoff_chisq$p.value))

# Falls viele kleine Zellen: simulierten Fisher-Test ergänzen
stoff_fisher <- fisher.test(stoff_tab, simulate.p.value = TRUE, B = 10000)
cat(sprintf("Fisher's Exact Stoffklasse × Cluster (simuliert): p=%.4f\n",
            stoff_fisher$p.value))

# Für die Visualisierung: nur Stoffklassen mit >= 3 Dissertationen anzeigen
stoff_long <- df_main |>
  count(stoffklasse, cluster, name = "n") |>
  group_by(stoffklasse) |>
  mutate(total = sum(n)) |>
  ungroup() |>
  filter(total >= 3)

stoff_cross <- stoff_long |>
  group_by(stoffklasse) |>
  mutate(pct = n / sum(n)) |>
  ungroup()

p_stoff <- ggplot(stoff_cross,
                  aes(x = pct, y = reorder(stoffklasse, total),
                      fill = cluster)) +
  geom_col(width = 0.7, alpha = 0.85, position = "stack") +
  geom_text(aes(label = ifelse(n >= 2, n, "")),
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 3) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = CLUSTER_COLORS, name = "Cluster") +
  labs(x = "Anteil", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_stoff, "18_stoffklasse_cluster", w = 12, h = 7)

# --- 19: EXPLIZITE UNTERSUCHUNGSGEGENSTÄNDE NACH CLUSTER ---

# Nur Fälle mit kodiertem Untersuchungsgegenstand
df_gg <- df_main |>
  filter(!is.na(untersuchungsgegenstand) & untersuchungsgegenstand != "")

gg_tab <- table(df_gg$untersuchungsgegenstand, df_gg$cluster)

cat("\n=== Untersuchungsgegenstand × Cluster ===\n")
print(gg_tab)

# Wegen vieler seltener Gegenstände direkt simulierten Fisher-Test verwenden
gg_fisher <- fisher.test(gg_tab, simulate.p.value = TRUE, B = 10000)
cat(sprintf("Fisher's Exact Untersuchungsgegenstand × Cluster (simuliert): p=%.4f\n",
            gg_fisher$p.value))

# Für die Visualisierung: nur Gegenstände mit >= 3 Dissertationen anzeigen
gg_long <- df_gg |>
  count(untersuchungsgegenstand, cluster, name = "n") |>
  group_by(untersuchungsgegenstand) |>
  mutate(total = sum(n)) |>
  ungroup() |>
  filter(total >= 3)

gg_cross <- gg_long |>
  group_by(untersuchungsgegenstand) |>
  mutate(pct = n / sum(n)) |>
  ungroup()

p_gg <- ggplot(gg_cross,
               aes(x = pct, y = reorder(untersuchungsgegenstand, total),
                   fill = cluster)) +
  geom_col(width = 0.7, alpha = 0.85, position = "stack") +
  geom_text(aes(label = ifelse(n >= 2, n, "")),
            position = position_stack(vjust = 0.5),
            color = "white", fontface = "bold", size = 3) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = CLUSTER_COLORS, name = "Cluster") +
  labs(x = "Anteil", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_gg, "19_untersuchungsgegenstand_cluster", w = 12, h = 7)


# ============================================================
# 5. EXPORT
# ============================================================

df_export <- df_main |>
  select(id1, nachname, vorname, jahr, titel, stoffklasse,
         cluster, historie_stellenwert_skala,
         anteil_hist_clean, n_pre19, n_hist_quellen, n_personen,
         herkunftsland, zeitkontext_clean, sprachregister, narrative_form) |>
  arrange(cluster, jahr)

write_csv(df_export, file.path(OUT_DIR, "cluster_zuordnung_v2.csv"))

cat("\n=== Alle Tests abgeschlossen ===\n")
cat("Signifikante Ergebnisse (p < .05):\n")
print(kw_results |> filter(p_value < 0.05) |> select(variable, H, p_value, signif))

# Plot-Objekte für Panel-Komposition speichern
saveRDS(
  list(
    p_sw   = p_sw,
    p_ant  = p_ant,
    p_ep   = p_ep
  ),
  "output_cluster_v2/plots_cluster.rds"
)

message(sprintf("\n✓ Alle Abbildungen gespeichert in /%s (19 Dateien)", OUT_DIR))