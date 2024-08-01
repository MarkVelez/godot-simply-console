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
func process_input_text(text: String) -> PackedStringArray:
	var processedText_: PackedStringArray = []
	# Ignore leading and trailing whitespace
	text = text.strip_edges()
	var next: int = text.find(" ")
	var previous: int = next
	
	# Check if no arguments were inputted
	if next == -1:
		processedText_.append(text)
		return processedText_
	
	# Append the command to the start of the array
	processedText_.append(text.substr(0, next))
	
	# Get the remaining arguments
	while next != -1:
		# Check the next character
		match text[next + 1]:
			# Extract the contents of long strings which are in quotes
			"\"":
				var start: int = next + 2
				var end: int = text.find("\"", start)
				processedText_.append(text.substr(start, end - start))
				previous = end + 1
			# Extract vectors and remove spaces
			"(":
				var start: int = next + 1
				var end: int = text.find(")", start)
				var content: String = text.substr(start, end - start + 1)
				content = content.replace(" ", "")
				processedText_.append(content)
				previous = end + 1
			# Extract a normal argument
			_:
				var start: int = next + 1
				var end: int = text.find(" ", start)
				if end == -1:
					end = text.length()
				processedText_.append(text.substr(start, end - start))
				previous = end
		
		# Go to the next argument
		next = text.find(" ", previous)
	
	return processedText_
