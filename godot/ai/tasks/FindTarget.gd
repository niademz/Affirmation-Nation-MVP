extends BTAction

@export var group: StringName
@export var target_var:StringName = &"target"


var target

func _tick(_delta) -> Status:
	if group == "tree":
		target = get_tree_node()
	elif group == "player":
		target = get_player_node()
	blackboard.set_var(target_var,target)
	return SUCCESS

func get_tree_node():
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	nodes = nodes.filter(func(tree): return not tree.burned)
	nodes.shuffle()
	return nodes.front()

func get_player_node():
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	return nodes[0]
