#define MINIAUDIO_IMPLEMENTATION
#include "include/miniaudio.h"
#include "audio_engine.h"

// Conditional FFmpeg support
#ifdef USE_FFMPEG
extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
}
#endif

#include <vector>
#include <mutex>
#include <atomic>
#include <cmath>
#include <cstring>
#include <unistd.h>
#include <cstdlib>
#include <android/log.h>

#define LOG_TAG "FamsicAudioEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

enum AE_State {
    STATE_IDLE = 0,
    STATE_LOADING = 1,
    STATE_PLAYING = 2
};

// --- Double-Precision Biquad Filter ---
struct Biquad {
    double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
    double z1[2] = {0, 0}, z2[2] = {0, 0};

    void calculatePeaking(double fs, double f0, double gainDb, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double A     = pow(10.0, gainDb / 40.0);
        double w0    = 2.0 * M_PI * f0 / fs;
        double sinW  = sin(w0);
        double cosW  = cos(w0);
        double alpha = sinW / (2.0 * Q);
        double a0    = 1.0 + alpha / A;
        b0 = (1.0 + alpha * A) / a0;
        b1 = (-2.0 * cosW)     / a0;
        b2 = (1.0 - alpha * A) / a0;
        a1 = (-2.0 * cosW)     / a0;
        a2 = (1.0 - alpha / A) / a0;
    }

    void calculateLowPass(double fs, double f0, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double w0    = 2.0 * M_PI * f0 / fs;
        double cosW  = cos(w0);
        double alpha = sin(w0) / (2.0 * Q);
        double a0    = 1.0 + alpha;
        b0 = (1.0 - cosW) / 2.0 / a0;
        b1 = (1.0 - cosW) / a0;
        b2 = (1.0 - cosW) / 2.0 / a0;
        a1 = (-2.0 * cosW) / a0;
        a2 = (1.0 - alpha) / a0;
    }

    void calculateHighPass(double fs, double f0, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double w0    = 2.0 * M_PI * f0 / fs;
        double cosW  = cos(w0);
        double alpha = sin(w0) / (2.0 * Q);
        double a0    = 1.0 + alpha;
        b0 = (1.0 + cosW) / 2.0 / a0;
        b1 = -(1.0 + cosW) / a0;
        b2 = (1.0 + cosW) / 2.0 / a0;
        a1 = (-2.0 * cosW) / a0;
        a2 = (1.0 - alpha) / a0;
    }

    void calculateBandpass(double fs, double f0, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double w0    = 2.0 * M_PI * f0 / fs;
        double sinW  = sin(w0);
        double cosW  = cos(w0);
        double alpha = sinW / (2.0 * Q);
        double a0    = 1.0 + alpha;
        b0 = alpha / a0;
        b1 = 0;
        b2 = -alpha / a0;
        a1 = (-2.0 * cosW) / a0;
        a2 = (1.0 - alpha) / a0;
    }

    void calculateHighShelf(double fs, double f0, double gainDb, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double A     = pow(10.0, gainDb / 40.0);
        double w0    = 2.0 * M_PI * f0 / fs;
        double cosW  = cos(w0);
        double alpha = sin(w0) / (2.0 * Q);
        double sqrtA = sqrt(A);
        double a0    = (A+1.0) - (A-1.0)*cosW + 2.0*sqrtA*alpha;
        b0 =    A * ( (A+1.0) + (A-1.0)*cosW + 2.0*sqrtA*alpha ) / a0;
        b1 = -2.0*A * ( (A-1.0) + (A+1.0)*cosW                  ) / a0;
        b2 =    A * ( (A+1.0) + (A-1.0)*cosW - 2.0*sqrtA*alpha ) / a0;
        a1 =  2.0 * ( (A-1.0) - (A+1.0)*cosW                  ) / a0;
        a2 =         ( (A+1.0) - (A-1.0)*cosW - 2.0*sqrtA*alpha ) / a0;
    }

    void calculateLowShelf(double fs, double f0, double gainDb, double Q) {
        if (fs <= 0.0 || f0 >= fs * 0.5) { identity(); return; }
        double A     = pow(10.0, gainDb / 40.0);
        double w0    = 2.0 * M_PI * f0 / fs;
        double cosW  = cos(w0);
        double alpha = sin(w0) / (2.0 * Q);
        double sqrtA = sqrt(A);
        double a0    = (A+1.0) + (A-1.0)*cosW + 2.0*sqrtA*alpha;
        b0 =    A * ( (A+1.0) - (A-1.0)*cosW + 2.0*sqrtA*alpha ) / a0;
        b1 =  2.0*A * ( (A-1.0) - (A+1.0)*cosW                  ) / a0;
        b2 =    A * ( (A+1.0) - (A-1.0)*cosW - 2.0*sqrtA*alpha ) / a0;
        a1 = -2.0 * ( (A-1.0) + (A+1.0)*cosW                  ) / a0;
        a2 =         ( (A+1.0) + (A-1.0)*cosW - 2.0*sqrtA*alpha ) / a0;
    }

    void identity() { b0=1; b1=0; b2=0; a1=0; a2=0; }

    inline double process(double in, int ch) {
        double out = b0*in + b1*z1[ch] + b2*z2[ch] - a1*z1[ch] - a2*z2[ch];
        z2[ch] = z1[ch];
        z1[ch] = out;
        return out;
    }
};

// --- Professional True-Peak Limiter ---
struct TruePeakLimiter {
    float peakEnv = 0.0f;
    float releaseCoeff = 0.999f; 
    float ceiling = 0.966f;     
    void setup(float fs, float releaseMs) {
        releaseCoeff = expf(-1.0f / (fs * (releaseMs / 1000.0f)));
    }
    inline float process(float in) {
        float absIn = fabsf(in);
        if (absIn > peakEnv) peakEnv = absIn;
        else peakEnv *= releaseCoeff;
        if (peakEnv > ceiling) {
            float gain = ceiling / peakEnv;
            return in * gain;
        }
        return in;
    }
};

// --- Interface for Hybrid Audio Source ---
struct IAudioSource {
    virtual ~IAudioSource() {}
    virtual bool open(const char* url, int targetSampleRate) = 0;
    virtual int readFrames(float* buffer, int count) = 0;
    virtual void seek(double ms) = 0;
    virtual void close() = 0;
    virtual double getDurationMs() = 0;
};

#ifdef USE_FFMPEG
class FFmpegSource : public IAudioSource {
public:
    FFmpegSource() = default;
    ~FFmpegSource() { close(); }

    bool open(const char* url, int targetSR) override {
        close();
        if (avformat_open_input(&formatCtx, url, NULL, NULL) != 0) return false;
        if (avformat_find_stream_info(formatCtx, NULL) < 0) return false;
        streamIdx = av_find_best_stream(formatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, &codec, 0);
        if (streamIdx < 0) return false;
        codecCtx = avcodec_alloc_context3(codec);
        avcodec_parameters_to_context(codecCtx, formatCtx->streams[streamIdx]->codecpar);
        if (avcodec_open2(codecCtx, codec, NULL) < 0) return false;
        packet = av_packet_alloc();
        frame = av_frame_alloc();
        swr = swr_alloc();
        av_opt_set_chlayout(swr, "in_chlayout",  &codecCtx->ch_layout, 0);
        av_opt_set_int(swr, "in_sample_rate",    codecCtx->sample_rate, 0);
        av_opt_set_sample_fmt(swr, "in_sample_fmt", codecCtx->sample_fmt, 0);
        AVChannelLayout outLayout;
        av_channel_layout_default(&outLayout, 2);
        av_opt_set_chlayout(swr, "out_chlayout", &outLayout, 0);
        av_opt_set_int(swr, "out_sample_rate",   targetSR, 0);
        av_opt_set_sample_fmt(swr, "out_sample_fmt", AV_SAMPLE_FMT_FLT, 0);
        swr_init(swr);
        durationMs = (double)formatCtx->streams[streamIdx]->duration * av_q2d(formatCtx->streams[streamIdx]->time_base) * 1000.0;
        isOpened = true;
        return true;
    }

    int readFrames(float* buffer, int count) override {
        if (!isOpened) return 0;
        int totalRead = 0;
        while (totalRead < count) {
            int outSamples = swr_get_out_samples(swr, 0);
            if (outSamples > 0) {
                int toRead = std::min(count - totalRead, outSamples);
                uint8_t* outPtr = (uint8_t*)(buffer + totalRead * 2);
                int converted = swr_convert(swr, &outPtr, toRead, NULL, 0);
                if (converted > 0) totalRead += converted;
            }
            if (totalRead >= count) break;
            if (av_read_frame(formatCtx, packet) < 0) break;
            if (packet->stream_index == streamIdx) {
                if (avcodec_send_packet(codecCtx, packet) == 0) {
                    while (avcodec_receive_frame(codecCtx, frame) == 0) {
                        uint8_t* outPtr = (uint8_t*)(buffer + totalRead * 2);
                        int toRead = count - totalRead;
                        int converted = swr_convert(swr, &outPtr, toRead, (const uint8_t**)frame->data, frame->nb_samples);
                        if (converted > 0) totalRead += converted;
                        if (totalRead >= count) break;
                    }
                }
            }
            av_packet_unref(packet);
        }
        return totalRead;
    }

    void seek(double ms) override {
        if (!isOpened) return;
        int64_t ts = (int64_t)(ms / 1000.0 / av_q2d(formatCtx->streams[streamIdx]->time_base));
        av_seek_frame(formatCtx, streamIdx, ts, AVSEEK_FLAG_BACKWARD);
        avcodec_flush_buffers(codecCtx);
    }

    void close() override {
        if (!isOpened) return;
        swr_free(&swr); av_frame_free(&frame); av_packet_free(&packet);
        avcodec_free_context(&codecCtx); avformat_close_input(&formatCtx);
        isOpened = false;
    }

    double getDurationMs() override { return durationMs; }

private:
    AVFormatContext* formatCtx = nullptr; AVCodecContext* codecCtx = nullptr;
    const AVCodec* codec = nullptr; AVPacket* packet = nullptr; AVFrame* frame = nullptr;
    SwrContext* swr = nullptr; int streamIdx = -1; bool isOpened = false; double durationMs = 0;
};
#endif

class MiniAudioSource : public IAudioSource {
public:
    MiniAudioSource() { memset(&decoder, 0, sizeof(decoder)); }
    ~MiniAudioSource() { close(); }

    bool open(const char* url, int targetSR) override {
        close();
        ma_decoder_config cfg = ma_decoder_config_init(ma_format_f32, 2, targetSR);
        if (ma_decoder_init_file(url, &cfg, &decoder) != MA_SUCCESS) return false;
        isOpened = true;
        return true;
    }

    int readFrames(float* buffer, int count) override {
        if (!isOpened) return 0;
        ma_uint64 read = 0;
        ma_decoder_read_pcm_frames(&decoder, buffer, count, &read);
        return (int)read;
    }

    void seek(double ms) override {
        if (!isOpened) return;
        ma_uint64 frame = (ma_uint64)(ms * decoder.outputSampleRate / 1000.0);
        ma_decoder_seek_to_pcm_frame(&decoder, frame);
    }

    void close() override {
        if (!isOpened) return;
        ma_decoder_uninit(&decoder);
        isOpened = false;
    }

    double getDurationMs() override {
        if (!isOpened) return 0;
        ma_uint64 total = 0;
        ma_decoder_get_length_in_pcm_frames(&decoder, &total);
        return (double)total / decoder.outputSampleRate * 1000.0;
    }

private:
    ma_decoder decoder;
    bool isOpened = false;
};

// --- Audio Globals ---
static ma_device  g_device;
static IAudioSource* g_currentSource = nullptr;
static std::atomic<AE_State> g_state{STATE_IDLE};
static std::atomic<float>    g_volume{1.0f};
static std::atomic<float>    g_autoGain{1.0f};
static std::atomic<double>   g_currentDurationMs{0.0};
static std::atomic<double>   g_currentPositionMs{0.0};
static std::atomic<bool>     g_isSeeking{false};
static std::atomic<bool>     g_isPlaying{false};
static std::mutex g_ctrlMutex;

// --- DSP Parameters ---
static std::atomic<bool>  g_eqEnabled{false};
static std::atomic<int>   g_listeningMode{0};
static std::atomic<bool>  g_headsetModeActive{false};
static std::atomic<bool>  g_vocalPurityEnabled{false};

const int NUM_BANDS = 10;
static float g_eqGains[NUM_BANDS] = {0};
static const float EQ_FREQS[NUM_BANDS] = { 32.0f, 64.0f, 125.0f, 250.0f, 500.0f, 1000.0f, 2000.0f, 4000.0f, 8000.0f, 16000.0f };

struct BiquadSet {
    Biquad eq[NUM_BANDS]; Biquad headset[4]; Biquad bassOptimize; Biquad crossfeedLP;
    Biquad vocalPurity[3]; Biquad monoLowPass; Biquad monoHighPass; Biquad loudnessContour;
};

static BiquadSet g_biquadSets[2];
static std::atomic<int> g_activeBiquadIndex{0};
static TruePeakLimiter  g_limiter;
const int CROSSFEED_DELAY_SAMPLES = 32;
static double g_delayLineL[CROSSFEED_DELAY_SAMPLES] = {0};
static double g_delayLineR[CROSSFEED_DELAY_SAMPLES] = {0};
static int    g_delayWriteIdx = 0;
const int VIZ_BANDS = 7;
static const float VIZ_FREQS[VIZ_BANDS] = { 60.0f, 150.0f, 400.0f, 1000.0f, 2400.0f, 6000.0f, 12000.0f };
static Biquad g_vizFilters[VIZ_BANDS]; static std::atomic<float> g_vizMagnitudes[VIZ_BANDS];
static float g_sampleRate = 48000.0f;

static void rebuildBiquadsInternal() {
    double fs = (double)g_sampleRate;
    int shadowIdx = 1 - g_activeBiquadIndex.load();
    BiquadSet* shadow = &g_biquadSets[shadowIdx];
    float maxBoostDb = 0.0f;
    for (int i = 0; i < NUM_BANDS; i++) if (g_eqGains[i] > maxBoostDb) maxBoostDb = g_eqGains[i];
    if (g_headsetModeActive.load() && 8.0f > maxBoostDb) maxBoostDb = 8.0f;
    g_autoGain.store(powf(10.0f, -maxBoostDb / 20.0f), std::memory_order_release);
    for (int i = 0; i < NUM_BANDS; i++) shadow->eq[i].calculatePeaking(fs, (double)EQ_FREQS[i], (double)g_eqGains[i], 1.414);
    shadow->vocalPurity[0].calculatePeaking(fs, 250.0, -2.5, 1.0); shadow->vocalPurity[1].calculatePeaking(fs, 3200.0, 1.5, 1.2);
    shadow->vocalPurity[2].calculatePeaking(fs, 8000.0, 2.0, 0.5); shadow->headset[0].calculateLowShelf(fs, 60.0, 8.0, 1.0);
    shadow->headset[1].calculatePeaking(fs, 140.0, 3.0, 1.2); shadow->headset[2].calculatePeaking(fs, 3200.0, 4.0, 1.5);
    shadow->headset[3].calculateHighShelf(fs, 14000.0, 5.0, 1.0); shadow->bassOptimize.calculateLowShelf(fs, 80.0, 4.0, 1.0);
    shadow->crossfeedLP.calculateLowShelf(fs, 800.0, -3.0, 0.707); shadow->monoLowPass.calculateLowPass(fs, 120.0, 0.707);
    shadow->monoHighPass.calculateHighPass(fs, 120.0, 0.707); shadow->loudnessContour.calculateHighShelf(fs, 2500.0, 2.0, 0.707);
    for (int i = 0; i < VIZ_BANDS; ++i) g_vizFilters[i].calculateBandpass(fs, (double)VIZ_FREQS[i], 1.2);
    g_limiter.setup(g_sampleRate, 50.0f); g_activeBiquadIndex.store(shadowIdx, std::memory_order_release);
}

static void data_callback(ma_device* pDevice, void* pOutput, const void* /*pInput*/, ma_uint32 fCount) {
    float* out = (float*)pOutput;
    if (g_state.load(std::memory_order_acquire) != STATE_PLAYING || !g_isPlaying.load() || g_isSeeking.load() || !g_currentSource) {
        memset(pOutput, 0, fCount * 2 * sizeof(float)); return;
    }
    int read = g_currentSource->readFrames(out, fCount);
    if (read == 0) { g_isPlaying.store(false); memset(pOutput, 0, fCount * 2 * sizeof(float)); return; }
    const bool eqOn = g_eqEnabled.load(); const bool vocalPurity = g_vocalPurityEnabled.load();
    const int mode = g_listeningMode.load(); const bool headsetOptim = g_headsetModeActive.load();
    const float vol = g_volume.load(); const float autoGain = g_autoGain.load();
    BiquadSet* biquads = &g_biquadSets[g_activeBiquadIndex.load(std::memory_order_acquire)];
    for (int i = 0; i < read; ++i) {
        double L = (double)out[i * 2 + 0] * autoGain; double R = (double)out[i * 2 + 1] * autoGain;
        if (vocalPurity) { for (int s = 0; s < 3; ++s) { L = biquads->vocalPurity[s].process(L, 0); R = biquads->vocalPurity[s].process(R, 1); } }
        if (eqOn) { for (int b = 0; b < NUM_BANDS; ++b) { L = biquads->eq[b].process(L, 0); R = biquads->eq[b].process(R, 1); } }
        if (mode == 1 || headsetOptim) {
            L = biquads->loudnessContour.process(L, 0); R = biquads->loudnessContour.process(R, 1);
            for (int s = 0; s < 4; ++s) { L = biquads->headset[s].process(L, 0); R = biquads->headset[s].process(R, 1); }
            if (headsetOptim) {
                double subL = biquads->monoLowPass.process(L, 0); double subR = biquads->monoLowPass.process(R, 1); double monoSub = (subL+subR)*0.5;
                double midHighL = biquads->monoHighPass.process(L, 0); double midHighR = biquads->monoHighPass.process(R, 1);
                L = midHighL + monoSub; R = midHighR + monoSub; L = biquads->bassOptimize.process(L, 0); R = biquads->bassOptimize.process(R, 1);
                g_delayLineL[g_delayWriteIdx] = L; g_delayLineR[g_delayWriteIdx] = R;
                int rIdx = (g_delayWriteIdx - 24 + CROSSFEED_DELAY_SAMPLES) % CROSSFEED_DELAY_SAMPLES;
                double cL = biquads->crossfeedLP.process(g_delayLineR[rIdx], 0) * 0.25;
                double cR = biquads->crossfeedLP.process(g_delayLineL[rIdx], 1) * 0.25;
                g_delayWriteIdx = (g_delayWriteIdx + 1) % CROSSFEED_DELAY_SAMPLES; L = (L + cL) * 0.9; R = (R + cR) * 0.9;
            } else { double m=(L+R)*0.5; double s=(L-R)*0.5*1.35; L=m+s; R=m-s; }
        }
        L = L * (1.5 - 0.5 * L * L) * vol; R = R * (1.5 - 0.5 * R * R) * vol; // softclip inline
        if (headsetOptim) { L *= 1.55; R *= 1.55; }
        float fL = g_limiter.process((float)L); float fR = g_limiter.process((float)R);
        float mono = (fL + fR) * 0.5f;
        for (int b = 0; b < VIZ_BANDS; ++b) {
            float f = (float)g_vizFilters[b].process((double)mono, 0);
            float a = fabsf(f); float c = g_vizMagnitudes[b].load();
            if (a > c) g_vizMagnitudes[b].store(a); else g_vizMagnitudes[b].store(c * 0.9995f);
        }
        out[i * 2 + 0] = fL; out[i * 2 + 1] = fR;
    }
    if (read < (int)fCount) memset(out + read * 2, 0, (fCount - read) * 2 * sizeof(float));
    g_currentPositionMs.store(g_currentPositionMs.load() + ((double)read / g_sampleRate * 1000.0));
}

extern "C" bool AE_Initialize() {
    std::lock_guard<std::mutex> lk(g_ctrlMutex);
    ma_device_config cfg = ma_device_config_init(ma_device_type_playback);
    cfg.playback.format = ma_format_f32; cfg.playback.channels = 2; cfg.sampleRate = 48000; cfg.dataCallback = data_callback;
    if (ma_device_init(NULL, &cfg, &g_device) != MA_SUCCESS) return false;
    g_sampleRate = (float)g_device.sampleRate;
    rebuildBiquadsInternal(); ma_device_start(&g_device); return true;
}
extern "C" bool AE_LoadAndPlay(const char* url) {
    std::lock_guard<std::mutex> lk(g_ctrlMutex);
    g_state.store(STATE_LOADING); g_isPlaying.store(false);
    if (g_currentSource) { g_currentSource->close(); delete g_currentSource; g_currentSource = nullptr; }
#ifdef USE_FFMPEG
    g_currentSource = new FFmpegSource();
    if (!g_currentSource->open(url, (int)g_sampleRate)) {
        delete g_currentSource;
        g_currentSource = new MiniAudioSource();
    }
#else
    g_currentSource = new MiniAudioSource();
#endif
    if (!g_currentSource->open(url, (int)g_sampleRate)) return false;
    g_currentDurationMs.store(g_currentSource->getDurationMs()); g_currentPositionMs.store(0.0);
    g_isPlaying.store(true); g_state.store(STATE_PLAYING); return true;
}
extern "C" void AE_Deinitialize() { if (g_currentSource) { g_currentSource->close(); delete g_currentSource; g_currentSource = nullptr; } ma_device_uninit(&g_device); }
extern "C" void AE_SetVolume(float v) { g_volume.store(v); }
extern "C" void AE_Pause() { g_isPlaying.store(false); }
extern "C" void AE_Play() { g_isPlaying.store(true); }
extern "C" void AE_Stop() { g_isPlaying.store(false); g_state.store(STATE_IDLE); }
extern "C" void AE_SetEQEnabled(bool e) { g_eqEnabled.store(e); }
extern "C" void AE_SetEQBand(int b, float g) { std::lock_guard<std::mutex> lk(g_ctrlMutex); g_eqGains[b] = g; rebuildBiquadsInternal(); }
extern "C" void AE_SetListeningMode(int m) { g_listeningMode.store(m); }
extern "C" void AE_SetHeadsetMode(bool a) { g_headsetModeActive.store(a); }
extern "C" void AE_EnableVocalPurity(bool a) { g_vocalPurityEnabled.store(a); }
extern "C" bool AE_IsPlaying() { return g_isPlaying.load(); }
extern "C" double AE_GetDurationMs() { return g_currentDurationMs.load(); }
extern "C" double AE_GetPositionMs() { return g_currentPositionMs.load(); }
extern "C" void AE_SeekToMs(double ms) { g_isSeeking.store(true); { std::lock_guard<std::mutex> lk(g_ctrlMutex); if (g_currentSource) g_currentSource->seek(ms); } g_currentPositionMs.store(ms); g_isSeeking.store(false); }
extern "C" void AE_GetMagnitudes(float* m) {
    for (int i=0; i<VIZ_BANDS; ++i) {
        float v = g_vizMagnitudes[i].exchange(0);
        m[i] = v > 0 ? (20.0f * log10f(v + 0.0001f) + 60.0f) / 60.0f : 0;
        if (m[i]<0) m[i]=0; if (m[i]>1) m[i]=1;
    }
}
