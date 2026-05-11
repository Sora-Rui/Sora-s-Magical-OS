# Sora's Magical OS Prototype

Dieses Verzeichnis enthaelt den aktuellen ComputerCraft-Prototyp fuer Sora's Magical OS.

Der Prototyp deckt jetzt alle geplanten Kernpunkte ab:

- Flugmodi: `Parken`, `Docking`, `Reise`, `Gefahr`, `Notfall`
- Startcheckliste vor Abflug
- Autopilot-Light mit Makroprogrammen
- Navigation mit manuellen Wegpunkten
- Maschinenraum- und Fabrikueberwachung
- Schadens- und Alarmmatrix
- Crew-Konten mit Benutzername/Passwort und Rollen fuer Pilot, Ingenieur, Alarmzentrale, Co-Captain und Captain
- Lokales Logbuch
- Rollen-Login als einzige Freigabeebene fuer Schiffsfunktionen
- Funk- und Nachrichtenseite per Modem
- Tablet-/Pocket-Computer-Client per `tablet.lua`

## Installation

Empfohlene Wege:

- Dev-Weg: Den Inhalt von `prototype/computercraft/` direkt auf einen Computer oder eine Disk kopieren.
- Veroeffentlichter GitHub-Raw-Pfad: `wget run https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft/install.lua https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft /`
- reboot
- (Falls bereits installiert:
delete startup.lua
delete smos)
- Komfort-Weg im Spiel: Nur `install.lua` mit `wget` laden, der Installer zieht den Rest.

### Schnellinstallation fuer dieses Repo

- Bridge direkt installieren:
- `wget run https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft/install.lua https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft / bridge`
- danach `reboot`
- Tablet direkt installieren:
- `wget run https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft/install.lua https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft / tablet`
- danach `tablet`

### Wenn du noch die alte Version siehst

- Dann ist fast immer noch ein alter lokaler Stand auf Bridge oder Tablet vorhanden, nicht die GitHub-Raw-Datei.
- Der aktuell veroeffentlichte Raw-Pfad fuer GitHub ist `main/computercraft/...`.
- Der lokale Quellordner im Repo bleibt trotzdem `prototype/computercraft/`.
- Wenn im Debug noch `Security: Nur kritisch` steht, laeuft weiterhin ein alter Bridge-Stand.
- Bridge zwangsweise neu aufsetzen:
- `delete startup.lua`
- `delete smos`
- `wget run https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft/install.lua https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft / bridge`
- `reboot`
- Tablet zwangsweise neu aufsetzen:
- `delete tablet.lua`
- `delete smos`
- `wget run https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft/install.lua https://raw.githubusercontent.com/Sora-Rui/Sora-s-Magical-OS/main/computercraft / tablet`
- `tablet`
- Woran du die neue Version sofort erkennst:
- auf dem Tablet steht `Funkprotokoll`
- auf dem Tablet steht `Auth: U User W Pw`
- auf dem Tablet steht `Sys : S Schiff R`
- im Bridge-Funkbereich tauchen `T` und `BC` im Protokoll auf
- auf der Crew-Seite gibt es `User+`, `User-`, `Rolle+`, `Rolle-` und eine klickbare Crew-Auswahl

Wichtig:

- `startup.lua` muss im Wurzelverzeichnis des Brueckencomputers liegen.
- Der Ordner `smos/` muss komplett vorhanden sein.
- Fuer das Tablet wird zusaetzlich `tablet.lua` installiert.
- Das Tablet-Profil installiert nur `tablet.lua` und keinen Bruecken-Startup.

### Wget-Installation

- Basis-URL auf den veroeffentlichten Ordner `computercraft` zeigen lassen.
- Beispiel:
- `https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft`
- Installer laden:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft/install.lua`
- Direkt mit Argumenten:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft /`
- Bridge-Profil explizit:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft / bridge`
- Tablet-Profil explizit:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft / tablet`
- Auf Disk installieren:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/computercraft disk`

Installierte Hauptdateien:

- `/startup.lua`
- `/tablet.lua`
- `/smos/boot.lua`
- `/smos/app/runtime.lua`
- `/smos/app/theme.lua`
- `/smos/app/ui.lua`
- `/smos/app/screens.lua`

## Wichtig vor der Nutzung

- Brueckencomputer und Tablet muessen nach den letzten Auth- und Funkaenderungen beide auf denselben Stand gebracht werden.
- Das erste Captain-Konto wird nur lokal auf der Bruecke eingerichtet, nicht vom Tablet aus.
- Fuer einen Pocket Computer braucht die Bruecke mindestens ein Wireless Modem; Wired allein reicht nicht.
- Das Funkprotokoll zeigt jetzt eingehende und ausgehende Eintraege mit Autor, PC-ID und Geraetetyp `T` oder `BC`.
- Das Tablet fuehrt ein eigenes kompaktes Funkprotokoll fuer Syncs, Nachrichten und Remote-Aktionen.
- fuer eigene Speaker-Audios erwartet das OS `.dfpwm` Dateien in `/smos/audio`; der Ordner wird bei Bedarf automatisch angelegt

## Ingame-Aufbau

### Brueckenrechner

Empfohlen:

- `Advanced Computer` oder normaler Computer als Hauptrechner
- grosser Monitor an der Bruecke
- Speaker fuer Alarmton
- mindestens ein Wireless Modem fuer Pocket-/Tablet-Anbindung
- ein reines Wired Modem reicht nicht fuer einen Pocket Computer

### Tablet

Empfohlen:

- `Pocket Computer` oder `Advanced Pocket Computer`
- Wireless Modem aktiv
- `tablet.lua` auf dem Pocket Computer vorhanden
- zuerst nach einem Update neu starten, damit das neue Setup fuer Benutzername/Passwort und Funkprotokoll geladen wird

### Create- und Redstone-Ebene

Sora's Magical OS spricht nicht direkt mit Aeronautics oder Create per Mod-API.
Das System schaltet reale Redstone-Punkte, die wiederum dein Schiff und deine Bordtechnik steuern.

Typische Ausfuehrungskomponenten:

- Clutches
- Gearshifts
- Redstone Links
- Motorfreigaben
- Alarmglocken, Lampen, Sirenen
- Maschinenraum-Sperren oder Reservepfade

## Seiten und Funktionen

### Home

- Schiffsstatus
- aktive Rolle
- Startcheckliste
- aktueller Wegpunkt
- `mom. pos.` ueber `gps.locate()` falls ein GPS-Netz erreichbar ist
- Flugmodus-Schalter
- im Brueckenkopf nahe der Uhrzeit steht zusaetzlich eine kompakte Positionsanzeige

### Helm

- Schub und Kurs
- Helmsignal- und Ruderzuordnung
- Sicherheitsstatus

### Maschinenraum

- Treibstoff, Generator, Fabrik, Reservebetrieb
- Not-Aus-Ueberwachung
- Fabrik-Sollmodus fuer die Checkliste

### Navigation

- aktiver Wegpunkt
- Heimathafen
- Distanz- und Richtungsnotiz
- Autopilot-Light mit Makros

### Alarmzentrale

- Alarmmatrix fuer:
  - Treibstoff niedrig
  - Antrieb gestoert
  - Helm getrennt
  - Werkstatt ueberlastet
  - Feindkontakt
  - Not-Aus aktiv
- manueller Alarm
- Alarmmodus `Gefahr` und `Notfall`

Wichtig fuer den manuellen Alarm:

- er setzt den `Alarm I/O` jetzt dauerhaft auf aktiv, damit angeschlossene Sirenen und Lampen eindeutig einschalten
- ohne zugeordneten `Alarm I/O` und ohne Speaker bleibt nur die Anzeige auf dem OS sichtbar
- die Alarmseite hat jetzt einen `Speaker-Test`, um direkt zu pruefen, ob der CC-Speaker selbst hoerbar ist
- der `Speaker-Test` spielt jetzt eine kurze mehrtoenige Folge statt nur eines einzelnen Signals
- das Feld `Speaker` zeigt den Speaker-Status; `Alarm I/O` wird separat darunter angezeigt und ist nicht die Speaker-Seite

### Crew

- Rollenprofil `Pilot`, `Ingenieur`, `Alarmzentrale`, `Co-Captain`, `Captain`
- Crew-Konten mit Benutzername und Passwort
- klickbare Crew-Verwaltungsliste auf dem Monitor
- Rollenentzug und Benutzerloeschung arbeiten mit der aktuell ausgewaehlten Crew-Person statt mit getipptem Benutzernamen
- `User+` verwendet die aktuelle Auswahl als Standard, kann aber auch neue Konten anlegen
- Rollen-Login steuert alle Bereiche direkt ohne zweite Freigabestufe
- gekoppeltes Tablet anzeigen

## Defaults

- neuer Standardname fuer frische Installationen: `Mein Luftschift`

### Funk

- Funkstatus
- letzte Kontakte
- eingehende Kurznachrichten
- ausgehende Kurznachrichten der Bruecke
- Anzeige von Autor, PC-ID und Typ `T`/`BC`
- Hinweis fuer Tablet-Betrieb

### Logbuch

- lokale Historie fuer Moduswechsel, Alarme, Funk und Steuerbefehle

### System

- Schiffsname
- Palette und Symbol
- Monitor-, Speaker- und Funkstatus
- Audio-Cue-Auswahl fuer eingebaute Sounds und eigene `.dfpwm` Dateien
- Debug-Zusammenfassung auf dem Monitor und Live-Debug auf dem Computer-Terminal, solange die Systemseite offen ist
- Kern-I/O fuer Alarm, Helm und Ruder

## Verdrahtung

Die Seitenzuordnung erfolgt immer ueber die normalen ComputerCraft-Seiten:

- `top`
- `bottom`
- `left`
- `right`
- `front`
- `back`
- `none`

### Typische Signale

- `Helm I/O`: Helmsignal oder Freigabe von der Steuerung
- `Schub I/O`: Hauptantrieb oder Master-Freigabe
- `Backbord I/O`: Linksdrehung
- `Steuerbord I/O`: Rechtsdrehung
- `Alarm I/O`: Lampe, Glocke, Sirene
- `Fuel I/O`: Treibstoffsensor
- `Gen I/O`: Generatorstatus
- `Fabrik I/O`: Fabrik-Start/Stop
- `Res I/O`: Reservebetrieb-Ausgang
- `Not-Aus`: physischer Not-Aus-Eingang
- `Feind I/O`: Feindkontakt-Sensor
- `Last I/O`: Ueberlast- oder Werkstattsensor

### Beispielbelegung

- `Helm I/O` -> `back`
- `Schub I/O` -> `top`
- `Backbord I/O` -> `left`
- `Steuerbord I/O` -> `right`
- `Alarm I/O` -> `front`
- `Fabrik I/O` -> `bottom`
- `Fuel I/O` -> `left`
- `Gen I/O` -> `right`
- `Res I/O` -> `front`
- `Not-Aus` -> `bottom`

Passe die Zuordnung an deine echte Verkabelung an. Wenn die Seiten nicht stimmen, schaltet das OS die falschen Punkte.

## Startcheckliste

Vor dem Abflug prueft das System:

- Helm-Signal vorhanden
- Treibstoff okay
- Fabrik im Sollzustand
- Alarmseite belegt
- Monitor verbunden
- Speaker verbunden

Der Sollzustand der Fabrik kann im Maschinenraum zwischen `Standby`, `Produktion` und `Beliebig` durchgeschaltet werden.

## Flugmodi

- `Parken`: alle Bewegungsachsen sichern, Fabrik aus, ruhige Farben
- `Docking`: praeziser Annahmebetrieb
- `Reise`: normaler Flugmodus
- `Gefahr`: Reservebetrieb an, Alarmbereitschaft, Warnfarben
- `Notfall`: Alarm aktiv, Bewegungen stoppen, Reserve an

Die obere UI-Leiste wechselt ihre Farbe mit dem Modus.

## Autopilot-Light

Aktuell enthaltene Makros:

- `Abflugsequenz`
- `Dockingkurs`
- `Patrouille`

Der Autopilot schaltet nur die vorhandenen Redstone-Ausgaenge nach Zeitplan.
Er ist kein echter Physik- oder GPS-Autopilot.

## Sicherheit

Es gibt jetzt nur noch eine Sicherheitsstufe:

- Crew-Konto mit Benutzername und Passwort
- die zugewiesene Rolle entscheidet direkt, welche Aktionen erlaubt sind
- es gibt keine zusaetzliche PIN- oder Schluesselschalter-Freigabe mehr
- sobald eine Rolle die Aktion darf, ist sie sofort verfuegbar
- waehrend Texteingaben zeigt der Monitor `Bitte Eingabe im Computer ausfuehren`; Abbruch geht ueber den Monitor-Button oder `Esc` am Computer

## Eigene Audios

Eigene Audioausgabe ueber den CC-Speaker ist jetzt vorbereitet.

- lege eigene `.dfpwm` Dateien in `/smos/audio`
- oeffne `System`
- waehle mit `Cue <` und `Cue >` die gewuenschte Audio-Cue
- `Play Cue` spielt die aktuelle Auswahl ab
- eingebaute Cues und eigene DFPWM-Dateien erscheinen gemeinsam in der Auswahl

Hinweis:

- fuer eigene Dateien wird das CC:Tweaked-Format `DFPWM` verwendet, nicht `.ogg`
- `Speaker-Test` prueft weiterhin nur den allgemeinen Speaker, unabhaengig von der gewaehlten Cue

## Debug

Wenn `System` auf dem Monitor geoeffnet ist, spiegelt Sora's Magical OS erweiterte Debugdaten parallel auf das native Computer-Terminal.

Dort siehst du unter anderem:

- aktive Seite, Tick, Modus und Crew-Kontext
- Monitor- und Speaker-Erkennung
- Alarmstatus und Ausgangszustaende
- GPS-, Funk- und Sicherheitsstatus
- aktuelle Audio-Cue und letztes Audio-Ergebnis
- letzten Logeintrag

## Rollen-Login und Bereiche

Es gibt jetzt nur noch eine Sicherheitsstufe:

- Crew-Konto mit Benutzername und Passwort
- die zugewiesene Rolle entscheidet direkt ueber den Zugriff

Rollenlogik:

- der erste Captain wird zum Gruender-Captain und bleibt die oberste Leitung
- weitere leitende Offiziere sollten als `Co-Captain` gefuehrt werden
- der Gruender-Captain kann `Co-Captain` vergeben oder entziehen
- `Co-Captain` und `Captain` koennen normale Crew-Konten verwalten
- ein Crew-Konto kann mehrere Rollen besitzen
- wenn noch kein Captain existiert, wird das erste erfolgreiche Captain-Login auf der Bruecke automatisch als Captain-Konto angelegt

Bereichslogik:

- ohne Login ist nur `Home` und `Crew` offen
- `Pilot` oeffnet `Helm` und `Navigation`
- `Ingenieur` oeffnet `Maschinenraum/Fabrik` und `System`
- `Alarmzentrale` oeffnet `Alarmzentrale`
- `Co-Captain` oeffnet alle Bereiche unterhalb des Gruender-Captains
- `Captain` oeffnet alle Bereiche
- `Funk` und `Logbuch` sind fuer eingeloggte Rollen sichtbar

Erstes Captain-Konto einrichten:

1. auf `Crew` gehen
2. Rolle `Captain` waehlen
3. `Login` druecken
4. neuen Benutzernamen und Passwort eingeben
5. wenn noch kein Captain existiert, wird dieses Konto automatisch zum ersten Captain

Crew-Konten fuer andere Personen anlegen:

1. als `Captain` einloggen
2. auf `Crew` `User+` druecken
3. Benutzername und Passwort fuer das neue Konto setzen
4. gewuenschte Rolle oben auswaehlen
5. `Rolle+` druecken, um diese Rolle dem Benutzer zu geben

Rollen oder Benutzer wieder entfernen:

1. als Leitung auf `Crew` einloggen
2. Zielkonto in der klickbaren Crew-Liste auswaehlen
3. gewuenschte Rolle oben auswaehlen
4. `Rolle-` entzieht genau diese Rolle
5. `User-` loescht das gesamte Crew-Konto

Wichtig dabei:

- der Gruender-Captain steht in der Crew-Liste immer ganz oben und ist mit `Gruender` markiert
- der Gruender-Captain kann nicht geloescht oder als Captain entzogen werden
- `Co-Captain` ist fuer weitere leitende Personen gedacht
- der Gruender-Captain kann alte oder migrierte Captain-Rechte von anderen wieder entfernen

Login auf dem Hauptrechner:

1. auf `Crew` gehen
2. gewuenschte Rolle mit den Rollenbuttons auswaehlen
3. `Login` druecken
4. Benutzername und Passwort eingeben
5. danach oeffnen sich die Bereiche dieser Rolle

Der `Captain` hat Bereichszugriff auf das gesamte OS und kann alle Rollenaktionen ausfuehren.
Der `Co-Captain` hat ebenfalls Vollzugriff auf den Schiffsbetrieb, bleibt aber unter dem Gruender-Captain.
Es gibt keine zusaetzliche globale PIN mehr.
Sobald die Rolle die Aktion darf, ist sie direkt verfuegbar.

## Funk und Tablet

### Schiff

- Mindestens ein Wireless Modem am Hauptrechner anschliessen
- Funkseite beobachten
- Tablet koppelt sich automatisch ueber den Schiffsnamen

Pocket-Verbindung Schritt fuer Schritt:

1. am Brueckencomputer mindestens ein Wireless Modem anschliessen
2. sicherstellen, dass `tablet.lua` auf dem Pocket Computer installiert ist
3. das erste Captain-Konto einmal lokal auf der Bruecke einrichten, falls noch keines existiert
4. auf dem Brueckencomputer den Schiffsnamen festlegen
5. auf dem Pocket Computer `tablet` starten
6. der erste Setup-Dialog fragt nach Schiffsname und ob das Tablet als `Captain` verbinden soll
7. Benutzername und Passwort eines vorhandenen Crew-Kontos eintragen
8. mit `P` bei Bedarf die Rolle wechseln, dabei ist jetzt auch `Co-Captain` enthalten; mit `C` wird direkt das Captain-Profil gesetzt
9. mit `R` den Status abrufen
10. sobald der Pocket Computer eine Statusantwort bekommt, ist die Verbindung aktiv

### Pocket Computer

- `tablet.lua` auf dem Pocket Computer starten
- Schiffsnamen eintragen
- Benutzername des Crew-Kontos hinterlegen
- Passwort des Crew-Kontos hinterlegen
- vereinfachte Hauptansicht mit letzten Funkprotokollen verfuegbar
- Rolle wechseln mit `P` zwischen `Pilot`, `Ingenieur`, `Alarmzentrale`, `Co-Captain`, `Captain`
- Captain-Profil umschalten mit `C`
- Benutzer setzen mit `U`
- Passwort setzen mit `W`
- Status aktualisieren mit `R`

Tablet-Befehle:

- `1` Alarm
- `2` Docking
- `3` Reise
- `4` Gefahr
- `5` Notfall
- `6` Schub
- `7` Fabrik
- `8` Reserve
- `9` Autopilot Start
- `0` Autopilot Stop
- `M` Nachricht senden

Wichtig:

- Nur der Hauptrechner schaltet echte Ausgaenge.
- Das Tablet sendet nur Befehle an den Hauptrechner.
- Das Tablet nutzt dieselben Crew-Konten mit Benutzername und Passwort wie die Bruecke.
- Die Rolle muss dem Benutzer vorher vom Captain zugewiesen worden sein.
- Im Funkprotokoll steht `T` fuer Tablet/Pocket Computer und `BC` fuer Brueckencomputer.
- Eigene Nachrichten werden jetzt ebenfalls im Funkprotokoll angezeigt und nicht nur eingehende Nachrichten.
- Kritische Befehle folgen nur der Rolle des Crew-Kontos.

## Bedienung auf dem Hauptrechner

- `Q` beendet das Programm
- `M` schaltet den manuellen Alarm
- `N` oeffnet Namenseingabe
- `H`, `F`, `G`, `A`, `C`, `K`, `L`, `S` springen zu Seiten
- linke und rechte Pfeiltaste wechseln Seiten
- Monitor-Touch und Mausklick funktionieren auf den registrierten Buttons

## Grenzen des Prototyps

- keine direkte Aeronautics-API-Anbindung
- Navigation arbeitet aktuell manuell mit gespeicherten Wegpunkten
- Alarmmatrix basiert auf deinen Redstone-Sensoren
- Tablet ist ein kompakter Remote-Client, kein zweiter Hauptrechner
