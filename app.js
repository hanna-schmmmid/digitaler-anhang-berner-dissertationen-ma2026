// ============================================================
// DIGITALER ANHANG – Anwendungslogik
// ============================================================

const tagLabels = { haupt: 'Hauptauswertung', anhang: 'Hauptauswertung', cluster: 'Cluster' };

// ---------- Navigation ----------
const navItems = document.querySelectorAll('.nav-item');
const panels = document.querySelectorAll('.panel');
const rendered = {};

navItems.forEach(item => {
  item.addEventListener('click', () => {
    const target = item.dataset.panel;
    navItems.forEach(n => n.classList.remove('active'));
    item.classList.add('active');
    panels.forEach(p => p.classList.remove('active'));
    document.getElementById('panel-' + target).classList.add('active');
    if (!rendered[target]) { renderPanel(target); rendered[target] = true; }
    closeSidebar();
    window.scrollTo(0, 0);
  });
});

function renderPanel(name) {
  ({ home: renderHome, abbildungen: renderAbbildungen,
     hermeneutik: renderHermeneutik, rskripte: renderRSkripte,
     korpus: renderKorpus, personen: renderPersonen })[name]();
}

// Mobile sidebar
const sidebar = document.getElementById('sidebar');
const backdrop = document.getElementById('sidebarBackdrop');
document.getElementById('menuToggle').addEventListener('click', () => {
  sidebar.classList.toggle('open'); backdrop.classList.toggle('show');
});
backdrop.addEventListener('click', closeSidebar);
function closeSidebar() { sidebar.classList.remove('open'); backdrop.classList.remove('show'); }

function esc(s) { return String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
function snippet(t, n=140) { return t.length <= n ? t : t.slice(0, n).replace(/\s+\S*$/, '') + '…'; }

// Navigation per Code (für die Kacheln der Startseite)
function goToPanel(name) {
  const item = document.querySelector(`.nav-item[data-panel="${name}"]`);
  if (item) item.click();
}

// ============================================================
// 0) STARTSEITE
// ============================================================
function renderHome() {
  const p = document.getElementById('panel-home');
  const cards = [
    { panel: 'abbildungen', ico: '▦', title: 'Abbildungen', meta: '51 Abbildungen',
      desc: 'Sämtliche Grafiken der quantitativen Auswertung, thematisch gegliedert in Hauptauswertung und Clusteranalyse, mit Bildunterschrift und PNG-Download.' },
    { panel: 'korpus', ico: '☰', title: 'Korpus & Explorer', meta: '160 Dissertationen',
      desc: 'Vollständige Liste aller betreuten Arbeiten. Die 100 mit historischer Einleitung sind filterbar und per Klick mit ihrem Analyseprofil verknüpft.' },
    { panel: 'hermeneutik', ico: '❦', title: 'Hermeneutische Analysen', meta: '14 Fallstudien',
      desc: 'Qualitative Einzellektüren ausgewählter Dissertationen, jeweils mit Titelseite der Originalarbeit und vollständigem Analysetext.' },
    { panel: 'rskripte', ico: '⟨⟩', title: 'R-Skripte & Daten', meta: '2 Skripte · 5 Datensätze',
      desc: 'Der vollständige Analysecode beider Auswertungen sowie die zugrunde liegenden CSV-Datensätze zum Download.' },
    { panel: 'personen', ico: '✦', title: 'Personenranking', meta: '53 Autoritäten',
      desc: 'Die in den historischen Einleitungen genannten historischen Autoritäten, gefärbt nach pharmaziehistorischer Traditionslinie.' }
  ];
  p.innerHTML = `
    <div class="home-hero">
      <div class="home-eyebrow">Universität Bern · Masterarbeit · 2026</div>
      <h1 class="home-title">Digitaler Anhang</h1>
      <p class="home-sub">Berner Dissertationen als Quellen zur Geschichte der Pharmazie</p>
      <p class="home-author">Hanna Schmid</p>
    </div>

    <div class="home-intro">
      <p>Dieser digitale Anhang ergänzt die gleichnamige Masterarbeit. Er macht das vollständige Quellenkorpus, die quantitative Auswertung, die qualitativen Einzelanalysen und den Analysecode interaktiv zugänglich. Alle Inhalte sind offline nutzbar; es wird keine Internetverbindung benötigt.</p>
    </div>

    <h2 class="home-section-title">Bereiche</h2>
    <div class="home-cards">
      ${cards.map(c => `
        <button class="home-card" data-goto="${c.panel}">
          <span class="home-card-ico">${c.ico}</span>
          <span class="home-card-body">
            <span class="home-card-title">${esc(c.title)}</span>
            <span class="home-card-meta">${esc(c.meta)}</span>
            <span class="home-card-desc">${esc(c.desc)}</span>
          </span>
        </button>`).join('')}
    </div>

    <div class="home-note">
      <h2 class="home-note-title">Zur Erstellung dieses Anhangs</h2>
      <p>Die Konzeption, die Quellenerhebung, die Kodierung des Korpus, die statistische Auswertung und sämtliche inhaltlichen Analysen stammen von der Verfasserin. Die technische Umsetzung dieses digitalen Anhangs, also die Programmierung der interaktiven Oberfläche (HTML, CSS, JavaScript) und die Aufbereitung der Daten für die Darstellung, wurde mit Unterstützung des KI-Assistenten Claude (Anthropic) erarbeitet. Die zugrunde liegenden Daten, R-Skripte und Analysetexte wurden von der Verfasserin erstellt und verantwortet.</p>
    </div>`;

  p.querySelectorAll('.home-card').forEach(btn =>
    btn.addEventListener('click', () => goToPanel(btn.dataset.goto)));
}

// ============================================================
// 1) ABBILDUNGEN
// ============================================================
let figFilter = 'all', figSearch = '';
const themeMap = Object.fromEntries([...FIG_THEMES, ...FIG_CLUSTER_THEMES].map(t => [t.id, t]));

function renderAbbildungen() {
  const p = document.getElementById('panel-abbildungen');
  p.innerHTML = `
    <div class="panel-intro">
      <h2>Abbildungen</h2>
      <p>Sämtliche 51 Abbildungen der quantitativen Auswertung, gegliedert in Hauptauswertung und Clusteranalyse. Klick auf eine Abbildung öffnet die Vollansicht mit Bildunterschrift und Download.</p>
    </div>
    <div class="controls-bar">
      <div class="search-box"><input type="text" id="figSearchInput" placeholder="Suche in Titeln und Beschreibungen…"></div>
      <div class="filter-group" id="figFilterGroup">
        <button class="filter-btn active" data-filter="all">Alle</button>
        <button class="filter-btn" data-filter="haupt">Hauptauswertung</button>
        <button class="filter-btn" data-filter="cluster">Clusteranalyse</button>
      </div>
      <span class="stats" id="figStats"></span>
    </div>
    <div id="figContainer"></div>`;

  document.getElementById('figFilterGroup').addEventListener('click', e => {
    if (!e.target.classList.contains('filter-btn')) return;
    document.querySelectorAll('#figFilterGroup .filter-btn').forEach(b => b.classList.remove('active'));
    e.target.classList.add('active'); figFilter = e.target.dataset.filter; renderFigGrid();
  });
  let t;
  document.getElementById('figSearchInput').addEventListener('input', e => {
    clearTimeout(t); t = setTimeout(() => { figSearch = e.target.value; renderFigGrid(); }, 150);
  });
  renderFigGrid();
}

const CLUSTER_THEME_IDS = new Set(FIG_CLUSTER_THEMES.map(t => t.id));
function figGroup(f) { return CLUSTER_THEME_IDS.has(f.theme) ? 'cluster' : 'haupt'; }

function figMatch(f) {
  const s = figSearch.toLowerCase().trim();
  const okF = figFilter === 'all' || figGroup(f) === figFilter;
  const okS = !s || f.title.toLowerCase().includes(s) || f.caption.toLowerCase().includes(s);
  return okF && okS;
}

function renderFigGrid() {
  const cont = document.getElementById('figContainer');
  cont.innerHTML = '';
  let shown = 0;
  const renderGroup = (themeList, isCluster) => {
    themeList.forEach(theme => {
      const figs = FIGURES.filter(f => f.theme === theme.id && figMatch(f));
      if (!figs.length) return;
      shown += figs.length;
      const sec = document.createElement('section');
      sec.className = 'section' + (isCluster ? ' cluster' : '');
      sec.innerHTML = `<div class="section-header"><h2 class="section-title">${esc(theme.title)}</h2>
        <p class="section-subtitle">${esc(theme.subtitle)}</p></div><div class="grid"></div>`;
      const grid = sec.querySelector('.grid');
      figs.forEach(fig => {
        const idx = FIGURES.indexOf(fig);
        const card = document.createElement('div');
        card.className = 'card';
        card.innerHTML = `<div class="card-image"><img src="figures/${fig.file}" alt="${esc(fig.title)}" loading="lazy"></div>
          <div class="card-body"><span class="card-tag ${fig.type}">${tagLabels[fig.type]}</span>
          <h3 class="card-title">${esc(fig.title)}</h3><p class="card-snippet">${esc(snippet(fig.caption))}</p></div>`;
        card.addEventListener('click', () => openFigModal(idx));
        grid.appendChild(card);
      });
      cont.appendChild(sec);
    });
  };
  renderGroup(FIG_THEMES, false);
  const clusterShown = FIGURES.filter(f => FIG_CLUSTER_THEMES.find(t => t.id === f.theme) && figMatch(f)).length;
  if (clusterShown) {
    const sep = document.createElement('div');
    sep.style.cssText = 'margin: 3rem 0 1rem; padding-top: 1rem; border-top: 1px solid var(--border);';
    sep.innerHTML = `<h2 style="font-size:1.6rem;margin:0;color:var(--tag-cluster);font-weight:600;">Clusteranalyse</h2>
      <p style="margin:.3rem 0 0;color:var(--text-muted);font-style:italic;font-size:.95rem;">Vier historiographische Dissertationstypen — Ward-Linkage / Gower-Distanz, n = 78</p>`;
    cont.appendChild(sep);
    renderGroup(FIG_CLUSTER_THEMES, true);
  }
  if (!shown) cont.innerHTML = '<div class="empty-state">Keine Abbildungen gefunden.</div>';
  document.getElementById('figStats').textContent = shown === FIGURES.length ? `${FIGURES.length} Abbildungen` : `${shown} von ${FIGURES.length}`;
}

// Fig modal
const figModal = document.getElementById('figModal');
const figModalImage = document.getElementById('figModalImage');
function openFigModal(idx) {
  const f = FIGURES[idx];
  document.getElementById('figModalImg').src = `figures/${f.file}`;
  document.getElementById('figModalTag').textContent = tagLabels[f.type];
  document.getElementById('figModalTag').className = `card-tag ${f.type}`;
  document.getElementById('figModalTheme').textContent = themeMap[f.theme]?.title || '';
  document.getElementById('figModalTitle').textContent = f.title;
  document.getElementById('figModalCaption').textContent = f.caption;
  const dl = document.getElementById('figModalDownload');
  dl.href = `figures/${f.file}`; dl.download = f.file;
  figModalImage.classList.remove('zoomed');
  figModal.classList.add('active'); document.body.style.overflow = 'hidden';
}
function closeFigModal() { figModal.classList.remove('active'); figModalImage.classList.remove('zoomed'); document.body.style.overflow = ''; }
function toggleFigZoom() {
  figModalImage.classList.toggle('zoomed');
  const zoomed = figModalImage.classList.contains('zoomed');
  const zb = document.getElementById('figModalZoom');
  if (zb) zb.textContent = zoomed ? '⊖ Zoom zurücksetzen' : '⊕ Bild anklicken zum Zoomen';
  if (zoomed) figModalImage.scrollTop = 0;
}
document.getElementById('figModalClose').addEventListener('click', closeFigModal);
figModal.addEventListener('click', e => { if (e.target === figModal) closeFigModal(); });
figModalImage.addEventListener('click', toggleFigZoom);
document.getElementById('figModalZoom').addEventListener('click', e => { e.stopPropagation(); toggleFigZoom(); });

// ============================================================
// 2) DETAILANSICHT (geteilt mit Korpus & Explorer)
// ============================================================
function dots(lv) {
  let h = '<span class="stellenwert-dots">';
  for (let i=1;i<=3;i++) h += `<span class="${i<=lv?'on':''}"></span>`;
  return h + '</span>';
}

const dissModal = document.getElementById('dissModal');
document.getElementById('dissModalClose').addEventListener('click', () => { dissModal.classList.remove('active'); document.body.style.overflow=''; });
dissModal.addEventListener('click', e => { if (e.target === dissModal) { dissModal.classList.remove('active'); document.body.style.overflow=''; } });
function openDissDetail(d) {
  document.getElementById('dissDetailTitle').textContent = d.titel;
  document.getElementById('dissDetailAuthor').textContent = `${d.vorname} ${d.nachname} · ${d.jahr} · ${d.herkunft}`;
  const clusterVal = d.cluster
    ? `<span class="cluster-badge" data-c="${d.cluster}">${d.cluster}</span> Typ ${d.cluster}`
    : `<span class="cluster-badge none">–</span> nicht geclustert (Stoffklasse Sonstige)`;
  const items = [
    ['Cluster-Typ', clusterVal],
    ['Stoffklasse', esc(d.stoffklasse)], ['Zeitkontext', esc(d.zeitkontext)],
    ['Stellenwert', `${dots(d.stellenwert)} ${['gering','mittel','zentral'][d.stellenwert-1]}`],
    ['Anteil historisch', `${d.anteil_hist.toFixed(1)} %`],
    ['Vor-19.-Jh.-Epochen', d.n_pre19], ['Historische Quellen', d.n_hist_quellen],
    ['Genannte Personen', d.n_personen], ['Sprachregister', esc(d.sprachregister.replaceAll(',', ', '))],
    ['Narrative Form', d.narrativ === 'NA' ? '–' : esc(d.narrativ.replaceAll(',', ', '))]
  ];
  document.getElementById('dissDetailGrid').innerHTML = items.map(([l,v]) =>
    `<div class="meta-item"><label>${l}</label><div class="val">${v}</div></div>`).join('');
  dissModal.classList.add('active'); document.body.style.overflow = 'hidden';
}

// ============================================================
// 3) HERMENEUTISCHE ANALYSEN
// ============================================================
const typColors = {
  'A': ['var(--c-a)','var(--c-a-d)'], 'B': ['var(--c-b)','var(--c-b-d)'],
  'C': ['var(--c-c)','var(--c-c-d)'], 'D': ['var(--c-d)','var(--c-d-d)']
};
function typLetter(meta) {
  const t = (meta.Typ || '').match(/\b([A-D])\b/);
  return t ? t[1] : null;
}

function renderHermeneutik() {
  const p = document.getElementById('panel-hermeneutik');
  let cards = '';
  HERMENEUTIK.forEach((e, i) => {
    const tl = typLetter(e.meta);
    const col = tl ? typColors[tl] : ['var(--bg)','var(--text-muted)'];
    cards += `<div class="herm-card" data-idx="${i}">
      <div class="herm-card-img"><img src="titelseiten/${e.titelseite}" alt="Titelseite ${esc(e.surname)}" loading="lazy"></div>
      <div class="herm-card-body">
        <div class="herm-card-author">${esc(e.surname)}</div>
        <div class="herm-card-year">${esc(e.vorname)} · ${e.jahr}</div>
        <div class="herm-card-titel">${esc(e.titel)}</div>
        ${tl ? `<span class="herm-card-typ" style="background:${col[0]};color:${col[1]};">Typ ${tl}</span>` : ''}
      </div></div>`;
  });
  p.innerHTML = `
    <div class="panel-intro">
      <h2>Hermeneutische Analysen</h2>
      <p>Vierzehn qualitative Einzelanalysen ausgewählter Dissertationseinleitungen, je nach einheitlichem Raster (Heuristik, Sprachanalyse, Epistemologie, zentrale Zitate, Fazit). Klick auf eine Titelseite öffnet die vollständige Analyse neben dem Original.</p>
    </div>
    <div class="herm-gallery">${cards}</div>`;
  p.querySelectorAll('.herm-card').forEach(c =>
    c.addEventListener('click', () => openHermDetail(parseInt(c.dataset.idx))));
}

const hermOverlay = document.getElementById('hermDetail');
const hermInner = document.getElementById('hermDetailInner');
document.getElementById('hermDetailClose').addEventListener('click', closeHermDetail);
hermOverlay.addEventListener('click', e => { if (e.target === hermOverlay) closeHermDetail(); });
function closeHermDetail() { hermOverlay.classList.remove('active'); document.body.style.overflow = ''; }

function openHermDetail(idx) {
  const e = HERMENEUTIK[idx];
  const s = e.sections;
  const metaRows = Object.entries(e.meta).map(([k,v]) =>
    `<tr><td>${esc(k)}</td><td>${esc(v)}</td></tr>`).join('');
  const para = txt => (txt||'').split(/(?<=\.)\s+(?=[A-ZÄÖÜ])/).reduce((acc,_,i,arr)=>acc, '') ; // placeholder
  const block = (heading, txt) => txt ? `<div class="herm-block"><h3>${heading}</h3><p>${esc(txt)}</p></div>` : '';
  const zitateBlock = (s.zitate && s.zitate.length)
    ? `<div class="herm-block"><h3>Zentrale Zitate</h3><ul class="herm-zitate">${s.zitate.map(z=>`<li>${esc(z)}</li>`).join('')}</ul></div>`
    : '';
  hermInner.innerHTML = `
    <div class="herm-cols">
      <div class="herm-col-image">
        <img src="titelseiten/${e.titelseite}" alt="Titelseite ${esc(e.surname)}" id="hermZoomImg">
        <div class="zoom-hint">Klick zum Vergrössern</div>
      </div>
      <div class="herm-col-text">
        <h2>${esc(e.surname)}, ${esc(e.vorname)}</h2>
        <p class="herm-sub">${esc(e.titel)} · ${e.jahr}</p>
        <table class="herm-meta-table">${metaRows}</table>
        ${block('Heuristik und Bestandesaufnahme', s.heuristik)}
        ${block('Sprachanalyse und Quellengebrauch', s.sprache)}
        ${block('Historische Epistemologie und Denkstil', s.epistemologie)}
        ${zitateBlock}
        ${block('Fazit', s.fazit)}
      </div>
    </div>`;
  hermOverlay.classList.add('active'); document.body.style.overflow = 'hidden';
  hermOverlay.scrollTop = 0;
  const zoomImg = document.getElementById('hermZoomImg');
  const zoomHint = zoomImg.parentElement.querySelector('.zoom-hint');
  zoomImg.addEventListener('click', function() {
    const zoomed = this.classList.toggle('zoomed');
    if (zoomHint) zoomHint.textContent = zoomed ? 'Klick zum Verkleinern' : 'Klick zum Vergrössern';
  });
}

// ============================================================
// 4) R-SKRIPTE
// ============================================================
function highlightR(code) {
  const kws = new Set(['library','require','function','if','else','for','while','return','in',
    'TRUE','FALSE','NULL','NA','NA_real_','NA_integer_','Inf','NaN','switch','repeat','next','break']);
  const esc = c => ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c] || c);
  const escStr = s => s.replace(/[&<>]/g, esc);

  return code.split('\n').map(line => {
    let out = '', i = 0, n = line.length;
    while (i < n) {
      const c = line[i];
      // Comment to end of line
      if (c === '#') { out += `<span class="cmt">${escStr(line.slice(i))}</span>`; break; }
      // String literal
      if (c === '"' || c === "'") {
        let j = i + 1;
        while (j < n && line[j] !== c) { if (line[j] === '\\') j++; j++; }
        out += `<span class="str">${escStr(line.slice(i, j + 1))}</span>`;
        i = j + 1; continue;
      }
      // Number
      if (/[0-9]/.test(c) && !/[A-Za-z_.]/.test(line[i-1] || '')) {
        let j = i;
        while (j < n && /[0-9.eE]/.test(line[j])) j++;
        out += `<span class="num">${line.slice(i, j)}</span>`;
        i = j; continue;
      }
      // Identifier / keyword / function
      if (/[A-Za-z_.]/.test(c)) {
        let j = i;
        while (j < n && /[A-Za-z0-9_.]/.test(line[j])) j++;
        const word = line.slice(i, j);
        let k = j; while (k < n && line[k] === ' ') k++;
        if (kws.has(word)) out += `<span class="kw">${word}</span>`;
        else if (line[k] === '(') out += `<span class="fn">${word}</span>`;
        else out += word;
        i = j; continue;
      }
      // Operators
      const two = line.slice(i, i + 2), three = line.slice(i, i + 3);
      if (three === '%>%') { out += `<span class="op">${escStr(three)}</span>`; i += 3; continue; }
      if (two === '<-' || two === '->' || two === '|>' || two === '==' || two === '!=' ||
          two === '<=' || two === '>=') { out += `<span class="op">${escStr(two)}</span>`; i += 2; continue; }
      if ('+-*/<>=~&|'.includes(c)) { out += `<span class="op">${escStr(c)}</span>`; i++; continue; }
      out += escStr(c); i++;
    }
    return out;
  }).join('\n');
}

// CSV-Datensätze, die die Skripte einlesen. path = tatsächlicher Ablageort
// im Anhang; die Skripte erwarten genau diese Ordner (csv_daten/, cluster_analyse/).
const R_DATASETS = [
  { folder: 'csv_daten', file: 'Getting Started - diss_tschirch (diss_tschirch_historisch) 2026-04-14_16-57.csv',
    label: 'Historischer Teilkorpus', desc: '100 Dissertationen mit historischer Einleitung – Kerndatensatz beider Skripte.' },
  { folder: 'csv_daten', file: 'Getting Started - diss_tschirch (diss_tschirch_gesamtkorpus) 2026-04-15_10-36.csv',
    label: 'Gesamtkorpus', desc: 'Alle 160 betreuten Dissertationen – für Verbreitungs- und Dekadengrafiken.' },
  { folder: 'csv_daten', file: 'Getting Started - tschirch_top_personen (tschirch_top_personen) 2026-04-15_10-36.csv',
    label: 'Personenreferenz', desc: 'Historische Autoritäten mit Traditionslinie und Nennungszeitraum.' },
  { folder: 'csv_daten', file: 'Getting Started - cluster_zuordnung (cluster_zuordnung) 2026-04-15_10-36.csv',
    label: 'Cluster-Zuordnung', desc: 'Cluster-Label je Dissertation – Join für die Hauptauswertung.' },
  { folder: 'cluster_analyse', file: 'clustering_tschirch_diss_tschirch_clusteranalysis_2026-03-30_17-15.csv',
    label: 'Cluster-Rohdaten', desc: 'Merkmalsmatrix, aus der die Clusteranalyse berechnet wird.' }
];

const rScripts = {
  haupt: { name: 'tschirch_hauptauswertung_finalversion.R', code: R_HAUPTAUSWERTUNG, label: 'Hauptauswertung' },
  cluster: { name: 'tschirch_clusteranalyse_finalversion.R', code: R_CLUSTERANALYSE, label: 'Clusteranalyse' }
};
let rActive = 'haupt';

function renderRSkripte() {
  const p = document.getElementById('panel-rskripte');
  const dsRows = R_DATASETS.map(d => {
    const href = `${d.folder}/${encodeURIComponent(d.file)}`;
    return `<div class="ds-row">
      <div class="ds-info">
        <span class="ds-label">${esc(d.label)}</span>
        <span class="ds-desc">${esc(d.desc)}</span>
        <span class="ds-path">${esc(d.folder)}/${esc(d.file)}</span>
      </div>
      <a class="btn ds-btn" href="${href}" download="${esc(d.file)}">↓ CSV</a>
    </div>`;
  }).join('');
  p.innerHTML = `
    <div class="panel-intro">
      <h2>R-Skripte &amp; Daten</h2>
      <p>Der vollständige Analysecode der quantitativen Auswertung. Beide Skripte erzeugen sämtliche Abbildungen und statistischen Tests. Code direkt einsehbar, Download als <code>.R</code>-Datei.</p>
    </div>
    <div class="ds-block">
      <h3 class="ds-heading">Datensätze</h3>
      <p class="ds-note">Die Skripte erwarten die folgenden fünf CSV-Dateien in der gezeigten Ordnerstruktur neben der jeweiligen <code>.R</code>-Datei. <code>BASE_DIR</code> im Skriptkopf zeigt standardmässig auf das Arbeitsverzeichnis (<code>getwd()</code>); bei abweichender Ablage einmalig anpassen.</p>
      <div class="ds-list">${dsRows}</div>
    </div>
    <div class="r-tabs" id="rTabs">
      <div class="r-tab active" data-r="haupt">⟨⟩ Hauptauswertung</div>
      <div class="r-tab" data-r="cluster">⟨⟩ Clusteranalyse</div>
    </div>
    <div id="rContainer"></div>`;
  document.getElementById('rTabs').addEventListener('click', e => {
    const tab = e.target.closest('.r-tab'); if (!tab) return;
    document.querySelectorAll('.r-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active'); rActive = tab.dataset.r; renderRCode();
  });
  renderRCode();
}

function renderRCode() {
  const sc = rScripts[rActive];
  const lines = sc.code.split('\n').length;
  const cont = document.getElementById('rContainer');
  cont.innerHTML = `
    <div class="r-toolbar">
      <span class="r-filename">${sc.name}</span>
      <span style="display:flex;gap:1rem;align-items:center;">
        <span class="r-meta">${lines} Zeilen</span>
        <a class="btn" id="rDownload" style="padding:.4rem .9rem;font-size:.82rem;">↓ Download .R</a>
      </span>
    </div>
    <div class="code-wrap"><pre class="code">${highlightR(sc.code)}</pre></div>`;
  document.getElementById('rDownload').addEventListener('click', () => {
    const blob = new Blob([sc.code], { type: 'text/plain;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = sc.name; a.click();
    URL.revokeObjectURL(a.href);
  });
}

// ============================================================
// 5) KORPUS & EXPLORER (zusammengeführt)
// ============================================================
// Alle 160 betreuten Dissertationen als Basis; die 100 Arbeiten mit histori-
// scher Einleitung werden mit ihren Analysedaten angereichert, hervorgehoben
// und per Klick zum Detailprofil geöffnet.

const kNorm = s => (s || '').toLowerCase().normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '').replace(/[^a-z]/g, '');
const kForeInit = s => { const t = (s || '').trim().split(/[\s,]+/).filter(Boolean);
  return t.length ? kNorm(t[0]).charAt(0) : ''; };

// Alle 100 Arbeiten mit historischer Einleitung sind anklickbar: die 78 in die
// Clusteranalyse eingegangenen (DISSERTATIONEN) plus die 22 als "Sonstige"
// ausgeschlossenen (HIST_EXTRA). Letztere haben kein Cluster-Label.
const ANALYZED = [...DISSERTATIONEN, ...HIST_EXTRA];

// Join-Schlüssel: Nachname | Vorname-Initial | Jahr (trennt z. B. Leo/Paul Schmitz 1929)
const _dissByKey = {};
ANALYZED.forEach(d => { _dissByKey[kNorm(d.nachname) + '|' + kForeInit(d.vorname) + '|' + d.jahr] = d; });

// Angereicherte Korpusliste: jede der 160 Zeilen, analysierte mit .diss
const KORPUS_MERGED = KORPUS.map(k => {
  const nn = k.autor.split(',')[0];
  const vn = k.autor.split(',').slice(1).join(',');
  const diss = _dissByKey[kNorm(nn) + '|' + kForeInit(vn) + '|' + k.jahr] || null;
  return { ...k, diss };
});

let kSort = 'nr', kAsc = true, kSearch = '';
let kCluster = 'all', kAnalyzedOnly = false;
const kAnalyzedCount = KORPUS_MERGED.filter(r => r.diss).length;

function renderKorpus() {
  const p = document.getElementById('panel-korpus');
  p.innerHTML = `
    <div class="panel-intro">
      <h2>Korpus &amp; Explorer</h2>
      <p>Vollständige Liste aller ${KORPUS.length} unter Alexander Tschirch betreuten Dissertationen (1889–1935). Die ${kAnalyzedCount} Arbeiten mit historischer Einleitung sind hervorgehoben und per Klick mit ihrem vollständigen Analyseprofil verknüpft. Davon gingen 78 in die Clusteranalyse ein; die übrigen sind als Stoffklasse „Sonstige“ ausgewiesen.</p>
    </div>
    <div class="explorer-actions">
      <div class="cluster-quickfilter" id="kClusterFilter">
        <button class="cluster-pill active" data-cluster="all">Alle Typen</button>
        <button class="cluster-pill" data-cluster="A">Typ A · Pflichterfüller</button>
        <button class="cluster-pill" data-cluster="B">Typ B · Namennenner</button>
        <button class="cluster-pill" data-cluster="C">Typ C · Gründlicher</button>
        <button class="cluster-pill" data-cluster="D">Typ D · Ausnahmefall</button>
      </div>
      <label class="analyzed-toggle"><input type="checkbox" id="kAnalyzedOnly"> Nur analysierte (${kAnalyzedCount})</label>
      <button class="reset-btn" id="kReset">↺ Zurücksetzen</button>
    </div>
    <div class="explorer-filters">
      <div class="filter-field"><label>Stoffklasse</label><select id="kStoff"><option value="">Alle</option></select></div>
      <div class="filter-field"><label>Herkunftsland</label><select id="kHerk"><option value="">Alle</option></select></div>
      <div class="filter-field"><label>Zeitkontext</label><select id="kZeit"><option value="">Alle</option></select></div>
      <div class="filter-field"><label>Stellenwert</label><select id="kStell"><option value="">Alle</option><option value="1">1 – gering</option><option value="2">2 – mittel</option><option value="3">3 – zentral</option></select></div>
      <div class="filter-field"><label>Sprachregister</label><select id="kSprache"><option value="">Alle</option></select></div>
      <div class="filter-field"><label>Narrative Form</label><select id="kNarr"><option value="">Alle</option></select></div>
      <div class="filter-field"><label>Suche (Autor / Titel / Jahr)</label><input type="text" id="kSearch" placeholder="z. B. Halbey, Rhabarber, 1902…"></div>
    </div>
    <div class="merged-legend" id="kStats"></div>
    <div class="korpus-table-wrap"><table class="korpus-table merged" id="kTable"><thead><tr>
      <th data-sort="nr" class="sorted asc">Nr.</th><th data-sort="autor">Autor:in</th>
      <th data-sort="titel">Titel</th><th data-sort="jahr">Jahr</th>
      <th data-sort="land">Herkunft</th><th data-sort="stellenwert">Stellenwert</th>
      <th data-sort="anteil">Anteil hist.</th><th data-sort="cluster">Typ</th>
    </tr></thead><tbody id="kBody"></tbody></table></div>`;

  // Filter-Dropdowns aus allen analysierten Datensätzen befüllen
  const uniq = (field, split=false) => {
    const set = new Set();
    ANALYZED.forEach(d => { const v = d[field]; if (!v || v === 'NA') return;
      split ? v.split(',').forEach(x => set.add(x.trim())) : set.add(v); });
    return [...set].sort((a,b) => a.localeCompare(b,'de'));
  };
  const fill = (id, vals) => { const s = document.getElementById(id);
    vals.forEach(v => { const o = document.createElement('option'); o.value = v; o.textContent = v; s.appendChild(o); }); };
  fill('kStoff', uniq('stoffklasse')); fill('kHerk', uniq('herkunft'));
  fill('kZeit', uniq('zeitkontext')); fill('kSprache', uniq('sprachregister', true)); fill('kNarr', uniq('narrativ', true));

  let t;
  document.getElementById('kSearch').addEventListener('input', e => {
    clearTimeout(t); t = setTimeout(() => { kSearch = e.target.value; renderKTable(); }, 150); });
  ['kStoff','kHerk','kZeit','kStell','kSprache','kNarr'].forEach(id =>
    document.getElementById(id).addEventListener('change', renderKTable));
  document.getElementById('kAnalyzedOnly').addEventListener('change', e => {
    kAnalyzedOnly = e.target.checked; renderKTable(); });
  document.querySelectorAll('#kTable th').forEach(th => th.addEventListener('click', () => {
    const k = th.dataset.sort; if (kSort === k) kAsc = !kAsc; else { kSort = k; kAsc = true; } renderKTable();
  }));
  document.getElementById('kClusterFilter').addEventListener('click', e => {
    if (!e.target.classList.contains('cluster-pill')) return;
    document.querySelectorAll('#kClusterFilter .cluster-pill').forEach(x => x.classList.remove('active'));
    e.target.classList.add('active'); kCluster = e.target.dataset.cluster; renderKTable();
  });
  document.getElementById('kReset').addEventListener('click', () => {
    ['kStoff','kHerk','kZeit','kStell','kSprache','kNarr'].forEach(id => document.getElementById(id).value = '');
    document.getElementById('kSearch').value = ''; kSearch = '';
    document.getElementById('kAnalyzedOnly').checked = false; kAnalyzedOnly = false;
    kCluster = 'all'; kSort = 'nr'; kAsc = true;
    document.querySelectorAll('#kClusterFilter .cluster-pill').forEach(x => x.classList.remove('active'));
    document.querySelector('#kClusterFilter .cluster-pill[data-cluster="all"]').classList.add('active');
    renderKTable();
  });
  renderKTable();
}

// Aktive Analyse-Filter (über Cluster hinaus)?
function kAnalysisFilterActive() {
  const g = id => document.getElementById(id).value;
  return kCluster !== 'all' || kAnalyzedOnly ||
    g('kStoff') || g('kHerk') || g('kZeit') || g('kStell') || g('kSprache') || g('kNarr');
}

function renderKTable() {
  const g = id => document.getElementById(id).value;
  const s = kSearch.toLowerCase().trim();
  const analysisActive = kAnalysisFilterActive();

  let rows = KORPUS_MERGED.filter(r => {
    // Analyse-Filter blenden nicht-analysierte Zeilen aus (sie haben keine Werte)
    if (analysisActive && !r.diss) return false;
    const d = r.diss;
    if (kCluster !== 'all' && (!d || d.cluster !== kCluster)) return false;
    if (g('kStoff') && (!d || d.stoffklasse !== g('kStoff'))) return false;
    if (g('kHerk') && (!d || d.herkunft !== g('kHerk'))) return false;
    if (g('kZeit') && (!d || d.zeitkontext !== g('kZeit'))) return false;
    if (g('kStell') && (!d || String(d.stellenwert) !== g('kStell'))) return false;
    if (g('kSprache') && (!d || !d.sprachregister.split(',').map(x=>x.trim()).includes(g('kSprache')))) return false;
    if (g('kNarr') && (!d || !d.narrativ.split(',').map(x=>x.trim()).includes(g('kNarr')))) return false;
    if (s && !`${r.autor} ${r.titel} ${r.jahr}`.toLowerCase().includes(s)) return false;
    return true;
  });

  rows.sort((a,b) => {
    let av, bv;
    if (kSort === 'stellenwert') { av = a.diss ? a.diss.stellenwert : -1; bv = b.diss ? b.diss.stellenwert : -1; }
    else if (kSort === 'anteil') { av = a.diss ? a.diss.anteil_hist : -1; bv = b.diss ? b.diss.anteil_hist : -1; }
    else if (kSort === 'cluster') { av = (a.diss && a.diss.cluster) ? a.diss.cluster : '\uffff'; bv = (b.diss && b.diss.cluster) ? b.diss.cluster : '\uffff'; }
    else { av = a[kSort]; bv = b[kSort]; }
    if (typeof av === 'string') return kAsc ? av.localeCompare(bv,'de') : bv.localeCompare(av,'de');
    return kAsc ? av-bv : bv-av;
  });

  const body = document.getElementById('kBody');
  if (!rows.length) {
    body.innerHTML = '<tr class="empty-row"><td colspan="8">Keine Dissertationen entsprechen diesen Filtern.</td></tr>';
  } else {
    body.innerHTML = '';
    rows.forEach(r => {
      const d = r.diss;
      const tr = document.createElement('tr');
      if (d) {
        tr.className = 'analyzed';
        const badge = d.cluster
          ? `<span class="cluster-badge" data-c="${d.cluster}">${d.cluster}</span>`
          : `<span class="cluster-badge none" title="nicht geclustert (Stoffklasse Sonstige)">–</span>`;
        tr.innerHTML = `<td class="k-nr">${r.nr}</td><td class="k-autor">${esc(r.autor)}</td>
          <td class="k-titel">${esc(r.titel)}</td><td class="k-jahr">${r.jahr}</td>
          <td><span class="land-badge">${esc(r.land)}</span></td>
          <td>${dots(d.stellenwert)}</td>
          <td class="k-anteil">${d.anteil_hist.toFixed(1)} %</td>
          <td>${badge}</td>`;
        tr.addEventListener('click', () => openDissDetail(d));
      } else {
        tr.innerHTML = `<td class="k-nr">${r.nr}</td><td class="k-autor">${esc(r.autor)}</td>
          <td class="k-titel">${esc(r.titel)}</td><td class="k-jahr">${r.jahr}</td>
          <td><span class="land-badge">${esc(r.land)}</span></td>
          <td class="k-empty">–</td><td class="k-empty">–</td><td class="k-empty">–</td>`;
      }
      body.appendChild(tr);
    });
  }

  const nAnalyzed = rows.filter(r => r.diss).length;
  document.getElementById('kStats').innerHTML =
    `<span class="legend-swatch analyzed"></span> ${nAnalyzed} analysiert &amp; klickbar` +
    `<span class="legend-sep">·</span>` +
    `<span>${rows.length} von ${KORPUS.length} Dissertationen sichtbar</span>`;

  document.querySelectorAll('#kTable th').forEach(th => { th.classList.remove('sorted','asc');
    if (th.dataset.sort === kSort) { th.classList.add('sorted'); if (kAsc) th.classList.add('asc'); } });
}

// ============================================================
// 6) PERSONENRANKING
// ============================================================
const tradColors = {
  'Griechisch-römische Antike': '#8FB0CE', 'Byzantinische Medizin': '#9BC2C2',
  'Arabisch-islamische Medizin': '#E0B978', 'Frühneuzeitliche Botanik': '#A9C99B',
  'Frühneuzeitliche Pharmakochemie': '#C9A9D4', 'Chemie & Pharmazie 19. Jh.': '#D98B95',
  'Geographie & Handelswege': '#B0A89C', 'Mythisch / Frühgeschichte': '#E5D5A3'
};
let tradActive = 'all';
function renderPersonen() {
  const p = document.getElementById('panel-personen');
  const trads = [...new Set(PERSONEN.map(x => x.tradition))];
  let chips = `<div class="trad-chip active" data-trad="all">Alle Traditionen</div>`;
  trads.forEach(t => chips += `<div class="trad-chip" data-trad="${esc(t)}"><span class="trad-dot" style="background:${tradColors[t]||'#ccc'}"></span>${esc(t)}</div>`);
  p.innerHTML = `
    <div class="panel-intro">
      <h2>Personenranking</h2>
      <p>Alle historischen Autoritäten mit mindestens drei Nennungen in den Einleitungen (53 Personen), gefärbt nach pharmaziehistorischer Traditionslinie. Filtern Sie nach Tradition.</p>
    </div>
    <div class="trad-filter" id="tradFilter">${chips}</div>
    <div class="personen-grid" id="personenGrid"></div>`;
  document.getElementById('tradFilter').addEventListener('click', e => {
    const chip = e.target.closest('.trad-chip'); if (!chip) return;
    document.querySelectorAll('.trad-chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active'); tradActive = chip.dataset.trad; renderPersonenGrid();
  });
  renderPersonenGrid();
}
function renderPersonenGrid() {
  const grid = document.getElementById('personenGrid');
  const rows = PERSONEN.filter(p => tradActive === 'all' || p.tradition === tradActive);
  grid.innerHTML = rows.map((p, i) => {
    const rank = PERSONEN.indexOf(p) + 1;
    return `<div class="person-card">
      <div class="person-rank">${rank}</div>
      <div class="person-info">
        <div class="person-name">${esc(p.name)}</div>
        <div class="person-trad"><span class="trad-dot" style="background:${tradColors[p.tradition]||'#ccc'}"></span>${esc(p.tradition)}</div>
      </div>
      <div class="person-count">${p.nennungen}</div>
    </div>`;
  }).join('');
}

// ============================================================
// Global keyboard
// ============================================================
document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  if (figModal.classList.contains('active')) closeFigModal();
  if (dissModal.classList.contains('active')) { dissModal.classList.remove('active'); document.body.style.overflow=''; }
  if (hermOverlay.classList.contains('active')) closeHermDetail();
});

// Init first panel
renderHome();
rendered.home = true;
