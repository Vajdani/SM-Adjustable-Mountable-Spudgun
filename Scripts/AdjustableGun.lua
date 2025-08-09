AdjustableGun = class()
AdjustableGun.maxParentCount = 2
AdjustableGun.maxChildCount = 0
AdjustableGun.connectionInput = bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.ammo )
AdjustableGun.connectionOutput = sm.interactable.connectionType.none
AdjustableGun.colorNormal = sm.color.new( "#34f5ff" )
AdjustableGun.colorHighlight = sm.color.new( "#11f5ff" )
AdjustableGun.poseWeightCount = 1

fellowGuns = fellowGuns or {}
templates = templates or {}

dofile "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua"
local projectileTypes = {
	{ name = "Potato",				projectile = projectile_potato,				offset = sm.vec3.new( 0, 0, 0 ) },
	{ name = "Small Potato",		projectile = projectile_smallpotato,		offset = sm.vec3.new( 0, 0, 0.6 ) },
	{ name = "Fries",				projectile = projectile_fries,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	{ name = "Tape",				projectile = projectile_tape,				offset = sm.vec3.new( 0, 0, 1 ) },
	{ name = "Explosive Tape", 		projectile = projectile_explosivetape,		offset = sm.vec3.new( 0, 0, 1 ) },
	{ name = "Water",				projectile = projectile_water,				offset = sm.vec3.new( 0, 0, 0 ) },
	{ name = "Pesticide",			projectile = projectile_pesticide,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	{ name = "Glowstick",			projectile = projectile_glowstick,			offset = sm.vec3.new( 0, 0, 0 ) },
	-- { name = "Chemical",			projectile = projectile_chemical,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Banana",				projectile = projectile_banana,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Blueberry",			projectile = projectile_blueberry,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Broccoli",			projectile = projectile_broccoli,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Carrot",				projectile = projectile_carrot,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Orange",				projectile = projectile_orange,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Pineapple",			projectile = projectile_pineapple,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Redbeet",				projectile = projectile_redbeet,			offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Tomato",				projectile = projectile_tomato,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Seed",				projectile = projectile_seed,				offset = sm.vec3.new( 0, 0, 0.6 ) },
	-- { name = "Epic Loot",			projectile = projectile_epicloot,			offset = sm.vec3.new( 0, 0, 0.6 ) },
}

local values = {
	1,
	10,
	100,
	1000
}

function AdjustableGun:sv_save( data )
	self.sv.data = data
	self.storage:save(self.sv.data)
	self.interactable:setPublicData( { name = tostring(self.gunId), data = self.sv.data } )
	templates[self.gunId] = self.interactable:getPublicData()
	self.network:setClientData( { data = self.sv.data, templates = templates } )
end

function AdjustableGun.server_onCreate( self )
	self.gunId = #fellowGuns+1
	fellowGuns[self.gunId] = self.interactable

	self:sv_init()
end

function AdjustableGun.server_onRefresh( self )
	self:sv_init()
end

function AdjustableGun.sv_init( self )
	self.sv = {}
	self.sv.fireDelayProgress = 0
	self.sv.canFire = true
	self.sv.parentActive = false

	self.sv.data = self.storage:load()
	if self.sv.data == nil then
		self.sv.data = {
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

	self.sv.canSwitch = true
	self:sv_save( self.sv.data )
end

function AdjustableGun:sv_isOutOfDate()
	local templateData = templates[self.sv.data.templateCount].data
	for v, k in pairs(templateData) do
		if v ~= "controlled" and v ~= "templateCount" and v ~= "isTemplate" then
			if self.sv.data[v] ~= templateData[v] then
				return true
			end
		end
	end

	return false
end


function AdjustableGun.server_onFixedUpdate( self, timeStep )
	if self.sv.data.isTemplate and self.sv.data ~= self.interactable:getPublicData() then
		self:sv_save( self.sv.data )
	end

	if #templates > 0 then
		if self.sv.data.templateCount > 0 and not self.sv.data.isTemplate and self:sv_isOutOfDate() then
			local data = templates[self.sv.data.templateCount].data
			self.sv.data = {
				type = data.type,
				damage = data.damage,
				shots = data.shots,
				spread = data.spread,
				delay = data.delay,
				fireForce = data.fireForce,
				fullAuto = data.fullAuto,
				templateCount = self.sv.data.templateCount,
				controlled = true,
				isTemplate = false
			}

			self:sv_save( self.sv.data )
		else
			self.sv.data.controlled = false
		end
	end

	if not self.sv.canFire then
		self.sv.fireDelayProgress = self.sv.fireDelayProgress + 1
		if self.sv.fireDelayProgress >= self.sv.data.delay then
			self.sv.fireDelayProgress = 0
			self.sv.canFire = true
		end
	end
	self:sv_tryFire()
	local logicInteractables, _ = self:getInputs()
	if logicInteractables[1] then
		self.sv.parentActive = logicInteractables[1]:isActive()
	end

	if logicInteractables[2] then
		if logicInteractables[2]:isActive() and self.sv.canSwitch then
			self.sv.canSwitch = false
			self.network:sendToClients("cl_template_button")
		elseif not logicInteractables[2]:isActive() and not self.sv.canSwitch then
			self.sv.canSwitch = true
		end
	end
end

function AdjustableGun:client_onClientDataUpdate( data, channel )
	self.cl.data = data.data
	self.cl.templates = data.templates
end

function AdjustableGun:client_onFixedUpdate( dt )
	self.cl.shootEffect = self.cl.effects[self.cl.data.type]
	self.cl.shootEffect:setOffsetPosition( projectileTypes[self.cl.data.type].offset)
end

function AdjustableGun.sv_tryFire( self )
	local logicInteractables, ammoInteractable = self:getInputs()
	local active = logicInteractables[1] and logicInteractables[1]:isActive() or false
	local ammoContainer = ammoInteractable and ammoInteractable:getContainer( 0 ) or nil
	local freeFire = not sm.game.getEnableAmmoConsumption() and not ammoContainer

	if freeFire then
		if active and (self.sv.data.fullAuto or not self.sv.parentActive) and self.sv.canFire then
			self:sv_fire()
		end
	else
		if active and (self.sv.data.fullAuto or not self.sv.parentActive) and self.sv.canFire and ammoContainer then
			sm.container.beginTransaction()
			sm.container.spend( ammoContainer, obj_plantables_potato, 1 )
			if sm.container.endTransaction() then
				self:sv_fire()
			end
		end
	end
end

function AdjustableGun.sv_fire( self )
	self.sv.canFire = false
	local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
	--local MinForce = 125.0
	--local MaxForce = 135.0
	--local fireForce = math.random( MinForce, MaxForce )

	for i = 1, self.sv.data.shots do
		local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), self.sv.data.spread )
		sm.projectile.shapeProjectileAttack( projectileTypes[self.sv.data.type].projectile, self.sv.data.damage, firePos, dir * self.sv.data.fireForce, self.shape )
	end

	self.network:sendToClients( "cl_onShoot" )
end

function AdjustableGun.client_onCreate( self )
	self.cl = {}
	self.cl.boltValue = 0.0

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

	self.cl.gui:setVisible("barrel", false)

	self.cl.effect = sm.effect.createEffect( "Template Highlight", self.interactable )
	self.cl.idGUI = sm.gui.createNameTagGui()

	self.cl.effects = {
		sm.effect.createEffect( "MountedPotatoRifle - Shoot", self.interactable ),
		sm.effect.createEffect( "SpudgunSpinner - SpinnerMuzzel", self.interactable ),
		sm.effect.createEffect( "SpudgunFrier - FrierMuzzel", self.interactable ),
		sm.effect.createEffect( "TapeBot - Shoot", self.interactable ),
		sm.effect.createEffect( "TapeBot - Shoot", self.interactable ),
		sm.effect.createEffect( "Mountedwatercanon - Shoot", self.interactable ),
		sm.effect.createEffect( "Farmbot - Shoot", self.interactable ),
		sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
		-- sm.effect.createEffect( "Glowstick - Throw", self.interactable ),
	}

	self.cl.shootEffect = self.cl.effects[1]
	self.cl.data = nil
	self.cl.templates = nil

	self.cl.valueIndex = 1
end

function AdjustableGun:cl_projType(button)
	if not self.cl.data.controlled then
		self.cl.data.type = self.cl.data.type < #projectileTypes and self.cl.data.type + 1 or 1
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_fullAuto(button)
	if not self.cl.data.controlled then
		self.cl.data.fullAuto = not self.cl.data.fullAuto
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_dmg(button)
	if not self.cl.data.controlled then
		if button == "dmgInc" then
			self.cl.data.damage = self.cl.data.damage + values[self.cl.valueIndex]
		elseif button == "dmgDec" and self.cl.data.damage > 0 then
			self.cl.data.damage = math.max(self.cl.data.damage - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_sprd(button)
	if not self.cl.data.controlled then
		if button == "sprdInc" then
			self.cl.data.spread = self.cl.data.spread + values[self.cl.valueIndex]
		elseif button == "sprdDec" and self.cl.data.spread > 0 then
			self.cl.data.spread = math.max(self.cl.data.spread - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_rld(button)
	if not self.cl.data.controlled then
		if button == "rldInc" then
			self.cl.data.delay = self.cl.data.delay + values[self.cl.valueIndex]
		elseif button == "rldDec" and self.cl.data.delay > 0 then
			self.cl.data.delay = math.max(self.cl.data.delay - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_proj(button)
	if not self.cl.data.controlled then
		if button == "projInc" then
			self.cl.data.shots = self.cl.data.shots + values[self.cl.valueIndex]
		elseif button == "projDec" and self.cl.data.shots > 1 then
			self.cl.data.shots = math.max(self.cl.data.shots - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_vel(button)
	if not self.cl.data.controlled then
		if button == "velInc" then
			self.cl.data.fireForce = self.cl.data.fireForce + values[self.cl.valueIndex]
		elseif button == "velDec" and self.cl.data.fireForce > 0 then
			self.cl.data.fireForce = math.max(self.cl.data.fireForce - values[self.cl.valueIndex], 0)
		end
		self.network:sendToServer("sv_save", self.cl.data)
	end
end

function AdjustableGun:cl_template_button()
	if sm.isHost() then
		self:cl_template()
	end
end

function AdjustableGun:cl_template()
	if #templates > 0 and not self.cl.data.isTemplate then
		self.cl.data.templateCount = self.cl.data.templateCount < #templates and self.cl.data.templateCount + 1 or 0
		if self.cl.data.templateCount == 0 then
			self.cl.data = {
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

function AdjustableGun:cl_value()
	self.cl.valueIndex = self.cl.valueIndex == #values and 1 or self.cl.valueIndex + 1
end

function AdjustableGun:client_canInteract()
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use", true ), "Tune gun settings" )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Tinker", true ), "Create template" )

    return true
end

function AdjustableGun:client_onInteract( char, lookAt )
	if lookAt then
		self.cl.gui:open()
	end
end

function AdjustableGun:client_onTinker( character, lookAt )
	if lookAt then
		if not self.cl.data.controlled and not self.cl.data.isTemplate then
			self.cl.data.isTemplate = true
			sm.gui.displayAlertText("Template of this spudgun has been created!", 2.5)
			self.network:sendToServer("sv_save", self.cl.data)
			self.cl.effect:start()
		else
			sm.gui.displayAlertText("Cant create template!", 2.5)
			sm.audio.play("RaftShark")
		end
	end
end

function AdjustableGun.client_onUpdate( self, dt )
	if self.cl.data == nil or self.cl.templates == nil then return end

	if self.cl.data.isTemplate then
		self.cl.idGUI:setText("Text", "Template id: #ff9d00"..tostring(self.shape.id))
		self.cl.idGUI:setWorldPosition(self.shape:getWorldPosition() + sm.vec3.new(0,0,0.5))
		self.cl.idGUI:open()
	end

	if self.cl.gui:isActive() then
		self.cl.gui:setText("projType", projectileTypes[self.cl.data.type].name)
		self.cl.gui:setText("projCount", tostring(self.cl.data.shots))
		self.cl.gui:setText("dmg", tostring(self.cl.data.damage))
		self.cl.gui:setText("spread", tostring(self.cl.data.spread))
		self.cl.gui:setText("reload", tostring(self.cl.data.delay))
		self.cl.gui:setText("velocity", tostring(self.cl.data.fireForce))

		local txt = self.cl.data.fullAuto and "#269e44ON" or "#9e2626OFF"
		self.cl.gui:setText("fullAuto", txt)

		if not self.cl.data.isTemplate then
			local txt2 = #self.cl.templates > 0 and self.cl.data.templateCount > 0 and self.cl.templates[self.cl.data.templateCount].name or "none"
			self.cl.gui:setText("template", txt2)
		else
			self.cl.gui:setText("template", "#9e2626DISABLED")
			self.cl.gui:setVisible("template", true)
		end

		self.cl.gui:setText("value", "Change value by: #ff9d00"..tostring(values[self.cl.valueIndex]) )
	end

	if self.cl.data.isTemplate and not self.cl.effect:isPlaying() then
		self.cl.effect:start()
	end

	if self.cl.effect:isPlaying() then
		local minColor = sm.color.new( 0.0, 0.0, 0.25, 0.1 )
		local maxColor = sm.color.new( 0.0, 0.3, 0.75, 1 )
		self.cl.effect:setParameter( "minColor", minColor )
		self.cl.effect:setParameter( "maxColor", maxColor )

		self.cl.effect:setScale(sm.vec3.new(0.25,0.25,0.25))
		self.cl.effect:setOffsetPosition( sm.vec3.new( 0.0, 0.0, 0.016 ) )
	end

	if self.cl.boltValue > 0.0 then
		self.cl.boltValue = self.cl.boltValue - dt * 10
	end
	if self.cl.boltValue ~= self.cl.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.cl.boltValue )
		self.cl.prevBoltValue = self.cl.boltValue
	end
end

function AdjustableGun.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, sm.interactable.connectionType.logic ) ~= 0 then
		return self.maxParentCount - #self.interactable:getParents( sm.interactable.connectionType.logic )
	end
	if bit.band( connectionType, sm.interactable.connectionType.ammo ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.ammo )
	end
	return 0
end

function AdjustableGun.cl_onShoot( self )
	self.cl.boltValue = 1.0
	self.cl.shootEffect:start()
	local impulse = sm.vec3.new( 0, 0, -1 ) * 500
	sm.physics.applyImpulse( self.shape, impulse )
end

function AdjustableGun.getInputs( self )
	local logicInteractables = { nil, nil }
	local ammoInteractable = nil
	--local parents = self.interactable:getParents()

	for v, parent in pairs(self.interactable:getParents()) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then
			if logicInteractables[1] == nil then
				logicInteractables[1] = parent
			else
				logicInteractables[2] = parent
			end
		elseif parent:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammoInteractable = parent
		end
	end

	--[[if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[2]
		elseif parents[2]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammoInteractable = parents[2]
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[1]
		elseif parents[1]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammoInteractable = parents[1]
		end
	end]]

	return logicInteractables, ammoInteractable
end

function AdjustableGun:client_onDestroy()
	self.cl.idGUI:close()
	self.cl.gui:close()

	self.cl.idGUI:destroy()
	self.cl.gui:destroy()
end

function AdjustableGun:server_onDestroy()
	fellowGuns[self.gunId] = nil
end