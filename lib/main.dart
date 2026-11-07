import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'native/canaux.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TP3 - Platform Channels',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const InfosPage(),
    );
  }
}

class InfosPage extends StatefulWidget {
  const InfosPage({super.key});

  @override
  State<InfosPage> createState() => _InfosPageState();
}

class _InfosPageState extends State<InfosPage> {
  // Informations du téléphone
  Map<String, dynamic>? informations;
  bool loading = false;

  // Vibration
  String? dernierMotif;

  // Lumière
  double? lux;
  bool lumiereActive = false;
  StreamSubscription<double>? abonnementLumiere;

  // Microphone
  double? db;
  bool microActif = false;
  StreamSubscription<double>? abonnementAudio;

  // Proximité
  bool? proche;
  bool proximiteActive = false;
  StreamSubscription<bool>? abonnementProximite;

  // Torche
  bool etatTorche = false;

  // Afficher un message
  void message(String texte) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  // 1. Lire les informations
  Future<void> chargerInfos() async {
    setState(() {
      loading = true;
    });

    final resultat = await Canaux.lireInfos();

    if (!mounted) return;

    setState(() {
      informations = resultat;
      loading = false;
    });
  }

  // 2. Vibration
  Future<void> lancerVibration(String motif) async {
    try {
      await Canaux.vibrer(motif);

      if (!mounted) return;

      setState(() {
        dernierMotif = motif;
      });

      message('Vibration : $motif');
    } on PlatformException catch (e) {
      message('Erreur vibration : ${e.message}');
    }
  }

  // 3. Démarrer / arrêter le capteur de lumière
  Future<void> basculerLumiere() async {
    if (lumiereActive) {
      await abonnementLumiere?.cancel();

      if (!mounted) return;

      setState(() {
        abonnementLumiere = null;
        lumiereActive = false;
      });
    } else {
      try {
        final abonnement = Canaux.lumiere().listen(
          (valeur) {
            if (!mounted) return;

            setState(() {
              lux = valeur;
            });
          },
          onError: (e) {
            message('Erreur capteur lumière : $e');
          },
        );

        if (!mounted) {
          await abonnement.cancel();
          return;
        }

        setState(() {
          abonnementLumiere = abonnement;
          lumiereActive = true;
        });
      } catch (e) {
        message('Impossible de démarrer le capteur : $e');
      }
    }
  }

  // 4. Démarrer / arrêter le microphone
  Future<void> basculerMicro() async {
    if (microActif) {
      await abonnementAudio?.cancel();

      if (!mounted) return;

      setState(() {
        abonnementAudio = null;
        microActif = false;
      });
    } else {
      try {
        final autorise = await Canaux.demanderMicro();

        if (!mounted) return;

        if (!autorise) {
          message('Permission microphone refusée');
          return;
        }

        final abonnement = Canaux.niveauSonore().listen(
          (valeur) {
            if (!mounted) return;

            setState(() {
              db = valeur;
            });
          },
          onError: (e) {
            message('Erreur microphone : $e');
          },
        );

        setState(() {
          abonnementAudio = abonnement;
          microActif = true;
        });
      } on PlatformException catch (e) {
        message('Erreur microphone : ${e.message}');
      }
    }
  }

  // 5. Démarrer / arrêter le capteur de proximité
  Future<void> basculerProximite() async {
    if (proximiteActive) {
      await abonnementProximite?.cancel();

      if (!mounted) return;

      setState(() {
        abonnementProximite = null;
        proximiteActive = false;
      });
    } else {
      try {
        final abonnement = Canaux.proximite().listen(
          (valeur) {
            if (!mounted) return;

            setState(() {
              proche = valeur;
            });
          },
          onError: (e) {
            message('Erreur capteur proximité : $e');
          },
        );

        if (!mounted) {
          await abonnement.cancel();
          return;
        }

        setState(() {
          abonnementProximite = abonnement;
          proximiteActive = true;
        });
      } catch (e) {
        message('Impossible de démarrer le capteur : $e');
      }
    }
  }

  // 6. Allumer / éteindre la torche
  Future<void> basculerTorche(bool etat) async {
    try {
      await Canaux.allumerTorche(etat);

      if (!mounted) return;

      setState(() {
        etatTorche = etat;
      });
    } on PlatformException catch (e) {
      message('Erreur torche : ${e.message}');
    }
  }

  // Libérer les abonnements
  @override
  void dispose() {
    abonnementLumiere?.cancel();
    abonnementAudio?.cancel();
    abonnementProximite?.cancel();

    super.dispose();
  }

  // Carte réutilisable
  Widget carte({
    required String titre,
    required IconData icone,
    required Widget contenu,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 26),
                const SizedBox(width: 10),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            contenu,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TP3 - Platform Channels'),
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // 1. Informations du téléphone
          carte(
            titre: 'Informations du téléphone',
            icone: Icons.phone_android,
            contenu: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: loading ? null : chargerInfos,
                  child: const Text('Lire les informations'),
                ),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),

                if (informations != null) ...[
                  const SizedBox(height: 10),
                  Text('Fabricant : ${informations!['fabricant']}'),
                  Text('Modèle : ${informations!['modele']}'),
                  Text('Android : ${informations!['version']}'),
                  Text('SDK : ${informations!['sdk']}'),
                ],
              ],
            ),
          ),

          // 2. Vibration
          carte(
            titre: 'Vibration',
            icone: Icons.vibration,
            contenu: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => lancerVibration('court'),
                      child: const Text('Court'),
                    ),
                    ElevatedButton(
                      onPressed: () => lancerVibration('long'),
                      child: const Text('Long'),
                    ),
                    ElevatedButton(
                      onPressed: () => lancerVibration('sos'),
                      child: const Text('SOS'),
                    ),
                    OutlinedButton(
                      onPressed: () => lancerVibration('disco'),
                      child: const Text('Disco (test erreur)'),
                    ),
                  ],
                ),
                if (dernierMotif != null)
                  Text('Dernier motif : $dernierMotif'),
              ],
            ),
          ),

          // 3. Capteur de lumière
          carte(
            titre: 'Capteur de lumière',
            icone: Icons.light_mode,
            contenu: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lux == null
                      ? 'Luminosité : -- lux'
                      : 'Luminosité : ${lux!.toStringAsFixed(2)} lux',
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: basculerLumiere,
                  child: Text(
                    lumiereActive
                        ? 'Arrêter le capteur'
                        : 'Démarrer le capteur',
                  ),
                ),
              ],
            ),
          ),

          // 4. Microphone
          carte(
            titre: 'Niveau sonore',
            icone: Icons.mic,
            contenu: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  db == null
                      ? 'Niveau sonore : -- dB'
                      : 'Niveau sonore : ${db!.toStringAsFixed(2)} dB',
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: basculerMicro,
                  child: Text(
                    microActif
                        ? 'Arrêter le microphone'
                        : 'Démarrer le microphone',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Mesures limitées à une valeur toutes les 200 ms.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          // 5. Proximité
          carte(
            titre: 'Capteur de proximité',
            icone: Icons.sensors,
            contenu: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proche == null
                      ? 'État : --'
                      : proche!
                          ? 'État : Proche'
                          : 'État : Loin',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: basculerProximite,
                  child: Text(
                    proximiteActive
                        ? 'Arrêter le capteur'
                        : 'Démarrer le capteur',
                  ),
                ),
              ],
            ),
          ),

          // 6. Lampe torche
          carte(
            titre: 'Lampe torche',
            icone: Icons.flashlight_on,
            contenu: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                etatTorche ? 'Torche allumée' : 'Torche éteinte',
              ),
              value: etatTorche,
              onChanged: basculerTorche,
            ),
          ),
        ],
      ),
    );
  }
}