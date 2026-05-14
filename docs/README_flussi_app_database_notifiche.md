# README - Flussi principali app, database e notifiche

Questo documento spiega i punti principali del funzionamento di Vez: avvio app, sessione locale, login/signup, OTP provvisorio, Supabase, creazione eventi, inviti, notifiche push e differenza tra schermata notifiche e Firebase Messaging.

File principali da tenere aperti:

- `lib/main.dart`
- `lib/UI/loading_screen.dart`
- `lib/services/user_session.dart`
- `lib/services/auth_service.dart`
- `lib/UI/auth/signup/signup_controller.dart`
- `lib/services/getters_service.dart`
- `lib/services/setters_service.dart`
- `lib/services/notification_service.dart`
- `lib/UI/notifications_screen.dart`
- `lib/UI/event_creation/create_event_screen.dart`

## 1. Avvio app

L'app parte da `main.dart`.

Il metodo `main()` fa queste cose, in ordine:

1. Chiama `WidgetsFlutterBinding.ensureInitialized()`, necessario prima di usare plugin Flutter nativi.
2. Inizializza Firebase con `Firebase.initializeApp()`.
3. Inizializza il sistema notifiche con `NotificationService().initialize()`.
4. Blocca l'orientamento in verticale.
5. Avvia `MyApp`, che mostra come prima schermata `LoadingPage`.

Quindi `main.dart` non decide direttamente se mostrare login o home. Prepara i servizi globali e poi delega la scelta iniziale a `LoadingPage`.

## 2. LoadingPage e bootstrap

`LoadingPage` è la schermata di caricamento iniziale.

Nel suo `initState()` chiama `_bootstrapApp()`. Questo metodo:

1. Ripristina la sessione locale con `UserSession().restore()`.
2. Imposta la lingua salvata, se esiste.
3. Sincronizza il token notifiche con `NotificationService().syncTokenForCurrentUser()`.
4. Aggiorna lo stato account dal database con `RemoteDbService().refreshCurrentAccountStatus()`.
5. Esegue l'animazione iniziale.
6. Decide la schermata finale:
   - se `UserSession().isLoggedIn` è vero, apre `HomePage`;
   - altrimenti apre `LoginPage`.

In pratica, la splash non è solo estetica: è anche il punto in cui l'app ricostruisce lo stato dell'utente.

## 3. Sessione locale

La sessione locale è gestita da `UserSession`, un singleton.

Salva e ripristina dati usando `SharedPreferences`, quindi i dati restano disponibili anche dopo la chiusura dell'app.

I valori principali sono:

- `userID`
- `locale`
- `accountType`
- `accountState`

La proprietà più importante è:

```dart
bool get isLoggedIn => userID.isNotEmpty && accountState == 'active';
```

Quindi un utente è considerato loggato solo se:

- esiste uno `userID` salvato;
- lo stato account è `active`.

Quando login o signup vanno a buon fine, il codice chiama:

```dart
UserSession().startSession(...)
```

Quando l'utente fa logout, viene chiamato:

```dart
UserSession().clearSession()
```

Il logout inoltre rimuove il token FCM dal database e dal dispositivo, così l'utente non continua a ricevere notifiche su quell'account.

## 4. Login

Il login è gestito da `RemoteDbService.login()` in `auth_service.dart`.

Il flusso è:

1. L'utente inserisce username e password.
2. La password viene unita a un salt fisso.
3. Il risultato viene hashato con SHA-256.
4. L'app fa una richiesta GET alla tabella `users` di Supabase filtrando per:
   - `username`
   - `hash_psw`
5. Se trova una riga, avvia la sessione locale con i dati dell'utente.
6. Imposta la lingua dell'utente.
7. Sincronizza il token Firebase per le notifiche push.

Importante: qui non viene usato Supabase Auth classico per il login utente. L'app usa una tabella custom `users` e controlla manualmente username e password hashata.

## 5. Signup

Il signup principale passa da `SignupFlowController`.

Il flusso è diviso in step:

1. Foto profilo e nome.
2. Telefono e password.
3. Città e codice OTP.

Durante il signup il controller valida:

- foto profilo obbligatoria;
- nome abbastanza lungo;
- telefono valido;
- password con requisiti minimi;
- città presente;
- codice OTP presente.

Alla fine chiama:

```dart
RemoteDbService().completeSignup(...)
```

`completeSignup()`:

1. Hasha la password.
2. Carica eventuale foto profilo su Supabase Storage.
3. Inserisce l'utente nella tabella `users`.
4. Se l'account è `venue`, crea anche una riga nella tabella `venues`.
5. Avvia la sessione locale.
6. Sincronizza il token notifiche.

## 6. OTP provvisorio

Nel codice attuale l'OTP è provvisorio.

In `signup_controller.dart` ci sono queste due righe importanti:

```dart
static const String _developmentOtpCode = '123456';
static const bool _useSupabasePhoneAuth = false;
```

Questo significa:

- Supabase Phone Auth è già previsto nel codice, ma è disattivato;
- finché `_useSupabasePhoneAuth` resta `false`, l'app accetta solo il codice `123456`;
- non viene mandato un SMS reale.

Quando l'utente passa allo step OTP, `requestOtp()` controlla internet e, se Supabase Phone Auth fosse attivo, chiamerebbe:

```dart
Supabase.instance.client.auth.signInWithOtp(phone: phone)
```

Quando l'utente conferma, `completeSignup()`:

- se Supabase Phone Auth è attivo, verifica il codice con `verifyOTP`;
- se è disattivo, confronta il testo inserito con `123456`.

In breve: l'OTP serve già a simulare il flusso reale, ma per ora è una modalità sviluppo.

## 7. Database Supabase

Supabase viene usato principalmente tramite REST API HTTP.

I service principali sono:

- `RemoteDbService`: login, signup, upload foto profilo, stato account.
- `GetDBService`: lettura dati, utenti, eventi, inviti, notifiche.
- `SetDBService`: scrittura/modifica dati, eventi, inviti, partecipazioni.

Le richieste usano:

- `ApiKeys.baseUrl`
- `ApiKeys.remoteDbKey`
- header `Authorization: Bearer ...`
- header `apikey: ...`

Tabelle usate nei flussi principali:

- `users`: utenti, profilo, lingua, password hashata, tipo account, stato, token FCM.
- `venues`: dati aggiuntivi per account venue.
- `events`: eventi creati.
- `place`: luogo collegato a un evento.
- `event_category`: categorie eventi.
- `event_invites`: inviti agli eventi e ruoli.
- `participation`: partecipazione a eventi pubblici o stati di presenza.
- `follows`: relazioni follow tra utenti.
- `venue_otp_verifications`: tabella prevista per OTP custom, usata in alcuni metodi di `auth_service.dart`.

Supabase Storage viene usato per:

- foto profilo (`avatars`);
- immagini eventi (`backgrounds_events`).

## 8. Creazione eventi

La schermata è `CreateEvent`.

L'utente compila:

- titolo;
- immagine di sfondo;
- categoria;
- tipo evento;
- data;
- ora;
- luogo;
- descrizione;
- massimo partecipanti;
- prezzo.

Un evento è considerato valido da `_isValid` solo se ha almeno:

- titolo;
- data;
- ora;
- luogo;
- immagine non vuota;
- immagine scelta dall'utente o già caricata, non solo asset locale di default.

Quando l'utente salva:

1. Viene creato o aggiornato il luogo nella tabella `place`.
2. Viene costruito il payload evento.
3. Viene cercato il `category_id` partendo dal nome categoria.
4. Se l'immagine è un file locale, viene caricata su Supabase Storage.
5. L'evento viene inserito o aggiornato nella tabella `events`.

I metodi più importanti sono:

- `_saveEvent()` in `create_event_screen.dart`;
- `storePlace()` in `setters_service.dart`;
- `storeEventAndGetId()` in `setters_service.dart`;
- `updateEvent()` in `setters_service.dart`;
- `_buildEventPayload()` in `setters_service.dart`.

## 9. Inviti

Gli inviti sono salvati nella tabella `event_invites`.

Un invito contiene almeno:

- `event_id`
- `user_id`
- `role`
- `response`
- `invited_at`
- `responded_at`

Il metodo principale è:

```dart
addOrUpdateEventInvite(...)
```

Si trova in `SetDBService`.

Il flusso è:

1. Controlla se esiste già un invito per quella coppia evento/utente.
2. Se esiste, aggiorna ruolo, risposta e data invito.
3. Se non esiste, crea una nuova riga in `event_invites`.
4. Dopo creazione o aggiornamento, chiama una Edge Function Supabase:

```text
send-event-invite-notification
```

Questa funzione serve a inviare una push notification al destinatario dell'invito.

Le risposte possibili vengono normalizzate in:

- `going`
- `maybe`
- `not_going`

Quando l'utente risponde da schermata notifiche o card evento, viene aggiornata la riga in `event_invites`.

## 10. Notifiche push

Le notifiche push sono gestite da `NotificationService`.

Qui entrano in gioco due librerie:

- `firebase_messaging`: riceve notifiche push da Firebase Cloud Messaging.
- `flutter_local_notifications`: mostra una notifica locale quando l'app è aperta in foreground.

All'avvio, `NotificationService().initialize()`:

1. Registra l'handler per i messaggi in background.
2. Crea il canale Android `vez_events`.
3. Configura la visualizzazione notifiche.
4. Ascolta i messaggi foreground con `FirebaseMessaging.onMessage`.
5. Ascolta il refresh del token FCM.

Quando un utente è loggato, `syncTokenForCurrentUser()`:

1. Chiede i permessi notifiche.
2. Ottiene il token FCM del dispositivo.
3. Salva il token nella colonna `fcm_token` della tabella `users`.

Quel token è fondamentale: permette al backend o alla Edge Function di sapere a quale dispositivo inviare la notifica.

Quando l'app riceve una notifica mentre è aperta, `_showForegroundNotification()` usa `flutter_local_notifications` per mostrare comunque una notifica visibile all'utente.

## 11. Schermata notifiche vs Firebase Messaging

Questa distinzione è molto importante.

### Schermata notifiche

La schermata `NotificationsPage` è una pagina interna dell'app.

Non riceve push direttamente. Legge dal database gli inviti dell'utente usando:

```dart
GetDBService.getInviteNotifications()
```

Quindi mostra una lista costruita dalla tabella `event_invites`, includendo dati collegati dell'evento, del luogo e del creator.

Da questa schermata l'utente può:

- vedere gli inviti ricevuti;
- cercare tra le notifiche;
- aprire l'evento;
- aprire il profilo del creator;
- rispondere `going`, `maybe` o `not_going`.

Quando risponde, la UI aggiorna il database con:

```dart
SetDBService.updateEventInviteResponse(...)
```

e aggiorna localmente la card senza dover ricaricare tutta la pagina.

### Firebase Messaging

Firebase Messaging invece è il sistema esterno che consegna notifiche push al dispositivo.

Serve per dire al telefono:

```text
Hai ricevuto un nuovo invito.
```

Firebase Messaging non è la schermata notifiche. È il canale di consegna.

La schermata notifiche è lo storico/interfaccia dentro l'app.

Firebase Messaging è il meccanismo che sveglia o avvisa l'utente fuori dalla schermata.

### Esempio pratico

1. Alessandro invita Luca a un evento.
2. L'app crea o aggiorna una riga in `event_invites`.
3. L'app chiama la Edge Function `send-event-invite-notification`.
4. La funzione usa il token `fcm_token` di Luca per inviare una push.
5. Firebase Messaging consegna la push al telefono di Luca.
6. Luca apre l'app e va nella schermata notifiche.
7. La schermata legge `event_invites` e mostra l'invito.
8. Luca risponde `going`, `maybe` o `not_going`.
9. La risposta viene salvata di nuovo nel database.

## 12. Riassunto mentale veloce

Puoi ricordare il sistema così:

- `main.dart`: prepara Firebase, notifiche e app.
- `LoadingPage`: ripristina sessione e decide home/login.
- `UserSession`: tiene la sessione locale.
- `RemoteDbService`: gestisce login/signup/account.
- `SignupFlowController`: gestisce gli step del signup e l'OTP provvisorio.
- `GetDBService`: legge dati da Supabase.
- `SetDBService`: scrive/modifica dati su Supabase.
- `CreateEvent`: raccoglie dati evento e li salva.
- `event_invites`: è la tabella che rappresenta gli inviti.
- `NotificationService`: gestisce token FCM e notifiche push.
- `NotificationsPage`: mostra gli inviti salvati nel database.

## 13. Nota importante sullo stato attuale

Alcune parti sono già predisposte per una versione più completa, ma oggi funzionano in modalità semplificata:

- OTP reale via Supabase Phone Auth è predisposto ma disattivato.
- Il codice `123456` è il codice OTP di sviluppo.
- La push notification dipende dal token FCM salvato in `users.fcm_token`.
- La schermata notifiche non dipende direttamente da Firebase: dipende dai dati presenti in `event_invites`.
