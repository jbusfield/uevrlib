--Courtesy of Pande4360 and gwizdek
local uevrUtils = require("libs/uevr_utils")

local M = {}
M.msecTimer = 5000

local flickerFixerComponent = nil
local isTriggered = false

local function createFlickerFixerComponent(fov, rt)
	local component = uevrUtils.create_component_of_class("Class /Script/Engine.SceneCaptureComponent2D", false)
    if component == nil then
        print("Failed to spawn scene capture")
    else
		component.TextureTarget = rt
		component.FOVAngle = fov
		component:SetVisibility(true)
	end
	return component
end

function triggerFlickerFixer()
	if uevrUtils.validate_object(flickerFixerComponent) ~= nil then
		flickerFixerComponent:SetVisibility(true)
		--print("Fixer on")
		delay(1000, function()
			flickerFixerComponent:SetVisibility(false)
			--print("Fixer off")
		end)
	end
	delay(M.msecTimer, triggerFlickerFixer)
end

function M.create()
	local world = uevrUtils.get_world()
	local fov = 2.0
	local kismet_rendering_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetRenderingLibrary")
	local rt = kismet_rendering_library:CreateRenderTarget2D(world, 64, 64, 6, zero_color, false)
	if rt ~= nil then
		flickerFixerComponent = createFlickerFixerComponent(fov, rt)
		if flickerFixerComponent ~= nil then
			if not isTriggered then
				triggerFlickerFixer()
				isTriggered = true
			end
		else	
			print("Flicker fixer component could not be created")
		end
	else	
		print("Flicker fixer render target could not be created")
	end
end

return M