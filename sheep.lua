local enum = require "libs/enum"
local Entity = require "entity"
local Sheep = Entity:extend()

local Action = enum { "grazing", "walking", "herding" }
Sheep.Action = Action

assert(Action.grazing == Action.grazing)
assert(Action.grazing ~= Action.walking)

function Sheep:new(x, y)
    Sheep.super.new(self, x, y, 10, 10)
    self.action = Action.grazing
end

function Sheep.update(self, dt)
    if self.action == Action.grazing then
        -- 1/60 chance each frame to start walking
        if love.math.random(1, 60) == 1 then
            self.action = Action.walking
            self.velocity = {
                x = love.math.random(-20, 20),
                y = love.math.random(-20, 20)
            }
        end
    elseif self.action == Action.walking then
        -- 1/300 chance each frame to start grazing
        if love.math.random(1, 300) == 1 then
            self.action = Action.grazing
            self.velocity = { x = 0, y = 0 }
        end
    end

    Sheep.super.update(self, dt)
end

function Sheep:draw()
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    if self.velocity.x ~= 0 or self.velocity.y ~= 0 then
        -- Draw a line that represents the direction of velocity
        love.graphics.setColor(0, 1, 0, 0.5)
        local vel_x = self.x + (self.w / 2) + (self.velocity.x * 1)
        local vel_y = self.y + (self.h / 2) + (self.velocity.y * 1)
        love.graphics.line(self.x + (self.w / 2), self.y + (self.h / 2), vel_x, vel_y)
        love.graphics.setColor(1, 1, 1)
    end
end

return Sheep
