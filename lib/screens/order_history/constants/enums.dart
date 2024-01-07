import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

enum MyOrderStatus {
  any('any')

  ;

  const MyOrderStatus(this.status);
  final String status;

  String getName(BuildContext context) {
    return S.of(context).all;
  }
}
