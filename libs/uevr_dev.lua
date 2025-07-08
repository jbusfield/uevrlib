local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")

local M = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[dev] " .. text, logLevel)
	end
end

local meshNames = {}
local currentComponent = nil
local currentSelectionIndex = 1
local configDefinition = {
	{
		panelLabel = "Dev Utils", 
		saveFile = "config_dev_utils", 
		layout = 
		{
			{
				widgetType = "tree_node",
				id = "uevr_dev_static_mesh_viewer",
				label = "Static Mesh Viewer"
			},
				{
					widgetType = "input_text",
					id = "uevr_dev_static_mesh_filter",
					label = "Filter",
					initialValue = ""
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "button",
					id = "uevr_dev_static_mesh_refresh_button",
					label = "Refresh",
					size = {80,22}
				},
				{
					widgetType = "button",
					id = "uevr_dev_static_mesh_prev",
					label = "<",
					size = {40,22}
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "combo",
					id = "uevr_dev_static_mesh_list",
					label = "",
					selections = {"None"},
					initialValue = 1
				},
				{
					widgetType = "same_line",
				},
				{
					widgetType = "button",
					id = "uevr_dev_static_mesh_next",
					label = ">",
					size = {40,22}
				},
				{
					widgetType = "begin_group"
				},
					{
						widgetType = "text",
						id = "uevr_dev_static_mesh_total_count",
						label = "Total static meshes"
					},
					{
						widgetType = "text",
						id = "uevr_dev_static_mesh_filtered_count",
						label = "Filtered static meshes"
					},
				{
					widgetType = "end_group"
				},
				{
					widgetType = "indent",
					width = 12
				},
				{
					widgetType = "text",
					label = "UI"
				},
				{
					widgetType = "begin_rect",
				},
					{
						widgetType = "checkbox",
						id = "uevr_dev_static_mesh_nativescale",
						label = "Show at native scale",
						initialValue = false
					},
					{
						widgetType = "drag_float",
						id = "uevr_dev_static_mesh_relativescale",
						label = "Scale Adjust",
						speed = 0.01,
						range = {0.01, 10},
						initialValue = 1.0
					},
				{
					widgetType = "end_rect",
					additionalSize = 12,
					rounding = 5
				},
				{
					widgetType = "unindent",
					width = 12
				},
			{
				widgetType = "tree_pop"
			},
		}
	}
}

function setCurrentComponentScale()
	if configui.getValue("uevr_dev_static_mesh_nativescale") == false then
		local scale = 10 / currentComponent.StaticMesh.ExtendedBounds.SphereRadius
		local scaleMultiplier = configui.getValue("uevr_dev_static_mesh_relativescale")
		currentComponent.RelativeScale3D.X = scale * scaleMultiplier
		currentComponent.RelativeScale3D.Y = scale * scaleMultiplier
		currentComponent.RelativeScale3D.Z = scale * scaleMultiplier
	end
end

function updateMesh()
	if currentComponent ~= nil then
		uevrUtils.detachAndDestroyComponent(currentComponent, false, true)
		currentComponent = nil
	end

	currentComponent = uevrUtils.createStaticMeshComponent(meshNames[currentSelectionIndex])
	if uevrUtils.getValid(currentComponent) ~= nil then
		M.print("Created component " .. currentComponent:get_full_name(), LogLevel.Critical)
		setCurrentComponentScale()
		local leftConnected = controllers.attachComponentToController(Handed.Left, currentComponent, nil, nil, nil, true)
	end
end

function M.init()
	configui.create(configDefinition)
	M.displayStaticMeshes(configui.getValue("uevr_dev_static_mesh_filter"))
	configui.hideWidget("uevr_dev_static_mesh_relativescale", configui.getValue("uevr_dev_static_mesh_nativescale"))
end

function M.onLevelChange()
	M.print("Level changed")
	M.displayStaticMeshes(configui.getValue("uevr_dev_static_mesh_filter"))
end

function M.displayStaticMeshes(searchText)
	if searchText == nil then searchText = "" end
	local meshes = uevrUtils.find_all_instances("Class /Script/Engine.StaticMesh", false)
	--print(#meshes, searchText)
	meshNames = {}
	for name, mesh in pairs(meshes) do
		--print(mesh:get_full_name())
		if searchText == nil or searchText == "" or string.find(mesh:get_full_name(), searchText) then
			table.insert(meshNames, mesh:get_full_name())
		end
	end
	--print(#meshNames)
	
	configui.setLabel("uevr_dev_static_mesh_total_count", "Total static meshes:" .. #meshes)
	configui.setLabel("uevr_dev_static_mesh_filtered_count", "Filtered static meshes:" .. #meshNames)
	configui.setSelections("uevr_dev_static_mesh_list", meshNames)
end

configui.onUpdate("uevr_dev_static_mesh_filter", function(value)
	M.displayStaticMeshes(value)
end)


configui.onUpdate("uevr_dev_static_mesh_nativescale", function(value)
	updateMesh()
	configui.hideWidget("uevr_dev_static_mesh_relativescale", value)
end)

configui.onUpdate("uevr_dev_static_mesh_relativescale", function(value)
	setCurrentComponentScale()
end)

configui.onUpdate("uevr_dev_static_mesh_refresh_button", function(value)
	M.displayStaticMeshes(configui.getValue("uevr_dev_static_mesh_filter"))
end)

configui.onUpdate("uevr_dev_static_mesh_prev", function(value)
	currentSelectionIndex = currentSelectionIndex - 1
	if currentSelectionIndex < 1 then currentSelectionIndex = 1 end
	if currentSelectionIndex <= #meshNames then
		configui.setValue("uevr_dev_static_mesh_list", currentSelectionIndex)
	end
end)

configui.onUpdate("uevr_dev_static_mesh_next", function(value)
	currentSelectionIndex = currentSelectionIndex + 1
	if currentSelectionIndex > #meshNames then currentSelectionIndex = #meshNames end
	if currentSelectionIndex <= #meshNames then
		configui.setValue("uevr_dev_static_mesh_list", currentSelectionIndex)
	end
end)

configui.onUpdate("uevr_dev_static_mesh_list", function(value)
	M.print("Using mesh at index " .. value .. " - " .. meshNames[value], LogLevel.Critical)
	currentSelectionIndex = value
	updateMesh()
end)


return M