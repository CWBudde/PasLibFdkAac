program CommandLineEncoder;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  LibFdkAac in '..\..\Source\LibFdkAac.pas',
  UnitFdkAac in '..\..\Source\UnitFdkAac.pas',
  UnitWaveFile in '..\..\Source\UnitWaveFile.pas';

procedure PrintUsage;
begin
  WriteLn('Usage ' + ParamStr(0) + ' input.wav [output.m4a]');
end;

procedure EncodeWav(InputFile: TAudioFileContainerWAV; OutputStream: TStream);
var
  Encoder: TFdkAacEncoder;
  EncoderInfo: TAacEncInfoStruct;

	InputBufferSize: Integer;
	InputBuffer: PSmallInt;
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
  SamplePos: Integer;
  ReadBytes: Integer;
begin
  Encoder := TFdkAacEncoder.Create(0, InputFile.ChannelCount);
  Encoder.AudioObjectType := aotAacLC;
  Encoder.Samplerate := 44100;
  Encoder.ChannelMode := TChannelMode(InputFile.ChannelCount);
  Encoder.ChannelOrder := 1;
  Encoder.Bitrate := 0;
  Encoder.Bitrate := 64000;
  Encoder.Transmux := ttMp4Adts;

  // initialize encoder
  Encoder.Initiazlize;
  EncoderInfo := Encoder.Info;

  // clear Input and Output Arguments
  FillChar(InputArgs, SizeOf(InputArgs), 0);
  FillChar(OutputArgs, SizeOf(OutputArgs), 0);

  // calculate input buffer size and input buffer
  InputBufferSize := EncoderInfo.frameLength * InputFile.ChannelCount * SizeOf(SmallInt);
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
      InputSize := InputFile.ChannelCount * EncoderInfo.frameLength;

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

      InputFile.ReadAudioData(PByte(InputBuffer), 0, 0);

      SamplePos := 0;
      while True do
      begin
        // read buffer
        ReadBytes := InputFile.ReadAudioData(PByte(InputBuffer), InputSize);
        if InputSize <> ReadBytes then
          InputSize := ReadBytes;

        if ReadBytes <= 0 then
          InputArgs.numInSamples := -1
        else
        begin
          InputArgs.numInSamples := ReadBytes div 2;
          // append_encoder_input(convert_buf, in_args.numInSamples);
        end;

        ErrorCodeEnc := Encoder.Encode(@InputBufferDesc, @OutputBufferDesc, @InputArgs, @OutputArgs);
        if ErrorCodeEnc <> aeOK then
        begin
          if (ErrorCodeEnc = aeEncodeEof) then
            break;

          raise Exception.Create('Encoding failed');
        end;
        if OutputArgs.numOutBytes = 0 then
          continue;

        OutputStream.Write(OutputBuffer^, OutputArgs.numOutBytes);
      end;

      // flush file
      InputArgs.numInSamples := -1;
      ErrorCodeEnc := Encoder.Encode(@InputBufferDesc, @OutputBufferDesc,
        @InputArgs, @OutputArgs);
      Assert(ErrorCodeEnc in [aeEncodeEof, aeOK]);

      OutputStream.Write(OutputBuffer^, OutputArgs.numOutBytes);

      Encoder.Destroy;
    finally
      FreeMem(OutputBuffer);
    end;
  finally
    FreeMem(InputBuffer);
  end;
end;

procedure EncodeFile(InputFile, OutputFile: TFileName);
var
  WavFile: TAudioFileContainerWAV;
  InputStream: TMemoryStream;
  OutputStream: TMemoryStream;
begin
  if not FileExists(InputFile) then
  begin
    WriteLn('File ' + InputFile + ' does not seem to exist');
    WriteLn('');
    PrintUsage;
    Exit;
  end;

  if not TAudioFileContainerWAV.CanLoad(InputFile) then
  begin
    WriteLn('File ' + InputFile + ' does not seem to be a valid WAV file');
    WriteLn('');
    PrintUsage;
    Exit;
  end;

  InputStream := TMemoryStream.Create;
  try
    InputStream.LoadFromFile(InputFile);
    try
      WavFile := TAudioFileContainerWAV.Create(InputStream);

      OutputStream := TMemoryStream.Create;
      try
        EncodeWav(WavFile, OutputStream);
        OutputStream.SaveToFile(OutputFile);
      finally
        OutputStream.Free;
      end;
    finally
      WavFile.Free;
    end;
  finally
    InputStream.Free;
  end;
end;

begin
  try
    case ParamCount of
      1:
        EncodeFile(ParamStr(1), ParamStr(1) + '.m4a');
      2:
        EncodeFile(ParamStr(1), ParamStr(2));
      else
        begin
          PrintUsage;
          exit;
        end;
    end

    { TODO -oUser -cConsole Main : Code hier einfügen }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
