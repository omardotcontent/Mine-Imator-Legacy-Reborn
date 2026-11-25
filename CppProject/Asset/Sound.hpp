#pragma once
#include "Asset.hpp"

#include <QBuffer>
#include <QIODevice>
#include <memory>
#include <vector>

struct AVFrame;

namespace CppProject
{
	struct Sound : Asset
	{
		Sound(StringType filename);
		~Sound();

		QBuffer buffer;
		ALuint alBuffer = 0;
		IntType samples = 0;
		std::shared_ptr<std::vector<int16_t>> pcmData;
	};

	struct SoundInstance : Asset
	{
		SoundInstance(Sound* sound, BoolType loop);
		~SoundInstance();

		Sound* sound = nullptr;
		ALuint alSource = 0;
		BoolType paused = false;

		// Clean sounds that have finished playing.
		static void CleanSounds();

		static QVector<SoundInstance*> sounds;
	};
}