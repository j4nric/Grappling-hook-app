# Nächste Schritte – Runde 3

Stand: 2026-10-18. Runde 1 und 2 sind erledigt (PRs #1–#24, Zusammenfassung in
`roadmap.md`). Diese Runde nimmt sich bewusst die aufwendigen Brocken vor:
Figur und Seil als Physik, neue Hallen-Mechaniken, Kamera-Regie, Raumklang,
Replays, installierbare Web-App – plus Bugs und Leistung.
Belege in Klammern stammen aus Messungen mit dem aktuellen Build.

## 1. Bugs und Aufräumen

- [ ] **Daily Cave hängt an der lokalen Zeitzone:** Der Seed kommt aus dem
      Systemdatum; um Mitternacht UTC sehen Spieler in verschiedenen Zonen
      verschiedene „Daily Caves“. → UTC-Datum.
- [ ] **Level-Menü läuft über:** 8 Einträge (Tutorial, 5 Level, Daily, Random)
      à 96 px + Titel passen auf kleine Handys/Querformat nicht mehr. →
      scrollbare Liste.
- [ ] **Rekord-Datei wächst ewig:** Jede Level-Version und jede Random Cave legt
      Einträge und Geister-Dateien an, nichts wird gelöscht. → alte Versionen
      und alte Random Caves aufräumen (nur die letzten N behalten).
- [ ] **CLAUDE.md doppelt:** Dateiüberblick listet `levels.gd`, `level.gd` und
      `cave_generator.gd` zweimal, „Generierte Level“ stimmt nicht mehr.
- [ ] **Fehlwurf beim Einstieg ins Menü:** Der Tipp, der im Level-Menü ein Level
      wählt, darf nicht als Spiel-Tipp/Wurf weiterlaufen (prüfen und testen).

## 2. Leistung

- [ ] **Licht-LOD:** bis zu 42 Lichter pro Level (Random Cave #48213), der
      Compatibility-Renderer nimmt pro Objekt höchstens 8 → Lichter flackern an
      Hallengrenzen und kosten Zeit. → Lichtmanager: nur die nächsten N Lichter
      an, weich ein- und ausblenden.
- [ ] **Sichtweite für Deko:** Kristalle, Lichtkegel und Staub weit hinten im
      Nebel nicht zeichnen (`visibility_range`).
- [ ] **Messbar machen:** Leistungs-Test (Lichter aktiv, Draw-Objekte im Bild,
      Aufbauzeit) und ein Browser-Benchmark im Bot-Build als Vergleichswert.

## 3. Figur und Seil (Schwunggefühl sichtbar machen)

- [ ] **Gelenkfigur statt Kapsel:** Rumpf, Kopf, Arme, Beine, Rucksack; Posen
      nach Zustand: Arm greift zum Anker, Beine schwingen nach, Salto beim
      Zip, Hocke bei der Landung, Ziel-Haltung beim Zielen.
- [ ] **Schal als Verlet-Band:** zeigt Tempo und Richtung, flattert im Wind.
- [ ] **Seil als Verlet-Kette:** hängt beim Flug des Hakens durch, strafft sich
      beim Einhaken, schlängelt nach dem Lösen zurück.

## 4. Neue Hallen-Mechaniken

- [ ] **Aufwind-Schächte:** Luftsäulen aus der Tiefe tragen den Spieler nach
      oben (sichtbare Partikel, Windgeräusch).
- [ ] **Brechende Stalaktiten:** halten den Haken kurz, dann brechen sie und
      fallen – zwingen zur Kette.
- [ ] **Tempo-Ringe:** optionale Ringe, die beim Durchfliegen Schub geben
      (Abkürzungen für Speedrunner).
- [ ] **Dunkle Hallen:** nur Kristalle und eine Kopflampe am Spieler.
- [ ] Generator, Baukasten, Bot und ein neues Level „Updraft“ dafür.

## 5. Kamera-Regie

- [ ] **Unter der Decke:** Nach Zips hängt man knapp unter der Decke; die Kamera
      senkt sich dann und blickt leicht nach oben, damit die Halle sichtbar bleibt.
- [ ] **Ziel-Kamera:** Zeitlupe beim Durchfliegen des Ziels, die Kamera schwenkt
      um den Spieler.
- [ ] **Respawn-Blende:** kurzes Abblenden statt hartem Sprung beim Tod.

## 6. Raumklang

- [ ] **Höhlen-Hall:** Reverb-Bus für Effekte und Musik.
- [ ] **3D-Geräusche:** Tropfen, Lava-Brodeln, Kristall-Summen, Aufwind-Rauschen
      an ihren Orten (`AudioStreamPlayer3D`).

## 7. Replays und Statistik

- [ ] **Replay der Bestzeit:** im Ziel „Watch best run“ – Kamera folgt dem
      aufgezeichneten Lauf (Position, Seil, Anker).
- [ ] **Statistik:** Läufe, Meter, Haken, längster Flow, Spielzeit – gesamt und
      pro Level, im Menü.

## 8. Web-App

- [ ] **Installierbar (PWA):** Manifest, Icon, Offline-Cache, Vollbild ohne
      Safari-Leisten, wenn vom Home-Bildschirm gestartet.

## Auf dem Gerät (nur mit dem iPhone möglich)

- [ ] **Bildrate auf dem iPhone messen** (TUNE → Misc → Debug-Anzeige).
- [ ] **Neue Standardwerte erspielen** und per **Copy** schicken.

## Später

- [ ] iOS-App, TestFlight, Game Center (braucht Mac + Apple-Developer-Account).
- [ ] Bestenliste für die Daily Cave (braucht einen Server).
