local DataStoreService=game:GetService('DataStoreService')
local HttpService=game:GetService('HttpService')
local RunService=game:GetService('RunService')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local P={Sessions={}}
local memory=RunService:IsStudio() and not Config.StudioPersistence
local store=if not memory then DataStoreService:GetDataStore(Config.SaveKey) else nil
local LEASE=180
local function copy(t)
    local out={}
    for k,v in t do out[k]=if type(v)=='table' then copy(v) else v end
    return out
end
function P.load(player)
    if memory then
        P.Sessions[player]={Data=Rules.newProfile(),Memory=true,LastSave=os.time()}
        return P.Sessions[player].Data
    end
    local token=game.JobId..':'..HttpService:GenerateGUID(false)
    for attempt=1,4 do
        local ok,result=pcall(function()
            return store:UpdateAsync('Player_'..player.UserId,function(old)
                if old~=nil and type(old)~='table' then error('Invalid profile envelope') end
                old=old or {Data=Rules.newProfile()}
                if old.Lock and old.Lock.Token~=token and (old.Lock.Expires or 0)>os.time() then return nil end
                return {Data=Rules.reconcile(old.Data),Lock={Token=token,Expires=os.time()+LEASE}}
            end)
        end)
        if ok and result and result.Lock and result.Lock.Token==token then
            local data=Rules.reconcile(result.Data)
            P.Sessions[player]={Data=data,Token=token,LastSave=os.time()}
            if not player.Parent then P.save(player,true); P.Sessions[player]=nil; return nil end
            return data
        end
        if not ok then warn('Profile load failed',player.UserId,result) end
        if attempt<4 then task.wait(attempt*2) end
    end
    if player.Parent then player:Kick('Your save is unavailable or still open on another server. Please rejoin shortly; no progress was overwritten.') end
    return nil
end
function P.save(player,release)
    local s=P.Sessions[player]
    if not s then return true end
    while s.Saving do task.wait(0.05) end
    if s.Released then return true end
    if s.Memory then if release then s.Released=true end; return true end
    if s.Lost then return false end
    s.Saving=true
    local snapshot=copy(s.Data)
    local saved=false
    for attempt=1,3 do
        local lost=false
        local ok,result=pcall(function()
            return store:UpdateAsync('Player_'..player.UserId,function(old)
                if not old or not old.Lock or old.Lock.Token~=s.Token then lost=true; return nil end
                return {Data=snapshot,Lock=if release then nil else {Token=s.Token,Expires=os.time()+LEASE}}
            end)
        end)
        if ok and result and not lost then saved=true; s.LastSave=os.time(); break end
        if lost then s.Lost=true; break end
        warn('Profile save retry',player.UserId,attempt,result)
        if attempt<3 then task.wait(attempt) end
    end
    s.Saving=false
    if saved and release then s.Released=true end
    if s.Lost or (not saved and os.time()-s.LastSave>LEASE-35) then
        s.Lost=true
        if player.Parent then player:Kick('Saving connection lost. Please rejoin to protect your saved progress.') end
    end
    return saved
end
function P.get(player)
    local s=P.Sessions[player]
    return if s and not s.Lost and not s.Released and not s.Closing then s.Data else nil
end
function P.start()
    if memory then warn('Ghostlight Hollow: Studio practice session. Persistence is intentionally OFF.') end
    task.spawn(function()
        while task.wait(45) do
            for player,s in P.Sessions do if not s.Closing then task.spawn(P.save,player,false) end end
        end
    end)
end
P.Memory=memory
return P
