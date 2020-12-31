program FdkAacGetLibInfo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  LibFdkAac in '../../Source/LibFdkAac.pas',
  System.SysUtils;

var
  EncLibInfos: array[TFdkModuleID] of TLibInfo;
  DecLibInfos: array[TFdkModuleID] of TLibInfo;
  ModuleId: TFdkModuleID;

begin
  try
    AacEncGetLibInfo(EncLibInfos[fmNone]);
    for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
      if EncLibInfos[ModuleId].title <> nil then
        Writeln('Encoder Title: ' + string(EncLibInfos[ModuleId].title) +
          ' (build ' + string(EncLibInfos[ModuleId].build_date) +
          ', ' + string(EncLibInfos[ModuleId].build_time) + ')');

    // get info about aac decoder
    AacDecGetLibInfo(DecLibInfos[fmNone]);
    for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
      if DecLibInfos[ModuleId].title <> nil then
        Writeln('Decoder Title: ' + string(DecLibInfos[ModuleId].title) +
          ' (build ' + string(DecLibInfos[ModuleId].build_date) +
          ', ' + string(DecLibInfos[ModuleId].build_time) + ')');

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
