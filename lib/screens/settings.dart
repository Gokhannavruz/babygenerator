import 'dart:io';

import 'package:babyprediction/screens/baby_prediction.dart';
import 'package:babyprediction/src/views/firstlaunch_paywall.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:babyprediction/screens/privacy_url.dart';
import 'package:babyprediction/screens/terms_of_use.dart';
import 'package:babyprediction/src/components/native_dialog.dart';
import 'package:babyprediction/src/model/singletons_data.dart';
import 'package:babyprediction/src/model/weather_data.dart';
import 'package:babyprediction/src/rvncat_constant.dart';
import 'package:babyprediction/src/views/paywall.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:babyprediction/models/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    // final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '1.0.0'; // Replace with actual version
    });
  }

  void _initializeUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (appData.appUserID == null || appData.appUserID.isEmpty) {
        String newUserID = Uuid().v4();
        await Purchases.logIn(newUserID);
        appData.appUserID = await Purchases.appUserID;
      }
    } on PlatformException catch (e) {
      await showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
              title: "Error",
              content: e.message ?? "Unknown error",
              buttonText: 'OK'));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _restore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      appData.entitlementIsActive =
          customerInfo.entitlements.all[entitlementID]?.isActive ?? false;

      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appData.entitlementIsActive
                ? 'Premium features restored successfully!'
                : 'No previous purchases found.'),
            backgroundColor:
                appData.entitlementIsActive ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore purchases. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        title: Text('Settings',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: appData.entitlementIsActive
                          ? [Colors.green.shade400, Colors.green.shade700]
                          : AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(20.0),
                    title: Text(
                      appData.entitlementIsActive
                          ? 'Premium Active'
                          : 'Subscription Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        appData.entitlementIsActive
                            ? 'You have access to all premium features'
                            : 'Get premium to access all features',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    trailing: appData.entitlementIsActive
                        ? Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 32,
                          )
                        : ElevatedButton(
                            onPressed: () => perfomMagic(),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color(0xFF13A11A),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Get Premium',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SettingsSection(
              title: 'ACCOUNT',
              tiles: [
                SettingsTile(
                  title: 'Restore Purchase',
                  onTap: () => _restore(),
                ),
              ],
            ),
            SettingsSection(
              title: 'LEGAL',
              tiles: [
                SettingsTile(
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsOfServicePage(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: 'Terms of Use',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EulaPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void perfomMagic() async {
    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        // current offering is available, show paywall
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsTile> tiles;

  SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: tiles
                .map((tile) => Column(
                      children: [
                        tile,
                        if (tiles.indexOf(tile) != tiles.length - 1)
                          Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  SettingsTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.black45,
        size: 24,
      ),
      onTap: onTap,
    );
  }
}
