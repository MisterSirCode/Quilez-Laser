#include "umf_complete_c.lua"

local maxLaserDepth = 10
local maxDist = 1000
local deflectors = {}
local vaultDoors = {}
local laserColors = {
	{1, 0.3, 0.3},
	{1, 0.6, 0.3},
	{0.6, 0.3, 1},
	{0.1, 0, 1}}
local brightness = {
    {8, 5, 5},
    {8, 6, 5},
    {5, 6, 8},
	{4, 2, 10}}
local laserNames = {
	"Classic Quilez Plasma Laser",
	"Low Power Infrared Laser",
	"Pressurized Cold Plasma Laser",
	"Gamma Ray Burst Laser"}
local Tool = {
    printname = 'Quilez™ Laser',
    group = 6
}

function rnd(mi, ma)
	return math.random(1000) / 1000 * (ma - mi) + mi
end

function rndVec(t)
	return Vec(rnd(-t, t), rnd(-t, t), rnd(-t, t))
end 

function emitSmoke(pos)
	ParticleReset()
	ParticleType("smoke")
	ParticleColor(0.8, 0.8, 0.8)
	ParticleRadius(0.2, 0.4)
	ParticleAlpha(0.5, 0)
	ParticleDrag(0.5)
	ParticleGravity(rnd(0.0, 2.0))
	SpawnParticle(VecAdd(pos, rndVec(0.01)), rndVec(0.1), rnd(1.0, 3.0))
	ParticleReset()
	ParticleEmissive(5, 0, "easeout")
	ParticleGravity(-10)
	ParticleRadius(0.01, 0.0, "easein")
	ParticleColor(1, 0.4, 0.3)
	ParticleTile(4)
	local vel = VecAdd(Vec(0, 1, 0), rndVec(2.0))
	SpawnParticle(pos, vel, rnd(1.0, 2.0))
end

function updateLaserMode()
	SetInt("savegame.mod.laserMode", GetInt("savegame.mod.laserMode") + 1)
	if (GetInt("savegame.mod.laserMode") > #laserNames) then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function drawlaserSprite(pos1, pos2, color, size, depth)
	if depth < 1 then sprite = laserStartSprite
	else sprite = laserSprite end
	--DrawLine(pos1, pos2, color[1], color[2], color[3])
    visual.drawline(laserSprite, pos1, pos2, {
        r = color[1], 
        g = color[2], 
        b = color[3],
        additive = true,
        width = size
    })
end

function drawLaser(startpos, endpos, col, brt, depth)
    PointLight(startpos, col[1], col[2], col[3], 0.5)
    PointLight(endpos, col[1], col[2], col[3], 1)
    PointLight(endpos, brt[1], brt[2], brt[3], 0.1)
    drawlaserSprite(startpos, endpos, col, 0.5 + math.random() * 0.05, depth)
    drawlaserSprite(startpos, endpos, brt, 0.05 + math.random() * 0.05, depth)
end

function customRaycast(pos, dir, dist, mul, radius, rejectTransparent)
    if mul then
        dir = dir * mul
    end
    local hit, dist2, normal, shape = QueryRaycast(pos, dir, dist, radius, rejectTransparent)
    return {
        hit = hit,
        dist = dist2,
        normal = hit and MakeVector(normal),
        shape = hit and Shape and Shape(shape) or shape,
        hitpos = pos + dir:Mul(hit and dist2 or dist),
    }
end

function ultravioletSpan(v)
	return (math.random() - 0.5)
end

function drawLaserRecursive(initPos, target, dir, mode, col, brt, dt, depth, defsHit, defDepth)
	DebugWatch('target'..depth, target.hitpos)
    if target.hit then
        -- Hit a deflector, recursively fire lasers from a specific point
        local hitBody = target.shape:GetBody()
        if hitBody:HasTag('mirror2') then
            if defDepth <= maxLaserDepth then
                drawLaser(initPos, target.hitpos, col, brt, depth)
                local alreadyHit = false
                for i=1, #defsHit do
                    if defsHit[i] == hitBody then
                        alreadyHit = true
                        break
                    end
                end
                if not alreadyHit then
                    defsHit[#defsHit+1] = hitBody
                    local ht = hitBody:GetTransform()
                    local refDir = TransformToParentVec(ht, Vec(0, 0, 1))
                    SetShapeEmissiveScale(target.shape.handle, 1)
                    local reflected = refDir - target.normal * target.normal:Dot(refDir) * 2
                    local newTarget = customRaycast(ht.pos + reflected * 0.1, reflected, maxDist, 1)
                    drawLaserRecursive(ht.pos, newTarget, refDir, mode, col, brt, dt, 0, defsHit, defDepth + 1)
                end
            end
        elseif hitBody:HasTag('mirror') then
            -- Hit a mirror, recursively fire lasers until maximum depth
            if depth <= maxLaserDepth then
                drawLaser(initPos, target.hitpos, col, brt, depth)
                local reflected = dir - target.normal * target.normal:Dot(dir) * 2
                local rot = QuatLookAt(target.hitpos, target.hitpos + target.normal)
                local newTarget = customRaycast(target.hitpos + reflected * 0.1, reflected, maxDist, 1)
                drawLaserRecursive(target.hitpos, newTarget, rot, mode, col, brt, dt, depth + 1, defsHit, defDepth)
            end
        else
            for i = 1, #vaultDoors do
                if hitBody.handle == vaultDoors[i] then
                    RemoveTag(vaultDoors[i], "unbreakable")
                end
            end
			-- No mirror or deflector, business as usual
			drawLaser(initPos, target.hitpos, col, brt, depth)
			emitSmoke(target.hitpos)
			if mode == 1 then
				MakeHole(target.hitpos, 0.5, 0.3, 0.1, true)
				SpawnFire(target.hitpos)
			elseif mode == 2 then
				local curPos = target.hitpos
				for i=1, 5 do
					curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
					SpawnFire(curPos)
					MakeHole(curPos, 0.1, 0, 0, true)
					emitSmoke(curPos, 1.0)
				end
			elseif mode == 3 then
				local curPos = target.hitpos
				for i=1, 5 do
					curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
					MakeHole(curPos, 0.5, 0.4, 0.3, true)
					emitSmoke(curPos, 1.0)
				end
			elseif mode == 4 then
				local curPos = target.hitpos
				MakeHole(curPos, 0.3, 0.2, 0.1, true)
				SpawnFire(curPos)
				if math.random() > 0.5 then
					Explosion(curPos, 0.1)
				end
				ParticleReset()
				ParticleColor(0.3, 0.1, 1, 0, 0, 0.5)
				ParticleAlpha(1, 0)
				ParticleRadius(0.05)
				ParticleGravity(-10.0)
				ParticleDrag(0)
				ParticleEmissive(math.random(2, 5), 0, "easeout")
				ParticleTile(3)
				for i=1, 6 do
					curPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 0.6))
					MakeHole(curPos, 0.2, 0.1, 0, true)
					SpawnFire(curPos)
					Paint(curPos, 0.2, "explosion", 0.5)
					local v = Vec(math.random(-5,5),math.random(-5,5),math.random(-10,5))
					SpawnParticle(curPos, v, 3)
				end
				for i=1, 8 do
					curPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 2.0))
					MakeHole(curPos, 0.1, 0, 0, true)
					SpawnFire(curPos)
					Paint(curPos, 0.1, "explosion", 0.5)
					local v = Vec(math.random(-5,5),math.random(-5,5),math.random(-10,5))
					ParticleRadius(0.025)
					SpawnParticle(curPos, v, 3)
				end
				for i=1, 32 do
					curPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 4.0))
					SpawnFire(curPos)
					Paint(curPos, 0.2, "explosion", 0.5)
					ParticleRadius(0.01)
					SpawnParticle(curPos, v, 3)
				end
			end
		end
	else 
		-- If firing laser at sky... just fire laser... nothing else
		DebugWatch('loose', 'firing')
		DebugWatch('positions', {initPos, target.hitpos})
		DebugCross(initPos)
		DebugCross(target.hitpos)
        drawLaser(initPos, target.hitpos, col, brt, depth)
	end
end

function Tool:Initialize()
    laserLoop = LoadLoop("MOD/assets/sounds/laser-loop.ogg")
    laserHitLoop = LoadLoop("MOD/assets/sounds/laser-hit-loop.ogg")
    laserSprite = LoadSprite("MOD/assets/images/laser.png")
    laserStartSprite = LoadSprite("MOD/assets/images/laserfade.png")
    laserSpriteOg = LoadSprite("MOD/assets/images/laserog.png")
	deflectors = FindBodies("mirror2", true)
	vaultDoors = FindBodies("vaultdoor", true)
	if GetInt("savegame.mod.laserMode") == 0 then
		SetInt("savegame.mod.laserMode", 1)
	end
	SetString("game.tool.quilezlaser.ammo.display", "")
end

function Tool:Animate()
	local arm = self.armature
	local target = PLAYER:GetCamera():Raycast(maxDist, -1)
	local pointer = self:GetBoneGlobalTransform('root'):ToLocal(target.hitpos)
	arm:SetBoneTransform('Laser', Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), pointer)))
end

function Tool:Tick(dt)
	if GetBool('game.player.canusetool') then
        SetToolTransform(Transform(Vec(0.5, -0.4, -0.6), QuatEuler(0, 0, 0)))
        local gripTransform = self:GetBoneGlobalTransform('grip')
        SetToolHandPoseWorldTransform(gripTransform)
		local target = PLAYER:GetCamera():Raycast(maxDist, -1)
		local mode = GetInt("savegame.mod.laserMode")
		if InputPressed("alt") then
			updateLaserMode()
		end
		if InputDown("lmb") then
			local col = laserColors[mode]
			local brt = brightness[mode]
			local dir = (target.hitpos - PLAYER:GetCamera().pos):Normalize()
			drawLaserRecursive(self:GetBoneGlobalTransform('nozzle').pos, target, dir, mode, col, brt, dt, 0, {}, 0)
		end
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

function draw()
	local mode = GetInt("savegame.mod.laserMode")
	if GetString("game.player.tool") == "quilezlaser" then
        UiAlign("center bottom")
        UiTextAlignment("center middle")
        UiTranslate(UiCenter(), UiHeight() - 100)
        UiFont("bold.ttf", 24)
        UiTextShadow(0, 0, 0, 0.5, 1.5)
        local col = laserColors[mode]
        UiColor(col[1] / 2 + 0.5, col[2] / 2 + 0.5, col[3] / 2 + 0.5)
        UiText(laserNames[mode])
        UiTranslate(0, 30)
        UiFont("bold.ttf", 16)
        UiText("Press ALT to Switch Modes")
	end
end