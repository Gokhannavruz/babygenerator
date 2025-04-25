import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EulaPage extends StatelessWidget {
  final String privacyPolicyUrl =
      "https://toolstoore.blogspot.com/2024/12/what-look-like-my-baby-terms-of-service.html";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'EULA',
          style: TextStyle(color: Colors.black, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What My Baby Look Like End User License Agreement (EULA)',
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
            SizedBox(height: 20),
            _buildSectionTitle('1. License Grant'),
            _buildText(
                'We grant you a limited, non-exclusive, non-transferable, revocable license to use What My Baby Look Like in accordance with these terms.'),
            SizedBox(height: 20),
            _buildSectionTitle('2. Data Privacy'),
            _buildText(
                'Your privacy is important to us. We do not store or collect any photos or personal information you upload. All processing is done in real-time and no data is retained on our servers.'),
            SizedBox(height: 20),
            _buildSectionTitle('2. Restrictions'),
            _buildText('You may not:\n\n'
                '- Decompile, reverse engineer, disassemble, attempt to derive the source code of, or decrypt Bug Identifier.\n\n'
                '- Make any modification, adaptation, improvement, enhancement, translation, or derivative work from Bug Identifier.\n\n'
                '- Use Bug Identifier for any unlawful or illegal activity, or to facilitate any illegal activity.'),
            SizedBox(height: 20),
            _buildSectionTitle('3. User Content'),
            _buildText(
                'You are responsible for the content you post on or through Bug Identifier. By posting content, you grant us a worldwide, non-exclusive, royalty-free, transferable license to use, reproduce, distribute, prepare derivative works of, display, and perform that content in connection with the service.'),
            SizedBox(height: 20),
            _buildSectionTitle('4. No Tolerance for Objectionable Content'),
            _buildText(
                'There is zero tolerance for objectionable content or abusive users. Users found to be engaging in such activities will have their accounts terminated.'),
            SizedBox(height: 20),
            _buildSectionTitle('5. Termination'),
            _buildText(
                'We may terminate your access to Bug Identifier if you fail to comply with any of the terms and conditions of this EULA. Upon termination, you must cease all use of Bug Identifier and delete all copies of Bug Identifier from your devices.'),
            SizedBox(height: 20),
            _buildSectionTitle('6. Changes to EULA'),
            _buildText(
                'We may update this EULA from time to time. The most current version will always be available on our website. Your continued use of Bug Identifier after any updates indicates your acceptance of the new terms.'),
            SizedBox(height: 20),
            _buildSectionTitle('7. Contact Us'),
            _buildText(
                'If you have any questions about this EULA, please contact us at gkhnnavruz@gmail.com.'),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    if (await canLaunch(privacyPolicyUrl)) {
                      await launch(privacyPolicyUrl);
                    } else {
                      throw 'Could not launch $privacyPolicyUrl';
                    }
                  },
                  child: Text('Open Term of Service in Browser',
                      style: TextStyle(fontSize: 13.0, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16.0),
    );
  }
}
