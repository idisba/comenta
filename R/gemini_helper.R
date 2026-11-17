# ============================================================
# Helper per integrar Google Gemini a AnotaR PDF
# ============================================================

library(httr)
library(jsonlite)

# Configuració
GEMINI_API_KEY <- Sys.getenv("GEMINI_API_KEY")
GEMINI_MODEL <- "gemini-1.5-flash-latest"  # Model gratuït i ràpid
GEMINI_ENDPOINT <- "https://generativelanguage.googleapis.com/v1beta"

#' Verificar si Gemini està configurat
#'
#' @return TRUE si l'API key està configurada
gemini_disponible <- function() {
  return(GEMINI_API_KEY != "" && !is.null(GEMINI_API_KEY))
}

#' Resumir text amb Gemini
#'
#' @param text Text a resumir
#' @param max_paraules Nombre màxim de paraules del resum
#' @param idioma Idioma del resum (catala, espanyol, angles)
#' @return Text resumit
resumir_text_gemini <- function(text, max_paraules = 200, idioma = "catala") {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada. Afegeix GEMINI_API_KEY al .Renviron")
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
    "TEXT A RESUMIR:\n", text
  )

  # URL de l'API
  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  # Cos de la petició
  body <- list(
    contents = list(
      list(
        parts = list(
          list(text = prompt)
        )
      )
    ),
    generationConfig = list(
      temperature = 0.3,  # Més determinístic
      maxOutputTokens = as.integer(max_paraules * 2),  # Marge
      topP = 0.8,
      topK = 10
    )
  )

  # Fer la petició
  response <- tryCatch({
    httr::POST(
      url,
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      httr::content_type_json(),
      encode = "raw",
      httr::timeout(30)
    )
  }, error = function(e) {
    stop(paste("Error de connexió amb Gemini:", e$message))
  })

  # Comprovar status
  if (httr::status_code(response) != 200) {
    error_content <- httr::content(response, "text", encoding = "UTF-8")
    stop(paste("Error de Gemini API:", error_content))
  }

  # Parsejar resposta
  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )

  # Extreure text
  if (is.null(result$candidates) || length(result$candidates) == 0) {
    stop("Gemini no ha retornat resultats")
  }

  text_resum <- result$candidates[[1]]$content$parts[[1]]$text

  return(text_resum)
}

#' Extreure conceptes clau d'un text
#'
#' @param text Text científic
#' @param num_conceptes Nombre de conceptes a extreure
#' @return Vector de conceptes clau
extreure_conceptes_gemini <- function(text, num_conceptes = 5) {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada")
  }

  prompt <- paste0(
    "Extreu els ", num_conceptes, " conceptes clau més importants d'aquest text científic.\n",
    "Respon NOMÉS amb una llista separada per comes, sense numeració.\n",
    "Exemple: diabetes mellitus, glucosa, insulina, hemoglobina glicada\n\n",
    "TEXT:\n", text
  )

  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  body <- list(
    contents = list(
      list(parts = list(list(text = prompt)))
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw"
  )

  if (httr::status_code(response) != 200) {
    stop("Error cridant Gemini API")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )

  text_conceptes <- result$candidates[[1]]$content$parts[[1]]$text

  # Parsejar llista
  conceptes <- strsplit(text_conceptes, ",")[[1]]
  conceptes <- trimws(conceptes)

  return(conceptes)
}

#' Traduir text amb Gemini
#'
#' @param text Text a traduir
#' @param idioma_desti Idioma destí (catala, espanyol, angles)
#' @return Text traduït
traduir_gemini <- function(text, idioma_desti = "angles") {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada")
  }

  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )

  idioma <- idioma_map[[idioma_desti]] %||% "English"

  prompt <- paste0(
    "Tradueix aquest text científic a ", idioma, ".\n",
    "Manté la terminologia tècnica.\n\n",
    "TEXT:\n", text
  )

  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  body <- list(
    contents = list(
      list(parts = list(list(text = prompt)))
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw"
  )

  if (httr::status_code(response) != 200) {
    stop("Error cridant Gemini API")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )

  return(result$candidates[[1]]$content$parts[[1]]$text)
}

#' Interpretar resultats científics amb Gemini
#'
#' @param text Text o dades a interpretar (taula, resultats, gràfic)
#' @param tipus Tipus de dades ("taula", "grafic", "resultats", "general")
#' @param idioma Idioma de la interpretació
#' @return Interpretació detallada
interpretar_resultats_gemini <- function(text, tipus = "general", idioma = "catala") {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada")
  }

  if (nchar(text) < 20) {
    stop("Text massa curt per interpretar (mínim 20 caràcters)")
  }

  idioma_map <- list(
    catala = "català",
    espanyol = "español",
    angles = "English"
  )
  idioma_text <- idioma_map[[idioma]] %||% "català"

  # Prompts especialitzats segons tipus
  tipus_prompts <- list(
    taula = "Analitza aquesta taula de resultats científics. Identifica:\n1. Valors destacats (normals vs anòmals)\n2. Patrons o tendències\n3. Possibles problemes o outliers\n4. Significat biològic/científic",
    grafic = "Interpreta aquest gràfic o les seves dades. Identifica:\n1. Patró general (tendència, distribució)\n2. Punts destacats o anomalies\n3. Implicacions científiques\n4. Possibles explicacions biològiques",
    resultats = "Interpreta aquests resultats científics. Identifica:\n1. Resultats clau principals\n2. Significació estadística i biològica\n3. Implicacions per a la hipòtesi\n4. Limitacions observades",
    general = "Interpreta científicament aquestes dades. Identifica aspectes clau, patrons, i significat."
  )

  prompt_base <- tipus_prompts[[tipus]] %||% tipus_prompts[["general"]]

  prompt <- paste0(
    "Ets un expert bioinformàtic. ", prompt_base, "\n\n",
    "IMPORTANT:\n",
    "- Respon en ", idioma_text, "\n",
    "- Usa emojis per claritat: ✅ (positiu), ⚠️ (atenció), 📊 (dades), 🔬 (científic), 💡 (recomanació)\n",
    "- Sigues concís però precís (màx 200 paraules)\n",
    "- Centra't en allò científicament rellevant\n\n",
    "DADES A INTERPRETAR:\n", text, "\n\n",
    "INTERPRETACIÓ:"
  )

  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  body <- list(
    contents = list(
      list(parts = list(list(text = prompt)))
    ),
    generationConfig = list(
      temperature = 0.4,
      maxOutputTokens = 500,
      topP = 0.9
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(30)
  )

  if (httr::status_code(response) != 200) {
    stop("Error cridant Gemini API")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )

  return(result$candidates[[1]]$content$parts[[1]]$text)
}

#' Analitzar dades amb Gemini (anàlisi més profunda)
#'
#' @param text Dades a analitzar
#' @param context Context addicional (opcional)
#' @param idioma Idioma de l'anàlisi
#' @return Anàlisi detallada
analitzar_dades_gemini <- function(text, context = "", idioma = "catala") {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada")
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

  context_text <- if (context != "") paste0("\n\nCONTEXT ADDICIONAL:\n", context) else ""

  prompt <- paste0(
    "Ets un bioinformàtic expert en anàlisi de dades. Analitza aquestes dades en profunditat:\n\n",
    "TASQUES:\n",
    "1. 📊 Anàlisi descriptiva: Resumeix les dades principals\n",
    "2. 🔍 Detecció d'anomalies: Identifica outliers o valors sospitosos\n",
    "3. 📈 Comparacions: Compara valors entre si (si aplicable)\n",
    "4. 🔬 Interpretació biològica: Què signifiquen aquestes dades?\n",
    "5. ⚠️ Possibles problemes: Errors, biaixos, o limitacions\n\n",
    "IMPORTANT:\n",
    "- Respon en ", idioma_text, "\n",
    "- Sigues sistemàtic i estructurat\n",
    "- Màxim 300 paraules\n",
    "- Inclou valors específics quan sigui rellevant\n",
    context_text, "\n\n",
    "DADES A ANALITZAR:\n", text, "\n\n",
    "ANÀLISI:"
  )

  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  body <- list(
    contents = list(
      list(parts = list(list(text = prompt)))
    ),
    generationConfig = list(
      temperature = 0.3,
      maxOutputTokens = 700,
      topP = 0.85
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(40)
  )

  if (httr::status_code(response) != 200) {
    stop("Error cridant Gemini API")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )

  return(result$candidates[[1]]$content$parts[[1]]$text)
}

#' Obtenir recomanacions pràctiques amb Gemini
#'
#' @param text Resultats o situació a analitzar
#' @param idioma Idioma de les recomanacions
#' @return Recomanacions pràctiques
recomanacions_gemini <- function(text, idioma = "catala") {

  if (!gemini_disponible()) {
    stop("Gemini API key no configurada")
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
    "Ets un assessor bioinformàtic expert. Basant-te en aquests resultats, proporciona recomanacions pràctiques:\n\n",
    "ESTRUCTURA DE LA RESPOSTA:\n",
    "1. 💡 Pròxims passos recomanats (2-4 accions concretes)\n",
    "2. ⚠️ Aspectes a vigilar o verificar\n",
    "3. 🔬 Anàlisis o validacions addicionals suggerides\n",
    "4. 📋 Consideracions pràctiques\n\n",
    "IMPORTANT:\n",
    "- Respon en ", idioma_text, "\n",
    "- Sigues concret i accionable (no genèric)\n",
    "- Prioritza per importància\n",
    "- Màxim 250 paraules\n",
    "- Si detectes problemes crítics, marca'ls amb ⚠️ o ❌\n\n",
    "RESULTATS/SITUACIÓ:\n", text, "\n\n",
    "RECOMANACIONS:"
  )

  url <- paste0(
    GEMINI_ENDPOINT, "/models/", GEMINI_MODEL,
    ":generateContent?key=", GEMINI_API_KEY
  )

  body <- list(
    contents = list(
      list(parts = list(list(text = prompt)))
    ),
    generationConfig = list(
      temperature = 0.5,
      maxOutputTokens = 600,
      topP = 0.9
    )
  )

  response <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    encode = "raw",
    httr::timeout(35)
  )

  if (httr::status_code(response) != 200) {
    stop("Error cridant Gemini API")
  }

  result <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )

  return(result$candidates[[1]]$content$parts[[1]]$text)
}

#' Obtenir informació d'ús de Gemini
#'
#' @return Missatge amb estat de configuració
gemini_info <- function() {
  if (gemini_disponible()) {
    return(paste0(
      "✅ Gemini configurat correctament\n",
      "Model: ", GEMINI_MODEL, "\n",
      "Quota gratuïta: 60 req/min, 1500 req/dia, 1M tokens/mes\n",
      "Cost estimat: 0€ (dins quota gratuïta)"
    ))
  } else {
    return(paste0(
      "❌ Gemini NO configurat\n\n",
      "Per configurar:\n",
      "1. Ves a https://makersuite.google.com/app/apikey\n",
      "2. Crea una API key (gratuït, no cal targeta)\n",
      "3. Afegeix a ~/.Renviron:\n",
      "   GEMINI_API_KEY=la_teva_clau\n",
      "4. Reinicia R/Shiny"
    ))
  }
}

# Exportar funcions
# (No cal export explícit si es fa source() a l'app)
