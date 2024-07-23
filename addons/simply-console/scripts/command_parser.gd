extends Node
class_name CommandParser


func parse_command(command: String, ARGUMENTS_: Array = []) -> String:
	if not ConsoleDataManager.COMMAND_LIST_.has(command):
		return "Command '" + command + "' does not exist."
	
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
			+ str(PARSED_ARGUMENTS_["invalidArgument"])
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


func arguments_optional(METHOD_ARGUMENTS_: Array, ARGUMENTS_: Array) -> bool:
	if not ARGUMENTS_.is_empty():
		return false
	
	if METHOD_ARGUMENTS_.is_empty():
		return true
	
	for ARGUMENT_ in METHOD_ARGUMENTS_:
		if not ARGUMENT_["optional"]:
			return false
	
	return true


func parse_argument_list(METHOD_ARGUMENTS_: Array, ARGUMENTS_: Array) -> Dictionary:
	var PARSED_ARGUMENTS_: Dictionary = {
		"argumentList": []
	}
	var i: int = 0
	var invalidArgument: int = 0
	
	for ARGUMENT_ in METHOD_ARGUMENTS_:
		var argument: String = ARGUMENTS_[i]
		
		match int(ARGUMENT_["type"]):
			TYPE_STRING:
				PARSED_ARGUMENTS_["argumentList"].append(argument)
			
			TYPE_INT:
				if argument.is_valid_int():
					PARSED_ARGUMENTS_["argumentList"].append(int(argument))
				else:
					invalidArgument = i + 1
					break
			
			TYPE_FLOAT:
				if argument.is_valid_float():
					PARSED_ARGUMENTS_["argumentList"].append(float(argument))
				else:
					invalidArgument = i + 1
					break
		
		if i == ARGUMENTS_.size() - 1:
			break
		
		i += 1
		
	if invalidArgument > 0:
		PARSED_ARGUMENTS_["invalidArgument"] = invalidArgument
	
	return PARSED_ARGUMENTS_
