extends CharacterBody2D
@export var house_id = ""
var item_type = ""
var item_texture : Texture

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta):
	pass

func set_item_data(data):
	item_type = data["type"]
	item_texture = data["texture"]


func _on_button_pressed():
	$remove.visible = !$remove.visible


func _on_remove_house_pressed():
	var item_prices = {
		"bench": 50
	}
	
	if item_type in item_prices:
		var refund = max(item_prices[item_type] - 30, 0) # Ensure refund is not negative
		Global.player_wood += refund
		Global.save_wood() # Save updated wood value
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
