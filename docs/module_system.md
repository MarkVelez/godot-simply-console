# Module System

The module system is new as of `v1.4.0` and it allows you to add extra functionality or helpful utility to the console directly.

## Adding modules to the console

When you open up the `console_window.tscn` scene and select the `ConsoleWindow` node, if you look at the inspector, you will see the `Module List` property. You can add the scenes of the modules that you wish to use with the console. The module scenes can be found at `addons/simply-console/modules/`.

## Creating a module

All modules extend from the `ConsoleModule` class as it connects the modules with the console window. The root node of the module's scene has to be a `Control` type node, however that doesn't mean that the module has to be visible, e.g., the object picker module.

The console will call the `_module_init()` method when loading the modules, so prefer using this for setting up your module over `_ready()`, `_enter_tree()` or `_init()` when possible to avoid loading issues. The console itself can also be accessed through `ConsoleRef` inside of the module.

Optionally, you can change how the module reacts to the console window being closed/opened by overwriting the `on_console_toggle()` method. By default, this method hides the shows the module with the console as well as disable its processing.

# Included Modules

## Object Picker

The object picker is a module for the console that can be used to retrieve the reference of objects that are clicked on while the console is open. Once an object is selected, a message is shown in the console containing the reference and how to access it. To access the object that was selected the `this` keyword can be used.

The object picker currently only works on `PhysicsBodies` and everything else will not be pickable. It also requires that the scene have an active camera as it is used to cast the mouse position onto the game world.

The object picker tries to determine the current scene type using the active camera type. You can however set a fixed scene type in the inspector by changing the value of `Fixed Scene Type` if you know that the scene type won't change or leave it at `Unknown` otherwise.

## Property Tracker

The property tracker is a module that will display user defined properties, i.e, variables, of a selected object. It integrates directly with the object picker module, so the property list will automatically updated when a new object is selected using it. However, it does not require the object picker module as you can also pass the reference of the object you wish to track using the same command that is used to toggle the module which is `property_tracker`.

By default, the property tracker is persistent, meaning that the property tracker will continue showing and working even if the console is closed. You can change the persitence with the `property_tracker` command.

To toggle the property tracker, as mentioned before, the `property_tracker` command can be used. This command is automatically added when the module is loaded and can't be edited in the command editor. If you wish to change the command name or permissions you will have to change it in `property_tracker.gd`. *Calling the command with arguments will not toggle the module if it is already enabled.*