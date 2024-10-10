extends Node2D
class_name Card

var number = 3
var color
var canSee : bool = true
var card_type : String = ""  # For special cards, such as “+2”, “skip”, etc.

signal card_pressed(card_info)

#Function to configure the chart in general: color, number, chart type, if visible.
func _set_card_info(_number, _color, _type, _flag):
	number = _number
	color = _color
	card_type = _type
		
	var button = $Button
	var style_normal = _change_color(_color)
	button.add_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = style_normal.bg_color + (Color(1, 1, 1) - style_normal.bg_color) * 0.4
	button.add_stylebox_override("hover", style_hover)
	_can_see(_flag)

#Configure the chart depending on whether it is viewable or not
func _can_see(flag): 
	if flag == true:
		$Label.text = str(number)
		$Label2.text = str(number)
	elif canSee:
		$Button.disabled = true
		$Label.text = ""
		$Label2.text = ""
	pass

#Configure the material of the chart according to its color
func _change_color(_color):
	var style_normal = StyleBoxFlat.new()
	match _color:
		0:
			style_normal.bg_color = Color(1, 0, 0)  # Red background
		1:
			style_normal.bg_color = Color(0, 1, 0)  # Green background
		2:
			style_normal.bg_color = Color(0, 0, 1)  # Blue background
		3:
			style_normal.bg_color = Color(1, 1, 0)  # Yellow background
	
	return style_normal

#Function to be used by the child cards such as +2, skip, etc...
func execute_action(game_state):
	pass

#In case you press the button, it will send a signal to the scene to perform the appropriate procedures.
func _on_Button_pressed():
	emit_signal("card_pressed", self)

#These two functions are used to show the card above the others in case they are stacked.
func _on_Button_mouse_entered():
	self.z_index = 1

func _on_Button_mouse_exited():
	self.z_index = 0
