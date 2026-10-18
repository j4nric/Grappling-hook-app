# Nächste Schritte – Runde 3

Stand: 2026-10-18. Runde 1 und 2 sind erledigt (PRs #1–#24, Zusammenfassung in
`roadmap.md`). Diese Runde nimmt sich bewusst die aufwendigen Brocken vor:
Figur und Seil als Physik, neue Hallen-Mechaniken, Kamera-Regie, Raumklang,
Replays, installierbare Web-App – plus Bugs und Leistung.
Belege in Klammern stammen aus Messungen mit dem aktuellen Build.

## 1. Bugs und Aufräumen

- [x] **Daily Cave hängt an der lokalen Zeitzone:** Der Seed kommt aus dem
      Systemdatum; um Mitternacht UTC sehen Spieler in verschiedenen Zonen
      verschiedene „Daily Caves“. → UTC-Datum.
- [x] **Level-Menü läuft über:** 8 Einträge (Tutorial, 5 Level, Daily, Random)
      à 96 px + Titel passen auf kleine Handys/Querformat nicht mehr. →
      scrollbare Liste.
- [x] **Rekord-Datei wächst ewig:** Jede Level-Version und jede Random Cave legt
      Einträge und Geister-Dateien an, nichts wird gelöscht. → alte Versionen
      und alte Random Caves aufräumen (umgesetzt: alte Versionen sofort, Random
      Caves nur die 20, Daily Caves die 14 zuletzt gespielten).
- [x] **CLAUDE.md doppelt:** Dateiüberblick listet `levels.gd`, `level.gd` und
      `cave_generator.gd` zweimal, „Generierte Level“ stimmt nicht mehr.
- [x] **Fehlwurf beim Einstieg ins Menü:** Der Tipp, der im Level-Menü ein Level
      wählt, darf nicht als Spiel-Tipp/Wurf weiterlaufen (geprüft: der Druck
      fällt in die Pause des Menüs und wird verworfen; Test in `test_records`).

## 2. Leistung

- [x] **Licht-LOD:** bis zu 42 Lichter pro Level (Random Cave #48213), der
      Compatibility-Renderer nimmt pro Objekt höchstens 8 → Lichter flackern an
      Hallengrenzen und kosten Zeit. → Lichtmanager: nur die nächsten N Lichter
      an, weich ein- und ausblenden. (Umgesetzt: höchstens 10 Lichter im Umkreis
      von 90 m; Browser-Vergleich mit Software-Rendering: 4,4–6,0 → 9,0–9,2 fps.)
- [x] **Sichtweite für Deko:** Kristalle, Lichtkegel und Staub weit hinten im
      Nebel nicht zeichnen (`visibility_range`).
- [x] **Messbar machen:** Leistungs-Test (Lichter aktiv, Draw-Objekte im Bild,
      Aufbauzeit) und ein Browser-Benchmark im Bot-Build als Vergleichswert.

## 3. Figur und Seil (Schwunggefühl sichtbar machen)

- [x] **Gelenkfigur statt Kapsel:** Rumpf, Kopf, Arme, Beine, Rucksack; Posen
      nach Zustand: Arm greift zum Anker, Beine schwingen nach, Salto beim
      Zip, Hocke bei der Landung, Ziel-Haltung beim Zielen.
- [x] **Schal als Verlet-Band:** zeigt Tempo und Richtung, flattert im Wind.
- [x] **Seil als Verlet-Kette:** hängt beim Flug des Hakens durch, strafft sich
      beim Einhaken, schlängelt nach dem Lösen zurück.

## 4. Neue Hallen-Mechaniken

- [x] **Aufwind-Schächte:** Luftsäulen aus der Tiefe tragen den Spieler nach
      oben (sichtbare Partikel, Windgeräusch).
- [x] **Brechende Stalaktiten:** halten den Haken kurz, dann brechen sie und
      fallen – zwingen zur Kette.
- [x] **Tempo-Ringe:** optionale Ringe, die beim Durchfliegen Schub geben
      (Abkürzungen für Speedrunner).
- [x] **Dunkle Hallen:** nur Kristalle und eine Kopflampe am Spieler.
- [x] Generator, Baukasten, Bot und ein neues Level „Updraft“ dafür.
- [x] **Neu entdeckt:** Ein zusätzlicher Zufallswurf im Baukasten verschiebt alle
      Höhlen (und damit Rekorde und Medaillen). Neue Elemente würfeln nur, wo sie
      vorkommen; bestehende Level bleiben bitgleich.
- [x] **Neu entdeckt:** Rötliche Brüchig-Steine sahen im Dunkeln wie Lava aus →
      eigenes helles Sandstein-Material.

## 5. Kamera-Regie

- [x] **Unter der Decke:** Nach Zips hängt man knapp unter der Decke; die Kamera
      senkt sich dann und blickt leicht nach oben, damit die Halle sichtbar bleibt.
- [x] **Ziel-Kamera:** Zeitlupe beim Durchfliegen des Ziels, die Kamera schwenkt
      um den Spieler.
- [x] **Respawn-Blende:** kurzes Abblenden statt hartem Sprung beim Tod.

## 6. Raumklang

- [x] **Höhlen-Hall:** Hall für die Effekte (umgesetzt als eingebackener Hall
      in `tools/gen_sounds.py`: frühe Reflexionen + 1,4 s Nachhall).
- [x] **3D-Geräusche:** Tropfen, Lava-Brodeln, Kristall-Summen, Aufwind-Rauschen
      an ihren Orten (`AmbientSound`, ein `AudioStreamPlayer3D`, vom Baukasten
      platziert).
- [x] **Neu entdeckt:** Im Web-Export spielt Godot Sounds als Web-Audio-Samples;
      Bus-Effekte (Reverb) greifen dort nicht zuverlässig → Hall in die Dateien
      backen statt Reverb-Bus.
- [x] **Neu entdeckt:** Dutzende dauernd laufende 3D-Schleifen kosten im Browser
      je einen Audio-Knoten → Geräusche spielen nur in Hörweite des Spielers.

## 7. Replays und Statistik

- [x] **Replay der Bestzeit:** im Ziel „Replay“ – Kamera folgt dem
      aufgezeichneten Lauf (Position, Seil, Anker). Der Geist zeichnet dafür
      auch den Anker auf; alte Geister (nur Positionen) spielen ohne Seil.
- [x] **Statistik:** Läufe, Meter, Haken, längster Flow, Spielzeit – gesamt und
      pro Level, im Menü („Stats“). Daily und Random Caves zählen je als eine
      Gruppe.
- [x] **Neu entdeckt:** Ein Neustart aus dem Lauf heraus zählte nirgends –
      Statistik wird jetzt bei Ziel, Neustart, Levelwechsel und beim Wechsel in
      den Hintergrund geschrieben (nicht jeden Frame: IndexedDB im Browser).

## 8. Web-App

- [ ] **Installierbar (PWA):** Manifest, Icon, Offline-Cache, Vollbild ohne
      Safari-Leisten, wenn vom Home-Bildschirm gestartet.

## Auf dem Gerät (nur mit dem iPhone möglich)

- [ ] **Bildrate auf dem iPhone messen** (TUNE → Misc → Debug-Anzeige).
- [ ] **Neue Standardwerte erspielen** und per **Copy** schicken.

## Später

- [ ] iOS-App, TestFlight, Game Center (braucht Mac + Apple-Developer-Account).
- [ ] Bestenliste für die Daily Cave (braucht einen Server).
