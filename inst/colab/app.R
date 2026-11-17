library(Comenta)
library(shiny)
library(bs4Dash)
library(jsonlite)
library(httr)
library(base64enc)
library(shinyjs)
library(htmltools)
library(shinymanager)

FITXER_DADES <- "comentaris.rds"
DIRECTORI_BASE_DOCS <- "./documents"
DIRECTORI_BASE_ANOTATS <- "./documents_anotats"

# Crear directoris base
if(!dir.exists(DIRECTORI_BASE_DOCS)) dir.create(DIRECTORI_BASE_DOCS)
if(!dir.exists(DIRECTORI_BASE_ANOTATS)) dir.create(DIRECTORI_BASE_ANOTATS)
if(!dir.exists("www")) dir.create("www")

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


# Funció per obtenir el directori de documents d'un usuari
get_directori_usuari <- function(usuari, base = DIRECTORI_BASE_DOCS) {
  if (is.null(usuari) || usuari == "" || usuari == "Anònim") {
    usuari <- "public"
  }
  dir_usuari <- file.path(base, usuari)
  if (!dir.exists(dir_usuari)) {
    dir.create(dir_usuari, recursive = TRUE)
    cat("📁 Directori creat per usuari:", usuari, "→", dir_usuari, "\n")
  }
  return(dir_usuari)
}


llegir_dades <- function() {
  if (file.exists(FITXER_DADES)) {
    tryCatch({
      dades <- readRDS(FITXER_DADES)
      if (is.data.frame(dades)) {
        # Afegir columnes si no existeixen (compatibilitat)
        if (!"usuari" %in% names(dades)) {
          dades$usuari <- "Usuari anònim"
        }
        if (!"tipus" %in% names(dades)) {
          dades$tipus <- "html"  # Per defecte són HTMLs
        }
        if (!"pagina" %in% names(dades)) {
          dades$pagina <- NA_integer_
        }
        if (!"x" %in% names(dades)) {
          dades$x <- NA_real_
        }
        if (!"y" %in% names(dades)) {
          dades$y <- NA_real_
        }
        return(dades)
      }
      return(data.frame(
        id = character(),
        doc = character(),
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
      return(data.frame(
        id = character(),
        doc = character(),
        text = character(),
        element_idx = integer(),
        usuari = character(),
        tipus = character(),
        pagina = integer(),
        x = numeric(),
        y = numeric(),
        stringsAsFactors = FALSE
      ))
    })
  } else {
    return(data.frame(
      id = character(),
      doc = character(),
      text = character(),
      element_idx = integer(),
      usuari = character(),
      tipus = character(),
      pagina = integer(),
      x = numeric(),
      y = numeric(),
      stringsAsFactors = FALSE
    ))
  }
}


# Funció per generar nom d'usuari


# 🛠️ 1. CAPA JAVASCRIPT PER AL VISOR EN VIU (Interactiva amb clics)
JS_VISOR_LIVE <- "
<style>
    p, h1, h2, h3, h4, h5, h6, li {
        position: relative; cursor: pointer; transition: background 0.15s; padding: 5px; margin: 8px 0;
    }
    p:hover, h1:hover, h2:hover, h3:hover, h4:hover, h5:hover, h6:hover, li:hover {
        background-color: rgba(52, 152, 219, 0.08);
        border-left: 3px solid #3498db;
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
    /* Estils per cel·les */
    td, th {
        padding: 8px;
    }
    table {
        position: relative;
        cursor: pointer;
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
    /* Estil per enllaços */
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
    // Nom d'usuari actual
    const NOM_USUARI_ACTUAL = TEXT_NOM_USUARI;

    // Indexar tots els elements anotables
    function indexarElements() {
        // Indexar elements: taules senceres, NO cel·les
        document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, table, .plotly-graph-div, figure').forEach(function(el, idx) {
            el.setAttribute('data-element-idx', idx);
        });
        console.log('✅ Elements indexats');
    }

    // Carregar notes existents
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

    // Exposar indexarElements globalment per auto_interpret.js
    window.indexarElements = indexarElements;

    // Inicialitzar quan el document estigui llest
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            indexarElements();
            carregarNotes();
        });
    } else {
        indexarElements();
        carregarNotes();
    }

    // Re-indexar després que auto_interpret marqui les taules
    setTimeout(function() {
        console.log('🔄 Re-indexant elements després d\'auto-interpret...');
        indexarElements();
    }, 2000);

    // Prevenir navegació en enllaços (per evitar que l'app es carregui dins l'iframe)
    document.addEventListener('click', function(e) {
        // Si és un enllaç, prevenir navegació per defecte però permetre scroll a ancoratge
        if (e.target.tagName === 'A' || e.target.closest('a')) {
            const link = e.target.tagName === 'A' ? e.target : e.target.closest('a');
            const href = link.getAttribute('href');

            // Si és un enllaç intern d'ancoratge (#something), només fer scroll
            if (href && href.startsWith('#')) {
                e.preventDefault();
                const targetId = href.substring(1);
                const targetElement = document.getElementById(targetId);
                if (targetElement) {
                    targetElement.scrollIntoView({ behavior: 'smooth' });
                }
                return;
            }

            // Si és enllaç extern, obrir en nova finestra
            if (href && (href.startsWith('http') || href.startsWith('www'))) {
                e.preventDefault();
                window.open(href, '_blank');
                return;
            }
        }

        // Ignorar clics dins de notes
        if (e.target.closest('.contenidor-notes') || e.target.closest('.nota-flotant-hyp')) return;

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

        // Evitar crear múltiples editors
        if (contenidor.querySelector('.textarea-simple')) return;

        // Crear editor
        const editorDiv = document.createElement('div');
        editorDiv.innerHTML = '<textarea class=\"textarea-simple\" placeholder=\"Escriu un comentari...\"></textarea><button class=\"btn-guardar\">Guardar</button><button class=\"btn-cancelar\">Cancel·lar</button>';
        contenidor.appendChild(editorDiv);

        const txtArea = editorDiv.querySelector('.textarea-simple');
        txtArea.focus();

        // Botó Guardar
        editorDiv.querySelector('.btn-guardar').addEventListener('click', function() {
            const text = txtArea.value.trim();
            if (text === '') {
                editorDiv.remove();
                if (contenidor.children.length === 0) contenidor.remove();
                return;
            }

            const temporalId = 'temp_' + Date.now();
            console.log('💾 Guardant:', text.substring(0, 30) + '...');

            dibuixarNotaAncorada(idx, text, temporalId, NOM_USUARI_ACTUAL);
            editorDiv.remove();

            if (window.parent && window.parent.Shiny) {
                window.parent.Shiny.setInputValue('guardar_anotacio', {
                    id: temporalId,
                    text: text,
                    element_idx: idx,
                    _timestamp: Date.now()
                });
            }
        });

        // Botó Cancel·lar
        editorDiv.querySelector('.btn-cancelar').addEventListener('click', function() {
            editorDiv.remove();
            if (contenidor.children.length === 0) contenidor.remove();
        });
    });

    // Dibuixar nota ancorada a un element
    function dibuixarNotaAncorada(elementIdx, text, id, usuari) {
        const element = document.querySelector('[data-element-idx=\"' + elementIdx + '\"]');
        if (!element) {
            console.error('❌ Element no trobat per idx:', elementIdx);
            return;
        }

        console.log('✅ Dibuixant nota:', element.tagName, 'idx:', elementIdx);

        // Crear/buscar contenidor (per taules, posar-lo després)
        let contenidor = element.querySelector('.contenidor-notes');
        if (!contenidor) {
            // Buscar contenidor just després de l'element (per taules)
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

        // Afegir usuari si existeix
        if (usuari) {
            const usuariSpan = document.createElement('span');
            usuariSpan.classList.add('nota-usuari');
            usuariSpan.textContent = '🦠 ' + usuari;
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

# 🔒 2. CAPA JAVASCRIPT ESTÀTICA PER A LES EXPORTACIONS (Només lectura)
JS_EXPORTACIO_ESTATIC <- "
<style>
    p, h1, h2, h3, h4, h5, h6, li { position: relative; padding: 5px; margin: 8px 0; }
    .contenidor-notes {
        display: block; margin-top: 8px; padding-left: 12px;
        border-left: 3px solid #27ae60; background: #f0fdf4;
    }
    .nota-flotant-hyp {
        border: 1px solid #d1fae5; border-radius: 6px;
        padding: 8px 12px; background: #ffffff; margin: 5px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.06); color: #2c3e50;
        font-size: 13px; font-family: sans-serif; display: block; cursor: pointer;
    }
    .nota-flotant-hyp:hover { background: #f8f9fa; }
    .nota-usuari {
        font-size: 11px; color: #27ae60; font-weight: 600;
        font-style: italic; margin-bottom: 4px; display: block;
    }
    /* Estil per enllaços */
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
    // Prevenir navegació en enllaços
    document.addEventListener('click', function(e) {
        if (e.target.tagName === 'A' || e.target.closest('a')) {
            const link = e.target.tagName === 'A' ? e.target : e.target.closest('a');
            const href = link.getAttribute('href');

            // Si és un enllaç intern d'ancoratge (#something), només fer scroll
            if (href && href.startsWith('#')) {
                e.preventDefault();
                const targetId = href.substring(1);
                const targetElement = document.getElementById(targetId);
                if (targetElement) {
                    targetElement.scrollIntoView({ behavior: 'smooth' });
                }
                return;
            }

            // Si és enllaç extern, obrir en nova finestra
            if (href && (href.startsWith('http') || href.startsWith('www'))) {
                e.preventDefault();
                window.open(href, '_blank');
                return;
            }
        }
    });

    function inicialitzar() {
        // Indexar elements
        let idx = 0;
        // Indexar tots els elements EXCEPTE td/th dins de taules auto-interpret
        document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, .plotly-graph-div, figure').forEach(function(el) {
            el.setAttribute('data-element-idx', idx);
            idx++;
        });

        // Indexar taules auto-interpret (senceres, no cel·les individuals)
        document.querySelectorAll('table[data-auto-interpret]').forEach(function(el) {
            el.setAttribute('data-element-idx', idx);
            idx++;
        });

        // Indexar td/th NOMÉS si NO estan dins d'una taula auto-interpret
        document.querySelectorAll('td, th').forEach(function(el) {
            if (!el.closest('table[data-auto-interpret]')) {
                el.setAttribute('data-element-idx', idx);
                idx++;
            }
        });

        // Carregar notes
        const notes = TEXT_JSON_NOTES;
        if(notes && notes.length > 0) {
            notes.forEach(n => {
                if(n.element_idx !== undefined && n.text) {
                    const element = document.querySelector('[data-element-idx=\"' + n.element_idx + '\"]');
                    if (!element) return;

                    let contenidor = element.querySelector('.contenidor-notes');
                    if (!contenidor) {
                        contenidor = document.createElement('div');
                        contenidor.classList.add('contenidor-notes');
                        element.appendChild(contenidor);
                    }

                    const nota = document.createElement('div');
                    nota.classList.add('nota-flotant-hyp');

                    // Afegir usuari si existeix
                    if (n.usuari) {
                        const usuariSpan = document.createElement('span');
                        usuariSpan.classList.add('nota-usuari');
                        usuariSpan.textContent = '🦠 ' + n.usuari;
                        nota.appendChild(usuariSpan);
                    }

                    const textNode = document.createTextNode(n.text);
                    nota.appendChild(textNode);

                    nota.title = 'Doble clic per esborrar';
                    nota.addEventListener('dblclick', function() { this.remove(); });
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

ui_base <- dashboardPage(
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
          "col·laboratiu · comentari amb mentor IA"
        )
      )
    ),
    compact = FALSE,
    border = TRUE


  ),
  sidebar = dashboardSidebar(
    tags$div(style = "padding: 20px 15px;",
      textInput("nom_usuari", "👤 El teu nom:",
                placeholder = "Introdueix nom per identificar les notes"),
      
      uiOutput("info_usuaris_actius"),
      hr(),
      tags$div(style = "margin-bottom: 10px;",
        tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 5px; display: block;", "📁 Documents"),
        fileInput("pujar_html", NULL, accept = c("text/html", ".html", "application/pdf", ".pdf"), buttonLabel = "Pujar HTML/PDF", placeholder = "Selecciona arxiu..."),
        tags$div(style = "margin-top: 5px;"),
        selectInput("selector_doc", NULL, choices = NULL)
      ),
      tags$div(style = "margin: 20px 0; border-top: 2px solid rgba(255,255,255,0.3);"),

      # === Secció IA ===
      tags$div(
        style = "background: rgba(156, 39, 176, 0.2); padding: 12px; border-radius: 8px; margin-bottom: 15px; border-left: 4px solid #9c27b0;",
        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
          tags$label(style = "color: white; font-weight: 600; font-size: 13px; margin: 0;", "🤖 Assistent IA"),
          actionButton("toggle_ia_config_colab", "⚙️", class = "btn-xs",
                      style = "background: rgba(255,255,255,0.3); border: none; color: white; padding: 4px 8px; border-radius: 4px;")
        ),
        conditionalPanel(
          condition = "input.toggle_ia_config_colab % 2 == 1",
          selectInput("ia_model_colab", "Model:",
                     choices = c("Selecciona..." = "", "Gemini Flash (Google)" = "gemini", "Ollama Local" = "ollama"),
                     selectize = FALSE),
          conditionalPanel(
            condition = "input.ia_model_colab == 'ollama'",
            uiOutput("ollama_model_selector_colab")
          ),
          conditionalPanel(
            condition = "input.ia_model_colab == 'gemini'",
            textInput("gemini_api_key_colab", "API Key:",
                     placeholder = "AIzaSy...",
                     value = ""),
            tags$a(href = "https://makersuite.google.com/app/apikey", target = "_blank",
                  style = "color: white; font-size: 9px; text-decoration: underline;",
                  "Obtenir API key gratuïta")
          ),
          selectInput("ia_idioma_colab", "Idioma resum:",
                     choices = c("Català" = "catala", "Español" = "espanyol", "English" = "angles"),
                     selected = "catala",
                     selectize = FALSE),
          uiOutput("ia_status_text_colab")
        ),
        textAreaInput("text_resumir_colab", "Text/Dades a analitzar:",
                     placeholder = "Enganxa text, taula o descripció de gràfic...",
                     rows = 3),
        selectInput("tipus_dades_colab", "Tipus de dades:",
                   choices = c("General" = "general", "Taula" = "taula", "Gràfic" = "grafic", "Resultats" = "resultats"),
                   selected = "general",
                   selectize = FALSE),
        tags$div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 5px; margin-bottom: 8px;",
          actionButton("resumir_ia_colab", "✨ Resumir",
                      class = "btn-warning btn-sm",
                      style = "font-weight: 600; font-size: 10px; padding: 6px 4px;"),
          actionButton("interpretar_ia_colab", "🔍 Interpretar",
                      class = "btn-info btn-sm",
                      style = "font-weight: 600; font-size: 10px; padding: 6px 4px;")
        ),
        tags$div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 5px;",
          actionButton("analitzar_ia_colab", "📊 Analitzar",
                      class = "btn-success btn-sm",
                      style = "font-weight: 600; font-size: 10px; padding: 6px 4px;"),
          actionButton("recomanar_ia_colab", "💡 Recomanar",
                      class = "btn-primary btn-sm",
                      style = "font-weight: 600; font-size: 10px; padding: 6px 4px;")
        ),
        tags$div(id = "resum_resultat_colab",
                style = "margin-top: 10px; padding: 8px; background: rgba(255,255,255,0.95); border-radius: 6px; display: none; color: #2c3e50; font-size: 11px; max-height: 300px; overflow-y: auto;")
      ),

      tags$div(style = "margin: 20px 0; border-top: 2px solid rgba(255,255,255,0.3);"),
      tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 10px; display: block;", "💾 Accions"),
      tags$div(style = "text-align: left; display: flex; flex-direction: column; gap: 10px;",
        actionButton("guardar_servidor", "Guardar", icon = icon("save"), class = "btn-danger", style = "width: 100%; margin: 0;"),
        downloadButton("descarregar_html", "Descarregar", icon = icon("download"), class = "btn-success", style = "width: 100%; margin: 0;"),
        actionButton("esborrar_doc", "Esborrar document", icon = icon("trash"), class = "btn-warning", style = "width: 100%; margin: 0;")
      ),
      br(),
      textOutput("avis_guardat")
    ),
    width = "350px"
    
  
  ),
  body = dashboardBody(
    tags$head(
      tags$style(HTML("
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

        /* Font global */
        body, .sidebar, .main-header {
          font-family: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif !important;
        }

        /* Barra lateral vermellosa */
        .main-sidebar {
          background: linear-gradient(180deg, #dc3545 0%, #c82333 100%) !important;
          box-shadow: 2px 0 10px rgba(0,0,0,0.1);
        }

        .sidebar label {
          color: #ffffff !important;
          font-weight: 500;
          font-size: 13px;
          letter-spacing: 0.3px;
        }

        .sidebar .form-control,
        .sidebar .selectize-input {
          background-color: #ffffff;
          color: #2c3e50;
          border-radius: 8px;
          border: none;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          transition: all 0.2s ease;
        }

        .sidebar .form-control::placeholder {
          color: #95a5a6;
          font-size: 12px;
          font-style: italic;
        }

        .sidebar .form-control:focus,
        .sidebar .selectize-input.focus {
          box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }

        .sidebar hr {
          border-color: rgba(255, 255, 255, 0.2);
          margin: 15px 0;
        }

        .sidebar .btn-danger,
        .sidebar .btn-success {
          background: #ffffff !important;
          border: none;
          font-weight: 600;
          border-radius: 8px;
          padding: 10px 20px;
          transition: all 0.2s ease;
          min-width: 140px;
          text-align: center;
        }

        .sidebar .btn-danger {
          color: #dc3545 !important;
        }

        .sidebar .btn-success {
          color: #28a745 !important;
        }

        .sidebar .btn-danger:hover,
        .sidebar .btn-success:hover {
          background: #f8f9fa !important;
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }

        .sidebar .btn-warning {
          background: #ffc107 !important;
          color: #000000 !important;
          font-weight: 600;
          border-radius: 8px;
          padding: 10px 20px;
          transition: all 0.2s ease;
          min-width: 140px;
          text-align: center;
        }

        .sidebar .btn-warning:hover {
          background: #ffb300 !important;
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(255, 193, 7, 0.3);
        }

        #avis_guardat {
          color: #ffffff;
          background: rgba(255, 255, 255, 0.15);
          padding: 10px;
          border-radius: 8px;
          font-size: 12px;
          text-align: center;
          font-weight: 500;
        }

        /* Header vermell */
        .main-header {
          background: linear-gradient(135deg, #dc3545 0%, #c82333 100%) !important;
          box-shadow: 0 2px 10px rgba(220, 53, 69, 0.2);
        }

        .main-header .navbar-light {
          background: transparent !important;
        }

        .main-header .brand-link {
          padding: 8px 15px 8px 30px !important;
          width: auto !important;
        }

        .main-header .brand-text {
          display: inline-block !important;
          margin-left: 0 !important;
        }

        /* Cos de l'aplicació */
        .content-wrapper {
          background-color: #f5f6fa;
        }

        /* iframe */
        iframe {
          border: 1px solid #e9ecef !important;
          border-radius: 8px !important;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
          background: white;
        }

        /* Millores generals */
        .btn {
          font-family: 'Poppins', sans-serif !important;
        }
      "))
    ),
    useShinyjs(),  # Necessari per comunicar-se amb l'iframe del PDF

    # Carregar JavaScript d'auto-interpretació
    tags$head(
      tags$script(src = "auto_interpret.js")
    ),

    box(
      width = 12,
      status = NULL,
      solidHeader = FALSE,
      collapsible = FALSE,
      uiOutput("visor_dinamic")
    ),
    tags$div(
      style = "position: fixed; bottom: 0; left: 0; right: 0; background: rgba(255,255,255,0.95); padding: 10px; text-align: center; font-size: 11px; color: #666; border-top: 1px solid #dee2e6; z-index: 1000; backdrop-filter: blur(5px);",
      HTML('AnotaR v1.0.0 | <a href="https://github.com/josepmuncunill/AnotaR" target="_blank" style="color: #007bff;">GitHub</a> | MIT License | IDISBA Bioinformàtica')
    )
  )
)

server <- function(input, output, session) {
  # ========== AUTENTICACIÓ ==========
  res_auth <- secure_server(
    check_credentials = check_credentials(
      "database.sqlite",
      passphrase = "clau_secreta_canviar"
    )
  )

  # Informació de l'usuari autenticat (reactiu)
  usuari_actual <- reactive({
    if (!is.null(res_auth$user)) {
      res_auth$user
    } else {
      "public"
    }
  })

  # És administrador?
  es_admin <- reactive({
    !is.null(res_auth$admin) && res_auth$admin == TRUE
  })

  # Directoris específics de l'usuari (reactius)
  DIRECTORI_HTMLs <- reactive({
    get_directori_usuari(usuari_actual(), DIRECTORI_BASE_DOCS)
  })

  DIRECTORI_SORTIDA <- reactive({
    get_directori_usuari(usuari_actual(), DIRECTORI_BASE_ANOTATS)
  })

  # ========== CONFIGURACIÓ ORIGINAL ==========
  options(shiny.maxRequestSize=30*1024^2)
  status_msg <- reactiveVal("")

  # Fer accessibles els directoris base
  addResourcePath("documents", normalizePath(DIRECTORI_BASE_DOCS))
  addResourcePath("www", normalizePath("www"))

  # Generar bacteri únic per aquesta sessió
  bacteri_sessio <- reactiveVal("Sense nom assignat")

  # === Secció IA ===

  # Selector de models Ollama
  output$ollama_model_selector_colab <- renderUI({
    if (ia_ollama_disponible) {
      models <- ollama_llistar_models()

      if (length(models) > 0) {
        model_recomanat <- ollama_model_recomanat()

        selectInput("ollama_model_colab", "Model Ollama:",
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
  output$ia_status_text_colab <- renderUI({
    model <- input$ia_model_colab

    if (is.null(model) || model == "") {
      return(tags$div(
        style = "color: rgba(255,255,255,0.85); font-size: 9px; margin-top: 8px;",
        "Selecciona un model per activar l'assistent IA"
      ))
    }

    if (model == "gemini") {
      api_key <- input$gemini_api_key_colab

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
  observeEvent(input$resumir_ia_colab, {
    req(input$text_resumir_colab)
    text <- trimws(input$text_resumir_colab)

    if (text == "" || nchar(text) < 50) {
      showNotification(
        "⚠️ Escriu text per resumir (mínim 50 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_colab

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
          api_key <- input$gemini_api_key_colab

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          incProgress(0.3, detail = "Enviant a Gemini...")

          resum <- resumir_text_gemini(
            text = text,
            max_paraules = 150,
            idioma = input$ia_idioma_colab %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_colab

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          incProgress(0.3, detail = paste0("Processant amb ", ollama_model, "..."))

          resum <- resumir_text_ollama(
            text = text,
            model = ollama_model,
            max_paraules = 150,
            idioma = input$ia_idioma_colab %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.4, detail = "Rebent resum...")

        if (!is.null(resum) && nchar(resum) > 0) {
          # Mostrar resum en un div especial
          runjs(sprintf("
            $('#resum_resultat_colab').html('<strong>📝 Resum generat:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", resum))))

          incProgress(0.1, detail = "Finalitzant...")

          showNotification(
            HTML(paste0(
              "✅ Resum generat amb <strong>",
              if(model == "gemini") "Gemini Flash" else input$ollama_model_colab,
              "</strong><br>",
              "<small>Ara pots copiar-lo i enganxar-lo com anotació al document</small>"
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
  observeEvent(input$interpretar_ia_colab, {
    req(input$text_resumir_colab)
    text <- trimws(input$text_resumir_colab)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per interpretar (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_colab
    tipus <- input$tipus_dades_colab %||% "general"

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
        incProgress(0.3, detail = "Analitzant...")

        interpretacio <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_colab

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          interpretacio <- interpretar_resultats_gemini(
            text = text,
            tipus = tipus,
            idioma = input$ia_idioma_colab %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_colab

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          interpretacio <- interpretar_resultats_ollama(
            text = text,
            model = ollama_model,
            tipus = tipus,
            idioma = input$ia_idioma_colab %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent interpretació...")

        if (!is.null(interpretacio) && nchar(interpretacio) > 0) {
          runjs(sprintf("
            $('#resum_resultat_colab').html('<strong>🔍 Interpretació:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", interpretacio))))

          showNotification(
            HTML(paste0(
              "✅ Interpretació generada amb <strong>",
              if(model == "gemini") "Gemini Flash" else input$ollama_model_colab,
              "</strong><br>",
              "<small>Copia-la per anotar al document</small>"
            )),
            type = "message",
            duration = 7
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          HTML(paste0("<strong>❌ Error interpretant:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Analitzar amb IA
  observeEvent(input$analitzar_ia_colab, {
    req(input$text_resumir_colab)
    text <- trimws(input$text_resumir_colab)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per analitzar (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_colab

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
        incProgress(0.3, detail = "Analitzant en profunditat...")

        analisi <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_colab

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          analisi <- analitzar_dades_gemini(
            text = text,
            context = "",
            idioma = input$ia_idioma_colab %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_colab

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          analisi <- analitzar_dades_ollama(
            text = text,
            model = ollama_model,
            context = "",
            idioma = input$ia_idioma_colab %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent anàlisi...")

        if (!is.null(analisi) && nchar(analisi) > 0) {
          runjs(sprintf("
            $('#resum_resultat_colab').html('<strong>📊 Anàlisi detallada:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", analisi))))

          showNotification(
            HTML(paste0(
              "✅ Anàlisi completa amb <strong>",
              if(model == "gemini") "Gemini Flash" else input$ollama_model_colab,
              "</strong><br>",
              "<small>Copia-la per anotar al document</small>"
            )),
            type = "message",
            duration = 7
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          HTML(paste0("<strong>❌ Error analitzant:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Recomanacions amb IA
  observeEvent(input$recomanar_ia_colab, {
    req(input$text_resumir_colab)
    text <- trimws(input$text_resumir_colab)

    if (text == "" || nchar(text) < 20) {
      showNotification(
        "⚠️ Escriu text/dades per generar recomanacions (mínim 20 caràcters)",
        type = "warning",
        duration = 3
      )
      return()
    }

    model <- input$ia_model_colab

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

        recomanacions <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_colab

          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          Sys.setenv(GEMINI_API_KEY = api_key)

          recomanacions <- recomanacions_gemini(
            text = text,
            idioma = input$ia_idioma_colab %||% "catala"
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_colab

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          recomanacions <- recomanacions_ollama(
            text = text,
            model = ollama_model,
            idioma = input$ia_idioma_colab %||% "catala"
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.5, detail = "Rebent recomanacions...")

        if (!is.null(recomanacions) && nchar(recomanacions) > 0) {
          runjs(sprintf("
            $('#resum_resultat_colab').html('<strong>💡 Recomanacions:</strong><br><br>%s').show();
          ", gsub("'", "\\\\'", gsub("\n", "<br>", recomanacions))))

          showNotification(
            HTML(paste0(
              "✅ Recomanacions generades amb <strong>",
              if(model == "gemini") "Gemini Flash" else input$ollama_model_colab,
              "</strong><br>",
              "<small>Copia-les per anotar al document</small>"
            )),
            type = "message",
            duration = 7
          )
        }

        incProgress(0.2)

      }, error = function(e) {
        showNotification(
          HTML(paste0("<strong>❌ Error generant recomanacions:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
      })
    })
  })

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
        model <- input$ia_model_colab
        idioma <- input$ia_idioma_colab %||% "catala"

        if (is.null(model) || model == "") {
          stop("Selecciona un model d'IA a la sidebar (secció 🤖 Assistent IA)")
        }

        # Executar funció corresponent
        resultat <- NULL

        if (model == "gemini") {
          api_key <- input$gemini_api_key_colab
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
            )
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          ollama_model <- input$ollama_model_colab
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

          showNotification(
            HTML(paste0(
              "✅ ",
              if(element$accio == 'interpretar') 'Interpretació'
              else if(element$accio == 'analitzar') 'Anàlisi'
              else 'Recomanacions',
              " generada amb <strong>",
              if(model == "gemini") "Gemini Flash" else input$ollama_model_colab,
              "</strong>"
            )),
            type = "message",
            duration = 5
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

  # Mostrar info dels usuaris actius en aquest document
  output$info_usuaris_actius <- renderUI({
    req(input$selector_doc)
    if (input$selector_doc == "" || input$selector_doc == "No s'han trobat HTMLs") return(NULL)

    totes_les_notes <- llegir_dades()

    if (nrow(totes_les_notes) > 0 && "doc" %in% names(totes_les_notes) && "usuari" %in% names(totes_les_notes)) {
      notes_doc <- totes_les_notes[totes_les_notes$doc == input$selector_doc, ]

      if (nrow(notes_doc) > 0) {
        usuaris_stats <- table(notes_doc$usuari)
        info_text <- paste0(names(usuaris_stats), " (", usuaris_stats, ")", collapse = ", ")

        return(tags$div(
          style = "background: rgba(255,255,255,0.1); padding: 8px; border-radius: 6px; margin-top: 5px; margin-bottom: 5px;",
          tags$div(style = "color: white; font-size: 10px; font-weight: 600; margin-bottom: 4px;", "👥 Usuaris actius:"),
          tags$div(style = "color: rgba(255,255,255,0.9); font-size: 10px; line-height: 1.4;", info_text)
        ))
      }
    }
    return(NULL)
  })

  llista_fitxers <- reactivePoll(1000, session,
                                 checkFunc = function() {
                                   dir_user <- DIRECTORI_HTMLs()
                                   if (dir.exists(dir_user)) {
                                     length(list.files(dir_user, pattern = "\\.(html|pdf)$"))
                                   } else { 0 }
                                 },
                                 valueFunc = function() {
                                   dir_user <- DIRECTORI_HTMLs()
                                   list.files(dir_user, pattern = "\\.(html|pdf)$", full.names = FALSE)
                                 }
  )

  observe({
    fitxers <- llista_fitxers()
    if (length(fitxers) > 0) {
      seleccio_actual <- input$selector_doc
      # Si la selecció actual no existeix als fitxers, seleccionar el primer
      if (is.null(seleccio_actual) || !(seleccio_actual %in% fitxers)) {
        seleccio_actual <- fitxers[1]
      }
      updateSelectInput(session, "selector_doc", choices = fitxers, selected = seleccio_actual)
    } else {
      updateSelectInput(session, "selector_doc", choices = c("No s'han trobat HTMLs" = ""))
    }
  })

  observeEvent(input$pujar_html, {
    req(input$pujar_html)
    nom_fitxer <- input$pujar_html$name
    extension <- tolower(tools::file_ext(nom_fitxer))

    if (extension == "pdf" || extension == "html" || extension == "htm") {
      # Copiar fitxer al directori de l'usuari
      dir_user <- DIRECTORI_HTMLs()
      file.copy(input$pujar_html$datapath, file.path(dir_user, nom_fitxer), overwrite = TRUE)
      tipus <- if(extension == "pdf") "PDF" else "HTML"
      status_msg(paste0("✔️ ", tipus, " pujat: ", nom_fitxer, " (usuari: ", usuari_actual(), ")"))
    } else {
      status_msg("❌ Format no suportat. Puja HTML o PDF")
    }
  })
  
  # Genera l'HTML dinàmic interactiu per al visor web
  generar_html_visor <- function(nom_document, nom_usuari_actual, bacteri_default) {
    tryCatch({
      dir_user <- DIRECTORI_HTMLs()
      ruta_real <- file.path(dir_user, nom_document)
      if (!file.exists(ruta_real)) return("<h1>Falta fitxer</h1>")

      html_base <- paste(readLines(ruta_real, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

      # Validar que html_base és vàlid
      if (is.null(html_base) || length(html_base) == 0 || !validUTF8(html_base)) {
        cat("⚠️ HTML base invàlid per:", nom_document, "\n")
        return("<h1>Error: Document invàlid</h1>")
      }

      totes_les_notes <- llegir_dades()

      notes_filtrades <- data.frame()
      if (nrow(totes_les_notes) > 0 && "doc" %in% names(totes_les_notes)) {
        notes_filtrades <- totes_les_notes[totes_les_notes$doc == nom_document, ]
      }

      # Generar nom d'usuari per mostrar
      if (is.null(nom_usuari_actual) || nom_usuari_actual == "" || trimws(nom_usuari_actual) == "") {
        usuari_a_mostrar <- bacteri_default
      } else {
        usuari_a_mostrar <- trimws(nom_usuari_actual)
      }

      js_notes <- jsonlite::toJSON(notes_filtrades, auto_unbox = FALSE)
      js_usuari <- jsonlite::toJSON(usuari_a_mostrar, auto_unbox = TRUE)

      js_injectable <- sub("TEXT_JSON_NOTES", js_notes, JS_VISOR_LIVE, fixed = TRUE)
      js_injectable <- sub("TEXT_NOM_USUARI", js_usuari, js_injectable, fixed = TRUE)

      html_final <- sub("</body>", paste0(js_injectable, "</body>"), html_base, ignore.case = TRUE)
      if(html_base == html_final) html_final <- paste0(html_base, js_injectable)
      return(html_final)
    }, error = function(e) {
      cat("❌ Error a generar_html_visor:", conditionMessage(e), "\n")
      cat("   Document:", nom_document, "\n")
      return(paste0("<h1>Error carregant document</h1><pre>", htmltools::htmlEscape(conditionMessage(e)), "</pre>"))
    })
  }
  
  # Genera HTML autònom per PDFs amb anotacions incrustades
  generar_pdf_autonom <- function(nom_document) {
    tryCatch({
      # Llegir el template
      template_path <- "template_pdf_autonom.html"
      if (!file.exists(template_path)) {
        cat("❌ No es troba el template:", template_path, "\n")
        return("")
      }

      template <- paste(readLines(template_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

      # Llegir el PDF i codificar-lo (del directori de l'usuari)
      dir_user <- DIRECTORI_HTMLs()
      pdf_path <- file.path(dir_user, nom_document)
      if (!file.exists(pdf_path)) {
        cat("❌ No es troba el PDF:", pdf_path, "\n")
        return("")
      }

      pdf_base64 <- base64enc::base64encode(pdf_path)
      pdf_data_uri <- paste0("data:application/pdf;base64,", pdf_base64)

      # Obtenir anotacions
      totes_les_notes <- llegir_dades()
      notes_pdf <- totes_les_notes[totes_les_notes$doc == nom_document &
                                     totes_les_notes$tipus == "pdf", ]

      # Substituir placeholders
      html_final <- template
      html_final <- gsub("{{TITLE}}", nom_document, html_final, fixed = TRUE)
      html_final <- gsub("{{NUM_ANNOTATIONS}}", nrow(notes_pdf), html_final, fixed = TRUE)
      html_final <- gsub("{{PDF_BASE64}}", pdf_data_uri, html_final, fixed = TRUE)
      html_final <- gsub("{{ANNOTATIONS_JSON}}",
                        jsonlite::toJSON(notes_pdf, auto_unbox = FALSE, dataframe = "rows"),
                        html_final, fixed = TRUE)

      cat("✅ HTML autònom generat per:", nom_document, "amb", nrow(notes_pdf), "anotacions\n")
      return(html_final)
    }, error = function(e) {
      cat("❌ Error generant PDF autònom:", conditionMessage(e), "\n")
      return("")
    })
  }

  # Genera l'HTML tancat estàtic de només lectura per a les exportacions
  generar_html_estatic <- function(nom_document) {
    tryCatch({
      dir_user <- DIRECTORI_HTMLs()
      ruta_real <- file.path(dir_user, nom_document)
      if (!file.exists(ruta_real)) return("")

      html_base <- paste(readLines(ruta_real, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

      # Validar que html_base és vàlid
      if (is.null(html_base) || length(html_base) == 0 || !validUTF8(html_base)) {
        cat("⚠️ HTML base invàlid (estàtic) per:", nom_document, "\n")
        return("")
      }

      totes_les_notes <- llegir_dades()

      notes_filtrades <- data.frame()
      if (nrow(totes_les_notes) > 0 && "doc" %in% names(totes_les_notes)) {
        notes_filtrades <- totes_les_notes[totes_les_notes$doc == nom_document, ]
      }

      js_notes <- jsonlite::toJSON(notes_filtrades, auto_unbox = FALSE)
      js_injectable_estatic <- sub("TEXT_JSON_NOTES", js_notes, JS_EXPORTACIO_ESTATIC, fixed = TRUE)

      html_final <- sub("</body>", paste0(js_injectable_estatic, "</body>"), html_base, ignore.case = TRUE)
      if(html_base == html_final) html_final <- paste0(html_base, js_injectable_estatic)
      return(html_final)
    }, error = function(e) {
      cat("❌ Error a generar_html_estatic:", conditionMessage(e), "\n")
      cat("   Document:", nom_document, "\n")
      return("")
    })
  }
  
  # Obrir automàticament el panell d'admin si és administrador
  observe({
    if (es_admin()) {
      # Esperar un moment perquè la UI estigui carregada
      shinyjs::delay(500, {
        shinyjs::runjs("
          // Buscar el botó d'Admin mode i clicar-lo automàticament
          var adminBtn = document.querySelector('a[data-toggle=\"sidebar-admin\"]') ||
                         document.querySelector('.fa-users-cog')?.parentElement ||
                         document.querySelector('[id*=\"admin\"]') ||
                         Array.from(document.querySelectorAll('a')).find(a => a.textContent.includes('Admin'));

          if (adminBtn) {
            adminBtn.click();
          } else {
            // Si no troba el botó, intentar amb el mètode de shinymanager
            setTimeout(function() {
              var btns = document.querySelectorAll('a, button');
              for (var i = 0; i < btns.length; i++) {
                if (btns[i].textContent.includes('Admin') || btns[i].id.includes('admin')) {
                  btns[i].click();
                  break;
                }
              }
            }, 100);
          }
        ")
      })
    }
  })

  output$visor_dinamic <- renderUI({

    req(input$selector_doc)
    if (input$selector_doc == "No s'han trobat HTMLs" || input$selector_doc == "") {
      return(h4("No hi ha documents."))
    }

    # Detectar si és PDF o HTML
    extension <- tolower(tools::file_ext(input$selector_doc))

    if (extension == "pdf") {
      # Visor PDF personalitzat amb anotacions
      nom_usuari_actual <- if (!is.null(input$nom_usuari) && input$nom_usuari != "") {
        input$nom_usuari
      } else {
        bacteri_sessio()
      }

      # Utilitzar ruta servida per addResourcePath amb subdirectori d'usuari
      pdf_url <- paste0("documents/", usuari_actual(), "/", input$selector_doc)

      tags$iframe(
        id = "pdf_viewer",
        src = paste0("pdf_viewer.html?file=", URLencode(pdf_url, reserved = TRUE),
                     "&doc=", URLencode(input$selector_doc, reserved = TRUE),
                     "&user=", URLencode(nom_usuari_actual, reserved = TRUE)),
        style = "width: 100%; height: calc(100vh - 180px); border: 1px solid #dee2e6; background: white;"
      )
    } else {
      # Visor HTML
      tags$iframe(
        id = "iframe_document",
        srcdoc = generar_html_visor(input$selector_doc, input$nom_usuari, bacteri_sessio()),
        style = "width: 100%; height: calc(100vh - 180px); border: 1px solid #dee2e6; background: white;"
      )
    }
  })
  
  observeEvent(input$guardar_anotacio, {
    dades <- input$guardar_anotacio
    req(dades$text, input$selector_doc)

    # Generar nom d'usuari (bacteri persistent si està buit)
    if (is.null(input$nom_usuari) || input$nom_usuari == "" || trimws(input$nom_usuari) == "") {
      nom_usuari_final <- bacteri_sessio()
    } else {
      nom_usuari_final <- trimws(input$nom_usuari)
    }

    historial <- llegir_dades()
    nova_fila <- data.frame(
      id = as.character(dades$id),
      doc = as.character(input$selector_doc),
      text = as.character(dades$text),
      element_idx = as.integer(dades$element_idx),
      usuari = as.character(nom_usuari_final),
      tipus = "html",
      pagina = NA_integer_,
      x = NA_real_,
      y = NA_real_,
      stringsAsFactors = FALSE
    )
    if (nrow(historial) == 0) { historial_actualitzat <- nova_fila } else { historial_actualitzat <- rbind(historial, nova_fila) }
    saveRDS(historial_actualitzat, FITXER_DADES)
  })
  
  observeEvent(input$id_a_esborrar, {
    req(input$id_a_esborrar$id)
    target_id <- input$id_a_esborrar$id
    historial <- llegir_dades()
    if (nrow(historial) > 0 && "id" %in% names(historial)) {
      historial_filtrat <- historial[historial$id != target_id, ]
      saveRDS(historial_filtrat, FITXER_DADES)
    }
  })

  # ========== OBSERVERS PER ANOTACIONS PDF ==========

  # Guardar anotació PDF
  observeEvent(input$guardar_anotacio_pdf, {
    cat("📥 Rebut event guardar_anotacio_pdf\n")
    dades <- input$guardar_anotacio_pdf
    req(dades$text, input$selector_doc)

    # Generar nom d'usuari
    if (is.null(input$nom_usuari) || input$nom_usuari == "" || trimws(input$nom_usuari) == "") {
      nom_usuari_final <- bacteri_sessio()
    } else {
      nom_usuari_final <- trimws(input$nom_usuari)
    }

    cat("💾 Guardant anotació PDF:", dades$text, "| Pàgina:", dades$pagina, "| Usuari:", nom_usuari_final, "\n")

    historial <- llegir_dades()
    nova_fila <- data.frame(
      id = as.character(dades$id),
      doc = as.character(input$selector_doc),
      text = as.character(dades$text),
      element_idx = NA_integer_,
      usuari = as.character(nom_usuari_final),
      tipus = "pdf",
      pagina = as.integer(dades$pagina),
      x = as.numeric(dades$x),
      y = as.numeric(dades$y),
      stringsAsFactors = FALSE
    )

    if (nrow(historial) == 0) {
      historial_actualitzat <- nova_fila
    } else {
      historial_actualitzat <- rbind(historial, nova_fila)
    }
    saveRDS(historial_actualitzat, FITXER_DADES)
    cat("✅ Anotació PDF guardada correctament\n")
  })

  # Esborrar anotació PDF
  observeEvent(input$esborrar_anotacio_pdf, {
    req(input$esborrar_anotacio_pdf$id)
    target_id <- input$esborrar_anotacio_pdf$id
    historial <- llegir_dades()
    if (nrow(historial) > 0 && "id" %in% names(historial)) {
      historial_filtrat <- historial[historial$id != target_id, ]
      saveRDS(historial_filtrat, FITXER_DADES)
    }
  })

  # Enviar anotacions PDF existents al visor
  observeEvent(input$request_annotations_pdf, {
    cat("📥 Rebut request_annotations_pdf\n")
    req(input$request_annotations_pdf$doc)
    doc_name <- input$request_annotations_pdf$doc

    cat("🔍 Buscant anotacions per:", doc_name, "\n")

    totes_les_notes <- llegir_dades()

    if (nrow(totes_les_notes) > 0 && "doc" %in% names(totes_les_notes) && "tipus" %in% names(totes_les_notes)) {
      notes_pdf <- totes_les_notes[totes_les_notes$doc == doc_name & totes_les_notes$tipus == "pdf", ]

      cat("📊 Anotacions trobades:", nrow(notes_pdf), "\n")

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
        cat("✅ Anotacions enviades a l'iframe\n")
      }
    } else {
      cat("ℹ️ No hi ha anotacions per aquest document\n")
    }
  })

  observeEvent(input$guardar_servidor, {
    req(input$selector_doc)

    # Generar timestamp: YYYYMMDD_HHMMSS
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    extension <- tolower(tools::file_ext(input$selector_doc))
    nom_base <- tools::file_path_sans_ext(input$selector_doc)

    # Directori de sortida de l'usuari
    dir_sortida <- DIRECTORI_SORTIDA()

    if (extension == "pdf") {
      # Per PDFs, generem un HTML autònom amb el PDF i anotacions incrustades
      nom_fitxer <- paste0(timestamp, "_", nom_base, ".html")
      ruta_desti <- file.path(dir_sortida, nom_fitxer)

      html_autonom <- generar_pdf_autonom(input$selector_doc)

      if (nchar(html_autonom) > 0) {
        writeLines(html_autonom, ruta_desti, useBytes = TRUE)
        status_msg(paste0("✔️ PDF exportat com HTML: ", nom_fitxer))
      } else {
        status_msg("❌ Error generant l'exportació del PDF")
      }
    } else {
      # Per HTMLs
      nom_fitxer <- paste0(timestamp, "_", input$selector_doc)
      ruta_desti <- file.path(dir_sortida, nom_fitxer)
      html_contingut <- generar_html_estatic(input$selector_doc)

      if (nchar(html_contingut) > 0) {
        writeLines(html_contingut, ruta_desti)
        status_msg(paste0("✔️ HTML guardat: ", nom_fitxer))
      } else {
        status_msg("❌ Error generant l'HTML anotat")
      }
    }
  })
  output$avis_guardat <- renderText({ status_msg() })

  # Esborrar document
  observeEvent(input$esborrar_doc, {
    req(input$selector_doc)

    if (input$selector_doc == "No s'han trobat HTMLs" || input$selector_doc == "") {
      status_msg("⚠️ No hi ha cap document seleccionat per esborrar")
      return()
    }

    # Mostrar confirmació amb shinyjs
    shinyjs::runjs(sprintf(
      "if (confirm('⚠️ ATENCIÓ\\n\\nEstàs segur que vols esborrar:\\n\\n%s\\n\\nAquesta acció NO es pot desfer!\\n\\nTambé s\\'esborraran totes les anotacions associades.')) {
         Shiny.setInputValue('confirmar_esborrar', Math.random(), {priority: 'event'});
       }",
      input$selector_doc
    ))
  })

  # Confirmació d'esborrat
  observeEvent(input$confirmar_esborrar, {
    req(input$selector_doc)

    doc_a_esborrar <- input$selector_doc
    dir_user <- DIRECTORI_HTMLs()
    dir_sortida <- DIRECTORI_SORTIDA()
    ruta_document <- file.path(dir_user, doc_a_esborrar)

    tryCatch({
      # 1. Esborrar el document original (del directori de l'usuari)
      if (file.exists(ruta_document)) {
        file.remove(ruta_document)
        cat("🗑️ Document original esborrat:", doc_a_esborrar, "\n")

        # 2. Esborrar anotacions de la base de dades
        historial <- llegir_dades()
        num_anotacions_esborrades <- 0
        if (nrow(historial) > 0 && "doc" %in% names(historial)) {
          historial_filtrat <- historial[historial$doc != doc_a_esborrar, ]
          saveRDS(historial_filtrat, FITXER_DADES)
          num_anotacions_esborrades <- nrow(historial) - nrow(historial_filtrat)
          if (num_anotacions_esborrades > 0) {
            cat("🗑️ Anotacions esborrades de la BD:", num_anotacions_esborrades, "\n")
          }
        }

        # 3. Esborrar tots els fitxers exportats relacionats (del directori de l'usuari)
        # Nom base sense extensió per buscar
        nom_base <- tools::file_path_sans_ext(doc_a_esborrar)

        # Llistar tots els fitxers del directori de sortida de l'usuari
        fitxers_anotats <- list.files(dir_sortida, full.names = TRUE)

        # Buscar fitxers que continguin el nom base del document
        # Patró: poden començar amb timestamp o "anotat_" o "anotacions_" i contenir el nom
        fitxers_a_esborrar <- fitxers_anotats[grepl(nom_base, basename(fitxers_anotats), fixed = TRUE)]

        num_exportacions_esborrades <- 0
        if (length(fitxers_a_esborrar) > 0) {
          for (fitxer in fitxers_a_esborrar) {
            if (file.exists(fitxer)) {
              file.remove(fitxer)
              cat("🗑️ Exportació esborrada:", basename(fitxer), "\n")
              num_exportacions_esborrades <- num_exportacions_esborrades + 1
            }
          }
        }

        # Missatge final resum
        missatge_final <- paste0("✅ Esborrat complet:\n",
                                "• Document: ", doc_a_esborrar)
        if (num_anotacions_esborrades > 0) {
          missatge_final <- paste0(missatge_final, "\n• Anotacions: ", num_anotacions_esborrades)
        }
        if (num_exportacions_esborrades > 0) {
          missatge_final <- paste0(missatge_final, "\n• Exportacions: ", num_exportacions_esborrades)
        }

        status_msg(missatge_final)

      } else {
        status_msg(paste0("❌ No s'ha trobat el fitxer: ", doc_a_esborrar))
      }
    }, error = function(e) {
      cat("❌ Error esborrant document:", conditionMessage(e), "\n")
      status_msg(paste0("❌ Error: ", conditionMessage(e)))
    })
  })

  output$descarregar_html <- downloadHandler(
    filename = function() {
      # Generar timestamp: YYYYMMDD_HHMMSS
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      extension <- tolower(tools::file_ext(input$selector_doc))
      nom_base <- tools::file_path_sans_ext(input$selector_doc)

      if (extension == "pdf") {
        paste0(timestamp, "_", nom_base, ".html")
      } else {
        paste0(timestamp, "_", input$selector_doc)
      }
    },
    content = function(file) {
      extension <- tolower(tools::file_ext(input$selector_doc))

      if (extension == "pdf") {
        # Per PDFs, generem HTML autònom amb PDF i anotacions
        html_autonom <- generar_pdf_autonom(input$selector_doc)
        writeLines(html_autonom, file, useBytes = TRUE)
      } else {
        # Per HTMLs, descarreguem l'HTML anotat
        writeLines(generar_html_estatic(input$selector_doc), file)
      }
    }
  )
}

# Afegir autenticació amb shinymanager
ui <- secure_app(ui_base,
                 theme = "flatly",
                 enable_admin = TRUE,
                 language = "es",
                 choose_language = FALSE)

shinyApp(ui = ui, server = server)
