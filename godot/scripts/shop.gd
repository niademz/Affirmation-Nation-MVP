extends StaticBody2D





func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		$CanvasLayer/shopnew.visible = true
		
	pass # Replace with function body.


func _on_area_2d_body_exited(body):
	if body.has_method("player"):
		$CanvasLayer/shopnew.visible = false
	pass # Replace with function body.
