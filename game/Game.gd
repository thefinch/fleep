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
	randomize()
	
	reset()

func reset():
	get_tree().paused = true
	
	board.setup_board()
	setup_players()
	
	get_tree().paused = false

# figures out where to position the tile in the given player's hand
func get_tile_position_in_hand(player_number, tile_number):
	var y_offset_amount = 1200
	var y_offset = -y_offset_amount if player_number == 1 else y_offset_amount
	
	var x_offset = 600
	var x_offsets = {
		0: x_offset * -2,
		1: x_offset * -1,
		2: 0,
		3: x_offset,
		4: x_offset * 2
	}
	
	return Vector3(
		x_offsets[tile_number],
		y_offset,
		0
	)

# creates a tile and adds it to the given player's hand
func add_tile(player_hand, player_number, tile_number):
	# create the tile and add it to the player's hand array
	var new_tile = tile_scene.instantiate()
	var scale = 0.003
	new_tile.scale = Vector3(scale, scale, scale)
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
	# reset player scores
	set_player_score(1, 0)
	set_player_score(2, 0)

	# reset the players' hands
	for tile in player1:
		tile.queue_free()
	for tile in player2:
		tile.queue_free()
	player1 = []
	player2 = []

	# create our tiles
	tiles_per_hand = 5
	for tile_number in range(0, tiles_per_hand):
		add_tile(player1, 1, tile_number)
		add_tile(player2, 2, tile_number)

func set_player_score(player, score):
	if player == 1:
		player1Score = score
		$Player1Score.text = 'You: ' + str(player1Score)
	else:
		player2Score = score
		$Player2Score.text = 'Not You: ' + str(player2Score)

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
	
# flip all the tiles that tiles_that_flipped are pointing to, get the new list of 
func flip(player, tiles_that_flipped):
	var run_again = []
	var tile_at_position
	var check_position
	var tile_at_check_position
	for position in tiles_that_flipped:
		# get the tile at this position
		tile_at_position = board.get_tile_at_position(position['x'], position['y'])
		prints('tile', tile_at_position, 'at', position, 'was placed or flipped')
		prints('tile top', tile_at_position.top)
		print('tile bottom', tile_at_position.bottom)

		var matrix = tile_at_position.top if tile_at_position.current_side == 'top' else tile_at_position.bottom
		for arrow in matrix:
			check_position = get_coordinate_from_arrow(arrow, position)
			print('arrow ', arrow, ' is pointing at ', check_position)
			
			# flip tile if needed
			tile_at_check_position = board.get_tile_at_position(check_position['x'], check_position['y'])
			if tile_at_check_position != null:
				print('there is a tile at that position', tile_at_check_position)
				var map = {
					'UL': tile_at_check_position.up_left,
					'UR': tile_at_check_position.up_right,
					'DL': tile_at_check_position.down_left,
					'DR': tile_at_check_position.down_right,
					'U': tile_at_check_position.up,
					'D': tile_at_check_position.down,
					'L': tile_at_check_position.left,
					'R': tile_at_check_position.right,
				}
				map[arrow].call()
			
				# add to the list of board positions to flip if necessary
				if not run_again.has(check_position):
					# increase score
					flip_count += 1                  
					
					# add it to the list of tiles that have been flipped
					run_again.append(check_position)
					
			print('')

	# make sure all animations have completed before we continue
	await get_tree().create_timer(1.0).timeout
	
	# update the player's score based on how many flips just happened
	var new_score = player1Score if player == 1 else player2Score
	new_score = new_score + flip_count
	set_player_score(player, new_score)
	
	# run again if needed
	if len(run_again) > 0:
		# check for infinite flips
		if flip_count > 100:
			print('probably going infinite')
			return

		flip_count = 0
		flip(player, run_again)

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
		flip(player, [where_to_play])

		if flip_count > 200:
			print('infinite!')
			break

		# switch which player will take a turn
		player = 2 if player == 1 else 1
		
		# get the empty spots again
		open = board.get_empty_spots()

func _input(event):
	# check if we need to reset the game
	if event is InputEventKey  \
		and event.pressed == false \
		and event.keycode == KEY_R:
			reset()
			return

	# select a tile if it has been clicked on
	var clicked = event is InputEventMouseButton \
		and event.is_pressed() \
		and event.button_index == MOUSE_BUTTON_LEFT 
	if clicked:
		for tile in player1:
			if tile.mouse_over:
				tile.selected = true

	# get the selected tile
	var selected
	for tile in player1:
		if tile.selected:
			selected = tile
	
	if not selected:
		return
	
	# handle any input for the selected tile
	check_tile_movement(event, selected)
	check_rotate(event, selected)

# check if we need to rotate
# if so, do so
func check_rotate(event, tile):
	var keys_and_actions = {
		KEY_KP_9: tile.up_right,
		KEY_KP_7: tile.up_left,
		KEY_KP_8: tile.up,
		KEY_KP_2: tile.down,
		KEY_KP_4: tile.left,
		KEY_KP_6: tile.right,
		KEY_KP_1: tile.down_left,
		KEY_KP_3: tile.down_right,
		KEY_MINUS: tile.rotate_left,
		KEY_EQUAL: tile.rotate_right
	}
	
	for key in keys_and_actions:
		if event is InputEventKey  \
			and event.pressed \
			and event.keycode == key:
				keys_and_actions[key].call()

func check_tile_movement(event, tile):
	# only process input if needed
	if not tile.draggable:
		return

	# check if we need to stop dragging
	var stopped = tile.being_dragged \
		and event is InputEventMouseButton \
		and not event.is_pressed()
	if stopped:
		print('stopping drag')
		print('')
		end_drag(tile)
		return

	# check if we need to start dragging
	var started = event is InputEventMouseButton \
		and event.is_pressed() \
		and event.button_index == MOUSE_BUTTON_LEFT 
	if started:
		print('picked up')
		tile.pick_up()
		return

	# check if we need to continue dragging
	var continued = event is InputEventMouseMotion \
					and tile.being_dragged
	if continued:
		tile.drag(event)
		return

func end_drag(tile):
	# stop allowing this to be dragged around
	tile.being_dragged = false
	tile.selected = false
	
	# check if this is a valid drop location
	var dropboxes = tile.get_node('Area3D').get_overlapping_areas()
	if dropboxes.size() > 0:
		# put the tile in the box
		var dropbox = dropboxes[0].get_parent()
		var box_name = dropbox.get_name()
		var parts = box_name.split('_')
		var x = parts[0].to_int()
		var y = parts[1].to_int()
		
		# make sure there is not a tile there already
		var tile_in_spot = board.get_tile_at_position(x, y)
		if tile_in_spot:
			tile.revert_position()
			return

		# update the board 
		tile.place_at(dropbox.global_position)
		board.set_tile_at_position(tile, x, y)
		
		# try to flip
		flip_count = 0
		flip(1, [{'x': x, 'y': y}])
		
		return
	
	tile.revert_position()

# gets the currently selected tile if there is one
func get_selected_tile():
	for tile in player1:
		if tile.mouse_over:
			return tile
	
	return null
