extends Node

# the state of the board
var board_positions
var size = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_board()

# initializes the board state
func setup_board():
	# remove all tiles
	if board_positions:
		var tile
		for y in range(0, size):
			for x in range(0, size):
				tile = get_tile_at_position(x, y)
				if tile:
					tile.queue_free()
	
	# build the array to hold all the tiles
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

# gets the boxes that don't currently have a tile in them
func get_empty_boxes():
	var spots = []
	for y in range(0, size):
		for x in range(0, size):
			if get_tile_at_position(x, y) == null:
				spots.append({
					'x': x,
					'y': y
				})
	
	return spots

# saves a tile at the given board position
func set_tile_at_position(tile, x, y):
	board_positions[x][y] = tile

# gets the box at the given position
func get_box(x, y):
	return get_node(str(x) + '_' + str(y))
