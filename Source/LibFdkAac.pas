unit LibFdkAac;

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
    aeInvalid_Config        = $0023, // Configuration not provided.
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
    ttUnknown       = -1, // Unknown format.
    ttMP4_RAW       = 0,  // "as is" access units (packet based since there is obviously no sync layer)
    ttMP4_ADIF      = 1,  // ADIF bitstream format.
    ttMP4_ADTS      = 2,  // ADTS bitstream format.
    ttMP4_LATM_MCP1 = 6,  // Audio Mux Elements with muxConfigPresent = 1
    ttMP4_LATM_MCP0 = 7,  // Audio Mux Elements with muxConfigPresent = 0, out of band StreamMuxConfig
    ttMP4_LOAS      = 10, // Audio Sync Stream.
    ttDRM           = 12, // Digital Radio Mondial (DRM30/DRM+) bitstream format.
    ttMp1Layer1     = 16, // MPEG 1 Audio Layer 1 audio bitstream.
    ttMp1Layer2     = 17, // MPEG 1 Audio Layer 2 audio bitstream.
    ttMp1Layer3     = 18, // MPEG 1 Audio Layer 3 audio bitstream.
    ttRSVD50        = 50
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

  TAudioObjectType = (
    AOT_NONE             = -1,
    AOT_NULL_OBJECT      = 0,
    AOT_AAC_MAIN         = 1, // Main profile
    AOT_AAC_LC           = 2, // Low Complexity object
    AOT_AAC_SSR          = 3,
    AOT_AAC_LTP          = 4,
    AOT_SBR              = 5,
    AOT_AAC_SCAL         = 6,
    AOT_TWIN_VQ          = 7,
    AOT_CELP             = 8,
    AOT_HVXC             = 9,
    AOT_RSVD_10          = 10, // (reserved)
    AOT_RSVD_11          = 11, // (reserved)
    AOT_TTSI             = 12, // TTSI Object
    AOT_MAIN_SYNTH       = 13, // Main Synthetic object
    AOT_WAV_TAB_SYNTH    = 14, // Wavetable Synthesis object
    AOT_GEN_MIDI         = 15, // General MIDI object
    AOT_ALG_SYNTH_AUD_FX = 16, // Algorithmic Synthesis and Audio FX object
    AOT_ER_AAC_LC        = 17, // Error Resilient(ER) AAC Low Complexity
    AOT_RSVD_18          = 18, // (reserved)
    AOT_ER_AAC_LTP       = 19, // Error Resilient(ER) AAC LTP object
    AOT_ER_AAC_SCAL      = 20, // Error Resilient(ER) AAC Scalable object
    AOT_ER_TWIN_VQ       = 21, // Error Resilient(ER) TwinVQ object
    AOT_ER_BSAC          = 22, // Error Resilient(ER) BSAC object
    AOT_ER_AAC_LD        = 23, // Error Resilient(ER) AAC LowDelay object
    AOT_ER_CELP          = 24, // Error Resilient(ER) CELP object
    AOT_ER_HVXC          = 25, // Error Resilient(ER) HVXC object
    AOT_ER_HILN          = 26, // Error Resilient(ER) HILN object
    AOT_ER_PARA          = 27, // Error Resilient(ER) Parametric object
    AOT_RSVD_28          = 28, // might become SSC
    AOT_PS               = 29, // PS, Parametric Stereo (includes SBR)
    AOT_MPEGS            = 30, // MPEG Surround

    AOT_ESCAPE           = 31, // Signal AOT uses more than 5 bits

    AOT_MP3ONMP4_L1      = 32, // MPEG-Layer1 in mp4
    AOT_MP3ONMP4_L2      = 33, // MPEG-Layer2 in mp4
    AOT_MP3ONMP4_L3      = 34, // MPEG-Layer3 in mp4
    AOT_RSVD_35          = 35, // might become DST
    AOT_RSVD_36          = 36, // might become ALS
    AOT_AAC_SLS          = 37, // AAC + SLS
    AOT_SLS              = 38, // SLS
    AOT_ER_AAC_ELD       = 39, // AAC Enhanced Low Delay

    AOT_USAC             = 42, // USAC
    AOT_SAOC             = 43, // SAOC
    AOT_LD_MPEGS         = 44, // Low Delay MPEG Surround

    // Pseudo AOTs *)
    AOT_MP2_AAC_LC       = 129, // Virtual AOT MP2 Low Complexity profile
    AOT_MP2_SBR          = 132, // Virtual AOT MP2 Low Complexity Profile with SBR

    AOT_DRM_AAC          = 143, // Virtual AOT for DRM (ER-AAC-SCAL without SBR)
    AOT_DRM_SBR          = 144, // Virtual AOT for DRM (ER-AAC-SCAL with SBR)
    AOT_DRM_MPEG_PS      = 145, // Virtual AOT for DRM (ER-AAC-SCAL with SBR and MPEG-PS)
    AOT_DRM_SURROUND     = 146, // Virtual AOT for DRM Surround (ER-AAC-SCAL (+SBR) +MPS)
    AOT_DRM_USAC         = 147  // Virtual AOT for DRM with USAC
  );

  TFDK_MODULE_ID = (
    FDK_NONE               = 0,
    FDK_TOOLS              = 1,
    FDK_SYSLIB             = 2,
    FDK_AACDEC             = 3,
    FDK_AACENC             = 4,
    FDK_SBRDEC             = 5,
    FDK_SBRENC             = 6,
    FDK_TPDEC              = 7,
    FDK_TPENC              = 8,
    FDK_MPSDEC             = 9,
    FDK_MPEGFILEREAD       = 10,
    FDK_MPEGFILEWRITE      = 11,
    FDK_MP2DEC             = 12,
    FDK_DABDEC             = 13,
    FDK_DABPARSE           = 14,
    FDK_DRMDEC             = 15,
    FDK_DRMPARSE           = 16,
    FDK_AACLDENC           = 17,
    FDK_MP2ENC             = 18,
    FDK_MP3ENC             = 19,
    FDK_MP3DEC             = 20,
    FDK_MP3HEADPHONE       = 21,
    FDK_MP3SDEC            = 22,
    FDK_MP3SENC            = 23,
    FDK_EAEC               = 24,
    FDK_DABENC             = 25,
    FDK_DMBDEC             = 26,
    FDK_FDREVERB           = 27,
    FDK_DRMENC             = 28,
    FDK_METADATATRANSCODER = 29,
    FDK_AC3DEC             = 30,
    FDK_PCMDMX             = 31
  );

  TLIB_INFO = record
    title: PChar;
    build_date: PChar;
    build_time: PChar;
    module_id: TFDK_MODULE_ID;
    version: Integer;
    flags: Cardinal;
    versionStr: array[0..31] of Char;
  end;
  PLIB_INFO = ^TLIB_INFO;

  TAACENC_CTRLFLAGS = (
    AACENC_INIT_NONE      = $0000, // Do not trigger initialization.
    AACENC_INIT_CONFIG    = $0001, // Initialize all encoder modules configuration.
    AACENC_INIT_STATES    = $0002, // Reset all encoder modules history buffer.
    AACENC_INIT_TRANSPORT = $1000, // Initialize transport lib with new parameters.
    AACENC_RESET_INBUFFER = $2000, // Reset fill level of internal input buffer.
    AACENC_INIT_ALL       = $FFFF  // Initialize all.
  );

  TAacEncParam = (
    AACENC_AOT =
        $0100, (* Audio object type. See ::AUDIO_OBJECT_TYPE in FDK_audio.h.
                     - 2: MPEG-4 AAC Low Complexity.
                     - 5: MPEG-4 AAC Low Complexity with Spectral Band Replication
                   (HE-AAC).
                     - 29: MPEG-4 AAC Low Complexity with Spectral Band
                   Replication and Parametric Stereo (HE-AAC v2). This
                   configuration can be used only with stereo input audio data.
                     - 23: MPEG-4 AAC Low-Delay.
                     - 39: MPEG-4 AAC Enhanced Low-Delay. Since there is no
                   ::AUDIO_OBJECT_TYPE for ELD in combination with SBR defined,
                   enable SBR explicitely by ::AACENC_SBR_MODE parameter. The ELD
                   v2 212 configuration can be configured by ::AACENC_CHANNELMODE
                   parameter.
                     - 129: MPEG-2 AAC Low Complexity.
                     - 132: MPEG-2 AAC Low Complexity with Spectral Band
                   Replication (HE-AAC).
                     Please note that the virtual MPEG-2 AOT's basically disables
                   non-existing Perceptual Noise Substitution tool in AAC encoder
                   and controls the MPEG_ID flag in adts header. The virtual
                   MPEG-2 AOT doesn't prohibit specific transport formats. *)

    AACENC_BITRATE = $0101, (* Total encoder bitrate. This parameter is
                                mandatory and interacts with ::AACENC_BITRATEMODE.
                                  - CBR: Bitrate in bits/second.
                                  - VBR: Variable bitrate. Bitrate argument will
                                be ignored. See \ref suppBitrates for details. *)

    AACENC_BITRATEMODE = $0102, (* Bitrate mode. Configuration can be different
                                    kind of bitrate configurations:
                                      - 0: Constant bitrate, use bitrate according
                                    to ::AACENC_BITRATE. (default) Within none
                                    LD/ELD ::AUDIO_OBJECT_TYPE, the CBR mode makes
                                    use of full allowed bitreservoir. In contrast,
                                    at Low-Delay ::AUDIO_OBJECT_TYPE the
                                    bitreservoir is kept very small.
                                      - 1: Variable bitrate mode, \ref vbrmode
                                    "very low bitrate".
                                      - 2: Variable bitrate mode, \ref vbrmode
                                    "low bitrate".
                                      - 3: Variable bitrate mode, \ref vbrmode
                                    "medium bitrate".
                                      - 4: Variable bitrate mode, \ref vbrmode
                                    "high bitrate".
                                      - 5: Variable bitrate mode, \ref vbrmode
                                    "very high bitrate". *)

    AACENC_SAMPLERATE = $0103, (* Audio input data sampling rate. Encoder
                                   supports following sampling rates: 8000, 11025,
                                   12000, 16000, 22050, 24000, 32000, 44100,
                                   48000, 64000, 88200, 96000 *)

    AACENC_SBR_MODE = $0104, (* Configure SBR independently of the chosen Audio
                                 Object Type ::AUDIO_OBJECT_TYPE. This parameter
                                 is for ELD audio object type only.
                                   - -1: Use ELD SBR auto configurator (default).
                                   - 0: Disable Spectral Band Replication.
                                   - 1: Enable Spectral Band Replication. *)

    AACENC_GRANULE_LENGTH =
        $0105, (* Core encoder (AAC) audio frame length in samples:
                     - 1024: Default configuration.
                     - 512: Default length in LD/ELD configuration.
                     - 480: Length in LD/ELD configuration.
                     - 256: Length for ELD reduced delay mode (x2).
                     - 240: Length for ELD reduced delay mode (x2).
                     - 128: Length for ELD reduced delay mode (x4).
                     - 120: Length for ELD reduced delay mode (x4). *)

    AACENC_CHANNELMODE = $0106, (* Set explicit channel mode. Channel mode must
                                    match with number of input channels.
                                      - 1-7, 11,12,14 and 33,34: MPEG channel
                                    modes supported, see ::CHANNEL_MODE in
                                    FDK_audio.h. *)

    AACENC_CHANNELORDER =
        $0107, (* Input audio data channel ordering scheme:
                     - 0: MPEG channel ordering (e. g. 5.1: C, L, R, SL, SR, LFE).
                   (default)
                     - 1: WAVE file format channel ordering (e. g. 5.1: L, R, C,
                   LFE, SL, SR). *)

    AACENC_SBR_RATIO =
        $0108, (*  Controls activation of downsampled SBR. With downsampled
                   SBR, the delay will be shorter. On the other hand, for
                   achieving the same quality level, downsampled SBR needs more
                   bits than dual-rate SBR. With downsampled SBR, the AAC encoder
                   will work at the same sampling rate as the SBR encoder (single
                   rate). Downsampled SBR is supported for AAC-ELD and HE-AACv1.
                      - 1: Downsampled SBR (default for ELD).
                      - 2: Dual-rate SBR   (default for HE-AAC). *)

    AACENC_AFTERBURNER =
        $0200, (* This parameter controls the use of the afterburner feature.
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

    AACENC_BANDWIDTH = $0203, (* Core encoder audio bandwidth:
                                    - 0: Determine audio bandwidth internally
                                  (default, see chapter \ref BEHAVIOUR_BANDWIDTH).
                                    - 1 to fs/2: Audio bandwidth in Hertz. Limited
                                  to 20kHz max. Not usable if SBR is active. This
                                  setting is for experts only, better do not touch
                                  this value to avoid degraded audio quality. *)

    AACENC_PEAK_BITRATE =
        $0207, (* Peak bitrate configuration parameter to adjust maximum bits
                   per audio frame. Bitrate is in bits/second. The peak bitrate
                   will internally be limited to the chosen bitrate
                   ::AACENC_BITRATE as lower limit and the
                   number_of_effective_channels*6144 bit as upper limit.
                     Setting the peak bitrate equal to ::AACENC_BITRATE does not
                   necessarily mean that the audio frames will be of constant
                   size. Since the peak bitate is in bits/second, the frame sizes
                   can vary by one byte in one or the other direction over various
                   frames. However, it is not recommended to reduce the peak
                   pitrate to ::AACENC_BITRATE - it would disable the
                   bitreservoir, which would affect the audio quality by a large
                   amount. *)

    AACENC_TRANSMUX = $0300, (* Transport type to be used. See ::TRANSPORT_TYPE
                                 in FDK_audio.h. Following types can be configured
                                 in encoder library:
                                   - 0: raw access units
                                   - 1: ADIF bitstream format
                                   - 2: ADTS bitstream format
                                   - 6: Audio Mux Elements (LATM) with
                                 muxConfigPresent = 1
                                   - 7: Audio Mux Elements (LATM) with
                                 muxConfigPresent = 0, out of band StreamMuxConfig
                                   - 10: Audio Sync Stream (LOAS) *)

    AACENC_HEADER_PERIOD =
        $0301, (* Frame count period for sending in-band configuration buffers
                   within LATM/LOAS transport layer. Additionally this parameter
                   configures the PCE repetition period in raw_data_block(). See
                   \ref encPCE.
                     - $FF: auto-mode default 10 for TT_MP4_ADTS, TT_MP4_LOAS and
                   TT_MP4_LATM_MCP1, otherwise 0.
                     - n: Frame count period. *)

    AACENC_SIGNALING_MODE =
        $0302, (* Signaling mode of the extension AOT:
                     - 0: Implicit backward compatible signaling (default for
                   non-MPEG-4 based AOT's and for the transport formats ADIF and
                   ADTS)
                          - A stream that uses implicit signaling can be decoded
                   by every AAC decoder, even AAC-LC-only decoders
                          - An AAC-LC-only decoder will only decode the
                   low-frequency part of the stream, resulting in a band-limited
                   output
                          - This method works with all transport formats
                          - This method does not work with downsampled SBR
                     - 1: Explicit backward compatible signaling
                          - A stream that uses explicit backward compatible
                   signaling can be decoded by every AAC decoder, even AAC-LC-only
                   decoders
                          - An AAC-LC-only decoder will only decode the
                   low-frequency part of the stream, resulting in a band-limited
                   output
                          - A decoder not capable of decoding PS will only decode
                   the AAC-LC+SBR part. If the stream contained PS, the result
                   will be a a decoded mono downmix
                          - This method does not work with ADIF or ADTS. For
                   LOAS/LATM, it only works with AudioMuxVersion==1
                          - This method does work with downsampled SBR
                     - 2: Explicit hierarchical signaling (default for MPEG-4
                   based AOT's and for all transport formats excluding ADIF and
                   ADTS)
                          - A stream that uses explicit hierarchical signaling can
                   be decoded only by HE-AAC decoders
                          - An AAC-LC-only decoder will not decode a stream that
                   uses explicit hierarchical signaling
                          - A decoder not capable of decoding PS will not decode
                   the stream at all if it contained PS
                          - This method does not work with ADIF or ADTS. It works
                   with LOAS/LATM and the MPEG-4 File format
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

    AACENC_TPSUBFRAMES =
        $0303, (* Number of sub frames in a transport frame for LOAS/LATM or
                   ADTS (default 1).
                     - ADTS: Maximum number of sub frames restricted to 4.
                     - LOAS/LATM: Maximum number of sub frames restricted to 2.*)

    AACENC_AUDIOMUXVER =
        $0304, (* AudioMuxVersion to be used for LATM. (AudioMuxVersionA,
                   currently not implemented):
                     - 0: Default, no transmission of tara Buffer fullness, no ASC
                   length and including actual latm Buffer fullnes.
                     - 1: Transmission of tara Buffer fullness, ASC length and
                   actual latm Buffer fullness.
                     - 2: Transmission of tara Buffer fullness, ASC length and
                   maximum level of latm Buffer fullness. *)

    AACENC_PROTECTION = $0306, (* Configure protection in transport layer:
                                     - 0: No protection. (default)
                                     - 1: CRC active for ADTS transport format. *)

    AACENC_ANCILLARY_BITRATE =
        $0500, (* Constant ancillary data bitrate in bits/second.
                     - 0: Either no ancillary data or insert exact number of
                   bytes, denoted via input parameter, numAncBytes in
                   AACENC_InArgs.
                     - else: Insert ancillary data with specified bitrate. *)

    AACENC_METADATA_MODE = $0600, (* Configure Meta Data. See ::AACENC_MetaData
                                      for further details:
                                        - 0: Do not embed any metadata.
                                        - 1: Embed dynamic_range_info metadata.
                                        - 2: Embed dynamic_range_info and
                                      ancillary_data metadata.
                                        - 3: Embed ancillary_data metadata. *)

    AACENC_CONTROL_STATE =
        $FF00, (* There is an automatic process which internally reconfigures
                   the encoder instance when a configuration parameter changed or
                   an error occured. This paramerter allows overwriting or getting
                   the control status of this process. See ::AACENC_CTRLFLAGS. *)

    AACENC_NONE = $FFFF (* ------ *)
  );

type
(*
  AAC encoder buffer descriptors identifier.
  This identifier are used within buffer descriptors
  AACENC_BufDesc::bufferIdentifiers.
*)
  AACENC_BufferIdentifier = (
    (* Input buffer identifier. *)
    IN_AUDIO_DATA = 0,    (* Audio input buffer, interleaved INT_PCM samples. *)
    IN_ANCILLRY_DATA = 1, (* Ancillary data to be embedded into bitstream. *)
    IN_METADATA_SETUP = 2, (* Setup structure for embedding meta data. *)

    (* Output buffer identifier. *)
    OUT_BITSTREAM_DATA = 3, (* Buffer holds bitstream output data. *)
    OUT_AU_SIZES =
        4 (* Buffer contains sizes of each access unit. This information
               is necessary for superframing. *)
  );

(**
 *  Provides some info about the encoder configuration.
 *)
  AACENC_InfoStruct = record
    maxOutBufBytes: Cardinal; (* Maximum number of encoder bitstream bytes within one
                            frame. Size depends on maximum number of supported
                            channels in encoder instance. *)

    maxAncBytes: Cardinal; (* Maximum number of ancillary data bytes which can be
                         inserted into bitstream within one frame. *)

    inBufFillLevel: Cardinal; (* Internal input buffer fill level in samples per
                            channel. This parameter will automatically be cleared
                            if samplingrate or channel(Mode/Order) changes. *)

    inputChannels: Cardinal; (* Number of input channels expected in encoding
                           process. *)

    frameLength: Cardinal; (* Amount of input audio samples consumed each frame per
                         channel, depending on audio object type configuration. *)

    nDelay: Cardinal; (* Codec delay in PCM samples/channel. Depends on framelength
                    and AOT. Does not include framing delay for filling up encoder
                    PCM input buffer. *)

    nDelayCore: Cardinal; (* Codec delay in PCM samples/channel, w/o delay caused by
                        the decoder SBR module. This delay is needed to correctly
                        write edit lists for gapless playback. The decoder may not
                        know how much delay is introdcued by SBR, since it may not
                        know if SBR is active at all (implicit signaling),
                        therefore the deocder must take into account any delay
                        caused by the SBR module. *)

    confBuf: array [0..63] of Byte; (* Configuration buffer in binary format as an
                          AudioSpecificConfig or StreamMuxConfig according to the
                          selected transport type. *)

    confSize: Cardinal; (* Number of valid bytes in confBuf. *)
  end;

  // Describes the input and output buffers for an aacEncEncode() call.
  AACENC_BufDesc = record
    numBufs: Integer ;           // Number of buffers.
    bufs: PPointer;              // Pointer to vector containing buffer addresses.
    bufferIdentifiers: PInteger; // Identifier of each buffer element.
    bufSizes: PInteger;          // Size of each buffer in 8-bit bytes.
    bufElSizes: PInteger;        // Size of each buffer element in bytes.
  end;

  // Defines the input arguments for an aacEncEncode() call.
  AACENC_InArgs = record
    numInSamples: Integer; // Number of valid input audio samples (multiple of input channels).
    numAncBytes: Integer;  // Number of ancillary data bytes to be encoded.
  end;

  //  Defines the output arguments for an aacEncEncode() call.
  AACENC_OutArgs = record
    numOutBytes: Integer;  // Number of valid bitstream bytes generated during aacEncEncode().
    numInSamples: Integer; // Number of input audio samples consumed by the encoder.
    numAncBytes: Integer;  // Number of ancillary data bytes consumed by the encoder.
    bitResState: Integer;  // State of the bit reservoir in bits. *)
  end;

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

    drc_TargetRefLevel: Integer;  (* Used to define expected level to:
                                  Scaled with 16 bit. x*2^16. *)
    comp_TargetRefLevel: Integer; (* Adjust limiter to avoid overload.
                                  Scaled with 16 bit. x*2^16. *)

    prog_ref_level_present: Integer; (* Flag, if prog_ref_level is present *)
    prog_ref_level: Integer;         (* Programme Reference Level = Dialogue Level:
                                     -31.75dB .. 0 dB ; stepsize: 0.25dB
                                     Scaled with 16 bit. x*2^16.*)

    PCE_mixdown_idx_present: Byte; (* Flag, if dmx-idx should be written in
                                      programme config element *)
    ETSI_DmxLvl_present: Byte;     (* Flag, if dmx-lvl should be written in
                                      ETSI-ancData *)

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
      lfeDmxLevel: Byte;  (* Downmix level index for LFE (0..15, according to
                             table) *)

    end;
  end;

const
  AACDEC_CLRHIST = 8;
  AACDEC_CONCEAL = 1;
  AACDEC_FLUSH   = 2;
  AACDEC_INTR    = 4;

type
  TAAC_MD_PROFILE = (
    AAC_MD_PROFILE_MPEG_STANDARD =
      0, (* The standard profile creates a mixdown signal based on the
            advanced downmix metadata (from a DSE). The equations and default
            values are defined in ISO/IEC 14496:3 Ammendment 4. Any other
            (legacy) downmix metadata will be ignored. No other parameter will
            be modified.         *)
    AAC_MD_PROFILE_MPEG_LEGACY =
      1, (* This profile behaves identical to the standard profile if advanced
            downmix metadata (from a DSE) is available. If not, the
            matrix_mixdown information embedded in the program configuration
            element (PCE) will be applied. If neither is the case, the module
            creates a mixdown using the default coefficients as defined in
            ISO/IEC 14496:3 AMD 4. The profile can be used to support legacy
            digital TV (e.g. DVB) streams.           *)
    AAC_MD_PROFILE_MPEG_LEGACY_PRIO =
      2, (* Similar to the ::AAC_MD_PROFILE_MPEG_LEGACY profile but if both
            the advanced (ISO/IEC 14496:3 AMD 4) and the legacy (PCE) MPEG
            downmix metadata are available the latter will be applied.
          *)
    AAC_MD_PROFILE_ARIB_JAPAN =
      3 (* Downmix creation as described in ABNT NBR 15602-2. But if advanced
           downmix metadata (ISO/IEC 14496:3 AMD 4) is available it will be
           preferred because of the higher resolutions. In addition the
           metadata expiry time will be set to the value defined in the ARIB
           standard (see ::AAC_METADATA_EXPIRY_TIME).
         *)
  );

  TAAC_DRC_DEFAULT_PRESENTATION_MODE_OPTIONS = (
    AAC_DRC_PARAMETER_HANDLING_DISABLED = -1, (* DRC parameter handling
                                                 disabled, all parameters are
                                                 applied as requested. *)
    AAC_DRC_PARAMETER_HANDLING_ENABLED =
        0, (* Apply changes to requested DRC parameters to prevent clipping. *)
    AAC_DRC_PRESENTATION_MODE_1_DEFAULT =
        1, (* Use DRC presentation mode 1 as default (e.g. for Nordig) *)
    AAC_DRC_PRESENTATION_MODE_2_DEFAULT =
        2 (* Use DRC presentation mode 2 as default (e.g. for DTG DBook) *)
  );

  TAacDecParam = (
    AAC_PCM_DUAL_CHANNEL_OUTPUT_MODE =
        $0002, (*!< Defines how the decoder processes two channel signals: \n
                     0: Leave both signals as they are (default). \n
                     1: Create a dual mono output signal from channel 1. \n
                     2: Create a dual mono output signal from channel 2. \n
                     3: Create a dual mono output signal by mixing both channels
                   (L' = R' = 0.5*Ch1 + 0.5*Ch2). *)
    AAC_PCM_OUTPUT_CHANNEL_MAPPING =
        $0003, (*!< Output buffer channel ordering. 0: MPEG PCE style order, 1:
                   WAV file channel order (default). *)
    AAC_PCM_LIMITER_ENABLE =
        $0004,                           (*!< Enable signal level limiting. \n
                                               -1: Auto-config. Enable limiter for all
                                             non-lowdelay configurations by default. \n
                                                0: Disable limiter in general. \n
                                                1: Enable limiter always.
                                               It is recommended to call the decoder
                                             with a AACDEC_CLRHIST flag to reset all
                                             states when      the limiter switch is changed
                                             explicitly. *)
    AAC_PCM_LIMITER_ATTACK_TIME = $0005, (*!< Signal level limiting attack time
                                             in ms. Default configuration is 15
                                             ms. Adjustable range from 1 ms to 15
                                             ms. *)
    AAC_PCM_LIMITER_RELEAS_TIME = $0006, (*!< Signal level limiting release time
                                             in ms. Default configuration is 50
                                             ms. Adjustable time must be larger
                                             than 0 ms. *)
    AAC_PCM_MIN_OUTPUT_CHANNELS =
        $0011, (*!< Minimum number of PCM output channels. If higher than the
                   number of encoded audio channels, a simple channel extension is
                   applied (see note 4 for exceptions). \n -1, 0: Disable channel
                   extension feature. The decoder output contains the same number
                   of channels as the encoded bitstream. \n 1:    This value is
                   currently needed only together with the mix-down feature. See
                            ::AAC_PCM_MAX_OUTPUT_CHANNELS and note 2 below. \n
                      2:    Encoded mono signals will be duplicated to achieve a
                   2/0/0.0 channel output configuration. \n 6:    The decoder
                   tries to reorder encoded signals with less than six channels to
                   achieve a 3/0/2.1 channel output signal. Missing channels will
                   be filled with a zero signal. If reordering is not possible the
                   empty channels will simply be appended. Only available if
                   instance is configured to support multichannel output. \n 8:
                   The decoder tries to reorder encoded signals with less than
                   eight channels to achieve a 3/0/4.1 channel output signal.
                   Missing channels will be filled with a zero signal. If
                   reordering is not possible the empty channels will simply be
                            appended. Only available if instance is configured to
                   support multichannel output.\n NOTE: \n
                       1. The channel signaling (CStreamInfo::pChannelType and
                   CStreamInfo::pChannelIndices) will not be modified. Added empty
                   channels will be signaled with channel type
                          AUDIO_CHANNEL_TYPE::ACT_NONE. \n
                       2. If the parameter value is greater than that of
                   ::AAC_PCM_MAX_OUTPUT_CHANNELS both will be set to the same
                   value. \n
                       3. This parameter will be ignored if the number of encoded
                   audio channels is greater than 8. *)
    AAC_PCM_MAX_OUTPUT_CHANNELS =
        $0012, (*!< Maximum number of PCM output channels. If lower than the
                   number of encoded audio channels, downmixing is applied
                   accordingly (see note 5 for exceptions). If dedicated metadata
                   is available in the stream it will be used to achieve better
                   mixing results. \n -1, 0: Disable downmixing feature. The
                   decoder output contains the same number of channels as the
                   encoded bitstream. \n 1:    All encoded audio configurations
                   with more than one channel will be mixed down to one mono
                   output signal. \n 2:    The decoder performs a stereo mix-down
                   if the number encoded audio channels is greater than two. \n 6:
                   If the number of encoded audio channels is greater than six the
                   decoder performs a mix-down to meet the target output
                   configuration of 3/0/2.1 channels. Only available if instance
                   is configured to support multichannel output. \n 8:    This
                   value is currently needed only together with the channel
                   extension feature. See ::AAC_PCM_MIN_OUTPUT_CHANNELS and note 2
                   below. Only available if instance is configured to support
                   multichannel output. \n NOTE: \n
                       1. Down-mixing of any seven or eight channel configuration
                   not defined in ISO/IEC 14496-3 PDAM 4 is not supported by this
                   software version. \n
                       2. If the parameter value is greater than zero but smaller
                   than ::AAC_PCM_MIN_OUTPUT_CHANNELS both will be set to same
                   value. \n
                       3. This parameter will be ignored if the number of encoded
                   audio channels is greater than 8. *)
    AAC_METADATA_PROFILE =
        $0020, (*!< See ::AAC_MD_PROFILE for all available values. *)
    AAC_METADATA_EXPIRY_TIME = $0021, (*!< Defines the time in ms after which all
                                          the bitstream associated meta-data (DRC,
                                          downmix coefficients, ...) will be reset
                                          to default if no update has been
                                          received. Negative values disable the
                                          feature. *)

    AAC_CONCEAL_METHOD = $0100, (*!< Error concealment: Processing method. \n
                                      0: Spectral muting. \n
                                      1: Noise substitution (see ::CONCEAL_NOISE).
                                    \n 2: Energy interpolation (adds additional
                                    signal delay of one frame, see
                                    ::CONCEAL_INTER. only some AOTs are
                                    supported). \n *)
    AAC_DRC_BOOST_FACTOR =
        $0200, (*!< MPEG-4 / MPEG-D Dynamic Range Control (DRC): Scaling factor
                   for boosting gain values. Defines how the boosting DRC factors
                   (conveyed in the bitstream) will be applied to the decoded
                   signal. The valid values range from 0 (don't apply boost
                   factors) to 127 (fully apply boost factors). Default value is 0
                   for MPEG-4 DRC and 127 for MPEG-D DRC. *)
    AAC_DRC_ATTENUATION_FACTOR = $0201, (*!< MPEG-4 / MPEG-D DRC: Scaling factor
                                            for attenuating gain values. Same as
                                              ::AAC_DRC_BOOST_FACTOR but for
                                            attenuating DRC factors. *)
    AAC_DRC_REFERENCE_LEVEL =
        $0202, (*!< MPEG-4 / MPEG-D DRC: Target reference level / decoder target
                   loudness.\n Defines the level below full-scale (quantized in
                   steps of 0.25dB) to which the output audio signal will be
                   normalized to by the DRC module.\n The parameter controls
                   loudness normalization for both MPEG-4 DRC and MPEG-D DRC. The
                   valid values range from 40 (-10 dBFS) to 127 (-31.75 dBFS).\n
                     Example values:\n
                     124 (-31 dBFS) for audio/video receivers (AVR) or other
                   devices allowing audio playback with high dynamic range,\n 96
                   (-24 dBFS) for TV sets or equivalent devices (default),\n 64
                   (-16 dBFS) for mobile devices where the dynamic range of audio
                   playback is restricted.\n Any value smaller than 0 switches off
                   loudness normalization and MPEG-4 DRC. *)
    AAC_DRC_HEAVY_COMPRESSION =
        $0203, (*!< MPEG-4 DRC: En-/Disable DVB specific heavy compression (aka
                   RF mode). If set to 1, the decoder will apply the compression
                   values from the DVB specific ancillary data field. At the same
                   time the MPEG-4 Dynamic Range Control tool will be disabled. By
                     default, heavy compression is disabled. *)
    AAC_DRC_DEFAULT_PRESENTATION_MODE =
        $0204, (*!< MPEG-4 DRC: Default presentation mode (DRC parameter
                   handling). \n Defines the handling of the DRC parameters boost
                   factor, attenuation factor and heavy compression, if no
                   presentation mode is indicated in the bitstream.\n For options,
                   see ::AAC_DRC_DEFAULT_PRESENTATION_MODE_OPTIONS.\n Default:
                   ::AAC_DRC_PARAMETER_HANDLING_DISABLED *)
    AAC_DRC_ENC_TARGET_LEVEL =
        $0205, (*!< MPEG-4 DRC: Encoder target level for light (i.e. not heavy)
                   compression.\n If known, this declares the target reference
                   level that was assumed at the encoder for calculation of
                   limiting gains. The valid values range from 0 (full-scale) to
                   127 (31.75 dB below full-scale). This parameter is used only
                   with ::AAC_DRC_PARAMETER_HANDLING_ENABLED and ignored
                   otherwise.\n Default: 127 (worst-case assumption).\n *)
    AAC_UNIDRC_SET_EFFECT = $0206, (*!< MPEG-D DRC: Request a DRC effect type for
                                       selection of a DRC set.\n Supported indices
                                       are:\n -1: DRC off. Completely disables
                                       MPEG-D DRC.\n 0: None (default). Disables
                                       MPEG-D DRC, but automatically enables DRC
                                       if necessary to prevent clipping.\n 1: Late
                                       night\n 2: Noisy environment\n 3: Limited
                                       playback range\n 4: Low playback level\n 5:
                                       Dialog enhancement\n 6: General
                                       compression. Used for generally enabling
                                       MPEG-D DRC without particular request.\n *)
    AAC_UNIDRC_ALBUM_MODE =
        $0207, (*!<  MPEG-D DRC: Enable album mode. 0: Disabled (default), 1:
                   Enabled.\n Disabled album mode leads to application of gain
                   sequences for fading in and out, if provided in the
                   bitstream.\n Enabled album mode makes use of dedicated album
                   loudness information, if provided in the bitstream.\n *)
    AAC_QMF_LOWPOWER =
        $0300, (*!< Quadrature Mirror Filter (QMF) Bank processing mode. \n
                     -1: Use internal default. \n
                      0: Use complex QMF data mode. \n
                      1: Use real (low power) QMF data mode. \n *)
    AAC_TPDEC_CLEAR_BUFFER =
        $0603 (*!< Clear internal bit stream buffer of transport layers. The
                  decoder will start decoding at new data passed after this event
                  and any previous data is discarded. *)
  );

  TStreamInfo = record
    (* These five members are the only really relevant ones for the user. *)
    sampleRate: Integer; (*!< The sample rate in Hz of the decoded PCM audio signal. *)
    frameSize: Integer;  (*!< The frame size of the decoded PCM audio signal. \n
                         Typically this is: \n
                         1024 or 960 for AAC-LC \n
                         2048 or 1920 for HE-AAC (v2) \n
                         512 or 480 for AAC-LD and AAC-ELD \n
                         768, 1024, 2048 or 4096 for USAC  *)
    numChannels: Integer; (*!< The number of output audio channels before the rendering
                        module, i.e. the original channel configuration. *)
    pChannelType: PAudioChannelType; (*!< Audio channel type of each output audio channel. *)
    pChannelIndices: PByte; (*!< Audio channel index for each output audio
                               channel. See ISO/IEC 13818-7:2005(E), 8.5.3.2
                               Explicit channel mapping using a
                               program_config_element() *)
    (* Decoder internal members. *)
    aacSampleRate: Integer; (*!< Sampling rate in Hz without SBR (from configuration
                          info) divided by a (ELD) downscale factor if present. *)
    profile: Integer; (*!< MPEG-2 profile (from file header) (-1: not applicable (e. g.
                    MPEG-4)).               *)

    aot: TAudioObjectType; (*!< Audio Object Type (from ASC): is set to the appropriate value
            for MPEG-2 bitstreams (e. g. 2 for AAC-LC). *)
    channelConfig: Integer; (*!< Channel configuration (0: PCE defined, 1: mono, 2:
                          stereo, ...                       *)
    bitRate: Integer;       (*!< Instantaneous bit rate.                   *)
    aacSamplesPerFrame: Integer;   (*!< Samples per frame for the AAC core (from ASC)
                                 divided by a (ELD) downscale factor if present. \n
                                   Typically this is (with a downscale factor of 1):
                                 \n   1024 or 960 for AAC-LC \n   512 or 480 for
                                 AAC-LD   and AAC-ELD         *)
    aacNumChannels: Integer;       (*!< The number of audio channels after AAC core
                                 processing (before PS or MPS processing).       CAUTION: This
                                 are not the final number of output channels! *)
    extAot: TAudioObjectType; (*!< Extension Audio Object Type (from ASC)   *)
    extSamplingRate: Integer; (*!< Extension sampling rate in Hz (from ASC) divided by
                            a (ELD) downscale factor if present. *)

    outputDelay: Cardinal; (*!< The number of samples the output is additionally
                         delayed by.the decoder. *)
    flags: Cardinal; (*!< Copy of internal flags. Only to be written by the decoder,
                   and only to be read externally. *)

    epConfig: ShortInt; (*!< epConfig level (from ASC): only level 0 supported, -1
                       means no ER (e. g. AOT=2, MPEG-2 AAC, etc.)  *)
    (* Statistics *)
    numLostAccessUnits: Integer; (*!< This integer will reflect the estimated amount of
                               lost access units in case aacDecoder_DecodeFrame()
                                 returns AAC_DEC_TRANSPORT_SYNC_ERROR. It will be
                               < 0 if the estimation failed. *)

    numTotalBytes: INT64; (*!< This is the number of total bytes that have passed
                            through the decoder. *)
    numBadBytes: INT64; (*!< This is the number of total bytes that were considered
                    with errors from numTotalBytes. *)
    numTotalAccessUnits: INT64;     (*!< This is the number of total access units that
                                have passed through the decoder. *)
    numBadAccessUnits: INT64; (*!< This is the number of total access units that
                                were considered with errors from numTotalBytes. *)

    (* Metadata *)
    drcProgRefLev: ShortInt; (*!< DRC program reference level. Defines the reference
                            level below full-scale. It is quantized in steps of
                            0.25dB. The valid values range from 0 (0 dBFS) to 127
                            (-31.75 dBFS). It is used to reflect the average
                            loudness of the audio in LKFS according to ITU-R BS
                            1770. If no level has been found in the bitstream the
                            value is -1. *)
    drcPresMode: ShortInt;        (*!< DRC presentation mode. According to ETSI TS 101 154,
                           this field indicates whether   light (MPEG-4 Dynamic Range
                           Control tool) or heavy compression (DVB heavy
                           compression)   dynamic range control shall take priority
                           on the outputs.   For details, see ETSI TS 101 154, table
                           C.33. Possible values are: \n   -1: No corresponding
                           metadata found in the bitstream \n   0: DRC presentation
                           mode not indicated \n   1: DRC presentation mode 1 \n   2:
                           DRC presentation mode 2 \n   3: Reserved *)
    outputLoudness: Integer; (*!< Audio output loudness in steps of -0.25 dB. Range: 0
                           (0 dBFS) to 231 (-57.75 dBFS).\n  A value of -1
                           indicates that no loudness metadata is present.\n  If
                           loudness normalization is active, the value corresponds
                           to the target loudness value set with
                           ::AAC_DRC_REFERENCE_LEVEL.\n  If loudness normalization
                           is not active, the output loudness value corresponds to
                           the loudness metadata given in the bitstream.\n
                             Loudness metadata can originate from MPEG-4 DRC or
                           MPEG-D DRC. *)

  end;

  TAacDecoderInstance = record end;
  PAacDecoderInstance = ^TAacDecoderInstance;

  TAacEncoderInstance = record end;
  PAacEncoderInstance = ^TAacEncoderInstance;

{$IFDEF DynLink}
  // static linking
  TAacDecAncDataInit = function (Self: PAacDecoderInstance; Buffer: PByte; Size: Integer): TAacDecoderError; cdecl;
  TAacDecAncDataGet = function (Self: PAacDecoderInstance; index: Integer; var Buffer: PByte; var Size: Integer): TAacDecoderError; cdecl;
  TAacDecSetParam = function (const Self: PAacDecoderInstance; const param: TAacDecParam; const value: Integer): TAacDecoderError; cdecl;
  TAacDecGetFreeBytes = function (const Self: PAacDecoderInstance; varpFreeBytes: Cardinal): TAacDecoderError; cdecl;
  TAacDecOpen = function (transportFmt: TTransportType; nrOfLayers: Cardinal): TAacDecoderError; cdecl;
  TAacDecConfigRaw = function (Self: PAacDecoderInstance; conf: PByte; const length: Cardinal): TAacDecoderError; cdecl;
  TAacDecFill = function (Self: PAacDecoderInstance; pBuffer: PByte; const bufferSize: Cardinal; var bytesValid: Cardinal): TAacDecoderError; cdecl;
  TAacDecDecodeFrame = function (Self: PAacDecoderInstance; pTimeData: Pointer; const timeDataSize: Integer; const flags: Cardinal): TAacDecoderError; cdecl;
  TAacDecClose = procedure (Self: PAacDecoderInstance); cdecl;
  TAacDecGetStreamInfo = function (Self: PAacDecoderInstance): TStreamInfo; cdecl;
  TAacDecGetLibInfo = function (info: PLIB_INFO): Integer; cdecl;

  TAacEncClose = function (phAacEncoder: PAacEncoderInstance): TAacEncoderError; cdecl;
  TAacEncEncode = function (const hAacEncoder: PAacEncoderInstance; var inBufDesc, outBufDesc: AACENC_BufDesc; var inargs: AACENC_InArgs; var outargs: AACENC_OutArgs): TAacEncoderError; cdecl;
  TAacEncInfo = function (const hAacEncoder: PAacEncoderInstance; var Info: AACENC_InfoStruct): TAacEncoderError; cdecl;
  TAacEncOpen = function (phAacEncoder: PAacEncoderInstance; const encModules: Cardinal; const maxChannels: Cardinal): TAacEncoderError; cdecl;
  TAacEncGetParam = function (const hAacEncoder: PAacEncoderInstance; const param: Cardinal): Cardinal; cdecl;
  TAacEncSetParam = function (const hAacEncoder: PAacEncoderInstance; const param: Cardinal; const value: Cardinal): TAacEncoderError; cdecl;
  TAacEncGetLibInfo = function (info: PLIB_INFO): TAacEncoderError; cdecl;

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
  function AacDecSetParam(const Self: PAacDecoderInstance; const param: TAacDecParam; const value: Integer): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_SetParam';
  function AacDecGetFreeBytes(const Self: PAacDecoderInstance; varpFreeBytes: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_GetFreeBytes';
  function AacDecOpen(transportFmt: TTransportType; nrOfLayers: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_Open';
  function AacDecConfigRaw(Self: PAacDecoderInstance; conf: PByte; const length: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_ConfigRaw';
  function AacDecFill(Self: PAacDecoderInstance; pBuffer: PByte; const bufferSize: Cardinal; var bytesValid: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_Fill';
  function AacDecDecodeFrame(Self: PAacDecoderInstance; pTimeData: Pointer; const timeDataSize: Integer; const flags: Cardinal): TAacDecoderError; cdecl; external CLibFdkAac name 'aacDecoder_DecodeFrame';
  procedure AacDecClose(Self: PAacDecoderInstance); cdecl; external CLibFdkAac name 'aacDecoder_Close';
  function AacDecGetStreamInfo(Self: PAacDecoderInstance): TStreamInfo; cdecl; external CLibFdkAac name 'aacDecoder_GetStreamInfo';
  function AacDecGetLibInfo(info: PLIB_INFO): Integer; cdecl; external CLibFdkAac name 'aacDecoder_GetLibInfo';

  function AacEncClose(phAacEncoder: PAacEncoderInstance): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncClose';
  function AacEncEncode(const hAacEncoder: PAacEncoderInstance; var inBufDesc, outBufDesc: AACENC_BufDesc; var inargs: AACENC_InArgs; var outargs: AACENC_OutArgs): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncoder_Encode';
  function AacEncInfo(const hAacEncoder: PAacEncoderInstance; var Info: AACENC_InfoStruct): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncInfo';
  function AacEncOpen(phAacEncoder: PAacEncoderInstance; const encModules: Cardinal; const maxChannels: Cardinal): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncOpen';
  function AacEncGetParam(const hAacEncoder: PAacEncoderInstance; const param: TAacEncParam): Cardinal; cdecl; external CLibFdkAac name 'aacEncoder_GetParam';
  function AacEncSetParam(const hAacEncoder: PAacEncoderInstance; const param: TAacEncParam; const value: Cardinal): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncoder_SetParam';
  function AacEncGetLibInfo(info: PLIB_INFO): TAacEncoderError; cdecl; external CLibFdkAac name 'aacEncGetLibInfo';

{$ENDIF}

implementation

{$IFDEF DynLink}
uses
{$IFDEF FPC}
  DynLibs;
{$ELSE}
{$IFDEF MSWindows}
  Windows;
{$ENDIF}
{$ENDIF}
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

{$IFDEF DynLink}
initialization
  InitDLL;

finalization
  FreeDLL;
{$ENDIF}

end.
