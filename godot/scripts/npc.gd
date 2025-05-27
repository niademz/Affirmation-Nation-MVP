extends CharacterBody2D

@export var target : Node2D
@export var char_type : int
@onready var navigation_agent_2d = $NavigationAgent2D
var speed = 50
@onready var anim = $AnimatedSprite2D

var direction
var is_move
var stopping_distance = 2.0  # Adjust this if needed

func _ready():
	if char_type == 1:
		anim.play("front_idle_girl")
	elif char_type == 2:
		anim.play("front_idle_man")
	else:
		anim.play("front_idle_woman")
	pass
	is_move = true
	$NavTimer.start()

func _physics_process(delta : float) -> void:
	if not is_move:
		velocity = Vector2.ZERO
		if char_type == 1:
			anim.play("front_idle_girl")
		elif char_type == 2:
			anim.play("front_idle_man")
		else:
			anim.play("front_idle_woman")
		return  # Stop further movement processing

	# Get direction to target
	direction = navigation_agent_2d.get_next_path_position() - global_position

	# Check if close enough to stop
	if direction.length() < stopping_distance:
		velocity = Vector2.ZERO
		if char_type == 1:
			anim.play("front_idle_girl")
		elif char_type == 2:
			anim.play("front_idle_man")
		else:
			anim.play("front_idle_woman")
		return  # Stop movement processing

	direction = direction.normalized()

	# Snap to four directions (no diagonal movement)
	if abs(direction.x) > abs(direction.y):
		direction.y = 0
	else:
		direction.x = 0

	# Move NPC
	velocity = velocity.lerp(direction * speed, delta)
	move_and_slide()

	# Play correct animation based on movement direction
	if direction.x > 0:
		if char_type == 1:
			anim.play("side_walk_girl")
		elif char_type == 2:
			anim.play("side_walk_man")
		else:
			anim.play("side_walk_woman")
		anim.flip_h = false  # Right movement
	elif direction.x < 0:
		if char_type == 1:
			anim.play("side_walk_girl")
		elif char_type == 2:
			anim.play("side_walk_man")
		else:
			anim.play("side_walk_woman")
		anim.flip_h = true  # Left movement
	elif direction.y > 0:
		if char_type == 1:
			anim.play("front_walk_girl")
		elif char_type == 2:
			anim.play("front_walk_man")
		else:
			anim.play("front_walk_woman")
	elif direction.y < 0:
		if char_type == 1:
			anim.play("back_walk_girl")
		elif char_type == 2:
			anim.play("back_walk_man")
		else:
			anim.play("back_walk_woman")



func _on_nav_timer_timeout() -> void:
	is_move = true
	navigation_agent_2d.target_position = target.global_position
	$NavTimer.start()


func _on_area_2d_body_entered(body):
	if body.has_method("player"):
		print("eww player")
		is_move = false
	pass # Replace with function body.


func _on_area_2d_body_exited(body):
	if body.has_method("player"):
		print("bye eww player")
		is_move = false
		$NavTimer.start()
		
	pass # Replace with function body.
