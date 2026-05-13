# Guida di studio al codice Vez

Questa guida serve per prepararti a spiegare il progetto a un professore. L'obiettivo non e' imparare tutto a memoria, ma capire il flusso dell'app: come parte, come salva l'utente, come comunica con il database, come crea eventi e soprattutto come gestisce le notifiche.

## 1. Idea generale dell'app

Vez e' un'app Flutter per creare, scoprire e gestire eventi reali. Un utente puo' registrarsi, fare login, creare eventi, invitare altri utenti, rispondere agli inviti, vedere eventi vicini e gestire il proprio profilo.

Il progetto e' diviso in alcune aree principali:

- `lib/main.dart`: punto di ingresso dell'app.
- `lib/screens/`: schermate dell'app, come login, home, creazione evento, notifiche e profilo.
- `lib/services/`: servizi riutilizzabili, cioe' classi che gestiscono sessione, database, autenticazione, notifiche e traduzioni.
- `lib/models/`: modelli e cataloghi dati usati dalla UI.
- `lib/views/widgets/`: widget riutilizzabili, per esempio popup, layout, card eventi e componenti glassmorphism.
- `assets/`: immagini, icone, font e risorse visive.

## 2. Avvio dell'app

Il file principale e' `lib/main.dart`.

La funzione `main()` esegue queste operazioni:

1. Chiama `WidgetsFlutterBinding.ensureInitialized()` per poter inizializzare servizi asincroni prima di mostrare la UI.
2. Inizializza Firebase con `Firebase.initializeApp()`.
3. Inizializza il servizio notifiche con `NotificationService().initialize()`.
4. Blocca l'orientamento in verticale con `SystemChrome.setPreferredOrientations`.
5. Avvia l'app con `runApp`.

La classe `MyApp` crea una `MaterialApp` con:

- tema scuro;
- font personalizzato `InstagramSans`;
- localizzazioni Flutter;
- lingue supportate;
- schermata iniziale `LoadingPage`.

Domanda possibile:

**Perche' inizializzi Firebase nel `main()`?**

Perche' Firebase deve essere pronto prima di usare servizi come Firebase Messaging. Se non viene inizializzato, le chiamate alle API Firebase possono fallire.

## 3. Loading e routing iniziale

La schermata `lib/screens/loading_screen.dart` e' la splash screen animata. Non mostra solo il logo: decide anche dove mandare l'utente.

Il metodo `_bootstrapApp()`:

1. recupera la sessione locale con `UserSession().restore()`;
2. imposta la lingua salvata, oppure rileva quella del dispositivo;
3. sincronizza il token notifiche con `NotificationService().syncTokenForCurrentUser()`;
4. aggiorna lo stato account con `RemoteDbService().refreshCurrentAccountStatus()`;
5. avvia l'animazione e poi naviga.

Alla fine decide la destinazione:

- se l'utente non e' loggato, va a `LoginPage`;
- se e' un locale in attesa, va a `VenuePendingPage`;
- altrimenti va a `HomePage`.

Domanda possibile:

**Come fa l'app a sapere se un utente e' gia' loggato?**

Usa `UserSession`, che salva localmente l'id utente con `SharedPreferences`. Se `userID` non e' vuoto, l'utente e' considerato loggato.

## 4. Sessione utente

Il file `lib/services/user_session.dart` contiene la classe `UserSession`.

Questa classe e' un Singleton, cioe' esiste una sola istanza condivisa in tutta l'app. Salva:

- `userID`;
- `profilePic`;
- `locale`;
- `accountType`;
- `accountState`.

I dati importanti vengono salvati con `SharedPreferences`, quindi restano anche dopo la chiusura dell'app.

Metodi importanti:

- `restore()`: legge i dati salvati localmente.
- `startSession(...)`: salva una nuova sessione dopo login/signup.
- `saveLocale(...)`: salva la lingua scelta.
- `clearSession(...)`: cancella la sessione al logout.
- `updateAccountStatus(...)`: aggiorna tipo e stato account.

Domanda possibile:

**Perche' hai usato un Singleton per la sessione?**

Perche' la sessione e' un'informazione globale: molte schermate devono sapere chi e' l'utente corrente. Con un Singleton evito di passare manualmente l'id utente da una schermata all'altra.

## 5. Autenticazione

Il file `lib/services/auth_service.dart` contiene `RemoteDbService`.

Questa classe gestisce:

- registrazione utente;
- login;
- registrazione locali;
- OTP per signup locale;
- upload immagine profilo;
- logout.

La password non viene salvata in chiaro. Prima viene trasformata cosi':

```dart
var bytes = utf8.encode(password + salt);
var digest = sha256.convert(bytes);
String hashedPassword = digest.toString();
```

Quindi nel database viene salvato `hash_psw`, non la password originale.

Domanda possibile:

**Cos'e' un hash?**

Un hash e' una trasformazione a senso unico. Dalla password si ottiene una stringa fissa, ma dalla stringa non si dovrebbe poter ricostruire facilmente la password originale.

Domanda possibile:

**Cos'e' il salt?**

Il salt e' una stringa aggiunta alla password prima dell'hash. Serve a rendere meno prevedibili gli hash, perche' due sistemi diversi con salt diversi generano hash diversi anche partendo dalla stessa password.

Domanda trabocchetto:

**Questo sistema e' sicuro come un sistema professionale di autenticazione?**

No. E' meglio di salvare password in chiaro, pero' in produzione sarebbe preferibile usare un sistema dedicato come Supabase Auth, Firebase Auth o un backend che usa algoritmi specifici per password come bcrypt o Argon2.

## 6. Database: letture e scritture

Il progetto separa le operazioni database in due servizi:

- `GetDBService` in `lib/services/getters_service.dart`;
- `SetDBService` in `lib/services/setters_service.dart`.

`GetDBService` legge dati:

- dati utente;
- profilo completo;
- followers/following;
- eventi creati;
- eventi invitati;
- eventi co-host;
- eventi pubblici;
- notifiche invito;
- eventi scaduti.

`SetDBService` modifica dati:

- aggiorna profilo;
- segue/smette di seguire utenti;
- cambia password;
- elimina account;
- crea/aggiorna luogo;
- crea/aggiorna/elimina evento;
- aggiunge/rimuove inviti;
- aggiorna risposta RSVP;
- salva partecipazione a eventi pubblici.

Domanda possibile:

**Perche' dividere getter e setter?**

Per ordine e manutenzione. Le letture e le scritture hanno responsabilita' diverse. Separandole, le schermate possono usare un servizio chiaro per leggere e uno chiaro per modificare.

## 7. Home e gestione eventi

La home usa due file principali:

- `lib/screens/home/home_screen.dart`;
- `lib/screens/home/home_controller.dart`.

`HomePage` e' la schermata. `HomeController` contiene la logica.

La home mostra tre gruppi:

- `Invited`: eventi a cui l'utente e' invitato;
- `By You`: eventi creati dall'utente;
- `Nearby`: eventi pubblici vicini alla posizione dell'utente.

`HomeController.loadEvents()` carica:

1. eventi creati;
2. eventi dove l'utente e' co-host;
3. eventi invitati;
4. eventi pubblici scopribili.

Poi converte i dati grezzi del database in `HomeEventCardData`, cioe' un modello piu' comodo per disegnare le card.

Domanda possibile:

**Perche' non usi direttamente le mappe JSON nella UI?**

Perche' una classe modello rende il codice piu' leggibile. La UI non deve sapere tutti i nomi delle colonne del database: riceve gia' dati puliti come titolo, immagine, data, luogo, ospiti e stato.

## 8. Eventi nearby

Gli eventi nearby sono eventi pubblici filtrati in base alla distanza.

Il controller:

1. chiede la posizione GPS con `Geolocator`;
2. prende gli eventi pubblici dal database;
3. controlla che il luogo abbia coordinate precise;
4. calcola la distanza;
5. tiene solo quelli entro il raggio selezionato.

La distanza e' calcolata con una formula sferica, usando il raggio terrestre medio:

```dart
const earthRadiusKm = 6371.0;
```

Domanda possibile:

**Perche' devi chiedere i permessi di posizione?**

Perche' il GPS e' un dato sensibile. Android e iOS obbligano l'app a chiedere il consenso prima di leggere la posizione.

## 9. Creazione e modifica evento

Il file principale e' `lib/screens/event_creation/create_event_screen.dart`.

La schermata permette di impostare:

- immagine di sfondo;
- categoria;
- tipo evento;
- titolo;
- data e ora;
- luogo;
- descrizione;
- massimo ospiti;
- prezzo.

La validazione e' nel getter `_isValid`:

```dart
bool get _isValid =>
    _titleController.text.isNotEmpty &&
    _date != null &&
    _time != null &&
    _locationName.isNotEmpty &&
    _bgImage.isNotEmpty &&
    !_bgImage.startsWith('assets/');
```

Questo significa che l'evento e' valido solo se l'utente ha inserito titolo, data, ora, luogo e immagine personalizzata.

Quando salva:

1. salva o aggiorna il luogo nella tabella `place`;
2. costruisce il payload dell'evento;
3. salva o aggiorna la riga nella tabella `events`;
4. torna alla schermata precedente segnalando che qualcosa e' cambiato.

Domanda possibile:

**Perche' salvi prima il luogo e poi l'evento?**

Perche' l'evento contiene un `place_id`. Quindi prima serve creare o aggiornare il luogo, poi posso collegarlo all'evento.

## 10. Inviti, RSVP e co-host

Gli inviti sono gestiti nella tabella `event_invites`.

Un invito contiene informazioni come:

- `event_id`;
- `user_id`;
- `role`;
- `response`;
- `invited_at`;
- `responded_at`.

Gli stati RSVP vengono normalizzati in:

- `going`;
- `maybe`;
- `not_going`.

Questo e' importante perche' nel database potrebbero arrivare valori simili come `accepted`, `yes`, `declined`, `no`. Il codice li trasforma in stati standard.

I co-host sono invitati con ruolo `cohost`. Nel modello `HomeEventRole` un co-host puo':

- invitare utenti;
- rimuovere invitati.

Non puo' modificare o cancellare l'evento, perche' `canEditEvent` e' vero solo per eventi `By You`.

Domanda possibile:

**Che differenza c'e' tra host e co-host?**

L'host e' il creatore dell'evento. Il co-host e' un utente invitato con permessi speciali: puo' aiutare nella gestione degli invitati, ma non puo' modificare o eliminare l'evento.

## 11. Traduzioni

Il file `lib/services/translation_service.dart` gestisce la lingua.

La classe principale e' `StringRes`.

Le traduzioni sono mappe Dart in:

- `lib/l10n/en.dart`;
- `lib/l10n/it.dart`;
- `lib/l10n/de.dart`;
- `lib/l10n/fr.dart`;
- `lib/l10n/es.dart`;
- `lib/l10n/zh.dart`.

Quando serve una stringa, il codice chiama:

```dart
StringRes.at('search')
```

Se la chiave esiste nella lingua corrente, restituisce la traduzione. Se non esiste, restituisce la chiave stessa.

Domanda possibile:

**Come fai ad aggiornare tutta l'app quando cambia lingua?**

`StringRes` usa `LocaleRefreshNotifier`, che estende `ChangeNotifier`. In `main.dart`, la `MaterialApp` e' dentro un `AnimatedBuilder` che ascolta `StringRes.localeNotifier`. Quando la lingua cambia, l'app viene ricostruita.

## 12. Notifiche: panoramica completa

Questa e' una delle parti piu' importanti da saper spiegare.

Nel progetto ci sono due concetti diversi:

1. **notifiche push di sistema**, quelle che arrivano dal sistema operativo anche fuori dall'app;
2. **schermata notifiche interna**, cioe' `NotificationsPage`, che mostra gli inviti ricevuti leggendo il database.

Le notifiche push sono gestite da:

- Firebase;
- Firebase Cloud Messaging;
- `firebase_messaging`;
- `flutter_local_notifications`;
- `NotificationService`.

La schermata interna e' gestita da:

- `lib/screens/notifications_screen.dart`;
- `GetDBService.getInviteNotifications()`;
- `SetDBService.updateEventInviteResponse()`.

## 13. Che cos'e' Firebase Messaging?

Firebase Messaging, piu' precisamente Firebase Cloud Messaging o FCM, e' un servizio di Google che permette di inviare notifiche push a dispositivi Android, iOS e web.

In pratica funziona cosi':

1. l'app si registra presso Firebase;
2. Firebase genera un token univoco per quel dispositivo/installazione;
3. l'app salva quel token nel database;
4. quando il backend vuole mandare una notifica a un utente, recupera il token;
5. il backend chiede a Firebase di inviare la notifica a quel token;
6. il telefono riceve la notifica.

Il token FCM e' come un indirizzo tecnico del dispositivo. Non e' il numero di telefono e non e' l'id utente, ma serve a Firebase per sapere dove consegnare la notifica.

Domanda possibile:

**Firebase Messaging salva le notifiche nel database?**

No. Firebase Messaging consegna notifiche push ai dispositivi. Nel tuo progetto, i dati degli inviti stanno nel database Supabase. Firebase serve solo per avvisare l'utente.

Domanda possibile:

**Perche' serve il token FCM?**

Perche' il backend deve sapere a quale dispositivo inviare la notifica. Il token identifica l'installazione dell'app sul dispositivo.

## 14. Configurazione Firebase nel progetto

Nel file `pubspec.yaml` usi:

- `firebase_core`;
- `firebase_messaging`;
- `flutter_local_notifications`.

Nel file Android `android/app/build.gradle.kts` e' presente:

```kotlin
id("com.google.gms.google-services")
```

Questo plugin permette ad Android di leggere la configurazione Firebase, di solito dal file:

```text
android/app/google-services.json
```

Domanda possibile:

**A cosa serve `google-services.json`?**

Contiene la configurazione del progetto Firebase per Android: project id, app id e altre informazioni necessarie per collegare l'app mobile al progetto Firebase.

## 15. NotificationService

Il file `lib/services/notification_service.dart` contiene tutta la logica principale delle notifiche push.

Anche `NotificationService` e' un Singleton:

```dart
NotificationService._internal();
static final NotificationService _instance = NotificationService._internal();
factory NotificationService() => _instance;
```

Questo evita di creare piu' gestori notifiche contemporaneamente.

### 15.1 Handler in background

All'inizio trovi:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
```

Questo metodo viene chiamato quando arriva una notifica mentre l'app e' in background o terminata. Deve essere una funzione top-level, non un metodo interno a una classe, perche' Firebase deve poterla richiamare separatamente.

Domanda possibile:

**Perche' c'e' `@pragma('vm:entry-point')`?**

Serve a indicare al compilatore che quella funzione deve restare disponibile anche se sembra non usata direttamente dal codice Dart. Firebase puo' chiamarla dall'esterno.

### 15.2 Canale Android

Il servizio crea un canale Android:

```dart
AndroidNotificationChannel(
  'vez_events',
  'Vez events',
  description: 'Inviti e aggiornamenti degli eventi Vez',
  importance: Importance.high,
)
```

Su Android moderno le notifiche devono appartenere a un canale. Il canale definisce importanza, nome e comportamento della notifica.

Domanda possibile:

**Perche' hai creato un AndroidNotificationChannel?**

Perche' Android richiede canali per gestire categorie di notifiche. Qui il canale `vez_events` rappresenta notifiche legate a inviti e aggiornamenti eventi.

### 15.3 initialize()

Il metodo `initialize()` fa queste cose:

1. evita doppia inizializzazione con `_isInitialized`;
2. non fa nulla su web con `kIsWeb`;
3. registra l'handler background;
4. inizializza `flutter_local_notifications`;
5. crea il canale Android;
6. imposta la presentazione delle notifiche in foreground;
7. ascolta notifiche ricevute mentre l'app e' aperta;
8. ascolta il refresh del token FCM.

Punto chiave:

```dart
FirebaseMessaging.onMessage.listen(_showForegroundNotification);
```

Quando l'app e' aperta, Android/iOS spesso non mostrano automaticamente la notifica come banner. Quindi il codice intercetta il messaggio e lo mostra usando `flutter_local_notifications`.

Domanda possibile:

**Perche' usi anche `flutter_local_notifications` se hai gia' Firebase Messaging?**

Firebase Messaging riceve il messaggio push. `flutter_local_notifications` serve a mostrare una notifica locale quando l'app e' aperta in foreground. In questo modo l'utente vede comunque un banner/notifica anche se sta usando l'app.

### 15.4 syncTokenForCurrentUser()

Questo metodo collega dispositivo e utente.

Fa:

1. controlla che non sia web;
2. controlla che l'utente sia loggato;
3. chiede il permesso notifiche;
4. prende il token FCM con `_messaging.getToken()`;
5. salva il token nel database.

Codice chiave:

```dart
final token = await _messaging.getToken();
await _saveTokenForCurrentUser(token);
```

Domanda possibile:

**Quando viene sincronizzato il token?**

All'avvio nella loading page, e anche dopo login/signup. Inoltre `onTokenRefresh` aggiorna il database se Firebase cambia token.

### 15.5 _saveTokenForCurrentUser()

Questo metodo salva il token nel database nella tabella `users`, colonna `fcm_token`.

Fa una richiesta PATCH:

```dart
PATCH /rest/v1/users?user_id=eq.<id>
```

con body:

```json
{
  "fcm_token": "<token>"
}
```

Domanda possibile:

**Perche' salvi il token nel database?**

Perche' quando qualcuno invita un utente, il backend deve sapere il token del destinatario per mandargli una notifica push.

### 15.6 _showForegroundNotification()

Questo metodo viene chiamato quando arriva un messaggio Firebase mentre l'app e' aperta.

Prende:

- `notification.title`;
- `notification.body`;
- `message.data`.

Poi mostra una notifica locale:

```dart
_localNotifications.show(...)
```

Domanda possibile:

**Cosa succede se il messaggio non ha `notification`?**

Il metodo ritorna subito. Questo codice mostra solo messaggi con parte `notification`. Se arrivasse solo un messaggio dati, andrebbe gestito a parte.

## 16. Flusso completo: invito e notifica push

Quando un host invita un utente a un evento, il flusso e' questo:

1. dalla home viene chiamato `addOrUpdateEventInvite(...)`;
2. `SetDBService` controlla se l'invito esiste gia';
3. se esiste lo aggiorna, altrimenti lo crea;
4. imposta `response` a `maybe`;
5. salva `invited_at`;
6. chiama `_sendEventInviteNotification(...)`;
7. questa funzione chiama una Supabase Edge Function:

```text
/functions/v1/send-event-invite-notification
```

8. il backend riceve `event_id`, `invited_user_id`, `inviter_user_id`;
9. il backend puo' recuperare dati evento, host e token FCM dell'invitato;
10. il backend invia la notifica tramite Firebase Cloud Messaging;
11. il dispositivo dell'invitato riceve la push.

Domanda possibile:

**Perche' la notifica push non viene inviata direttamente dall'app Flutter?**

Perche' per inviare notifiche tramite Firebase serve una credenziale server segreta. Se fosse dentro l'app, chiunque potrebbe estrarla. Quindi l'app chiama una funzione backend, e il backend invia la notifica in modo piu' sicuro.

Domanda possibile:

**Qual e' la differenza tra creare un invito e mandare una notifica?**

Creare un invito significa salvare un dato persistente nel database. Mandare una notifica significa avvisare il telefono dell'utente. Anche se la notifica non arrivasse, l'invito resta comunque visibile nella schermata notifiche perche' e' salvato nel database.

## 17. Schermata notifiche interna

Il file `lib/screens/notifications_screen.dart` mostra gli inviti ricevuti.

All'avvio chiama `_loadPageData()`, che carica in parallelo:

```dart
_db.getUserData('profile_photo')
_db.getInviteNotifications()
```

Quindi la pagina mostra:

- foto profilo host;
- titolo evento;
- host;
- data;
- luogo;
- stato RSVP;
- pulsanti going/maybe/not going.

La risposta dell'utente e' gestita da:

```dart
_respondToInvite(String eventId, String responseState)
```

Questo metodo:

1. evita doppie richieste con `_isResponding`;
2. chiama `SetDBService.updateEventInviteResponse`;
3. se va bene, aggiorna localmente la lista `_notifications`;
4. non fa uscire l'utente dalla pagina.

Domanda possibile:

**Perche' aggiorni la lista localmente invece di ricaricare tutta la pagina?**

Per rendere la UI piu' immediata. L'utente vede subito il cambio di stato senza aspettare un nuovo caricamento completo.

Domanda possibile:

**La schermata notifiche usa Firebase per leggere gli inviti?**

No. La schermata notifiche legge gli inviti dal database. Firebase serve per ricevere l'avviso push, non per mostrare lo storico degli inviti.

## 18. Differenza tra push notification e notification screen

Questa e' una risposta molto importante da saper dare.

La push notification e' un messaggio inviato al sistema operativo del telefono tramite Firebase Cloud Messaging. Serve ad avvisare l'utente anche se non sta guardando l'app.

La notification screen e' una pagina dell'app che legge gli inviti dal database e permette di rispondere.

Quindi:

- Firebase = consegna l'avviso al dispositivo;
- Supabase/database = conserva i dati reali dell'invito;
- `NotificationsPage` = mostra quei dati e permette interazioni.

## 19. Domande e risposte approfondite sulle notifiche

### Domanda: Che cos'e' Firebase Messaging?

Firebase Cloud Messaging e' un servizio di Google per inviare notifiche push. Ogni installazione dell'app riceve un token. Il backend usa quel token per chiedere a Firebase di consegnare una notifica a quel dispositivo.

### Domanda: Che cos'e' un token FCM?

E' una stringa generata da Firebase che identifica una specifica installazione dell'app su un dispositivo. Nel progetto viene salvata nella colonna `fcm_token` dell'utente.

### Domanda: Il token FCM e' uguale all'id utente?

No. L'id utente identifica l'account nel database. Il token FCM identifica il dispositivo/installazione dell'app. Un utente potrebbe cambiare telefono e quindi avere un token diverso.

### Domanda: Quando viene salvato il token?

Viene salvato quando l'utente e' loggato e viene chiamato `syncTokenForCurrentUser()`. Questo succede all'avvio, dopo login/signup e quando Firebase aggiorna il token.

### Domanda: Perche' Firebase puo' cambiare token?

Per motivi di sicurezza, reinstallazione app, pulizia dati, cambio dispositivo o aggiornamenti interni. Per questo il codice ascolta `onTokenRefresh`.

### Domanda: Cosa succede se l'utente nega il permesso notifiche?

L'app puo' comunque funzionare, ma non ricevera' notifiche push visibili. Gli inviti restano comunque nel database e possono essere visti aprendo la schermata notifiche.

### Domanda: A cosa serve `flutter_local_notifications`?

Serve a mostrare notifiche locali dal dispositivo. Nel progetto viene usato soprattutto quando arriva una notifica mentre l'app e' aperta.

### Domanda: A cosa serve `FirebaseMessaging.onMessage`?

Serve ad ascoltare i messaggi ricevuti mentre l'app e' in foreground, cioe' aperta e visibile.

### Domanda: A cosa serve `FirebaseMessaging.onBackgroundMessage`?

Serve a registrare una funzione che Firebase puo' chiamare quando arriva un messaggio con l'app in background.

### Domanda: Chi invia davvero la notifica?

Non l'app Flutter direttamente. L'app chiama una funzione backend Supabase (`send-event-invite-notification`). La funzione backend dovrebbe usare il token FCM del destinatario e inviare la notifica tramite Firebase.

### Domanda: Perche' non inviare dal client?

Perche' l'invio diretto richiederebbe chiavi server segrete. Metterle nell'app sarebbe insicuro: l'app puo' essere decompilata e le chiavi rubate.

### Domanda: Se la push fallisce, l'invito esiste comunque?

Si'. L'invito viene salvato nel database prima della notifica. Quindi anche se la push non arriva, l'utente puo' vedere l'invito nella pagina notifiche.

### Domanda: Come risponde l'utente a una notifica/invito?

Aprendo la schermata notifiche o la card evento, puo' scegliere `going`, `maybe` o `not_going`. Il codice aggiorna la tabella `event_invites`.

### Domanda: Che differenza c'e' tra `event_invites` e `participation`?

`event_invites` gestisce inviti a eventi non pubblici o eventi dove c'e' una lista invitati. `participation` gestisce la partecipazione a eventi pubblici/discoverable, come quelli nearby.

### Domanda: Cosa migliorerei nelle notifiche?

Si potrebbero aggiungere:

- gestione tap sulla notifica per aprire direttamente l'evento;
- supporto completo a notifiche data-only;
- salvataggio di piu' token per utente se usa piu' dispositivi;
- cancellazione token al logout;
- gestione iOS piu' dettagliata;
- test della funzione backend.

## 20. Domande generali da interrogazione

### Domanda: Qual e' l'architettura generale del progetto?

E' un'app Flutter organizzata per schermate, servizi, modelli e widget riutilizzabili. Le schermate gestiscono la UI, i servizi gestiscono database/sessione/notifiche, i modelli normalizzano i dati e i widget comuni mantengono uno stile coerente.

### Domanda: Perche' usi `StatefulWidget` in molte schermate?

Perche' molte schermate hanno stato locale: caricamento dati, campi input, filtri, popup aperti, risposta RSVP, immagine selezionata, ecc.

### Domanda: Come gestisci gli errori di rete?

Molti metodi usano `try/catch` e ritornano valori neutri come `0`, `null` o lista vuota. La UI poi mostra snackbar o stati vuoti.

### Domanda: Come aggiorni la home automaticamente?

In `HomePage` c'e' un `Timer.periodic` ogni 60 secondi. Se la pagina e' ancora visibile e non sta gia' caricando, richiama `loadEvents()`.

### Domanda: Come eviti memory leak?

Nei `dispose()` vengono chiusi controller, timer, focus node e listener. Per esempio nella home viene cancellato `_autoRefreshTimer` e rimosso il listener dal controller.

### Domanda: Perche' usi `mounted` dopo operazioni async?

Perche' una schermata potrebbe essere stata chiusa mentre una richiesta async era in corso. Controllare `mounted` evita di chiamare `setState` su un widget non piu' presente.

### Domanda: Che cosa sono `Future` e `async/await`?

`Future` rappresenta un risultato disponibile in futuro, per esempio una richiesta HTTP. `async/await` permette di scrivere codice asincrono in modo leggibile, aspettando il risultato senza bloccare l'interfaccia.

### Domanda: Cosa fa `ChangeNotifier`?

Permette a una classe di notificare la UI quando cambia qualcosa. `HomeController` lo usa per dire alla home di ricostruirsi dopo caricamenti o aggiornamenti.

### Domanda: Che ruolo hanno gli asset?

Gli asset contengono icone, immagini, sfondi e font. Sono dichiarati nel `pubspec.yaml` per renderli disponibili all'app.

### Domanda: Quale parte del progetto e' piu' importante da spiegare?

Il flusso completo:

1. avvio app;
2. recupero sessione;
3. login/signup;
4. caricamento home;
5. creazione evento;
6. inviti;
7. notifica push;
8. risposta RSVP;
9. aggiornamento database e UI.

## 21. Domande e risposte approfondite sul funzionamento del progetto

Questa sezione serve per allenarti a rispondere non solo "cosa fa" il codice, ma anche "perche' e' stato fatto cosi'". Le risposte sono pensate per un'interrogazione o una presentazione tecnica.

### Domanda: Cosa fa l'app Vez in una frase?

Vez e' un'app Flutter che permette agli utenti di creare eventi reali, scoprire eventi vicini, invitare altre persone, gestire RSVP e ricevere notifiche push quando vengono invitati.

### Domanda: Qual e' il flusso principale dall'apertura dell'app alla home?

Quando l'app parte, `main.dart` inizializza Firebase, Supabase, notifiche, tema e orientamento verticale. Poi mostra la loading screen. La loading screen recupera la sessione locale, imposta la lingua, sincronizza il token notifiche e decide dove mandare l'utente: login, home, schermata locale in attesa o account bloccato.

### Domanda: Perche' la loading screen non e' solo una schermata estetica?

Perche' contiene il bootstrap dell'app. Mentre l'utente vede l'animazione, il codice controlla sessione, lingua, stato account e token notifiche. Quindi la loading screen nasconde un lavoro tecnico importante prima della navigazione.

### Domanda: Cosa fa `SignupFlowController`?

`SignupFlowController` gestisce la registrazione a step. Tiene i controller dei campi, valida i dati, controlla la pagina corrente, chiede la citta' tramite GPS, gestisce immagine profilo, password, telefono e codice OTP. La UI legge il suo stato e si aggiorna quando il controller chiama `notifyListeners()`.

### Domanda: Perche' la registrazione e' divisa in controller e schermata?

Per separare logica e interfaccia. La schermata disegna campi e bottoni; il controller decide se i dati sono validi, quando andare avanti, quando mostrare errori e quando completare il signup. Questo rende il codice piu' ordinato e piu' facile da modificare.

### Domanda: Come funziona ora l'OTP di registrazione?

In questo momento l'invio SMS reale e' disattivato. Il codice accetta come OTP valido il valore:

```text
123456
```

Questo serve per poter testare e presentare la registrazione senza dipendere da provider SMS, costi o configurazioni esterne.

### Domanda: Il codice OTP reale e' stato cancellato?

No. Nel controller resta la logica Supabase Phone Auth dietro al flag:

```dart
static const bool _useSupabasePhoneAuth = false;
```

Finche' il flag resta `false`, l'app non invia SMS e accetta `123456`. Se in futuro si rimette `true`, il flusso puo' tornare a chiamare `signInWithOtp` e `verifyOTP`.

### Domanda: Perche' hai lasciato il codice Supabase OTP anche se ora usi `123456`?

Perche' e' una scelta temporanea. In fase di sviluppo conviene avere un OTP fisso per testare velocemente signup, UI e database. Pero' lasciare il codice vero rende piu' semplice riattivare la verifica SMS in futuro senza riscrivere tutto.

### Domanda: Perche' `123456` non andrebbe bene in produzione?

Perche' chiunque potrebbe registrarsi fingendo di possedere un numero. Un OTP fisso e' utile solo in sviluppo, demo o test locali. In produzione serve un provider reale che mandi il codice al telefono dell'utente.

### Domanda: Cosa succede quando l'utente inserisce un OTP sbagliato?

Nel metodo `completeSignup()`, se il codice non e' `123456` e l'autenticazione SMS reale e' disattivata, il controller imposta:

```dart
error = StringRes.at('otp_invalid');
```

e ritorna `401`, quindi la registrazione non viene completata.

### Domanda: Perche' anche con OTP fisso serve modificare `RemoteDbService.completeSignup()`?

Perche' prima il completamento signup dipendeva da `Supabase.instance.client.auth.currentUser`. Se non si usa davvero Supabase Phone Auth, quell'utente autenticato potrebbe non esistere. Per questo il servizio ora puo' lasciare generare al database il `user_id` e poi usa l'id restituito dalla risposta.

### Domanda: A cosa serve il flag `_useSupabaseAuthUserId`?

Serve a conservare la possibilita' futura di usare l'id generato da Supabase Auth. Ora e' disattivato:

```dart
static const bool _useSupabaseAuthUserId = false;
```

Quando e' `false`, l'app non pretende che esista un `currentUser` Supabase e usa l'id generato dalla tabella `users`.

### Domanda: Che differenza c'e' tra autenticazione e profilo utente?

L'autenticazione serve a dimostrare chi sei, per esempio con telefono, email o password. Il profilo utente e' invece la riga nel database con username, foto, telefono, citta', lingua, tipo account e stato account. Nel progetto queste due cose sono collegate, ma concettualmente sono diverse.

### Domanda: Perche' la password viene hashata?

Per evitare di salvare la password in chiaro nel database. Il codice unisce password e salt, poi calcola SHA-256. Cosi' nel database finisce una stringa derivata, non la password originale.

### Domanda: Qual e' il limite dell'hash SHA-256 usato per le password?

SHA-256 e' una funzione hash generica, non un algoritmo specifico per password. Per una produzione vera sarebbe meglio usare bcrypt, Argon2 o un servizio auth dedicato. Nel progetto e' comunque meglio che salvare password in chiaro.

### Domanda: Come viene salvata la sessione dopo login o signup?

Dopo login o signup viene chiamato `UserSession().startSession(...)`. Questo metodo salva in memoria e in `SharedPreferences` informazioni come `userID`, lingua, tipo account e stato account. Alla prossima apertura, `restore()` recupera questi dati.

### Domanda: Perche' usi `SharedPreferences`?

Per salvare piccoli dati locali persistenti, come id sessione e lingua. Non e' pensato per grandi quantita' di dati, ma e' adatto a preferenze e stato login semplice.

### Domanda: Cosa significa `accountState`?

Indica lo stato dell'account. Per esempio un utente normale puo' essere `active`, mentre un locale puo' essere `pending_verification` finche' non completa la verifica. La loading screen usa questo valore per decidere quale schermata mostrare.

### Domanda: Perche' ci sono account utente e account locale?

Perche' hanno ruoli diversi. Un utente partecipa principalmente agli eventi. Un locale puo' promuovere eventi e ha bisogno di una verifica aggiuntiva, quindi puo' partire in stato `pending_verification`.

### Domanda: Come funziona la verifica del locale?

Il locale viene registrato con uno stato iniziale di verifica non completata. Poi il codice di verifica viene controllato tramite una Supabase Edge Function, ad esempio `verify-venue-code`. Questa separazione permette di tenere la logica sensibile lato backend.

### Domanda: Perche' usare Supabase Edge Functions?

Per eseguire logica server-side senza metterla dentro l'app Flutter. Le funzioni possono usare credenziali piu' sensibili e fare controlli che non dovrebbero stare nel client, come invio notifiche o verifica codici.

### Domanda: Cosa fa `RemoteDbService`?

E' il servizio che gestisce operazioni remote legate ad auth e account: login, signup, upload foto profilo, logout, registrazione locale, verifica locale e refresh dello stato account. Comunica con Supabase tramite richieste HTTP REST e funzioni.

### Domanda: Perche' molte funzioni ritornano codici numerici come `200`, `201`, `401` o `500`?

Perche' rispecchiano i codici HTTP. `200` e `201` indicano successo, `401` indica non autorizzato o credenziali/codice non validi, `500` indica errore interno o situazione imprevista. La UI usa questi valori per decidere cosa mostrare.

### Domanda: Cosa succede se manca internet durante il signup?

Il controller controlla la connessione con `connectivity_plus`. Se non c'e' rete, imposta l'errore `no_internet_connection` e blocca l'avanzamento. Questo evita di far partire chiamate remote destinate a fallire.

### Domanda: Perche' la citta' viene presa dal GPS?

Per semplificare l'inserimento e rendere il profilo piu' collegato al territorio. Il controller usa `Geolocator` per ottenere coordinate e `geocoding` per trasformarle in un nome di citta'.

### Domanda: Cosa succede se l'utente nega i permessi posizione?

Il controller intercetta il caso e mostra un errore tradotto, per esempio permessi negati o servizi posizione disattivati. La UI non va in crash: informa l'utente.

### Domanda: Perche' si usa `notifyListeners()`?

Per avvisare la UI che lo stato e' cambiato. Ad esempio quando parte un caricamento, cambia un errore, viene scelta una foto o cambia pagina, il controller notifica la schermata e Flutter ricostruisce la parte interessata.

### Domanda: Cosa fa `canContinue`?

E' un getter che decide se il pulsante avanti deve essere attivo. Cambia in base allo step: nel primo richiede immagine e nome, nel secondo telefono e password, nel terzo citta' e OTP.

### Domanda: Perche' usi un `PageController` per il signup?

Per creare un flusso a step controllato. L'utente non scrolla liberamente: il controller decide quando passare allo step successivo dopo aver validato i dati.

### Domanda: Cosa fa Firebase nel progetto attuale?

Firebase e' usato soprattutto per Firebase Cloud Messaging, cioe' notifiche push. L'app inizializza Firebase all'avvio, ottiene un token FCM dal dispositivo e lo salva nel database per poter ricevere notifiche.

### Domanda: Firebase Auth e Firebase Messaging sono la stessa cosa?

No. Firebase Auth gestisce autenticazione utenti. Firebase Messaging gestisce notifiche push. Nel progetto attuale Firebase Messaging e' gia' usato; l'autenticazione via SMS Firebase era un'idea futura, ma ora il signup usa OTP provvisorio `123456`.

### Domanda: Perche' l'invio notifiche passa dal backend e non dal telefono?

Perche' per inviare push FCM servono credenziali server. Se fossero dentro l'app, potrebbero essere estratte. Il client quindi salva l'invito e chiama una funzione backend, che si occupa della parte sicura.

### Domanda: Se la notifica push non arriva, l'invito viene perso?

No. L'invito e' salvato nel database. La push e' solo un avviso. Anche se l'avviso fallisce, la schermata notifiche puo' ancora leggere l'invito dal database.

### Domanda: Qual e' la differenza tra dati persistenti e notifiche push?

I dati persistenti vivono nel database e rappresentano la verita' dell'app. Le notifiche push sono messaggi temporanei inviati al telefono per attirare l'attenzione dell'utente. Un'app robusta non deve dipendere solo dalla push.

### Domanda: Quali sono le parti piu' importanti da spiegare bene?

Le parti piu' importanti sono: avvio app, sessione locale, login/signup, OTP provvisorio, database Supabase, creazione eventi, inviti, notifiche push e differenza tra schermata notifiche e Firebase Messaging.

### Domanda: Cosa diresti se ti chiedono "cosa miglioreresti"?

Direi che renderei l'autenticazione production-ready con un provider reale, sposterei piu' controlli lato backend, aggiungerei test automatici, tipizzerei meglio le risposte del database e gestirei piu' token FCM per utenti con piu' dispositivi.

### Domanda: Come spiegheresti il progetto in modo semplice ma tecnico?

Direi che Vez e' un'app Flutter con un frontend mobile e un backend Supabase/Firebase. Flutter gestisce UI e stato, Supabase conserva dati come utenti, eventi e inviti, Firebase gestisce notifiche push. La sessione viene salvata localmente, mentre le operazioni importanti vengono sincronizzate con il database remoto.

## 22. Mini discorso pronto da dire al professore

Il mio progetto e' un'app Flutter chiamata Vez, pensata per creare e partecipare a eventi reali. All'avvio inizializzo Firebase, notifiche, tema e traduzioni. Poi una loading screen recupera la sessione locale con SharedPreferences e decide se mandare l'utente al login, alla home o alla schermata di account locale in attesa.

La logica e' divisa in servizi: `RemoteDbService` gestisce login e registrazione, `GetDBService` legge dal database, `SetDBService` scrive sul database, `UserSession` mantiene la sessione e `NotificationService` gestisce Firebase Messaging.

La home mostra eventi creati dall'utente, inviti ricevuti ed eventi pubblici vicini. Gli eventi vicini usano la posizione GPS e il calcolo della distanza con latitudine e longitudine. Gli eventi possono avere invitati, stati RSVP e co-host.

Per le notifiche uso Firebase Cloud Messaging. Ogni dispositivo riceve un token FCM, che salvo nel database sull'utente. Quando un host invita qualcuno, l'app salva l'invito nel database e chiama una funzione backend Supabase. Il backend usa il token FCM del destinatario per inviare la push tramite Firebase. La pagina notifiche invece non dipende da Firebase: legge gli inviti dal database e permette all'utente di rispondere going, maybe o not going.

## 23. Punti critici da sapere ammettere

Se il professore chiede cosa miglioreresti, puoi dire:

- userei un sistema auth professionale come Supabase Auth invece di gestire password custom;
- sposterei piu' logica sensibile lato backend;
- salverei piu' token FCM per utente, uno per dispositivo;
- aggiungerei test automatici;
- tipizzerei meglio le risposte database evitando troppe `Map<String, dynamic>`;
- gestirei meglio il tap sulle notifiche push per aprire direttamente l'evento.

Dire queste cose non svaluta il progetto. Anzi, fa vedere che sai distinguere un progetto scolastico/funzionale da una versione production-ready.
