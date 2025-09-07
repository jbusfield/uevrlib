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

	configui.setLabel(itemID, newLabel) -- sets the label of the given itemID
		example
			configui.setLabel("use_hands", "Use Hands")

	configui.hideWidget(widgetID, value) -- hides widget if value is true or shows widget if value is false
		example
			configui.hideWidget("use_hands", true)

	configui.setSelections(widgetID, selections) --changes the available selections in a dropdown
		example
			configui.setSelections("selection_list", {"One","Two","Three"})
	
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
local createFunctions = {}
local createOrUpdateFunctions = {}
local defaultFilename = "config_default"
local treeInitialized = {}

local defaultPanelList = {}
local framePanelList = {}
local customPanelList = {}

local function doUpdate(panelID, widgetID, value, updateConfigValue, noCallbacks)
	if panelID ~= nil then
		if updateConfigValue == nil then updateConfigValue = true end
		if updateConfigValue == true then
			if configValues[panelID] == nil then 
				configValues[panelID] = {} 
				itemMap[widgetID] = panelID
			end
			configValues[panelID][widgetID] = value
		end
		
		if noCallbacks ~= true then
			local funcList = updateFunctions[widgetID]
			if funcList ~= nil and #funcList > 0 then
				for i = 1, #funcList do
					funcList[i](value)
				end
			end
			funcList = createOrUpdateFunctions[widgetID]
			if funcList ~= nil and #funcList > 0 then
				for i = 1, #funcList do
					funcList[i](value)
				end
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
	local treeDepth = 0
	local treeState = {}
	local groupHide = 0
	local isTreeOpen = false

	for _, item in ipairs(layoutDefinitions[panelID]) do
		if item.widgetType == "begin_group" and (groupHide > 0 or item.isHidden) then 
			groupHide = groupHide + 1 
		end
		if groupHide > 0 then goto continue end
		
		if item.isHidden ~= true and (treeDepth == 0 or treeState[treeDepth] == true or item.widgetType == "tree_node" or item.widgetType == "tree_node_ptr_id" or item.widgetType == "tree_node_str_id" or item.widgetType == "tree_pop") then 
			if item.label == "" then item.label = " " end --with an empty label, combos wont open
			if item.disabled == true then
				imgui.begin_disabled()
			end

			if item.id ~= nil and item.id ~= "" then
				imgui.push_id(item.id)
			end
			
			if item.width ~= nil and item.widgetType ~= "unindent" and item.widgetType ~= "indent" then
				imgui.set_next_item_width(item.width)
			end
			
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
			elseif item.widgetType == "tree_node" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					treeState[treeDepth] = imgui.tree_node(item.label)
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_node_ptr_id" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					treeState[treeDepth] = imgui.tree_node_ptr_id(item.id,item.label)
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_node_str_id" then
				treeDepth = treeDepth + 1
				if treeDepth - 1 == 0 or treeState[treeDepth - 1] == true then
					if treeInitialized[item.id] ~= true then
						imgui.set_next_item_open(item.initialOpen == true and true or false)
						treeInitialized[item.id] = true
					end
					treeState[treeDepth] = imgui.tree_node_str_id(item.id,item.label)
				else
					treeState[treeDepth] = false
				end
			elseif item.widgetType == "tree_pop" then
				if treeState[treeDepth] == true then
					imgui.tree_pop()
				end
				treeDepth = treeDepth - 1
			elseif item.widgetType == "collapsing_header" then
				imgui.collapsing_header(item.label)
			elseif item.widgetType == "new_line" then
				imgui.new_line()
			elseif item.widgetType == "spacing" then
				imgui.spacing()
			elseif item.widgetType == "same_line" then
				if item.spacing ~= nil then
					imgui.same_line(item.spacing)
				else
					imgui.same_line()
				end
			elseif item.widgetType == "spacing" then
				if item.spacing ~= nil then
					imgui.spacing(item.spacing)
				else
					imgui.spacing()
				end
			elseif item.widgetType == "text" then
				imgui.text(item.label)
			elseif item.widgetType == "indent" then
				imgui.indent(item.width)
			elseif item.widgetType == "unindent" then
				imgui.unindent(item.width)
			elseif item.widgetType == "text_colored" then
				imgui.text_colored(item.label, colorStringToInteger(item.color))
			end
			
			if item.id ~= nil and item.id ~= "" then
				imgui.pop_id()
			end

			if item.disabled == true then
				imgui.end_disabled()
			end
		end
		::continue::
		
		if item.widgetType == "end_group" then 
			if groupHide > 0 then
				groupHide = groupHide - 1
			end
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

local function wrapTextOnWordBoundary(text, maxCharsPerLine)
	if text == nil then text = "" end
 	if maxCharsPerLine == nil then maxCharsPerLine = 73 end
    local wrapped_text = ""
    local current_line_length = 0
    local words = {}

    -- Split the text into words, preserving spaces
    for word in string.gmatch(text .. " ", "([^%s]+%s*)") do
        table.insert(words, word)
    end

    for i, word in ipairs(words) do
        local word_length = string.len(word)

        if current_line_length + word_length > maxCharsPerLine and current_line_length > 0 then
            wrapped_text = wrapped_text .. "\n"
            current_line_length = 0
        end

        wrapped_text = wrapped_text .. word
        current_line_length = current_line_length + word_length
    end

    return wrapped_text
end

function M.updatePanel(panelDefinition)
	local label = panelDefinition["panelLabel"]
	local fileName = panelDefinition["saveFile"]
	if label == nil or label == "" or label == "Script UI" then
		label = "__default__"
		fileName = defaultFilename
	end

	local panelID = panelDefinition["id"]
	if panelID == nil or panelID == "" then 		
		panelID = fileName
		if panelID == nil or panelID == "" then 
			panelID = label
		end
	end
	
	layoutDefinitions[panelID] = panelDefinition["layout"]

	panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=fileName, isHidden=panelDefinition["isHidden"]}

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
		if item.widgetType == "text" and item.wrapped == true then
			item.label = wrapTextOnWordBoundary(item.label, item.textWidth)
		end
	end


	M.load(panelID, fileName)
end

function M.createPanel(panelDefinition)
	local label = panelDefinition["panelLabel"]
	local fileName = panelDefinition["saveFile"]
	if label == nil or label == "" or label == "Script UI" then
		label = "__default__"
		fileName = defaultFilename
	end

	local panelID = panelDefinition["id"]
	if panelID == nil or panelID == "" then 		
		panelID = fileName
		if panelID == nil or panelID == "" then 
			panelID = label
		end
	end
	
	layoutDefinitions[panelID] = panelDefinition["layout"]

	panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=fileName, isHidden=panelDefinition["isHidden"]}
	
	print("Creating panel",label, fileName)
	if configValues[panelID] == nil then
		configValues[panelID] = {}
		
		if label == "__default__" then
			--table.insert(defaultPanelList, panelID)
			uevr.sdk.callbacks.on_draw_ui(function()
				drawUI(panelID)
			end)
		elseif panelDefinition["windowed"] == true then
			--table.insert(framePanelList, panelID)
			uevr.sdk.callbacks.on_frame(function()
				if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
					local opened = imgui.begin_window(label, true)
					drawUI(panelID)
					imgui.end_window()
					if not opened then 
						panelList[panelID]["isHidden"] = true
					end
				end
			end)
		elseif uevr.lua ~= nil then
			--table.insert(customPanelList, panelID)
			if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
				uevr.lua.add_script_panel(label, function()
						drawUI(panelID)
				end)
			end
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
		if item.widgetType == "text" and item.wrapped == true then
			item.label = wrapTextOnWordBoundary(item.label, item.textWidth)
		end
	end


	M.load(panelID, fileName)
	
end

function M.update(configDefinition)
	
	if configDefinition ~= nil then
		for _, panel in ipairs(configDefinition) do
			M.updatePanel(panel)
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
	-- if json == nil then
		-- json = require("jsonStorage")
	-- end
	if fileName ~= nil and fileName ~= "" and json ~= nil then
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
	
	for widgetID, value in pairs(configValues[panelID]) do
		local funcList = createFunctions[widgetID]
		if funcList ~= nil and #funcList > 0 then
			for i = 1, #funcList do
				funcList[i](value)
			end
		end
		funcList = createOrUpdateFunctions[widgetID]
		if funcList ~= nil and #funcList > 0 then
			for i = 1, #funcList do
				funcList[i](value)
			end
		end
	end
end

function M.save(panelID)
	local panel = panelList[panelID]
	if panel ~= nil then
		local fileName = panel.fileName
		if fileName ~= nil and fileName ~= "" and json ~= nil then
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
			
			-- if json == nil then
				-- json = require("jsonStorage")
			-- end
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

function M.onCreate(widgetID, funcDef)
	if createFunctions[widgetID] == nil then
		createFunctions[widgetID] = {}
	end
	table.insert(createFunctions[widgetID], funcDef)
end

function M.onCreateOrUpdate(widgetID, funcDef)
	if createOrUpdateFunctions[widgetID] == nil then
		createOrUpdateFunctions[widgetID] = {}
	end
	table.insert(createOrUpdateFunctions[widgetID], funcDef)
end

function M.getPanelID(widgetID)
	local panelID = itemMap[widgetID]
	if panelID == nil then
		panelID = defaultFilename
		panelList[panelID] = {isDirty=false, timeSinceLastSave=0, fileName=defaultFilename}
	end
	return panelID
end

-- function M.setPanelWindowed(panelID, value)
-- change the configDefinition and then destroy existing an call create to create a new one
-- end

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

function M.setValue(widgetID, value, noCallbacks)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item.widgetType == "drag_float2" and type(value) == "table" then
		value = getVector2FromArray(value)
	elseif item.widgetType == "drag_float3" and type(value) == "table" then
		value = getVector3FromArray(value)
	elseif item.widgetType == "drag_float4" and type(value) == "table" then
		value = getVector4FromArray(value)
	elseif item.widgetType == "color_picker" and type(value) == "table" then
		value = colorStringToInteger(value)
	end
	doUpdate(M.getPanelID(widgetID), widgetID, value, nil, noCallbacks)
end

function M.setSelections(widgetID, selections)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.selections = selections
	end
end

function M.hideWidget(widgetID, value)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.isHidden = value
	end
end

function M.disableWidget(widgetID, value)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		item.disabled = value
	end
end

function M.hidePanel(panelID, value)
	panelList[panelID]["isHidden"] = value
end

function M.togglePanel(panelID)
	if panelList[panelID]["isHidden"] == nil then panelList[panelID]["isHidden"] = false end
	panelList[panelID]["isHidden"] = not panelList[panelID]["isHidden"]
end

function M.setLabel(widgetID, newLabel)
	local item = getDefinitionElement(M.getPanelID(widgetID), widgetID)
	if item ~= nil then
		if item.widgetType == "text" and item.wrapped == true then
			newLabel = wrapTextOnWordBoundary(newLabel, item.textWidth)
		end
		item.label = newLabel
	end
end

function M.applyOptionsToConfigWidgets(configWidgets, options)
	if options ~= nil then
		for index, item in ipairs(options) do
			local id = item.id
			if id ~= nil then
				for j, configItem in ipairs(configWidgets) do
					if configItem.id == id then
						for name, value in pairs(item) do
							configItem[name] = value
						end
					end
				end
			end
		end
	end
	return configWidgets
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
		--prevent spamming save
		if element.isDirty == true and element.timeSinceLastSave > 1.0 then
			M.save(panelID)
			element.isDirty = false
			element.timeSinceLastSave = 0
        end
    end
end)

-- uevr.sdk.callbacks.on_draw_ui(function()
	-- for index, panelID in ipairs(defaultPanelList) do
		-- drawUI(panelID)
	-- end
-- end)

-- uevr.sdk.callbacks.on_frame(function()
-- --print(#framePanelList)
	-- for index, panelID in ipairs(framePanelList) do
		-- if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
			-- local opened = imgui.begin_window(label, true)
			-- drawUI(panelID)
			-- imgui.end_window()
			-- if not opened then 
				-- panelList[panelID]["isHidden"] = true
			-- end
		-- end
	-- end
-- end)

-- uevr.lua.add_script_panel(label, function()
-- print(#customPanelList)
	-- for index, panelID in ipairs(customPanelList) do
	-- print("here",panelID)
		-- if (panelList[panelID]["isHidden"] == nil or panelList[panelID]["isHidden"] == false) then
			-- drawUI(panelID)
		-- end
	-- end
-- end)

return M

