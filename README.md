# Comenta 📝🤖

**CO**llaborative **ME**ntions and **N**otes with **TA**sked AI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R-CMD-check](https://github.com/idisba/comenta/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/idisba/comenta/actions/workflows/R-CMD-check.yaml)
[![Project Status: Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24310215.svg)](https://doi.org/10.5281/zenodo.24310215)

## Description

**Comenta** is a suite of Shiny applications developed by IDISBA to facilitate collaborative annotation and commenting of scientific documents with Artificial Intelligence support (Google Gemini Flash and local Ollama models).

### 🎯 Features

- 📄 **PDF annotation** with PyMuPDF and automatic summary page generation
- 🌐 **HTML annotation** with automatic interpretation of tables and figures
- 📊 **Graphics annotation** for PNG files with clickable coordinate markers
- 👥 **Collaborative mode** with SQLite database for multi-user workflows
- 🤖 **AI integration**: Interpret, Analyze, Recommend, Summarize
  - Google Gemini Flash 2.0
  - Ollama (local, private)
- 🔗 **Automatic biomedical term linking** to PubMed, NCBI Gene, and UniProt

## Installation

### From GitHub

```r
# Install devtools if you don't have it
install.packages("devtools")

# Install Comenta
devtools::install_github("idisba/comenta")
```

### Python Dependencies (optional, for PDF annotation)

The PDF annotation app requires Python 3 with PyMuPDF:

```bash
pip3 install PyMuPDF
```

### API Keys (optional)

For Google Gemini:
```r
# Add to your .Renviron file
GEMINI_API_KEY=your_key_here
```

For Ollama (local):
```bash
# Install Ollama: https://ollama.ai
ollama pull qwen2.5:7b  # or another model
```

## Usage

### Collaborative Annotation App

```r
library(Comenta)
run_colab()
```

Features:
- SQLite database for multiple users
- Upload PDFs/HTMLs
- AI-assisted comments
- Export annotated documents

### PDF Annotation App

```r
library(Comenta)
run_pdf()
```

Features:
- Annotate PDFs with sticky notes in margins
- AI-powered auto-interpretation
- Automatic summary page at the end
- Export annotated PDF with permanent annotations

### HTML Annotation App

```r
library(Comenta)
run_public()
```

Features:
- Automatic toolbars on tables and figures
- Interpret, Analyze, and Summarize sections
- Anchored notes
- Export annotated HTML

### Graphics Annotation App

```r
library(Comenta)
run_grafics()
```

Features:
- Upload PNG images
- Add annotations by clicking on the graphic
- Comments with coordinate markers
- Export annotated image

## Package Structure

```
Comenta/
├── R/
│   ├── run_apps.R           # run_*() functions
│   ├── gemini_helper.R      # Gemini API functions
│   └── ollama_helper.R      # Ollama functions
├── inst/
│   ├── colab/               # Collaborative app
│   ├── pdf/                 # PDF app
│   ├── grafics/             # Graphics app
│   └── public/              # HTML app
├── inst/python/
│   └── anotar_pdf.py        # PyMuPDF script
└── man/                     # Documentation
```

## Advanced Configuration

### Recommended Ollama Models

```bash
# Small models (7B) - fast
ollama pull qwen2.5:7b
ollama pull llama3.2:latest

# Medium models (13B) - balanced
ollama pull qwen2.5:14b

# Large models (32B+) - highest quality
ollama pull qwen2.5:32b
```

### Environment Variables

```bash
# .Renviron
GEMINI_API_KEY=your_key_here
OLLAMA_HOST=http://localhost:11434
```

## Examples

### Example 1: Analyze PDF with AI

```r
library(Comenta)

# Launch app
run_pdf()

# 1. Upload a scientific PDF
# 2. Select text from a table
# 3. Click "📊 Analyze"
# 4. AI generates statistical analysis
# 5. Click "🎨 Generate Annotated PDF"
# 6. Download PDF with annotations + summary page
```

### Example 2: Interpret HTML Report

```r
library(Comenta)

# Launch app
run_public()

# 1. Upload an HTML report (e.g., MultiQC, FastQC)
# 2. Hover over a table
# 3. Automatic toolbar appears
# 4. Click "🔍 Interpret"
# 5. AI explains the results
```

## Development

### Local Installation

To develop and modify the package:

```bash
# Clone repository
git clone https://github.com/idisba/comenta.git
cd comenta

# Install from local directory
R -e "devtools::install('.', dependencies = FALSE)"

# Test
R -e "library(Comenta); run_pdf()"
```

### Updating After Changes

When you modify files in `inst/`, you need to reinstall:

```bash
# Option 1: Automated script (recommended)
./actualitzar.sh

# Option 2: Manual
R -e "devtools::install('.', dependencies = FALSE)"
```

The `actualitzar.sh` script:
- Reinstalls the package
- Automatically restarts Shiny Server apps
- Keeps everything synchronized

See `DESENVOLUPAMENT.md` for detailed development guidelines (in Catalan).

## Testing

The package includes 36 automated tests:

```r
devtools::test()
```

Continuous integration via GitHub Actions tests on Ubuntu, Windows, and macOS.

## Citation

If you use Comenta in your research, please cite:

```bibtex
@software{comenta_2026,
  author       = {IDISBA Bioinformatics Team},
  title        = {Comenta: Collaborative Scientific Document Annotation with AI},
  year         = 2026,
  publisher    = {Zenodo},
  version      = {v0.1.0},
  doi          = {10.5281/zenodo.24310215},
  url          = {https://doi.org/10.5281/zenodo.24310215}
}
```

## Contributing

Contributions are welcome! 

1. Fork the repository
2. Create a branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## Support

For issues or questions:
- 🐛 [GitHub Issues](https://github.com/idisba/comenta/issues)
- 📧 Email: bioinformatica@idisba.es

## License

MIT License - Copyright (c) 2026 IDISBA

## Authors

**IDISBA - Institut d'Investigació Sanitària Illes Balears**
- Bioinformatics Team

---

Developed with ❤️ at the Balearic Islands 🏝️
