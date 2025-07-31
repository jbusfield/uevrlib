local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")

local M = {}

M.Gesture = 
{
	PUNCH = 0
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

local function rotationToForwardVector(rot)
    local pitchRad = math.rad(rot.Pitch)
    local yawRad = math.rad(rot.Yaw)
    return {
        X = math.cos(pitchRad) * math.cos(yawRad),
        Y = math.cos(pitchRad) * math.sin(yawRad),
        Z = math.sin(pitchRad)
    }
end

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

function punchDetector:update(controllerPos, controllerRot, pawnPos, deltaTime)
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
    local forward = rotationToForwardVector(controllerRot)
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

function M.detectGesture(id, deltaTime, hand, currentPos, currentRot, pawnPos )
	if hand == nil then hand = Handed.Right end
	if currentPos == nil then 
		currentPos = controllers.getControllerLocation(hand)
	end
	if currentRot == nil then 
		currentRot = controllers.getControllerRotation(hand)
	end
	if pawnPos == nil then 
		pawnPos = controllers.getControllerLocation(2)
	end
	if currentPos == nil or currentRot == nil or pawnPos == nil then
		M.print("Call to detectGesture() failed because controller was invalid")
		return false
	else
		if id == M.Gesture.PUNCH then
			return punchDetector:update(currentPos, currentRot, pawnPos, deltaTime)
		end
	end
	return false
end

return M