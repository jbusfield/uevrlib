local uevrUtils = require("libs/uevr_utils")

local M = {}

local animations = {}
local boneVisualizers = {}

function M.print(text)
	uevrUtils.print("[animation] " .. text)
end

function M.createPoseableComponent(skeletalMeshComponent, parent)
	local poseableComponent = nil
	if skeletalMeshComponent ~= nil then
		poseableComponent = uevrUtils.createPoseableMeshFromSkeletalMesh(skeletalMeshComponent, parent)
		
		--hack for component not initially showing
		-- poseableComponent:SetVisibility(false, true)
		-- poseableComponent:SetHiddenInGame(true, true)
		-- poseableComponent:SetVisibility(true, true) 
		-- poseableComponent:SetHiddenInGame(false, true)
		
		--fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
		--poseableComponent.BoundsScale = 8.0
		--poseableComponent.bCastDynamicShadow=false
		
		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.X = 100
		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.Y = 100
		-- poseableComponent.SkeletalMesh.PositiveBoundsExtension.Z = 100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.X = -100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.Y = -100
		-- poseableComponent.SkeletalMesh.NegativeBoundsExtension.Z = -100
	else
		M.print("SkeletalMeshComponent was not valid in createPoseableComponent")
	end

	return poseableComponent
end

-- boneName - the name of the bone that will serve as the root of the hand. It could be the hand bone or the forearm bone
-- hideBoneName - if showing the right hand then you would hide the left shoulder and vice versa
-- M.initPoseableComponent(poseableComponent, "RightForeArm", "LeftShoulder", location, rotation, scale)
function M.initPoseableComponent(poseableComponent, boneName, hideBoneName, location, rotation, scale, rootBoneName)
	if uevrUtils.validate_object(poseableComponent) ~= nil then
		if rootBoneName == nil then 
			rootBoneName = poseableComponent:GetBoneName(1) 
		else
			rootBoneName = uevrUtils.fname_from_string(rootBoneName)
		end
		local boneSpace = 0
		
		-- this is now handled by the transform below
		-- get the location of the root of the skeleton
		--location = poseableComponent:GetBoneLocationByName(poseableComponent:GetBoneName(1), boneSpace);
		--poseableComponent:SetBoneLocationByName(uevrUtils.fname_from_string(boneName), location, boneSpace);

		--apply a transform of the specified bone with respect the the tranform of the root bone of the skeleton
		local parentTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)
		local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(boneName), localTransform, boneSpace, parentTransform)

		--scale the hidden bone (eg the shoulder bone) to 0 so it and its children dont display
		poseableComponent:SetBoneScaleByName(uevrUtils.fname_from_string(hideBoneName), vector_3f(0, 0, 0), boneSpace);		
	end
end

function M.getBoneSpaceLocalRotator(component, boneFName, fromBoneSpace)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if fromBoneSpace == nil then fromBoneSpace = 0 end
		local parentTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), fromBoneSpace)
		local wTranform = component:GetBoneTransformByName(boneFName, fromBoneSpace)
		local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(parentTransform))
		local localRotator = uevrUtils.rotator(0, 0, 0)
		kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
		return localRotator, parentTransform
	end
	return nil, nil
end

function M.getChildSkeletalMeshComponent(parent, name)
	local skeletalMeshComponent = nil
	if uevrUtils.validate_object(parent) ~= nil and name ~= nil then
		local children = parent.AttachChildren
		for i, child in ipairs(children) do
			if  string.find(child:get_full_name(), name) then
				skeletalMeshComponent = child
			end
		end
	end
	return skeletalMeshComponent
end

--if you know the parent transform then pass it in to save a step
function M.setBoneSpaceLocalRotator(component, boneFName, localRotator, toBoneSpace, pTransform)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if component.GetParentBone ~= nil then
			if toBoneSpace == nil then toBoneSpace = 0 end
			if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
			local wRotator = kismet_math_library:TransformRotation(pTransform, localRotator);
			component:SetBoneRotationByName(boneFName, wRotator, toBoneSpace)
		else
			M.print("component.GetParentBone was nil for " .. component:get_full_name())
		end
	end
end

function M.setBoneSpaceLocalTransform(component, boneFName, localTransform, toBoneSpace, pTransform)
	if uevrUtils.validate_object(component) ~= nil and boneFName ~= nil then
		if toBoneSpace == nil then toBoneSpace = 0 end
		if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
		local wTransform = kismet_math_library:ComposeTransforms(localTransform, pTransform)
		component:SetBoneTransformByName(boneFName, wTransform, toBoneSpace)
	end
end

function M.hasBone(component, boneName)
	local index = component:GetBoneIndex(uevrUtils.fname_from_string(boneName))
	--print("Has bone",boneName,index,"\n")
	return index ~= -1
end

function M.animate(animID, animName, val)
	local animation = animations[animID]
	if animation ~= nil then
		local component = animation["component"]
		if component ~= nil then
			local boneSpace = 0
			local subAnim = animation["definitions"]["positions"][animName]
			if subAnim ~= nil then
				local anim = subAnim[val]
				if anim ~= nil then
					for boneName, angles in pairs(anim) do
						local localRotator = uevrUtils.rotator(angles[1], angles[2], angles[3])
						M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
					end
				end
			end
		end
	end
end

function M.pose(animID, poseID)
	local pose = animations[animID]["definitions"]["poses"][poseID]
	for i, positions in ipairs(pose) do
		local animName = positions[1]
		local val = positions[2]
		M.animate(animID, animName, val)
	end

end

function M.add(animID, skeletalMeshComponent, animationDefinitions)
	animations[animID] = {}
	animations[animID]["component"] = skeletalMeshComponent
	animations[animID]["definitions"] = animationDefinitions
end

local animStates = {}
function M.updateAnimation(animID, animName, isPressed)
	if animStates[animID] == nil then 
		animStates[animID] = {} 
		if animStates[animID][animName] == nil then 
			animStates[animID][animName] = false 
		end
	end
	if isPressed then
		if not animStates[animID][animName] then
			M.animate(animID, animName, "on")
		end
		animStates[animID][animName] = true
	else
		if animStates[animID][animName] then
			M.animate(animID, animName, "off")
		end
		animStates[animID][animName] = false
	end
end 

function M.createSkeletalVisualization(skeletalMeshComponent, scale)
	if skeletalMeshComponent ~= nil then
		if scale == nil then scale = 0.003 end
		boneVisualizers = {}
		local count = skeletalMeshComponent:GetNumBones()
		--print(count, "bones")
		for index = 1 , count do
			--uevrUtils.print(index .. " " .. skeletalMeshComponent:GetBoneName(index):to_string())
			boneVisualizers[index] = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			uevrUtils.set_component_relative_transform(boneVisualizers[index], nil, nil, {X=scale, Y=scale, Z=scale})
		end
	end
end

function M.updateSkeletalVisualization(skeletalMeshComponent)
	if skeletalMeshComponent ~= nil then
		local count = skeletalMeshComponent:GetNumBones()
		local boneSpace = 0
		for index = 1 , count do
			local location = skeletalMeshComponent:GetBoneLocationByName(skeletalMeshComponent:GetBoneName(index), boneSpace)
			boneVisualizers[index]:K2_SetWorldLocation(location, false, reusable_hit_result, false)
		end
	end
end

function M.setSkeletalVisualizationBoneScale(skeletalMeshComponent, index, scale)
	if skeletalMeshComponent ~= nil then
		if index < 1 then index = 1 end
		if index > skeletalMeshComponent:GetNumBones() then index = skeletalMeshComponent:GetNumBones() end
		uevrUtils.print("Visualizing " .. index .. " " .. skeletalMeshComponent:GetBoneName(index):to_string())
		local component = boneVisualizers[index]
		component.RelativeScale3D.X = scale
		component.RelativeScale3D.Y = scale
		component.RelativeScale3D.Z = scale
	end
end

function M.setFingerAngles(component, boneList, fingerIndex, jointIndex, angleID, angle)
	local boneSpace = 0
	local boneFName = component:GetBoneName(boneList[fingerIndex] + jointIndex - 1, boneSpace)
	
	local localRotator, pTransform = M.getBoneSpaceLocalRotator(component, boneFName, boneSpace)
	M.print(boneFName:to_string() .. " Local Space Before: " .. fingerIndex .. " " .. jointIndex .. " " .. localRotator.Pitch .. " " .. localRotator.Yaw .. " " .. localRotator.Roll)
	if angleID == 0 then
		localRotator.Pitch = localRotator.Pitch + angle
	elseif angleID == 1 then
		localRotator.Yaw = localRotator.Yaw + angle
	elseif angleID == 2 then
		localRotator.Roll = localRotator.Roll + angle
	end
	M.print(boneFName:to_string() .. " Local Space After: " .. fingerIndex .. " " .. jointIndex .. " " .. localRotator.Pitch .. " " .. localRotator.Yaw .. " " .. localRotator.Roll)
	M.setBoneSpaceLocalRotator(component, boneFName, localRotator, boneSpace, pTransform)

	M.logBoneRotators(component, boneList)
end

function M.logBoneRotators(component, boneList)
	local boneSpace = 0
	if component ~= nil then
		--local pc = component
	--local parentFName =  uevrUtils.fname_from_string("r_Hand_JNT") --pc:GetParentBone(pc:GetBoneName(1))
	--local pTransform = pc:GetBoneTransformByName(parentFName, boneSpace)
	--local pRotator = pc:GetBoneRotationByName(parentFName, boneSpace)
		local text = "Rotators for " .. component:get_full_name() .. "\n"

		for j = 1, #boneList do
			for index = 1 , 3 do
				local fName = component:GetBoneName(boneList[j] + index - 1)
				
				local pTransform = component:GetBoneTransformByName(component:GetParentBone(fName), boneSpace)
				local wTranform = component:GetBoneTransformByName(fName, boneSpace)
				--local localTransform = kismet_math_library:InvertTransform(pTransform) * wTranform
				--local localTransform = kismet_math_library:ComposeTransforms(kismet_math_library:InvertTransform(pTransform), wTranform)
				local localTransform2 = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(pTransform))
				local localRotator = uevrUtils.rotator(0, 0, 0)
				--kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
				--print("Local Space1",index, localRotator.Pitch, localRotator.Yaw, localRotator.Roll)
				kismet_math_library:BreakTransform(localTransform2,temp_vec3, localRotator, temp_vec3)
				text = text .. "[\"" .. fName:to_string() .. "\"] = {" .. localRotator.Pitch .. ", " .. localRotator.Yaw .. ", " .. localRotator.Roll .. "}" .. "\n"
				--["RightHandIndex1_JNT"] = {13.954909324646, 19.658151626587, 12.959843635559}
				-- local wRotator = pc:GetBoneRotationByName(pc:GetBoneName(index), boneSpace)
				-- --local relativeRotator = GetRelativeRotation(wRotator, pRotator) --wRotator - pRotator
				-- local relativeRotator = GetRelativeRotation(wRotator, pRotator)
				-- print("Local Space",index, relativeRotator.Pitch, relativeRotator.Yaw, relativeRotator.Roll)
				
				--[[
				print("World Space",index, wRotator.Pitch, wRotator.Yaw, wRotator.Roll)
				boneSpace = 1
				local cRotator = pc:GetBoneRotationByName(pc:GetBoneName(index), boneSpace)
				print("Component Space",index, cRotator.Pitch, cRotator.Yaw, cRotator.Roll)
				local boneRotator = uevrUtils.rotator(0, 0, 0)
				wRotator.Pitch = 0
				wRotator.Yaw = 0
				wRotator.Roll = 0
				pc:TransformToBoneSpace(pc:GetBoneName(index), temp_vec3, wRotator, temp_vec3, boneRotator)
				print("Bone Space",index, boneRotator.Pitch, boneRotator.Yaw, boneRotator.Roll)
				--pc:TransformFromBoneSpace(class FName BoneName, const struct FVector& InPosition, const struct FRotator& InRotation, struct FVector* OutPosition, struct FRotator* OutRotation);

				if pc.CachedBoneSpaceTransforms ~= nil then
					local transform = pc.CachedBoneSpaceTransforms[index]
					local boneRotator = uevrUtils.rotator(0, 0, 0)
					kismet_math_library:BreakTransform(transform, temp_vec3, boneRotator, temp_vec3)
					print("Bone Space",index, boneRotator.Pitch, boneRotator.Yaw, boneRotator.Roll)
				else
					print(pc.CachedBoneSpaceTransforms, pc.CachedComponentSpaceTransforms, pawn.FPVMesh.CachedBoneSpaceTransforms)
				end
				]]--
			end
		end
		
		M.print(text)
	end
end


function M.logBoneNames(component)
	if component ~= nil then
		local count = component:GetNumBones()
		M.print(count .. " bones for " .. component:get_full_name())
		for index = 1 , count do
			M.print(index .. " " .. component:GetBoneName(index):to_string())
		end
	end
end

return M