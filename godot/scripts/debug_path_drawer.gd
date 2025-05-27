extends Node2D

var path: Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	for i in range(path.size()):
		draw_circle(path[i], 4, Color.ORANGE)
	
	for i in range(path.size() - 1):
		draw_line(path[i], path[i + 1], Color.YELLOW, 2)
