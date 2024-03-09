local Object = require "libs/classic"
local vector = require "libs/hump/vector"

local Entity = Object:extend()

function Entity:new(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.velocity = vector(0, 0)
end

function Entity:update(dt)
    if self.velocity.x ~= 0 or self.velocity.y ~= 0 then
        self.x = self.x + (self.velocity.x * dt)
        self.y = self.y + (self.velocity.y * dt)

        if self.x < 0 then
            self.x = window_size.w
        elseif self.x > window_size.w then
            self.x = 0
        end

        if self.y < 0 then
            self.y = window_size.h
        elseif self.y > window_size.h then
            self.y = 0
        end
    end
end

function Entity:center()
    return vector(self.x + (self.w / 2), self.y + (self.h / 2))
end

return Entity
