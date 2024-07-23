@tool
extends EditorPlugin

const CommandEditor: PackedScene =\
	preload("res://addons/simply-console/scenes/command_editor.tscn")

var CommandEditorRef: Window


func _enter_tree() -> void:
	add_tool_menu_item("Open Command Editor...", create_command_editor)


func _exit_tree() -> void:
	remove_tool_menu_item("Open Command Editor...")


func create_command_editor() -> void:
	CommandEditorRef = CommandEditor.instantiate()
	EditorInterface.get_base_control().add_child(CommandEditorRef)
	CommandEditorRef.init_window()
