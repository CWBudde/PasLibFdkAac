program FdkAacDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  LibFdkAac in '../Source/LibFdkAac.pas',
  System.SysUtils;

var
  EncLibInfos: array[TFdkModuleID] of TLibInfo;
  DecLibInfos: array[TFdkModuleID] of TLibInfo;
  ModuleId: TFdkModuleID;
  Encoder: PAacEncoderInstance;
  Decoder: PAacDecoderInstance;
  EncoderInfo: AACENC_InfoStruct;
  BufferInput: PByteArray;
  BufferOutput: PByteArray;
  BufferDescInput: AACENC_BufDesc;
  BufferDescOutput: AACENC_BufDesc;
  Value: Cardinal;

const
  Channels = 2;

begin
  try
    AacEncGetLibInfo(EncLibInfos[fmNone]);
    for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
      if EncLibInfos[ModuleId].title <> nil then
        Writeln('Encoder Title: ' + string(EncLibInfos[ModuleId].title) +
          ' (build ' + string(EncLibInfos[ModuleId].build_date) +
          ', ' + string(EncLibInfos[ModuleId].build_time) + ')');

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

    // get info about aac decoder
    AacDecGetLibInfo(DecLibInfos[fmNone]);
    for ModuleId := Low(TFdkModuleID) to High(TFdkModuleID) do
      if DecLibInfos[ModuleId].title <> nil then
        Writeln('Decoder Title: ' + string(DecLibInfos[ModuleId].title) +
          ' (build ' + string(DecLibInfos[ModuleId].build_date) +
          ', ' + string(DecLibInfos[ModuleId].build_time) + ')');

    Decoder := AacDecOpen(ttMp1Layer3, 1);
    AacDecClose(Decoder);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;

end.
