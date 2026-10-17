# iOS-Export (M5)

## Voraussetzungen
- Mac mit aktuellem Xcode (App Store)
- Apple-ID. Zum Testen auf dem eigenen Gerät reicht ein kostenloser Account
  (App läuft 7 Tage, dann neu signieren). Für TestFlight/App Store: Apple
  Developer Program, 99 $/Jahr.
- In Godot: Editor → Exportvorlagen verwalten → passende Vorlagen herunterladen

## Schritte
1. Projekt → Exportieren: Das Preset „iOS“ ist schon angelegt
   (`export_presets.cfg`).
2. Bundle Identifier ersetzen (Platzhalter `de.example.grapplingcave`),
   z. B. `de.<name>.grapplingcave`
3. Team-ID aus dem Apple Developer Account eintragen (bei kostenlosem Account
   die ID, die Xcode unter Accounts anzeigt)
4. Icons/Launch Screen können zunächst leer bleiben (Godot generiert Platzhalter)
5. "Projekt exportieren" → erzeugt ein Xcode-Projekt in `build/ios/`
6. Xcode-Projekt öffnen, Signing & Capabilities → Team wählen, iPhone anschließen,
   Run

## Projekt-Einstellungen, die für iOS relevant sind
- `display/window/handheld/orientation` in `project.godot`
  (0 = Querformat, 1 = Hochkant; das Spiel nutzt 1)
- Renderer bleibt "Mobile"
- Pixelgröße: `stretch_shrink` von `World/PixelView` in `scenes/main.tscn`
  (Auto-Qualität erhöht sie bei niedriger Bildrate)
- Safe Area: `SafeArea.margins()` nutzt nativ die vom System gemeldeten Ränder
- Vibration beim Einhaken über `Input.vibrate_handheld` (nativ verfügbar)

## Stolpersteine
- Touch-Events kommen als `InputEventScreenTouch`. `emulate_mouse_from_touch`
  ist an (für die GUI); InputRouter ignoriert die emulierten Mausereignisse.
- Touch-Indizes sind auf iOS beliebige Zahlen, nicht 0, 1, 2.
- Die Safe Area (Notch) beachten: HUD-Elemente mit
  `DisplayServer.get_display_safe_area()` positionieren.
- Beim ersten Export fehlen oft Export-Vorlagen genau für die installierte
  Godot-Version; Version im Editor und beim Vorlagen-Download müssen übereinstimmen.
