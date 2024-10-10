extends Node2D

# Function to update the position of the shift indicator based on the shift status.
func update_position(state):
	match state:
		Globals.TurnState.PLAYER:
			position = Vector2(100, get_viewport_rect().size.y - 150)
		Globals.TurnState.AI: 
			position = Vector2(get_viewport_rect().size.x - 150, 50)
