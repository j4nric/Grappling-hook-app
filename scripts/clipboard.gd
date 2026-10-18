class_name Clipboard
## Copy and paste text (tuning values, run codes). In the browser, iOS
## Safari above all, both only work inside a real input event handler, and
## Godot handles input a frame later. So both are armed on button_down and
## run in the browser's handler when the finger lifts. Pasting asks for the
## text in a browser dialog (long-press > Paste works there everywhere); the
## answer arrives a moment later, see take_paste().

## A paste was asked for and has not been taken yet.
static var _pending := false
## Native: the clipboard text read when the paste was asked for.
static var _native_paste := ""


static func copy(text: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window.gcCopyText = %s;
			const gcCopy = () => navigator.clipboard.writeText(window.gcCopyText).catch(() => {});
			window.addEventListener('touchend', gcCopy, {once: true, capture: true});
			window.addEventListener('mouseup', gcCopy, {once: true, capture: true});
		""" % JSON.stringify(text))
	else:
		DisplayServer.clipboard_set(text)


## Asks for text to paste (call on button_down); poll take_paste().
static func request_paste(message: String) -> void:
	_pending = true
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window.gcPasteText = undefined;
			const gcPaste = () => { window.gcPasteText = prompt(%s, '') ?? ''; };
			window.addEventListener('touchend', gcPaste, {once: true, capture: true});
			window.addEventListener('mouseup', gcPaste, {once: true, capture: true});
		""" % JSON.stringify(message))
	else:
		_native_paste = DisplayServer.clipboard_get() if DisplayServer.clipboard_has() else ""


## The pasted text once it is there ("" if cancelled), null while waiting
## or when nothing was asked for.
static func take_paste() -> Variant:
	if not _pending:
		return null
	var text: Variant = _native_paste
	if OS.has_feature("web"):
		text = JavaScriptBridge.eval("(() => { const t = window.gcPasteText; window.gcPasteText = undefined; return t ?? null; })()", true)
		if text == null:
			return null
	_pending = false
	return str(text)
