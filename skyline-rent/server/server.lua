RegisterNetEvent("vehicleRental:pay")
AddEventHandler("vehicleRental:pay", function(cost, vehicle, minutes)
    local xPlayer = ESX.GetPlayerFromId(source)
    local cash = xPlayer.getMoney()
    local bank = xPlayer.getAccount("bank").money

    if cash >= cost then
        xPlayer.removeMoney(cost)
        TriggerClientEvent("vehicleRental:success", source, vehicle, minutes)
    elseif bank >= cost then
        xPlayer.removeAccountMoney("bank", cost)
        TriggerClientEvent("vehicleRental:success", source, vehicle, minutes)
    else
        TriggerClientEvent("vehicleRental:failure", source)
    end
end)
