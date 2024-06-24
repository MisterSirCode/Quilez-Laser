local laserColors = {
	{1, 0.3, 0.3},
	{1, 0.6, 0.3},
	{0.6, 0.3, 1},
	{0.1, 0, 1}
}
local brightness = {
    {8, 5, 5},
    {8, 6, 5},
    {5, 6, 8},
	{4, 2, 10}
}
local laserNames = {
	"Classic Quilez Plasma Laser",
	"Low Power Infrared Laser",
	"Pressurized Cold Plasma Laser",
	"Gamma Ray Burst Laser"
}
local toolpos = Transform(Vec(0.8, -0.6, -1.0), QuatEuler(0, 0, 0))
local tool = {
    printname = "Quilez Laser",
    group = 6
}
local maxDist = 1000
local maxLaserDepth = 10

function updateLaserMode()
	SetInt("savegame.mod.laserMode", GetInt("savegame.mod.laserMode") + 1)
	if (GetInt("savegame.mod.laserMode") > #laserNames) then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function drawlaserSprite(pos1, pos2, color, size)
    visual.drawline(laserSprite, pos1, pos2, {
        r = color[1], 
        g = color[2], 
        b = color[3],
        additive = true,
        width = size
    })
end

function drawLaser(startpos, endpos, col, brt)
	PointLight(startpos, col[1], col[2], col[3], 0.5)
	PointLight(endpos, col[1], col[2], col[3], 1)
	PointLight(endpos, brt[1], brt[2], brt[3], 0.1)
	drawlaserSprite(startpos, endpos, col, 0.5 + math.random() * 0.05)
	drawlaserSprite(startpos, endpos, brt, 0.05 + math.random() * 0.05)
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
	return (math.random()-0.5)
end

function drawLaserRecursive(initPos, target, dir, mode, col, brt, dt, depth)
    local curLaserDepth = depth
	if target.hit then
		-- Only do these checks IF IT HITS SOMETHING..... dont want errors :L
		if (target.shape:GetBody()):HasTag('mirror2') then
			-- TODO: Deflectors
		elseif (target.shape:GetBody()):HasTag('mirror') then
			-- Hit a mirror, recursively fire lasers until maximum depth
			local reflected = dir - target.normal * target.normal:Dot(dir) * 2
			if curLaserDepth <= maxLaserDepth then
				drawLaser(initPos, target.hitpos, col, brt)
				local rot = QuatLookAt(target.hitpos, target.hitpos + target.normal)
				local newTarget = customRaycast(target.hitpos + reflected * 0.1, reflected, maxDist, 1)
				drawLaserRecursive(target.hitpos, newTarget, reflected, mode, col, brt, dt, curLaserDepth + 1)
			end
		else
			drawLaser(initPos, target.hitpos, col, brt)
			-- No mirror or deflector, business as usual
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
		drawLaser(initPos, target.hitpos, col, brt)
	end
end

function tool:Initialize()
	laserReady = 0
	laserFireTime = 0
	laserLoop = LoadLoop("MOD/assets/laser-loop.ogg")
	laserHitLoop = LoadLoop("MOD/assets/laser-hit-loop.ogg")
	laserSprite = LoadSprite("MOD/assets/laser.png")
	laserSpriteOg = LoadSprite("MOD/assets/laserog.png")
	laserDist = 0
	laserHitScale = 0

	if GetInt("savegame.mod.laserMode") == 0 then
		SetInt("savegame.mod.laserMode", 1)
	end
	SetString("game.tool.quilezlaser.ammo.display", "")
end

function tool:Animate()
    local ar = self.armature
    local target = PLAYER:GetCamera():Raycast(maxDist, -1)
    local TinT = self:GetPredictedTransform():ToLocal(target.hitpos)
    ar:SetBoneTransform("root", Transform(Vec(0, 0, 0), QuatLookAt(Vec(0, 0, 0), TinT)))
end

function tool:Tick(dt)
	if GetBool("game.player.canusetool") then
		SetToolTransform(toolpos)
		local target = PLAYER:GetCamera():Raycast(maxDist, -1)
		local mode = GetInt("savegame.mod.laserMode")
		print(target)
		if InputPressed("alt") then
			updateLaserMode()
		end
		if InputDown("lmb") then
			local col = laserColors[GetInt("savegame.mod.laserMode")]
			local brt = brightness[GetInt("savegame.mod.laserMode")]
			local length = 0;
			local newCol = {};
			local dir = (target.hitpos - PLAYER:GetCamera().pos):Normalize()
			drawLaserRecursive(self:GetBoneGlobalTransform('nozzle').pos, target, dir, mode, col, brt, dt, 0)
		end
	end
end

tool.model = {
    prefab = [[
<prefab version="0.9.2">
    <group id_="473592032" open_="true" name="laser" pos="0.0 0.0 0.0" rot="0.0 0.0 0.0">
        <group id_="2048256128" open_="true" name="base" pos="0.0 0.0 0.0">
            <vox id_="1640400640" pos="-0.025 -0.175 0.175" rot="0.0 0.0 0.0" file="MOD/assets/laser.vox" object="laserbase" scale="0.5"/>
        </group>
        <location id_="1100482176" name="nozzle" pos="0.0 0.0 0.275"/>
        <location id_="2067721472" name="tip" pos="0.0 0.0 -0.525"/>
    </group>
</prefab>
    ]],
    objects = {
        {'laserbase', Vec(7, 12, 7)}
    }
}

RegisterToolUMF('quilezlaser', tool)

function draw()
	local mode = GetInt("savegame.mod.laserMode")
	if GetString("game.player.tool") == "quilezlaser" then
		UiAlign("center bottom")
		UiTranslate(UiCenter(), UiHeight() - 100)
		UiFont("bold.ttf", 24)
		UiTextShadow(0, 0, 0, 0.5, 1.5)
		local col = laserColors[mode]
		UiColor(col[1] / 2 + 0.5, col[2] / 2 + 0.5, col[3] / 2 + 0.5)
		UiText(laserNames[mode], true)
		UiFont("bold.ttf", 16)
		UiText("Press ALT to Switch Modes", true)
	end
end