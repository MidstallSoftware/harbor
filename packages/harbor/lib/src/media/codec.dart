/// Video/image codec definitions for the Harbor media engine.

/// Supported video/image codec formats.
enum HarborCodecFormat {
  /// H.264 / MPEG-4 AVC.
  h264('H.264/AVC'),

  /// H.265 / HEVC.
  h265('H.265/HEVC'),

  /// VP9 (WebM).
  vp9('VP9'),

  /// AV1 (Alliance for Open Media).
  av1('AV1'),

  /// JPEG (image only).
  jpeg('JPEG'),

  /// JPEG 2000 (image only).
  jpeg2000('JPEG 2000');

  /// Human-readable codec name.
  final String displayName;

  const HarborCodecFormat(this.displayName);

  /// Whether this codec supports video (multi-frame).
  bool get isVideo => this != jpeg && this != jpeg2000;

  /// Whether this codec supports image (single-frame).
  bool get isImage => true;
}

/// Codec capability (encode, decode, or both).
enum HarborCodecCapability {
  /// Decode only.
  decodeOnly,

  /// Encode only.
  encodeOnly,

  /// Both encode and decode.
  both,
}

/// Codec profile for H.264.
enum HarborH264Profile { baseline, main, high, high10, high422 }

/// Codec profile for H.265/HEVC.
enum HarborH265Profile { main, main10, mainStillPicture, main422_10, main444 }

/// Codec profile for AV1.
enum HarborAv1Profile { main, high, professional }

/// Describes a single codec instance's capabilities.
class HarborCodecInstance {
  /// Codec format.
  final HarborCodecFormat format;

  /// Encode/decode capability.
  final HarborCodecCapability capability;

  /// Maximum resolution width.
  final int maxWidth;

  /// Maximum resolution height.
  final int maxHeight;

  /// Maximum framerate (fps) for video codecs.
  final int maxFps;

  /// Maximum bitrate in Mbps.
  final int maxBitrateMbps;

  /// Supported bit depths (e.g., 8, 10, 12).
  final List<int> bitDepths;

  /// Supported chroma subsampling (e.g., '4:2:0', '4:2:2', '4:4:4').
  final List<String> chromaFormats;

  const HarborCodecInstance({
    required this.format,
    required this.capability,
    this.maxWidth = 3840,
    this.maxHeight = 2160,
    this.maxFps = 60,
    this.maxBitrateMbps = 100,
    this.bitDepths = const [8, 10],
    this.chromaFormats = const ['4:2:0'],
  });

  /// Whether this instance can decode.
  bool get canDecode =>
      capability == HarborCodecCapability.decodeOnly ||
      capability == HarborCodecCapability.both;

  /// Whether this instance can encode.
  bool get canEncode =>
      capability == HarborCodecCapability.encodeOnly ||
      capability == HarborCodecCapability.both;

  /// Whether this supports 4K resolution.
  bool get supports4K => maxWidth >= 3840 && maxHeight >= 2160;

  /// Whether this supports 8K resolution.
  bool get supports8K => maxWidth >= 7680 && maxHeight >= 4320;
}

/// Pixel format for frame buffers.
enum HarborMediaPixelFormat {
  /// NV12: Y plane + interleaved UV, 8-bit, 4:2:0.
  nv12,

  /// NV21: Y plane + interleaved VU, 8-bit, 4:2:0.
  nv21,

  /// I420: Y + U + V planar, 8-bit, 4:2:0.
  i420,

  /// P010: Y + interleaved UV, 10-bit packed in 16-bit, 4:2:0.
  p010,

  /// YUYV: packed 4:2:2.
  yuyv,

  /// RGB24: packed 8-bit RGB.
  rgb24,

  /// ARGB32: packed 8-bit ARGB.
  argb32,
}

/// Rate control mode for encoding.
enum HarborRateControlMode {
  /// Constant QP (quality).
  cqp,

  /// Constant bitrate.
  cbr,

  /// Variable bitrate.
  vbr,

  /// Constant quality (CRF).
  crf,
}
