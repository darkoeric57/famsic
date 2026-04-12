package com.example.famsic

import android.content.ContentUris
import android.database.Cursor
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import android.graphics.Bitmap
import android.media.audiofx.Visualizer
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : AudioServiceActivity() {

    private val MEDIA_CHANNEL = "com.famsic.app/media_store"
    private val EQ_CHANNEL = "com.famsic.app/equalizer"
    private val VISUALIZER_CHANNEL = "com.famsic.app/visualizer"

    private val scope = MainScope()

    // Audio effects
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── MediaStore Channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "querySongs" -> {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val songs = querySongs()
                                withContext(Dispatchers.Main) { result.success(songs) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("QUERY_ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    "getArtwork" -> {
                        val uriStr = call.argument<String>("uri") ?: run {
                            result.success(null); return@setMethodCallHandler
                        }
                        scope.launch(Dispatchers.IO) {
                            try {
                                val bytes = getArtworkBytes(uriStr)
                                withContext(Dispatchers.Main) { result.success(bytes) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.success(null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Equalizer Channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQ_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Initialize effects on the given audio session ID
                    "init" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        try {
                            initEffects(sessionId)
                            result.success(getEqInfo())
                        } catch (e: Exception) {
                            result.error("INIT_ERROR", e.message, null)
                        }
                    }

                    // Get current EQ info (bands, ranges, current values)
                    "getInfo" -> {
                        try {
                            result.success(getEqInfo())
                        } catch (e: Exception) {
                            result.error("INFO_ERROR", e.message, null)
                        }
                    }

                    // Set a single band level (millibel)
                    "setBandLevel" -> {
                        val band = call.argument<Int>("band") ?: 0
                        val level = call.argument<Int>("level") ?: 0
                        try {
                            equalizer?.setBandLevel(band.toShort(), level.toShort())
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SET_BAND_ERROR", e.message, null)
                        }
                    }

                    // Apply a full preset (list of millibel values per band)
                    "applyBands" -> {
                        val levels = call.argument<List<Int>>("levels") ?: emptyList()
                        try {
                            levels.forEachIndexed { i, level ->
                                equalizer?.setBandLevel(i.toShort(), level.toShort())
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("APPLY_BANDS_ERROR", e.message, null)
                        }
                    }

                    // Enable / disable EQ
                    "setEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        try {
                            equalizer?.enabled = enabled
                            bassBoost?.enabled = enabled
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SET_ENABLED_ERROR", e.message, null)
                        }
                    }

                    // Set bass boost strength (0–1000)
                    "setBassBoost" -> {
                        val strength = call.argument<Int>("strength") ?: 0
                        try {
                            bassBoost?.setStrength(strength.toShort())
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("BASS_BOOST_ERROR", e.message, null)
                        }
                    }

                    // Set loudness gain in millibels (0–1000)
                    "setLoudness" -> {
                        val gainMb = call.argument<Int>("gainMb") ?: 0
                        try {
                            loudnessEnhancer?.setTargetGain(gainMb)
                            loudnessEnhancer?.enabled = gainMb > 0
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOUDNESS_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Visualizer Channel ──────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VISUALIZER_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // ── Audio Effects Initialization ──────────────────────────────────────

    private fun initEffects(audioSessionId: Int) {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bassBoost?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}
        try { visualizer?.release() } catch (_: Exception) {}

        equalizer = Equalizer(0, audioSessionId).also { it.enabled = true }
        bassBoost = BassBoost(0, audioSessionId).also { it.enabled = true }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            loudnessEnhancer = LoudnessEnhancer(audioSessionId).also { it.enabled = false }
        }

        // Initialize Visualizer
        try {
            visualizer = Visualizer(audioSessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
                setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(v: Visualizer?, waveform: ByteArray?, samplingRate: Int) {}

                    override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, samplingRate: Int) {
                        if (fft == null || eventSink == null) return
                        
                        // Extract magnitudes for 7 frequency buckets
                        val magnitudes = FloatArray(7)
                        val numBuckets = 7
                        val fftSize = fft.size / 2
                        val bucketSize = fftSize / numBuckets
                        
                        for (i in 0 until numBuckets) {
                            var sum = 0f
                            for (j in (i * bucketSize) until ((i + 1) * bucketSize)) {
                                val re = fft[j * 2].toFloat()
                                val im = fft[j * 2 + 1].toFloat()
                                sum += Math.sqrt((re * re + im * im).toDouble()).toFloat()
                            }
                            magnitudes[i] = (sum / bucketSize).coerceIn(0f, 100f)
                        }
                        
                        // Send magnitudes back to Flutter
                        scope.launch(Dispatchers.Main) {
                            eventSink?.success(magnitudes.toList())
                        }
                    }
                }, Visualizer.getMaxCaptureRate() / 2, false, true)
                enabled = true
            }
        } catch (e: Exception) {
            // Handle visualizer init failure (often due to missing RECORD_AUDIO permission)
        }
    }

    private fun getEqInfo(): Map<String, Any?> {
        val eq = equalizer ?: return mapOf("bands" to listOf<Any>(), "minLevel" to -1500, "maxLevel" to 1500)
        val numBands = eq.numberOfBands.toInt()
        val (min, max) = eq.bandLevelRange.let { it[0].toInt() to it[1].toInt() }

        val bands = (0 until numBands).map { i ->
            mapOf(
                "index" to i,
                "centerFreq" to eq.getCenterFreq(i.toShort()),  // in millihertz
                "level" to eq.getBandLevel(i.toShort()).toInt(),
            )
        }
        return mapOf(
            "bands" to bands,
            "minLevel" to min,
            "maxLevel" to max,
            "numBands" to numBands,
        )
    }

    // ── MediaStore Query ──────────────────────────────────────────────────

    private fun querySongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATE_ADDED,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"
        val cursor: Cursor? = contentResolver.query(collection, projection, selection, null, sortOrder)
        cursor?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val displayNameCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val dateAddedCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            while (c.moveToNext()) {
                val id = c.getLong(idCol)
                val contentUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                songs.add(mapOf(
                    "id" to id,
                    "title" to (c.getString(titleCol) ?: c.getString(displayNameCol) ?: "Unknown"),
                    "artist" to (c.getString(artistCol) ?: "Unknown Artist"),
                    "album" to (c.getString(albumCol) ?: "Unknown Album"),
                    "albumId" to c.getLong(albumIdCol),
                    "duration" to c.getLong(durationCol),
                    "data" to (c.getString(dataCol) ?: ""),
                    "uri" to contentUri.toString(),
                    "dateAdded" to c.getLong(dateAddedCol),
                ))
            }
        }
        return songs
    }

    private fun getArtworkBytes(uriStr: String): ByteArray? {
        return try {
            val uri = Uri.parse(uriStr)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val bitmap = contentResolver.loadThumbnail(uri, Size(512, 512), null)
                val stream = java.io.ByteArrayOutputStream()
                bitmap.compress(Bitmap.`CompressFormat`.JPEG, 80, stream)
                stream.toByteArray()
            } else {
                contentResolver.openInputStream(uri)?.use { it.readBytes() }
            }
        } catch (_: Exception) { null }
    }

    override fun onDestroy() {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bassBoost?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}
        try { visualizer?.release() } catch (_: Exception) {}
        scope.cancel()
        super.onDestroy()
    }
}
