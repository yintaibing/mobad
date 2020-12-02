import 'package:flutter/material.dart';
import 'package:mobad/ad.dart';

class InterstitialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
                onPressed: () {
                  AdSdk.showInterstitialAd(
                    "i1",
                    onAdLoad: (String id) {
                      print("InterstitialAd onAdLoad");
                    },
                    onAdShow: (String id) {
                      print("InterstitialAd onAdShow");
                    },
                    onAdClick: (String id) {
                      print("InterstitialAd onAdClick");
                    },
                    onAdClose: (String id) {
                      print("InterstitialAd onAdClose");
                    },
                    onError: (String id, int code, String message) {
                      print("InterstitialAd onError");
                    },
                  );
                },
                child: Text("加载插屏广告")),
          ],
        ),
      ),
    );
  }
}
