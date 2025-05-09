
local M = {}

local definition = nil
local filename = nil
local configValues = {}
local updateFunctions = {}
local isDirty = false

local function doUpdate(widgetID, value)
	local funcList = updateFunctions[widgetID]
	if funcList ~= nil and #funcList > 0 then
		for i = 1, #funcList do
			funcList[i](value)
		end
	end
	isDirty = true
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

local function drawUI()
	for _, item in ipairs(definition) do
		if item.widgetType == "checkbox" then
			local changed, newValue = imgui.checkbox(item.label, configValues[item.id])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "button" then
			local changed, newValue = imgui.button(item.label, item.size) 
			if changed then 
				--configValues[item.id] = newValue 
				doUpdate(item.id, true)
			end
		elseif item.widgetType == "small_button" then
			local changed, newValue = imgui.small_button(item.label, item.size) 
			if changed then 
				--configValues[item.id] = newValue 
				doUpdate(item.id, true)
			end
		elseif item.widgetType == "combo" then
		    local changed, newValue = imgui.combo(item.label, configValues[item.id], item.selections)
			if changed then
				configValues[item.id] = newValue
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "slider_int" then
			local changed, newValue = imgui.slider_int(item.label, configValues[item.id], item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "slider_float" then
			local changed, newValue = imgui.slider_float(item.label, configValues[item.id], item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "drag_int" then
			local changed, newValue = imgui.drag_int(item.label, configValues[item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "drag_float" then
			local changed, newValue = imgui.drag_float(item.label, configValues[item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "drag_float2" then
			local changed, newValue = imgui.drag_float2(item.label, configValues[item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "drag_float3" then
			local changed, newValue = imgui.drag_float3(item.label, configValues[item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "drag_float4" then
			local changed, newValue = imgui.drag_float4(item.label, configValues[item.id], item.speed, item.range[1], item.range[2])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "input_text" then
			local changed, newValue, selectionStart, selectionEnd = imgui.input_text(item.label, configValues[item.id])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "input_text_multiline" then
			local changed, newValue, selectionStart, selectionEnd = imgui.input_text_multiline(item.label, configValues[item.id], item.size)
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
			end
		elseif item.widgetType == "color_picker" then
			local changed, newValue = imgui.color_picker(item.label, configValues[item.id])
			if changed then 
				configValues[item.id] = newValue 
				doUpdate(item.id, newValue)
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

local function getDefinitionElement(id)
    for _, element in ipairs(definition) do
        if element.id == id then
            return element
        end
    end
    return nil -- Return nil if the id is not found
end

function M.create(configDefinition, configFilename, panelName)
	if definition ~= nil then
		print("ConfigUI already created")
		return
	end
	
	filename = configFilename
	if configDefinition ~= nil then
		print("Creating config UI")
		definition = configDefinition
		for _, item in ipairs(definition) do
			if item.id ~= nil then
				if item.widgetType == "drag_float2" then
					configValues[item.id] = getVector2FromArray(item.initialValue)
				elseif item.widgetType == "drag_float3" then
					configValues[item.id] = getVector3FromArray(item.initialValue)
				elseif item.widgetType == "drag_float4" then
					configValues[item.id] = getVector4FromArray(item.initialValue)
				elseif item.widgetType == "color_picker" then
					configValues[item.id] = colorStringToInteger(item.initialValue)
				else
					configValues[item.id] = item.initialValue
				end
			end
		end
	else
		print("Cant create create UI because no definition provided")
	end
	
	M.load()
	
	if panelName == nil then
		uevr.sdk.callbacks.on_draw_ui(function()
			drawUI()
		end)
	else
		uevr.lua.add_script_panel(panelName, function()
			drawUI()
		end)
	end
	
	if filename ~= nil and filename ~= "" then
		local timeSinceLastSave = 0
		uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
			timeSinceLastSave = timeSinceLastSave + delta
			--print(isDirty, timeSinceLastSave)
			if isDirty == true and timeSinceLastSave > 1.0 then
				M.save()
				isDirty = false
				timeSinceLastSave = 0
			end
		end)
	end
end

function M.load()
	print("Loading config")
	if filename ~= nil and filename ~= "" then
		local loadConfig = json.load_file(filename)
		for key, val in pairs(loadConfig) do
			item = getDefinitionElement(key)
			if item.widgetType == "drag_float2" then
				configValues[key] = getVector2FromArray(val)
			elseif item.widgetType == "drag_float3" then
				configValues[key] = getVector3FromArray(val)
			elseif item.widgetType == "drag_float4" then
				configValues[key] = getVector4FromArray(val)
			else
				configValues[key] = val
			end
		end
	end
end

function M.save()
	print("Saving config")
	if filename ~= nil and filename ~= "" then
		--things like vector3 need to be converted into a json friendly format
		local saveConfig = {}
		for key, val in pairs(configValues) do
			item = getDefinitionElement(key)
			if item.widgetType == "drag_float2" then
				saveConfig[key] = getArrayFromVector2(val)
			elseif item.widgetType == "drag_float3" then
				saveConfig[key] = getArrayFromVector3(val)
			elseif item.widgetType == "drag_float4" then
				saveConfig[key] = getArrayFromVector4(val)
			else
				saveConfig[key] = val
			end
		end
		
		--print(configValues)
		json.dump_file(filename, saveConfig, 4)
	end
end

function M.onUpdate(widgetID, funcDef)
	if updateFunctions[widgetID] == nil then
		updateFunctions[widgetID] = {}
	end
	table.insert(updateFunctions[widgetID], funcDef)
end

function M.getValue(widgetID)
	return configValues[widgetID]
end

function M.intToAARRGGBB(num)
    local a = (num >> 24) & 0xFF
    local b = (num >> 16) & 0xFF
    local g = (num >> 8) & 0xFF
    local r = num & 0xFF
    return string.format("#%02X%02X%02X%02X", a, r, g, b)
end


return M

