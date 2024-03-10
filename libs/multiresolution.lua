-- makes all window operations
-- version 2022-09-18



local multiresolution = {}
local MR = multiresolution


-- add it to the main.lua
function MR.load(w, h, s)
    MR.width = w
    MR.height = h
    MR.resize() -- update new translation and scale
end

function MR.draw()
    -- before all other graphics
    love.graphics.translate(MR.translateX, MR.translateY)
    love.graphics.scale(MR.scale)
end

function MR.drawTestBackground()
    -- test background
    love.graphics.setColor(89 / 255, 157 / 255, 220 / 255) -- 599DDC
    love.graphics.rectangle('fill', 0, 0, MR.width, MR.height)
end

function MR.resize()                   -- update new translation and scale:
    local width, height = love.graphics.getDimensions()
    local w1, h1 = MR.width, MR.height -- target rendering resolution
    -- DOM: for perfect int scaling, add a math.floor here to scale
    local scale = math.min(width / w1, height / h1)
    MR.translateX = math.floor((width - w1 * scale) / 2 + 0.5)
    MR.translateY = math.floor((height - h1 * scale) / 2 + 0.5)
    MR.scale = scale
end

function MR.keypressed(key, scancode, isrepeat)
    if key == "f11" then
        MR.fullscreen = not MR.fullscreen
        love.window.setFullscreen(MR.fullscreen)
        MR.resize()
    end
end

----------------------------
--- replacing functions: ---
----------------------------

-- instead of love.mouse.getX ()
function MR.getMouseX()
    local mx = math.floor((love.mouse.getX() - MR.translateX) / MR.scale + 0.5)
    return mx
end

-- instead of love.mouse.getY ()
function MR.getMouseY()
    local my = math.floor((love.mouse.getY() - MR.translateY) / MR.scale + 0.5)
    return my
end

-- instead of love.mouse.getPosition ()
--love.mouse.getPosition ()
function MR.getMousePosition()
    return MR.getMouseX(), MR.getMouseY()
end

-- instead of love.graphics.getDimensions( )
function MR.getGraphicsDimensions()
    return MR.width, MR.height
end

return multiresolution
