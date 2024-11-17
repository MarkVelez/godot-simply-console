# Console Guide

## Setting up the console

First, you want to enable the plugin by going to `Project > Project Settings > Plugins` and then look for `Simply Console`. After this you will want to reload your project. *If you see errors pop up when you first install the plugin, that is to be expected, just enable the plugin and reload your project.*

**Note:** As of `v1.4.0`, the console has been made "global", i.e., it is now persistent between scenes as it is added as a child of the console manager singleton. If you wish to keep using instances of the console, you can go to the `console_manager.gd` script which can be found at `addons/simply-console/singletons/`. Here you can change `GLOBAL_CONSOLE` to `false`. *The console will still be easily accessible through the `Console` singleton.*

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

To print to the console you can use the following functions through the `Console` singleton:
- `output_text()`
- `output_error()`
- `output_warning()`
- `output_comment()`

For `output_text()`, you can optionally pass a custom color as well. As for the rest they function the same, but they have predefined colors, i.e., **red for error**, **yellow for warning** and **grey for comment**.

If you want to get the reference to the console window itself, you can do so using `Console.ConsoleRef`.

## Using and adding keywords

Keywords represent an object thus they can be used to call commands directly on a specific object. To call a command using a keyword you can use `<keyword>.<command>` similar to how objects work in code. Alternatively, keywords can also be used as a command argument, which will pass the reference of the object that the keyword is representing.

Currently, adding keywords has to be done via code, but is very easy to do. Keywords, and the reference of the object that they are representing, are stored in the `Console` singleton inside of the `keywordList_` dictionary. To add a keyword and its reference, you can use `Console.keywordList_[<keyword>] = <reference>`.
