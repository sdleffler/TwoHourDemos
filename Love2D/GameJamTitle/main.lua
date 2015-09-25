local graphics = love.graphics

graphics.setDefaultFilter('nearest')

love.window.setMode(0, 0, {fullscreen = true})

local function wave(neutral, amp, omega, phase)
	return function(t)
		return neutral + amp * math.cos(omega * t + phase)
	end
end

math.randomseed(os.time())

local stars = {}

for i = 1, 5000 do
	table.insert(stars, {
		x = math.random(-graphics.getWidth(), graphics.getWidth());
		y = math.random(-graphics.getHeight(), graphics.getHeight());
		z = math.random(0, 100);
	})
end

local objects = {
	{
		img = graphics.newImage 'game.png';
		scale = wave(2, 0.1, math.random() + 1, math.random() * 100);
		angle = wave(0, 0.025, math.sqrt(2), math.random() * 100);
		pos = {0, 0};
	};
	
	{
		img = graphics.newImage 'jam.png';
		scale = wave(2, 0.1, math.random() + 1, math.random() * 100);
		angle = wave(0, 0.025, math.sqrt(2), math.random() * 100);
		pos = {0, 0};
	};
	
	{
		img = graphics.newImage 'club.png';
		scale = wave(2, 0.1, math.random() + 1, math.random() * 100);
		angle = wave(0, 0.025, math.sqrt(2), math.random() * 100);
		pos = {0, 0};
	};
}

local t = 0

function love.draw()
	graphics.push()
	graphics.translate(graphics.getWidth() / 2, graphics.getHeight() / 2)
	
	graphics.setPointSize(4)
	for _, star in ipairs(stars) do
		local x = star.x / star.z
		local y = star.y / star.z
		graphics.setColor(255, 255, 255, math.min(255, 255 / star.z))
		graphics.rectangle('fill', x, y, 5 / star.z, 5 / star.z)
	end
	
	graphics.setColor(255, 255, 255)
	for _, obj in ipairs(objects) do
		local img = obj.img
		graphics.push()
		graphics.translate(unpack(obj.pos))
		graphics.rotate(obj.angle(t))
		graphics.scale(obj.scale(t))
		graphics.draw(img, -img:getWidth() / 2, -img:getHeight() / 2)
		graphics.pop()
	end
	graphics.pop()
end

local speed = 1

function love.update(dt)
	t = t + dt
	
	for _, star in ipairs(stars) do
		star.z = star.z - speed * dt
		star.z = star.z % 100
	end
end
