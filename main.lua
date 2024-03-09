-- 10 fps with 500 entities (unbucketed)
-- steady 60 fps with 500 entities (bucketed)
-- steady 30 fps with 1000 entities (bucketed)
-- 20 fps with 1500, 12 fps with 2000 (bucketed)
local NUM_SHEEP = 20

function get_bucket_vector_from_number(b)
    local i = (b % NUM_BUCKETS.x)
    if i == 0 then
        i = NUM_BUCKETS.x
    end
    local j = math.floor((b - 1) / NUM_BUCKETS.x) + 1
    return vector(i, j)
end

function get_bucket_number_from_vector(v)
    return ((v.y - 1) * NUM_BUCKETS.x) + v.x
end

function get_bucket_vector_from_pixel(v)
    local bucket_i = math.min(1 + math.floor(v.x / VISION_RAD), NUM_BUCKETS.x)
    local bucket_j = math.min(1 + math.floor(v.y / VISION_RAD), NUM_BUCKETS.y)
    return vector(bucket_i, bucket_j)
end

function get_bucket_number_from_pixel(v)
    local clamped_pixel_vector = v:clamp(0, window_size.w, 0, window_size.h)
    return get_bucket_number_from_vector(
        get_bucket_vector_from_pixel(clamped_pixel_vector)
    )
end

function get_buckets_surrounding(b, wrap_around)
    local wrap = wrap_around or true
    local i, j = get_bucket_vector_from_number(b):unpack()
    local nearby = {}
    for x = -1 + i, 1 + i do
        for y = -1 + j, 1 + j do
            if wrap then
                -- Handle wraparound cases
                if x <= 0 then
                    x = NUM_BUCKETS.x
                end
                if y <= 0 then
                    y = NUM_BUCKETS.y
                end
                if x >= NUM_BUCKETS.x + 1 then
                    x = 1
                end
                if y >= NUM_BUCKETS.y + 1 then
                    y = 1
                end
                table.insert(nearby, vector(x, y))
            else
                -- Wraparound not supported, ignore invalid bucket numbers
                if x < 1 or y < 1 or x > NUM_BUCKETS.x
                    or y > NUM_BUCKETS.y then
                    table.insert(nearby, vector(x, y))
                end
            end
        end
    end
    return nearby
end

local function setup_sheep()
    local Sheep = require "sheep"

    VISION_RAD = 80
    SHEEPS = {}
    BUCKETS = {}
    NEIGHBORS = {}

    NUM_BUCKETS = vector(
        math.ceil(window_size.w / VISION_RAD),
        math.ceil(window_size.h / VISION_RAD)
    )

    -- Generate all buckets of size VISION_RADIUS
    for i = 1, NUM_BUCKETS.x do
        for j = 1, NUM_BUCKETS.y do
            bucket_num = get_bucket_number_from_vector(vector(i, j))
            BUCKETS[bucket_num] = {}
        end
    end

    for i = 1, NUM_SHEEP do
        local x = love.math.random(0, window_size.w)
        local y = love.math.random(0, window_size.h)
        local new_sheep = Sheep(x, y)
        table.insert(SHEEPS, new_sheep)
        local bucket_num = get_bucket_number_from_pixel(vector(x, y))
        new_sheep.bucket = bucket_num
        BUCKETS[bucket_num][new_sheep] = true
    end

    for i, sheep in ipairs(SHEEPS) do
        -- if i % 2 == 1 then
        sheep.velocity = vector(
            love.math.random(-1, 1),
            love.math.random(0, 1)
        ):normalized() * 150
        sheep.action = Sheep.Action.walking
        -- end
    end
end

function setup_sliders()
    require "libs/slider"
    POWER = {
        flock = 1,
        repel = 4,
        align = 2,
        wall = 8,
        follow = 4,
        scatter = false,
    }
    flockSlider = newSlider(100, 560, 150, POWER.flock, 0, 20, function(v) POWER.flock = v end)
    repelSlider = newSlider(300, 560, 150, POWER.repel, 0, 20, function(v) POWER.repel = v end)
    alignSlider = newSlider(500, 560, 150, POWER.align, 0, 20, function(v) POWER.align = v end)
    wallSlider = newSlider(700, 560, 150, POWER.wall, 0, 20, function(v) POWER.wall = v end)
end

function love.load()
    vector = require "libs/hump/vector"
    enum = require "libs/enum"
    set = require "libs/set"

    -- love.mouse.setVisible(false)
    mouse_position = vector(0, 0)

    window_size = {
        w = love.graphics.getWidth(),
        h = love.graphics.getHeight()
    }

    setup_sheep()
    setup_sliders()
end

function love.update(dt)
    for _, sheep in ipairs(SHEEPS) do
        sheep:update(dt)
    end

    flockSlider:update()
    wallSlider:update()
    alignSlider:update()
    repelSlider:update()

    -- local x, y = love.mouse.getPosition()
    local m_x, m_y = love.mouse.getPosition()
    mouse_position.x = m_x
    mouse_position.y = m_y
end

function love.draw()
    local highlight_bucket = SHEEPS[1].bucket

    for _, vec in ipairs(get_buckets_surrounding(highlight_bucket, false)) do
        local x = (vec.x - 1) * VISION_RAD
        local y = (vec.y - 1) * VISION_RAD
        local bucket_num = get_bucket_number_from_vector(vec)
        if bucket_num == highlight_bucket then
            love.graphics.setColor(0, 1, 0, 0.5)
        else
            love.graphics.setColor(0, 1, 0, 0.2)
        end
        love.graphics.rectangle("fill", x, y, VISION_RAD, VISION_RAD)
    end

    for _, sheep in ipairs(SHEEPS) do
        sheep:draw()
    end

    -- Draw all buckets
    for i = 1, NUM_BUCKETS.x do
        for j = 1, NUM_BUCKETS.y do
            local bucket_num = ((j - 1) * NUM_BUCKETS.x) + i
            local x = (i - 1) * VISION_RAD
            local y = (j - 1) * VISION_RAD
            love.graphics.setColor(0, 1, 0, 0.3)
            love.graphics.rectangle("line", x, y, VISION_RAD, VISION_RAD)
            love.graphics.print(bucket_num, x + 10, y + 10)
        end
    end

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)

    love.graphics.setColor(1, 1, 1, 0.8)
    flockSlider:draw()
    love.graphics.print("FLOCK " .. math.floor(POWER.flock), 80, 530)
    repelSlider:draw()
    love.graphics.print("REPEL " .. math.floor(POWER.repel), 280, 530)
    alignSlider:draw()
    love.graphics.print("ALIGN " .. math.floor(POWER.align), 480, 530)
    wallSlider:draw()
    love.graphics.print("WALL " .. math.floor(POWER.wall), 680, 530)
end

function love.keypressed(key)
    if key == "f1" or key == "q" then
        love.event.quit("restart")
    end

    if key == "r" then
        setup_sheep()
    end

    if key == "p" then
        POWER.flock = -POWER.flock
    end

    if key == "o" then
        POWER.follow = -POWER.follow
    end
end
