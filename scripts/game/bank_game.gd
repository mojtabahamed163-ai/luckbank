extends RefCounted
class_name BankGame

const SAVE_VERSION := 3
const STARTING_CASH := 10000
const LAP_BONUS := 500
const TILE_COUNT := 40
const MAX_LOCAL_PLAYERS := 4
const MODE_COMPUTER := "computer"
const MODE_LOCAL := "local"
const PLAYER_HUMAN := 0
const PLAYER_CPU := 1
const SAVE_PATH := "user://luckbank-save.json"
const DEV_COSTS := [500, 800, 1200]
const INVESTMENT_DATA := {
	"agriculture": {"name": "الزراعة", "cost": 700, "income": 70, "tiles": [1, 2]},
	"livestock": {"name": "الثروة الحيوانية", "cost": 900, "income": 90, "tiles": [2]},
	"energy": {"name": "الطاقة", "cost": 1000, "income": 100, "tiles": [8]},
	"trade": {"name": "التجارة والخدمات", "cost": 900, "income": 90, "tiles": [1, 9]},
	"industry": {"name": "الصناعة", "cost": 1200, "income": 120, "tiles": [14, 26]},
	"technology": {"name": "التقنية", "cost": 1300, "income": 130, "tiles": [16, 26]},
	"logistics": {"name": "النقل والخدمات اللوجستية", "cost": 850, "income": 85, "tiles": []}
}

# Group membership follows country order: six fixed sets of five countries.
const BOARD := [
	{"id": 0, "type": "start", "name": "البداية", "short": "البداية"},
	{"id": 1, "type": "country", "name": "مصر", "price": 800, "rent": 80, "income": 40, "group": 0, "feature": "التجارة والزراعة"},
	{"id": 2, "type": "country", "name": "السودان", "price": 1600, "rent": 160, "income": 80, "group": 0, "feature": "الزراعة والثروة الحيوانية"},
	{"id": 3, "type": "country", "name": "المغرب", "price": 850, "rent": 85, "income": 40, "group": 0},
	{"id": 4, "type": "country", "name": "جنوب أفريقيا", "price": 1100, "rent": 110, "income": 55, "group": 0},
	{"id": 5, "type": "tax", "name": "ضريبة الخدمات العامة", "amount": 300},
	{"id": 6, "type": "country", "name": "نيجيريا", "price": 1000, "rent": 100, "income": 50, "group": 0},
	{"id": 7, "type": "country", "name": "كينيا", "price": 750, "rent": 75, "income": 35, "group": 1},
	{"id": 8, "type": "country", "name": "السعودية", "price": 1500, "rent": 150, "income": 75, "group": 1, "feature": "الطاقة"},
	{"id": 9, "type": "country", "name": "الإمارات", "price": 1700, "rent": 170, "income": 85, "group": 1, "feature": "التجارة والخدمات"},
	{"id": 10, "type": "jail", "name": "السجن", "bail": 500},
	{"id": 11, "type": "country", "name": "تركيا", "price": 1200, "rent": 120, "income": 60, "group": 1},
	{"id": 12, "type": "country", "name": "الهند", "price": 1300, "rent": 130, "income": 65, "group": 1},
	{"id": 13, "type": "market", "name": "السوق والاستثمار", "market": "local"},
	{"id": 14, "type": "country", "name": "الصين", "price": 2200, "rent": 220, "income": 110, "group": 2, "feature": "الصناعة"},
	{"id": 15, "type": "event", "name": "حدث اقتصادي"},
	{"id": 16, "type": "country", "name": "اليابان", "price": 2100, "rent": 210, "income": 105, "group": 2, "feature": "التقنية"},
	{"id": 17, "type": "country", "name": "كوريا الجنوبية", "price": 1800, "rent": 180, "income": 90, "group": 2},
	{"id": 18, "type": "country", "name": "إندونيسيا", "price": 1000, "rent": 100, "income": 50, "group": 2},
	{"id": 19, "type": "country", "name": "سنغافورة", "price": 1900, "rent": 190, "income": 95, "group": 2},
	{"id": 20, "type": "rest", "name": "الراحة الاقتصادية"},
	{"id": 21, "type": "country", "name": "أستراليا", "price": 1800, "rent": 180, "income": 90, "group": 3},
	{"id": 22, "type": "country", "name": "نيوزيلندا", "price": 1200, "rent": 120, "income": 60, "group": 3},
	{"id": 23, "type": "event", "name": "حدث اقتصادي"},
	{"id": 24, "type": "country", "name": "فرنسا", "price": 2000, "rent": 200, "income": 100, "group": 3},
	{"id": 25, "type": "event", "name": "حدث اقتصادي"},
	{"id": 26, "type": "country", "name": "ألمانيا", "price": 2300, "rent": 230, "income": 115, "group": 3, "feature": "الصناعة والتقنية"},
	{"id": 27, "type": "country", "name": "إيطاليا", "price": 1700, "rent": 170, "income": 85, "group": 3},
	{"id": 28, "type": "country", "name": "إسبانيا", "price": 1600, "rent": 160, "income": 80, "group": 4},
	{"id": 29, "type": "country", "name": "المملكة المتحدة", "price": 2400, "rent": 240, "income": 120, "group": 4},
	{"id": 30, "type": "market", "name": "السوق العالمي", "market": "global"},
	{"id": 31, "type": "country", "name": "النرويج", "price": 1800, "rent": 180, "income": 90, "group": 4},
	{"id": 32, "type": "country", "name": "روسيا", "price": 1900, "rent": 190, "income": 95, "group": 4},
	{"id": 33, "type": "country", "name": "البرازيل", "price": 1400, "rent": 140, "income": 70, "group": 4},
	{"id": 34, "type": "country", "name": "الأرجنتين", "price": 1000, "rent": 100, "income": 50, "group": 5},
	{"id": 35, "type": "event", "name": "حدث اقتصادي"},
	{"id": 36, "type": "country", "name": "المكسيك", "price": 1300, "rent": 130, "income": 65, "group": 5},
	{"id": 37, "type": "country", "name": "كندا", "price": 2200, "rent": 220, "income": 110, "group": 5},
	{"id": 38, "type": "country", "name": "الولايات المتحدة الأمريكية", "price": 2800, "rent": 280, "income": 140, "group": 5, "feature": "الابتكار والسوق العالمي"},
	{"id": 39, "type": "country", "name": "تشيلي", "price": 1100, "rent": 110, "income": 55, "group": 5}
]

# Every card has a distinct description and a deterministic financial or strategic effect.
const EVENTS := [
	{"id": 0, "title": "ارتفاع الطلب على الغذاء", "text": "ازداد الطلب على الغذاء؛ يحصل مالك السودان الزراعي على 140 إضافية.", "amount": 80, "food": true},
	{"id": 1, "title": "انخفاض أسعار السلع", "text": "تراجعت أسعار السلع؛ خسر اللاعب 120 من قيمة المخزون.", "amount": -120},
	{"id": 2, "title": "موسم زراعي ناجح", "text": "موسم زراعي ناجح؛ عائد 180، ويزيد عائد السودان الزراعي 60.", "amount": 180, "food": true},
	{"id": 3, "title": "خسائر محاصيل", "text": "تضررت المحاصيل؛ تكاليف التعويض 150.", "amount": -150},
	{"id": 4, "title": "ارتفاع تكاليف الطاقة", "text": "ارتفعت كلفة الطاقة؛ دفعة طارئة 130.", "amount": -130},
	{"id": 5, "title": "ازدهار التجارة", "text": "نشطت التجارة؛ حصل اللاعب على 160.", "amount": 160},
	{"id": 6, "title": "تباطؤ السوق", "text": "تباطؤ مؤقت في السوق؛ انخفض الرصيد 110.", "amount": -110},
	{"id": 7, "title": "دعم للاستثمار", "text": "منحة استثمار محلية؛ أضيف 220 إلى الرصيد.", "amount": 220},
	{"id": 8, "title": "تكاليف صيانة", "text": "صيانة الممتلكات؛ دفعت 100.", "amount": -100},
	{"id": 9, "title": "تحسن النقل", "text": "تحسن النقل والخدمات؛ مكافأة 140.", "amount": 140},
	{"id": 10, "title": "فرصة تقنية", "text": "فرصة تقنية جديدة؛ مكافأة 190.", "amount": 190},
	{"id": 11, "title": "ضريبة طارئة", "text": "رسم اقتصادي طارئ؛ دفعت 170.", "amount": -170},
	{"id": 12, "title": "تعويض اقتصادي", "text": "تعويض عن اضطراب السوق؛ أضيف 130.", "amount": 130},
	{"id": 13, "title": "زيادة الطلب العالمي", "text": "ارتفع الطلب العالمي؛ عائد 210.", "amount": 210},
	{"id": 14, "title": "ازدحام الموانئ", "text": "تأخر الشحن وارتفعت التكلفة؛ دفعت 90.", "amount": -90},
	{"id": 15, "title": "استرداد جمركي", "text": "استرداد رسوم تجارية؛ أضيف 100.", "amount": 100},
	{"id": 16, "title": "ابتكار محلي", "text": "ابتكار وفّر التكاليف؛ مكافأة 170.", "amount": 170},
	{"id": 17, "title": "تراجع العملة", "text": "تراجع سعر الصرف؛ أثر سلبي 140.", "amount": -140},
	{"id": 18, "title": "مخزون استراتيجي", "text": "بيع جزء من المخزون الاستراتيجي؛ عائد 120.", "amount": 120},
	{"id": 19, "title": "جفاف موسمي", "text": "جفاف موسمي؛ خسر اللاعب 160.", "amount": -160},
	{"id": 20, "title": "طلب غذائي طارئ", "text": "طلب غذائي طارئ؛ عائد زراعي إضافي للسودان عند امتلاك مشروعه.", "amount": 70, "food": true},
	{"id": 21, "title": "تأمين شحنة", "text": "تغطية تأمينية للشحنة؛ استرداد 90.", "amount": 90},
	{"id": 22, "title": "تحديث صناعي", "text": "تحديث صناعي خفّض النفقات؛ مكافأة 150.", "amount": 150},
	{"id": 23, "title": "إضراب نقل", "text": "إضراب في النقل؛ دفعت 180.", "amount": -180},
	{"id": 24, "title": "منحة تدريب", "text": "منحة تدريب للعاملين؛ أضيف 110.", "amount": 110},
	{"id": 25, "title": "سوق موسمي هادئ", "text": "لا تغيير في السوق هذا الدور.", "amount": 0},
	{"id": 26, "title": "صيانة شبكة الكهرباء", "text": "إصلاحات شبكة الكهرباء؛ دفعت 120.", "amount": -120},
	{"id": 27, "title": "تصدير فائض المحصول", "text": "بيع فائض المحصول؛ ربح 145، وزيادة للزراعة السودانية المؤهلة.", "amount": 145, "food": true},
	{"id": 28, "title": "رسوم تخزين", "text": "رسوم تخزين إضافية؛ دفعت 80.", "amount": -80},
	{"id": 29, "title": "انتعاش السياحة", "text": "انتعاش السياحة والخدمات؛ مكافأة 135.", "amount": 135},
	{"id": 30, "title": "طلب على الطاقة", "text": "طلب جديد على الطاقة؛ ربح 175.", "amount": 175},
	{"id": 31, "title": "تأخر مشروع", "text": "تأخر تنفيذ مشروع؛ دفعت 125.", "amount": -125},
	{"id": 32, "title": "اتفاقية تجارة", "text": "اتفاقية تجارية نافعة؛ أضيف 200.", "amount": 200},
	{"id": 33, "title": "تقلب أسعار الفائدة", "text": "تكلفة تمويل أعلى؛ دفعت 105.", "amount": -105},
	{"id": 34, "title": "حافز إنتاج", "text": "حافز لزيادة الإنتاج؛ مكافأة 155.", "amount": 155},
	{"id": 35, "title": "فحص سلامة غذائية", "text": "فحص سلامة غذائية؛ كلفة 95، ويستفيد المشروع السوداني من دعم 35.", "amount": -95, "food": true},
	{"id": 36, "title": "استرداد تأمين", "text": "استرداد بوليصة تأمين؛ أضيف 115.", "amount": 115},
	{"id": 37, "title": "شح مواد أولية", "text": "شح في المواد الأولية؛ دفعت 165.", "amount": -165},
	{"id": 38, "title": "خدمات رقمية", "text": "توسع الخدمات الرقمية؛ مكافأة 185.", "amount": 185},
	{"id": 39, "title": "ميزانية متوازنة", "text": "استقرت الميزانية؛ لا ربح أو خسارة.", "amount": 0}
]

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

static func calculate_move(position: int, steps: int) -> Dictionary:
	if position < 0 or position >= TILE_COUNT or steps < 0:
		return {"ok": false, "position": position, "crossings": 0}
	var total := position + steps
	return {"ok": true, "position": total % TILE_COUNT, "crossings": int(total / TILE_COUNT)}

static func tile_definition(index: int) -> Dictionary:
	if index < 0 or index >= TILE_COUNT:
		return {}
	return BOARD[index].duplicate(true)

static func country_tiles() -> Array[int]:
	var result: Array[int] = []
	for tile in BOARD:
		if str(tile["type"]) == "country":
			result.append(int(tile["id"]))
	return result

func new_game(player_name: String = "اللاعب", mode: String = MODE_COMPUTER, friend_names: Array = [], difficulty: String = "medium", duration: String = "normal") -> void:
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
		players.append({"id": index, "name": player_names[index], "controller": controller,
			"balance": STARTING_CASH, "position": 0, "completed_laps": 0, "steps_moved": 0,
			"alive": true, "debt": 0, "difficulty": _clean_difficulty(difficulty)})
	var owners: Array[int] = []
	var development: Array[int] = []
	for _i in range(TILE_COUNT):
		owners.append(-1)
		development.append(0)
	var limit := 8 if duration == "short" else (24 if duration == "long" else 16)
	var deck: Array[int] = []
	for card_id in range(EVENTS.size()):
		deck.append(card_id)
	_shuffle(deck)
	state = {"mode": clean_mode, "players": players, "tile_owners": owners, "development": development,
		"investments": [], "turn": 0, "active": true, "winner_id": -1, "pending_property": -1,
		"pending_obligation": {}, "pending_trade": {}, "busy": false, "phase": "await_roll",
		"last_dice": 0, "turn_number": 1, "round_number": 1, "round_limit": limit,
		"duration": duration if duration in ["short", "normal", "long"] else "normal",
		"difficulty": _clean_difficulty(difficulty), "can_market": false, "did_develop": false,
		"did_invest": false, "current_tile": 0, "event_deck": deck, "event_discard": [],
		"last_event": {}, "last_message": "بدأت المباراة. دور %s أولًا." % player_names[0],
		"ledger": [], "log": ["بدأت المباراة برصيد 10,000 لكل لاعب."], "result": {}}

func _clean_player_name(value: String, fallback: String) -> String:
	var cleaned := value.strip_edges()
	return fallback if cleaned.is_empty() else cleaned.substr(0, 24)

func _clean_difficulty(value: String) -> String:
	return value if value in ["easy", "medium", "hard"] else "medium"

func _shuffle(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: Variant = values[i]
		values[i] = values[j]
		values[j] = temp

func is_human_player(player_id: int) -> bool:
	return _valid_player_id(player_id) and str(state["players"][player_id].get("controller", "")) == "human"

func is_computer_player(player_id: int) -> bool:
	return _valid_player_id(player_id) and str(state["players"][player_id].get("controller", "")) == "computer"

func _valid_player_id(player_id: int) -> bool:
	return not state.is_empty() and player_id >= 0 and player_id < state.get("players", []).size()

func _is_alive(player_id: int) -> bool:
	return _valid_player_id(player_id) and bool(state["players"][player_id].get("alive", true))

func _can_act(player_id: int, allowed_phases: Array = ["actions"]) -> bool:
	return not state.is_empty() and bool(state.get("active", false)) and _valid_player_id(player_id) and _is_alive(player_id) and int(state.get("turn", -1)) == player_id and str(state.get("phase", "")) in allowed_phases

func roll(player_id: int, dice: int, forced_event_index: int = -1) -> Dictionary:
	if state.is_empty() or not bool(state.get("active", false)):
		return _failure("انتهت المباراة.")
	if str(state.get("phase", "")) != "await_roll":
		return _failure("أكمل الإجراء الحالي قبل رمية جديدة.")
	if int(state.get("turn", -1)) != player_id or not _valid_player_id(player_id):
		return _failure("ليس هذا دورك الآن.")
	if not _is_alive(player_id):
		return _failure("خرج هذا اللاعب من المباراة.")
	if dice < 1 or dice > 6:
		return _failure("نتيجة النرد يجب أن تكون بين 1 و6.")
	state["last_dice"] = dice
	state["can_market"] = false
	state["did_develop"] = false
	state["did_invest"] = false
	var player: Dictionary = state["players"][player_id]
	var old_position := int(player["position"])
	var movement := calculate_move(old_position, dice)
	var destination := int(movement["position"])
	var crossings := int(movement["crossings"])
	var path: Array[int] = []
	for step in range(1, dice + 1):
		path.append((old_position + step) % TILE_COUNT)
	player["position"] = destination
	player["steps_moved"] = int(player["steps_moved"]) + dice
	state["current_tile"] = destination
	var messages: Array[String] = []
	if crossings > 0:
		player["completed_laps"] = int(player["completed_laps"]) + crossings
		for _crossing in range(crossings):
			_credit(player_id, LAP_BONUS, "مكافأة عبور البداية", -1, "start")
			var periodic := collect_periodic_income(player_id)
			messages.append("دخل دوري عند البداية: %s." % _cash(periodic))
		messages.append("عبرت البداية %d مرة؛ أضيفت مكافأة %s لكل عبور." % [crossings, _cash(LAP_BONUS)])
	var landing := _resolve_landing(player_id, destination, forced_event_index)
	if not str(landing.get("message", "")).is_empty():
		messages.append(str(landing["message"]))
	if str(state.get("phase", "")) == "await_roll":
		state["phase"] = "actions"
	state["busy"] = str(state.get("phase", "")) in ["pending_purchase", "obligation", "trade"]
	state["last_message"] = "\n".join(messages) if not messages.is_empty() else "انتهت الحركة. يمكنك التطوير أو الاستثمار أو إنهاء الدور."
	_add_log("%s رمى %d ووصل إلى %s." % [str(player["name"]), dice, str(BOARD[destination]["name"])])
	var pending := int(state.get("pending_property", -1))
	return {"ok": true, "path": path, "from": old_position, "to": destination, "crossings": crossings,
		"messages": messages, "pending_purchase": pending, "phase": str(state["phase"]),
		"game_over": not bool(state.get("active", false)), "last_event": state.get("last_event", {})}

func _resolve_landing(player_id: int, tile_index: int, forced_event_index: int) -> Dictionary:
	var tile: Dictionary = BOARD[tile_index]
	var kind := str(tile["type"])
	var player: Dictionary = state["players"][player_id]
	var result := {"message": ""}
	match kind:
		"start":
			result["message"] = "وصل %s إلى البداية؛ لا مكافأة إضافية عند الوقوف." % str(player["name"])
		"country":
			var owner := int(state["tile_owners"][tile_index])
			if owner == -1:
				if is_computer_player(player_id):
					if computer_should_buy(player_id, tile_index):
						var paid := _commit_payment(player_id, int(tile["price"]), "شراء " + str(tile["name"]), -1, "purchase")
						if paid:
							state["tile_owners"][tile_index] = player_id
							result["message"] = "اشترى الكمبيوتر %s مقابل %s." % [str(tile["name"]), _cash(int(tile["price"]))]
						else:
							result["message"] = "توقّف الكمبيوتر لتسوية تكلفة الشراء."
					else:
						result["message"] = "تجاوز الكمبيوتر شراء %s للمحافظة على السيولة." % str(tile["name"])
				else:
					state["pending_property"] = tile_index
					state["phase"] = "pending_purchase"
					result["message"] = "%s متاحة بسعر %s؛ راجع رصيدك قبل القرار." % [str(tile["name"]), _cash(int(tile["price"]))]
			elif owner == player_id:
				result["message"] = "هذه الدولة ملكك؛ لا تدفع إيجارًا لنفسك."
			else:
				var rent := rent_for_tile(tile_index)
				var owner_name := str(state["players"][owner]["name"])
				if _commit_payment(player_id, rent, "إيجار " + str(tile["name"]), owner, "rent"):
					result["message"] = "دفع %s إيجار %s وقدره %s إلى %s." % [str(player["name"]), str(tile["name"]), _cash(rent), owner_name]
				else:
					result["message"] = "تعذر دفع إيجار %s؛ اختر التصفية أو الإفلاس." % str(tile["name"])
		"tax":
			var tax_amount := int(tile["amount"])
			if _commit_payment(player_id, tax_amount, str(tile["name"]), -1, "tax"):
				result["message"] = "سُجلت ضريبة %s بمبلغ %s." % [str(tile["name"]), _cash(tax_amount)]
			else:
				result["message"] = "رصيد غير كافٍ لضريبة %s؛ يمكنك تصفية أصل قبل الإفلاس." % _cash(tax_amount)
		"event":
			var card := _draw_event(forced_event_index)
			state["last_event"] = card.duplicate(true)
			var event_amount := int(card.get("amount", 0))
			var food_bonus := 0
			if bool(card.get("food", false)) and has_investment(player_id, "agriculture", 2):
				food_bonus = 60 if event_amount >= 0 else 35
			var net_amount := event_amount + food_bonus
			if net_amount >= 0:
				_credit(player_id, net_amount, "حدث: " + str(card["title"]), -1, "event")
				result["message"] = str(card["text"])
				if food_bonus > 0:
					result["message"] += " ميزة الأمن الغذائي السودانية: +%s." % _cash(food_bonus)
			else:
				if _commit_payment(player_id, -net_amount, "حدث: " + str(card["title"]), -1, "event"):
					result["message"] = str(card["text"])
					if food_bonus > 0:
						result["message"] += " دعم المشروع الزراعي: +%s." % _cash(food_bonus)
				else:
					result["message"] = str(card["text"]) + " لا يكفي الرصيد؛ اختر التصفية."
		"market":
			state["can_market"] = true
			result["message"] = "وصلت إلى " + str(tile["name"]) + ". افتح السوق لرؤية التكلفة والعائد قبل التأكيد."
		"rest":
			result["message"] = "راحة اقتصادية: لا ضريبة ولا مكافأة تلقائية؛ لم يتغير الرصيد."
		"jail":
			var bail := int(tile.get("bail", 500))
			if _commit_payment(player_id, bail, "كفالة الخروج من السجن", -1, "jail_bail"):
				result["message"] = "دفع %s كفالة السجن وقدرها %s وخرج منه." % [str(player["name"]), _cash(bail)]
			else:
				result["message"] = "لا يكفي الرصيد لكفالة السجن؛ سوِّ الالتزام أو صفِّ أصلًا."
		_:
			result["message"] = "مربع غير معروف؛ لم تُجرَ معاملة مالية."
	return result

func _draw_event(forced_index: int = -1) -> Dictionary:
	if forced_index >= 0 and forced_index < EVENTS.size():
		return EVENTS[forced_index].duplicate(true)
	var deck: Array = state.get("event_deck", [])
	if deck.is_empty():
		for i in range(EVENTS.size()):
			deck.append(i)
		_shuffle(deck)
		state["event_deck"] = deck
		state["event_discard"] = []
	var card_id := int(deck.pop_back())
	state["event_deck"] = deck
	var discard: Array = state.get("event_discard", [])
	discard.append(card_id)
	state["event_discard"] = discard
	return EVENTS[card_id].duplicate(true)

func _credit(player_id: int, amount: int, reason: String, recipient: int = -1, category: String = "income") -> bool:
	if amount < 0 or not _valid_player_id(player_id):
		return false
	var player: Dictionary = state["players"][player_id]
	player["balance"] = int(player["balance"]) + amount
	_record_transaction(player_id, amount, reason, recipient, category)
	return true

func _commit_payment(player_id: int, amount: int, reason: String, recipient: int = -1, category: String = "expense") -> bool:
	if amount < 0 or not _valid_player_id(player_id):
		return false
	var player: Dictionary = state["players"][player_id]
	if int(player["balance"]) < amount:
		state["pending_obligation"] = {"debtor": player_id, "amount": amount, "reason": reason, "recipient": recipient, "category": category}
		state["phase"] = "obligation"
		state["busy"] = true
		_add_log("%s يحتاج إلى %s لسداد %s؛ لم يُخصم مبلغ ولم يصبح الرصيد سالبًا." % [str(player["name"]), _cash(amount - int(player["balance"])), reason])
		return false
	player["balance"] = int(player["balance"]) - amount
	_record_transaction(player_id, -amount, reason, recipient, category)
	if recipient >= 0 and recipient != player_id:
		var receiver: Dictionary = state["players"][recipient]
		receiver["balance"] = int(receiver["balance"]) + amount
		_record_transaction(recipient, amount, reason, player_id, "transfer_in")
	return true

func _record_transaction(player_id: int, amount: int, reason: String, recipient: int, category: String) -> void:
	var balance_after := int(state["players"][player_id]["balance"])
	var transaction := {"player": player_id, "amount": amount, "reason": reason, "recipient": recipient,
		"balance_after": balance_after, "category": category, "turn": int(state.get("turn_number", 1))}
	var ledger: Array = state.get("ledger", [])
	ledger.append(transaction)
	while ledger.size() > 500:
		ledger.pop_front()
	state["ledger"] = ledger
	var sign := "+" if amount >= 0 else ""
	_add_log("%s | %s%s | %s | الرصيد %s" % [str(state["players"][player_id]["name"]), sign + str(amount), "", reason, _cash(balance_after)])

func collect_periodic_income(player_id: int) -> int:
	if not _valid_player_id(player_id):
		return 0
	var total := 0
	for tile_index in country_tiles():
		if int(state["tile_owners"][tile_index]) == player_id:
			var income := income_for_tile(tile_index)
			if income > 0:
				total += income
				_credit(player_id, income, "دخل دوري من " + str(BOARD[tile_index]["name"]), -1, "periodic_income")
	return total

func income_for_tile(tile_index: int) -> int:
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country":
		return 0
	var owner := int(state["tile_owners"][tile_index])
	if owner < 0:
		return 0
	var level := int(state["development"][tile_index])
	var result := int(BOARD[tile_index]["income"]) * (100 + level * 10) / 100
	for investment in state.get("investments", []):
		if int(investment.get("owner", -1)) == owner and int(investment.get("tile", -1)) == tile_index:
				var investment_type := str(investment.get("type", ""))
				var base_yield := int(investment.get("income", 0))
				var extra_percent := _special_investment_percent(tile_index, investment_type)
				result += base_yield + int(base_yield * extra_percent / 100.0)
				if tile_index == 2 and investment_type == "agriculture":
					result += int(BOARD[tile_index]["income"] * 0.25)
	return result

func rent_for_tile(tile_index: int) -> int:
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country":
		return 0
	var owner := int(state["tile_owners"][tile_index])
	if owner < 0:
		return 0
	var level := int(state["development"][tile_index])
	var rent := int(BOARD[tile_index]["rent"]) * (100 + level * 25) / 100
	if owns_complete_group(owner, int(BOARD[tile_index]["group"])):
		rent = int(rent * 1.25)
	return rent

func _special_investment_percent(tile_index: int, investment_type: String) -> int:
	match tile_index:
		1:
			return 15 if investment_type in ["agriculture", "trade"] else 0
		2:
			return 0
		8:
			return 25 if investment_type == "energy" else 0
		9:
			return 20 if investment_type == "trade" else 0
		14:
			return 25 if investment_type == "industry" else 0
		16:
			return 20 if investment_type == "technology" else 0
		26:
			return 10 if investment_type in ["industry", "technology"] else 0
		38:
			return 10
	return 0

func owns_complete_group(player_id: int, group_id: int) -> bool:
	if not _valid_player_id(player_id) or group_id < 0:
		return false
	var count := 0
	for tile in BOARD:
		if str(tile["type"]) == "country" and int(tile["group"]) == group_id:
			count += 1
			if int(state["tile_owners"][int(tile["id"])]) != player_id:
				return false
	return count == 5

func group_tiles(group_id: int) -> Array[int]:
	var result: Array[int] = []
	for tile in BOARD:
		if str(tile["type"]) == "country" and int(tile["group"]) == group_id:
			result.append(int(tile["id"]))
	return result

func buy_pending_property() -> Dictionary:
	if not _can_act(int(state.get("turn", -1)), ["pending_purchase"]):
		return _failure("لا توجد دولة معلقة للشراء في هذا الدور.")
	var player_id := int(state["turn"])
	var tile_index := int(state.get("pending_property", -1))
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country":
		return _failure("المربع المحدد ليس دولة قابلة للشراء.")
	if int(state["tile_owners"][tile_index]) != -1:
		return _failure("الدولة مملوكة بالفعل.")
	var price := int(BOARD[tile_index]["price"])
	if int(state["players"][player_id]["balance"]) < price:
		return _failure("الرصيد لا يكفي؛ اختر تجاوز الشراء أو لا تشترِ.")
	if not _commit_payment(player_id, price, "شراء " + str(BOARD[tile_index]["name"]), -1, "purchase"):
		return _failure("تعذر إتمام الشراء.")
	state["tile_owners"][tile_index] = player_id
	state["pending_property"] = -1
	state["phase"] = "actions"
	state["busy"] = false
	state["last_message"] = "اشترى %s %s مقابل %s." % [str(state["players"][player_id]["name"]), str(BOARD[tile_index]["name"]), _cash(price)]
	_add_log(str(state["last_message"]))
	return {"ok": true, "message": state["last_message"], "tile": tile_index, "price": price, "owner": player_id}

func skip_pending_purchase() -> Dictionary:
	if not _can_act(int(state.get("turn", -1)), ["pending_purchase"]):
		return _failure("لا يوجد شراء معلق لتجاوزه.")
	var tile_index := int(state["pending_property"])
	state["pending_property"] = -1
	state["phase"] = "actions"
	state["busy"] = false
	state["last_message"] = "تجاوز %s شراء %s دون خصم." % [str(state["players"][int(state["turn"])]["name"]), str(BOARD[tile_index]["name"])]
	_add_log(str(state["last_message"]))
	return {"ok": true, "message": state["last_message"]}

func upgrade_property(player_id: int, tile_index: int) -> Dictionary:
	if not _can_act(player_id):
		return _failure("التطوير متاح بعد الحركة وقبل إنهاء الدور.")
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country" or int(state["tile_owners"][tile_index]) != player_id:
		return _failure("لا تملك هذه الدولة.")
	var level := int(state["development"][tile_index])
	if level >= DEV_COSTS.size():
		return _failure("وصلت الدولة إلى أعلى مستوى تطوير.")
	var cost := development_cost(player_id, tile_index)
	if int(state["players"][player_id]["balance"]) < cost:
		return _failure("الرصيد لا يكفي للتطوير؛ التكلفة %s." % _cash(cost))
	var rent_before := rent_for_tile(tile_index)
	var income_before := income_for_tile(tile_index)
	if not _commit_payment(player_id, cost, "تطوير " + str(BOARD[tile_index]["name"]), -1, "development"):
		return _failure("تعذر دفع تكلفة التطوير.")
	state["development"][tile_index] = level + 1
	state["did_develop"] = true
	var rent_after := rent_for_tile(tile_index)
	var income_after := income_for_tile(tile_index)
	var message := "تطوير %s إلى المستوى %d: الإيجار %s→%s، والدخل الدوري %s→%s." % [str(BOARD[tile_index]["name"]), level + 1, _cash(rent_before), _cash(rent_after), _cash(income_before), _cash(income_after)]
	state["last_message"] = message
	_add_log(message)
	return {"ok": true, "message": message, "cost": cost, "level": level + 1, "rent_before": rent_before, "rent_after": rent_after, "income_before": income_before, "income_after": income_after}

func development_cost(player_id: int, tile_index: int) -> int:
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country" or int(state["tile_owners"][tile_index]) != player_id:
		return -1
	var level := int(state["development"][tile_index])
	if level < 0 or level >= DEV_COSTS.size():
		return -1
	var base_cost := int(DEV_COSTS[level])
	var discount := 0
	if owns_complete_group(player_id, int(BOARD[tile_index]["group"])):
		discount += int(base_cost * 0.1)
	if tile_index == 26:
		discount += int(base_cost * 0.1)
	return maxi(1, base_cost - discount)

func investment_options(player_id: int, tile_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _valid_player_id(player_id) or not _valid_tile(tile_index) or int(state["tile_owners"][tile_index]) != player_id:
		return result
	for kind in INVESTMENT_DATA.keys():
		var info: Dictionary = INVESTMENT_DATA[kind]
		var allowed_tiles: Array = info["tiles"]
		if kind == "logistics" or tile_index in allowed_tiles or (tile_index == 38 and str(kind) != "livestock"):
			var existing_index := -1
			var investments: Array = state.get("investments", [])
			for investment_index in range(investments.size()):
				if int(investments[investment_index].get("owner", -1)) == player_id and int(investments[investment_index].get("tile", -1)) == tile_index and str(investments[investment_index].get("type", "")) == str(kind):
					existing_index = investment_index
					break
			if existing_index < 0:
				var extra := _special_investment_percent(tile_index, str(kind))
				var base_income := int(info["income"])
				var sudan_bonus := int(BOARD[tile_index]["income"] * 0.25) if tile_index == 2 and str(kind) == "agriculture" else 0
				var total_income := base_income + int(base_income * extra / 100.0) + sudan_bonus
				result.append({"type": str(kind), "name": str(info["name"]), "tile": tile_index,
					"cost": int(info["cost"]), "income": total_income,
					"extra_percent": extra, "payback": int(ceil(float(info["cost"]) / float(maxi(1, total_income))) )})
			elif tile_index == 2 and str(kind) in ["agriculture", "livestock"]:
				var current_level := int(investments[existing_index].get("level", 0))
				if current_level < 2:
					var next_level := current_level + 1
					var expansion_cost := (500 if str(kind) == "agriculture" else 600) + current_level * 200
					var expansion_income := (55 if str(kind) == "agriculture" else 60) + current_level * 15
					result.append({"type": str(kind), "name": str(info["name"]), "tile": tile_index,
						"cost": expansion_cost, "income": expansion_income, "expansion": true,
						"expansion_level": next_level,
						"payback": int(ceil(float(expansion_cost) / float(maxi(1, expansion_income))))})
	return result

func buy_investment(player_id: int, investment_type: String, tile_index: int) -> Dictionary:
	if not _can_act(player_id):
		return _failure("الاستثمار متاح بعد الحركة وقبل إنهاء الدور.")
	if not bool(state.get("can_market", false)):
		return _failure("يجب الوقوف على إحدى خانات السوق قبل شراء الاستثمار.")
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country" or int(state["tile_owners"][tile_index]) != player_id:
		return _failure("يجب أن تملك الدولة المرتبط بها الاستثمار.")
	var info: Dictionary = INVESTMENT_DATA.get(investment_type, {})
	if info.is_empty():
		return _failure("نوع الاستثمار غير معروف.")
	if investment_type != "logistics" and tile_index != 38 and not tile_index in info["tiles"]:
		return _failure("هذا الاستثمار غير مرتبط بهذه الدولة.")
	if investment_type == "livestock" and tile_index != 2:
		return _failure("استثمار الثروة الحيوانية متاح للسودان فقط.")
	var investments: Array = state.get("investments", [])
	var existing_index := -1
	for investment_index in range(investments.size()):
		if int(investments[investment_index].get("owner", -1)) == player_id and int(investments[investment_index].get("tile", -1)) == tile_index and str(investments[investment_index].get("type", "")) == investment_type:
			existing_index = investment_index
			break
	if existing_index >= 0:
		if tile_index != 2 or investment_type not in ["agriculture", "livestock"]:
			return _failure("تم شراء هذا الاستثمار لهذه الدولة من قبل.")
		var current_level := int(investments[existing_index].get("level", 0))
		if current_level >= 2:
			return _failure("وصل مشروع السودان إلى آخر مرحلة توسعة.")
		var expansion_cost := (500 if investment_type == "agriculture" else 600) + current_level * 200
		var expansion_income := (55 if investment_type == "agriculture" else 60) + current_level * 15
		if int(state["players"][player_id]["balance"]) < expansion_cost:
			return _failure("الرصيد غير كافٍ؛ تكلفة التوسعة %s." % _cash(expansion_cost))
		if not _commit_payment(player_id, expansion_cost, "توسعة " + str(info["name"]) + " في السودان", -1, "investment"):
			return _failure("تعذر دفع قيمة التوسعة.")
		var expanded: Dictionary = investments[existing_index]
		expanded["level"] = current_level + 1
		expanded["cost"] = int(expanded.get("cost", 0)) + expansion_cost
		expanded["income"] = int(expanded.get("income", int(info["income"]))) + expansion_income
		investments[existing_index] = expanded
		state["investments"] = investments
		state["did_invest"] = true
		var expansion_message := "توسعة %s في السودان إلى المرحلة %d: التكلفة %s، وتزيد الدخل الدوري %s." % [str(info["name"]), current_level + 1, _cash(expansion_cost), _cash(expansion_income)]
		_add_log(expansion_message)
		state["last_message"] = expansion_message
		return {"ok": true, "message": expansion_message, "cost": expansion_cost, "income": expansion_income, "level": current_level + 1, "payback": int(ceil(float(expansion_cost) / float(maxi(1, expansion_income))))}
	var cost := int(info["cost"])
	if int(state["players"][player_id]["balance"]) < cost:
		return _failure("الرصيد غير كافٍ؛ التكلفة %s." % _cash(cost))
	var base_income := int(info["income"])
	var special := _special_investment_percent(tile_index, investment_type)
	var sudan_bonus := int(BOARD[tile_index]["income"] * 0.25) if tile_index == 2 and investment_type == "agriculture" else 0
	var income := base_income + int(base_income * special / 100.0) + sudan_bonus
	if not _commit_payment(player_id, cost, "شراء استثمار " + str(info["name"]) + " في " + str(BOARD[tile_index]["name"]), -1, "investment"):
		return _failure("تعذر دفع قيمة الاستثمار.")
	investments.append({"type": investment_type, "tile": tile_index, "owner": player_id, "cost": cost, "income": base_income, "level": 0, "purchased_turn": int(state["turn_number"])})
	state["investments"] = investments
	state["did_invest"] = true
	var message := "استثمار %s في %s: التكلفة %s، والعائد الدوري المتوقع %s%s%s." % [str(info["name"]), str(BOARD[tile_index]["name"]), _cash(cost), _cash(income), " (ميزة الدولة +%d بالمئة)" % special if special > 0 else "", " (مشروع السودان +25 بالمئة من الدخل الأساسي)" if sudan_bonus > 0 else ""]
	_add_log(message)
	state["last_message"] = message
	return {"ok": true, "message": message, "cost": cost, "income": income, "payback": int(ceil(float(cost) / float(maxi(1, income))))}

func has_investment(player_id: int, investment_type: String, tile_index: int = -1) -> bool:
	for investment in state.get("investments", []):
		if int(investment.get("owner", -1)) == player_id and str(investment.get("type", "")) == investment_type and (tile_index < 0 or int(investment.get("tile", -1)) == tile_index):
			return true
	return false

func sell_investment(player_id: int, investment_index: int) -> Dictionary:
	if not _can_act(player_id) and not _can_act(player_id, ["obligation"]):
		return _failure("لا يمكن بيع الاستثمار في هذه المرحلة.")
	if str(state.get("phase", "")) == "actions" and not bool(state.get("can_market", false)):
		return _failure("يمكن بيع الاستثمار من إحدى خانات السوق فقط.")
	var investments: Array = state.get("investments", [])
	if investment_index < 0 or investment_index >= investments.size():
		return _failure("الاستثمار المحدد غير موجود.")
	var item: Dictionary = investments[investment_index]
	if int(item.get("owner", -1)) != player_id:
		return _failure("هذا الاستثمار ليس ملكك.")
	var refund := int(item.get("cost", 0)) / 2
	investments.remove_at(investment_index)
	state["investments"] = investments
	_credit(player_id, refund, "بيع استثمار " + str(INVESTMENT_DATA.get(str(item["type"]), {}).get("name", item["type"])), -1, "asset_sale")
	_add_log("بيع الاستثمار يعيد 50% من تكلفته الأصلية وفق القاعدة المعلنة.")
	_try_settle_obligation(player_id)
	return {"ok": true, "refund": refund, "message": "تم بيع الاستثمار واسترداد %s (50 بالمئة من التكلفة)." % _cash(refund)}

func end_turn(player_id: int) -> Dictionary:
	if not _can_act(player_id, ["actions"]):
		return _failure("أكمل الشراء أو الالتزام المعلق قبل إنهاء الدور.")
	state["busy"] = false
	state["pending_property"] = -1
	var next := _next_alive_player(player_id)
	state["turn_number"] = int(state.get("turn_number", 1)) + 1
	if next <= player_id:
		state["round_number"] = int(state.get("round_number", 1)) + 1
	state["turn"] = next
	state["phase"] = "await_roll"
	state["can_market"] = false
	state["last_message"] = "انتهى الدور. دور %s." % str(state["players"][next]["name"])
	_add_log(str(state["last_message"]))
	if int(state["round_number"]) > int(state["round_limit"]):
		_finish_match("اكتمل حد الجولات (%d)." % int(state["round_limit"]))
	return {"ok": true, "next_player": next, "round": int(state["round_number"]), "game_over": not bool(state["active"]), "message": str(state["last_message"])}

func _next_alive_player(after_id: int) -> int:
	var players: Array = state.get("players", [])
	for offset in range(1, players.size() + 1):
		var candidate := (after_id + offset) % players.size()
		if bool(players[candidate].get("alive", true)):
			return candidate
	return after_id

func computer_should_buy(player_id: int, tile_index: int) -> bool:
	if not _valid_player_id(player_id) or not _valid_tile(tile_index) or int(state["tile_owners"][tile_index]) != -1:
		return false
	var price := int(BOARD[tile_index]["price"])
	var balance := int(state["players"][player_id]["balance"])
	var difficulty := str(state["players"][player_id].get("difficulty", state.get("difficulty", "medium")))
	var reserve := 1100 if difficulty == "easy" else (700 if difficulty == "medium" else 400)
	var score := float(balance - price - reserve)
	var group_count := 0
	for group_tile in group_tiles(int(BOARD[tile_index].get("group", -1))):
		if int(state["tile_owners"][group_tile]) == player_id:
			group_count += 1
	if group_count > 0:
		score += float(group_count * 180)
	var threshold := 250.0 if difficulty == "easy" else (0.0 if difficulty == "medium" else -350.0)
	return balance >= price and score >= threshold

func run_computer_actions(player_id: int) -> Array[String]:
	var decisions: Array[String] = []
	if not is_computer_player(player_id) or not _can_act(player_id):
		return decisions
	var difficulty := str(state["players"][player_id].get("difficulty", "medium"))
	var balance := int(state["players"][player_id]["balance"])
	var reserve := 1500 if difficulty == "easy" else (900 if difficulty == "medium" else 550)
	var best_tile := -1
	var best_score := -999999
	for tile in country_tiles():
		if int(state["tile_owners"][tile]) != player_id or int(state["development"][tile]) >= DEV_COSTS.size():
			continue
		var cost := development_cost(player_id, tile)
		if balance - cost < reserve:
			continue
		var score := int(BOARD[tile]["rent"]) * 25 + income_for_tile(tile) - cost / 2
		if owns_complete_group(player_id, int(BOARD[tile]["group"])):
			score += 300
		if score > best_score:
			best_score = score
			best_tile = tile
	var threshold := 1200 if difficulty == "easy" else (500 if difficulty == "medium" else 0)
	if best_tile >= 0 and best_score > threshold and (difficulty == "hard" or rng.randf() < (0.35 if difficulty == "easy" else 0.65)):
		var upgrade_result := upgrade_property(player_id, best_tile)
		if bool(upgrade_result.get("ok", false)):
			decisions.append(str(upgrade_result["message"]))
	if bool(state.get("can_market", false)):
		if not bool(state.get("did_invest", false)):
			var candidates: Array[Dictionary] = []
			for tile in country_tiles():
				if int(state["tile_owners"][tile]) == player_id:
					candidates.append_array(investment_options(player_id, tile))
			candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["income"]) / float(a["cost"]) > float(b["income"]) / float(b["cost"]))
			for option in candidates:
				if int(state["players"][player_id]["balance"]) - int(option["cost"]) < reserve:
					continue
				var ratio := float(option["income"]) / float(option["cost"])
				if ratio < (0.09 if difficulty == "easy" else 0.075):
					continue
				if difficulty == "easy" and rng.randf() > 0.3:
					break
				var invest_result := buy_investment(player_id, str(option["type"]), int(option["tile"]))
				if bool(invest_result.get("ok", false)):
					decisions.append(str(invest_result["message"]))
					break
	return decisions

func owns_sudan(player_id: int) -> bool:
	return _valid_player_id(player_id) and int(state.get("tile_owners", [])[2]) == player_id

func resolve_computer_obligation(player_id: int) -> Array[String]:
	var decisions: Array[String] = []
	if not is_computer_player(player_id) or not _can_act(player_id, ["obligation"]):
		return decisions
	var safety := 0
	while str(state.get("phase", "")) == "obligation" and safety < TILE_COUNT * 3:
		safety += 1
		var investment_index := -1
		var investments: Array = state.get("investments", [])
		for index in range(investments.size()):
			if int(investments[index].get("owner", -1)) == player_id:
				investment_index = index
				break
		if investment_index >= 0:
			var sold: Dictionary = sell_investment(player_id, investment_index)
			if bool(sold.get("ok", false)):
				decisions.append(str(sold.get("message", "")))
				continue
		var developed_tile := -1
		for tile in country_tiles():
			if int(state["tile_owners"][tile]) == player_id and int(state["development"][tile]) > 0:
				developed_tile = tile
				break
		if developed_tile >= 0:
			var reduced: Dictionary = downgrade_property(player_id, developed_tile)
			if bool(reduced.get("ok", false)):
				decisions.append(str(reduced.get("message", "")))
				continue
		var owned_tile := -1
		for tile in country_tiles():
			if int(state["tile_owners"][tile]) == player_id:
				owned_tile = tile
				break
		if owned_tile >= 0:
			var liquidated: Dictionary = sell_property(player_id, owned_tile)
			if bool(liquidated.get("ok", false)):
				decisions.append(str(liquidated.get("message", "")))
				continue
		var bankruptcy: Dictionary = declare_bankruptcy(player_id)
		if bool(bankruptcy.get("ok", false)):
			decisions.append(str(bankruptcy.get("message", "")))
		break
	return decisions

func pending_obligation() -> Dictionary:
	return (state.get("pending_obligation", {}) as Dictionary).duplicate(true)

func sell_property(player_id: int, tile_index: int) -> Dictionary:
	if not _can_act(player_id) and not _can_act(player_id, ["obligation"]):
		return _failure("لا يمكن بيع الدولة في هذه المرحلة.")
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country" or int(state["tile_owners"][tile_index]) != player_id:
		return _failure("لا تملك هذه الدولة.")
	var base_refund := int(BOARD[tile_index]["price"]) / 2
	var level := int(state["development"][tile_index])
	var upgrade_refund := 0
	for i in range(level):
		upgrade_refund += int(DEV_COSTS[i]) / 2
	var removed_investment_refund := 0
	var investments: Array = state.get("investments", [])
	for i in range(investments.size() - 1, -1, -1):
		if int(investments[i].get("owner", -1)) == player_id and int(investments[i].get("tile", -1)) == tile_index:
			removed_investment_refund += int(investments[i].get("cost", 0)) / 2
			investments.remove_at(i)
	state["investments"] = investments
	state["tile_owners"][tile_index] = -1
	state["development"][tile_index] = 0
	var refund := base_refund + upgrade_refund + removed_investment_refund
	_credit(player_id, refund, "بيع " + str(BOARD[tile_index]["name"]) + " (استرداد 50% للأصل والتطوير والاستثمار)", -1, "asset_sale")
	_add_log("تمت إزالة الملكية والتطوير والاستثمارات المرتبطة بالدولة بعد البيع.")
	_try_settle_obligation(player_id)
	return {"ok": true, "refund": refund, "message": "بيع %s أعاد %s وفق قاعدة استرداد 50 بالمئة." % [str(BOARD[tile_index]["name"]), _cash(refund)]}

func downgrade_property(player_id: int, tile_index: int) -> Dictionary:
	if not _can_act(player_id) and not _can_act(player_id, ["obligation"]):
		return _failure("لا يمكن خفض التطوير الآن.")
	if not _valid_tile(tile_index) or int(state["tile_owners"][tile_index]) != player_id or int(state["development"][tile_index]) <= 0:
		return _failure("لا يوجد تطوير مملوك يمكن خفضه.")
	var old_level := int(state["development"][tile_index])
	var refund := int(DEV_COSTS[old_level - 1] * 0.25)
	state["development"][tile_index] = old_level - 1
	_credit(player_id, refund, "خفض تطوير " + str(BOARD[tile_index]["name"]) + " (استرداد 25%)", -1, "asset_sale")
	_try_settle_obligation(player_id)
	return {"ok": true, "refund": refund, "message": "خُفض التطوير واستُرد %s (25 بالمئة من تكلفة المستوى)." % _cash(refund)}

func _try_settle_obligation(player_id: int) -> bool:
	var obligation: Dictionary = state.get("pending_obligation", {})
	if obligation.is_empty() or int(obligation.get("debtor", -1)) != player_id:
		return false
	var amount := int(obligation.get("amount", 0))
	if int(state["players"][player_id]["balance"]) < amount:
		return false
	var reason := str(obligation.get("reason", "التزام"))
	var recipient := int(obligation.get("recipient", -1))
	var category := str(obligation.get("category", "expense"))
	state["pending_obligation"] = {}
	state["phase"] = "actions"
	state["busy"] = false
	_commit_payment(player_id, amount, reason, recipient, category)
	state["last_message"] = "سُدد الالتزام %s بعد التصفية." % reason
	_add_log(str(state["last_message"]))
	return true

func declare_bankruptcy(player_id: int) -> Dictionary:
	if not _can_act(player_id, ["obligation"]):
		return _failure("لا توجد حالة عجز معلقة لإعلان الإفلاس.")
	var obligation: Dictionary = state.get("pending_obligation", {})
	if obligation.is_empty() or int(obligation.get("debtor", -1)) != player_id:
		return _failure("بيانات الالتزام غير صالحة.")
	if _has_liquidatable_assets(player_id):
		return _failure("ما زالت لديك أصول قابلة للبيع؛ صفِّها قبل الإفلاس.")
	var due := int(obligation.get("amount", 0))
	var player: Dictionary = state["players"][player_id]
	var available := int(player["balance"])
	var creditor := int(obligation.get("recipient", -1))
	if available > 0:
		var reason := str(obligation.get("reason", "التزام"))
		player["balance"] = 0
		_record_transaction(player_id, -available, reason + " (سداد جزئي عند الإفلاس)", creditor, str(obligation.get("category", "expense")))
		if creditor >= 0 and creditor != player_id:
			var receiver: Dictionary = state["players"][creditor]
			receiver["balance"] = int(receiver["balance"]) + available
			_record_transaction(creditor, available, reason + " (سداد جزئي عند الإفلاس)", player_id, "transfer_in")
	player["debt"] = int(player.get("debt", 0)) + maxi(0, due - available)
	var property_transfers: Array[int] = []
	for tile in country_tiles():
		if int(state["tile_owners"][tile]) == player_id:
			property_transfers.append(tile)
			state["tile_owners"][tile] = creditor if creditor >= 0 and creditor != player_id else -1
			state["development"][tile] = 0
	var investments: Array = state.get("investments", [])
	for i in range(investments.size() - 1, -1, -1):
		if int(investments[i].get("owner", -1)) == player_id:
			if creditor >= 0 and creditor != player_id:
				investments[i]["owner"] = creditor
			else:
				investments.remove_at(i)
	state["investments"] = investments
	player["balance"] = 0
	player["alive"] = false
	state["pending_obligation"] = {}
	state["phase"] = "actions"
	state["busy"] = false
	var message := "أُعلن إفلاس %s بسبب %s. نُقلت %d دولة إلى الدائن أو أعيدت للبنك؛ سُجل الدين المتبقي %s." % [str(player["name"]), str(obligation.get("reason", "التزام")), property_transfers.size(), _cash(int(player["debt"]))]
	_add_log(message)
	state["last_message"] = message
	if _alive_count() <= 1:
		_finish_match("لم يبقَ سوى لاعب واحد بعد الإفلاس.")
	else:
		var next_player := _next_alive_player(player_id)
		state["turn_number"] = int(state.get("turn_number", 1)) + 1
		if next_player <= player_id:
			state["round_number"] = int(state.get("round_number", 1)) + 1
		state["turn"] = next_player
		state["phase"] = "await_roll"
		state["can_market"] = false
		state["did_develop"] = false
		state["did_invest"] = false
		if int(state["round_number"]) > int(state["round_limit"]):
			_finish_match("اكتمل حد الجولات (%d)." % int(state["round_limit"]))
	return {"ok": true, "message": message, "transferred_properties": property_transfers, "game_over": not bool(state["active"])}

func _has_liquidatable_assets(player_id: int) -> bool:
	for tile in country_tiles():
		if int(state["tile_owners"][tile]) == player_id:
			return true
	for investment in state.get("investments", []):
		if int(investment.get("owner", -1)) == player_id:
			return true
	return false

func _alive_count() -> int:
	var count := 0
	for player in state.get("players", []):
		if bool(player.get("alive", true)):
			count += 1
	return count

func propose_trade(player_id: int, target_id: int, give_tile: int = -1, ask_tile: int = -1, give_cash: int = 0, ask_cash: int = 0) -> Dictionary:
	if not _can_act(player_id):
		return _failure("الصفقة متاحة خلال مرحلة الإجراءات فقط.")
	if target_id < 0 or target_id >= state["players"].size() or target_id == player_id or not _is_alive(target_id):
		return _failure("الطرف الآخر غير صالح.")
	if give_cash < 0 or ask_cash < 0:
		return _failure("المبالغ لا يمكن أن تكون سالبة.")
	if give_cash > int(state["players"][player_id]["balance"]) or ask_cash > int(state["players"][target_id]["balance"]):
		return _failure("أحد الطرفين لا يملك الرصيد الكافي.")
	if give_tile >= 0 and (not _valid_tile(give_tile) or int(state["tile_owners"][give_tile]) != player_id):
		return _failure("الدولة التي تعرضها ليست ملكك.")
	if ask_tile >= 0 and (not _valid_tile(ask_tile) or int(state["tile_owners"][ask_tile]) != target_id):
		return _failure("الدولة المطلوبة ليست ملك الطرف الآخر.")
	if give_tile < 0 and ask_tile < 0 and give_cash == 0 and ask_cash == 0:
		return _failure("الصفقة لا تتضمن أصولًا أو مبالغ.")
	var offer := {"from": player_id, "to": target_id, "give_tile": give_tile, "ask_tile": ask_tile, "give_cash": give_cash, "ask_cash": ask_cash}
	if is_computer_player(target_id):
		var accepted := computer_accepts_trade(target_id, offer)
		if accepted:
			var result := _execute_trade(offer)
			result["message"] = "وافق الكمبيوتر على الصفقة بعد مقارنة القيمة والسيولة. " + str(result.get("message", ""))
			return result
		return {"ok": true, "accepted": false, "message": "رفض الكمبيوتر الصفقة؛ قيمة ما سيحصل عليه لا تبرر ما سيدفعه."}
	state["pending_trade"] = offer
	state["phase"] = "trade"
	state["busy"] = true
	return {"ok": true, "pending": true, "message": "عُرضت الصفقة على %s للموافقة أو الرفض." % str(state["players"][target_id]["name"])}

func respond_to_trade(target_id: int, accept: bool) -> Dictionary:
	if str(state.get("phase", "")) != "trade":
		return _failure("لا توجد صفقة بانتظار الرد.")
	var offer: Dictionary = state.get("pending_trade", {})
	if offer.is_empty() or int(offer.get("to", -1)) != target_id:
		return _failure("هذا اللاعب ليس الطرف المطلوب في الصفقة.")
	state["pending_trade"] = {}
	state["phase"] = "actions"
	state["busy"] = false
	if not accept:
		return {"ok": true, "accepted": false, "message": "رُفضت الصفقة؛ لم تتغير الأرصدة أو الملكيات."}
	return _execute_trade(offer)

func computer_accepts_trade(computer_id: int, offer: Dictionary) -> bool:
	if not is_computer_player(computer_id):
		return false
	var incoming := _trade_asset_value(int(offer.get("give_tile", -1))) + int(offer.get("give_cash", 0))
	var outgoing := _trade_asset_value(int(offer.get("ask_tile", -1))) + int(offer.get("ask_cash", 0))
	var difficulty := str(state["players"][computer_id].get("difficulty", "medium"))
	var tolerance := 1.1 if difficulty == "easy" else (0.94 if difficulty == "medium" else 0.86)
	var target_tile := int(offer.get("ask_tile", -1))
	if target_tile >= 0 and owns_complete_group(computer_id, int(BOARD[target_tile]["group"])):
		outgoing *= 1.18
	return incoming >= outgoing * tolerance

func _trade_asset_value(tile_index: int) -> int:
	if not _valid_tile(tile_index) or str(BOARD[tile_index]["type"]) != "country":
		return 0
	return int(BOARD[tile_index]["price"]) + int(DEV_COSTS[0]) * int(state["development"][tile_index]) / 2

func _execute_trade(offer: Dictionary) -> Dictionary:
	var giver := int(offer["from"])
	var receiver := int(offer["to"])
	var give_tile := int(offer.get("give_tile", -1))
	var ask_tile := int(offer.get("ask_tile", -1))
	var give_cash := int(offer.get("give_cash", 0))
	var ask_cash := int(offer.get("ask_cash", 0))
	if give_cash > int(state["players"][giver]["balance"]) or ask_cash > int(state["players"][receiver]["balance"]):
		return _failure("تغير الرصيد؛ لم تنفذ الصفقة.")
	if give_tile >= 0 and int(state["tile_owners"][give_tile]) != giver:
		return _failure("تغيرت ملكية الدولة؛ لم تنفذ الصفقة.")
	if ask_tile >= 0 and int(state["tile_owners"][ask_tile]) != receiver:
		return _failure("تغيرت ملكية الدولة؛ لم تنفذ الصفقة.")
	if give_tile >= 0:
		_transfer_tile_bundle(give_tile, receiver)
	if ask_tile >= 0:
		_transfer_tile_bundle(ask_tile, giver)
	if give_cash > 0:
		_commit_payment(giver, give_cash, "نقد ضمن صفقة", receiver, "trade")
	if ask_cash > 0:
		_commit_payment(receiver, ask_cash, "نقد مقابل صفقة", giver, "trade")
	var message := "اكتملت صفقة بين %s و%s؛ نُقلت الدول والمبالغ المتفق عليها." % [str(state["players"][giver]["name"]), str(state["players"][receiver]["name"])]
	_add_log(message)
	state["last_message"] = message
	return {"ok": true, "accepted": true, "message": message}

func _transfer_tile_bundle(tile_index: int, new_owner: int) -> void:
	var old_owner := int(state["tile_owners"][tile_index])
	state["tile_owners"][tile_index] = new_owner
	var investments: Array = state.get("investments", [])
	for index in range(investments.size()):
		if int(investments[index].get("tile", -1)) == tile_index and int(investments[index].get("owner", -1)) == old_owner:
			investments[index]["owner"] = new_owner
	state["investments"] = investments

func get_net_worth(player_id: int) -> Dictionary:
	if not _valid_player_id(player_id):
		return {}
	var cash := int(state["players"][player_id]["balance"])
	var property_value := 0
	var development_value := 0
	var investment_value := 0
	for tile in country_tiles():
		if int(state["tile_owners"][tile]) == player_id:
			property_value += int(BOARD[tile]["price"]) / 2
			var level := int(state["development"][tile])
			for i in range(level):
				development_value += int(DEV_COSTS[i]) / 2
	for investment in state.get("investments", []):
		if int(investment.get("owner", -1)) == player_id:
			investment_value += int(investment.get("cost", 0)) / 2
	var debt := int(state["players"][player_id].get("debt", 0))
	var net := cash + property_value + development_value + investment_value - debt
	return {"cash": cash, "property_value": property_value, "development_value": development_value,
		"investment_value": investment_value, "debt": debt, "net_worth": net}

func _finish_match(reason: String) -> void:
	if not bool(state.get("active", false)):
		return
	state["active"] = false
	state["phase"] = "finished"
	state["busy"] = false
	var winner := -1
	var best := -9223372036854775807
	var summaries: Array[Dictionary] = []
	for player_id in range(state.get("players", []).size()):
		if not _is_alive(player_id):
			continue
		var summary := get_net_worth(player_id)
		summary["player"] = player_id
		summaries.append(summary)
		if int(summary["net_worth"]) > best:
			best = int(summary["net_worth"])
			winner = player_id
	state["winner_id"] = winner
	state["result"] = {"reason": reason, "winner_id": winner, "players": summaries}
	state["last_message"] = reason + (" الفائز: %s." % str(state["players"][winner]["name"]) if winner >= 0 else " لا يوجد لاعب ناجٍ.")
	_add_log(str(state["last_message"]))

func finish_match_by_user(player_id: int) -> Dictionary:
	if not _can_act(player_id, ["actions"]):
		return _failure("لا يمكن إنهاء المباراة مع إجراء معلق.")
	_finish_match("أنهى اللاعب المباراة يدويًا بعد التأكيد.")
	return {"ok": true, "result": state["result"], "message": state["last_message"]}

func get_balance(player_id: int) -> int:
	if not _valid_player_id(player_id):
		return 0
	return int(state["players"][player_id]["balance"])

func count_owned_properties(player_id: int) -> int:
	if not _valid_player_id(player_id):
		return 0
	var count := 0
	for tile in country_tiles():
		if int(state["tile_owners"][tile]) == player_id:
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
	if parser.parse(raw) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "corrupt": true, "message": "ملف الحفظ تالف أو غير مكتمل."}
	var payload: Dictionary = parser.data
	var version := int(payload.get("version", -1))
	if version not in [1, 2, SAVE_VERSION] or typeof(payload.get("state", null)) != TYPE_DICTIONARY:
		return {"ok": false, "corrupt": true, "message": "إصدار أو بنية ملف الحفظ غير صالحة."}
	var candidate: Dictionary = payload["state"].duplicate(true)
	var migrated := version != SAVE_VERSION
	if version == 1:
		candidate = _migrate_v1_state(candidate)
	elif version == 2:
		candidate = _migrate_v2_state(candidate)
	if not validate_state(candidate):
		return {"ok": false, "corrupt": true, "message": "بيانات المباراة المحفوظة غير متوافقة أو تالفة."}
	state = candidate.duplicate(true)
	rng.randomize()
	return {"ok": true, "migrated": migrated, "message": "تم استرجاع المباراة المحفوظة."}

func _migrate_v1_state(old_state: Dictionary) -> Dictionary:
	var players: Variant = old_state.get("players", null)
	if typeof(players) != TYPE_ARRAY or players.size() != 2:
		return {}
	var names: Array = []
	for person in players:
		if typeof(person) != TYPE_DICTIONARY:
			return {}
		names.append(str(person.get("name", "لاعب")))
	var migrated_game = get_script().new()
	migrated_game.new_game(str(names[0]), MODE_COMPUTER)
	for i in range(2):
		migrated_game.state["players"][i]["balance"] = maxi(0, int(players[i].get("balance", STARTING_CASH)))
		migrated_game.state["players"][i]["position"] = posmod(int(players[i].get("position", 0)) * TILE_COUNT / 12, TILE_COUNT)
	migrated_game.state["turn"] = clampi(int(old_state.get("turn", 0)), 0, 1)
	return migrated_game.state

func _migrate_v2_state(old_state: Dictionary) -> Dictionary:
	var old_players: Variant = old_state.get("players", null)
	if typeof(old_players) != TYPE_ARRAY or old_players.size() < 2 or old_players.size() > MAX_LOCAL_PLAYERS:
		return {}
	var old_mode := str(old_state.get("mode", MODE_COMPUTER))
	var names: Array = []
	for player in old_players:
		if typeof(player) != TYPE_DICTIONARY:
			return {}
		names.append(str(player.get("name", "لاعب")))
	var migrated_game = get_script().new()
	migrated_game.new_game(str(names[0]), old_mode, names)
	for i in range(old_players.size()):
		migrated_game.state["players"][i]["balance"] = maxi(0, int(old_players[i].get("balance", STARTING_CASH)))
		migrated_game.state["players"][i]["position"] = posmod(int(old_players[i].get("position", 0)) * TILE_COUNT / 12, TILE_COUNT)
		migrated_game.state["players"][i]["completed_laps"] = int(old_players[i].get("completed_laps", 0))
		migrated_game.state["players"][i]["steps_moved"] = int(old_players[i].get("steps_moved", 0))
	var old_owners: Variant = old_state.get("tile_owners", [])
	if typeof(old_owners) == TYPE_ARRAY:
		for old_index in range(mini(old_owners.size(), 12)):
			if int(old_owners[old_index]) < 0 or int(old_owners[old_index]) >= old_players.size():
				continue
			var old_name := str(BOARD_OLD_NAME(old_index))
			var new_index := _find_country_by_name(old_name)
			if new_index >= 0:
				migrated_game.state["tile_owners"][new_index] = int(old_owners[old_index])
			else:
				var owner_id := int(old_owners[old_index])
				var old_price := _legacy_price(old_name)
				migrated_game.state["players"][owner_id]["balance"] = int(migrated_game.state["players"][owner_id]["balance"]) + old_price / 2
	migrated_game.state["turn"] = clampi(int(old_state.get("turn", 0)), 0, old_players.size() - 1)
	migrated_game.state["turn_number"] = maxi(1, int(old_state.get("turn_number", 1)))
	migrated_game.state["phase"] = "await_roll"
	migrated_game.state["log"] = ["رُحّلت مباراة قديمة إلى لوحة 40 خانة؛ الدول غير الموجودة حُولت إلى 50% من سعرها نقدًا."]
	return migrated_game.state

static func BOARD_OLD_NAME(index: int) -> String:
	var old_names := ["البداية", "مصر", "مفاجأة", "السعودية", "الإمارات", "الضريبة", "المغرب", "مكافأة", "مفاجأة", "الأردن", "العراق", "راحة"]
	return str(old_names[index]) if index >= 0 and index < old_names.size() else ""

static func _legacy_price(name: String) -> int:
	match name:
		"الأردن": return 2000
		"العراق": return 2500
	return 0

func _find_country_by_name(name: String) -> int:
	for tile in BOARD:
		if str(tile.get("name", "")) == name and str(tile.get("type", "")) == "country":
			return int(tile["id"])
	return -1

static func validate_state(candidate: Dictionary) -> bool:
	if typeof(candidate) != TYPE_DICTIONARY:
		return false
	var mode := str(candidate.get("mode", ""))
	if mode not in [MODE_COMPUTER, MODE_LOCAL]:
		return false
	var players: Variant = candidate.get("players", null)
	var owners: Variant = candidate.get("tile_owners", null)
	var development: Variant = candidate.get("development", null)
	if typeof(players) != TYPE_ARRAY or players.size() < 2 or players.size() > MAX_LOCAL_PLAYERS:
		return false
	if mode == MODE_COMPUTER and players.size() != 2:
		return false
	if typeof(owners) != TYPE_ARRAY or owners.size() != TILE_COUNT or typeof(development) != TYPE_ARRAY or development.size() != TILE_COUNT:
		return false
	for i in range(players.size()):
		if typeof(players[i]) != TYPE_DICTIONARY:
			return false
		var person: Dictionary = players[i]
		for key in ["id", "name", "controller", "balance", "position", "completed_laps", "steps_moved", "alive", "debt"]:
			if not person.has(key):
				return false
		if int(person["id"]) != i or typeof(person["name"]) != TYPE_STRING or str(person["name"]).strip_edges().is_empty():
			return false
		if str(person["controller"]) not in ["human", "computer"]:
			return false
		if mode == MODE_LOCAL and str(person["controller"]) != "human":
			return false
		if mode == MODE_COMPUTER and str(person["controller"]) != ("human" if i == 0 else "computer"):
			return false
		if int(person["balance"]) < 0 or int(person["position"]) < 0 or int(person["position"]) >= TILE_COUNT or int(person["debt"]) < 0:
			return false
		if typeof(person["alive"]) != TYPE_BOOL:
			return false
	for i in range(TILE_COUNT):
		if int(owners[i]) < -1 or int(owners[i]) >= players.size() or int(development[i]) < 0 or int(development[i]) > 3:
			return false
		if str(BOARD[i]["type"]) != "country" and (int(owners[i]) != -1 or int(development[i]) != 0):
			return false
	var phase := str(candidate.get("phase", ""))
	if phase not in ["await_roll", "pending_purchase", "obligation", "trade", "actions", "finished"]:
		return false
	var turn_value: Variant = candidate.get("turn", -1)
	if typeof(turn_value) not in [TYPE_INT, TYPE_FLOAT] or not is_equal_approx(float(turn_value), float(int(turn_value))) or int(turn_value) < 0 or int(turn_value) >= players.size():
		return false
	if not candidate.get("active", false) is bool or not candidate.get("busy", false) is bool:
		return false
	if bool(candidate["active"]) and phase == "finished":
		return false
	if not bool(candidate["active"]) and phase != "finished":
		return false
	if int(candidate.get("pending_property", -1)) >= 0:
		var pending := int(candidate["pending_property"])
		if phase != "pending_purchase" or pending >= TILE_COUNT or str(BOARD[pending]["type"]) != "country" or int(owners[pending]) != -1:
			return false
	if phase == "pending_purchase" and int(candidate.get("pending_property", -1)) < 0:
		return false
	if typeof(candidate.get("investments", null)) != TYPE_ARRAY or typeof(candidate.get("ledger", null)) != TYPE_ARRAY or typeof(candidate.get("log", null)) != TYPE_ARRAY:
		return false
	if typeof(candidate.get("event_deck", null)) != TYPE_ARRAY or typeof(candidate.get("event_discard", null)) != TYPE_ARRAY:
		return false
	for investment in candidate["investments"]:
		if typeof(investment) != TYPE_DICTIONARY or not _valid_saved_investment(investment, players.size(), owners):
			return false
	return true

static func _valid_saved_investment(investment: Dictionary, player_count: int, owners: Array) -> bool:
	var tile := int(investment.get("tile", -1))
	var owner := int(investment.get("owner", -1))
	return INVESTMENT_DATA.has(str(investment.get("type", ""))) and tile >= 0 and tile < TILE_COUNT and str(BOARD[tile]["type"]) == "country" and owner >= 0 and owner < player_count and int(owners[tile]) == owner and int(investment.get("cost", -1)) >= 0 and int(investment.get("income", -1)) >= 0

func _valid_tile(tile_index: int) -> bool:
	return tile_index >= 0 and tile_index < TILE_COUNT

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

func _add_log(message: String) -> void:
	if state.is_empty():
		return
	var history: Array = state.get("log", [])
	history.append(message)
	while history.size() > 24:
		history.pop_front()
	state["log"] = history

static func _cash(value: int) -> String:
	var raw := str(absi(value))
	var formatted := ""
	var group_size := 0
	for index in range(raw.length() - 1, -1, -1):
		formatted = raw.substr(index, 1) + formatted
		group_size += 1
		if group_size == 3 and index > 0:
			formatted = "," + formatted
			group_size = 0
	return ("-" if value < 0 else "") + formatted
