import 'package:flutter/material.dart';
import '../utils/sf_font.dart';

/// Demo screen to showcase San Francisco font styles
class FontDemoScreen extends StatelessWidget {
  const FontDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'San Francisco Fonts',
          style: SFFont.titleLarge(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display styles
            _buildSection(
              'Display Styles (SF Pro Display)',
              [
                _buildFontExample('Display Large', SFFont.displayLarge()),
                _buildFontExample('Display Medium', SFFont.displayMedium()),
                _buildFontExample('Display Small', SFFont.displaySmall()),
              ],
            ),

            // Headlines
            _buildSection(
              'Headlines (SF Pro Display)',
              [
                _buildFontExample('Headline Large', SFFont.headlineLarge()),
                _buildFontExample('Headline Medium', SFFont.headlineMedium()),
                _buildFontExample('Headline Small', SFFont.headlineSmall()),
              ],
            ),

            // Titles
            _buildSection(
              'Titles (SF Pro Display)',
              [
                _buildFontExample('Title Large', SFFont.titleLarge()),
                _buildFontExample('Title Medium', SFFont.titleMedium()),
                _buildFontExample('Title Small', SFFont.titleSmall()),
              ],
            ),

            // Body text
            _buildSection(
              'Body Text (SF Pro Text)',
              [
                _buildFontExample('Body Large', SFFont.bodyLarge()),
                _buildFontExample('Body Medium', SFFont.bodyMedium()),
                _buildFontExample('Body Small', SFFont.bodySmall()),
              ],
            ),

            // Labels
            _buildSection(
              'Labels (SF Pro Text)',
              [
                _buildFontExample('Label Large', SFFont.labelLarge()),
                _buildFontExample('Label Medium', SFFont.labelMedium()),
                _buildFontExample('Label Small', SFFont.labelSmall()),
              ],
            ),

            // Font weights
            _buildSection(
              'Font Weights',
              [
                _buildFontExample(
                    'Ultralight', SFFont.ultralight(fontSize: 18)),
                _buildFontExample('Thin', SFFont.thin(fontSize: 18)),
                _buildFontExample('Light', SFFont.light(fontSize: 18)),
                _buildFontExample('Regular', SFFont.regular(fontSize: 18)),
                _buildFontExample('Medium', SFFont.medium(fontSize: 18)),
                _buildFontExample('Semibold', SFFont.semibold(fontSize: 18)),
                _buildFontExample('Bold', SFFont.bold(fontSize: 18)),
                _buildFontExample('Heavy', SFFont.heavy(fontSize: 18)),
                _buildFontExample('Black', SFFont.black(fontSize: 18)),
              ],
            ),

            // Theme styles
            _buildSection(
              'Theme Text Styles',
              [
                _buildFontExample(
                    'Theme Display Large', theme.textTheme.displayLarge),
                _buildFontExample(
                    'Theme Headline Large', theme.textTheme.headlineLarge),
                _buildFontExample(
                    'Theme Title Large', theme.textTheme.titleLarge),
                _buildFontExample(
                    'Theme Body Large', theme.textTheme.bodyLarge),
                _buildFontExample(
                    'Theme Label Large', theme.textTheme.labelLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SFFont.headlineSmall(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFontExample(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: SFFont.bodySmall(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: style,
          ),
        ],
      ),
    );
  }
}
