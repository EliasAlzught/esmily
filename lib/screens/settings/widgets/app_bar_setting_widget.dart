import 'package:flutter/material.dart';
import 'package:inspireui/icons/icon_picker.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../common/tools/navigate_tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/app_model.dart';
import '../../../widgets/common/flux_image.dart';
import '../../common/app_bar_mixin.dart';

const _kBannerHigh = 150.0;

class AppBarSettingWidget extends StatefulWidget {
  const AppBarSettingWidget({
    super.key,
    this.background,

    required this.showBackground,
  });

  final String? background;
  final bool showBackground;


  @override
  State<AppBarSettingWidget> createState() => _AppBarSettingWidgetState();
}

class _AppBarSettingWidgetState extends State<AppBarSettingWidget>
    with AppBarMixin {
  bool get _canPop => ModalRoute.of(context)?.canPop ?? false;



  Widget _renderPopButton({Color? color}) {
    var popButton = GestureDetector(


    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: popButton,
    );
  }

  List<Widget>? _renderActions() {
    return _canPop
        ? [
            _renderPopButton(
                color: widget.showBackground
                    ? Colors.white
                    : Theme.of(context).iconTheme.color!)
          ]
        : null;
  }

  @override
  Widget build(BuildContext context) {
    var background = widget.showBackground
        ? (widget.background ?? kProfileBackground)
        : null;

    if (showAppBar(RouteList.profile)) {
      return getSliverAppBarWidget(
        appBar: appBar,
        popButton: _renderPopButton(
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    final leadingWidget =
    (context.read<AppModel>().appConfig?.drawer?.enable ?? true) && !_canPop;

    if (background != null) {
      return SliverAppBar(
        backgroundColor: Theme.of(context).primaryColor,

        expandedHeight: _kBannerHigh,
        floating: true,
        pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          title:  const Text(
              '',
            style: TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          background: FluxImage(
            imageUrl: background,
            fit: BoxFit.cover,
          ),
        ),
        actions: _renderActions(),
      );
    }

    return SliverAppBar(
      title: Text(S.of(context).settings),
      centerTitle: true,
      floating: true,
      pinned: true,

      backgroundColor: Theme.of(context).colorScheme.background,
      actions: _renderActions(),
    );
  }
}
