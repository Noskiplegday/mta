-- Define the items table
local foodItems = {
	--drinks
    
    ["water"] = {name = "water", weight = 1, image = "[images]/foods/agua.png"},
    ["coffee"] = {name = "coffee", weight = 1, image = "[images]/foods/cafe.png"},
    ["fanta"] = {name = "fanta", weight = 1, image = "[images]/foods/energetico.png"},
    ["LemonSoda"] = {name = "LemonSoda", weight = 1, image = "[images]/foods/limonada.png"},
    
    ["wine"] = {name = "wine", weight = 1, image = "[images]/foods/absinto.png"},
    ["beer"] = {name = "beer", weight = 1, image = "[images]/foods/cerveja.png"},
    ["oldMonk"] = {name = "oldMonk", weight = 1, image = "[images]/foods/conhaque.png"},
    ["Tequila"] = {name = "Tequila", weight = 1, image = "[images]/foods/tequila.png"},
    ["Vodka"] = {name = "Vodka", weight = 1, image = "[images]/foods/vodka.png"},
    ["Whisky"] = {name = "Whisky", weight = 1, image = "[images]/foods/whisky.png"},

    ["tea"] = {name = "tea", weight = 1, image = "[images]/foods/tea.png"},
    
    --food
    
    ["Chocolate"] = {name = "Chocolate", weight = 1, image = "[images]/foods/chocolate.png"},
    ["lays"] = {name = "lays", weight = 1, image = "[images]/foods/salgadinho.png"},
    
    ["Pizza"] = {name = "Pizza", weight = 1, image = "[images]/foods/pizza.png"},
    ["burger"] = {name = "burger", weight = 1, image = "[images]/foods/lanche.png"},
    ["salad"] = {name = "salad", weight = 1, image = "[images]/foods/salada.png"},

    ["biriyani"] = {name = "biriyani", weight = 1, image = "[images]/foods/biriyani.png"},
    ["chicken"] = {name = "chicken", weight = 1, image = "[images]/foods/chickenCurry.png"},
    ["fish"] = {name = "fish", weight = 1, image = "[images]/foods/fishCurry.png"},
    ["friedRice"] = {name = "friedRice", weight = 1, image = "[images]/foods/friedRice.png"},
    ["prawn"] = {name = "prawn", weight = 1, image = "[images]/foods/prawn.png"},
    ["rice"] = {name = "rice", weight = 1, image = "[images]/foods/rice.png"},
    ["sambar"] = {name = "sambar", weight = 1, image = "[images]/foods/sambar.png"},
    ["vada"] = {name = "vada", weight = 1, image = "[images]/foods/vada.png"}
}
-- Command handler to give all items
function giveallfood(player)
    if not player then
        outputChatBox("This command can only be used by a player.", player, 255, 0, 0)
        return
    end
    -- Loop through the items table
    for itemName, itemData in pairs(foodItems) do
        if giveItem(player, itemName, 1) then
            outputChatBox("You received: " .. itemData.name, player, 0, 255, 0)
        else
            outputChatBox("Failed to give: " .. itemData.name, player, 255, 0, 0)
        end
    end
end
-- Register the command
addCommandHandler("giveallfood", giveallfood)


