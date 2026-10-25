extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var app: Variant = packed.instantiate()
	root.add_child(app)
	await process_frame
	app._show_setup()
	app.mode_option.select(1)
	app.player_count_option.select(2)
	app.duration_option.select(0)
	app._on_setup_changed(2)
	app._start_match()
	await process_frame
	assert(app.game.state["players"].size() == 4)
	assert(app.game.state["players"][0]["controller"] == "human")
	app.game.state["tile_owners"][1] = 0
	app.game.state["tile_owners"][2] = 0
	app.game.state["investments"].append({"type": "agriculture", "tile": 1, "owner": 0, "cost": 700, "income": 70, "level": 0})
	app.game.state["phase"] = "actions"
	app.game.state["can_market"] = true
	app._show_game()
	await process_frame
	await process_frame
	app._on_tile_selected(2)
	await process_frame
	assert(app.screen_name == "tile_information")
	app._show_game()
	await process_frame
	await process_frame
	assert(app.tile_buttons.size() == 40)
	assert(app.player_tokens.size() == 4)
	assert(not app.player_tokens[0].is_computer and not app.player_tokens[1].is_computer)
	assert(app.roll_button.text.is_empty() and app.dice_face != null)
	assert(app.roll_button.visible and app.find_child("BottomNavigation", true, false).visible)
	assert(app.board_surface.size.x > app.board_surface.size.y)
	assert(app.board_surface.get_child_count() == 41)
	assert(app.center_panel.size.x > app.center_panel.size.y)
	var start_rect: Rect2 = app.tile_buttons[0].get_rect()
	assert(start_rect.position.x > 0.0 and start_rect.position.y > app.board_surface.size.y * 0.5)
	app.game.state["pending_property"] = 1
	app.game.state["phase"] = "pending_purchase"
	app._update_game_view()
	assert(app.purchase_panel.visible)
	assert(not app.portfolio_button.get_parent().visible)
	assert(not app.tile_info_button.get_parent().visible)
	app.game.state["pending_property"] = -1
	app.game.state["phase"] = "actions"
	app._update_game_view()
	var seen: Dictionary = {}
	for tile_index in range(40):
		var coordinate: Vector2i = app._ring_coordinate(tile_index)
		assert(coordinate.x >= 0 and coordinate.x <= 10 and coordinate.y >= 0 and coordinate.y <= 10)
		assert(coordinate.x == 0 or coordinate.x == 10 or coordinate.y == 0 or coordinate.y == 10)
		assert(not seen.has(coordinate))
		seen[coordinate] = true
		var tile_rect: Rect2 = app.tile_buttons[tile_index].get_rect()
		assert(tile_rect.position.x >= -0.5 and tile_rect.position.y >= -0.5)
		assert(tile_rect.end.x <= app.board_surface.size.x + 0.5 and tile_rect.end.y <= app.board_surface.size.y + 0.5)
		var center_rect: Rect2 = app.center_panel.get_rect()
		var overlap_width := minf(tile_rect.end.x, center_rect.end.x) - maxf(tile_rect.position.x, center_rect.position.x)
		var overlap_height := minf(tile_rect.end.y, center_rect.end.y) - maxf(tile_rect.position.y, center_rect.position.y)
		assert(overlap_width <= 0.5 or overlap_height <= 0.5)
	assert(app._ring_coordinate(0) == Vector2i(0, 10))
	assert(app._ring_coordinate(10) == Vector2i(0, 0))
	assert(app._ring_coordinate(11) == Vector2i(1, 0))
	assert(app._ring_coordinate(20) == Vector2i(10, 0))
	assert(app._ring_coordinate(21) == Vector2i(10, 1))
	assert(app._ring_coordinate(30) == Vector2i(10, 10))
	assert(app._ring_coordinate(31) == Vector2i(9, 10))
	assert(app._ring_coordinate(39) == Vector2i(1, 10))
	assert(app.tile_labels[10].text == app._tile_name(10) and app.tile_labels[20].text == app._tile_name(20))
	assert(app.tile_id_labels[1].text.begins_with("1 ") and not app.tile_id_labels[1].text.begins_with("01"))
	assert(app.tile_value_labels[31].text.contains("1,800") or app.tile_value_labels[31].text.contains("1800"))
	var side_tile_height: float = app.tile_buttons[31].size.y
	assert(side_tile_height > 0.0 and app.board_surface.size.y > 0.0)
	assert(app.tile_value_labels[31].get_theme_font_size("font_size") >= 11)
	assert(app.tile_labels[38].text == app._tile_name(38))
	await app._animate_dice_roll(4)
	assert(app.dice_face.face_value == 4)
	app.game.state["phase"] = "await_roll"
	app._update_game_view()
	await process_frame
	assert(app.roll_button.visible and app.roll_button.size.x <= 90.0)
	assert(app.dice_face.size.x >= 48.0 and app.dice_face.size.y >= 48.0)
	app.game.state["phase"] = "actions"
	app._update_game_view()
	assert(seen.size() == 40)
	for language in ["ar", "en", "es", "fr"]:
		app.locale = language
		app.locale_data = app.catalogs[language]
		app._show_game()
		await process_frame
		assert(app.tile_buttons.size() == 40)
		app._show_market()
		await process_frame
		assert(app.screen_name == "market")
		assert(_contains_text(app.main_column, app._trf("investment_expansion", {"level": "1"})))
		app._show_development()
		await process_frame
		assert(app.screen_name == "development")
		app._show_portfolio()
		await process_frame
		assert(app.screen_name == "portfolio")
		assert(_contains_text(app.main_column, app._tile_name(1)))
		assert(_contains_text(app.main_column, app._tile_name(2)))
		assert(not _contains_text(app.main_column, app._tile_name(8)))
		app._show_more_actions()
		await process_frame
		assert(app.screen_name == "more")
		assert(_contains_text(app.main_column, app._tr("market")))
		assert(_contains_text(app.main_column, app._tr("rules")))
		app.selected_tile = 2
		app._show_tile_information()
		await process_frame
		assert(app.screen_name == "tile_information")
		assert(_contains_text(app.main_column, app._tile_name(2)))
		app._show_trade()
		await process_frame
		assert(app.screen_name == "trade")
		app._show_ledger()
		await process_frame
		assert(app.screen_name == "ledger")
		app._show_rules()
		await process_frame
		assert(app.screen_name == "rules")
		app._show_settings()
		await process_frame
		assert(app.screen_name == "settings")
	print("[luckbank-ui-smoke] PASS setup, 40-tile board, portfolio, more menu, tile details and core pages in ar/en/es/fr")
	app.queue_free()
	quit()

func _contains_text(node: Node, needle: String) -> bool:
	if node is Button and needle in (node as Button).text:
		return true
	if node is Label and needle in (node as Label).text:
		return true
	for child in node.get_children():
		if _contains_text(child, needle):
			return true
	return false
