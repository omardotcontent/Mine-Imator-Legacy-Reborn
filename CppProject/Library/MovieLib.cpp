#include "Generated/Scripts.hpp"

#include "Asset/Sound.hpp"
#include "Asset/SpatialAudio.hpp"
#include "Asset/Surface.hpp"
#include "AppHandler.hpp"

#include <QHash>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <vector>

extern "C"
{
	#include <libavutil/opt.h>
	#include <libavutil/mathematics.h>
	#include <libavutil/channel_layout.h>
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libswscale/swscale.h>
	#include <libswresample/swresample.h>
}

#define INPUT_PIXEL_FORMAT					AV_PIX_FMT_RGBA
#define STREAM_VIDEO_PIXEL_FORMAT			AV_PIX_FMT_YUV420P

#define STREAM_AUDIO_BIT_RATE				320000
#define STREAM_AUDIO_SAMPLE_RATE			44100
#define STREAM_AUDIO_FRAME_SIZE				1152
#define STREAM_AUDIO_SAMPLE_FORMAT			AV_SAMPLE_FMT_S16
#define STREAM_AUDIO_SAMPLE_FORMAT_MOVIE	AV_SAMPLE_FMT_FLTP
#define STREAM_AUDIO_CHANNEL_LAYOUT			AV_CH_LAYOUT_STEREO
#define STREAM_AUDIO_CHANNELS				2

namespace CppProject
{
	// Media file output
	AVFormatContext* outContext;

	// Video
	IntType videoWidth, videoHeight, videoBitRate, videoFrameRate;
	AVStream* videoStream;
	AVCodecContext* videoCodecContext;
	IntType videoFrameNum;
	SwsContext* videoSwsContext;
	uchar* videoFrameData = nullptr;

	// Audio
	BoolType audioEnabled;
	AVStream* audioStream;
	AVCodec* audioCodec;
	AVCodecContext* audioCodecContext;
	AVRational audioTimeBase;
	IntType audioFrameNum;
	int exportAudioChannels = 2;
	bool exportLisPrevValid = false;
	AudioVec3 exportLisPrevPos{ 0.0, 0.0, 0.0 };
	QHash<IntType, AudioVec3> exportTrackPrevPos;
	std::vector<float> exportMixBuf;

	extern BoolType g_export_movie_surround;
	extern void tl_ext_fill_audio_params(IntType tlId, AudioTrackParams& out, const AudioVec3& vel, bool isExport);

	// Movie sound
	struct MovieSound
	{
		Sound* sound = nullptr;
		IntType tlId = null_;
		IntType kfId = null_;
		int64_t playStartSample = 0;
		double startSec = 0.0;
		double endSec = 0.0;
		double totalDurSec = -1.0;
		double initElapsedSec = 0.0;
		RealType volume = 1.0;
		RealType pitch = 1.0;
		bool voiceInitialized = false;
		SpatialAudioDspVoice dspVoice;
	};
	QVector<MovieSound*> movieSounds;

	RealType lib_movie_init()
	{
		// Do nothing
		return 0;
	}

	RealType lib_movie_audio_file_decode(StringType, StringType)
	{
		// Unused
		return 0;
	}

	Sound::Sound(StringType filename) : Asset(ID_Sound)
	{
		AVFormatContext* formatContext = nullptr;
		const AVCodec* codec = nullptr;
		AVCodecContext* codecContext = nullptr;
		SwrContext* swrContext = nullptr;
		AVFrame* decodedFrame = nullptr;
		uint8_t* convertedData = nullptr;
		AVPacket* inPacket = nullptr;

		// Decode file into buffer
		buffer.open(QIODevice::WriteOnly);
		QDataStream outStream(&buffer);

		try
		{
			Timer tmr;
			std::string filenameStd = filename.ToStdString();

			// Get format from audio file
			formatContext = avformat_alloc_context();
			if (avformat_open_input(&formatContext, filenameStd.c_str(), nullptr, nullptr) != 0)
				throw "avformat_open_input failed";

			if (avformat_find_stream_info(formatContext, nullptr) < 0)
				throw "avformat_find_stream_info failed";

			codecContext = avcodec_alloc_context3(nullptr);
			for (IntType i = 0; i < formatContext->nb_streams; i++)
			{
				AVCodecParameters* par = formatContext->streams[i]->codecpar;
				if (par->codec_type == AVMEDIA_TYPE_AUDIO)
				{
					codec = avcodec_find_decoder(par->codec_id);
					if (!codec)
						throw "avcodec_find_decoder failed";
					if (avcodec_parameters_to_context(codecContext, par) < 0)
						throw "avcodec_parameters_to_context failed";
					break;
				}
			}

			if (!codec)
				throw "No codec found";

			// Open codec of the audio file
			if (avcodec_open2(codecContext, codec, nullptr) < 0)
				throw "avcodec_open2 failed";

			// Prepare resampling
		#if LIBAVUTIL_VERSION_MAJOR >= 59
			AVChannelLayout outChLayout;
			av_channel_layout_default(&outChLayout, STREAM_AUDIO_CHANNELS);
			if (codecContext->ch_layout.order == AV_CHANNEL_ORDER_UNSPEC)
				av_channel_layout_default(&codecContext->ch_layout, codecContext->ch_layout.nb_channels > 0 ? codecContext->ch_layout.nb_channels : 2);
			if (swr_alloc_set_opts2(&swrContext, &outChLayout, STREAM_AUDIO_SAMPLE_FORMAT, STREAM_AUDIO_SAMPLE_RATE,
				&codecContext->ch_layout, codecContext->sample_fmt, codecContext->sample_rate, 0, nullptr) < 0 || !swrContext)
				throw "swr_alloc failed";
		#else
			swrContext = swr_alloc();
			if (!swrContext)
				throw "swr_alloc failed";

			av_opt_set_int(swrContext, "in_channel_count", codecContext->channels, 0);
			av_opt_set_int(swrContext, "in_channel_layout", codecContext->channel_layout, 0);
			av_opt_set_int(swrContext, "in_sample_rate", codecContext->sample_rate, 0);
			av_opt_set_sample_fmt(swrContext, "in_sample_fmt", codecContext->sample_fmt, 0);

			av_opt_set_int(swrContext, "out_channel_count", STREAM_AUDIO_CHANNELS, 0);
			av_opt_set_int(swrContext, "out_channel_layout", STREAM_AUDIO_CHANNEL_LAYOUT, 0);
			av_opt_set_int(swrContext, "out_sample_rate", STREAM_AUDIO_SAMPLE_RATE, 0);
			av_opt_set_sample_fmt(swrContext, "out_sample_fmt", STREAM_AUDIO_SAMPLE_FORMAT, 0);
		#endif

			if (swr_init(swrContext))
				throw "swr_init failed";

			// Create packet
			inPacket = av_packet_alloc();
			if (!inPacket)
				throw "av_packet_alloc failed";

			// Prepare to read data
			decodedFrame = av_frame_alloc();
			if (!decodedFrame)
				throw "av_packet_alloc failed";

			// Read frames and store the decoded buffer in the resample context
			IntType inSamples = 0;
			while (av_read_frame(formatContext, inPacket) >= 0)
			{
				if (avcodec_send_packet(codecContext, inPacket) < 0 ||
					avcodec_receive_frame(codecContext, decodedFrame) < 0)
				{
					av_frame_unref(decodedFrame);
					av_packet_unref(inPacket);
					continue;
				}

				swr_convert(swrContext, nullptr, 0, (const uint8_t**)decodedFrame->data, decodedFrame->nb_samples);
				inSamples += decodedFrame->nb_samples;
			}

			// Allocate data
			if (av_samples_alloc(&convertedData, nullptr, STREAM_AUDIO_CHANNELS, STREAM_AUDIO_FRAME_SIZE, STREAM_AUDIO_SAMPLE_FORMAT, 0) < 0)
				throw "av_samples_alloc failed";

			// Read from the resample context buffer and convert
			RealType rateDiv = codecContext->sample_rate / (RealType)STREAM_AUDIO_SAMPLE_RATE;
			IntType totalSamples = (IntType)(inSamples / rateDiv);
			while (samples < totalSamples)
			{
				// Convert
				IntType outSamples = swr_convert(swrContext, &convertedData, STREAM_AUDIO_FRAME_SIZE, nullptr, 0);
				if (outSamples == 0)
					break;
				else if (outSamples < 0)
					throw "swr_convert failed";
				samples += outSamples;

				// Calculate buffer size
				IntType bufferSize = av_samples_get_buffer_size(nullptr, STREAM_AUDIO_CHANNELS, outSamples, STREAM_AUDIO_SAMPLE_FORMAT, 0);
				if (bufferSize < 0)
					throw "av_samples_get_buffer_size failed";

				outStream.writeRawData((const char*)convertedData, bufferSize);
			}

			tmr.Print("Decoded " + (QString)filename + " into " + NumStr(samples) + " samples");

			const QByteArray& rawBytes = buffer.data();
			if (!rawBytes.isEmpty())
			{
				size_t sampleCount16 = (size_t)rawBytes.size() / sizeof(int16_t);
				pcmData = std::make_shared<std::vector<int16_t>>(sampleCount16);
				std::memcpy(pcmData->data(), rawBytes.constData(), sampleCount16 * sizeof(int16_t));
			}

			// Create OpenAL buffer
			if (App->audioSupported)
			{
				alGenBuffers(1, &alBuffer);
				alBufferData(alBuffer, AL_FORMAT_STEREO16, buffer.data().constData(), buffer.size(), sample_rate_);
			}

			buffer.close();
		}
		catch (const char* err)
		{
			log({ err });
			WARNING(err);
			samples = 0;
			buffer.close();
			buffer.buffer().clear();
		}

		// Cleanup
		if (decodedFrame)
			av_frame_free(&decodedFrame);
		if (swrContext)
			swr_free(&swrContext);
		if (codecContext)
		#if LIBAVCODEC_VERSION_MAJOR >= 61
			avcodec_free_context(&codecContext);
		#else
			avcodec_close(codecContext);
		#endif
		if (formatContext)
		{
			avformat_close_input(&formatContext);
			avformat_free_context(formatContext);
		}
		if (convertedData)
			av_freep(&convertedData);
		if (inPacket)
			av_packet_free(&inPacket);
	}

	Sound::~Sound()
	{
		SpatialAudioEngine::Instance().StopBySoundAsset(this);
		if (alBuffer)
			alDeleteBuffers(1, &alBuffer);
	}

	RealType lib_movie_set(RealType width, RealType height, RealType bitRate, RealType frameRate, RealType audio)
	{
		videoWidth = width;
		videoHeight = height;
		videoBitRate = bitRate;
		videoFrameRate = frameRate;
		audioEnabled = audio > 0.0;
		return 0;
	}

	RealType lib_movie_start(StringType outFile, StringType outFormat)
	{
		std::string outFileStd = outFile.ToStdString();
		std::string outFormatStd = outFormat.ToStdString();
		
		try
		{
			// Find format
			const AVOutputFormat* outFmt = av_guess_format(outFormatStd.c_str(), 0, 0);
			if (!outFmt)
				throw "av_guess_format failed";

			// Allocate the output media context
			avformat_alloc_output_context2(&outContext, const_cast<AVOutputFormat*>(outFmt), 0, 0);
			if (!outContext)
				throw "avformat_alloc_output_context2 failed";

			// Find video encoder (prefer high-quality libx264 for MP4/MOV, libvpx for WebM)
			const AVCodec* videoCodec = nullptr;
			if (outFormatStd == "mp4" || outFormatStd == "mov")
			{
				videoCodec = avcodec_find_encoder_by_name("libx264");
				if (!videoCodec)
					videoCodec = avcodec_find_encoder(AV_CODEC_ID_H264);
			}
			else if (outFormatStd == "webm")
			{
				videoCodec = avcodec_find_encoder_by_name("libvpx-vp9");
				if (!videoCodec)
					videoCodec = avcodec_find_encoder_by_name("libvpx");
			}
			if (!videoCodec)
				videoCodec = avcodec_find_encoder(outContext->oformat->video_codec);
			if (!videoCodec)
				throw "avcodec_find_encoder failed";

			if (outFormatStd == "gif" || outContext->oformat->audio_codec == AV_CODEC_ID_NONE)
				audioEnabled = false;

			AVPixelFormat streamPixFmt = STREAM_VIDEO_PIXEL_FORMAT;
		#if LIBAVCODEC_VERSION_MAJOR >= 62
			const AVPixelFormat* supportedPixFmts = nullptr;
			int numSupportedPixFmts = 0;
			if (avcodec_get_supported_config(nullptr, videoCodec, AV_CODEC_CONFIG_PIX_FORMAT, 0,
				(const void**)&supportedPixFmts, &numSupportedPixFmts) >= 0 && supportedPixFmts && numSupportedPixFmts > 0)
			{
				bool hasYuv420p = false;
				for (int p = 0; p < numSupportedPixFmts; p++)
				{
					if (supportedPixFmts[p] == AV_PIX_FMT_YUV420P)
					{
						hasYuv420p = true;
						break;
					}
				}
				if (!hasYuv420p)
					streamPixFmt = supportedPixFmts[0];
			}
		#else
			if (videoCodec->pix_fmts)
			{
				bool hasYuv420p = false;
				for (int p = 0; videoCodec->pix_fmts[p] != AV_PIX_FMT_NONE; p++)
				{
					if (videoCodec->pix_fmts[p] == AV_PIX_FMT_YUV420P)
					{
						hasYuv420p = true;
						break;
					}
				}
				if (!hasYuv420p)
					streamPixFmt = videoCodec->pix_fmts[0];
			}
		#endif

			DEBUG("Encoder: " + QString(videoCodec->long_name));

			// Start video stream
			videoStream = avformat_new_stream(outContext, videoCodec);
			if (!videoStream)
				throw "avformat_new_stream failed";

			videoStream->id = 0;
			videoStream->codecpar->width = videoWidth;
			videoStream->codecpar->height = videoHeight;
			videoStream->codecpar->codec_id = videoCodec->id;
			videoStream->codecpar->codec_type = videoCodec->type;
			videoStream->avg_frame_rate = { (int)videoFrameRate, 1 };
			
			// Setup context
			videoCodecContext = avcodec_alloc_context3(videoCodec);
			videoCodecContext->bit_rate = videoBitRate * 5;
			videoCodecContext->width = videoWidth;
			videoCodecContext->height = videoHeight;
			videoCodecContext->time_base = { 1, (int)videoFrameRate };
			videoCodecContext->framerate = { (int)videoFrameRate, 1 };
			videoCodecContext->pix_fmt = streamPixFmt;
			videoCodecContext->gop_size = (outFormatStd == "gif") ? 1 : 24;
			if (outContext->oformat->flags & AVFMT_GLOBALHEADER)
				videoCodecContext->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;

			// Open the codec
			AVDictionary* opt = NULL;
			if (videoCodec->id == AV_CODEC_ID_H264)
			{
				av_dict_set(&opt, "preset", "fast", 0);
				int crf = (videoBitRate >= 5000000) ? 16 : ((videoBitRate >= 2500000) ? 18 : ((videoBitRate >= 1200000) ? 21 : 24));
				av_dict_set_int(&opt, "crf", crf, 0);
			}
			else
				av_dict_set(&opt, "tune", "zerolatency", 0);
			if (avcodec_open2(videoCodecContext, videoCodec, &opt) < 0)
				throw "avcodec_open2 failed";

			videoFrameNum = 0;
			avcodec_parameters_from_context(videoStream->codecpar, videoCodecContext);

			// Scaling context
			videoSwsContext = sws_getContext(videoWidth, videoHeight, INPUT_PIXEL_FORMAT,
											 videoWidth, videoHeight, streamPixFmt,
											 SWS_BILINEAR, nullptr, nullptr, nullptr);
			if (!videoSwsContext)
				throw "sws_getContext failed";

			deleteArrayAndReset(videoFrameData);
			videoFrameData = new uchar[videoWidth * videoHeight * 4];

			for (MovieSound* snd : movieSounds)
				delete snd;
			movieSounds.clear();
			exportLisPrevValid = false;
			exportTrackPrevPos.clear();
			exportAudioChannels = 2;

			if (audioEnabled)
			{
				// Find audio encoder
				const AVCodec* audioCodec = avcodec_find_encoder(outContext->oformat->audio_codec);
				if (!audioCodec)
					throw "avcodec_find_encoder failed";

				// Start audio stream
				audioStream = avformat_new_stream(outContext, audioCodec);
				if (!audioStream)
					throw "avformat_new_stream failed";
				audioStream->id = 1;
				audioStream->codecpar->sample_rate = STREAM_AUDIO_SAMPLE_RATE;
				audioStream->codecpar->frame_size = STREAM_AUDIO_FRAME_SIZE;
				audioStream->codecpar->codec_id = audioCodec->id;
				audioStream->codecpar->codec_type = audioCodec->type;

				auto tryOpenAudioCodec = [&](int channels, uint64_t chMask) -> AVCodecContext* {
					AVCodecContext* ctx = avcodec_alloc_context3(audioCodec);
					if (!ctx)
						return nullptr;
					ctx->sample_fmt = STREAM_AUDIO_SAMPLE_FORMAT_MOVIE;
					ctx->sample_rate = STREAM_AUDIO_SAMPLE_RATE;
					ctx->bit_rate = (channels == 6) ? 512000 : STREAM_AUDIO_BIT_RATE;
				#if LIBAVUTIL_VERSION_MAJOR >= 59
					if (av_channel_layout_from_mask(&ctx->ch_layout, chMask) < 0)
						av_channel_layout_default(&ctx->ch_layout, channels);
				#else
					ctx->channels = channels;
					ctx->channel_layout = chMask;
				#endif
					if (outContext->oformat->flags & AVFMT_GLOBALHEADER)
						ctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
					if (avcodec_open2(ctx, audioCodec, nullptr) < 0)
					{
						avcodec_free_context(&ctx);
						return nullptr;
					}
					return ctx;
				};

				audioCodecContext = nullptr;
				if (g_export_movie_surround)
				{
					audioCodecContext = tryOpenAudioCodec(6, AV_CH_LAYOUT_5POINT1);
					if (!audioCodecContext)
						audioCodecContext = tryOpenAudioCodec(6, AV_CH_LAYOUT_5POINT1_BACK);
					if (audioCodecContext)
					{
						exportAudioChannels = 6;
					}
					else
					{
						log({ StringType("5.1 surround not supported by audio encoder, falling back to stereo.") });
					}
				}
				if (!audioCodecContext)
				{
					exportAudioChannels = 2;
					audioCodecContext = tryOpenAudioCodec(2, AV_CH_LAYOUT_STEREO);
					if (!audioCodecContext)
						throw "avcodec_open2 failed";
				}

				int frameSamples = (audioCodecContext->frame_size > 0) ? audioCodecContext->frame_size : STREAM_AUDIO_FRAME_SIZE;
				audioFrameNum = 0;
				audioTimeBase = { frameSamples, STREAM_AUDIO_SAMPLE_RATE };
				avcodec_parameters_from_context(audioStream->codecpar, audioCodecContext);
			}

			// Open the output file
			if (avio_open(&outContext->pb, outFileStd.c_str(), AVIO_FLAG_WRITE) < 0)
				throw "avio_open failed";

			// Write the stream header, if any
			if (avformat_write_header(outContext, nullptr) < 0)
				throw "avformat_write_header failed";

			return 0;
		}
		catch (const char* err)
		{
			log({ err });
			WARNING(err);
			return -1;
		}
	}

	RealType lib_movie_audio_file_add(StringType)
	{
		if (Sound* sound = FindSound(global::_app->exportmovie_current_sound))
			return sound->id;

		return -1;
	}

	RealType movie_audio_sound_add_tl(IntType tlId, IntType kfId, VarType file, RealType play, VarType volume, VarType pitch, VarType start, VarType ed, RealType totalDurSec, RealType initElapsedSec)
	{
		if (!audioEnabled)
			return 0.0;

		Sound* snd = FindSound((RealType)file);
		if (!snd)
			return 0.0;

		auto* ms = new MovieSound();
		ms->sound = snd;
		ms->tlId = tlId;
		ms->kfId = kfId;
		ms->playStartSample = (int64_t)std::llround(std::max(0.0, (double)play) * (double)STREAM_AUDIO_SAMPLE_RATE);
		ms->startSec = (double)start;
		ms->endSec = (double)ed;
		ms->totalDurSec = (double)totalDurSec;
		ms->initElapsedSec = (double)initElapsedSec;
		ms->volume = (RealType)volume;
		ms->pitch = (RealType)pitch;
		ms->voiceInitialized = false;
		movieSounds.append(ms);
		return 0.0;
	}

	RealType lib_movie_audio_sound_add(RealType id, RealType time, RealType volume, RealType pitch, RealType start, RealType end)
	{
		return movie_audio_sound_add_tl(null_, null_, id, time, volume, pitch, start, end, -1.0, 0.0);
	}

	void Encode(AVCodecContext* context, AVFrame* frame, AVStream* stream)
	{
		AVPacket* packet = av_packet_alloc();
		if (!packet)
			throw "av_packet_alloc failed";

		// Send in a frame, a nullptr will enable flush mode
		if (avcodec_send_frame(context, frame) < 0)
			throw "avcodec_send_frame failed";

		// Encode a submitted video or audio frame to the stream
		while (true)
		{
			switch (avcodec_receive_packet(context, packet))
			{
				case 0:
				{
					av_packet_rescale_ts(packet, context->time_base, stream->time_base);
					packet->stream_index = stream->index;

					if (av_interleaved_write_frame(outContext, packet) < 0)
						throw "av_interleaved_write_frame failed";
					break;
				}
				case AVERROR(EAGAIN):
				case AVERROR_EOF:
					av_packet_free(&packet);
					return;

				default:
					throw "avcodec_receive_packet failed";
			}
		}

		av_packet_free(&packet);
	}

	RealType lib_movie_frame(StringType)
	{
		try
		{
			// Allocate and init frame
			AVFrame* videoFrame = av_frame_alloc();
			if (!videoFrame)
				throw "av_frame_alloc failed";

			videoFrame->pts = videoFrameNum++;
			videoFrame->format = videoCodecContext->pix_fmt;
			videoFrame->width = videoCodecContext->width;
			videoFrame->height = videoCodecContext->height;

			if (av_frame_get_buffer(videoFrame, 0) < 0)
				throw "av_frame_get_buffer failed";

			// Convert surface into frame
			FindSurface(global::_app->export_surface)->frameBuffer->CopyColorData(videoFrameData);
			uint8_t* inData[1] = { videoFrameData }; // RGBA have one plane
			int inLinesize[1] = { 4 * (int)videoWidth }; // RGBA stride
			sws_scale(videoSwsContext, inData, inLinesize, 0, videoHeight, videoFrame->data, videoFrame->linesize);
			
			// Submit frame and encode
			Encode(videoCodecContext, videoFrame, videoStream);

			// Cleanup video
			av_frame_free(&videoFrame);

			// Build current frame spatial audio snapshot (listener & audio tracks) before encoding audio blocks
			AudioListenerState exportListener;
			std::unordered_map<int64_t, AudioTrackParams> exportTrackMap;
			if (audioEnabled)
			{
				double frameDt = 1.0 / std::max(1.0, (double)videoFrameRate);
				AudioVec3 lisFrom{ (double)global::cam_from.Real(X_), (double)global::cam_from.Real(Y_), (double)global::cam_from.Real(Z_) };
				AudioVec3 lisTo{ (double)global::cam_to.Real(X_), (double)global::cam_to.Real(Y_), (double)global::cam_to.Real(Z_) };
				AudioVec3 lisUp{ (double)global::cam_up.Real(X_), (double)global::cam_up.Real(Y_), (double)global::cam_up.Real(Z_) };
				AudioVec3 lisVel{ 0.0, 0.0, 0.0 };
				if (exportLisPrevValid && frameDt > 1e-4 && (lisFrom - exportLisPrevPos).Len() < 2000.0)
					lisVel = (lisFrom - exportLisPrevPos) * (1.0 / frameDt);
				exportLisPrevPos = lisFrom;
				exportLisPrevValid = true;
				exportListener = AudioListenerState::FromCamera(lisFrom, lisTo, lisUp, lisVel);

				if (global::_app && ds_list_valid(global::_app->project_timeline_list))
				{
					for (IntType i = 0; i < ds_list_size(global::_app->project_timeline_list); i++)
					{
						IntType tlId = (IntType)DsList(global::_app->project_timeline_list).Value(i);
						if (!instance_exists(tlId))
							continue;
						obj_timeline* tlObj = ObjType(obj_timeline, tlId);
						if (!tlObj || tlObj->type != e_tl_type_AUDIO)
							continue;
						AudioVec3 curPos{ (double)tlObj->world_pos.Value(X_), (double)tlObj->world_pos.Value(Y_), (double)tlObj->world_pos.Value(Z_) };
						AudioVec3 vel{ 0.0, 0.0, 0.0 };
						if (exportTrackPrevPos.contains(tlId) && frameDt > 1e-4 && (curPos - exportTrackPrevPos[tlId]).Len() < 2000.0)
							vel = (curPos - exportTrackPrevPos[tlId]) * (1.0 / frameDt);
						exportTrackPrevPos[tlId] = curPos;

						AudioTrackParams tp;
						tl_ext_fill_audio_params(tlId, tp, vel, true);
						exportTrackMap[(int64_t)tlId] = tp;
					}
				}
			}

			// Write interleaved audio
			while (audioEnabled && av_compare_ts(videoFrameNum, videoCodecContext->time_base, audioFrameNum, audioTimeBase) > 0)
			{
				int frameSamples = (audioCodecContext->frame_size > 0) ? audioCodecContext->frame_size : STREAM_AUDIO_FRAME_SIZE;
				int outChannels = (exportAudioChannels == 6) ? 6 : 2;

				// Allocate frame
				AVFrame* audioFrame = av_frame_alloc();
				if (!audioFrame)
					throw "av_frame_alloc failed";

				audioFrame->nb_samples = frameSamples;
				audioFrame->format = audioCodecContext->sample_fmt;
			#if LIBAVUTIL_VERSION_MAJOR >= 59
				av_channel_layout_copy(&audioFrame->ch_layout, &audioCodecContext->ch_layout);
			#else
				audioFrame->channel_layout = audioCodecContext->channel_layout;
				audioFrame->channels = audioCodecContext->channels;
			#endif
				audioFrame->sample_rate = STREAM_AUDIO_SAMPLE_RATE;

				if (av_frame_get_buffer(audioFrame, 0) < 0)
					throw "av_frame_get_buffer failed";

				if (av_frame_make_writable(audioFrame) < 0)
					throw "av_frame_make_writable failed";

				exportMixBuf.assign((size_t)(frameSamples * outChannels), 0.0f);
				int64_t frameStartSample = (int64_t)audioFrameNum * (int64_t)frameSamples;
				int64_t frameEndSample = frameStartSample + (int64_t)frameSamples;
				AudioTrackParams defaultTrackParams;

				for (MovieSound* sound : movieSounds)
				{
					if (!sound->sound || !sound->sound->pcmData || sound->sound->pcmData->size() < 2)
						continue;
					if (frameEndSample <= sound->playStartSample)
						continue;

					if (!sound->voiceInitialized)
					{
						double srcDurSec = (double)sound->sound->samples / (double)STREAM_AUDIO_SAMPLE_RATE;
						double playPitch = std::max(0.01, (double)sound->pitch);
						double playDur = srcDurSec / playPitch;
						double trackPos = (playDur > 1e-6) ? std::fmod(sound->startSec, playDur) * playPitch : 0.0;
						sound->dspVoice.Init(sound->sound->pcmData, (double)sound->volume, (double)sound->pitch,
											 (sound->endSec > 0.0), sound->totalDurSec, sound->initElapsedSec);
						sound->dspVoice.SetTrackPositionSec(trackPos);
						sound->voiceInitialized = true;
					}

					if (sound->dspVoice.IsFinished())
						continue;

					int offsetInFrame = (int)std::max<int64_t>(0, sound->playStartSample - frameStartSample);
					int countToRender = frameSamples - offsetInFrame;
					if (countToRender <= 0)
						continue;

					const AudioTrackParams* tp = &defaultTrackParams;
					if (sound->tlId >= 0)
					{
						auto it = exportTrackMap.find((int64_t)sound->tlId);
						if (it != exportTrackMap.end())
							tp = &it->second;
					}
					sound->dspVoice.RenderAccumulate(exportMixBuf.data() + offsetInFrame * outChannels,
													 countToRender, outChannels, false, exportListener, *tp);
				}

				bool isPlanar = av_sample_fmt_is_planar(audioCodecContext->sample_fmt) > 0;
				if (isPlanar)
				{
					for (int c = 0; c < outChannels; c++)
					{
						float* dstData = (float*)audioFrame->data[c];
						for (int s = 0; s < frameSamples; s++)
						{
							float x = exportMixBuf[s * outChannels + c];
							float ax = std::abs(x);
							if (ax > 0.90f)
								x = ((x < 0.0f) ? -1.0f : 1.0f) * (0.90f + 0.10f * std::tanh((ax - 0.90f) * 3.5f));
							dstData[s] = std::clamp(x, -1.0f, 1.0f);
						}
					}
				}
				else
				{
					float* dstData = (float*)audioFrame->data[0];
					for (int i = 0; i < frameSamples * outChannels; i++)
					{
						float x = exportMixBuf[i];
						float ax = std::abs(x);
						if (ax > 0.90f)
							x = ((x < 0.0f) ? -1.0f : 1.0f) * (0.90f + 0.10f * std::tanh((ax - 0.90f) * 3.5f));
						dstData[i] = std::clamp(x, -1.0f, 1.0f);
					}
				}

				audioFrame->pts = av_rescale_q(audioFrameNum++, audioTimeBase, audioCodecContext->time_base);

				// Submit frame and encode
				Encode(audioCodecContext, audioFrame, audioStream);

				// Cleanup audio
				av_frame_free(&audioFrame);
			}

			return 0;
		}
		catch (const char* err)
		{
			log({ err });
			WARNING(err);
			return -1;
		}
	}

	RealType lib_movie_done()
	{
		try
		{
			// Flush video & audio
			Encode(videoCodecContext, nullptr, videoStream);
			if (audioEnabled)
				Encode(audioCodecContext, nullptr, audioStream);

			// Write the trailer
			if (av_write_trailer(outContext) < 0)
				throw "av_write_trailer failed";

			// Close video
			sws_freeContext(videoSwsContext);
		#if LIBAVCODEC_VERSION_MAJOR >= 61
			avcodec_free_context(&videoCodecContext);
		#else
			avcodec_close(videoCodecContext);
		#endif

			// Close audio
			if (audioEnabled)
			{
			#if LIBAVCODEC_VERSION_MAJOR >= 61
				avcodec_free_context(&audioCodecContext);
			#else
				avcodec_close(audioCodecContext);
			#endif

				for (MovieSound* snd : movieSounds)
					delete snd;
				movieSounds.clear();
			}

			// Close the output file.
			if (avio_close(outContext->pb) < 0)
				throw "avio_close failed";

			// Free the stream
			avformat_free_context(outContext);

			deleteArrayAndReset(videoFrameData);

			return 0;
		}
		catch (const char* err)
		{
			log({ err });
			WARNING(err);
			return -1;
		}
	}

}