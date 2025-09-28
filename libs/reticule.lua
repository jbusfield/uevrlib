--[[ 
Usage
    Drop the lib folder containing this file into your project folder
    Add code like this in your script:
        local reticule = require("libs/reticule")
        local isDeveloperMode = true  
        reticule.init(isDeveloperMode)

    Typical usage would be to run this code with developerMode set to true, then use the configuration tab
    to set parameters the way you want them, then set developerMode to false for production use. Be sure
    to ship your code with the data folder as well as the script folder because the data folder will contain
    your parameter settings.
        
    Available functions:

    reticule.init(isDeveloperMode, logLevel) - initializes the reticule system with specified mode and log level
        example:
            reticule.init(true, LogLevel.Debug)

    reticule.setReticuleType(value) - sets the type of reticule to be created (None, Default, Mesh, Widget, Custom)
		Typically you would enable developer mode and set this value in the UI. You can however, override the
		developer mode setting with this function
        example: 
		reticule.setReticuleType(reticule.ReticuleType.Custom)
		reticule.registerOnCustomCreateCallback(function()
			local AHStatics = uevrUtils.find_default_instance("Class /Script/AtomicHeart.AHGameplayStatics")
			if AHStatics ~= nil then
				local hud = AHStatics:GetPlayerHUD(uevrUtils.getWorld(), 0)
				if hud ~= nil then
					return reticule.ReticuleType.Widget, hud.CrosshairWidget,  { removeFromViewport = true, twoSided = true }
				end
			end
			return nil
		end)

    reticule.create() - creates a default sphere mesh-based reticule
        example:
            reticule.create()

    reticule.createFromWidget(widget, options) - creates a reticule from a UMG widget component
        example:
			reticule.setReticuleType(reticule.ReticuleType.None) --disable auto creation
			function createReticule()
				local AHStatics = uevrUtils.find_default_instance("Class /Script/AtomicHeart.AHGameplayStatics")
				if AHStatics ~= nil then
					local hud = AHStatics:GetPlayerHUD(uevrUtils.getWorld(), 0)
					if hud ~= nil then
						local widget = hud.CrosshairWidget
						if uevrUtils.getValid(widget) ~= nil then
							local options = { removeFromViewport = true, twoSided = true }
							reticule.createFromWidget(widget, options)
						end		
					end
				end
			end
			uevrUtils.setInterval(1000, function()
				if not reticule.exists() then
					createReticule()
				end
			end)

    reticule.createFromMesh(mesh, options) - creates a reticule from a static mesh
        example:
			local meshName = "StaticMesh /Engine/BasicShapes/Cube.Cube"
			local options = {
				materialName = "Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial",
				scale = {.03, .03, .03},
				rotation = {Pitch=0,Yaw=0,Roll=0},
			}
			reticule.createFromMesh(meshName, options )				

    reticule.registerOnCustomCreateCallback(callback) - registers a callback function for custom reticule creation
        example:
            reticule.registerOnCustomCreateCallback(function()
                return M.ReticuleType.Mesh, "StaticMesh /Game/MyMesh", {scale = {1,1,1}}
            end)

    reticule.exists() - returns true if a reticule component exists and is valid
        example:
            if reticule.exists() then
                -- Do something with reticule
            end

    reticule.getComponent() - gets the current reticule component
        example:
            local component = reticule.getComponent()

    reticule.destroy() - removes the current reticule component
		Be aware that if reticule mode is not set to None, the reticule will be recreated automatically
        example:
            reticule.destroy()

    reticule.hide(val) - sets reticule visibility
        example:
            reticule.hide(true)  -- Hide reticule

    reticule.update(originLocation, targetLocation, distance, scale, rotation, allowAutoHandle) - updates reticule position and transform
        The reticule will update automatically with default targeting but you can provide custom
		targeting information using this function
		example:
            reticule.update(nil, nil, 200, {1,1,1}, {0,0,0}, true)
			reticule.update(controllers.getControllerLocation(2), lastWandTargetLocation, distanceAdjustment, {reticuleScale,reticuleScale,reticuleScale}) 

    reticule.setDistance(val) - sets the reticule distance from origin
        example:
            reticule.setDistance(200)  -- Set to 200 units

    reticule.setScale(val) - sets the reticule scale multiplier
        example:
            reticule.setScale(1.0)

    reticule.setRotation(val) - sets the reticule rotation offset
        example:
            reticule.setRotation({0, 0, 0})

    reticule.setDefaultWidgetClass(val) - sets the default widget class for widget reticules
        example:
            reticule.setDefaultWidgetClass("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/WBP_Crosshair.WBP_Crosshair_C")

    reticule.setDefaultMeshClass(val) - sets the default mesh class to use for mesh-type reticules
        example:
            reticule.setDefaultMeshClass("StaticMesh /Engine/BasicShapes/Sphere.Sphere")

    reticule.setDefaultMeshMaterialClass(val) - sets the default material class for mesh-type reticules
        example:
            reticule.setDefaultMeshMaterialClass("Material /Engine/EngineMaterials/Widget3DPassThrough")

    reticule.getConfigurationWidgets(options) - gets configuration UI widgets for basic settings
        example:
            local widgets = reticule.getConfigurationWidgets()

    reticule.getDeveloperConfigurationWidgets(options) - gets configuration UI widgets including developer options
        example:
            local widgets = reticule.getDeveloperConfigurationWidgets()

    reticule.showConfiguration(saveFileName, options) - creates and shows basic configuration UI
        example:
            reticule.showConfiguration("reticule_config")

    reticule.showDeveloperConfiguration(saveFileName, options) - creates and shows developer configuration UI
        example:
            reticule.showDeveloperConfiguration("reticule_config_dev")

    reticule.loadConfiguration(fileName) - loads reticule configuration from a file
        example:
            reticule.loadConfiguration("reticule_config")

    reticule.setLogLevel(val) - sets the logging level for reticule messages
        example:
            reticule.setLogLevel(LogLevel.Debug)

    reticule.print(text, logLevel) - prints a message with the specified log level
        example:
            reticule.print("Reticule created", LogLevel.Info)

    reticule.reset() - resets the reticule system state, clearing components and widgets
        example:
            reticule.reset()

    reticule.getOriginPositionFromController() - gets the origin position from the controller
        example:
            local origin = reticule.getOriginPositionFromController()

    reticule.getTargetLocationFromController(handed) - gets the target location from a specific controller
        example:
            local target = reticule.getTargetLocationFromController(Handed.Right)

    reticule.getTargetLocation(originPosition, originDirection) - gets the target location from a position and direction
        example:
            local target = reticule.getTargetLocation(origin, direction)

]]--

local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local configui = require("libs/configui")

local M = {}

M.ReticuleType = {
	None = 1,
	Default = 2,
	Mesh = 3,
	Widget = 4,
	Custom = 5
}
---@class reticuleComponent
---@field [any] any
local reticuleComponent = nil
local reticuleRotation = nil
local reticulePosition = nil
local reticuleScale = nil
local reticuleCollisionChannel = 0
local restoreWidgetPosition = nil

local reticuleUpdateDistance = 200
local reticuleUpdateScale = 1.0
local reticuleUpdateRotation = {0.0, 0.0, 0.0}

local reticuleAutoCreationType = M.ReticuleType.None
local autoHandleInput = true

local reticuleNames = {}
local currentReticuleSelectionIndex = 0
local selectedReticuleWidget = nil
local selectedReticuleWidgetDefaultVisibility = nil
local reticuleRemoveFromViewport = true
local reticuleTwoSided = true
local reticuleDefaultWidgetClass = ""
local reticuleDefaultMeshMaterialClass = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
local reticuleDefaultMeshClass = "StaticMesh /Engine/BasicShapes/Plane.Plane"

local systemMeshes = {
	"Custom",
	"StaticMesh /Engine/BasicShapes/Sphere.Sphere",
	"StaticMesh /Engine/BasicShapes/Cube.Cube",
	"StaticMesh /Engine/BasicShapes/Plane.Plane",
	"StaticMesh /Engine/BasicShapes/Cone.Cone",
	"StaticMesh /Engine/BasicShapes/Cylinder.Cylinder",
	"StaticMesh /Engine/BasicShapes/Torus.Torus",
	"StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
}

local systemMaterials = {
	"Custom",
	"Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough",
	"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial",
	"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial",
	"Material /Engine/EngineMaterials/UnlitGeneric.UnlitGeneric",
	"Material /Engine/EngineMaterials/VertexColorMaterial.VertexColorMaterial",
	"Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial"
}


local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[reticule] " .. text, logLevel)
	end
end

local helpText = "This module allows you to configure the reticule system. If you want the reticule to be created automatically, select the type of reticule you want. You can choose a default reticule, a mesh-based reticule, or a widget-based reticule. If you choose Custom, you will need to implement the RegisterOnCustomCreateCallback function in your code and return the type of reticule to create along with any parameters needed for creation. If you do not want the reticule to be created automatically, set the type to None and create the reticule manually in your code using the Create, CreateFromWidget or CreateFromMesh functions."

local configWidgets = spliceableInlineArray{
	{
		widgetType = "slider_int",
		id = "reticuleUpdateDistance",
		label = "Distance",
		speed = 1.0,
		range = {0, 1000},
		initialValue = reticuleUpdateDistance
	},
	{
		widgetType = "slider_float",
		id = "reticuleUpdateScale",
		label = "Scale",
		speed = 0.01,
		range = {0.01, 5.0},
		initialValue = reticuleUpdateScale
	},
	{
		widgetType = "drag_float3",
		id = "reticuleUpdateRotation",
		label = "Rotation",
		speed = 1,
		range = {0, 360},
		initialValue = reticuleUpdateRotation
	}
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_reticle_config",
		initialOpen = true,
		label = "Reticule Automatic Configuration"
	},
		{
			widgetType = "combo",
			id = "uevr_reticule_type",
			selections = {"None", "Default", "Mesh",  "Widget", "Custom"},
			label = "Type",
			initialValue = reticuleAutoCreationType
		},
		{ widgetType = "begin_group", id = "uevr_reticule_widget_group", isHidden = false },
--			{ widgetType = "begin_group", id = "uevr_reticule_widget_finder", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Reticule Widget Finder" }, { widgetType = "begin_rect", },
			{ widgetType = "new_line" },
			{
				widgetType = "tree_node",
				id = "uevr_reticle_widget_finder_tree",
				initialOpen = false,
				label = "Reticule Widget Finder"
			},
				{
					widgetType = "text",
					id = "uevr_reticule_finder_instructions",
					label = "Instructions: Perform the search when the game reticule is currently visible on the screen. The finder will automatically search for widgets that contain the words Cursor, Reticule, Reticle or Crosshair in their name. You can also enter text in the Find box to search for other widgets. Press Refresh to see an updated list of widgets. After selecting a widget press Toggle Visibility to see if it is the correct one. If it is, press Use Selected Reticule to set it as the attached reticule.",
					wrapped = true
				},
				{
					widgetType = "input_text",
					id = "uevr_reticule_filter",
					label = "Find",
					initialValue = ""
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "button",
					id = "uevr_reticule_refresh_button",
					label = "Refresh",
					size = {80,22}
				},
				{
					widgetType = "combo",
					id = "uevr_reticule_list",
					label = "Possible Reticules",
					selections = {"None"},
					initialValue = 1,
				},
				{
					widgetType = "text_colored",
					id = "uevr_reticule_error",
					color = "#FF0000FF",
					isHidden = true,
					label = "Selected item not found. Press Refresh and try again."
				},
				{ widgetType = "indent", width = 60 },
				{
					widgetType = "button",
					id = "uevr_reticule_toggle_visibility_button",
					label = "Toggle Visibility",
					size = {150,22}
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "button",
					id = "uevr_reticule_use_button",
					label = "Use Selected Reticule",
					size = {150,22}
				},
				{ widgetType = "unindent", width = 60 },
				{
					widgetType = "input_text",
					id = "uevr_reticule_selected_name",
					label = "Selected Reticule",
					isHidden = true,
					initialValue = ""
				},
			{ widgetType = "tree_pop" },
--			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
			{ widgetType = "new_line" },
			{
				widgetType = "input_text",
				id = "uevr_reticule_widget_class",
				label = "Widget Class",
				initialValue = ""
			},
			-- {
			-- 	widgetType = "text",
			-- 	id = "uevr_reticule_custom_description",
			-- 	label = "You have either not chosen a widget to use as the reticule or you have chosen to use a custom reticule. Therefore, you should implement the RegisterCustomCallback in your code and supply your own widget",
			-- 	initialValue = "",
			-- 	wrapped = true
			-- },
			{
				widgetType = "checkbox",
				id = "reticuleRemoveFromViewport",
				label = "Remove From Viewport",
				initialValue = reticuleRemoveFromViewport
			},
			{
				widgetType = "checkbox",
				id = "reticuleTwoSided",
				label = "Two Sided",
				initialValue = reticuleTwoSided
			},
		{ widgetType = "end_group", },
		{ widgetType = "begin_group", id = "uevr_reticule_mesh_group", isHidden = false },
--			{ widgetType = "begin_group", id = "uevr_reticule_widget_finder", isHidden = false }, { widgetType = "new_line" }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "Mesh Reticule" }, { widgetType = "begin_rect", },
				{ widgetType = "new_line" },
				{
					widgetType = "combo",
					id = "uevr_reticule_mesh_class_list",
					label = "System Meshes",
					selections = systemMeshes,
					initialValue = 1,
				},
				{
					widgetType = "input_text",
					id = "uevr_reticule_mesh_class",
					label = "Custom Mesh Class",
					initialValue = reticuleDefaultMeshClass
				},
				{
					widgetType = "combo",
					id = "uevr_reticule_mesh_material_class_list",
					label = "System Material",
					selections = systemMaterials,
					initialValue = 1,
				},
				{
					widgetType = "input_text",
					id = "uevr_reticule_mesh_material_class",
					label = "Custom Material Class",
					initialValue = reticuleDefaultMeshMaterialClass
				},
--			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },
		{ widgetType = "end_group", },
	{
		widgetType = "tree_pop"
	},
	{ widgetType = "new_line" },
	{
		widgetType = "tree_node",
		id = "uevr_pawn_help_tree",
		initialOpen = true,
		label = "Help"
	},
		{
			widgetType = "text",
			id = "uevr_pawn_help",
			label = helpText,
			wrapped = true
		},
	{
		widgetType = "tree_pop"
	},
}

local function updateReticuleList()
	local searchText = configui.getValue("uevr_reticule_filter")
	M.print("Searching for widgets " .. searchText)
	local widgets = uevrUtils.find_all_instances("Class /Script/UMG.Widget", false)
	reticuleNames = {}
	--local activeWidgets = {}

	if widgets ~= nil then
		for name, widget in pairs(widgets) do
			local widgetName = widget:get_full_name()
			if not (widgetName:sub(1, 5) == "Image" or widgetName:sub(1, 7) == "Overlay" or widgetName:sub(1, 11) == "CanvasPanel" or widgetName:sub(1, 13) == "HorizontalBox" or widgetName:sub(1, 8) == "ScaleBox" or widgetName:sub(1, 7) == "SizeBox" or widgetName:sub(1, 11) == "VerticalBox" or widgetName:sub(1, 6) == "Border" or widgetName:sub(1, 9) == "TextBlock" or widgetName:sub(1, 6) == "Spacer") then
				if string.find(widgetName, "Cursor") or string.find(widgetName, "Reticule") or string.find(widgetName, "Reticle") or string.find(widgetName, "Crosshair") or (searchText ~= nil and searchText ~= "" and string.find(widgetName, searchText)) then
					if configui.getValue("uevr_dev_reticule_active") == true then
						local isActive = false
						if uevrUtils.getValid(pawn) ~= nil and widget.GetOwningPlayerPawn ~= nil then
							isActive = widget:GetOwningPlayerPawn() == pawn
							if isActive then
								--table.insert(activeWidgets, widget)
								table.insert(reticuleNames, widgetName)
							end
						end
						--print(widget:get_full_name(), isActive and "true" or "false")
					else
						table.insert(reticuleNames, widgetName)
					end
				end
			end
		end
	end

	--configui.setLabel("uevr_dev_reticule_total_count", "Reticule count:" .. #reticuleNames)
	table.insert(reticuleNames, 1, "Custom")
	configui.setSelections("uevr_reticule_list", reticuleNames)
end

local function updateMeshLists()
	configui.setSelections("uevr_reticule_mesh_class_list", systemMeshes)
	configui.setSelections("uevr_reticule_mesh_material_class_list", systemMaterials)
	local index = 1
	for i = 1, #systemMeshes do
		if systemMeshes[i] == reticuleDefaultMeshClass then
			index = i
			break
		end
	end
	configui.setValue("uevr_reticule_mesh_class_list", index)
	local matIndex = 1
	for i = 1, #systemMaterials do
		if systemMaterials[i] == reticuleDefaultMeshMaterialClass then
			matIndex = i
			break
		end
	end
	configui.setValue("uevr_reticule_mesh_material_class_list", matIndex)
end

local function resetSelectedWidget()
	if selectedReticuleWidget ~= nil and uevrUtils.getValid(selectedReticuleWidget) ~= nil then
		--reset previous widget visibility
		if selectedReticuleWidgetDefaultVisibility ~= nil then
			selectedReticuleWidget:SetVisibility(selectedReticuleWidgetDefaultVisibility)
		end
		selectedReticuleWidget = nil
		selectedReticuleWidgetDefaultVisibility = nil
	end
end

local function getSelectedReticuleWidget()
	if reticuleNames ~= nil and currentReticuleSelectionIndex <= #reticuleNames and currentReticuleSelectionIndex > 1 then
		--local widget = uevrUtils.getLoadedAsset(reticuleNames[currentReticuleSelectionIndex])	
		return uevrUtils.find_instance_of("Class /Script/UMG.Widget", reticuleNames[currentReticuleSelectionIndex])
	end
	return nil
end

local function updateSelectedReticule()
	resetSelectedWidget()
	if currentReticuleSelectionIndex == 1 then
		--custom widget do callback
		configui.setValue("uevr_reticule_selected_name", "")
	else
		--local widget = uevrUtils.getLoadedAsset(reticuleNames[currentReticuleSelectionIndex])	
		local widget = getSelectedReticuleWidget()
		if widget == nil then
			configui.hideWidget("uevr_reticule_error" ,false)
			delay(3000, function()
				configui.hideWidget("uevr_reticule_error" ,true)
			end)
		else
			selectedReticuleWidget = widget
			selectedReticuleWidgetDefaultVisibility = widget:GetVisibility()
			--print("Widget is",widget)
			configui.setValue("uevr_reticule_selected_name", widget:get_full_name())
			-- print(reticuleNames[currentReticuleSelectionIndex])
			-- print(widget:get_full_name())
			-- print("Has function", widget.HandleShowTargetReticule ~= nil)

			-- currentComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=false, twoSided=true})--, drawSize=vector_2(620, 620)})
			-- if uevrUtils.getValid(currentComponent) ~= nil then
			-- 	--setCurrentComponentScale(1.0)
			-- 	uevrUtils.set_component_relative_transform(currentComponent, {X=0.0, Y=0.0, Z=0.0}, {Pitch=0,Yaw=0 ,Roll=0}, {X=-0.1, Y=-0.1, Z=0.1})
			-- 	local leftConnected = controllers.attachComponentToController(Handed.Left, currentComponent, nil, nil, nil, true)
			-- 	M.print("Added reticule to controller " .. (leftConnected and "true" or "false"))
			-- end
		end
	end
end

local function toggleSelectedReticuleVisibility()
	local widget = getSelectedReticuleWidget()
	if uevrUtils.getValid(widget) ~= nil then
		---@cast widget -nil
		local vis = widget:GetVisibility()
		if vis == 0 or vis == 4 or vis == 3 then
			vis = 1
		else
			vis = 0
		end
		widget:SetVisibility(vis)
	else
		M.print("Selected widget is not valid in toggleSelectedReticuleVisibility")
	end
end

local function destroyReticuleComponent()
	if uevrUtils.getValid(reticuleComponent) ~= nil then
		if reticuleComponent:is_a(uevrUtils.get_class("Class /Script/UMG.WidgetComponent")) then
			local widget = reticuleComponent:GetWidget()
			if widget ~= nil then
				widget:AddToViewport(0)
				if restoreWidgetPosition ~= nil then
					widget:SetAlignmentInViewport(restoreWidgetPosition)
					restoreWidgetPosition = nil
				end
			end
		end
		uevrUtils.destroyComponent(reticuleComponent, true, true)
	end
	reticuleComponent = nil
end

local function autoCreateReticule()
	M.print("Auto creating reticule of type " .. tostring(reticuleAutoCreationType))
	destroyReticuleComponent()
	if reticuleAutoCreationType == M.ReticuleType.Default then
		M.create()
	elseif reticuleAutoCreationType == M.ReticuleType.Widget  then
		if reticuleDefaultWidgetClass ~= nil and reticuleDefaultWidgetClass ~= "" then
			local options = { removeFromViewport = reticuleRemoveFromViewport, twoSided = reticuleTwoSided }
			M.createFromWidget(reticuleDefaultWidgetClass, options)
		else
			M.print("Reticule default widget class is empty, not creating reticule")
		end
	elseif reticuleAutoCreationType == M.ReticuleType.Mesh then
		if reticuleDefaultMeshClass ~= nil and reticuleDefaultMeshClass ~= "" then
			local options = {
				materialName = reticuleDefaultMeshMaterialClass,
				scale = {.03, .03, .03},
				rotation = {Pitch=0,Yaw=0,Roll=0},
	--			collisionChannel = configui.getValue("reticuleCollisionChannel")
			}
			M.createFromMesh(reticuleDefaultMeshClass, options )
		else
			M.print("Reticule default mesh class is empty, not creating reticule")
		end
	end
end

configui.onUpdate("uevr_reticule_toggle_visibility_button", function()
	toggleSelectedReticuleVisibility()
end)

configui.onUpdate("uevr_reticule_use_button", function()
	local widget = getSelectedReticuleWidget()
	local widgetClassName = ""
	---@cast widget -nil
	if uevrUtils.getValid(widget) ~= nil and widget:get_class() ~= nil then
		widgetClassName = widget:get_class():get_full_name()
	end
	M.setDefaultWidgetClass(widgetClassName)
end)

configui.onUpdate("uevr_reticule_list", function(value)
	if value ~= nil and reticuleNames ~= nil and reticuleNames[value] ~= nil then
		M.print("Using reticule at index " .. value .. " - " .. reticuleNames[value])
	end
	currentReticuleSelectionIndex = value
	updateSelectedReticule()
end)

configui.onUpdate("uevr_reticule_mesh_class_list", function(value)
	if value ~= nil and systemMeshes ~= nil and systemMeshes[value] ~= nil then
		M.print("Using mesh at index " .. value .. " - " .. systemMeshes[value])
		if value == 1 then
			configui.setValue("uevr_reticule_mesh_class", "")
		else
			configui.setValue("uevr_reticule_mesh_class", systemMeshes[value])
		end
		configui.setHidden("uevr_reticule_mesh_class", value ~= 1)
	end
end)

configui.onUpdate("uevr_reticule_mesh_material_class_list", function(value)
	if value ~= nil and systemMaterials ~= nil and systemMaterials[value] ~= nil then
		M.print("Using material at index " .. value .. " - " .. systemMaterials[value])
		if value == 1 then
			configui.setValue("uevr_reticule_mesh_material_class", "")
		else
			configui.setValue("uevr_reticule_mesh_material_class", systemMaterials[value])
		end
		configui.setHidden("uevr_reticule_mesh_material_class", value ~= 1)
	end
end)

function M.setDistance(val)
	reticuleUpdateDistance = val
	configui.setValue("reticuleUpdateDistance", val, true)
end

function M.setScale(val)
	reticuleUpdateScale = val
	configui.setValue("reticuleUpdateScale", val, true)
end

function M.setRotation(val)
	reticuleUpdateRotation = val
	configui.setValue("reticuleUpdateRotation", val, true)
end

local createDevMonitor = doOnce(function()
	uevrUtils.registerLevelChangeCallback(function(level)
		print("Level changed, updating reticule list")
		updateReticuleList()
	end)
end, Once.EVER)

function M.init(isDeveloperMode, logLevel)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration("reticule_config_dev")
        createDevMonitor()
        updateReticuleList()
        updateMeshLists()
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

function M.loadConfiguration(fileName)
    configui.load(fileName, fileName)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Reticule Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Reticule Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

function M.setReticuleType(value)
	reticuleAutoCreationType = value
	configui.setHidden("uevr_reticule_widget_group", value ~= M.ReticuleType.Widget)
	configui.setHidden("uevr_reticule_mesh_group", value ~= M.ReticuleType.Mesh)
	configui.setValue("uevr_reticule_type", value, true)
	destroyReticuleComponent()
	--uevr_reticule_group
	--M.ReticuleConfigType
end

function M.setDefaultWidgetClass(val)
	reticuleDefaultWidgetClass = val
	configui.setValue("uevr_reticule_widget_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.setDefaultMeshClass(val)
	reticuleDefaultMeshClass = val
	configui.setValue("uevr_reticule_mesh_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.setDefaultMeshMaterialClass(val)
	reticuleDefaultMeshMaterialClass = val
	configui.setValue("uevr_reticule_mesh_material_class", val, true)
	--configui.setHidden("uevr_reticule_custom_description", val ~= "")
	destroyReticuleComponent()
end

function M.registerOnCustomCreateCallback(callback)
	uevrUtils.registerUEVRCallback("on_reticule_create", callback)
end

function M.reset()
	reticuleComponent = nil
	restoreWidgetPosition = nil
	reticuleNames = {}
	resetSelectedWidget()
end

function M.exists()
	return reticuleComponent ~= nil
end

function M.getComponent()
	return reticuleComponent
end

function M.destroy()
	-- if uevrUtils.getValid(reticuleComponent) ~= nil then
	-- 	uevrUtils.detachAndDestroyComponent(reticuleComponent, false)
	-- end
	destroyReticuleComponent()
	M.reset()
end

function M.hide(val)
	if val == nil then val = true end
	if uevrUtils.getValid(reticuleComponent) ~= nil then reticuleComponent:SetVisibility(not val) end
end

-- widget can be string or object
-- options can be removeFromViewport, twoSided, drawSize, scale, rotation, position, collisionChannel
function M.createFromWidget(widget, options)
	M.print("Creating reticule from widget")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if widget ~= nil then
		reticuleComponent, restoreWidgetPosition = uevrUtils.createWidgetComponent(widget, options)
		if uevrUtils.getValid(reticuleComponent) ~= nil then
			---@cast reticuleComponent -nil
			--reticuleComponent:SetDrawAtDesiredSize(true)

			reticuleComponent.BoundsScale = 10 --without this object can disappear when small

			uevrUtils.set_component_relative_transform(reticuleComponent, options.position, options.rotation, options.scale)
			reticuleRotation = uevrUtils.rotator(options.rotation)
			reticulePosition = uevrUtils.vector(options.position)
			if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
				reticuleScale = kismet_math_library:Multiply_VectorVector(uevrUtils.vector(options.scale), uevrUtils.vector(-1,-1, 1))
			else
				reticuleScale = uevrUtils.vector(-0.1,-0.1,0.1)
			end

			M.print("Created reticule " .. reticuleComponent:get_full_name())
		end
	else
		M.print("Reticule component could not be created, widget is invalid")
	end

	return reticuleComponent
end

-- mesh can be string or object
-- options can be materialName, scale, rotation, position, collisionChannel
function M.createFromMesh(mesh, options)
	M.print("Creating reticule from mesh")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if mesh == nil or mesh == "DEFAULT" then
		if options.scale == nil then options.scale = {.01, .01, .01} end
		mesh = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		if options.materialName == nil or options.materialName == "" then
			options.materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
		end
	end

	local component = uevrUtils.createStaticMeshComponent(mesh, {tag="uevrlib_reticule"})
	if uevrUtils.getValid(component) ~= nil then
			---@cast component -nil
		if options.materialName ~= nil and options.materialName ~= "" then
			M.print("Adding material to reticule component")
			local material = uevrUtils.getLoadedAsset(options.materialName)
			--debugModule.dump(material)
			--local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", options.materialName) 
			if uevrUtils.getValid(material) ~= nil then
				component:SetMaterial(0, material)
			else
				M.print("Reticule material was invalid " .. options.materialName)
			end
		end

		component.BoundsScale = 10 -- without this object can disappear when small

		uevrUtils.set_component_relative_transform(component, options.position, options.rotation, options.scale)
		reticuleRotation = uevrUtils.rotator(options.rotation)
		reticulePosition = uevrUtils.vector(options.position)
		if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
			reticuleScale = uevrUtils.vector(options.scale)
		else
			reticuleScale = uevrUtils.vector(1,1,1)
		end

		M.print("Created reticule " .. component:get_full_name())
	else
		M.print("Reticule component could not be created")
	end

	reticuleComponent = component
	return reticuleComponent

	-- local component = nil
	-- if meshName == nil or meshName == "DEFAULT" then
		-- if scale == nil then scale = {.01, .01, .01} end
		-- --alternates
		-- --"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"
		-- --"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial"
		-- --Not useful here but cool
		-- --Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial
		-- --Material /Engine/EditorMeshes/ColorCalibrator/M_ChromeBall.M_ChromeBall
		-- local materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough" 
		-- meshName = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
		-- if uevrUtils.getValid(component) ~= nil then
			-- M.print("Crosshair is valid. Adding material")
			-- local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", materialName) 
			-- if uevrUtils.getValid(material) ~= nil then
				-- component:SetMaterial(0, material)
			-- else
				-- M.print("Crosshair material was invalid " .. materialName)
			-- end
		-- end
	-- else		
		-- if scale == nil then scale = {1, 1, 1} end
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
	-- end


	-- if uevrUtils.getValid(component) ~= nil then
		-- component.BoundsScale = 10 --without this object can disappear when small
		-- component:SetWorldScale3D(uevrUtils.vector(scale))
		-- M.print("Created crosshair " .. component:get_full_name())
	-- end
	--crosshairComponent = component
end

function M.create()
	return M.createFromMesh()
end

-- function M.update_old(wandDirection, wandTargetLocation, originPosition, distanceAdjustment, crosshairScale, pitchAdjust, crosshairScaleAdjust)
	-- if distanceAdjustment == nil then distanceAdjustment = 200 end
	-- if crosshairScale == nil then crosshairScale = 1 end
	-- if pitchAdjust == nil then pitchAdjust = 0 end
	-- if crosshairScaleAdjust == nil then crosshairScaleAdjust = {0.01, 0.01, 0.01} end

	-- if  wandDirection ~= nil and wandTargetLocation ~= nil and originPosition ~= nil and uevrUtils.getValid(crosshairComponent) ~= nil then

		-- local maxDistance =  kismet_math_library:Vector_Distance(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- local targetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- if distanceAdjustment > maxDistance then distanceAdjustment = maxDistance end
		-- temp_vec3f:set(wandDirection.X,wandDirection.Y,wandDirection.Z) 
		-- local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
		-- rot.Pitch = rot.Pitch + pitchAdjust
		-- temp_vec3f:set(originPosition.X + (targetDirection.X * distanceAdjustment), originPosition.Y + (targetDirection.Y * distanceAdjustment), originPosition.Z + (targetDirection.Z * distanceAdjustment))

		-- crosshairComponent:GetOwner():K2_SetActorLocation(temp_vec3f, false, reusable_hit_result, false)	
		-- crosshairComponent:K2_SetWorldLocationAndRotation(temp_vec3f, rot, false, reusable_hit_result, false)
		-- temp_vec3f:set(crosshairScale * crosshairScaleAdjust[1],crosshairScale * crosshairScaleAdjust[2],crosshairScale * crosshairScaleAdjust[3])
		-- crosshairComponent:SetWorldScale3D(temp_vec3f)	
	-- end
-- end

function M.getOriginPositionFromController()
	if not controllers.controllerExists(2) then
		controllers.createController(2)
	end
	return controllers.getControllerLocation(2)
end

function M.getTargetLocationFromController(handed)
	if not controllers.controllerExists(handed) then
		controllers.createController(handed)
	end
	local direction = controllers.getControllerDirection(handed)
	if direction ~= nil then
		local startLocation = controllers.getControllerLocation(handed)
		--print(startLocation.X,startLocation.Y,startLocation.Z)
		local endLocation = startLocation + (direction * 8192.0)

		local ignore_actors = {}
		local world = uevrUtils.get_world()
		if world ~= nil then
			local hit = kismet_system_library:LineTraceSingle(world, startLocation, endLocation, reticuleCollisionChannel, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			if hit and reusable_hit_result.Distance > 10 then
				endLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
			end
		end

		return endLocation
	else
		M.print("Error in getTargetLocationFromController. Controller direction was nil")
	end
end

function M.getTargetLocation(originPosition, originDirection)
	local endLocation = originPosition + (originDirection * 8192.0)

	local ignore_actors = {}
	local world = uevrUtils.get_world()
	if world ~= nil then
		local hit = kismet_system_library:LineTraceSingle(world, originPosition, endLocation, reticuleCollisionChannel, false, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
		if hit and reusable_hit_result.Distance > 100 then
			endLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
		end
	end

	return endLocation
end

function M.update(originLocation, targetLocation, distance, scale, rotation, allowAutoHandle )
	if allowAutoHandle ~= true then
		autoHandleInput = false --if something else is calling this then dont auto handle input
	end

	if uevrUtils.getValid(reticuleComponent) ~= nil and reticuleComponent.K2_SetWorldLocationAndRotation ~= nil then
		if distance == nil then distance = reticuleUpdateDistance end
		if scale == nil then scale = {reticuleUpdateScale,reticuleUpdateScale,reticuleUpdateScale} end
		if rotation == nil then rotation = reticuleUpdateRotation end
		rotation = uevrUtils.rotator(rotation)

		if originLocation == nil or targetLocation == nil then
			local playerController = uevr.api:get_player_controller(0)
			local playerCameraManager = nil
			if playerController ~= nil then
				playerCameraManager = playerController.PlayerCameraManager
			end

			if originLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraLocation ~= nil then
					originLocation = playerCameraManager:GetCameraLocation()
				else
					originLocation = M.getOriginPositionFromController()
				end
			end

			if targetLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraRotation ~= nil then
					local direction = kismet_math_library:GetForwardVector(playerCameraManager:GetCameraRotation())
					targetLocation = M.getTargetLocation(originLocation, direction)
				else
					targetLocation = M.getTargetLocationFromController(Handed.Right)
				end
			end
		end

		if originLocation ~= nil and targetLocation ~= nil then
			local maxDistance =  kismet_math_library:Vector_Distance(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			--print(maxDistance)
			local hmdToTargetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			if distance > maxDistance - 10 then distance = maxDistance - 10 end --move target distance back slightly so reticule doesnt go through the target
			temp_vec3f:set(hmdToTargetDirection.X,hmdToTargetDirection.Y,hmdToTargetDirection.Z)
			local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
			rot = uevrUtils.sumRotators(rot, reticuleRotation, rotation)
			---@cast reticulePosition -nil
			temp_vec3f:set(originLocation.X + (hmdToTargetDirection.X * distance) + reticulePosition.X, originLocation.Y + (hmdToTargetDirection.Y * distance) + reticulePosition.Y, originLocation.Z + (hmdToTargetDirection.Z * distance) + reticulePosition.Z)
			reticuleComponent:K2_SetWorldLocationAndRotation(temp_vec3f, rot, false, reusable_hit_result, false)
			if scale ~= nil then
				reticuleComponent:SetWorldScale3D(kismet_math_library:Multiply_VectorVector(uevrUtils.vector(scale), reticuleScale))
			end
		end
	else
		--M.print("Update failed component not valid")
	end
end

configui.onCreateOrUpdate("reticuleUpdateDistance", function(value)
	M.setDistance(value)
end)

configui.onCreateOrUpdate("reticuleUpdateScale", function(value)
	M.setScale(value)
end)

configui.onCreateOrUpdate("reticuleUpdateRotation", function(value)
	M.setRotation(value)
end)

configui.onCreateOrUpdate("reticuleRemoveFromViewport", function(value)
	reticuleRemoveFromViewport = value
	destroyReticuleComponent()
end)

configui.onCreateOrUpdate("reticuleTwoSided", function(value)
	reticuleTwoSided = value
	destroyReticuleComponent()
end)

configui.onUpdate("uevr_reticule_refresh_button", function(value)
	updateReticuleList()
end)

configui.onCreateOrUpdate("uevr_reticule_widget_class", function(value)
	M.setDefaultWidgetClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_mesh_class", function(value)
	M.setDefaultMeshClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_mesh_material_class", function(value)
	M.setDefaultMeshMaterialClass(value)
end)

configui.onCreateOrUpdate("uevr_reticule_type", function(value)
	M.setReticuleType(value)
end)



uevrUtils.setInterval(1000, function()
	if reticuleAutoCreationType ~= M.ReticuleType.None and not M.exists() then
		if reticuleAutoCreationType == M.ReticuleType.Custom then
			local reticuleType, element, options = uevrUtils.executeUEVRCallbacks("on_reticule_create")
			if reticuleType == M.ReticuleType.Widget then
				M.createFromWidget(element, options)
			elseif reticuleType == M.ReticuleType.Mesh then
				M.createFromMesh(element, options)
			elseif reticuleType == M.ReticuleType.Default then
				M.create()
			end
		else
			autoCreateReticule()
		end
	end
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	M.print("Pre-Level changed in reticule")
	M.reset()
end)

uevrUtils.registerPreEngineTickCallback(function(engine, delta)
	if autoHandleInput == true then
		M.update(nil, nil, nil, nil, nil, true)
	end
end)

uevr.params.sdk.callbacks.on_script_reset(function()
	resetSelectedWidget()
	destroyReticuleComponent()
end)

return M
