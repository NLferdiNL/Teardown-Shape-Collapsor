#include "scripts/utils.lua"
#include "scripts/savedata.lua"
#include "scripts/menu.lua"
#include "datascripts/keybinds.lua"
#include "datascripts/inputList.lua"

toolName = "shapecollapsor"
toolReadableName = "Shape Collapsor"

-- TODO: AaBb Get faces and render sprites on them.

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

savedVars = {
	PerUnit = { default = 2, current = nil, valueType = "float" },
	HoleSize = { default = 5, current = nil, valueType = "float" },
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
	
	if GetString("game.player.tool") ~= toolName or GetPlayerVehicle() ~= 0 then
		return
	end
	
	if aabbActive then
		renderAabbZone()
	end
	
	if isMenuOpenRightNow then
		return
	end
	
	aimLogic()
	
	if InputPressed(binds["Alt_Fire"]) then
		altFireLogic()
		return
	end
	
	if InputPressed(binds["Shoot"]) then
		shootLogic()
	end
end

function draw(dt)
	menu_draw(dt)
end


function shootLogic()
	local cameraTransform = GetPlayerCameraTransform()
	local origin = cameraTransform.pos
	local direction = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction)
	
	if not hit then
		return
	end
	
	collapseShape(shape)
	
	--local shapeBody = GetShapeBody(shape)
	
	--[[local bodyShapes = GetBodyShapes(shapeBody)
	
	for i = 1, #bodyShapes do
		collapseShape(bodyShapes[i])
	end]]--
end

function checkAxis(a, b, i)
	if a[i] > b[i] then
		local backup = b[i]
		b[i] = a[i]
		a[i] = backup
	end
end

function altFireLogic()
	if aabbActive and aabbMinPosSet and aabbMaxPosSet then
		aabbActive = false
		aabbMinPosSet = false
		aabbMaxPosSet = false
		
		checkAxis(aabbMinPos, aabbMaxPos, 1)
		checkAxis(aabbMinPos, aabbMaxPos, 2)
		checkAxis(aabbMinPos, aabbMaxPos, 3)
		
		collapseAaBb(aabbMinPos, aabbMaxPos)
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
		return
	end
	
	local shapeBody = GetShapeBody(shape)
	
	aimPoint = VecCopy(hitPoint)
	
	DrawShapeOutline(shape)
	DrawShapeHighlight(shape, 0.5)
end


function collapseShape(shape)
	local shapeMin, shapeMax = GetShapeBounds(shape)
	
	collapseAaBb(shapeMin, shapeMax)
end

function collapseAaBb(minPos, maxPos)
	local xWidth = math.abs(minPos[1] - maxPos[1]) + 1
	local yWidth = math.abs(minPos[2] - maxPos[2]) + 1
	local zWidth = math.abs(minPos[3] - maxPos[3]) + 1
	
	local perUnit = GetValue("PerUnit")
	local holeSize = GetValue("HoleSize")
	
	if xWidth / perUnit > 50 or yWidth / perUnit > 50 or zWidth / perUnit > 50 then
		return
	end
	
	for x = -1, xWidth, perUnit do
		for y = -1, yWidth, perUnit do
			for z = -1, zWidth, perUnit do
				local currVec = VecAdd(minPos, Vec(x, y, z))
				--SpawnParticle(currVec, Vec(), 50)
				MakeHole(currVec, holeSize, holeSize, holeSize)
			end
		end
	end
end

function renderAabbZone()
	local maxPos = nil
	
	if aabbMaxPosSet then
		maxPos = aabbMaxPos
	else
		maxPos = aimPoint
	end

	local xWidth = -(aabbMinPos[1] - maxPos[1])
	local yWidth = -(aabbMinPos[2] - maxPos[2])
	local zWidth = -(aabbMinPos[3] - maxPos[3])

	local cornerRightBackTop = VecAdd(maxPos, Vec(0, -yWidth, 0))
	local cornerRightBackBottom = maxPos
	
	local cornerRightFrontTop = VecAdd(aabbMinPos, Vec(xWidth, 0, 0))
	local cornerRightFrontBottom = VecAdd(maxPos, Vec(0, 0, -zWidth))
	
	local cornerLeftBackTop = VecAdd(aabbMinPos, Vec(0, 0, zWidth))
	local cornerLeftBackBottom = VecAdd(aabbMinPos, Vec(0, yWidth, zWidth))
	
	local cornerLeftFrontTop = aabbMinPos
	local cornerLeftFrontBottom = VecAdd(aabbMinPos, Vec(0, yWidth, 0))
	
	local frontFace = VecLerp(cornerLeftFrontTop, cornerRightFrontBottom, 0.5)
	local backFace = VecLerp(cornerLeftBackTop, cornerRightBackBottom, 0.5)
	
	local leftFace = VecLerp(cornerLeftFrontTop, cornerLeftBackBottom, 0.5)
	local rightFace = VecLerp(cornerRightFrontTop, cornerRightBackBottom, 0.5)
	
	local topFace = VecLerp(cornerLeftFrontTop, cornerRightBackTop, 0.5)
	local bottomFace = VecLerp(cornerLeftFrontBottom, cornerRightBackBottom, 0.5)

	DebugLine(cornerRightBackTop, cornerRightBackBottom, red, green, blue, alpha)
	DebugLine(cornerRightFrontTop, cornerRightFrontBottom, red, green, blue, alpha)
	DebugLine(cornerLeftBackTop, cornerLeftBackBottom, red, green, blue, alpha)
	DebugLine(cornerLeftFrontTop, cornerLeftFrontBottom, red, green, blue, alpha)
	
	DebugLine(cornerRightBackTop, cornerLeftBackTop, red, green, blue, alpha)
	DebugLine(cornerLeftBackBottom, cornerRightBackBottom, red, green, blue, alpha)
	
	DebugLine(cornerRightFrontTop, cornerLeftFrontTop, red, green, blue, alpha)
	DebugLine(cornerLeftFrontBottom, cornerRightFrontBottom, red, green, blue, alpha)
	
	DebugLine(cornerRightFrontTop, cornerRightBackTop, red, green, blue, alpha)
	DebugLine(cornerRightFrontBottom, cornerRightBackBottom, red, green, blue, alpha)
	
	DebugLine(cornerLeftFrontTop, cornerLeftBackTop, red, green, blue, alpha)
	DebugLine(cornerLeftFrontBottom, cornerLeftBackBottom, red, green, blue, alpha)
	
	--SpawnParticle(frontFace, Vec(), 1)
	local frontLookRot = QuatLookAt(Vec(0, 0, 0), Vec(0, 0, -1))
	local topLookRot = QuatLookAt(Vec(0, 0, 0), Vec(0, -1, 0))
	local sideLookRot = QuatLookAt(Vec(0, 0, 0), Vec(-1, 0, 0))
	
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