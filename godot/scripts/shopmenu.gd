extends StaticBody2D

# item 1 = small_house, 2 = small_hut, 3 = small_tavern 
# 4 = dock_house, 5 = big_hut, 6 = keep

var item : int = 1

var item1price = 100
var item2price = 100
var item3price = 150
var item4price = 250
var item5price = 500
var item6price = 500

var price

func _ready():
	$icon.play("small_house")
	item = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if self.visible == true:
		if item == 1:
			$icon.play("small_house")
			$pricelabel.text = str(item1price)
			if Global.player_wood >= item1price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"
		if item == 2:
			$icon.play("small_hut")
			$pricelabel.text = str(item2price)
			if Global.player_wood >= item2price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"
		if item == 3:
			$icon.play("small_tavern")
			$pricelabel.text = str(item3price)
			if Global.player_wood >= item3price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"
		if item == 4:
			$icon.play("dock_house")
			$pricelabel.text = str(item4price)
			if Global.player_wood >= item4price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"
		if item == 5:
			$icon.play("big_hut")
			$pricelabel.text = str(item5price)
			if Global.player_wood >= item5price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"
		if item == 6:
			$icon.play("keep")
			$pricelabel.text = str(item6price)
			if Global.player_wood >= item6price:
				$buybuttoncolor.color = "00ff0a77"
			else:
				$buybuttoncolor.color = "ff000a77"


func _on_buttonleft_pressed():
	swap_item_back()
func _on_buttonright_pressed():
	swap_item_forward()
func _on_buybutton_pressed():
	if item == 1:
		price = item1price
		if Global.player_wood >= price:
			buy()
	elif item == 2:
		price = item2price
		if Global.player_wood >= price:
			buy()
	elif item == 3:
		price = item3price
		if Global.player_wood >= price:
			buy()
	elif item == 4:
		price = item4price
		if Global.player_wood >= price:
			buy()
	elif item == 5:
		price = item5price
		if Global.player_wood >= price:
			buy()
	elif item == 6:
		price = item6price
		if Global.player_wood >= price:
			buy()
	

func swap_item_back():
	if item == 1:
		item = 6
	elif item == 2:
		item = 1
	elif item == 3:
		item = 2
	elif item == 4:
		item = 3
	elif item == 5:
		item = 4
	elif item == 6:
		item = 5

func swap_item_forward():
	if item == 1:
		item = 2
	elif item == 2:
		item = 3
	elif item == 3:
		item = 4
	elif item == 4:
		item = 5
	elif item == 5:
		item = 6
	elif item == 6:
		item = 1

# item 1 = small_house, 2 = small_hut, 3 = small_tavern 
# 4 = dock_house, 5 = big_hut, 6 = keep

func buy():
	Global.player_wood -= price
	Global.save_wood()
	if item == 1:
		var building = {
			"quantity" : 1 ,
			"type" : "small_house",
			"texture" : preload("res://data/small_house.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
	if item == 2:
		var building = {
			"quantity" : 1 ,
			"type" : "small_hut",
			"texture" : preload("res://data/small_hut.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
	if item == 3:
		var building = {
			"quantity" : 1 ,
			"type" : "small_tavern",
			"texture" : preload("res://data/small_tavern.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
	if item == 4:
		var building = {
			"quantity" : 1 ,
			"type" : "dock_house",
			"texture" : preload("res://data/dock_house.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
	if item == 5:
		var building = {
			"quantity" : 1 ,
			"type" : "big_hut",
			"texture" : preload("res://data/big_hut.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
	if item == 6:
		var building = {
			"quantity" : 1 ,
			"type" : "keep",
			"texture" : preload("res://data/keep.tres"),
			"scene_path" : "res://scenes/inventory_item.tscn"
		}
		Global.add_item(building)
