tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("IProp", "Spatial", preload("IProp.gd"), preload("IProp.png"))

func _exit_tree():
	remove_custom_type("IProp")