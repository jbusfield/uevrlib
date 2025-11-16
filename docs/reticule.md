## Reticules

### Using the Reticule Config Tool
Add the uevrlib libs folder to your scripts folder. Rename example_reticule_wizard.luax to example_reticule_wizard.lua or create a file in your scripts folder with this code
```
local uevrUtils = require('libs/uevr_utils')
local reticule = require("libs/reticule")

uevrUtils.setLogLevel(LogLevel.Debug)
reticule.setLogLevel(LogLevel.Debug)
uevrUtils.setDeveloperMode(true)

reticule.init()
```

Run your game and make sure you're at a point in the game where you can see the reticule you're targeting.
Go to the Reticule Config Dev tab in UEVR UI. 

#### Widget Based Reticules
Select Widget for the type and press the Refresh button to make sure the tool has found all of the available reticules. 
<br><br><img width="346" height="348" alt="reticule1" src="https://github.com/user-attachments/assets/acb6c66c-fa1e-4f59-b56c-73bac691d8eb" />

The tool will automatically search for widgets that contain the words Cursor, Reticule, Reticle or Crosshair in their name. You can also enter text in the Find box to search for additional widgets. Then press Refresh to see an updated list of reticules. Try the various reticules found in the "Possible Reticules" list by moving the UEVR UI so you can see the reticule on screen and pressing Toggle Visibility until it disappears. Although this works most of the time a small number of games wont toggle visibility with this method and you will just have to try each one individually with "Add Selected Reticule" 
<br><br><img width="897" height="709" alt="reticule2" src="https://github.com/user-attachments/assets/c8c2b9d0-0754-4855-80cd-110f671d3b5f" />

When you have the correct reticule selected in the dropdown press Add Selected Reticule. Additional settings such as position, scale, remove from viewport, two sided and collision channel can be configured. If you now close the UEVR UI window the reticule should be connected to your right controller if you have the UEVR Aim Method set to Right Controller.
<br><br><img width="355" height="357" alt="reticule3" src="https://github.com/user-attachments/assets/ab88f2c9-976d-47bf-844e-1a5faa598d69" />

The reticule settings are now saved in the game's data folder and you can use code like this to use it in your game
```
local uevrUtils = require('libs/uevr_utils')
local reticule = require("libs/reticule")

reticule.init()
```

### Using the Manual Reticule Creation

Rename the file "example_reticule_simple.luax" as "example_reticule_simple.lua" or "example_reticule_advanced.luax" as "example_reticule_advanced.lua"

