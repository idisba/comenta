# ============================================================
# Helper per integrar Ollama local a AnotaR PDF
# ============================================================

library(httr)
library(jsonlite)

# Configuració
OLLAMA_ENDPOINT <- Sys.getenv("OLLAMA_ENDPOINT", "http://localhost:11434")

#' Verificar si Ollama està disponible
#'
#' @return TRUE si Ollama està executant-se
ollama_disponible <- function() {
  tryCatch({
    response <- httr::GET(
      paste0(OLLAMA_ENDPOINT, "/api/tags"),
      httr::timeout(2)
    )
    return(httr::status_code(response) == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

#' Llistar models disponibles a Ollama
#'
#' @return Vector de noms de models
ollama_llistar_models <- function() {
  if (!ollama_disponible()) {
    return(character(0))
  }

  tryCatch({
    response <- httr::GET(
      paste0(OLLAMA_ENDPOINT, "/api/tags"),
      httr::timeout(5)
    )

    if (httr::status_code(response) != 200) {
      return(character(0))
    }

    result <- jsonlite::fromJSON(
      httr::content(response, "text", encoding = "UTF-8")
    )

    if (!is.null(result$models) && length(result$models) > 0) {
      return(result$models$name)
    }

    return(character(0))

  }, error = function(e) {
    return(character(0))
  })
}

#' Resumir text amb Ollama
#'
#' @param text Text a resumir
#' @param model Model d'Ollama a usar (ex: "qwen2.5:7b")
#' @param max_paraules Nombre màxim de paraules del resum
#' @param idioma Idioma del resum (catala, espanyol, angles)
#' @return Text resumit
resumir_text_ollama <- function(text, model = "qwen2.5:7b", max_paraules = 200, idioma = "catala") {

  if (!ollama_disponible()) {
    stop("Ollama no està disponible. Verifica que el servei està executant-se.")
  }

  if (nchar(text) < 100) {
    stop("Text massa curt per resumir (mínim 100 caràcters)")
  }

  # Construir prompt segons idioma
  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )

  idioma_text <- idioma_map[[idioma]] %||% "català"

  prompt <- paste0(
    "Resumeix aquest fragment científic en màxim ", max_paraules, " paraules.\n",
    "IMPORTANT: Respon NOMÉS en ", idioma_text, ".\n",
    "Format: Paràgraf únic, clar i concís.\n\n",
    "TEXT A RESUMIR:\n", text, "\n\n",
    "RESUM:"
  )

  # URL de l'API
  url <- paste0(OLLAMA_ENDPOINT, "/api/generate")

  # Cos de la petició
  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE,
    options = list(
      temperature = 0.3,
      num_predict = as.integer(max_paraules * 2)
    )
  )

  # Fer la petició
  response <- tryCatch({
    httr::POST(
      url,
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      httr::content_type_json(),
      encode = "raw",
      httr::timeout(120)  # Ollama pot trigar
    )
  }, error = function(e) {
    stop(paste("Error de connexió amb Ollama:", e$message))
  })

  # Comprovar status
  if (httr::status_code(response) != 200) {
    error_content <- httr::content(response, "text", encoding = "UTF-8")
    stop(paste("Error de Ollama:", error_content))
  }

  # Parsejar resposta
  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  # Extreure text
  if (is.null(result$response)) {
    stop("Ollama no ha retornat resultats")
  }

  text_resum <- trimws(result$response)

  return(text_resum)
}

#' Interpretar resultats científics amb Ollama
#'
#' @param text Text o dades a interpretar
#' @param model Model d'Ollama a usar
#' @param tipus Tipus de dades ("taula", "grafic", "resultats", "general")
#' @param idioma Idioma de la interpretació
#' @return Interpretació detallada
interpretar_resultats_ollama <- function(text, model = "qwen2.5:7b", tipus = "general", idioma = "catala") {

  if (!ollama_disponible()) {
    stop("Ollama no està disponible")
  }

  if (nchar(text) < 20) {
    stop("Text massa curt per interpretar")
  }

  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )
  idioma_text <- idioma_map[[idioma]] %||% "català"

  tipus_prompts <- list(
    taula = "Analitza aquesta taula de resultats científics. Identifica valors destacats, patrons, possibles problemes i significat biològic.",
    grafic = "Interpreta aquest gràfic. Identifica el patró general, punts destacats, implicacions científiques i possibles explicacions.",
    resultats = "Interpreta aquests resultats científics. Identifica resultats clau, significació estadística i biològica, i implicacions.",
    general = "Interpreta científicament aquestes dades. Identifica aspectes clau i significat."
  )

  prompt_base <- tipus_prompts[[tipus]] %||% tipus_prompts[["general"]]

  prompt <- paste0(
    "Ets un expert bioinformàtic. ", prompt_base, "\n\n",
    "IMPORTANT: Respon en ", idioma_text, ".\n",
    "Usa emojis: ✅ (positiu), ⚠️ (atenció), 📊 (dades), 🔬 (científic), 💡 (recomanació).\n",
    "Màxim 200 paraules, concís i precís.\n\n",
    "DADES:\n", text, "\n\n",
    "INTERPRETACIÓ:"
  )

  url <- paste0(OLLAMA_ENDPOINT, "/api/generate")

  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE,
    options = list(
      temperature = 0.4,
      num_predict = 400
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(120)
  )

  if (httr::status_code(response) != 200) {
    stop("Error de Ollama")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  return(trimws(result$response))
}

#' Analitzar dades amb Ollama
#'
#' @param text Dades a analitzar
#' @param model Model d'Ollama
#' @param context Context addicional
#' @param idioma Idioma
#' @return Anàlisi detallada
analitzar_dades_ollama <- function(text, model = "qwen2.5:7b", context = "", idioma = "catala") {

  if (!ollama_disponible()) {
    stop("Ollama no està disponible")
  }

  if (nchar(text) < 20) {
    stop("Text massa curt per analitzar")
  }

  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )
  idioma_text <- idioma_map[[idioma]] %||% "català"

  context_text <- if (context != "") paste0("\nCONTEXT: ", context) else ""

  prompt <- paste0(
    "Ets un bioinformàtic expert. Analitza aquestes dades:\n\n",
    "1. 📊 Resum dades principals\n",
    "2. 🔍 Anomalies o outliers\n",
    "3. 📈 Comparacions\n",
    "4. 🔬 Interpretació biològica\n",
    "5. ⚠️ Possibles problemes\n\n",
    "Respon en ", idioma_text, ". Màxim 300 paraules.\n",
    context_text, "\n\n",
    "DADES:\n", text, "\n\n",
    "ANÀLISI:"
  )

  url <- paste0(OLLAMA_ENDPOINT, "/api/generate")

  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE,
    options = list(
      temperature = 0.3,
      num_predict = 550
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(150)
  )

  if (httr::status_code(response) != 200) {
    stop("Error de Ollama")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  return(trimws(result$response))
}

#' Obtenir recomanacions pràctiques amb Ollama
#'
#' @param text Resultats a analitzar
#' @param model Model d'Ollama
#' @param idioma Idioma
#' @return Recomanacions
recomanacions_ollama <- function(text, model = "qwen2.5:7b", idioma = "catala") {

  if (!ollama_disponible()) {
    stop("Ollama no està disponible")
  }

  if (nchar(text) < 20) {
    stop("Text massa curt per generar recomanacions")
  }

  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )
  idioma_text <- idioma_map[[idioma]] %||% "català"

  prompt <- paste0(
    "Ets un assessor bioinformàtic. Basant-te en aquests resultats, proporciona recomanacions:\n\n",
    "1. 💡 Pròxims passos (2-4 accions concretes)\n",
    "2. ⚠️ Aspectes a verificar\n",
    "3. 🔬 Anàlisis addicionals suggerides\n",
    "4. 📋 Consideracions pràctiques\n\n",
    "Respon en ", idioma_text, ". Sigues concret i accionable. Màxim 250 paraules.\n\n",
    "RESULTATS:\n", text, "\n\n",
    "RECOMANACIONS:"
  )

  url <- paste0(OLLAMA_ENDPOINT, "/api/generate")

  body <- list(
    model = model,
    prompt = prompt,
    stream = FALSE,
    options = list(
      temperature = 0.5,
      num_predict = 500
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(140)
  )

  if (httr::status_code(response) != 200) {
    stop("Error de Ollama")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  return(trimws(result$response))
}

#' Obtenir informació d'Ollama
#'
#' @return Missatge amb estat de configuració
ollama_info <- function() {
  if (ollama_disponible()) {
    models <- ollama_llistar_models()

    if (length(models) > 0) {
      return(paste0(
        "✅ Ollama disponible\n",
        "Endpoint: ", OLLAMA_ENDPOINT, "\n",
        "Models instal·lats: ", length(models), "\n",
        "Models: ", paste(head(models, 5), collapse = ", "),
        if(length(models) > 5) "..." else "", "\n",
        "Cost: 0€ (100% local)\n",
        "Privacitat: Total (no surt del servidor)"
      ))
    } else {
      return(paste0(
        "⚠️ Ollama disponible però sense models\n",
        "Instal·la un model:\n",
        "  ollama pull qwen2.5:7b\n",
        "  ollama pull mistral:latest"
      ))
    }
  } else {
    return(paste0(
      "❌ Ollama NO disponible\n\n",
      "Verifica que el servei està executant-se:\n",
      "  sudo systemctl status ollama\n",
      "O inicia'l:\n",
      "  ollama serve"
    ))
  }
}

#' Obtenir model recomanat
#'
#' @return Nom del millor model disponible
ollama_model_recomanat <- function() {
  models <- ollama_llistar_models()

  if (length(models) == 0) {
    return(NULL)
  }

  # Prioritats (models més adequats per resumir text científic)
  preferits <- c(
    "qwen2.5:7b",
    "qwen2.5-coder:7b",
    "mistral:latest",
    "dolphin3:8b",
    "qwen:4b"
  )

  # Buscar primer model preferit disponible
  for (model in preferits) {
    if (model %in% models) {
      return(model)
    }
  }

  # Si no, retornar el primer disponible
  return(models[1])
}
