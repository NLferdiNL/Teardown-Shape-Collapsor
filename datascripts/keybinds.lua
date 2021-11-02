#include "scripts/utils.lua"

binds = {
	Shoot = "usetool",
	Alt_Fire = "rmb",
	Toggle_Mode = "r",
	Cancel_Operation = "t",
	Open_Menu = "c",
}

local bindBackup = deepcopy(binds)

bindOrder = {
	"Toggle_Mode",
	"Cancel_Operation",
	"Open_Menu",
}
		
bindNames = {
	Shoot = "Shoot",
	Alt_Fire = "Alternate Fire",
	Toggle_Mode = "Toggle Mode",
	Cancel_Operation = "Cancel Operation",
	Open_Menu = "Open Menu",
}

function resetKeybinds()
	binds = deepcopy(bindBackup)
end

function getFromBackup(id)
	return bindBackup[id]
end