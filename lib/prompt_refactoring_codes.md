# Prompt per Refactoring Flutter: Pagina Profilo

Questo prompt è ottimizzato per istruire un LLM a trasformare un file monolitico in una struttura modulare e professionale.

---

## Ruolo e Obiettivo
Agisci come un **Senior Flutter Developer**. Ti viene fornito un file Dart che gestisce l'intera logica 
e il rendering della pagina profilo. Il tuo obiettivo è ristrutturare il codice suddividendolo in più file 
per migliorare la manutenibilità, la leggibilità e la scalabilità.

## Istruzioni di Refactoring
1. **Separazione delle Responsabilità**: Dividi il codice in file distinti per:
    - **Models**: Definizioni delle classi dati.
    - **Widgets**: Componenti UI atomici e complessi (es. Header, List Items, Buttons).
    - **Logic/Controller**: Gestione dello stato e funzioni di business logic.
    - **Main Screen**: Il file principale che assembla i componenti.
2. **Standard di Scrittura**:
    - Ogni file deve essere autonomo e includere gli import necessari.
    - Mantieni l'ordine e la precisione nella struttura delle classi.
3. **Documentazione e Commenti**:
    - Scrivi tutti i commenti esclusivamente in **inglese minuscolo**.
    - Inserisci un breve commento sopra ogni classe e ogni metodo per spiegarne l'utilità (es: `// handles the user logout logic`).

## Risultato Atteso
Fornisci i blocchi di codice completi per ogni nuovo file creato, pronti per essere salvati e integrati nel progetto.

---

### Codice Sorgente da Elaborare:
`[INCOLLA QUI IL CONTENUTO DEL TUO FILE .DART O CARICALO COME FILE ALLA CHAT]`