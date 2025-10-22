@tool
extends EditorPlugin

var _script := preload("res://addons/display_vector3d/DisplayVector3D.gd")
var _icon := preload("res://addons/display_vector3d/icon.svg")

func _enter_tree() -> void:
	add_custom_type("DisplayVector3D", "Node3D", _script, _icon)

func _exit_tree() -> void:
	remove_custom_type("DisplayVector3D")
