extends Node
class_name CommandParser
## Used to parse and interpert commands and arguments.


## Parses a command and it's arguments, if it has any, and executes them if they are valid.
func parse_command(
	command: String,
	ARGUMENTS_: PackedStringArray,
	permission: ConsoleDataManager.PermissionLevel,
	cheatsEnabled: bool
) -> String:
	if not ConsoleDataManager.COMMAND_LIST_.has(command):
		return "Command '" + command + "' does not exist."
	
	if not cheatsEnabled and ConsoleDataManager.COMMAND_LIST_[command]["cheats"]:
		return "Command requires cheats to be enabled."
	
	if permission < ConsoleDataManager.COMMAND_LIST_[command]["minPermission"]:
		return "Permission level too low to use this command."
	
	var response
	var TargetRef: Node = get_command_target(command)
	var method: String = ConsoleDataManager.COMMAND_LIST_[command]["method"]
	var METHOD_ARGUMENTS_: Array =\
		ConsoleDataManager.COMMAND_LIST_[command]["argumentList"]
	
	if not TargetRef:
		return "Could not find command target for '" + command + "'."
	
	# Check if command expects arguments
	if arguments_optional(METHOD_ARGUMENTS_, ARGUMENTS_):
		response = TargetRef.call(method)
		if response:
			return response
		return ""
	
	if ARGUMENTS_.size() > METHOD_ARGUMENTS_.size():
		return (
			"Too many arguments for command '"
			+ command
			+ "'. Expected "
			+ str(METHOD_ARGUMENTS_.size())
			+ ", but got "
			+ str(ARGUMENTS_.size())
			+ "." 
		)
	
	if not METHOD_ARGUMENTS_.is_empty() and ARGUMENTS_.is_empty():
		return (
			"Too few arguments for command '"
			+ command
			+ "'. Expected "
			+ str(METHOD_ARGUMENTS_.size())
			+ ", but got "
			+ str(ARGUMENTS_.size())
			+ "." 
		)
	
	var PARSED_ARGUMENTS_: Dictionary =\
		parse_argument_list(METHOD_ARGUMENTS_, ARGUMENTS_)
	
	if PARSED_ARGUMENTS_.has("invalidArgument"):
		return (
			"Invalid type for argument "
			+ str(PARSED_ARGUMENTS_["invalidArgument"] + 1)
			+ " expected '"
			+ type_string(
				METHOD_ARGUMENTS_[PARSED_ARGUMENTS_["invalidArgument"]]["type"]
			)
			+ "'."
		)
	
	response = TargetRef.callv(method, PARSED_ARGUMENTS_["argumentList"])
	if response:
		return response
	return ""


## Gets the reference to the command's target node or returns null if it's not found.
func get_command_target(command: String) -> Node:
	var target: String = ConsoleDataManager.COMMAND_LIST_[command]["target"]
	var type: int = ConsoleDataManager.COMMAND_LIST_[command]["type"]
	
	match type:
		ConsoleDataManager.CommandType.GLOBAL:
			return get_node("/root/" + target)
		
		ConsoleDataManager.CommandType.LOCAL:
			if target.is_empty():
				return get_parent()
			
			return get_tree().root.find_child(target, true , false)
	
	return null


## Checks if the command expects any arguments.
func arguments_optional(
	METHOD_ARGUMENTS_: Array,
	ARGUMENTS_: Array[String]
) -> bool:
	if not ARGUMENTS_.is_empty():
		return false
	
	if METHOD_ARGUMENTS_.is_empty():
		return true
	
	for ARGUMENT_ in METHOD_ARGUMENTS_:
		if not ARGUMENT_["optional"]:
			return false
	
	return true


## Parses the arguments for the command and converts them to appropriate type.
## Returns the index of the invalid argument if there are any.[br][br]
## [i]It only returns the first invalid argument if there are multiple.[/i]
func parse_argument_list(
	METHOD_ARGUMENTS_: Array,
	ARGUMENTS_: PackedStringArray
) -> Dictionary:
	var PARSED_ARGUMENTS_: Dictionary = {
		"argumentList": []
	}
	var i: int = 0
	var invalidArgument: int = -1
	
	for ARGUMENT_ in METHOD_ARGUMENTS_:
		var argument: String = ARGUMENTS_[i]
		# Type match and convert command argument to method argument
		invalidArgument = parse_argument_type(
			PARSED_ARGUMENTS_,
			int(ARGUMENT_["type"]),
			argument,
			i
		)
		if invalidArgument > -1:
			PARSED_ARGUMENTS_["invalidArgument"] = invalidArgument
			break
		
		if i == ARGUMENTS_.size() - 1:
			break
		
		i += 1
	
	return PARSED_ARGUMENTS_


## Type matches the argument provided and converts it to the expect type.
## Returns the index of the argument if it is invalid.
func parse_argument_type(
	PARSED_ARGUMENTS_: Dictionary,
	type: int,
	argument: String,
	i: int
) -> int:
	match type:
		TYPE_STRING:
			PARSED_ARGUMENTS_["argumentList"].append(argument)
		
		TYPE_INT:
			if argument.is_valid_int():
				PARSED_ARGUMENTS_["argumentList"].append(int(argument))
			else:
				return i
		
		TYPE_FLOAT:
			if argument.is_valid_float():
				PARSED_ARGUMENTS_["argumentList"].append(float(argument))
			else:
				return i
		
		TYPE_BOOL:
			match argument:
				"true":
					PARSED_ARGUMENTS_["argumentList"].append(true)
				"false":
					PARSED_ARGUMENTS_["argumentList"].append(false)
				_:
					return i
		
		TYPE_VECTOR2, TYPE_VECTOR2I:
			if argument[0] == "(" and argument[argument.length() - 1] == ")":
				var isIntOnly: bool = false if type == TYPE_VECTOR2 else true
				var AXISES_: PackedStringArray =\
					parse_vector(argument, 2, false)
				
				if AXISES_.is_empty():
					return i
				
				PARSED_ARGUMENTS_["argumentList"].append(
					Vector2(
						float(AXISES_[0]),
						float(AXISES_[1])
					) if type == TYPE_VECTOR2 else Vector2i(
						int(AXISES_[0]),
						int(AXISES_[1])
					)
				)
			else:
				return i
		
		TYPE_VECTOR3, TYPE_VECTOR3I:
			if argument[0] == "(" and argument[argument.length() - 1] == ")":
				var isIntOnly: bool = false if type == TYPE_VECTOR3 else true
				var AXISES_: PackedStringArray =\
					parse_vector(argument, 3, false)
				
				if AXISES_.is_empty():
					return i
				
				PARSED_ARGUMENTS_["argumentList"].append(
					Vector3(
						float(AXISES_[0]),
						float(AXISES_[1]),
						float(AXISES_[2])
					) if type == TYPE_VECTOR3 else Vector3i(
						int(AXISES_[0]),
						int(AXISES_[1]),
						int(AXISES_[2])
					)
				)
			else:
				return i
	
	return -1


## Parses vector arguments specifically.
func parse_vector(
	argument: String,
	axisCount: int,
	isIntOnly: bool
) -> PackedStringArray:
	argument = argument.trim_prefix("(")
	argument = argument.trim_suffix(")")
	var AXISES_: PackedStringArray = argument.split(",", false)
	
	if AXISES_.size() != axisCount:
		return []
	
	for axis in AXISES_:
		if isIntOnly:
			if not axis.is_valid_int():
				return []
		else:
			if not axis.is_valid_float():
				return []
	
	return AXISES_
