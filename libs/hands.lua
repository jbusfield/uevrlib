local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local animation = require("libs/animation")

local M = {}

local handComponents = {}
local handDefinitions = {}
local handBoneList = {} --used for debugging
local offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}
local inputHandlerAnimID = {} --list of animID only used for the default input handler

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[hands] " .. text, logLevel)
	end
end

local function getValidVector(definition, id, default)
	if definition == nil or id == nil or definition[id] == nil then
		return uevrUtils.vector(default[1], default[2], default[3])
	end
	return uevrUtils.vector(definition[id][1], definition[id][2], definition[id][3])
end

local function getValidRotator(definition, id, default)
	if definition == nil or id == nil or definition[id] == nil then
		return uevrUtils.rotator(default[1], default[2], default[3])
	end
	return uevrUtils.rotator(definition[id][1], definition[id][2], definition[id][3])
end

local function getComponentName(componentName)
	local foundName = componentName
	if componentName == nil then --just get the first one
		for name, component in pairs(handComponents) do
			foundName = name
			break
		end
	end
	return foundName == nil and "" or foundName
end

local function getAnimIDSuffix(animID)
	local arr = uevrUtils.splitStr(animID, "_")
	return #arr > 0 and arr[#arr] or nil
end


function M.reset()
	handComponents = {}
	definition = {}
	handBoneList = {}
	offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}
	inputHandlerAnimID = {}
end

function M.exists()
	return M.getHandComponent(Handed.Left) ~= nil or M.getHandComponent(Handed.Right) ~= nil
end

-- if using multiple component like hands and gloves then include componentName or which one is picked will be random
function M.getHandComponent(hand, componentName)
	componentName = getComponentName(componentName)
	if handComponents[componentName] ~= nil then
		return handComponents[componentName][hand]
	end
end 

function M.create(skeletalMeshComponent, definition, handAnimations)
	if definition ~= nil then
		for name, skeletalMeshDefinition in pairs(definition) do
			M.print("Creating hand component: " .. name )
			local component = nil
			if type(skeletalMeshComponent) == "table" then
				component = skeletalMeshComponent[name]
			else
				component = skeletalMeshComponent
			end
			if uevrUtils.validate_object(component) ~= nil then
				handComponents[name] = {}
				for index = 0 , 1 do
					handComponents[name][index] = M.createComponent(component, name, index, skeletalMeshDefinition[index==0 and "Left" or "Right"])
					M.print("Created " .. name .. " component: " .. (index==0 and "Left" or "Right"), LogLevel.Info )
					local animID = skeletalMeshDefinition[index==0 and "Left" or "Right"]["AnimationID"]
					local suffix = getAnimIDSuffix(animID)
					if suffix ~= nil then inputHandlerAnimID[animID] = suffix end
					animation.add(animID, handComponents[name][index], handAnimations)
					animation.initialize(animID, handComponents[name][index])
				end
			else
				M.print("Call to create " .. name .. " failed, invalid skeletalMeshComponent", LogLevel.Info )
			end
		end
		handDefinitions = definition
	else
		M.print("Call to create failed, invalid definiton", LogLevel.Warning )
	end
end

function M.createComponent(skeletalMeshComponent, name, hand, definition)
	local component = nil
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		--not using an existing actor as owner. Mesh affects the hands opacity so its not appropriate
		component = animation.createPoseableComponent(skeletalMeshComponent, nil)
		if component ~= nil then
			--fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
			--a better way to do this should be found
			component.BoundsScale = 16.0
			component.bCastDynamicShadow = false

			controllers.attachComponentToController(hand, component)
			local baseRotation = skeletalMeshComponent.RelativeRotation
			uevrUtils.set_component_relative_transform(component, offset, {Pitch=baseRotation.Pitch+offset.Pitch, Yaw=baseRotation.Yaw+offset.Yaw,Roll=baseRotation.Roll+offset.Roll})	

			if definition ~= nil then
				local jointName = definition["Name"]
				if jointName ~= nil and jointName ~= "" then
					local location = getValidVector(definition, "Location", {0,0,0})
					local rotation = getValidRotator(definition, "Rotation", {0,0,0})
					local scale = getValidVector(definition, "Scale", {1,1,1})
					local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
					animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				else
					M.print("Could not initialize bone in createComponent() because joint name is invalid" )
				end
			end
		end
	else
		M.print("SkeletalMesh component is nil in createComponent()" )
	end
	return component
end


--if, in debug mode, the skeleton is not pointed forward when the wrist is pointed forward then make adjustments with this function
function  M.setOffset(newOffset)
	offset = newOffset
end

function M.addRealism()

end

--set overrideTrigger to true if the default triggers have already been swapped (ie a plugin or code aleady makes the game do right trigger actions when the left trigger is pulled)
function M.handleInput(state, isHoldingWeapon, hand, overrideTrigger)
	if hand == nil then hand = Handed.Right end
	if overrideTrigger == nil then overrideTrigger = false end
	local isRightHanded = hand == Handed.Right
	local weaponHandStr = isRightHanded and "right" or "left"
	local offHandStr = isRightHanded and "left" or "right"
	local animDuration = 0.1
	for id, target in pairs(inputHandlerAnimID) do
		local offhandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bLeftTrigger or state.Gamepad.bRightTrigger
		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_trigger", offhandTriggerValue > 100, {duration=animDuration})

		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_grip", uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_LEFT_SHOULDER or XINPUT_GAMEPAD_RIGHT_SHOULDER), {duration=animDuration})

		local offhandController = uevr.params.vr.get_left_joystick_source() 
		if not isRightHanded then offhandController = uevr.params.vr.get_right_joystick_source() end
		local offhandRest = uevr.params.vr.get_action_handle(isRightHanded and "/actions/default/in/ThumbrestTouchLeft" or "/actions/default/in/ThumbrestTouchRight")    
		animation.updateAnimation(offHandStr.."_"..target, offHandStr.."_thumb", uevr.params.vr.is_action_active(offhandRest, offhandController), {duration=animDuration})

		if not isHoldingWeapon then
			local weaponHandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_trigger", weaponHandTriggerValue > 100, {duration=animDuration})

			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip", uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER), {duration=animDuration})

			local weaponhandController = uevr.params.vr.get_right_joystick_source() 
			if not isRightHanded then weaponhandController = uevr.params.vr.get_left_joystick_source() end
			local weaponhandRest = uevr.params.vr.get_action_handle(isRightHanded and "/actions/default/in/ThumbrestTouchRight" or "/actions/default/in/ThumbrestTouchLeft")  
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_thumb", uevr.params.vr.is_action_active(weaponhandRest, weaponhandController), {duration=animDuration})
		else
			local weaponHandTriggerValue = (isRightHanded or overrideTrigger) and state.Gamepad.bRightTrigger or state.Gamepad.bLeftTrigger
			animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_trigger_weapon", weaponHandTriggerValue > 100, {duration=animDuration})
			if uevrUtils.isButtonPressed(state, isRightHanded and XINPUT_GAMEPAD_RIGHT_SHOULDER or XINPUT_GAMEPAD_LEFT_SHOULDER) then 
				animation.resetAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip_weapon", false) --forces an update regardless of current state
				animation.updateAnimation(weaponHandStr.."_"..target, weaponHandStr.."_grip_weapon", true, {duration=animDuration})
			end
		end
	end
end

function M.hideHands(val)
	for name, components in pairs(handComponents) do
		M.print("Hiding " .. components[0]:get_full_name() .. " hand components", LogLevel.Debug)
		components[0]:SetVisibility(not val, true)	
		components[1]:SetVisibility(not val, true)	
	end
end

function M.destroyHands()
	--since we didnt use an existing actor as parent in createComponent(), destroy the owner actor too
	for name, components in pairs(handComponents) do
		M.print("Destroying " .. name .. " hand components", LogLevel.Debug)
		uevrUtils.detachAndDestroyComponent(components[0], true)	
		uevrUtils.detachAndDestroyComponent(components[1], true)	
	end
end

function M.createSkeletalVisualization(hand, scale, componentName)
	if M.exists() then
		if hand == null then hand = Handed.Right end
		if scale == null then scale = 0.003 end
		animation.createSkeletalVisualization(M.getHandComponent(hand, componentName), scale)
		uevrUtils.registerPostEngineTickCallback(function()
			if M.exists() then
				animation.updateSkeletalVisualization(M.getHandComponent(hand, componentName))
			end
		end)
	end
end

local adjustMode = 1  -- 1-hand rotation  2-hand location  3-finger angles
local adjustModeLabels = {"Hand Rotation", "Hand Location", "Finger Angles"}
local currentHand = 1 -- 0-left  1-right
local currentHandLabels = {"Left", "Right"}
local currentIndex = 1	--1-knuckle 
local currentFinger = 1 -- 1-10
local currentFingerLabels = {"Left Thumb", "Left Index", "Left Middle", "Left Ring", "Left Pinky", "Right Thumb", "Right Index", "Right Middle", "Right Ring", "Right Pinky"}
local positionDelta = 0.2
local rotationDelta = 45
local jointAngleDelta = 5

function M.enableHandAdjustments(boneList, componentName)	
	handBoneList = boneList
	M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
	if adjustMode == 3 then
		M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, LogLevel.Info)
	else
		M.print("Current hand: " .. currentHandLabels[currentHand+1], LogLevel.Info)
	end
	
	register_key_bind("NumPadFive", function()
		M.print("Num5 pressed")
		adjustMode = (adjustMode % 3) + 1
		M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
		if adjustMode == 3 then
			M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, LogLevel.Info)
		else
			M.print("Current hand: " .. currentHandLabels[currentHand+1], LogLevel.Info)
		end
	end)

	register_key_bind("NumPadNine", function()
		M.print("Num9 pressed")
		currentIndex = (currentIndex % 3) + 1
		M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, LogLevel.Info)
	end)

	register_key_bind("NumPadSeven", function()
		M.print("Num7 pressed")
		if adjustMode == 3 then
			currentFinger = (currentFinger % 10) + 1
			M.print("Current finger:" .. currentFingerLabels[currentFinger] .. " finger joint:" .. currentIndex, LogLevel.Info)
		else 
			currentHand = (currentHand + 1) % 2
			M.print("Current hand: " .. currentHandLabels[currentHand+1], LogLevel.Info)
		end
	end)

	register_key_bind("NumPadEight", function()
		M.print("Num8 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 1, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 1, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 0, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadTwo", function()
		M.print("Num2 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 1, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 1, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 0, -jointAngleDelta, componentName)
		end
	end)

	register_key_bind("NumPadFour", function()
		M.print("Num4 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 2, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 2, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 1, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadSix", function()
		M.print("Num6 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 2, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 2, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 1, -jointAngleDelta, componentName)
		end
	end)

	register_key_bind("NumPadThree", function()
		M.print("Num3 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 3, rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 3, positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 2, jointAngleDelta, componentName)
		end
	end)
	register_key_bind("NumPadOne", function()
		M.print("Num1 pressed")
		if adjustMode == 1 then
			M.adjustRotation(currentHand, 3, -rotationDelta, componentName)
		elseif adjustMode == 2 then
			M.adjustLocation(currentHand, 3, -positionDelta, componentName)
		elseif adjustMode == 3 then
			M.setFingerAngles(currentFinger, currentIndex, 2, -jointAngleDelta, componentName)
		end
	end)
end

function M.setFingerAngles(fingerIndex, jointIndex, angleID, angle, componentName)
	if handBoneList == nil or #handBoneList ==0 then
		M.print("Could not adjust fingers because hand bonelist in invalid")
	else
		componentName = getComponentName(componentName)
		if componentName == "" then
			M.print("Could not adjust rotation because component is undefined")
		else	
			local component = M.getHandComponent(fingerIndex < 6 and 0 or 1, componentName)
			animation.setFingerAngles(component, handBoneList, fingerIndex, jointIndex, angleID, angle)
		end
	end
end

function M.printHandTranforms(transforms)
	M.print("Rotation = {" .. transforms["Rotation"][1] .. ", " .. transforms["Rotation"][2] .. ", "  .. transforms["Rotation"][3] ..  "}", LogLevel.Info)
	M.print("Location = {" .. transforms["Location"][1] .. ", " .. transforms["Location"][2] .. ", "  .. transforms["Location"][3] ..  "}", LogLevel.Info)
end

function M.adjustRotation(hand, axis, delta, componentName)
	componentName = getComponentName(componentName)
	if componentName == "" then
		M.print("Could not adjust rotation because component is undefined")
	else	
		local handStr = hand == Handed.Left and "Left" or "Right"
		local definition = handDefinitions[componentName][handStr]
		if definition ~= nil then
			local jointName = definition["Name"]
			if jointName ~= nil and jointName ~= "" then
				local location = getValidVector(definition, "Location", {0,0,0})
				--local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				if handDefinitions[componentName][handStr]["Rotation"] == nil then
					handDefinitions[componentName][handStr]["Rotation"] = {0,0,0}
				end
				handDefinitions[componentName][handStr]["Rotation"][axis] = handDefinitions[componentName][handStr]["Rotation"][axis] + delta
				local rotation = uevrUtils.rotator(handDefinitions[componentName][handStr]["Rotation"][1], handDefinitions[componentName][handStr]["Rotation"][2], handDefinitions[componentName][handStr]["Rotation"][3])
				local scale = getValidVector(definition, "Scale", {1,1,1})
				local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				local component = M.getHandComponent(hand, componentName)
				animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				M.printHandTranforms(handDefinitions[componentName][handStr])
			else
				M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			end
		end
	end
end

function M.adjustLocation(hand, axis, delta, componentName)
	componentName = getComponentName(componentName)
	if componentName == "" then
		M.print("Could not adjust rotation because component is undefined")
	else	
		local handStr = hand == Handed.Left and "Left" or "Right"
		local definition = handDefinitions[componentName][handStr]
		if definition ~= nil then
			local jointName = definition["Name"]
			if jointName ~= nil and jointName ~= "" then
				--local location = getValidVector(definition, "Location", {0,0,0})
				if handDefinitions[componentName][handStr]["Location"] == nil then
					handDefinitions[componentName][handStr]["Location"] = {0,0,0}
				end
				handDefinitions[componentName][handStr]["Location"][axis] = handDefinitions[componentName][handStr]["Location"][axis] + delta
				local location = uevrUtils.vector(handDefinitions[componentName][handStr]["Location"][1], handDefinitions[componentName][handStr]["Location"][2], handDefinitions[componentName][handStr]["Location"][3])
				local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				local scale = getValidVector(definition, "Scale", {1,1,1})
				local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				local component = M.getHandComponent(hand, componentName)
				animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
				M.printHandTranforms(handDefinitions[componentName][handStr])
			else
				M.print("Could not adjust bone in adjustRotation() because joint name is invalid" )
			end
		end
	end
end

function M.debug(skeletalMeshComponent, hand, rightTargetJoint)
	local definition = nil
	if rightTargetJoint ~= nil then 
		definition = { Name = rightTargetJoint }
	end
	if hand == nil then hand = Handed.Right end
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )	
		handComponents["Arms"] = {}
		handComponents["Arms"][hand] = M.createComponent(skeletalMeshComponent, "Arms", hand, definition)

		animation.logBoneNames(skeletalMeshComponent)
		M.createSkeletalVisualization(hand)
	else
		M.print("SkeletalMesh component is nil in create" )
	end
end

return M

--deprecated code
-- local currentRightRotation = {0, 0, 0}
-- local currentRightLocation = {0, 0, 0}
-- local currentLeftRotation = {0, 0, 0}
-- local currentLeftLocation = {0, 0, 0}
-- local currentScale = 1.0
-- 

-- local rightHandComponent = nil
-- local leftHandComponent = nil

-- local leftJointName = ""
-- local rightJointName = ""

-- function M.create(skeletalMeshComponent, leftTargetJoint, rightTargetJoint, rightRotation, rightLocation, leftRotation, leftLocation, pHandBoneList, scale)
	-- if uevrUtils.validate_object(skeletalMeshComponent) ~= nil and leftTargetJoint ~= nil and leftTargetJoint ~= "" and rightTargetJoint ~= nil and rightTargetJoint ~= "" then
		-- leftJointName = leftTargetJoint
		-- rightJointName = rightTargetJoint
		-- if pHandBoneList ~= nil then handBoneList = pHandBoneList end
		-- if rightRotation ~= nil then currentRightRotation = rightRotation end
		-- if rightLocation ~= nil then currentRightLocation = rightLocation end
		-- if leftRotation ~= nil then currentLeftRotation = leftRotation end
		-- if leftLocation ~= nil then currentLeftLocation = leftLocation end
		-- if scale ~= nil then currentScale = scale end
		-- M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )	
		-- rightHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 1)
		-- if rightHandComponent ~= nil then
			-- leftHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 0)	
			
			-- animation.add("right_hand", rightHandComponent, handAnimations)
			-- animation.add("left_hand", leftHandComponent, handAnimations)			
		-- end
	-- else
		-- M.print("SkeletalMesh component is nil or target joints are invalid in create" )
	-- end
-- end

-- function M.createComponent(skeletalMeshComponent, name, hand, disableInit)
	-- local component = nil
	-- if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		-- --not using an existing actor as owner. Mesh affects the hands opacity so its not appropriate
		-- component = animation.createPoseableComponent(skeletalMeshComponent, nil)
		-- if component ~= nil then
			-- --fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
			-- --a better way to do this should be found
			-- component.BoundsScale = 16.0
			-- component.bCastDynamicShadow = false

			-- controllers.attachComponentToController(hand, component)
			-- local baseRotation = skeletalMeshComponent.RelativeRotation
			-- uevrUtils.set_component_relative_transform(component, offset, {Pitch=baseRotation.Pitch+offset.Pitch, Yaw=baseRotation.Yaw+offset.Yaw,Roll=baseRotation.Roll+offset.Roll})	

			-- if disableInit ~= true then
				-- local location = hand == 1 and uevrUtils.vector(currentRightLocation[1], currentRightLocation[2], currentRightLocation[3]) or uevrUtils.vector(currentLeftLocation[1], currentLeftLocation[2], currentLeftLocation[3])
				-- local rotation = hand == 1 and uevrUtils.rotator(currentRightRotation[1], currentRightRotation[2], currentRightRotation[3]) or uevrUtils.rotator(currentLeftRotation[1], currentLeftRotation[2], currentLeftRotation[3])
				-- --animation.initPoseableComponent(component, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
				-- animation.transformBoneToRoot(component, (hand == 1) and rightJointName or leftJointName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), uevrUtils.vector(20, 0, 0))		
			-- end
		-- end
	-- end
	-- return component
-- end
