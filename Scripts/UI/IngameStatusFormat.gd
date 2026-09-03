class_name IngameStatusFormat

const LEVEL_NAMES := {
	0: "OUTBREAK",
	1: "BELOW FREEZING POINT",
	2: "THE HIVE",
	3: "HELLFIRE",
	4: "DECISIONS DECISIONS"
}

static func phase_to_index(phase: String) -> int:
	match phase:
		"online": return 0
		"afk": return 1
		"busy": return 2
		"in_game_menu", "lobby", "in_room", "in_game": return 3
		_: return 4

static func status_text(phase: String) -> String:
	match phase:
		"online": return TranslationServer.translate("BADGE_ONLINE")
		"afk": return TranslationServer.translate("BADGE_AFK")
		"busy": return TranslationServer.translate("BADGE_BUSY")
		"in_game_menu", "lobby", "in_room", "in_game": return TranslationServer.translate("BADGE_INGAME")
		_: return TranslationServer.translate("BADGE_OFFLINE")

static func level_name(idx: int) -> String:
	return LEVEL_NAMES.get(idx, "?")

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

static func in_game_status(user: Dictionary, ingame: Dictionary) -> String:
	var phase := str(user.get("phase", ""))
	var area := int(user.get("area", 0))
	var room := int(user.get("room", 0))
	match phase:
		"in_game_menu":
			return TranslationServer.translate("INGAME_MENU")
		"lobby":
			return TranslationServer.translate("INGAME_LOBBY_AREA") % area if area > 0 else TranslationServer.translate("INGAME_LOBBY")
		"in_room":
			if room == 0:
				return TranslationServer.translate("INGAME_LOBBY_AREA") % area
			else:
				return TranslationServer.translate("INGAME_LOBBY_AREA_ROOM") % [area, room]
		"in_game":
			return "%s - %s" % [level_name(int(user.get("level", 0))), format_time(float(ingame.get("time", 0.0)))]
		_:
			return ""

static func infection_text(user: Dictionary, ingame: Dictionary, short: bool = false) -> String:
	if str(user.get("phase", "")) != "in_game":
		return ""
	var prefix := TranslationServer.translate("BADGE_INF_SHORT") if short else TranslationServer.translate("BADGE_INF_LONG")
	return TranslationServer.translate("INGAME_INFECTION") % [prefix, float(ingame.get("infection", 0.0))]