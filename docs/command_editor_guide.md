# Command Editor Guide

The command editor is used to edit existing or add new commands to the console via a GUI found inside of the Godot editor. The command editor can be access by going to `Project > Tools > Open Command Editor...`.

## The command editor interface

When opening the command editor, you are greeted with multiple input fields used for creating a new and or editing an existing command. Each field has a description of what it is used for when hovering over them.

- `Command List` is a list of all the existing commands. If the `<new>` option is selected a new command can be created, while selecting an existing command will let you edit that command.

- `Command Name` is the name that will be used inside of the console to call the command.

- `Command Type` determines what type of target the command has.
  - **GLOBAL** is used for autoload targets.
  - **LOCAL** is used for targets inside of the game scene. LOCAL commands look through the whole game scene until they find their target, therefore they can be significantly slower compared to GLOBAL commands as they have a direct reference to their target. To minimize the performance hit, try to move the command target to as close to the scene root as possible and avoid nesting. Alternatively an intermediate node can be used as the target which will propagate the call to the appropriate node.

- `Target Name` is the name of the target node. The name has to be an exact match otherwise the command will not work. Optionally this field can be left empty which will directly reference the console window.

- `Target Method` is the method i.e. function which will be called from the target node. This as well has to be an exact match otherwise the command will not work.

- `Command Arguments` is the list of arguments for the command. These correspond to the arguments of the target method. Arguments are also stored sequentually so the order has to be the same as the order in the target method. Each argument also has three fields:
  - **Argument Name** is purely visual and does not have to match what is in the target method. It can also be left empty, however I advise againts doing so as it can be used as a short descriptor of what the argument is used for.
  - **Argument Type** is the type of value the argument expects. Currently the support types are: String, Int, Float, Bool and Vector2/3 as well as their Int only counterparts. Vectors are constructed with parenthesis and the values are separated via a comma. Whitespace is not ignored inside of a Vector so **(1, 2)** would be counted as two separate arguments.
  - **Optional** is a toggle to make the argument optional. When making an argument optional you also have to assign a default value to the corresponding argument inside of the target method.


## Adding/Editing commands

To create a new command, you first have to have the `<new>` optional selected from the `Command List`. Afterwhich you can fill out the rest of the fields as explained before. Once you are done, you can pressed the `Add Command` button at the bottom.

To edit an existing command, you can select the command you wish to edit from the `Command List`. Once doing so, the rest of the fields will be filled with the information corresponding to the selected command. After you have tweaked the command you can finalize the edit by pressing the `Edit Command` button, alternatively if you wish to completely delete the command you can press the `Remove Command` button.

To save all the changes made to the command list, press the `Save` button at the bottom of the command editor window. This will save the command list to a json file, which can be found under `addons/simply-console/data`.