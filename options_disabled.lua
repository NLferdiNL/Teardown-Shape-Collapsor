#include "scripts/ui.lua"
#include "scripts/savedata.lua"
#include "scripts/textbox.lua"
#include "datascripts/keybinds.lua"
#include "datascripts/inputList.lua"
#include "datascripts/color4.lua"

local modname = "DestructOrb"

local resettingBinds = 0
local rebinding = nil

local resolutionBox = nil

function init()
	saveFileInit()
	textboxClass_setTextBoxBg()
	textboxClass_setDescBoxBg()
end

function draw()
	UiPush()
		UiTranslate(UiWidth(), UiHeight())
		UiTranslate(-50, 3 * -50)
		UiAlign("right bottom")
	
		UiFont("regular.ttf", 26)
		
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
		
		if UiTextButton("Reset to default", 200, 50) then
			-- DEFAULTS
			resetKeybinds()
		end
		
		UiTranslate(0, 60)
		
		if UiTextButton("Save and exit", 200, 50) then
			saveKeyBinds()
			Menu()
		end
		
		UiTranslate(0, 60)
		
		if UiTextButton("Cancel", 200, 50) then
			Menu()
		end
	UiPop()
	
	UiPush()
		UiWordWrap(400)
	
		UiTranslate(UiCenter(), 50)
		UiAlign("center middle")
	
		UiFont("bold.ttf", 48)
		UiTranslate(0, 50)
		UiText(modname)
	
		UiTranslate(0, 100)
		
		UiFont("regular.ttf", 26)
		
		setupTextBoxes()
		
		UiPush()
			UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
			
			if resettingBinds > 0 then
				UiColor(1, 0, 0, 1)
				if UiTextButton("Are you sure?") then
					resetKeybinds()
					resettingBinds = 0
				end
			else
				if UiTextButton("Reset Keybinds") then
					resettingBinds = 5
				end
			end
		UiPop()
		
		UiTranslate(0, 50)
		
		UiPush()
			UiTranslate(0, 50)
			for i = 1, #bindOrder do
				local id = bindOrder[i]
				local key = binds[id]
				drawRebindable(id, key)
				UiTranslate(0, 50)
			end
		UiPop()
		
		UiTranslate(0, 50 * (#bindOrder + 1))
		
		textboxClass_render(resolutionBox)
	UiPop()
	
	textboxClass_drawDescriptions()
end

function tick(dt)
	textboxClass_tick()
	
	if resettingBinds > 0 then
		resettingBinds = resettingBinds - dt
	end
	
	if rebinding ~= nil then
		local lastKeyPressed = getKeyPressed()
		
		if lastKeyPressed ~= nil then
			binds[rebinding] = lastKeyPressed
			rebinding = nil
		end
	end
end

function setupTextBoxes()
	local textBox01, newBox01 = textboxClass_getTextBox(1)
	
	if newBox01 then
		textBox01.name = "Resolution"
		textBox01.value = resolution .. ""
		textBox01.numbersOnly = true
		textBox01.limitsActive = true
		textBox01.numberMin = 1
		textBox01.numberMax = 500
		textBox01.description = "The amount of pixels wide and high.\n Min: 1\nDefault: 50\nMax: 500"
		textBox01.onInputFinished = function(v) resolution = tonumber(v) end
		
		resolutionBox = textBox01
	end
end

function drawRebindable(id, key)
	UiPush()
		UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	
		--UiTranslate(UiWidth() * menuWidth / 1.5, 0)
	
		UiAlign("right middle")
		UiText(bindNames[id] .. "")
		
		--UiTranslate(UiWidth() * menuWidth * 0.1, 0)
		
		UiAlign("left middle")
		
		if rebinding == id then
			c_UiColor(Color4.Green)
		else
			c_UiColor(Color4.Yellow)
		end
		
		if UiTextButton(key:upper(), 40, 40) then
			rebinding = id
		end
	UiPop()
end