#include "AppHandler.hpp"
#include "AppWindow.hpp"

#include "Asset/Font.hpp"
#include "Asset/Shader.hpp"
#include "Asset/Sound.hpp"
#include "Asset/Surface.hpp"
#include "ErrorDialog.hpp"
#include "Generated/Scripts.hpp"
#include "Render/GLWidget.hpp"
#include "Render/GraphicsApiHandler.hpp"
#include "Render/PrimitiveRenderer.hpp"
#include "Render/TexturePage.hpp"
#include "Render/VertexBufferRenderer.hpp"

#include <QDesktopWidget>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QNetworkInterface>
#include <QStyle>
#include <QTimer>
#include <QStandardPaths>

#ifdef OS_WINDOWS
#include <shobjidl.h>
#define USE_GPU 1
typedef unsigned long DWORD;
extern "C" __declspec(dllexport) DWORD NvOptimusEnablement = USE_GPU;
extern "C" __declspec(dllexport) DWORD AmdPowerXpressRequestHighPerformance = USE_GPU;
#endif

int main(int argc, char* argv[])
{
	return (new CppProject::AppHandler(argc, argv))->Run();
}

namespace CppProject
{
	AppHandler* AppHandler::handler = nullptr;
	Random::ThreadData Random::threadData[OPENMP_MAX_THREADS];
	IntType Printer::indent = 0;

	AppHandler::AppHandler(int& argc, char* argv[])
	{
		try
		{
			// Disable DPI scaling
			QCoreApplication::setAttribute(Qt::AA_DisableHighDpiScaling);

			// Create graphics API handler
			new GraphicsApiHandler;

			// Create application
			handler = this;
			new QApplication(argc, argv);
			QCoreApplication::setApplicationName(APP_STORAGE_NAME);
			QApplication::setApplicationDisplayName(APP_DISPLAY_NAME);
			QApplication::setDesktopFileName("mine-imator-legacy-reborn");
		#if OS_WINDOWS
			SetCurrentProcessExplicitAppUserModelID(L"OmarDotContent.MineImator.LegacyReborn");
			checkStartup = QCoreApplication::arguments().contains("--check-startup");
		#endif

			// Initialize string table
			StringType::AddQThread(QThread::currentThread());
			StringType::AddGMLStrings();

			// Set paths
			QDir().mkpath(user_directory_get());
			QDir().mkpath(projects_directory_get());
			file_delete_lib(log_file);

		#if RELEASE_MODE
			gmlGlobal::working_directory = QCoreApplication::applicationDirPath() + "/";
		#else
			gmlGlobal::working_directory = QDir::currentPath() + "/";
			DEBUG("Debug mode enabled");
		#endif
			DEBUG("Mine-imator version " + mineimator_version_full + " (" + mineimator_version_date + ")");
		#if OS_WINDOWS
			BOOL is64Bit;
			IsWow64Process((HANDLE)qApp->applicationPid(), &is64Bit);
			DEBUG("Platform: Windows " + QString(is64Bit ? "x64" : "x86"));
		#ifdef _WIN64
			DEBUG("Executable: 64-bit");
		#else
			DEBUG("Executable: 32-bit");
		#endif
		#elif OS_MAC
			DEBUG("Platform: MacOS");
		#else
			DEBUG("Platform: Linux");
		#endif
			DEBUG("OS: " + os_get());
			DEBUG("working_directory: " + gmlGlobal::working_directory);
			DEBUG("user_directory: " + user_directory_get());
			DEBUG("DPI: " + NumStr(qApp->desktop()->logicalDpiX()));
			omp_set_num_threads(std::min(omp_get_max_threads(), OPENMP_MAX_THREADS));
			DEBUG("OpenMP max threads: " + NumStr(omp_get_max_threads()));

			// Create temporary folder
		#if OS_WINDOWS
			gmlGlobal::game_save_id = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation)[0] + "/";
		#else
			gmlGlobal::game_save_id = QDir::tempPath() + "/" + StringType(APP_STORAGE_NAME) + "_tmp/";
		#endif
			if (QDir(gmlGlobal::game_save_id).exists())
				DEBUG("Found temporary folder " + gmlGlobal::game_save_id);
			else if (QDir().mkdir(gmlGlobal::game_save_id))
				DEBUG("Created temporary folder " + gmlGlobal::game_save_id);
			else
				FATAL("Could not create temporary folder " + gmlGlobal::game_save_id);

			DEBUG("Minecraft saves: " + world_import_get_saves_dir());

			// Set globals
			gmlGlobal::room_speed = 60;
			gmlGlobal::delta_time = 1.0;
			gmlGlobal::GM_runtime_version = "NA";
			gmlGlobal::async_load = ds_map_create();
			fpsLastUpdate = QDateTime::currentDateTime();
			startTime = QDateTime::currentDateTime().toMSecsSinceEpoch();
			randomize();

			// Map cursors
			cursorMap[cr_none] = Qt::BlankCursor;
			cursorMap[cr_default] = Qt::ArrowCursor;
			cursorMap[cr_beam] = Qt::IBeamCursor;
			cursorMap[cr_drag] = Qt::ClosedHandCursor;
			cursorMap[cr_size_nesw] = Qt::SizeBDiagCursor;
			cursorMap[cr_size_ns] = Qt::SizeVerCursor;
			cursorMap[cr_size_nwse] = Qt::SizeFDiagCursor;
			cursorMap[cr_size_we] = Qt::SizeHorCursor;
			cursorMap[cr_size_all] = Qt::SizeAllCursor;
			cursorMap[cr_handpoint] = Qt::PointingHandCursor;

			// Map Qt/GML key codes
			keyMap[Qt::Key_Alt] = vk_alt;
			keyMap[Qt::Key_Control] = vk_control;
			keyMap[Qt::Key_Shift] = vk_shift;
			keyMap[Qt::Key_Backspace] = vk_backspace;
			keyMap[Qt::Key_Delete] = vk_delete;
			keyMap[Qt::Key_Down] = vk_down;
			keyMap[Qt::Key_End] = vk_end;
			keyMap[Qt::Key_Return] = keyMap[Qt::Key_Enter] = vk_enter;
			keyMap[Qt::Key_Escape] = vk_escape;
			keyMap[Qt::Key_F1] = vk_f1;
			keyMap[Qt::Key_F2] = vk_f2;
			keyMap[Qt::Key_F3] = vk_f3;
			keyMap[Qt::Key_F4] = vk_f4;
			keyMap[Qt::Key_F5] = vk_f5;
			keyMap[Qt::Key_F6] = vk_f6;
			keyMap[Qt::Key_F7] = vk_f7;
			keyMap[Qt::Key_F8] = vk_f8;
			keyMap[Qt::Key_F9] = vk_f9;
			keyMap[Qt::Key_F10] = vk_f10;
			keyMap[Qt::Key_F11] = vk_f11;
			keyMap[Qt::Key_F12] = vk_f12;
			keyMap[Qt::Key_Home] = vk_home;
			keyMap[Qt::Key_Insert] = vk_insert;
			keyMap[Qt::Key_Left] = vk_left;
			keyMap[Qt::Key_multiply] = vk_multiply;
			keyMap[Qt::Key_PageDown] = vk_pagedown;
			keyMap[Qt::Key_PageUp] = vk_pageup;
			keyMap[Qt::Key_Pause] = vk_pause;
			keyMap[Qt::Key_Print] = vk_printscreen;
			keyMap[Qt::Key_Right] = vk_right;
			keyMap[Qt::Key_Space] = vk_space;
			keyMap[Qt::Key_Tab] = vk_tab;
			keyMap[Qt::Key_Backtab] = vk_tab;
			keyMap[Qt::Key_Up] = vk_up;
			for (int k = Qt::Key_A; k <= Qt::Key_Z; k++)
				keyMap[k] = k;
			for (int k = Qt::Key_0; k <= Qt::Key_9; k++)
				keyMap[k] = k;

		#if API_D3D11
			// Initialize Direct3D graphics
			GFX->Init();
			if (checkStartup)
			{
				bool valid = !Shader::allShaders.isEmpty();
				for (const Shader* shader : Shader::allShaders)
					if (!shader->IsLoaded())
					{
						WARNING("Shader check failed: " + shader->name);
						valid = false;
					}
				if (!valid)
				{
					startupCheckResult = 1;
					return;
				}
			}
		#endif

			// Initialize audio
			try
			{
				DEBUG("Initialize OpenAL");
				openALDevice = alcOpenDevice(nullptr);
				if (!openALDevice)
					throw QString("alcOpenDevice failed");

				openALContext = alcCreateContext(openALDevice, nullptr);
				if (!openALContext)
					throw QString("alcCreateContext failed");

				if (!alcMakeContextCurrent(openALContext))
					throw QString("alcMakeContextCurrent failed");

				DEBUG("Audio is supported");
				audioSupported = true;
			}
			catch (const QString& err)
			{
				DEBUG("Audio not supported: " + err);
				audioSupported = false;
			}

			// Create main window
			AddWindow();

		}
		catch (const QString& ex)
		{
			if (checkStartup)
			{
				startupCheckResult = 1;
				return;
			}
			new ErrorDialog(ex);
			qApp->exit(1);
		}
	}

	AppHandler::~AppHandler()
	{
		StringType::qThreadActive = false;

		if (audioSupported)
		{
			alcMakeContextCurrent(nullptr);
			alcDestroyContext(openALContext);
			alcCloseDevice(openALDevice);
		}
	}

	int AppHandler::Run()
	{
		if (startupCheckResult >= 0)
			return startupCheckResult;
		return qApp->exec();
	}

	void AppHandler::LoadResources()
	{
		if (prRenderer)
			return;

		DEBUG("Load resources");

		// Create renderers
		prRenderer = new PrimitiveRenderer;
		vbRenderer = new VertexBufferRenderer;

		// First texture page
		new TexturePage;

		// Load sprites and shaders into memory
		Shader::Init();
		Asset::Load();

		// GPU settings
		gpu_set_blendenable(true);
		gpu_set_blendmode(bm_normal);
		gpu_set_ztestenable(false);
		gpu_set_zwriteenable(false);
		gpu_set_cullmode(cull_counterclockwise);

		DEBUG("Resources loaded");

		// Start application loop
		stepTimer.start(10, this);
	}

	AppWindow* AppHandler::AddWindow(QRect rect, IntType id, AppWindow* from)
	{
		// Create main window
		AppWindow* win = new AppWindow(id);
		mouseWindow = win;
		windows.append(win);

		// Set as main
		if (!mainWindow)
			mainWindow = win;

		if (rect == QRect()) // Show minimized if no rect given
			win->showMinimized();
		
		else if (from) // Show relative to a window
		{
			win->setGeometry(from->x() + rect.x(), from->y() + rect.y() + QApplication::style()->pixelMetric(QStyle::PM_TitleBarHeight) + 4, rect.width(), rect.height());
			win->ShowNormal();
		}
		else
		{
			win->setGeometry(rect);
			win->ShowNormal();
		}

		win->UpdateSize();
		return win;
	}

	void AppHandler::timerEvent(QTimerEvent* event)
	{
		stepTimer.stop();
		
		// True frame-to-frame delta_time in microseconds
		double frameElapsedMs = frameTimer.ElapsedMs();
		if (frameElapsedMs > 0.0 && frameElapsedMs < 5000.0)
			gmlGlobal::delta_time = std::max(100.0, frameElapsedMs * 1000.0);
		else
			gmlGlobal::delta_time = 1000000.0 / 60.0;
		frameTimer.Reset();
		fpsTimer.Reset();

		// Debug
		if (keyboard_check_pressed(vk_f6) && dev_mode)
		{
			move_all_to_texture_page();
			TexturePage::Debug();
		}

		// Loop through opened windows
		bool drewStartScreen = false;
		for (AppWindow* win : windows)
		{
			if (win->closing)
				continue;

			currentWindow = win;

			// Set mouse to widget window
			if (mouseWindow == win)
			{
				if (AppWin->mouseLocked)
				{
					QPoint winPos = AppWin->mouseLockWinPos + (AppWin->mousePos - AppWin->mouseLastPos) / scale;
					gmlGlobal::mouse_x = winPos.x();
					gmlGlobal::mouse_y = winPos.y();
				}
				else
				{
					gmlGlobal::mouse_x = win->mousePos.x() / scale;
					gmlGlobal::mouse_y = win->mousePos.y() / scale;
				}
			}
			else
				gmlGlobal::mouse_x = gmlGlobal::mouse_y = -1;
			
			if (!GFX->StartOffScreenRender())
				continue;
			GFX->surface = win->GetSurface();
			GFX->surface->BeginUse(win->size());

			GFX->ClearDepth();
			GFX->shader = PR->GetShader();
			GFX->shader->BeginUse();
			
			// Run application
			try
			{
				// Start
				if (!global::_app)
				{
					new app;
					app_event_create(global::_app->id);
				}

				app_event_step(global::_app->id);
				drewStartScreen = checkStartup && global::_app->window_state == "startup";
				app_event_draw(global::_app->id);
			}
			catch (AppEndRequest)
			{
				DEBUG("App end requested");
				if (checkStartup)
				{
					qApp->exit(1);
					return;
				}
			
				GFX->shader->EndUse();
				if (GFX->surface)
					GFX->surface->EndUse();
				mainWindow->closing = true;
				mainWindow->close();
				return;
			}
			catch (const QString& ex)
			{
				if (checkStartup)
				{
					qApp->exit(1);
					return;
				}
				new ErrorDialog(ex);
				qApp->exit(1);
			}

			GFX->SubmitBatch();
			GFX->shader->EndUse();
			if (GFX->surface)
				GFX->surface->EndUse();

			win->mouseWheel = 0;
			win->mouseLastPos = win->mousePos;
			if (win->mouseUnlock)
				win->mouseLocked = win->mouseUnlock = false;

			win->Present();
			win->UpdateSize();
		}

		VB->EndFrame();
		if (drewStartScreen)
		{
			DEBUG("Startup check passed");
			qApp->exit(0);
			return;
		}
		currentWindow = mainWindow;
		blocked = false;

		// Reset pressed & release key states
		for (IntType key : keyStateMap.keys())
			keyStateMap[key].pressed = keyStateMap[key].released = false;
		for (IntType key : keyWinStateMap.keys())
			keyWinStateMap[key].pressed = keyWinStateMap[key].released = false;
		keyStateMap[vk_nokey].pressed = keyStateMap[vk_nokey].released = true;

		// Add new window(s)
		if (global::_app->window_state == "")
		{
			for (const AddedWindow& addWin : addedWindows)
			{
				AppWindow* win = AddWindow(addWin.rect, addWin.id, addWin.from);
				if (addWin.maximize)
					win->Maximize();
			}
			addedWindows.clear();
		}

		// Track work time and update rolling FPS every 500ms
		double workMs = fpsTimer.ElapsedMs();
		fpsWorkMsAccum += workMs;
		fpsFrameCount++;
		
		QDateTime now = QDateTime::currentDateTime();
		qint64 sinceLastMs = fpsLastUpdate.msecsTo(now);
		if (sinceLastMs >= 500)
		{
			double sec = sinceLastMs / 1000.0;
			gmlGlobal::fps = std::max(IntType(1), (IntType)std::llround(fpsFrameCount / std::max(0.001, sec)));
			double avgWorkMs = fpsWorkMsAccum / std::max(IntType(1), fpsFrameCount);
			gmlGlobal::fps_real = (avgWorkMs > 0.01) ? (IntType)std::llround(1000.0 / avgWorkMs) : IntType(9999);
			
			fpsFrameCount = 0;
			fpsWorkMsAccum = 0.0;
			fpsLastUpdate = now;

			// Clean unused data
			VecType::CleanHeapData();
			Font::CleanUnused();
			Mesh<>::CleanBuffers();
			StringType::GetCurrentQThreadData()->mainTable.Clean();

			// Reload shader when debugging
			Shader::CheckReload();
		}

		// Delete finished sounds
		SoundInstance::CleanSounds();

		// Schedule next step using dynamic FPS cap / unlimited / unfocused throttle
		bool unlimited = false;
		double targetFps = std::max(15.0, (double)gmlGlobal::room_speed);
		if (global::_app)
		{
			bool exporting = (global::_app->window_state == "export_movie" || global::_app->window_state == "export_image");
			bool unfocused = (QApplication::activeWindow() == nullptr);
			
			if (exporting)
				unlimited = true;
			else if (unfocused && (bool)global::_app->setting_fps_unfocused_limit)
				targetFps = std::clamp((double)global::_app->setting_fps_unfocused, 5.0, 60.0);
			else if ((bool)global::_app->setting_fps_unlimited)
				unlimited = true;
			else
				targetFps = std::clamp((double)global::_app->setting_fps_cap, 15.0, 360.0);
		}
		
		int delayMs = 0;
		if (!unlimited)
		{
			double targetMs = 1000.0 / targetFps;
			delayMs = std::max(0, (int)std::floor(targetMs - workMs));
		}
		stepTimer.start(delayMs, Qt::PreciseTimer, this);
	}

	IntType AppHandler::GetMsec() const
	{
		return QDateTime::currentDateTime().toMSecsSinceEpoch() - startTime;
	}

	int AppHandler::ExecDialog(QDialog* dialog)
	{
		GFX->SubmitBatch();

		// Clear keys
		for (IntType key : keyStateMap.keys())
			keyStateMap[key] = {};
		for (IntType key : keyWinStateMap.keys())
			keyWinStateMap[key] = {};

		blocked = true;
		int res = dialog->exec();

		GFX->StartOffScreenRender();

		return res;
	}

	void AppHandler::SetKeyDown(QKeyEvent* event, BoolType down)
	{
		QVector<IntType> keys = {};
		switch (event->key())
		{
			case Qt::Key_Alt: keys = { vk_alt, vk_ralt, vk_lalt }; break;
			case Qt::Key_Control: keys = { vk_control, vk_rcontrol, vk_lcontrol }; break;
			case Qt::Key_Shift: keys = { vk_shift, vk_rshift, vk_lshift }; break;
			default:
			{
				int qtKey = event->key();
				bool isKeypad = (event->modifiers() & Qt::KeypadModifier) != 0;
				if (isKeypad && qtKey >= Qt::Key_0 && qtKey <= Qt::Key_9)
					keys = { vk_numpad0 + (qtKey - Qt::Key_0) };
				else if (isKeypad && qtKey == Qt::Key_Plus)
					keys = { vk_add };
				else if (isKeypad && qtKey == Qt::Key_Minus)
					keys = { vk_subtract };
				else if (isKeypad && qtKey == Qt::Key_Asterisk)
					keys = { vk_multiply };
				else if (isKeypad && qtKey == Qt::Key_Slash)
					keys = { vk_divide };
				else if (isKeypad && qtKey == Qt::Key_Period)
					keys = { vk_decimal };
				else if (keyMap.contains(qtKey)) // Mapped key (includes A-Z, 0-9, F-keys, arrows, Space, Tab, etc.)
					keys = { keyMap.value(qtKey) };
				else
				{
					IntType nvk = event->nativeVirtualKey();
				#if defined(OS_UNIX)
					// X11 KeySyms for lowercase letters 'a'..'z' (0x61..0x7A) -> uppercase GML ord('A'..'Z') (65..90)
					if (nvk >= 0x61 && nvk <= 0x7A)
						nvk -= 32;
				#endif
					keys = { nvk };
				}
				break;
			}
		}

		// Update key states
		for (IntType key : keys)
			keyStateMap[key].SetDown(down);

		// Set last key
		if (keys.length() && down)
			gmlGlobal::keyboard_lastkey = keys[0];

		// Update vk_nokey/vk_anykey down state
		keyStateMap[vk_nokey].down = true;
		keyStateMap[vk_anykey].down = false;

		QHashIterator<IntType, KeyState> it(keyStateMap);
		while (it.hasNext())
		{
			it.next();
			if (it.key() == vk_nokey || !it.value().down)
				continue;
			
			keyStateMap[vk_nokey].down = false;
			keyStateMap[vk_anykey].down = true;
			break;
		}

	#if DEBUG_MODE && 0
		QString keyStr = "";
		for (IntType key : keys)
			keyStr += NumStr(key) + " ";
		DEBUG(QString(down ? "KeyPress" : "KeyRelease") + " key=" + NumStr(event->key()) + ", nativeVirtualKey=" + NumStr(event->nativeVirtualKey()) + ", nativeScanCode=" + NumStr(event->nativeScanCode()) + " => " + keyStr);
	#endif
	}

	void AppHandler::SetWinKeyDown(IntType keyCode, BoolType down)
	{
	#if OS_WINDOWS
		IntType key = 0;
		switch (keyCode)
		{
			case 312: key = vk_ralt; break;
			case 56: key = vk_lalt; break;
			case 285: key = vk_rcontrol; break;
			case 29: key = vk_lcontrol; break;
			case 54: key = vk_rshift; break;
			case 42: key = vk_lshift; break;
		}

		if (key)
		{
			keyWinStateMap[key].SetDown(down);

			// Set last key
			if (down)
				gmlGlobal::keyboard_lastkey = key;
		}
	#endif
	}

	void AppHandler::KeyState::SetDown(BoolType down)
	{
		if (down && !this->down)
			pressed = true;
		if (!down && this->down)
			released = true;
		this->down = down;

		if (pressed)
		{
			App->keyStateMap[vk_nokey].pressed = false;
			App->keyStateMap[vk_anykey].pressed = true;
		}

		if (released)
		{
			App->keyStateMap[vk_nokey].released = false;
			App->keyStateMap[vk_anykey].released = true;
		}
	}

	void AppHandler::HttpProgress(const HttpRequest& request, IntType received, IntType total)
	{
		GFX->StartOffScreenRender();
		Map& asyncMap = DsMap(gmlGlobal::async_load);
		asyncMap["id"] = request.id;
		asyncMap["status"] = 1;
		asyncMap["sizeDownloaded"] = received;
		asyncMap["contentLength"] = total;
		app_event_http(ScopeAny(global::_app->id));
	}

	void AppHandler::HttpResponse(const HttpRequest& request)
	{
		GFX->StartOffScreenRender();
		Map& asyncMap = DsMap(gmlGlobal::async_load);
		asyncMap["id"] = request.id;
		asyncMap["http_status"] = request.data->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
		if (request.data->error())
		{
			asyncMap["status"] = -1;
			WARNING("Error fetching " + request.url + ":\n" + request.data->errorString());
		}
		else
		{
			asyncMap["status"] = 0;
			asyncMap["result"] = QString(request.data->readAll());
		}

		app_event_http(ScopeAny(global::_app->id));
	}
}
