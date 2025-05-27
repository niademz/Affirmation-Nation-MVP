extends Node

var schedules = {
	"Alice": [
		{ "type": "GOTO", "start": 900, "end": 1200, "spot": "ShopSpot" },
		{ "type": "GOTO", "start": 1200, "end": 1800, "spot": "Well" },
		{ "type": "GOTO", "start": 1800, "end": 2200, "spot": "Statue" },
		{ "type": "SLEEP", "start": 2200, "end": 600, "spot": "AliceBed" }
	],
	"Ben": [
		{ "type": "GOTO", "start": 1000, "end": 1300, "spot": "Well" },
		{ "type": "GOTO", "start": 1300, "end": 1900, "spot": "Statue" },
		{ "type": "GOTO", "start": 1900, "end": 2230, "spot": "ShopSpot" },
		{ "type": "SLEEP", "start": 2230, "end": 600, "spot": "AliceBed" }
	]
}

var villagers = {
	"Alice": {
		"name": "Alice",

		"personality_traits": {
			"cheerful": 0.9,
			"hermit": 0.1,
			"caretaker": 0.4,
			"wanderer": 0.5,
			"planner": 0.6,
			"tinkerer": 0.2
		},

		"mood": {
			"emotions": {
				"joy": 0.6,
				"sadness": 0.1,
				"anger": 0.0,
				"boredom": 0.2,
				"fear": 0.0
			},
			"social_meter": 0.5,
			"trust_safe": 0.2,
		},

		"preferences": {
			"likes_items": ["Apples", "Books", "Tea"],
			"likes_places": ["Well", "Nature", "Garden"]
		},

		"schedule": [
			{ "type": "GOTO", "start": 900, "end": 1200, "spot": "ShopSpot" },
			{ "type": "GOTO", "start": 1200, "end": 1800, "spot": "Well" },
			{ "type": "GOTO", "start": 1800, "end": 2200, "spot": "Statue" },
			{ "type": "SLEEP", "start": 2200, "end": 600, "spot": "AliceBed" }
		],

		"ownership": {
			"home": "small_house_23",
			"places": []
		},

		"friends": [],

		"job": null,

		"memory": [],
		"plans": []
	},
	"Ben": {
	"name": "Ben",

	"personality_traits": {
		"cheerful": 0.2,
		"hermit": 0.3,
		"caretaker": 0.2,
		"wanderer": 0.2,
		"planner": 0.9,
		"tinkerer": 0.8
	},

	"mood": {
		"emotions": {
			"joy": 0.5,
			"sadness": 0.2,
			"anger": 0.0,
			"boredom": 0.3,
			"fear": 0.0
		},
		"social_meter": 0.3,
		"trust_safe": 0.1,
	},

	"preferences": {
		"likes_items": ["Books", "Tools", "Tea"],
		"likes_places": ["Garden", "Statue"]
	},

	"schedule": schedules["Ben"],

	"ownership": {
		"home": "small_tavern_19",
		"places": []
	},

	"friends": [],

	"job": null,

	"memory": [],
	"plans": []
	}
}

var astar = AStar2D.new()
var cell_size = 16
var sleep_steps_to_home = {}

func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func build_grid(tile_map: TileMap):
	var astar = VillagerManager.astar
	astar.clear()
	
	var ground_layer = 1
	var block_layers = [2,3]
	
	var used_cells = tile_map.get_used_cells(ground_layer)
	var tile_size = Vector2(tile_map.tile_set.tile_size)
	var buffer_radius = 1
	
	for cell in used_cells:
		var is_blocked = false
		
		for layer in block_layers:
			var tile_data = tile_map.get_cell_tile_data(layer, cell)
			if tile_data == null:
				continue
			if tile_data.get_custom_data("walkable") == false:
				is_blocked = true
			if tile_data.get_collision_polygons_count(0) > 0:
				is_blocked = true
		
		if is_blocked:
			#for x_offset in range(-buffer_radius, buffer_radius + 1):
				#for y_offset in range(-buffer_radius, buffer_radius + 1):
					#var offset_cell = cell + Vector2i(x_offset, y_offset)
					#var id = hash(offset_cell)
					#astar.set_point_disabled(id, true)
			continue
		
		var id = hash(cell)
		var world_pos = tile_map.map_to_local(cell) + tile_size / 2.0
		astar.add_point(id, world_pos)
	
	for cell in used_cells:
		var from_id = hash(cell)
		var neighbors = [
			cell + Vector2i(0, -1),
			cell + Vector2i(0, 1),
			cell + Vector2i(-1, 0),
			cell + Vector2i(1, 0)
		]
		for neighbor in neighbors:
			if astar.has_point(hash(cell)) and astar.has_point(hash(neighbor)):
				astar.connect_points(from_id, hash(neighbor),false)
	#print("Astar Point Count:", astar.get_point_count())

func block_tile(cell: Vector2i):
	var id = hash(cell)
	if astar.has_point(id):
		astar.set_point_disabled(id, true)
	else:
		pass

func unblock_tile(cell: Vector2i):
	var id = hash(cell)
	if astar.has_point(id):
		astar.set_point_disabled(id, false)
	else:
		pass

func _on_time_tick(day:int, hour:int, minute:int):
	if minute == 0:
		for villager in get_tree().get_nodes_in_group("Villagers"):
			villager.check_schedule(hour)
	if minute == 0:
		print("Hour:", Global.current_hour)
		
		var names = villagers.keys()
		for name in names:
			var data = villagers[name]
			var updated = Mind.process_villager(name, data)
			villagers[name] = updated
		for i in range(names.size()):
			for j in range(i+1, names.size()):
				var name1 = names[i]
				var name2 = names[j]
				
				var v1 = villagers[name1]
				var v2 = villagers[name2]
				
				if !Mind.is_villager_sleeping(v1) and !Mind.is_villager_sleeping(v2):
					if randf() < 0.3:
						Mind.attempt_social_interaction(name1, name2)

func get_astar_distance(from_pos: Vector2, to_pos: Vector2):
	var tilemap = get_tree().current_scene.get_node_or_null("TileMap")
	if tilemap == null:
		return -1
	var from_cell = tilemap.local_to_map(from_pos)
	var to_cell = tilemap.local_to_map(to_pos)
	
	var from_id = hash(from_cell)
	var to_id = hash(to_cell)
	
	if !astar.has_point(from_id) or !astar.has_point(to_id):
		return -1
	
	var path = astar.get_id_path(from_id, to_id)
	return path.size()
