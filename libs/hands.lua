local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local animation = require("libs/animation")

local M = {}

local handComponents = {}
local handDefinitions = {}
local handBoneList = {}
local offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}

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

function M.print(text, logLevel)
	uevrUtils.print("[hands] " .. text, logLevel)
end

function M.reset()
	handComponents = {}
	definition = {}
	handBoneList = {}
	offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}
end

function M.exists()
	return M.getHandComponent(0) ~= nil
end

-- if using multiple component like hands and gloves then include componentName or which one is picked will be random
function M.getHandComponent(hand, componentName)
	componentName = getComponentName(componentName)
	if handComponents[componentName] ~= nil then
		return handComponents[componentName][hand]
	end
end 

function M.create(skeletalMeshComponent, definition, handAnimations)
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil and definition ~= nil then
		for name, skeletalMeshDefinition in pairs(definition) do
			M.print("Creating hand component: " .. name )
			handComponents[name] = {}
			for index = 0 , 1 do
				handComponents[name][index] = M.createComponent(skeletalMeshComponent, name, index, skeletalMeshDefinition[index==0 and "Left" or "Right"])
				M.print("Created hand component index: " .. index )
				animation.add(skeletalMeshDefinition[index==0 and "Left" or "Right"]["AnimationID"], handComponents[name][index], handAnimations)
			end
		end
		handDefinitions = definition
	else
		M.print("SkeletalMesh component is nil or target joints are invalid in create" )
	end
	print(M.getHandComponent(0))
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

function M.handleInput(state, isHoldingWeapon)
	
	local triggerValue = state.Gamepad.bLeftTrigger
	animation.updateAnimation("left_hand", "left_trigger", triggerValue > 100)

	animation.updateAnimation("left_hand", "left_grip", uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER))

    local left_controller = uevr.params.vr.get_left_joystick_source()
    local h_left_rest = uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchLeft")    
	animation.updateAnimation("left_hand", "left_thumb", uevr.params.vr.is_action_active(h_left_rest, left_controller))
 
 	if not isHoldingWeapon then
		local triggerValue = state.Gamepad.bRightTrigger
		animation.updateAnimation("right_hand", "right_trigger", triggerValue > 100)

		animation.updateAnimation("right_hand", "right_grip", uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER))

		local right_controller = uevr.params.vr.get_right_joystick_source()
		local h_right_rest = uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchRight")  
		animation.updateAnimation("right_hand", "right_thumb", uevr.params.vr.is_action_active(h_right_rest, right_controller))
	else
		local triggerValue = state.Gamepad.bRightTrigger
		animation.updateAnimation("right_hand", "right_trigger_weapon", triggerValue > 100)
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
		if hand == null then hand = 1 end
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
local positionDelta = 0.2
local rotationDelta = 45
local jointAngleDelta = 5

function M.enableHandAdjustments(boneList, componentName)	
	if boneList == nil or #boneList == 0 then
		M.print("Call to enableHandAdjustments() failed because boneList is invalid", LogLevel.Warning)
	else
		handBoneList = boneList
		M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
		if adjustMode == 3 then
			M.print("Current finger:" .. currentFinger .. " finger joint:" .. currentIndex)
		else
			M.print("Current hand: " .. currentHandLabels[currentHand+1])
		end
		
		register_key_bind("NumPadFive", function()
			M.print("Num5 pressed")
			adjustMode = (adjustMode % 3) + 1
			M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
		end)

		register_key_bind("NumPadNine", function()
			M.print("Num9 pressed")
			currentIndex = (currentIndex % 3) + 1
			M.print("Current finger:" .. currentFinger .. " finger joint:" .. currentIndex)
		end)

		register_key_bind("NumPadSeven", function()
			M.print("Num7 pressed")
			if adjustMode == 3 then
				currentFinger = (currentFinger % 10) + 1
				M.print("Current finger:" .. currentFinger .. " finger joint:" .. currentIndex)
			else 
				currentHand = (currentHand + 1) % 2
				M.print("Current hand: " .. currentHandLabels[currentHand+1])
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
				M.adjustRotation(currentHand, 1, -rotationDelta)
			elseif adjustMode == 2 then
				M.adjustLocation(currentHand, 1, -positionDelta)
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
end

function M.setFingerAngles(fingerIndex, jointIndex, angleID, angle, componentName)
	componentName = getComponentName(componentName)
	if componentName == "" then
		M.print("Could not adjust rotation because component is undefined")
	else	
		animation.setFingerAngles(fingerIndex < 6 and handDefinitions[debugComponentName][0] or handDefinitions[debugComponentName][1], handBoneList, fingerIndex, jointIndex, angleID, angle)
	end
end

function M.adjustRotation(hand, axis, delta, componentName)
	componentName = getComponentName(componentName)
	if componentName == "" then
		M.print("Could not adjust rotation because component is undefined")
	else	
		local definition = handDefinitions[debugComponentName][hand]
		if definition ~= nil then
			local jointName = definition["Name"]
			if jointName ~= nil and jointName ~= "" then
				local location = getValidVector(definition, "Location", {0,0,0})
				--local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				if definition["Rotation"] == nil then
					definition["Rotation"] = {0,0,0}
				end
				definition["Rotation"][axis] = definition["Rotation"][axis] + delta
				local rotation = uevrUtils.rotator(definition["Rotation"][1], definition["Rotation"][2], definition["Rotation"][3])
				local scale = getValidVector(definition, "Scale", {1,1,1})
				local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
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
		local definition = handDefinitions[debugComponentName][hand]
		if definition ~= nil then
			local jointName = definition["Name"]
			if jointName ~= nil and jointName ~= "" then
				--local location = getValidVector(definition, "Location", {0,0,0})
				if definition["Location"] == nil then
					definition["Location"] = {0,0,0}
				end
				definition["Location"][axis] = definition["Location"][axis] + delta
				local location = uevrUtils.vector(definition["Location"][1], definition["Location"][2], definition["Location"][3])
				local rotation = getValidRotator(definition, "Rotation", {0,0,0})
				local scale = getValidVector(definition, "Scale", {1,1,1})
				local taperOffset = getValidVector(definition, "TaperOffset", {0,0,0})
				animation.transformBoneToRoot(component, jointName, location, rotation, scale, taperOffset)		
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
	if hand == nil then hand = 1 end
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil then
		M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )	
		local component = M.createComponent(skeletalMeshComponent, "Arms", hand, definition)

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
