#include "umf_complete_c.lua"

-- DO NOT MESS WITH INCLUDE FORMATTING OR QUOTATIONS. EVER.

-- Main Settings and Defaults
local hitGlass = true
local breakVaults = true
local maxDist = 1000
local maxLaserDepth = 1000
local deflectors = {}
local vaultDoors = {}
local innerBeam = {
	{0.8, 0.8, 0.8},
	{2, 2, 4}
}

-- If you wish to add custom laser modes, add their Visual settings here, and then the specific functionality in the functions below.
local laserColors = {
	{1, 0.3, 0.3},
	{0.7, 0.3, 0.0},
	{0.8, 0.3, 1},
	{0.1, 0, 1.5}
}
local brightness = {
    {8, 5, 5},
    {3, 2, 1},
    {5, 5, 7},
	{4, 2, 15}
}
local laserNames = {
	'Classic Quilez Plasma Laser',
	'Superheated Infrared Laser',
	'Pressurized Cold Plasma Laser',
	'Gamma Ray Burst Laser'
}

-- Technical
local key = 'savegame.mod.quilez_laser.'
if not GetBool(key..'everOpened') then
	SetBool(key..'everOpened', true)
	SetBool(key..'hitGlass', true)
	SetBool(key..'breakVaults', true)
	SetInt(key..'maxLaserDist', 1000)
	SetInt(key..'maxRecursion', 20)
	SetInt(key..'toolTab', 6)
end
local Tool = {
    printname = 'Quilez™ Laser',
    group = GetInt(key..'toolTab')
}

function rnd(mi, ma)
	return math.random(1000) / 1000 * (ma - mi) + mi
end

function rndVec(t)
	return Vec(rnd(-t, t), rnd(-t, t), rnd(-t, t))
end 

function emitSmoke(pos)
	ParticleReset()
	ParticleType('smoke')
	ParticleColor(0.8, 0.8, 0.8)
	ParticleRadius(0.2, 0.4)
	ParticleAlpha(0.5, 0)
	ParticleDrag(0.5)
	ParticleGravity(rnd(0.0, 2.0))
	SpawnParticle(VecAdd(pos, rndVec(0.01)), rndVec(0.1), rnd(1.0, 3.0))
	ParticleReset()
	ParticleEmissive(5, 0, 'easeout')
	ParticleGravity(-10)
	ParticleRadius(0.01, 0.0, 'easein')
	ParticleColor(1, 0.4, 0.3)
	ParticleTile(4)
	local vel = VecAdd(Vec(0, 1, 0), rndVec(2.0))
	SpawnParticle(pos, vel, rnd(1.0, 2.0))
end

function updateLaserMode()
	SetInt(key..'laserMode', GetInt(key..'laserMode') + 1)
	if (GetInt(key..'laserMode') > #laserNames) then
		SetInt(key..'laserMode', 1)
	end
end

function drawLaserSprite(pos1, pos2, color, size, depth)
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

function drawLaser(innerPos, startPos, endPos, col, brt, depth)
    PointLight(startPos, col[1], col[2], col[3], 0.5)
    PointLight(endPos, col[1], col[2], col[3], 1)
    PointLight(endPos, brt[1], brt[2], brt[3], 0.1)
    drawLaserSprite(startPos, endPos, col, 0.5 + math.random() * 0.05, depth)
    drawLaserSprite(startPos, endPos, brt, 0.05 + math.random() * 0.025, depth)
	if innerPos then
		drawLaserSprite(innerPos, startPos, innerBeam[1], 0.2 + math.random() * 0.02, depth)
		drawLaserSprite(innerPos, startPos, innerBeam[2], 0.04 + math.random() * 0.01, depth)
	end
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

function drawLaserRecursive(innerPos, initPos, target, dir, mode, col, brt, dt, depth, defsHit, defDepth)
    if target.hit then
		shouldHit = true
		-- PlayLoop(laserHitLoop, target.hitPoint, 0.5)
        -- Hit a deflector, recursively fire lasers from a specific point
        local hitBody = target.shape:GetBody()
        if hitBody:HasTag('mirror2') then
			shouldHit = false
            if defDepth <= maxLaserDepth then
                drawLaser(innerPos, initPos, target.hitpos, col, brt, depth)
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
					SetTag(target.shape.handle, "state", true)
                    SetShapeEmissiveScale(target.shape.handle, 1)
                    local reflected = refDir - target.normal * target.normal:Dot(refDir) * 2
                    local newTarget = customRaycast(ht.pos + reflected * 0.1, reflected, maxDist, 1, not hitGlass)
                    drawLaserRecursive(false, ht.pos, newTarget, refDir, mode, col, brt, dt, 0, defsHit, defDepth + 1)
                end
            end
        elseif hitBody:HasTag('mirror') then
			shouldHit = false
            -- Hit a mirror, recursively fire lasers until maximum depth
            if depth <= maxLaserDepth then
                drawLaser(innerPos, initPos, target.hitpos, col, brt, depth)
                local reflected = dir - target.normal * target.normal:Dot(dir) * 2
                local newTarget = customRaycast(target.hitpos + reflected * 0.1, reflected, maxDist, 1, not hitGlass)
                drawLaserRecursive(false, target.hitpos, newTarget, reflected, mode, col, brt, dt, depth + 1, defsHit, defDepth)
            end
		else
			-- DebugWatch('Hit at depth-'..depth..' at def-depth-'..defDepth, target.hitpos)
            for i = 1, #vaultDoors do
                if hitBody.handle == vaultDoors[i] and breakVaults then
                    RemoveTag(vaultDoors[i], 'unbreakable')
                end
            end
			-- No mirror or deflector, business as usual
			drawLaser(innerPos, initPos, target.hitpos, col, brt, depth)
			-- emitSmoke(target.hitpos)
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
				ParticleEmissive(math.random(2, 5), 0, 'easeout')
				ParticleTile(3)
				for i=1, 6 do
					local ranPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 0.5))
					MakeHole(ranPos, 0.2, 0.1, 0.1, true)
					SpawnFire(ranPos)
					Paint(ranPos, 0.2, 'explosion', 0.5)
					local v = Vec(math.random(-5,5),math.random(-5,5),math.random(-10,5))
					SpawnParticle(ranPos, v, 3)
				end
				for i=1, 8 do
					local ranPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 2.0))
					MakeHole(ranPos, 0.1, 0.1, 0, true)
					SpawnFire(ranPos)
					Paint(ranPos, 0.1, 'explosion', 0.5)
					local v = Vec(math.random(-5,5),math.random(-5,5),math.random(-10,5))
					ParticleRadius(0.025)
					SpawnParticle(ranPos, v, 3)
				end
				for i=1, 32 do
					local ranPos = VecAdd(curPos, VecScale(Vec(ultravioletSpan(), ultravioletSpan(), ultravioletSpan()), 4.0))
					MakeHole(ranPos, 0.1, 0, 0, true)
					SpawnFire(ranPos)
					Paint(ranPos, 0.2, 'explosion', 0.5)
					ParticleRadius(0.01)
					SpawnParticle(ranPos, v, 3)
				end
			end
			return
		end
	else 
		-- If firing laser at sky... just fire laser... nothing else
        drawLaser(innerPos, initPos, target.hitpos, col, brt, depth)
	end
end

function Tool:Initialize()
    RegisterListenerTo("EntityPlaced", "EntitySpawned")
    laserLoop = LoadLoop('MOD/assets/sounds/laser-loop.ogg')
    laserHitLoop = LoadLoop('MOD/assets/sounds/laser-hit-loop.ogg')
	laserHitSound = LoadSound('OD/assets/sounds/spark0.ogg')
    laserSprite = LoadSprite('MOD/assets/images/laser.png')
    laserStartSprite = LoadSprite('MOD/assets/images/laserfade.png')
    laserSpriteOg = LoadSprite('MOD/assets/images/laserog.png')
	deflectors = FindBodies('mirror2', true)
	vaultDoors = FindBodies('vaultdoor', true)
	if GetInt(key..'laserMode') == 0 then
		SetInt(key..'laserMode', 1)
	end
	SetString('game.tool.quilezlaser.ammo.display', '')
	hitGlass = GetBool(key..'hitGlass')
	breakVaults = GetBool(key..'breakVaults')
	maxDist = GetInt(key..'maxLaserDist')
	maxLaserDepth = GetInt(key..'maxRecursion')
end

-- Detect for deflectors spawned
function EntitySpawned(file)
    deflectors = FindBodies('mirror2', true)
end

function Tool:Animate()
	local target = PLAYER:GetCamera():Raycast(maxDist, -1, 0, not hitGlass)
	local pointer = self:GetBoneGlobalTransform('root'):ToLocal(target.hitpos)
	self.armature:SetBoneTransform('Laser', Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), pointer)))
	if GetBool('game.player.canusetool') then
        SetToolTransform(Transform(Vec(0.5, -0.4, -0.6), QuatEuler(0, 0, 0)))
		-- use self.armature in this case for armature / local space
		if GetVersion() ~= '1.5.4' and GetVersion() ~= '1.4.0' then
			local gripTransform = self.armature:GetBoneGlobalTransform('grip')
			SetToolHandPoseLocalTransform(gripTransform, nil)
		end
		local target = PLAYER:GetCamera():Raycast(maxDist, -1, 0, not hitGlass)
		local mode = GetInt(key..'laserMode')
		if InputDown('grab') and InputPressed('usetool') then
			updateLaserMode()
		end
		if not InputDown('grab') and InputDown('usetool') then
			PlayLoop(laserLoop, PLAYER:GetCamera().pos, 2)
			local col = laserColors[mode]
			local brt = brightness[mode]
			local dir = (target.hitpos - PLAYER:GetCamera().pos):Normalize()
			-- use self in this case for world space
			drawLaserRecursive(self:GetBoneGlobalTransform('inner').pos, self:GetBoneGlobalTransform('nozzle').pos, target, dir, mode, col, brt, dt, 0, {}, 0)
		end
	end
end

-- function Tool:Tick(dt)
-- end

function draw()
	inputDevice = LastInputDevice()
	local mode = GetInt(key..'laserMode')
	if GetString('game.player.tool') == 'quilezlaser' then
        UiAlign('center bottom')
        UiTextAlignment('center middle')
        UiTranslate(UiCenter(), UiHeight() - 100)
        UiFont('bold.ttf', 24)
        UiTextShadow(0, 0, 0, 0.5, 1.5)
        local col = laserColors[mode]
        UiColor(col[1] / 2 + 0.5, col[2] / 2 + 0.5, col[3] / 2 + 0.5)
        UiText(laserNames[mode])
        UiTranslate(0, 30)
        UiFont('bold.ttf', 16)
		if inputDevice == 2 then
			UiFont('bold.ttf', 18)
		end
		inputGrab = GetString('game.input.grab')
		inputTool = GetString('game.input.usetool')
		if inputDevice == 0 then
        	UiText('Hold Grab and Use Tool to Switch Modes')
		else
			UiText('Hold '..inputGrab..' and tap '..inputTool..' to Switch Modes')
		end
	end
end

-- REMEMBER: Set main group name to Laser!

Tool.model = {
    prefab = [[
<prefab version='1.6.0'>
	<group name='Laser' pos='0.0 0.0 0.0' rot='-180.0 -180.0 0.0'>
		<location name='nozzle' pos='0.0 0.0 -0.25'/>
		<location name='inner' pos='0.0 0.0 -0.05'/>
		<group name='Chamber' pos='-0.06 -0.025 0.15'>
			<vox pos='0.0 0.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.05 0.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.035355 0.085355 0.0' rot='0.0 0.0 -90.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.085355 0.085355 0.0' rot='180.0 180.0 -45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.12071 0.05 0.0' rot='-180.0 -180.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.12071 0.0 0.0' rot='180.0 -180.0 45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.085355 -0.035355 0.0' rot='0.0 -360.0 90.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.035355 -0.035355 0.0' rot='0.0 0.0 45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.0 0.05 0.0' rot='0.0 0.0 -45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
		</group>
		<group name='Chamber' pos='0.0 0.0 0.15' rot='0.0 0.0 22.5'>
			<vox pos='-0.06 -0.025 0.0' rot='0.0 0.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='-0.01 -0.025 0.0' rot='0.0 0.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='-0.024645 0.060355 0.0' rot='0.0 0.0 -90.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.025355 0.060355 0.0' rot='-180.0 -180.0 -45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.06071 0.025 0.0' rot='180.0 180.0 0.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.06071 -0.025 0.0' rot='-180.0 180.0 45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.025355 -0.060355 0.0' rot='0.0 360.0 90.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='-0.024645 -0.060355 0.0' rot='0.0 0.0 45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='-0.06 0.025 0.0' rot='0.0 0.0 -45.0' file='MOD/assets/models/tool.vox' object='chamberbit' scale='0.5' pbr='0.1 1 1 0'/>
		</group>
		<group name='Rim' pos='-0.077 -0.025 -0.05'>
			<vox file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 -0.04045 0.0' rot='0.0 0.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 -0.0559 0.0' rot='0.0 0.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 -0.04045 0.0' rot='-180.0 -180.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.0 0.0' rot='-180.0 -180.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.05 0.0' rot='-180.0 -180.0 0.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 0.09045 0.0' rot='-180.0 -180.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 0.1059 0.0' rot='-180.0 -180.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 0.09045 0.0' rot='0.0 0.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.0 0.05 0.0' rot='0.0 0.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
		</group>
		<group name='Rim' pos='-0.077 -0.025 0.4'>
			<vox file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 -0.04045 0.0' rot='0.0 0.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 -0.0559 0.0' rot='0.0 0.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 -0.04045 0.0' rot='-180.0 -180.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.0 0.0' rot='-180.0 -180.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.05 0.0' rot='-180.0 -180.0 0.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 0.09045 0.0' rot='-180.0 -180.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 0.1059 0.0' rot='-180.0 -180.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 0.09045 0.0' rot='0.0 0.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.0 0.05 0.0' rot='0.0 0.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
		</group>
		<group name='Rim' pos='-0.077 -0.025 0.175'>
			<vox file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 -0.04045 0.0' rot='0.0 0.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 -0.0559 0.0' rot='0.0 0.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 -0.04045 0.0' rot='-180.0 -180.0 72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.0 0.0' rot='-180.0 -180.0 36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.153885 0.05 0.0' rot='-180.0 -180.0 0.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.124495 0.09045 0.0' rot='-180.0 -180.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.07694 0.1059 0.0' rot='-180.0 -180.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.02939 0.09045 0.0' rot='0.0 0.0 -72.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.0 0.05 0.0' rot='0.0 0.0 -36.0' file='MOD/assets/models/tool.vox' object='rimbit' scale='0.5' pbr='0.3 1 1 0'/>
		</group>
		<group name='Lens Rim' pos='-0.077 -0.025 -0.2'>
			<vox pos='-0.05 0.0 0.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='-0.03087 -0.0462 0.0' rot='0.0 0.0 22.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.00449 -0.08155 0.0' rot='0.0 0.0 45.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.05068 -0.10069 0.0' rot='0.0 0.0 67.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.10069 -0.10069 0.0' rot='0.0 360.0 90.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.14687 -0.08155 0.0' rot='180.0 180.0 67.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.18224 -0.0462 0.0' rot='180.0 180.0 45.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.20136 0.0 0.0' rot='180.0 180.0 22.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.20136 0.05 0.0' rot='180.0 180.0 0.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.18224 0.09619 0.0' rot='180.0 180.0 -22.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.14687 0.13155 0.0' rot='180.0 180.0 -45.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.10069 0.15068 0.0' rot='180.0 180.0 -67.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.05068 0.15068 0.0' rot='0.0 0.0 -90.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.00449 0.13155 0.0' rot='0.0 0.0 -67.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='-0.03087 0.09619 0.0' rot='0.0 0.0 -45.0' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='-0.05 0.05 0.0' rot='0.0 0.0 -22.5' file='MOD/assets/models/tool.vox' object='rimbit2' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='-0.05 0.0 0.05' rot='90.0 35.0 0.0' file='MOD/assets/models/tool.vox' object='clampbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.050685 0.150685 0.05' rot='180.0 90.0 -55.0' file='MOD/assets/models/tool.vox' object='clampbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.201365 0.05 0.05' rot='-90.0 145.0 0.0' file='MOD/assets/models/tool.vox' object='clampbit' scale='0.5' pbr='0.3 1 1 0'/>
			<vox pos='0.100685 -0.100685 0.05' rot='0.0 90.0 55.0' file='MOD/assets/models/tool.vox' object='clampbit' scale='0.5' pbr='0.3 1 1 0'/>
		</group>
		<group name='Handle' pos='-0.025 0.0 0.25'>
			<vox rot='160.0 0.0 0.0' file='MOD/assets/models/tool.vox' object='handlebit' scale='0.5' pbr='0.1 1 1 0'/>
			<vox pos='0.0 0.02 0.04' rot='170.0 0.0 0.0' file='MOD/assets/models/tool.vox' object='handlebit' scale='0.5' pbr='0.1 1 1 0'/>
		</group>
		<location name='grip' pos='0.0 -0.15 0.35' rot='0 90 0'/>
		<group name='Glowy Bits'/>
		<group name='Lens' pos='0.0 -0.1 -0.2'>
			<vox pos='0.0 0.0 0.01' file='MOD/assets/models/tool.vox' object='lens' scale='0.5' color='1 1 1 0.2' pbr='0.1 1.0 0.1 0'/>
			<vox pos='0.0 0.0 0.04' file='MOD/assets/models/tool.vox' object='lens' scale='0.5' color='1 1 1 0.2' pbr='0.1 1.0 0.1 0'/>
		</group>
	</group>
</prefab>
    ]],
}

-- Final Registration
RegisterToolUMF('quilezlaser', Tool)
