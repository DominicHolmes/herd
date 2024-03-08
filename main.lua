function love.load()
    window_size = {
        w = love.graphics.getWidth(),
        h = love.graphics.getHeight()
    }

    Sheep = require "sheep"
    sheeps = {}
    for i = 1, 100 do
        local x = love.math.random(0, window_size.w)
        local y = love.math.random(0, window_size.h)
        table.insert(sheeps, Sheep(x, y))
    end
    for i, sheep in ipairs(sheeps) do
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
    for _, sheep in ipairs(sheeps) do
        sheep:update(dt)
    end
end

function love.draw()
    for _, sheep in ipairs(sheeps) do
        sheep:draw()
    end
end

function love.keypressed(key)
    if key == "f1" then
        love.event.quit("restart")
    end
end
