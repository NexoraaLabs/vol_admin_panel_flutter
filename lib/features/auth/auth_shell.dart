import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';

/// Figma frames 705:3646 / 705:4534: black canvas with the purple swirl spilling past every edge,
/// the VÔL hero image filling the left 868/1920 of the screen, and the form centred on the right.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dak.bg,
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // inset: -55.06% -35.93% -79.91% -27.19%
              Positioned(
                left: -w * .2719,
                right: -w * .3593,
                top: -h * .5506,
                bottom: -h * .7991,
                child: const IgnorePointer(child: AssetIcon('illustrations/swirl-bg.svg', fit: BoxFit.fill)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (context.isLg)
                    SizedBox(
                      width: w * .452,
                      child: const Stack(
                        fit: StackFit.expand,
                        children: [
                          AssetIcon('illustrations/auth-hero.png', fit: BoxFit.cover),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(.78, -.63),
                                end: Alignment(-.78, .63),
                                stops: [.0552, .9882],
                                colors: [Color(0x289436FB), Color(0x339436FB)],
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-.46, -.89),
                                end: Alignment(.46, .89),
                                stops: [.0152, 1],
                                colors: [Color(0x2E121212), Color(0x2B050505)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: h),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: context.isSm ? 32 : 16, vertical: 40),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 570),
                              child: Column(
                                children: [
                                  for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 40), children[i]],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.body});

  final String title;
  final List<InlineSpan> body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.dvh(110, 14, 150),
          width: context.dvh(73, 9.3, 100),
          child: Semantics(
            label: 'VÔL',
            image: true,
            child: const AssetIcon('brand/admin-logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 498),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.dvw(26, 2.4, 32), fontWeight: FontWeight.w700, color: Dak.heading),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(children: body),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 23 / 16, color: Dak.body),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The big purple submit button on the sign-in screens.
class AuthButton extends StatelessWidget {
  const AuthButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? .6 : 1,
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Dak.cta,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x669436FB), offset: Offset(0, 8), blurRadius: 6)],
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: .28, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
