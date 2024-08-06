# Simply Console for Godot 4

Simply Console is an in-game console window focused on being usable by players not just the developer.

## Usage

Since the console is made to be accessible by players, it does not have the ability to execute arbitrary pieces of code. Instead, custom commands are used to execute existing methods from any object inside of the game.

The console can also be directly printed to to display errors, warnings or general messages.

## Planned features

- Command hints and suggestion
- In-Game object picker to get references

## Guides

- [Console](docs/console_guide.md)
- [Command Editor](docs/command_editor_guide.md)

## Notice

If you are upgrading from `v1.0.0` to `v1.1.0`, make sure to update your command list file as there are two new attributes for commands.

To update your command list:
- Go to the `Batch Edit` tab in the command editor.
- Press the `Select All` button.
- Press the `Edit Commands` button.
- Press the `Save` button.

If you also want the new built in command, go to the `Extras` tab and press the `Restore Built-In Commands` button. *This will restore ***all*** built in commands.*