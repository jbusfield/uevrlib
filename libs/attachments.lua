local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")

local M = {}

M.AttachType =
{
    MESH = 0,
    CONTROLLER = 1,
    RAW_CONTROLLER = 2,
}

local configurationFileName = "attachments_parameters"
local configuration = {}
local isConfigurationDirty = false


local attachmentNames = {}
local attachmentOffsets = {}
local activeAttachment = nil
local attachType = M.AttachType.MESH
local defaultLocation = nil
local defaultRotation = nil
local defaultScale = nil

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

function M.addAttachmentOffsetsToConfigUI(configDefinition, m_attachmentOffsets)	
	if m_attachmentOffsets == nil then m_attachmentOffsets = attachmentOffsets end
	table.insert(configDefinition[1]["layout"], 
		{
			widgetType = "tree_node",
			id = "attachment_offsets",
			initialOpen = true,
			label = "Attachment Configuration"
		}
	)

	for i = 1, #m_attachmentOffsets do
		local parent = m_attachmentOffsets[i]["parent"]
		local child = m_attachmentOffsets[i]["child"]
		local name = parent .. "_" .. child
		local pos = m_attachmentOffsets[i]["location"]
		local rot = m_attachmentOffsets[i]["rotation"]
		local scale = m_attachmentOffsets[i]["scale"]
		table.insert(configDefinition[1]["layout"], 
				{
					id = "attachment_" .. name, label = name, widgetType = "tree_node",
				}
		)
		table.insert(configDefinition[1]["layout"], 
					{					
						id = "attachment_" .. name .. "_position", label = "Position",
						widgetType = "drag_float3", speed = .1, range = {-500, 500}, initialValue = pos
					}
		)
		table.insert(configDefinition[1]["layout"], 
					{					
						id = "attachment_" .. name .. "_rotation", label = "Rotation",
						widgetType = "drag_float3", speed = .1, range = {-360, 360}, initialValue = rot
					}
		)
		table.insert(configDefinition[1]["layout"], 
					{					
						id = "attachment_" .. name .. "_scale", label = "Scale",
						widgetType = "drag_float3", speed = .01, range = {0.01, 10}, initialValue = scale
					}
		)
		table.insert(configDefinition[1]["layout"], 
				{
					widgetType = "tree_pop"
				}
		)
		
		configui.onUpdate("attachment_" .. name .. "_position", function(value)
			M.updateAttachmentTransform(value, nil, nil, parent, child) 
		end)
		configui.onUpdate("attachment_" .. name .. "_rotation", function(value)
			M.updateAttachmentTransform(nil, value, nil, parent, child)
		end)
		configui.onUpdate("attachment_" .. name .. "_scale", function(value)
			M.updateAttachmentTransform(nil, nil, value, parent, child)
		end)
			
	end
	
	table.insert(configDefinition[1]["layout"], 
		{
			widgetType = "tree_pop"
		}
	)
	return configDefinition
end

function M.loadConfiguration(fileName)
	if fileName ~= nil then configurationFileName = fileName end
	M.print("Loading attachments configuration " .. configurationFileName)
	configuration = json.load_file(configurationFileName .. ".json")

	if configuration == nil then
		configuration = {}
		M.print("Creating attachments configuration")
	end
	if configuration["attachmentOffsets"] ~= nil then
		attachmentOffsets = configuration["attachmentOffsets"]
	end
end

local function saveConfiguration()
	M.print("Saving attachments configuration " .. configurationFileName)
	json.dump_file(configurationFileName .. ".json", configuration, 4)
end

local timeSinceLastSave = 0
local function createSaveCallback()
	uevrUtils.registerPreEngineTickCallback(function(engine, delta)
		timeSinceLastSave = timeSinceLastSave + delta
		if isConfigurationDirty == true and timeSinceLastSave > 1.0 then
			saveConfiguration()
			isConfigurationDirty = false
			timeSinceLastSave = 0
		end
	end)
end

local function getDefaultConfig()
	return  {
		{
			panelLabel = "Attachments Config", 
			saveFile = "attachments_config", 
			layout = 
			{
			}
		}
	}
end

local enableConfiguration = doOnce(function(m_defaultLocation, m_defaultRotation, m_defaultScale)
	defaultLocation = m_defaultLocation
	defaultRotation = m_defaultRotation
	defaultScale = m_defaultScale

	createSaveCallback()
	M.loadConfiguration()
	if configuration["attachmentOffsets"] == nil then
		configuration["attachmentOffsets"] = {}
		isConfigurationDirty = true
	end
	
	attachmentOffsets = configuration["attachmentOffsets"]
	local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
	configui.create(configDefinition)		
end, Once.EVER)

function M.enableConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
	enableConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
end

function strip_after_last_underscore(str)
    local last = str:match("^(.*)_.*$")
    return last or str
end
function stripTrailingNumbers(str)
    return str:match("^(.-)%d*$")
end

function getAttachmentNames(attachment)
	local attachmentParentName = uevrUtils.getShortName(attachment:get_outer())
	local attachmentNameNoNumberSuffix = stripTrailingNumbers(attachmentParentName)
	if string.sub(attachmentNameNoNumberSuffix, -1, -1) ~= "_" then
		attachmentParentName = attachmentNameNoNumberSuffix
	else
		attachmentParentName = strip_after_last_underscore(attachmentParentName) -- strip off anything after the last underscore
	end
	
	local attachmentChildName = ""
	if attachment.StaticMesh ~= nil then
		attachmentChildName = uevrUtils.getShortName(attachment.StaticMesh)
	else
		attachmentChildName = uevrUtils.getShortName(attachment.SkeletalMesh)
	end
		
	return attachmentParentName, attachmentChildName
end

function M.addAttachmentToConfig(attachment)
	if configuration ~= nil then
		local attachmentParentName, attachmentChildName = getAttachmentNames(attachment)

		local exists = false
		for i = 1, #configuration["attachmentOffsets"] do
			if attachmentParentName == attachmentOffsets[i]["parent"] and attachmentChildName == attachmentOffsets[i]["child"] then
				exists = true
			end
		end
		
		if not exists then
			M.print("Adding attachment to config " .. attachmentParentName .. " - " .. attachmentChildName)
			attachmentLocation =  defaultLocation or {attachment.RelativeLocation.X, attachment.RelativeLocation.Y, attachment.RelativeLocation.Z}
			attachmentRotation = defaultRotation or {attachment.RelativeRotation.Pitch, attachment.RelativeRotation.Yaw, attachment.RelativeRotation.Roll}
			attachmentScale = defaultScale or {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}

			table.insert(configuration["attachmentOffsets"], {parent=attachmentParentName, child=attachmentChildName, location=attachmentLocation, rotation=attachmentRotation, scale=attachmentScale})	
			isConfigurationDirty = true
			
			attachmentOffsets = configuration["attachmentOffsets"]
			local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
			configui.update(configDefinition)
		end
	end
end

function M.setAttachmentNames(attachmentNamesList)
	attachmentNames = attachmentNamesList
	attachmentOffsets = {}
	for i, attachmentName in ipairs(attachmentNames) do
		table.insert(attachmentOffsets, {parent=attachmentName, child="", location=defaultLocation or {0,0,0}, rotation=defaultRotation or {0,0,0}, rotation=defaultScale or {1,1,1}})	
	end
end

local function hasNamedObject(attachment, parentName, childName)
	local result = false
	if parentName == nil or parentName == "" then
		result = true
	else
		result = not not string.find(attachment:get_full_name(), parentName)
	end
	
	if result then
		if not(childName == nil or childName == "") then
			if attachment.StaticMesh ~= nil then
				result = string.find(attachment.StaticMesh:get_full_name(), childName)
			elseif attachment.SkeletalMesh ~= nil then
				result = string.find(attachment.SkeletalMesh:get_full_name(), childName)
			else
				result = false
			end
		end
	end
	
	return result
end

function M.getAttachmentOffset(attachment) 
	local attachmentLocation = {0,0,0}
	local attachmentRotation = {0,0,0}
	local attachmentScale = {1,1,1}
	if uevrUtils.getValid(attachment) ~= nil then
		for i = 1, #attachmentOffsets do
			local parent = attachmentOffsets[i]["parent"]
			local child = attachmentOffsets[i]["child"]
			local name = parent .. "_" .. child
			if hasNamedObject(attachment, parent, child) then
				local position = configui.getValue("attachment_" .. name .. "_position")
				if position == nil then position = attachmentOffsets[i]["location"] end
				
				local rotation = configui.getValue("attachment_" .. name .. "_rotation")
				if rotation == nil then rotation = attachmentOffsets[i]["rotation"] end
				
				local scale = configui.getValue("attachment_" .. name .. "_scale")
				if scale == nil then scale = attachmentOffsets[i]["scale"] end
				if scale == nil then --set a fixed scale in case something else tries to change it
					attachmentOffsets[i]["scale"] = {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}
					scale = attachmentOffsets[i]["scale"]
				end
				
				return uevrUtils.vector(position), uevrUtils.rotator(rotation), uevrUtils.vector(scale)				
			end
		end
		attachmentLocation = {attachment.RelativeLocation.X, attachment.RelativeLocation.Y, attachment.RelativeLocation.Z}
		attachmentRotation = {attachment.RelativeRotation.Pitch, attachment.RelativeRotation.Yaw, attachment.RelativeRotation.Roll}
		attachmentScale = {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}
	end
	
	if defaultLocation ~= nil then attachmentLocation = defaultLocation end
	if defaultRotation ~= nil then attachmentRotation = defaultRotation end
	if defaultScale ~= nil then attachmentScale = defaultScale end

	--we didnt find an existing attachment. Add it to config if config is enabled
	M.addAttachmentToConfig(attachment)
	
	return uevrUtils.vector(attachmentLocation), uevrUtils.rotator(attachmentRotation), uevrUtils.rotator(attachmentScale)
end

function M.setAttachmentOffset(parentName, childName, location, rotation) 
	for i = 1, #attachmentOffsets do
		local parent = attachmentOffsets[i]["parent"]
		local child = attachmentOffsets[i]["child"]
		if parentName == parent and childName == child then
			if location ~= nil then attachmentOffsets[i]["location"] = {location.X, location.Y, location.Z} end
			if rotation ~= nil then attachmentOffsets[i]["rotation"] = {rotation.X, rotation.Y, rotation.Z} end			
		end
	end
	configuration["attachmentOffsets"] = attachmentOffsets
	isConfigurationDirty = true
end

function M.updateAttachmentTransform(pos, rot, scale, parentName, childName)
	if parentName ~= nil then
		M.setAttachmentOffset(parentName, childName, pos, rot)
	end
	
	if uevrUtils.validate_object(activeAttachment) ~= nil then		
		if parentName == nil or hasNamedObject(activeAttachment, parentName, childName) then		
			if attachType == M.AttachType.RAW_CONTROLLER then
				if attachmentState ~= nil then
					if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
					if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
				end
			end
			if attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER then
				if pos ~= nil then uevrUtils.set_component_relative_location(activeAttachment, pos) end
				if rot ~= nil then uevrUtils.set_component_relative_rotation(activeAttachment, rot) end
				if scale ~= nil then uevrUtils.set_component_relative_scale(activeAttachment, scale) end
			end
		end
	end
end

function M.updateOffset()
	local location, rotation, scale = M.getAttachmentOffset(activeAttachment)
	M.updateAttachmentTransform(location, rotation, scale)
end

function M.setActiveAttachment(attachment)
	activeAttachment = attachment
	M.updateOffset()
end

function M.attachToMesh(attachment, mesh, socketName) 
	local success = false
	if uevrUtils.getValid(attachment) ~= nil and uevrUtils.getValid(mesh) ~= nil  then
		uevrUtils.print("Attaching attachment to mesh: " .. attachment:get_full_name() .. " to " .. mesh:get_full_name())
		if type(socketName) == "string" then
			socketName = uevrUtils.fname_from_string(socketName)
		end
		if socketName == nil then socketName = attachment.AttachSocketName end
		success = attachment:K2_AttachTo(mesh, socketName, 0, false)
		attachType = M.AttachType.MESH
		M.setActiveAttachment(attachment)
	else
		M.print("Failed to attach attachment to mesh")
	end
	return success
end

function M.attachToController(attachment, controllerID)
	if uevrUtils.getValid(attachment) ~= nil then
		uevrUtils.print("Attaching " .. attachment:get_full_name() .. " to controller with ID " .. controllerID)
		controllers.attachComponentToController(controllerID, attachment, nil, nil, nil, true)
		attachType = M.AttachType.CONTROLLER
		M.setActiveAttachment(attachment)
	else
		M.print("Failed to attach attachment to controller")
	end
end

return M