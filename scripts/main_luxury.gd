extends "res://scripts/main.gd"

const NAVY := Color("#09283b")
const NAVY_DEEP := Color("#061d2c")
const PAPER := Color("#f4eedb")
const PAPER_EDGE := Color("#d7c28f")
const TEXT_DARK := Color("#263640")
const BLUE_CARD := Color("#14537a")
const RED_CARD := Color("#a83f43")
const GREEN_CARD := Color("#147351")
const GOLD_CARD := Color("#9a7025")
const PLAYER_COLORS_LUXURY := [Color("#348dd0"), Color("#cf4d52"), Color("#28a26c"), Color("#d3a13b")]

var luxury_overlay: Control
var luxury_board: Control


func _show_game() -> void:
	super._show_game()
	if screen_name != "game":
		return
	await get_tree().process_frame
	_apply_luxury_skin()


func _apply_luxury_skin() -> void:
	if not is_instance_valid(board_surface) or not is_instance_valid(center_panel):
		return
	var backdrop := get_child(0) as ColorRect
	if backdrop != null:
		backdrop.color = NAVY
	board_surface.offset_left = 22
	board_surface.offset_top = 22
	board_surface.offset_right = -22
	board_surface.offset_bottom = -22
	var center_style := StyleBoxFlat.new()
	center_style.bg_color = PAPER
	center_style.border_color = PAPER_EDGE
	center_style.set_border_width_all(2)
	center_style.set_corner_radius_all(24)
	center_style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	center_style.shadow_size = 18
	center_style.shadow_offset = Vector2(0, 8)
	center_panel.add_theme_stylebox_override("panel", center_style)
	if not board_surface.resized.is_connected(_layout_luxury_board):
		board_surface.resized.connect(_layout_luxury_board)
	_layout_luxury_board()
	_style_luxury_tiles()
	_create_luxury_overlay()


func _layout_luxury_board() -> void:
	if not is_instance_valid(board_surface) or not is_instance_valid(center_panel):
		return
	var board_size := board_surface.size
	if board_size.x < 160.0 or board_size.y < 160.0:
		return
	var cell := minf((board_size.x - 8.0) / 13.0, (board_size.y - 8.0) / 9.0)
	var origin := Vector2((board_size.x - cell * 13.0) * 0.5, (board_size.y - cell * 9.0) * 0.5)
	center_panel.position = origin + Vector2(cell, cell)
	center_panel.size = Vector2(cell * 11.0, cell * 7.0)
	var tile_buttons: Array = get("tile_buttons")
	var tile_labels: Array = get("tile_labels")
	var tile_ids: Array = get("tile_id_labels")
	var tile_values: Array = get("tile_value_labels")
	var tile_art: Array = get("tile_corner_art")
	for tile_index in range(mini(tile_buttons.size(), BankGameModel.TILE_COUNT)):
		var coord := _luxury_ring_coordinate(tile_index)
		var rect := Rect2(origin + Vector2(coord) * cell, Vector2(cell, cell))
		var tile_button := tile_buttons[tile_index] as Button
		tile_button.position = rect.position
		tile_button.size = rect.size
		var side_tile := coord.x == 0 or coord.x == 12
		(tile_ids[tile_index] as Label).add_theme_font_size_override("font_size", 10 if side_tile else 11)
		(tile_labels[tile_index] as Label).add_theme_font_size_override("font_size", 12)
		(tile_values[tile_index] as Label).add_theme_font_size_override("font_size", 10)
		(tile_art[tile_index] as Control).custom_minimum_size.y = 24 if not side_tile else 0


func _luxury_ring_coordinate(tile_index: int) -> Vector2i:
	if tile_index <= 8:
		return Vector2i(0, 8 - tile_index)
	if tile_index <= 20:
		return Vector2i(tile_index - 8, 0)
	if tile_index <= 28:
		return Vector2i(12, tile_index - 20)
	return Vector2i(40 - tile_index, 8)


func _style_luxury_tiles() -> void:
	var tile_buttons: Array = get("tile_buttons")
	var tile_labels: Array = get("tile_labels")
	var tile_ids: Array = get("tile_id_labels")
	var tile_values: Array = get("tile_value_labels")
	for tile_index in range(mini(tile_buttons.size(), BankGameModel.TILE_COUNT)):
		var tile: Dictionary = BankGameModel.BOARD[tile_index]
		var tile_type := str(tile.get("type", ""))
		var color := Color("#205c80")
		if tile_type == "country":
			color = [Color("#237e59"), Color("#1f618c"), Color("#3e4f91"), Color("#a15b32"), Color("#9b3d43"), Color("#2d7566")][int(tile.get("group", 0)) % 6]
		elif tile_type == "start":
			color = Color("#217c4e")
		elif tile_type == "tax":
			color = Color("#8c3b3f")
		elif tile_type == "event":
			color = Color("#47558e")
		elif tile_type == "market":
			color = Color("#216e63")
		elif tile_type == "jail":
			color = Color("#80553a")
		var button := tile_buttons[tile_index] as Button
		var normal := _tile_style(color, Color("#d4b85d"))
		var hover := _tile_style(color.lightened(0.12), Color("#fff1a8"))
		var pressed := _tile_style(color.darkened(0.12), Color("#fff1a8"))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		(button as Control).tooltip_text = str((button as Control).tooltip_text)
		(tile_ids[tile_index] as Label).add_theme_color_override("font_color", Color("#fff8de"))
		(tile_labels[tile_index] as Label).add_theme_color_override("font_color", Color.WHITE)
		(tile_values[tile_index] as Label).add_theme_color_override("font_color", Color("#ffe294"))


func _tile_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


func _create_luxury_overlay() -> void:
	if is_instance_valid(luxury_overlay):
		luxury_overlay.queue_free()
	luxury_overlay = LuxuryOverlay.new()
	luxury_overlay.host = self
	luxury_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	luxury_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	luxury_overlay.z_index = 8
	add_child(luxury_overlay)
	luxury_overlay.queue_redraw()


class LuxuryOverlay extends Control:
	var host: Control
	const PANEL := Color("#f4eedb")
	const NAVY := Color("#09283b")
	const TEXT := Color("#263640")
	const GOLD := Color("#e6ba59")
	const COLORS := [Color("#348dd0"), Color("#cf4d52"), Color("#28a26c"), Color("#d3a13b")]
	const CARD_COLORS := [Color("#14537a"), Color("#a83f43"), Color("#147351"), Color("#9a7025")]

	func _draw() -> void:
		if host == null or not is_instance_valid(host.get("center_panel")):
			return
		var board: Control = host.get("board_surface")
		var center: Control = host.get("center_panel")
		var center_rect := Rect2(board.position + center.position, center.size)
		_draw_map(center_rect)
		_draw_player_cards(center_rect)
		_draw_logo(center_rect)
		_draw_bottom_bar(center_rect)

	func _draw_map(rect: Rect2) -> void:
		var tint := Color("#7caab1")
		var alpha := 0.13
		var p1 := PackedVector2Array([rect.position + Vector2(rect.size.x * 0.10, rect.size.y * 0.39), rect.position + Vector2(rect.size.x * 0.23, rect.size.y * 0.24), rect.position + Vector2(rect.size.x * 0.36, rect.size.y * 0.30), rect.position + Vector2(rect.size.x * 0.31, rect.size.y * 0.48), rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.57)])
		var p2 := PackedVector2Array([rect.position + Vector2(rect.size.x * 0.42, rect.size.y * 0.22), rect.position + Vector2(rect.size.x * 0.65, rect.size.y * 0.18), rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.31), rect.position + Vector2(rect.size.x * 0.69, rect.size.y * 0.46), rect.position + Vector2(rect.size.x * 0.51, rect.size.y * 0.42)])
		var p3 := PackedVector2Array([rect.position + Vector2(rect.size.x * 0.55, rect.size.y * 0.57), rect.position + Vector2(rect.size.x * 0.74, rect.size.y * 0.51), rect.position + Vector2(rect.size.x * 0.86, rect.size.y * 0.68), rect.position + Vector2(rect.size.x * 0.71, rect.size.y * 0.81), rect.position + Vector2(rect.size.x * 0.57, rect.size.y * 0.73)])
		draw_colored_polygon(p1, Color(tint, alpha))
		draw_colored_polygon(p2, Color(tint, alpha))
		draw_colored_polygon(p3, Color(tint, alpha))

	func _draw_player_cards(rect: Rect2) -> void:
		var game_state: Dictionary = host.get("game").state
		var players: Array = game_state.get("players", [])
		var gap := 8.0
		var card_width := (rect.size.x - 24.0 - gap * 3.0) / 4.0
		var top := rect.position + Vector2(12.0, 14.0)
		for index in range(4):
			var card_rect := Rect2(top + Vector2((card_width + gap) * index, 0), Vector2(card_width, 94.0))
			var card := StyleBoxFlat.new()
			card.bg_color = Color(CARD_COLORS[index], 0.97)
			card.border_color = Color(COLORS[index], 0.95)
			card.set_border_width_all(2)
			card.set_corner_radius_all(16)
			card.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
			card.shadow_size = 8
			card.shadow_offset = Vector2(0, 4)
			draw_style_box(card, card_rect)
			draw_circle(card_rect.position + Vector2(card_rect.size.x - 28.0, 30.0), 18.0, COLORS[index])
			draw_circle(card_rect.position + Vector2(card_rect.size.x - 28.0, 25.0), 6.0, Color.WHITE)
			draw_arc(card_rect.position + Vector2(card_rect.size.x - 28.0, 40.0), 10.0, PI, TAU, 18, Color.WHITE, 4.0, true)
			var name := "اللاعب %d" % (index + 1)
			if index < players.size():
				name = str(players[index].get("name", name))
			var font: Font = host.get("ui_font")
			if font != null:
				draw_string(font, card_rect.position + Vector2(12.0, 30.0), name, HORIZONTAL_ALIGNMENT_RIGHT, card_rect.size.x - 52.0, 17, Color.WHITE)
				draw_string(font, card_rect.position + Vector2(12.0, 58.0), "الدورة %d/%d" % [int(game_state.get("round_number", 1)), int(game_state.get("round_limit", 16))], HORIZONTAL_ALIGNMENT_RIGHT, card_rect.size.x - 52.0, 11, Color(1, 1, 1, 0.75))
				draw_string(font, card_rect.position + Vector2(12.0, 78.0), "الرصيد: %s" % host.call("_money", int(players[index].get("balance", 0))) if index < players.size() else "جاهز", HORIZONTAL_ALIGNMENT_RIGHT, card_rect.size.x - 52.0, 11, Color("#ffe9a8"))

	func _draw_logo(rect: Rect2) -> void:
		var font: Font = host.get("ui_font")
		if font == null:
			return
		var center := rect.get_center() + Vector2(0, 72)
		draw_circle(center, 52.0, Color("#1c6d86", 0.16))
		draw_arc(center, 56.0, 0.0, TAU, 48, Color("#caa34f", 0.45), 2.0, true)
		draw_string(font, center + Vector2(-150, 12), "بنك الحظ", HORIZONTAL_ALIGNMENT_CENTER, 300, 36, Color("#bd862d"))
		draw_string(font, center + Vector2(-150, 39), "LUCK BANK", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, Color("#6f7d78"))

	func _draw_bottom_bar(rect: Rect2) -> void:
		var bar_rect := Rect2(rect.position + Vector2(16.0, rect.size.y - 70.0), Vector2(rect.size.x - 32.0, 52.0))
		var bar := StyleBoxFlat.new()
		bar.bg_color = Color(NAVY, 0.97)
		bar.border_color = Color("#4a91ba")
		bar.set_border_width_all(1)
		bar.set_corner_radius_all(20)
		bar.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
		bar.shadow_size = 8
		draw_style_box(bar, bar_rect)
		var font: Font = host.get("ui_font")
		if font == null:
			return
		var labels := ["اللاعبون", "المحادثة", "القائمة", "الإعدادات"]
		for index in range(labels.size()):
			var x := bar_rect.position.x + bar_rect.size.x * (float(index) + 0.5) / labels.size()
			draw_circle(Vector2(x, bar_rect.position.y + 17.0), 8.0, Color("#74bce2"))
			draw_string(font, Vector2(x - 55, bar_rect.position.y + 42.0), labels[index], HORIZONTAL_ALIGNMENT_CENTER, 110, 12, Color.WHITE)
