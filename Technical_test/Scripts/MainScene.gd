extends Node2D

# Definition of turn states for clarity in game control.
const TurnState = Globals.TurnState

# Exported variables and initial game configurations.
export(PackedScene) var card_scene
export(PackedScene) var card_scene_p2
export(PackedScene) var card_scene_skip
var turn_indicator
var starting_cards = 5
var card_width = 80
var separation_between_cards = 30
var AI_separation_y = 100
var rng = RandomNumberGenerator.new()
var game_state = TurnState.PLAYER
var last_game_state = TurnState.PLAYER

# Game state variables.
var uno_deck
var last_card
var screen_width
var screen_height
var total_width : float
var ai_turn_in_progress = false  # Variable to track the AI's turn progress
var skip_used : bool = false
var player_uno_announced : bool = false
var AI_uno_announced : bool = false

# Game initialization, setting dimensions and creating the initial deck.
func _ready():
	# Initialize the turn indicator and start the game.
	turn_indicator = $TurnIndicator
	_startGame()

# Set up the game by initializing variables and creating initial cards for the player and the AI.
func _startGame():
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	total_width = (card_width * starting_cards) + (separation_between_cards * (starting_cards - 1))
	uno_deck = _build_deck()
	$UNOSign.connect("uno_finished", self, "_on_uno_updated")
	if card_scene:
		# Position player cards
		_position_cards($PlayerCards, screen_height)
		# Position AI cards
		_position_cards($AICards, AI_separation_y)
		_set_first_card()
		_change_state(TurnState.PLAYER)

# Build the initial deck of cards, with numbered and special cards.
func _build_deck():
	var unoDeck = {}
	for color in Globals.CardColors.values():
		unoDeck[color] = {}
		unoDeck[color]["+2"] = {"color": color, "number": +2, "type": "+2"}
		unoDeck[color]["Ø"] = {"color": color, "number": -1, "type": "skip"}
		for cardNumber in range(10):
			unoDeck[color][str(cardNumber)] = {"color": color, "number": cardNumber, "type": "normal"}
	return unoDeck

# Function to get a random card from the deck.
func _get_card():
	rng.randomize()
	# Create a list of available cards to get their information.
	var available_cards = []
	for color in uno_deck.keys():
		for number in uno_deck[color].keys():
			available_cards.append([color, number, uno_deck[color][number].type])
	
	# If there are no more cards in the deck, disable the draw button.
	if available_cards.size() == 1:
		$DrawButton.disabled = true
	
	# Choose a random card and remove it from the actual deck.
	var chosen_card = available_cards[rng.randi_range(0, available_cards.size() - 1)]
	var card_color = chosen_card[0]
	var card_number = chosen_card[1]
	var card_type = chosen_card[2]
	uno_deck[card_color].erase(card_number)
	if uno_deck[card_color].empty():
		uno_deck.erase(card_color)
	return [card_number, card_color, card_type]

# Draw a card and place it according to the player requesting it.
func _draw_card(container, position, canSee):
	var card_info = _get_card()
	# Once the card is selected, it is instantiated in the scene.
	var card_instance
	match card_info[2]:
		"normal":
			card_instance = card_scene.instance()
		"+2":
			card_instance = card_scene_p2.instance()
		"skip":
			card_instance = card_scene_skip.instance()
	
	# Assign values to the card.
	card_instance._set_card_info(card_info[0], Globals.CardColors.values()[card_info[1]], card_info[2], canSee)
	
	# Update its position and add it to the corresponding container.
	card_instance.position = position
	container.add_child(card_instance)
	# Connect the card press signal if it is not the central one.
	if container != $Last_cart:
		card_instance.connect("card_pressed", self, "_on_Card_pressed")
	return card_instance

# Set the first card of the game in the center of the screen.
func _set_first_card():
	# Calculate the central position of the screen.
	var start_x = (screen_width / 2)
	var y_position = (screen_height / 2)
	last_card = _draw_card($Last_cart, Vector2(start_x, y_position), true)
	last_card.set_block_signals(true)
	last_card.set_process(false)

# Create initial cards for the player and strategically place them.
func _get_player_cards():
	_position_cards($PlayerCards, screen_height)

# Create initial cards for the AI and strategically place them.
func _get_AI_cards():
	_position_cards($AICards, AI_separation_y)

# Helper function to position cards initially for both the player and the AI.
func _position_cards(container, y_position):
	# Calculate the total size occupied by the cards, including the separation between them.
	var total_width = starting_cards * card_width + (starting_cards - 1) * separation_between_cards
	# Calculate the initial position of the first card.
	var start_x = screen_width / 2 - total_width / 2 + card_width / 2
	for n in range(starting_cards):
		# Adjust the initial position of each card to make them centered.
		var x_position = start_x + (card_width + separation_between_cards) * n
		_draw_card(container, Vector2(x_position, y_position), container == $PlayerCards)

# Update the position of the cards according to the viewport size.
func _update_cards_position():
	var viewport_size = get_viewport_rect().size
	# Save the screen size.
	screen_width = viewport_size.x
	screen_height = viewport_size.y
	var containers = [$PlayerCards, $AICards]
	# Update the position of the last played card.
	last_card.position = Vector2(screen_width / 2, screen_height / 2)
	# Iterate over the containers of the player and AI cards.
	for container in containers:
		var child_count = container.get_child_count()
		
		# Adjust the Y position according to the type of player (container).
		var y_position = 100
		if container == containers[0]:
			y_position = screen_height - 150
		
		# Victory and defeat conditions.
		if child_count == 0:
			if container == $PlayerCards:
				_change_state(TurnState.WIN)
				$PlayAgain._ended_game("YOU\nWIN")
			if container == $AICards:
				_change_state(TurnState.LOSE)
				$PlayAgain._ended_game("You\nlose....")
			pass
		
		# Recalculate the total size based on the cards in the container.
		var total_width = child_count * card_width + (child_count - 1) * separation_between_cards
		# Temporary and individual separation to not modify the total separation that would affect both players.
		var card_separation = separation_between_cards
		# If the total size is greater than the screen width minus a predefined margin, adjust the temporary separation to make the cards closer together.
		if total_width > screen_width - 200:
			card_separation = (screen_width - 200 - (child_count * card_width)) / (child_count - 1)
			total_width = child_count * card_width + (child_count - 1) * card_separation
		# Calculate the initial position of the first card.
		var start_x = screen_width / 2 - total_width / 2 + card_width / 2
		# Iterate over the container's children to adjust their new position.
		for i in range(child_count):
			var child = container.get_child(i)
			child.position.x = start_x + (card_width + card_separation) * i
			child.position.y = y_position

# Count the total number of cards in the deck.
func _get_total_cards():
	var total_cards = 0
	for color in uno_deck.keys():
		total_cards += uno_deck[color].size()
	return total_cards

# Verify if the played card is valid and update the game state.
func _check_if_play(card):
	if (card.number == last_card.number or card.color == last_card.color):
		# If the card is special, execute its action.
		if card.card_type != "normal":
			if card.card_type == "+2" && _get_total_cards() <= 1:
				return false
			card.execute_action(self)
		# Put the last card back into the deck before changing it.
		if not uno_deck.has(last_card.color):
			uno_deck[last_card.color] = {}
		uno_deck[last_card.color][str(last_card.number)] = {
			"color": last_card.color,
			"number": last_card.number,
			"type": last_card.card_type
		}
		
		# If the draw button is disabled, re-enable it because there are new cards.
		if $DrawButton.disabled == true:
			$DrawButton.disabled = false
		
		# Assign the values of the played card as the new central card.
		last_card._set_card_info(card.number, card.color, card.card_type, true)
		# Remove the played card.
		card.queue_free()
		return true
	return false

# Apply the action of drawing two cards.
func _apply_draw_two(number):
	var container
	var canSee : bool = true
	# Check which player this card is targeting.
	if (game_state == TurnState.PLAYER):
		# Reset the variable so the UNO signal can appear again.
		AI_uno_announced = false
		container = $AICards
		canSee = false
	elif (game_state == TurnState.AI):
		player_uno_announced = false
		container = $PlayerCards
	
	# Add the cards to the corresponding player's container.
	for i in number:
		var child = container.get_child(0)
		var card = _draw_card(container, Vector2(0, child.position.y), canSee)

# Apply the action of skipping a turn.
func _apply_skip():
	skip_used = true

# Handle the event when a card is pressed.
func _on_Card_pressed(card):
	if game_state == TurnState.PLAYER:
		var check : bool = _check_if_play(card)
		if check:
			_change_state(TurnState.AI)

# The AI chooses a card to play.
func _choose_card():
	var possible_cards = $AICards.get_children()
	for card in possible_cards:
		if _check_if_play(card):
			return true
	return false

# Manage the AI turn system.
func _AI_turn():
	# Create a timer and wait for it to expire.
	yield(get_tree().create_timer(1.0), "timeout")
	if game_state == TurnState.WIN || game_state == TurnState.LOSE:
		return
	# Once the timer expires, continue execution.
	var has_played = _choose_card()
	if not has_played:
		# If no card can be played, draw a card. But first check if it can draw, otherwise pass the turn
		if _get_total_cards() > 0:
			var child = $AICards.get_child(0)
			var card = _draw_card($AICards, Vector2(0, child.position.y), false)
	AI_uno_announced = false
	# Change the state to player.
	_change_state(TurnState.PLAYER)
	
	ai_turn_in_progress = false  # Reset the variable after processing the AI turn.

# Manage the game based on the turn state, including AI turns and victory condition checks.
func _process(delta):
	match game_state:
		TurnState.AI:
			if not ai_turn_in_progress:
				ai_turn_in_progress = true 
				_AI_turn()
		TurnState.UNO_AI:
			_AI_uno_pick()
		TurnState.UNO_PLAYER:
			_AI_uno_pick()
	
	# Update the position of the cards.
	_update_cards_position()
	
	if game_state != TurnState.WAITING:
		_check_if_uno()

# The AI enters a mode to press the UNO button before the player (has a cooldown of 0.75 seconds).
func _AI_uno_pick():
	# Start the timer.
	$UNOSign._start()
	_change_state(TurnState.WAITING)
	yield(get_tree().create_timer(0.75), "timeout")
	# Finish the timer.
	$UNOSign._finish()
	# Call the function to check who pressed the button.
	if last_game_state == TurnState.UNO_PLAYER || last_game_state == TurnState.UNO_AI:
		_on_uno_updated(false)

# Update the UNO state based on whether the button was pressed.
func _on_uno_updated(pressed):
	# If the button was pressed by the player and not the AI.
	if last_game_state == TurnState.UNO_PLAYER:
		if pressed == false:
			var child = $PlayerCards.get_child(0)
			_draw_card($PlayerCards, Vector2(0, child.position.y), true)
			player_uno_announced = false
		_change_state(TurnState.AI)
	# If the button was pressed by the AI.
	elif last_game_state == TurnState.UNO_AI:
		if pressed == true:
			var child = $AICards.get_child(0)
			_draw_card($AICards, Vector2(0, child.position.y), false)
			AI_uno_announced = false
		_change_state(TurnState.PLAYER)

# Change the game state.
func _change_state(state):
	if not skip_used:
		last_game_state = game_state
		game_state = state
		# Send the current state to the turn indicator, and it changes position according to the turn.
		turn_indicator.update_position(game_state)
	else:
		skip_used = false

# Check if a player or the AI has only one card and update the state to UNO.
func _check_if_uno():
	if $PlayerCards.get_children().size() == 1 and not player_uno_announced:
		player_uno_announced = true
		_change_state(TurnState.UNO_PLAYER)
	elif $AICards.get_children().size() == 1 and not AI_uno_announced:
		AI_uno_announced = true
		_change_state(TurnState.UNO_AI)

# Handle the event when the button to draw a card is pressed.
func _on_Button_pressed():
	if game_state == TurnState.PLAYER:
		var child = $PlayerCards.get_child(0)
		var card = _draw_card($PlayerCards, Vector2(0, child.position.y), true)
		player_uno_announced = false
		_change_state(TurnState.AI)
