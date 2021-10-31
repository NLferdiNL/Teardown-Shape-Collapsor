#include "datascripts/keybinds.lua"

moddataPrefix = "savegame.mod.bodycollapsor"

function saveFileInit(savedVars)
	saveVersion = GetInt(moddataPrefix .. "Version")
	
	loadKeyBinds()
	
	--[[f saveVersion < 1 or saveVersion == nil then
		saveVersion = 1
		SetInt(moddataPrefix .. "Version", saveVersion)
	end]]--
	
	loadVars(savedVars)
	saveVars(savedVars) -- Write defaults to save.
end

function saveVars(savedVars)
	for varName, varData in pairs(savedVars) do
		local currentValue = varData.current
		
		if varData.valueType == "float" then
			SetFloat(moddataPrefix .. "Var" .. varName, currentValue)
		elseif varData.valueType == "int" then
			SetInt(moddataPrefix .. "Var" .. varName, currentValue)
		elseif varData.valueType == "string" then
			SetFloat(moddataPrefix .. "Var" .. varName, currentValue)
		end
	end
end

function loadVars(savedVars)
	for varName, varData in pairs(savedVars) do
		local currentValue = nil
		
		if HasKey(moddataPrefix .. "Var" .. varName) then
			if varData.valueType == "float" then
				currentValue = GetFloat(moddataPrefix .. "Var" .. varName)
			elseif varData.valueType == "int" then
				currentValue = GetInt(moddataPrefix .. "Var" .. varName)
			elseif varData.valueType == "string" then
				currentValue = GetFloat(moddataPrefix .. "Var" .. varName)
			end
		else
			currentValue = varData.default
		end
		
		varData.current = currentValue
	end
end

function loadKeyBinds()
	for i = 1, #bindOrder do
		local currBindID = bindOrder[i]
		local boundKey = GetString(moddataPrefix .. "Keybind" .. currBindID)
		
		if boundKey == nil or boundKey == "" then
			boundKey = getFromBackup(currBindID)
		end
		
		binds[currBindID] = boundKey
	end
end

function saveKeyBinds()
	for i = 1, #bindOrder do
		local currBindID = bindOrder[i]
		local boundKey = binds[currBindID]
		
		SetString(moddataPrefix .. "Keybind" .. currBindID, boundKey)
	end
end

function saveData(savedVars)
	saveKeyBinds()
	saveVars(savedVars)
end