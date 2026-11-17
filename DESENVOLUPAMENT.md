# Guia de Desenvolupament - Comenta

## 📁 Estructura del Projecte

```
/opt/shiny-server/samples/sample-apps/
│
├── Comenta/                          ← CODI FONT (edita aquí)
│   ├── R/
│   │   ├── run_apps.R               # Funcions per llançar apps
│   │   ├── gemini_helper.R          # Helpers Gemini API
│   │   └── ollama_helper.R          # Helpers Ollama
│   │
│   ├── inst/                        # Apps Shiny (s'instal·len amb el paquet)
│   │   ├── colab/app.R             # App col·laborativa
│   │   ├── pdf/app.R               # App PDFs
│   │   ├── grafics/app.R           # App gràfics
│   │   ├── public/app.R            # App HTMLs
│   │   ├── www/comenta_logo.png    # Logo compartit
│   │   └── python/anotar_pdf.py    # Script PyMuPDF
│   │
│   ├── man/                         # Documentació (generada amb roxygen2)
│   ├── DESCRIPTION                  # Metadades del paquet
│   ├── actualitzar.sh              # Script d'actualització automàtica
│   └── README.md
│
└── comenta-server/                  ← WRAPPERS (NO editis aquí)
    ├── colab/app.R                 # Wrapper → crida library(Comenta)
    ├── pdf/app.R
    ├── grafics/app.R
    └── public/app.R
```

## 🔄 Flux de Treball

### 1. Editar el Codi

**✅ Edita sempre a `Comenta/inst/`:**

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta/inst/pdf
# Editar app.R amb vim, nano, o IDE
vim app.R
```

**❌ NO editis a `comenta-server/`** - són només wrappers que criden el paquet.

### 2. Actualitzar el Paquet

**Opció A: Script automàtic (recomanat)**

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta
./actualitzar.sh
```

Això fa:
1. Reinstal·la el paquet amb els teus canvis
2. Reinicia automàticament les apps del servidor Shiny
3. Manté tot sincronitzat ✅

**Opció B: Manual**

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta

# Reinstal·lar paquet
R -e "devtools::install('.', dependencies = FALSE)"

# Reiniciar apps del servidor
touch /opt/shiny-server/samples/sample-apps/comenta-server/*/restart.txt
```

### 3. Provar els Canvis

**Des de R:**
```r
library(Comenta)
run_pdf()  # O run_colab(), run_grafics(), run_public()
```

**Des del servidor Shiny:**
- http://localhost:3838/shiny/sample-apps/comenta-server/pdf/
- http://localhost:3838/shiny/sample-apps/comenta-server/colab/
- http://localhost:3838/shiny/sample-apps/comenta-server/grafics/
- http://localhost:3838/shiny/sample-apps/comenta-server/public/

**Les dues vies usen el mateix codi del paquet instal·lat!** ✅

## 🎯 Casos d'Ús

### Modificar l'app de PDFs

```bash
# 1. Editar
vim /opt/shiny-server/samples/sample-apps/Comenta/inst/pdf/app.R

# 2. Actualitzar
cd /opt/shiny-server/samples/sample-apps/Comenta
./actualitzar.sh

# 3. Provar des de R
R
> library(Comenta)
> run_pdf()

# 4. O des del servidor
# http://localhost:3838/shiny/sample-apps/comenta-server/pdf/
```

### Afegir una funció helper

```bash
# 1. Crear/editar helper
vim /opt/shiny-server/samples/sample-apps/Comenta/R/nou_helper.R

# 2. Documentar amb roxygen2
#' @export
#' @title Títol de la funció
nova_funcio <- function() { ... }

# 3. Generar documentació
R -e "devtools::document()"

# 4. Actualitzar
./actualitzar.sh
```

### Canviar el logo

```bash
# 1. Reemplaçar logo
cp nou_logo.png /opt/shiny-server/samples/sample-apps/Comenta/inst/www/comenta_logo.png

# 2. Actualitzar
cd /opt/shiny-server/samples/sample-apps/Comenta
./actualitzar.sh

# El logo es copia automàticament a inst/*/www/ durant la instal·lació
```

### Modificar mida del visor

```bash
# 1. Editar height al renderUI
vim /opt/shiny-server/samples/sample-apps/Comenta/inst/pdf/app.R

# Buscar: height = "calc(100vh - 150px)"
# Canviar el valor segons necessitat

# 2. Actualitzar
./actualitzar.sh
```

## 🐛 Depuració

### Veure logs del servidor Shiny

```bash
# Logs generals
tail -f /var/log/shiny-server.log

# Logs de l'app PDF
tail -f /var/log/shiny-server/comenta-server-pdf-*.log
```

### Provar canvis sense reinstal·lar

Per proves ràpides (no persistents):

```r
# Executar directament des del codi font
shiny::runApp("/opt/shiny-server/samples/sample-apps/Comenta/inst/pdf")
```

**Nota:** Això NO carrega `library(Comenta)`, així que les funcions helper no estaran disponibles.

## 📦 Publicar a GitHub

```bash
cd /opt/shiny-server/samples/sample-apps/Comenta

# Inicialitzar git (si no ho està)
git init
git add .
git commit -m "Initial commit"

# Afegir remote i pujar
git remote add origin https://github.com/idisba/Comenta.git
git branch -M main
git push -u origin main
```

Després, els usuaris poden instal·lar amb:

```r
devtools::install_github("idisba/Comenta")
```

## ❓ Preguntes Freqüents

### Per què hi ha dues carpetes (Comenta i comenta-server)?

- **`Comenta/`** és el paquet R amb el codi font
- **`comenta-server/`** són wrappers per Shiny Server que criden el paquet

Els wrappers permeten executar les apps via URL sense haver de llançar R manualment.

### Quan cal executar actualitzar.sh?

**Sempre que modifiquis qualsevol fitxer a `Comenta/`:**
- Apps a `inst/*/app.R`
- Helpers a `R/*.R`
- Scripts Python a `inst/python/`
- Logo a `inst/www/`

### Les apps del servidor i library(Comenta) poden estar dessincronitzades?

**No**, si uses `actualitzar.sh` correctament. Ambdues vies usen el mateix paquet instal·lat.

Si no executés `actualitzar.sh` després d'un canvi:
- ❌ `library(Comenta)` veu el paquet VELL
- ❌ Servidor Shiny també veu el paquet VELL

Després d'executar `actualitzar.sh`:
- ✅ `library(Comenta)` veu el paquet NOU
- ✅ Servidor Shiny veu el paquet NOU

### Com veig quina versió està instal·lada?

```r
packageVersion("Comenta")
# Retorna: '0.1.0'
```

### Com forço reinici d'una app del servidor?

```bash
# Tocar restart.txt
touch /opt/shiny-server/samples/sample-apps/comenta-server/pdf/restart.txt

# O reiniciar el servei sencer
sudo systemctl restart shiny-server
```

## 🚀 Consells

1. **Usa sempre `actualitzar.sh`** després de canvis
2. **Prova primer des de R** (`library(Comenta); run_pdf()`) - més ràpid per iterar
3. **Consulta logs** si hi ha errors al servidor
4. **Documenta amb roxygen2** les noves funcions
5. **Commit sovint** al git local

---

**Desenvolupat per IDISBA Bioinformàtica** 🧬
