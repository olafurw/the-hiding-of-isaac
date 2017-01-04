require('mobdebug').start()

local hiding = RegisterMod("Hiding", 1)

debugText = 0.0

roomIndex = 0
hasIsaacBeenSeen = false

function IsNewRoom(aLevel)
  local oldRoomIndex = roomIndex
  roomIndex = aLevel:GetCurrentRoomIndex()
  
  return oldRoomIndex ~= roomIndex
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

function hiding:PlayerInit(aConstPlayer)
  local player = Isaac.GetPlayer(0)
end

function hiding:Text()
	--Isaac.RenderText(tostring(debugText), 100.0, 100.0, 1.0, 1.0, 1.0, 1.0)
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
  
  local enemies = {}
  
  if IsNewRoom(level) then
    hasIsaacBeenSeen = false
    OpenNormalDoors(room)
    
    local	entities = Isaac.GetRoomEntities()
    
    for i = 1, #entities do
      
      if entities[i]:IsActiveEnemy() then
        entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
      end
      
    end
  end
  
  if not DoExpensiveAction(player) then
    return
  end
  
  local closestDistance = nil
  local	entities = Isaac.GetRoomEntities()
  
  for i = 1, #entities do
    
    if entities[i]:IsActiveEnemy() then
      entities[i]:AddEntityFlags(EntityFlag.FLAG_FREEZE)
      
      local distance = DistanceFromPlayer(player, entities[i])
      
      if closestDistance == nil or closestDistance > distance then
        closestDistance = distance
      end
      
    end
    
    --if entities[i]:HiddenIsFrozen and not entities[i]:HasFullHealth() then
    --  entities[i]:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
    --  CloseNormalDoors(room)
    --end
    
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
