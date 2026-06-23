# ============================================================
# TSCHIRCH-DISSERTATIONEN: HAUPTAUSWERTUNG
# ============================================================

library(tidyverse)
library(ggplot2)
library(scales)
library(igraph)
library(ggraph)
library(tidygraph)
library(patchwork)

# ============================================================
# PFADE  –  vor dem Ausfuehren ggf. BASE_DIR anpassen
# ============================================================
# Alle CSV-Dateien werden relativ zu BASE_DIR im Unterordner csv_daten/
# erwartet. Standardmaessig wird das Arbeitsverzeichnis von R verwendet
# (getwd()). Wer die Daten woanders liegen hat, setzt BASE_DIR einmalig
# auf den entsprechenden Ordner, z. B.:
#   BASE_DIR <- "C:/Users/hanna/Masterarbeit/auswertung"
BASE_DIR  <- getwd()
CSV_DIR   <- file.path(BASE_DIR, "csv_daten")

CSV_HIST     <- file.path(CSV_DIR,
  "Getting Started - diss_tschirch (diss_tschirch_historisch) 2026-04-14_16-57.csv")
CSV_ALL      <- file.path(CSV_DIR,
  "Getting Started - diss_tschirch (diss_tschirch_gesamtkorpus) 2026-04-15_10-36.csv")
CSV_PERSREF  <- file.path(CSV_DIR,
  "Getting Started - tschirch_top_personen (tschirch_top_personen) 2026-04-15_10-36.csv")
CSV_CLUSTER  <- file.path(CSV_DIR,
  "Getting Started - cluster_zuordnung (cluster_zuordnung) 2026-04-15_10-36.csv")

# ============================================================
# FARBSYSTEM
# ============================================================

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

# Narrative Formen – neutrale Grundfarben für ordnende Formen,
# Akzent für ideologisch aufgeladene
narrativ_farben <- c(
  "thematisch-systematisch" = "#A8C5E0",   # Hellblau (sachlich-ordnend)
  "chronologisch"           = "#D8C8E8",   # Lavendelblau (zeitlich-ordnend)
  "personenzentriert"       = "#E8A0B4",   # Rosa (heroisierend)
  "teleologisch"            = "#C8D48C"    # Gelbgrün (Fortschritt)
)

# Sprachregister – Wertungs-Kontinuum grün ↔ neutral ↔ orange,
# autoritativ als eigene Dimension
sprachregister_farben <- c(
  "wertend-positiv"       = "#A8C5A0",   # Salbeigrün
  "deskriptiv-neutral"    = "#E1DEDA",   # Warmgrau (echte Neutralität)
  "wertend-kritisch"      = "#F0BC82",   # Orange
  "autoritativ-kanonisch" = "#C4A8D4"    # Lavendel (eigene Dimension)
)

# Funktionen – konstruktiv-traditionsbildend vs. weniger substanziell
funktion_farben <- c(
  "legitimierend" = "#7DB8B0",   # Petrol (konstruktiv, stark)
  "kanonbildend"  = "#E8C870",   # Goldgelb (traditionsbildend)
  "ornamental"    = "#D4A8A0",   # Altrosa (schmückend, schwach)
  "abgrenzend"    = "#D78663"    # Terrakotta (distanzierend, bestimmt)
)

# ============================================================
# HILFSFUNKTIONEN
# ============================================================

# Checkbox: '', 'false', NA alle → FALSE
as_bool <- function(x) {
  x_lower <- tolower(trimws(as.character(x)))
  case_when(
    x_lower == "true"  ~ TRUE,
    x_lower == "false" ~ FALSE,
    TRUE               ~ FALSE   # NA, leer, alles andere → FALSE
  )
}

epochen_map <- c(
  "Anfang 19. Jahrhundert"   = "19. Jahrhundert",
  "Mitte 19. Jahrhundert"    = "19. Jahrhundert",
  "Ende 19. Jahrhundert"     = "19. Jahrhundert",
  "Übergang 19. Jahrhundert" = "19. Jahrhundert",
  "Gesamtes 19. Jahrhundert" = "19. Jahrhundert",
  "Frühmittelalter"          = "Mittelalter",
  "Frühgeschichte"           = "Mythisch / Frühgeschichte",
  "Anfang 20.. Jahrhundert"  = "Frühes 20. Jahrhundert"
)

epochen_levels <- c(
  "Mythisch / Frühgeschichte",
  "Altertum",
  "Mittelalter",
  "Frühe Neuzeit",
  "19. Jahrhundert",
  "Frühes 20. Jahrhundert"
)

# Zeitkontext bereinigen: "1. Weltkrieg,Russische Revolution" → "1. Weltkrieg"
clean_zeitkontext <- function(x) {
  case_when(
    str_detect(x, "Russische Revolution") ~ "1. Weltkrieg",
    x %in% c("1. Weltkrieg","Hochimperialismus","Zwischenkriegszeit") ~ x,
    TRUE ~ NA_character_
  )
}

save_plot <- function(p, name, w = 12, h = 7) {
  ggsave(file.path("output6", paste0(name, ".png")),
         plot = p, width = w, height = h, dpi = 300, bg = "white")
  message("✓ ", name)
}

dir.create("output6", showWarnings = FALSE)

# ============================================================
# DATEN LADEN  –  Pfade anpassen
# ============================================================

df_hist_raw <- read_csv(CSV_HIST, show_col_types = FALSE)
names(df_hist_raw)[1] <- "id1"

df_all_raw <- read_csv(CSV_ALL, show_col_types = FALSE)
names(df_all_raw)[1] <- "id1"

df_personen_ref <- read_csv(CSV_PERSREF, show_col_types = FALSE) %>%
  mutate(
    person = str_trim(person),
    person = recode(person,
                    "Jöns Jakob Berzellius" = "Jöns Jakob Berzelius",
                    "Berzellius" = "Berzelius",
                    "Avicenna (Ibn Sina)"   = "Avicenna"
    )
  )

df_cluster_ref <- read_csv(CSV_CLUSTER, show_col_types = FALSE)
names(df_cluster_ref)[1] <- "id1"

hist_typen <- c(
  "Historische Sekundärquellen","Historische Wissensliteratur",
  "Historische Akten","Pharmakohistoria","Arzneibuch",
  "botanisches Systematikwerk","Reiseberichte","Kräuterbuch","Religiöse Schriften"
)

# ============================================================
# AUFBEREITUNG
# ============================================================

df <- df_hist_raw %>%
  mutate(
    dekade        = floor(jahr / 10) * 10,
    anteil_pct    = as.numeric(anteil_historisch) * 100,
    skala_f       = factor(historie_stellenwert_skala, levels = 1:3,
                           labels = c("1 – gering","2 – mittel","3 – zentral")),
    einleitung    = as_bool(historische_einleitung_vorhanden),
    tschirch_zit  = as_bool(zitiert_tschirch),
    zeitkontext_clean = clean_zeitkontext(zaesuren_zeitkontext)
  ) %>%
  left_join(df_cluster_ref %>% select(id1, cluster), by = "id1") %>%
  mutate(
    cluster = factor(cluster, levels = c("A","B","C","D")),
    zeitkontext_clean = factor(
      zeitkontext_clean,
      levels = c("Hochimperialismus", "1. Weltkrieg", "Zwischenkriegszeit")
    )
  )
  
df_all <- df_all_raw %>%
  mutate(einleitung = as_bool(historische_einleitung_vorhanden))

# Epochen
df_epochen <- df %>%
  filter(!is.na(vorkommende_epochen), vorkommende_epochen != "") %>%
  mutate(epoche_list = strsplit(vorkommende_epochen, ",")) %>%
  unnest(epoche_list) %>%
  mutate(
    epoche = str_trim(epoche_list),
    epoche = recode(epoche, !!!epochen_map, .default = epoche)
  ) %>%
  filter(!is.na(epoche), epoche != "", epoche != "nicht definiert", epoche != "NA") %>%
  mutate(epoche = factor(epoche, levels = epochen_levels))

# Personen
df_personen <- df %>%
  filter(!is.na(wichtige_historische_personen_im_text),
         wichtige_historische_personen_im_text != "") %>%
  mutate(person_list = strsplit(wichtige_historische_personen_im_text, ",")) %>%
  unnest(person_list) %>%
  mutate(person = str_trim(person_list)) %>%
  mutate(
    person = case_when(
      person == "Jöns Jakob Berzellius" ~ "Jöns Jakob Berzelius",
      person == "Berzellius"            ~ "Berzelius",
      person == "Avicenna (Ibn Sina)"   ~ "Avicenna",
      TRUE ~ person
    )) %>%
  filter(person != "") %>%
  left_join(df_personen_ref %>% select(person, tradition, nennungen), by = "person")

df_wozu <- df %>%
  filter(!is.na(wozu_dient_geschichte), wozu_dient_geschichte != "") %>%
  mutate(wozu_list = strsplit(wozu_dient_geschichte, ",")) %>%
  unnest(wozu_list) %>%
  mutate(wozu = str_trim(wozu_list)) %>%
  filter(wozu != "", wozu != "kontextualisierend")

df_narrativ <- df %>%
  filter(!is.na(narrative_form), narrative_form != "") %>%
  mutate(form_list = strsplit(narrative_form, ",")) %>%
  unnest(form_list) %>%
  mutate(narrative = str_trim(form_list)) %>%
  filter(narrative != "")

df_register <- df %>%
  filter(!is.na(sprachregister), sprachregister != "") %>%
  mutate(reg_list = strsplit(sprachregister, ",")) %>%
  unnest(reg_list) %>%
  mutate(register = str_trim(reg_list)) %>%
  filter(register != "")

df_fokus <- df %>%
  filter(!is.na(fokus_historischer_teil), fokus_historischer_teil != "") %>%
  mutate(fok_list = strsplit(fokus_historischer_teil, ",")) %>%
  unnest(fok_list) %>%
  mutate(fokus = str_trim(fok_list)) %>%
  filter(fokus != "")

df_quellen <- df %>%
  filter(!is.na(quellentypen), quellentypen != "") %>%
  mutate(q_list = strsplit(quellentypen, ",")) %>%
  unnest(q_list) %>%
  mutate(quellentyp = str_trim(q_list)) %>%
  filter(quellentyp != "")

df_tschirch_werke <- df %>%
  filter(!is.na(tschirch_werke), tschirch_werke != "") %>%
  mutate(werk_list = strsplit(tschirch_werke, ",")) %>%
  unnest(werk_list) %>%
  mutate(werk = str_trim(werk_list)) %>%
  filter(werk != "")

# ============================================================
# ============================================================

## 1a – Donut Gesamtkorpus
d_donut <- df_all %>%
  mutate(label = case_when(
    einleitung == TRUE  ~ "Mit hist. Einleitung",
    einleitung == FALSE | einleitung == "" | is.na(einleitung) ~ "Ohne hist. Einleitung",
  )) %>%
  filter(!is.na(label)) %>%
  count(label) %>%
  mutate(pct = n / sum(n))

p_donut <- ggplot(d_donut, aes(x = 2, y = n, fill = label)) +
  geom_col(width = 1, color = "white", linewidth = 0.8) +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) +
  scale_fill_manual(values = c(
    "Mit hist. Einleitung"  = "#C397C1",
    "Ohne hist. Einleitung" = "#E1DEDA"
  )) +
  geom_text(aes(label = paste0(label, "\n", n, " (", percent(pct, accuracy = 1), ")")),
            position = position_stack(vjust = 0.5), size = 4.2) +
  theme_void(base_size = 13) +
  theme(legend.position = "none",
        plot.title    = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, color = "#555555"))

save_plot(p_donut, "donut_verbreitung")

## 1b – Balken Stellenwert
p_bar <- df %>%
  filter(!is.na(skala_f)) %>%
  count(skala_f) %>%
  ggplot(aes(x = skala_f, y = n, fill = skala_f)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = n), vjust = -0.5, size = 4.5) +
  scale_fill_manual(values = stellenwert_farben) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(x = "Stellenwert", y = "Anzahl Dissertationen") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_bar, "balken_stellenwert")

## 1c – Boxplot Anteil × Stellenwert
n_stellenwert <- df %>% filter(!is.na(skala_f), !is.na(anteil_pct)) %>%
  count(skala_f) %>% mutate(label = paste0("n=", n))

p_box_stellenwert <- df %>%
  filter(!is.na(skala_f), !is.na(anteil_pct)) %>%
  ggplot(aes(x = skala_f, y = anteil_pct, fill = skala_f)) +
  geom_boxplot(alpha = 0.75, outlier.shape = 21, outlier.fill = "white") +
  geom_jitter(width = 0.15, alpha = 0.35, size = 1.5) +
  geom_text(data = n_stellenwert, aes(x = skala_f, y = -2.5, label = label),
            size = 3.5, color = "#555555") +
  scale_fill_manual(values = stellenwert_farben) +
  labs(x = "Stellenwert (Skala)", y = "Anteil historischer Teil (%)") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_box_stellenwert, "boxplot_stellenwert_anteil")

# ============================================================
# ============================================================

## 2a – Anteil historisch im Zeitverlauf
d_dekade_anteil <- df %>%
  filter(!is.na(anteil_pct)) %>%
  group_by(dekade) %>%
  summarise(n = n(), mean_ant = mean(anteil_pct), median_ant = median(anteil_pct),
            .groups = "drop")

p_anteil <- ggplot(d_dekade_anteil, aes(x = dekade)) +
  geom_col(aes(y = mean_ant), fill = "#A8C5E0", alpha = 0.5, width = 8) +
  geom_line(aes(y = mean_ant), color = "#7FB6B2", linewidth = 1.3) +
  geom_point(aes(y = mean_ant), color = "#7FB6B2", size = 3) +
  geom_line(aes(y = median_ant), color = "#E8A87C", linewidth = 0.9, linetype = "dashed") +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  labs(x = "Dekade", y = "Ø Anteil historischer Teil (%)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_anteil, "linie_anteil_zeitverlauf")

## 2b – Absolute Verteilung nach Dekade (Gesamtkorpus)
d_dekade_abs <- df_all %>%
  filter(!is.na(einleitung)) %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  count(dekade, einleitung) %>%
  mutate(label = ifelse(einleitung, "Mit hist. Einleitung", "Ohne hist. Einleitung"))

p_abs <- ggplot(d_dekade_abs, aes(x = dekade, y = n, fill = label)) +
  geom_col(position = "stack", width = 8) +
  geom_text(aes(label = n), position = position_stack(vjust = 0.5),
            size = 3.2, color = "white", fontface = "bold") +
  scale_fill_manual(values = c("Mit hist. Einleitung" = "#C397C1",
                                "Ohne hist. Einleitung" = "#E1DEDA"), name = NULL) +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  labs(x = "Dekade", y = "Anzahl Dissertationen") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

save_plot(p_abs, "abs_verteilung_dekade")

## 2c – Heatmap Epochen nach Dekade (zeilen-normalisiert: Peak-Analyse)
d_epochen_heat <- df_epochen %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  count(dekade, epoche) %>%
  complete(dekade, epoche, fill = list(n = 0)) %>%
  group_by(epoche) %>%
  mutate(
    anteil_zeile = n / sum(n),
    n_epoche_total = sum(n)
  ) %>%
  ungroup() %>%
  mutate(
    epoche_lbl = paste0(epoche, "\n(n=", n_epoche_total, ")"),
    epoche_lbl = factor(epoche_lbl,
                        levels = paste0(epochen_levels, "\n(n=",
                                        sapply(epochen_levels, function(e)
                                          sum(.$n[.$epoche == e])), ")"))
  )

# Faktor-Levels sauber setzen (der inline-Ansatz oben ist fragil)
lvl_order <- df_epochen %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  count(epoche) %>%
  right_join(tibble(epoche = epochen_levels), by = "epoche") %>%
  mutate(n = replace_na(n, 0),
         lbl = paste0(epoche, "\n(n=", n, ")")) %>%
  pull(lbl)

d_epochen_heat <- d_epochen_heat %>%
  mutate(epoche_lbl = factor(paste0(epoche, "\n(n=", n_epoche_total, ")"),
                             levels = lvl_order))

p_heatmap <- ggplot(d_epochen_heat,
                        aes(x = dekade, y = fct_rev(epoche_lbl), fill = anteil_zeile)) +
  geom_tile(color = "white", linewidth = 0.6) +
  geom_text(aes(label = ifelse(n > 0,
                               paste0(percent(anteil_zeile, accuracy = 1),
                                      "\n(", n, ")"),
                               "")),
            size = 2.9, lineheight = 0.9,
            color = ifelse(d_epochen_heat$anteil_zeile > 0.35, "white", "#333333")) +
  scale_fill_gradient(
    low  = "#EDF5F1",
    high = "#5F8F87",
    name = "Anteil\n(zeilenweise)",
    labels = percent,
    limits = c(0, NA)) +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  labs(x = "Dekade", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold")) +
  theme(
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank()
  )

save_plot(p_heatmap, "heatmap_epochen_dekade", w = 13, h = 6)

## 2d – Stellenwert nach Zeitkontext (bereinigt: RR → 1. WK)
p_ztk_stellenwert <- df %>%
  filter(!is.na(zeitkontext_clean), !is.na(skala_f)) %>%
  count(zeitkontext_clean, skala_f) %>%
  group_by(zeitkontext_clean) %>%
  mutate(pct = n / sum(n), total = sum(n),
         ztk_label = paste0(zeitkontext_clean, "\n(n=", total, ")"),
         ztk_label = factor(ztk_label,
                            levels = unique(ztk_label[order(match(
                              zeitkontext_clean,
                              c("Hochimperialismus","1. Weltkrieg","Zwischenkriegszeit")))]))) %>%
  ggplot(aes(x = ztk_label, y = pct, fill = skala_f)) +
  geom_col(position = "fill", width = 0.55) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = stellenwert_farben, name = "Stellenwert") +
  labs(x = NULL, y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_ztk_stellenwert, "stellenwert_zeitkontext")

# ============================================================
# EPOCHEN UND PERSONEN
# ============================================================

## 3a – Epochen-Ranking (chronologisch sortiert)
p_epochen <- df_epochen %>%
  count(epoche) %>%
  # Reihenfolge: chronologisch (Faktor-Levels), Balken nach Länge INNERHALB dieser Logik
  mutate(epoche = factor(epoche, levels = rev(epochen_levels))) %>%
  ggplot(aes(x = n, y = epoche, fill = epoche)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = n), hjust = -0.3, size = 4) +
  scale_fill_manual(values = epochen_farben) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_epochen, "epochen_ranking")

## 3b – Alle Personen (Lollipop mit Tradition)
p_alle_personen <- df_personen_ref %>%
  filter(!is.na(tradition)) %>%
  mutate(person = fct_reorder(person, nennungen)) %>%
  ggplot(aes(x = nennungen, y = person, color = tradition)) +
  geom_segment(aes(x = 0, xend = nennungen, yend = person),
               color = "#DDDDDD", linewidth = 0.7) +
  geom_point(size = 6) +
  geom_text(aes(label = nennungen), hjust = -0.6, size = 5, color = "#333333") +
  scale_color_manual(values = tradition_farben, name = "Tradition") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 9) +
  theme(plot.title = element_text(face = "bold"), legend.position = "right",
        legend.text = element_text(size = 8), axis.text.y = element_text(size = 7))

save_plot(p_alle_personen, "alle_personen_tradition", w = 15, h = 14)

## 3c – Kanonstabilität Top 25 (erweitert von 15)
top25_kanon <- df_personen %>% count(person, sort = TRUE) %>%
  slice_head(n = 25) %>% pull(person)

d_kanon <- df_personen %>%
  filter(person %in% top25_kanon) %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  count(person, dekade) %>%
  left_join(df_personen_ref %>% select(person, tradition), by = "person") %>%
  mutate(tradition = replace_na(tradition, "Nicht zugeordnet"))

p_kanon <- ggplot(d_kanon,
                      aes(x = dekade, y = fct_reorder(person, n, sum),
                          size = n, color = tradition)) +
  geom_point(alpha = 0.85) +
  scale_size_continuous(range = c(2, 12), name = "Nennungen") +
  scale_color_manual(values = c(tradition_farben, "Nicht zugeordnet" = "#AAAAAA"),
                     name = "Tradition") +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  labs(x = "Dekade", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_kanon, "kanonstabilitaet_top25", w = 14, h = 9)

## 3d – Autoritäten × Stoffklassen Heatmap (NEU / wieder eingebaut)
top30_pers <- df_personen %>% count(person, sort = TRUE) %>%
  slice_head(n = 30) %>% pull(person)

heatmap_data <- df_personen %>%
  filter(person %in% top30_pers,
         !is.na(stoffklasse), stoffklasse != "") %>%
  count(person, stoffklasse) %>%
  # Person-Reihenfolge: nach Gesamtnennungen
  left_join(df_personen %>% count(person, name = "total"), by = "person") %>%
  mutate(person = fct_reorder(person, total))

p_heatmap_pers <- ggplot(heatmap_data,
                              aes(x = stoffklasse, y = person, fill = n)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = ifelse(n > 0, n, "")), size = 2.8,
            color = ifelse(heatmap_data$n >= 5, "white", "#333333")) +
  scale_fill_gradient(
    low  = "#EDF5F1",
    high = "#5F8F87",
    name = "Nennungen", na.value = "white") +
  labs(x = "Stoffklasse", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title    = element_text(face = "bold"),
        panel.grid    = element_blank(),
        axis.text.x   = element_text(angle = 35, hjust = 1, size = 9),
        axis.text.y   = element_text(size = 8))

save_plot(p_heatmap_pers, "heatmap_autoritaeten_stoffklassen",
          w = 15, h = 11)

## 3e – Ko-Präsenznetzwerk
top20_netz <- df_personen %>% count(person, sort = TRUE) %>%
  slice_head(n = 20) %>% pull(person)

netz_edges <- df_personen %>%
  filter(person %in% top20_netz) %>% select(id1, person) %>%
  inner_join(df_personen %>% filter(person %in% top20_netz) %>%
               select(id1, person2 = person), by = "id1") %>%
  filter(person < person2) %>%
  count(person, person2, name = "weight") %>%
  filter(weight >= 3)

netz_nodes <- data.frame(person = top20_netz) %>%
  left_join(df_personen_ref %>% select(person, tradition), by = "person") %>%
  mutate(tradition = replace_na(tradition, "Nicht zugeordnet"))

if (nrow(netz_edges) > 0) {
  g  <- graph_from_data_frame(netz_edges, directed = FALSE, vertices = netz_nodes)
  tg <- as_tbl_graph(g) %>% activate(nodes) %>%
    mutate(grad = centrality_degree(weights = weight))
  tg_plot <- tg %>% 
    activate(nodes) %>% 
    filter(grad > 0)

  p_netz <- ggraph(tg_plot, layout = "fr", niter = 3000) +
    geom_edge_link(aes(width = weight), color = "#DDDDDD", alpha = 0.8) +
    geom_node_point(aes(color = tradition, size = grad)) +
    geom_node_text(aes(label = name), repel = TRUE, size = 2.6,
                   max.overlaps = 12, color = "#333333") +
    scale_edge_width_continuous(range = c(0.5, 3), name = "Ko-Präsenz") +
    scale_color_manual(values = c(tradition_farben, "Nicht zugeordnet" = "#AAAAAA"),
                       name = "Tradition") +
    scale_size_continuous(range = c(3, 9), guide = "none") +
    theme_graph(base_size = 12) +
    theme(plot.title = element_text(face = "bold"))

  save_plot(p_netz, "netzwerk_kopraesenz", w = 13, h = 9)
}

# ============================================================
# STOFFKLASSE
# ============================================================

## Gemeinsame Sortierreihenfolge (alphabetisch)
stoff_order <- df %>%
  filter(!is.na(stoffklasse), stoffklasse != "Sonstige") %>%
  distinct(stoffklasse) %>%
  arrange(desc(stoffklasse)) %>%   # desc, damit A oben im Plot landet
  pull(stoffklasse)

## Labels mit n (für beide Plots gemeinsam)
n_stoff <- df %>% filter(!is.na(stoffklasse), stoffklasse != "Sonstige") %>%
  count(stoffklasse)
n_stoff_vec <- setNames(n_stoff$n, n_stoff$stoffklasse)

stoff_lbl_order <- paste0(stoff_order, " (n=", n_stoff_vec[stoff_order], ")")

## 4a – Boxplot Stoffklasse
p_box_stoffklasse <- df %>%
  filter(!is.na(stoffklasse), stoffklasse != "Sonstige", !is.na(anteil_pct)) %>%
  mutate(stoff_n   = n_stoff_vec[stoffklasse],
         stoff_lbl = paste0(stoffklasse, " (n=", stoff_n, ")"),
         stoff_lbl = factor(stoff_lbl, levels = stoff_lbl_order)) %>%
  ggplot(aes(x = anteil_pct, y = stoff_lbl, fill = stoffklasse)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21) +
  geom_jitter(height = 0.15, alpha = 0.35, size = 1.5) +
  scale_fill_manual(values = stoff_farben_fix) +
  labs(x = "Anteil historischer Teil (%)", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_box_stoffklasse, "boxplot_stoffklasse", w = 12, h = 8)

## 4b – Stellenwert nach Stoffklasse
p_kreuz_stoffklasse <- df %>%
  filter(!is.na(stoffklasse), stoffklasse != "Sonstige", !is.na(skala_f)) %>%
  count(stoffklasse, skala_f) %>%
  group_by(stoffklasse) %>%
  mutate(pct = n / sum(n), total = sum(n),
         lbl = paste0(stoffklasse, " (n=", total, ")"),
         lbl = factor(lbl, levels = stoff_lbl_order)) %>%
  ggplot(aes(x = pct, y = lbl, fill = skala_f)) +
  geom_col(position = "stack", width = 0.65) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = stellenwert_farben, name = "Stellenwert") +
  labs(x = "Anteil", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold")) +
  theme(
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank()
  )

save_plot(p_kreuz_stoffklasse, "stellenwert_stoffklasse", w = 12, h = 7)

# ============================================================
# HERKUNFTSLAND
# ============================================================

hk_mindest <- df %>% count(herkunftsland) %>% filter(n >= 3) %>% pull(herkunftsland)
n_hk <- df %>% filter(herkunftsland %in% hk_mindest) %>%
  count(herkunftsland, name = "n_total")

## 5a – Boxplot historischer Anteil
p_box_herkunft <- df %>%
  filter(herkunftsland %in% hk_mindest, !is.na(anteil_pct)) %>%
  left_join(n_hk, by = "herkunftsland") %>%
  mutate(hk_lbl = paste0(herkunftsland, " (n=", n_total, ")"),
         hk_lbl = fct_reorder(hk_lbl, anteil_pct, median)) %>%
  ggplot(aes(x = anteil_pct, y = hk_lbl, fill = herkunftsland)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21) +
  geom_jitter(height = 0.15, alpha = 0.35, size = 1.5) +
  scale_fill_manual(values = hk_farben_fix) +
  labs(x = "Anteil historischer Teil (%)", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_box_herkunft, "boxplot_herkunft", w = 12, h = 7)

## 5b – Stellenwert nach Herkunftsland
p_kreuz_herkunft <- df %>%
  filter(herkunftsland %in% hk_mindest, !is.na(skala_f)) %>%
  count(herkunftsland, skala_f) %>%
  group_by(herkunftsland) %>%
  mutate(pct = n / sum(n), total = sum(n),
         lbl = paste0(herkunftsland, " (n=", total, ")")) %>%
  ggplot(aes(x = pct, y = fct_reorder(lbl, pct), fill = skala_f)) +
  geom_col(position = "stack", width = 0.65) +
  scale_x_continuous(labels = percent) +
  scale_fill_manual(values = stellenwert_farben, name = "Stellenwert") +
  labs(x = "Anteil", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_kreuz_herkunft, "stellenwert_herkunft", w = 12, h = 7)

## 5c – Anteil mit historischer Einleitung (aus Gesamtkorpus, proportional)
## Dies entspricht Bild 1 (Balkenbreite proportional zu n, Durchschnittslinie)
d_herkunft_anteil <- df_all %>%
  filter(!is.na(einleitung), !is.na(herkunftsland)) %>%
  group_by(herkunftsland) %>%
  summarise(n_total = n(), n_hist = sum(einleitung),
            pct_hist = n_hist / n_total, .groups = "drop") %>%
  filter(n_total >= 3) %>%
  mutate(lbl     = paste0(herkunftsland, "\n(n=", n_total, ")"),
         lbl     = fct_reorder(lbl, pct_hist),
         hk_fill = herkunftsland)

durchschnitt <- sum(d_herkunft_anteil$n_hist) / sum(d_herkunft_anteil$n_total)

p_einleitung <- ggplot(d_herkunft_anteil,
                            aes(x = pct_hist, y = lbl, fill = hk_fill,
                                linewidth = n_total)) +
  geom_col(aes(width = scales::rescale(n_total, to = c(0.3, 0.85))),
           alpha = 0.85) +
  geom_text(aes(label = paste0(percent(pct_hist, accuracy = 1),
                                " (", n_hist, "/", n_total, ")")),
            hjust = -0.08, size = 3.3, color = "#333333") +
  geom_vline(xintercept = durchschnitt, linetype = "dashed",
             color = "#555555", linewidth = 0.8) +
  annotate("text", x = durchschnitt + 0.01, y = 0.5,
           label = paste0("Ø ", percent(durchschnitt, accuracy = 1)),
           hjust = 0, size = 3.2, color = "#555555") +
  scale_x_continuous(labels = percent, expand = expansion(mult = c(0, 0.2)),
                     limits = c(0, 1)) +
  scale_fill_manual(values = hk_farben_fix) +
  labs(x = "Anteil mit historischer Einleitung (%)", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"),
        panel.grid.major.y = element_blank())

save_plot(p_einleitung, "anteil_einleitung_herkunft_proportional", w = 12, h = 7)

# ============================================================
# QUELLENTYPEN
# ============================================================

## 6a – Lollipop
p_quellen <- df_quellen %>%
  count(quellentyp, sort = TRUE) %>%
  filter(!is.na(quellentyp)) %>%
  slice_head(n = 20) %>%
  mutate(quellentyp = fct_reorder(quellentyp, n),
         kategorie  = ifelse(quellentyp %in% hist_typen,
                             "Historisch", "Naturwiss./Fachlich")) %>%
  ggplot(aes(x = n, y = quellentyp, color = kategorie)) +
  geom_segment(aes(x = 0, xend = n, yend = quellentyp),
               color = "#DDDDDD", linewidth = 0.8) +
  geom_point(size = 4) +
  geom_text(aes(label = n), hjust = -0.6, size = 3.2, color = "#333333") +
  scale_color_manual(values = quellen_farben, name = "Quellentyp") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_quellen, "quellentypen", w = 12, h = 8)

## 6b – Verhältnis nach Stellenwert
df_q_typ <- df_quellen %>%
  select(-any_of("skala_f")) %>%
  mutate(q_kat = ifelse(quellentyp %in% hist_typen, "Historisch", "Naturwiss./Fachlich")) %>%
  left_join(df %>% select(id1, skala_f), by = "id1") %>%
  filter(!is.na(skala_f)) %>%
  count(skala_f, q_kat) %>%
  group_by(skala_f) %>% mutate(pct = n / sum(n))

p_verh <- ggplot(df_q_typ, aes(x = skala_f, y = pct, fill = q_kat)) +
  geom_col(position = "fill", width = 0.55) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = quellen_farben, name = "Quellentyp") +
  labs(x = "Stellenwert", y = "Anteil") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_verh, "quellen_verhaeltnis_stellenwert")

# ============================================================
# TSCHIRCH-ZITATION
# ============================================================

## 7a – Zeitverlauf (Checkbox komplett fix)
d_zitation_zeit <- df %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  group_by(dekade) %>%
  summarise(n_total = n(), n_zit = sum(tschirch_zit),
            pct_zit = n_zit / n_total, .groups = "drop")

p_zeit <- ggplot(d_zitation_zeit, aes(x = dekade)) +
  geom_col(aes(y = pct_zit), fill = "#A8C5E0", alpha = 0.5, width = 8) +
  geom_line(aes(y = pct_zit), color = "#C97B8A", linewidth = 1.3) +
  geom_point(aes(y = pct_zit, size = n_total), color = "#C97B8A") +
  geom_text(aes(y = pct_zit, label = paste0(n_zit, "/", n_total)),
            vjust = -1.4, size = 3, color = "#555555") +
  scale_y_continuous(labels = percent, limits = c(0, 1.12)) +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  scale_size_continuous(range = c(3, 8), name = "Anzahl Diss.") +
  labs(x = "Dekade", y = "Anteil Tschirch-Zitationen") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_zeit, "zeitverlauf_zitationen")

## 7b – Werke-Ranking
p_werke <- df_tschirch_werke %>%
  count(werk, sort = TRUE) %>%
  filter(!is.na(werk)) %>%
  mutate(werk = fct_reorder(werk, n)) %>%
  ggplot(aes(x = n, y = werk)) +
  geom_segment(aes(x = 0, xend = n, yend = werk),
               color = "#DDDDDD", linewidth = 0.9) +
  geom_point(size = 4, color = "#C97B8A") +
  geom_text(aes(label = n), hjust = -0.6, size = 3.5, color = "#333333") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_werke, "tschirch_werke", w = 13, h = 6)

## 7c – VERNETZEND: Welche Werke werden in welchen Dekaden zitiert? (NEU)
## Zeigt die Kanonisierungsdynamik der einzelnen Werke über die Zeit
d_werke_dekade <- df_tschirch_werke %>%
  mutate(dekade = floor(jahr / 10) * 10) %>%
  count(werk, dekade) %>%
  # Gesamtnennungen für Sortierung
  left_join(df_tschirch_werke %>% count(werk, name = "total"), by = "werk") %>%
  mutate(werk = fct_reorder(werk, total))

p_vernetz <- ggplot(d_werke_dekade,
                         aes(x = dekade, y = werk, size = n, color = werk)) +
  geom_point(alpha = 0.85) +
  geom_line(aes(group = werk), linewidth = 0.4, alpha = 0.3, color = "#AAAAAA") +
  scale_size_continuous(range = c(2, 12), name = "Nennungen") +
  scale_color_manual(
    values = setNames(
      colorRampPalette(c("#B0C4DE","#7FB6B2","#7EB8A0","#EBC46A",
                          "#E8A87C","#C97B8A","#C2A4D6","#A6D9BD",
                          "#E1A9BE","#DCCBEA","#E3C9AF"))(
        length(unique(d_werke_dekade$werk))),
      levels(d_werke_dekade$werk)
    ),
    guide = "none"
  ) +
  scale_x_continuous(breaks = seq(1880, 1930, 10)) +
  labs(x = "Dekade", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

save_plot(p_vernetz, "werke_zeitverlauf_vernetzt", w = 13, h = 7)

## 7d – VERNETZEND 2: Welche Werke werden zusammen zitiert? (Heatmap)
## Für jede Dissertation: Ko-Zitatmatrix der Werke
# Hauptwerke bestimmen (mindestens 3 Nennungen)
hauptwerke <- df_tschirch_werke |>
  count(werk, name = "n_gesamt") |>
  filter(n_gesamt >= 3)

werke_ko <- df_tschirch_werke |>
  select(id1, werk) |>
  inner_join(
    df_tschirch_werke |>
      select(id1, werk2 = werk),
    by = "id1"
  ) |>
  filter(werk != werk2) |>
  count(werk, werk2, name = "n_ko") |>
  semi_join(hauptwerke, by = "werk") |>
  semi_join(hauptwerke, by = c("werk2" = "werk"))

if (nrow(werke_ko) > 0) {
  p_ko_heatmap <- ggplot(werke_ko, aes(x = werk2, y = werk, fill = n_ko)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = n_ko), size = 3,
              color = ifelse(werke_ko$n_ko >= 8, "white", "#333333")) +
    scale_fill_gradient(
      low  = "#EDF5F1",
      high = "#5F8F87",
      name = "Ko-Zitationen"
    ) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 11) +
    theme(plot.title  = element_text(face = "bold"),
          panel.grid  = element_blank(),
          axis.text.x = element_text(angle = 35, hjust = 1, size = 9),
          axis.text.y = element_text(size = 9))

  save_plot(p_ko_heatmap, "ko_zitation_heatmap", w = 10, h = 8)
}

# ============================================================
# NARRATIVE UND FUNKTIONEN
# ============================================================

## 8a – Narrative Formen
p_form <- df_narrativ %>%
  count(narrative, sort = TRUE) %>%
  mutate(narrative = fct_reorder(narrative, n)) %>%
  ggplot(aes(x = n, y = narrative, fill = narrative)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.2, size = 4) +
  scale_fill_manual(values = narrativ_farben) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_form, "narrative_formen")

## 8b – Weitere Funktionen (ohne kontextualisierend)
p_wozu <- df_wozu %>%
  count(wozu, sort = TRUE) %>%
  mutate(wozu = fct_reorder(wozu, n)) %>%
  ggplot(aes(x = n, y = wozu, fill = wozu)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.2, size = 4) +
  scale_fill_manual(values = funktion_farben) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_wozu, "funktionen")

## 8c – Sprachregister (wieder aufgenommen, einzeln, eigene Farben)
p_register <- df_register %>%
  count(register, sort = TRUE) %>%
  mutate(register = fct_reorder(register, n)) %>%
  ggplot(aes(x = n, y = register, fill = register)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.2, size = 4) +
  scale_fill_manual(values = sprachregister_farben) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_register, "sprachregister")

# ============================================================
# FOKUS DES HISTORISCHEN TEILS
# ============================================================

fokus_n <- df_fokus %>% count(fokus, sort = TRUE)

fokus_farben_use <- setNames(
  colorRampPalette(c("#B0C4DE","#7EB8A0","#E8A87C","#C2A4D6",
                      "#EBC46A","#C97B8A","#A6D9BD"))(nrow(fokus_n)),
  fokus_n$fokus
)

## 9a – Fokus Ranking
p_fokus <- fokus_n %>%
  mutate(fokus = fct_reorder(fokus, n)) %>%
  ggplot(aes(x = n, y = fokus, fill = fokus)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = paste0("n=", n)), hjust = -0.2, size = 3.8) +
  scale_fill_manual(values = fokus_farben_use) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = "Anzahl Nennungen", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))

save_plot(p_fokus, "fokus", w = 12, h = 7)

## 9b – Fokus nach Zeitkontext
p_ztk_fokus <- df_fokus %>%
  select(-any_of("zeitkontext_clean")) %>%
  left_join(df %>% select(id1, zeitkontext_clean), by = "id1") %>%
  filter(!is.na(zeitkontext_clean)) %>%
  count(fokus, zeitkontext_clean) %>%
  group_by(zeitkontext_clean) %>%
  mutate(pct = n / sum(n), total = sum(n),
         ztk_lbl = paste0(zeitkontext_clean, " (n=", total, ")"),
         ztk_lbl = factor(ztk_lbl,
                           levels = unique(ztk_lbl[order(match(
                             zeitkontext_clean,
                             c("Hochimperialismus","1. Weltkrieg","Zwischenkriegszeit")))]))) %>%
  ggplot(aes(x = ztk_lbl, y = pct, fill = fct_reorder(fokus, pct, sum))) +
  geom_col(position = "fill", width = 0.55) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = fokus_farben_use, name = "Fokus") +
  labs(x = NULL, y = "Anteil") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"), legend.text = element_text(size = 8))

save_plot(p_ztk_fokus, "fokus_zeitkontext", w = 12, h = 7)

# ============================================================
# Gebündelte Plots zu Panels
# ============================================================

# Epochenranking & Heatmap Epochen x Dekade
library(patchwork)

p_panel_epochen <- (p_epochen + p_heatmap) +
  plot_annotation(
    tag_levels = "A"
  )

save_plot(p_panel_epochen, "01_epochenpanel", w = 20, h = 10)

# Narrative Formen + Sprachregister + Funktionen
p_panel_sprache <- (p_form + p_register + p_wozu) +
  plot_annotation(
    tag_levels = "A"
  )

save_plot(p_panel_sprache, "02_sprachenpanel", w = 20, h = 10)

# Stoffklassen Anteil und Stellenwert
p_panel_stoffklasse <- (p_box_stoffklasse + p_kreuz_stoffklasse) +
  plot_annotation(
    tag_levels = "A"
  )

save_plot(p_panel_stoffklasse, "03_stoffklassenpanel", w = 20, h = 10)

# Tschirch-Zitationen und Werke
p_panel_tschirch <- (p_zeit + p_vernetz) +
  plot_annotation(
    tag_levels = "A"
  )

save_plot(p_panel_tschirch, "04_tschirchpanel", w = 20, h = 10)


# ============================================================

# Plot-Objekte für Panel-Komposition speichern
saveRDS(
  list(
    p_epochen = p_epochen,
    p_heatmap = p_heatmap,
    p_form = p_form, 
    p_register = p_register,
    p_wozu = p_wozu,
    p_box = p_box_stoffklasse,
    p_kreuz = p_kreuz_stoffklasse,
    p_zeit = p_zeit,
    p_werke = p_werke,
    df             = df
  ),
  "output6/plots_hauptauswertung.rds"
)


