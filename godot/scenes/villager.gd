extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@export var char_name = "Alice"
var schedule = []
var current_path = []
var path_index = 0
@export var speed = 50
@export var home_id = "small_house_23"
var sleep_offset = Vector2(0, 32)
var current_target = ""
var is_sleeping = false
var directions = [
	Vector2i(0, 0),
	Vector2i(2,0), Vector2i(-2, 0),
	Vector2i(0, 2), Vector2i(0, -2),
	Vector2i(2, 2), Vector2i(-2, 2),
	Vector2i(2, -2), Vector2i(-2, -2)
]
signal arrived_home(name)

func _ready():
	scale = Vector2(0.5,0.5)
	add_to_group("Villagers")
	if Global.villager_positions.has(char_name):
		global_position = Global.villager_positions[char_name]
	schedule = VillagerManager.schedules.get(char_name, [])
	call_deferred("_init_home_and_schedule")

func check_schedule(current_hour: int):
	if is_sleeping:
		var current = Global.current_hour * 100 + Global.current_minute
		if current == 600:
			is_sleeping = false
			sprite.visible = true
	for entry in schedule:
		if is_time_in_range(entry["start"], entry["end"]):
			match entry["type"]:
				"GOTO":
					Global.villager_home_arrived[char_name] = false
					is_sleeping = false
					sprite.visible = true
					if current_target != entry["spot"]:
						move_to_spot(entry["spot"])
						current_target = entry["spot"]
				"SLEEP":
					if not is_sleeping:
						is_sleeping = true
						var house = Global.get_house_by_id(home_id)
						if house:
							var sleep_position = house.global_position + sleep_offset
							move_to_position(sleep_position)
					
			return
	current_target = ""
	

func _physics_process(delta):
	if path_index < current_path.size():
		var target = current_path[path_index]
		var direction = (target - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if abs(direction.x) > abs(direction.y):
			sprite.play("right" if direction.x > 0 else "left")
		else:
			sprite.play("down" if direction.y > 0 else "up")
		
		if global_position.distance_to(target) < 4:
			path_index += 1
	else:
		velocity = Vector2.ZERO
		sprite.play("default")
	if is_sleeping and path_index >= current_path.size():
		sprite.visible = false
		if get_tree().current_scene.name == "Nation":
			emit_signal("arrived_home", char_name)
	if is_inside_tree() and get_tree().current_scene.name == "Nation":
		Global.villager_positions[char_name] = global_position

func move_to_spot(spot_name:String):
	var nation = get_tree().current_scene
	var spot_node = nation.get_node_or_null("Spots/" + spot_name)
	if not spot_node:
		#print("node not found")
		return
	
	var tilemap = nation.get_node("TileMap")
	var from_cell = tilemap.local_to_map(global_position)
	var to_cell = tilemap.local_to_map(spot_node.global_position)
	
	var id_path = VillagerManager.astar.get_id_path(hash(from_cell), hash(to_cell))
	#print("Full ID path:", id_path)
	#
	#print("From cell:", from_cell, "To cell:", to_cell)
	#print("From hash exists:", VillagerManager.astar.has_point(hash(from_cell)))
	#print("To hash exists:", VillagerManager.astar.has_point(hash(to_cell)))
	if id_path.is_empty():
		return
	
	current_path.clear()
	for id in id_path:
		current_path.append(VillagerManager.astar.get_point_position(id))
	path_index = 0

func is_time_in_range(start: int, end: int):
	var current = Global.current_hour * 100 + Global.current_minute
	if start < end:
		return current >= start and current < end
	else:
		#overnight ranges
		return current >= start or current < end

func move_to_position(pos: Vector2):
	var tilemap = get_tree().current_scene.get_node("TileMap")
	var from_cell = tilemap.local_to_map(global_position)
	var to_cell = tilemap.local_to_map(pos)
	var from_id = hash(from_cell)
	var to_id = hash(to_cell)
	
	#print("Sleep movement debug:")
	#print("From:", from_cell, "To:", to_cell)
	#print("From ID in AStar:", VillagerManager.astar.has_point(from_id), "disabled:", VillagerManager.astar.is_point_disabled(from_id))
	#print("To ID in AStar:", VillagerManager.astar.has_point(to_id), "disabled:", VillagerManager.astar.is_point_disabled(to_id))
	
	var id_path = VillagerManager.astar.get_id_path(from_id,to_id)
	
	if id_path.is_empty():
		#print("Original Sleep path failed. trying fallback")
		to_id = find_nearest_walkable_id(to_cell, VillagerManager.astar)
		if to_id == -1:
			#print("Fallback: No nearby walkable cell for sleep position")
			return
		id_path = VillagerManager.astar.get_id_path(from_id, to_id)
		if id_path.is_empty():
			#print("Fallback sleep path still could not be found")
			return
	current_path.clear()
	for id in id_path:
		current_path.append(VillagerManager.astar.get_point_position(id))
	path_index = 0
	#print("Sleep path set with", current_path.size(), "nodes.")
	VillagerManager.sleep_steps_to_home[char_name] = id_path.size()

func _init_home_and_schedule():
	var house = Global.get_house_by_id(home_id)
	if house:
		pass
		#print(char_name, " has home at: ", house.global_position)
	else:
		pass
		#print(char_name, " has no home.")

func find_nearest_walkable_id(start_cell: Vector2i, astar: AStar2D):
	var directions = [
		Vector2i(0, 0),
		Vector2i(3,0), Vector2i(-3, 0),
		Vector2i(0, 3), Vector2i(0, -3),
		Vector2i(3, 3), Vector2i(-3, 3),
		Vector2i(3, -3), Vector2i(-3, -3)
	]
	
	for offset in directions:
		var cell = start_cell + offset
		var id = hash(cell)
		if astar.has_point(id) and not astar.is_point_disabled(id):
			#print("found recoverable walking path at:", id)
			return id
	return -1 #not found
