# Console Guide

## Setting up the console

First, activate the plugin as it will create an autorun script which is used to access the list of commands that the console can use.

Once you have activate the plugin, you can create an instance of the console window, which can be found under `scenes/console_window.tscn`, inside of your game scene.
*The console window is not persistent between scenes so you will have to add an instance to each scene you want to have it in.*

The console has built in limits for responses, character count and command history to save memory. These limits can be adjusted if needed by opening the console window scene and adjusting the `MAX_RESPONSES`, `MAX_CHAR_COUNT` and `MAX_COMMAND_HISTORY` variables respectively. *Note that MAX_RESPONSES limits the amount of paragraphs inside of the console which includes '\n' as well, so its possible for a single response to take up multiple response slots. This is however accounted for when trimming the contents of the console so the limit will never be surpassed.*

Lastly, you will want to add a way to show the console like pressing the ` key, which is standard in most games with a console.

### For Godot 4.2 users

The method used to limit the amount of responses has been changed in Godot 4.3 as it had a bug that I have worked around previously, but this bug now is fixed. If you are using v1.1.1 on Godot 4.2, `disable BBCode` on the `OutputField` of the `Console Window` otherwise the first response will never get removed. Additionally, you may want to increase the max reponse limit by one as the number of displayed responses will be one less than what is defined.

## Using the console

The structure for commands is `<command> <arguments>`. The command and arguments are separated by a single space. String arguments can be written as one word or inside of quotes which will let you use spaces in the text. Vector arguments are written the same as in code, i.e., (x, y), and spaces will be ignored inside of the parentheses.

When typing a command into the console, if it is a valid command, command suggestions will show up. The suggestion list has a limit of five suggestions, which can be changed inside of the `CommandSuggestions` script by changing the value of `MAX_SUGGESTIONS`. When there are more valid suggestions than the max amount, the remaining suggestions are cached and an indicator arrow will appear at the top of the suggestion list. You can navigate the suggestion list by using the up and down arrows or by clicking on a suggestion. When clicking on a selected suggestion or pressing enter when a suggestion is selected, that suggestion will be copied to the input field. The suggestion list can be dismissed by either clicking away from it or pressing the escape button, this will also make it so it wont appear again until the current command is submitted.

The console comes with three build in commands:
- `help` shows all **accessible** commands. Optionally a command can be added as an argument which will show the arguments for the command. *Accessible means that the player has an adequate permission level and or has cheats enabled if it is required.*

- `clear` clears the console window.

- `cheats` lets you toggle cheats by passing **true** or **false** as an argument. *By default this command has no access restriction.*

If you want to add custom commands, refer to the [Command Editor](command_editor_guide.md) guide.

To print to the console you can use the following functions:
- `output_text()`
- `output_error()`
- `output_warning()`
- `output_comment()`

For `output_text()`, you can optionally pass a custom color as well. As for the rest they function the same, but they have predefined colors, i.e., **red for error**, **yellow for warning** and **grey for comment**.

## Using and adding keywords

Keywords represent an object thus they can be used to call commands directly on a specific object. To call a command using a keyword you can use `<keyword>.<command>` similar to how objects work in code. Alternatively, keywords can also be used as a command argument, which will pass the reference of the object that the keyword is representing.

Currently, adding keywords has to be done via code, but is very easy to do. Keywords, and the reference of the object that they are representing, are stored in the `ConsoleDataManager` inside of the `keywordList_` dictionary. To add a keyword and its reference, you can use `ConsoleDataManager.keywordList_[<keyword>] = <reference>`.


## Using the object picker

The object picker is an addon for the console that can be used to retrieve the reference of objects that are clicked on while the console is open. Once an object is selected, a message is shown in the console containing the reference and how to access it. To access the object that was selected the `this` keyword can be used.

To add the object picker to your scene, simply search for `ObjectPicker` when adding a new node to the scene. **Do not put the object picker as a child of the console window otherwise it may not work properly.** Once added to the scene, you will have to provide the reference to the console window and optionally select the scene type, i.e., 2D or 3D. If the `Fixed Scene Type` is left `Unknown` the object picker will attempt to dynamically determine the scene type by retrieving the currently active camera.

The object picker currently only works on `PhysicsBodies` and everything else will not be pickable. It also requires that the scene have an active camera as it is used to cast the mouse position onto the game world.