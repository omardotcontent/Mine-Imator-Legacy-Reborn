#pragma once

#ifndef SPATIAL_AUDIO_DSP_ONLY
#include "Common.hpp"
#endif

#include <array>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <memory>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <vector>

namespace CppProject
{
	static constexpr int kAudioSampleRate = 44100;
	static constexpr double kAudioPi = 3.14159265358979323846;

	struct AudioVec3
	{
		double x = 0.0;
		double y = 0.0;
		double z = 0.0;

		AudioVec3 operator+(const AudioVec3& o) const { return { x + o.x, y + o.y, z + o.z }; }
		AudioVec3 operator-(const AudioVec3& o) const { return { x - o.x, y - o.y, z - o.z }; }
		AudioVec3 operator*(double s) const { return { x * s, y * s, z * s }; }

		double Dot(const AudioVec3& o) const { return x * o.x + y * o.y + z * o.z; }
		double LenSq() const { return x * x + y * y + z * z; }
		double Len() const { return std::sqrt(LenSq()); }

		AudioVec3 Cross(const AudioVec3& o) const
		{
			return {
				y * o.z - z * o.y,
				z * o.x - x * o.z,
				x * o.y - y * o.x
			};
		}

		AudioVec3 Normalize(const AudioVec3& fallback = { 0.0, 1.0, 0.0 }) const
		{
			double l = Len();
			if (l <= 1e-8)
				return fallback;
			double inv = 1.0 / l;
			return { x * inv, y * inv, z * inv };
		}
	};

	struct AudioListenerState
	{
		AudioVec3 pos{ 0.0, 0.0, 0.0 };
		AudioVec3 vel{ 0.0, 0.0, 0.0 };
		AudioVec3 forward{ 0.0, 1.0, 0.0 };
		AudioVec3 right{ 1.0, 0.0, 0.0 };
		AudioVec3 up{ 0.0, 0.0, 1.0 };

		// Matches Mine-imator's left-handed view basis (matrix_create_lookat & cam right strafe).
		static AudioListenerState FromCamera(AudioVec3 from, AudioVec3 to, AudioVec3 upHint, AudioVec3 velocity = { 0.0, 0.0, 0.0 });
	};

	struct AudioTrackParams
	{
		bool spatial = false;
		AudioVec3 pos{ 0.0, 0.0, 0.0 };
		AudioVec3 vel{ 0.0, 0.0, 0.0 };
		double range = 250.0;
		double falloff = 0.20;
		double doppler = 0.0;
		double pan = 0.0;
		double fadeIn = 0.0;
		double fadeOut = 0.0;
		double lpf = 0.0;
		double distMuffle = 0.35;
		int hpfMode = 0; // 0=Off, 1=High-Pass, 2=Walkie-Talkie/Radio, 3=Megaphone/PA
		double hpfMix = 1.0;
		int reverbMode = 0; // 0=Off, 1=Small Room, 2=Large Hall, 3=Cave/Cavern, 4=Outdoor Arena
		double reverbMix = 0.30;
		double reverbDecay = 0.50;
		bool muted = false;
	};

	class SpatialAudioDspVoice
	{
	public:
		struct ReverbState
		{
			static constexpr int kNumCombs = 4;
			static constexpr int kNumAllpass = 2;
			static constexpr int kStereoSpread = 23;

			std::vector<float> preDelayL, preDelayR;
			int preIdx = 0;
			int preDelaySamples = 260;

			std::vector<float> combBufL[kNumCombs];
			std::vector<float> combBufR[kNumCombs];
			int combIdxL[kNumCombs] = {};
			int combIdxR[kNumCombs] = {};
			float combStoreL[kNumCombs] = {};
			float combStoreR[kNumCombs] = {};

			std::vector<float> apBufL[kNumAllpass];
			std::vector<float> apBufR[kNumAllpass];
			int apIdxL[kNumAllpass] = {};
			int apIdxR[kNumAllpass] = {};

			int activeMode = -1;
			void Configure(int mode);
			void Reset();
			void Process(float inL, float inR, int mode, float decay, float& outWetL, float& outWetR);
		};

		struct Biquad
		{
			double b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0;
			double z1 = 0.0, z2 = 0.0;

			void SetHighPass(double cutoffHz, double q);
			void SetLowPass(double cutoffHz, double q);
			void Reset();
			float Process(float x);
		};

		void Init(std::shared_ptr<const std::vector<int16_t>> pcmData,
				  double volume, double pitch, bool isLoop,
				  double totalDurSec, double initialElapsedSec);

		void SetVolume(double volume) { baseVolume = volume; }
		void SetPitch(double pitch) { basePitch = pitch; }
		void SetLoop(bool isLoop) { loop = isLoop; }
		void SetTrackPositionSec(double sec);
		double GetTrackPositionSec() const;
		void TriggerRelease();
		bool IsFinished() const { return finished; }

		// Accumulate processed audio into an interleaved or planar mix buffer.
		// outChannels must be 2 (Stereo) or 6 (5.1 Surround: FL, FR, FC, LFE, BL, BR).
		void RenderAccumulate(float* outBuf, int numFrames, int outChannels, bool planarOut,
							  const AudioListenerState& listener, const AudioTrackParams& params);

	private:
		std::shared_ptr<const std::vector<int16_t>> pcm;
		int64_t totalPcmFrames = 0;

		double baseVolume = 1.0;
		double basePitch = 1.0;
		bool loop = false;

		double readFramePos = 0.0;
		double clipElapsedSec = 0.0;
		double clipTotalDurSec = -1.0;

		bool releasing = false;
		bool releaseTailArmed = false;
		int tailSamplesRemaining = 0;
		int releaseElapsedSamples = 0;
		int silentTailSamples = 0;
		bool finished = false;

		// Smoothing & filter state
		double dopplerSmooth = 1.0;
		float lpfZ1[2] = { 0.0f, 0.0f };
		float lpfZ2[2] = { 0.0f, 0.0f };
		float lfeZ1 = 0.0f;
		float lfeZ2 = 0.0f;

		int configuredEqMode = 0;
		Biquad eqHpf[2];
		Biquad eqLpf[2];

		std::unique_ptr<ReverbState> reverb;

		// 64-sample fractional ITD delay line for 3D stereo cues
		static constexpr int kItdBufSize = 64;
		float itdBuf[kItdBufSize] = {};
		int itdWriteIdx = 0;

		// Gain smoother for up to 6 channels
		bool gainsInitialized = false;
		float chGainSmooth[6] = {};
	};

#ifndef SPATIAL_AUDIO_DSP_ONLY
	class SpatialAudioEngine
	{
	public:
		static SpatialAudioEngine& Instance();

		void Init();
		void Shutdown();
		bool IsInitialized() const { return initialized.load(); }

		int64_t PlaySound(const void* soundAssetPtr,
						  std::shared_ptr<const std::vector<int16_t>> pcmData,
						  int64_t tlId, int64_t kfId, bool loop,
						  double totalDurSec, double initElapsedSec);

		void StopSound(int64_t voiceId);
		void ReleaseSound(int64_t voiceId);
		void StopAll();
		void StopBySoundAsset(const void* soundAssetPtr);

		void PauseSound(int64_t voiceId);
		void ResumeSound(int64_t voiceId);
		bool IsPlaying(int64_t voiceId);
		bool IsPaused(int64_t voiceId);

		void SetGain(int64_t voiceId, double volume);
		void SetPitch(int64_t voiceId, double pitch);
		void SetTrackPos(int64_t voiceId, double sec);
		double GetTrackPos(int64_t voiceId);

		void UpdateSceneState(const AudioListenerState& newListener,
							  std::unordered_map<int64_t, AudioTrackParams> newTracks);

	private:
		SpatialAudioEngine() = default;
		~SpatialAudioEngine();
		SpatialAudioEngine(const SpatialAudioEngine&) = delete;
		SpatialAudioEngine& operator=(const SpatialAudioEngine&) = delete;

		struct VoiceEntry
		{
			int64_t id = -1;
			const void* assetPtr = nullptr;
			int64_t tlId = -1;
			int64_t kfId = -1;
			bool paused = false;
			SpatialAudioDspVoice dsp;
		};

		void MixerThreadLoop();
		void FillBuffer(uint32_t alBufId);

		static constexpr int kNumStreamBuffers = 4;
		static constexpr int kBlockFrames = 512;

		std::mutex mtx;
		std::atomic<bool> initialized{ false };
		std::atomic<bool> running{ false };
		std::thread mixerThread;

		uint32_t streamSource = 0;
		uint32_t streamBuffers[kNumStreamBuffers] = {};

		int64_t nextVoiceId = 1;
		std::vector<std::unique_ptr<VoiceEntry>> voices;

		AudioListenerState listener;
		std::unordered_map<int64_t, AudioTrackParams> tracks;
		std::vector<float> mixFloatBuf;
		std::vector<int16_t> mixPcmBuf;
	};
#endif
}
