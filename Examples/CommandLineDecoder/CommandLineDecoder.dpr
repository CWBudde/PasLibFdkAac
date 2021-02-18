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

procedure DecodeStream(InputStream: TStream; Output: TAudioFileContainerWAV;
  AdtsPacketReader: TAdtsPacketReader);
var
  Decoder: TFdkAacDecoder;
  InputBuffer: PByte;
  InputBufferSize: Cardinal;
  OutputBuffer: PByteArray;
  OutputBufferSize: Cardinal;
  BufferSize: Cardinal;
  StreamInfo: PStreamInfo;
  Index: Integer;
begin
  Assert(Assigned(InputStream));
  InputStream.Position := 0;
  StreamInfo := nil;

  Decoder := TFdkAacDecoder.Create(ttMp4Adts, 1);
  try
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
      try
        repeat
          // read first packet
          AdtsPacketReader.ReadFromStream(InputStream);
          BufferSize := AdtsPacketReader.FrameLength;
          InputStream.Read(InputBuffer^, BufferSize);

          // fill decoder
          Decoder.Fill(InputBuffer, BufferSize, BufferSize);

          Decoder.DecodeFrame(@OutputBuffer^, OutputBufferSize, []);

          // get stream information
          if not Assigned(StreamInfo) then
          begin
            StreamInfo := Decoder.GetStreamInfo;
            Output.ChannelCount := StreamInfo.numChannels;
          end;

          // finally write audio data
          Output.WriteAudioData(@OutputBuffer^[0], StreamInfo^.numChannels * StreamInfo^.frameSize * SizeOf(SmallInt));
        until InputStream.Position = InputStream.Size;
      finally
        FreeMem(OutputBuffer);
      end;
    finally
      FreeMem(InputBuffer);
    end;
  finally
    Decoder.Free;
  end;
end;

procedure DecodeFile(InputFile, OutputFile: TFileName);
var
  InputStream: TFileStream;
  OutputStream, OutputFileStream: TMemoryStream;
  AudioFile: TAudioFileContainerWAV;
  AdtsPacketReader: TAdtsPacketReader;
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
    AdtsPacketReader := TAdtsPacketReader.Create;
    try
      if not AdtsPacketReader.ReadFromStream(InputStream) then
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
          AudioFile.SampleRate := AdtsPacketReader.SamplingFrequency;
          AudioFile.ChannelCount := Cardinal(AdtsPacketReader.ChannelConfiguration);

          DecodeStream(InputStream, AudioFile, AdtsPacketReader);
          AudioFile.Flush;
        finally
          AudioFile.Free;
        end;
        OutputStream.SaveToFile(OutputFile);
      finally
        OutputStream.Free;
      end;
    finally
      AdtsPacketReader.Free;
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
