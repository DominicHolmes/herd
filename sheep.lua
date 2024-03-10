local Entity = require "entity"
local Sheep = Entity:extend()

local Action = enum { "grazing", "walking", "herding" }
Sheep.Action = Action

function Sheep:new(x, y)
    Sheep.super.new(self, x, y, 8, 8)
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
    for _, bucket in ipairs(get_buckets_surrounding(self.bucket, false)) do
        local bucket_num = get_bucket_number_from_vector(bucket)
        for neighbor, _ in pairs(BUCKETS[bucket_num]) do
            if neighbor == self then goto continue end
            -- Check distance
            if neighbor:center():dist(pos) > VISION_RAD then goto continue end
            -- The point is close enough. Check the vision cone
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
    -- distance to maintain from other sheep
    local maintain_distance = self.w * 1.5
    local move = vector(0, 0)
    local pos = self:center()
    for neighbor, _ in pairs(NEIGHBORS[self]) do
        if pos:dist(neighbor:center()) < maintain_distance then
            move = move - (neighbor:center() - pos)
        end
    end
    return move * power
end

function Sheep:seek_flock_center(power)
    local avg_center = vector(0, 0)
    local num_flock = 0
    for neighbor, _ in pairs(NEIGHBORS[self]) do
        if neighbor.action == Action.walking then
            avg_center = avg_center + neighbor:center()
            num_flock = num_flock + 1
        end
    end
    if num_flock == 0 then return vector(0, 0) end
    avg_center = avg_center / num_flock
    -- velocity vector to push a sheep toward the flock's center
    return power * (avg_center - self:center())
end

function Sheep:match_neighbor_velocity(power)
    local avg_velocity = vector(0, 0)
    local num_flock = 0
    for neighbor, _ in pairs(NEIGHBORS[self]) do
        avg_velocity = avg_velocity + neighbor.velocity
        num_flock = num_flock + 1
    end
    if num_flock == 0 then return vector(0, 0) end
    avg_velocity = avg_velocity / num_flock
    return power * (avg_velocity - self.velocity)
end

function Sheep:avoid_obstacles(power)
    local result = self:center() + (self.velocity)
    local nudge = vector(0, 0)
    local nudge_amount = 20
    local dist_to_edge = 100
    if result.x < dist_to_edge then
        if result.y > window_size.h / 2 then
            -- Steer toward top right
            nudge = nudge + vector(nudge_amount, -nudge_amount)
        else
            -- Steer toward bottom right
            nudge = nudge + vector(nudge_amount, nudge_amount)
        end
    elseif result.x > window_size.w - dist_to_edge then
        if result.y > window_size.h / 2 then
            -- Steer toward top left
            nudge = nudge + vector(-nudge_amount, -nudge_amount)
        else
            -- Steer toward bottom left
            nudge = nudge + vector(-nudge_amount, nudge_amount)
        end
    end
    if result.y < dist_to_edge then
        if result.x > window_size.w / 2 then
            -- Steer toward bottom left
            nudge = nudge + vector(-nudge_amount, nudge_amount)
        else
            -- Steer toward bottom right
            nudge = nudge + vector(nudge_amount, nudge_amount)
        end
    elseif result.y > window_size.h - dist_to_edge then
        if result.x > window_size.w / 2 then
            -- Steer toward top left
            nudge = nudge + vector(-nudge_amount, -nudge_amount)
        else
            -- Steer toward top right
            nudge = nudge + vector(nudge_amount, -nudge_amount)
        end
    end
    return power * nudge
end

function Sheep:tend_toward_location(location, power)
    -- if power > 0, scale force to be stronger when further from target
    -- if power < 0, scale force to be weaker when further from target
    local toward_loc = (location - self:center()):normalized()

    -- we have a vector pointing toward target
    -- get the length of the vector
    local distance_scale = 200
    local distance_to_loc = math.min(location:dist(self:center()), distance_scale)

    local distance_scaler = 0
    if power < 0 then
        distance_scaler = (distance_scale - distance_to_loc) / distance_scale
    else
        distance_scaler = distance_to_loc / distance_scale
    end

    return toward_loc * power * distance_scaler * 20
end

function Sheep.update(self, dt)
    if self.action == Action.walking then
        self:update_neighbors()
        local v1 = self:seek_flock_center(POWER.flock / 100)
        local v2 = self:avoid_neighbors(POWER.repel)
        local v3 = self:match_neighbor_velocity(POWER.align)
        local v4 = self:avoid_obstacles(POWER.wall)

        if POWER.scatter then
            v1 = -v1
        end

        local total_dv = (v1 + v2 + v3 + v4) * dt

        -- optional extras
        if mouse_position ~= vector(0, 0) then
            local v5 = self:tend_toward_location(mouse_position, POWER.follow)
            total_dv = total_dv + (v5 * dt)
        end

        -- apply flock behaviors to velocity
        self.velocity = self.velocity + total_dv
        if self.velocity:len() > 200 then
            self.velocity = self.velocity:normalizeInplace() * 200
        end
    end

    -- apply velocity changes
    Sheep.super.update(self, dt)
    -- update animation
    sheep_animation:update(dt)
end

function Sheep:draw()
    love.graphics.setColor(1, 1, 1)
    if self == SHEEPS[1] and DEBUG_DRAW then
        love.graphics.setColor(1, 1, 0)
        local c = self:center()
        if self.velocity == vector(0, 0) then
            love.graphics.circle("line", c.x, c.y, VISION_RAD)
        else
            local angle_to_vel = self.velocity:angleTo(vector(1, 0))
            local a1 = (math.pi * 2) + (math.pi * 3 / 4) + angle_to_vel
            local a2 = (math.pi * 5 / 4) + angle_to_vel
            love.graphics.arc("line", "pie", c.x, c.y, VISION_RAD, a1, a2)
        end
        love.graphics.setColor(1, 0, 0)
    end
    if NEIGHBORS[SHEEPS[1]][self] and DEBUG_DRAW then
        -- Color neighbors yellow
        love.graphics.setColor(0.5, 0.5, 0)
    end

    sheep_animation:draw(sprite_image, self.x, self.y)

    if (self.velocity.x ~= 0 or self.velocity.y ~= 0) and DEBUG_DRAW then
        -- Draw a line that represents the direction of velocity
        love.graphics.setColor(0, 1, 0, 0.5)
        local vel_x = self.x + (self.w / 2) + (self.velocity.x * 0.4)
        local vel_y = self.y + (self.h / 2) + (self.velocity.y * 0.4)
        love.graphics.line(self.x + (self.w / 2), self.y + (self.h / 2), vel_x, vel_y)
        love.graphics.setColor(1, 1, 1)
    end
end

return Sheep
