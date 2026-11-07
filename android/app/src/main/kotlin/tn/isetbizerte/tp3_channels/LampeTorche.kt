package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LampeTorche(context: Context) :
    MethodChannel.MethodCallHandler {

    private val cameraManager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    fun allumer(etat: Boolean, result: MethodChannel.Result) {
        try {
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }

            if (cameraId == null) {
                result.error(
                    "PAS_DE_FLASH",
                    "Aucun flash disponible sur cet appareil",
                    null
                )
            } else {
                cameraManager.setTorchMode(cameraId, etat)
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("TORCHE_ERREUR", e.message, null)
        }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "allumer" -> {
                val etat = call.argument<Boolean>("etat") ?: false
                allumer(etat, result)
            }

            else -> result.notImplemented()
        }
    }
}