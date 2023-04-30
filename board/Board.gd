extends Node

# the state of the board
var board_positions
var size = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_board()

# initializes the board state
func setup_board():
	board_positions = []
	for row_key in range(0, size - 1):
		board_positions.append([])
		for column_key in range(0, size - 1):
			board_positions[row_key].append(null)

# gets the tile at the position
func get_tile_at_position(x, y):
	return board_positions[x][y]

# gets empty spots
func get_empty_spots():
	var spots = []
	
	for row_key in range(0, size - 1):
		for column_key in range(0, size - 1):
			if board_positions[row_key][column_key] == null:
				spots.append({
					'x': row_key,
					'y': column_key
				})
	
	return spots
