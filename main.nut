/*
** Connect cities by train depots
*/

import("pathfinder.rail", "RailPathFinder", 1);

class TrainLikerAI extends AIController
{

  function Start();
}

function TrainLikerAI::SplitIndex(index)
{
  local townA = index % 10000;
  local townB = ceil(index / 10000);

  return [townA.tointeger(), townB.tointeger()];
}

function TrainLikerAI::TownCrossScore(townA, townB)
{
  /*
  ** Calculate a cross score between
  ** 2 towns for development
  */

  local totalPop  = AITown.GetPopulation(townA);
  local mhDist    = AITown.GetDistanceManhattanToTile(townA, AITown.GetLocation(townB));

  //SQRT model
  //local score = sqrt(totalPop*mhDist);

  //Linear model
  local score = totalPop * (mhDist*-0.5)+10;

  return score.tointeger();
}

function TrainLikerAI::FindBuildableStationTile(focusTown) {
  local buildableTile;

  local townLoc = AITown.GetLocation(focusTown);
  local tileX   = AIMap.GetTileX(townLoc);
  local tileY   = AIMap.GetTileY(townLoc);

  buildableTile = AIMap.GetTileIndex(tileX, tileY);

  while(AITile.IsBuildable(buildableTile) == false || AITown.IsWithinTownInfluence(focusTown, buildableTile)) {
    tileX += 1;
    buildableTile = AIMap.GetTileIndex(tileX, tileY);
  }

  return buildableTile;
}

function TrainLikerAI::Start()
{
  AICompany.SetName("We Love Trains Inc.");

  AILog.Info("TrainLikerAI likes trains and excited about this game");

  local types = AIRailTypeList();
  AIRail.SetCurrentRailType(types.Begin());

  local allTowns = AITownList();
  local townRanking = AIList();

  AILog.Info(allTowns.Count() + " towns on the list.");
  AILog.Info(AITown.GetTownCount() + " towns on the map");

  local i;
  local j;

  for (i = 0; i < AITown.GetTownCount(); i++) {
    for (j = 0; j < i; j++) {
      AILog.Info("Scoring " + AITown.GetName(i) + " with " + AITown.GetName(j));
      local score = TownCrossScore(i, j);
      AILog.Info("Score: " + score);
      local townA;
      local townB;
      if (i < j) {
        townA = i;
        townB = j;
      } else {
        townA = j;
        townB = i;
      }
      local index = townA*10000+townB;
      // Magnify score to store as int
      local magScore = ceil(score*1000);
      townRanking.AddItem(index, magScore.tointeger());
    }
  }

  local topTownPair = SplitIndex(townRanking.Begin());

  AILog.Info("Highest scored cross town pair: " + AITown.GetName(topTownPair[0]) + " | " + AITown.GetName(topTownPair[1]));



  townRanking.Sort(AIList.SORT_BY_VALUE, false);

  local built_a = false;
  local built_b = false;

  while (true) {
    /*
    ** I Like Trains loop
    */
    AILog.Info("TLAI is trying its best at this game, but it hard :/");

    while (built_a == false && built_b == false) {

      local townA = topTownPair[0];
      local townB = topTownPair[1];

      // Build train stations in both towns
      local stationA  = FindBuildableStationTile(townA);
      local stationB  = FindBuildableStationTile(townB);

      AILog.Info(AIRail.IsRailTypeAvailable(AIRail.GetCurrentRailType()));

      AILog.Info("Found tile " + stationA + " for town " + AITown.GetName(townA) + " | " + AITile.IsBuildable(stationA));
      AILog.Info("Found tile " + stationB + " for town " + AITown.GetName(townB) + " | " + AITile.IsBuildable(stationB));

      // Pick an orientation
      local stationOrientation = AIRail.RAILTRACK_NE_SW;

      local buildMode = AIExecMode();


      built_a = AIRail.BuildRailStation(stationA, AIRail.RAILTRACK_NE_SW, 1, 1, AIStation.STATION_NEW);
      built_b = AIRail.BuildRailStation(stationB, AIRail.RAILTRACK_NE_SW, 1, 1, AIStation.STATION_NEW);

      AILog.Info("Station A status: " + built_a);
      AILog.Info("Station B status: " + built_b);

    }

    local builtTrack = false;
    local pathfinder = RailPathFinder();

    pathfinder.InitializePath([[stationA, stationA + AIMap.GetTileIndex(-1, 0)]], [[stationB + AIMap.GetTileIndex(-1, 0), stationB]]);

    local path = pathfinder.FindPath(-1);

    while (builtTrack == false) {
      local prev = null;
      local prevprev = null;
      while (path != null) {
        if (prevprev != null) {
          if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
            if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
              AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
            } else {
              local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
              bridge_list.Valuate(AIBridge.GetMaxSpeed);
              bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
              AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
            }
            prevprev = prev;
            prev = path.GetTile();
            path = path.GetParent();
          } else {
            AIRail.BuildRail(prevprev, prev, path.GetTile());
          }
        }
        if (path != null) {
          prevprev = prev;
          prev = path.GetTile();
          path = path.GetParent();
        }
      }
    }



    this.Sleep(50);
  }
}

function TrainLikerAI::Save() {
  // Do nothing for now
  local table = {count = 0};
  return table;
}
