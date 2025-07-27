import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/accessibility_settings.dart';
import '../../providers/accessibility_provider.dart';
import '../../theme/theme.dart';

class AccessibilitySettingsWidget extends ConsumerWidget {
  final bool showTitle;
  
  const AccessibilitySettingsWidget({
    Key? key,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilitySettings = ref.watch(accessibilityProvider);
    final notifier = ref.read(accessibilityProvider.notifier);
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const Text(
            'Preferencias de Accesibilidad',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
        
        // Tamaño de fuente
        _buildSectionTitle('Tamaño de fuente'),
        const SizedBox(height: 8),
        Row(
          children: FontSizeOption.values.map((size) {
            final isSelected = accessibilitySettings.fontSize == size;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => notifier.setFontSize(size),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surface,
                    foregroundColor: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                    elevation: isSelected ? 2 : 0,
                  ),
                  child: Text(
                    size == FontSizeOption.small ? 'Pequeño' :
                    size == FontSizeOption.medium ? 'Mediano' : 'Grande',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        
        // Tema
        _buildSectionTitle('Tema'),
        const SizedBox(height: 8),
        Row(
          children: ThemeModeOption.values.map((mode) {
            final isSelected = accessibilitySettings.themeMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => notifier.setThemeMode(mode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surface,
                    foregroundColor: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                    elevation: isSelected ? 2 : 0,
                  ),
                  child: Text(
                    mode == ThemeModeOption.light ? 'Claro' :
                    mode == ThemeModeOption.dark ? 'Oscuro' : 'Sistema',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        
        // Paleta de colores
        _buildSectionTitle('Color de la aplicación'),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AccessibilitySettings.colorPalette.length,
            itemBuilder: (context, index) {
              final color = AccessibilitySettings.colorPalette[index];
              final isSelected = accessibilitySettings.selectedColorIndex == index;
              return GestureDetector(
                onTap: () => notifier.setSelectedColorIndex(index),
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Modo de accesibilidad
        _buildSectionTitle('Accesibilidad de color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorBlindnessType.values.map((type) {
            final isSelected = accessibilitySettings.colorBlindnessType == type;
            return ChoiceChip(
              label: Text(_getColorBlindnessLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.setColorBlindnessType(type);
                }
              },
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurface,
              ),
              backgroundColor: theme.colorScheme.surface,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Modo blanco y negro'),
          value: accessibilitySettings.isBlackAndWhite,
          onChanged: (value) => notifier.setBlackAndWhite(value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }
  
  String _getColorBlindnessLabel(ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.none:
        return 'Ninguno';
      case ColorBlindnessType.protanopia:
        return 'Protanopia';
      case ColorBlindnessType.deuteranopia:
        return 'Deuteranopia';
      case ColorBlindnessType.tritanopia:
        return 'Tritanopia';
      case ColorBlindnessType.achromatopsia:
        return 'Escala de grises';
    }
  }
}
