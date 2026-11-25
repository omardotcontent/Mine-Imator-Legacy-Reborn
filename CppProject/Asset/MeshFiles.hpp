#pragma once

#include <QString>

class QByteArray;
class QDir;
class QJsonObject;

namespace CppProject
{
	bool IsExternalMesh(const QString& path);
	QString MeshDirective(const QString& line, const QString& keyword);
	QString MeshMaterialMapPath(const QString& line, const QString& keyword);
	QString MeshDiffuseMap(const QString& line);
	QString GltfLocalPath(const QString& uri);
	QString ResolveMeshCompanionPath(const QDir& primaryDir, const QDir& rootDir, const QString& rawRef);
	QJsonObject ReadGltf(const QString& path, QByteArray& binaryChunk);
	bool CopyMeshFiles(const QString& source, const QString& destination);
	QString ImportMeshFiles(const QString& source, const QString& projectFolder);
}
