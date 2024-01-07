import 'dart:async';

import 'package:country_pickers/country_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/entities/aftership.dart';
import '../../../models/index.dart' show AppModel, OrderStatus;

// import '../../../models/order/order.dart';
import '../../../models/user_model.dart';
import '../../../services/index.dart';
import '../../../widgets/common/box_comment.dart';
import '../../../widgets/common/webview.dart';
import '../../../widgets/html/index.dart';
import '../../base_screen.dart';
import '../../checkout/widgets/success.dart';
import '../models/order_history_detail_model.dart';
import 'widgets/order_price.dart';
import 'widgets/product_order_item.dart';

class OrderDetailArguments {
  OrderHistoryDetailModel model;
  bool enableReorder;
  bool disableReview;

  OrderDetailArguments(
      {required this.model,
      this.enableReorder = true,
      this.disableReview = false});
}
launcdURLInBrowser() async {
  const url = 'https://help.esimly.io/help-app-page-2';
  if (await canLaunch(url)) {
    await launch(url);
  }
}
class OrderHistoryDetailScreen extends StatefulWidget {
  final bool enableReorder;
  final bool disableReview;

  const OrderHistoryDetailScreen(
      {this.enableReorder = true, this.disableReview = false});

  @override
  BaseScreen<OrderHistoryDetailScreen> createState() =>
      _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState
    extends BaseScreen<OrderHistoryDetailScreen> {
  OrderHistoryDetailModel get orderHistoryModel =>
      Provider.of<OrderHistoryDetailModel>(context, listen: false);

  @override
  void afterFirstLayout(BuildContext context) {
    super.afterFirstLayout(context);
    // orderHistoryModel.getTracking();
    orderHistoryModel.getOrderNote();
  }

  void cancelOrder() {
    orderHistoryModel.cancelOrder();
  }

  void _onNavigate(context, AfterShipTracking afterShipTracking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebView(
          url:
              "${afterShip['tracking_url']}/${afterShipTracking.slug}/${afterShipTracking.trackingNumber}",
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back_ios),
            ),
            title: Text(S.of(context).trackingPage),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderHistoryDetailModel>(builder: (context, model, child) {
      final order = model.order;
      final currencyCode =
          order.currencyCode ?? Provider.of<AppModel>(context).currencyCode!;
      final currencyRate = (order.currencyCode?.isEmpty ?? true)
          ? Provider.of<AppModel>(context).currencyRate
          : null;
      final loggedIn = Provider.of<UserModel>(context).loggedIn;

      final isPending = (order.status != OrderStatus.refunded &&
          order.status != OrderStatus.canceled &&
          order.status != OrderStatus.completed);

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          actions: [
            if (widget.enableReorder && loggedIn)
              Center(child: Services().widget.reOrderButton(order)),
          ],
          title: Text(
            'View Instructions',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0.0,
        ),
        body: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              ...List.generate(
                order.lineItems.length,
                (index) {
                  final item = order.lineItems[index];
                  return ProductOrderItem(
                    orderId: order.id!,
                    orderStatus: order.status!,
                    product: item,
                    index: index,
                    storeDeliveryDates: order.storeDeliveryDates,
                    currencyCode: order.currencyCode,
                    disableReview: widget.disableReview,
                  );
                },

              ),













              if (model.order.aftershipTrackings.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(S.of(context).orderTracking,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Column(
                      children: List.generate(
                        model.order.aftershipTrackings.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: GestureDetector(
                            onTap: () => _onNavigate(
                                context, model.order.aftershipTrackings[index]),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Row(
                                children: <Widget>[
                                  Text(
                                      '${index + 1}. ${S.of(context).trackingNumberIs} '),
                                  Text(
                                    model.order.aftershipTrackings[index]
                                        .trackingNumber!,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              Services().widget.renderOrderTimelineTracking(context, order),


              /// Render the Cancel and Refund
              if (kPaymentConfig.enableRefundCancel)
                Services()
                    .widget
                    .renderButtons(context, order, cancelOrder, refundOrder),


              if (isPending && kPaymentConfig.showTransactionDetails) ...[
                if (order.bacsInfo.isNotEmpty && order.paymentMethod == 'bacs')
                  Text(
                    S.of(context).ourBankDetails,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ...order.bacsInfo
                    .map((e) => BankAccountInfo(bankInfo: e))
                    .toList(),


                /// Thai PromptPay
                /// false: hide show Thank you message - https://tppr.me/xrNh1
                Services()
                    .thaiPromptPayBuilder(showThankMsg: false, order: order),

              ],

              // here
              if (kPaymentConfig.showOrderNotes)
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Builder(
                    builder: (context) {
                      final listOrderNote = model.listOrderNote;
                      if (model.orderNoteLoading) {
                        return kLoadingWidget(context);
                      }
                      if (listOrderNote?.isEmpty ?? true) {
                        return       Container(

                          decoration: BoxDecoration(

                            color: Colors.teal[100] ,
                            borderRadius: BorderRadius.circular(20.0),

                          ),
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(vertical: 0),

                          child: Column(

                            children: <Widget>[
                      if (order.deliveryDate != null &&
                      order.storeDeliveryDates == null)

                      Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),

                      child: Row(

                      children: <Widget>[

                      Text(S.of(context).expectedDeliveryDate,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                      fontWeight: FontWeight.w400,
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                      child: Text(
                      order.deliveryDate!,
                      textAlign: TextAlign.right,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                      fontWeight: FontWeight.w700,
                      ),
                      ),
                      )
                      ],
                      ),
                      ),

                       Row(
                      children: [
                        Image.asset('assets/images/warning1.png',height:40,width:40, fit: BoxFit.fill),
                        const SizedBox(width:5),
                       Flexible(child:

                      Text(
                      'it is take 1-10 min to get your esim, our support team will provide it here as fast as possible and if there any problem please contact us.',



                      style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      fontFamily: 'Genos',
                      fontWeight: FontWeight.w700,
                      ),
                      )
                      )
                      ,








                      ],
                      ),  const SizedBox(height:15),

                              const SizedBox(height:5),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(child:
                                  Text(
                                    'this box will disappear when your esim ready and will appear to you your QR Code with all instructions you need.',


                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                      fontFamily: 'Genos',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  )
                                  )
                                  ,


                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Image.asset('assets/images/qrcode.gif',height:40,width:40, fit: BoxFit.fill),

                                ],
                              ),
                              if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                const SizedBox(height: 10),
                              (order.shippingMethodTitle?.isNotEmpty ?? false) &&
                                  kPaymentConfig.enableShipping
                                  ? Row(
                                children: <Widget>[
                                  Text(S.of(context).shippingMethod,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                        fontWeight: FontWeight.w400,
                                      )),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.shippingMethodTitle!,
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                ],
                              )
                                  : const SizedBox(),
                              if (order.totalShipping != null) const SizedBox(height: 10),
                              if (order.totalShipping != null)

                                const SizedBox(height: 10),
                              ...List.generate(
                                order.feeLines.length,
                                    (index) {
                                  final item = order.feeLines[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: <Widget>[
                                        Text(item.name ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                            )),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            PriceTools.getCurrencyFormatted(
                                                item.total, currencyRate,
                                                currency: currencyCode)!,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),


                              // row here can add

                            ],
                          ),
                        );

                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // here
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [Container(
                                width: 250,
                                height: 50,
                                padding: EdgeInsets.all(10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    // Set border width
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(10.0)), // Set rounded corner radius

                                ),
                              child:Text(
                                '! الخاصة بك eSIM ها هى',  style: TextStyle(
                                fontSize: 15,
                                color: Colors.orange[900],
                                fontFamily: 'Genos',
                                fontWeight: FontWeight.w900,
                              ),
                               )
                            ),
                              ...List.generate(
                                listOrderNote!.length,
                                (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          margin: EdgeInsets.all(10),
                                          padding: EdgeInsets.all(10),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              // Set border width
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10.0)), // Set rounded corner radius
                                              boxShadow: [BoxShadow(blurRadius: 5,color: Colors.black54,offset: Offset(1,3))] // Make rounded corner of border
                                          ),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Padding(

                                              padding: const EdgeInsets.only(
                                                  left: 100,
                                                  right: 100,
                                                  top: 15,
                                                  bottom: 25),
                                              child: kAdvanceConfig
                                                      .orderNotesLinkSupport
                                                  ? Linkify(
                                                      text: listOrderNote[index]
                                                          .note!,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          height: 1.2),
                                                      onOpen: (link) async {
                                                        await Tools.launchURL(
                                                            link.url);
                                                      },
                                                    )
                                                  : HtmlWidget(
                                                      listOrderNote[index]
                                                          .note!,
                                                      textStyle:
                                                          const TextStyle(
                                                              color:
                                                                  Colors.black54,
                                                              fontSize: 13,
                                                              height: 1.2),
                                                    ),
                                            ),
                                          ),

                                      //  here
                                      ],
                                    ),
                                  );
                                },
                              ),

                            ],
                          ),
                          Container(

                            decoration: BoxDecoration(

                              color: const Color(0xFF004E6B),
                              borderRadius: BorderRadius.circular(20.0),

                            ),
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Row(

                              children: <Widget>[

                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10.0),

                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                

                            const Flexible(child:
                            Text(
                              'Warning! Most eSIMs can only be installed once, If you remove an eSIM from your device, you cannot install it again.',



                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFFFFFF),
                                fontFamily: 'Genos',
                                fontWeight: FontWeight.w400,
                              ),
                            )
                            )
,




                                   
                             
                                Image.asset('assets/images/megaphone.png',height:40,width:40, fit: BoxFit.fill),
                                // row here can add

                              ],
                            ),



                          ), Container(


                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Column(

                              children: <Widget>[
                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 0),
                                    child: Row(

                                      children: <Widget>[

                                        Text(S.of(context).expectedDeliveryDate,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                            )),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.deliveryDate!,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  Row(
                                    children: [

                                         Image.asset('assets/images/rec.png',height:30,width:30, fit: BoxFit.fill),
                                         const Flexible(
                                           child: Text(
                                             ' Step 1                                                     ',



                                             style: TextStyle(
                                               fontSize: 10,
                                               color:Color(0xFFFFFFFF),
                                               fontFamily: 'Genos',
                                               fontWeight: FontWeight.w400,
                                             ),
                                           ),

                                     ),
                                      const SizedBox(width: 40),
                                      Image.asset('assets/images/help.png',height:40,width:30, fit: BoxFit.fill),
                                    const Flexible(
                                       child: Text(
                                         ' Do you need help?\n watch our tutorial guide.',


                                      
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: Color(0xFFFFFFFF),
                                           fontFamily: 'Genos',
                                           fontWeight: FontWeight.w400,
                                         ),
                                       ),
                                     ),

                                    ],
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)

                                  (order.shippingMethodTitle?.isNotEmpty ?? false) &&
                                      kPaymentConfig.enableShipping
                                      ? Row(
                                    children: <Widget>[
                                      Text(S.of(context).shippingMethod,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                            fontWeight: FontWeight.w400,
                                          )),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          order.shippingMethodTitle!,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                      : const SizedBox(),
                                if (order.totalShipping != null) const SizedBox(height: 10),
                                if (order.totalShipping != null)

                                  const SizedBox(height: 10),
                                ...List.generate(
                                  order.feeLines.length,
                                      (index) {
                                    final item = order.feeLines[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: <Widget>[
                                          Text(item.name ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w400,
                                              )),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              PriceTools.getCurrencyFormatted(
                                                  item.total, currencyRate,
                                                  currency: currencyCode)!,
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),


                                // row here can add

                              ],
                            ),

                          ),
                          Container(

                            decoration: BoxDecoration(

                              color: const Color(0xFF4A4A4C) ,
                              borderRadius: BorderRadius.circular(20.0),

                            ),
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Column(

                              children: <Widget>[
                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),

                                    child: Row(

                                      children: <Widget>[

                                        Text(S.of(context).expectedDeliveryDate,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                            )),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.deliveryDate!,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                 const  Row(
                                    children: [

                                      Flexible(
                                        child: Text(
                                          '1. Take a screenshot of this screen.',


                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:Color(0xFFFFFFFF),
                                            fontFamily: 'Genos',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),  const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '2. Go to Setting > Cellular > Add eSIM',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ), const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '3. Tap on `Use QR Code` `then`Open Photos` and\n select the screenshot.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ), const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '4. Label the eSIM as `eSimly-Palestine',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '5. Choose your primary line to call or send messages.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '6. Choose your primary line to use with iMessage,\n Face Time.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '7. Choose the eSIM plan as your default line for\n Cellular Data and do not turn on `Allow Cellular Data\n Switching` to prevent charges on your other line.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  const SizedBox(height: 10),
                                (order.shippingMethodTitle?.isNotEmpty ?? false) &&
                                    kPaymentConfig.enableShipping
                                    ? Row(
                                  children: <Widget>[
                                    Text(S.of(context).shippingMethod,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w400,
                                        )),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.shippingMethodTitle!,
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                                    : const SizedBox(),
                                if (order.totalShipping != null) const SizedBox(height: 10),
                                if (order.totalShipping != null)

                                  const SizedBox(height: 10),
                                ...List.generate(
                                  order.feeLines.length,
                                      (index) {
                                    final item = order.feeLines[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: <Widget>[
                                          Text(item.name ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w400,
                                              )),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              PriceTools.getCurrencyFormatted(
                                                  item.total, currencyRate,
                                                  currency: currencyCode)!,
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),


                                // row here can add

                              ],
                            ),
                          ),  Container(


                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Column(

                              children: <Widget>[
                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom:0),
                                    child: Row(

                                      children: <Widget>[

                                        Text(S.of(context).expectedDeliveryDate,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                            )),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.deliveryDate!,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  Row(
                                    children: [
                                      Image.asset('assets/images/rec.png',height:30,width:30, fit: BoxFit.fill),
                                      const Flexible(
                                        child: Text(
                                          ' Step 2                                                     ',


                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFFFFFFF),
                                            fontFamily: 'Genos',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)

                                  (order.shippingMethodTitle?.isNotEmpty ?? false) &&
                                      kPaymentConfig.enableShipping
                                      ? Row(
                                    children: <Widget>[
                                      Text(S.of(context).shippingMethod,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                            fontWeight: FontWeight.w400,
                                          )),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          order.shippingMethodTitle!,
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                      : const SizedBox(),
                                if (order.totalShipping != null) const SizedBox(height: 10),
                                if (order.totalShipping != null)

                                  const SizedBox(height: 10),
                                ...List.generate(
                                  order.feeLines.length,
                                      (index) {
                                    final item = order.feeLines[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: Row(
                                        children: <Widget>[
                                          Text(item.name ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w400,
                                              )),

                                        ],
                                      ),
                                    );
                                  },
                                ),


                                // row here can add

                              ],
                            ),

                          ), Container(

                            decoration: BoxDecoration(

                              color: const Color(0xFFD33B74) ,
                              borderRadius: BorderRadius.circular(20.0),

                            ),
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Column(

                              children: <Widget>[
                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)

                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: Row(

                                      children: <Widget>[

                                        Text(S.of(context).expectedDeliveryDate,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w400,
                                            )),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order.deliveryDate!,
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium!
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  Row(
                                    children: [
                                      Image.asset('assets/images/signal.png',height:30,width:30, fit: BoxFit.fill),
                                      const Flexible(

                                        child: Text(
                                          ' Network:  Automatic',


                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFFFFFFF),
                                            fontFamily: 'Genos',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ), const Row(
                                  children: [

                                    Flexible(

                                      child: Text(
                                        ' ',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),    Row(
                                  children: [
                                    Image.asset('assets/images/apn.png',height:30,width:30, fit: BoxFit.fill),
                                    const Flexible(

                                      child: Text(
                                        ' APN:  APN is set automatically',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ), const Row(
                                  children: [

                                    Flexible(

                                      child: Text(
                                        ' ',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ), Row(
                                  children: [
                                    Image.asset('assets/images/setting.png',height:30,width:30, fit: BoxFit.fill),
                                    const Flexible(

                                      child: Text(
                                        ' data roaming:  ON',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ), const Row(
                                  children: [

                                    Flexible(

                                      child: Text(
                                        ' ',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),  const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '1. Select you eSimly eSIM under `Cellular Plans`.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '2. Ensure that `Turn On This Line` is toggled on.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '3. Go to `Network Selection` and select the supported network..',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '4. Turn on the Data Rooming.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '5. Need help? Chat with us.',


                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:Color(0xFFFFFFFF),
                                          fontFamily: 'Genos',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  const SizedBox(height: 10),
                                (order.shippingMethodTitle?.isNotEmpty ?? false) &&
                                    kPaymentConfig.enableShipping
                                    ? Row(
                                  children: <Widget>[
                                    Text(S.of(context).shippingMethod,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w400,
                                        )),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.shippingMethodTitle!,
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  ],
                                )
                                    : const SizedBox(),
                                if (order.totalShipping != null) const SizedBox(height: 10),
                                if (order.totalShipping != null)

                                  const SizedBox(height: 10),
                                ...List.generate(
                                  order.feeLines.length,
                                      (index) {
                                    final item = order.feeLines[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: <Widget>[
                                          Text(item.name ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w400,
                                              )),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              PriceTools.getCurrencyFormatted(
                                                  item.total, currencyRate,
                                                  currency: currencyCode)!,
                                              textAlign: TextAlign.right,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),


                                // row here can add

                              ],
                            ),
                          ),      const SizedBox(height: 10),Container(

                            decoration: BoxDecoration(

                              color: Colors.grey[50] ,
                              borderRadius: BorderRadius.circular(20.0),

                            ),
                            padding: const EdgeInsets.all(15),
                            margin: const EdgeInsets.symmetric(vertical: 0),

                            child: Column(

                              children: <Widget>[
                                if (order.deliveryDate != null &&
                                    order.storeDeliveryDates == null)

                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10.0),
                                    child: Row(

                                      children: <Widget>[



                                      ],
                                    ),
                                  ),
                                if (order.paymentMethodTitle?.isNotEmpty ?? false)
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4A4A4C),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12), //

                                          ),
                                        ),
                                        child: const Text('OK'),
                                        onPressed: () {
                                          launcdURLInBrowser();
                                        },
                                      ),
                                      const SizedBox(width: 5),
                                       const Flexible(
                                           child:
                                          Text(
                                            'هل تحتاج الى مساعدة؟ قم باستعراض  دليلنا المفصل خطوة بخطوة'

,

                                            softWrap: true,

                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                              fontFamily: 'Genos',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),


                                      ),
                                      Image.asset('assets/images/help.png',height:40,width:30, fit: BoxFit.fill),


                                    ],
                                  ),




                                // row here can add

                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 50)
            ],
          ),
        ),
      );
    });
  }

  String getCountryName(country) {
    try {
      return CountryPickerUtils.getCountryByIsoCode(country).name;
    } catch (err) {
      return country;
    }
  }

  Future<void> refundOrder() async {
    var loadingContext = context;
    _showLoading((BuildContext context) {
      loadingContext = context;
    });
    try {
      await orderHistoryModel.createRefund();
      _hideLoading(loadingContext);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).refundOrderSuccess)));
    } catch (err) {
      _hideLoading(loadingContext);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).refundOrderFailed)));
    }
  }

  void _showLoading(Function(BuildContext) onGetContext) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        onGetContext(context);
        return Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                kLoadingWidget(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  String formatTime(DateTime time) {
    return DateFormat('dd/MM/yyyy, HH:mm').format(time);
  }
}
