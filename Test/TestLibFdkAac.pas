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
  System.SysUtils, TestFramework, LibFdkAac, UnitWaveFileReader;

type
  TestTTestClass = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
    procedure TestAacEncodeDecodeFile(FileName: TFileName);
    procedure TestAacEncodeDecodeAudio(AudioFileWav: TAudioFileWAV;
      AudioObjectType: TAudioObjectType; IsAfterburner, IsEldSbr: Boolean;
      VariableBitRate: Integer; Bitrate: Integer; IsAdts: Boolean);
  published
    procedure TestAacDecGetLibInfo;
    procedure TestAacEncGetLibInfo;

    procedure TestAacDecoder;
    procedure TestAacEncoder;

    procedure TestAacEncodeDecode;
  end;

implementation

uses
  Classes;

{ TestTTestClass }

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

	InputBufferSize: Integer;
	InputBuffer: PSmallIntArray;
  OutputBufferSize: Integer;
  OutputBuffer: PByteArray;

  InputBufferDesc, OutputBufferDesc: TAacEncBufDesc;
  InputArgs: TAacEncInArgs;
  OutputArgs: TAacEncOutArgs;
  InputIdentifier: TAacEncBufferIdentifier;
  InputSize, InputElementSize: Integer;
  OutputIdentifier: TAacEncBufferIdentifier;
  OutputSize, OutputElementSize: Integer;
  ErrorCodeEnc: TAacEncoderError;
const
  CNumberOfChannels = 1;
begin
  CheckTrue(AacEncOpen(Encoder, 0, CNumberOfChannels) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepAudioObjectType, Integer(aotAacLC)) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepSamplerate, 44100) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepChannelMode, CNumberOfChannels) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepChannelOrder, CNumberOfChannels) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepBitratemode, 0) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepBitrate, 64000) = aeOK);
  CheckTrue(AacEncSetParam(Encoder, aepTransmux, 0) = aeOK);
  CheckTrue(aacEncEncode(Encoder, nil, nil, nil, nil) = aeOK);
  CheckTrue(aacEncInfo(Encoder, EncoderInfo) = aeOK);

  // check parameters
  CheckEquals(aacEncGetParam(Encoder, aepSamplerate), 44100);
  CheckEquals(aacEncGetParam(Encoder, aepChannelMode), CNumberOfChannels);
  CheckEquals(aacEncGetParam(Encoder, aepChannelOrder), CNumberOfChannels);
  CheckEquals(aacEncGetParam(Encoder, aepBitratemode), 0);
  CheckEquals(aacEncGetParam(Encoder, aepBitrate), 64000);
  CheckEquals(aacEncGetParam(Encoder, aepTransmux), 0);

  CheckTrue(aacEncInfo(Encoder, EncoderInfo) = aeOK, 'Unable to get encoder info');

  // clear Input and Output Arguments
  FillChar(InputArgs, SizeOf(InputArgs), 0);
  FillChar(OutputArgs, SizeOf(OutputArgs), 0);

  // initialize encoder
  CheckTrue(aacEncEncode(Encoder, nil, nil, nil, nil) = aeOK, 'Unable to initialize encoder');

  // calculate input buffer size and input buffer
  InputBufferSize := EncoderInfo.frameLength * CNumberOfChannels * SizeOf(SmallInt);
  InputBuffer := AllocMem(InputBufferSize);
  try
    // calculate output buffer size and output buffer
    OutputBufferSize := EncoderInfo.maxOutBufBytes;
    OutputBuffer := AllocMem(OutputBufferSize);

    try
      Assert(SizeOf(InputIdentifier) = 4);

      // setup input buffer description
      InputIdentifier := biInAudioData;
      InputElementSize := SizeOf(SmallInt);
      InputSize := EncoderInfo.frameLength * CNumberOfChannels * SizeOf(SmallInt);

      InputBufferDesc.numBufs := 1;
      InputBufferDesc.bufs := @InputBuffer;
      InputBufferDesc.bufferIdentifiers := @InputIdentifier;
      InputBufferDesc.bufSizes := @InputSize;
      InputBufferDesc.bufElSizes := @InputElementSize;

      // setup output buffer description
      OutputIdentifier := biOutBitstreamData;
      OutputElementSize := SizeOf(Byte);
      OutputSize := OutputBufferSize;

      OutputBufferDesc.numBufs := 1;
      OutputBufferDesc.bufs := @OutputBuffer;
      OutputBufferDesc.bufferIdentifiers := @OutputIdentifier;
      OutputBufferDesc.bufSizes := @OutputSize;
      OutputBufferDesc.bufElSizes := @OutputElementSize;

      // encode some silence
      InputArgs.numInSamples := InputSize;
      InputArgs.numAncBytes := 0;
      CheckTrue(aacEncEncode(encoder, @InputBufferDesc, @OutputBufferDesc,
        @InputArgs, @OutputArgs) = aeOK);

      // flush file
      InputArgs.numInSamples := -1;
      ErrorCodeEnc := aacEncEncode(encoder, @InputBufferDesc, @OutputBufferDesc,
        @InputArgs, @OutputArgs);
      CheckTrue(ErrorCodeEnc in [aeEncodeEof, aeOK]);

      AacEncClose(Encoder);
    finally
      FreeMem(OutputBuffer);
    end;
  finally
    FreeMem(InputBuffer);
  end;
end;

procedure TestTTestClass.TestAacDecoder;
var
  Decoder: PAacDecoderInstance;
  ErrorCodeDec: TAacDecoderError;
  FileStream: TFileStream;
  ReadBytes: Cardinal;
  ValidBytes: Cardinal;
  Buffer: PByteArray;
begin
  Decoder := AacDecOpen(ttMp4Raw, 1);
  CheckTrue(Decoder <> nil);

  ErrorCodeDec := AacDecSetParam(Decoder, dpConcealMethod, 1);
  CheckTrue(ErrorCodeDec = adOK);

  ErrorCodeDec := AacDecSetParam(Decoder, dpPcmLimiterEnable, 0);
  CheckTrue(ErrorCodeDec = adOK);

  ValidBytes := 0;

  if FileExists('..\Loop.m4a') then
  begin
    FileStream := TFileStream.Create('..\Loop.m4a', fmOpenRead);
    try
      ReadBytes := 8192;
      Buffer := AllocMem(ReadBytes);
      try
        repeat
          ReadBytes := FileStream.Read(Buffer^[0], ReadBytes);
          ErrorCodeDec := AacDecFill(Decoder, @Buffer^[0], ReadBytes, ValidBytes);
        until FileStream.Position = FileStream.Size;
      finally
        FreeMem(Buffer);
      end;
    finally
      FileStream.Free;
    end;
  end;

  AacDecClose(Decoder);
end;

function decode(decoder: PAacDecoderInstance; ptr: PByte; size: Integer;
  decoder_buffer: PByte; decoder_buffer_size: Integer; channels: Integer): Integer;
var
	err: TAacDecoderError;
//	info: CStreamInfo;
	valid: Cardinal;
  buffer_size: Cardinal;
begin
	repeat
		valid := size;
    buffer_size := size;
//		err := AacDecFill(Decoder, ptr, buffer_size, valid);
(*
		ptr += buffer_size - valid;
		size -= buffer_size - valid;
		if (err == AAC_DEC_NOT_ENOUGH_BITS)
			continue;
		if (err != AAC_DEC_OK)
			break;
		err = aacDecoder_DecodeFrame(decoder, (INT_PCM * ) decoder_buffer, decoder_buffer_size / sizeof(INT_PCM), 0);
		if (!ptr && err != AAC_DEC_OK)
			break;
		if (err == AAC_DEC_NOT_ENOUGH_BITS)
			continue;
		if (err != AAC_DEC_OK) {
			fprintf(stderr, "Decoding failed\n");
			Result := 1;
		}
		info = aacDecoder_GetStreamInfo(decoder);
		if (info->numChannels != channels) {
			fprintf(stderr, "Mismatched number of channels, input %d, output %d\n", channels, info->numChannels);
			return 1;
		}
		compare_decoder_output((int16_t* ) decoder_buffer, info->numChannels * info->frameSize);
*)
	until size = 0;
	Result := 0;
end;

procedure TestTTestClass.TestAacEncodeDecodeAudio(AudioFileWav: TAudioFileWav;
  AudioObjectType: TAudioObjectType; IsAfterburner, IsEldSbr: Boolean;
  VariableBitRate: Integer; Bitrate: Integer; IsAdts: Boolean);
var
  encoder_input_samples, encoder_input_size: Integer;
  encoder_input: PSmallInt;
  max_diff: Integer;
  diff_sum, diff_samples: UInt64;

  SamplePos: Cardinal;

	InputBufferSize: Integer;
	InputBuffer: PSmallIntArray;
  OutputBufferSize: Integer;
  OutputBuffer: PByteArray;

	Encoder: PAacEncoderInstance;
	ChannelMode: TChannelMode;
  EncoderInfo: TAacEncInfoStruct;

	Decoder: PAacDecoderInstance;
	DecoderBuffer: PByte;
  DecoderOutputSkip: Integer;

  InputBufferDesc, OutputBufferDesc: TAacEncBufDesc;
  InputArgs: TAacEncInArgs;
  OutputArgs: TAacEncOutArgs;
  InputIdentifier: TAacEncBufferIdentifier;
  InputSize, InputElementSize: Integer;
  OutputIdentifier: TAacEncBufferIdentifier;
  OutputSize, OutputElementSize: Integer;

  ReadBytes, i: Integer;
  ErrorCodeEnc: TAacEncoderError;
  ErrorCodeDec: TAacDecoderError;
const
	DecoderBufferSize = 2048 * 2 * 8;
begin
  DecoderBuffer := AllocMem(DecoderBufferSize);
  try
    encoder_input_samples := 0;
    max_diff := 0;
    diff_sum := 0;
    diff_samples := 0;

    case AudioFileWav.ChannelCount of
      1:
        ChannelMode := cm1;
      2:
        ChannelMode := cm2;
      3:
        ChannelMode := cm1_2;
      4:
        ChannelMode := cm1_2_1;
      5:
        ChannelMode := cm1_2_2;
      6:
        ChannelMode := cm1_2_2_1;
      else
        raise Exception.Create('Unsupported WAV channel count');
    end;

    ErrorCodeEnc := AacEncOpen(Encoder, 0, AudioFileWav.ChannelCount);
    CheckTrue(ErrorCodeEnc = aeOK, 'Unable to open encoder');

    // set audio object type
    ErrorCodeEnc := AacEncSetParam(Encoder, aepAudioObjectType, Integer(AudioObjectType));
    CheckTrue(ErrorCodeEnc = aeOK, 'Unable to set audio object type');

    // eventually set SBR Mode
    if (AudioObjectType = aotErrorResAacELD) and IsEldSbr then
      CheckTrue(AacEncSetParam(Encoder, aepSbrMode, 1) = aeOK, 'Unable to set SBR mode');

    // set samplerate
    CheckTrue(AacEncSetParam(Encoder, aepSamplerate, Round(AudioFileWav.SampleRate)) = aeOK, 'Unable to set samplerate');

    // set channel mode
    CheckTrue(AacEncSetParam(Encoder, aepChannelMode, Integer(ChannelMode)) = aeOK, 'Unable to set channel mode');

    // set channel order
    CheckTrue(AacEncSetParam(Encoder, aepChannelOrder, 1) = aeOK, 'Unable to set channel order');

    // eventually set bitrate (mode)
    if VariableBitRate > 0 then
      CheckTrue(AacEncSetParam(Encoder, aepBitrateMode, VariableBitRate) = aeOK, 'Unable to set bitrate mode')
    else
      CheckTrue(AacEncSetParam(Encoder, aepBitrate, Bitrate) = aeOK, 'Unable to set bitrate mode');

    // set transmux
    if IsAdts then
      CheckTrue(AacEncSetParam(Encoder, aepTransmux, 2) = aeOK, 'Unable to set transmux')
    else
      CheckTrue(AacEncSetParam(Encoder, aepTransmux, 0) = aeOK, 'Unable to set transmux');

    // set afterburner
    CheckTrue(AacEncSetParam(Encoder, aepAfterburner, Integer(IsAfterburner)) = aeOK, 'Unable to set afterburner');

    // initialize encoder
    CheckTrue(aacEncEncode(Encoder, nil, nil, nil, nil) = aeOK, 'Unable to initialize encoder');

    // get encoder info
    CheckTrue(aacEncInfo(Encoder, EncoderInfo) = aeOK, 'Unable to get encoder info');

    // clear Input and Output Arguments
    FillChar(InputArgs, SizeOf(InputArgs), 0);
    FillChar(OutputArgs, SizeOf(OutputArgs), 0);

    // calculate input buffer size and input buffer
    InputBufferSize := EncoderInfo.frameLength * AudioFileWav.ChannelCount * SizeOf(SmallInt);
    InputBuffer := AllocMem(InputBufferSize);
    try
      // calculate output buffer size and output buffer
      OutputBufferSize := EncoderInfo.maxOutBufBytes;
      OutputBuffer := AllocMem(OutputBufferSize);
      try
        DecoderOutputSkip := AudioFileWav.ChannelCount * EncoderInfo.nDelay;

        if IsAdts then
          Decoder := AacDecOpen(ttMp4Adts, 1)
        else
          Decoder := AacDecOpen(ttMp4Raw, 1);

        // set ASC
        if not IsAdts then
        begin
          ErrorCodeDec := AacDecConfigRaw(Decoder, @EncoderInfo.confBuf[0], EncoderInfo.confSize);
          CheckTrue(ErrorCodeDec = adOK, 'Unable to set ASC');
        end;

        aacDecSetParam(decoder, dpConcealMethod, 1);
        aacDecSetParam(decoder, dpPcmLimiterEnable, 0);

        try
          // setup input buffer description
          InputIdentifier := biInAudioData;
          InputElementSize := SizeOf(SmallInt);
          InputSize := AudioFileWav.ChannelCount * EncoderInfo.frameLength;

          InputBufferDesc.numBufs := 1;
          InputBufferDesc.bufs := @InputBuffer;
          InputBufferDesc.bufferIdentifiers := @InputIdentifier;
          InputBufferDesc.bufSizes := @InputSize;
          InputBufferDesc.bufElSizes := @InputElementSize;

          OutputIdentifier := biOutBitstreamData;
          OutputElementSize := SizeOf(Byte);
          OutputSize := OutputBufferSize;

          OutputBufferDesc.numBufs := 1;
          OutputBufferDesc.bufs := @OutputBuffer;
          OutputBufferDesc.bufferIdentifiers := @OutputIdentifier;
          OutputBufferDesc.bufSizes := @OutputSize;
          OutputBufferDesc.bufElSizes := @OutputElementSize;

          SamplePos := 0;
          while True do
          begin
            // read buffer
            ReadBytes := AudioFileWav.DecodeToBuffer(SamplePos, InputBuffer, InputSize);
            if InputSize <> ReadBytes then
              InputSize := ReadBytes;

            if ReadBytes <= 0 then
              InputArgs.numInSamples := -1
            else
            begin
              InputArgs.numInSamples := ReadBytes div 2;
              // append_encoder_input(convert_buf, in_args.numInSamples);
            end;

            ErrorCodeEnc := aacEncEncode(encoder, @InputBufferDesc, @OutputBufferDesc,
              @InputArgs, @OutputArgs);
            if ErrorCodeEnc <> aeOK then
            begin
              if (ErrorCodeEnc = aeEncodeEof) then
                break;

              raise Exception.Create('Encoding failed');
            end;
            if OutputArgs.numOutBytes = 0 then
              continue;

      (*
            if Decode(decoder, outbuf, out_args.numOutBytes, decoder_buffer, decoder_buffer_size, channels) then
            begin
              break;
            end;
      *)
          end;
        finally
          FreeMem(OutputBuffer);
        end;
      finally
        FreeMem(InputBuffer);
      end;
    finally
      AacEncClose(Encoder);
      AacDecClose(Decoder);
    end;
  finally
    FreeMem(DecoderBuffer);
  end;
end;

procedure TestTTestClass.TestAacEncodeDecodeFile(FileName: TFileName);
var
  AudioFileWav: TAudioFileWAV;
  BitrateMode: Integer;
begin
  AudioFileWav := TAudioFileWAV.Create(FileName);
  try
    // AAC-LC, without afterburner
    TestAacEncodeDecodeAudio(AudioFileWav, aotAacLC, False, False, 0, 64000, False);

    // AAC-LC
    TestAacEncodeDecodeAudio(AudioFileWav, aotAacLC, True, False, 0, 64000, False);
    TestAacEncodeDecodeAudio(AudioFileWav, aotAacLC, True, False, 0, 64000, True);

    // AAC-LC VBR
    for BitrateMode := 0 to 5 do
      TestAacEncodeDecodeAudio(AudioFileWav, aotAacLC, True, False, BitrateMode, 0, False);

    if (AudioFileWav.ChannelCount = 2) then
    begin
      // HE-AACv2 only works for stereo; HE-AACv1 gets upconverted to stereo (which we don't match properly)

      // HE-AAC
      TestAacEncodeDecodeAudio(AudioFileWav, aotSBR, True, False, 0, 64000, False);
      TestAacEncodeDecodeAudio(AudioFileWav, aotSBR, True, False, 0, 64000, True);

      // HE-AAC VBR
      for BitrateMode := 0 to 5 do
        TestAacEncodeDecodeAudio(AudioFileWav, aotSBR, True, False, BitrateMode, 0, False);

      // HE-AACv2
      TestAacEncodeDecodeAudio(AudioFileWav, aotPS, True, False, 0, 64000, False);
      TestAacEncodeDecodeAudio(AudioFileWav, aotPS, True, False, 0, 64000, True);

      // HE-AACv2 VBR
      for BitrateMode := 0 to 5 do
        TestAacEncodeDecodeAudio(AudioFileWav, aotPS, True, False, BitrateMode, 0, False);
    end;

    // AAC-LD
    if (AudioFileWav.ChannelCount = 1) then
      TestAacEncodeDecodeAudio(AudioFileWav, aotErrorResAacLD, True, False, 0, 64000, False);

    // AAC-ELD
    TestAacEncodeDecodeAudio(AudioFileWav, aotErrorResAacELD, True, False, 0, 64000, False);

    // AAC-ELD with SBR
    TestAacEncodeDecodeAudio(AudioFileWav, aotErrorResAacELD, True, True, 0, 64000, False);

  finally
    AudioFileWav.Free;
  end;
end;

procedure TestTTestClass.TestAacEncodeDecode;
begin
  TestAacEncodeDecodeFile('../Loop.wav');
end;

initialization
  // Alle Testfälle beim Testprogramm registrieren
  RegisterTest(TestTTestClass.Suite);
end.

