# uevrlib

### How to use
This is a LUA library designed to help UEVR mod developers perform common tasks. To use, place the libs folder and the example files in the scripts directory of your game's profile. For example, for Outer Worlds it would look like<br/>

-AppData<br/>
&nbsp;&nbsp;&nbsp;-Roaming<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-UnrealVRMod<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-Indiana-Win64-Shipping<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-scripts<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-lib<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;example_devtools.lua<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;etc...<br/>

The library comes with several examples. The files that begin with "example_" would normally not be included in your shipping mod, only the lib folder and its contents are required. To test an example, rename the file from ".luax" to ".lua" and name the other examples files to ".luax"

### Examples
#### Example: Devtools
Rename the file "example_devtools" as "example_devtools.lua" if required and rename all other examples to ".luax"<br/>

When Show Advanced Options is checked in the UEVR UI, a new tab labeled Dev Utils will appear at the bottom.<br/>

The Static Mesh Viewer tool finds all of the Static Mesh objects currently available in the level and displays that list in a dropdown. Selecting an item from the list or pressing the forward or backward arrows will create a copy of that Static Mesh in your left hand. Note that some meshes are one-sided so it may require that you rotate your left hand at various angles to see the mesh. Rarely, some meshes may not be visible at all and you will have to select another.<br/>

To show only a subset of available meshes, use the Filter text entry box to enter a search string. Capitalization matters. The mesh list will refresh when a level changes but if more meshes are added while in a level, press the Refresh button to update the list. Below the mesh list you will see the total number of Static Meshes found in the level and the number of meshes listed based on the filter.<br/>

In the UI section you can change the scale of the object in your hand. By default the meshes will be resized to fit in your hand and you can adjust that size with the Scale Adjust slider. If you want to see the mesh at its native in-game scale, check the "Show at native scale" check box. Be aware that with this checkbox checked, the meshes can be extremely large or small.<br/>

When a mesh is selected, in addition to showing it in your hand, the information about the mesh will be printed to the console so that you can do additional searches for it in the ObjectHook UEVR UI.<br/>

![Screenshot 2025-07-08 100446](https://github.com/user-attachments/assets/257227f6-a548-417e-b081-4accf3b47989)

<br/><br/><hr>

#### Example: Config
Rename the files "example_config_1", "example_config_2", "example_config_3" to ".lua" and rename all other examples to ".luax"<br/>

The uevrlib comes with a way to define imgui widget layouts using json instead of coding them by hand. This functionality can be used across multiple lua files and each file can access the other's widgets. This allows for modular code design where a general purpose feature can be developed with it's own config UI and then integrated into other modder's projects without interfering with the modder's code but giving the modder access to the config values if needed. The example files show how multiple files can define their own configuration tabs but access each others settings as needed.<br/>

The file "example_config_1.lua" contains examples of many of the json defined widgets available. For more information on using the config ui features see the comments in /libs/configui.lua<br/>

<br/><br/><hr>

#### Example: Controllers
Rename the file "example_controllers" as "example_controllers.lua" if required and rename all other examples to ".luax"<br/>

Attaching objects to VR controllers is one of the most common tasks in UEVR modding. The controllers example when run, will attach a cube to your left hand controller and a sphere to your right hand controller. If run in Outer Worlds it will also attach a HUD widget to your HMD. In other games you can specify you own widget for attachment.

<br/><br/><hr>

#### Example: Debug Dump
Rename the file "example_debug_dump" as "example_debug_dump.lua" if required and rename all other examples to ".luax"<br/>

The uevrlib comes with a powerful debug dumper that can dump runtime objects, tables and structures to the console or log. "example_debug_dump.lua" shows 4 ways to use the dumper by pressing F1-F4. More info can be found in /libs/uevr_debug.lua

<br/><br/><hr>

#### Example: Flicker Fixer
Rename the file "example_flicker_fixer" as "example_flicker_fixer.lua" if required and rename all other examples to ".luax"<br/>

UEVR has a bug in some games that causes the left eye to flicker after some amount of time. Flicker Fixer is designed to help mitigate this problem in games that have the issue. It comes with its own config ui for setting various params
