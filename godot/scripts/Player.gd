extends CharacterBody2D
var speed : int = 100
var current_dir = "none"
var is_attacking = false
var tree_axe_cooldown = false
var is_angry = false
@onready var inventory_ui = $CanvasLayer/Inventory_UI
@onready var light2d = $PointLight2D


func _ready():
	$Sprite2D/AnimatedSprite2D.play("front_idle")
	Global.set_player_reference(self)

func _physics_process(delta):
	light2d.visible = Global.player_angry
	if not is_attacking:
		player_movement(delta)
	axe()
	

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		inventory_ui.visible = !inventory_ui.visible

func player_movement(delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(1)
		velocity.x = 0
		velocity.y = speed
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(1)
		velocity.x = 0
		velocity.y = -speed
	else:
		play_anim(0)
		velocity.x = 0
		velocity.y = 0

	move_and_slide()

func play_anim(movement):
	var dir = current_dir
	var anim = $Sprite2D/AnimatedSprite2D

	if dir == "right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif dir == "left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			anim.play("side_idle")
	elif dir == "down":
		anim.flip_h = true
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			anim.play("front_idle")
	elif dir == "up":
		anim.flip_h = true
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			anim.play("back_idle")

func axe():
	var dir = current_dir
	var anim = $Sprite2D/AnimatedSprite2D
	if Input.is_action_just_pressed("left_click"):
		Global.player_current_axe = true
		is_attacking = true
		if dir == "right":
			anim.flip_h = false
			anim.play("side_axe")
		elif dir == "left":
			anim.flip_h = true
			anim.play("side_axe")
		elif dir == "down":
			anim.play("front_axe")
		elif dir == "up":
			anim.play("back_axe")
		$axe_cooldown.start()
		$deal_attack_timer.start()

func player():
	pass

func _on_deal_attack_timer_timeout():
	$deal_attack_timer.stop()
	is_attacking = false
	play_anim(0)


func _on_player_hitbox_body_entered(body):
	if body.has_method("tree"):
		Global.tree_inaxe_range = true
		print("tree")
	if body.has_method("blaze"):
		temporary_speed_boost()
		$AnimationPlayer.stop()
		$AnimationPlayer.play_backwards("get_angry")
		await $AnimationPlayer.animation_finished
		Global.player_angry = true
		Global.player_wood -= 20
		Global.save_wood()
		is_angry = true


func _on_player_hitbox_body_exited(body):
	if body.has_method("tree"):
		Global.tree_inaxe_range = false


func _on_axe_cooldown_timeout():
	$axe_cooldown.stop()
	Global.player_current_axe = false

func in_water():
	speed = 65
	if is_angry:
		$AnimationPlayer.play_backwards("get_angry")
		await $AnimationPlayer.animation_finished
		is_angry = false
		Global.player_angry = false
	$AnimationPlayer.play("in_water")

func on_land():
	speed = 100
	$AnimationPlayer.play("RESET")
	if is_angry:
		Global.player_angry = true
		$AnimationPlayer.play_backwards("get_angry")

func temporary_speed_boost():
	speed = 400  # Boost speed
	await get_tree().create_timer(3).timeout  # Wait 3 seconds
	speed = 100  # Reset speed
