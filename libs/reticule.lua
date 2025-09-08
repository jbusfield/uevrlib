local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local debugModule = require("libs/uevr_debug")

local M = {}
local reticuleComponent = nil
local reticuleRotation = nil
local reticulePosition = nil
local reticuleScale = nil
local reticuleCollisionChannel = 0

local configWidgets = {
	{
		widgetType = "slider_int",
		id = "reticuleDistance",
		label = "Distance",
		speed = 1.0,
		range = {0, 1000},
		initialValue = 200
	},
	{
		widgetType = "slider_float",
		id = "reticuleScale",
		label = "Scale",
		speed = 0.01,
		range = {0.01, 5.0},
		initialValue = 1.0
	},
	{
		widgetType = "drag_float3",
		id = "reticuleRotation",
		label = "Rotation",
		speed = 1,
		range = {0, 360},
		initialValue = {0.0, 0.0, 0.0}
	}
}

local defaultMeshMaterial = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[reticule] " .. text, logLevel)
	end
end

function M.getConfigurationWidgets()
	return configWidgets
end

function M.reset()
	reticuleComponent = nil
end

function M.exists()
	return reticuleComponent ~= nil
end

function M.getComponent()
	return reticuleComponent
end

function M.setDefaultMeshMaterial(materialName)
	defaultMeshMaterial = materialName
end

function M.destroy()
	if uevrUtils.getValid(reticuleComponent) ~= nil then
		uevrUtils.detachAndDestroyComponent(reticuleComponent, false)
	end
	M.reset()
end

function M.hide(val)
	if val == nil then val = true end
	if uevrUtils.getValid(reticuleComponent) ~= nil then reticuleComponent:SetVisibility(not val) end
end

-- widget can be string or object
-- options can be removeFromViewport, twoSided, drawSize, scale, rotation, position, collisionChannel
function M.createFromWidget(widget, options)
	M.print("Creating reticule from widget")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if widget ~= nil then
		reticuleComponent = uevrUtils.createWidgetComponent(widget, options)
		if uevrUtils.getValid(reticuleComponent) ~= nil then
			--reticuleComponent:SetDrawAtDesiredSize(true)

			reticuleComponent.BoundsScale = 10 --without this object can disappear when small

			uevrUtils.set_component_relative_transform(reticuleComponent, options.position, options.rotation, options.scale)
			reticuleRotation = uevrUtils.rotator(options.rotation)
			reticulePosition = uevrUtils.vector(options.position)		
			if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
				reticuleScale = kismet_math_library:Multiply_VectorVector(uevrUtils.vector(options.scale), uevrUtils.vector(-1,-1, 1))
			else
				reticuleScale = uevrUtils.vector(-0.1,-0.1,0.1) 
			end
			
			M.print("Created reticule " .. reticuleComponent:get_full_name())
		end
	else
		M.print("Reticule component could not be created, widget is invalid")
	end

	return reticuleComponent
end

-- mesh can be string or object
-- options can be materialName, scale, rotation, position, collisionChannel
function M.createFromMesh(mesh, options)
	M.print("Creating reticule from mesh")
	M.destroy()

	if options == nil then options = {} end
	if options.collisionChannel ~= nil then reticuleCollisionChannel = options.collisionChannel else reticuleCollisionChannel = 0 end
	if mesh == nil or mesh == "DEFAULT" then
		if options.scale == nil then options.scale = {.01, .01, .01} end
		mesh = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"	
		if options.materialName == nil then
			options.materialName = defaultMeshMaterial 
		end
	end
	
	local component = uevrUtils.createStaticMeshComponent(mesh, {tag="uevrlib_reticule"}) 
	if uevrUtils.getValid(component) ~= nil then
		if options.materialName ~= nil then
			M.print("Adding material to reticule component")
			local material = uevrUtils.getLoadedAsset(options.materialName)	
			--debugModule.dump(material)
			--local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", options.materialName) 
			if uevrUtils.getValid(material) ~= nil then
				component:SetMaterial(0, material)
			else
				M.print("Reticule material was invalid " .. options.materialName)
			end
		end
		
		component.BoundsScale = 10 -- without this object can disappear when small

		uevrUtils.set_component_relative_transform(component, options.position, options.rotation, options.scale)
		reticuleRotation = uevrUtils.rotator(options.rotation)
		reticulePosition = uevrUtils.vector(options.position)		
		if options.scale ~= nil then --default return from vector() is 0,0,0 so need to do special check
			reticuleScale = uevrUtils.vector(options.scale)
		else
			reticuleScale = uevrUtils.vector(1,1,1) 
		end
		
		M.print("Created reticule " .. component:get_full_name())
	else
		M.print("Reticule component could not be created")
	end

	reticuleComponent = component
	return reticuleComponent

	-- local component = nil
	-- if meshName == nil or meshName == "DEFAULT" then
		-- if scale == nil then scale = {.01, .01, .01} end
		-- --alternates
		-- --"Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"
		-- --"Material /Engine/EngineMaterials/DefaultLightFunctionMaterial.DefaultLightFunctionMaterial"
		-- --Not useful here but cool
		-- --Material /Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial
		-- --Material /Engine/EditorMeshes/ColorCalibrator/M_ChromeBall.M_ChromeBall
		-- local materialName = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough" 
		-- meshName = "StaticMesh /Engine/EngineMeshes/Sphere.Sphere"
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
		-- if uevrUtils.getValid(component) ~= nil then
			-- M.print("Crosshair is valid. Adding material")
			-- local material = uevrUtils.find_instance_of("Class /Script/Engine.Material", materialName) 
			-- if uevrUtils.getValid(material) ~= nil then
				-- component:SetMaterial(0, material)
			-- else
				-- M.print("Crosshair material was invalid " .. materialName)
			-- end
		-- end
	-- else		
		-- if scale == nil then scale = {1, 1, 1} end
		-- component = uevrUtils.createStaticMeshComponent(meshName, {tag="uevrlib_crosshair"}) 
	-- end
	
	
	-- if uevrUtils.getValid(component) ~= nil then
		-- component.BoundsScale = 10 --without this object can disappear when small
		-- component:SetWorldScale3D(uevrUtils.vector(scale))
		-- M.print("Created crosshair " .. component:get_full_name())
	-- end
	--crosshairComponent = component
end

function M.create()
	return M.createFromMesh()
end

-- function M.update_old(wandDirection, wandTargetLocation, originPosition, distanceAdjustment, crosshairScale, pitchAdjust, crosshairScaleAdjust)
	-- if distanceAdjustment == nil then distanceAdjustment = 200 end
	-- if crosshairScale == nil then crosshairScale = 1 end
	-- if pitchAdjust == nil then pitchAdjust = 0 end
	-- if crosshairScaleAdjust == nil then crosshairScaleAdjust = {0.01, 0.01, 0.01} end
	
	-- if  wandDirection ~= nil and wandTargetLocation ~= nil and originPosition ~= nil and uevrUtils.getValid(crosshairComponent) ~= nil then
		
		-- local maxDistance =  kismet_math_library:Vector_Distance(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- local targetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originPosition), uevrUtils.vector(wandTargetLocation))
		-- if distanceAdjustment > maxDistance then distanceAdjustment = maxDistance end
		-- temp_vec3f:set(wandDirection.X,wandDirection.Y,wandDirection.Z) 
		-- local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
		-- rot.Pitch = rot.Pitch + pitchAdjust
		-- temp_vec3f:set(originPosition.X + (targetDirection.X * distanceAdjustment), originPosition.Y + (targetDirection.Y * distanceAdjustment), originPosition.Z + (targetDirection.Z * distanceAdjustment))

		-- crosshairComponent:GetOwner():K2_SetActorLocation(temp_vec3f, false, reusable_hit_result, false)	
		-- crosshairComponent:K2_SetWorldLocationAndRotation(temp_vec3f, rot, false, reusable_hit_result, false)
		-- temp_vec3f:set(crosshairScale * crosshairScaleAdjust[1],crosshairScale * crosshairScaleAdjust[2],crosshairScale * crosshairScaleAdjust[3])
		-- crosshairComponent:SetWorldScale3D(temp_vec3f)	
	-- end
-- end

function M.getOriginPositionFromController()
	if not controllers.controllerExists(2) then
		controllers.createController(2)
	end
	return controllers.getControllerLocation(2)
end

function M.getTargetLocationFromController(handed)
	if not controllers.controllerExists(handed) then
		controllers.createController(handed)
	end
	local direction = controllers.getControllerDirection(handed)
	if direction ~= nil then
		local startLocation = controllers.getControllerLocation(handed)
		--print(startLocation.X,startLocation.Y,startLocation.Z)
		local endLocation = startLocation + (direction * 8192.0)
		
		local ignore_actors = {}
		local world = uevrUtils.get_world()
		if world ~= nil then
			local hit = kismet_system_library:LineTraceSingle(world, startLocation, endLocation, reticuleCollisionChannel, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			if hit and reusable_hit_result.Distance > 10 then
				endLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
			end
		end

		return endLocation
	else
		M.print("Error in getTargetLocationFromController. Controller direction was nil")
	end
end

function M.getTargetLocation(originPosition, originDirection)	
	local endLocation = originPosition + (originDirection * 8192.0)
	
	local ignore_actors = {}
	local world = uevrUtils.get_world()
	if world ~= nil then
		local hit = kismet_system_library:LineTraceSingle(world, originPosition, endLocation, reticuleCollisionChannel, false, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
		if hit and reusable_hit_result.Distance > 100 then
			endLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
		end
	end

	return endLocation
end

function M.update(originLocation, targetLocation, distance, scale, rotation )
	if uevrUtils.getValid(reticuleComponent) ~= nil and reticuleComponent.K2_SetWorldLocationAndRotation ~= nil then
		if distance == nil then distance = 200 end
		if scale == nil then scale = {1,1,1} end
		rotation = uevrUtils.rotator(rotation)
		
		if originLocation == nil or targetLocation == nil then
			local playerController = uevr.api:get_player_controller(0)
			local playerCameraManager = nil
			if playerController ~= nil then
				playerCameraManager = playerController.PlayerCameraManager
			end
			
			if originLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraLocation ~= nil then
					originLocation = playerCameraManager:GetCameraLocation()
				else
					originLocation = M.getOriginPositionFromController()
				end
			end
			
			if targetLocation == nil then
				if playerCameraManager ~= nil and playerCameraManager.GetCameraRotation ~= nil then
					local direction = kismet_math_library:GetForwardVector(playerCameraManager:GetCameraRotation())
					targetLocation = M.getTargetLocation(originLocation, direction)
				else
					targetLocation = M.getTargetLocationFromController(Handed.Right)
				end
			end
		end

		
		if originLocation ~= nil and targetLocation ~= nil then			
			local maxDistance =  kismet_math_library:Vector_Distance(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			--print(maxDistance)
			local hmdToTargetDirection = kismet_math_library:GetDirectionUnitVector(uevrUtils.vector(originLocation), uevrUtils.vector(targetLocation))
			if distance > maxDistance - 10 then distance = maxDistance - 10 end --move target distance back slightly so reticule doesnt go through the target
			temp_vec3f:set(hmdToTargetDirection.X,hmdToTargetDirection.Y,hmdToTargetDirection.Z) 
			local rot = kismet_math_library:Conv_VectorToRotator(temp_vec3f)
			rot = uevrUtils.sumRotators(rot, reticuleRotation, rotation)
			temp_vec3f:set(originLocation.X + (hmdToTargetDirection.X * distance) + reticulePosition.X, originLocation.Y + (hmdToTargetDirection.Y * distance) + reticulePosition.Y, originLocation.Z + (hmdToTargetDirection.Z * distance) + reticulePosition.Z)
			reticuleComponent:K2_SetWorldLocationAndRotation(temp_vec3f, rot, false, reusable_hit_result, false)
			if scale ~= nil then
				reticuleComponent:SetWorldScale3D(kismet_math_library:Multiply_VectorVector(uevrUtils.vector(scale), reticuleScale))
			end
		end
	else
		--M.print("Update failed component not valid")
	end
end

uevrUtils.registerPreLevelChangeCallback(function(level)
	M.print("Pre-Level changed in reticule")
	M.reset()
end)

return M
