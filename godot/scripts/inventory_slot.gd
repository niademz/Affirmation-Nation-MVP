extends Control

@onready var icon = $border/itemicon
@onready var quantity_label = $border/ItemQuantity
@onready var usage_panel = $UsagePanel
@onready var item_type = $UsagePanel/BuildingType

var item_detail = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	#print(icon.texture)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_item_button_pressed():
	if item_detail != null:
		usage_panel.visible = !usage_panel.visible


func set_empty():
	icon.texture = null
	quantity_label.text = ""

func set_item(new_item):
	item_detail = new_item
	icon.texture = new_item["texture"]
	quantity_label.text = str(item_detail["quantity"])
	item_type.text = str(item_detail["type"])
	pass


func _on_select_button_pressed():
	if item_detail != null:
		var ghost = preload("res://scenes/DragGhost.tscn").instantiate()
		ghost.item_data = item_detail
		get_tree().current_scene.add_child(ghost)
		usage_panel.visible = false


#
#func _on_select_button_pressed():
	#if item_detail != null:
		#var drop_position = Global.player_node.global_position
		#Global.drop_item(item_detail, drop_position)
		#Global.remove_item(item_detail["type"])
		#usage_panel.visible = false
