import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CnpsLogo extends StatelessWidget {
  const CnpsLogo({super.key, this.height = 72, this.fit = BoxFit.contain});

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/cnps_logo.png',
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => SizedBox(
        height: height,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, color: AppTheme.cnpsGreen, size: 38),
            SizedBox(width: 10),
            Text('CNPS', style: TextStyle(color: AppTheme.cnpsBlue, fontSize: 34, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class CnpsColorBar extends StatelessWidget {
  const CnpsColorBar({super.key, this.height = 5});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Row(
      children: [
        Expanded(flex: 5, child: ColoredBox(color: AppTheme.cnpsRed)),
        Expanded(flex: 3, child: ColoredBox(color: AppTheme.cnpsYellow)),
        Expanded(flex: 4, child: ColoredBox(color: AppTheme.cnpsGreen)),
      ],
    ),
  );
}
