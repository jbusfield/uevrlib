local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
--local hands = require("libs/hands")

local M = {}

local bodyMeshName = "Pawn.Mesh"
local armsMeshName = "Pawn.Mesh"
local armsAnimationMeshName = "Pawn.Mesh"
local pawnUpperArmRight = ""
local pawnUpperArmLeft = ""

local hidePawnArmsBones = false

local pawnMeshList = {}
local boneList = {}
local includeChildrenInMeshList = false

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[pawn] " .. text, logLevel)
	end
end

local helpText = "This module allows you to configure the pawn body and arms meshes. You can hide/show the meshes in order to help locate them, select different meshes if your game has multiple meshes, and hide the arm bones if they are visible using the arms mesh. If your game has a separate mesh for first person arms animation (e.g. when using weapons), you can also configure that mesh separately. If your game uses the same mesh for everything, then just select that mesh in each dropdown box"

local configWidgets = spliceableInlineArray{
}

local developerWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_pawn_body",
		initialOpen = true,
		label = "Pawn Body"
	},
		{
			widgetType = "combo",
			id = "pawnBodyMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnBodyMesh",
			label = "Hide",
			initialValue = false
		},
		{
			widgetType = "input_text",
			id = "selectedPawnBodyMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_pawn_arms",
		initialOpen = true,
		label = "Pawn Arms"
	},
		{
			widgetType = "combo",
			id = "pawnArmsMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnArmsMesh",
			label = "Hide",
			initialValue = false
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnArmsBones",
			label = "Hide Arm Bones",
			initialValue = hidePawnArmsBones
		},
		{
			widgetType = "input_text",
			id = "selectedPawnArmsMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
		{
			widgetType = "combo",
			id = "pawnUpperArmLeft",
			label = "Left Upper Arm Bone",
			selections = {"None"},
			initialValue = 1
		},
		{
			widgetType = "combo",
			id = "pawnUpperArmRight",
			label = "Right Upper Arm Bone",
			selections = {"None"},
			initialValue = 1
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "tree_node",
		id = "uevr_pawn_arms_animation",
		initialOpen = true,
		label = "Pawn Arms Animation"
	},
		{
			widgetType = "combo",
			id = "pawnArmsAnimationMeshList",
			label = "Mesh",
			selections = {"None"},
			initialValue = 1,
--			width = 400
		},
		{ widgetType = "same_line" },
		{
			widgetType = "checkbox",
			id = "hidePawnArmsAnimationMesh",
			label = "Hide",
			initialValue = false
		},
		{
			widgetType = "input_text",
			id = "selectedPawnArmsAnimationMesh",
			label = "Name",
			initialValue = "",
			isHidden = true
		},
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

local function setPawnUpperArmLeft(value)
	pawnUpperArmLeft = boneList[value]
end

local function setPawnUpperArmRight(value)
	pawnUpperArmRight = boneList[value]
end

local function setBoneNames()
	local mesh = M.getArmsMesh()
	if mesh ~= nil then
		boneList = uevrUtils.getBoneNames(mesh)
		if #boneList == 0 then error() end
		configui.setSelections("pawnUpperArmLeft", boneList)
		configui.setSelections("pawnUpperArmRight", boneList)
	end
	local currentBoneIndex = configui.getValue("pawnUpperArmLeft")
	if currentBoneIndex ~= nil and currentBoneIndex > 1 then
		setPawnUpperArmLeft(currentBoneIndex)
	end
	currentBoneIndex = configui.getValue("pawnUpperArmRight")
	if currentBoneIndex ~= nil and  currentBoneIndex > 1 then
		setPawnUpperArmRight(currentBoneIndex)
	end
end

local function updateMeshUI(pawnMeshList, listName, selectedName, defaultValue)
	configui.setSelections(listName, pawnMeshList)

	local selectedPawnBodyMesh = configui.getValue(selectedName)
	if selectedPawnBodyMesh == nil or selectedPawnBodyMesh == "" then
		selectedPawnBodyMesh = defaultValue
	end

	for i = 1, #pawnMeshList do
		if pawnMeshList[i] == selectedPawnBodyMesh then
			configui.setValue(listName, i)
			break
		end
	end

end

local function setPawnMeshList()
	M.print("Setting pawn mesh list", LogLevel.Debug)
	pawnMeshList = uevrUtils.getPropertyPathDescriptorsOfClass(pawn, "Pawn", "Class /Script/Engine.SkeletalMeshComponent", includeChildrenInMeshList)
	M.print("Found " .. #pawnMeshList .. " meshes", LogLevel.Debug)
	updateMeshUI(pawnMeshList, "pawnBodyMeshList", "selectedPawnBodyMesh", bodyMeshName)
	updateMeshUI(pawnMeshList, "pawnArmsMeshList", "selectedPawnArmsMesh", armsMeshName)
	updateMeshUI(pawnMeshList, "pawnArmsAnimationMeshList", "selectedPawnArmsAnimationMesh", armsAnimationMeshName)

end

local createDevMonitor = doOnce(function()
	uevrUtils.registerLevelChangeCallback(function(level)
		setPawnMeshList()
		setBoneNames()
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
	    M.showDeveloperConfiguration("pawn_config_dev")
        createDevMonitor()
		setPawnMeshList()
		setBoneNames()
   	else
        M.loadConfiguration("pawn_config_dev")
    end
end

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.getDeveloperConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(developerWidgets, options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel("Pawn Config", saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

function M.showDeveloperConfiguration(saveFileName, options)
	configui.createConfigPanel("Pawn Config Dev", saveFileName, spliceableInlineArray{expandArray(M.getDeveloperConfigurationWidgets, options)})
end

-- function M.showConfiguration(saveFileName, options)
-- 	local configDefinition = {
-- 		{
-- 			panelLabel = "Pawn Config", 
-- 			saveFile = saveFileName, 
-- 			layout = spliceableInlineArray{
-- 				expandArray(M.getConfigurationWidgets, options)
-- 			}
-- 		}
-- 	}
-- 	configui.create(configDefinition)
-- end

function M.setBodyMeshName(val)
	bodyMeshName = "Pawn." .. val
end

function M.getBodyMesh()
	return uevrUtils.getObjectFromDescriptor(bodyMeshName)
end

function M.getArmsMesh()
	return uevrUtils.getObjectFromDescriptor(armsMeshName)
end

function M.getArmsAnimationMesh()
	return uevrUtils.getObjectFromDescriptor(armsAnimationMeshName)
end


configui.onUpdate("pawnBodyMeshList", function(value)
	configui.setValue("selectedPawnBodyMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnBodyMesh", function(value)
	if value ~= "" then
		bodyMeshName = value
	end
end)

configui.onUpdate("pawnArmsMeshList", function(value)
	configui.setValue("selectedPawnArmsMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnArmsMesh", function(value)
	if value ~= "" then
		armsMeshName = value
		setBoneNames()
	end
end)

configui.onUpdate("pawnArmsAnimationMeshList", function(value)
	configui.setValue("selectedPawnArmsAnimationMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate("selectedPawnArmsAnimationMesh", function(value)
	if value ~= "" then
		armsAnimationMeshName = value
	end
end)

configui.onCreateOrUpdate("hidePawnBodyMesh", function(value)
	M.hideBodyMesh(value)
end)

configui.onCreateOrUpdate("hidePawnArmsMesh", function(value)
	M.hideArms(value)
end)

configui.onCreateOrUpdate("hidePawnArmsBones", function(value)
	M.hideArmsBones(value)
end)


configui.onCreateOrUpdate("hidePawnArmsAnimationMesh", function(value)
	M.hideAnimationArms(value)
end)

configui.onCreateOrUpdate("pawnUpperArmRight", function(value)
	setPawnUpperArmRight(value)
end)

configui.onCreateOrUpdate("pawnUpperArmLeft", function(value)
	setPawnUpperArmLeft(value)
end)

function M.hideBodyMesh(val)
	configui.setValue("hidePawnBodyMesh", val, true)
	local mesh = M.getBodyMesh()
	if mesh ~= nil then
		mesh:SetVisibility(not val, true)
		mesh:SetHiddenInGame(val, true)
	end
end

function M.hideAnimationArms(val)
	configui.setValue("hidePawnArmsAnimationMesh", val, true)
	local mesh = M.getArmsAnimationMesh()
	if mesh ~= nil then
		mesh:SetVisibility(not val, true)
		mesh:SetHiddenInGame(val, true)
	end
end

function M.hideArms(val)
	configui.setValue("hidePawnArmsMesh", val, true)
	local mesh = M.getArmsMesh()
	if mesh ~= nil then
		mesh:SetVisibility(not val, true)
		mesh:SetHiddenInGame(val, true)
	end
end

function M.hideArmsBones(val)
	configui.setValue("hidePawnArmsBones", val, true)

	local armsMesh = M.getArmsMesh()
	if armsMesh ~= nil then
		if val then
			if pawnUpperArmRight ~= nil and pawnUpperArmRight ~= "" then
				armsMesh:HideBoneByName(uevrUtils.fname_from_string(pawnUpperArmRight), 0)
			end
			if pawnUpperArmLeft ~= nil and pawnUpperArmLeft ~= "" then
				armsMesh:HideBoneByName(uevrUtils.fname_from_string(pawnUpperArmLeft), 0)
			end
		else
			if pawnUpperArmRight ~= nil and pawnUpperArmRight ~= "" then
				armsMesh:UnHideBoneByName(uevrUtils.fname_from_string(pawnUpperArmRight))
			end
			if pawnUpperArmLeft ~= nil and pawnUpperArmLeft ~= "" then
				armsMesh:UnHideBoneByName(uevrUtils.fname_from_string(pawnUpperArmLeft))
			end
		end
	end
end

--local armBonesHiddenCallbacks = {}
local function executeIsArmBonesHiddenCallback(...)
	return uevrUtils.executeUEVRCallbacksWithPriorityBooleanResult("is_arms_bones_hidden", table.unpack({...}))
	-- local result = false
	-- for i, func in ipairs(armBonesHiddenCallbacks) do
	-- 	result = result or func(...)
	-- end
	-- return result
end

function M.registerIsArmBonesHiddenCallback(func)
	uevrUtils.registerUEVRCallback("is_arms_bones_hidden", func)
	-- for i, existingFunc in ipairs(armBonesHiddenCallbacks) do
	-- 	if existingFunc == func then
	-- 		--print("Function already exists")
	-- 		return
	-- 	end
	-- end
	-- table.insert(armBonesHiddenCallbacks, func)
end

local isHiddenLast = false
uevrUtils.setInterval(100, function()
	local isHidden, priority = executeIsArmBonesHiddenCallback()
	if isHidden ~= isHiddenLast then
		isHiddenLast = isHidden
		M.hideArmsBones(isHidden)
	end
end)

uevrUtils.registerPreLevelChangeCallback(function(level)
	isHiddenLast = false
end)

return M



-- local armsMesh = pawnModule.getArmsMesh()
-- if armsMesh ~= nil then
	-- print("IsAnyMontagePlaying",armsMesh.AnimScriptInstance:IsAnyMontagePlaying())
	-- print("AnimToPlay",armsMesh.AnimationData.AnimToPlay)
	-- print("GetAnimationMode",armsMesh:GetAnimationMode())
	-- print("IsPlaying",armsMesh:IsPlaying())
	-- --print("IsAnyMontagePlaying2",armsMesh["As ABP PLayer Character Hands"]:IsAnyMontagePlaying())
	-- local component = uevrUtils.find_first_instance("AnimBlueprintGeneratedClass /Game/Development/Characters/PlayerCharacterHands/ABP_PLayerCharacterHands.ABP_PLayerCharacterHands_C", true)
	-- print(component:IsAnyMontagePlaying())
-- end
-- local armsMesh = pawn.FPHandsMesh
-- if armsMesh ~= nil then
	-- print("IsAnyMontagePlaying",armsMesh.AnimScriptInstance:IsAnyMontagePlaying())
	-- print("AnimToPlay",armsMesh.AnimationData.AnimToPlay)
	-- print("GetAnimationMode",armsMesh:GetAnimationMode())
	-- print("IsPlaying",armsMesh:IsPlaying())
	-- --print("IsAnyMontagePlaying2",armsMesh["As ABP PLayer Character Hands"]:IsAnyMontagePlaying())
	-- local component = uevrUtils.find_first_instance("AnimBlueprintGeneratedClass /Game/Development/Characters/PlayerCharacterHands/ABP_PLayerCharacterHands.ABP_PLayerCharacterHands_C", true)
	-- print(component:IsAnyMontagePlaying())
-- end
