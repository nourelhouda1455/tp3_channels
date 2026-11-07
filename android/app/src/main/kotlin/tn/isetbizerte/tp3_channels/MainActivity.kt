package tn.isetbizerte.tp3_channels

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity() {

    private val scope = MainScope()

    private var resultatPermissionMicro: MethodChannel.Result? = null
    private var resultatPermissionCamera: MethodChannel.Result? = null
    private var etatTorcheEnAttente = false

    private lateinit var lampeTorche: LampeTorche

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messager = flutterEngine.dartExecutor.binaryMessenger

        // 1. Informations du téléphone
        MethodChannel(messager, "appareil/infos")
            .setMethodCallHandler { call, result ->

                when (call.method) {
                    "lire" -> {
                        val informations = mapOf(
                            "fabricant" to Build.MANUFACTURER,
                            "modele" to Build.MODEL,
                            "version" to Build.VERSION.RELEASE,
                            "sdk" to Build.VERSION.SDK_INT
                        )

                        result.success(informations)
                    }

                    else -> result.notImplemented()
                }
            }

        // 2. Vibration
        MethodChannel(messager, "appareil/vibrer")
            .setMethodCallHandler(Vibreur(this))

        // 3. Capteur de lumière
        EventChannel(messager, "capteur/lumiere")
            .setStreamHandler(CapteurLumiere(this))

        // 4. Permission microphone
        MethodChannel(messager, "audio/permission")
            .setMethodCallHandler { call, result ->

                when (call.method) {
                    "demander" -> {
                        if (
                            checkSelfPermission(Manifest.permission.RECORD_AUDIO)
                            == PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)
                        } else {
                            resultatPermissionMicro = result

                            requestPermissions(
                                arrayOf(Manifest.permission.RECORD_AUDIO),
                                REQ_MICRO
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // 5. Niveau sonore
        EventChannel(messager, "audio/niveau")
            .setStreamHandler(NiveauSonore(scope))

        // 6. Capteur de proximité
        EventChannel(messager, "capteur/proximite")
            .setStreamHandler(CapteurProximite(this))

        // 7. Lampe torche
        lampeTorche = LampeTorche(this)

        MethodChannel(messager, "appareil/torche")
            .setMethodCallHandler { call, result ->

                when (call.method) {
                    "allumer" -> {
                        val etat = call.argument<Boolean>("etat") ?: false

                        if (
                            checkSelfPermission(Manifest.permission.CAMERA)
                            == PackageManager.PERMISSION_GRANTED
                        ) {
                            lampeTorche.allumer(etat, result)
                        } else {
                            etatTorcheEnAttente = etat
                            resultatPermissionCamera = result

                            requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                REQ_CAMERA
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        when (requestCode) {
            REQ_MICRO -> {
                resultatPermissionMicro?.success(
                    grantResults.firstOrNull() ==
                        PackageManager.PERMISSION_GRANTED
                )

                resultatPermissionMicro = null
            }

            REQ_CAMERA -> {
                val accordee =
                    grantResults.firstOrNull() ==
                        PackageManager.PERMISSION_GRANTED

                val resultat = resultatPermissionCamera
                resultatPermissionCamera = null

                if (accordee && resultat != null) {
                    lampeTorche.allumer(etatTorcheEnAttente, resultat)
                } else {
                    resultat?.error(
                        "PERMISSION_REFUSEE",
                        "La permission caméra est nécessaire pour utiliser le flash",
                        null
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val REQ_MICRO = 42
        private const val REQ_CAMERA = 43
    }
}