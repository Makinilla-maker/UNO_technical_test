extends Card

func execute_action(game_state):
	game_state._apply_draw_two(2)
