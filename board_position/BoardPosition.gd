extends Node

@export var board_position : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Area_body_entered(body):
	print('tile entered ', board_position)

func _on_Area_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	print('tile entered 2', board_position)

func _on_Area_body_exited(body):
	print('tile left', board_position)

func _on_Area_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	print('tile left 2', board_position)
