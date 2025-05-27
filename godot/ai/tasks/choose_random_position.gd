extends BTAction

@export var range_min_in_dir = 40.0
@export var range_max_in_dir = 100.0

@export var position_var = &"pos"
@export var dir_var = &"dir"

func _tick(_delta: float) -> Status:
	var pos:Vector2
	var dir = rando_dir()
	
	pos = rando_pos(dir)
	blackboard.set_var(position_var,pos)
	return SUCCESS
	

func rando_pos(dir):
	var vector: Vector2
	var distance = Vector2(randi_range(range_min_in_dir, range_max_in_dir),randi_range(range_min_in_dir, range_max_in_dir)) * dir
	var final_position = (distance + agent.global_position)
	vector.x = final_position.x
	vector.y = final_position.y
	return vector

func rando_dir():
	var dir: Vector2
	dir.x = randi_range(-2,1)
	dir.y = randi_range(-2,1)
	
	if abs(dir.x) != dir.x:
		dir.x = -1
	else:
		dir.x = 1
	
	if abs(dir.y) != dir.y:
		dir.y = -1
	else:
		dir.y = 1
	blackboard.set_var(dir_var,dir)
	return dir
