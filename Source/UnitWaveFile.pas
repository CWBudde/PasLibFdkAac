unit UnitWaveFile;

interface

uses
  Classes, Contnrs, SysUtils;

type
  TChunkName = array [0..3] of AnsiChar;
  TChunkFlag = (cfSizeFirst, cfReversedByteOrder, cfPadSize,
    cfIncludeChunkInSize);
  TChunkFlags = set of TChunkFlag;

  TCustomChunk = class(TInterfacedPersistent, IStreamPersist)
  protected
    FChunkName: TChunkName;
    FChunkSize: Cardinal;
    FChunkFlags: TChunkFlags;
    function GetChunkNameAsString: AnsiString; virtual;
    function GetChunkSize: Cardinal; virtual;
    function CalculateZeroPad: Integer;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetChunkNameAsString(const Value: AnsiString); virtual;
    procedure CheckAddZeroPad(Stream: TStream);
  public
    constructor Create; virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure LoadFromFile(FileName: TFileName); virtual;
    procedure SaveToFile(FileName: TFileName); virtual;

    property ChunkName: TChunkName read FChunkName;
    property ChunkNameAsString: AnsiString read GetChunkNameAsString write SetChunkNameAsString;
    property ChunkSize: Cardinal read GetChunkSize;
    property ChunkFlags: TChunkFlags read FChunkFlags write FChunkFlags default [];
  end;

  TCustomChunkClass = class of TCustomChunk;

  TDummyChunk = class(TCustomChunk)
  public
    procedure LoadFromStream(Stream: TStream); override;
  end;

  TUnknownChunk = class(TCustomChunk)
  private
    function GetData(Index: Integer): Byte;
    procedure SetData(Index: Integer; const Value: Byte);
  protected
    FDataStream: TMemoryStream;
    function CalculateChecksum: Integer;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

    property Data[Index: Integer]: Byte read GetData write SetData;
    property DataStream: TMemoryStream read FDataStream;
  end;

  TDefinedChunk = class(TCustomChunk)
  protected
    FFilePosition: Cardinal;
    procedure SetChunkNameAsString(const Value: AnsiString); override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;

    class function GetClassChunkName: TChunkName; virtual; abstract;
    procedure LoadFromStream(Stream: TStream); override;

    property FilePosition: Cardinal read FFilePosition;
  end;

  TDefinedChunkClass = class of TDefinedChunk;

  TFixedDefinedChunk = class(TDefinedChunk)
  private
    function GetStartAddress: Pointer;
    procedure SetStartAddress(const Value: Pointer);
  protected
    FStartAddresses: array of Pointer;
    procedure AssignTo(Dest: TPersistent); override;
    function GetChunkSize: Cardinal; override;
    class function GetClassChunkSize: Cardinal; virtual; abstract;

    property StartAddress: Pointer read GetStartAddress write SetStartAddress;
  public
    constructor Create; override;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TChunkList = class(TObjectList)
  protected
    function GetItem(Index: Integer): TCustomChunk;
    procedure SetItem(Index: Integer; AChunk: TCustomChunk);
  public
    function Add(AChunk: TCustomChunk): Integer;
    function Extract(Item: TCustomChunk): TCustomChunk;
    function Remove(AChunk: TCustomChunk): Integer;
    function IndexOf(AChunk: TCustomChunk): Integer;
    procedure Insert(Index: Integer; AChunk: TCustomChunk);
    function First: TCustomChunk;
    function Last: TCustomChunk;

    property Items[Index: Integer]: TCustomChunk read GetItem write SetItem; default;
  end;

  TCustomChunkContainer = class(TDefinedChunk)
  private
    function GetSubChunk(Index: Integer): TCustomChunk;
    function GetCount: Integer;
  protected
    FChunkList: TChunkList;
    function GetChunkClass(ChunkName: TChunkName): TCustomChunkClass;
      virtual; abstract;
    function GetChunkSize: Cardinal; override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure ConvertStreamToChunk(ChunkClass: TCustomChunkClass;
      Stream: TStream); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure AddChunk(Chunk: TCustomChunk); virtual;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

    property SubChunk[Index: Integer]: TCustomChunk read GetSubChunk;
    property Count: Integer read GetCount;
  end;

  TChunkContainer = class(TCustomChunkContainer)
  protected
    FRegisteredChunks: array of TDefinedChunkClass;
    function GetChunkClass(ChunkName: TChunkName): TCustomChunkClass; override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure RegisterChunkClass(ChunkClass: TDefinedChunkClass);
    procedure RegisterChunkClasses; overload;
    procedure RegisterChunkClasses(ChunkClasses: array of TDefinedChunkClass); overload;

    property Count;
  end;

  TChunkedFile = class(TCustomChunkContainer)
  private
    class var FChunkClasses: array of TDefinedChunkClass;
    class function IsChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
  public
    class procedure RegisterChunk(AClass: TDefinedChunkClass);
    class procedure RegisterChunks(AClasses: array of TDefinedChunkClass);
    class function ChunkClassByName(Value: string): TDefinedChunkClass;
    class function ChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;
  end;


  TUnknownChunkContainer = class(TUnknownChunk)
  private
    function GetSubChunk(Index: Integer): TCustomChunk;
    function GetCount: Integer;
    function ConvertStreamToChunk(ChunkClass: TCustomChunkClass;
      Stream: TStream): TCustomChunk; virtual;
  protected
    FChunkList: TChunkList;
    function CheckForSubchunks: Boolean; virtual;
    function GetChunkSize: Cardinal; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

    property SubChunk[Index: Integer]: TCustomChunk read GetSubChunk;
    property Count: Integer read GetCount;
  end;

  TCustomBinaryChunk = class(TDefinedChunk)
  protected
    FBinaryData: Array of Byte;
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TCustomTextChunk = class(TDefinedChunk)
  protected
    FText: AnsiString;
    procedure SetText(const Value: AnsiString);
    procedure AssignTo(Dest: TPersistent); override;
    property Text: AnsiString read FText write SetText;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TCustomStreamChunk = class(TDefinedChunk)
  protected
    FStream: TStream;
    procedure AssignTo(Dest: TPersistent); override;
    function GetChunkSize: Cardinal; override;
  public
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TCustomMemoryStreamChunk = class(TCustomStreamChunk)
  private
    function GetMemoryStream: TMemoryStream;
  public
    constructor Create; override;
    property MemoryStream: TMemoryStream read GetMemoryStream;
  end;

type
  TWavEncoding = (
    etUnknown = $0,
    etPcm = $1,
    etMsAdPcm = $2,
    etPcmFloat = $3,
    etCompaqVSELP = $4,
    etIbmCVSD = $5,
    etALaw = $6,
    etMuLaw = $7,
    etMicrosoftDTS = $8,
    etDRM = $9,
    etWMA9Speech = $A,
    etWMRTVoice = $B,
    etOKIAdPcm = $10,
    etDVIAdPcm = $11,
    etMediaSpaceAdPcm = $12,
    etSierraAdPcm = $13,
    etG723AdPcm = $14,
    etDIGISTD = $15,
    etDIGIFIX = $16,
    etDiaLogicAdPcm = $17,
    etMVAdPcm = $18,
    etHPCU = $19,
    etHPDynamicVoice = $1A,
    etYamahaAdPcm = $20,
    etSONARC = $21,
    etTrueSpeech = $22,
    etECHOSC1 = $23,
    etAF36 = $24,
    etAPTX = $25,
    etAF10 = $26,
    etProsody1612 = $27,
    etMergingTechLRC = $28,
    etDolbyAC2 = $30,
    etGSM610 = $31,
    etMSNAudio = $32,
    etAntexAdPcmE = $33,
    etResVQLPC1 = $34,
    etResVQLPC2 = $35,
    etDigiAdPcm = $36,
    etResCR10 = $37,
    etVBXAdPcm = $38,
    etIMAAdPcm = $39,
    etECHOSC3 = $3A,
    etRockwellAdPcm = $3B,
    etDIGITALK = $3C,
    etXebecMultimedia = $3D,
    etG721AdPcm = $40,
    etAntexG728CELP = $41,
    etMicrosoftMSG723 = $42,
    etIBMAVCAdPcm = $43,
    etITU_TG726 = $45,
    etMPEG = $50,
    etRT23orPAC = $51,
    etInSoftRT24 = $52,
    etInSoftPAC = $53,
    etMP3 = $55,
    etCirrus = $59,
    etCirrusLogic = $60,
    etESSTechPCM = $61,
    etVoxwareInc = $62,
    etCanopusATRAC = $63,
    etAPICOMG726AdPcm = $64,
    etAPICOMG722AdPcm = $65,
    etMicrosoftDSAT = $66,
    etMSDSATDISPLAY = $67,
    etXboxAdPcm = $69,
    etVoxwareAC8 = $70,
    etVoxwareAC10 = $71,
    etVoxwareAC16 = $72,
    etVoxwareAC20 = $73,
    etVoxwareMetaVoice = $74,
    etVoxwareMetaSound = $75,
    etVoxwareRT29HW = $76,
    etVoxwareVR12 = $77,
    etVoxwareVR18 = $78,
    etVoxwareTQ40 = $79,
    etVoxwareSC3A = $7A,
    etVoxwareSC3B = $7B,
    etSoundsoft = $80,
    etVoxwareTQ60 = $81,
    etMicrosoftMSRT24 = $82,
    etATandTG729A = $83,
    etMP_MVI_MV12 = $84,
    etDF_G726 = $85,
    etDF_GSM610 = $86,
    etItrdSystemsAudio = $88,
    etOnlive = $89,
    etM_FTSX20 = $8A,
    etITSASG721AdPcm = $8B,
    etConvediaG729 = $8C,
    etNSpC_Inc = $8D,
    etSiemensSBC24 = $91,
    etSF_DolbyAC3APDIF = $92,
    etMediaSonicG723 = $93,
    etProsody8kbps = $94,
    etZyXELAdPcm = $97,
    etPhilipsLPCBB = $98,
    etStuderProPacked = $99,
    etMaldenPhonyTalk = $A0,
    etRacalRecorderGSM = $A1,
    etRecorderG720a = $A2,
    etRacalG723_1 = $A3,
    etRacalTetraACELP = $A4,
    etNECAAC = $B0,
    etExtended = $FE,
    etAAC = $FF,
    etRhetorexAdPcm = $100,
    etIBMuLaw = $101,
    etIBMaLaw = $102,
    etIBMAdPcm = $103,
    etVivoG723 = $111,
    etVivoSiren = $112,
    etCELP = $120,
    etGRUNDIG = $121,
    etDigitalG723 = $123,
    etSanyoLD_AdPcm = $125,
    etSiproLabACEPLNET = $130,
    etSL_ACELP4800 = $131,
    etSL_ACELP8V3 = $132,
    etSL_G729 = $133,
    etSL_G729A = $134,
    etSL_Kelvin = $135,
    etVoiceAgeAMR = $136,
    etG726AdPcm = $140,
    etQC_PureVoice = $150,
    etQC_HalfRate = $151,
    etRZS_TUBGSM = $155,
    etMicrosoftAudio = $160,
    etWMA_DivX_AC3 = $161,
    etWMA_ProV9 = $162,
    etWMA_LosslessV9 = $163,
    etWMAProOverSPDIF = $164,
    etUNISYS_AdPcm = $170,
    etUNISYS_ULAW = $171,
    etUNISYS_ALAW = $172,
    etUNISYS_16K = $173,
    etSYC008_SyCom = $174,
    etSYC701_G726L = $175,
    etSYC701_CELP54 = $176,
    etSYC701_CELP68 = $177,
    etKA_AdPcm = $178,
    etIISMPEG2AAC = $180,
    etDTS_DS = $190,
    etCreativeAdPcm = $200,
    etFastSpeech8 = $202,
    etFastSpeech10 = $203,
    etUHERAdPcm = $210,
    etUleadDVACM_A = $215,
    etUleadDVACM_B = $216,
    etQuarterdeckCorp = $220,
    etILinkVC = $230,
    etAurealRawSport = $240,
    etESSTAC3 = $241,
    etIP_HSX = $250,
    etIP_RPELP = $251,
    etConsistentCS2 = $260,
    etSonySCX = $270,
    etSonySCY = $271,
    etSonyATRAC3 = $272,
    etSonySPC = $273,
    etTELUM_TelumInc = $280,
    etTELUMIA_TelumInc = $281,
    etNVS_AdPcm = $285,
    etFMTownsSND = $300,
    etFujitsu1 = $301,
    etFujitsu2 = $302,
    etFujitsu3 = $303,
    etFujitsu4 = $304,
    etFujitsu5 = $305,
    etFujitsu6 = $306,
    etFujitsu7 = $307,
    etFujitsu8 = $308,
    etMSIncDev = $350,
    etMSIncCELP833 = $351,
    etBrooktreeDigital = $400,
    etIntel_IMC = $401,
    etLigosIndeoAudio = $402,
    etQDesignMusic = $450,
    etOn2VP7 = $500,
    etOn2VP6 = $501,
    etATandT_VMPCM = $680,
    etATandT_TCP = $681,
    etYMPEGAlpha = $700,
    etClearJumpLiteWav = $8AE,
    etOLIGSM = $1000,
    etOLIAdPcm = $1001,
    etOLICELP = $1002,
    etOLISBC = $1003,
    etOLIOPR = $1004,
    etLH = $1100,
    etLH_CELPcodec = $1101,
    etLH_SBCcodecA = $1102,
    etLH_SBCcodecB = $1103,
    etLH_SBCcodec = $1104,
    etNorrisCommInc = $1400,
    etISIAudio = $1401,
    etATnT_Soundspace = $1500,
    etVoxWareRT24 = $181C,
    etLucentAX24000P = $181E,
    etSF_LOSSLESS = $1971,
    etITI_AdPcm = $1979,
    etLucentSX8300P = $1C07,
    etLucentSX5363S = $1C0C, // G.723 complient
    etCUseeMeDigiTalk = $1F03,
    etNCTSoftALF2CDACM = $1FC4,
    etFASTMultimDVM = $2000,
    etDolbyDTS = $2001,
    etRealAudio14_4 = $2002,
    etRealAudio28_8 = $2003,
    etRealAudioG28Cook = $2004,
    etRealAudioMusic = $2005,
    etRealAudio10RAAC = $2006,
    etRealAudio10RACP = $2007,
    etmakeAVIS = $3313,
    etDivioMPEG4AAC = $4143,
    etNokiaAdaptiveMR = $4201,
    etDivioG726 = $4243,
    etLEADSpeech = $434C,
    etLEADVorbis = $564C,
    etWavPackAudio = $5756,
    etOggVorbisMode1 = $674F,
    etOggVorbisMode2 = $6750,
    etOggVorbisMode3 = $6751,
    etOggVorbisMode1p = $676F,
    etOggVorbisMode2p = $6770,
    etOggVorbisMode3p = $6771,
    et3COM_NBX = $7000,
    etFAAD_AAC = $706D,
    etGSM_AMR_CBR = $7A21,
    etGSM_AMR_VBR = $7A22,
    etComInfosysG723 = $A100,
    etComInfosysAVQSBC = $A101,
    etComInfosysOLDSBC = $A102,
    etSymbolTec_G729A = $A103,
    etVoiceAgeAMRWB = $A104,
    etIngTech_G726 = $A105,
    etISOMPEG4_AAC = $A106,
    etEncoreSoft_G726 = $A107,
    etSpeexACMCodec = $A109,
    etSF_ACM_Codec = $DFAC,
    etFLAC = $F1AC,
    etExtensible = $FFFE,
    etExperimental = $FFFF);

  TWavFormatRecord = packed record
    FormatTag: Word; // format type
    Channels: Word; // number of channels (i.e. mono, stereo, etc.)
    SampleRate: Cardinal; // sample rate
    BytesPerSecond: Cardinal; // = SampleRate * BlockAlign
    BlockAlign: Word; // block size of data
    BitsPerSample: Word; // = 3, 4, 8, 16 or 32 Bits/sample
  end;
  PWavFormatChunkExtensible = ^TWavFormatChunkExtensible;

  TWavFormatChunkExtensible = packed record
    SamplesPerBlock: Word; // number of samples per channel per Block
    ChMask: Integer;
    GUID: TGUID; // was array [0..71] of Byte;
  end;

  TWavAdPcmCoefficientSet = packed record
    Coefficient: array [0 .. 1] of SmallInt;
  end;

  TWavAdPcmInfoEx = packed record
    SamplesPerBlock: Word;
    NumCoeff: Word;
    CoefSets: array [0 .. 35] of TWavAdPcmCoefficientSet;
  end;

  TAdPcmState = packed record
    PrevSampleLeft: SmallInt;
    IndexLeft: Byte;
    PrevSampleRight: SmallInt;
    IndexRight: Byte;
  end;

  TAdPcmMs = packed record
    Predictor: array [0 .. 1] of Byte;
    Delta: array [0 .. 1] of SmallInt;
    Samp1: array [0 .. 1] of SmallInt;
    Samp2: array [0 .. 1] of SmallInt;
  end;

  TWavDefinedChunk = class(TDefinedChunk)
  public
    constructor Create; override;
  end;

  TWavFixedDefinedChunk = class(TFixedDefinedChunk)
  public
    constructor Create; override;
  end;

  TWavChunkText = class(TCustomTextChunk)
  public
    constructor Create; override;
  end;

  TWavUnknownChunk = class(TUnknownChunk)
  public
    constructor Create; override;
  end;

  TWavBinaryChunk = class(TCustomBinaryChunk)
  public
    constructor Create; override;
  end;

  TFormatChunk = class(TWavDefinedChunk)
  private
    function GetFormatTag: TWavEncoding;
    function GetValidBitsPerSample: Word;
    procedure CalculateChunkSize;
    procedure SetBitsPerSample(const Value: Word);
    procedure SetBlockAlign(const Value: Word);
    procedure SetBytesPerSecond(const Value: Cardinal);
    procedure SetChannels(const Value: Word);
    procedure SetFormatTag(const Value: TWavEncoding);
    procedure SetSampleRate(const Value: Cardinal);
  protected
    FFormatSpecific: array of Byte;
    FFormatExtensible: PWavFormatChunkExtensible;
    FWaveFormatRecord: TWavFormatRecord;
    procedure AssignTo(Dest: TPersistent); override;
    function GetChunkSize: Cardinal; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property FormatTag: TWavEncoding read GetFormatTag write SetFormatTag;
    property Channels: Word read FWaveFormatRecord.Channels write SetChannels;
    property SampleRate: Cardinal read FWaveFormatRecord.SampleRate
      write SetSampleRate;
    property BytesPerSecond: Cardinal read FWaveFormatRecord.BytesPerSecond
      write SetBytesPerSecond;
    property BlockAlign: Word read FWaveFormatRecord.BlockAlign
      write SetBlockAlign;
    property BitsPerSample: Word read FWaveFormatRecord.BitsPerSample
      write SetBitsPerSample;
    property ValidBitsPerSample: Word read GetValidBitsPerSample;
  end;

  TFactRecord = packed record
    SampleCount: Cardinal;
  end;

  TFactChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    FactRecord: TFactRecord;
    constructor Create; override;
    class function GetClassChunkSize: Cardinal; override;
    class function GetClassChunkName: TChunkName; override;

    property SampleCount: Cardinal read FactRecord.SampleCount
      write FactRecord.SampleCount;
  end;

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s2_tcm6-10482.pdf

  TQualityChunkRecord = packed record
    FileSecurityReport: Cardinal; // FileSecurityCode of quality report
    FileSecurityWave: Cardinal; // FileSecurityCode of BWF wave data
  end;

  TQualityChunk = class(TWavBinaryChunk)
  public
    class function GetClassChunkName: TChunkName; override;
  end;

  TInfoSoftwareNameChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property SoftwareName: AnsiString read FText write FText;
  end;

  TInfoCommentChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Comment: AnsiString read FText write FText;
  end;

  TInfoCreationDateChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property CreationDate: AnsiString read FText write FText;
  end;

  TInfoCopyrightChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Copyright: AnsiString read FText write FText;
  end;

  TInfoSubjectChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Subject: AnsiString read FText write FText;
  end;

  TInfoArtistChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Artist: AnsiString read FText write FText;
  end;

  TInfoTitleChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;

    property Title: AnsiString read FText write FText;
  end;

  TCustomWavCuedTextChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FText: string;
    FCueID: Cardinal;
    procedure SetText(const Value: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
  end;

  TLabelChunk = class(TCustomWavCuedTextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Text: string read FText write FText;
  end;

  TNoteChunk = class(TCustomWavCuedTextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Note: string read FText write FText;
  end;

  TLabeledTextRecord = packed record
    CuePointID: Cardinal;
    SampleLength: Cardinal;
    PurposeID: Cardinal;
    Country: Word;
    Language: Word;
    Dialect: Word;
    CodePage: Word;
  end;

  TLabeledTextChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FText: string;
    procedure SetText(const Value: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    LabeledTextRecord: TLabeledTextRecord;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Text: string read FText write FText;
    property CuePointID: Cardinal read LabeledTextRecord.CuePointID
      write LabeledTextRecord.CuePointID;
    property SampleLength: Cardinal read LabeledTextRecord.SampleLength
      write LabeledTextRecord.SampleLength;
    property PurposeID: Cardinal read LabeledTextRecord.PurposeID
      write LabeledTextRecord.PurposeID;
    property Country: Word read LabeledTextRecord.Country
      write LabeledTextRecord.Country;
    property Language: Word read LabeledTextRecord.Language
      write LabeledTextRecord.Language;
    property Dialect: Word read LabeledTextRecord.Dialect
      write LabeledTextRecord.Dialect;
    property CodePage: Word read LabeledTextRecord.CodePage
      write LabeledTextRecord.CodePage;
  end;

  TCuedFileChunk = class(TWavDefinedChunk)
  private
    procedure CalculateChunkSize;
  protected
    FCueID: Cardinal;
    FMediaType: Cardinal;
    FBinaryData: array of Byte;
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;
  end;

  TPlaylistSegmentRecord = packed record
    CuePointID: Cardinal;
    LengthInSamples: Cardinal;
    NumberOfRepeats: Cardinal;
  end;

  TPlaylistSegmentItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    PlaylistSegment: TPlaylistSegmentRecord;

    property CuePointID: Cardinal read PlaylistSegment.CuePointID
      write PlaylistSegment.CuePointID;
    property LengthInSamples: Cardinal read PlaylistSegment.LengthInSamples
      write PlaylistSegment.LengthInSamples;
    property NumberOfRepeats: Cardinal read PlaylistSegment.NumberOfRepeats
      write PlaylistSegment.NumberOfRepeats;
  end;

  TPlaylistChunk = class(TWavDefinedChunk)
  private
    FCount: Cardinal;
    FPlaylistSegments: TOwnedCollection;
    procedure CalculateChunkSize;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property PlaylistSegments: TOwnedCollection read FPlaylistSegments;
  end;

  TSilentRecord = packed record
    NumberOfSilentSamples: Cardinal;
  end;

  TSilentChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    SilentRecord: TSilentRecord;
    constructor Create; override;
    class function GetClassChunkSize: Cardinal; override;
    class function GetClassChunkName: TChunkName; override;

    property NumberOfSilentSamples: Cardinal
      read SilentRecord.NumberOfSilentSamples
      write SilentRecord.NumberOfSilentSamples;
  end;

  TWavelistRecord = packed record
    NumberOfSilentSamples: Cardinal;
  end;

  TCustomPaddingChunk = class(TWavDefinedChunk)
  public
    procedure LoadFromStream(Stream: TStream); override;
  end;

  TJunkChunk = class(TCustomPaddingChunk)
  private
    FPadding: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Padding: Integer read FPadding write FPadding default 16;
  end;

  TPadChunk = class(TCustomPaddingChunk)
  private
    FAlignSize: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream); override;
    procedure LoadFromStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property AlignSize: Integer read FAlignSize write FAlignSize default 2048;
  end;

  TCuePointRecord = packed record
    CuePointName: TChunkName;
    CuePointPos: Cardinal;
    CuePointChunk: Cardinal;
    FilePosStart: Cardinal;
    BlockStartPos: Cardinal;
    SampleOffset: Cardinal;
  end;

  TCueItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    CuePointRecord: TCuePointRecord;

    property CuePointName: TChunkName read CuePointRecord.CuePointName
      write CuePointRecord.CuePointName;
    property CuePointSamplePosition: Cardinal read CuePointRecord.CuePointPos
      write CuePointRecord.CuePointPos;
    property FileStartPosition: Cardinal read CuePointRecord.FilePosStart
      write CuePointRecord.FilePosStart;
    property RelativeBlockStartPosition: Cardinal
      read CuePointRecord.BlockStartPos write CuePointRecord.BlockStartPos;
    property RelativeBlockSampleOffset: Cardinal
      read CuePointRecord.SampleOffset write CuePointRecord.SampleOffset;
  end;

  TCueChunk = class(TWavDefinedChunk)
  private
    FCount: Cardinal;
    FCueCollection: TOwnedCollection;
    procedure CalculateChunkSize;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property CueCollection: TOwnedCollection read FCueCollection;
  end;

  TSMPTEFormat = (soZero = 0, so24 = 24, so25 = 25, so30Drop = 29, so30 = 30);

  TMidiManufacturer = (
    mmUnknown = $00,
    mmSequentialCircuits = $01,
    mmBigBriar = $02,
    mmOctavePlateau = $03,
    mmMoog = $04,
    mmPassportDesigns = $05,
    mmLexicon = $06,
    mmKurzweil = $07,
    mmFender = $08,
    mmGulbransen = $09,
    mmDeltaLabs = $0A,
    mmSoundComp = $0B,
    mmGeneralElectro = $0C,
    mmTechmar = $0D,
    mmMatthewsResearch = $0E,
    mmOberheim = $10,
    mmPAIA = $11,
    mmSimmons = $12,
    mmDigiDesign = $13,
    mmFairlight = $14,
    mmJLCooper = $15,
    mmLowery = $16,
    mmLin = $17,
    mmEmu = $18,
    mmPeavey = $1B,
    mmBonTempi = $20,
    mmSIEL = $21,
    mmSyntheAxe = $23,
    mmHohner = $24,
    mmCrumar = $25,
    mmSolton = $26,
    mmJellinghausMs = $27,
    mmCTS = $28,
    mmPPG = $29,
    mmElka = $2F,
    mmCheetah = $36,
    mmWaldorf = $3E,
    mmKawai = $40,
    mmRoland = $41,
    mmKorg = $42,
    mmYamaha = $43,
    mmCasio = $44,
    mmKamiyaStudio = $46,
    mmAkai = $47,
    mmVictor = $48,
    mmFujitsu = $4B,
    mmSony = $4C,
    mmTeac = $4E,
    mmMatsushita1 = $50,
    mmFostex = $51,
    mmZoom = $52,
    mmMatsushita2 = $54,
    mmSuzuki = $55,
    mmFujiSound = $56,
    mmAcousticTecLab = $57
  );

  TSamplerRecord = packed record
    Manufacturer: Cardinal;
    Product: Cardinal;
    SamplePeriod: Cardinal;
    MIDIUnityNote: Cardinal;
    MIDIPitchFraction: Cardinal;
    SMPTEFormat: Cardinal; // 0, 24, 25, 29, 30
    SMPTEOffset: Cardinal;
    NumSampleLoops: Cardinal;
    SamplerData: Cardinal;
  end;

  TLoopRecord = packed record
    CuePointID: Cardinal;
    LoopType: Cardinal;
    LoopStart: Cardinal;
    LoopEnd: Cardinal;
    Fraction: Cardinal;
    PlayCount: Cardinal;
  end;

  TLoopItem = class(TCollectionItem)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    LoopRecord: TLoopRecord;

    property CuePointID: Cardinal read LoopRecord.CuePointID
      write LoopRecord.CuePointID;
    property LoopType: Cardinal read LoopRecord.LoopType
      write LoopRecord.LoopType;
    property LoopStart: Cardinal read LoopRecord.LoopStart
      write LoopRecord.LoopStart;
    property LoopEnd: Cardinal read LoopRecord.LoopEnd write LoopRecord.LoopEnd;
    property Fraction: Cardinal read LoopRecord.Fraction
      write LoopRecord.Fraction;
    property PlayCount: Cardinal read LoopRecord.PlayCount
      write LoopRecord.PlayCount;
  end;

  TSamplerChunk = class(TWavDefinedChunk)
  private
    FLoopCollection: TOwnedCollection;
    function GetManufacturer: TMidiManufacturer;
    function GetSMPTEFormat: TSMPTEFormat;
    procedure CalculateChunkSize;
    procedure SetManufacturer(const Value: TMidiManufacturer);
    procedure SetSMPTEFormat(const Value: TSMPTEFormat);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    SamplerRecord: TSamplerRecord;
    constructor Create; override;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    class function GetClassChunkName: TChunkName; override;

    property Manufacturer: TMidiManufacturer read GetManufacturer
      write SetManufacturer;
    property Product: Cardinal read SamplerRecord.Product
      write SamplerRecord.Product;
    property SamplePeriod: Cardinal read SamplerRecord.SamplePeriod
      write SamplerRecord.SamplePeriod;
    property MIDIUnityNote: Cardinal read SamplerRecord.MIDIUnityNote
      write SamplerRecord.MIDIUnityNote;
    property MIDIPitchFraction: Cardinal read SamplerRecord.MIDIPitchFraction
      write SamplerRecord.MIDIPitchFraction;
    property SMPTEFormat: TSMPTEFormat read GetSMPTEFormat write SetSMPTEFormat;
    property SMPTEOffset: Cardinal read SamplerRecord.SMPTEOffset
      write SamplerRecord.SMPTEOffset;
    property NumSampleLoops: Cardinal read SamplerRecord.NumSampleLoops;
    property SamplerData: Cardinal read SamplerRecord.SamplerData
      write SamplerRecord.SamplerData;
    property LoopCollection: TOwnedCollection read FLoopCollection;
  end;

  TInstrumentRecord = packed record
    UnshiftedNote: Byte;
    FineTune: ShortInt;
    Gain_dB: ShortInt;
    LowNote: Byte;
    HighNote: Byte;
    LowVelocity: Byte;
    HighVelocity: Byte;
  end;

  TInstrumentChunk = class(TWavFixedDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    InstrumentRecord: TInstrumentRecord;
    constructor Create; override;
    class function GetClassChunkSize: Cardinal; override;
    class function GetClassChunkName: TChunkName; override;
    procedure SetNoteRange(Low, High: ShortInt);
    procedure SetVelocityRange(Low, High: Byte);

    property UnshiftedNote: Byte read InstrumentRecord.UnshiftedNote
      write InstrumentRecord.UnshiftedNote;
    property FineTune: ShortInt read InstrumentRecord.FineTune
      write InstrumentRecord.FineTune;
    property Gain_dB: ShortInt read InstrumentRecord.Gain_dB
      write InstrumentRecord.Gain_dB;
    property LowNote: Byte read InstrumentRecord.LowNote
      write InstrumentRecord.LowNote;
    property HighNote: Byte read InstrumentRecord.HighNote
      write InstrumentRecord.HighNote;
    property LowVelocity: Byte read InstrumentRecord.LowVelocity
      write InstrumentRecord.LowVelocity;
    property HighVelocity: Byte read InstrumentRecord.HighVelocity
      write InstrumentRecord.HighVelocity;
  end;

  TLevelChunkRecord = packed record
    dwVersion: Cardinal; // version information
    dwFormat: Cardinal; // format of a peak point
    dwPointsPerValue: Cardinal;
    dwBlockSize: Cardinal; // frames per value
    dwPeakChannels: Cardinal; // number of channels
    dwNumPeakFrames: Cardinal; // number of peak frames
    dwPosPeakOfPeaks: Cardinal;
    dwOffsetToPeaks: Cardinal;
    StrTimestamp: array [0 .. 27] of AnsiChar; // ASCII: time stamp of the peak data
    Reserved: array [0 .. 59] of AnsiChar; // reserved set to 0x00
  end;

  // chunk not yet created...
  // see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s3_tcm6-10483.pdf

  TBextRecord = packed record
    Description: array [0 .. 255] of AnsiChar;
    Originator: array [0 .. 31] of AnsiChar;
    OriginatorRef: array [0 .. 31] of AnsiChar;
    OriginationDate: array [0 .. 9] of AnsiChar;
    OriginationTime: array [0 .. 7] of AnsiChar;
    TimeRefLow: Integer;
    TimeRefHigh: Integer;
    Version: Word;
    UMID: array [0 .. 63] of Byte;
    Reserved: array [0 .. 189] of Byte;
  end;

  PBextRecord = ^TBextRecord;

  TCustomBextChunk = class(TWavFixedDefinedChunk)
  private
    function GetDescription: AnsiString;
    function GetOriginationDate: AnsiString;
    function GetOriginationTime: AnsiString;
    function GetOriginator: AnsiString;
    function GetOriginatorRef: AnsiString;
    procedure SetDescription(const Value: AnsiString);
    procedure SetOriginationDate(const Value: AnsiString);
    procedure SetOriginationTime(const Value: AnsiString);
    procedure SetOriginator(const Value: AnsiString);
    procedure SetOriginatorRef(const Value: AnsiString);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    BextRecord: TBextRecord;
    constructor Create; override;
    class function GetClassChunkSize: Cardinal; override;

    property Description: AnsiString read GetDescription write SetDescription;
    property Originator: AnsiString read GetOriginator write SetOriginator;
    property OriginatorRef: AnsiString read GetOriginatorRef write SetOriginatorRef;
    property OriginationDate: AnsiString read GetOriginationDate
      write SetOriginationDate;
    property OriginationTime: AnsiString read GetOriginationTime
      write SetOriginationTime;
    property TimeRefLow: Integer read BextRecord.TimeRefLow
      write BextRecord.TimeRefLow;
    property TimeRefHigh: Integer read BextRecord.TimeRefHigh
      write BextRecord.TimeRefHigh;
    property Version: Word read BextRecord.Version write BextRecord.Version;
  end;

  TBextChunk = class(TCustomBextChunk)
  public
    class function GetClassChunkName: TChunkName; override;

    property Description;
    property Originator;
    property OriginatorRef;
    property OriginationDate;
    property OriginationTime;
    property TimeRefLow;
    property TimeRefHigh;
    property Version;
  end;

  TBextChunkOld = class(TCustomBextChunk)
  public
    class function GetClassChunkName: TChunkName; override;
  end;

  TCartRecord = packed record
    Version: Integer;
    Title: array [0 .. 63] of AnsiChar;
    Artist: array [0 .. 63] of AnsiChar;
    CutID: array [0 .. 63] of AnsiChar;
    ClientID: array [0 .. 63] of AnsiChar;
    Category: array [0 .. 63] of AnsiChar;
    Classification: array [0 .. 63] of AnsiChar;
    OutCue: array [0 .. 63] of AnsiChar;
    StartDate: array [0 .. 9] of AnsiChar;
    StartTime: array [0 .. 7] of AnsiChar;
    EndDate: array [0 .. 9] of AnsiChar;
    EndTime: array [0 .. 7] of AnsiChar;
    ProducerAppID: array [0 .. 63] of AnsiChar;
    ProducerAppVersion: array [0 .. 63] of AnsiChar;
    UserDef: array [0 .. 63] of AnsiChar;
    dbLevelReference: Integer;
  end;

  PCartRecord = ^TCartRecord;

  TCartChunk = class(TWavFixedDefinedChunk)
  private
    function GetArtist: AnsiString;
    function GetCategory: AnsiString;
    function GetClassification: AnsiString;
    function GetClientID: AnsiString;
    function GetCutID: AnsiString;
    function GetEndDate: AnsiString;
    function GetEndTime: AnsiString;
    function GetOutCue: AnsiString;
    function GetProducerAppID: AnsiString;
    function GetProducerAppVersion: AnsiString;
    function GetStartDate: AnsiString;
    function GetStartTime: AnsiString;
    function GetTitle: AnsiString;
    function GetUserDef: AnsiString;
    procedure SetArtist(const Value: AnsiString);
    procedure SetCategory(const Value: AnsiString);
    procedure SetClassification(const Value: AnsiString);
    procedure SetClientID(const Value: AnsiString);
    procedure SetCutID(const Value: AnsiString);
    procedure SetEndDate(const Value: AnsiString);
    procedure SetEndTime(const Value: AnsiString);
    procedure SetOutCue(const Value: AnsiString);
    procedure SetProducerAppID(const Value: AnsiString);
    procedure SetProducerAppVersion(const Value: AnsiString);
    procedure SetStartDate(const Value: AnsiString);
    procedure SetStartTime(const Value: AnsiString);
    procedure SetTitle(const Value: AnsiString);
    procedure SetUserDef(const Value: AnsiString);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    CartRecord: TCartRecord;
    constructor Create; override;
    class function GetClassChunkSize: Cardinal; override;
    class function GetClassChunkName: TChunkName; override;

    property Version: Integer read CartRecord.Version write CartRecord.Version;
    property Title: AnsiString read GetTitle write SetTitle;
    property Artist: AnsiString read GetArtist write SetArtist;
    property CutID: AnsiString read GetCutID write SetCutID;
    property ClientID: AnsiString read GetClientID write SetClientID;
    property Category: AnsiString read GetCategory write SetCategory;
    property Classification: AnsiString read GetClassification
      write SetClassification;
    property OutCue: AnsiString read GetOutCue write SetOutCue;
    property StartDate: AnsiString read GetStartDate write SetStartDate;
    property StartTime: AnsiString read GetStartTime write SetStartTime;
    property EndDate: AnsiString read GetEndDate write SetEndDate;
    property EndTime: AnsiString read GetEndTime write SetEndTime;
    property ProducerAppID: AnsiString read GetProducerAppID write SetProducerAppID;
    property ProducerAppVersion: AnsiString read GetProducerAppVersion
      write SetProducerAppVersion;
    property UserDef: AnsiString read GetUserDef write SetUserDef;
    property dbLevelReference: Integer read CartRecord.dbLevelReference
      write CartRecord.dbLevelReference;
  end;

  TWavSDA8Chunk = class(TDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;
  end;

  TWavSDAChunk = class(TWavBinaryChunk)
  public
    class function GetClassChunkName: TChunkName; override;
  end;

  TWavAFspChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;
  published
    property Text: AnsiString read FText write FText;
  end;

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s4_tcm6-10484.pdf

  TBWFLinkChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;
  published
    property XMLData: AnsiString read FText write FText;
  end;

  // -> see: http://www.ebu.ch/CMSimages/en/tec_doc_t3285_s5_tcm6-10485.pdf

  TBwfAXMLChunk = class(TWavChunkText)
  public
    class function GetClassChunkName: TChunkName; override;
  published
    property XMLData: AnsiString read FText write FText;
  end;

  TWavDisplayChunk = class(TWavDefinedChunk)
  private
    FData   : AnsiString;
  protected
    FTypeID : Cardinal;
    procedure AssignTo(Dest: TPersistent); override;
  published
  public
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;
  published
    property TypeID: Cardinal read FTypeID write FTypeID;
    property Data: AnsiString read FData write FData;
  end;

  TPeakRecord = record
    Version   : Cardinal;
    TimeStamp : Cardinal;
  end;

  TWavPeakChunk = class(TWavDefinedChunk)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    Peak : TPeakRecord;
    constructor Create; override;
    class function GetClassChunkName: TChunkName; override;
    procedure LoadFromStream(Stream : TStream); override;
    procedure SaveToStream(Stream : TStream); override;
  end;

  EWavError = class(Exception);

  IAudioFileBitsPerSample = interface(IInterface)
    ['{1BB97B83-7F50-4BD7-9634-37F4399EA6FC}']
    procedure SetBitsPerSample(const Value: Byte);
    function GetBitsPerSample: Byte;

    property BitsPerSample: Byte read GetBitsPerSample write SetBitsPerSample;
  end;

  TCustomAudioFileContainer = class(TInterfacedPersistent)
  strict private
    constructor Create; overload; virtual; abstract;
  protected
    FOwnsStream: Boolean;
    FStream: TStream;
    function GetChannels: Cardinal; virtual; abstract;
    function GetSampleFrames: Cardinal; virtual; abstract;
    function GetSampleRate: Double; virtual; abstract;
    function GetTotalTime: Double; virtual;
    procedure SetChannels(const Value: Cardinal); virtual; abstract;
    procedure SetSampleFrames(const Value: Cardinal); virtual; abstract;
    procedure SetSampleRate(const Value: Double); virtual; abstract;
  protected
    procedure SetupHeader; virtual; abstract;
    procedure ReadHeader; virtual;
  public
    constructor Create(const FileName: TFileName); overload; virtual;
    constructor Create(const Stream: TStream); overload; virtual;
    destructor Destroy; override;

    procedure Flush; virtual;

    // file format identifier
    class function DefaultExtension: string; virtual; abstract;
    class function Description: string; virtual; abstract;
    class function FileFormatFilter: string; virtual; abstract;
    class function CanLoad(const FileName: TFileName): Boolean;
      overload; virtual;
    class function CanLoad(const Stream: TStream): Boolean; overload;
      virtual; abstract;

    property SampleRate: Double read GetSampleRate write SetSampleRate;
    property ChannelCount: Cardinal read GetChannels write SetChannels;
    property SampleFrames: Cardinal read GetSampleFrames;
    property TotalTime: Double read GetTotalTime; // = SampleFrames / SampleRate
  end;

  TAudioFileClass = class of TCustomAudioFileContainer;

  TCustomChunkedAudioFileContainer = class(TCustomAudioFileContainer)
  private
    class var FChunkClasses: array of TDefinedChunkClass;
    class function IsChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
  public
    class procedure RegisterChunk(AClass: TDefinedChunkClass);
    class procedure RegisterChunks(AClasses: array of TDefinedChunkClass);
    class function ChunkClassByName(Value: string): TDefinedChunkClass;
    class function ChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;
  end;

  TAudioFileContainerWAV = class(TCustomChunkedAudioFileContainer, IAudioFileBitsPerSample)
  private
    FChunkSize: Cardinal;
    FFormatChunk: TFormatChunk;
    FFactChunk: TFactChunk;
    FChunkList: TChunkList;
    FBytesPerSample: Integer;
    function GetEmptyData: Boolean;
    function GetSubChunk(Index: Integer): TCustomChunk;
    function GetSubChunkCount: Cardinal;
    function GetTypicalAudioDataPosition: Cardinal;
    function GetBextChunk: TBextChunk;
    function GetCartChunk: TCartChunk;
    procedure ReadFormatChunk;
    procedure ReadFactChunk;
  protected
    FDataPosition: Cardinal;
    FDataSize: Cardinal;
    constructor Create; override;

    function GetBitsPerSample: Byte; virtual;
    function GetChannels: Cardinal; override;
    function GetSampleRate: Double; override;
    function GetSampleFrames: Cardinal; override;

    procedure SetBitsPerSample(const Value: Byte); virtual;
    procedure SetChannels(const Value: Cardinal); override;
    procedure SetSampleRate(const Value: Double); override;
    procedure SetSampleFrames(const Value: Cardinal); override;

    procedure ReadDataChunk;
    procedure ReadUnknownChunk(const ChunkName: TChunkName);

    property EmptyData: Boolean read GetEmptyData;
    property TypicalAudioDataPosition: Cardinal
      read GetTypicalAudioDataPosition;

    procedure SetupHeader; override;
    procedure ReadHeader; override;
  public
    destructor Destroy; override;

    procedure WriteAudioData(Buffer: PByte; Size: Cardinal);
    function ReadAudioData(Buffer: PByte; Size: Cardinal): Cardinal; overload;
    function ReadAudioData(Buffer: PByte; Offset, Size: Cardinal): Cardinal; overload;

    procedure Flush; override;

    // sub chunks
    function AddSubChunk(SubChunkClass: TCustomChunkClass): TCustomChunk; overload; virtual;
    procedure AddSubChunk(SubChunk: TCustomChunk); overload; virtual;
    procedure DeleteSubChunk(SubChunk: TCustomChunk); overload; virtual;
    procedure DeleteSubChunk(const Index: Integer); overload; virtual;

    // file format identifier
    class function DefaultExtension: string; override;
    class function Description: string; override;
    class function FileFormatFilter: string; override;
    class function CanLoad(const Stream: TStream): Boolean; override;

    property BitsPerSample: Byte read GetBitsPerSample write SetBitsPerSample;
    property BytesPerSample: Integer read FBytesPerSample;
    property DataSize: Cardinal read FDataSize;
    property DataPosition: Cardinal read FDataPosition;

    // sub chunks
    property SubChunkCount: Cardinal read GetSubChunkCount;
    property SubChunk[Index: Integer]: TCustomChunk read GetSubChunk;

    property BextChunk: TBextChunk read GetBextChunk;
    property CartChunk: TCartChunk read GetCartChunk;
  end;

const
  CZeroPad: Integer = 0;

var
  GAudioFileFormats: array of TAudioFileClass;

function CompareChunkNames(ChunkNameA, ChunkNameB: TChunkName): Boolean;

procedure RegisterFileFormat(AClass: TAudioFileClass);
function ExtensionToFileFormat(Extension: string): TAudioFileClass;
function FileNameToFormat(FileName: TFileName): TAudioFileClass;
function StreamToFormat(Stream: TStream): TAudioFileClass;
function GetSimpleFileFilter: string;

implementation

uses
  Types;

resourcestring
  RCStrFileAlreadyLoaded = 'File already loaded';
  RCStrStreamInUse = 'Stream is already in use';
  RCStrNoStreamAssigned = 'No stream assigned';
  RCStrTooManySampleframes = 'Too many sampleframes!';
  RCRIFFChunkNotFound = 'This is not a RIFF file!';
  RCRIFFSizeMismatch = 'Filesize mismatch';
  RCWAVEChunkNotFound = 'This is not a WAVE file!';
  RCFMTChunkDublicate = 'More than one format chunk found!';
  RCFACTChunkDublicate = 'More than one fact chunk found!';
  RCDATAChunkDublicate = 'Only one data chunk supported!';
  RCStrIndexOutOfBounds = 'Index out of bounds (%d)';
  RCStrCantChangeTheFormat = 'Can''t change the format!';
  RCStrNoDataChunkFound = 'No data chunk found!';

{ Byte Ordering }

type
  T16Bit = record
    case Integer of
      0 :  (v: SmallInt);
      1 :  (b: array[0..1] of Byte);
  end;

  T32Bit = record
    case Integer of
      0 :  (v: LongInt);
      1 :  (b: array[0..3] of Byte);
  end;

  T64Bit = record
    case Integer of
      0 :  (v: Int64);
      1 :  (b: array[0..7] of Byte);
  end;

  T80Bit = record
    case Integer of
      0 :  (v: Extended);
      1 :  (b: array[0..9] of Byte);
  end;


procedure Flip16(var Value);
var
  t: Byte;
begin
 with T16Bit(Value) do
  begin
   t := b[0];
   b[0] := b[1];
   b[1] := t;
  end;
end;

procedure Flip32(var Value);
var
  Temp: Byte;
begin
 with T32Bit(Value) do
  begin
   Temp := b[0];
   b[0] := b[3];
   b[3] := Temp;
   Temp := b[1];
   b[1] := b[2];
   b[2] := Temp;
  end;
end;

procedure Flip64(var Value);
var
  Temp: Byte;
begin
 with T64Bit(Value) do
  begin
   Temp := b[0];
   b[0] := b[7];
   b[7] := Temp;
   Temp := b[1];
   b[1] := b[6];
   b[6] := Temp;
   Temp := b[2];
   b[2] := b[5];
   b[5] := Temp;
   Temp := b[3];
   b[3] := b[4];
   b[4] := Temp;
  end;
end;

procedure Flip80(var Value);
var
  Temp: Byte;
  T80B: T80Bit absolute Value;
begin
 with T80B do
  begin
   Temp := b[0];
   b[0] := b[9];
   b[9] := Temp;
   Temp := b[1];
   b[1] := b[8];
   b[8] := Temp;
   Temp := b[2];
   b[2] := b[7];
   b[7] := Temp;
   Temp := b[3];
   b[3] := b[6];
   b[6] := Temp;
   Temp := b[4];
   b[4] := b[5];
   b[5] := Temp;
  end;
end;

function Swap16(Value: Word): Word; {$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
{$IFDEF SUPPORTS_INLINE}
begin
  Result := Swap(Value);
{$ELSE}
{$IFDEF PUREPASCAL}
begin
  Result := Swap(Value);
{$ELSE}
asm
  {$IFDEF CPUx86_64}
  MOV     EAX, ECX
  {$ENDIF}
  XCHG    AL, AH
  {$ENDIF}
  {$ENDIF}
end;

function Swap32(Value: Cardinal): Cardinal;
{$IFDEF PUREPASCAL}
type
  TTwoWords = array [0..1] of Word;
begin
  TTwoWords(Result)[1] := Swap(TTwoWords(Value)[0]);
  TTwoWords(Result)[0] := Swap(TTwoWords(Value)[1]);
{$ELSE}
asm
  {$IFDEF CPUx86_64}
  MOV     EAX, ECX
  {$ENDIF}
  BSWAP   EAX
  {$ENDIF}
end;

function Swap64(Value: Int64): Int64;
type
  TFourWords = array [0..3] of Word;
begin
  TFourWords(Result)[3] := Swap(TFourWords(Value)[0]);
  TFourWords(Result)[2] := Swap(TFourWords(Value)[1]);
  TFourWords(Result)[1] := Swap(TFourWords(Value)[2]);
  TFourWords(Result)[0] := Swap(TFourWords(Value)[3]);
end;

function ReadSwappedWord(Stream: TStream): Word;
begin
{$IFDEF ValidateEveryReadOperation}
  if Stream.Read(Result, SizeOf(Word)) <> SizeOf(Word) then
    raise EPascalTypeStremReadError.Create(RCStrStreamReadError);
{$ELSE}
  Stream.Read(Result, SizeOf(Word));
{$ENDIF}
  Result := Swap16(Result);
end;

function ReadSwappedSmallInt(Stream: TStream): SmallInt;
begin
{$IFDEF ValidateEveryReadOperation}
  if Stream.Read(Result, SizeOf(SmallInt)) <> SizeOf(SmallInt) then
    raise EPascalTypeStremReadError.Create(RCStrStreamReadError);
{$ELSE}
  Stream.Read(Result, SizeOf(SmallInt));
{$ENDIF}
  Result := Swap16(Result);
end;

function ReadSwappedCardinal(Stream: TStream): Cardinal;
begin
{$IFDEF ValidateEveryReadOperation}
  Assert(SizeOf(Cardinal) = 4);
  if Stream.Read(Result, SizeOf(Cardinal)) <> SizeOf(Cardinal) then
    raise EPascalTypeStremReadError.Create(RCStrStreamReadError);
{$ELSE}
  Stream.Read(Result, SizeOf(Cardinal));
{$ENDIF}
  Result := Swap32(Result);
end;

function ReadSwappedInt64(Stream: TStream): Int64;
begin
{$IFDEF ValidateEveryReadOperation}
  if Stream.Read(Result, SizeOf(Int64)) <> SizeOf(Int64) then
    raise EPascalTypeStremReadError.Create(RCStrStreamReadError);
{$ELSE}
  Stream.Read(Result, SizeOf(Int64));
{$ENDIF}
  Result := Swap64(Result);
end;

procedure WriteSwappedWord(Stream: TStream; Value: Word);
begin
  Value := Swap16(Value);
  Stream.Write(Value, SizeOf(Word));
end;

procedure WriteSwappedSmallInt(Stream: TStream; Value: SmallInt);
begin
  Value := Swap16(Value);
  Stream.Write(Value, SizeOf(SmallInt));
end;

procedure WriteSwappedCardinal(Stream: TStream; Value: Cardinal);
begin
  Value := Swap32(Value);
  Stream.Write(Value, SizeOf(Cardinal));
end;

procedure WriteSwappedInt64(Stream: TStream; Value: Int64);
begin
  Value := Swap64(Value);
  Stream.Write(Value, SizeOf(Int64));
end;

procedure CopySwappedWord(Source: PWord; Destination: PWord; Size: Integer);
var
  Cnt: Integer;
begin
  for Cnt := 0 to Size - 1 do
  begin
    Destination^ := Swap16(Source^);
    Inc(Source);
    Inc(Destination);
  end;
end;

function CompareChunkNames(ChunkNameA, ChunkNameB: TChunkName): Boolean;
begin
  Result := False;
  if ChunkNameA[0] <> ChunkNameB[0] then
    Exit;
  if ChunkNameA[1] <> ChunkNameB[1] then
    Exit;
  if ChunkNameA[2] <> ChunkNameB[2] then
    Exit;
  if ChunkNameA[3] <> ChunkNameB[3] then
    Exit;
  Result := True;
end;

procedure RegisterFileFormat(AClass: TAudioFileClass);
var
  i: Integer;
begin
  // check if file format is already registered
  for i := 0 to Length(GAudioFileFormats) - 1 do
    if GAudioFileFormats[i] = AClass then
      exit;

  // add file format to list
  SetLength(GAudioFileFormats, Length(GAudioFileFormats) + 1);
  GAudioFileFormats[Length(GAudioFileFormats) - 1] := AClass;
end;

function ExtensionToFileFormat(Extension: string): TAudioFileClass;
var
  i: Integer;
begin
  Result := nil;
  Extension := LowerCase(Extension);
  for i := 0 to Length(GAudioFileFormats) - 1 do
    if GAudioFileFormats[i].DefaultExtension = Extension then
      Result := GAudioFileFormats[i];
end;

function FileNameToFormat(FileName: TFileName): TAudioFileClass;
var
  i: Integer;
begin
  Result := nil;
  if not FileExists(FileName) then
  begin
    Result := ExtensionToFileFormat(LowerCase(ExtractFileExt(FileName)));
    exit;
  end;

  for i := 0 to Length(GAudioFileFormats) - 1 do
    if GAudioFileFormats[i].CanLoad(FileName) then
      Result := GAudioFileFormats[i];
end;

function StreamToFormat(Stream: TStream): TAudioFileClass;
var
  Index: Integer;
begin
  Result := nil;
  if not Assigned(Stream) then
    exit;

  for Index := 0 to Length(GAudioFileFormats) - 1 do
    if GAudioFileFormats[Index].CanLoad(Stream) then
      Result := GAudioFileFormats[Index];
end;

function GetSimpleFileFilter: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Length(GAudioFileFormats) - 1 do
    with GAudioFileFormats[i] do
      Result := Result + Description + ' (*' + DefaultExtension + ') |*' +
        DefaultExtension + '|';

  // remove last separator
  if Result <> '' then
    SetLength(Result, Length(Result) - 1);
end;


{ TCustomChunk }

function TCustomChunk.CalculateZeroPad: Integer;
begin
  Result := (2 - (FChunkSize and 1)) and 1;
end;

procedure TCustomChunk.CheckAddZeroPad(Stream: TStream);
begin
  // insert pad byte if necessary
  if cfPadSize in ChunkFlags then
    Stream.Write(CZeroPad, CalculateZeroPad);
end;

constructor TCustomChunk.Create;
begin
  FChunkName := '';
  FChunkSize := 0;
end;

procedure TCustomChunk.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomChunk then
  begin
    TCustomChunk(Dest).FChunkName := FChunkName;
    TCustomChunk(Dest).FChunkSize := FChunkSize;
  end
  else
    inherited;
end;

function TCustomChunk.GetChunkNameAsString: AnsiString;
begin
  Result := AnsiString(FChunkName);
end;

function TCustomChunk.GetChunkSize: Cardinal;
begin
  Result := FChunkSize;
end;

procedure TCustomChunk.LoadFromFile(FileName: TFileName);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead);
  with FileStream do
    try
      LoadFromStream(FileStream);
    finally
      Free;
    end;
end;

procedure TCustomChunk.SaveToFile(FileName: TFileName);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  with FileStream do
    try
      SaveToStream(FileStream);
    finally
      Free;
    end;
end;

procedure TCustomChunk.LoadFromStream(Stream: TStream);
begin
  with Stream do
  begin
    Assert(Position <= Size + 8);
    if cfSizeFirst in ChunkFlags then
    begin
      // order known from PNG
      Read(FChunkSize, 4);
      Read(FChunkName, 4);
    end
    else
    begin
      // order known from WAVE, AIFF, etc.
      Read(FChunkName, 4);
      Read(FChunkSize, 4);
    end;
  end;

  // eventually flip bytes
  if cfReversedByteOrder in ChunkFlags then
    Flip32(FChunkSize);

  // eventually exclude header
  if cfIncludeChunkInSize in ChunkFlags then
    FChunkSize := FChunkSize - 8;
end;

procedure TCustomChunk.SaveToStream(Stream: TStream);
var
  TempSize: Cardinal;
begin
  // calculate chunk size before save
  FChunkSize := GetChunkSize;
  TempSize := FChunkSize;

  // eventually include header
  if cfIncludeChunkInSize in ChunkFlags then
    TempSize := TempSize + 8;

  // eventually flip bytes
  if cfReversedByteOrder in ChunkFlags then
    Flip32(TempSize);

  with Stream do
    if cfSizeFirst in ChunkFlags then
    begin
      // order known from PNG, MPEG
      Write(TempSize, 4);
      Write(FChunkName[0], 4);
    end
    else
    begin
      // order known from WAVE, AIFF, etc.
      Write(FChunkName[0], 4);
      Write(TempSize, 4);
    end;
end;

procedure TCustomChunk.SetChunkNameAsString(const Value: AnsiString);
var
  ChunkNameSize: Integer;
begin
  ChunkNameSize := Length(Value);
  if ChunkNameSize > 3 then
    ChunkNameSize := 4;
  Move(Value[1], FChunkName[0], ChunkNameSize);
end;


{ TDummyChunk }

procedure TDummyChunk.LoadFromStream(Stream: TStream);
begin
  with Stream do
  begin
    inherited;
    Position := Position + FChunkSize;
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;


{ TUnknownChunk }

function TUnknownChunk.CalculateChecksum: Integer;
var
  b: Byte;
begin
  with FDataStream do
  begin
    Position := 0;
    Result := 0;
    while Position < Size do
    begin
      Read(b, 1);
      Result := Result + b;
    end;
  end;
end;

constructor TUnknownChunk.Create;
begin
  inherited;
  FDataStream := TMemoryStream.Create;
end;

destructor TUnknownChunk.Destroy;
begin
  FreeAndNil(FDataStream);
  inherited;
end;

procedure TUnknownChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TUnknownChunk then
  begin
    TUnknownChunk(Dest).FDataStream.CopyFrom(FDataStream, FDataStream.Size);
  end;
end;

function TUnknownChunk.GetData(Index: Integer): Byte;
begin
  if (Index >= 0) and (Index < FDataStream.Size) then
    with FDataStream do
    begin
      Position := Index;
      Read(Result, 1);
    end
  else
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);
end;

procedure TUnknownChunk.LoadFromStream(Stream: TStream);
begin
  with Stream do
  begin
    inherited;
    Assert(FChunkSize <= Size);
    Assert(FChunkName <> #0#0#0#0);
    FDataStream.Clear;
    FDataStream.Size := FChunkSize;
    FDataStream.Position := 0;
    if FChunkSize > 0 then
      FDataStream.CopyFrom(Stream, FChunkSize);

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TUnknownChunk.SaveToStream(Stream: TStream);
begin
  with Stream do
  begin
    FChunkSize := FDataStream.Size; // Length(FData);
    inherited;
    FDataStream.Position := 0;
    CopyFrom(FDataStream, FDataStream.Position);

    // check and eventually add zero pad
    CheckAddZeroPad(Stream);
  end;
end;

procedure TUnknownChunk.SetData(Index: Integer; const Value: Byte);
begin
  if (Index >= 0) and (Index < FDataStream.Size) then
    with FDataStream do
    begin
      Position := Index;
      Write(Value, 1);
    end
  else
    raise Exception.CreateFmt('Index out of bounds (%d)', [Index]);
end;


{ TDefinedChunk }

constructor TDefinedChunk.Create;
begin
  inherited;
  FFilePosition := 0;
  FChunkName := GetClassChunkName;
end;

procedure TDefinedChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TDefinedChunk then
    TDefinedChunk(Dest).FFilePosition := FFilePosition;
end;

procedure TDefinedChunk.LoadFromStream(Stream: TStream);
var
  TempChunkName: TChunkName;
begin
  with Stream do
  begin
    if cfSizeFirst in ChunkFlags then
    begin
      // Assume chunk name fits the defined one
      Position := Position + 4;
      Read(TempChunkName, 4);
      Assert(TempChunkName = FChunkName);
      Position := Position - 8;
    end
    else
    begin
      // Assume chunk name fits the defined one
      Read(TempChunkName, 4);
      Assert(TempChunkName = FChunkName);
      Position := Position - 4;
    end;
    inherited;
  end;
end;

procedure TDefinedChunk.SetChunkNameAsString(const Value: AnsiString);
begin
  inherited;
  if Value <> FChunkName then
    raise Exception.Create('Chunk name must always be ''' +
      string(AnsiString(FChunkName)) + '''');
end;


{ TFixedDefinedChunk }

constructor TFixedDefinedChunk.Create;
begin
  inherited;
  SetLength(FStartAddresses, 1);
  FChunkSize := GetClassChunkSize;
end;

procedure TFixedDefinedChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TFixedDefinedChunk then
  begin
    SetLength(TFixedDefinedChunk(Dest).FStartAddresses,
      Length(FStartAddresses));
    Move(FStartAddresses[0], TFixedDefinedChunk(Dest).FStartAddresses[0],
      Length(FStartAddresses) * SizeOf(Pointer));
  end;
end;

function TFixedDefinedChunk.GetChunkSize: Cardinal;
begin
  Result := GetClassChunkSize;
end;

function TFixedDefinedChunk.GetStartAddress: Pointer;
begin
  Result := FStartAddresses[0];
end;

procedure TFixedDefinedChunk.SetStartAddress(const Value: Pointer);
begin
  FStartAddresses[0] := Value;
end;

procedure TFixedDefinedChunk.LoadFromStream(Stream: TStream);
var
  BytesReaded: Cardinal;
begin
  inherited;

  with Stream do
  begin
    if FChunkSize <= Cardinal(GetClassChunkSize) then
      Read(FStartAddresses[0]^, FChunkSize)
    else
    begin
      BytesReaded := Read(FStartAddresses[0]^, GetClassChunkSize);
      Assert(BytesReaded = GetClassChunkSize);
      Position := Position + FChunkSize - GetClassChunkSize;
    end;
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TFixedDefinedChunk.SaveToStream(Stream: TStream);
var
  BytesWritten: Cardinal;
begin
  FChunkSize := GetClassChunkSize;
  inherited;
  try
    BytesWritten := Stream.Write(FStartAddresses[0]^, GetClassChunkSize);
    Assert(BytesWritten = FChunkSize);

    // check and eventually add zero pad
    CheckAddZeroPad(Stream);
  except
    raise Exception.Create('Wrong Start Address of Chunk: ' + string(ChunkName));
  end;
end;


{ TChunkList }

function TChunkList.Add(AChunk: TCustomChunk): Integer;
begin
  Result := inherited Add(TObject(AChunk));
end;

function TChunkList.Extract(Item: TCustomChunk): TCustomChunk;
begin
  Result := TCustomChunk(inherited Extract(TObject(Item)));
end;

function TChunkList.First: TCustomChunk;
begin
  Result := TCustomChunk(inherited First);
end;

function TChunkList.GetItem(Index: Integer): TCustomChunk;
begin
  Result := TCustomChunk(inherited GetItem(Index));
end;

function TChunkList.IndexOf(AChunk: TCustomChunk): Integer;
begin
  Result := inherited IndexOf(TObject(AChunk));
end;

procedure TChunkList.Insert(Index: Integer; AChunk: TCustomChunk);
begin
  inherited Insert(Index, TObject(AChunk));
end;

function TChunkList.Last: TCustomChunk;
begin
  Result := TCustomChunk(inherited Last);
end;

function TChunkList.Remove(AChunk: TCustomChunk): Integer;
begin
  Result := inherited Remove(TObject(AChunk));
end;

procedure TChunkList.SetItem(Index: Integer; AChunk: TCustomChunk);
begin
  inherited SetItem(Index, TObject(AChunk));
end;


{ TCustomChunkContainer }

constructor TCustomChunkContainer.Create;
begin
  inherited;
  FChunkList := TChunkList.Create;
end;

destructor TCustomChunkContainer.Destroy;
begin
  FreeAndNil(FChunkList);
  inherited;
end;

procedure TCustomChunkContainer.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomChunkContainer then
    TCustomChunkContainer(Dest).FChunkList.Assign(FChunkList);
end;

procedure TCustomChunkContainer.AddChunk(Chunk: TCustomChunk);
begin
  FChunkList.Add(Chunk);
end;

function TCustomChunkContainer.GetCount: Integer;
begin
  Result := FChunkList.Count;
end;

function TCustomChunkContainer.GetSubChunk(Index: Integer): TCustomChunk;
begin
  if (Index >= 0) and (Index < FChunkList.Count) then
    Result := FChunkList[Index]
  else
    Result := nil;
end;

procedure TCustomChunkContainer.LoadFromStream(Stream: TStream);
var
  ChunkEnd: Integer;
  ChunkName: TChunkName;
begin
  inherited;
  with Stream do
  begin
    ChunkEnd := Position + FChunkSize;
    Assert(ChunkEnd <= Stream.Size);
    while Position < ChunkEnd do
    begin
      if cfSizeFirst in ChunkFlags then
      begin
        Position := Position + 4;
        Read(ChunkName, 4);
        Position := Position - 8;
      end
      else
      begin
        Read(ChunkName, 4);
        Position := Position - 4;
      end;
      ConvertStreamToChunk(GetChunkClass(ChunkName), Stream);
    end;
    if Position <> ChunkEnd then
      Position := ChunkEnd;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCustomChunkContainer.ConvertStreamToChunk
  (ChunkClass: TCustomChunkClass; Stream: TStream);
var
  Chunk: TCustomChunk;
begin
  Chunk := ChunkClass.Create;
  Chunk.ChunkFlags := ChunkFlags;
  Chunk.LoadFromStream(Stream);
  AddChunk(Chunk);
end;

function TCustomChunkContainer.GetChunkSize: Cardinal;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FChunkList.Count - 1 do
    Inc(Result, FChunkList[i].ChunkSize + 8); // Chunk Size + Chunk Frame (8)
end;

procedure TCustomChunkContainer.SaveToStream(Stream: TStream);
var
  i: Integer;
begin
  FChunkSize := GetChunkSize;
  inherited;
  for i := 0 to FChunkList.Count - 1 do
    FChunkList[i].SaveToStream(Stream);

  // insert pad byte if necessary
  if cfPadSize in ChunkFlags then
    Stream.Write(CZeroPad, CalculateZeroPad);
end;


{ TChunkContainer }

procedure TChunkContainer.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TChunkContainer then
  begin
    SetLength(TChunkContainer(Dest).FRegisteredChunks,
      Length(FRegisteredChunks));
    Move(FRegisteredChunks, TChunkContainer(Dest).FRegisteredChunks,
      Length(FRegisteredChunks) * SizeOf(TCustomChunkClass));
  end;
end;

function TChunkContainer.GetChunkClass(ChunkName: TChunkName)
  : TCustomChunkClass;
var
  Index: Integer;
begin
  Result := TUnknownChunk;
  for Index := 0 to Length(FRegisteredChunks) - 1 do
    if CompareChunkNames(FRegisteredChunks[Index].GetClassChunkName, ChunkName)
    then
    begin
      Result := FRegisteredChunks[Index];
      Exit;
    end;
end;

procedure TChunkContainer.RegisterChunkClass(ChunkClass: TDefinedChunkClass);
var
  i: Integer;
begin
  // Check if the chunk class is already in the list
  for i := 0 to Length(FRegisteredChunks) - 1 do
    if FRegisteredChunks[i] = ChunkClass then
      Exit;

  // If not, add chunk class to the list
  SetLength(FRegisteredChunks, Length(FRegisteredChunks) + 1);
  FRegisteredChunks[Length(FRegisteredChunks) - 1] := ChunkClass;
end;

procedure TChunkContainer.RegisterChunkClasses(ChunkClasses
  : array of TDefinedChunkClass);
var
  i: Integer;
begin
  for i := 0 to Length(ChunkClasses) - 1 do
    RegisterChunkClass(ChunkClasses[i]);
end;

procedure TChunkContainer.RegisterChunkClasses;
var
  i: Integer;
begin
  for i := 0 to FChunkList.Count - 1 do
    RegisterChunkClass(TDefinedChunkClass(FChunkList[i].ClassType));
end;


{ TChunkedFile }

class function TChunkedFile.ChunkClassByName(Value: string): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := Length(FChunkClasses) - 1 downto 0 do
  begin
    if FChunkClasses[X].ClassName = Value then
    begin
      Result := FChunkClasses[X];
      Break;
    end;
  end;
end;

class function TChunkedFile.ChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := 0 to Length(FChunkClasses) - 1 do
    if CompareChunkNames(FChunkClasses[X].GetClassChunkName, Value) then
    begin
      Result := FChunkClasses[X];
      Break;
    end;
end;

class function TChunkedFile.IsChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
var
  X: Integer;
begin
  Result := False;
  for X := Length(FChunkClasses) - 1 downto 0 do
  begin
    if FChunkClasses[X] = AClass then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class procedure TChunkedFile.RegisterChunk(AClass: TDefinedChunkClass);
begin
  Classes.RegisterClass(AClass);
  Assert(not IsChunkClassRegistered(AClass));
  SetLength(FChunkClasses, Length(FChunkClasses) + 1);
  FChunkClasses[Length(FChunkClasses) - 1] := AClass;
end;

class procedure TChunkedFile.RegisterChunks(AClasses: array of TDefinedChunkClass);
var
  i: Integer;
begin
  for i := 0 to Length(AClasses) - 1 do
    RegisterChunk(AClasses[i]);
end;


{ TUnknownChunkContainer }

constructor TUnknownChunkContainer.Create;
begin
  inherited;
  FChunkList := TChunkList.Create;
end;

destructor TUnknownChunkContainer.Destroy;
begin
  FreeAndNil(FChunkList);
  inherited;
end;

function TUnknownChunkContainer.ConvertStreamToChunk
  (ChunkClass: TCustomChunkClass; Stream: TStream): TCustomChunk;
begin
  Result := ChunkClass.Create;
  Result.ChunkFlags := ChunkFlags;
  Result.LoadFromStream(Stream);
  FChunkList.Add(Result);
end;

function TUnknownChunkContainer.CheckForSubchunks: Boolean;
var
  TempSize: Cardinal;
  TempName: TChunkName;
begin
  Result := False;
  if (ChunkName = 'RIFF') or (ChunkName = 'FORM') or (ChunkName = 'MTrk') then
    FDataStream.Position := 4
  else
    FDataStream.Position := 0;
  while FDataStream.Position + 8 < FChunkSize do
  begin
    if cfSizeFirst in ChunkFlags then
    begin
      // read chunk size
      FDataStream.Read(TempSize, 4);

      // read chunk name
      FDataStream.Read(TempName, 4);
    end
    else
    begin
      // read chunk name
      FDataStream.Read(TempName, 4);

      // read chunk size
      FDataStream.Read(TempSize, 4);
    end;

    // eventually reverse byte order
    if cfReversedByteOrder in ChunkFlags then
      Flip32(TempSize);

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      TempSize := TempSize + (2 - (TempSize and 1)) and 1;

    if (FDataStream.Position + TempSize) <= FChunkSize then
    begin
      FDataStream.Position := FDataStream.Position + TempSize;
      Result := FDataStream.Position = FChunkSize;
      if Result then
        break;
    end
    else
      Exit;
  end;
end;

procedure TUnknownChunkContainer.LoadFromStream(Stream: TStream);
begin
  inherited;

  if CheckForSubchunks then
  begin
    if (ChunkName = 'RIFF') or (ChunkName = 'FORM') then
      FDataStream.Position := 4
    else
      FDataStream.Position := 0;
    while FDataStream.Position + 8 < FChunkSize do
      ConvertStreamToChunk(TUnknownChunkContainer, FDataStream);
  end;
end;

procedure TUnknownChunkContainer.SaveToStream(Stream: TStream);
var
  i: Integer;
begin
  FChunkSize := GetChunkSize;
  inherited;
  for i := 0 to FChunkList.Count - 1 do
    FChunkList[i].SaveToStream(Stream);

  // insert pad byte if necessary
  if cfPadSize in ChunkFlags then
    Stream.Write(CZeroPad, CalculateZeroPad);
end;

function TUnknownChunkContainer.GetChunkSize: Cardinal;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FChunkList.Count - 1 do
    Inc(Result, FChunkList[i].ChunkSize + 8); // Chunk Size + Chunk Frame (8)
end;

function TUnknownChunkContainer.GetCount: Integer;
begin
  Result := FChunkList.Count;
end;

function TUnknownChunkContainer.GetSubChunk(Index: Integer): TCustomChunk;
begin
  if (Index >= 0) and (Index < FChunkList.Count) then
    Result := FChunkList[Index]
  else
    Result := nil;
end;


{ TCustomBinaryChunk }

procedure TCustomBinaryChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomBinaryChunk then
  begin
    SetLength(TCustomBinaryChunk(Dest).FBinaryData, Length(FBinaryData));
    Move(FBinaryData, TCustomBinaryChunk(Dest).FBinaryData,
      SizeOf(FBinaryData));
  end;
end;

procedure TCustomBinaryChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  SetLength(FBinaryData, FChunkSize);
  Stream.Read(FBinaryData[0], Length(FBinaryData));
end;

procedure TCustomBinaryChunk.SaveToStream(Stream: TStream);
begin
  FChunkSize := Length(FBinaryData);
  inherited;
  Stream.Write(FBinaryData[0], FChunkSize);
end;


{ TCustomTextChunk }

procedure TCustomTextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomTextChunk then
  begin
    TCustomTextChunk(Dest).FText := FText;
  end;
end;

procedure TCustomTextChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  SetLength(FText, FChunkSize);
  Stream.Read(FText[1], Length(FText));

  // eventually skip padded zeroes
  if cfPadSize in ChunkFlags then
    Stream.Position := Stream.Position + CalculateZeroPad;
end;

procedure TCustomTextChunk.SaveToStream(Stream: TStream);
begin
  FChunkSize := Length(FText);

  inherited;
  Stream.Write(FText[1], FChunkSize);

  // eventually skip padded zeroes
  if (cfPadSize in ChunkFlags) then
    Stream.Position := Stream.Position + CalculateZeroPad;
end;

procedure TCustomTextChunk.SetText(const Value: AnsiString);
begin
  if FText <> Value then
  begin
    FText := Value;
    FChunkSize := Length(FText);
  end;
end;


{ TCustomStreamChunk }

procedure TCustomStreamChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomStreamChunk then
  begin
    FStream.Position := 0;
    TCustomStreamChunk(Dest).FStream.Position := 0;
    TCustomStreamChunk(Dest).FStream.CopyFrom(FStream, FStream.Size);
  end;
end;

destructor TCustomStreamChunk.Destroy;
begin
  FreeAndNil(FStream);
  inherited;
end;

function TCustomStreamChunk.GetChunkSize: Cardinal;
begin
  FChunkSize := FStream.Size;
  Result := inherited GetChunkSize;
end;

procedure TCustomStreamChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  FStream.Position := 0;
  FStream.CopyFrom(Stream, FChunkSize);
  FStream.Position := 0;

  // eventually skip padded zeroes
  if cfPadSize in ChunkFlags then
    Stream.Position := Stream.Position + CalculateZeroPad;
end;

procedure TCustomStreamChunk.SaveToStream(Stream: TStream);
begin
  FChunkSize := FStream.Size;
  inherited;
  FStream.Position := 0;
  Stream.CopyFrom(FStream, FStream.Size);

  // eventually skip padded zeroes
  if (cfPadSize in ChunkFlags) then
    Stream.Position := Stream.Position + CalculateZeroPad;
end;


{ TCustomMemoryStreamChunk }

constructor TCustomMemoryStreamChunk.Create;
begin
  inherited;
  FStream := TMemoryStream.Create;
end;

function TCustomMemoryStreamChunk.GetMemoryStream: TMemoryStream;
begin
  Result := TMemoryStream(FStream);
end;

{ TWavDefinedChunk }

constructor TWavDefinedChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;


{ TWavFixedDefinedChunk }

constructor TWavFixedDefinedChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;


{ TWavChunkText }

constructor TWavChunkText.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;


{ TWavBinaryChunk }

constructor TWavBinaryChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;


{ TWavUnknownChunk }

constructor TWavUnknownChunk.Create;
begin
  inherited;
  ChunkFlags := ChunkFlags + [cfPadSize];
end;


{ TFormatChunk }

constructor TFormatChunk.Create;
begin
  inherited;
  with FWaveFormatRecord do
  begin
    FormatTag := 1; // PCM encoding by default
    Channels := 1; // one channel
    SampleRate := 44100; // 44.1 kHz
    BitsPerSample := 24; // 24bit
    BlockAlign := (BitsPerSample + 7) div 8 * Channels;
    BytesPerSecond := Channels * BlockAlign * SampleRate;
  end;
  SetLength(FFormatSpecific, 0);
end;

destructor TFormatChunk.Destroy;
begin
  Dispose(FFormatExtensible);
  inherited;
end;

procedure TFormatChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TFormatChunk then
  begin
    TFormatChunk(Dest).FWaveFormatRecord := FWaveFormatRecord;
    SetLength(TFormatChunk(Dest).FFormatSpecific, Length(FFormatSpecific));
    Move(FFormatSpecific[0], TFormatChunk(Dest).FFormatSpecific[0],
      Length(FFormatSpecific));
  end;
end;

procedure TFormatChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(TWavFormatRecord);
  if FWaveFormatRecord.FormatTag <> 1 then
    FChunkSize := FChunkSize + SizeOf(Word) + Cardinal(Length(FFormatSpecific));
end;

procedure TFormatChunk.LoadFromStream(Stream: TStream);
var
  FormatSpecificBytes: Word;
begin
  inherited;
  with Stream do
  begin
    // make sure the chunk size is at least the header size
    Assert(FChunkSize >= SizeOf(TWavFormatRecord));
    Read(FWaveFormatRecord, SizeOf(TWavFormatRecord));

    // check whether format specific data can be found:
    if FChunkSize <= SizeOf(TWavFormatRecord) then
      Exit;
    Read(FormatSpecificBytes, SizeOf(Word));

    // read format specific bytes
    Assert(FChunkSize >= SizeOf(TWavFormatRecord) + SizeOf(Word) +
      FormatSpecificBytes);

    // check format extensible
    if FWaveFormatRecord.FormatTag = $FFFE then
    begin
      // check length
      if FormatSpecificBytes < SizeOf(TWavFormatChunkExtensible) then
        raise Exception.Create('Extensible format chunk size too small');

      // allocate memory for the extensible format
      ReallocMem(FFormatExtensible, FormatSpecificBytes);

      // read format extensible part
      Read(FFormatExtensible^, FormatSpecificBytes);
    end
    else
    begin
      // assign general format specific data
      SetLength(FFormatSpecific, FormatSpecificBytes);
      Read(FFormatSpecific[0], FormatSpecificBytes);
    end;

    // Move position to the end of this chunk
    Position := Position + FChunkSize - SizeOf(TWavFormatRecord) - SizeOf(Word)
      - FormatSpecificBytes;
  end;
end;

procedure TFormatChunk.SaveToStream(Stream: TStream);
var
  FormatSpecificBytes: Word;
begin
  CalculateChunkSize;
  inherited;
  with Stream do
  begin
    // write header
    Write(FWaveFormatRecord, SizeOf(TWavFormatRecord));

    // write format specific bytes
    if FWaveFormatRecord.FormatTag <> 1 then
    begin
      FormatSpecificBytes := Length(FFormatSpecific);
      Write(FormatSpecificBytes, SizeOf(Word));
      if FormatSpecificBytes > 0 then
        Write(FFormatSpecific[0], FormatSpecificBytes);
    end;
  end;
end;

function TFormatChunk.GetChunkSize: Cardinal;
begin
  CalculateChunkSize;
  Result := FChunkSize;
end;

class function TFormatChunk.GetClassChunkName: TChunkName;
begin
  Result := 'fmt ';
end;

function TFormatChunk.GetFormatTag: TWavEncoding;
begin
  // check if extensible format
  if (FWaveFormatRecord.FormatTag <> $FFFE) or not Assigned(FFormatExtensible)
  then
    Result := TWavEncoding(FWaveFormatRecord.FormatTag)
  else
    Move(FFormatExtensible^.GUID, Result, SizeOf(Word));
end;

function TFormatChunk.GetValidBitsPerSample: Word;
begin
  if (Length(FFormatSpecific) >= 2) and (FWaveFormatRecord.FormatTag = $FFFE)
  then
    Move(FFormatSpecific[0], Result, SizeOf(Word))
  else
    Result := FWaveFormatRecord.BitsPerSample;
end;

procedure TFormatChunk.SetBitsPerSample(const Value: Word);
begin
  if FWaveFormatRecord.BitsPerSample <> Value then
  begin
    if Value < 2 then
      raise Exception.Create('Value must be greater then 1!');
    FWaveFormatRecord.BitsPerSample := Value;
  end;
end;

procedure TFormatChunk.SetBlockAlign(const Value: Word);
begin
  if FWaveFormatRecord.BlockAlign <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.BlockAlign := Value;
  end;
end;

procedure TFormatChunk.SetBytesPerSecond(const Value: Cardinal);
begin
  if FWaveFormatRecord.BytesPerSecond <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.BytesPerSecond := Value;
  end;
end;

procedure TFormatChunk.SetChannels(const Value: Word);
begin
  if FWaveFormatRecord.Channels <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.Channels := Value;
  end;
end;

procedure TFormatChunk.SetFormatTag(const Value: TWavEncoding);
begin
  // ensure that the extensible format is used correctly
  if Assigned(FFormatExtensible) then
  begin
    // Move current format tag to extensible format tag
    Move(Value, FFormatExtensible.GUID, SizeOf(Word));
  end
  else
  begin
    if Value = etExtensible then
    begin
      // allocate memory for extensible format
      ReallocMem(FFormatExtensible, SizeOf(TWavFormatChunkExtensible));

      // Move current format tag to extensible format tag
      Move(FWaveFormatRecord.FormatTag, FFormatExtensible.GUID, SizeOf(Word));
    end;
    FWaveFormatRecord.FormatTag := Word(Value);
  end;
end;

procedure TFormatChunk.SetSampleRate(const Value: Cardinal);
begin
  if FWaveFormatRecord.SampleRate <> Value then
  begin
    if Value < 1 then
      raise Exception.Create('Value must be greater then 0!');
    FWaveFormatRecord.SampleRate := Value;
  end;
end;


{ TFactChunk }

constructor TFactChunk.Create;
begin
  inherited;
  StartAddress := @FactRecord;
end;

procedure TFactChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TFactChunk then
    TFactChunk(Dest).FactRecord := FactRecord;
end;

class function TFactChunk.GetClassChunkName: TChunkName;
begin
  Result := 'fact';
end;

class function TFactChunk.GetClassChunkSize: Cardinal;
begin
  Result := SizeOf(TFactRecord);
end;


{ TInfoSoftwareNameChunk }

class function TInfoSoftwareNameChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ISFT';
end;


{ TInfoCommnetChunk }

class function TInfoCommentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICMT';
end;


{ TInfoCreationDateChunk }

class function TInfoCreationDateChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICRD';
end;


{ TInfoCopyrightChunk }

class function TInfoCopyrightChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ICOP';
end;


{ TInfoSubjectChunk }

class function TInfoSubjectChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ISBJ';
end;


{ TInfoTitleChunk }

class function TInfoTitleChunk.GetClassChunkName: TChunkName;
begin
  Result := 'INAM';
end;


{ TInfoArtistChunk }

class function TInfoArtistChunk.GetClassChunkName: TChunkName;
begin
  Result := 'IART';
end;


{ TQualityChunk }

class function TQualityChunk.GetClassChunkName: TChunkName;
begin
  Result := 'qlty';
end;


{ TSilentChunk }

constructor TSilentChunk.Create;
begin
  inherited;
  StartAddress := @SilentRecord;
end;

procedure TSilentChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSilentChunk then
    TSilentChunk(Dest).SilentRecord := SilentRecord;
end;

class function TSilentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'slnt';
end;

class function TSilentChunk.GetClassChunkSize: Cardinal;
begin
  Result := SizeOf(TSilentRecord);
end;


{ TCustomPaddingChunk }

procedure TCustomPaddingChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  with Stream do
  begin
    // advance position
    Position := Position + FChunkSize;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;


{ TJunkChunk }

constructor TJunkChunk.Create;
begin
  inherited;
  FPadding := 16;
end;

procedure TJunkChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TJunkChunk then
    TJunkChunk(Dest).Padding := Padding;
end;

class function TJunkChunk.GetClassChunkName: TChunkName;
begin
  Result := 'junk';
end;

procedure TJunkChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  FChunkSize := FPadding;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
    Position := Position + FChunkSize;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;


{ TPadChunk }

constructor TPadChunk.Create;
begin
  inherited;
  FAlignSize := 2048;
end;

procedure TPadChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomPaddingChunk then
  begin
    TPadChunk(Dest).FAlignSize := FAlignSize;
  end;
end;

class function TPadChunk.GetClassChunkName: TChunkName;
begin
  Result := 'PAD ';
end;

procedure TPadChunk.LoadFromStream(Stream: TStream);
begin
  inherited;
  // set align size
  // FAlignSize :=
end;

procedure TPadChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  with Stream do
    FChunkSize := ((Position + FAlignSize) div FAlignSize) * FAlignSize
      - Position;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
    Position := Position + FChunkSize;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;


{ TCustomWavCuedTextChunk }

procedure TCustomWavCuedTextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomWavCuedTextChunk then
  begin
    TCustomWavCuedTextChunk(Dest).FText := FText;
    TCustomWavCuedTextChunk(Dest).FCueID := FCueID;
  end;
end;

procedure TCustomWavCuedTextChunk.LoadFromStream(Stream: TStream);
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    SetLength(FText, FChunkSize - SizeOf(Cardinal));
    Read(FCueID, SizeOf(Cardinal));
    Read(FText[1], Length(FText));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCustomWavCuedTextChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(FCueID, SizeOf(Cardinal));
    Write(FText[1], Length(FText));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TCustomWavCuedTextChunk.SetText(const Value: string);
begin
  FText := Value;
  CalculateChunkSize;
end;

procedure TCustomWavCuedTextChunk.CalculateChunkSize;
begin
  FChunkSize := Length(FText) + SizeOf(Cardinal);
end;


{ TLabelChunk }

class function TLabelChunk.GetClassChunkName: TChunkName;
begin
  Result := 'labl';
end;


{ TNoteChunk }

class function TNoteChunk.GetClassChunkName: TChunkName;
begin
  Result := 'note';
end;


{ TLabeledTextChunk }

procedure TLabeledTextChunk.CalculateChunkSize;
begin
  FChunkSize := Length(FText) + SizeOf(TLabeledTextRecord);
end;

class function TLabeledTextChunk.GetClassChunkName: TChunkName;
begin
  Result := 'ltxt';
end;

procedure TLabeledTextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TLabeledTextChunk then
  begin
    TLabeledTextChunk(Dest).FText := FText;
    TLabeledTextChunk(Dest).LabeledTextRecord := LabeledTextRecord;
  end;
end;

procedure TLabeledTextChunk.LoadFromStream(Stream: TStream);
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    SetLength(FText, FChunkSize - SizeOf(TLabeledTextRecord));
    Read(LabeledTextRecord, SizeOf(TLabeledTextRecord));
    Read(FText[1], Length(FText));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TLabeledTextChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(LabeledTextRecord, SizeOf(TLabeledTextRecord));
    Write(FText[1], FChunkSize);
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TLabeledTextChunk.SetText(const Value: string);
begin
  FText := Value;
  CalculateChunkSize;
end;


{ TCuedFileChunk }

procedure TCuedFileChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCuedFileChunk then
  begin
    TCuedFileChunk(Dest).FCueID := FCueID;
    TCuedFileChunk(Dest).FMediaType := FMediaType;

    // copy binary data:
    SetLength(TCuedFileChunk(Dest).FBinaryData, Length(FBinaryData));
    Move(FBinaryData[0], TCuedFileChunk(Dest).FBinaryData[0],
      Length(FBinaryData));
  end;
end;

procedure TCuedFileChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(FCueID) + SizeOf(FMediaType) + Length(FBinaryData);
end;

class function TCuedFileChunk.GetClassChunkName: TChunkName;
begin
  Result := 'file';
end;

procedure TCuedFileChunk.LoadFromStream(Stream: TStream);
begin
  // calculate chunk size
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(FCueID, SizeOf(FCueID));
    Read(FMediaType, SizeOf(FMediaType));

    // read binary data
    SetLength(FBinaryData, FChunkSize - SizeOf(FCueID) - SizeOf(FMediaType));
    Read(FBinaryData[0], Length(FBinaryData));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCuedFileChunk.SaveToStream(Stream: TStream);
begin
  // calculate chunk size
  CalculateChunkSize;

  // write basic chunk information
  inherited;

  // write custom chunk information
  with Stream do
  begin
    Write(FCueID, SizeOf(FCueID));
    Write(FMediaType, SizeOf(FMediaType));

    // write binary data:
    Write(FBinaryData[0], Length(FBinaryData));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;


{ TPlaylistSegmentItem }

procedure TPlaylistSegmentItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TPlaylistSegmentItem then
    TPlaylistSegmentItem(Dest).PlaylistSegment := PlaylistSegment
  else
    inherited;
end;


{ TPlaylistChunk }

constructor TPlaylistChunk.Create;
begin
  inherited;
  FPlaylistSegments := TOwnedCollection.Create(Self, TPlaylistSegmentItem);
end;

destructor TPlaylistChunk.Destroy;
begin
  FreeAndNil(FPlaylistSegments);
  inherited;
end;

class function TPlaylistChunk.GetClassChunkName: TChunkName;
begin
  Result := 'plst';
end;

procedure TPlaylistChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TPlaylistChunk then
  begin
    TPlaylistChunk(Dest).FCount := FCount;
    TPlaylistChunk(Dest).FPlaylistSegments.Assign(FPlaylistSegments);
  end;
end;

procedure TPlaylistChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(Cardinal) + FCount * SizeOf(TPlaylistSegmentRecord);
end;

procedure TPlaylistChunk.LoadFromStream(Stream: TStream);
var
  l: Integer;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(FCount, SizeOf(Cardinal));

    // clear all eventually existing playlist segments
    FPlaylistSegments.Clear;

    // load every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TPlaylistSegmentItem(FPlaylistSegments.Add) do
        Read(PlaylistSegment, SizeOf(TPlaylistSegmentRecord));

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TPlaylistChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // update FCount:
  FCount := FPlaylistSegments.Count;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  with Stream do
  begin
    // write sampler header
    Write(FCount, SizeOf(Cardinal));

    // write every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TPlaylistSegmentItem(FPlaylistSegments.Items[l]) do
        Write(PlaylistSegment, SizeOf(TPlaylistSegmentRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;


{ TCueItem }

procedure TCueItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TCueItem then
    TCueItem(Dest).CuePointRecord := CuePointRecord
  else
    inherited;
end;


{ TCueChunk }

constructor TCueChunk.Create;
begin
  inherited;
  FCueCollection := TOwnedCollection.Create(Self, TCueItem);
end;

destructor TCueChunk.Destroy;
begin
  FreeAndNil(FCueCollection);
  inherited;
end;

class function TCueChunk.GetClassChunkName: TChunkName;
begin
  Result := 'cue ';
end;

procedure TCueChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCueChunk then
  begin
    TCueChunk(Dest).FCount := FCount;
    TCueChunk(Dest).FCueCollection.Assign(FCueCollection);
  end;
end;

procedure TCueChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(Cardinal) + FCount * SizeOf(TCuePointRecord);
end;

procedure TCueChunk.LoadFromStream(Stream: TStream);
var
  CueCnt: Integer;
  ChunkEnd: Cardinal;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    // calculate end of chunk in case there are no cue items in this chunk
    ChunkEnd := Position + FChunkSize;

    // read number of cue items in this chunk
    Read(FCount, SizeOf(Cardinal));

    // clear all eventually existing cues
    FCueCollection.Clear;

    // load every single playlist segment and add to playlist collection
    for CueCnt := 0 to FCount - 1 do
      with TCueItem(FCueCollection.Add) do
        Read(CuePointRecord, SizeOf(TCuePointRecord));

    // make sure the position is still inside this chunk
    Assert(Position <= ChunkEnd);

    // jump to the end of this chunk
    Position := ChunkEnd;

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TCueChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // update FCount:
  FCount := FCueCollection.Count;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  // write custom chunk information
  with Stream do
  begin
    // write sampler header
    Write(FCount, SizeOf(Cardinal));

    // write every single playlist segment and add to playlist collection
    for l := 0 to FCount - 1 do
      with TCueItem(FCueCollection.Items[l]) do
        Write(CuePointRecord, SizeOf(TCuePointRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;


{ TLoopItem }

procedure TLoopItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TLoopItem then
    TLoopItem(Dest).LoopRecord := LoopRecord
  else
    inherited;
end;


{ TSamplerChunk }

constructor TSamplerChunk.Create;
begin
  inherited;
  FLoopCollection := TOwnedCollection.Create(Self, TLoopItem);
end;

destructor TSamplerChunk.Destroy;
begin
  FreeAndNil(FLoopCollection);
  inherited;
end;

procedure TSamplerChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSamplerChunk then
  begin
    TSamplerChunk(Dest).SamplerRecord := SamplerRecord;
    TSamplerChunk(Dest).FLoopCollection.Assign(FLoopCollection);
  end;
end;

procedure TSamplerChunk.CalculateChunkSize;
begin
  FChunkSize := SizeOf(TSamplerRecord) + SamplerRecord.NumSampleLoops *
    SizeOf(TLoopRecord) + SamplerRecord.SamplerData;
end;

class function TSamplerChunk.GetClassChunkName: TChunkName;
begin
  Result := 'smpl';
end;

function TSamplerChunk.GetManufacturer: TMidiManufacturer;
begin
  Result := TMidiManufacturer(SamplerRecord.Manufacturer)
end;

function TSamplerChunk.GetSMPTEFormat: TSMPTEFormat;
begin
  Result := TSMPTEFormat(SamplerRecord.SMPTEFormat);
end;

procedure TSamplerChunk.LoadFromStream(Stream: TStream);
var
  l: Integer;
begin
  // load basic chunk information
  inherited;

  // load custom chunk information
  with Stream do
  begin
    Read(SamplerRecord, SizeOf(TSamplerRecord));

    // clear all eventually existing loop points
    FLoopCollection.Clear;

    // load every single loop and add to loop collection
    for l := 0 to SamplerRecord.NumSampleLoops - 1 do
      with TLoopItem(FLoopCollection.Add) do
        Read(LoopRecord, SizeOf(TLoopRecord));

    // read rest, should only be SamplerRecord.SamplerData
    Assert(FChunkSize - SizeOf(TSamplerRecord) = SamplerRecord.SamplerData);
    Position := Position + FChunkSize - SizeOf(TSamplerRecord);

    // eventually skip padded zeroes
    if cfPadSize in ChunkFlags then
      Position := Position + CalculateZeroPad;
  end;
end;

procedure TSamplerChunk.SaveToStream(Stream: TStream);
var
  l: Integer;
begin
  // make sure some entries are correct:
  SamplerRecord.NumSampleLoops := FLoopCollection.Count;
  SamplerRecord.SamplerData := 0;

  // now recalculate the chunk size:
  CalculateChunkSize;

  // write chunk name & size
  inherited;

  // write custom chunk information
  with Stream do
  begin
    // write sampler header
    Write(SamplerRecord, SizeOf(TSamplerRecord));

    // write every single loop and add to loop collection
    for l := 0 to SamplerRecord.NumSampleLoops - 1 do
      with TLoopItem(FLoopCollection.Items[l]) do
        Write(LoopRecord, SizeOf(TLoopRecord));
  end;

  // check and eventually add zero pad
  CheckAddZeroPad(Stream);
end;

procedure TSamplerChunk.SetManufacturer(const Value: TMidiManufacturer);
begin
  SamplerRecord.Manufacturer := Cardinal(Value);
end;

procedure TSamplerChunk.SetSMPTEFormat(const Value: TSMPTEFormat);
begin
  SamplerRecord.SMPTEFormat := Cardinal(Value);
end;


{ TInstrumentChunk }

constructor TInstrumentChunk.Create;
begin
  inherited;
  StartAddress := @InstrumentRecord;
end;

procedure TInstrumentChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TInstrumentChunk then
    TInstrumentChunk(Dest).InstrumentRecord := InstrumentRecord;
end;

class function TInstrumentChunk.GetClassChunkName: TChunkName;
begin
  Result := 'inst';
end;

class function TInstrumentChunk.GetClassChunkSize: Cardinal;
begin
  Result := SizeOf(TInstrumentRecord);
end;

procedure TInstrumentChunk.SetNoteRange(Low, High: ShortInt);
begin
  Assert(Low <= High);
  InstrumentRecord.LowNote := Low;
  InstrumentRecord.HighNote := High;
end;

procedure TInstrumentChunk.SetVelocityRange(Low, High: Byte);
begin
  Assert(Low <= High);
  InstrumentRecord.LowVelocity := Low;
  InstrumentRecord.HighVelocity := High;
end;


{ TCustomBextChunk }

constructor TCustomBextChunk.Create;
begin
  inherited;
  StartAddress := @BextRecord;
end;

procedure TCustomBextChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomBextChunk then
    TCustomBextChunk(Dest).BextRecord := BextRecord;
end;

class function TCustomBextChunk.GetClassChunkSize: Cardinal;
begin
  Result := SizeOf(TBextRecord);
end;

// Some Wrapper Functions
function TCustomBextChunk.GetDescription: AnsiString;
begin
  Result := AnsiString(BextRecord.Description);
end;

function TCustomBextChunk.GetOriginationDate: AnsiString;
begin
  Result := AnsiString(BextRecord.OriginationDate);
end;

function TCustomBextChunk.GetOriginationTime: AnsiString;
begin
  Result := AnsiString(BextRecord.OriginationTime);
end;

function TCustomBextChunk.GetOriginator: AnsiString;
begin
  Result := AnsiString(BextRecord.Originator);
end;

function TCustomBextChunk.GetOriginatorRef: AnsiString;
begin
  Result := AnsiString(BextRecord.OriginatorRef);
end;

procedure TCustomBextChunk.SetDescription(const Value: AnsiString);
begin
  with BextRecord do
    if Length(Value) < SizeOf(Description) then
      Move(Value[1], Description, Length(Value))
    else
      Move(Value[1], Description, SizeOf(Description));
end;

procedure TCustomBextChunk.SetOriginationDate(const Value: AnsiString);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginationDate) then
      Move(Value[1], OriginationDate, Length(Value))
    else
      Move(Value[1], OriginationDate, SizeOf(OriginationDate));
end;

procedure TCustomBextChunk.SetOriginationTime(const Value: AnsiString);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginationTime) then
      Move(Value[1], OriginationTime, Length(Value))
    else
      Move(Value[1], OriginationTime, SizeOf(OriginationTime));
end;

procedure TCustomBextChunk.SetOriginator(const Value: AnsiString);
begin
  with BextRecord do
    if Length(Value) < SizeOf(Originator) then
      Move(Value[1], Originator, Length(Value))
    else
      Move(Value[1], Originator, SizeOf(Originator));
end;

procedure TCustomBextChunk.SetOriginatorRef(const Value: AnsiString);
begin
  with BextRecord do
    if Length(Value) < SizeOf(OriginatorRef) then
      Move(Value[1], OriginatorRef, Length(Value))
    else
      Move(Value[1], OriginatorRef, SizeOf(OriginatorRef));
end;


{ TBextChunk }

class function TBextChunk.GetClassChunkName: TChunkName;
begin
  Result := 'bext';
end;


{ TBextChunkOld }

class function TBextChunkOld.GetClassChunkName: TChunkName;
begin
  Result := 'BEXT';
end;


{ TCartChunkTag }

constructor TCartChunk.Create;
begin
  inherited;
  StartAddress := @CartRecord;
end;

procedure TCartChunk.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCartChunk then
    TCartChunk(Dest).CartRecord := CartRecord;
end;

class function TCartChunk.GetClassChunkName: TChunkName;
begin
  Result := 'cart';
end;

class function TCartChunk.GetClassChunkSize: Cardinal;
begin
  Result := SizeOf(TCartRecord);
end;

// Some Wrapper Functions
function TCartChunk.GetArtist: AnsiString;
begin
  Result := AnsiString(CartRecord.Artist);
end;

function TCartChunk.GetCategory: AnsiString;
begin
  Result := AnsiString(CartRecord.Category);
end;

function TCartChunk.GetClassification: AnsiString;
begin
  Result := AnsiString(CartRecord.Classification);
end;

function TCartChunk.GetClientID: AnsiString;
begin
  Result := AnsiString(CartRecord.ClientID);
end;

function TCartChunk.GetCutID: AnsiString;
begin
  Result := AnsiString(CartRecord.CutID);
end;

function TCartChunk.GetEndDate: AnsiString;
begin
  Result := AnsiString(CartRecord.EndDate);
end;

function TCartChunk.GetEndTime: AnsiString;
begin
  Result := AnsiString(CartRecord.EndTime);
end;

function TCartChunk.GetOutCue: AnsiString;
begin
  Result := AnsiString(CartRecord.OutCue);
end;

function TCartChunk.GetProducerAppID: AnsiString;
begin
  Result := AnsiString(CartRecord.ProducerAppID);
end;

function TCartChunk.GetProducerAppVersion: AnsiString;
begin
  Result := AnsiString(CartRecord.ProducerAppVersion);
end;

function TCartChunk.GetStartDate: AnsiString;
begin
  Result := AnsiString(CartRecord.StartDate);
end;

function TCartChunk.GetStartTime: AnsiString;
begin
  Result := AnsiString(CartRecord.StartTime);
end;

function TCartChunk.GetTitle: AnsiString;
begin
  Result := AnsiString(CartRecord.Title);
end;

function TCartChunk.GetUserDef: AnsiString;
begin
  Result := AnsiString(CartRecord.UserDef);
end;

procedure TCartChunk.SetArtist(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Artist) then
      Move(Value[1], Artist, Length(Value))
    else
      Move(Value[1], Artist, SizeOf(Artist));
end;

procedure TCartChunk.SetCategory(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Category) then
      Move(Value[1], Category, Length(Value))
    else
      Move(Value[1], Category, SizeOf(Category));
end;

procedure TCartChunk.SetClassification(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Classification) then
      Move(Value[1], Classification, Length(Value))
    else
      Move(Value[1], Classification, SizeOf(Classification));
end;

procedure TCartChunk.SetClientID(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ClientID) then
      Move(Value[1], ClientID, Length(Value))
    else
      Move(Value[1], ClientID, SizeOf(ClientID));
end;

procedure TCartChunk.SetCutID(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(CutID) then
      Move(Value[1], CutID, Length(Value))
    else
      Move(Value[1], CutID, SizeOf(CutID));
end;

procedure TCartChunk.SetEndDate(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(EndDate) then
      Move(Value[1], EndDate, Length(Value))
    else
      Move(Value[1], EndDate, SizeOf(EndDate));
end;

procedure TCartChunk.SetEndTime(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(EndTime) then
      Move(Value[1], EndTime, Length(Value))
    else
      Move(Value[1], EndTime, SizeOf(EndTime));
end;

procedure TCartChunk.SetOutCue(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(OutCue) then
      Move(Value[1], OutCue, Length(Value))
    else
      Move(Value[1], OutCue, SizeOf(OutCue));
end;

procedure TCartChunk.SetProducerAppID(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ProducerAppID) then
      Move(Value[1], ProducerAppID, Length(Value))
    else
      Move(Value[1], ProducerAppID, SizeOf(ProducerAppID));
end;

procedure TCartChunk.SetProducerAppVersion(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(ProducerAppVersion) then
      Move(Value[1], ProducerAppVersion, Length(Value))
    else
      Move(Value[1], ProducerAppVersion, SizeOf(ProducerAppVersion));
end;

procedure TCartChunk.SetStartDate(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(StartDate) then
      Move(Value[1], StartDate, Length(Value))
    else
      Move(Value[1], StartDate, SizeOf(StartDate));
end;

procedure TCartChunk.SetStartTime(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(StartTime) then
      Move(Value[1], StartTime, Length(Value))
    else
      Move(Value[1], StartTime, SizeOf(StartTime));
end;

procedure TCartChunk.SetTitle(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(Title) then
      Move(Value[1], Title, Length(Value))
    else
      Move(Value[1], Title, SizeOf(Title));
end;

procedure TCartChunk.SetUserDef(const Value: AnsiString);
begin
  with CartRecord do
    if Length(Value) < SizeOf(UserDef) then
      Move(Value[1], UserDef, Length(Value))
    else
      Move(Value[1], UserDef, SizeOf(UserDef));
end;


{ TWavSDA8Chunk }

constructor TWavSDA8Chunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize, cfReversedByteOrder];
end;

class function TWavSDA8Chunk.GetClassChunkName: TChunkName;
begin
 Result := 'SDA8';
end;

procedure TWavSDA8Chunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 // not yet defined
end;

procedure TWavSDA8Chunk.LoadFromStream(Stream: TStream);
begin
 inherited;
 with Stream
  do Position := Position + FChunkSize;
end;

procedure TWavSDA8Chunk.SaveToStream(Stream: TStream);
begin
 FChunkSize := 0;
 inherited;

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;


{ TWavSDAChunk }

class function TWavSDAChunk.GetClassChunkName: TChunkName;
begin
 Result := 'SDA ';
end;


{ TWavAFspChunk }

class function TWavAFspChunk.GetClassChunkName: TChunkName;
begin
 Result := 'afsp';
end;


{ TBWFLinkChunk }

class function TBWFLinkChunk.GetClassChunkName: TChunkName;
begin
 Result := 'link';
end;


{ TBWFAXMLChunk }

class function TBwfAXMLChunk.GetClassChunkName: TChunkName;
begin
 Result := 'axml';
end;


{ TWavDisplayChunk }

constructor TWavDisplayChunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize];
end;

procedure TWavDisplayChunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 if Dest is TWavDisplayChunk then
  begin
   TWavDisplayChunk(Dest).FTypeID := FTypeID;
   TWavDisplayChunk(Dest).FData := FData;
  end;
end;

class function TWavDisplayChunk.GetClassChunkName: TChunkName;
begin
 Result := 'DISP';
end;

procedure TWavDisplayChunk.LoadFromStream(Stream: TStream);
var
  ChunkEnd : Integer;
begin
 inherited;
 // calculate end of stream position
 ChunkEnd := Stream.Position + FChunkSize;
// assert(ChunkEnd <= Stream.Size);

 // read type ID
 Stream.Read(FTypeID, SizeOf(Cardinal));

 // set length of data and read data
 SetLength(FData, FChunkSize - SizeOf(Cardinal));
 Stream.Read(FData[1], Length(FData));

 assert(Stream.Position <= ChunkEnd);

 // goto end of this chunk
 Stream.Position := ChunkEnd;

 // eventually skip padded zeroes
 if cfPadSize in ChunkFlags
  then Stream.Position := Stream.Position + CalculateZeroPad;
end;

procedure TWavDisplayChunk.SaveToStream(Stream: TStream);
begin
 // calculate chunk size
 FChunkSize := SizeOf(Cardinal) + Length(FData);

 // write basic chunk information
 inherited;

 // write custom chunk information
 with Stream do
  begin
   Write(FTypeID, SizeOf(Cardinal));
   Write(FData[1], FChunkSize - SizeOf(Cardinal));
  end;

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;

{ TWavPeakChunk }

constructor TWavPeakChunk.Create;
begin
 inherited;
 ChunkFlags := ChunkFlags + [cfPadSize];
end;

procedure TWavPeakChunk.AssignTo(Dest: TPersistent);
begin
 inherited;
 if Dest is TWavPeakChunk
  then TWavPeakChunk(Dest).Peak := Peak;
end;

class function TWavPeakChunk.GetClassChunkName: TChunkName;
begin
 Result := 'PEAK';
end;

procedure TWavPeakChunk.LoadFromStream(Stream: TStream);
var
  ChunkEnd : Integer;
begin
 inherited;
 ChunkEnd := Stream.Position + FChunkSize;
 Stream.Read(Peak, SizeOf(TPeakRecord));
 Stream.Position := ChunkEnd;
end;

procedure TWavPeakChunk.SaveToStream(Stream: TStream);
begin
 // calculate chunk size
 FChunkSize := SizeOf(TPeakRecord);

 // write basic chunk information
 inherited;

 // write custom chunk information
 Stream.Write(Peak, FChunkSize);

 // check and eventually add zero pad
 CheckAddZeroPad(Stream);
end;


{ TCustomAudioFileContainer }

constructor TCustomAudioFileContainer.Create(const FileName: TFileName);
begin
  if FileExists(FileName) then
    Create(TFileStream.Create(FileName, fmOpenReadWrite))
  else
    Create(TFileStream.Create(FileName, fmCreate));
  FOwnsStream := True;
end;

constructor TCustomAudioFileContainer.Create(const Stream: TStream);
begin
  Create;

  // store stream
  FStream := Stream;

  // basic setup
  if CanLoad(Stream) then
    ReadHeader
  else if Stream.Size = 0 then
    SetupHeader;
end;

destructor TCustomAudioFileContainer.Destroy;
begin
  if FOwnsStream then
    FreeAndNil(FStream);

  inherited;
end;

class function TCustomAudioFileContainer.CanLoad(const FileName: TFileName): Boolean;
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmOpenRead);
  try
    Result := CanLoad(FS);
  finally
    FreeAndNil(FS);
  end;
end;

procedure TCustomAudioFileContainer.Flush;
begin
  // jump to header start position
  FStream.Position := 0;
end;

procedure TCustomAudioFileContainer.ReadHeader;
begin
  // jump to header start position
  FStream.Position := 0;
end;

function TCustomAudioFileContainer.GetTotalTime: Double;
begin
  Result := SampleFrames / SampleRate;
end;

class function TCustomChunkedAudioFileContainer.ChunkClassByName(Value: string): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := Length(FChunkClasses) - 1 downto 0 do
  begin
    if FChunkClasses[X].ClassName = Value then
    begin
      Result := FChunkClasses[X];
      Break;
    end;
  end;
end;

class function TCustomChunkedAudioFileContainer.ChunkClassByChunkName(Value: TChunkName): TDefinedChunkClass;
var
  X: Integer;
begin
  Result := nil;
  for X := 0 to Length(FChunkClasses) - 1 do
    if CompareChunkNames(FChunkClasses[X].GetClassChunkName, Value) then
    begin
      Result := FChunkClasses[X];
      Break;
    end;
end;

class function TCustomChunkedAudioFileContainer.IsChunkClassRegistered(AClass: TDefinedChunkClass): Boolean;
var
  X: Integer;
begin
  Result := False;
  for X := Length(FChunkClasses) - 1 downto 0 do
  begin
    if FChunkClasses[X] = AClass then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class procedure TCustomChunkedAudioFileContainer.RegisterChunk(AClass: TDefinedChunkClass);
begin
  Classes.RegisterClass(AClass);
  Assert(not IsChunkClassRegistered(AClass));
  SetLength(FChunkClasses, Length(FChunkClasses) + 1);
  FChunkClasses[Length(FChunkClasses) - 1] := AClass;
end;

class procedure TCustomChunkedAudioFileContainer.RegisterChunks(AClasses: array of TDefinedChunkClass);
var
  i: Integer;
begin
  for i := 0 to Length(AClasses) - 1 do
    RegisterChunk(AClasses[i]);
end;


{ TAudioFileContainerWAV }

constructor TAudioFileContainerWAV.Create;
begin
  inherited;

  FChunkList := TChunkList.Create;
end;

destructor TAudioFileContainerWAV.Destroy;
begin
  FreeAndNil(FFactChunk);
  FreeAndNil(FFormatChunk);
  FreeAndNil(FChunkList);

  inherited;
end;

class function TAudioFileContainerWAV.DefaultExtension: string;
begin
  Result := '.wav';
end;

procedure TAudioFileContainerWAV.DeleteSubChunk(SubChunk: TCustomChunk);
var
  i: Integer;
begin
  i := 0;
  while i < FChunkList.Count do
    if FChunkList[i] = SubChunk then
      FChunkList.Delete(i)
    else
      Inc(i);
end;

procedure TAudioFileContainerWAV.DeleteSubChunk(const Index: Integer);
begin
  if (Index >= 0) and (Index < FChunkList.Count) then
    FChunkList.Delete(Index)
  else
    raise EWavError.CreateFmt(RCStrIndexOutOfBounds, [Index]);
end;

class function TAudioFileContainerWAV.Description: string;
begin
  Result := 'Microsoft RIFF WAVE';
end;

class function TAudioFileContainerWAV.FileFormatFilter: string;
begin
  Result := Description + ' (*.' + DefaultExtension + ')|*.wav*'
end;

function TAudioFileContainerWAV.AddSubChunk(
  SubChunkClass: TCustomChunkClass): TCustomChunk;
begin
  Result := TCustomChunkClass.Create;
  AddSubChunk(Result);
end;

procedure TAudioFileContainerWAV.AddSubChunk(SubChunk: TCustomChunk);
begin
  // check if the very same chunk is already present
  if FChunkList.IndexOf(SubChunk) >= 0 then
    raise EWavError.Create('Chunk already present');

  FChunkList.Add(SubChunk);
end;

class function TAudioFileContainerWAV.CanLoad(const Stream: TStream): Boolean;
var
  ChunkName: TChunkName;
  ChunkSize: Cardinal;
  OldPosition: Cardinal;
begin
  Result := False;

  // store old position
  OldPosition := Stream.Position;

  with Stream do
    try
      // check whether file is a resource interchange file format ('RIFF')
      Read(ChunkName, 4);
      if ChunkName <> 'RIFF' then
        exit;

      // check whether the real file size match the filesize stored inside the RIFF chunk
      Read(ChunkSize, 4);
      if (ChunkSize > Size - Position) and not(ChunkSize = $FFFFFFFF) then
        exit;

      // now specify the RIFF file to be a WAVE file
      Read(ChunkName, 4);
      if ChunkName <> 'WAVE' then
        exit;

      Result := True;
    finally
      // restore old position
      Position := OldPosition;
    end;
end;

function TAudioFileContainerWAV.GetCartChunk: TCartChunk;
var
  Index: Integer;
begin
  Result := nil;
  for Index := 0 to FChunkList.Count - 1 do
    if FChunkList[Index] is TCartChunk then
      Result := TCartChunk(FChunkList[Index]);
end;

function TAudioFileContainerWAV.GetChannels: Cardinal;
begin
  Result := FFormatChunk.Channels;
end;

function TAudioFileContainerWAV.GetSampleFrames: Cardinal;
begin
  if Assigned(FFactChunk) then
    Result := FFactChunk.SampleCount
  else if FFormatChunk.FormatTag <> etPCM then
    Result := DataSize div FFormatChunk.BlockAlign
  else
    raise Exception.Create('Could not determine sample frames');
end;

function TAudioFileContainerWAV.GetSampleRate: Double;
begin
  Result := FFormatChunk.SampleRate;
end;

function TAudioFileContainerWAV.GetSubChunk(Index: Integer): TCustomChunk;
begin
  if (Index >= 0) and (Index < FChunkList.Count) then
    Result := FChunkList[Index]
  else
    raise EWavError.CreateFmt(RCStrIndexOutOfBounds, [Index]);
end;

function TAudioFileContainerWAV.GetSubChunkCount: Cardinal;
begin
  Result := FChunkList.Count;
end;

function TAudioFileContainerWAV.GetTypicalAudioDataPosition: Cardinal;
begin
  Result := 12 + SizeOf(TChunkName) + SizeOf(Integer) + FFormatChunk.ChunkSize;
  if Assigned(FFactChunk) then
    Result := Result + SizeOf(TChunkName) + SizeOf(Integer) +
      FFactChunk.ChunkSize;
end;

function TAudioFileContainerWAV.GetBextChunk: TBextChunk;
var
  Index: Integer;
begin
  Result := nil;
  for Index := 0 to FChunkList.Count - 1 do
    if FChunkList[Index] is TBextChunk then
      Result := TBextChunk(FChunkList[Index]);
end;

function TAudioFileContainerWAV.GetBitsPerSample: Byte;
begin
  Result := FFormatChunk.BitsPerSample;
end;

function TAudioFileContainerWAV.GetEmptyData: Boolean;
begin
  Result := FDataPosition = 0;
end;

procedure TAudioFileContainerWAV.SetBitsPerSample(const Value: Byte);
begin
  // Assert stream is empty
  if not EmptyData then
    raise Exception.Create(RCStrCantChangeTheFormat);

  with FFormatChunk do
    if BitsPerSample <> Value then
    begin
      BitsPerSample := Value;
      FBytesPerSample := (BitsPerSample + 7) div 8;
      BlockAlign := Channels * FBytesPerSample;
      BytesPerSecond := BlockAlign * SampleRate;
    end;

(*
  // if empty stream is assigned update format chunk
  if EmptyData then
  begin
    FStream.Position := 12;
    WriteFormatChunk(FStream);
  end;
*)
end;

procedure TAudioFileContainerWAV.SetChannels(const Value: Cardinal);
var
  WordValue: Word;
begin
  // Assert stream is empty
  if not EmptyData then
    raise Exception.Create(RCStrCantChangeTheFormat);

  if Value > 65535 then
    WordValue := 65535
  else
    WordValue := Word(Value);

  inherited;

  with FFormatChunk do
    if Channels <> Value then
    begin
      Channels := WordValue;
      BlockAlign := Word(FBytesPerSample * WordValue);
      BytesPerSecond := BlockAlign * SampleRate;
    end;

(*
  // if empty stream is assigned update format chunk
  if EmptyData then
  begin
    FStream.Position := 12;
    WriteFormatChunk(FStream);
  end;
*)
end;

procedure TAudioFileContainerWAV.SetSampleFrames(const Value: Cardinal);
begin
  // eventually store sample count right away
  if Assigned(FFactChunk) then
    FFactChunk.SampleCount := Value
  else
  begin
    // check if data has been written so far
    if DataSize = 0 then
    begin
      // create fact chunk and store sample count
      FFactChunk := TFactChunk.Create;
      FFactChunk.SampleCount := Value
    end
    else
      raise Exception.Create('SampleFrames');
  end;
end;

procedure TAudioFileContainerWAV.SetSampleRate(const Value: Double);
begin
  // Assert stream is empty
  if Assigned(FStream) and not EmptyData then
    raise Exception.Create(RCStrCantChangeTheFormat);

  inherited;
  with FFormatChunk do
    if SampleRate <> Value then
    begin
      SampleRate := Round(Value);
      BytesPerSecond := BlockAlign * SampleRate;
    end;

(*
  // if empty stream is assigned update format chunk
  if Assigned(FStream) and EmptyData then
  begin
    FStream.Position := 12;
    WriteFormatChunk(FStream);
  end;
*)
end;

procedure TAudioFileContainerWAV.SetupHeader;
begin
  inherited;

  Assert(not Assigned(FFormatChunk));
  Assert(not Assigned(FFactChunk));

  FFormatChunk := TFormatChunk.Create;
  FFormatChunk.FormatTag := etPcm;
  FFormatChunk.Channels := 1;
  FFormatChunk.SampleRate := 44100;
  FBytesPerSample := 3;
  BitsPerSample := 24;

  // always write fact chunk! (TODO: could be dependent on encoding!)
  FFactChunk := TFactChunk.Create;
  FFactChunk.SampleCount := 0;

  FDataPosition := 0;
end;

procedure TAudioFileContainerWAV.ReadDataChunk;
begin
  with FStream do
    begin
      // skip chunk name
      Position := Position + 4;

      // read data size
      Read(FDataSize, 4);

      // store data chunk position
      FDataPosition := Position;

      Position := Position + FDataSize;

      // make all chunks word aligned!
      Position := Position + ((Position - FDataPosition) and $1);
    end
end;

procedure TAudioFileContainerWAV.ReadUnknownChunk(const ChunkName: TChunkName);
var
  ChunkClass: TDefinedChunkClass;
  DefinedChunk: TDefinedChunk;
begin
  ChunkClass := ChunkClassByChunkName(ChunkName);
  if Assigned(ChunkClass) then
  begin
    DefinedChunk := ChunkClass.Create;
    DefinedChunk.LoadFromStream(FStream);
    FChunkList.Add(DefinedChunk);
  end
  else
  begin
    // ignore unknown chunk
    with TWavUnknownChunk.Create do
      try
        LoadFromStream(FStream);
      finally
        Free;
      end;
  end;
end;


// Load/Save

procedure TAudioFileContainerWAV.ReadHeader;
var
  ChunkName: TChunkName;
  ChunkEnd: Cardinal;
begin
  inherited;

  with FStream do
  begin
    // check whether file is a resource interchange file format ('RIFF')
    Read(ChunkName, 4);
    if ChunkName <> 'RIFF' then
      raise EWavError.Create(RCRIFFChunkNotFound);

    // check whether the real file size match the filesize stored inside the RIFF chunk
    Read(FChunkSize, 4);
    if (FChunkSize > Size - Position) and not (FChunkSize = $FFFFFFFF) then
      raise EWavError.Create(RCRIFFSizeMismatch);
    ChunkEnd := Position + FChunkSize;

    // now specify the RIFF file to be a WAVE file
    Read(ChunkName, 4);
    if ChunkName <> 'WAVE' then
      raise EWavError.Create(RCWAVEChunkNotFound);

    while Position < ChunkEnd do
    begin
      // read chunk name
      Read(ChunkName, 4);

      // read chunk position
      Position := Position - 4;

      if ChunkName = 'fmt ' then
        ReadFormatChunk
      else if ChunkName = 'fact' then
        ReadFactChunk
      else if ChunkName = 'data' then
        ReadDataChunk
      else
        ReadUnknownChunk(ChunkName);
    end;
  end;
end;

procedure TAudioFileContainerWAV.ReadFormatChunk;
begin
  // check whether format chunk is already present otherwise create it
  if Assigned(FFormatChunk) then
    raise Exception.Create(RCFACTChunkDublicate)
  else
    FFormatChunk := TFormatChunk.Create;

  // finally load format chunk
  FFormatChunk.LoadFromStream(FStream);
end;

procedure TAudioFileContainerWAV.ReadFactChunk;
begin
  // check whether fact chunk is already present otherwise create it
  if Assigned(FFactChunk) then
    raise Exception.Create(RCFACTChunkDublicate)
  else
    FFactChunk := TFactChunk.Create;

  // finally load fact chunk
  FFactChunk.LoadFromStream(FStream);
end;

procedure TAudioFileContainerWAV.Flush;
var
  ChunkName: TChunkName;
  ChunkStart: Cardinal;
  ChunkSize: Cardinal;
  Index: Integer;
begin
  inherited;

  with FStream do
  begin
    // Store chunk start position, just in case the stream position is not 0;
    ChunkStart := Position;

    // first write 'RIFF' (resource interchange file format)
    ChunkName := 'RIFF';
    Write(ChunkName, 4);

    // write dummy filesize yet, since final size is still unknown
    ChunkSize := $FFFFFFFF;
    Write(ChunkSize, 4);

    // now specify the RIFF file to be a WAVE file
    ChunkName := 'WAVE';
    Write(ChunkName, 4);

    // write format chunk
    FFormatChunk.SaveToStream(FStream);

    // eventually update fact chunk
    if Assigned(FFactChunk) and (FFormatChunk.FormatTag = etPCM) then
      FFactChunk.SampleCount := FDataSize div FFormatChunk.BlockAlign;
    FFactChunk.SaveToStream(FStream);

    // write subchunks
    for Index := 0 to FChunkList.Count - 1 do
      FChunkList[Index].SaveToStream(FStream);

    // write 'data' chunk name
    ChunkName := 'data';
    Write(ChunkName, 4);

    // write chunk size
    ChunkSize := DataSize;
    Write(ChunkSize, 4);

    Assert(Position = FDataPosition);

    // finally write filesize
    ChunkSize := Position - (ChunkStart + 8);
    Position := ChunkStart + 4;
    Write(ChunkSize, 4);

    // Reset Position to end of Stream;
    Position := ChunkStart + ChunkSize;
  end;
end;

function TAudioFileContainerWAV.ReadAudioData(Buffer: PByte; Offset, Size: Cardinal): Cardinal;
begin
  // check if the data position has been specified already
  if FDataPosition = 0 then
    Exit(0);

  FStream.Position := FDataPosition + Offset;
  Result := FStream.Read(Buffer^, Size);
end;

function TAudioFileContainerWAV.ReadAudioData(Buffer: PByte; Size: Cardinal): Cardinal;
begin
  // check if the data position has been specified already
  if FDataPosition = 0 then
    Exit(0);

  // eventually set position to data position
  if FStream.Position < FDataPosition then
    FStream.Position := FDataPosition;

  Result := FStream.Read(Buffer^, Size);
end;

procedure TAudioFileContainerWAV.WriteAudioData(Buffer: PByte; Size: Cardinal);
var
  Index: Integer;
begin
  // eventually update data position
  if FDataPosition = 0 then
  begin
    FDataPosition := 20 + FFormatChunk.ChunkSize + 8;
    if Assigned(FFactChunk) then
      FDataPosition := FDataPosition + FFactChunk.ChunkSize + 8;
    for Index := 0 to FChunkList.Count - 1 do
      FDataPosition := FDataPosition + FChunkList[Index].ChunkSize + 8;
    FStream.Position := FDataPosition;
  end;

  FDataSize := FDataSize + Size;
  FStream.Write(Buffer^, Size);
end;



initialization
  RegisterFileFormat(TAudioFileContainerWAV);

  TAudioFileContainerWAV.RegisterChunks([TFormatChunk, TFactChunk,
    TQualityChunk, TLabelChunk, TNoteChunk, TLabeledTextChunk, TCuedFileChunk,
    TPlaylistChunk, TSilentChunk, TCueChunk, TInfoSoftwareNameChunk,
    TInfoCommentChunk, TInfoCreationDateChunk, TInfoSubjectChunk,
    TInfoCopyrightChunk, TInfoArtistChunk, TInfoTitleChunk, TJunkChunk, TPadChunk,
    TSamplerChunk, TInstrumentChunk, TBextChunk, TCartChunk, TWavSDA8Chunk,
    TWavSDAChunk, TBWFLinkChunk, TBWFAXMLChunk, TWavDisplayChunk,
    TWavAFspChunk, TWavPeakChunk]);

end.
