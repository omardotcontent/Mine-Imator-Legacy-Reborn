#include "Sprite.hpp"

#include "Render/Texture.hpp"
#include "Render/TexturePage.hpp"
#include "Shader.hpp"
#include "Surface.hpp"

#include <QFileInfo>
#include <QHash>
#include <cmath>

extern "C"
{
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libswscale/swscale.h>
}

namespace CppProject
{
	extern double GetVideoTimelineSeconds();
	extern void NotifyVideoTextureUpdated();

	struct VideoSpriteStream
	{
		AVFormatContext* fmtCtx = nullptr;
		AVCodecContext* codecCtx = nullptr;
		SwsContext* swsCtx = nullptr;
		AVFrame* frame = nullptr;
		AVFrame* lastFrame = nullptr;
		AVPacket* pkt = nullptr;
		int streamIndex = -1;
		int width = 0;
		int height = 0;
		double timeBase = 1.0 / 30.0;
		double fps = 30.0;
		double durationSec = 0.0;
		double currentSec = -1.0;
		double lastRequestedSec = -1.0;

		~VideoSpriteStream()
		{
			if (swsCtx) sws_freeContext(swsCtx);
			if (frame) av_frame_free(&frame);
			if (lastFrame) av_frame_free(&lastFrame);
			if (pkt) av_packet_free(&pkt);
			if (codecCtx) avcodec_free_context(&codecCtx);
			if (fmtCtx) avformat_close_input(&fmtCtx);
		}

		bool Open(const QString& path, QImage& outFirstImage)
		{
			if (avformat_open_input(&fmtCtx, path.toUtf8().constData(), nullptr, nullptr) < 0)
				return false;
			if (avformat_find_stream_info(fmtCtx, nullptr) < 0)
				return false;

			const AVCodec* codec = nullptr;
			for (unsigned int i = 0; i < fmtCtx->nb_streams; i++)
			{
				if (fmtCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO)
				{
					streamIndex = (int)i;
					codec = avcodec_find_decoder(fmtCtx->streams[i]->codecpar->codec_id);
					break;
				}
			}
			if (streamIndex < 0 || !codec)
				return false;

			AVStream* st = fmtCtx->streams[streamIndex];
			codecCtx = avcodec_alloc_context3(codec);
			if (!codecCtx)
				return false;
			if (avcodec_parameters_to_context(codecCtx, st->codecpar) < 0)
				return false;
			if (avcodec_open2(codecCtx, codec, nullptr) < 0)
				return false;

			width = codecCtx->width;
			height = codecCtx->height;
			if (width <= 0 || height <= 0)
				return false;

			timeBase = av_q2d(st->time_base);
			if (st->avg_frame_rate.den > 0 && st->avg_frame_rate.num > 0)
				fps = av_q2d(st->avg_frame_rate);
			else if (st->r_frame_rate.den > 0 && st->r_frame_rate.num > 0)
				fps = av_q2d(st->r_frame_rate);
			if (fps <= 0.1 || fps > 240.0)
				fps = 30.0;

			if (st->duration > 0 && timeBase > 0.0)
				durationSec = st->duration * timeBase;
			else if (fmtCtx->duration > 0)
				durationSec = (double)fmtCtx->duration / (double)AV_TIME_BASE;

			frame = av_frame_alloc();
			lastFrame = av_frame_alloc();
			pkt = av_packet_alloc();
			if (!frame || !lastFrame || !pkt)
				return false;
			outFirstImage = QImage(width, height, QImage::Format_RGBA8888);
			outFirstImage.fill(Qt::black);

			if (!DecodeToTime(0.0, outFirstImage))
				return false;
			return true;
		}

		bool DecodeToTime(double targetSec, QImage& img)
		{
			if (!fmtCtx || !codecCtx || !frame || !lastFrame || !pkt)
				return false;

			if (durationSec > 0.05)
				targetSec = std::fmod(std::max(0.0, targetSec), durationSec);
			else
				targetSec = std::max(0.0, targetSec);

			// Instant O(1) pause: if timeline time hasn't changed since last decode, do zero work
			if (lastRequestedSec >= 0.0 && std::abs(targetSec - lastRequestedSec) < 0.0005)
				return false;
			lastRequestedSec = targetSec;

			double frameStep = 1.0 / std::max(1.0, fps);
			if (currentSec >= 0.0 && std::abs(targetSec - currentSec) < frameStep * 0.45)
				return false;

			// Seek if going backwards or jumping more than 0.75s ahead
			if (currentSec < 0.0 || targetSec < currentSec - 0.04 || targetSec > currentSec + 0.75)
			{
				int64_t seekTs = (timeBase > 0.0) ? (int64_t)(targetSec / timeBase) : 0;
				av_seek_frame(fmtCtx, streamIndex, std::max<int64_t>(0, seekTs), AVSEEK_FLAG_BACKWARD);
				avcodec_flush_buffers(codecCtx);
				currentSec = -1.0;
			}

			bool gotFrame = false;
			int safetyPackets = 0;
			while (safetyPackets++ < 180)
			{
				int ret = avcodec_receive_frame(codecCtx, frame);
				if (ret == 0)
				{
					int64_t pts = (frame->best_effort_timestamp != AV_NOPTS_VALUE) ? frame->best_effort_timestamp : frame->pts;
					double ptsSec = (pts != AV_NOPTS_VALUE && timeBase > 0.0) ? (pts * timeBase) : (currentSec < 0.0 ? 0.0 : currentSec + frameStep);
					currentSec = ptsSec;
					av_frame_unref(lastFrame);
					av_frame_move_ref(lastFrame, frame);
					gotFrame = true;
					if (ptsSec >= targetSec - frameStep * 0.5)
						break;
				}
				else
				{
					if (av_read_frame(fmtCtx, pkt) < 0)
					{
						// EOF: loop back to start if we didn't get a frame yet
						if (!gotFrame)
						{
							av_seek_frame(fmtCtx, streamIndex, 0, AVSEEK_FLAG_BACKWARD);
							avcodec_flush_buffers(codecCtx);
							if (av_read_frame(fmtCtx, pkt) < 0)
								break;
						}
						else
							break;
					}
					if (pkt->stream_index == streamIndex)
						avcodec_send_packet(codecCtx, pkt);
					av_packet_unref(pkt);
				}
			}

			if (gotFrame && lastFrame->data[0] != nullptr && lastFrame->width > 0 && lastFrame->height > 0 && lastFrame->format != AV_PIX_FMT_NONE)
			{
				if (img.isNull() || img.width() != width || img.height() != height || img.format() != QImage::Format_RGBA8888)
					img = QImage(width, height, QImage::Format_RGBA8888);

				swsCtx = sws_getCachedContext(swsCtx, lastFrame->width, lastFrame->height, (AVPixelFormat)lastFrame->format,
					width, height, AV_PIX_FMT_RGBA, SWS_BILINEAR, nullptr, nullptr, nullptr);
				if (!swsCtx)
					return false;

				uint8_t* dstData[4] = { img.bits(), nullptr, nullptr, nullptr };
				int dstLinesize[4] = { (int)img.bytesPerLine(), 0, 0, 0 };
				sws_scale(swsCtx, lastFrame->data, lastFrame->linesize, 0, lastFrame->height, dstData, dstLinesize);
				return true;
			}
			return false;
		}
	};

	static QHash<Sprite*, VideoSpriteStream*> g_videoSprites;
	static QHash<Sprite::Frame*, BoolType> g_videoFrames;

	bool HasActiveVideoSprites()
	{
		return !g_videoSprites.isEmpty();
	}
	QVector<Sprite*> Sprite::allSprites;

	Sprite::Sprite(Sprite* other) : Asset(ID_Sprite)
	{
		allSprites.append(this);
		size = other->size;
		origin = other->origin;
		
		for (Frame* frame : other->frames)
		{
			QImage copy;
			if (frame->pageLoc)
				copy = frame->pageLoc->page->image.copy(frame->pageLoc->rect);
			else
				copy = frame->image.copy();

			
			frames.append(new Frame(copy, false));
		}
	}

	Sprite::Sprite(QString name, IntType subAssetId, int numFrames, QPoint origin) : Asset(ID_Sprite, subAssetId, name)
	{
		allSprites.append(this);
		this->origin = origin;

		for (int f = 0; f < numFrames; f++)
		{
			const QString path = ":/Sprites/" + name + "_frame_" + NumStr(f) + ".png";
			QImage image(path);
			if (image.isNull())
				FATAL("Could not load built-in sprite: " + path);
			image.convertTo(QImage::Format_RGBA8888);
			size = image.size();
			frames.append(new Frame(image, true));
		}
	}

	Sprite::Sprite(const StringType& filename, QPoint origin) : Asset(ID_Sprite)
	{
		allSprites.append(this);
		this->origin = origin;

		QString qfn = filename;
		QString ext = QFileInfo(qfn).suffix().toLower();
		bool isVideoExt = (ext == "mp4" || ext == "webm" || ext == "mov" || ext == "avi" || ext == "mkv" || ext == "m4v" || ext == "gif");

		QImage image;
		bool loadedAsVideo = false;
		if (isVideoExt)
		{
			VideoSpriteStream* stream = new VideoSpriteStream();
			if (stream->Open(qfn, image) && (ext != "gif" || stream->durationSec > 0.05))
			{
				useTexturePage = false;
				g_videoSprites[this] = stream;
				loadedAsVideo = true;
			}
			else
				delete stream;
		}

		if (!loadedAsVideo)
		{
			image = QImage(qfn);
			image.convertTo(QImage::Format_RGBA8888);
		}

		size = image.size();
		Frame* frm = new Frame(image, false);
		if (loadedAsVideo)
			g_videoFrames[frm] = true;
		frames.append(frm);
	}

	Sprite::Sprite(Surface* surface, QPoint origin) : Asset(ID_Sprite)
	{
		allSprites.append(this);
		useTexturePage = false;
		this->origin = origin;
		size = surface->size;

		frames.append(new Frame(surface->ToImage(), false));
	}
	
	Sprite::Sprite(Surface* surface, QRect rect, QPoint origin) : Asset(ID_Sprite)
	{
		allSprites.append(this);
		useTexturePage = false;
		this->origin = origin;
		size = surface->size;

		frames.append(new Frame(surface->ToImage().copy(rect), false));
	}

	Sprite::~Sprite()
	{
		allSprites.removeOne(this);
		if (g_videoSprites.contains(this))
		{
			delete g_videoSprites[this];
			g_videoSprites.remove(this);
		}

		for (Frame* frame : frames)
		{
			g_videoFrames.remove(frame);
			delete frame;
		}
	}

	IntType Sprite::GetTexture(IntType index)
	{
		if (index >= frames.size())
			return -1;

		if (index < 0)
			index = 0;

		if (g_videoSprites.contains(this) && !frames.isEmpty())
		{
			VideoSpriteStream* stream = g_videoSprites[this];
			Frame* frm = frames[0];
			double tSec = GetVideoTimelineSeconds();
			if (stream->DecodeToTime(tSec, frm->image))
			{
				deleteAndReset(frm->texture);
				NotifyVideoTextureUpdated();
			}
		}

		return frames[index]->GetTexture();
	}

	QColor Sprite::GetPixel(IntType index, QPoint point) const
	{
		if (index < 0 || index >= frames.size())
			return Qt::transparent;

		Frame* frame = frames[index];
		if (frame->pageLoc) // Pixel from texture page
			return frame->pageLoc->page->image.pixelColor(frame->pageLoc->rect.topLeft() + point);
		else // Pixel from image
			return frame->image.pixelColor(point);
	}

	Sprite::Frame::Frame(QImage image, bool toPage) : image(image)
	{
		if (toPage)
		{
			// Check if image is supported for a texture page
			if (pageLoc = TexturePage::Add(image))
				this->image = QImage();
		}
	}

	Sprite::Frame::~Frame()
	{
		g_videoFrames.remove(this);
		deleteAndReset(texture);
		deleteAndReset(pageLoc);
	}

	IntType Sprite::Frame::GetTexture()
	{
		// Get texture page location ID or texture ID from QImage
		if (pageLoc)
			return pageLoc->id;

		else if (!image.isNull())
		{
			if (!texture)
				texture = new Texture(image);
			return texture->GetId();
		}

		return -1;
	}

	bool Sprite::Frame::MoveToTexturePage()
	{
		if (pageLoc || g_videoFrames.contains(this)) // Already on texture page or dynamic video texture
			return false;

		if (pageLoc = TexturePage::Add(image))
		{
			deleteAndReset(texture);
			image = QImage(); // Free image
		}

		return true;
	}
}
