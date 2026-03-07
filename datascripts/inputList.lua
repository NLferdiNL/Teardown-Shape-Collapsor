#version 2

local filteredKeys = { esc = "f", 
					   lmb = "f", 
					   mmb = "f", 
					   rmb = "f", 
					   space = "f", 
					   any = "f", 
					}

function isFilteredKey(key)
	return filteredKeys[key] ~= nil or tonumber(key) ~= nil
end

function getKeyPressed()
	local pressedKey = InputLastPressedKey(0):lower()
	
	if pressedKey == nil or pressedKey == "" then
		return nil
	end
	
	if isFilteredKey(pressedKey) then
		return nil
	end
	
	return pressedKey
end