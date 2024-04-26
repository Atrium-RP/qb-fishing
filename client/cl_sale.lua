local ped
local isSelling = false

local fish = {
    -- fish = true,
    -- fish2 = true,
    -- catfish = true,
    -- goldfish = true,
    -- largemouthbass = true,
    -- redfish = true,
    -- salmon = true,
    -- stingray = true,
    -- stripedbass = true,
    -- whale = true,
    -- whale2 = true

    frog = true,
    carp = true,
    crayfish = true,
    catfish = true,
    snakehead = true,
    largemouthbass = true,
    pike = true,
    yellowperch = true,
    goldentrout = true,
    salmon = true,
    bass = true,
    anchovy = true,
    snapper = true,
    tuna = true,
    coelacanth = true
}

RegisterNetEvent('qb-fishing:client:OpenSale', function()
    -- Anti spam
    if isSelling then return end

    -- Start with empty menu
    local menu = {
        {
            header = "Poissonnerie :",
            isMenuHeader = true,
            txt = "Vous pouvez revendre tout vos poissons ici :",
            icon = 'fas fa-dollar',
            params = {
                event = "qb-menu:closeMenu",
            }
        }
    }

    -- Add options to the menu
    local items = QBCore.Functions.GetPlayerData().items
    for k, v in pairs(items) do
        if fish[v.name] then
            menu[#menu+1] = {
                header = QBCore.Shared.Items[v.name].label,
                txt = "Quantité: "..v.amount,
                icon = "fas fa-fish-fins",
                params = {
                    event = "qb-fishing:client:SellFish",
                    args = v.name
                }
            }
        end
    end

    -- Close menu
    menu[#menu+1] = {
            header = "Quitter",
            --txt = "ESC or click to close",
            icon = 'fas fa-angle-left',
            params = {
                event = "qb-menu:closeMenu",
            }
        }

    -- Open menu
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-fishing:client:SellFish', function(itemName)
    -- Ask the player how many he wishes to sell
    local sellingAmount = exports['qb-input']:ShowInput({
        header = "Vente de "..QBCore.Shared.Items[itemName].label,
        submitText = "Confirmer",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = 'Quantité'
            }
        }
    })
    if not sellingAmount then return end
    if tonumber(sellingAmount.amount) < 0 then return end
    
    -- Check if player can sell that many
    QBCore.Functions.TriggerCallback('qb-fishing:server:CanSell', function(result)
        if result then
            -- Anti spam
            if isSelling then return end
            isSelling = true

            -- Hand off animtion
            local playerPed = PlayerPedId()
            TaskTurnPedToFaceEntity(ped, playerPed, 1.0)
            TaskTurnPedToFaceEntity(playerPed, ped, 1.0)
            Wait(1500)
            PlayAmbientSpeech1(ped, "Generic_Hi", "Speech_Params_Force")
            Wait(1000)

            FreezeEntityPosition(playerPed, true)

            -- Playerped animation
            RequestAnimDict("mp_safehouselost@")
            while not HasAnimDictLoaded("mp_safehouselost@") do Wait(0) end
            TaskPlayAnim(playerPed, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
            Wait(4000)

            -- Sell Fish
            TriggerServerEvent('qb-fishing:server:SellFish', itemName, tonumber(sellingAmount.amount))
            
            -- ped animation
            PlayAmbientSpeech1(ped, "Chat_State", "Speech_Params_Force")
            Wait(500)
            RequestAnimDict("mp_safehouselost@")
            while not HasAnimDictLoaded("mp_safehouselost@") do Wait(0) end
            TaskPlayAnim(ped, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0 )
            Wait(3000)

            FreezeEntityPosition(playerPed, false)
            isSelling = false
        else
            QBCore.Functions.Notify('Vous n\'avez pas assez de '..QBCore.Shared.Items[itemName].label, 'error', 2500)
        end
    end, itemName, tonumber(sellingAmount.amount))
end)

CreateThread(function()
    -- Blip
    local blip = AddBlipForCoord(Shared.SellLocation.x, Shared.SellLocation.y, Shared.SellLocation.z)
    SetBlipSprite (blip, 628)
    SetBlipDisplay(blip, 4)
    SetBlipScale  (blip, 0.7)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Poissonnier")
    EndTextCommandSetBlipName(blip)

    -- Load ped model
    local pedModel = `s_m_m_migrant_01`
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end

    -- Create Ped
    ped = CreatePed(0, pedModel, Shared.SellLocation.x, Shared.SellLocation.y, Shared.SellLocation.z, Shared.SellLocation.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

    -- Add qb-target interaction
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "qb-fishing:client:OpenSale",
                icon = 'fas fa-hand-holding-dollar',
                label = 'Accéder à la poissonnerie',
            },
            {
                type = "client",
                event = "qb-fishing:client:AskQuestions",
                icon = 'fas fa-question',
                label = 'Demander des conseils',
            }
        },
        distance = 1.5,
    })
end)

RegisterNetEvent('qb-fishing:client:AskQuestions', function()

    -- Check for fishing level
    local playerRep = QBCore.Functions.GetPlayerData().metadata["jobrep"]
    if not playerRep.fishing then
        playerRep.fishing = 0
    end
    local fishingRep = playerRep.fishing
    local titre = ''
    local lvl = {
        lake = false,
        river = false,
        ocean = false,
    }
    if fishingRep <= 24 then
        titre = 'Pêcheur débutant'
        lvl.lake = true
    elseif fishingRep <= 74 then
        titre = 'Pêcheur intermédiaire'
        --lvl = 2
        lvl.lake = true
        lvl.river = true
    elseif fishingRep >= 75 then
        titre = 'Maitre pêcheur'
        --lvl = 3
        lvl.lake = true
        lvl.river = true
        lvl.ocean = true
    end

    -- Start with empty menu
    local menu = {
        {
            header = "Poissonnerie :",
            isMenuHeader = true,
            txt = "Votre niveau de pêche actuel est: " .. titre ,
            icon = 'fas fa-dollar',
            params = {
                event = "qb-menu:closeMenu",
            }
        },
        {
            header = "Information sur les lacs",
            txt = "Cette zone est parfaite pour les débutants...",
            disabled = not lvl.lake,
            icon = 'fas fa-angle-right',
            params = {
                event = "qb-fishing:client:ZoneInformation",
                args = 'lake'
            }
        },
        {
            header = "Information sur les rivières",
            txt = "Cette zone demande un peu d'expérience...",
            disabled = not lvl.river,
            icon = 'fas fa-angle-right',
            params = {
                event = "qb-fishing:client:ZoneInformation",
                args = 'river'
            }
        },
        {
            header = "Information sur les océans",
            txt = "Cette zone demande beaucoup d'entrainement !",
            disabled = not lvl.ocean,
            icon = 'fas fa-angle-right',
            params = {
                event = "qb-fishing:client:ZoneInformation",
                args = 'ocean'
            }
        },
        {
            header = "Quitter",
            --txt = "ESC or click to close",
            icon = 'fas fa-angle-left',
            params = {
                event = "qb-menu:closeMenu",
            }
        }
    }
    -- Open menu
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-fishing:client:ZoneInformation', function(data)

    -- Start with empty menu
    local menu = {
        {
            header = "Poissonnerie :",
            isMenuHeader = true,
            txt = "Voici les poissons que vous pouvez trouver dans cette zone :",
            icon = 'fas fa-fish',
            params = {
                event = "qb-menu:closeMenu",
            }
        }
    }

    -- Add options to the menu
    local zoneType = data
    for k, v in pairs(Shared.fishByZone[zoneType]) do
        menu[#menu+1] = {
            header = QBCore.Shared.Items[v].label,
            --txt = "Info Blahblah: ",
            icon = "fas fa-fish-fins",
            params = {
                event = "",
            }
        }

    end

    -- Close menu
    menu[#menu+1] = {
            header = "Quitter",
            --txt = "ESC or click to close",
            icon = 'fas fa-angle-left',
            params = {
                event = "qb-menu:closeMenu",
            }
        }

    -- Open menu
    exports['qb-menu']:openMenu(menu)
end)