package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

class CapteurProximite(context: Context) :
    EventChannel.StreamHandler,
    SensorEventListener {

    private val sensorManager =
        context.getSystemService(SensorManager::class.java)

    private val capteur: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)

    private var sink: EventChannel.EventSink? = null

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink
    ) {
        val sensor = capteur

        if (sensor == null) {
            events.error(
                "PAS_DE_CAPTEUR",
                "Ce téléphone n'a pas de capteur de proximité",
                null
            )
            return
        }

        sink = events
        sensorManager.registerListener(
            this,
            sensor,
            SensorManager.SENSOR_DELAY_NORMAL
        )
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val sensor = capteur ?: return

        event?.let {
            val proche = it.values[0] < sensor.maximumRange
            sink?.success(proche)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}