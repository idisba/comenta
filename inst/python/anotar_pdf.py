#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mòdul per afegir anotacions permanents a PDFs amb PyMuPDF
Compatible amb Adobe Reader i tots els lectors PDF
"""

import fitz  # PyMuPDF
import sys
import json
from datetime import datetime


class AnotadorPDF:
    """Classe per gestionar anotacions en PDFs"""

    def __init__(self, pdf_path):
        """
        Inicialitzar amb un PDF existent

        Args:
            pdf_path (str): Ruta al fitxer PDF
        """
        self.pdf_path = pdf_path
        try:
            self.doc = fitz.open(pdf_path)
        except Exception as e:
            raise Exception(f"❌ No s'ha pogut obrir el PDF: {str(e)}")

        # Verificar si el PDF està encriptat
        if self.doc.is_encrypted:
            self.doc.close()
            raise Exception("❌ El PDF està protegit amb contrasenya. Desencripta'l primer.")

        # Verificar si el document està buit
        if len(self.doc) == 0:
            self.doc.close()
            raise Exception("❌ El PDF no conté cap pàgina.")

        # Verificar si té text extractible
        self.te_text = self._verificar_text()

    def _verificar_text(self):
        """Verificar si el PDF té text extractible"""
        for page in self.doc:
            text = page.get_text().strip()
            if len(text) > 10:  # Si té més de 10 caràcters en alguna pàgina
                return True
        return False

    def afegir_highlight(self, pagina, coords, color=(1, 1, 0), text=""):
        """
        Afegir subratllat/highlight a un rectangle

        Args:
            pagina (int): Número de pàgina (0-indexed)
            coords (tuple): (x0, y0, x1, y1) coordenades del rectangle
            color (tuple): Color RGB normalitzat (0-1)
            text (str): Text del comentari associat
        """
        page = self.doc[pagina]
        rect = fitz.Rect(coords)

        # Crear highlight
        highlight = page.add_highlight_annot(rect)
        highlight.set_colors(stroke=color)

        if text:
            highlight.set_info(content=text)

        highlight.update()
        return highlight

    def afegir_nota(self, pagina, posicio, text, usuari="", icon="Comment"):
        """
        Afegir nota adhesiva (sticky note)

        Args:
            pagina (int): Número de pàgina (0-indexed)
            posicio (tuple): (x, y) posició de la nota
            text (str): Contingut de la nota
            usuari (str): Nom de l'usuari
            icon (str): Tipus d'icona - "Comment", "Note", "Help", "Key", etc.
        """
        page = self.doc[pagina]
        point = fitz.Point(posicio)

        # Crear anotació de text
        annot = page.add_text_annot(point, text, icon=icon)

        # Configurar metadata
        info = {
            "title": usuari if usuari else "Anònim",
            "subject": "Comentari",
            "content": text,
            "creationDate": datetime.now().isoformat()
        }
        annot.set_info(info)

        annot.update()
        return annot

    def afegir_text_lliure(self, pagina, coords, text, font_size=11, color=(0, 0, 0)):
        """
        Afegir text lliure sobre el PDF

        Args:
            pagina (int): Número de pàgina
            coords (tuple): (x0, y0, x1, y1) rectangle on escriure
            text (str): Text a afegir
            font_size (int): Mida de la font
            color (tuple): Color RGB normalitzat
        """
        page = self.doc[pagina]
        rect = fitz.Rect(coords)

        # Crear anotació de text lliure
        annot = page.add_freetext_annot(
            rect,
            text,
            fontsize=font_size,
            text_color=color,
            fill_color=(1, 1, 0.8)  # Fons groc clar
        )
        annot.update()
        return annot

    def afegir_rectangle(self, pagina, coords, color=(1, 0, 0), width=2):
        """
        Afegir un rectangle (marc) al voltant d'un àrea

        Args:
            pagina (int): Número de pàgina
            coords (tuple): (x0, y0, x1, y1) coordenades
            color (tuple): Color RGB normalitzat
            width (float): Amplada de la línia
        """
        page = self.doc[pagina]
        rect = fitz.Rect(coords)

        annot = page.add_rect_annot(rect)
        annot.set_colors(stroke=color)
        annot.set_border(width=width)
        annot.update()
        return annot

    def buscar_text_i_anotar(self, text_a_buscar, comentari, usuari=""):
        """
        Buscar text al PDF i afegir anotació (NOMÉS 1 ANOTACIÓ)

        Args:
            text_a_buscar (str): Text a buscar
            comentari (str): Comentari a afegir
            usuari (str): Nom usuari

        Returns:
            int: Nombre d'anotacions afegides (sempre 0 o 1)
        """
        print(f"🔍 Buscant: '{text_a_buscar[:50]}...'")

        # Advertir si el PDF no té text
        if not self.te_text:
            print("⚠️ ATENCIÓ: Aquest PDF sembla no tenir text extractible")
            return 0

        # Netejar text buscat (treure salts de línia extra, espais múltiples)
        import re
        text_net = re.sub(r'\s+', ' ', text_a_buscar.strip())

        for pagina_num in range(len(self.doc)):
            page = self.doc[pagina_num]

            # Buscar només la primera instància del text
            instances = []
            try:
                # Provar text net (espais normalitzats)
                instances = page.search_for(text_net)

                # Si no troba, provar text original
                if not instances:
                    instances = page.search_for(text_a_buscar)

            except Exception as e:
                print(f"⚠️ Error buscant a pàgina {pagina_num + 1}: {str(e)}")
                continue

            # Si trobem alguna instància, afegir NOMÉS 1 anotació i sortir
            if instances:
                inst = instances[0]  # Primera instància d'aquesta pàgina
                print(f"  → Trobat a pàgina {pagina_num + 1}, {len(instances)} coincidències (usant només la 1a)")

                try:
                    # Highlight groc sobre el text
                    self.afegir_highlight(pagina_num, inst, color=(1, 1, 0))

                    # Postit al marge dret FORA del text
                    page_rect = page.rect
                    x = page_rect.width - 40  # Més lluny del marge
                    y = inst.y0 + 5  # Lleugerament més avall
                    self.afegir_nota(pagina_num, (x, y), comentari, usuari, icon="Note")

                    print(f"✓ 1 anotació afegida")
                    return 1

                except Exception as e:
                    print(f"⚠️ Error: {str(e)}")
                    return 0

        # Si arriba aquí, no s'ha trobat el text en cap pàgina
        print(f"❌ Text NO trobat: '{text_net[:80]}'")
        return 0

    def guardar(self, output_path):
        """
        Guardar PDF amb anotacions

        Args:
            output_path (str): Ruta del fitxer de sortida
        """
        # Si guardem sobre el mateix fitxer, utilitzar incremental
        import os
        is_same_file = os.path.abspath(output_path) == os.path.abspath(self.doc.name)

        if is_same_file:
            self.doc.saveIncr()
        else:
            self.doc.save(output_path, garbage=4, deflate=True, clean=True)

    def extreure_text_pagina(self, pagina):
        """
        Extreure tot el text d'una pàgina específica

        Args:
            pagina (int): Número de pàgina (1-based)

        Returns:
            str: Text de la pàgina
        """
        if pagina < 1 or pagina > len(self.doc):
            raise ValueError(f"Pàgina {pagina} fora de rang (1-{len(self.doc)})")

        page = self.doc[pagina - 1]  # PyMuPDF usa 0-based index
        text = page.get_text()

        return text.strip()

    def afegir_pagina_resum(self, anotacions_list):
        """
        Afegir pàgina final amb resum d'anotacions

        Args:
            anotacions_list (list): Llista d'anotacions (dicts amb text, comentari, usuari)
        """
        print(f"🔵 Iniciant afegir_pagina_resum amb {len(anotacions_list)} anotacions")

        if not anotacions_list or len(anotacions_list) == 0:
            print("⚠️ No hi ha anotacions per afegir")
            return

        try:
            # Crear nova pàgina al final
            print(f"📄 Creant nova pàgina (actual: {len(self.doc)} pàgines)")
            page = self.doc.new_page(width=595, height=842)  # A4
            print(f"✓ Pàgina creada (ara: {len(self.doc)} pàgines)")

            y = 60

            # TÍTOL
            page.insert_text(
                fitz.Point(200, y),
                "RESUM D'ANOTACIONS IA",
                fontsize=18,
                color=(0.0, 0.0, 0.8)
            )
            y += 40

            # DATA
            from datetime import datetime
            ara = datetime.now().strftime("%d/%m/%Y %H:%M")
            page.insert_text(
                fitz.Point(230, y),
                f"Generat: {ara}",
                fontsize=10,
                color=(0.5, 0.5, 0.5)
            )
            y += 30

            # LÍNIA
            page.draw_line(fitz.Point(50, y), fitz.Point(545, y), color=(0, 0, 0.8), width=1)
            y += 30

            # ANOTACIONS
            for i, annot in enumerate(anotacions_list, 1):
                text_id = annot.get('text', '')
                comentari = annot.get('comentari', '')
                usuari = annot.get('usuari', 'Anonim')

                # Verificar espai
                if y > 750:
                    page = self.doc.new_page(width=595, height=842)
                    y = 60

                # Número
                page.insert_text(
                    fitz.Point(50, y),
                    f"#{i} - {usuari}",
                    fontsize=11,
                    color=(0, 0, 0.8)
                )
                y += 20

                # Text identificador
                text_net = text_id[:100] + "..." if len(text_id) > 100 else text_id
                text_net = text_net.replace('\n', ' ').replace('\r', ' ')
                page.draw_rect(fitz.Rect(50, y, 545, y + 25), color=(0.9, 0.9, 0.9), fill=(0.9, 0.9, 0.9))
                page.insert_text(
                    fitz.Point(55, y + 15),
                    f"Text: {text_net}",
                    fontsize=8,
                    color=(0, 0, 0)
                )
                y += 30

                # Comentari
                comentari_net = comentari.replace('\n', ' ').replace('\r', ' ')
                if len(comentari_net) > 400:
                    comentari_net = comentari_net[:400] + "..."

                # Dividir en línies
                lines = []
                words = comentari_net.split()
                current_line = ""
                for word in words:
                    test_line = current_line + " " + word if current_line else word
                    if len(test_line) < 80:
                        current_line = test_line
                    else:
                        lines.append(current_line)
                        current_line = word
                if current_line:
                    lines.append(current_line)

                # Limitar a 5 línies
                lines = lines[:5]

                page.insert_text(
                    fitz.Point(55, y + 10),
                    "Comentari:",
                    fontsize=9,
                    color=(0, 0, 0)
                )
                y += 15

                for line in lines:
                    page.insert_text(
                        fitz.Point(55, y + 10),
                        line,
                        fontsize=8,
                        color=(0.2, 0.2, 0.2)
                    )
                    y += 12

                y += 20

                # Separador
                if i < len(anotacions_list):
                    page.draw_line(fitz.Point(50, y), fitz.Point(545, y), color=(0.7, 0.7, 0.7), width=0.5)
                    y += 15

            print(f"✅ Pàgina de resum completada amb {len(anotacions_list)} anotacions")
            print(f"📊 Total pàgines del document: {len(self.doc)}")

        except Exception as e:
            print(f"❌ ERROR en afegir_pagina_resum: {e}")
            import traceback
            traceback.print_exc()

    def tancar(self):
        """Tancar el document"""
        self.doc.close()


def diagnosticar_pdf(pdf_path):
    """
    Diagnosticar un PDF i retornar informació sobre ell

    Args:
        pdf_path (str): Ruta al PDF

    Returns:
        dict: Informació del PDF
    """
    info = {
        "valid": False,
        "error": None,
        "pages": 0,
        "encrypted": False,
        "has_text": False,
        "text_sample": ""
    }

    try:
        doc = fitz.open(pdf_path)

        info["valid"] = True
        info["pages"] = len(doc)
        info["encrypted"] = doc.is_encrypted

        if not doc.is_encrypted and len(doc) > 0:
            # Extreure mostra de text
            for page_num in range(min(3, len(doc))):  # Primeres 3 pàgines
                text = doc[page_num].get_text().strip()
                if len(text) > 50:
                    info["has_text"] = True
                    info["text_sample"] = text[:200]
                    break

        doc.close()

    except Exception as e:
        info["error"] = str(e)

    return info


def extreure_text_pagina_pdf(pdf_path, pagina):
    """
    Extreure tot el text d'una pàgina específica d'un PDF

    Args:
        pdf_path (str): Ruta al fitxer PDF
        pagina (int): Número de pàgina (1-based)

    Returns:
        dict: Diccionari amb 'success', 'text' i 'error' (si n'hi ha)
    """
    result = {
        "success": False,
        "text": "",
        "error": None
    }

    try:
        doc = fitz.open(pdf_path)

        if doc.is_encrypted:
            doc.close()
            result["error"] = "El PDF està protegit amb contrasenya"
            return result

        if pagina < 1 or pagina > len(doc):
            doc.close()
            result["error"] = f"Pàgina {pagina} fora de rang (1-{len(doc)})"
            return result

        page = doc[pagina - 1]  # PyMuPDF usa 0-based index
        text = page.get_text()

        doc.close()

        result["success"] = True
        result["text"] = text.strip()
        result["num_chars"] = len(text.strip())

    except Exception as e:
        result["error"] = str(e)

    return result


def processar_anotacions_json(pdf_input, json_anotacions, pdf_output):
    """
    Processar anotacions des d'un JSON i crear PDF anotat

    Args:
        pdf_input (str): PDF original
        json_anotacions (str): JSON amb les anotacions
        pdf_output (str): PDF amb anotacions
    """
    # Diagnosticar PDF primer
    diag = diagnosticar_pdf(pdf_input)
    if not diag["valid"]:
        raise Exception(f"❌ PDF no vàlid: {diag['error']}")

    if diag["encrypted"]:
        raise Exception("❌ El PDF està protegit amb contrasenya")

    if not diag["has_text"]:
        print("⚠️ ATENCIÓ: Aquest PDF no sembla tenir text extractible")
        print("   Pot ser una imatge escanejada. Les anotacions per text no funcionaran.")

    try:
        anotacions = json.loads(json_anotacions)
    except:
        # Si és un fitxer, llegir-lo
        with open(json_anotacions, 'r', encoding='utf-8') as f:
            anotacions = json.load(f)

    anotar = AnotadorPDF(pdf_input)

    total_anotacions = 0
    for annot in anotacions:
        text = annot.get('text', '')
        comentari = annot.get('comentari', '')
        usuari = annot.get('usuari', 'Anònim')

        # Buscar el text i anotar
        count = anotar.buscar_text_i_anotar(text, comentari, usuari)
        total_anotacions += count
        if count > 0:
            print(f"✅ '{text[:30]}...' → {count} anotacions afegides")
        else:
            print(f"⚠️ '{text[:30]}...' → No s'ha trobat el text")

    # SEMPRE afegir pàgina de resum si hi ha anotacions al JSON
    print(f"\n" + "="*60)
    print(f"📊 RESUM: Total anotacions trobades al PDF: {total_anotacions}")
    print(f"📋 Anotacions al JSON: {len(anotacions)}")

    if total_anotacions == 0:
        print("\n⚠️ No s'ha afegit cap anotació al PDF. Possibles motius:")
        print("   - El text buscat no existeix al PDF")
        print("   - El PDF és una imatge escanejada sense text extractible")
        print("   - El text està en un format no reconegut")

    # AFEGIR PÀGINA DE RESUM SEMPRE (fins i tot si no s'han trobat els textos al PDF)
    if len(anotacions) > 0:
        print(f"\n📄 AFEGINT PÀGINA DE RESUM AMB {len(anotacions)} ANOTACIONS...")
        print(f"   Pàgines abans: {len(anotar.doc)}")
        try:
            anotar.afegir_pagina_resum(anotacions)
            print(f"   Pàgines després: {len(anotar.doc)}")
            print("✅ PÀGINA DE RESUM AFEGIDA CORRECTAMENT")
        except Exception as e:
            print(f"❌ ERROR AFEGINT PÀGINA DE RESUM: {e}")
            import traceback
            traceback.print_exc()
    else:
        print("\n⚠️ No hi ha anotacions al JSON, no s'afegeix pàgina de resum")

    print("\n💾 GUARDANT PDF...")
    print(f"   Ruta: {pdf_output}")
    print(f"   Pàgines totals: {len(anotar.doc)}")
    anotar.guardar(pdf_output)
    anotar.tancar()
    print(f"✅ PDF GUARDAT CORRECTAMENT")
    print("="*60 + "\n")

    return pdf_output


# CLI per usar des de línia de comandes
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Anotar PDFs amb PyMuPDF')
    parser.add_argument('input', help='PDF d\'entrada')
    parser.add_argument('output', help='PDF de sortida')
    parser.add_argument('--json', help='JSON amb anotacions')
    parser.add_argument('--text', help='Text a buscar')
    parser.add_argument('--comentari', help='Comentari a afegir')
    parser.add_argument('--usuari', default='', help='Nom usuari')

    args = parser.parse_args()

    if args.json:
        # Processar des de JSON
        processar_anotacions_json(args.input, args.json, args.output)
        print(f"✅ PDF anotat guardat a: {args.output}")

    elif args.text and args.comentari:
        # Anotar un text específic
        anotar = AnotadorPDF(args.input)
        count = anotar.buscar_text_i_anotar(args.text, args.comentari, args.usuari)
        anotar.guardar(args.output)
        anotar.tancar()
        print(f"✅ {count} anotacions afegides → {args.output}")

    else:
        parser.print_help()
