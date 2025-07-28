import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/language_service.dart';
import '../../widgets/base_screen.dart';

class FAQScreen extends ConsumerWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEnglish = ref.watch(languageServiceProvider).isEnglish;

    final List<Map<String, String>> faqs = [
      {
        'question': isEnglish ? 'How do I add a new note?' : '¿Cómo agrego una nueva nota?',
        'answer': isEnglish 
            ? 'To add a new note, tap the + button at the bottom of the main screen.'
            : 'Para agregar una nueva nota, toca el botón + en la parte inferior de la pantalla principal.',
      },
      {
        'question': isEnglish ? 'How do I change the app language?' : '¿Cómo cambio el idioma de la aplicación?',
        'answer': isEnglish
            ? 'Go to Profile > App Settings and toggle the language option.'
            : 'Ve a Perfil > Configuración de la aplicación y cambia la opción de idioma.',
      },
      {
        'question': isEnglish ? 'Is my data backed up?' : '¿Mis datos están respaldados?',
        'answer': isEnglish
            ? 'Your data is stored locally on your device. We recommend regularly backing up your data.'
            : 'Tus datos se almacenan localmente en tu dispositivo. Te recomendamos hacer copias de seguridad regularmente.',
      },
    ];

    return BaseScreen(
      title: isEnglish ? 'FAQ' : 'Preguntas Frecuentes',
      showBackButton: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                faqs[index]['question']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(faqs[index]['answer']!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
