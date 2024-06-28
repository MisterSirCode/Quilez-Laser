#include "umf_complete_c.lua"

local Tool = {
    printname = "Quilez™ Laser",
    group = 6
}

function Tool:Initialize()
	SetString("game.tool.quilezlaser.ammo.display", "")
end

function Tool:Animate()
    local arm = self.armature
    local target = PLAYER:GetCamera():Raycast(maxDist, -1)
    local pointer = self:GetPredictedTransform():ToLocal(target.hitpos)
    arm:SetBoneTransform("root", Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), pointer)))
end

function Tool:Tick(dt)
	if GetBool("game.player.canusetool") then
        --DebugPrint('Tool On')
		SetToolTransform(Transform(Vec(0.8, -0.6, -1.0), QuatEuler(0, 0, 0)))
	end
end

Tool.model = {
    prefab = [[
<prefab version="1.6.0">
	<group name="Laser" pos="0.0 0.0 0.0" rot="0.0 0.0 180.0">
		<location name="nozzle" pos="0.0 0.0 -0.05"/>
		<group name="Chamber" pos="-0.06 -0.025 0.15">
			<vox pos="0.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.05 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.035355 0.085355 0.0" rot="0.0 0.0 -90.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.085355 0.085355 0.0" rot="180.0 180.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.12071 0.05 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.12071 0.0 0.0" rot="180.0 -180.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.085355 -0.035355 0.0" rot="0.0 -360.0 90.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.035355 -0.035355 0.0" rot="0.0 0.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.0 0.05 0.0" rot="0.0 0.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
		</group>
		<group name="Chamber" pos="0.0 0.0 0.15" rot="0.0 0.0 22.5">
			<vox pos="-0.06 -0.025 0.0" rot="0.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="-0.01 -0.025 0.0" rot="0.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="-0.024645 0.060355 0.0" rot="0.0 0.0 -90.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.025355 0.060355 0.0" rot="-180.0 -180.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.06071 0.025 0.0" rot="180.0 180.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.06071 -0.025 0.0" rot="-180.0 180.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="0.025355 -0.060355 0.0" rot="0.0 360.0 90.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="-0.024645 -0.060355 0.0" rot="0.0 0.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
			<vox pos="-0.06 0.025 0.0" rot="0.0 0.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit" scale="0.5"/>
		</group>
		<group name="Rim" pos="-0.077 -0.025 -0.05">
			<vox file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 -0.04045 0.0" rot="0.0 0.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 -0.0559 0.0" rot="0.0 0.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 -0.04045 0.0" rot="-180.0 -180.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.0 0.0" rot="-180.0 -180.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.05 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 0.09045 0.0" rot="-180.0 -180.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 0.1059 0.0" rot="-180.0 -180.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 0.09045 0.0" rot="0.0 0.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.0 0.05 0.0" rot="0.0 0.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
		</group>
		<group name="Rim" pos="-0.077 -0.025 0.4">
			<vox file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 -0.04045 0.0" rot="0.0 0.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 -0.0559 0.0" rot="0.0 0.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 -0.04045 0.0" rot="-180.0 -180.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.0 0.0" rot="-180.0 -180.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.05 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 0.09045 0.0" rot="-180.0 -180.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 0.1059 0.0" rot="-180.0 -180.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 0.09045 0.0" rot="0.0 0.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.0 0.05 0.0" rot="0.0 0.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
		</group>
		<group name="Rim" pos="-0.077 -0.025 0.175">
			<vox file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 -0.04045 0.0" rot="0.0 0.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 -0.0559 0.0" rot="0.0 0.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 -0.04045 0.0" rot="-180.0 -180.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.0 0.0" rot="-180.0 -180.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.153885 0.05 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.124495 0.09045 0.0" rot="-180.0 -180.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.07694 0.1059 0.0" rot="-180.0 -180.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.02939 0.09045 0.0" rot="0.0 0.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
			<vox pos="0.0 0.05 0.0" rot="0.0 0.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit" scale="0.5"/>
		</group>
		<group name="Lens Rim" pos="-0.077 -0.025 -0.2">
			<vox pos="-0.05 0.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="-0.030865 -0.046195 0.0" rot="0.0 0.0 22.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.00449 -0.08155 0.0" rot="0.0 0.0 45.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.050685 -0.100685 0.0" rot="0.0 0.0 67.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.100685 -0.100685 0.0" rot="0.0 360.0 90.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.146875 -0.08155 0.0" rot="180.0 180.0 67.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.182235 -0.046195 0.0" rot="180.0 180.0 45.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.201365 -0.0 0.0" rot="180.0 180.0 22.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.201365 0.05 0.0" rot="180.0 180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.182235 0.096195 0.0" rot="180.0 180.0 -22.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.146875 0.13155 0.0" rot="180.0 180.0 -45.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.100685 0.150685 0.0" rot="180.0 180.0 -67.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.050685 0.150685 0.0" rot="0.0 0.0 -90.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="0.00449 0.13155 0.0" rot="0.0 0.0 -67.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="-0.030865 0.096195 0.0" rot="0.0 0.0 -45.0" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="-0.05 0.05 0.0" rot="0.0 0.0 -22.5" file="MOD/assets/models/tool.vox" object="rimbit2" scale="0.5"/>
			<vox pos="-0.05 0.0 0.05" rot="90.0 35.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit" scale="0.5"/>
			<vox pos="0.050685 0.150685 0.05" rot="180.0 90.0 -55.0" file="MOD/assets/models/tool.vox" object="clampbit" scale="0.5"/>
			<vox pos="0.201365 0.05 0.05" rot="-90.0 145.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit" scale="0.5"/>
			<vox pos="0.100685 -0.100685 0.05" rot="0.0 90.0 55.0" file="MOD/assets/models/tool.vox" object="clampbit" scale="0.5"/>
		</group>
		<group name="Handle" pos="-0.025 0.0 0.25">
			<vox rot="160.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="handlebit" scale="0.5"/>
			<vox pos="0.0 0.02 0.04" rot="170.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="handlebit" scale="0.5"/>
		</group>
		<location name="grip" pos="0.0 -0.15 0.35"/>
		<group name="Glowy Bits"/>
	</group>
</prefab>
    ]],
}

RegisterToolUMF('quilezlaser', Tool)