extends BTAction

@export var target_pos_var := &"pos"
@export var dir_var := &"dir"

@export var speed_var = 70
@export var tolerance = 10

func _tick(delta) -> Status:
	var target_pos : Vector2 = blackboard.get_var(target_pos_var,Vector2.ZERO)
	var dir = blackboard.get_var(dir_var)
	dir = target_pos - agent.global_position
	blackboard.set_var(dir_var,dir)
	if abs(agent.global_position - target_pos).length() < tolerance:
		agent.move(Vector2.ZERO, delta, speed_var)
		return SUCCESS
	
	agent.move(dir, delta, speed_var)
	return RUNNING
