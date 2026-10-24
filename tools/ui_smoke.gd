extends SceneTree

var app: Control
var total := 0
var passed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	total += 1
	if condition:
		passed += 1
	else:
		failures.append(label)
		push_error("[luckbank-ui] FAIL: " + label)

func _button(name: String) -> Button:
	var node := app.find_child(name, true, false)
	if node is Button:
		return node as Button
	return null

func _press(name: String) -> void:
	var button := _button(name)
	if button == null:
		_check(false, "button exists: " + name)
		return
	button.pressed.emit()
	await process_frame
	await process_frame

func _wait_until_idle(max_frames: int = 1200) -> void:
	for _frame in range(max_frames):
		if app.screen_name != "game":
			return
		if not app.animation_lock and not app.cpu_running:
			return
		await create_timer(0.01).timeout
	_check(not app.animation_lock and not app.cpu_running, "game animation and computer turn finish")

func _resolve_pending_by_skip() -> void:
	if int(app.game.state.get("pending_property", -1)) >= 0:
		await _press("SkipPurchaseButton")
		await _wait_until_idle()

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	app = scene.instantiate() as Control
	get_root().add_child(app)
	await process_frame
	await process_frame
	_check(app.screen_name == "home", "home menu starts")
	_check(_button("NewGameButton") != null and _button("SettingsButton") != null, "main menu keeps working actions")
	var initial_fast := bool(app.settings["fast_cpu"])
	await _press("SettingsButton")
	_check(app.screen_name == "settings" and app.settings_value_label.text == ("سريع" if initial_fast else "عادي"), "settings screen displays the saved speed")
	await _press("FastCpuToggleButton")
	_check(bool(app.settings["fast_cpu"]) != initial_fast and is_equal_approx(app.cpu_delay, 0.28 if not initial_fast else 0.75), "speed setting changes the actual computer delay")
	await _press("FastCpuToggleButton")
	_check(bool(app.settings["fast_cpu"]) == initial_fast, "speed setting can be restored")
	await _press("SettingsBackButton")
	_check(app.screen_name == "home", "settings return button restores the home menu")

	await _press("NewGameButton")
	_check(app.screen_name == "mode_selection", "new match opens explicit mode choice")
	_check(_button("PlayVsComputerButton") != null and _button("PlayWithFriendButton") != null, "both requested play modes are visible")
	await _press("PlayWithFriendButton")
	_check(app.screen_name == "player_setup" and app.selected_mode == "local", "friend option opens local-player setup")
	var count_option := app.find_child("FriendPlayerCount", true, false) as OptionButton
	_check(count_option != null, "friend mode exposes player-count selector")
	if count_option != null:
		count_option.select(2)
		count_option.item_selected.emit(2)
		_check(app.friend_player_count == 4 and app.name_input_rows[3].visible, "four-player option reveals a fourth name field")
		count_option.select(0)
		count_option.item_selected.emit(0)
		_check(app.friend_player_count == 2 and app.name_input_rows[1].visible and not app.name_input_rows[2].visible, "two-player option hides unused name fields")
		count_option.select(1)
		count_option.item_selected.emit(1)
		_check(app.friend_player_count == 3 and app.name_input_rows[2].visible and not app.name_input_rows[3].visible, "three-player option restores exactly three name fields")
	if app.player_name_inputs.size() >= 3:
		app.player_name_inputs[0].text = "سارة"
		app.player_name_inputs[1].text = "مريم"
		app.player_name_inputs[2].text = "هند"
	else:
		_check(false, "three editable player-name fields exist")
	await _press("StartMatchButton")
	_check(app.screen_name == "game" and str(app.game.state.get("mode", "")) == "local", "friend choice launches local gameplay")
	_check(app.game.state["players"].size() == 3 and app.game.is_human_player(2), "three named human players are initialized")
	_check(str(app.game.state["players"][1]["name"]) == "مريم" and int(app.game.state["players"][2]["balance"]) == 10000, "names and starting balances are displayed in the model")
	_check(app.find_child("PlayerCard2", true, false) != null, "HUD shows every local player")
	_check(app.find_child("CurrentLocationCard", true, false) != null and app.property_text.text.contains("البداية"), "permanent location card identifies the current station")

	var first_button := _button("RollButton")
	var dice_one_seed := 0
	for candidate in range(1000):
		seed(candidate)
		if randi_range(1, 6) == 1:
			dice_one_seed = candidate
			break
	seed(dice_one_seed)
	if first_button != null:
		first_button.pressed.emit()
	await _wait_until_idle()
	_check(int(app.game.state.get("pending_property", -1)) == 1, "controlled die lands directly on Egypt before any purchase")
	_check(app.property_text.text.contains("مصر") and app.property_text.text.contains("1,000") and app.property_text.text.contains("100") and app.property_text.text.contains("متاحة للشراء"), "unowned-country card shows country, price, rent, and availability before buying")
	_check(app.buy_button.visible and app.skip_button.visible, "purchase and skip actions appear for an available country")
	await _press("BuyPropertyButton")
	_check(int(app.game.state["tile_owners"][1]) == 0 and int(app.game.state["players"][0]["balance"]) == 9000, "actual UI purchase registers ownership and deducts once")
	_check(app.property_text.text.contains("مصر") and app.property_text.text.contains("سارة") and app.property_text.text.contains("مملوكة"), "location card keeps the purchased country and its owner visible after turn handoff")
	_check(app.stat_ownerships[0].text.contains("1"), "player property count updates immediately after purchase")
	_check(int(app.game.state["turn"]) == 1, "first friend yields control to the second friend")
	_check(app.feedback_label.text.contains("سارة") and app.feedback_label.text.contains("وصل إلى"), "arrival feedback names the moving player and destination")
	await create_timer(0.16).timeout
	_check(int(app.game.state["turn"]) == 1 and int(app.game.state["players"][1]["steps_moved"]) == 0, "hotseat mode never launches a computer turn")
	var second_button := _button("RollButton")
	if second_button != null:
		second_button.pressed.emit()
	await _wait_until_idle()
	await _resolve_pending_by_skip()
	_check(int(app.game.state["turn"]) == 2, "second friend gets an independent manual turn")
	_check(app.feedback_label.text.contains("مريم") and app.feedback_label.text.contains("وصل إلى"), "second friend receives named destination feedback")
	_check(app.stat_names.size() == 3 and app.stat_ownerships.size() == 3 and app.stat_positions.size() == 3, "HUD has name, owned-country count, and location for each friend")
	var shot := get_root().get_texture().get_image()
	shot.save_png("/tmp/luckbank-three-player-ui.png")

	await _press("ReturnHomeButton")
	await _press("NewGameButton")
	await _press("PlayVsComputerButton")
	if not app.player_name_inputs.is_empty():
		app.player_name_inputs[0].text = "ليلى"
	app.cpu_delay = 0.03
	await _press("StartMatchButton")
	_check(str(app.game.state["mode"]) == "computer" and app.game.is_computer_player(1), "computer option launches an actual computer-controlled opponent")
	var human_roll := _button("RollButton")
	if human_roll != null:
		human_roll.pressed.emit()
	await _wait_until_idle()
	await _resolve_pending_by_skip()
	await _wait_until_idle()
	_check(int(app.game.state["turn"]) == 0 and int(app.game.state["players"][1]["steps_moved"]) > 0, "computer automatically rolls and completes its turn")
	_check(app.feedback_label.text.contains("الكمبيوتر وصل إلى"), "computer landing also names the destination")

	if failures.is_empty():
		print("[luckbank-ui] PASS: %d/%d checks" % [passed, total])
		quit(0)
	else:
		print("[luckbank-ui] FAIL: %d/%d; %d failures" % [passed, total, failures.size()])
		quit(1)
