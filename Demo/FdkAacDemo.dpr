program FdkAacDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  LibFdkAac in '../Source/LibFdkAac.pas',
  System.SysUtils;

var
  EncLibInfo: TLibInfo;
  DecLibInfo: TLibInfo;

begin
  try
    // get info about aac encoder
    AacEncGetLibInfo(EncLibInfo);
    Writeln('Encoder Title: ' + string(EncLibInfo.title) +
      ' (build ' + string(EncLibInfo.build_date) +
      ', ' + string(EncLibInfo.build_time) + ')');

    // get info about aac decoder
    AacDecGetLibInfo(DecLibInfo);
    Writeln('Decoder Title: ' + string(DecLibInfo.title) +
      ' (build ' + string(DecLibInfo.build_date) +
      ', ' + string(DecLibInfo.build_time) + ')');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
