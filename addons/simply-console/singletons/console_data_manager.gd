extends Node

# GLOBAL = Singleton(Autorun)
# LOCAL = Scene Node
enum CommandType {
	GLOBAL,
	LOCAL
}

# Command list file location constants
const FILE: String = "command_list.json"
const DIRECTORY: String = "res://addons/simply-console/data/"
const PATH: String = DIRECTORY + FILE

var COMMAND_LIST_: Dictionary = {
	"help": {
		"target": "ConsoleDataManager",
		"type": CommandType.GLOBAL,
		"method": "show_command_list",
		"args": null
	},
	"clear": {
		"target": null,
		"type": CommandType.LOCAL,
		"method": "clear_console",
		"args": null
	},
	"test": {
		"target": "LocalNode",
		"type": CommandType.LOCAL,
		"method": "test_method",
		"args": null
	}
}


func _ready() -> void:
	# Verify the directory
	DirAccess.make_dir_absolute(DIRECTORY)
	
	if FileAccess.file_exists(PATH):
		call_deferred("get_data")
	else:
		save_data()
		push_warning("No command list file found.")


func save_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(COMMAND_LIST_, "\t"))
	file.close()


func get_data() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	COMMAND_LIST_ = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	# Check for issues with parsing
	if COMMAND_LIST_ == null:
		push_error("Failed to parse command list file.")
		return


func show_command_list() -> String:
	var list: String = "List of available commands:\n"
	
	for command in COMMAND_LIST_:
		list += command + ", "
	
	list.trim_suffix(", ")
	return list
