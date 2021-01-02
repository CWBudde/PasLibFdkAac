unit TestLibFdkAac;
{

  Delphi DUnit-Testfall
  ----------------------
  Diese Unit enth�lt ein Skeleton einer Testfallklasse, das vom Experten f�r Testf�lle erzeugt wurde.
  �ndern Sie den erzeugten Code so, dass er die Methoden korrekt einrichtet und aus der 
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
  EncoderInfo: TAacEncInfoStruct;
  BufferInput: PByteArray;
  BufferOutput: PByteArray;
  BufferDescInput: TAacEncBufDesc;
  BufferDescOutput: TAacEncBufDesc;
const
  Channels = 2;
begin
    if AacEncOpen(Encoder, 0, Channels) = aeOK then
    begin
      Assert(AacEncSetParam(Encoder, aepAOT, Integer(AOT_AAC_LC)) = aeOK);
      Assert(AacEncSetParam(Encoder, aepSamplerate, 44100) = aeOK);
      Assert(AacEncSetParam(Encoder, aepChannelMode, Cardinal(cm2)) = aeOK);
      Assert(AacEncSetParam(Encoder, aepChannelOrder, 1) = aeOK);
      Assert(AacEncSetParam(Encoder, aepBitratemode, 0) = aeOK);
      Assert(AacEncSetParam(Encoder, aepBitrate, 64000) = aeOK);
      Assert(AacEncSetParam(Encoder, aepTransmux, 0) = aeOK);
      Assert(aacEncEncode(Encoder, nil, nil, nil, nil) = aeOK);
      Assert(aacEncInfo(Encoder, EncoderInfo) = aeOK);

      GetMem(BufferInput, 2 * Channels * EncoderInfo.frameLength);
      GetMem(BufferOutput, 2 * Channels * EncoderInfo.frameLength);

      // check parameters
      Assert(AacEncGetParam(Encoder, aepSamplerate) = 44100);

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
  // Alle Testf�lle beim Testprogramm registrieren
  RegisterTest(TestTTestClass.Suite);
end.

