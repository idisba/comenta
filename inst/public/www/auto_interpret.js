// ============================================================
// Auto-interpretació de taules i gràfics amb IA
// AnotaR - Fase 1: Detecció Intel·ligent
// ============================================================

console.log('📦 auto_interpret.js carregat!');

// Variable global per evitar múltiples inicialitzacions
let autoInterpretInicialitzat = false;

function inicialitzarAutoInterpret() {
  console.log('🤖 ========================================');
  console.log('🤖 INICIALITZANT AUTO-INTERPRETACIÓ');
  console.log('🤖 ========================================');

  let iframe = document.querySelector('iframe');
  if (!iframe) {
    console.warn('⚠️ Iframe no trobat, reintentant en 1 segon...');
    setTimeout(inicialitzarAutoInterpret, 1000);
    return;
  }

  console.log('✅ Iframe trobat!');

  // Si ja està inicialitzat, només reprocessar el document
  if (autoInterpretInicialitzat) {
    console.log('🔄 Ja inicialitzat, reprocessant document...');
    if (typeof window.processarDocumentAutoInterpret === 'function') {
      window.processarDocumentAutoInterpret();
    }
    return;
  }

  autoInterpretInicialitzat = true;

  // Variable per evitar múltiples processaments simultanis
  let processantDocument = false;

  // Funció per processar el document (definir com a variable global per ser accessible)
  window.processarDocumentAutoInterpret = function processarDocument() {
    if (processantDocument) {
      console.log('⏸️ Ja s\'està processant el document, saltant...');
      return;
    }

    processantDocument = true;

    try {
      let doc = iframe.contentDocument || iframe.contentWindow.document;

      if (!doc || !doc.body) {
        console.warn('⚠️ Document iframe encara no està llest');
        processantDocument = false;
        return;
      }

      console.log('✓ Iframe carregat, netejant toolbars antics...');

      // NETEJAR COMPLETAMENT abans d'afegir-ne de nous

      // 1. Netejar wrappers de toolbars
      let wrappersAntics = doc.querySelectorAll('.toolbar-wrapper-anotar');
      if (wrappersAntics.length > 0) {
        console.log('🧹 Netejant', wrappersAntics.length, 'wrappers antics...');
        wrappersAntics.forEach(w => w.remove());
      }

      // 2. Netejar toolbars solts (per si de cas)
      let toolbarsAntics = doc.querySelectorAll('.toolbar-interpret');
      if (toolbarsAntics.length > 0) {
        console.log('🧹 Netejant', toolbarsAntics.length, 'toolbars solts...');
        toolbarsAntics.forEach(t => t.remove());
      }

      // 3. Netejar atributs data-auto-interpret
      let elementsAmbAtribut = doc.querySelectorAll('[data-auto-interpret="true"]');
      if (elementsAmbAtribut.length > 0) {
        console.log('🧹 Netejant', elementsAmbAtribut.length, 'atributs data-auto-interpret...');
        elementsAmbAtribut.forEach(el => el.removeAttribute('data-auto-interpret'));
      }

      // Comprovar si hi ha datatables dinàmiques per esperar més
      let datatableWidgets = doc.querySelectorAll('.datatables.html-widget');
      let tempsEspera = 1500; // Per defecte 1.5s

      if (datatableWidgets.length > 0) {
        console.log('⏳ Detectats', datatableWidgets.length, 'widgets datatables, esperant 3s...');
        tempsEspera = 3000; // Si hi ha datatables, esperar 3s
      } else {
        console.log('⏳ Esperant', tempsEspera, 'ms per renderitzat complet...');
      }

      // ESPERAR que el DOM estigui completament renderitzat (incloent datatables)
      setTimeout(() => {
        console.log('✓ Afegint toolbars després de', tempsEspera, 'ms...');

        try {
          // Afegir toolbars a TOTS els elements
          let elementsProcessats = afegirToolbarATots(doc);
          console.log('✅ Toolbars afegits:', elementsProcessats);

          // Plotly (si la funció existeix)
          if (typeof afegirBotonsAPlotly === 'function') {
            let plotlyProcessats = afegirBotonsAPlotly(doc);
            console.log('✅ Toolbars Plotly:', plotlyProcessats);
          } else {
            console.log('⚠️ afegirBotonsAPlotly no definida, saltant...');
          }

          console.log('🎯 Auto-interpretació activada!');
        } catch (error) {
          console.error('❌ Error afegint toolbars:', error);
        } finally {
          // Alliberar bloqueig
          processantDocument = false;
        }
      }, tempsEspera);

    } catch (e) {
      console.error('Error processant document:', e);
      processantDocument = false;
    }
  }

  // Afegir listener per futurs canvis de document
  iframe.addEventListener('load', window.processarDocumentAutoInterpret);

  // Intentar processar si ja hi ha contingut
  try {
    let doc = iframe.contentDocument || iframe.contentWindow.document;
    if (doc && doc.body && doc.body.children.length > 0) {
      console.log('✓ Document ja carregat, processant...');
      window.processarDocumentAutoInterpret();
    }
  } catch (e) {
    // Si no es pot accedir, esperarem l'event load
    console.log('Esperant event load de l\'iframe...');
  }
}

// ============================================================
// TOOLBARS PER A TOTS ELS ELEMENTS
// ============================================================

function afegirToolbarATots(doc) {
  let comptador = 0;
  let errors = 0;

  // Processar NOMÉS elements dins del contingut principal
  // Buscar contenidor principal (main, article, .content, o body com a fallback)
  let contenidorPrincipal = doc.querySelector('main, article, .content, #quarto-document-content');
  if (!contenidorPrincipal) {
    console.log('⚠️ No s\'ha trobat contenidor principal, usant body');
    contenidorPrincipal = doc.body;
  }

  let selector = 'p, h1, h2, h3, h4, h5, h6, li, table, .datatables.html-widget, .plotly-graph-div, figure, img';
  let elements = contenidorPrincipal.querySelectorAll(selector);
  console.log('📊 Total elements trobats:', elements.length);

  elements.forEach((element, index) => {
    try {
      // Saltar si està dins d'un toolbar (evitar processar toolbars mateixos)
      if (element.closest('.toolbar-interpret')) {
        return;
      }

      // Saltar si ja té toolbar (evitar duplicats)
      if (element.getAttribute('data-auto-interpret') === 'true') {
        return;
      }

      // Saltar elements dins de zones especials (navbar, sidebar, footer, TOC, etc.)
      if (element.closest('nav, .navbar, header, .header, .sidebar, footer, .footer, .toc, #toc, aside, .breadcrumb')) {
        return;
      }

      let tag = element.tagName.toLowerCase();

      // Saltar h1 amb classes especials
      if (tag === 'h1' && (element.classList.contains('title') || element.classList.contains('toc-title'))) {
        return;
      }

      let tipusElement = determinarTipusElement(element);

      // Per GRÀFICS: saltar imatges petites (logos, icons) i imatges dins de figures processades
      if (tipusElement === 'grafic') {
        // Saltar imatges molt petites
        if (tag === 'img') {
          try {
            let bbox = element.getBoundingClientRect();
            if (bbox.width < 100 || bbox.height < 100) {
              return;
            }
          } catch (e) {
            // Si no es pot obtenir bbox, continuar
          }

          // Saltar imatges dins de figure ja processada
          let parentFigure = element.closest('figure');
          if (parentFigure && parentFigure.getAttribute('data-auto-interpret') === 'true') {
            return;
          }
        }
      }

      // Saltar elements massa petits
      if (tipusElement === 'text') {
        let text = element.textContent || element.innerText || '';
        if (text.trim().length === 0) {
          return; // Completament buit
        }
        // Per paràgrafs i llistes: mínim 20 caràcters
        if (['p', 'li'].includes(tag) && text.trim().length < 20) {
          return;
        }
      }

      if (tipusElement === 'taula') {
        let numCells = element.querySelectorAll('td, th').length;
        let classes = element.className || 'sense-classe';

        if (numCells < 2) {
          return;
        }

        // Saltar taules dins de .dataTables_scrollBody (són fragments de datatables)
        if (element.closest('.dataTables_scrollBody')) {
          console.log('  ⏭️ Taula dins de .dataTables_scrollBody saltada (fragment de datatable)');
          return;
        }

        // Saltar taules dins de .dataTables_scrollHead (capçaleres de datatables)
        if (element.closest('.dataTables_scrollHead')) {
          console.log('  ⏭️ Taula dins de .dataTables_scrollHead saltada (capçalera de datatable)');
          return;
        }
      }

      // Comprovar ABANS de modificar l'element si és un header especial
      let esHeader = /^h[1-6]$/i.test(tag);
      if (esHeader) {
        let dentreHeader = element.closest('header, #title-block-header, .navbar, .header');
        if (dentreHeader) {
          console.log('  ⏭️ Header dins de <header> o navbar saltat (layout especial)');
          return;
        }
      }

      // ID únic
      if (!element.id) element.id = 'element-auto-' + tipusElement + '-' + index;

      // Marcar element (però NO canviar position encara)
      element.setAttribute('data-auto-interpret', 'true');

      // Crear toolbar adaptat al tipus (tag ja està declarat abans)
      let toolbar = crearToolbar(tipusElement, element.id, null, tag);

      if (!toolbar) {
        console.error('❌ crearToolbar ha retornat null per', element.id, '(', tipusElement, ')');
        return;
      }

      // Posicionament diferent segons tipus
      if (tipusElement === 'text') {
        // Per TEXT (incloent headers): posar DINS amb position: absolute
        toolbar.style.position = 'absolute';
        toolbar.style.top = '0px';
        toolbar.style.right = '0px';
        toolbar.style.zIndex = '10';

        // Només canviar position si no està ja establert
        try {
          let doc = element.ownerDocument;
          let computedPosition = doc.defaultView.getComputedStyle(element).position;
          if (computedPosition === 'static') {
            element.style.position = 'relative';
          }
        } catch (e) {
          // Si falla, establir position: relative per defecte
          element.style.position = 'relative';
        }

        element.appendChild(toolbar);

      } else if (tipusElement === 'taula') {
        // Per taules: NO modificar position per evitar trencar datatables
        toolbar.style.position = 'absolute';
        toolbar.style.top = '-15px';  // Posició superior per evitar superposicions
        toolbar.style.right = '5px';
        toolbar.style.zIndex = '1050';

        // Comprovar si l'element mateix és un widget de datatable
        let esDatatableWidget = element.classList.contains('datatables') && element.classList.contains('html-widget');

        if (esDatatableWidget) {
          console.log('  📊 Widget DataTable processat directament');

          // Crear wrapper només per al toolbar
          let wrapper = doc.createElement('div');
          wrapper.className = 'toolbar-wrapper-anotar';
          wrapper.style.position = 'relative';
          wrapper.style.height = '0px';  // No ocupa espai
          wrapper.appendChild(toolbar);

          // Inserir ABANS del widget
          if (element.parentNode) {
            element.parentNode.insertBefore(wrapper, element);
          } else {
            console.warn('⚠️ Widget sense parentNode');
            return;
          }

        } else {
          // És una taula <table> normal
          // Buscar si està dins d'un wrapper de datatables
          let datatableWrapper = element.closest('.dataTables_wrapper, .html-widget.datatables');

          if (datatableWrapper) {
            console.log('  📊 Taula dins de DataTable wrapper, posant toolbar al wrapper');

            // Crear wrapper només per al toolbar
            let wrapper = doc.createElement('div');
            wrapper.className = 'toolbar-wrapper-anotar';
            wrapper.style.position = 'relative';
            wrapper.style.height = '0px';  // No ocupa espai
            wrapper.appendChild(toolbar);

            // Inserir ABANS del wrapper de datatables
            if (datatableWrapper.parentNode) {
              datatableWrapper.parentNode.insertBefore(wrapper, datatableWrapper);
            } else {
              console.warn('⚠️ DataTable wrapper sense parentNode');
              return;
            }

          } else {
            // Taula normal (no datatables)
            if (!element.parentNode) {
              console.warn('⚠️ Taula sense parentNode:', element.id);
              return;
            }

            // Crear wrapper només per al toolbar
            let wrapper = doc.createElement('div');
            wrapper.className = 'toolbar-wrapper-anotar';
            wrapper.style.position = 'relative';
            wrapper.style.height = '0px';  // No ocupa espai
            wrapper.appendChild(toolbar);

            // Inserir wrapper ABANS de la taula
            try {
              element.parentNode.insertBefore(wrapper, element);
            } catch (insertError) {
              console.warn('⚠️ No es pot inserir wrapper abans de taula', element.id);
              return;
            }
          }
        }

      } else {
        // Per gràfics i altres: posar dins de l'element
        toolbar.style.position = 'absolute';
        toolbar.style.top = '5px';
        toolbar.style.right = '5px';
        toolbar.style.zIndex = '1050';

        // Per imatges, posar dins d'un wrapper si no té parentNode adequat
        if (element.tagName.toLowerCase() === 'img') {
          // Assegurar que la imatge té position relative al seu container
          if (element.parentNode) {
            element.parentNode.style.position = 'relative';
            element.parentNode.appendChild(toolbar);
          } else {
            console.warn('⚠️ Imatge sense parentNode:', element.src);
            return;
          }
        } else {
          element.style.position = 'relative';
          element.appendChild(toolbar);
        }
      }

      // Mostrar toolbar amb hover (amb timeout per evitar parpadeig)
      let hideTimeout;

      element.addEventListener('mouseenter', () => {
        clearTimeout(hideTimeout);
        toolbar.style.display = 'flex';
      });

      element.addEventListener('mouseleave', (e) => {
        // Si el ratolí es mou cap al toolbar, no ocultar
        if (e.relatedTarget && e.relatedTarget === toolbar) {
          return;
        }
        hideTimeout = setTimeout(() => {
          toolbar.style.display = 'none';
        }, 200);
      });

      // Mantenir toolbar visible quan el ratolí està sobre ell
      toolbar.addEventListener('mouseenter', () => {
        clearTimeout(hideTimeout);
        toolbar.style.display = 'flex';
      });

      toolbar.addEventListener('mouseleave', () => {
        hideTimeout = setTimeout(() => {
          toolbar.style.display = 'none';
        }, 200);
      });

      comptador++;

      // Log de progrés cada 50 elements
      if ((index + 1) % 50 === 0) {
        console.log('   ... processat', index + 1, '/', elements.length, '(', comptador, 'toolbars)');
      }

    } catch (e) {
      errors++;
      console.error('❌ Error processant element', index, '(', element.tagName, '):', e.message);
      if (errors <= 3) {
        // Només mostrar els primers 3 errors per no saturar la consola
        console.error('   Element:', element);
      }
    }
  });

  console.log('✅ Toolbars afegits:', comptador, '/', elements.length, '| Errors:', errors);

  if (comptador === 0 && elements.length > 0) {
    console.error('❌ CAP toolbar creat però hi ha', elements.length, 'elements!');
  }

  return comptador;
}

// Determinar tipus d'element per adaptar toolbar
function determinarTipusElement(element) {
  let tag = element.tagName.toLowerCase();

  // Datatables HTML widgets
  if (element.classList.contains('datatables') && element.classList.contains('html-widget')) {
    return 'taula';
  }

  if (tag === 'table') return 'taula';
  if (tag === 'figure' || tag === 'img' || element.classList.contains('plotly-graph-div')) return 'grafic';
  if (['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li'].includes(tag)) return 'text';

  return 'generic';
}

function extreureDadesTaula(taulaId) {
  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let taula = doc.getElementById(taulaId);

  if (!taula) {
    console.error('Taula no trobada:', taulaId);
    return '';
  }

  let text = "";

  // FIX DATATABLES: Buscar wrapper de DataTables
  let wrapper = taula.closest('.dataTables_wrapper');

  if (wrapper) {
    console.log('📊 DataTable detectada, buscant capçalera i cos...');

    // Capçalera: pot estar a .dataTables_scrollHead o dins de la mateixa taula
    let thead = wrapper.querySelector('.dataTables_scrollHead thead');
    if (!thead) {
      thead = taula.querySelector('thead');
    }

    // Cos: pot estar a .dataTables_scrollBody o dins de la mateixa taula
    let tbody = wrapper.querySelector('.dataTables_scrollBody tbody');
    if (!tbody) {
      tbody = taula.querySelector('tbody');
    }

    // Extreure capçalera
    if (thead) {
      thead.querySelectorAll('tr').forEach(tr => {
        let cells = tr.querySelectorAll('th, td');
        let rowText = [];
        cells.forEach(cell => {
          let cellText = cell.innerText.trim();
          if (cellText) rowText.push(cellText);
        });
        if (rowText.length > 0) {
          text += rowText.join('\t') + '\n';
        }
      });
    }

    // Extreure cos
    if (tbody) {
      tbody.querySelectorAll('tr').forEach(tr => {
        let cells = tr.querySelectorAll('th, td');
        let rowText = [];
        cells.forEach(cell => {
          let cellText = cell.innerText.trim();
          if (cellText) rowText.push(cellText);
        });
        if (rowText.length > 0) {
          text += rowText.join('\t') + '\n';
        }
      });
    }

  } else {
    // Taula normal
    let rows = taula.querySelectorAll('tr');
    rows.forEach((tr, i) => {
      let cells = tr.querySelectorAll('th, td');
      let rowText = [];
      cells.forEach(cell => {
        let cellText = cell.innerText.trim();
        if (cellText) rowText.push(cellText);
      });
      if (rowText.length > 0) {
        text += rowText.join('\t') + '\n';
      }
    });
  }

  return text.trim();
}

function extreureDadesText(elementId) {
  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let element = doc.getElementById(elementId);

  if (!element) {
    console.error('Element no trobat:', elementId);
    return '';
  }

  // Extreure tot el text de l'element
  let text = element.textContent || element.innerText || '';
  return text.trim();
}

function extreureDadesSeccio(titol, tag) {
  let text = "";
  let elementsProcessats = 0;

  // Afegir el títol mateix
  text += titol.textContent.trim() + "\n\n";
  console.log('📑 Títol:', titol.textContent.trim());

  // Determinar el nivell del títol (h1=1, h2=2, etc.)
  let nivellTitol = parseInt(tag.substring(1)); // "h1" -> 1, "h2" -> 2
  console.log('📑 Nivell títol:', nivellTitol, '(', tag, ')');

  // Buscar el contenidor pare (pot ser una section, div, o body)
  let contenidor = titol.parentElement;

  // Recórrer germans següents dins del mateix contenidor
  let nextElement = titol.nextElementSibling;

  console.log('📑 Començant a recórrer germans...');

  while (nextElement) {
    let nextTag = nextElement.tagName.toLowerCase();

    // Si és un títol del mateix nivell o superior, parar
    if (nextTag.match(/^h[1-6]$/)) {
      let nextNivell = parseInt(nextTag.substring(1));
      console.log('   Trobat títol:', nextTag, '(nivell', nextNivell, ')');
      if (nextNivell <= nivellTitol) {
        console.log('   → Parant (mateix nivell o superior)');
        break; // Hem arribat al següent capítol/secció
      }
    }

    // Extreure text de l'element (excloent toolbars)
    if (!nextElement.classList.contains('toolbar-interpret')) {
      let elementText = nextElement.textContent || nextElement.innerText || '';
      if (elementText.trim().length > 0) {
        text += elementText.trim() + "\n\n";
        elementsProcessats++;
      }
    }

    nextElement = nextElement.nextElementSibling;
  }

  console.log('📑 Elements processats:', elementsProcessats);
  console.log('📑 Longitud final:', text.length, 'caràcters');

  return text.trim();
}

// ============================================================
// GRÀFICS ESTÀTICS
// ============================================================

function afegirBotonsAGrafics(doc) {
  let comptador = 0;

  // Detectar figures, imatges i SVGs
  let selectors = [
    'figure',
    'img[src*=".png"]',
    'img[src*=".jpg"]',
    'img[src*=".jpeg"]',
    'img[src*=".svg"]',
    'svg'
  ];

  console.log('📈 Buscant gràfics amb selectors:', selectors.join(', '));

  selectors.forEach(selector => {
    let elements = doc.querySelectorAll(selector);
    console.log('  Selector "' + selector + '":', elements.length, 'elements');

    elements.forEach((element, index) => {
      // Saltar imatges molt petites (logos, icons)
      try {
        let bbox = element.getBoundingClientRect();
        if (bbox.width < 200 || bbox.height < 150) return;
      } catch (e) {
        // Si no es pot obtenir bbox, continuar
      }

      // Saltar si ja està dins d'una figure processada
      if (element.tagName !== 'FIGURE') {
        let parentFigure = element.closest('figure');
        if (parentFigure && parentFigure.id && parentFigure.id.startsWith('grafic-auto-')) {
          return;
        }
      }

      // ID únic
      let graficElement = element;
      if (!graficElement.id) {
        graficElement.id = 'grafic-auto-' + Math.random().toString(36).substr(2, 9);
      }

      // Buscar taula associada
      let taulaAssociada = buscarTaulaAssociada(graficElement);

      // Crear contenidor amb positioning relatiu
      let contenidor = document.createElement('div');
      contenidor.className = 'contenidor-auto-interpret';
      contenidor.style.cssText = 'position: relative; margin: 20px 0; overflow: visible;';

      // Embolcallar el gràfic
      graficElement.parentNode.insertBefore(contenidor, graficElement);
      contenidor.appendChild(graficElement);

      // Crear toolbar
      let toolbar = crearToolbar('grafic', graficElement.id, taulaAssociada);
      contenidor.insertBefore(toolbar, graficElement);

      // Guardar referència a taula si existeix
      if (taulaAssociada) {
        graficElement.setAttribute('data-taula-associada', taulaAssociada);
      }

      // Hover (amb timeout per evitar parpadeig)
      let hideTimeoutGrafic;

      contenidor.addEventListener('mouseenter', () => {
        clearTimeout(hideTimeoutGrafic);
        toolbar.style.display = 'flex';
      });

      contenidor.addEventListener('mouseleave', (e) => {
        // Si el ratolí es mou cap al toolbar, no ocultar
        if (e.relatedTarget && e.relatedTarget === toolbar) {
          return;
        }
        hideTimeoutGrafic = setTimeout(() => {
          toolbar.style.display = 'none';
        }, 200);
      });

      // Mantenir toolbar visible quan el ratolí està sobre ell
      toolbar.addEventListener('mouseenter', () => {
        clearTimeout(hideTimeoutGrafic);
        toolbar.style.display = 'flex';
      });

      toolbar.addEventListener('mouseleave', () => {
        hideTimeoutGrafic = setTimeout(() => {
          toolbar.style.display = 'none';
        }, 200);
      });

      comptador++;
    });
  });

  return comptador;
}

function buscarTaulaAssociada(grafic) {
  // Estratègia 1: Següent germà és una taula
  let nextSibling = grafic.nextElementSibling;
  if (nextSibling && nextSibling.tagName === 'TABLE') {
    return nextSibling.id || assignarId(nextSibling, 'taula-grafic-');
  }

  // Estratègia 2: Taula dins del mateix contenidor
  let parent = grafic.parentElement;
  if (parent) {
    let taula = parent.querySelector('table');
    if (taula && taula !== grafic) {
      return taula.id || assignarId(taula, 'taula-grafic-');
    }
  }

  // Estratègia 3: Taula dins del següent div/section
  if (nextSibling) {
    let taulaInside = nextSibling.querySelector('table');
    if (taulaInside) {
      return taulaInside.id || assignarId(taulaInside, 'taula-grafic-');
    }
  }

  // Estratègia 4: Buscar en els següents 3 germans
  let sibling = grafic.nextElementSibling;
  for (let i = 0; i < 3 && sibling; i++) {
    if (sibling.tagName === 'TABLE') {
      return sibling.id || assignarId(sibling, 'taula-grafic-');
    }
    let taulaInside = sibling.querySelector('table');
    if (taulaInside) {
      return taulaInside.id || assignarId(taulaInside, 'taula-grafic-');
    }
    sibling = sibling.nextElementSibling;
  }

  // No trobada
  return null;
}

function assignarId(element, prefix) {
  let id = prefix + Math.random().toString(36).substr(2, 9);
  element.id = id;
  return id;
}

function extreureCcontextGrafic(grafic) {
  let context = "";

  // Títol del figure
  if (grafic.tagName === 'FIGURE') {
    let caption = grafic.querySelector('figcaption');
    if (caption) context += "Títol: " + caption.innerText.trim() + "\n";
  }

  // Alt text de la imatge
  if (grafic.tagName === 'IMG') {
    if (grafic.alt) context += "Descripció: " + grafic.alt + "\n";
  }

  // Títol anterior (h1-h6)
  let previousElement = grafic.previousElementSibling;
  let attempts = 0;
  while (previousElement && attempts < 5) {
    if (/^H[1-6]$/.test(previousElement.tagName)) {
      context += "Secció: " + previousElement.innerText.trim() + "\n";
      break;
    }
    previousElement = previousElement.previousElementSibling;
    attempts++;
  }

  // Nom del fitxer
  if (grafic.tagName === 'IMG' && grafic.src) {
    let filename = grafic.src.split('/').pop();
    context += "Fitxer: " + filename + "\n";
  }

  return context || "Gràfic sense metadades detectades";
}

// ============================================================
// TOOLBAR
// ============================================================

function crearToolbar(tipus, elementId, taulaAssociada, tag) {
  let toolbar = document.createElement('div');
  toolbar.className = 'toolbar-interpret';
  toolbar.style.cssText = `
    display: none;
    position: absolute;
    top: -40px;
    right: 5px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 6px;
    padding: 6px 10px;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    z-index: 1000;
    gap: 8px;
    align-items: center;
    flex-wrap: nowrap;
    pointer-events: auto;
  `;

  // Label segons tipus
  let labelText = {
    'taula': '📊 Taula',
    'grafic': '📈 Gràfic',
    'text': '📝 Text'
  }[tipus] || '📄 Element';

  let label = document.createElement('span');
  label.style.cssText = 'color: white; font-size: 10px; font-weight: 600; white-space: nowrap;';
  label.innerText = labelText;
  toolbar.appendChild(label);

  // Botons segons tipus d'element
  if (tipus === 'text') {
    // Text: Interpretar, Resumir, Comentar
    toolbar.appendChild(crearBotoToolbar('🔍', 'Interpretar', () => {
      interpretarElement(elementId, tipus, null);
    }));

    toolbar.appendChild(crearBotoToolbar('📝', 'Resumir', () => {
      resumirElement(elementId);
    }));

    // Si és h1 o h2, afegir botons especials
    if (tag === 'h1') {
      // H1: Resumir secció + Resumir tot
      toolbar.appendChild(crearBotoToolbar('📑', 'Resumir secció', () => {
        resumirSeccio(elementId, tag);
      }));

      toolbar.appendChild(crearBotoToolbar('📚', 'Resumir tot el document', () => {
        resumirDocument();
      }));

    } else if (tag === 'h2') {
      // H2: Només resumir secció
      toolbar.appendChild(crearBotoToolbar('📑', 'Resumir secció', () => {
        resumirSeccio(elementId, tag);
      }));
    }

    toolbar.appendChild(crearBotoToolbar('💬', 'Comentar', () => {
      comentarElement(elementId);
    }));

  } else if (tipus === 'taula') {
    // Taula: Interpretar, Analitzar, Recomanar, Comentar
    toolbar.appendChild(crearBotoToolbar('🔍', 'Interpretar', () => {
      interpretarElement(elementId, tipus, null);
    }));

    toolbar.appendChild(crearBotoToolbar('📊', 'Analitzar', () => {
      analitzarElement(elementId, tipus, null);
    }));

    toolbar.appendChild(crearBotoToolbar('💡', 'Recomanar', () => {
      recomanarElement(elementId, tipus, null);
    }));

    toolbar.appendChild(crearBotoToolbar('💬', 'Comentar', () => {
      comentarElement(elementId);
    }));

  } else if (tipus === 'grafic') {
    // Gràfic: Interpretar, Analitzar, Comentar
    toolbar.appendChild(crearBotoToolbar('🔍', 'Interpretar', () => {
      interpretarElement(elementId, tipus, taulaAssociada);
    }));

    toolbar.appendChild(crearBotoToolbar('📊', 'Analitzar', () => {
      analitzarElement(elementId, tipus, taulaAssociada);
    }));

    toolbar.appendChild(crearBotoToolbar('💬', 'Comentar', () => {
      comentarElement(elementId);
    }));
  }

  return toolbar;
}

function crearBotoToolbar(emoji, tooltip, onclick) {
  let btn = document.createElement('button');
  btn.className = 'btn-toolbar-interpret';
  btn.innerHTML = emoji;
  btn.title = tooltip;
  btn.onclick = onclick;
  btn.style.cssText = `
    background: rgba(255,255,255,0.2);
    border: 1px solid rgba(255,255,255,0.3);
    border-radius: 4px;
    color: white;
    cursor: pointer;
    font-size: 14px;
    padding: 4px 8px;
    transition: all 0.2s;
  `;

  btn.onmouseenter = function() {
    this.style.background = 'rgba(255,255,255,0.3)';
    this.style.transform = 'scale(1.1)';
  };

  btn.onmouseleave = function() {
    this.style.background = 'rgba(255,255,255,0.2)';
    this.style.transform = 'scale(1)';
  };

  return btn;
}

// ============================================================
// ACCIONS
// ============================================================

function interpretarElement(elementId, tipus, taulaAssociada) {
  executarAccio(elementId, tipus, 'interpretar', taulaAssociada);
}

function analitzarElement(elementId, tipus, taulaAssociada) {
  executarAccio(elementId, tipus, 'analitzar', taulaAssociada);
}

function recomanarElement(elementId, tipus, taulaAssociada) {
  executarAccio(elementId, tipus, 'recomanar', taulaAssociada);
}

function resumirElement(elementId) {
  executarAccio(elementId, 'text', 'resumir', null);
}

function resumirDocument() {
  console.log('📚 Resumint tot el document...');

  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;

  // Extreure tot el text del body
  let totElText = doc.body.textContent || doc.body.innerText || '';

  console.log('📚 Longitud document complet:', totElText.length, 'caràcters');

  if (totElText.length < 100) {
    alert('⚠️ Document massa curt per resumir');
    return;
  }

  // Limitar a 15000 caràcters per evitar timeouts
  if (totElText.length > 15000) {
    console.warn('⚠️ Document massa llarg (', totElText.length, 'chars), truncant a 15000...');
    totElText = totElText.substring(0, 15000) + '\n\n[...contingut truncat...]';
  }

  // Enviar a Shiny amb acció 'resumir' i tipus especial 'document'
  Shiny.setInputValue('auto_interpretar', {
    element_id: 'document-complet',
    tipus: 'text',
    tipus_dades: 'document',
    dades: totElText,
    accio: 'resumir',
    timestamp: Date.now()
  });

  // Mostrar notificació de loading (no podem usar mostrarLoadingElement perquè no hi ha element específic)
  console.log('📚 Enviant document a la IA...');

  // Crear un indicador de loading global al document
  let loadingGlobal = doc.createElement('div');
  loadingGlobal.id = 'loading-document-complet';
  loadingGlobal.style.cssText = `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(102, 126, 234, 0.95);
    color: white;
    padding: 30px 50px;
    border-radius: 12px;
    font-size: 18px;
    font-weight: 600;
    z-index: 100000;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
  `;
  loadingGlobal.innerHTML = '📚 Resumint document...<br><small style="font-size: 14px; font-weight: 400;">Això pot trigar uns minuts</small>';
  doc.body.appendChild(loadingGlobal);
}

function resumirSeccio(elementId, tag) {
  console.log('📑 Resumint secció:', elementId, '(', tag, ')');

  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let titol = doc.getElementById(elementId);

  if (!titol) {
    console.error('❌ Títol no trobat:', elementId);
    return;
  }

  // Extreure tot el contingut de la secció
  let dadesSeccio = extreureDadesSeccio(titol, tag);

  console.log('📑 Longitud contingut extret:', dadesSeccio.length, 'caràcters');

  if (!dadesSeccio || dadesSeccio.length < 20) {
    alert('⚠️ No s\'ha pogut extreure contingut de la secció (massa curt: ' + dadesSeccio.length + ' chars)');
    console.error('Contingut extret:', dadesSeccio);
    return;
  }

  // Limitar longitud per evitar timeouts (màxim 10000 caràcters)
  if (dadesSeccio.length > 10000) {
    console.warn('⚠️ Secció massa llarga (', dadesSeccio.length, 'chars), truncant a 10000...');
    dadesSeccio = dadesSeccio.substring(0, 10000) + '\n\n[...contingut truncat per longitud...]';
  }

  console.log('📑 Contingut secció:', dadesSeccio.substring(0, 200) + '...');

  // Enviar a Shiny amb acció especial 'resumir'
  Shiny.setInputValue('auto_interpretar', {
    element_id: elementId,
    tipus: 'text',
    tipus_dades: 'seccio',
    dades: dadesSeccio,
    accio: 'resumir',
    timestamp: Date.now()
  });

  mostrarLoadingElement(elementId);
}

function comentarElement(elementId) {
  console.log('💬 Comentant element:', elementId);

  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let element = doc.getElementById(elementId);

  if (!element) {
    console.error('❌ Element no trobat:', elementId);
    return;
  }

  // Simular clic per activar el sistema de comentaris
  let clickEvent = new MouseEvent('click', {
    bubbles: true,
    cancelable: true,
    view: doc.defaultView
  });

  element.dispatchEvent(clickEvent);
  console.log('✅ Clic simulat a l\'element:', elementId);
}

function executarAccio(elementId, tipus, accio, taulaAssociada) {
  let dades, tipusDades;

  if (tipus === 'taula') {
    dades = extreureDadesTaula(elementId);
    tipusDades = 'taula';

    if (!dades || dades.length < 10) {
      alert('⚠️ No s\'han pogut extreure dades de la taula');
      return;
    }

  } else if (tipus === 'text') {
    dades = extreureDadesText(elementId);
    tipusDades = 'text';

    if (!dades || dades.length < 10) {
      alert('⚠️ No s\'han pogut extreure dades del text');
      return;
    }

  } else if (tipus === 'grafic') {
    if (taulaAssociada) {
      // Usar taula associada
      dades = extreureDadesTaula(taulaAssociada);
      tipusDades = 'taula';

      if (!dades || dades.length < 10) {
        console.warn('Taula associada buida, obrint modal de descripció');
        obrirModalDescripcio(elementId, accio);
        return;
      }

    } else {
      // Obrir modal per descriure
      obrirModalDescripcio(elementId, accio);
      return;
    }
  }

  console.log(`Executant ${accio} sobre ${tipus}:`, elementId);

  // Enviar a Shiny
  Shiny.setInputValue('auto_interpretar', {
    element_id: elementId,
    tipus: tipus,
    tipus_dades: tipusDades,
    dades: dades,
    accio: accio,
    timestamp: Date.now()
  });

  mostrarLoadingElement(elementId);
}

// ============================================================
// MODAL PER DESCRIPCIÓ DE GRÀFIC
// ============================================================

function obrirModalDescripcio(graficId, accio) {
  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let grafic = doc.getElementById(graficId);

  // Extreure context
  let context = extreureCcontextGrafic(grafic);

  // Crear modal
  let modal = document.createElement('div');
  modal.id = 'modal-descripcio-grafic';
  modal.style.cssText = `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: white;
    border-radius: 12px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
    padding: 24px;
    max-width: 600px;
    width: 90%;
    z-index: 10000;
  `;

  let titolAccio = accio === 'interpretar' ? 'interpretar-lo' : accio === 'analitzar' ? 'analitzar-lo' : 'generar recomanacions';

  modal.innerHTML = `
    <h3 style="margin-top: 0; color: #667eea;">
      📈 Descriu el gràfic per ${titolAccio}
    </h3>

    <div style="background: #f3f4f6; padding: 12px; border-radius: 6px; margin-bottom: 16px; font-size: 12px; color: #6b7280;">
      <strong>Context detectat:</strong><br>
      ${context.replace(/\n/g, '<br>')}
    </div>

    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: #374151;">
      Descriu el gràfic (valors, tendències, patrons):
    </label>

    <textarea id="descripcio-grafic" style="
      width: 100%;
      height: 150px;
      padding: 12px;
      border: 2px solid #e5e7eb;
      border-radius: 6px;
      font-family: inherit;
      font-size: 14px;
      resize: vertical;
      box-sizing: border-box;
    " placeholder="Exemple per gràfic de barres:
Gràfic expressió 5 gens (qPCR normalitzat a GAPDH)
BRCA1: Control=1.0, Tractament=8.5
TP53: Control=1.0, Tractament=0.15
MYC: Control=1.0, Tractament=6.2
CDK2: Control=1.0, Tractament=0.25
EGFR: Control=1.0, Tractament=1.1"></textarea>

    <div style="margin-top: 16px; display: flex; gap: 12px; justify-content: flex-end;">
      <button onclick="tancarModalDescripcio()" style="
        padding: 10px 20px;
        border: 1px solid #d1d5db;
        background: white;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 600;
        color: #6b7280;
      ">
        ✖ Cancel·lar
      </button>

      <button onclick="enviarDescripcioGrafic('${graficId}', '${accio}')" style="
        padding: 10px 20px;
        border: none;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 600;
      ">
        ${accio === 'interpretar' ? '🔍 Interpretar' : accio === 'analitzar' ? '📊 Analitzar' : '💡 Recomanar'}
      </button>
    </div>
  `;

  // Overlay
  let overlay = document.createElement('div');
  overlay.id = 'overlay-modal-descripcio';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.5);
    z-index: 9999;
  `;
  overlay.onclick = tancarModalDescripcio;

  document.body.appendChild(overlay);
  document.body.appendChild(modal);

  // Focus al textarea
  setTimeout(() => {
    document.getElementById('descripcio-grafic').focus();
  }, 100);
}

function tancarModalDescripcio() {
  let modal = document.getElementById('modal-descripcio-grafic');
  let overlay = document.getElementById('overlay-modal-descripcio');
  if (modal) modal.remove();
  if (overlay) overlay.remove();
}

function enviarDescripcioGrafic(graficId, accio) {
  let descripcio = document.getElementById('descripcio-grafic').value.trim();

  if (descripcio.length < 20) {
    alert('⚠️ Escriu una descripció més detallada (mínim 20 caràcters)');
    return;
  }

  // Tancar modal
  tancarModalDescripcio();

  console.log(`Enviant descripció de gràfic per ${accio}:`, graficId);

  // Enviar a Shiny
  Shiny.setInputValue('auto_interpretar', {
    element_id: graficId,
    tipus: 'grafic',
    tipus_dades: 'grafic',  // Marcar com descripció manual
    dades: descripcio,
    accio: accio,
    timestamp: Date.now()
  });

  mostrarLoadingElement(graficId);
}

// ============================================================
// LOADING I RESULTATS
// ============================================================

function mostrarLoadingElement(elementId) {
  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let element = doc.getElementById(elementId);

  if (!element) {
    console.error('Element no trobat per mostrar loading:', elementId);
    return;
  }

  // Eliminar loading anterior si existeix
  amagarLoadingElement(elementId);

  let loading = document.createElement('div');
  loading.id = 'loading-' + elementId;
  loading.style.cssText = `
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(255,255,255,0.95);
    border-radius: 12px;
    padding: 20px 40px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    z-index: 999;
    text-align: center;
  `;

  loading.innerHTML = `
    <div class="spinner" style="
      border: 3px solid #f3f3f3;
      border-top: 3px solid #667eea;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 0 auto 12px;
    "></div>
    <div style="color: #667eea; font-weight: 600;">Processant amb IA...</div>
  `;

  // Afegir animació spinner
  if (!doc.getElementById('spinner-style')) {
    let style = doc.createElement('style');
    style.id = 'spinner-style';
    style.textContent = `
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    `;
    doc.head.appendChild(style);
  }

  let contenidor = element.closest('.contenidor-auto-interpret');
  if (contenidor) {
    contenidor.appendChild(loading);
  } else {
    element.parentElement.style.position = 'relative';
    element.parentElement.appendChild(loading);
  }
}

function amagarLoadingElement(elementId) {
  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;
  let loading = doc.getElementById('loading-' + elementId);
  if (loading) loading.remove();
}

// Funció global accessible des de Shiny
window.mostrarResultatInterpretacio = function(elementId, resultat, accio) {
  amagarLoadingElement(elementId);

  let iframe = document.querySelector('iframe');
  let doc = iframe.contentDocument || iframe.contentWindow.document;

  // Eliminar modals anteriors
  let modalsAnteriors = doc.querySelectorAll('.modal-resultat-interpret');
  modalsAnteriors.forEach(m => m.remove());

  let modal = document.createElement('div');
  modal.className = 'modal-resultat-interpret';
  modal.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: white;
    border: 2px solid #667eea;
    border-radius: 12px;
    padding: 24px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
    z-index: 99999;
    width: 500px;
    max-height: calc(100vh - 40px);
    overflow-y: auto;
    pointer-events: auto;
  `;

  // Determinar icona i títol segons l'acció
  let iconaAccio, titolAccio;
  switch(accio) {
    case 'interpretar':
      iconaAccio = '🔍';
      titolAccio = 'Interpretació';
      break;
    case 'analitzar':
      iconaAccio = '📊';
      titolAccio = 'Anàlisi';
      break;
    case 'recomanar':
      iconaAccio = '💡';
      titolAccio = 'Recomanacions';
      break;
    case 'resumir':
      iconaAccio = '📝';
      titolAccio = 'Resum';
      break;
    default:
      iconaAccio = '🤖';
      titolAccio = 'Resultat';
  }

  // Escapar resultat per HTML
  let resultatEscapat = resultat.replace(/"/g, '&quot;').replace(/'/g, '&#39;');

  modal.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 2px solid #e5e7eb;">
      <h3 style="margin: 0; color: #667eea; font-size: 20px; font-weight: 700;">
        ${iconaAccio} ${titolAccio} automàtica
      </h3>
      <button onclick="this.parentElement.parentElement.remove()" style="
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #9ca3af;
        padding: 0;
        line-height: 1;
      ">✖</button>
    </div>

    <div style="
      background: #f9fafb;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 20px;
      max-height: 60vh;
      overflow-y: auto;
      line-height: 1.7;
      color: #374151;
      font-size: 15px;
    ">
      ${resultat}
    </div>

    <div style="display: flex; gap: 15px; justify-content: space-between; align-items: center;">
      <button class="btn-tancar-modal" style="
        padding: 10px 20px;
        background: #f3f4f6;
        border: 1px solid #d1d5db;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 600;
        color: #6b7280;
        font-size: 14px;
      ">
        ✖ Tancar
      </button>

      <div style="display: flex; gap: 15px;">
        <button class="btn-copiar-resultat" data-resultat="${resultatEscapat}" style="
          padding: 10px 20px;
          background: white;
          border: 1px solid #d1d5db;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 600;
          color: #6b7280;
          font-size: 14px;
        ">
          📋 Copiar
        </button>

        <button class="btn-afegir-resultat" data-resultat="${resultatEscapat}" data-element-id="${elementId}" style="
          padding: 10px 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 600;
          font-size: 14px;
        ">
          ➕ Afegir com anotació
        </button>
      </div>
    </div>
  `;

  // Crear overlay fosc
  let overlay = doc.createElement('div');
  overlay.className = 'overlay-modal-resultat';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0,0,0,0.5);
    z-index: 99998;
    pointer-events: auto;
  `;

  console.log('🎨 Creant overlay i modal');

  // Afegir al body del document iframe PRIMER
  doc.body.appendChild(overlay);
  doc.body.appendChild(modal);
  console.log('✅ Modal i overlay afegits al DOM');

  // Funció per tancar modal i overlay
  function tancarModal() {
    modal.remove();
    overlay.remove();
  }

  // DESPRÉS assignar event listeners
  // Tancar modal en clicar overlay
  overlay.onclick = tancarModal;

  // Botó X també tanca (buscar per posició al header)
  let btnTancar = modal.querySelector('button');
  if (btnTancar) {
    btnTancar.onclick = tancarModal;
    console.log('✅ Event listener X assignat');
  }

  // Debug: veure tots els botons
  let totsBotons = modal.querySelectorAll('button');
  console.log('🔍 Botons trobats al modal:', totsBotons.length);
  totsBotons.forEach((btn, i) => {
    console.log(`  Botó ${i}: class="${btn.className}", text="${btn.innerText.substring(0, 20)}"`);
  });

  // Botó Copiar
  let btnCopiar = modal.querySelector('.btn-copiar-resultat');
  console.log('🔘 Botó copiar trobat:', !!btnCopiar);
  if (btnCopiar) {
    btnCopiar.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      console.log('📋 Botó copiar clicat!');
      let resultat = this.getAttribute('data-resultat')
        .replace(/<br>/g, '\n')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/<[^>]*>/g, '');

      navigator.clipboard.writeText(resultat).then(() => {
        let textOriginal = this.innerHTML;
        this.innerHTML = '✅ Copiat!';
        this.style.background = '#d1fae5';
        this.style.color = '#065f46';

        setTimeout(() => {
          this.innerHTML = textOriginal;
          this.style.background = 'white';
          this.style.color = '#6b7280';
        }, 2000);
      }).catch(err => {
        console.error('Error copiant:', err);
        alert('Error copiant al portapapers');
      });
    });
    console.log('✅ Event listener copiar assignat');
  }

  // Botó Tancar Modal
  let btnTancarModal = modal.querySelector('.btn-tancar-modal');
  if (btnTancarModal) {
    btnTancarModal.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      console.log('🚪 Tancant modal');
      tancarModal();
    });
    console.log('✅ Event listener tancar modal assignat');
  }

  // Botó Afegir com anotació
  let btnAfegir = modal.querySelector('.btn-afegir-resultat');
  console.log('🔘 Botó afegir trobat:', !!btnAfegir);
  if (btnAfegir) {
    btnAfegir.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      console.log('🎯 BOTÓ AFEGIR CLICAT!');
      let elId = this.getAttribute('data-element-id');
      let resultat = this.getAttribute('data-resultat')
        .replace(/<br>/g, '\n')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/<[^>]*>/g, '');

      console.log('💾 Afegint anotació per element:', elId);
      console.log('📝 Resultat:', resultat.substring(0, 100) + '...');

      // Cas especial: "document-complet" (resumir tot el document)
      let element;
      if (elId === 'document-complet') {
        console.log('📚 Cas especial: Resum de document complet');
        // Buscar el primer h1 per afegir-hi l'anotació
        element = doc.querySelector('h1');
        if (!element) {
          // Si no hi ha h1, buscar qualsevol títol
          element = doc.querySelector('h2, h3, p');
        }
        if (!element) {
          console.error('❌ No s\'ha trobat cap element per afegir l\'anotació del document');
          alert('⚠️ No s\'ha pogut afegir l\'anotació. Prova de copiar-la manualment.');
          tancarModal();
          return;
        }
        console.log('📍 Afegint anotació al primer títol:', element.tagName, element.textContent.substring(0, 50));
      } else {
        // Cas normal: buscar l'element per ID
        element = doc.getElementById(elId);
        if (!element) {
          console.error('❌ Element no trobat:', elId);
          alert('⚠️ No s\'ha pogut afegir l\'anotació. Element no trobat.');
          tancarModal();
          return;
        }
      }

      // Clicar directament l'element (taula, figura, etc.)
      console.log('🖱️ Clicant element:', element.tagName);
      element.click();

      // Esperar i omplir textarea
      setTimeout(() => {
        let textarea = doc.querySelector('.textarea-simple');
        if (textarea) {
          console.log('✅ Textarea trobat, omplint...');
          textarea.value = resultat;
          textarea.focus();
          textarea.dispatchEvent(new Event('input', { bubbles: true }));
          textarea.dispatchEvent(new Event('change', { bubbles: true }));

          // NO tancar el modal automàticament - deixar que l'usuari guardi primer
          console.log('📝 Text afegit al textarea. Clica "Guardar" per desar-lo.');

          // Afegir missatge informatiu al modal
          let missatgeInfo = doc.createElement('div');
          missatgeInfo.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: #10b981;
            color: white;
            padding: 15px 25px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            z-index: 100001;
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
          `;
          missatgeInfo.textContent = '✅ Text afegit! Ara clica "Guardar"';
          doc.body.appendChild(missatgeInfo);

          // Eliminar missatge després de 3 segons
          setTimeout(() => missatgeInfo.remove(), 3000);

        } else {
          console.error('❌ No es troba .textarea-simple');
          alert('⚠️ No s\'ha pogut trobar el camp de comentaris');
          tancarModal();
        }
      }, 500);
    });
    console.log('✅ Event listener afegir assignat');
  } else {
    console.warn('⚠️ Botó afegir NO trobat!');
  }
};

// window.copiarResultat = function(btn) {
//   let resultat = btn.getAttribute('data-resultat')
//     .replace(/<br>/g, '\n')
//     .replace(/&quot;/g, '"')
//     .replace(/&#39;/g, "'")
//     .replace(/<[^>]*>/g, '');  // Eliminar altres tags HTML
// 
//   navigator.clipboard.writeText(resultat).then(() => {
//     let textOriginal = btn.innerHTML;
//     btn.innerHTML = '✅ Copiat!';
//     btn.style.background = '#d1fae5';
//     btn.style.color = '#065f46';
// 
//     setTimeout(() => {
//       btn.innerHTML = textOriginal;
//       btn.style.background = 'white';
//       btn.style.color = '#6b7280';
//     }, 2000);
//   }).catch(err => {
//     console.error('Error copiant:', err);
//     alert('Error copiant al portapapers');
//   });
// };
// 
// window.afegirComAnotacioAuto = function(elementId) {
//   let iframe = document.querySelector('iframe');
//   let doc = iframe.contentDocument || iframe.contentWindow.document;
//   let element = doc.getElementById(elementId);
// 
//   // Buscar modal al document (ara està al body)
//   let modal = doc.querySelector('.modal-resultat-interpret');
//   if (!modal) {
//     console.error('No es troba el modal');
//     return;
//   }
// 
//   // Buscar overlay i tancar-lo també
//   let overlay = doc.querySelector('.overlay-modal-resultat');
//   if (overlay) overlay.remove();
// 
//   let btnAfegir = modal.querySelector('button[onclick*="afegirComAnotacioAuto"]');
//   let resultat = btnAfegir.getAttribute('data-resultat')
//     .replace(/<br>/g, '\n')
//     .replace(/&quot;/g, '"')
//     .replace(/&#39;/g, "'")
//     .replace(/<[^>]*>/g, '');
// 
//   console.log('💾 Resultat a afegir:', resultat.substring(0, 100) + '...');
// 
//   // Tancar modal
//   modal.remove();
// 
//   // Trobar element clickable (td, th per taules, figure per gràfics)
//   let clickableElement;
//   if (element.tagName === 'TABLE') {
//     // Per taules, fer clic a la primera cel·la
//     clickableElement = element.querySelector('td, th');
//     console.log('📊 Clicant primera cel·la de la taula');
//   } else if (element.tagName === 'FIGURE' || element.tagName === 'IMG' || element.tagName === 'SVG') {
//     // Per gràfics, buscar figure parent o usar l'element mateix
//     clickableElement = element.closest('figure') || element;
//     console.log('📈 Clicant gràfic');
//   } else {
//     clickableElement = element;
//   }
// 
//   if (!clickableElement) {
//     console.error('No es troba element clickable');
//     return;

// ============================================================
// INICIALITZAR
// ============================================================

// Cridar quan carrega la pàgina
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', inicialitzarAutoInterpret);
} else {
  inicialitzarAutoInterpret();
}

// Re-inicialitzar si es canvia de document
if (typeof window.parent.Shiny !== 'undefined') {
  Shiny.addCustomMessageHandler('reinicialitzar_auto_interpret', function(message) {
    setTimeout(inicialitzarAutoInterpret, 500);
  });
}
