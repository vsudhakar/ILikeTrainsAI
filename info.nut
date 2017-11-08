class TrainLikerAI extends AIInfo {
  function GetAuthor()        { return "Visrut Sudhakar"; }
  function GetName()          { return "TrainLikerAI"; }
  function GetDescription()   { return "Just an AI that wants to build trains, okay?"}
  function GetVersion()       { return 1; }
  function GetDate()          { return "2017-10-27"; }
  function CreateInstance()   { return "TrainLikerAI"; }
  function GetShortName()     { return "TLAI"; }
  function GetAPIVersion()    { return "1.0"; }
}

RegisterAI(TrainLikerAI());
