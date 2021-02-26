unit UnitFdkAac;

interface

uses
  SysUtils, LibFdkAac;

type
  EFdkAacEncoder = class(Exception);
  EFdkAacEncoderInvalidConfiguration = class(EFdkAacEncoder);
  EFdkAacDecoder = class(Exception);

  TBitrateMode = (
    bmConstant,
    bmVeryLowBitrate,
    bmLowBitrate,
    bmMediumBitrate,
    bmHighBitrate,
    bmVeryHighBitrate
  );

  TSbrMode = (
    sbrDefault = -1,
    sbrDisable = 0,
    sbrEnable = 1
  );

  TFdkAacEncoder = class
  private
    FHandle: PAacEncoderInstance;
    function GetParam(Parameter: TAacEncoderParam): Cardinal;
    procedure SetParam(Parameter: TAacEncoderParam; const Value: Cardinal);
    function GetAfterburner: Boolean;
    function GetAncillaryBitrate: Cardinal;
    function GetAudioMuxVer: Byte;
    function GetAudioObjectType: TAudioObjectType;
    function GetBandwidth: Boolean;
    function GetBitrate: Cardinal;
    function GetBitrateMode: TBitrateMode;
    function GetChannelMode: TChannelMode;
    function GetGranuleLength: Cardinal;
    function GetHeaderPeriod: Cardinal;
    function GetMetadataMode: Byte;
    function GetPeakBitrate: Cardinal;
    function GetProtection: Boolean;
    function GetSamplerate: Cardinal;
    function GetSbrMode: TSbrMode;
    function GetSbrRatio: Byte;
    function GetSignalingMode: TSbrParametricStereoSignaling;
    function GetTpSubframes: Byte;
    function GetTransmux: TTransportType;
    procedure SetAfterburner(const Value: Boolean);
    procedure SetAncillaryBitrate(const Value: Cardinal);
    procedure SetAudioMuxVer(const Value: Byte);
    procedure SetBandwidth(const Value: Boolean);
    procedure SetBitrate(const Value: Cardinal);
    procedure SetBitrateMode(const Value: TBitrateMode);
    procedure SetChannelMode(const Value: TChannelMode);
    procedure SetGranuleLength(const Value: Cardinal);
    procedure SetHeaderPeriod(const Value: Cardinal);
    procedure SetMetadataMode(const Value: Byte);
    procedure SetPeakBitrate(const Value: Cardinal);
    procedure SetProtection(const Value: Boolean);
    procedure SetSamplerate(const Value: Cardinal);
    procedure SetSbrMode(const Value: TSbrMode);
    procedure SetSbrRatio(const Value: Byte);
    procedure SetSignalingMode(const Value: TSbrParametricStereoSignaling);
    procedure SetTpSubframes(const Value: Byte);
    procedure SetTransmux(const Value: TTransportType);
    procedure SetAudioObjectType(const Value: TAudioObjectType);
    function GetChannelOrder: Byte;
    procedure SetChannelOrder(const Value: Byte);
  public
    constructor Create(const encModules: Cardinal = 0; const maxChannels: Cardinal = 0);
    destructor Destroy; override;

    function Encode(var InputBufferDescriptor, OutputBufferDescriptor: TAacEncBufDesc;
      var InputArguments: TAacEncInArgs; var OutputArguments: TAacEncOutArgs): TAacEncoderError;
    procedure Initiazlize;
    function Info: TAacEncInfoStruct;
    class function GetLibInfo: TLibInfoArray;

    property Parameter[Param: TAacEncoderParam]: Cardinal read GetParam write SetParam;

    property AudioObjectType: TAudioObjectType read GetAudioObjectType write SetAudioObjectType;
    property Bitrate: Cardinal read GetBitrate write SetBitrate;
    property BitrateMode: TBitrateMode read GetBitrateMode write SetBitrateMode;
    property Samplerate: Cardinal read GetSamplerate write SetSamplerate;
    property SbrMode: TSbrMode read GetSbrMode write SetSbrMode;
    property GranuleLength: Cardinal read GetGranuleLength write SetGranuleLength;
    property ChannelMode: TChannelMode read GetChannelMode write SetChannelMode;
    property ChannelOrder: Byte read GetChannelOrder write SetChannelOrder;
    property SbrRatio: Byte read GetSbrRatio write SetSbrRatio;
    property Afterburner: Boolean read GetAfterburner write SetAfterburner;
    property Bandwidth: Boolean read GetBandwidth write SetBandwidth;
    property PeakBitrate: Cardinal read GetPeakBitrate write SetPeakBitrate;
    property Transmux: TTransportType read GetTransmux write SetTransmux;
    property HeaderPeriod: Cardinal read GetHeaderPeriod write SetHeaderPeriod;
    property SignalingMode: TSbrParametricStereoSignaling read GetSignalingMode write SetSignalingMode;
    property TpSubframes: Byte read GetTpSubframes write SetTpSubframes;
    property AudioMuxVer: Byte read GetAudioMuxVer write SetAudioMuxVer;
    property Protection: Boolean read GetProtection write SetProtection;
    property AncillaryBitrate: Cardinal read GetAncillaryBitrate write SetAncillaryBitrate;
    property MetadataMode: Byte read GetMetadataMode write SetMetadataMode;
  end;

  TFdkAacDecoder = class
  private
    FHandle: PAacDecoderInstance;
  public
    constructor Create(TransportFormat: TTransportType; NumberOfLayers: Cardinal);
    destructor Destroy; override;

    procedure AncDataInit(Buffer: PByte; Size: Integer);
    function AncDataGet(index: Integer): TBytes;
    procedure SetParam(const param: TAacDecoderParam; const value: Integer);
    function GetFreeBytes: Cardinal;
    procedure ConfigRaw(Configuration: TBytes);
    procedure Fill(var Buffer: PByte; var BufferSize: Cardinal; var ValidBytes: Cardinal);
    function DecodeFrame(TimeData: Pointer; const TimeDataSize: Integer;
      const Flags: TAacDecodeFrameFlags): Boolean;
    function GetStreamInfo: PStreamInfo;

    class function GetLibInfo: TLibInfoArray;
  end;

implementation

function AacDecodeFrameFlagsToCardinal(Flags: TAacDecodeFrameFlags): Cardinal;
begin
  Result := 0;
  if dfDoConcealment in Flags then
    Result := Result + 1;
  if dfFlushFilterBanks in Flags then
    Result := Result + 2;
  if dfInputDataIsContinous in Flags then
    Result := Result + 4;
  if dfClearHistoryBuffers in Flags then
    Result := Result + 8;
end;

{ TFdkAacEncoder }

constructor TFdkAacEncoder.Create(const encModules, maxChannels: Cardinal);
var
  Error: TAacEncoderError;
begin
  Error := AacEncOpen(FHandle, encModules, maxChannels);
  if Error <> aeOK then
    raise EFdkAacEncoder.Create('Error opening instance');
end;

destructor TFdkAacEncoder.Destroy;
var
  Error: TAacEncoderError;
begin
  Error := AacEncClose(FHandle);
  if Error <> aeOK then
    raise EFdkAacEncoder.Create('Error closing instance');

  inherited;
end;

function TFdkAacEncoder.Encode(var InputBufferDescriptor,
  OutputBufferDescriptor: TAacEncBufDesc;
  var InputArguments: TAacEncInArgs;
  var OutputArguments: TAacEncOutArgs): TAacEncoderError;
begin
  Result := AacEncEncode(FHandle, @InputBufferDescriptor,
    @OutputBufferDescriptor, @InputArguments, @OutputArguments);
end;

function TFdkAacEncoder.GetAfterburner: Boolean;
begin
  Result := AacEncGetParam(FHandle, aepAfterburner) <> 0;
end;

function TFdkAacEncoder.GetAncillaryBitrate: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepAncillaryBitrate);
end;

function TFdkAacEncoder.GetAudioMuxVer: Byte;
begin
  Result := Byte(AacEncGetParam(FHandle, aepAudioMuxVer));
end;

function TFdkAacEncoder.GetAudioObjectType: TAudioObjectType;
begin
  Result := TAudioObjectType(AacEncGetParam(FHandle, aepAudioObjectType));
end;

function TFdkAacEncoder.GetBandwidth: Boolean;
begin
  Result := AacEncGetParam(FHandle, aepBandwidth) <> 0;
end;

function TFdkAacEncoder.GetBitrate: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepBitrate);
end;

function TFdkAacEncoder.GetBitrateMode: TBitrateMode;
begin
  Result := TBitrateMode(AacEncGetParam(FHandle, aepBitrateMode));
end;

function TFdkAacEncoder.GetChannelMode: TChannelMode;
begin
  Result := TChannelMode(AacEncGetParam(FHandle, aepChannelMode));
end;

function TFdkAacEncoder.GetChannelOrder: Byte;
begin
  Result := AacEncGetParam(FHandle, aepChannelOrder);
end;

function TFdkAacEncoder.GetGranuleLength: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepGranuleLength);
end;

function TFdkAacEncoder.GetHeaderPeriod: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepHeaderPeriod);
end;

class function TFdkAacEncoder.GetLibInfo: TLibInfoArray;
var
  Error: TAacEncoderError;
begin
  Error := AacEncGetLibInfo(Result[fmNone]);
  if Error <> aeOK then
    raise EFdkAacEncoder.Create('Error getting library information');
end;

function TFdkAacEncoder.GetMetadataMode: Byte;
begin
  Result := AacEncGetParam(FHandle, aepMetadataMode);
end;

function TFdkAacEncoder.GetParam(Parameter: TAacEncoderParam): Cardinal;
begin
  Result := AacEncGetParam(FHandle, Parameter);
end;

function TFdkAacEncoder.GetPeakBitrate: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepPeakBitrate);
end;

function TFdkAacEncoder.GetProtection: Boolean;
begin
  Result := AacEncGetParam(FHandle, aepProtection) <> 0;
end;

function TFdkAacEncoder.GetSamplerate: Cardinal;
begin
  Result := AacEncGetParam(FHandle, aepSamplerate);
end;

function TFdkAacEncoder.GetSbrMode: TSbrMode;
begin
  Result := TSbrMode(AacEncGetParam(FHandle, aepSbrMode));
end;

function TFdkAacEncoder.GetSbrRatio: Byte;
begin
  Result := Byte(AacEncGetParam(FHandle, aepSbrRatio));
end;

function TFdkAacEncoder.GetSignalingMode: TSbrParametricStereoSignaling;
begin
  Result := TSbrParametricStereoSignaling(AacEncGetParam(FHandle, aepSignalingMode));
end;

function TFdkAacEncoder.GetTpSubframes: Byte;
begin
  Result := Byte(AacEncGetParam(FHandle, aepTpSubframes));
end;

function TFdkAacEncoder.GetTransmux: TTransportType;
begin
  Result := TTransportType(AacEncGetParam(FHandle, aepTransmux));
end;

function TFdkAacEncoder.Info: TAacEncInfoStruct;
var
  Error: TAacEncoderError;
begin
  Error := AacEncInfo(FHandle, Result);
  if Error <> aeOK then
    raise EFdkAacEncoder.Create('Error getting information');
end;

procedure TFdkAacEncoder.Initiazlize;
var
  Error: TAacEncoderError;
begin
  Error := AacEncEncode(FHandle, nil, nil, nil, nil);
  if Error <> aeOK then
    raise EFdkAacEncoder.Create('Error initializing');
end;

procedure TFdkAacEncoder.SetAfterburner(const Value: Boolean);
begin
  SetParam(aepAfterburner, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetAncillaryBitrate(const Value: Cardinal);
begin
  SetParam(aepAncillaryBitrate, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetAudioMuxVer(const Value: Byte);
begin
  SetParam(aepAudioMuxVer, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetAudioObjectType(const Value: TAudioObjectType);
begin
  case Value of
    aotAacLC, aotSBR, aotPS, aotErrorResAacELD, aotMp2AacLC, aotMp2Sbr:
      SetParam(aepAudioObjectType, Cardinal(Value));
    else
      raise EFdkAacEncoderInvalidConfiguration.Create('Invalid audio object type');
  end;
end;

procedure TFdkAacEncoder.SetBandwidth(const Value: Boolean);
begin
  SetParam(aepBandwidth, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetBitrate(const Value: Cardinal);
begin
  SetParam(aepBitrate, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetBitrateMode(const Value: TBitrateMode);
begin
  SetParam(aepBitrateMode, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetChannelMode(const Value: TChannelMode);
begin
  SetParam(aepChannelMode, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetChannelOrder(const Value: Byte);
begin
  SetParam(aepChannelOrder, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetGranuleLength(const Value: Cardinal);
begin
  case Value of
    1024, 512, 480, 256, 240, 128, 120:
      SetParam(aepGranuleLength, Cardinal(Value));
    else
      raise EFdkAacEncoderInvalidConfiguration.Create('Invalid granule length');
  end;
end;

procedure TFdkAacEncoder.SetHeaderPeriod(const Value: Cardinal);
begin
  SetParam(aepHeaderPeriod, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetMetadataMode(const Value: Byte);
begin
  SetParam(aepMetadataMode, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetParam(Parameter: TAacEncoderParam;
  const Value: Cardinal);
var
  Error: TAacEncoderError;
begin
  Error := AacEncSetParam(FHandle, Parameter, Value);
  if Error <> aeOK then
    case Error of
      aeInvalidConfig:
        raise EFdkAacEncoderInvalidConfiguration.Create(
          'Error setting parameter. Invalid configuration, probably not supported');
      else
        raise EFdkAacEncoder.Create('Error setting parameter');
    end;
end;

procedure TFdkAacEncoder.SetPeakBitrate(const Value: Cardinal);
begin
  SetParam(aepPeakBitrate, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetProtection(const Value: Boolean);
begin
  SetParam(aepProtection, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetSamplerate(const Value: Cardinal);
begin
  case Value of
    8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 64000, 88200,
    96000:
      SetParam(aepSamplerate, Cardinal(Value));
    else
      raise EFdkAacEncoderInvalidConfiguration.Create('Invalid Samplerate');
  end;
end;

procedure TFdkAacEncoder.SetSbrMode(const Value: TSbrMode);
begin
  SetParam(aepSbrMode, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetSbrRatio(const Value: Byte);
begin
  SetParam(aepSbrRatio, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetSignalingMode(const Value: TSbrParametricStereoSignaling);
begin
  SetParam(aepSignalingMode, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetTpSubframes(const Value: Byte);
begin
  SetParam(aepTpSubframes, Cardinal(Value));
end;

procedure TFdkAacEncoder.SetTransmux(const Value: TTransportType);
begin
  SetParam(aepTransmux, Cardinal(Value));
end;


{ TFdkAacDecoder }

constructor TFdkAacDecoder.Create(TransportFormat: TTransportType;
  NumberOfLayers: Cardinal);
begin
  FHandle := AacDecOpen(TransportFormat, NumberOfLayers);
end;

destructor TFdkAacDecoder.Destroy;
begin
  AacDecClose(FHandle);

  inherited;
end;

function TFdkAacDecoder.AncDataGet(Index: Integer): TBytes;
var
  Error: TAacDecoderError;
  Buffer: PByte;
  Size: Integer;
begin
  Error := AacDecAncDataGet(FHandle, Index, Buffer, Size);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error getting ancilliary data');

  // now copy the buffer content to the result
  SetLength(Result, Size);
  Move(Buffer^, Result[0], Size);
end;

procedure TFdkAacDecoder.AncDataInit(Buffer: PByte; Size: Integer);
var
  Error: TAacDecoderError;
begin
  Error := AacDecAncDataInit(FHandle, Buffer, Size);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error initializing ancilliary data');
end;

procedure TFdkAacDecoder.ConfigRaw(Configuration: TBytes);
var
  Error: TAacDecoderError;
begin
  Error := AacDecConfigRaw(FHandle, @Configuration[0], Length(Configuration));
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error getting raw configuration');
end;

function TFdkAacDecoder.DecodeFrame(TimeData: Pointer;
  const TimeDataSize: Integer; const Flags: TAacDecodeFrameFlags): Boolean;
var
  Error: TAacDecoderError;
begin
  Error := AacDecDecodeFrame(FHandle, TimeData, TimeDataSize,
    AacDecodeFrameFlagsToCardinal(Flags));
  if (Error = adOK) or (Error = adNotEnoughBits) then
    Result := Error = adOK
  else
    raise EFdkAacDecoder.Create('Error decoding frame');
end;

procedure TFdkAacDecoder.Fill(var Buffer: PByte; var BufferSize: Cardinal;
  var ValidBytes: Cardinal);
var
  Error: TAacDecoderError;
begin
  Error := AacDecFill(FHandle, Buffer, BufferSize, ValidBytes);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error filling buffer');
end;

function TFdkAacDecoder.GetFreeBytes: Cardinal;
var
  Error: TAacDecoderError;
begin
  Error := AacDecGetFreeBytes(FHandle, Result);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error getting free bytes');
end;

class function TFdkAacDecoder.GetLibInfo: TLibInfoArray;
var
  Error: TAacDecoderError;
begin
  Error := AacDecGetLibInfo(Result[fmNone]);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error getting library information');
end;

function TFdkAacDecoder.GetStreamInfo: PStreamInfo;
begin
  Result := AacDecGetStreamInfo(FHandle);
end;

procedure TFdkAacDecoder.SetParam(const param: TAacDecoderParam;
  const value: Integer);
var
  Error: TAacDecoderError;
begin
  Error := AacDecSetParam(FHandle, param, value);
  if Error <> adOK then
    raise EFdkAacDecoder.Create('Error setting parameter');
end;

end.
