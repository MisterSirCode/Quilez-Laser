local key = 'savegame.mod.quilez_laser.'

function init()
    if not GetBool(key..'everOpened') then
        SetBool(key..'everOpened', true)
        SetBool(key..'hitGlass', true)
        SetBool(key..'breakVaults', true)
        SetInt(key..'maxLaserDist', 1000)
        SetInt(key..'maxRecursion', 20)
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

function draw()
    UiPush()
        UiTranslate(UiCenter(), UiHeight() / 4)
        UiAlign('center top')
        UiFont('bold.ttf', 35)
        UiText('Quilez™ Laser')
        UiTranslate(0, 50)
        UiFont('regular.ttf', 20)
        UiText('Version 5.2')
        UiTranslate(0, 100)
        BoolButton('Laser Hits Glass', 'hitGlass')
        UiTranslate(0, 50)
        BoolButton('Laser Cuts Vaults', 'breakVaults')
        UiTranslate(0, 50)
        BoolButton('Debug - everOpened', 'everOpened')
    UiPop()
end