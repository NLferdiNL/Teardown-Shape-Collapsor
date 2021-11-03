#include "scripts/utils.lua"
#include "scripts/savedata.lua"
#include "scripts/menu.lua"
#include "datascripts/keybinds.lua"
#include "datascripts/inputList.lua"
#include "datascripts/color4.lua"

toolName = "shapecollapsor"
toolReadableName = "Shape Collapsor"

local menu_disabled = false

local aabbActive = false

local aabbMinPosSet = false
local aabbMaxPosSet = false

local aimPoint = Vec()
local aabbMinPos = Vec()
local aabbMaxPos = Vec()

local faceSprite = LoadSprite("MOD/sprites/square.png")

local red = 1
local green = 0
local blue = 0
local alpha = 1
local spriteAlpha = 0.5

local firingMode = 1
local firingModes = 2

local frontLookRot = QuatLookAt(Vec(0, 0, 0), Vec(0, 0, -1))
local topLookRot = QuatLookAt(Vec(0, 0, 0), Vec(0, -1, 0))
local sideLookRot = QuatLookAt(Vec(0, 0, 0), Vec(-1, 0, 0))

local largeOperationWarning = false

local cutModeExtraWide = 0
local cutModePerUnit = 0.5
local cutModeHoleSize = 0.5
local cutModeOverrideMax = true

savedVars = {
	PerUnit = { default = 5, current = nil, valueType = "float" },
	HoleSize = { default = 10, current = nil, valueType = "float" },
}

function init()
	saveFileInit(savedVars)
	menu_init()
	
	RegisterTool(toolName, toolReadableName, "MOD/vox/tool.vox")
	SetBool("game.tool." .. toolName .. ".enabled", true)
end

function tick(dt)
	if not menu_disabled then
		menu_tick(dt)
	end
	
	local isMenuOpenRightNow = isMenuOpen()
	
	if not canUseTool() then
		return
	end
	
	if aabbActive then
		if GetPlayerGrabShape() ~= 0 or GetPlayerGrabBody() ~= 0 then
			clearAaBbVars()
			return
		end
	
		local maxPos = nil
	
		if aabbMaxPosSet then
			maxPos = aabbMaxPos
		else
			maxPos = aimPoint
		end
		renderAabbZone(aabbMinPos, maxPos)
		
		local perUnit = cutModePerUnit
		
		if firingMode == 1 then
			perUnit = GetValue("PerUnit")
		end
		
		largeOperationWarning = checkLargeOperation(aabbMinPos, maxPos, perUnit)
	end
	
	if isMenuOpenRightNow then
		return
	end
	
	if InputPressed(binds["Toggle_Mode"]) then
		changeFiringMode()
	end
	
	if InputPressed(binds["Cancel_Operation"]) then
		clearAaBbVars()
	end
	
	handleToolBody()
	
	aimLogic()
	
	if InputPressed(binds["Alt_Fire"]) or (aabbActive and InputPressed(binds["Shoot"])) then
		altFireLogic()
		return
	end
	
	if aabbActive then
		return
	end
	
	if InputPressed(binds["Shoot"]) then
		shootLogic()
	end
end

function draw(dt)
	menu_draw(dt)
	
	if not canUseTool() then
		return
	end
	
	if largeOperationWarning then
	UiPush()
		UiFont("bold.ttf", 18)
		
		c_UiColor(Color4.Yellow)
		
		c_UiTextOutline(Color4.Black, 0.5)
		
		UiAlign("center bottom")
		UiTranslate(UiCenter(), UiMiddle() - 20)
		
		UiText("Large Operation!")
	UiPop()
	end
end

function canUseTool()
	return GetString("game.player.tool") == toolName and GetPlayerVehicle() == 0 and GetString("game.player.canusetool")
end

function handleToolBody()
	local toolBody = GetToolBody()
	
	local toolShapes = GetBodyShapes(toolBody)
	
	local redVox = toolShapes[1]
	local yellowVox = toolShapes[2]
	
	local heldPosition = Vec(0.15, -0.3, -0.5)
	local hiddenPosition = Vec(0, 0, 1)
	
	if firingMode == 1 then
		SetShapeLocalTransform(redVox, Transform(heldPosition, Quat()))
		
		SetShapeLocalTransform(yellowVox, Transform(hiddenPosition, Quat()))
	elseif firingMode == 2 then
		SetShapeLocalTransform(redVox, Transform(hiddenPosition, Quat()))
		
		SetShapeLocalTransform(yellowVox, Transform(heldPosition, Quat()))
	end
end

function shootLogic()
	local cameraTransform = GetPlayerCameraTransform()
	local origin = cameraTransform.pos
	local direction = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction)
	
	if not hit then
		return
	end
	
	largeOperationWarning = false
	
	collapseShape(shape)
	
	--local shapeBody = GetShapeBody(shape)
	
	--[[local bodyShapes = GetBodyShapes(shapeBody)
	
	for i = 1, #bodyShapes do
		collapseShape(bodyShapes[i])
	end]]--
end

function checkLargeOperation(minPos, maxPos, perUnit, maxUnit, maxSpace)
	local xWidth = math.abs(minPos[1] - maxPos[1]) / perUnit
	local yWidth = math.abs(minPos[2] - maxPos[2]) / perUnit
	local zWidth = math.abs(minPos[3] - maxPos[3]) / perUnit
	
	maxUnit = maxUnit or 50
	maxSpace = maxSpace or 30
	
	--[[DebugPrint("x " .. xWidth .. " / " .. perUnit .. " = " .. xWidth / perUnit)
	DebugPrint("y " .. yWidth .. " / " .. perUnit .. " = " .. yWidth / perUnit)
	DebugPrint("z " .. zWidth .. " / " .. perUnit .. " = " .. zWidth / perUnit)]]--
	
	local space = xWidth * zWidth * yWidth
	
	if (xWidth / perUnit > maxUnit or yWidth / perUnit > maxUnit or zWidth / perUnit > maxUnit) or space > maxSpace then
		return true
	end
	
	return false
end

function checkAxis(a, b, i)
	if a[i] > b[i] then
		local backup = b[i]
		b[i] = a[i]
		a[i] = backup
	end
end

function changeFiringMode()
	firingMode = firingMode + 1
	
	if firingMode > firingModes then
		firingMode = 1
	end
	
	if firingMode == 1 then
		red = 1
		green = 0
		blue = 0
		alpha = 1
		spriteAlpha = 0.5
	elseif firingMode == 2 then
		red = 1
		green = 1
		blue = 0
		alpha = 0.75
		spriteAlpha = 0.25
	end
end

function clearAaBbVars()
	aabbActive = false
	aabbMinPosSet = false
	aabbMaxPosSet = false
	largeOperationWarning = false
end

function altFireLogic()
	if aabbActive and aabbMinPosSet and aabbMaxPosSet then
		clearAaBbVars()
		
		checkAxis(aabbMinPos, aabbMaxPos, 1)
		checkAxis(aabbMinPos, aabbMaxPos, 2)
		checkAxis(aabbMinPos, aabbMaxPos, 3)
		
		if firingMode == 1 then
			collapseAaBb(aabbMinPos, aabbMaxPos)
		elseif firingMode == 2 then
			cutOutAaBb(aabbMinPos, aabbMaxPos)
		end
		
		return
	end
	
	local cameraTransform = GetPlayerCameraTransform()
	local origin = cameraTransform.pos
	local direction = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction)
	
	if not hit then
		return
	end
	
	aabbActive = true
	
	if not aabbMinPosSet then
		aabbMinPosSet = true
		aabbMinPos = VecCopy(hitPoint)
	elseif not aabbMaxPosSet then
		aabbMaxPosSet = true
		aabbMaxPos = VecCopy(hitPoint)
	end
end

function aimLogic()
	local cameraTransform = GetPlayerCameraTransform()
	local origin = cameraTransform.pos
	local direction = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction)
	
	if not hit then
		if not aabbActive then
			largeOperationWarning = false
		end
		return
	end
	
	local shapeBody = GetShapeBody(shape)
	
	aimPoint = VecCopy(hitPoint)
	
	local shapeMin, shapeMax = GetShapeBounds(shape)
	
	largeOperationWarning = checkLargeOperation(shapeMin, shapeMax, GetValue("PerUnit"), 5)
	
	if not aabbActive then
		DrawShapeOutline(shape)
		DrawShapeHighlight(shape, 0.5)
	end
end

function cutOutAaBb(minPos, maxPos)
	local xWidth, yWidth, zWidth, cRBT, cRBB, 
		  cRFT, cRFB, cLBT, cLBB, cLFT, cLFB = getAaBbCorners(minPos, maxPos, 1)
	
	-- front
	collapseAaBb(cLFT, cRFB, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
	
	-- back
	collapseAaBb(cLBT, cRBB, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
	
	-- left
	collapseAaBb(cLFT, cLBB, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
	
	-- right
	collapseAaBb(cRFT, cRBB, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
	
	-- top
	collapseAaBb(cLFT, cRBT, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
	
	-- bottom
	collapseAaBb(cLFB, cRBB, cutModeExtraWide, cutModePerUnit, cutModeHoleSize, cutModeOverrideMax)
end

function collapseShape(shape)
	local shapeMin, shapeMax = GetShapeBounds(shape)
	
	collapseAaBb(shapeMin, shapeMax)
end

function collapseAaBb(minPos, maxPos, extraWide, perUnit, holeSize, overrideMax, offset)
	extraWide = extraWide or 0
	perUnit = perUnit or GetValue("PerUnit")
	holeSize = holeSize or GetValue("HoleSize")
	overrideMax = overrideMax or false
	offset = offset or 0.5

	local xWidth = math.abs(minPos[1] - maxPos[1])
	local yWidth = math.abs(minPos[2] - maxPos[2])
	local zWidth = math.abs(minPos[3] - maxPos[3])
	
	xWidth = xWidth + extraWide
	yWidth = yWidth + extraWide
	zWidth = zWidth + extraWide

	--[[if checkLargeOperation(minPos, maxPos, perUnit) and not overrideMax then
		return
	end]]--
	
	local dirToMin = VecDir(minPos, maxPos)
	minPos = VecAdd(minPos, VecScale(dirToMin, offset * perUnit))
	
	local startIndex = -extraWide
	
	for x = startIndex, xWidth, perUnit do
		for y = startIndex, yWidth, perUnit do
			for z = startIndex, zWidth, perUnit do
				local currVec = VecAdd(minPos, Vec(x, y, z))
				--SpawnParticle(currVec, Vec(), 50)
				MakeHole(currVec, holeSize, holeSize, holeSize)
			end
		end
	end
end

function getAaBbCorners(minPos, maxPos, extraWide)
	if extraWide ~= nil and extraWide ~= 0 then
		local dirToMin = VecDir(maxPos, minPos)
		local dirToMax = VecDir(minPos, maxPos)
		minPos = VecAdd(minPos, VecScale(dirToMin, extraWide))
		maxPos = VecAdd(maxPos, VecScale(dirToMax, extraWide))
	end

	local xWidth = -(minPos[1] - maxPos[1])
	local yWidth = -(minPos[2] - maxPos[2])
	local zWidth = -(minPos[3] - maxPos[3])

	local cRBT = VecAdd(maxPos, Vec(0, -yWidth, 0)) 	--corner right back top cRBT
	local cRBB = maxPos 								-- corner right back bottom cRBB
	
	local cRFT = VecAdd(minPos, Vec(xWidth, 0, 0)) 		-- corner right front top cRFT
	local cRFB = VecAdd(maxPos, Vec(0, 0, -zWidth)) 	-- corner right front bottom cRFB
	
	local cLBT = VecAdd(minPos, Vec(0, 0, zWidth)) 		-- corner left back top cLBT
	local cLBB = VecAdd(minPos, Vec(0, yWidth, zWidth)) -- corner left back bottom cLBB
	
	local cLFT = minPos 								-- corner left front top cLFT
	local cLFB = VecAdd(minPos, Vec(0, yWidth, 0)) 		-- corner left front bottom cLFB
	
	return xWidth, yWidth, zWidth, cRBT, cRBB, cRFT, cRFB, cLBT, cLBB, cLFT, cLFB
end

function renderAabbZone(minPos, maxPos)
	local xWidth, yWidth, zWidth, cRBT, cRBB, 
		  cRFT, cRFB, cLBT, cLBB, cLFT, cLFB = getAaBbCorners(minPos, maxPos)

	local frontFace = VecLerp(cLFT, cRFB, 0.5)
	local backFace = VecLerp(cLBT, cRBB, 0.5)
	
	local leftFace = VecLerp(cLFT, cLBB, 0.5)
	local rightFace = VecLerp(cRFT, cRBB, 0.5)
	
	local topFace = VecLerp(cLFT, cRBT, 0.5)
	local bottomFace = VecLerp(cLFB, cRBB, 0.5)

	DebugLine(cRBT, cRBB, red, green, blue, alpha)
	DebugLine(cRFT, cRFB, red, green, blue, alpha)
	DebugLine(cLBT, cLBB, red, green, blue, alpha)
	DebugLine(cLFT, cLFB, red, green, blue, alpha)
	
	DebugLine(cRBT, cLBT, red, green, blue, alpha)
	DebugLine(cLBB, cRBB, red, green, blue, alpha)
	
	DebugLine(cRFT, cLFT, red, green, blue, alpha)
	DebugLine(cLFB, cRFB, red, green, blue, alpha)
	
	DebugLine(cRFT, cRBT, red, green, blue, alpha)
	DebugLine(cRFB, cRBB, red, green, blue, alpha)
	
	DebugLine(cLFT, cLBT, red, green, blue, alpha)
	DebugLine(cLFB, cLBB, red, green, blue, alpha)
	
	renderFace(frontFace, frontLookRot, xWidth, yWidth)
	renderFace(backFace, frontLookRot, xWidth, yWidth)
	
	renderFace(leftFace, sideLookRot, zWidth, yWidth)
	renderFace(rightFace, sideLookRot, zWidth, yWidth)
	
	renderFace(topFace, topLookRot, xWidth, zWidth)
	renderFace(bottomFace, topLookRot, xWidth, zWidth)
end

function renderFace(pos, rot, xWidth, yWidth)
	DrawSprite(faceSprite, Transform(pos, rot), xWidth, yWidth, red, green, blue, spriteAlpha, false, false)
end

function GetValue(name)
	if savedVars[name] == nil then
		DebugPrint(toolReadableName.. " Error: " .. name .. " value not found!")
	end
	
	return savedVars[name].current
end

function SetValue(name, value)
	if savedVars[name] == nil then
		DebugPrint(toolReadableName.. " Error: " .. name .. " value not found!")
	end
	
	savedVars[name].current = value
end

function ResetValueToDefault(name)
	if savedVars[name] == nil then
		DebugPrint(toolReadableName.. " Error: " .. name .. " value not found!")
	end
	
	savedVars[name].current = savedVars[name].default
end

function ResetValuesToDefault()
	for varName, varData in pairs(savedVars) do
		ResetValueToDefault(varName)
	end
end