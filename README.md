# Digitaler Anhang

**Berner Dissertationen als Quellen zur Geschichte der Pharmazie**
Masterarbeit von Hanna Schmid · Universität Bern · 2026

---

## Öffnen

`index.html` mit einem aktuellen Browser öffnen (Chrome, Firefox, Safari, Edge).
Doppelklick genügt – es wird keine Internetverbindung benötigt, alles läuft offline.

Wichtig: Die Datei `index.html` muss zusammen mit den Ordnern `figures/`,
`titelseiten/`, `r_skripte/` sowie den Dateien `data.js` und `app.js` im selben
Verzeichnis liegen.

## Inhalt

Die Navigation links führt zu sechs Bereichen:

| Bereich | Inhalt |
|---|---|
| **Abbildungen** | Alle 51 Abbildungen der quantitativen Auswertung, thematisch gegliedert, mit Bildunterschrift und PNG-Download |
| **Korpus & Explorer** | Vollständige Liste aller 160 unter Tschirch betreuten Dissertationen (1889–1935). Die 78 in die Clusteranalyse eingegangenen Arbeiten sind hervorgehoben, filterbar (nach Cluster, Stoffklasse, Herkunft, Zeitkontext, Stellenwert, Sprachregister, narrativer Form) und per Klick mit ihrem vollständigen Analyseprofil verknüpft |
| **Hermeneutische Analysen** | 14 qualitative Einzelanalysen, jeweils mit Titelseite der Originaldissertation und vollständigem Analysetext |
| **R-Skripte & Daten** | Vollständiger Analysecode (Hauptauswertung & Clusteranalyse) mit Syntax-Hervorhebung und Download, dazu die fünf CSV-Datensätze, die die Skripte einlesen |
| **Personenranking** | Alle 53 historischen Autoritäten mit ≥ 3 Nennungen, gefärbt nach Traditionslinie |

## Dateien bearbeiten

Sämtliche Texte und Daten liegen in **`data.js`**. Wer Bildunterschriften,
Analysetexte oder Tabellendaten ändern möchte, bearbeitet diese Datei mit einem
Texteditor (empfohlen: VS Code). Das Layout und die Logik stecken in `app.js`,
das Design in `index.html`.

## Struktur

```
digitaler-anhang/
├── index.html        ← hier starten
├── app.js            ← Anwendungslogik
├── data.js           ← alle Inhalte und Daten
├── figures/          ← 51 Abbildungen (PNG)
├── titelseiten/      ← 14 Titelseiten der Fallstudien (JPG)
├── r_skripte/        ← 2 R-Skripte (.R)
├── csv_daten/        ← 4 CSV-Datensätze (Haupt- und Clusterauswertung)
└── cluster_analyse/  ← 1 CSV-Datensatz (Cluster-Rohdaten)
```

## Hinweis zu den R-Skripten

Die beiden Skripte in `r_skripte/` lesen fünf CSV-Dateien aus den Ordnern
`csv_daten/` und `cluster_analyse/`. Damit der Code ohne Anpassung läuft, müssen
die Skripte zusammen mit diesen beiden Ordnern im selben Arbeitsverzeichnis
liegen. `BASE_DIR` im Skriptkopf zeigt standardmässig auf `getwd()`; bei
abweichender Ablage einmalig anpassen. Die Datensätze stehen im Bereich
**R-Skripte & Daten** auch einzeln zum Download bereit.
