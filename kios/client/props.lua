Props = {}

local validModels = {}

---Returns a model hash that exists, falling back to Config.fallbackModel.
---@return integer hash, boolean valid
function Props.model(name)
    if validModels[name] == nil then
        local hash = joaat(name)
        validModels[name] = IsModelInCdimage(hash) and IsModelValid(hash)
        if not validModels[name] then
            print(('[kios] ^3model "%s" does not exist, using %s instead^0'):format(name, Config.fallbackModel))
        end
    end
    if validModels[name] then return joaat(name), true end
    return joaat(Config.fallbackModel), false
end

---Spawns a local (non-networked) frozen prop.
---@param name string
---@param coords vector3
---@param heading number
---@param opts? { collision?: boolean, rot?: vector3, dynamic?: boolean }
---@return integer? entity
function Props.spawn(name, coords, heading, opts)
    opts = opts or {}
    local hash = Props.model(name)
    if not pcall(lib.requestModel, hash, 5000) then return end
    local obj = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if obj == 0 then return end
    if opts.rot and (opts.rot.x ~= 0.0 or opts.rot.y ~= 0.0 or opts.rot.z ~= 0.0) then
        SetEntityRotation(obj, opts.rot.x, opts.rot.y, heading + opts.rot.z, 2, false)
    else
        SetEntityHeading(obj, heading)
    end
    if not opts.dynamic then FreezeEntityPosition(obj, true) end
    if not opts.collision then SetEntityCollision(obj, false, false) end
    return obj
end

function Props.delete(obj)
    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
end

function Props.deleteAll(list)
    if not list then return end
    for _, obj in pairs(list) do Props.delete(obj) end
end

---Unit direction vector of a camera rotation.
function Props.rotToDir(rot)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(x))
    return vec3(-math.sin(z) * c, math.cos(z) * c, math.sin(x))
end

function Props.camera()
    return GetFinalRenderedCamCoord(), Props.rotToDir(GetFinalRenderedCamRot(2))
end

---Synchronous ray from the camera centre.
---@param flags integer 1 = world, 16 = objects
---@return boolean hit, vector3 coords, integer entity, vector3 normal
function Props.camRay(flags, distance, ignore)
    local from, dir = Props.camera()
    local to = from + dir * distance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore or cache.ped, 4)
    local _, hit, coords, normal, entity = GetShapeTestResult(handle)
    return hit == 1, coords, entity, normal
end

function Props.playAnim(anim)
    if not anim then return end
    if not pcall(lib.requestAnimDict, anim.dict, 3000) then return end
    TaskPlayAnim(cache.ped, anim.dict, anim.name, 8.0, -8.0, anim.duration or -1, anim.flag or 48, 0.0, false, false, false)
    RemoveAnimDict(anim.dict)
end
