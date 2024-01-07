import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';

class EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return SizedBox(
      width: screenSize.width,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width:
              screenSize.width / (2 / (screenSize.height / screenSize.width)),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/leaves.png',
                  width: 120,
                  height: 120,
                ),
              ),
              Column(
                children: <Widget>[
                  const SizedBox(height: 60),
                  Text('Your bag of eSIMS is empty',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text( 'Looks like you haven’t added any eSIM to the bag yet. Start Choosing Your destination to fill it in.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 50)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
