MAX_DIST = 1000

function updateLaserMode()
	SetInt("savegame.mod.laserMode", GetInt("savegame.mod.laserMode") + 1)
	if (GetInt("savegame.mod.laserMode") > #LASER_NAMES) then
		SetInt("savegame.mod.laserMode", 1)
	end
end

function sign(n)
	return (n > 0 and 1) or (n == 0 and 0) or -1
end

function rnd(mi, ma)
	return math.random(1000)/1000*(ma-mi) + mi
end

function rndVec(t)
	return Vec(rnd(-t, t), rnd(-t, t), rnd(-t, t))
end 

function init()
	RegisterTool("quilezlaser", "Quilez™ Laser", "MOD/assets/laser.vox")
	SetBool("game.tool.quilezlaser.enabled", true)
    SetFloat('game.tool.quilezlaser.ammo', 1000)
    SetString('game.tool.quilezlaser.ammo.display', '')
	laserReady = 0
	laserFireTime = 0
	laserLoop = LoadLoop("MOD/assets/laser-loop.ogg")
	laserHitLoop = LoadLoop("MOD/assets/laser-hit-loop.ogg")
	laserSprite = LoadSprite("MOD/assets/laser.png")
	laserDist = 0
	laserHitScale = 0
	deflectors = FindBodies("mirror2", true)
	if GetInt("savegame.mod.laserMode") == 0 then
		SetInt("savegame.mod.laserMode", 1)
	end
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

function getDistanceToLineSegment(point, p0, p1)
    local line_vec = VecSub(p1, p0)
    local pnt_vec = VecSub(point, p0)
    local line_len = VecLength(line_vec)
    local line_unitvec = VecNormalize(line_vec)
    local pnt_vec_scaled = VecScale(pnt_vec, 1.0/line_len)
    local t = VecDot(line_unitvec, pnt_vec_scaled)    
    if t < 0.0 then
        t = 0.0
    elseif t > 1.0 then
        t = 1.0
	end
    local nearest = VecScale(line_vec, t)
    local dist = VecLength(VecSub(nearest, pnt_vec))
    local nearest = VecAdd(nearest, p0)
    return dist, nearest
end

-- function shootLaser(body, shape, origin, dir, currentLength, deflectorsHit)
-- 	QueryRequire("physical")
-- 	if shape ~= 0 then
-- 		QueryRejectShape(shape)
-- 	end
-- 	if body ~= 0 then
-- 		QueryRejectBody(body)
-- 	end
-- 	local hit, hitDist, hitNormal, hitShape = QueryRaycast(origin, dir, MAX_DIST, 0.0, true)
-- 	local length = MAX_DIST
-- 	if hit then
-- 		length = hitDist
-- 	end
-- 	local hitPoint = VecAdd(origin, VecScale(dir, length))
-- 	local t = Transform(VecLerp(origin, hitPoint, 0.5))
-- 	local xAxis = VecNormalize(VecSub(hitPoint, origin))
-- 	local zAxis = VecNormalize(VecSub(origin, GetCameraTransform().pos))
-- 	t.rot = QuatAlignXZ(xAxis, zAxis)
-- 	DrawSprite(laserSprite, t, length, 0.05+math.random()*0.01, 8, 4, 4, 1, true, true)
-- 	local col = LASER_COLORS[GetInt("savegame.mod.laserMode")]
-- 	DrawSprite(laserSprite, t, length, 0.5, col[1], col[2], col[3], 1, true, true)
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror2") and currentLength < MAX_DIST then
-- 		local alreadyHit = false
-- 		for i=1, #deflectorsHit do
-- 			if deflectorsHit[i] == hitBody then
-- 				alreadyHit = true
-- 				break
-- 			end
-- 		end
-- 		if not alreadyHit then
-- 			deflectorsHit[#deflectorsHit+1] = hitBody
-- 			local t = GetBodyTransform(hitBody)
-- 			local refDir = TransformToParentVec(t, Vec(0, 0, 1))
-- 			SetShapeEmissiveScale(hitShape, 1)
-- 			return shootLaser(hitBody, hitShape, t.pos, refDir, currentLength + length, deflectorsHit)
-- 		end
-- 	end
-- 	local hitBody = GetShapeBody(hitShape)
-- 	if HasTag(hitBody, "mirror") and currentLength < MAX_DIST then
-- 		local refDir = VecSub(dir, VecScale(hitNormal, VecDot(hitNormal, dir)*2))
-- 		return shootLaser(hitBody, hitShape, hitPoint, refDir, currentLength + length, deflectorsHit)
-- 	end
-- 	return currentLength + length, hitPoint, hitBody, hitShape
-- end

function playerLaser() 
	QueryRequire("physical")
	if shape ~= 0 then
		QueryRejectShape(shape)
	end
	if body ~= 0 then
		QueryRejectBody(body)
	end
	local tlt = GetBodyTransform(GetToolBody())
	local origin = TransformToParentPoint(tlt, Vec(0, -0.5, 0))
	local hit, hitDist, hitNormal, hitShape = QueryRaycast(origin, dir, MAX_DIST, 0.0, true)
	local length = MAX_DIST
	if hit then
		length = hitDist
	end
end

function tick(dt)
	if InputPressed("insert") then
		SetBool("savegame.mod.laserAngle", not GetBool("savegame.mod.laserAngle"))
	end
	DebugWatch("angle", GetBool("savegame.mod.laserAngle"))
	local LASER_MODE = GetInt("savegame.mod.laserMode")
	if GetString("game.player.tool") == "quilezlaser" then
		if InputPressed("alt") then
			updateLaserMode()
		end
		local offset = Transform(Vec(0.5, 0, 0))
		SetToolTransform(offset)
		local tlt = GetBodyTransform(GetToolBody())
		local origin = TransformToParentPoint(tlt, Vec(0, -0.5, 0))
		local col = LASER_COLORS[GetInt("savegame.mod.laserMode")]
		PointLight(VecAdd(origin, Vec(0, 0.1, 0)), col[1], col[2], col[3], rnd(0.5, 1.0))
		if GetBool("game.player.canusetool") and InputDown("usetool") then
			for i=1, #deflectors do
				local shapes = GetBodyShapes(deflectors[i])
				if #shapes > 0 then
					SetShapeEmissiveScale(shapes[1], 0)
				end
			end
			local cam = GetPlayerCameraTransform()
			PlayLoop(laserLoop, origin, 0.5)
			local tool = GetToolBody()
			local shapes = 0
			if tool ~= 0 then
				shapes = GetBodyShapes(tool)
			end
			local dir = TransformToParentVec(tlt, Vec(0, 0, -1))
			local length, hitPoint, hitBody, hitShape = shootLaser(0, shapes, origin, dir, 0, {})
			if length ~= laserDist then
				laserHitScale = 1
				laserDist = length
			end
			laserHitScale = math.max(0.0, laserHitScale - dt)
			if laserHitScale > 0 then
				PlayLoop(laserHitLoop, hitPoint, laserHitScale)
				PointLight(hitPoint, col[1], col[2], col[3], rnd(2.0, 4.0) * laserHitScale)
			else
				PointLight(hitPoint, col[1], col[2], col[3], rnd(0.5, 1.0))
			end
			if LASER_MODE == 1 then
				MakeHole(hitPoint, 0.5, 0.3, 0.1, true)
				SpawnFire(hitPoint)
				emitSmoke(hitPoint, 1.0)
			elseif LASER_MODE == 2 then
				local curPos = hitPoint
				for i=1, 5 do
					curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
					MakeHole(curPos, 0.5, 0.4, 0.3, true)
				end
			else
				local curPos = hitPoint
				for i=1, 5 do
					curPos = VecAdd(curPos, VecScale(VecScale(dir, dt), 6))
					SpawnFire(curPos)
					emitSmoke(curPos, 1.0)
				end
			end
		else
			laserFireTime = 0
		end
	end
end

function draw()
	local LASER_MODE = GetInt("savegame.mod.laserMode")
	if GetString("game.player.tool") == "quilezlaser" then
		UiAlign("center bottom")
		UiTranslate(UiCenter(), UiHeight() - 75)
		UiFont("bold.ttf", 24)
		UiTextShadow(0, 0, 0, 0.5, 1.5)
		local col = LASER_COLORS[LASER_MODE]
		UiColor(col[1] / 2 + 0.5, col[2] / 2 + 0.5, col[3] / 2 + 0.5)
		UiText(LASER_NAMES[LASER_MODE], true)
		UiFont("bold.ttf", 16)
		UiText("Press ALT to Switch Modes", true)
	end
end
