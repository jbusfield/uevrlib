# uevrlib
A Lua based helper library for UEVR

### Contributors
The following have provided code, ideas and inspiration to this project: Pande4360, qwizdek, markmon, DJ, Mutar, CJ117, Ashok, Rusty Gere and lobotomy

### How to use
This is a Lua library designed to help UEVR mod developers perform common tasks. To use, place the libs folder and the example files in the scripts directory of your game's profile. For example, for Outer Worlds it would look like<br/>

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
- [Controllers](docs/controllers.md)
- [Hands](https://github.com/jbusfield/hands_tutorial_uevr)
- [Reticules](docs/reticule.md)
- [Config UI](docs/configui.md)
- [Developer Tools](docs/dev_tools.md)
- [Flicker Fixer](docs/flicker_fixer.md)
- [Debug Dump](docs/debug_dump.md)




