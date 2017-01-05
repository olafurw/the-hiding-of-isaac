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