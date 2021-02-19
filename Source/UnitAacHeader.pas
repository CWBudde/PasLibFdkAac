unit UnitAacHeader;

interface

uses
  SysUtils, Classes;

type
  TMpegAudioObjectType = (
    maotAacMain = 0,
    maotAacLowComplexity = 1,
    maotAacScalableSampleRate = 2,
    maotAacLongTermPrediction = 3
  );

  TMpegSamplingFrequency = (
    msf96000 = 0,
    msf88200 = 1,
    msf64000 = 2,
    msf48000 = 3,
    msf44100 = 4,
    msf32000 = 5,
    msf24000 = 6,
    msf22050 = 7,
    msf16000 = 8,
    msf12000 = 9,
    msf11000 = 10,
    msf8000 = 11,
    msf7350 = 12,
    msfReserved1 = 13,
    msfReserved2 = 14,
    msfExplicit = 15
  );

  TMpegChannelConfiguration = (
    mccSpecificlyDefined = 0,
    mccFront1Channel = 1,
    mccFront2Channel = 2,
    mccFront3Channel = 3,
    mccFront4Channel = 4,
    mccFront5Channel = 5,
    mccFront6Channel = 6,
    mccFront8Channel = 7
  );

  TAdtsPacketReader = class
  private
    FIsMp4: Boolean;
    FHasCrC: Boolean;
    FProfile: TMpegAudioObjectType;
    FSamplingFrequencyIndex: TMpegSamplingFrequency;
    FIsPrivate: Boolean;
    FChannelConfiguration: TMpegChannelConfiguration;
    FOriginality: Boolean;
    FHome: Boolean;
    FCopyrightId: Boolean;
    FCopyrightIdStart: Boolean;
    FFrameLength: Word;
    FBufferFullnes: Word;
    FNumberOfAacFrames: Byte;
    FCrc: Word;
    FLastByte: Byte;
    FLastByteBitPos: Byte;
    function GetIsVariableBitrate: Boolean;

    function ReadBit(Stream: TStream): Boolean;
    function ReadBits(Stream: TStream; Bits: Byte): Cardinal;
    function GetSamplingFrequency: Cardinal;
  public
    function ReadFromStream(Stream: TStream): Boolean;

    property IsVariableBitrate: Boolean read GetIsVariableBitrate;
    property IsMp4: Boolean read FIsMp4;
    property HasCrC: Boolean read FHasCrC;
    property Profile: TMpegAudioObjectType read FProfile;
    property SamplingFrequencyIndex: TMpegSamplingFrequency read FSamplingFrequencyIndex;
    property SamplingFrequency: Cardinal read GetSamplingFrequency;
    property IsPrivate: Boolean read FIsPrivate;
    property ChannelConfiguration: TMpegChannelConfiguration read FChannelConfiguration;
    property Originality: Boolean read FOriginality;
    property Home: Boolean read FHome;
    property CopyrightId: Boolean read FCopyrightId;
    property CopyrightIdStart: Boolean read FCopyrightIdStart;
    property FrameLength: Word read FFrameLength;
    property BufferFullnes: Word read FBufferFullnes;
    property NumberOfAacFrames: Byte read FNumberOfAacFrames;
    property Crc: Word read FCrc;
  end;

implementation

{ TAdtsPacketReader }

function TAdtsPacketReader.GetIsVariableBitrate: Boolean;
begin
  Result := FBufferFullnes = $7FF;
end;

function TAdtsPacketReader.ReadBits(Stream: TStream; Bits: Byte): Cardinal;
var
  Index: Integer;
begin
  Assert(Bits > 0);
  Assert(Bits <= 16);

  Result := 0;
  for Index := 0 to Bits - 1 do
  begin
    if FLastByteBitPos = 0 then
      Stream.Read(FLastByte, 1);

    Result := (Result shl 1) or (FLastByte shr (7 - FLastByteBitPos) and 1);
    FLastByteBitPos := (FLastByteBitPos + 1) mod 8;
  end;
end;

function TAdtsPacketReader.GetSamplingFrequency: Cardinal;
begin
  case FSamplingFrequencyIndex of
    msf96000:
      Result := 96000;
    msf88200:
      Result := 88200;
    msf64000:
      Result := 64000;
    msf48000:
      Result := 48000;
    msf44100:
      Result := 44100;
    msf32000:
      Result := 32000;
    msf24000:
      Result := 24000;
    msf22050:
      Result := 22050;
    msf16000:
      Result := 16000;
    msf12000:
      Result := 12000;
    msf8000:
      Result := 8000;
    msf7350:
      Result := 7350;
  end;
end;

function TAdtsPacketReader.ReadBit(Stream: TStream): Boolean;
begin
  if FLastByteBitPos = 0 then
    Stream.Read(FLastByte, 1);

  Result := (FLastByte shr (7 - FLastByteBitPos) and 1) > 0;
  FLastByteBitPos := (FLastByteBitPos + 1) mod 8;
end;

function TAdtsPacketReader.ReadFromStream(Stream: TStream): Boolean;
var
  LastPos: Int64;
  Index: Integer;
  Value: array [0..6] of Byte;
begin
  LastPos := Stream.Position;
  Stream.Read(Value[0], 7);
  if (Value[0] <> $FF) or ((Value[1] shr 4) <> $F) then
  begin
    Stream.Position := LastPos;
    Exit(False);
  end;

  FIsMp4 := (Value[1] and $8) = 0;
  if (Value[1] and $6) <> 0 then
    raise Exception.Create('Unknown layer');
  FHasCrC := (Value[1] and $1) = 0;

  FProfile := TMpegAudioObjectType(Value[2] shr 6);
  FSamplingFrequencyIndex := TMpegSamplingFrequency((Value[2] shr 2) and $F);
  FIsPrivate := Value[2] and $2 > 0;
  FChannelConfiguration := TMpegChannelConfiguration(((Value[2] and $1) shl 1) or (Value[3] shr 6));
  FOriginality := (Value[3] and $20) <> 0;
  FCopyrightId := (Value[3] and $10) <> 0;
  FCopyrightIdStart := (Value[3] and $8) <> 0;
  FFrameLength := ((Value[3] and $3) shl 12) or (Value[4] shl 3) or (Value[5] shr 5);
  FBufferFullnes := ((Value[5] and $1F) shl 6) or (Value[6] shr 2);
  FNumberOfAacFrames := (Value[6] and $3) + 1;

  if FHasCrC then
    Stream.Read(FCrc, 2);

  Stream.Position := LastPos;
end;

end.
