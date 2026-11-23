#include "MeshFiles.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QTemporaryDir>
#include <QTextStream>
#include <QUrl>
#include <QtEndian>

namespace CppProject
{
	bool IsExternalMesh(const QString& path)
	{
		const QString ext = QFileInfo(path).suffix().toLower();
		return ext == "obj" || ext == "gltf" || ext == "glb";
	}

	QString MeshDirective(const QString& line, const QString& keyword)
	{
		const QString text = line.section('#', 0, 0).trimmed();
		if (!text.startsWith(keyword) || text.size() <= keyword.size() || !text[keyword.size()].isSpace())
			return {};
		return text.mid(keyword.size()).trimmed();
	}

	QString GltfLocalPath(const QString& uri)
	{
		const QUrl url = QUrl::fromEncoded(uri.toUtf8(), QUrl::StrictMode);
		if (!url.isValid() || !url.isRelative() || !url.authority().isEmpty() || url.hasQuery() || url.hasFragment())
			return {};
		return url.path(QUrl::FullyDecoded);
	}

	QString MeshDiffuseMap(const QString& line)
	{
		const QString map = MeshDirective(line, "map_Kd");
		// Keep support for the legacy importer's final filename token after map options.
		return map.startsWith('-') ? map.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts).last() : map;
	}

	QJsonObject ReadGltf(const QString& path, QByteArray& binaryChunk)
	{
		binaryChunk.clear();
		QFile file(path);
		if (!file.open(QIODevice::ReadOnly))
			return {};
		const QByteArray raw = file.readAll();
		QByteArray json = raw;
		if (raw.startsWith("glTF"))
		{
			if (raw.size() < 12 || qFromLittleEndian<quint32>(raw.constData() + 4) != 2
				|| qFromLittleEndian<quint32>(raw.constData() + 8) != quint32(raw.size()))
				return {};
			json.clear();
			int position = 12;
			while (raw.size() - position >= 8)
			{
				const auto length = qFromLittleEndian<quint32>(raw.constData() + position);
				const auto type = qFromLittleEndian<quint32>(raw.constData() + position + 4);
				position += 8;
				if (length > quint32(raw.size() - position))
					return {};
				if (type == 0x4E4F534A) // JSON
					json = raw.mid(position, length);
				else if (type == 0x004E4942) // BIN
					binaryChunk = raw.mid(position, length);
				position += length;
			}
			if (position != raw.size())
				return {};
		}
		return QJsonDocument::fromJson(json).object();
	}

	static bool CopyMeshFile(const QString& source, const QString& destination)
	{
		if (QFileInfo(source) == QFileInfo(destination))
			return QFileInfo(source).isFile();
		QFile input(source);
		if (!input.open(QIODevice::ReadOnly) || !QDir().mkpath(QFileInfo(destination).absolutePath()))
			return false;
		QSaveFile output(destination);
		if (!output.open(QIODevice::WriteOnly))
			return false;
		while (!input.atEnd())
		{
			const QByteArray chunk = input.read(1024 * 1024);
			if (chunk.isEmpty() || output.write(chunk) != chunk.size())
				return false;
		}
		return output.commit();
	}

	bool CopyMeshFiles(const QString& source, const QString& destination)
	{
		const QFileInfo sourceInfo(source);
		const QDir sourceDir(sourceInfo.absolutePath());
		const QDir destinationDir(QFileInfo(destination).absolutePath());
		const QString sourceRoot = sourceDir.canonicalPath() + '/';
		auto copyCompanion = [&](QString relativePath) {
			relativePath.replace('\\', '/');
			relativePath = QDir::cleanPath(relativePath);
			const QString companion = sourceDir.filePath(relativePath);
			const QString realPath = QFileInfo(companion).canonicalFilePath();
			if (relativePath.isEmpty() || QDir::isAbsolutePath(relativePath) || relativePath.startsWith("../")
				|| !realPath.startsWith(sourceRoot) || !QFileInfo(realPath).isFile()
				|| !CopyMeshFile(companion, destinationDir.filePath(relativePath)))
			{
				WARNING("Could not package mesh companion: " + companion);
				return false;
			}
			return true;
		};

		if (sourceInfo.suffix().compare("obj", Qt::CaseInsensitive) == 0)
		{
			QFile obj(source);
			if (!obj.open(QIODevice::ReadOnly | QIODevice::Text))
				return false;
			QTextStream model(&obj);
			while (!model.atEnd())
			{
				QString library = MeshDirective(model.readLine(), "mtllib");
				if (library.isEmpty() || !copyCompanion(library))
					continue;
				library.replace('\\', '/');
				QFile mtl(sourceDir.filePath(library));
				if (!mtl.open(QIODevice::ReadOnly | QIODevice::Text))
					continue;
				QTextStream materials(&mtl);
				while (!materials.atEnd())
				{
				const QString map = MeshDiffuseMap(materials.readLine());
					if (!map.isEmpty())
						copyCompanion(QFileInfo(library).dir().filePath(map));
				}
			}
		}
		else
		{
			QByteArray binaryChunk;
			const QJsonObject model = ReadGltf(source, binaryChunk);
			if (model.isEmpty())
				return false;
			for (const auto& buffer : model.value("buffers").toArray())
			{
				const QString uri = buffer.toObject().value("uri").toString();
				if (!uri.isEmpty() && !uri.startsWith("data:") && !copyCompanion(GltfLocalPath(uri)))
					return false;
			}
			for (const auto& image : model.value("images").toArray())
			{
				const QString uri = image.toObject().value("uri").toString();
				if (!uri.isEmpty() && !uri.startsWith("data:"))
					copyCompanion(GltfLocalPath(uri));
			}
		}
		return CopyMeshFile(source, destination);
	}

	QString ImportMeshFiles(const QString& source, const QString& projectFolder)
	{
		const QDir project(projectFolder);
		if (!project.mkpath("Models"))
			return {};
		QTemporaryDir bundle(project.filePath("Models/model-XXXXXX"));
		if (!bundle.isValid())
			return {};
		const QString destination = bundle.filePath(QFileInfo(source).fileName());
		if (!CopyMeshFiles(source, destination))
			return {};
		bundle.setAutoRemove(false);
		return project.relativeFilePath(destination);
	}
}
