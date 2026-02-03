local uevrUtils = require("libs/uevr_utils")
local particles = require("libs/particles")
local linetracer = require("libs/linetracer")

local M = {}

M.LengthType = {
    FIXED = 1,
    CAMERA = 2,
    LEFT_CONTROLLER = 3,
    RIGHT_CONTROLLER = 4,
    HUD = 5,
    CUSTOM = 6
}

local laserLengthPerecentage = 1.0 --global multiplier for laser length 0.0 - 1.0

local Laser = {}
Laser.__index = Laser

local function normalizeColor(val)
    if type(val) == "string" then return val end
    return uevrUtils.intToHexString(val)
end

-- options.target = {type="particle", options={...}} -- optional target to spawn at laser end
function M.new(options)
    options = options or {}
    local self = setmetatable({
        component = nil,
        targetComponent = nil,
        laserLengthOffset = options.laserLengthOffset or 0,
        laserColor = normalizeColor(options.laserColor or "#0000FFFF"),
        relativePosition = options.relativePosition or uevrUtils.vector(0,0,0),
        target = options.target or nil,
        lengthSettings = {
            type = (options.lengthSettings and options.lengthSettings.type) or M.LengthType.FIXED,
            fixedLength = (options.lengthSettings and options.lengthSettings.fixedLength) or 50,
            lengthPercentage = (options.lengthSettings and options.lengthSettings.lengthPercentage) or 1.0,
            customTargetingFunctionID = (options.lengthSettings and options.lengthSettings.customTargetingFunctionID) or nil,
            customTargetingOptions = {
                collisionChannel = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.collisionChannel) or 0,
                traceComplex = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.traceComplex) or false,
                maxDistance = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.maxDistance) or 10000,
                ignoreActors = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.ignoreActors) or {},
                includeFullDetails = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.includeFullDetails) or false,
                minHitDistance = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.minHitDistance) or 0,
                customCallback = (options.lengthSettings and options.lengthSettings.customTargetingOptions and options.lengthSettings.customTargetingOptions.customCallback) or nil
            }
        },
    }, Laser)

    self:create() -- auto-create component
    return self
end

function Laser:lineTracerCallback(hitResult, hitLocation)
    if hitLocation ~= nil then
        self:setTargetLocation(hitLocation)
    end
    self.lastHitResult = hitResult
end

function Laser:getLastHitResult()
    return self.lastHitResult
end

function Laser:getLineTraceType()
    local lineTraceType = self.lengthSettings.type == M.LengthType.CAMERA and linetracer.TraceType.CAMERA or
        self.lengthSettings.type == M.LengthType.LEFT_CONTROLLER and linetracer.TraceType.LEFT_CONTROLLER or
        self.lengthSettings.type == M.LengthType.RIGHT_CONTROLLER and linetracer.TraceType.RIGHT_CONTROLLER or
        self.lengthSettings.type == M.LengthType.HUD and linetracer.TraceType.HUD or
        nil
    return lineTraceType
end

function Laser:create()
     if self.component == nil then
        self.component = uevrUtils.create_component_of_class("Class /Script/Engine.CapsuleComponent")
        local c = uevrUtils.getValid(self.component)
        if c ~= nil then
            c:SetCapsuleSize(0.1, 0, true)
            c:SetVisibility(true, true)
            c:SetHiddenInGame(false, false)
            c.bAutoActivate = true
            c:SetGenerateOverlapEvents(false)
            c:SetCollisionEnabled(ECollisionEnabled.NoCollision)
            c:SetRenderInMainPass(true)
            c.bRenderInDepthPass = true
            c.ShapeColor = uevrUtils.hexToColor(self.laserColor)

            c:SetRenderCustomDepth(true)
            c:SetCustomDepthStencilValue(100)
            c:SetCustomDepthStencilWriteMask(ERendererStencilMask.ERSM_255)
            --if self.lengthSettings.type == M.LengthType.FIXED then
                c:SetCapsuleHalfHeight(50, false) -- give it an initial length so it can be seen
            --end
            c.RelativeRotation = uevrUtils.rotator(90, 0, 0)
            self:setRelativePosition(uevrUtils.vector(0,0,0))
        end
    end
    if self.target ~= nil then
        if self.targetComponent == nil then
            if self.target.type == "particle" then
                self.targetComponent = particles.new(self.target.options or {})
            end
            -- self.targetComponent = particles.new({
            --     particleSystemAsset = "ParticleSystem /Game/Art/VFX/ParticleSystems/Weapons/Projectiles/Plasma/PS_Plasma_Ball.PS_Plasma_Ball",
            --     scale = {0.04, 0.04, 0.04},
            --     autoActivate = true
            -- })
        end
    end

    if self.lengthSettings.type ~= M.LengthType.FIXED then
        self.lineTraceType = self:getLineTraceType()
        if self.lineTraceType == nil then --its a custom type
        --if theres no custom callback then treat it as fixed
            if self.lengthSettings.customTargetingOptions.customCallback == nil then
                print("No custom callback found for laser line tracer, defaulting to FIXED length")
                self.lineTraceType = M.LengthType.FIXED
            end
            self.lineTraceType = self.lengthSettings.customTargetingFunctionID or tostring(self) -- just need a unique id
        end
        if self.lineTraceType ~= M.LengthType.FIXED then
            --print("Subscribing laser line tracer: " .. tostring(self.lineTraceType))
            linetracer.subscribe(tostring(self), self.lineTraceType,
            function(hitResult, hitLocation)
                return self:lineTracerCallback(hitResult, hitLocation)
            end, self.lengthSettings.customTargetingOptions, 1)
        end
    end

    if self.lengthSettings.type == M.LengthType.FIXED then
        self:setLength(self.lengthSettings.fixedLength)
    end

    return self.component
end

function Laser:destroy()
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:DetachFromParent(false,false)
        uevrUtils.destroyComponent(self.component, true, true)
        self.component = nil
    end
    if self.targetComponent ~= nil then
        self.targetComponent:destroy()
        self.targetComponent = nil
    end
    linetracer.unsubscribe(tostring(self))
end

function Laser:attachTo(mesh, socketName, attachType, weld)
    local c = uevrUtils.getValid(self.component)
    local m = uevrUtils.getValid(mesh)
    if c ~= nil and m ~= nil then
		return c:K2_AttachTo(m, uevrUtils.fname_from_string(socketName or ""), attachType or 0, weld or false)
    end
end

function Laser:getComponent()
    return self.component
end

function Laser:updateCustomTargetingOptions(options)
    if options == nil then return end

    linetracer.updateOptions(tostring(self), self.lineTraceType, options)
end

function Laser:updatePointer(origin, target)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil and origin ~= nil and target ~= nil then
        local hitDistance = kismet_math_library:Vector_Distance(origin, target) + self.laserLengthOffset
        c:SetCapsuleHalfHeight(hitDistance / 2, false)
        c:K2_SetWorldLocation(
            uevrUtils.vector(
                origin.X + ((target.X-origin.X)/2),
                origin.Y + ((target.Y-origin.Y)/2),
                origin.Z + ((target.Z-origin.Z)/2)
            ),
            false, reusable_hit_result, false
        )
        local rotation = kismet_math_library:Conv_VectorToRotator(
            uevrUtils.vector(target.X-origin.X, target.Y-origin.Y, target.Z-origin.Z)
        )
        rotation.Pitch = rotation.Pitch + 90
        c:K2_SetWorldRotation(rotation, false, reusable_hit_result, false)
    end
end

function Laser:updateRelativePositionOffset()
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c.RelativeLocation = uevrUtils.vector(self.relativePosition)
        c.RelativeLocation.X = c.RelativeLocation.X + c:GetUnscaledCapsuleHalfHeight()
    end
end

function Laser:setRelativePosition(pos)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        self.relativePosition = pos
        self:updateRelativePositionOffset()
    end
end

function Laser:setLength(length)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:SetCapsuleHalfHeight((length / 2) * (laserLengthPerecentage * (self.lengthSettings.lengthPercentage or 1.0) / 2), false)
    end
end

function Laser:setVisibility(isVisible)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:SetVisibility(isVisible, false)
    end
    if self.targetComponent ~= nil then
        self.targetComponent:setVisibility(isVisible)
    end
end

function Laser:setLaserLengthOffset(val)
    self.laserLengthOffset = val or 0
end

function Laser:setLaserColor(val)
    self.laserColor = normalizeColor(val)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c.ShapeColor = uevrUtils.hexToColor(self.laserColor)
    end
end


--local debugSphereComponent = nil
--local particleComponent = nil
function Laser:setTargetLocation(location)
    --calculate the distance between the laser's current location and the target location and set the distance from that
    local c = uevrUtils.getValid(self.component)

    -- if particleComponent == nil then
    --     particleComponent = particles.new({
    --         particleSystemAsset = "ParticleSystem /Game/Art/VFX/ParticleSystems/Weapons/Projectiles/Plasma/PS_Plasma_Ball.PS_Plasma_Ball",
    --         scale = {0.04, 0.04, 0.04},
    --         autoActivate = true
    --     })
    -- end
    -- if particleComponent ~= nil then
    --     particleComponent:setWorldLocation(location)
    -- end
    -- if debugSphereComponent == nil then
	-- 	--debugSphereComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
    --     debugSphereComponent = uevrUtils.create_component_of_class("Class /Script/Engine.SceneComponent")
    --     --"Class /Script/Engine.SceneComponent")--
	-- 	if debugSphereComponent ~= nil then
    --         -- debugSphereComponent.BoundsScale = 10
    --         -- debugSphereComponent:SetVisibility(true,true)
    --         -- debugSphereComponent:SetHiddenInGame(false,true)
	-- 		-- uevrUtils.set_component_relative_transform(debugSphereComponent, nil, nil, {X=0.01, Y=0.01, Z=0.01})
	-- 		-- --uevrUtils.set_component_relative_transform(debugSphereComponent, nil, nil, {X=1, Y=1, Z=1})
    --     end

    --     local ps = uevrUtils.getLoadedAsset("ParticleSystem /Game/Art/VFX/ParticleSystems/Weapons/Projectiles/Plasma/PS_Plasma_Ball.PS_Plasma_Ball")
    --     particleComponent = Statics:SpawnEmitterAttached(
    --         ps, debugSphereComponent, uevrUtils.fname_from_string(""), uevrUtils.vector(0, 0, 0 ), uevrUtils.rotator(0, 0, 0), uevrUtils.vector( 0.04, 0.04, 0.04 ), 0, true, 0, true)

    --     if particleComponent ~= nil then
    --         particleComponent:SetAutoActivate(true)
    --         particleComponent.SecondsBeforeInactive = 0.0
    --         particleComponent:SetCollisionEnabled(3)
    --         particleComponent:SetCollisionResponseToAllChannels(2)
    --         particleComponent:SetRenderInMainPass(true)
    --         particleComponent.bRenderInDepthPass = true
    --     end

    -- end
    -- if debugSphereComponent ~= nil then
    --     debugSphereComponent:K2_SetWorldLocation(location, false, reusable_hit_result, false)
    -- end

    if c ~= nil and location ~= nil then
        local cWorldLocation = c:K2_GetComponentLocation()
        local hitDistance = kismet_math_library:Vector_Distance(cWorldLocation, location) + self.laserLengthOffset
        self:setLength(hitDistance * 1.9) --not sure why 1.9 is the right number here. Maybe has to do with endcaps?
        self:updateRelativePositionOffset()

        if self.targetComponent ~= nil then
            self.targetComponent:setWorldLocation(location)
        end
    end

end

function M.setLaserLengthPercentage(val)
    laserLengthPerecentage = math.max(0.0, math.min(1.0, val or 1.0))
end

return M