extends Node

var prop_scenes = {}

func load_props():
	var prop_iterator = Directory.new()
	
	prop_iterator.change_dir("res://props")
	prop_iterator.list_dir_begin(true, true)
	var prop_folder = prop_iterator.get_next()
	
	while prop_folder != "":
		if prop_iterator.file_exists(str("res://props/", prop_folder, "/", prop_folder, ".tscn")):
			prop_scenes[prop_folder] = load(str("res://props/", prop_folder, "/", prop_folder, ".tscn"))
			Gamestate.print_debug(str("Found prop: ", prop_folder))
		else:
			Gamestate.print_debug(str("Did not find prop: ", prop_folder))
		
		prop_folder = prop_iterator.get_next()

func instanciate_prop(prop_name, position, id):
	if prop_scenes.has(prop_name):
		Gamestate.print_debug(str("Created instance of prop: ", prop_name))
		var prop = prop_scenes[prop_name].instance()
		prop.name = str(id)
		prop.prop_name = prop_name
		get_tree().current_scene.get_node("Props").add_child(prop)
		prop.translation = position
		return prop
	else:
		Gamestate.print_debug(str("Tried to create instance of unknown prop: ", prop_name))

var props = {}

remote func create_prop(prop_name, position, id):
	props[id] = instanciate_prop(prop_name, position, id)
	return props[id]

remote func request_prop(prop_name, position):
	if get_tree().is_network_server():
		var id = 0
		while props.has(id):
			id += 1
			
		Gamestate.print_debug(str("Creating prop ", prop_name,  " at ", position, " with id ", id))
		rpc("create_prop", prop_name, position, id)
		create_prop(prop_name, position, id)
	else:
		Gamestate.print_debug(str("Asking server to create prop ", prop_name,  " at ", position))
		rpc_id(1, "request_prop", prop_name, position)
		
# Glue

func _ready():
	load_props()






