local uevrUtils = require("libs/uevr_utils")

local M = {}

local animations = {}

function M.getBoneSpaceLocalRotator(component, boneFName, fromBoneSpace)
	if component ~= nil and boneFName ~= nil then
		if fromBoneSpace == nil then fromBoneSpace = 0 end
		local pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), fromBoneSpace)
		local wTranform = component:GetBoneTransformByName(boneFName, fromBoneSpace)
		local localTransform = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(pTransform))
		local localRotator = uevrUtils.rotator(0, 0, 0)
		kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
		return localRotator, pTransform
	end
	return nil, nil
end

--if you know the parent transform then pass it in to save a step
function M.setBoneSpaceLocalRotator(component, boneFName, localRotator, toBoneSpace, pTransform)
	if component ~= nil and boneFName ~= nil then
		if toBoneSpace == nil then toBoneSpace = 0 end
		if pTransform == nil then pTransform = component:GetBoneTransformByName(component:GetParentBone(boneFName), toBoneSpace) end
		local wRotator = kismet_math_library:TransformRotation(pTransform, localRotator);
		component:SetBoneRotationByName(boneFName, wRotator, toBoneSpace)
	end
end

function M.animate(animID, animName, val)
	local component = animations[animID]["component"]
	local boneSpace = 0
	local anim = animations[animID]["definitions"]["positions"][animName][val]
	for boneName, angles in pairs(anim) do
		local localRotator = uevrUtils.rotator(angles[1], angles[2], angles[3])
		M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
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

function M.logBoneRotators(boneList)
	local boneSpace = 0
	local pc = masterPoseableComponent
	--local parentFName =  uevrUtils.fname_from_string("r_Hand_JNT") --pc:GetParentBone(pc:GetBoneName(1))
	--local pTransform = pc:GetBoneTransformByName(parentFName, boneSpace)
	--local pRotator = pc:GetBoneRotationByName(parentFName, boneSpace)
	for j = 1, #boneList do
		for index = 1 , 3 do
			local fName = pc:GetBoneName(boneList[j] + index - 1)
			local pTransform = pc:GetBoneTransformByName(pc:GetParentBone(fName), boneSpace)
			local wTranform = pc:GetBoneTransformByName(fName, boneSpace)
			--local localTransform = kismet_math_library:InvertTransform(pTransform) * wTranform
			--local localTransform = kismet_math_library:ComposeTransforms(kismet_math_library:InvertTransform(pTransform), wTranform)
			local localTransform2 = kismet_math_library:ComposeTransforms(wTranform, kismet_math_library:InvertTransform(pTransform))
			local localRotator = uevrUtils.rotator(0, 0, 0)
			--kismet_math_library:BreakTransform(localTransform,temp_vec3, localRotator, temp_vec3)
			--print("Local Space1",index, localRotator.Pitch, localRotator.Yaw, localRotator.Roll)
			kismet_math_library:BreakTransform(localTransform2,temp_vec3, localRotator, temp_vec3)
			print("[\"" .. fName:to_string() .. "\"] = {" .. localRotator.Pitch .. ", " .. localRotator.Yaw .. ", " .. localRotator.Roll .. "}")
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
-- 61      RightHandIndex1_JNT
-- 62      RightHandIndex2_JNT
-- 63      RightHandIndex3_JNT
-- 61      -8.4396343231201        2.0033404827118 110.19987487793
-- 62      -38.08088684082 -21.983268737793        119.43022155762
-- 63      -45.489593505859        -35.716114044189        124.20422363281
end

function M.logBoneNames(component)
	if component ~= nil then
		local count = component:GetNumBones()
		print(count, "bones")
		for index = 1 , count do
			print(index, component:GetBoneName(index),"\n")
		end
	end
end

return M