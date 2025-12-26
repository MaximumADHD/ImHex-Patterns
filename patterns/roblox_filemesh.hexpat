#pragma author MaximumADHD
#pragma description Roblox FileMesh format (*.mesh)

import std.sys;
import std.mem;
import std.core;
import std.string;
import type.magic;

struct AsciiVector3 {
    str openToken = std::mem::read_string($, 1);
    std::assert(openToken == "[",  "Expected [ opening token! got: " + openToken);
    padding[1];
    
    char rawX[while (std::mem::read_string($, 1) != ",")];
    padding[1];
    
    char rawY[while (std::mem::read_string($, 1) != ",")];
    padding[1];
    
    char rawZ[while (std::mem::read_string($, 1) != "]")];
    str closeToken = std::mem::read_string($, 1);

    std::assert(closeToken == "]", "Expected ] closing token! got: " + closeToken);
    padding[1];
};

struct AsciiVertex {
    AsciiVector3 position;
    AsciiVector3 normal;
    AsciiVector3 uv;
};

struct AsciiFace {
    AsciiVertex verts[3];
};

struct Vector2 {
    float x, y;
};

struct Vector3 {
    float x, y, z;
};

struct Tangent {
    s8 x, y, z, s;
};

struct Color4 {
    u8 r, g, b, a;
};

struct CFrame {
    float r00, r01, r02;
    float r10, r11, r12;
    float r20, r21, r22;
    
    float x, y, z;
};

enum LodType : u16 {
    None = 0,
    Unknown = 1,
    RbxSimplifier = 2,
    ZeuxMeshOptimizer = 3,
};

struct MeshVertex {
    Vector3 position;
    Vector3 normal;
    
    Vector2 uv;
    Tangent tangent;
    
    if (parent.colorable) {
        Color4 color;
    }
};

struct MeshFace {
    u32 a, b, c;
};

struct MeshSkinning {
    u8 subsetIndices[4];
    u8 boneWeights[4];
};

struct MeshBone {
    u32 boneNameIndex;
    u16 parentIndex;
    u16 lodParentIndex;
    
    float culling;
    CFrame cframe;
};

struct MeshSubset {
    u32 facesBegin;
    u32 facesLength;
    
    u32 vertsBegin;
    u32 vertsLength;
    
    u32 numBoneIndices;
    u16 boneIndices[26];
};

struct TwoPoseCorrective {
    u16 controlIndex0;
    u16 controlIndex1;
};

struct ThreePoseCorrective {
    u16 controlIndex0;
    u16 controlIndex1;
    u16 controlIndex2;
};

struct QuantizedRow<T> {
    T data[parent.rows];
};

struct QuantizedMatrix {
    u16 version;
    u32 rows, cols;
    
    if (version == 1) {
        QuantizedRow<float> matrix[cols];
    } else if (version == 2) {
        float min, max;
        QuantizedRow<u16> matrix[cols];
    }
};

struct QuantizedTransforms {
    QuantizedMatrix x, y, z;
    QuantizedMatrix rx, ry, rz;
};

struct FacsData {
    u32 sizeof_faceBoneNames;
    u32 sizeof_faceControlNames;
    u64 sizeof_quantizedTransforms;
    
    u32 sizeof_twoPoseCorrectives;
    u32 sizeof_threePoseCorrectives;
    
    char faceBoneNames[sizeof_faceBoneNames];
    char faceControlNames[sizeof_faceControlNames];
    
    QuantizedTransforms quantizedTransforms;
    TwoPoseCorrective twoPoseCorrectives[sizeof_twoPoseCorrectives / 4];
    ThreePoseCorrective threePoseCorrectives[sizeof_threePoseCorrectives / 6];
};

struct MeshChunk {
    char chunkType[8];
    u32 version;
    u32 size;
    
    chunkType = std::string::replace(chunkType, "\0", "");
    
    if (chunkType == "COREMESH" && version < 3) {
        if (version == 1) {
            bool hasColor = true;
            
            u32 numVerts;
            MeshVertex verts[numVerts];
            
            u32 numFaces;
            MeshFace faces[numFaces];
        } else if (version == 2) {
            // !! STUB: DRACO Decompression
            u32 sizeof_dracoBitStream;
            u8 dracoBitStream[sizeof_dracoBitStream];
        }
    } else if (chunkType == "LODS" && version == 1) {
        LodType lodType;
        u8 numHighQualityLODs;
        
        u32 numLodOffsets;
        u32 lodOffsets[numLodOffsets];
    } else if (chunkType == "SKINNING" && version == 1) {
        u32 numSkinnings;
        
        u32 numBones;
        MeshBone bones[numBones];
        
        u32 nameTableSize;
        char nameTable[nameTableSize];
        
        u32 numSubsets;
        MeshSubset subsets[numSubsets];
    } else if (chunkType == "FACS" && version == 1) {
        u32 facsDataSize;
        FacsData facsData;
    } else if (chunkType == "HSRAVIS" && version == 1) {
        u32 numAlwaysVisibleBitFlags;
        u8 alwaysVisibleBitFlags[(numAlwaysVisibleBitFlags + 7) / 8];
    } else {
        u8 unknownData[size];
    }
};

struct MeshVersion {
    type::Magic<"version "> magic;
    
    char major[while (std::mem::read_string($, 1) != ".")];
    padding[1];
    
    char minor[while (std::mem::read_string($, 1) != "\n")];
    padding[1];
    
    // Some version 1 meshes are terminated with \r\n
    if (std::string::ends_with(minor, "\r")) {
        minor = std::string::replace(minor, "\r", " ");
    }
};

struct MeshHeader {
    u16 sizeof_MeshHeader;
    
    u8 versionMajor = parent.versionMajor;
    u8 versionMinor = parent.versionMinor;
    
    bool colorable = true;
    
    if (versionMajor < 4) {
        u8 sizeof_MeshVertex;
        u8 sizeof_MeshFace;
        
        if (versionMajor == 3) {
            u16 sizeof_LodOffset;
            u16 numLodOffsets;
        }
        
        colorable = (sizeof_MeshVertex > 36);
    } else {
        LodType lodType;
    }
    
    u32 numVerts;
    u32 numFaces;
    
    if (versionMajor >= 4) {
        u16 numLodOffsets;
        u16 numBones;
        
        u32 sizeof_boneNames;
        u16 numSubsets;
        
        u8 numHighQualityLODs;
        padding[1];
        
        if (versionMajor == 5) {
            u32 facsDataFormat;
            u32 facsDataSize;
        }
    }
};

struct FileMesh {
    MeshVersion version;
    
    u8 versionMajor = std::string::parse_int(version.major, 10);
    u8 versionMinor = std::string::parse_int(version.minor, 10);
    
    if (versionMajor == 1) {
        char numAsciiFaces[while (std::mem::read_string($, 1) != "\n")];    
        u32 faceCount = 0;
        
        if (std::string::ends_with(numAsciiFaces, "\r")) {
            str trimmed = std::string::substr(numAsciiFaces, 0, std::string::length(numAsciiFaces) - 1);
            faceCount = std::string::parse_int(trimmed, 10);
        } else {
            faceCount = std::string::parse_int(numAsciiFaces, 10);
        }
        
        padding[1];
        AsciiFace asciiFaces[faceCount];
    } else if (versionMajor < 6) {
        // Binary Schema
        MeshHeader header;
        
        bool colorable = header.colorable;
        MeshVertex verts[header.numVerts];
        
        if (versionMajor >= 4) {
            if (header.numBones > 0) {
                MeshSkinning skinning[header.numVerts];
            }
        }
        
        MeshFace faces[header.numFaces];
        
        if (versionMajor >= 3) {
            u32 lodOffsets[header.numLodOffsets];
        }
        
        if (versionMajor >= 4) {
            MeshBone bones[header.numBones];
            char boneNames[header.sizeof_boneNames];
            MeshSubset subsets[header.numSubsets];
        }
        
        if (versionMajor == 5) {
            if (header.facsDataFormat == 1) {
                FacsData facsData;
            }
        }
    } else {
        // Chunk Schema
        MeshChunk chunks[];
    }
};

FileMesh mesh @ 0x00;
