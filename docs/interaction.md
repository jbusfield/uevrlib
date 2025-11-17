# Interaction (Laser Pointer)

The interaction module provides VR interaction capabilities for UEVR mods, enabling laser pointer-based interaction with both UI widgets and 3D meshes in the game world.

## Overview

This module supports:

- **Widget Interaction**: Creates a `WidgetInteractionComponent` that can interact with Unreal Engine UI elements
- **Mesh Interaction**: Raycast against 3D geometry
- **Laser Pointer**: Visual feedback showing interaction direction
- **Mouse Control**: Optional mouse cursor synchronization

## Quick Start

### Basic Setup

```lua
local uevrUtils = require('libs/uevr_utils')
local interaction = require("libs/interaction")

-- remove the next three line for production mode
uevrUtils.setDeveloperMode(true)
uevrUtils.setLogLevel(LogLevel.Debug)
interaction.setLogLevel(LogLevel.Debug)

interaction.init()
```

### Register Hit Callbacks

```lua
interaction.registerOnHitCallback(function(hitResult)
    print("Hit at location:", hitResult.Location.X, hitResult.Location.Y, hitResult.Location.Z)
    print("Hit actor:", hitResult.Actor:get_full_name())
end)
```
<br>

## Configuration Interface
UI guide coming soon