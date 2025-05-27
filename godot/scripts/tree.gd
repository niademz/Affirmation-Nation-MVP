extends CharacterBody2D

var health = 80
var player_inaxe_zone = false
var burned = false



func _physics_process(delta):
	deal_with_damage()

func tree():
	pass



func _on_tree_hitbox_body_entered(body):
	if body.has_method("player"):
		player_inaxe_zone = true
		print("player")
		if health == 0:
			Global.player_wood += 100
			print("Wood: ", Global.player_wood)
			$".".queue_free()
			Global.save_wood()
	if body.has_method("blaze") and not burned:
		burned = true
		$Blaze_kill.start()


func _on_tree_hitbox_body_exited(body):
	if body.has_method("player"):
		player_inaxe_zone = false

func deal_with_damage():
	if player_inaxe_zone and Global.player_current_axe == true:
		if health > 0:
			$tree_cooldown.start()
			$AnimationPlayer.play("hurt")
			




func _on_tree_cooldown_timeout():
	$tree_cooldown.stop()
	health = health - 20
	print(health)
	if health <= 0:
		health = 0
		$AnimationPlayer.play("RESET")
		$AnimationPlayer.play("dead")


func _on_blaze_kill_timeout():
	$BasicGrassBiomThings.texture = $BasicGrassBiomThings.texture.duplicate()
	$BasicGrassBiomThings.texture = load("res://art/Sprout Lands - Sprites/Objects/burned_tree.png")
	$AnimationPlayer.play("burning")
	$Blaze_kill.stop()
