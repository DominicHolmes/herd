local Entity = require "entity"
local Sheep = Entity:extend()

local Action = enum { "grazing", "walking", "herding" }
Sheep.Action = Action

function Sheep:new(x, y)
    Sheep.super.new(self, x, y, 10, 10)
    self.action = Action.walking
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
            -- Check distance
            if neighbor:center():dist(pos) > VISION_RAD then goto continue end
            -- The point is close enough. Check the vision cone
            -- -0.707

            -- When stationary, assume a 360 deg vision cone
            if self.velocity == vector(0, 0) then
                NEIGHBORS[self][neighbor] = true
            else
                -- When not stationary, assume a 90 degree blind spot directly behind
                -- forward direction of movement
                local angle_to_neighbor = self.velocity:angleTo(
                    neighbor:center() - pos
                )
                local lb = (math.pi * 3 / 4) -- 135 deg
                local ub = (math.pi * 5 / 4) -- 225 deg
                if angle_to_neighbor < lb or angle_to_neighbor > ub then
                    NEIGHBORS[self][neighbor] = true
                end
            end
            ::continue::
        end
    end
end

function Sheep:avoid_neighbors(power)
    local maintain_distance = 15 -- distance to maintain from other sheep

    local move = vector(0, 0)
    local pos = self:center()
    for neighbor, _ in pairs(NEIGHBORS[self]) do
        if pos:dist(neighbor:center()) < maintain_distance then
            move.x = move.x + (self.x - neighbor.x)
            move.y = move.y + (self.y - neighbor.y)
        end
    end

    self.velocity.x = self.velocity.x + (move.x * power)
    self.velocity.y = self.velocity.y + (move.y * power)
end

function Sheep:seek_flock_center(power)
    local center = self:center()
    local num_flock = 1

    for neighbor, _ in pairs(NEIGHBORS[self]) do
        if neighbor.action == Action.walking then
            center = center + neighbor:center()
            num_flock = num_flock + 1
        end
    end

    center = center / num_flock
    self.velocity = self.velocity + ((center - self:center()) * power)
end

function Sheep:match_neighbors_velocities(power)
    local avg_velocity = vector(0, 0)
    local walkers = 0

    for neighbor, _ in pairs(NEIGHBORS[self]) do
        if neighbor.action == Action.walking then
            avg_velocity = avg_velocity + neighbor.velocity
            walkers = walkers + 1
        end
    end

    if walkers == 0 then
        return
    end

    avg_velocity = avg_velocity / walkers
    self.velocity = self.velocity + ((avg_velocity - self.velocity) * power)
end

function Sheep.update(self, dt)
    if self.action == Action.grazing then
        -- 1/60 chance each frame to start walking
        if love.math.random(1, 60) == 1 then
            self.action = Action.walking
            self.velocity = vector(
                love.math.random(50, 60), love.math.random(50, 60)
            )
        end
        -- elseif self.action == Action.walking then
        --     -- 1/300 chance each frame to start grazing
        --     if love.math.random(1, 10000) == 1 then
        --         self.action = Action.grazing
        --         self.velocity = vector(0, 0)
        --     end
    end

    Sheep.super.update(self, dt)
    if self.action == Action.walking then
        self:update_neighbors()
        self:seek_flock_center(0.001)
        self:avoid_neighbors(0.05)
        self:match_neighbors_velocities(0.05)
    end
end

function Sheep:draw()
    love.graphics.setColor(1, 1, 1)
    if self == SHEEPS[1] then
        love.graphics.setColor(1, 1, 0)
        local c = self:center()
        if self.velocity == vector.zero then
            love.graphics.circle("line", c.x, c.y, VISION_RAD)
        else
            local angle_to_vel = self.velocity:angleTo(vector(1, 0))
            local a1 = (math.pi * 2) + (math.pi * 3 / 4) + angle_to_vel
            local a2 = (math.pi * 5 / 4) + angle_to_vel
            love.graphics.arc("line", "pie", c.x, c.y, VISION_RAD, a1, a2)
        end
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
