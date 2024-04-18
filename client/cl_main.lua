QBCore = exports['qb-core']:GetCoreObject()

local canFish = false
local zoneFish = 0
local isFishing = false
local fishingRod

--- Method to perform fishing animation
--- @return nil
local fishAnimation = function()
    -- Remove Fishing Bait
    TriggerServerEvent('qb-fishing:server:RemoveBait')

    -- Throw Bait Animation
    local ped = PlayerPedId()
    RequestAnimDict('mini@tennis')
    while not HasAnimDictLoaded('mini@tennis') do Wait(0) end
    TaskPlayAnim(ped, 'mini@tennis', 'forehand_ts_md_far', 1.0, -1.0, 1.0, 48, 0, 0, 0, 0)
    while IsEntityPlayingAnim(ped, 'mini@tennis', 'forehand_ts_md_far', 3) do Wait(0) end

    -- Fish Animation
    RequestAnimDict('amb@world_human_stand_fishing@idle_a')
    while not HasAnimDictLoaded('amb@world_human_stand_fishing@idle_a') do Wait(0) end
    TaskPlayAnim(ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 1.0, -1.0, 1.0, 10, 0, 0, 0, 0)
    Wait(math.random(Shared.CastTimeMin, Shared.CastTimeMax) * 1000)
    
    -- Minigame
    -- exports['ps-ui']:Circle(function(success)
    --     if success then
    --         TriggerServerEvent('hud:server:RelieveStress', 2)
    --         TriggerServerEvent('qb-fishing:server:ReceiveFish')
    --     else
    --         QBCore.Functions.Notify('The fish got away!', 'error', 2500)
    --         TriggerServerEvent('hud:server:RelieveStress', 1)
    --     end
    -- end, math.random(Shared.MinigameCirclesMin, Shared.MinigameCirclesMax), Shared.MinigameTime)

    exports['boii_minigames']:skill_bar({
        style = 'default', -- Style template
        icon = 'fa-solid fa-fish', -- Any font-awesome icon; will use template icon if none is provided
        orientation = math.random(1, 2), -- Orientation of the bar; 1 = horizontal centre, 2 = vertical right.
        area_size = 20, -- Size of the target area in %
        perfect_area_size = 5, -- Size of the perfect area in %
        speed = 0.5, -- Speed the target area moves
        moving_icon = true, -- Toggle icon movement; true = icon will move randomly, false = icon will stay in a static position
        icon_speed = 3, -- Speed to move the icon if icon movement enabled; this value is / 100 in the javascript side true value is 0.03
    }, function(success) -- Game callback
        if success == 'perfect' then
            -- If perfect do something
            TriggerServerEvent('hud:server:RelieveStress', 2)
            TriggerServerEvent('qb-fishing:server:ReceiveFish', zoneFish)
            ClearPedTasks(ped)
            DeleteObject(fishingRod)
        elseif success == 'success' then
            -- If success do something
            exports['boii_minigames']:skill_bar({
                style = 'default', -- Style template
                icon = 'fa-solid fa-fish', -- Any font-awesome icon; will use template icon if none is provided
                orientation = math.random(1, 2), -- Orientation of the bar; 1 = horizontal centre, 2 = vertical right.
                area_size = 20, -- Size of the target area in %
                perfect_area_size = 5, -- Size of the perfect area in %
                speed = 0.5, -- Speed the target area moves
                moving_icon = true, -- Toggle icon movement; true = icon will move randomly, false = icon will stay in a static position
                icon_speed = 3, -- Speed to move the icon if icon movement enabled; this value is / 100 in the javascript side true value is 0.03
            }, function(success) -- Game callback
                if success == 'perfect' then
                    -- If perfect do something
                    TriggerServerEvent('hud:server:RelieveStress', 2)
                    TriggerServerEvent('qb-fishing:server:ReceiveFish', zoneFish)
                    ClearPedTasks(ped)
                    DeleteObject(fishingRod)
                elseif success == 'success' then
                    -- If success do something
                    TriggerServerEvent('hud:server:RelieveStress', 2)
                    TriggerServerEvent('qb-fishing:server:ReceiveFish', zoneFish)
                    ClearPedTasks(ped)
                    DeleteObject(fishingRod)
                elseif success == 'failed' then
                    -- If failed do something
                    QBCore.Functions.Notify('The fish got away!', 'error', 2500)
                    TriggerServerEvent('hud:server:RelieveStress', 1)
                    ClearPedTasks(ped)
                    DeleteObject(fishingRod)
                end
            end)
        elseif success == 'failed' then
            -- If failed do something
            QBCore.Functions.Notify('The fish got away!', 'error', 2500)
            TriggerServerEvent('hud:server:RelieveStress', 1)
            ClearPedTasks(ped)
            DeleteObject(fishingRod)
        end
    end)

    -- Finishing up
    -- ClearPedTasks(ped)
    -- DeleteObject(fishingRod)
    isFishing = false
end

--- Method to create a fishing rod prop and return the object
--- @return fishingRod number - Entity number
local startFishing = function()
    -- Spam Prevent
    if isFishing then return end
    isFishing = true

    -- Load Fishing Rod Model
    local fishingRodHash = `prop_fishing_rod_01`
    if not IsModelValid(fishingRodHash) then return end
    if not HasModelLoaded(fishingRodHash) then RequestModel(fishingRodHash) end
    while not HasModelLoaded do Wait(0) end

    -- Create Object and attach on player ped
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local object = CreateObject(fishingRodHash, pedCoords, true, false, false)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.05, 0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(object)
    fishingRod = object
    fishAnimation()
end

RegisterNetEvent('qb-fishing:client:FishingRod', function()
    -- Check if inside fishing zone
    if not canFish then
        QBCore.Functions.Notify('You can\'t fish over here..', 'error', 2500)
        return
    end

    -- Check if player has fishingbait
    local hasItem = QBCore.Functions.HasItem("fishingbait")
    if hasItem then
        -- Start Fishing
        startFishing()
    else
        QBCore.Functions.Notify('You need both a fishing rod and bait to start fishing..', 'error', 2500)
    end
end)

CreateThread(function()
    -- Start with empty array (for ComboZone)
    local zones = {}

    -- Create individual fishing zones and add them to the array
    for k, v in pairs(Shared.FishingZones) do
        if v.box then -- BoxZone
            zones[#zones+1] = BoxZone:Create(v.coords, v.length, v.width, {
                name = "FishingZones"..k,
                minZ = v.minZ,
                maxZ = v.maxZ,
                debugPoly = false
            })
        else -- PolyZone
            zones[#zones+1] = PolyZone:Create(v.points, {
                name = "FishingZones"..k,
                minZ = v.minZ,
                maxZ = v.maxZ,
                debugGrid = false,
            })
        end
    end

    -- Create ComboZone
    local fishingCombo = ComboZone:Create(zones, {
        name = "fishingCombo", 
        debugPoly = false
    })

    -- Enter/Exit Fishing Zone
    fishingCombo:onPlayerInOut(function(isPointInside, point, zone)
        if isPointInside then
            exports['qb-core']:DrawText('Fishing', 'left')
            canFish = true
            zoneFish = zone.id
        else
            exports['qb-core']:HideText()
            canFish = false
            zoneFish = 0
        end
    end)
end)