//Cornell box path tracing with:
//    1 random sample per pixel,
//    next event estimation (1 random sample towards light),
//    russian roulette,
//    ggx brdf,
//    and multiple importance sampling.

//Highly unoptimized path tracing, any advice would be greatly appreciated!
//Combining triangles to quads saves lots of compiling time!
//Thanks to spalmer, by replacing `0` with `min(0, iFrame)` in for loops, the compile time is greatly reduced!

#define CUBE_COUNT 1
#define WALL_COUNT 5
#define SPHERE_COUNT 1
#define LIGHT_COUNT 1

Quad lights[LIGHT_COUNT];
Quad quads[CUBE_COUNT * 6 + WALL_COUNT + LIGHT_COUNT];
Sphere spheres[SPHERE_COUNT];
Material materials[6];

///////////////////////////////////////////////////
//             Scene Build Functions             //
///////////////////////////////////////////////////

void CubeToQuads(int materialID, vec3 center, vec3 xAxis, vec3 size, inout int offset)
{
    vec3 u = normalize(xAxis);
    vec3 w = normalize(cross(u, vec3(0.0, 1.0, 0.0)));
    vec3 v = cross(w, u);

    u *= size.x;
    v *= size.y;
    w *= size.z;

    vec3 p0 = center - (u + v + w) * 0.5;
    vec3 p6 = center + (u + v + w) * 0.5;

    quads[offset] = Quad(materialID, p0, u, w);
    quads[offset + 1] = Quad(materialID, p0, v, u);
    quads[offset + 2] = Quad(materialID, p0, w, v);

    quads[offset + 3] = Quad(materialID, p6, -w, -u);
    quads[offset + 4] = Quad(materialID, p6, -u, -v);
    quads[offset + 5] = Quad(materialID, p6, -v, -w);

    offset += 6;
}


void MakeScene()
{
    //floor
    quads[0] = Quad(1, vec3(-6.0, 0.0, -6.0), vec3(0.0, 0.0, 12.0), vec3(12.0, 0.0, 0.0));

    //ceil
    quads[1] = Quad(1, vec3(-6.0, 10.0, -6.0), vec3(12.0, 0.0, 0.0), vec3(0.0, 0.0, 12.0));

    //left wall
    quads[2] = Quad(2, vec3(-6.0, 0.0, -6.0), vec3(0.0, 10.0, 0.0), vec3(0.0, 0.0, 12.0));

    //right wall
    quads[3] = Quad(3, vec3(6.0, 0.0, -6.0), vec3(0.0, 0.0, 12.0), vec3(0.0, 10.0, 0.0));

    //back wall
    quads[4] = Quad(1, vec3(-6.0, 0.0, 6.0), vec3(0.0, 10.0, 0.0), vec3(12.0, 0.0, 0.0));

    int offset = 5;
    //cube 6-11
    CubeToQuads(4, vec3(-2.0, 3.0, 3.0), vec3(1.0, 0.0, 0.5), vec3(4.0, 8.0, 4.0), offset);

    //sphere
    spheres[0] = Sphere(5, vec3(2.0, 2.0, 0.0), 2.0);

    //light 12
    lights[0] = Quad(0, vec3(-2.0, 9.5, -2.0), vec3(4.0, 0.0, 0.0), vec3(0.0, 0.0, 4.0));
    quads[11] = lights[0];

    //materials
    materials[0] = Material(0, vec3(5.0, 5.0, 5.0), 0.0, 0.0);
    materials[1] = Material(1, vec3(0.7, 0.7, 0.4), 0.9, 0.0);
    materials[2] = Material(1, vec3(1.0, 0.0, 0.0), 0.9, 0.0);
    materials[3] = Material(1, vec3(0.0, 1.0, 0.0), 0.9, 0.0);
    materials[4] = Material(1, vec3(0.7, 0.7, 0.4), 0.1, 0.7);
    materials[5] = Material(1, vec3(1.0, 0.64, 0.05), 0.6, 0.9);
}

///////////////////////////////////////////////////
//             Scene Related Tracing             //
///////////////////////////////////////////////////

bool TraceScene(Ray ray, out Intersection intersection, out int materialID)
{
    float d = INFINITY;
    bool hasHit = false;
    for (int i = min(0, iFrame); i < quads.length(); i++)
    {
        float t;
        Intersection tempIntersection;
        bool isHit = RayQuadIntersect(ray, quads[i], t, tempIntersection);
        if (isHit && t < d)
        {
            d = t;
            hasHit = true;

            materialID = quads[i].materialID;
            intersection = tempIntersection;
        }
    }

    for (int i = min(0, iFrame); i < spheres.length(); i++)
    {
        float t;
        Intersection tempIntersection;
        bool isHit = RaySphereIntersect(ray, spheres[i], t, tempIntersection);
        if (isHit && t < d)
        {
            d = t;
            hasHit = true;

            materialID = spheres[i].materialID;
            intersection = tempIntersection;
        }
    }

    return hasHit;
}

bool TraceLight(Ray ray, int lightMaterialID)
{
    float d = INFINITY;
    int materialID = -1;
    for (int i = min(0, iFrame); i < quads.length(); i++)
    {
        float t;
        Intersection tempIntersection;
        bool isHit = RayQuadIntersect(ray, quads[i], t, tempIntersection);
        if (isHit && t < d)
        {
            d = t;

            materialID = quads[i].materialID;
        }
    }

    for (int i = min(0, iFrame); i < spheres.length(); i++)
    {
        float t;
        Intersection tempIntersection;
        bool isHit = RaySphereIntersect(ray, spheres[i], t, tempIntersection);
        if (isHit && t < d)
        {
            d = t;

            materialID = spheres[i].materialID;
        }
    }

    return materialID == lightMaterialID;
}

///////////////////////////////////////////////////
//             Scene Related PDFs                //
///////////////////////////////////////////////////

float PDF_NEE(Ray ray)
{
    float pdfNEE = 0.0;
    for (int i = min(0, iFrame); i < lights.length(); i++)
    {
        float pdfLight = PDF_Quad(lights[i], ray);
        pdfNEE += pdfLight;
    }
    return pdfNEE / float(lights.length());
}

float PDF_BRDF(vec3 wi, vec3 wo, vec3 normal, float roughness, float t)
{
    return (1.0 - t) * PDF_Lambert(wi, normal) + t * PDF_GGX(wi, wo, normal, roughness);
}

void WeightPDF(Ray ray, vec3 wo, vec3 normal, float roughness, float t, out float weightNEE, out float weightBRDF)
{
    float pdfNEE = PDF_NEE(ray);
    float pdfBRDF = PDF_BRDF(ray.direction, wo, normal, roughness, t);

    float squareSum = pdfNEE * pdfNEE + pdfBRDF * pdfBRDF;
    if (squareSum == 0.0)
    {
        weightNEE = 1.0;
        weightBRDF = 0.0;
    }
    else
    {
        weightNEE = pdfNEE / squareSum;
        weightBRDF = pdfBRDF / squareSum;
    }
}

///////////////////////////////////////////////////
//                Main Function                  //
///////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = vec3(0.0);

    seed = hash12(fragCoord) + iTime;
    float randomValue = GetRandom();

    Camera camera = Camera(vec3(0.0, 4.0, -12.0), vec3(0.0, 4.0, 0.0), vec3(0.0, 1.0, 0.0), 45.0);

    Ray ray = InitRay(camera, fragCoord, iResolution.xy);
    MakeScene();

    Intersection intersection;
    int materialID;
    bool isHit = TraceScene(ray, intersection, materialID);
    if (isHit)
    {
        int depth = 1;
        Material material = materials[materialID];

        if (material.materialType == 0)
        {
            //Hit light directly.
            color = material.baseColor;
        }
        else
        {
            vec3 lastBRDF = vec3(1.0);

            bool terminateRay = false;
            while (!terminateRay)
            {
                vec3 lastRayDir = ray.direction;
                float roughness = material.roughness * material.roughness;

                vec3 F0 = F0(material.baseColor, material.metallic);
                vec3 diffuse = material.baseColor * (1.0 - material.metallic);
                float F0Sum = F0.x + F0.y + F0.z;
                float diffuseSum = diffuse.x + diffuse.y + diffuse.z;
                float t = max(F0Sum / (diffuseSum + F0Sum), 0.25);

                //Next event estimation for directional light.
                vec3 directBRDF = vec3(0.0);

                for (int i = 0; i < lights.length(); i++)
                {
                    float dist;
                    Ray lightRay = GetRandomRay_NEE(lights[i], intersection.position, intersection.normal, dist);

                    float weightNEE, weightIndirect;
                    WeightPDF(lightRay, -lastRayDir, intersection.normal, roughness, t, weightNEE, weightIndirect);

                    vec3 lightNormal = cross(lights[i].w, lights[i].l);
                    float LNdotL = dot(lightNormal, -lightRay.direction);

                    int lightMaterialID = lights[i].materialID;
                    if (LNdotL > 0.0)
                    {
                        bool isShaded = TraceLight(lightRay, lightMaterialID);
                        if (isShaded)
                        {
                            directBRDF += EvaluateBRDF(lightRay.direction, -lastRayDir, material, intersection.normal)
                                * materials[lightMaterialID].baseColor * weightNEE;
                        }
                    }
                }

                color += lastBRDF * directBRDF;

                //GGX importance sampling for indirectional light.
                vec3 indirectBRDF = vec3(0.0);

                //Russian roulette
                float randomA = GetRandom();
                float probability = 1.0 - min(max(max(lastBRDF.r, lastBRDF.g), lastBRDF.b), 1.0);
                if (randomA >= probability)
                {
                    //GGX importance sampling new ray.
                    ray = GetRandomRay_GGX(lastRayDir, intersection.position, intersection.normal, roughness, t);
                    float weightNEE, weightIndirect;
                    WeightPDF(ray, -lastRayDir, intersection.normal, roughness, t, weightNEE, weightIndirect);

                    Intersection ggxIntersection;
                    int ggxMaterialID;
                    bool ggxHit = TraceScene(ray, ggxIntersection, ggxMaterialID);
                    if (ggxHit)
                    {
                        Material ggxMaterial = materials[ggxMaterialID];
                        indirectBRDF = EvaluateBRDF(ray.direction, -lastRayDir, material, intersection.normal) / (1.0 - probability);
                        lastBRDF *= indirectBRDF * weightIndirect;

                        if (ggxMaterial.materialType == 0)
                        {
                            //Reached light, terminate ray.
                            float frontLight = dot(ray.direction, ggxIntersection.normal) < 0.0 ? 1.0 : 0.0;
                            color += lastBRDF * ggxMaterial.baseColor * frontLight;
                            terminateRay = true;
                        }
                        else
                        {
                            //Start a new iteration.
                            intersection = ggxIntersection;
                            materialID = ggxMaterialID;
                            material = ggxMaterial;
                            depth++;
                        }
                    }
                    else
                    {
                        //GGX importance sampling missed, terminate ray.
                        terminateRay = true;
                    }
                }
                else
                {
                    //Russian roulette failed, terminate ray.
                    terminateRay = true;
                }
            }
        }
    }

    fragColor = vec4(color, 1.0);
}