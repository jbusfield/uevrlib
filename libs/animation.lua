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
-- because we hide parts of the mesh using scale, the end of a mesh will taper to a point. We can adjust the location of that
-- point with taperOffset. For example to make a hollow arm we could use taperOffset = uevrUtils.vector(0, 0, 15)
function M.initPoseableComponent(poseableComponent, boneName, shoulderBoneName, hideBoneName, location, rotation, scale, rootBoneName, taperOffset)
	if uevrUtils.validate_object(poseableComponent) ~= nil then
		if rootBoneName == nil then 
			rootBoneName = M.getRootBoneOfBone(poseableComponent, boneName) --poseableComponent:GetBoneName(1) 
			M.print("Found root bone " .. rootBoneName:to_string())
		else
			rootBoneName = uevrUtils.fname_from_string(rootBoneName)
		end
		local boneSpace = 0

		local parentTransform = poseableComponent:GetBoneTransformByName(rootBoneName, boneSpace)
				
		if taperOffset == nil then taperOffset = uevrUtils.vector(0, 0, 0) end
		--scale the shoulder bone to almost 0 so it and its children dont display
		local localTransform = kismet_math_library:MakeTransform(kismet_math_library:Add_VectorVector(location, taperOffset), uevrUtils.rotator(0,0,0), uevrUtils.vector(0.001, 0.001, 0.001))
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(shoulderBoneName), localTransform, boneSpace, parentTransform)
		
		--apply a transform of the specified bone with respect the the tranform of the root bone of the skeleton
		local localTransform = kismet_math_library:MakeTransform(location, rotation, scale)
		M.setBoneSpaceLocalTransform(poseableComponent, uevrUtils.fname_from_string(boneName), localTransform, boneSpace, parentTransform)

		--scale the hidden bone to 0 so it and its children dont display
		poseableComponent:SetBoneScaleByName(uevrUtils.fname_from_string(hideBoneName), vector_3f(0.001, 0.001, 0.001), boneSpace);		

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
						M.print("Animating " .. boneName)
						M.setBoneSpaceLocalRotator(component, uevrUtils.fname_from_string(boneName), localRotator, boneSpace)
					end
				end
			end
		else
			M.print("Component was nil in animate")
		end
	end
end

function M.pose(animID, poseID)
	M.print("Called pose")
	if animations ~= nil and animations[animID] ~= nil  and animations[animID]["definitions"]["poses"][poseID] ~= nil then
		M.print("In pose")
		local pose = animations[animID]["definitions"]["poses"][poseID]
		for i, positions in ipairs(pose) do
			local animName = positions[1]
			local val = positions[2]
			M.animate(animID, animName, val)
			M.print("Got pose " .. i .. " " .. animID .. " " .. animName .. " " .. val)
		end
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

-- creates a set of spheres that are positioned at each bone joint in order to visualize the bone hierarchy
function M.createSkeletalVisualization(skeletalMeshComponent, scale)
	if skeletalMeshComponent ~= nil then
		if scale == nil then scale = 0.003 end
		boneVisualizers = {}
		local count = skeletalMeshComponent:GetNumBones()
		M.print("Creating Skeletal Visualization with " .. count .. " bones")
		for index = 1 , count do
			--uevrUtils.print(index .. " " .. skeletalMeshComponent:GetBoneName(index):to_string())
			boneVisualizers[index] = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere")
			boneVisualizers[index]:SetVisibility(false,true)
			boneVisualizers[index]:SetVisibility(true,true)
			boneVisualizers[index]:SetHiddenInGame(true,true)
			boneVisualizers[index]:SetHiddenInGame(false,true)
			
			uevrUtils.set_component_relative_transform(boneVisualizers[index], nil, nil, {X=scale, Y=scale, Z=scale})
		end
	end
end

--call on the tick to do the actual position update
function M.updateSkeletalVisualization(skeletalMeshComponent)
	if skeletalMeshComponent ~= nil and #boneVisualizers > 0 then
		local count = skeletalMeshComponent:GetNumBones()
		local boneSpace = 0
		--print("updateSkeletalVisualization", skeletalMeshComponent, #boneVisualizers, "\n")
		for index = 1 , count do
			local location = skeletalMeshComponent:GetBoneLocationByName(skeletalMeshComponent:GetBoneName(index), boneSpace)
			boneVisualizers[index]:K2_SetWorldLocation(location, false, reusable_hit_result, false)
			--location = skeletalMeshComponent:K2_GetComponentLocation()
			--print(location.X, location.Y, location.Z)
		end
	end
end

--scale a specific sphere in the hierarchy to a larger size and print that bone's name
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
-- end of skeletal visualization

function M.getRootBoneOfBone(skeletalMeshComponent, boneName)
	local fName = uevrUtils.fname_from_string(boneName)
	local boneName = fName
	while fName:to_string() ~= "None" do
		boneName = fName
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	return boneName
end

function M.getHierarchyForBone(skeletalMeshComponent, boneName)
	local str = ""
	local fName = uevrUtils.fname_from_string(boneName)
	while fName:to_string() ~= "None" do
		if str ~= "" then str = str .. " -> " end
		str = str .. fName:to_string()
		fName = skeletalMeshComponent:GetParentBone(fName)
	end
	-- repeat 
		-- fName = skeletalMeshComponent:GetParentBone(fName)
		-- str = str .. " -> " .. fName:to_string()
	-- until (fName == nil or fName:to_string() == "None")
	M.print(str)
end

--used by mod devs to update bone angles interactively
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
		for index = 0 , count - 1 do
			M.print(index .. " " .. component:GetBoneName(index):to_string())
		end
	else
		M.print("Can't log bone name because component was nil")
	end
end

return M