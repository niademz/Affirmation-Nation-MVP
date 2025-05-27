extends StaticBody2D

@onready var textbox = $textbox




func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		$textbox.visible = true

func _on_area_2d_body_exited(body):
	if body.has_method("player"):
		$textbox.visible = false
