extends Control

const BankGameModel = preload("res://scripts/game/bank_game.gd")
const ARABIC_FONT = preload("res://assets/fonts/Amiri-Regular.ttf")
const SAVE_FILE := "user://luckbank-save.json"
const SETTINGS_FILE := "user://luckbank-settings.cfg"

const BG := Color("#101820")
const PANEL := Color("#1c2a34")
const TILE := Color("#243541")
const TEXT := Color("#f3f0e9")
const MUTED := Color("#b7c2c8")
const GOLD := Color("#e6bb62")
const GREEN := Color("#71c5a2")
const BLUE := Color("#77b8e8")
const RED := Color("#e47e72")
const COUNTRY_COLORS := [Color("#4c9e86"), Color("#4c83a8"), Color("#916eae"), Color("#bc8754"), Color("#aa687c"), Color("#759552")]
const PLAYER_SYMBOLS := ["●١", "◆٢", "▲٣", "■٤"]
const PLAYER_COLORS := [Color("#e6bb62"), Color("#77b8e8"), Color("#71c5a2"), Color("#e47e72")]
const MODE_COMPUTER := "computer"
const MODE_LOCAL := "local"
const TILE_COORDS := {
	"0,0": 0, "1,0": 1, "2,0": 2, "3,0": 3,
	"3,1": 4, "3,2": 5, "3,3": 6, "2,3": 7,
	"1,3": 8, "0,3": 9, "0,2": 10, "0,1": 11
}

var game: BankGameModel
var screen_name := "home"
var resume_available := false
var startup_notice := ""
var settings := {"fast_cpu": false}
var cpu_delay := 0.75
var cpu_running := false
var animation_lock := false
var animated_positions: Array = []
var tile_widgets: Array = []
var stat_names: Array[Label] = []
var stat_balances: Array[Label] = []
var stat_ownerships: Array[Label] = []
var stat_positions: Array[Label] = []
var player_name_inputs: Array[LineEdit] = []
var name_input_rows: Array[Control] = []
var friend_player_count := 2
var friend_count_option: OptionButton
var selected_mode := ""
var last_landed_player_id := 0
var feedback_label: Label
var log_label: Label
var dice_label: Label
var turn_label: Label
var roll_button: Button
var property_panel: PanelContainer
var property_text: Label
var purchase_buttons: HBoxContainer
var buy_button: Button
var skip_button: Button
var result_panel: PanelContainer
var result_text: Label
var center_dice: Label
var center_status: Label
var center_hint: Label
var settings_value_label: Label
var main_column: VBoxContainer
var app_theme: Theme

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	game = BankGameModel.new()
	_setup_theme()
	_load_settings()
	_check_saved_match()
	_show_home()

func _setup_theme() -> void:
	app_theme = Theme.new()
	app_theme.default_font = ARABIC_FONT
	app_theme.default_font_size = 20
	for type_name in ["Label", "Button", "LineEdit", "CheckBox", "OptionButton"]:
		app_theme.set_color("font_color", type_name, TEXT)
		app_theme.set_color("font_hover_color", type_name, TEXT)
		app_theme.set_color("font_pressed_color", type_name, TEXT)
		app_theme.set_color("font_disabled_color", type_name, MUTED.darkened(0.25))
		app_theme.set_font("font", type_name, ARABIC_FONT)
	theme = app_theme

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		settings["fast_cpu"] = bool(config.get_value("game", "fast_cpu", false))
	cpu_delay = 0.28 if bool(settings["fast_cpu"]) else 0.75

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "fast_cpu", bool(settings["fast_cpu"]))
	config.save(SETTINGS_FILE)
	cpu_delay = 0.28 if bool(settings["fast_cpu"]) else 0.75

func _check_saved_match() -> void:
	var probe = BankGameModel.new()
	var result: Dictionary = probe.load_from(SAVE_FILE)
	resume_available = bool(result.get("ok", false))
	if bool(result.get("corrupt", false)):
		startup_notice = "تعذر استكمال الحفظ السابق لأنه تالف. يمكنك بدء مباراة جديدة."

func _clear_screen() -> void:
	for child in get_children():
		child.queue_free()
	tile_widgets.clear()
	stat_names.clear()
	stat_balances.clear()
	stat_ownerships.clear()
	stat_positions.clear()
	player_name_inputs.clear()
	name_input_rows.clear()

func _begin_layout(title_text: String = "") -> VBoxContainer:
	_clear_screen()
	var backdrop := ColorRect.new()
	backdrop.color = BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)
	main_column = VBoxContainer.new()
	main_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_column.add_theme_constant_override("separation", 10)
	main_column.layout_direction = Control.LAYOUT_DIRECTION_RTL
	margin.add_child(main_column)
	if not title_text.is_empty():
		var title := _label(title_text, 29, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		main_column.add_child(title)
	return main_column

func _label(text: String, size: int = 20, color: Color = TEXT, alignment: int = HORIZONTAL_ALIGNMENT_RIGHT) -> Label:
	var item := Label.new()
	item.text = text
	item.horizontal_alignment = alignment
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.text_direction = Control.TEXT_DIRECTION_RTL
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
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	result.add_theme_stylebox_override("panel", style)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func _button(text: String, color: Color = GOLD, min_height: int = 58) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, min_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.layout_direction = Control.LAYOUT_DIRECTION_RTL
	button.text_direction = Control.TEXT_DIRECTION_RTL
	button.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.12)
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

func _secondary_button(text: String, min_height: int = 54) -> Button:
	return _button(text, Color("#40515b"), min_height)

func _show_home() -> void:
	screen_name = "home"
	_check_saved_match()
	var column := _begin_layout()
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size.y = 20
	column.add_child(top_spacer)
	var logo := _label("اختبار بنك الحظ", 42, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	logo.custom_minimum_size.y = 72
	column.add_child(logo)
	column.add_child(_label("لعبة لوحية اقتصادية — الكمبيوتر أو الأصدقاء", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var rules := _panel(Color("#1a2831"), GOLD.darkened(0.45))
	rules.add_child(_label("ارمِ النرد، اشترِ الدول، واجمع الإيجار.
العب ضد الكمبيوتر أو بالتناوب مع الأصدقاء.", 20, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(rules)
	var gap := Control.new()
	gap.custom_minimum_size.y = 12
	column.add_child(gap)
	var new_button := _button("لعبة جديدة", GOLD, 66)
	new_button.name = "NewGameButton"
	new_button.pressed.connect(_show_setup)
	column.add_child(new_button)
	var continue_button := _button("استكمال اللعبة المحفوظة", GREEN, 62)
	continue_button.name = "ContinueMatchButton"
	continue_button.disabled = not resume_available
	continue_button.pressed.connect(_resume_match)
	column.add_child(continue_button)
	var settings_button := _secondary_button("الإعدادات")
	settings_button.name = "SettingsButton"
	settings_button.pressed.connect(_show_settings)
	column.add_child(settings_button)
	var exit_button := _secondary_button("خروج")
	exit_button.name = "ExitButton"
	exit_button.pressed.connect(func(): get_tree().quit())
	column.add_child(exit_button)
	var footer_gap := Control.new()
	footer_gap.custom_minimum_size.y = 10
	column.add_child(footer_gap)
	var notice := _label(startup_notice, 17, RED, HORIZONTAL_ALIGNMENT_CENTER)
	notice.visible = not startup_notice.is_empty()
	column.add_child(notice)

func _show_setup() -> void:
	screen_name = "mode_selection"
	selected_mode = ""
	var column := _begin_layout("لعبة جديدة")
	column.add_child(_label("اختر أسلوب اللعب", 23, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var computer_button := _button("اللعب ضد الكمبيوتر", GOLD, 68)
	computer_button.name = "PlayVsComputerButton"
	computer_button.pressed.connect(func(): _show_player_setup(MODE_COMPUTER))
	column.add_child(computer_button)
	var friend_button := _button("اللعب مع صديق", BLUE, 68)
	friend_button.name = "PlayWithFriendButton"
	friend_button.pressed.connect(func(): _show_player_setup(MODE_LOCAL))
	column.add_child(friend_button)
	var explain := _panel(Color("#1a2831"), Color("#344956"))
	explain.add_child(_label("ضد الكمبيوتر: يلعب الخصم تلقائيًا.
مع صديق: يتناوب 2–4 لاعبين على الهاتف نفسه.", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(explain)
	var back := _secondary_button("العودة للقائمة")
	back.name = "BackToHomeButton"
	back.pressed.connect(_show_home)
	column.add_child(back)

func _show_player_setup(mode: String) -> void:
	if mode != MODE_COMPUTER and mode != MODE_LOCAL:
		_show_setup()
		return
	selected_mode = mode
	screen_name = "player_setup"
	friend_player_count = 2
	var title := "إعداد اللعب مع صديق" if mode == MODE_LOCAL else "إعداد اللعب ضد الكمبيوتر"
	var column := _begin_layout(title)
	var info := _panel()
	var info_text := "يتحكم كل لاعب بدوره على الهاتف نفسه." if mode == MODE_LOCAL else "بعد دورك يرمي الكمبيوتر ويتحرك ويقرر الشراء بنفسه."
	info.add_child(_label(info_text, 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(info)
	if mode == MODE_LOCAL:
		var count_panel := _panel()
		var count_box := VBoxContainer.new()
		count_box.add_child(_label("عدد اللاعبين", 20, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		friend_count_option = OptionButton.new()
		friend_count_option.name = "FriendPlayerCount"
		friend_count_option.custom_minimum_size.y = 54
		friend_count_option.add_item("لاعبان", 2)
		friend_count_option.add_item("3 لاعبين", 3)
		friend_count_option.add_item("4 لاعبين", 4)
		friend_count_option.select(0)
		friend_count_option.item_selected.connect(_on_friend_count_selected)
		count_box.add_child(friend_count_option)
		count_panel.add_child(count_box)
		column.add_child(count_panel)
	var names_panel := _panel()
	var setup_name_fields := VBoxContainer.new()
	setup_name_fields.add_theme_constant_override("separation", 8)
	var field_count := 4 if mode == MODE_LOCAL else 1
	for index in range(field_count):
		var field_row := VBoxContainer.new()
		field_row.add_child(_label("اسم اللاعب %d" % (index + 1), 17, MUTED))
		var input := LineEdit.new()
		input.name = "PlayerName%d" % index
		input.placeholder_text = "اللاعب %d" % (index + 1)
		input.text = "اللاعب" if index == 0 else "اللاعب %d" % (index + 1)
		input.max_length = 24
		input.custom_minimum_size.y = 54
		input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		input.virtual_keyboard_enabled = true
		input.text_direction = Control.TEXT_DIRECTION_AUTO
		var edit_style := StyleBoxFlat.new()
		edit_style.bg_color = Color("#101820")
		edit_style.set_corner_radius_all(10)
		edit_style.set_border_width_all(1)
		edit_style.border_color = Color("#526773")
		edit_style.content_margin_left = 10
		edit_style.content_margin_right = 10
		input.add_theme_stylebox_override("normal", edit_style)
		input.add_theme_stylebox_override("focus", edit_style)
		field_row.add_child(input)
		setup_name_fields.add_child(field_row)
		name_input_rows.append(field_row)
		player_name_inputs.append(input)
	names_panel.add_child(setup_name_fields)
	column.add_child(names_panel)
	_update_name_field_visibility()
	var start_button := _button("ابدأ المباراة", GOLD, 64)
	start_button.name = "StartMatchButton"
	start_button.pressed.connect(_start_new_match)
	column.add_child(start_button)
	var back := _secondary_button("اختيار نمط آخر")
	back.name = "BackToModesButton"
	back.pressed.connect(_show_setup)
	column.add_child(back)
	if not player_name_inputs.is_empty():
		player_name_inputs[0].grab_focus()

func _on_friend_count_selected(index: int) -> void:
	if not is_instance_valid(friend_count_option) or index < 0 or index >= friend_count_option.item_count:
		return
	friend_player_count = clampi(friend_count_option.get_item_id(index), 2, BankGameModel.MAX_LOCAL_PLAYERS)
	_update_name_field_visibility()

func _update_name_field_visibility() -> void:
	var visible_count := friend_player_count if selected_mode == MODE_LOCAL else 1
	for index in range(name_input_rows.size()):
		name_input_rows[index].visible = index < visible_count

func _start_new_match() -> void:
	if selected_mode != MODE_COMPUTER and selected_mode != MODE_LOCAL:
		_show_setup()
		return
	if player_name_inputs.is_empty():
		_feedback("أدخل أسماء اللاعبين قبل البدء.", RED)
		return
	var first_name := player_name_inputs[0].text.strip_edges()
	if first_name.is_empty():
		first_name = "اللاعب"
	if selected_mode == MODE_LOCAL:
		var names: Array = []
		for index in range(friend_player_count):
			names.append(player_name_inputs[index].text.strip_edges())
		game.new_game(first_name, MODE_LOCAL, names)
	else:
		game.new_game(first_name, MODE_COMPUTER)
	var save_result: Dictionary = game.save_to(SAVE_FILE)
	if not bool(save_result.get("ok", false)):
		startup_notice = str(save_result.get("message", "تعذر حفظ المباراة."))
	_open_game_screen()

func _resume_match() -> void:
	var result: Dictionary = game.load_from(SAVE_FILE)
	if not bool(result.get("ok", false)):
		startup_notice = str(result.get("message", "تعذر استعادة المباراة."))
		resume_available = false
		_show_home()
		return
	if bool(result.get("migrated", false)):
		var migration_save: Dictionary = game.save_to(SAVE_FILE)
		if not bool(migration_save.get("ok", false)):
			startup_notice = "استُعيد الحفظ القديم، لكن تعذر ترحيله إلى الصيغة الجديدة."
	_open_game_screen()

func _show_settings() -> void:
	screen_name = "settings"
	var column := _begin_layout("الإعدادات")
	var settings_card := _panel()
	var settings_box := VBoxContainer.new()
	settings_box.add_child(_label("سرعة دور الكمبيوتر", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	settings_box.add_child(_label("يتوقف الكمبيوتر قليلًا بين الرمي والحركة لتتابع دوره.", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	settings_value_label = _label("", 21, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	settings_box.add_child(settings_value_label)
	settings_card.add_child(settings_box)
	column.add_child(settings_card)
	var speed_button := _button("تغيير سرعة الكمبيوتر", BLUE)
	speed_button.name = "FastCpuToggleButton"
	speed_button.pressed.connect(_toggle_cpu_speed)
	column.add_child(speed_button)
	var save_card := _panel()
	save_card.add_child(_label("الحفظ محلي على هذا الجهاز ولا يحتاج إلى الإنترنت.", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(save_card)
	var back := _secondary_button("العودة للقائمة")
	back.name = "SettingsBackButton"
	back.pressed.connect(_show_home)
	column.add_child(back)
	_update_settings_text()

func _toggle_cpu_speed() -> void:
	settings["fast_cpu"] = not bool(settings["fast_cpu"])
	_save_settings()
	_update_settings_text()

func _update_settings_text() -> void:
	if is_instance_valid(settings_value_label):
		settings_value_label.text = "سريع" if bool(settings["fast_cpu"]) else "عادي"

func _open_game_screen() -> void:
	screen_name = "game"
	last_landed_player_id = clampi(int(game.state.get("turn", 0)), 0, game.state["players"].size() - 1)
	cpu_running = false
	animation_lock = false
	animated_positions.clear()
	for _index in range(game.state["players"].size()):
		animated_positions.append(-1)
	var column := _begin_layout()
	_build_player_hud(column)
	var status_panel := _panel()
	var status_box := VBoxContainer.new()
	turn_label = _label("", 19, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	status_box.add_child(turn_label)
	feedback_label = _label("", 19, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	feedback_label.custom_minimum_size.y = 48
	status_box.add_child(feedback_label)
	status_panel.add_child(status_box)
	column.add_child(status_panel)
	property_panel = _make_purchase_panel()
	column.add_child(property_panel)
	_build_board(column)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	roll_button = _button("ارمِ النرد", GOLD, 66)
	roll_button.name = "RollButton"
	roll_button.pressed.connect(_on_roll_pressed)
	action_row.add_child(roll_button)
	var dice_box := _panel(Color("#22333e"), Color("#607784"))
	dice_label = _label("—", 35, BLUE, HORIZONTAL_ALIGNMENT_CENTER)
	dice_box.add_child(dice_label)
	dice_box.custom_minimum_size.x = 88
	action_row.add_child(dice_box)
	column.add_child(action_row)
	var log_panel := _panel(Color("#17242d"), Color("#344956"), 10)
	log_label = _label("", 16, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	log_label.custom_minimum_size.y = 52
	log_panel.add_child(log_label)
	column.add_child(log_panel)
	result_panel = _panel(Color("#2b2221"), RED, 16)
	var result_box := VBoxContainer.new()
	result_text = _label("", 21, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	result_box.add_child(result_text)
	var replay := _button("مباراة جديدة", GOLD)
	replay.name = "ReplayButton"
	replay.pressed.connect(_show_setup)
	result_box.add_child(replay)
	result_panel.add_child(result_box)
	column.add_child(result_panel)
	var bottom_row := HBoxContainer.new()
	var save_exit := _secondary_button("حفظ والعودة للقائمة", 52)
	save_exit.name = "SaveAndHomeButton"
	save_exit.pressed.connect(_save_and_home)
	bottom_row.add_child(save_exit)
	var home_button := _secondary_button("القائمة الرئيسية", 52)
	home_button.name = "ReturnHomeButton"
	home_button.pressed.connect(_show_home)
	bottom_row.add_child(home_button)
	column.add_child(bottom_row)
	_update_game_screen()
	if bool(game.state.get("active", false)) and game.is_computer_player(int(game.state.get("turn", -1))):
		call_deferred("_run_cpu_turn")

func _build_player_hud(column: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.name = "PlayerHUD"
	grid.columns = 2
	grid.layout_direction = Control.LAYOUT_DIRECTION_RTL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for index in range(game.state["players"].size()):
		var player: Dictionary = game.state["players"][index]
		var card := _panel(Color("#1c2a34"), PLAYER_COLORS[index], 12)
		card.name = "PlayerCard%d" % index
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 2)
		var name_label := _label("", 18, PLAYER_COLORS[index].lightened(0.15), HORIZONTAL_ALIGNMENT_CENTER)
		name_label.name = "PlayerNameLabel%d" % index
		var balance_label := _label("", 19, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		var ownership_label := _label("", 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		var position_label := _label("", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		position_label.custom_minimum_size.y = 36
		content.add_child(name_label)
		content.add_child(balance_label)
		content.add_child(ownership_label)
		content.add_child(position_label)
		card.add_child(content)
		grid.add_child(card)
		stat_names.append(name_label)
		stat_balances.append(balance_label)
		stat_ownerships.append(ownership_label)
		stat_positions.append(position_label)
	column.add_child(grid)

func _build_board(column: VBoxContainer) -> void:
	var board_panel := _panel(Color("#14212a"), Color("#344956"), 16)
	board_panel.name = "GameBoard"
	var grid := GridContainer.new()
	grid.columns = 4
	grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.add_child(grid)
	var tile_lookup: Dictionary = TILE_COORDS
	for row in range(4):
		for col in range(4):
			var key := "%d,%d" % [col, row]
			if tile_lookup.has(key):
				var tile_index := int(tile_lookup[key])
				var tile_panel := _panel(TILE, Color("#465a65"), 9)
				tile_panel.custom_minimum_size = Vector2(0, 108)
				var tile_content := VBoxContainer.new()
				tile_content.add_theme_constant_override("separation", 2)
				var tile_label := _label("", 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
				tile_label.name = "TileInfo%d" % tile_index
				tile_label.custom_minimum_size.y = 58
				var markers := HBoxContainer.new()
				markers.name = "TilePlayers%d" % tile_index
				markers.alignment = BoxContainer.ALIGNMENT_CENTER
				markers.add_theme_constant_override("separation", 1)
				tile_content.add_child(tile_label)
				tile_content.add_child(markers)
				tile_panel.add_child(tile_content)
				grid.add_child(tile_panel)
				while tile_widgets.size() <= tile_index:
					tile_widgets.append({})
				tile_widgets[tile_index] = {"panel": tile_panel, "label": tile_label, "markers": markers}
			else:
				var center := _panel(Color("#1b2b35"), Color("#2d424e"), 9)
				center.custom_minimum_size = Vector2(0, 78)
				var text_label := _label("", 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
				center.add_child(text_label)
				grid.add_child(center)
				if key == "1,1":
					center_status = text_label
				elif key == "2,1":
					center_dice = text_label
				elif key == "1,2":
					center_hint = text_label
				else:
					text_label.text = "مسار
12 محطة"
	column.add_child(board_panel)

func _make_purchase_panel() -> PanelContainer:
	var card := _panel(Color("#23323b"), GOLD, 13)
	card.name = "CurrentLocationCard"
	var box := VBoxContainer.new()
	property_text = _label("", 19, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	property_text.name = "CurrentLocationInfo"
	box.add_child(property_text)
	purchase_buttons = HBoxContainer.new()
	purchase_buttons.name = "PurchaseActionsRow"
	purchase_buttons.add_theme_constant_override("separation", 10)
	buy_button = _button("شراء الدولة", GREEN, 58)
	buy_button.name = "BuyPropertyButton"
	buy_button.pressed.connect(_on_buy_pressed)
	purchase_buttons.add_child(buy_button)
	skip_button = _secondary_button("تخطي الشراء", 58)
	skip_button.name = "SkipPurchaseButton"
	skip_button.pressed.connect(_on_skip_pressed)
	purchase_buttons.add_child(skip_button)
	box.add_child(purchase_buttons)
	card.add_child(box)
	return card

func _on_roll_pressed() -> void:
	if screen_name != "game" or animation_lock or cpu_running or not bool(game.state.get("active", false)):
		return
	var player_id := int(game.state.get("turn", -1))
	if not game.is_human_player(player_id) or int(game.state.get("pending_property", -1)) >= 0:
		return
	var player_name := str(game.state["players"][player_id]["name"])
	var before := int(game.state["players"][player_id]["position"])
	var result: Dictionary = game.roll(player_id, randi_range(1, 6))
	if not bool(result.get("ok", false)):
		_feedback(str(result.get("message", "تعذر تنفيذ الرمية.")), RED)
		return
	last_landed_player_id = player_id
	_save_game_state()
	dice_label.text = str(game.state["last_dice"])
	_feedback("%s رمى %d ويتحرك على اللوحة…" % [player_name, int(game.state["last_dice"])], GOLD)
	await _animate_path(player_id, result["path"], before)
	_feedback(_landing_summary(player_id, int(result["to"]), result.get("messages", [])), RED if bool(result.get("game_over", false)) else GOLD)
	_update_game_screen()
	await _maybe_run_cpu_turn()

func _landing_summary(player_id: int, tile_index: int, messages: Array) -> String:
	var player_name := str(game.state["players"][player_id]["name"])
	var tile: Dictionary = BankGameModel.BOARD[tile_index]
	var arrival := "%s وصل إلى %s — %s." % [player_name, str(tile["name"]), _tile_type_name(str(tile["type"]))]
	if messages.is_empty():
		return arrival
	return arrival + "\n" + _messages_to_text(messages)

func _tile_type_name(tile_type: String) -> String:
	match tile_type:
		"start": return "نقطة البداية"
		"country": return "دولة"
		"event": return "حدث عشوائي"
		"tax": return "ضريبة"
		"reward": return "مكافأة"
		"rest": return "راحة"
		_: return "مربع"

func _maybe_run_cpu_turn() -> void:
	if screen_name == "game" and bool(game.state.get("active", false)) and game.is_computer_player(int(game.state.get("turn", -1))) and int(game.state.get("pending_property", -1)) < 0:
		await _run_cpu_turn()

func _run_cpu_turn() -> void:
	if cpu_running or screen_name != "game" or not bool(game.state.get("active", false)):
		return
	var player_id := int(game.state.get("turn", -1))
	if not game.is_computer_player(player_id) or int(game.state.get("pending_property", -1)) >= 0:
		return
	cpu_running = true
	animation_lock = true
	_feedback("دور الكمبيوتر — يتخذ قراره تلقائيًا…", BLUE)
	_update_game_screen()
	await get_tree().create_timer(cpu_delay).timeout
	if screen_name != "game" or not bool(game.state.get("active", false)) or int(game.state.get("turn", -1)) != player_id:
		cpu_running = false
		animation_lock = false
		return
	var player_name := str(game.state["players"][player_id]["name"])
	var before := int(game.state["players"][player_id]["position"])
	var result: Dictionary = game.roll(player_id, randi_range(1, 6))
	if not bool(result.get("ok", false)):
		cpu_running = false
		animation_lock = false
		_feedback(str(result.get("message", "تعذر تنفيذ دور الكمبيوتر.")), RED)
		_update_game_screen()
		return
	last_landed_player_id = player_id
	_save_game_state()
	dice_label.text = str(game.state["last_dice"])
	_feedback("الكمبيوتر رمى %d وتحرك تلقائيًا…" % int(game.state["last_dice"]), BLUE)
	await _animate_path(player_id, result["path"], before)
	cpu_running = false
	_feedback(_landing_summary(player_id, int(result["to"]), result.get("messages", [])), GOLD if bool(game.state.get("active", false)) else RED)
	_update_game_screen()

func _animate_path(player_id: int, path: Array, starting_position: int) -> void:
	if player_id < 0 or player_id >= animated_positions.size():
		return
	animation_lock = true
	animated_positions[player_id] = starting_position
	_refresh_board()
	for step_position in path:
		if screen_name != "game":
			break
		animated_positions[player_id] = int(step_position)
		_refresh_board()
		await get_tree().create_timer(0.12).timeout
	animated_positions[player_id] = -1
	animation_lock = false
	_refresh_board()

func _on_buy_pressed() -> void:
	if screen_name != "game" or animation_lock or cpu_running:
		return
	var player_id := int(game.state["turn"])
	var tile_index := int(game.state["pending_property"])
	var result: Dictionary = game.buy_pending_property()
	if not bool(result.get("ok", false)):
		_feedback(str(result.get("message", "تعذر الشراء.")), RED)
		_update_game_screen()
		return
	_save_game_state()
	_feedback(_landing_summary(player_id, tile_index, []) + "\n" + str(result.get("message", "تم الشراء.")), GREEN)
	_update_game_screen()
	await _maybe_run_cpu_turn()

func _on_skip_pressed() -> void:
	if screen_name != "game" or animation_lock or cpu_running:
		return
	var player_id := int(game.state["turn"])
	var tile_index := int(game.state["pending_property"])
	var result: Dictionary = game.skip_pending_purchase()
	if bool(result.get("ok", false)):
		_save_game_state()
		_feedback(_landing_summary(player_id, tile_index, []) + "\n" + str(result.get("message", "تم تخطي الشراء.")), MUTED)
		_update_game_screen()
		await _maybe_run_cpu_turn()

func _update_location_card() -> void:
	if game.state.is_empty() or not is_instance_valid(property_text):
		return
	var players: Array = game.state["players"]
	var current_turn_id := clampi(int(game.state.get("turn", 0)), 0, players.size() - 1)
	var player_id := clampi(last_landed_player_id, 0, players.size() - 1)
	var player: Dictionary = players[player_id]
	var tile_index := int(player["position"])
	var tile: Dictionary = BankGameModel.BOARD[tile_index]
	var tile_type := str(tile["type"])
	var lines: Array[String] = []
	if player_id == current_turn_id:
		lines.append("موقع الدور الحالي — %s" % str(player["name"]))
	else:
		lines.append("آخر وصول — %s" % str(player["name"]))
		lines.append("الدور الحالي — %s" % str(players[current_turn_id]["name"]))
	lines.append("%s — %s" % [str(tile["name"]), _tile_type_name(tile_type)])
	if tile_type == "country":
		var owner := int(game.state["tile_owners"][tile_index])
		lines.append("السعر: %s  •  الإيجار: %s" % [_format_money(int(tile["price"])), _format_money(int(tile["rent"]))])
		if owner < 0:
			lines.append("الحالة: متاحة للشراء")
		else:
			lines.append("المالك الحالي: %s" % str(players[owner]["name"]))
			var owner_status := "مملوكة للاعب الواصل (%s)" % str(players[owner]["name"]) if owner == player_id else "مملوكة للاعب آخر (%s)" % str(players[owner]["name"])
			lines.append("الحالة: " + owner_status)
	else:
		match tile_type:
			"start": lines.append("الأثر: مكافأة 500 عند عبور البداية")
			"event": lines.append("الأثر: حدث مالي قد يمنحك ربحًا أو يفرض دفعًا")
			"tax": lines.append("الأثر: ضريبة 200")
			"reward": lines.append("الأثر: مكافأة 300")
			"rest": lines.append("الأثر: لا تغيير في الرصيد")
	var pending := int(game.state.get("pending_property", -1))
	if pending == tile_index and current_turn_id == player_id:
		var balance := int(player["balance"])
		lines.append("رصيد %s: %s" % [str(player["name"]), _format_money(balance)])
		if balance < int(tile["price"]):
			lines.append("الرصيد غير كافٍ للشراء؛ يمكنك تخطيه.")
	property_text.text = "\n".join(lines)
	purchase_buttons.visible = bool(game.state.get("active", false)) and pending >= 0
	buy_button.visible = purchase_buttons.visible
	skip_button.visible = purchase_buttons.visible
	if pending >= 0:
		var enough_cash := int(game.state["players"][current_turn_id]["balance"]) >= int(BankGameModel.BOARD[pending]["price"])
		buy_button.disabled = not enough_cash or animation_lock or cpu_running
		buy_button.text = "شراء الدولة" if enough_cash else "الرصيد لا يكفي"
		skip_button.disabled = animation_lock or cpu_running

func _update_game_screen() -> void:
	if screen_name != "game" or game.state.is_empty():
		return
	var players: Array = game.state["players"]
	var current_player := int(game.state.get("turn", 0))
	for player_id in range(players.size()):
		var player: Dictionary = players[player_id]
		var marker: String = str(PLAYER_SYMBOLS[player_id])
		var turn_suffix := " • الدور الآن" if bool(game.state["active"]) and player_id == current_player else ""
		if game.is_computer_player(player_id) and player_id == current_player and cpu_running:
			turn_suffix = " • يتحرك آليًا"
		stat_names[player_id].text = "%s  %s%s" % [marker, str(player["name"]), turn_suffix]
		stat_balances[player_id].text = "الرصيد: " + _format_money(int(player["balance"]))
		stat_ownerships[player_id].text = "الدول: %d" % game.count_owned_properties(player_id)
		var position := int(player["position"])
		stat_positions[player_id].text = "الموقع %02d — %s\nالدورات: %d" % [position, str(BankGameModel.BOARD[position]["name"]), int(player["completed_laps"])]
	if bool(game.state["active"]):
		var current_name := str(players[current_player]["name"])
		if game.is_computer_player(current_player):
			turn_label.text = "دور الكمبيوتر — يتحرك الآن" if cpu_running else "دور الكمبيوتر — سيبدأ تلقائيًا"
		elif int(game.state["pending_property"]) >= 0:
			turn_label.text = "دور %s — اختر قرار الدولة" % current_name
		else:
			turn_label.text = "دور %s — ارمِ النرد" % current_name
	else:
		turn_label.text = "انتهت المباراة"
	_update_location_card()
	var pending := int(game.state.get("pending_property", -1))
	roll_button.disabled = not bool(game.state["active"]) or not game.is_human_player(current_player) or pending >= 0 or animation_lock or cpu_running
	if is_instance_valid(center_dice):
		center_dice.text = "النرد\n%s" % ("—" if int(game.state["last_dice"]) == 0 else str(game.state["last_dice"]))
	if is_instance_valid(center_status):
		center_status.text = "اختبار\nبنك الحظ"
	if is_instance_valid(center_hint):
		center_hint.text = "الأصدقاء" if str(game.state.get("mode", MODE_COMPUTER)) == MODE_LOCAL else "ضد الكمبيوتر"
	if is_instance_valid(log_label):
		var history: Array = game.state.get("log", [])
		var begin := maxi(0, history.size() - 3)
		var recent: Array[String] = []
		for i in range(begin, history.size()):
			recent.append(str(history[i]))
		log_label.text = "سجل المباراة\n" + "\n".join(recent)
	if not bool(game.state["active"]):
		var winner := int(game.state["winner_id"])
		var result_lines: Array[String] = ["الفائز: %s" % str(players[winner]["name"])]
		for player_id in range(players.size()):
			result_lines.append("%s: %s" % [str(players[player_id]["name"]), _format_money(int(players[player_id]["balance"]))])
		result_text.text = "\n".join(result_lines)
	result_panel.visible = not bool(game.state["active"])
	_refresh_board()

func _refresh_board() -> void:
	if game.state.is_empty() or tile_widgets.is_empty():
		return
	var players: Array = game.state["players"]
	for tile_index in range(BankGameModel.TILE_COUNT):
		if tile_index >= tile_widgets.size() or tile_widgets[tile_index].is_empty():
			continue
		var widget: Dictionary = tile_widgets[tile_index]
		var tile: Dictionary = BankGameModel.BOARD[tile_index]
		var kind := str(tile["type"])
		var owner := int(game.state["tile_owners"][tile_index])
		var marker_ids: Array[int] = []
		for player_id in range(players.size()):
			if _display_position(player_id) == tile_index:
				marker_ids.append(player_id)
		var detail := ""
		var tile_color := TILE
		var border := Color("#465a65")
		if kind == "country":
			var country_index := 0
			for item in range(tile_index + 1):
				if str(BankGameModel.BOARD[item]["type"]) == "country":
					country_index += 1
			tile_color = COUNTRY_COLORS[(country_index - 1) % COUNTRY_COLORS.size()].darkened(0.60)
			if owner < 0:
				detail = "سعر %s\nإيجار %s" % [_format_money(int(tile["price"])), _format_money(int(tile["rent"]))]
			else:
				detail = "ملك %s\nإيجار %s" % [str(players[owner]["name"]), _format_money(int(tile["rent"]))]
				border = PLAYER_COLORS[owner]
		elif kind == "start":
			tile_color = Color("#5c4a26")
			detail = "عبور +500"
		elif kind == "event":
			tile_color = Color("#433558")
			detail = "ربح أو دفع"
		elif kind == "tax":
			tile_color = Color("#553634")
			detail = "ضريبة 200"
		elif kind == "reward":
			tile_color = Color("#315547")
			detail = "+300"
		else:
			tile_color = Color("#34404a")
			detail = "بلا تغيير"
		widget["label"].text = "%02d • %s\n%s" % [tile_index, str(tile["name"]), detail]
		var marker_row: HBoxContainer = widget["markers"]
		for old_marker in marker_row.get_children():
			marker_row.remove_child(old_marker)
			old_marker.free()
		for player_id in marker_ids:
			var marker_label := _label(PLAYER_SYMBOLS[player_id], 14, PLAYER_COLORS[player_id], HORIZONTAL_ALIGNMENT_CENTER)
			marker_label.custom_minimum_size.x = 20
			marker_label.tooltip_text = str(players[player_id]["name"])
			marker_row.add_child(marker_label)
		if not marker_ids.is_empty() and owner < 0:
			border = PLAYER_COLORS[marker_ids[0]]
		var style := StyleBoxFlat.new()
		style.bg_color = tile_color
		style.border_color = border
		style.set_border_width_all(1)
		if owner >= 0 or not marker_ids.is_empty():
			style.set_border_width_all(2)
		style.set_corner_radius_all(9)
		style.content_margin_left = 3
		style.content_margin_right = 3
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		widget["panel"].add_theme_stylebox_override("panel", style)

func _display_position(player_id: int) -> int:
	if player_id < 0 or player_id >= game.state.get("players", []).size():
		return -1
	if player_id < animated_positions.size() and int(animated_positions[player_id]) >= 0:
		return int(animated_positions[player_id])
	return int(game.state["players"][player_id]["position"])

func _messages_to_text(messages: Array) -> String:
	if messages.is_empty():
		return "اكتمل الدور."
	return "\n".join(messages)

func _feedback(text: String, color: Color) -> void:
	if is_instance_valid(feedback_label):
		feedback_label.text = text
		feedback_label.add_theme_color_override("font_color", color)

func _save_game_state() -> void:
	var result: Dictionary = game.save_to(SAVE_FILE)
	if not bool(result.get("ok", false)):
		_feedback(str(result.get("message", "تعذر حفظ المباراة.")), RED)
	else:
		resume_available = true

func _save_and_home() -> void:
	_save_game_state()
	_show_home()

func _format_money(amount: int) -> String:
	var digits := str(amount)
	var formatted := ""
	var group := 0
	for i in range(digits.length() - 1, -1, -1):
		formatted = digits.substr(i, 1) + formatted
		group += 1
		if group == 3 and i > 0:
			formatted = "," + formatted
			group = 0
	return formatted
