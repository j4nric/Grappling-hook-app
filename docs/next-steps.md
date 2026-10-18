# Nächste Schritte – Runde 2

Stand: 2026-10-18. Runde 1 (Zip-Launch, Level, Speedrun, Optik, Sound, CI) ist
erledigt, siehe `roadmap.md` und PRs #1–#12. **Runde 2 ist umgesetzt** (PRs #13–#24);
offen sind nur Punkte, die ein echtes Gerät brauchen (unten „Auf dem Gerät“).

Fokus dieser Runde: **flüssiges, befriedigendes Spielgefühl** und eine Höhle,
die **groß, hoch und leer** wirkt statt wie ein enger Gang.
Belege in Klammern stammen aus Headless-Messungen (60 fps) mit dem aktuellen Build.

## Offene Entscheidungen

- [x] **Wurf während eines Zugs:** → Seil-Übergabe (umgesetzt). Seil-Übergabe (altes Seil hält, bis der neue
      Haken greift – Spider-Man-Kette) oder wie jetzt sofort lösen?
- [x] **Höhlenmaßstab:** (umgesetzt: 30–46 m breit, Decke 22–32 m, Abgrund) Vorschlag 40 m breit, 35 m hoch, Boden über weite
      Strecken Abgrund. Größer/kleiner?
- [x] **Schwingen:** (`swing_time`, Regler; in den Gängen kostet schon 0,1 s die 2–3-fache Zeit → Standard 0; in den Kavernen neu bewertet: 0,15 s fast doppelte Zeit, 0,3 s scheitert schon am ersten Abgrund → bleibt 0) Kurze Pendelphase (Seil hält seine Länge ~0,3 s), bevor
      das Einholen startet? Als Vorschau-Build A/B vergleichen.
- [x] **Rekorde mit verstellten Reglern (TUNE\*):** (gespeichert und markiert: „*“ in HUD und Menü, „(TUNE*)“ im Ziel) nicht speichern, oder
      speichern und markieren?

## 1. Bugs und Übersehenes (zuerst)

- [x] **Hook-Spam kostet Schwung:** (jetzt umgekehrt: Nachwerfen 38,6 m statt 26,1 m in 2 s) Jeder neue Wurf löst das aktuelle Seil
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
- [x] **Stampfer drückt in den Boden:** (`crushed` → Checkpoint) Der vertikale Mover in Level 4 schiebt
      den Spieler 0,4 m in den Boden (Gefahr, durchzufallen). Zerquetschen soll
      wie Lava zum Checkpoint führen.
- [x] **Hintergrund/Tab-Wechsel:** (Pause bei Fokusverlust, Timer-Schritt max. 0,1 s) Kommt die App zurück, kann ein riesiger
      Frame-Schritt den Timer springen lassen. Bei Fokusverlust pausieren,
      Delta begrenzen.
- [x] **Ruckeln bei 120 Hz und schwankender Bildrate:** Physik läuft mit 60 Hz,
      Kamera und Seil werden in `_physics_process` bewegt, Physik-Interpolation
      ist aus → sichtbares Ruckeln auf ProMotion-iPhones und bei Einbrüchen.
      Physik-Interpolation einschalten, Kamera im Render-Frame glätten.
- [x] **Zip-Launch in die Decke:** (Umlenkung mit Streifwinkel) Wer nach oben zippt, prallt an die Decke und
      verliert den Großteil des Tempos (gemessen 38 → 24 m/s). Tempo entlang
      der Fläche umlenken statt vernichten.
- [x] **Tempo-Grenze:** Der Zip-Boost kommt nach der Begrenzung, kurz
      53 statt 50 m/s. Vereinheitlichen.
- [x] **Wind-Sound knackt:** Der Wind wird beim Unterschreiten der Schwelle hart
      gestoppt/gestartet. Ein- und ausblenden.
- [x] **Rekorde/Geister veralten:** (Rekord-ID = Level + Hash des Layouts) Ändert sich ein Level im Generator, bleiben
      alte Bestzeiten und Geister (passen nicht mehr zur Geometrie). Rekorde an
      eine Level-Version koppeln.
- [x] **Kein Weg zurück ins Menü** außer über den Ziel-Bildschirm → Pause-Menü.

### Neu entdeckt beim Umsetzen

- [x] **Zurückschwingen am Anker:** Fliegt man unter/an einem Anker vorbei,
      zog das straffe Seil zurück (gemessen: 40 m/s rückwärts). → Vorbeiflug-
      Lösen (`flyby_release_distance`): am Anker vorbei = Zip-Launch.
- [x] **Schonzeit blockierte den Zip:** Nach einer Seil-Übergabe verhinderte die
      Kontakt-Schonzeit den Zip-Launch, der Spieler schoss durch den Anker.
- [x] **Neues Seil bremste:** Jedes neue Seil holte wieder langsam ein; jetzt
      startet es mit dem aktuellen Annäherungstempo (`_reel_base`).
- [x] **Umlenkung verstärkte Rückwärtstempo:** Volle Geschwindigkeit entlang
      der Fläche machte aus kleinen Restanteilen (z. B. 3 m/s rückwärts beim
      Frontal-Crash) volles Tempo zurück. → Streifwinkel skaliert, nie schneller
      als vorher, kein Wall-Kick bei Frontal-Crash, keine Umlenkung am Seil.
- [x] **Stampfer unsichtbar für Kollisionen:** Ein schiebender `AnimatableBody3D`
      taucht nicht in den Slide-Kollisionen auf, nur in `is_on_ceiling()` →
      Erkennung per `test_move` nach oben.
- [x] **Ruckler beim Loslassen schwächte den Wurf:** Kam das Loslassen einen
      langen Frame nach der letzten Bewegung (Ruckler, langsamer Browser), galt
      der Finger als „stehen geblieben“ → Haken mit Mindesttempo, Fehlwurf.
      → Loslassen bis 2 Frames nach der letzten Bewegung zählt zum Flick.
- [x] **Zeitlupe und Hit-Stop teilen sich `Engine.time_scale`** → `TimeScale`
      verwaltet beide; der Timer zählt den Hit-Stop nicht.
- [x] **Kamera taucht in Wände ein:** Beim Schwingen nah an der Wand oder an
      Hindernissen stand die Kamera hinter der Geometrie (Bild dunkel oder voller
      Lava). → Kamera-Kollision: erst Höhe, dann Abstand begrenzen (sonst rutscht
      sie unter der Decke in den Spieler), sofort rein, weich wieder raus.
- [x] **Texturen auf dem iPhone:** Godot hätte 3D-Texturen fürs Web als
      Desktop-VRAM-Format (S3TC) komprimiert, das iPhone-Browser nicht können →
      Texturen verlustfrei importiert (klein, 128 px).
- [x] **Bot wirft nie während des Zugs:** (Bot wirft jetzt in der Kette, zwei Wurfstärken, 17 Richtungen, variiert nach jedem Tod) Ein Ketten-Bot würde zeigen, welche
      Zeiten mit Kettenwürfen möglich sind (Medaillen-Kalibrierung).
- [x] **Decken-Krabbeln:** Nach jedem Zip ist man unter der Decke; der feste
      50°-Wurf traf dann die Decke 2–3 m voraus. → Wurfwinkel-Hilfe: hält der Wurf
      nicht oder ist zu nah, wird flacher geworfen (bis 5°).
- [x] **Stufen zwischen Hallen:** Eine niedrigere Decke in der nächsten Halle war
      eine senkrechte Wand, an der man abprallte und in den Abgrund fiel. →
      schräge Übergänge (Decke und Wände).
- [x] **Taschen über Deckenblöcken:** Zwischen gedrehten Blöcken konnte man auf
      einen Block steigen und feststecken. → durchgehender Deckel über der Decke.
- [x] **Tore:** Ein Loch in der Wand funktioniert mit Zug-zum-Anker kaum (lange
      Seile hängen durch, die Unterkante fängt den Spieler). → Eiswand mit
      senkrechtem Schlitz und Felsinsel als Ziel dahinter.
- [x] **Test-Runner meldete Erfolg trotz kaputtem Testskript** → Ladefehler und
      Skriptfehler zählen als Fehlschlag (CI).
- [x] **Mechanik-Tests hingen an der Level-Geometrie** → feste Test-Tunnel
      (`tests/levels/`).

## 2. Die Höhle: groß, hoch, leer

- [x] **Neuer Level-Baukasten „Kaverne“:** statt Kasten-Tunnel weite Hallen
      (Richtwert 40 × 35 m) mit unregelmäßigen Wänden aus versetzten,
      gedrehten Felsblöcken. Seed-basiert im Generator, damit Level
      reproduzierbar bleiben.
- [x] **Leere als Gestaltungsmittel:** Boden größtenteils Abgrund (Nebel nach
      unten, kein sichtbarer Grund), wenige, klare Haken-Ziele: Stalaktiten,
      überhängende Felsnasen, frei hängende Felsinseln, Säulen aus der Tiefe.
- [x] **Maßstab spürbar machen:** Spieler klein im Bild (Kamera weiter weg,
      höher), ferne Silhouetten, schwebender Staub, Lichtkegel von oben,
      leuchtende Kristalle als Orientierung statt Fackel-Reihe.
- [x] **Licht und Tiefe:** Wenige große Lichtquellen + Nebel mit Höhenverlauf;
      dunkle Tiefe unten, hellere Decke. Farbkontrast Nähe/Ferne.
- [x] **Physik an den Maßstab anpassen:** (Seil 70 m, Haken bis 90 m/s, Vorschau 50 m/s, Kamera 3,5/10 m, Wurfwinkel-Hilfe) größere Reichweite
      (`max_rope_length` ~70 m), schnellerer Haken, Wurfwinkel evtl. aus dem
      Wischwinkel (steil/flach), Kamera-FOV und Abstand.
- [x] **Level 1–5 als Kavernen neu bauen**, Bot-Test anpassen (Abgrund statt
      Lava, Medaillen neu).
- [x] **Prozedurales Level:** `CaveGenerator` baut aus einem Seed eine faire
      Hallenfolge (Boden-Hallen am Anfang und Ende, 4–6 Hallen dazwischen, nie
      zweimal dieselbe Art, kein Tor zuerst, Checkpoint jede zweite Halle).
      „Daily Cave“ (Seed = Datum, für alle gleich) und „Random Cave“ (neu bei jeder
      Wahl, „New cave“ nach dem Ziel). Medaillen aus Zeitschätzung, am Bot kalibriert
      (Bot ≈ 0,82 × Schätzung über 4 Seeds).
- [x] **Performance prüfen:** (je Halle ein MultiMesh pro Material statt einzelner CSG-Boxen: ~20 Draws, 200–280 Blöcke, 15–38 Lichter ohne Schatten pro Level; FPS auf dem iPhone weiter in TUNE → Misc messen) mehr/größere Geometrie, Nebel; Ziel bleibt 60 fps.

## 3. Spielgefühl: flüssig und befriedigend

- [x] **Seil-Übergabe / Kettenwürfe** (siehe Entscheidung): der Moment, in dem
      der neue Haken greift und das alte Seil loslässt, ist der Kern des Flows.
- [x] **Treffer-Gefühl:** (Hit-Stop 50 ms ab 12 m/s, FOV-Kick 12°, Seil-Zittern) Hit-Stop (40–60 ms Mini-Freeze) beim Einhaken,
      kurzer FOV-Kick beim Zip-Launch, Seil spannt sich sichtbar (zittert kurz).
- [x] **Tempo sichtbar machen:** (Speed-Lines ab 28 m/s, Wind-Streifen, Wind-Tonhöhe) Speed-Lines am Bildrand ab hohem Tempo,
      Wind-Partikel, stärkerer Tempo-Sound (Tonhöhe).
- [x] **Schwingen** (siehe Entscheidung; gemessen in Gängen und Kavernen, Standard 0, Regler `swing_time` bleibt zum Ausprobieren): Pendelphase vor dem Einholen,
      damit es nicht nur geradlinige Zips gibt.
- [x] **Landungen erhalten Schwung:** (`landing_roll`, `slide_friction`, Wall-Kick) Rollen/Rutschen statt harter Bremsung;
      Wand-Abprall (Wall-Kick) beim Auftreffen mit Tempo.
- [x] **Flow-Anzeige:** (ab x2, Haken-Ton steigt mit der Kette, „Longest flow“ im Ziel) Kette von Treffern ohne Bodenberührung zählen
      (z. B. „x5“), dezent im HUD – belohnt flüssiges Spielen.
- [x] **Zielhilfe für Stalaktiten** (durch die Wurfwinkel-Hilfe ersetzt; der Kegel-Assist bleibt als Regler, Standard aus) in der großen Höhle (jetzt aus) testen.
- [x] **Musik:** dezente Loop, die mit dem Tempo intensiver wird. (`tools/gen_music.py`: drei synchrone Spuren – Fläche/Bass/Tropfen, Puls, Arpeggio – A-Moll, 96 BPM, 20 s; Puls ab 6 m/s, Arpeggio ab 26 m/s oder ab Flow x4)

## 3b. Grafik und Atmosphäre

- [x] **Prozedurale Texturen** (`tools/gen_textures.py`, nahtlos, 128 px):
      Fels (Schichten, Risse, Normal-Map), Metall (Platten, Nieten, Rost), Eis
      (Kristallzellen, leuchtende Kanten), Kristall (Facetten, Leuchten),
      Lava-Rauschen, Staubkorn, Lichtkegel, Vignette.
- [x] **Materialbibliothek** (`assets/materials/`): Welt-Triplanar, damit
      Kacheln über alle Blöcke weiterlaufen; Lava als Shader (zwei Rausch-Lagen
      gegeneinander, glühende Risse).
- [x] **Atmosphäre:** flackernde Fackeln und Lava-Licht, Vignette, schwebender
      Staub, weiche Tempo-Spur statt Kästen.
- [x] **Props für die Kavernen:** Lichtkegel (`scenes/props/light_shaft.tscn`),
      leuchtender Kristall (`scenes/props/crystal.tscn`).
- [x] **Lichtkegel, Kristalle, Silhouetten in den Leveln** (mit den Kavernen).

## 4. Speedrun

- [x] **Zwischenzeiten:** (an jedem Checkpoint, grün/rot, und im Ziel gegen die Bestzeit) an Checkpoints „−0,4 s“/„+1,2 s“ gegenüber der
      Bestzeit (grün/rot) – stärkster Antrieb für Wiederholungen.
- [x] **Geist-Delta** im HUD (Sekunden vor/hinter dem Geist an derselben Stelle) (Abstand zum Geist in Metern/Sekunden).
- [x] **Sofort-Neustart** (zwei Finger 0,3 s halten, ohne Neuladen) ohne Ladezeit und mit einem Griff (siehe Bug zum
      Zwei-Finger-Tipp).

- [x] **Pause-Menü:** zeigt Level, Bestzeit und Medaillenziele; Schalter für
      Geist und Ton (gespeichert).

## 5. Technik

- [x] **Bot-Test erweitern:** (Spam: `test_chain`, Timer-Start: `test_input`, Zerquetschen: `test_movement`) prüft auch Spam-Verhalten, Timer-Start und
      Zerquetschen (Regressionen der Bugs oben).
- [x] **Onboarding-Level:** („Tutorial“ als erstes Level, Hinweise je nach Position: Werfen, Kette, Eis, Tor, Lösen/Neustart) kurzer Tutorial-Abschnitt (Werfen, Zip, Eis).

## Auf dem Gerät (nur mit dem iPhone möglich)

- [ ] **Bildrate auf dem iPhone messen** (TUNE → Misc → Debug-Anzeige). Bei
      unter 60 fps: zuerst `stretch_shrink` (Pixelgröße) und die Zahl der
      Kristall-Lichter prüfen.
- [ ] **Neue Standardwerte erspielen:** Seil 70 m, Haken bis 90 m/s,
      Wurfwinkel-Hilfe 14 m, Kamera 3,5/10 m. Abweichungen per **Copy** schicken.
- [ ] **Musik-Lautstärke und Mix** (TUNE → Misc → Music/volume).

## Ideen für Runde 3 (beim Umsetzen aufgefallen)

- **Kamera unter der Decke:** Nach Zips ist man oft knapp unter der Decke; die
  Kamera wird dann auf Spielerhöhe gedrückt. Eine leicht von unten blickende
  Kamera in diesen Momenten könnte den Raum besser zeigen.
- **Bot als Level-Prüfer im Generator:** Daily/Random Caves vor dem Spielen
  einmal headless „anspielen“ lassen ist im Browser zu teuer; stattdessen
  Regeln im Generator weiter schärfen (Abstände zwischen greifbaren Ankern messen).
- **Mehr Hallen-Arten:** Aufwind-Schächte, einstürzende Stalaktiten, Wasserfall
  (Eis-Vorhang), dunkle Hallen nur mit Kristall-Licht.
- **Bestenliste für die Daily Cave** (braucht einen kleinen Server).
- **Seil-Physik sichtbar:** Seil hängt beim Flug des Hakens durch statt gerade.

## Später

- [ ] iOS-App, TestFlight, Game Center (braucht Mac + Apple-Developer-Account).
