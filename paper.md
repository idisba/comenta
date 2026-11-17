---
title: 'Comenta: Collaborative Scientific Document Annotation with AI Support'
tags:
  - R
  - Shiny
  - annotation
  - collaboration
  - artificial intelligence
  - scientific documents
  - bioinformatics
authors:
  - name: Josep Muncunill
    orcid: 0000-0000-0000-0000
    affiliation: 1
affiliations:
  - name: Institut d'Investigació Sanitària Illes Balears (IDISBA), Palma, Spain
    index: 1
date: 17 November 2026
bibliography: paper.bib
---

# Summary

Scientific research increasingly relies on collaborative document review and annotation, yet existing tools often lack integration with modern AI assistants or fail to support diverse document formats. `Comenta` is an R package providing four specialized Shiny applications for annotating PDFs, HTML reports, graphics, and collaborative document review. The package integrates both cloud-based (Google Gemini) and local (Ollama) AI models to assist researchers in interpreting results, analyzing data, and generating summaries. With support for persistent annotations, automatic biomedical term linking, and collaborative workflows using SQLite databases, `Comenta` addresses the growing need for intelligent annotation tools in scientific research.

# Statement of need

Research teams working with scientific documents—including publications, sequencing reports, and data visualizations—require efficient annotation and collaboration tools. While general-purpose annotation software exists (e.g., Hypothesis, Mendeley), these tools typically: (1) lack specialized support for scientific document formats like bioinformatics reports, (2) do not integrate AI-assisted interpretation, and (3) provide limited collaborative features for research teams.

`Comenta` fills this gap by offering domain-specific annotation capabilities tailored to scientific workflows. The package enables researchers to:

- **Annotate PDFs** with persistent sticky notes and automatic summary page generation using PyMuPDF [@pymupdf]
- **Review HTML reports** (e.g., MultiQC, FastQC) with automatic interpretation of tables and figures
- **Mark up graphics** with coordinate-based annotations
- **Collaborate** through shared SQLite databases with user attribution

The integration of AI models (Gemini Flash 2.0 and Ollama) enables automatic interpretation of complex results, statistical analysis suggestions, and context-aware recommendations. Biomedical term detection automatically links to PubMed, NCBI Gene, and UniProt databases, accelerating literature review.

# Implementation

`Comenta` is implemented as an R package using the Shiny [@shiny] framework with bs4Dash [@bs4dash] for the user interface. The package consists of four main applications:

1. **PDF annotation** (`run_pdf()`): Utilizes PyMuPDF via reticulate [@reticulate] for permanent PDF annotations
2. **HTML annotation** (`run_public()`): JavaScript-based interactive annotation with auto-interpretation
3. **Graphics annotation** (`run_grafics()`): PNG image annotation with clickable coordinate markers
4. **Collaborative mode** (`run_colab()`): Multi-user annotation with SQLite database backend

AI integration supports both cloud-based inference (Google Gemini API) and local models (Ollama), giving users control over data privacy. The package includes 36 automated tests using testthat [@testthat] and continuous integration via GitHub Actions.

# Availability

`Comenta` is released under the MIT license and is available at https://github.com/idisba/comenta. Installation requires R ≥4.0.0 and can be performed via:

```r
devtools::install_github("idisba/comenta")
```

PDF annotation functionality requires Python 3 with PyMuPDF. Documentation includes installation guides, usage examples, and a developer guide for contributors.

# Acknowledgments

This work was developed by the Bioinformatics team at Institut d'Investigació Sanitària Illes Balears (IDISBA).

# References
