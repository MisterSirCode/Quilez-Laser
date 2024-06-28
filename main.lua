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
	<group name="laser" pos="0.0 0.0 0.0" rot="0.0 0.0 0.0">
		<location name="nozzle" pos="0.0 0.0 -0.1"/>
		<group name="chamber" pos="-0.12 -0.05 0.3">
			<vox pos="0.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.1 0.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.07071 0.17071 0.0" rot="0.0 0.0 -90.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.17071 0.17071 0.0" rot="180.0 180.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.24142 0.1 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.24142 0.0 0.0" rot="180.0 -180.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.17071 -0.07071 0.0" rot="0.0 -360.0 90.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.07071 -0.07071 0.0" rot="0.0 0.0 45.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
			<vox pos="0.0 0.1 0.0" rot="0.0 0.0 -45.0" file="MOD/assets/models/tool.vox" object="chamberbit"/>
		</group>
		<group name="Rim" pos="-0.154 -0.05 -0.1">
			<vox file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.05878 -0.0809 0.0" rot="0.0 0.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.15388 -0.1118 0.0" rot="0.0 0.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.24899 -0.0809 0.0" rot="-180.0 -180.0 72.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.30777 0.0 0.0" rot="-180.0 -180.0 36.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.30777 0.1 0.0" rot="-180.0 -180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.24899 0.1809 0.0" rot="-180.0 -180.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.15388 0.2118 0.0" rot="-180.0 -180.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.05878 0.1809 0.0" rot="0.0 0.0 -72.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
			<vox pos="0.0 0.1 0.0" rot="0.0 0.0 -36.0" file="MOD/assets/models/tool.vox" object="rimbit"/>
		</group>
		<group name="Lens Rim" pos="-0.154 -0.05 -0.4">
			<vox pos="-0.1 0.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit2">
				<vox pos="0.0 0.0 0.1" rot="90.0 35.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit"/>
			</vox>
			<vox pos="-0.06173 -0.09239 0.0" rot="0.0 0.0 22.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.00898 -0.1631 0.0" rot="0.0 0.0 45.0" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.10137 -0.20137 0.0" rot="0.0 0.0 67.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.20137 -0.20137 0.0" rot="0.0 360.0 90.0" file="MOD/assets/models/tool.vox" object="rimbit2">
				<vox pos="0.0 0.0 0.1" rot="90.0 35.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit"/>
			</vox>
			<vox pos="0.29375 -0.1631 0.0" rot="180.0 180.0 67.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.36447 -0.09239 0.0" rot="180.0 180.0 45.0" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.40273 -0.0 0.0" rot="180.0 180.0 22.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.40273 0.1 0.0" rot="180.0 180.0 0.0" file="MOD/assets/models/tool.vox" object="rimbit2">
				<vox pos="0.0 0.0 0.1" rot="90.0 35.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit"/>
			</vox>
			<vox pos="0.36447 0.19239 0.0" rot="180.0 180.0 -22.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.29375 0.2631 0.0" rot="180.0 180.0 -45.0" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.20137 0.30137 0.0" rot="180.0 180.0 -67.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="0.10137 0.30137 0.0" rot="0.0 0.0 -90.0" file="MOD/assets/models/tool.vox" object="rimbit2">
				<vox pos="0.0 0.0 0.1" rot="90.0 35.0 0.0" file="MOD/assets/models/tool.vox" object="clampbit"/>
			</vox>
			<vox pos="0.00898 0.2631 0.0" rot="0.0 0.0 -67.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="-0.06173 0.19239 0.0" rot="0.0 0.0 -45.0" file="MOD/assets/models/tool.vox" object="rimbit2"/>
			<vox pos="-0.1 0.1 0.0" rot="0.0 0.0 -22.5" file="MOD/assets/models/tool.vox" object="rimbit2"/>
		</group>
		<group name="Handle" pos="-0.05 0.0 0.5">
			<vox rot="160.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="handlebit"/>
			<vox pos="0.0 0.04 0.08" rot="170.0 0.0 0.0" file="MOD/assets/models/tool.vox" object="handlebit"/>
		</group>
		<location name="grip" pos="0.0 -0.3 0.7"/>
	</group>
</prefab>
    ]],
    scale = 0.5
}

RegisterToolUMF('quilezlaser', Tool)