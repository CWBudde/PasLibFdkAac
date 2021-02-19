program CommandLineDecoder;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  LibFdkAac in '..\..\Source\LibFdkAac.pas',
  UnitFdkAac in '..\..\Source\UnitFdkAac.pas',
  UnitAacHeader in '..\..\Source\UnitAacHeader.pas',
  UnitWaveFileWriter in '..\..\Source\UnitWaveFileWriter.pas';

procedure PrintUsage;
begin
  WriteLn('Usage ' + ParamStr(0) + ' input.aac [output.wav]');
end;

function DecodeStream(InputStream: TStream; Output: TAudioFileContainerWAV;
  TransportType: TTransportType): Boolean;
var
  Decoder: TFdkAacDecoder;
  InputBuffer: PByte;
  InputBufferSize: Cardinal;
  OutputBuffer: PByteArray;
  OutputBufferSize: Cardinal;
  BufferSize: Cardinal;
  ValidBytes: Cardinal;
  StreamInfo: PStreamInfo;
  AdtsPacketReader: TAdtsPacketReader;
  Index: Integer;
begin
  Assert(Assigned(InputStream));
  StreamInfo := nil;

  Decoder := TFdkAacDecoder.Create(TransportType, 1);
  try
    if not Assigned(Decoder) then
    begin
      WriteLn('Input format not supported');
      Exit(False);
    end;

    // set error concealment to noise
    Decoder.SetParam(dpConcealMethod, 1);

    // disable limiter
    Decoder.SetParam(dpPcmLimiterEnable, 0);

    // specify WAV channel mapping
    Decoder.SetParam(dpPcmOutputChannelMapping, 1);

    // setup input buffer
    InputBufferSize := 8192;
    InputBuffer := AllocMem(InputBufferSize);
    try
      OutputBufferSize := 16384;
      OutputBuffer := AllocMem(OutputBufferSize);

      if TransportType = ttMp4Adts then
        AdtsPacketReader := TAdtsPacketReader.Create;

      try
        BufferSize := 1152;
        repeat
          // eventually read ADTS packet to adapt the buffer size
          if TransportType = ttMp4Adts then
          begin
            AdtsPacketReader.ReadFromStream(InputStream);
            BufferSize := AdtsPacketReader.FrameLength;
          end;

          InputStream.Read(InputBuffer^, BufferSize);

          // fill decoder
          ValidBytes := BufferSize;
          Decoder.Fill(InputBuffer, BufferSize, ValidBytes);
          // TODO: handle ValidBytes <> 0

          // eventually decode frame (skip if not enough bits are present)
          if not Decoder.DecodeFrame(@OutputBuffer^, OutputBufferSize, []) then
            continue;

          // get stream information
          if not Assigned(StreamInfo) then
          begin
            StreamInfo := Decoder.GetStreamInfo;
            Output.ChannelCount := StreamInfo.numChannels;
            Output.SampleRate := StreamInfo.sampleRate;
          end;

          // finally write audio data
          Output.WriteAudioData(@OutputBuffer^[0], StreamInfo^.numChannels * StreamInfo^.frameSize * SizeOf(SmallInt));
        until InputStream.Position = InputStream.Size;
      finally
        FreeMem(OutputBuffer);
        FreeAndNil(AdtsPacketReader);
      end;

      Result := True;
    finally
      FreeMem(InputBuffer);
    end;
  finally
    Decoder.Free;
  end;
end;

function DetectTransportType(InputStream: TFileStream): TTransportType;
var
  Value: array [0..3] of Byte;
  Name: array [0..3] of AnsiChar absolute Value;
begin
  Result := ttUnknown;
  if InputStream.Size < 4 then
    Exit;

  InputStream.Read(Value[0], 4);
  InputStream.Position := 0;

  // check
  if (Value[0] = $FF) and ((Value[1] shr 4) = $F) then
    Result := ttMp4Adts
  else
  if (Name[0] = 'I') and (Name[1] = 'D') and (Name[2] = '3') then
  begin
    Result := ttMp1Layer3;
    InputStream.Read(Value[1], 1);
    repeat
      Value[0] := Value[1];
      InputStream.Read(Value[1], 1);

      if InputStream.Position >= InputStream.Size then
        Exit(ttUnknown);
    until (Value[0] = $FF) and (Value[1] = $FB);
    InputStream.Position := InputStream.Position - 2;
  end;
end;

procedure DecodeFile(InputFile, OutputFile: TFileName);
var
  InputStream: TFileStream;
  OutputStream, OutputFileStream: TMemoryStream;
  AudioFile: TAudioFileContainerWAV;
  TransportType: TTransportType;
  Valid: Boolean;
begin
  if not FileExists(InputFile) then
  begin
    WriteLn('File ' + InputFile + ' does not seem to exist');
    WriteLn('');
    PrintUsage;
    Exit;
  end;

  InputStream := TFileStream.Create(InputFile, fmOpenRead);
  try
    TransportType := DetectTransportType(InputStream);
    if TransportType = ttUnknown then
    begin
      WriteLn('File ' + InputFile + ' does not seem to be a valid aac file');
      WriteLn('');
      PrintUsage;
      Exit;
    end;

    OutputStream := TMemoryStream.Create;
    try
      AudioFile := TAudioFileContainerWAV.Create(OutputStream);
      try
        AudioFile.BitsPerSample := 16;
        Valid := DecodeStream(InputStream, AudioFile, TransportType);
        AudioFile.Flush;
      finally
        AudioFile.Free;
      end;
      if Valid then
        OutputStream.SaveToFile(OutputFile);
    finally
      OutputStream.Free;
    end;
  finally
    InputStream.Free;
  end;
end;

begin
  try
    case ParamCount of
      1:
        DecodeFile(ParamStr(1), ParamStr(1) + '.wav');
      2:
        DecodeFile(ParamStr(1), ParamStr(2));
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
