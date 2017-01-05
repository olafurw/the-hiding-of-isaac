--require('mobdebug').start()

--local debugFile = io.open("hiding-debug.txt", "w")

local hiding = RegisterMod("the-hiding-of-isaac", 1)

-- Current Room
CurrentRoom = {
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

-- Current Floor
CurrentFloor = {
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

local rng = RNG()
local roomsClearedHidden = 0

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
  
  Isaac.RenderText(roomsClearedHiddenText, 5.0, 225.0, 1.0, 1.0, 1.0, 1.0)
end

function hiding:TakeDamage(aEntity)
  
end

function hiding:PostUpdate()
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
        level:RemoveCurse(LevelCurse.CURSE_OF_DARKNESS)
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

function hiding:PostPEffectUpdate(aConstPlayer)
  
end

function hiding:NpcUpdate(aNpc)
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()
  
  if not aNpc:IsChampion() then
    aNpc:MakeChampion(rng:Next())
  end
  
  if aNpc:IsBoss() then
    CloseNormalDoors(room)
    level:RemoveCurse(LevelCurse.CURSE_OF_DARKNESS)
  end
end

function hiding:PostRender()
end

function hiding:EvaluateCache(aNumber)
end

hiding:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, hiding.PlayerInit)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.Text)
hiding:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, hiding.TakeDamage)
hiding:AddCallback(ModCallbacks.MC_POST_UPDATE, hiding.PostUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, hiding.PostPEffectUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.PostRender)
hiding:AddCallback(ModCallbacks.MC_NPC_UPDATE, hiding.NpcUpdate)
hiding:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, hiding.EvaluateCache)
