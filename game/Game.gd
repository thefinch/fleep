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

# sets up the board and the players to be able to start the game
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
	var flips = 0
	var tween
	var duration = 0.3
	var original_z
	
	# prevent some infinite scenarios by occasionally reversing the array
	if randf() > 0.5:
		tiles_that_flipped.reverse()
		
	for position in tiles_that_flipped:
		# get the tile at this position
		tile_at_position = board.get_tile_at_position(position['x'], position['y'])

		# figure out which side we're looking at
		var matrix = tile_at_position.top if tile_at_position.current_side == 'top' else tile_at_position.bottom
		for arrow in matrix:
			# flip tile if needed
			check_position = get_coordinate_from_arrow(arrow, position)
			tile_at_check_position = board.get_tile_at_position(check_position['x'], check_position['y'])
			if tile_at_check_position != null:
				prints('arrow', arrow, 'from position', position, 'is pointing to tile with', 'top', tile_at_check_position.top, 'and bottom', tile_at_check_position.bottom, 'and current side', tile_at_check_position.current_side)
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
				
#				original_z = tile_at_check_position.global_position.z
#				tween = create_tween()
#				tween.tween_property(tile_at_check_position, "global_position:z", tile_at_check_position.global_position.z + 1, duration)
#				await tween.finished

				map[arrow].call()
				
				prints('tile after', 'top', tile_at_check_position.top, 'bottom', tile_at_check_position.bottom, 'current side', tile_at_check_position.current_side)

#				tween = create_tween()
#				tween.tween_property(tile_at_check_position, "global_position:z", original_z, duration)
#				await tween.finished
			
				# add to the list of board positions to flip if necessary
				if not run_again.has(check_position):
					# increase score
					flips += 1                  
					
					# add it to the list of tiles that have been flipped
					run_again.append(check_position)
					
				print('')

	# make sure all animations have completed before we continue
	await get_tree().create_timer(1.0).timeout
	
	# update the player's score based on how many flips just happened
	var new_score = player1Score if player == 1 else player2Score
	new_score = new_score + flips
	set_player_score(player, new_score)
	
	# run again if needed
	if len(run_again) > 0:
		# check for infinite flips
		if flip_count > 100:
			print('probably going infinite')
			return

		flip_count += flips
		await flip(player, run_again)

	return

func make_ai_move():
	# get a tile from the opponent
	var tile = player2.pop_back()

	# get open spots
	var open = board.get_empty_boxes()
	
	# if there's no open spaces, then it's game over
	if len(open) == 0:
		print('game over')
		return
	
	# limit open spots to ones that should cause a flip
	var playable_open = []
	var check_position
	var check_tile
	for arrow in tile.top:
		for position in open:
			check_position = get_coordinate_from_arrow(arrow, position)
			check_tile = board.get_tile_at_position(check_position['x'], check_position['y'])
			if check_tile != null \
				and not playable_open.has(position):
				playable_open.append(position)
		
	# if there's no spots to play that will cause a flip, default to any empty spot
	if len(playable_open) == 0:
		playable_open = open
		
	# make it look like the AI is actually thinking
	await get_tree().create_timer(0.5).timeout

	# get a random open spot and put the tile there
	var where_to_play = playable_open[randi() % len(playable_open) - 1]
	var x = where_to_play['x']
	var y = where_to_play['y']
	var dropbox = board.get_box(x, y)
	
	# make it look like the AI is picking it up and moving it
	var camera = get_viewport().get_camera_3d()
	var screen_position = camera.unproject_position(tile.global_position)
	tile.face_camera(screen_position, 7)
	
	var duration = 0.5
	var tween = create_tween().set_parallel(true)
	tween.tween_property(tile, "global_position", dropbox.global_position, duration)
	await tween.finished
	
	# put the tile down to start flipping
	place_tile(tile, dropbox, x, y, 2)

func _input(event):
	# check if we need to reset the game
	if event is InputEventKey  \
		and event.pressed == false \
		and event.keycode == KEY_R:
			reset()
			return

	if event is InputEventKey  \
		and event.pressed == false \
		and event.keycode == KEY_A:
			make_ai_move()
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
		end_drag(tile)
		return

	# check if we need to start dragging
	var started = event is InputEventMouseButton \
		and event.is_pressed() \
		and event.button_index == MOUSE_BUTTON_LEFT 
	if started:
		tile.pick_up()
		return

	# check if we need to continue dragging
	var continued = event is InputEventMouseMotion \
					and tile.being_dragged
	if continued:
		tile.drag(event)
		return

func place_tile(tile, dropbox, x, y, player):
	print('placing tile for player', player)
	# stop the ability to place tiles
	if player == 1:
		make_player_tiles_unavailable()
		
	# update the board 
	tile.place_at(dropbox.global_position)
	board.set_tile_at_position(tile, x, y)
	
	# try to flip
	flip_count = 0
	await flip(player, [{'x': x, 'y': y}])
	
	# if this was the player's turn, not let the AI go
	if player == 1:
		await make_ai_move()
		make_player_tiles_available()

func make_player_tiles_available():
	for tile in player1:
		tile.draggable = true
	
func make_player_tiles_unavailable():
	for tile in player1:
		tile.draggable = false

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

		# play the game
		place_tile(tile, dropbox, x, y, 1)
		
		return
	
	tile.revert_position()

# gets the currently selected tile if there is one
func get_selected_tile():
	for tile in player1:
		if tile.mouse_over:
			return tile
	
	return null
