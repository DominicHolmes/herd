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

function get_bucket_number_from_pixel(v)
    local bucket_i = math.min(1 + math.floor(v.x / VISION_RAD), NUM_BUCKETS.x)
    local bucket_j = math.min(math.floor(v.y / VISION_RAD), NUM_BUCKETS.y - 1)
    return bucket_i + (bucket_j * NUM_BUCKETS.y)
end

function get_buckets_surrounding(b)
    local i, j = get_bucket_vector_from_number(b):unpack()
    local nearby = {}
    for x = -1 + i, 1 + i do
        for y = -1 + j, 1 + j do
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
        end
    end
    return nearby
end

local function setup_sheep()
    local Sheep = require "sheep"

    VISION_RAD = 50
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
            bucket_num = ((j - 1) * NUM_BUCKETS.x) + i
            -- if not (vector(i, j) == get_buckets_surrounding(bucket_num)) then
            --     print("num buckets: ", NUM_BUCKETS)
            --     print("NOT EQUAL: ")
            --     print("bucket_num " .. bucket_num)
            --     local m = get_buckets_surrounding(bucket_num)
            --     print("original: ")
            --     print("i: ", i, "   j: ", j)
            --     print("after func call: ")
            --     print("i: ", m.x, "   j: ", m.y)
            --     assert(false)
            -- end
            BUCKETS[bucket_num] = {}
        end
    end

    for _, b in ipairs(get_buckets_surrounding(80)) do
        -- print(b)
        print(get_bucket_number_from_vector(b))
    end

    -- 10 fps with 500 entities (unbucketed)
    for i = 1, 500 do
        local x = love.math.random(0, window_size.w)
        local y = love.math.random(0, window_size.h)
        local new_sheep = Sheep(x, y)
        table.insert(SHEEPS, new_sheep)
        local bucket_num = get_bucket_number_from_pixel(vector(x, y))
        new_sheep.bucket_num = bucket_num
        BUCKETS[bucket_num][new_sheep] = true
    end

    for i, sheep in ipairs(SHEEPS) do
        if i % 2 == 1 then
            sheep.velocity = {
                x = love.math.random(-30, 30),
                y = love.math.random(-30, 30)
            }
            sheep.action = Sheep.Action.walking
        end
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
    for _, vec in ipairs(get_buckets_surrounding(18)) do
        local x = (vec.x - 1) * VISION_RAD
        local y = (vec.y - 1) * VISION_RAD
        local bucket_num = get_bucket_number_from_vector(vec)
        if bucket_num == 18 then
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
