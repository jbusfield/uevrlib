local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")

local reloadTriggerDistance = 20.0
local earGripTriggerDistance = 25.0
local earGripForwardDotThreshold = 0.8
local mouthTriggerDistance = 25.0
local mouthForwardDotMaxThreshold = 0.65
local mouthForwardDotMinThreshold = 0.35
local headTriggerDistance = 20.0
local headForwardDotMaxThreshold = 0.65
local headForwardDotMinThreshold = 0.0
local eyesTriggerDistance = 15.0
local eyesForwardDotThreshold = 0.85
local holsterTriggerAngle = -65.0

local M = {}

M.Gesture = 
{
	PUNCH = 0,
	HOLSTER = 1,
	RELOAD = 2,
	EARGRAB = 3,
	EAT = 4,
	GLASSESGRAB = 5,
	HATGRAB = 6,
	EARSCRATCH = 7,
	HEADSCRATCH = 8,
	LIPSCRATCH = 9,
	EYESCRATCH = 10,
}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[gestures] " .. text, logLevel)
	end
end

local punchDetector = {
    prevControllerPos = nil,
    prevPawnPos = nil,
    cooldown = 0,
    thresholdSpeed = 180, -- units/sec
    forwardDotThreshold = 0.75,
    cooldownTime = 0.8
}

-- local function degToRad(deg)
    -- return deg * math.pi / 180
-- end

-- local function rotatorToMatrix(rotator)
    -- local Pitch = degToRad(rotator.Pitch)
    -- local Yaw   = degToRad(rotator.Yaw)
    -- local Roll  = degToRad(rotator.Roll)

    -- local cosP, sinP = math.cos(Pitch), math.sin(Pitch)
    -- local cosY, sinY = math.cos(Yaw), math.sin(Yaw)
    -- local cosR, sinR = math.cos(Roll), math.sin(Roll)

    -- local matrix = {
        -- {
            -- cosY * cosR,
            -- cosY * sinR,
            -- -sinY
        -- },
        -- {
            -- sinP * sinY * cosR - cosP * sinR,
            -- sinP * sinY * sinR + cosP * cosR,
            -- sinP * cosY
        -- },
        -- {
            -- cosP * sinY * cosR + sinP * sinR,
            -- cosP * sinY * sinR - sinP * cosR,
            -- cosP * cosY
        -- }
    -- }
    -- return matrix
-- end

-- local function rotateVector(vector, m)
    -- --local m = rotatorToMatrix(rotator)
    -- return {
        -- X = vector.X * m[1][1] + vector.Y * m[1][2] + vector.Z * m[1][3],
        -- Y = vector.X * m[2][1] + vector.Y * m[2][2] + vector.Z * m[2][3],
        -- Z = vector.X * m[3][1] + vector.Y * m[3][2] + vector.Z * m[3][3]
    -- }
-- end

-- local function rotationToForwardVector(rot)
    -- local pitchRad = math.rad(rot.Pitch)
    -- local yawRad = math.rad(rot.Yaw)
    -- return {
        -- X = math.cos(pitchRad) * math.cos(yawRad),
        -- Y = math.cos(pitchRad) * math.sin(yawRad),
        -- Z = math.sin(pitchRad)
    -- }
-- end

local function subtract(a, b)
    return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
end

local function magnitude(v)
    return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z)
end

local function normalize(v)
    local mag = magnitude(v)
    if mag == 0 then return {X=0, Y=0, Z=0} end
    return { X = v.X / mag, Y = v.Y / mag, Z = v.Z / mag }
end

local function dot(a, b)
    return a.X*b.X + a.Y*b.Y + a.Z*b.Z
end

function punchDetector:update(controllerPos, forward, pawnPos, deltaTime)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - deltaTime
		self.prevControllerPos = controllerPos
		self.prevPawnPos = pawnPos
        return false
    end

    if not self.prevControllerPos or not self.prevPawnPos then
        self.prevControllerPos = controllerPos
        self.prevPawnPos = pawnPos
        return false
    end

    -- Compute controller and pawn movement
    local controllerDelta = subtract(controllerPos, self.prevControllerPos)
    local pawnDelta = subtract(pawnPos, self.prevPawnPos)
    local relativeMotion = subtract(controllerDelta, pawnDelta)
	-- print("Pawn delta", pawnDelta.X, pawnDelta.Y, pawnDelta.Z)
	-- print("Controller delta", controllerDelta.X, controllerDelta.Y, controllerDelta.Z)

    local speed = magnitude(relativeMotion) / deltaTime
    --local forward = rotationToForwardVector(controllerRot)
    local motionDir = normalize(relativeMotion)
    local forwardDot = dot(forward, motionDir)

    local isPunch = speed > self.thresholdSpeed and forwardDot > self.forwardDotThreshold

    if isPunch then
        self.cooldown = self.cooldownTime
    end

    -- Update history
    self.prevControllerPos = controllerPos
    self.prevPawnPos = pawnPos

    return isPunch
end

local holsterGripOn = false
function detectHolster(state, hand, continuous)
	local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	end
	if (continuous == true or not holsterGripOn) and uevrUtils.isButtonPressed(state, gripButton) then
		holsterGripOn = true
		local rotation = controllers.getControllerRotation(hand)
		--print(rotation.Pitch,rotation.Yaw,rotation.Roll)
		--only holster if the hand is pointing down
		if rotation.Pitch < holsterTriggerAngle then
			return true
		end
	elseif holsterGripOn and uevrUtils.isButtonNotPressed(state, gripButton)  then
		holsterGripOn = false
	end
	return false
end

local reloadGripOn = false
function detectReload(state, hand, continuous)
	local gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	end
	if (continuous == true or not reloadGripOn) and uevrUtils.isButtonPressed(state, gripButton) then
		reloadGripOn = true
		local gripLocation = controllers.getControllerLocation(1-hand)
		local targetLocation = controllers.getControllerLocation(hand)
		if gripLocation ~= nil and targetLocation ~= nil then
			local distance = magnitude(subtract(gripLocation, targetLocation))
			--print(distance)
			--only reload if one hand is close to the other when grip is pulled
			if distance < reloadTriggerDistance then
				return true
			end
		end
	elseif reloadGripOn and uevrUtils.isButtonNotPressed(state, gripButton) then
		reloadGripOn = false
	end
	return false
end

-- local earGrabGripOn = false
-- function detectEarGrab(state, hand, continuous)
	-- local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	-- if hand == Handed.Left then
		-- gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	-- end
	-- if (continuous == true or not earGrabGripOn) and uevrUtils.isButtonPressed(state, gripButton)  then
		-- earGrabGripOn = true
		-- local headLocation = controllers.getControllerLocation(2)
		-- local handLocation = controllers.getControllerLocation(hand)
		-- if headLocation ~= nil and handLocation ~= nil then
			-- local headRightVector = controllers.getControllerRightVector(2)
			-- local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			-- local forwardDot = dot(headRightVector, headToHandForwardVector) * (hand == Handed.Left and -1 or 1)
			-- local distance = magnitude(subtract(handLocation, headLocation))
			-- --local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			-- --print(distance,forwardDot)
			-- if distance < earGripTriggerDistance and forwardDot > earGripForwardDotThreshold then	
				-- return true
			-- end
		-- end
	-- elseif earGrabGripOn and uevrUtils.isButtonNotPressed(state, gripButton) then
		-- earGrabGripOn = false
	-- end
	-- return false
-- end

local headGripOn = false
function detectFace(state, hand, continuous)
	local gripMouth, gripEyes, gripHead, gripEar = false, false, false, false
	local triggerMouth, triggerEyes, triggerHead, triggerEar = false, false, false, false
	
	local isGripped, isTriggerred = false, false
	if hand == Handed.Right then
		isGripped = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
		isTriggerred = state.Gamepad.bRightTrigger > 128
	else
		isGripped = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
		isTriggerred = state.Gamepad.bLeftTrigger > 128
	end
	
	local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	end
	if (continuous == true or not headGripOn) and (isGripped or isTriggerred)  then
		headGripOn = true
		local headLocation = controllers.getControllerLocation(2)
		local handLocation = controllers.getControllerLocation(hand)
		if headLocation ~= nil and handLocation ~= nil then
			local headForwardVector = controllers.getControllerDirection(2)
			local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			local forwardDot = dot(headForwardVector, headToHandForwardVector)
			local distance = magnitude(subtract(handLocation, headLocation))
			--local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			--print(distance, forwardDot, headLocation.Z-handLocation.Z)
			if distance < mouthTriggerDistance and forwardDot > mouthForwardDotMinThreshold and forwardDot < mouthForwardDotMaxThreshold and headLocation.Z-handLocation.Z > 0 then	
				gripMouth = isGripped
				triggerMouth = isTriggerred
			elseif distance < headTriggerDistance and forwardDot > headForwardDotMinThreshold and forwardDot < headForwardDotMaxThreshold and headLocation.Z-handLocation.Z < 0 then	
				gripHead = isGripped
				triggerHead = isTriggerred
			elseif distance < eyesTriggerDistance and forwardDot > eyesForwardDotThreshold then	
				gripEyes = isGripped
				triggerEyes = isTriggerred
			end		

			local headRightVector = controllers.getControllerRightVector(2)
			--local headToHandForwardVector = normalize(subtract(handLocation, headLocation))
			forwardDot = dot(headRightVector, headToHandForwardVector) * (hand == Handed.Left and -1 or 1)
			--local distance = magnitude(subtract(handLocation, headLocation))
			--local distance = kismet_math_library:Vector_Distance(headLocation, handLocation)
			--print(distance,forwardDot)
			if distance < earGripTriggerDistance and forwardDot > earGripForwardDotThreshold then	
				gripEar = isGripped
				triggerEar = isTriggerred
			end
			
		end
	elseif headGripOn and not (isGripped or isTriggerred) then
		headGripOn = false
	end
	return gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar
end


function M.detectGesture(id, deltaTime, hand, currentPos, currentDirection, pawnPos )
	if hand == nil then hand = Handed.Right end
	if currentPos == nil then 
		currentPos = controllers.getControllerLocation(hand)
	end
	if currentDirection == nil then 
		currentDirection = controllers.getControllerDirection(hand)
	end
	if pawnPos == nil then 
		pawnPos = controllers.getControllerLocation(2)
	end
	if currentPos == nil or currentDirection == nil or pawnPos == nil then
		M.print("Call to detectGesture() failed because controller was invalid")
		return false
	else
		if id == M.Gesture.PUNCH then
			return punchDetector:update(currentPos, currentDirection, pawnPos, deltaTime)
		end
	end
	return false
end

function M.detectGestureWithState(id, state, hand, continuous)
	if id == M.Gesture.HOLSTER then
		return detectHolster(state, hand, continuous)
	elseif id == M.Gesture.RELOAD then
		return detectReload(state, hand, continuous)
	elseif id == M.Gesture.EAT then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripMouth
	elseif id == M.Gesture.GLASSESGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripEyes
	elseif id == M.Gesture.HATGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripHead
	elseif id == M.Gesture.EARGRAB then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return gripEar
	elseif id == M.Gesture.LIPSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerMouth
	elseif id == M.Gesture.EYESCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerEyes
	elseif id == M.Gesture.HEADSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerHead
	elseif id == M.Gesture.EARSCRATCH then
		local gripMouth, gripEyes, gripHead, gripEar, triggerMouth, triggerEyes, triggerHead, triggerEar = detectFace(state, hand, continuous)
		return triggerEar
	end
end

function M.getHeadGestures(state, hand, continuous)
	return detectFace(state, hand, continuous)
end

return M