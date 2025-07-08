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
Name example_devtools as "example_devtools.lua" and rename all other examples to ".luax"![Screenshot 2025-07-08 100446](https://github.com/user-attachments/assets/257227f6-a548-417e-b081-4accf3b47989)
![Screenshot 2025-07-08 100446](https://github.com/user-attachments/assets/c5afbdd4-1e9d-4270-afde-6f25278cfe7f)
