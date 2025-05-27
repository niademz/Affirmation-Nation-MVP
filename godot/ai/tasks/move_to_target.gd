extends BTAction

@export var target_var := &"target"

@export var speed_var = 70
@export var tolerance = 5

func _tick(delta) -> Status:
	var target = blackboard.get_var(target_var)
	
	if target != null:
		var target_position = target.global_position
		var dir = target_position - agent.global_position
		
		if abs(agent.global_position - target_position).length() < tolerance:
			agent.move(Vector2.ZERO, delta, speed_var)
			agent.rage()
			return SUCCESS
		else:
			agent.move(dir, delta, speed_var)
			return RUNNING
	return FAILURE
