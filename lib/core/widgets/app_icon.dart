import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_spacing_constant.dart';

/// The kind of source [AppIcon] should render.
enum AppIconVariant {
  icon,
  svgAsset,
  svgNetwork,
  imageAsset,
  imageNetwork,
  imageMemory,
}

/// The app's only icon widget — every icon renders through this so sizing
/// stays consistent across the app (hard rule: no raw [Icon]/[SvgPicture]/
/// [Image] in feature or core code, only here).
///
/// [variant] decides which field is actually used to render:
/// - [AppIconVariant.icon] → [icon]
/// - [AppIconVariant.svgAsset] / [imageAsset] → [source] (asset path)
/// - [AppIconVariant.svgNetwork] / [imageNetwork] → [source] (url)
/// - [AppIconVariant.imageMemory] → [bytes]
///
/// [size] always resolves to a concrete value: it defaults to
/// [AppSpacingConstant.r24] (Material's 24, run through screenutil) so every
/// icon has an explicit size rather than inheriting an ambient one. [color]
/// falls back to the surrounding [IconTheme] when null (ignored for raster
/// images unless [applyColorToImage] is true).
///
/// [hasPadding] wraps the rendered icon with [AppSpacingConstant.r8] padding
/// on all sides — useful for giving tappable icons a larger hit area without
/// affecting the visual icon size itself.
class AppIcon extends StatelessWidget {
  const AppIcon({
    this.icon,
    this.source,
    this.bytes,
    this.size,
    this.color,
    this.applyColorToImage = false,
    this.variant = AppIconVariant.icon,
    this.hasPadding = false,
    this.padding,
    super.key,
  });

  final AppIconVariant variant;

  /// Required when [variant] == [AppIconVariant.icon].
  final IconData? icon;

  /// Asset path or network url. Required when [variant] is svgAsset,
  /// svgNetwork, imageAsset or imageNetwork.
  final String? source;

  /// Required when [variant] == [AppIconVariant.imageMemory].
  final Uint8List? bytes;

  final double? size;
  final Color? color;

  /// Whether to tint raster images (asset/network/memory) with [color].
  /// SVG and [Icon] are always tinted when [color] is set.
  final bool applyColorToImage;

  /// Whether to wrap the icon in padding. Ignored if [padding] is provided.
  final bool hasPadding;

  /// Custom padding around the icon. If set, this takes priority over
  /// [hasPadding] and is applied regardless of [hasPadding]'s value.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? AppSpacingConstant.r24;
    final resolvedColor = color ?? IconTheme.of(context).color;
    final colorFilter = resolvedColor == null
        ? null
        : ColorFilter.mode(resolvedColor, BlendMode.srcIn);

    final Widget child;
    switch (variant) {
      case AppIconVariant.icon:
        assert(
          icon != null,
          'AppIcon: `icon` is required for AppIconVariant.icon',
        );
        child = Icon(icon, size: resolvedSize, color: resolvedColor);

      case AppIconVariant.svgAsset:
        assert(
          source != null,
          'AppIcon: `source` is required for AppIconVariant.svgAsset',
        );
        child = SvgPicture.asset(
          source!,
          width: resolvedSize,
          height: resolvedSize,
          colorFilter: colorFilter,
        );

      case AppIconVariant.svgNetwork:
        assert(
          source != null,
          'AppIcon: `source` is required for AppIconVariant.svgNetwork',
        );
        child = SvgPicture.network(
          source!,
          width: resolvedSize,
          height: resolvedSize,
          colorFilter: colorFilter,
        );

      case AppIconVariant.imageAsset:
        assert(
          source != null,
          'AppIcon: `source` is required for AppIconVariant.imageAsset',
        );
        child = _wrapColor(
          Image.asset(
            source!,
            width: resolvedSize,
            height: resolvedSize,
            fit: BoxFit.contain,
          ),
          resolvedColor,
        );

      case AppIconVariant.imageNetwork:
        assert(
          source != null,
          'AppIcon: `source` is required for AppIconVariant.imageNetwork',
        );
        child = _wrapColor(
          Image.network(
            source!,
            width: resolvedSize,
            height: resolvedSize,
            fit: BoxFit.contain,
          ),
          resolvedColor,
        );

      case AppIconVariant.imageMemory:
        assert(
          bytes != null,
          'AppIcon: `bytes` is required for AppIconVariant.imageMemory',
        );
        child = _wrapColor(
          Image.memory(
            bytes!,
            width: resolvedSize,
            height: resolvedSize,
            fit: BoxFit.contain,
          ),
          resolvedColor,
        );
    }

    final resolvedPadding =
        padding ?? (hasPadding ? EdgeInsets.all(AppSpacingConstant.r8) : null);

    if (resolvedPadding == null) return child;
    return Padding(padding: resolvedPadding, child: child);
  }

  /// Wraps a raster image with a [ColorFiltered] tint when
  /// [applyColorToImage] is enabled and a color is resolved.
  Widget _wrapColor(Widget image, Color? resolvedColor) {
    if (!applyColorToImage || resolvedColor == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      child: image,
    );
  }
}
