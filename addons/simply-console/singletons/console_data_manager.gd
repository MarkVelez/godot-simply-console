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
		"args": [
			{
				"name": "command",
				"type": TYPE_STRING,
				"optional": true
			}
		]
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
		"args": [
			{
				"name": "arg1",
				"type": TYPE_INT,
				"optional": true
			},
			{
				"name": "arg2",
				"type": TYPE_STRING,
				"optional": true
			}
		]
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


func show_command_list(command: String = "") -> String:
	var response: String = "List of available commands:\n"
	
	if command == "":
		for cmd in COMMAND_LIST_:
			response += cmd + ", "
		
		return response.trim_suffix(", ")
	
	if COMMAND_LIST_.has(command):
		if COMMAND_LIST_[command]["args"] == null:
			return "'" + command + "' does not have any arguments."
		response = "Argument(s) for '" + command + "':\n"
		for ARG_ in COMMAND_LIST_[command]["args"]:
			response += ARG_["name"]
			if ARG_["optional"]:
				response += " (optional)"
			response += "\n"
		return response.trim_suffix("\n")
	
	return "Command '" + command + "' does not exist."
