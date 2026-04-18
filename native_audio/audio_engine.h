#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the audio engine (miniaudio setup). Returns true on success.
bool AE_Initialize();

// Uninitialize and cleanup miniaudio.
void AE_Deinitialize();

// Load an audio file from an absolute path and start playing it.
bool AE_LoadAndPlay(const char* filePath);

// Pause playback.
void AE_Pause();

// Resume playback.
void AE_Play();

// Stop playback and unload current file.
void AE_Stop();

// Set system volume (0.0 to 1.0)
void AE_SetVolume(float volume);

// Enable or disable the Equalizer
void AE_SetEQEnabled(bool enabled);

// Set gain for a specific EQ band index (0-9 for the 10 bands). 
// Gain is expected in deciBels (-12.0 to +12.0)
void AE_SetEQBand(int bandIndex, float gainDb);

// Listening modes: 0 = Monitors/Large Speaker, 1 = Headphone/Earpiece
void AE_SetListeningMode(int mode);

// Headset Optimization: Toggles crossfeed and bass enhancement
void AE_SetHeadsetMode(bool active);

// Vocal Purity: Applies specialized filters for vocal clarity and transparency
void AE_EnableVocalPurity(bool active);

// Get playback state
bool AE_IsPlaying();

// Get length in milliseconds
double AE_GetDurationMs();

// Get current position in milliseconds
double AE_GetPositionMs();

// Seek to a position in milliseconds
void AE_SeekToMs(double positionMs);

// Get real-time magnitudes for visualizer (7 bands).
// magnitudes must be a pointer to an array of 7 floats.
void AE_GetMagnitudes(float* magnitudes);

#ifdef __cplusplus
}
#endif

#endif // AUDIO_ENGINE_H
