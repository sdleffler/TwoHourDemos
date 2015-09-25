local graphics = love.graphics

love.window.setMode(0, 0, {fullscreen = true})

local function wait(t)
	while t > 0 do
		t = t - coroutine.yield()
	end
end

local canvas = graphics.newCanvas()

local function step(img, scale)
	canvas:renderTo(function()
		graphics.push 'all'
		graphics.setColor(0, math.random(64, 128) * scale, math.random(64, 128) * scale)
		if scale >= 1 then
			graphics.setColor(255, 0, 0)
		end
		graphics.translate(canvas:getWidth() / 2, canvas:getHeight() / 2 + img:getHeight() / 2)
		graphics.scale(scale, scale)
		graphics.draw(img, -img:getWidth() / 2, -img:getHeight())
		graphics.pop()
	end)
end

local game_img = graphics.newImage 'game.png'
local jam_img  = graphics.newImage 'jam.png'
local club_img = graphics.newImage 'club.png'

function love.draw()
	graphics.draw(canvas)
end

love.update = coroutine.wrap(function()
	while true do
		canvas:clear()
		for _, img in ipairs {game_img, jam_img, club_img} do
			for i = 1, 8 do
				step(img, i / 8)
				wait(0.1)
			end
		end
		wait(1)
		canvas:clear()
		for _, img in ipairs {game_img, jam_img, club_img} do
			step(img, 1)
		end
		wait(2)
	end
end)
