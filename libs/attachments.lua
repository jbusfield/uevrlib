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

local parametersFileName = "attachments_parameters"
local parameters = {}
local isParametersDirty = false

local attachmentNames = {}
local attachmentOffsets = {}
--local activeAttachment = nil
local defaultLocation = nil
local defaultRotation = nil
local defaultScale = nil
local animationLabels = {"None"}
local animationIDs = {""}
--local activeAnimationID = false

local meshAttachmentList = {}
local activeGripAnimations = {}
local attachmentCallbacks = {}

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
		local animation = m_attachmentOffsets[i]["animation"]
		local selectedIndex = 1
		for j = 1, #animationIDs do
			if animation == animationIDs[j] then
				selectedIndex = j
			end
		end

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
						id = "attachment_" .. name .. "_grip_animation", label = "Grip Animation",
						widgetType = "combo", selections = animationLabels, initialValue = selectedIndex
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
		configui.onUpdate("attachment_" .. name .. "_grip_animation", function(value)
			M.updateAttachmentAnimation(value, parent, child)
		end)

	end

	table.insert(configDefinition[1]["layout"],
		{
			widgetType = "tree_pop"
		}
	)
	return configDefinition
end

function M.loadParameters(fileName)
	if fileName ~= nil then parametersFileName = fileName end
	M.print("Loading attachments parameters " .. parametersFileName)
	parameters = json.load_file(parametersFileName .. ".json")

	if parameters == nil then
		parameters = {}
		M.print("Creating attachments parameters")
	end
	if parameters["attachmentOffsets"] == nil then
		parameters["attachmentOffsets"] = {}
		isParametersDirty = true
	end
	attachmentOffsets = parameters["attachmentOffsets"]
end

local function saveParameters()
	M.print("Saving attachments parameters " .. parametersFileName)
	json.dump_file(parametersFileName .. ".json", parameters, 4)
end

local createDevMonitor = doOnce(function()
    uevrUtils.setInterval(1000, function()
        if isParametersDirty == true then
            saveParameters()
            isParametersDirty = false
        end
    end)
end, Once.EVER)

local function getDefaultConfig()
	return  {
		{
			panelLabel = "Attachments Config Dev",
			saveFile = "attachments_config_dev",
			layout =
			{
			}
		}
	}
end

function M.showDeveloperConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
	defaultLocation = m_defaultLocation
	defaultRotation = m_defaultRotation
	defaultScale = m_defaultScale

	local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
	configui.create(configDefinition)
end

local function registerAttachmentCallback(callbackName, callbackFunc)
	if attachmentCallbacks[callbackName] == nil then attachmentCallbacks[callbackName] = {} end
	for i, existingFunc in ipairs(attachmentCallbacks[callbackName]) do
		if existingFunc == callbackFunc then
			--print("Function already exists")
			return
		end
	end
	table.insert(attachmentCallbacks[callbackName], callbackFunc)
end
local function executeAttachmentCallbacks(callbackName, ...)
	if attachmentCallbacks[callbackName] ~= nil then
		for i, func in ipairs(attachmentCallbacks[callbackName]) do
			func(table.unpack({...}))
		end
	end
end

function M.init(isDeveloperMode, logLevel, m_defaultLocation, m_defaultRotation, m_defaultScale)
    if logLevel ~= nil then
        M.setLogLevel(logLevel)
    end
    if isDeveloperMode == nil and uevrUtils.getDeveloperMode() ~= nil then
        isDeveloperMode = uevrUtils.getDeveloperMode()
    end

    if isDeveloperMode then
	    M.showDeveloperConfiguration(m_defaultLocation, m_defaultRotation, m_defaultScale)
        createDevMonitor()
    end
end

local function strip_after_last_underscore(str)
    local last = str:match("^(.*)_.*$")
    return last or str
end
local function stripTrailingNumbers(str)
    return str:match("^(.-)%d*$")
end

local function getAttachmentNames(attachment)
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
	elseif attachment.SkeletalMesh ~= nil then
		attachmentChildName = uevrUtils.getShortName(attachment.SkeletalMesh)
	else
		attachmentChildName = uevrUtils.getShortName(attachment)
	end
	--print("getAttachmentNames",attachmentParentName, attachmentChildName)
	return attachmentParentName, attachmentChildName, attachmentParentName .. "_" .. attachmentChildName
end

-- function M.getActiveAttachment()
-- 	return activeAttachment
-- end

function M.addAttachmentToConfig(attachment)
	if parameters ~= nil then
		local attachmentParentName, attachmentChildName = getAttachmentNames(attachment)

		local exists = false
		--if configuration["attachmentOffsets"] == nil then configuration["attachmentOffsets"] = {} end
		if parameters["attachmentOffsets"] ~= nil then
			for i = 1, #parameters["attachmentOffsets"] do
				if attachmentParentName == attachmentOffsets[i]["parent"] and attachmentChildName == attachmentOffsets[i]["child"] then
					exists = true
				end
			end
			if not exists then
				M.print("Adding attachment to config " .. attachmentParentName .. " - " .. attachmentChildName)
				local attachmentLocation =  defaultLocation or {attachment.RelativeLocation.X, attachment.RelativeLocation.Y, attachment.RelativeLocation.Z}
				local attachmentRotation = defaultRotation or {attachment.RelativeRotation.Pitch, attachment.RelativeRotation.Yaw, attachment.RelativeRotation.Roll}
				local attachmentScale = defaultScale or {attachment.RelativeScale3D.X, attachment.RelativeScale3D.Y, attachment.RelativeScale3D.Z}

				table.insert(parameters["attachmentOffsets"], {parent=attachmentParentName, child=attachmentChildName, location=attachmentLocation, rotation=attachmentRotation, scale=attachmentScale})
				isParametersDirty = true

				attachmentOffsets = parameters["attachmentOffsets"]
				local configDefinition = M.addAttachmentOffsetsToConfigUI(getDefaultConfig())
				configui.update(configDefinition)
			end
		end
	end
end

function M.setAttachmentNames(attachmentNamesList)
	attachmentNames = attachmentNamesList
	attachmentOffsets = {}
	for i, attachmentName in ipairs(attachmentNames) do
		table.insert(attachmentOffsets, {parent=attachmentName, child="", location=defaultLocation or {0,0,0}, rotation=defaultRotation or {0,0,0}, scale=defaultScale or {1,1,1}})
	end
end

local function hasNamedObject(attachment, parentName, childName)
	M.print("Called hasNamedObject with parent: " .. parentName .. " child: " .. childName)
	local result = false
	if parentName == nil or parentName == "" then
		result = true
	else
		result = not not string.find(attachment:get_full_name(), parentName)
	end

	if result then
		if not(childName == nil or childName == "") then
			if attachment.StaticMesh ~= nil then
				--print("Static Mesh",attachment.StaticMesh:get_full_name())
				result = not not string.find(attachment.StaticMesh:get_full_name(), childName)
			elseif attachment.SkeletalMesh ~= nil then
				--print("Skeletal Mesh",attachment.SkeletalMesh:get_full_name())
				result = not not string.find(attachment.SkeletalMesh:get_full_name(), childName)
			else
				result = not not string.find(attachment:get_full_name(), childName)
			end
		else
			result = false
		end
	end
	M.print("hasNamedObject result is " .. (result and "true" or "false"))
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
	parameters["attachmentOffsets"] = attachmentOffsets
	isParametersDirty = true
end

function M.updateAttachmentAnimation(animationIndex, parentName, childName)
	for i = 1, #attachmentOffsets do
		local parent = attachmentOffsets[i]["parent"]
		local child = attachmentOffsets[i]["child"]
		if parentName == parent and childName == child then
			attachmentOffsets[i]["animation"] = animationIDs[animationIndex]
		end
	end
	parameters["attachmentOffsets"] = attachmentOffsets
	isParametersDirty = true
end

local function getNamedAttachmentFromMeshAttachmentList(parentName, childName)
	for meshName, meshData in pairs(meshAttachmentList) do
		for attachmentName, attachmentData in pairs(meshData) do
			if uevrUtils.getValid(attachmentData.attachment) ~= nil then
				if hasNamedObject(attachmentData.attachment, parentName, childName) then
					return attachmentData.attachment, attachmentData.attachType
				end
			end
		end
	end
	return nil, nil
end

function M.updateAttachmentTransform(pos, rot, scale, parentName, childName)
	if parentName ~= nil then
		M.setAttachmentOffset(parentName, childName, pos, rot)
	end

	local attachment, attachType = getNamedAttachmentFromMeshAttachmentList(parentName, childName)
	if attachType == M.AttachType.RAW_CONTROLLER then
		-- if attachmentState ~= nil then
		-- 	if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
		-- 	if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
		-- end
	end
	if attachment ~= nil and (attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER) then
		if pos ~= nil then uevrUtils.set_component_relative_location(attachment, pos) end
		if rot ~= nil then uevrUtils.set_component_relative_rotation(attachment, rot) end
		if scale ~= nil then uevrUtils.set_component_relative_scale(attachment, scale) end
	end

	-- for id, mesh in pairs(meshAttachmentList) do
	-- 	for attachmentName, attachmentData in pairs(mesh) do
	-- 		if uevrUtils.getValid(attachmentData.attachment) ~= nil then
	-- 			if hasNamedObject(attachmentData.attachment, parentName, childName) then
	-- 				local attachType = attachmentData.attachType
	-- 				if attachType == M.AttachType.RAW_CONTROLLER then
	-- 					-- if attachmentState ~= nil then
	-- 					-- 	if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
	-- 					-- 	if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
	-- 					-- end
	-- 				end
	-- 				if attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER then
	-- 					if pos ~= nil then uevrUtils.set_component_relative_location(activeAttachment, pos) end
	-- 					if rot ~= nil then uevrUtils.set_component_relative_rotation(activeAttachment, rot) end
	-- 					if scale ~= nil then uevrUtils.set_component_relative_scale(activeAttachment, scale) end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- if uevrUtils.validate_object(activeAttachment) ~= nil then
	-- 	if parentName == nil or hasNamedObject(activeAttachment, parentName, childName) then
	-- 		if attachType == M.AttachType.RAW_CONTROLLER then
	-- 			-- if attachmentState ~= nil then
	-- 			-- 	if pos ~= nil then attachmentState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z)) end
	-- 			-- 	if rot ~= nil then attachmentState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z))) end
	-- 			-- end
	-- 		end
	-- 		if attachType == M.AttachType.MESH or attachType == M.AttachType.CONTROLLER then
	-- 			if pos ~= nil then uevrUtils.set_component_relative_location(activeAttachment, pos) end
	-- 			if rot ~= nil then uevrUtils.set_component_relative_rotation(activeAttachment, rot) end
	-- 			if scale ~= nil then uevrUtils.set_component_relative_scale(activeAttachment, scale) end
	-- 		end
	-- 	end
	-- end
end

function M.updateOffset(attachment)
	if attachment ~= nil then
		local location, rotation, scale = M.getAttachmentOffset(attachment)
		local parentName, childName, id = getAttachmentNames(attachment)
		M.updateAttachmentTransform(location, rotation, scale, parentName, childName)
	end
end

function M.setActiveAnimation(attachment, gripHand)
	if gripHand ~= nil then
		if uevrUtils.getValid(attachment) ~= nil then
			activeGripAnimations[gripHand] = true
			for i = 1, #attachmentOffsets do
				local parent = attachmentOffsets[i]["parent"]
				local child = attachmentOffsets[i]["child"]
				--local name = parent .. "_" .. child
				if hasNamedObject(attachment, parent, child) then
					activeGripAnimations[gripHand] = attachmentOffsets[i]["animation"]
				end
			end
		else
			activeGripAnimations[gripHand] = false
		end
		M.print("Calling callback for grip animation " .. activeGripAnimations[gripHand] .. " " .. gripHand)
		executeAttachmentCallbacks("grip_animation", activeGripAnimations[gripHand], gripHand)
	end
end

function M.getCurrentGripAnimation(handed)
	return activeGripAnimations[handed]
end

function M.attachToMesh(attachment, mesh, socketName, gripHand, detachFromParent)
	local success = false
	if uevrUtils.getValid(attachment) ~= nil and uevrUtils.getValid(mesh) ~= nil  then
		local meshName = mesh:get_full_name()
		if meshAttachmentList[meshName] ==  nil then
			meshAttachmentList[meshName] = {mesh=mesh}
		end
		local attachmentName = attachment:get_full_name()
		if meshAttachmentList[meshName][attachmentName] == nil then
			meshAttachmentList[meshName][attachmentName] = {attachment=attachment, socket=socketName, detachFromParent = detachFromParent, attachType = M.AttachType.MESH, gripHand = gripHand}
		end

		--see if the attachment is already a child of the mesh
		if mesh.AttachChildren ~= nil then
			for i, child in ipairs(mesh.AttachChildren) do
				if child == attachment then
					--M.print("Attachment is already a child of the mesh")
					return true
				end
			end
		end

		if detachFromParent == true then
			meshAttachmentList[meshName][attachmentName].parent = attachment.AttachParent
			attachment:DetachFromParent(false,false)
		end

		M.print("Attaching attachment to mesh: " .. attachment:get_full_name() .. " to " .. mesh:get_full_name())
		if type(socketName) == "string" then
			socketName = uevrUtils.fname_from_string(socketName)
		end
		if socketName == nil then socketName = attachment.AttachSocketName end
		success = attachment:K2_AttachTo(mesh, socketName, 0, false)
		attachment:SetHiddenInGame(false,true)
		attachment:SetVisibility(true,true)

		--attachType = M.AttachType.MESH
		M.updateOffset(attachment)
		M.setActiveAnimation(attachment, gripHand)
		M.print("Attached attachment to mesh" .. (success and " successfully" or " with errors"))
	else
		M.print("Failed to attach attachment to mesh")
	end
	return success
end

function M.attachToController(attachment, controllerID, detachFromParent)
	if uevrUtils.getValid(attachment) ~= nil then
		if detachFromParent == true then
			attachment:DetachFromParent(false,false)
		end
		M.print("Attaching " .. attachment:get_full_name() .. " to controller with ID " .. controllerID)
		controllers.attachComponentToController(controllerID, attachment, nil, nil, nil, true)
		attachment:SetHiddenInGame(false,true)
		attachment:SetVisibility(true,true)
		--attachType = M.AttachType.CONTROLLER
		M.updateOffset(attachment)
		M.setActiveAnimation(attachment, controllerID)
		M.print("Attached attachment to controller")
	else
		M.print("Failed to attach attachment to controller")
	end
end

function M.detach(attachment, parent)
	if uevrUtils.getValid(attachment) ~= nil then
		M.print("Detaching attachment: " .. attachment:get_full_name())
		if parent ~= nil then
			attachment:K2_AttachTo(parent, attachment.AttachSocketName, 0, false)
		end
	else
		M.print("Failed to detach attachment")
	end
end

function M.detachAttachmentFromMeshes(attachment, reattachToParent)
	if uevrUtils.getValid(attachment) ~= nil then
		local attachmentName = attachment:get_full_name()
		M.print("Detaching attachment from all meshes: " .. attachment:get_full_name())
		for meshName, meshData in pairs(meshAttachmentList) do
			if meshData[attachmentName] ~= nil then
				if meshData[attachmentName].gripHand ~= nil then
					activeGripAnimations[meshData[attachmentName].gripHand] = false
				end
				M.detach(meshData[attachmentName].attachment, reattachToParent and meshData[attachmentName].parent or nil)
				meshData[attachmentName] = nil
			end
		end
	else
		M.print("Failed to detach attachment from meshes")
	end
end

function M.detachAttachmentsFromMesh(mesh, reattachToParent)
	if uevrUtils.getValid(mesh) ~= nil then
		M.print("Detaching all attachments from mesh: " .. mesh:get_full_name())
		local meshName = mesh:get_full_name()
		local meshData = meshAttachmentList[meshName]
		if meshData ~= nil then
			for attachmentName, attachmentData in pairs(meshData) do
				if attachmentData.gripHand ~= nil then
					activeGripAnimations[attachmentData.gripHand] = false
				end
				M.detach(attachmentData.attachment, reattachToParent and attachmentData.parent or nil)
			end
			meshAttachmentList[meshName] = nil
		end
	else
		M.print("Failed to detach attachments from mesh")
	end
end

local function getAnimationLabelsArray(animationIDList)
	local labels = {"None"}
	for id, data in pairs(animationIDList) do
		table.insert(labels, data["label"])
	end
	return labels
end

local function getAnimationIDsArray(animationIDList)
	local ids = {""}
	for id, data in pairs(animationIDList) do
		table.insert(ids, id)
	end
	return ids
end

function M.setAnimationIDs(animationIDList)
	if animationIDList ~= nil then
		animationLabels = getAnimationLabelsArray(animationIDList)
		animationIDs = getAnimationIDsArray(animationIDList)
		for i = 1, #attachmentOffsets do
			local parent = attachmentOffsets[i]["parent"]
			local child = attachmentOffsets[i]["child"]
			local name = parent .. "_" .. child
			configui.setSelections("attachment_" .. name .. "_grip_animation", animationLabels)
			local selectedID = attachmentOffsets[i]["animation"]
			for j = 1, #animationIDs do
				if selectedID == animationIDs[j] then
					configui.setValue("attachment_" .. name .. "_grip_animation", j)
				end
			end
		end
	end
end

local autoUpdateCallbackCreated = false
--local autoUpdateCurrentAttachment = nil
--local autoUpdateCurrentMesh = nil
function M.autoUpdateGripAttachments(callback)
	if not autoUpdateCallbackCreated then
		uevrUtils.setInterval(1000, function()
			local rightAttachment, rightMesh, leftAttachment, leftMesh, socketName, handleParentAttachment = callback()
			--print(attachment, mesh, autoUpdateCurrentAttachment)
			if handleParentAttachment == nil then handleParentAttachment = false end
			if rightMesh == nil and rightAttachment == nil then
				--do nothing
			elseif rightMesh == nil and rightAttachment ~= nil then
				M.detachAttachmentFromMeshes(rightAttachment, handleParentAttachment)
			elseif rightMesh ~= nil and rightAttachment == nil then
				M.detachAttachmentsFromMesh(rightMesh, handleParentAttachment)
			elseif rightMesh ~= nil and rightAttachment ~= nil then
				M.attachToMesh(rightAttachment, rightMesh, socketName, Handed.Right, handleParentAttachment)
			end

			if leftMesh == nil and leftAttachment == nil then
				--do nothing
			elseif leftMesh == nil and leftAttachment ~= nil then
				M.detachAttachmentFromMeshes(leftAttachment, handleParentAttachment)
			elseif leftMesh ~= nil and leftAttachment == nil then
				M.detachAttachmentsFromMesh(leftMesh, handleParentAttachment)
			elseif leftMesh ~= nil and leftAttachment ~= nil then
				M.attachToMesh(leftAttachment, leftMesh, socketName, Handed.Left, handleParentAttachment)
			end

			-- if mesh ~= nil then
			-- 	print("Children",mesh:get_full_name(),mesh.AttachChildren and #mesh.AttachChildren or 0)
			-- end
			-- if (mesh == nil and autoUpdateCurrentMesh~= nil) or (attachment == nil and autoUpdateCurrentAttachment ~= nil) then
			-- 	M.detach(autoUpdateCurrentAttachment, true)
			-- 	autoUpdateCurrentMesh = mesh
			-- 	autoUpdateCurrentAttachment = attachment
			-- elseif attachment ~= nil and mesh ~= nil and autoUpdateCurrentAttachment ~= attachment then
			-- 	M.attachToMesh(attachment, mesh, socketName, true)
			-- 	autoUpdateCurrentMesh = mesh
			-- 	autoUpdateCurrentAttachment = attachment
			-- end
		end)
	end
end

function M.registerGripAnimationCallback(callbackFunc)
	registerAttachmentCallback("grip_animation", callbackFunc)
end

uevrUtils.registerPreLevelChangeCallback(function(level)
	meshAttachmentList = {}
	activeGripAnimations = {}
end)

M.loadParameters()

return M