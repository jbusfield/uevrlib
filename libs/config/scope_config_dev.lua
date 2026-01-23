local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local configFileName = "dev/scope_config_dev"
local configTabLabel = "Scope Dev Config"
local widgetPrefix = "uevr_scope_"

local configDefaults = {}
local paramManager = nil

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
		uevrUtils.print("[scope config dev] " .. text, logLevel)
	end
end

local helpText = ""

local function getConfigWidgets(m_paramManager)
    return {		
        {
            widgetType = "checkbox",
            id = "uevr_lib_scope_create_demo",
            label = "Create left hand demo",
            initialValue = false
        },
        {
            widgetType = "checkbox",
            id = "uevr_lib_scope_show_debug",
            label = "Show debug meshes",
            initialValue = false
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_fov",
            label = "FOV",
            range = {0.01, 30},
            initialValue = 2
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_brightness",
            label = "Brightness",
            range = {0, 10},
            initialValue = 2
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_ocular_lens_scale",
            label = "Scale",
            range = {0.1, 10},
            initialValue = 1
        },
        {
            widgetType = "drag_float3",
            id = "uevr_lib_scope_objective_lens_rotation",
            label = "Objective Lens Rotation",
            speed = 0.5,
            range = {-90, 90},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = "uevr_lib_scope_objective_lens_location",
            label = "Objective Lens Location",
            speed = 0.5,
            range = {-100, 100},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = "uevr_lib_scope_ocular_lens_rotation",
            label = "Ocular Lens Rotation",
            speed = 0.5,
            range = {-90, 90},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = "uevr_lib_scope_ocular_lens_location",
            label = "Ocular Lens Location",
            speed = 0.05,
            range = {-100, 100},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "checkbox",
            id = "uevr_lib_scope_disable",
            label = "Disable",
            initialValue = false
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_deactivate_distance",
            label = "Deactivate distance",
            range = {0, 100},
            initialValue = 15
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_zoom_speed",
            label = "Zoom Speed",
            range = {0, 2},
            initialValue = zoomSpeed
        },
        {
            widgetType = "slider_float",
            id = "uevr_lib_scope_zoom_exponential",
            label = "Zoom Exponential",
            range = {0, 1},
            initialValue = zoomExponential
        },
    }	

end

local function updateSetting(key, value)
    uevrUtils.executeUEVRCallbacks("on_pawn_config_param_change", key, value)
end

local function setPawnUpperArmLeft(value)
	--pawnUpperArmLeft = boneList[value]
    updateSetting("pawnUpperArmLeft", boneList[value])
end

local function setPawnUpperArmRight(value)
	--pawnUpperArmRight = boneList[value]
    updateSetting("pawnUpperArmRight", boneList[value])
end

local function getArmsMesh()
	return uevrUtils.getObjectFromDescriptor(configui.getValue(widgetPrefix .. "selectedPawnArmsMesh"))
end

local function setBoneNames()
	local mesh = getArmsMesh()
	if mesh ~= nil then
		boneList = uevrUtils.getBoneNames(mesh)
		if #boneList == 0 then return end
		configui.setSelections(widgetPrefix .. "pawnUpperArmLeft", boneList)
		configui.setSelections(widgetPrefix .. "pawnUpperArmRight", boneList)
	end
	local currentBoneIndex = configui.getValue(widgetPrefix .. "pawnUpperArmLeft")
	if currentBoneIndex ~= nil and currentBoneIndex > 1 then
		setPawnUpperArmLeft(currentBoneIndex)
	end
	currentBoneIndex = configui.getValue(widgetPrefix .. "pawnUpperArmRight")
	if currentBoneIndex ~= nil and  currentBoneIndex > 1 then
		setPawnUpperArmRight(currentBoneIndex)
	end
end

local function updateMeshUI(pawnMeshList, listName, selectedName, defaultValue)
	configui.setSelections(widgetPrefix .. listName, pawnMeshList)

	local selectedPawnBodyMesh = configui.getValue(widgetPrefix .. selectedName)
	if selectedPawnBodyMesh == nil or selectedPawnBodyMesh == "" then
		selectedPawnBodyMesh = defaultValue
	end

	for i = 1, #pawnMeshList do
		if pawnMeshList[i] == selectedPawnBodyMesh then
			configui.setValue(widgetPrefix .. listName, i)
			break
		end
	end

end

local function setPawnMeshList()
	M.print("Setting pawn mesh list", LogLevel.Debug)
	pawnMeshList = uevrUtils.getObjectPropertyDescriptors(pawn, "Pawn", "Class /Script/Engine.SkeletalMeshComponent", includeChildrenInMeshList)
	M.print("Found " .. #pawnMeshList .. " meshes", LogLevel.Debug)
	updateMeshUI(pawnMeshList, "pawnBodyMeshList", "selectedPawnBodyMesh", configDefaults["bodyMeshName"])
	updateMeshUI(pawnMeshList, "pawnArmsMeshList", "selectedPawnArmsMesh", configDefaults["armsMeshName"])
	updateMeshUI(pawnMeshList, "pawnArmsAnimationMeshList", "selectedPawnArmsAnimationMesh", configDefaults["armsAnimationMeshName"])
end

--if the pawn isnt ready then keep checking until it is
local function loadPawnProperties()
	if uevrUtils.getValid(pawn) == nil then
		delay(1000, loadPawnProperties)
		return
	end
	setPawnMeshList()
	setBoneNames()
end


configui.onUpdate(widgetPrefix .. "pawnBodyMeshList", function(value)
	configui.setValue(widgetPrefix .. "selectedPawnBodyMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate(widgetPrefix .. "selectedPawnBodyMesh", function(value)
	if value ~= "" then
		--bodyMeshName = value
        updateSetting("bodyMeshName", value)
	end
end)

configui.onUpdate(widgetPrefix .. "pawnArmsMeshList", function(value)
	configui.setValue(widgetPrefix .. "selectedPawnArmsMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate(widgetPrefix .. "selectedPawnArmsMesh", function(value)
	if value ~= "" then
		--armsMeshName = value
        updateSetting("armsMeshName", value)
		setBoneNames()
	end
end)

configui.onUpdate(widgetPrefix .. "pawnArmsAnimationMeshList", function(value)
	configui.setValue(widgetPrefix .. "selectedPawnArmsAnimationMesh", pawnMeshList[value])
end)

configui.onCreateOrUpdate(widgetPrefix .. "selectedPawnArmsAnimationMesh", function(value)
	if value ~= "" then
		--armsAnimationMeshName = value
        updateSetting("armsAnimationMeshName", value)
	end
end)

configui.onCreateOrUpdate(widgetPrefix .. "hidePawnBodyMesh", function(value)
	--M.hideBodyMesh(value)
    updateSetting("hidePawnBodyMesh", value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "hidePawnArmsMesh", function(value)
	--M.hideArms(value)
    updateSetting("hidePawnArmsMesh", value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "hidePawnArmsBones", function(value)
    updateSetting("hidePawnArmsBones", value)
	--M.hideArmsBones(value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "hidePawnArmsAnimationMesh", function(value)
	--M.hideAnimationArms(value)
    updateSetting("hideAnimationArms", value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "pawnUpperArmRight", function(value)
	setPawnUpperArmRight(value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "pawnUpperArmLeft", function(value)
	setPawnUpperArmLeft(value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "pawnBodyFOVFix", function(value)
    updateSetting("bodyMeshFOVFixID", value)
	--M.setBodyMeshFOVFixID(value)
end)

configui.onCreateOrUpdate(widgetPrefix .. "pawnArmsFOVFix", function(value)
	--M.setArmsMeshFOVFixID(value)
    updateSetting("armsMeshFOVFixID", value)
end)

local createDevMonitor = doOnce(function()
	uevrUtils.registerLevelChangeCallback(function(level)
		loadScopeProperties()
	end)
end, Once.EVER)

function M.getConfigurationWidgets(options)
	return configui.applyOptionsToConfigWidgets(getConfigWidgets(paramManager), options)
end

function M.showConfiguration(saveFileName, options)
	configui.createConfigPanel(configTabLabel, saveFileName, spliceableInlineArray{expandArray(M.getConfigurationWidgets, options)})
end

local function setUIValue(key, value)
	local bonesChangd = false
	if key == "pawnUpperArmLeft" then
		configui.setValue(widgetPrefix .. "pawnUpperArmLeft", uevrUtils.indexOf(boneList, value) or 1, true)
	elseif key == "pawnUpperArmRight" then
		configui.setValue(widgetPrefix .. "pawnUpperArmRight", uevrUtils.indexOf(boneList, value) or 1, true)
	elseif key == "bodyMeshName" then
		configui.setValue(widgetPrefix .. "selectedPawnBodyMesh", value, true)
		configui.setValue(widgetPrefix .. "pawnBodyMeshList", uevrUtils.indexOf(pawnMeshList, value) or 1, true)
	elseif key == "armsMeshName" then
		configui.setValue(widgetPrefix .. "selectedPawnArmsMesh", value, true)
		configui.setValue(widgetPrefix .. "pawnArmsMeshList", uevrUtils.indexOf(pawnMeshList, value) or 1, true)
		bonesChangd = true
		--setBoneNames()
	elseif key == "armsAnimationMeshName" then
		configui.setValue(widgetPrefix .. "selectedPawnArmsAnimationMesh", value, true)
		configui.setValue(widgetPrefix .. "pawnArmsAnimationMeshList", uevrUtils.indexOf(pawnMeshList, value) or 1, true)
	elseif key == "hideAnimationArms" then
		configui.setValue(widgetPrefix .. "hidePawnArmsAnimationMesh", value, true)
	elseif key == "bodyMeshFOVFixID" then
		configui.setValue(widgetPrefix .. "pawnBodyFOVFix", value, true)
	elseif key == "armsMeshFOVFixID" then
		configui.setValue(widgetPrefix .. "pawnArmsFOVFix", value, true)
	else
		configui.setValue(widgetPrefix .. key, value, true)
	end
	return bonesChangd
end

local function updateUI(params)
	local bonesChanged = false
	for key, value in pairs(params) do
		if setUIValue(key, value) then bonesChanged = true end
	end
	if bonesChanged then
		setBoneNames()
	end
end

function M.init(m_paramManager)
    configDefaults = m_paramManager and m_paramManager:getAll() or {}
	paramManager = m_paramManager
    createDevMonitor()
    M.showConfiguration(configFileName)
	loadScopeProperties()

	paramManager:initProfileHandler(widgetPrefix, function(profileParams)
		if updateUI(profileParams) then
			setBoneNames()
		end
	end)
end

uevrUtils.registerUEVRCallback("on_scope_config_param_change", function(key, value)
	setUIValue(key, value)
end)


return M