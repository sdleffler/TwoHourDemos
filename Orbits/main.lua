local orb = require 'orbital'

function renderSun(self)
	love.graphics.setColor(255, 255, 0)
	love.graphics.circle('fill', origin.x + ((self.p_x - center.x) * scale), origin.y + ((self.p_y - center.y) * scale), 10, 25)
end

function renderEarth(self)
	love.graphics.setColor(0, 127, 31)
	love.graphics.circle('fill', origin.x + ((self.p_x - center.x) * scale), origin.y + ((self.p_y - center.y) * scale), 4, 25)
end

function renderMoon(self)
	love.graphics.setColor(63, 63, 63)
	love.graphics.circle('fill', origin.x + ((self.p_x - center.x) * scale), origin.y + ((self.p_y - center.y) * scale), 2, 25)
end

function love.load()
	universe = orb.System(100)
	sun = orb.Body(1, 0, 0, 0, 0, false, renderSun)
	earth = orb.Body(1/333000, 1 * orb.AU, 0, 0, 30 * orb.KM_PER_SEC, false, renderEarth)
	moon = orb.Body(3.69396868 * (10^-8), 1 + orb.LD, 0, 0, (30 + 1.023) * orb.KM_PER_SEC, false, renderMoon)
	universe:add(sun)
	universe:add(earth)
	universe:add(moon)

	origin = { x = love.window.getWidth() / 2, y = love.window.getHeight() / 2 }
	scale = 100
	center = { x = 0, y = 0 }
	timestep = 100
	focus = 1 -- Sun
	time = 0
end

function love.keypressed(key, isrepeat)
	if key == 'k' then
		scale = scale / 10
	elseif key == 'l' then
		scale = scale * 10
	elseif key == 'g' then
		if focus == #universe.bodies then
			focus = 1
		else
			focus = focus + 1
		end
	elseif key == 'i' then
		timestep = timestep - 5
		if timestep <= 0 then timestep = 0 end
	elseif key == 'o' then
		timestep = timestep + 5
	end
end

function love.update(dt)
	time = time + dt/timestep
	universe:step(dt/timestep)
	center.x = universe.bodies[focus].p_x
	center.y = universe.bodies[focus].p_y
end

function love.draw()
	universe:render()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.print("[Scale (K-, L+) " .. scale .. "]", 8, 8)
	love.graphics.print("[Timestep (I-, O+) 1/" .. timestep .. "]", 8, 24)
	love.graphics.print("[Focus " .. focus .. "]", 8, 40)
	love.graphics.print("[Year " .. time .. "]", 8, 56)
end