import 'package:flutter/material.dart';

import 'expansion_tile.dart';

class ExpansionInfo extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final bool expand;
  final List<Widget> children;

  const ExpansionInfo({
    this.title = '',
    this.titleWidget,
    required this.children,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      initiallyExpanded: expand,
      bottomBorderOn: false,
      topBorderOn: false,

      header: Flexible(
       child: Text(''),
      ),
      children: children,
    );
  }
}
