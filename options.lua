local key = 'savegame.mod.quilez_laser.'

function init()
    if not GetBool(key..'everOpened') then
        SetBool(key..'everOpened', true)
        SetBool(key..'hitGlass', true)
        SetBool(key..'breakVaults', true)
        SetInt(key..'maxLaserDist', 1000)
        SetInt(key..'maxRecursion', 20)
        SetInt(key..'toolTab', 6)
    end
end

function BoolButton(text, bool)
	UiButtonImageBox('MOD/assets/images/box-light.png', 6, 6)
	if GetBool(key..bool) then
		UiColor(0.3, 1, 0.1)
		if UiTextButton(text..' - Yes', 300, 40) then
			SetBool(key..bool, false)
			UiSound('MOD/assets/sounds/pause-off.ogg')
		end
	else
		UiColor(1, 0.3, 0.1)
		if UiTextButton(text..' - No', 300, 40) then
			SetBool(key..bool, true)
			UiSound('MOD/assets/sounds/pause-on.ogg')
		end
	end
end

function ShiftInt(int, min, max, iter)
    SetInt(int, GetInt(int) + iter)
    if GetInt(int) < min then
        SetInt(int, max)
    elseif GetInt(int) > max then
        SetInt(int, min)
    end
end

function IntButton(text, int, min, max, iter)
	UiButtonImageBox('MOD/assets/images/box-light.png', 6, 6)
    UiColor(1, 1, 1)
    UiTextButton(text..' - '..GetInt(key..int), 190, 40)
    UiPush()
        UiColor(1, 0.3, 0.1)
        UiAlign('right top')
        UiTranslate(-100, 0)
        if UiTextButton('<', 50, 40) then
            ShiftInt(key..int, min, max, -iter)
            UiSound('MOD/assets/sounds/pause-off.ogg')
        end
    UiPop()
    UiPush()
        UiColor(0.3, 1, 0.1)
        UiAlign('left top')
        UiTranslate(100, 0)
        if UiTextButton('>', 50, 40) then
            ShiftInt(key..int, min, max, iter)
            UiSound('MOD/assets/sounds/pause-on.ogg')
        end
    UiPop()
end

function draw()
    UiPush()
        UiTranslate(UiCenter(), UiHeight() / 4)
        UiAlign('center top')
        UiFont('bold.ttf', 35)
        UiText('Quilez™ Laser')
        UiTranslate(0, 50)
        UiFont('regular.ttf', 20)
        UiText('Version 5.5')
        UiTranslate(0, 25)
        UiText('Special thanks to Thomasims for UMF, and for assisting with development')
        UiTranslate(0, 100)
        BoolButton('Laser Hits Glass', 'hitGlass')
        UiTranslate(0, 50)
        BoolButton('Laser Cuts Vaults', 'breakVaults')
        UiTranslate(0, 50)
        IntButton('Tool Group', 'toolTab', 1, 6, 1)
    UiPop()
end