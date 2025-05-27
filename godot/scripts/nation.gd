extends Node2D

@onready var tile_map = $TileMap
@onready var player = $Player
@onready var canvas_modulate = $CanvasModulate
@onready var ui = $CanvasLayer/DayNightCycleUI

var affirmation_open = false


func _ready():
	VillagerManager.build_grid($TileMap)
	#block_tree_tiles()
	$instructions_timeout.start()
	Global.load_buildings_data()
	canvas_modulate.time_tick.connect(ui.set_daytime)
	canvas_modulate.time_tick.connect(Global.update_time)
	canvas_modulate.time_tick.connect(VillagerManager._on_time_tick)
	if Global.return_position != Vector2.ZERO:
		$Player.global_position = Global.return_position + Vector2(0,32)
		Global.return_position = Vector2.ZERO
	
	for villager in get_tree().get_nodes_in_group("Villagers"):
		villager.check_schedule(Global.current_hour)
		villager.connect("arrived_home", Callable(self, "_on_villager_arrived_home"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	player_in_water()
	get_wood()
	get_coin()
	set_angry_mode(Global.player_angry)
	#pass

func player_in_water():
	var tile_data : TileData = tile_map.get_cell_tile_data(1, tile_map.local_to_map(player.position))
	#print(tile_data)
	if tile_data == null:
		player.in_water()
	else:
		player.on_land()
	pass

func get_wood():
	Global.load_wood_data()
	$CanvasLayer/thingy/wood_label.text = str(Global.player_wood)

func get_coin():
	Global.load_coin_data()
	$CanvasLayer/thingy/coin_count.text = str(Global.player_coin)

func _on_button_pressed():
	toggle_menu()
	

func toggle_menu():
	affirmation_open = !affirmation_open
	if affirmation_open:
		$CanvasLayer/Affirmation.visible = true
		$CanvasLayer/thingy.visible = false
	else:
		$CanvasLayer/Affirmation.visible = false
		$CanvasLayer/thingy.visible = true


func _on_instructions_timeout_timeout():
	$instructions_timeout.stop()
	$textbox.visible = false


func _on_portal_area_body_entered(body):
	if body.has_method("player"):
		print("change world")
		get_tree().change_scene_to_file("res://scenes/Underground.tscn")

func set_angry_mode(enabled):
	if enabled:
		$CanvasModulate.color = Color(0, 0, 0, 1)  # Very dark
	else:
		$CanvasModulate.color = Color(1, 1, 1, 1)

func _on_villager_arrived_home(name: String):
	Global.villager_home_arrived[name] = true

func block_tree_tiles():
	var tilemap = $TileMap
	for tree in get_tree().get_nodes_in_group("tree"):
		var pos = tree.global_position
		var cell = tilemap.local_to_map(pos)
		VillagerManager.block_tile(cell)
