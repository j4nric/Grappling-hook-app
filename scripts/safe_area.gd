class_name SafeArea
## Screen insets (notch, Dynamic Island, home indicator) in viewport units, so
## HUD elements can stay clear of them. Natively the OS reports the safe area;
## in the browser it is usually the full screen, so minimum margins apply too.

## Minimum top and bottom margins (viewport units, 720 px wide screen).
const MIN_TOP := 12.0
const MIN_BOTTOM := 40.0


## Returns Vector4(left, top, right, bottom) margins in viewport units.
static func margins(viewport: Viewport) -> Vector4:
	var window := Vector2(DisplayServer.window_get_size())
	var visible := viewport.get_visible_rect().size
	var result := Vector4(0, MIN_TOP, 0, MIN_BOTTOM)
	if window.x <= 0 or window.y <= 0:
		return result
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0 or safe.size.y <= 0:
		return result
	var scale := visible / window
	result.x = maxf(result.x, safe.position.x * scale.x)
	result.y = maxf(result.y, safe.position.y * scale.y)
	result.z = maxf(result.z, (window.x - safe.end.x) * scale.x)
	result.w = maxf(result.w, (window.y - safe.end.y) * scale.y)
	return result
