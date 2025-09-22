local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local parametersFileName = "montage_parameters"
local parameters = {}
local isParametersDirty = false

local montageList = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[attachments] " .. text, logLevel)
	end
end

local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_montage",
		initialOpen = true,
		label = "Montage Configuration"
	},
		{
			widgetType = "combo",
			id = "knownMontageList",
			label = "Montages",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{
			widgetType = "input_text",
			id = "lastMontagePlayed",
			label = "Last Montage Played",
			initialValue = "",
		},
	{
		widgetType = "tree_pop"
	},
}

local function updateMontageList()
    montageList = {}
    if parameters ~= nil then
        for id, data in pairs(parameters) do
            if data ~= nil and data["label"] ~= nil then
                table.insert(montageList, data["label"])
            end
        end
        table.sort(montageList)
        --table.insert(montageList, 1, "None")
        configui.setSelections("knownMontageList", montageList)
    end
end

local function saveParameters()
	M.print("Saving montage parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)

	uevrUtils.registerMontageChangeCallback(function(montage, montageName)
    if parameters ~= nil and montageName ~= nil and montageName ~= "" then
        if parameters[montageName] == nil then
            parameters[montageName] = {}
            parameters[montageName]["label"] = montageName
            isParametersDirty = true

            updateMontageList()
        end
        configui.setValue("lastMontagePlayed", montageName)
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
	    M.showDeveloperConfiguration("montage_config_dev")
        createDevMonitor()
        updateMontageList()
    end
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading montage parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating montage parameters")
	end

    updateMontageList()
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Montage Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Montage Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

M.loadParameters()

return M