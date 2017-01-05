--require('mobdebug').start()

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

local hiding = SetupMod("the-hiding-of-isaac", 1)

local rng = RNG()
local roomsClearedHidden = 0

local CurrentRoom = {
  myRoomIndex = 0,
  myRoomInitialEnemyCount = 0,
  myClosestEnemyDistance = 9000.0,
  myHasIsaacBeenSeen = false
}

function CurrentRoom:Reset()
  CurrentRoom.myClosestEnemyDistance = 9000.0
  CurrentRoom.myHasIsaacBeenSeen = false
end

function CurrentRoom:IsNewRoom(aLevel)
  local oldRoomIndex = CurrentRoom.myRoomIndex
  CurrentRoom.myRoomIndex = aLevel:GetCurrentRoomIndex()
  
  return oldRoomIndex ~= CurrentRoom.myRoomIndex
end

local CurrentFloor = {
  myStageIndex = LevelStage.STAGE_NULL
}

function CurrentFloor:Reset()
  CurrentRoom.myStageIndex = LevelStage.STAGE_NULL
end

function CurrentFloor:IsNewFloor(aLevel)
  local oldStageIndex = CurrentRoom.myStageIndex
  CurrentRoom.myStageIndex = aLevel:GetAbsoluteStage()
  
  return oldStageIndex ~= CurrentRoom.myStageIndex
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

function MorphEnemiesToChampions()
  local	entities = Isaac.GetRoomEntities()
  
  for i = 1, #entities do
    if entities[i]:IsActiveEnemy() then
      entities[i]:MakeChampion(1)
    end
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
  local room = game:GetRoom()
  
  roomsClearedHidden = 0
  
  player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE, 0, false)
  player:AddCollectible(CollectibleType.COLLECTIBLE_CEREMONIAL_ROBES, 0, false)
  player:AddMaxHearts(-7, true)
  player:AddBlackHearts(-4)
  player:RemoveBlackHeart(2)
  
  CurrentFloor:Reset()
  CurrentRoom:Reset()
  CurrentRoom.myRoomInitialEnemyCount = room:GetAliveEnemiesCount()
end

function hiding:Text()
  local roomsClearedHiddenText = "Stealth: " .. tostring(roomsClearedHidden)
  local seenText = "Hidden: " .. tostring(not CurrentRoom.myHasIsaacBeenSeen)
  --local closestEnemy = "Distance: " .. tostring(math.floor(CurrentRoom.myClosestEnemyDistance))
  
  Isaac.RenderText(seenText, 10.0, 100.0, 1.0, 1.0, 1.0, 1.0)
  --Isaac.RenderText(closestEnemy, 10.0, 112.0, 1.0, 1.0, 1.0, 1.0)
  Isaac.RenderText(roomsClearedHiddenText, 10.0, 112.0, 1.0, 1.0, 1.0, 1.0)
end

function hiding:TakeDamage(aEntity)
  
end

function hiding:PostUpdate()

end

function hiding:PostPerfectUpdate(aConstPlayer)
  
  local player = Isaac.GetPlayer(0)
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()
  
  if CurrentFloor:IsNewFloor(level) then
    level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
  end
  
  if CurrentRoom:IsNewRoom(level) then
    CurrentRoom:Reset()
    CurrentRoom.myRoomInitialEnemyCount = room:GetAliveEnemiesCount()
    
    level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
    OpenNormalDoors(room)
  end
  
  if not CurrentRoom.myHasIsaacBeenSeen and CurrentRoom.myRoomInitialEnemyCount ~= 0 and room:GetAliveEnemiesCount() == 0 then
    roomsClearedHidden = roomsClearedHidden + 1
    CurrentRoom.myRoomInitialEnemyCount = 0
  end
  
  if not DoExpensiveAction(player) then
    return
  end
  
  local	entities = Isaac.GetRoomEntities()
  local oldHasIsaacBeenSeen = CurrentRoom.myHasIsaacBeenSeen
    
  for i = 1, #entities do

    if entities[i]:IsActiveEnemy() then

      local distance = DistanceFromPlayer(player, entities[i])
      
      if distance < CurrentRoom.myClosestEnemyDistance then
        CurrentRoom.myClosestEnemyDistance = distance
      end
      
      if CurrentRoom.myClosestEnemyDistance < 110 then
        CurrentRoom.myHasIsaacBeenSeen = true
      end

      if not CurrentRoom.myHasIsaacBeenSeen and not entities[i]:IsBoss() then
        entities[i]:AddEntityFlags(EntityFlag.FLAG_CONFUSION)
        entities[i]:AddEntityFlags(EntityFlag.FLAG_SLOW)
      else
        entities[i]:ClearEntityFlags(EntityFlag.FLAG_CONFUSION)
        entities[i]:ClearEntityFlags(EntityFlag.FLAG_SLOW)
      end
      
    end
  end
  
  if oldHasIsaacBeenSeen ~= CurrentRoom.myHasIsaacBeenSeen then
    CloseNormalDoors(room)
  end
  
end

function hiding:NpcUpdate(aNpc)
  local game = Game()
  local room = game:GetRoom()
  
  aNpc:MakeChampion(rng:Next())
  
  if aNpc:IsBoss() then
    CloseNormalDoors(room)
  end
end

function hiding:PostRender()
end

hiding:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, hiding.PlayerInit)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.Text)
hiding:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, hiding.TakeDamage)
hiding:AddCallback(ModCallbacks.MC_POST_UPDATE, hiding.PostUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, hiding.PostPerfectUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.PostRender)
hiding:AddCallback(ModCallbacks.MC_NPC_UPDATE, hiding.NpcUpdate)
