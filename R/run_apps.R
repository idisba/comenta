#' Executar aplicació col·laborativa d'anotació
#'
#' Llança l'aplicació Shiny per anotació col·laborativa de documents
#' amb base de dades SQLite i suport d'IA (Gemini/Ollama).
#'
#' @param port Port on executar l'aplicació (per defecte aleatori)
#' @param launch.browser Si obrir automàticament el navegador (TRUE per defecte)
#'
#' @export
#' @examples
#' \dontrun{
#'   run_colab()
#' }
run_colab <- function(port = NULL, launch.browser = TRUE) {
  app_dir <- system.file("colab", package = "Comenta")

  if (app_dir == "") {
    stop("No s'ha trobat l'aplicació. Assegura't que el paquet està instal·lat correctament.")
  }

  message("🚀 Llançant Comenta: Anotació Col·laborativa")
  message("📂 Directori:", app_dir)

  shiny::runApp(
    appDir = app_dir,
    port = port,
    launch.browser = launch.browser
  )
}

#' Executar aplicació d'anotació de PDFs
#'
#' Llança l'aplicació Shiny per anotar PDFs amb PyMuPDF i IA.
#' Requereix Python 3 amb PyMuPDF instal·lat.
#'
#' @param port Port on executar l'aplicació (per defecte aleatori)
#' @param launch.browser Si obrir automàticament el navegador (TRUE per defecte)
#'
#' @export
#' @examples
#' \dontrun{
#'   run_pdf()
#' }
run_pdf <- function(port = NULL, launch.browser = TRUE) {
  app_dir <- system.file("pdf", package = "Comenta")

  if (app_dir == "") {
    stop("No s'ha trobat l'aplicació. Assegura't que el paquet està instal·lat correctament.")
  }

  # Verificar Python i PyMuPDF
  python_ok <- tryCatch({
    reticulate::py_module_available("fitz") || reticulate::py_module_available("pymupdf")
  }, error = function(e) FALSE)

  if (!python_ok) {
    warning(
      "⚠️ PyMuPDF no detectat. Instal·la'l amb:\n",
      "   pip3 install PyMuPDF\n",
      "L'aplicació pot no funcionar correctament sense PyMuPDF."
    )
  }

  message("🚀 Llançant Comenta: Anotació de PDFs")
  message("📂 Directori:", app_dir)

  # Copiar script Python (necessari per PyMuPDF)
  python_dir <- system.file("python", package = "Comenta")
  if (file.exists(file.path(python_dir, "anotar_pdf.py"))) {
    file.copy(
      file.path(python_dir, "anotar_pdf.py"),
      file.path(app_dir, "anotar_pdf.py"),
      overwrite = TRUE
    )
  }

  shiny::runApp(
    appDir = app_dir,
    port = port,
    launch.browser = launch.browser
  )
}

#' Executar aplicació d'anotació de gràfics
#'
#' Llança l'aplicació Shiny per anotar gràfics i imatges PNG.
#'
#' @param port Port on executar l'aplicació (per defecte aleatori)
#' @param launch.browser Si obrir automàticament el navegador (TRUE per defecte)
#'
#' @export
#' @examples
#' \dontrun{
#'   run_grafics()
#' }
run_grafics <- function(port = NULL, launch.browser = TRUE) {
  app_dir <- system.file("grafics", package = "Comenta")

  if (app_dir == "") {
    stop("No s'ha trobat l'aplicació. Assegura't que el paquet està instal·lat correctament.")
  }

  message("🚀 Llançant Comenta: Anotació de Gràfics")
  message("📂 Directori:", app_dir)

  shiny::runApp(
    appDir = app_dir,
    port = port,
    launch.browser = launch.browser
  )
}

#' Executar aplicació d'anotació d'HTMLs
#'
#' Llança l'aplicació Shiny per anotar documents HTML amb
#' auto-interpretació per IA de taules, gràfics i seccions.
#'
#' @param port Port on executar l'aplicació (per defecte aleatori)
#' @param launch.browser Si obrir automàticament el navegador (TRUE per defecte)
#'
#' @export
#' @examples
#' \dontrun{
#'   run_public()
#' }
run_public <- function(port = NULL, launch.browser = TRUE) {
  app_dir <- system.file("public", package = "Comenta")

  if (app_dir == "") {
    stop("No s'ha trobat l'aplicació. Assegura't que el paquet està instal·lat correctament.")
  }

  message("🚀 Llançant Comenta: Anotació d'HTMLs Públics")
  message("📂 Directori:", app_dir)

  shiny::runApp(
    appDir = app_dir,
    port = port,
    launch.browser = launch.browser
  )
}
