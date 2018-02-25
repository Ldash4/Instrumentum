extends Node

const DEFAULT_PORT = 27015
const DEFAULT_IP = "83.254.45.109"
const MAX_PLAYERS = 16
const VERSION = "1.09"
const PLAYER_TICKRATE = 1 / 30
var last_player_tick = 0
const PROP_TICKRATE = 1 / 30
var last_prop_tick = 0

signal player_tick()
signal prop_tick()

onready var player_scene = load("res://scenes/Player.tscn")

# DEBUG

var DEBUG = true

func print_debug(string):
	if DEBUG:
		print(str("DEBUG | ", string))

# Player management

var players = {}

func create_player(id, local):
	var player = player_scene.instance()
	if not local:
		player.local = false
		player.get_node("Camera").queue_free()
		player.set_network_master(id)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	player.name = str(id)
	var current_scene = get_tree().current_scene
	current_scene.get_node("Players").add_child(player)
	if current_scene.has_node("World/spawnPoint"):
		player.transform.origin = current_scene.get_node("World/spawnPoint").transform.origin
	
	print_debug(str("Created player with ID: ", id))
	
	return player

remote func register_player(id):
	if get_tree().is_network_server():
		
		for player_id in players:
			if id != 1: # Don't send to the server (yourself)
				rpc_id(id, "register_player", player_id)
			rpc_id(player_id, "register_player", id)
			
	players[id] = create_player(id, false)
	
	print_debug(str("Player registered with ID: ", id))

sync func unregister_player(id):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
		
		print_debug(str("Player unregistered with ID: ", id))
		
# Net functions

var host
func host_game(port, maxplayers):
	host = NetworkedMultiplayerENet.new()
	host.create_server(port, maxplayers)
	get_tree().set_network_peer(host)
	
	players[1] = create_player(1, true)
	
	print_debug(str("Started server with ", maxplayers, " players on port ", port))
	OS.set_window_title(str("Instrumentum v", VERSION, " - HOST"))
	
func join_game(ip, port):
	host = NetworkedMultiplayerENet.new()
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	
	print_debug(str("Connected to server at ", ip, ":", port))
	OS.set_window_title(str("Instrumentum v", VERSION, " - CLIENT"))
	
func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id())
	players[get_tree().get_network_unique_id()] = create_player(get_tree().get_network_unique_id(), true)
	
	print_debug("Connection OK")

func _connected_fail():
	get_tree().set_network_peer(null)
	
	print_debug("Connecton failed")
	
func leave_game():
	host.close_connection()
	get_tree().current_scene.get_node("Players").queue_free()
	
	print_debug("Left game")
	
remote func check_version(version):
	if version != VERSION:
		OS.alert(str("Wrong version! Server: ", version, " You: ", VERSION))
		print_debug(str("Wrong version! Server: ", version, " You: ", VERSION))
		get_tree().quit()
	
func _player_connected(id):
	if get_tree().is_network_server():
		rpc_id(id, "check_version", VERSION)
	
	print_debug(str("Player connected with ID: ", id))
	
func _player_disconnected(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	
	print_debug(str("Player disconnected with ID: ", id))
	
func _server_disconnected():
	if get_tree().current_scene.has_node("Players"):
		for player_id in players:
			unregister_player(player_id)
			
	print_debug("Server disconnected")
	
# Glue it all together	

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail") 
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	print_debug("Game initialized")
	
func _process(delta):
	if get_tree().has_network_peer():
		last_player_tick += delta
		if last_player_tick >= PLAYER_TICKRATE:
			last_player_tick -= PLAYER_TICKRATE
			emit_signal("player_tick")
			
		last_prop_tick += delta
		if last_prop_tick >= PROP_TICKRATE:
			last_prop_tick -= PROP_TICKRATE
			emit_signal("prop_tick")