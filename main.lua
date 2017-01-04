require('mobdebug').start()

function SetupMod(modname, apiversion)
  local mod = {
    Name = modname,
    AddCallback = function(self, callbackId, fn, entityId)
      if entityId == nil then entityId = -1; end
      
      Isaac.AddCallback(self, callbackId, fn, entityId)
    end,
    SaveData = function(self, data)
      Isaac.SaveModData(self, data)
    end,
    LoadData = function(self)
      return Isaac.LoadModData(self)
    end,
    HasData = function(self)
      return Isaac.HasModData(self)
    end,
    RemoveData = function(self)
      Isaac.RemoveModData(self)
    end
  }
  Isaac.RegisterMod(mod, modname, apiversion)
  return mod
end

local hiding = SetupMod("Hiding", 1)

local CurrentRoom = {
  myRoomIndex = 0,
  myClosestEnemyDistance = 0.0,
  myHasIsaacBeenSeen = false
}

function CurrentRoom:Reset()
  myClosestEnemyDistance = 0.0
  myHasIsaacBeenSeen = false
end

function CurrentRoom:IsNewRoom(aLevel)
  local oldRoomIndex = myRoomIndex
  myRoomIndex = aLevel:GetCurrentRoomIndex()
  
  return oldRoomIndex ~= myRoomIndex
end

function DoExpensiveAction(aPlayer)
  return aPlayer.FrameCount % 10 == 0
end

function OpenNormalDoor(aDoor)
  if aDoor ~= nil and aDoor:IsRoomType(RoomType.ROOM_DEFAULT) and not aDoor:IsOpen() then
    aDoor:Open()
  end
end

function CloseNormalDoor(aDoor)
  if aDoor ~= nil and aDoor:IsRoomType(RoomType.ROOM_DEFAULT) and aDoor:IsOpen() then
    aDoor:Close(false)
  end
end

function OpenNormalDoors(aRoom)
  for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
    OpenNormalDoor(aRoom:GetDoor(i))
  end
end

function CloseNormalDoors(aRoom)
  for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
    CloseNormalDoor(aRoom:GetDoor(i))
  end
end

function DistanceFromPlayer(aPlayer, aEntity)
  return aPlayer.Position:Distance(aEntity.Position)
end

function FreezeAllEnemies()
  local	entities = Isaac.GetRoomEntities()
    
  for i = 1, #entities do
    
    if entities[i]:IsActiveEnemy() then
      entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
    end
    
  end
end

function hiding:PlayerInit(aConstPlayer)
  local game = Game()
  local level = game:GetLevel()
  local player = Isaac.GetPlayer(0)
end

function hiding:Text()
  local seenText = "Seen: " .. tostring(CurrentRoom.myHasIsaacBeenSeen)
  local closestEnemy = "Distance: " .. tostring(math.floor(CurrentRoom.myClosestEnemyDistance))
  
	Isaac.RenderText(seenText, 10.0, 100.0, 1.0, 1.0, 1.0, 1.0)
  Isaac.RenderText(closestEnemy, 10.0, 112.0, 1.0, 1.0, 1.0, 1.0)
end

function hiding:TakeDamage()
end

function hiding:PostUpdate()

end

function hiding:PostPerfectUpdate(aConstPlayer)
  
  local player = Isaac.GetPlayer(0)
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()
  
  if CurrentRoom:IsNewRoom(level) then
    CurrentRoom:Reset()
    OpenNormalDoors(room)
  end
  
  level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
  
  if not DoExpensiveAction(player) then
    return
  end
  
  local closestDistance = nil
  local	entities = Isaac.GetRoomEntities()
  
  for i = 1, #entities do
    
    local distance = DistanceFromPlayer(player, entities[i])
    
    if entities[i]:IsActiveEnemy() then
      if closestDistance == nil or closestDistance > distance then
        closestDistance = distance
      end
      
      CurrentRoom.myClosestEnemyDistance = closestDistance
    end
    
    if not CurrentRoom.myHasIsaacBeenSeen and entities[i]:IsActiveEnemy() then
      entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
    end
    
    if not CurrentRoom.myHasIsaacBeenSeen and closestDistance ~= nil and closestDistance < 80 then
      hasIsaacBeenSeen = true
      CloseNormalDoors(room)
    end
    
    if CurrentRoom.myHasIsaacBeenSeen and distance < 80 then
      entities[i]:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
    end
    
  end
  
end

function hiding:PostRender()
end

hiding:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, hiding.PlayerInit)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.Text)
hiding:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, hiding.TakeDamage, EntityType.ENTITY_PLAYER)
hiding:AddCallback(ModCallbacks.MC_POST_UPDATE, hiding.PostUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, hiding.PostPerfectUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.PostRender)
