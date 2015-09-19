-- This function returns a new "Triangle" object, which is a table
-- with a few closures and values in it (not a class!) The Triangle
-- object contains position, size, and color data. The constructor
-- takes an additional callback - add_child() - which allows the Triangle
-- constructor to tessellate the currently constructing triangle by
-- providing somewhere to store the child. The constructor takes one
-- parameter which controlls tesselation, the 'tess' argument; when
-- constructing a triangle, a random chance is taken four times to
-- tessellate - one for each possible sub-triangle (top, lower left
-- corner, lower right corner, and center.) The chance that one particular
-- sub-triangle might be created is 1/tess. The 'dir' argument controls
-- the orientation of the triangle - +1 if upright, -1 if upside-down.
function Triangle(x, width, dir, tess, y, add_child)
	add_child = add_child or function() end
	tess = tess or 0
	y = y or 0

	assert(tess ~= 1)

	local newtri = {}

	newtri.width = width

	local d = math.sqrt(width^2 - (width/2)^2) * dir
	local b_max = 64
	local b = math.random(b_max)

	newtri.yverts = { d/2 + y, d/2 + y, -d/2 + y }
	newtri.color = { b, b, b + (128 - b_max) + math.random(127) }
	newtri.x = x
	newtri.y = y

	function newtri.draw(ripple_func)
		love.graphics.setColor(newtri.color)
		love.graphics.polygon('fill', newtri.x + math.sin(ripple_func(newtri.x, newtri.y)) * width, newtri.yverts[1], newtri.x + width - math.sin(ripple_func(newtri.x, newtri.y)) * width, newtri.yverts[2], (newtri.x + width/2), newtri.yverts[3])
	end

	function newtri.update(dt, bounds)
		if newtri.x + dt/width > bounds/2 then
			newtri.x = newtri.x + dt / width - bounds
		else
			newtri.x = newtri.x + dt / width
		end
	end

	if tess ~= 0 then
		if math.random(tess) == 1 then
			add_child(Triangle(x, width/2, dir, tess + 1, y + d/4, add_child))
		end
		if math.random(tess) == 1 then
			add_child(Triangle(x + width/2, width/2, dir, tess + 1, y + d/4, add_child))
		end
		if math.random(tess) == 1 then
			add_child(Triangle(x + width/4, width/2, dir, tess + 1, y - d/4, add_child))
		end
		if math.random(tess) == 1 then
			add_child(Triangle(x + width/4, width/2, -dir, tess + 1, y + d/4, add_child))
		end
	end

	return newtri
end

-- Generate a bunch of triangles to fill up our screen, where width is the width of our screen in pixels / 128,
-- and height is the height of our screen in pixels / 128.
function generate_tris(width, height)
	math.random()
	triangles = {}
	local c = 0
	for j=-height,height,math.sqrt(0.75) do
		for i=-width,width do
			local x, dir = i/2 + (1/2 * math.floor(c % 2)), ({-1, 1})[(i % 2) + 1]
			table.insert(triangles, Triangle(x, 1, dir, 5, j, function(child) table.insert(triangles, child) end))
		end
		c = c + 1
	end
	table.sort(triangles, function(tri1, tri2) return tri1.width > tri2.width end)
end

-- Love2D window resize callback; resets width/height for the new resolution and regenerates our
-- triangles accordingly, for efficiency. Also sets the max_time parameter of the ripples so that
-- the ripples don't disapppear while they're on screen, and don't take too long to respawn. The
-- background color is also set here.
function love.resize(w, h)
	width = math.ceil(w/64) + 2
	height = math.ceil(h/64)

	generate_tris(width, height)

	local b_max = 64
	local b = math.random(b_max)
	love.graphics.setBackgroundColor(b, b, b + (128 - b_max) + math.random(128))

	ripple_state.max_time = (width * 2) * (ripple_state.ripple_width_coeff / ripple_state.radius_per_time)
end

-- Love2D keypress callback, just for fullscreen toggling.
function love.keypressed(key, isrepeat)
	if key == "f" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

-- Love2D on load callback, sets the random() seed to the OS time, initializes the ripple state table,
-- and then sets the window as resizable before calling the resize callback to initialize
-- triangles/certain window-size dependent aspects of the ripple state.
function love.load()
	math.randomseed(os.time())
	diagnostics = false
	init_ripple_state()
	love.window.setMode(800, 600, { resizable = true })
	love.resize(love.window.getWidth(), love.window.getHeight())
end

-- Initializes the ripple state table, which is used to keep track of the current ripple (or whether
-- there is no current ripple.) The ripple state table also contains the ripple function, and also
-- has an update function and a function to reset to a newly rippling state.
function init_ripple_state()
	--ripple_state = { ripple_chance = 90, rippling = false, time_rippled = 0, ripple_width_coeff = 128, radius_per_time = 1, max_time = 60, min_time = -20, x_orig = 0, y_orig = 0 }
	ripple_state = { ripple_chance = 20, rippling = false, time_rippled = 0, ripple_width_coeff = 1, radius_per_time = 1.5, max_time = 20, min_time = 0, x_orig = 0, y_orig = 0 }

	function ripple_state.ripple_func(x, y)
		if ripple_state.rippling then
			return math.pi * math.exp((1/ripple_state.ripple_width_coeff) * -(math.sqrt((x - ripple_state.x_orig)^2 + (y - ripple_state.y_orig)^2) - (ripple_state.time_rippled * ripple_state.radius_per_time))^2)
		else
			return 0
		end
	end

	function ripple_state.update(dt)
		if ripple_state.rippling and ripple_state.time_rippled < ripple_state.max_time then
			ripple_state.time_rippled = ripple_state.time_rippled + dt * ripple_state.radius_per_time
		else
			ripple_state.time_rippled = 0
			ripple_state.rippling = false
		end
	end

	function ripple_state.begin_ripple(x, y)
		ripple_state.rippling = true
		ripple_state.time_rippled = ripple_state.min_time
		ripple_state.x_orig = x
		ripple_state.y_orig = y
	end
end

-- Love2D draw callback. Draws all of the triangles.
function love.draw()
	love.graphics.push()
	love.graphics.translate(love.window.getWidth()/2, love.window.getHeight()/2)
	love.graphics.scale(64, 64)

	for i,v in ipairs(triangles) do
		v.draw(ripple_state.ripple_func)
	end

	love.graphics.pop()

	if diagnostics then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.print("[Ripple time: " .. ripple_state.time_rippled .. "/" .. ripple_state.max_time .. "]", 8, 8)
	end
end

-- Update the triangle locations as well as the ripple state.
function love.update(dt)
	for i,v in ipairs(triangles) do
		v.update(dt, width)
	end

	if not ripple_state.rippling and math.random(ripple_state.ripple_chance) == 1 then
		ripple_state.begin_ripple(math.random(width * 2) - width, math.random(height * 2) - height)
	end
	ripple_state.update(dt)
end