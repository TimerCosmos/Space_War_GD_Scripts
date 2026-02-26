class_name RarityEnum

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
	GALACTIC
}

static func from_string(name: String) -> int:
	match name.to_lower():
		"common": return Rarity.COMMON
		"rare": return Rarity.RARE
		"epic": return Rarity.EPIC
		"legendary": return Rarity.LEGENDARY
		"galactic": return Rarity.GALACTIC
		_: return Rarity.COMMON

static func get_primary_color(rarity: int) -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.6, 0.6, 0.6)
		Rarity.RARE: return Color(0.2, 0.6, 1.0)
		Rarity.EPIC: return Color(0.7, 0.2, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.5, 0.0)
		Rarity.GALACTIC: return Color(0.0, 1.0, 1.0)
	return Color.WHITE

static func get_glow_color(rarity: int) -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.8, 0.8, 0.8)
		Rarity.RARE: return Color(0.4, 0.8, 1.0)
		Rarity.EPIC: return Color(0.8, 0.0, 1.0) 
		Rarity.LEGENDARY: return Color(1.0, 0.7, 0.2)
		Rarity.GALACTIC: return Color(0.2, 1.0, 1.0)
	return Color.WHITE
