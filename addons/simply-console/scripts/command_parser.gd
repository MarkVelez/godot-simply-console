extends Node
class_name CommandParser


func parse_command(command: String, ARGS_: Array = []) -> String:
	if not ConsoleDataManager.COMMAND_LIST_.has(command):
		return "Command '" + command + "' does not exist."
	
	var response
	var TargetRef: Node = get_command_target(command)
	var method: String = ConsoleDataManager.COMMAND_LIST_[command]["method"]
	var METHOD_ARGS_: Array = ConsoleDataManager.COMMAND_LIST_[command]["args"]
	
	if not TargetRef:
		return "Could not find command target for '" + command + "'."
	
	# Check if command expects arguments
	if args_optional(METHOD_ARGS_, ARGS_):
		response = TargetRef.call(method)
		if response:
			return response
		return ""
	
	if ARGS_.size() > METHOD_ARGS_.size():
		return (
			"Too many arguments for command '"
			+ command
			+ "'. Expected "
			+ str(METHOD_ARGS_.size())
			+ ", but got "
			+ str(ARGS_.size())
			+ "." 
		)
	
	if not METHOD_ARGS_.is_empty() and ARGS_.is_empty():
		return (
			"Too few arguments for command '"
			+ command
			+ "'. Expected "
			+ str(METHOD_ARGS_.size())
			+ ", but got "
			+ str(ARGS_.size())
			+ "." 
		)
	
	var PARSED_ARGS_: Dictionary = parse_args(METHOD_ARGS_, ARGS_)
	
	if PARSED_ARGS_.has("invalidArg"):
		return (
			"Invalid type for argument "
			+ str(PARSED_ARGS_["invalidArg"])
			+ " expected '"
			+ type_string(METHOD_ARGS_[PARSED_ARGS_["invalidArg"]]["type"])
			+ "'."
		)
	
	response = TargetRef.callv(method, PARSED_ARGS_["args"])
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


func args_optional(METHOD_ARGS_: Array, ARGS_: Array) -> bool:
	if not ARGS_.is_empty():
		return false
	
	if METHOD_ARGS_.is_empty():
		return true
	
	for ARG_INFO_ in METHOD_ARGS_:
		if not ARG_INFO_["optional"]:
			return false
	
	return true


func parse_args(METHOD_ARGS_: Array, ARGS_: Array) -> Dictionary:
	var PARSED_ARGS_: Dictionary = {
		"args": []
	}
	var i: int = 0
	var invalidArg: int = 0
	
	for ARG_INFO_ in METHOD_ARGS_:
		var receivedArg: String = ARGS_[i]
		
		match int(ARG_INFO_["type"]):
			TYPE_STRING:
				PARSED_ARGS_["args"].append(receivedArg)
			
			TYPE_INT:
				if receivedArg.is_valid_int():
					PARSED_ARGS_["args"].append(int(receivedArg))
				else:
					invalidArg = i + 1
					break
			
			TYPE_FLOAT:
				if receivedArg.is_valid_float():
					PARSED_ARGS_["args"].append(float(receivedArg))
				else:
					invalidArg = i + 1
					break
		
		if i == ARGS_.size() - 1:
			break
		
		i += 1
		
	if invalidArg > 0:
		PARSED_ARGS_["invalidArg"] = invalidArg
		return PARSED_ARGS_
	
	return PARSED_ARGS_
