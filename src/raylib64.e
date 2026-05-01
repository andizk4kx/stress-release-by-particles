without warning
/*******************************************************************************************
 *
 *   Copyright (c) 2026 Andreas Wagner (andizk4kx)
 *   Based on EuRayLib5 by gAndy50 and raylib by Ramon Santamaria
 *
 *   This software is provided 'as-is', without any express or implied warranty. 
 *   Distributed under the terms of the zlib license.
 *   Full license text available in the LICENSE file.
 *
 ********************************************************************************************/

--/*
--include std/ffi.e
include std/error.e
include std/machine.e
include std/os.e
include std/dll.e
include std/convert.e
include std/math.e
include std/search.e
include std/text.e
constant C_INT64=C_LONGLONG
--*/


atom win=open_dll("user32.dll")
atom myMessageBox = define_c_func (win,"MessageBoxA",{C_INT,C_POINTER,C_POINTER,C_INT},C_INT)
atom ps1=allocate_string("Raylib/RayGui for Phix/Euphoria\nOnly 64bit Interpreter are supported!",1)

--/**/ if machine_bits()=32 then
--/**/  atom ps2=allocate_string("Phix 32bit",1)
--/**/  {}=c_func(myMessageBox,{0,ps1,ps2,#00000010})
--/**/  abort(0)
--/**/ end if

--/*
ifdef EU4 and BITS32 then
    atom ps2=allocate_string("Euphoria 32bit",1)
    c_func(myMessageBox,{0,ps1,ps2,#00000010})
    abort(0)
end ifdef
--*/




constant Vector2=C_INT64,
    C_Color=C_INT64,
    Image=C_POINTER,
    Camera2D=C_POINTER,
    Camera3D=C_POINTER,
    Texture=C_POINTER,
    Rectangle=C_POINTER,
    Music=C_POINTER,
    AudioStream=C_POINTER,
    C_STRING=C_POINTER,
    Sound=C_POINTER,
    Wave=C_POINTER,
    Ray=C_POINTER,
    Mesh=C_POINTER,
    Vector3=C_POINTER,
    Vector4=C_POINTER,
    Matrix=C_POINTER,
    BoundingBox=C_POINTER,
    Model=C_POINTER,
    Texture2D=C_POINTER,
    Material=C_POINTER,
    RayCollision=C_POINTER,
    ModelAnimation=C_POINTER,
    Camera=C_POINTER,
    Font=C_POINTER,
    RenderTexture2D=C_POINTER,
    NPatchInfo=C_POINTER,
    GlyphInfo=C_POINTER,
    TextureCubemap=C_POINTER,
    AutomationEvent=C_POINTER,
    AutomationEventList=C_POINTER,
    FilePathList=C_POINTER,
    Shader=C_POINTER,
    VrDeviceInfo=C_POINTER,
    VrStereoConfig=C_POINTER,
    C_HPTR=C_POINTER --A Pointer that is added (64 bit calling convention) for a struct result (not really part of the Api)
                     -- normally silenty done by the C-Compiler
    
    
--Load the shared library
global atom ray 

ifdef WINDOWS then
        ray = open_dll({"libraylib.dll","../libraylib.dll","../../libraylib.dll","../../bin/libraylib.dll","bin/libraylib.dll","../bin/libraylib.dll"})
--      ray = open_dll({"libraylib_rl.dll"})
end ifdef

if ray = 0 then
        puts(1,"Unable to load Raylib!\n")
        abort(0)
end if

atom kernel=open_dll("kernel32.dll")
atom gpa=define_c_func(kernel,"GetProcAddress",{C_INT64,C_INT64},C_INT64)
function GetProcAddress(atom lib,sequence progname)
    atom pstr=allocate_string(progname)
        atom result=c_func(gpa,{lib,pstr})
    free(pstr)
return result
end function


--Raylib Version
global constant RAYLIB_VERSION_MAJOR = 6
global constant RAYLIB_VERSION_MINOR = 0
global constant RAYLIB_VERSION_PATCH = 0
global constant RAYLIB_VERSION = "6.0"

--Basic Defines
global constant PI = 3.14159265358979323846
global constant DEG2RAD = PI / 180.0
global constant RAD2DEG = 180.0 / PI

--Little helper
global function peek_float32(atom addr)
    -- Holt 4 Bytes (32-Bit) und konvertiert sie in ein Phix-Atom
    return float32_to_atom(peek({addr,4}))
end function

-- 
global procedure poke_float32(atom addr, atom v)
    -- Konvertiert das Phix-Atom in 32-Bit Bit-Muster und schreibt es
    poke(addr, atom_to_float32(v))
end procedure

-- Converts a 64-bit Vector2 result into a sequence
function RegtoV2(atom in_)
sequence result={0,0}
sequence x=int_to_bytes(in_,8)
    result[1]=float32_to_atom(x[1..4])
    result[2]=float32_to_atom(x[5..8])
return result
end function

--Stuffs a sequence {0,0} into a 64-bit register compatible format
function V2toReg(sequence  in_)
atom mem=allocate(8)
sequence x
    x=atom_to_float32(in_[1])
    poke(mem,x)
    x=atom_to_float32(in_[2])
    poke(mem+4,x)
return peek8u(mem)
end function

constant size_vector3=16 -- padded to 64bit 8-bytes
function poke_vector3(atom addr,sequence vector3)
    poke(addr,atom_to_float32(vector3[1]))
    poke(addr+4,atom_to_float32(vector3[2]))
    poke(addr+8,atom_to_float32(vector3[3]))
    poke4(addr+12,0) --padding
    return addr
end function

function peek_vector3(atom memC)
sequence result={0,0,0}
    result[1]=float32_to_atom(peek({memC,4}))
    result[2]=float32_to_atom(peek({memC+4,4}))
    result[3]=float32_to_atom(peek({memC+8,4}))
return result
end function

constant size_boundingbox=32
global sequence Tboundingbox={{0,0,0},{0,0,0}} 
function poke_boundingbox(atom addr,sequence box)
atom dummy
    dummy=poke_vector3(addr,box[1])
    dummy=poke_vector3(addr+12,box[2]) -- overlap padding
    return addr
end function

function peek_boundingbox(atom mem)
sequence result=Tboundingbox
        result[1]=peek_vector3(mem)
        result[2]=peek_vector3(mem+12)
return result
end function

constant size_vector4=16
function poke_vector4(atom addr,sequence vector4)
    poke(addr,atom_to_float32(vector4[1]))
    poke(addr+4,atom_to_float32(vector4[2]))
    poke(addr+8,atom_to_float32(vector4[3]))
    poke(addr+12,atom_to_float32(vector4[4]))
    return addr
end function

constant size_rectangle=16
function poke_rectangle(atom addr,sequence rect)
    poke(addr,atom_to_float32(rect[1]))
    poke(addr+4,atom_to_float32(rect[2]))
    poke(addr+8,atom_to_float32(rect[3]))
    poke(addr+12,atom_to_float32(rect[4]))
    return addr
end function

function peek_rectangle(atom memC)
sequence result={0,0,0,0}
    result[1]=float32_to_atom(peek({memC,4}))
    result[2]=float32_to_atom(peek({memC+4,4}))
    result[3]=float32_to_atom(peek({memC+8,4}))
    result[4]=float32_to_atom(peek({memC+12,4}))
return result
end function

constant size_image=24
function poke_image(atom addr,sequence image)
    poke8(addr,image[1])
    poke4(addr+8,image[2])
    poke4(addr+12,image[3])
    poke4(addr+16,image[4])
    poke4(addr+20,image[5])
    return addr
end function

function peek_image(atom mem)
sequence result={0,0,0,0,0}
    result[1]=peek8u(mem)
    result[2]=peek4s(mem+8)
    result[3]=peek4s(mem+12)
    result[4]=peek4s(mem+16)
    result[5]=peek4s(mem+20)
    return result
end function

constant Ttexture={0,0,0,0,0}
constant size_texture=24 -- padded to 64bit 8-bytes
function poke_texture(atom addr,sequence texture)
    poke4(addr,texture[1])
    poke4(addr+4,texture[2])
    poke4(addr+8,texture[3])
    poke4(addr+12,texture[4])
    poke4(addr+16,texture[5])
    poke4(addr+20,0) -- padding
    return addr
end function

function peek_texture(atom addr)
sequence result={0,0,0,0,0}
    result[1]=peek4u(addr)
    result[2]=peek4s(addr+4)
    result[3]=peek4s(addr+8)
    result[4]=peek4s(addr+12)
    result[5]=peek4s(addr+16)
return result
end function

constant Trendertexture={0,{0,0,0,0,0},{0,0,0,0,0}}
constant size_rendertexture=48
function poke_rendertexture(atom addr,sequence rtex)
atom dummy
    poke4(addr,rtex[1])
    dummy=poke_texture(addr+4,rtex[2])
    dummy=poke_texture(addr+24,rtex[3])
    poke4(addr+44,0) --padding
return addr
end function


function peek_rendertexture(atom addr)
sequence result=Trendertexture
    result[1]=peek4u(addr)
    result[2]=peek_texture(addr+4)
    result[3]=peek_texture(addr+24)
return result
end function


constant size_camera2d=24
function poke_camera2d(atom addr,sequence camera2D)
    poke(addr,atom_to_float32(camera2D[1][1]))
    poke(addr+4,atom_to_float32(camera2D[1][2]))
    poke(addr+8,atom_to_float32(camera2D[2][1]))
    poke(addr+12,atom_to_float32(camera2D[2][2]))
    poke(addr+16,atom_to_float32(camera2D[3]))
    poke(addr+20,atom_to_float32(camera2D[4]))
return addr
end function

global constant Tcamera3D={{0,0,0},{0,0,0},{0,0,0},0,0}
constant size_camera3d=64 -- padded to 64bit 8-bytes
function poke_camera3d(atom mem, sequence camera3D)
    poke(mem,atom_to_float32(camera3D[1][1]))
    poke(mem+4,atom_to_float32(camera3D[1][2]))
    poke(mem+8,atom_to_float32(camera3D[1][3]))

    poke(mem+12,atom_to_float32(camera3D[2][1]))
    poke(mem+16,atom_to_float32(camera3D[2][2]))
    poke(mem+20,atom_to_float32(camera3D[2][3]))

    poke(mem+24,atom_to_float32(camera3D[3][1]))
    poke(mem+28,atom_to_float32(camera3D[3][2]))
    poke(mem+32,atom_to_float32(camera3D[3][3]))

    poke(mem+36,atom_to_float32(camera3D[4])) --war 36
    poke4(mem+40,camera3D[5])
    --poke4(mem+44,0) --padding
return mem
end function

function peek_camera3d(atom mem)
sequence camera3D=Tcamera3D
    camera3D[1][1]=float32_to_atom(peek({mem,4}))
    camera3D[1][2]=float32_to_atom(peek({mem+4,4}))
    camera3D[1][3]=float32_to_atom(peek({mem+8,4}))


    camera3D[2][1]=float32_to_atom(peek({mem+12,4}))
    camera3D[2][2]=float32_to_atom(peek({mem+16,4}))
    camera3D[2][3]=float32_to_atom(peek({mem+20,4}))

    camera3D[3][1]=float32_to_atom(peek({mem+24,4}))

    camera3D[3][2]=float32_to_atom(peek({mem+28,4}))
    camera3D[3][3]=float32_to_atom(peek({mem+32,4}))


    camera3D[4]=float32_to_atom(peek({mem+36,4}))
    camera3D[5]=(peek4s(mem+40))
return camera3D
end function

global constant size_audiostream=32 --MUST be padded for Music
function poke_stream(atom mem,sequence stream)
    poke8(mem,stream[1])
    poke8(mem+8,stream[2])
    poke4(mem+16,stream[3])
    poke4(mem+20,stream[4])
    poke4(mem+24,stream[5])
    poke4(mem+28,0)
return mem
end function

function peek_stream(atom mem)
sequence stream={0,0,0,0,0}
    stream[1]=peek8u(mem)
    stream[2]=peek8u(mem+8)
    stream[3]=peek4u(mem+16)
    stream[4]=peek4u(mem+20)
    stream[5]=peek4u(mem+24)
return stream
end function


constant size_music=64
function poke_music(atom mem,sequence music)
atom dummy
dummy=poke_stream(mem,music[1])
    poke4(mem+32,music[2]) --framecount
    poke4(mem+36,music[3]) --bool looping
    poke4(mem+40,music[4])
    poke8(mem+44,music[5])
return mem
end function

global constant Tmusic = {{0,0,0,0,0},0,0,0,0}
function peek_music(atom mem)
sequence music=Tmusic
    music[1]=peek_stream(mem)
    music[2]=peek4u(mem+32) --framecount
    music[3]=peek(mem+36) -- bool looping
    music[4]=peek4s(mem+40)
    music[5]=peek8s(mem+44)
return music
end function

global constant Tsound={{0,0,0,0,0},0}
constant size_sound =40
function poke_sound(atom mem,sequence sound_)
atom dummy
dummy=poke_stream(mem,sound_[1])
      poke4(mem+32,sound_[2]) --framecount
return mem
end function

function peek_sound(atom mem)
sequence sound_=Tsound
    sound_[1]=peek_stream(mem)
    sound_[2]=peek4u(mem+32) --framecount
return sound_
end function


constant Tshader={0,0}
constant size_shader=16 
function poke_shader(atom mem, sequence shader)
    poke4(mem,shader[1])
    poke8(mem+8,shader[2])
    --?shader
return mem
end function

function peek_shader(atom mem)
sequence shader=Tshader
    shader[1]=peek4u(mem)
    shader[2]=peek8u(mem+8)
    --?shader
return shader
end function

constant Tfont={0,0,0,Ttexture,0,0}
constant size_font=64
function peek_font(atom mem)
sequence font=Tfont
        font[1]=peek4s(mem)
        font[2]=peek4s(mem+4)
        font[3]=peek4s(mem+8)
        font[4]=peek_texture(mem+12)
        font[5]=peek8u(mem+32) --44? 48? 52?
        font[6]=peek8u(mem+40)
return font
end function

function poke_font(atom mem,sequence font)
atom dummy
        poke4(mem,font[1])
        poke4(mem+4,font[2])
        poke4(mem+8,font[3])
dummy=  poke_texture(mem+12,font[4])
        poke8(mem+32,font[5])
        poke8(mem+40,font[6])
return mem
end function

constant size_matrix=64
constant Tmatrix={{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}}
function peek_matrix(atom mem)
sequence M=Tmatrix
-- Erste Zeile von M (Index 1)
M[1][1] = peek_float32(mem + 0)
M[1][2] = peek_float32(mem + 16)
M[1][3] = peek_float32(mem + 32)
M[1][4] = peek_float32(mem + 48)

-- Zweite Zeile von M (Index 2)
M[2][1] = peek_float32(mem + 4)
M[2][2] = peek_float32(mem + 20)
M[2][3] = peek_float32(mem + 36)
M[2][4] = peek_float32(mem + 52)

-- Dritte Zeile von M (Index 3)
M[3][1] = peek_float32(mem + 8)
M[3][2] = peek_float32(mem + 24)
M[3][3] = peek_float32(mem + 40)
M[3][4] = peek_float32(mem + 56)

-- Vierte Zeile von M (Index 4)
M[4][1] = peek_float32(mem + 12)
M[4][2] = peek_float32(mem + 28)
M[4][3] = peek_float32(mem + 44)
M[4][4] = peek_float32(mem + 60)
return M
end function


function poke_matrix(atom mem,sequence M)
    -- Spalte 1 (X-Achse)
poke_float32(mem + 0,  M[1][1])
poke_float32(mem + 4,  M[2][1])
poke_float32(mem + 8,  M[3][1])
poke_float32(mem + 12, M[4][1])

-- Spalte 2 (Y-Achse)
poke_float32(mem + 16, M[1][2])
poke_float32(mem + 20, M[2][2])
poke_float32(mem + 24, M[3][2])
poke_float32(mem + 28, M[4][2])

-- Spalte 3 (Z-Achse)
poke_float32(mem + 32, M[1][3])
poke_float32(mem + 36, M[2][3])
poke_float32(mem + 40, M[3][3])
poke_float32(mem + 44, M[4][3])

-- Spalte 4 (Translation/Position)
poke_float32(mem + 48, M[1][4])
poke_float32(mem + 52, M[2][4])
poke_float32(mem + 56, M[3][4])
poke_float32(mem + 60, M[4][4])
return mem
end function


global enum matmap_texture=1,matmap_color=2
constant size_materialmap=28 --28?
constant Tmaterialmap={Ttexture,{0,0,0,0},0}
global function peek_materialmap(atom mem)
sequence matmap=Tmaterialmap
    matmap[1]=peek_texture(mem)
    matmap[2]=peek({mem+20,4})
    matmap[3]=peek_float32(mem+24)
return matmap
end function

global function poke_materialmap(atom mem,sequence matmap)
atom dummy
    dummy=poke_texture(mem,matmap[1])
    poke(mem+20,matmap[2])
    poke_float32(mem+24,matmap[3])
return mem
end function

global enum mat_shader=1
constant size_material=40
constant Tmaterial={Tshader,0,0,0,0,0}
global function peek_material(atom mem)
sequence mat=Tmaterial
    mat[1]=peek_shader(mem)
    mat[2]=peek8u(mem+16) --pointer to materialmaps
    mat[3]=peek_float32(mem+24)
    mat[4]=peek_float32(mem+28)
    mat[5]=peek_float32(mem+32)
    mat[6]=peek_float32(mem+36)
return mat
end function

global function poke_material(atom mem,sequence mat)
atom dummy
    dummy=poke_shader(mem,mat[1])
    poke8(mem+16,mat[2])  -- pointer to materialmaps
    poke_float32(mem+24,mat[3])
    poke_float32(mem+28,mat[4])
    poke_float32(mem+32,mat[5])
    poke_float32(mem+36,mat[6])
return mem
end function

--model[10]=materials model[10][1] materialmaps model[10][1][2][1]=texture material 0 materialmap 0
global enum mod_materials=10,mod_materialmaps=2 
constant  size_model=120
constant Tmaterials={Tmaterial,repeat(Tmaterialmap,12)}
constant Tmodel={Tmatrix,0,0,0,0,0,0,0,0}
global function peek_model(atom mem)
    -- Holt die Rohdaten der Model-Struktur (64-Bit Layout)
    sequence model = {
        peek_matrix(mem),      -- [1] transform (64 Bytes)
        peek4s(mem + 64),      -- [2] meshCount (4 Bytes)
        peek4s(mem + 68),      -- [3] materialCount (4 Bytes)
        peek8u(mem + 72),      -- [4] meshes (Pointer, 8 Bytes)
        peek8u(mem + 80),      -- [5] materials (Pointer, 8 Bytes)
        peek8u(mem + 88),      -- [6] meshMaterial (Pointer, 8 Bytes)
        peek4s(mem + 96),      -- [7] boneCount (4 Bytes)
        peek8u(mem + 104),     -- [8] bones (Pointer, 8 Bytes)
        peek8u(mem + 112)      -- [9] bindPose (Pointer, 8 Bytes)
    }                           --[10] materials as a sequence
    
sequence materials=repeat(Tmaterials,model[3])
for i=1 to model[3] do
    materials[i][1]=peek_material(model[5]+((i-1)*size_material))
    for j=1 to 12  do
        materials[i][2][j]=peek_materialmap(materials[i][1][2]+((j-1)*size_materialmap))
    end for
end for
model =append(model,materials)
    return model
end function

global function poke_model(atom mem, sequence modl)
atom dummy
    -- mod = {matrix, meshCount, materialCount, pMeshes, pMaterials, pMeshMaterial, boneCount, pBones, pBindPose}
    
    -- 1. Die Matrix (belegt Offset 0 bis 63)
    dummy=poke_matrix(mem, modl[1])
    
    -- 2. Integers (4 Bytes)
    poke4(mem + 64, modl[2]) -- meshCount
    poke4(mem + 68, modl[3]) -- materialCount
    
    -- 3. Pointer (8 Bytes auf 64-Bit)
    poke8(mem + 72, modl[4]) -- meshes (pointer)
    poke8(mem + 80, modl[5]) -- materials (pointer)
    poke8(mem + 88, modl[6]) -- meshMaterial (pointer)
    
    -- 4. Animation / Bones
    poke4(mem + 96, modl[7])  -- boneCount (4 Bytes)
    -- Padding beachten: Raylib lässt oft 4 Bytes frei für 8-Byte Alignment des nächsten Pointers
    poke8(mem + 104, modl[8]) -- bones (pointer)
    poke8(mem + 112, modl[9]) -- bindPose (pointer)

sequence materials=modl[10]
atom addr
for i=1 to modl[3] do
    addr=(modl[5]+((i-1)*size_material))
    dummy=poke_material(addr,materials[i][1])
    for j=1 to 12  do
        dummy=poke_materialmap(materials[i][1][2]+((j-1)*size_materialmap),materials[i][2][j])
    end for
end for
return mem
end function

global sequence Tmesh=repeat(0,16)
constant size_mesh=120
global function peek_mesh(atom pMesh)
    -- pMesh: Pointer auf die Mesh-Struktur im RAM
    -- Rückgabe: Eine Sequence mit allen Mesh-Daten und Pointern
    
    sequence mesh = {
        peek4s(pMesh + 0),      -- [1] vertexCount
        peek4s(pMesh + 4),      -- [2] triangleCount
        
        -- Attribut-Pointer (8-Byte)
        peek8u(pMesh + 8),      -- [3] vertices (float*)
        peek8u(pMesh + 16),     -- [4] texcoords (float*)
        peek8u(pMesh + 24),     -- [5] texcoords2 (float*)
        peek8u(pMesh + 32),     -- [6] normals (float*)
        peek8u(pMesh + 40),     -- [7] tangents (float*)
        peek8u(pMesh + 48),     -- [8] colors (uchar*)
        peek8u(pMesh + 56),     -- [9] indices (ushort*)
        
        -- Animation / Skinning
        peek4s(pMesh + 64),     -- [10] boneCount (int)
        -- (+4 Bytes Padding hier, da der nächste Wert ein Pointer ist)
        peek8u(pMesh + 72),     -- [11] boneIndices (uchar*)
        peek8u(pMesh + 80),     -- [12] boneWeights (float*)
        
        -- CPU Skinning / AnimData
        peek8u(pMesh + 88),     -- [13] animVertices (float*)
        peek8u(pMesh + 96),     -- [14] animNormals (float*)
        
        -- Rendering IDs
        peek4u(pMesh + 104),    -- [15] vaoId (uint)
        -- (+4 Bytes Padding hier, da der nächste Wert ein Pointer ist)
        peek8u(pMesh + 112)     -- [16] vboId (uint* - Pointer auf ID-Array)
    }
    
    return mesh
end function

function poke_mesh(atom mem, sequence mesh)
    -- mesh = {vertexCount(1), triangleCount(2), vertices(3), texcoords(4), 
    --         texcoords2(5), normals(6), tangents(7), colors(8), indices(9), 
    --         boneCount(10), boneIndices(11), boneWeights(12), 
    --         animVertices(13), animNormals(14), vaoId(15), vboId(16)}

    poke4(mem + 0,  mesh[1])   -- vertexCount
    poke4(mem + 4,  mesh[2])   -- triangleCount
    
    -- Vertex attributes data (Pointer)
    poke8(mem + 8,  mesh[3])   -- vertices
    poke8(mem + 16, mesh[4])   -- texcoords
    poke8(mem + 24, mesh[5])   -- texcoords2
    poke8(mem + 32, mesh[6])   -- normals
    poke8(mem + 40, mesh[7])   -- tangents
    poke8(mem + 48, mesh[8])   -- colors
    poke8(mem + 56, mesh[9])   -- indices

    -- Skin data / Animation
    poke4(mem + 64, mesh[10])  -- boneCount (int)
    -- Offset 68 ist Padding (4 Bytes)
    poke8(mem + 72, mesh[11])  -- boneIndices (Pointer)
    poke8(mem + 80, mesh[12])  -- boneWeights (Pointer)

    -- CPU Skinning data
    poke8(mem + 88, mesh[13])  -- animVertices (Pointer)
    poke8(mem + 96, mesh[14])  -- animNormals (Pointer)

    -- OpenGL identifiers
    poke4(mem + 104, mesh[15]) -- vaoId (uint)
    -- Offset 108 ist Padding (4 Bytes)
    poke8(mem + 112, mesh[16]) -- vboId (uint* Pointer)

    return mem
end function


-- Helper (kind off a primitive state-manager) for GUI not in Raylib API handling for more Phix/Euphoria Style coding (less Pointer)
sequence ids={{0,allocate(8)}}
function get_addr_(atom id_) --get adress of allready existing ID
atom result
for i=1 to length(ids) 
do
    if (id_ = ids[i][1])
    then
        result = ids[i][2]
        exit
    else 
        result = -1
    end if  
end for
return result
end function

-- Sucht eine freie ID im Bereich [from, to]
function make_unique_id(integer from_id, integer to_id)
    integer candidate = from_id
    integer found
    while candidate <= to_id do
        found = 0
        for i = 1 to length(ids) do
            if ids[i][1] = candidate then
                found = 1
                exit -- ID belegt, brich innere Schleife ab
            end if
        end for
        if not found then
            return candidate -- Erste freie ID gefunden!
        end if
                candidate += 1
    end while
    return -1 -- Fehler: Bereich voll
end function


global function get_addr_float(sequence idval) -- Set Value in existing ID memory or create new ID and allocate memory return the adress
atom addr=get_addr_(idval[1])
if (addr>0) then
    poke(addr,atom_to_float32(idval[2]))
else
    ids=append(ids,{idval[1],allocate(8)})
    addr=get_addr_(idval[1])
    poke(addr,atom_to_float32(idval[2]))  -- for setting a start value
end if
return addr
end function

function get_addr_bool(sequence idval)
atom addr=get_addr_(idval[1])
if (addr>0) then
    poke4(addr,idval[2])
else
    ids=append(ids,{idval[1],allocate(8)})
    addr=get_addr_(idval[1])
    poke4(addr,idval[2])  -- for setting a start value
end if
return addr
end function

global function get_addr_int(sequence idval)
atom addr=get_addr_(idval[1])
if (addr>0) then
    poke4(addr,idval[2])
else
    ids=append(ids,{idval[1],allocate(8)})
    addr=get_addr_(idval[1])
    poke4(addr,idval[2])  -- for setting a start value
end if
return addr
end function

global function get_addr_string(sequence idval) -- aet the buffer to 1024
atom addr=get_addr_(idval[1])
atom dummy
if (addr>0) then
    dummy=poke_string(addr,1024,idval[2])
else
    ids=append(ids,{idval[1],allocate(1024)})
    addr=get_addr_(idval[1])
    dummy=poke_string(addr,1024,idval[2])  -- for setting a start value
end if
return addr
end function

constant musicid=6
function get_addr_music(sequence idval)
atom addr=get_addr_(idval[1])
if (addr>0) then
    return poke_music(addr,idval[2])
else
    ids=append(ids,{idval[1],allocate(size_music)})
    addr=get_addr_(idval[1])
    return poke_music(addr,idval[2])  -- for setting a start value
end if
--return addr
end function

constant shaderid=3
function get_addr_shader(sequence idval)
atom addr=get_addr_(idval[1])
if (addr>0) then
    return poke_shader(addr,idval[2])
else
    ids=append(ids,{idval[1],allocate(size_shader)})
    addr=get_addr_(idval[1])
    return poke_shader(addr,idval[2])  -- for setting a start value
end if
--return addr
end function


---------------------------------------------------------------------------------------------------------------
-- end little helper
--Colors
global constant LIGHTGRAY = {200,200,200,255},
                                GRAY      = {130,130,130,255},
                                DARKGRAY  = {80,80,80,255},
                                YELLOW    = {253,249,9,255},
                                GOLD      = {255,203,0,255},
                                ORANGE    = {255,161,0,255},
                                PINK      = {255,109,194,255},
                                RED       = {230,41,55,255},
                                MAROON    = {190,33,55,255},
                                GREEN     = {0,228,48,255},
                                LIME      = {0,158,47,255},
                                DARKGREEN = {0,117,44,255},
                                SKYBLUE   = {102,191,255,255},
                                BLUE      = {0,121,241,255},
                                DARKBLUE  = {0,82,172,255},
                                PURPLE    = {200,122,255,255},
                                VIOLET    = {135,60,190,255},
                                DARKPURPLE = {112,31,126,255},
                                BEIGE     = {211,176,131,255},
                                BROWN     = {127,106,79,255},
                                DARKBROWN = {76,63,47,255}
                                
global constant                 WHITE = {255,255,255,255},
                                BLACK = {0,0,0,255},
                                MAGENTA = {255,0,255,255},
                                RAYWHITE = {245,245,245,255},
                                BLANK = {0,0,0,0}

--Enums

global constant     FLAG_VSYNC_HINT         = 0x00000040,   --// Set to try enabling V-Sync on GPU
                    FLAG_FULLSCREEN_MODE    = 0x00000002,   --// Set to run program in fullscreen
                    FLAG_WINDOW_RESIZABLE   = 0x00000004,   --// Set to allow resizable window
                    FLAG_WINDOW_UNDECORATED = 0x00000008,   --// Set to disable window decoration (frame and buttons)
                    FLAG_WINDOW_HIDDEN      = 0x00000080,   --// Set to hide window
                    FLAG_WINDOW_MINIMIZED   = 0x00000200,   --// Set to minimize window (iconify)
                    FLAG_WINDOW_MAXIMIZED   = 0x00000400,   --// Set to maximize window (expanded to monitor)
                    FLAG_WINDOW_UNFOCUSED   = 0x00000800,   --// Set to window non focused
                    FLAG_WINDOW_TOPMOST     = 0x00001000,   --// Set to window always on top
                    FLAG_WINDOW_ALWAYS_RUN  = 0x00000100,   --// Set to allow windows running while minimized
                    FLAG_WINDOW_TRANSPARENT = 0x00000010,   --// Set to allow transparent framebuffer
                    FLAG_WINDOW_HIGHDPI     = 0x00002000,   --// Set to support HighDPI
                    FLAG_WINDOW_MOUSE_PASSTHROUGH = 0x00004000, --// Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED
                    FLAG_BORDERLESS_WINDOWED_MODE = 0x00008000, --// Set to run program in borderless windowed mode
                FLAG_MSAA_4X_HINT       = 0x00000020,   --// Set to try enabling MSAA 4X
                FLAG_INTERLACED_HINT    = 0x00010000


global enum LOG_ALL = 0,       -- // Display all logs
    LOG_TRACE,          --// Trace logging, intended for internal use only
    LOG_DEBUG,          --// Debug logging, used for internal debugging, it should be disabled on release builds
    LOG_INFO,           --// Info logging, used for program execution info
    LOG_WARNING,        --// Warning logging, used on recoverable failures
    LOG_ERROR,          --// Error logging, used on unrecoverable failures
    LOG_FATAL,          --// Fatal logging, used to abort program: exit(EXIT_FAILURE)
    LOG_NONE



global constant     KEY_NULL            = 0,       -- // Key: NULL, used for no key pressed
   -- // Alphanumeric keys
    KEY_APOSTROPHE      = 39,      -- // Key: '
    KEY_COMMA           = 44,      -- // Key: ,
    KEY_MINUS           = 45,      -- // Key: -
    KEY_PERIOD          = 46,      -- // Key: .
    KEY_SLASH           = 47,      -- // Key: /
    KEY_ZERO            = 48,      -- // Key: 0
    KEY_ONE             = 49,      -- // Key: 1
    KEY_TWO             = 50,      -- // Key: 2
    KEY_THREE           = 51,       --// Key: 3
    KEY_FOUR            = 52,       --// Key: 4
    KEY_FIVE            = 53,       --// Key: 5
    KEY_SIX             = 54,       --// Key: 6
    KEY_SEVEN           = 55,       --// Key: 7
    KEY_EIGHT           = 56,       --// Key: 8
    KEY_NINE            = 57,       --// Key: 9
    KEY_SEMICOLON       = 59,       --// Key: ;
    KEY_EQUAL           = 61,       --// Key: =
    KEY_A               = 65,       --// Key: A | a
    KEY_B               = 66,       --// Key: B | b
    KEY_C               = 67,       --// Key: C | c
    KEY_D               = 68,       --// Key: D | d
    KEY_E               = 69,       --// Key: E | e
    KEY_F               = 70,       --// Key: F | f
    KEY_G               = 71,       --// Key: G | g
    KEY_H               = 72,       --// Key: H | h
    KEY_I               = 73,       --// Key: I | i
    KEY_J               = 74,       --// Key: J | j
    KEY_K               = 75,       --// Key: K | k
    KEY_L               = 76,       --// Key: L | l
    KEY_M               = 77,       --// Key: M | m
    KEY_N               = 78,       --// Key: N | n
    KEY_O               = 79,       --// Key: O | o
    KEY_P               = 80,       --// Key: P | p
    KEY_Q               = 81,       --// Key: Q | q
    KEY_R               = 82,       --// Key: R | r
    KEY_S               = 83,       --// Key: S | s
    KEY_T               = 84,       --// Key: T | t
    KEY_U               = 85,       --// Key: U | u
    KEY_V               = 86,       --// Key: V | v
    KEY_W               = 87,       --// Key: W | w
    KEY_X               = 88,       --// Key: X | x
    KEY_Y               = 89,       --// Key: Y | y
    KEY_Z               = 90,       --// Key: Z | z
    KEY_LEFT_BRACKET    = 91,       --// Key: [
    KEY_BACKSLASH       = 92,       --// Key: '\'
    KEY_RIGHT_BRACKET   = 93,       --// Key: ]
    KEY_GRAVE           = 96,       --// Key: `
    --// Function keys
    KEY_SPACE           = 32,       --// Key: Space
    KEY_ESCAPE          = 256,      --// Key: Esc
    KEY_ENTER           = 257,      --// Key: Enter
    KEY_TAB             = 258,      --// Key: Tab
    KEY_BACKSPACE       = 259,      --// Key: Backspace
    KEY_INSERT          = 260,      --// Key: Ins
    KEY_DELETE          = 261,      --// Key: Del
    KEY_RIGHT           = 262,      --// Key: Cursor right
    KEY_LEFT            = 263,      --// Key: Cursor left
    KEY_DOWN            = 264,      --// Key: Cursor down
    KEY_UP              = 265,      --// Key: Cursor up
    KEY_PAGE_UP         = 266,      --// Key: Page up
    KEY_PAGE_DOWN       = 267,      --// Key: Page down
    KEY_HOME            = 268,      --// Key: Home
    KEY_END             = 269,      --// Key: End
    KEY_CAPS_LOCK       = 280,      --// Key: Caps lock
    KEY_SCROLL_LOCK     = 281,      --// Key: Scroll down
    KEY_NUM_LOCK        = 282,      --// Key: Num lock
    KEY_PRINT_SCREEN    = 283,      --// Key: Print screen
    KEY_PAUSE           = 284,      --// Key: Pause
    KEY_F1              = 290,      --// Key: F1
    KEY_F2              = 291,      --// Key: F2
    KEY_F3              = 292,      --// Key: F3
    KEY_F4              = 293,      --// Key: F4
    KEY_F5              = 294,      --// Key: F5
    KEY_F6              = 295,      --// Key: F6
    KEY_F7              = 296,      --// Key: F7
    KEY_F8              = 297,      --// Key: F8
    KEY_F9              = 298,      --// Key: F9
    KEY_F10             = 299,      --// Key: F10
    KEY_F11             = 300,      --// Key: F11
    KEY_F12             = 301,      --// Key: F12
    KEY_LEFT_SHIFT      = 340,      --// Key: Shift left
    KEY_LEFT_CONTROL    = 341,      --// Key: Control left
    KEY_LEFT_ALT        = 342,      --// Key: Alt left
    KEY_LEFT_SUPER      = 343,      --// Key: Super left
    KEY_RIGHT_SHIFT     = 344,      --// Key: Shift right
    KEY_RIGHT_CONTROL   = 345,      --// Key: Control right
    KEY_RIGHT_ALT       = 346,      --// Key: Alt right
    KEY_RIGHT_SUPER     = 347,      --// Key: Super right
    KEY_KB_MENU         = 348,      --// Key: KB menu
    --// Keypad keys
    KEY_KP_0            = 320,     -- // Key: Keypad 0
    KEY_KP_1            = 321,     -- // Key: Keypad 1
    KEY_KP_2            = 322,     -- // Key: Keypad 2
    KEY_KP_3            = 323,     -- // Key: Keypad 3
    KEY_KP_4            = 324,     -- // Key: Keypad 4
    KEY_KP_5            = 325,      --// Key: Keypad 5
    KEY_KP_6            = 326,      --// Key: Keypad 6
    KEY_KP_7            = 327,      --// Key: Keypad 7
    KEY_KP_8            = 328,      --// Key: Keypad 8
    KEY_KP_9            = 329,      --// Key: Keypad 9
    KEY_KP_DECIMAL      = 330,      --// Key: Keypad .
    KEY_KP_DIVIDE       = 331,      --// Key: Keypad /
    KEY_KP_MULTIPLY     = 332,      --// Key: Keypad *
    KEY_KP_SUBTRACT     = 333,      --// Key: Keypad -
    KEY_KP_ADD          = 334,      --// Key: Keypad +
    KEY_KP_ENTER        = 335,      --// Key: Keypad Enter
    KEY_KP_EQUAL        = 336,      --// Key: Keypad =
    --// Android key buttons
    KEY_BACK            = 4,       -- // Key: Android back button
    KEY_MENU            = 5,       -- // Key: Android menu button
    KEY_VOLUME_UP       = 24,      -- // Key: Android volume up button
    KEY_VOLUME_DOWN     = 25



global constant     MOUSE_BUTTON_LEFT    = 0,     --  // Mouse button left
    MOUSE_BUTTON_RIGHT   = 1,     --  // Mouse button right
    MOUSE_BUTTON_MIDDLE  = 2,      -- // Mouse button middle (pressed wheel)
    MOUSE_BUTTON_SIDE    = 3,       --// Mouse button side (advanced mouse device)
    MOUSE_BUTTON_EXTRA   = 4,       --// Mouse button extra (advanced mouse device)
    MOUSE_BUTTON_FORWARD = 5,       --// Mouse button forward (advanced mouse device)
    MOUSE_BUTTON_BACK    = 6


--backwards compatbility naming
global constant MOUSE_LEFT_BUTTON = MOUSE_BUTTON_LEFT
global constant MOUSE_RIGHT_BUTTON = MOUSE_BUTTON_RIGHT
global constant MOUSE_MIDDLE_BUTTON = MOUSE_BUTTON_MIDDLE

global constant     MOUSE_CURSOR_DEFAULT       = 0,    -- // Default pointer shape
    MOUSE_CURSOR_ARROW         = 1,    -- // Arrow shape
    MOUSE_CURSOR_IBEAM         = 2,    -- // Text writing cursor shape
    MOUSE_CURSOR_CROSSHAIR     = 3,    -- // Cross shape
    MOUSE_CURSOR_POINTING_HAND = 4,    -- // Pointing hand cursor
    MOUSE_CURSOR_RESIZE_EW     = 5,    -- // Horizontal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NS     = 6,    -- // Vertical resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NWSE   = 7,    -- // Top-left to bottom-right diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_NESW   = 8,    -- // The top-right to bottom-left diagonal resize/move arrow shape
    MOUSE_CURSOR_RESIZE_ALL    = 9,    -- // The omnidirectional resize/move cursor shape
    MOUSE_CURSOR_NOT_ALLOWED   = 10



global enum GAMEPAD_BUTTON_UNKNOWN = 0,        -- // Unknown button, just for error checking
    GAMEPAD_BUTTON_LEFT_FACE_UP,       -- // Gamepad left DPAD up button
    GAMEPAD_BUTTON_LEFT_FACE_RIGHT,    -- // Gamepad left DPAD right button
    GAMEPAD_BUTTON_LEFT_FACE_DOWN,     -- // Gamepad left DPAD down button
    GAMEPAD_BUTTON_LEFT_FACE_LEFT,     -- // Gamepad left DPAD left button
    GAMEPAD_BUTTON_RIGHT_FACE_UP,      -- // Gamepad right button up (i.e. PS3: Triangle, Xbox: Y)
    GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,   -- // Gamepad right button right (i.e. PS3: Circle, Xbox: B)
    GAMEPAD_BUTTON_RIGHT_FACE_DOWN,    -- // Gamepad right button down (i.e. PS3: Cross, Xbox: A)
    GAMEPAD_BUTTON_RIGHT_FACE_LEFT,     --// Gamepad right button left (i.e. PS3: Square, Xbox: X)
    GAMEPAD_BUTTON_LEFT_TRIGGER_1,      --// Gamepad top/back trigger left (first), it could be a trailing button
    GAMEPAD_BUTTON_LEFT_TRIGGER_2,      --// Gamepad top/back trigger left (second), it could be a trailing button
    GAMEPAD_BUTTON_RIGHT_TRIGGER_1,     --// Gamepad top/back trigger right (first), it could be a trailing button
    GAMEPAD_BUTTON_RIGHT_TRIGGER_2,     --// Gamepad top/back trigger right (second), it could be a trailing button
    GAMEPAD_BUTTON_MIDDLE_LEFT,         --// Gamepad center buttons, left one (i.e. PS3: Select)
    GAMEPAD_BUTTON_MIDDLE,              --// Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX)
    GAMEPAD_BUTTON_MIDDLE_RIGHT,        --// Gamepad center buttons, right one (i.e. PS3: Start)
    GAMEPAD_BUTTON_LEFT_THUMB,          --// Gamepad joystick pressed button left
    GAMEPAD_BUTTON_RIGHT_THUMB 



global enum     GAMEPAD_AXIS_LEFT_X        = 0,   --  // Gamepad left stick X axis
    GAMEPAD_AXIS_LEFT_Y        = 1,   --  // Gamepad left stick Y axis
    GAMEPAD_AXIS_RIGHT_X       = 2,    -- // Gamepad right stick X axis
    GAMEPAD_AXIS_RIGHT_Y       = 3,    -- // Gamepad right stick Y axis
    GAMEPAD_AXIS_LEFT_TRIGGER  = 4,    -- // Gamepad back trigger left, pressure level: [1..-1]
    GAMEPAD_AXIS_RIGHT_TRIGGER = 5



global enum     MATERIAL_MAP_ALBEDO = 0,      --  // Albedo material (same as: MATERIAL_MAP_DIFFUSE)
    MATERIAL_MAP_METALNESS,        -- // Metalness material (same as: MATERIAL_MAP_SPECULAR)
    MATERIAL_MAP_NORMAL,           -- // Normal material
    MATERIAL_MAP_ROUGHNESS,        -- // Roughness material
    MATERIAL_MAP_OCCLUSION,        -- // Ambient occlusion material
    MATERIAL_MAP_EMISSION,         -- // Emission material
    MATERIAL_MAP_HEIGHT,           -- // Heightmap material
    MATERIAL_MAP_CUBEMAP,          -- // Cubemap material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_IRRADIANCE,        --// Irradiance material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_PREFILTER,         --// Prefilter material (NOTE: Uses GL_TEXTURE_CUBE_MAP)
    MATERIAL_MAP_BRDF


global constant MATERIAL_MAP_DIFFUSE = MATERIAL_MAP_ALBEDO
global constant MATERIAL_MAP_SPECULAR = MATERIAL_MAP_METALNESS


global enum  SHADER_LOC_VERTEX_POSITION = 0, --// Shader location: vertex attribute: position
    SHADER_LOC_VERTEX_TEXCOORD01,  -- // Shader location: vertex attribute: texcoord01
    SHADER_LOC_VERTEX_TEXCOORD02,   --// Shader location: vertex attribute: texcoord02
    SHADER_LOC_VERTEX_NORMAL,       --// Shader location: vertex attribute: normal
    SHADER_LOC_VERTEX_TANGENT,      --// Shader location: vertex attribute: tangent
    SHADER_LOC_VERTEX_COLOR,        --// Shader location: vertex attribute: color
    SHADER_LOC_MATRIX_MVP,          --// Shader location: matrix uniform: model-view-projection
    SHADER_LOC_MATRIX_VIEW,         --// Shader location: matrix uniform: view (camera transform)
    SHADER_LOC_MATRIX_PROJECTION,   --// Shader location: matrix uniform: projection
    SHADER_LOC_MATRIX_MODEL,        --// Shader location: matrix uniform: model (transform)
    SHADER_LOC_MATRIX_NORMAL,       --// Shader location: matrix uniform: normal
    SHADER_LOC_VECTOR_VIEW,         --// Shader location: vector uniform: view
    SHADER_LOC_COLOR_DIFFUSE,       --// Shader location: vector uniform: diffuse color
    SHADER_LOC_COLOR_SPECULAR,      --// Shader location: vector uniform: specular color
    SHADER_LOC_COLOR_AMBIENT,       --// Shader location: vector uniform: ambient color
    SHADER_LOC_MAP_ALBEDO,          --// Shader location: sampler2d texture: albedo (same as: SHADER_LOC_MAP_DIFFUSE)
    SHADER_LOC_MAP_METALNESS,       --// Shader location: sampler2d texture: metalness (same as: SHADER_LOC_MAP_SPECULAR)
    SHADER_LOC_MAP_NORMAL,          --// Shader location: sampler2d texture: normal
    SHADER_LOC_MAP_ROUGHNESS,       --// Shader location: sampler2d texture: roughness
    SHADER_LOC_MAP_OCCLUSION,       --// Shader location: sampler2d texture: occlusion
    SHADER_LOC_MAP_EMISSION,        --// Shader location: sampler2d texture: emission
    SHADER_LOC_MAP_HEIGHT,          --// Shader location: sampler2d texture: height
    SHADER_LOC_MAP_CUBEMAP,         --// Shader location: samplerCube texture: cubemap
    SHADER_LOC_MAP_IRRADIANCE,      --// Shader location: samplerCube texture: irradiance
    SHADER_LOC_MAP_PREFILTER,       --// Shader location: samplerCube texture: prefilter
    SHADER_LOC_MAP_BRDF,            --// Shader location: sampler2d texture: brdf
    SHADER_LOC_VERTEX_BONEIDS,      --// Shader location: vertex attribute: boneIds
    SHADER_LOC_VERTEX_BONEWEIGHTS,  --// Shader location: vertex attribute: boneWeights
    SHADER_LOC_BONE_MATRICES


global constant SHADER_LOC_MAP_DIFFUSE = SHADER_LOC_MAP_ALBEDO
global constant SHADER_LOC_MAP_SPECULAR = SHADER_LOC_MAP_METALNESS


global enum  SHADER_UNIFORM_FLOAT = 0,   --    // Shader uniform type: float
    SHADER_UNIFORM_VEC2,          --  // Shader uniform type: vec2 (2 float)
    SHADER_UNIFORM_VEC3,           -- // Shader uniform type: vec3 (3 float)
    SHADER_UNIFORM_VEC4,           -- // Shader uniform type: vec4 (4 float)
    SHADER_UNIFORM_INT,            -- // Shader uniform type: int
    SHADER_UNIFORM_IVEC2,          -- // Shader uniform type: ivec2 (2 int)
    SHADER_UNIFORM_IVEC3,          -- // Shader uniform type: ivec3 (3 int)
    SHADER_UNIFORM_IVEC4,           --// Shader uniform type: ivec4 (4 int)
    SHADER_UNIFORM_SAMPLER2D



global enum  SHADER_ATTRIB_FLOAT = 0,    --    // Shader attribute type: float
    SHADER_ATTRIB_VEC2,           --  // Shader attribute type: vec2 (2 float)
    SHADER_ATTRIB_VEC3,            -- // Shader attribute type: vec3 (3 float)
    SHADER_ATTRIB_VEC4 



global enum     PIXELFORMAT_UNCOMPRESSED_GRAYSCALE = 1, --// 8 bit per pixel (no alpha)
    PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,    --// 8*2 bpp (2 channels)
    PIXELFORMAT_UNCOMPRESSED_R5G6B5,        --// 16 bpp
    PIXELFORMAT_UNCOMPRESSED_R8G8B8,        --// 24 bpp
    PIXELFORMAT_UNCOMPRESSED_R5G5B5A1,      --// 16 bpp (1 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R4G4B4A4,      --// 16 bpp (4 bit alpha)
    PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,      --// 32 bpp
    PIXELFORMAT_UNCOMPRESSED_R32,           --// 32 bpp (1 channel - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32,     --// 32*3 bpp (3 channels - float)
    PIXELFORMAT_UNCOMPRESSED_R32G32B32A32,  --// 32*4 bpp (4 channels - float)
    PIXELFORMAT_UNCOMPRESSED_R16,           --// 16 bpp (1 channel - half float)
    PIXELFORMAT_UNCOMPRESSED_R16G16B16,     --// 16*3 bpp (3 channels - half float)
    PIXELFORMAT_UNCOMPRESSED_R16G16B16A16,  --// 16*4 bpp (4 channels - half float)
    PIXELFORMAT_COMPRESSED_DXT1_RGB,        --// 4 bpp (no alpha)
    PIXELFORMAT_COMPRESSED_DXT1_RGBA,       --// 4 bpp (1 bit alpha)
    PIXELFORMAT_COMPRESSED_DXT3_RGBA,       --// 8 bpp
    PIXELFORMAT_COMPRESSED_DXT5_RGBA,       --// 8 bpp
    PIXELFORMAT_COMPRESSED_ETC1_RGB,        --// 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_RGB,        --// 4 bpp
    PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA,  -- // 8 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGB,       -- // 4 bpp
    PIXELFORMAT_COMPRESSED_PVRT_RGBA,       --// 4 bpp
    PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA,   --// 8 bpp
    PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA



global enum     TEXTURE_FILTER_POINT = 0,           --    // No filter, just pixel approximation
    TEXTURE_FILTER_BILINEAR,             --   // Linear filtering
    TEXTURE_FILTER_TRILINEAR,             --  // Trilinear filtering (linear with mipmaps)
    TEXTURE_FILTER_ANISOTROPIC_4X,         -- // Anisotropic filtering 4x
    TEXTURE_FILTER_ANISOTROPIC_8X,         -- // Anisotropic filtering 8x
    TEXTURE_FILTER_ANISOTROPIC_16X


global enum     TEXTURE_WRAP_REPEAT = 0,            --    // Repeats texture in tiled mode
    TEXTURE_WRAP_CLAMP,                  --   // Clamps texture to edge pixel in tiled mode
    TEXTURE_WRAP_MIRROR_REPEAT,           --  // Mirrors and repeats the texture in tiled mode
    TEXTURE_WRAP_MIRROR_CLAMP



global enum CUBEMAP_LAYOUT_AUTO_DETECT = 0,       --  // Automatically detect layout type
    CUBEMAP_LAYOUT_LINE_VERTICAL,         --  // Layout is defined by a vertical line with faces
    CUBEMAP_LAYOUT_LINE_HORIZONTAL,        -- // Layout is defined by a horizontal line with faces
    CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR,    -- // Layout is defined by a 3x4 cross with cubemap faces
    CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE



global enum FONT_DEFAULT = 0,            --    // Default font generation, anti-aliased
            FONT_BITMAP,             --       // Bitmap font generation, no anti-aliasing
            FONT_SDF



global enum      BLEND_ALPHA = 0,          --      // Blend textures considering alpha (default)
    BLEND_ADDITIVE,             --    // Blend textures adding colors
    BLEND_MULTIPLIED,            --   // Blend textures multiplying colors
    BLEND_ADD_COLORS,             --  // Blend textures adding colors (alternative)
    BLEND_SUBTRACT_COLORS,         -- // Blend textures subtracting colors (alternative)
    BLEND_ALPHA_PREMULTIPLY,       -- // Blend premultiplied textures considering alpha
    BLEND_CUSTOM,                  -- // Blend textures using custom src/dst factors (use rlSetBlendFactors())
    BLEND_CUSTOM_SEPARATE



global enum GESTURE_NONE         = 0,    --    // No gesture
    GESTURE_TAP         = 1,      --  // Tap gesture
    GESTURE_DOUBLETAP   = 2,       -- // Double tap gesture
    GESTURE_HOLD        = 4,        --// Hold gesture
    GESTURE_DRAG        = 8,        --// Drag gesture
    GESTURE_SWIPE_RIGHT = 16,       --// Swipe right gesture
    GESTURE_SWIPE_LEFT  = 32,       --// Swipe left gesture
    GESTURE_SWIPE_UP    = 64,       --// Swipe up gesture
    GESTURE_SWIPE_DOWN  = 128,     -- // Swipe down gesture
    GESTURE_PINCH_IN    = 256,      --// Pinch in gesture
    GESTURE_PINCH_OUT   = 512



global enum CAMERA_CUSTOM = 0,        --      // Camera custom, controlled by user (UpdateCamera() does nothing)
    CAMERA_FREE,               --     // Camera free mode
    CAMERA_ORBITAL,             --    // Camera orbital, around target, zoom supported
    CAMERA_FIRST_PERSON,         --   // Camera first person
    CAMERA_THIRD_PERSON



global constant      CAMERA_PERSPECTIVE = 0,   --     // Perspective projection
                     CAMERA_ORTHOGRAPHIC =1



global constant     NPATCH_NINE_PATCH = 0,        --  // Npatch layout: 3x3 tiles
                    NPATCH_THREE_PATCH_VERTICAL =1,   -- // Npatch layout: 1x3 tiles
                    NPATCH_THREE_PATCH_HORIZONTAL=2


--Callbacks TODO

--Window Functions
constant xInitWindow = define_c_proc(ray,"+InitWindow",{C_INT,C_INT,C_STRING}),
                                xCloseWindow = define_c_proc(ray,"+CloseWindow",{}),
                                xWindowShouldClose = define_c_func(ray,"+WindowShouldClose",{},C_BOOL),
                                xIsWindowReady = define_c_func(ray,"+IsWindowReady",{},C_BOOL),
                                xIsWindowFullscreen = define_c_func(ray,"+IsWindowFullscreen",{},C_BOOL),
                                xIsWindowHidden = define_c_func(ray,"+IsWindowHidden",{},C_BOOL),
                                xIsWindowMinimized = define_c_func(ray,"+IsWindowMinimized",{},C_BOOL),
                                xIsWindowMaximized = define_c_func(ray,"+IsWindowMaximized",{},C_BOOL),
                                xIsWindowFocused = define_c_func(ray,"+IsWindowFocused",{},C_BOOL),
                                xIsWindowResized = define_c_func(ray,"+IsWindowResized",{},C_BOOL),
                                xIsWindowState = define_c_func(ray,"+IsWindowState",{C_UINT},C_BOOL),
                                xSetWindowState = define_c_proc(ray,"+SetWindowState",{C_UINT}),
                                xClearWindowState = define_c_proc(ray,"+ClearWindowState",{C_UINT}),
                                xToggleFullscreen = define_c_proc(ray,"+ToggleFullscreen",{}),
                                xToggleBorderlessWindowed = define_c_proc(ray,"+ToggleBorderlessWindowed",{}),
                                xMaximizeWindow = define_c_proc(ray,"+MaximizeWindow",{}),
                                xMinimizeWindow = define_c_proc(ray,"+MinimizeWindow",{}),
                                xRestoreWindow = define_c_proc(ray,"+RestoreWindow",{}),
                                xSetWindowIcon = define_c_proc(ray,"SetWindowIcon",{Image}),
                                xSetWindowIcons = define_c_proc(ray,"+SetWindowIcons",{C_POINTER,C_INT}),
                                xSetWindowTitle = define_c_proc(ray,"+SetWindowTitle",{C_STRING}),
                                xSetWindowPosition = define_c_proc(ray,"+SetWindowPosition",{C_INT,C_INT}),
                                xSetWindowMonitor = define_c_proc(ray,"+SetWindowMonitor",{C_INT}),
                                xSetWindowMinSize = define_c_proc(ray,"+SetWindowMinSize",{C_INT,C_INT}),
                                xSetWindowMaxSize = define_c_proc(ray,"+SetWindowMaxSize",{C_INT,C_INT}),
                                xSetWindowSize = define_c_proc(ray,"+SetWindowSize",{C_INT,C_INT}),
                                xSetWindowOpacity = define_c_proc(ray,"+SetWindowOpacity",{C_FLOAT}),
                                xSetWindowFocused = define_c_proc(ray,"+SetWindowFocused",{}),
                                xGetWindowHandle = define_c_func(ray,"+GetWindowHandle",{},C_POINTER),
                                xGetScreenWidth = define_c_func(ray,"+GetScreenWidth",{},C_INT),
                                xGetScreenHeight = define_c_func(ray,"+GetScreenHeight",{},C_INT),
                                xGetRenderWidth = define_c_func(ray,"+GetRenderWidth",{},C_INT),
                                xGetRenderHeight = define_c_func(ray,"+GetRenderHeight",{},C_INT),
                                xGetMonitorCount = define_c_func(ray,"+GetMonitorCount",{},C_INT),
                                xGetCurrentMonitor = define_c_func(ray,"+GetCurrentMonitor",{},C_INT),
                                xGetMonitorPosition = define_c_func(ray,"+GetMonitorPosition",{C_INT},Vector2),
                                xGetMonitorWidth = define_c_func(ray,"+GetMonitorWidth",{C_INT},C_INT),
                                xGetMonitorHeight = define_c_func(ray,"+GetMonitorHeight",{C_INT},C_INT),
                                xGetMonitorPhysicalWidth = define_c_func(ray,"+GetMonitorPhysicalWidth",{C_INT},C_INT),
                                xGetMonitorPhysicalHeight = define_c_func(ray,"+GetMonitorPhysicalHeight",{C_INT},C_INT),
                                xGetMonitorRefreshRate = define_c_func(ray,"+GetMonitorRefreshRate",{C_INT},C_INT),
                                xGetWindowPosition = define_c_func(ray,"+GetWindowPosition",{},Vector2),
                                xGetWindowScaleDPI = define_c_func(ray,"+GetWindowScaleDPI",{},Vector2),
                                xGetMonitorName = define_c_func(ray,"+GetMonitorName",{C_INT},C_STRING),
                                xSetClipboardText = define_c_proc(ray,"+SetClipboardText",{C_STRING}),
                                xGetClipboardText = define_c_func(ray,"+GetClipboardText",{},C_STRING),
                                xGetClipboardImage = define_c_func(ray,"+GetClipboardImage",{C_HPTR},Image),
                                xEnableEventWaiting = define_c_proc(ray,"+EnableEventWaiting",{}),
                                xDisableEventWaiting = define_c_proc(ray,"+DisableEventWaiting",{})

global procedure InitWindow(atom width,atom height,sequence title)
atom pstr=allocate_string(title)
        c_proc(xInitWindow,{width,height,pstr})
free(pstr)
end procedure

global procedure CloseWindow()
        c_proc(xCloseWindow,{})
end procedure

global function WindowShouldClose()
        return c_func(xWindowShouldClose,{})
end function

global function IsWindowReady()
        return c_func(xIsWindowReady,{})
end function

global function IsWindowFullscreen()
        return c_func(xIsWindowFullscreen,{})
end function

global function IsWindowHidden()
        return c_func(xIsWindowHidden,{})
end function

global function IsWindowMinimized()
        return c_func(xIsWindowMinimized,{})
end function

global function IsWindowMaximized()
        return c_func(xIsWindowMaximized,{})
end function

global function IsWindowFocused()
        return c_func(xIsWindowFocused,{})
end function

global function IsWindowResized()
        return c_func(xIsWindowResized,{})
end function

global function IsWindowState(atom flag)
        return c_func(xIsWindowState,{flag})
end function

global procedure SetWindowState(atom flags)
        c_proc(xSetWindowState,{flags})
end procedure

global procedure ClearWindowState(atom flags)
        c_proc(xClearWindowState,{flags})
end procedure

global procedure ToggleFullscreen()
        c_proc(xToggleFullscreen,{})
end procedure

global procedure ToggleBorderlessWindowed()
        c_proc(xToggleBorderlessWindowed,{})
end procedure

global procedure MaximizeWindow()
        c_proc(xMaximizeWindow,{})
end procedure

global procedure MinimizeWindow()
        c_proc(xMinimizeWindow,{})
end procedure

global procedure RestoreWindow()
        c_proc(xRestoreWindow,{})
end procedure

global procedure SetWindowIcon(sequence image)
atom mem=allocate(24)
poke8(mem,image[1])
poke4(mem+8,image[2])
poke4(mem+12,image[3])
poke4(mem+16,image[4])
poke4(mem+20,image[5])
        c_proc(xSetWindowIcon,{image})
end procedure

--CHECK images should be a Pointer to an array[1..count] of images
global procedure SetWindowIcons(atom images,atom count)
        c_proc(xSetWindowIcons,{images,count})
end procedure

global procedure SetWindowTitle(sequence title)
atom pstr=allocate_string(title)
        c_proc(xSetWindowTitle,{title})
free(pstr)
end procedure

global procedure SetWindowPosition(atom x,atom y)
        c_proc(xSetWindowPosition,{x,y})
end procedure

global procedure SetWindowMonitor(atom monitor)
        c_proc(xSetWindowMonitor,{monitor})
end procedure

global procedure SetWindowMinSize(atom width,atom height)
        c_proc(xSetWindowMinSize,{width,height})
end procedure

global procedure SetWindowMaxSize(atom width,atom height)
        c_proc(xSetWindowMaxSize,{width,height})
end procedure

global procedure SetWindowSize(atom width,atom height)
        c_proc(xSetWindowSize,{width,height})
end procedure

global procedure SetWindowOpacity(atom opacity)
        c_proc(xSetWindowOpacity,{opacity})
end procedure

global procedure SetWindowFocused()
        c_proc(xSetWindowFocused,{})
end procedure

global function GetWindowHandle()
        return c_func(xGetWindowHandle,{})
end function

global function GetScreenWidth()
        return c_func(xGetScreenWidth,{})
end function

global function GetScreenHeight()
        return c_func(xGetScreenHeight,{})
end function

global function GetRenderWidth()
        return c_func(xGetRenderWidth,{})
end function

global function GetRenderHeight()
        return c_func(xGetRenderHeight,{})
end function

global function GetMonitorCount()
        return c_func(xGetMonitorCount,{})
end function

global function GetCurrentMonitor()
        return c_func(xGetCurrentMonitor,{})
end function

global function GetMonitorPosition(atom monitor)
        return RegtoV2(c_func(xGetMonitorPosition,{monitor}))
end function

global function GetMonitorWidth(atom monitor)
        return c_func(xGetMonitorWidth,{monitor})
end function

global function GetMonitorHeight(atom monitor)
        return c_func(xGetMonitorHeight,{monitor})
end function

global function GetMonitorPhysicalWidth(atom monitor)
        return c_func(xGetMonitorPhysicalWidth,{monitor})
end function

global function GetMonitorPhysicalHeight(atom monitor)
        return c_func(xGetMonitorPhysicalHeight,{monitor})
end function

global function GetMonitorRefreshRate(atom monitor)
        return c_func(xGetMonitorRefreshRate,{monitor})
end function

global function GetWindowPosition()
        return RegtoV2(c_func(xGetWindowPosition,{}))
end function

global function GetWindowScaleDPI()
        return RegtoV2(c_func(xGetWindowScaleDPI,{}))
end function

-- CHECK
global function GetMonitorName(atom monitor)
        return peek_string(c_func(xGetMonitorName,{monitor})) -- UTF-8 hopefully it works
end function

global procedure SetClipboardText(sequence text)
--if not length(text) then
--  return
--end if
atom pstr = allocate_string(text)
        c_proc(xSetClipboardText,{pstr})
free(pstr)
end procedure

global function GetClipboardText()
atom pstr
        pstr= c_func(xGetClipboardText,{})
        return peek_string(pstr)
end function

global function GetClipboardImage()
atom mem=allocate(24)
atom erg
sequence result={0,0,0,0,0}
        erg = c_func(xGetClipboardImage,{mem})
if not equal(mem,erg) then
    crash("Something ugly in : GetClipboardText")
end if
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global procedure EnableEventWaiting()
        c_proc(xEnableEventWaiting,{})
end procedure

global procedure DisableEventWaiting()
        c_proc(xDisableEventWaiting,{})
end procedure

--Cursor functions

global constant xShowCursor = define_c_proc(ray,"+ShowCursor",{}),
                                xHideCursor = define_c_proc(ray,"+HideCursor",{}),
                                xIsCursorHidden = define_c_func(ray,"+IsCursorHidden",{},C_BOOL),
                                xEnableCursor = define_c_proc(ray,"+EnableCursor",{}),
                                xDisableCursor = define_c_proc(ray,"+DisableCursor",{}),
                                xIsCursorOnScreen = define_c_func(ray,"+IsCursorOnScreen",{},C_BOOL)
                                
global procedure ShowCursor()
        c_proc(xShowCursor,{})
end procedure

global procedure HideCursor()
        c_proc(xHideCursor,{})
end procedure

global function IsCursorHidden()
        return c_func(xIsCursorHidden,{})
end function

global procedure EnableCursor()
        c_proc(xEnableCursor,{})
end procedure

global procedure DisableCursor()
        c_proc(xDisableCursor,{})
end procedure

global function IsCursorOnScreen()
        return c_func(xIsCursorOnScreen,{})
end function

--Drawing Functions

constant xClearBackground = define_c_proc(ray,"+ClearBackground",{C_Color}),
                                xBeginDrawing = define_c_proc(ray,"+BeginDrawing",{}),
                                xEndDrawing = define_c_proc(ray,"+EndDrawing",{}),
                                xBeginMode2D = define_c_proc(ray,"+BeginMode2D",{Camera2D}),
                                xEndMode2D = define_c_proc(ray,"+EndMode2D",{}),
                                xBeginMode3D = define_c_proc(ray,"+BeginMode3D",{Camera3D}),
                                xEndMode3D = define_c_proc(ray,"+EndMode3D",{}),
                                xBeginTextureMode = define_c_proc(ray,"+BeginTextureMode",{RenderTexture2D}),
                                xEndTextureMode = define_c_proc(ray,"+EndTextureMode",{}),
                                xBeginShaderMode = define_c_proc(ray,"+BeginShaderMode",{Shader}),
                                xEndShaderMode = define_c_proc(ray,"+EndShaderMode",{}),
                                xBeginBlendMode = define_c_proc(ray,"+BeginBlendMode",{C_INT}),
                                xEndBlendMode = define_c_proc(ray,"+EndBlendMode",{}),
                                xBeginScissorMode = define_c_proc(ray,"+BeginScissorMode",{C_INT,C_INT,C_INT,C_INT}),
                                xEndScissorMode = define_c_proc(ray,"+EndScissorMode",{}),
                                xBeginVrStereoMode = define_c_proc(ray,"+BeginVrStereoMode",{VrStereoConfig}),
                                xEndVrStereoMode = define_c_proc(ray,"+EndVrStereoMode",{})
                                
global procedure ClearBackground(sequence color)
        c_proc(xClearBackground,{bytes_to_int(color)})
end procedure

global procedure BeginDrawing()
        c_proc(xBeginDrawing,{})
end procedure

global procedure EndDrawing()
        c_proc(xEndDrawing,{})
end procedure

global procedure BeginMode2D(sequence camera2D)
atom mem=allocate(size_camera2d)
        c_proc(xBeginMode2D,{poke_camera2d(mem,camera2D)})
free(mem)
end procedure

global procedure EndMode2D()
        c_proc(xEndMode2D,{})
end procedure

global procedure BeginMode3D(sequence camera3D)
atom mem=allocate(size_camera3d)
        c_proc(xBeginMode3D,{poke_camera3d(mem,camera3D)})
free(mem)
end procedure

global procedure EndMode3D()
        c_proc(xEndMode3D,{})
end procedure
--CHECK
global procedure BeginTextureMode(sequence target)
atom addr=allocate(size_rendertexture)
        c_proc(xBeginTextureMode,{poke_rendertexture(addr,target)}) --target is RenderTexture2D
free(addr)
end procedure

global procedure EndTextureMode()
        c_proc(xEndTextureMode,{})
end procedure
--CHECK
global procedure BeginShaderMode(sequence shader)
--atom mem=allocate(size_shader)
        c_proc(xBeginShaderMode,{get_addr_shader({shader[3],shader})})
--free(mem)
end procedure

global procedure EndShaderMode()
        c_proc(xEndShaderMode,{})
end procedure

global procedure BeginBlendMode(atom mode)
        c_proc(xBeginBlendMode,{mode})
end procedure

global procedure EndBlendMode()
        c_proc(xEndBlendMode,{})
end procedure

global procedure BeginScissorMode(atom x,atom y,atom width,atom height)
        c_proc(xBeginScissorMode,{x,y,width,height})
end procedure

global procedure EndScissorMode()
        c_proc(xEndScissorMode,{})
end procedure
--CHECK
global procedure BeginVrStereoMode(sequence config)
        c_proc(xBeginVrStereoMode,{config}) --config is VrStereoConfig
end procedure

global procedure EndVrStereoMode()
        c_proc(xEndVrStereoMode,{})
end procedure
--CHECK
--VR Stereo config functions
global constant xLoadVrStereoConfig = define_c_func(ray,"+LoadVrStereoConfig",{VrDeviceInfo},VrStereoConfig),
                                xUnloadVrStereoConfig = define_c_proc(ray,"+UnloadVrStereoConfig",{VrStereoConfig})
                                
global function LoadVrStereoConfig(sequence device)
        return c_func(xLoadVrStereoConfig,{device}) --device is VrDeviceInfo
end function

global procedure UnloadVrStereoConfig(sequence config)
        c_proc(xUnloadVrStereoConfig,{config}) --config is VrStereoConfig
end procedure

--Shader functions
constant xLoadShader = define_c_func(ray,"+LoadShader",{C_HPTR,C_STRING,C_STRING},Shader),
                                xLoadShaderFromMemory = define_c_func(ray,"+LoadShaderFromMemory",{C_STRING,C_STRING},Shader),
                                xIsShaderValid = define_c_func(ray,"+IsShaderValid",{Shader},C_BOOL),
                                xGetShaderLocation = define_c_func(ray,"+GetShaderLocation",{Shader,C_STRING},C_INT),
                                xGetShaderLocationAttrib = define_c_func(ray,"+GetShaderLocationAttrib",{Shader,C_STRING},C_INT),
                                xSetShaderValue = define_c_proc(ray,"+SetShaderValue",{Shader,C_INT,C_POINTER,C_INT}),
                                xSetShaderValueV = define_c_proc(ray,"+SetShaderValueV",{Shader,C_INT,C_POINTER,C_INT,C_INT}),
                                xSetShaderValueMatrix = define_c_proc(ray,"+SetShaderValueMatrix",{Shader,C_INT,Matrix}),
                                xSetShaderValueTexture = define_c_proc(ray,"+SetShaderValueTexture",{Shader,C_INT,Texture2D}),
                                xUnloadShader = define_c_proc(ray,"+UnloadShader",{Shader})
                                
global function LoadShader(object  vsFileName,object  fsFileName)
atom id=allocate(8)
sequence shader=Tshader
atom mem=get_addr_shader({id,shader})
atom ptr

if atom(vsFileName) 
then
    vsFileName=0
else
    vsFileName=allocate_string(vsFileName)
end if
if atom(fsFileName) 
then
    fsFileName=0
else
    fsFileName=allocate_string(fsFileName)
end if
        ptr= c_func(xLoadShader,{mem,vsFileName,fsFileName})
shader=peek_shader(ptr)
if vsFileName then
    free(vsFileName)
end if
if fsFileName then
    free(fsFileName)
end if
shader=append(shader,mem)
return shader
end function

global function LoadShaderFromMemory(sequence vsCode,sequence fsCode)
        return c_func(xLoadShaderFromMemory,{vsCode,fsCode})
end function

global function IsShaderValid(sequence shader)
atom addr=get_addr_shader({shader[3],shader})
        return c_func(xIsShaderValid,{addr})
end function

global function GetShaderLocation(sequence shader,sequence uniformName)
atom addr=get_addr_shader({shader[3],shader})
atom pstr=allocate_string(uniformName)
atom result
        result= c_func(xGetShaderLocation,{addr,pstr})
free(pstr)
return result
end function

global function GetShaderLocationAttrib(sequence shader,sequence attribName)
        return c_func(xGetShaderLocationAttrib,{shader,attribName})
end function

global procedure SetShaderValue(sequence shader,atom locIndex,object val,atom uniformType)
atom addr=get_addr_shader({shader[3],shader})
atom val1
if atom (val) 
then
    val1=allocate(8)
    if not(uniformType) --SHADER_UNIFORM_FLOAT = 0
    then
        poke(val1,atom_to_float32(val))
    else
        poke4(val1,val)
    end if
else
    val1=allocate(4*length(val))
    if uniformType=SHADER_UNIFORM_VEC2 then
        poke(val1,atom_to_float32(val[1]))
        poke(val1+4,atom_to_float32(val[2]))
    elsif uniformType=SHADER_UNIFORM_VEC3 then
        poke(val1,atom_to_float32(val[1]))
        poke(val1+4,atom_to_float32(val[2]))
        poke(val1+8,atom_to_float32(val[3]))
    elsif uniformType=SHADER_UNIFORM_VEC4 then
        poke(val1,atom_to_float32(val[1]))
        poke(val1+4,atom_to_float32(val[2]))
        poke(val1+8,atom_to_float32(val[3]))
        poke(val1+12,atom_to_float32(val[4]))
    elsif uniformType=SHADER_UNIFORM_IVEC2 then
        poke4(val1,val[1])
        poke4(val1+4,val[2])
    elsif uniformType=SHADER_UNIFORM_IVEC3 then
        poke4(val1,val[1])
        poke4(val1+4,val[2])
        poke4(val1+8,val[3])
    elsif uniformType=SHADER_UNIFORM_IVEC4 then
        poke4(val1,val[1])
        poke4(val1+4,val[2])
        poke4(val1+8,val[3])
        poke4(val1+12,val[4])
    end if  
end if
        c_proc(xSetShaderValue,{addr,locIndex,val1,uniformType})
free(val1)
end procedure

global procedure SetShaderValueV(sequence shader,atom locIndex,object val,atom uniformType,atom count)
        c_proc(xSetShaderValueV,{shader,locIndex,val,uniformType,count})
end procedure

global procedure SetShaderValueMatrix(sequence shader,atom locIndex,sequence mat)
        c_proc(xSetShaderValueMatrix,{shader,locIndex,mat})
end procedure

global procedure SetShaderValueTexture(sequence shader,atom locIndex,sequence texture)
atom addr=get_addr_shader({shader[3],shader})
atom mem=allocate(size_texture)
        c_proc(xSetShaderValueTexture,{addr,locIndex,poke_texture(mem,texture)})
free(mem)
end procedure

global procedure UnloadShader(sequence shader)
atom addr=get_addr_shader({shader[3],shader})
        c_proc(xUnloadShader,{addr})
free(shader[3])
free(addr)
end procedure

--Screen space functions
constant xGetScreenToWorldRay = define_c_func(ray,"+GetScreenToWorldRay",{Vector2,Camera},Ray),
                                xGetScreenToWorldRayEx = define_c_func(ray,"+GetScreenToWorldRayEx",{Vector2,Camera,C_INT,C_INT},Ray),
                                xGetWorldToScreen = define_c_func(ray,"+GetWorldToScreen",{Vector3,Camera},Vector2),
                                xGetWorldToScreenEx = define_c_func(ray,"+GetWorldToScreenEx",{Vector3,Camera,C_INT,C_INT},Vector2),
                                xGetWorldToScreen2D = define_c_func(ray,"+GetWorldToScreen2D",{Vector2,Camera2D},Vector2),
                                xGetScreenToWorld2D = define_c_func(ray,"+GetScreenToWorld2D",{Vector2,Camera2D},Vector2),
                                xGetCameraMatrix = define_c_func(ray,"+GetCameraMatrix",{Camera},Matrix),
                                xGetCameraMatrix2D = define_c_func(ray,"+GetCameraMatrix2D",{Camera2D},Matrix)
                                
global function GetScreenToWorldRay(sequence pos,sequence camera)
        return c_func(xGetScreenToWorldRay,{pos,camera})
end function

global function GetScreenToWorldRayEx(sequence pos,sequence camera,atom width,atom height)
        return c_func(xGetScreenToWorldRayEx,{pos,camera,width,height})
end function

global function GetWorldToScreen(sequence pos,sequence camera)
atom vec=allocate(size_vector3)
atom cam=allocate(size_camera3d)
        return RegtoV2(c_func(xGetWorldToScreen,{poke_vector3(vec,pos),poke_camera3d(cam,camera)}))
free(vec)
free(cam)
end function

global function GetWorldToScreenEx(sequence pos,sequence camera,atom width,atom height)
        return c_func(xGetWorldToScreenEx,{pos,camera,width,height})
end function

global function GetWorldToScreen2D(sequence pos,sequence camera2D)
        return c_func(xGetWorldToScreen2D,{pos,camera2D})
end function

global function GetScreenToWorld2D(sequence pos,sequence camera2D)
atom mem=allocate(24)
poke(mem,atom_to_float32(camera2D[1][1]))
poke(mem+4,atom_to_float32(camera2D[1][2]))
poke(mem+8,atom_to_float32(camera2D[2][1]))
poke(mem+12,atom_to_float32(camera2D[2][2]))
poke(mem+16,atom_to_float32(camera2D[3]))
poke(mem+20,atom_to_float32(camera2D[4]))
sequence erg={0,0}
        erg= RegtoV2(c_func(xGetScreenToWorld2D,{V2toReg(pos),mem}))
free(mem)
return erg
end function

global function GetCameraMatrix(sequence camera)
        return c_func(xGetCameraMatrix,{camera})
end function

global function GetCameraMatrix2D(sequence camera)
        return c_func(xGetCameraMatrix2D,{camera})
end function

--Timing functions

global constant xSetTargetFPS = define_c_proc(ray,"+SetTargetFPS",{C_INT}),
                                xGetFrameTime = define_c_func(ray,"+GetFrameTime",{},C_FLOAT),
                                xGetTime = define_c_func(ray,"+GetTime",{},C_DOUBLE),
                                xGetFPS = define_c_func(ray,"+GetFPS",{},C_INT)
                                
global procedure SetTargetFPS(atom fps)
        c_proc(xSetTargetFPS,{fps})
end procedure

global function GetFrameTime()
        return c_func(xGetFrameTime,{})
end function

global function GetTime()
        return c_func(xGetTime,{})
end function

global function GetFPS()
        return c_func(xGetFPS,{})
end function

--Custom frame control functions
global constant xSwapScreenBuffer = define_c_proc(ray,"+SwapScreenBuffer",{}),
                xPollInputEvents = define_c_proc(ray,"+PollInputEvents",{}),
                xWaitTime = define_c_proc(ray,"+WaitTime",{C_DOUBLE})
                                
global procedure SwapScreenBuffer()
        c_proc(xSwapScreenBuffer,{})
end procedure

global procedure PollInputEvents()
        c_proc(xPollInputEvents,{})
end procedure

global procedure WaitTime(atom seconds)
        c_proc(xWaitTime,{seconds})
end procedure

--Random value generation functions
global constant xSetRandomSeed = define_c_proc(ray,"+SetRandomSeed",{C_UINT}),
                xGetRandomValue = define_c_func(ray,"+GetRandomValue",{C_INT,C_INT},C_INT),
                xLoadRandomSequence = define_c_func(ray,"+LoadRandomSequence",{C_UINT,C_INT,C_INT},C_POINTER),
                xUnloadRandomSequence = define_c_proc(ray,"+UnloadRandomSequence",{C_POINTER})
                                
global procedure SetRandomSeed(atom seed)
        c_proc(xSetRandomSeed,{seed})
end procedure

global function GetRandomValue(atom _min,atom _max)
        return rand_range(_min,_max)
--      return c_func(xGetRandomValue,{min,max})
end function
--CHECK
global function LoadRandomSequence(atom count,atom _min,atom _max)
sequence result=repeat(0,count)
for i=1 to count  
do
    result[i]=rand_range(_min,_max)
end for
return result
        --return c_func(xLoadRandomSequence,{count,min,max})
end function

global procedure UnloadRandomSequence(atom _seq)
        c_proc(xUnloadRandomSequence,{_seq})
end procedure

--Misc functions
global constant xTakeScreenshot = define_c_proc(ray,"+TakeScreenshot",{C_STRING}),
                                xSetConfigFlags = define_c_proc(ray,"+SetConfigFlags",{C_UINT}),
                                xOpenURL = define_c_proc(ray,"+OpenURL",{C_STRING})
                                
global procedure TakeScreenshot(sequence fName)
atom pstr=allocate_string(fName)
        c_proc(xTakeScreenshot,{fName})
free(pstr)
end procedure

global procedure SetConfigFlags(atom flags)
        c_proc(xSetConfigFlags,{flags})
end procedure

global procedure OpenURL(sequence url)
atom pstr=allocate_string(url)
        c_proc(xOpenURL,{pstr})
free(pstr)
end procedure

--
constant xTraceLog = define_c_proc(ray,"+TraceLog",{C_INT,C_STRING,C_POINTER}),
                                xSetTraceLogLevel = define_c_proc(ray,"+SetTraceLogLevel",{C_INT}),
                                xMemAlloc = define_c_func(ray,"+MemAlloc",{C_UINT},C_POINTER),
                                xMemRealloc = define_c_func(ray,"+MemRealloc",{C_POINTER,C_UINT},C_POINTER),
                                xMemFree = define_c_proc(ray,"+MemFree",{C_POINTER})
--CHECK                             
global procedure TraceLog(atom logLevel,sequence text,object x=1)
atom pstr=allocate_string(text)
atom vargs=allocate(8) -- really do not know hos to handle this
        c_proc(xTraceLog,{logLevel,pstr,vargs})
free(pstr)
free(vargs)
end procedure

global procedure SetTraceLogLevel(atom logLevel)
        c_proc(xSetTraceLogLevel,{logLevel})
end procedure

global function MemAlloc(atom size)
        return c_func(xMemAlloc,{size})
end function

global function MemRealloc(atom ptr,atom size)
        return c_func(xMemRealloc,{ptr,size})
end function

global procedure MemFree(atom ptr)
        c_proc(xMemFree,{ptr})
end procedure

--Custom callback functions TODO

--File management functions
constant xLoadFileData = define_c_func(ray,"+LoadFileData",{C_STRING,C_POINTER},C_POINTER),
                                xUnloadFileData = define_c_proc(ray,"+UnloadFileData",{C_POINTER}),
                                xSaveFileData = define_c_func(ray,"+SaveFileData",{C_STRING,C_POINTER,C_INT},C_BOOL),
                                xExportDataAsCode = define_c_func(ray,"+ExportDataAsCode",{C_POINTER,C_INT,C_STRING},C_BOOL),
                                xLoadFileText = define_c_func(ray,"+LoadFileText",{C_STRING},C_POINTER),
                                xUnloadFileText = define_c_proc(ray,"+UnloadFileText",{C_STRING}),
                                xSaveFileText = define_c_func(ray,"+SaveFileText",{C_STRING,C_STRING},C_BOOL)
                                
global function LoadFileData(sequence fName,atom dataSize)
        return c_func(xLoadFileData,{fName,dataSize})
end function

global procedure UnloadFileData(atom data)
        c_proc(xUnloadFileData,{data})
end procedure

global function SaveFileData(sequence fname,object data,atom dataSize)
        return c_func(xSaveFileData,{fname,data,dataSize})
end function

global function ExportDataAsCode(atom data,atom dataSize,sequence fname)
        return c_func(xExportDataAsCode,{data,dataSize,fname})
end function

global function LoadFileText(sequence fname)
        return c_func(xLoadFileText,{fname})
end function

global procedure UnloadFileText(sequence text)
        c_proc(xUnloadFileText,{text})
end procedure

global function SaveFileText(sequence fname,sequence text)
        return c_func(xSaveFileText,{fname,text})
end function

--file system functions
constant xFileExists = define_c_func(ray,"+FileExists",{C_STRING},C_BOOL),
                                xDirectoryExists = define_c_func(ray,"+DirectoryExists",{C_STRING},C_BOOL),
                                xIsFileExtension = define_c_func(ray,"+IsFileExtension",{C_STRING,C_STRING},C_BOOL),
                                xGetFileLength = define_c_func(ray,"+GetFileLength",{C_STRING},C_INT),
                                xGetFileExtension = define_c_func(ray,"+GetFileExtension",{C_STRING},C_STRING),
                                xGetFileName = define_c_func(ray,"+GetFileName",{C_STRING},C_STRING),
                                xGetFileNameWithoutExt = define_c_func(ray,"+GetFileNameWithoutExt",{C_STRING},C_STRING),
                                xGetDirectoryPath = define_c_func(ray,"+GetDirectoryPath",{C_STRING},C_STRING),
                                xGetPrevDirectoryPath = define_c_func(ray,"+GetPrevDirectoryPath",{C_STRING},C_STRING),
                                xGetWorkingDirectory = define_c_func(ray,"+GetWorkingDirectory",{},C_STRING),
                                xGetApplicationDirectory = define_c_func(ray,"+GetApplicationDirectory",{},C_STRING),
                                xMakeDirectory = define_c_func(ray,"+MakeDirectory",{C_STRING},C_INT),
                                xChangeDirectory = define_c_func(ray,"+ChangeDirectory",{C_STRING},C_BOOL),
                                xIsPathFile = define_c_func(ray,"+IsPathFile",{C_STRING},C_BOOL),
                                xIsFileNameValid = define_c_func(ray,"+IsFileNameValid",{C_STRING},C_BOOL),
                                xLoadDirectoryFiles = define_c_func(ray,"+LoadDirectoryFiles",{C_STRING},FilePathList),
                                xLoadDirectoryFilesEx = define_c_func(ray,"+LoadDirectoryFilesEx",{C_STRING,C_STRING,C_BOOL},FilePathList),
                                xUnloadDirectoryFiles = define_c_proc(ray,"+UnloadDirectoryFiles",{FilePathList}),
                                xIsFileDropped = define_c_func(ray,"+IsFileDropped",{},C_BOOL),
                                xLoadDroppedFiles = define_c_func(ray,"+LoadDroppedFiles",{},FilePathList),
                                xUnloadDroppedFiles = define_c_proc(ray,"+UnloadDroppedFiles",{FilePathList}),
                                xGetFileModTime = define_c_func(ray,"+GetFileModTime",{C_STRING},C_LONG)
                                
global function FileExists(sequence fName)
        return c_func(xFileExists,{fName})
end function

global function DirectoryExists(sequence dirPath)
        return c_func(xDirectoryExists,{dirPath})
end function

global function IsFileExtension(sequence fName,sequence ext)
        return c_func(xIsFileExtension,{fName,ext})
end function

global function GetFileLength(sequence fName)
        return c_func(xGetFileLength,{fName})
end function

global function GetFileExtension(sequence fName)
        return c_func(xGetFileExtension,{fName})
end function

global function GetFileName(sequence filePath)
        return c_func(xGetFileName,{filePath})
end function

global function GetFileNameWithoutExt(sequence filePath)
        return c_func(xGetFileNameWithoutExt,{filePath})
end function

global function GetDirectoryPath(sequence filePath)
        return c_func(xGetDirectoryPath,{filePath})
end function

global function GetPrevDirectoryPath(sequence dirPath)
        return c_func(xGetPrevDirectoryPath,{dirPath})
end function

global function GetWorkingDirectory()
        return c_func(xGetWorkingDirectory,{})
end function

global function GetApplicationDirectory()
        return c_func(xGetApplicationDirectory,{})
end function

global function MakeDirectory(sequence dirPath)
        return c_func(xMakeDirectory,{dirPath})
end function

global function ChangeDirectory(sequence _dir)
        return c_func(xChangeDirectory,{_dir})
end function

global function IsPathFile(sequence path)
        return c_func(xIsPathFile,{path})
end function

global function IsFileNameValid(sequence fName)
        return c_func(xIsFileNameValid,{fName})
end function

global function LoadDirectoryFiles(sequence dirPath)
        return c_func(xLoadDirectoryFiles,{dirPath})
end function

global function LoadDirectoryFilesEx(sequence basePath,sequence filter,atom scanSubdirs)
        return c_func(xLoadDirectoryFilesEx,{basePath,filter,scanSubdirs})
end function

global procedure UnloadDirectoryFiles(sequence files)
        c_proc(xUnloadDirectoryFiles,{files})
end procedure

global function IsFileDropped()
        return c_func(xIsFileDropped,{})
end function

global function LoadDroppedFiles()
        return c_func(xLoadDroppedFiles,{})
end function

global procedure UnloadDroppedFiles(sequence files)
        c_proc(xUnloadDroppedFiles,{files})
end procedure

global function GetFileModTime(sequence fName)
        return c_func(xGetFileModTime,{fName})
end function

--Compression functions
constant xCompressData = define_c_func(ray,"+CompressData",{C_POINTER,C_INT,C_POINTER},C_POINTER),
                                xDecompressData = define_c_func(ray,"+DecompressData",{C_POINTER,C_INT,C_POINTER},C_POINTER),
                                xEncodeDataBase64 = define_c_func(ray,"+EncodeDataBase64",{C_POINTER,C_INT,C_POINTER},C_POINTER),
                                xDecodeDataBase64 = define_c_func(ray,"+DecodeDataBase64",{C_POINTER,C_POINTER},C_POINTER),
                                xComputeCRC32 = define_c_func(ray,"+ComputeCRC32",{C_POINTER,C_INT},C_UINT),
                                xComputeMD5 = define_c_func(ray,"+ComputeMD5",{C_POINTER,C_INT},C_POINTER),
                                xComputeSHA1 = define_c_func(ray,"+ComputeSHA1",{C_POINTER,C_INT},C_POINTER)
                                
global function CompressData(atom data,atom dataSize,atom compDataSize)
        return c_func(xCompressData,{data,dataSize,compDataSize})
end function

global function DecompressData(atom compData,atom compDataSize,atom dataSize)
        return c_func(xDecompressData,{compData,compDataSize,dataSize})
end function

global function EncodeDataBase64(atom data,atom dataSize,atom outputSize)
        return c_func(xEncodeDataBase64,{data,dataSize,outputSize})
end function

global function DecodeDataBase64(atom data,atom outputSize)
        return c_func(xDecodeDataBase64,{data,outputSize})
end function

global function ComputeCRC32(atom data,atom dataSize)
        return c_func(xComputeCRC32,{data,dataSize})
end function

global function ComputeMD5(atom data,atom dataSize)
        return c_func(xComputeMD5,{data,dataSize})
end function

global function ComputeSHA1(atom data,atom dataSize)
        return c_func(xComputeSHA1,{data,dataSize})
end function

--Automation event functions
constant xLoadAutomationEventList = define_c_func(ray,"+LoadAutomationEventList",{C_STRING},AutomationEventList),
                                xUnloadAutomationEventList = define_c_proc(ray,"+UnloadAutomationEventList",{AutomationEventList}),
                                xExportAutomationEventList = define_c_func(ray,"+ExportAutomationEventList",{AutomationEventList,C_STRING},C_BOOL),
                                xSetAutomationEventList = define_c_proc(ray,"+SetAutomationEventList",{C_POINTER}),
                                xSetAutomationEventBaseFrame = define_c_proc(ray,"+SetAutomationEventBaseFrame",{C_INT}),
                                xStartAutomationEventRecording = define_c_proc(ray,"+StartAutomationEventRecording",{}),
                                xStopAutomationEventRecording = define_c_proc(ray,"+StopAutomationEventRecording",{}),
                                xPlayAutomationEvent = define_c_proc(ray,"+PlayAutomationEvent",{AutomationEvent})
                                
global function LoadAutomationEventList(sequence fName)
        return c_func(xLoadAutomationEventList,{fName})
end function

global procedure UnloadAutomationEventList(sequence list)
        c_proc(xUnloadAutomationEventList,{list})
end procedure

global function ExportAutomationEventList(sequence list,sequence fName)
        return c_func(xExportAutomationEventList,{list,fName})
end function

global procedure SetAutomationEventList(atom list)
        c_proc(xSetAutomationEventList,{list})
end procedure

global procedure SetAutomationEventBaseFrame(atom frame)
        c_proc(xSetAutomationEventBaseFrame,{frame})
end procedure

global procedure StartAutomationEventRecording()
        c_proc(xStartAutomationEventRecording,{})
end procedure

global procedure StopAutomationEventRecording()
        c_proc(xStopAutomationEventRecording,{})
end procedure

global procedure PlayAutomationEvent(sequence event)
        c_proc(xPlayAutomationEvent,{event})
end procedure

--Input functions: Keyboard
constant xIsKeyPressed = define_c_func(ray,"+IsKeyPressed",{C_INT},C_BOOL),
                                xIsKeyPressedRepeat = define_c_func(ray,"+IsKeyPressedRepeat",{C_INT},C_BOOL),
                                xIsKeyDown = define_c_func(ray,"+IsKeyDown",{C_INT},C_BOOL),
                                xIsKeyReleased = define_c_func(ray,"+IsKeyReleased",{C_INT},C_BOOL),
                                xIsKeyUp = define_c_func(ray,"+IsKeyUp",{C_INT},C_BOOL),
                                xGetKeyPressed = define_c_func(ray,"+GetKeyPressed",{},C_INT),
                                xGetCharPressed = define_c_func(ray,"+GetCharPressed",{},C_INT),
                                xSetExitKey = define_c_proc(ray,"+SetExitKey",{C_INT})
                                
global function IsKeyPressed(atom key)
        return and_bits(c_func(xIsKeyPressed,{key}),1)
end function

global function IsKeyPressedRepeat(atom key)
        return and_bits(c_func(xIsKeyPressedRepeat,{key}),1)
end function

global function IsKeyDown(atom key)
        return and_bits(c_func(xIsKeyDown,{key}),1)
end function

global function IsKeyReleased(atom key)
        return and_bits(c_func(xIsKeyReleased,{key}),1)
end function

global function IsKeyUp(atom key)
        return and_bits(c_func(xIsKeyUp,{key}),1)
end function

global function GetKeyPressed()
        return c_func(xGetKeyPressed,{})
end function

global function GetCharPressed()
        return c_func(xGetCharPressed,{})
end function

global procedure SetExitKey(atom key)
        c_proc(xSetExitKey,{key})
end procedure

--Input functions: Gamepad
constant xIsGamepadAvailable = define_c_func(ray,"+IsGamepadAvailable",{C_INT},C_BOOL),
                                xGetGamepadName = define_c_func(ray,"+GetGamepadName",{C_INT},C_STRING),
                                xIsGamepadButtonPressed = define_c_func(ray,"+IsGamepadButtonPressed",{C_INT,C_INT},C_BOOL),
                                xIsGamepadButtonDown = define_c_func(ray,"+IsGamepadButtonDown",{C_INT,C_INT},C_BOOL),
                                xIsGamepadButtonReleased = define_c_func(ray,"+IsGamepadButtonReleased",{C_INT,C_INT},C_BOOL),
                                xIsGamepadButtonUp = define_c_func(ray,"+IsGamepadButtonUp",{C_INT,C_INT},C_BOOL),
                                xGetGamepadButtonPressed = define_c_func(ray,"+GetGamepadButtonPressed",{},C_INT),
                                xGetGamepadAxisCount = define_c_func(ray,"+GetGamepadAxisCount",{C_INT},C_INT),
                                xGetGamepadAxisMovement = define_c_func(ray,"+GetGamepadAxisMovement",{C_INT,C_INT},C_FLOAT),
                                xSetGamepadMappings = define_c_func(ray,"+SetGamepadMappings",{C_STRING},C_INT),
                                xSetGamepadVibration = define_c_proc(ray,"+SetGamepadVibration",{C_INT,C_FLOAT,C_FLOAT,C_FLOAT})
                                
global function IsGamepadAvailable(atom gamepad)
        return and_bits(c_func(xIsGamepadAvailable,{gamepad}),1)
end function

global function GetGamepadName(atom gamepad)
atom pstr
        pstr = c_func(xGetGamepadName,{gamepad})
        return peek_string(pstr)
end function

global function IsGamepadButtonPressed(atom gamepad,atom button)
        return and_bits(c_func(xIsGamepadButtonPressed,{gamepad,button}),1)
end function

global function IsGamepadButtonDown(atom gamepad,atom button)
        return and_bits(c_func(xIsGamepadButtonDown,{gamepad,button}),1)
end function

global function IsGamepadButtonReleased(atom gamepad,atom button)
        return and_bits(c_func(xIsGamepadButtonReleased,{gamepad,button}),1)
end function

global function IsGamepadButtonUp(atom gamepad,atom button)
        return and_bits(c_func(xIsGamepadButtonUp,{gamepad,button}),1)
end function

global function GetGamepadButtonPressed()
        return c_func(xGetGamepadButtonPressed,{})
end function

global function GetGamepadAxisCount(atom gamepad)
        return c_func(xGetGamepadAxisCount,{gamepad})
end function

global function GetGamepadAxisMovement(atom gamepad,atom axis)
        return c_func(xGetGamepadAxisMovement,{gamepad,axis})
end function

global function SetGamepadMappings(sequence mappings)
        return c_func(xSetGamepadMappings,{mappings})
end function

global procedure SetGamepadVibration(atom gamepad,atom leftMotor,atom rightMotor,atom duration)
        c_proc(xSetGamepadVibration,{gamepad,leftMotor,rightMotor,duration})
end procedure

--Input functions: Mouse
constant xIsMouseButtonPressed = define_c_func(ray,"+IsMouseButtonPressed",{C_INT},C_BOOL),
                                xIsMouseButtonDown = define_c_func(ray,"+IsMouseButtonDown",{C_INT},C_BOOL),
                                xIsMouseButtonReleased = define_c_func(ray,"+IsMouseButtonReleased",{C_INT},C_BOOL),
                                xIsMouseButtonUp = define_c_func(ray,"+IsMouseButtonUp",{C_INT},C_BOOL),
                                xGetMouseX = define_c_func(ray,"+GetMouseX",{},C_INT),
                                xGetMouseY = define_c_func(ray,"+GetMouseY",{},C_INT),
                                xGetMousePosition = define_c_func(ray,"+GetMousePosition",{},Vector2),
                                xGetMouseDelta = define_c_func(ray,"+GetMouseDelta",{},Vector2),
                                xSetMousePosition = define_c_proc(ray,"+SetMousePosition",{C_INT,C_INT}),
                                xSetMouseOffset = define_c_proc(ray,"+SetMouseOffset",{C_INT,C_INT}),
                                xSetMouseScale = define_c_proc(ray,"+SetMouseScale",{C_FLOAT,C_FLOAT}),
                                xGetMouseWheelMove = define_c_func(ray,"+GetMouseWheelMove",{},C_FLOAT),
                                xGetMouseWheelMoveV = define_c_func(ray,"+GetMouseWheelMoveV",{},Vector2),
                                xSetMouseCursor = define_c_proc(ray,"+SetMouseCursor",{C_INT})
                                
global function IsMouseButtonPressed(atom button)   
        --?c_func(xIsMouseButtonPressed,{button})
        return and_bits(c_func(xIsMouseButtonPressed,{button}),1)
        
end function

global function IsMouseButtonDown(atom button)
        return and_bits(c_func(xIsMouseButtonDown,{button}),1)
end function

global function IsMouseButtonReleased(atom button)
        return and_bits(c_func(xIsMouseButtonReleased,{button}),1)
end function

global function IsMouseButtonUp(atom button)
        return and_bits(c_func(xIsMouseButtonUp,{button}),1)
end function

global function GetMouseX()
        return c_func(xGetMouseX,{})
end function

global function GetMouseY()
        return c_func(xGetMouseY,{})
end function

global function GetMousePosition()
sequence result
    result=RegtoV2(c_func(xGetMousePosition,{}))
return result
end function

global function GetMouseDelta()
        return RegtoV2(c_func(xGetMouseDelta,{}))
end function

global procedure SetMousePosition(atom x,atom y)
        c_proc(xSetMousePosition,{x,y})
end procedure

global procedure SetMouseOffset(atom x,atom y)
        c_proc(xSetMouseOffset,{x,y})
end procedure

global procedure SetMouseScale(atom x,atom y)
        c_proc(xSetMouseScale,{x,y})
end procedure

global function GetMouseWheelMove()
        return c_func(xGetMouseWheelMove,{})
end function

global function GetMouseWheelMoveV()
        return RegtoV2(c_func(xGetMouseWheelMoveV,{}))
end function

global procedure SetMouseCursor(atom cursor)
        c_proc(xSetMouseCursor,{cursor})
end procedure

--Input functions: Touch
constant xGetTouchX = define_c_func(ray,"+GetTouchX",{},C_INT),
                                xGetTouchY = define_c_func(ray,"+GetTouchY",{},C_INT),
                                xGetTouchPosition = define_c_func(ray,"+GetTouchPosition",{C_INT},Vector2),
                                xGetTouchPointId = define_c_func(ray,"+GetTouchPointId",{C_INT},C_INT),
                                xGetTouchPointCount = define_c_func(ray,"+GetTouchPointCount",{},C_INT)
                                
global function GetTouchX()
        return c_func(xGetTouchX,{})
end function

global function GetTouchY()
        return c_func(xGetTouchY,{})
end function

global function GetTouchPosition(atom index)
        return RegtoV2(c_func(xGetTouchPosition,{index}))
end function

global function GetTouchPointId(atom index)
        return c_func(xGetTouchPointId,{index})
end function

global function GetTouchPointCount()
        return c_func(xGetTouchPointCount,{})
end function

--Gesture functions
constant xSetGesturesEnabled = define_c_proc(ray,"+SetGesturesEnabled",{C_UINT}),
                                xIsGestureDetected = define_c_func(ray,"+IsGestureDetected",{C_UINT},C_BOOL),
                                xGetGestureDetected = define_c_func(ray,"+GetGestureDetected",{},C_INT),
                                xGetGestureHoldDuration = define_c_func(ray,"+GetGestureHoldDuration",{},C_FLOAT),
                                xGetGestureDragVector = define_c_func(ray,"+GetGestureDragVector",{},Vector2),
                                xGetGestureDragAngle = define_c_func(ray,"+GetGestureDragAngle",{},C_FLOAT),
                                xGetGesturePinchVector = define_c_func(ray,"+GetGesturePinchVector",{},Vector2),
                                xGetGesturePinchAngle = define_c_func(ray,"+GetGesturePinchAngle",{},C_FLOAT)
                                
global procedure SetGesturesEnabled(atom flags)
        c_proc(xSetGesturesEnabled,{flags})
end procedure

global function IsGestureDetected(atom gesture)
        return c_func(xIsGestureDetected,{gesture})
end function

global function GetGestureDetected()
        return c_func(xGetGestureDetected,{})
end function

global function GetGestureHoldDuration()
        return c_func(xGetGestureHoldDuration,{})
end function

global function GetGestureDragVector()
        return RegtoV2(c_func(xGetGestureDragVector,{}))
end function

global function GetGestureDragAngle()
        return c_func(xGetGestureDragAngle,{})
end function

global function GetGesturePinchVector()
        return RegtoV2(c_func(xGetGesturePinchVector,{}))
end function

global function GetGesturePinchAngle()
        return c_func(xGetGesturePinchAngle,{})
end function

--Camera functions
constant xUpdateCamera = define_c_proc(ray,"+UpdateCamera",{C_POINTER,C_INT}),
                                xUpdateCameraPro = define_c_proc(ray,"+UpdateCameraPro",{C_POINTER,Vector3,Vector3,C_FLOAT})
                                
global function UpdateCamera(sequence  cam,atom mode)
atom camera=allocate(size_camera3d)
sequence camret=Tcamera3D
        c_proc(xUpdateCamera,{poke_camera3d(camera,cam),mode})
camret=peek_camera3d(camera)
free(camera)
return camret
end function

global function UpdateCameraPro(sequence  cam,sequence movement,sequence rotation,atom zoom)
atom camera=allocate(size_camera3d)
sequence camret=Tcamera3D
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
        c_proc(xUpdateCameraPro,{poke_camera3d(camera,cam),poke_vector3(vec1,movement),poke_vector3(vec2,rotation),zoom})
camret=peek_camera3d(camera)
free(camera)
free(vec1)
free(vec2)
return camret
end function

--RLAPI Vector3 GetCameraForward(Camera *camera);
--RLAPI Vector3 GetCameraUp(Camera *camera);
--RLAPI Vector3 GetCameraRight(Camera *camera);

-- Camera movement
--RLAPI void CameraMoveForward(Camera *camera, float distance, bool moveInWorldPlane);
--RLAPI void CameraMoveUp(Camera *camera, float distance);
--RLAPI void CameraMoveRight(Camera *camera, float distance, bool moveInWorldPlane);
--RLAPI void CameraMoveToTarget(Camera *camera, float delta);
-- Camera ratation

--RLAPI void CameraYaw(Camera *camera, float angle, bool rotateAroundTarget);
--RLAPI void CameraPitch(Camera *camera, float angle, bool lockView, bool rotateAroundTarget, bool rotateUp);
--RLAPI void CameraRoll(Camera *camera, float angle);

--RLAPI Matrix GetCameraViewMatrix(Camera *camera);
--RLAPI Matrix GetCameraProjectionMatrix(Camera *camera, float aspect);
constant xCameraYaw = define_c_proc(ray,"CameraYaw",{C_POINTER,C_FLOAT,C_BOOL}),
         xCameraPitch = define_c_proc(ray,"CameraPitch",{C_POINTER,C_FLOAT,C_BOOL,C_BOOL,C_BOOL}),
         xCameraRoll = define_c_proc(ray,"CameraRoll",{C_POINTER,C_FLOAT})

global function CameraYaw(sequence cam,atom angle,atom rotate)
atom camera=allocate(size_camera3d)
sequence camret=Tcamera3D       
            c_proc(xCameraYaw,{poke_camera3d(camera,cam),angle,rotate})
camret=peek_camera3d(camera)
free(camera)
return camret        
end function

global function CameraPitch(sequence cam,atom angle,atom lock,atom rotate,atom rotateup)
atom camera=allocate(size_camera3d)
sequence camret=Tcamera3D
            c_proc(xCameraPitch,{poke_camera3d(camera,cam),angle,lock,rotate,rotateup})
camret=peek_camera3d(camera)
free(camera)
return camret
end function

global function CameraRoll(sequence cam,atom angle)
atom camera=allocate(size_camera3d)
sequence camret=Tcamera3D
camret=peek_camera3d(camera)
            c_proc(xCameraRoll,{poke_camera3d(camera,cam),angle})   
free(camera)
return camret
end function

--Shape functions
constant xSetShapesTexture = define_c_proc(ray,"+SetShapesTexture",{Texture2D,Rectangle}),
                                xGetShapesTexture = define_c_func(ray,"+GetShapesTexture",{},Texture2D),
                                xGetShapesTextureRectangle = define_c_func(ray,"+GetShapesTextureRectangle",{},Rectangle)
                                
global procedure SetShapesTexture(sequence tex2D,sequence source)
        c_proc(xSetShapesTexture,{tex2D,source})
end procedure

global function GetShapesTexture()
        return c_func(xGetShapesTexture,{})
end function

global function GetShapesTextureRectangle()
        return c_func(xGetShapesTextureRectangle,{})
end function

--Basic shape drawing functions
constant xDrawPixel = define_c_proc(ray,"+DrawPixel",{C_INT,C_INT,C_Color}),
                                xDrawPixelV = define_c_proc(ray,"+DrawPixelV",{Vector2,C_Color}),
                                xDrawLine = define_c_proc(ray,"+DrawLine",{C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xDrawLineV = define_c_proc(ray,"+DrawLineV",{Vector2,Vector2,C_Color}),
                                xDrawLineEx = define_c_proc(ray,"+DrawLineEx",{Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawLineStrip = define_c_proc(ray,"+DrawLineStrip",{C_POINTER,C_INT,C_Color}),
                                xDrawLineBezier = define_c_proc(ray,"+DrawLineBezier",{Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawLineDashed = define_c_proc(ray,"+DrawLineDashed",{Vector2,Vector2,C_INT,C_INT,C_Color}),
                                xDrawCircle = define_c_proc(ray,"+DrawCircle",{C_INT,C_INT,C_FLOAT,C_Color}),
                                xDrawCircleSector = define_c_proc(ray,"+DrawCircleSector",{Vector2,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCircleSectorLines = define_c_proc(ray,"+DrawCircleSectorLines",{Vector2,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCircleGradient = define_c_proc(ray,"+DrawCircleGradient",{Vector2,C_FLOAT,C_Color,C_Color}),
                                xDrawCircleV = define_c_proc(ray,"+DrawCircleV",{Vector2,C_FLOAT,C_Color}),
                                xDrawCircleLines = define_c_proc(ray,"+DrawCircleLines",{C_INT,C_INT,C_FLOAT,C_Color}),
                                xDrawCircleLinesV = define_c_proc(ray,"+DrawCircleLinesV",{Vector2,C_FLOAT,C_Color}),
                                xDrawEllipse = define_c_proc(ray,"+DrawEllipse",{C_INT,C_INT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawEllipseLines = define_c_proc(ray,"+DrawEllipseLines",{C_INT,C_INT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawRing = define_c_proc(ray,"+DrawRing",{Vector2,C_FLOAT,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawRingLines = define_c_proc(ray,"+DrawRingLines",{Vector2,C_FLOAT,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawRectangle = define_c_proc(ray,"+DrawRectangle",{C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xDrawRectangleV = define_c_proc(ray,"+DrawRectangleV",{Vector2,Vector2,C_Color}),
                                xDrawRectangleRec = define_c_proc(ray,"+DrawRectangleRec",{Rectangle,C_Color}),
                                xDrawRectanglePro = define_c_proc(ray,"+DrawRectanglePro",{Rectangle,Vector2,C_FLOAT,C_Color}),
                                xDrawRectangleGradientV = define_c_proc(ray,"+DrawRectangleGradientV",{C_INT,C_INT,C_INT,C_INT,C_Color,C_Color}),
                                xDrawRectangleGradientH = define_c_proc(ray,"+DrawRectangleGradientH",{C_INT,C_INT,C_INT,C_INT,C_Color,C_Color}),
                                xDrawRectangleGradientEx = define_c_proc(ray,"+DrawRectangleGradientEx",{Rectangle,C_Color,C_Color,C_Color,C_Color}),
                                xDrawRectangleLines = define_c_proc(ray,"+DrawRectangleLines",{C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xDrawRectangleLinesEx = define_c_proc(ray,"+DrawRectangleLinesEx",{Rectangle,C_FLOAT,C_Color}),
                                xDrawRectangleRounded = define_c_proc(ray,"+DrawRectangleRounded",{Rectangle,C_FLOAT,C_INT,C_Color}),
                                xDrawRectangleRoundedLines = define_c_proc(ray,"+DrawRectangleRoundedLines",{Rectangle,C_FLOAT,C_INT,C_Color}),
                                xDrawRectangleRoundedLinesEx = define_c_proc(ray,"+DrawRectangleRoundedLinesEx",{Rectangle,C_FLOAT,C_INT,C_FLOAT,C_Color}),
                                xDrawTriangle = define_c_proc(ray,"+DrawTriangle",{Vector2,Vector2,Vector2,C_Color}),
                                xDrawTriangleLines = define_c_proc(ray,"+DrawTriangleLines",{Vector2,Vector2,Vector2,C_Color}),
                                xDrawTriangleFan = define_c_proc(ray,"+DrawTriangleFan",{C_POINTER,C_INT,C_Color}),
                                xDrawTriangleStrip = define_c_proc(ray,"+DrawTriangleStrip",{C_POINTER,C_INT,C_Color}),
                                xDrawPoly = define_c_proc(ray,"+DrawPoly",{Vector2,C_INT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawPolyLines = define_c_proc(ray,"+DrawPolyLines",{Vector2,C_INT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawPolyLinesEx = define_c_proc(ray,"+DrawPolyLinesEx",{Vector2,C_INT,C_FLOAT,C_FLOAT,C_FLOAT,C_Color})
                                
constant DrawPixel_=GetProcAddress(ray,"DrawPixel")
global procedure DrawPixel(integer x,integer y,sequence color)
integer col=bytes_to_int(color)
--/**/#ilASM{ 
--/**/  [64]
--/**/
--/**/      mov rcx,[x]
--/**/      mov rdx,[y]
--/**/      mov r8,[col]
--/**/      sub rsp, 40                 -- Shadow Space (32) + Alignment (8)
--/**/      mov rax,[DrawPixel_]
--/**/      call rax
--/**/      --call "libraylib","DrawPixel"       -- Direkter Sprung
--/**/      add rsp,40
--/**/      [32]
--/**/      nop 
--/**/  }
--/*
    c_proc(xDrawPixel,{x,y,col})
--*/
end procedure

global procedure _DrawPixel(integer x,integer  y,sequence color)
    c_proc(xDrawPixel,{x,y,bytes_to_int(color)})
end procedure



constant DrawPixelV_=GetProcAddress(ray,"DrawPixelV")
global procedure DrawPixelV(sequence pos,sequence color)
atom reg=V2toReg(pos)
integer col=bytes_to_int(color)
--/**/#ilASM{ 
--/**/  [64]
--/**/      mov rax,[reg]
--/**/      call :%pLoadMint    
--/**/      mov rcx,rax  
--/**/      mov rax,[DrawPixelV_]
--/**/      mov rdx,[col]
--/**/      sub rsp, 40                 -- Shadow Space (32) + Alignment (8)
--/**/  --  mov rax,[DrawPixelV_]
--/**/      call rax
--/**/  --  call "libraylib","DrawPixelV"        -- Direkter Sprung
--/**/      add rsp,40
--/**/      [32]
--/**/      nop
--/**/  }
--/*
    c_proc(xDrawPixelV,{reg,col})
--*/
end procedure



global procedure _DrawPixelV(sequence pos,sequence color)
        c_proc(xDrawPixelV,{V2toReg(pos),bytes_to_int(color)})
end procedure

global procedure DrawLine(atom startX,atom startY,atom endX,atom endY,sequence color)
        c_proc(xDrawLine,{startX,startY,endX,endY,bytes_to_int(color)})
end procedure

global procedure DrawLineV(sequence start,sequence endPos,sequence color)
        c_proc(xDrawLineV,{V2toReg(start),V2toReg(endPos),bytes_to_int(color)})
end procedure

global procedure DrawLineEx(sequence start,sequence endPos,atom thick,sequence color)
        c_proc(xDrawLineEx,{V2toReg(start),V2toReg(endPos),thick,bytes_to_int(color)})
end procedure

global procedure DrawLineStrip(sequence pts,atom count,sequence color)
atom buffer=allocate(length(pts)*2*8)
for i= 0 to length(pts)-1
do
    poke(buffer+(i*8),atom_to_float32(pts[i+1][1]))
    poke(buffer+((i*8)+4),atom_to_float32(pts[i+1][2]))
end for
        c_proc(xDrawLineStrip,{buffer,count,bytes_to_int(color)})
free(buffer)
end procedure

global procedure DrawLineBezier(sequence start,sequence endPos,atom thick,sequence color)
        c_proc(xDrawLineBezier,{V2toReg(start),V2toReg(endPos),thick,bytes_to_int(color)})
end procedure

global procedure DrawLineDashed(sequence start,sequence endPos,atom dashsize,atom spacesize,sequence color)
        c_proc(xDrawLineDashed,{V2toReg(start),V2toReg(endPos),dashsize,spacesize,bytes_to_int(color)})
end procedure

global procedure DrawCircle(atom x,atom y,atom radius,sequence color)
        c_proc(xDrawCircle,{x,y,radius,bytes_to_int(color)})
end procedure

global procedure DrawCircleSector(sequence center,atom radius,atom start,atom endAngle,atom segments,sequence color)
        c_proc(xDrawCircleSector,{V2toReg(center),radius,start,endAngle,segments,bytes_to_int(color)})
end procedure

global procedure DrawCircleSectorLines(sequence center,atom radius,atom start,atom endAngle,atom segments,sequence color)
        c_proc(xDrawCircleSectorLines,{V2toReg(center),radius,start,endAngle,segments,bytes_to_int(color)})
end procedure

global procedure DrawCircleGradient(sequence center,atom radius,sequence inner,sequence outer)
        c_proc(xDrawCircleGradient,{V2toReg(center),radius,bytes_to_int(inner),bytes_to_int(outer)})
end procedure

global procedure DrawCircleV(sequence center,atom radius,sequence color)
        c_proc(xDrawCircleV,{V2toReg(center),radius,bytes_to_int(color)})
end procedure

global procedure DrawCircleLines(atom x,atom y,atom radius,sequence color)
        c_proc(xDrawCircleLines,{x,y,radius,bytes_to_int(color)})
end procedure

global procedure DrawCircleLinesV(sequence center,atom radius,sequence color)
        c_proc(xDrawCircleLinesV,{V2toReg(center),radius,bytes_to_int(color)})
end procedure

global procedure DrawEllipse(atom x,atom y,atom radH,atom radV,sequence color)
        c_proc(xDrawEllipse,{x,y,radH,radV,bytes_to_int(color)})
end procedure

global procedure DrawEllipseLines(atom x,atom y,atom radH,atom radV,sequence color)
        c_proc(xDrawEllipseLines,{x,y,radH,radV,bytes_to_int(color)})
end procedure

global procedure DrawRing(sequence center,atom innerRad,atom outerRad,atom start,atom endAngle,atom segments,sequence color)
        c_proc(xDrawRing,{V2toReg(center),innerRad,outerRad,start,endAngle,segments,bytes_to_int(color)})
end procedure

global procedure DrawRingLines(sequence center,atom innerRad,atom outerRad,atom start,atom endAngle,atom segments,sequence color)
        c_proc(xDrawRingLines,{V2toReg(center),innerRad,outerRad,start,endAngle,segments,bytes_to_int(color)})
end procedure

global procedure DrawRectangle(atom x,atom y,atom width,atom height,sequence color)
        c_proc(xDrawRectangle,{x,y,width,height,bytes_to_int(color)})
end procedure

global procedure DrawRectangleV(sequence pos,sequence size,sequence color)
        c_proc(xDrawRectangleV,{V2toReg(pos),V2toReg(size),bytes_to_int(color)})
end procedure

global procedure DrawRectangleRec(sequence rec,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleRec,{mem,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawRectanglePro(sequence rec,sequence origin,atom rotation,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectanglePro,{mem,V2toReg(origin),rotation,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawRectangleGradientV(atom x,atom y,atom width,atom height,sequence top,sequence bottom)
        c_proc(xDrawRectangleGradientV,{x,y,width,height,bytes_to_int(top),bytes_to_int(bottom)})
end procedure

global procedure DrawRectangleGradientH(atom x,atom y,atom width,atom height,sequence left,sequence right)
        c_proc(xDrawRectangleGradientH,{x,y,width,height,bytes_to_int(left),bytes_to_int(right)})
end procedure

global procedure DrawRectangleGradientEx(sequence rec,sequence topLeft,sequence bottomLeft,sequence topRight,sequence bottomRight)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleGradientEx,{mem,bytes_to_int(topLeft),bytes_to_int(bottomLeft),bytes_to_int(topRight),bytes_to_int(bottomRight)})
free(mem)
end procedure

global procedure DrawRectangleLines(atom x,atom y,atom width,atom height,sequence color)
        c_proc(xDrawRectangleLines,{x,y,width,height,bytes_to_int(color)})
end procedure

global procedure DrawRectangleLinesEx(sequence rec,atom thick,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleLinesEx,{mem,thick,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawRectangleRounded(sequence rec,atom _round,atom segments,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleRounded,{mem,_round,segments,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawRectangleRoundedLines(sequence rec,atom _round,atom segments,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleRoundedLines,{mem,_round,segments,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawRectangleRoundedLinesEx(sequence rec,atom _round,atom segments,atom thick,sequence color)
atom mem=allocate(20)
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        c_proc(xDrawRectangleRoundedLinesEx,{mem,_round,segments,thick,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawTriangle(sequence v,sequence v2,sequence v3,sequence color)
        c_proc(xDrawTriangle,{V2toReg(v),V2toReg(v2),V2toReg(v3),bytes_to_int(color)})
end procedure

global procedure DrawTriangleLines(sequence v,sequence v2,sequence v3,sequence color)
        c_proc(xDrawTriangleLines,{V2toReg(v),V2toReg(v2),V2toReg(v3),bytes_to_int(color)})
end procedure

global procedure DrawTriangleFan(sequence  pts,atom count,sequence color)
atom buffer=allocate(length(pts)*2*8)
for i= 0 to length(pts)-1
do
    poke(buffer+(i*8),atom_to_float32(pts[i+1][1]))
    poke(buffer+((i*8)+4),atom_to_float32(pts[i+1][2]))
end for
        c_proc(xDrawTriangleFan,{buffer,count,bytes_to_int(color)})
free(buffer)
end procedure

global procedure DrawTriangleStrip(sequence  pts,atom count,sequence color)
atom buffer=allocate(length(pts)*2*8)
for i= 0 to length(pts)-1
do
    poke(buffer+(i*8),atom_to_float32(pts[i+1][1]))
    poke(buffer+((i*8)+4),atom_to_float32(pts[i+1][2]))
end for
        c_proc(xDrawTriangleStrip,{buffer,count,bytes_to_int(color)})
free(buffer)
end procedure

global procedure DrawPoly(sequence center,atom sides,atom radius,atom rotation,sequence color)
        c_proc(xDrawPoly,{V2toReg(center),sides,radius,rotation,bytes_to_int(color)})
end procedure

global procedure DrawPolyLines(sequence center,atom sides,atom radius,atom rotation,sequence color)
        c_proc(xDrawPolyLines,{V2toReg(center),sides,radius,rotation,bytes_to_int(color)})
end procedure

global procedure DrawPolyLinesEx(sequence center,atom sides,atom radius,atom rotation,atom thick,sequence color)
        c_proc(xDrawPolyLinesEx,{V2toReg(center),sides,radius,rotation,thick,bytes_to_int(color)})
end procedure

--Spline drawing functions
constant xDrawSplineLinear = define_c_proc(ray,"+DrawSplineLinear",{C_POINTER,C_INT,C_FLOAT,C_Color}),
                                xDrawSplineBasis = define_c_proc(ray,"+DrawSplineBasis",{C_POINTER,C_INT,C_FLOAT,C_Color}),
                                xDrawSplineCatmullRom = define_c_proc(ray,"+DrawSplineCatmullRom",{C_POINTER,C_INT,C_FLOAT,C_Color}),
                                xDrawSplineBezierQuadratic = define_c_proc(ray,"+DrawSplineBezierQuadratic",{C_POINTER,C_INT,C_FLOAT,C_Color}),
                                xDrawSplineBezierCubic = define_c_proc(ray,"+DrawSplineBezierCubic",{C_POINTER,C_INT,C_FLOAT,C_Color}),
                                xDrawSplineSegmentLinear = define_c_proc(ray,"+DrawSplineSegmentLinear",{Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawSplineSegmentBasis = define_c_proc(ray,"+DrawSplineSegmentBasis",{Vector2,Vector2,Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawSplineSegmentCatmullRom = define_c_proc(ray,"+DrawSplineSegmentCatmullRom",{Vector2,Vector2,Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawSplineSegmentBezierQuadratic = define_c_proc(ray,"+DrawSplineSegmentBezierQuadratic",{Vector2,Vector2,Vector2,C_FLOAT,C_Color}),
                                xDrawSplineSegmentBezierCubic = define_c_proc(ray,"+DrawSplineSegmentBezierCubic",{Vector2,Vector2,Vector2,Vector2,C_FLOAT,C_Color})
                                
global procedure DrawSplineLinear(sequence pts,atom count,atom thick,sequence color)
atom buffer=allocate(length(pts)*2*8)
for i= 0 to length(pts)-1
do
    poke(buffer+(i*8),atom_to_float32(pts[i+1][1]))
    poke(buffer+((i*8)+4),atom_to_float32(pts[i+1][2]))
end for
        c_proc(xDrawSplineLinear,{buffer,count,thick,bytes_to_int(color)})
free(buffer)    
end procedure

global procedure DrawSplineBasis(atom pts,atom count,atom thick,sequence color)
        c_proc(xDrawSplineBasis,{pts,count,thick,color})
end procedure

global procedure DrawSplineCatmullRom(atom pts,atom count,atom thick,sequence color)
        c_proc(xDrawSplineCatmullRom,{pts,count,thick,color})
end procedure

global procedure DrawSplineBezierQuadratic(atom pts,atom count,atom thick,sequence color)
        c_proc(xDrawSplineBezierQuadratic,{pts,count,thick,color})
end procedure

global procedure DrawSplineBezierCubic(atom pts,atom count,atom thick,sequence color)
        c_proc(xDrawSplineBezierCubic,{pts,count,thick,color})
end procedure

global procedure DrawSplineSegmentLinear(sequence p1,sequence p2,atom thick,sequence color)
        c_proc(xDrawSplineSegmentLinear,{p1,p2,thick,color})
end procedure

global procedure DrawSplineSegmentBasis(sequence p1,sequence p2,sequence p3,sequence p4,atom thick,sequence color)
        c_proc(xDrawSplineSegmentBasis,{p1,p2,p3,p4,thick,color})
end procedure

global procedure DrawSplineSegmentCatmullRom(sequence p1,sequence p2,sequence p3,sequence p4,atom thick,sequence color)
        c_proc(xDrawSplineSegmentCatmullRom,{p1,p2,p3,p4,thick,color})
end procedure

global procedure DrawSplineSegmentBezierQuadratic(sequence p1,sequence p2,sequence p3,atom thick,sequence color)
        c_proc(xDrawSplineSegmentBezierQuadratic,{p1,p2,p3,thick,color})
end procedure

global procedure DrawSplineSegmentBezierCubic(sequence p1,sequence c2, sequence c3,sequence p4,atom thick,sequence color)
        c_proc(xDrawSplineSegmentBezierCubic,{p1,c2,c3,p4,thick,color})
end procedure

--Spline segment point evaluation functions
global constant xGetSplinePointLinear = define_c_func(ray,"+GetSplinePointLinear",{Vector2,Vector2,C_FLOAT},Vector2),
                                xGetSplinePointBasis = define_c_func(ray,"+GetSplinePointBasis",{Vector2,Vector2,Vector2,Vector2,C_FLOAT},Vector2),
                                xGetSplinePointCatmullRom = define_c_func(ray,"+GetSplinePointCatmullRom",{Vector2,Vector2,Vector2,Vector2,C_FLOAT},Vector2),
                                xGetSplinePointBezierQuad = define_c_func(ray,"+GetSplinePointBezierQuad",{Vector2,Vector2,Vector2,C_FLOAT},Vector2),
                                xGetSplinePointBezierCubic = define_c_func(ray,"+GetSplinePointBezierCubic",{Vector2,Vector2,Vector2,Vector2,C_FLOAT},Vector2)
                                
global function GetSplinePointLinear(sequence start,sequence endPos,atom t)
        return c_func(xGetSplinePointLinear,{start,endPos,t})
end function

global function GetSplinePointBasis(sequence p1,sequence p2,sequence p3,sequence p4,atom t)
        return c_func(xGetSplinePointBasis,{p1,p2,p3,p4,t})
end function

global function GetSplinePointCatmullRom(sequence p1,sequence p2,sequence p3,sequence p4,atom t)
        return c_func(xGetSplinePointCatmullRom,{p1,p2,p3,p4,t})
end function

global function GetSplinePointBezierQuad(sequence p1,sequence c2,sequence p3,atom t)
        return c_func(xGetSplinePointBezierQuad,{p1,c2,p3,t})
end function

global function GetSplinePointBezierCubic(sequence p1,sequence c2,sequence c3,sequence p4,atom t)
        return c_func(xGetSplinePointBezierCubic,{p1,c2,c3,p4,t})
end function

--Shape collision detection functions
constant xCheckCollisionRecs = define_c_func(ray,"+CheckCollisionRecs",{Rectangle,Rectangle},C_BOOL),
                                xCheckCollisionCircles = define_c_func(ray,"+CheckCollisionCircles",{Vector2,C_FLOAT,Vector2,C_FLOAT},C_BOOL),
                                xCheckCollisionCircleRec = define_c_func(ray,"+CheckCollisionCircleRec",{Vector2,C_FLOAT,Rectangle},C_BOOL),
                                xCheckCollisionCircleLine = define_c_func(ray,"+CheckCollisionCircleLine",{Vector2,C_FLOAT,Vector2,Vector2},C_BOOL),
                                xCheckCollisionPointRec = define_c_func(ray,"+CheckCollisionPointRec",{Vector2,Rectangle},C_BOOL),
                                xCheckCollisionPointCircle = define_c_func(ray,"+CheckCollisionPointCircle",{Vector2,Vector2,C_FLOAT},C_BOOL),
                                xCheckCollisionPointTriangle = define_c_func(ray,"+CheckCollisionPointTriangle",{Vector2,Vector2,Vector2,Vector2},C_BOOL),
                                xCheckCollisionPointLine = define_c_func(ray,"+CheckCollisionPointLine",{Vector2,Vector2,Vector2,C_INT},C_BOOL),
                                xCheckCollisionPointPoly = define_c_func(ray,"+CheckCollisionPointPoly",{Vector2,C_POINTER,C_INT},C_BOOL),
                                xCheckCollisionLines = define_c_func(ray,"+CheckCollisionLines",{Vector2,Vector2,Vector2,Vector2,C_POINTER},C_BOOL),
                                xGetCollisionRec = define_c_func(ray,"+GetCollisionRec",{C_HPTR,Rectangle,Rectangle},Rectangle)
                                
global function CheckCollisionRecs(sequence rec,sequence rec2)
atom memA=allocate(20)
poke(memA,atom_to_float32(rec[1]))
poke(memA+4,atom_to_float32(rec[2]))
poke(memA+8,atom_to_float32(rec[3]))
poke(memA+12,atom_to_float32(rec[4]))
atom memB=allocate(20)
poke(memB,atom_to_float32(rec2[1]))
poke(memB+4,atom_to_float32(rec2[2]))
poke(memB+8,atom_to_float32(rec2[3]))
poke(memB+12,atom_to_float32(rec2[4]))
atom erg
        erg = c_func(xCheckCollisionRecs,{memA,memB})
free(memA)
free(memB)
return erg
end function

global function CheckCollisionCircles(sequence center,atom rad,sequence center2,atom rad2)
        return c_func(xCheckCollisionCircles,{V2toReg(center),rad,V2toReg(center2),rad2})
end function

global function CheckCollisionCircleRec(sequence center,atom rad,sequence rec)
atom mem=allocate(size_rectangle)
        return and_bits(c_func(xCheckCollisionCircleRec,{V2toReg(center),rad,poke_rectangle(mem,rec)}),1)
free(mem)
end function

global function CheckCollisionCircleLine(sequence center,atom rad,sequence p1,sequence p2)
        return c_func(xCheckCollisionCircleLine,{V2toReg(center),rad,V2toReg(p1),V2toReg(p2)})
end function

global function CheckCollisionPointRec(sequence point,sequence rec)
atom mem=allocate(16)
atom result=0
poke(mem,atom_to_float32(rec[1]))
poke(mem+4,atom_to_float32(rec[2]))
poke(mem+8,atom_to_float32(rec[3]))
poke(mem+12,atom_to_float32(rec[4]))
        result = c_func(xCheckCollisionPointRec,{V2toReg(point),mem})
free(mem)
return result
end function

global function CheckCollisionPointCircle(sequence point,sequence center,atom rad)
        return and_bits(c_func(xCheckCollisionPointCircle,{V2toReg(point),V2toReg(center),rad}),1)
end function

global function CheckCollisionPointTriangle(sequence point,sequence p1,sequence p2,sequence p3)
        return c_func(xCheckCollisionPointTriangle,{V2toReg(point),V2toReg(p1),V2toReg(p2),V2toReg(p3)})
end function

global function CheckCollisionPointLine(sequence point,sequence p1,sequence p2,atom threshold)
        return c_func(xCheckCollisionPointLine,{V2toReg(point),V2toReg(p1),V2toReg(p2),threshold})
end function

global function CheckCollisionPointPoly(sequence point,atom points,atom count)
        return c_func(xCheckCollisionPointPoly,{V2toReg(point),points,count})
end function

global function CheckCollisionLines(sequence start,sequence endpos,sequence start2,sequence pos2,atom cpoint)
        return c_func(xCheckCollisionLines,{V2toReg(start),V2toReg(endpos),V2toReg(start2),V2toReg(pos2),cpoint})
end function

global function GetCollisionRec(sequence rec,sequence rec2)
atom memA=allocate(20)
poke(memA,atom_to_float32(rec[1]))
poke(memA+4,atom_to_float32(rec[2]))
poke(memA+8,atom_to_float32(rec[3]))
poke(memA+12,atom_to_float32(rec[4]))
atom memB=allocate(20)
poke(memB,atom_to_float32(rec2[1]))
poke(memB+4,atom_to_float32(rec2[2]))
poke(memB+8,atom_to_float32(rec2[3]))
poke(memB+12,atom_to_float32(rec2[4]))
atom memC=allocate(20)
sequence result={0,0,0,0}
atom erg
        erg = c_func(xGetCollisionRec,{memC,memA,memB})
if not equal(memC,erg) then
    crash("Something ugly in : GetCollisionRec")
end if
result[1]=float32_to_atom(peek({memC,4}))
result[2]=float32_to_atom(peek({memC+4,4}))
result[3]=float32_to_atom(peek({memC+8,4}))
result[4]=float32_to_atom(peek({memC+12,4}))
free(memA)
free(memB)
free(memC)
return result
end function

--Image loading functions
global constant xLoadImage = define_c_func(ray,"+LoadImage",{C_HPTR,C_STRING},Image),
                                xLoadImageRaw = define_c_func(ray,"+LoadImageRaw",{C_STRING,C_INT,C_INT,C_INT,C_INT},Image),
                                xLoadImageAnim = define_c_func(ray,"+LoadImageAnim",{C_HPTR,C_STRING,C_POINTER},Image),
                                xLoadImageAnimFromMemory = define_c_func(ray,"+LoadImageAnimFromMemory",{C_STRING,C_POINTER,C_INT,C_POINTER},Image),
                                xLoadImageFromMemory = define_c_func(ray,"+LoadImageFromMemory",{C_STRING,C_POINTER,C_INT},Image),
                                xLoadImageFromTexture = define_c_func(ray,"+LoadImageFromTexture",{Texture2D},Image),
                                xLoadImageFromScreen = define_c_func(ray,"+LoadImageFromScreen",{},Image),
                                xIsImageValid = define_c_func(ray,"+IsImageValid",{Image},C_BOOL),
                                xUnloadImage = define_c_proc(ray,"+UnloadImage",{Image}),
                                xExportImage = define_c_func(ray,"+ExportImage",{Image,C_STRING},C_BOOL),
                                xExportImageToMemory = define_c_func(ray,"+ExportImageToMemory",{Image,C_STRING,C_POINTER},C_POINTER),
                                xExportImageAsCode = define_c_func(ray,"+ExportImageAsCode",{Image,C_STRING},C_BOOL)
                                
global function LoadImage(sequence fName)
atom mem=allocate(24)
atom pstr=allocate_string(fName)
sequence result={0,0,0,0,0}
atom ptr=0
        ptr = c_func(xLoadImage,{mem,pstr})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)

free(mem)
free(pstr)
return result
end function

global function LoadImageRaw(sequence fName,atom width,atom height,atom format,atom headerSize)
        return c_func(xLoadImageRaw,{fName,width,height,format,headerSize})
end function

global function LoadImageAnim(sequence fName,atom frames) --frames need to be a pointer to int
atom mem=allocate(24)
atom pstr=allocate_string(fName)
sequence result={0,0,0,0,0}
atom ptr=0
        ptr = c_func(xLoadImageAnim,{mem,pstr,frames})
--result[1]=peek8u(mem)
--result[2]=peek4s(mem+8)
--result[3]=peek4s(mem+12)
--result[4]=peek4s(mem+16)
--result[5]=peek4s(mem+20)
result=peek_image(mem)
free(mem)
free(pstr)
return result
end function

global function LoadImageAnimFromMemory(sequence fileType,atom fileData,atom dataSize,atom frames)
        return c_func(xLoadImageAnimFromMemory,{fileType,fileData,dataSize,frames})
end function

global function LoadImageFromMemory(sequence fileType,atom fileData,atom dataSize)
        return c_func(xLoadImageFromMemory,{fileType,fileData,dataSize})
end function

global function LoadImageFromTexture(sequence tex)
        return c_func(xLoadImageFromTexture,{tex})
end function

global function LoadImageFromScreen()
        return c_func(xLoadImageFromScreen,{})
end function

global function IsImageValid(sequence image)
atom addr=allocate(size_image)
integer result=0
        result= c_func(xIsImageValid,{poke_image(addr,image)})
free(addr)
return result
end function

global procedure UnloadImage(sequence image)
atom mem=allocate(24)
poke8(mem,image[1])
poke4(mem+8,image[2])
poke4(mem+12,image[3])
poke4(mem+16,image[4])
poke4(mem+20,image[5])
        c_proc(xUnloadImage,{mem})
free(mem)
end procedure

global function ExportImage(sequence image,sequence fName)
        return c_func(xExportImage,{image,fName})
end function

global function ExportImageToMemory(sequence image,sequence fileType,atom fileSize)
        return c_func(xExportImageToMemory,{image,fileType,fileSize})
end function

global function ExportImageAsCode(sequence image,sequence fName)
        return c_func(xExportImageAsCode,{image,fName})
end function

--Image generation functions
constant xGenImageColor = define_c_func(ray,"+GenImageColor",{C_HPTR,C_INT,C_INT,C_Color},Image),
                                xGenImageGradientLinear = define_c_func(ray,"+GenImageGradientLinear",{C_HPTR,C_INT,C_INT,C_INT,C_Color,C_Color},Image),
                                xGenImageGradientRadial = define_c_func(ray,"+GenImageGradientRadial",{C_HPTR,C_INT,C_INT,C_FLOAT,C_Color,C_Color},Image),
                                xGenImageGradientSquare = define_c_func(ray,"+GenImageGradientSquare",{C_HPTR,C_INT,C_INT,C_FLOAT,C_Color,C_Color},Image),
                                xGenImageChecked = define_c_func(ray,"+GenImageChecked",{C_HPTR,C_INT,C_INT,C_INT,C_INT,C_Color,C_Color},Image),
                                xGenImageWhiteNoise = define_c_func(ray,"+GenImageWhiteNoise",{C_HPTR,C_INT,C_INT,C_FLOAT},Image),
                                xGenImagePerlinNoise = define_c_func(ray,"+GenImagePerlinNoise",{C_HPTR,C_INT,C_INT,C_INT,C_INT,C_FLOAT},Image),
                                xGenImageCellular = define_c_func(ray,"+GenImageCellular",{C_HPTR,C_INT,C_INT,C_INT},Image),
                                xGenImageText = define_c_func(ray,"+GenImageText",{C_HPTR,C_INT,C_INT,C_STRING},Image)
                                
global function GenImageColor(atom width,atom height,sequence color)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr= c_func(xGenImageColor,{mem,width,height,bytes_to_int(color)})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global function GenImageGradientLinear(atom width,atom height,atom direction,sequence start,sequence cend)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageGradientLinear,{mem,width,height,direction,bytes_to_int(start),bytes_to_int(cend)})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result       
end function

global function GenImageGradientRadial(atom width,atom height,atom density,sequence inner,sequence outer)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageGradientRadial,{mem,width,height,density,bytes_to_int(inner),bytes_to_int(outer)})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global function GenImageGradientSquare(atom width,atom height,atom density,sequence inner,sequence outer)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageGradientSquare,{mem,width,height,density,bytes_to_int(inner),bytes_to_int(outer)})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result   
end function

global function GenImageChecked(atom width,atom height,atom x,atom y,sequence col,sequence col2)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageChecked,{mem,width,height,x,y,bytes_to_int(col),bytes_to_int(col2)})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global function GenImageWhiteNoise(atom width,atom height,atom factor)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageWhiteNoise,{mem,width,height,factor})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result       
end function

global function GenImagePerlinNoise(atom width,atom height,atom x,atom y,atom scale)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImagePerlinNoise,{mem,width,height,x,y,scale})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global function GenImageCellular(atom width,atom height,atom tileSize)
atom mem=allocate(24)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageCellular,{mem,width,height,tileSize})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(mem)
return result
end function

global function GenImageText(atom width,atom height,sequence text)
atom mem=allocate(24)
atom pstr=allocate_string(text)
atom ptr
sequence result={0,0,0,0,0}
        ptr = c_func(xGenImageText,{mem,width,height,pstr})
result[1]=peek8u(mem)
result[2]=peek4s(mem+8)
result[3]=peek4s(mem+12)
result[4]=peek4s(mem+16)
result[5]=peek4s(mem+20)
free(pstr)
free(mem)
return result
end function

--Image manipulation functions
constant xImageCopy = define_c_func(ray,"+ImageCopy",{C_HPTR,Image},Image),
                                xImageFromImage = define_c_func(ray,"+ImageFromImage",{C_HPTR,Image,Rectangle},Image),
                                xImageFromChannel = define_c_func(ray,"+ImageFromChannel",{Image,C_INT},Image),
                                xImageText = define_c_func(ray,"+ImageText",{C_STRING,C_INT,C_Color},Image),
                                xImageTextEx = define_c_func(ray,"+ImageTextEx",{Font,C_STRING,C_FLOAT,C_FLOAT,C_Color},Image),
                                xImageFormat = define_c_proc(ray,"+ImageFormat",{C_POINTER,C_INT}),
                                xImageToPOT = define_c_proc(ray,"+ImageToPOT",{C_POINTER,C_Color}),
                                xImageCrop = define_c_proc(ray,"+ImageCrop",{C_POINTER,Rectangle}),
                                xImageAlphaCrop = define_c_proc(ray,"+ImageAlphaCrop",{C_POINTER,C_FLOAT}),
                                xImageAlphaClear = define_c_proc(ray,"+ImageAlphaClear",{C_POINTER,C_Color,C_FLOAT}),
                                xImageAlphaMask = define_c_proc(ray,"+ImageAlphaMask",{C_POINTER,Image}),
                                xImageAlphaPremultiply = define_c_proc(ray,"+ImageAlphaPremultiply",{C_POINTER}),
                                xImageBlurGaussian = define_c_proc(ray,"+ImageBlurGaussian",{C_POINTER,C_INT}),
                                xImageKernelConvolution = define_c_proc(ray,"+ImageKernelConvolution",{C_POINTER,C_POINTER,C_INT}),
                                xImageResize = define_c_proc(ray,"+ImageResize",{C_POINTER,C_INT,C_INT}),
                                xImageResizeNN = define_c_proc(ray,"+ImageResizeNN",{C_POINTER,C_INT,C_INT}),
                                xImageResizeCanvas = define_c_proc(ray,"+ImageResizeCanvas",{C_POINTER,C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xImageMipmaps = define_c_proc(ray,"+ImageMipmaps",{C_POINTER}),
                                xImageDither = define_c_proc(ray,"+ImageDither",{C_POINTER,C_INT,C_INT,C_INT,C_INT}),
                                xImageFlipVertical = define_c_proc(ray,"+ImageFlipVertical",{C_POINTER}),
                                xImageFlipHorizontal = define_c_proc(ray,"+ImageFlipHorizontal",{C_POINTER}),
                                xImageRotate = define_c_proc(ray,"+ImageRotate",{C_POINTER,C_INT}),
                                xImageRotateCW = define_c_proc(ray,"+ImageRotateCW",{C_POINTER}),
                                xImageRotateCCW = define_c_proc(ray,"+ImageRotateCCW",{C_POINTER}),
                                xImageColorTint = define_c_proc(ray,"+ImageColorTint",{C_POINTER,C_Color}),
                                xImageColorInvert = define_c_proc(ray,"+ImageColorInvert",{C_POINTER}),
                                xImageColorGrayscale = define_c_proc(ray,"+ImageColorGrayscale",{C_POINTER}),
                                xImageColorContrast = define_c_proc(ray,"+ImageColorContrast",{C_POINTER,C_FLOAT}),
                                xImageColorBrightness = define_c_proc(ray,"+ImageColorBrightness",{C_POINTER,C_INT}),
                                xImageColorReplace = define_c_proc(ray,"+ImageColorReplace",{C_POINTER,C_Color,C_Color}),
                                xLoadImageColors = define_c_func(ray,"+LoadImageColors",{Image},C_POINTER),
                                xLoadImagePalette = define_c_func(ray,"+LoadImagePalette",{Image,C_INT,C_POINTER},C_POINTER),
                                xUnloadImageColors = define_c_proc(ray,"+UnloadImageColors",{C_POINTER}),
                                xUnloadImagePalette = define_c_proc(ray,"+UnloadImagePalette",{C_POINTER}),
                                xGetImageAlphaBorder = define_c_func(ray,"+GetImageAlphaBorder",{Image,C_FLOAT},Rectangle),
                                xGetImageColor = define_c_func(ray,"+GetImageColor",{Image,C_INT,C_INT},C_Color)
                                
global function ImageCopy(sequence image)
atom mem=allocate(size_image)
atom img=allocate(size_image)
atom ptr
        ptr = c_func(xImageCopy,{mem,poke_image(img,image)})
sequence result=peek_image(ptr)
free(mem)
free(img)
return result
end function

global function ImageFromImage(sequence image,sequence rec)
atom mem=allocate(size_image)
atom rect=allocate(size_rectangle)
atom ptr
sequence result
        ptr = c_func(xImageFromImage,{mem,poke_image(mem,image),poke_rectangle(rect,rec)})
        result=peek_image(ptr)
free(rect)
free(mem)
return (result)
end function

global function ImageFromChannel(sequence image,atom selectChannel)
        return c_func(xImageFromChannel,{image,selectChannel})
end function

global function ImageText(sequence text,atom fontSize,sequence color)
        return c_func(xImageText,{text,fontSize,color})
end function

global function ImageTextEx(sequence font,sequence text,atom fontSize,atom space,sequence tint)
        return c_func(xImageTextEx,{font,text,fontSize,space,tint})
end function

global function ImageFormat(sequence image,atom newFormat)
atom mem=allocate(size_image)
        c_proc(xImageFormat,{poke_image(mem,image),newFormat})
sequence result=peek_image(mem)
free(mem)
return result
end function

global procedure ImageToPOT(atom image,sequence fill)
        c_proc(xImageToPOT,{image,fill})
end procedure

global procedure ImageCrop(atom image,sequence crop)
        c_proc(xImageCrop,{image,crop})
end procedure

global procedure ImageAlphaCrop(atom image,atom threshold)
        c_proc(xImageAlphaCrop,{image,threshold})
end procedure

global procedure ImageAlphaClear(atom image,sequence color,atom threshold)
        c_proc(xImageAlphaClear,{image,color,threshold})
end procedure

global procedure ImageAlphaMask(atom image,sequence mask)
        c_proc(xImageAlphaMask,{image,mask})
end procedure

global procedure ImageAlphaPremultiply(atom image)
        c_proc(xImageAlphaPremultiply,{image})
end procedure

global procedure ImageBlurGaussian(atom image,atom blurSize)
        c_proc(xImageBlurGaussian,{image,blurSize})
end procedure

global procedure ImageKernelConvolution(atom image,atom kernel,atom size)
        c_proc(xImageKernelConvolution,{image,kernel,size})
end procedure

global procedure ImageResize(atom image,atom width,atom height)
        c_proc(xImageResize,{image,width,height})
end procedure

global procedure ImageResizeNN(atom image,atom width,atom height)
        c_proc(xImageResizeNN,{image,width,height})
end procedure

global procedure ImageResizeCanvas(atom image,atom width,atom height,atom x,atom y,sequence fill)
        c_proc(xImageResizeCanvas,{image,width,height,x,y,fill})
end procedure

global procedure ImageMipmaps(atom image)
        c_proc(xImageMipmaps,{image})
end procedure

global procedure ImageDither(atom image,atom r,atom g,atom b,atom a)
        c_proc(xImageDither,{image,r,g,b,a})
end procedure

global procedure ImageFlipVertical(atom image)
        c_proc(xImageFlipVertical,{image})
end procedure

global procedure ImageFlipHorizontal(atom image)
        c_proc(xImageFlipHorizontal,{image})
end procedure

global procedure ImageRotate(atom image,atom degrees)
        c_proc(xImageRotate,{image,degrees})
end procedure

global procedure ImageRotateCW(atom image)
        c_proc(xImageRotateCW,{image})
end procedure

global procedure ImageRotateCCW(atom image)
        c_proc(xImageRotateCCW,{image})
end procedure

global procedure ImageColorTint(atom image,sequence color)
        c_proc(xImageColorTint,{image,color})
end procedure

global procedure ImageColorInvert(atom image)
        c_proc(xImageColorInvert,{image})
end procedure

global procedure ImageColorGrayscale(atom image)
        c_proc(xImageColorGrayscale,{image})
end procedure

global procedure ImageColorContrast(atom image,atom contrast)
        c_proc(xImageColorContrast,{image,contrast})
end procedure

global procedure ImageColorBrightness(atom image,atom bright)
        c_proc(xImageColorBrightness,{image,bright})
end procedure

global procedure ImageColorReplace(atom image,sequence color,sequence replace)
        c_proc(xImageColorReplace,{image,color,replace})
end procedure

global function LoadImageColors(sequence image,integer raw=0)
atom mem=allocate(size_image)
integer width=2,height=3
integer numPixels = image[width] * image[height]
atom pPixels=c_func(xLoadImageColors,{poke_image(mem,image)})
free(mem)
if raw then
        return pPixels
else
        ---- Lies alle Bytes auf einmal 
        sequence rawBytes = peek({pPixels, numPixels * 4})
        --  Die Farben als {R,G,B,A} Gruppen:
        sequence colors = {}
        for i=1 to length(rawBytes) by 4 do
            colors = append(colors, {rawBytes[i], rawBytes[i+1], rawBytes[i+2], rawBytes[i+3]})
        end for
        colors=append(colors,pPixels) -- pointer noch anhaengen zum wieder freigeben
        return colors
end if

end function

global function LoadImagePalette(sequence image,atom size,atom count)
        return c_func(xLoadImagePalette,{image,size,count})
end function

global procedure UnloadImageColors(object  colors)
atom ptrforfree
if sequence(colors) then
    ptrforfree=colors[$]
else
    ptrforfree=colors
end if
        c_proc(xUnloadImageColors,{ptrforfree})
end procedure

global procedure UnloadImagePalette(atom colors)
        c_proc(xUnloadImagePalette,{colors})
end procedure

global function GetImageAlphaBorder(sequence image,atom threshold)
        return c_func(xGetImageAlphaBorder,{image,threshold})
end function

global function GetImageColor(sequence image,atom x,atom y)
        return c_func(xGetImageColor,{image,x,y})
end function

--Image drawing functions
constant xImageClearBackground = define_c_proc(ray,"+ImageClearBackground",{C_POINTER,C_Color}),
                                xImageDrawPixel = define_c_proc(ray,"+ImageDrawPixel",{C_POINTER,C_INT,C_INT,C_Color}),
                                xImageDrawPixelV = define_c_proc(ray,"+ImageDrawPixelV",{C_POINTER,Vector2,C_Color}),
                                xImageDrawLine = define_c_proc(ray,"+ImageDrawLine",{C_POINTER,C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xImageDrawLineV = define_c_proc(ray,"+ImageDrawLineV",{C_POINTER,Vector2,Vector2,C_Color}),
                                xImageDrawLineEx = define_c_proc(ray,"+ImageDrawLineEx",{C_POINTER,Vector2,Vector2,C_INT,C_Color}),
                                xImageDrawCircle = define_c_proc(ray,"+ImageDrawCircle",{C_POINTER,C_INT,C_INT,C_INT,C_Color}),
                                xImageDrawCircleV = define_c_proc(ray,"+ImageDrawCircleV",{C_POINTER,Vector2,C_INT,C_Color}),
                                xImageDrawCircleLines = define_c_proc(ray,"+ImageDrawCircleLines",{C_POINTER,C_INT,C_INT,C_INT,C_Color}),
                                xImageDrawCircleLinesV = define_c_proc(ray,"+ImageDrawCircleLinesV",{C_POINTER,Vector2,C_INT,C_Color}),
                                xImageDrawRectangle = define_c_proc(ray,"+ImageDrawRectangle",{C_POINTER,C_INT,C_INT,C_INT,C_INT,C_Color}),
                                xImageDrawRectangleV = define_c_proc(ray,"+ImageDrawRectangleV",{C_POINTER,Vector2,Vector2,C_Color}),
                                xImageDrawRectangleRec = define_c_proc(ray,"+ImageDrawRectangleRec",{C_POINTER,Rectangle,C_Color}),
                                xImageDrawRectangleLines = define_c_proc(ray,"+ImageDrawRectangleLines",{C_POINTER,Rectangle,C_INT,C_Color}),
                                xImageDrawTriangle = define_c_proc(ray,"+ImageDrawTriangle",{C_POINTER,Vector2,Vector2,Vector2,C_Color}),
                                xImageDrawTriangleEx = define_c_proc(ray,"+ImageDrawTriangleEx",{C_POINTER,Vector2,Vector2,Vector2,C_Color,C_Color,C_Color}),
                                xImageDrawTriangleLines = define_c_proc(ray,"+ImageDrawTriangleLines",{C_POINTER,Vector2,Vector2,Vector2,C_Color}),
                                xImageDrawTriangleFan = define_c_proc(ray,"+ImageDrawTriangleFan",{C_POINTER,C_POINTER,C_INT,C_Color}),
                                xImageDrawTriangleStrip = define_c_proc(ray,"+ImageDrawTriangleStrip",{C_POINTER,C_POINTER,C_INT,C_Color}),
                                xImageDraw = define_c_proc(ray,"+ImageDraw",{C_POINTER,Image,Rectangle,Rectangle,C_Color}),
                                xImageDrawText = define_c_proc(ray,"+ImageDrawText",{C_POINTER,C_STRING,C_INT,C_INT,C_INT,C_Color}),
                                xImageDrawTextEx = define_c_proc(ray,"+ImageDrawTextEx",{C_POINTER,Font,C_STRING,Vector2,C_FLOAT,C_FLOAT,C_Color})
                                
global function ImageClearBackground(sequence dst,sequence color)
atom mem=allocate(size_image)
        c_proc(xImageClearBackground,{poke_image(mem,dst),bytes_to_int(color)})
sequence result=peek_image(mem)
return result
end function

global procedure ImageDrawPixel(atom dst,atom x,atom y,sequence color)
        c_proc(xImageDrawPixel,{dst,x,y,color})
end procedure

global procedure ImageDrawPixelV(atom dst,sequence pos,sequence color)
        c_proc(xImageDrawPixelV,{dst,pos,color})
end procedure

global procedure ImageDrawLine(atom dst,atom x,atom y,atom endx,atom endy,sequence color)
        c_proc(xImageDrawLine,{dst,x,y,endx,endy,color})
end procedure

global procedure ImageDrawLineV(atom dst,sequence start,sequence e,sequence color)
        c_proc(xImageDrawLine,{dst,start,e,color})
end procedure

global procedure ImageDrawLineEx(atom dst,sequence start,sequence e,atom thick,sequence color)
        c_proc(xImageDrawLineEx,{dst,start,e,thick,color})
end procedure

global procedure ImageDrawCircle(atom dst,atom x,atom y,atom rad,sequence color)
        c_proc(xImageDrawCircle,{dst,x,y,rad,color})
end procedure

global procedure ImageDrawCircleV(atom dst,sequence center,atom rad,sequence color)
        c_proc(xImageDrawCircleV,{dst,center,rad,color})
end procedure

global procedure ImageDrawCircleLines(atom dst,atom x,atom y,atom rad,sequence color)
        c_proc(xImageDrawCircleLines,{dst,x,y,rad,color})
end procedure

global procedure ImageDrawCircleLinesV(atom dst,sequence center,atom rad,sequence color)
        c_proc(xImageDrawCircleLinesV,{dst,center,rad,color})
end procedure

global procedure ImageDrawRectangle(atom dst,atom x,atom y,atom width,atom height,sequence color)
        c_proc(xImageDrawRectangle,{dst,x,y,width,height,color})
end procedure

global procedure ImageDrawRectangleV(atom dst,sequence pos,sequence size,sequence color)
        c_proc(xImageDrawRectangleV,{dst,pos,size,color})
end procedure

global procedure ImageDrawRectangleRec(atom dst,sequence rec,sequence color)
        c_proc(xImageDrawRectangleRec,{dst,rec,color})
end procedure

global procedure ImageDrawRectangleLines(atom dst,sequence rec,atom thick,sequence color)
        c_proc(xImageDrawRectangleLines,{dst,rec,thick,color})
end procedure

global procedure ImageDrawTriangle(atom dst,sequence v,sequence v2,sequence v3,sequence color)
        c_proc(xImageDrawTriangle,{dst,v,v2,v3,color})
end procedure

global procedure ImageDrawTriangleEx(atom dst,sequence v,sequence v2,sequence v3,sequence c,sequence c2,sequence c3)
        c_proc(xImageDrawTriangleEx,{dst,v,v2,v3,c,c2,c3})
end procedure

global procedure ImageDrawTriangleLines(atom dst,sequence v,sequence v2,sequence v3,sequence color)
        c_proc(xImageDrawTriangleLines,{dst,v,v2,v3,color})
end procedure

global procedure ImageDrawTriangleFan(atom dst,atom points,atom count,sequence color)
        c_proc(xImageDrawTriangleFan,{dst,points,count,color})
end procedure

global procedure ImageDrawTriangleStrip(atom dst,atom points,atom count,sequence color)
        c_proc(xImageDrawTriangleStrip,{dst,points,count,color})
end procedure

global procedure ImageDraw(atom dst,sequence src,sequence srcRec,sequence dstRec,sequence tint)
        c_proc(xImageDraw,{dst,src,srcRec,dstRec,tint})
end procedure

global procedure ImageDrawText(atom dst,sequence text,atom x,atom y,atom size,sequence color)
        c_proc(xImageDrawText,{dst,text,x,y,size,color})
end procedure

global procedure ImageDrawTextEx(atom dst,sequence font,sequence text,sequence pos,atom size,atom space,sequence tint)
        c_proc(xImageDrawTextEx,{dst,font,text,pos,size,space,tint})
end procedure

--Texture loading functions
global constant xLoadTexture = define_c_func(ray,"+LoadTexture",{C_HPTR,C_STRING},Texture2D),
                                xLoadTextureFromImage = define_c_func(ray,"+LoadTextureFromImage",{C_HPTR,Image},Texture2D),
                                xLoadTextureCubemap = define_c_func(ray,"+LoadTextureCubemap",{Image,C_INT},TextureCubemap),
                                xLoadRenderTexture = define_c_func(ray,"+LoadRenderTexture",{C_HPTR,C_INT,C_INT},RenderTexture2D),
                                xIsTextureValid = define_c_func(ray,"+IsTextureValid",{Texture2D},C_BOOL),
                                xUnloadTexture = define_c_proc(ray,"+UnloadTexture",{Texture2D}),
                                xIsRenderTextureValid = define_c_func(ray,"+IsRenderTextureValid",{RenderTexture2D},C_BOOL),
                                xUnloadRenderTexture = define_c_proc(ray,"+UnloadRenderTexture",{RenderTexture2D}),
                                xUpdateTexture = define_c_proc(ray,"+UpdateTexture",{Texture2D,C_POINTER}),
                                xUpdateTextureRec = define_c_proc(ray,"+UpdateTextureRec",{Texture2D,Rectangle,C_POINTER})
                                
global function LoadTexture(sequence fname)
sequence tex={0,0,0,0,0}
atom mem= allocate(size_texture)
atom pstr=allocate_string(fname)
atom ptr
        ptr = c_func(xLoadTexture,{mem,pstr})
if not equal(ptr,mem) then
    crash("Something ugly in: LoadTexture")
end if
tex[1]=peek4u(mem)
tex[2]=peek4s(mem+4)
tex[3]=peek4s(mem+8)
tex[4]=peek4s(mem+12)
tex[5]=peek4s(mem+16)       
free (pstr)
free (mem)
return tex
end function

global function LoadTextureFromImage(sequence image)
atom memimg=allocate(24)
atom memtex=allocate(size_texture)
atom ptr
sequence tex ={0,0,0,0,0}
poke8(memimg,image[1])
poke4(memimg+8,image[2])
poke4(memimg+12,image[3])
poke4(memimg+16,image[4])
poke4(memimg+20,image[5])
        ptr = c_func(xLoadTextureFromImage,{memtex,memimg})
if not equal(ptr,memtex) then
    crash("Something ugly in: LoadTexture")
end if
tex[1]=peek4u(memtex)
tex[2]=peek4s(memtex+4)
tex[3]=peek4s(memtex+8)
tex[4]=peek4s(memtex+12)
tex[5]=peek4s(memtex+16)        
free (memimg)
free (memtex)
return tex
end function

global function LoadTextureCubemap(sequence image,atom layout)
        return c_func(xLoadTextureCubemap,{image,layout})
end function

global function LoadRenderTexture(atom width,atom height)
atom addr=allocate(size_rendertexture)
sequence result
atom ptr=0
        ptr= c_func(xLoadRenderTexture,{addr,width,height})
result=peek_rendertexture(addr)
free(addr)
return result
end function

global function IsTextureValid(sequence tex)
        return c_func(xIsTextureValid,{tex})
end function

global procedure UnloadTexture(sequence  tex)
atom mem=allocate(size_texture)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
        c_proc(xUnloadTexture,{mem})
free(mem)
end procedure

global function IsRenderTextureValid(sequence target)
        return c_func(xIsRenderTextureValid,{target})
end function

global procedure UnloadRenderTexture(sequence target)
atom addr =allocate(size_rendertexture)
        c_proc(xUnloadRenderTexture,{poke_rendertexture(addr,target)})
free(addr)
end procedure

global procedure UpdateTexture(sequence tex,atom pixels)
atom mem=allocate(size_texture)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
        c_proc(xUpdateTexture,{mem,pixels})
free(mem)
end procedure

global procedure UpdateTextureRec(sequence tex,sequence rec,atom pixels)
        c_proc(xUpdateTextureRec,{tex,rec,pixels})
end procedure

--Texture config functions
global constant xGenTextureMipmaps = define_c_proc(ray,"+GenTextureMipmaps",{C_POINTER}),
                                xSetTextureFilter = define_c_proc(ray,"+SetTextureFilter",{Texture2D,C_INT}),
                                xSetTextureWrap = define_c_proc(ray,"+SetTextureWrap",{Texture2D,C_INT})
                                
global procedure GenTextureMipmaps(atom tex)
        c_proc(xGenTextureMipmaps,{tex})
end procedure

global function SetTextureFilter(sequence tex,atom filter)
atom addr=allocate(size_texture)
        c_proc(xSetTextureFilter,{poke_texture(addr,tex),filter})
sequence result=peek_texture(addr)
free(addr)
return result
end function

global procedure SetTextureWrap(sequence tex,atom _wrap)
        c_proc(xSetTextureWrap,{tex,_wrap})
end procedure

--Texture drawing functions
constant xDrawTexture = define_c_proc(ray,"+DrawTexture",{Texture2D,C_INT,C_INT,C_Color}),
                                xDrawTextureV = define_c_proc(ray,"+DrawTextureV",{Texture2D,Vector2,C_Color}),
                                xDrawTextureEx = define_c_proc(ray,"+DrawTextureEx",{Texture2D,Vector2,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawTextureRec = define_c_proc(ray,"+DrawTextureRec",{Texture2D,Rectangle,Vector2,C_Color}),
                                xDrawTexturePro = define_c_proc(ray,"+DrawTexturePro",{Texture2D,Rectangle,Rectangle,Vector2,C_FLOAT,C_Color}),
                                xDrawTextureNPatch = define_c_proc(ray,"+DrawTextureNPatch",{Texture2D,NPatchInfo,Rectangle,Vector2,C_FLOAT,C_Color})
                                
global procedure DrawTexture(sequence tex,atom x,atom y,sequence color)
atom mem=allocate(20)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
        c_proc(xDrawTexture,{mem,x,y,bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawTextureV(sequence tex,sequence pos,sequence color)
atom mem=allocate(20)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
        c_proc(xDrawTextureV,{mem,V2toReg(pos),bytes_to_int(color)})
free(mem)
end procedure

global procedure DrawTextureEx(sequence tex,sequence pos,atom rotation,atom scale,sequence tint)
atom mem=allocate(20)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
        c_proc(xDrawTextureEx,{mem,V2toReg(pos),rotation,scale,bytes_to_int(tint)})
free(mem)
end procedure

global procedure DrawTextureRec(sequence tex,sequence source,sequence pos,sequence tint)
atom mem=allocate(20)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
atom memrect=allocate(16)
poke(memrect,atom_to_float32(source[1]))
poke(memrect+4,atom_to_float32(source[2]))
poke(memrect+8,atom_to_float32(source[3]))
poke(memrect+12,atom_to_float32(source[4]))
        c_proc(xDrawTextureRec,{mem,memrect,V2toReg(pos),bytes_to_int(tint)})
free(mem)
free(memrect)
end procedure

global procedure DrawTexturePro(sequence tex,sequence source,sequence dst,sequence origin,atom rotation,sequence tint)
atom mem=allocate(20)
poke4(mem,tex[1])
poke4(mem+4,tex[2])
poke4(mem+8,tex[3])
poke4(mem+12,tex[4])
poke4(mem+16,tex[5])
atom memrect1=allocate(16)
poke(memrect1,atom_to_float32(source[1]))
poke(memrect1+4,atom_to_float32(source[2]))
poke(memrect1+8,atom_to_float32(source[3]))
poke(memrect1+12,atom_to_float32(source[4]))
atom memrect2=allocate(16)
poke(memrect2,atom_to_float32(dst[1]))
poke(memrect2+4,atom_to_float32(dst[2]))
poke(memrect2+8,atom_to_float32(dst[3]))
poke(memrect2+12,atom_to_float32(dst[4]))
        c_proc(xDrawTexturePro,{mem,memrect1,memrect2,V2toReg(origin),rotation,bytes_to_int(tint)})
free(mem)
free(memrect1)
free(memrect2)
end procedure

global procedure DrawTextureNPatch(sequence tex,sequence patch,sequence dst,sequence origin,atom rotation,sequence tint)
        c_proc(xDrawTextureNPatch,{tex,patch,dst,origin,rotation,tint})
end procedure

--Color/pixel functions
constant xColorIsEqual = define_c_func(ray,"+ColorIsEqual",{C_Color,C_Color},C_BOOL),
                                xFade = define_c_func(ray,"+Fade",{C_Color,C_FLOAT},C_Color),
                                xColorToInt = define_c_func(ray,"+ColorToInt",{C_Color},C_INT),
                                xColorNormalize = define_c_func(ray,"+ColorNormalize",{C_Color},Vector4),
                                xColorFromNormalized = define_c_func(ray,"+ColorFromNormalized",{Vector4},C_Color),
                                xColorToHSV = define_c_func(ray,"+ColorToHSV",{C_Color},Vector3),
                                xColorFromHSV = define_c_func(ray,"+ColorFromHSV",{C_FLOAT,C_FLOAT,C_FLOAT},C_Color),
                                xColorTint = define_c_func(ray,"+ColorTint",{C_Color,C_Color},C_Color),
                                xColorBrightness = define_c_func(ray,"+ColorBrightness",{C_Color,C_FLOAT},C_Color),
                                xColorContrast = define_c_func(ray,"+ColorContrast",{C_Color,C_FLOAT},C_Color),
                                xColorAlpha = define_c_func(ray,"+ColorAlpha",{C_Color,C_FLOAT},C_Color),
                                xColorAlphaBlend = define_c_func(ray,"+ColorAlphaBlend",{C_Color,C_Color,C_Color},C_Color),
                                xColorLerp = define_c_func(ray,"+ColorLerp",{C_Color,C_Color,C_FLOAT},C_Color),
                                xGetColor = define_c_func(ray,"+GetColor",{C_UINT},C_Color),
                                xGetPixelColor = define_c_func(ray,"+GetPixelColor",{C_POINTER,C_INT},C_Color),
                                xSetPixelColor = define_c_proc(ray,"+SetPixelColor",{C_POINTER,C_Color,C_INT}),
                                xGetPixelDataSize = define_c_func(ray,"+GetPixelDataSize",{C_INT,C_INT,C_INT},C_INT)
                                
public function ColorIsEqual(sequence col,sequence col2)
        return c_func(xColorIsEqual,{bytes_to_int(col),bytes_to_int(col2)})
end function

public function Fade(sequence col,atom alpha)
        return int_to_bytes(c_func(xFade,{bytes_to_int(col),alpha}))
end function

public function ColorToInt(sequence col)
        return c_func(xColorToInt,{bytes_to_int(col)})
end function

public function ColorNormalize(sequence col)
        return c_func(xColorNormalize,{bytes_to_int(col)})
end function

public function ColorFromNormalized(sequence norm)
        return int_to_bytes(c_func(xColorFromNormalized,{norm}))
end function

public function ColorToHSV(sequence col)
        return c_func(xColorToHSV,{bytes_to_int(col)})
end function

public function ColorFromHSV(atom hue,atom saturation,atom val)
        return int_to_bytes(c_func(xColorFromHSV,{hue,saturation,val}))
end function

global function ColorFromHSV_(atom  hue, atom  saturation, atom value_)
sequence color = { 0, 0, 0, 255 }
integer r=1,g=2,b=3
-- Red channel
  
atom k = mod((5.0 + hue/60.0), 6)

    
atom t = 4.0 - k
if (t<k) then k=t else k=k end if
if (k<1) then k=k else k=1 end if
if (k>0) then k=k else k=0 end if    

color[r] = ((value_ - value_*saturation*k)*255.0)
  
-- Green channel
   
k = mod((3.0 + hue/60.0), 6)
    
t = 4.0 - k 
if (t<k) then k=t else k=k end if
if (k<1) then k=k else k=1 end if
if (k>0) then k=k else k=0 end if  
    
color[g] = ((value_ - value_*saturation*k)*255.0)     
-- Blue channel
     
k = mod((1.0 + hue/60.0), 6)
t = 4.0 - k
if (t<k) then k=t else k=k end if
if (k<1) then k=k else k=1 end if
if (k>0) then k=k else k=0 end if     
     
color[b] = ((value_ - value_*saturation*k)*255.0)
    
return color
end function





public function ColorTint(sequence col,sequence tint)
        return int_to_bytes(c_func(xColorTint,{col,tint}))
end function

public function ColorBrightness(sequence col,atom factor)
        return int_to_bytes(c_func(xColorBrightness,{col,factor}))
end function

public function ColorContrast(sequence col,atom contrast)
        return int_to_bytes(c_func(xColorContrast,{col,contrast}))
end function

public function ColorAlpha(sequence col,atom alpha)
        return int_to_bytes(c_func(xColorAlpha,{col,alpha}))
end function

public function ColorAlphaBlend(sequence dst,sequence src,sequence tint)
        return int_to_bytes(c_func(xColorAlphaBlend,{dst,src,tint}))
end function

public function ColorLerp(sequence col,sequence col2,atom factor)
        return int_to_bytes(c_func(xColorLerp,{bytes_to_int(col),bytes_to_int(col2),factor}),4)
end function

public function GetColor(atom hex)
        return int_to_bytes(c_func(xGetColor,{hex}))
end function

public function GetPixelColor(atom ptr,atom _format)
        return int_to_bytes(c_func(xGetPixelColor,{ptr,_format}))
end function

public procedure SetPixelColor(atom ptr,sequence col,atom _format)
        c_proc(xSetPixelColor,{ptr,bytes_to_int(col),_format})
end procedure

public function GetPixelDataSize(atom width,atom height,atom _format)
        return c_func(xGetPixelDataSize,{width,height,_format})
end function

--Font loading functions
constant xGetFontDefault = define_c_func(ray,"+GetFontDefault",{C_HPTR},Font),
                                xLoadFont = define_c_func(ray,"+LoadFont",{C_HPTR,C_STRING},Font),
                                xLoadFontEx = define_c_func(ray,"+LoadFontEx",{C_HPTR,C_STRING,C_INT,C_POINTER,C_INT},Font),
                                xLoadFontFromImage = define_c_func(ray,"+LoadFontFromImage",{Image,C_Color,C_INT},Font),
                                xLoadFontFromMemory = define_c_func(ray,"+LoadFontFromMemory",{C_STRING,C_POINTER,C_INT,C_INT,C_POINTER,C_INT},Font),
                                xIsFontValid = define_c_func(ray,"+IsFontValid",{Font},C_BOOL),
                                xLoadFontData = define_c_func(ray,"+LoadFontData",{C_POINTER,C_INT,C_INT,C_POINTER,C_INT,C_INT},C_POINTER),
                                xGenImageFontAtlas = define_c_func(ray,"+GenImageFontAtlas",{C_POINTER,C_POINTER,C_INT,C_INT,C_INT,C_INT},Image),
                                xUnloadFontData = define_c_proc(ray,"+UnloadFontData",{C_POINTER,C_INT}),
                                xUnloadFont = define_c_proc(ray,"+UnloadFont",{Font}),
                                xExportFontAsCode = define_c_func(ray,"+ExportFontAsCode",{Font,C_STRING},C_BOOL)
                                
public function GetFontDefault()
atom mem=allocate(size_font)
atom ptr
sequence font=Tfont
        ptr = c_func(xGetFontDefault,{})
font=peek_font(ptr)
free(mem)
return font
end function

public function LoadFont(sequence fName)
atom mem=allocate(size_font)
atom pstr=allocate_string(fName)
atom ptr
sequence font=Tfont
        ptr= c_func(xLoadFont,{mem,pstr})
font=peek_font(ptr)
free(mem)
free(pstr)
return font
end function

public function LoadFontEx(sequence fName,atom size,atom points,atom count)
atom mem=allocate(size_font)
atom pstr=allocate_string(fName)
atom ptr
sequence font=Tfont
        ptr = c_func(xLoadFontEx,{mem,pstr,size,points,count})
font=peek_font(ptr)
free(mem)
free(pstr)
return font
end function

public function LoadFontFromImage(sequence image,sequence key,atom firstchar)
        return c_func(xLoadFontFromImage,{image,key,firstchar})
end function

public function LoadFontFromMemory(sequence fileType,atom data,atom size,atom fontSize,atom points,atom count)
        return c_func(xLoadFontFromMemory,{fileType,data,size,fontSize,points,count})
end function

public function IsFontValid(sequence font)
        return c_func(xIsFontValid,{font})
end function

public function LoadFontData(atom fileData,atom size,atom fontSize,atom points,atom count,atom _type)
        return c_func(xLoadFontData,{fileData,size,fontSize,points,count,_type})
end function

public function GenImageFontAtlas(atom glyphs,atom recs,atom count,atom size,atom pad,atom pack)
        return c_func(xGenImageFontAtlas,{glyphs,recs,count,size,pad,pack})
end function

public procedure UnloadFontData(atom glyphs,atom count)
        c_proc(xUnloadFontData,{glyphs,count})
end procedure

public procedure UnloadFont(sequence font)
atom mem=allocate(size_font)
        c_proc(xUnloadFont,{poke_font(mem,font)})
free(mem)
end procedure

public function ExportFontAsCode(sequence font,sequence fName)
        return c_func(xExportFontAsCode,{font,fName})
end function

--Text drawing functions
constant xDrawFPS = define_c_proc(ray,"+DrawFPS",{C_INT,C_INT}),
                                xDrawText = define_c_proc(ray,"+DrawText",{C_STRING,C_INT,C_INT,C_INT,C_Color}),
                                xDrawTextEx = define_c_proc(ray,"+DrawTextEx",{Font,C_STRING,Vector2,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawTextPro = define_c_proc(ray,"+DrawTextPro",{Font,C_STRING,Vector2,Vector2,C_FLOAT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawTextCodepoint = define_c_proc(ray,"+DrawTextCodepoint",{Font,C_INT,Vector2,C_FLOAT,C_Color}),
                                xDrawTextCodepoints = define_c_proc(ray,"+DrawTextCodepoints",{Font,C_POINTER,C_INT,Vector2,C_FLOAT,C_FLOAT,C_Color})
                                
public procedure DrawFPS(atom x,atom y)
        c_proc(xDrawFPS,{x,y})
end procedure

public procedure DrawText(sequence text,atom x,atom y,atom fontSize,sequence color)
atom pstr =allocate_string(text)
        c_proc(xDrawText,{pstr,x,y,fontSize,bytes_to_int(color)})
free(pstr)
end procedure

public procedure DrawTextEx(sequence font,sequence text,sequence pos,atom fontSize,atom space,sequence tint)
atom pstr =allocate_string(text)
atom mem=allocate(size_font)
        c_proc(xDrawTextEx,{poke_font(mem,font),pstr,V2toReg(pos),fontSize,space,bytes_to_int(tint)})
free(mem)
free(pstr)
end procedure

public procedure DrawTextPro(sequence  font,sequence text,sequence pos,sequence origin,atom rotation,atom fontSize,atom space,sequence tint)
atom pstr =allocate_string(text)
atom mem=allocate(size_font)
        c_proc(xDrawTextPro,{poke_font(mem,font),pstr,V2toReg(pos),V2toReg(origin),rotation,fontSize,space,bytes_to_int(tint)})
free(mem)
free(pstr)
end procedure

public procedure DrawTextCodepoint(atom font,atom codepoint,sequence pos,atom fontSize,sequence tint)
        c_proc(xDrawTextCodepoint,{font,codepoint,pos,fontSize,tint})
end procedure

public procedure DrawTextCodepoints(atom font,atom codepoints,atom count,sequence pos,atom fontSize,atom space,sequence tint)
        c_proc(xDrawTextCodepoints,{font,codepoints,count,pos,fontSize,space,tint})
end procedure

--Text font info functions
constant xSetTextLineSpacing = define_c_proc(ray,"+SetTextLineSpacing",{C_INT}),
                                xMeasureText = define_c_func(ray,"+MeasureText",{C_STRING,C_INT},C_INT),
                                xMeasureTextEx = define_c_func(ray,"+MeasureTextEx",{Font,C_STRING,C_FLOAT,C_FLOAT},Vector2),
                                xGetGlyphIndex = define_c_func(ray,"+GetGlyphIndex",{Font,C_INT},C_INT),
                                xGetGlyphInfo = define_c_func(ray,"+GetGlyphInfo",{Font,C_INT},GlyphInfo),
                                xGetGlyphAtlasRec = define_c_func(ray,"+GetGlyphAtlasRec",{Font,C_INT},Rectangle)
                                
public procedure SetTextLineSpacing(atom space)
        c_proc(xSetTextLineSpacing,{space})
end procedure

public function MeasureText(sequence text,atom size)
atom pstr=allocate_string(text)
        return c_func(xMeasureText,{pstr,size})
free(pstr)
end function

public function MeasureTextEx(sequence font,sequence text,atom size,atom space)
atom pstr =allocate_string(text)
atom mem=allocate(size_font)

         return RegtoV2(c_func(xMeasureTextEx,{poke_font(mem,font),pstr,size,space}))
free(pstr)
free(mem)

end function

public function GetGlyphIndex(sequence font,atom cpoint)
        return c_func(xGetGlyphIndex,{font,cpoint})     
end function

public function GetGlyphInfo(sequence font,atom cpoint)
        return c_func(xGetGlyphInfo,{font,cpoint})
end function

public function GetGlyphAtlasRec(sequence font,atom cpoint)
        return c_func(xGetGlyphAtlasRec,{font,cpoint})
end function

--Text codepoint functions
constant xLoadUTF8 = define_c_func(ray,"+LoadUTF8",{C_POINTER,C_INT},C_STRING),
                                xUnloadUTF8 = define_c_proc(ray,"+UnloadUTF8",{C_STRING}),
                                xLoadCodepoints = define_c_func(ray,"+LoadCodepoints",{C_STRING,C_POINTER},C_POINTER),
                                xUnloadCodepoints = define_c_proc(ray,"+UnloadCodepoints",{C_POINTER}),
                                xGetCodepointCount = define_c_func(ray,"+GetCodepointCount",{C_STRING},C_INT),
                                xGetCodepoint = define_c_func(ray,"+GetCodepoint",{C_STRING,C_POINTER},C_INT),
                                xGetCodepointNext = define_c_func(ray,"+GetCodepointNext",{C_STRING,C_POINTER},C_INT),
                                xGetCodepointPrevious = define_c_func(ray,"+GetCodepointPrevious",{C_STRING,C_POINTER},C_INT),
                                xCodepointToUTF8 = define_c_func(ray,"+CodepointToUTF8",{C_INT,C_POINTER},C_STRING)
                                
public function LoadUTF8(atom points,atom len)
        return c_func(xLoadUTF8,{points,len})
end function

public procedure UnloadUTF8(sequence text)
        c_proc(xUnloadUTF8,{text})
end procedure

public function LoadCodepoints(sequence text,atom count)
        return c_func(xLoadCodepoints,{text,count})
end function

public procedure UnloadCodepoints(atom points)
        c_proc(xUnloadCodepoints,{points})
end procedure

public function GetCodepointCount(sequence text)
        return c_func(xGetCodepointCount,{text})
end function

public function GetCodepoint(sequence text,atom size)
        return c_func(xGetCodepoint,{text,size})
end function

public function GetCodepointNext(sequence text,atom size)
        return c_func(xGetCodepointNext,{text,size})
end function

public function GetCodepointPrevious(sequence text,atom size)
        return c_func(xGetCodepointPrevious,{text,size})
end function

public function CodepointToUTF8(atom point,atom size)
        return c_func(xCodepointToUTF8,{point,size})
end function

--Text string management functions
constant xTextCopy = define_c_func(ray,"+TextCopy",{C_POINTER,C_STRING},C_INT),
                                xTextIsEqual = define_c_func(ray,"+TextIsEqual",{C_STRING,C_STRING},C_BOOL),
                                xTextLength = define_c_func(ray,"+TextLength",{C_STRING},C_UINT),
                                xTextFormat = define_c_func(ray,"+TextFormat",{C_STRING,C_POINTER},C_STRING),
                                xTextSubtext = define_c_func(ray,"+TextSubtext",{C_STRING,C_INT,C_INT},C_STRING),
                                xTextReplace = define_c_func(ray,"+TextReplace",{C_STRING,C_STRING,C_STRING},C_STRING),
                                xTextInsert = define_c_func(ray,"+TextInsert",{C_STRING,C_STRING,C_INT},C_STRING),
                                xTextJoin = define_c_func(ray,"+TextJoin",{C_STRING,C_INT,C_STRING},C_STRING),
                                xTextSplit = define_c_func(ray,"+TextSplit",{C_STRING,C_CHAR,C_POINTER},C_STRING),
                                xTextAppend = define_c_proc(ray,"+TextAppend",{C_STRING,C_STRING,C_POINTER}),
                                xTextFindIndex = define_c_func(ray,"+TextFindIndex",{C_STRING,C_STRING},C_INT),
                                xTextToUpper = define_c_func(ray,"+TextToUpper",{C_STRING},C_STRING),
                                xTextToLower = define_c_func(ray,"+TextToLower",{C_STRING},C_STRING),
                                xTextToPascal = define_c_func(ray,"+TextToPascal",{C_STRING},C_STRING),
                                xTextToSnake = define_c_func(ray,"+TextToSnake",{C_STRING},C_STRING),
                                xTextToCamel = define_c_func(ray,"+TextToCamel",{C_STRING},C_STRING)
                                
public function TextCopy(object dst,sequence src)
        --dst=src
        -- no need to wrap this in Eu/Phix
        return length(dst)
        --return c_func(xTextCopy,{dst,src})
end function

public function TextIsEqual(sequence text,sequence text2)   
        return equal(text,text2)
        return c_func(xTextIsEqual,{text,text2})
end function

public function TextLength(sequence text)
    return(length(text))
    --  return c_func(xTextLength,{text})
end function

public function TextFormat(sequence text,object x)
text=match_replace("%i",text,"%d")
        --return c_func(xTextFormat,{text,x})
        return sprintf(text,x)
end function

public function TextSubtext(sequence text,atom pos,atom len)
if pos=0 then pos=1 
end if

if pos+len>length(text) 
then
    return text[pos..$] 
end if
        return text[pos..pos+len]
    --  return c_func(xTextSubtext,{text,pos,len})
end function

public function TextReplace(sequence text,sequence replace_,sequence _by)
        return match_replace(text,replace_,_by)
        --return c_func(xTextReplace,{text,replace_,_by})
end function

public function TextInsert(sequence text,sequence _insert,atom pos)
        return text[1..pos]&_insert&text[pos+1..$]
        --return c_func(xTextInsert,{text,insert,pos})
end function

public function TextJoin(sequence text,atom count,sequence del)
        return c_func(xTextJoin,{text,count,del})
end function

public function TextSplit(sequence text,sequence del,atom count)
        return c_func(xTextSplit,{text,del,count})
end function

public procedure TextAppend(sequence text,sequence app,atom pos)
        c_proc(xTextAppend,{text,app,pos})
end procedure

public function TextFindIndex(sequence text,sequence _find)
atom result=-1 
        result = match(text,_find) 
        if result=0 then  --emulate C - function
            return -1
        else  
            return result
        end if
        return result
        --return c_func(xTextFindIndex,{text,_find})
end function

public function TextToUpper(sequence text)
        return upper(text)
--      return c_func(xTextToUpper,{text})
end function

public function TextToLower(sequence text)
        return lower(text)
--      return c_func(xTextToLower,{text})
end function

public function TextToPascal(sequence text)
        return c_func(xTextToPascal,{text})
end function

public function TextToSnake(sequence text)
        return c_func(xTextToSnake,{text})
end function

public function TextToCamel(sequence text)
        return c_func(xTextToCamel,{text})
end function

public constant xTextToInteger = define_c_func(ray,"+TextToInteger",{C_STRING},C_INT),
                xTextToFloat = define_c_func(ray,"+TextToFloat",{C_STRING},C_FLOAT)
                                
public function TextToInteger(sequence text)
        return c_func(xTextToInteger,{text})
end function

public function TextToFloat(sequence text)
        return c_func(xTextToFloat,{text})
end function

--3D shape drawing functions
constant xDrawLine3D = define_c_proc(ray,"+DrawLine3D",{Vector3,Vector3,C_Color}),
                                xDrawPoint3D = define_c_proc(ray,"+DrawPoint3D",{Vector3,C_Color}),
                                xDrawCircle3D = define_c_proc(ray,"+DrawCircle3D",{Vector3,C_FLOAT,Vector3,C_FLOAT,C_Color}),
                                xDrawTriangle3D = define_c_proc(ray,"+DrawTriangle3D",{Vector3,Vector3,Vector3,C_Color}),
                                xDrawTriangleStrip3D = define_c_proc(ray,"+DrawTriangleStrip3D",{C_POINTER,C_INT,C_Color}),
                                xDrawCube = define_c_proc(ray,"+DrawCube",{Vector3,C_FLOAT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawCubeV = define_c_proc(ray,"+DrawCubeV",{Vector3,Vector3,C_Color}),
                                xDrawCubeWires = define_c_proc(ray,"+DrawCubeWires",{Vector3,C_FLOAT,C_FLOAT,C_FLOAT,C_Color}),
                                xDrawCubeWiresV = define_c_proc(ray,"+DrawCubeWiresV",{Vector3,Vector3,C_Color}),
                                xDrawSphere = define_c_proc(ray,"+DrawSphere",{Vector3,C_FLOAT,C_Color}),
                                xDrawSphereEx = define_c_proc(ray,"+DrawSphereEx",{Vector3,C_FLOAT,C_INT,C_INT,C_Color}),
                                xDrawSphereWires = define_c_proc(ray,"+DrawSphereWires",{Vector3,C_FLOAT,C_INT,C_INT,C_Color}),
                                xDrawCylinder = define_c_proc(ray,"+DrawCylinder",{Vector3,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCylinderEx = define_c_proc(ray,"+DrawCylinderEx",{Vector3,Vector3,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCylinderWires = define_c_proc(ray,"+DrawCylinderWires",{Vector3,C_FLOAT,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCylinderWiresEx = define_c_proc(ray,"+DrawCylinderWiresEx",{Vector3,Vector3,C_FLOAT,C_FLOAT,C_INT,C_Color}),
                                xDrawCapsule = define_c_proc(ray,"+DrawCapsule",{Vector3,Vector3,C_FLOAT,C_INT,C_INT,C_Color}),
                                xDrawCapsuleWires = define_c_proc(ray,"+DrawCapsuleWires",{Vector3,Vector3,C_FLOAT,C_INT,C_INT,C_Color}),
                                xDrawPlane = define_c_proc(ray,"+DrawPlane",{Vector3,Vector2,C_Color}),
                                xDrawRay = define_c_proc(ray,"+DrawRay",{Ray,C_Color}),
                                xDrawGrid = define_c_proc(ray,"+DrawGrid",{C_INT,C_FLOAT})
                                
public procedure DrawLine3D(sequence start,sequence ep,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawLine3D,{poke_vector3(v1,start),poke_vector3(v2,ep),bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawPoint3D(sequence pos,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawPoint3D,{poke_vector3(v1,pos),bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawCircle3D(sequence center,atom rad,sequence rotaxis,atom rotang,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCircle3D,{poke_vector3(v1,center),rad,poke_vector3(v2,rotaxis),rotang,bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawTriangle3D(sequence vd1,sequence vd2,sequence vd3,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
atom v3=allocate(size_vector3)
        c_proc(xDrawTriangle3D,{poke_vector3(v1,vd1),poke_vector3(v2,vd2),poke_vector3(v3,vd3),bytes_to_int(col)})
free(v1)
free(v2)
free(v3)
end procedure

public procedure DrawTriangleStrip3D(atom pts,atom count,sequence col)
        c_proc(xDrawTriangleStrip3D,{pts,count,bytes_to_int(col)})
end procedure

public procedure DrawCube(sequence pos,atom width,atom height,atom len,sequence col)
atom mem=allocate(12)
poke(mem,atom_to_float32(pos[1]))
poke(mem+4,atom_to_float32(pos[2]))
poke(mem+8,atom_to_float32(pos[3]))
        c_proc(xDrawCube,{mem,width,height,len,bytes_to_int(col)})
free(mem)
end procedure

public procedure DrawCubeV(sequence pos,sequence size,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCubeV,{poke_vector3(v1,pos),poke_vector3(v2,size),bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawCubeWires(sequence pos,atom width,atom height,atom len,sequence col)
atom mem=allocate(12)
poke(mem,atom_to_float32(pos[1]))
poke(mem+4,atom_to_float32(pos[2]))
poke(mem+8,atom_to_float32(pos[3]))
        c_proc(xDrawCubeWires,{mem,width,height,len,bytes_to_int(col)})
free(mem)
end procedure

public procedure DrawCubeWiresV(sequence pos,sequence size,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCubeWiresV,{poke_vector3(v1,pos),poke_vector3(v2,size),bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawSphere(sequence pos,atom rad,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawSphere,{poke_vector3(v1,pos),rad,bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawSphereEx(sequence pos,atom rad,atom rings,atom slices,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawSphereEx,{poke_vector3(v1,pos),rad,rings,slices,bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawSphereWires(sequence pos,atom rad,atom rings,atom slices,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawSphereWires,{poke_vector3(v1,pos),rad,rings,slices,bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawCylinder(sequence pos,atom radtop,atom radbot,atom height,atom slices,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawCylinder,{poke_vector3(v1,pos),radtop,radbot,height,slices,bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawCylinderEx(sequence start,sequence ep,atom startrad,atom endrad,atom sides,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCylinderEx,{poke_vector3(v1,start),poke_vector3(v2,ep),startrad,endrad,sides,bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawCylinderWires(sequence pos,atom radtop,atom radbot,atom height,atom slices,sequence col)
atom v1=allocate(size_vector3)
        c_proc(xDrawCylinderWires,{poke_vector3(v1,pos),radtop,radbot,height,slices,bytes_to_int(col)})
free(v1)
end procedure

public procedure DrawCylinderWiresEx(sequence start,sequence ep,atom startrad,atom endrad,atom sides,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCylinderWiresEx,{poke_vector3(v1,start),poke_vector3(v2,ep),startrad,endrad,sides,bytes_to_int(col)})
free(v1)
free(v2)
end procedure

--CHECK for 6.1+
public procedure DrawCapsule(sequence startpos,sequence ep,atom rad,atom slices,atom rings,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCapsule,{poke_vector3(v1,startpos),poke_vector3(v2,ep),rad,slices,rings,bytes_to_int(col)})
free(v1)
free(v2)
end procedure
--CHECK for 6.1+
public procedure DrawCapsuleWires(sequence start,sequence ep,atom rad,atom slices,atom rings,sequence col)
atom v1=allocate(size_vector3)
atom v2=allocate(size_vector3)
        c_proc(xDrawCapsuleWires,{poke_vector3(v1,start),poke_vector3(v2,ep),rad,slices,rings,bytes_to_int(col)})
free(v1)
free(v2)
end procedure

public procedure DrawPlane(sequence pos,sequence size,sequence  col)
atom mem=allocate(size_vector3)
        c_proc(xDrawPlane,{poke_vector3(mem,pos),V2toReg(size),bytes_to_int(col)})
free(mem)
end procedure
--CHECK ray is still missing
public procedure DrawRay(sequence ray,sequence col)
        c_proc(xDrawPlane,{ray,bytes_to_int(col)})
end procedure

public procedure DrawGrid(atom slices,atom space)
        c_proc(xDrawGrid,{slices,space})
end procedure

--Model 3D Loading functions
constant xLoadModel = define_c_func(ray,"+LoadModel",{C_HPTR,C_STRING},Model),
                                xLoadModelFromMesh = define_c_func(ray,"+LoadModelFromMesh",{C_HPTR,Mesh},Model),
                                xIsModelValid = define_c_func(ray,"+IsModelValid",{Model},C_BOOL),
                                xUnloadModel = define_c_proc(ray,"+UnloadModel",{Model}),
                                xGetModelBoundingBox = define_c_func(ray,"+GetModelBoundingBox",{C_HPTR,Model},BoundingBox)
                                
public function LoadModel(sequence fName)
atom pstr=allocate_string(fName)
atom mem=allocate(size_model)
atom ptr
sequence result=Tmodel
        ptr= c_func(xLoadModel,{mem,pstr})
result=peek_model(ptr)
free(pstr)
free(mem)
return result
end function

public function LoadModelFromMesh(sequence mesh)
atom pmesh=allocate(size_mesh)
atom mem=allocate(size_model)
atom ptr
sequence result=Tmodel
        ptr = c_func(xLoadModelFromMesh,{mem,poke_mesh(pmesh,mesh)})
result=peek_model(ptr)
free(pmesh)
free(mem)
return result
end function

public function IsModelValid(sequence model)
        return c_func(xIsModelValid,{model})
end function

public procedure UnloadModel(sequence model)
atom mem=allocate(size_model)
        c_proc(xUnloadModel,{poke_model(mem,model)})
free(mem)
end procedure

public function GetModelBoundingBox(sequence model)
atom modl=allocate(size_model)
atom mem=allocate(size_boundingbox)
sequence result
atom ptr
        ptr = c_func(xGetModelBoundingBox,{mem,poke_model(modl,model)})
result=peek_boundingbox(ptr)
free(mem)
free(modl)
return result
end function

--Model drawing functions
constant xDrawModel = define_c_proc(ray,"+DrawModel",{Model,Vector3,C_FLOAT,C_Color}),
                                xDrawModelEx = define_c_proc(ray,"+DrawModelEx",{Model,Vector3,Vector3,C_FLOAT,Vector3,C_Color}),
                                xDrawModelWires = define_c_proc(ray,"+DrawModelWires",{Model,Vector3,C_FLOAT,C_Color}),
                                xDrawModelWiresEx = define_c_proc(ray,"+DrawModelWiresEx",{Model,Vector3,Vector3,C_FLOAT,Vector3,C_Color}),
                            --  xDrawModelPoints = define_c_proc(ray,"+DrawModelPoints",{Model,Vector3,C_FLOAT,C_Color}),
                            --  xDrawModelPointsEx = define_c_proc(ray,"+DrawModelPointsEx",{Model,Vector3,Vector3,C_FLOAT,Vector3,C_Color}),
                                xDrawBoundingBox = define_c_proc(ray,"+DrawBoundingBox",{BoundingBox,C_Color}),
                                xDrawBillboard = define_c_proc(ray,"+DrawBillboard",{Camera,Texture2D,Vector3,C_FLOAT,C_Color}),
                                xDrawBillboardRec = define_c_proc(ray,"+DrawBillboardRec",{Camera,Texture2D,Rectangle,Vector3,Vector2,C_Color}),
                                xDrawBillboardPro = define_c_proc(ray,"+DrawBillboardPro",{Camera,Texture2D,Rectangle,Vector3,Vector3,Vector2,Vector2,C_FLOAT,C_Color})
                                
public procedure DrawModel(sequence model,sequence pos,atom scale,sequence tint)
atom modl=allocate(size_model)
atom vec1=allocate(size_vector3)
        c_proc(xDrawModel,{poke_model(modl,model),poke_vector3(vec1,pos),scale,bytes_to_int(tint)})
free(modl)
free(vec1)
end procedure

public procedure DrawModelEx(sequence model,sequence pos,sequence rotAxis,atom rotAng,sequence scale,sequence tint)
atom modl=allocate(size_model)
atom pos1=allocate(size_vector3)
atom rot=allocate(size_vector3)
atom sca=allocate(size_vector3)
        c_proc(xDrawModelEx,{poke_model(modl,model),poke_vector3(pos1,pos),poke_vector3(rot,rotAxis),rotAng,poke_vector3(sca,scale),bytes_to_int(tint)})
free(modl)
free(pos1)
free(rot)
free(sca)
end procedure

public procedure DrawModelWires(sequence model,sequence pos,atom scale,sequence tint)
        c_proc(xDrawModelWires,{model,pos,scale,tint})
end procedure

public procedure DrawModelWiresEx(sequence model,sequence pos,sequence rotAxis,atom rotAng,sequence scale,sequence tint)
        c_proc(xDrawModelWiresEx,{model,pos,rotAxis,rotAng,scale,tint})
end procedure

--CHECK removed 6.0
--public procedure DrawModelPoints(sequence model,sequence pos,atom scale,sequence tint)
--      c_proc(xDrawModelPoints,{model,pos,scale,tint})
--end procedure

--public procedure DrawModelPointsEx(sequence model,sequence pos,sequence rotAxis,atom rotAng,sequence scale,sequence tint)
--      c_proc(xDrawModelPointsEx,{model,pos,rotAxis,rotAng,scale,tint})
--end procedure

public procedure DrawBoundingBox(sequence box,sequence col)
atom box1=allocate(size_boundingbox)
        c_proc(xDrawBoundingBox,{poke_boundingbox(box1,box),bytes_to_int(col)})
free(box1)
end procedure
--{Camera,Texture2D,Vector3,C_FLOAT,C_Color}
public procedure DrawBillboard(sequence cam,sequence tex,sequence pos,atom scale,sequence tint)
atom camera=allocate(size_camera3d)
atom texture=allocate(size_texture)
atom vec3=allocate(size_vector3)
        c_proc(xDrawBillboard,{poke_camera3d(camera,cam),poke_texture(texture,tex),poke_vector3(vec3,pos),scale,bytes_to_int(tint)})
free(texture)
free(vec3)
free(camera)
end procedure

public procedure DrawBillboardRec(sequence cam,sequence tex,sequence source,sequence pos,sequence size,sequence tint)
        c_proc(xDrawBillboardRec,{cam,tex,source,pos,size,tint})
end procedure
--{Camera,Texture2D,Rectangle,Vector3,Vector3,Vector2,Vector2,C_FLOAT,C_Color})
public procedure DrawBillboardPro(sequence cam,sequence tex,sequence source,sequence pos,sequence up,sequence size,sequence origin,atom rot,sequence tint)
atom camera=allocate(size_camera3d)
atom texture=allocate(size_texture)
atom rect=allocate(size_rectangle)
atom vec3_pos=allocate(size_vector3)
atom vec3_up=allocate(size_vector3) 
        c_proc(xDrawBillboardPro,{poke_camera3d(camera,cam),poke_texture(texture,tex),poke_rectangle(rect,source),
        poke_vector3(vec3_pos,pos),poke_vector3(vec3_up,up),V2toReg(size),V2toReg(origin),rot,bytes_to_int(tint)})
free(rect)
free(texture)
free(vec3_pos)
free(vec3_up)
free(camera)
end procedure

--Mesh management functions
constant xUploadMesh = define_c_proc(ray,"+UploadMesh",{C_POINTER,C_BOOL}),
                                xUpdateMeshBuffer = define_c_proc(ray,"+UpdateMeshBuffer",{Mesh,C_INT,C_POINTER,C_INT,C_INT}),
                                xUnloadMesh = define_c_proc(ray,"+UnloadMesh",{Mesh}),
                                xDrawMesh = define_c_proc(ray,"+DrawMesh",{Mesh,Material,Matrix}),
                                xDrawMeshInstanced = define_c_proc(ray,"+DrawMeshInstanced",{Mesh,Material,C_POINTER,C_INT}),
                                xGetMeshBoundingBox = define_c_func(ray,"+GetMeshBoundingBox",{Mesh},BoundingBox),
                                xGenMeshTangents = define_c_proc(ray,"+GenMeshTangents",{C_POINTER}),
                                xExportMesh = define_c_func(ray,"+ExportMesh",{Mesh,C_STRING},C_BOOL),
                                xExportMeshAsCode = define_c_func(ray,"+ExportMeshAsCode",{Mesh,C_STRING},C_BOOL)
                                
public procedure UploadMesh(atom mesh,atom dynamic)
        c_proc(xUploadMesh,{mesh,dynamic})
end procedure

public procedure UpdateMeshBuffer(sequence mesh,atom index,atom data,atom size,atom offset)
        c_proc(xUpdateMeshBuffer,{mesh,index,data,size,offset})
end procedure

public procedure UnloadMesh(sequence mesh)
        c_proc(xUnloadMesh,{mesh})
end procedure

public procedure DrawMesh(sequence mesh,sequence material,sequence transform)
        c_proc(xDrawMesh,{mesh,material,transform})
end procedure

public procedure DrawMeshInstanced(sequence mesh,sequence material,atom transform,atom instanced)
        c_proc(xDrawMeshInstanced,{mesh,material,transform,instanced})  
end procedure

public function GetMeshBoundingBox(sequence mesh)
        return c_func(xGetMeshBoundingBox,{mesh})
end function

public procedure GenMeshTangents(atom mesh)
        c_proc(xGenMeshTangents,{mesh})
end procedure

public function ExportMesh(sequence mesh,sequence fName)
        return c_func(xExportMesh,{mesh,fName})
end function

public function ExportMeshAsCode(sequence mesh,sequence fName)
        return c_func(xExportMeshAsCode,{mesh,fName})
end function

--Mesh generation functions
constant xGenMeshPoly = define_c_func(ray,"+GenMeshPoly",{C_HPTR,C_INT,C_FLOAT},Mesh),
                                xGenMeshPlane = define_c_func(ray,"+GenMeshPlane",{C_HPTR,C_FLOAT,C_FLOAT,C_INT,C_INT},Mesh),
                                xGenMeshCube = define_c_func(ray,"+GenMeshCube",{C_HPTR,C_FLOAT,C_FLOAT,C_FLOAT},Mesh),
                                xGenMeshSphere = define_c_func(ray,"+GenMeshSphere",{C_HPTR,C_FLOAT,C_INT,C_INT},Mesh),
                                xGenMeshHemiSphere = define_c_func(ray,"+GenMeshHemiSphere",{C_HPTR,C_FLOAT,C_INT,C_INT},Mesh),
                                xGenMeshCylinder = define_c_func(ray,"+GenMeshCylinder",{C_HPTR,C_FLOAT,C_FLOAT,C_INT},Mesh),
                                xGenMeshCone = define_c_func(ray,"+GenMeshCone",{C_HPTR,C_FLOAT,C_FLOAT,C_INT},Mesh),
                                xGenMeshTorus = define_c_func(ray,"+GenMeshTorus",{C_HPTR,C_FLOAT,C_FLOAT,C_INT,C_INT},Mesh),
                                xGenMeshKnot = define_c_func(ray,"+GenMeshKnot",{C_HPTR,C_FLOAT,C_FLOAT,C_INT,C_INT},Mesh),
                                xGenMeshHeightmap = define_c_func(ray,"+GenMeshHeightmap",{C_HPTR,Image,Vector3},Mesh),
                                xGenMeshCubicmap = define_c_func(ray,"+GenMeshCubicmap",{C_HPTR,Image,Vector3},Mesh)
                                
public function GenMeshPoly(atom sides,atom rad)
atom mem=allocate(size_mesh)
atom ptr=c_func(xGenMeshPoly,{mem,sides,rad})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshPlane(atom width,atom len,atom x,atom z)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshPlane,{mem,width,len,x,z})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshCube(atom width,atom height,atom len)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshCube,{mem,width,height,len})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshSphere(atom rad,atom rings,atom slices)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshSphere,{mem,rad,rings,slices})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshHemiSphere(atom rad,atom rings,atom slices)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshHemiSphere,{mem,rad,rings,slices})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshCylinder(atom rad,atom height,atom slices)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshCylinder,{mem,rad,height,slices})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshCone(atom rad,atom height,atom slices)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshCone,{mem,rad,height,slices})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshTorus(atom rad,atom size,atom seg,atom sides)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshTorus,{mem,rad,size,seg,sides})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshKnot(atom rad,atom size,atom seg,atom sides)
atom mem=allocate(size_mesh)
atom ptr= c_func(xGenMeshKnot,{mem,rad,size,seg,sides})
sequence mesh=peek_mesh(ptr)
free(mem)
return mesh
end function

public function GenMeshHeightmap(sequence heightmap,sequence size)
atom pimg=allocate(size_image)
atom vec=allocate(size_vector3)
atom mem=allocate(size_mesh)
atom result
        result = c_func(xGenMeshHeightmap,{mem,poke_image(pimg,heightmap),poke_vector3(vec,size)})
sequence mesh=peek_mesh(result)
free(pimg)
free(mem)
free(vec)
return mesh
end function

public function GenMeshCubicmap(sequence cubicmap,sequence size)
atom pimg=allocate(size_image)
atom vec=allocate(size_vector3)
atom mem=allocate(size_mesh)
atom result
        result= c_func(xGenMeshCubicmap,{mem,poke_image(pimg,cubicmap),poke_vector3(vec,size)})
sequence mesh=peek_mesh(result)
free(pimg)
free(mem)
free(vec)
return mesh
end function

--Material loading functions
constant xLoadMaterials = define_c_func(ray,"+LoadMaterials",{C_STRING,C_POINTER},C_POINTER),
                                xLoadMaterialDefault = define_c_func(ray,"+LoadMaterialDefault",{},Material),
                                xIsMaterialValid = define_c_func(ray,"+IsMaterialValid",{Material},C_BOOL),
                                xUnloadMaterial = define_c_proc(ray,"+UnloadMaterial",{Material}),
                                xSetMaterialTexture = define_c_proc(ray,"+SetMaterialTexture",{C_POINTER,C_INT,Texture2D}),
                                xSetModelMeshMaterial = define_c_proc(ray,"+SetModelMeshMaterial",{C_POINTER,C_INT,C_INT})
                                
public function LoadMaterials(sequence fName,atom count)
        return c_func(xLoadMaterials,{fName,count})
end function

public function LoadMaterialDefault()
        return c_func(xLoadMaterialDefault,{})
end function

public function IsMaterialValid(sequence material)
        return c_func(xIsMaterialValid,{material})
end function

public procedure UnloadMaterial(sequence material)
        c_proc(xUnloadMaterial,{material})
end procedure

public procedure SetMaterialTexture(sequence mat,atom mapType,sequence tex)
        c_proc(xSetMaterialTexture,{mat,mapType,tex})
end procedure

public procedure SetModelMeshMaterial(atom model,atom meshID,atom matID)
        c_proc(xSetModelMeshMaterial,{model,meshID,matID})
end procedure

--Model animation loading functions
constant xLoadModelAnimations = define_c_func(ray,"+LoadModelAnimations",{C_STRING,C_POINTER},C_POINTER),
                                xUpdateModelAnimation = define_c_proc(ray,"+UpdateModelAnimation",{Model,ModelAnimation,C_INT}),
--CHECK not in lib???           xUpdateModelAnimationBones = define_c_proc(ray,"+UpdateModelAnimationBones",{Model,ModelAnimation,C_INT}),
--CHECK not in lib???           xUnloadModelAnimation = define_c_proc(ray,"+UnloadModelAnimation",{ModelAnimation}),
                                xUnloadModelAnimations = define_c_proc(ray,"+UnloadModelAnimations",{C_POINTER,C_INT}),
                                xIsModelAnimationValid = define_c_func(ray,"+IsModelAnimationValid",{Model,ModelAnimation},C_BOOL)
                                
public function LoadModelAnimations(sequence fName,atom count)
        return c_func(xLoadModelAnimations,{fName,count})
end function

public procedure UpdateModelAnimation(sequence model,sequence anim,atom frame)
        c_proc(xUpdateModelAnimation,{model,anim,frame})
end procedure

public procedure UpdateModelAnimationBones(sequence model,sequence anim,atom frame)
--CHECK see define  c_proc(xUpdateModelAnimationBones,{model,anim,frame})
end procedure

public procedure UnloadModelAnimation(sequence anim)
--CHECK see define      c_proc(xUnloadModelAnimation,{anim})
end procedure

public procedure UnloadModelAnimations(atom anim,atom count)
        c_proc(xUnloadModelAnimations,{anim,count})
end procedure

public function IsModelAnimationValid(sequence model,sequence anim)
        return c_func(xIsModelAnimationValid,{model,anim})
end function

--Collision detection functions
public constant xCheckCollisionSpheres = define_c_func(ray,"+CheckCollisionSpheres",{Vector3,C_FLOAT,Vector3,C_FLOAT},C_BOOL),
                                xCheckCollisionBoxes = define_c_func(ray,"+CheckCollisionBoxes",{BoundingBox,BoundingBox},C_BOOL),
                                xCheckCollisionBoxSphere = define_c_func(ray,"+CheckCollisionBoxSphere",{BoundingBox,Vector3,C_FLOAT},C_BOOL),
                                xGetRayCollisionSphere = define_c_func(ray,"+GetRayCollisionSphere",{Ray,Vector3,C_FLOAT},RayCollision),
                                xGetRayCollisionBox = define_c_func(ray,"+GetRayCollisionBox",{Ray,BoundingBox},RayCollision),
                                xGetRayCollisionMesh = define_c_func(ray,"+GetRayCollisionMesh",{Ray,Mesh,Matrix},RayCollision),
                                xGetRayCollisionTriangle = define_c_func(ray,"+GetRayCollisionTriangle",{Ray,Vector3,Vector3,Vector3},RayCollision),
                                xGetRayCollisionQuad = define_c_func(ray,"+GetRayCollisionQuad",{Ray,Vector3,Vector3,Vector3,Vector3},RayCollision)
                                
public function CheckCollisionSpheres(sequence center,atom rad,sequence center2,atom rad2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
        return and_bits(c_func(xCheckCollisionSpheres,{poke_vector3(vec1,center),rad,poke_vector3(vec2,center2),rad2}),1)
free(vec1)
free(vec2)
end function

public function CheckCollisionBoxes(sequence box,sequence box2)
atom box_1=allocate(size_boundingbox)
atom box_2=allocate(size_boundingbox)
        return and_bits(c_func(xCheckCollisionBoxes,{poke_boundingbox(box_1,box),poke_boundingbox(box_2,box2)}),1)
free(box_1)
free(box_2)
end function

public function CheckCollisionBoxSphere(sequence box,sequence center,atom rad)
atom box_1=allocate(size_boundingbox)
atom vec1=allocate(size_boundingbox)
        return c_func(xCheckCollisionBoxSphere,{poke_boundingbox(box_1,box),poke_vector3(vec1,center),rad})
free(box_1)
free(vec1)
end function

public function GetRayCollisionSphere(sequence ray,sequence center,atom rad)
        return c_func(xGetRayCollisionSphere,{ray,center,rad})
end function

public function GetRayCollisionBox(sequence ray,sequence box)
        return c_func(xGetRayCollisionBox,{ray,box})
end function

public function GetRayCollisionMesh(sequence ray,sequence mesh,sequence transform)
        return c_func(xGetRayCollisionMesh,{ray,mesh,transform})
end function

public function GetRayCollisionTriangle(sequence ray,sequence p1,sequence p2,sequence p3)
        return c_func(xGetRayCollisionTriangle,{ray,p1,p2,p3})
end function

public function GetRayCollisionQuad(sequence ray,sequence p1,sequence p2,sequence p3,sequence p4)
        return c_func(xGetRayCollisionQuad,{ray,p1,p2,p3,p4})
end function

--Audio functions
public constant xInitAudioDevice = define_c_proc(ray,"+InitAudioDevice",{}),
                                xCloseAudioDevice = define_c_proc(ray,"+CloseAudioDevice",{}),
                                xIsAudioDeviceReady = define_c_func(ray,"+IsAudioDeviceReady",{},C_BOOL),
                                xSetMasterVolume = define_c_proc(ray,"+SetMasterVolume",{C_FLOAT}),
                                xGetMasterVolume = define_c_func(ray,"+GetMasterVolume",{},C_FLOAT)
                                
public procedure InitAudioDevice()
        c_proc(xInitAudioDevice,{})
end procedure

public procedure CloseAudioDevice()
        c_proc(xCloseAudioDevice,{})
end procedure

public function IsAudioDeviceReady()
        return and_bits(c_func(xIsAudioDeviceReady,{}),1)
end function

public procedure SetMasterVolume(atom vol)
        c_proc(xSetMasterVolume,{vol})
end procedure

public function GetMasterVolume()
        return c_func(xGetMasterVolume,{})
end function

--Wave loading functions
public constant xLoadWave = define_c_func(ray,"+LoadWave",{C_STRING},Wave),
                                xLoadWaveFromMemory = define_c_func(ray,"+LoadWaveFromMemory",{C_STRING,C_POINTER,C_INT},Wave),
                                xIsWaveValid = define_c_func(ray,"+IsWaveValid",{Wave},C_BOOL),
                                xLoadSound = define_c_func(ray,"+LoadSound",{C_HPTR,C_STRING},Sound),
                                xLoadSoundFromWave = define_c_func(ray,"+LoadSoundFromWave",{Wave},Sound),
                                xLoadSoundAlias = define_c_func(ray,"+LoadSoundAlias",{C_HPTR,Sound},Sound),
                                xIsSoundValid = define_c_func(ray,"+IsSoundValid",{Sound},C_BOOL),
                                xUpdateSound = define_c_proc(ray,"+UpdateSound",{Sound,C_POINTER,C_INT}),
                                xUnloadWave = define_c_proc(ray,"+UnloadWave",{Wave}),
                                xUnloadSound = define_c_proc(ray,"+UnloadSound",{Sound}),
                                xUnloadSoundAlias = define_c_proc(ray,"+UnloadSoundAlias",{Sound}),
                                xExportWave = define_c_func(ray,"+ExportWave",{Wave,C_STRING},C_BOOL),
                                xExportWaveAsCode = define_c_func(ray,"+ExportWaveAsCode",{Wave,C_STRING},C_BOOL)
                                
public function LoadWave(sequence fName)
        return c_func(xLoadWave,{fName})
end function

public function LoadWaveFromMemory(sequence fileType,atom fileData,atom dataSize)
        return c_func(xLoadWaveFromMemory,{fileType,fileData,dataSize})
end function

public function IsWaveValid(sequence wave)
        return c_func(xIsWaveValid,{wave})
end function

public function LoadSound(sequence fName)
atom pstr=allocate_string(fName)
atom mem=allocate(32)
atom erg
sequence snd=Tsound
        erg= c_func(xLoadSound,{mem,pstr})
if not equal(erg,mem) then
    crash("Something ugly in : LoadSound")
end if
snd=peek_sound(erg) 
free(pstr)
free(mem)
return(snd)
end function

public function LoadSoundFromWave(sequence wave)
        return c_func(xLoadSoundFromWave,{wave})
end function

public function LoadSoundAlias(sequence source)
atom mem=allocate(size_sound)
atom src=allocate(size_sound)
atom erg
sequence snd=Tsound
        erg = c_func(xLoadSoundAlias,{mem,poke_sound(src,source)})
snd=peek_sound(erg) 
free(mem)
free(src)
return(snd)
end function

public function IsSoundValid(sequence sound)
        return c_func(xIsSoundValid,{sound})
end function

public procedure UpdateSound(sequence sound,atom data,atom count)
        c_proc(xUpdateSound,{sound,data,count})
end procedure

public procedure UnloadWave(sequence wave)
        c_proc(xUnloadWave,{wave})
end procedure

public procedure UnloadSound(sequence sound_)
atom mem=allocate(size_sound)
        c_proc(xUnloadSound,{poke_sound(mem,sound_)})
free(mem)
end procedure

public procedure UnloadSoundAlias(sequence alias)
atom mem=allocate(size_sound)
        c_proc(xUnloadSoundAlias,{poke_sound(mem,alias)})
free(mem)
end procedure

public function ExportWave(sequence wave,sequence fName)
        return c_func(xExportWave,{wave,fName})
end function

public function ExportWaveAsCode(sequence wave,sequence fName)
        return c_func(xExportWaveAsCode,{wave,fName})
end function

--Wave/sound management functions
public constant xPlaySound = define_c_proc(ray,"+PlaySound",{Sound}),
                                xStopSound = define_c_proc(ray,"+StopSound",{Sound}),
                                xPauseSound = define_c_proc(ray,"+PauseSound",{Sound}),
                                xResumeSound = define_c_proc(ray,"+ResumeSound",{Sound}),
                                xIsSoundPlaying = define_c_func(ray,"+IsSoundPlaying",{Sound},C_BOOL),
                                xSetSoundVolume = define_c_proc(ray,"+SetSoundVolume",{Sound,C_FLOAT}),
                                xSetSoundPitch = define_c_proc(ray,"+SetSoundPitch",{Sound,C_FLOAT}),
                                xSetSoundPan = define_c_proc(ray,"+SetSoundPan",{Sound,C_FLOAT}),
                                xWaveCopy = define_c_func(ray,"+WaveCopy",{Wave},Wave),
                                xWaveCrop = define_c_proc(ray,"+WaveCrop",{C_POINTER,C_INT,C_INT}),
                                xWaveFormat = define_c_proc(ray,"+WaveFormat",{C_POINTER,C_INT,C_INT,C_INT}),
                                xLoadWaveSamples = define_c_func(ray,"+LoadWaveSamples",{Wave},C_POINTER),
                                xUnloadWaveSamples = define_c_proc(ray,"+UnloadWaveSamples",{C_POINTER})
                                
public procedure PlaySound(sequence snd)
atom mem=allocate(size_sound)
        c_proc(xPlaySound,{poke_sound(mem,snd)})
free(mem)
end procedure

public procedure StopSound(sequence snd)
atom mem=allocate(size_sound)
        c_proc(xStopSound,{poke_sound(mem,snd)})
free(mem)
end procedure

public procedure PauseSound(sequence snd)
atom mem=allocate(size_sound)
        c_proc(xPauseSound,{poke_sound(mem,snd)})
free(mem)
end procedure

public procedure ResumeSound(sequence snd)
atom mem=allocate(size_sound)
        c_proc(xResumeSound,{poke_sound(mem,snd)})
free(mem)
end procedure

public function IsSoundPlaying(sequence snd)
atom mem=allocate(size_sound)
        return c_func(xIsSoundPlaying,{poke_sound(mem,snd)})
free(mem)
end function

public procedure SetSoundVolume(sequence snd,atom vol)
atom mem=allocate(size_sound)
        c_proc(xSetSoundVolume,{poke_sound(mem,snd),vol})
free(mem)
end procedure

public procedure SetSoundPitch(sequence snd,atom pit)
atom mem=allocate(size_sound)
        c_proc(xSetSoundPitch,{poke_sound(mem,snd),pit})
free(mem)
end procedure

public procedure SetSoundPan(sequence snd,atom pan)
atom mem=allocate(size_sound)
        c_proc(xSetSoundPan,{poke_sound(mem,snd),pan})
free(mem)
end procedure

public function WaveCopy(sequence wav)
        return c_func(xWaveCopy,{wav})
end function

public procedure WaveCrop(atom wav,atom initFrame,atom finalFrame)
        c_proc(xWaveCrop,{wav,initFrame,finalFrame})
end procedure

public procedure WaveFormat(atom wav,atom sampleRate,atom sampleSize,atom channels)
        c_proc(xWaveFormat,{wav,sampleRate,sampleSize,channels})
end procedure

public function LoadWaveSamples(sequence wav)
        return c_func(xLoadWaveSamples,{wav})
end function

public procedure UnloadWaveSamples(atom samp)
        c_proc(xUnloadWaveSamples,{samp})
end procedure

--Music management functions
public constant xLoadMusicStream = define_c_func(ray,"+LoadMusicStream",{C_HPTR,C_STRING},Music),
                                xLoadMusicStreamFromMemory = define_c_func(ray,"+LoadMusicStreamFromMemory",{C_STRING,C_POINTER,C_INT},Music),
                                xIsMusicValid = define_c_func(ray,"+IsMusicValid",{Music},C_BOOL),
                                xUnloadMusicStream = define_c_proc(ray,"+UnloadMusicStream",{Music}),
                                xPlayMusicStream = define_c_proc(ray,"+PlayMusicStream",{Music}),
                                xIsMusicStreamPlaying = define_c_func(ray,"+IsMusicStreamPlaying",{Music},C_BOOL),
                                xUpdateMusicStream = define_c_proc(ray,"+UpdateMusicStream",{Music}),
                                xStopMusicStream = define_c_proc(ray,"+StopMusicStream",{Music}),
                                xPauseMusicStream = define_c_proc(ray,"+PauseMusicStream",{Music}),
                                xResumeMusicStream = define_c_proc(ray,"+ResumeMusicStream",{Music}),
                                xSeekMusicStream = define_c_proc(ray,"+SeekMusicStream",{Music,C_FLOAT}),
                                xSetMusicVolume = define_c_proc(ray,"+SetMusicVolume",{Music,C_FLOAT}),
                                xSetMusicPitch = define_c_proc(ray,"+SetMusicPitch",{Music,C_FLOAT}),
                                xSetMusicPan = define_c_proc(ray,"+SetMusicPan",{Music,C_FLOAT}),
                                xGetMusicTimeLength = define_c_func(ray,"+GetMusicTimeLength",{Music},C_FLOAT),
                                xGetMusicTimePlayed = define_c_func(ray,"+GetMusicTimePlayed",{Music},C_FLOAT)
atom mus=allocate(size_music)                               
public function LoadMusicStream(sequence fName)
sequence music=Tmusic
atom id=allocate(8)
atom mus=get_addr_music({id,music})
atom pstr=allocate_string(fName)
atom ptr
        ptr= c_func(xLoadMusicStream,{mus,pstr})
music=peek_music(ptr)
free(pstr)
return append(music,id)
--?music
end function

public function LoadMusicStreamFromMemory(sequence fileType,atom data,atom size)
        return c_func(xLoadMusicStreamFromMemory,{fileType,data,size})
end function

public function IsMusicValid(sequence music)
atom mus=get_addr_music({music[6],music})
        return and_bits(c_func(xIsMusicValid,{poke_music(mus,music)}),1)
end function

public procedure UnloadMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xUnloadMusicStream,{poke_music(mus,music)})
free(mus)
free(music[6])
end procedure

public procedure PlayMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xPlayMusicStream,{poke_music(mus,music)})
end procedure

public function IsMusicStreamPlaying(sequence music)
atom mus=get_addr_music({music[6],music})
        return c_func(xIsMusicStreamPlaying,{poke_music(mus,music)})
end function

public procedure UpdateMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xUpdateMusicStream,{poke_music(mus,music)})

end procedure

public procedure StopMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xStopMusicStream,{poke_music(mus,music)})

end procedure

public procedure PauseMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xPauseMusicStream,{poke_music(mus,music)})
end procedure

public procedure ResumeMusicStream(sequence music)
atom mus=get_addr_music({music[6],music})
        c_proc(xResumeMusicStream,{poke_music(mus,music)})
end procedure

public procedure SeekMusicStream(sequence music,atom pos)
atom mus=get_addr_music({music[6],music})
        c_proc(xSeekMusicStream,{poke_music(mus,music),pos})
end procedure

public procedure SetMusicVolume(sequence music,atom vol)
atom mus=get_addr_music({music[6],music})
        c_proc(xSetMusicVolume,{poke_music(mus,music),vol})
end procedure

public procedure SetMusicPitch(sequence music,atom pit)
atom mus=get_addr_music({music[6],music})
        c_proc(xSetMusicPitch,{poke_music(mus,music),pit})
end procedure

public procedure SetMusicPan(sequence music,atom pan)
atom mus=get_addr_music({music[6],music})
        c_proc(xSetMusicPan,{poke_music(mus,music),pan})
end procedure

public function GetMusicTimeLength(sequence music)
atom mus=get_addr_music({music[6],music})
        return c_func(xGetMusicTimeLength,{poke_music(mus,music)})
end function

public function GetMusicTimePlayed(sequence music)
atom mus=get_addr_music({music[6],music})
        return c_func(xGetMusicTimePlayed,{poke_music(mus,music)})
end function

--Audiostream functions
public constant xLoadAudioStream = define_c_func(ray,"+LoadAudioStream",{C_UINT,C_UINT,C_UINT},AudioStream),
                                xIsAudioStreamValid = define_c_func(ray,"+IsAudioStreamValid",{AudioStream},C_BOOL),
                                xUnloadAudioStream = define_c_proc(ray,"+UnloadAudioStream",{AudioStream}),
                                xUpdateAudioStream = define_c_proc(ray,"+UpdateAudioStream",{AudioStream,C_POINTER,C_INT}),
                                xIsAudioStreamProcessed = define_c_func(ray,"+IsAudioStreamProcessed",{AudioStream},C_BOOL),
                                xPlayAudioStream = define_c_proc(ray,"+PlayAudioStream",{AudioStream}),
                                xPauseAudioStream = define_c_proc(ray,"+PauseAudioStream",{AudioStream}),
                                xResumeAudioStream = define_c_proc(ray,"+ResumeAudioStream",{AudioStream}),
                                xIsAudioStreamPlaying = define_c_proc(ray,"+IsAudioStreamPlaying",{AudioStream}),
                                xStopAudioStream = define_c_proc(ray,"+StopAudioStream",{AudioStream}),
                                xSetAudioStreamVolume = define_c_proc(ray,"+SetAudioStreamVolume",{AudioStream,C_FLOAT}),
                                xSetAudioStreamPitch = define_c_proc(ray,"+SetAudioStreamPitch",{AudioStream,C_FLOAT}),
                                xSetAudioStreamPan = define_c_proc(ray,"+SetAudioStreamPan",{AudioStream,C_FLOAT}),
                                xSetAudioStreamBufferSizeDefault = define_c_proc(ray,"+SetAudioStreamBufferSizeDefault",{C_INT}),
                                xSetAudioStreamCallback = define_c_proc(ray,"+SetAudioStreamCallback",{AudioStream,C_POINTER})
                                
public function LoadAudioStream(atom sampleRate,atom sampleSize,atom channels)
        return c_func(xLoadAudioStream,{sampleRate,sampleSize,channels})
end function

public function IsAudioStreamValid(sequence stream)
        return c_func(xIsAudioStreamValid,{stream})
end function

public procedure UnloadAudioStream(sequence stream)
        c_proc(xUnloadAudioStream,{stream})
end procedure

public procedure UpdateAudioStream(sequence stream,atom data,atom count)
        c_proc(xUpdateAudioStream,{stream,data,count})
end procedure

public function IsAudioStreamProcessed(sequence stream)
        return c_func(xIsAudioStreamProcessed,{stream})
end function

public procedure PlayAudioStream(sequence stream)
        c_proc(xPlayAudioStream,{stream})
end procedure

public procedure PauseAudioStream(sequence stream)
        c_proc(xPauseAudioStream,{stream})
end procedure

public procedure ResumeAudioStream(sequence stream)
        c_proc(xResumeAudioStream,{stream})
end procedure

public function IsAudioStreamPlaying(sequence stream)
        return c_func(xIsAudioStreamPlaying,{stream})
end function

public procedure StopAudioStream(sequence stream)
        c_proc(xStopAudioStream,{stream})
end procedure

public procedure SetAudioStreamVolume(sequence stream,atom vol)
        c_proc(xSetAudioStreamVolume,{stream,vol})
end procedure

public procedure SetAudioStreamPitch(sequence stream,atom pit)
        c_proc(xSetAudioStreamPitch,{stream,pit})
end procedure

public procedure SetAudioStreamPan(sequence stream,atom pan)
        c_proc(xSetAudioStreamPan,{stream,pan})
end procedure

public procedure SetAudioStreamBufferSizeDefault(atom size)
        c_proc(xSetAudioStreamBufferSizeDefault,{size})
end procedure

public procedure SetAudioStreamCallback(sequence stream,object cb)
        c_proc(xSetAudioStreamCallback,{stream,cb})
end procedure

public constant xAttachAudioStreamProcessor = define_c_proc(ray,"+AttachAudioStreamProcessor",{AudioStream,C_POINTER}),
                                xDetachAudioStreamProcessor = define_c_proc(ray,"+DetachAudioStreamProcessor",{AudioStream,C_POINTER})
                                
public procedure AttachAudioStreamProcessor(sequence stream,object processor)
        c_proc(xAttachAudioStreamProcessor,{stream,processor})
end procedure

public procedure DetachAudioStreamProcessor(sequence stream,object processor)
        c_proc(xDetachAudioStreamProcessor,{stream,processor})
end procedure

public constant xAttachAudioMixedProcessor = define_c_proc(ray,"+AttachAudioMixedProcessor",{C_POINTER}),
                                xDetachAudioMixedProcessor = define_c_proc(ray,"+DetachAudioMixedProcessor",{C_POINTER})
                                
public procedure AttachAudioMixedProcessor(object processor)
        c_proc(xAttachAudioMixedProcessor,{processor})
end procedure

public procedure DetachAudioMixedProcessor(object processor)
        c_proc(xDetachAudioMixedProcessor,{processor})
end procedure

--#########################################################################################################
--#                                                                                                     #
--# raymath functions   appended as needed                                                              #
--#                                                                                                     #
--#########################################################################################################
global function Vector2Zero()
    return {0,0}
end function


-- Calculate two vectors dot product
global function Vector2DotProduct(sequence v,sequence v2)
        return (v[1]*v2[1])+(v[2]*v2[2])
end function

constant xVector2LengthSqr = define_c_func(ray,"+Vector2LengthSqr",{Vector2},C_FLOAT)

global function Vector2LengthSqr(sequence v)
        return c_func(xVector2LengthSqr,{V2toReg(v)})
end function


-- Subtract two vectors (v1 - v2)
global function Vector2Subtract(sequence v,sequence v2)
        return {v[1]-v2[1],v[2]-v2[2]} 
end function


-- Normalize provided vector
global function Vector2Normalize(sequence v)
sequence result={0,0}
atom _length = sqrt((v[1]*v[1]) + (v[2]*v[2]))
atom ilength
if (_length>0)
then
    ilength=1/_length
    result[1] = v[1]*ilength
    result[2] = v[2]*ilength
end if
return result
end function

constant xVector2Angle = define_c_func(ray,"+Vector2Angle",{Vector2,Vector2},C_FLOAT)

global function Vector2Angle(sequence v,sequence v2)
        return c_func(xVector2Angle,{V2toReg(v),V2toReg(v2)})
end function

constant xVector2Add = define_c_func(ray,"+Vector2Add",{Vector2,Vector2},Vector2)

global function Vector2Add(sequence v1,sequence v2) 
        return RegtoV2(c_func(xVector2Add,{V2toReg(v1),V2toReg(v2)}))
end function
--global function Vector2Add(sequence v1,sequence v2) 
--integer x=1,y=2
--  return { v1[x] + v2[x], v1[y] + v2[y] }
--end function

constant xVector2Distance = define_c_func(ray,"+Vector2Distance",{Vector2,Vector2},C_FLOAT)

global function Vector2Distance(sequence v1,sequence v2)
--float result = sqrtf((v1.x - v2.x)*(v1.x - v2.x) + (v1.y - v2.y)*(v1.y - v2.y));
    return sqrt((v1[1]-v2[1])*(v1[1]-v2[1])+(v1[2]-v2[2])*(v1[2]-v2[2]))
--       return c_func(xVector2Distance,{V2toReg(v),V2toReg(v2)})
end function

constant xVector2Scale = define_c_func(ray,"+Vector2Scale",{Vector2,C_FLOAT},Vector2)

global function Vector2Scale(sequence v,atom scale)
        return RegtoV2(c_func(xVector2Scale,{V2toReg(v),scale}))
end function
--global function Vector2Scale(sequence v,atom scale)
--integer x=1,y=2
--  return { v[x]*scale, v[y]*scale }
--end function

constant xVector2Length = define_c_func(ray,"+Vector2Length",{Vector2},C_FLOAT)

global function Vector2Length(sequence v)
        return c_func(xVector2Length,{V2toReg(v)})
end function

constant xVector3Length = define_c_func(ray,"+Vector3Length",{Vector3},C_FLOAT)

global function Vector3Length(sequence v)
atom vec1=allocate(size_vector3)
        return c_func(xVector3Length,{poke_vector3(vec1,v)})
free(vec1)
end function

constant xVector3Distance = define_c_func(ray,"+Vector3Distance",{Vector3,Vector3},C_FLOAT)

global function Vector3Distance(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
        return c_func(xVector3Distance,{poke_vector3(vec1,v),poke_vector3(vec2,v2)})
free(vec1)
free(vec2)
end function

constant xVector3Scale = define_c_func(ray,"+Vector3Scale",{C_HPTR,Vector3,C_FLOAT},Vector3)

global function Vector3Scale(sequence v,atom scalar)
atom vec1=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Scale,{mem,poke_vector3(vec1,v),scalar})
result=peek_vector3(ptr)
free(vec1)
free(mem)
return result
end function

constant xVector3Angle = define_c_func(ray,"+Vector3Angle",{Vector3,Vector3},C_FLOAT)

global function Vector3Angle(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom result
        result = c_func(xVector3Angle,{poke_vector3(vec1,v),poke_vector3(vec2,v2)})

free(vec1)
free(vec2)
return result
end function



constant xVector3Normalize = define_c_func(ray,"+Vector3Normalize",{C_HPTR,Vector3},Vector3)

global function Vector3Normalize(sequence v)
atom vec1=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Normalize,{mem,poke_vector3(vec1,v)})
result=peek_vector3(ptr)
free(vec1)
free(mem)
return result
end function

constant xVector3Negate = define_c_func(ray,"+Vector3Negate",{C_HPTR,Vector3},Vector3)

global function Vector3Negate(sequence v)
atom vec1=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Negate,{mem,poke_vector3(vec1,v)})
result=peek_vector3(ptr)
free(vec1)
free(mem)
return result
end function


constant xVector3DotProduct = define_c_func(ray,"+Vector3DotProduct",{Vector3,Vector3},C_FLOAT)

global function Vector3DotProduct(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
        return c_func(xVector3DotProduct,{poke_vector3(vec1,v),poke_vector3(vec2,v2)})
free(vec1)
free(vec2)
end function

constant xVector3RotateByAxisAngle = define_c_func(ray,"+Vector3RotateByAxisAngle",{C_HPTR,Vector3,Vector3,C_FLOAT},Vector3)

global function Vector3RotateByAxisAngle(sequence v,sequence v1,atom ang)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr= c_func(xVector3RotateByAxisAngle,{mem,poke_vector3(vec1,v),poke_vector3(vec2,v1),ang})
result=peek_vector3(ptr)
free(vec1)
free(vec2)
free(mem)
return result
end function

constant xVector3Lerp = define_c_func(ray,"+Vector3Lerp",{C_HPTR,Vector3,Vector3,C_FLOAT},Vector3)

global function Vector3Lerp(sequence v,sequence v2,atom amt)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Lerp,{mem,poke_vector3(vec1,v),poke_vector3(vec2,v2),amt})
result=peek_vector3(ptr)
free(vec1)
free(vec2)
free(mem)
return result
end function

constant xVector3Add = define_c_func(ray,"+Vector3Add",{C_HPTR,Vector3,Vector3},Vector3)

global function Vector3Add(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Add,{mem,poke_vector3(vec1,v),poke_vector3(vec2,v2)})
result=peek_vector3(ptr)
free(vec1)
free(vec2)
free(mem)
return result
end function

constant xVector3CrossProduct = define_c_func(ray,"+Vector3CrossProduct",{C_HPTR,Vector3,Vector3},Vector3)

global function Vector3CrossProduct(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3CrossProduct,{mem,poke_vector3(vec1,v),poke_vector3(vec2,v2)})
result=peek_vector3(ptr)
free(vec1)
free(vec2)
free(mem)
return result
end function

constant xVector3Subtract = define_c_func(ray,"+Vector3Subtract",{C_HPTR,Vector3,Vector3},Vector3)

global function Vector3Subtract(sequence v,sequence v2)
atom vec1=allocate(size_vector3)
atom vec2=allocate(size_vector3)
atom mem=allocate(size_vector3)
sequence result={0,0,0}
atom ptr
        ptr = c_func(xVector3Subtract,{mem,poke_vector3(vec1,v),poke_vector3(vec2,v2)})
result=peek_vector3(ptr)
free(vec1)
free(vec2)
free(mem)
return result
end function

constant xMatrixRotateXYZ = define_c_func(ray,"+MatrixRotateXYZ",{C_HPTR,Vector3},Matrix)

global function MatrixRotateXYZ(sequence ang)
atom mat = allocate(size_matrix)
atom vec=allocate(size_vector3)
atom ptr
sequence matrix
        ptr = c_func(xMatrixRotateXYZ,{mat,poke_vector3(vec,ang)})
matrix=peek_matrix(ptr)
free(mat)
free(vec)
return matrix
end function

constant xMatrixRotateZYX = define_c_func(ray,"+MatrixRotateZYX",{C_HPTR,Vector3},Matrix)

global function MatrixRotateZYX(sequence ang)
atom mat = allocate(size_matrix)
atom vec=allocate(size_vector3)
atom ptr
sequence matrix
        ptr = c_func(xMatrixRotateZYX,{mat,poke_vector3(vec,ang)})
matrix=peek_matrix(ptr)
free(mat)
free(vec)
return matrix
end function


constant xClamp = define_c_func(ray,"+Clamp",{C_FLOAT,C_FLOAT,C_FLOAT},C_FLOAT)

global function Clamp(atom val,atom _min,atom _max)
atom result
if val<_min 
then
    result=_min
else
    result=val  
end if
if result > _max then result =_max end if
return result
--      return c_func(xClamp,{val,min,max})
end function

export constant xLerp = define_c_func(ray,"+Lerp",{C_FLOAT,C_FLOAT,C_FLOAT},C_FLOAT)

public function Lerp(atom start,atom xend,atom amount)
        return c_func(xLerp,{start,xend,amount})
end function

export constant xNormalize = define_c_func(ray,"+Normalize",{C_FLOAT,C_FLOAT,C_FLOAT},C_FLOAT)

public function Normalize(atom val,atom start,atom xend)
        return c_func(xNormalize,{val,start,xend})
end function

constant xRemap = define_c_func(ray,"+Remap",{C_FLOAT,C_FLOAT,C_FLOAT,C_FLOAT,C_FLOAT},C_FLOAT)

global function Remap(atom val,atom iS,atom iE,atom oS,atom oE)
        return c_func(xRemap,{val,iS,iE,oS,oE})
end function

constant xWrap = define_c_func(ray,"+Wrap",{C_FLOAT,C_FLOAT,C_FLOAT},C_FLOAT)

global function Wrap(atom val,atom min,atom max)
        return c_func(xWrap,{val,min,max})
end function

--#########################################################################################################
--#                                                                                                     #
--# raygl functions appended as needed                                                                  #
--#                                                                                                     #
--#########################################################################################################


 constant xrlMatrixMode = define_c_proc(ray,"+rlMatrixMode",{C_INT}),
                                xrlPushMatrix = define_c_proc(ray,"+rlPushMatrix",{}),
                                xrlPopMatrix = define_c_proc(ray,"+rlPopMatrix",{}),
                                xrlLoadIdentity = define_c_proc(ray,"+rlLoadIdentity",{}),
                                xrlTranslatef = define_c_proc(ray,"+rlTranslatef",{C_FLOAT,C_FLOAT,C_FLOAT}),
                                xrlRotatef = define_c_proc(ray,"+rlRotatef",{C_FLOAT,C_FLOAT,C_FLOAT,C_FLOAT}),
                                xrlScalef = define_c_proc(ray,"+rlScalef",{C_FLOAT,C_FLOAT,C_FLOAT}),
                                --xrlMultMatrixf = define_c_proc(ray,"+rlMultiMatrixf",{C_POINTER}),
                                xrlFrustum = define_c_proc(ray,"+rlFrustum",{C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE}),
                                xrlOrtho = define_c_proc(ray,"+rlOrtho",{C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE,C_DOUBLE}),
                                xrlViewport = define_c_proc(ray,"+rlViewport",{C_INT,C_INT,C_INT,C_INT})
                                
global procedure rlMatrixMode(atom mode)
        c_proc(xrlMatrixMode,{mode})
end procedure

global procedure rlPushMatrix()
        c_proc(xrlPushMatrix,{})
end procedure

global procedure rlPopMatrix()
        c_proc(xrlPopMatrix,{})
end procedure

global procedure rlLoadIdentity()
        c_proc(xrlLoadIdentity,{})
end procedure

global procedure rlTranslatef(atom x,atom y,atom z)
        c_proc(xrlTranslatef,{x,y,z})
end procedure

global procedure rlRotatef(atom angle,atom x,atom y,atom z)
        c_proc(xrlRotatef,{angle,x,y,z})
end procedure

global procedure rlScalef(atom x,atom y,atom z)
        c_proc(xrlScalef,{x,y,z})
end procedure
--CHECK can not link
--global procedure rlMultMatrixf(atom mat)
--      c_proc(xrlMultMatrixf,{mat})
--end procedure

global procedure rlFrustum(atom left,atom right,atom bottom,atom top,atom znear,atom zfar)
        c_proc(xrlFrustum,{left,right,bottom,top,znear,zfar})
end procedure

public procedure rlOrtho(atom left,atom right,atom bottom,atom top,atom znear,atom zfar)
        c_proc(xrlOrtho,{left,right,bottom,top,znear,zfar})
end procedure

global procedure rlViewport(atom x,atom y,atom w,atom h)
        c_proc(xrlViewport,{x,y,w,h})
end procedure


--#########################################################################################################
--#                                                                                                     #
--# raygui functions appended as needed                                                                 #
--#                                                                                                     #
--#########################################################################################################
global enum DEFAULT = 0,
        LABEL,
        BUTTON,
        TOGGLE,
        SLIDER,
        PROGRESSBAR,
        CHECKBOX,
        COMBOBOX,
        DROPDOWNBOX,
        TEXTBOX,
        VALUEBOX,
        SPINNER,
        LISTVIEW,
        COLORPICKER,
        SCROLLBAR,
        STATUSBAR


global enum BORDER_COLOR_NORMAL = 0,
        BASE_COLOR_NORMAL,
        TEXT_COLOR_NORMAL,
        BORDER_COLOR_FOCUSED,
        BASE_COLOR_FOCUSED,
        TEXT_COLOR_FOCUSED,
        BORDER_COLOR_PRESSED,
        BASE_COLOR_PRESSED,
        TEXT_COLOR_PRESSED,
        BORDER_COLOR_DISABLED,
        BASE_COLOR_DISABLED,
        TEXT_COLOR_DISABLED,
        BORDER_WIDTH,
        TEXT_PADDING,
        TEXT_ALIGNMENT

global enum TEXT_SIZE = 16,
        TEXT_SPACING,
        LINE_COLOR,
        BACKGROUND_COLOR,
        TEXT_LINE_SPACING,
        TEXT_ALIGNMENT_VERTICAL,
        TEXT_WRAP_MODE

global enum STATE_NORMAL = 0,
            STATE_FOCUSED,
            STATE_PRESSED,
            STATE_DISABLED

global enum TEXT_READONLY = 16



constant xGuiEnable = define_c_proc(ray,"+GuiEnable",{}),
         xGuiDisable = define_c_proc(ray,"+GuiDisable",{}),
         xGuiSetIconScale = define_c_proc(ray,"+GuiSetIconScale",{C_INT}),
         xGuiSetState = define_c_proc(ray,"+GuiSetState",{C_INT})
        
global procedure GuiSetState(atom state)
        c_proc(xGuiSetState,{state})
end procedure

global procedure GuiSetIconScale(atom scale)
        c_proc(xGuiSetIconScale,{scale})
end procedure

global procedure GuiEnable()
        c_proc(xGuiEnable,{})
end procedure

global procedure GuiDisable()
        c_proc(xGuiDisable,{})
end procedure

public constant xGuiSetStyle = define_c_proc(ray,"+GuiSetStyle",{C_INT,C_INT,C_INT}),
                                xGuiGetStyle = define_c_func(ray,"+GuiGetStyle",{C_INT,C_INT},C_INT)
                                
public procedure GuiSetStyle(atom control,atom property,atom val)
        c_proc(xGuiSetStyle,{control,property,val})
end procedure

public function GuiGetStyle(atom control,atom property)
        return c_func(xGuiGetStyle,{control,property})
end function

constant xGuiLabel = define_c_func(ray,"+GuiLabel",{Rectangle,C_STRING},C_INT),
                                xGuiButton = define_c_func(ray,"+GuiButton",{Rectangle,C_STRING},C_INT),
                                xGuiLabelButton = define_c_func(ray,"+GuiLabelButton",{Rectangle,C_STRING},C_INT),
                                xGuiToggle = define_c_func(ray,"+GuiToggle",{Rectangle,C_STRING,C_POINTER},C_INT),
                                xGuiToggleGroup = define_c_func(ray,"+GuiToggleGroup",{Rectangle,C_STRING,C_POINTER},C_INT),
                                xGuiToggleSlider = define_c_func(ray,"+GuiToggleSlider",{Rectangle,C_STRING,C_POINTER},C_INT),
                                xGuiCheckBox = define_c_func(ray,"+GuiCheckBox",{Rectangle,C_STRING,C_POINTER},C_INT),
                                xGuiComboBox = define_c_func(ray,"+GuiComboBox",{Rectangle,C_STRING,C_POINTER},C_INT)
public function GuiLabel(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
        return c_func(xGuiLabel,{poke_rectangle(memrect,bounds),pstr})
free(pstr)
free(memrect)       
end function

public function GuiButton(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiButton,{poke_rectangle(memrect,bounds),pstr})
free(pstr)
free(memrect)
return and_bits(result,1)
end function

public function GuiLabelButton(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiLabelButton,{poke_rectangle(memrect,bounds),pstr})
free(pstr)
free(memrect)return and_bits(result,1)
end function

public function GuiToggle(sequence bounds,sequence text,sequence  idval)
atom memrect=allocate(size_rectangle)
atom pstr1=allocate_string(text)
atom result,val,addr
addr=get_addr_bool(idval)
        result = c_func(xGuiToggle,{poke_rectangle(memrect,bounds),pstr1,addr})
val=peek4u(addr)
free(memrect)
free(pstr1)
    return and_bits(val,1)
end function

public function GuiToggleGroup(sequence bounds,sequence text,sequence  idval)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom addr,result,val
addr=get_addr_int(idval)
        result = c_func(xGuiToggleGroup,{poke_rectangle(memrect,bounds),pstr,addr})
val=peek4s(addr)
free(memrect)
free(pstr)

return val
end function

public function GuiToggleSlider(sequence bounds,sequence text,atom active)
        return c_func(xGuiToggleSlider,{bounds,text,active})
end function

public function GuiCheckBox(sequence bounds,sequence text,sequence idval)
atom memrect=allocate(size_rectangle)
atom pstr1=allocate_string(text)
atom result,val,addr
addr=get_addr_bool(idval)

        result = c_func(xGuiCheckBox,{poke_rectangle(memrect,bounds),pstr1,addr})
val=peek4s(addr)
free(memrect)
free(pstr1)
    return and_bits(val,1)
end function

public function GuiComboBox(sequence bounds,sequence text,atom active)
        return c_func(xGuiComboBox,{bounds,text,active})
end function
                
global constant xGuiDropdownBox = define_c_func(ray,"+GuiDropdownBox",{Rectangle,C_STRING,C_POINTER,C_BOOL},C_INT),
                                xGuiSpinner = define_c_func(ray,"+GuiSpinner",{Rectangle,C_STRING,C_POINTER,C_INT,C_INT,C_BOOL},C_INT),
                                xGuiValueBox = define_c_func(ray,"+GuiValueBox",{Rectangle,C_STRING,C_POINTER,C_INT,C_INT,C_BOOL},C_INT),
                                xGuiTextBox = define_c_func(ray,"+GuiTextBox",{Rectangle,C_STRING,C_INT,C_BOOL},C_INT)
                                
public function GuiDropdownBox(sequence bounds,sequence text,atom active,atom editMode)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiDropdownBox,{poke_rectangle(memrect,bounds),pstr,active,editMode})
free(pstr)      
free(memrect)
return result
end function

public function GuiSpinner(sequence bounds,sequence text,atom val,atom min,atom max,atom editMode)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiSpinner,{poke_rectangle(memrect,bounds),pstr,val,min,max,editMode})
free(pstr)      
free(memrect)
return result
end function

public function GuiValueBox(sequence bounds,sequence text,atom val,atom min,atom max,atom editMode)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiValueBox,{poke_rectangle(memrect,bounds),pstr,val,min,max,editMode})
free(pstr)      
free(memrect)
return result
end function

public function GuiTextBox(sequence bounds,sequence idval,atom size,atom editMode)
atom memrect=allocate(size_rectangle)
atom addr=get_addr_string(idval)
atom result
        result = c_func(xGuiTextBox,{poke_rectangle(memrect,bounds),addr,size,editMode})
        --?result   
free(memrect)
return peek_string(addr)
end function


constant xGuiWindowBox = define_c_func(ray,"+GuiWindowBox",{Rectangle,C_STRING},C_INT),
                                xGuiGroupBox = define_c_func(ray,"+GuiGroupBox",{Rectangle,C_STRING},C_INT),
                                xGuiLine = define_c_func(ray,"+GuiLine",{Rectangle,C_STRING},C_INT),
                                xGuiPanel = define_c_func(ray,"+GuiPanel",{Rectangle,C_STRING},C_INT),
                                xGuiTabBar = define_c_func(ray,"+GuiTabBar",{Rectangle,C_STRING,C_INT,C_POINTER},C_INT),
                                xGuiScrollPanel = define_c_func(ray,"+GuiScrollPanel",{Rectangle,C_STRING,Rectangle,C_POINTER,C_POINTER},C_INT)
                                
global function GuiWindowBox(sequence bounds,sequence title)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(title)
atom result
        result = c_func(xGuiWindowBox,{poke_rectangle(memrect,bounds),pstr})
free(pstr)      
free(memrect)
return result
end function

global function GuiGroupBox(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result= c_func(xGuiGroupBox,{poke_rectangle(memrect,bounds),pstr})
free(pstr)      
free(memrect)
return result
end function

public function GuiLine(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiLine,{poke_rectangle(memrect,bounds),pstr})
free(pstr)      
free(memrect)
return result
end function

public function GuiPanel(sequence bounds,sequence text)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiPanel,{poke_rectangle(memrect,bounds),pstr})
free(pstr)      
free(memrect)
return result
end function

public function GuiTabBar(sequence bounds,sequence text,atom count,atom active)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result = c_func(xGuiTabBar,{poke_rectangle(memrect,bounds),pstr,count,active})
free(pstr)      
free(memrect)
return result
end function

public function GuiScrollPanel(sequence bounds,sequence text,sequence content,atom scroll_,atom view)
atom memrect=allocate(size_rectangle)
atom pstr=allocate_string(text)
atom result
        result= c_func(xGuiScrollPanel,{poke_rectangle(memrect,bounds),pstr,content,scroll_,view})
free(pstr)      
free(memrect)
return result
end function
                
-- Slider Bar control extended, returns selected value
constant xGuiSliderBar = define_c_func(ray,"+GuiSliderBar",{Rectangle,C_STRING,C_STRING,C_POINTER,C_FLOAT,C_FLOAT},C_INT)
global function _GuiSliderBar(sequence bounds,sequence lefttext,sequence righttext,atom val,atom min_,atom max_)
atom memrect=allocate(size_rectangle)
atom pstr1=allocate_string(lefttext)
atom pstr2=allocate_string(righttext)
atom result
        result= c_func(xGuiSliderBar,{poke_rectangle(memrect,bounds),pstr1,pstr2,val,min_,max_})
free(memrect)
free(pstr1)
free(pstr2)
    return result
end function

-- Slider Bar control extended, Slider Bar control alternate version you have to provide a unique id and value in this form {id,value}
-- does not provide the has_changed information in the returned result but the value


global function GuiSliderBar(sequence bounds,sequence lefttext,sequence righttext,sequence idval,atom min_,atom max_)
atom memrect=allocate(size_rectangle)
atom pstr1=allocate_string(lefttext)
atom pstr2=allocate_string(righttext)
atom result,val,addr
addr=get_addr_float(idval)

        result= c_func(xGuiSliderBar,{poke_rectangle(memrect,bounds),pstr1,pstr2,addr,min_,max_})
val=float32_to_atom(peek({addr,4}))
free(memrect)
free(pstr1)
free(pstr2)
    return val
end function



