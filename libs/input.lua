-- Decoupled Yaw code courtesy of Pande4360

local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local controllers = require("libs/controllers")
local pawnModule = require("libs/pawn")

local M = {}

M.AimMethod =
{
    UEVR = 1,
    HEAD = 2,
    RIGHT_CONTROLLER = 3,
    LEFT_CONTROLLER = 4,
}

M.PawnRotationMode =
{
    NONE = 1,
    LOCKED = 2,
    SIMPLE = 3,
    ADVANCED = 4,
}

M.PawnPositionMode =
{
    NONE = 1,
    FOLLOWS = 2,
    ANIMATED = 3
}

local aimMethod = M.AimMethod.UEVR

local decoupledYaw = nil
local bodyRotationOffset = 0

local rxState = 0
local snapTurnDeadZone = 8000

local headOffset = uevrUtils.vector(0,0,80)
local useSnapTurn = false
local smoothTurnSpeed = 100
local snapAngle = 30
local pawnPositionAnimationScale = 0.2
local eyeOffset = 0
local pawnPositionMode = M.PawnPositionMode.NONE
local pawnRotationMode = M.PawnRotationMode.NONE
local adjustForAnimation = false
local adjustForEyeOffset = false

local currentHeadRotator = uevrUtils.rotator(0,0,0)
local headBoneName = ""
local rootBoneName = ""
local boneList = {}

local handed = Handed.Right

local configWidgets = spliceableInlineArray{
	{
		widgetType = "tree_node",
		id = "uevr_input_aim_method",
		initialOpen = true,
		label = "Aim Method"
	},
		{
			widgetType = "combo",
			id = "aimMethod",
			label = "Type",
			selections = {"UEVR", "Head/HMD", "Right Controller", "Left Controller"},
			initialValue = aimMethod
		},
	{
		widgetType = "tree_pop"
	},
	{
		widgetType = "begin_group",
		id = "advanced_input",
		isHidden = false
	},
		{
			widgetType = "tree_node",
			id = "uevr_input_turning",
			initialOpen = true,
			label = "Turning"
		},
			{
				widgetType = "checkbox",
				id = "useSnapTurn",
				label = "Use Snap Turn",
				initialValue = useSnapTurn
			},
			{
				widgetType = "slider_int",
				id = "snapAngle",
				label = "Snap Turn Angle",
				speed = 1.0,
				range = {2, 180},
				initialValue = snapAngle
			},
			{
				widgetType = "slider_int",
				id = "smoothTurnSpeed",
				label = "Smooth Turn Speed",
				speed = 1.0,
				range = {1, 200},
				initialValue = smoothTurnSpeed
			},
		{
			widgetType = "tree_pop"
		},
		{
			widgetType = "tree_node",
			id = "uevr_input_pawn",
			initialOpen = true,
			label = "Player Body"
		},
			{
				widgetType = "drag_float3",
				id = "headOffset",
				label = "Head Offset",
				speed = .1,
				range = {-200, 200},
				initialValue = {headOffset.X, headOffset.Y, headOffset.Z}
			},
			{
				widgetType = "checkbox",
				id = "adjustForAnimation",
				label = "Running Animation Compensation",
				initialValue = adjustForAnimation
			},
			{
				widgetType = "combo",
				id = "headBones",
				label = "Head Bone",
				selections = {"None"},
				initialValue = 1
			},
			{
				widgetType = "checkbox",
				id = "adjustForEyeOffset",
				label = "Eye Offset Compensation",
				initialValue = adjustForEyeOffset
			},
			{
				widgetType = "slider_float",
				id = "eyeOffset",
				label = "Eye Offset",
				speed = .1,
				range = {-40, 40},
				initialValue = eyeOffset
			},
			{
				widgetType = "tree_node",
				id = "uevr_input_roomscale",
				initialOpen = true,
				label = "Roomscale"
			},
				{
					widgetType = "combo",
					id = "pawnPositionMode",
					label = "Position",
					selections = {"Does Not Follow HMD", "Follows HMD", "Follows HMD With Animation"},
					initialValue = pawnPositionMode
				},
				{
					widgetType = "slider_float",
					id = "pawnPositionAnimationScale",
					label = "Animation Scale",
					speed = .01,
					range = {0, 1},
					initialValue = pawnPositionAnimationScale,
				},
				{
					widgetType = "combo",
					id = "pawnRotationMode",
					label = "Rotation",
					selections = {"Not Affected by HMD", "Locked to HMD", "Follows HMD (Simple)", "Follows HMD (Advanced)"},
					initialValue = pawnRotationMode
				},
				expandArray(pawnModule.getConfigWidgets),
			{
				widgetType = "tree_pop"
			},
		{
			widgetType = "tree_pop"
		},
	{
		widgetType = "end_group",
	},
	-- {
		-- widgetType = "slider_float",
		-- id = "neckOffset",
		-- label = "Neck Offset",
		-- speed = .1,
		-- range = {-40, 40},
		-- initialValue = 10
	-- },

}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[input] " .. text, logLevel)
	end
end

function M.getConfigWidgets(options)
	return configui.applyOptionsToConfigWidgets(configWidgets, options)
end

function M.setAimMethod(val)
	aimMethod = val
end

function M.setUseSnapTurn(val)
	useSnapTurn = val
end

function M.setSmoothTurnSpeed(val)
	smoothTurnSpeed = val
end

function M.setSnapAngle(val)
	snapAngle = val
end

function M.setHandedness(val)
	handed = val
end

function M.setPawnRotationMode(val)
	pawnRotationMode = val
end

function M.setPawnPositionMode(val)
	pawnPositionMode = val
end

function M.setPawnPositionAnimationScale(val)
	pawnPositionAnimationScale = val
end

function M.setAdjustForAnimation(val)
	adjustForAnimation = val
end

function M.setAdjustForEyeOffset(val)
	adjustForEyeOffset = val
end

function M.setEyeOffset(val)
	eyeOffset = val
end

function M.setHeadOffset(...)
	headOffset = uevrUtils.vector(table.unpack({...}))
end

--VR_SwapControllerInputs check this to see if user has chosen left hand full input swap in the UEVR UI
local function updateDecoupledYaw(state, rotationHand)
	if rotationHand == nil then rotationHand = Handed.Right end
	local yawChange = 0
	if decoupledYaw ~= nil then
		local thumbLX = state.Gamepad.sThumbLX
		local thumbLY = state.Gamepad.sThumbLY
		local thumbRX = state.Gamepad.sThumbRX
		local thumbRY = state.Gamepad.sThumbRY
		
		if rotationHand == Handed.Left then
			thumbLX = state.Gamepad.sThumbRX
			thumbLY = state.Gamepad.sThumbRY
			thumbRX = state.Gamepad.sThumbLX
			thumbRY = state.Gamepad.sThumbLY
		end
		
		if useSnapTurn then
			if thumbRX > snapTurnDeadZone and rxState == 0 then
				yawChange = snapAngle
				rxState=1
			elseif thumbRX < -snapTurnDeadZone and rxState == 0 then
				yawChange = -snapAngle
				rxState=1
			elseif thumbRX <= snapTurnDeadZone and thumbRX >=-snapTurnDeadZone then
				rxState=0
			end
		else 
			local smoothTurnRate = smoothTurnSpeed / 12.5
			local rate = thumbRX/32767
			rate =  rate*rate*rate*rate
			if thumbRX > 2200 then
				yawChange = (rate * smoothTurnRate)
			end
			if thumbRX < -2200 then
				yawChange =  -(rate * smoothTurnRate)
			end
		end	
		
		--keep the decoupled yaw in the range of -180 to 180
		decoupledYaw = uevrUtils.clampAngle180(decoupledYaw + yawChange)
	end
	return yawChange
end

local function getRootBoneOfBone(skeletalMeshComponent, boneName)
	local fName = uevrUtils.fname_from_string(boneName)
	local boneName = fName
	while fName:to_string() ~= "None" do
		boneName = fName
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	return boneName
end

local function getBoneNames(skeletalMeshComponent)
	local boneNames = {}
	if skeletalMeshComponent ~= nil then
		local count = skeletalMeshComponent:GetNumBones()
		for index = 0 , count - 1 do
			table.insert(boneNames, skeletalMeshComponent:GetBoneName(index):to_string()) 
		end
	else
		M.print("Can't get bone names because skeletalMeshComponent was nil", LogLevel.Warning)
	end
	return boneNames
end

local function setCurrentHeadBone(value)
	headBoneName = boneList[value]
	local mesh = uevrUtils.getValid(pawn,{"Mesh"})
	if mesh ~= nil then
		local rootBoneFName = getRootBoneOfBone(mesh, headBoneName)
		if rootBoneFName ~= nil then
			rootBoneName = rootBoneFName:to_string()
		end
	end
end

local setBoneNames = doOnce(function ()
	local mesh = uevrUtils.getValid(pawn,{"Mesh"})
	if mesh ~= nil then
		boneList = getBoneNames(mesh)
		if #boneList == 0 then error() end
		configui.setSelections("headBones", boneList)
	end
	local currentHeadBoneIndex = configui.getValue("headBones")
	if currentHeadBoneIndex > 1 then
		setCurrentHeadBone(currentHeadBoneIndex)
	end
end, Once.PER_LEVEL)


-- When a pawn runs, the animation can move the mesh ahead of the pawn, allowing you to
-- see down the neck hole if you are looking down. This function calculates an offset by which a pawn's
-- mesh can be moved to keep the neck in its proper place with respect to the pawn. Concept courtesy of Pande4360
local function getAnimationHeadDelta(pawn, pawnYaw)
	if headBoneName ~= "" and rootBoneName ~= "" and adjustForAnimation == true then
		local baseRotationOffsetRotatorYaw = 0
		if pawn.BaseRotationOffset ~= nil then
			baseRotationOffsetRotator = kismet_math_library:Quat_Rotator(pawn.BaseRotationOffset)
			if baseRotationOffsetRotator ~= nil then				
				baseRotationOffsetRotatorYaw = baseRotationOffsetRotator.Yaw
			end
		end

		local headSocketLocation = pawn.Mesh:GetSocketLocation(uevrUtils.fname_from_string(headBoneName))
		local rootSocketLocation = pawn.Mesh:GetSocketLocation(uevrUtils.fname_from_string(rootBoneName))
		local socketDelta = uevrUtils.vector(headSocketLocation.Y - rootSocketLocation.Y, headSocketLocation.X - rootSocketLocation.X, headSocketLocation.Z - rootSocketLocation.Z)
		socketDelta = kismet_math_library:RotateAngleAxis(socketDelta, pawnYaw - baseRotationOffsetRotatorYaw, uevrUtils.vector(0,0,1))
		return socketDelta
	else
		return uevrUtils.vector(0,0,0)
	end
end

--because the eyes may not be centered on the origin, an hmd rotation can cause unexpected movement of the pawn. This compensates for that movement
local function getEyeOffsetDelta(pawn, pawnYaw)
	if adjustForEyeOffset == true then
		local eyeOffsetScale = (pawn.BaseTranslationOffset and pawn.BaseTranslationOffset.X or 0) + eyeOffset
		local eyeVector = kismet_math_library:Conv_RotatorToVector(uevrUtils.rotator(currentHeadRotator.Pitch, pawnYaw - currentHeadRotator.Yaw, currentHeadRotator.Roll))			
		eyeVector = eyeVector * eyeOffsetScale
		--print("EYE1",eyeVector.X,eyeVector.Y,eyeVector.Z)
		return eyeVector
	else
		return uevrUtils.vector(0,0,0)
	end
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if aimMethod ~= M.AimMethod.UEVR then
		local yawChange = updateDecoupledYaw(state)
		
		if yawChange~= 0 and decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
			pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
		end
	end
end)
local deltaX = 0
local deltaY = 0
local lastPosition = nil


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if aimMethod ~= M.AimMethod.UEVR then
		if decoupledYaw == nil then
			if uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_GetComponentRotation ~= nil then
				local rotator = pawn.RootComponent:K2_GetComponentRotation()
				decoupledYaw = rotator.Yaw
			end
		end

		local controllerID = aimMethod == M.AimMethod.LEFT_CONTROLLER and 0 or (aimMethod == M.AimMethod.HEAD and 2 or 1)
		local rotation = controllers.getControllerRotation(controllerID)
		if uevrUtils.getValid(pawn) ~= nil and pawn.Controller ~= nil and pawn.Controller.SetControlRotation ~= nil and rotation ~= nil then			
			--disassociates the rotation of the pawn from the rotation set by pawn.Controller:SetControlRotation()
			pawn.bUseControllerRotationPitch = false
			pawn.bUseControllerRotationYaw = false
			pawn.bUseControllerRotationRoll = false
			
			pawn.CharacterMovement.bOrientRotationToMovement = false
			pawn.CharacterMovement.bUseControllerDesiredRotation = false
			
			pawn.Controller:SetControlRotation(rotation) --now aiming with the hand or head doesnt affect the rotation of the pawn
		end
		
		--isolate this and anything else that can be
		if pawnRotationMode ~= M.PawnRotationMode.NONE then	
			if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
				if pawnRotationMode == M.PawnRotationMode.SIMPLE then	
					bodyRotationOffset = pawnModule.updateBodyYaw(bodyRotationOffset, currentHeadRotator.Yaw - decoupledYaw, delta)
				elseif pawnRotationMode == M.PawnRotationMode.ADVANCED then
					bodyRotationOffset = pawnModule.updateBodyYaw_Advanced(bodyRotationOffset, currentHeadRotator.Yaw - decoupledYaw, controllers.getControllerLocation(2), controllers.getControllerLocation(0),  controllers.getControllerLocation(1), delta)
				elseif pawnRotationMode == M.PawnRotationMode.LOCKED then
					bodyRotationOffset = currentHeadRotator.Yaw - decoupledYaw
				end
				pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
			end
		end
	end

	setBoneNames()
end)

uevr.params.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)	
	if aimMethod ~= M.AimMethod.UEVR and view_index == 1 then
		--isolate this
		local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
		if rootComponent ~= nil and decoupledYaw ~= nil and pawn.Mesh ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then			
			if pawnPositionMode ~= M.PawnPositionMode.NONE then			
				uevr.params.vr.get_standing_origin(temp_vec3f)
				
				local origin = {X=temp_vec3f.X,Y=temp_vec3f.Y,Z=temp_vec3f.Z}
				temp_quatf:set(0,0,0,0)
				uevr.params.vr.get_pose(uevr.params.vr.get_hmd_index(), temp_vec3f, temp_quatf)
				
				--delta is how much the real world position of the hmd is changed from the real world origin
				local delta = {X=(temp_vec3f.X-origin.X)*world_to_meters, Y=(temp_vec3f.Y-origin.Y)*world_to_meters, Z=(temp_vec3f.Z-origin.Z)*world_to_meters}

				-- temp_quatf contains how much the rotation of the hmd is relative to the real world vr coordinate system
				local poseQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, -temp_quatf.W)  --reordered terms to convert UEVR to unreal coord system
				--local poseRotator = kismet_math_library:Quat_Rotator(poseQuat)
				--print("POSE",poseRotator.Pitch, poseRotator.Yaw, poseRotator.Roll) --this is in the Unreal coord system
				
				temp_quatf:set(0,0,0,0)
				uevr.params.vr.get_rotation_offset(temp_quatf) --This is how much the head was twisted from the pose quat the last time "recenter view" was performed
				local headQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, temp_quatf.W) --reordered terms to convert UEVR to unreal coord system
				--local headRotator = kismet_math_library:Quat_Rotator(headQuat)
				--print("HEAD",headRotator.Pitch, headRotator.Yaw, headRotator.Roll) --this is in the Unreal coord system
											
				--rotate the delta by the amount of the hmd offset
				local forwardVector = kismet_math_library:Quat_RotateVector(headQuat, uevrUtils.vector(-delta.Z, delta.X, delta.Y)) --converts UEVR to Unreal coord system
				
				--add the decoupledYaw yaw rotation to the delta vector
				forwardVector = kismet_math_library:RotateAngleAxis( forwardVector,  decoupledYaw, uevrUtils.vector(0,0,1))
				forwardVector.Z = 0 --do not affect up/down
				if pawnPositionMode == M.PawnPositionMode.ANIMATED then
					pawn:AddMovementInput(forwardVector, pawnPositionAnimationScale, false);
				elseif pawnPositionMode == M.PawnPositionMode.FOLLOWS then
					rootComponent:K2_AddWorldOffset(forwardVector, true, reusable_hit_result, false)
					--rootComponent:K2_SetWorldLocation(uevrUtils.vector(pawnPos.X+forwardVector.X,pawnPos.Y+forwardVector.Y,pawnPos.Z),true,reusable_hit_result,false)
				end
				
				--temp_vec3f has the get_pose location
				temp_vec3f.Y = origin.Y --dont affect the up_down position
				uevr.params.vr.set_standing_origin(temp_vec3f)
				--done with pawn

			end

			--work on mesh
			local pawnRot = rootComponent:K2_GetComponentRotation()
			local animationDelta = getAnimationHeadDelta(pawn, pawnRot.Yaw)
			local eyeOffsetDelta = getEyeOffsetDelta(pawn, pawnRot.Yaw) 
							
			temp_vec3:set(0, 0, 1) --the axis to rotate around
			local forwardVector = kismet_math_library:RotateAngleAxis(headOffset, pawnRot.Yaw - bodyRotationOffset - decoupledYaw, temp_vec3)

			--dont worry about Z here. Z is applied directly to the RootComponent later
			pawn.Mesh.RelativeLocation.X = -forwardVector.X + animationDelta.X + eyeOffsetDelta.X --
			pawn.Mesh.RelativeLocation.Y = -forwardVector.Y + animationDelta.Y - eyeOffsetDelta.Y --
			--done with mesh

		end
	end

	if aimMethod ~= M.AimMethod.UEVR then
		local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
		if bodyRotationOffset ~= nil and rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
			local pawnPos = rootComponent:K2_GetComponentLocation()	
			local pawnRot = rootComponent:K2_GetComponentRotation()					
			pawnRot.Yaw = pawnRot.Yaw - bodyRotationOffset
			
			-- temp_vec3f:set(headOffset.X, headOffset.Y, headOffset.Z) -- the vector representing the offset adjustment
			-- temp_vec3:set(0, 0, 1) --the axis to rotate around
			-- local forwardVector = kismet_math_library:RotateAngleAxis(temp_vec3f, pawnRot.Yaw, temp_vec3)

			-- position.x = pawnPos.x + forwardVector.X
			-- position.y = pawnPos.y + forwardVector.Y
			-- position.z = pawnPos.z + forwardVector.Z

			position.x = pawnPos.x 
			position.y = pawnPos.y 
			position.z = pawnPos.z + headOffset.Z
			rotation.Pitch = 0--pawnRot.Pitch 
			rotation.Yaw = pawnRot.Yaw
			rotation.Roll = 0--pawnRot.Roll 
			
		end
	end
end)

-- uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	-- --print("Pre Stereo")
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
-- --print("Pre",view_index, position.X - pawnPos.X, position.Y - pawnPos.Y)
	-- end

-- end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--currentHeadRotator = rotation -- this doesnt work	
	currentHeadRotator.Pitch = rotation.Pitch
	currentHeadRotator.Yaw = rotation.Yaw
	currentHeadRotator.Roll = rotation.Roll

--print("Post Stereo")
	-- local minYawDelta = configui.getValue("minYawDelta")
	-- local maxYawDelta = configui.getValue("maxYawDelta")
	-- local bodyYawThreshhold = configui.getValue("bodyYawThreshhold")
-- print("EYE2",position.X, position.Y, position.Z)		
	
	
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
	
		-- if lastPosition == nil then
			-- lastPosition = {X = position.X, Y = position.Y, Z = position.Z}
		-- end
		-- deltaX = position.X - pawnPos.X
		-- deltaY = position.Y - pawnPos.Y
		-- --print("Post ",view_index,deltaX,deltaY)
		
		-- lastPosition.X = position.X
		-- lastPosition.Y = position.Y
		-- lastPosition.Z = position.Z
	-- end
	
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- --local pawnLocation = rootComponent:K2_GetComponentLocation()
		
		-- --rootComponent:K2_SetWorldLocation(uevrUtils.vector(position.X,position.Y,0),true,reusable_hit_result,false)
		-- --position.X = pawnLocation.X
		-- --position.Y = pawnLocation.Y
		-- --transform = rootComponent:K2_GetComponentToWorld()
	-- end

	-- local postYaw = clampAngle180(rotation.Yaw - decoupledYaw)
	-- local yawDelta = clampAngle180(postYaw - bodyRotationOffset)
	-- local offset = 0--yawDelta
	-- print(yawDelta)
	-- if yawDelta < - 40 then
		-- targetYaw = postYaw
	-- end
	
	--offset = postYaw - bodyRotationOffset
	-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
	-- if math.abs(yawDelta - bodyRelativeYaw) > 10 then
		-- --offset = yawDelta
		-- --storedYaw = storedYaw + yawDelta
		-- storedYaw =  yawDelta
	-- end
-- print(bodyRelativeYaw, yawDelta, yawDelta - bodyRelativeYaw, storedYaw)
	-- if storedYaw > 0.1 then
		-- offset = yawDelta - storedYaw
		-- storedYaw = storedYaw - 0.1
	-- elseif storedYaw < 0.1 then
		-- offset = yawDelta + storedYaw
		-- storedYaw = storedYaw + 0.1
	-- else
		-- storedYaw = 0
	-- end
--offset = yawDelta - bodyRelativeYaw
	-- if yawDelta > minYawDelta then 
		-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
		-- print("YAW 1",bodyRelativeYaw) 
		-- if yawDelta > maxYawDelta then
			-- --offset = 15.0 --set it to controller rotation yaw
			-- offset = rotation.Yaw - bodyRotationOffset
		-- elseif (bodyRelativeYaw > -bodyYawThreshhold and bodyRelativeYaw < bodyYawThreshhold) then
			-- offset = 0.2 
		-- end
	-- end
	
	-- if yawDelta < -minYawDelta then 
		-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
		-- print("YAW 2",bodyRelativeYaw) 
		-- if yawDelta < -maxYawDelta then
			-- --offset = -15.0
			-- offset = rotation.Yaw - bodyRotationOffset
		-- elseif (bodyRelativeYaw > -bodyYawThreshhold and bodyRelativeYaw < bodyYawThreshhold) then
			-- offset = -0.2 
		-- end
	-- end
	
	-- if offset ~= 0 then
		-- --print(yawDelta,decoupledYaw, postYaw, bodyRotationOffset, offset)
		-- bodyRotationOffset = clampAngle180(bodyRotationOffset + offset)

		-- --decoupledYaw = rotation.Yaw
		-- if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
			-- pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
		-- end
	-- end

end)


uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
--print("Post engine")
--print(bodyRotationOffset, currentHeadYaw, delta)

	-- if configui.getValue("pawnPositionFollowsHMD") then
	
		-- local hmdDirection = controllers.getControllerDirection(2)
		-- bodyRotationOffset = UpdateBodyYaw(bodyRotationOffset, currentHeadYaw - decoupledYaw, delta)
		-- --bodyRotationOffset = UpdateBodyYaw(bodyRotationOffset, currentHeadYaw - decoupledYaw, controllers.getControllerLocation(0),  controllers.getControllerLocation(1), hmdDirection, delta)
		-- if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
			-- pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
		-- end
	-- end

	-- local hmdRightVector = controllers.getControllerRightVector(2)
	-- local hmdRotation = controllers.getControllerRotation(2)
	-- -- local rotator = uevrUtils.rotator(0,0,1)
	-- -- local vector = kismet_math_library:GetRightVector(rotator)
	-- print("Forward",hmdDirection.X,hmdDirection.Y, hmdDirection.Z)
	-- print("Right",hmdRightVector.X,hmdRightVector.Y, hmdRightVector.Z)
	-- --print(hmdRotationn.Pitch,hmdRotationn.Yaw, hmdRotationn.Roll)
	-- --hmdRightVector.Z * something -- 0 when not tilted -1 when titled all the way right
	-- --pawn.Mesh.RelativeLocation.Y = hmdRightVector.Z * 7
	-- --print(hmdDirection.X)
	-- --pawn.Mesh.RelativeLocation.X = -(1-hmdDirection.X) * 10
	-- --pawn.Mesh.RelativeLocation.Y = -hmdDirection.Y * 10
	-- --pawn.Mesh.RelativeLocation.Z = hmdDirection.Z * 7
	---bodyRotationOffset = UpdateBodyYaw(bodyRotationOffset, currentHeadYaw - decoupledYaw, delta)
	
	-- bodyRotationOffset = UpdateBodyYaw(bodyRotationOffset, currentHeadYaw - decoupledYaw, controllers.getControllerLocation(0),  controllers.getControllerLocation(1), hmdDirection, delta)
	-- if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
		-- pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyRotationOffset,0),false,reusable_hit_result,false)
	-- end

	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
	-- --print("Here")
		-- -- rootComponent.RelativeLocation.X = lastPosition.X
		-- -- rootComponent.RelativeLocation.Y = lastPosition.Y
		-- -- rootComponent.RelativeLocation.Z = lastPosition.Z
		-- -- rootComponent.RelativeLocation.X = rootComponent.RelativeLocation.X + deltaX
		-- -- rootComponent.RelativeLocation.Y = rootComponent.RelativeLocation.Y + deltaY
		-- rootComponent.K2_SetWorldLocation(uevrUtils.vector(lastPosition),false,reusable_hit_result,false)
	-- end
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- rootComponent:K2_AddWorldOffset(uevrUtils.vector(deltaX,deltaY,0), true, reusable_hit_result, false)
		-- deltaX = 0
		-- deltaY = 0
	-- end

end)


-- register_key_bind("F1", function()
    -- print("F1 pressed\n")
	-- --pawn:StartBulletTime(0.0, 50.0, false, 1.0, 0.4, 2.0)
	-- --rootComponent:K2_SetWorldLocation(uevrUtilsvector(lastPosition),false,reusable_hit_result,false)
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- rootComponent:K2_AddWorldOffset(uevrUtils.vector(deltaX,deltaY,0), true, reusable_hit_result, false);
	-- end
-- end)

configui.onCreateOrUpdate("headOffset", function(value)
	M.setHeadOffset(value)
end)

configui.onUpdate("headBones", function(value)
	setCurrentHeadBone(value)
end)

configui.onCreateOrUpdate("aimMethod", function(value)
	M.setAimMethod(value)
	configui.hideWidget("advanced_input", value == M.AimMethod.UEVR)
end)

configui.onCreateOrUpdate("useSnapTurn", function(value)
	M.setUseSnapTurn(value)
	configui.hideWidget("snapAngle", not value)	
	configui.hideWidget("smoothTurnSpeed", value)	
end)

configui.onCreateOrUpdate("snapAngle", function(value)
	M.setSnapAngle(value)
end)

configui.onCreateOrUpdate("smoothTurnSpeed", function(value)
	M.setSmoothTurnSpeed(value)
end)

configui.onCreateOrUpdate("pawnRotationMode", function(value)
	M.setPawnRotationMode(value)
end)

configui.onCreateOrUpdate("pawnPositionMode", function(value)
	M.setPawnPositionMode(value)
	configui.hideWidget("pawnPositionAnimationScale", value ~= M.PawnPositionMode.ANIMATED)		
end)

configui.onCreateOrUpdate("pawnPositionAnimationScale", function(value)
	M.setPawnPositionAnimationScale(value)
end)

configui.onCreateOrUpdate("adjustForAnimation", function(value)
	M.setAdjustForAnimation(value)
	configui.hideWidget("headBones", not value)		
end)

configui.onCreateOrUpdate("adjustForEyeOffset", function(value)
	M.setAdjustForEyeOffset(value)
	configui.hideWidget("eyeOffset", not value)		
end)

configui.onCreateOrUpdate("eyeOffset", function(value)
	M.setEyeOffset(value)
end)


uevrUtils.registerPreLevelChangeCallback(function(level)
	decoupledYaw = nil
	bodyRotationOffset = 0
end)

return M