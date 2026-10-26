extends Control

const BankGameModel = preload("res://scripts/game/bank_game.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansArabic-Regular.ttf")
const EMOJI_FONT = preload("res://assets/fonts/NotoColorEmoji.ttf")
const LOCALE_FILE := "res://localization/luckbank.json"
const SAVE_FILE := "user://luckbank-save.json"
const SETTINGS_FILE := "user://luckbank-settings.cfg"

const BG := Color("#3b2418")
const PANEL := Color("#fbf1d9")
const PANEL_ALT := Color("#ead6b0")
const TEXT := Color("#34261c")
const MUTED := Color("#75604c")
const GOLD := Color("#a96a2c")
const GREEN := Color("#3d9968")
const BLUE := Color("#397e9c")
const RED := Color("#b74e45")
const GROUP_COLORS := [Color("#d28a4b"), Color("#5d9db3"), Color("#9c79b5"), Color("#ce7060"), Color("#c76c91"), Color("#78a55d")]
const PLAYER_COLORS := [Color("#238bd0"), Color("#d83f48"), Color("#20a978"), Color("#c7962f")]
const PLAYER_SYMBOLS := ["●١", "◆٢", "▲٣", "■٤"]
const LOCALE_IDS := ["ar", "en", "es", "fr"]

class DiceFace extends Control:
	var face_value := 1

	func set_face(value: int) -> void:
		face_value = clampi(value, 1, 6)
		queue_redraw()

	func _draw() -> void:
		var inset := minf(size.x, size.y) * 0.10
		var die_rect := Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = Color("#000000", 0.32)
		shadow.set_corner_radius_all(int(size.x * 0.16))
		draw_style_box(shadow, Rect2(die_rect.position + Vector2(0, size.y * 0.035), die_rect.size))
		var die := StyleBoxFlat.new()
		die.bg_color = Color("#fffaf0")
		die.border_color = Color("#8f6a36")
		die.set_border_width_all(maxi(2, int(size.x * 0.035)))
		die.set_corner_radius_all(int(size.x * 0.16))
		draw_style_box(die, die_rect)
		var left := Vector2(0.25, 0.25)
		var middle_left := Vector2(0.25, 0.5)
		var right := Vector2(0.75, 0.75)
		var middle_right := Vector2(0.75, 0.5)
		var top_right := Vector2(0.75, 0.25)
		var bottom_left := Vector2(0.25, 0.75)
		var center := Vector2(0.5, 0.5)
		var points: Array[Vector2] = []
		match face_value:
			1: points = [center]
			2: points = [left, right]
			3: points = [left, center, right]
			4: points = [left, top_right, bottom_left, right]
			5: points = [left, top_right, center, bottom_left, right]
			6: points = [Vector2(0.25, 0.25), middle_left, bottom_left, top_right, middle_right, right]
		var radius := minf(die_rect.size.x, die_rect.size.y) * 0.085
		for point in points:
				draw_circle(die_rect.position + Vector2(point.x * die_rect.size.x, point.y * die_rect.size.y), radius, Color("#273a43"))

class PlayerToken extends Control:
	var token_color := Color.WHITE
	var is_computer := false

	func configure(color: Color, computer: bool) -> void:
		token_color = color
		is_computer = computer
		queue_redraw()

	func _draw() -> void:
		var w := minf(size.x, size.y)
		var c := size * 0.5
		var outline := Color("#14212a")
		if is_computer:
			draw_line(Vector2(c.x, 1), Vector2(c.x, 4), outline, 2.0, true)
			draw_circle(Vector2(c.x, 1.5), 1.5, token_color.lightened(0.35))
			var body := Rect2(Vector2(c.x - w * 0.34, c.y - w * 0.28), Vector2(w * 0.68, w * 0.62))
			draw_rect(body, token_color, true)
			draw_rect(body, outline, false, 1.4)
			draw_rect(Rect2(Vector2(c.x - w * 0.20, c.y - w * 0.08), Vector2(w * 0.11, w * 0.10)), Color.WHITE, true)
			draw_rect(Rect2(Vector2(c.x + w * 0.08, c.y - w * 0.08), Vector2(w * 0.11, w * 0.10)), Color.WHITE, true)
			draw_rect(Rect2(Vector2(c.x - w * 0.25, c.y + w * 0.35), Vector2(w * 0.50, w * 0.12)), outline, true)
		else:
			draw_circle(Vector2(c.x, c.y - w * 0.20), w * 0.18, outline)
			draw_circle(Vector2(c.x, c.y - w * 0.20), w * 0.13, token_color.lightened(0.12))
			var body := PackedVector2Array([Vector2(c.x - w * 0.12, c.y - w * 0.07), Vector2(c.x + w * 0.12, c.y - w * 0.07), Vector2(c.x + w * 0.25, c.y + w * 0.28), Vector2(c.x - w * 0.25, c.y + w * 0.28)])
			draw_colored_polygon(body, outline)
			var fill := PackedVector2Array([Vector2(c.x - w * 0.08, c.y - w * 0.04), Vector2(c.x + w * 0.08, c.y - w * 0.04), Vector2(c.x + w * 0.18, c.y + w * 0.23), Vector2(c.x - w * 0.18, c.y + w * 0.23)])
			draw_colored_polygon(fill, token_color)
			var base := Rect2(Vector2(c.x - w * 0.36, c.y + w * 0.27), Vector2(w * 0.72, w * 0.18))
			draw_rect(base, token_color, true)
			draw_rect(base, outline, false, 1.3)

class CornerArt extends Control:
	var art_kind := ""

	func configure(kind: String) -> void:
		art_kind = kind
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var s := minf(size.x, size.y)
		var ink := Color("#f7e7bd")
		var accent := Color("#f1c66a")
		if art_kind == "start":
			draw_circle(c, s * 0.34, Color("#f1c66a", 0.18))
			draw_arc(c, s * 0.32, 0.0, TAU, 24, accent, maxf(2.0, s * 0.035), true)
			draw_line(c - Vector2(0, s * 0.22), c + Vector2(0, s * 0.22), ink, maxf(2.0, s * 0.035), true)
			draw_line(c - Vector2(s * 0.22, 0), c + Vector2(s * 0.22, 0), ink, maxf(2.0, s * 0.035), true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.26), c + Vector2(s * 0.24, -s * 0.18), c + Vector2(0, -s * 0.10)]), accent)
		elif art_kind == "jail":
			var frame := Rect2(c - Vector2(s * 0.34, s * 0.31), Vector2(s * 0.68, s * 0.62))
			draw_rect(frame, Color("#f07f75", 0.18), true)
			draw_rect(frame, ink, false, maxf(2.0, s * 0.035))
			for bar in range(4):
				var x := frame.position.x + s * (0.12 + bar * 0.17)
				draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), accent, maxf(2.0, s * 0.03), true)
			draw_circle(Vector2(c.x, frame.position.y + s * 0.18), s * 0.07, ink)
			draw_arc(Vector2(c.x, frame.position.y + s * 0.38), s * 0.14, PI, TAU, 12, ink, maxf(2.0, s * 0.03), true)
		elif art_kind == "tax":
			var receipt := Rect2(c - Vector2(s * 0.22, s * 0.30), Vector2(s * 0.44, s * 0.60))
			draw_rect(receipt, Color("#fff2d4"), true)
			draw_rect(receipt, ink, false, maxf(1.5, s * 0.025))
			for line_index in range(3):
				var y := receipt.position.y + s * (0.18 + line_index * 0.13)
				draw_line(Vector2(receipt.position.x + s * 0.07, y), Vector2(receipt.end.x - s * 0.07, y), accent, maxf(1.5, s * 0.025), true)
			draw_circle(Vector2(c.x, receipt.end.y - s * 0.08), s * 0.06, Color("#e07a58"))
		elif art_kind == "event":
			draw_circle(c, s * 0.29, Color("#f1c66a", 0.18))
			draw_arc(c, s * 0.29, 0.0, TAU, 24, accent, maxf(2.0, s * 0.035), true)
			draw_line(c + Vector2(-s * 0.14, -s * 0.10), c + Vector2(s * 0.14, -s * 0.10), ink, maxf(2.0, s * 0.04), true)
			draw_line(c + Vector2(0, -s * 0.10), c + Vector2(0, s * 0.10), ink, maxf(2.0, s * 0.04), true)
			draw_circle(c + Vector2(0, s * 0.18), s * 0.025, ink)
		elif art_kind == "rest":
			var cup := Rect2(c - Vector2(s * 0.25, s * 0.13), Vector2(s * 0.42, s * 0.27))
			draw_rect(cup, Color("#f1c66a", 0.28), true)
			draw_rect(cup, ink, false, maxf(2.0, s * 0.035))
			draw_arc(Vector2(cup.end.x, c.y), s * 0.11, -PI * 0.5, PI * 0.5, 12, ink, maxf(2.0, s * 0.03), true)
			draw_line(Vector2(cup.position.x - s * 0.06, cup.end.y + s * 0.08), Vector2(cup.end.x + s * 0.07, cup.end.y + s * 0.08), accent, maxf(2.0, s * 0.035), true)
			for steam_x in [-0.10, 0.08]:
				draw_arc(c + Vector2(s * steam_x, -s * 0.22), s * 0.08, PI, TAU, 10, ink, maxf(1.5, s * 0.025), true)
		else:
			draw_circle(c, s * 0.30, Color("#6bb7ff", 0.16))
			draw_arc(c, s * 0.29, 0.0, TAU, 24, ink, maxf(2.0, s * 0.035), true)
			draw_line(c + Vector2(-s * 0.29, 0), c + Vector2(s * 0.29, 0), accent, maxf(1.5, s * 0.025), true)
			draw_arc(c, s * 0.18, 0.0, TAU, 20, accent, maxf(1.5, s * 0.025), true)

class WorldMapArt extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color(1.0, 1.0, 1.0, 0.26)
		queue_redraw()

	func _draw() -> void:
		var c := Color("#6ba7ae")
		var w := size.x
		var h := size.y
		var shapes := [
			PackedVector2Array([Vector2(w * .08, h * .28), Vector2(w * .20, h * .17), Vector2(w * .31, h * .22), Vector2(w * .27, h * .43), Vector2(w * .17, h * .48), Vector2(w * .11, h * .40)]),
			PackedVector2Array([Vector2(w * .29, h * .53), Vector2(w * .39, h * .48), Vector2(w * .49, h * .56), Vector2(w * .46, h * .77), Vector2(w * .36, h * .85), Vector2(w * .31, h * .70)]),
			PackedVector2Array([Vector2(w * .48, h * .22), Vector2(w * .59, h * .16), Vector2(w * .70, h * .25), Vector2(w * .67, h * .43), Vector2(w * .58, h * .46), Vector2(w * .52, h * .36)]),
			PackedVector2Array([Vector2(w * .64, h * .54), Vector2(w * .79, h * .48), Vector2(w * .91, h * .58), Vector2(w * .84, h * .76), Vector2(w * .72, h * .80), Vector2(w * .66, h * .69)])
		]
		for shape: PackedVector2Array in shapes:
			draw_colored_polygon(shape, c)
			draw_polyline(shape, Color(c, 0.42), 1.5, true)

class AvatarIcon extends Control:
	var avatar_color := Color.WHITE

	func configure(color: Color) -> void:
		avatar_color = color
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.44
		draw_circle(center, radius, avatar_color)
		draw_circle(center + Vector2(0, -radius * .22), radius * .20, Color("#ffffff"))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-radius * .38, radius * .39), center + Vector2(radius * .38, radius * .39),
			center + Vector2(radius * .23, radius * .02), center + Vector2(-radius * .23, radius * .02)
	]), Color("#ffffff"))

var locale_data: Dictionary = {}
var catalogs: Dictionary = {}
var locale := "ar"
var settings := {"fast_cpu": false}
var game
var screen_name := "home"
var resume_available := false
var startup_notice := ""
var current_mode := BankGameModel.MODE_COMPUTER
var cpu_delay := 0.62
var cpu_running := false
var animation_lock := false
var animated_positions: Array[int] = []
var tile_buttons: Array[Button] = []
var tile_labels: Array[Label] = []
var tile_id_labels: Array[Label] = []
var tile_value_labels: Array[Label] = []
var tile_token_rows: Array[HBoxContainer] = []
var tile_corner_art: Array[CornerArt] = []
var player_tokens: Array[PlayerToken] = []
var dice_face: DiceFace
var player_cards: Array[Dictionary] = []
var name_inputs: Array[LineEdit] = []
var name_rows: Array[Control] = []
var selected_tile := 0
var last_landed_player_id := 0
var last_feedback := ""
var last_feedback_color := GOLD

var mode_option: OptionButton
var player_count_option: OptionButton
var difficulty_option: OptionButton
var duration_option: OptionButton
var language_option: OptionButton
var fast_cpu_option: CheckBox
var status_turn_label: Label
var status_round_label: Label
var status_phase_label: Label
var dice_value_label: Label
var feedback_label: Label
var event_log_label: Label
var tile_detail_label: Label
var purchase_panel: PanelContainer
var purchase_description: Label
var buy_button: Button
var skip_button: Button
var obligation_panel: PanelContainer
var obligation_content: VBoxContainer
var result_panel: PanelContainer
var result_content: VBoxContainer
var roll_button: Button
var end_turn_button: Button
var board_surface: Control
var center_panel: PanelContainer
var center_content: VBoxContainer
var portfolio_button: Button
var more_button: Button
var tile_info_button: Button
var main_column: VBoxContainer
var app_theme: Theme
var ui_font: FontFile

func _ready() -> void:
	_load_catalogs()
	_load_settings()
	game = BankGameModel.new()
	_setup_theme()
	_check_saved_match()
	_show_home()

func _load_catalogs() -> void:
	var file := FileAccess.open(LOCALE_FILE, FileAccess.READ)
	if file == null:
		push_error("Missing embedded game translations: " + LOCALE_FILE)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		catalogs = parsed
	locale_data = catalogs.get(locale, catalogs.get("ar", {}))

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		settings["fast_cpu"] = bool(config.get_value("game", "fast_cpu", false))
		var saved_locale := str(config.get_value("game", "locale", "ar"))
		if catalogs.has(saved_locale):
			locale = saved_locale
	cpu_delay = 0.24 if bool(settings["fast_cpu"]) else 0.62
	locale_data = catalogs.get(locale, catalogs.get("ar", {}))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "fast_cpu", bool(settings["fast_cpu"]))
	config.set_value("game", "locale", locale)
	config.save(SETTINGS_FILE)
	cpu_delay = 0.24 if bool(settings["fast_cpu"]) else 0.62

func _tr(key: String) -> String:
	var strings: Dictionary = locale_data.get("ui", {})
	if strings.has(key):
		return str(strings[key])
	var arabic: Dictionary = catalogs.get("ar", {}).get("ui", {})
	return str(arabic.get(key, key))

func _trf(key: String, values: Dictionary) -> String:
	return _tr(key).format(values)

func _tile_name(tile_index: int) -> String:
	var names: Array = locale_data.get("tiles", [])
	if tile_index >= 0 and tile_index < names.size():
		return str(names[tile_index])
	return str(BankGameModel.BOARD[clampi(tile_index, 0, BankGameModel.TILE_COUNT - 1)]["name"])

func _flag(tile_index: int) -> String:
	var flags: Array = locale_data.get("flags", [])
	return str(flags[tile_index]) if tile_index >= 0 and tile_index < flags.size() else ""

func _event_name(card_id: int) -> String:
	var names: Array = locale_data.get("events", [])
	if card_id >= 0 and card_id < names.size():
		return str(names[card_id])
	return _tr("event_title")

func _setup_theme() -> void:
	app_theme = Theme.new()
	ui_font = UI_FONT.duplicate() as FontFile
	ui_font.fallbacks.append(EMOJI_FONT)
	app_theme.default_font = ui_font
	app_theme.default_font_size = 19
	for type_name in ["Label", "Button", "LineEdit", "CheckBox", "OptionButton", "SpinBox"]:
		app_theme.set_color("font_color", type_name, TEXT)
		app_theme.set_color("font_hover_color", type_name, TEXT)
		app_theme.set_color("font_pressed_color", type_name, TEXT)
		app_theme.set_color("font_disabled_color", type_name, MUTED.darkened(0.2))
		app_theme.set_font("font", type_name, ui_font)
	theme = app_theme

func _check_saved_match() -> void:
	var probe = BankGameModel.new()
	var result: Dictionary = probe.load_from(SAVE_FILE)
	resume_available = bool(result.get("ok", false))
	startup_notice = _tr("corrupt_save") if bool(result.get("corrupt", false)) else ""

func _begin_layout(title_text: String = "") -> VBoxContainer:
	for child in get_children():
		child.queue_free()
	layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)
	main_column = VBoxContainer.new()
	main_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_column.add_theme_constant_override("separation", 10)
	main_column.layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	margin.add_child(main_column)
	if not title_text.is_empty():
		main_column.add_child(_label(title_text, 27, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	return main_column

func _label(text: String, size: int = 19, color: Color = TEXT, alignment: int = HORIZONTAL_ALIGNMENT_RIGHT) -> Label:
	var item := Label.new()
	item.text = text
	item.horizontal_alignment = alignment
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.text_direction = Control.TEXT_DIRECTION_RTL if locale == "ar" else Control.TEXT_DIRECTION_LTR
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func _panel(color: Color = PANEL, border: Color = Color("#344956"), radius: int = 14) -> PanelContainer:
	var result := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	result.add_theme_stylebox_override("panel", style)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func _button(text: String, color: Color = GOLD, min_height: int = 54, font_size: int = 20) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, min_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	button.text_direction = Control.TEXT_DIRECTION_RTL if locale == "ar" else Control.TEXT_DIRECTION_LTR
	button.add_theme_font_size_override("font_size", font_size)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(13)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.11)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.14)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#34434b")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", BG)
	button.add_theme_color_override("font_hover_color", BG)
	button.add_theme_color_override("font_pressed_color", BG)
	button.add_theme_color_override("font_disabled_color", MUTED)
	return button

func _secondary_button(text: String, min_height: int = 48) -> Button:
	return _button(text, Color("#40515b"), min_height, 17)

func _add_header(title: String, back_to_game: bool = false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var back := _secondary_button(_tr("back_to_game") if back_to_game else _tr("back"), 46)
	if back_to_game:
		back.pressed.connect(_show_game)
	else:
		back.pressed.connect(_go_back)
	row.custom_minimum_size.y = 46
	row.add_child(back)
	var heading := _label(title, 25, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(heading)
	main_column.add_child(row)

func _go_back() -> void:
	match screen_name:
		"setup": _show_home()
		"settings": _show_home()
		"rules": _show_game() if not game.state.is_empty() else _show_home()
		"market", "development", "portfolio", "trade": _show_game()
		"ledger": _show_game()
		_: _show_home()

func _show_home() -> void:
	screen_name = "home"
	_check_saved_match()
	var column := _begin_layout()
	var top_space := Control.new()
	top_space.custom_minimum_size.y = 24
	column.add_child(top_space)
	var logo := _label("◈  " + _tr("title") + "  ◈", 38, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	logo.custom_minimum_size.y = 64
	column.add_child(logo)
	column.add_child(_label(_tr("subtitle"), 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var intro := _panel(Color("#1a2831"), GOLD.darkened(0.45))
	intro.add_child(_label(_tr("welcome") + "\n" + _tr("tips"), 18, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(intro)
	var new_button := _button(_tr("new_game"), GOLD, 64, 22)
	new_button.pressed.connect(_show_setup)
	column.add_child(new_button)
	var resume := _button(_tr("resume"), BLUE, 58, 19)
	resume.disabled = not resume_available
	resume.pressed.connect(_resume_game)
	column.add_child(resume)
	var settings_button := _secondary_button(_tr("settings"))
	settings_button.pressed.connect(_show_settings)
	column.add_child(settings_button)
	var rules_button := _secondary_button(_tr("rules"))
	rules_button.pressed.connect(_show_rules)
	column.add_child(rules_button)
	var footer := _panel(Color("#17232b"), Color("#293943"))
	footer.add_child(_label("⌁  " + _tr("offline"), 16, GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(footer)
	if not startup_notice.is_empty():
		column.add_child(_label(startup_notice, 16, RED, HORIZONTAL_ALIGNMENT_CENTER))

func _show_setup() -> void:
	screen_name = "setup"
	name_inputs.clear()
	name_rows.clear()
	var column := _begin_layout(_tr("setup"))
	_add_header(_tr("setup"))
	column.add_child(_label(_tr("mode"), 19, GOLD))
	mode_option = OptionButton.new()
	mode_option.add_item(_tr("cpu_mode"), 0)
	mode_option.add_item(_tr("local_mode"), 1)
	mode_option.select(0 if current_mode == BankGameModel.MODE_COMPUTER else 1)
	_style_option(mode_option)
	mode_option.item_selected.connect(_on_setup_changed)
	column.add_child(mode_option)
	var mode_note := _panel()
	mode_note.add_child(_label(_tr("mode_cpu_label") + "\n" + _tr("mode_local_label"), 15, MUTED))
	column.add_child(mode_note)
	column.add_child(_label(_tr("player_name"), 18, TEXT))
	var first_name := LineEdit.new()
	first_name.placeholder_text = _tr("player_name")
	first_name.text = "سارة" if locale == "ar" else "Player 1"
	first_name.custom_minimum_size.y = 48
	first_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	first_name.text_direction = Control.TEXT_DIRECTION_AUTO
	name_inputs.append(first_name)
	column.add_child(first_name)
	column.add_child(_label(_tr("players"), 18, TEXT))
	player_count_option = OptionButton.new()
	for count in range(2, BankGameModel.MAX_LOCAL_PLAYERS + 1):
		player_count_option.add_item(str(count), count)
	player_count_option.select(0)
	_style_option(player_count_option)
	player_count_option.item_selected.connect(_on_setup_changed)
	column.add_child(player_count_option)
	for index in range(1, BankGameModel.MAX_LOCAL_PLAYERS):
		var row := HBoxContainer.new()
		var name_label := _label(_trf("player_name_n", {"n": str(index + 1)}), 17, MUTED)
		name_label.custom_minimum_size.x = 120
		var input := LineEdit.new()
		input.placeholder_text = _trf("player_name_n", {"n": str(index + 1)})
		input.text = ("اللاعب " + str(index + 1)) if locale == "ar" else ("Player " + str(index + 1))
		input.custom_minimum_size.y = 46
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.text_direction = Control.TEXT_DIRECTION_AUTO
		row.add_child(name_label)
		row.add_child(input)
		name_inputs.append(input)
		name_rows.append(row)
		column.add_child(row)
	column.add_child(_label(_tr("difficulty"), 18, GOLD))
	difficulty_option = OptionButton.new()
	difficulty_option.add_item(_tr("easy"), 0)
	difficulty_option.add_item(_tr("medium"), 1)
	difficulty_option.add_item(_tr("hard"), 2)
	difficulty_option.select(1)
	_style_option(difficulty_option)
	column.add_child(difficulty_option)
	column.add_child(_label(_tr("duration"), 18, GOLD))
	duration_option = OptionButton.new()
	duration_option.add_item(_tr("short"), 0)
	duration_option.add_item(_tr("normal"), 1)
	duration_option.add_item(_tr("long"), 2)
	duration_option.select(1)
	_style_option(duration_option)
	column.add_child(duration_option)
	column.add_child(_label(_tr("duration_note"), 15, MUTED))
	var start := _button(_tr("start"), GREEN, 62, 22)
	start.pressed.connect(_start_match)
	column.add_child(start)
	_on_setup_changed(0)

func _style_option(option: OptionButton) -> void:
	option.custom_minimum_size.y = 48
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	option.add_theme_font_size_override("font_size", 18)

func _on_setup_changed(_index: int) -> void:
	if mode_option == null or player_count_option == null:
		return
	var local_mode := mode_option.get_selected_id() == 1
	var count := player_count_option.get_selected_id()
	for i in range(name_rows.size()):
		name_rows[i].visible = local_mode and i < count - 1
	player_count_option.visible = local_mode
	for input_index in range(1, name_inputs.size()):
		name_inputs[input_index].visible = local_mode and input_index < count
	difficulty_option.visible = not local_mode

func _start_match() -> void:
	var mode: String = BankGameModel.MODE_LOCAL if mode_option.get_selected_id() == 1 else BankGameModel.MODE_COMPUTER
	current_mode = mode
	var difficulty_id := difficulty_option.get_selected_id()
	var difficulty: String = ["easy", "medium", "hard"][clampi(difficulty_id, 0, 2)]
	var duration_id := duration_option.get_selected_id()
	var duration: String = ["short", "normal", "long"][clampi(duration_id, 0, 2)]
	var first := name_inputs[0].text.strip_edges()
	if first.is_empty():
		first = "اللاعب" if locale == "ar" else "Player"
	var names: Array[String] = []
	if mode == BankGameModel.MODE_LOCAL:
		var count := clampi(player_count_option.get_selected_id(), 2, BankGameModel.MAX_LOCAL_PLAYERS)
		for index in range(count):
			var name := name_inputs[index].text.strip_edges()
			if name.is_empty():
				name = _trf("player_name_n", {"n": str(index + 1)})
			names.append(name)
	game = BankGameModel.new()
	game.new_game(first, mode, names, difficulty, duration)
	selected_tile = 0
	last_landed_player_id = 0
	animated_positions.clear()
	for _i in range(game.state["players"].size()):
		animated_positions.append(-1)
	last_feedback = _tr("welcome")
	last_feedback_color = GREEN
	_save_game_state()
	_show_game()
	_maybe_run_cpu_turn()

func _resume_game() -> void:
	var restored = BankGameModel.new()
	var result: Dictionary = restored.load_from(SAVE_FILE)
	if not bool(result.get("ok", false)):
		startup_notice = _tr("corrupt_save") if bool(result.get("corrupt", false)) else _tr("no_saved")
		_show_home()
		return
	game = restored
	current_mode = str(game.state.get("mode", BankGameModel.MODE_COMPUTER))
	selected_tile = int(game.state.get("current_tile", 0))
	last_landed_player_id = clampi(int(game.state.get("turn", 0)), 0, game.state["players"].size() - 1)
	animated_positions.clear()
	for _i in range(game.state["players"].size()):
		animated_positions.append(-1)
	last_feedback = _tr("message_saved")
	last_feedback_color = GREEN
	_show_game()
	_maybe_run_cpu_turn()

func _show_settings() -> void:
	var return_to_game: bool = not game.state.is_empty()
	screen_name = "settings"
	var column := _begin_layout(_tr("settings_title"))
	_add_header(_tr("settings_title"))
	column.add_child(_label(_tr("language"), 19, GOLD))
	language_option = OptionButton.new()
	language_option.add_item(_tr("language_ar"), 0)
	language_option.add_item(_tr("language_en"), 1)
	language_option.add_item(_tr("language_es"), 2)
	language_option.add_item(_tr("language_fr"), 3)
	language_option.select(maxi(0, LOCALE_IDS.find(locale)))
	_style_option(language_option)
	language_option.item_selected.connect(_on_language_selected)
	column.add_child(language_option)
	fast_cpu_option = CheckBox.new()
	fast_cpu_option.text = _tr("fast_cpu")
	fast_cpu_option.button_pressed = bool(settings["fast_cpu"])
	fast_cpu_option.custom_minimum_size.y = 48
	fast_cpu_option.toggled.connect(_on_fast_cpu_toggled)
	column.add_child(fast_cpu_option)
	var save_button := _button(_tr("save"), GREEN)
	save_button.pressed.connect(func(): _save_settings(); _show_game() if return_to_game else _show_home())
	column.add_child(save_button)
	var rules_button := _secondary_button(_tr("rules"))
	rules_button.pressed.connect(_show_rules)
	column.add_child(rules_button)

func _on_language_selected(index: int) -> void:
	locale = LOCALE_IDS[clampi(index, 0, LOCALE_IDS.size() - 1)]
	locale_data = catalogs.get(locale, catalogs.get("ar", {}))
	_save_settings()
	_show_settings()

func _on_fast_cpu_toggled(enabled: bool) -> void:
	settings["fast_cpu"] = enabled
	_save_settings()

func _show_rules() -> void:
	var return_game: bool = not game.state.is_empty()
	screen_name = "rules"
	var column := _begin_layout(_tr("rules_title"))
	_add_header(_tr("rules_title"), return_game)
	var keys := ["rule_start", "rule_economy", "rule_groups", "rule_development", "rule_investment", "rule_sudan", "rule_events", "rule_bankruptcy", "rule_trades", "rule_finish"]
	for key in keys:
		var section := _panel(PANEL, Color("#344956"))
		var inner := VBoxContainer.new()
		inner.add_child(_label(_tr(key), 17, TEXT))
		section.add_child(inner)
		column.add_child(section)
	var back := _button(_tr("back_to_game") if return_game else _tr("back"), BLUE)
	back.pressed.connect(_show_game if return_game else _show_home)
	column.add_child(back)

func _hud_player_card(player_id: int) -> PanelContainer:
	var player: Dictionary = game.state["players"][player_id]
	var accent: Color = PLAYER_COLORS[player_id % PLAYER_COLORS.size()]
	var card := PanelContainer.new()
	card.name = "PlayerCard%d" % player_id
	card.custom_minimum_size = Vector2(0, 54)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var is_current := player_id == int(game.state.get("turn", 0))
	card.add_theme_stylebox_override("panel", _card_style(Color(accent, 0.88), GOLD if is_current else Color(accent.lightened(0.30), 0.95), 14))
	card.tooltip_text = "الدور الحالي" if is_current else ""
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	var avatar := AvatarIcon.new()
	avatar.custom_minimum_size = Vector2(32, 32)
	avatar.configure(accent.lightened(0.12))
	row.add_child(avatar)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(_label(str(player.get("name", "لاعب")), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
	var owned := 0
	for owner in game.state.get("tile_owners", []):
		if int(owner) == player_id:
			owned += 1
	details.add_child(_label("%s · %d دولة · %d/%d دورة" % [_money(int(player.get("balance", 0))), owned, int(game.state.get("round_number", 1)), int(game.state.get("round_limit", 16))], 10, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(details)
	card.add_child(row)
	return card


func _add_board_hud() -> void:
	var players: Array = game.state.get("players", [])
	var players_row := HBoxContainer.new()
	players_row.name = "PlayersHud"
	players_row.add_theme_constant_override("separation", 8)
	players_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	for player_id in range(players.size()):
		players_row.add_child(_hud_player_card(player_id))
	center_content.add_child(players_row)

	var map_stage := Control.new()
	map_stage.name = "WorldMapStage"
	map_stage.custom_minimum_size = Vector2(0, 84)
	var map := WorldMapArt.new()
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_stage.add_child(map)
	var logo_wrap := CenterContainer.new()
	logo_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo_column := VBoxContainer.new()
	logo_column.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_column.add_theme_constant_override("separation", 2)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/luckbank-icon.png")
	logo.custom_minimum_size = Vector2(96, 58)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_column.add_child(logo)
	logo_column.add_child(_label("بنك الحظ", 20, Color("#b77724"), HORIZONTAL_ALIGNMENT_CENTER))
	logo_column.add_child(_label("استثمر، اشترِ، اربح", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	logo_wrap.add_child(logo_column)
	map_stage.add_child(logo_wrap)
	center_content.add_child(map_stage)


func _add_bottom_nav() -> void:
	var nav := PanelContainer.new()
	nav.name = "BottomNavigation"
	nav.custom_minimum_size = Vector2(0, 46)
	nav.add_theme_stylebox_override("panel", _card_style(Color("#0c4163"), Color("#2ca4d8"), 24))
	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 8)
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var buttons := [
		["▤  قواعد اللعبة", Callable(self, "_show_rules")],
		["▥  الممتلكات", Callable(self, "_show_portfolio")],
		["▣  بطاقات الحدث", Callable(self, "_show_more_actions")],
		["⚙  الإعدادات", Callable(self, "_show_settings")]
	]
	for item: Array in buttons:
		var button := _button(str(item[0]), Color("#155d86"), 44, 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(item[1])
		nav_row.add_child(button)
	nav.add_child(nav_row)
	center_content.add_child(nav)


func _show_game() -> void:
	if game == null or game.state.is_empty():
		_show_home()
		return
	if str(game.state.get("phase", "")) == "trade":
		_show_trade_response()
		return
	screen_name = "game"
	selected_tile = clampi(selected_tile, 0, BankGameModel.TILE_COUNT - 1)
	for child in get_children():
		child.queue_free()
	layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	board_surface = Control.new()
	board_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_surface.offset_left = 10
	board_surface.offset_top = 10
	board_surface.offset_right = -10
	board_surface.offset_bottom = -10
	add_child(board_surface)
	var board_base := Panel.new()
	board_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_base.add_theme_stylebox_override("panel", _card_style(Color("#65402a"), Color("#c59a62"), 18))
	board_surface.add_child(board_base)
	tile_buttons.clear()
	tile_labels.clear()
	tile_id_labels.clear()
	tile_value_labels.clear()
	tile_token_rows.clear()
	tile_corner_art.clear()
	player_tokens.clear()
	for tile_index in range(BankGameModel.TILE_COUNT):
		var tile_button := Button.new()
		tile_button.focus_mode = Control.FOCUS_NONE
		tile_button.clip_contents = false
		tile_button.text_direction = Control.TEXT_DIRECTION_AUTO
		tile_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile_button.pressed.connect(_on_tile_selected.bind(tile_index))
		var tile_content := VBoxContainer.new()
		tile_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile_content.add_theme_constant_override("separation", -3)
		tile_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_button.add_child(tile_content)
		var header := HBoxContainer.new()
		header.layout_direction = Control.LAYOUT_DIRECTION_LTR
		header.add_theme_constant_override("separation", 1)
		header.custom_minimum_size = Vector2(0, 13)
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var id_label := _label("", 10, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		id_label.text_direction = Control.TEXT_DIRECTION_LTR
		id_label.custom_minimum_size = Vector2(28, 0)
		header.add_child(id_label)
		var token_row := HBoxContainer.new()
		token_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
		token_row.add_theme_constant_override("separation", 0)
		token_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(token_row)
		tile_content.add_child(header)
		var corner_art := CornerArt.new()
		corner_art.custom_minimum_size = Vector2(0, 28)
		corner_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var square_type := str(BankGameModel.BOARD[tile_index].get("type", ""))
		if square_type == "start":
			corner_art.configure("start")
		elif square_type == "market":
			corner_art.configure("market")
		elif square_type == "rest":
			corner_art.configure("rest")
		elif square_type == "jail":
			corner_art.configure("jail")
		elif square_type == "tax":
			corner_art.configure("tax")
		elif square_type == "event":
			corner_art.configure("event")
		else:
			corner_art.visible = false
		tile_content.add_child(corner_art)
		var name_label := _label("", 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = false
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_content.add_child(name_label)
		var value_label := _label("", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		value_label.custom_minimum_size = Vector2(0, 20)
		value_label.clip_text = false
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_content.add_child(value_label)
		var value_bottom_padding := Control.new()
		value_bottom_padding.custom_minimum_size = Vector2(0, 6)
		value_bottom_padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_content.add_child(value_bottom_padding)
		board_surface.add_child(tile_button)
		tile_buttons.append(tile_button)
		tile_labels.append(name_label)
		tile_id_labels.append(id_label)
		tile_value_labels.append(value_label)
		tile_token_rows.append(token_row)
		tile_corner_art.append(corner_art)
	for player_id in range(game.state["players"].size()):
		var token := PlayerToken.new()
		token.custom_minimum_size = Vector2(28, 28)
		token.mouse_filter = Control.MOUSE_FILTER_IGNORE
		token.configure(PLAYER_COLORS[player_id % PLAYER_COLORS.size()], game.is_computer_player(player_id))
		player_tokens.append(token)

	center_panel = PanelContainer.new()
	center_panel.add_theme_stylebox_override("panel", _card_style(Color("#fff4dc"), Color("#b58a50"), 16))
	board_surface.add_child(center_panel)
	var center_margin := MarginContainer.new()
	center_margin.add_theme_constant_override("margin_left", 5)
	center_margin.add_theme_constant_override("margin_right", 5)
	center_margin.add_theme_constant_override("margin_top", 5)
	center_margin.add_theme_constant_override("margin_bottom", 5)
	center_panel.add_child(center_margin)
	var center_scroll := ScrollContainer.new()
	center_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	center_margin.add_child(center_scroll)
	center_content = VBoxContainer.new()
	center_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_content.add_theme_constant_override("separation", 3)
	center_scroll.add_child(center_content)
	_add_board_hud()
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	var home := _secondary_button("⌂  " + _tr("save_home"), 30)
	home.pressed.connect(_save_and_home)
	top.add_child(home)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/brand/luckbank-icon.png")
	logo.custom_minimum_size = Vector2(26, 26)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(logo)
	top.add_child(_label(_tr("title"), 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	top.visible = false
	center_content.add_child(top)
	status_turn_label = _label("", 17, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	status_round_label = _label("", 13, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	status_phase_label = _label("", 12, BLUE, HORIZONTAL_ALIGNMENT_CENTER)
	status_round_label.visible = true
	status_phase_label.visible = true
	center_content.add_child(status_turn_label)
	center_content.add_child(status_round_label)
	center_content.add_child(status_phase_label)
	tile_detail_label = _label("", 13, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	tile_detail_label.visible = true
	center_content.add_child(tile_detail_label)
	var tile_info_row := HBoxContainer.new()
	tile_info_button = _secondary_button(_tr("tile_info_button"), 34)
	tile_info_button.pressed.connect(_show_tile_information)
	tile_info_row.add_child(tile_info_button)
	tile_info_row.visible = false
	center_content.add_child(tile_info_row)
	var playmat := _panel(Color("#e7ebcf"), Color("#6f936d"), 8)
	var playmat_box := VBoxContainer.new()
	playmat_box.add_child(_label("قطع اللعب", 14, Color("#3f654b"), HORIZONTAL_ALIGNMENT_CENTER))
	var pieces_row := HBoxContainer.new()
	pieces_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pieces_row.add_theme_constant_override("separation", 6)
	for player_id in range(game.state["players"].size()):
		var piece := _label("%s  %s" % [_player_symbol(player_id), str(game.state["players"][player_id]["name"])] , 13, PLAYER_COLORS[player_id % PLAYER_COLORS.size()], HORIZONTAL_ALIGNMENT_CENTER)
		piece.custom_minimum_size = Vector2(92, 28)
		pieces_row.add_child(piece)
	playmat_box.add_child(pieces_row)
	playmat.add_child(playmat_box)
	playmat.visible = false
	center_content.add_child(playmat)
	var log_panel := _panel(Color("#fff8df"), Color("#8aa676"), 8)
	event_log_label = _label("", 12, Color("#514435"), HORIZONTAL_ALIGNMENT_RIGHT)
	event_log_label.custom_minimum_size.y = 58
	event_log_label.max_lines_visible = 4
	log_panel.add_child(event_log_label)
	log_panel.visible = false
	center_content.add_child(log_panel)
	var dice_row := HBoxContainer.new()
	dice_row.add_theme_constant_override("separation", 8)
	dice_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	dice_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dice_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dice_value_label = _label("", 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	dice_value_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dice_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dice_value_label.visible = false
	dice_row.add_child(dice_value_label)
	roll_button = _button("", GOLD, 64, 17)
	roll_button.custom_minimum_size = Vector2(58, 58)
	roll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	roll_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	roll_button.tooltip_text = _tr("roll")
	roll_button.pressed.connect(_on_roll_pressed)
	dice_face = DiceFace.new()
	dice_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dice_face.offset_left = 5
	dice_face.offset_top = 5
	dice_face.offset_right = -5
	dice_face.offset_bottom = -5
	dice_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll_button.add_child(dice_face)
	dice_row.add_child(roll_button)
	end_turn_button = _button(_tr("end_turn"), GREEN, 44, 16)
	end_turn_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_turn_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	dice_row.add_child(end_turn_button)
	center_content.add_child(dice_row)
	var utility_row := HBoxContainer.new()
	utility_row.visible = false
	portfolio_button = _button(_tr("countries"), GREEN, 40, 15)
	portfolio_button.pressed.connect(_show_portfolio)
	utility_row.add_child(portfolio_button)
	more_button = _button(_tr("more"), BLUE, 40, 15)
	more_button.pressed.connect(_show_more_actions)
	utility_row.add_child(more_button)
	center_content.add_child(utility_row)
	var message_panel := _panel(PANEL, Color("#cbb890"), 10)
	message_panel.name = "MessageBar"
	feedback_label = _label("", 16, last_feedback_color, HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.custom_minimum_size.y = 44
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.clip_text = false
	message_panel.add_child(feedback_label)
	center_content.add_child(message_panel)
	_add_bottom_nav()
	purchase_panel = _panel(Color("#f2d39a"), GOLD)
	var purchase_box := VBoxContainer.new()
	purchase_description = _label("", 16, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	purchase_box.add_child(purchase_description)
	var purchase_row := HBoxContainer.new()
	purchase_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button = _button(_tr("buy"), GREEN, 44, 17)
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.pressed.connect(_on_buy_pressed)
	skip_button = _secondary_button(_tr("skip"), 44)
	skip_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	skip_button.pressed.connect(_on_skip_pressed)
	purchase_row.add_child(buy_button)
	purchase_row.add_child(skip_button)
	purchase_box.add_child(purchase_row)
	purchase_panel.add_child(purchase_box)
	center_content.add_child(purchase_panel)
	obligation_panel = _panel(Color("#f0c4ad"), RED)
	obligation_content = VBoxContainer.new()
	obligation_content.add_theme_constant_override("separation", 7)
	obligation_panel.add_child(obligation_content)
	center_content.add_child(obligation_panel)
	result_panel = _panel(Color("#c9e3c8"), GREEN)
	result_content = VBoxContainer.new()
	result_panel.add_child(result_content)
	center_content.add_child(result_panel)
	board_surface.resized.connect(_layout_ring_tiles)
	call_deferred("_layout_ring_tiles")
	_update_game_view()

func _ring_coordinate(tile_index: int) -> Vector2i:
	if tile_index < 0 or tile_index >= BankGameModel.TILE_COUNT:
		return Vector2i(-1, -1)
	if tile_index <= 10:
		return Vector2i(0, 10 - tile_index)
	if tile_index <= 20:
		return Vector2i(tile_index - 10, 0)
	if tile_index <= 30:
		return Vector2i(10, tile_index - 20)
	return Vector2i(40 - tile_index, 10)

func _layout_ring_tiles() -> void:
	if not is_instance_valid(board_surface) or not is_instance_valid(center_panel) or tile_buttons.size() != BankGameModel.TILE_COUNT:
		return
	var board_size := board_surface.size
	if board_size.x < 100.0 or board_size.y < 100.0:
		return
	# Landscape tabletop board: width and height are intentionally independent
	# so the game reads as a rectangular board instead of a square grid.
	var board_origin := Vector2(6.0, 6.0)
	var cell_x := (board_size.x - 12.0) / 11.0
	var cell_y := (board_size.y - 12.0) / 11.0
	var inner_margin := 1.35
	center_panel.position = board_origin + Vector2(cell_x * inner_margin, cell_y * inner_margin)
	center_panel.size = Vector2(cell_x * (11.0 - inner_margin * 2.0), cell_y * (11.0 - inner_margin * 2.0))
	var font_size := clampi(int(minf(cell_x, cell_y) / 5.0), 11, 15)
	for tile_index in range(BankGameModel.TILE_COUNT):
		var coord := _ring_coordinate(tile_index)
		var rect := Rect2(board_origin + Vector2(coord.x * cell_x, coord.y * cell_y), Vector2(cell_x, cell_y))
		var tile_button := tile_buttons[tile_index]
		tile_button.position = rect.position
		tile_button.size = rect.size
		var side_tile := coord.x == 0 or coord.x == 10
		var full_name := _tile_name(tile_index)
		var title_size := 11 if full_name.length() > 15 else 12
		var value_size := 11
		tile_id_labels[tile_index].add_theme_font_size_override("font_size", 8 if side_tile else 9)
		tile_labels[tile_index].add_theme_font_size_override("font_size", title_size)
		tile_value_labels[tile_index].add_theme_font_size_override("font_size", value_size)
		for token in tile_token_rows[tile_index].get_children():
			(token as Control).custom_minimum_size = Vector2(24, 24) if side_tile else Vector2(28, 28)
		if tile_index < tile_corner_art.size():
			tile_corner_art[tile_index].custom_minimum_size.y = 30 if not side_tile else 0
	_refresh_board()
	_update_game_view()

func _update_game_view() -> void:
	if screen_name != "game" or game.state.is_empty():
		return
	var players: Array = game.state["players"]
	var turn_id := clampi(int(game.state.get("turn", 0)), 0, players.size() - 1)
	var current: Dictionary = players[turn_id]
	var phase := str(game.state.get("phase", ""))
	var is_active := bool(game.state.get("active", false))
	var current_is_cpu: bool = game.is_computer_player(turn_id)
	if current_is_cpu:
		status_turn_label.text = _tr("cpu_turn") if cpu_running else _trf("players_turn", {"name": str(current["name"])})
	else:
		status_turn_label.text = _trf("players_turn", {"name": str(current["name"])})
	status_round_label.text = "%s %d/%d   ·   %s: %s" % [_tr("round"), int(game.state.get("round_number", 1)), int(game.state.get("round_limit", 16)), _tr("balance"), _money(int(current["balance"]))]
	status_phase_label.text = _phase_name(phase)
	tile_detail_label.text = "%s: %s" % [_tr("position"), _tile_name(int(current["position"]))]
	tile_info_button.text = "%s · %s" % [_tr("tile_info_button"), _tile_name(selected_tile)]
	dice_value_label.text = "%s: %s" % [_tr("dice"), "—" if int(game.state.get("last_dice", 0)) == 0 else str(game.state["last_dice"])]
	if is_instance_valid(dice_face):
		var total_dice := int(game.state.get("last_dice", 0))
		dice_face.set_face(maxi(1, total_dice))
		feedback_label.text = last_feedback.replace("\n", " · ")
		feedback_label.add_theme_color_override("font_color", last_feedback_color)
		if is_instance_valid(event_log_label):
			event_log_label.text = _event_log_text()
	var human_turn: bool = is_active and game.is_human_player(turn_id)
	roll_button.visible = is_active
	end_turn_button.visible = human_turn and phase == "actions"
	end_turn_button.text = _tr("end_turn")
	roll_button.disabled = not human_turn or phase != "await_roll" or animation_lock or cpu_running
	end_turn_button.disabled = not human_turn or phase != "actions" or animation_lock or cpu_running
	portfolio_button.disabled = not is_active and phase != "finished"
	var pending := int(game.state.get("pending_property", -1))
	purchase_panel.visible = is_active and pending >= 0
	if purchase_panel.visible:
		var price := int(BankGameModel.BOARD[pending].get("price", 0))
		var enough := int(current["balance"]) >= price
		purchase_description.text = "%s  ·  %s %s  ·  %s: %s" % [_tile_name(pending), _tr("price"), _money(price), _tr("balance"), _money(int(current["balance"]))]
		buy_button.disabled = not human_turn or not enough or animation_lock or cpu_running
		buy_button.text = _tr("buy") if enough else _tr("insufficient")
		skip_button.disabled = not human_turn or animation_lock or cpu_running
	obligation_panel.visible = is_active and phase in ["obligation", "jail"] and human_turn
	if obligation_panel.visible:
		_populate_obligation_panel(turn_id)
	var waiting_for_decision: bool = purchase_panel.visible or obligation_panel.visible
	tile_info_button.get_parent().visible = false
	# The landscape HUD uses the dedicated rounded bottom navigation bar.
	portfolio_button.get_parent().visible = false
	feedback_label.text = last_feedback.replace("\n", " · ") if not last_feedback.is_empty() else _phase_name(phase)
	feedback_label.visible = true
	result_panel.visible = not is_active
	if result_panel.visible:
		_populate_result_panel()
	_refresh_board()

func _card_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1 if border == Color("#344956") else 2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color("#2b170d", 0.16)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style

func _phase_name(phase: String) -> String:
	match phase:
		"await_roll": return _tr("phase_roll")
		"actions": return _tr("phase_actions")
		"pending_purchase": return _tr("phase_purchase")
		"obligation": return _tr("phase_obligation")
		"trade": return _tr("phase_trade")
		"finished": return _tr("phase_finished")
	return _tr("unknown")

func _player_symbol(player_id: int) -> String:
	return PLAYER_SYMBOLS[player_id] if player_id >= 0 and player_id < PLAYER_SYMBOLS.size() else "●"

func _money(amount: int) -> String:
	return BankGameModel._cash(amount) + " " + _tr("money_unit")

func _refresh_board() -> void:
	if game.state.is_empty() or tile_buttons.size() != BankGameModel.TILE_COUNT or tile_labels.size() != BankGameModel.TILE_COUNT:
		return
	var players: Array = game.state["players"]
	for player_id in range(player_tokens.size()):
		var token: PlayerToken = player_tokens[player_id]
		var tile_index := _display_position(player_id)
		var alive := player_id < players.size() and bool(players[player_id].get("alive", true))
		if not alive or tile_index < 0 or tile_index >= tile_token_rows.size():
			if token.get_parent() != null:
				token.get_parent().remove_child(token)
			continue
		var target_row := tile_token_rows[tile_index]
		if token.get_parent() != target_row:
			if token.get_parent() != null:
				token.get_parent().remove_child(token)
			target_row.add_child(token)
	for tile_index in range(BankGameModel.TILE_COUNT):
		var tile: Dictionary = BankGameModel.BOARD[tile_index]
		var tile_type := str(tile["type"])
		var owner := int(game.state["tile_owners"][tile_index])
		var title := _tile_name(tile_index)
		var value := ""
		var value_color := GOLD
		var background := Color("#f8f0df")
		var border := Color("#9d8a70")
		if tile_type == "country":
			var group_id := int(tile.get("group", 0))
			background = Color("#fbf4e5")
			border = GROUP_COLORS[group_id].darkened(0.12)
			if owner >= 0:
				border = PLAYER_COLORS[owner % PLAYER_COLORS.size()]
				value = _money(game.rent_for_tile(tile_index))
			else:
				value = _money(int(tile["price"]))
		elif tile_type == "start":
			background = Color("#f4dfaa")
			border = GOLD
			value = "+" + _money(BankGameModel.LAP_BONUS)
		elif tile_type == "tax":
			background = Color("#f2d6cf")
			border = RED
			value = _money(int(tile["amount"]))
		elif tile_type == "event":
			background = Color("#e9def1")
			border = Color("#82629a")
			value = _tr("event_title")
			value_color = BLUE
		elif tile_type == "market":
			background = Color("#dcebd7")
			border = GREEN
			value = _tr("investment")
			value_color = GREEN
		elif tile_type == "rest":
			background = Color("#e9e3d4")
			value = _tr("rest_board")
			value_color = MUTED
		elif tile_type == "jail":
			background = Color("#ead3d0")
			border = RED
			value = _money(int(tile.get("bail", 500)))
		var owner_mark := "  " + _player_symbol(owner) if tile_type == "country" and owner >= 0 else ""
		tile_id_labels[tile_index].text = "%d %s%s" % [tile_index, _flag(tile_index), owner_mark]
		tile_labels[tile_index].text = title
		tile_id_labels[tile_index].add_theme_color_override("font_color", MUTED)
		tile_labels[tile_index].add_theme_color_override("font_color", TEXT)
		tile_value_labels[tile_index].text = value
		tile_value_labels[tile_index].add_theme_color_override("font_color", value_color)
		var cell := tile_buttons[tile_index]
		cell.tooltip_text = title
		if tile_type == "jail":
			cell.tooltip_text += " · " + _trf("jail_bail_info", {"amount": _money(int(tile.get("bail", 500)))})
		if tile_index == selected_tile:
			border = PLAYER_COLORS[int(game.state.get("turn", 0)) % PLAYER_COLORS.size()]
		var normal := _card_style(background, border, 10)
		normal.content_margin_left = 3
		normal.content_margin_right = 3
		normal.content_margin_top = 2
		normal.content_margin_bottom = 2
		cell.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = background.lightened(0.15)
		cell.add_theme_stylebox_override("hover", hover)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = background.lightened(0.22)
		cell.add_theme_stylebox_override("pressed", pressed)

func _display_position(player_id: int) -> int:
	if player_id < 0 or player_id >= game.state.get("players", []).size():
		return -1
	if player_id < animated_positions.size() and animated_positions[player_id] >= 0:
		return animated_positions[player_id]
	return int(game.state["players"][player_id]["position"])

func _shorten(value: String, limit: int) -> String:
	return value if value.length() <= limit else value.substr(0, limit - 1) + "…"

func _on_tile_selected(tile_index: int) -> void:
	selected_tile = tile_index
	if screen_name == "game":
		_show_tile_information()
	else:
		_update_game_view()

func _tile_details_text(tile_index: int) -> String:
	if tile_index < 0 or tile_index >= BankGameModel.TILE_COUNT:
		return ""
	var tile: Dictionary = BankGameModel.BOARD[tile_index]
	var kind := str(tile["type"])
	var lines: Array[String] = ["%s  %s  ·  %s" % [_flag(tile_index), _tile_name(tile_index), _tile_kind(kind)]]
	if kind == "country":
		var owner := int(game.state["tile_owners"][tile_index])
		var level := int(game.state["development"][tile_index])
		lines.append("%s: %s    %s: %s    %s: %s" % [_tr("price"), _money(int(tile["price"])), _tr("rent"), _money(game.rent_for_tile(tile_index)), _tr("income"), _money(game.income_for_tile(tile_index))])
		lines.append("%s: %s    %s: %d/%d" % [_tr("owner"), _tr("unowned") if owner < 0 else str(game.state["players"][owner]["name"]), _tr("development"), level, BankGameModel.DEV_COSTS.size()])
		lines.append("%s: %d" % [_tr("group"), int(tile["group"]) + 1])
		var feature_key := _feature_key(tile_index)
		if not feature_key.is_empty():
			lines.append(_tr(feature_key))
		if game.owns_complete_group(owner, int(tile["group"])):
			lines.append(_tr("group_bonus") + " · " + _tr("development_discount"))
	elif kind == "tax":
		lines.append(_tr("effect") + ": " + _money(int(tile["amount"])))
	elif kind == "event":
		var card: Dictionary = game.state.get("last_event", {})
		if int(card.get("id", -1)) >= 0 and int(game.state.get("current_tile", -1)) == tile_index:
			lines.append(_event_name(int(card["id"])) + " · " + _event_effect(int(card.get("amount", 0))))
		else:
			lines.append(_tr("event_effect"))
	elif kind == "market":
		lines.append(_tr("market_bonus") if bool(game.state.get("can_market", false)) else _tr("market_only"))
	elif kind == "rest":
		lines.append(_tr("rest_message"))
	elif kind == "jail":
		lines.append(_trf("jail_bail_info", {"amount": _money(int(tile.get("bail", 500)))}))
	elif kind == "start":
		lines.append(_tr("start_bonus") + ": " + _money(BankGameModel.LAP_BONUS) + " · " + _tr("income_note"))
	return "\n".join(lines)

func _show_tile_information() -> void:
	if game.state.is_empty():
		return
	screen_name = "tile_information"
	var column := _begin_layout(_tr("tile_info_button"))
	_add_header(_tr("tile_info_button"), true)
	var info_panel := _panel(PANEL_ALT, GOLD)
	info_panel.add_child(_label(_tile_details_text(selected_tile), 18, TEXT))
	column.add_child(info_panel)
	var close := _button(_tr("back_to_game"), BLUE)
	close.pressed.connect(_show_game)
	column.add_child(close)

func _feature_key(tile_index: int) -> String:
	match tile_index:
		1: return "feature_sudan"
		2: return "feature_egypt"
		8: return "feature_saudi"
		9: return "feature_uae"
		14: return "feature_china"
		16: return "feature_japan"
		26: return "feature_germany"
		38: return "feature_usa"
	return ""

func _tile_kind(kind: String) -> String:
	match kind:
		"start": return _tr("tile_start")
		"country": return _tr("tile_country")
		"tax": return _tr("tile_tax")
		"event": return _tr("tile_event")
		"rest": return _tr("tile_rest")
		"jail": return _tr("tile_jail")
		"market": return _tr("tile_market")
	return _tr("unknown")

func _event_effect(amount: int) -> String:
	if amount > 0:
		return _tr("event_positive") + ": +" + _money(amount)
	if amount < 0:
		return _tr("event_negative") + ": " + _money(amount)
	return _tr("event_neutral")

func _event_category(card: Dictionary) -> String:
	var event_id := int(card.get("id", -1))
	var amount := int(card.get("amount", 0))
	if event_id in [10, 13, 30, 32]:
		return "opportunity"
	if event_id in [19, 27, 35]:
		return "rare"
	if event_id in [11, 14, 28, 33, 37]:
		return "penalty"
	if amount < 0:
		return "crisis"
	if amount == 0:
		return "information"
	return "reward"

func _event_color(card: Dictionary) -> Color:
	match _event_category(card):
		"reward": return GREEN
		"opportunity": return GOLD
		"crisis": return RED
		"information": return BLUE
		"rare": return Color("#b58cff")
		"penalty": return Color("#68727a")
	return BLUE

func _event_log_text() -> String:
	var entries: Array = game.state.get("log", [])
	if entries.is_empty():
		return "لا توجد أحداث بعد"
	var recent: Array[String] = []
	var start := maxi(0, entries.size() - 4)
	for index in range(start, entries.size()):
		recent.append("• " + str(entries[index]))
	return "\n".join(recent)

func _landing_summary(player_id: int, tile_index: int, crossings: int) -> String:
	var tile: Dictionary = BankGameModel.BOARD[tile_index]
	var summary := "%s %s — %s." % [_flag(tile_index), _tile_name(tile_index), _tile_kind(str(tile["type"]))]
	var kind := str(tile["type"])
	if crossings > 0:
		var income_total := 0
		for entry in game.state.get("ledger", []):
			if int(entry.get("player", -1)) == player_id and str(entry.get("category", "")) == "periodic_income" and int(entry.get("turn", -1)) == int(game.state.get("turn_number", 1)):
				income_total += int(entry.get("amount", 0))
		summary += "\n" + _trf("crossing_summary", {"amount": _money(income_total)})
	if kind == "country":
		var owner := int(game.state["tile_owners"][tile_index])
		if owner < 0:
			summary += "\n" + _tr("available") + " · " + _tr("price") + ": " + _money(int(tile["price"]))
		elif owner == player_id:
			summary += "\n" + _tr("owner_you") + " · " + _tr("income") + ": " + _money(game.income_for_tile(tile_index))
		else:
			summary += "\n" + _tr("rent") + ": " + _money(game.rent_for_tile(tile_index)) + " · " + _tr("owner") + ": " + str(game.state["players"][owner]["name"])
	elif kind == "tax":
		summary += "\n" + _tr("tile_tax") + ": " + _money(int(tile["amount"]))
	elif kind == "event":
		var card: Dictionary = game.state.get("last_event", {})
		if not card.is_empty():
			var effect := int(card.get("amount", 0))
			if bool(card.get("food", false)) and game.has_investment(player_id, "agriculture", BankGameModel.SUDAN_TILE):
				effect += 60 if effect >= 0 else 35
			var category := _event_category(card)
			summary += "\n" + _event_name(int(card.get("id", -1))) + " · " + _tr("event_category") + ": " + _tr("event_" + category)
			summary += "\n" + _trf("event_player_effect", {"name": str(game.state["players"][player_id]["name"]), "amount": _event_effect(effect)})
			if bool(card.get("food", false)):
				summary += "\n" + _tr("food_condition")
	elif kind == "market":
		summary += "\n" + _tr("on_market")
	elif kind == "rest":
		summary += "\n" + _tr("rest_message")
	elif kind == "jail":
		var pending: Dictionary = game.state.get("pending_obligation", {})
		var bail_text := "jail_bail_due" if str(pending.get("category", "")) == "jail_bail" else "jail_bail_paid"
		summary += "\n" + _trf(bail_text, {"amount": _money(int(tile.get("bail", 500)))})
	return summary

func _on_roll_pressed() -> void:
	if screen_name != "game" or animation_lock or cpu_running or not bool(game.state.get("active", false)):
		return
	var player_id := int(game.state.get("turn", -1))
	if not game.is_human_player(player_id) or str(game.state.get("phase", "")) != "await_roll":
		return
	await _perform_roll(player_id)

func _perform_roll(player_id: int) -> void:
	var before := int(game.state["players"][player_id]["position"])
	var dice_result := randi_range(1, 6)
	await _animate_dice_roll(dice_result)
	var result: Dictionary = game.roll(player_id, dice_result)
	if not bool(result.get("ok", false)):
		last_feedback = _tr("roll_done")
		last_feedback_color = RED
		_update_game_view()
		return
	last_landed_player_id = player_id
	selected_tile = int(result["to"])
	if player_id >= 0 and player_id < animated_positions.size():
		animated_positions[player_id] = before
	_save_game_state()
	_update_game_view()
	await _animate_path(player_id, result.get("path", []), before)
	last_feedback = _landing_summary(player_id, int(result["to"]), int(result.get("crossings", 0)))
	var event_card: Dictionary = game.state.get("last_event", {})
	last_feedback_color = _event_color(event_card) if not event_card.is_empty() else (BLUE if game.is_computer_player(player_id) else GOLD)
	_save_game_state()
	_update_game_view()

func _animate_dice_roll(final_face: int) -> void:
	if not is_instance_valid(dice_face):
		return
	animation_lock = true
	for frame in range(8):
		dice_face.set_face(randi_range(1, 6))
		dice_face.rotation = deg_to_rad(randf_range(-10.0, 10.0))
		dice_face.scale = Vector2(0.94, 0.94) if frame % 2 == 0 else Vector2.ONE
		await get_tree().create_timer(0.055).timeout
	dice_face.set_face(final_face)
	dice_face.rotation = 0.0
	dice_face.scale = Vector2.ONE
	animation_lock = false

func _animate_path(player_id: int, path: Array, starting_position: int) -> void:
	if player_id < 0 or player_id >= animated_positions.size():
		return
	animation_lock = true
	animated_positions[player_id] = starting_position
	_refresh_board()
	for position in path:
		if screen_name != "game":
			break
		animated_positions[player_id] = int(position)
		_refresh_board()
		await get_tree().create_timer(0.11).timeout
	animated_positions[player_id] = -1
	animation_lock = false
	_refresh_board()
	_update_game_view()

func _on_buy_pressed() -> void:
	var pending := int(game.state.get("pending_property", -1))
	if pending < 0:
		return
	_confirm(_tr("confirm"), _tr("confirm_buy") + "\n" + _tile_name(pending) + " · " + _money(int(BankGameModel.BOARD[pending]["price"])), _perform_buy)

func _perform_buy() -> void:
	var result: Dictionary = game.buy_pending_property()
	last_feedback = _tr("purchase_done") if bool(result.get("ok", false)) else _tr("insufficient")
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_game()
	_maybe_run_cpu_turn()

func _on_skip_pressed() -> void:
	var result: Dictionary = game.skip_pending_purchase()
	last_feedback = _tr("purchase_skipped") if bool(result.get("ok", false)) else _tr("unknown")
	last_feedback_color = MUTED
	_save_game_state()
	_show_game()
	_maybe_run_cpu_turn()

func _on_end_turn_pressed() -> void:
	var player_id := int(game.state.get("turn", -1))
	var result: Dictionary = game.end_turn(player_id)
	if not bool(result.get("ok", false)):
		last_feedback = _tr("unknown")
		last_feedback_color = RED
		_update_game_view()
		return
	last_feedback = _tr("turn_done")
	last_feedback_color = GREEN
	_save_game_state()
	_show_game()
	_maybe_run_cpu_turn()

func _maybe_run_cpu_turn() -> void:
	if cpu_running or screen_name != "game" or game.state.is_empty() or not bool(game.state.get("active", false)):
		return
	var player_id := int(game.state.get("turn", -1))
	if not game.is_computer_player(player_id):
		return
	cpu_running = true
	var guard := 0
	while screen_name == "game" and bool(game.state.get("active", false)) and game.is_computer_player(int(game.state.get("turn", -1))) and guard < 3:
		guard += 1
		player_id = int(game.state["turn"])
		_update_game_view()
		await get_tree().create_timer(cpu_delay).timeout
		if screen_name != "game" or not bool(game.state.get("active", false)):
			break
		if str(game.state.get("phase", "")) == "await_roll":
			await _perform_roll(player_id)
		if not bool(game.state.get("active", false)):
			break
		if str(game.state.get("phase", "")) == "obligation":
			var cpu_sales: Array[String] = game.resolve_computer_obligation(player_id)
			if not cpu_sales.is_empty():
				last_feedback = _tr("computer_reason") + "\n" + "\n".join(cpu_sales)
				last_feedback_color = BLUE
		if not bool(game.state.get("active", false)):
			break
		if str(game.state.get("phase", "")) == "actions":
			var decisions: Array[String] = game.run_computer_actions(player_id)
			last_feedback = _tr("computer_reason") if decisions.is_empty() else _tr("computer_reason") + "\n" + "\n".join(decisions)
			last_feedback_color = BLUE
			var ended: Dictionary = game.end_turn(player_id)
			if not bool(ended.get("ok", false)):
				break
			_save_game_state()
		_update_game_view()
		if str(game.state.get("phase", "")) == "obligation" and game.is_computer_player(int(game.state.get("turn", -1))):
			continue
	cpu_running = false
	_save_game_state()
	if screen_name == "game":
		_update_game_view()

func _show_market() -> void:
	if game.state.is_empty():
		return
	screen_name = "market"
	var player_id := int(game.state.get("turn", 0))
	var can_open: bool = str(game.state.get("phase", "")) == "actions" and bool(game.state.get("can_market", false)) and game.is_human_player(player_id)
	var column := _begin_layout(_tr("market_title"))
	_add_header(_tr("market_title"), true)
	var notice := _panel(Color("#182a28"), GREEN.darkened(0.3))
	notice.add_child(_label(_tr("market_only") + ("\n" + _tr("market_bonus") if can_open else ""), 16, GREEN if can_open else MUTED))
	column.add_child(notice)
	if not can_open:
		column.add_child(_label(_tr("no_market"), 18, RED, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		column.add_child(_label("السوق العالمي · العرض والطلب", 20, GOLD))
		for product in game.market_products():
			var product_id := str(product["id"])
			var quote: Dictionary = game.market_quote(product_id)
			var trend := "↑" if int(quote.get("trend", 0)) > 0 else ("↓" if int(quote.get("trend", 0)) < 0 else "→")
			var product_box := _panel(PANEL_ALT, Color("#263c48"))
			product_box.add_child(_label("%s · السعر: %s · العرض: %d · الطلب: %d %s" % [str(product["name"]), _money(int(quote["price"])), int(quote["supply"]), int(quote["demand"]), trend], 15, TEXT))
			var product_actions := HBoxContainer.new()
			product_actions.add_theme_constant_override("separation", 8)
			var buy_product := _secondary_button("شراء 1", 44)
			buy_product.pressed.connect(_perform_market_buy.bind(product_id))
			product_actions.add_child(buy_product)
			var sell_product := _secondary_button("بيع 1", 44)
			sell_product.pressed.connect(_perform_market_sell.bind(product_id))
			product_actions.add_child(sell_product)
			product_box.add_child(product_actions)
			column.add_child(product_box)
		for global_event in game.state.get("active_global_events", []):
			column.add_child(_label("حدث عالمي: %s · متبقٍ %d دورًا" % [str(global_event["title"]), int(global_event["duration"])], 15, Color("#b58cff")))
		column.add_child(_label(_tr("buy_investment"), 20, GOLD))
		var option_count := 0
		for tile_index in BankGameModel.country_tiles():
			if int(game.state["tile_owners"][tile_index]) != player_id:
				continue
			for option in game.investment_options(player_id, tile_index):
				option_count += 1
				var investment_type := str(option["type"])
				var expansion_label := ""
				if bool(option.get("expansion", false)):
					expansion_label = " · " + _trf("investment_expansion", {"level": str(option.get("expansion_level", 1))})
				var box := _panel(PANEL_ALT, GROUP_COLORS[int(BankGameModel.BOARD[tile_index]["group"])].darkened(0.25))
				var button_text := "%s%s  ·  %s\n%s: %s   |   %s: +%s\n%s: %d %s" % [_investment_name(investment_type), expansion_label, _tile_name(tile_index), _tr("invest_cost"), _money(int(option["cost"])), _tr("invest_income"), _money(int(option["income"])), _tr("payback"), int(option["payback"]), _tr("round")]
				var buy := _button(button_text, GROUP_COLORS[int(BankGameModel.BOARD[tile_index]["group"])], 76, 15)
				buy.pressed.connect(_confirm_investment.bind(investment_type, tile_index, option))
				box.add_child(buy)
				column.add_child(box)
		if option_count == 0:
			column.add_child(_label(_tr("no_investments"), 16, MUTED))
		column.add_child(_label(_tr("sell_investment") + " · 50%", 20, GOLD))
		var investments: Array = game.state.get("investments", [])
		var sells := 0
		for index in range(investments.size()):
			var investment: Dictionary = investments[index]
			if int(investment.get("owner", -1)) != player_id:
				continue
			sells += 1
			var refund := int(investment.get("cost", 0)) / 2
			var sell := _secondary_button("%s · %s · %s: %s" % [_investment_name(str(investment["type"])), _tile_name(int(investment["tile"])), _tr("sell"), _money(refund)], 54)
			sell.pressed.connect(_confirm_sell_investment.bind(index))
			column.add_child(sell)
		if sells == 0:
			column.add_child(_label(_tr("no_investments"), 15, MUTED))
	var close := _button(_tr("back_to_game"), BLUE)
	close.pressed.connect(_show_game)
	column.add_child(close)

func _investment_name(investment_type: String) -> String:
	var key := "invest_" + investment_type
	return _tr(key)

func _perform_market_buy(product_id: String) -> void:
	var result: Dictionary = game.buy_market_product(int(game.state["turn"]), product_id, 1)
	last_feedback = "تم شراء وحدة من السوق." if bool(result.get("ok", false)) else str(result.get("message", _tr("unknown")))
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_market()

func _perform_market_sell(product_id: String) -> void:
	var result: Dictionary = game.sell_market_product(int(game.state["turn"]), product_id, 1)
	last_feedback = "تم بيع وحدة من السوق." if bool(result.get("ok", false)) else str(result.get("message", _tr("unknown")))
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_market()

func _confirm_investment(investment_type: String, tile_index: int, option: Dictionary) -> void:
	var expansion_label := ""
	if bool(option.get("expansion", false)):
		expansion_label = " · " + _trf("investment_expansion", {"level": str(option.get("expansion_level", 1))})
	var details := "%s%s · %s\n%s: %s\n%s: +%s\n%s: %d %s" % [_investment_name(investment_type), expansion_label, _tile_name(tile_index), _tr("invest_cost"), _money(int(option["cost"])), _tr("invest_income"), _money(int(option["income"])), _tr("payback"), int(option["payback"]), _tr("round")]
	_confirm(_tr("confirm"), _tr("confirm_invest") + "\n" + details, func(): _perform_investment(investment_type, tile_index))

func _perform_investment(investment_type: String, tile_index: int) -> void:
	var result: Dictionary = game.buy_investment(int(game.state["turn"]), investment_type, tile_index)
	last_feedback = _tr("investment_done") if bool(result.get("ok", false)) else _tr("insufficient")
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_game()

func _confirm_sell_investment(index: int) -> void:
	if index < 0 or index >= game.state.get("investments", []).size():
		return
	_confirm(_tr("confirm"), _tr("confirm_sell") + "\n" + _tr("sell_investment"), func(): _perform_sell_investment(index))

func _perform_sell_investment(index: int) -> void:
	var result: Dictionary = game.sell_investment(int(game.state["turn"]), index)
	last_feedback = _tr("sale_done") if bool(result.get("ok", false)) else _tr("unknown")
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_game()

func _show_development() -> void:
	if game.state.is_empty():
		return
	screen_name = "development"
	var player_id := int(game.state.get("turn", 0))
	var column := _begin_layout(_tr("upgrade_title"))
	_add_header(_tr("upgrade_title"), true)
	column.add_child(_label(_tr("upgrade_preview"), 17, MUTED))
	var count := 0
	for tile_index in BankGameModel.country_tiles():
		if int(game.state["tile_owners"][tile_index]) != player_id:
			continue
		count += 1
		var level := int(game.state["development"][tile_index])
		var box := _panel(PANEL_ALT, GROUP_COLORS[int(BankGameModel.BOARD[tile_index]["group"])].darkened(0.2))
		var current_rent: int = game.rent_for_tile(tile_index)
		var current_income: int = game.income_for_tile(tile_index)
		if level >= BankGameModel.DEV_COSTS.size():
			box.add_child(_label("%s  ·  %s %d/%d\n%s" % [_tile_name(tile_index), _tr("development"), level, BankGameModel.DEV_COSTS.size(), _tr("max_level")], 17, MUTED))
		else:
			var cost: int = game.development_cost(player_id, tile_index)
			game.state["development"][tile_index] = level + 1
			var next_rent: int = game.rent_for_tile(tile_index)
			var next_income: int = game.income_for_tile(tile_index)
			game.state["development"][tile_index] = level
			var text := "%s  ·  %s %d → %d\n%s: %s\n%s: %s → %s\n%s: %s → %s" % [_tile_name(tile_index), _tr("development"), level, level + 1, _tr("upgrade_cost"), _money(cost), _tr("rent_after"), _money(current_rent), _money(next_rent), _tr("income_after"), _money(current_income), _money(next_income)]
			var upgrade := _button(text, GROUP_COLORS[int(BankGameModel.BOARD[tile_index]["group"])], 92, 15)
			upgrade.pressed.connect(_confirm_upgrade.bind(tile_index, cost, next_rent, next_income))
			box.add_child(upgrade)
		column.add_child(box)
	if count == 0:
		column.add_child(_label(_tr("no_development"), 17, MUTED))
	var back := _button(_tr("back_to_game"), BLUE)
	back.pressed.connect(_show_game)
	column.add_child(back)

func _confirm_upgrade(tile_index: int, cost: int, next_rent: int, next_income: int) -> void:
	var details := "%s · %s: %s\n%s: %s · %s: %s" % [_tile_name(tile_index), _tr("upgrade_cost"), _money(cost), _tr("rent_after"), _money(next_rent), _tr("income_after"), _money(next_income)]
	_confirm(_tr("confirm"), _tr("confirm_upgrade") + "\n" + details, func(): _perform_upgrade(tile_index))

func _perform_upgrade(tile_index: int) -> void:
	var result: Dictionary = game.upgrade_property(int(game.state["turn"]), tile_index)
	last_feedback = _tr("upgrade_done") if bool(result.get("ok", false)) else _tr("insufficient")
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_game()

func _show_more_actions() -> void:
	if game.state.is_empty():
		return
	screen_name = "more"
	var column := _begin_layout(_tr("more"))
	_add_header(_tr("more"), true)
	var turn_id := clampi(int(game.state.get("turn", 0)), 0, game.state["players"].size() - 1)
	var phase := str(game.state.get("phase", ""))
	var human_turn: bool = bool(game.state.get("active", false)) and game.is_human_player(turn_id)
	var note := _panel(Color("#18262f"), Color("#40515b"))
	note.add_child(_label("%s · %s" % [_phase_name(phase), str(game.state["players"][turn_id]["name"])] , 15, MUTED))
	column.add_child(note)
	var develop := _button(_tr("develop"), BLUE, 50, 17)
	develop.disabled = not human_turn or phase != "actions" or game.count_owned_properties(turn_id) == 0
	develop.pressed.connect(_show_development)
	column.add_child(develop)
	var market := _button(_tr("market"), GOLD, 50, 17)
	market.disabled = not human_turn or phase != "actions"
	market.pressed.connect(_show_market)
	column.add_child(market)
	var trade := _button(_tr("trade"), Color("#9e83c1"), 50, 17)
	trade.disabled = not human_turn or phase != "actions" or _alive_player_count() < 2
	trade.pressed.connect(_show_trade)
	column.add_child(trade)
	var ledger := _button(_tr("ledger"), Color("#759552"), 50, 17)
	ledger.pressed.connect(_show_ledger)
	column.add_child(ledger)
	var rules := _button(_tr("rules"), Color("#40515b"), 50, 17)
	rules.pressed.connect(_show_rules)
	column.add_child(rules)
	var finish := _button(_tr("end_match"), RED, 50, 17)
	finish.disabled = not human_turn or phase != "actions"
	finish.pressed.connect(_confirm_finish_match)
	column.add_child(finish)
	var save_home := _secondary_button(_tr("save_home"), 46)
	save_home.pressed.connect(_save_and_home)
	column.add_child(save_home)
	var close := _button(_tr("back_to_game"), BLUE)
	close.pressed.connect(_show_game)
	column.add_child(close)

func _show_portfolio() -> void:
	if game.state.is_empty():
		return
	screen_name = "portfolio"
	var players: Array = game.state["players"]
	var player_id := clampi(int(game.state.get("turn", 0)), 0, players.size() - 1)
	var player: Dictionary = players[player_id]
	var column := _begin_layout(_tr("portfolio_title"))
	_add_header(_tr("portfolio_title"), true)
	var total_income := 0
	for tile_index in game.country_tiles():
		if int(game.state["tile_owners"][tile_index]) == player_id:
			total_income += game.income_for_tile(tile_index)
	var worth: Dictionary = game.get_net_worth(player_id)
	var summary := _panel(Color("#18262f"), PLAYER_COLORS[player_id])
	summary.add_child(_label("%s  %s\n%s: %s · %s: %d\n%s: %s · %s: %s" % [_player_symbol(player_id), str(player["name"]), _tr("balance"), _money(int(player["balance"])), _tr("countries"), game.count_owned_properties(player_id), _tr("income"), _money(total_income), _tr("net_worth"), _money(int(worth.get("net_worth", 0)))], 16, PLAYER_COLORS[player_id]))
	column.add_child(summary)
	var goals: Dictionary = game.state.get("goals", [])[player_id] if game.state.get("goals", []).size() > player_id else {}
	var achievements: Dictionary = game.state.get("achievements", [])[player_id] if game.state.get("achievements", []).size() > player_id else {}
	var goals_panel := _panel(Color("#263846"), GOLD)
	goals_panel.add_child(_label("الأهداف الجانبية\nالثروة: %s / %s %s\nالتنويع: %d / %s قطاعات" % [_money(int(goals.get("wealth", {}).get("progress", 0))), _money(int(goals.get("wealth", {}).get("target", 0))), "✓" if bool(goals.get("wealth", {}).get("completed", false)) else "", int(goals.get("diversified", {}).get("progress", 0)), str(goals.get("diversified", {}).get("target", 0))], 15, TEXT))
	column.add_child(goals_panel)
	var achieved_names: Array[String] = []
	for achievement_id in achievements:
		if bool(achievements[achievement_id]):
			achieved_names.append(str(achievement_id))
	column.add_child(_label("الإنجازات: " + (", ".join(achieved_names) if not achieved_names.is_empty() else "لا توجد إنجازات بعد"), 14, Color("#b58cff")))
	var owned_count := 0
	for tile_index in game.country_tiles():
		if int(game.state["tile_owners"][tile_index]) != player_id:
			continue
		owned_count += 1
		var tile: Dictionary = BankGameModel.BOARD[tile_index]
		var level := int(game.state["development"][tile_index])
		var text := "%s %s\n%s: %s · %s: %s\n%s: %s · %s: %d/%d" % [_flag(tile_index), _tile_name(tile_index), _tr("price"), _money(int(tile["price"])), _tr("rent"), _money(game.rent_for_tile(tile_index)), _tr("income"), _money(game.income_for_tile(tile_index)), _tr("development"), level, BankGameModel.DEV_COSTS.size()]
		if game.owns_complete_group(player_id, int(tile["group"])):
			text += "\n" + _tr("group_bonus")
		var property_panel := _panel(PANEL_ALT, GROUP_COLORS[int(tile["group"])])
		property_panel.add_child(_label(text, 15, TEXT))
		column.add_child(property_panel)
	if owned_count == 0:
		column.add_child(_label(_tr("no_properties"), 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var investments: Array = game.state.get("investments", [])
	var owned_investments := 0
	for investment in investments:
		if int(investment.get("owner", -1)) != player_id:
			continue
		owned_investments += 1
		var text := "%s · %s · %s" % [_investment_name(str(investment["type"])), _tile_name(int(investment["tile"])), _tr("owner_you")]
		var investment_panel := _panel(PANEL_ALT, GREEN.darkened(0.3))
		investment_panel.add_child(_label(text, 15, TEXT))
		column.add_child(investment_panel)
	if owned_count == 0 and owned_investments == 0:
		column.add_child(_label(_tr("no_investments"), 15, MUTED))
	var close := _button(_tr("back_to_game"), BLUE)
	close.pressed.connect(_show_game)
	column.add_child(close)

func _show_ledger() -> void:
	if game.state.is_empty():
		return
	screen_name = "ledger"
	var column := _begin_layout(_tr("ledger_title"))
	_add_header(_tr("ledger_title"), true)
	var ledger: Array = game.state.get("ledger", [])
	if ledger.is_empty():
		column.add_child(_label(_tr("no_transactions"), 17, MUTED))
	else:
		for index in range(ledger.size() - 1, -1, -1):
			var entry: Dictionary = ledger[index]
			var player_id := int(entry.get("player", -1))
			var category := str(entry.get("category", ""))
			var recipient := int(entry.get("recipient", -1))
			var amount := int(entry.get("amount", 0))
			var reason := _tr("reason") + ": " + (_category_label(category) if locale != "ar" else str(entry.get("reason", _category_label(category))))
			var beneficiary := str(game.state["players"][recipient]["name"]) if recipient >= 0 and recipient < game.state["players"].size() else _tr("bank")
			var text := "%s  %s · %s\n%s: %s\n%s: %s · %s: %s\n%s: %s" % [_player_symbol(player_id), str(game.state["players"][player_id]["name"]), _category_label(category), reason, _signed_money(amount), _tr("beneficiary"), beneficiary, _tr("after_balance"), _money(int(entry.get("balance_after", 0))), _tr("round"), str(entry.get("turn", ""))]
			column.add_child(_panel(PANEL_ALT, PLAYER_COLORS[player_id].darkened(0.25)))
			var row: PanelContainer = column.get_child(column.get_child_count() - 1)
			row.add_child(_label(text, 15, GREEN if amount >= 0 else RED))
	var close := _button(_tr("back_to_game"), BLUE)
	close.pressed.connect(_show_game)
	column.add_child(close)

func _signed_money(amount: int) -> String:
	return ("+" if amount > 0 else "") + _money(amount)

func _category_label(category: String) -> String:
	var key := "category_" + category
	return _tr(key)

func _show_trade() -> void:
	if game.state.is_empty():
		return
	screen_name = "trade"
	var player_id := int(game.state.get("turn", 0))
	var column := _begin_layout(_tr("trade_title"))
	_add_header(_tr("trade_title"), true)
	if str(game.state.get("phase", "")) != "actions" or not game.is_human_player(player_id):
		column.add_child(_label(_tr("phase_actions"), 17, MUTED))
		return
	var target_option := OptionButton.new()
	var target_ids: Array[int] = []
	for i in range(game.state["players"].size()):
		if i == player_id or not bool(game.state["players"][i].get("alive", true)):
			continue
		target_ids.append(i)
		target_option.add_item("%s  %s" % [_player_symbol(i), str(game.state["players"][i]["name"])], i)
	_style_option(target_option)
	column.add_child(_label(_tr("trade_target"), 18, GOLD))
	column.add_child(target_option)
	var give_option := OptionButton.new()
	give_option.add_item(_tr("no_tile"), -1)
	for tile_index in BankGameModel.country_tiles():
		if int(game.state["tile_owners"][tile_index]) == player_id:
			give_option.add_item(_tile_name(tile_index), tile_index)
	_style_option(give_option)
	column.add_child(_label(_tr("give_tile"), 17, TEXT))
	column.add_child(give_option)
	var ask_option := OptionButton.new()
	ask_option.add_item(_tr("no_tile"), -1)
	var selected_target := target_option.get_selected_id() if target_option.item_count > 0 else -1
	for tile_index in BankGameModel.country_tiles():
		if int(game.state["tile_owners"][tile_index]) == selected_target:
			ask_option.add_item(_tile_name(tile_index), tile_index)
	_style_option(ask_option)
	column.add_child(_label(_tr("ask_tile"), 17, TEXT))
	column.add_child(ask_option)
	target_option.item_selected.connect(func(_idx: int): _refresh_trade_target_tiles(target_option, ask_option, player_id))
	var give_cash := _spinbox()
	var ask_cash := _spinbox()
	column.add_child(_label(_tr("give_cash"), 17, TEXT))
	column.add_child(give_cash)
	column.add_child(_label(_tr("ask_cash"), 17, TEXT))
	column.add_child(ask_cash)
	var offer_button := _button(_tr("offer"), GREEN)
	offer_button.pressed.connect(func(): _submit_trade(player_id, target_option, give_option, ask_option, give_cash, ask_cash))
	column.add_child(offer_button)
	var note := _panel()
	note.add_child(_label(_tr("confirm_trade"), 15, MUTED))
	column.add_child(note)

func _spinbox() -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 999999
	spin.step = 50
	spin.rounded = true
	spin.custom_minimum_size.y = 46
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin

func _refresh_trade_target_tiles(target_option: OptionButton, ask_option: OptionButton, proposer: int) -> void:
	var selected := target_option.get_selected_id()
	ask_option.clear()
	ask_option.add_item(_tr("no_tile"), -1)
	for tile_index in BankGameModel.country_tiles():
		if int(game.state["tile_owners"][tile_index]) == selected and selected != proposer:
			ask_option.add_item(_tile_name(tile_index), tile_index)

func _submit_trade(player_id: int, target_option: OptionButton, give_option: OptionButton, ask_option: OptionButton, give_cash: SpinBox, ask_cash: SpinBox) -> void:
	var target := target_option.get_selected_id()
	var give_tile := give_option.get_selected_id()
	var ask_tile := ask_option.get_selected_id()
	var details := _tr("give_tile") + ": " + (_tile_name(give_tile) if give_tile >= 0 else _tr("none")) + " · " + _tr("give_cash") + ": " + _money(int(give_cash.value)) + "\n" + _tr("ask_tile") + ": " + (_tile_name(ask_tile) if ask_tile >= 0 else _tr("none")) + " · " + _tr("ask_cash") + ": " + _money(int(ask_cash.value))
	_confirm(_tr("confirm"), _tr("confirm_trade") + "\n" + details, func(): _perform_trade(player_id, target, give_tile, ask_tile, int(give_cash.value), int(ask_cash.value)))

func _perform_trade(player_id: int, target: int, give_tile: int, ask_tile: int, give_cash: int, ask_cash: int) -> void:
	var result: Dictionary = game.propose_trade(player_id, target, give_tile, ask_tile, give_cash, ask_cash)
	if not bool(result.get("ok", false)):
		last_feedback = _tr("insufficient")
		last_feedback_color = RED
		_show_game()
		return
	if bool(result.get("pending", false)):
		last_feedback = _tr("trade_pending")
		last_feedback_color = BLUE
		_save_game_state()
		_show_trade_response()
		return
	last_feedback = _tr("ai_accepted") if bool(result.get("accepted", false)) else _tr("ai_rejected")
	last_feedback_color = GREEN if bool(result.get("accepted", false)) else MUTED
	_save_game_state()
	_show_game()

func _show_trade_response() -> void:
	screen_name = "trade_response"
	var column := _begin_layout(_tr("trade_pending"))
	var offer: Dictionary = game.state.get("pending_trade", {})
	if offer.is_empty():
		_show_game()
		return
	var target := int(offer.get("to", -1))
	_add_header(_tr("trade_pending"))
	var proposer := int(offer.get("from", -1))
	var terms := "%s: %s\n%s: %s\n%s: %s\n%s: %s" % [_tr("give_tile"), _tile_name(int(offer.get("give_tile", -1))) if int(offer.get("give_tile", -1)) >= 0 else _tr("none"), _tr("give_cash"), _money(int(offer.get("give_cash", 0))), _tr("ask_tile"), _tile_name(int(offer.get("ask_tile", -1))) if int(offer.get("ask_tile", -1)) >= 0 else _tr("none"), _tr("ask_cash"), _money(int(offer.get("ask_cash", 0)))]
	var card := _panel(Color("#18262f"), PLAYER_COLORS[maxi(0, proposer)])
	card.add_child(_label(_trf("pass_phone", {"name": str(game.state["players"][target]["name"])}), 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(_label(terms, 17, TEXT))
	column.add_child(card)
	var row := HBoxContainer.new()
	var accept := _button(_tr("accept"), GREEN)
	accept.pressed.connect(_respond_trade.bind(true))
	var reject := _button(_tr("reject"), RED)
	reject.pressed.connect(_respond_trade.bind(false))
	var counter := _secondary_button("تقديم عرض مضاد", 50)
	counter.pressed.connect(_counter_trade)
	row.add_child(accept)
	row.add_child(reject)
	row.add_child(counter)
	column.add_child(row)

func _respond_trade(accept: bool) -> void:
	var target := int(game.state.get("pending_trade", {}).get("to", -1))
	var result: Dictionary = game.respond_to_trade(target, accept)
	last_feedback = _tr("trade_done") if accept and bool(result.get("ok", false)) else _tr("trade_rejected")
	last_feedback_color = GREEN if accept and bool(result.get("ok", false)) else MUTED
	_save_game_state()
	_show_game()

func _counter_trade() -> void:
	var offer: Dictionary = game.state.get("pending_trade", {})
	var target := int(offer.get("to", -1))
	var result: Dictionary = game.counter_offer(target, int(offer.get("ask_tile", -1)), int(offer.get("give_tile", -1)), int(offer.get("ask_cash", 0)), int(offer.get("give_cash", 0)))
	last_feedback = "تم تقديم العرض المضاد." if bool(result.get("ok", false)) else str(result.get("message", _tr("unknown")))
	last_feedback_color = Color("#b58cff") if bool(result.get("ok", false)) else RED
	_save_game_state()
	if bool(result.get("ok", false)):
		_show_trade_response()
	else:
		_show_game()

func _populate_obligation_panel(player_id: int) -> void:
	for child in obligation_content.get_children():
		child.queue_free()
	if str(game.state.get("phase", "")) == "jail":
		var player: Dictionary = game.state["players"][player_id]
		var remaining := int(player.get("jail_turns_remaining", 0))
		obligation_content.add_child(_label(_tr("jail_status_title"), 19, RED, HORIZONTAL_ALIGNMENT_CENTER))
		obligation_content.add_child(_label(_trf("jail_status_detail", {"turns": remaining, "amount": _money(int(BankGameModel.BOARD[BankGameModel.JAIL_TILE].get("bail", 500)))}), 16, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		var bail := _button(_tr("jail_pay_bail"), GOLD, 48, 16)
		bail.disabled = int(game.get_balance(player_id)) < int(BankGameModel.BOARD[BankGameModel.JAIL_TILE].get("bail", 500))
		bail.pressed.connect(_perform_jail_bail)
		obligation_content.add_child(bail)
		var wait := _secondary_button(_tr("jail_wait"), 46)
		wait.pressed.connect(_perform_jail_wait)
		obligation_content.add_child(wait)
		return
	var obligation: Dictionary = game.pending_obligation()
	var due := int(obligation.get("amount", 0))
	var balance := int(game.get_balance(player_id))
	var shortfall := maxi(0, due - balance)
	obligation_content.add_child(_label(_tr("obligation_title"), 19, RED, HORIZONTAL_ALIGNMENT_CENTER))
	obligation_content.add_child(_label("%s: %s  ·  %s: %s" % [_tr("due"), _money(due), _tr("shortfall"), _money(shortfall)], 16, TEXT))
	var has_asset := false
	var investments: Array = game.state.get("investments", [])
	for index in range(investments.size()):
		var investment: Dictionary = investments[index]
		if int(investment.get("owner", -1)) != player_id:
			continue
		has_asset = true
		var refund := int(investment.get("cost", 0)) / 2
		var sale := _secondary_button("%s · %s · %s: %s" % [_tr("liquidate_investment"), _investment_name(str(investment["type"])), _tr("asset_value"), _money(refund)], 48)
		sale.pressed.connect(_confirm_obligation_investment.bind(index))
		obligation_content.add_child(sale)
	for tile_index in BankGameModel.country_tiles():
		if int(game.state["tile_owners"][tile_index]) != player_id:
			continue
		has_asset = true
		var downgrade_level := int(game.state["development"][tile_index])
		if downgrade_level > 0:
			var downgrade_refund := int(BankGameModel.DEV_COSTS[downgrade_level - 1] * 0.25)
			var downgrade := _secondary_button("%s · %s · %s: %s" % [_tr("downgrade"), _tile_name(tile_index), _tr("asset_value"), _money(downgrade_refund)], 48)
			downgrade.pressed.connect(_confirm_obligation_downgrade.bind(tile_index))
			obligation_content.add_child(downgrade)
		var refund := _property_refund(tile_index)
		var sale := _button("%s · %s · %s: %s" % [_tr("liquidate_property"), _tile_name(tile_index), _tr("asset_value"), _money(refund)], Color("#675047"), 50, 15)
		sale.pressed.connect(_confirm_obligation_property.bind(tile_index))
		obligation_content.add_child(sale)
		if not has_asset:
			obligation_content.add_child(_label(_tr("no_assets"), 16, MUTED))
			var bankruptcy := _button(_tr("bankruptcy"), RED)
			bankruptcy.pressed.connect(_confirm_bankruptcy)
			obligation_content.add_child(bankruptcy)

func _perform_jail_bail() -> void:
	var result: Dictionary = game.pay_jail_bail(int(game.state["turn"]))
	last_feedback = str(result.get("message", _tr("unknown")))
	last_feedback_color = GREEN if bool(result.get("ok", false)) else RED
	_save_game_state()
	_update_game_view()

func _perform_jail_wait() -> void:
	var result: Dictionary = game.end_turn(int(game.state["turn"]))
	last_feedback = str(result.get("message", _tr("unknown")))
	last_feedback_color = BLUE if bool(result.get("ok", false)) else RED
	_save_game_state()
	_show_game()
	_maybe_run_cpu_turn()

func _property_refund(tile_index: int) -> int:
	var refund := int(BankGameModel.BOARD[tile_index]["price"]) / 2
	var level := int(game.state["development"][tile_index])
	for i in range(level):
		refund += int(BankGameModel.DEV_COSTS[i]) / 2
	for investment in game.state.get("investments", []):
		if int(investment.get("tile", -1)) == tile_index:
			refund += int(investment.get("cost", 0)) / 2
	return refund

func _confirm_obligation_investment(index: int) -> void:
	_confirm(_tr("confirm"), _tr("confirm_sell") + "\n" + _tr("sell_investment"), func(): _perform_obligation_investment(index))

func _perform_obligation_investment(index: int) -> void:
	var player_id := int(game.state["turn"])
	var result: Dictionary = game.sell_investment(player_id, index)
	last_feedback = _tr("settled") if str(game.state.get("phase", "")) != "obligation" else _tr("sale_done")
	last_feedback_color = GREEN
	_save_game_state()
	_show_game()

func _confirm_obligation_property(tile_index: int) -> void:
	_confirm(_tr("confirm"), _tr("confirm_sell") + "\n" + _tile_name(tile_index) + " · " + _money(_property_refund(tile_index)), func(): _perform_obligation_property(tile_index))

func _perform_obligation_property(tile_index: int) -> void:
	var player_id := int(game.state["turn"])
	game.sell_property(player_id, tile_index)
	last_feedback = _tr("settled") if str(game.state.get("phase", "")) != "obligation" else _tr("sale_done")
	last_feedback_color = GREEN
	_save_game_state()
	_show_game()

func _confirm_obligation_downgrade(tile_index: int) -> void:
	_confirm(_tr("confirm"), _tr("confirm_sell") + "\n" + _tile_name(tile_index) + " · " + _tr("downgrade"), func(): _perform_obligation_downgrade(tile_index))

func _perform_obligation_downgrade(tile_index: int) -> void:
	var player_id := int(game.state["turn"])
	game.downgrade_property(player_id, tile_index)
	last_feedback = _tr("settled") if str(game.state.get("phase", "")) != "obligation" else _tr("sale_done")
	last_feedback_color = GREEN
	_save_game_state()
	_show_game()

func _confirm_bankruptcy() -> void:
	_confirm(_tr("bankruptcy"), _tr("confirm_bankruptcy"), _perform_bankruptcy)

func _perform_bankruptcy() -> void:
	var result: Dictionary = game.declare_bankruptcy(int(game.state["turn"]))
	last_feedback = _tr("bankruptcy_done") if bool(result.get("ok", false)) else _tr("no_assets")
	last_feedback_color = RED
	_save_game_state()
	_show_game()

func _populate_result_panel() -> void:
	for child in result_content.get_children():
		child.queue_free()
	result_content.add_child(_label(_tr("final_summary"), 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var winner_id := int(game.state.get("winner_id", -1))
	var winner_name := str(game.state["players"][winner_id]["name"]) if winner_id >= 0 and winner_id < game.state["players"].size() else _tr("unknown")
	result_content.add_child(_label(_tr("winner") + ": " + winner_name, 20, GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	var reason := str(game.state.get("result", {}).get("reason", ""))
	result_content.add_child(_label(_tr("winner_reason") + ": " + (_tr("round_end") if reason.contains("الجولات") else reason if locale == "ar" else _tr("game_over")), 15, MUTED))
	for player_id in range(game.state["players"].size()):
		var worth: Dictionary = game.get_net_worth(player_id)
		var summary := "%s %s\n%s: %s · %s: %s\n%s: %s · %s: %s\n%s: %s · %s: %s" % [_player_symbol(player_id), str(game.state["players"][player_id]["name"]), _tr("cash_value"), _money(int(worth.get("cash", 0))), _tr("property_value"), _money(int(worth.get("property_value", 0))), _tr("development_value"), _money(int(worth.get("development_value", 0))), _tr("investment_value"), _money(int(worth.get("investment_value", 0))), _tr("debt_value"), _money(int(worth.get("debt", 0))), _tr("net_worth"), _money(int(worth.get("net_worth", 0)))]
		result_content.add_child(_panel(PANEL_ALT, PLAYER_COLORS[player_id]))
		var row: PanelContainer = result_content.get_child(result_content.get_child_count() - 1)
		row.add_child(_label(summary, 15, TEXT))
	var new_game := _button(_tr("play_again"), GREEN)
	new_game.pressed.connect(_show_setup)
	result_content.add_child(new_game)
	var home := _secondary_button(_tr("back"))
	home.pressed.connect(_show_home)
	result_content.add_child(home)

func _confirm_finish_match() -> void:
	_confirm(_tr("end_match"), _tr("confirm_end"), _perform_finish_match)

func _perform_finish_match() -> void:
	var result: Dictionary = game.finish_match_by_user(int(game.state["turn"]))
	if bool(result.get("ok", false)):
		last_feedback = _tr("game_over")
		_save_game_state()
		_show_game()

func _alive_player_count() -> int:
	var count := 0
	for player in game.state.get("players", []):
		if bool(player.get("alive", true)):
			count += 1
	return count

func _confirm(title: String, details: String, action: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = details
	dialog.ok_button_text = _tr("confirm")
	dialog.get_cancel_button().text = _tr("cancel")
	dialog.min_size = Vector2i(360, 210)
	dialog.layout_direction = Control.LAYOUT_DIRECTION_RTL if locale == "ar" else Control.LAYOUT_DIRECTION_LTR
	add_child(dialog)
	dialog.confirmed.connect(func():
		action.call()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _save_game_state() -> void:
	if game == null or game.state.is_empty():
		return
	var result: Dictionary = game.save_to(SAVE_FILE)
	resume_available = bool(result.get("ok", false))
	if not resume_available:
		last_feedback = _tr("save_error")
		last_feedback_color = RED

func _save_and_home() -> void:
	_save_game_state()
	_show_home()

func _on_home_pressed() -> void:
	_save_and_home()
