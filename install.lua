local repo, branch = ...
repo = repo or 'jkeDev/CC-Automated'
branch = branch or 'main'

local basePath = ('https://raw.githubusercontent.com/%s/%s/'):format(repo, branch)

local function log(lvl, ...)
    (lvl > 0 and io.stderr or io.stdout)
        :write(({[0] =
            "[INFO ] ",
            "[WARN ] ",
            "[ERROR] "})[lvl]
            .. string.format(...))
end
local function resolve(path, base)
    base = base or basePath .. 'src/'
    return base .. path
end
local function request(...)
    local path = resolve(...)
    local response, err = http.get(path)
    local status        = response.getResponseCode()
    local triesLeft     = 3
    while (status ~= 200 or err ~= nil) and triesLeft > 0 do
        response.close()
        log(1, "Could not fetch file /%s (%s)", path, err or tostring(status))
        triesLeft = triesLeft - 1
        status, response = http.get(path)
    end
    if status ~= 200 then
        response.close()
        log(2, "All retries failed...")
        return nil
    else return response end
end

log(0, "Fetching index from %s", resolve('index')) 
local response = request('index')
if response ~= nil then
    for path in response.readLine do
        log(0, "Downloading %s", path)
        local source = request(path)
        local target = fs.open(path, 'w')
        if source == nil then
            log(2, "Could not read file %s...", path)
        elseif type(target) ~= 'table' then
            log(2, "Could not open file %s...", path)
            source.close()
        else
            target.write(
                -- TODO: Check if multiple arguments to write are an issue
                source.readAll()
                :gsub('%s+', ' '))
            target.close()
            source.close()
        end
    end
    response.close()
end
