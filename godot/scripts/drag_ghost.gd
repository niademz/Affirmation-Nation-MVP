extends Node2D


var item_data = {}
var can_place := false
@onready var sprite = $Sprite2D
@onready var area = $Area2D

func _ready():
	sprite.texture = load(item_data.texture_path)
	set_process(true)

func _process(delta):
	global_position = get_global_mouse_position()
	_update_visuals()

func _update_visuals():
	var overlap = area.get_overlapping_bodies().size() + area.get_overlapping_areas().size() > 0
	can_place = not overlap
	sprite.modulate = Color(1,0,0,0.7) if overlap else Color(1,1,1,0.7)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if can_place:
			Global.place_item(item_data, global_position)
			Global.remove_item(item_data["type"])
			queue_free()
		else:
			pass
