# Simply Console for Godot 4

Simply Console is an in-game console window focused on being usable by players not just the developer.

## Usage

Since the console is made to be accessible by players, it does not have the ability to execute arbitrary pieces of code. Instead, custom commands are used to execute existing methods from any object inside of the game.

The console can also be directly printed to to display errors, warnings or general messages.

## Current Features
- Custom commands to call set functions on any object

- <details><summary><b>Multiple argument type support</b></summary>
    <ul>
        <li>String</li>
        <li>int</li>
        <li>float</li>
        <li>bool</li>
        <li>Vector2 & Vector2i</li>
        <li>Vector3 & Vector3i</li>
        <li>Object</li>
    </ul>
</details>

- Object picker to get reference of objects being clicked on

- Keywords to access specific objects directly

- Permission levels and cheats to restrict command access

- Graphical editor plugin for creating and editing commands

- Print functions

- Command history

- Command suggestions

## Guides

- [Console](docs/console_guide.md)
- [Command Editor](docs/command_editor_guide.md)

## Notice

If you are upgrading from a version prior to `v1.3.0`, make sure to update your command list file as the command structure got reworked.

To update your command list:
- Go to the `Extras` tab in the command editor.
- Press the `Validate Command List` button. *This may spam the editor output.*
- Press the `Save` button.