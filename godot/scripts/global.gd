extends Node

@onready var inventory_slot_scene = preload("res://scenes/inventory_slot.tscn")

var current_day = 0
var current_hour = 0
var current_minute = 0
var world_time = -1.0

var player_current_axe = false
var tree_inaxe_range = false
var player_angry = false


var save_path = "user://wood.save"
var player_wood : int
var save_path1 = "user://point.save"
var player_point : int
var player_lvl = 1
var save_path2 = "user://coin.save"
var player_coin : int
var save_path3 = "user://aff1.save"
var save_path4 = "user://aff2.save"
var save_path5 = "user://aff3.save"
var affirmation_1_date : String
var affirmation_2_date : String
var affirmation_3_date : String

var save_path6 = "user://inventory.save"
var inventory = []
var player_node = null

var save_path7 = "user://buildings.save"
var buildings_dropped = []

var town_happiness = 0.5
var streak = 0
var last_affirm_ts = 0
var last_happiness_ts = 0
const HAPPINESS_SAVE = "user://happiness.save"

var current_house_id = ""
var house_layouts := {} 
var return_position : Vector2 = Vector2.ZERO
var villager_home_arrived = {}

var villager_positions = {}
const VILLAGER_POSITIONS_PATH = "user://villager_positions.save"

signal inventory_updated

func _ready():
	inventory.resize(9)
	load_villager_positions()
	load_inventory_data()
	inventory_updated.emit()
	_load_happiness()
	#_decay_happiness()


func _load_happiness():
	if FileAccess.file_exists(HAPPINESS_SAVE):
		var f = FileAccess.open(HAPPINESS_SAVE, FileAccess.READ)
		var d = f.get_var(true)
		print(d)
		town_happiness   = d.get("happiness", 0.5)
		streak           = d.get("streak", 0)
		last_affirm_ts   = d.get("last_affirm_ts", 0)
		last_happiness_ts= d.get("last_happiness_ts", 0)
	else:
		var now = Time.get_unix_time_from_system()
		now = int(now)
		last_happiness_ts = now - (now % 86400)
		last_affirm_ts    = last_happiness_ts
		_save_happiness()

func _decay_happiness():
	var now = Time.get_unix_time_from_system()
	var days = int((now - last_happiness_ts) / 86400)
	if days > 0:
		town_happiness = clamp(town_happiness - 0.02 * days, 0, 1)
		last_happiness_ts += days * 86400
		_save_happiness()


func log_affirmation():
	var now = Time.get_unix_time_from_system()
	now = int(now)
	var day_delta = int((now - last_affirm_ts) / 86400)
	if day_delta >= 1:
		streak = streak + 1 if day_delta == 1 else 1
		last_affirm_ts = now - (now % 86400)
		town_happiness = clamp(town_happiness + 0.1 * streak, 0, 1)
		_save_happiness()

func _save_happiness():
	var f = FileAccess.open(HAPPINESS_SAVE, FileAccess.WRITE)
	f.store_var({
		"happiness": town_happiness,
		"streak":    streak,
		"last_affirm_ts": last_affirm_ts,
		"last_happiness_ts": last_happiness_ts
		})

func _process(delta):
	load_wood_data()
	load_point_data()
	load_coin_data()
	load_aff1_date()
	load_aff2_date()
	load_aff3_date()
	load_inventory_data()
	update_level()

# Function to calculate the points required for the next level
func nextLevel(level: int) -> int:
	return round((4 * (level ** 3)) / 5)


#function to update the time so it is available globally
func update_time(day:int, hour:int, minute:int):
	current_day = day
	current_hour = hour
	current_minute = minute

# Function to update the player's level
func update_level():
	var level = 1
	while player_point >= nextLevel(level):
		level += 1
	player_lvl = level
	return level


func set_player_reference(player):
	player_node = player

func add_item(item):
	for i in range(inventory.size()):
		if inventory[i] != null and  inventory[i]["type"] == item["type"]:
			inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			print("item added", inventory)
			save_inventory()
			return true
		elif inventory[i] == null:
			item["texture_path"] = item["texture"].resource_path
			inventory[i] = item
			inventory_updated.emit()
			print("item added", inventory)
			save_inventory()
			return true
	return false

func remove_item(item_type):
	for i in range(inventory.size()):
		if inventory[i] != null and  inventory[i]["type"] == item_type:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			save_inventory()
			return true
	save_inventory()
	return false

func adjust_drop_position(position):
	var radius = 100
	var nearby_items = get_tree().get_nodes_in_group("Items")
	for item in nearby_items:
		if item.global_position.distance_to(position) < radius:
			var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			position += random_offset
			break
	return position

func drop_item(item_data, drop_position):
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	item_instance.set_item_data(item_data)
	drop_position = adjust_drop_position(drop_position)
	item_instance.global_position = drop_position
	get_tree().current_scene.add_child(item_instance)
	var building_data = {
		"type" : item_data["type"],
		"position" : drop_position,
		"texture_path": item_data["texture"].resource_path,
		"scene_path": item_data["scene_path"]
	}
	buildings_dropped.append(building_data)
	save_building_data()
	print("buildings dropped: ", buildings_dropped)

func place_item(item_data, position):
	var scene = load(item_data["scene_path"])
	var inst = scene.instantiate()
	var id = "%s_%d" % [ item_data["type"], buildings_dropped.size() ]
	inst.house_id = id
	inst.set_item_data(item_data)
	inst.global_position = position
	get_tree().current_scene.add_child(inst)
	var tile_map = get_tree().current_scene.get_node("TileMap")
	
	var origin = tile_map.local_to_map(position)
	
	for x_offset in range(-2, 3):
		for y_offset in range(-2, 3):
			var cell = origin + Vector2i(x_offset, y_offset)
			VillagerManager.block_tile(cell)
	
	var item_type = item_data.get("item_type", "building")
	var building_data = {
		"type": item_data["type"],
		"item_type": item_type,
		"position": position,
		"texture_path" : item_data["texture"].resource_path,
		"scene_path": item_data["scene_path"],
		"layout":     {"furniture": [], "floor_tiles": []}
	}
	buildings_dropped.append(building_data)
	house_layouts[id] = building_data.layout
	save_building_data()


func save_building_data():
	var file = FileAccess.open(save_path7, FileAccess.WRITE)
	file.store_var(buildings_dropped)


func load_buildings_data():
	if FileAccess.file_exists(save_path7):
		var file = FileAccess.open(save_path7, FileAccess.READ)
		buildings_dropped = file.get_var(true)
		var did_migrate = false
		for i in range(buildings_dropped.size()):
			var b = buildings_dropped[i]
			if not b.has("id"):
				b.id = "%s_%d" % [b.type, i]
				b.layout = {"furniture": [], "floor_tiles": []}
				did_migrate = true
			house_layouts[b.id] = b.layout
		if did_migrate:
			save_building_data()
		for b in buildings_dropped:
			var scene = load(b.scene_path)
			var inst  = scene.instantiate()
			b["texture"] = load(b["texture_path"])
			inst.set_item_data(b)  
			inst.global_position = b.position
			inst.house_id = b.id
			get_tree().current_scene.add_child(inst)
			var tile_map = get_tree().current_scene.get_node("TileMap")
			var origin = tile_map.local_to_map(b.position)
			
			for x_offset in range(-2, 3):
				for y_offset in range(-2, 3):
					var cell = origin + Vector2i(x_offset, y_offset)
					VillagerManager.block_tile(cell)

func get_house_by_id(house_id: String):
	for node in get_tree().get_nodes_in_group("Buildings"):
		if node.has_method("get_house_id") and node.get_house_id() == house_id:
			return node
	return null

func get_house_position_by_id(house_id : String):
	for building in buildings_dropped:
		var id = "%s_%d" % [building.type, buildings_dropped.find(building)]
		if id == house_id:
			return building.position
	return Vector2.ZERO


func clear_inventory_save():
	if FileAccess.file_exists(save_path7):
		buildings_dropped.clear()
		save_building_data()

func save_inventory():
	var inventory_to_save = []
	for item in inventory:
		if item != null:
			var item_copy = item.duplicate()
			item_copy["texture_path"] = item["texture"].resource_path
			inventory_to_save.append(item_copy)
		else:
			inventory_to_save.append(null)
	var file = FileAccess.open(save_path6, FileAccess.WRITE)
	file.store_var(inventory_to_save)

func save_wood():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(player_wood)

func load_inventory_data():
	if FileAccess.file_exists(save_path6):
		var file = FileAccess.open(save_path6, FileAccess.READ)
		inventory = file.get_var(true)
		for i in range(inventory.size()):
			if inventory[i] != null and inventory[i].has("texture_path"):
				inventory[i]["texture"] = load(inventory[i]["texture_path"])

func load_wood_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		player_wood = file.get_var(player_wood)

func save_points():
	var file = FileAccess.open(save_path1, FileAccess.WRITE)
	file.store_var(player_point)

func load_point_data():
	if FileAccess.file_exists(save_path1):
		var file = FileAccess.open(save_path1, FileAccess.READ)
		player_point = file.get_var(player_point)

func save_coins():
	var file = FileAccess.open(save_path2, FileAccess.WRITE)
	file.store_var(player_coin)

func load_coin_data():
	if FileAccess.file_exists(save_path2):
		var file = FileAccess.open(save_path2, FileAccess.READ)
		player_coin = file.get_var(player_coin)

func save_aff1_date():
	var file = FileAccess.open(save_path3, FileAccess.WRITE)
	file.store_var(affirmation_1_date)

func save_aff2_date():
	var file = FileAccess.open(save_path4, FileAccess.WRITE)
	file.store_var(affirmation_2_date)

func save_aff3_date():
	var file = FileAccess.open(save_path5, FileAccess.WRITE)
	file.store_var(affirmation_3_date)

func load_aff1_date():
	if FileAccess.file_exists(save_path3):
		var file = FileAccess.open(save_path3, FileAccess.READ)
		affirmation_1_date = file.get_var(true)

func load_aff2_date():
	if FileAccess.file_exists(save_path4):
		var file = FileAccess.open(save_path4, FileAccess.READ)
		affirmation_2_date = file.get_var(true)

func load_aff3_date():
	if FileAccess.file_exists(save_path5):
		var file = FileAccess.open(save_path5, FileAccess.READ)
		affirmation_3_date = file.get_var(true)
		#print(affirmation_3_date)

func save_villager_positions():
	var file = FileAccess.open(VILLAGER_POSITIONS_PATH, FileAccess.WRITE)
	file.store_var(villager_positions)

func load_villager_positions():
	if FileAccess.file_exists(VILLAGER_POSITIONS_PATH):
		var file = FileAccess.open(VILLAGER_POSITIONS_PATH, FileAccess.READ)
		villager_positions = file.get_var(true)
