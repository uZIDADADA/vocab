import 'package:flutter/material.dart';

import '../theme/vocab_theme.dart';

const pagePadding = EdgeInsets.fromLTRB(20, 18, 20, 28);

class VocabPageHeader extends StatelessWidget {
  const VocabPageHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        backgroundColor: VocabColors.surface,
        foregroundColor: VocabColors.ink,
        minimumSize: const Size.square(44),
        side: const BorderSide(color: VocabColors.line),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: VocabColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.foreground = VocabColors.ink,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(
        color: foreground,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconWidth = icon == null ? 0.0 : 19.0;
            final maxLabelWidth = constraints.maxWidth.isFinite
                ? (constraints.maxWidth - iconWidth).clamp(0.0, double.infinity)
                : double.infinity;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foreground, size: 14),
                  const SizedBox(width: 5),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxLabelWidth),
                  child: labelText,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.color = VocabColors.surface,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = VocabColors.line,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({
    required this.icon,
    required this.background,
    this.foreground = VocabColors.ink,
    this.size = 46,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: Icon(icon, color: foreground, size: size * .5),
    );
  }
}
