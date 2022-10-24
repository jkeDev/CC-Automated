local repo, branch = ...
repo = repo or 'jkeDev/CC-Automated'
branch = branch or 'main'

local basePath = ('https://raw.githubusercontent.com/%s/%s/'):format(repo, branch)

local function log(...) io.stdout:write(string.format(...)) end
local function err(...) io.stderr:write(string.format(...)) end
local function resolve(path, base)
    base = base or basePath .. 'src/'
    return basePath .. path
end
local function request(...)
    local response  = http.get(resolve(...))
    local status    = request.getResponseCode()
    local triesLeft = 3
    while status ~= 200 and triesLeft > 0 do
        response.close()
        err("[FAIL ] Could not fetch file /%s", path)
        triesLeft = triesLeft - 1
        status, response = http.get(basePath .. path)
    end
    if status ~= 200 then
        response.close()
        err("[ERROR] All retries failed...")
        return nil
    else return response end
end

log("[INFO ] Fetching index from %s", resolve('index')) 
local response = request('index')
if response ~= nil then
    for _,path in response.readLine do
        log("[INFO ] Downloading %s", path)
        local source = request(path)
        local target = fs.open(path, 'w')
        if source == nil then
            err("[ERROR] Could not read file %s...", path)
        elseif type(target) ~= 'table' then
            err("[ERROR] Could not open file %s...", path)
            source.close()
        else
            target.write(source.readAll())
            target.close()
            source.close()
        end
    end
    response.close()
end
