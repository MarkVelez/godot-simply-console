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

- Keywords to access specific objects directly

- Permission levels and cheats to restrict command access

- Graphical editor plugin for creating and editing commands

- <details><summary><b>Module system with included modules</b></summary>
    <ul>
        <li>Object Picker</li>
        <li>Property Viewer</li>
    </ul>
</details>

- Print functions

- Command history

- Command suggestions

## Guides

- [Console](docs/console_guide.md)
- [Command Editor](docs/command_editor_guide.md)
- [Module System](docs/module_system.md)