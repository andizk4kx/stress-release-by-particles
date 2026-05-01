without warning
--adapted to Phix/Euphoria 2026 Andreas Wagner
include "..\\..\\raylib64.e"
--/**/constant PI_=PI

--/*
--include raylib.e
--include raymath.e
include std/convert.e
constant true = 1
constant false = 0
include std/math.e
constant PI_= 3.14159265358979323846
--*/
constant MAX_PARTICLES = 10000
constant MAX_MUSIC_VOLUME = 5.0

enum  STATE_MENU, STATE_ABOUT, STATE_RELAX 
enum  COLOR_BLUE, COLOR_GREEN, COLOR_RED 
enum  EFFECT_ATTRACT, EFFECT_REPEL

sequence Particle={{0,0},{0,0},{0,0,0,0}}
enum _position=1,velocity=2,color=3
enum x=1,y=2
--typedef struct Particle {
--  Vector2 position;
--  Vector2 velocity;
--  Color color;
--} Particle;

-- Globals
integer screenWidth = 800
integer screenHeight = 448
sequence particles = {}
integer currentEffect = EFFECT_ATTRACT
integer currentState = STATE_MENU
integer selectedColor = COLOR_BLUE

integer justStarted = false
integer musicMuted = false
integer needRestart = false
sequence previousEffectPosition = {0,0}
sequence backgroundMusic = {}

constant inv10000 = 0.0001

integer maxParticles = MAX_PARTICLES
sequence maxParticlesOptions = {10000, 15000, 20000,25000,30000,35000}
integer maxParticlesOptionsIndex = 1
-- --- UTILS ---

sequence backimage,backtex
atom pixels
function GetGaussianRandom(atom mean, atom stdDev)
    atom u1 = GetRandomValue(1, 10000)*inv10000
    atom u2 = GetRandomValue(1, 10000)*inv10000
    atom r = sqrt(-2.0*log(u1))
    atom theta = 2.0*PI_*u2
    return (r*cos(theta))*stdDev + mean
end function

function GetSelectedColor(integer isSolid)
    integer variantFrom = 100
    integer variantTo
    if isSolid then
        variantTo=100
    else
        variantTo=255
    end if
    switch (selectedColor) 
    do
        case COLOR_BLUE then 
            return { GetRandomValue(variantFrom, variantTo), GetRandomValue(variantFrom, variantTo), 255, 255 } 
            break
        case COLOR_GREEN then
            return { GetRandomValue(variantFrom, variantTo), 255, GetRandomValue(variantFrom, variantTo), 255 } 
            break
        case COLOR_RED then  
            return { 255, GetRandomValue(variantFrom, variantTo), GetRandomValue(variantFrom, variantTo), 255 } 
            break
        case else 
            return { 255, GetRandomValue(variantFrom, variantTo), GetRandomValue(variantFrom, variantTo), 255 } --RED Fallback
            break
    end switch
end function

procedure ResetParticles()
    if (length(particles) <maxParticles) 
    then 
        particles = repeat(Particle,maxParticles)
    end if
    atom centerX =  screenWidth*0.5
    atom centerY =  screenHeight*0.5
    atom spreadX =  screenWidth*0.166
    atom spreadY =  screenHeight*0.166

    for i = 1 to maxParticles 
    do
        particles[i][_position][x] = GetGaussianRandom(centerX, spreadX)
        particles[i][_position][y] = GetGaussianRandom(centerY, spreadY)
        particles[i][velocity] = {GetRandomValue(-5, 5)*0.1,GetRandomValue(-5, 5)*0.1 }
        particles[i][color] = GetSelectedColor(false)

        if (particles[i][_position][x] < 0) then particles[i][_position][x] = screenWidth end if
        if (particles[i][_position][x] >= screenWidth) then particles[i][_position][x] = 0 end if
        if (particles[i][_position][y] < 0) then particles[i][_position][y] = screenHeight end if
        if (particles[i][_position][y] >= screenHeight) then particles[i][_position][y] = 0 end if
    end for
end procedure

-- --- CORE ---

global function Init()
    SetConfigFlags(FLAG_WINDOW_RESIZABLE)

    InitWindow(screenWidth, screenHeight, "raylib - Particle Effects")  
    backimage=GenImageColor(screenWidth,screenHeight,BLACK)
    backimage=ImageFormat(backimage,PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)
    backtex=LoadTextureFromImage(backimage)
    sequence backCopy = ImageCopy(backimage)
    

    SetExitKey(KEY_NULL) -- Prevent ESC from closing window
    InitAudioDevice()

    backgroundMusic = LoadMusicStream("resources/background-music.mp3")
    if not(IsMusicValid(backgroundMusic))
    then
        TraceLog(LOG_ERROR, "Error while loading the background music",1)
        return false
    end if
    
    SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME)
    PlayMusicStream(backgroundMusic)

    screenWidth = GetScreenWidth()
    screenHeight = GetScreenHeight()

    particles = repeat(Particle,maxParticles)
    if (length(particles) < 2) then return false end if

    ResetParticles()
    --SetTargetFPS(30)
    return true
end function

global function UpdateDrawFrame()

    if (IsWindowResized())
    then
        screenWidth = GetScreenWidth()
        screenHeight = GetScreenHeight()
    UnloadImage(backimage)
    backimage=GenImageColor(screenWidth,screenHeight,BLACK)
    backimage=ImageFormat(backimage,PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)
    UnloadTexture(backtex)
    backtex=LoadTextureFromImage(backimage)
        needRestart = true
    end if

    UpdateMusicStream(backgroundMusic)
    integer gesture = GetGestureDetected()
    sequence touchPos = GetTouchPosition(0) 
    integer isActionPressed = IsMouseButtonPressed(MOUSE_LEFT_BUTTON) or (gesture = GESTURE_TAP)
    integer activeFingers = GetTouchPointCount()

    -- --- LOGIC ---
    switch (currentState)
    do
        case STATE_MENU
        then
            if (isActionPressed)
            then
                atom halfScreen =  screenHeight*0.5
                -- Large touch zones for menu items
                if (touchPos[y] > 20 and touchPos[y] < 60)
                then
                    selectedColor = (mod((selectedColor + 1), 3))
                elsif (touchPos[y] > 60 and touchPos[y] < 80)
                then
                    musicMuted = not(musicMuted)
                    if (musicMuted)
                    then
                        SetMusicVolume(backgroundMusic, 0.0)
                    else
                        SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME)
                    end if
                elsif (touchPos[y] > 80 and touchPos[y] < 110)
                then
                    maxParticlesOptionsIndex = maxParticlesOptionsIndex + 1
                    if maxParticlesOptionsIndex> length(maxParticlesOptions) then
                        maxParticlesOptionsIndex=1
                    end if
                    if maxParticlesOptionsIndex< 1 then
                        maxParticlesOptionsIndex=length(maxParticlesOptions)
                    end if
                    maxParticles = maxParticlesOptions[maxParticlesOptionsIndex]
                
                elsif (touchPos[y] > halfScreen - 30 and touchPos[y] < halfScreen + 30)
                then
                    ResetParticles()
                    currentState = STATE_RELAX
                elsif (touchPos[y] > halfScreen + 30 and touchPos[y] < halfScreen + 80)
                then
                    currentState = STATE_ABOUT
                elsif (touchPos[y] > halfScreen + 80 and touchPos[y] < halfScreen + 130)
                then
                    return false
                end if
                previousEffectPosition = touchPos
                justStarted = true
            end if
        break

        case STATE_ABOUT
        then
            if (isActionPressed or IsKeyPressed(KEY_BACKSPACE) or IsKeyPressed(KEY_ESCAPE))
            then
                currentState = STATE_MENU
            end if
        break

        case STATE_RELAX 
        then 
            if (needRestart)
            then
                needRestart = false
                ResetParticles()
            end if
            atom effectSize = screenHeight*0.15
            atom effectStrength = screenHeight*0.002

            integer toggleRequested = IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) or (gesture = GESTURE_DOUBLETAP)
            integer resetRequested = IsKeyPressed(KEY_R) or activeFingers >= 3
            
            if (IsKeyPressed(KEY_ESCAPE) or resetRequested) 
            then
                currentState = STATE_MENU
                break
            end if

            if (toggleRequested)
            then
                if (currentEffect = EFFECT_ATTRACT) 
                then 
                    currentEffect= EFFECT_REPEL 
                else 
                    currentEffect =EFFECT_ATTRACT
                end if
                justStarted = false
            end if

            integer isDown = IsMouseButtonDown(MOUSE_LEFT_BUTTON) or (activeFingers > 0)
            if (justStarted or (isDown)) --if (justStarted and not(isDown))
            then
                justStarted = false
            end if

            if not(justStarted)
            then
                sequence mouseDelta = {}
                if (gesture != GESTURE_TAP or activeFingers = 0)
                then
                    mouseDelta = Vector2Subtract(touchPos, previousEffectPosition)
                end if
                atom segmentLengthSq = Vector2LengthSqr(mouseDelta)

                for i = 1 to maxParticles
                do
                    if (isDown)
                    then
                        sequence targetPos = touchPos
                        if (segmentLengthSq >= 0.0001)
                        then
                            sequence toParticle = Vector2Subtract(particles[i][_position], previousEffectPosition)
                            atom t = Clamp(Vector2DotProduct(toParticle, mouseDelta) / segmentLengthSq, 0.0, 1.0)
                            targetPos = { previousEffectPosition[x] + t*mouseDelta[x], previousEffectPosition[y] + t*mouseDelta[y] }
                        end if

                        atom dist = Vector2Distance(particles[i][_position], targetPos)
                        if (dist < effectSize)
                        then
                            sequence _dir = Vector2Normalize(Vector2Subtract(targetPos, particles[i][_position]))
                            atom force = effectStrength*(1.0 - (dist / effectSize))
                            atom _sign
                            if currentEffect=EFFECT_ATTRACT 
                            then
                                _sign=1
                            else
                                _sign=-1    
                            end if
                            particles[i][velocity][x] += _dir[x]*force*_sign
                            particles[i][velocity][y] += _dir[y]*force*_sign
                        end if
                    end if
                    particles[i][velocity][x] *= 0.95
                    particles[i][velocity][y] *= 0.95
                    particles[i][_position][x] += particles[i][velocity][x]
                    particles[i][_position][y] += particles[i][velocity][y]

                    if (particles[i][_position][x] < 0) then particles[i][_position][x] = screenWidth end if
                    if (particles[i][_position][x] >= screenWidth) then particles[i][_position][x] = 0 end if
                    if (particles[i][_position][y] < 0) then particles[i][_position][y] = screenHeight end if
                    if (particles[i][_position][y] >= screenHeight) then particles[i][_position][y] = 0 end if
                end for
            end if
            previousEffectPosition = touchPos
        break
        
        case else break
    end switch

    -- --- DRAW ---
    sequence TEXT="NONE"
    sequence col=RED
    BeginDrawing()
    ClearBackground(BLACK)

    switch (currentState)
    do
        case STATE_MENU
        then
            sequence uiColor = GetSelectedColor(true)
            if selectedColor=COLOR_BLUE 
            then
                TEXT="BLUE"
            elsif selectedColor=COLOR_GREEN
            then
                TEXT="GREEN"
            else
                TEXT="RED"  
            end if
            DrawText(sprintf("COLOR: %s", {TEXT}), screenWidth - 160, 20, 20, uiColor)
            if musicMuted then
                TEXT="OFF"
            else
                TEXT="ON"
            end if
            
            if musicMuted 
            then
                col=RED
            else
                col=uiColor
            end if
            DrawText(sprintf("MUSIC: %s", {TEXT}), screenWidth - 160, 60, 20, col)

            DrawText("Stress Release By Particles", screenWidth/2 - MeasureText("Stress Release By Particles", 40)/2, (screenHeight*0.5)-130, 40, uiColor)
            DrawText(sprintf("PARTICLES: %d", maxParticles), screenWidth - 215, 80, 20, uiColor)
            DrawText("START RELAXING", screenWidth/2 - MeasureText("START RELAXING", 25)/2, (screenHeight*0.5)-30, 25, uiColor)
            
            DrawText("ABOUT", screenWidth/2 - MeasureText("ABOUT", 20)/2, (screenHeight*0.5)+30, 20, uiColor)
            
            DrawText("EXIT", screenWidth/2 - MeasureText("EXIT", 20)/2, (screenHeight*0.5)+80, 20, uiColor)
        break

        case STATE_ABOUT
        then
            DrawText("ABOUT", screenWidth/2 - MeasureText("ABOUT", 30)/2, (screenHeight*0.2), 30, RAYWHITE)
            DrawText("A minimalist particle experience.", screenWidth/2 - 140, (screenHeight*0.4), 20, GRAY)
            DrawText("Tap/Click to interact.", screenWidth/2 - 100, (screenHeight*0.45), 20, GRAY)
            DrawText("Double Tap to toggle mode.", screenWidth/2 - 120, (screenHeight*0.5), 20, GRAY)
            sequence attribution = TextFormat("Documentary Background Music by Muyo5438\nhttps://freesound.org/s/712110/\nLicense: Attribution 4.0",{})
            DrawText(attribution, screenWidth/2 - MeasureText(attribution, 20)/2, (screenHeight*0.6), 20, GRAY)
            DrawText("TAP ANYWHERE TO GO BACK", screenWidth/2 - 150, (screenHeight*0.8), 15, DARKGRAY)
        break

        case STATE_RELAX
        then
            --backimage=ImageClearBackground(backimage,BLACK)
            pixels = LoadImageColors(backimage,1) -- Load pixel data from image (RGBA 32bit)
            --atom colx=bytes_to_int(particles[1][color])
            for i = 1 to maxParticles
            do
            atom x1=floor(particles[i][_position][x])
            atom y1=floor(particles[i][_position][y])
            atom offset=((y1*screenWidth+x1))*4
--          if y1>screenHeight then puts(1,"ping")
--          end if
--          if offset<0 then
--              offset=offset*-1
--          end if
--          if offset>screenWidth*screenHeight*4 then
--              offset=0
--          end if
            --poke(pixels+offset, particles[i][color])
            poke4(pixels+offset,bytes_to_int(particles[i][color]))
            --poke4(pixels+offset,colx)
            end for
            UpdateTexture(backtex, pixels)
            DrawTexture(backtex,0,0, WHITE)
            --DrawPixelV(particles[i][_position], particles[i][color])
            DrawText("Press ESC or 3-Finger Tap for Menu", 20, screenHeight - 30, 15, Fade(GRAY, 0.5))
            DrawFPS(10,10)
            UnloadImageColors(pixels)                   -- Unload pixels data from RAM
        break
        case else break
    end switch

    EndDrawing()
    return not(WindowShouldClose())
end function

global procedure Destroy()

    particles ={}
    CloseAudioDevice()
    UnloadMusicStream(backgroundMusic)
end procedure
