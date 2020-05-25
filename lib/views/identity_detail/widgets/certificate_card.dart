import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tw_wallet_ui/common/theme/color.dart';
import 'package:tw_wallet_ui/common/theme/font.dart';

class CertificateCardWidget extends StatelessWidget {
  final String title;
  final Function onTap;
  final String routeTitle;

  CertificateCardWidget({this.title, this.onTap, this.routeTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: WalletColor.white
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      margin: EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: WalletFont.font_18()
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              child: Row(
                children: <Widget>[
                  Text(
                    routeTitle != null ? routeTitle : '去认证',
                    style: WalletFont.font_14(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: WalletColor.primary
                      )
                    )
                  ),
                  SvgPicture.asset('assets/icons/right-arrow.svg')
                ],
              )
            ),
          )
        ],
      )
    );
  }
}