extends Node

const Model = preload("res://scripts/game/bank_game.gd")
const TEST_SAVE := "user://luckbank-test-save.json"
const CORRUPT_SAVE := "user://luckbank-test-corrupt.json"
const LEGACY_SAVE := "user://luckbank-test-legacy.json"

var total := 0
var passed := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_board_definition()
	_test_localization()
	_test_move_math_and_start_crossing()
	_test_purchase_and_skip()
	_test_rent_and_self_ownership()
	_test_taxes_and_rest()
	_test_stage_one_messages_and_jail_cycle()
	_test_groups_and_upgrades()
	_test_investment_economy_and_sudan()
	_test_event_deck_and_food_condition()
	_test_phase_two_market_trade_goals()
	_test_shortage_liquidation_and_bankruptcy()
	_test_trade_rules()
	_test_trade_moves_investment_bundle()
	_test_computer_decisions()
	_test_match_end_and_net_worth()
	_test_full_local_match_simulation()
	_test_save_restore_and_corruption()
	_test_legacy_migration()
	print("[luckbank-tests] %d/%d passed" % [passed, total])
	if not failures.is_empty():
		for failure in failures:
			push_error("[luckbank-tests] FAIL: " + failure)
		print("[luckbank-tests] FAIL: %d failures" % failures.size())
		get_tree().quit(1)
	else:
		print("[luckbank-tests] PASS: 40-tile economic board checks")
		get_tree().quit(0)

func _check(condition: bool, label: String) -> void:
	total += 1
	if condition:
		passed += 1
	else:
		failures.append(label)

func _test_localization() -> void:
	var file := FileAccess.open("res://localization/luckbank.json", FileAccess.READ)
	_check(file != null, "localization catalog is present in exported resources")
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_check(typeof(data) == TYPE_DICTIONARY, "localization catalog is valid JSON")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var base: Dictionary = data.get("ar", {}).get("ui", {})
	var expected_special_tiles: Dictionary = {
		"ar": ["السوق العالمي", "الراحة الاقتصادية"],
		"en": ["World market", "Economic rest"],
		"es": ["Mercado mundial", "Descanso económico"],
		"fr": ["Marché mondial", "Repos économique"]
	}
	for language in ["ar", "en", "es", "fr"]:
		var locale: Dictionary = data.get(language, {})
		var ui: Dictionary = locale.get("ui", {})
		_check(ui.size() == base.size(), "%s has the complete UI key set" % language)
		for key in base.keys():
			_check(ui.has(key) and typeof(ui.get(key, null)) == TYPE_STRING, "%s translates UI key %s" % [language, key])
		_check(locale.get("tiles", []).size() == Model.TILE_COUNT, "%s has names for all board tiles" % language)
		var localized_tiles: Array = locale.get("tiles", [])
		_check(localized_tiles[Model.GLOBAL_MARKET_TILE] == expected_special_tiles[language][0] and localized_tiles[20] == expected_special_tiles[language][1], "%s places global market on 10 and rest on 20" % language)
		_check(locale.get("events", []).size() == Model.EVENTS.size(), "%s has names for every event card" % language)
		_check(locale.get("flags", []).size() == Model.TILE_COUNT, "%s has a marker for every tile" % language)

func _fresh(mode: String = Model.MODE_COMPUTER, names: Array = [], difficulty: String = "medium", duration: String = "normal") -> Model:
	var game = Model.new(24680)
	game.new_game("سارة", mode, names, difficulty, duration)
	return game

func _test_board_definition() -> void:
	_check(Model.BOARD.size() == 40 and Model.TILE_COUNT == 40, "exactly 40 board spaces")
	var expected_names := ["البداية", "السودان", "مصر", "المغرب", "جنوب أفريقيا", "ضريبة الخدمات العامة", "نيجيريا", "كينيا", "السعودية", "الإمارات", "السوق العالمي", "تركيا", "الهند", "السوق والاستثمار", "الصين", "حدث اقتصادي", "اليابان", "كوريا الجنوبية", "إندونيسيا", "سنغافورة", "الراحة الاقتصادية", "أستراليا", "نيوزيلندا", "حدث اقتصادي", "فرنسا", "حدث اقتصادي", "ألمانيا", "إيطاليا", "إسبانيا", "المملكة المتحدة", "السجن", "النرويج", "روسيا", "البرازيل", "الأرجنتين", "حدث اقتصادي", "المكسيك", "كندا", "الولايات المتحدة الأمريكية", "تشيلي"]
	var actual_names: Array[String] = []
	var counts := {"start": 0, "country": 0, "tax": 0, "event": 0, "rest": 0, "jail": 0, "market": 0}
	for i in range(Model.BOARD.size()):
		var tile: Dictionary = Model.BOARD[i]
		actual_names.append(str(tile["name"]))
		counts[str(tile["type"])] += 1
		_check(int(tile["id"]) == i, "stable id %d" % i)
	_check(actual_names == expected_names, "all names and tile order match the requested 40-square route")
	_check(counts["country"] == 30 and counts["start"] == 1 and counts["tax"] == 1 and counts["event"] == 4 and counts["rest"] == 1 and counts["jail"] == 1 and counts["market"] == 2, "required board types include rest and jail")
	_check(str(Model.BOARD[Model.GLOBAL_MARKET_TILE]["type"]) == "market" and str(Model.BOARD[Model.GLOBAL_MARKET_TILE]["market"]) == "global", "space 10 is the global market")
	_check(str(Model.BOARD[Model.JAIL_TILE]["type"]) == "jail" and int(Model.BOARD[Model.JAIL_TILE]["bail"]) == 500, "space 30 is jail with 500 bail")
	_check(str(Model.BOARD[20]["type"]) == "rest", "space 20 is the neutral economic rest space")
	_check(Model.country_tiles().size() == 30, "exactly 30 purchasable countries")
	for group_id in range(6):
		var game = _fresh()
		_check(game.group_tiles(group_id).size() == 5, "group %d contains five countries" % group_id)
	var expected_economy := [[1, 1600, 160, 80], [2, 800, 80, 40], [3, 850, 85, 40], [4, 1100, 110, 55], [6, 1000, 100, 50], [7, 750, 75, 35], [8, 1500, 150, 75], [9, 1700, 170, 85], [11, 1200, 120, 60], [12, 1300, 130, 65], [14, 2200, 220, 110], [16, 2100, 210, 105], [17, 1800, 180, 90], [18, 1000, 100, 50], [19, 1900, 190, 95], [21, 1800, 180, 90], [22, 1200, 120, 60], [24, 2000, 200, 100], [26, 2300, 230, 115], [27, 1700, 170, 85], [28, 1600, 160, 80], [29, 2400, 240, 120], [31, 1800, 180, 90], [32, 1900, 190, 95], [33, 1400, 140, 70], [34, 1000, 100, 50], [36, 1300, 130, 65], [37, 2200, 220, 110], [38, 2800, 280, 140], [39, 1100, 110, 55]]
	for row in expected_economy:
		var tile: Dictionary = Model.BOARD[int(row[0])]
		_check(int(tile["price"]) == int(row[1]) and int(tile["rent"]) == int(row[2]) and int(tile["income"]) == int(row[3]), "%s buy/rent/income exactly match the requested economy" % str(tile["name"]))

func _test_move_math_and_start_crossing() -> void:
	var normal := Model.calculate_move(2, 3)
	_check(bool(normal["ok"]) and int(normal["position"]) == 5 and int(normal["crossings"]) == 0, "regular movement")
	var wrap := Model.calculate_move(39, 1)
	_check(int(wrap["position"]) == 0 and int(wrap["crossings"]) == 1, "last-to-first wrap crosses start")
	var bad := Model.calculate_move(40, 2)
	_check(not bool(bad["ok"]), "invalid position rejected")
	var game = _fresh()
	game.state["tile_owners"][Model.SUDAN_TILE] = 0
	game.state["players"][0]["position"] = 39
	var roll: Dictionary = game.roll(0, 1)
	_check(bool(roll["ok"]) and int(roll["to"]) == 0, "actual wrapped move arrives at start")
	_check(int(game.state["players"][0]["balance"]) == 10580, "one start bonus and one Sudan periodic income paid once")
	_check(int(game.state["players"][0]["completed_laps"]) == 1, "lap count increases once")
	var start_entries := 0
	for entry in game.state["ledger"]:
		if str(entry.get("category", "")) == "start":
			start_entries += 1
	_check(start_entries == 1, "no duplicate start bonus in one move")
	_check(int(game.state["players"][0]["balance"]) >= 0, "no negative balance from start movement")

func _test_purchase_and_skip() -> void:
	var game = _fresh()
	var landing: Dictionary = game.roll(0, 1)
	_check(int(landing["pending_purchase"]) == Model.SUDAN_TILE and str(game.state["phase"]) == "pending_purchase", "free Egypt awaits a real purchase decision")
	var purchase: Dictionary = game.buy_pending_property()
	_check(bool(purchase["ok"]) and int(game.state["tile_owners"][Model.SUDAN_TILE]) == 0, "purchase transfers ownership")
	_check(int(game.get_balance(0)) == 8400 and str(game.state["phase"]) == "actions", "purchase deducts exactly 1600 once")
	var duplicate: Dictionary = game.buy_pending_property()
	_check(not bool(duplicate["ok"]) and int(game.get_balance(0)) == 8400, "duplicate purchase rejected without another debit")
	var poor = _fresh()
	poor.state["players"][0]["balance"] = 500
	poor.roll(0, 1)
	var failed: Dictionary = poor.buy_pending_property()
	_check(not bool(failed["ok"]) and int(poor.get_balance(0)) == 500 and int(poor.state["tile_owners"][Model.SUDAN_TILE]) == -1, "insufficient purchase changes neither cash nor ownership")
	_check(bool(poor.skip_pending_purchase()["ok"]), "player may skip a free-property offer")

func _test_rent_and_self_ownership() -> void:
	var game = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	game.state["tile_owners"][Model.SUDAN_TILE] = 1
	var landing: Dictionary = game.roll(0, 1)
	_check(bool(landing["ok"]), "rent landing resolves")
	_check(int(game.get_balance(0)) == 9840 and int(game.get_balance(1)) == 10160, "Sudan rent transfers 160 from visitor to owner")
	var own = _fresh()
	own.state["tile_owners"][Model.SUDAN_TILE] = 0
	var before := own.get_balance(0)
	own.roll(0, 1)
	_check(own.get_balance(0) == before and str(own.state["phase"]) == "actions", "owner pays no rent to self")
	var ledger_owner := 0
	for entry in game.state["ledger"]:
		if str(entry.get("category", "")) == "transfer_in":
			ledger_owner = int(entry.get("player", -1))
	_check(ledger_owner == 1, "rent ledger records the beneficiary")

func _test_taxes_and_rest() -> void:
	var service = _fresh()
	service.state["players"][0]["position"] = 4
	service.roll(0, 1)
	_check(int(service.get_balance(0)) == 9700, "public-services tax is exactly 300")
	var rest = _fresh()
	rest.state["players"][0]["position"] = 19
	var rest_before := rest.get_balance(0)
	var rest_result: Dictionary = rest.roll(0, 1)
	_check(int(rest.get_balance(0)) == rest_before and str(rest.state["phase"]) == "actions", "space 20 rest has no automatic charge or reward")
	_check(str(rest_result["messages"][0]).contains("راحة اقتصادية"), "space 20 describes free rest")
	var jail = _fresh()
	jail.state["players"][0]["position"] = 29
	var jail_result: Dictionary = jail.roll(0, 1)
	_check(int(jail.get_balance(0)) == 10000 and str(jail.state["phase"]) == "jail" and int(jail.state["players"][0]["jail_turns_remaining"]) == 3, "space 30 enters jail for three turns without an automatic debit")
	_check(str(jail_result["messages"][0]).contains("دخل"), "jail landing describes bail")
	var bail_entries := 0
	for entry in jail.state["ledger"]:
		if str(entry.get("category", "")) == "jail_bail" and int(entry.get("amount", 0)) == -500:
			bail_entries += 1
	_check(bail_entries == 0, "jail entry does not charge bail before the player chooses")
	var bail_payment: Dictionary = jail.pay_jail_bail(0)
	_check(bool(bail_payment.get("ok", false)) and int(jail.get_balance(0)) == 9500 and str(jail.state["phase"]) == "actions", "paying bail releases the player exactly once")
	bail_entries = 0
	for entry in jail.state["ledger"]:
		if str(entry.get("category", "")) == "jail_bail" and int(entry.get("amount", 0)) == -500:
			bail_entries += 1
	_check(bail_entries == 1, "jail bail is recorded exactly once in the ledger")
	var poor = _fresh()
	poor.state["players"][0]["position"] = 29
	poor.state["players"][0]["balance"] = 100
	poor.roll(0, 1)
	_check(str(poor.state["phase"]) == "jail" and int(poor.get_balance(0)) == 100, "unaffordable bail creates an obligation without negative balance")

func _test_stage_one_messages_and_jail_cycle() -> void:
	var reward = _fresh()
	reward.state["players"][0]["position"] = 14
	var reward_result: Dictionary = reward.roll(0, 1, 0)
	_check(bool(reward_result.get("ok", false)) and int(reward.get_balance(0)) == 10080 and str(reward_result["messages"][0]).contains("الأثر المالي الفعلي: +80"), "event reward message matches the actual credit")
	var negative = _fresh()
	negative.state["players"][0]["position"] = 14
	var negative_result: Dictionary = negative.roll(0, 1, 1)
	_check(bool(negative_result.get("ok", false)) and int(negative.get_balance(0)) == 9880 and str(negative_result["messages"][0]).contains("الأثر المالي الفعلي: -120"), "event loss message matches the actual debit")
	var balance_before_summary := reward.get_balance(0)
	var event_transactions := 0
	for entry in reward.state["ledger"]:
		if str(entry.get("category", "")) == "event":
			event_transactions += 1
	_check(reward.get_balance(0) == balance_before_summary and event_transactions == 1, "an event is recorded once and cannot repeat its transaction")
	var jailed = _fresh(Model.MODE_LOCAL, ["سجين", "مراقب"])
	jailed.state["tile_owners"][Model.SUDAN_TILE] = 0
	jailed.state["players"][0]["position"] = 29
	jailed.roll(0, 1)
	var initial_balance := jailed.get_balance(0)
	for jail_round in range(3):
		var jail_end: Dictionary = jailed.end_turn(0)
		_check(bool(jail_end.get("ok", false)), "jailed player completes one real turn")
		if jail_round < 2:
			jailed.state["phase"] = "actions"
			jailed.end_turn(1)
	_check(int(jailed.state["players"][0]["jail_turns_remaining"]) == 0 and str(jailed.state["phase"]) == "await_roll", "jail releases automatically after three turns")
	_check(int(jailed.state["players"][0]["position"]) == Model.JAIL_TILE and int(jailed.get_balance(0)) == initial_balance + 240, "jail preserves position and pays periodic income without a start bonus")
	var start_entries := 0
	for entry in jailed.state["ledger"]:
		if str(entry.get("category", "")) == "start":
			start_entries += 1
	_check(start_entries == 0, "jail turns never create a false start crossing")

func _test_groups_and_upgrades() -> void:
	var game = _fresh()
	for tile in game.group_tiles(0):
		game.state["tile_owners"][tile] = 0
	_check(game.owns_complete_group(0, 0), "complete ownership bonus activates")
	_check(game.rent_for_tile(Model.SUDAN_TILE) == 200, "full group gives exactly 25 percent rent bonus on Sudan")
	game.state["phase"] = "actions"
	var first: Dictionary = game.upgrade_property(0, 1)
	_check(bool(first["ok"]) and int(first["cost"]) == 450, "completed group reduces first development cost by 10 percent")
	_check(game.rent_for_tile(Model.SUDAN_TILE) == 250, "level 1 rent rise is applied on top of group benefit")
	_check(game.income_for_tile(Model.SUDAN_TILE) == 88, "level 1 increases periodic income by 10 percent")
	game.state["tile_owners"][6] = -1
	_check(not game.owns_complete_group(0, 0) and game.rent_for_tile(Model.SUDAN_TILE) == 200, "group bonus is removed immediately when one state is lost")
	var dev = _fresh()
	dev.state["tile_owners"][Model.SUDAN_TILE] = 0
	dev.state["phase"] = "actions"
	var costs := [500, 800, 1200]
	var rents := [200, 240, 280]
	var incomes := [88, 96, 104]
	for level in range(3):
		var outcome: Dictionary = dev.upgrade_property(0, 1)
		_check(bool(outcome.get("ok", false)) and int(outcome.get("cost", -1)) == costs[level], "development %d price" % (level + 1))
		_check(dev.rent_for_tile(Model.SUDAN_TILE) == rents[level] and dev.income_for_tile(Model.SUDAN_TILE) == incomes[level], "development %d affects rent and income" % (level + 1))
	var fourth: Dictionary = dev.upgrade_property(0, 1)
	_check(not bool(fourth["ok"]) and int(dev.state["development"][1]) == 3, "cannot exceed level 3")
	_check(int(dev.get_balance(0)) == 7500, "all three base upgrade costs deducted exactly")
	var germany = _fresh()
	germany.state["tile_owners"][26] = 0
	_check(germany.development_cost(0, 26) == 450, "Germany has a real 10 percent development discount")
	for tile in germany.group_tiles(3):
		germany.state["tile_owners"][tile] = 0
	_check(germany.development_cost(0, 26) == 400, "Germany trait stacks with the completed-group development discount")
	germany.state["can_market"] = true
	var germany_options: Array[Dictionary] = germany.investment_options(0, 26)
	var germany_industry_yield := 0
	for option in germany_options:
		if str(option["type"]) == "industry":
			germany_industry_yield = int(option["income"])
	_check(germany_industry_yield == 132, "Germany's 10 percent industry yield bonus is priced into investment offers")

func _test_investment_economy_and_sudan() -> void:
	var game = _fresh()
	game.state["tile_owners"][Model.SUDAN_TILE] = 0
	game.state["phase"] = "actions"
	_check(game.income_for_tile(Model.SUDAN_TILE) == 80, "Sudan has no unpurchased project yield")
	_check(not bool(game.buy_investment(0, "agriculture", Model.SUDAN_TILE)["ok"]), "investment cannot be bought away from a market square")
	game.state["can_market"] = true
	var agriculture: Dictionary = game.buy_investment(0, "agriculture", Model.SUDAN_TILE)
	_check(bool(agriculture["ok"]) and int(agriculture["cost"]) == 700 and int(agriculture["income"]) == 90, "Sudan agriculture costs 700 and yields 70 plus its explicit 25 percent soil bonus")
	_check(game.income_for_tile(Model.SUDAN_TILE) == 170, "Sudan agricultural periodic income is actually applied")
	var livestock: Dictionary = game.buy_investment(0, "livestock", Model.SUDAN_TILE)
	_check(bool(livestock["ok"]) and int(livestock["income"]) == 90 and game.income_for_tile(Model.SUDAN_TILE) == 260, "Sudan livestock is separate, purchasable, and adds 90 income")
	var livestock_stage: Dictionary = game.buy_investment(0, "livestock", Model.SUDAN_TILE)
	_check(bool(livestock_stage.get("ok", false)) and int(livestock_stage.get("cost", 0)) == 600 and int(livestock_stage.get("income", 0)) == 60 and game.income_for_tile(Model.SUDAN_TILE) == 320, "Sudan livestock has a paid first expansion stage")
	var stage_one_available := false
	for option in game.investment_options(0, Model.SUDAN_TILE):
		if str(option.get("type", "")) == "agriculture" and bool(option.get("expansion", false)) and int(option.get("expansion_level", 0)) == 1 and int(option.get("cost", 0)) == 500 and int(option.get("income", 0)) == 55:
			stage_one_available = true
	var stage_one: Dictionary = game.buy_investment(0, "agriculture", Model.SUDAN_TILE)
	_check(stage_one_available and bool(stage_one.get("ok", false)) and game.income_for_tile(Model.SUDAN_TILE) == 375, "Sudan agriculture stage 1 shows 500 cost, +55 yield, and updates periodic income")
	var stage_two_available := false
	for option in game.investment_options(0, Model.SUDAN_TILE):
		if str(option.get("type", "")) == "agriculture" and bool(option.get("expansion", false)) and int(option.get("expansion_level", 0)) == 2 and int(option.get("cost", 0)) == 700 and int(option.get("income", 0)) == 70:
			stage_two_available = true
	var stage_two: Dictionary = game.buy_investment(0, "agriculture", Model.SUDAN_TILE)
	_check(stage_two_available and bool(stage_two.get("ok", false)) and game.income_for_tile(Model.SUDAN_TILE) == 445, "Sudan agriculture stage 2 increases yield and cost in defined steps")
	_check(not bool(game.buy_investment(0, "agriculture", Model.SUDAN_TILE).get("ok", false)), "Sudan project cannot be expanded beyond its two offered stages")
	var no_sudan = _fresh()
	no_sudan.state["tile_owners"][Model.SUDAN_TILE] = 0
	no_sudan.state["phase"] = "actions"
	no_sudan.state["can_market"] = true
	no_sudan.state["players"][0]["balance"] = 600
	_check(not bool(no_sudan.buy_investment(0, "agriculture", Model.SUDAN_TILE)["ok"]) and no_sudan.income_for_tile(Model.SUDAN_TILE) == 80, "investment cannot grant benefit without enough cash")
	var types := [{"kind": "energy", "tile": 8, "cost": 1000}, {"kind": "trade", "tile": 9, "cost": 900}, {"kind": "industry", "tile": 14, "cost": 1200}, {"kind": "technology", "tile": 16, "cost": 1300}, {"kind": "logistics", "tile": 2, "cost": 850}]
	for row in types:
		var item := _fresh()
		item.state["tile_owners"][int(row["tile"])] = 0
		item.state["phase"] = "actions"
		item.state["can_market"] = true
		var bought: Dictionary = item.buy_investment(0, str(row["kind"]), int(row["tile"]))
		_check(bool(bought.get("ok", false)) and int(bought.get("cost", -1)) == int(row["cost"]) and int(bought.get("income", 0)) > 0, "investment type %s has a real cost and yield" % str(row["kind"]))
	var traits := [{"tile": 2, "kind": "agriculture", "income": 80}, {"tile": 2, "kind": "trade", "income": 103}, {"tile": 8, "kind": "energy", "income": 125}, {"tile": 9, "kind": "trade", "income": 108}, {"tile": 14, "kind": "industry", "income": 150}, {"tile": 16, "kind": "technology", "income": 156}, {"tile": 26, "kind": "industry", "income": 132}, {"tile": 38, "kind": "technology", "income": 143}]
	for feature_row in traits:
		var country_game = _fresh()
		var trait_tile := int(feature_row["tile"])
		var trait_kind := str(feature_row["kind"])
		country_game.state["tile_owners"][trait_tile] = 0
		country_game.state["phase"] = "actions"
		country_game.state["can_market"] = true
		var offer: Array[Dictionary] = country_game.investment_options(0, trait_tile)
		var offered_income := -1
		for option in offer:
			if str(option["type"]) == trait_kind:
				offered_income = int(option["income"])
		var trait_purchase: Dictionary = country_game.buy_investment(0, trait_kind, trait_tile)
		_check(offered_income == int(feature_row["income"]) and int(trait_purchase.get("income", -1)) == int(feature_row["income"]), "%s %s bonus is visible and applied in exact costed yield" % [str(Model.BOARD[trait_tile]["name"]), trait_kind])
	var usa = _fresh()
	usa.state["tile_owners"][38] = 0
	var usa_options: Array[Dictionary] = usa.investment_options(0, 38)
	var livestock_in_us := false
	for option in usa_options:
		if str(option["type"]) == "livestock":
			livestock_in_us = true
	_check(not livestock_in_us, "United States yield bonus does not bypass Sudan-only livestock restriction")
	var sold = game.sell_investment(0, 0)
	_check(bool(sold["ok"]) and int(sold["refund"]) == 950 and game.income_for_tile(Model.SUDAN_TILE) == 230, "expanded investment sale refunds 50 percent of all stages and removes only its yield")

func _test_event_deck_and_food_condition() -> void:
	var deck_game = _fresh()
	_check(Model.EVENTS.size() >= 40 and deck_game.state["event_deck"].size() == 40, "at least 40 economic event cards are loaded into a local deck")
	var seen := {}
	for card_id in range(Model.EVENTS.size()):
		var game = _fresh()
		game.state["players"][0]["position"] = 14
		var result: Dictionary = game.roll(0, 1, card_id)
		var card: Dictionary = game.state["last_event"]
		seen[int(card["id"])] = true
		_check(bool(result["ok"]) and int(card["id"]) == card_id, "event %d is applied and reported" % card_id)
	_check(seen.size() >= 40, "40 different card identities are available")
	var without_farm = _fresh()
	without_farm.state["players"][0]["position"] = 14
	without_farm.roll(0, 1, 0)
	_check(int(without_farm.get_balance(0)) == 10080, "food demand event has only its base effect without Sudan farm")
	var with_farm = _fresh()
	with_farm.state["tile_owners"][Model.SUDAN_TILE] = 0
	with_farm.state["investments"].append({"type": "agriculture", "tile": Model.SUDAN_TILE, "owner": 0, "cost": 700, "income": 70, "purchased_turn": 0})
	with_farm.state["players"][0]["position"] = 14
	with_farm.roll(0, 1, 0)
	_check(int(with_farm.get_balance(0)) == 10140, "food event pays its 80 base plus 60 only with Sudan agriculture")

func _test_phase_two_market_trade_goals() -> void:
	var market = _fresh(Model.MODE_LOCAL, ["مريم"])
	market.state["phase"] = "actions"
	market.state["can_market"] = true
	var profile: Dictionary = market.country_profile(Model.SUDAN_TILE)
	_check("agriculture" in profile["sectors"] and "food" in profile["resources"], "Sudan exposes real strategic food and livestock sectors")
	var quote_before: Dictionary = market.market_quote("food")
	var bought: Dictionary = market.buy_market_product(0, "food", 2)
	_check(bool(bought.get("ok", false)) and int(market.state["market_inventory"][0].get("food", 0)) == 2 and int(market.get_balance(0)) < 10000, "market purchase updates inventory and cash once")
	var sold: Dictionary = market.sell_market_product(0, "food", 1)
	_check(bool(sold.get("ok", false)) and int(market.state["market_inventory"][0].get("food", 0)) == 1, "market sale updates inventory and credits the player")
	var global_event: Dictionary = market.trigger_global_event(0)
	var quote_after: Dictionary = market.market_quote("food")
	_check(str(global_event["product"]) == "food" and int(quote_after["price"]) != int(quote_before["price"]), "global event changes a related product price for a limited period")
	market._advance_global_events()
	_check(market.state["active_global_events"].size() == 1 and int(market.state["active_global_events"][0]["duration"]) == 2, "global event duration counts down without changing country definitions")
	var trade = _fresh(Model.MODE_LOCAL, ["مريم"])
	trade.state["phase"] = "actions"
	trade.state["tile_owners"][Model.SUDAN_TILE] = 0
	trade.state["tile_owners"][6] = 1
	var offer: Dictionary = trade.propose_trade(0, 1, Model.SUDAN_TILE, 6, 0, 0)
	var counter: Dictionary = trade.counter_offer(1, 6, Model.SUDAN_TILE, 0, 0)
	var counter_result: Dictionary = trade.respond_to_trade(0, true) if bool(counter.get("ok", false)) else {}
	_check(bool(offer.get("pending", false)) and bool(counter.get("counter", false)) and bool(counter_result.get("ok", false)) and int(trade.state["tile_owners"][Model.SUDAN_TILE]) == 1, "counter-offer validates ownership and completes safely")
	_check(bool(trade.state["achievements"][0]["trade_success"]) and bool(trade.state["achievements"][1]["trade_success"]), "successful trade records a real achievement")

func _test_shortage_liquidation_and_bankruptcy() -> void:
	var liquidate = _fresh()
	liquidate.state["tile_owners"][Model.SUDAN_TILE] = 0
	liquidate.state["players"][0]["balance"] = 0
	liquidate.state["players"][0]["position"] = 4
	liquidate.roll(0, 1)
	_check(str(liquidate.state["phase"]) == "obligation" and int(liquidate.get_balance(0)) == 0, "tax shortfall pauses for liquidation without negative cash")
	var sale: Dictionary = liquidate.sell_property(0, 1)
	_check(bool(sale["ok"]) and int(sale["refund"]) == 800, "property liquidation returns 50 percent of original price")
	_check(str(liquidate.state["phase"]) == "actions" and int(liquidate.get_balance(0)) == 500 and int(liquidate.state["tile_owners"][Model.SUDAN_TILE]) == -1, "sale proceeds settle tax and release property")
	var bankrupt = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	bankrupt.state["players"][0]["balance"] = 0
	bankrupt.state["players"][0]["position"] = 4
	bankrupt.roll(0, 1)
	var result: Dictionary = bankrupt.declare_bankruptcy(0)
	_check(bool(result["ok"]) and not bool(bankrupt.state["players"][0]["alive"]), "player with no liquidatable assets can declare bankruptcy")
	_check(not bool(bankrupt.state["active"]) and int(bankrupt.state["winner_id"]) == 1, "last survivor wins after bankruptcy")
	var three_player = _fresh(Model.MODE_LOCAL, ["أ", "ب", "ج"])
	three_player.state["players"][0]["balance"] = 100
	three_player.state["players"][0]["position"] = 4
	three_player.roll(0, 1)
	var partial_result: Dictionary = three_player.declare_bankruptcy(0)
	_check(bool(partial_result["ok"]) and int(three_player.state["players"][0]["debt"]) == 200, "bankruptcy records only the unpaid remainder of the obligation")
	_check(int(three_player.get_balance(0)) == 0 and int(three_player.state["turn"]) == 1 and str(three_player.state["phase"]) == "await_roll", "local bankruptcy pays available cash and passes play to the next surviving player")
	_check(not bool(three_player.state["active"]) or int(three_player.state["turn"]) != 0, "eliminated local player cannot deadlock the match")

func _test_trade_rules() -> void:
	var game = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	game.state["tile_owners"][Model.SUDAN_TILE] = 0
	game.state["tile_owners"][6] = 1
	game.state["phase"] = "actions"
	var proposal: Dictionary = game.propose_trade(0, 1, Model.SUDAN_TILE, 6, 50, 25)
	_check(bool(proposal.get("pending", false)) and str(game.state["phase"]) == "trade", "local trade pauses for the other human's response")
	var accepted: Dictionary = game.respond_to_trade(1, true)
	_check(bool(accepted.get("ok", false)) and int(game.state["tile_owners"][1]) == 1 and int(game.state["tile_owners"][6]) == 0, "accepted trade transfers both legal properties")
	_check(int(game.get_balance(0)) == 9975 and int(game.get_balance(1)) == 10025, "trade cash is transferred exactly once")
	var illegal: Dictionary = game.propose_trade(0, 1, 1, -1, 0, 0)
	_check(not bool(illegal["ok"]), "trade cannot offer property not owned by proposer")
	var reject_game = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	reject_game.state["tile_owners"][Model.SUDAN_TILE] = 0
	reject_game.state["tile_owners"][6] = 1
	reject_game.state["phase"] = "actions"
	reject_game.propose_trade(0, 1, Model.SUDAN_TILE, 6)
	var rejected: Dictionary = reject_game.respond_to_trade(1, false)
	_check(bool(rejected["ok"]) and int(reject_game.state["tile_owners"][1]) == 0, "rejected trade changes no ownership")

func _test_trade_moves_investment_bundle() -> void:
	var game = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	game.state["tile_owners"][Model.SUDAN_TILE] = 0
	game.state["tile_owners"][6] = 1
	game.state["investments"].append({"type": "agriculture", "tile": Model.SUDAN_TILE, "owner": 0, "cost": 700, "income": 70, "purchased_turn": 1})
	game.state["phase"] = "actions"
	var proposal: Dictionary = game.propose_trade(0, 1, Model.SUDAN_TILE, 6)
	var accepted: Dictionary = game.respond_to_trade(1, true) if bool(proposal.get("pending", false)) else {}
	_check(bool(accepted.get("ok", false)) and int(game.state["tile_owners"][Model.SUDAN_TILE]) == 1, "accepted country trade transfers the requested title")
	_check(int(game.state["investments"][0]["owner"]) == 1 and game.income_for_tile(Model.SUDAN_TILE) > 80, "investment and its yield move with the country instead of being stranded")

func _test_computer_decisions() -> void:
	for difficulty in ["easy", "medium", "hard"]:
		var tier = _fresh(Model.MODE_COMPUTER, [], difficulty)
		tier.state["players"][1]["balance"] = 3500
		var expected: bool = difficulty != "easy"
		_check(tier.computer_should_buy(1, 26) == expected, "%s CPU uses its own reserve and purchase threshold" % difficulty)
	var game = _fresh(Model.MODE_COMPUTER, [], "hard")
	game.state["turn"] = 1
	var result: Dictionary = game.roll(1, 1)
	_check(bool(result["ok"]) and int(game.state["tile_owners"][1]) == 1, "computer is a real controller that buys an affordable country")
	_check(int(game.get_balance(1)) == 8400, "computer purchase uses only its real balance")
	game.state["phase"] = "actions"
	game.state["tile_owners"][Model.SUDAN_TILE] = 1
	game.state["players"][1]["balance"] = 5000
	game.state["can_market"] = true
	var decisions: Array[String] = game.run_computer_actions(1)
	var any_developed := false
	for tile in Model.country_tiles():
		if int(game.state["tile_owners"][tile]) == 1 and int(game.state["development"][tile]) > 0:
			any_developed = true
	_check(not decisions.is_empty() and any_developed, "computer selects a useful affordable development action")
	var market_guard = _fresh(Model.MODE_COMPUTER, [], "hard")
	market_guard.state["turn"] = 1
	market_guard.state["phase"] = "actions"
	market_guard.state["tile_owners"][Model.SUDAN_TILE] = 1
	market_guard.run_computer_actions(1)
	_check(market_guard.state["investments"].is_empty(), "computer does not buy investments off-market even when it owns Sudan")
	var cpu_trade = _fresh(Model.MODE_COMPUTER, [], "hard")
	cpu_trade.state["tile_owners"][Model.SUDAN_TILE] = 1
	cpu_trade.state["phase"] = "actions"
	var offer := {"from": 0, "to": 1, "give_tile": -1, "ask_tile": Model.EGYPT_TILE, "give_cash": 1000, "ask_cash": 0}
	_check(cpu_trade.computer_accepts_trade(1, offer), "computer evaluates a valuable and solvent trade")
	_check(not cpu_trade.computer_accepts_trade(1, {"from": 0, "to": 1, "give_tile": -1, "ask_tile": Model.EGYPT_TILE, "give_cash": 1, "ask_cash": 0}), "computer declines a clearly unfavorable trade")

func _test_match_end_and_net_worth() -> void:
	var game = _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	_check(int(game.state["lap_limit"]) == 10, "new matches persist the default ten laps per player")
	var five = Model.new(24681)
	five.new_game("أ", Model.MODE_LOCAL, ["أ", "ب"], "medium", "normal", 5)
	var fifteen = Model.new(24682)
	fifteen.new_game("أ", Model.MODE_LOCAL, ["أ", "ب"], "medium", "normal", 15)
	_check(int(five.state["lap_limit"]) == 5 and int(fifteen.state["lap_limit"]) == 15, "five and fifteen lap options are stored in the actual match state")
	game.state["tile_owners"][Model.SUDAN_TILE] = 0
	game.state["development"][1] = 2
	game.state["investments"].append({"type": "agriculture", "tile": 1, "owner": 0, "cost": 700, "income": 70, "purchased_turn": 1})
	var worth: Dictionary = game.get_net_worth(0)
	_check(int(worth["net_worth"]) == 10000 + 800 + 650 + 350, "net worth uses cash plus 50 percent property, development, and investment value")
	game.state["players"][0]["completed_laps"] = 10
	game.state["players"][1]["completed_laps"] = 8
	game.state["phase"] = "actions"
	game.state["turn"] = 1
	var end: Dictionary = game.end_turn(1)
	_check(not bool(end["game_over"]) and bool(game.state["active"]) and int(game.state["turn"]) == 1, "one player completing the target laps does not end the match")
	game.state["players"][1]["completed_laps"] = 10
	game.state["phase"] = "actions"
	var final_end: Dictionary = game.end_turn(1)
	_check(bool(final_end["game_over"]) and not bool(game.state["active"]) and str(game.state["result"].get("reason", "")).contains("اللفات"), "match ends only after every player completes the selected laps")
	var tie_game := _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	tie_game.state["players"][0]["completed_laps"] = 10
	tie_game.state["players"][1]["completed_laps"] = 10
	tie_game.state["phase"] = "actions"
	tie_game.end_turn(0)
	_check(bool(tie_game.state["result"].get("tied", false)) and int(tie_game.state["winner_id"]) == -1 and tie_game.state["result"].get("players", []).size() == 2, "equal net worth is published as a tie without inventing a winner")
	var result_snapshot := JSON.stringify(tie_game.state["result"])
	var post_finish_roll: Dictionary = tie_game.roll(0, 1)
	var post_finish_purchase: Dictionary = tie_game.buy_pending_property()
	_check(not bool(post_finish_roll.get("ok", false)) and not bool(post_finish_purchase.get("ok", false)) and JSON.stringify(tie_game.state["result"]) == result_snapshot, "finished matches reject new movement or transactions without changing the result")
	_check(game.state["result"].get("players", [])[0].has("owned_properties") and game.state["result"].get("players", [])[0].has("completed_goals") and game.state["result"].get("players", [])[0].has("trade_count"), "final summaries include only recorded properties, goals, achievements and transaction counts")
	var capped = _fresh(Model.MODE_COMPUTER)
	capped.state["lap_limit"] = 5
	capped.state["players"][0]["completed_laps"] = 5
	capped.state["players"][0]["position"] = 39
	capped.state["phase"] = "await_roll"
	var capped_move: Dictionary = capped.roll(0, 3)
	_check(bool(capped_move.get("ok", false)) and int(capped.state["players"][0]["completed_laps"]) == 5 and int(capped_move.get("crossings", -1)) == 0, "a completed player cannot exceed the lap target or receive another crossing reward")
	var local_finish := _fresh(Model.MODE_LOCAL, ["أ", "ب"])
	local_finish.state["phase"] = "actions"
	var request: Dictionary = local_finish.request_finish_match(0)
	_check(bool(request.get("pending", false)) and bool(local_finish.state["active"]) and not local_finish.state["pending_finish"].is_empty(), "local early finish requires a second human approval")
	var rejected: Dictionary = local_finish.respond_to_finish_request(1, false)
	_check(bool(rejected.get("ok", false)) and bool(local_finish.state["active"]) and local_finish.state["pending_finish"].is_empty(), "one local rejection keeps the match running")
	local_finish.state["phase"] = "actions"
	local_finish.request_finish_match(0)
	var approved: Dictionary = local_finish.respond_to_finish_request(1, true)
	_check(bool(approved.get("finished", false)) and not bool(local_finish.state["active"]), "two local approvals finish the match using the live state")
	var cpu_finish := _fresh(Model.MODE_COMPUTER)
	cpu_finish.state["phase"] = "actions"
	var cpu_end: Dictionary = cpu_finish.finish_match_by_user(0)
	_check(bool(cpu_end.get("ok", false)) and not bool(cpu_finish.state["active"]), "computer mode ends after the human confirmation without a phantom second approval")

func _test_full_local_match_simulation() -> void:
	var game = Model.new(24683)
	game.new_game("أ", Model.MODE_LOCAL, ["أ", "ب"], "medium", "normal", 5)
	var guard := 0
	while bool(game.state["active"]) and guard < 220:
		guard += 1
		var player_id := int(game.state["turn"])
		if str(game.state.get("phase", "")) == "jail":
			game.end_turn(player_id)
			continue
		var move: Dictionary = game.roll(player_id, 6)
		if not bool(move.get("ok", false)):
			break
		if str(game.state.get("phase", "")) == "pending_purchase":
			game.skip_pending_purchase()
		if str(game.state.get("phase", "")) == "jail":
			game.end_turn(player_id)
			continue
		if str(game.state.get("phase", "")) != "actions":
			break
		game.end_turn(player_id)
	_check(not bool(game.state["active"]) and int(game.state["players"][0]["completed_laps"]) == 5 and int(game.state["players"][1]["completed_laps"]) == 5, "full local match reaches the lap target without hanging")
	_check(game.state["result"].get("players", []).size() == 2 and int(game.state["result"].get("lap_limit", 0)) == 5, "simulated match publishes a complete final result from live state")
	for player in game.state["players"]:
		_check(int(player["balance"]) >= 0, "simulated match never creates an unsupported negative balance")

func _test_save_restore_and_corruption() -> void:
	var game = _fresh(Model.MODE_LOCAL, ["أ", "ب", "ج"])
	game.state["tile_owners"][Model.SUDAN_TILE] = 2
	game.state["development"][Model.SUDAN_TILE] = 1
	game.state["investments"].append({"type": "agriculture", "tile": Model.SUDAN_TILE, "owner": 2, "cost": 700, "income": 70, "purchased_turn": 1})
	game.state["turn"] = 2
	game.state["phase"] = "actions"
	game.state["lap_limit"] = 15
	game.state["players"][2]["completed_laps"] = 6
	var finish_request := game.request_finish_match(2)
	var saved: Dictionary = game.save_to(TEST_SAVE)
	var restored: Model = Model.new()
	var loaded: Dictionary = restored.load_from(TEST_SAVE)
	_check(bool(saved.get("ok", false)) and bool(loaded.get("ok", false)), "valid match and investments save and restore")
	_check(int(restored.state["turn"]) == 2 and int(restored.state["tile_owners"][Model.SUDAN_TILE]) == 2 and int(restored.state["development"][Model.SUDAN_TILE]) == 1, "player turn, Sudan title and development persist")
	_check(restored.state["investments"].size() == 1 and int(restored.get_balance(2)) == 10000, "investment and player balances persist")
	_check(bool(finish_request.get("pending", false)) and int(restored.state["lap_limit"]) == 15 and int(restored.state["players"][2]["completed_laps"]) == 6 and not restored.state["pending_finish"].is_empty(), "lap target, per-player progress and early-finish request survive save and restore")
	var restored_accept_0 := restored.respond_to_finish_request(0, true)
	var restored_accept_1 := restored.respond_to_finish_request(1, true)
	_check(bool(restored_accept_0.get("pending", false)) and bool(restored_accept_1.get("finished", false)) and not bool(restored.state["active"]), "restored early-finish approvals remain stable and finish exactly once")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var file := FileAccess.open(CORRUPT_SAVE, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	var corrupt := Model.new().load_from(CORRUPT_SAVE)
	_check(not bool(corrupt.get("ok", false)) and bool(corrupt.get("corrupt", false)), "corrupt save is rejected without a crash")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CORRUPT_SAVE))

func _test_legacy_migration() -> void:
	var old_state := {"mode": "computer", "players": [
		{"id": 0, "name": "لاعب قديم", "controller": "human", "balance": 7400, "position": 5, "completed_laps": 1, "steps_moved": 45},
		{"id": 1, "name": "الكمبيوتر", "controller": "computer", "balance": 9200, "position": 9, "completed_laps": 0, "steps_moved": 9}],
		"tile_owners": [-1, 0, -1, 1, 0, -1, -1, -1, -1, 1, -1, -1], "turn": 0, "turn_number": 4}
	var file := FileAccess.open(LEGACY_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 2, "state": old_state}))
	file.close()
	var game := Model.new()
	var result: Dictionary = game.load_from(LEGACY_SAVE)
	_check(bool(result.get("ok", false)) and bool(result.get("migrated", false)), "version 2 save migrates to new board")
	_check(int(game.state["tile_owners"][Model.EGYPT_TILE]) == 0 and int(game.state["tile_owners"][8]) == 1, "shared countries retain their actual owners")
	_check(str(game.state["phase"]) == "await_roll" and Model.validate_state(game.state), "migrated match is structurally valid and resumable")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE))
