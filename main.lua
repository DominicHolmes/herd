function love.load()
    window_size = {
        w = love.graphics.getWidth(),
        h = love.graphics.getHeight()
    }

    Sheep = require "sheep"
    SHEEPS = {}
    NEIGHBORS = {}
    for i = 1, 500 do
        local x = love.math.random(0, window_size.w)
        local y = love.math.random(0, window_size.h)
        table.insert(SHEEPS, Sheep(x, y))
    end
    for i, sheep in ipairs(SHEEPS) do
        if i % 2 == 1 then
            sheep.velocity = {
                x = love.math.random(-20, 20),
                y = love.math.random(-20, 20)
            }
            sheep.action = Sheep.Action.walking
        end
    end
end

function love.update(dt)
    for _, sheep in ipairs(SHEEPS) do
        sheep:update(dt)
    end
end

function love.draw()
    for _, sheep in ipairs(SHEEPS) do
        sheep:draw()
    end
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
end

function love.keypressed(key)
    if key == "f1" then
        love.event.quit("restart")
    end
end
