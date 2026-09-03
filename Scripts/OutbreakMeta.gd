extends Node

const SCENARIOS := {
	0: "Outbreak",
	1: "Below Freezing Point",
	2: "The Hive",
	3: "Hellfire",
	4: "Decisions, Decisions"
}

const DIFFICULTIES := {
	0: "DIFFICULTY_EASY",
	1: "DIFFICULTY_NORMAL",
	2: "DIFFICULTY_HARD",
	3: "DIFFICULTY_VERY_HARD"
}

const DIFFICULTY_COLORS := {
	0: Color(0.608, 0.95, 0.665),
	1: Color(0.608, 0.939, 0.95),
	2: Color(0.95, 0.796, 0.608),
	3: Color(0.95, 0.608, 0.608)
}

const RANKS := {
	0: "Z",
	1: "E",
	2: "D",
	3: "C",
	4: "B",
	5: "A",
	6: "S"
}

const RANK_COLORS := {
	0: Color(0.95, 0.608, 0.608),
	1: Color(0.95, 0.608, 0.608),
	2: Color(0.95, 0.608, 0.608),
	3: Color(0.95, 0.796, 0.608),
	4: Color(0.608, 0.939, 0.95),
	5: Color(0.608, 0.95, 0.665),
	6: Color(0.95, 0.86, 0.4)
}

const CHARACTERS := {
	0: "KEVIN", 1: "KEVIN:B", 2: "MARK", 3: "MARK:B", 4: "JIM", 5: "JIM:B",
	6: "GEORGE", 7: "GEORGE:B", 8: "DAVID", 9: "DAVID:B", 10: "ALYSSA",
	11: "ALYSSA:B", 12: "ALYSSA:C", 13: "YOKO", 14: "YOKO:B", 15: "YOKO:C",
	16: "CINDY", 17: "CINDY:B", 18: "CINDY:C", 19: "MACDOWELL", 20: "RODRIGUEZ",
	21: "CONRAD", 22: "HUNK:B", 23: "HUNK", 24: "MIGUEL", 25: "LUKE", 26: "ARNOLD",
	27: "MATT", 28: "BILLY", 29: "HARSH", 30: "PETER", 31: "MARVIN", 32: "FRED",
	33: "ANDY", 34: "JEAN", 35: "TONY", 36: "PATRICK", 37: "LLOYD", 38: "AUSTIN",
	39: "CLINT", 40: "BONE", 41: "BOB", 42: "NATHAN", 43: "SAMUEL", 44: "WILL",
	45: "ROGER", 46: "CARTER", 47: "GREG", 48: "FROST", 49: "FROST:B", 50: "JAKE",
	51: "GARY", 52: "RICHARD", 53: "MICKEY", 54: "AL", 55: "AXEMAN", 56: "AL:B",
	57: "BEN", 58: "REGAN", 59: "REGAN:B", 60: "MONICA", 61: "LINDA", 62: "RITA",
	63: "MARY", 64: "KATE", 65: "DANNY", 66: "DANNY:B", 67: "GILL", 68: "GILL:B",
	69: "KEITH", 70: "KURT", 71: "KURT:B", 72: "GARY:B", 73: "AL:C", 74: "DOROTHY",
	75: "YOKO:Z", 76: "RAYMOND", 77: "ARTHUR", 78: "AARON", 79: "DORIAN",
	80: "ELLIOTT", 81: "ERIC", 82: "HARRY", 83: "KARL", 84: "DUSTIN", 85: "DEREK",
	86: "LEN", 87: "NICOLAS", 88: "SEAN", 89: "PHILIP", 90: "DON", 91: "MATTHEW",
	92: "ROBERT", 93: "CHUCK", 94: "GINGER", 95: "LAURA", 96: "AMELIA", 97: "ETHAN",
	98: "HOWARD", 99: "ISAAC", 100: "KATHY", 101: "ELENA", 102: "FRANK",
	103: "RODNEY", 104: "Mr. RED", 105: "Mr. BLUE", 106: "Mr. GREEN",
	107: "Mr. GOLD", 108: "Mr. BLACK"
}

func scenario_name(id: int) -> String:
	return SCENARIOS.get(id, "?")

func difficulty_name(id: int) -> String:
	if not DIFFICULTIES.has(id):
		return "?"
	return tr(DIFFICULTIES[id])

func difficulty_color(id: int) -> Color:
	return DIFFICULTY_COLORS.get(id, Color.WHITE)

func rank_name(id: int) -> String:
	return RANKS.get(id, "?")

func rank_color(id: int) -> Color:
	return RANK_COLORS.get(id, Color.WHITE)

func character_name(id: int) -> String:
	var full : String = CHARACTERS.get(id, "?")
	return full.split(":")[0].capitalize()

func character_costume(id: int) -> String:
	var full : String = CHARACTERS.get(id, "")
	var parts := full.split(":")
	if parts.size() < 2:
		return "A"
	return parts[1]