extends NinePatchRect


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Panel/wood_label.text = str(Global.player_wood)
	pass


func _on_housebutton_pressed():
	$GridContainer2/slot1.item_id=1
	$GridContainer2/slot2.item_id=2
	$GridContainer2/slot3.item_id=3
	$GridContainer2/slot4.item_id=4
	$GridContainer2/slot5.item_id=5
	$GridContainer2/slot6.item_id=6


func _on_decobutton_pressed():
	$GridContainer2/slot1.item_id=10
	$GridContainer2/slot2.item_id=11
	$GridContainer2/slot3.item_id=12
	$GridContainer2/slot4.item_id=13
	$GridContainer2/slot5.item_id=14
	$GridContainer2/slot6.item_id=15
	pass # Replace with function body.



func _on_seasonbutton_pressed():
	$GridContainer2/slot1.item_id=20
	$GridContainer2/slot2.item_id=21
	$GridContainer2/slot3.item_id=22
	$GridContainer2/slot4.item_id=23
	$GridContainer2/slot5.item_id=24
	$GridContainer2/slot6.item_id=25
	pass # Replace with function body.
