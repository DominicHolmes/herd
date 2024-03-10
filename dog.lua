local Entity = require "entity"
local Dog = Entity:extend()

local Action = enum { "idle", "standing", "running" }
Dog.Action = Action

local animation = {}
local anim_facing_right = true

function Dog:new(x, y)
    Dog.super.new(self, x, y, 8, 8)
    self.action = Action.idle
    self.speed = 7500

    -- Setup animations
    local anim8 = require "libs/anim8"
    animation[Action.idle] = anim8.newAnimation(sprite_grid(10, "1-2"), 0.8)
    animation[Action.standing] = anim8.newAnimation(sprite_grid(10, "3-4"), 0.8)
    animation[Action.running] = anim8.newAnimation(sprite_grid(10, "5-6"), 0.05)
end

function Dog:update(dt)
    local dv = vector(0, 0)
    if love.keyboard.isDown('w', "up") then
        dv.y = dv.y - 1
    end
    if love.keyboard.isDown('s', "down") then
        dv.y = dv.y + 1
    end
    if love.keyboard.isDown('a', "left") then
        dv.x = dv.x - 1
    end
    if love.keyboard.isDown('d', "right") then
        dv.x = dv.x + 1
    end
    dv:normalizeInplace()

    if dv.x ~= 0 then
        if (dv.x < 0 and anim_facing_right) or
            (dv.x > 0 and not anim_facing_right) then
            animation[Action.idle]:flipH()
            animation[Action.standing]:flipH()
            animation[Action.running]:flipH()
            anim_facing_right = not anim_facing_right
        end
    end

    self.velocity = self.speed * dv * dt

    if self.velocity:len() > 0 then
        self.action = Action.running
    elseif self.action == Action.running then
        self.action = Action.standing
    end

    animation[self.action]:update(dt)
    Dog.super.update(self, dt)
end

function Dog:draw()
    love.graphics.setColor(1, 1, 1)
    animation[self.action]:draw(sprite_image, self.x, self.y)
end

return Dog
