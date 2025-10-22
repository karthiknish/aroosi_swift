import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double cardWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isDesktop(context)) return width / 4 - 24;
    if (isTablet(context)) return width / 3 - 20;
    return width / 2 - 18;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    if (isLargeScreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static EdgeInsets contentPadding(BuildContext context) {
    if (isLargeScreen(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }

  static SizedBox spacing(BuildContext context, {double multiplier = 1.0}) {
    final baseSpace = isLargeScreen(context) ? 24.0 : 16.0;
    return SizedBox(height: baseSpace * multiplier);
  }

  static double fontSize(BuildContext context, {SizeType type = SizeType.body}) {
    final baseSize = isLargeScreen(context) ? 1.1 : 1.0;
    
    switch (type) {
      case SizeType.small:
        return 12.0 * baseSize;
      case SizeType.body:
        return 14.0 * baseSize;
      case SizeType.subtitle:
        return 16.0 * baseSize;
      case SizeType.title:
        return 18.0 * baseSize;
      case SizeType.heading:
        return 24.0 * baseSize;
      case SizeType.large:
        return 32.0 * baseSize;
    }
  }

  static int maxListItems(BuildContext context) {
    if (isDesktop(context)) return 12;
    if (isTablet(context)) return 9;
    return 6;
  }
}

enum SizeType {
  small,
  body,
  subtitle,
  title,
  heading,
  large,
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenType screenType) builder;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return builder(context, ScreenType.desktop);
    } else if (Responsive.isTablet(context)) {
      return builder(context, ScreenType.tablet);
    } else {
      return builder(context, ScreenType.mobile);
    }
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

class AdaptiveContainer extends StatelessWidget {
  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.alignment,
    this.constraints,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment ?? Alignment.topCenter,
      padding: padding ?? Responsive.screenPadding(context),
      child: ConstrainedBox(
        constraints: constraints ??
            BoxConstraints(
              maxWidth: maxWidth ?? (Responsive.isDesktop(context) ? 1200 : double.infinity),
            ),
        child: child,
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;

  @override
  Widget build(BuildContext context) {
    final columns = maxColumns ?? Responsive.gridColumns(context);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: Responsive.isTablet(context) ? 1.3 : 1.4,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: Responsive.isTablet(context) ? 270 : 250,
          ),
          child: children[index],
        );
      },
    );
  }
}
