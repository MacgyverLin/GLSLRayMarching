#include "LPVObjLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVObjLoader::LPVObjLoader()
{
}

LPVObjLoader::~LPVObjLoader()
{
}

void LPVObjLoader::Load(const std::string& filename, std::function<void(std::vector<ObjectInfo>&)> onload)
{
    std::vector<ObjectInfo> container;

    Assimp::Importer importer;
    const aiScene* scene = importer.ReadFile(filename, aiProcess_Triangulate | aiProcess_GenSmoothNormals | aiProcess_FlipUVs | aiProcess_CalcTangentSpace);

    if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) // if is Not Zero
    {
        std::cout << "ERROR::ASSIMP:: " << importer.GetErrorString() << std::endl;
        return;
    }

    // process ASSIMP's root node recursively
    processNode(container, scene->mRootNode, scene);

    onload(container);
}

void LPVObjLoader::processNode(std::vector<ObjectInfo>& container, aiNode* node, const aiScene* scene)
{
    for (unsigned int i = 0; i < node->mNumMeshes; i++)
    {
        aiMesh* mesh = scene->mMeshes[node->mMeshes[i]];
        container.push_back(processMesh(mesh, scene));
    }

    for (unsigned int i = 0; i < node->mNumChildren; i++)
    {
        processNode(container, node->mChildren[i], scene);
    }

}

LPVObjLoader::ObjectInfo LPVObjLoader::processMesh(aiMesh* mesh, const aiScene* scene)
{
    // data to fill
    std::vector<Vector3> tangents;
    std::vector<Vector3> bitangents;
    std::vector<Vector3> normals;
    std::vector<Vector3> positions;
    std::vector<Vector2> uvs;
    std::vector<Vector2> uv2s;
    std::vector<unsigned int> indices;
    std::string name = "";

    // walk through each of the mesh's vertices
    for (unsigned int i = 0; i < mesh->mNumVertices; i++)
    {
        // positions
        Vector3 position;
        position.X() = mesh->mVertices[i].x;
        position.Y() = mesh->mVertices[i].y;
        position.Z() = mesh->mVertices[i].z;
        positions.push_back(position);

        // normals
        if (mesh->HasNormals())
        {
            Vector3 normal;
            normal.X() = mesh->mNormals[i].x;
            normal.Y() = mesh->mNormals[i].y;
            normal.Z() = mesh->mNormals[i].z;
            normals.push_back(normal);
        }
        // texture coordinates
        if (mesh->mTextureCoords[0]) // does the mesh contain texture coordinates?
        {
            // uv.
            Vector2 uv;
            uv.X() = mesh->mTextureCoords[0][i].x;
            uv.Y() = mesh->mTextureCoords[0][i].y;
            uvs.push_back(uv);

            // tangent
            Vector3 tangent;
            tangent.X() = mesh->mTangents[i].x;
            tangent.Y() = mesh->mTangents[i].y;
            tangent.Z() = mesh->mTangents[i].z;
            tangents.push_back(tangent);

            // bitangent
            Vector3 bitangent;
            bitangent.X() = mesh->mBitangents[i].x;
            bitangent.Y() = mesh->mBitangents[i].y;
            bitangent.Z() = mesh->mBitangents[i].z;
            bitangents.push_back(bitangent);
        }
        else
        {
            uvs.push_back(Vector2(0.0f, 0.0f));
        }
    }

    for (unsigned int i = 0; i < mesh->mNumFaces; i++)
    {
        aiFace face = mesh->mFaces[i];

        for (unsigned int j = 0; j < face.mNumIndices; j++)
            indices.push_back(face.mIndices[j]);
    }

    // process materials
    aiMaterial* material = scene->mMaterials[mesh->mMaterialIndex];
    std::string materialName(material->GetName().C_Str());

    return ObjectInfo({ tangents, bitangents, normals, positions, uvs, uv2s, indices, name, materialName });
}

void LPVObjLoader::OnCompletion(std::function<void(std::vector<ObjectInfo>&)> onload)
{
}