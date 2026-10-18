# Nächste Schritte – Runde 2

Stand: 2026-10-18, Build `9adbab0`. Runde 1 (Zip-Launch, Level, Speedrun, Optik,
Sound, CI) ist erledigt, siehe `roadmap.md` und PRs #1–#12.

Fokus dieser Runde: **flüssiges, befriedigendes Spielgefühl** und eine Höhle,
die **groß, hoch und leer** wirkt statt wie ein enger Gang.
Belege in Klammern stammen aus Headless-Messungen (60 fps) mit dem aktuellen Build.

## Offene Entscheidungen

- [ ] **Wurf während eines Zugs:** Seil-Übergabe (altes Seil hält, bis der neue
      Haken greift – Spider-Man-Kette) oder wie jetzt sofort lösen?
- [ ] **Höhlenmaßstab:** Vorschlag 40 m breit, 35 m hoch, Boden über weite
      Strecken Abgrund. Größer/kleiner?
- [ ] **Schwingen:** Kurze Pendelphase (Seil hält seine Länge ~0,3 s), bevor
      das Einholen startet? Als Vorschau-Build A/B vergleichen.
- [ ] **Rekorde mit verstellten Reglern (TUNE\*):** nicht speichern, oder
      speichern und markieren?

## 1. Bugs und Übersehenes (zuerst)

- [ ] **Hook-Spam kostet Schwung:** Jeder neue Wurf löst das aktuelle Seil
      sofort. Schnelles Nachwerfen bremst (2 s nach dem Start: 18 m statt 24 m,
      Spitze 17 statt 53 m/s), das Seil flackert, es gibt keine Abklingzeit.
      → Seil-Übergabe, Wurf-Puffer (Wisch während der Haken fliegt wird
      gemerkt statt den Flug abzubrechen), kurze Sperre gegen Doppel-Wische.
- [x] **Tippen startet den Timer** (gemessen: nach einem Tipp läuft die Zeit,
      ohne dass man sich bewegt). Nur ein Wurf soll den Lauf starten.
- [x] **Kurzer Wisch zählt als Tipp:** (Tipp nur unter 20 px *und* 500 px/s; 0,15 s Tipp-Sperre nach dem Einhaken) Unter 24 px (ca. 13 pt) und 0,25 s gilt ein
      Wisch als Tipp und löst das Seil – mitten im Zug ärgerlich. Schwelle prüfen,
      Tippen während des Zugs evtl. erst nach 0,15 s zulassen.
- [x] **TUNE während des Zielens startet neu:** (zweiter Finger auf Buttons zählt nicht; Neustart = zwei Finger 0,3 s halten) Ein zweiter Finger (z. B. auf
      TUNE) macht aus dem Zielen einen Zwei-Finger-Tipp → Neustart. Zweiter
      Finger auf GUI darf nicht zählen; Neustart evtl. nur mit Halten (0,4 s).
- [ ] **Stampfer drückt in den Boden:** Der vertikale Mover in Level 4 schiebt
      den Spieler 0,4 m in den Boden (Gefahr, durchzufallen). Zerquetschen soll
      wie Lava zum Checkpoint führen.
- [x] **Hintergrund/Tab-Wechsel:** (Pause bei Fokusverlust, Timer-Schritt max. 0,1 s) Kommt die App zurück, kann ein riesiger
      Frame-Schritt den Timer springen lassen. Bei Fokusverlust pausieren,
      Delta begrenzen.
- [x] **Ruckeln bei 120 Hz und schwankender Bildrate:** Physik läuft mit 60 Hz,
      Kamera und Seil werden in `_physics_process` bewegt, Physik-Interpolation
      ist aus → sichtbares Ruckeln auf ProMotion-iPhones und bei Einbrüchen.
      Physik-Interpolation einschalten, Kamera im Render-Frame glätten.
- [ ] **Zip-Launch in die Decke:** Wer nach oben zippt, prallt an die Decke und
      verliert den Großteil des Tempos (gemessen 38 → 24 m/s). Tempo entlang
      der Fläche umlenken statt vernichten.
- [x] **Tempo-Grenze:** Der Zip-Boost kommt nach der Begrenzung, kurz
      53 statt 50 m/s. Vereinheitlichen.
- [x] **Wind-Sound knackt:** Der Wind wird beim Unterschreiten der Schwelle hart
      gestoppt/gestartet. Ein- und ausblenden.
- [ ] **Rekorde/Geister veralten:** Ändert sich ein Level im Generator, bleiben
      alte Bestzeiten und Geister (passen nicht mehr zur Geometrie). Rekorde an
      eine Level-Version koppeln.
- [x] **Kein Weg zurück ins Menü** außer über den Ziel-Bildschirm → Pause-Menü.

## 2. Die Höhle: groß, hoch, leer

- [ ] **Neuer Level-Baukasten „Kaverne“:** statt Kasten-Tunnel weite Hallen
      (Richtwert 40 × 35 m) mit unregelmäßigen Wänden aus versetzten,
      gedrehten Felsblöcken. Seed-basiert im Generator, damit Level
      reproduzierbar bleiben.
- [ ] **Leere als Gestaltungsmittel:** Boden größtenteils Abgrund (Nebel nach
      unten, kein sichtbarer Grund), wenige, klare Haken-Ziele: Stalaktiten,
      überhängende Felsnasen, frei hängende Felsinseln, Säulen aus der Tiefe.
- [ ] **Maßstab spürbar machen:** Spieler klein im Bild (Kamera weiter weg,
      höher), ferne Silhouetten, schwebender Staub, Lichtkegel von oben,
      leuchtende Kristalle als Orientierung statt Fackel-Reihe.
- [ ] **Licht und Tiefe:** Wenige große Lichtquellen + Nebel mit Höhenverlauf;
      dunkle Tiefe unten, hellere Decke. Farbkontrast Nähe/Ferne.
- [ ] **Physik an den Maßstab anpassen:** größere Reichweite
      (`max_rope_length` ~70 m), schnellerer Haken, Wurfwinkel evtl. aus dem
      Wischwinkel (steil/flach), Kamera-FOV und Abstand.
- [ ] **Level 1–5 als Kavernen neu bauen**, Bot-Test anpassen (Abgrund statt
      Lava, Medaillen neu).
- [ ] **Performance prüfen:** mehr/größere Geometrie, Nebel; Ziel bleibt 60 fps.

## 3. Spielgefühl: flüssig und befriedigend

- [ ] **Seil-Übergabe / Kettenwürfe** (siehe Entscheidung): der Moment, in dem
      der neue Haken greift und das alte Seil loslässt, ist der Kern des Flows.
- [ ] **Treffer-Gefühl:** Hit-Stop (40–60 ms Mini-Freeze) beim Einhaken,
      kurzer FOV-Kick beim Zip-Launch, Seil spannt sich sichtbar (zittert kurz).
- [ ] **Tempo sichtbar machen:** Speed-Lines am Bildrand ab hohem Tempo,
      Wind-Partikel, stärkerer Tempo-Sound (Tonhöhe).
- [ ] **Schwingen** (siehe Entscheidung): Pendelphase vor dem Einholen,
      damit es nicht nur geradlinige Zips gibt.
- [ ] **Landungen erhalten Schwung:** Rollen/Rutschen statt harter Bremsung;
      Wand-Abprall (Wall-Kick) beim Auftreffen mit Tempo.
- [ ] **Flow-Anzeige:** Kette von Treffern ohne Bodenberührung zählen
      (z. B. „x5“), dezent im HUD – belohnt flüssiges Spielen.
- [ ] **Zielhilfe für Stalaktiten** in der großen Höhle (jetzt aus) testen.
- [ ] **Musik:** dezente Loop, die mit dem Tempo intensiver wird.

## 4. Speedrun

- [ ] **Zwischenzeiten:** an Checkpoints „−0,4 s“/„+1,2 s“ gegenüber der
      Bestzeit (grün/rot) – stärkster Antrieb für Wiederholungen.
- [ ] **Geist-Delta** im HUD (Abstand zum Geist in Metern/Sekunden).
- [ ] **Sofort-Neustart** ohne Ladezeit und mit einem Griff (siehe Bug zum
      Zwei-Finger-Tipp).

## 5. Technik

- [ ] **Bildrate auf dem iPhone messen** (Debug-Anzeige in TUNE → Misc).
- [ ] **Bot-Test erweitern:** prüft auch Spam-Verhalten, Timer-Start und
      Zerquetschen (Regressionen der Bugs oben).
- [ ] **Onboarding-Level:** kurzer Tutorial-Abschnitt (Werfen, Zip, Eis).

## Später

- [ ] iOS-App, TestFlight, Game Center (braucht Mac + Apple-Developer-Account).
