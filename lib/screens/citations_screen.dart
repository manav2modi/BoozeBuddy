// lib/screens/citations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/citation.dart';
import '../utils/theme.dart';

class CitationsScreen extends StatelessWidget {
  const CitationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.cardColor,
        middle: Text('Health Information Sources'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoSection(
                'About Medical Information',
                'The drinking guidelines and health recommendations provided in this app are based on scientific research and public health guidelines from reputable sources. The information is provided for educational purposes only and is not intended as medical advice.'
            ),
            const SizedBox(height: 24),

            _buildCitationSection('Drinking Guidelines', HealthCitations.all),

            const SizedBox(height: 24),

            _buildInfoSection(
                'Medical Disclaimer',
                'This app is designed for informational and educational purposes only. It is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition or health goals.'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String text) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFBBBBBB),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationSection(String title, List<Citation> sources) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          ...sources.map((source) => _buildCitationItem(source)),
        ],
      ),
    );
  }

  Widget _buildCitationItem(Citation source) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFBBBBBB),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _launchURL(source.url),
            child: Text(
              source.url,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}