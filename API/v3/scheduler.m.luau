return newcclosure(function(Library, Tabs, RootMaid, CacheManager, MaidClass)
    local RunService = game:GetService("RunService")
    
    local Scheduler = {}
    Scheduler.Throttle = 0 -- Global throttle in seconds
    Scheduler.RGBThrottle = 0 -- Specific throttle for RGB features

    local SchedulerMaid = MaidClass.new()
    RootMaid:GiveTask(SchedulerMaid)

    local ActiveIntervals = {}
    
    SchedulerMaid:GiveTask(RunService.Heartbeat:Connect(newcclosure(function()
        local now = os.clock()
        for i = #ActiveIntervals, 1, -1 do
            local taskObj = ActiveIntervals[i]
            -- Calculate effective rate: max of defined Rate or Global Throttle
            local effectiveRate = math.max(taskObj.Rate, Scheduler.Throttle)
            if not taskObj.Paused and (now - taskObj.LastRun >= effectiveRate) then
                taskObj.LastRun = now
                task.spawn(taskObj.Callback)
            end
        end
    end)))

    Scheduler.Interval = newcclosure(function(seconds, callback)
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
        
        function taskObj:Destroy() self:Disconnect() end

        SchedulerMaid:GiveTask(newcclosure(function() taskObj:Disconnect() end))
        return taskObj
    end)

    Scheduler.Delay = newcclosure(function(seconds, callback)
        local thread = task.delay(seconds, callback)
        SchedulerMaid:GiveTask(newcclosure(function() if thread then task.cancel(thread) end end))
        return thread
    end)
    
    Scheduler.Render = newcclosure(function(callback)
        local conn = RunService.RenderStepped:Connect(callback)
        SchedulerMaid:GiveTask(conn)
        return conn
    end)
    
    Scheduler.Heartbeat = newcclosure(function(callback)
        local conn = RunService.Heartbeat:Connect(callback)
        SchedulerMaid:GiveTask(conn)
        return conn
    end)

    getgenv().Scheduler = Scheduler
    RootMaid:GiveTask(newcclosure(function() getgenv().Scheduler = nil end))

    return Scheduler
end)
