import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/constants.dart';
import '../../../generated/l10n.dart';
import '../../../models/entities/transaction.dart';
import '../../../models/tera_wallet/index.dart';
import '../../../widgets/common/refresh_scroll_physics.dart';
import '../helpers/wallet_helpers.dart';
import 'widgets/transaction_item.dart';
import 'widgets/transaction_item_skeleton.dart';



class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({Key? key}) : super(key: key);

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}


launcdURLInBrowser1() async {
  const url = 'https://help.esimly.io/about-us';
  if (await canLaunch(url)) {
    await launch(url);

  }
}
launcdURLInBrowser2() async {
  const url = 'https://help.esimly.io/privacy-policy';
  if (await canLaunch(url)) {
    await launch(url);
  }
}launcdURLInBrowser5() async {
  const url = 'https://help.esimly.io';
  if (await canLaunch(url)) {
    await launch(url);
  }
}
launcdURLInBrowser3() async {
  const url = 'https://wa.me/+971508016707';
  if (await canLaunch(url)) {
    await launch(url);
  }

}
class _MyWalletScreenState extends State<MyWalletScreen> {
  WalletModel get _walletModel =>
      Provider.of<WalletModel>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {

        _walletModel.getBalance();
        _walletModel.getListTransaction();

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        physics: const RefreshScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              'Help Center',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await Future.wait([
                _walletModel.getBalance(),
                _walletModel.refreshListTransaction(),
              ]);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCard(),
                        const SizedBox(height: 16),
                        _buildCardAction(),
                        const SizedBox(height: 16),
                        Container(

                          decoration: BoxDecoration(

                            color: const Color(0xFF004E6B),
                            borderRadius: BorderRadius.circular(20.0),

                          ),
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(vertical: 0),

                          child: Row(

                            children: <Widget>[


                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10.0),

                                ),



                                const Flexible(child:
                                Text(
                                  'That is all communication ways,You can also reach us by using the customer service icon on all pages and contacting us.',



                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFFFFFF),
                                    fontFamily: 'Genos',
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                                )
                              ,






                              Image.asset('assets/images/helpicon.png',height:40,width:40, fit: BoxFit.fill),
                              // row here can add

                            ],
                          ),



                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  Selector<WalletTransactionModel, List<Transaction>?>(
                    selector: (_, model) => model.data.take(10).toList(),
                    builder: (context, listTransaction, child) {
                      if (listTransaction == null) {
                        return ListView.separated(
                          itemBuilder: (_, index) {
                            return const TransactionItemSkeleton();
                          },
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 5,
                          shrinkWrap: true,
                          separatorBuilder: (_, __) => const Divider(),
                        );
                      }



                      return ListView.separated(
                        itemBuilder: (_, index) {
                          final transaction = listTransaction[index];
                          return TransactionItem(
                            key: ValueKey(transaction.id),
                            transaction: transaction,
                          );
                        },
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listTransaction.length,
                        shrinkWrap: true,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 35,
              child: _buildCardFake(
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1)),
            ),
            Transform.rotate(
              angle: -math.pi / 35,
              child: _buildCardFake(
                  Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
            ),
            Consumer<WalletModel>(builder: (context, model, child) {
              return _buildCardInfo(
                color: Theme.of(context).primaryColor.withOpacity(0.9),
                fullName: model.user.fullName,
                balance: '${model.balance}',
                cardId: '5345345345',
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFake(Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color,
      ),
      height: MediaQuery.of(context).size.height / 4 - 8,
    );
  }

  Widget _buildCardInfo({
    required Color color,
    required String fullName,
    required String cardId,
    required String balance,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
      ),
      height: MediaQuery.of(context).size.height / 4,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Do you need Someone To Help You,',

                      style: TextStyle(fontSize: 24,color: Colors.white, fontFamily: 'Genos',
                        fontWeight: FontWeight.w900,),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    Text('${fullName}?',

                      style: const TextStyle(fontSize: 24,color: Colors.green, fontFamily: 'Genos',
                        fontWeight: FontWeight.w900,),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    // const SizedBox(height: 12),
                    // Text(
                    //   cardId,
                    //   style: Theme.of(context).textTheme.headline6!.copyWith(
                    //         color: Colors.white.withOpacity(0.8),
                    //       ),
                    // ),
                  ],
                ),
              ),

            ],
          ),
          Flexible(

            child:
              Text(
                'The three pages below where you can learn more about us or contact us if you have any problems',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Colors.white.withOpacity(0.8),fontSize:12
                    ),
              ),


          )
        ],
      ),
    );
  }

  Widget _buildCardAction() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Wrap(

        children: [
      ElevatedButton(
      style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4A4A4C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), //

      ),
    ),
    child: const Text('About'),
    onPressed: () {
    launcdURLInBrowser1();
    },
    ),const SizedBox(width: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), //

              ),
            ),
            child: const Text('Privacy'),
            onPressed: () {
              launcdURLInBrowser2();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), //

              ),
            ),
            child: const Text('Contact us'),
            onPressed: () {
              launcdURLInBrowser3();
            },
          ),const SizedBox(width: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), //

              ),
            ),

            child: const Text('Help Center'),
            onPressed: () {
              launcdURLInBrowser5();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionItem({
    required String actionName,
    required Widget icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            padding: const EdgeInsets.all(12),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            actionName,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
