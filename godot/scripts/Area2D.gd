extends Area2D


var entered = false

func _on_Area2D_body_entered(body: PhysicsBody2D):
	entered = true


func _on_Area2D_body_exited(body):
	entered = false

func _process(delta):
	if entered == true:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene("res://scenes/nation.tscn")
			 #actual transition all the rest leads up this controls transition


func _on_body_entered(body):
	get_tree().change_scene_to_file("res://scenes/nation.tscn")
