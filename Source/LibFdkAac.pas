unit LibFdkAac;

{$Z4}

interface

{-$DEFINE DynLink}

const
{$IF Defined(MSWINDOWS)}
  CLibFdkAac = 'libfdk-aac-2.dll';
{$ELSEIF Defined(DARWIN) or Defined(MACOS)}
  CLibFdkAac = 'libfdk-aac-2.dylib';
{$ELSEIF Defined(UNIX)}
  CLibFdkAac = '/usr/lib/libfdk-aac-2.so';
{$IFEND}

const
  AACENCODER_LIB_VL0 = 4;
  AACENCODER_LIB_VL1 = 0;
  AACENCODER_LIB_VL2 = 1;

  AACDECODER_LIB_VL0 = 3;
  AACDECODER_LIB_VL1 = 0;
  AACDECODER_LIB_VL2 = 0;

type
  // Error handling

  TAacEncoderError = (
    aeOK                    = $0000, // No error happened. All fine.
    aeInvalidHandle         = $0020, // Handle passed to function call was invalid.
    aeMemoryError           = $0021, // Memory allocation failed.
    aeUnsupportedParameter  = $0022, // Parameter not available.
    aeInvalidConfig         = $0023, // Configuration not provided.
    aeInitError             = $0040, // General initialization error.
    aeInitAacError          = $0041, // AAC library initialization error.
    aeInitSbrError          = $0042, // SBR library initialization error.
    aeInitTpError           = $0043, // Transport library initialization error.
    aeInitMetaError         = $0044, // Meta data library initialization error.
    aeInitMpsError          = $0045, // MPS library initialization error.
    aeEncodeError           = $0060, // The encoding process was interrupted by an unexpected error.
    aeEncodeEof             = $0080  // End of file reached.
  );

  TAacDecoderError = (
    adOK                            = $0000, // No error occurred. Output buffer is valid and error free..
    adOutOfMemory                   = $0002, // Heap returned NULL pointer. Output buffer is invalid.
    adUnknown                       = $0005, // Error condition is of unknown reason, or from a another module. Output buffer is invalid.
    adSyncErrorStart                = $1000,
    adTransportSyncError            = $1001, // The transport decoder had synchronization problems. Do not exit decoding. Just feed new bitstream data.
    adNotEnoughBits                 = $1002, // The input buffer ran out of bits.
    adSyncErrorEnd                  = $1FFF, // ---
    adInitErrorStart                = $2000,
    adInvalidHandle                 = $2001, // The handle passed to the function call was invalid (NULL).
    adUnsupportedAot                = $2002, // The AOT found in the configuration is not supported.
    adUnsupportedFormat             = $2003, // The bitstream format is not supported.
    adUnsupportedErFormat           = $2004, // The error resilience tool format is not supported.
    adUnsupportedEpconfig           = $2005, // The error protection format is not supported.
    adUnsupportedMultilayer         = $2006, // More than one layer for AAC scalable is not supported.
    adUnsupportedChannelconfig      = $2007, // The channel configuration (either number or arrangement) is not supported.
    adUnsupportedSamplingrate       = $2008, // The sample rate specified in the configuration is not supported.
    adInvalidSbrConfig              = $2009, // The SBR configuration is not supported.
    adSetParamFail                  = $200A, // The parameter could not be set. Either the value was out of range or the parameter does not exist.
    adNeedToRestart                 = $200B, // The decoder needs to be restarted, since the required configuration change cannot be performed.
    adOutputBufferTooSmall          = $200C, // The provided output buffer is too small.
    adInitErrorEnd                  = $2FFF, // ---
    adDecodeErrorStart              = $4000,
    adTransportError                = $4001, // The transport decoder encountered an unexpected error.
    adParseError                    = $4002,
    adUnsupportedExtensionPayload   = $4003,
    adDecodeFrameError              = $4004,
    adCrcError                      = $4005,
    adInvalidCodeBook               = $4006,
    adUnsupportedPrediction         = $4007,
    adUnsupportedCce                = $4008,
    adUnsupportedLfe                = $4009,
    adUnsupportedGainControlData    = $400A,
    adUnsupportedSba                = $400B,
    adTnsReadError                  = $400C,
    adRvlcError                     = $400D, // Error while decoding error resilient data.
    adDecodeErrorEnd                = $4FFF, // ---
    adAncDataErrorStart             = $8000,
    adAncDataError                  = $8001, // Non severe error concerning the ancillary data handling.
    adTooSmallAncBuffer             = $8002, // The registered ancillary data buffer is too small to receive the parsed data.
    adTooManyAncElements            = $8003, // More than the allowed number of ancillary data elements should be written to buffer.
    adAncDataErrorEnd               = $8FFF  // ---
  );

  TFileFormat = (
    ffUnknown    = -1, // Unknown format.
    ffRaw        = 0,  // No container, bit stream data conveyed "as is".
    ffMP4_3GPP   = 3,  // 3GPP file format.
    ffMP4_MP4F   = 4,  // MPEG-4 File format.
    ffRawPackets = 5,  // Proprietary raw packet file.
    ffDrmCT      = 12  // Digital Radio Mondial (DRM30/DRM+) CT proprietary file format.
  );

  TTransportType = (
    ttUnknown     = -1, // Unknown format.
    ttMp4Raw      = 0,  // "as is" access units (packet based since there is obviously no sync layer)
    ttMp4Adif     = 1,  // ADIF bitstream format.
    ttMp4Adts     = 2,  // ADTS bitstream format.
    ttMp4LatmMcp1 = 6,  // Audio Mux Elements with muxConfigPresent = 1
    ttMp4LatmMcp0 = 7,  // Audio Mux Elements with muxConfigPresent = 0, out of band StreamMuxConfig
    ttMp4Loas     = 10, // Audio Sync Stream.
    ttDrm         = 12, // Digital Radio Mondial (DRM30/DRM+) bitstream format.
    ttMp1Layer1   = 16, // MPEG 1 Audio Layer 1 audio bitstream.
    ttMp1Layer2   = 17, // MPEG 1 Audio Layer 2 audio bitstream.
    ttMp1Layer3   = 18, // MPEG 1 Audio Layer 3 audio bitstream.
    ttRsvd50      = 50
  );

  TAudioObjectType = (
    aotNone             = -1,
    aotNullObject       = 0,
    aotAacMain          = 1, // Main profile
    aotAacLC            = 2, // Low Complexity object
    aotAacSSR           = 3,
    aotAacLTP           = 4,
    aotSBR              = 5,
    aotAacSCAL          = 6,
    aotTwinVQ           = 7,
    aotCELP             = 8,
    aotHVXC             = 9,
    aotRSVD_10          = 10, // (reserved)
    aotRSVD_11          = 11, // (reserved)
    aotTTSI             = 12, // TTSI Object
    aotMainSynthetic    = 13, // Main Synthetic object
    aotWavTabSynth      = 14, // Wavetable Synthesis object
    aotGeneralMIDI      = 15, // General MIDI object
    aotAlgSynthAudioFX  = 16, // Algorithmic Synthesis and Audio FX object
    aotErrorResAacLC    = 17, // Error Resilient(ER) AAC Low Complexity
    aotRSVD_18          = 18, // (reserved)
    aotErrorResAacLTP   = 19, // Error Resilient(ER) AAC LTP object
    aotErrorResAacSCAL  = 20, // Error Resilient(ER) AAC Scalable object
    aotErrorResTwinVQ   = 21, // Error Resilient(ER) TwinVQ object
    aotErrorResBSAC     = 22, // Error Resilient(ER) BSAC object
    aotErrorResAacLD    = 23, // Error Resilient(ER) AAC LowDelay object
    aotErrorResCELP     = 24, // Error Resilient(ER) CELP object
    aotErrorResHVXC     = 25, // Error Resilient(ER) HVXC object
    aotErrorResHILN     = 26, // Error Resilient(ER) HILN object
    aotErrorResPara     = 27, // Error Resilient(ER) Parametric object
    aotRSVD_28          = 28, // might become SSC
    aotPS               = 29, // PS, Parametric Stereo (includes SBR)
    aotMpegS            = 30, // MPEG Surround

    aotEscape           = 31, // Signal AOT uses more than 5 bits

    aotMp3OnMp4Layer1   = 32, // MPEG-Layer1 in mp4
    aotMp3OnMp4Layer2   = 33, // MPEG-Layer2 in mp4
    aotMp3OnMp4Layer3   = 34, // MPEG-Layer3 in mp4
    aotRSVD_35          = 35, // might become DST
    aotRSVD_36          = 36, // might become ALS
    aotAacSLS           = 37, // AAC + SLS
    aotSLS              = 38, // SLS
    aotErrorResAacELD   = 39, // AAC Enhanced Low Delay

    aotUSAC             = 42, // USAC
    aotSAOC             = 43, // SAOC
    aotLowDelayMpegS    = 44, // Low Delay MPEG Surround

    // Pseudo AOTs
    aotMp2AacLC         = 129, // Virtual AOT MP2 Low Complexity profile
    aotMp2Sbr           = 132, // Virtual AOT MP2 Low Complexity Profile with SBR

    aotDrmAac           = 143, // Virtual AOT for DRM (ER-AAC-SCAL without SBR)
    aotDrmSbr           = 144, // Virtual AOT for DRM (ER-AAC-SCAL with SBR)
    aotDrmMpegPS        = 145, // Virtual AOT for DRM (ER-AAC-SCAL with SBR and MPEG-PS)
    aotDrmSurround      = 146, // Virtual AOT for DRM Surround (ER-AAC-SCAL (+SBR) +MPS)
    aotDrmUSAC          = 147  // Virtual AOT for DRM with USAC
  );

  TChannelMode = (
    cmInvalid           = -1,
    cmUnknown           = 0,
    cm1                 = 1,  // C */
    cm2                 = 2,  // L+R */
    cm1_2               = 3,  // C, L+R */
    cm1_2_1             = 4,  // C, L+R, Rear */
    cm1_2_2             = 5,  // C, L+R, LS+RS */
    cm1_2_2_1           = 6,  // C, L+R, LS+RS, LFE */
    cm1_2_2_2_1         = 7,  // C, LC+RC, L+R, LS+RS, LFE */

    cm6_1               = 11, // C, L+R, LS+RS, Crear, LFE */
    cm7_1_Back          = 12, // C, L+R, LS+RS, Lrear+Rrear, LFE */
    cm7_1_TopFront      = 14, // C, L+R, LS+RS, LFE, Ltop+Rtop */

    cm7_1_RearSurround  = 33, // C, L+R, LS+RS, Lrear+Rrear, LFE */
    cm7_1_FrontCenter   = 34, // C, LC+RC, L+R, LS+RS, LFE */

    cm212               = 128 // 212 configuration, used in ELDv2
  );

  TAudioChannelType = (
    actNone          = $00,
    actFront        = $01, // Front speaker position (at normal height)
    actSide         = $02, // Side speaker position (at normal height)
    actBack         = $03, // Back speaker position (at normal height)
    actLFE          = $04, // Low frequency effect speaker postion (front)
    actTop          = $10, // Top speaker area (for combination with speaker positions)
    actFrontTop     = $11, // Top front speaker = (actFront + actTop)
    actSideTop      = $12, // Top side speaker  = (actSide + actTop)
    actBackTop      = $13, // Top back speaker  = (actBack + actTop)
    actBottom       = $20, // Bottom speaker area (for combination with speaker positions)
    actFrontBottom  = $21, // Bottom front speaker = (actFront + actBottom)
    actSideBottom   = $22, // Bottom side speaker  = (actSide  +actBottom)
    actBackBottom   = $23  // Bottom back speaker  = (actBack + actBottom)
  );
  PAudioChannelType = ^TAudioChannelType;

  TSbrParametricStereoSignaling = (
    sigUnknown = -1,
    sigImplicit = 0,             // implicit signaling,
    sigExplicitBwCompatible = 1, // backwards compatible explicit signaling,
    sigExplicitHierarchical = 2  // hierarcical explicit signaling
  );

  // Audio Codec flags
  TAudioCodecFlag = (
    acER_VCB11       =  0, // aacSectionDataResilienceFlag flag (from ASC): 1 means use virtual codebooks
    acER_RVLC        =  1, // aacSpectralDataResilienceFlag flag (from ASC): 1 means use huffman codeword reordering
    acER_HCR         =  2, // aacSectionDataResilienceFlag flag (from ASC): 1 means use virtual codebooks
    acSCALABLE       =  3, // AAC Scalable
    acELD            =  4, // AAC-ELD
    acLD             =  5, // AAC-LD
    acER             =  6, // ER syntax
    acBSAC           =  7, // BSAC
    acUSAC           =  8, // USAC
    acRSV603DA       =  9, // RSVD60 3D audio
    acHDAAC          = 10, // HD-AAC
    acRSVD50         = 14, // Rsvd50
    acSbrPresent     = 15, // SBR present flag (from ASC)
    acSbrCRC         = 16, // SBR CRC present flag. Only relevant for AAC-ELD for now.
    acPsPresent      = 17, // PS present flag (from ASC or implicit)
    acMpsPresent     = 18, // MPS present flag (from ASC or implicit)
    acDrm            = 19, // DRM bit stream syntax
    acINDEP          = 20, // Independency flag
    acMpegDResidual  = 21, // MPEG-D residual individual channel data.
    acSAOC_Present   = 22, // SAOC Present Flag
    acDAB            = 23, // DAB bit stream syntax
    acELD_DownScale  = 24, // ELD Downscaled playout
    acLowDelayMPS    = 25, // Low Delay MPS.
    acDrcPresent     = 26, // Dynamic Range Control (DRC) data found.
    acUSAC_SCFGI3    = 27  // USAC flag: If stereoConfigIndex is 3 the flag is set.
  );
  TAudioCodecFlags = set of TAudioCodecFlag;

  // Audio Codec flags (reconfiguration).
  TAudioCodecReconfigurationFlag = (
    acrDetCfgChange = 0, // Config mode signalizes the callback to work in config change detection mode
    acrAllocMem     = 1  // Config mode signalizes the callback to work in memory allocation mode
  );
  TAudioCodecReconfigurationFlags = set of TAudioCodecReconfigurationFlag;

  // Audio Codec flags (element specific).
  TAudioCodecElementSpecificFlag = (
    aceUSAC_TW          =  0, // USAC time warped filter bank is active
    aceUSAC_Noise       =  1, // USAC noise filling is active
    aceUSAC_ITES        =  2, // USAC SBR inter-TES tool is active
    aceUSAC_PVC         =  3, // USAC SBR predictive vector coding tool is active
    aceUSAC_MPS212      =  4, // USAC MPS212 tool is active
    aceUSAC_LFE         =  5, // USAC element is LFE
    aceUSAC_CP_Possible =  6, // USAC may use Complex Stereo Prediction in this channel element
    aceEnhancedNoise    =  7, // Enhanced noise filling
    aceIGF_AfterTNS     =  8, // IGF after TNS
    aceIGF_IndepTiling  =  9, // IGF independent tiling
    aceIGF_UseENF       = 10, // IGF use enhanced noise filling
    aceFullbandLPD      = 11, // enable fullband LPD tools
    aceLPDStereoIdx     = 12, // LPD-stereo-tool stereo index
    aceLFE              = 13  // The element is of type LFE.
  );
  TAudioCodecElementSpecificFlags = set of TAudioCodecElementSpecificFlag;

  TCoderConfigFlag = (
    ccSBRCRC          = 16,
    ccSAC             = 17,
    ccMPEG_ID         = 20,
    ccIS_BASELAYER    = 21,
    ccPROTECTION      = 22,
    ccSBR             = 23,
    ccRVLC            = 24,
    ccVCB11           = 25,
    ccHCR             = 26,
    ccPSEUDO_SURROUND = 27,
    ccUSAC_NOISE      = 28,
    ccUSAC_TW         = 29,
    ccUSAC_HBE        = 30
  );
  TCoderConfigFlags = set of TCoderConfigFlag;

  // Generic audio coder configuration structure.
  TCoderConfig = record
    aot                   : TAudioObjectType; // Audio Object Type (AOT).
    extAOT                : TAudioObjectType; // Extension Audio Object Type (SBR).
    channelMode           : TChannelMode;     // Channel mode.
    channelConfigZero     : Byte;             // Use channel config zero + pce although a standard channel config could be signaled.
    samplingRate          : Integer;          // Sampling rate.
    extSamplingRate       : Integer;          // Extended samplerate (SBR).
    downscaleSamplingRate : Integer;          // Downscale sampling rate (ELD downscaled mode)

    bitRate               : Integer;          // Average bitrate.
    samplesPerFrame       : Integer;          // Number of PCM samples per codec frame and audio channel.
    noChannels            : Integer;          // Number of audio channels.
    bitsFrame             : Integer;
    nSubFrames            : Integer;          // Amount of encoder subframes. 1 means no subframing.
    BSACnumOfSubFrame     : Integer;          // The number of the sub-frames which are grouped and transmitted in a super-frame (BSAC).
    BSAClayerLength       : Integer;          // The average length of the large-step layers in bytes (BSAC).
    flags                 : Cardinal;         // flags
    matrixMixdownA        : Byte;             // Matrix mixdown index to put into PCE. Default value 0 means no mixdown coefficient, valid values are 1-4 which correspond to matrix_mixdown_idx 0-3.
    headerPeriod          : Byte;             // Frame period for sending in band configuration buffers in the transport layer.

    stereoConfigIndex     : Byte;                      // USAC MPS stereo mode
    sbrMode               : Byte;                      // USAC SBR mode
    sbrSignaling          : TSbrParametricStereoSignaling; // see above
    rawConfig             : array [0..63] of Byte;     // raw codec specific config as bit stream
    rawConfigBits         : Integer;                   // Size of rawConfig in bits
    sbrPresent            : Byte;
    psPresent             : Byte;
  end;

const
  USAC_ID_BIT = 16; // USAC element IDs start at USAC_ID_BIT

type
  // MP4 Element IDs.
  TMp4ElementID = (
    // mp4 element IDs
    idNone = -1, // Invalid Element helper ID.
    idSCE = 0,   // Single Channel Element.
    idCPE = 1,   // Channel Pair Element.
    idCCE = 2,   // Coupling Channel Element.
    idLFE = 3,   // LFE Channel Element.
    idDSE = 4,   // Currently one Data Stream Element for ancillary data is supported.
    idPCE = 5,   // Program Config Element.
    idFIL = 6,   // Fill Element.
    idEND = 7,   // Arnie (End Element = Terminator).
    idEXT = 8,   // Extension Payload (ER only).
    idSCAL = 9,  // AAC scalable element (ER only).

    // USAC element IDs
    idUSAC_SCE = 0 + USAC_ID_BIT, // Single Channel Element.
    idUSAC_CPE = 1 + USAC_ID_BIT, // Channel Pair Element.
    idUSAC_LFE = 2 + USAC_ID_BIT, // LFE Channel Element.
    idUSAC_EXT = 3 + USAC_ID_BIT, // Extension Element.
    idUSAC_END = 4 + USAC_ID_BIT  // Arnie (End Element = Terminator).
  );

  // usacConfigExtType q.v. ISO/IEC DIS 23008-3 Table 52  and  ISO/IEC FDIS 23003-3:2011(E) Table 74 */
  TConfigExtID = (
    // USAC and RSVD60 3DA
    ceFill = 0,
    // RSVD60 3DA
    ceDownMix = 1,
    ceLoudnessInfo = 2,
    ceAudiosceneInfo = 3,
    ceHoaMatrix = 4,
    ceSigGroupInfo = 6
    // 5-127 => reserved for ISO use
    // > 128 => reserved for use outside of ISO scope
  );

const
  EXT_ID_BITS = 4; // Size in bits of extension payload type tags.

  // Extension payload types.
type
  TEXT_PAYLOAD_TYPE = (
    EXT_FIL = $00,
    EXT_FILL_DATA = $01,
    EXT_DATA_ELEMENT = $02,
    EXT_DATA_LENGTH = $03,
    EXT_UNI_DRC = $04,
    EXT_LDSAC_DATA = $09,
    EXT_SAOC_DATA = $0a,
    EXT_DYNAMIC_RANGE = $0b,
    EXT_SAC_DATA = $0c,
    EXT_SBR_DATA = $0d,
    EXT_SBR_DATA_CRC = $0e
  );

  // MPEG-D USAC & RSVD60 3D audio Extension Element Types.
  TUSAC_EXT_ELEMENT_TYPE = (
    // usac
    ID_EXT_ELE_FILL = $00,
    ID_EXT_ELE_MPEGS = $01,
    ID_EXT_ELE_SAOC = $02,
    ID_EXT_ELE_AUDIOPREROLL = $03,
    ID_EXT_ELE_UNI_DRC = $04,

    // rsv603da
    ID_EXT_ELE_OBJ_METADATA = $05,
    ID_EXT_ELE_SAOC_3D = $06,
    ID_EXT_ELE_HOA = $07,
    ID_EXT_ELE_FMT_CNVRTR = $08,
    ID_EXT_ELE_MCT = $09,
    ID_EXT_ELE_ENHANCED_OBJ_METADATA = $0d,

    // reserved for use outside of ISO scope
    ID_EXT_ELE_VR_METADATA = $81,
    ID_EXT_ELE_UNKNOWN = $FF
  );

// Proprietary raw packet file configuration data type identifier.

  TP_CONFIG_TYPE = (
    TC_NOTHING = 0,  // No configuration available -> in-band configuration.
    TC_RAW_ADTS = 2, // Transfer type is ADTS.
    TC_RAW_LATM_MCP1 = 6, // Transfer type is LATM with SMC present.
    TC_RAW_SDC = 21       // Configuration data field is Drm SDC.
  );

type
  TFdkModuleID = (
    fmNone               = 0,
    fmTools              = 1,
    fmSysLib             = 2,
    fmAacDec             = 3,
    fmAacEnc             = 4,
    fmSbrDec             = 5,
    fmSbrEnc             = 6,
    fmTpDec              = 7,
    fmTpEnc              = 8,
    fmMpsDec             = 9,
    fmMpegFileRead       = 10,
    fmMpegFileWrite      = 11,
    fmMp2Dec             = 12,
    fmDabDec             = 13,
    fmDabParse           = 14,
    fmDrmDec             = 15,
    fmDrmParse           = 16,
    fmAacldEnc           = 17,
    fmMp2Enc             = 18,
    fmMp3Enc             = 19,
    fmMp3Dec             = 20,
    fmMp3Headphone       = 21,
    fmMp3SDec            = 22,
    fmMp3SEnc            = 23,
    fmEAEC               = 24,
    fmDabEnc             = 25,
    fmDmbDec             = 26,
    fmFDReverb           = 27,
    fmDrmEnc             = 28,
    fmMetaDataTranscoder = 29,
    fmAc3Dec             = 30,
    fmPcmDmx             = 31,
    fmMpsEnc             = 34,
    fmTdLimit            = 35,
    fmUniDrcDec          = 38
  );

  // AAC capability flags
  TAacCapabilityFlag = (
    acfAacLc           =  0, // Support flag for AAC Low Complexity.
    acfAacLD           =  1, // Support flag for AAC Low Delay with Error Resilience tools.
    acfErAacSCAL       =  2, // Support flag for AAC Scalable.
    acfErAacLC         =  3, // Support flag for AAC Low Complexity with Error Resilience tools.
    acfAac480          =  4, // Support flag for AAC with 480 framelength.
    acfAac512          =  5, // Support flag for AAC with 512 framelength.
    acfAac960          =  6, // Support flag for AAC with 960 framelength.
    acfAac1024         =  7, // Support flag for AAC with 1024 framelength.
    acfAacHCR          =  8, // Support flag for AAC with Huffman Codeword Reordering.
    acfAacVCB11        =  9, // Support flag for AAC Virtual Codebook 11.
    acfAacRVLC         = 10, // Support flag for AAC Reversible Variable Length Coding.
    acfAacMPEG4        = 11, // Support flag for MPEG file format.
    acfAacDRC          = 12, // Support flag for AAC Dynamic Range Control.
    acfAacConcealment  = 13, // Support flag for AAC concealment.
    acfAacDrmBSFormat  = 14, // Support flag for AAC DRM bistream format.
    acfErAacELD        = 15, // Support flag for AAC Enhanced Low Delay with Error Resilience tools.
    acfErAacBSAC       = 16, // Support flag for AAC BSAC.
    acfAacELDDownscale = 18, // Support flag for AAC-ELD Downscaling
    acfAacUSAC_LP      = 20, // Support flag for USAC low power mode.
    acfAacUSAC         = 21, // Support flag for Unified Speech and Audio Coding (USAC).
    acfErAacELDV2      = 23, // Support flag for AAC Enhanced Low Delay with MPS 212.
    acfAacUniDrc       = 24  // Support flag for MPEG-D Dynamic Range Control (uniDrc).
  );
  TAacCapabilityFlags = set of TAacCapabilityFlag;

  // Transport capability flags
  TTransportCapabilityFlag = (
    CAPF_ADTS       = 0, // Support flag for ADTS transport format.
    CAPF_ADIF       = 1, // Support flag for ADIF transport format.
    CAPF_LATM       = 2, // Support flag for LATM transport format.
    CAPF_LOAS       = 3, // Support flag for LOAS transport format.
    CAPF_RAWPACKETS = 4, // Support flag for RAW PACKETS transport format.
    CAPF_DRM        = 5, // Support flag for DRM/DRM+ transport format.
    CAPF_RSVD50     = 6  // Support flag for RSVD50 transport format
  );
  TTransportCapabilityFlags = set of TTransportCapabilityFlag;

  // SBR capability flags
  TSbrCapabilityFlag = (
    cfsLP            = 0, // Support flag for SBR Low Power mode.
    cfsHQ            = 1, // Support flag for SBR High Quality mode.
    cfsDRM_BS        = 2, // Support flag for
    cfsConcealment   = 3, // Support flag for SBR concealment.
    cfsDRC           = 4, // Support flag for SBR Dynamic Range Control.
    cfsPS_MPEG       = 5, // Support flag for MPEG Parametric Stereo.
    cfsPS_DRM        = 6, // Support flag for DRM Parametric Stereo.
    cfsELD_DOWNSCALE = 7, // Support flag for ELD reduced delay mode
    cfsHBEHQ         = 8  // Support flag for HQ HBE
  );
  TSbrCapabilityFlags = set of TSbrCapabilityFlag;

  // PCM utils capability flags
  TPcmUtilsCapabilityFlag = (
    cfpuBlind      =  0, // Support flag for blind downmixing.
    cfpuPCE        =  1, // Support flag for guided downmix with data from MPEG-2/4 Program Config Elements (PCE).
    cfpuARIB       =  2, // Support flag for PCE guided downmix with slightly different equations and levels to fulfill ARIB standard.
    cfpuDVB        =  3, // Support flag for guided downmix with data from DVB ancillary data fields.
    cfpuChannelExp =  4, // Support flag for simple upmixing by dublicating channels or adding zero channels.
    cfpu6Channel   =  5, // Support flag for 5.1 channel configuration (input and output).
    cfpu8Channel   =  6, // Support flag for 6 and 7.1 channel configurations (input and output).
    cfpu24Channel  =  7, // Support flag for 22.2 channel configuration (input and output).
    cfpuLimiter    = 13  // Support flag for signal level limiting.
  );
  TPcmUtilsCapabilityFlags = set of TPcmUtilsCapabilityFlag;


  // MPEG Surround capability flags
  TMpegSurroundCapabilityFlag = (
    cfmsSTD             =  0, // Support flag for MPEG Surround.
    cfmsLD              =  1, // Support flag for Low Delay MPEG Surround.
    cfmsUSAC            =  2, // Support flag for USAC MPEG Surround.

    cfmsHQ              =  4, // Support flag indicating if high quality processing is supported
    cfmsLP              =  5, // Support flag indicating if partially complex (low power) processing is supported
    cfmsBlind           =  6, // Support flag indicating if blind processing is supported
    cfmsBinaural        =  7, // Support flag indicating if binaural output is possible
    cfms2ChannelOutput  =  8, // Support flag indicating if 2ch output is possible
    cfms6ChannelOutput  =  9, // Support flag indicating if 6ch output is possible
    cfms8ChannelOutput  = 10, // Support flag indicating if 8ch output is possible

    cfms1ChannelInput   = 12, // Support flag indicating if 1ch dmx input is possible
    cfms2ChannelInput   = 13, // Support flag indicating if 2ch dmx input is possible
    cfms6ChannelInput   = 14  // Support flag indicating if 5ch dmx input is possible
  );
  TMpegSurroundCapabilityFlags = set of TMpegSurroundCapabilityFlag;

  TLibInfo = record
    title: PAnsiChar;
    build_date: PAnsiChar;
    build_time: PAnsiChar;
    module_id: TFdkModuleID;
    version: Cardinal;
    flags: Cardinal;
    versionStr: array[0..31] of AnsiChar;
  end;
  PLibInfo = ^TLibInfo;
  TLibInfoArray = array[TFdkModuleID] of TLibInfo;

  TFDK_bufDescr = record
    ppBase: Pointer;     // Pointer to an array containing buffer base addresses. Set to NULL for buffer requirement info.
    pBufSize: PCardinal; // Pointer to an array containing the number of elements that can be placed in the specific buffer.
    pEleSize: PCardinal; // Pointer to an array containing the element size for each buffer in bytes. That is mostly the number returned by the sizeof() operator for the data type used for the specific buffer.
    pBufType: PCardinal; // Pointer to an array of bit fields containing a description for each buffer. See XXX below for more details.
    numBufs: Cardinal;   // Total number of buffers.
  end;

  TAacEncCtrlFlag = (
    cfInitConfig    =  0, // Initialize all encoder modules configuration.
    cfInitStates    =  1, // Reset all encoder modules history buffer.
    cfInitTransport = 12, // Initialize transport lib with new parameters.
    cfResetInBuffer = 13  // Reset fill level of internal input buffer.
  );
  TAacEncCtrlFlags = set of TAacEncCtrlFlag;

  TAacEncoderParam = (
    aepAudioObjectType = $0100,
      (* Audio object type. See TAudioObjectType
        - 2: MPEG-4 AAC Low Complexity.
        - 5: MPEG-4 AAC Low Complexity with Spectral Band Replication (HE-AAC).
        - 23: MPEG-4 AAC Low-Delay.
        - 29: MPEG-4 AAC Low Complexity with Spectral Band Replication and Parametric Stereo (HE-AAC v2). This configuration can be used only with stereo input audio data.
        - 39: MPEG-4 AAC Enhanced Low-Delay. Since there is no
              TAudioObjectType for ELD in combination with SBR defined,
              enable SBR explicitely by aepSbrMode parameter. The ELD
              v2 212 configuration can be configured by aepChannelMode
              parameter.
        - 129: MPEG-2 AAC Low Complexity.
        - 132: MPEG-2 AAC Low Complexity with Spectral Band Replication (HE-AAC).

          Please note that the virtual MPEG-2 AOT's basically disables
        non-existing Perceptual Noise Substitution tool in AAC encoder
        and controls the MPEG_ID flag in adts header. The virtual
        MPEG-2 AOT doesn't prohibit specific transport formats. *)

    aepBitrate = $0101,
      (* Total encoder bitrate. This parameter is mandatory and interacts with aepBitrateMode.
           - CBR: Bitrate in bits/second.
           - VBR: Variable bitrate. Bitrate argument will be ignored. *)

    aepBitrateMode = $0102,
      (* Bitrate mode. Configuration can be different kind of bitrate configurations:
           - 0: Constant bitrate, use bitrate according to aepBitrate. (default)
                Within none LD/ELD TAudioObjectType, the CBR mode makes
                use of full allowed bitreservoir. In contrast,
                at Low-Delay TAudioObjectType the bitreservoir is kept very small.
           - 1: Variable bitrate mode, "very low bitrate".
           - 2: Variable bitrate mode, "low bitrate".
           - 3: Variable bitrate mode, "medium bitrate".
           - 4: Variable bitrate mode, "high bitrate".
           - 5: Variable bitrate mode, "very high bitrate". *)

    aepSamplerate = $0103,
      (* Audio input data sampling rate. Encoder supports following sampling rates:
           8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 64000, 88200, 96000 *)

    aepSbrMode = $0104,
      (* Configure SBR independently of the chosen Audio Object Type TAudioObjectType. This parameter is for ELD audio object type only.
           - -1: Use ELD SBR auto configurator (default).
           - 0: Disable Spectral Band Replication.
           - 1: Enable Spectral Band Replication. *)

    aepGranuleLength = $0105,
      (* Core encoder (AAC) audio frame length in samples:
           - 1024: Default configuration.
           - 512: Default length in LD/ELD configuration.
           - 480: Length in LD/ELD configuration.
           - 256: Length for ELD reduced delay mode (x2).
           - 240: Length for ELD reduced delay mode (x2).
           - 128: Length for ELD reduced delay mode (x4).
           - 120: Length for ELD reduced delay mode (x4). *)

    aepChannelMode = $0106,
      (* Set explicit channel mode. Channel mode must match with number of input channels.
           - 1-7, 11,12,14 and 33,34: MPEG channel modes supported, see TChannelMode *)

    aepChannelOrder = $0107,
      (* Input audio data channel ordering scheme:
           - 0: MPEG channel ordering (e. g. 5.1: C, L, R, SL, SR, LFE). (default)
           - 1: WAVE file format channel ordering (e. g. 5.1: L, R, C, LFE, SL, SR). *)

    aepSbrRatio = $0108,
      (* Controls activation of downsampled SBR. With downsampled
         SBR, the delay will be shorter. On the other hand, for
         achieving the same quality level, downsampled SBR needs more
         bits than dual-rate SBR. With downsampled SBR, the AAC encoder
         will work at the same sampling rate as the SBR encoder (single
         rate). Downsampled SBR is supported for AAC-ELD and HE-AACv1.
           - 1: Downsampled SBR (default for ELD).
           - 2: Dual-rate SBR   (default for HE-AAC). *)

    aepAfterburner = $0200,
      (* This parameter controls the use of the afterburner feature.
           The afterburner is a type of analysis by synthesis algorithm
         which increases the audio quality but also the required
         processing power. It is recommended to always activate this if
         additional memory consumption and processing power consumption
         is not a problem. If increased MHz and memory consumption are
         an issue then the MHz and memory cost of this optional module
         need to be evaluated against the improvement in audio quality
         on a case by case basis.
           - 0: Disable afterburner (default).
           - 1: Enable afterburner. *)

    aepBandwidth = $0203,
      (* Core encoder audio bandwidth:
           - 0: Determine audio bandwidth internally (default, see chapter \ref BEHAVIOUR_BANDWIDTH).
           - 1 to fs/2: Audio bandwidth in Hertz. Limited to 20kHz max. Not usable if SBR is active.
         This setting is for experts only, better do not touch this value to avoid degraded audio quality. *)

    aepPeakBitrate = $0207,
      (* Peak bitrate configuration parameter to adjust maximum bits
         per audio frame. Bitrate is in bits/second. The peak bitrate
         will internally be limited to the chosen bitrate aepBitrate as lower limit and the
         number_of_effective_channels*6144 bit as upper limit.
           Setting the peak bitrate equal to aepBitrate does not
         necessarily mean that the audio frames will be of constant
         size. Since the peak bitate is in bits/second, the frame sizes
         can vary by one byte in one or the other direction over various
         frames. However, it is not recommended to reduce the peak
         pitrate to aepBitrate - it would disable the
         bitreservoir, which would affect the audio quality by a large
         amount. *)

    aepTransmux = $0300,
      (* Transport type to be used. See TTransportType. Following types can be configured in encoder library:
           - 0: raw access units
           - 1: ADIF bitstream format
           - 2: ADTS bitstream format
           - 6: Audio Mux Elements (LATM) with muxConfigPresent = 1
           - 7: Audio Mux Elements (LATM) with muxConfigPresent = 0, out of band StreamMuxConfig
           - 10: Audio Sync Stream (LOAS) *)

    aepHeaderPeriod = $0301,
      (* Frame count period for sending in-band configuration buffers
         within LATM/LOAS transport layer. Additionally this parameter
         configures the PCE repetition period in raw_data_block()..
           - $FF: auto-mode default 10 for TT_MP4_ADTS, TT_MP4_LOAS and TT_MP4_LATM_MCP1, otherwise 0.
           - n: Frame count period. *)

    aepSignalingMode = $0302,
      (* Signaling mode of the extension AOT:
           - 0: Implicit backward compatible signaling (default for non-MPEG-4 based AOT's and for the transport formats ADIF and ADTS)
                - A stream that uses implicit signaling can be decoded by every AAC decoder, even AAC-LC-only decoders
                - An AAC-LC-only decoder will only decode the low-frequency part of the stream, resulting in a band-limited output
                - This method works with all transport formats
                - This method does not work with downsampled SBR
           - 1: Explicit backward compatible signaling
                - A stream that uses explicit backward compatible signaling can be decoded by every AAC decoder, even AAC-LC-only decoders
                - An AAC-LC-only decoder will only decode the low-frequency part of the stream, resulting in a band-limited output
                - A decoder not capable of decoding PS will only decode the AAC-LC+SBR part. If the stream contained PS, the result will be a a decoded mono downmix
                - This method does not work with ADIF or ADTS. For LOAS/LATM, it only works with AudioMuxVersion==1
                - This method does work with downsampled SBR
          - 2: Explicit hierarchical signaling (default for MPEG-4 based AOT's and for all transport formats excluding ADIF and ADTS)
                - A stream that uses explicit hierarchical signaling can be decoded only by HE-AAC decoders
                - An AAC-LC-only decoder will not decode a stream that uses explicit hierarchical signaling
                - A decoder not capable of decoding PS will not decode the stream at all if it contained PS
                - This method does not work with ADIF or ADTS. It works with LOAS/LATM and the MPEG-4 File format
                - This method does work with downsampled SBR

             For making sure that the listener always experiences the
           best audio quality, explicit hierarchical signaling should be
           used. This makes sure that only a full HE-AAC-capable decoder
           will decode those streams. The audio is played at full
           bandwidth. For best backwards compatibility, it is recommended
           to encode with implicit SBR signaling. A decoder capable of
           AAC-LC only will then only decode the AAC part, which means the
           decoded audio will sound band-limited.
              For MPEG-2 transport types (ADTS,ADIF), only implicit
           signaling is possible.
              For LOAS and LATM, explicit backwards compatible signaling
           only works together with AudioMuxVersion==1. The reason is
           that, for explicit backwards compatible signaling, additional
           information will be appended to the ASC. A decoder that is only
           capable of decoding AAC-LC will skip this part. Nevertheless,
           for jumping to the end of the ASC, it needs to know the ASC
           length. Transmitting the length of the ASC is a feature of
           AudioMuxVersion==1, it is not possible to transmit the length
           of the ASC with AudioMuxVersion==0, therefore an AAC-LC-only
           decoder will not be able to parse a LOAS/LATM stream that was
           being encoded with AudioMuxVersion==0.
              For downsampled SBR, explicit signaling is mandatory. The
           reason for this is that the extension sampling frequency (which
           is in case of SBR the sampling frequqncy of the SBR part) can
           only be signaled in explicit mode.
              For AAC-ELD, the SBR information is transmitted in the
           ELDSpecific Config, which is part of the AudioSpecificConfig.
           Therefore, the settings here will have no effect on AAC-ELD.*)

    aepTpSubframes = $0303,
      (* Number of sub frames in a transport frame for LOAS/LATM or ADTS (default 1).
           - ADTS: Maximum number of sub frames restricted to 4.
           - LOAS/LATM: Maximum number of sub frames restricted to 2.*)

    aepAudioMuxVer = $0304,
      (* AudioMuxVersion to be used for LATM. (AudioMuxVersionA, currently not implemented):
           - 0: Default, no transmission of tara Buffer fullness, no ASC length and including actual latm Buffer fullnes.
           - 1: Transmission of tara Buffer fullness, ASC length and actual latm Buffer fullness.
           - 2: Transmission of tara Buffer fullness, ASC length and maximum level of latm Buffer fullness. *)

    aepProtection = $0306,
      (* Configure protection in transport layer:
           - 0: No protection. (default)
           - 1: CRC active for ADTS transport format. *)

    aepAncillaryBitrate = $0500,
      (* Constant ancillary data bitrate in bits/second.
           - 0: Either no ancillary data or insert exact number of bytes,
                denoted via input parameter, numAncBytes in aepInArgs.
           - else: Insert ancillary data with specified bitrate. *)

    aepMetadataMode = $0600,
      (* Configure Meta Data. See aepMetaData for further details:
           - 0: Do not embed any metadata.
           - 1: Embed dynamic_range_info metadata.
           - 2: Embed dynamic_range_info and ancillary_data metadata.
           - 3: Embed ancillary_data metadata. *)

    aepControlState = $FF00,
      (* There is an automatic process which internally reconfigures
         the encoder instance when a configuration parameter changed or
         an error occured. This paramerter allows overwriting or getting
         the control status of this process. See TAacEncCtrlFlags. *)

    aepNone = $FFFF (* ------ *)
  );

type
(*
  AAC encoder buffer descriptors identifier.
  This identifier are used within buffer descriptors
  AACENC_BufDesc::bufferIdentifiers.
*)
  TAacEncBufferIdentifier = (
    // Input buffer identifier.
    biInAudioData = 0,     // Audio input buffer, interleaved INT_PCM samples.
    biInAncillaryData = 1, // Ancillary data to be embedded into bitstream.
    biInMetadataSetup = 2, // Setup structure for embedding meta data.

    // Output buffer identifier.
    biOutBitstreamData = 3, // Buffer holds bitstream output data.
    biOutAccessUnitSizes = 4 // Buffer contains sizes of each access unit. This information is necessary for superframing.
  );
  PAacEncBufferIdentifier = ^TAacEncBufferIdentifier;

  // Provides some info about the encoder configuration.
  TAacEncInfoStruct = record
    maxOutBufBytes: Cardinal;
      (* Maximum number of encoder bitstream bytes within one frame.
         Size depends on maximum number of supported channels in encoder instance. *)

    maxAncBytes: Cardinal;
      (* Maximum number of ancillary data bytes which can be
         inserted into bitstream within one frame. *)

    inBufFillLevel: Cardinal;
      (* Internal input buffer fill level in samples per channel.
         This parameter will automatically be cleared if samplingrate
         or channel(Mode/Order) changes. *)

    inputChannels: Cardinal;
      (* Number of input channels expected in encoding process. *)

    frameLength: Cardinal;
      (* Amount of input audio samples consumed each frame per
         channel, depending on audio object type configuration. *)

    nDelay: Cardinal;
      (* Codec delay in PCM samples/channel. Depends on framelength
         and AOT. Does not include framing delay for filling up encoder
         PCM input buffer. *)

    nDelayCore: Cardinal;
      (* Codec delay in PCM samples/channel, w/o delay caused by
         the decoder SBR module. This delay is needed to correctly
         write edit lists for gapless playback. The decoder may not
         know how much delay is introdcued by SBR, since it may not
         know if SBR is active at all (implicit signaling),
         therefore the deocder must take into account any delay
         caused by the SBR module. *)

    confBuf: array [0..63] of Byte;
      (* Configuration buffer in binary format as an
         AudioSpecificConfig or StreamMuxConfig according to the
         selected transport type. *)

    confSize: Cardinal;
      (* Number of valid bytes in confBuf. *)
  end;

  // Describes the input and output buffers for an aacEncEncode() call.
  TAacEncBufDesc = record
    numBufs: Integer; // Number of buffers.
    bufs: PPointer; // Pointer to vector containing buffer addresses.
    bufferIdentifiers: PAacEncBufferIdentifier; // Identifier of each buffer element.
    bufSizes: PInteger; // Size of each buffer in 8-bit bytes.
    bufElSizes: PInteger; // Size of each buffer element in bytes.
  end;
  PAacEncBufDesc = ^TAacEncBufDesc;

  // Defines the input arguments for an aacEncEncode() call.
  TAacEncInArgs = record
    numInSamples: Integer; // Number of valid input audio samples (multiple of input channels).
    numAncBytes: Integer;  // Number of ancillary data bytes to be encoded.
  end;
  PAacEncInArgs = ^TAacEncInArgs;

  //  Defines the output arguments for an aacEncEncode() call.
  TAacEncOutArgs = record
    numOutBytes: Integer;  // Number of valid bitstream bytes generated during aacEncEncode().
    numInSamples: Integer; // Number of input audio samples consumed by the encoder.
    numAncBytes: Integer;  // Number of ancillary data bytes consumed by the encoder.
    bitResState: Integer;  // State of the bit reservoir in bits.
  end;
  PAacEncOutArgs = ^TAacEncOutArgs;

  // Meta Data Compression Profiles.
  TAacEncMetaDataDrcProfile = (
    mdNone          = 0,   // None.
    mdFilmStandard  = 1,   // Film standard.
    mdFilmLight     = 2,   // Film light.
    mdMusicStandard = 3,   // Music standard.
    mdMusicLight    = 4,   // Music light.
    mdSpeech        = 5,   // Speech.
    mdNotPresent    = 256  // Disable writing gain factor (used for comp_profile only).
  );

  // Meta Data setup structure.
  TAacEncMetaData = record
    drc_profile: TAacEncMetaDataDrcProfile;  // MPEG DRC compression profile.
    comp_profile: TAacEncMetaDataDrcProfile; // ETSI heavy compression profile.

    drc_TargetRefLevel: Integer;  // Used to define expected level to: Scaled with 16 bit. x*2^16.
    comp_TargetRefLevel: Integer; // Adjust limiter to avoid overload. Scaled with 16 bit. x*2^16.

    prog_ref_level_present: Integer; (* Flag, if prog_ref_level is present *)
    prog_ref_level: Integer;         (* Programme Reference Level = Dialogue Level:
                                     -31.75dB .. 0 dB ; stepsize: 0.25dB
                                     Scaled with 16 bit. x*2^16.*)

    PCE_mixdown_idx_present: Byte; // Flag, if dmx-idx should be written in programme config element
    ETSI_DmxLvl_present: Byte;     // Flag, if dmx-lvl should be written in ETSI-ancData

    centerMixLevel: ShortInt; (* Center downmix level (0...7, according to table) *)
    surroundMixLevel: ShortInt; (* Surround downmix level (0...7, according to
                               table) *)

    dolbySurroundMode: Byte; (* Indication for Dolby Surround Encoding Mode.
                            - 0: Dolby Surround mode not indicated
                            - 1: 2-ch audio part is not Dolby surround encoded
                            - 2: 2-ch audio part is Dolby surround encoded *)

    drcPresentationMode: Byte; (* Indicatin for DRC Presentation Mode.
                                    - 0: Presentation mode not inticated
                                    - 1: Presentation mode 1
                                    - 2: Presentation mode 2 *)
    ExtMetaData: record
      (* extended ancillary data *)
      extAncDataEnable: Byte; (* Indicates if MPEG4_ext_ancillary_data() exists.
                                  - 0: No MPEG4_ext_ancillary_data().
                                  - 1: Insert MPEG4_ext_ancillary_data(). *)

      extDownmixLevelEnable: Byte;   (* Indicates if ext_downmixing_levels() exists.
                                   - 0: No ext_downmixing_levels().
                                   - 1: Insert ext_downmixing_levels(). *)
      extDownmixLevel_A: Byte; (* Downmix level index A (0...7, according to
                                  table) *)
      extDownmixLevel_B: Byte; (* Downmix level index B (0...7, according to
                                  table) *)

      dmxGainEnable: Byte; (* Indicates if ext_downmixing_global_gains() exists.
                               - 0: No ext_downmixing_global_gains().
                               - 1: Insert ext_downmixing_global_gains(). *)
      dmxGain5: Integer;        (* Gain factor for downmix to 5 channels.
                                -15.75dB .. -15.75dB; stepsize: 0.25dB
                                Scaled with 16 bit. x*2^16.*)
      dmxGain2: Integer;        (* Gain factor for downmix to 2 channels.
                                -15.75dB .. -15.75dB; stepsize: 0.25dB
                                Scaled with 16 bit. x*2^16.*)

      lfeDmxEnable: Byte; (* Indicates if ext_downmixing_lfe_level() exists.
                              - 0: No ext_downmixing_lfe_level().
                              - 1: Insert ext_downmixing_lfe_level(). *)
      lfeDmxLevel: Byte;
        (* Downmix level index for LFE (0..15, according to table) *)
    end;
  end;

  TAacDecodeFrameFlag = (
    dfDoConcealment        = 0,
    dfFlushFilterBanks     = 1,
    dfInputDataIsContinous = 2,
    dfClearHistoryBuffers  = 3
  );
  TAacDecodeFrameFlags = set of TAacDecodeFrameFlag;

  TAacMD_PROFILE = (
    AacMD_PROFILE_MPEG_STANDARD = 0,
      (* The standard profile creates a mixdown signal based on the advanced
         downmix metadata (from a DSE). The equations and default values are
         defined in ISO/IEC 14496:3 Ammendment 4. Any other (legacy) downmix
         metadata will be ignored. No other parameter will be modified. *)
    AacMD_PROFILE_MPEG_LEGACY = 1,
      (* This profile behaves identical to the standard profile if advanced
         downmix metadata (from a DSE) is available. If not, the matrix_mixdown
         information embedded in the program configuration element (PCE) will
         be applied. If neither is the case, the module creates a mixdown using
         the default coefficients as defined in ISO/IEC 14496:3 AMD 4.
         The profile can be used to support legacy digital TV (e.g. DVB) streams. *)
    AacMD_PROFILE_MPEG_LEGACY_PRIO = 2,
      (* Similar to the ::AacMD_PROFILE_MPEG_LEGACY profile but if both
         the advanced (ISO/IEC 14496:3 AMD 4) and the legacy (PCE) MPEG
         downmix metadata are available the latter will be applied. *)

    AacMD_PROFILE_ARIB_JAPAN = 3
      (* Downmix creation as described in ABNT NBR 15602-2. But if advanced
         downmix metadata (ISO/IEC 14496:3 AMD 4) is available it will be
         preferred because of the higher resolutions. In addition the
         metadata expiry time will be set to the value defined in the ARIB
         standard (see ::AacMETADATA_EXPIRY_TIME). *)
  );

  TAacDrcDefaultPresentationModeOptions = (
    adParameterHandlingDisabled = -1,
      (* DRC parameter handling disabled, all parameters are applied as requested. *)
    adParameterHandlingEnabled = 0,
      (* Apply changes to requested DRC parameters to prevent clipping. *)
    adPresentationMode1Default = 1,
      (* Use DRC presentation mode 1 as default (e.g. for Nordig) *)
    adPresentationMode2Default = 2
      (* Use DRC presentation mode 2 as default (e.g. for DTG DBook) *)
  );

  TAacDecoderParam = (
    dpPcmDualChannelOutputMode = $0002,
      (* Defines how the decoder processes two channel signals:
           0: Leave both signals as they are (default).
           1: Create a dual mono output signal from channel 1.
           2: Create a dual mono output signal from channel 2.
           3: Create a dual mono output signal by mixing both channels
           (L' = R' = 0.5*Ch1 + 0.5*Ch2). *)

    dpPcmOutputChannelMapping = $0003,
      (* Output buffer channel ordering.
           0: MPEG PCE style order,
           1: WAV file channel order (default). *)

    dpPcmLimiterEnable = $0004,
      (* Enable signal level limiting.
           -1: Auto-config. Enable limiter for all non-lowdelay configurations by default.
            0: Disable limiter in general.
            1: Enable limiter always.
         It is recommended to call the decoder with a AACDEC_CLRHIST flag to
         reset all states when the limiter switch is changed explicitly. *)

    dpPcmLimiterAttackTime = $0005,
      (* Signal level limiting attack time in ms.
         Default configuration is 15 ms.
         Adjustable range from 1 ms to 15 ms. *)

    dpPcmLimiterReleaseTime = $0006,
      (* Signal level limiting release time in ms.
         Default configuration is 50 ms.
         Adjustable time must be larger than 0 ms. *)

    dpPcmMinOutputChannels = $0011,
      (* Minimum number of PCM output channels. If higher than the
         number of encoded audio channels, a simple channel extension is
         applied (see note 4 for exceptions).
           -1, 0: Disable channel extension feature. The decoder output contains the same number of channels as the encoded bitstream.
               1: This value is currently needed only together with the mix-down feature. See ::dpPcmMAX_OUTPUT_CHANNELS and note 2 below.
               2: Encoded mono signals will be duplicated to achieve a 2/0/0.0 channel output configuration.
               6: The decoder tries to reorder encoded signals with less than six channels to achieve a 3/0/2.1 channel output signal.
                  Missing channels will be filled with a zero signal. If reordering is not possible the empty channels will simply be appended.
                  Only available if instance is configured to support multichannel output.
               8: The decoder tries to reorder encoded signals with less than eight channels to achieve a 3/0/4.1 channel output signal.
                  Missing channels will be filled with a zero signal. If reordering is not possible the empty channels will simply be appended.
                  Only available if instance is configured to support multichannel output.
         NOTE:
           1. The channel signaling (CStreamInfo::pChannelType and
              CStreamInfo::pChannelIndices) will not be modified. Added empty
              channels will be signaled with channel type AUDIO_CHANNEL_TYPE::ACT_NONE.
           2. If the parameter value is greater than that of
              ::dpPcmMAX_OUTPUT_CHANNELS both will be set to the same value.
           3. This parameter will be ignored if the number of encoded audio channels is greater than 8. *)

    dpPcmMaxOutputChannels = $0012,
      (* Maximum number of PCM output channels. If lower than the
         number of encoded audio channels, downmixing is applied
         accordingly (see note 5 for exceptions). If dedicated metadata
         is available in the stream it will be used to achieve better
         mixing results.
           -1, 0: Disable downmixing feature. The decoder output contains the same number of channels as the encoded bitstream.
               1: All encoded audio configurations with more than one channel will be mixed down to one mono output signal.
               2: The decoder performs a stereo mix-down if the number encoded audio channels is greater than two.
               6: If the number of encoded audio channels is greater than six the decoder performs a mix-down to meet the target output configuration of 3/0/2.1 channels.
                  Only available if instance is configured to support multichannel output.
               8: This value is currently needed only together with the channel extension feature. See ::dpPcmMIN_OUTPUT_CHANNELS and note 2 below.
                  Only available if instance is configured to support multichannel output.
         NOTE:
           1. Down-mixing of any seven or eight channel configuration not defined in
              ISO/IEC 14496-3 PDAM 4 is not supported by this software version.
           2. If the parameter value is greater than zero but smaller than
              ::dpPcmMIN_OUTPUT_CHANNELS both will be set to same value.
           3. This parameter will be ignored if the number of encoded audio
              channels is greater than 8. *)

    dpMetadataProfile = $0020,
      (* See ::AacMD_PROFILE for all available values. *)

    dpMetadataExpiryTime = $0021,
      (* Defines the time in ms after which all the bitstream associated
         meta-data (DRC, downmix coefficients, ...) will be reset to default if
         no update has been received. Negative values disable the feature. *)

    dpConcealMethod = $0100,
      (* Error concealment: Processing method.
           0: Spectral muting.
           1: Noise substitution (see ::CONCEAL_NOISE).
           2: Energy interpolation (adds additional signal delay of one frame,
              see ::CONCEAL_INTER. only some AOTs are supported). *)

    dpDrcBoostFactor = $0200,
      (* MPEG-4 / MPEG-D Dynamic Range Control (DRC):
           Scaling factor for boosting gain values. Defines how the boosting
           DRC factors (conveyed in the bitstream) will be applied to the
           decoded signal. The valid values range from 0 (don't apply boost
           factors) to 127 (fully apply boost factors). Default value is 0
           for MPEG-4 DRC and 127 for MPEG-D DRC. *)

    dpDrcAttenuationFactor = $0201,
      (* MPEG-4 / MPEG-D DRC: Scaling factor for attenuating gain values.
         Same as ::AacDRC_BOOST_FACTOR but for attenuating DRC factors. *)

    dpDrcReferenceLevel = $0202,
      (* MPEG-4 / MPEG-D DRC: Target reference level / decoder target loudness.
         Defines the level below full-scale (quantized in steps of 0.25dB) to
         which the output audio signal will be normalized to by the DRC module.
           The parameter controls loudness normalization for both MPEG-4 DRC and
         MPEG-D DRC. The valid values range from 40 (-10 dBFS) to 127 (-31.75 dBFS).
           Example values:
             124 (-31 dBFS) for audio/video receivers (AVR) or other
                   devices allowing audio playback with high dynamic range,
             96  (-24 dBFS) for TV sets or equivalent devices (default),
             64  (-16 dBFS) for mobile devices where the dynamic range of audio
                   playback is restricted.
         Any value smaller than 0 switches off loudness normalization and MPEG-4 DRC. *)

    dpDrcHeavyCompression = $0203,
      (* MPEG-4 DRC: En-/Disable DVB specific heavy compression (aka RF mode).
         If set to 1, the decoder will apply the compression values from the
         DVB specific ancillary data field. At the same time the MPEG-4
         Dynamic Range Control tool will be disabled. By default, heavy
         compression is disabled. *)

    dpDrcDefaultPresentationMode = $0204,
      (* MPEG-4 DRC: Default presentation mode (DRC parameter handling).
         Defines the handling of the DRC parameters boost factor, attenuation
         factor and heavy compression, if no presentation mode is indicated in
         the bitstream.
           For options, see ::AacDrcDEFAULT_PRESENTATION_MODE_OPTIONS.
         Default:
           ::AacDrcPARAMETER_HANDLING_DISABLED *)

    dpDrcEncTargetLevel = $0205,
      (* MPEG-4 DRC: Encoder target level for light (i.e. not heavy)
         compression.
           If known, this declares the target reference
         level that was assumed at the encoder for calculation of
         limiting gains. The valid values range from 0 (full-scale) to
         127 (31.75 dB below full-scale). This parameter is used only
         with ::AacDrcPARAMETER_HANDLING_ENABLED and ignored
         otherwise.
           Default: 127 (worst-case assumption). *)

    dpUniDrcSetEffect = $0206,
      (* MPEG-D DRC: Request a DRC effect type for selection of a DRC set.
         Supported indices are:
           -1: DRC off. Completely disables MPEG-D DRC.
            0: None (default). Disables MPEG-D DRC, but automatically enables DRC if necessary to prevent clipping.
            1: Late night
            2: Noisy environment
            3: Limited playback range
            4: Low playback level
            5: Dialog enhancement
            6: General compression. Used for generally enabling MPEG-D DRC without particular request. *)

    dpUniDrcAlbumMode = $0207,
      (*  MPEG-D DRC: Enable album mode.
            0: Disabled (default),
            1: Enabled.
         Disabled album mode leads to application of gain sequences for fading
         in and out, if provided in the bitstream.
           Enabled album mode makes use of dedicated album loudness information,
         if provided in the bitstream. *)

    dpQmfLowPower = $0300,
      (* Quadrature Mirror Filter (QMF) Bank processing mode.
           -1: Use internal default.
            0: Use complex QMF data mode.
            1: Use real (low power) QMF data mode. *)

    AacTpDecClearBuffer = $0603
      (* Clear internal bit stream buffer of transport layers.
         The decoder will start decoding at new data passed after this event
         and any previous data is discarded. *)
  );

  TStreamInfo = record
    (* These five members are the only really relevant ones for the user. *)
    sampleRate: Integer; (* The sample rate in Hz of the decoded PCM audio signal. *)
    frameSize: Integer;
      (* The frame size of the decoded PCM audio signal. Typically this is:
           1024 or 960 for AAC-LC
           2048 or 1920 for HE-AAC (v2)
           512 or 480 for AAC-LD and AAC-ELD
           768, 1024, 2048 or 4096 for USAC  *)
    numChannels: Integer;
      (* The number of output audio channels before the rendering module,
         i.e. the original channel configuration. *)
    pChannelType: PAudioChannelType; // Audio channel type of each output audio channel.
    pChannelIndices: PByte; (* Audio channel index for each output audio
                               channel. See ISO/IEC 13818-7:2005(E), 8.5.3.2
                               Explicit channel mapping using a
                               program_config_element() *)

    (* Decoder internal members. *)
    aacSampleRate: Integer; (* Sampling rate in Hz without SBR (from configuration
                          info) divided by a (ELD) downscale factor if present. *)
    profile: Integer; // MPEG-2 profile (from file header) (-1: not applicable (e. g. MPEG-4)).

    aot: TAudioObjectType;
      (* Audio Object Type (from ASC): is set to the appropriate
         value for MPEG-2 bitstreams (e. g. 2 for AAC-LC). *)
    channelConfig: Integer;
      (* Channel configuration (0: PCE defined, 1: mono, 2: stereo, ... *)
    bitRate: Integer; // Instantaneous bit rate.
    aacSamplesPerFrame: Integer;
      (* Samples per frame for the AAC core (from ASC) divided by a (ELD) downscale factor if present.
         Typically this is (with a downscale factor of 1):
             1024 or 960 for AAC-LC
             512 or 480 for  AAC-LD and AAC-ELD         *)
    aacNumChannels: Integer;
      (* The number of audio channels after AAC core processing (before PS or MPS processing).
         CAUTION: This are not the final number of output channels! *)
    extAot: TAudioObjectType; // Extension Audio Object Type (from ASC)
    extSamplingRate: Integer; (* Extension sampling rate in Hz (from ASC) divided by
                            a (ELD) downscale factor if present. *)

    outputDelay: Cardinal; (* The number of samples the output is additionally
                         delayed by.the decoder. *)
    flags: Cardinal; (* Copy of internal flags. Only to be written by the decoder,
                   and only to be read externally. *)

    epConfig: ShortInt; (* epConfig level (from ASC): only level 0 supported, -1
                       means no ER (e. g. AOT=2, MPEG-2 AAC, etc.)  *)

    (* Statistics *)
    numLostAccessUnits: Integer; (* This integer will reflect the estimated amount of
                               lost access units in case aacDecoder_DecodeFrame()
                                 returns AacDEC_TRANSPORT_SYNC_ERROR. It will be
                               < 0 if the estimation failed. *)

    numTotalBytes: INT64; (* This is the number of total bytes that have passed
                            through the decoder. *)
    numBadBytes: INT64; (* This is the number of total bytes that were considered
                    with errors from numTotalBytes. *)
    numTotalAccessUnits: INT64;  (* This is the number of total access units that
                                have passed through the decoder. *)
    numBadAccessUnits: INT64; (* This is the number of total access units that
                                were considered with errors from numTotalBytes. *)

    (* Metadata *)
    drcProgRefLev: ShortInt; (* DRC program reference level. Defines the reference
                            level below full-scale. It is quantized in steps of
                            0.25dB. The valid values range from 0 (0 dBFS) to 127
                            (-31.75 dBFS). It is used to reflect the average
                            loudness of the audio in LKFS according to ITU-R BS
                            1770. If no level has been found in the bitstream the
                            value is -1. *)

    drcPresMode: ShortInt;
      (* DRC presentation mode. According to ETSI TS 101 154, this field indicates
         whether light (MPEG-4 Dynamic Range Control tool) or heavy compression
         (DVB heavy compression) dynamic range control shall take priority on the outputs.
         For details, see ETSI TS 101 154, table C.33. Possible values are:
           -1: No corresponding metadata found in the bitstream
            0: DRC presentation mode not indicated
            1: DRC presentation mode 1
            2: DRC presentation mode 2
            3: Reserved
      *)

    outputLoudness: Integer;
      (* Audio output loudness in steps of -0.25 dB. Range: 0 (0 dBFS) to 231 (-57.75 dBFS).
         A value of -1 indicates that no loudness metadata is present.
         If loudness normalization is active, the value corresponds to the target loudness value set with ::AacDRC_REFERENCE_LEVEL.
         If loudness normalization is not active, the output loudness value corresponds to the loudness metadata given in the bitstream.
         Loudness metadata can originate from MPEG-4 DRC or MPEG-D DRC. *)
  end;
  PStreamInfo = ^TStreamInfo;

  TUserParam = record
    userAOT: TAudioObjectType; // Audio Object Type.
    userSamplerate: Cardinal;       // Sampling frequency.
    nChannels: Cardinal;            // will be set via channelMode.
    userChannelMode: TChannelMode;
    userBitrate: Cardinal;
    userBitrateMode: Cardinal;
    userBandwidth: Cardinal;
    userAfterburner: Cardinal;
    userFramelength: Cardinal;
    userAncDataRate: Cardinal;
    userPeakBitrate: Cardinal;
    userTns: Byte;       // Use TNS coding.
    userPns: Byte;       // Use PNS coding.
    userIntensity: Byte; //  Use Intensity coding.
    userTpType: TTransportType; // Transport type
    userTpSignaling: Byte;      // Extension AOT signaling mode.
    userTpNsubFrames: Byte;     // Number of sub frames in a transport frame for LOAS/LATM or ADTS (default 1).
    userTpAmxv: Byte;           // AudioMuxVersion to be used for LATM (default 0).
    userTpProtection: Byte;
    userTpHeaderPeriod: Byte;   // Parameter used to configure LATM/LOAS SMC rate. Moreover this parameters is used to configure repetition rate of PCE in raw_data_block.
    userErTools: Byte;          // Use VCB11, HCR and/or RVLC ER tool.
    userPceAdditions: Cardinal; // Configure additional bits in PCE.
    userMetaDataMode: Byte;     // Meta data library configuration.
    userSbrEnabled: Byte;       // Enable SBR for ELD.
    userSbrRatio: Cardinal;     // SBR sampling rate ratio. Dual- or single-rate.
    userDownscaleFactor: Cardinal;
  end;

  TAacDecoderInstance = record
    aacChannels: Integer;                // Amount of AAC decoder channels allocated.
    ascChannels: array[0..0] of Integer; // Amount of AAC decoder channels signalled in ASC.
    blockNumber: Integer;                // frame counter
    nrOfLayers: Integer;
    outputInterleaved: Integer ;         // PCM output format (interleaved/none interleaved).

(*
    hInput: HANDLE_TRANSPORTDEC; // Transport layer handle.

  SamplingRateInfo
      samplingRateInfo[(1 * 1)]; // Sampling Rate information table

  UCHAR
  frameOK; // Will be unset if a consistency check, e.g. CRC etc. fails

  UINT flags[(1 * 1)]; // Flags for internal decoder use. DO NOT USE
                          self::streaminfo::flags !
  UINT elFlags[(3 * ((8) * 2) + (((8) * 2)) / 2 + 4 * (1) +
                1)]; // Flags for internal decoder use (element specific). DO
                        NOT USE self::streaminfo::flags !

  MP4_ELEMENT_ID elements[(3 * ((8) * 2) + (((8) * 2)) / 2 + 4 * (1) +
                           1)]; // Table where the element Id's are listed
  UCHAR elTags[(3 * ((8) * 2) + (((8) * 2)) / 2 + 4 * (1) +
                1)]; // Table where the elements id Tags are listed
  UCHAR chMapping[((8) * 2)]; // Table of MPEG canonical order to bitstream
                                 channel order mapping.

  AUDIO_CHANNEL_TYPE channelType[(8)]; // Audio channel type of each output
                                          audio channel (from 0 upto
                                          numChannels).
  UCHAR channelIndices[(8)]; // Audio channel index for each output audio
                                channel (from 0 upto numChannels).
  /* See ISO/IEC 13818-7:2005(E), 8.5.3.2 Explicit channel mapping using a
   * program_config_element()

  FDK_channelMapDescr mapDescr; // Describes the output channel mapping.
  UCHAR chMapIndex; // Index to access one line of the channelOutputMapping
                       table. This is required because not all 8 channel
                       configurations have the same output mapping.
  INT sbrDataLen;   // Expected length of the SBR remaining in bitbuffer after
                         the AAC payload has been pared.

  CProgramConfig pce;
  CStreamInfo
      streamInfo; // Pointer to StreamInfo data (read from the bitstream)
  CAacDecoderChannelInfo
      *pAacDecoderChannelInfo[(8)]; // Temporal channel memory
  CAacDecoderStaticChannelInfo
      *pAacDecoderStaticChannelInfo[(8)]; // Persistent channel memory

  FIXP_DBL *workBufferCore2;
  PCM_DEC *pTimeData2;
  INT timeData2Size;

  CpePersistentData *cpeStaticData[(
      3 * ((8) * 2) + (((8) * 2)) / 2 + 4 * (1) +
      1)]; // Pointer to persistent data shared by both channels of a CPE.
This structure is allocated once for each CPE.

  CConcealParams concealCommonData;
  CConcealmentMethod concealMethodUser;

  CUsacCoreExtensions usacCoreExt; // Data and handles to extend USAC FD/LPD
                                      core decoder (SBR, MPS, ...)
  UINT numUsacElements[(1 * 1)];
  UCHAR usacStereoConfigIndex[(3 * ((8) * 2) + (((8) * 2)) / 2 + 4 * (1) + 1)];
  const CSUsacConfig *pUsacConfig[(1 * 1)];
  INT nbDiv; // number of frame divisions in LPD-domain

  UCHAR useLdQmfTimeAlign;

  INT aacChannelsPrev; // The amount of AAC core channels of the last
                          successful decode call.
  AUDIO_CHANNEL_TYPE channelTypePrev[(8)]; // Array holding the channelType
                                              values of the last successful
                                              decode call.
  UCHAR
  channelIndicesPrev[(8)]; // Array holding the channelIndices values of
                              the last successful decode call.

  UCHAR
  downscaleFactor; // Variable to store a supported ELD downscale factor
                      of 1, 2, 3 or 4
  UCHAR downscaleFactorInBS; // Variable to store the (not necessarily
                                supported) ELD downscale factor discovered in
                                the bitstream

  HANDLE_SBRDECODER hSbrDecoder; // SBR decoder handle.
  UCHAR sbrEnabled;     // flag to store if SBR has been detected     */
  UCHAR sbrEnabledPrev; // flag to store if SBR has been detected from
                           previous frame */
  UCHAR psPossible;     // flag to store if PS is possible            */
  SBR_PARAMS sbrParams; // struct to store all sbr parameters         */

  UCHAR *pDrmBsBuffer; // Pointer to dynamic buffer which is used to reverse
                          the bits of the DRM SBR payload */
  USHORT drmBsBufferSize; // Size of the dynamic buffer which is used to
                             reverse the bits of the DRM SBR payload */
  FDK_QMF_DOMAIN
  qmfDomain; // Instance of module for QMF domain data handling */

  QMF_MODE qmfModeCurr; // The current QMF mode                       */
  QMF_MODE qmfModeUser; // The QMF mode requested by the library user */

  HANDLE_AAC_DRC hDrcInfo; // handle to DRC data structure               */
  INT metadataExpiry;      // Metadata expiry time in milli-seconds.     */

  void *pMpegSurroundDecoder; // pointer to mpeg surround decoder structure */
  UCHAR mpsEnableUser;        // MPS enable user flag                       */
  UCHAR mpsEnableCurr;        // MPS enable decoder state                   */
  UCHAR mpsApplicable;        // MPS applicable                             */
  SCHAR mpsOutputMode; // setting: normal = 0, binaural = 1, stereo = 2, 5.1ch
                          = 3 */
  INT mpsOutChannelsLast; // The amount of channels returned by the last
                             successful MPS decoder call. */
  INT mpsFrameSizeLast;   // The frame length returned by the last successful
                             MPS decoder call. */

  CAncData ancData; // structure to handle ancillary data         */

  HANDLE_PCM_DOWNMIX hPcmUtils; // privat data for the PCM utils. */

  TDLimiterPtr hLimiter;   // Handle of time domain limiter.             */
  UCHAR limiterEnableUser; // The limiter configuration requested by the
                              library user */
  UCHAR limiterEnableCurr; // The current limiter configuration.         */
  FIXP_DBL extGain[1]; // Gain that must be applied to the output signal. */
  UINT extGainDelay;   // Delay that must be accounted for extGain. */

  INT_PCM pcmOutputBuffer[(8) * (1024 * 2)];

  HANDLE_DRC_DECODER hUniDrcDecoder;
  UCHAR multibandDrcPresent;
  UCHAR numTimeSlots;
  UINT loudnessInfoSetPosition[3];
  SCHAR defaultTargetLoudness;

  INT_PCM
  *pTimeDataFlush[((8) * 2)]; // Pointer to the flushed time data which
                                 will be used for the crossfade in case of
                                 an USAC DASH IPF config change */

  UCHAR flushStatus;     // Indicates flush status: on|off */
  SCHAR flushCnt;        // Flush frame counter */
  UCHAR buildUpStatus;   // Indicates build up status: on|off */
  SCHAR buildUpCnt;      // Build up frame counter */
  UCHAR hasAudioPreRoll; // Indicates preRoll status: on|off */
  UINT prerollAULength[AACDEC_MAX_NUM_PREROLL_AU + 1]; // Relative offset of
                                                          the prerollAU end
                                                          position to the AU
                                                          start position in the
                                                          bitstream */
  INT accessUnit; // Number of the actual processed preroll accessUnit */
  UCHAR applyCrossfade; // if set crossfade for seamless stream switching is
                           applied */

  FDK_SignalDelay usacResidualDelay; // Delay residual signal to compensate
                                        for eSBR delay of DMX signal in case of
                                        stereoConfigIndex==2. */
*)
  end;
  PAacDecoderInstance = ^TAacDecoderInstance;

  TAacEncoderInstance = record
    extParam: TUserParam;
  end;
  PAacEncoderInstance = ^TAacEncoderInstance;

{$IFDEF DynLink}
  // static linking
  TAacDecAncDataInit = function (Self: PAacDecoderInstance; Buffer: PByte; Size: Integer): TAacDecoderError; cdecl;
  TAacDecAncDataGet = function (Self: PAacDecoderInstance; index: Integer; var Buffer: PByte; var Size: Integer): TAacDecoderError; cdecl;
  TAacDecSetParam = function (const Self: PAacDecoderInstance; const param: TAacDecParam; const value: Integer): TAacDecoderError; cdecl;
  TAacDecGetFreeBytes = function (const Self: PAacDecoderInstance; var FreeBytes: Cardinal): TAacDecoderError; cdecl;
  TAacDecOpen = function (transportFmt: TTransportType; nrOfLayers: Cardinal): TAacDecoderError; cdecl;
  TAacDecConfigRaw = function (Self: PAacDecoderInstance; conf: PByte; const length: Byte): TAacDecoderError; cdecl;
  TAacDecFill = function (Self: PAacDecoderInstance; var pBuffer: PByte; var bufferSize: Cardinal; var bytesValid: Cardinal): TAacDecoderError; cdecl;
  TAacDecDecodeFrame = function (Self: PAacDecoderInstance; pTimeData: Pointer; const timeDataSize: Integer; const flags: Cardinal): TAacDecoderError; cdecl;
  TAacDecClose = procedure (Self: PAacDecoderInstance); cdecl;
  TAacDecGetStreamInfo = function (Self: PAacDecoderInstance): PStreamInfo; cdecl;
  TAacDecGetLibInfo = function (var info: TLibInfo): Integer; cdecl;

  TAacEncClose = function (out phAacEncoder: PAacEncoderInstance): TAacEncoderError; cdecl;
  TAacEncEncode = function (const hAacEncoder: PAacEncoderInstance; const inBufDesc, outBufDesc: PAacEncBufDesc; const inargs: PAacEncInArgs; outargs: PAacEncOutArgs): TAacEncoderError; cdecl;
  TAacEncInfo = function (const hAacEncoder: PAacEncoderInstance; var Info: TAacEncInfoStruct): TAacEncoderError; cdecl;
  TAacEncOpen = function (out phAacEncoder: PAacEncoderInstance; const encModules: Cardinal; const maxChannels: Cardinal): TAacEncoderError; cdecl;
  TAacEncGetParam = function (const hAacEncoder: PAacEncoderInstance; const param: Cardinal): Cardinal; cdecl;
  TAacEncSetParam = function (const hAacEncoder: PAacEncoderInstance; const param: Cardinal; const value: Cardinal): TAacEncoderError; cdecl;
  TAacEncGetLibInfo = function (var info: TLibInfo): TAacEncoderError; cdecl;

var
  AacDecAncDataInit: TAacDecAncDataInit;
  AacDecAncDataGet: TAacDecAncDataGet;
  AacDecSetParam: TAacDecSetParam;
  AacDecGetFreeBytes: TAacDecGetFreeBytes;
  AacDecOpen: TAacDecOpen;
  AacDecConfigRaw: TAacDecConfigRaw;
  AacDecFill: TAacDecFill;
  AacDecDecodeFrame: TAacDecDecodeFrame;
  AacDecClose: TAacDecClose;
  AacDecGetStreamInfo: TAacDecGetStreamInfo;
  AacDecGetLibInfo: TAacDecGetLibInfo;

  AacEncClose: TAacEncClose;
  AacEncEncode: TAacEncEncode;
  AacEncInfo: TAacEncInfo;
  AacEncOpen: TAacEncOpen;
  AacEncGetParam: TAacEncGetParam;
  AacEncSetParam: TAacEncSetParam;
  AacEncGetLibInfo: TAacEncGetLibInfo;

{$ELSE}
  // static linking
  function AacDecAncDataInit(Self: PAacDecoderInstance; Buffer: PByte; Size: Integer): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_AncDataInit';
  function AacDecAncDataGet(Self: PAacDecoderInstance; index: Integer; var Buffer: PByte; var Size: Integer): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_AncDataGet';
  function AacDecSetParam(const Self: PAacDecoderInstance; const param: TAacDecoderParam; const value: Integer): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_SetParam';
  function AacDecGetFreeBytes(const Self: PAacDecoderInstance; var FreeBytes: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_GetFreeBytes';
  function AacDecOpen(transportFmt: TTransportType; nrOfLayers: Cardinal): PAacDecoderInstance; cdecl; external CLibFdkAac name 'aacDecoder_Open';
  function AacDecConfigRaw(Self: PAacDecoderInstance; conf: PByte; const length: Byte): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_ConfigRaw';
  function AacDecFill(Self: PAacDecoderInstance; var pBuffer: PByte; var bufferSize: Cardinal; var bytesValid: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_Fill';
  function AacDecDecodeFrame(Self: PAacDecoderInstance; pTimeData: Pointer; const timeDataSize: Integer; const flags: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_DecodeFrame';
  procedure AacDecClose(Self: PAacDecoderInstance); cdecl; external CLibFdkAac name 'aacDecoder_Close';
  function AacDecGetStreamInfo(Self: PAacDecoderInstance): PStreamInfo; cdecl; external CLibFdkAac name 'aacDecoder_GetStreamInfo';
  function AacDecGetLibInfo(var info: TLibInfo): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_GetLibInfo';

  function AacEncClose(out hAacEncoder: PAacEncoderInstance): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncClose';
  function AacEncEncode(const hAacEncoder: PAacEncoderInstance; const inBufDesc, outBufDesc: PAacEncBufDesc; const inargs: PAacEncInArgs; outargs: PAacEncOutArgs): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncEncode';
  function AacEncInfo(const hAacEncoder: PAacEncoderInstance; var Info: TAacEncInfoStruct): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncInfo';
  function AacEncOpen(out hAacEncoder: PAacEncoderInstance; const encModules: Cardinal; const maxChannels: Cardinal): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncOpen';
  function AacEncGetParam(const hAacEncoder: PAacEncoderInstance; const param: TAacEncoderParam): Cardinal; cdecl; external CLibFdkAac name 'aacEncoder_GetParam';
  function AacEncSetParam(const hAacEncoder: PAacEncoderInstance; const param: TAacEncoderParam; const value: Cardinal): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncoder_SetParam';
  function AacEncGetLibInfo(var info: TLibInfo): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncGetLibInfo';

{$ENDIF}

function TransportTypeIsPacket(TransportType: TTransportType): Boolean;
function CanDoParametricStereo(AudioObjectType: TAudioObjectType): Boolean;
function IsUsac(AudioObjectType: TAudioObjectType): Boolean;
function IsLowDelay(AudioObjectType: TAudioObjectType): Boolean;

implementation

uses
  System.SysUtils
{$IFDEF DynLink}
{$IFDEF FPC}
  , DynLibs;
{$ELSE}
{$IFDEF MSWindows}
  , Windows;
{$ENDIF}
{$ENDIF}
{$ELSE}
  ;
{$ENDIF}

{$IFDEF DynLink}
var
  CLibFdkAacHandle: {$IFDEF FPC}TLibHandle{$ELSE}HINST{$ENDIF};

procedure InitDLL;

  function BindFunction(Name: AnsiString): Pointer;
  begin
    Result := GetProcAddress(CLibFdkAacHandle, PAnsiChar(Name));
    Assert(Assigned(Result));
  end;

begin
  {$IFDEF FPC}
  CSfmlSystemHandle := LoadLibrary(CLibFdkAac);
  {$ELSE}
  CLibFdkAacHandle := LoadLibraryA(CLibFdkAac);
  {$ENDIF}
  if CLibFdkAacHandle <> 0 then
    try
      AacDecAncDataInit := BindFunction('aacDecoder_AncDataInit');
      AacDecAncDataGet := BindFunction('aacDecoder_AncDataGet');
      AacDecSetParam := BindFunction('aacDecoder_SetParam');
      AacDecGetFreeBytes := BindFunction('aacDecoder_GetFreeBytes');
      AacDecOpen := BindFunction('aacDecoder_Open');
      AacDecConfigRaw := BindFunction('aacDecoder_ConfigRaw');
      AacDecFill := BindFunction('aacDecoder_Fill');
      AacDecDecodeFrame := BindFunction('aacDecoder_DecodeFrame');
      AacDecClose := BindFunction('aacDecoder_Close');
      AacDecGetStreamInfo := BindFunction('aacDecoder_GetStreamInfo');
      AacDecGetLibInfo := BindFunction('aacDecoder_GetLibInfo');

      AacEncClose := BindFunction('aacEncClose');
      AacEncEncode := BindFunction('aacEncEncode');
      AacEncInfo := BindFunction('aacEncInfo');
      AacEncOpen := BindFunction('aacEncOpen');
      AacEncGetParam := BindFunction('aacEncoder_GetParam');
      AacEncSetParam := BindFunction('aacEncoder_SetParam');
      AacEncGetLibInfo := BindFunction('aacEncGetLibInfo');
    except
      FreeLibrary(CLibFdkAacHandle);
      CLibFdkAacHandle := 0;
    end;
end;

procedure FreeDLL;
begin
  if CLibFdkAacHandle <> 0 then
    FreeLibrary(CLibFdkAacHandle);
end;
{$ELSE}
{$ENDIF}

function TransportTypeIsPacket(TransportType: TTransportType): Boolean;
begin
  Result := TransportType in [ttMp4Raw, ttDrm, ttMp4LatmMcp0, ttMp4LatmMcp1];
end;

function CanDoParametricStereo(AudioObjectType: TAudioObjectType): Boolean;
begin
  Result := AudioObjectType in [aotAacLC, aotSBR, aotPS, aotErrorResBSAC,
    aotDrmAac];
end;

function IsUsac(AudioObjectType: TAudioObjectType): Boolean;
begin
  Result := AudioObjectType = aotUSAC;
end;

function IsLowDelay(AudioObjectType: TAudioObjectType): Boolean;
begin
  Result := AudioObjectType in [aotErrorResAacLD, aotErrorResAacELD];
end;

function IsChannelElement(ElementId: TMp4ElementID): Boolean;
begin
  Result := ElementId in [idSCE, idCPE, idLFE, idUSAC_SCE, idUSAC_CPE, idUSAC_LFE];
end;

function IsMp4ChannelElement(ElementId: TMp4ElementID): Boolean;
begin
  Result := ElementId in [idSCE, idCPE, idLFE];
end;

function IsUsacChannelElement(ElementId: TMp4ElementID): Boolean;
begin
  Result := ElementId in [idUSAC_SCE, idUSAC_CPE, idUSAC_LFE];
end;

function LibVersion(lev0, lev1, lev2: Byte): Integer;
begin
  Result := (lev0 shl 24) or (lev1 shl 16) or (lev2 shl 8);
end;

function LibVersionString(info: TLibInfo): string;
begin
  Result := string(Info.versionStr);
  if Result = '' then
    Result := Format('%d.%d.%d', [
      (Info.version shr 24) and $FF,
      (Info.version shr 16) and $FF,
      (Info.version shr  8) and $FF]
    );
end;

{$IFDEF DynLink}
initialization
  InitDLL;

finalization
  FreeDLL;
{$ENDIF}

end.
