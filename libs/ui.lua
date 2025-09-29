--[[ 
Usage
    Drop the lib folder containing this file into your project folder

     Add code like this in your script:
        local ui = require("libs/ui")
        local isDeveloperMode = true  
        ui.init(isDeveloperMode)

    This module allows you to configure a head-locked UI mode that keeps the UI in front 
    of your view which is useful for roomscale. You can also enable a motion sickness 
    reduction mode that smooths camera movements during cutscenes and other 
    motion-sickness-inducing scenes.

    Available functions:

    ui.init(isDeveloperMode, logLevel) - initializes the UI system
        example:
            ui.init(true, LogLevel.Debug)

    ui.setIsHeadLocked(value) - enables/disables head-locked UI mode
        example:
            ui.setIsHeadLocked(true)

    ui.setHeadLockedUIPosition(value) - sets the position of head-locked UI
        example:
            ui.setHeadLockedUIPosition({X=0, Y=0, Z=2.0})

    ui.setHeadLockedUISize(value) - sets the size of head-locked UI
        example:
            ui.setHeadLockedUISize(2.0)

    ui.disableHeadLockedUI(value) - temporarily disables head-locked UI without changing its state
        example:
            ui.disableHeadLockedUI(true)

    ui.getViewportWidgetState() - gets the current state of viewport widgets
        example:
            local state = ui.getViewportWidgetState()
            -- state contains: viewLocked, screen2D, decouplePitch, inputEnabled, handsEnabled

    ui.setIsInMotionSicknessCausingScene(value) - sets whether current scene may cause motion sickness
        example:
            ui.setIsInMotionSicknessCausingScene(true)

    ui.registerIsInMotionSicknessCausingSceneCallback(func) - registers a callback for motion sickness scene changes
        Second param  is an optional priority. Higher priority callbacks override lower priority ones.
        If the second param is not provided it defaults to 0.
        example:
            ui.registerIsInMotionSicknessCausingSceneCallback(function()
                return isInMotionSicknessCausingScene, 0
            end)

    ui.loadParameters(fileName) - loads UI parameters from a file
        example:
            ui.loadParameters("ui_config")

    ui.getConfigurationWidgets(options) - gets configuration UI widgets
        example:
            local widgets = ui.getConfigurationWidgets()

    ui.getDeveloperConfigurationWidgets(options) - gets developer configuration UI widgets
        example:
            local widgets = ui.getDeveloperConfigurationWidgets()

    ui.showConfiguration(saveFileName, options) - shows basic configuration UI
        example:
            ui.showConfiguration("ui_config")

    ui.showDeveloperConfiguration(saveFileName, options) - shows developer configuration UI
        example:
            ui.showDeveloperConfiguration("ui_config_dev")

    ui.setLogLevel(val) - sets the logging level for UI messages
        example:
            ui.setLogLevel(LogLevel.Debug)

    ui.print(text, logLevel) - prints a debug/log message with the specified log level
        example:
            ui.print("UI initialized", LogLevel.Info)


]]--


local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local input = require("libs/input")
local hands = require("libs/hands")

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
local viewportWidgetState = {viewLocked = nil, screen2D = nil, decouplePitch = nil, inputEnabled = nil, handsEnabled = nil}

local stateConfig = {
    {stateKey = "viewLocked", valueKey = "lockedUIWhenActive"},
    {stateKey = "screen2D", valueKey = "screen2DWhenActive"},
    {stateKey = "decouplePitch", valueKey = "decouplePitchWhenActive"},
    {stateKey = "inputEnabled", valueKey = "inputWhenActive"},
    {stateKey = "handsEnabled", valueKey = "handsWhenActive"}
}

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

local helpText = "This module allows you to configure how the system behaves when UI overlays such as dialogs and menus are active. You can set whether the view is locked when a widget is active, whether 2D mode is enabled, whether pitch is decoupled, whether input is enabled, and whether hands are shown. Settings are applied based on priority, so if multiple widgets are active, the one with the highest priority for a given setting takes precedence. For example, if one active widget sets 'Screen 2D' to 'Enable' with priority 5, and another active widget sets it to 'Disable' with priority 10, the screen will not be 2D because the second widget has a higher priority."
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
            { widgetType = "indent", width = 20 },
	        { widgetType = "begin_group", id = "viewport_widget_config", isHidden = false }, { widgetType = "indent", width = 5 }, { widgetType = "text", label = "When Active" }, { widgetType = "begin_rect", },
            { widgetType = "text", label = "State                                       Priority"},
            {
                widgetType = "combo",
                id = "lockedUIWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "lockedUIWhenActivePriority",
                label = " Locked UI",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "screen2DWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
		    { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "screen2DWhenActivePriority",
                label = " Screen 2D",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "decouplePitchWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "decouplePitchWhenActivePriority",
                label = " Decoupled Pitch",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "inputWhenActive",
                label = "",
                selections = {"No effect", "Enable", "Disable"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "inputWhenActivePriority",
                label = " Input",
                initialValue = "0",
                width = 35,
            },
            {
                widgetType = "combo",
                id = "handsWhenActive",
                label = "",
                selections = {"No effect", "Show", "Hide"},
                initialValue = 1,
                width = 150,
            },
            { widgetType = "same_line" },
            {
                widgetType = "input_text",
                id = "handsWhenActivePriority",
                label = " Hands",
                initialValue = "0",
                width = 35,
            },
            { widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 5 }, { widgetType = "end_group", },	
            { widgetType = "unindent", width = 20 },
        {
            widgetType = "end_group",
        },
		{ widgetType = "new_line" },
		{ widgetType = "text", label = "Current Viewport Widgets"},
        {
            widgetType = "input_text_multiline",
            id = "currentViewportWidgets",
            label = " ",
            initialValue = "",
            size = {440, 230} -- optional, will default to full size without it
        },
		-- {
		-- 	widgetType = "input_text",
		-- 	id = "lastWidgetPlayed",
		-- 	label = "Last Widget Played",
		-- 	initialValue = "",
		-- },
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

local function updateUI()
    --print(headLockedUI ,isFollowing, not isGamePaused)
    local canFollowView = ((headLockedUI and viewportWidgetState["viewLocked"] ~= true) or (not headLockedUI and viewportWidgetState["viewLocked"] == true)) and isFollowing and not isGamePaused
    uevrUtils.enableUIFollowsView(canFollowView)
    if canFollowView then
        uevrUtils.setUIFollowsViewOffset(headLockedUIPosition)
        uevrUtils.setUIFollowsViewSize(headLockedUISize)
    else
        uevrUtils.setUIFollowsViewOffset({X=0, Y=0, Z=2.0})
        uevrUtils.setUIFollowsViewSize(2.0)
    end

    if viewportWidgetState["screen2D_last"] ~= viewportWidgetState["screen2D"] then
        if viewportWidgetState["screen2D_last"] == nil then
            viewportWidgetState["screen2D_cache"] = uevrUtils.get_2D_mode()
        end
        if viewportWidgetState["screen2D"] == nil then
            uevrUtils.set_2D_mode(viewportWidgetState["screen2D_cache"])
        else
            uevrUtils.set_2D_mode(viewportWidgetState["screen2D"])
        end
        viewportWidgetState["screen2D_last"] = viewportWidgetState["screen2D"]
        --M.print("Setting 2D mode to " .. tostring(viewportWidgetState["screen2D"]))
    end

    if viewportWidgetState["decouplePitch_last"] ~= viewportWidgetState["decouplePitch"] then
        if viewportWidgetState["decouplePitch_last"] == nil then
            viewportWidgetState["decouplePitch_cache"] = uevrUtils.get_decoupled_pitch()
        end
        if viewportWidgetState["decouplePitch"] == nil then
            uevrUtils.set_decoupled_pitch(viewportWidgetState["decouplePitch_cache"])
        else
            uevrUtils.set_decoupled_pitch(viewportWidgetState["decouplePitch"])
        end
        viewportWidgetState["decouplePitch_last"] = viewportWidgetState["decouplePitch"]
    end

end

input.registerIsDisabledCallback(function()
	return viewportWidgetState["inputEnabled"] ~= nil and (not viewportWidgetState["inputEnabled"]) or nil, viewportWidgetState["inputEnabledPriority"]
end)

hands.registerIsHiddenCallback(function()
	return viewportWidgetState["handsEnabled"] ~= nil and (not viewportWidgetState["handsEnabled"]) or nil, viewportWidgetState["handsEnabledPriority"]
end)

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
            -- Initialize and set values for all state configs
            for _, config in ipairs(stateConfig) do
                local valueKey = config.valueKey
                if data[valueKey] == nil then data[valueKey] = 1 end
                configui.setValue(valueKey, data[valueKey], true)
                
                local priorityKey = valueKey .. "Priority"
                if data[priorityKey] == nil or data[priorityKey] == "" then data[priorityKey] = "0" end
                configui.setValue(priorityKey, data[priorityKey], true)
            end
        end
    end
end
--WBP_Fullscreenhint_Single_C
--TerminalSuslik
--WBP_TerminalWidget
--WBP_MainMenu_C
--WBP_Dialog_C
--WBP_CraftWindowMain_C
local function updateCurrentViewportWidgetFields()
    local index = configui.getValue("knownViewportWidgetList")
    if index ~= nil and index ~= 1 then
        local id = viewportWidgetIDList[index]
        if id ~= "" and  parameters ~= nil and parameters["widgetlist"] ~= nil and parameters["widgetlist"][id] ~= nil then
            for _, config in ipairs(stateConfig) do
                local valueKey = config.valueKey
                parameters["widgetlist"][id][valueKey] = configui.getValue(valueKey)
                parameters["widgetlist"][id][valueKey .. "Priority"] = configui.getValue(valueKey .. "Priority")
            end
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
            isParametersDirty = true
        end
        if parameters["widgetlist"][widgetClassName] == nil then
            parameters["widgetlist"][widgetClassName] = {}
            parameters["widgetlist"][widgetClassName]["label"] = widgetShortName
            isParametersDirty = true

            updateViewportWidgetList()
        end
        --configui.setValue("lastWidgetPlayed", widgetClassName)
    end
end

local function registerViewportWidgets()
	local foundWidgets = {}
	local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
    ---@diagnostic disable-next-line: undefined-field
    WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
	--print("Found widgets: " .. #foundWidgets)
	for index, widget in pairs(foundWidgets) do
		--print(widget:get_full_name(), widget:get_class():get_full_name(), widget:IsInViewport())
        registerViewportWidget(widget:get_class():get_full_name(), uevrUtils.getShortName(widget:get_class()))
 	end
end

local function updateViewportWidgets()
    local currentWidgetsStr = ""
    if parameters ~= nil and parameters["widgetlist"] ~= nil then
        for _, config in ipairs(stateConfig) do
            viewportWidgetState[config.stateKey] = nil
            viewportWidgetState[config.stateKey .. "Priority"] = 0
        end
    
        --viewportWidgetState.activeWidget = nil
        local foundWidgets = {}
        local widgetClass = uevrUtils.get_class("Class /Script/UMG.UserWidget")
        ---@diagnostic disable-next-line: undefined-field
        WidgetBlueprintLibrary:GetAllWidgetsOfClass(uevrUtils.get_world(), foundWidgets, widgetClass, true)
        --print("Found widgets: " .. #foundWidgets)
        for index, widget in pairs(foundWidgets) do
            if widget:IsInViewport() then
                --get the widget data from the configurations
                local id = widget:get_class():get_full_name()
                local data = parameters["widgetlist"][id]
                if data ~= nil then
                    if data["label"] ~= nil then         
                        currentWidgetsStr = currentWidgetsStr .. data["label"] .. "\n"
                    end

                    local function updateStateIfHigherPriority(stateKey, valueKey)
                        local priority = tonumber(data[valueKey .. "Priority"]) or 0
                        if priority >= viewportWidgetState[stateKey .. "Priority"] then
                            if data[valueKey] == 2 then
                                viewportWidgetState[stateKey] = true
                                viewportWidgetState[stateKey .. "Priority"] = priority
                            elseif data[valueKey] == 3 then
                                viewportWidgetState[stateKey] = false
                                viewportWidgetState[stateKey .. "Priority"] = priority
                            end
                        end
                    end

                    for _, config in ipairs(stateConfig) do
                        updateStateIfHigherPriority(config.stateKey, config.valueKey)
                    end
                    -- if data["shouldLockViewWhenVisible"] == true then
                    --     viewportWidgetState.viewLocked = true
                    -- end
                    -- if data["useControllerMouse"] == true then
                    --     viewportWidgetState.activeWidget = widget
                    -- end
                end
            end  
        end
    end
    configui.setValue("currentViewportWidgets", currentWidgetsStr) 
end

local function saveParameters()
	M.print("Saving ui parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(500, function()
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

configui.onUpdate("knownViewportWidgetList", function(value)
	showViewportWidgetEditFields()
end)

-- configui.onCreateOrUpdate("shouldLockViewWhenVisible", function(value)
-- 	updateCurrentViewportWidgetFields()
-- end)

-- configui.onCreateOrUpdate("useControllerMouse", function(value)
-- 	updateCurrentViewportWidgetFields()
-- end)

-- Register update handlers for all state configs and their priorities
for _, config in ipairs(stateConfig) do
    local valueKey = config.valueKey
    configui.onUpdate(valueKey, function(value)
        updateCurrentViewportWidgetFields()
    end)
    configui.onUpdate(valueKey .. "Priority", function(value)
        updateCurrentViewportWidgetFields()
    end)
end


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

-- function M.getActiveViewportWidget()
--     return viewportWidgetState.activeWidget
-- end

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
    --M.print("Setting UI Position to " .. value.X .. ", " .. value.Y .. ", " .. value.Z)
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

local function executeIsInMotionSicknessCausingSceneCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_in_motion_sickness_causing_scene", table.unpack({...}))
end

function M.registerIsInMotionSicknessCausingSceneCallback(func)
	uevrUtils.registerUEVRCallback("is_in_motion_sickness_causing_scene", func)
end

uevrUtils.registerGamePausedCallback(function(isPaused)
    if isGamePaused ~= isPaused then
        isGamePaused = isPaused
        updateUI()
    end
end)

local isInMotionSicknessCausingSceneLast = false
uevrUtils.setInterval(200, function()
    updateViewportWidgets()

    updateUI()

    local m_isInMotionSicknessCausingScene, priority = executeIsInMotionSicknessCausingSceneCallback()
	if m_isInMotionSicknessCausingScene ~= isInMotionSicknessCausingSceneLast then
		isInMotionSicknessCausingSceneLast = m_isInMotionSicknessCausingScene
		M.setIsInMotionSicknessCausingScene(m_isInMotionSicknessCausingScene)
	end
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	isInMotionSicknessCausingSceneLast = false
end)

M.loadParameters()

return M