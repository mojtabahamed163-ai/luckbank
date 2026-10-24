extends Node

const Model = preload("res://scripts/game/bank_game.gd")
const TEST_SAVE := "user://luckbank-test-save.json"
const CORRUPT_SAVE := "user://luckbank-test-corrupt.json"
const LOCAL_SAVE := "user://luckbank-test-local-save.json"
const LEGACY_SAVE := "user://luckbank-test-legacy-save.json"

var total := 0
var passed := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_board_definition()
	_test_position_math()
	_test_lap_bonus_and_wrap()
	_test_no_lap_bonus_without_crossing()
	_test_single_purchase()
	_test_purchase_insufficient_funds()
	_test_already_owned_purchase_rejected()
	_test_rent_transfer()
	_test_rent_bankruptcy_no_negative_balance()
	_test_tax_reward_and_event()
	_test_cpu_turn_and_purchase()
	_test_local_players_and_turn_cycle()
	_test_local_player_purchase_and_rent()
	_test_local_owner_validation_and_winner()
	_test_overlapping_turn_rejected()
	_test_end_game_locks_actions()
	_test_save_restore()
	_test_local_save_restore()
	_test_legacy_save_migration()
	_test_corrupt_save_rejected()
	_test_offline_manifest()
	print("[luckbank-tests] %d/%d passed" % [passed, total])
	if not failures.is_empty():
		for failure in failures:
			push_error("[luckbank-tests] FAIL: " + failure)
		print("[luckbank-tests] FAIL: %d failures" % failures.size())
		get_tree().quit(1)
	else:
		print("[luckbank-tests] PASS: deterministic board-game checks")
		get_tree().quit(0)

func _check(condition: bool, label: String) -> void:
	total += 1
	if condition:
		passed += 1
	else:
		failures.append(label)

func _fresh() -> Model:
	var game = Model.new(24680)
	game.new_game("سارة")
	return game

func _test_board_definition() -> void:
	_check(Model.BOARD.size() == 12, "board has exactly 12 tiles")
	var counts := {"start": 0, "country": 0, "event": 0, "tax": 0, "reward": 0, "rest": 0}
	for i in range(Model.BOARD.size()):
		var tile: Dictionary = Model.BOARD[i]
		counts[tile["type"]] += 1
		_check(int(tile["id"]) == i, "stable tile id %d" % i)
	_check(counts["start"] == 1 and counts["country"] == 6 and counts["event"] == 2, "required tile counts")
	_check(counts["tax"] == 1 and counts["reward"] == 1 and counts["rest"] == 1, "special tile counts")
	var countries := [{"price": 1000, "rent": 100}, {"price": 1200, "rent": 120}, {"price": 1500, "rent": 150}, {"price": 1800, "rent": 180}, {"price": 2000, "rent": 200}, {"price": 2500, "rent": 250}]
	var actual: Array = []
	for tile: Dictionary in Model.BOARD:
		if tile["type"] == "country":
			actual.append({"price": tile["price"], "rent": tile["rent"]})
	_check(actual == countries, "country purchase/rent values")

func _test_position_math() -> void:
	var inside := Model.calculate_move(2, 3)
	_check(bool(inside["ok"]) and int(inside["position"]) == 5 and int(inside["crossings"]) == 0, "normal circular movement")
	var invalid := Model.calculate_move(-1, 2)
	_check(not bool(invalid["ok"]), "invalid board index is rejected")

func _test_lap_bonus_and_wrap() -> void:
	var movement := Model.calculate_move(10, 4)
	_check(int(movement["position"]) == 2 and int(movement["crossings"]) == 1, "10 + 4 wraps to tile 2 and crosses start")
	var game = _fresh()
	game.state["players"][0]["position"] = 10
	var result: Dictionary = game.roll(0, 4, 0)
	_check(bool(result["ok"]) and int(game.state["players"][0]["position"]) == 2, "actual move updates wrapped position")
	_check(int(game.state["players"][0]["balance"]) == 10700, "one lap bonus 500 plus event 200 applied once")
	_check(int(game.state["players"][0]["completed_laps"]) == 1, "one completed lap counted")
	_check(int(game.state["players"][0]["steps_moved"]) == 4, "actual steps persisted")
	var multiple := Model.calculate_move(10, 28)
	_check(int(multiple["position"]) == 2 and int(multiple["crossings"]) == 3, "multiple start crossings counted exactly")

func _test_no_lap_bonus_without_crossing() -> void:
	var game = _fresh()
	game.state["players"][0]["position"] = 1
	var result: Dictionary = game.roll(0, 1, 0)
	_check(bool(result["ok"]) and int(result["crossings"]) == 0, "no start crossing")
	_check(int(game.state["players"][0]["balance"]) == 10200, "no lap bonus when no crossing")
	_check(int(game.state["players"][0]["completed_laps"]) == 0, "no lap counter increment on ordinary move")

func _test_single_purchase() -> void:
	var game = _fresh()
	var landed: Dictionary = game.roll(0, 1)
	_check(int(landed["pending_purchase"]) == 1 and bool(game.state["busy"]), "human country landing pauses for decision")
	var purchase: Dictionary = game.buy_pending_property()
	_check(bool(purchase["ok"]), "purchase succeeds")
	_check(int(game.state["players"][0]["balance"]) == 9000 and int(game.state["tile_owners"][1]) == 0, "purchase debit and ownership commit together")
	_check(int(game.state["turn"]) == 1 and not bool(game.state["busy"]), "purchase completes human turn")
	var again: Dictionary = game.buy_pending_property()
	_check(not bool(again["ok"]) and int(game.state["players"][0]["balance"]) == 9000, "duplicate purchase cannot debit twice")

func _test_purchase_insufficient_funds() -> void:
	var game = _fresh()
	game.state["players"][0]["balance"] = 500
	game.roll(0, 1)
	var result: Dictionary = game.buy_pending_property()
	_check(not bool(result["ok"]), "insufficient balance blocks purchase")
	_check(int(game.state["players"][0]["balance"]) == 500 and int(game.state["tile_owners"][1]) == -1, "failed purchase changes neither cash nor owner")
	_check(bool(game.skip_pending_purchase()["ok"]), "player may skip after insufficient funds")

func _test_already_owned_purchase_rejected() -> void:
	var game = _fresh()
	game.state["tile_owners"][1] = 1
	game.state["pending_property"] = 1
	game.state["busy"] = true
	var result: Dictionary = game.buy_pending_property()
	_check(not bool(result["ok"]), "owned property cannot be bought again")
	_check(int(game.state["players"][0]["balance"]) == 10000 and int(game.state["tile_owners"][1]) == 1, "owned-property rejection is transactional")

func _test_rent_transfer() -> void:
	var game = _fresh()
	game.state["tile_owners"][1] = 1
	var result: Dictionary = game.roll(0, 1)
	_check(bool(result["ok"]), "rent landing resolved")
	_check(int(game.state["players"][0]["balance"]) == 9900, "visitor paid 100 rent")
	_check(int(game.state["players"][1]["balance"]) == 10100, "correct owner received 100 rent")

func _test_rent_bankruptcy_no_negative_balance() -> void:
	var game = _fresh()
	game.state["tile_owners"][1] = 1
	game.state["players"][0]["balance"] = 50
	game.roll(0, 1)
	_check(not bool(game.state["active"]) and int(game.state["winner_id"]) == 1, "unaffordable rent ends match for owner")
	_check(int(game.state["players"][0]["balance"]) == 50, "unpaid rent never creates negative balance")
	_check(not bool(game.buy_pending_property()["ok"]), "bankrupt match rejects purchases")

func _test_tax_reward_and_event() -> void:
	var tax = _fresh()
	tax.state["players"][0]["position"] = 4
	tax.roll(0, 1)
	_check(int(tax.state["players"][0]["balance"]) == 9800, "tax deducts 200")
	var reward = _fresh()
	reward.state["players"][0]["position"] = 6
	reward.roll(0, 1)
	_check(int(reward.state["players"][0]["balance"]) == 10300, "reward adds 300")
	var event = _fresh()
	event.state["players"][0]["position"] = 1
	event.roll(0, 1, 1)
	_check(int(event.state["players"][0]["balance"]) == 9850, "controlled event charges exactly 150")
	var event_gain = _fresh()
	event_gain.state["players"][0]["position"] = 1
	event_gain.roll(0, 1, 0)
	_check(int(event_gain.state["players"][0]["balance"]) == 10200, "event reward changes balance by 200")

func _test_cpu_turn_and_purchase() -> void:
	var game = _fresh()
	game.state["turn"] = 1
	var result: Dictionary = game.roll(1, 1)
	_check(bool(result["ok"]) and int(game.state["tile_owners"][1]) == 1, "computer buys an affordable country")
	_check(int(game.state["players"][1]["balance"]) == 9000 and int(game.state["turn"]) == 0, "computer turn updates funds and returns to human")
	var cautious = _fresh()
	cautious.state["turn"] = 1
	cautious.state["players"][1]["balance"] = 1500
	cautious.roll(1, 1)
	_check(int(cautious.state["tile_owners"][1]) == -1, "computer does not buy when reserve would fall below policy")

func _test_local_players_and_turn_cycle() -> void:
	var game = Model.new(111)
	game.new_game("تجاهل", Model.MODE_LOCAL, ["سارة", "مريم", "هند", "لينا"])
	_check(str(game.state["mode"]) == Model.MODE_LOCAL and game.state["players"].size() == 4, "local mode initializes four named human players")
	_check(not game.is_computer_player(1) and game.is_human_player(1), "friend two is human and never treated as computer")
	_check(int(game.state["players"][3]["balance"]) == Model.STARTING_CASH, "every local player starts with 10000")
	var cycle_ok := true
	for player_id in range(4):
		game.state["players"][player_id]["position"] = 10
		var result: Dictionary = game.roll(player_id, 1)
		if not bool(result.get("ok", false)) or int(game.state["turn"]) != (player_id + 1) % 4:
			cycle_ok = false
	_check(cycle_ok, "four human turns rotate in order without triggering a CPU turn")
	var three = Model.new(112)
	three.new_game("", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	_check(three.state["players"].size() == 3 and str(three.state["players"][0]["name"]) == "أ", "three-player setup retains entered names")
	var two = Model.new(113)
	two.new_game("", Model.MODE_LOCAL, ["أ", "ب"])
	_check(two.state["players"].size() == 2 and two.is_human_player(0) and two.is_human_player(1), "two-player friend match contains two humans and no computer")

func _test_local_player_purchase_and_rent() -> void:
	var game = Model.new(221)
	game.new_game("أ", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	game.state["players"][0]["position"] = 10
	game.roll(0, 1)
	_check(int(game.state["turn"]) == 1, "second friend receives next turn")
	var offer: Dictionary = game.roll(1, 1)
	_check(int(offer["pending_purchase"]) == 1, "second human receives a real country purchase prompt")
	var bought: Dictionary = game.buy_pending_property()
	_check(bool(bought["ok"]) and int(game.state["tile_owners"][1]) == 1, "second friend can buy the country in their own name")
	_check(int(game.state["players"][1]["balance"]) == 9000 and int(game.state["turn"]) == 2, "second friend pays once and turn proceeds to third")
	var rent = Model.new(222)
	rent.new_game("أ", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	rent.state["tile_owners"][1] = 2
	rent.roll(0, 1)
	_check(int(rent.state["players"][0]["balance"]) == 9900 and int(rent.state["players"][2]["balance"]) == 10100, "local rent transfers once to the correct third-player owner")

func _test_local_owner_validation_and_winner() -> void:
	var game = Model.new(331)
	game.new_game("أ", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	game.state["tile_owners"][1] = 2
	_check(Model.validate_state(game.state), "third-player ownership is valid in three-player local mode")
	var bad_owner: Dictionary = game.state.duplicate(true)
	bad_owner["tile_owners"][1] = 3
	_check(not Model.validate_state(bad_owner), "owner index beyond local player count is rejected")
	var bankrupt = Model.new(332)
	bankrupt.new_game("أ", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	bankrupt.state["players"][0]["position"] = 4
	bankrupt.state["players"][0]["balance"] = 0
	bankrupt.roll(0, 1)
	_check(not bool(bankrupt.state["active"]) and int(bankrupt.state["winner_id"]) == 1, "bankruptcy ends three-player match and selects the richest opponent deterministically")

func _test_overlapping_turn_rejected() -> void:
	var game = _fresh()
	game.roll(0, 1)
	var second: Dictionary = game.roll(0, 2)
	_check(not bool(second["ok"]), "second human action is blocked while purchase choice is pending")
	game.skip_pending_purchase()
	var wrong_player: Dictionary = game.roll(0, 2)
	_check(not bool(wrong_player["ok"]), "human cannot roll during computer turn")
	var invalid_die: Dictionary = game.roll(1, 7)
	_check(not bool(invalid_die["ok"]), "die outside one through six is rejected")

func _test_end_game_locks_actions() -> void:
	var game = _fresh()
	game.state["players"][0]["position"] = 4
	game.state["players"][0]["balance"] = 0
	game.roll(0, 1)
	_check(not bool(game.state["active"]) and int(game.state["winner_id"]) == 1, "unable to pay tax declares bankruptcy")
	var after: Dictionary = game.roll(1, 1)
	_check(not bool(after["ok"]), "no roll is allowed after match end")
	_check(int(game.state["players"][0]["balance"]) == 0, "final balance does not go negative")

func _test_save_restore() -> void:
	var game = _fresh()
	game.state["tile_owners"][1] = 0
	game.state["players"][0]["balance"] = 8765
	game.state["players"][0]["position"] = 4
	var saved: Dictionary = game.save_to(TEST_SAVE)
	var restored = Model.new()
	var loaded: Dictionary = restored.load_from(TEST_SAVE)
	_check(bool(saved["ok"]) and bool(loaded["ok"]), "valid match saves and reloads")
	if bool(loaded.get("ok", false)):
		_check(int(restored.state["players"][0]["balance"]) == 8765 and int(restored.state["players"][0]["position"]) == 4, "saved balances and locations restored")
		_check(int(restored.state["tile_owners"][1]) == 0, "property owner restored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

func _test_local_save_restore() -> void:
	var game = Model.new(441)
	game.new_game("أ", Model.MODE_LOCAL, ["أ", "ب", "ج"])
	game.state["players"][2]["position"] = 4
	game.state["players"][2]["balance"] = 7654
	game.state["tile_owners"][1] = 2
	game.state["turn"] = 2
	var saved: Dictionary = game.save_to(LOCAL_SAVE)
	var restored = Model.new()
	var loaded: Dictionary = restored.load_from(LOCAL_SAVE)
	_check(bool(saved.get("ok", false)) and bool(loaded.get("ok", false)), "three-player local match saves and reloads")
	if bool(loaded.get("ok", false)):
		_check(str(restored.state["mode"]) == Model.MODE_LOCAL and restored.state["players"].size() == 3, "local mode and player count survive restore")
		_check(int(restored.state["turn"]) == 2 and str(restored.state["players"][2]["name"]) == "ج", "active third player survives restore")
		_check(int(restored.state["tile_owners"][1]) == 2 and int(restored.state["players"][2]["balance"]) == 7654, "third-player property and funds survive restore")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LOCAL_SAVE))

func _test_legacy_save_migration() -> void:
	var game = _fresh()
	var old_state: Dictionary = game.state.duplicate(true)
	old_state.erase("mode")
	for player in old_state["players"]:
		player.erase("controller")
	var file := FileAccess.open(LEGACY_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "state": old_state}))
	file.close()
	var restored = Model.new()
	var loaded: Dictionary = restored.load_from(LEGACY_SAVE)
	_check(bool(loaded.get("ok", false)) and bool(loaded.get("migrated", false)), "version-one computer save migrates safely")
	if bool(loaded.get("ok", false)):
		_check(str(restored.state["mode"]) == Model.MODE_COMPUTER and restored.is_human_player(0) and restored.is_computer_player(1), "legacy players receive the correct controllers")
		var saved: Dictionary = restored.save_to(LEGACY_SAVE)
		var migrated_file := FileAccess.open(LEGACY_SAVE, FileAccess.READ)
		var parser := JSON.new()
		parser.parse(migrated_file.get_as_text())
		migrated_file.close()
		_check(bool(saved.get("ok", false)) and int(parser.data.get("version", -1)) == Model.SAVE_VERSION, "resaving migrated match writes the current save format")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE))

func _test_corrupt_save_rejected() -> void:
	var file := FileAccess.open(CORRUPT_SAVE, FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	var game = Model.new()
	var result: Dictionary = game.load_from(CORRUPT_SAVE)
	_check(not bool(result["ok"]) and bool(result.get("corrupt", false)), "corrupt JSON handled without crash")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CORRUPT_SAVE))
	var invalid = _fresh()
	var bad_state: Dictionary = invalid.state.duplicate(true)
	bad_state["tile_owners"] = [9]
	_check(not Model.validate_state(bad_state), "invalid save structure rejected")

func _test_offline_manifest() -> void:
	var file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	var manifest := file.get_as_text()
	file.close()
	_check(manifest.contains("permissions/internet=false"), "Android export explicitly disables Internet permission")
	var source := FileAccess.open("res://scripts/game/bank_game.gd", FileAccess.READ)
	var logic := source.get_as_text()
	source.close()
	_check(not logic.contains("HTTPRequest") and not logic.contains("WebSocket") and not logic.contains("https://"), "game rules have no network dependency")
