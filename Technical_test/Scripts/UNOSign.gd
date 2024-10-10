extends Node2D

# Signal to indicate that the UNO action has ended.
signal uno_finished(_pressed)

# Function to start the sign, scale it according to the size of the viewport and start the timer.
func _start():
	# Make the sign visible.
	$".".set_visible(true)
	
	# Get the size of the viewport.
	var viewport_size = get_viewport_rect().size
	
	# Target dimensions for scaling.
	var target_width = 1920  # Target width (you can adjust this value according to your needs).
	var target_height = 1080  # High target (you can adjust this value according to your needs).
	
	# Calculate the scale based on the size of the viewport.
	var scale_x = viewport_size.x / target_width
	var scale_y = viewport_size.y / target_height
	
	# Choose the minimum scale to maintain proportion.
	var scale_factor = min(scale_x, scale_y)
	
	# Apply the scale and center the sign.
	$".".scale = Vector2(scale_factor, scale_factor)
	$".".position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	
	# Start the timer.
	$Timer.start()

# Function to end the UNO action.
func _finish():
	# Stop the timer.
	$Timer.stop()
	# Make the sign invisible.
	$".".set_visible(false)

# Function that is called when the timer runs out.
func _on_Timer_timeout():
	# Emit the signal indicating that the button was not pressed.
	emit_signal("uno_finished", false)
	# End the UNO action.
	_finish()

# Function that is called when the button is pressed.
func _on_Button_pressed():
	# Emit the signal indicating that the button was pressed.
	emit_signal("uno_finished", true)
	# End the UNO action.
	_finish()
