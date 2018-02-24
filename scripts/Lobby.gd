extends Control

func _on_host_pressed():
	Gamestate.print_debug("Clicked host")
	hide()
	Gamestate.host_game(Gamestate.DEFAULT_PORT, Gamestate.MAX_PLAYERS)

func _on_join_pressed():
	Gamestate.print_debug("Clicked join")
	hide()
	Gamestate.join_game(Gamestate.DEFAULT_IP, Gamestate.DEFAULT_PORT)
	
func _ready():
	get_node("Panel/Host").connect("pressed", self, "_on_host_pressed")
	get_node("Panel/Join").connect("pressed", self, "_on_join_pressed")