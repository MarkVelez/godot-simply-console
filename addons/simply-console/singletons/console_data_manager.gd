@tool
extends Node

# Permissions to restrict commands
enum PermissionLevel {
	NONE,
}

# Command list file location constants
const FILE: String = "command_list.json"
const DIRECTORY: String = "res://addons/simply-console/data/"
const PATH: String = DIRECTORY + FILE

var COMMAND_LIST_: Dictionary
var keywordList_: Dictionary


func _ready() -> void:
	# Verify the directory
	DirAccess.make_dir_absolute(DIRECTORY)
	
	# Check if the command list file exists
	if FileAccess.file_exists(PATH):
		# Stop automatically loading data in the editor
		if not Engine.is_editor_hint():
			call_deferred("get_data")
	else:
		COMMAND_LIST_ = get_built_in_commands()
		save_data()
		push_warning("No command list file found.")


func get_built_in_commands() -> Dictionary:
	return {
		"help": {
			"target": "",
			"minPermission": PermissionLevel.NONE,
			"cheats": false,
			"requiresKeyword": false,
			"method": "show_command_list"
		},
		"clear": {
			"target": "",
			"minPermission": PermissionLevel.NONE,
			"cheats": false,
			"requiresKeyword": false,
			"method": "clear_console"
		},
		"cheats": {
			"target": "",
			"minPermission": PermissionLevel.NONE,
			"cheats": false,
			"requiresKeyword": false,
			"method": "toggle_cheats"
		},
	}


func save_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(COMMAND_LIST_, "\t", false))
	file.close()


func get_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	COMMAND_LIST_ = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	# Check for issues with parsing
	if COMMAND_LIST_ == null:
		push_error("Failed to parse command list file.")
		return
