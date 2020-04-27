import 'package:avataaar_image/avataaar_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:tw_wallet_ui/global/common/application.dart';
import 'package:tw_wallet_ui/global/common/theme.dart';
import 'package:tw_wallet_ui/global/widgets/page_title.dart';
import 'package:tw_wallet_ui/views/home/identity/identity_new_store.dart';

class IdentityNewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _IdentityNewPageState();
}

class _IdentityNewPageState extends State<IdentityNewPage> {
  bool _isInAsyncCall = false;

  final IdentityNewStore store = IdentityNewStore();

  @override
  void initState() {
    super.initState();
    store.setupAvatarAndValidators();
    store.validateAll();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  Future<void> _addOnPressed() async {
    setState(() => _isInAsyncCall = true);
    Future.microtask(() {
      store.validateAll();
    }).then((_) {
      if (!store.error.hasErrors) {
        store.addIdentity().then((success) {
          Future.delayed(Duration(seconds: 2)).then((_) {
            if (success) {
              Application.router.pop(context);
            } else {
              setState(() => _isInAsyncCall = false);
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WalletTheme.mainBgColor,
      body: SafeArea(
          child: ModalProgressHUD(
              color: WalletTheme.mainBgColor,
              inAsyncCall: _isInAsyncCall,
              progressIndicator: CircularProgressIndicator(
                  backgroundColor: WalletTheme.mainBgColor),
              child: Container(
                  color: WalletTheme.mainBgColor,
                  child: Column(children: <Widget>[
                    Container(
                        padding: EdgeInsets.all(25),
                        child: PageTitleWidget(title: '新建个人信息')),
                    Expanded(
                        child: Form(
                      child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Column(
                            children: <Widget>[
                              Observer(
                                  builder: (_) => Stack(
                                          alignment: const Alignment(0.0, 2.0),
                                          children: <Widget>[
                                            AvataaarImage(
                                              avatar: store.avatar,
                                              errorImage: Icon(Icons.error),
                                              placeholder:
                                                  CircularProgressIndicator(),
                                              width: 65,
                                            ),
                                            IconButton(
                                                icon: Icon(Icons.refresh),
                                                onPressed: store.refreshAvatar)
                                          ])),
                              Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Text('以下带 * 的为必填项',
                                      style: TextStyle(color: Colors.grey))),
                              Observer(
                                  builder: (_) => TextField(
                                      keyboardType: TextInputType.text,
                                      onChanged: (value) => store.name = value,
                                      decoration: InputDecoration(
                                        labelText: '名称*',
                                        hintText: '输入名称',
                                        errorText: store.error.username,
                                      ))),
                              Observer(
                                  builder: (_) => TextField(
                                      onChanged: (value) => store.email = value,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: '邮箱',
                                        hintText: '输入邮箱',
                                        errorText: store.error.email,
                                      ))),
                              Observer(
                                  builder: (_) => TextField(
                                      onChanged: (value) => store.phone = value,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: '手机',
                                        hintText: '输入手机号',
                                        errorText: store.error.phone,
                                      ))),
                              Observer(
                                  builder: (_) => TextField(
                                      onChanged: (value) =>
                                          store.birthday = value,
                                      keyboardType: TextInputType.datetime,
                                      decoration: InputDecoration(
                                        labelText: '生日',
                                        hintText: 'YYYY-MM-DD',
                                        errorText: store.error.birthday,
                                      ))),
                              Expanded(child: Container()),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 55),
                                  child: Observer(
                                      builder: (_) => WalletTheme.button(
                                          text: '添加',
                                          onPressed: store.error.hasErrors
                                              ? null
                                              : _addOnPressed)))
                            ],
                          )),
                    ))
                  ])))),
      resizeToAvoidBottomPadding: false,
    );
  }
}