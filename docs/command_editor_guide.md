# Command Editor Guide

The command editor is used to edit existing or add new commands to the console via a GUI found inside of the Godot editor. The command editor can be access by going to `Project > Tools > Open Command Editor...`.

## The command editor interface

When opening the command editor, you are greeted with multiple input fields used for creating a new and or editing an existing command. Each field has a description of what it is used for when hovering over them.

- `Command List` is a list of all the existing commands. If the `<new>` option is selected a new command can be created, while selecting an existing command will let you edit that command.

- `Command Name` is the name that will be used inside of the console to call the command.

- `Minimum Permission` let's you set a minimum permission requirement to use the command allowing the restriction of commands. Permission levels are hierarchical so a higher level permission will have the access to commands from the permission levels below it. If you want to add or change a permission level, you can do so by going to `singletons/console_data_manager.gd` and changing the `PermissionLevel` enum. *The player's permission level is stored in the console window and can be changed as needed.*

- `Requires Cheats` let's you decide if the command requires cheats to be enabled to use.

- `Requires Keyword` let's you decide if the command only works if used with a keyword. If you want to know how to add keywords, refer to the [Console Guide](console_guide.md#using-and-adding-keywords). *Leaving this unchecked will still allow you to use keywords with the command.*

- `Target Name` is the name of the target node. The name has to be an exact match otherwise the command will not work. Optionally this field can be left empty which will directly reference the console window.

- `Target Method` is the method, i.e., function which will be called from the target node. This as well has to be an exact match otherwise the command will not work.


## Adding/Editing commands

To create a new command, you first have to have the `<new>` optional selected from the `Command List`. Afterwhich you can fill out the rest of the fields as explained before. Once you are done, you can pressed the `Add Command` button at the bottom.

*As of `v1.3.0`, command arguments are retrived dynamically from the target method. This is so one command can be used to call the same method on different objects with the help of keywords. Methods that have arguments with unsupported types will not work. [List of support types](../README.md#current-features)*

To edit an existing command, you can select the command you wish to edit from the `Command List`. Once doing so, the rest of the fields will be filled with the information corresponding to the selected command. After you have tweaked the command you can finalize the edit by pressing the `Edit Command` button, alternatively if you wish to completely delete the command you can press the `Remove Command` button.

To save all the changes made to the command list, press the `Save` button at the bottom of the command editor window. This will save the command list to a json file, which can be found under `addons/simply-console/data`.

## Using batch edit

The batch edit tab in the command editor lets you edit or remove multiple commands at once. It has less options to edit compared to editing individual commands, otherwise it works functionally the same as the normal editor.

On the left side of the editor is the list of all the commands. To select multiple commands you can hold `Ctrl` or `Shift`. Once you have the commands you wish to edit or remove selected, you can change the options you wish on the right side of the editor and then press the `Edit Commands` button. If you want to remove the selected commands, you can press the `Remove Commands` button.

To save all the changes made to the command list, press the `Save` button at the bottom of the command editor window. This will save the command list to a json file, which can be found under `addons/simply-console/data`.