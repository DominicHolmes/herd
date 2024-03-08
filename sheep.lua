local Entity = require "entity"
local Sheep = Entity:extend()

local Action = enum { "grazing", "walking", "herding" }
Sheep.Action = Action

local VISION_DISTANCE = 80

function Sheep:new(x, y)
    Sheep.super.new(self, x, y, 10, 10)
    self.action = Action.grazing
end

function Sheep:update_neighbors()
    local v1 = self:center()
    local n = {}
    for _, neighbor in ipairs(SHEEPS) do
        if neighbor == self then goto continue end
        if neighbor:center():dist(v1) <= VISION_DISTANCE then
            n[neighbor] = true
        end
        ::continue::
    end
    NEIGHBORS[self] = n
end

-- function Sheep:update_velocity(dt)
--     if self == sheeps[1] then
--         local n = self:neighbors()
--         sheep_1_neighbors = set(n)
--     end
-- end

function Sheep.update(self, dt)
    self:update_neighbors()

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
    love.graphics.setColor(1, 1, 1)
    if self == SHEEPS[1] then
        love.graphics.setColor(1, 0, 0, 0.2)
        local c = self:center()
        love.graphics.circle("line", c.x, c.y, VISION_DISTANCE)
        love.graphics.setColor(1, 0, 0)
    end
    if NEIGHBORS[SHEEPS[1]][self] then
        love.graphics.setColor(0.5, 0.5, 0)
    end
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
