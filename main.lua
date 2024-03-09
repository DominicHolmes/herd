-- 10 fps with 500 entities (unbucketed)
-- steady 60 fps with 500 entities (bucketed)
-- steady 30 fps with 1000 entities (bucketed)
-- 20 fps with 1500, 12 fps with 2000 (bucketed)
local NUM_SHEEP = 50

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

    VISION_RAD = 100
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

function love.load()
    vector = require "libs/hump/vector"
    enum = require "libs/enum"
    set = require "libs/set"

    window_size = {
        w = love.graphics.getWidth(),
        h = love.graphics.getHeight()
    }

    setup_sheep()
end

function love.update(dt)
    for _, sheep in ipairs(SHEEPS) do
        sheep:update(dt)
    end
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
end

function love.keypressed(key)
    if key == "f1" then
        love.event.quit("restart")
    end
end
