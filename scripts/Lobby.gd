extends Control

func is_valid_port(port):
	return int(port) and int(port) < 65536
	
func show_error(error):
	$Panel/Error.text = error
		

func _on_host_pressed():

	if not is_valid_port($Panel/Port.text):
		show_error("Invalid port.")
		return
		
	Gamestate.host_game(int($Panel/Port.text), Gamestate.MAX_PLAYERS)
	hide()		

func _on_join_pressed():
	if not $Panel/IP.text.is_valid_ip_address():
		show_error("Invalid IP address.")
		return
		
	if not is_valid_port($Panel/Port.text):
		show_error("Invalid port.")
		return

	Gamestate.join_game($Panel/IP.text, int($Panel/Port.text))
	hide()
	
func _ready():
	get_node("Panel/Host").connect("pressed", self, "_on_host_pressed")
	get_node("Panel/Join").connect("pressed", self, "_on_join_pressed")