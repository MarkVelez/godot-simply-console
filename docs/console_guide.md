# Console Guide

## Setting up the console

First, activate the plugin as it will create an autorun script which is used to access the list of commands that the console can use.

Once you have activate the plugin, you can create an instance of the console window, which can be found under `scenes/console_window.tscn`, inside of your game scene.
*The console window is not persistent between scenes so you will have to add an instance to each scene you want to have it in.*

The console has built in limits for responses, character count and command history to save memory. These limits can be adjusted if needed by opening the console window scene and adjusting the `MAX_RESPONSES`, `MAX_CHAR_COUNT` and `MAX_COMMAND_HISTORY` variables respectively. *Note that MAX_RESPONSES limits the amount of paragraphs inside of the console which includes '\n' as well, so its possible for a single response to take up multiple response slots. This is however accounted for when trimming the contents of the console so the limit will never be surpassed.*

Lastly, you will want to add a way to show the console like pressing the ` key, which is standard in most games with a console.

## Using the console

The structure for commands is `<command>` `<arguments>`. The command and arguments are separated by a single space. If you want to add custom commands, refer to the [Command Editor](command_editor_guide.md) guide

To print to the console you can use the following functions:
- `output_text()`
- `output_error()`
- `output_warning()`
- `output_comment()`

For `output_text()`, you can optionally pass a custom color as well. As for the rest they function the same, but they have predefined colors, i.e. **red for error**, **yellow for warning** and **grey for comment**.