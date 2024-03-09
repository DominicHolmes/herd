local Entity = require "entity"
local Sheep = Entity:extend()

local Action = enum { "grazing", "walking", "herding" }
Sheep.Action = Action

function Sheep:new(x, y)
    Sheep.super.new(self, x, y, 10, 10)
    self.action = Action.grazing
    self.bucket = -1
end

function Sheep:update_neighbors()
    local pos = self:center()
    -- Update the bucket for this sheep, if needed
    local new_bucket = get_bucket_number_from_pixel(pos)
    if new_bucket ~= self.bucket then
        -- Remove from old bucket and add to new one
        BUCKETS[self.bucket][self] = nil
        BUCKETS[new_bucket][self] = true
        self.bucket = new_bucket
    end

    -- Update set of nearby neighbors, only checking the surrounding buckets
    NEIGHBORS[self] = {}
    for _, bucket in ipairs(get_buckets_surrounding(self.bucket)) do
        local bucket_num = get_bucket_number_from_vector(bucket)
        for neighbor, _ in pairs(BUCKETS[bucket_num]) do
            if neighbor == self then goto continue end
            if neighbor:center():dist(pos) <= VISION_RAD then
                NEIGHBORS[self][neighbor] = true
            end
            ::continue::
        end
    end
end

-- function Sheep:update_velocity(dt)
--     if self == sheeps[1] then
--         local n = self:neighbors()
--         sheep_1_neighbors = set(n)
--     end
-- end

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
    self:update_neighbors()
end

function Sheep:draw()
    love.graphics.setColor(1, 1, 1)
    if self == SHEEPS[1] then
        love.graphics.setColor(1, 0, 0)
        local c = self:center()
        love.graphics.circle("line", c.x, c.y, VISION_RAD)
        love.graphics.setColor(1, 0, 0)
    end
    if NEIGHBORS[SHEEPS[1]][self] then
        -- Color neighbors yellow
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
