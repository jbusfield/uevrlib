local uevrUtils = require('libs/uevr_utils')
local controllers = require('libs/controllers')
--local configui = require("libs/configui")
local reticule = require("libs/reticule")
--local hands = require('libs/hands')
local attachments = require('libs/attachments')
local input = require('libs/input')
local flickerFixer = require("libs/flicker_fixer")

uevrUtils.setLogLevel(LogLevel.Debug)
reticule.setLogLevel(LogLevel.Debug)
input.setLogLevel(LogLevel.Debug)
attachments.setLogLevel(LogLevel.Debug)

attachments.enableConfiguration() 
input.setMeshName("TPVMesh")
input.showConfiguration("config_outer_worlds")
attachments.autoUpdate(function()
	if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
		local currentWeapon = pawn:GetCurrentWeapon()
		if currentWeapon ~= nil and currentWeapon.SkeletalMeshComponent ~= nil then 
			currentWeapon.SkeletalMeshComponent:SetHiddenInGame(false,true)
			currentWeapon.SkeletalMeshComponent:SetVisibility(true,true)
		end
		return currentWeapon.SkeletalMeshComponent, controllers.getController(Handed.Right)
	end
end)

function createReticule()
	local options = {
		removeFromViewport = true,
		twoSided = true,
		scale = {0.2,0.2,0.2}, 
		position = {0.0, 0.0, 14.0}
	}
	local className = "WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C" --The Outer Worlds
	local widget = uevrUtils.getActiveWidgetByClass(className)
	if uevrUtils.getValid(widget) ~= nil then
		reticule.createFromWidget(widget, options)
	end			
end

function on_game_paused(isPaused)
	if isPaused then --adds black background to any dialog screens that freeze the game
		uevrUtils.set_2D_mode(true)
		uevrUtils.set_2D_mode(false, 1)
	end
end

function on_level_change(level)
	controllers.createController(0)
	controllers.createController(1)
	controllers.createController(2)
	attachments.attachToController(pawn.FPVCamera, Handed.Right)
	--attachments.attachToMesh(pawn.FPVCamera, pawn:GetCurrentWeapon().SkeletalMeshComponent, "MuzzleFlashSocket") 
	createReticule()
	flickerFixer.create()
end

function on_post_engine_tick(engine, delta)
	--muzzleflash is incorrect unless this is done on the tick
	if uevrUtils.getValid(pawn) ~= nil then 
		if pawn.GetCurrentWeapon ~= nil then
			uevrUtils.fixMeshFOV(pawn:GetCurrentWeapon().SkeletalMeshComponent, "ForegroundPriorityEnabled", 0.0, true, true, false)
		end
		if pawn.FPVCamera ~= nil then
			reticule.update(controllers.getControllerLocation(2),reticule.getTargetLocation(pawn.FPVCamera:K2_GetComponentLocation(), pawn.FPVCamera:GetForwardVector()))
		end
	end
end

setInterval(1000, function()
	if pawn and pawn.FPVMesh then
		uevrUtils.fixMeshFOV(pawn.FPVMesh, "ForegroundPriorityEnabled", 0.0, true, true, false)
		uevrUtils.fixMeshFOV(pawn.TPVMesh, "ForegroundPriorityEnabled", 0.0, true, true, false)
		pawn.TPVMesh:SetVisibility(true,true)
		pawn.FPVMesh:SetVisibility(false,true)
	end
end)


