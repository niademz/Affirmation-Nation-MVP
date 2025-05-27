extends NinePatchRect

# Expose item_id to the inspector
@export var item_id: int = 0

# Define a dictionary mapping item IDs to their properties
var item_data = {
	1: {
		"texture": preload("res://data/small_house.tres"),
		"price": 100,
		"min_lvl": 1,
		"type": "small_house",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	2: {
		"texture": preload("res://data/small_hut.tres"),
		"price": 100,
		"min_lvl": 2,
		"type": "small_hut",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	3: {
		"texture": preload("res://data/small_tavern.tres"),
		"price": 150,
		"min_lvl": 5,
		"type": "small_tavern",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	4: {
		"texture": preload("res://data/dock_house.tres"),
		"price": 250,
		"min_lvl": 7,
		"type": "dock_house",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	5: {
		"texture": preload("res://data/big_hut.tres"),
		"price": 500,
		"min_lvl": 10,
		"type": "big_hut",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	6: {
		"texture": preload("res://data/keep.tres"),
		"price": 500,
		"min_lvl": 10,
		"type": "keep",
		"item_type": "building",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	10: {
		"texture": preload("res://data/bench.tres"),
		"price": 50,
		"min_lvl": 3,
		"type": "bench",
		"item_type": "furniture",
		"scene_path": "res://scenes/bench_item.tscn"
	},
	11: {
		"texture": preload("res://data/lantern.tres"),
		"price": 70,
		"min_lvl": 5,
		"type": "lantern",
		"item_type": "furniture",
		"scene_path": "res://scenes/lantern.tscn"
	},
	12: {
		"texture": preload("res://data/barrel.tres"),
		"price": 100,
		"min_lvl": 5,
		"type": "barrel",
		"item_type": "furniture",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	13: {
		"texture": preload("res://data/ship.tres"),
		"price": 200,
		"min_lvl": 10,
		"type": "ship",
		"item_type": "ship",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	14: {
		"texture": preload("res://data/well.tres"),
		"price": 300,
		"min_lvl": 15,
		"type": "well",
		"item_type": "well",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	15: {
		"texture": preload("res://data/statue.tres"),
		"price": 1000,
		"min_lvl": 20,
		"type": "statue",
		"item_type": "statue",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	20: {
		"texture": preload("res://data/snow_globe.tres"),
		"price": 100,
		"min_lvl": 3,
		"type": "snowglobe",
		"item_type": "snowglobe",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	21: {
		"texture": preload("res://data/snowman.tres"),
		"price": 200,
		"min_lvl": 5,
		"type": "snowman",
		"item_type": "snowman",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	22: {
		"texture": preload("res://data/street_light.tres"),
		"price": 300,
		"min_lvl": 5,
		"type": "streetlight",
		"item_type": "street_light",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	23: {
		"texture": preload("res://data/season_bush.tres"),
		"price": 300,
		"min_lvl": 10,
		"type": "seasonbush",
		"item_type": "seasonbush",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	24: {
		"texture": preload("res://data/christmashouse.tres"),
		"price": 700,
		"min_lvl": 10,
		"type": "christmashouse",
		"item_type": "christmas_house",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
	25: {
		"texture": preload("res://data/winter_fountain.tres"),
		"price": 1000,
		"min_lvl": 15,
		"type": "winterfountain",
		"item_type": "winter_fountain",
		"scene_path": "res://scenes/inventory_item.tscn"
	},
}

@onready var texture_rect = $TextureRect
@onready var price_label = $pricelabel
@onready var buy_button = $buybuttoncolor 
@onready var lock_panel = $Panel
@onready var lock_label = $Panel/Label 

func _ready():
	# Update the shop item based on the item_id
	update_item_display()

func _physics_process(delta):
	update_buy_button_color()
	update_item_display()
	pass

func update_buy_button_color():
	if item_id in item_data:
		var price = item_data[item_id]["price"]
		if Global.player_wood >= price:
			buy_button.color = Color("00ff0a77") # Green if enough wood
		else:
			buy_button.color = Color("ff000a77") # Red if not enough wood

func update_item_display():
	var current_level = Global.player_lvl
	var current_points = Global.player_point
	var points_for_current_level = Global.nextLevel(current_level - 1) if current_level > 1 else 0
	var points_for_next_level = Global.nextLevel(current_level)
	var progress = (current_points - points_for_current_level) / float(points_for_next_level - points_for_current_level)
	if item_id in item_data:
		var data = item_data[item_id]
		
		# Check if player level meets the minimum level
		if current_level >= data["min_lvl"]:
			# Player level is sufficient: show the item and hide the lock panel
			lock_panel.visible = false
			texture_rect.texture = data["texture"]
			price_label.text = str(data["price"])
		else:
			# Player level is insufficient: show the lock panel
			lock_panel.visible = true
			lock_label.text = "[center]Unlock at level %d[/center]" % data["min_lvl"]
			texture_rect.texture = data["texture"]
			price_label.text = "--" # Hide the price
	else:
		pass


func _on_buybutton_pressed():
	if item_id in item_data:
		var data = item_data[item_id]
		
		# Check level and resource requirements
		if Global.player_lvl >= data["min_lvl"] and Global.player_wood >= data["price"]:
			Global.player_wood -= data["price"]
			Global.save_wood()
			
			# Add the purchased item to the inventory
			var building = {
				"quantity": 1,
				"type": data["type"],
				"item_type": data["item_type"],
				"texture": data["texture"],
				"scene_path": data["scene_path"]
			}
			Global.add_item(building)
			print("Purchased:", data["type"])
		else:
			print("Cannot purchase:", data["type"], "- Insufficient resources or level")
