--TODO need to move much of uevr_utils essential calls like get_struct_object into core modules so that these utils can access them
local M = {}


-- function M.ProjectVectorOnToPlane(vec, planeNormal)
-- 	if kismet_math_library.ProjectVectorOnToPlane ~= nil then
--         return kismet_math_library:ProjectVectorOnToPlane(vec, planeNormal)
--     else
--         if vec == nil then return uevrUtils.vector(0,0,0) end
-- 			if planeNormal == nil then return vec end

-- 			-- Prefer engine helpers if present
-- 			if kismet_math_library.Dot_VectorVector and kismet_math_library.Multiply_VectorFloat and kismet_math_library.Subtract_VectorVector then
-- 				local dotVN = kismet_math_library:Dot_VectorVector(vec, planeNormal) or 0.0
-- 				local denom = kismet_math_library:Dot_VectorVector(planeNormal, planeNormal) or 0.0
-- 				if denom <= 1e-8 then return uevrUtils.vector(0,0,0) end
-- 				local scale = dotVN / denom
-- 				local comp = kismet_math_library:Multiply_VectorFloat(planeNormal, scale)
-- 				return kismet_math_library:Subtract_VectorVector(vec, comp)
-- 			end

-- 			-- Fallback: plain numeric vectors (supports {X,Y,Z} or array)
-- 			local vx = vec.X or vec[1] or 0
-- 			local vy = vec.Y or vec[2] or 0
-- 			local vz = vec.Z or vec[3] or 0
-- 			local nx = planeNormal.X or planeNormal[1] or 0
-- 			local ny = planeNormal.Y or planeNormal[2] or 0
-- 			local nz = planeNormal.Z or planeNormal[3] or 0
-- 			local dotVN = vx*nx + vy*ny + vz*nz
-- 			local denom = nx*nx + ny*ny + nz*nz
-- 			if denom <= 1e-8 then return uevrUtils.vector(0,0,0) end
-- 			local s = dotVN / denom
-- 			return uevrUtils.vector(vx - nx*s, vy - ny*s, vz - nz*s)
-- 	end
-- end

return M