extends Node
class_name CommandParser
## Used to parse and interpert commands and arguments.


## Parses a command and it's arguments, if it has any, and executes them if they are valid.
func parse_command(
	command: String,
	arguments_: Array,
	keyword: String,
	permission: Console.PermissionLevel,
	cheatsEnabled: bool
) -> String:
	if not Console.COMMAND_LIST_.has(command):
		return "Command '" + command + "' does not exist."
	
	if keyword and not Console.keywordList_.has(keyword):
		return "Keyword '" + keyword + "' does not exist."
	
	if not cheatsEnabled and Console.COMMAND_LIST_[command]["cheats"]:
		return "Command requires cheats to be enabled."
	
	if permission < Console.COMMAND_LIST_[command]["minPermission"]:
		return "Permission level too low to use this command."
	
	var TargetRef: Node = get_command_target(command, keyword)
	if not TargetRef:
		if keyword:
			return "Keyword '" + keyword + "' does not have a reference."
		if Console.COMMAND_LIST_[command]["requiresKeyword"]:
			return "Command '" + command + "' does not exist in global scope."
		return "Could not find command target for '" + command + "'."
	
	var method: String = Console.COMMAND_LIST_[command]["method"]
	if not method_exists(TargetRef, method):
		return (
			"Command '"
			+ command
			+ "' does not exist in '"
			+ TargetRef.get_name()
			+ "'."
		)
	
	var methodArguments_: Array[Dictionary] =\
		get_method_arguments(TargetRef, method)
	if not validate_method_arguments(methodArguments_):
		return "Arguments of target method has unsupported argument type(s)."
	
	var response
	var optionalCount: int = arguments_optional(methodArguments_, arguments_)
	
	# Check if command expects arguments
	if optionalCount == -1:
		response = TargetRef.call(method)
		if response:
			return str(response)
		return ""
	
	if arguments_.size() > methodArguments_.size():
		return (
			"Too many arguments for command '"
			+ command
			+ "'. Expected "
			+ str(methodArguments_.size())
			+ ", but got "
			+ str(arguments_.size())
			+ "." 
		)
	
	if (
		not methodArguments_.is_empty()
		and arguments_.size() < methodArguments_.size() - optionalCount
	):
		return (
			"Too few arguments for command '"
			+ command
			+ "'. Expected "
			+ str(methodArguments_.size())
			+ ", but got "
			+ str(arguments_.size())
			+ "." 
		)
	
	var parsedArguments_: Dictionary =\
		parse_argument_list(methodArguments_, arguments_)
	
	if parsedArguments_.has("invalidArgument"):
		return (
			"Invalid type for argument "
			+ str(parsedArguments_["invalidArgument"] + 1)
			+ " expected '"
			+ type_string(
				methodArguments_[parsedArguments_["invalidArgument"]]["type"]
			)
			+ "'."
		)
	
	response = TargetRef.callv(method, parsedArguments_["argumentList"])
	if response:
		return str(response)
	return ""


## Gets the reference to the command's target node or returns null if it's not found.
func get_command_target(command: String, keyword: String = "") -> Node:
	var target: String = Console.COMMAND_LIST_[command]["target"]
	
	if keyword.is_empty():
		if Console.COMMAND_LIST_[command]["requiresKeyword"]:
			return null
		
		if target.is_empty():
			return get_parent()
		
		var NodeRef: Node = get_node_or_null("/root/" + target)
		if NodeRef == null:
			return get_tree().root.find_child(target, true , false)
		return NodeRef
	else:
		if Console.keywordList_.has(keyword):
			return Console.keywordList_[keyword]
	
	return null


func get_method_arguments(
	TargetRef: Node,
	commandMethod: String
) -> Array[Dictionary]:
	var methodArguments_: Array = []
	var defaultValues_: Array = []
	for method in TargetRef.get_method_list():
		if method["name"] == commandMethod:
			methodArguments_ = method["args"]
			defaultValues_ = method["default_args"]
			break
	
	var argumentList_: Array[Dictionary] = []
	for i in range(methodArguments_.size()):
		var argumentInfo_: Dictionary = methodArguments_[i]
		var argument_: Dictionary = {}
		argument_ = {
			"name": argumentInfo_["name"],
			"type": argumentInfo_["type"]
		}
		
		if i >= methodArguments_.size() - defaultValues_.size():
			argument_["default"] = defaultValues_[i - defaultValues_.size()]
		
		argumentList_.append(argument_)
	
	return argumentList_


## Checks if the target method's arguments are supported.
func validate_method_arguments(methodArguments_: Array[Dictionary]) -> bool:
	const VALID_TYPES_: PackedInt32Array = [
		TYPE_STRING,
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
		TYPE_OBJECT
	]
	for argument_ in methodArguments_:
		if not VALID_TYPES_.has(argument_["type"]):
			return false
	
	return true


## Checks if the target has the command method.
func method_exists(TargetRef: Node, method: String) -> bool:
	if not TargetRef.has_method(method):
		return false
	
	return true


## Checks if the command expects any arguments.
func arguments_optional(
	methodArguments_: Array[Dictionary],
	arguments_: Array
) -> int:
	if methodArguments_.is_empty() and arguments_.is_empty():
		return -1
	
	var optionalCount: int = 0
	for argument_ in methodArguments_:
		if not argument_.has("default"):
			continue
		optionalCount += 1
	
	if (
		arguments_.is_empty()
		and optionalCount == methodArguments_.size()
	):
		return -1
	
	return optionalCount


## Parses the arguments for the command and converts them to appropriate type.
## Returns the index of the invalid argument if there are any.[br][br]
## [i]It only returns the first invalid argument if there are multiple.[/i]
func parse_argument_list(
	methodArguments_: Array[Dictionary],
	arguments_: Array
) -> Dictionary:
	var parsedArguments_: Dictionary = {
		"argumentList": []
	}
	var i: int = 0
	var invalidArgument: int = -1
	
	for argument_ in methodArguments_:
		var argument: String = arguments_[i]
		# Type match and convert command argument to method argument
		invalidArgument = parse_argument_type(
			parsedArguments_,
			int(argument_["type"]),
			argument,
			i
		)
		if invalidArgument > -1:
			parsedArguments_["invalidArgument"] = invalidArgument
			break
		
		if i == arguments_.size() - 1:
			break
		
		i += 1
	
	return parsedArguments_


## Type matches the argument provided and converts it to the expect type.
## Returns the index of the argument if it is invalid.
func parse_argument_type(
	parsedArguments_: Dictionary,
	type: int,
	argument: String,
	i: int
) -> int:
	match type:
		TYPE_STRING:
			parsedArguments_["argumentList"].append(argument)
		
		TYPE_INT:
			if argument.is_valid_int():
				parsedArguments_["argumentList"].append(int(argument))
			else:
				return i
		
		TYPE_FLOAT:
			if argument.is_valid_float():
				parsedArguments_["argumentList"].append(float(argument))
			else:
				return i
		
		TYPE_BOOL:
			match argument:
				"true":
					parsedArguments_["argumentList"].append(true)
				"false":
					parsedArguments_["argumentList"].append(false)
				_:
					return i
		
		TYPE_VECTOR2, TYPE_VECTOR2I:
			if argument[0] == "(" and argument[argument.length() - 1] == ")":
				var isIntOnly: bool = false if type == TYPE_VECTOR2 else true
				var axises_: PackedStringArray =\
					parse_vector(argument, 2, false)
				
				if axises_.is_empty():
					return i
				
				parsedArguments_["argumentList"].append(
					Vector2(
						float(axises_[0]),
						float(axises_[1])
					) if type == TYPE_VECTOR2 else Vector2i(
						int(axises_[0]),
						int(axises_[1])
					)
				)
			else:
				return i
		
		TYPE_VECTOR3, TYPE_VECTOR3I:
			if argument[0] == "(" and argument[argument.length() - 1] == ")":
				var isIntOnly: bool = false if type == TYPE_VECTOR3 else true
				var axises_: PackedStringArray =\
					parse_vector(argument, 3, false)
				
				if axises_.is_empty():
					return i
				
				parsedArguments_["argumentList"].append(
					Vector3(
						float(axises_[0]),
						float(axises_[1]),
						float(axises_[2])
					) if type == TYPE_VECTOR3 else Vector3i(
						int(axises_[0]),
						int(axises_[1]),
						int(axises_[2])
					)
				)
			else:
				return i
		
		TYPE_OBJECT:
			if Console.keywordList_.has(argument):
				parsedArguments_["argumentList"].append(
					Console.keywordList_[argument]
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
	var axises_: PackedStringArray = argument.split(",", false)
	
	if axises_.size() != axisCount:
		return []
	
	for axis in axises_:
		if isIntOnly:
			if not axis.is_valid_int():
				return []
		else:
			if not axis.is_valid_float():
				return []
	
	return axises_
