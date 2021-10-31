local textboxClass = {
	name = "TextBox",
	disabled = false,
	description = "",
	mouseOver = false,
	value = "",
	width = 100,
	height = 40,
	limitsActive = false,
	numberMin = 0,
	numberMax = 1,
	inputActive = false,
	lastInputActive = false,
	onInputFinished = nil,
}

local inputNumbers = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "-"}
local inputLetters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "space"}

local textboxes = {}

-- STYLE CONFIG

local font = "regular.ttf"

local descriptionBoxMargin = 20

local defaultTextSize = 26
local defaultDescriptionTextSize = 26

local textBoxBg = "MOD/sprites/square.png" -- "ui/common/box-outline-6.png"
local descBoxBg = "MOD/sprites/square.png" -- "ui/hud/infobox.png"

local textBoxBgBorderWidth = 0
local textBoxBgBorderHeight = 0

local textBoxDefaultTextColor = {1, 1, 1, 1}
local textBoxHoverTextColor = {1, 1, 0, 1}
local textBoxActiveTextColor = {0, 1, 0, 1}

local textBoxBgColor = {0, 0, 0, 0.5}
local textBoxDisabledBgColor = {0, 0, 0, 0.25}

local descBoxBgColor = {0, 0, 0, 0.75}
local descBoxTextColor = {1, 1, 1, 1}

-- END STYLE CONFIG

function textboxClass_tick()
	for i = 1, #textboxes do
		local textBox = textboxes[i]
		textboxClass_inputTick(textBox)
	end
end

function disableButtonStyle()
	UiButtonImageBox(textBoxBg, textBoxBgBorderWidth, textBoxBgBorderHeight, textBoxDisabledBgColor[1], textBoxDisabledBgColor[2], textBoxDisabledBgColor[3], textBoxDisabledBgColor[4])
	UiButtonPressColor(1, 1, 1)
	UiButtonHoverColor(1, 1, 1)
	UiButtonPressDist(0)	
end

function textboxClass_render(me)
	if me == nil then
		return
	end

	UiPush()
		UiFont(font, 26)
		UiAlign("left middle")
		
		local labelString = me.name
		local nameWidth, nameHeight = UiGetTextSize(labelString)
		
		UiButtonImageBox(textBoxBg, textBoxBgBorderWidth, textBoxBgBorderHeight, textBoxBgColor[1], textBoxBgColor[2], textBoxBgColor[3], textBoxBgColor[4])
		
		UiPush()
			UiAlign("right middle")
			UiText(labelString)
		UiPop()
		
		if not me.disabled then
			if textboxClass_checkMouseInRect(me) and not me.inputActive then
				UiColor(textBoxHoverTextColor[1], textBoxHoverTextColor[2], textBoxHoverTextColor[3], textBoxHoverTextColor[4])
			elseif me.inputActive then
				UiColor(textBoxActiveTextColor[1], textBoxActiveTextColor[2], textBoxActiveTextColor[3], textBoxActiveTextColor[4])
			else
				UiColor(textBoxDefaultTextColor[1], textBoxDefaultTextColor[2], textBoxDefaultTextColor[3], textBoxDefaultTextColor[4])
			end
		end
		
		UiPush()
			local fontSize = getMaxTextSize(me.value, defaultTextSize, me.width - 2)
			
			UiFont(font, fontSize)
			
			local tempVal = me.value
			
			if tempVal == "" then
				tempVal = " "
			end
			
			if me.disabled then
				disableButtonStyle()
			end
			
			if UiTextButton(tempVal, me.width, me.height) then
				if not me.disabled then
					me.inputActive = not me.inputActive
				end
			end
		UiPop()
		
		UiPush()
			if textboxClass_checkMouseInRect(me) and (me.description ~= nil and me.description ~= "") and not me.inputActive then
				me.mouseOver = true
			else
				me.mouseOver = false
			end
		UiPop()
	UiPop()
end

function textboxClass_drawDescriptions()
	UiPush()
		UiFont(font, defaultDescriptionTextSize)
	
		for i = 1, #textboxes do
			local currentTextbox = textboxes[i]
			
			if currentTextbox.mouseOver then
				currentTextbox.mouseOver = false
				
				local mX, mY = UiGetMousePos()
				UiAlign("top left")
				UiTranslate(mX, mY)
				
				local textWidth, textHeight = UiGetTextSize(currentTextbox.description)
				
				local boxWidth = mX + textWidth + descriptionBoxMargin
				
				local textOffsetX = 10
				
				if boxWidth > UiWidth() then
					UiAlign("top right")
					textOffsetX = -10
				end
				
				UiColor(descBoxBgColor[1], descBoxBgColor[2], descBoxBgColor[3], descBoxBgColor[4])
				UiImageBox(descBoxBg, textWidth + descriptionBoxMargin, textHeight + descriptionBoxMargin, 10, 10)
				
				UiTranslate(textOffsetX, 10)
				
				UiColor(descBoxTextColor[1], descBoxTextColor[2], descBoxTextColor[3], descBoxTextColor[4])
				UiText(currentTextbox.description)
			end
		end
	UiPop()
end

function textboxClass_getTextBox(id)
	if id == nil then
		return 
	end
	
	if id <= -1 then
		id = #textboxes + 1
	end
	local textBox = textboxes[id]
	local newBox = false
	
	if textBox == nil then
		textboxes[id] = deepcopy(textboxClass)
		textBox = textboxes[id]
		newBox = true
	end
	
	return textBox, newBox
end

 function textboxClass_inputTick(me)
	if me == nil then
		return
	end

 
	if me.inputActive ~= me.lastInputActive then
		me.lastInputActive = me.inputActive
	end

	if me.inputActive then
		if InputPressed("lmb") then
			textboxClass_setActiveState(me, textboxClass_checkMouseInRect(me))
		elseif InputPressed("return") then
			textboxClass_setActiveState(me, false)
		elseif InputPressed("backspace") then
			me.value = me.value:sub(1, #me.value - 1)
		else
			for j = 1, #inputNumbers do
				if InputPressed(inputNumbers[j]) then
					me.value = me.value .. inputNumbers[j]
				end
			end
			if not me.numbersOnly then
				for j = 1, #inputLetters do
					if InputPressed(inputLetters[j]) then
						local newLetter = inputLetters[j]
						
						if newLetter == "space" then
							newLetter = " "
						elseif InputDown("shift") then
							newLetter = newLetter:upper()
						end
						me.value = me.value .. newLetter
					end
				end
			end
		end
	end
end

function textboxClass_inputFinished(me)
	if me == nil then
		return true
	end

	return not me.inputActive and me.lastInputActive
end

function textboxClass_checkMouseInRect(me)
	if me == nil then
		return false
	end
	
	UiPush()
		UiAlign("left middle")
		local isInsideMe = UiIsMouseInRect(me.width, me.height)
	UiPop()
	
	return isInsideMe
end

function textboxClass_setActiveState(me, newState)
	if me == nil or newState == nil then
		return
	end

	me.inputActive = newState
	if not me.inputActive then
		if me.numbersOnly then
			if me.value == "" then
				me.value = me.numberMin .. ""
			end
			
			if me.limitsActive then
				local tempVal = tonumber(me.value)
				
				if tempVal == nil then
					me.value = me.numberMin .. ""
				elseif tempVal < me.numberMin then
					me.value = me.numberMin .. ""
				elseif tempVal > me.numberMax then
					me.value = me.numberMax .. ""
				end
			end
		end
		
		if me.lastInputActive and me.onInputFinished ~= nil then
			me.onInputFinished(me.value)
		end
	end
end

function textboxClass_anyInputActive()
	for i = 1, #textboxes do
		local textBox = textboxes[i]
		
		if textBox.inputActive then
			return true, i
		end
	end
end

function textboxClass_getTextBoxCount()
	return #textboxes
end

function getMaxTextSize(text, fontSize, maxSize, minFontSize)
	minFontSize = minFontSize or 1
	UiPush()
		UiFont(font, fontSize)
		
		local currentSize = UiGetTextSize(text)
		
		while currentSize > maxSize and fontSize > minFontSize do
			fontSize = fontSize - 0.1
			UiFont(font, fontSize)
			currentSize = UiGetTextSize(text)
		end
	UiPop()
	return fontSize, fontSize > minFontSize
end

function textboxClass_setTextBoxBg(bg, borderWidth, borderHeight, color, disabledColor)
	textBoxBg = bg or "ui/common/box-outline-6.png"
	textBoxBgBorderWidth = borderWidth or 6
	textBoxBgBorderHeight = borderHeight or 6
	textBoxBgColor = color or {1, 1, 1, 1}
	textBoxDisabledBgColor = disabledColor or {0.25, 0.25, 0.25, 1}
end

function textboxClass_setDescBoxBg(bg, color)
	descBoxBg = bg or "ui/hud/infobox.png"
	descBoxBgColor = color or {1, 1, 1, 0.75}
end