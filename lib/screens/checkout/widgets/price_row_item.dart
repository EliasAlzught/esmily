import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/tools/price_tools.dart';
import '../../../models/app_model.dart';
import '../../../models/cart/cart_base.dart';

class PriceRowItemWidget extends StatelessWidget {
  final String title;
  final double? total;
  final TextStyle? style;
  final bool isWalletTopup;

  const PriceRowItemWidget({
    super.key,
    required this.title,
    this.total,
    this.style,
    this.isWalletTopup = false,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;
    final model = Provider.of<CartModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: Row(

      ),
    );
  }
}
