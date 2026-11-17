-- Minimal event-driven Roblox mock for UI logic tests. No renderer or network.
local function signal()
    local callbacks={}
    return {
        Connect=function(_,fn)
            local connection={Connected=true}
            function connection:Disconnect() self.Connected=false end
            table.insert(callbacks,{connection,fn})
            return connection
        end,
        Fire=function(_,...)
            for _,entry in ipairs(table.clone(callbacks)) do
                if entry[1].Connected then entry[2](...) end
            end
        end,
    }
end
local Enum=setmetatable({},{__index=function(self,name)
    local group=setmetatable({},{__index=function(t,key)
        local value={Name=key,EnumType=t,_type="EnumItem"}
        rawset(t,key,value) return value
    end})
    rawset(self,name,group) return group
end})
local nativeTypeof=typeof
local function typeof(value) return type(value)=="table" and value._type or nativeTypeof(value) end
local Vector2={}
local vectorMt={__sub=function(a,b) return Vector2.new(a.X-b.X,a.Y-b.Y) end}
function Vector2.new(x,y) return setmetatable({X=x or 0,Y=y or 0},vectorMt) end
local UDim={new=function(s,o) return {Scale=s or 0,Offset=o or 0} end}
local UDim2={}
function UDim2.new(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local Color3={}
local colorMethods={}
local colorMt={__index=colorMethods,__eq=function(a,b) return a.R==b.R and a.G==b.G and a.B==b.B end}
function Color3.new(r,g,b) return setmetatable({_type="Color3",R=r or 0,G=g or 0,B=b or 0},colorMt) end
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
function Color3.fromHSV(h,s,v)
    local chroma=v*s local x=chroma*(1-math.abs((h*6)%2-1)) local m=v-chroma
    local colors={{chroma,x,0},{x,chroma,0},{0,chroma,x},{0,x,chroma},{x,0,chroma},{chroma,0,x}}
    local c=colors[math.floor(h*6)%6+1]
    return Color3.new(c[1]+m,c[2]+m,c[3]+m)
end
function colorMethods:ToHSV()
    local hi,lo=math.max(self.R,self.G,self.B),math.min(self.R,self.G,self.B)
    local d=hi-lo local h=0
    if d>0 then
        if hi==self.R then h=((self.G-self.B)/d)%6
        elseif hi==self.G then h=(self.B-self.R)/d+2
        else h=(self.R-self.G)/d+4 end
    end
    return h/6,hi==0 and 0 or d/hi,hi
end
function colorMethods:ToHex()
    return string.format("%02X%02X%02X",math.round(self.R*255),math.round(self.G*255),math.round(self.B*255))
end
function colorMethods:Lerp(c,t) return Color3.new(self.R+(c.R-self.R)*t,self.G+(c.G-self.G)*t,self.B+(c.B-self.B)*t) end
local ColorSequence={new=function(...) return {...} end}
local NumberSequence={new=function(...) return {...} end}
local ColorSequenceKeypoint={new=function(...) return {...} end}
local methods={}
local Instance={}
function Instance.new(class)
    local props={ClassName=class,Name=class,_type="Instance",Size=UDim2.fromOffset(0,0),Position=UDim2.fromOffset(0,0),
        AnchorPoint=Vector2.new(),AbsolutePosition=Vector2.new(),AbsoluteSize=Vector2.new(1280,800),
        Text="",TextSize=11,TextTransparency=0,BackgroundTransparency=0,Visible=true,ZIndex=1,Active=true}
    local children,events,changed={},{},{}
    local object={_props=props,_children=children,_events=events,_changed=changed}
    return setmetatable(object,{
        __index=function(_,key)
            if key=="TextBounds" then return Vector2.new(#props.Text*5,11) end
            if methods[key] then return methods[key] end
            if props[key]~=nil then return props[key] end
            if key:match("Changed$") or table.find({"Activated","MouseEnter","MouseLeave","InputBegan","InputEnded","Destroying","Focused","FocusLost","MouseButton2Click"},key) then
                events[key]=events[key] or signal() return events[key]
            end
        end,
        __newindex=function(self,key,value)
            local old=props[key]
            if key=="Parent" and old~=value then
                if old then local i=table.find(old._children,self) if i then table.remove(old._children,i) end end
                if value then table.insert(value._children,self) end
            end
            props[key]=value
            if old~=value and changed[key] then changed[key]:Fire() end
        end,
    })
end
function methods:IsA(class) return self.ClassName==class end
function methods:GetPropertyChangedSignal(key)
    self._changed[key]=self._changed[key] or signal() return self._changed[key]
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
    local result={}
    for _,child in ipairs(self._children) do
        table.insert(result,child)
        for _,descendant in ipairs(child:GetDescendants()) do table.insert(result,descendant) end
    end
    return result
end
function methods:FindFirstChild(name)
    for _,child in ipairs(self._children) do if child.Name==name then return child end end
end
function methods:WaitForChild(name)
    local child=assert(self:FindFirstChild(name),name) return child
end
function methods:Destroy()
    self.Destroying:Fire()
    for _,child in ipairs(self:GetChildren()) do child:Destroy() end
    self.Parent=nil
end
function methods:CaptureFocus() self.Focused:Fire() end
local player=Instance.new("Player") player.Name="test-player" player.UserId=1
local playerGui=Instance.new("PlayerGui") playerGui.Parent=player
local input={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal(),GetFocusedTextBox=function() return nil end}
local services={Players={LocalPlayer=player},UserInputService=input,CoreGui=Instance.new("CoreGui")}
local jsonValues={}
services.HttpService={
    JSONEncode=function(_,value) table.insert(jsonValues,value) return tostring(#jsonValues) end,
    JSONDecode=function(_,text) return assert(jsonValues[tonumber(text)],"Invalid JSON token") end,
}
local game={GetService=function(_,name) return services[name] end}
local task={spawn=function(fn,...) return fn(...) end,defer=function(fn,...) return fn(...) end,delay=function(_,fn,...) return fn(...) end}
local function warn(message) print(message) end
local _G={}
