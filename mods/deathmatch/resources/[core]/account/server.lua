addEventHandler("onPlayerJoin", root,
function()
    fadeCamera(source, false)
    setElementFrozen(source, true)
    showChat(source, false)
end)