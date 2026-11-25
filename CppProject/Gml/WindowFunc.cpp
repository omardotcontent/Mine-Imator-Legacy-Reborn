#include "Generated/GmlFunc.hpp"
#include "Generated/Scripts.hpp"

#include "AppHandler.hpp"
#include "AppWindow.hpp"
#include "Render/GraphicsApiHandler.hpp"

#include <QCursor>
#include <QDesktopWidget>

namespace CppProject
{
	IntType display_get_dpi_x()
	{
		return qApp->desktop()->logicalDpiX();
	}

	IntType display_get_dpi_y()
	{
		return qApp->desktop()->logicalDpiY();
	}

	IntType display_mouse_get_x()
	{
	#if defined(OS_WINDOWS)
		if (AppWindow::mouseEnableLock)
			return QCursor::pos().x() / App->scale;
	#endif
		if (AppWin->mouseLocked)
			return AppWin->mouseLockPos.x() + (IntType)std::llround((AppWin->mousePos.x() - AppWin->mouseLastPos.x()) / App->scale);
		return (IntType)std::llround(AppWin->mousePos.x() / App->scale);
	}

	IntType display_mouse_get_y()
	{
	#if defined(OS_WINDOWS)
		if (AppWindow::mouseEnableLock)
			return QCursor::pos().y() / App->scale;
	#endif
		if (AppWin->mouseLocked)
			return AppWin->mouseLockPos.y() + (IntType)std::llround((AppWin->mousePos.y() - AppWin->mouseLastPos.y()) / App->scale);
		return (IntType)std::llround(AppWin->mousePos.y() / App->scale);
	}

	void display_mouse_set(IntType x, IntType y)
	{
	#if defined(OS_WINDOWS)
		if (AppWindow::mouseEnableLock)
		{
			QPoint target((int)std::llround(x * App->scale), (int)std::llround(y * App->scale));
			if (QCursor::pos() != target)
				QCursor::setPos(target);
			return;
		}
	#endif
		if (!AppWin->mouseLocked)
		{
			AppWin->mouseLocked = true;
			AppWin->mouseLockPos = QPoint((int)x, (int)y);
			AppWin->mouseLockWinPos = AppWin->mousePos;
		}
		else if (AppWindow::mouseEnableLock && !AppWin->ignoreNextWarpJump)
		{
			const int margin = 48;
			QPoint p = AppWin->mousePos;
			if (AppWin->width() > margin * 3 && AppWin->height() > margin * 3 &&
				(p.x() < margin || p.x() > AppWin->width() - margin || p.y() < margin || p.y() > AppWin->height() - margin))
			{
				QPoint center(AppWin->width() / 2, AppWin->height() / 2);
				AppWin->warpTarget = center;
				AppWin->ignoreNextWarpJump = true;
				QCursor::setPos(AppWin->mapToGlobal(center));
				AppWin->mousePos = AppWin->mouseLastPos = center;
			}
		}
	}

	IntType display_reset(IntType, IntType)
	{
		// Do nothing
		return 0;
	}

	IntType window_get_height()
	{
		return AppWin->height() / App->scale;
	}

	IntType window_get_width()
	{
		return AppWin->width() / App->scale;
	}

	IntType window_get_x()
	{
		return AppWin->x();
	}

	IntType window_get_y()
	{
		return AppWin->y();
	}

	StringType window_handle()
	{
		// Do nothing
		return "";
	}

	void window_mouse_set(IntType x, IntType y)
	{
		QPoint global = AppWin->mapToGlobal({ (int)x, (int)y });
		display_mouse_set(global.x(), global.y());
		AppWin->mouseLockWinPos = QPoint(x, y);
	}

	void window_set_caption(StringType caption)
	{
		QString title = caption;
		const QString originalName = "Mine-imator";
		if (title.compare(originalName, Qt::CaseInsensitive) == 0 || title.endsWith(" - " + originalName, Qt::CaseInsensitive))
			title.replace(title.size() - originalName.size(), originalName.size(), APP_DISPLAY_NAME);
		AppWin->setWindowTitle(title);
	}

	void window_set_cursor(IntType cursor)
	{
		AppWin->setCursor(App->cursorMap[cursor]);
	}

	void window_set_min_height(IntType height)
	{
		AppWin->setMinimumHeight(height);
	}

	void window_set_min_width(IntType width)
	{
		AppWin->setMinimumHeight(width);
	}

	void window_set_rectangle(IntType, IntType, IntType, IntType)
	{
		// Do nothing
	}

	void window_set_size(IntType width, IntType height)
	{
		AppWin->newSize = { (int)width, (int)height };
	}

	IntType window_get_current()
	{
		return AppWin->id;
	}

	void window_create(IntType window, IntType x, IntType y, IntType width, IntType height)
	{
		x *= App->scale;
		y *= App->scale;
		width *= App->scale;
		height *= App->scale;
		ds_list_add({ global::window_list, window });
		GFX->SubmitBatch();
		App->addedWindows.append({ window, QRect(x, y, width, height), AppWin });
	}

	void window_close(IntType window)
	{
		for (AppWindow* win : App->windows)
		{
			if (win->id == window)
			{
				win->close();
				return;
			}
		}
	}

	BoolType window_mouse_is_active(IntType window)
	{
		return (App->mouseWindow->id == window);
	}

	void window_mouse_set_permission(BoolType enabled)
	{
		AppWindow::mouseEnableLock = enabled;
	}

	BoolType window_mouse_get_permission()
	{
		return AppWindow::mouseEnableLock;
	}

	void window_state_save(IntType window)
	{
		AppWindow* saveWin = App->mainWindow;

		for (AppWindow* win : App->windows)
			if (win->id == window)
				saveWin = win;

		int x, y, w, h;
		saveWin->geometry().getRect(&x, &y, &w, &h);
		json_save_var("rect", ArrType::From({ x, y, w, h }));
		json_save_var_bool("maximized", saveWin->isMaximized());
	}

	void window_state_restore(IntType window, IntType mapId)
	{
		ds_list_add({ global::window_list, window });

		const Map& map = DsMap(mapId);
		const List& rectList = DsList(map.Value("rect"));
		QRect rect = QRect(rectList.Value(0), rectList.Value(1), rectList.Value(2), rectList.Value(3));
		BoolType maximized = map.Value("maximized").Int();
		App->addedWindows.append({ window, rect, nullptr, maximized });
	}

	void window_main_restore(VarType rect, BoolType maximize)
	{
		if (rect == null_)
			App->mainWindow->Maximize();

		else
		{
			App->mainWindow->setGeometry(QRect(rect[0], rect[1], rect[2], rect[3]));
			if (maximize)
				App->mainWindow->Maximize();
		}
	}
}
