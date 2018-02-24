extends Node

const DEFAULT_PORT = 27015
const DEFAULT_IP = "83.254.45.109"
const MAX_PLAYERS = 16
const VERSION = "1.01"
const TICKRATE = 1 / 30

onready var player_scene = load("res://scenes/Player.tscn")

# DEBUG

var DEBUG = true

func print_debug(string):
	if DEBUG:
		print(string)

# Gamestate/player management

var players = {}

func create_player(id, local):
	var player = player_scene.instance()
	if not local:
		player.local = false
		player.get_node("Camera").queue_free()
		player.set_collision_layer_bit(1, false)
		player.set_collision_mask_bit(1, false)
		player.set_network_master(id)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	player.name = str(id)
	var current_scene = get_tree().current_scene
	current_scene.get_node("Players").add_child(player)
	if current_scene.has_node("World/spawnPoint"):
		player.transform.origin = current_scene.get_node("World/spawnPoint").transform.origin
	
	return player

remote func register_player(id):
	if get_tree().is_network_server():
		
		for player_id in players:
			rpc_id(id, "register_player", player_id)
			rpc_id(player_id, "register_player", id)
			
	players[id] = create_player(id, false)

sync func unregister_player(id):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

# Net functions

var host
func host_game(port, maxplayers):
	host = NetworkedMultiplayerENet.new()
	host.create_server(port, maxplayers)
	get_tree().set_network_peer(host)
	
	players[1] = create_player(1, true)
	
	print_debug(str("Started server with ", maxplayers, " players on port ", port))
	
func join_game(ip, port):
	host = NetworkedMultiplayerENet.new()
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	
	print_debug(str("Connected to server at ", ip, ":", port))
	
func _connected_ok():
	rpc("register_player", get_tree().get_network_unique_id())
	players[get_tree().get_network_unique_id()] = create_player(get_tree().get_network_unique_id(), true)

func _connected_fail():
	get_tree().set_network_peer(null)
	
func leave_game():
	print("Left game")
	host.close_connection()
	get_tree().current_scene.get_node("Players").queue_free()
	
remote func check_version(version):
	if version != VERSION:
		OS.alert(str("Wrong version! Server: ", version, " You: ", VERSION))
		get_tree().quit()
	
func _player_connected(id):
	if get_tree().is_network_server():
		rpc_id(id, "check_version", VERSION)
	
func _player_disconnected(id):
	if get_tree().is_network_server():
		rpc("unregister_player", id)
	
func _server_disconnected():
	if get_tree().current_scene.has_node("Players"):
		for player_id in players:
			unregister_player(player_id)
	
# Glue it all together	

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail") 
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	get_tree().connect("server_disconnected", self, "_server_disconnected")