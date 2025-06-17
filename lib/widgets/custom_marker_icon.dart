import 'package:flutter/material.dart';

class CustomMarkerIcon extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final double iconSize;
  final String? tooltip;

  const CustomMarkerIcon({
    super.key,
    required this.iconData,
    this.iconColor = Colors.red,
    this.iconSize = 40.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, color: iconColor, size: iconSize),
        if (tooltip != null && tooltip!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tooltip!,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
