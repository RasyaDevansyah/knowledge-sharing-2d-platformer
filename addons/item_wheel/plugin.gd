@tool
extends EditorPlugin
## Registers the ItemWheel custom node type while the plugin is enabled and
## removes it again on disable, leaving no residue behind.


func _enter_tree() -> void:
	add_custom_type(
		"ItemWheel",
		"Control",
		preload("item_wheel.gd"),
		preload("icons/item_wheel_icon.svg")
	)


func _exit_tree() -> void:
	remove_custom_type("ItemWheel")
