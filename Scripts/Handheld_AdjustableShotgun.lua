dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

HandheldSh = class()

local renderables = {
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Base/char_spudgun_base_basic.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Barrel/Barrel_frier/char_spudgun_barrel_frier.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Sight/Sight_basic/char_spudgun_sight_basic.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Stock/Stock_broom/char_spudgun_stock_broom.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Tank/Tank_basic/char_spudgun_tank_basic.rend"
}

dofile "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua"
local projectileTypes = {
	{ name = "Potato",				projectile = projectile_potato },
	{ name = "Small Potato",		projectile = projectile_smallpotato },
	{ name = "Fries",				projectile = projectile_fries },
	{ name = "Tape",				projectile = projectile_tape },
	{ name = "Explosive Tape", 		projectile = projectile_explosivetape },
	{ name = "Water",				projectile = projectile_water },
	{ name = "Pesticide",			projectile = projectile_pesticide },
	{ name = "Glowstick",			projectile = projectile_glowstick }
}

local values = {
	1,
	10,
	100,
	1000
}

local modes = {
	"single",
	"double"
}


local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_spudgun.rend", "$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function HandheldSh:sv_save( data )
	self.sv.data = data
	self.storage:save(self.sv.data)
	self.network:setClientData( { data = self.sv.data, templates = templates } )
end

function HandheldSh:sv_isOutOfDate( index )
	local templateData = templates[self.sv.data[index].templateCount].data
	for v, k in pairs(templateData) do
		if v ~= "controlled" and v ~= "templateCount" and v ~= "isTemplate" then
			if self.sv.data[index][v] ~= templateData[v] then
				return true
			end
		end
	end

	return false
end

function HandheldSh:sv_syncFireMode( fireMode )
	self.network:sendToClients("cl_syncFireMode", fireMode)
end

function HandheldSh:cl_syncFireMode( fireMode )
	self.cl.fireMode = fireMode
end

function HandheldSh:client_onClientDataUpdate( data, channel )
	self.cl.data = data.data
	self.cl.templates = data.templates
end

function HandheldSh:server_onCreate()
    self.sv = {}
	self.sv.data = self.storage:load()
	if self.sv.data == nil then
		self.sv.data = {
			--two data tables for two barrels
			{
				type = 1,
				damage = 28,
				shots = 1,
				spread = 1,
				delay = 8,
				fireForce = 130,
				fullAuto = false,
				templateCount = 0,
				controlled = false,
				isTemplate = false
			},
			{
				type = 1,
				damage = 28,
				shots = 1,
				spread = 1,
				delay = 8,
				fireForce = 130,
				fullAuto = false,
				templateCount = 0,
				controlled = false,
				isTemplate = false
			}
		}
	end

	self:sv_save( self.sv.data )
end

function HandheldSh.client_onCreate( self )
	self.cl = {}

	--10/10 solution for the FP/TP thing
    --just use the same effect for FP and TP if theres only a TP effect
	self.cl.effects = {
		{ sm.effect.createEffect( "SpudgunBasic - BasicMuzzel" ), 			sm.effect.createEffect( "SpudgunBasic - FPBasicMuzzel" ) },
		{ sm.effect.createEffect( "SpudgunSpinner - SpinnerMuzzel" ), 		sm.effect.createEffect( "SpudgunSpinner - FPSpinnerMuzzel" ) },
		{ sm.effect.createEffect( "SpudgunFrier - FrierMuzzel" ), 			sm.effect.createEffect( "SpudgunFrier - FPFrierMuzzel" ) },
		{ sm.effect.createEffect( "TapeBot - Shoot" ), 						sm.effect.createEffect( "TapeBot - Shoot" ) },
		{ sm.effect.createEffect( "TapeBot - Shoot" ), 						sm.effect.createEffect( "TapeBot - Shoot" ) },
		{ sm.effect.createEffect( "Mountedwatercanon - Shoot" ), 			sm.effect.createEffect( "Mountedwatercanon - Shoot" ) },
		{ sm.effect.createEffect( "Farmbot - Shoot" ), 						sm.effect.createEffect( "Farmbot - Shoot" ) },
		{ sm.effect.createEffect( "Glowstick - Throw" ),					sm.effect.createEffect( "Glowstick - Throw" ) }
	}

	self.cl.effects_2 = {
		{ sm.effect.createEffect( "SpudgunBasic - BasicMuzzel" ), 			sm.effect.createEffect( "SpudgunBasic - FPBasicMuzzel" ) },
		{ sm.effect.createEffect( "SpudgunSpinner - SpinnerMuzzel" ), 		sm.effect.createEffect( "SpudgunSpinner - FPSpinnerMuzzel" ) },
		{ sm.effect.createEffect( "SpudgunFrier - FrierMuzzel" ), 			sm.effect.createEffect( "SpudgunFrier - FPFrierMuzzel" ) },
		{ sm.effect.createEffect( "TapeBot - Shoot" ), 						sm.effect.createEffect( "TapeBot - Shoot" ) },
		{ sm.effect.createEffect( "TapeBot - Shoot" ), 						sm.effect.createEffect( "TapeBot - Shoot" ) },
		{ sm.effect.createEffect( "Mountedwatercanon - Shoot" ), 			sm.effect.createEffect( "Mountedwatercanon - Shoot" ) },
		{ sm.effect.createEffect( "Farmbot - Shoot" ), 						sm.effect.createEffect( "Farmbot - Shoot" ) },
		{ sm.effect.createEffect( "Glowstick - Throw" ),					sm.effect.createEffect( "Glowstick - Throw" ) }
	}

    self.shootEffect = self.cl.effects[1][1]
	self.shootEffectFP = self.cl.effects[1][2]
	self.shootEffect_2 = self.cl.effects_2[1][1]
	self.shootEffectFP_2 = self.cl.effects_2[1][2]

	self.cl.data = nil
	self.cl.templates = nil

	self.cl.fireMode = "double"

	if not self.tool:isLocal() then return end

    self.cl.gui = sm.gui.createGuiFromLayout( "$CONTENT_d9e6682a-1885-44b2-9cda-11bf5fec9dac/Gui/AdjustableGun.layout" )
	self.cl.gui:setButtonCallback( "projType", "cl_projType" )
	self.cl.gui:setButtonCallback( "fullAuto", "cl_fullAuto" )
	self.cl.gui:setButtonCallback( "dmgInc", "cl_dmg" )
	self.cl.gui:setButtonCallback( "dmgDec", "cl_dmg" )
	self.cl.gui:setButtonCallback( "sprdInc", "cl_sprd" )
	self.cl.gui:setButtonCallback( "sprdDec", "cl_sprd" )
	self.cl.gui:setButtonCallback( "rldInc", "cl_rld" )
	self.cl.gui:setButtonCallback( "rldDec", "cl_rld" )
	self.cl.gui:setButtonCallback( "projInc", "cl_proj" )
	self.cl.gui:setButtonCallback( "projDec", "cl_proj" )
	self.cl.gui:setButtonCallback( "velInc", "cl_vel" )
	self.cl.gui:setButtonCallback( "velDec", "cl_vel" )

	self.cl.gui:setButtonCallback( "template", "cl_template")
	self.cl.gui:setButtonCallback( "value", "cl_value")
	self.cl.gui:setButtonCallback( "barrel", "cl_barrel")

    self.cl.fireCounter = 0
	self.cl.fireCounter_2 = 0
    self.cl.isFiring = false
    self.cl.lastShotTick = 0
	self.cl.lastShotTick_2 = 0
	self.cl.selectedBarrel = 1
	self.cl.valueIndex = 1
end

function HandheldSh:cl_shoot( barrel )
    if not sm.game.getEnableAmmoConsumption() or sm.container.canSpend( sm.localPlayer.getInventory(), obj_plantables_potato, 1 ) then
        local firstPerson = self.tool:isInFirstPersonView()

        local dir = sm.localPlayer.getDirection()

        local firePos = self:calculateFirePosition()
        local fakePosition = self:calculateTpMuzzlePos()
        local fakePositionSelf = fakePosition
        if firstPerson then
            fakePositionSelf = self:calculateFpMuzzlePos()
        end

        -- Aim assist
        if not firstPerson then
            local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
            local hit, result = sm.localPlayer.getRaycast( 250, raycastPos, sm.camera.getDirection() )
            if hit then
                local norDir = sm.vec3.normalize( result.pointWorld - firePos )
                local dirDot = norDir:dot( dir )

                if dirDot > 0.96592583 then -- max 15 degrees off
                    dir = norDir
                else
                    local radsOff = math.asin( dirDot )
                    dir = sm.vec3.lerp( dir, norDir, math.tan( radsOff ) / 3.7320508 ) -- if more than 15, make it 15
                end
            end
        end

        dir = dir:rotate( math.rad( 0.955 ), sm.camera.getRight() ) -- 50 m sight calibration

        -- Spread
        local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
        local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

        local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
        spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
        local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

        --dir = sm.noise.gunSpread( dir, spreadDeg )

        local owner = self.tool:getOwner()
        if owner then
			local double = self.cl.fireMode == modes[2]
			local right = sm.localPlayer.getRight() * 0.25
			local offset = double and right or sm.vec3.zero()

			if barrel == nil or barrel == 1 then
				for i = 1, self.cl.data[1].shots do
					local dir = sm.noise.gunSpread( dir, self.cl.data[1].spread )
					sm.projectile.projectileAttack( projectileTypes[self.cl.data[1].type].projectile, self.cl.data[1].damage, firePos - offset, dir * self.cl.data[1].fireForce, owner, fakePosition, fakePositionSelf )
				end
				self.cl.lastShotTick = sm.game.getCurrentTick()

				-- Send TP shoot over network and dircly to self
				self:onShoot( dir )
				self.network:sendToServer( "sv_n_onShoot", dir )

				-- Play FP shoot animation
				setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.05 )
			end

			if barrel == nil and double or barrel == 2 then
				for i = 1, self.cl.data[2].shots do
					local dir = sm.noise.gunSpread( dir, self.cl.data[2].spread )
					sm.projectile.projectileAttack( projectileTypes[self.cl.data[2].type].projectile, self.cl.data[2].damage, firePos + offset, dir * self.cl.data[2].fireForce, owner, fakePosition, fakePositionSelf )
				end
				self.cl.lastShotTick_2 = sm.game.getCurrentTick()

				-- Send TP shoot over network and dircly to self
				self:onShoot_2( dir )
				self.network:sendToServer( "sv_n_onShoot_2", dir )

				-- Play FP shoot animation
				setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.05 )
			end
        end

        -- Timers
        self.fireCooldownTimer = fireMode.fireCooldown
        self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
        self.sprintCooldownTimer = self.sprintCooldown
    else
        local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
        self.fireCooldownTimer = fireMode.fireCooldown
        sm.audio.play( "PotatoRifle - NoAmmo" )
    end
end

function HandheldSh.client_onRefresh( self )
	self:loadAnimations()
end

function HandheldSh.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" }
		}
	)
	local movementAnimations = {
		idle = "spudgun_idle",
		idleRelaxed = "spudgun_relax",

		sprint = "spudgun_sprint",
		runFwd = "spudgun_run_fwd",
		runBwd = "spudgun_run_bwd",

		jump = "spudgun_jump",
		jumpUp = "spudgun_jump_up",
		jumpDown = "spudgun_jump_down",

		land = "spudgun_jump_land",
		landFwd = "spudgun_jump_land_fwd",
		landBwd = "spudgun_jump_land_bwd",

		crouchIdle = "spudgun_crouch_idle",
		crouchFwd = "spudgun_crouch_fwd",
		crouchBwd = "spudgun_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "spudgun_pickup", { nextAnimation = "idle" } },
				unequip = { "spudgun_putdown" },

				idle = { "spudgun_idle", { looping = true } },
				shoot = { "spudgun_shoot", { nextAnimation = "idle" } },

				aimInto = { "spudgun_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "spudgun_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "spudgun_aim_idle", { looping = true} },
				aimShoot = { "spudgun_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "spudgun_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "spudgun_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "spudgun_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 2.6,
		spreadMinAngle = .25,
		spreadMaxAngle = 8,
		fireVelocity = 130.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 1.3,
		spreadMinAngle = 0,
		spreadMaxAngle = 8,
		fireVelocity =  130.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 0.0
	self.spreadCooldownTimer = 0.0

	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 0.0
	self.sprintCooldown = 0.3

	self.aimBlendSpeed = 3.0
	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )

end

function HandheldSh:cl_projType(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		self.cl.data[self.cl.selectedBarrel].type = self.cl.data[self.cl.selectedBarrel].type < #projectileTypes and self.cl.data[self.cl.selectedBarrel].type + 1 or 1
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_fullAuto(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		self.cl.data[self.cl.selectedBarrel].fullAuto = not self.cl.data[self.cl.selectedBarrel].fullAuto
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_dmg(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		if button == "dmgInc" then
			self.cl.data[self.cl.selectedBarrel].damage = self.cl.data[self.cl.selectedBarrel].damage + values[self.cl.valueIndex]
		elseif button == "dmgDec" and self.cl.data[self.cl.selectedBarrel].damage > 0 then
			self.cl.data[self.cl.selectedBarrel].damage = math.max(self.cl.data[self.cl.selectedBarrel].damage - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_sprd(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		if button == "sprdInc" then
			self.cl.data[self.cl.selectedBarrel].spread = self.cl.data[self.cl.selectedBarrel].spread + values[self.cl.valueIndex]
		elseif button == "sprdDec" and self.cl.data[self.cl.selectedBarrel].spread > 0 then
			self.cl.data[self.cl.selectedBarrel].spread = math.max(self.cl.data[self.cl.selectedBarrel].spread - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_rld(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		if button == "rldInc" then
			self.cl.data[self.cl.selectedBarrel].delay = self.cl.data[self.cl.selectedBarrel].delay + values[self.cl.valueIndex]
		elseif button == "rldDec" and self.cl.data[self.cl.selectedBarrel].delay > 0 then
			self.cl.data[self.cl.selectedBarrel].delay = math.max(self.cl.data[self.cl.selectedBarrel].delay - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_proj(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		if button == "projInc" then
			self.cl.data[self.cl.selectedBarrel].shots = self.cl.data[self.cl.selectedBarrel].shots + values[self.cl.valueIndex]
		elseif button == "projDec" and self.cl.data[self.cl.selectedBarrel].shots > 1 then
			self.cl.data[self.cl.selectedBarrel].shots = math.max(self.cl.data[self.cl.selectedBarrel].shots - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_vel(button)
	if not self.cl.data[self.cl.selectedBarrel].controlled then
		if button == "velInc" then
			self.cl.data[self.cl.selectedBarrel].fireForce = self.cl.data[self.cl.selectedBarrel].fireForce + values[self.cl.valueIndex]
		elseif button == "velDec" and self.cl.data[self.cl.selectedBarrel].fireForce > 0 then
			self.cl.data[self.cl.selectedBarrel].fireForce = math.max(self.cl.data[self.cl.selectedBarrel].fireForce - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function HandheldSh:cl_template()
	if templates ~= nil and #templates > 0 and not self.cl.data[self.cl.selectedBarrel].isTemplate then
		self.cl.data[self.cl.selectedBarrel].templateCount = self.cl.data[self.cl.selectedBarrel].templateCount < #templates and self.cl.data[self.cl.selectedBarrel].templateCount + 1 or 0
		if self.cl.data[self.cl.selectedBarrel].templateCount == 0 then
			self.cl.data[self.cl.selectedBarrel] = {
				type = 1,
				damage = 28,
				shots = 1,
				spread = 1,
				delay = 8,
				fireForce = 130,
				fullAuto = false,
				templateCount = 0,
				controlled = false,
				isTemplate = false
			}
		end

		self.network:sendToServer("sv_save", self.cl.data)
	else
		sm.gui.displayAlertText("Cant find any templates!", 2.5)
		sm.audio.play("RaftShark")
	end
end

function HandheldSh:cl_value()
	self.cl.valueIndex = self.cl.valueIndex == #values and 1 or self.cl.valueIndex + 1
end

function HandheldSh:cl_barrel()
	self.cl.selectedBarrel = self.cl.selectedBarrel == 1 and 2 or 1
end

function HandheldSh:client_onReload()
	self.cl.gui:open()

    return true
end

function HandheldSh:client_onToggle()
	self.cl.fireMode = self.cl.fireMode == modes[2] and modes[1] or modes[2]
	sm.gui.displayAlertText("Current fire mode: #ff9d00"..self.cl.fireMode, 2)
	self.network:sendToServer("sv_syncFireMode", self.cl.fireMode)
	return true
end

function HandheldSh:server_onFixedUpdate( dt )
	if templates ~= nil and #templates > 0 then
		for i = 1, 2 do
			if self.sv.data[i].templateCount > 0 and not self.sv.data[i].isTemplate and self:sv_isOutOfDate( i ) then
				local data = templates[self.sv.data[i].templateCount].data
				self.sv.data[i] = {
					type = data.type,
					damage = data.damage,
					shots = data.shots,
					spread = data.spread,
					delay = data.delay,
					fireForce = data.fireForce,
					fullAuto = data.fullAuto,
					templateCount = self.sv.data[i].templateCount,
					controlled = true,
					isTemplate = false
				}

				self:sv_save( self.sv.data )
			else
				self.sv.data[i].controlled = false
			end
		end
	end
end

function HandheldSh:client_onFixedUpdate( dt )
	if self.cl.data == nil then return end
    self.shootEffect = self.cl.effects[self.cl.data[1].type][1]
    self.shootEffectFP = self.cl.effects[self.cl.data[1].type][2]

	self.shootEffect_2 = self.cl.effects_2[self.cl.data[2].type][1]
    self.shootEffectFP_2 = self.cl.effects_2[self.cl.data[2].type][2]

	if not self.tool:isLocal() or not self.tool:isEquipped() then return end
    if self.cl.data[1].fullAuto and self.cl.isFiring then
        self.cl.fireCounter = self.cl.fireCounter + dt
        if sm.game.getCurrentTick() >= self.cl.lastShotTick + self.cl.data[1].delay then
            self.cl.fireCounter = 0
            self:cl_shoot( 1 )
        end
    end

	if self.cl.data[2].fullAuto and self.cl.isFiring and self.cl.fireMode == "double" then
        self.cl.fireCounter_2 = self.cl.fireCounter_2 + dt
        if sm.game.getCurrentTick() >= self.cl.lastShotTick_2 + self.cl.data[2].delay then
            self.cl.fireCounter_2 = 0
            self:cl_shoot( 2 )
        end
    end
end

function HandheldSh.client_onUpdate( self, dt )
	-- First person animation
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching()

	if self.tool:isLocal() then
		if self.cl.data ~= nil and self.cl.gui:isActive() then
			self.cl.gui:setText("projType", projectileTypes[self.cl.data[self.cl.selectedBarrel].type].name)
			self.cl.gui:setText("projCount", tostring(self.cl.data[self.cl.selectedBarrel].shots))
			self.cl.gui:setText("dmg", tostring(self.cl.data[self.cl.selectedBarrel].damage))
			self.cl.gui:setText("spread", tostring(self.cl.data[self.cl.selectedBarrel].spread))
			self.cl.gui:setText("reload", tostring(self.cl.data[self.cl.selectedBarrel].delay))
			self.cl.gui:setText("velocity", tostring(self.cl.data[self.cl.selectedBarrel].fireForce))

			local txt = self.cl.data[self.cl.selectedBarrel].fullAuto and "#269e44ON" or "#9e2626OFF"
			self.cl.gui:setText("fullAuto", txt)

			if not self.cl.data[self.cl.selectedBarrel].isTemplate then
				local txt2 = templates ~= nil and #templates > 0 and self.cl.data[self.cl.selectedBarrel].templateCount > 0 and templates[self.cl.data[self.cl.selectedBarrel].templateCount].name or "none"
				self.cl.gui:setText("template", txt2)
			else
				self.cl.gui:setText("template", "#9e2626DISABLED")
				self.cl.gui:setVisible("template", true)
			end

			self.cl.gui:setText("barrel", "Selected Barrel: #ff9d00"..(self.cl.selectedBarrel == 1 and "left" or "right"))
			self.cl.gui:setText("value", "Change value by: #ff9d00"..tostring(values[self.cl.valueIndex]) )
		end

		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.aiming and not isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

	local effectPos, rot

	if self.tool:isLocal() then

		local zOffset = 0.6
		if self.tool:isCrouching() then
			zOffset = 0.29
		end

		local dir = sm.localPlayer.getDirection()
		local firePos = self.tool:getFpBonePos( "pejnt_barrel" )

		if not self.aiming then
			effectPos = firePos + dir * 0.2
		else
			effectPos = firePos + dir * 0.45
		end

		rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )


		self.shootEffectFP:setPosition( effectPos )
		self.shootEffectFP:setVelocity( self.tool:getMovementVelocity() )
		self.shootEffectFP:setRotation( rot )

		self.shootEffectFP_2:setPosition( effectPos )
		self.shootEffectFP_2:setVelocity( self.tool:getMovementVelocity() )
		self.shootEffectFP_2:setRotation( rot )
	end
	local pos = self.tool:getTpBonePos( "pejnt_barrel" )
	local dir = self.tool:getTpBoneDir( "pejnt_barrel" )

	effectPos = pos + dir * 0.2

	rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )


	self.shootEffect:setPosition( effectPos )
	self.shootEffect:setVelocity( self.tool:getMovementVelocity() )
	self.shootEffect:setRotation( rot )

	self.shootEffect_2:setPosition( effectPos )
	self.shootEffect_2:setVelocity( self.tool:getMovementVelocity() )
	self.shootEffect_2:setRotation( rot )

	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
	self.spreadCooldownTimer = math.max( self.spreadCooldownTimer - dt, 0.0 )
	self.sprintCooldownTimer = math.max( self.sprintCooldownTimer - dt, 0.0 )


	if self.tool:isLocal() then
		local dispersion = 0.0
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max( fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

		if isCrouching then
			dispersion = fireMode.minDispersionCrouching
		else
			dispersion = fireMode.minDispersionStanding
		end

		if self.tool:getRelativeMoveDirection():length() > 0 then
			dispersion = dispersion + fireMode.maxMovementDispersion * self.tool:getMovementSpeedFraction()
		end

		if not self.tool:isOnGround() then
			dispersion = dispersion * fireMode.jumpDispersionMultiplier
		end

		self.movementDispersion = dispersion

		self.spreadCooldownTimer = clamp( self.spreadCooldownTimer, 0.0, fireMode.spreadCooldown )
		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0

		self.tool:setDispersionFraction( clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 ) )

		if self.aiming then
			if self.tool:isInFirstPersonView() then
				self.tool:setCrossHairAlpha( 0.0 )
			else
				self.tool:setCrossHairAlpha( 1.0 )
			end
			self.tool:setInteractionTextSuppressed( true )
		else
			self.tool:setCrossHairAlpha( 1.0 )
			self.tool:setInteractionTextSuppressed( false )
		end
	end

	-- Sprint block
	local blockSprint = self.aiming or self.sprintCooldownTimer > 0.0
	self.tool:setBlockSprint( blockSprint )

	local playerDir = self.tool:getDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local linareAngle = playerDir:dot( sm.vec3.new( 0, 0, 1 ) )

	local linareAngleDown = clamp( -linareAngle, 0.0, 1.0 )

	down = clamp( -angle, 0.0, 1.0 )
	fwd = ( 1.0 - math.abs( angle ) )
	up = clamp( angle, 0.0, 1.0 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 0.001 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end

	-- Third Person joint lock
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) or ( self.aiming and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local finalAngle = ( 0.5 + angle * 0.5 )
	self.tool:updateAnimation( "spudgun_spine_bend", finalAngle, self.spineWeight )

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )


	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )


	-- Camera update
	local bobbing = 1
	if self.aiming then
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 1.0, blend )
		bobbing = 0.12
	else
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function HandheldSh.client_onEquip( self, animate )

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.wantEquipped = true
	self.aiming = false
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	self.tool:setTpRenderables( currentRenderablesTp )

	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )

	if self.tool:isLocal() then
		-- Sets PotatoRifle renderable, change this to change the mesh
		self.tool:setFpRenderables( currentRenderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function HandheldSh.client_onUnequip( self, animate )

	if animate then
		sm.audio.play( "PotatoRifle - Unequip", self.tool:getPosition() )
	end

	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
end

function HandheldSh.sv_n_onAim( self, aiming )
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function HandheldSh.cl_n_onAim( self, aiming )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function HandheldSh.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function HandheldSh.sv_n_onShoot( self, dir )
	self.network:sendToClients( "cl_n_onShoot", dir )
end

function HandheldSh.cl_n_onShoot( self, dir )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot( dir )
	end
end

function HandheldSh.onShoot( self, dir )

	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0 )

	if self.tool:isInFirstPersonView() then
		self.shootEffectFP:start()
	else
		self.shootEffect:start()
	end
end

function HandheldSh.sv_n_onShoot_2( self, dir )
	self.network:sendToClients( "cl_n_onShoot_2", dir )
end

function HandheldSh.cl_n_onShoot_2( self, dir )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot_2( dir )
	end
end

function HandheldSh.onShoot_2( self, dir )

	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0 )

	if self.tool:isInFirstPersonView() then
		self.shootEffectFP_2:start()
	else
		self.shootEffect_2:start()
	end
end

function HandheldSh.calculateFirePosition( self )
	local crouching = self.tool:isCrouching()
	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()

	local fireOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	if crouching then
		fireOffset.z = 0.15
	else
		fireOffset.z = 0.45
	end

	if firstPerson then
		if not self.aiming then
			fireOffset = fireOffset + right * 0.05
		end
	else
		fireOffset = fireOffset + right * 0.25
		fireOffset = fireOffset:rotate( math.rad( pitch ), right )
	end
	local firePosition = GetOwnerPosition( self.tool ) + fireOffset
	return firePosition
end

function HandheldSh.calculateTpMuzzlePos( self )
	local crouching = self.tool:isCrouching()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()
	local up = right:cross(dir)

	local fakeOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	--General offset
	fakeOffset = fakeOffset + right * 0.25
	fakeOffset = fakeOffset + dir * 0.5
	fakeOffset = fakeOffset + up * 0.25

	--Action offset
	local pitchFraction = pitch / ( math.pi * 0.5 )
	if crouching then
		fakeOffset = fakeOffset + dir * 0.2
		fakeOffset = fakeOffset + up * 0.1
		fakeOffset = fakeOffset - right * 0.05

		if pitchFraction > 0.0 then
			fakeOffset = fakeOffset - up * 0.2 * pitchFraction
		else
			fakeOffset = fakeOffset + up * 0.1 * math.abs( pitchFraction )
		end
	else
		fakeOffset = fakeOffset + up * 0.1 *  math.abs( pitchFraction )
	end

	local fakePosition = fakeOffset + GetOwnerPosition( self.tool )
	return fakePosition
end

function HandheldSh.calculateFpMuzzlePos( self )
	local fovScale = ( sm.camera.getFov() - 45 ) / 45

	local up = sm.localPlayer.getUp()
	local dir = sm.localPlayer.getDirection()
	local right = sm.localPlayer.getRight()

	local muzzlePos45 = sm.vec3.new( 0.0, 0.0, 0.0 )
	local muzzlePos90 = sm.vec3.new( 0.0, 0.0, 0.0 )

	if self.aiming then
		muzzlePos45 = muzzlePos45 - up * 0.2
		muzzlePos45 = muzzlePos45 + dir * 0.5

		muzzlePos90 = muzzlePos90 - up * 0.5
		muzzlePos90 = muzzlePos90 - dir * 0.6
	else
		muzzlePos45 = muzzlePos45 - up * 0.15
		muzzlePos45 = muzzlePos45 + right * 0.2
		muzzlePos45 = muzzlePos45 + dir * 1.25

		muzzlePos90 = muzzlePos90 - up * 0.15
		muzzlePos90 = muzzlePos90 + right * 0.2
		muzzlePos90 = muzzlePos90 + dir * 0.25
	end

	return self.tool:getFpBonePos( "pejnt_barrel" ) + sm.vec3.lerp( muzzlePos45, muzzlePos90, fovScale )
end

function HandheldSh.cl_onPrimaryUse( self, state )
	if self.tool:getOwner().character == nil then
		return
	end

	if self.fireCooldownTimer <= 0.0 and state == sm.tool.interactState.start then
        self:cl_shoot()
	end
end

function HandheldSh.cl_onSecondaryUse( self, state )
	if state == sm.tool.interactState.start and not self.aiming then
		self.aiming = true
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end

	if self.aiming and (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
		self.aiming = false
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end
end

function HandheldSh.client_onEquippedUpdate( self, primaryState, secondaryState )
    self.cl.isFiring = (primaryState == sm.tool.interactState.start or primaryState == sm.tool.interactState.hold) and true or false

	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse( primaryState )
		self.prevPrimaryState = primaryState
	end

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end

function HandheldSh:client_onDestroy()
	if self.cl.gui ~= nil then
		self.cl.gui:close()
		self.cl.gui:destroy()
	end
end