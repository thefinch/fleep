extends Node

# the tiles that each player has
var player1 = []
var player2 = []
var tiles_per_hand = 5

# the scores
var player1Score = 0
var player2Score = 0
var flip_count = 0

# the tile object
var tile_scene = preload('res://tile/Tile.tscn')

# the board object
@onready var board = get_node('Board')

# called when the node enters the scene tree for the first time
func _ready():
	setup_players()

# figures out where to position the tile in the given player's hand
func get_tile_position_in_hand(player_number, tile_number):
	var x_offset = 0
	var offset = 8
	match(tile_number):
		0:
			x_offset = -2 * offset
		1:
			x_offset = -offset
		3:
			x_offset = offset
		4:
			x_offset = 2 * offset

	var y_offset = -25
	if player_number == 2:
		y_offset = -y_offset

	return Vector3(
		x_offset,
		y_offset,
		0
	)

# creates a tile and adds it to the given player's hand
func add_tile(player_hand, player_number, tile_number):
	# create the tile and add it to the player's hand array
	var new_tile = tile_scene.instantiate()
	new_tile.scale = Vector3(0.2, 0.2, 0.2)
	player_hand.append(new_tile)
	
	# put the tile where it needs to be in the player's hand on the screen
	var position = get_tile_position_in_hand(player_number, tile_number)
	new_tile.translate(position)
	new_tile.add_to_group('player' + str(player_number))
	add_child(new_tile)
	
	# make the tile draggable for the player
	if player_number == 1:
		new_tile.draggable = true

# resets and then fills up the player's hands
func setup_players():
	# reset the players' hands
	player1 = []
	player2 = []

	# create our tiles
	for tile_number in range(0, tiles_per_hand):
		add_tile(player1, 1, tile_number)
		add_tile(player2, 2, tile_number)

# gets the board position pointed to by an arrow located at the given position
func get_coordinate_from_arrow(arrow, position):
	var x = 0
	var y = 0
	match arrow:
		'UL':
			x = -1
			y = -1
		'U':
			y = -1
		'UR':
			x = 1
			y = -1
		'L':
			x = -1
		'R':
			x = 1
		'DL':
			x = -1
			y = 1
		'D':
			y = 1
		'DR':
			x = 1
			y = 1

	return {
		'x': position['x'] + x,
		'y': position['y'] + y
	}
	
# @todo this is broken right now
func flip(tiles_that_flipped):
	var run_again = []
	var tile_at_position
	var check_position
	var tile_at_check_position
	var current_side
	var new_side
	for position in tiles_that_flipped:
		# get the tile at this position
		tile_at_position = board.get_tile_at_position(position['x'], position['y'])
		# print('tile', tile_at_position, 'was placed at', $position)

		# flip each tile that it is pointing to
		for arrow in tile_at_position['tile'][tile_at_position['side']]:
			# get position of tile to flip
			check_position = get_coordinate_from_arrow(arrow, position)

			# flip tile if needed
			tile_at_check_position = board.get_tile_at_position(check_position['x'], check_position['y'])
			if board.get_tile_at_position(position['x'], position['y']) != null:
				# set which side we need to care about
				current_side = tile_at_check_position.get_current_side()
				new_side = 'bottom' if current_side == 'top' else 'top'
				tile_at_check_position.set_current_side(new_side)

				# flip the tile in the direction the arrow was pointing
				for side in ['top', 'bottom']:
					match arrow:
						'UL', 'DR':
							board[check_position['x']][check_position['y']]['tile'][side] = tile_scene.transpose(
								board[check_position['x']][check_position['y']]['tile'][side],
								'up-left'
							)

						'UR', 'DL':
							board[check_position['x']][check_position['y']]['tile'][side] = tile_scene.transpose(
								board[check_position['x']][check_position['y']]['tile'][side],
								'down-left'
							)

						'L', 'R':
							board[check_position['x']][check_position['y']]['tile'][side] = tile_scene.reflect(
								board[check_position['x']][check_position['y']]['tile'][side],
								'horizontal'
							)

						'U', 'D':
							board[check_position['x']][check_position['y']]['tile'][side] = tile_scene.reflect(
								board[check_position['x']][check_position['y']]['tile'][side],
								'vertical'
							)
							
				# add to the list of board positions to flip if necessary
				if not run_again.has(check_position):
					# increase score
					flip_count += 1                  
					
					# add it to the list of tiles that have been flipped
					run_again.append(check_position)

	# run again if needed
	if len(run_again) > 0:
		# check for infinite flips
		if flip_count > 100:
			print('probably going infinite')
			return

		flip(run_again)

	return

func make_ai_move():
	# get a tile from the opponent
	var tile = player2.pop()

	# get open spots
	var open = []
	for row_key in board.size:
		for col_key in board.size:
			if board[row_key][col_key] == null:
				open.append({
					'x': row_key,
					'y': col_key
				})

	# limit open spots to ones that should cause a flip
	var playable_open = []
	var check_position
	for arrow in tile.top:
		for position in open:
			check_position = get_coordinate_from_arrow(arrow, position)
			if board.has(check_position['x']) \
				and board[check_position['x']].has(check_position['y']) \
				and board[check_position['x']][check_position['y']] != null \
				and not playable_open.has(position):
				playable_open.append(position)

	# if there's no spots to play that will cause a flip, default to all empty spots
	if len(playable_open) == 0:
		open = playable_open

	# get a random open spot and put the tile there
	var where_to_play = open[randi() % len(open) - 1]
	board[where_to_play['x']][where_to_play['y']] = {
		'tile': tile,
		'side': 'top'
	}
	
# increases the given player's score by the specified amount
func add_to_player_score(player, new_points):
	if player == 1:
		var old_points = $Player1Score.text.to_int()
		var points = old_points + new_points
		$Player1Score.text = 'You: ' + points as String
	else:
		var old_points = $Player2Score.text.to_int()
		var points = old_points + new_points
		$Player2Score.text = 'Not You: ' + points as String

func play():
	# keep playing until the board is full
	var player = 1
	var tile
	var playable_open
	var check_position
	var where_to_play
	var open = board.get_empty_spots()
	while len(open) > 0:
		# get a tile from the current player
		tile = player1.pop() if player == 1 else player2.pop()

		# limit open spots to ones that should cause a flip
		playable_open = []
		for arrow in tile.top:
			for position in open:
				check_position = get_coordinate_from_arrow(arrow, position)
				if board.has(check_position['x']) \
					and board[check_position['x']].has(check_position['y']) \
					and board[check_position['x']][check_position['y']] != null \
					and not playable_open.has(position):
					playable_open.append(position)

		# if there's no spots to play that will cause a flip, default to all empty spots
		if len(playable_open) == 0:
			open = playable_open

		# get a random open spot and put the tile there
		where_to_play = open[randi() % len(open) - 1]
		board[where_to_play['x']][where_to_play['y']] = {
			'tile': tile,
			'side': 'top'
		}

		# print('board', $board);

		# do the flips
		flip_count = 0
		flip([where_to_play])
		if player == 1:
			player1Score += flip_count
		else:
			player2Score += flip_count

		if flip_count > 200:
			print('infinite!')
			break

		# switch which player will take a turn
		player = 2 if player == 1 else 1
		
		# get the empty spots again
		open = board.get_empty_spots()
