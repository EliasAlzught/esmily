import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/constants.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/entities/user.dart';
import '../../../../models/search_model.dart';
import '../../../../models/user_model.dart';
import '../../../../routes/flux_navigate.dart';

import 'recent_products_custom.dart';





import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

launcdURLInBrowserr() async {
  const url = 'https://www.google.com';
  if (await canLaunch(url)) {
    await launch(url);
  }
}
class RecentSearchesCustom extends StatelessWidget {
  final Function? onTap;
  final User? user;

  const RecentSearchesCustom({this.onTap, this.user});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final widthContent = (screenSize.width / 2) - 4;

    return Consumer<SearchModel>(
      builder: (context, model, child) {
        return (model.keywords.isEmpty)
            ? renderEmpty(context)
            : renderKeywords(model, widthContent, context);
      },
    );
  }

  Widget renderEmpty(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[   const SizedBox(
        width: 250,
        child: Text(
          'All Your eSIMS  you have been order is there.',
          style: TextStyle(color: kGrey400),
          textAlign: TextAlign.center,
        ),
      ),
        const SizedBox(height: 20),
        Container(

          child: InkWell(

            splashColor: Colors.grey, // Splash color
              onTap : () {
                final user = Provider.of<UserModel>(context, listen: false).user;
                FluxNavigate.pushNamed(
                  RouteList.orders,
                  arguments: user,
                );
              },
            child: Container(

                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(

                  color: const Color(0xFF004E6B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(4, 8), // Shadow position
                    ),
                  ],
                ),
                child: const Text('My eSIM')),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            SizedBox(width:10),

            SizedBox(width:5),










          ],
        ),  const SizedBox(height:15),

        const SizedBox(height:5),



        const SizedBox(height: 150),

        const SizedBox(height: 20),
        Container(

          decoration: BoxDecoration(

            color: const Color(0xFF4F7942),
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
                  'If you encounter any problem, click on the help center to get  immediate help.',



                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFFFFF),
                    fontFamily: 'Genos',
                    fontWeight: FontWeight.w400,
                  ),
                )
                )
              ,






              Image.asset('assets/images/help-desk.png',height:40,width:40, fit: BoxFit.fill),
              // row here can add

            ],
          ),



        ),
        const SizedBox(height: 20),
        Container(



          child:  Container(

            child: InkWell(

              splashColor: Colors.grey, // Splash color
              onTap : () {
                final user = Provider.of<UserModel>(context, listen: false).user;
                FluxNavigate.pushNamed(
                  RouteList.myWallet,
                  arguments: user,
                );
              },
              child: Container(

                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(

                    color: const Color(0xFF4A4A4C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(4, 8), // Shadow position
                      ),
                    ],
                  ),
                  child: const Text('Help Center')),
            ),
          ),



        ),
      ],
    );
  }

  Widget renderKeywords(
      SearchModel model, double widthContent, BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                S.of(context).history,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (model.keywords.isNotEmpty)
                InkWell(
                  onTap: model.clearKeywords,
                  child: Text(
                    S.of(context).clear,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                    ),
                  ),
                )
            ],
          ),
        ),
        Card(
          elevation: 0,
          color: Theme.of(context).primaryColorLight,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: model.keywords
                .take(5)
                .map((e) => ListTile(
                      title: Text(e),
                      onTap: () {
                        onTap?.call(e);
                      },
                    ))
                .toList(),
          ),
        ),
        RecentProductsCustom(),
      ],
    );
  }
}
