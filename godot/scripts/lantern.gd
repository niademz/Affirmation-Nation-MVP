extends CharacterBody2D

@export var house_id = ""
var item_type = "lantern"
var item_texture : Texture

@onready var light = $PointLight2D
@onready var anim = $AnimatedSprite2D

var is_on = false
var transitioning = false
var frame_counter := 0

func _ready():
	scale = Vector2(0.7,0.7)
	anim.play("off")
	anim.stop()
	light.energy = 0.0

func _physics_process(delta):
	# Run logic every 8 frames
	frame_counter += 1
	if frame_counter % 10 == 0:
		update_lantern_state()

func set_item_data(data):
	item_type = data["type"]
	item_texture = data["texture"]

func update_lantern_state():
	var hour = Global.current_hour

	if hour >= 18 or hour <= 5:
		if !is_on and !transitioning:
			anim.play("turn_on")
			transitioning = true
			await get_tree().create_timer(anim.sprite_frames.get_frame_count("turn_on") / anim.speed_scale / 60.0).timeout
			anim.play("on")
			light.energy = 1.0
			is_on = true
			transitioning = false
		elif is_on:
			anim.play("on")
			light.energy = 1.0
	else:
		if is_on:
			anim.play("off")
			anim.stop()
			light.energy = 0.0
			is_on = false
			transitioning = false

func _on_button_pressed():
	$remove.visible = !$remove.visible

func _on_remove_house_pressed():
	var item_prices = {
		"lantern": 70
	}

	if item_type in item_prices:
		var refund = max(item_prices[item_type] - 30, 0)
		Global.player_wood += refund
		Global.save_wood()
		print("Refunded wood:", refund)

	for i in range(Global.buildings_dropped.size()):
		var saved_building = Global.buildings_dropped[i]
		if saved_building["type"] == item_type and saved_building["position"] == self.global_position:
			Global.buildings_dropped.remove_at(i)
			Global.save_building_data()
			break

	var tile_map = get_parent().get_node("TileMap")
	var origin = tile_map.local_to_map(global_position)

	for x_offset in range(-2, 3):
		for y_offset in range(-2, 3):
			var cell = origin + Vector2i(x_offset, y_offset)
			VillagerManager.unblock_tile(cell)

	self.queue_free()
