#include "datascripts/inputList.lua"
#include "datascripts/keybinds.lua"
#include "scripts/ui.lua"
#include "scripts/utils.lua"
#include "scripts/textbox.lua"

local menuOpened = false
local menuOpenLastFrame = false

local rebinding = nil

local erasingBinds = 0
local erasingValues = 0

local menuWidth = 0.40 / 2
local menuHeight = 0.45

local perUnitBox = nil
local holeSizeBox = nil

function menu_init()
	
end

function menu_tick(dt)
	if PauseMenuButton(toolReadableName .. " Settings") then
		setMenuOpen(true)
	end
	
	if GetString("game.player.tool") == toolName and GetPlayerVehicle() == 0 and InputPressed(binds["Open_Menu"]) then
		setMenuOpen(not menuOpened)
	end
	
	if menuOpened and not menuOpenLastFrame then
		menuUpdateActions()
		menuOpenActions()
	end
	
	if not menuOpened and menuOpenLastFrame then
		menuCloseActions()
	end
	
	menuOpenLastFrame = menuOpened
	
	if rebinding ~= nil then
		local lastKeyPressed = getKeyPressed()
		
		if lastKeyPressed ~= nil then
			binds[rebinding] = lastKeyPressed
			rebinding = nil
		end
	end
	
	textboxClass_tick()
	
	if erasingBinds > 0 then
		erasingBinds = erasingBinds - dt
	end
end

function drawTitle()
	UiPush()
		UiFont("bold.ttf", 45)
		
		local titleText = toolReadableName .. " Settings"
		
		local titleBoxWidth, titleBoxHeight = UiGetTextSize(titleText)
		
		UiTranslate(0, -40 - titleBoxHeight / 2)
		
		UiPush()
			UiColorFilter(0, 0, 0, 0.25)
			UiImageBox("MOD/sprites/square.png", titleBoxWidth + 20, titleBoxHeight + 20, 10, 10)
		UiPop()
		
		UiText(titleText)
	UiPop()
end

function bottomMenuButtons()
	UiPush()
		UiFont("regular.ttf", 26)
	
		UiButtonImageBox("MOD/sprites/square.png", 6, 6, 0, 0, 0, 0.5)
		
		UiAlign("center bottom")
		
		local buttonWidth = 250
		
		UiPush()
			UiTranslate(0, -100)
			if erasingValues > 0 then
				UiPush()
				c_UiColor(Color4.Red)
				if UiTextButton("Are you sure?" , buttonWidth, 40) then
					resetValues()
					erasingValues = 0
				end
				UiPop()
			else
				if UiTextButton("Reset values to defaults" , buttonWidth, 40) then
					erasingValues = 5
				end
			end
		UiPop()
		
		
		UiPush()
			--UiAlign("right bottom")
			--UiTranslate(230, 0)
			UiTranslate(0, -50)
			if erasingBinds > 0 then
				UiPush()
				c_UiColor(Color4.Red)
				if UiTextButton("Are you sure?" , buttonWidth, 40) then
					resetKeybinds()
					erasingBinds = 0
				end
				UiPop()
			else
				if UiTextButton("Reset binds to defaults" , buttonWidth, 40) then
					erasingBinds = 5
				end
			end
		UiPop()
		
		
		UiPush()
			--UiAlign("left bottom")
			--UiTranslate(-230, 0)
			if UiTextButton("Close" , buttonWidth, 40) then
				menuCloseActions()
			end
		UiPop()
	UiPop()
end

function disableButtonStyle()
	UiButtonImageBox("MOD/sprites/square.png", 6, 6, 0, 0, 0, 0.5)
	UiButtonPressColor(1, 1, 1)
	UiButtonHoverColor(1, 1, 1)
	UiButtonPressDist(0)
end

function greenAttentionButtonStyle()
	local greenStrength = math.sin(GetTime() * 5) - 0.5
	local otherStrength = 0.5 - greenStrength
	
	if greenStrength < otherStrength then
		greenStrength = otherStrength
	end
	
	UiButtonImageBox("MOD/sprites/square.png", 6, 6, otherStrength, greenStrength, otherStrength, 0.5)
end

function leftSideMenu()
	UiPush()
		UiTranslate(-UiWidth() * menuWidth / 5, 0)
		
	UiPop()
end

function rightSideMenu()
	UiPush()
		UiPush()
			UiTranslate(UiWidth() * menuWidth / 5, 0)
			
			UiFont("regular.ttf", 20)
		UiPop()
	UiPop()
end

function menu_draw(dt)
	if not isMenuOpen() then
		return
	end
	
	UiMakeInteractive()
	
	UiPush()
		UiBlur(0.75)
		
		UiAlign("center middle")
		UiTranslate(UiWidth() * 0.5, UiHeight() * 0.5)
		
		UiPush()
			UiColorFilter(0, 0, 0, 0.25)
			UiImageBox("MOD/sprites/square.png", UiWidth() * menuWidth, UiHeight() * menuHeight, 10, 10)
		UiPop()
		
		UiWordWrap(UiWidth() * menuWidth)
		
		UiTranslate(0, -UiHeight() * (menuHeight / 2))
		
		drawTitle()
		
		--UiTranslate(UiWidth() * (menuWidth / 10), 0)
		
		UiFont("regular.ttf", 26)
		UiAlign("center middle")
		
		setupTextBoxes()
		
		UiTranslate(0, 50)
		
		UiPush()
			for i = 1, #bindOrder do
				local id = bindOrder[i]
				local key = binds[id]
				drawRebindable(id, key)
				UiTranslate(0, 50)
			end
		UiPop()
		
		UiTranslate(0, 50 * (#bindOrder + 1))
		textboxClass_render(perUnitBox)
		
		UiTranslate(0, 50)
		textboxClass_render(holeSizeBox)
		
		--leftSideMenu()
		
		--rightSideMenu()
	UiPop()
	
	UiPush()
		UiTranslate(UiWidth() * 0.5, UiHeight() * 0.5)
		--UiTranslate(0, -UiHeight() * (menuHeight / 2))
		UiTranslate(0, UiHeight() * (menuHeight / 2) - 10)
		
		bottomMenuButtons()
	UiPop()

	textboxClass_drawDescriptions()
end

function setupTextBoxes()
	local textBox01, newBox01 = textboxClass_getTextBox(1)
	local textBox02, newBox02 = textboxClass_getTextBox(2)
	
	if newBox01 then
		textBox01.name = "Per Unit"
		textBox01.value = GetValue("PerUnit") .. ""
		textBox01.numbersOnly = true
		textBox01.limitsActive = true
		textBox01.numberMin = 0.1
		textBox01.numberMax = 50
		textBox01.description = "Min: 0.1\nDefault: 5\nMax: 50"
		textBox01.onInputFinished = function(v) SetValue("PerUnit", tonumber(v)) end
		
		perUnitBox = textBox01
	end
	
	if newBox02 then
		textBox02.name = "Hole Size"
		textBox02.value = GetValue("HoleSize") .. ""
		textBox02.numbersOnly = true
		textBox02.limitsActive = true
		textBox02.numberMin = 0.5
		textBox02.numberMax = 10
		textBox02.description = "Min: 0.5\nDefault: 10\nMax: 50"
		textBox02.onInputFinished = function(v) SetValue("HoleSize", tonumber(v)) end
		
		holeSizeBox = textBox02
	end
end

function drawRebindable(id, key)
	UiPush()
		UiButtonImageBox("MOD/sprites/square.png", 6, 6, 0, 0, 0, 0.5)
	
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

function menuOpenActions()
	
end

function menuUpdateActions()
	--[[if resolutionBox ~= nil then
		resolutionBox.value = resolution .. ""
	end]]--
end

function menuCloseActions()
	menuOpened = false
	rebinding = nil
	erasingBinds = 0
	erasingValues = 0
	saveData(savedVars)
end

function resetValues()
	menuUpdateActions()
	
	ResetValuesToDefault()
	
	perUnitBox.value = GetValue("PerUnit") .. ""
	holeSizeBox.value = GetValue("HoleSize") .. ""
end

function isMenuOpen()
	return menuOpened
end

function setMenuOpen(val)
	menuOpened = val
end