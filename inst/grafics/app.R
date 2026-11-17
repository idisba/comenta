library(Comenta)
# ============================================================
# AnotaR - Exportació de gràfics a PowerPoint
# Converteix PNG i ggplot a presentacions editables
# ============================================================

library(shiny)
library(bs4Dash)
library(shinyjs)
library(ggplot2)
library(magick)
library(imager)
library(officer)
library(rvg)
library(shinycssloaders)
library(parallel)

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
          "gràfics · anotació visual"
        )
      )
    )
  ),
  sidebar = dashboardSidebar(
    tags$div(style = "padding: 20px 15px;",
      # Info tipus de fitxers acceptats
      tags$div(
        style = "background: rgba(156, 39, 176, 0.15); padding: 12px; border-radius: 6px; border-left: 4px solid #9c27b0; margin-bottom: 15px;",
        tags$div(style = "color: white; font-size: 12px; font-weight: 600; margin-bottom: 6px;", "📊 Formats acceptats"),
        tags$div(style = "color: rgba(255,255,255,0.9); font-size: 10px; line-height: 1.4;",
          "PNG: converteix a gràfic vectorial editable | RDS: objectes ggplot guardats | 💡 Diagrames: usar 16+ colors"
        )
      ),

      # Selector de tipus de càrrega
      radioButtons("tipus_carrega",
                   "Tipus d'entrada:",
                   choices = c("Imatge PNG" = "png", "Objecte ggplot (RDS)" = "ggplot"),
                   selected = "png"),

      hr(),

      # Càrrega PNG
      conditionalPanel(
        condition = "input.tipus_carrega == 'png'",
        tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 5px; display: block;", "🖼️ Puja imatge PNG"),
        fileInput("pujar_png", NULL, accept = c("image/png", ".png"),
                  buttonLabel = "Seleccionar PNG",
                  placeholder = "Cap fitxer seleccionat"),

          sliderInput("num_colors", "Nombre de colors:",
                   min = 2, max = 32, value = 16, step = 1),

        selectInput("upscale_factor", "Augmentar resolució:",
                   choices = c("Original (1x)" = 1, "Doble (2x)" = 2, "Triple (3x)" = 3, "Quàdruple (4x)" = 4),
                   selected = 1),

        tags$div(
          style = "color: rgba(255,255,255,0.8); font-size: 10px; margin-top: -10px; padding: 5px 0;",
          "💡 Resolucions 3x i 4x triguen més temps a processar"
        )
      ),

      # Càrrega ggplot
      conditionalPanel(
        condition = "input.tipus_carrega == 'ggplot'",
        tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 5px; display: block;", "📈 Puja ggplot (RDS)"),
        fileInput("pujar_ggplot", NULL, accept = c(".rds", ".RDS"),
                  buttonLabel = "Seleccionar RDS",
                  placeholder = "Cap fitxer seleccionat")
      ),

      tags$div(style = "margin: 20px 0; border-top: 2px solid rgba(255,255,255,0.3);"),

      # Opcions d'exportació
      tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 10px; display: block;", "⚙️ Opcions PowerPoint"),

      selectInput("mida_diapo", "Mida diapositiva:",
                 choices = c("Completa" = "full", "2/3" = "medium", "1/2" = "small"),
                 selected = "full"),

      hr(),

      # Descarregar
      tags$label(style = "color: white; font-weight: 500; font-size: 13px; margin-bottom: 10px; display: block;", "💾 Descarregar"),
      downloadButton("descarregar_pptx", "Descarregar PowerPoint",
                    icon = icon("file-powerpoint"),
                    class = "btn-success",
                    style = "width: 100%; margin: 0;"),

      br(), br(),

      # Indicador de temps estimat
      conditionalPanel(
        condition = "input.tipus_carrega == 'png' && (input.upscale_factor == '3' || input.upscale_factor == '4')",
        tags$div(
          style = "background: rgba(255, 152, 0, 0.15); padding: 8px; border-radius: 6px; border-left: 4px solid #ff9800; margin-bottom: 10px;",
          tags$div(style = "color: white; font-size: 10px; font-weight: 600; margin-bottom: 3px;", "⚡ Mode alta resolució"),
          tags$div(style = "color: rgba(255,255,255,0.9); font-size: 9px; line-height: 1.3;",
            "El processament pot trigar 10-30 segons segons la mida de la imatge"
          )
        )
      ),

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
          background: linear-gradient(180deg, #9c27b0 0%, #7b1fa2 100%) !important;
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
          color: #4CAF50 !important;
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

        #status {
          color: #ffffff;
          background: rgba(255, 255, 255, 0.15);
          padding: 10px;
          border-radius: 8px;
          font-size: 11px;
          text-align: center;
        }

        .main-header {
          background: linear-gradient(135deg, #9c27b0 0%, #7b1fa2 100%) !important;
          box-shadow: 0 2px 10px rgba(156, 39, 176, 0.2);
        }

        .content-wrapper {
          background-color: #f5f6fa;
        }

        .plot-container {
          background: white;
          padding: 15px;
          border-radius: 8px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
          min-height: 900px;
        }

        #preview_plot {
          width: 100%;
        }

        .shiny-plot-output {
          width: 100%;
        }

        .shiny-plot-output img {
          width: 100%;
          height: auto;
          display: block;
        }

        /* Estil per l'spinner de càrrega */
        .load-container {
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          z-index: 1000;
        }

        /* Animació de pulsació per l'status quan està carregant */
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }

        .loading-status {
          animation: pulse 1.5s ease-in-out infinite;
        }
      "))
    ),
    useShinyjs(),
    box(
      width = 12,
      status = NULL,
      solidHeader = FALSE,
      collapsible = FALSE,
      title = "Previsualització",
      div(
        class = "plot-container",
        withSpinner(
          plotOutput("preview_plot", width = "100%", height = "calc(100vh - 200px)"),
          type = 6,
          color = "#9c27b0",
          size = 1.5
        )
      )
    ),
    tags$div(
      style = "position: fixed; bottom: 0; left: 0; right: 0; background: rgba(255,255,255,0.95); padding: 10px; text-align: center; font-size: 11px; color: #666; border-top: 1px solid #dee2e6; z-index: 1000; backdrop-filter: blur(5px);",
      HTML('AnotaR v1.0.0 | <a href="https://github.com/josepmuncunill/AnotaR" target="_blank" style="color: #007bff;">GitHub</a> | MIT License | IDISBA Bioinformàtica')
    )
  )
)

server <- function(input, output, session) {

  # Configurar resource path per www només si existeix
  if (dir.exists("www")) {
    addResourcePath("www", normalizePath("www"))
  }

  # Variables reactives
  grafic_actual <- reactiveVal(NULL)
  nom_fitxer <- reactiveVal(NULL)
  tipus_grafic <- reactiveVal(NULL) # "png" o "ggplot"
  imatge_aspect_ratio <- reactiveVal(1) # Relació d'aspecte de la imatge

  status_text <- reactiveVal("")

  # Processar imatge PNG
  observeEvent(input$pujar_png, {
    req(input$pujar_png)

    # Crear barra de progrés
    withProgress(message = '🖼️ Processant imatge', value = 0, {
      tryCatch({
        # Cronòmetre
        temps_inici <- Sys.time()

        # Mostrar missatge segons upscaling
        upscale_mult <- as.numeric(input$upscale_factor)
        if (upscale_mult > 2) {
          status_text(paste0("⏳ Processant amb upscaling ", upscale_mult, "x... Això pot trigar uns segons"))
        } else {
          status_text("⏳ Processant imatge...")
        }

        incProgress(0.1, detail = "Carregant imatge...")

        # Guardar ruta per reprocessament
        ultima_imatge_path(input$pujar_png$datapath)

      # 1. Llegir imatge
      incProgress(0.2, detail = "Llegint i convertint colors...")
      img_magick <- image_read(input$pujar_png$datapath) |>
        image_convert(colorspace = "sRGB") |>
        image_background("white", flatten = TRUE)

      # Quantificar colors ABANS d'upscaling (més estable)
      incProgress(0.1, detail = paste0("Quantificant a ", input$num_colors, " colors..."))
      img_magick <- image_quantize(img_magick, max = input$num_colors, dither = FALSE)

      # Augmentar resolució segons el factor seleccionat
      upscale_mult <- as.numeric(input$upscale_factor)
      if (upscale_mult > 1) {
        incProgress(0.15, detail = paste0("Augmentant resolució ", upscale_mult, "x..."))
        info_orig <- image_info(img_magick)
        nova_amplada <- info_orig$width * upscale_mult
        nova_altura <- info_orig$height * upscale_mult
        img_magick <- image_resize(img_magick, paste0(nova_amplada, "x", nova_altura), filter = "Lanczos")
        cat(sprintf("Upscaling %dx: %dx%d → %dx%d píxels\n",
                    upscale_mult, info_orig$width, info_orig$height, nova_amplada, nova_altura))
      }

      # Obtenir mida final
      info <- image_info(img_magick)
      cat(sprintf("Processant imatge: %dx%d píxels\n", info$width, info$height))

      # 2. Desar temporalment amb qualitat màxima
      incProgress(0.1, detail = "Preparant canals de color...")
      temp_file <- tempfile(fileext = ".png")
      image_write(img_magick, temp_file, format = "png", quality = 100)
      img <- load.image(temp_file)

      # Convertir a RGB si és necessari
      if (spectrum(img) == 1) {
        # Imatge en escala de grisos - convertir a RGB
        img <- imager::add.color(img)
      }

      # 3. Extreure canals RGB i crear matriu de colors hexadecimals
      incProgress(0.1, detail = "Extraient colors...")
      R_mat <- as.matrix(channel(img, 1))
      G_mat <- as.matrix(channel(img, 2))
      B_mat <- as.matrix(channel(img, 3))

      hex_mat <- matrix(rgb(R_mat, G_mat, B_mat), nrow = nrow(R_mat), ncol = ncol(R_mat))
      colors_unics <- unique(as.vector(hex_mat))

      # 4. Filtrar colors (excloure quasi-blanc)
      lum <- col2rgb(colors_unics)
      colors_dibuix <- colors_unics[colMeans(lum) < 250]

      if (length(colors_dibuix) == 0) {
        stop("No s'han trobat colors per dibuixar. La imatge és massa clara. Prova amb una imatge amb més contrast.")
      }

      # 5. Crear polígons per cada color (paral·lelitzat)
      incProgress(0.15, detail = paste0("Generant ", length(colors_dibuix), " polígons vectorials..."))
      num_cores <- min(parallel::detectCores() - 1, length(colors_dibuix))
      llista_poligons <- parallel::mclapply(colors_dibuix, function(col_hex) {
        mascara <- (hex_mat == col_hex) * 1
        contorns <- contourLines(x = 1:nrow(mascara), y = 1:ncol(mascara), z = mascara, levels = 0.5)

        # Si no hi ha contorns, retornar NULL
        if (length(contorns) == 0) return(NULL)

        do.call(rbind, lapply(seq_along(contorns), function(i) {
          data.frame(x = contorns[[i]]$x, y = -contorns[[i]]$y, id = paste0(col_hex, "_", i), color = col_hex,
                     stringsAsFactors = FALSE)
        }))
      }, mc.cores = num_cores)

      # Filtrar NULLs i combinar
      llista_poligons <- Filter(Negate(is.null), llista_poligons)

      if (length(llista_poligons) == 0) {
        stop("No s'han pogut extreure polígons de la imatge. Prova amb un nombre diferent de colors.")
      }

      df_final <- do.call(rbind, llista_poligons)

      # 6. Crear ggplot optimitzat
      incProgress(0.15, detail = "Creant gràfic vectorial...")
      p <- ggplot(df_final, aes(x = x, y = y, group = id, fill = color)) +
        geom_polygon(color = NA, linewidth = 0) +
        scale_fill_identity() +
        coord_fixed() +
        theme_void() +
        theme(
          plot.margin = margin(0, 0, 0, 0)
        )

      grafic_actual(p)
      tipus_grafic("png")
      nom_fitxer(input$pujar_png$name)

      # Calcular temps transcorregut
      temps_final <- Sys.time()
      temps_total <- round(difftime(temps_final, temps_inici, units = "secs"), 1)

      incProgress(0.04, detail = "Finalitzant...")

      msg <- paste0("✅ ", input$pujar_png$name, " (", info$width, "x", info$height, " px)")
      if (upscale_mult > 1) {
        msg <- paste0(msg, " · Upscaling ", upscale_mult, "x")
      }
      msg <- paste0(msg, " · ", temps_total, "s")
      status_text(msg)

      unlink(temp_file)

      }, error = function(e) {
        status_text(paste0("❌ Error: ", conditionMessage(e)))
      })
    }) # Tanca withProgress
  })

  # Desar la ruta de l'últim fitxer pujat per poder reprocessar
  ultima_imatge_path <- reactiveVal(NULL)

  # Canviar nombre de colors o upscale (reprocessar)
  observeEvent(list(input$num_colors, input$upscale_factor), {
    req(ultima_imatge_path())
    if (!is.null(grafic_actual()) && tipus_grafic() == "png") {
      # Reprocessar amb el nou nombre de colors
      withProgress(message = '🔄 Reprocessant', value = 0, {
        tryCatch({
          temps_inici <- Sys.time()

          upscale_mult <- as.numeric(input$upscale_factor)
          if (upscale_mult > 2) {
            status_text(paste0("⏳ Reprocessant amb ", input$num_colors, " colors i upscaling ", upscale_mult, "x... Espera uns segons"))
          } else {
            status_text(paste0("⏳ Reprocessant amb ", input$num_colors, " colors..."))
          }

          incProgress(0.1, detail = "Carregant imatge...")

          # Usar la ruta guardada
        incProgress(0.2, detail = "Convertint colors...")
        img_magick <- image_read(ultima_imatge_path()) |>
          image_convert(colorspace = "sRGB") |>
          image_background("white", flatten = TRUE)

        # Quantificar colors ABANS d'upscaling
        incProgress(0.1, detail = paste0("Quantificant a ", input$num_colors, " colors..."))
        img_magick <- image_quantize(img_magick, max = input$num_colors, dither = FALSE)

        # Augmentar resolució segons el factor seleccionat
        upscale_mult <- as.numeric(input$upscale_factor)
        if (upscale_mult > 1) {
          incProgress(0.15, detail = paste0("Upscaling ", upscale_mult, "x..."))
          info_orig <- image_info(img_magick)
          nova_amplada <- info_orig$width * upscale_mult
          nova_altura <- info_orig$height * upscale_mult
          img_magick <- image_resize(img_magick, paste0(nova_amplada, "x", nova_altura), filter = "Lanczos")
        }

        incProgress(0.1, detail = "Preparant canals...")
        temp_file <- tempfile(fileext = ".png")
        image_write(img_magick, temp_file, format = "png", quality = 100)
        img <- load.image(temp_file)

        # Convertir a RGB si és necessari
        if (spectrum(img) == 1) {
          img <- imager::add.color(img)
        }

        incProgress(0.1, detail = "Extraient colors...")
        R_mat <- as.matrix(channel(img, 1))
        G_mat <- as.matrix(channel(img, 2))
        B_mat <- as.matrix(channel(img, 3))

        hex_mat <- matrix(rgb(R_mat, G_mat, B_mat), nrow = nrow(R_mat), ncol = ncol(R_mat))
        colors_unics <- unique(as.vector(hex_mat))

        lum <- col2rgb(colors_unics)
        colors_dibuix <- colors_unics[colMeans(lum) < 250]

        if (length(colors_dibuix) == 0) {
          stop("No s'han trobat colors per dibuixar.")
        }

        incProgress(0.15, detail = paste0("Generant ", length(colors_dibuix), " polígons..."))
        num_cores <- min(parallel::detectCores() - 1, length(colors_dibuix))
        llista_poligons <- parallel::mclapply(colors_dibuix, function(col_hex) {
          mascara <- (hex_mat == col_hex) * 1
          contorns <- contourLines(x = 1:nrow(mascara), y = 1:ncol(mascara), z = mascara, levels = 0.5)
          if (length(contorns) == 0) return(NULL)
          do.call(rbind, lapply(seq_along(contorns), function(i) {
            data.frame(x = contorns[[i]]$x, y = -contorns[[i]]$y, id = paste0(col_hex, "_", i), color = col_hex,
                       stringsAsFactors = FALSE)
          }))
        }, mc.cores = num_cores)

        llista_poligons <- Filter(Negate(is.null), llista_poligons)

        if (length(llista_poligons) == 0) {
          stop("No s'han pogut extreure polígons.")
        }

        df_final <- do.call(rbind, llista_poligons)

        incProgress(0.15, detail = "Creant gràfic vectorial...")
        p <- ggplot(df_final, aes(x = x, y = y, group = id, fill = color)) +
          geom_polygon(color = NA, linewidth = 0) +
          scale_fill_identity() +
          coord_fixed() +
          theme_void() +
          theme(
            plot.margin = margin(0, 0, 0, 0)
          )

        grafic_actual(p)

        # Calcular temps transcorregut
        temps_final <- Sys.time()
        temps_total <- round(difftime(temps_final, temps_inici, units = "secs"), 1)

        incProgress(0.04, detail = "Finalitzant...")

        msg <- paste0("✅ Reprocessat: ", input$num_colors, " colors")
        if (upscale_mult > 1) {
          msg <- paste0(msg, ", resolució ", upscale_mult, "x")
        }
        msg <- paste0(msg, " · ", temps_total, "s")
        status_text(msg)

        unlink(temp_file)

        }, error = function(e) {
          status_text(paste0("❌ Error: ", conditionMessage(e)))
        })
      }) # Tanca withProgress
    }
  }, ignoreInit = TRUE)

  # Processar ggplot RDS
  observeEvent(input$pujar_ggplot, {
    req(input$pujar_ggplot)

    withProgress(message = '📈 Carregant ggplot', value = 0, {
      tryCatch({
        status_text("⏳ Carregant ggplot...")

        incProgress(0.3, detail = "Llegint arxiu RDS...")

        # Carregar objecte RDS
        p <- readRDS(input$pujar_ggplot$datapath)

        incProgress(0.4, detail = "Validant objecte...")

        # Verificar que és un ggplot
        if (!inherits(p, "gg") && !inherits(p, "ggplot")) {
          stop("L'arxiu RDS no conté un objecte ggplot vàlid")
        }

        incProgress(0.2, detail = "Preparant visualització...")

        grafic_actual(p)
        tipus_grafic("ggplot")
        nom_fitxer(input$pujar_ggplot$name)

        incProgress(0.1, detail = "Finalitzant...")
        status_text(paste0("✅ ggplot carregat: ", input$pujar_ggplot$name))

      }, error = function(e) {
        status_text(paste0("❌ Error: ", conditionMessage(e)))
      })
    })
  })

  # Mostrar previsualització amb alta resolució
  output$preview_plot <- renderPlot({
    req(grafic_actual())

    tryCatch({
      print(grafic_actual())
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, paste("Error en previsualització:", conditionMessage(e)), cex = 1.2)
    })
  }, res = 144, width = 1200, height = 900)

  # Descarregar PowerPoint
  output$descarregar_pptx <- downloadHandler(
    filename = function() {
      if (!is.null(nom_fitxer())) {
        nom_base <- tools::file_path_sans_ext(nom_fitxer())
        paste0(nom_base, "_editable.pptx")
      } else {
        "grafic_editable.pptx"
      }
    },
    content = function(file) {
      req(grafic_actual())

      withProgress(message = '💾 Creant PowerPoint', value = 0, {
        tryCatch({
          incProgress(0.2, detail = "Convertint a format vectorial...")

          # Crear objecte DrawingML vectorial editable
          p_dml <- rvg::dml(ggobj = grafic_actual())

          incProgress(0.3, detail = "Configurant diapositiva...")

          # Configurar ubicació segons mida seleccionada
          location <- switch(input$mida_diapo,
            "full" = ph_location_fullsize(),
            "medium" = ph_location(left = 1, top = 1, width = 8, height = 6),
            "small" = ph_location(left = 2, top = 1.5, width = 6, height = 4.5)
          )

          incProgress(0.3, detail = "Generant presentació...")

          # Crear PowerPoint
          doc <- read_pptx() |>
            add_slide() |>
            ph_with(value = p_dml, location = location)

          incProgress(0.15, detail = "Desant arxiu...")

          # Guardar
          print(doc, target = file)

          incProgress(0.05, detail = "Finalitzant...")

          status_text("✅ PowerPoint generat correctament")

        }, error = function(e) {
          status_text(paste0("❌ Error generant PowerPoint: ", conditionMessage(e)))
        })
      })
    }
  )

  # Mostrar status
  output$status <- renderText({
    status_text()
  })
}

shinyApp(ui = ui, server = server)
