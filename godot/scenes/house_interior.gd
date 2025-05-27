extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	print("=== HouseInterior Ready ===")
	print("Current house ID:", Global.current_house_id)
	print("Current time:", Global.current_hour * 100 + Global.current_minute)
	spawn_villager_if_sleeping()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		get_tree().change_scene_to_file("res://scenes/nation.tscn")

func is_time_in_range(current, start, end):
	if start < end:
		return current >= start and current < end
	else:
		return current >=start or current < end

func get_villager_home_id(name):
	if name == "Alice":
		return "small_house_23"
	if name == "Ben":
		return "small_tavern_19"
	return ""

func spawn_villager_inside(name):
	var scene = preload("res://scenes/villager.tscn")
	var villager = scene.instantiate()
	add_child(villager)
	await get_tree().process_frame
	villager.char_name = name
	villager.global_position = $VillagerPosition.global_position
	villager.get_node("AnimatedSprite2D").visible = true
	print("Villager", name, "spawned inside house at", villager.global_position)

func spawn_villager_if_sleeping():
	var house_id = Global.current_house_id
	var time = Global.current_hour * 100 + Global.current_minute
	print("Checking sleeping villagers for house:", house_id)
	for name in VillagerManager.schedules.keys():
		var schedule = VillagerManager.schedules[name]
		for entry in schedule:
			if entry["type"] == "SLEEP" and is_time_in_range(time, entry["start"], entry["end"]):
				print("Checking sleep entry for", name, ":", entry)
				print(name, "should be sleeping now.")
				if get_villager_home_id(name) == house_id:
					if Global.villager_home_arrived.get(name, false):
						print(name, "is confirmed home. spawning...")
						spawn_villager_inside(name)
						return
					else:
						print(name, "is not home yet. Not spawning")
						return
					print(name, "belongs to this house. Spawning...")
				else:
					print(name, "does not belong to this house.")
