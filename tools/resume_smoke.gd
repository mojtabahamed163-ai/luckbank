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
		push_error("[luckbank-resume] FAIL: " + label)

func _run() -> void:
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	get_root().add_child(app)
	await process_frame
	await process_frame
	_check(app.screen_name == "home", "fresh app process opens on the home screen")
	var resume := app.find_child("ContinueMatchButton", true, false) as Button
	_check(resume != null and not resume.disabled, "saved active match enables Continue after process restart")
	if resume != null and not resume.disabled:
		resume.pressed.emit()
		await process_frame
		await process_frame
		var players: Array = app.game.state.get("players", [])
		_check(app.screen_name == "game" and players.size() == 2, "Continue reopens the saved game scene")
		if players.size() == 2:
			_check(str(app.game.state["mode"]) == "computer" and str(players[0]["name"]) == "ليلى" and app.game.is_computer_player(1), "saved mode, human name, and computer role survive process restart")
			_check(int(players[1]["steps_moved"]) > 0, "computer position and completed movement survive process restart")
			_check(int(app.game.state["turn"]) == 0 and bool(app.game.state["active"]), "match turn and active status survive process restart")
			_check(app.stat_names.size() == 2 and app.stat_balances.size() == 2 and app.stat_ownerships.size() == 2, "resumed HUD is rebuilt from saved data")
	if failures.is_empty():
		print("[luckbank-resume] PASS: %d/%d checks" % [passed, total])
		quit(0)
	else:
		print("[luckbank-resume] FAIL: %d/%d; %d failures" % [passed, total, failures.size()])
		quit(1)
