local activeRental = false
local rentalTimeLeft = 0

CreateThread(function()
    for _, location in ipairs(Config.RentalLocations) do
        local npcLocation = location[1]
        local npcModel = Config.NPCModel
        RequestModel(npcModel)
        while not HasModelLoaded(npcModel) do
            Wait(100)
        end

        local npc = CreatePed(4, npcModel, npcLocation.x, npcLocation.y, npcLocation.z - 1.0, npcLocation.w, false, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedCanRagdoll(npc, false)
        FreezeEntityPosition(npc, true)
        TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)

        local blip = AddBlipForCoord(npcLocation.x, npcLocation.y, npcLocation.z)
        SetBlipSprite(blip, 226)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Biciklibérlés")
        EndTextCommandSetBlipName(blip)

        exports.ox_target:addLocalEntity(npc, {
            {
                name = "vehicle_rental",
                icon = "fas fa-car",
                label = "Bicikli bérlés",
                onSelect = function()
                    openRentalMenu() 
                end
            }
        })
    end
end)

function openRentalMenu()
    local options = {}

    for _, vehicle in ipairs(Config.RentalVehicles) do
        table.insert(options, {
            title = vehicle.label,
            description = string.format("Ár: %d$ / perc", vehicle.pricePerMinute),
            event = "vehicleRental:chooseVehicle",
            args = vehicle
        })
    end

    lib.registerContext({
        id = "rental_menu",
        title = "Bicikli bérlés",
        options = options
    })

    lib.showContext("rental_menu")
end

function getClosestSpawnPoint(playerCoords)
    local closestDistance = math.huge
    local closestPoint = nil

    for _, spawnPoint in ipairs(Config.VehicleSpawnPoints) do
        local pointCoords = Config.VehicleSpawnPoints
        local distance = #(playerCoords - pointCoords)
        if distance < closestDistance then
            closestDistance = distance
            closestPoint = spawnPoint
        end
    end

    return closestPoint
end

RegisterNetEvent("vehicleRental:chooseVehicle", function(vehicle)
    local duration = lib.inputDialog("Bérlés ideje", {"Idő (percben)"})

    if not duration or not tonumber(duration[1]) then
        lib.notify({
            title = "Hiba",
            description = "Érvénytelen időtartam!",
            type = "error"
        })
        return
    end

    local minutes = tonumber(duration[1])
    local cost = vehicle.pricePerMinute * minutes

    if lib.progressCircle({
        duration = 5000,
        label = "Fizetés, és Szerződés megírása folyamatban...",
        position = "bottom"
    }) then
        TriggerServerEvent("vehicleRental:pay", cost, vehicle, minutes)
    end
end)

RegisterNetEvent("vehicleRental:success")
AddEventHandler("vehicleRental:success", function(vehicle, minutes)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local spawnPoint = getClosestSpawnPoint(playerCoords)
    if not spawnPoint then
        lib.notify({
            title = "Hiba",
            description = "Nincs elérhető spawn pont!",
            type = "error"
        })
        return
    end

    lib.notify({
        title = "Sikeres bérlés",
        description = "Sikeresen kibérelted a járművet!",
        type = "success"
    })

    local vehicleHash = GetHashKey(vehicle.model)
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(100)
    end

    local rentedVehicle = CreateVehicle(vehicleHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    SetVehicleNumberPlateText(rentedVehicle, "RENTAL")
    TaskWarpPedIntoVehicle(playerPed, rentedVehicle, -1)

    rentalTimeLeft = minutes * 60
    activeRental = true

    CreateThread(function()
        rentalTimeLeft = rentalTimeLeft - 1

        local minutes = math.floor(rentalTimeLeft / 60)
        local seconds = rentalTimeLeft % 60
        local timeText = string.format("Hátralévő bérlési idő: %02d:%02d", minutes, seconds)

        lib.notify({
            title = "Bérlés időzítő",
            description = timeText,
            type = "info",
            duration = minutes,
            keepOpen = true 
        })

        if rentalTimeLeft <= 0 and DoesEntityExist(rentedVehicle) then
            DeleteEntity(rentedVehicle)
            lib.notify({
                title = "Bérlés vége",
                description = "A bérelt jármű eltávolítva.",
                type = "info"
            })
            activeRental = false
        end
    end)
end)

RegisterNetEvent("vehicleRental:failure")
AddEventHandler("vehicleRental:failure", function()
    lib.notify({
        title = "Hiba",
        description = "Nincs elég pénzed a bérléshez!",
        type = "error"
    })
end)