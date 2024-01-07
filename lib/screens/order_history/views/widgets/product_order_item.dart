import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/config.dart';
import '../../../../common/constants.dart';
import '../../../../common/tools.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/entities/store_delivery_date.dart';
import '../../../../models/index.dart';
import '../../../../services/index.dart';
import '../../../../widgets/html/index.dart';
import '../../../detail/widgets/review.dart';
import '../../../index.dart';

class ProductOrderItem extends StatefulWidget {
  final String orderId;
  final OrderStatus orderStatus;
  final ProductItem product;
  final List<StoreDeliveryDate>? storeDeliveryDates;
  final String? currencyCode;
  final bool disableReview;

  /// For prestashop.
  final int index;

  const ProductOrderItem(
      {required this.orderId,
      required this.orderStatus,
      required this.product,
      this.storeDeliveryDates,
      this.currencyCode,
      this.index = 0,
      this.disableReview = false});

  @override
  BaseScreen<ProductOrderItem> createState() => _StateProductOrderItem();
}

class _StateProductOrderItem extends BaseScreen<ProductOrderItem> {
  Product? product;
  late String imageFeatured = kDefaultImage;
  bool isLoading = true;

  @override
  void afterFirstLayout(BuildContext context) async {
    super.afterFirstLayout(context);

    if (widget.product.featuredImage == null) {
      // Try to load product because listing app will load listing product
      // instead of WooComerce product. And order history item cannot be listing
      var productObj = await Services().api.overrideGetProduct(
            widget.product.productId,
          );
      if (productObj != null) {
        setState(() {
          product = productObj;
          imageFeatured = product!.imageFeature ?? kDefaultImage;
        });
      }
    } else {
      setState(() {
        imageFeatured = widget.product.featuredImage ?? kDefaultImage;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void navigateToProductDetail() async {
    if (product == null) {
      // Try to load product because listing app will load listing product
      // instead of WooComerce product. And order history item cannot be listing
      final productVal =
          await Services().api.overrideGetProduct(widget.product.productId);
      setState(() {
        product = productVal;
      });
    }
    await Navigator.of(context).pushNamed(
      RouteList.productDetail,
      arguments: product,
    );
  }

  Widget _buildItemDesc(String title, String content) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 3.0,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 8,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          Text(
            content,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode =
        widget.currencyCode ?? Provider.of<AppModel>(context).currencyCode;
    var addonsOptions = {};
    if (widget.product.addonsOptions.isNotEmpty) {
      for (var element in widget.product.addonsOptions.keys) {
        addonsOptions[element] =
            Tools.getFileNameFromUrl(widget.product.addonsOptions[element]!);
      }
    }
    var deliveryDate;
    if (widget.storeDeliveryDates != null &&
        widget.storeDeliveryDates!.isNotEmpty) {
      var storeIndex = widget.storeDeliveryDates!
          .indexWhere((element) => element.storeId == widget.product.storeId);

      if (storeIndex != -1) {
        deliveryDate = widget.storeDeliveryDates![storeIndex].displayDDate;
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: navigateToProductDetail,

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(


              ),
              const SizedBox(width: 10),
            //  here
            ],
          ),
        ),

        /// Review for completed order only. Removed


        const SizedBox(height: 10),
      ],
    );
  }
}

class DownloadButton extends StatefulWidget {
  final String? id;

  const DownloadButton(this.id);

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool isLoading = false;

  void _handleDownloadAction(String file) async {
    try {
      Navigator.pop(context);
      setState(() => isLoading = true);

      await Tools.launchURL(
        file,
        mode: LaunchMode.externalApplication,
      );

      await Future.delayed(const Duration(milliseconds: 200));

      setState(() => isLoading = false);
    } catch (err) {
      Tools.showSnackBar(ScaffoldMessenger.of(context), '$err');
    }
  }

  void _showDownloadableFiles(BuildContext context) async {
    try {
      setState(() => isLoading = true);

      var product = await Services().api.overrideGetProduct(widget.id);

      setState(() => isLoading = false);

      if (product?.files?.isEmpty ?? true) {
        throw (S.of(context).noFileToDownload);
      }

      var files = product!.files!;

      if (files.length == 1) {
        final file = files[0];
        if (file != null) {
          _handleDownloadAction(file);
        }
      } else {
        await showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final fileNames =
                          product.fileNames?[index] ?? S.of(context).files;

                      return ListTile(
                        title: Text(fileNames),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            if (file != null) {
                              _handleDownloadAction(file);
                            }
                          },
                          child: Text(
                            S.of(context).download,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(color: kGrey200),
                ),
                ListTile(
                  title: Text(
                    S.of(context).selectTheFile,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (err) {
      Tools.showSnackBar(ScaffoldMessenger.of(context), '$err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(

      onPressed: isLoading ? null : () => "f",
      icon: isLoading
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      )
          : Icon(
        Icons.picture_as_pdf,
        color: Theme.of(context).primaryColor,
      ),
      label: Text(
        "g",
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class ProductOptions extends StatelessWidget {
  final List<Map<String, dynamic>?> prodOptions;

  const ProductOptions({required this.prodOptions});

  @override
  Widget build(BuildContext context) {
    var list = <Widget>[];
    for (var option in prodOptions) {
      list.add(Row(
        children: [
          HtmlWidget(option!['name'] + ':'),
          const SizedBox(width: 10.0),
          Text(option['value']),
        ],
      ));
      list.add(const SizedBox(
        height: 5.0,
      ));
    }
    return Column(children: list);
  }
}
