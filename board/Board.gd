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
	for row_key in range(0, size):
		board_positions.append([])
		for column_key in range(0, size):
			board_positions[row_key].append(null)

# gets the tile at the position
func get_tile_at_position(x, y):
	if x < 0 or \
		x > size - 1 or \
		y < 0 or \
		y > size - 1:
		return null
		
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

# saves a tile at the given board position
func set_tile_at_position(tile, x, y):
	board_positions[x][y] = tile
