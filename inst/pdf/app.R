library(Comenta)
library(shiny)
library(bs4Dash)
library(jsonlite)
library(httr)
library(shinyjs)
library(reticulate)

# ============================================================
# AnotaR PyMuPDF - Anotacions permanents
# ============================================================

# Desactivar virtualenv (compatibilitat Shiny Server)
Sys.unsetenv("VIRTUAL_ENV")
Sys.unsetenv("PYTHONHOME")

# Configurar Python
python_configurat <- FALSE
missatge_error <- NULL

tryCatch({
  # Prioritzar virtualenv amb PyMuPDF instal·lat
  python_paths <- c(
    "/home/josep/.virtualenvs/r-reticulate/bin/python3",
    "/usr/bin/python3",
    "/usr/local/bin/python3",
    Sys.which("python3")
  )

  python_path <- NULL
  for (path in python_paths) {
    if (file.exists(path) && path != "") {
      python_path <- path
      break
    }
  }

  if (is.null(python_path)) {
    stop("No s'ha trobat Python3")
  }

  use_python(python_path, required = TRUE)

  if (!py_module_available("fitz")) {
    stop("PyMuPDF no instal·lat. Executa: pip3 install PyMuPDF")
  }

  python_configurat <- TRUE

}, error = function(e) {
  missatge_error <<- e$message
})

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
          "PDF · anotacions permanents amb IA"
        )
      )
    )
  ),
  sidebar = dashboardSidebar(
    tags$div(style = "padding: 20px 15px;",
      # Avís anotacions permanents + funcions noves
      tags$div(
        style = "background: rgba(76, 175, 80, 0.15); padding: 12px; border-radius: 6px; border-left: 4px solid #4CAF50; margin-bottom: 15px;",
        tags$div(style = "color: white; font-size: 12px; font-weight: 600; margin-bottom: 6px;", "✨ Funcionalitats"),
        tags$div(style = "color: rgba(255,255,255,0.9); font-size: 10px; line-height: 1.4;",
          HTML("
            ✓ Anotacions permanents al PDF<br>
            ✓ OCR automàtic per PDFs escanejats<br>
            ✓ Cerca ràpida a PubMed/NCBI/UniProt<br>
            ✓ Enllaços automàtics a termes biomèdics
          ")
        )
      ),

      # Nom usuari
      textInput("nom_usuari", "👤 El teu nom:", value = "Josep"),

      hr(),

      # Pujar PDF
      tags$div(style = "margin-bottom: 10px;",
        tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 5px; display: block;", "📄 Puja PDF"),
        fileInput("pujar_pdf", NULL, accept = c("application/pdf", ".pdf"),
                  buttonLabel = "Seleccionar PDF",
                  placeholder = "Cap fitxer seleccionat"),
        tags$div(
          style = "color: rgba(255,255,255,0.8); font-size: 10px; margin-top: -10px; padding: 5px 0;",
          "💡 Pots pujar un PDF ja anotat per afegir més anotacions"
        )
      ),

      hr(),

      # Anotació
      tags$label(style = "color: white; font-weight: 500; font-size: 13px;", "✍️ Nova anotació"),

      tags$div(style = "position: relative;",
        textAreaInput("text_buscar", "🔍 Text a buscar:",
                     height = "70px",
                     placeholder = "Text que vols anotar..."),

        # Botons de cerca ràpida
        tags$div(style = "margin-top: -10px; margin-bottom: 10px;",
          actionButton("cerca_pubmed", "📚 PubMed",
                      class = "btn-info btn-xs",
                      style = "font-size: 10px; padding: 2px 8px; margin-right: 5px;"),
          actionButton("cerca_ncbi_gene", "🧬 NCBI Gene",
                      class = "btn-info btn-xs",
                      style = "font-size: 10px; padding: 2px 8px; margin-right: 5px;"),
          actionButton("cerca_uniprot", "🔬 UniProt",
                      class = "btn-info btn-xs",
                      style = "font-size: 10px; padding: 2px 8px;")
        )
      ),

      textAreaInput("comentari", "💬 Comentari:",
                   height = "70px",
                   placeholder = "El teu comentari..."),

      # Secció IA - Assistents amb múltiples accions
      tags$div(
        style = "background: rgba(156, 39, 176, 0.1); padding: 10px; border-radius: 6px; margin-bottom: 10px; border-left: 3px solid #9c27b0;",

        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
          tags$label(style = "color: white; font-weight: 600; font-size: 12px; margin: 0;", "🤖 Assistent IA"),
          actionButton("toggle_ia_config", "⚙️",
                      class = "btn-xs",
                      style = "background: transparent; border: 1px solid rgba(255,255,255,0.3); color: white; padding: 2px 8px; font-size: 10px;")
        ),

        # Configuració IA (plegable)
        conditionalPanel(
          condition = "input.toggle_ia_config % 2 == 1",

          selectInput("ia_model", "Model:",
                     choices = c("Selecciona..." = "", "Gemini Flash (Google)" = "gemini", "Ollama Local" = "ollama"),
                     selected = ""),

          # Selector de model Ollama (condicional)
          conditionalPanel(
            condition = "input.ia_model == 'ollama'",
            uiOutput("ollama_model_selector")
          ),

          # API Key per Gemini (condicional)
          conditionalPanel(
            condition = "input.ia_model == 'gemini'",
            textInput("gemini_api_key", "API Key:",
                     placeholder = "AIzaSy..."),
            tags$div(
              style = "color: rgba(255,255,255,0.7); font-size: 9px; margin-top: -8px;",
              HTML("Obté-la gratuït a <a href='https://makersuite.google.com/app/apikey' target='_blank' style='color: #ffeb3b;'>Google AI Studio</a>")
            )
          ),

          selectInput("ia_idioma", "Idioma:",
                     choices = c("Català" = "catala", "Espanyol" = "espanyol", "Anglès" = "angles"),
                     selected = "catala"),

          tags$div(style = "margin-top: 5px;",
            uiOutput("ia_status_text")
          )
        ),

        # Botons d'acció IA (sempre visibles)
        tags$div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 5px; margin-top: 5px;",
          actionButton("interpretar_ia", "🔍 Interpretar",
                      class = "btn-info btn-sm",
                      style = "width: 100%; font-size: 11px; padding: 6px;"),
          actionButton("analitzar_ia", "📊 Analitzar",
                      class = "btn-primary btn-sm",
                      style = "width: 100%; font-size: 11px; padding: 6px;"),
          actionButton("recomanar_ia", "💡 Recomanar",
                      class = "btn-success btn-sm",
                      style = "width: 100%; font-size: 11px; padding: 6px;"),
          actionButton("resumir_ia", "📝 Resumir",
                      class = "btn-warning btn-sm",
                      style = "width: 100%; font-size: 11px; padding: 6px;")
        )
      ),

      actionButton("afegir", "➕ Afegir",
                  class = "btn-primary",
                  style = "width: 100%; margin-bottom: 10px;"),

      actionButton("generar_pdf", "🎨 Generar PDF Anotat",
                  class = "btn-success",
                  style = "width: 100%; font-weight: 600; margin-bottom: 8px;"),

      actionButton("netejar_llista", "🧹 Netejar llista",
                  class = "btn-warning btn-sm",
                  style = "width: 100%; font-size: 12px;"),

      hr(),

      # Descarregar
      uiOutput("botons_descarregar"),

      # Botó per combinar fluxos
      conditionalPanel(
        condition = "output.status && output.status.includes('processades')",
        hr(),
        tags$div(
          style = "background: #e7f3ff; padding: 12px; border-radius: 6px; border-left: 4px solid #2196F3; margin-bottom: 10px;",
          tags$div(style = "color: #0c5460; font-weight: 600; margin-bottom: 5px; font-size: 12px;", "🔄 Vols afegir més anotacions?"),
          tags$div(style = "color: #0c5460; font-size: 11px; margin-bottom: 8px;",
            "1. Descarrega el PDF anotat<br>2. Torna a pujar-lo aquí<br>3. Afegeix més anotacions amb el formulari"
          ),
          actionButton("reiniciar_amb_anotat", "📤 Carregar PDF anotat",
                      class = "btn-info btn-sm",
                      style = "width: 100%; font-size: 11px;")
        )
      ),

      br(),
      textOutput("status")
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
          background: linear-gradient(180deg, #28a745 0%, #218838 100%) !important;
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

        .sidebar .btn-primary {
          background: #2196F3 !important;
          color: white !important;
          border: none;
          font-weight: 600;
          border-radius: 8px;
          padding: 10px 20px;
        }

        #status {
          color: #ffffff;
          background: rgba(255, 255, 255, 0.15);
          padding: 10px;
          border-radius: 8px;
          font-size: 11px;
          text-align: center;
        }

        .main-header {
          background: linear-gradient(135deg, #28a745 0%, #218838 100%) !important;
          box-shadow: 0 2px 10px rgba(40, 167, 69, 0.2);
        }

        .content-wrapper {
          background-color: #f5f6fa;
        }

        iframe, embed {
          border: 1px solid #e9ecef !important;
          border-radius: 8px !important;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06) !important;
        }

        /* Notificacions al lateral dret, més petites */
        .shiny-notification {
          position: fixed !important;
          top: 80px !important;
          right: 20px !important;
          left: auto !important;
          width: 350px !important;
          max-width: 350px !important;
          font-size: 13px !important;
          padding: 12px 16px !important;
          border-radius: 8px !important;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
          z-index: 9999 !important;
        }

        .shiny-notification-message {
          font-size: 13px !important;
          line-height: 1.4 !important;
        }

        .shiny-notification-error {
          background-color: #f8d7da !important;
          border-left: 4px solid #dc3545 !important;
        }

        .shiny-notification-warning {
          background-color: #fff3cd !important;
          border-left: 4px solid #ffc107 !important;
        }

        .shiny-notification-message-type {
          background-color: #d1ecf1 !important;
          border-left: 4px solid #17a2b8 !important;
        }
      "))
    ),
    useShinyjs(),

    # Llista d'anotacions a processar
    box(
      width = 12,
      title = "📋 Anotacions a processar",
      status = "success",
      solidHeader = TRUE,
      collapsible = TRUE,
      uiOutput("llista_anotacions")
    ),

    # Anotacions ja afegides al PDF
    uiOutput("box_anotacions_pdf"),

    # Visor PDF
    tags$div(
      id = "pdf-viewer-container",
      style = "margin: 0 -15px; padding: 0;",
      box(
        width = 12,
        title = "👁️ Previsualització PDF",
        status = "info",
        solidHeader = TRUE,
        collapsible = TRUE,

        tags$style(HTML("
          #pdf-viewer-container .box-body {
            padding: 0 !important;
          }
        ")),

        uiOutput("visor_pdf")
      )
    ),

    # Footer
    tags$div(
      style = "position: fixed; bottom: 0; left: 0; right: 0; background: rgba(255,255,255,0.95); padding: 10px; text-align: center; font-size: 11px; color: #666; border-top: 1px solid #dee2e6; z-index: 1000; backdrop-filter: blur(5px);",
      HTML('AnotaR PyMuPDF v1.0.0 | <a href="https://pymupdf.readthedocs.io/" target="_blank" style="color: #28a745;">PyMuPDF</a> | IDISBA Bioinformàtica')
    )
  )
)

server <- function(input, output, session) {

  # Wrapper per cridar funcions Python
  call_py_func <- function(func_name, ...) {
    if (!is.null(py[[func_name]])) {
      return(py[[func_name]](...))
    } else {
      stop(paste("Funció Python", func_name, "no disponible"))
    }
  }

  # Carregar helpers d'IA (ja disponibles via library(Comenta))
  ia_gemini_disponible <- gemini_disponible()
  if (ia_gemini_disponible) {
    cat("✓ Gemini helper carregat\n")
  }

  ia_ollama_disponible <- ollama_disponible()
  if (ia_ollama_disponible) {
    cat("✓ Ollama disponible\n")
  } else {
    cat("⚠️ Ollama no disponible (opcional)\n")
  }

  # Funció per detectar i enllaçar termes biomèdics
  enriquir_text <- function(text) {
    if (is.null(text) || text == "") return(text)

    text_enriquit <- text

    # Detectar DOIs
    text_enriquit <- gsub(
      "(10\\.\\d{4,}/[^\\s]+)",
      "<a href='https://doi.org/\\1' target='_blank' style='color: #007bff;'>\\1</a>",
      text_enriquit
    )

    # Detectar PMIDs (PubMed IDs)
    text_enriquit <- gsub(
      "\\b(PMID:?\\s*(\\d{6,8}))\\b",
      "<a href='https://pubmed.ncbi.nlm.nih.gov/\\2/' target='_blank' style='color: #007bff;'>\\1</a>",
      text_enriquit,
      ignore.case = TRUE
    )

    # Detectar gens comuns (patró: majúscules seguides de números)
    # Ex: BRCA1, TP53, HER2, CD8
    text_enriquit <- gsub(
      "\\b([A-Z]{2,}[0-9]+[A-Z]*)\\b",
      "<a href='https://www.ncbi.nlm.nih.gov/gene/?term=\\1' target='_blank' style='color: #28a745;' title='Cercar gen a NCBI'>\\1 🧬</a>",
      text_enriquit
    )

    # Detectar números Entrez Gene
    text_enriquit <- gsub(
      "\\b(Gene ID:?\\s*(\\d{4,}))\\b",
      "<a href='https://www.ncbi.nlm.nih.gov/gene/\\2' target='_blank' style='color: #007bff;'>\\1</a>",
      text_enriquit,
      ignore.case = TRUE
    )

    # Detectar números UniProt
    text_enriquit <- gsub(
      "\\b([A-Z][0-9][A-Z0-9]{3}[0-9]|[OPQ][0-9][A-Z0-9]{3}[0-9])\\b",
      "<a href='https://www.uniprot.org/uniprotkb/\\1' target='_blank' style='color: #9c27b0;' title='Veure a UniProt'>\\1 🔬</a>",
      text_enriquit
    )

    return(text_enriquit)
  }

  # Crear directori temporal per aquesta sessió
  session_pdf_dir <- file.path(tempdir(), "shiny_pdf_viewer", session$token)
  dir.create(session_pdf_dir, recursive = TRUE, showWarnings = FALSE, mode = "0777")

  # Copiar script Python al directori temporal (té permisos d'escriptura)
  python_script <- system.file("python", "anotar_pdf.py", package = "Comenta")
  python_script_dest <- file.path(session_pdf_dir, "anotar_pdf.py")
  if (file.exists(python_script)) {
    file.copy(python_script, python_script_dest, overwrite = TRUE)
    cat("✓ Script Python copiat a:", python_script_dest, "\n")
  } else {
    warning("⚠️ No s'ha trobat anotar_pdf.py al paquet")
  }

  # Netejar al tancar la sessió
  session$onSessionEnded(function() {
    if (dir.exists(session_pdf_dir)) {
      unlink(session_pdf_dir, recursive = TRUE)
    }
  })

  # Variables reactives
  anotacions <- reactiveVal(list())
  anotacions_pdf <- reactiveVal(list())  # Anotacions que ja estan al PDF generat
  pdf_anotat_path <- reactiveVal(NULL)
  pdf_actual <- reactiveVal(NULL)
  pdf_actual_nom <- reactiveVal("nihms-1548654.pdf")

  # === Secció IA ===

  # Selector de models Ollama
  output$ollama_model_selector <- renderUI({
    if (ia_ollama_disponible) {
      models <- ollama_llistar_models()

      if (length(models) > 0) {
        model_recomanat <- ollama_model_recomanat()

        selectInput("ollama_model", "Model Ollama:",
                   choices = setNames(models, models),
                   selected = model_recomanat)
      } else {
        tags$div(
          style = "color: rgba(255,255,255,0.8); font-size: 10px; padding: 5px;",
          "⚠️ Cap model instal·lat. Executa: ollama pull qwen2.5:7b"
        )
      }
    } else {
      tags$div(
        style = "color: rgba(255,255,255,0.8); font-size: 10px; padding: 5px;",
        "❌ Ollama no disponible. Verifica que està executant-se."
      )
    }
  })

  # Estat de configuració IA
  output$ia_status_text <- renderUI({
    model <- input$ia_model

    if (is.null(model) || model == "") {
      return(tags$div(
        style = "color: rgba(255,255,255,0.7); font-size: 9px;",
        "Selecciona un model per activar l'assistent IA"
      ))
    }

    if (model == "gemini") {
      api_key <- input$gemini_api_key

      if (is.null(api_key) || api_key == "") {
        return(tags$div(
          style = "color: #ff9800; font-size: 9px;",
          "⚠️ Introdueix l'API key de Gemini"
        ))
      } else {
        return(tags$div(
          style = "color: #4caf50; font-size: 9px;",
          "✅ Gemini configurat (gratuït, 1M tokens/mes)"
        ))
      }
    } else if (model == "ollama") {
      if (ia_ollama_disponible) {
        return(tags$div(
          style = "color: #4caf50; font-size: 9px;",
          "✅ Ollama disponible (100% local, privat)"
        ))
      } else {
        return(tags$div(
          style = "color: #ff9800; font-size: 9px;",
          "❌ Ollama no disponible"
        ))
      }
    }
  })

  # Funció auxiliar per executar accions d'IA
  executar_accio_ia <- function(accio, text, model, idioma, api_key = NULL, ollama_model = NULL, min_chars = 20) {

    if (text == "" || nchar(text) < min_chars) {
      showNotification(
        paste0("⚠️ Escriu text per ", accio, " (mínim ", min_chars, " caràcters)"),
        type = "warning",
        duration = 3
      )
      return(NULL)
    }

    if (is.null(model) || model == "") {
      showNotification(
        "⚠️ Selecciona un model d'IA primer",
        type = "warning",
        duration = 3
      )
      return(NULL)
    }

    missatge_map <- list(
      'interpretar' = '🔍 Interpretant',
      'analitzar' = '📊 Analitzant',
      'recomanar' = '💡 Generant recomanacions',
      'resumir' = '📝 Resumint'
    )

    missatge <- missatge_map[[accio]] %||% '🤖 Processant'

    resultat <- withProgress(message = paste0(missatge, ' amb IA...'), value = 0, {
      tryCatch({
        incProgress(0.2, detail = "Preparant...")

        res <- NULL

        if (model == "gemini") {
          # Verificar API key
          if (is.null(api_key) || api_key == "") {
            stop("Introdueix l'API key de Gemini")
          }

          # Configurar temporalment l'API key
          Sys.setenv(GEMINI_API_KEY = api_key)

          incProgress(0.3, detail = "Enviant a Gemini...")

          res <- switch(accio,
            'interpretar' = interpretar_resultats_gemini(
              text = text,
              tipus = "general",
              idioma = idioma
            ),
            'analitzar' = analitzar_dades_gemini(
              text = text,
              context = "",
              idioma = idioma
            ),
            'recomanar' = recomanacions_gemini(
              text = text,
              idioma = idioma
            ),
            'resumir' = resumir_text_gemini(
              text = text,
              max_paraules = 150,
              idioma = idioma
            )
          )

        } else if (model == "ollama") {
          if (!ia_ollama_disponible) {
            stop("Ollama no està disponible")
          }

          if (is.null(ollama_model) || ollama_model == "") {
            stop("Selecciona un model d'Ollama")
          }

          incProgress(0.3, detail = paste0("Processant amb ", ollama_model, "..."))

          res <- switch(accio,
            'interpretar' = interpretar_resultats_ollama(
              text = text,
              model = ollama_model,
              tipus = "general",
              idioma = idioma
            ),
            'analitzar' = analitzar_dades_ollama(
              text = text,
              model = ollama_model,
              context = "",
              idioma = idioma
            ),
            'recomanar' = recomanacions_ollama(
              text = text,
              model = ollama_model,
              idioma = idioma
            ),
            'resumir' = resumir_text_ollama(
              text = text,
              model = ollama_model,
              max_paraules = 150,
              idioma = idioma
            )
          )
        } else {
          stop("Model no reconegut")
        }

        incProgress(0.4, detail = "Rebent resultat...")

        cat("📥 Resultat IA rebut:\n")
        cat("   Classe:", class(res), "\n")
        cat("   NULL?:", is.null(res), "\n")
        if (!is.null(res)) {
          cat("   Longitud:", nchar(as.character(res)), "\n")
        }

        return(res)

      }, error = function(e) {
        cat("❌ Error executant IA:", e$message, "\n")
        showNotification(
          HTML(paste0("<strong>❌ Error:</strong><br>", e$message)),
          type = "error",
          duration = 10
        )
        return(NULL)
      })
    })

    cat("📤 Retornant resultat des de executar_accio_ia\n")
    cat("   Classe resultat:", class(resultat), "\n")
    cat("   NULL?:", is.null(resultat), "\n")

    return(resultat)
  }

  # Interpretar amb IA
  observeEvent(input$interpretar_ia, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    cat("🔍 Interpretant...\n")
    cat("   Text longitud:", nchar(text), "\n")
    cat("   Model:", input$ia_model, "\n")

    resultat <- executar_accio_ia(
      accio = "interpretar",
      text = text,
      model = input$ia_model,
      idioma = input$ia_idioma %||% "catala",
      api_key = input$gemini_api_key,
      ollama_model = input$ollama_model,
      min_chars = 20
    )

    # Reduir text_buscar a primeres 6-8 paraules per identificació única
    text_net <- gsub("\\s+", " ", trimws(text))
    paraules <- strsplit(text_net, " ")[[1]]
    num_paraules <- min(8, length(paraules))
    text_identificador <- paste(paraules[1:num_paraules], collapse = " ")

    cat("   Resultat rebut:", !is.null(resultat), "\n")
    cat("   Classe resultat:", class(resultat), "\n")

    if (!is.null(resultat)) {
      cat("   Resultat longitud:", nchar(as.character(resultat)), "\n")
      cat("   Resultat (primeres 100 chars):", substr(as.character(resultat), 1, 100), "\n")
    }

    if (!is.null(resultat) && nchar(as.character(resultat)) > 0) {
      cat("   ✅ Actualitzant textarea...\n")

      resultat_text <- as.character(resultat)

      # Actualitzar text_buscar amb només les primeres paraules
      updateTextAreaInput(
        session,
        "text_buscar",
        value = text_identificador
      )

      updateTextAreaInput(
        session,
        "comentari",
        value = paste0("🔍 Interpretació IA: ", resultat_text)
      )

      cat("   ✅ updateTextAreaInput executat (text identificador:", num_paraules, "paraules)\n")

      # Afegir automàticament l'anotació
      Sys.sleep(0.3)  # Petit delay per assegurar que el textarea s'ha actualitzat
      shinyjs::click("afegir")
      cat("   ✅ Botó 'afegir' clicat automàticament\n")

      showNotification(
        HTML(paste0(
          "✅ Interpretació generada i afegida (", nchar(resultat_text), " chars)<br>",
          "<small>Clica 'Generar PDF Anotat' quan estiguis preparat</small>"
        )),
        type = "message",
        duration = 5
      )
    } else {
      cat("   ❌ Resultat NULL o buit\n")
      showNotification(
        "❌ No s'ha rebut resultat de la IA",
        type = "error",
        duration = 5
      )
    }
  })

  # Analitzar amb IA
  observeEvent(input$analitzar_ia, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    resultat <- executar_accio_ia(
      accio = "analitzar",
      text = text,
      model = input$ia_model,
      idioma = input$ia_idioma %||% "catala",
      api_key = input$gemini_api_key,
      ollama_model = input$ollama_model,
      min_chars = 20
    )

    # Reduir text_buscar a primeres 6-8 paraules per identificació única
    text_net <- gsub("\\s+", " ", trimws(text))
    paraules <- strsplit(text_net, " ")[[1]]
    num_paraules <- min(8, length(paraules))
    text_identificador <- paste(paraules[1:num_paraules], collapse = " ")

    if (!is.null(resultat) && nchar(resultat) > 0) {
      # Actualitzar text_buscar amb només les primeres paraules
      updateTextAreaInput(
        session,
        "text_buscar",
        value = text_identificador
      )

      updateTextAreaInput(
        session,
        "comentari",
        value = paste0("📊 Anàlisi IA: ", resultat)
      )

      # Afegir automàticament l'anotació
      Sys.sleep(0.3)
      shinyjs::click("afegir")

      showNotification(
        HTML(paste0(
          "✅ Anàlisi generada i afegida<br>",
          "<small>Clica 'Generar PDF Anotat' quan estiguis preparat</small>"
        )),
        type = "message",
        duration = 5
      )
    }
  })

  # Recomanar amb IA
  observeEvent(input$recomanar_ia, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    resultat <- executar_accio_ia(
      accio = "recomanar",
      text = text,
      model = input$ia_model,
      idioma = input$ia_idioma %||% "catala",
      api_key = input$gemini_api_key,
      ollama_model = input$ollama_model,
      min_chars = 20
    )

    # Reduir text_buscar a primeres 6-8 paraules per identificació única
    text_net <- gsub("\\s+", " ", trimws(text))
    paraules <- strsplit(text_net, " ")[[1]]
    num_paraules <- min(8, length(paraules))
    text_identificador <- paste(paraules[1:num_paraules], collapse = " ")

    if (!is.null(resultat) && nchar(resultat) > 0) {
      # Actualitzar text_buscar amb només les primeres paraules
      updateTextAreaInput(
        session,
        "text_buscar",
        value = text_identificador
      )

      updateTextAreaInput(
        session,
        "comentari",
        value = paste0("💡 Recomanacions IA: ", resultat)
      )

      # Afegir automàticament l'anotació
      Sys.sleep(0.3)
      shinyjs::click("afegir")

      showNotification(
        HTML(paste0(
          "✅ Recomanacions generades i afegides<br>",
          "<small>Clica 'Generar PDF Anotat' quan estiguis preparat</small>"
        )),
        type = "message",
        duration = 5
      )
    }
  })

  # Resumir amb IA
  observeEvent(input$resumir_ia, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    resultat <- executar_accio_ia(
      accio = "resumir",
      text = text,
      model = input$ia_model,
      idioma = input$ia_idioma %||% "catala",
      api_key = input$gemini_api_key,
      ollama_model = input$ollama_model,
      min_chars = 50
    )

    if (!is.null(resultat) && nchar(resultat) > 0) {
      # Extreure identificador únic del text original (primeres 5-7 paraules)
      text_net <- gsub("\\s+", " ", trimws(text))
      paraules <- strsplit(text_net, " ")[[1]]
      num_paraules <- min(6, length(paraules))
      text_identificador <- paste(paraules[1:num_paraules], collapse = " ")

      if (num_paraules < 3) {
        showNotification(
          "⚠️ Text massa curt. Escriu més paraules per identificar millor.",
          type = "warning",
          duration = 5
        )
        return()
      }

      updateTextAreaInput(
        session,
        "text_buscar",
        value = text_identificador
      )

      updateTextAreaInput(
        session,
        "comentari",
        value = paste0("📝 Resum IA: ", resultat)
      )

      # Afegir automàticament l'anotació
      Sys.sleep(0.3)
      shinyjs::click("afegir")

      showNotification(
        HTML(paste0(
          "✅ Resum generat i afegit<br>",
          "<small>Clica 'Generar PDF Anotat' quan estiguis preparat</small>"
        )),
        type = "message",
        duration = 5
      )
    }
  })

  # === OBSERVEVENT ANTIC ELIMINAT, SUBSTITUÏT PER LA NOVA FUNCIÓ ===
  # (El vell observeEvent de resumir_ia s'ha substituït pel de dalt)

  # Dummy placeholder per mantenir estructura

  # === Fi secció IA ===

  # Verificar Python
  if (!python_configurat) {
    showNotification(
      HTML(paste0(
        "<strong>❌ Error Python</strong><br>",
        missatge_error, "<br><br>",
        "Solució: <code>pip3 install PyMuPDF</code>"
      )),
      type = "error",
      duration = NULL
    )
  } else {
    # Importar mòdul Python amb py_run_string (més compatible amb Shiny Server)
    tryCatch({
      py_run_string(sprintf("
import sys
sys.path.insert(0, '%s')
from anotar_pdf import processar_anotacions_json, diagnosticar_pdf
      ", normalizePath(session_pdf_dir)))

      cat("✓ Funcions Python carregades correctament des de:", session_pdf_dir, "\n")

    }, error = function(e) {
      cat("❌ Error carregant Python:", e$message, "\n")
      showNotification(
        HTML(paste0(
          "<strong>❌ Error carregant mòdul Python</strong><br>",
          e$message
        )),
        type = "error",
        duration = NULL
      )
    })
  }

  # Pujar PDF
  observeEvent(input$pujar_pdf, {
    req(input$pujar_pdf)

    tryCatch({
      # Guardar PDF temporalment
      pdf_temp <- file.path(tempdir(), input$pujar_pdf$name)
      file.copy(input$pujar_pdf$datapath, pdf_temp, overwrite = TRUE)

      # Diagnosticar PDF
      diag <- tryCatch({
        call_py_func("diagnosticar_pdf", pdf_temp)
      }, error = function(e) {
        cat("⚠️ Error diagnosticant PDF:", e$message, "\n")
        # Si falla, fer diagnòstic bàsic
        list(
          valid = file.exists(pdf_temp) && tools::file_ext(pdf_temp) == "pdf",
          error = if (!file.exists(pdf_temp)) "Fitxer no trobat" else e$message,
          pages = NA,
          encrypted = FALSE,
          has_text = TRUE  # Assumir que sí per defecte
        )
      })

      if (!diag$valid) {
        showNotification(
          HTML(paste0(
            "<strong>❌ PDF no vàlid</strong><br>",
            diag$error
          )),
          type = "error",
          duration = 10
        )
        return()
      }

      if (diag$encrypted) {
        showNotification(
          HTML("<strong>🔒 PDF protegit</strong><br>Aquest PDF està protegit amb contrasenya. Si us plau, desencripta'l abans de pujar-lo."),
          type = "error",
          duration = 10
        )
        return()
      }

      # Avisar si no té text i oferir OCR
      if (!diag$has_text) {
        # Verificar si ocrmypdf està disponible
        ocr_disponible <- system2("which", "ocrmypdf", stdout = FALSE, stderr = FALSE) == 0

        if (ocr_disponible) {
          showModal(modalDialog(
            title = "⚠️ PDF escanejat detectat",
            HTML(paste0(
              "<strong>Aquest PDF no té text extractible</strong><br><br>",
              "És una imatge escanejada. Les anotacions per text <strong>no funcionaran</strong>.<br><br>",
              "<strong>Solució automàtica:</strong> Puc aplicar OCR (Reconeixement Òptic de Caràcters) ",
              "per convertir-lo en text cerca-ble.<br><br>",
              "<strong>Temps estimat:</strong> 30 segons - 2 minuts segons la mida del document."
            )),
            footer = tagList(
              actionButton("aplicar_ocr", "✨ Aplicar OCR automàtic", class = "btn-success"),
              modalButton("❌ Cancel·lar")
            ),
            size = "m",
            easyClose = FALSE
          ))
        } else {
          showNotification(
            HTML(paste0(
              "<strong>⚠️ Advertència: PDF sense text extractible</strong><br>",
              "Aquest PDF sembla ser una imatge escanejada.<br>",
              "Les anotacions per text <strong>no funcionaran</strong>.<br><br>",
              "<strong>Solució:</strong> Aplica OCR amb:<br>",
              "<code>sudo apt install ocrmypdf tesseract-ocr-cat</code><br>",
              "<code>ocrmypdf input.pdf output.pdf</code>"
            )),
            type = "warning",
            duration = 20
          )
        }
      }

      pdf_actual(pdf_temp)
      pdf_actual_nom(input$pujar_pdf$name)

      # Reiniciar anotacions
      anotacions(list())
      pdf_anotat_path(NULL)

      msg <- paste0("✅ PDF carregat: ", input$pujar_pdf$name, " (", diag$pages, " pàgines)")
      if (diag$has_text) {
        msg <- paste0(msg, " ✓ Text extractible")
      }

      showNotification(msg, type = "message", duration = 5)

    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 10)
    })
  })

  # Afegir anotació
  observeEvent(input$afegir, {

    if (is.null(input$text_buscar) || input$text_buscar == "") {
      showNotification("⚠️ Escriu text a buscar", type = "warning")
      return()
    }

    if (is.null(input$comentari) || input$comentari == "") {
      showNotification("⚠️ Escriu un comentari", type = "warning")
      return()
    }

    usuari <- if (!is.null(input$nom_usuari) && input$nom_usuari != "") {
      input$nom_usuari
    } else {
      "Anònim"
    }

    nova <- list(
      text = trimws(input$text_buscar),
      comentari = trimws(input$comentari),
      usuari = usuari
    )

    anotacions(c(anotacions(), list(nova)))

    showNotification("✅ Anotació afegida", type = "message", duration = 2)

    updateTextAreaInput(session, "text_buscar", value = "")
    updateTextAreaInput(session, "comentari", value = "")
  })

  # Llista d'anotacions
  output$llista_anotacions <- renderUI({
    notes <- anotacions()

    if (length(notes) == 0) {
      return(tags$div(
        style = "text-align: center; padding: 40px; color: #999;",
        tags$h5("📝 Encara no hi ha anotacions"),
        tags$p("Afegeix la primera anotació amb el formulari de l'esquerra")
      ))
    }

    lapply(seq_along(notes), function(i) {
      nota <- notes[[i]]
      tags$div(
        style = "background: white; border-left: 4px solid #28a745; padding: 15px; margin-bottom: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.08);",

        tags$div(
          style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
          tags$strong(paste0("#", i, " - 👤 ", nota$usuari), style = "color: #28a745;"),
          actionButton(paste0("remove_", i), "🗑️", class = "btn-sm btn-danger")
        ),

        tags$div(
          style = "background: #e8f5e9; padding: 8px; border-radius: 4px; margin-bottom: 8px;",
          tags$strong("🔍 Buscar: "),
          HTML(enriquir_text(nota$text))
        ),

        tags$div(
          style = "color: #333;",
          tags$strong("💬 Comentari: "),
          HTML(enriquir_text(nota$comentari))
        )
      )
    })
  })

  # Esborrar anotació
  observe({
    notes <- anotacions()
    lapply(seq_along(notes), function(i) {
      observeEvent(input[[paste0("remove_", i)]], {
        anotacions(notes[-i])
        showNotification("🗑️ Anotació esborrada", type = "warning", duration = 1)
      })
    })
  })

  # Box d'anotacions al PDF generat
  output$box_anotacions_pdf <- renderUI({
    notes_pdf <- anotacions_pdf()

    if (length(notes_pdf) == 0) {
      return(NULL)  # No mostrar el box si no hi ha anotacions
    }

    box(
      width = 12,
      title = HTML(paste0("✅ Anotacions al PDF generat (", length(notes_pdf), ")")),
      status = "primary",
      solidHeader = TRUE,
      collapsible = TRUE,
      collapsed = FALSE,

      tags$div(
        style = "max-height: 600px; overflow-y: auto;",

        lapply(seq_along(notes_pdf), function(i) {
          nota <- notes_pdf[[i]]
          tags$div(
            style = "background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); border-left: 5px solid #2196F3; padding: 18px; margin-bottom: 15px; border-radius: 10px; box-shadow: 0 3px 8px rgba(0,0,0,0.1);",

            tags$div(
              style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 2px solid rgba(33, 150, 243, 0.3);",
              tags$strong(paste0("#", i, " - 👤 ", nota$usuari), style = "color: #1976D2; font-size: 15px;"),
              tags$span(
                style = "background: #2196F3; color: white; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: 600;",
                "AL PDF"
              )
            ),

            tags$div(
              style = "background: white; padding: 12px; border-radius: 6px; margin-bottom: 12px; border: 1px solid #e3f2fd;",
              tags$div(
                style = "color: #555; font-weight: 600; margin-bottom: 6px; font-size: 12px;",
                "🔍 Text identificador:"
              ),
              tags$div(
                style = "color: #333; font-size: 13px; font-style: italic;",
                HTML(enriquir_text(nota$text))
              )
            ),

            tags$div(
              style = "background: white; padding: 14px; border-radius: 6px; border: 1px solid #e3f2fd;",
              tags$div(
                style = "color: #555; font-weight: 600; margin-bottom: 8px; font-size: 12px;",
                "💬 Comentari IA:"
              ),
              tags$div(
                style = "color: #333; line-height: 1.6; font-size: 13px; max-height: 300px; overflow-y: auto;",
                HTML(gsub("\n", "<br>", enriquir_text(nota$comentari)))
              )
            )
          )
        })
      )
    )
  })

  # Netejar llista d'anotacions
  observeEvent(input$netejar_llista, {
    if (length(anotacions()) > 0) {
      anotacions(list())
      showNotification("🧹 Llista d'anotacions netejada", type = "warning", duration = 2)
    } else {
      showNotification("ℹ️ La llista ja està buida", type = "message", duration = 2)
    }
  })

  # Generar PDF
  observeEvent(input$generar_pdf, {

    if (length(anotacions()) == 0) {
      showNotification("⚠️ Afegeix almenys una anotació", type = "warning")
      return()
    }

    # Determinar PDF a processar
    pdf_input <- if (!is.null(pdf_actual())) {
      pdf_actual()
    } else {
      "nihms-1548654.pdf"
    }

    if (!file.exists(pdf_input)) {
      showNotification("❌ PDF no trobat. Puja un PDF primer.", type = "error")
      return()
    }

    withProgress(message = 'Generant PDF...', value = 0, {

      tryCatch({
        # JSON temporal
        json_temp <- tempfile(fileext = ".json")
        json_content <- toJSON(anotacions(), auto_unbox = TRUE, pretty = TRUE)
        writeLines(json_content, json_temp)

        cat("\n📋 ANOTACIONS A PROCESSAR:\n")
        cat("   Nombre d'anotacions:", length(anotacions()), "\n")
        for (i in seq_along(anotacions())) {
          ann <- anotacions()[[i]]
          cat(sprintf("   #%d - Text: '%s...'\n", i, substr(ann$text, 1, 50)))
        }
        cat("\n")

        incProgress(0.5)

        # Output - generar sempre amb timestamp per evitar conflictes
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        output_path <- file.path(session_pdf_dir, paste0("anotat_", timestamp, ".pdf"))

        cat("📄 PDF d'entrada:", pdf_input, "\n")
        cat("📄 PDF de sortida:", output_path, "\n\n")

        # Processar amb captura de sortida
        cat("🐍 Cridant processar_anotacions_json...\n")

        # Crear script Python temporal
        script_py <- tempfile(fileext = ".py")

        # Directori on està anotar_pdf.py (copiat al session_pdf_dir)
        script_dir <- session_pdf_dir

        writeLines(sprintf("
import sys
import os

# Afegir directori del script al path
sys.path.insert(0, '%s')
os.chdir('%s')

from anotar_pdf import processar_anotacions_json

pdf_input = '%s'
json_file = '%s'
pdf_output = '%s'

print('=' * 60)
print('INICIANT PROCESSAMENT')
print('=' * 60)
sys.stdout.flush()

result = processar_anotacions_json(pdf_input, json_file, pdf_output)

print('=' * 60)
print('PROCESSAMENT COMPLETAT')
print('=' * 60)
sys.stdout.flush()
", script_dir, script_dir, pdf_input, json_temp, output_path), script_py)

        # Executar script Python
        output_msg <- system2(
          "python3",
          args = c(script_py),
          stdout = TRUE,
          stderr = TRUE
        )

        # Netejar script temporal
        unlink(script_py)

        cat("\n🐍 SORTIDA PYTHON:\n")
        cat(paste(output_msg, collapse = "\n"))
        cat("\n\n")

        incProgress(1)

        # Verificar que el PDF s'ha creat
        if (!file.exists(output_path)) {
          stop("El PDF no s'ha generat correctament")
        }

        pdf_anotat_path(output_path)

        # Verificar si s'han afegit anotacions
        if (is.null(output_msg) || length(output_msg) == 0) {
          showNotification("⚠️ No s'han rebut logs de Python", type = "warning", duration = 5)
        } else if (any(grepl("No s'ha afegit cap anotació", output_msg))) {
          # Mostrar detalls del debug
          debug_lines <- grep("DEBUG:|Primeres paraules del PDF:", output_msg, value = TRUE)

          showNotification(
            HTML(paste0(
              "<strong>⚠️ PDF generat però SENSE anotacions</strong><br><br>",
              "<strong>Cap text buscat s'ha trobat al PDF.</strong><br><br>",
              "<strong>Consells:</strong><br>",
              "1️⃣ Verifica que el text buscat és DEL MATEIX PDF<br>",
              "2️⃣ Redueix el text buscar a 3-4 paraules úniques<br>",
              "3️⃣ Copia text directament del visor PDF<br>",
              "4️⃣ Revisa majúscules/minúscules i ortografia<br><br>",
              if (length(debug_lines) > 0) paste0("<small>", paste(debug_lines, collapse = "<br>"), "</small>") else ""
            )),
            type = "error",
            duration = 15
          )
        } else if (any(grepl("No s'ha trobat el text", output_msg))) {
          num_no_trobades <- sum(grepl("No s'ha trobat el text", output_msg))
          num_afegides <- sum(grepl("anotacions afegides", output_msg))

          showNotification(
            HTML(paste0(
              "<strong>⚠️ Només algunes anotacions s'han afegit</strong><br>",
              "✅ ", num_afegides, " afegides correctament<br>",
              "❌ ", num_no_trobades, " no trobades al PDF<br><br>",
              "<small>Consell: Revisa el text buscat de les que han fallat</small>"
            )),
            type = "warning",
            duration = 10
          )
        } else {
          num_afegides <- sum(grepl("anotacions afegides", output_msg))

          # Guardar les anotacions processades per mostrar-les al lateral
          anotacions_pdf(c(anotacions_pdf(), anotacions()))

          showNotification(
            HTML(paste0(
              "✅ PDF anotat generat correctament!<br>",
              "<strong>", num_afegides, " anotacions afegides</strong><br>",
              "<small>Pots descarregar-lo o afegir més anotacions</small>"
            )),
            type = "message",
            duration = 5
          )
        }

      }, error = function(e) {
        error_msg <- e$message

        # Millorar missatge d'error
        if (grepl("protegit\\|encrypted", error_msg, ignore.case = TRUE)) {
          error_msg <- "El PDF està protegit amb contrasenya"
        } else if (grepl("text extractible", error_msg, ignore.case = TRUE)) {
          error_msg <- "El PDF no té text extractible (imatge escanejada)"
        }

        showNotification(
          HTML(paste0("<strong>❌ Error processant PDF</strong><br>", error_msg)),
          type = "error",
          duration = 10
        )
      })
    })
  })

  # Botons descarregar
  output$botons_descarregar <- renderUI({
    if (!is.null(pdf_anotat_path()) && file.exists(pdf_anotat_path())) {
      tagList(
        downloadButton("descarregar_pdf", "📄 PDF",
                      class = "btn-success",
                      style = "width: 100%; margin-bottom: 8px;"),
        downloadButton("descarregar_json", "📋 JSON",
                      class = "btn-info",
                      style = "width: 100%; margin-bottom: 8px;"),
        downloadButton("descarregar_zip", "📦 ZIP",
                      class = "btn-primary",
                      style = "width: 100%;")
      )
    }
  })

  # Descarregar PDF
  output$descarregar_pdf <- downloadHandler(
    filename = function() {
      paste0("anotat_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf")
    },
    content = function(file) {
      file.copy(pdf_anotat_path(), file)
    }
  )

  # Descarregar JSON
  output$descarregar_json <- downloadHandler(
    filename = function() {
      paste0("anotacions_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")
    },
    content = function(file) {
      writeLines(toJSON(anotacions(), auto_unbox = TRUE, pretty = TRUE), file)
    }
  )

  # Descarregar ZIP
  output$descarregar_zip <- downloadHandler(
    filename = function() {
      paste0("complet_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
    },
    content = function(file) {
      temp_dir <- tempfile()
      dir.create(temp_dir)

      # PDF
      file.copy(pdf_anotat_path(), file.path(temp_dir, "anotat.pdf"))

      # JSON
      writeLines(toJSON(anotacions(), auto_unbox = TRUE, pretty = TRUE),
                file.path(temp_dir, "anotacions.json"))

      # README
      readme <- paste0(
        "ANOTACIONS PDF - ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n",
        "Total anotacions: ", length(anotacions()), "\n\n",
        paste(sapply(seq_along(anotacions()), function(i) {
          n <- anotacions()[[i]]
          paste0(i, ". ", n$text, "\n   Usuari: ", n$usuari, "\n   Comentari: ", n$comentari, "\n")
        }), collapse = "\n")
      )
      writeLines(readme, file.path(temp_dir, "README.txt"))

      # ZIP
      files_to_zip <- list.files(temp_dir, full.names = TRUE)
      zip(file, files_to_zip, flags = "-j")
      unlink(temp_dir, recursive = TRUE)
    }
  )

  # Configurar resource path una sola vegada
  addResourcePath("pdf_temp", session_pdf_dir)

  # Configurar www només si existeix
  if (dir.exists("www")) {
    addResourcePath("www", normalizePath("www"))
  }

  # Visor PDF
  output$visor_pdf <- renderUI({
    # Determinar quin PDF mostrar: anotat o original
    pdf_a_mostrar <- if (!is.null(pdf_anotat_path()) && file.exists(pdf_anotat_path())) {
      # Si hi ha PDF anotat, mostrar-lo
      nom_anotat <- paste0("anotat_", pdf_actual_nom())
      pdf_link <- file.path(session_pdf_dir, nom_anotat)
      file.copy(pdf_anotat_path(), pdf_link, overwrite = TRUE)
      Sys.chmod(pdf_link, mode = "0644")  # Llegible per tots

      list(path = paste0("pdf_temp/", nom_anotat), tipus = "anotat")
    } else if (!is.null(pdf_actual())) {
      # Mostrar PDF original
      pdf_link <- file.path(session_pdf_dir, pdf_actual_nom())
      file.copy(pdf_actual(), pdf_link, overwrite = TRUE)
      Sys.chmod(pdf_link, mode = "0644")

      list(path = paste0("pdf_temp/", pdf_actual_nom()), tipus = "original")
    } else if (file.exists("nihms-1548654.pdf")) {
      list(path = "nihms-1548654.pdf", tipus = "exemple")
    } else {
      NULL
    }

    if (is.null(pdf_a_mostrar)) {
      return(tags$div(
        style = "text-align: center; padding: 40px; color: #999;",
        tags$h5("📄 Cap PDF carregat"),
        tags$p("Puja un PDF amb el selector de l'esquerra")
      ))
    }

    tagList(
      # Indicador de quin PDF s'està mostrant
      if (pdf_a_mostrar$tipus == "anotat") {
        tags$div(
          style = "background: #d4edda; border: 1px solid #c3e6cb; padding: 10px; margin-bottom: 10px; border-radius: 4px; text-align: center;",
          tags$span(style = "color: #155724; font-weight: 600;", "✅ Mostrant PDF amb anotacions PyMuPDF")
        )
      } else if (pdf_a_mostrar$tipus == "original") {
        tags$div(
          style = "background: #cce5ff; border: 1px solid #b8daff; padding: 10px; margin-bottom: 10px; border-radius: 4px; text-align: center;",
          tags$span(style = "color: #004085; font-weight: 600;", "📄 Mostrant PDF original (sense anotacions PyMuPDF)")
        )
      },

      tags$iframe(
        src = paste0(pdf_a_mostrar$path, "#view=FitH&pagemode=none&toolbar=1"),
        type = "application/pdf",
        width = "100%",
        height = "calc(100vh - 180px)",
        style = "border: none; display: block; min-height: 800px;"
      )
    )
  })

  # Cerca a PubMed
  observeEvent(input$cerca_pubmed, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    if (text == "") {
      showNotification("⚠️ Escriu text per cercar", type = "warning", duration = 3)
      return()
    }

    # Construir URL de PubMed
    query <- URLencode(text, reserved = TRUE)
    url <- paste0("https://pubmed.ncbi.nlm.nih.gov/?term=", query)

    # Obrir en nova pestanya
    runjs(sprintf("window.open('%s', '_blank');", url))

    showNotification(
      paste0("🔍 Cercant '", substr(text, 1, 50), "' a PubMed..."),
      type = "message",
      duration = 3
    )
  })

  # Cerca a NCBI Gene
  observeEvent(input$cerca_ncbi_gene, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    if (text == "") {
      showNotification("⚠️ Escriu text per cercar", type = "warning", duration = 3)
      return()
    }

    query <- URLencode(text, reserved = TRUE)
    url <- paste0("https://www.ncbi.nlm.nih.gov/gene/?term=", query)

    runjs(sprintf("window.open('%s', '_blank');", url))

    showNotification(
      paste0("🧬 Cercant gen '", substr(text, 1, 50), "' a NCBI..."),
      type = "message",
      duration = 3
    )
  })

  # Cerca a UniProt
  observeEvent(input$cerca_uniprot, {
    req(input$text_buscar)
    text <- trimws(input$text_buscar)

    if (text == "") {
      showNotification("⚠️ Escriu text per cercar", type = "warning", duration = 3)
      return()
    }

    query <- URLencode(text, reserved = TRUE)
    url <- paste0("https://www.uniprot.org/uniprotkb?query=", query)

    runjs(sprintf("window.open('%s', '_blank');", url))

    showNotification(
      paste0("🔬 Cercant proteïna '", substr(text, 1, 50), "' a UniProt..."),
      type = "message",
      duration = 3
    )
  })

  # Aplicar OCR automàtic
  observeEvent(input$aplicar_ocr, {
    req(pdf_actual())

    removeModal()

    withProgress(message = '🔍 Aplicant OCR...', value = 0, {
      tryCatch({
        incProgress(0.1, detail = "Preparant document...")

        pdf_input <- pdf_actual()
        pdf_output <- file.path(tempdir(), paste0("ocr_", pdf_actual_nom()))

        incProgress(0.2, detail = "Executant OCR (pot trigar uns minuts)...")

        # Executar ocrmypdf
        result <- system2("ocrmypdf",
          args = c(
            "-l", "cat+spa+eng",  # Idiomes: català, espanyol, anglès
            "--force-ocr",         # Forçar OCR encara que sembli tenir text
            "--skip-text",         # Saltar text existent
            shQuote(pdf_input),
            shQuote(pdf_output)
          ),
          stdout = TRUE,
          stderr = TRUE
        )

        incProgress(0.6, detail = "Finalitzant...")

        if (file.exists(pdf_output)) {
          # Reemplaçar PDF actual amb el que té OCR
          pdf_actual(pdf_output)
          pdf_actual_nom(paste0("ocr_", pdf_actual_nom()))

          incProgress(0.1, detail = "Verificant text...")

          # Re-diagnosticar
          diag_nou <- call_py_func("diagnosticar_pdf", pdf_output)

          if (diag_nou$has_text) {
            showNotification(
              HTML(paste0(
                "<strong>✅ OCR completat amb èxit!</strong><br>",
                "Ara pots buscar i anotar text al document.<br>",
                "Pàgines processades: ", diag_nou$pages
              )),
              type = "message",
              duration = 10
            )
          } else {
            showNotification(
              HTML(paste0(
                "<strong>⚠️ OCR completat però sense text detectat</strong><br>",
                "El document pot tenir problemes de qualitat.<br>",
                "Prova amb una imatge de millor resolució."
              )),
              type = "warning",
              duration = 10
            )
          }
        } else {
          stop("OCR no ha generat fitxer de sortida")
        }

      }, error = function(e) {
        showNotification(
          HTML(paste0(
            "<strong>❌ Error aplicant OCR</strong><br>",
            conditionMessage(e), "<br><br>",
            "Verifica que ocrmypdf està instal·lat:<br>",
            "<code>sudo apt install ocrmypdf tesseract-ocr-cat</code>"
          )),
          type = "error",
          duration = 15
        )
      })
    })
  })

  # Reiniciar amb PDF anotat
  observeEvent(input$reiniciar_amb_anotat, {
    req(pdf_anotat_path())

    if (!file.exists(pdf_anotat_path())) {
      showNotification("❌ PDF anotat no disponible", type = "error")
      return()
    }

    # Copiar PDF anotat com a nou PDF d'entrada
    nou_nom <- paste0("acumulat_", pdf_actual_nom())
    nou_path <- file.path(tempdir(), nou_nom)
    file.copy(pdf_anotat_path(), nou_path, overwrite = TRUE)

    # Actualitzar variables
    pdf_actual(nou_path)
    pdf_actual_nom(nou_nom)

    # Reiniciar anotacions (per afegir més)
    anotacions(list())
    pdf_anotat_path(NULL)

    showNotification(
      HTML(paste0(
        "<strong>✅ PDF anotat carregat com a base</strong><br>",
        "Ara pots afegir més anotacions amb el formulari"
      )),
      type = "message",
      duration = 5
    )
  })

  # Status
  output$status <- renderText({
    if (!is.null(pdf_anotat_path()) && file.exists(pdf_anotat_path())) {
      paste("✅", length(anotacions()), "anotacions processades")
    } else if (length(anotacions()) > 0) {
      paste("📋", length(anotacions()), "anotacions preparades")
    } else {
      "Afegeix anotacions"
    }
  })
}

shinyApp(ui = ui, server = server)
