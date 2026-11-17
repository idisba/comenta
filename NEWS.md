# Comenta 0.1.0 (2024-11-16)

## Primera versió pública 🎉

### Aplicacions incloses

- **run_colab()**: Aplicació col·laborativa amb SQLite
- **run_pdf()**: Anotació de PDFs amb PyMuPDF
- **run_grafics()**: Anotació de gràfics PNG
- **run_public()**: Anotació d'HTMLs amb auto-interpretació

### Funcionalitats IA

- ✅ Integració Gemini Flash 2.0
- ✅ Integració Ollama (models locals)
- ✅ 4 accions: Interpretar, Analitzar, Recomanar, Resumir
- ✅ Suport català, castellà, anglès

### Característiques PDFs

- ✅ Anotacions amb postits al marge dret
- ✅ Pàgina de resum automàtica al final
- ✅ Cerca intel·ligent de text (normalització)
- ✅ Només 1 anotació per text (primera coincidència)

### Característiques HTMLs

- ✅ Toolbars automàtics a taules/gràfics/headers
- ✅ Notes ancorades visuals
- ✅ Exportar HTML anotat
- ✅ Compatibilitat NanoPlot, MultiQC, reports R

### Característiques col·laboratives

- ✅ Base de dades SQLite
- ✅ Múltiples usuaris
- ✅ Historial de comentaris
- ✅ Exportar documents amb anotacions

### Millores tècniques

- ✅ Notificacions al lateral dret (no tapen contingut)
- ✅ Logging complet de Python
- ✅ Gestió d'errors robusta
- ✅ Documentació roxygen2

## Pròximes versions

### v0.2.0 (planificat)

- [ ] Tests amb testthat
- [ ] Vignettes amb exemples
- [ ] Suport més models Ollama
- [ ] Millora UI/UX
- [ ] CI/CD amb GitHub Actions

### v0.3.0 (planificat)

- [ ] Integració amb altres LLMs (Claude, GPT)
- [ ] Mode offline complet
- [ ] Exportar a Word/Markdown
- [ ] API REST per integració externa
