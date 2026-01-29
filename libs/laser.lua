local uevrUtils = require("libs/uevr_utils")

local M = {}

local Laser = {}
Laser.__index = Laser

local function normalizeColor(val)
    if type(val) == "string" then return val end
    return uevrUtils.intToHexString(val)
end

function M.new(options)
    options = options or {}
    local self = setmetatable({
        component = nil,
        laserLengthOffset = options.laserLengthOffset or 0,
        laserColor = normalizeColor(options.laserColor or "#0000FFFF"),
    }, Laser)

    self:create() -- auto-create component
    return self
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
            --c:SetCapsuleHalfHeight(50, false) -- give it an initial length so it can be seen
            c.RelativeRotation = uevrUtils.rotator(90, 0, 0)
            self:setRelativePosition(uevrUtils.vector(0,0,0))
        end
    end
    return self.component
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

function Laser:destroy()
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:DetachFromParent(false,false)
        uevrUtils.destroyComponent(self.component, true, true)
        self.component = nil
    end
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

function Laser:setRelativePosition(pos)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        --pos.X = pos.X + (c:GetUnscaledCapsuleHalfHeight() / 2)
        c.RelativeLocation = uevrUtils.vector(pos)
        c.RelativeLocation.X = c.RelativeLocation.X + c:GetUnscaledCapsuleHalfHeight()
    end
end

function Laser:setLength(length)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:SetCapsuleHalfHeight(length / 2, false)
    end
end

function Laser:setVisibility(isVisible)
    local c = uevrUtils.getValid(self.component)
    if c ~= nil then
        c:SetVisibility(isVisible, false)
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

return M