return function(Library, Tabs, RootMaid, CacheManager, MaidClass)
    local RunService = game:GetService("RunService")

    local Scheduler = {}
    local SchedulerMaid = MaidClass.new()
    RootMaid:GiveTask(SchedulerMaid)

    local ActiveIntervals = {}

    SchedulerMaid:GiveTask(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for i = #ActiveIntervals, 1, -1 do
            local taskObj = ActiveIntervals[i]
            if not taskObj.Paused and (now - taskObj.LastRun >= taskObj.Rate) then
                taskObj.LastRun = now
                task.spawn(taskObj.Callback)
            end
        end
    end))

    function Scheduler.Interval(seconds, callback)
        local taskObj = {
            Rate = seconds,
            Callback = callback,
            LastRun = os.clock(),
            Paused = false,
            Destroyed = false
        }

        table.insert(ActiveIntervals, taskObj)

        function taskObj:Pause() self.Paused = true end
        function taskObj:Resume() self.Paused = false; self.LastRun = os.clock() end
        function taskObj:RunNow() task.spawn(self.Callback); self.LastRun = os.clock() end

        function taskObj:Disconnect()
            if self.Destroyed then return end
            self.Destroyed = true
            for i, t in ipairs(ActiveIntervals) do
                if t == self then table.remove(ActiveIntervals, i); break end
            end
        end

        SchedulerMaid:GiveTask(function() taskObj:Disconnect() end)

        return taskObj
    end

    function Scheduler.Delay(seconds, callback)
        local thread = task.delay(seconds, callback)
        SchedulerMaid:GiveTask(function() if thread then task.cancel(thread) end end)
        return thread
    end

    function Scheduler.Throttle(seconds, func)
        local lastCall = 0
        return function(...)
            local now = os.clock()
            if now - lastCall >= seconds then
                lastCall = now
                return func(...)
            end
        end
    end

    function Scheduler.Debounce(seconds, func)
        local thread
        return function(...)
            local args = {...}
            if thread then task.cancel(thread) end
            thread = task.delay(seconds, function()
                func(unpack(args))
            end)
        end
    end

    getgenv().Scheduler = Scheduler
    RootMaid:GiveTask(function() getgenv().Scheduler = nil end)

    return Scheduler
end
