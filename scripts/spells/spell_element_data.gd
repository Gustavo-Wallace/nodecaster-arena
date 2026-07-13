class_name SpellElementData
extends RefCounted

const ELEMENTS := {
	"arcane": {
		"id": "arcane",
		"display_name": "Arcano",
		"description": "Energia pura e direta, sem status adicional.",
		"primary_color": Color(0.77, 0.36, 1.0),
		"secondary_color": Color(1.0, 0.78, 1.0),
		"impact_color": Color(0.96, 0.48, 1.0),
		"effect_id": "direct",
		"effect_power": 0.0,
		"tags": ["direto", "arcano"],
		"modifiers_text": "Dano direto e assinatura magenta.",
	},
	"fire": {
		"id": "fire",
		"display_name": "Fogo",
		"description": "Queima inimigos por um curto periodo apos o impacto.",
		"primary_color": Color(1.0, 0.3, 0.12),
		"secondary_color": Color(1.0, 0.78, 0.22),
		"impact_color": Color(1.0, 0.48, 0.12),
		"effect_id": "burn",
		"effect_power": 0.22,
		"tags": ["dano", "queimadura"],
		"modifiers_text": "Aplica queimadura leve por 1.8s.",
	},
	"ice": {
		"id": "ice",
		"display_name": "Gelo",
		"description": "Resfria inimigos e reduz a velocidade por pouco tempo.",
		"primary_color": Color(0.28, 0.72, 1.0),
		"secondary_color": Color(0.8, 0.98, 1.0),
		"impact_color": Color(0.46, 0.88, 1.0),
		"effect_id": "slow",
		"effect_power": 0.72,
		"tags": ["controle", "lentidao"],
		"modifiers_text": "Reduz a velocidade do alvo por 1.4s.",
	},
	"lightning": {
		"id": "lightning",
		"display_name": "Raio",
		"description": "Favorece a propagacao da Cadeia e acelera os pulsos de Areas.",
		"primary_color": Color(0.36, 0.94, 1.0),
		"secondary_color": Color(1.0, 0.94, 0.34),
		"impact_color": Color(0.72, 1.0, 0.88),
		"effect_id": "direct",
		"effect_power": 0.0,
		"tags": ["direto", "eletrico"],
		"modifiers_text": "+1 salto na Cadeia e -16% intervalo dos pulsos de Area.",
	},
}


static func get_data(element_id: String) -> Dictionary:
	var resolved_id := element_id if ELEMENTS.has(element_id) else "arcane"
	return ELEMENTS[resolved_id].duplicate(true)


static func get_available() -> Array[Dictionary]:
	var elements: Array[Dictionary] = []
	for element_id in ["arcane", "fire", "ice", "lightning"]:
		elements.append(get_data(element_id))
	return elements
