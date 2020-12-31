unit TestLibFdkAac;
{

  Delphi DUnit-Testfall
  ----------------------
  Diese Unit enthält ein Skeleton einer Testfallklasse, das vom Experten für Testfälle erzeugt wurde.
  Ändern Sie den erzeugten Code so, dass er die Methoden korrekt einrichtet und aus der 
  getesteten Unit aufruft.

}

interface

uses
  System.SysUtils, TestFramework, LibFdkAac;

type
  TestTTestClass = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAacDecGetLibInfo;
    procedure TestAacEncGetLibInfo;

    procedure TestAacDecoder;
    procedure TestAacEncoder;
  end;

implementation

procedure TestTTestClass.SetUp;
begin
  // do nothing here so far
end;

procedure TestTTestClass.TearDown;
begin
  // do nothing here so far
end;

procedure TestTTestClass.TestAacEncGetLibInfo;
var
  ModuleId: TFdkModuleID;
  ModuleCount: Integer;
  EncLibInfos: array[TFdkModuleID] of TLibInfo;
begin
  AacEncGetLibInfo(EncLibInfos[fmNone]);

  ModuleCount := 0;
  for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
    if EncLibInfos[ModuleId].title <> nil then
      Inc(ModuleCount);
end;


procedure TestTTestClass.TestAacDecGetLibInfo;
var
  ModuleId: TFdkModuleID;
  ModuleCount: Integer;
  DecLibInfos: array[TFdkModuleID] of TLibInfo;
begin
  AacDecGetLibInfo(DecLibInfos[fmNone]);

  ModuleCount := 0;
  for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
    if DecLibInfos[ModuleId].title <> nil then
      Inc(ModuleCount);
end;

procedure TestTTestClass.TestAacEncoder;
var
  Encoder: PAacEncoderInstance;
  EncoderInfo: AACENC_InfoStruct;
  BufferInput: PByteArray;
  BufferOutput: PByteArray;
  BufferDescInput: AACENC_BufDesc;
  BufferDescOutput: AACENC_BufDesc;
const
  Channels = 2;
begin
    if AacEncOpen(Encoder, 0, Channels) = aeOK then
    begin
      Assert(AacEncSetParam(Encoder, AACENC_AOT, Integer(AOT_AAC_LC)) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_SAMPLERATE, 44100) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_CHANNELMODE, Cardinal(MODE_2)) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_CHANNELORDER, 1) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_BITRATEMODE, 0) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_BITRATE, 64000) = aeOK);
      Assert(AacEncSetParam(Encoder, AACENC_TRANSMUX, 0) = aeOK);
      Assert(aacEncEncode(Encoder, nil, nil, nil, nil) = aeOK);
      Assert(aacEncInfo(Encoder, EncoderInfo) = aeOK);

      GetMem(BufferInput, 2 * Channels * EncoderInfo.frameLength);
      GetMem(BufferOutput, 2 * Channels * EncoderInfo.frameLength);

      // check parameters
      Assert(AacEncGetParam(Encoder, AACENC_SAMPLERATE) = 44100);

      // AacEncClose(Encoder);
    end;
end;

procedure TestTTestClass.TestAacDecoder;
var
  Decoder: PAacDecoderInstance;
begin
  Decoder := AacDecOpen(ttMp1Layer3, 1);
  AacDecClose(Decoder);
end;

initialization
  // Alle Testfälle beim Testprogramm registrieren
  RegisterTest(TestTTestClass.Suite);
end.

