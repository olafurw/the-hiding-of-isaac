--StartDebug()

local hiding = RegisterMod("the-hiding-of-isaac", 1)
local headInABag = Isaac.GetItemIdByName("Head in a bag")

knifeDamageReduction = 0.25

Character = {
  myStealthDamageBonus = 0.0
}

function Character:Reset()
  Character.myStealthDamageBonus = 0.0
end

-- Current Room
CurrentRoom = {
  myRoomIndex = 0,
  myRoomInitialEnemyCount = 0,
  myClosestEnemyDistance = 9000.0,
  myHasIsaacBeenSeen = false,
  myIsBossRoom = false,
  myIsHeadInABagActive = false
}

function CurrentRoom:Reset()
  CurrentRoom.myClosestEnemyDistance = 9000.0
  CurrentRoom.myHasIsaacBeenSeen = false
  CurrentRoom.myIsBossRoom = false
  CurrentRoom.myIsHeadInABagActive = false
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

function IsBossInRoom(aRoom)
  local	entities = Isaac.GetRoomEntities()
    
  for i = 1, #entities do

    if entities[i]:IsActiveEnemy() and entities[i]:IsBoss() then
      return true
    end
  end
  
  return false
end

function DistanceFromPlayer(aPlayer, aEntity)
  return aPlayer.Position:Distance(aEntity.Position)
end

function GetCostumeItem(aCollectibleType)
  local player = Isaac.GetPlayer(0)
  
  player:GetEffects():AddCollectibleEffect(aCollectibleType, true)
  local effect = player:GetEffects():GetCollectibleEffect(aCollectibleType)
  
  if effect ~= nil then
    return effect.Item
  end
  
  return nil
end

local robesCostume = nil
local sackCostume = nil
local transendCostume = nil

local hasSpawnedBag = false

function hiding:PlayerInit(aConstPlayer)
  local game = Game()
  local level = game:GetLevel()
  local player = Isaac.GetPlayer(0)
  local room = game:GetRoom()
  
  Character:Reset()
  
  roomsClearedHidden = 0
  hasSpawnedBag = false
  
  player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
  player:AddCollectible(headInABag, 1, false)
  player:AddMaxHearts(-7, true)
  player:AddBlackHearts(2)
  
  Character:Reset()
  CurrentFloor:Reset()
  CurrentRoom:Reset()
  CurrentRoom.myRoomInitialEnemyCount = room:GetAliveEnemiesCount()

  robesCostume = GetCostumeItem(CollectibleType.COLLECTIBLE_CEREMONIAL_ROBES)
  sackCostume = GetCostumeItem(CollectibleType.COLLECTIBLE_SACK_HEAD)
  transendCostume = GetCostumeItem(CollectibleType.COLLECTIBLE_TRANSCENDENCE)

end

function hiding:Text()
  local roomsClearedHiddenText = "Stealth: " .. tostring(roomsClearedHidden)
  
  Isaac.RenderText(roomsClearedHiddenText, 5.0, 215.0, 1.0, 1.0, 1.0, 1.0)
end

function hiding:TakeDamage(aEntity)
  
end

function hiding:PostUpdate()
  
end

function hiding:PostPEffectUpdate(aConstPlayer)
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
    
    if IsBossInRoom(room) then
      CurrentRoom.myIsBossRoom = true
    end
    
  end
  
  if not hasSpawnedBag then
    hasSpawnedBag = true
    local pos = Isaac.GetFreeNearPosition(player.Position, 80)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, headInABag, pos, Vector(0, 0), player)
    
    local pos2 = Isaac.GetFreeNearPosition(player.Position, 80)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_MOMS_KNIFE, pos2, Vector(0, 0), player)
  end
  
  if not CurrentRoom.myHasIsaacBeenSeen and CurrentRoom.myRoomInitialEnemyCount ~= 0 and room:GetAliveEnemiesCount() == 0 then
    roomsClearedHidden = roomsClearedHidden + 1
    CurrentRoom.myRoomInitialEnemyCount = 0
    
    Character.myStealthDamageBonus = Character.myStealthDamageBonus + 0.05
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    player:EvaluateItems()
  end
    
  if not DoExpensiveAction(player) then
    return
  end
  
  local oldHasIsaacBeenSeen = CurrentRoom.myHasIsaacBeenSeen
  
  local	entities = Isaac.GetRoomEntities()
  
  local isBossInRoom = false
    
  for i = 1, #entities do

    if entities[i]:IsActiveEnemy() then
      
      if entities[i]:IsBoss() then
        isBossInRoom = true
      end

      local distance = DistanceFromPlayer(player, entities[i])
      
      if distance < CurrentRoom.myClosestEnemyDistance then
        CurrentRoom.myClosestEnemyDistance = distance
      end
      
      if not CurrentRoom.myIsHeadInABagActive and CurrentRoom.myClosestEnemyDistance < 110 then
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

function hiding:NpcUpdate(aNpc)
  local game = Game()
  local room = game:GetRoom()
  local level = game:GetLevel()

  if aNpc:IsBoss() then
    CloseNormalDoors(room)
    level:RemoveCurse(LevelCurse.CURSE_OF_DARKNESS)
  end
end

function hiding:PostRender()
  local player = Isaac.GetPlayer(0)
  
  if robesCostume ~= nil and not CurrentRoom.myIsBossRoom and not CurrentRoom.myHasIsaacBeenSeen and not CurrentRoom.myIsHeadInABagActive then
    player:RemoveCostume(robesCostume)
    player:AddCostume(robesCostume, false)
  end
  
  if transendCostume ~= nil and sackCostume ~= nil and robesCostume ~= nil and (CurrentRoom.myHasIsaacBeenSeen or CurrentRoom.myIsBossRoom) then
    player:RemoveCostume(robesCostume)
    player:RemoveCostume(transendCostume)
    player:RemoveCostume(sackCostume)
  end
  
  if transendCostume ~= nil and sackCostume ~= nil and not CurrentRoom.myIsHeadInABagActive then 
    player:RemoveCostume(transendCostume)
    player:RemoveCostume(sackCostume)
  end
end

function hiding:EvaluateCache(aEntityPlayer, aCacheFlag)
  if aCacheFlag == CacheFlag.CACHE_DAMAGE and aEntityPlayer:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
    aEntityPlayer.Damage = aEntityPlayer.Damage * knifeDamageReduction
  end
  
  if aCacheFlag == CacheFlag.CACHE_DAMAGE then
    aEntityPlayer.Damage = aEntityPlayer.Damage + Character.myStealthDamageBonus
  end
end

function hiding:UseHeadInABag(aFoo, aBar)
  if robesCostume ~= nil and transendCostume ~= nil and sackCostume ~= nil then
    local game = Game()
    local room = game:GetRoom()
    local level = game:GetLevel()    
    local player = Isaac.GetPlayer(0)
    
    player:RemoveCostume(robesCostume)
    player:AddCostume(transendCostume, false)
    player:AddCostume(sackCostume, false)
    
    CurrentRoom.myIsHeadInABagActive = true
    CurrentRoom.myHasIsaacBeenSeen = false
    level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
    OpenNormalDoors(room)
  end
end

hiding:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, hiding.PlayerInit)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.Text)
hiding:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, hiding.TakeDamage)
hiding:AddCallback(ModCallbacks.MC_POST_UPDATE, hiding.PostUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, hiding.PostPEffectUpdate)
hiding:AddCallback(ModCallbacks.MC_POST_RENDER, hiding.PostRender)
hiding:AddCallback(ModCallbacks.MC_NPC_UPDATE, hiding.NpcUpdate)
hiding:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, hiding.EvaluateCache)
hiding:AddCallback(ModCallbacks.MC_USE_ITEM, hiding.UseHeadInABag, headInABag);
