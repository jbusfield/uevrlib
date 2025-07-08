local uevrUtils = require("libs/uevr_utils")
uevrUtils.initUEVR(uevr)
local debugModule = require("libs/uevr_debug")
local controllersModule = require("libs/controllers")
local flickerFixer = require("libs/flicker_fixer")


local objectsConnected = false

function on_level_change(level)
	print("Level changed\n")

	controllersModule.onLevelChange()
	controllersModule.createController(0)
	controllersModule.createController(1)
	controllersModule.createController(2) 
	objectsConnected = false
	
	--To fix flicker with the Native Stereo Fix on, include the require("libs/flicker_fixer") 
	--above and call flickerFixer.create() at a level change
	flickerFixer.create()
	
end

function on_pre_engine_tick(engine, delta)
	attachObjectsToControllers()
end

function on_lazy_poll()

end

--replace this with a way to get a widget in your particular game
function getWidget()
	local hud = uevrUtils.find_first_of("Class /Script/Indiana.HUDWidget", false)
	if hud ~= nil then
		return hud.Compass
	end
end

function attachObjectsToControllers()
	if objectsConnected == false then
		local rightComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
		local rightConnected = controllersModule.attachComponentToController(1, rightComponent)
		uevrUtils.set_component_relative_transform(rightComponent, nil, nil, {X=0.03, Y=0.03, Z=0.03})
		
		local leftComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/BasicShapes/Cube.Cube")
		local leftConnected = controllersModule.attachComponentToController(0, leftComponent)
		uevrUtils.set_component_relative_transform(leftComponent, nil, nil, {X=0.03, Y=0.03, Z=0.03})

		local widget = getWidget()
		if widget ~= nil then
			local hudComponent = uevrUtils.createWidgetComponent(widget, true, false, vector_2(620, 75))
			local hudConnected = controllersModule.attachComponentToController(2, hudComponent)		
			uevrUtils.set_component_relative_transform(hudComponent, {X=25.0, Y=0.0, Z=10}, {Pitch=0,Yaw=0 ,Roll=0}, {X=-0.03, Y=-0.03, Z=0.03})
		end
		objectsConnected = rightConnected and leftConnected
	end
end

hook_function("Class /Script/Engine.PlayerController", "ClientRestart", true, nil, 
	function(fn, obj, locals, result)
		print("ClientRestart called")
		return false
	end
, true)

register_key_bind("F1", function()
    print("F1 pressed\n")
	debugModule.dump(pawn)
end)

register_key_bind("F2", function()
    print("F2 pressed\n")
end)

