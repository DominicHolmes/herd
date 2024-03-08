function get_buckets_surrounding(b)
    local i = b % NUM_BUCKETS.y
    local j = math.floor(b / NUM_BUCKETS.y) + 1
end

-- Convert from x,y to bucket number 1 through N
function get_bucket_num(v)
    local bucket_i = math.min(1 + math.floor(v.x / VISION_RAD), NUM_BUCKETS.x)
    local bucket_j = math.min(math.floor(v.y / VISION_RAD), NUM_BUCKETS.y - 1)
    return bucket_i + (bucket_j * NUM_BUCKETS.y)
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
            BUCKETS[bucket_num] = {}
        end
    end

    -- 10 fps with 500 entities (unbucketed)
    for i = 1, 500 do
        local x = love.math.random(0, window_size.w)
        local y = love.math.random(0, window_size.h)
        local new_sheep = Sheep(x, y)
        table.insert(SHEEPS, new_sheep)
        local bucket_num = get_bucket_num(vector(x, y))
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
    for _, sheep in ipairs(SHEEPS) do
        sheep:draw()
    end

    -- Draw all buckets
    for i = 1, NUM_BUCKETS.x do
        for j = 1, NUM_BUCKETS.y do
            bucket_num = ((j - 1) * NUM_BUCKETS.x) + i
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
