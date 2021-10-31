#include "scripts/utils.lua"
#include "scripts/savedata.lua"
#include "scripts/menu.lua"
#include "datascripts/keybinds.lua"
#include "datascripts/inputList.lua"

toolName = "shapecollapsor"
toolReadableName = "Shape Collapsor"

-- TODO: AaBb Destruction

local menu_disabled = false

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
	
	if isMenuOpenRightNow then
		return
	end
	
	aimLogic()
	
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

function aimLogic()
	local cameraTransform = GetPlayerCameraTransform()
	local origin = cameraTransform.pos
	local direction = TransformToParentVec(cameraTransform, Vec(0, 0, -1))
	
	local hit, hitPoint, distance, normal, shape = raycast(origin, direction)
	
	if not hit then
		return
	end
	
	local shapeBody = GetShapeBody(shape)
	
	DrawShapeOutline(shape)
	DrawShapeHighlight(shape, 0.5)
end


function collapseShape(shape)
	local shapeMin, shapeMax = GetShapeBounds(shape)
	
	local xWidth = math.abs(shapeMin[1] - shapeMax[1]) + 1
	local yWidth = math.abs(shapeMin[2] - shapeMax[2]) + 1
	local zWidth = math.abs(shapeMin[3] - shapeMax[3]) + 1
	
	local perUnit = GetValue("PerUnit")
	local holeSize = GetValue("HoleSize")
	
	if xWidth / perUnit > 50 or yWidth / perUnit > 50 or zWidth / perUnit > 50 then
		return
	end
	
	for x = -1, xWidth, perUnit do
		for y = -1, yWidth, perUnit do
			for z = -1, zWidth, perUnit do
				local currVec = VecAdd(shapeMin, Vec(x, y, z))
				MakeHole(currVec, holeSize, holeSize, holeSize)
			end
		end
	end
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