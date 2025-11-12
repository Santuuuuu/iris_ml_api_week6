-- stress-test.lua
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"

init = function(args)
    math.randomseed(os.time())
    requests = 0
end

request = function()
    -- Generate random iris features for more realistic testing
    local sepal_length = 4 + math.random() * 4
    local sepal_width = 2 + math.random() * 2
    local petal_length = 1 + math.random() * 5
    local petal_width = 0.1 + math.random() * 2
    
    local body = string.format('{"features": [%.2f, %.2f, %.2f, %.2f]}', 
        sepal_length, sepal_width, petal_length, petal_width)
    
    requests = requests + 1
    if requests % 100 == 0 then
        print("Completed " .. requests .. " requests")
    end
    
    wrk.body = body
    return wrk.format()
end

response = function(status, headers, body)
    if status ~= 200 then
        print("Error " .. status .. ": " .. body)
    end
end
