# 5. Documento finale di descrizione del codice

## Panoramica

Vez e' un'app mobile Flutter per creare, scoprire e gestire eventi reali. Il codice e' organizzato per separare:

- schermate (`lib/screens`), cioe' le pagine visibili all'utente;
- widget riutilizzabili (`lib/views/widgets`), cioe' componenti grafici comuni;
- servizi (`lib/services`), cioe' accesso a database, sessione, notifiche, traduzioni e feedback aptico;
- modelli (`lib/models`), cioe' strutture dati usate dalla UI;
- controller (`lib/controllers`), cioe' logica di caricamento e stato della Home.

L'app usa Flutter/Dart, Supabase tramite REST API, Firebase Messaging per notifiche push, `shared_preferences` per sessione locale, `flutter_map`/`geolocator`/`geocoding` per posizione e mappa, e un design glassmorphism personalizzato.

## Entry point

Il file principale e' `lib/main.dart`.

Responsabilita':

- inizializza Flutter con `WidgetsFlutterBinding.ensureInitialized()`;
- inizializza Firebase;
- inizializza `NotificationService`;
- forza orientamento portrait;
- avvia `MyApp`;
- configura `MaterialApp`, tema scuro, font `InstagramSans`, localizzazioni e schermata iniziale `LoadingPage`.

`MyApp` ascolta `StringRes.localeNotifier`, quindi quando cambia lingua l'app ricostruisce il `MaterialApp` con la nuova `Locale`.

## Autenticazione e sessione

Le schermate di autenticazione sono in `lib/screens/auth`:

- `loading_screen.dart`: controlla se esiste una sessione salvata e decide dove mandare l'utente.
- `account_type_choice_screen.dart`: scelta tra account utente e account locale/venue.
- `login_screen.dart`: accesso con username e password.
- `signup_screen.dart`: registrazione utente normale.
- `venue_signup_screen.dart`: richiesta registrazione locale.
- `venue_pending_screen.dart`: stato dell'account locale in attesa/verifica.

La logica principale e' in `lib/services/auth_service.dart`, classe `RemoteDbService`.

Funzioni chiave:

- `signup`: crea un utente normale in tabella `users`, carica eventuale foto profilo, salva password hashata con SHA-256 + salt.
- `login`: controlla username e hash password su Supabase REST, poi apre sessione locale.
- `signupVenue`: invia richiesta a Edge Function Supabase `submit-venue-signup`.
- `verifyVenueCode`: invia codice a Edge Function `verify-venue-code`.
- `refreshCurrentAccountStatus`: aggiorna stato account dal DB.
- `uploadProfilePhoto`: carica immagine nello storage Supabase `avatars`.
- `logout`: cancella sessione locale.

La sessione e' gestita da `lib/services/user_session.dart`, che mantiene:

- `userID`;
- lingua;
- tipo account (`user` o `venue`);
- stato account (`active`, `pending_verification`, ecc.).

## Traduzioni

Le traduzioni sono in:

- `lib/l10n/en.dart`
- `lib/l10n/it.dart`
- `lib/l10n/de.dart`
- `lib/l10n/fr.dart`
- `lib/l10n/es.dart`
- `lib/l10n/zh.dart`

Il servizio `lib/services/translation_service.dart` espone `StringRes.at(key)`, usato nelle schermate per ottenere stringhe localizzate. La lingua corrente viene salvata per utente e puo' essere cambiata dal profilo.

## Home

La Home e' `lib/screens/home_screen.dart`.

Responsabilita':

- mostra eventi divisi per categorie:
  - invitati;
  - creati dall'utente / gestiti;
  - vicini;
- gestisce ricerca e filtri;
- carica dati tramite `HomeController`;
- apre profilo, creazione evento e notifiche;
- gestisce popup per invitati, co-host e liste ospiti;
- aggiorna automaticamente gli eventi ogni 60 secondi;
- mostra il tutorial iniziale tramite `VezCoachMarks`.

La Home usa:

- `HomeController` per caricare profilo, eventi e nearby;
- `VezPageLayout` per struttura comune pagina;
- `VezEventCard` per le card evento;
- `VezPopup` e popup custom per azioni su ospiti/co-host.

## HomeController

File: `lib/controllers/home_controller.dart`.

Responsabilita':

- centralizza il caricamento dati della Home;
- mantiene stato loading/error;
- carica foto profilo;
- carica eventi invitati, creati, co-host e nearby;
- aggiorna risposte RSVP;
- arricchisce i dati grezzi del DB in modelli usabili dalla UI.

La Home ascolta il controller con `addListener`, cosi' quando i dati cambiano la UI viene aggiornata.

## Modelli dati

### `lib/models/home_event.dart`

Contiene le strutture principali per rappresentare eventi in Home:

- dati evento;
- ruolo utente;
- stato RSVP;
- ospiti;
- contatori ospiti;
- permessi co-host;
- tipologia evento nella UI.

Questi modelli evitano di usare direttamente mappe JSON dentro i widget.

### `lib/models/event_catalog.dart`

Contiene cataloghi statici:

- categorie evento;
- icone categorie;
- tipi evento;
- immagine default.

Serve soprattutto nella schermata di creazione/modifica evento.

## Creazione e modifica evento

Schermata: `lib/screens/create_event/create_event_screen.dart`.

Widget collegati:

- `widgets/event_editor_card.dart`
- `widgets/create_event_bottom_nav.dart`
- `vez_map_picker.dart`

Responsabilita':

- creare nuovo evento;
- modificare evento esistente;
- scegliere immagine di sfondo;
- scegliere categoria;
- scegliere tipo evento (`Exclusive`, `Private`, `Public`);
- inserire titolo, data, ora, luogo, descrizione, massimo ospiti, prezzo;
- scegliere luogo con nome semplice o tramite mappa;
- salvare evento e place nel DB;
- eliminare/modificare evento;
- mostrare tutorial della schermata se aperta dalla sequenza iniziale.

La validazione richiede:

- titolo non vuoto;
- data;
- ora;
- luogo;
- immagine di sfondo non default asset.

La logica dati usa `SetDBService`:

- `storePlace`
- `updatePlace`
- `storeEventAndGetId`
- `updateEvent`
- `deleteEvent`

## Mappa e posizione

File: `lib/screens/create_event/vez_map_picker.dart`.

Responsabilita':

- mostra mappa con `flutter_map`;
- usa coordinate iniziali se presenti;
- permette di scegliere un punto;
- risolve indirizzo/nome luogo quando possibile;
- restituisce a `CreateEvent` nome, indirizzo, latitudine, longitudine e precisione.

Gli eventi con posizione precisa possono apparire nella sezione Nearby.

## Profilo

Schermata: `lib/screens/profile_screen.dart`.

Responsabilita':

- mostra foto profilo, username, citta', bio;
- mostra statistiche followers/following/eventi partecipati;
- mostra eventi passati creati o partecipati;
- apre impostazioni;
- apre popup modifica profilo;
- cambia lingua;
- cambia password;
- elimina account;
- gestisce logout;
- permette navigazione verso Home, Create e Notifications.

Il profilo usa:

- `GetDBService` per leggere dati utente, followers, following ed eventi scaduti;
- `SetDBService` per modificare username, bio, lingua, password, badge e cancellazione account;
- `RemoteDbService` per upload foto profilo e logout.

## Notifiche

Schermata: `lib/screens/notifications_screen.dart`.

Servizio: `lib/services/notification_service.dart`.

Responsabilita':

- inizializzare Firebase Messaging;
- sincronizzare token dispositivo con utente corrente;
- ricevere notifiche push;
- mostrare notifiche locali;
- gestire inviti evento e aggiornamenti RSVP;
- permettere all'utente di rispondere alle notifiche restando nella pagina.

Nel backend sono presenti funzioni Supabase in:

- `supabase/functions/send-event-invite-notification`
- `supabase/functions/submit-venue-signup`
- `supabase/functions/verify-venue-code`

## Servizi database

### `GetDBService`

File: `lib/services/getters_service.dart`.

Legge dati da Supabase REST.

Funzioni principali:

- `getUserData`: legge una singola colonna utente;
- `getFullUserData`: legge dati profilo principali;
- `getFollowersCount`;
- `getFollowing`;
- `getFollowers`;
- `getUsersBasic`;
- `getCreatedEvents`;
- `getEventById`;
- metodi per eventi invitati, nearby, eventi scaduti e arricchimento dati.

Il servizio costruisce query REST con `select`, join e filtri su:

- `users`;
- `events`;
- `place`;
- `event_category`;
- `participation`;
- `event_invites`;
- `follows`.

### `SetDBService`

File: `lib/services/setters_service.dart`.

Scrive, aggiorna o cancella dati.

Funzioni principali:

- `updateUserData`;
- `changePassword`;
- `deleteCurrentUserAccount`;
- `storePlace`;
- `updatePlace`;
- `storeEvent`;
- `storeEventAndGetId`;
- `updateEvent`;
- `deleteEvent`;
- gestione inviti;
- gestione partecipazione RSVP;
- gestione co-host;
- upload e compressione immagini evento.

Il servizio usa richieste `POST`, `PATCH`, `DELETE` verso Supabase REST e storage.

## UI condivisa

I widget riutilizzabili sono in `lib/views/widgets`.

### `vez_page_layout.dart`

Layout globale delle pagine principali.

Divide lo schermo in:

- background;
- corpo centrale;
- blur top/bottom;
- top navbar;
- bottom navbar.

Permette alle schermate di condividere search bar, bottone profilo/settings, bottone filtro/edit e nav inferiore.

### `vez_glass.dart`

Contiene helper visuali per contenitori e campi con effetto vetro/glassmorphism.

### `vez_popup.dart`

Popup generico con sfondo blur e bordo coerente.

### `vez_event_card.dart`

Card eventi della Home.

Gestisce due forme principali:

- card evento creato/gestito dall'utente;
- preview evento invitato/nearby con RSVP.

Mostra immagine, titolo, categoria, tipo, luogo, data, ospiti, prezzo e azioni disponibili in base ai permessi.

### `vez_event_popups.dart`

Popup riutilizzabili per:

- input testo;
- conferme;
- scelta luogo;
- campi evento.

### `vez_coach_marks.dart`

Tutorial in-app con overlay scuro, buco evidenziato e tooltip.

Supporta:

- tutorial Home;
- tutorial Create Event;
- tutorial Profilo.

Il tutorial ritorna `true` se completato e `false` se saltato. La Home usa questo valore per decidere se continuare la sequenza.

## Tutorial iniziale

Il tutorial parte dalla Home se `has_seen_tutorial` e' falso sul profilo utente.

Flusso:

1. Home mostra i coach marks.
2. Se completato, apre `CreateEvent(showTutorial: true)`.
3. Create mostra i suoi coach marks e poi si chiude.
4. Se completato, apre `ProfilePage(showTutorial: true)`.
5. Profile mostra i suoi coach marks e poi si chiude.
6. Viene salvato `has_seen_tutorial = true`.

Se l'utente preme "Salta", la sequenza si ferma.

## Asset e stile

Gli asset sono in `assets`.

Cartelle principali:

- `assets/app_icon`: icona app;
- `assets/images/bg`: sfondi;
- `assets/icons/auth`: icone auth;
- `assets/icons/home_page`: icone Home;
- `assets/icons/nav_bar`: icone navigazione;
- `assets/icons/profile_page`: icone profilo/impostazioni;
- `assets/icons/categories`: icone categorie evento;
- `assets/icons/event`: icone evento;
- `assets/loading_screen`: lettere animazione loading;
- `assets/fonts`: font `InstagramSans` e `JollyLodger`.

Il design usa:

- tema scuro;
- testi bianchi;
- bordi bianchi semi-trasparenti;
- blur;
- card arrotondate;
- icone custom.

## Backend e dati

Il backend e' Supabase/PostgreSQL, usato via:

- REST API;
- storage per immagini;
- Edge Functions per venue signup e notifiche/verifica.

Tabelle/concetti principali:

- `users`: utenti, credenziali hashate, lingua, account type/state, profilo;
- `events`: eventi;
- `place`: luoghi;
- `event_category`: categorie;
- `participation`: stato partecipazione/RSVP;
- `event_invites`: inviti e ruoli evento;
- `follows`: relazioni social;
- storage `avatars`: foto profilo;
- storage/event backgrounds: immagini evento.

## Dipendenze principali

Da `pubspec.yaml`:

- `http`: chiamate REST;
- `crypto`: hashing password;
- `image` e `image_picker`: immagini;
- `liquid_glass_easy`: effetto vetro;
- `geolocator`, `geocoding`, `flutter_map`, `latlong2`: posizione e mappa;
- `connectivity_plus`: stato rete;
- `shared_preferences`: sessione locale;
- `firebase_core`, `firebase_messaging`, `flutter_local_notifications`: notifiche.

## Flussi principali

### Login

1. Utente inserisce username e password.
2. Password viene hashata.
3. `RemoteDbService.login` cerca utente su Supabase.
4. Se valido, `UserSession` salva sessione.
5. Si sincronizza token notifiche.
6. L'app entra nella Home.

### Creazione evento

1. Utente apre Create dalla bottom nav.
2. Compila titolo, data, ora, luogo e immagine.
3. Sceglie categoria e tipo.
4. Opzionalmente aggiunge dettagli, max ospiti, prezzo.
5. Il luogo viene salvato/aggiornato.
6. L'evento viene salvato nel DB.
7. La Home ricarica eventi.

### Invito e RSVP

1. Host/co-host apre popup invitati.
2. Seleziona utenti.
3. Il DB salva inviti.
4. La notifica viene inviata.
5. L'invitato risponde con Going, Not Going o Maybe.
6. La card e i contatori si aggiornano.

### Profilo

1. L'utente apre il profilo.
2. Vengono caricati dati personali e statistiche.
3. L'utente puo' modificare dati, lingua, password o foto.
4. Le modifiche vengono salvate via `SetDBService`.

## Note tecniche

- Molta UI e' stateful per gestire popup, campi, filtri e caricamenti.
- Le chiamate DB sono asincrone e usano `Future`.
- I servizi restituiscono spesso status code HTTP per decidere il messaggio UI.
- La Home ricarica automaticamente ogni 60 secondi solo se la route e' corrente.
- I permessi evento determinano quali azioni appaiono sulle card.
- La UI usa `mounted` prima di aggiornare stato dopo chiamate asincrone.

## Possibili miglioramenti futuri

- Ridurre duplicazione delle bottom nav tra schermate.
- Tipizzare ulteriormente le risposte DB invece di usare mappe dinamiche in alcuni punti.
- Centralizzare logging e gestione errori.
- Rimuovere `print` da produzione.
- Migliorare test automatici su servizi e controller.
- Completare social groups, deadline RSVP, changelog eventi e deep link mappe.
