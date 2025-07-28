--!strict
--[[

        __                                         
       /\ \        __                              
       \ \ \      /\_\    __  __    ___     ___    
        \ \ \  __ \/\ \  /\ \/\ \  / __`\ /' _ `\  
         \ \ \L\ \ \ \ \ \ \ \_/ |/\ \L\ \/\ \/\ \ 
          \ \____/  \ \_\ \ \___/ \ \____/\ \_\ \_\
           \/___/    \/_/  \/__/   \/___/  \/_/\/_/
                                                                         

       🗒️ Creation Date : 2025-07-03
       📜 Last Updated  : 2025-07-03

       Sigma @1.0.0
]]

local HttpService = game:GetService('HttpService')

export type Connection<In...> = {
      Disconnect : (self : any) -> (),
      Function   : (In...) -> (),
      _uuid      : string,
      _once      : boolean
}

export type Sigma<Input...> = {
      Fire    : (self : any, Input...) -> (),
      
      Connect : (self : any, Output : (Input...) -> ()) -> Connection<(Input...) -> ()>,
      Once    : (self : any, Output : (Input...) -> ()) -> Connection<(Input...) -> ()>,
      Wait    : (self : any) -> Input...,
      
      __cache   : {[string] : Connection<Input...>},
      __waiting : { thread },
      
      Destroy : (self : any) -> ()
}

export type Constructor = {
      New  : <I...>() -> Sigma<I...>,
      --Wrap : <I, O>(Signal : RBXScriptSignal) -> Sigma<I,O>,
     
      __index : Constructor
} & Sigma<any>

local Sigma = {} :: Constructor
Sigma.__index = Sigma


function Sigma.New <I...>()
      local self= setmetatable({}, Sigma)
      
 
      
      self.__cache   = {}
      self.__waiting = {}
      
      return ( self :: any ) :: any
end

function Sigma:Fire(... : any)
      local self = self :: Sigma<any>

      for uuid, Connection in self.__cache do
            if Connection.Function then
                  task.spawn(Connection.Function, ...)
            end
            
            if Connection._once then
                  Connection:Disconnect()
            end
      end      
      
      for Index, Routine in self.__waiting do
            coroutine.resume(Routine, ...)
      end
end



function Sigma:Connect(Out : any )
      local _self = self :: Sigma<any>

      local NewConnection = {} :: Connection<typeof(Out)>
      local new_uuid      = HttpService:GenerateGUID()
      
      NewConnection.Function = Out
      NewConnection._uuid    = new_uuid
      NewConnection.Disconnect = function (self : typeof(NewConnection))
            if not _self.__cache[self._uuid] then return end
            
            _self.__cache[self._uuid] = nil
            self.Function = nil :: any
            self._uuid    = nil :: any
      end
      
      _self.__cache[new_uuid] = NewConnection
      
      return NewConnection
end


function Sigma:Once(Out : any )
      local _self = self :: Sigma<any>

      local NewConnection = {} :: Connection<typeof(Out)>
      local new_uuid      = HttpService:GenerateGUID()

      NewConnection.Function = Out
      NewConnection._uuid    = new_uuid
      NewConnection._once    = true
      NewConnection.Disconnect = function (self : typeof(NewConnection))
            if not _self.__cache[self._uuid] then return end

            _self.__cache[self._uuid] = nil
            self.Function = nil :: any
            self._uuid    = nil :: any
      end

      _self.__cache[new_uuid] = NewConnection
      
      return NewConnection
end

function Sigma:Wait()
      local self = self :: Sigma<any>
      
      local Routine = coroutine.running()
      
      table.insert(self.__waiting, Routine)
      
      return coroutine.yield()
end

function Sigma:Destroy ()
      local self = self :: Sigma<any>
      
      for uuid, Connection in self.__cache do
            Connection:Disconnect()
      end
      
      for Index, Thread in self.__waiting do
            coroutine.resume(Thread)
      end
      
      table.clear(self.__cache)
      table.clear(self.__waiting)
      
      table.clear(self :: any)
end


return Sigma
