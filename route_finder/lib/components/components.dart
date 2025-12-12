import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route_finder/logic/firebase_helper.dart';
import 'package:route_finder/logic/helpers.dart';
import 'package:route_finder/logic/models.dart';
import 'package:route_finder/pages/routes/route_details_page.dart';
import 'package:toastification/toastification.dart';

const Color kPrimary = Color(0xFF4C6FFF);
const Color kPrimaryVariant = Color(0xFF6D4CFF);
const Color kAccent = Color(0xFF1AD598);
const Color kBgLight = Color(0xFFFFFFFF);
const Color kSurfaceLight = Color(0xFFF6F8FF);
const Color kTextPrimary = Color(0xFF0F1724);
const Color kTextMuted = Color(0xFF6B7280);
const double kRadiusMd = 12.0;
const double kRadiusLg = 16.0;
const double kRadiusXl = 24.0;

class AppColor {
  static const Color primary = Color(0xFFFF9143);
  static const Color secondary = Color(0xFF29746F);

  static const Color background = Color(0xFFFFF8F0);
  static const Color backgroundSecondary = Color(0xFFEBEBE3);
  static const Color backgroundDark = Color(0xFFF1EAE4);

  static const Color textPrimary = Color(0xFF2C314A);
  static const Color textMuted = Color(0xFF6D7392);

  static const Color outline = Color(0xFFE7E1DA);
}

/// Small helper for marker data
class MapMarker {
  final String id;
  final Coordinate coord;
  final String label;
  final Color color;
  const MapMarker({
    required this.id,
    required this.coord,
    required this.label,
    this.color = Colors.deepOrange,
  });
}

/* ---------------------------
   AppButton
   - variants: primary, ghost, outline, danger
   - sizes: small, medium, large
   - isLoading, enabled, leading/trailing
   --------------------------- */
enum AppButtonVariant { primary, ghost, outline, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool enabled;
  final bool? fullWidth;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final BorderRadius? borderRadius;

  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.width,
    this.borderRadius,
    this.fullWidth = true,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  Color _foregroundFor(AppButtonVariant v) {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    switch (v) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.ghost:
        return AppColor.primary;
      case AppButtonVariant.outline:
        return AppColor.primary;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Color _backgroundFor(AppButtonVariant v) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (v) {
      case AppButtonVariant.primary:
        return AppColor.primary;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return Colors.red;
    }
  }

  Border? _borderFor(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.outline:
        return Border.all(color: widget.borderColor ?? AppColor.primary);
      case AppButtonVariant.ghost:
        return Border.all(color: widget.borderColor ?? AppColor.primary);
      default:
        return null;
    }
  }

  double _heightFor(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.small:
        return 40;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = _heightFor(widget.size);
    final br = widget.borderRadius ?? BorderRadius.circular(kRadiusMd);
    final bg = _backgroundFor(widget.variant);
    final fg = _foregroundFor(widget.variant);
    final border = _borderFor(widget.variant);
    final scale = _pressed ? 0.98 : 1.0;

    final button = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Container(
            width: widget.width,
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: br,
              border: border,
              boxShadow:
                  widget.variant == AppButtonVariant.ghost ||
                      widget.variant == AppButtonVariant.outline
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: br,
                onTap: widget.enabled && !widget.isLoading
                    ? widget.onTap
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: widget.width == null
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        )
                      else ...[
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: AppText(
                            widget.label,
                            variant: widget.size != AppButtonSize.small
                                ? AppTextVariant.body
                                : AppTextVariant.label,
                            weightOverride: FontWeight.w600,
                            textAlign: TextAlign.center,
                            colorOverride: _foregroundFor(widget.variant),
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.trailing!,
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.fullWidth == true
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/* ---------------------------
   AppChip (tag / removable)
   --------------------------- */
class AppChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool selected;
  final Color? color;
  const AppChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (color ?? Colors.white).withOpacity(0.12)
        : Colors.grey[100];
    final textColor = selected ? (color ?? Colors.white) : AppColor.textPrimary;
    return Container(
      padding: EdgeInsets.all(AppSpacings.md),
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: AppSpacings.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(label, colorOverride: textColor),
          if (onDeleted != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(LucideIcons.x300, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

/* ---------------------------
   SearchBar with chips & suggestions
   - minimal but functional demo
   --------------------------- */
typedef ChipCallback = void Function(String);

class SearchChipsBar extends StatefulWidget {
  final List<String> initialChips;
  final List<String> suggestions;
  final ChipCallback? onChipAdded;
  final ChipCallback? onChipRemoved;
  final ValueChanged<String>? onSubmitted;
  final String placeholder;

  const SearchChipsBar({
    super.key,
    this.initialChips = const [],
    this.suggestions = const [],
    this.onChipAdded,
    this.onChipRemoved,
    this.onSubmitted,
    this.placeholder = 'Procura temas — ex.: arte, história, comida',
  });

  @override
  State<SearchChipsBar> createState() => _SearchChipsBarState();
}

class _SearchChipsBarState extends State<SearchChipsBar> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  late List<String> _chips;
  List<String> _filteredSuggestions = [];

  List<String> _startingSuggestions = [];

  @override
  void initState() {
    super.initState();
    _chips = List.from(widget.initialChips);
    _filteredSuggestions = widget.suggestions;
    _ctrl.addListener(_onTextChanged);

    _startingSuggestions = _filteredSuggestions;
  }

  void _onTextChanged() {
    final q = _ctrl.text.toLowerCase();
    setState(() {
      _filteredSuggestions = widget.suggestions
          .where((s) => s.toLowerCase().contains(q) && !_chips.contains(s))
          .toList();
    });
  }

  void _addFromText() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (!_chips.contains(text)) {
      setState(() => _chips.add(text));
      widget.onChipAdded?.call(text);
    }
    _ctrl.clear();
    _focus.requestFocus();
  }

  void _removeChip(String c) {
    setState(() => _chips.remove(c));
    widget.onChipRemoved?.call(c);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusMd),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              widget.onSubmitted?.call(v);
              _addFromText();
            },
            decoration: InputDecoration(
              hintText: widget.placeholder,
              prefixIcon: const Icon(
                LucideIcons.search300,
                color: AppColor.textMuted,
              ),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () => _ctrl.clear(),
                      child: const Icon(
                        LucideIcons.x300,
                        color: AppColor.textMuted,
                      ),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_filteredSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacings.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._filteredSuggestions.map(
                    (s) => GestureDetector(
                      onTap: () {
                        setState(() => _chips.add(s));
                        widget.onChipAdded?.call(s);
                        setState(() => _filteredSuggestions.remove(s));
                        _ctrl.clear();
                        _focus.requestFocus();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacings.md),
                        child: Chip(
                          backgroundColor: Colors.white,
                          label: AppText(
                            s,
                            variant: AppTextVariant.caption,
                            colorOverride: AppColor.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_chips.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacings.md),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppText(
                  "Filtering by:",
                  variant: AppTextVariant.title,
                  colorOverride: Colors.white,
                ),
                ..._chips.map(
                  (c) => AppChip(
                    label: c,
                    onDeleted: () {
                      _removeChip(c);
                      if (_startingSuggestions.contains(c)) {
                        setState(() => _filteredSuggestions.add(c));
                      }
                    },
                    selected: true,
                  ),
                ),
                AppButton(
                  label: "Clear",
                  leading: Icon(
                    LucideIcons.trash2300,
                    size: 20,
                    color: Colors.white,
                  ),
                  fullWidth: false,
                  variant: AppButtonVariant.outline,
                  foregroundColor: Colors.white,
                  borderColor: Colors.white,
                  size: AppButtonSize.small,
                  onTap: () => setState(() {
                    _chips.map((c) => _removeChip(c));
                    _chips.clear();
                  }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/* ---------------------------
   RadiusSlider
   --------------------------- */

class RadiusSlider extends StatelessWidget {
  final double valueKm;
  final ValueChanged<double> onChanged;
  final double minKm;
  final double maxKm;
  final int divisions;

  const RadiusSlider({
    super.key,
    required this.valueKm,
    required this.onChanged,
    this.minKm = 0.5,
    this.maxKm = 20,
    this.divisions = 195, // step 0.1 -> (20-0.5)/0.1 = 195
  });

  @override
  Widget build(BuildContext context) {
    final display = valueKm % 1 == 0
        ? valueKm.toStringAsFixed(0)
        : valueKm.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Raio: $display km',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          min: minKm,
          max: maxKm,
          divisions: divisions,
          value: valueKm.clamp(minKm, maxKm),
          onChanged: onChanged,
          activeColor: kPrimary,
          inactiveColor: kPrimary.withOpacity(0.18),
        ),
      ],
    );
  }
}

/* ---------------------------
   POICard
   --------------------------- */
class POICard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final double? rating;
  final bool openNow;
  final List<String> tags;
  final VoidCallback? onTap;

  const POICard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.rating,
    this.openNow = false,
    this.tags = const [],
    this.onTap,
  });

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) => AppChip(label: t)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 110,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(
                          LucideIcons.camera300,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(
                        LucideIcons.mapPin300,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (openNow)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Aberto',
                              style: TextStyle(color: kAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (rating != null) ...[
                          Icon(
                            LucideIcons.star300,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: _buildTags()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------------
   Bottom sheet helper
   --------------------------- */
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: child,
    ),
  );
}

/* ---------------------------
   AppFAB (floating action with subtle pulse)
   --------------------------- */
class AppFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget? child;
  final double size;

  const AppFAB({
    super.key,
    required this.onPressed,
    this.child,
    this.size = 56.0,
  });

  @override
  State<AppFAB> createState() => _AppFABState();
}

class _AppFABState extends State<AppFAB> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        child: widget.child ?? const Icon(LucideIcons.navigation300),
      ),
    );
  }
}

/* ---------------------------
   AppToast (simple helper)
   --------------------------- */
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final sm = ScaffoldMessenger.of(context);
    sm.hideCurrentSnackBar();
    sm.showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }
}

/* ---------------------------
   SkeletonBox (shimmer-ish)
   --------------------------- */
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final shimmerPos = (_ctrl.value * 2) - 1; // -1..1
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade300,
              ],
              stops: [
                (shimmerPos + 1) / 4,
                (shimmerPos + 1) / 2,
                (shimmerPos + 1) * 3 / 4,
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ---------------------------
   RatingStars (interactive)
   --------------------------- */
class RatingStars extends StatefulWidget {
  final int initial;
  final void Function(int)? onChanged;
  final double size;

  const RatingStars({
    super.key,
    this.initial = 0,
    this.onChanged,
    this.size = 28,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  void _set(int v) {
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  Widget _star(int idx) {
    final filled = idx <= _value;
    return GestureDetector(
      onTap: () => _set(idx),
      child: AnimatedScale(
        scale: filled ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Icon(
          LucideIcons.star300,
          color: filled ? Colors.amber[700] : Colors.grey[400],
          size: widget.size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(5, (i) => _star(i + 1)));
  }
}

/* ---------------------------
   ImageCarousel
   --------------------------- */
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;

  const ImageCarousel({super.key, required this.images, this.height = 200});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(child: Icon(LucideIcons.camera300, size: 48)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.images[i],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) {
            final active = i == _page;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 12 : 8,
              height: active ? 8 : 8,
              decoration: BoxDecoration(
                color: active ? kPrimary : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/* ---------------------------
   Lottie presets wrappers
   - Requires `lottie` dependency
   --------------------------- */
class LottieLoader extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final bool loop;

  const LottieLoader({
    super.key,
    required this.asset,
    this.width = 120,
    this.height = 120,
    this.loop = true,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Lottie.asset(asset, width: width, height: height, repeat: loop);
    } catch (e) {
      // fallback
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }
}

/* ---------------------------
   Small modal helper
   --------------------------- */
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog(content: child),
  );
}

enum AppTextVariant { display, heading, title, body, label, caption, small }

const Map<AppTextVariant, double> _kVariantFontSize = {
  AppTextVariant.display: 40.0,
  AppTextVariant.heading: 26.0,
  AppTextVariant.title: 20.0,
  AppTextVariant.body: 18.0,
  AppTextVariant.label: 16.0,
  AppTextVariant.caption: 14.0,
  AppTextVariant.small: 12.0,
};

const Map<AppTextVariant, FontWeight> _kVariantFontWeight = {
  AppTextVariant.display: FontWeight.w700,
  AppTextVariant.heading: FontWeight.w600,
  AppTextVariant.title: FontWeight.w600,
  AppTextVariant.body: FontWeight.w400,
  AppTextVariant.label: FontWeight.w500,
  AppTextVariant.caption: FontWeight.w400,
  AppTextVariant.small: FontWeight.w400,
};

class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? colorOverride;
  final FontWeight? weightOverride;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;
  final TextStyle? style;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.body,
    this.colorOverride,
    this.weightOverride,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.softWrap = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize =
        _kVariantFontSize[variant] ?? _kVariantFontSize[AppTextVariant.body]!;
    final FontWeight defaultWeight =
        _kVariantFontWeight[variant] ?? FontWeight.w400;

    final Color effectiveColor =
        colorOverride ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        Colors.black87;

    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: weightOverride ?? defaultWeight,
      color: effectiveColor,
      height: _lineHeightFor(fontSize),
      fontFamily: 'Nunito',
    );

    final TextStyle finalStyle = (style != null) ? base.merge(style) : base;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  double _lineHeightFor(double size) {
    if (size >= 26) return 1.2;
    if (size >= 20) return 1.3;
    if (size >= 18) return 1.4;
    return 1.25;
  }
}

class SafeAreaPadding extends StatelessWidget {
  final Widget child;
  const SafeAreaPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }
}

class AppSpacings {
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppTextInput extends StatefulWidget {
  final String label;
  final String placeholder;
  final String? suffix;
  final bool? requiredField;
  final bool? obscureText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final TextInputType? keyboard;
  final TextEditingController controller;
  final String? error;
  final bool? multiline;
  final int? maxLines;

  // Novos: foco e navegação por teclado
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const AppTextInput({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.requiredField = true,
    this.obscureText = false,
    this.leadingIcon,
    this.suffix,
    this.trailingIcon,
    this.keyboard = TextInputType.text,
    this.error,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.onChanged,
    this.multiline,
    this.maxLines,
  });

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  late bool _hasText;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _obscured = widget.obscureText ?? false;
    _hasText = widget.controller.text.isNotEmpty;
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant AppTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // obscure sync
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText ?? false;
    }

    // controller swap handling
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
      _hasText = widget.controller.text.isNotEmpty;
    }

    // focusNode swap handling
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) {
        try {
          _focusNode.dispose();
        } catch (_) {}
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      try {
        // _AppSelectInputState.openNotifier.value = null;
      } catch (_) {}
    }
    setState(() {});
  }

  void _onTextChange() {
    final nowHas = widget.controller.text.isNotEmpty;
    if (nowHas != _hasText) setState(() => _hasText = nowHas);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    final bool hasValue = _hasText;

    Color borderColor;
    double borderWidth;
    if (widget.error != null) {
      borderColor = Colors.red;
      borderWidth = 2.0;
    } else if (focused) {
      borderColor = AppColor.primary;
      borderWidth = 2.0;
    } else if (hasValue) {
      borderColor = AppColor.textPrimary;
      borderWidth = 1.0;
    } else {
      borderColor = Colors.grey;
      borderWidth = 1.0;
    }

    final Color iconColor = focused ? AppColor.textPrimary : AppColor.textMuted;

    return Column(
      spacing: AppSpacings.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != "")
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(widget.label, variant: AppTextVariant.label),
              if (widget.requiredField ?? false)
                Icon(LucideIcons.asterisk300, color: Colors.red, size: 12),
            ],
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusMd),
            color: AppColor.backgroundDark,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacings.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(widget.leadingIcon, size: 24, color: iconColor),
                  SizedBox(width: AppSpacings.md),
                ],
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    keyboardType: widget.keyboard,
                    obscureText: _obscured,
                    maxLines: widget.maxLines ?? 1,
                    cursorColor: AppColor.primary,
                    textInputAction:
                        widget.textInputAction ?? TextInputAction.done,
                    onEditingComplete: widget.onEditingComplete,
                    onSubmitted: widget.onSubmitted,
                    onChanged: widget.onChanged,
                    style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 18,
                      height: 1.5,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        color: AppColor.textMuted,
                        fontSize: 18,
                        height: 1.5,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      try {
                        // _AppSelectInputState.openNotifier.value = null;
                      } catch (_) {}
                    },
                  ),
                ),

                if (widget.suffix != null) ...[
                  SizedBox(width: AppSpacings.md),
                  AppText(
                    widget.suffix!,
                    variant: AppTextVariant.label,
                    colorOverride: AppColor.textMuted,
                  ),
                ],

                if (widget.obscureText == true) ...[
                  SizedBox(width: AppSpacings.md),
                  GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured ? LucideIcons.eyeOff300 : LucideIcons.eye300,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ] else if (widget.trailingIcon != null) ...[
                  SizedBox(width: AppSpacings.md),
                  Icon(widget.trailingIcon, size: 24, color: iconColor),
                ],
              ],
            ),
          ),
        ),
        if (widget.error != null) ...[
          SizedBox(height: AppSpacings.sm),
          AppText(
            widget.error!,
            variant: AppTextVariant.label,
            colorOverride: Colors.red,
          ),
        ],
      ],
    );
  }
}

class AppCodeInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int length;
  final bool requiredField;
  final String? error;
  final ValueChanged<String>? onCompleted;
  final TextInputType keyboard;

  const AppCodeInput({
    super.key,
    required this.label,
    required this.controller,
    this.length = 6,
    this.requiredField = true,
    this.error,
    this.onCompleted,
    this.keyboard = TextInputType.number,
  });

  @override
  State<AppCodeInput> createState() => _AppCodeInputState();
}

class _AppCodeInputState extends State<AppCodeInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sanitizeController());
  }

  void _onFocusChange() => setState(() {});

  void _onTextChanged() {
    final filtered = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (filtered != widget.controller.text) {
      final sel = filtered.length.clamp(0, widget.length);
      widget.controller.value = TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: sel),
      );
      return;
    }

    if (mounted) setState(() {});

    if (filtered.length == widget.length) {
      // chama callback de complete, mas NÃO desfoca automaticamente
      widget.onCompleted?.call(filtered);
      // Se realmente quiseres desfocar automaticamente, faz isso no pai
      // depois de processar a confirmação (assim evita corrida foco/teclado).
    }
  }

  void _sanitizeController() {
    final filtered = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = filtered.length > widget.length
        ? filtered.substring(0, widget.length)
        : filtered;
    if (truncated != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _waitForFocus(Duration timeout) {
    final completer = Completer<bool>();
    void listener() {
      if (_focusNode.hasFocus && !completer.isCompleted) {
        _focusNode.removeListener(listener);
        completer.complete(true);
      }
    }

    _focusNode.addListener(listener);

    Timer(timeout, () {
      if (!completer.isCompleted) {
        _focusNode.removeListener(listener);
        completer.complete(_focusNode.hasFocus);
      }
    });

    return completer.future;
  }

  void _focusAtIndex(int i) async {
    final len = widget.controller.text.length;
    final offset = i <= len ? i : len;

    // se já tem foco aplica selection imediatamente
    if (_focusNode.hasFocus) {
      widget.controller.selection = TextSelection.collapsed(offset: offset);
      setState(() {});
      return;
    }

    // pede foco
    FocusScope.of(context).requestFocus(_focusNode);

    // força o teclado a abrir (resolve plataformas onde o teclado aparece
    // mas o FocusNode demora a reportar hasFocus)
    try {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    } catch (_) {}

    // espera até o FocusNode reportar foco (até timeout)
    final got = await _waitForFocus(const Duration(milliseconds: 300));

    // aplica seleção e actualiza UI (mesmo que o focus não tenha sido reportado)
    widget.controller.selection = TextSelection.collapsed(offset: offset);
    if (mounted) setState(() {});

    // se continua sem foco, como fallback pede foco e abre teclado outra vez
    if (!got) {
      try {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final focused = _focusNode.hasFocus;

    return Column(
      spacing: AppSpacings.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(widget.label, variant: AppTextVariant.label),
            if (widget.requiredField) ...[
              SizedBox(width: AppSpacings.xs),
              Icon(LucideIcons.asterisk300, color: Colors.red, size: 12),
            ],
          ],
        ),

        LayoutBuilder(
          builder: (ctx, constraints) {
            final gap = AppSpacings.md;
            final totalGap = gap * (widget.length - 1);
            final raw = (constraints.maxWidth - totalGap) / widget.length;
            final boxWidth = raw.clamp(44.0, 64.0);
            final boxHeight = 56.0;

            return Stack(
              children: [
                // TextField por baixo (invisível) — recebe input quando focado
                Positioned.fill(
                  child: SizedBox(
                    height: boxHeight,
                    child: Opacity(
                      opacity: 0.0,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: widget.controller,
                        keyboardType: widget.keyboard,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(widget.length),
                        ],
                        cursorColor: kPrimary,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        style: const TextStyle(
                          color: Colors.transparent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                Row(
                  children: List.generate(widget.length, (i) {
                    final isFilled = i < text.length;
                    final isCurrent = focused && i == text.length;
                    final displayChar = isFilled ? text[i] : (i + 1).toString();
                    final isPlaceholder = !isFilled;

                    Color borderColor;
                    double borderWidth;

                    if (widget.error != null) {
                      borderColor = Colors.red;
                      borderWidth = 2.0;
                    } else if (isCurrent) {
                      borderColor = kPrimary;
                      borderWidth = 2.0;
                    } else if (isFilled) {
                      borderColor = kTextPrimary;
                      borderWidth = 1.0;
                    } else {
                      borderColor = Colors.grey.withValues(alpha: 0.4);
                      borderWidth = 1.0;
                    }

                    return GestureDetector(
                      onTap: () => _focusAtIndex(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        width: boxWidth,
                        height: boxHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadiusMd),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                          right: i == widget.length - 1 ? 0 : gap,
                        ),
                        child: Text(
                          displayChar,
                          style: TextStyle(
                            color: isPlaceholder
                                ? Colors.grey.withValues(alpha: 0.6)
                                : kTextPrimary,
                            fontSize: 18,
                            height: 1.5,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),

        if (widget.error != null) ...[
          SizedBox(height: AppSpacings.sm),
          AppText(
            widget.error!,
            variant: AppTextVariant.label,
            colorOverride: Colors.red,
          ),
        ],
      ],
    );
  }
}

class ShadowedLottie extends StatefulWidget {
  final String name;

  /// Quando null, o widget tenta preencher o espaço disponível (p.ex. dentro de Expanded).
  final double? height;
  final double? width;

  /// Offset do "shadow" em pixels (podes usar valores pequenos se o container for grande).
  final Offset shadowOffset;

  /// Blur e opacidade do shadow
  final double shadowBlur;
  final double shadowOpacity;

  /// Fit do Lottie (por defeito contain)
  final BoxFit fit;

  /// Cor do shadow (normalmente preto)
  final Color shadowColor;

  /// Fallback quando não há constraints finitas (por ex. Column sem Expanded)
  final double fallbackHeight;

  const ShadowedLottie({
    super.key,
    required this.name,
    this.height,
    this.width,
    this.shadowOffset = const Offset(6, 8),
    this.shadowBlur = 6.0,
    this.shadowOpacity = 0.45,
    this.fit = BoxFit.contain,
    this.shadowColor = Colors.black,
    this.fallbackHeight = 200,
  });

  @override
  State<ShadowedLottie> createState() => _ShadowedLottieState();
}

class _ShadowedLottieState extends State<ShadowedLottie>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Não definimos duration aqui — vamos obter do composition onLoaded.
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Chamado quando um Lottie carrega a composição. Só arrancamos o controller uma vez.
  void _onLoaded(LottieComposition composition) {
    if (!_started) {
      _started = true;
      _controller.duration = composition.duration;
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asset path
    final assetPath = 'assets/lotties/${widget.name}.json';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Se o utilizador passou uma height explícita, usamos essa.
        if (widget.height != null) {
          return SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height,
            child: _buildStack(assetPath),
          );
        }

        // Se o parent forneceu uma altura finita (p.ex. Expanded), usamos esse espaço.
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          return SizedBox(
            width: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity,
            height: constraints.maxHeight,
            child: _buildStack(assetPath),
          );
        }

        // Se não houver altura finita mas houver largura finita (por exemplo conained by row),
        // definimos uma altura proporcional à largura.
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          final fallback = constraints.maxWidth * 0.6;
          return SizedBox(
            width: constraints.maxWidth,
            height: fallback,
            child: _buildStack(assetPath),
          );
        }

        // Caso extremo: nenhum constraint finito -> fallback height para evitar overflow
        return SizedBox(
          height: widget.fallbackHeight,
          child: _buildStack(assetPath),
        );
      },
    );
  }

  // Cria a Stack com a layer de "shadow" (blur + color filter) e a layer principal.
  Widget _buildStack(String assetPath) {
    // layer de shadow: Lottie tintado a preto, opacidade e blur aplicados
    final shadow = Transform.translate(
      offset: widget.shadowOffset,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: widget.shadowBlur,
          sigmaY: widget.shadowBlur,
        ),
        child: Opacity(
          opacity: widget.shadowOpacity,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(widget.shadowColor, BlendMode.srcIn),
            child: Lottie.asset(
              assetPath,
              controller: _controller,
              fit: widget.fit,
              onLoaded: _onLoaded,
            ),
          ),
        ),
      ),
    );

    // layer principal
    final main = Lottie.asset(
      assetPath,
      controller: _controller,
      fit: widget.fit,
      onLoaded: _onLoaded,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // shadow atrás
        Positioned.fill(child: Center(child: shadow)),
        // animação principal
        Positioned.fill(child: Center(child: main)),
      ],
    );
  }
}

class RouteCard extends StatefulWidget {
  final RouteModel route;
  const RouteCard({super.key, required this.route});

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  double scale = 1.0;

  double _averageRating() {
    final pois = widget.route.waypoints;
    if (pois.isEmpty) return 0.0;
    final sum = pois.map((p) => p.rating).reduce((a, b) => a + b);
    return sum / pois.length;
  }

  double _calculateDistance() {
    double totalDistance = 0.0;
    if (widget.route.waypoints.isEmpty) return 0.0;

    // Start to first waypoint
    totalDistance += Geolocator.distanceBetween(
      widget.route.start.coordinate.lat,
      widget.route.start.coordinate.lng,
      widget.route.waypoints.first.coordinates.lat,
      widget.route.waypoints.first.coordinates.lng,
    );

    // Between waypoints
    for (int i = 0; i < widget.route.waypoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        widget.route.waypoints[i].coordinates.lat,
        widget.route.waypoints[i].coordinates.lng,
        widget.route.waypoints[i + 1].coordinates.lat,
        widget.route.waypoints[i + 1].coordinates.lng,
      );
    }

    // Last waypoint to end
    totalDistance += Geolocator.distanceBetween(
      widget.route.waypoints.last.coordinates.lat,
      widget.route.waypoints.last.coordinates.lng,
      widget.route.end.coordinate.lat,
      widget.route.end.coordinate.lng,
    );

    return totalDistance / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final poiImage =
        widget.route.waypoints.isNotEmpty &&
            widget.route.waypoints.first.photos.isNotEmpty
        ? widget
              .route
              .waypoints
              .first
              .photos
              .first
              .name // This is not a URL, but we'll use it for now or need a placeholder
        : null;

    // Use a placeholder if name is not a URL (which it likely isn't)
    // For now, let's assume we don't have a valid image URL unless we construct it.
    // We'll skip the image if it's not a valid asset path or URL.
    final validImage =
        poiImage != null &&
            (poiImage.startsWith('http') || poiImage.startsWith('assets'))
        ? poiImage
        : null;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      scale: scale,
      child: Transform.scale(
        scale: scale.toDouble(),
        child: GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.98),
          onTapUp: (_) => setState(() => scale = 1),
          onTapCancel: () => setState(() => scale = 1),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadiusMd),
            ),
            child: Column(
              children: [
                if (validImage != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(kRadiusMd),
                    ),
                    child: Image.asset(
                      validImage,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(
                          LucideIcons.camera300,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                Divider(height: 1, color: Colors.grey[100]),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacings.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Route to ${widget.route.end.address}",
                          variant: AppTextVariant.title,
                        ),
                        SizedBox(height: AppSpacings.sm),
                        Wrap(
                          children: widget.route.waypoints
                              .expand((w) => w.types)
                              .toSet()
                              .take(4)
                              .map((kw) => AppChip(label: kw))
                              .toList(),
                        ),
                        SizedBox(height: AppSpacings.md),
                        Row(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin300,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: AppSpacings.sm),
                                AppText(
                                  '${_calculateDistance().toStringAsFixed(1)} km',
                                  variant: AppTextVariant.label,
                                  colorOverride: Colors.grey,
                                ),
                              ],
                            ),
                            SizedBox(width: AppSpacings.md),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.clock3300,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: AppSpacings.sm),
                                AppText(
                                  'N/A min',
                                  variant: AppTextVariant.label,
                                  colorOverride: Colors.grey,
                                ),
                              ],
                            ),
                            SizedBox(width: AppSpacings.md),
                            AppText(
                              '${widget.route.waypoints.length} stops',
                              variant: AppTextVariant.label,
                              colorOverride: Colors.grey,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacings.md),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.star300,
                              size: 20,
                              color: Colors.amber[700],
                            ),
                            SizedBox(width: AppSpacings.sm),
                            AppText(
                              _averageRating().toStringAsFixed(1),
                              variant: AppTextVariant.label,
                              colorOverride: kTextPrimary,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacings.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SavedRouteCard extends StatelessWidget {
  final RouteModel route;
  const SavedRouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "https://places.googleapis.com/v1/${route.waypoints.first.photos.first.name}/media?maxWidthPx=400&key=${dotenv.env['GOOGLE_PLACES_API_KEY'] ?? ''}",
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: AppSpacings.lg,
                right: AppSpacings.lg,
                child: GestureDetector(
                  onTap: () async {
                    final result = await showOkCancelAlertDialog(
                      context: context,
                      title: "Delete Route",
                      message: "Are you sure you want to delete this route?",
                      okLabel: "Delete",
                      cancelLabel: "Cancel",
                    );

                    if (result != OkCancelResult.ok) return;

                    if (route.id != null) {
                      final response = await FirebaseHelper.deleteRoute(
                        routeId: route.id ?? "",
                      );
                      if (response['success'] != true) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          title: AppText(
                            'Delete failed!',
                            variant: AppTextVariant.title,
                            weightOverride: FontWeight.w600,
                          ),
                          description: AppText(
                            'An unknown error occurred.',
                            variant: AppTextVariant.label,
                            weightOverride: FontWeight.w600,
                            colorOverride: Colors.grey,
                          ),
                          autoCloseDuration: const Duration(seconds: 2),
                          dragToClose: true,
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppSpacings.md),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Icon(LucideIcons.trash300, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsetsGeometry.all(AppSpacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  route.name,
                  variant: AppTextVariant.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacings.md),
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin300,
                          size: 20,
                          color: Colors.grey,
                        ),
                        SizedBox(width: AppSpacings.sm),
                        AppText(
                          '${route.routeData['distance'].toStringAsFixed(1)} km',
                          variant: AppTextVariant.label,
                          colorOverride: Colors.grey,
                        ),
                      ],
                    ),
                    SizedBox(width: AppSpacings.md),
                    Expanded(
                      child: AppText(
                        '${route.waypoints.length} stops',
                        variant: AppTextVariant.label,
                        colorOverride: Colors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacings.lg),
                AppButton(
                  label: "Details",
                  leading: Icon(LucideIcons.info300, color: Colors.white),
                  size: AppButtonSize.medium,
                  onTap: () {
                    context.pushAnimated(RouteDetailsPage(route: route));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TripMapCard extends StatefulWidget {
  final List<RouteModel> route;
  final Future<void> Function(RouteModel)? onSave;
  const TripMapCard({super.key, required this.route, this.onSave});

  @override
  State<TripMapCard> createState() => _TripMapCardState();
}

class _TripMapCardState extends State<TripMapCard> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _loading = true;

  // caches per-route
  final Map<int, List<LatLng>> _routePointsByIndex = {};
  final Map<int, List<int>> _routeOptimizedOrder = {};
  final Map<int, LatLngBounds> _routeBounds = {};
  final Map<int, List<Marker>> _routeCachedMarkers = {};

  // icons per-route
  final Map<int, BitmapDescriptor> _poiIcons = {};
  final Map<int, BitmapDescriptor> _startIcons = {};

  // page controller for cards (enables swipe -> select)
  late final PageController _pageController;
  int _selectedIndex = 0;

  static const List<Color> _palette = [
    AppColor.primary,
    AppColor.secondary,
    Colors.teal,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.86,
      initialPage: _selectedIndex,
    );
    _initMap();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    if (widget.route.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // reset
    _markers.clear();
    _polylines.clear();
    _routePointsByIndex.clear();
    _routeOptimizedOrder.clear();
    _routeBounds.clear();
    _routeCachedMarkers.clear();

    setState(() {});

    // prepare small icons for each route (colored)
    await _prepareIcons();

    final List<LatLng> allPoints = [];

    for (var routeIndex = 0; routeIndex < widget.route.length; routeIndex++) {
      final route = widget.route[routeIndex];
      final pois = route.waypoints;
      if (pois.isEmpty) continue;

      // debug prints (keeps your previous diagnostics)
      for (var i = 0; i < pois.length; i++) {
        final p = pois[i];
        debugPrint(
          'Route $routeIndex POI[$i] ${p.name} -> lat=${p.coordinates.lat}, lng=${p.coordinates.lng}',
        );
      }

      final origin = pois.first.coordinates;
      final waypoints = <Coordinate>[];
      for (var i = 1; i < pois.length; i++) {
        waypoints.add(pois[i].coordinates);
      }

      List<LatLng> routePoints = [];

      try {
        final encoded = route.routeData['encodedPolyline'] as String?;
        if (encoded != null && encoded.isNotEmpty) {
          final decoded = decodePolyline(encoded);
          routePoints = decoded.map((c) => LatLng(c.lat, c.lng)).toList();
        } else {
          // fallback to client-side TSP
          final fallbackOrder = _solveTspNearestNeighbor(origin, waypoints);
          final pts = [origin, ...fallbackOrder, origin];
          routePoints = pts.map((c) => LatLng(c.lat, c.lng)).toList();
        }
      } catch (e) {
        debugPrint('Error decoding polyline for route $routeIndex: $e');
        // fallback to client-side TSP
        final fallbackOrder = _solveTspNearestNeighbor(origin, waypoints);
        final pts = [origin, ...fallbackOrder, origin];
        routePoints = pts.map((c) => LatLng(c.lat, c.lng)).toList();
      }

      // cache route points & bounds
      _routePointsByIndex[routeIndex] = routePoints;
      final bounds = _boundsFromLatLngList(routePoints);
      if (bounds != null) _routeBounds[routeIndex] = bounds;

      // add polyline (initial width depends on selection)
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$routeIndex'),
          color: _palette[routeIndex % _palette.length],
          width: (_selectedIndex == routeIndex) ? 6 : 4,
          points: routePoints,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: _selectedIndex == routeIndex ? 1 : 0,
        ),
      );

      // pre-build markers for this route (cached) but do NOT add to _markers yet
      _routeCachedMarkers[routeIndex] = _buildMarkersForRoute(
        route,
        routeIndex,
        _routeOptimizedOrder[routeIndex] ?? [],
      );

      allPoints.addAll(routePoints);
      setState(() {}); // update progressively so polylines appear as they come
    }

    // Show markers only for selected index
    _updateMarkersForSelectedRoute();

    setState(() => _loading = false);

    // fit camera to allPoints if available
    if (allPoints.isNotEmpty) {
      if (mapController != null) {
        await _fitCameraToPolyline(mapController!, allPoints);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController != null) {
            _fitCameraToPolyline(mapController!, allPoints);
          }
        });
      }
    }
  }

  Future<void> _prepareIcons() async {
    for (var i = 0; i < widget.route.length; i++) {
      final color = _palette[i % _palette.length];
      _poiIcons[i] = await createCircleBitmapDescriptor(
        borderColor: Colors.white,
        color,
        40,
      );
      _startIcons[i] = await createCircleBitmapDescriptor(
        Colors.white,
        40,
        borderColor: color,
        borderWidth: 3,
      );
    }
  }

  List<Marker> _buildMarkersForRoute(
    RouteModel route,
    int routeIndex,
    List<int> optimizedOrder,
  ) {
    final markers = <Marker>[];
    final pois = route.waypoints;
    if (pois.isEmpty) return markers;

    final colorPoi = _poiIcons[routeIndex];
    final colorStart = _startIcons[routeIndex];

    // start
    final origin = pois.first.coordinates;
    if (_isValidLatLng(origin.lat, origin.lng)) {
      markers.add(
        Marker(
          markerId: MarkerId('r${routeIndex}_start'),
          position: LatLng(origin.lat, origin.lng),
          icon: colorStart ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: "Route", snippet: 'Start'),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    final intermediate = pois.sublist(1);
    if (optimizedOrder.isNotEmpty &&
        optimizedOrder.length == intermediate.length) {
      for (
        var orderIndex = 0;
        orderIndex < optimizedOrder.length;
        orderIndex++
      ) {
        final originalWaypointIndex = optimizedOrder[orderIndex];
        if (originalWaypointIndex < 0 ||
            originalWaypointIndex >= intermediate.length) {
          continue;
        }
        final poi = intermediate[originalWaypointIndex];
        if (!_isValidLatLng(poi.coordinates.lat, poi.coordinates.lng)) continue;
        markers.add(
          Marker(
            markerId: MarkerId('r${routeIndex}_poi_${orderIndex + 1}'),
            position: LatLng(poi.coordinates.lat, poi.coordinates.lng),
            icon: colorPoi ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: 'Stop ${orderIndex + 1}',
              snippet: poi.name,
            ),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    } else {
      for (var j = 0; j < intermediate.length; j++) {
        final poi = intermediate[j];
        if (!_isValidLatLng(poi.coordinates.lat, poi.coordinates.lng)) continue;
        markers.add(
          Marker(
            markerId: MarkerId('r${routeIndex}_poi_${j + 1}'),
            position: LatLng(poi.coordinates.lat, poi.coordinates.lng),
            icon: colorPoi ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: 'Stop ${j + 1}', snippet: poi.name),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    return markers;
  }

  // expose only markers for selected route
  void _updateMarkersForSelectedRoute() {
    _markers.clear();
    final cached = _routeCachedMarkers[_selectedIndex];
    if (cached != null && cached.isNotEmpty) {
      _markers.addAll(cached);
    } else {
      // fallback: build simple markers from POIs
      if (_selectedIndex >= 0 && _selectedIndex < widget.route.length) {
        final r = widget.route[_selectedIndex];
        final pois = r.waypoints;
        if (pois.isNotEmpty) {
          final start = pois.first;
          if (_isValidLatLng(start.coordinates.lat, start.coordinates.lng)) {
            _markers.add(
              Marker(
                markerId: MarkerId('r${_selectedIndex}_start_fb'),
                position: LatLng(start.coordinates.lat, start.coordinates.lng),
                icon:
                    _startIcons[_selectedIndex] ??
                    BitmapDescriptor.defaultMarker,
                infoWindow: InfoWindow(title: "Route", snippet: 'Start'),
                anchor: const Offset(0.5, 1.0),
              ),
            );
          }
          for (var j = 0; j < pois.length; j++) {
            final p = pois[j];
            if (!_isValidLatLng(p.coordinates.lat, p.coordinates.lng)) continue;
            _markers.add(
              Marker(
                markerId: MarkerId('r${_selectedIndex}_poi_fb_$j'),
                position: LatLng(p.coordinates.lat, p.coordinates.lng),
                icon:
                    _poiIcons[_selectedIndex] ?? BitmapDescriptor.defaultMarker,
                infoWindow: InfoWindow(title: 'Stop ${j + 1}', snippet: p.name),
                anchor: const Offset(0.5, 0.5),
              ),
            );
          }
        }
      }
    }
    setState(() {});
  }

  // helper to validate lat/lng
  bool _isValidLatLng(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  // rebuild polylines so selected one is thicker
  void _rebuildPolylinesWithSelection() {
    _polylines.clear();
    for (var i = 0; i < widget.route.length; i++) {
      final pts =
          _routePointsByIndex[i] ?? _polyPointsFromPOIs(widget.route[i]);
      if (pts.isEmpty) continue;
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          color: _palette[i % _palette.length],
          width: (i == _selectedIndex) ? 8 : 4,
          points: pts,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          zIndex: i == _selectedIndex ? 1 : 0,
        ),
      );
    }
    setState(() {});
  }

  List<LatLng> _polyPointsFromPOIs(RouteModel route) {
    final pts = <LatLng>[];
    for (final p in route.waypoints) {
      if (_isValidLatLng(p.coordinates.lat, p.coordinates.lng)) {
        pts.add(LatLng(p.coordinates.lat, p.coordinates.lng));
      }
    }
    if (pts.length > 1) {
      if (pts.first.latitude != pts.last.latitude ||
          pts.first.longitude != pts.last.longitude) {
        // close loop
        pts.add(pts.first);
      }
    }
    return pts;
  }

  Future<void> _selectRoute(int index) async {
    if (index < 0 || index >= widget.route.length) return;
    if (_selectedIndex == index) {
      // already selected: just recenter if we have bounds
      final bounds = _routeBounds[index];
      if (bounds != null && mapController != null) {
        await _fitCameraToPolyline(mapController!, _routePointsByIndex[index]!);
      }
      return;
    }

    _selectedIndex = index;
    _rebuildPolylinesWithSelection();
    _updateMarkersForSelectedRoute();

    // animate to route bounds if available
    final bounds = _routeBounds[index];
    if (bounds != null &&
        mapController != null &&
        _routePointsByIndex[index] != null) {
      await _fitCameraToPolyline(mapController!, _routePointsByIndex[index]!);
    } else if (mapController != null) {
      // fallback center on first POI
      final r = widget.route[index];
      if (r.waypoints.isNotEmpty) {
        final c = r.waypoints.first.coordinates;
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(c.lat, c.lng), 14),
        );
      }
    }
  }

  Future<void> _fitCameraToPolyline(
    GoogleMapController controller,
    List<LatLng> points,
  ) async {
    if (points.isEmpty) return;

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if ((maxLat - minLat).abs() < 1e-6) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if ((maxLng - minLng).abs() < 1e-6) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 28));
      await Future.delayed(const Duration(milliseconds: 200));
      await controller.animateCamera(CameraUpdate.zoomBy(1.0));
    } catch (_) {
      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      try {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(center, 14));
      } catch (_) {}
    }
  }

  LatLngBounds? _boundsFromLatLngList(List<LatLng> points) {
    if (points.isEmpty) return null;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    if ((maxLat - minLat).abs() < 1e-6) {
      minLat -= 0.0005;
      maxLat += 0.0005;
    }
    if ((maxLng - minLng).abs() < 1e-6) {
      minLng -= 0.0005;
      maxLng += 0.0005;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  CameraPosition _initial() {
    if (widget.route.isEmpty) {
      return const CameraPosition(target: LatLng(0, 0), zoom: 2);
    }
    final first = widget.route.first;
    final pts = _polyPointsFromPOIs(first);
    if (pts.isEmpty) return const CameraPosition(target: LatLng(0, 0), zoom: 2);
    if (pts.length >= 2) {
      final a = pts[0];
      final b = pts[1];
      return CameraPosition(
        target: LatLng(
          (a.latitude + b.latitude) / 2,
          (a.longitude + b.longitude) / 2,
        ),
        zoom: 12,
      );
    } else {
      return CameraPosition(target: pts.first, zoom: 13);
    }
  }

  double _avgRating(RouteModel r) {
    if (r.waypoints.isEmpty) return 0.0;
    final sum = r.waypoints.map((p) => p.rating).reduce((a, b) => a + b);
    return sum / r.waypoints.length;
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = 150.0;

    return SizedBox(
      height: cardHeight,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial(),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              mapController = controller;
              if (!_loading && _selectedIndex >= 0) {
                final pts = _routePointsByIndex[_selectedIndex];
                if (pts != null && pts.isNotEmpty) {
                  _fitCameraToPolyline(mapController!, pts);
                }
              }
            },
            zoomControlsEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            liteModeEnabled: false,
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.03),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(
                bottom: AppSpacings.lg,
                left: AppSpacings.md,
                right: AppSpacings.md,
              ),
              child: SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.route.length,
                  onPageChanged: (index) => _selectRoute(index),
                  itemBuilder: (context, i) {
                    final r = widget.route[i];
                    final selected = _selectedIndex == i;
                    final color = _palette[i % _palette.length];
                    final thumbnail = Image.network(
                      "https://places.googleapis.com/v1/${r.waypoints.first.photos.first.name}/media?maxWidthPx=400&key=${dotenv.env['GOOGLE_PLACES_API_KEY'] ?? ''}",
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacings.lg),
                      child: GestureDetector(
                        onTap: () => _selectRoute(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  selected ? 0.10 : 0.06,
                                ),
                                blurRadius: selected ? 12 : 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(AppSpacings.lg),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: thumbnail,
                                ),
                              ),
                              SizedBox(width: AppSpacings.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppText(
                                      r.name,
                                      variant: AppTextVariant.body,
                                      weightOverride: FontWeight.w600,
                                    ),
                                    const SizedBox(height: AppSpacings.sm),
                                    AppText(
                                      '${r.waypoints.length} stops',
                                      variant: AppTextVariant.label,
                                      colorOverride: Colors.grey,
                                    ),
                                    SizedBox(height: AppSpacings.lg),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 20,
                                          color: Colors.amber,
                                        ),
                                        SizedBox(width: AppSpacings.sm),
                                        AppText(
                                          _avgRating(r).toStringAsFixed(1),
                                          variant: AppTextVariant.label,
                                        ),
                                        if (widget.onSave != null) ...[
                                          Spacer(),
                                          GestureDetector(
                                            onTap: () async {
                                              await widget.onSave!(r);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColor.primary
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                LucideIcons.download300,
                                                size: 20,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<BitmapDescriptor> createCircleBitmapDescriptor(
  Color color,
  int size, {
  Color? borderColor,
  double borderWidth = 2,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final radius = size / 2.0;

  final paint = Paint()..color = color;
  canvas.drawCircle(Offset(radius, radius), radius, paint);

  if (borderColor != null && borderWidth > 0) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(
      Offset(radius, radius),
      radius - borderWidth / 2,
      borderPaint,
    );
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final bd = await img.toByteData(format: ImageByteFormat.png);
  final bytes = bd!.buffer.asUint8List();
  return BitmapDescriptor.fromBytes(bytes);
}

double _avgRating(RouteModel r) {
  if (r.waypoints.isEmpty) return 0.0;
  final sum = r.waypoints.map((p) => p.rating).reduce((a, b) => a + b);
  return sum / r.waypoints.length;
}

class OptimizedRouteResult {
  final List<Coordinate> polyline;
  final List<int> optimizedWaypointOrder;
  OptimizedRouteResult({
    required this.polyline,
    required this.optimizedWaypointOrder,
  });
}

Future<OptimizedRouteResult> fetchOptimizedRoundTripRoutesAPI(
  Coordinate origin,
  List<Coordinate> waypoints,
  String apiKey,
) async {
  if (waypoints.isEmpty) {
    return OptimizedRouteResult(polyline: [origin], optimizedWaypointOrder: []);
  }

  final url = Uri.parse(
    'https://routes.googleapis.com/directions/v2:computeRoutes',
  );

  final intermediates = waypoints
      .map(
        (w) => {
          "location": {
            "latLng": {"latitude": w.lat, "longitude": w.lng},
          },
        },
      )
      .toList();

  final body = jsonEncode({
    "origin": {
      "location": {
        "latLng": {"latitude": origin.lat, "longitude": origin.lng},
      },
    },
    "destination": {
      "location": {
        "latLng": {"latitude": origin.lat, "longitude": origin.lng},
      },
    },
    "intermediates": intermediates,
    "travelMode": "WALK",
    "polylineQuality": "HIGH_QUALITY",
    "optimizeWaypointOrder": true,
  });

  final res = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      // include optimized intermediate waypoint indices in the fieldmask (required when optimizeWaypointOrder=true)
      'X-Goog-FieldMask':
          'routes.polyline.encodedPolyline,routes.optimized_intermediate_waypoint_index',
    },
    body: body,
  );

  if (res.statusCode != 200) {
    throw Exception('Routes API error ${res.statusCode}: ${res.body}');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final routes = data['routes'] as List<dynamic>?;
  if (routes == null || routes.isEmpty) {
    return OptimizedRouteResult(polyline: [], optimizedWaypointOrder: []);
  }

  final routeMap = routes[0] as Map<String, dynamic>;

  String? encoded;
  try {
    final poly = routeMap['polyline'];
    if (poly is Map) {
      encoded =
          poly['encodedPolyline'] ??
          poly['encoded_polyline'] ??
          poly['encodedPolyline'];
    }
  } catch (_) {}

  encoded ??= routeMap['overviewPolyline']?['points'] as String?;

  List<Coordinate> polylinePoints = [];
  if (encoded != null && encoded.isNotEmpty) {
    polylinePoints = decodePolyline(encoded);
  }

  // extract optimized indices (try several key variants)
  List<int> optimized = [];
  dynamic optRaw;
  if (routeMap.containsKey('optimizedIntermediateWaypointIndex')) {
    optRaw = routeMap['optimizedIntermediateWaypointIndex'];
  } else if (routeMap.containsKey('optimized_intermediate_waypoint_index'))
    optRaw = routeMap['optimized_intermediate_waypoint_index'];
  else {
    for (final k in routeMap.keys) {
      final lk = k.toString().toLowerCase();
      if (lk.contains('optimized') && lk.contains('index')) {
        optRaw = routeMap[k];
        break;
      }
    }
  }
  if (optRaw is List) {
    optimized = optRaw
        .map<int>((e) => int.tryParse(e.toString()) ?? 0)
        .toList();
  }

  return OptimizedRouteResult(
    polyline: polylinePoints,
    optimizedWaypointOrder: optimized,
  );
}

List<Coordinate> decodePolyline(String encoded) {
  final List<Coordinate> points = [];
  int index = 0;
  int lat = 0, lng = 0;

  while (index < encoded.length) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(Coordinate(lat: lat / 1E5, lng: lng / 1E5));
  }

  return points;
}

double _haversineDistance(Coordinate a, Coordinate b) {
  const R = 6371000;
  final phi1 = a.lat * math.pi / 180;
  final phi2 = b.lat * math.pi / 180;
  final dPhi = (b.lat - a.lat) * math.pi / 180;
  final dLambda = (b.lng - a.lng) * math.pi / 180;

  final sinDPhi = math.sin(dPhi / 2);
  final sinDLambda = math.sin(dLambda / 2);
  final aa =
      sinDPhi * sinDPhi +
      math.cos(phi1) * math.cos(phi2) * sinDLambda * sinDLambda;
  final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
  return R * c;
}

List<Coordinate> _solveTspNearestNeighbor(
  Coordinate origin,
  List<Coordinate> stops,
) {
  if (stops.isEmpty) return [];
  final remaining = List<Coordinate>.from(stops);
  final order = <Coordinate>[];
  var current = origin;
  while (remaining.isNotEmpty) {
    remaining.sort(
      (a, b) => _haversineDistance(
        current,
        a,
      ).compareTo(_haversineDistance(current, b)),
    );
    final next = remaining.removeAt(0);
    order.add(next);
    current = next;
  }
  return order;
}
