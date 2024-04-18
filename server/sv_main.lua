QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-fishing:server:RemoveBait', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if exports['qb-inventory']:RemoveItem(Player.PlayerData.source, 'fishingbait', 1, false) then
        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items['fishingbait'], 'remove', 1)
    end
end)

RegisterNetEvent('qb-fishing:server:ReceiveFish', function(zone)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local fishZone = zone
    local random = math.random(100) -- Random number from 1 to 100
    local item
    local xPoint = 0
    -- if random >= 1 and random <= 30 then -- 30%
    --     item = 'fish'
    -- elseif random >= 30 and random <= 37 then -- 7%
    --     item = 'fish2'
    -- elseif random >= 37 and random <= 44 then -- 7%
    --     item = 'catfish'
    -- elseif random >= 44 and random <= 51 then -- 7%
    --     item = 'goldfish'
    -- elseif random >= 51 and random <= 58 then -- 7%
    --     item = 'largemouthbass'
    -- elseif random >= 58 and random <= 65 then -- 7%
    --     item = 'redfish'
    -- elseif random >= 65 and random <= 72 then -- 7%
    --     item = 'salmon'
    -- elseif random >= 72 and random <= 79 then -- 7%
    --     item = 'stingray'
    -- elseif random >= 79 and random <= 86 then -- 7%
    --     item = 'stripedbass'
    -- elseif random >= 86 and random <= 93 then -- 7%
    --     item = 'whale'
    -- elseif random >= 93 and random <= 100 then -- 7%
    --     item = 'whale2'
    -- end

    if Shared.FishingZones[fishZone].zoneType == 'lake' then

        if random >= 1 and random <= 38 then -- 38%
            item = 'frog'
        elseif random >= 38 and random <= 75 then -- 37%
            item = 'carp'
        elseif random >= 75 and random <= 85 then -- 10%
            item = 'crayfish'
        elseif random >= 85 and random <= 95 then -- 10%
            item = 'catfish'
        elseif random >= 95 and random <= 100 then -- 5%
            item = 'snakehead'
            xPoint = 1
        end

    elseif Shared.FishingZones[fishZone].zoneType == 'river' then

        if random >= 1 and random <= 38 then -- 38%
            item = 'largemouthbass'
        elseif random >= 38 and random <= 75 then -- 37%
            item = 'pike'
        elseif random >= 75 and random <= 85 then -- 10%
            item = 'yellowperch'
        elseif random >= 85 and random <= 95 then -- 10%
            item = 'goldentrout'
        elseif random >= 95 and random <= 100 then -- 5%
            item = 'salmon'
            xPoint = 1
        end

    elseif Shared.FishingZones[fishZone].zoneType == 'ocean' then

        if random >= 1 and random <= 38 then -- 38%
            item = 'bass'
        elseif random >= 38 and random <= 75 then -- 37%
            item = 'anchovy'
        elseif random >= 75 and random <= 85 then -- 10%
            item = 'snapper'
        elseif random >= 85 and random <= 95 then -- 10%
            item = 'tuna'
        elseif random >= 95 and random <= 100 then -- 5%
            item = 'coelacanth'
            xPoint = 1
        end

    else
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Zone Error..', 'error', 2500) return
    end    

    if exports['qb-inventory']:AddItem(Player.PlayerData.source, item, 1, false) then
        -- New rep system
        -- Add 1 rep point for each fishing success.
        local newrep = Player.PlayerData.metadata["jobrep"]
        newrep.fishing = newrep.fishing + xPoint
        Player.Functions.SetMetaData("jobrep", newrep)

        TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items[item], 'add', 1)
        TriggerEvent('qb-log:server:CreateLog', 'fishing', 'Received Fish', 'blue', "**"..Player.PlayerData.name .. " (citizenid: "..Player.PlayerData.citizenid.." | id: "..Player.PlayerData.source..")** received 1x "..QBCore.Shared.Items[item].label)
    else
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'Your inventory is full already..', 'error', 2500)
    end
end)

QBCore.Functions.CreateUseableItem('fishingrod', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.Functions.GetItemByName('fishingrod') then return end
    TriggerClientEvent('qb-fishing:client:FishingRod', src)
end)
