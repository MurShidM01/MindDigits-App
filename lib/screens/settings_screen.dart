import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _availableFonts = [
    'Poppins',
    'Roboto',
    'Montserrat',
    'Open Sans',
    'Lato',
    'Raleway',
    'Ubuntu',
    'Nunito',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    context,
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    children: [
                      ListTile(
                        title: Text(
                          'Theme Mode',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          settings.themeMode.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                          ),
                        ),
                        leading: Icon(
                          settings.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : settings.themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_auto,
                          color: colorScheme.primary,
                        ),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          onChanged: (ThemeMode? mode) {
                            if (mode != null) settings.setThemeMode(mode);
                          },
                          items: ThemeMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(
                                mode.name.toUpperCase(),
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }).toList(),
                          underline: Container(),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'App Font',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          settings.selectedFont,
                          style: GoogleFonts.getFont(
                            settings.selectedFont,
                            color: colorScheme.primary,
                          ),
                        ),
                        leading: Icon(
                          Icons.font_download,
                          color: colorScheme.primary,
                        ),
                        trailing: DropdownButton<String>(
                          value: settings.selectedFont,
                          onChanged: (String? font) {
                            if (font != null) settings.setFont(font);
                          },
                          items: _availableFonts.map((font) {
                            return DropdownMenuItem(
                              value: font,
                              child: Text(
                                font,
                                style: GoogleFonts.getFont(font),
                              ),
                            );
                          }).toList(),
                          underline: Container(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Game Settings',
                    icon: Icons.games_outlined,
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Sound Effects',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'Play sounds during gameplay',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        value: settings.soundEnabled,
                        onChanged: (_) => settings.toggleSound(),
                        secondary: Icon(
                          settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: colorScheme.primary,
                        ),
                      ),
                      SwitchListTile(
                        title: Text(
                          'Vibration',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'Vibrate on actions',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        value: settings.vibrationEnabled,
                        onChanged: (_) => settings.toggleVibration(),
                        secondary: Icon(
                          settings.vibrationEnabled ? Icons.vibration : Icons.do_not_disturb_on,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'About',
                    icon: Icons.info_outline,
                    children: [
                      ListTile(
                        title: Text(
                          'Version',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          '1.0.0',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        leading: Icon(
                          Icons.new_releases,
                          color: colorScheme.primary,
                        ),
                        trailing: TextButton.icon(
                          onPressed: () => settings.checkForUpdates(context),
                          icon: const Icon(Icons.system_update),
                          label: Text(
                            'Check Updates',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'Source Code',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'View on GitHub',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        leading: Icon(
                          Icons.code,
                          color: colorScheme.primary,
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () async {
                          final url = Uri.parse('https://github.com/MurShidM01/MindDigits-App');
                          try {
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Could not open repository',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Error: ${e.toString()}',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Developer',
                    icon: Icons.developer_mode,
                    children: [
                      ListTile(
                        title: Text(
                          'Developer',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'Ali Khan Jalbani',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        leading: Icon(
                          Icons.person,
                          color: colorScheme.primary,
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'Contact',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'alikhanjalbani@outlook.com',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        leading: Icon(
                          Icons.email,
                          color: colorScheme.primary,
                        ),
                        onTap: () async {
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'alikhanjalbani@outlook.com',
                            queryParameters: {
                              'subject': 'MindDigits App Feedback'
                            }
                          );
                          try {
                            await launchUrl(emailLaunchUri);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open email app',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        return Card(
          elevation: 4,
          shadowColor: colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: colorScheme.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                ...children.map((child) {
                  if (child is ListTile) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        listTileTheme: ListTileThemeData(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 16,
                            vertical: isSmallScreen ? 4 : 8,
                          ),
                        ),
                      ),
                      child: child,
                    );
                  }
                  return child;
                }).toList(),
              ],
            ),
          ),
        );
      }
    );
  }
} 