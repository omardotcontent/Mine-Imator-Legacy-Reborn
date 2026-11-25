#include "SpatialAudio.hpp"

#include <algorithm>
#include <cstring>

#ifndef SPATIAL_AUDIO_DSP_ONLY
#include <AL/al.h>
#endif

namespace CppProject
{
	namespace
	{
		static inline float FastTanhSoftLimit(float x)
		{
			float ax = std::abs(x);
			if (ax <= 0.90f)
				return x;
			float sign = (x < 0.0f) ? -1.0f : 1.0f;
			return sign * (0.90f + 0.10f * std::tanh((ax - 0.90f) * 3.5f));
		}

		static inline float ReadItdFraction(const float* buf, int size, int writeIdx, double delaySamples)
		{
			double d = std::clamp(delaySamples, 0.0, (double)(size - 2));
			int dInt = (int)std::floor(d);
			float frac = (float)(d - (double)dInt);
			int idx0 = (writeIdx - dInt + size) % size;
			int idx1 = (writeIdx - dInt - 1 + size) % size;
			return buf[idx0] * (1.0f - frac) + buf[idx1] * frac;
		}
	}

	AudioListenerState AudioListenerState::FromCamera(AudioVec3 from, AudioVec3 to, AudioVec3 upHint, AudioVec3 velocity)
	{
		AudioListenerState st;
		st.pos = from;
		st.vel = velocity;
		st.forward = (to - from).Normalize({ 0.0, 1.0, 0.0 });

		AudioVec3 r = upHint.Cross(st.forward);
		if (r.LenSq() <= 1e-8)
		{
			AudioVec3 altUp = (std::abs(st.forward.y) < 0.9) ? AudioVec3{ 0.0, 1.0, 0.0 } : AudioVec3{ 1.0, 0.0, 0.0 };
			r = altUp.Cross(st.forward);
		}
		st.right = r.Normalize({ 1.0, 0.0, 0.0 });
		st.up = st.forward.Cross(st.right).Normalize({ 0.0, 0.0, 1.0 });
		return st;
	}

	void SpatialAudioDspVoice::Biquad::SetHighPass(double cutoffHz, double q)
	{
		double w0 = 2.0 * kAudioPi * std::clamp(cutoffHz, 20.0, 20000.0) / (double)kAudioSampleRate;
		double cosw0 = std::cos(w0);
		double alpha = std::sin(w0) / (2.0 * std::max(0.1, q));
		double invA0 = 1.0 / (1.0 + alpha);

		b0 = ((1.0 + cosw0) * 0.5) * invA0;
		b1 = (-(1.0 + cosw0)) * invA0;
		b2 = ((1.0 + cosw0) * 0.5) * invA0;
		a1 = (-2.0 * cosw0) * invA0;
		a2 = (1.0 - alpha) * invA0;
	}

	void SpatialAudioDspVoice::Biquad::SetLowPass(double cutoffHz, double q)
	{
		double w0 = 2.0 * kAudioPi * std::clamp(cutoffHz, 20.0, 20000.0) / (double)kAudioSampleRate;
		double cosw0 = std::cos(w0);
		double alpha = std::sin(w0) / (2.0 * std::max(0.1, q));
		double invA0 = 1.0 / (1.0 + alpha);

		b0 = ((1.0 - cosw0) * 0.5) * invA0;
		b1 = (1.0 - cosw0) * invA0;
		b2 = ((1.0 - cosw0) * 0.5) * invA0;
		a1 = (-2.0 * cosw0) * invA0;
		a2 = (1.0 - alpha) * invA0;
	}

	void SpatialAudioDspVoice::Biquad::Reset()
	{
		z1 = 0.0;
		z2 = 0.0;
	}

	float SpatialAudioDspVoice::Biquad::Process(float x)
	{
		double y = b0 * (double)x + z1;
		z1 = b1 * (double)x - a1 * y + z2;
		z2 = b2 * (double)x - a2 * y;
		return (float)y;
	}

	void SpatialAudioDspVoice::ReverbState::Configure(int mode)
	{
		static constexpr int kCombDelays[4][kNumCombs] = {
			{ 487, 547, 613, 677 },     // 1: Small Room
			{ 1277, 1433, 1597, 1777 }, // 2: Large Hall
			{ 2081, 2377, 2713, 3119 }, // 3: Cave / Cavern
			{ 3001, 3571, 4153, 4783 }  // 4: Outdoor Arena / Echo
		};
		static constexpr int kPreDelays[4] = { 260, 970, 1680, 2420 };
		static constexpr int kApDelays[kNumAllpass] = { 225, 341 };

		int idx = std::clamp(mode - 1, 0, 3);
		activeMode = mode;
		preDelaySamples = kPreDelays[idx];
		preDelayL.assign((size_t)preDelaySamples, 0.0f);
		preDelayR.assign((size_t)preDelaySamples, 0.0f);
		preIdx = 0;

		for (int i = 0; i < kNumCombs; i++)
		{
			combBufL[i].assign((size_t)kCombDelays[idx][i], 0.0f);
			combBufR[i].assign((size_t)(kCombDelays[idx][i] + kStereoSpread), 0.0f);
			combIdxL[i] = 0;
			combIdxR[i] = 0;
			combStoreL[i] = 0.0f;
			combStoreR[i] = 0.0f;
		}
		for (int i = 0; i < kNumAllpass; i++)
		{
			apBufL[i].assign((size_t)kApDelays[i], 0.0f);
			apBufR[i].assign((size_t)(kApDelays[i] + kStereoSpread), 0.0f);
			apIdxL[i] = 0;
			apIdxR[i] = 0;
		}
	}

	void SpatialAudioDspVoice::ReverbState::Reset()
	{
		std::fill(preDelayL.begin(), preDelayL.end(), 0.0f);
		std::fill(preDelayR.begin(), preDelayR.end(), 0.0f);
		preIdx = 0;
		for (int i = 0; i < kNumCombs; i++)
		{
			std::fill(combBufL[i].begin(), combBufL[i].end(), 0.0f);
			std::fill(combBufR[i].begin(), combBufR[i].end(), 0.0f);
			combIdxL[i] = 0;
			combIdxR[i] = 0;
			combStoreL[i] = 0.0f;
			combStoreR[i] = 0.0f;
		}
		for (int i = 0; i < kNumAllpass; i++)
		{
			std::fill(apBufL[i].begin(), apBufL[i].end(), 0.0f);
			std::fill(apBufR[i].begin(), apBufR[i].end(), 0.0f);
			apIdxL[i] = 0;
			apIdxR[i] = 0;
		}
	}

	void SpatialAudioDspVoice::ReverbState::Process(float inL, float inR, int mode, float decay, float& outWetL, float& outWetR)
	{
		if (activeMode != mode)
			Configure(mode);

		float damp = 0.35f;
		float fb = 0.72f;
		switch (mode)
		{
			case 1: damp = 0.48f; fb = 0.58f + 0.25f * decay; break;
			case 2: damp = 0.30f; fb = 0.72f + 0.20f * decay; break;
			case 3: damp = 0.42f; fb = 0.79f + 0.165f * decay; break;
			case 4: damp = 0.24f; fb = 0.68f + 0.24f * decay; break;
			default: damp = 0.40f; fb = 0.60f; break;
		}
		fb = std::clamp(fb, 0.1f, 0.965f);
		float dampInv = 1.0f - damp;

		float pdInL = inL * 0.32f;
		float pdInR = inR * 0.32f;
		float delayedInL = preDelayL[preIdx];
		float delayedInR = preDelayR[preIdx];
		preDelayL[preIdx] = pdInL;
		preDelayR[preIdx] = pdInR;
		if (++preIdx >= preDelaySamples)
			preIdx = 0;

		float accL = 0.0f;
		float accR = 0.0f;
		for (int i = 0; i < kNumCombs; i++)
		{
			float outL = combBufL[i][combIdxL[i]];
			combStoreL[i] = outL * dampInv + combStoreL[i] * damp;
			combBufL[i][combIdxL[i]] = delayedInL + combStoreL[i] * fb;
			if (++combIdxL[i] >= (int)combBufL[i].size())
				combIdxL[i] = 0;
			accL += outL;

			float outR = combBufR[i][combIdxR[i]];
			combStoreR[i] = outR * dampInv + combStoreR[i] * damp;
			combBufR[i][combIdxR[i]] = delayedInR + combStoreR[i] * fb;
			if (++combIdxR[i] >= (int)combBufR[i].size())
				combIdxR[i] = 0;
			accR += outR;
		}

		float yL = accL * 0.25f;
		float yR = accR * 0.25f;

		// Two series Schroeder allpass diffusers per channel (unity all-frequency magnitude)
		for (int i = 0; i < kNumAllpass; i++)
		{
			float bufOutL = apBufL[i][apIdxL[i]];
			float vL = yL - 0.5f * bufOutL;
			yL = bufOutL + 0.5f * vL;
			apBufL[i][apIdxL[i]] = vL;
			if (++apIdxL[i] >= (int)apBufL[i].size())
				apIdxL[i] = 0;

			float bufOutR = apBufR[i][apIdxR[i]];
			float vR = yR - 0.5f * bufOutR;
			yR = bufOutR + 0.5f * vR;
			apBufR[i][apIdxR[i]] = vR;
			if (++apIdxR[i] >= (int)apBufR[i].size())
				apIdxR[i] = 0;
		}

		outWetL = yL;
		outWetR = yR;
	}

	void SpatialAudioDspVoice::Init(std::shared_ptr<const std::vector<int16_t>> pcmData,
									double volume, double pitch, bool isLoop,
									double totalDurSec, double initialElapsedSec)
	{
		pcm = std::move(pcmData);
		totalPcmFrames = pcm ? (int64_t)(pcm->size() / 2) : 0;
		baseVolume = volume;
		basePitch = pitch;
		loop = isLoop;

		readFramePos = 0.0;
		clipElapsedSec = std::max(0.0, initialElapsedSec);
		clipTotalDurSec = totalDurSec;

		releasing = false;
		releaseTailArmed = false;
		tailSamplesRemaining = 0;
		releaseElapsedSamples = 0;
		silentTailSamples = 0;
		finished = (totalPcmFrames <= 0);

		dopplerSmooth = 1.0;
		lpfZ1[0] = lpfZ1[1] = 0.0f;
		lpfZ2[0] = lpfZ2[1] = 0.0f;
		lfeZ1 = lfeZ2 = 0.0f;
		configuredEqMode = 0;
		eqHpf[0].Reset();
		eqHpf[1].Reset();
		eqLpf[0].Reset();
		eqLpf[1].Reset();
		if (reverb)
			reverb->Reset();
		std::fill(std::begin(itdBuf), std::end(itdBuf), 0.0f);
		itdWriteIdx = 0;
		gainsInitialized = false;
		std::fill(std::begin(chGainSmooth), std::end(chGainSmooth), 0.0f);
	}

	void SpatialAudioDspVoice::SetTrackPositionSec(double sec)
	{
		if (totalPcmFrames <= 0)
			return;
		double pos = sec * (double)kAudioSampleRate;
		if (loop)
		{
			pos = std::fmod(pos, (double)totalPcmFrames);
			if (pos < 0.0)
				pos += (double)totalPcmFrames;
		}
		else
		{
			pos = std::clamp(pos, 0.0, (double)totalPcmFrames);
		}
		readFramePos = pos;
	}

	double SpatialAudioDspVoice::GetTrackPositionSec() const
	{
		return readFramePos / (double)kAudioSampleRate;
	}

	void SpatialAudioDspVoice::TriggerRelease()
	{
		releasing = true;
	}

	void SpatialAudioDspVoice::RenderAccumulate(float* outBuf, int numFrames, int outChannels, bool planarOut,
												const AudioListenerState& listener, const AudioTrackParams& params)
	{
		if (finished || !outBuf || numFrames <= 0 || totalPcmFrames <= 0 || !pcm)
			return;
		if (outChannels != 2 && outChannels != 6)
			return;

		// Ensure EQ biquads are configured cleanly when mode changes
		int eqMode = std::clamp(params.hpfMode, 0, 3);
		if (eqMode != configuredEqMode)
		{
			configuredEqMode = eqMode;
			for (int c = 0; c < 2; c++)
			{
				eqHpf[c].Reset();
				eqLpf[c].Reset();
				if (eqMode == 1)
					eqHpf[c].SetHighPass(380.0, 0.7071);
				else if (eqMode == 2)
				{
					eqHpf[c].SetHighPass(550.0, 0.8);
					eqLpf[c].SetLowPass(2600.0, 1.35);
				}
				else if (eqMode == 3)
				{
					eqHpf[c].SetHighPass(750.0, 0.9);
					eqLpf[c].SetLowPass(3400.0, 1.85);
				}
			}
		}

		// Spatial geometry computations (constant across this short 512-sample or 21ms block)
		double range = std::max(8.0, params.range);
		double falloffRatio = std::clamp(params.falloff, 0.0, 0.99);
		double minDist = range * falloffRatio;

		AudioVec3 delta = params.pos - listener.pos;
		double dist = delta.Len();
		AudioVec3 dir = (dist > 1e-4) ? (delta * (1.0 / dist)) : listener.forward;

		double azRight = std::clamp(dir.Dot(listener.right) + params.pan * 0.5, -1.0, 1.0);
		double azFront = std::clamp(dir.Dot(listener.forward), -1.0, 1.0);
		double spread = (minDist > 0.01) ? std::clamp(dist / minDist, 0.25, 1.0) : 1.0;

		float distGain = 1.0f;
		if (params.spatial)
		{
			if (dist >= range)
			{
				distGain = 0.0f;
			}
			else if (dist > minDist)
			{
				double t = (dist - minDist) / std::max(1e-4, range - minDist);
				double window = (1.0 - t) * (1.0 - t);
				distGain = (float)(window * (0.45 + 0.55 / (1.0 + 3.0 * t * t)));
			}
		}

		// Target Doppler factor
		double targetDoppler = 1.0;
		if (params.spatial && params.doppler > 0.001)
		{
			AudioVec3 dirSrcToLis = (dist > 1e-4) ? ((listener.pos - params.pos) * (1.0 / dist)) : AudioVec3{ 0.0, 0.0, 0.0 };
			double vRel = (params.vel - listener.vel).Dot(dirSrcToLis);
			constexpr double cSound = 5400.0; // units/s (~337.5 blocks/s)
			double denom = std::clamp(cSound - vRel * params.doppler, 1900.0, 15000.0);
			targetDoppler = std::clamp(cSound / denom, 0.35, 2.85);
		}

		// Low-pass cutoff mapping (manual + spatial air absorption + behind-head pinna cue)
		double muf = std::clamp(params.lpf, 0.0, 0.98);
		if (params.spatial)
		{
			double normDist = std::clamp((dist - minDist) / std::max(1.0, range - minDist), 0.0, 1.0);
			muf += std::clamp(params.distMuffle, 0.0, 1.0) * normDist * 0.72;
			double rearness = std::max(0.0, -azFront);
			muf += rearness * 0.28;
		}
		muf = std::clamp(muf, 0.0, 0.98);
		double lpfCutoffHz = 20000.0 * std::pow(220.0 / 20000.0, muf);
		float lpfAlpha = (float)(1.0 - std::exp(-2.0 * kAudioPi * lpfCutoffHz / (double)kAudioSampleRate));
		float lfeAlpha = (float)(1.0 - std::exp(-2.0 * kAudioPi * 80.0 / (double)kAudioSampleRate));

		// Precompute target channel weights for 3D Positional mode
		float targetChGain[6] = {};
		double delayL = 0.0, delayR = 0.0;
		float rearScale = (params.spatial && azFront < 0.0) ? (float)(1.0 + 0.16 * azFront) : 1.0f;

		if (params.spatial)
		{
			if (outChannels == 2)
			{
				double panVal = std::clamp(azRight * spread * 0.92, -1.0, 1.0);
				double p = 0.5 * (1.0 + panVal);
				targetChGain[0] = (float)(std::cos(p * kAudioPi * 0.5) * 1.35) * rearScale * distGain;
				targetChGain[1] = (float)(std::sin(p * kAudioPi * 0.5) * 1.35) * rearScale * distGain;
				delayL = std::max(0.0, azRight * spread) * 24.0;
				delayR = std::max(0.0, -azRight * spread) * 24.0;
			}
			else // 5.1 Surround: FL=0, FR=1, FC=2, LFE=3, BL=4, BR=5
			{
				double theta = std::atan2(azRight, azFront);
				double deg = theta * (180.0 / kAudioPi);
				double w[6] = {};
				constexpr double halfPi = kAudioPi * 0.5;
				if (deg >= 0.0 && deg < 30.0)
				{
					double t = deg / 30.0;
					w[2] = std::cos(t * halfPi); // FC
					w[1] = std::sin(t * halfPi); // FR
				}
				else if (deg >= 30.0 && deg < 110.0)
				{
					double t = (deg - 30.0) / 80.0;
					w[1] = std::cos(t * halfPi); // FR
					w[5] = std::sin(t * halfPi); // BR
				}
				else if (deg >= 110.0 || deg <= -110.0)
				{
					double t = (deg >= 110.0) ? ((deg - 110.0) / 140.0) : ((deg + 250.0) / 140.0);
					w[5] = std::cos(t * halfPi); // BR
					w[4] = std::sin(t * halfPi); // BL
				}
				else if (deg <= 0.0 && deg > -30.0)
				{
					double t = (-deg) / 30.0;
					w[2] = std::cos(t * halfPi); // FC
					w[0] = std::sin(t * halfPi); // FL
				}
				else // -30 .. -110
				{
					double t = (-deg - 30.0) / 80.0;
					w[0] = std::cos(t * halfPi); // FL
					w[4] = std::sin(t * halfPi); // BL
				}

				static const int spkIndices[5] = { 0, 1, 2, 4, 5 };
				double normSq = 0.0;
				for (int si = 0; si < 5; si++)
				{
					int ch = spkIndices[si];
					w[ch] = spread * w[ch] + (1.0 - spread) * 0.4472135955;
					normSq += w[ch] * w[ch];
				}
				double invNorm = (normSq > 1e-8) ? (1.0 / std::sqrt(normSq)) : 1.0;
				for (int si = 0; si < 5; si++)
				{
					int ch = spkIndices[si];
					targetChGain[ch] = (float)(w[ch] * invNorm) * distGain;
				}
				targetChGain[3] = 0.22f * distGain; // LFE
			}
		}

		// Fade timings adjusted smoothly if overlapping
		double effFadeIn = std::max(0.0, params.fadeIn);
		double effFadeOut = (clipTotalDurSec > 0.0) ? std::max(0.0, params.fadeOut) : 0.0;
		if (clipTotalDurSec > 0.0 && effFadeIn + effFadeOut > clipTotalDurSec)
		{
			double s = clipTotalDurSec / std::max(1e-6, effFadeIn + effFadeOut);
			effFadeIn *= s;
			effFadeOut *= s;
		}

		float hpfMix = (float)std::clamp(params.hpfMix, 0.0, 1.0);
		int revMode = std::clamp(params.reverbMode, 0, 4);
		float revMix = (float)std::clamp(params.reverbMix, 0.0, 1.0);
		float revDecay = (float)std::clamp(params.reverbDecay, 0.0, 1.0);
		bool useReverb = (revMode > 0 && revMix > 0.001f);
		if (useReverb && !reverb)
			reverb = std::make_unique<ReverbState>();

		float dryMixScale = useReverb ? (1.0f - 0.45f * revMix) : 1.0f;
		float wetMixScale = useReverb ? (1.15f * revMix) : 0.0f;
		float masterVol = params.muted ? 0.0f : (float)std::max(0.0, baseVolume);

		const int16_t* raw = pcm->data();
		constexpr double invSampleMax = 1.0 / 32768.0;

		if (!gainsInitialized)
		{
			for (int c = 0; c < outChannels; c++)
				chGainSmooth[c] = params.spatial ? (targetChGain[c] * masterVol) : masterVol;
			gainsInitialized = true;
		}

		auto armRelease = [&]() {
			releasing = true;
			if (!releaseTailArmed)
			{
				releaseTailArmed = true;
				if (useReverb && revMix > 0.002f)
					tailSamplesRemaining = (int)((0.7 + (double)revDecay * 3.2) * (double)kAudioSampleRate);
				else
				{
					tailSamplesRemaining = 0;
					finished = true;
				}
			}
		};

		if (releasing && !releaseTailArmed)
			armRelease();

		for (int i = 0; i < numFrames; i++)
		{
			if (finished)
				break;

			if (!params.spatial)
				dopplerSmooth = 1.0;
			else
				dopplerSmooth += 0.002 * (targetDoppler - dopplerSmooth);

			float srcL = 0.0f;
			float srcR = 0.0f;

			if (!releasing)
			{
				if (clipTotalDurSec >= 0.0 && clipElapsedSec >= clipTotalDurSec)
				{
					armRelease();
				}
				else if (!loop && readFramePos >= (double)totalPcmFrames)
				{
					armRelease();
				}
			}

			if (!releasing && totalPcmFrames > 0)
			{
				double pos = readFramePos;
				if (loop)
				{
					pos = std::fmod(pos, (double)totalPcmFrames);
					if (pos < 0.0)
						pos += (double)totalPcmFrames;
				}
				int64_t idx0 = (int64_t)std::floor(pos);
				double frac = pos - (double)idx0;
				int64_t idx1 = idx0 + 1;

				if (idx0 >= 0 && idx0 < totalPcmFrames)
				{
					if (idx1 >= totalPcmFrames)
						idx1 = loop ? 0 : (totalPcmFrames - 1);

					float l0 = (float)((double)raw[idx0 * 2] * invSampleMax);
					float r0 = (float)((double)raw[idx0 * 2 + 1] * invSampleMax);
					float l1 = (float)((double)raw[idx1 * 2] * invSampleMax);
					float r1 = (float)((double)raw[idx1 * 2 + 1] * invSampleMax);
					srcL = l0 + (l1 - l0) * (float)frac;
					srcR = r0 + (r1 - r0) * (float)frac;
				}

				// Fade in & fade out envelope
				double env = 1.0;
				if (effFadeIn > 1e-4 && clipElapsedSec < effFadeIn)
				{
					double ft = std::clamp(clipElapsedSec / effFadeIn, 0.0, 1.0);
					env *= ft * ft * (3.0 - 2.0 * ft);
				}
				if (clipTotalDurSec > 0.0 && effFadeOut > 1e-4)
				{
					double rem = clipTotalDurSec - clipElapsedSec;
					if (rem < effFadeOut)
					{
						double ft = std::clamp(rem / effFadeOut, 0.0, 1.0);
						env *= ft * ft * (3.0 - 2.0 * ft);
					}
				}
				srcL *= (float)env;
				srcR *= (float)env;

				double step = (basePitch > 0.0001) ? std::clamp(basePitch * dopplerSmooth, 0.05, 8.0) : 0.0;
				readFramePos += step;
				clipElapsedSec += 1.0 / (double)kAudioSampleRate;
			}
			else if (releasing)
			{
				if (tailSamplesRemaining <= 0)
				{
					finished = true;
					break;
				}
				tailSamplesRemaining--;
				releaseElapsedSamples++;
			}

			// EQ / Filter stage
			float eqL = srcL;
			float eqR = srcR;
			if (eqMode == 1)
			{
				float wL = eqHpf[0].Process(srcL);
				float wR = eqHpf[1].Process(srcR);
				eqL = srcL + (wL - srcL) * hpfMix;
				eqR = srcR + (wR - srcR) * hpfMix;
			}
			else if (eqMode == 2)
			{
				float wL = std::tanh(eqLpf[0].Process(eqHpf[0].Process(srcL)) * 2.6f) * 0.68f;
				float wR = std::tanh(eqLpf[1].Process(eqHpf[1].Process(srcR)) * 2.6f) * 0.68f;
				eqL = srcL + (wL - srcL) * hpfMix;
				eqR = srcR + (wR - srcR) * hpfMix;
			}
			else if (eqMode == 3)
			{
				float wL = std::tanh(eqLpf[0].Process(eqHpf[0].Process(srcL)) * 3.4f) * 0.65f;
				float wR = std::tanh(eqLpf[1].Process(eqHpf[1].Process(srcR)) * 3.4f) * 0.65f;
				eqL = srcL + (wL - srcL) * hpfMix;
				eqR = srcR + (wR - srcR) * hpfMix;
			}

			// 2-pole LPF (manual muffle + spatial distance absorption + rear pinna cue)
			float filtL = eqL;
			float filtR = eqR;
			if (muf > 0.001)
			{
				lpfZ1[0] += lpfAlpha * (eqL - lpfZ1[0]);
				lpfZ2[0] += lpfAlpha * (lpfZ1[0] - lpfZ2[0]);
				lpfZ1[1] += lpfAlpha * (eqR - lpfZ1[1]);
				lpfZ2[1] += lpfAlpha * (lpfZ1[1] - lpfZ2[1]);
				filtL = lpfZ2[0];
				filtR = lpfZ2[1];
			}
			else
			{
				lpfZ1[0] = filtL; lpfZ2[0] = filtL;
				lpfZ1[1] = filtR; lpfZ2[1] = filtR;
			}

			// Reverb stage
			float wetL = 0.0f;
			float wetR = 0.0f;
			if (useReverb)
			{
				reverb->Process(filtL, filtR, revMode, revDecay, wetL, wetR);
				if (releasing && releaseElapsedSamples > 10000)
				{
					if (std::max(std::abs(wetL), std::abs(wetR)) < 1e-5f)
					{
						if (++silentTailSamples >= 2048)
						{
							finished = true;
							break;
						}
					}
					else
					{
						silentTailSamples = 0;
					}
				}
			}
			else if (releasing)
			{
				finished = true;
				break;
			}

			// Channel routing & spatialization
			float chOut[6] = {};
			if (!params.spatial)
			{
				chGainSmooth[0] += 0.008f * (masterVol - chGainSmooth[0]);
				float g = chGainSmooth[0];

				float dL = filtL * dryMixScale + wetL * wetMixScale;
				float dR = filtR * dryMixScale + wetR * wetMixScale;

				float p = (float)std::clamp(params.pan, -1.0, 1.0);
				float panL = dL;
				float panR = dR;
				if (p < 0.0f)
				{
					float w = -p;
					panL = dL + w * dR * 0.7071f;
					panR = dR * (1.0f - w);
				}
				else if (p > 0.0f)
				{
					float w = p;
					panR = dR + w * dL * 0.7071f;
					panL = dL * (1.0f - w);
				}

				if (outChannels == 2)
				{
					chOut[0] = panL * g;
					chOut[1] = panR * g;
				}
				else // 5.1 global compatibility + surround ambience from wet reverb
				{
					chOut[0] = panL * g;
					chOut[1] = panR * g;
					chOut[4] = wetL * wetMixScale * 0.28f * g;
					chOut[5] = wetR * wetMixScale * 0.28f * g;
				}
			}
			else // 3D Positional mode
			{
				float dryMono = 0.5f * (filtL + filtR) * dryMixScale;

				if (outChannels == 2)
				{
					chGainSmooth[0] += 0.008f * (targetChGain[0] * masterVol - chGainSmooth[0]);
					chGainSmooth[1] += 0.008f * (targetChGain[1] * masterVol - chGainSmooth[1]);

					itdWriteIdx = (itdWriteIdx + 1) % kItdBufSize;
					itdBuf[itdWriteIdx] = dryMono;
					float dDryL = ReadItdFraction(itdBuf, kItdBufSize, itdWriteIdx, delayL);
					float dDryR = ReadItdFraction(itdBuf, kItdBufSize, itdWriteIdx, delayR);

					float spatialWetScale = distGain * wetMixScale * masterVol;
					chOut[0] = dDryL * chGainSmooth[0] + wetL * spatialWetScale;
					chOut[1] = dDryR * chGainSmooth[1] + wetR * spatialWetScale;
				}
				else // 5.1 Surround VBAP
				{
					for (int c = 0; c < 6; c++)
						chGainSmooth[c] += 0.008f * (targetChGain[c] * masterVol - chGainSmooth[c]);

					lfeZ1 += lfeAlpha * (dryMono - lfeZ1);
					lfeZ2 += lfeAlpha * (lfeZ1 - lfeZ2);

					float spatialWetScale = distGain * wetMixScale * masterVol;
					chOut[0] = dryMono * chGainSmooth[0] + wetL * spatialWetScale * 0.75f;
					chOut[1] = dryMono * chGainSmooth[1] + wetR * spatialWetScale * 0.75f;
					chOut[2] = dryMono * chGainSmooth[2];
					chOut[3] = lfeZ2 * chGainSmooth[3];
					chOut[4] = dryMono * chGainSmooth[4] + wetL * spatialWetScale * 0.85f;
					chOut[5] = dryMono * chGainSmooth[5] + wetR * spatialWetScale * 0.85f;
				}
			}

			if (planarOut)
			{
				for (int c = 0; c < outChannels; c++)
					outBuf[c * numFrames + i] += chOut[c];
			}
			else
			{
				int base = i * outChannels;
				for (int c = 0; c < outChannels; c++)
					outBuf[base + c] += chOut[c];
			}
		}
	}

#ifndef SPATIAL_AUDIO_DSP_ONLY
	SpatialAudioEngine& SpatialAudioEngine::Instance()
	{
		static SpatialAudioEngine instance;
		return instance;
	}

	SpatialAudioEngine::~SpatialAudioEngine()
	{
		Shutdown();
	}

	void SpatialAudioEngine::Init()
	{
		std::lock_guard<std::mutex> lock(mtx);
		if (initialized.load())
			return;

		alGenSources(1, &streamSource);
		alGenBuffers(kNumStreamBuffers, streamBuffers);

		alSourcei(streamSource, AL_SOURCE_RELATIVE, AL_TRUE);
		alSource3f(streamSource, AL_POSITION, 0.0f, 0.0f, 0.0f);
		alSource3f(streamSource, AL_VELOCITY, 0.0f, 0.0f, 0.0f);
		alSourcef(streamSource, AL_GAIN, 1.0f);
		alSourcef(streamSource, AL_PITCH, 1.0f);
		alSourcei(streamSource, AL_LOOPING, AL_FALSE);

		mixFloatBuf.assign((size_t)(kBlockFrames * 2), 0.0f);
		mixPcmBuf.assign((size_t)(kBlockFrames * 2), 0);

		for (int i = 0; i < kNumStreamBuffers; i++)
			alBufferData(streamBuffers[i], AL_FORMAT_STEREO16, mixPcmBuf.data(), (ALsizei)(mixPcmBuf.size() * sizeof(int16_t)), kAudioSampleRate);

		alSourceQueueBuffers(streamSource, kNumStreamBuffers, streamBuffers);
		alSourcePlay(streamSource);

		initialized.store(true);
		running.store(true);
		mixerThread = std::thread(&SpatialAudioEngine::MixerThreadLoop, this);
	}

	void SpatialAudioEngine::Shutdown()
	{
		running.store(false);
		if (mixerThread.joinable())
			mixerThread.join();

		std::lock_guard<std::mutex> lock(mtx);
		voices.clear();
		tracks.clear();

		if (!initialized.exchange(false))
			return;

		if (streamSource != 0)
		{
			alSourceStop(streamSource);
			alSourcei(streamSource, AL_BUFFER, 0);
			alDeleteSources(1, &streamSource);
			streamSource = 0;
		}
		alDeleteBuffers(kNumStreamBuffers, streamBuffers);
		for (int i = 0; i < kNumStreamBuffers; i++)
			streamBuffers[i] = 0;
	}

	int64_t SpatialAudioEngine::PlaySound(const void* soundAssetPtr,
										  std::shared_ptr<const std::vector<int16_t>> pcmData,
										  int64_t tlId, int64_t kfId, bool loop,
										  double totalDurSec, double initElapsedSec)
	{
		if (!initialized.load() || !pcmData || pcmData->size() < 2)
			return -1;

		std::lock_guard<std::mutex> lock(mtx);
		auto entry = std::make_unique<VoiceEntry>();
		entry->id = nextVoiceId++;
		if (nextVoiceId < 1)
			nextVoiceId = 1;
		entry->assetPtr = soundAssetPtr;
		entry->tlId = tlId;
		entry->kfId = kfId;
		entry->paused = false;
		entry->dsp.Init(std::move(pcmData), 1.0, 1.0, loop, totalDurSec, initElapsedSec);

		int64_t outId = entry->id;
		voices.push_back(std::move(entry));
		return outId;
	}

	void SpatialAudioEngine::StopSound(int64_t voiceId)
	{
		if (voiceId <= 0)
			return;
		std::lock_guard<std::mutex> lock(mtx);
		voices.erase(std::remove_if(voices.begin(), voices.end(), [voiceId](const auto& v) {
			return v->id == voiceId;
		}), voices.end());
	}

	void SpatialAudioEngine::ReleaseSound(int64_t voiceId)
	{
		if (voiceId <= 0)
			return;
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
		{
			if (v->id == voiceId)
			{
				v->dsp.TriggerRelease();
				break;
			}
		}
	}

	void SpatialAudioEngine::StopAll()
	{
		std::lock_guard<std::mutex> lock(mtx);
		voices.clear();
	}

	void SpatialAudioEngine::StopBySoundAsset(const void* soundAssetPtr)
	{
		if (!soundAssetPtr)
			return;
		std::lock_guard<std::mutex> lock(mtx);
		voices.erase(std::remove_if(voices.begin(), voices.end(), [soundAssetPtr](const auto& v) {
			return v->assetPtr == soundAssetPtr;
		}), voices.end());
	}

	void SpatialAudioEngine::PauseSound(int64_t voiceId)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
			if (v->id == voiceId) { v->paused = true; break; }
	}

	void SpatialAudioEngine::ResumeSound(int64_t voiceId)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
			if (v->id == voiceId) { v->paused = false; break; }
	}

	bool SpatialAudioEngine::IsPlaying(int64_t voiceId)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (const auto& v : voices)
			if (v->id == voiceId) return !v->dsp.IsFinished();
		return false;
	}

	bool SpatialAudioEngine::IsPaused(int64_t voiceId)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (const auto& v : voices)
			if (v->id == voiceId) return v->paused;
		return false;
	}

	void SpatialAudioEngine::SetGain(int64_t voiceId, double volume)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
			if (v->id == voiceId) { v->dsp.SetVolume(volume); break; }
	}

	void SpatialAudioEngine::SetPitch(int64_t voiceId, double pitch)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
			if (v->id == voiceId) { v->dsp.SetPitch(pitch); break; }
	}

	void SpatialAudioEngine::SetTrackPos(int64_t voiceId, double sec)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (auto& v : voices)
			if (v->id == voiceId) { v->dsp.SetTrackPositionSec(sec); break; }
	}

	double SpatialAudioEngine::GetTrackPos(int64_t voiceId)
	{
		std::lock_guard<std::mutex> lock(mtx);
		for (const auto& v : voices)
			if (v->id == voiceId) return v->dsp.GetTrackPositionSec();
		return 0.0;
	}

	void SpatialAudioEngine::UpdateSceneState(const AudioListenerState& newListener,
											  std::unordered_map<int64_t, AudioTrackParams> newTracks)
	{
		std::lock_guard<std::mutex> lock(mtx);
		listener = newListener;
		tracks = std::move(newTracks);
	}

	void SpatialAudioEngine::FillBuffer(uint32_t alBufId)
	{
		std::fill(mixFloatBuf.begin(), mixFloatBuf.end(), 0.0f);

		{
			std::lock_guard<std::mutex> lock(mtx);
			AudioTrackParams defaultParams;
			for (auto& v : voices)
			{
				if (v->paused || v->dsp.IsFinished())
					continue;

				const AudioTrackParams* p = &defaultParams;
				if (v->tlId >= 0)
				{
					auto it = tracks.find(v->tlId);
					if (it != tracks.end())
						p = &it->second;
				}
				v->dsp.RenderAccumulate(mixFloatBuf.data(), kBlockFrames, 2, false, listener, *p);
			}

			voices.erase(std::remove_if(voices.begin(), voices.end(), [](const auto& v) {
				return v->dsp.IsFinished();
			}), voices.end());
		}

		for (size_t i = 0; i < mixFloatBuf.size(); i++)
		{
			float s = FastTanhSoftLimit(mixFloatBuf[i]);
			int scaled = (int)std::lrintf(s * 32767.0f);
			mixPcmBuf[i] = (int16_t)std::clamp(scaled, -32768, 32767);
		}

		alBufferData((ALuint)alBufId, AL_FORMAT_STEREO16, mixPcmBuf.data(),
					 (ALsizei)(mixPcmBuf.size() * sizeof(int16_t)), kAudioSampleRate);
	}

	void SpatialAudioEngine::MixerThreadLoop()
	{
		while (running.load())
		{
			ALint processed = 0;
			alGetSourcei(streamSource, AL_BUFFERS_PROCESSED, &processed);

			while (processed > 0)
			{
				ALuint bufId = 0;
				alSourceUnqueueBuffers(streamSource, 1, &bufId);
				FillBuffer(bufId);
				alSourceQueueBuffers(streamSource, 1, &bufId);
				processed--;
			}

			ALint state = 0;
			alGetSourcei(streamSource, AL_SOURCE_STATE, &state);
			if (state != AL_PLAYING)
			{
				ALint queued = 0;
				alGetSourcei(streamSource, AL_BUFFERS_QUEUED, &queued);
				if (queued > 0)
					alSourcePlay(streamSource);
			}

			std::this_thread::sleep_for(std::chrono::milliseconds(4));
		}
	}
#endif
}
