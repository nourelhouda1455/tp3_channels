import 'package:flutter/services.dart';

class Canaux {
  // 1. Informations du téléphone
  static const MethodChannel _infos =
      MethodChannel('appareil/infos');

  static Future<Map<String, dynamic>?> lireInfos() async {
    try {
      final result =
          await _infos.invokeMapMethod<String, dynamic>('lire');

      return result;
    } on PlatformException catch (e) {
      print('Erreur lors de la lecture des informations : ${e.message}');
      return null;
    }
  }

  // 2. Vibration
  static const MethodChannel _vibreur =
      MethodChannel('appareil/vibrer');

  static Future<void> vibrer(String motif) {
    return _vibreur.invokeMethod(
      'vibrer',
      {'motif': motif},
    );
  }

  // 3. Capteur de lumière
  static const EventChannel _lumiere =
      EventChannel('capteur/lumiere');

  static Stream<double> lumiere() {
    return _lumiere.receiveBroadcastStream().map(
      (v) => (v as num).toDouble(),
    );
  }

  // 4. Permission microphone
  static const MethodChannel _permission =
      MethodChannel('audio/permission');

  static Future<bool> demanderMicro() async {
    return await _permission.invokeMethod<bool>('demander') ?? false;
  }

  // 5. Niveau sonore
  static const EventChannel _audio =
      EventChannel('audio/niveau');

  static Stream<double> niveauSonore() {
    return _audio.receiveBroadcastStream().map(
      (v) => (v as num).toDouble(),
    );
  }

  // 6. Capteur de proximité
  static const EventChannel _proximite =
      EventChannel('capteur/proximite');

  static Stream<bool> proximite() {
    return _proximite.receiveBroadcastStream().map(
      (v) => v as bool,
    );
  }

  // 7. Lampe torche
  static const MethodChannel _torche =
      MethodChannel('appareil/torche');

  static Future<void> allumerTorche(bool etat) {
    return _torche.invokeMethod(
      'allumer',
      {'etat': etat},
    );
  }
}