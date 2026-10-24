extends RefCounted
class_name BankGame

const SAVE_VERSION := 2
const STARTING_CASH := 10000
const LAP_BONUS := 500
const TILE_COUNT := 12
const MAX_LOCAL_PLAYERS := 4
const MODE_COMPUTER := "computer"
const MODE_LOCAL := "local"
const PLAYER_HUMAN := 0
const PLAYER_CPU := 1
const SAVE_PATH := "user://luckbank-save.json"

const BOARD := [
	{"id": 0, "type": "start", "name": "البداية"},
	{"id": 1, "type": "country", "name": "مصر", "price": 1000, "rent": 100},
	{"id": 2, "type": "event", "name": "مفاجأة"},
	{"id": 3, "type": "country", "name": "السعودية", "price": 1200, "rent": 120},
	{"id": 4, "type": "country", "name": "الإمارات", "price": 1500, "rent": 150},
	{"id": 5, "type": "tax", "name": "الضريبة"},
	{"id": 6, "type": "country", "name": "المغرب", "price": 1800, "rent": 180},
	{"id": 7, "type": "reward", "name": "مكافأة"},
	{"id": 8, "type": "event", "name": "مفاجأة"},
	{"id": 9, "type": "country", "name": "الأردن", "price": 2000, "rent": 200},
	{"id": 10, "type": "country", "name": "العراق", "price": 2500, "rent": 250},
	{"id": 11, "type": "rest", "name": "راحة"}
]
const EVENTS := [
	{"amount": 200, "text": "عائد استثمار مفاجئ: ربحت 200"},
	{"amount": -150, "text": "إصلاحات عاجلة: دفعت 150"},
	{"amount": 100, "text": "هدية من البنك: ربحت 100"},
	{"amount": -100, "text": "رسم خدمة: دفعت 100"}
]

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func new_game(player_name: String = "اللاعب", mode: String = MODE_COMPUTER, friend_names: Array = []) -> void:
	var clean_mode := MODE_LOCAL if mode == MODE_LOCAL else MODE_COMPUTER
	var player_names: Array[String] = []
	if clean_mode == MODE_COMPUTER:
		player_names = [_clean_player_name(player_name, "اللاعب"), "الكمبيوتر"]
	else:
		for index in range(mini(friend_names.size(), MAX_LOCAL_PLAYERS)):
			player_names.append(_clean_player_name(str(friend_names[index]), "اللاعب %d" % (index + 1)))
		while player_names.size() < 2:
			player_names.append("اللاعب %d" % (player_names.size() + 1))
	var players: Array[Dictionary] = []
	for index in range(player_names.size()):
		var controller := "computer" if clean_mode == MODE_COMPUTER and index == PLAYER_CPU else "human"
		players.append({
			"id": index,
			"name": player_names[index],
			"controller": controller,
			"balance": STARTING_CASH,
			"position": 0,
			"completed_laps": 0,
			"steps_moved": 0
		})
	var owners: Array[int] = []
	for _i in range(TILE_COUNT):
		owners.append(-1)
	state = {
		"mode": clean_mode,
		"players": players,
		"tile_owners": owners,
		"turn": 0,
		"active": true,
		"winner_id": -1,
		"pending_property": -1,
		"busy": false,
		"last_dice": 0,
		"turn_number": 1,
		"last_message": "بدأت المباراة. دور %s أولًا." % player_names[0],
		"log": ["بدأت المباراة برصيد 10,000 لكل لاعب."]
	}

func _clean_player_name(value: String, fallback: String) -> String:
	var cleaned := value.strip_edges()
	return fallback if cleaned.is_empty() else cleaned.substr(0, 24)

static func calculate_move(position: int, steps: int) -> Dictionary:
	if position < 0 or position >= TILE_COUNT or steps < 0:
		return {"ok": false, "position": position, "crossings": 0}
	var total := position + steps
	return {"ok": true, "position": total % TILE_COUNT, "crossings": int(total / TILE_COUNT)}

static func tile_definition(index: int) -> Dictionary:
	if index < 0 or index >= TILE_COUNT:
		return {}
	return BOARD[index].duplicate(true)

func is_human_player(player_id: int) -> bool:
	return _valid_player_id(player_id) and str(state["players"][player_id].get("controller", "")) == "human"

func is_computer_player(player_id: int) -> bool:
	return _valid_player_id(player_id) and str(state["players"][player_id].get("controller", "")) == "computer"

func _valid_player_id(player_id: int) -> bool:
	return not state.is_empty() and player_id >= 0 and player_id < state.get("players", []).size()

func roll(player_id: int, dice: int, forced_event_index: int = -1) -> Dictionary:
	if state.is_empty() or not bool(state.get("active", false)):
		return _failure("انتهت المباراة.")
	if bool(state.get("busy", false)):
		return _failure("انتظر انتهاء معالجة الدور الحالي.")
	if int(state.get("turn", -1)) != player_id:
		return _failure("ليس هذا دورك الآن.")
	if not _valid_player_id(player_id):
		return _failure("معرّف اللاعب غير صالح.")
	if dice < 1 or dice > 6:
		return _failure("نتيجة النرد يجب أن تكون بين 1 و6.")

	state["busy"] = true
	state["last_dice"] = dice
	var player: Dictionary = state["players"][player_id]
	var old_position: int = int(player["position"])
	var movement := calculate_move(old_position, dice)
	var crossings: int = int(movement["crossings"])
	var destination: int = int(movement["position"])
	var path: Array[int] = []
	for step in range(1, dice + 1):
		path.append((old_position + step) % TILE_COUNT)
	player["position"] = destination
	player["steps_moved"] = int(player["steps_moved"]) + dice

	var messages: Array[String] = []
	if crossings > 0:
		player["completed_laps"] = int(player["completed_laps"]) + crossings
		var lap_cash := crossings * LAP_BONUS
		player["balance"] = int(player["balance"]) + lap_cash
		messages.append("عبرت نقطة البداية %d مرة؛ أضيفت %s." % [crossings, _cash(lap_cash)])

	var landing := _resolve_landing(player_id, destination, forced_event_index)
	if not str(landing.get("message", "")).is_empty():
		messages.append(str(landing["message"]))
	if not bool(state["active"]):
		messages.append(str(state["last_message"]))
		return {"ok": true, "path": path, "from": old_position, "to": destination, "crossings": crossings, "messages": messages, "pending_purchase": -1, "game_over": true}

	if int(state["pending_property"]) >= 0:
		state["last_message"] = "اختر شراء الدولة أو تخطي الشراء."
		_add_log("%s: %s" % [player["name"], str(landing.get("message", "وصل إلى دولة متاحة."))])
		return {"ok": true, "path": path, "from": old_position, "to": destination, "crossings": crossings, "messages": messages, "pending_purchase": int(state["pending_property"]), "game_over": false}

	_finish_turn(player_id)
	state["last_message"] = " ".join(messages) if not messages.is_empty() else "انتهى الدور دون تغيير إضافي."
	_add_log("%s رمى %d ووصل إلى %s." % [player["name"], dice, str(BOARD[destination]["name"])])
	return {"ok": true, "path": path, "from": old_position, "to": destination, "crossings": crossings, "messages": messages, "pending_purchase": -1, "game_over": false}

func buy_pending_property() -> Dictionary:
	if state.is_empty() or not bool(state.get("active", false)):
		return _failure("لا يمكن الشراء بعد انتهاء المباراة.")
	var player_id := int(state.get("turn", -1))
	var tile_index := int(state.get("pending_property", -1))
	if tile_index < 0 or tile_index >= TILE_COUNT or not is_human_player(player_id):
		return _failure("لا توجد دولة معروضة للشراء في دور بشري.")
	if str(BOARD[tile_index]["type"]) != "country":
		return _failure("المربع المحدد ليس دولة.")
	if int(state["tile_owners"][tile_index]) != -1:
		return _failure("أصبحت الدولة مملوكة بالفعل.")
	var player: Dictionary = state["players"][player_id]
	var price := int(BOARD[tile_index]["price"])
	if int(player["balance"]) < price:
		return _failure("رصيد %s لا يكفي لشراء هذه الدولة." % str(player["name"]))
	# لا يحدث أي خصم إلا مع تسجيل الملكية في العملية نفسها.
	player["balance"] = int(player["balance"]) - price
	state["tile_owners"][tile_index] = player_id
	state["pending_property"] = -1
	_finish_turn(player_id)
	state["last_message"] = "تم شراء %s مقابل %s للاعب %s." % [str(BOARD[tile_index]["name"]), _cash(price), str(player["name"])]
	_add_log(state["last_message"])
	return {"ok": true, "message": str(state["last_message"]), "tile": tile_index, "price": price, "owner": player_id}

func skip_pending_purchase() -> Dictionary:
	if state.is_empty() or not bool(state.get("active", false)):
		return _failure("لا توجد مباراة نشطة.")
	var player_id := int(state.get("turn", -1))
	var tile_index := int(state.get("pending_property", -1))
	if tile_index < 0 or not is_human_player(player_id):
		return _failure("لا يوجد شراء معلّق لتخطيه.")
	state["pending_property"] = -1
	_finish_turn(player_id)
	state["last_message"] = "تخطى %s شراء %s دون خصم أي مبلغ." % [str(state["players"][player_id]["name"]), str(BOARD[tile_index]["name"])]
	_add_log(state["last_message"])
	return {"ok": true, "message": str(state["last_message"])}

func _resolve_landing(player_id: int, tile_index: int, forced_event_index: int) -> Dictionary:
	var tile: Dictionary = BOARD[tile_index]
	var kind := str(tile["type"])
	var player: Dictionary = state["players"][player_id]
	var result := {"message": ""}
	match kind:
		"start":
			result["message"] = "وقف %s عند البداية." % str(player["name"])
		"country":
			var owner := int(state["tile_owners"][tile_index])
			if owner == -1:
				var price := int(tile["price"])
				if is_computer_player(player_id):
					if _cpu_should_buy(int(player["balance"]), price):
						player["balance"] = int(player["balance"]) - price
						state["tile_owners"][tile_index] = player_id
						result["message"] = "اشترى الكمبيوتر %s مقابل %s." % [str(tile["name"]), _cash(price)]
						_add_log(str(result["message"]))
					else:
						result["message"] = "تجاوز الكمبيوتر شراء %s للمحافظة على رصيده." % str(tile["name"])
				else:
					state["pending_property"] = tile_index
					result["message"] = "%s متاحة للاعب %s بسعر %s." % [str(tile["name"]), str(player["name"]), _cash(price)]
			elif owner == player_id:
				result["message"] = "%s وصل إلى %s المملوكة له؛ لا إيجار عليه." % [str(player["name"]), str(tile["name"])]
			else:
				var rent := int(tile["rent"])
				if int(player["balance"]) < rent:
					_bankrupt(player_id, owner, "أفلس %s لأنه لم يستطع دفع إيجار %s." % [str(player["name"]), str(tile["name"])])
					result["message"] = str(state["last_message"])
				else:
					player["balance"] = int(player["balance"]) - rent
					var recipient: Dictionary = state["players"][owner]
					recipient["balance"] = int(recipient["balance"]) + rent
					result["message"] = "دفع %s إيجار %s قدره %s إلى %s." % [str(player["name"]), str(tile["name"]), _cash(rent), str(recipient["name"])]
					_add_log(str(result["message"]))
		"event":
			var event_index := forced_event_index
			if event_index < 0 or event_index >= EVENTS.size():
				event_index = rng.randi_range(0, EVENTS.size() - 1)
			var event: Dictionary = EVENTS[event_index]
			var amount := int(event["amount"])
			if amount < 0 and int(player["balance"]) < -amount:
				_bankrupt(player_id, _wealthiest_opponent(player_id), "أفلس %s بسبب الحدث: %s." % [str(player["name"]), str(event["text"])])
				result["message"] = str(state["last_message"])
			else:
				player["balance"] = int(player["balance"]) + amount
				result["message"] = str(event["text"])
				_add_log("%s — %s." % [str(player["name"]), str(event["text"])])
		"tax":
			if int(player["balance"]) < 200:
				_bankrupt(player_id, _wealthiest_opponent(player_id), "أفلس %s لأنه لم يستطع دفع ضريبة 200." % str(player["name"]))
				result["message"] = str(state["last_message"])
			else:
				player["balance"] = int(player["balance"]) - 200
				result["message"] = "دفع %s ضريبة قدرها 200." % str(player["name"])
		"reward":
			player["balance"] = int(player["balance"]) + 300
			result["message"] = "مكافأة المربع: أضيف 300 إلى رصيد %s." % str(player["name"])
		"rest":
			result["message"] = "استراحة هادئة؛ لم يتغير رصيد %s." % str(player["name"])
		_:
			result["message"] = "مربع غير معروف."
	return result

func _cpu_should_buy(balance: int, price: int) -> bool:
	# يشتري الكمبيوتر فقط إن كان يستطيع الدفع مع إبقاء احتياطي يتناسب مع سعر الدولة.
	var reserve := maxi(800, int(price / 2))
	return balance >= price and balance - price >= reserve

func _finish_turn(player_id: int) -> void:
	state["busy"] = false
	var player_count: int = state["players"].size()
	if player_id == player_count - 1:
		state["turn_number"] = int(state.get("turn_number", 1)) + 1
	state["turn"] = (player_id + 1) % player_count

func _wealthiest_opponent(loser_id: int) -> int:
	var winner_id := -1
	var winning_balance := -1
	for player_id in range(state.get("players", []).size()):
		if player_id == loser_id:
			continue
		var balance := int(state["players"][player_id]["balance"])
		if balance > winning_balance:
			winning_balance = balance
			winner_id = player_id
	return maxi(0, winner_id)

func _bankrupt(loser_id: int, winner_id: int, message: String) -> void:
	state["active"] = false
	state["winner_id"] = winner_id if winner_id >= 0 and winner_id != loser_id else _wealthiest_opponent(loser_id)
	state["pending_property"] = -1
	state["busy"] = false
	state["turn"] = int(state["winner_id"])
	state["last_message"] = message
	_add_log(message)

func _add_log(message: String) -> void:
	if state.is_empty():
		return
	var history: Array = state.get("log", [])
	history.append(message)
	while history.size() > 8:
		history.pop_front()
	state["log"] = history

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func _cash(value: int) -> String:
	return "%s" % value

static func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		return is_finite(number) and number == float(int(number))
	return false

func get_balance(player_id: int) -> int:
	if not _valid_player_id(player_id):
		return 0
	return int(state["players"][player_id]["balance"])

func count_owned_properties(player_id: int) -> int:
	if not _valid_player_id(player_id):
		return 0
	var count := 0
	for owner in state.get("tile_owners", []):
		if int(owner) == player_id:
			count += 1
	return count

func can_resume() -> bool:
	return not state.is_empty() and validate_state(state)

func save_to(path: String = SAVE_PATH) -> Dictionary:
	if not can_resume():
		return {"ok": false, "message": "حالة اللعبة غير صالحة للحفظ."}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "تعذر إنشاء ملف الحفظ المؤقت."}
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "state": state}))
	file.flush()
	file.close()
	var target := ProjectSettings.globalize_path(path)
	var temporary := ProjectSettings.globalize_path(path + ".tmp")
	var backup := ProjectSettings.globalize_path(path + ".bak")
	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(backup)
		var backup_error := DirAccess.rename_absolute(target, backup)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary)
			return {"ok": false, "message": "تعذر حماية ملف الحفظ السابق (%s)." % error_string(backup_error)}
	var rename_error := DirAccess.rename_absolute(temporary, target)
	if rename_error != OK:
		if had_previous and FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(backup, target)
		DirAccess.remove_absolute(temporary)
		return {"ok": false, "message": "تعذر تثبيت ملف الحفظ (%s)." % error_string(rename_error)}
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(backup)
	return {"ok": true, "message": "تم حفظ المباراة محليًا."}

func load_from(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "missing": true, "message": "لا توجد مباراة محفوظة."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "corrupt": true, "message": "تعذر قراءة ملف الحفظ."}
	var raw := file.get_as_text()
	file.close()
	var parser := JSON.new()
	var parse_error := parser.parse(raw)
	if parse_error != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "corrupt": true, "message": "ملف الحفظ تالف أو غير مكتمل."}
	var payload: Dictionary = parser.data
	var version := int(payload.get("version", -1))
	if version != SAVE_VERSION and version != 1:
		return {"ok": false, "corrupt": true, "message": "إصدار ملف الحفظ غير صالح."}
	if typeof(payload.get("state", null)) != TYPE_DICTIONARY:
		return {"ok": false, "corrupt": true, "message": "بيانات المباراة غير موجودة في ملف الحفظ."}
	var candidate: Dictionary = payload["state"].duplicate(true)
	var migrated := version == 1
	if migrated:
		candidate = _migrate_v1_state(candidate)
	if not validate_state(candidate):
		return {"ok": false, "corrupt": true, "message": "بيانات المباراة المحفوظة غير متوافقة أو تالفة."}
	state = candidate.duplicate(true)
	rng.randomize()
	return {"ok": true, "migrated": migrated, "message": "تم استرجاع المباراة المحفوظة."}

func _migrate_v1_state(old_state: Dictionary) -> Dictionary:
	var migrated := old_state.duplicate(true)
	var old_players: Variant = migrated.get("players", null)
	if typeof(old_players) != TYPE_ARRAY or old_players.size() != 2:
		return {}
	migrated["mode"] = MODE_COMPUTER
	for index in range(2):
		if typeof(old_players[index]) != TYPE_DICTIONARY:
			return {}
		old_players[index]["controller"] = "human" if index == PLAYER_HUMAN else "computer"
	migrated["players"] = old_players
	return migrated

static func validate_state(candidate: Dictionary) -> bool:
	if typeof(candidate) != TYPE_DICTIONARY:
		return false
	var mode: String = str(candidate.get("mode", ""))
	if mode != MODE_COMPUTER and mode != MODE_LOCAL:
		return false
	var players: Variant = candidate.get("players", null)
	var owners: Variant = candidate.get("tile_owners", null)
	if typeof(players) != TYPE_ARRAY or players.size() < 2 or players.size() > MAX_LOCAL_PLAYERS:
		return false
	if mode == MODE_COMPUTER and players.size() != 2:
		return false
	if typeof(owners) != TYPE_ARRAY or owners.size() != TILE_COUNT:
		return false
	for i in range(players.size()):
		if typeof(players[i]) != TYPE_DICTIONARY:
			return false
		var person: Dictionary = players[i]
		for key in ["id", "name", "controller", "balance", "position", "completed_laps", "steps_moved"]:
			if not person.has(key):
				return false
		if not _is_integer_number(person["id"]) or int(person["id"]) != i:
			return false
		if typeof(person["name"]) != TYPE_STRING or str(person["name"]).strip_edges().is_empty():
			return false
		var controller := str(person["controller"])
		if controller != "human" and controller != "computer":
			return false
		if mode == MODE_LOCAL and controller != "human":
			return false
		if mode == MODE_COMPUTER and controller != ("human" if i == PLAYER_HUMAN else "computer"):
			return false
		if not _is_integer_number(person["balance"]) or int(person["balance"]) < 0:
			return false
		if not _is_integer_number(person["position"]) or int(person["position"]) < 0 or int(person["position"]) >= TILE_COUNT:
			return false
		if not _is_integer_number(person["completed_laps"]) or int(person["completed_laps"]) < 0:
			return false
		if not _is_integer_number(person["steps_moved"]) or int(person["steps_moved"]) < 0:
			return false
	for i in range(TILE_COUNT):
		if not _is_integer_number(owners[i]) or int(owners[i]) < -1 or int(owners[i]) >= players.size():
			return false
		if str(BOARD[i]["type"]) != "country" and int(owners[i]) != -1:
			return false
	for required in ["turn", "active", "winner_id", "pending_property", "busy", "last_dice", "turn_number", "last_message", "log"]:
		if not candidate.has(required):
			return false
	if not _is_integer_number(candidate["turn"]) or int(candidate["turn"]) < 0 or int(candidate["turn"]) >= players.size():
		return false
	if typeof(candidate["active"]) != TYPE_BOOL or typeof(candidate["busy"]) != TYPE_BOOL:
		return false
	if not _is_integer_number(candidate["winner_id"]) or int(candidate["winner_id"]) < -1 or int(candidate["winner_id"]) >= players.size():
		return false
	if bool(candidate["active"]) and int(candidate["winner_id"]) != -1:
		return false
	if not bool(candidate["active"]) and int(candidate["winner_id"]) == -1:
		return false
	if not _is_integer_number(candidate["pending_property"]) or int(candidate["pending_property"]) < -1 or int(candidate["pending_property"]) >= TILE_COUNT:
		return false
	if int(candidate["pending_property"]) >= 0:
		var pending := int(candidate["pending_property"])
		var current_player := int(candidate["turn"])
		if not bool(candidate["active"]) or not bool(candidate["busy"]) or str(players[current_player]["controller"]) != "human":
			return false
		if int(players[current_player]["position"]) != pending or str(BOARD[pending]["type"]) != "country" or int(owners[pending]) != -1:
			return false
	elif bool(candidate["busy"]):
		return false
	if not _is_integer_number(candidate["last_dice"]) or int(candidate["last_dice"]) < 0 or int(candidate["last_dice"]) > 6:
		return false
	if not _is_integer_number(candidate["turn_number"]) or int(candidate["turn_number"]) < 1:
		return false
	if typeof(candidate["last_message"]) != TYPE_STRING or typeof(candidate["log"]) != TYPE_ARRAY:
		return false
	return true
