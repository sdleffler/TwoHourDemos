local orbital = {}

--[[

Mass, time, and distance are measured in astronomical units. Non-length astronomical units are as follows:

Astronomical unit of time

The astronomical unit of time is the day, defined as 86400 seconds. 365.25 days make up one Julian year.[1] The symbol D is used in astronomy to refer to this unit.
The unit as used here, however, is 220903200 seconds. (1 year in seconds.)

Astronomical unit of mass

The astronomical unit of mass is the solar mass.[1] The symbol M☉ is often used to refer to this unit. The solar mass (M☉), 1.98892×10^30 kg, is a standard way to express mass in astronomy, used to describe the masses of other stars and galaxies. It is equal to the mass of the Sun, about 333000 times the mass of the Earth or 1,048 times the mass of Jupiter.

]]--

orbital.AU = 1
orbital.LD = 1/389 -- Lunar Distance in AU.
orbital.KM = 1/149597871
orbital.M = 1/149597871000
orbital.M_SOLAR_KG = 1.989 * (10^30) -- Solar mass in kilograms
orbital.Y_SOLAR_SECS = 220903200 -- Seconds in a year.
orbital.G_SOLAR_UNIT_ADJUSTED = 6.674 * (10^(-11)) * orbital.M_SOLAR_KG *
	orbital.M^3 * orbital.Y_SOLAR_SECS^2 -- Newtonian gravitational constant, where F = ma, a is in terms of astronomical units^2 per year
orbital.KM_PER_SEC = orbital.Y_SOLAR_SECS * orbital.KM

do
	local System = {}
	setmetatable(System, {
		__call = function (cls, ...)
			return cls.new(...)
		end,
	})

	System.__index = System
	function System.new(nsteps)
		local self = setmetatable({}, System)
		self.nsteps = nsteps or 1
		self.bodies = {}
		return self
	end

	function System.add(self, body)
		self.bodies[#self.bodies + 1] = body
	end

	function System.step(self, dt_total)
		local dt = dt_total/self.nsteps
		for step=1,self.nsteps do
			for i,v in ipairs(self.bodies) do
				if not v.static then
					v.p_x = v.p_x + v.v_x * dt
					v.p_y = v.p_y + v.v_y * dt
				else
					v.v_x = 0
					v.v_y = 0
				end
			end

			for i,v in ipairs(self.bodies) do
				for j,u in ipairs(self.bodies) do
					if j ~= i then
						local r_vec = { x = v.p_x - u.p_x, y = v.p_y - u.p_y }
						local r_sq = r_vec.x^2 + r_vec.y^2
						local r_mag = math.sqrt(r_sq)

						local impulse = dt * orbital.G_SOLAR_UNIT_ADJUSTED * v.mass * u.mass / r_sq

						r_vec.x = (r_vec.x / r_mag) * impulse
						r_vec.y = (r_vec.y / r_mag) * impulse

						v.v_x = v.v_x - (r_vec.x / (v.mass))
						v.v_y = v.v_y - (r_vec.y / (v.mass))
					end
				end
			end
		end
	end

	function System.render(self)
		for i,v in ipairs(self.bodies) do
			v:render()
		end
	end

	orbital.System = System
end

do
	function dummy() end

	local Body = {}
	setmetatable(Body, {
		__call = function (cls, ...)
			return cls.new(...)
		end,
	})
	Body.__index = Body
	function Body.new(mass, x, y, dx, dy, static, render)
		local self = setmetatable({}, Body)
		self.mass = mass
		self.p_x = x
		self.p_y = y
		self.v_x = dx or 0
		self.v_y = dy or 0
		self.static = static or false
		self.render = render or dummy
		return self
	end

	orbital.Body = Body
end

return orbital