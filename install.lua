local repo, branch = ...
repo = repo or 'jkeDev/CC-Automated'
branch = branch or 'main'

local basePath = ('https://raw.githubusercontent.com/%s/%s/'):format(repo, branch)

do 
    local maxLvl = -1
    local function log(lvl, ...)
        if type(lvl) ~= 'number'
            then return maxLvl end
        maxLvl = math.max(maxLvl, lvl)
        if lvl <
            settings.get('logging.level',
            branch == 'main' and 1 or 0)
            then return end
        (lvl > 0 and io.stderr or io.stdout)
            :write(({[0] =
                "[INFO ] ",
                "[WARN ] ",
                "[ERROR] "})[lvl]
                .. string.format(...))
    end
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
            target.write(source.readAll())
            target.close()
            source.close()
        end
    end
    response.close()
end

do
    log(0, "Setting allow_startup to true")
    settings.set("shell.allow_startup", true)
    settings.save()
    local maxLvl = log()
    log(0, "Max log level reached %i", maxLvl)
    if maxLvl > 1 then
        log(2, "Please fix errors before continuing.")
    elseif maxLvl > 0 then
        log(0, "Please review warnings before rebooting...")
    else os.reboot() end
end
