---@class WidgetBlueprintLibrary
---@field GetAllWidgetsOfClass function

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local headLockedUI = false
local headLockedUISize = 2.0
local headLockedUIPosition = {X=0, Y=0, Z=2.0}
local isFollowing = true
local reduceMotionSickness = false
local isInMotionSicknessCausingScene
local isGamePaused = false

local viewportWidgetList = {}
local viewportWidgetIDList = {}
local viewportWidgetState = {viewLocked = false, activeWidget = nil}

local parametersFileName = "ui_parameters"
local parameters = {}
local isParametersDirty = false

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[ui] " .. text, logLevel)
	end
end

local configWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_ui",
		initialOpen = true,
		label = "UI Configuration"
	},
       {
            widgetType = "checkbox",
            id = "headLockedUI",
            label = "Enable Head Locked UI",
            initialValue = headLockedUI
        },
		{
			widgetType = "drag_float3",
			id = "headLockedUIPosition",
			label = "UI Position",
			speed = .01,
			range = {-10, 10},
			initialValue = headLockedUIPosition
		},
		{
			widgetType = "drag_float",
			id = "headLockedUISize",
			label = "UI Size",
			speed = .01,
			range = {-10, 10},
			initialValue = headLockedUISize
		},
        {
            widgetType = "checkbox",
            id = "reduceMotionSickness",
            label = "Reduce Motion Sickness in Cutscenes",
            initialValue = reduceMotionSickness
        },
	{
		widgetType = "tree_pop"
	},
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_ui_widgets",
		initialOpen = true,
		label = "UI Widget Configuration"
	},
		{
			widgetType = "combo",
			id = "knownViewportWidgetList",
			label = "Widgets",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
        {
            widgetType = "begin_group",
            id = "knowViewportWidgetSettings",
            isHidden = false
        },
 			{
				widgetType = "checkbox",
				id = "shouldLockViewWhenVisible",
				label = "Should Lock View When Visible",
				initialValue = false
			},
 			{
				widgetType = "checkbox",
				id = "useControllerMouse",
				label = "Use Controller Mouse",
				initialValue = false
			},
        {
            widgetType = "end_group",
        },
		{
			widgetType = "input_text",
			id = "lastWidgetPlayed",
			label = "Last Widget Played",
			initialValue = "",
		},
	{
		widgetType = "tree_pop"
	},
}

local function updateUI()
    --print(headLockedUI ,isFollowing, not isGamePaused)
    local canFollowView = headLockedUI and viewportWidgetState["viewLocked"] ~= true and isFollowing and not isGamePaused
    uevrUtils.enableUIFollowsView(canFollowView)
    if canFollowView then
        uevrUtils.setUIFollowsViewOffset(headLockedUIPosition)
        uevrUtils.setUIFollowsViewSize(headLockedUISize)
    else
        uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=2.0})
        uevrUtils.setUIFollowsViewSize(2.0)
    end
end

local function showViewportWidgetEditFields()
    local index = configui.getValue("knownViewportWidgetList")
    if index == nil or index == 1 then
        configui.setHidden("knowViewportWidgetSettings", true)
        return
    end
    configui.setHidden("knowViewportWidgetSettings", false)

    local id = viewportWidgetIDList[index]
    if id ~= "" and parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
        local data = parameters["widgetlist"][id]
        if data ~= nil then
            if data["shouldLockViewWhenVisible"] == nil then data["shouldLockViewWhenVisible"] = false end
            configui.setValue("shouldLockViewWhenVisible", data["shouldLockViewWhenVisible"], true)
            if data["useControllerMouse"] == nil then data["useControllerMouse"] = false end
            configui.setValue("useControllerMouse", data["useControllerMouse"], true)
        end
    end
end

local function updateCurrentViewportWidgetFields()
    local index = configui.getValue("knownViewportWidgetList")
    if index ~= nil and index ~= 1 then
        local id = viewportWidgetIDList[index]
        if id ~= "" and  parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
            parameters["widgetlist"][id]["shouldLockViewWhenVisible"] = configui.getValue("shouldLockViewWhenVisible")
            parameters["widgetlist"][id]["useControllerMouse"] = configui.getValue("useControllerMouse")
            isParametersDirty = true
        end
    end
end

local function updateViewportWidgetList()
    viewportWidgetList = {}
    viewportWidgetIDList = {}
    if parameters ~= nil and parameters["widgetlist"] ~= nil then
       for id, data in pairs(parameters["widgetlist"]) do
          if data ~= nil and data["label"] ~= nil then
              table.insert(viewportWidgetList, data["label"])
              table.insert(viewportWidgetIDList, id)
          end
        end
        table.insert(viewportWidgetList, 1, "None")
        table.insert(viewportWidgetIDList, 1, "")
        configui.setSelections("knownViewportWidgetList", viewportWidgetList)
        configui.setValue("knownViewportWidgetList", 1)

        showViewportWidgetEditFields()
    end
end

local function registerViewportWidget(widgetClassName, widgetShortName)
   if parameters ~= nil and widgetClassName ~= nil and widgetClassName ~= "" then
        if parameters["widgetlist"] == nil then
            parameters["widgetlist"] = {}
        end
        if parameters["widgetlist"][widgetClassName] == nil then
            parameters["widgetlist"][widgetClassName] = {}
            parameters["widgetlist"][widgetClassName]["label"] = widgetShortName
            isParametersDirty = true

            updateViewportWidgetList()
        end
        configui.setValue("lastWidgetPlayed", widgetClassName)
    end
end

local function registerViewportWidgets()
	local foundWidgets = {}
	local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
    WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
	--print("Found widgets: " .. #foundWidgets)
	for index, widget in pairs(foundWidgets) do
		--print(widget:get_full_name(), widget:get_class():get_full_name(), widget:IsInViewport())
        registerViewportWidget(widget:get_class():get_full_name(), uevrUtils.getShortName(widget:get_class()))
 	end
end

local function updateViewportWidgets()
    if parameters ~= nil and parameters["widgetlist"] ~= nil then
        viewportWidgetState.viewLocked = false
        viewportWidgetState.activeWidget = nil
        local foundWidgets = {}
        local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
        WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
        --print("Found widgets: " .. #foundWidgets)
        for index, widget in pairs(foundWidgets) do
            if widget:IsInViewport() then
                --get the widget data from the configurations
                local id = widget:get_class():get_full_name()
                local data = parameters["widgetlist"][id]
                if data ~= nil then
                    if data["shouldLockViewWhenVisible"] == true then
                        viewportWidgetState.viewLocked = true
                    end
                    if data["useControllerMouse"] == true then
                        viewportWidgetState.activeWidget = widget
                    end
                end
            end  
        end
    end 
end

local function saveParameters()
	M.print("Saving ui parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        registerViewportWidgets()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
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
	    M.showDeveloperConfiguration("ui_config_dev")
        createDevMonitor()
        updateViewportWidgetList()
    end
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading ui parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating ui parameters")
	end

    updateViewportWidgetList()
 end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("UI Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("UI Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

configui.onCreateOrUpdate("knownViewportWidgetList", function(value)
	showViewportWidgetEditFields()
end)

configui.onCreateOrUpdate("shouldLockViewWhenVisible", function(value)
	updateCurrentViewportWidgetFields()
end)

configui.onCreateOrUpdate("useControllerMouse", function(value)
	updateCurrentViewportWidgetFields()
end)


configui.onCreate("reduceMotionSickness", function(value)
	reduceMotionSickness = value
end)

configui.onUpdate("reduceMotionSickness", function(value)
	if reduceMotionSickness then
		uevrUtils.enableCameraLerp(value, true, true, true)
    else
        uevrUtils.enableCameraLerp(value and isInMotionSicknessCausingScene, true, true, true)
	end
	reduceMotionSickness = value
end)

configui.onCreateOrUpdate("headLockedUI", function(value)
	M.setIsHeadLocked(value)
    configui.setHidden("headLockedUIPosition", not value)
    configui.setHidden("headLockedUISize", not value)
end)

configui.onCreateOrUpdate("headLockedUIPosition", function(value)
	M.setHeadLockedUIPosition(value)
end)

configui.onCreateOrUpdate("headLockedUISize", function(value)
    M.setHeadLockedUISize(value)
end)

function M.getViewportWidgetState()
    return viewportWidgetState
end

function M.getActiveViewportWidget()
    return viewportWidgetState.activeWidget
end

function M.disableHeadLockedUI(value)
    if not value ~= isFollowing then
        isFollowing = not value
        updateUI()
    end
end

function M.setIsHeadLocked(value)
    configui.setValue("headLockedUI", value, true)
    headLockedUI = value
    if uevrUtils.isGamePaused() then
        M.disableHeadLockedUI(true)
    end
    updateUI()
end

function M.setHeadLockedUIPosition(value)
    print("Setting UI Position to ", value.X, value.Y, value.Z)
    configui.setValue("headLockedUIPosition", value, true)
    headLockedUIPosition = value
    updateUI()
end
function M.setHeadLockedUISize(value)
    configui.setValue("headLockedUISize", value, true)
    headLockedUISize = value
    updateUI()
end

function M.setIsInMotionSicknessCausingScene(value)
    isInMotionSicknessCausingScene = value
    if reduceMotionSickness then
        uevrUtils.enableCameraLerp(isInMotionSicknessCausingScene, true, true, true)
    end
end

uevrUtils.registerGamePausedCallback(function(isPaused)
    if isGamePaused ~= isPaused then
        isGamePaused = isPaused
        updateUI()
    end
end)

uevrUtils.setInterval(200, function()
    updateViewportWidgets()
    updateUI()
end)

M.loadParameters()

return M