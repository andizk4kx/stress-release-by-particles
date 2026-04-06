#ifdef IS_ANDROID
#include "raymob.h"
#else
#include "raylib.h"
#endif
#include "raymath.h" 
#include <stdbool.h>
#include <stdlib.h>

#define MAX_PARTICLES 100000
#define MAX_MUSIC_VOLUME 5.0f
#define EFFECT_STRENGTH 2.5f

typedef enum { STATE_MENU, STATE_ABOUT, STATE_RELAX, STATE_EXIT } GameState;
typedef enum { COLOR_BLUE, COLOR_GREEN, COLOR_RED } ParticleColor;
typedef enum { EFFECT_ATTRACT, EFFECT_REPEL } EffectType;

typedef struct Particle {
    Vector2 position;
    Vector2 velocity;
    Color color;
} Particle;

// Globals
int screenWidth = 800;
int screenHeight = 450;
Particle *particles = NULL;
EffectType currentEffect = EFFECT_ATTRACT;
GameState currentState = STATE_MENU;
ParticleColor selectedColor = COLOR_BLUE;

bool justStarted = false;
bool musicMuted = false;
bool shouldClose = false; // Flag to exit the application
bool needRestart = false;
Vector2 previousEffectPosition = {0};
Music backgroundMusic = {0};

const float inv10000 = 0.0001f;

// --- UTILS ---

float GetGaussianRandom(float mean, float stdDev)
{
    float u1 = (float)GetRandomValue(1, 10000)*inv10000;
    float u2 = (float)GetRandomValue(1, 10000)*inv10000;
    float r = sqrtf(-2.0f*logf(u1));
    float theta = 2.0f*PI*u2;
    return (r*cosf(theta))*stdDev + mean;
}

void ResetParticles(void)
{
    if (particles == NULL) return;
    float centerX = screenWidth*0.5f;
    float centerY = screenHeight*0.5f;
    float spreadX = screenWidth*0.166f;
    float spreadY = screenHeight*0.166f;

    for (int i = 0; i < MAX_PARTICLES; i++) {
        particles[i].position.x = GetGaussianRandom(centerX, spreadX);
        particles[i].position.y = GetGaussianRandom(centerY, spreadY);
        particles[i].velocity = (Vector2){ (float)GetRandomValue(-5, 5)*0.1f, (float)GetRandomValue(-5, 5)*0.1f };
        
        switch (selectedColor) {
            case COLOR_BLUE:  particles[i].color = (Color){ GetRandomValue(100, 255), GetRandomValue(100, 255), 255, 255 }; break;
            case COLOR_GREEN:  particles[i].color = (Color){ GetRandomValue(100, 255), 255, GetRandomValue(100, 255), 255 }; break;
            case COLOR_RED:  particles[i].color = (Color){ 255, GetRandomValue(100, 255), GetRandomValue(100, 255), 255 }; break;
        }
    }
}

// --- CORE ---

bool Init(void)
{
#if defined(IS_ANDROID) || !defined(PLATFORM_WEB)
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_FULLSCREEN_MODE);
#else
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
#endif

    InitWindow(screenWidth, screenHeight, "raylib - Particle Effects");
    SetExitKey(KEY_NULL); // Prevent ESC from closing window
    InitAudioDevice();

    backgroundMusic = LoadMusicStream("resources/background-music.mp3");
    if (!IsMusicValid(backgroundMusic))
    {
        TraceLog(LOG_ERROR, "Error while loading the background music");
        return false;
    }
    SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME);
    PlayMusicStream(backgroundMusic);

    screenWidth = GetScreenWidth();
    screenHeight = GetScreenHeight();

    particles = (Particle *)RL_MALLOC(MAX_PARTICLES*sizeof(Particle));
    if (particles == NULL) return false;

    ResetParticles();
    SetTargetFPS(60);
    return true;
}

bool UpdateDrawFrame(void)
{
    if (IsWindowResized())
    {
        screenWidth = GetScreenWidth();
        screenHeight = GetScreenHeight();
        needRestart = true;
    }

    UpdateMusicStream(backgroundMusic);
    int gesture = GetGestureDetected();
    Vector2 touchPos = GetTouchPosition(0); 
    bool isActionPressed = IsMouseButtonPressed(MOUSE_LEFT_BUTTON) || (gesture == GESTURE_TAP);
    int activeFingers = GetTouchPointCount();

    // --- LOGIC ---
    switch (currentState)
    {
        case STATE_MENU:
        {
            if (isActionPressed)
            {
                // Large touch zones for menu items
                if (touchPos.y > screenHeight*0.35f && touchPos.y < screenHeight*0.45f)
                {
                    selectedColor = (selectedColor + 1) % 3;
                }
                else if (touchPos.y > screenHeight*0.45f && touchPos.y < screenHeight*0.55f)
                {
                    musicMuted = !musicMuted;
                    if (musicMuted)
                    {
                        SetMusicVolume(backgroundMusic, 0.0f);
                    }
                    else
                    {
                        SetMusicVolume(backgroundMusic, MAX_MUSIC_VOLUME);
                    }
                }
                else if (touchPos.y > screenHeight*0.55f && touchPos.y < screenHeight*0.65f)
                {
                    ResetParticles();
                    currentState = STATE_RELAX;
                }
                else if (touchPos.y > screenHeight*0.65f && touchPos.y < screenHeight*0.75f)
                {
                    currentState = STATE_ABOUT;
                }
                else if (touchPos.y > screenHeight*0.80f)
                {
                    return false;
                }
                previousEffectPosition = touchPos;
                justStarted = true;
            }
        } break;

        case STATE_ABOUT:
        {
            if (isActionPressed || IsKeyPressed(KEY_BACKSPACE) || IsKeyPressed(KEY_ESCAPE))
            {
                currentState = STATE_MENU;
            }
        } break;

        case STATE_RELAX: {
            if (needRestart)
            {
                needRestart = false;
                ResetParticles();
            }
            float effectSize = (float)screenHeight*0.15f;
            float effectStrength = (float)screenHeight*0.002f;

            bool toggleRequested = IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) || (gesture == GESTURE_DOUBLETAP);
            bool resetRequested = IsKeyPressed(KEY_R) || activeFingers >= 3;
            
            if (IsKeyPressed(KEY_ESCAPE) || resetRequested) 
            {
                currentState = STATE_MENU;
                break;
            }

            if (toggleRequested)
            {
                currentEffect = (currentEffect == EFFECT_ATTRACT) ? EFFECT_REPEL : EFFECT_ATTRACT;
                justStarted = false;
            }

            bool isDown = IsMouseButtonDown(MOUSE_LEFT_BUTTON) || (activeFingers > 0);
            if (justStarted && !isDown)
            {
                justStarted = false;
            }

            if (!justStarted)
            {
                Vector2 mouseDelta = {0};
                if (gesture != GESTURE_TAP || activeFingers == 0)
                {
                    mouseDelta = Vector2Subtract(touchPos, previousEffectPosition);
                }
                float segmentLengthSq = Vector2LengthSqr(mouseDelta);

                for (int i = 0; i < MAX_PARTICLES; i++)
                {
                    if (isDown)
                    {
                        Vector2 targetPos = touchPos;
                        if (segmentLengthSq >= 0.0001f)
                        {
                            Vector2 toParticle = Vector2Subtract(particles[i].position, previousEffectPosition);
                            float t = Clamp(Vector2DotProduct(toParticle, mouseDelta) / segmentLengthSq, 0.0f, 1.0f);
                            targetPos = (Vector2){ previousEffectPosition.x + t*mouseDelta.x, previousEffectPosition.y + t*mouseDelta.y };
                        }

                        float dist = Vector2Distance(particles[i].position, targetPos);
                        if (dist < effectSize)
                        {
                            Vector2 dir = Vector2Normalize(Vector2Subtract(targetPos, particles[i].position));
                            float force = effectStrength*(1.0f - (dist / effectSize));
                            float sign = (currentEffect == EFFECT_ATTRACT) ? 1.0f : -1.0f;
                            particles[i].velocity.x += dir.x*force*sign;
                            particles[i].velocity.y += dir.y*force*sign;
                        }
                    }
                    particles[i].velocity.x *= 0.95f;
                    particles[i].velocity.y *= 0.95f;
                    particles[i].position.x += particles[i].velocity.x;
                    particles[i].position.y += particles[i].velocity.y;

                    if (particles[i].position.x < 0) particles[i].position.x = (float)screenWidth;
                    if (particles[i].position.x > screenWidth) particles[i].position.x = 0;
                    if (particles[i].position.y < 0) particles[i].position.y = (float)screenHeight;
                    if (particles[i].position.y > screenHeight) particles[i].position.y = 0;
                }
            }
            previousEffectPosition = touchPos;
        } break;
        
        default: break;
    }

    // --- DRAW ---
    BeginDrawing();
    ClearBackground(BLACK);

    switch (currentState)
    {
        case STATE_MENU:
            DrawText("Stress Release By Particles", screenWidth/2 - MeasureText("Stress Release By Particles", 40)/2, screenHeight*0.15f, 40, RAYWHITE);
            
            DrawText(TextFormat("COLOR: %s", (selectedColor == COLOR_BLUE) ? "BLUE" : (selectedColor == COLOR_GREEN ? "GREEN" : "RED")), 
                     screenWidth/2 - 80, screenHeight*0.4f, 20, RAYWHITE);
            
            DrawText(TextFormat("MUSIC: %s", musicMuted ? "OFF" : "ON"), 
                     screenWidth/2 - 80, screenHeight*0.5f, 20, musicMuted ? RED : GREEN);
            
            DrawText("START RELAXING", screenWidth/2 - MeasureText("START RELAXING", 25)/2, screenHeight*0.6f, 25, GOLD);
            
            DrawText("ABOUT", screenWidth/2 - MeasureText("ABOUT", 20)/2, screenHeight*0.7f, 20, LIGHTGRAY);
            
            DrawText("EXIT", screenWidth/2 - MeasureText("EXIT", 20)/2, screenHeight*0.84f, 20, MAROON);
            break;

        case STATE_ABOUT:
            DrawText("ABOUT", screenWidth/2 - MeasureText("ABOUT", 30)/2, screenHeight*0.2f, 30, RAYWHITE);
            DrawText("A minimalist particle experience.", screenWidth/2 - 140, screenHeight*0.4f, 20, GRAY);
            DrawText("Tap/Click to interact.", screenWidth/2 - 100, screenHeight*0.45f, 20, GRAY);
            DrawText("Double Tap to toggle mode.", screenWidth/2 - 120, screenHeight*0.5f, 20, GRAY);
            const char *attribution = TextFormat("Documentary Background Music by Muyo5438\nhttps://freesound.org/s/712110/\nLicense: Attribution 4.0");
            DrawText(attribution, screenWidth/2 - MeasureText(attribution, 20)/2, screenHeight*0.6f, 20, GRAY);
            DrawText("TAP ANYWHERE TO GO BACK", screenWidth/2 - 150, screenHeight*0.8f, 15, DARKGRAY);
            break;

        case STATE_RELAX:
            for (int i = 0; i < MAX_PARTICLES; i++) DrawPixelV(particles[i].position, particles[i].color);
            DrawText("Press ESC or 3-Finger Tap for Menu", 20, screenHeight - 30, 15, Fade(GRAY, 0.5f));
            break;
        default: break;
    }

    EndDrawing();
    return !WindowShouldClose();
}

void Destroy(void)
{
    if (particles != NULL) RL_FREE(particles);
    CloseAudioDevice();
    UnloadMusicStream(backgroundMusic);
}