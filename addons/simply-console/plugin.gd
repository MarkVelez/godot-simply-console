@tool
extends EditorPlugin

const CommandEditor: PackedScene =\
	preload("./scenes/command-editor/command_editor.tscn")

var CommandEditorRef: Window


func _enter_tree() -> void:
	add_tool_menu_item("Open Command Editor...", create_command_editor)
	add_autoload_singleton(
		"ConsoleDataManager",
		"/singletons/console_data_manager.gd"
	)


func _exit_tree() -> void:
	remove_tool_menu_item("Open Command Editor...")
	remove_autoload_singleton("ConsoleDataManager")


func create_command_editor() -> void:
	CommandEditorRef = CommandEditor.instantiate()
	EditorInterface.get_base_control().add_child(CommandEditorRef)
	CommandEditorRef.init_window()
