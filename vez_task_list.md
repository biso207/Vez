# Task List - Vez Improvements - Deadline: May 8th

- [ ] Migliorare e completare la creazione account per locali (pub, bar, ristoranti, etc.)
- [ ] Migliorare il filtro "Nearby"
- [x] Migliorare la scelta del luogo nella creazione eventi e specificare di usare la mappa per mostrare l'evento in "Nearby"
- [x] Completare la UI preview per eventi "Invited" e "Nearby"
- [x] Migliorare i menù popup per aggiungere e gestire gli invitati
- [x] Nella pagina delle notifiche l'utente deve vedere il cambio scelta immediatamente e deve rimanere in quella pagina
- [x] Aggiungere il refresh nella "Home Page" automatico ogni X secondi
- [x] Togliere il pulsante "Add Guests" dalla preview degli eventi pubblici
- [x] Impostare gli eventi "Invited" come i principali nella "Home Page"
- [x] Centrare il pulsante "Delete event" nella modifica evento senza che muova gli altri elementi della pagina
- [x] Migliorare la grafica della preview per gli eventi "By You" seguendo lo stile del mockup
- [x] Migliorare le scritte delle lingue
- [x] Obbligare l'utente a cambiare l'immagine di sfondo nella creazione evento
- [x] Correggere il bug del contatore di lunghezza del titolo alla creazione evento
- [x] Permettere agli invitati di vedere gli altri invitati a un determinato evento
- [x] Aggiungere numero limite ospiti e prezzo nelle card del carousel anche nel gruppo "Yours"
- [x] Migliorare la UI dei popup aumentando il blur e abbassando l'opacità dello sfondo
- [x] Migliorare la UI della pagina profilo
- [x] Il tasto in alto a dx della pagina profilo apre la modifica del profilo, le info del profilo mostrano solo 
      username, città, bio e foto profilo. Al click non fa più nulla.
- [x] Creazione di uno standard in vez_page_layout per rendere i pulsante della top navbar "globali" e più facilmente modificabili
- [x] Migliorare le impostazioni e aggiungere il cambio password nella zona "Utente" delle impostazioni
- [x] Rimuovere il cambio password dalla modifica del profilo e schiarire il bordo dell'immagine profilo
- [x] Aggiungere l'eliminazione del Profilo
- [x] Aggiungere i dati e interazioni tra utenti:
  - [x] follow/follow_back/unfollow di un utente
  - [x] sblocco dello stato di "amicizia" al following reciproco
  - [x] conteggio followers, eventi creati, eventi partecipati, numero like ai propri eventi
  - [x] mostrare il profilo di un qualunque utente al click sulla sua foto profilo
- [x] Evento "expired" quando passata la data:
  - [x] mostrato in bacheca
  - [x] sparisce dai carousels (Invites, Yours, Nearby)

## NUOVE FEATURE CORE

- [ ] Implementare i "Circles" per la tipologia "Private"
- [ ] UI gestione Circles (creazione, modifica, aggiunta utenti)
- [ ] Implementare selezione Circles durante creazione evento Private

## Gestione ruoli evento

- [x] Implementare ruolo "Co-Host" (max. 5 per evento)
- [x] Permessi Co-Host:
  - invitare utenti
  - rimuovere invitati
  - vedere lista partecipanti
- [x] Limitare Co-Host (NO modifica evento, NO eliminazione)

## Sistema RSVP e Deadline

- [ ] Implementare "Deadline risposta" (Ora X)
- [ ] Calcolo automatico deadline basato su distanza evento
- [ ] Possibilità override manuale da parte dell’Host
- [ ] Gestione stato "Maybe" alla scadenza
- [ ] UI countdown deadline evento

## Sistema modifiche evento

- [ ] Distinzione modifiche critiche / non critiche
- [ ] Implementare "Soft Lock"

## Modifiche last-minute

- [ ] Consentire override modifiche dopo deadline
- [ ] Popup warning Host
- [ ] Notifica immediata modifiche critiche
- [ ] Notifiche specifiche (luogo, orario, prezzo)

## Reazione utenti

- [ ] Reset stato utenti su modifiche critiche
- [ ] Bottone riconferma partecipazione
- [ ] Highlight modifiche

## Trasparenza evento

- [ ] Mostrare "Last Updated"
- [ ] Implementare Change Log
- [ ] Badge UI modifiche

## UX reale

- [ ] Deep link Google Maps
- [ ] Navigazione diretta
- [ ] Migliorare chiarezza RSVP

## Nearby & Discovery

- [ ] Ranking eventi Nearby
- [ ] Filtri avanzati
- [ ] Migliorare ricerca
- [ ] Creare una mappa che mostri tutti gli eventi nella zona cercata

---

# 2nd Task List - Deadline: June 1st

## Sistema achievements

- [ ] Definire sistema
- [ ] Creare lista
- [ ] Assegnazione automatica
- [ ] UI profilo
- [ ] Salvataggio DB

## Verifica presenza

- [ ] Metodo check-in
- [ ] Salvare stato partecipazione
- [ ] Anti-fake
- [ ] Mostrare nel profilo
- [ ] Collegamento achievement

## Sistema reputazione

- [ ] Rating eventi
- [ ] Rating Host
- [ ] Penalità modifiche last-minute
- [ ] Badge Host

## Post-evento

- [ ] Upload foto
- [ ] Timeline eventi
- [ ] Eventi partecipati

## Miglioramento UI
- [ ] Switch Dark/Light Mode
