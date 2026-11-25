#include "MeshFiles.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QTemporaryDir>
#include <QTextStream>
#include <QUrl>
#include <QtEndian>

namespace CppProject
{
	bool IsExternalMesh(const QString& path)
	{
		const QString ext = QFileInfo(path).suffix().toLower();
		return ext == "obj" || ext == "gltf" || ext == "glb" || ext == "bbmodel";
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

	static QString UnquoteMeshToken(QString s)
	{
		s = s.trimmed();
		if (s.size() >= 2 && ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith('\'') && s.endsWith('\''))))
			s = s.mid(1, s.size() - 2).trimmed();
		return s;
	}

	static QString TakeNextToken(QString& rest)
	{
		rest = rest.trimmed();
		if (rest.isEmpty())
			return {};
		if (rest.startsWith('"') || rest.startsWith('\''))
		{
			const QChar q = rest[0];
			const int end = rest.indexOf(q, 1);
			if (end > 0)
			{
				QString tok = rest.mid(1, end - 1);
				rest = rest.mid(end + 1).trimmed();
				return tok;
			}
		}
		int sp = 0;
		while (sp < rest.size() && !rest[sp].isSpace())
			sp++;
		QString tok = rest.left(sp);
		rest = rest.mid(sp).trimmed();
		return tok;
	}

	QString MeshMaterialMapPath(const QString& line, const QString& keyword)
	{
		const QString text = line.section('#', 0, 0).trimmed();
		if (!text.startsWith(keyword, Qt::CaseInsensitive) || text.size() <= keyword.size() || !text[keyword.size()].isSpace())
			return {};
		QString rest = text.mid(keyword.size()).trimmed();
		while (rest.startsWith('-'))
		{
			const QString flag = TakeNextToken(rest).toLower();
			if (flag == "-o" || flag == "-s" || flag == "-t")
			{
				for (int i = 0; i < 3 && !rest.isEmpty(); i++)
				{
					QString peekRest = rest;
					QString cand = TakeNextToken(peekRest);
					bool ok = false;
					cand.toDouble(&ok);
					if (!ok)
						break;
					rest = peekRest;
				}
			}
			else if (flag == "-mm")
			{
				for (int i = 0; i < 2 && !rest.isEmpty(); i++)
				{
					QString peekRest = rest;
					QString cand = TakeNextToken(peekRest);
					bool ok = false;
					cand.toDouble(&ok);
					if (!ok)
						break;
					rest = peekRest;
				}
			}
			else if (flag == "-bm" || flag == "-imfchan" || flag == "-texres" || flag == "-boost"
			         || flag == "-clamp" || flag == "-blendu" || flag == "-blendv" || flag == "-cc" || flag == "-type")
			{
				TakeNextToken(rest);
			}
			else
				break;
		}
		return UnquoteMeshToken(rest);
	}

	QString MeshDiffuseMap(const QString& line)
	{
		return MeshMaterialMapPath(line, "map_Kd");
	}

	QString ResolveMeshCompanionPath(const QDir& primaryDir, const QDir& rootDir, const QString& rawRef)
	{
		QString ref = UnquoteMeshToken(rawRef);
		ref.replace('\\', '/');
		while (ref.startsWith("./"))
			ref = ref.mid(2);
		if (ref.isEmpty() || ref.startsWith("data:", Qt::CaseInsensitive))
			return {};

		if (QFileInfo::exists(ref) && QFileInfo(ref).isFile())
			return QFileInfo(ref).absoluteFilePath();

		const bool hasWinDrive = (ref.size() >= 3 && ref[0].isLetter() && ref[1] == ':' && ref[2] == '/');
		const bool isAbsLike = QDir::isAbsolutePath(ref) || hasWinDrive || ref.startsWith('/');
		const QString cleanRel = QDir::cleanPath(ref);
		const QString fileName = QFileInfo(ref).fileName();

		QVector<QDir> probeDirs;
		auto appendDirIfValid = [&](const QDir& d) {
			const QString cp = d.absolutePath();
			for (const QDir& ex : probeDirs)
				if (ex.absolutePath() == cp)
					return;
			if (d.exists())
				probeDirs.append(d);
		};
		const QStringList subNames = { "", "textures", "Textures", "tex", "Tex", "images", "Images", "materials", "Materials" };
		for (const QDir& base : { primaryDir, rootDir })
		{
			for (const QString& sub : subNames)
				appendDirIfValid(sub.isEmpty() ? base : QDir(base.filePath(sub)));
		}

		if (!isAbsLike && !cleanRel.isEmpty())
		{
			for (const QDir& dir : probeDirs)
			{
				const QString cand = dir.filePath(cleanRel);
				if (QFileInfo::exists(cand) && QFileInfo(cand).isFile())
					return QFileInfo(cand).absoluteFilePath();
			}
		}

		if (!fileName.isEmpty())
		{
			for (const QDir& dir : probeDirs)
			{
				const QString cand = dir.filePath(fileName);
				if (QFileInfo::exists(cand) && QFileInfo(cand).isFile())
					return QFileInfo(cand).absoluteFilePath();
			}
			for (const QDir& dir : probeDirs)
			{
				const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
				for (const QFileInfo& fi : entries)
				{
					if (fi.fileName().compare(fileName, Qt::CaseInsensitive) == 0)
						return fi.absoluteFilePath();
				}
			}
		}
		return {};
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
		QSet<QString> copiedFiles;

		auto copyResolved = [&](const QString& resolvedPath) -> bool {
			const QString realPath = QFileInfo(resolvedPath).canonicalFilePath();
			if (realPath.isEmpty() || !QFileInfo(realPath).isFile())
				return false;
			if (copiedFiles.contains(realPath))
				return true;
			QString destRel;
			if (realPath.startsWith(sourceRoot))
				destRel = sourceDir.relativeFilePath(realPath);
			else
				destRel = QFileInfo(realPath).fileName();
			if (destRel.isEmpty() || QDir::isAbsolutePath(destRel) || destRel.startsWith("../"))
				destRel = QFileInfo(realPath).fileName();
			if (!CopyMeshFile(realPath, destinationDir.filePath(destRel)))
			{
				WARNING("Could not package mesh companion: " + realPath);
				return false;
			}
			copiedFiles.insert(realPath);
			return true;
		};

		auto copyCompanion = [&](const QDir& primaryDir, const QString& rawRef) -> QString {
			const QString resolved = ResolveMeshCompanionPath(primaryDir, sourceDir, rawRef);
			if (resolved.isEmpty() || !copyResolved(resolved))
				return {};
			return resolved;
		};

		const QString ext = sourceInfo.suffix().toLower();
		if (ext == "obj")
		{
			QFile obj(source);
			if (!obj.open(QIODevice::ReadOnly | QIODevice::Text))
				return false;
			const QStringList mapKeywords = {
				"map_Kd", "map_Ka", "map_d", "map_Bump", "bump", "norm",
				"map_Pr", "map_Ns", "map_Pm", "map_Ks", "map_Ke", "map_refl"
			};
			QTextStream model(&obj);
			while (!model.atEnd())
			{
				QString library = MeshDirective(model.readLine(), "mtllib");
				if (library.isEmpty())
					continue;
				const QString resolvedMtl = copyCompanion(sourceDir, library);
				if (resolvedMtl.isEmpty())
					continue;
				QFile mtl(resolvedMtl);
				if (!mtl.open(QIODevice::ReadOnly | QIODevice::Text))
					continue;
				const QDir mtlDir = QFileInfo(resolvedMtl).absoluteDir();
				QTextStream materials(&mtl);
				while (!materials.atEnd())
				{
					const QString mline = materials.readLine();
					for (const QString& kw : mapKeywords)
					{
						const QString mapRef = MeshMaterialMapPath(mline, kw);
						if (!mapRef.isEmpty())
							copyCompanion(mtlDir, mapRef);
					}
				}
			}
		}
		else if (ext == "bbmodel")
		{
			QFile bf(source);
			if (!bf.open(QIODevice::ReadOnly))
				return false;
			const QJsonObject root = QJsonDocument::fromJson(bf.readAll()).object();
			if (root.isEmpty())
				return false;
			for (const auto& tval : root.value("textures").toArray())
			{
				const QJsonObject tobj = tval.toObject();
				const QString src = tobj.value("source").toString();
				if (src.startsWith("data:", Qt::CaseInsensitive))
					continue;
				for (const QString& cand : { tobj.value("relative_path").toString(), tobj.value("path").toString(), tobj.value("name").toString() })
				{
					if (!cand.isEmpty() && !copyCompanion(sourceDir, cand).isEmpty())
						break;
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
				if (!uri.isEmpty() && !uri.startsWith("data:", Qt::CaseInsensitive))
				{
					const QString local = GltfLocalPath(uri);
					if (copyCompanion(sourceDir, local.isEmpty() ? uri : local).isEmpty())
						return false;
				}
			}
			for (const auto& image : model.value("images").toArray())
			{
				const QString uri = image.toObject().value("uri").toString();
				if (!uri.isEmpty() && !uri.startsWith("data:", Qt::CaseInsensitive))
				{
					const QString local = GltfLocalPath(uri);
					copyCompanion(sourceDir, local.isEmpty() ? uri : local);
				}
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
