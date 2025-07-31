-- The following code includes contributions from markmon and Pande4360

--[[ 
Usage
	Drop the lib folder containing this file into your project folder
	At the top of your script file add 
		local uevrUtils = require("libs/uevr_utils")
		uevrUtils.initUEVR(uevr)
		
	In your code call function like this
		local actor = uevrUtils.spawn_actor(transform, collisionMethod, owner)
		
	Some functions such as setTimeout(msec, func) that are globally useful have both
	a global and module referenced implementation. The module reference is just for
	convenience and does nothing but call the global implementation
	
	Available functions:
	
	setTimeout(msec, func) or uevrUtils.setTimeout(msec, func)) or uevrUtils.delay(msec, func) - delays for specified number of milliseconds 
		before executing func. 
		delay(msec, func) is deprecated to prevent global naming conflicts but, if used, will still call setTimeout(msec, func) internally
		example: 
			setTimeout(1000, function()
				print("after one second delay")
			end)
			
	setInterval(msec, func) or uevrUtils.setInterval(msec, func) - delays for specified number of milliseconds before executing func then repeats
		example: 
			setInterval(1000, function()
				print("repeats one second delay")
			end)

	uevrUtils.vector_2(x, y, reuseable) - returns a CoreUObject.Vector2D structure with the given params
		example:
			print("X value is",uevrUtils.vector_2(3, 4).X)
			
	uevrUtils.vector_3(x, y, z) - returns a UEVR Vector3d structure with the given params. Replacement for using temp_vec3 directly
		example:
			print("Z value is",uevrUtils.vector_3(3, 4, 5).Z)
	
	uevrUtils.vector_3f(x, y, z) - returns a UEVR Vector3f structure with the given params. Replacement for using temp_vec3f directly
		example:
			print("Z value is",uevrUtils.vector_3f(3, 4, 5).Z)
	
	uevrUtils.quatf(x, y, z, w) - returns a UEVR Quaternion structure with the given params
		example:
			print("Z value is",uevrUtils.quatf(3, 4, 5, 1).Z)
	
	uevrUtils.quat(x, y, z, w, reuseable) - returns a CoreUObject.Quat structure with the given params.
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("Z value is",uevrUtils.quat(3, 4, 5, 1).Z)
	
	uevrUtils.rotator(pitch, yaw, roll, reuseable) - returns a CoreUObject.Rotator with the given params
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("Yaw value is",uevrUtils.rotator(30, 40, 50).Yaw)
	
	uevrUtils.vector(x, y, z, (optional)reuseable) - returns a CoreUObject.Vector with the given params
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			print("X value is",uevrUtils.vector(30, 40, 50).X)
	
	uevrUtils.vector(table, (optional)reuseable) - returns a CoreUObject.Vector with the given params
		If reuseable is true a cached struct is returned. 
		example:
			print("X value is",uevrUtils.vector({30,40,50}).X)
			print("X value is",uevrUtils.vector({X=30,Y=40,Z=50}).X)
			print("X value is",uevrUtils.vector({x=30,y=40,z=50}).X)
	
	uevrUtils.rotatorFromQuat(x, y, z, w) - returns CoreUObject.Rotator given the x,y,z and w values from a quaternion
		example:
			print("Yaw value is",uevrUtils.rotatorFromQuat(0, 0, 0, 1).Yaw)
	
	uevrUtils.get_transform((optional)position, (optional)rotation, (optional)scale) -- returns a CoreUObject.Transform struct with the given params. 
		Replacement for temp_transform
		examples:
			local transform = uevrUtils.get_transform() -- position and rotation are set to 0s, scale is set to 1
			local transform = uevrUtils.get_transform({X=10, Y=15, Z=20})
			local transform = uevrUtils.get_transform({X=10, Y=15, Z=20}, nil, {X=.5, Y=.5, Z=.5})
			
	uevrUtils.set_component_relative_transform(component, (optional)position, (optional)rotation, (optional)scale) - sets the relative position, rotation
		and scale of a component class derived object
		examples:
			uevrUtils.set_component_relative_transform(meshComponent) -- position and rotation are set to 0s, scale is set to 1
			uevrUtils.set_component_relative_transform(meshComponent, {X=10, Y=10, Z=10}, {Pitch=0, Yaw=90, Roll=0})
	
	uevrUtils.get_struct_object(structClassName, (optional)reuseable) - get a structure object that can optionally be reuseable
		example:
			local vector = uevrUtils.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D")
			
	uevrUtils.get_reuseable_struct_object(structClassName) - gets a structure that can be reused in the way temp_transform was used but for any structure class
		The structure is cached so repeated calls to this function for the same class incur no penalty
		example:
			local reuseableColor = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")
			reuseableColor.R = 1.0
			
	uevrUtils.get_world() - gets the current world
		example:
			local world = uevrUtils.get_world()
	
	uevrUtils.spawn_actor(transform, collisionMethod, owner) - spawns an actor with the given params
		example:
			local pos = pawn:K2_GetActorLocation()
			local actor = uevrUtils.spawn_actor( uevrUtils.get_transform({X=pos.X, Y=pos.Y, Z=pos.Z}), 1, nil)
		
	uevrUtils.getValid(object, (optional)properties) -- returns a valid object or property of an object or nil if none is found. Use this
		in place of endless nested checks for nil on objects and their properties. Properties are passed in as an array of hierarchical 
		property names. The first example shows how to get the property pawn.Weapon.WeaponMesh
		example:
			local mesh = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
			local validPawn = uevrUtils.getValid(pawn) -- gets a valid pawn or nil
	
	uevrUtils.validate_object(object) - if the object is returned from this function then it is not nil and it exists
		if uevrUtils.validate_object(object) ~- nil then 
			print("Good object")
		end
	
	uevrUtils.destroy_actor(actor) - destroys a spawned actor
		example:
			uevrUtils.destroy_actor(actor)
		
	uevrUtils.create_component_of_class(className, (optional)manualAttachment, (optional)relativeTransform, (optional)deferredFinish, (optional)parent) - creates and 
		initializes a component based object of the desired class. If parent is provided then parent is used as the component's actor rather than create a new actor
		example:
			local component = create_component_of_class("Class /Script/Engine.StaticMeshComponent")
	
	uevrUtils.find_required_object(name) - wrapper for uevr.api:find_uobject(name).
	
	uevrUtils.get_class(name, (optional)clearCache) - cached wrapper for uevr.api:find_uobject(name). Can be called repeatedly for the same name 
		with no performance hit unless clearCache is true
		examples:
			local componentClass = uevrUtils.get_class("Class /Script/Engine.StaticMeshComponent")
			local poseableComponent = baseActor:AddComponentByClass(componentClass, true, uevrUtils.get_transform(), false)

	uevrUtils.find_instance_of(className, objectName) - find the named object instance of the given className. Can use short names for objects
		example:
			local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			local mesh = uevrUtils.find_instance_of("Class /Script/Engine.StaticMesh", "Sphere")
	
	uevrUtils.find_first_of(className, (optional)includeDefault) - find the first object instance of the given className
		example:
			local widget = uevrUtils.find_first_of("Class /Script/Indiana.HUDWidget", false)

	uevrUtils.find_all_of(className, (optional)includeDefault) - find all object instances of the given className. Returns an empty array if none found
		example:
			local motionControllers = uevrUtils.find_all_of("Class /Script/HeadMountedDisplay.MotionControllerComponent", false)

	uevrUtils.find_default_instance(className) - returns get_class_default_object() for the given className. Wraps uevr class:get_class_default_object()
		example:
			kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
			
	uevrUtils.find_first_instance(className, (optional)includeDefault) - find the first class instance of a given className. Wraps uevr class:get_first_object_matching(includeDefault)
	
	uevrUtils.find_all_instances(className, (optional)includeDefault) - find the all class instances of a given className. Wraps uevr class:get_objects_matching(includeDefault)
	
	uevrUtils.fname_from_string(str) - returns the FName of a given string
		example:
			local fname = uevrUtils.fname_from_string("Mesh")
			
	uevrUtils.color_from_rgba(r,g,b,a,reuseable) or color_from_rgba(r,g,b,a,reuseable) - returns a CoreUObject.LinearColor struct with the given params in the range of 0.0 to 1.0
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			local color = uevrUtils.color_from_rgba(1.0, 0.0, 0.0, 1.0)
			
	uevrUtils.color_from_rgba_int(r,g,b,a,reuseable) or color_from_rgba_int(r,g,b,a,reuseable) - returns a CoreUObject.Color struct with the given params in the range of 0 to 255
		If reuseable is true a cached struct is returned. This is faster but if you need two instances for the same function call this would not work
		example:
			uevr.api:get_player_controller(0):ClientSetCameraFade(false, color_from_rgba_int(0,0,0,0), vector_2(0, 1), 1.0, false, false)

	uevrUtils.isButtonPressed(state, button) - returns true if the given XINPUT button is pressed. The state param comes from on_xinput_get_state()
	uevrUtils.isButtonNotPressed(state, button) - returns true if the given XINPUT button is not pressed. The state param comes from on_xinput_get_state()
	uevrUtils.pressButton(state, button) - triggers a button press for the specified button. The state param comes from on_xinput_get_state()
	uevrUtils.unpressButton(state, button) - stops a button press for the specified button. The state param comes from on_xinput_get_state()
		example
			if isButtonPressed(state, XINPUT_GAMEPAD_X) then
				unpressButton(state, XINPUT_GAMEPAD_X)
				pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
			end
			
	uevrUtils.fadeCamera(rate, (optional)hardLock, (optional)softLock, (optional)overrideHardLock, (optional)overrideSoftLock) - fades the players camera to black
		example:
			uevrUtils.fadeCamera(1.0) - fades the camera to black over one second at which time the fade will disappear
			uevrUtils.fadeCamera(1.0, true) - fades the camera to black over one second and then keeps it black
			uevrUtils.fadeCamera(0.1, false, false, true) - unfades a camera that was previously locked to black

	uevrUtils.set_2D_mode(state, (optional)delay_msec) - make UEVR switch in or out of 2D mode
		example:
			uevrUtils.set_2D_mode(true)
			
	uevrUtils.set_cvar_int(cvar, value) or set_cvar_int(cvar, value) - sets an int cvar value
		example:
			uevrUtils.set_cvar_int("r.VolumetricFog", 0)
			
	uevrUtils.PrintInstanceNames(class_to_search) - Print all instance names of a class to debug console
	
	uevrUtils.getAssetDataFromPath(pathStr) - converts a path string into an AssetData structure
		example:
			local fAssetData = uevrUtils.getAssetDataFromPath("StaticMesh /Game/Environment/Hogwarts/Meshes/Statues/SM_HW_Armor_Sword.SM_HW_Armor_Sword")
			
	uevrUtils.getLoadedAsset(pathStr) - get an object even if it's not already loaded into the system
		example:
			local staticMesh = uevrUtils.getLoadedAsset("StaticMesh /Game/Environment/Hogwarts/Meshes/Statues/SM_HW_Armor_Sword.SM_HW_Armor_Sword")

	uevrUtils.copyMaterials(fromComponent, toComponent) - Copy Materials from one component to another
		example:
			uevrUtils.copyMaterials(wand.SK_Wand, component)
	
	uevrUtils.getChildComponent(parent, name) - gets a child component of a given parent component (from AttachChildren param) using partial name
		example:
			local referenceGlove = uevrUtils.getChildComponent(pawn.Mesh, "Gloves")
	
	uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, (optional)options) - creates a skeletal mesh component (PoseableMeshComponent) that can be 
		manually manipulated and is a copy of the passed in skeletalMeshComponent. If parent is provided then parent is used as the component's actor rather 
		than create a new actor
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
			showDebug(bool)
		example:
			poseableComponent = uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, {showDebug=false})
	
	uevrUtils.createSkeletalMeshComponent(meshName, (optional)options) - creates a skeletal mesh component and assigns a mesh to it with the given name. 
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
		Can use short name. If parent is provided then parent is used as the component's actor rather than create a new actor
		example:
			local component = uevrUtils.createSkeletalMeshComponent(wand.SK_Wand.SkeletalMesh:get_full_name(), {parent=wand})	

	uevrUtils.createStaticMeshComponent(mesh, (optional)options) - creates a static mesh component and assigns a mesh to it.
		The mesh param can be a StaticMesh object or the class name of a static mesh. Can use short name
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
		example:
			local rightComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			local rightComponent = uevrUtils.createStaticMeshComponent("Sphere") --beware of duplicate short names
			local rightComponent = uevrUtils.createStaticMeshComponent(mesh)

	uevrUtils.createWidgetComponent(widget, (optional)options) - creates a widget component and assigns a widget to it
		The widget param can be a widget class name or an actual widget object
		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
			removeFromViewport(bool)
			twoSided(bool)
			drawSize(Vector2D)
		example:
			local hudComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=true, twoSided=true, drawSize=vector_2(620, 75)})	
			local hudComponent = uevrUtils.createWidgetComponent("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C", {removeFromViewport=true, twoSided=true, drawSize=vector_2(100, 100)})	
	
	uevrUtils.fixMeshFOV(mesh, propertyName, value, (optional)includeChildren, (optional)includeNiagara, (optional)showDebug) --Removes the FOV distortions that 
		many flat FPS games apply to player and weapon meshes using ScalarParameterValues
		example:
			uevrUtils.fixMeshFOV(hands.getHandComponent(0), "UsePanini", 0.0, true, true, true)
	
	uevrUtils.registerOnInputGetStateCallback(func) - register for a your own callback when the uevr callback fires

	uevrUtils.registerPreEngineTickCallback(func) - register for a your own callback when the uevr callback fires

	uevrUtils.registerPostEngineTickCallback(func) - register for a your own callback when the uevr callback fires

	uevrUtils.registerPreCalculateStereoViewCallback(func) - register for a your own callback when the uevr callback fires

	uevrUtils.registerPostCalculateStereoViewCallback(func) - register for a your own callback when the uevr callback fires
		example:
			uevrUtils.registerPreEngineTickCallback(function(engine, delta)
				print("Delta is",delta)
			end)


	hook_function(class_name, function_name, native, prefn, postfn, dbgout)	- a method of getting a function callback from the game engine
		example:
			hook_function("BlueprintGeneratedClass /Game/Blueprints/Player/IndianaPlayerCharacter_BP.IndianaPlayerCharacter_BP_C", "PlayerCinematicChange", false, 
				function(fn, obj, locals, result)
					print("IndianaPlayerCharacter PlayerCinematicChange")
					isInCinematic = locals.bCinematicMode
					return true
				end
			, nil, true)

	register_key_bind(keyName, callbackFunc) - registers a callback function that will be triggered when a key is pressed
		example:
			register_key_bind("F1", function()
				print("F1 pressed\n")
			end)
			register_key_bind("LeftMouseButton", function()
				print("Left mouse button pressed\n")
			end)
			

	Callbacks:	
		The following functions can be added to you main script. They are optional and will only be called if you add them
		
		--callback for uevr.sdk.callbacks.on_xinput_get_state
		function on_xinput_get_state(retval, user_index, state)
		end

		--callback for on_pre_calculate_stereo_view_offset
		function on_pre_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end

		--callback for on_post_calculate_stereo_view_offset
		function on_post_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end
		
		--callback for uevr.sdk.callbacks.on_pre_engine_tick
		function on_pre_engine_tick(engine, delta)
		end

		--callback for uevr.sdk.callbacks.on_post_engine_tick
		function on_post_engine_tick(engine, delta)
		end

		-- function that gets called once per second for things you want to do at a slower interval than every tick
		function on_lazy_poll()
		end

		-- function that gets called when the level changes
		function on_level_change(level)
		end

		-- function that gets called when this library has finished initializing
		function UEVRReady(instance)
		end
]]--


-------------------------------
-- Globals
--  These exist for backwards compatability with existing scripts 
--  The functions in this library provide better ways than using these globals
temp_vec3 = nil
temp_vec3f = nil
temp_quatf = nil

reusable_hit_result = nil
temp_transform = nil
zero_color = nil

game_engine = nil

static_mesh_component_c = nil
motion_controller_component_c = nil			 
scene_component_c = nil
actor_c = nil

-- These are useful as is
pawn = nil -- updated every tick 
Statics = nil
WidgetBlueprintLibrary = nil
kismet_system_library = nil
kismet_math_library = nil
kismet_string_library = nil 
kismet_rendering_library = nil
--uevr = nil
-------------------------------
-- global enums
LogLevel = {
    Off = 0,
    Critical = 1,
    Error = 2,
    Warning = 3,
    Info = 4,
    Debug = 5,
    Trace = 6,
    Ignore = 99,
}

LogLevelString = {[0]="off",[1]="crit",[2]="error",[3]="warn",[4]="info",[5]="debug",[6]="trace",[99]="ignore"}

Handed = {
	Left = 0, 
	Right = 1
}
-------------------------------
local coreLerp = require("libs/core/lerp")

local M = {}

local classCache = {}
local structCache = {}
local uevrCallbacks = {}
local keyBindList = {}
local usingLuaVR = false

function register_key_bind(keyName, callbackFunc)
	keyBindList[keyName] = {}
	keyBindList[keyName].func = callbackFunc
	keyBindList[keyName].isPressed = false
	print("Registered key bind for ", keyName)
end

function unregister_key_bind(keyName)
	keyBindList[keyName] = nil
	print("Unregistered key bind for ", keyName)
end

local function updateKeyPress()
	local pc = uevr.api:get_player_controller(0)
	local keyStruct = M.get_reuseable_struct_object("ScriptStruct /Script/InputCore.Key")
	for key, elem in pairs(keyBindList) do
		keyStruct.KeyName = M.fname_from_string(key)
		if pc:IsInputKeyDown(keyStruct) then
			if elem.isPressed == false then
				elem.func()
				elem.isPressed = true
			end	
		else
			elem.isPressed = false
		end
	end
end

local delayList = {}
function setTimeout(msec, func)
	table.insert(delayList, {countDown = msec/1000, func = func})
end
function M.setTimeout(msec, func)
	setTimeout(msec, func)
end
function delay(msec, func)
	setTimeout(msec, func)
end
function M.delay(msec, func)
	setTimeout(msec, func)
end

local function updateDelay(delta)
	for i = #delayList, 1, -1 do
		delayList[i]["countDown"] = delayList[i]["countDown"] - delta
		if delayList[i]["countDown"] < 0 then
			if delayList[i]["func"] ~= nil then
				delayList[i]["func"]()
			end
			table.remove(delayList, i)
		end
	end
end

local timerList = {}
function setInterval(msec, func)
	table.insert(timerList, {period = msec/1000, countDown = msec/1000, func = func})
end
function M.setInterval(msec, func)
	setInterval(msec, func)
end

local function updateTimer(delta)
	for i = #timerList, 1, -1 do
		timerList[i]["countDown"] = timerList[i]["countDown"] - delta
		if timerList[i]["countDown"] < 0 then
			if timerList[i]["func"] ~= nil then
				timerList[i]["func"]()
			end
			timerList[i]["countDown"] = timerList[i]["countDown"] + timerList[i]["period"]
		end
	end
end

local lerpList = {}
function M.lerp(lerpID, startAlpha, endAlpha, duration, userdata, callback)
	if lerpList[lerpID] ~= nil then
		lerpList[lerpID]:update(startAlpha, endAlpha, duration, userdata)
	else
		local lerp = coreLerp.new(startAlpha, endAlpha, duration, userdata, callback)
		lerp:start()
		lerpList[lerpID] = lerp
		--print("Created lerp\n")
	end
end
local function updateLerp(delta)
	local cleanup = {}
	for id, lerp in pairs(lerpList) do
		lerp:tick(delta)
		if lerp:isFinished() then table.insert(cleanup, id) end		
	end
	for i = 1, #cleanup do
		lerpList[cleanup[i]] = nil
		--print("Deleted lerp\n")
	end
end

-- function delay(seconds, func)
  -- local co = coroutine.create(function()
    -- local start = os.time()
    -- while os.time() - start < seconds do
      -- coroutine.yield()
    -- end
    -- func()
  -- end)

  -- while coroutine.status(co) ~= "dead" do
    -- coroutine.resume(co)
  -- end
-- end

local lazyElapsedTime = 0.0
local lazyPollTime = 1.0
local function updateLazyPoll(delta)
	if on_lazy_poll ~= nil then
		lazyElapsedTime = lazyElapsedTime + delta
		if lazyElapsedTime > lazyPollTime then
			on_lazy_poll()
			lazyElapsedTime = 0
		end
	end 
end

local function registerUEVRCallback(callbackName, callbackFunc)
	if uevrCallbacks[callbackName] == nil then uevrCallbacks[callbackName] = {} end
	for i, existingFunc in ipairs(uevrCallbacks[callbackName]) do
		if existingFunc == callbackFunc then
			--print("Function already exists")
			return
		end
	end
	table.insert(uevrCallbacks[callbackName], callbackFunc)
end

local function executeUEVRCallbacks(callbackName, ...)
	if uevrCallbacks[callbackName] ~= nil then
		for i, func in ipairs(uevrCallbacks[callbackName]) do
			func(table.unpack({...}))
		end
	end
end

local function getCurrentLevel()
	local world = M.get_world()
	if world ~= nil then
		return world.PersistentLevel
	end
	return nil
end

local function updateCurrentLevel()
	local level = getCurrentLevel()
	if lastLevel ~= level then
		executeUEVRCallbacks("on_level_change", level)
		if on_level_change ~= nil then
			on_level_change(level)
		end
	end	
	lastLevel = level
end


local isInitialized = false
function M.initUEVR(UEVR, callbackFunc)
	if isInitialized == true then 
		if callbackFunc ~= nil then
			callbackFunc()
		end
		return 
	end
	isInitialized = true
	
	if UEVR == nil then
		UEVR = require("LuaVR")
		usingLuaVR = true
	end

	uevr = UEVR
	local params = uevr.params
	M.print("UEVR loaded " .. tostring(params.version.major) .. "." .. tostring(params.version.minor) .. "." .. tostring(params.version.patch))
	
	pawn = uevr.api:get_local_pawn(0)

	temp_vec3 = Vector3d.new(0, 0, 0)
	temp_vec3f = Vector3f.new(0, 0, 0)
	temp_quatf = Quaternionf.new(0, 0, 0, 0)
	
	kismet_system_library = M.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
	kismet_math_library = M.find_default_instance("Class /Script/Engine.KismetMathLibrary")
	kismet_string_library = M.find_default_instance("Class /Script/Engine.KismetStringLibrary")
	kismet_rendering_library = M.find_default_instance("Class /Script/Engine.KismetRenderingLibrary")
	Statics = M.find_default_instance("Class /Script/Engine.GameplayStatics")
	WidgetBlueprintLibrary = M.find_default_instance("Class /Script/UMG.WidgetBlueprintLibrary")
	
	game_engine = M.find_first_of("Class /Script/Engine.GameEngine")
	
	static_mesh_component_c = M.get_class("Class /Script/Engine.StaticMeshComponent")
	motion_controller_component_c = M.get_class("Class /Script/HeadMountedDisplay.MotionControllerComponent")			 
	scene_component_c = M.get_class("Class /Script/Engine.SceneComponent")
	actor_c = M.get_class("Class /Script/Engine.Actor")
	
	zero_color = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")
	reusable_hit_result = M.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
	temp_transform = M.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.Transform")
	
	uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
		if on_xinput_get_state ~= nil then
			on_xinput_get_state(retval, user_index, state)
		end
		
		executeUEVRCallbacks("onInputGetState", retval, user_index, state)
	end)

	uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
		if on_pre_calculate_stereo_view_offset ~= nil then
			on_pre_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
		end
		
		executeUEVRCallbacks("preCalculateStereoView", device, view_index, world_to_meters, position, rotation, is_double)
	end)

	uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
		local success, response = pcall(function()		
			if on_post_calculate_stereo_view_offset ~= nil then
				on_post_calculate_stereo_view_offset(device, view_index, world_to_meters, position, rotation, is_double)
			end
			
			executeUEVRCallbacks("postCalculateStereoView", device, view_index, world_to_meters, position, rotation, is_double)
		end)
		-- if success == false then
			-- M.print("[on_pre_engine_tick] " .. response, LogLevel.Error)
		-- end
	end)

	uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
		local success, response = pcall(function()		
			pawn = uevr.api:get_local_pawn(0)
			updateCurrentLevel()
			updateDelay(delta)
			updateTimer(delta)
			updateLazyPoll(delta)
			updateKeyPress()
			updateLerp(delta)
			if on_pre_engine_tick ~= nil then
				on_pre_engine_tick(engine, delta)
			end
			
			executeUEVRCallbacks("preEngineTick", engine, delta)
		end)
		-- if success == false then
			-- M.print("[on_pre_engine_tick] " .. response, LogLevel.Error)
		-- end
	end)

	uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
		if on_post_engine_tick ~= nil then
			on_post_engine_tick(engine, delta)
		end
			
		executeUEVRCallbacks("postEngineTick", engine, delta)
	end)
	
	if callbackFunc ~= nil then
		callbackFunc()
	end

	if UEVRReady ~= nil then UEVRReady(uevr) end
end

local currentLogLevel = LogLevel.Error
local logToFile = false
function M.enableDebug(val)
	currentLogLevel = val and LogLevel.Debug or LogLevel.Off
end

function M.setLogLevel(val)
	currentLogLevel = val
end

function M.setLogToFile(val)
	logToFile = val
end

function M.print(str, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if type(str) == "string" then
		if logLevel <= currentLogLevel then
			print("[" .. LogLevelString[logLevel] .. "] " .. str .. (usingLuaVR and "\n" or ""))
			if logToFile then
				if logLevel == LogLevel.Error or logLevel == LogLevel.Critical then
					uevr.params.functions.log_error("[" .. LogLevelString[logLevel] .. "] " .. str)
				elseif logLevel == LogLevel.Warning then
					uevr.params.functions.log_warning("[" .. LogLevelString[logLevel] .. "] " .. str)
				else
					uevr.params.functions.log_info("[" .. LogLevelString[logLevel] .. "] " .. str)
				end
			end
		end
	else
		print("Failed to print a non-string" .. (usingLuaVR and "\n" or ""))
	end
end

function M.registerOnInputGetStateCallback(func)
	registerUEVRCallback("onInputGetState", func)
end

function M.registerPreEngineTickCallback(func)
	registerUEVRCallback("preEngineTick", func)
end

function M.registerPostEngineTickCallback(func)
	registerUEVRCallback("postEngineTick", func)
end

function M.registerPreCalculateStereoViewCallback(func)
	registerUEVRCallback("preCalculateStereoView", func)
end

function M.registerPostCalculateStereoViewCallback(func)
	registerUEVRCallback("postCalculateStereoView", func)
end

function M.registerLevelChangeCallback(func)
	registerUEVRCallback("on_level_change", func)
end

function vector_2(x, y, reuseable)
	local vector = M.get_struct_object("ScriptStruct /Script/CoreUObject.Vector2D", reuseable)
	if vector ~= nil then
		vector.X = x
		vector.Y = y
	end
	return vector
end
function M.vector_2(x, y, reuseable)
	return vector_2(x, y, reuseable)
end

function vector_3(x, y, z)
	temp_vec3:set(x, y, z)
	return temp_vec3
end
function M.vector_3(x, y, z)
	return vector_3(x, y, z)
end

function vector_3f(x, y, z)
	temp_vec3f:set(x, y, z)
	return temp_vec3f
end
function M.vector_3f(x, y, z)
	return vector_3f(x, y, z)
end

function quatf(x, y, z, w)
	temp_quatf:set(x, y, z, w)
	return temp_quatf
end
function M.quatf(x, y, z, w)
	return quatf(x, y, z, w)
end

--function M.vector(x, y, z, reuseable)
function M.vector(...)
    local arg = {...}
	local x=0.0
	local y=0.0
	local z=0.0
	local reuseable = false

	if #arg == 1 or #arg == 2 then
		if type(arg[1]) == "userdata" then --maybe a vector was sent in
			--if arg[1]:is_a(M.get_class("ScriptStruct /Script/CoreUObject.Vector")) then
			return arg[1]
		elseif type(arg[1]) == "table" then
			x = (arg[1].X ~= nil) and arg[1].X or ((arg[1].x ~= nil) and arg[1].x or ((#arg[1] > 0) and arg[1][1]))
			y = (arg[1].Y ~= nil) and arg[1].Y or ((arg[1].y ~= nil) and arg[1].y or ((#arg[1] > 1) and arg[1][2]))
			z = (arg[1].Z ~= nil) and arg[1].Z or ((arg[1].z ~= nil) and arg[1].z or ((#arg[1] > 2) and arg[1][3]))
		else
			M.print("Invalid argument 1 passed to vector function", LogLevel.Warning)
		end
		
		if #arg == 2 then
			if type(arg[2]) == "boolean" then
				reuseable = arg[2]
			else
				M.print("Invalid argument 2 passed to vector function", LogLevel.Warning)
			end
		end
	elseif #arg == 3 or #arg == 4 then
		if type(arg[1]) == "number" then x = arg[1] else M.print("Invalid x value passed to vector function", LogLevel.Warning) end
		if type(arg[2]) == "number" then y = arg[2] else M.print("Invalid y value passed to vector function", LogLevel.Warning) end
		if type(arg[3]) == "number" then z = arg[3] else M.print("Invalid z value passed to vector function", LogLevel.Warning) end
		
		if #arg == 4 then
			if type(arg[4]) == "boolean" then
				reuseable = arg[4]
			else
				M.print("Invalid argument 4 passed to vector function", LogLevel.Warning)
			end
		end
	end
			
	local vector = M.get_struct_object("ScriptStruct /Script/CoreUObject.Vector", reuseable)
	if vector ~= nil then
		if vector["X"] ~= nil then vector.X = x else vector.x = x end
		if vector["Y"] ~= nil then vector.Y = y else vector.y = y end
		if vector["Z"] ~= nil then vector.Z = z else vector.z = z end
	end
	return vector
	
	--this should work but doesnt, at least in robocop
	--return kismet_math_library:MakeVector(x, y, z)

end

function M.rotator(...)
    local arg = {...}
	local pitch=0
	local yaw=0
	local roll=0
	local reuseable = false

	if #arg == 1 or #arg == 2 then
		if type(arg[1]) == "userdata" then --maybe a rotator was sent in
			--if arg[1]:is_a(M.get_class("ScriptStruct /Script/CoreUObject.Rotator")) then
			return arg[1]
		elseif type(arg[1]) == "table" then
			pitch = (arg[1].Pitch ~= nil) and arg[1].Pitch or ((arg[1].X ~= nil) and arg[1].X or ((arg[1].x ~= nil) and arg[1].x or ((#arg[1] > 0) and arg[1][1])))
			yaw = (arg[1].Yaw ~= nil) and arg[1].Yaw or ((arg[1].Y ~= nil) and arg[1].Y or ((arg[1].y ~= nil) and arg[1].y or ((#arg[1] > 1) and arg[1][2])))
			roll = (arg[1].Roll ~= nil) and arg[1].Roll or ((arg[1].Z ~= nil) and arg[1].Z or ((arg[1].z ~= nil) and arg[1].z or ((#arg[1] > 2) and arg[1][3])))
		else
			M.print("Invalid argument 1 passed to rotator function", LogLevel.Warning)
		end
		
		if #arg == 2 then
			if type(arg[2]) == "boolean" then
				reuseable = arg[2]
			else
				M.print("Invalid argument 2 passed to rotator function", LogLevel.Warning)
			end
		end
	elseif #arg == 3 or #arg == 4 then
		if type(arg[1]) == "number" then pitch = arg[1] else M.print("Invalid pitch value passed to rotator function", LogLevel.Warning) end
		if type(arg[2]) == "number" then yaw = arg[2] else M.print("Invalid yaw value passed to rotator function", LogLevel.Warning) end
		if type(arg[3]) == "number" then roll = arg[3] else M.print("Invalid roll value passed to rotator function", LogLevel.Warning) end
		
		if #arg == 4 then
			if type(arg[4]) == "boolean" then
				reuseable = arg[4]
			else
				M.print("Invalid argument 4 passed to vector function", LogLevel.Warning)
			end
		end
	end

	-- local rotator = M.get_struct_object("ScriptStruct /Script/CoreUObject.Rotator", reuseable)
	-- if rotator ~= nil then
		-- if rotator["Pitch"] ~= nil then rotator.Pitch = pitch else rotator.pitch = pitch end
		-- if rotator["Yaw"] ~= nil then rotator.Yaw = yaw else rotator.yaw = yaw end
		-- if rotator["Roll"] ~= nil then rotator.Roll = roll else rotator.roll = roll end
	-- end
	-- return rotator
	return kismet_math_library:MakeRotator(roll, pitch, yaw)
end

function M.rotatorFromQuat(x, y, z, w)
	return kismet_math_library:Quat_Rotator(M.quat(x, y, z, w))
end

function M.quat(x, y, z, w, reuseable)
	local quat = M.get_struct_object("ScriptStruct /Script/CoreUObject.Quat", reuseable)
	if quat ~= nil then
		kismet_math_library:Quat_SetComponents(quat, x, y, z, w)
	end
	return quat
end

-- function M.sumRotators(...) --BreakRotator doesnt work in robocop UB
    -- local arg = {...}
	-- local rollTotal,pitchTotal,yawTotal = 0,0,0
	-- for i = 1, #arg do
		-- local roll,pitch,yaw = 0,0,0
		-- kismet_math_library:BreakRotator(arg[i], roll, pitch, yaw) 
		-- print("here", roll, pitch, yaw)
		-- rollTotal = rollTotal + roll
		-- pitchTotal = pitchTotal + pitch
		-- yawTotal = yawTotal + yaw
	-- end
	-- return kismet_math_library:MakeRotator(rollTotal, pitchTotal, yawTotal)
-- end

function M.sumRotators(...)
    local arg = {...}
	local rollTotal,pitchTotal,yawTotal = 0,0,0
	if arg ~= nil then
		for i = 1, #arg do
			if arg[i] ~= nil then
				if arg[i]["Pitch"] ~= nil then pitchTotal = pitchTotal + arg[i]["Pitch"] else pitchTotal = pitchTotal + arg[i]["pitch"] end
				if arg[i]["Yaw"] ~= nil then yawTotal = yawTotal + arg[i]["Yaw"] else yawTotal = yawTotal + arg[i]["yaw"] end
				if arg[i]["Roll"] ~= nil then rollTotal = rollTotal + arg[i]["Roll"] else rollTotal = rollTotal + arg[i]["roll"] end
			end
		end
	end
	return kismet_math_library:MakeRotator(rollTotal, pitchTotal, yawTotal)
end

function M.get_transform(position, rotation, scale, reuseable)
	if position == nil then position = {X=0.0, Y=0.0, Z=0.0} end 
	if scale == nil then scale = {X=1.0, Y=1.0, Z=1.0} end
	local transform = M.get_struct_object("ScriptStruct /Script/CoreUObject.Transform", reuseable)
	transform.Translation = vector_3f(position.X, position.Y, position.Z)
	if rotation == nil then
		transform.Rotation.X = 0.0
		transform.Rotation.Y = 0.0
		transform.Rotation.Z = 0.0
		transform.Rotation.W = 1.0
	else
		transform.Rotation = rotation
	end
	transform.Scale3D = vector_3f(scale.X, scale.Y, scale.Z)
	return transform
end

function M.set_component_relative_location(component, position)
	if component ~= nil and component.RelativeLocation ~= nil then
		if position == nil then position = {X=0.0, Y=0.0, Z=0.0} else position = M.vector(position) end 
		component.RelativeLocation.X = position.X
		component.RelativeLocation.Y = position.Y
		component.RelativeLocation.Z = position.Z
	end
end

function M.set_component_relative_rotation(component, rotation)
	if component ~= nil and component.RelativeRotation ~= nil then
		if rotation == nil then rotation = {Pitch=0, Yaw=0, Roll=0} else rotation = M.rotator(rotation)  end
		component.RelativeRotation.Pitch = rotation.Pitch
		component.RelativeRotation.Yaw = rotation.Yaw
		component.RelativeRotation.Roll = rotation.Roll
	end
end

function M.set_component_relative_scale(component, scale)
	if component ~= nil and component.RelativeScale3D ~= nil then
		if scale == nil then scale = {X=1.0, Y=1.0, Z=1.0} else scale = M.vector(scale) end
		component.RelativeScale3D.X = scale.X
		component.RelativeScale3D.Y = scale.Y
		component.RelativeScale3D.Z = scale.Z
	end
end

function M.set_component_relative_transform(component, position, rotation, scale)
	M.set_component_relative_location(component, position)
	M.set_component_relative_rotation(component, rotation)
	M.set_component_relative_scale(component, scale)
end

function M.getUEVRParam_bool(paramName)
	local param = uevr.params.vr:get_mod_value(paramName)
	if param ~= nil then
		if string.sub(param, 1, 4 ) == "true" then return true else return false end
	else
		M.print("Invalid paramName in getUEVRParam_bool", LogLevel.Error)
	end
	return false
end

function M.getUEVRParam_int(paramName, default)
	local result = nil
	local param = uevr.params.vr:get_mod_value(paramName)
	if param ~= nil then 
		result = math.tointeger(param:gsub("[^%-%d]", ""))
	else
		M.print("Invalid paramName in getUEVRParam_int", LogLevel.Error)
	end
	if result == nil then result = default end
	return result
end


function M.PositiveIntegerMask(text)
    return text:gsub("[^%-%d]", "")
end

function M.get_reuseable_struct_object(structClassName)
	if structCache[structClassName] == nil then
		local class = M.get_class(structClassName)
		if class ~= nil then
			structCache[structClassName] = StructObject.new(class)
		end
	end
	return structCache[structClassName]
end

function M.get_struct_object(structClassName, reuseable)
	if reuseable == true then
		return M.get_reuseable_struct_object(structClassName)
	end
	local class = M.get_class(structClassName)
	if class ~= nil then
		return StructObject.new(class)
	end
	return nil
end

function M.get_world()
	if game_engine ~= nil then
		viewport = game_engine.GameViewport	
		if viewport ~= nil then
			local world = viewport.World
			return world
		end
	end
	return nil
end


function M.spawn_actor(transform, collisionMethod, owner, tag)
	viewport = game_engine.GameViewport
	if viewport == nil then
		print("Viewport is nil")
	end

	worldContext = viewport.World
	if worldContext == nil then
		print("World is nil")
	end

	if transform == nil then
		transform = M.get_transform()
	end

    local actor = Statics:BeginDeferredActorSpawnFromClass(worldContext, actor_c, transform, collisionMethod, owner)

    if actor == nil then
		print("Failed to spawn actor")
        return nil
    end

    Statics:FinishSpawningActor(actor, transform)
	
	-- print("Tags ",actor.Tags)
	-- if actor.Tags == nil then actor.Tags = {} end
	-- print("Tags before",#actor.Tags)
	-- if tag ~= nil then
		-- actor.Tags[#actor.Tags + 1] = M.fname_from_string(tag)
		-- print("Tag added", actor.Tags[#actor.Tags])
	-- end
	-- print("Tags after",#actor.Tags)
	
    return actor
end

function M.getAllActorsWithTag(tag)
	local actors = {}
	Statics:GetAllActorsWithTag(M.get_world(), M.fname_from_string(tag), actors)
	print("getAllActorWithTag",#actors)
	return actors
end

function M.getAllActorsOfClassWithTag(className, tag)
	local actors = {}
	local class = M.get_class(className)
	if class ~= nil then
		Statics:GetAllActorsOfClassWithTag(M.get_world(), class, M.fname_from_string(tag), actors)
	end
	print("getAllActorWithTag",#actors)
	return actors
end

function M.getAllActorsOfClass(className)
	local actors = {}
	local class = M.get_class(className)
	if class ~= nil then
		Statics:GetAllActorsOfClass(M.get_world(), class, M.fname_from_string(tag), actors)
	end
	print("getAllActorWithTag",#actors)
	return actors
end

--coutesy of Pande4360
function M.validate_object(object)
    if object == nil or not UEVR_UObjectHook.exists(object) then
        return nil
    else
        return object
    end
end

function M.getValid(object, properties)
	if M.validate_object(object) ~= nil then
		if properties ~= nil then
			for i = 1 , #properties do
				object = object[properties[i]]
				if M.validate_object(object) == nil then
					return nil
				end
			end	
			return object
		else
			return object
		end
	else
		return nil
	end
end

function M.destroy_actor(actor)
	if actor ~= nil then
		pcall(function()
			if actor.K2_DestroyActor ~= nil then
				actor:K2_DestroyActor()
				print("Actor destroyed\n")
			end
		end)	
	end
end

function M.spawn_object(objClassName, outer)
	local objClass = M.find_required_object(objClassName) --Class /Script/Engine.StaticMeshSocket
--	UObject* Statics:SpawnObject(UClass* ObjectClass, class UObject* Outer)
	if objClass ~= nil then
		return Statics:SpawnObject(objClass, outer)
	end
	return nil
end

-- namespace EAttachLocation {
    -- enum Type {
        -- KeepRelativeOffset = 0,
        -- KeepWorldPosition = 1,
        -- SnapToTarget = 2,
        -- SnapToTargetIncludingScale = 3,
        -- EAttachLocation_MAX = 4,
    -- };
-- }
function M.create_component_of_class(class, manualAttachment, relativeTransform, deferredFinish, parent, tag)
	if type(class) == "string" then class = M.get_class(class) end
	if manualAttachment == nil then manualAttachment = true end
	if relativeTransform == nil then relativeTransform = M.get_transform() end
	if deferredFinish == nil then deferredFinish = false end
	local baseActor = parent
	if baseActor == nil or baseActor.AddComponentByClass == nil then baseActor = M.spawn_actor( nil, 1, nil, tag) end
	local component = baseActor:AddComponentByClass(class, manualAttachment, relativeTransform, deferredFinish)
	component:SetVisibility(true)
	component:SetHiddenInGame(false)
	if component.SetCollisionEnabled ~= nil then
		component:SetCollisionEnabled(0, false)	
	end
	return component
end

function M.find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

--uses caching
function M.get_class(name, clearCache)
	if clearCache or classCache[name] == nil then
		classCache[name] = uevr.api:find_uobject(name)
	end
    return classCache[name]
end

function M.find_default_instance(className)
	local class =  M.get_class(className)
	if class ~= nil and class.get_first_object_matching ~= nil then
		return class:get_class_default_object()
	end
	return nil
end

function M.find_first_instance(className, includeDefault)
	local class =  M.get_class(className)
	if class ~= nil and class.get_first_object_matching ~= nil then
		return class:get_first_object_matching(includeDefault)
	end
	return nil
end

function M.find_all_instances(className, includeDefault)
	local class =  M.get_class(className)
	if class ~= nil and class.get_first_object_matching ~= nil then
		return class:get_objects_matching(includeDefault)
	end
	return nil
end

function M.find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  M.get_class(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function M.find_all_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  M.get_class(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_objects_by_class(class, includeDefault)
	end
	return {}
end

function splitOnLastPeriod(input)
    local lastPeriodIndex = input:match(".*()%.") -- Find the last period's position
    if not lastPeriodIndex then
        return input, nil -- No period found
    end
    local beforePeriod = input:sub(1, lastPeriodIndex - 1)
    local afterPeriod = input:sub(lastPeriodIndex + 1)
    return beforePeriod, afterPeriod
end

function M.find_instance_of(className, objectName)
	--check if the objectName is a short name
	local isShortName = string.find(objectName, '.', 1, true) == nil
	local instances = M.find_all_of(className, true)
	for i, instance in ipairs(instances) do
		if isShortName then
			local before, after = splitOnLastPeriod(instance:get_full_name())
			if after ~= nil and after == objectName then
				return instance
			end
		else
			if instance:get_full_name() == objectName then
				return instance
			end
		end
	end
	return nil
end

function M.fname_from_string(str)
	if str == nil then str = "" end
	return kismet_string_library:Conv_StringToName(str)
end

-- float values from 0.0 to 1.0
function color_from_rgba(r,g,b,a, reuseable)
	local color = M.get_struct_object("ScriptStruct /Script/CoreUObject.LinearColor", reuseable) --StructObject.new(M.get_class("ScriptStruct /Script/CoreUObject.LinearColor"))
	--zero_color = StructObject.new(color_c)
	if color["R"] ~= nil then color.R = r else color.r = r end
	if color["G"] ~= nil then color.G = g else color.g = g end
	if color["B"] ~= nil then color.B = b else color.b = b end
	if color["A"] ~= nil then color.A = a else color.a = a end
	return color
end
function M.color_from_rgba(r,g,b,a, reuseable)
	return color_from_rgba(r,g,b,a, reuseable)
end
-- int values from 0 to 255
function color_from_rgba_int(r,g,b,a, reuseable)
	local color = M.get_struct_object("ScriptStruct /Script/CoreUObject.Color", reuseable) --StructObject.new(M.get_class("ScriptStruct /Script/CoreUObject.Color"))
	color.R = r
	color.G = g
	if color["B"] == nil then
		color.b = b
	else
		color.B = b
	end
	color.A = a
	return color
end
function M.color_from_rgba_int(r,g,b,a, reuseable)
	return color_from_rgba_int(r,g,b,a, reuseable)
end

function M.splitStr(inputstr, sep)
   if sep == nil then
      sep = '%s'
   end
   local t={}
   for str in string.gmatch(inputstr, '([^'..sep..']+)') 
   do
     table.insert(t, str)
   end
   return t
end


function M.isButtonPressed(state, button)
    return state.Gamepad.wButtons & button ~= 0
end
function M.isButtonNotPressed(state, button)
    return state.Gamepad.wButtons & button == 0
end
function M.pressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function M.unpressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end
function M.isThumbpadTouched(state, hand)
    local thumbpad = hand == Handed.Right and uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchRight") or uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchLeft")
	local controller = hand == Handed.Right and uevr.params.vr.get_right_joystick_source() or uevr.params.vr.get_left_joystick_source()
	return uevr.params.vr.is_action_active(thumbpad, controller)
end
function M.triggerHapticVibration(hand, secondsFromNow, duration, frequency, amplitude)
	if hand == nil then hand = Handed.Right end
	if secondsFromNow == nil then secondsFromNow = 0 end
	if duration == nil then duration = .05 end
	if frequency == nil then frequency = 1000.0 end
	if amplitude == nil then amplitude = 1.0 end
	local controller = hand == Handed.Right and uevr.params.vr.get_right_joystick_source() or uevr.params.vr.get_left_joystick_source()
	uevr.params.vr.trigger_haptic_vibration(secondsFromNow, duration, frequency, amplitude, controller)
end

-- if isButtonPressed(state, XINPUT_GAMEPAD_X) then
    -- unpressButton(state, XINPUT_GAMEPAD_X)
    -- pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
-- end

local fadeHardLock = false
local fadeSoftLock = false
function M.isFadeHardLocked()
	return fadeHardLock
end
function M.fadeCamera(rate, hardLock, softLock, overrideHardLock, overrideSoftLock)
	--print("fadeCamera called", rate, hardLock, softLock, overrideHardLock, overrideSoftLock, fadeHardLock, fadeSoftLock, "\n")

	if hardLock == nil then hardLock = false end
	if softLock == nil then softLock = false end
	if overrideLocks == nil then overrideLocks = false end
	if overrideHardLock == nil then overrideHardLock = false end
	if overrideSoftLock == nil then overrideSoftLock = false end
	
	if overrideHardLock then
		fadeHardLock = false
	end
	if overrideSoftLock then
		fadeSoftLock = false
	end
	
	if fadeSoftLock or fadeHardLock then
		return
	end
	
	fadeHardLock = hardLock
	fadeSoftLock = softLock	
	--print("fadeCamera executed",rate,"\n")

	local camMan = M.find_first_of("Class /Script/Engine.PlayerCameraManager")
	--print("Camera Manager was",camMan:get_full_name(),"\n")
	if uevr ~= nil and camMan ~= nil and UEVR_UObjectHook.exists(camMan) then
		--(FromAlpha, ToAlpha, Duration, Color, bShouldFadeAudio, bHoldWhenFinished)
		camMan:StartCameraFade(0.999, 1.0, rate, color_from_rgba(0.0, 0.0, 0.0, 1.0), false, fadeHardLock)
		
		--pc:ClientSetCameraFade(bool bEnableFading, _Script_CoreUObject::Color FadeColor, _Script_CoreUObject::Vector2D FadeAlpha, float FadeTime, bool bFadeAudio, bool bHoldWhenFinished)
		if fadeSoftLock then
			delay(math.floor(rate * 1000), function()
				fadeSoftLock = false
			end)	
		end
	end
	-- end
	-- local obj_class = api:find_uobject("Class /Script/Engine.PlayerCameraManager")
    -- if obj_class == nil then 
		-- print("Class /Script/Engine.PlayerCameraManager not found") 
		-- return
	-- end

    -- local obj_instances = obj_class:get_objects_matching(false)
    -- for i, instance in ipairs(obj_instances) do
		-- instance:StartCameraFade(0.999, 1.0, rate, color_from_rgba(0.0, 0.0, 0.0, 1.0), false, fadeHardLock)
		-- print("Camera Manager ",i,instance:get_full_name(),fadeHardLock,"\n")
	-- end

	-- if fadeSoftLock then
		-- delay(math.floor(rate * 1000), function()
			-- fadeSoftLock = false
		-- end)	
	-- end

end

function M.stopFadeCamera()
	local camMan = M.find_first_of("Class /Script/Engine.PlayerCameraManager")
	--print("Camera Manager was",camMan:get_full_name(),"\n")
	
	if uevr ~= nil and camMan ~= nil and UEVR_UObjectHook.exists(camMan) then
		--(FromAlpha, ToAlpha, Duration, Color, bShouldFadeAudio, bHoldWhenFinished)
		camMan:StopCameraFade()
		--camMan:SetManualCameraFade(1, color_from_rgba(0.0, 0.0, 0.0, 0.0), false)
		print("stopFadeCamera executed\n")
	end
	fadeHardLock = false
	fadeSoftLock = false
end

function M.set_2D_mode(state, delay_msec)
    if uevr ~= nil and uevr.params ~= nil then
		local mode = uevr.params.vr:get_mod_value("VR_2DScreenMode")
		if state and (string.sub(mode, 1, 5 ) == "false") then
			if delay_msec == nil then
				uevr.params.vr.set_mod_value("VR_2DScreenMode", "true")
				print("2D mode set immediate\n")
			else
				delay( delay_msec, function()
					uevr.params.vr.set_mod_value("VR_2DScreenMode", "true")
					print("2D mode set\n")
				end)
			end
		end
		if (not state) and (string.sub(mode, 1, 4 ) == "true") then
			if delay_msec == nil then
				uevr.params.vr.set_mod_value("VR_2DScreenMode", "false")
				print("3D mode set immediate\n")
			else
				delay( delay_msec, function()
					uevr.params.vr.set_mod_value("VR_2DScreenMode", "false") --do not execute in game thread
					print("3D mode set\n")
				end)
			end
		end
	end
end

--there should be a better way to do this with the asset registry
function M.getAssetDataFromPath(pathStr)
	local fAssetData = M.get_struct_object("ScriptStruct /Script/CoreUObject.AssetData")
	local arr = M.splitStr(pathStr, " ")
	if fAssetData.ObjectPath ~= nil then
		fAssetData.AssetClass = M.fname_from_string(arr[1]) 
		fAssetData.ObjectPath = M.fname_from_string(arr[2])
	end
	if fAssetData.AssetClassPath ~= nil then
		fAssetData.AssetClassPath.PackageName = M.fname_from_string("/Script/Engine")
		fAssetData.AssetClassPath.AssetName = M.fname_from_string(arr[1]) 
	end
	arr = M.splitStr(arr[2], "/")
	local arr2 = M.splitStr(arr[#arr], ".")
	fAssetData.AssetName = M.fname_from_string(arr2[2])
	local packagePath = table.concat(arr, "/", 1, #arr - 1)
	fAssetData.PackagePath = "/" .. packagePath
	fAssetData.PackageName = "/" .. packagePath .. "/" .. arr2[1]
	return fAssetData
end

function M.getLoadedAsset(pathStr)
	local fAssetData = M.getAssetDataFromPath(pathStr)
	local assetRegistryHelper = M.find_first_of("Class /Script/AssetRegistry.AssetRegistryHelpers",  true)
	if not assetRegistryHelper:IsAssetLoaded(fAssetData) then
		local fSoftObjectPath = assetRegistryHelper:ToSoftObjectPath(fAssetData);
		kismet_system_library:LoadAsset_Blocking(fSoftObjectPath)
	end
	
	return assetRegistryHelper:GetAsset(fAssetData) 
end

function M.copyMaterials(fromComponent, toComponent, showDebug)
	if fromComponent ~= nil and toComponent ~= nil then
		local materials = fromComponent:GetMaterials()
		if materials ~= nil then
			if showDebug == true then M.print("Copying materials. Found " .. #materials .. " materials on fromComponent") end
			for i = 1 , #materials do
				toComponent:SetMaterial(i - 1, materials[i])
				if showDebug == true then M.print("Material index " .. i .. ": " .. materials[i]:get_full_name()) end
			end
		end
	end
end

function M.getChildComponent(parent, name)
	local childComponent = nil
	if M.validate_object(parent) ~= nil and name ~= nil then
		local children = parent.AttachChildren
		for i, child in ipairs(children) do
			if  string.find(child:get_full_name(), name) then
				childComponent = child
			end
		end
	end
	return childComponent
end

function M.destroyComponent(component, destroyOwner, destroyChildren)
	print("destroyComponent called on ", component )
	if M.validate_object(component) ~= nil then
		local success, response = pcall(function()
			local name = component:get_full_name()
			M.print("[destroyComponent] destroyComponent called for " .. name)
			
			if destroyChildren == true then
				local children = component.AttachChildren
				if children ~= nil then
					M.print("[destroyComponent] Found " .. #children .. " children")
					for i = #children, 1, -1 do
						M.destroyComponent(children[i], destroyOwner, destroyChildren)
					end
				else
					print("[destroyComponent] No children found")
				end
			end

			M.print("[destroyComponent] Getting component owner for " ..  name)
			local actor = component:GetOwner()
			if actor ~= nil then
				local actorName = actor:get_full_name()
				M.print("[destroyComponent] Found component owner " .. actorName)
				if actor.K2_DestroyComponent ~= nil then
					actor:K2_DestroyComponent(component)
					M.print("[destroyComponent] Destroyed component " .. name)
				elseif component.K2_DestroyComponent ~= nil then
					component:K2_DestroyComponent(component)
					M.print("[destroyComponent] Destroyed component directly " .. name)
				end
				if destroyOwner == nil then destroyOwner = false end
				if destroyOwner then
					actor:K2_DestroyActor()
					M.print("[destroyComponent] Destroyed component owner " .. actorName .. " for " .. name)
				end
			else
				M.print("[destroyComponent] Component owner not found")
			end
		end)	
		if success == false then
			print("[destroyComponent] pcall fail " .. response, LogLevel.Error)
		end
	end
end

function M.detachAndDestroyComponent(component, destroyOwner, destroyChildren)
	if M.validate_object(component) ~= nil then
		M.print("[detachAndDestroyComponent] Detaching " .. component:get_full_name())
		if component.DetachFromParent ~= nil then
			component:DetachFromParent(true,false)
		end
		M.print("[detachAndDestroyComponent] Component detached")
		M.destroyComponent(component, destroyOwner, destroyChildren)
	end
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, showDebug
function M.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, options)
	if options == nil then options = {} end
	local showDebug = options.showDebug
	if showDebug == true then M.print("Creating PoseableMeshComponent from " .. skeletalMeshComponent:get_full_name()) end
	local poseableComponent = nil
	if skeletalMeshComponent ~= nil then
		if skeletalMeshComponent:is_a(M.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
			poseableComponent = M.create_component_of_class("Class /Script/Engine.PoseableMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			--poseableComponent:SetCollisionEnabled(0, false)
			if poseableComponent ~= nil then
				if showDebug == true then M.print("Created " .. poseableComponent:get_full_name()) end
				poseableComponent.SkeletalMesh = skeletalMeshComponent.SkeletalMesh		
				--force initial update
				if poseableComponent.SetMasterPoseComponent ~= nil then
					poseableComponent:SetMasterPoseComponent(skeletalMeshComponent, true)
					poseableComponent:SetMasterPoseComponent(nil, false)
				elseif poseableComponent.SetLeaderPoseComponent ~= nil then
					poseableComponent:SetLeaderPoseComponent(skeletalMeshComponent, true)
					poseableComponent:SetLeaderPoseComponent(nil, false)
				end
				if showDebug == true then M.print("Master pose updated") end
				
				pcall(function()
					poseableComponent:CopyPoseFromSkeletalComponent(skeletalMeshComponent)	
					if showDebug == true then M.print("Pose copied") end
				end)	
			
				M.copyMaterials(skeletalMeshComponent, poseableComponent, showDebug)
			else 
				M.print("PoseableMeshComponent could not be created")
			end
		else
			M.print("PoseableMeshComponent could not be created because provided component is not a skeletalMeshComponent")
		end
	else
		M.print("PoseableMeshComponent could not be created because provided component is nil")
	end
	return poseableComponent
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, visible, collisionEnabled
function M.createStaticMeshComponent(mesh, options)
	local component = nil
	if mesh ~= nil and (type(mesh) == "string" or mesh:is_a(M.get_class("Class /Script/Engine.StaticMesh"))) then
		if type(mesh) == "string" then
			mesh = M.find_instance_of("Class /Script/Engine.StaticMesh", mesh) 
		end

		if mesh ~= nil then --check mesh again because it changed if it was originally a string
			if options == nil then options = {} end
			component = M.create_component_of_class("Class /Script/Engine.StaticMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				if options.visible ~= nil then
					component:SetVisibility(options.visible)
				end
				if options.collisionEnabled ~= nil and component.SetCollisionEnabled ~= nil then
					component:SetCollisionEnabled(options.collisionEnabled == true and 1 or 0)
				end
				--various ways of finding a StaticMesh
				--local staticMesh = M.find_required_object("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --no caching so performance could suffer
				--local staticMesh = M.get_class("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --has caching but call is ideally meant for classes not other types
				--local staticMesh = M.find_instance_of("Class /Script/Engine.StaticMesh", "Sphere") --easier to specify name unless there is more than one "Sphere"
				--local staticMesh = M.find_instance_of("Class /Script/Engine.StaticMesh", "StaticMesh /Engine/EngineMeshes/Sphere.Sphere") --safest

				component:SetStaticMesh(mesh)
			else
				M.print("StaticMeshComponent creation failed")
			end
		else
			M.print("StaticMeshComponent not created because static mesh could not be created")
		end
	else
		M.print("StaticMeshComponent not created because mesh param is invalid")
	end
	return component
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag
function M.createSkeletalMeshComponent(mesh, options)
	local component = nil
	if mesh ~= nil and (type(mesh) == "string" or mesh:is_a(M.get_class("Class /Script/Engine.SkeletalMesh"))) then
		if type(mesh) == "string" then
			mesh = M.find_instance_of("Class /Script/Engine.SkeletalMesh", mesh) 
		end
		
		if mesh ~= nil then --check mesh again because it changed if it was originally a string
			if options == nil then options = {} end
		
			component = M.create_component_of_class("Class /Script/Engine.SkeletalMeshComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				--component:SetCollisionEnabled(false,false)
				if component.SetSkeletalMesh ~= nil then
					component:SetSkeletalMesh(skeletalMesh)
					--M.print("Using SetSkeletalMesh")
				elseif component.SetSkeletalMeshAsset ~= nil then
					component:SetSkeletalMeshAsset(skeletalMesh)				
					--M.print("Using SetSkeletalMeshAsset")
				else
					M.print("SkeletalMeshComponent SetSkeletalMesh function does not exist")
				end
				--component.SkeletalMesh = skeletalMesh				
			else
				M.print("SkeletalMeshComponent creation failed")
			end
		else
			M.print("SkeletalMeshComponent not created because skeletal mesh could not be created")
		end
	else
		M.print("SkeletalMeshComponent not created because mesh param is invalid")
	end
	return component
end

--options are width, height, format
function M.createRenderTarget2D(options)
     return kismet_rendering_library:CreateRenderTarget2D( M.get_world(), options.width, options.height, options.format, zero_color, false)
end

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, visible, collisionEnabled
function M.createSceneCaptureComponent(options)
	local component = M.create_component_of_class("Class /Script/Engine.SceneCaptureComponent2D", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
	if component ~= nil then
		if options.visible ~= nil then
			component:SetVisibility(options.visible)
		end
		if options.collisionEnabled ~= nil and component.SetCollisionEnabled ~= nil then
			component:SetCollisionEnabled(options.collisionEnabled == true and 1 or 0)
		end
		-- if component["bCacheVolumetricCloudsShadowMaps"] ~= nil then component.bCacheVolumetricCloudsShadowMaps = true end
		-- -- component.bCachedDistanceFields = 1;
		-- component.bUseRayTracingIfEnabled = false;
		-- -- component.PrimitiveRenderMode = 2; -- 0 - legacy, 1 - other
		-- -- component.CaptureSource = 1;
		-- component.bAlwaysPersistRenderingState = true;
		-- if component["bEnableVolumetricCloudsCapture"] ~= nil then component.bEnableVolumetricCloudsCapture = false end
		-- component.bCaptureEveryFrame = 1;

		-- -- post processing
		-- component.PostProcessSettings.bOverride_MotionBlurAmount = true
		-- component.PostProcessSettings.MotionBlurAmount = 0.0 -- Disable motion blur
		-- component.PostProcessSettings.bOverride_ScreenSpaceReflectionIntensity = true
		-- component.PostProcessSettings.ScreenSpaceReflectionIntensity = 0.0 -- Disable screen space reflections
		-- component.PostProcessSettings.bOverride_AmbientOcclusionIntensity = true
		-- component.PostProcessSettings.AmbientOcclusionIntensity = 0.0 -- Disable ambient occlusion
		-- component.PostProcessSettings.bOverride_BloomIntensity = true
		-- component.PostProcessSettings.BloomIntensity = 0.0
		-- component.PostProcessSettings.bOverride_LensFlareIntensity = true
		-- component.PostProcessSettings.LensFlareIntensity = 0.0 -- Disable lens flares
		-- component.PostProcessSettings.bOverride_VignetteIntensity = true
		-- component.PostProcessSettings.VignetteIntensity = 0.0 -- Disable vignette
	else
		print("SceneCaptureComponent not created\n")
	end
	return component
end

function M.getActiveWidgetByClass(className)
	local widgets = M.find_all_instances(className, false)
	if widgets ~= nil and M.getValid(pawn) ~= nil then
		for _, widget in ipairs(widgets) do
			if widget:GetOwningPlayerPawn() == pawn then
				return widget
			end
		end
	end
end

-- local widget = WidgetBlueprintLibrary:Create(uevrUtils.get_world(), uevrUtils.get_class("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C"), playerController)

--options are manualAttachment, relativeTransform, deferredFinish, parent, tag, removeFromViewport, twoSided, drawSize
function M.createWidgetComponent(widget, options)
	local component = nil
	if widget ~= nil and (type(widget) == "string" or widget:is_a(M.get_class("Class /Script/UMG.Widget"))) then
		if type(widget) == "string" then
			widget = M.getActiveWidgetByClass(widget) 
		end
		
		if M.getValid(widget) ~= nil then
			component = M.create_component_of_class("Class /Script/UMG.WidgetComponent", options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
			if component ~= nil then
				if options.removeFromViewport == true and widget.RemoveFromViewport ~= nil then
					widget:RemoveFromViewport()
				end
				component:SetWidget(widget)
				if options.twoSided ~= nil and component.SetTwoSided ~= nil then 
					component:SetTwoSided(options.twoSided)
				end
				if options.drawSize ~= nil and component.SetDrawSize ~= nil then
					component:SetDrawSize(options.drawSize)
				end
				-- component:SetRenderCustomDepth(true)
				-- component:SetCustomDepthStencilValue(100)
				-- component:SetCustomDepthStencilWriteMask(1)
			else
				M.print("WidgetComponent creation failed")
			end			
		else
			M.print("WidgetComponent not created because widget could not be created")
		end
	else
		M.print("WidgetComponent not created because widget param was invalid")	
	end
	return component
end

function M.fixMeshFOV(mesh, propertyName, value, includeChildren, includeNiagara, showDebug)
	local logLevel = showDebug == true and LogLevel.Debug or LogLevel.Ignore
	if M.validate_object(mesh) == nil then
		M.print("Unable to fix mesh FOV, invalid Mesh", LogLevel.Warning)	
	elseif propertyName == nil or propertyName == "" then
		M.print("Unable to fix mesh FOV, invalid property name", LogLevel.Warning)
	else
		local propertyFName = M.fname_from_string(propertyName)	
		if value == nil then value = 0.0 end
		
		local oldValue = nil
		local newValue = nil
		if mesh ~= nil and mesh.GetMaterials ~= nil then
			local materials = mesh:GetMaterials()
			if materials ~= nil then
				if showDebug == true then M.print("Found " .. #materials .. " materials in fixMeshFOV", logLevel) end
				for i, material in ipairs(materials) do
					if material:is_a(M.get_class("Class /Script/Engine.MaterialInstanceConstant")) then
						material = mesh:CreateAndSetMaterialInstanceDynamicFromMaterial(i-1, material)
					end

					if material.SetScalarParameterValue ~= nil then
						if showDebug == true then oldValue = material:K2_GetScalarParameterValue(propertyFName) end
						material:SetScalarParameterValue(propertyFName, value)
						if showDebug == true then
							newValue = material:K2_GetScalarParameterValue(propertyFName)
							M.print("Material: " .. i .. " " .. material:get_full_name() .. " before:" .. oldValue .. " after:" .. newValue, logLevel)
						end
					end
				end
			else
				M.print("No materials found on mesh", logLevel)
			end
			if includeChildren == true then
				children = mesh.AttachChildren
				if children ~= nil then
					for i, child in ipairs(children) do
						if child:is_a(M.get_class("Class /Script/Engine.MeshComponent")) and child.GetMaterials ~= nil then
							local materials = child:GetMaterials()
							if materials ~= nil then
								for i, material in ipairs(materials) do
									if material:is_a(M.get_class("Class /Script/Engine.MaterialInstanceConstant")) then
										material = child:CreateAndSetMaterialInstanceDynamicFromMaterial(i-1, material)
									end
									if material.SetScalarParameterValue ~= nil then
										if showDebug == true then oldValue = material:K2_GetScalarParameterValue(propertyFName) end
										material:SetScalarParameterValue(propertyFName, value)
										if showDebug == true then
											newValue = material:K2_GetScalarParameterValue(propertyFName)
											M.print("Child Material: " .. i .. " " .. material:get_full_name() .. " before:" .. oldValue .. " after:" .. newValue, logLevel)
										end
									end
								end
							end
						end
						
						if includeNiagara == true and child:is_a(M.get_class("Class /Script/Niagara.NiagaraComponent")) then
							child:SetNiagaraVariableFloat(propertyName, value)
							if showDebug == true then M.print("Child Niagara Material: " .. child:get_full_name(),logLevel) end
						end
					end
				end
			end
		end
	end
end


function M.cloneComponent(component, options)
	if options == nil then options = {} end
	local clone = M.create_component_of_class(component:get_class(), options.manualAttachment, options.relativeTransform, options.deferredFinish, options.parent, options.tag)
	if component.SetStaticMesh ~= nil then
		clone:SetStaticMesh(component.StaticMesh)
	elseif component:is_a(M.get_class("Class /Script/Engine.SkeletalMeshComponent")) then
		clone = M.createPoseableMeshFromSkeletalMesh(component, nil)
	end
	-- if component.SetSkeletalMesh ~= nil then
		-- clone:SetSkeletalMesh(component.SkeletalMesh)
		-- M.copyMaterials(component, clone, showDebug)
	-- end
	-- if component.SetSkeletalMeshAsset ~= nil then
		-- clone:SetSkeletalMeshAsset(component.SkeletalMeshAsset)
		-- M.copyMaterials(component, clone, showDebug)
	-- end
	return clone
end

-- Following code is coutesy of markmon 
------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------
function get_cvar_int(cvar)
    local console_manager = uevr.api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        return var:get_int()
    end
end
function M.get_cvar_int(cvar)
	get_cvar_int(cvar)
end
function set_cvar_int(cvar, value)
    local console_manager = uevr.api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_int(value)
    end
end
function M.set_cvar_int(cvar, value)
	set_cvar_int(cvar, value)
end

function set_cvar_float(cvar, value)
    local console_manager = uevr.api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_float(value)
    end
end
function M.set_cvar_float(cvar, value)
	set_cvar_float(cvar, value)
end

-------------------------------------------------------------------------------
-- hook_function
--
-- Hooks a UEVR function. 
--
-- class_name = the class to find, such as "Class /Script.GunfireRuntime.RangedWeapon"
-- function_name = the function to Hook
-- native = true or false whether or not to set the native function flag.
-- prefn = the function to run if you hook pre. Pass nil to not use
-- postfn = the function to run if you hook post. Pass nil to not use.
-- dbgout = true to print the debug outputs, false to not
--
-- Example:
--    hook_function("Class /Script/GunfireRuntime.RangedWeapon", "OnFireBegin", true, nil, gun_firingbegin_hook, true)
--
-- Returns: true on success, false on failure.
-------------------------------------------------------------------------------
function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
	if(dbgout) then M.print("[hook_function] " .. class_name .. "   " .. function_name) end
    local result = false
    local class_obj = uevr.api:find_uobject(class_name)
    if(class_obj ~= nil) then
        if dbgout then M.print("[hook_function] Found class obj for " .. class_name) end
        local class_fn = class_obj:find_function(function_name)
        if(class_fn ~= nil) then 
            if dbgout then M.print("[hook_function] Found function " .. function_name .. " for " .. class_name) end
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then M.print("[hook_function] Set native flag") end
            end
            
            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then M.print("[hook_function] Set function hook for " .. (prefn == nil and "nil" or "pre-function") .. " and " .. (postfn == nil and "nil" or "post-function")) end
        end
    end
    if dbgout then M.print("---") end
    return result
end

-------------------------------------------------------------------------------
-- returns local pawn
-------------------------------------------------------------------------------
function M.get_local_pawn()
	return uevr.api:get_local_pawn(0)
end

-------------------------------------------------------------------------------
-- returns local player controller
-------------------------------------------------------------------------------
function M.get_player_controller()
	return uevr.api:get_player_controller(0)
end

-------------------------------------------------------------------------------
-- Logs to the log.txt
-------------------------------------------------------------------------------
function M.log_info(message)
	uevr.params.functions.log_info(message)
end

-------------------------------------------------------------------------------
-- Print all instance names of a class to debug console
-------------------------------------------------------------------------------
function M.PrintInstanceNames(class_to_search)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then 
		print(class_to_search, "was not found") 
		return
	end

    local obj_instances = obj_class:get_objects_matching(false)

    for i, instance in ipairs(obj_instances) do
		print(i, instance:get_fname():to_string(), mesh:get_full_name())
	end
end

-------------------------------------------------------------------------------
-- Get first instance of a given class object
-------------------------------------------------------------------------------
local function GetFirstInstance(class_to_search)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then 
		print(class_to_search, "was not found") 
		return nil
	end

    return obj_class:get_first_object_matching(false)
end


-------------------------------------------------------------------------------
-- Get class object instance matching string
-------------------------------------------------------------------------------
function M.GetInstanceMatching(class_to_search, match_string)
	local obj_class = uevr.api:find_uobject(class_to_search)
    if obj_class == nil then 
		print(class_to_search, "was not found") 
		return nil
	end

    local obj_instances = obj_class:get_objects_matching(false)

    for i, instance in ipairs(obj_instances) do
        if string.find(instance:get_full_name(), match_string) then
			return instance
		end
	end
end


-------------------------------------------------------------------------------
-- Example hook pre function. Post is same but no return.
-------------------------------------------------------------------------------

-- Note if post, do not return a value. 
-- If hooking as native, must return false.
-- local function HookedFunctionPre(fn, obj, locals, result)
    -- print("Shift beginning : ")
    
    -- return true
-- end

--hook_function("BlueprintGeneratedClass /Game/Reality/BP_ShiftManager.BP_ShiftManager_C", "OnShiftBegin", false, HookedFunctionPre, nil, true)


M.initUEVR(uevr)

return M