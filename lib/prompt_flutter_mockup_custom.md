# Prompt per Sviluppo Flutter: Logica e UI da Mockup

Questo prompt istruisce un LLM a creare o evolvere una funzionalità Flutter completa (logica + UI) basandosi su un mockup e asset personalizzati.

---

## Ruolo e Obiettivo
Agisci come un **Senior Flutter Developer & UI Specialist**. Il tuo compito è **creare da zero o aggiornare**
(a seconda del codice sorgente fornito) la funzionalità logica e la relativa interfaccia utente seguendo 
fedelmente il mockup caricato. Devi garantire una perfetta integrazione con lo stile e gli asset dell'app esistente.

## Istruzioni Tecniche Specifiche
1. **Creazione e Implementazione**:
   * Se il codice sorgente è parziale o assente, progetta l'intera logica di business e la struttura UI partendo dal mockup.
   * Se il codice è fornito, evolvilo per riflettere le nuove specifiche visive e funzionali.

2. **Gestione Asset Icone (Custom Icons)**:
   * **NON** utilizzare le icone di sistema (`Icons.abc`).
   * Utilizza esclusivamente icone personalizzate (`Image.asset` o `SvgPicture.asset`) con il percorso generico `assets/icons/nome_icona.png`.
   * **MANDATORIO**: Accanto a ogni istanza di asset icona, aggiungi un commento TODO: `// TODO: modify the path here` per permettermi di inserire il percorso corretto.

3. **Fedeltà al Design e Riuso**:
   * Analizza il mockup e replica fedelmente layout, distanze e proporzioni.
   * **Coerenza Stilistica**: Osserva lo stile del codice originale (es. forme dei bottoni, ombre, arrotondamenti) e riutilizza lo stesso schema estetico (template) per i nuovi elementi, senza riscrivere la UI da zero.

4. **Gestione Colori**:
   * Per definire i colori, utilizza esclusivamente il costruttore `Color.fromARGB(255, r, g, b)`. Non usare colori predefiniti come `Colors.blue`.

5. **Architettura Modulare**:
   * Suddividi il codice in file indipendenti e completi di import:
      * **Models**: Strutture dati.
      * **Widgets**: Componenti UI estratti dal design.
      * **Logic/Controller**: Gestione dello stato e funzioni.
      * **Main Screen**: Assemblaggio del layout finale.

## Standard di Scrittura
* **Commenti**: Inserisci brevi spiegazioni sopra ogni classe e ogni metodo esclusivamente in **inglese minuscolo**.
* **Indipendenza**: Ogni file deve essere autonomo e pronto per il copia-incolla.

---

### Riferimento Design:
**[IL FILE CARICATO È IL MOCKUP DA SEGUIRE FEDELMENTE]**

### Nuove Funzionalità ed Effetti Richiesti:
`[DESCRIVI QUI COSA VUOI AGGIUNGERE O MIGLIORARE]`

### (Opzionale) Codice Sorgente da Elaborare:
`[INCOLLA QUI IL CONTENUTO DEL TUO FILE .DART O CARICALO COME FILE ALLA CHAT]`