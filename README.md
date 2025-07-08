# uevrlib

This is a LUA library designed to help UEVR mod developers perform common tasks. To use, place the libs folder and the example files in the scripts directory of your game's profile. For example, for Outer Worlds it would look like
-AppData
  -Roaming
    -UnrealVRMod
      -Indiana-Win64-Shipping
        -scripts
          -lib
          example_devtools.lua
          etc...

The library comes with several examples. The files that begin with "example_" would normally not be included in your shipping mod, only the lib folder and its contents are required. To test an example, rename the file from ".luax" to ".lua" and name the other examples files to ".luax"

Example Devtools
Name example_devtools as "example_devtools.lua" and rename all other examples to ".luax"
When Show Advanced Options is checked in the UEVR UI, a new tab labeled Dev Utils will apeear at the bottom.
The Static Mesh Viewer tool finds all of the Static Mesh objects currently available in the level and displays that list in a dropdown. Selecting an item from the list or pressing the forward or backward arrows will create a copy of that Static Mesh in your left hand. Note that some meshes are one-sided so it may require that you rotate your left hand at various angles to see the mesh. Rarely, some meshes may not be visible at all and you will have to select another. To show only a subset of available meshes, use the Filter text entry box to enter a search string. Capitalization matters. The mesh list will refresh when a level changes but if more meshes are added while in a level, press the Refresh button to update the list. Below the mesh list you will see the total number of Static Meshes found in the level and the number of meshes listed based on the filter. In the UI section you can change the scale of the object in your hand. By default the meshes will be resized to fit in your hand and you can adjust that size with the Scale Adjust slider. If you want to see the mesh at its native in-game scale, check the "Show at native scale" check box. Be aware that with this checkbox checked, the meshes can be extremely large or small. When a mesh is selected, in addition to showing it in your hand, the information about the mesh will be printed to the console so that you can do additional searches for it in the ObjectHook UEVR UI.
![Screenshot 2025-07-08 100446](https://github.com/user-attachments/assets/257227f6-a548-417e-b081-4accf3b47989)

