import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:babyprediction/src/model/singletons_data.dart';
import 'package:babyprediction/src/rvncat_constant.dart';
import 'package:babyprediction/src/views/subscriptionterms_page.dart';
import 'package:babyprediction/main.dart';

class Paywall2 extends StatefulWidget {
  final Offering offering;

  const Paywall2({Key? key, required this.offering}) : super(key: key);

  @override
  _Paywall2State createState() => _Paywall2State();
}

class _Paywall2State extends State<Paywall2> {
  int? _selectedPackageIndex = 1;
  late List<Package> _sortedPackages;

  @override
  void initState() {
    super.initState();
    _sortedPackages = List<Package>.from(widget.offering.availablePackages);
    _sortPackages();
  }

  void _sortPackages() {
    _sortedPackages.sort((a, b) {
      return _getPackagePriority(a.packageType) -
          _getPackagePriority(b.packageType);
    });
  }

  int _getPackagePriority(PackageType packageType) {
    switch (packageType) {
      case PackageType.weekly:
        return 0;
      case PackageType.monthly:
        return 1;
      case PackageType.annual:
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false,
          );
          return false;
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/ai.png',
                      height: screenHeight * 0.40,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => MainScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow('Unlimited Baby Appearance Prediction',
                          Icons.child_care),
                      _buildFeatureRow(
                          'Unlimited Age Appearance Prediction', Icons.face),
                      _buildFeatureRow(
                          'Unlimited Predictions', Icons.all_inclusive),
                      _buildFeatureRow(
                          'Priority Customer Support', Icons.support_agent),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _sortedPackages.map((pkg) {
                      int index = _sortedPackages.indexOf(pkg);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPackageIndex = index),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPackageIndex == index
                                  ? Color(0xFFE3F2FD)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _selectedPackageIndex == index
                                    ? Color(0xFF2196F3)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _getSubscriptionType(pkg),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  pkg.storeProduct.priceString,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_getSavingsText(pkg).isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(top: 4),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getSavingsText(pkg),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed:
                        _selectedPackageIndex != null ? _subscribeNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubscriptionTermsPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Subscription terms',
                        style: TextStyle(
                          color: Color(0xFF5E5E5E),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF1976D2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _subscribeNow() async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(
        _sortedPackages[_selectedPackageIndex!],
      );
      EntitlementInfo? entitlement =
          customerInfo.entitlements.all[entitlementID];
      appData.entitlementIsActive = entitlement?.isActive ?? false;

      // Başarılı abonelik sonrası MainScreen'e yönlendirme
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false,
      );
    } catch (e) {
      print(e);
    }
  }

  String _getSubscriptionType(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annually';
      default:
        return 'Unknown';
    }
  }

  String _getSavingsText(Package package) {
    if (package.packageType == PackageType.weekly) return '';

    double weeklyPrice = _sortedPackages
        .firstWhere((p) => p.packageType == PackageType.weekly)
        .storeProduct
        .price;
    double packagePrice = package.storeProduct.price;

    int weeks;
    switch (package.packageType) {
      case PackageType.monthly:
        weeks = 4;
        break;
      case PackageType.annual:
        weeks = 52;
        break;
      default:
        weeks = 0;
    }

    double totalWeeklyPrice = weeklyPrice * weeks;
    double savings = totalWeeklyPrice - packagePrice;
    double savingsPercentage = (savings / totalWeeklyPrice) * 100;

    return 'Save ${savingsPercentage.toStringAsFixed(0)}%';
  }
}
