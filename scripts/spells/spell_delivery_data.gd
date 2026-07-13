class_name SpellDeliveryData
extends RefCounted

const DELIVERIES := {
	"simple_projectile": {
		"id": "simple_projectile",
		"display_name": "Projetil Simples",
		"description": "Dispara automaticamente contra o inimigo mais proximo.",
		"available": true,
		"tags": ["automatico", "alvo unico"],
	},
	"chain_lightning": {
		"id": "chain_lightning",
		"display_name": "Cadeia de Raio",
		"description": "Atinge ate 3 alvos proximos; dano cai a cada salto. Forte contra grupos.",
		"available": true,
		"tags": ["cadeia", "grupos"],
	},
	"area": {
		"id": "area",
		"display_name": "Area de Acao",
		"description": "Cria uma zona temporaria com dano periodico. Forte contra grupos lentos.",
		"available": true,
		"tags": ["area", "controle"],
	},
	"slash": {
		"id": "slash",
		"display_name": "Slash",
		"description": "Atinge instantaneamente o inimigo mais proximo.",
		"available": false,
		"tags": ["futuro", "instantaneo"],
	},
	"persistent_waves": {
		"id": "persistent_waves",
		"display_name": "Ondas Persistentes",
		"description": "Lanca ondas na direcao do alvo.",
		"available": false,
		"tags": ["futuro", "onda"],
	},
	"summon": {
		"id": "summon",
		"display_name": "Evocacao",
		"description": "Cria ecos ou mini clones que atacam por conta propria.",
		"available": false,
		"tags": ["futuro", "eco"],
	},
}


static func get_data(delivery_id: String) -> Dictionary:
	var resolved_id := delivery_id if DELIVERIES.has(delivery_id) else "simple_projectile"
	return DELIVERIES[resolved_id].duplicate(true)


static func get_all() -> Array[Dictionary]:
	var deliveries: Array[Dictionary] = []
	for delivery_id in ["simple_projectile", "chain_lightning", "area", "slash", "persistent_waves", "summon"]:
		deliveries.append(get_data(delivery_id))
	return deliveries
