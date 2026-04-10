package com.example.famsic

import android.content.ContentUris
import android.database.Cursor
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : AudioServiceActivity() {

    private val MEDIA_CHANNEL = "com.famsic.app/media_store"
    private val EQ_CHANNEL = "com.famsic.app/equalizer"

    private val scope = MainScope()

    // Audio effects (null until audio session is ready)
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

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
                        val songId = call.argument<Long>("id") ?: run {
                            result.success(null); return@setMethodCallHandler
                        }
                        scope.launch(Dispatchers.IO) {
                            try {
                                val bytes = getArtworkBytes(songId)
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
    }

    // ── Audio Effects Initialization ──────────────────────────────────────

    private fun initEffects(audioSessionId: Int) {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bassBoost?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}

        equalizer = Equalizer(0, audioSessionId).also { it.enabled = true }
        bassBoost = BassBoost(0, audioSessionId).also { it.enabled = true }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            loudnessEnhancer = LoudnessEnhancer(audioSessionId).also { it.enabled = false }
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
                ))
            }
        }
        return songs
    }

    private fun getArtworkBytes(songId: Long): ByteArray? {
        return try {
            val uri = Uri.parse("content://media/external/audio/albumart/$songId")
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (_: Exception) { null }
    }

    override fun onDestroy() {
        try { equalizer?.release() } catch (_: Exception) {}
        try { bassBoost?.release() } catch (_: Exception) {}
        try { loudnessEnhancer?.release() } catch (_: Exception) {}
        scope.cancel()
        super.onDestroy()
    }
}
