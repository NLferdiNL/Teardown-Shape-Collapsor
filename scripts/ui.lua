#include "datascripts/color4.lua"

function c_UiColor(color4)
	UiColor(color4.r, color4.g, color4.b, color4.a)
end

function c_UiColorFilter(color4)
	UiColorFilter(color4.r, color4.g, color4.b, color4.a)
end

function c_UiTextOutline(color4, thickness)
	thickness = thickness or 0.1
	
	UiTextOutline(color4.r, color4.g, color4.b, color4.a, thickness)
end

function c_UiTextShadow(color4, distance, blur)
	distance = distance or 1.0
	blur = blur or 0.5
	
	UiTextShadow(color4.r, color4.g, color4.b, color4.a, distance, blur)
end

function c_UiButtonImageBox(path, borderWidth, borderHeight, color4)
	color4 = color4 or Color4.White
	
	UiButtonImageBox(path, borderWidth, borderHeight, color4.r, color4.g, color4.b, color4.a)
end

function c_UiButtonHoverColor(color4)
	UiButtonHoverColor(color4.r, color4.g, color4.b, color4.a)
end

function c_UiButtonPressColor(color4)
	UiButtonPressColor(color4.r, color4.g, color4.b, color4.a)
end

function drawToggle(label, value, callback)
	local enabledText = "Enabled"
	local disabledText = "Disabled"

	UiPush()
		UiButtonImageBox("MOD/sprites/square.png", 6, 6, 0, 0, 0, 0.5)
		
		if UiTextButton(label .. " " .. (value and enabledText or disabledText), 250, 40) then
			callback(not value)
		end
	UiPop()
end

function drawToggleBox(value, callback)
	UiPush()
		local image = "ui/common/box-outline-6.png"
		
		if UiImageButton(image, 120, 120) then
			callback(not value)
		end
		
		if value then
			UiPush()
				UiColorFilter(0, 1, 0)
				UiImageBox("ui/terminal/checkmark.png", 25, 25, 0, 0)
			UiPop()
		end
	UiPop()
end


function c_DrawBodyOutline(handle, color4)
	DrawBodyOutline(handle, color4.r, color4.g, color4.b, color4.a)
end

function c_DrawShapeOutline(handle, color4)
	DrawShapeOutline(handle, color4.r, color4.g, color4.b, color4.a)
end

function c_DebugCross(pos, color4)
	DebugCross(pos, color4.r, color4.g, color4.b, color4.a)
end

function c_DrawLine(a, b, color4)
	DrawLine(a, b, color4.r, color4.g, color4.b, color4.a)
end

function c_DebugLine(a, b, color4)
	DebugLine(a, b, color4.r, color4.g, color4.b, color4.a)
end