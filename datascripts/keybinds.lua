#include "scripts/utils.lua"

binds = {
	Shoot = "usetool",
	Alt_Fire = "rmb",
	Open_Menu = "c",
}

local bindBackup = deepcopy(binds)

bindOrder = {
	"Open_Menu"
}
		
bindNames = {
	Shoot = "Shoot",
	Open_Menu = "Open Menu",
}

function resetKeybinds()
	binds = deepcopy(bindBackup)
end

function getFromBackup(id)
	return bindBackup[id]
end