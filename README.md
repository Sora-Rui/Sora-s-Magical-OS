# Sora's Magical OS Prototype

Dieses Verzeichnis enthaelt den aktuellen ComputerCraft-Prototyp fuer Sora's Magical OS.

Der Prototyp deckt jetzt alle geplanten Kernpunkte ab:

- Flugmodi: `Parken`, `Docking`, `Reise`, `Gefahr`, `Notfall`
- Startcheckliste vor Abflug
- Autopilot-Light mit Makroprogrammen
- Navigation mit manuellen Wegpunkten
- Maschinenraum- und Fabrikueberwachung
- Schadens- und Alarmmatrix
- Crew-Rollen fuer Pilot, Ingenieur und Alarmzentrale
- Lokales Logbuch
- PIN und physischer Schluesselschalter fuer kritische Funktionen
- Funk- und Nachrichtenseite per Modem
- Tablet-/Pocket-Computer-Client per `tablet.lua`

## Installation

Empfohlene Wege:

- Dev-Weg: Den Inhalt von `computercraft/` direkt auf einen Computer oder eine Disk kopieren.
- Komfort-Weg im Spiel: Nur `install.lua` mit `wget` laden, der Installer zieht den Rest.

Wichtig:

- `startup.lua` muss im Wurzelverzeichnis des Brueckencomputers liegen.
- Der Ordner `smos/` muss komplett vorhanden sein.
- Fuer das Tablet wird zusaetzlich `tablet.lua` installiert.
- Das Tablet-Profil installiert nur `tablet.lua` und keinen Bruecken-Startup.

### Wget-Installation

- Basis-URL auf den Ordner `soras-magical-os/prototype/computercraft` zeigen lassen.
- Beispiel:
- `https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft`
- Installer laden:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft/install.lua`
- Direkt mit Argumenten:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft /`
- Bridge-Profil explizit:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft / bridge`
- Tablet-Profil explizit:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft / tablet`
- Auf Disk installieren:
- `wget run https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft/install.lua https://raw.githubusercontent.com/USER/REPO/BRANCH/soras-magical-os/prototype/computercraft disk`

Installierte Hauptdateien:

- `/startup.lua`
- `/tablet.lua`
- `/smos/boot.lua`
- `/smos/app/runtime.lua`
- `/smos/app/theme.lua`
- `/smos/app/ui.lua`
- `/smos/app/screens.lua`

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
- Flugmodus-Schalter

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

### Crew

- Rollenprofil `Pilot`, `Ingenieur`, `Alarmzentrale`
- PIN-Freigabe
- Schluesselschalter-Zuordnung
- gekoppeltes Tablet anzeigen

### Funk

- Funkstatus
- letzte Kontakte
- eingehende Kurznachrichten
- Hinweis fuer Tablet-Betrieb

### Logbuch

- lokale Historie fuer Moduswechsel, Alarme, PIN-Freigaben, Funk und Steuerbefehle

### System

- Schiffsname
- Palette und Symbol
- Monitor-, Speaker- und Funkstatus
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
- `Schalter I/O`: physischer Schluesselschalter fuer kritische Funktionen

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

Kritische Funktionen brauchen eine Freigabe:

- `Schub`
- Ruderausgaenge
- `Fabrik an/aus`
- `Reserve`
- `Gefahr` / `Notfall`
- `Autopilot Start`
- `PIN aendern`

Freigabewege:

- `U` oder Button fuer PIN-Eingabe
- physischer Schluesselschalter ueber `Schalter I/O`

## Rollen-Login und Bereiche

Es gibt jetzt zwei getrennte Sicherheitsstufen:

- Rollencode fuer den Bereich und die Rolle
- globale PIN fuer kritische Schiffsfunktionen

Bereichslogik:

- ohne Login ist nur `Home` und `Crew` offen
- `Pilot` oeffnet `Helm` und `Navigation`
- `Ingenieur` oeffnet `Maschinenraum/Fabrik` und `System`
- `Alarmzentrale` oeffnet `Alarmzentrale`
- `Funk` und `Logbuch` sind fuer eingeloggte Rollen sichtbar

Standard-Rollencodes im Prototyp:

- `Pilot` -> `1111`
- `Ingenieur` -> `2222`
- `Alarmzentrale` -> `3333`

Im Spiel solltest du diese Codes direkt auf der Crew-Seite aendern.

Login auf dem Hauptrechner:

1. auf `Crew` gehen
2. gewuenschte Rolle mit den Rollenbuttons auswaehlen
3. `Login` druecken
4. Operatornamen und Rollencode eingeben
5. danach oeffnen sich die Bereiche dieser Rolle

Fuer sensible Aktionen wie Schub, Reserve oder Autopilot reicht der Rollencode allein nicht.
Dafuer braucht das System weiterhin die globale PIN oder den physischen Schluesselschalter.

## Funk und Tablet

### Schiff

- Mindestens ein Wireless Modem am Hauptrechner anschliessen
- Funkseite beobachten
- Tablet koppelt sich automatisch ueber den Schiffsnamen

Pocket-Verbindung Schritt fuer Schritt:

1. am Brueckencomputer mindestens ein Wireless Modem anschliessen
2. sicherstellen, dass `tablet.lua` auf dem Pocket Computer installiert ist
3. auf dem Brueckencomputer den Schiffsnamen festlegen
4. auf dem Pocket Computer `tablet` starten
5. mit `S` denselben Schiffsnamen eintragen
6. mit `P` die gewuenschte Rolle waehlen
7. mit `U` den Rollencode dieser Rolle setzen
8. mit `I` optional die globale PIN setzen, falls auch kritische Befehle erlaubt sein sollen
9. mit `R` den Status abrufen
10. sobald der Pocket Computer eine Statusantwort bekommt, ist die Verbindung aktiv

### Pocket Computer

- `tablet.lua` auf dem Pocket Computer starten
- Schiffsnamen eintragen
- Rollencode der gewaehlten Rolle hinterlegen
- globale PIN hinterlegen, falls du kritische Befehle senden willst
- Rolle wechseln mit `P`
- Rollencode setzen mit `U`
- globale PIN setzen mit `I`
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
- Der Rollencode oeffnet erst die Rollenrechte.
- Die globale PIN ist nur fuer kritische Befehle zusaetzlich noetig.

## Bedienung auf dem Hauptrechner

- `Q` beendet das Programm
- `M` schaltet den manuellen Alarm
- `N` oeffnet Namenseingabe
- `U` oeffnet PIN-Freigabe
- `O` aendert die globale PIN
- `H`, `F`, `G`, `A`, `C`, `K`, `L`, `S` springen zu Seiten
- linke und rechte Pfeiltaste wechseln Seiten
- Monitor-Touch und Mausklick funktionieren auf den registrierten Buttons

## Grenzen des Prototyps

- keine direkte Aeronautics-API-Anbindung
- Navigation arbeitet aktuell manuell mit gespeicherten Wegpunkten
- Alarmmatrix basiert auf deinen Redstone-Sensoren
- Tablet ist ein kompakter Remote-Client, kein zweiter Hauptrechner
