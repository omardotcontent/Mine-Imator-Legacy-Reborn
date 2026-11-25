#include "Generated/Scripts.hpp"

#include "Asset/Sound.hpp"
#include "Asset/SpatialAudio.hpp"
#include "AppHandler.hpp"

namespace CppProject
{
	IntType audio_create_buffer_sound(IntType bufferId, IntType bufferFormat, IntType bufferRate, IntType bufferOffset, IntType bufferLength, IntType bufferChannels)
	{
		// Unused
		return 0;
	}

	void audio_free_buffer_sound(IntType index)
	{
		if (Sound* sound = FindSound(index))
		{
			SpatialAudioEngine::Instance().StopBySoundAsset(sound);
			auto sounds = SoundInstance::sounds;
			for (SoundInstance* inst : sounds)
				if (inst->sound == sound)
					delete inst;

			delete sound;
		}
	}

	BoolType audio_is_paused(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
		{
			if (SpatialAudioEngine::Instance().IsPlaying(index))
				return SpatialAudioEngine::Instance().IsPaused(index);
		}
		if (SoundInstance* instance = FindSoundInstance(index))
			return instance->paused;
		return false;
	}

	BoolType audio_is_playing(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
		{
			if (SpatialAudioEngine::Instance().IsPlaying(index))
				return true;
		}
		return (FindSoundInstance(index));
	}

	void audio_pause_sound(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().PauseSound(index);
		if (SoundInstance* instance = FindSoundInstance(index))
		{
			instance->paused = true;
			alSourcei(instance->alSource, AL_SOURCE_STATE, AL_PAUSED);
		}
	}

	IntType audio_play_sound_tl(IntType index, IntType tlId, IntType kfId, BoolType loop, RealType totalDurSec, RealType initElapsedSec)
	{
		if (App->audioSupported)
		{
			if (Sound* sound = FindSound(index))
			{
				if (SpatialAudioEngine::Instance().IsInitialized() && sound->pcmData)
					return (IntType)SpatialAudioEngine::Instance().PlaySound(sound, sound->pcmData, (int64_t)tlId, (int64_t)kfId, loop, (double)totalDurSec, (double)initElapsedSec);
				return (new SoundInstance(sound, loop))->id;
			}
		}
		return -1;
	}

	IntType audio_play_sound(IntType index, IntType priority, BoolType loop)
	{
		return audio_play_sound_tl(index, null_, null_, loop, -1.0, 0.0);
	}

	void audio_resume_sound(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().ResumeSound(index);
		if (SoundInstance* instance = FindSoundInstance(index))
		{
			instance->paused = false;
			alSourcei(instance->alSource, AL_SOURCE_STATE, AL_PLAYING);
		}
	}

	void audio_sound_gain(IntType index, RealType volume, RealType time)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().SetGain(index, (double)volume);
		if (SoundInstance* instance = FindSoundInstance(index))
			alSourcef(instance->alSource, AL_GAIN, volume);
	}

	RealType audio_sound_get_track_position(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
		{
			if (SpatialAudioEngine::Instance().IsPlaying(index))
				return (RealType)SpatialAudioEngine::Instance().GetTrackPos(index);
		}
		if (SoundInstance* instance = FindSoundInstance(index))
		{
			ALfloat secs;
			alGetSourcef(instance->alSource, AL_SEC_OFFSET, &secs);
			return secs;
		}
		return 0;
	}

	void audio_sound_pitch(IntType index, RealType pitch)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().SetPitch(index, (double)pitch);
		if (SoundInstance* instance = FindSoundInstance(index))
			alSourcef(instance->alSource, AL_PITCH, pitch);
	}

	void audio_sound_set_track_position(IntType index, RealType time)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().SetTrackPos(index, (double)time);
		if (SoundInstance* instance = FindSoundInstance(index))
			alSourcef(instance->alSource, AL_SEC_OFFSET, time);
	}

	void audio_stop_all()
	{
		if (SpatialAudioEngine::Instance().IsInitialized())
			SpatialAudioEngine::Instance().StopAll();
		auto sounds = SoundInstance::sounds;
		for (SoundInstance* sound : sounds)
			delete sound;
	}

	void audio_stop_sound(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().StopSound(index);
		if (SoundInstance* sound = FindSoundInstance(index))
			delete sound;
	}

	void audio_release_sound(IntType index)
	{
		if (SpatialAudioEngine::Instance().IsInitialized() && index > 0)
			SpatialAudioEngine::Instance().ReleaseSound(index);
		if (SoundInstance* sound = FindSoundInstance(index))
			delete sound;
	}

	void res_load_audio(ScopeAny self)
	{
		obj_resource* res = ObjType(obj_resource, self->id);
		StringType fname = global::load_folder + "/" + res->filename;
		IntType prec = sample_rate_ / sample_avg_per_sec;

		if (res->sound_index)
			delete FindSound(res->sound_index);

		res->sound_index = null_;
		res->sound_samples = 0;

		if (!file_exists_lib(fname))
		{
			load_next(ScopeAny(global::_app->id));
			return;
		}

		// Decode file
		Sound* snd = new Sound(fname);
		if (!snd->buffer.size())
		{
			error("errorloadaudio");
			load_next(ScopeAny(global::_app->id));
			delete snd;
			return;
		}

		res->sound_index = snd->id;
		res->sound_samples = snd->samples;

		// Find max/min samples
		IntType maxMinSize = (IntType)res->sound_samples / prec;
		res->sound_max_sample = ArrType();
		res->sound_min_sample = ArrType();
		res->sound_max_sample.vec.Resize(maxMinSize + 1);
		res->sound_min_sample.vec.Resize(maxMinSize + 1);
		const int16_t* data = (int16_t*)snd->buffer.data().constData();

		#pragma OPENMP_FOR
		for (IntType s = 0; s < maxMinSize; s++)
		{
			int16_t maxVal = 0, minVal = 0;
			for (IntType s2 = 0; s2 < prec; s2++)
			{
				IntType offset = s * prec + s2;
				int16_t ch1 = data[offset * 2];
				int16_t ch2 = data[offset * 2 + 1];
				maxVal = std::max(maxVal, std::max(ch1, ch2));
				minVal = std::min(minVal, std::min(ch1, ch2));
			}
			res->sound_max_sample.vec[s] = (RealType)maxVal / sample_max;
			res->sound_min_sample.vec[s] = (RealType)minVal / sample_max;
		}

		res->ready = true;
		tl_update_length();
		load_next(ScopeAny(global::_app->id));
	}
}