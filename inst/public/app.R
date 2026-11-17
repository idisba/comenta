library(Comenta)
# ============================================================
# AnotaR - Versió PÚBLICA
# Per destinataris externs - Sense persistència al servidor
# ============================================================

library(shiny)
library(bs4Dash)
library(jsonlite)
library(httr)
library(shinyjs)
library(htmltools)
library(base64enc)
options(shiny.maxRequestSize=30*1024^2)

# Carregar helpers d'IA (ja disponibles via library(Comenta))
ia_gemini_disponible <- gemini_disponible()
if (ia_gemini_disponible) {
  cat("✓ Gemini AI disponible\n")
}

ia_ollama_disponible <- ollama_disponible()
if (ia_ollama_disponible) {
  cat("✓ Ollama AI disponible\n")
} else {
  cat("⚠️ Ollama no disponible (opcional)\n")
}

# Variables globals de sessió (en memòria, no es guarden)
# Cada usuari té la seva pròpia sessió independent

# JavaScript per anotacions interactives
JS_VISOR_LIVE <- "
<style>
    p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure {
        position: relative; cursor: pointer; transition: background 0.15s; padding: 5px; margin: 8px 0;
    }
    p:hover, h1:hover, h2:hover, h3:hover, h4:hover, h5:hover, h6:hover, li:hover, table:hover, .plotly-graph-div:hover, figure:hover {
        background-color: rgba(52, 152, 219, 0.08);
        border-left: 3px solid #3498db;
    }
    /* Estils específics per taules */
    td, th {
        min-width: 100px;
        vertical-align: top;
        padding: 8px;
    }
    table {
        position: relative;
        cursor: pointer;
        border-collapse: collapse;
        margin: 10px 0;
    }
    /* Estil per comentaris de taules - apareixen just després */
    table + .contenidor-notes {
        display: block !important;
        position: static !important;
        margin: 0 0 20px 0 !important;
        padding: 15px 20px;
        background: linear-gradient(to right, #f0fdf4 0%, #ffffff 100%);
        border-left: 4px solid #10b981;
        border-radius: 0 8px 8px 0;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        transform: none !important;
        left: auto !important;
        top: auto !important;
        z-index: auto !important;
        max-width: 100% !important;
        min-width: 0 !important;
    }
    table + .contenidor-notes .nota-flotant-hyp {
        background: white;
        padding: 12px 16px;
        border-radius: 6px;
        border: 1px solid #d1fae5;
        margin: 8px 0;
    }
    table td, table th {
        padding: 8px;
    }
    /* Estils específics per gràfics */
    .plotly-graph-div, figure {
        min-height: 50px;
        border: 1px dashed transparent;
    }
    .plotly-graph-div:hover, figure:hover {
        border: 1px dashed #3498db;
    }
    .plotly-graph-div .contenidor-notes, figure .contenidor-notes {
        position: relative;
        z-index: 100; /* Sobre el gràfic */
        background: rgba(255, 255, 255, 0.95);
        margin-top: 10px;
        padding: 10px;
        border-radius: 55px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }
    .contenidor-notes {
        display: block; margin-top: 8px; padding-left: 12px;
        border-left: 3px solid #e74c3c; background: #fff9f9;
    }
    .nota-flotant-hyp {
        border: 1px solid #e2e8f0; border-radius: 6px;
        padding: 8px 12px; background: #ffffff; margin: 5px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.08); color: #2c3e50;
        font-size: 13px; font-family: sans-serif; display: block;
    }
    .nota-flotant-hyp:hover { background: #f8f9fa; cursor: pointer; }
    .nota-usuari {
        font-size: 11px; color: #dc3545; font-weight: 600;
        font-style: italic; margin-bottom: 4px; display: block;
    }
    .textarea-simple {
        width: 100%; min-width: 400px; min-height: 80px; font-family: sans-serif;
        font-size: 14px; resize: vertical; border: 1px solid #cbd5e1;
        border-radius: 4px; padding: 8px; outline: none;
        box-sizing: border-box; line-height: 1.5;
    }
    .textarea-simple:focus { border-color: #3498db; box-shadow: 0 0 0 3px rgba(52, 152, 219, 0.1); }
    .btn-guardar {
        margin-top: 5px; padding: 6px 12px; background: #3498db;
        color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;
        margin-right: 5px;
    }
    .btn-guardar:hover { background: #2980b9; }
    .btn-cancelar {
        margin-top: 5px; padding: 6px 12px; background: #95a5a6;
        color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;
    }
    .btn-cancelar:hover { background: #7f8c8d; }
    a {
        cursor: pointer;
        text-decoration: underline;
        color: #3498db;
    }
    a:hover {
        color: #2980b9;
    }
</style>
<script>
    // Funció per obtenir el nom d'usuari actual dinàmicament
    function obtenirNomUsuari() {
        try {
            // Intentar llegir del camp de text de Shiny
            if (window.parent && window.parent.Shiny && window.parent.Shiny.inputBindings) {
                const nomInput = window.parent.document.getElementById('nom_usuari');
                if (nomInput && nomInput.value && nomInput.value.trim() !== '') {
                    return nomInput.value.trim();
                }
            }
        } catch(e) {
            // Si falla, usar el valor per defecte
        }
        // Fallback al valor inicial o Anònim
        return TEXT_NOM_USUARI || 'Anònim';
    }

    function indexarElements() {
        // Indexar elements: paràgrafs, títols, taules, gràfics i widgets de datatables (R DT)
        document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure, .datatables.html-widget').forEach(function(el, idx) {
            // FIX DATATABLES: No indexar taules dins de widgets datatables (es generen dinàmicament)
            if (el.tagName === 'TABLE') {
                // Si està dins d'un widget de datatables, saltar-la (ja indexem el widget)
                if (el.closest('.datatables.html-widget')) {
                    console.log('⏭️ Saltant taula dins de widget datatables');
                    return;
                }
                // Si està dins d'un div de scroll de DataTables, saltar-la
                const parent = el.parentElement;
                if (parent && (
                    parent.classList.contains('dataTables_scrollHead') ||
                    parent.classList.contains('dataTables_scrollBody') ||
                    parent.classList.contains('dataTables_scrollFoot') ||
                    parent.classList.contains('dataTables_wrapper')
                )) {
                    console.log('⏭️ Saltant taula clonada de DataTables');
                    return;
                }
            }
            el.setAttribute('data-element-idx', idx);
        });
        console.log('✅ Elements indexats (incl. widgets datatables)');
    }

    function carregarNotes() {
        const notesVelles = TEXT_JSON_NOTES;
        if(notesVelles && notesVelles.length > 0) {
            notesVelles.forEach(n => {
                if(n.element_idx !== undefined && n.text) {
                    dibuixarNotaAncorada(n.element_idx, n.text, n.id, n.usuari || 'Anònim');
                }
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            indexarElements();
            carregarNotes();
            // Re-indexar després de 1 segon (per datatables que es generen dinàmicament)
            setTimeout(function() {
                console.log('🔄 Re-indexant (per datatables dinàmiques)...');
                indexarElements();
                carregarNotes();
            }, 1000);
        });
    } else {
        indexarElements();
        carregarNotes();
        // Re-indexar després de 1 segon (per datatables que es generen dinàmicament)
        setTimeout(function() {
            console.log('🔄 Re-indexant (per datatables dinàmiques)...');
            indexarElements();
            carregarNotes();
        }, 1000);
    }

    // Observer per detectar noves datatables que es generen
    const observer = new MutationObserver(function(mutations) {
        let haCanvis = false;
        mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
                if (node.nodeType === 1) { // Element node
                    if (node.classList && node.classList.contains('dataTables_wrapper')) {
                        haCanvis = true;
                    }
                }
            });
        });
        if (haCanvis) {
            console.log('🔄 Nova DataTable detectada, re-indexant...');
            setTimeout(function() {
                indexarElements();
            }, 500);
        }
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });

    document.addEventListener('click', function(e) {
        if (e.target.tagName === 'A' || e.target.closest('a')) {
            const link = e.target.tagName === 'A' ? e.target : e.target.closest('a');
            const href = link.getAttribute('href');

            if (href && href.startsWith('#')) {
                e.preventDefault();
                const targetId = href.substring(1);
                const targetElement = document.getElementById(targetId);
                if (targetElement) {
                    targetElement.scrollIntoView({ behavior: 'smooth' });
                }
                return;
            }

            if (href && (href.startsWith('http') || href.startsWith('www'))) {
                e.preventDefault();
                window.open(href, '_blank');
                return;
            }
        }

        if (e.target.closest('.contenidor-notes') || e.target.closest('.nota-flotant-hyp')) return;

        // FIX DATATABLES R (DT): Si cliquem dins d'un widget de datatables, usar el widget
        const datatableWidget = e.target.closest('.datatables.html-widget');
        if (datatableWidget) {
            console.log('🔍 Clic dins de widget datatables R (DT)');
            const idx = parseInt(datatableWidget.getAttribute('data-element-idx'));
            if (!isNaN(idx)) {
                console.log('✅ Usant widget datatables, idx:', idx);
                // Usar el widget com a element
                let element = datatableWidget;

                // Crear contenidor després del widget
                let contenidor = element.parentNode.querySelector('.contenidor-notes[data-for-idx=\"' + idx + '\"]');
                if (!contenidor) {
                    contenidor = document.createElement('div');
                    contenidor.classList.add('contenidor-notes');
                    contenidor.setAttribute('data-for-idx', idx);
                    element.parentNode.insertBefore(contenidor, element.nextSibling);
                }

                if (contenidor.querySelector('.textarea-simple')) return;

                const editorDiv = document.createElement('div');
                editorDiv.innerHTML = '<textarea class=\"textarea-simple\" placeholder=\"Escriu un comentari...\"></textarea><button class=\"btn-guardar\">Guardar</button><button class=\"btn-cancelar\">Cancel·lar</button>';
                contenidor.appendChild(editorDiv);

                const textarea = editorDiv.querySelector('.textarea-simple');
                const btnGuardar = editorDiv.querySelector('.btn-guardar');
                const btnCancelar = editorDiv.querySelector('.btn-cancelar');

                textarea.focus();

                btnGuardar.addEventListener('click', function() {
                    console.log('🔘 BTN GUARDAR CLICAT (datatables widget)');
                    const text = textarea.value.trim();
                    console.log('   Text:', text.substring(0, 50));
                    console.log('   idx:', idx);

                    if (text === '') {
                        console.warn('⚠️ Text buit');
                        contenidor.removeChild(editorDiv);
                        return;
                    }

                    const temporalId = 'temp_' + Date.now();
                    const nomUsuari = obtenirNomUsuari();
                    console.log('💾 Guardant...');
                    console.log('   ID temporal:', temporalId);
                    console.log('   Usuari:', nomUsuari);

                    dibuixarNotaAncorada(idx, text, temporalId, nomUsuari);
                    contenidor.removeChild(editorDiv);

                    if (window.parent && window.parent.Shiny) {
                        console.log('📡 Enviant a Shiny (guardar_anotacio)...');
                        window.parent.Shiny.setInputValue('guardar_anotacio', {
                            id: temporalId,
                            text: text,
                            element_idx: idx,
                            _timestamp: Date.now()
                        });
                        console.log('✅ Enviat!');
                    } else {
                        console.error('❌ window.parent.Shiny no disponible');
                    }
                });

                btnCancelar.addEventListener('click', function() {
                    contenidor.removeChild(editorDiv);
                });

                return; // Sortir aquí, ja hem gestionat el clic
            }
        }

        // Buscar element clickable (taules senceres, NO cel·les individuals)
        let element = e.target.closest('p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure');

        if (!element) {
            console.log('⚠️ Element no clickable');
            return;
        }

        const idx = parseInt(element.getAttribute('data-element-idx'));
        console.log('✅ CLIC:', element.tagName, 'idx:', idx);

        if (isNaN(idx)) {
            console.error('❌ idx no vàlid!');
            return;
        }

        // Crear contenidor (per taules, posar-lo després)
        let contenidor = element.querySelector('.contenidor-notes');
        if (!contenidor) {
            contenidor = document.createElement('div');
            contenidor.classList.add('contenidor-notes');
            if (element.tagName === 'TABLE') {
                // Per taules, posar el contenidor després de la taula
                element.parentNode.insertBefore(contenidor, element.nextSibling);
            } else {
                element.appendChild(contenidor);
            }
        }

        if (contenidor.querySelector('.textarea-simple')) return;

        const editorDiv = document.createElement('div');
        editorDiv.innerHTML = '<textarea class=\"textarea-simple\" placeholder=\"Escriu un comentari...\"></textarea><button class=\"btn-guardar\">Guardar</button><button class=\"btn-cancelar\">Cancel·lar</button>';
        contenidor.appendChild(editorDiv);

        const txtArea = editorDiv.querySelector('.textarea-simple');
        txtArea.focus();

        editorDiv.querySelector('.btn-guardar').addEventListener('click', function() {
            console.log('🔘 BTN GUARDAR CLICAT!');
            const text = txtArea.value.trim();
            console.log('   Text a guardar:', text.substring(0, 50) + '...');
            console.log('   Longitud:', text.length);
            console.log('   Element idx:', idx);

            if (text === '') {
                console.warn('⚠️ Text buit, no guardant');
                editorDiv.remove();
                if (contenidor.children.length === 0) contenidor.remove();
                return;
            }

            const temporalId = 'temp_' + Date.now();
            const nomUsuari = obtenirNomUsuari();
            console.log('💾 Guardant:', text.substring(0, 30) + '...');
            console.log('   ID temporal:', temporalId);
            console.log('   Usuari:', nomUsuari);

            dibuixarNotaAncorada(idx, text, temporalId, nomUsuari);
            editorDiv.remove();

            if (window.parent && window.parent.Shiny) {
                console.log('📡 Enviant a Shiny...');
                window.parent.Shiny.setInputValue('guardar_anotacio', {
                    id: temporalId,
                    text: text,
                    element_idx: idx,
                    _timestamp: Date.now()
                });
                console.log('✅ Event enviat a Shiny!');
            } else {
                console.error('❌ window.parent.Shiny no disponible!');
            }
        });

        editorDiv.querySelector('.btn-cancelar').addEventListener('click', function() {
            editorDiv.remove();
            if (contenidor.children.length === 0) contenidor.remove();
        });
    });

    function dibuixarNotaAncorada(elementIdx, text, id, usuari) {
        const element = document.querySelector('[data-element-idx=\"' + elementIdx + '\"]');
        if (!element) {
            console.error('❌ Element no trobat per idx:', elementIdx);
            return;
        }

        console.log('✅ Dibuixant nota:', element.tagName || element.className, 'idx:', elementIdx);

        // Crear/buscar contenidor (per taules i widgets datatables, posar-lo després)
        let contenidor = element.querySelector('.contenidor-notes');
        const esTaulaOWidget = element.tagName === 'TABLE' || element.classList.contains('datatables');

        if (!contenidor) {
            // Buscar contenidor amb data-for-idx (per widgets datatables)
            let nextSibling = element.nextSibling;
            while (nextSibling) {
                if (nextSibling.classList && nextSibling.classList.contains('contenidor-notes')) {
                    const forIdx = nextSibling.getAttribute('data-for-idx');
                    if (forIdx && parseInt(forIdx) === elementIdx) {
                        contenidor = nextSibling;
                        break;
                    }
                }
                nextSibling = nextSibling.nextSibling;
            }

            // Si no s'ha trobat, crear-ne un de nou
            if (!contenidor) {
                contenidor = document.createElement('div');
                contenidor.classList.add('contenidor-notes');
                if (esTaulaOWidget) {
                    contenidor.setAttribute('data-for-idx', elementIdx);
                    element.parentNode.insertBefore(contenidor, element.nextSibling);
                } else {
                    element.appendChild(contenidor);
                }
            }
        }

        const nota = document.createElement('div');
        nota.classList.add('nota-flotant-hyp');

        if (usuari) {
            const usuariSpan = document.createElement('span');
            usuariSpan.classList.add('nota-usuari');
            usuariSpan.textContent = '👤 ' + usuari;
            nota.appendChild(usuariSpan);
        }

        const textNode = document.createTextNode(text);
        nota.appendChild(textNode);

        nota.setAttribute('data-id', id);
        nota.title = 'Doble clic per esborrar';

        nota.addEventListener('dblclick', function(e) {
            e.stopPropagation();
            const notaId = this.getAttribute('data-id');
            this.remove();

            if (contenidor.children.length === 0) contenidor.remove();

            if (window.parent && window.parent.Shiny) {
                window.parent.Shiny.setInputValue('id_a_esborrar', {
                    id: notaId,
                    _timestamp: Date.now()
                });
            }
        });

        contenidor.appendChild(nota);
    }
</script>
"

# JavaScript per exportacions estàtiques
JS_EXPORTACIO_ESTATIC <- "
<style>
    p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure { position: relative; padding: 5px; margin: 8px 0; }
    /* Estils específics per taules */
    table {
        border-collapse: collapse;
        margin: 10px 0;
    }
    /* Estil per comentaris de taules - just després de la taula */
    table + .contenidor-notes {
        display: block !important;
        position: static !important;
        margin: 0 0 20px 0 !important;
        padding: 15px 20px;
        background: linear-gradient(to right, #f0fdf4 0%, #ffffff 100%);
        border-left: 4px solid #10b981;
        border-radius: 0 8px 8px 0;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        transform: none !important;
        left: auto !important;
        top: auto !important;
        z-index: auto !important;
        max-width: 100% !important;
        min-width: 0 !important;
    }
    table + .contenidor-notes .nota-flotant-hyp {
        background: white;
        padding: 12px 16px;
        border-radius: 6px;
        border: 1px solid #d1fae5;
        margin: 8px 0;
    }
    /* Estils específics per gràfics */
    .plotly-graph-div .contenidor-notes, figure .contenidor-notes {
        position: relative;
        z-index: 100;
        background: rgba(255, 255, 255, 0.95);
        margin-top: 10px;
        padding: 10px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    }
    .contenidor-notes {
        display: block; margin-top: 8px; padding-left: 12px;
        border-left: 3px solid #27ae60; background: #f0fdf4;
    }
    .nota-flotant-hyp {
        border: 1px solid #d1fae5; border-radius: 6px;
        padding: 8px 12px; background: #ffffff; margin: 5px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.06); color: #2c3e50;
        font-size: 13px; font-family: sans-serif; display: block;
    }
    .nota-usuari {
        font-size: 11px; color: #27ae60; font-weight: 600;
        font-style: italic; margin-bottom: 4px; display: block;
    }
    a {
        cursor: pointer;
        text-decoration: underline;
        color: #3498db;
    }
    a:hover {
        color: #2980b9;
    }
</style>
<script>
    document.addEventListener('click', function(e) {
        if (e.target.tagName === 'A' || e.target.closest('a')) {
            const link = e.target.tagName === 'A' ? e.target : e.target.closest('a');
            const href = link.getAttribute('href');

            if (href && href.startsWith('#')) {
                e.preventDefault();
                const targetId = href.substring(1);
                const targetElement = document.getElementById(targetId);
                if (targetElement) {
                    targetElement.scrollIntoView({ behavior: 'smooth' });
                }
                return;
            }

            if (href && (href.startsWith('http') || href.startsWith('www'))) {
                e.preventDefault();
                window.open(href, '_blank');
                return;
            }
        }
    });

    function inicialitzar() {
        // INDEXACIÓ IDÈNTICA a l'app: taules senceres, NO cel·les
        document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure').forEach(function(el, idx) {
            el.setAttribute('data-element-idx', idx);
        });

        const notes = TEXT_JSON_NOTES;
        if(notes && notes.length > 0) {
            notes.forEach(n => {
                if(n.element_idx !== undefined && n.text) {
                    const element = document.querySelector('[data-element-idx=\"' + n.element_idx + '\"]');
                    if (!element) return;

                    let contenidor = element.querySelector('.contenidor-notes');
                    if (!contenidor) {
                        // Buscar contenidor després (per taules)
                        let nextSibling = element.nextSibling;
                        if (nextSibling && nextSibling.classList && nextSibling.classList.contains('contenidor-notes')) {
                            contenidor = nextSibling;
                        } else {
                            contenidor = document.createElement('div');
                            contenidor.classList.add('contenidor-notes');
                            if (element.tagName === 'TABLE') {
                                element.parentNode.insertBefore(contenidor, element.nextSibling);
                            } else {
                                element.appendChild(contenidor);
                            }
                        }
                    }

                    const nota = document.createElement('div');
                    nota.classList.add('nota-flotant-hyp');

                    if (n.usuari) {
                        const usuariSpan = document.createElement('span');
                        usuariSpan.classList.add('nota-usuari');
                        usuariSpan.textContent = '👤 ' + n.usuari;
                        nota.appendChild(usuariSpan);
                    }

                    const textNode = document.createTextNode(n.text);
                    nota.appendChild(textNode);

                    contenidor.appendChild(nota);
                }
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', inicialitzar);
    } else {
        inicialitzar();
    }
</script>
"

ui <- dashboardPage(
  header = dashboardHeader(
    title = tags$div(
      style = "display: flex; align-items: center; gap: 12px;",
      tags$img(
        src = "comenta_logo.png",
        height = "60px",
        style = "vertical-align: middle; background: white; padding: 0px; border-radius: 55px; box-shadow: 0 0px 0px rgba(0,0,0,0.15);"
      ),
      tags$div(
        style = "display: inline-block;",
        tags$div(
          style = "font-size: 32px; font-weight: 700; letter-spacing: 0.8px; color: white; font-family: 'Poppins', sans-serif; line-height: 1;",
          "Comenta"
        ),
        tags$div(
          style = "font-size: 9px; font-weight: 400; letter-spacing: 1.5px; color: rgba(255,255,255,0.85); text-transform: uppercase;",
          "versió pública · sense persistència"
        )
      )
    )
  ),
  sidebar = dashboardSidebar(
    tags$div(style = "padding: 20px 15px;",
      tags$div(
        style = "background: rgba(255, 193, 7, 0.15); padding: 12px; border-radius: 6px; border-left: 4px solid #ffc107; margin-bottom: 15px;",
        tags$div(style = "color: white; font-size: 12px; font-weight: 600; margin-bottom: 6px;", "⚠️ Avís important"),
        tags$div(style = "color: rgba(255,255,255,0.9); font-size: 10px; line-height: 1.4;",
          "Els documents i anotacions NO es guarden al servidor. Quan tanques el navegador, tot desapareix."
        )
      ),
      textInput("nom_usuari", "👤 El teu nom:"),
      hr(),
      tags$div(style = "margin-bottom: 10px;",
        tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 5px; display: block;", "📁 Puja document"),
        fileInput("pujar_html", NULL, accept = c("text/html", ".html", "application/pdf", ".pdf"),
                  buttonLabel = "Seleccionar HTML/PDF",
                  placeholder = "Cap fitxer seleccionat")
      ),
      tags$div(style = "margin: 20px 0; border-top: 2px solid rgba(255,255,255,0.3);"),

      # === Secció IA ===
      tags$div(
        style = "background: rgba(156, 39, 176, 0.2); padding: 12px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #9c27b0;",
        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
          tags$label(style = "color: white; font-weight: 600; font-size: 13px; margin: 0;", "🤖 Assistent IA"),
          actionButton("toggle_ia_config_pub", "⚙️", class = "btn-xs",
                      style = "background: rgba(255,255,255,0.3); border: none; color: white; padding: 4px 8px; border-radius: 4px;")
        ),
        conditionalPanel(
          condition = "input.toggle_ia_config_pub % 2 == 1",
          selectInput("ia_model_pub", "Model:",
                     choices = c("Selecciona..." = "", "Gemini Flash (Google)" = "gemini", "Ollama Local" = "ollama"),
                     selectize = FALSE),
          conditionalPanel(
            condition = "input.ia_model_pub == 'ollama'",
            uiOutput("ollama_model_selector_pub")
          ),
          conditionalPanel(
            condition = "input.ia_model_pub == 'gemini'",
            textInput("gemini_api_key_pub", "API Key:",
                     placeholder = "AIzaSy...",
                     value = ""),
            tags$a(href = "https://makersuite.google.com/app/apikey", target = "_blank",
                  style = "color: white; font-size: 9px; text-decoration: underline;",
                  "Obtenir API key gratuïta")
          ),
          selectInput("ia_idioma_pub", "Idioma resum:",
                     choices = c("Català" = "catala", "Español" = "espanyol", "English" = "angles"),
                     selected = "catala",
                     selectize = FALSE),
          uiOutput("ia_status_text_pub")
        ),
        textAreaInput("text_resumir_pub", "Text a analitzar:",
                     placeholder = "Enganxa text/dades d'informe aquí...",
                     rows = 3),
        tags$div(style = "display: flex; gap: 5px; margin-top: 5px;",
          actionButton("interpretar_ia_pub", "Interpretar",
                      class = "btn-success btn-sm",
                      style = "width: 100%; font-weight: 600; font-size: 11px;"),
          actionButton("analitzar_ia_pub", "Analitzar",
                      class = "btn-success btn-sm",
                      style = "width: 100%; font-weight: 600; font-size: 11px;")),
        tags$div(style = "display: flex; gap: 5px; margin-top: 5px;",
          actionButton("recomanar_ia_pub", "Recomanar",
                      class = "btn-success btn-sm",
                      style = "width: 100%; font-weight: 600; font-size: 11px;"),
        actionButton("resumir_ia_pub", "Resumir",
                    class = "btn-success btn-sm",
                    style = "width: 100%; font-weight: 600; font-size: 11px;")),
        tags$div(id = "resum_resultat_pub",
                style = "margin-top: 10px; padding: 8px; background: rgba(255,255,255,0.95); border-radius: 6px; display: none; color: #2c3e50; font-size: 11px;")
      ),

      tags$div(style = "margin: 20px 0; border-top: 2px solid rgba(255,255,255,0.3);"),
      tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 10px; display: block;", "💾 Descarregar"),
      downloadButton("descarregar_html", "Descarregar HTML anotat",
                    icon = icon("download"),
                    class = "btn-success",
                    style = "width: 100%; margin: 0;"),
      br(), br(),
      textOutput("avis")
    ),
    width = "350px"
  ),
  body = dashboardBody(
    tags$head(
      tags$style(HTML("
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

        body, .sidebar, .main-header {
          font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif !important;
        }

        .main-sidebar {
          background: linear-gradient(180deg, #17a2b8 0%, #138496 100%) !important;
          box-shadow: 2px 0 10px rgba(0,0,0,0.1);
        }

        .sidebar label {
          color: #ffffff !important;
          font-weight: 500;
          font-size: 13px;
        }

        .sidebar .form-control,
        .sidebar .selectize-input {
          background-color: #ffffff;
          color: #2c3e50;
          border-radius: 8px;
          border: none;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .sidebar .btn-success {
          background: #ffffff !important;
          color: #28a745 !important;
          border: none;
          font-weight: 600;
          border-radius: 8px;
          padding: 10px 20px;
        }

        .sidebar .btn-success:hover {
          background: #f8f9fa !important;
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }

        #avis {
          color: #ffffff;
          background: rgba(255, 255, 255, 0.15);
          padding: 10px;
          border-radius: 8px;
          font-size: 11px;
          text-align: center;
        }

        .main-header {
          background: linear-gradient(135deg, #17a2b8 0%, #138496 100%) !important;
          box-shadow: 0 2px 10px rgba(23, 162, 184, 0.2);
        }

        .content-wrapper {
          background-color: #f5f6fa;
        }

        iframe {
          border: 1px solid #e9ecef !important;
          border-radius: 8px !important;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
        }
      "))
    ),
    useShinyjs(),

    # Carregar JavaScript d'auto-interpretació
    tags$head(
      tags$script(src = "auto_interpret.js")
    ),

    box(
      width = 12,
      status = NULL,
      solidHeader = FALSE,
      collapsible = FALSE,
      uiOutput("visor")
    ),
    tags$div(
      style = "position: fixed; bottom: 0; left: 0; right: 0; background: rgba(255,255,255,0.95); padding: 10px; text-align: center; font-size: 11px; color: #666; border-top: 1px solid #dee2e6; z-index: 1000; backdrop-filter: blur(5px);",
      HTML('AnotaR v1.0.0 | <a href="https://github.com/josepmuncunill/AnotaR" target="_blank" style="color: #007bff;">GitHub</a> | MIT License | IDISBA Bioinformàtica')
    )
  )
)

server <- function(input, output, session) {
  # Crear directori temporal per PDFs de sessió
  dir_temp_session <- file.path("www", "temp", session$token)
  if (!dir.exists(dir_temp_session)) {
    dir.create(dir_temp_session, recursive = TRUE)
  }

  # Netejar al tancar sessió
  session$onSessionEnded(function() {
    if (dir.exists(dir_temp_session)) {
      unlink(dir_temp_session, recursive = TRUE)
    }
  })

  # Variables reactives de sessió (només en memòria)
  document_html <- reactiveVal(NULL)
  nom_document <- reactiveVal(NULL)
  tipus_document <- reactiveVal(NULL) # "html" o "pdf"
  pdf_base64 <- reactiveVal(NULL) # PDF codificat en base64
  pdf_temp_path <- reactiveVal(NULL) # Ruta temporal del PDF

  anotacions <- reactiveVal(data.frame(
    id = character(),
    text = character(),
    element_idx = integer(),
    usuari = character(),
    tipus = character(),
    pagina = integer(),
    x = numeric(),
    y = numeric(),
    stringsAsFactors = FALSE
  ))

  status <- reactiveVal("")

  # === Secció IA ===

  # Selector de models Ollama
  output$ollama_model_selector_pub <- renderUI({
    if (ia_ollama_disponible) {
      models <- ollama_llistar_models()

      if (length(models) > 0) {
        model_recomanat <- ollama_model_recomanat()

        selectInput("ollama_model_pub", "Model Ollama:",
                   choices = setNames(models, models),
                   selected = model_recomanat,
                   selectize = FALSE)
      } else {
        tags$div(
          style = "color: rgba(255,255,255,0.9); font-size: 10px; padding: 5px;",
          "⚠️ Cap model instal·lat"
        )
      }
    } else {
      tags$div(
        style = "color: rgba(255,255,255,0.9); font-size: 10px; padding: 5px;",
        "❌ Ollama no disponible"
      )
    }
  })

  # Estat de configuració IA
  output$ia_status_text_pub <- renderUI({
    model <- input$ia_model_pub

    if (is.null(model) || model == "") {
      return(tags$div(
        style = "color: rgba(255,255,255,0.85); font-size: 9px; margin-top: 8px;",
        "Selecciona un model per activar l'assistent IA"
      ))
    }

    if (model == "gemini") {
      api_key <- input$gemini_api_key_pub

      if (is.null(api_key) || api_key == "") {
        return(tags$div(
          style = "color: #ffc107; font-size: 9px; margin-top: 8px;",
          "⚠️ Introdueix l'API key de Gemini"
        ))
      } else {
        return(tags$div(
          style = "color: #4caf50; font-size: 9px; margin-top: 8px;",
          "✅ Gemini configurat (gratuït, 1M tokens/mes)"
        ))
      }
    } else if (model == "ollama") {
      if (ia_ollama_disponible) {
        return(tags$div(
          style = "color: #4caf50; font-size: 9px; margin-top: 8px;",
          "✅ Ollama disponible (100% local, privat)"
        ))
      } else {
        return(tags$div(
          style = "color: #ffc107; font-size: 9px; margin-top: 8px;",
          "❌ Ollama no disponible"
        ))
      }
    }
  })

  # Resumir amb IA
  observeEvent(input$resumir_ia_pub, {
    req(input$text_resumir_pub)
    text <- trimws(input$text_resumir_pub)

    if (text == "" || nchar(text) < 50) {
      showNotification(
        "⚠️ Escriu text per resumir (mínim 50 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_pub

    if (is.null(model) || model == "") {
      showNotification(
        "⚠️ Selecciona un model d'IA primer",
        type = "warning",
        duration = 3
      )
      return()
    }

    withProgress(message = '🤖 Resumint amb IA...', value = 0, {
      tryCatch({
        incProgress(0.2, detail = "Preparant...")

        resum <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_pub

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          incProgress(0.3, detail = "Enviant a Gemini...")

          resum <- resumir_text_gemini(
            text = text,
            max_paraules = 150,
            idioma = input$ia_idioma_pub %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_pub

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          incProgress(0.3, detail = paste0("Processant amb ", ollama_model, "..."))

          resum <- resumir_text_ollama(
            text = text,
            model = ollama_model,
            max_paraules = 150,
            idioma = input$ia_idioma_pub %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.4, detail = "Rebent resum...")

        if (!is.null(resum) && nchar(resum) > 0) {
          # Mostrar resum en un div especial
          runjs(sprintf("
            $('#resum_resultat_pub').html('<strong>📝 Resum generat:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", resum))))

          incProgress(0.3, detail = "Afegint anotació automàticament...")

          # Afegir resum automàticament com anotació al document
          text_net <- gsub("\\s+", " ", trimws(text))
          paraules <- strsplit(text_net, " ")[[1]]
          # Primeres 8 paraules per buscar
          text_buscar <- paste(paraules[1:min(8, length(paraules))], collapse = " ")

          # Netejar resum per JavaScript (escapar cometes i salts de línia)
          resum_safe <- gsub("'", "\\\\'", gsub('"', '\\\\"', gsub("\n", " ", resum)))
          text_buscar_safe <- gsub("'", "\\\\'", gsub('"', '\\\\"', text_buscar))

          # JavaScript per buscar i afegir anotació automàticament
          js_code <- sprintf("
            try {
              var iframe = document.querySelector('iframe');
              if (!iframe || !iframe.contentWindow) {
                console.error('No s\\'ha trobat l\\'iframe');
                return;
              }

              var doc = iframe.contentDocument || iframe.contentWindow.document;
              var textBuscar = '%s';
              var resum = '%s';
              var nomUsuari = $('#nom_usuari').val() || 'IA';

              // Buscar element que conté el text
              var elements = doc.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, td, th, .plotly-graph-div, figure');
              var elementTrobat = null;

              for (var i = 0; i < elements.length; i++) {
                var el = elements[i];
                var textElement = el.textContent || el.innerText || '';
                // Normalitzar espais
                textElement = textElement.replace(/\\s+/g, ' ').trim();

                if (textElement.indexOf(textBuscar) !== -1) {
                  elementTrobat = el;
                  break;
                }
              }

              if (!elementTrobat) {
                console.warn('No s\\'ha trobat element amb el text');
                Shiny.setInputValue('ia_anotacio_error', {
                  error: 'No s\\'ha trobat el text al document',
                  _timestamp: Date.now()
                });
                return;
              }

              // Obtenir índex de l'element
              var idx = parseInt(elementTrobat.getAttribute('data-element-idx'));
              if (isNaN(idx)) {
                console.error('Element sense data-element-idx');
                return;
              }

              // Crear anotació directament (simular funció dibuixarNotaAncorada de l'iframe)
              var contenidor = elementTrobat.querySelector('.contenidor-notes');
              if (!contenidor) {
                contenidor = doc.createElement('div');
                contenidor.classList.add('contenidor-notes');
                elementTrobat.appendChild(contenidor);
              }

              var nota = doc.createElement('div');
              nota.classList.add('nota-flotant-hyp');

              var usuariSpan = doc.createElement('span');
              usuariSpan.classList.add('nota-usuari');
              usuariSpan.textContent = '🤖 ' + nomUsuari + ' (IA)';
              nota.appendChild(usuariSpan);

              var textNode = doc.createTextNode(resum);
              nota.appendChild(textNode);

              var temporalId = 'ia_' + Date.now();
              nota.setAttribute('data-id', temporalId);
              nota.title = 'Resum generat per IA';

              contenidor.appendChild(nota);

              // Scroll a l'element
              elementTrobat.scrollIntoView({ behavior: 'smooth', block: 'center' });

              // Enviar al servidor per guardar
              Shiny.setInputValue('guardar_anotacio', {
                id: temporalId,
                text: resum,
                element_idx: idx,
                _timestamp: Date.now()
              });

              console.log('Anotació IA afegida a element', idx);

            } catch(e) {
              console.error('Error afegint anotació:', e);
            }
          ", text_buscar_safe, resum_safe)

          runjs(js_code)

          incProgress(0.1, detail = "Finalitzant...")

          model_nom <- if(model == "gemini") "Gemini Flash" else input$ollama_model_pub

          showNotification(
            HTML(paste0(
              "✅ Resum generat i afegit automàticament!<br>",
              "<strong>Model: ", model_nom, "</strong><br>",
              "<small>🤖 L'anotació s'ha afegit al document</small>"
            )),
            type = "message",
            duration = 7
          )
        } else {
          stop("No s'ha rebut resum vàlid")
        }

      }, error = function(e) {
        showNotification(
          HTML(paste0("<strong>❌ Error resumint:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Interpretar amb IA
  observeEvent(input$interpretar_ia_pub, {
    req(input$text_resumir_pub)
    text <- trimws(input$text_resumir_pub)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per interpretar (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_pub

    if (is.null(model) || model == "") {
      showNotification(
        "⚠️ Selecciona un model d'IA primer",
        type = "warning",
        duration = 3
      )
      return()
    }

    withProgress(message = '🔍 Interpretant amb IA...', value = 0, {
      tryCatch({
        incProgress(0.3, detail = "Processant...")

        resultat <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_pub

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          resultat <- interpretar_resultats_gemini(
            text = text,
            tipus = "general",
            idioma = input$ia_idioma_pub %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_pub

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          resultat <- interpretar_resultats_ollama(
            text = text,
            model = ollama_model,
            tipus = "general",
            idioma = input$ia_idioma_pub %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent interpretació...")

        if (!is.null(resultat) && nchar(resultat) > 0) {
          runjs(sprintf("
            $('#resum_resultat_pub').html('<strong>🔍 Interpretació:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", resultat))))

          showNotification(
            "✅ Interpretació generada! Copia-la per anotar.",
            type = "message",
            duration = 5
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          paste("❌ Error interpretant:", e$message),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Analitzar amb IA
  observeEvent(input$analitzar_ia_pub, {
    req(input$text_resumir_pub)
    text <- trimws(input$text_resumir_pub)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per analitzar (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_pub

    if (is.null(model) || model == "") {
      showNotification(
        "⚠️ Selecciona un model d'IA primer",
        type = "warning",
        duration = 3
      )
      return()
    }

    withProgress(message = '📊 Analitzant amb IA...', value = 0, {
      tryCatch({
        incProgress(0.3, detail = "Processant...")

        resultat <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_pub

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          resultat <- analitzar_dades_gemini(
            text = text,
            context = "",
            idioma = input$ia_idioma_pub %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_pub

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          resultat <- analitzar_dades_ollama(
            text = text,
            model = ollama_model,
            context = "",
            idioma = input$ia_idioma_pub %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent anàlisi...")

        if (!is.null(resultat) && nchar(resultat) > 0) {
          runjs(sprintf("
            $('#resum_resultat_pub').html('<strong>📊 Anàlisi:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", resultat))))

          showNotification(
            "✅ Anàlisi generada! Copia-la per anotar.",
            type = "message",
            duration = 5
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          paste("❌ Error analitzant:", e$message),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Recomanar amb IA
  observeEvent(input$recomanar_ia_pub, {
    req(input$text_resumir_pub)
    text <- trimws(input$text_resumir_pub)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per generar recomanacions (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_pub

    if (is.null(model) || model == "") {
      showNotification(
        "⚠️ Selecciona un model d'IA primer",
        type = "warning",
        duration = 3
      )
      return()
    }

    withProgress(message = '💡 Generant recomanacions...', value = 0, {
      tryCatch({
        incProgress(0.3, detail = "Processant...")

        resultat <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_pub

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          resultat <- recomanacions_gemini(
            text = text,
            idioma = input$ia_idioma_pub %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_pub

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          resultat <- recomanacions_ollama(
            text = text,
            model = ollama_model,
            idioma = input$ia_idioma_pub %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent recomanacions...")

        if (!is.null(resultat) && nchar(resultat) > 0) {
          runjs(sprintf("
            $('#resum_resultat_pub').html('<strong>💡 Recomanacions:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", resultat))))

          showNotification(
            "✅ Recomanacions generades! Copia-les per anotar.",
            type = "message",
            duration = 5
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          paste("❌ Error generant recomanacions:", e$message),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Gestió d'errors de l'anotació automàtica
  observeEvent(input$ia_anotacio_error, {
    req(input$ia_anotacio_error$error)

    showNotification(
      HTML(paste0(
        "<strong>⚠️ No s'ha pogut afegir automàticament</strong><br>",
        input$ia_anotacio_error$error, "<br><br>",
        "<small>Pots copiar el resum manualment i afegir-lo clicant l'element del document</small>"
      )),
      type = "warning",
      duration = 8
    )
  })

  #   # Interpretar amb IA
  #   observeEvent(input$interpretar_ia_pub, {
  #     req(input$text_resumir_pub)
  #     text <- trimws(input$text_resumir_pub)
  # 
  #     if (text == "" || nchar(text) < 20) {
  #       showNotification(
  #         "⚠️ Escriu text/dades per interpretar (mínim 20 caràcters)",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     model <- input$ia_model_pub
  #     tipus <- input$tipus_dades_pub %||% "general"
  # 
  #     if (is.null(model) || model == "") {
  #       showNotification(
  #         "⚠️ Selecciona un model d'IA primer",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     withProgress(message = '🔍 Interpretant amb IA...', value = 0, {
  #       tryCatch({
  #         incProgress(0.3, detail = "Analitzant...")
  # 
  #         interpretacio <- NULL
  # 
  #         if (model == "gemini") {
  #           api_key <- input$gemini_api_key_pub
  # 
  #           if (is.null(api_key) || api_key == "") {
  #             stop("Introdueix l'API key de Gemini")
  #           }
  # 
  #           Sys.setenv(GEMINI_API_KEY = api_key)
  # 
  #           interpretacio <- interpretar_resultats_gemini(
  #             text = text,
  #             tipus = tipus,
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  # 
  #         } else if (model == "ollama") {
  #           if (!ia_ollama_disponible) {
  #             stop("Ollama no està disponible")
  #           }
  # 
  #           ollama_model <- input$ollama_model_pub
  # 
  #           if (is.null(ollama_model) || ollama_model == "") {
  #             stop("Selecciona un model d'Ollama")
  #           }
  # 
  #           interpretacio <- interpretar_resultats_ollama(
  #             text = text,
  #             model = ollama_model,
  #             tipus = tipus,
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  #         } else {
  #           stop("Model no reconegut")
  #         }
  # 
  #         incProgress(0.5, detail = "Rebent interpretació...")
  # 
  #         if (!is.null(interpretacio) && nchar(interpretacio) > 0) {
  #           runjs(sprintf("
  #             $('#resum_resultat_pub').html('<strong>🔍 Interpretació:</strong><br><br>%s').show();
  #           ", gsub("'", "\\\\'", gsub("\n", "<br>", interpretacio))))
  # 
  #           showNotification(
  #             "✅ Interpretació generada! Copia-la per anotar.",
  #             type = "message",
  #             duration = 5
  #           )
  #         }
  # 
  #         incProgress(0.2)
  # 
  #       }, error = function(e) {
  #         showNotification(
  #           paste("❌ Error:", e$message),
  #           type = "error",
  #           duration = 10
  #         )
  #       })
  #     })
  #   })
  # 
  #   # Analitzar amb IA
  #   observeEvent(input$analitzar_ia_pub, {
  #     req(input$text_resumir_pub)
  #     text <- trimws(input$text_resumir_pub)
  # 
  #     if (text == "" || nchar(text) < 20) {
  #       showNotification(
  #         "⚠️ Escriu text/dades per analitzar (mínim 20 caràcters)",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     model <- input$ia_model_pub
  # 
  #     if (is.null(model) || model == "") {
  #       showNotification(
  #         "⚠️ Selecciona un model d'IA primer",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     withProgress(message = '📊 Analitzant amb IA...', value = 0, {
  #       tryCatch({
  #         incProgress(0.3, detail = "Analitzant en profunditat...")
  # 
  #         analisi <- NULL
  # 
  #         if (model == "gemini") {
  #           api_key <- input$gemini_api_key_pub
  # 
  #           if (is.null(api_key) || api_key == "") {
  #             stop("Introdueix l'API key de Gemini")
  #           }
  # 
  #           Sys.setenv(GEMINI_API_KEY = api_key)
  # 
  #           analisi <- analitzar_dades_gemini(
  #             text = text,
  #             context = "",
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  # 
  #         } else if (model == "ollama") {
  #           if (!ia_ollama_disponible) {
  #             stop("Ollama no està disponible")
  #           }
  # 
  #           ollama_model <- input$ollama_model_pub
  # 
  #           if (is.null(ollama_model) || ollama_model == "") {
  #             stop("Selecciona un model d'Ollama")
  #           }
  # 
  #           analisi <- analitzar_dades_ollama(
  #             text = text,
  #             model = ollama_model,
  #             context = "",
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  #         } else {
  #           stop("Model no reconegut")
  #         }
  # 
  #         incProgress(0.5, detail = "Rebent anàlisi...")
  # 
  #         if (!is.null(analisi) && nchar(analisi) > 0) {
  #           runjs(sprintf("
  #             $('#resum_resultat_pub').html('<strong>📊 Anàlisi detallada:</strong><br><br>%s').show();
  #           ", gsub("'", "\\\\'", gsub("\n", "<br>", analisi))))
  # 
  #           showNotification(
  #             "✅ Anàlisi completa! Copia-la per anotar.",
  #             type = "message",
  #             duration = 5
  #           )
  #         }
  # 
  #         incProgress(0.2)
  # 
  #       }, error = function(e) {
  #         showNotification(
  #           paste("❌ Error:", e$message),
  #           type = "error",
  #           duration = 10
  #         )
  #       })
  #     })
  #   })
  # 
  #   # Recomanacions amb IA
  #   observeEvent(input$recomanar_ia_pub, {
  #     req(input$text_resumir_pub)
  #     text <- trimws(input$text_resumir_pub)
  # 
  #     if (text == "" || nchar(text) < 20) {
  #       showNotification(
  #         "⚠️ Escriu text/dades per generar recomanacions (mínim 20 caràcters)",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     model <- input$ia_model_pub
  # 
  #     if (is.null(model) || model == "") {
  #       showNotification(
  #         "⚠️ Selecciona un model d'IA primer",
  #         type = "warning",
  #         duration = 3
  #       )
  #       return()
  #     }
  # 
  #     withProgress(message = '💡 Generant recomanacions...', value = 0, {
  #       tryCatch({
  #         incProgress(0.3, detail = "Processant...")
  # 
  #         recomanacions <- NULL
  # 
  #         if (model == "gemini") {
  #           api_key <- input$gemini_api_key_pub
  # 
  #           if (is.null(api_key) || api_key == "") {
  #             stop("Introdueix l'API key de Gemini")
  #           }
  # 
  #           Sys.setenv(GEMINI_API_KEY = api_key)
  # 
  #           recomanacions <- recomanacions_gemini(
  #             text = text,
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  # 
  #         } else if (model == "ollama") {
  #           if (!ia_ollama_disponible) {
  #             stop("Ollama no està disponible")
  #           }
  # 
  #           ollama_model <- input$ollama_model_pub
  # 
  #           if (is.null(ollama_model) || ollama_model == "") {
  #             stop("Selecciona un model d'Ollama")
  #           }
  # 
  #           recomanacions <- recomanacions_ollama(
  #             text = text,
  #             model = ollama_model,
  #             idioma = input$ia_idioma_pub %||% "catala"
  #           )
  #         } else {
  #           stop("Model no reconegut")
  #         }
  # 
  #         incProgress(0.5, detail = "Rebent recomanacions...")
  # 
  #         if (!is.null(recomanacions) && nchar(recomanacions) > 0) {
  #           runjs(sprintf("
  #             $('#resum_resultat_pub').html('<strong>💡 Recomanacions:</strong><br><br>%s').show();
  #           ", gsub("'", "\\\\'", gsub("\n", "<br>", recomanacions))))
  # 
  #           showNotification(
  #             "✅ Recomanacions generades! Copia-les per anotar.",
  #             type = "message",
  #             duration = 5
  #           )
  #         }
  # 
  #         incProgress(0.2)
  # 
  #       }, error = function(e) {
  #         showNotification(
  #           paste("❌ Error:", e$message),
  #           type = "error",
  #           duration = 10
  #         )
  #       })
  #     })
  #   })
  # })

  # === Fi secció IA ===

  # Auto-interpretació d'elements (taules i gràfics)
  observeEvent(input$auto_interpretar, {
      req(input$auto_interpretar)
  
      element <- input$auto_interpretar
  
      # Missatge de loading segons acció
      missatge <- switch(element$accio,
        'interpretar' = '🔍 Interpretant',
        'analitzar' = '📊 Analitzant',
        'recomanar' = '💡 Generant recomanacions',
        '🤖 Processant'
      )
  
      withProgress(message = paste0(missatge, '...'), value = 0, {
      tryCatch({
        incProgress(0.3)
  
        # Seleccionar model
        model <- input$ia_model_pub
        idioma <- input$ia_idioma_pub %||% "catala"
  
        if (is.null(model) || model == "") {
          stop("Selecciona un model d'IA a la sidebar (secció 🤖 Assistent IA)")
        }
  
        # Executar funció corresponent
        resultat <- NULL
  
        if (model == "gemini") {
          api_key <- input$gemini_api_key_pub
          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini a la sidebar")
          }
          Sys.setenv(GEMINI_API_KEY = api_key)
  
          incProgress(0.2)
  
          resultat <- switch(element$accio,
            'interpretar' = interpretar_resultats_gemini(
              text = element$dades,
              tipus = element$tipus_dades %||% "general",
              idioma = idioma
            ),
            'analitzar' = analitzar_dades_gemini(
              text = element$dades,
              context = "",
              idioma = idioma
            ),
            'recomanar' = recomanacions_gemini(
              text = element$dades,
              idioma = idioma
            ),
            'resumir' = resumir_text_gemini(
              text = element$dades,
              max_paraules = 150,
              idioma = idioma
            )
          )
  
        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }
  
          ollama_model <- input$ollama_model_pub
          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama a la sidebar")
          }
  
          incProgress(0.2)
  
          resultat <- switch(element$accio,
            'interpretar' = interpretar_resultats_ollama(
              text = element$dades,
              model = ollama_model,
              tipus = element$tipus_dades %||% "general",
              idioma = idioma
            ),
            'analitzar' = analitzar_dades_ollama(
              text = element$dades,
              model = ollama_model,
              context = "",
              idioma = idioma
            ),
            'recomanar' = recomanacions_ollama(
              text = element$dades,
              model = ollama_model,
              idioma = idioma
            ),
            'resumir' = resumir_text_ollama(
              text = element$dades,
              model = ollama_model,
              max_paraules = 150,
              idioma = idioma
            )
          )
        } else {
          stop("Model no reconegut")
        }
  
        incProgress(0.5)
  
        if (!is.null(resultat) && nchar(resultat) > 0) {
          # Enviar resultat a JavaScript
          runjs(sprintf("
            mostrarResultatInterpretacio('%s', '%s', '%s');
          ", element$element_id,
             gsub("'", "\\\\'", gsub("\n", "<br>", resultat)),
             element$accio))
  
          accio_nom <- if(element$accio == 'interpretar') {
            'Interpretació'
          } else if(element$accio == 'analitzar') {
            'Anàlisi'
          } else {
            'Recomanacions'
          }

          showNotification(
            paste0("✅ ", accio_nom, " generada!"),
            type = "message",
            duration = 3
          )
        }
  
      }, error = function(e) {
        # Amagar loading
        runjs(sprintf("amagarLoadingElement('%s');", element$element_id))
  
        showNotification(
          HTML(paste0("<strong>❌ Error:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Fer accessible el directori www
  addResourcePath("www", normalizePath("www"))

  # Pujar document
  observeEvent(input$pujar_html, {
    req(input$pujar_html)

    tryCatch({
      extension <- tolower(tools::file_ext(input$pujar_html$name))

      if (extension == "pdf") {
        # Guardar PDF temporalment
        pdf_temp <- file.path(dir_temp_session, input$pujar_html$name)
        file.copy(input$pujar_html$datapath, pdf_temp, overwrite = TRUE)

        # També guardar en base64 per exportació
        pdf_data <- base64enc::base64encode(pdf_temp)
        pdf_base64(pdf_data)
        pdf_temp_path(pdf_temp)
        document_html(NULL)
        tipus_document("pdf")
        status(paste0("✅ PDF carregat: ", input$pujar_html$name))
      } else {
        # Carregar HTML
        html_content <- paste(readLines(input$pujar_html$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
        document_html(html_content)
        pdf_base64(NULL)
        pdf_temp_path(NULL)
        tipus_document("html")
        status(paste0("✅ HTML carregat: ", input$pujar_html$name))
      }

      nom_document(input$pujar_html$name)

      # Reiniciar anotacions
      anotacions(data.frame(
        id = character(),
        text = character(),
        element_idx = integer(),
        usuari = character(),
        tipus = character(),
        pagina = integer(),
        x = numeric(),
        y = numeric(),
        stringsAsFactors = FALSE
      ))

    }, error = function(e) {
      status(paste0("❌ Error: ", conditionMessage(e)))
    })
  })

  # Generar HTML dinàmic (només al carregar document, no per cada anotació)
  generar_html_visor <- function() {
    req(document_html())

    html_base <- document_html()
    # Obtenir anotacions guardades
    notes <- anotacions()

    usuari <- if (!is.null(input$nom_usuari) && input$nom_usuari != "") {
      trimws(input$nom_usuari)
    } else {
      "Anònim"
    }

    js_notes <- jsonlite::toJSON(notes, auto_unbox = FALSE)
    js_usuari <- jsonlite::toJSON(usuari, auto_unbox = TRUE)

    js_injectable <- sub("TEXT_JSON_NOTES", js_notes, JS_VISOR_LIVE, fixed = TRUE)
    js_injectable <- sub("TEXT_NOM_USUARI", js_usuari, js_injectable, fixed = TRUE)

    html_final <- sub("</body>", paste0(js_injectable, "</body>"), html_base, ignore.case = TRUE)
    if(html_base == html_final) html_final <- paste0(html_base, js_injectable)

    return(html_final)
  }

  # Generar HTML estàtic per descàrrega
  generar_html_estatic <- function() {
    req(document_html())

    html_base <- document_html()
    notes <- anotacions()

    js_notes <- jsonlite::toJSON(notes, auto_unbox = FALSE)
    js_injectable <- sub("TEXT_JSON_NOTES", js_notes, JS_EXPORTACIO_ESTATIC, fixed = TRUE)

    html_final <- sub("</body>", paste0(js_injectable, "</body>"), html_base, ignore.case = TRUE)
    if(html_base == html_final) html_final <- paste0(html_base, js_injectable)

    return(html_final)
  }

  # Generar HTML autònom amb PDF incrustat
  generar_pdf_autonom <- function() {
    req(pdf_base64())

    tryCatch({
      # Llegir el template
      template_path <- "template_pdf_autonom.html"
      if (!file.exists(template_path)) {
        cat("❌ No es troba el template:", template_path, "\n")
        return("")
      }

      template <- paste(readLines(template_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

      pdf_data_uri <- paste0("data:application/pdf;base64,", pdf_base64())

      # Obtenir anotacions PDF
      notes <- anotacions()
      notes_pdf <- notes[notes$tipus == "pdf", ]

      # Substituir placeholders
      html_final <- template
      html_final <- gsub("{{TITLE}}", nom_document(), html_final, fixed = TRUE)
      html_final <- gsub("{{NUM_ANNOTATIONS}}", nrow(notes_pdf), html_final, fixed = TRUE)
      html_final <- gsub("{{PDF_BASE64}}", pdf_data_uri, html_final, fixed = TRUE)
      html_final <- gsub("{{ANNOTATIONS_JSON}}",
                        jsonlite::toJSON(notes_pdf, auto_unbox = FALSE, dataframe = "rows"),
                        html_final, fixed = TRUE)

      return(html_final)
    }, error = function(e) {
      cat("❌ Error generant PDF autònom:", conditionMessage(e), "\n")
      return("")
    })
  }

  # Mostrar visor
  output$visor <- renderUI({
    # Només re-renderitzar quan canvia el document, NO quan canvien anotacions
    tipus_document()
    nom_document()

    if (is.null(tipus_document())) {
      return(tags$div(
        # style = "text-align: center; padding: 500px 20px;",
        # Ho trec del gemini
        style="display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; text-align: center;",
        tags$h3(style = "color: #95a5a6;", "📄 Puja un document HTML/PDF per començar"),
        tags$p(style = "color: #bdc3c7; font-size: 14px;",
               "Utilitza el selector de fitxers a la barra lateral")
      ))
    }

    if (isolate(tipus_document()) == "pdf") {
      # Visor PDF interactiu
      nom_usuari_actual <- if (!is.null(isolate(input$nom_usuari)) && isolate(input$nom_usuari) != "") {
        isolate(input$nom_usuari)
      } else {
        "Anònim"
      }

      # URL relativa al PDF temporal
      pdf_url <- paste0("temp/", session$token, "/", isolate(nom_document()))

      tags$iframe(
        id = "pdf_viewer",
        src = paste0("www/pdf_viewer.html?file=", URLencode(pdf_url, reserved = TRUE),
                     "&doc=", URLencode(isolate(nom_document()), reserved = TRUE),
                     "&user=", URLencode(nom_usuari_actual, reserved = TRUE)),
        style = "width: 100%; height: calc(100vh - 180px); border: 1px solid #dee2e6; background: white;"
      )
    } else {
      # Mostrar visor HTML - usar isolate per no regenerar amb cada anotació
      tags$iframe(
        id = "iframe_document",
        srcdoc = isolate(generar_html_visor()),
        style = "width: 100%; height: calc(100vh - 180px); border: 1px solid #dee2e6; background: white;"
      )
    }
  })

  # Guardar anotació HTML
  observeEvent(input$guardar_anotacio, {
    cat("📡 Event guardar_anotacio rebut!\n")

    dades <- input$guardar_anotacio
    cat("   ID:", dades$id, "\n")
    cat("   Text:", substr(dades$text, 1, 50), "...\n")
    cat("   Element idx:", dades$element_idx, "\n")

    req(dades$text)

    usuari <- if (!is.null(input$nom_usuari) && input$nom_usuari != "") {
      trimws(input$nom_usuari)
    } else {
      "Anònim"
    }

    notes_actuals <- anotacions()
    nova_fila <- data.frame(
      id = as.character(dades$id),
      text = as.character(dades$text),
      element_idx = as.integer(dades$element_idx),
      usuari = as.character(usuari),
      tipus = "html",
      pagina = NA_integer_,
      x = NA_real_,
      y = NA_real_,
      stringsAsFactors = FALSE
    )

    anotacions(rbind(notes_actuals, nova_fila))
    cat("✅ Anotació guardada! Total anotacions:", nrow(anotacions()), "\n")
  })

  # Guardar anotació PDF
  observeEvent(input$guardar_anotacio_pdf, {
    dades <- input$guardar_anotacio_pdf
    req(dades$text)

    usuari <- if (!is.null(input$nom_usuari) && input$nom_usuari != "") {
      trimws(input$nom_usuari)
    } else {
      "Anònim"
    }

    notes_actuals <- anotacions()
    nova_fila <- data.frame(
      id = as.character(dades$id),
      text = as.character(dades$text),
      element_idx = NA_integer_,
      usuari = as.character(usuari),
      tipus = "pdf",
      pagina = as.integer(dades$pagina),
      x = as.numeric(dades$x),
      y = as.numeric(dades$y),
      stringsAsFactors = FALSE
    )

    anotacions(rbind(notes_actuals, nova_fila))
  })

  # Esborrar anotació PDF
  observeEvent(input$esborrar_anotacio_pdf, {
    req(input$esborrar_anotacio_pdf$id)
    target_id <- input$esborrar_anotacio_pdf$id
    notes_actuals <- anotacions()

    if (nrow(notes_actuals) > 0) {
      notes_filtrades <- notes_actuals[notes_actuals$id != target_id, ]
      anotacions(notes_filtrades)
    }
  })

  # Esborrar anotació
  observeEvent(input$id_a_esborrar, {
    req(input$id_a_esborrar$id)
    target_id <- input$id_a_esborrar$id
    notes_actuals <- anotacions()

    if (nrow(notes_actuals) > 0) {
      notes_filtrades <- notes_actuals[notes_actuals$id != target_id, ]
      anotacions(notes_filtrades)
    }
  })

  # Enviar anotacions PDF existents al visor
  observeEvent(input$request_annotations_pdf, {
    req(input$request_annotations_pdf$doc)
    doc_name <- input$request_annotations_pdf$doc

    notes <- anotacions()

    if (nrow(notes) > 0 && "tipus" %in% names(notes)) {
      notes_pdf <- notes[notes$tipus == "pdf", ]

      if (nrow(notes_pdf) > 0) {
        # Convertir a llista per enviar
        notes_list <- lapply(1:nrow(notes_pdf), function(i) {
          list(
            id = notes_pdf$id[i],
            pagina = notes_pdf$pagina[i],
            x = notes_pdf$x[i],
            y = notes_pdf$y[i],
            text = notes_pdf$text[i],
            usuari = notes_pdf$usuari[i]
          )
        })

        # Enviar via JavaScript a l'iframe
        js_code <- sprintf(
          "var iframe = document.getElementById('pdf_viewer');
           if (iframe && iframe.contentWindow) {
             iframe.contentWindow.postMessage({
               type: 'annotations',
               annotations: %s
             }, '*');
           }",
          jsonlite::toJSON(notes_list, auto_unbox = TRUE)
        )

        shinyjs::runjs(js_code)
      }
    }
  })

  # Descarregar HTML anotat
  output$descarregar_html <- downloadHandler(
    filename = function() {
      if (!is.null(nom_document())) {
        nom_base <- tools::file_path_sans_ext(nom_document())
        paste0(nom_base, "_anotat.html")
      } else {
        "document_anotat.html"
      }
    },
    content = function(file) {
      if (tipus_document() == "pdf") {
        # Generar HTML autònom amb PDF incrustat
        writeLines(generar_pdf_autonom(), file, useBytes = TRUE)
      } else {
        # Generar HTML estàtic
        writeLines(generar_html_estatic(), file)
      }
    }
  )

  output$avis <- renderText({ status() })
}

shinyApp(ui = ui, server = server)
