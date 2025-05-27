extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var ray = $Raycast_center
@onready var ray_left = $Raycast_left
@onready var ray_right = $Raycast_right



var avoiding_obstacle = false
var avoidance_timer = 1
var avoidance_direction = Vector2.ZERO

func _ready():
	anim.play("front_idle")



func move(dir : Vector2, delta, speed):
	if abs(dir.x) > abs(dir.y):
		dir.y = 0
	else:
		dir.x = 0

	dir = dir.normalized()
	
	if avoiding_obstacle:
		dir = avoidance_direction
	
	ray.target_position = dir * 40
	ray.force_shapecast_update()
	
	ray_left.target_position = (dir + Vector2.LEFT * 0.5).normalized() * 40
	ray_left.force_shapecast_update()
	
	ray_right.target_position = (dir + Vector2.RIGHT * 0.5).normalized() * 40
	ray_right.force_shapecast_update()
	
	if ray.is_colliding() or ray_left.is_colliding() or ray_right.is_colliding():
		if not avoiding_obstacle:
			avoidance_direction = avoid_obstacle(dir)
			avoiding_obstacle = true
			get_tree().create_timer(avoidance_timer).timeout.connect(reset_avoidance)
	
	velocity = velocity.lerp(dir * speed, delta)
	move_and_slide()
	
	if dir.x > 0:
		anim.play("side_walk")
		anim.flip_h = false  # Right movement
	elif dir.x < 0:
		anim.play("side_walk")
		anim.flip_h = true  # Left movement
	elif dir.y > 0:
		anim.play("front_walk")
	elif dir.y < 0:
		anim.play("back_walk")
	else:
		anim.play("front_idle")

func blaze():
	pass


func _on_area_2d_body_entered(body):
	if body.has_method("tree"):
		anim.play("rage_mode")

func rage():
	anim.play("rage_mode")

func avoid_obstacle(dir : Vector2):
	var alternate_directions = [Vector2.UP, Vector2.DOWN] if dir.x != 0 else [Vector2.LEFT, Vector2.RIGHT]

	# Check left and right rays first
	if not ray_left.is_colliding():
		return (dir + Vector2.LEFT * 0.5).normalized()
	elif not ray_right.is_colliding():
		return (dir + Vector2.RIGHT * 0.5).normalized()

	# If both left/right blocked, try perpendicular directions
	for new_dir in alternate_directions:
		ray.target_position = new_dir * 40
		ray.force_shapecast_update()
		if not ray.is_colliding():
			return new_dir

	# If no clear path, reverse
	return -dir

func reset_avoidance():
	avoiding_obstacle = false
	avoidance_direction = Vector2.ZERO
