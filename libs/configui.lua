--[[ 
Usage
	Drop the lib folder containing this file into your project folder
	Add code like this in any file. For example this could be added to a standalone file called config_hands.lua
		local configui = require("libs/configui")
		local configDefinition = {
			{
				panelLabel = "Hands", 
				saveFile = "config_hands", 
				layout = 
				{
					{
						widgetType = "checkbox",
						id = "use_hands",
						label = "Use Hands",
						initialValue = true
					}
				}
			}
		}
		configui.create(configDefinition)
	
	Available functions:
	
	configui.create(configDefinition) creates the imgui UI in the UEVR overlay based on the layout provided in the configDefinition
		example: 
			configui.create(configDefinition)

	configui.getValue(itemID) -- gets the current value of the item with the id field matching itemID. When creating id values in a configuration
		layout try to ensure uniqueness so that if multiple people are creating configs for the same project, the ids wont conflict. Be aware that
		the itemID can be that of any configDefiniton if multiple configDefinitons are used in the project. Also note
		the the itemID doesn't have to exist in a configDefiniton. If you want to keep track of config settings without providing a UI for it the the user, then
		you can do that as well.
		example
			local usingHands = configui.getValue("use_hands")
			local myVal = configui.getValue("some_id_that_doesnt_exist_in_any_config") -- returns nil until you set that value
			
	configui.setValue(itemID, value) -- sets the value of the given itemID
		example
			configui.setValue("use_hands", true)
			configui.setValue("some_id_that_doesnt_exist_in_any_config", 1) -- now getValue() will return 1

	configui.onUpdate(itemID, callbackFunction) -- allows you to define a callback function that triggers any time the value for the itemID changes for any reason,
		including being changed in the UI or being changed with code.
		example:
			configui.onUpdate("use_hands", function(value)
				if value == false then
					local count = configui.getValue("false_count")
					print("Current count", count)
					if count == nil then count = 0 end
					configui.setValue("false_count", count + 1)
					count = configui.getValue("false_count")
					print("New count", count)
				end
			end)

]]--

local M = {}

local configValues = {}
local itemMap = {}
local panelList = {}
local layoutDefinitions = {}
local updateFunctions = {}
local defaultFilename = "config_default"

local function doUpdate(panelID, widgetID, value, updateConfigValue)
	if panelID ~= nil then
		if updateConfigValue == nil then updateConfigValue = true end
		if updateConfigValue == true then
			if configValues[panelID] == nil then 
				configValues[panelID] = {} 
				itemMap[widgetID] = panelID
			end
			configValues[panelID][widgetID] = value
		end
		
		local funcList = updateFunctions[widgetID]
		if funcList ~= nil and #funcList > 0 then
			for i = 1, #funcList do
				funcList[i](value)
			end
		end
		panelList[panelID].isDirty = true
	else
		print("panelID is nil in doUpdate")
	end
end

local function colorStringToInteger(colorString)
	if colorString == nil then
		return 0
	end
    -- Remove the '#' character
    local hex = colorString:sub(2)
    
    -- Convert hex string to integer
    return tonumber(hex, 16)
end

local function getVector2FromArray(arr)
	local vec = UEVR_Vector2f.new()
	if arr == nil or #arr < 2 then
		vec.x = 0
		vec.y = 0
	else
		vec.x = arr[1]
		vec.y = arr[2]
	end
	return vec
end

local function getVector3FromArray(arr)
	if arr == nil or #arr < 3 then
		return Vector3f.new(0, 0, 0)
	end
	return Vector3f.new(arr[1], arr[2], arr[3])
end

local function getVector4FromArray(arr)
	if arr == nil or #arr < 4 then
		return Vector4f.new(0, 0, 0, 0)
	end
	return Vector4f.new(arr[1], arr[2], arr[3], arr[4])
end

local function getArrayFromVector2(vec)
	--vector 2 is broken
	return {0,0}
end

local function getArrayFromVector3(vec)
	if vec == nil then
		return {0,0,0}
	end
	return {vec.X, vec.Y, vec.Z}
end

local function getArrayFromVector4(vec)
	if vec == nil then
		return {0, 0, 0, 0}
	end
	return {vec.X, vec.Y, vec.Z, vec.W}
end

local function drawUI(panelID)
	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.widgetType == "checkbox" then
			local changed, newValue = imgui.checkbox(item.label, configValues[panelID][item.id])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "button" then
			local changed, newValue = imgui.button(item.label, item.size) 
			if changed then 
				doUpdate(panelID, item.id, true, false)
			end
		elseif item.widgetType == "small_button" then
			local changed, newValue = imgui.small_button(item.label, item.size) 
			if changed then 
				doUpdate(panelID, item.id, true, false)
			end
		elseif item.widgetType == "combo" then
		    local changed, newValue = imgui.combo(item.label, configValues[panelID][item.id], item.selections)
			if changed then
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "slider_int" then
			local changed, newValue = imgui.slider_int(item.label, configValues[panelID][item.id], item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "slider_float" then
			local changed, newValue = imgui.slider_float(item.label, configValues[panelID][item.id], item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "drag_int" then
			local changed, newValue = imgui.drag_int(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "drag_float" then
			local changed, newValue = imgui.drag_float(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "drag_float2" then
			local changed, newValue = imgui.drag_float2(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "drag_float3" then
			local changed, newValue = imgui.drag_float3(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "drag_float4" then
			local changed, newValue = imgui.drag_float4(item.label, configValues[panelID][item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "input_text" then
			local changed, newValue, selectionStart, selectionEnd = imgui.input_text(item.label, configValues[panelID][item.id])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "input_text_multiline" then
			local changed, newValue, selectionStart, selectionEnd = imgui.input_text_multiline(item.label, configValues[panelID][item.id], item.size)
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "color_picker" then
			local changed, newValue = imgui.color_picker(item.label, configValues[panelID][item.id])
			if changed then 
				doUpdate(panelID, item.id, newValue)
			end
		elseif item.widgetType == "begin_rect" then
			imgui.begin_rect()
		elseif item.widgetType == "end_rect" then
			imgui.end_rect(item.additionalSize ~= nil and item.additionalSize or 0, item.rounding ~= nil and item.rounding or 0)
		elseif item.widgetType == "begin_group" then
			imgui.begin_group()
		elseif item.widgetType == "end_group" then
			imgui.end_group()
		elseif item.widgetType == "begin_child_window" then
			imgui.begin_child_window(getVector2FromArray(item.size), item.border)
		elseif item.widgetType == "end_child_window" then
			imgui.end_child_window()
		elseif item.widgetType == "new_line" then
			imgui.new_line()
		elseif item.widgetType == "spacing" then
			imgui.spacing()
		elseif item.widgetType == "same_line" then
			imgui.same_line()
		elseif item.widgetType == "text" then
			imgui.text(item.label)
		elseif item.widgetType == "text_colored" then
			imgui.text_colored(item.label, colorStringToInteger(item.color))
		end
	end
end

local function getDefinitionElement(panelID, id)
	--print(panelID)
	local definition = layoutDefinitions[panelID]
	if definition ~= nil then
		for _, element in ipairs(definition) do
			if element.id == id then
				return element
			end
		end
	end
    return nil -- Return nil if the id is not found
end

function M.createPanel(panelDefinition)
	local label = panelDefinition["panelLabel"]
	local fileName = panelDefinition["saveFile"]
	if label == nil or label == "" or label == "Script UI" then
		label = "__default__"
		fileName = defaultFilename
	end
	
	local panelID = fileName
	if panelID == nil or panelID == "" then 
		panelID = label
	end
	
	layoutDefinitions[panelID] = panelDefinition["layout"]
	
		--print("Creating panel",label, fileName)
	if configValues[panelID] == nil then
		configValues[panelID] = {}
		
		if label == "__default__" then
			uevr.sdk.callbacks.on_draw_ui(function()
				drawUI(panelID)
			end)
		else
			uevr.lua.add_script_panel(label, function()
				drawUI(panelID)
			end)
		end
	end


	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.id ~= nil then
			if item.widgetType == "drag_float2" then
				configValues[panelID][item.id] = getVector2FromArray(item.initialValue)
			elseif item.widgetType == "drag_float3" then
				configValues[panelID][item.id] = getVector3FromArray(item.initialValue)
			elseif item.widgetType == "drag_float4" then
				configValues[panelID][item.id] = getVector4FromArray(item.initialValue)
			elseif item.widgetType == "color_picker" then
				configValues[panelID][item.id] = colorStringToInteger(item.initialValue)
			else
				configValues[panelID][item.id] = item.initialValue
			end
			itemMap[item.id] = panelID
		end
	end

	panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=fileName}

	M.load(panelID, fileName)
	
end

function M.create(configDefinition)
	
	if configDefinition ~= nil then
		for _, panel in ipairs(configDefinition) do
			M.createPanel(panel)
		end
	else
		print("Cant create create UI because no definition provided")
	end
	
	--Makes sure the default file is loaded if it exists so that dynamic config items can be loaded if necessary
	if configValues[defaultFilename] == nil then
		configValues[defaultFilename] = {}
		M.load(defaultFilename, defaultFilename)
	end
end

function M.load(panelID, fileName)
	--print("Loading config")
	if json == nil then
		json = require("jsonStorage")
	end
	if fileName ~= nil and fileName ~= "" then
		local loadConfig = json.load_file(fileName .. ".json")
		if loadConfig ~= nil then
			for key, val in pairs(loadConfig) do
				item = getDefinitionElement(panelID, key)
				if item ~= nil then
					if item.widgetType == "drag_float2" then
						configValues[panelID][key] = getVector2FromArray(val)
					elseif item.widgetType == "drag_float3" then
						configValues[panelID][key] = getVector3FromArray(val)
					elseif item.widgetType == "drag_float4" then
						configValues[panelID][key] = getVector4FromArray(val)
					else
						configValues[panelID][key] = val
					end
				else
					configValues[panelID][key] = val
				end
			end
		end
	end
end

function M.save(panelID)
	local panel = panelList[panelID]
	if panel ~= nil then
		local fileName = panel.fileName
		if fileName ~= nil and fileName ~= "" then
			--print("Saving config")
			--things like vector3 need to be converted into a json friendly format
			local saveConfig = {}
			for key, val in pairs(configValues[panelID]) do
				item = getDefinitionElement(panelID, key)
				if item ~= nil then
					if item.widgetType == "drag_float2" then
						saveConfig[key] = getArrayFromVector2(val)
					elseif item.widgetType == "drag_float3" then
						saveConfig[key] = getArrayFromVector3(val)
					elseif item.widgetType == "drag_float4" then
						saveConfig[key] = getArrayFromVector4(val)
					else
						saveConfig[key] = val
					end
				else
					saveConfig[key] = val
				end
			end
			
			if json == nil then
				json = require("jsonStorage")
			end
			--print(configValues)
			json.dump_file(fileName .. ".json", saveConfig, 4)
		end
	end
end

function M.onUpdate(widgetID, funcDef)
	if updateFunctions[widgetID] == nil then
		updateFunctions[widgetID] = {}
	end
	table.insert(updateFunctions[widgetID], funcDef)
end

function M.getValue(widgetID)
	local panelID = itemMap[widgetID]
	if panelID == nil then
		panelID = defaultFilename
	end
	if configValues[panelID] ~= nil then
		return configValues[panelID][widgetID]
	else
		--print("getValue no configValues for panelID",panelID)
	end
	return nil
end

function M.setValue(widgetID, value)
	local panelID = itemMap[widgetID]
	if panelID == nil then
		panelID = defaultFilename
		panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=defaultFilename}
	end
	doUpdate(panelID, widgetID, value)
end

function M.intToAARRGGBB(num)
    local a = (num >> 24) & 0xFF
    local b = (num >> 16) & 0xFF
    local g = (num >> 8) & 0xFF
    local r = num & 0xFF
    return string.format("#%02X%02X%02X%02X", a, r, g, b)
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	for panelID, element in pairs(panelList) do
		element.timeSinceLastSave = element.timeSinceLastSave + delta
		if element.isDirty == true and element.timeSinceLastSave > 1.0 then
			M.save(panelID)
			element.isDirty = false
			element.timeSinceLastSave = 0
        end
    end
end)

return M

