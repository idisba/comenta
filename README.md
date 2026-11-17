# Comenta 📝🤖

**Co**mentari **Co**l·laboratiu i **Menta** (Mentor IA) per Documents Científics

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Descripció

**Comenta** és una suite d'aplicacions Shiny desenvolupada per IDISBA per facilitar l'anotació i comentari de documents científics amb suport d'Intel·ligència Artificial (Gemini Flash i Ollama local).

### 🎯 Funcionalitats

- 📄 **Anotació de PDFs** amb PyMuPDF i pàgina de resum automàtica
- 🌐 **Anotació d'HTMLs** amb auto-interpretació de taules i gràfics
- 📊 **Anotació de gràfics** PNG amb punts clicables
- 👥 **Mode col·laboratiu** amb base de dades SQLite
- 🤖 **IA integrada**: Interpretar, Analitzar, Recomanar, Resumir
  - Google Gemini Flash 2.0
  - Ollama (local, privat)

## Instal·lació

### Des de GitHub

```r
# Instal·lar devtools si no el tens
install.packages("devtools")

# Instal·lar Comenta
devtools::install_github("idisba/Comenta")
```

### Dependencies Python (opcional, per PDFs)

Per l'aplicació de PDFs necessites Python 3 amb PyMuPDF:

```bash
pip3 install PyMuPDF
```

### API Keys (opcional)

Per usar Gemini:
```r
# Definir al .Renviron
GEMINI_API_KEY=la_teva_clau_aqui
```

Per usar Ollama (local):
```bash
# Instal·lar Ollama: https://ollama.ai
ollama pull qwen2.5:7b  # o un altre model
```

## Ús

### Aplicació Col·laborativa

```r
library(Comenta)
run_colab()
```

Funcionalitats:
- Base de dades SQLite per múltiples usuaris
- Pujar PDFs/HTMLs
- Comentaris amb IA
- Exportar documents anotats

### Aplicació de PDFs

```r
library(Comenta)
run_pdf()
```

Funcionalitats:
- Anotar PDFs amb postits al marge
- Auto-interpretació amb IA
- Pàgina de resum automàtica al final
- Exportar PDF anotat

### Aplicació d'HTMLs

```r
library(Comenta)
run_public()
```

Funcionalitats:
- Toolbars automàtics a taules i gràfics
- Interpretar, Analitzar, Resumir seccions
- Notes ancorades
- Exportar HTML anotat

### Aplicació de Gràfics

```r
library(Comenta)
run_grafics()
```

Funcionalitats:
- Pujar PNG
- Afegir anotacions clicant sobre el gràfic
- Comentaris amb coordenades
- Exportar imatge anotada

## Estructura del Paquet

```
Comenta/
├── R/
│   ├── run_apps.R           # Funcions run_*()
│   ├── gemini_helper.R      # Funcions Gemini
│   └── ollama_helper.R      # Funcions Ollama
├── inst/
│   ├── colab/               # App col·laborativa
│   ├── pdf/                 # App PDFs
│   ├── grafics/             # App gràfics
│   └── public/              # App HTMLs
├── python/
│   └── anotar_pdf.py        # Script PyMuPDF
└── man/                     # Documentació
```

## Configuració Avançada

### Models Ollama Recomanats

```bash
# Models petits (7B) - ràpids
ollama pull qwen2.5:7b
ollama pull llama3.2:latest

# Models mitjans (13B) - equilibrats
ollama pull qwen2.5:14b

# Models grans (70B+) - màxima qualitat
ollama pull qwen2.5:32b
```

### Variables d'Entorn

```bash
# .Renviron
GEMINI_API_KEY=your_key_here
OLLAMA_HOST=http://localhost:11434
```

## Exemples

### Exemple 1: Analitzar PDF amb IA

```r
library(Comenta)

# Llançar app
run_pdf()

# 1. Puja un PDF científic
# 2. Selecciona text d'una taula
# 3. Clica "📊 Analitzar"
# 4. La IA genera anàlisi estadística
# 5. Clica "🎨 Generar PDF Anotat"
# 6. Descarrega PDF amb anotacions + pàgina resum
```

### Exemple 2: Interpretar HTML

```r
library(Comenta)

# Llançar app
run_public()

# 1. Puja un report HTML (NanoPlot, MultiQC, etc.)
# 2. Passa el ratolí sobre una taula
# 3. Apareix toolbar automàtic
# 4. Clica "🔍 Interpretar"
# 5. La IA explica els resultats en català
```

## Desenvolupament

### Instal·lació Local

Per desenvolupar i modificar el paquet:

```bash
# Clonar repositori
git clone https://github.com/idisba/Comenta.git
cd Comenta

# Instal·lar des del directori local
devtools::install(".", dependencies = FALSE)

# Provar
library(Comenta)
run_pdf()
```

### Actualitzar després de Canvis

Quan modifiques fitxers a `inst/`, cal reinstal·lar:

```bash
# Opció 1: Script automàtic (recomanat)
./actualitzar.sh

# Opció 2: Manual
devtools::install(".", dependencies = FALSE)
```

El script `actualitzar.sh`:
- Reinstal·la el paquet
- Reinicia les apps del servidor Shiny automàticament
- Manté tot sincronitzat

### Servidor Shiny

Les apps del directori `/opt/shiny-server/samples/sample-apps/comenta-server/` són "wrappers" que criden el paquet instal·lat. **Sempre usen el paquet instal·lat**, així que:

1. Edita els fitxers a `Comenta/inst/`
2. Executa `./actualitzar.sh`
3. Les apps del servidor i `library(Comenta)` estan sincronitzades ✅

### Estructura de Desenvolupament

```
/opt/shiny-server/samples/sample-apps/
├── Comenta/                    # ← Edita aquí
│   ├── inst/colab/app.R
│   ├── inst/pdf/app.R
│   ├── inst/grafics/app.R
│   ├── inst/public/app.R
│   └── actualitzar.sh          # ← Executa després d'editar
│
└── comenta-server/             # ← NO editis aquí (només wrappers)
    ├── colab/app.R             # Crida library(Comenta); shinyAppDir(...)
    ├── pdf/app.R
    ├── grafics/app.R
    └── public/app.R
```

## Contribuir

Ets benvingut a contribuir al projecte! 

1. Fork el repositori
2. Crea una branca (`git checkout -b feature/nova-funcionalitat`)
3. Commit els canvis (`git commit -am 'Afegir nova funcionalitat'`)
4. Push a la branca (`git push origin feature/nova-funcionalitat`)
5. Obre un Pull Request

## Suport

Per problemes o preguntes:
- 🐛 [Issues](https://github.com/idisba/Comenta/issues)
- 📧 Email: bioinformatica@idisba.es

## Llicència

MIT License - Copyright (c) 2024 IDISBA

## Autors

**IDISBA - Institut d'Investigació Sanitària Illes Balears**
- Equip de Bioinformàtica

---

Desenvolupat amb ❤️ a les Illes Balears 🏝️
