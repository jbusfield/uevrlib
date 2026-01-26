local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local configui = require("libs/configui")
local paramModule = require("libs/core/params")

local M = {}

local settings = {}
local currentScopeID = ""

---@type any
local sceneCaptureComponent = nil
---@type any
local scopeMeshComponent = nil
---@type any
local scopeDebugComponent = nil
local currentActiveState = true
local isDisabled = true

local maxZoom = 1.0
local minZoom = 0.0
-- local maxFOV = 30.0
-- local minFOV = 1.0

local brightnessSpeed = 3.0
local maxBrightness = 8.0
local minBrightness = 0.1
--local currentBrightness = 1.0

local parameterDefaults = {
	min_fov = 2.0,
	max_fov = 32.0,
	brightness = 2.0,
	ocular_lens_scale = 1.0,
	objective_lens_rotation = {0.0, 0.0, 0.0},
	objective_lens_location = {0.0, 0.0, 0.0},
	ocular_lens_rotation = {0.0, 0.0, 0.0},
	ocular_lens_location = {0.0, 0.0, 0.0},
	zoom_speed = 1.0,
	zoom_exponential = 0.5,
	disable = false,
	deactivate_distance = 15.0,
	show_debug = false,
	zoom = 1.0,
	hide_ocular_lens_on_disable = true,
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[scope] " .. text, logLevel)
	end
end

local parametersFileName = "scope_parameters"
local parameters = {}
local paramManager = paramModule.new(parametersFileName, parameters, true)

local function saveParameter(scopeID, key, value, persist)
	--paramManager:set(key, value, persist)
	paramManager:set({"scopes", scopeID, key}, value, persist)
end

local function getParameter(scopeID, key)
    --return paramManager:get(key)
	local value = paramManager:get({"scopes", scopeID, key})
    return value or parameterDefaults[key]
end


-- local function saveSettings()
-- 	json.dump_file("uevrlib_scope_settings.json", settings)
-- 	M.print("Scope settings saved")
-- end

-- local timeSinceLastSave = 0
-- local isDirty = false
-- local function checkUpdates(delta)
-- 	timeSinceLastSave = timeSinceLastSave + delta
-- 	--prevent spamming save
-- 	if isDirty == true and timeSinceLastSave > 1.0 then
-- 		saveSettings()
-- 		isDirty = false
-- 		timeSinceLastSave = 0
-- 	end
-- end

-- function loadSettings()
-- 	settings = json.load_file("uevrlib_scope_settings.json")
-- 	if settings == nil then settings = {} end
-- end

M.AdjustMode =
{
    ZOOM = 0,
    BRIGHTNESS = 1,
}

local ETextureRenderTargetFormat = {
    RTF_R8 = 0,
    RTF_RG8 = 1,
    RTF_RGBA8 = 2,
    RTF_RGBA8_SRGB = 3,
    RTF_R16f = 4,
    RTF_RG16f = 5,
    RTF_RGBA16f = 6,
    RTF_R32f = 7,
    RTF_RG32f = 8,
    RTF_RGBA32f = 9,
    RTF_RGB10A2 = 10,
    RTF_MAX = 11,
}

function M.getConfigWidgets(prefix)
    prefix = prefix or ""
    return {
        {
            widgetType = "checkbox",
            id = prefix .. "scope_show_debug",
            label = "Show visual layout guide",
            initialValue = false
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_min_fov",
            label = "Max Zoom FOV",
            range = {0.01, 30},
            initialValue = parameterDefaults.min_fov
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_max_fov",
            label = "Min Zoom FOV",
            range = {0.01, 30},
            initialValue = parameterDefaults.max_fov
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_brightness",
            label = "Brightness",
            range = {0, 10},
            initialValue = parameterDefaults.brightness
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_ocular_lens_scale",
            label = "Scale",
            range = {0.1, 10},
            initialValue = parameterDefaults.ocular_lens_scale
        },
        {
            widgetType = "drag_float3",
            id = prefix .. "scope_objective_lens_rotation",
            label = "Objective Lens Rotation",
            speed = 0.1,
            range = {-90, 90},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = prefix .. "scope_objective_lens_location",
            label = "Objective Lens Location",
            speed = 0.05,
            range = {-100, 100},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = prefix .. "scope_ocular_lens_rotation",
            label = "Ocular Lens Rotation",
            speed = 0.1,
            range = {-90, 90},
            initialValue = {0.0, 0.0, 0.0}
        },
        {
            widgetType = "drag_float3",
            id = prefix .. "scope_ocular_lens_location",
            label = "Ocular Lens Location",
            speed = 0.05,
            range = {-100, 100},
            initialValue = {0.0, 0.0, 0.0}
        },
        -- {
        --     widgetType = "checkbox",
        --     id = prefix .. "scope_disable",
        --     label = "Disable",
        --     initialValue = false
        -- },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_zoom_speed",
            label = "Zoom Speed",
            range = {0, 2},
            initialValue = parameterDefaults.zoom_speed
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_zoom_exponential",
            label = "Zoom Exponential",
            range = {0, 1},
            initialValue = parameterDefaults.zoom_exponential
        },
        {
            widgetType = "slider_float",
            id = prefix .. "scope_deactivate_distance",
            label = "Deactivate distance",
            range = {0, 100},
            initialValue = parameterDefaults.deactivate_distance
        },
        {
            widgetType = "checkbox",
            id = prefix .. "scope_hide_ocular_lens_on_disable",
            label = "Hide Ocular Lens on Disable",
            initialValue = parameterDefaults.hide_ocular_lens_on_disable
        },
    }
end

function M.createConfigCallbacks(id, prefix)
	configui.onUpdate(prefix .. "scope_min_fov", function(value)
		saveParameter(id, "min_fov", value, true)
		M.setZoom(getParameter(id, "zoom"))
	end)

	configui.onUpdate(prefix .. "scope_max_fov", function(value)
		saveParameter(id, "max_fov", value, true)
		M.setZoom(getParameter(id, "zoom"))
	end)

	configui.onUpdate(prefix .. "scope_zoom_speed", function(value)
		saveParameter(id, "zoom_speed", value, true)
	end)

	configui.onUpdate(prefix .. "scope_zoom_exponential", function(value)
		saveParameter(id, "zoom_exponential", value, true)
	end)

	configui.onUpdate(prefix .. "scope_ocular_lens_scale", function(value)
		saveParameter(id, "ocular_lens_scale", value, true)
		M.setOcularLensScale(value)
	end)

	configui.onUpdate(prefix .. "scope_brightness", function(value)
		saveParameter(id, "brightness", value, true)
		M.setBrightness(value)
	end)

	configui.onUpdate(prefix .. "scope_objective_lens_rotation", function(value)
		saveParameter(id, "objective_lens_rotation", {value.Pitch, value.Yaw, value.Roll}, true)
		M.setObjectiveLensRelativeRotation(value)
	end)

	configui.onUpdate(prefix .. "scope_objective_lens_location", function(value)
		saveParameter(id, "objective_lens_location", {value.X, value.Y, value.Z}, true)
		M.setObjectiveLensRelativeLocation(value)
	end)

	configui.onUpdate(prefix .. "scope_ocular_lens_rotation", function(value)
		saveParameter(id, "ocular_lens_rotation", {value.Pitch, value.Yaw, value.Roll}, true)
		M.setOcularLensRelativeRotation(value)
	end)

	configui.onUpdate(prefix .. "scope_ocular_lens_location", function(value)
		saveParameter(id, "ocular_lens_location", {value.X, value.Y, value.Z}, true)
		M.setOcularLensRelativeLocation(value)
	end)

	configui.onUpdate(prefix .. "scope_disable", function(value)
		saveParameter(id, "disable", value, true)
		M.print("Scope disable set to " .. tostring(value))
		M.disable(value)
	end)

	configui.onUpdate(prefix .. "scope_deactivate_distance", function(value)
		saveParameter(id, "deactivate_distance", value, true)
		--M.setDeactivateDistance(value)
	end)

	configui.onUpdate(prefix .. "scope_hide_ocular_lens_on_disable", function(value)
		saveParameter(id, "hide_ocular_lens_on_disable", value, true)
	end)


	configui.onUpdate(prefix .. "scope_show_debug", function(value)
		saveParameter(id, "show_debug", value, true)
		M.showDebugMeshes(value)
	end)

	-- configui.onUpdate(prefix .. "scope_create_demo", function(value)
	-- 	saveParameter(id, "create_demo", value)
	-- 	M.destroy()
	-- 	M.create()
	-- end)

end

-- local configDefinition = {
-- 	{
-- 		panelLabel = "Scope Config", 
-- 		saveFile = "uevrlib_config_scope",
-- 		isHidden=false,
-- 		layout = 
-- 		{		
-- 			{
-- 				widgetType = "checkbox",
-- 				id = "uevr_lib_scope_create_demo",
-- 				label = "Create left hand demo",
-- 				initialValue = false
-- 			},
-- 			{
-- 				widgetType = "checkbox",
-- 				id = "uevr_lib_scope_show_debug",
-- 				label = "Show debug meshes",
-- 				initialValue = false
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_fov",
-- 				label = "FOV",
-- 				range = {0.01, 30},
-- 				initialValue = 2
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_brightness",
-- 				label = "Brightness",
-- 				range = {0, 10},
-- 				initialValue = 2
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_ocular_lens_scale",
-- 				label = "Scale",
-- 				range = {0.1, 10},
-- 				initialValue = 1
-- 			},
-- 			{
-- 				widgetType = "drag_float3",
-- 				id = "uevr_lib_scope_objective_lens_rotation",
-- 				label = "Objective Lens Rotation",
-- 				speed = 0.5,
-- 				range = {-90, 90},
-- 				initialValue = {0.0, 0.0, 0.0}
-- 			},
-- 			{
-- 				widgetType = "drag_float3",
-- 				id = "uevr_lib_scope_objective_lens_location",
-- 				label = "Objective Lens Location",
-- 				speed = 0.5,
-- 				range = {-100, 100},
-- 				initialValue = {0.0, 0.0, 0.0}
-- 			},
-- 			{
-- 				widgetType = "drag_float3",
-- 				id = "uevr_lib_scope_ocular_lens_rotation",
-- 				label = "Ocular Lens Rotation",
-- 				speed = 0.5,
-- 				range = {-90, 90},
-- 				initialValue = {0.0, 0.0, 0.0}
-- 			},
-- 			{
-- 				widgetType = "drag_float3",
-- 				id = "uevr_lib_scope_ocular_lens_location",
-- 				label = "Ocular Lens Location",
-- 				speed = 0.05,
-- 				range = {-100, 100},
-- 				initialValue = {0.0, 0.0, 0.0}
-- 			},
-- 			{
-- 				widgetType = "checkbox",
-- 				id = "uevr_lib_scope_disable",
-- 				label = "Disable",
-- 				initialValue = false
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_deactivate_distance",
-- 				label = "Deactivate distance",
-- 				range = {0, 100},
-- 				initialValue = 15
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_zoom_speed",
-- 				label = "Zoom Speed",
-- 				range = {0, 2},
-- 				initialValue = zoomSpeed
-- 			},
-- 			{
-- 				widgetType = "slider_float",
-- 				id = "uevr_lib_scope_zoom_exponential",
-- 				label = "Zoom Exponential",
-- 				range = {0, 1},
-- 				initialValue = zoomExponential
-- 			},
-- 		}	
-- 	}
-- }

--configui.create(configDefinition)
-- configui.setValue("uevr_lib_scope_create_demo", false)
-- configui.setValue("uevr_lib_scope_disable", false)

-- configui.onUpdate("uevr_lib_scope_fov", function(value)
-- 	M.setFOV(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_zoom_speed", function(value)
-- 	zoomSpeed = value
-- end)

-- configui.onUpdate("uevr_lib_scope_zoom_exponential", function(value)
-- 	zoomExponential = value
-- end)

-- configui.onUpdate("uevr_lib_scope_ocular_lens_scale", function(value)
-- 	M.setOcularLensScale(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_brightness", function(value)
-- 	M.setBrightness(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_objective_lens_rotation", function(value)
-- 	M.setObjectiveLensRelativeRotation(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_objective_lens_location", function(value)
-- 	M.setObjectiveLensRelativeLocation(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_ocular_lens_rotation", function(value)
-- 	M.setOcularLensRelativeRotation(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_ocular_lens_location", function(value)
-- 	M.setOcularLensRelativeLocation(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_disable", function(value)
-- 	M.disable(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_deactivate_distance", function(value)
-- 	M.setDeactivateDistance(value)
-- end)

-- configui.onUpdate("uevr_lib_scope_show_debug", function(value)
-- 	M.destroy()
-- 	if configui.getValue("uevr_lib_scope_create_demo") == true then
-- 		M.create()
-- 		M.attachToLeftHand()
-- 	end
-- end)

-- configui.onUpdate("uevr_lib_scope_create_demo", function(value)
-- 	M.destroy()
-- 	if value == true then
-- 		M.create()
-- 		M.attachToLeftHand()
-- 	end
-- end)
local function executeActiveScope(...)
	uevrUtils.executeUEVRCallbacks("scope_active_change", table.unpack({...}))
end
function M.setFOV(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then
		sceneCaptureComponent.FOVAngle = value
		--M.print(sceneCaptureComponent.FOVAngle)
	end
end

-- min_fov and max_fov may be confusing. min_fov is the narrowest field of view (highest zoom), max_fov is the widest field of view (lowest zoom)
function M.setZoom(zoom)
	local ratio = zoom / maxZoom
	local exponentialRatio = ratio ^ getParameter(currentScopeID, "zoom_exponential") -- where zoomExponential is typically less than 1 for gradual increase, >1 for steeper curve {Link: according to GitHub https://rikunert.github.io/exponential_scaler}
	local currentFOV = getParameter(currentScopeID, "max_fov") + exponentialRatio * (getParameter(currentScopeID, "min_fov") - getParameter(currentScopeID, "max_fov"))

	M.setFOV(currentFOV)
	if currentScopeID ~= nil and currentScopeID ~= "" then
		saveParameter(currentScopeID, "zoom", zoom, true)
	end
end

function M.updateZoom(zoomDirection, delta)
	if zoomDirection ~= 0 then
		local currentZoom = getParameter(currentScopeID, "zoom")
		currentZoom = currentZoom + (1 * getParameter(currentScopeID, "zoom_speed") * zoomDirection * delta)
		currentZoom = math.max(minZoom, math.min(maxZoom, currentZoom))

		M.setZoom(currentZoom)
		if currentScopeID ~= nil and currentScopeID ~= "" then
			saveParameter(currentScopeID, "zoom", currentZoom, true)
		end
	end
end

function M.updateBrightness(brightnessDirection, delta)
	if brightnessDirection ~= 0 then
		local currentBrightness = getParameter(currentScopeID, "brightness")
		currentBrightness = currentBrightness + (1 * brightnessSpeed * brightnessDirection * delta)
		currentBrightness = math.max(minBrightness, math.min(maxBrightness, currentBrightness))

		M.setBrightness(currentBrightness)
		if currentScopeID ~= nil and currentScopeID ~= "" then
			saveParameter(currentScopeID, "brightness", currentBrightness, true)
		end
	end
end


-- -- zoomType - 0 in, 1 out
-- -- zoomSpeed - 1.0 is default
-- function M.zoom(zoomType, zoomSpeed)
	-- if zoomType == nil then zoomType = 0 end
	-- if zoomSpeed == nil then zoomSpeed = 1.0 end

	-- ratio = currentZoom / MaxZoom
	-- exponentialRatio = ratio ^ exponent_value -- where exponent_value is typically less than 1 for gradual increase, >1 for steeper curve {Link: according to GitHub https://rikunert.github.io/exponential_scaler}
	-- currentFOV = minFOV + exponentialRatio * (MaxFOV - minFOV)
-- end


-- function M.zoomIn(zoomSpeed)
	-- M.zoom(0, zoomSpeed)
-- end

-- function M.zoomOut(zoomSpeed)
	-- M.zoom(1, zoomSpeed)
-- end

function M.getOcularLensComponent()
	return scopeMeshComponent
end

function M.getObjectiveLensComponent()
	return sceneCaptureComponent
end

function M.destroy()
	if sceneCaptureComponent ~= nil then
		uevrUtils.detachAndDestroyComponent(sceneCaptureComponent, true, true)
	end
	if scopeMeshComponent ~= nil then
		uevrUtils.detachAndDestroyComponent(scopeMeshComponent, true, true)
	end
	if scopeDebugComponent ~= nil then
		uevrUtils.detachAndDestroyComponent(scopeDebugComponent, true, true)
	end
	M.reset()
	executeActiveScope(false)
end

function M.reset()
	sceneCaptureComponent = nil
	scopeMeshComponent = nil
	scopeDebugComponent = nil
	currentActiveState = true
	isDisabled = true
end

function M.disable(value)
	isDisabled = true
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil and sceneCaptureComponent.SetVisibility ~= nil then
		sceneCaptureComponent:SetVisibility(not value)
		isDisabled = value
	end
	if uevrUtils.getValid(scopeMeshComponent) ~= nil and scopeMeshComponent.SetVisibility ~= nil then
		local val = value
		if getParameter(currentScopeID, "hide_ocular_lens_on_disable") == false then
			val = false
		end
		scopeMeshComponent:SetVisibility(not val)
	end
	if uevrUtils.getValid(scopeDebugComponent) ~= nil and scopeDebugComponent.SetVisibility ~= nil then
		local val = value
		if getParameter(currentScopeID, "show_debug") == false then
			val = true
		end
		scopeDebugComponent:SetVisibility(not val)
	end
	executeActiveScope(not value)
end

function M.setOcularLensScale(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil and value ~= nil then
		uevrUtils.set_component_relative_scale(scopeMeshComponent, {value*0.05,value*0.05,value*0.001})
	end
end

function M.setObjectiveLensRelativeRotation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil and value ~= nil then
		uevrUtils.set_component_relative_rotation(sceneCaptureComponent, {value.X-90,value.Y,value.Z})
		--print(value.X-90,value.Y,value.Z)
	end
end

function M.setObjectiveLensRelativeLocation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil and value ~= nil then
		uevrUtils.set_component_relative_location(sceneCaptureComponent, {value.X,value.Y,value.Z})
	end
end

-- function M.setDeactivateDistance(value)
-- 	deactivateDistance = value
-- end

function M.setOcularLensRelativeRotation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil and value ~= nil then
		uevrUtils.set_component_relative_rotation(scopeMeshComponent, {value.X,value.Y,value.Z})
	end
end

local function activeStateChanged(isActive)
	M.disable(not isActive)
end

function M.updateActiveState()
	local isActive = true
	if uevrUtils.getValid(scopeMeshComponent) == nil or uevrUtils.getValid(sceneCaptureComponent) == nil or scopeMeshComponent.K2_GetComponentLocation == nil then
		isActive = false
	else
		local deactivateDistance = getParameter(currentScopeID, "deactivate_distance")
		local headLocation = controllers.getControllerLocation(2)
		local ocularLensLocation = scopeMeshComponent:K2_GetComponentLocation()
		if headLocation ~= nil and ocularLensLocation ~= nil then
			local distance = kismet_math_library:Vector_Distance(headLocation, ocularLensLocation)
			isActive = distance < deactivateDistance
			--M.disable(distance > deactivateDistance)
			--scopeMeshComponent:SetVisibility(not (distance > deactivateDistance))
		end
	end
	if isActive ~= currentActiveState then
		activeStateChanged(isActive)
	end
	currentActiveState = isActive
end

function M.isDisplaying()
	return not isDisabled
end

function M.setOcularLensRelativeLocation(value)
	value = uevrUtils.vector(value)
	if uevrUtils.getValid(scopeMeshComponent) ~= nil and value ~= nil then
		uevrUtils.set_component_relative_location(scopeMeshComponent, {value.X,value.Y,value.Z})
	end
end

function M.setBrightness(value)
	local scopeMaterial = scopeMeshComponent:GetMaterial(0)
	if scopeMaterial ~= nil then
		local color = uevrUtils.color_from_rgba(value, value, value, value)
		scopeMaterial:SetVectorParameterValue("Color", color)
	end
end

EAttachmentRule = {
    KeepRelative = 0,
    KeepWorld = 1,
    SnapToTarget = 2,
    EAttachmentRule_MAX = 3,
}

function M.createOcularLens(renderTarget2D, options)
	if options == nil then options = {} end
	if options.scale == nil then options.scale = configui.getValue("uevr_lib_scope_ocular_lens_scale") end
	if options.brightness == nil then options.brightness = getParameter(currentScopeID, "brightness") end

	--currentBrightness = options.brightness
	-- if settings[currentScopeID] ~= nil and settings[currentScopeID].brightness ~= nil then
	-- 	currentBrightness = settings[currentScopeID].brightness
	-- end

	uevrUtils.getLoadedAsset("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
	scopeMeshComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder", {visible=false, collisionEnabled=false} )
	if uevrUtils.getValid(scopeMeshComponent) ~= nil then
		M.setOcularLensScale(options.scale)

		local templateMaterial = uevrUtils.find_required_object("Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial")
		if templateMaterial ~= nil then
			--templateMaterial.BlendMode = 7
			-- templateMaterial.BlendMode = 0
			-- templateMaterial.TwoSided = 0
			templateMaterial:set_property("BlendMode", 0)
			templateMaterial:set_property("TwoSided", false)

			-- templateMaterial.bDisableDepthTest = true
			-- templateMaterial.MaterialDomain = 0
			-- templateMaterial.ShadingModel = 0
---@diagnostic disable-next-line: need-check-nil
			local scopeMaterial = scopeMeshComponent:CreateDynamicMaterialInstance(0, templateMaterial, "scope_material")
			scopeMaterial:SetTextureParameterValue("LinearColor", renderTarget2D)
			M.setBrightness(options.brightness)
		end
		M.print("scopeMeshComponent created")
	else
		M.print("Could not create scopeMeshComponent")
	end
end

function M.createObjectiveLens(renderTarget2D, options)
	if options == nil then options = {} end
	if options.fov == nil then options.fov = getParameter(currentScopeID, "fov") end
---@diagnostic disable-next-line: cast-local-type
	minFOV = options.fov

	sceneCaptureComponent = uevrUtils.createSceneCaptureComponent({visible=false, collisionEnabled=false})
	if uevrUtils.getValid(sceneCaptureComponent) ~= nil then
		sceneCaptureComponent.TextureTarget = renderTarget2D
		--M.setFOV(minFOV)
		M.updateZoom(1, 0)
		M.setObjectiveLensRelativeRotation(getParameter(currentScopeID, "objective_lens_rotation"))
		--uevrUtils.set_component_relative_rotation(sceneCaptureComponent, {Pitch=-90, Yaw=0, Roll=0})

		scopeDebugComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder", {visible=true, collisionEnabled=false})
		if scopeDebugComponent ~= nil then
			scopeDebugComponent:K2_AttachTo(sceneCaptureComponent, uevrUtils.fname_from_string(""), EAttachmentRule.KeepRelative, false)
			uevrUtils.set_component_relative_transform(scopeDebugComponent, {0.5,0,0},{Pitch=90, Yaw=0, Roll=0},{0.01,0.01,0.01})
			scopeDebugComponent:SetVisibility(getParameter(currentScopeID, "show_debug"))
		end

		M.print("sceneCaptureComponent created")
	else
		M.print("sceneCaptureComponent not created")
	end
end

function M.showDebugMeshes(value)
	if uevrUtils.getValid(scopeDebugComponent) ~= nil then
		scopeDebugComponent:SetVisibility(value)
	end
end

function M.createAndAttach(id, attachment)
	M.print("Found scope settings. Creating scope")
	local ocularLensComponent, objectiveLensComponent = M.create(id)
	if objectiveLensComponent ~= nil then
		objectiveLensComponent:K2_AttachToComponent(
				attachment,
				"", --scopeSettings["socket"],
				0, -- Location rule
				0, -- Rotation rule
				0, -- Scale rule
				false -- Weld simulated bodies
			)
	else
		M.print("Objective lens component creation failed")
	end
	if ocularLensComponent ~= nil then
		ocularLensComponent:K2_AttachToComponent(
				attachment,
				"",
				0, -- Location rule
				0, -- Rotation rule
				0, -- Scale rule
				false -- Weld simulated bodies
			)
	else
		M.print("Ocular lens component creation failed")
	end
	M.setObjectiveLensRelativeRotation(getParameter(currentScopeID, "objective_lens_rotation"))
	M.setObjectiveLensRelativeLocation(getParameter(currentScopeID, "objective_lens_location"))
	M.setOcularLensRelativeRotation(getParameter(currentScopeID, "ocular_lens_rotation"))
	M.setOcularLensRelativeLocation(getParameter(currentScopeID, "ocular_lens_location"))
	M.setOcularLensScale(getParameter(currentScopeID, "ocular_lens_scale"))

	M.print("Scope created")
end

-- options example { disabled=true, fov=2.0, brightness=2.0, scale=1.0, deactivateDistance=15, hideOcularLensOnDisable=true}
function M.create(id, options)
	currentScopeID = id or ""
	M.destroy()

	if options == nil then options = {} end
	if options.brightness == nil then options.brightness = 1.0 end

	-- currentID = ""
	-- local id = options.id
	-- if id ~= nil then
	-- 	if settings[id] == nil then
	-- 		settings[id] = {}
	-- 		settings[id].zoom = 1.0
	-- 		settings[id].brightness = options.brightness
	-- 	end
	-- 	currentID = id
	-- end
	if options.deactivateDistance then
		saveParameter(currentScopeID, "deactivate_distance", options.deactivateDistance, false)
	end
	if options.hideOcularLensOnDisable then
		saveParameter(currentScopeID, "hide_ocular_lens_on_disable", options.hideOcularLensOnDisable, false)
	end

	local renderTarget2D = uevrUtils.createRenderTarget2D({width=1024, height=1024, format=ETextureRenderTargetFormat.RTF_RGBA16f})
	M.createOcularLens(renderTarget2D, options)
	M.createObjectiveLens(renderTarget2D, options)

	local disabled = options ~= nil and (options.disabled == true) or getParameter(currentScopeID, "disable") == true
	M.disable(disabled)

	return M.getOcularLensComponent(), M.getObjectiveLensComponent()
end

function M.attachToLeftHand()
	local headConnected = controllers.attachComponentToController(Handed.Left, M.getObjectiveLensComponent(), nil, nil, nil, true)
	local leftConnected = controllers.attachComponentToController(Handed.Left, M.getOcularLensComponent(), nil, nil, nil, true)
end

uevrUtils.registerPostEngineTickCallback(function(engine, delta)
	M.updateActiveState()
	--checkUpdates(delta)
end)

uevrUtils.registerLevelChangeCallback(function(level)
	M.reset()
end)

function M.init(isDeveloperMode, logLevel)
    paramManager:load()
end

function M.setActive(id)
	--print("Setting active scope to ", id)
	currentScopeID = id
end

function M.isActive()
	--TODO add better checks
	return currentScopeID ~= nil and currentScopeID ~= "" and scopeMeshComponent ~= nil and sceneCaptureComponent ~= nil
end

uevrUtils.registerUEVRCallback("attachment_grip_changed", function(id, gripHand)
    --M.addAdjustment({id = id})
	M.setActive("")
	M.destroy()

end)

uevr.params.sdk.callbacks.on_script_reset(function()
	M.destroy()
end)

local autoHandleInput = true
function M.setAutoHandleInput(value)
	autoHandleInput = value
end
local scopeAdjustDirection = 0
local scopeAdjustMode = M.AdjustMode.ZOOM
local leftControls = false
uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
	if M.isActive() and autoHandleInput then
		scopeAdjustDirection = 0
		local thumbY = state.Gamepad.sThumbRY
		if leftControls then
			thumbY = state.Gamepad.sThumbLY
		end

		if thumbY >= 10000 or thumbY <= -10000 then
			scopeAdjustDirection = thumbY/32768
		end
		scopeAdjustMode = M.AdjustMode.ZOOM
		local dpadMethod = uevr.params.vr:get_mod_value("VR_DPadShiftingMethod")
		--print(string.find(dpadMethod,"0"),string.find(dpadMethod,"1"))
		if uevrUtils.isThumbpadTouched(state, string.find(dpadMethod,"1") and Handed.Right or Handed.Left) then
			scopeAdjustMode = M.AdjustMode.BRIGHTNESS
		end
	end
end, 9) --high priority to intercept messages before possible remapper

function on_post_engine_tick(engine, delta)
	if M.isActive() and autoHandleInput then
		if scopeAdjustMode == M.AdjustMode.BRIGHTNESS then
			M.updateBrightness(scopeAdjustDirection, delta)
		elseif scopeAdjustMode == M.AdjustMode.ZOOM then
			M.updateZoom(scopeAdjustDirection, delta)
		end
	end
end

return M