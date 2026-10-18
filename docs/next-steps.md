# Nächste Schritte – Runde 6

Stand: 2026-10-18. Runden 1–6 sind erledigt (PRs #1–#51, Zusammenfassung in
`roadmap.md`, Archiv unten). Runde 5 hat das Grund-Design der Level, die neue
Optik, den Höhlen-Editor und das Teilen gebracht. Ziel dieser Runde: **mehr
Können belohnen, die Höhle lebendiger und abwechslungsreicher machen, den
Fortschritt sichtbar machen** – und die Technik dahinter aufräumen.
Reihenfolge = Umsetzungsreihenfolge, ein PR pro Themengebiet.
Größe: S = klein, M = mittel, L = groß.

## 1. Technik vorab

- [x] **Bot-Messung unabhängig von der Reihenfolge (S):** (umgesetzt: Ursache war
      der globale Zufall – brüchige Stalaktiten wackeln mit `randf` an ihrem
      Kollisionskörper, die Kamera würfelt ihr Wackeln aus demselben Strom.
      `Bot.reset()` setzt jetzt Zufall und Zeitlupe zurück; ein Test prüft, dass
      derselbe Start nach allen anderen Leveln dieselbe Zeit ergibt.) Der Bot liefert je nach
      vorher gelaufenen Tests andere Zeiten (Gates: 42,7 s bei Bronze 46,0 s – knapp).
      Jede Messung in einer frisch geladenen Hauptszene mit zurückgesetztem
      Zufall und gleicher Physik-Phase → gleiche Zeit bei jedem Lauf, Medaillen
      lassen sich sauber neu messen.
- [x] **Testlaufzeit (S):** (umgesetzt: Zeit pro Testdatei in der Ausgabe; die
      Bot-Tests hören beim ersten Lauf innerhalb Bronze auf, `BOT_FULL=1` spielt
      alle Startvarianten für die Medaillen-Messung. Lokal ~40 s für alle 34
      Dateien, davon 20 s Level-Bot und 12 s Zufallshöhlen.) Bot-Tests
      mit früherem Abbruch, wenn eine Variante schon klar gewinnt; Zeiten pro
      Testdatei ausgeben.

## 2. Spielgefühl: Können belohnen

- [x] **Perfekter Kettenwurf (M):** (umgesetzt: Signal `perfect_chain`, 3 Regler im
      Tab Rope mit Skizze, Zähler im Ziel und in der Statistik. Der Bot kam dabei
      in Gates nicht mehr durch – er wählte Anker hinter dem Eis-Tor; jetzt
      sieht er den Schlitz wie ein Spieler. Medaillen neu gemessen.) Greift der neue Haken, während man kurz vor
      dem Zip am alten Anker ist (`perfect_chain_window`), gibt es einen
      Tempo-Schub (`perfect_chain_boost`), goldene Funken, ein „PERFECT“ im HUD
      und einen hellen Ton. Belohnt Timing statt Zufall. Regler im TUNE-Panel
      mit Skizze; Medaillen danach neu messen.
- [x] **Sprungpilze (M):** (umgesetzt: `Bouncer`, Schlüssel `bouncers`, Regler im
      Tab Cave mit Skizze, „Boing“-Ton, Sporen-Partikel, Salto; neue Baukasten-
      Schlüssel ändern die Level-Version nicht mehr, solange sie auf Standard
      stehen – keine Rekorde gehen verloren) neues Element – Riesenpilze auf Böden und Inseln, die
      beim Aufkommen hoch und nach vorn schleudern (`bounce`). Neuer
      Baukasten-Schlüssel `bouncers`, Editor-Regler mit Skizze.

## 3. Level: Abwechslung

- [x] **Kurvige Höhlen (L):** (umgesetzt: Schlüssel `shift`; jedes Bauteil der
      Halle wandert mit, die Übergänge prüfen jede Seite einzeln – Schräge,
      wo die Wand nach innen springt, Rahmen, wo sie nach außen springt;
      bestehende Höhlen bleiben Stück für Stück gleich, geprüft per Abdruck aller
      Kollisionskörper; `Level.lanes` führt den Bot zur Hallenmitte) Hallen mit seitlichem Versatz (`shift`): die Höhle
      windet sich statt schnurgerade zu laufen. Übergänge schließen alles
      außerhalb der gemeinsamen Öffnung; der Bot zielt zur nächsten
      Hallenmitte; Editor-Regler und Skizze (Draufsicht).
- [x] **Abkürzungen (M):** (umgesetzt: Schlüssel `shortcut` = Röhrengröße; Felsriegel
      mit breitem Umweg an einer Seite und 10 m langer Röhre in der Mitte,
      Kristalle markieren die Röhre) aus dem Design-Dokument („Abzweigungen“) – eine enge
      Felsröhre durch eine Trennwand neben dem normalen Weg: kürzer, aber
      riskant (`shortcut`).
- [x] **Neues Level „Winding Rift“ (M):** (umgesetzt: 6 versetzte Hallen, Abkürzung,
      Sprungpilze über Lava, offene Decke; Generator: neue Arten „bounce“ und
      „shortcut“, jede Halle seitlich versetzt) windende Schlucht mit Sprungpilzen,
      Abkürzung und offener Decke; Generator nutzt Versatz und Pilze auch.

## 4. Darstellung: lebendige Höhle

- [x] **Wasserfälle (M):** (umgesetzt: in knapp der Hälfte der Hallen ohne Lava
      und Deckenöffnung, `shaders/waterfall.gdshader`, Nebel am Fuß,
      `amb_water`) fließender Shader an Wänden, Gischt-Partikel am Fuß,
      Rauschen als 3D-Geräusch (`tools/gen_sounds.py`), Deko mit eigenem Zufall.
- [x] **Teilchen in der Luft (S):** (umgesetzt: `Effects.air_for()`; dazu Pollen
      unter offener Decke) Staub und Glühwürmchen um die Kamera, je Halle
      anders (Lava: Glut, Eis: Schneeflocken, dunkle Halle: Glühwürmchen).
- [x] **Lava, die fließt (M):** (umgesetzt: unterteilte Fläche mit langsamer
      Dünung im Shader, pulsierendes Glühen, aufsteigende Glut) Lava-Shader mit Strömung und Pulsieren, Glutblasen.
- [x] **Ausgang ins Tageslicht (S):** (umgesetzt: Bogen mit Himmel-Shader hinter
      dem Ziel, Lichtstrahlen, warmes Licht) das Ziel als Höhlenausgang – helles Licht,
      Lichtstrahlen, Himmel; die Ziel-Kamerafahrt zeigt ihn.

## 5. Motivation und Fortschritt

- [x] **Fortschritt im Level-Menü (S):** (umgesetzt: farbige Medaillen-Marke vor
      jedem Level, Zeile mit Gold/Silber/Bronze und Daily-Serie) Medaillen als farbige Marken je Level,
      Summe Gold/Silber/Bronze, Daily-Cave-Serie (Tage in Folge).
- [x] **Zwischenzeiten im Ziel (S):** (umgesetzt) Tabelle der Checkpoints mit Zeit und
      Abstand zur Bestzeit.
- [x] **Farben für die Figur (M):** (umgesetzt: 6 Outfits in `Outfits.LIST`,
      freigespielt durch Medaillen; Pause-Menü „Outfit“ zeigt, was das nächste braucht) Anzug- und Schalfarben, freigespielt durch
      Medaillen; Auswahl im Pause-Menü.
- [x] **Daten sichern (S):** (umgesetzt: Stats-Bildschirm „Backup“/„Restore“, Code
      `GCB1:`; Geister bleiben zurück; beim Einlesen nur einfache Werte) Bestzeiten, Statistik und Tuning als Code
      kopieren und woanders einfügen – z. B. von Safari in die App auf dem
      Home-Bildschirm (die haben getrennte Speicher).

## 6. Optimierung

- [x] **Shader aufwärmen (S):** (umgesetzt: `Effects.warm_up()` beim Start hinter
      dem Schwarz: alle Effekte einmal, alle Level-Materialien und Shader einmal
      gezeichnet, nach 4 Ticks wieder weg) Im Browser ruckelt der erste Funke, Zip-Burst
      oder Ring, weil Shader erst dann kompiliert werden. Beim Laden alle
      Effekt-Materialien einmal unsichtbar zeichnen.
- [x] **Ladezeit und Paketgröße (S):** (gemessen: Spielpaket 1,7 MB – Musik 0,5 MB,
      Sounds, Texturen –, keine ungenutzten Dateien; die Engine `index.wasm` hat
      39,5 MB und bestimmt die Ladezeit. Der Service Worker lädt die Engine jetzt
      aus einem eigenen Cache, benannt nach ihrem Hash: ab dem zweiten Start
      wartet nichts mehr auf das Netz, eine neue Godot-Version bringt einen neuen
      Cache. Geprüft im Browser: zweiter Start und offline aus dem Cache.)
      Web-Paket messen, Texturen/Sounds/Musik prüfen, Unnötiges ausschließen.
- [x] **game.gd aufteilen (M):** (umgesetzt: 722 → 608 Zeilen; Lauf-Codes und
      Rivale in `Sharing`, Stats-Bildschirm, Medaillen-Zeile und Backup in
      `Progress` – eigene Knoten in `main.tscn`) Die Datei war auf ~700 Zeilen gewachsen.
- [x] **Abschluss-Doku (S):** CLAUDE.md, README, roadmap, next-steps.

## Auf dem Gerät (nur mit dem iPhone möglich)

- [ ] **Bildrate auf dem iPhone messen** (TUNE → Misc → Debug-Anzeige), vor allem
      in Wide Cave und Skyway.
- [ ] **Perfekter Kettenwurf und Sprungpilze** anspielen: Schub zu stark/schwach?

## Ideen für Runde 7

- [ ] **Gold-Geist:** Bot-Läufe als mitgelieferter Geist in Medaillen-Tempo.
- [ ] **Mehr Level mit den neuen Bausteinen** (Kurven, Abkürzungen, Pilze) –
      nach deinem Feedback zu Winding Rift.
- [ ] **Abkürzungen im Generator häufiger**, wenn sie sich bewähren.
- [ ] **Bot und Physik-Engine:** die erste Fahrt nach dem Laden weicht ab
      (Engine-Zustand); für exakte Wiederholbarkeit jeden Bot-Lauf in einer
      frisch geladenen Hauptszene.

## Später

- [ ] iOS-App, TestFlight, Game Center (braucht Mac + Apple-Developer-Account).
- [ ] Bestenliste für die Daily Cave (braucht einen Server).
- [ ] Rivalen-Geist aus Bot-Läufen als „Gold-Geist“ mitliefern.

## Archiv: Runde 5

### 1. Level-Design (Kern der Runde)

- [x] **Höhlen-Editor im TUNE-Panel (L):** (umgesetzt: Tab „Cave“ mit 23 Reglern
      pro Halle, inkl. offener Decke und schwebender Steine; Skizzen: Querschnitt,
      Draufsicht aller Hallen, Seitenansicht; Edits bleiben gespeichert und haben
      eigene Rekorde; „Copy layout“, „Reset cave“) neuer Tab „Cave“ mit Reglern für die
      Wide Cave – Hallenbreite, Deckenhöhe, Hallenlänge, Stalaktiten, Inseln,
      Säulen, Licht, Seed. Die Höhle baut sich beim Loslassen neu (Aufbau dauert
      2–5 ms), „Copy“ schickt das Layout als Text. So wird Level-Design wie
      Physik-Tuning direkt am Handy gemacht.
- [x] **Licht für breite Hallen (M):** (umgesetzt: Deckenkristalle als Lichtlinie
      in Hallen ab 50 m Breite) Die Wide Cave ist dunkel, weil die Lichter
      an den Wänden sitzen und die Wände 40 m weg sind. Licht entlang der
      Flugbahn (Deckenkristalle, Lichtkegel in der Mitte) und ein Leitlicht zum
      Ausgang.
- [x] **Level an die neue Reichweite anpassen (M):** (umgesetzt: alle Level breiter
      und höher nach dem Vorbild der Wide Cave, Entscheidung 3) Haken fliegen jetzt fast
      gerade (`hook_gravity` 3) bis 68 m; viele Hallen sind dafür zu kurz und
      zu niedrig. Abstände zwischen Ankerzonen, Hallenlängen und Deckenhöhen
      neu ausloten – erst in der Wide Cave, dann übertragen.
- [x] **Hallen-Vorlagen als Design-Vokabular (M):** (umgesetzt: start, sprint,
      slalom, cathedral, narrows, skyway, lava_lake, ice_vault; Level und
      Generator nutzen sie; neues Level „Skyway“ mit offenen Decken) wenige benannte Hallentypen
      mit klarer Aufgabe (Sprint: lang und hoch; Slalom: Säulen versetzt;
      Kathedrale: sehr hoch, Ringe; Engstelle: schmal und niedrig, schräg
      angeschlossen). Level und Generator setzen sich daraus zusammen.
- [x] **Orientierung (S):** (umgesetzt: Bernstein-Marke am Ausgang jeder Halle) Landmarken und ein sichtbarer Ausgang je Halle, damit
      man in breiten Hallen die Richtung nicht verliert.
- [x] **Tempo-Ringe auf der Ideallinie (S):** (umgesetzt: nahe der Mitte, auf der
      Höhe der Schwünge) zwischen zwei Ankerzonen statt
      zufällig in der Hallenmitte.

- [x] **Neue Optik (Wunsch):** Felsmodelle statt Quader (Brocken, Stalaktiten,
      Säulen), neue Texturen (Moos, nasser Fels, Adergestein, Wurzeln, Pilze,
      Bernstein), leuchtende Pilze, hängende Wurzeln.
- [x] **Offene Decke (Wunsch):** Hallen ohne Decke; schwebende Steine in einer
      Zickzack-Bahn, an denen man sich entlanghangelt; glatte Wände.
- [x] **Neu entdeckt:** Alle leuchtenden Materialien (auch Kristalle und Eis seit
      Runde 2) waren fast weiß: Godot addiert Emissionsfarbe (weiß) und Textur.
      Emissionsfarbe jetzt schwarz; das Eis-Leuchten aus Runde 3 wieder auf 0,8.
- [x] **Neu entdeckt:** Übergang aus einer offenen Halle in eine niedrigere baute
      eine 100 m lange Schräge über die ganze offene Halle → kurze Schräge ab der
      Schwebe-Ebene plus Stirnwand bis zum Gewölbe.
- [x] **Neu entdeckt:** Die Zeit-Skizze im TUNE-Panel nutzte `%g` (gibt es in
      GDScript nicht) – Achsenbeschriftung fehlte.

- [x] **Neu entdeckt:** Wird eine Halle breiter oder höher, blieb der Rahmen um
      die kleinere Öffnung offen: Der Bot flog hinter die Wände ins Leere (bei
      x = −82 in einer 91 m breiten Halle). Jetzt schließt ein Rahmen die Lücke
      (`tests/test_flow.gd` prüft es auch in Zufallshöhlen).
- [x] **Neu entdeckt:** Die Schräge aus einer offenen Halle lag mit ihrer Oberseite
      frei in der Luft – man konnte darauf stehen und kam ohne Hakenziel nicht
      mehr weg. Aus offenen Hallen gibt es keine Schräge mehr.
- [x] **Neu entdeckt:** Bot-Zeiten hängen davon ab, was vorher lief (gleicher
      Start, anderes Ergebnis) – Medaillen aus der besten Zeit mehrerer Läufe,
      Bronze für Zufallshöhlen großzügiger (2,1× der Schätzung).

### 2. Spielgefühl

- [x] **Seilende (S):** Mit `min_rope_length` 9,25 m > `zip_release_distance`
      5,5 m endete der Zug hängend, man konnte um den Anker kreisen
      (Kegelpendel; der Bot blieb so hängen). Jetzt löst das Seil am kürzesten
      Punkt wie ein Zip (`rope_end_release`, Regler „Rope end release“).
- [x] **Tuning-Presets (M):** (umgesetzt: Sätze A/B/C im TUNE-Panel, ein neuer Satz
      startet als Kopie; „Paste“ liest kopierte Werte oder eine getippte Liste) mehrere Wertesätze speichern und mit einem Tipp
      wechseln (A/B-Vergleich), Werte als Code einfügen statt nur kopieren.
- [x] **Tutorial an die neue Physik anpassen (S):** (umgesetzt: breitere, höhere
      Hallen bei gleichen Längen, damit die Hinweise an ihren Stellen bleiben) Hinweise und Abstände
      stammen aus der alten, langsameren Physik (Bot jetzt 7,5 s).

### 3. Speedrun und Motivation

- [ ] ~~**Medaillen aus echten Läufen (M):**~~ (Entscheidung 4: nein, Medaillen bleiben aus Bot-Zeiten) Der Bot spielt anders als ein Mensch
      (keine Zeitlupe, keine Zielhilfe). Deine Bestzeiten als „Dev-Zeit“ und
      Referenz-Geist mitliefern; Medaillen daraus ableiten.
- [x] **Replay teilen (M):** (umgesetzt: Pause → „Share run“ kopiert die Bestzeit
      als Code, ~1–2 KB; „Load run“ lädt das Level und zeigt den Lauf als orangen
      Rivalen-Geist, Rivalen-Zeit im Pause-Menü und im Ziel; auch Daily/Random
      Caves anderer Tage) Lauf als kurzer Text-Code, als Geist eines Freundes
      laden (ohne Server).
- [x] **Statistik-Verlauf (S):** (umgesetzt: Kurve der letzten 50 Zielzeiten je
      Level im Stats-Bildschirm, Gold-Linie = Bestzeit bis dahin) Bestzeit pro Level über die Zeit als kleine Kurve.

### 4. Präsentation

- [ ] ~~**Sound-Mix überarbeiten (M):**~~ (Entscheidung 2: alles gut, bleibt so)
- [x] **Sturz als Ragdoll (M):** (umgesetzt: die Figur fliegt bei Lava/Absturz
      schlaff weiter und überschlägt sich 0,7 s, dann Abblende zum Checkpoint;
      der Timer steht in der Zeit still, `fall_show_time` in `game.gd`) Die Figur fällt bei Lava/Absturz schlaff,
      statt hart zu verschwinden.
- [x] **Hall je Halle (S):** (umgesetzt: Bus „Cave“ mit Reverb, Raumgröße und
      Anteil folgen der Halle, in der man ist; offene Hallen hallen weniger, der
      Wind bleibt trocken) große Hallen mehr Nachhall als enge Gänge.

### 5. Technik und Qualität

- [x] **Test-Profil statt Standardwerte (M):** (umgesetzt: `TEST_TUNING` in
      `tests/test_case.gd` für alle Tests in den Testtunneln) Mechanik-Tests liefen mit den
      Standardwerten und brauchten nach jeder Übernahme von Handy-Werten
      Anpassungen (PR #36: 15 Tests). Ein festes Test-Tuning für Mechanik-Tests,
      Standardwerte nur noch in Level- und Bot-Tests.
- [x] **Bot an die neue Physik (M):** (umgesetzt: jede Startvariante bekommt eine
      eigene Richtungsvorliebe, `Bot.reset(variant)`; beste von 5 Starts) Der Bot nutzt weder Zeitlupe noch
      Zielhilfe, und Startverzögerungen ändern in prozeduralen Höhlen nichts
      (gleiche Zeit bei jedem Start) – Varianten über die Wurfrichtung statt
      über den Start.
- [x] **Leistung in breiten Hallen (S):** (gemessen im Browser-Build an festen
      Standpunkten: Wide Cave 108–111 Draw-Calls, Skyway 83–119, dagegen Gates
      162, Tutorial 144, Lava Deep 129; je 9–13 k Dreiecke, höchstens 10 Lichter.
      Breite Hallen sind nicht teurer – die Felsmodelle laufen als MultiMesh, die
      Sichtweite schneidet weit Entferntes ab. Nichts zu tun.) mehr Fläche und Lichter im Bild;
      Browser-Messung wie in Runde 3 wiederholen.

### Entscheidungen (Runde 5)

1. Seil löst am kürzesten Punkt automatisch (Zip): **ja** (umgesetzt).
2. Sound: **alles gut**, kein Umbau.
3. Wide Cave als Vorlage für alle Level: **ja** (umgesetzt).
4. Medaillen aus deinen Läufen: **nein**, sie bleiben aus Bot-Zeiten.


## Archiv: Runde 3 und 4

### 1. Bugs und Aufräumen

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

### 2. Leistung

- [x] **Licht-LOD:** bis zu 42 Lichter pro Level (Random Cave #48213), der
      Compatibility-Renderer nimmt pro Objekt höchstens 8 → Lichter flackern an
      Hallengrenzen und kosten Zeit. → Lichtmanager: nur die nächsten N Lichter
      an, weich ein- und ausblenden. (Umgesetzt: höchstens 10 Lichter im Umkreis
      von 90 m; Browser-Vergleich mit Software-Rendering: 4,4–6,0 → 9,0–9,2 fps.)
- [x] **Sichtweite für Deko:** Kristalle, Lichtkegel und Staub weit hinten im
      Nebel nicht zeichnen (`visibility_range`).
- [x] **Messbar machen:** Leistungs-Test (Lichter aktiv, Draw-Objekte im Bild,
      Aufbauzeit) und ein Browser-Benchmark im Bot-Build als Vergleichswert.

### 3. Figur und Seil (Schwunggefühl sichtbar machen)

- [x] **Gelenkfigur statt Kapsel:** Rumpf, Kopf, Arme, Beine, Rucksack; Posen
      nach Zustand: Arm greift zum Anker, Beine schwingen nach, Salto beim
      Zip, Hocke bei der Landung, Ziel-Haltung beim Zielen.
- [x] **Schal als Verlet-Band:** zeigt Tempo und Richtung, flattert im Wind.
- [x] **Seil als Verlet-Kette:** hängt beim Flug des Hakens durch, strafft sich
      beim Einhaken, schlängelt nach dem Lösen zurück.

### 4. Neue Hallen-Mechaniken

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

### 5. Kamera-Regie

- [x] **Unter der Decke:** Nach Zips hängt man knapp unter der Decke; die Kamera
      senkt sich dann und blickt leicht nach oben, damit die Halle sichtbar bleibt.
- [x] **Ziel-Kamera:** Zeitlupe beim Durchfliegen des Ziels, die Kamera schwenkt
      um den Spieler.
- [x] **Respawn-Blende:** kurzes Abblenden statt hartem Sprung beim Tod.

### 6. Raumklang

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

### 7. Replays und Statistik

- [x] **Replay der Bestzeit:** im Ziel „Replay“ – Kamera folgt dem
      aufgezeichneten Lauf (Position, Seil, Anker). Der Geist zeichnet dafür
      auch den Anker auf; alte Geister (nur Positionen) spielen ohne Seil.
- [x] **Statistik:** Läufe, Meter, Haken, längster Flow, Spielzeit – gesamt und
      pro Level, im Menü („Stats“). Daily und Random Caves zählen je als eine
      Gruppe.
- [x] **Neu entdeckt:** Ein Neustart aus dem Lauf heraus zählte nirgends –
      Statistik wird jetzt bei Ziel, Neustart, Levelwechsel und beim Wechsel in
      den Hintergrund geschrieben (nicht jeden Frame: IndexedDB im Browser).

### 8. Web-App

- [x] **Installierbar (PWA):** Manifest, Icon, Offline-Cache, Vollbild ohne
      Safari-Leisten, wenn vom Home-Bildschirm gestartet. In Safari auf dem
      iPhone zeigt das Level-Menü, wie man installiert.
- [x] **Neu entdeckt:** Godots eingebauter PWA-Service-Worker liefert die Seite
      aus dem Cache – neue Builds kämen erst nach einem Neustart der App an.
      Eigener Service Worker (`web/sw.js`): Netz zuerst, Cache nur ohne Netz;
      er speichert beim Installieren alle Dateien des Builds, sodass schon der
      erste Besuch offline spielbar macht.
- [x] **Neu entdeckt:** Der Service Worker von `main` gilt für die ganze Seite,
      also auch für `/preview/` – er übergeht Dateien in Unterordnern, jede
      Vorschau hat ihren eigenen.
- [x] **Neu entdeckt:** Level-Menü-Titel stieß an den TUNE-Knopf, HUD schien
      durch → Abstand oben, deckender Hintergrund.

Hinweis: Auf dem iPhone hat die installierte App einen eigenen Speicher –
Bestzeiten aus Safari sind dort nicht zu sehen (iOS trennt das, nicht änderbar).

### Auf dem Gerät (nur mit dem iPhone möglich)

- [ ] **Bildrate auf dem iPhone messen** (TUNE → Misc → Debug-Anzeige).
- [ ] **Neue Standardwerte erspielen** und per **Copy** schicken.

### Runde 4 – Feedback vom Handy (2026-10-18)

- [x] **Zu viele Hindernisse:** Stalaktiten halbiert und auf höchstens 8 m
      gekürzt (vorher 13 m), Felsvorsprünge halbiert, eine Säule weniger pro
      Halle, Generator entsprechend. Bot-Zeiten sanken deutlich (First Swing
      11,4 → 7,7 s, Lava Deep 17,2 → 11,4 s, Ice Ceiling 19,7 → 9,9 s),
      Medaillen neu kalibriert.
- [x] **Kanten in der Decke:** Decke und Wände sind nur noch optisch rau; die
      Kollision ist flach (Unterkante exakt auf Deckenhöhe, Eis bleibt Eis).
      Gleiten an der Decke behält das Tempo (`tests/test_flow.gd`).
- [x] **Neu entdeckt:** Auf der glatten Decke gleitet man bis vor den
      Eis-Sturz über dem Tor-Schlitz und bleibt dort hängen (Bot schaffte
      „Gates“ nicht mehr) → Tor-Schlitz reicht jetzt bis zur Decke.
- [x] **Breites Arbeitslevel „Wide Cave“:** Hallen 80–90 m breit, Decke bis
      36 m, kaum Hindernisse; erster Eintrag im Level-Menü. Hier wird das
      Grund-Design der Level weiterentwickelt.
- [x] **Einstellungen verständlich:** Jeder TUNE-Regler hat einen Klarnamen
      mit Einheit, eine kurze Erklärung und eine kleine animierte Skizze, die
      mit den aktuellen Werten zeichnet (Antippen eines Reglers oder Namens
      zeigt sie oben im Panel; der technische Name steht darunter, für Copy).

### Ideen aus Runde 3 (in Runde 5 übernommen)

- [ ] **Hall je Halle:** große Hallen mehr Nachhall als enge Gänge (zwei
      Varianten je Sound backen, nach Hallengröße wählen).
- [ ] **Sturz als Ragdoll:** Die Gelenkfigur fällt bei Lava/Absturz schlaff,
      statt hart zu verschwinden (Blende bleibt).
- [ ] **Replay teilen:** Lauf als kurzer Text-Code exportieren, als Geist eines
      Freundes laden (ohne Server).
- [ ] **Statistik-Verlauf:** Bestzeit pro Level über die Zeit (kleine Kurve).
- [ ] **Tempo-Ringe im Generator ausrichten:** Ringe auf der Ideallinie zwischen
      zwei Ankern statt zufällig in der Hallenmitte.
