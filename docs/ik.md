# Inverse Kinemtics (IK)

The IK module allows you to add Two Bone IK to player meshes using UEVR.

## Overview

Using the IK config UI you can select the game mesh you wish to use to create the IK rig. The mesh you select is then copied as a PoseableMeshComponent, whose bones are then 
manipulated to perform the Inverse Kinematics.
A quick video guide to setting up IK is available here https://youtu.be/UeKNvOFPmz4. The demo uses the game Hello Neighbor 2 Demo which is free on steam.

## Quick Start

### Basic Setup

```lua
local uevrUtils = require('libs/uevr_utils')
local ik = require('libs/ik')

uevrUtils.setDeveloperMode(true)

ik.init()
```

### Mesh Custom Creation Callback
The config UI allows you to specify the source mesh you wish to use for your IK Rig. You can also select "Custom" in the dropdown list of the UI. When "Custom" is selected,
the module will attempt to call a function that you will add to main.lua called getCustomIKComponent(). In this function you will return an array of descriptors for the meshes
you wish to use. The simplest case does the same thing as selecting Pawn.Mesh from the UI dropdown.
```lua
function getCustomIKComponent(rigID)
    return {{descriptor = "Pawn.Mesh"}}
end
```
Your game may, however, require multiple meshes to create a full IK setup. In Hogwarts, for example, there is a separate mesh for the robe, the gloves and the hands that all must be manipulated
together to perform a convincing IK. Returning an array as shown below, allows the IK to be applied to all of the meshes.
```lua
function getCustomIKComponent(rigID)
    return {{descriptor = "Pawn.Mesh(Robe)"}, {descriptor = "Pawn.Mesh(Gloves)", animation = "Gloves"}, {descriptor = "Pawn.Mesh(Arms)", animation = "Arms"}}
end
```
<br>

### Register IK Mesh Creation
After the PoseableMeshComponent copies are created, the system can call back on the registerOnMeshCreatedCallback function to allow you to further configure the newly created meshes
```lua
ik.registerOnMeshCreatedCallback(function(meshComponentList, ikInstance)
    local meshComponent = meshComponentList and meshComponentList[1] or nil
    if meshComponent ~= nil then
        meshComponent.bCastDynamicShadow = false
        meshComponent.bRenderInDepthPass = false
    end
end)
```
<br>

## Configuration Interface
With IK developer mode on, an "IK Config Dev" tab will appear in the UEVR UI. 
<br>



