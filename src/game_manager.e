without warning
--adapted to Phix/Euphoria 2026 Andreas Wagner
include "..\\..\\raylib64.e"
--/**/constant PI_=PI
--/*
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
enum _position,velocity,color
enum x,y
--typedef struct Particle {
--  Vector2 position;
--  Vector2 velocity;
--  Color color;
--} Particle;

-- Globals
integer screenWidth = 800
integer screenHeight = 450
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

-- --- UTILS ---

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
            break
    end switch
end function

procedure ResetParticles()
    if (length(particles) <2) then return end if
    atom centerX =  screenWidth*0.5
    atom centerY =  screenHeight*0.5
    atom spreadX =  screenWidth*0.166
    atom spreadY =  screenHeight*0.166

    for i = 1 to MAX_PARTICLES 
    do
        particles[i][_position][x] = GetGaussianRandom(centerX, spreadX)
        particles[i][_position][y] = GetGaussianRandom(centerY, spreadY)
        particles[i][velocity] = {GetRandomValue(-5, 5)*0.1,GetRandomValue(-5, 5)*0.1 }
        
        particles[i][color] = GetSelectedColor(false)
    end for
end procedure

-- --- CORE ---

global function Init()
    SetConfigFlags(FLAG_WINDOW_RESIZABLE)


    InitWindow(screenWidth, screenHeight, "raylib - Particle Effects")
    SetExitKey(KEY_NULL) -- Prevent ESC from closing window
    InitAudioDevice()

    backgroundMusic = LoadMusicStream("resources/background-music.mp3")
    if not(IsMusicValid(backgroundMusic))
    then
        TraceLog(LOG_ERROR, "Error while loading the background music")
        return false
    end if
    
    SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME)
    PlayMusicStream(backgroundMusic)

    screenWidth = GetScreenWidth()
    screenHeight = GetScreenHeight()

    particles = repeat(Particle,MAX_PARTICLES)
    if (length(particles) < 2) then return false end if

    ResetParticles()
    SetTargetFPS(60)
    return true
end function

global function UpdateDrawFrame()

    if (IsWindowResized())
    then
        screenWidth = GetScreenWidth()
        screenHeight = GetScreenHeight()
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
                    selectedColor = mod((selectedColor + 1), 3)
                elsif (touchPos[y] > 60 and touchPos[y] < 100)
                then
                    musicMuted = not(musicMuted)
                    if (musicMuted)
                    then
                        SetMusicVolume(backgroundMusic, 0.0)
                    else
                        SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME)
                    end if
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
            if (justStarted and not(isDown))
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

                for i = 1 to MAX_PARTICLES
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
                    if (particles[i][_position][x] > screenWidth) then particles[i][_position][x] = 0 end if
                    if (particles[i][_position][y] < 0) then particles[i][_position][y] = screenHeight end if
                    if (particles[i][_position][y] > screenHeight) then particles[i][_position][y] = 0 end if
                end for
            end if
            previousEffectPosition = touchPos
        break
        
        case else break
    end switch

    -- --- DRAW ---
    BeginDrawing()
    ClearBackground(BLACK)

    switch (currentState)
    do
        case STATE_MENU
        then
            sequence uiColor = GetSelectedColor(true)
            
--          DrawText(TextFormat("COLOR: %s", (selectedColor == COLOR_BLUE) ? "BLUE" : (selectedColor == COLOR_GREEN ? "GREEN" : "RED")), 
--                   screenWidth - 160, 20, 20, uiColor);
            
--          DrawText(TextFormat("MUSIC: %s", musicMuted ? "OFF" : "ON"), 
--                   screenWidth - 160, 60, 20, musicMuted ? RED : uiColor);

            DrawText("Stress Release By Particles", screenWidth/2 - MeasureText("Stress Release By Particles", 40)/2, (screenHeight*0.5)-130, 40, uiColor)
            
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
            for i = 1 to MAX_PARTICLES 
            do
                _DrawPixelV(particles[i][_position], particles[i][color])
            end for
            DrawText("Press ESC or 3-Finger Tap for Menu", 20, screenHeight - 30, 15, Fade(GRAY, 0.5))
            DrawFPS(10,10)
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
