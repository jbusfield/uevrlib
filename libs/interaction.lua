--Interaction component and laser pointer inspired by Gwizdek

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
-- local controllers = require("libs/controllers")
-- local ui = require("libs/ui")

local M = {}

local traceChannel = 1
local interactionDistance = 300
local interactionSource = EWidgetInteractionSource.World
local enableHitTesting = true
local pointerIndex = 1
local virtualUserIndex = 99

local laserLengthOffset = 0
local interactionDepthOffset = 0
local interactionZOffset = 0
local laserColor = "#0000FFFF"

---@class widgetInteractionComponent
---@field [any] any
local widgetInteractionComponent = nil
local laserComponent = nil
local trackerComponent = nil

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[interaction] " .. text, logLevel)
	end
end

local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_interaction",
		initialOpen = true,
		label = "Interaction Configuration"
	},
		{
			widgetType = "combo",
			id = "interactionSource",
			label = "Interaction Source",
			selections = {"World", "Mouse", "CenterScreen", "Custom"},
			initialValue = interactionSource + 1,
--			width = 400
		},
        {
            widgetType = "slider_int",
            id = "traceChannel",
            label = "Trace Channel",
            speed = 1.0,
            range = {0, 100},
            initialValue = traceChannel
        },
        {
            widgetType = "slider_int",
            id = "pointerIndex",
            label = "Pointer Index",
            speed = 1.0,
            range = {1, 100},
            initialValue = pointerIndex
        },
        {
            widgetType = "slider_int",
            id = "interactionDistance",
            label = "Interaction Distance",
            speed = 1.0,
            range = {1, 10000},
            initialValue = interactionDistance
        },
        {
            widgetType = "checkbox",
            id = "enableHitTesting",
            label = "Enable Hit Testing",
            initialValue = enableHitTesting
        },
        {
            widgetType = "slider_float",
            id = "interactionDepthOffset",
            label = "Interaction Depth Offset",
            speed = 1.0,
            range = {-50, 50},
            initialValue = interactionDepthOffset
        },
        {
            widgetType = "slider_float",
            id = "interactionZOffset",
            label = "Interaction Z Offset",
            speed = 1.0,
            range = {-20, 20},
            initialValue = interactionZOffset
        },
        {
            widgetType = "slider_float",
            id = "laserLengthOffset",
            label = "Laser Length Offset",
            speed = 1.0,
            range = {-200, 200},
            initialValue = laserLengthOffset
        },
        {
            widgetType = "color_picker",
            id = "laserColor",
            label = "Laser Color",
            initialValue = laserColor
        },
        
	{
		widgetType = "tree_pop"
	},
}

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("interaction_config_dev")
    else
        M.loadConfiguration("interaction_config_dev")
    end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Interaction Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Interaction Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end

function M.setInteractionSource(val)
    interactionSource = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.InteractionSource = interactionSource
    end
end

function M.setTraceChannel(val)
    traceChannel = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.TraceChannel = traceChannel
    end
end

function M.setPointerIndex(val)
    pointerIndex = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.PointerIndex = pointerIndex
    end
end

function M.setInteractionDistance(val)
    interactionDistance = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.InteractionDistance = interactionDistance
    end
end

function M.setEnableHitTesting(val)
    enableHitTesting = val
    if widgetInteractionComponent ~= nil then
        widgetInteractionComponent.bEnableHitTesting = enableHitTesting
    end
end

function M.setInteractionDepthOffset(val)
    interactionDepthOffset = val
end

function M.setInteractionZOffset(val)
    interactionZOffset = val
end

function M.setLaserLengthOffset(val)
    laserLengthOffset = val
end


function M.setLaserColor(val)
    laserColor = uevrUtils.intToHexString(val)
    --print("LaserColor", laserColor)
    if laserComponent ~= nil then
        laserComponent.ShapeColor = uevrUtils.hexToColor(laserColor)
    end
end

configui.onCreateOrUpdate("interactionSource", function(value)
	M.setInteractionSource(value - 1)
end)

configui.onCreateOrUpdate("traceChannel", function(value)
	M.setTraceChannel(value)
end)

configui.onCreateOrUpdate("pointerIndex", function(value)
	M.setPointerIndex(value)
end)

configui.onCreateOrUpdate("interactionDistance", function(value)
	M.setInteractionDistance(value)
end)

configui.onCreateOrUpdate("enableHitTesting", function(value)
	M.setEnableHitTesting(value)
end)

configui.onCreateOrUpdate("interactionDepthOffset", function(value)
	M.setInteractionDepthOffset(value)
end)

configui.onCreateOrUpdate("interactionZOffset", function(value)
	M.setInteractionZOffset(value)
end)

configui.onCreateOrUpdate("laserLengthOffset", function(value)
	M.setLaserLengthOffset(value)
end)

configui.onCreateOrUpdate("laserColor", function(value)
	M.setLaserColor(value)
end)

function M.createWidgetInteractionComponent(useLaser, useTerminator)
    local component = uevrUtils.create_component_of_class("Class /Script/UMG.WidgetInteractionComponent")
    if component == nil then
        component.VirtualUserIndex = virtualUserIndex
        component.PointerIndex = pointerIndex
        component.TraceChannel = traceChannel
        component.InteractionDistance = interactionDistance
        component.InteractionSource = interactionSource
        component.bEnableHitTesting = enableHitTesting
        component:SetVisibility(false, false)
        component:SetHiddenInGame(true, true)
    end

    if useLaser then
        laserComponent = M.createLaserComponent()
    end

    if useTerminator then
        trackerComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
        uevrUtils.set_component_relative_transform(trackerComponent, nil, nil, {X=0.003, Y=0.003, Z=0.003})
    end

    widgetInteractionComponent = component
    return component
end

function M.createLaserComponent()
    local component = uevrUtils.create_component_of_class("Class /Script/Engine.CapsuleComponent")
    if component ~= nil then
        component:SetCapsuleSize(0.1, 0, true)
        component:SetVisibility(true, true)
        component:SetHiddenInGame(false, false)
        component.bAutoActivate = true
        component:SetGenerateOverlapEvents(false)
        component:SetCollisionEnabled(ECollisionEnabled.NoCollision)
        component:SetRenderInMainPass(true)
        component.bRenderInDepthPass = true
        component.ShapeColor = uevrUtils.hexToColor(laserColor)

        component:SetRenderCustomDepth(true)
        component:SetCustomDepthStencilValue(100)
        component:SetCustomDepthStencilWriteMask(ERendererStencilMask.ERSM_255)
        --uevrUtils.set_component_relative_rotation(component, uevrUtils.rotator(0, 0, 90))
    end
    return component
end

function M.updateLaserPointer(origin, target) 
    if widgetInteractionComponent ~= nil and laserComponent ~= nil then
        --local screenLocation = widgetInteractionComponent:Get2DHitLocation()
        --print(screenLocation.X,screenLocation.Y)
        --local playerController = uevr.api:get_player_controller(0)
        --playerController:SetMouseLocation(screenLocation.X, screenLocation.Y)

        --local hitDistance = widgetInteractionComponent:GetHoveredWidgetComponent() ~= nil and (widgetInteractionComponent:GetLastHitResult().Distance + laserLengthOffset) or defaultLength
        local hitDistance = kismet_math_library:Vector_Distance(origin, target) + laserLengthOffset
        laserComponent:SetCapsuleHalfHeight(hitDistance / 2, false);
        --laserComponent:K2_SetRelativeLocation( uevrUtils.vector((hitDistance / 2) + laserLocationOffset, 0, 0 ), false, reusable_hit_result, false)
        laserComponent:K2_SetWorldLocation( uevrUtils.vector(origin.X + ((target.X-origin.X)/2), origin.Y + ((target.Y-origin.Y)/2), origin.Z + ((target.Z-origin.Z)/2)), false, reusable_hit_result, false)
        local rotation = kismet_math_library:Conv_VectorToRotator(uevrUtils.vector(target.X-origin.X,target.Y-origin.Y,target.Z-origin.Z))
        rotation.Pitch = rotation.Pitch + 90
        laserComponent:K2_SetWorldRotation(rotation, false, reusable_hit_result, false)
    end
end

-- Projects the intersection of a vector (from origin to endpoint) onto a second plane offset toward the viewer
local function projectIntersectionOntoOffsetPlane(origin, endpoint, planePoint, planeNormal, offset)
    offset = offset or 0.1 -- default to 10cm

    -- Vector math utilities
    local function isValidVector(v)
        return v and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
    end

    local function subtract(a, b)
        return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
    end

    local function add(a, b)
        return { X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }
    end

    local function scale(v, s)
        return { X = v.X * s, Y = v.Y * s, Z = v.Z * s }
    end

    local function dot(a, b)
        return a.X * b.X + a.Y * b.Y + a.Z * b.Z
    end

    local function normalize(v)
        local mag = math.sqrt(v.X^2 + v.Y^2 + v.Z^2)
        if mag == 0 then return nil, "Cannot normalize zero-length vector" end
        return { X = v.X / mag, Y = v.Y / mag, Z = v.Z / mag }
    end

    -- Validate inputs
    if not (isValidVector(origin) and isValidVector(endpoint) and isValidVector(planePoint) and isValidVector(planeNormal)) then
        return nil, "Invalid input: all vectors must have .X, .Y, .Z components"
    end

    -- Step 1: Compute direction
    local direction = subtract(endpoint, origin)
    if direction.X == 0 and direction.Y == 0 and direction.Z == 0 then
        return nil, "Origin and endpoint are the same (zero-length vector)"
    end

    -- Step 2: Normalize plane normal
    local n, err = normalize(planeNormal)
    if not n then return nil, err end

    -- Step 3: Compute intersection
    local denom = dot(n, direction)
    if math.abs(denom) < 0.000001 then
        return nil, "Vector is parallel to plane (no intersection)"
    end

    local t = dot(n, subtract(planePoint, origin)) / denom
    local q = add(origin, scale(direction, t))

    -- Step 4: Project onto offset plane
    local qProjected = subtract(q, scale(n, offset))

    return qProjected
end

--local oldMouseCursor = 0
local function onHoverChanged(isHovering)
    -- local playerController = uevr.api:get_player_controller(0)
    -- if isHovering then
    --     if playerController ~= nil then
    --         oldMouseCursor = playerController.CurrentMouseCursor
    --         playerController.CurrentMouseCursor = 0
    --     end
    -- else
    --     playerController.CurrentMouseCursor = oldMouseCursor
    -- end
    if trackerComponent ~= nil then trackerComponent:SetVisibility(isHovering, false) end
    if laserComponent ~= nil then laserComponent:SetVisibility(isHovering, false) end
end

-- local mouseMoveActive = true
-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- local WidgetLayoutLibrary = nil
-- local UIUtils = nil

--local function moveMouseCursor()
--     local activeWidget = ui.getActiveViewportWidget()
--     jiggle = false
--     if mouseMoveActive and activeWidget ~= nil then
--         print("Active widget", activeWidget:get_full_name())

--         if WidgetLayoutLibrary == nil then WidgetLayoutLibrary = uevrUtils.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary") end
--         --if UIUtils == nil then UIUtils = uevrUtils.find_default_instance("Class /Script/AtomicHeart.UIUtils") end
--         --local distance = 1000
--         local forwardVector = controllers.getControllerDirection(Handed.Right) 
--         local worldLocation = controllers.getControllerLocation(Handed.Right) + (forwardVector * 8192.0)

--         --local worldLocation = forwardVector * distance
--         print(worldLocation.X, worldLocation.Y, worldLocation.Z)
--         local playerController = uevr.api:get_player_controller(0)
--         if WidgetLayoutLibrary ~= nil and playerController ~= nil then
--             --UIUtils.SetCursorWidgetVisibility(playerController, true, 1)
--             playerController.bShowMouseCursor = true
--             playerController.bEnableMouseOverEvents = true
--             playerController.bEnableTouchOverEvents = true
--             playerController.bEnableClickEvents = true
            

--             local currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
--             print("Current mouse", currentMousePosition.X, currentMousePosition.Y)
--             local bProjected = WidgetLayoutLibrary:ProjectWorldLocationToWidgetPosition(playerController, worldLocation, g_screenLocation, false)
--             if bProjected and g_screenLocation~= nil then
--                 playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 print("Projected", bProjected, g_screenLocation.X, g_screenLocation.Y)
--             end
--             Statics:ProjectWorldToScreen(playerController, worldLocation, g_screenLocation, false)
--             if g_screenLocation~= nil and g_screenLocation.X ~= 0 and g_screenLocation.Y ~= 0 then
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                  print("Projected 2", g_screenLocation.X, g_screenLocation.Y)
--             end
--             playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
--             if g_screenLocation~= nil then
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--                 print("Projected 3", g_screenLocation.X, g_screenLocation.Y)
--             end
--             jiggle = true
--             -- local reply = {}
--             -- WidgetBlueprintLibrary:SetMousePosition(reply, g_screenLocation);

--             -- g_screenLocation = UIUtils:ProjectWorldLocationToScreenNormalizedCoords(uevrUtils.get_world(), playerController, worldLocation);
--             -- if g_screenLocation~= nil then
--             --     --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--             --     print("Projected 4", g_screenLocation.X, g_screenLocation.Y)
--             -- end
--         -- local success, response = pcall(function()		
--         --     bProjected = UIUtils:ProjectWorldLocationToLocalCoordsFromCenterOriginWithContainer(uevrUtils.get_world(), activeWidget, playerController, worldLocation, g_screenLocation)
--         --     if bProjected and g_screenLocation~= nil then
--         --         --playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
--         --         print("Projected 5", bProjected, g_screenLocation.X, g_screenLocation.Y)
--         --     end
-- 		-- end)
-- 		-- if success == false then
-- 		-- 	print("mouse move error " .. response, LogLevel.Error)
-- 		-- end

         
-- --UWidgetBlueprintLibrary
-- 	--static void GetAllWidgetsOfClass(class UObject* WorldContextObject, TArray<class UUserWidget*>* FoundWidgets, TSubclassOf<class UUserWidget> WidgetClass, bool TopLevelOnly);
-- 	--static struct FEventReply SetMousePosition(struct FEventReply& Reply, const struct FVector2D& NewMousePosition);
-- -- // ScriptStruct UMG.EventReply
-- -- // 0x00B8 (0x00B8 - 0x0000)
-- -- struct alignas(0x08) FEventReply final
-- -- {
-- -- public:
-- -- 	uint8                                         Pad_0[0xB8];                                       // 0x0000(0x00B8)(Fixing Struct Size After Last Property [ Dumper-7 ])
-- -- };

--         end
--     end

    -- if mouseMoveActive and widgetInteractionComponent ~= nil then
    --     --local isHovering = widgetInteractionComponent.HoveredWidgetComponent ~= nil
    --     --if isHovering then
    --         local screenLocation = widgetInteractionComponent:Get2DHitLocation()
    --         local playerController = uevr.api:get_player_controller(0)
    --         if playerController ~= nil then
    --             local hitResult = widgetInteractionComponent:GetLastHitResult()
    --             if hitResult ~= nil then
    --                 local bProjected = WidgetLayoutLibrary:ProjectWorldLocationToWidgetPosition(playerController, uevrUtils.vector(hitResult.TraceEnd), screenLocation, false)
    --                 print("Projected", bProjected, screenLocation.X, screenLocation.Y)
    --             end
    --         end
    --         if playerController ~= nil and screenLocation.X ~= 0 and screenLocation.Y ~= 0 then
    --             playerController:SetMouseLocation(screenLocation.X, screenLocation.Y)
    --             --playerController.bShowMouseCursor = true
    --             print("Moving mouse to", screenLocation.X, screenLocation.Y)
    --         end
    --     --end
    -- end
--end

local wasHovering = false
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
    if uevrUtils.getValid(widgetInteractionComponent) == nil then return end

        --if you dont do this repeatedly it doesnt stay set
    widgetInteractionComponent.VirtualUserIndex = virtualUserIndex
    widgetInteractionComponent.PointerIndex = pointerIndex
    widgetInteractionComponent.TraceChannel = traceChannel
    widgetInteractionComponent.InteractionDistance = interactionDistance
    widgetInteractionComponent.InteractionSource = interactionSource
    widgetInteractionComponent.bEnableHitTesting = enableHitTesting

    local isHovering = widgetInteractionComponent.HoveredWidgetComponent ~= nil
    --print("isHovering", isHovering, widgetInteractionComponent.HoveredWidgetComponent)
    if isHovering then
            --playerController.bShowMouseCursor = false

            --widgetInteractionComponent.HoveredWidgetComponent.Widget["NeedClickSound?"] = false
        local hitResult = widgetInteractionComponent:GetLastHitResult()
        if hitResult ~= nil then
            local projected = hitResult.Location
            if interactionDepthOffset ~= 0 then
                projected = projectIntersectionOntoOffsetPlane(hitResult.TraceStart, hitResult.TraceEnd, hitResult.ImpactPoint, hitResult.ImpactNormal, interactionDepthOffset)
            end
            if projected ~= nil then
                projected = uevrUtils.vector(projected)
                --print(projected.X, projected.Y, projected.Z)
                projected.Z = projected.Z + interactionZOffset
                if trackerComponent ~= nil then trackerComponent:K2_SetWorldLocation(uevrUtils.vector(projected), false, reusable_hit_result, false) end
                M.updateLaserPointer(uevrUtils.vector(hitResult.TraceStart), projected)
            end
        end
    else
        -- local forwardVector = controllers.getControllerDirection(Handed.Right)
        -- local location = controllers.getControllerLocation(Handed.Right)
        -- local worldLocation = location + (forwardVector * 8192.0)
        -- M.updateLaserPointer(location, worldLocation)
    end
    if isHovering ~= wasHovering then
        onHoverChanged(isHovering)
        wasHovering = isHovering
    end

end)

local keyStruct
local wasButtonPressed = false
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if uevrUtils.getValid(widgetInteractionComponent) == nil then return end
    
    local isButtonPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_A)
	if isButtonPressed and isButtonPressed ~= wasButtonPressed then
		if keyStruct == nil then keyStruct = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key") end
		keyStruct.KeyName = uevrUtils.fname_from_string("LeftMouseButton")
        -- if widgetInteractionComponent.PressPointerKey ~= nil then
		--     local result = widgetInteractionComponent:PressAndReleaseKey(keyStruct)
        -- end
        if widgetInteractionComponent.PressPointerKey ~= nil then
		    local result = widgetInteractionComponent:PressPointerKey(keyStruct)
        end
        print("Pressing left")
    elseif (not isButtonPressed) and isButtonPressed ~= wasButtonPressed then
		if keyStruct == nil then keyStruct = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key") end
		keyStruct.KeyName = uevrUtils.fname_from_string("LeftMouseButton")
		--local result = widgetInteractionComponent:PressAndReleaseKey(keyStruct)
        if widgetInteractionComponent.ReleasePointerKey ~= nil then
		    local result = widgetInteractionComponent:ReleasePointerKey(keyStruct)
        end
        print("Releasing left")
	end
    wasButtonPressed = isButtonPressed
end)

-- uevrUtils.setInterval(100, function()
--     moveMouseCursor()
-- end)
uevrUtils.registerPreLevelChangeCallback(function(level)
	wasHovering = false
    widgetInteractionComponent = nil
    laserComponent = nil
    trackerComponent = nil
end)

-- This will move the mouse on screen but hover and interaction wont work (unless you bump the mouse)
-- local mouseMoveActive = true
-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
-- 	local forwardVector = controllers.getControllerDirection(Handed.Right)
-- 	local location = controllers.getControllerLocation(Handed.Right)
-- 	local worldLocation = location + (forwardVector * 8192.0)
-- 	local playerController = uevr.api:get_player_controller(0)
-- 	if mouseMoveActive and playerController ~= nil then
-- 		playerController.bShowMouseCursor = true
-- 		playerController.bEnableMouseOverEvents = true
-- 		playerController.bEnableTouchOverEvents = true
-- 		playerController.bEnableClickEvents = true
-- 		playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
-- 		if g_screenLocation~= nil then
-- 			playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 			playerController:SetMouseLocation(g_screenLocation.X+1, g_screenLocation.Y+1)
-- 			playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 		end
-- 	end
-- end)

-- register_key_bind("F1", function()
-- 	mouseMoveActive = not mouseMoveActive
--     M.print("Mouse move active: " .. tostring(mouseMoveActive))
-- end)

return M




-- local uevrUtils = require('libs/uevr_utils')
-- local controllers = require('libs/controllers')

-- local mouseMoveActive = false
-- --callback from uevrUtils that fires whenever the level changes
-- function on_level_change(level, levelName)
-- 	print("Level changed to " .. levelName)
-- 	controllers.createController(0)
-- 	controllers.createController(1)
-- 	controllers.createController(2)
-- end

-- local g_screenLocation = uevrUtils.vector_2(0,0)
-- local WidgetLayoutLibrary = nil
-- uevrUtils.setInterval(200, function()
--     if WidgetLayoutLibrary == nil then WidgetLayoutLibrary = uevrUtils.find_default_instance("Class /Script/UMG.WidgetLayoutLibrary") end
-- 	local forwardVector = controllers.getControllerDirection(Handed.Right)
-- 	local location = controllers.getControllerLocation(Handed.Right)
-- 	local worldLocation = location + (forwardVector * 8192.0)
-- 	print("Location", location.X .. ", " .. location.Y .. ", " .. location.Z)
-- 	print("Target", worldLocation.X .. ", " .. worldLocation.Y .. ", " .. worldLocation.Z)
-- 	local playerController = uevr.api:get_player_controller(0)
-- 	local currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
-- 	print("Before mouse", currentMousePosition.X, currentMousePosition.Y)
-- 	--Statics:SetViewportMouseCaptureMode(uevrUtils.get_world(), 1)
-- 	if mouseMoveActive and playerController ~= nil then
-- 		--print(playerController:get_full_name())
-- 		playerController.bShowMouseCursor = true
-- 		playerController.bEnableMouseOverEvents = true
-- 		playerController.bEnableTouchOverEvents = true
-- 		playerController.bEnableClickEvents = true
-- 		playerController:ProjectWorldLocationToScreen(worldLocation, g_screenLocation, false)
-- 		if g_screenLocation~= nil then
-- 			--playerController:SetMouseLocation(g_screenLocation.X, g_screenLocation.Y)
-- 			local reply = {}
--             WidgetBlueprintLibrary:SetMousePosition(reply, g_screenLocation)
-- 			print(reply)
-- 		end
-- 	end
-- 	currentMousePosition = WidgetLayoutLibrary:GetMousePositionOnViewport(uevrUtils.get_world())
-- 	print("After mouse", currentMousePosition.X, currentMousePosition.Y)
-- end)

-- register_key_bind("F1", function()
-- 	mouseMoveActive = not mouseMoveActive
--     print("Mouse move active: " .. tostring(mouseMoveActive))
-- end)
