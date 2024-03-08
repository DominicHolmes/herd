local function set(list)
    local s = {}
    for _, l in ipairs(list) do s[l] = true end
    return s
end

return set
