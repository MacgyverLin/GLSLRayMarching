#include "LPVMtlLoader.h"
#include "LPVCommon.h"

//////////////////////////////////////////////////////////////
LPVMtlLoader::LPVMtlLoader()
{
    // Nothing to do.
}

LPVMtlLoader::~LPVMtlLoader()
{
}

void LPVMtlLoader::Load(const std::string & filename, std::function<void(std::map<std::string, MaterialInfo>&)> onload)
{
    std::ifstream mtl(filename);

    MaterialInfo material;
    bool saveMaterial = false;
    std::map<std::string, MaterialInfo> materials;

    std::string line;

    while (getline(mtl, line))
    {
        size_t nextVal = line.find(' ');

        if (0 == line.size() || std::string::npos == nextVal || '#' == line[0])
        {
            continue;
        }

        std::string key = line.substr(0, nextVal);
        std::string value = line.substr(nextVal + 1);
        std::string materialName;

        if (key == "newmtl")
        {
            if (saveMaterial)
            {
                materials[materialName] = material;
            }

            materialName = value;
            material = MaterialInfo();
            saveMaterial = true;
        }
        else if ("Ka" == key || "Kd" == key || "Ks" == key || "Ke" == key || "Tf" == key)
        {
            ColorRGBA xyz;
            std::stringstream ss(value);
            ss >> xyz.R() >> xyz.G() >> xyz.B();

            if ("Ka" == key)
            {
                material.Ka = xyz;
            }
            else if ("Kd" == key)
            {
                material.Kd = xyz;
            }
            else if ("Ks" == key)
            {
                material.Ks = xyz;
            }
            else if ("Ke" == key)
            {
                material.Ke = xyz;
            }
            else if ("Tf" == key)
            {
                material.Tf = xyz;
            }
        }
        else if ("Ns" == key || "Ni" == key || "d" == key || "Tr" == key || "illum" == key || "map_Ka" == key || "map_Kd" == key || "map_Ks" == key || "map_d" == key || "map_bump" == key || "map_norm" == key || "bump" == key)
        {
            std::stringstream ss(value);
            if ("Ns" == key)
            {
                ss >> material.Ns;
            }
            else if ("Ni" == key)
            {
                ss >> material.Ni;
            }
            else if ("d" == key)
            {
                ss >> material.d;
            }
            else if ("Tr" == key)
            {
                ss >> material.Tr;
            }
            else if ("illum" == key)
            {
                ss >> material.illum;
            }
            else if ("map_Ka" == key)
            {
                material.hasMapKa = true;
                material.map_Ka = value;
            }
            else if ("map_Kd" == key)
            {
                material.hasMapKd = true;
                material.map_Kd = value;
            }
            else if ("map_Ks" == key)
            {
                material.hasMapKs = true;
                material.map_Ks = value;
            }
            else if ("map_bump" == key)
            {
                material.hasMapbump = true;
                material.map_bump = value;
            }
            else if ("map_norm" == key)
            {
                material.hasMapNorm = true;
                material.map_norm = value;
            }
            else if ("bump" == key)
            {
                material.hasbump = true;
                material.bump = value;
            }
        }
        else
        {
            //Just a precaution, if things are working as they should, remove this
            throw "Key not recognized::" + key;
        }

        onload(materials);
    }
#if 0
    console.time('MTLLoader');
    var material;
    var materials = [];
    var lines = mtl.split('\n');

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();

        var nextVal = line.indexOf(' ');

        //If line is empty, has no spaces (hence no values) or is a comment, then skip it
        if (line.length == = 0 || nextVal < 0 || line[0] == '#')
            continue;

        var key = line.substr(0, nextVal);
        var value = line.substr(nextVal + 1, line.length);

        if (key == = 'newmtl') {
            //if start of new material, push the last material
            if (material)
                materials[material.name] = material;
            material = {
                name: value,
                properties : {}
            }
        }
        else if (key == = 'Ka' || key == = 'Kd' || key == = 'Ks' || key == = 'Ke' || key == = 'Tf') {
            var xyz = value.split(' ');
            material.properties[key] = xyz;
        }
        else if (key == = 'Ns' || key == = 'Ni' || key == = 'd' || key == = 'Tr' || key == = 'illum' || key == = 'map_Ka' || key == = 'map_Kd' || key == = 'map_Ks' || key == = 'map_d' || key == = 'map_bump' || key == = 'map_norm' || key == = 'bump') {
            material.properties[key] = value;
        }
        else {
            //Just a precaution, if things are working as they should, remove this
            throw "Key not recognized::" + key;
        }
    }
    //push the last material
    if (material && material.name && material.properties)
        materials[material.name] = material;
    console.timeEnd('MTLLoader');
    return materials;
#endif
}

void LPVMtlLoader::OnCompletion(std::function<void(std::map<std::string, MaterialInfo>&)> onload)
{
}