extends Node
class_name CommandLexer
## A simple lexer for processing command strings.
##
## The lexer does not actually construct tokens instead it simply splits up the
## received string into segements which then the parser can use directly.
## [br][br]
## [i]This is done because the command structure is not complicated enough to
## warrant using entire tokens and it also minimizes the performance impact of the lexer.[/i]


## Processes the provided text for the parser to use.
func process_input_text(text: String, partial: bool = false) -> Dictionary:
	var processedText_: Dictionary = {
		"command": "",
		"arguments": [],
		"keyword": ""
	}
	# Ignore leading whitespace
	text = text.strip_edges(true, false)
	var next: int = text.find(" ")
	var previous: int = next
	
	# Append the command to the start of the array
	var command: String = text.substr(0, next)
	if command.contains("."):
		processedText_["keyword"] = command.substr(0, command.find("."))
	processedText_["command"] = command.substr(command.find(".") + 1, next)
	
	# Get the remaining arguments
	while next != -1:
		if next + 1 == text.length():
			if partial:
				processedText_["arguments"].append(null)
			return processedText_
		
		# Check the next character
		match text[next + 1]:
			# Extract the contents of long strings which are in quotes
			"\"":
				var start: int = next + 2
				var end: int = text.find("\"", start)
				
				if end == -1:
					if partial:
						processedText_["arguments"].append(null)
					return processedText_
				
				processedText_["arguments"].append(
					text.substr(start, end - start)
				)
				previous = end + 1
			# Extract vectors and remove spaces
			"(":
				var start: int = next + 1
				var end: int = text.find(")", start)
				
				if end == -1:
					if partial:
						processedText_["arguments"].append(null)
					return processedText_
				
				var content: String = text.substr(start, end - start + 1)
				content = content.replace(" ", "")
				processedText_["arguments"].append(content)
				previous = end + 1
			# Extract a normal argument
			_:
				var start: int = next + 1
				var end: int = text.find(" ", start)
				
				if end == -1:
					end = text.length()
				
				processedText_["arguments"].append(
					text.substr(start, end - start)
				)
				previous = end
		
		# Go to the next argument
		next = text.find(" ", previous)
	
	return processedText_
