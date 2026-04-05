//
// Created by maiconpintoabreu on 31/03/2026.
//
#ifdef IS_ANDROID
#include "raymob.h"
#else
#include "raylib.h"
#endif
#include "raymath.h" 
#include <stdbool.h>
#include <stdlib.h> // Required for malloc and free

#if defined(PLATFORM_WEB)
#define MAX_PARTICLES 100000
#else
#define MAX_PARTICLES 100000
#endif
#define EFFECT_STRENGTH 2.5f

typedef enum {
    EFFECT_ATTRACT,
    EFFECT_REPEL
} EffectType;

typedef struct Particle {
    Vector2 position;
    Vector2 velocity;
    Color color;
} Particle;

int screenWidth = 800;
int screenHeight = 450;

Particle *particles = NULL;

// Start with the attraction effect
EffectType currentEffect = EFFECT_ATTRACT;

bool justReset = false;

const float half = 0.5f;
const float invSix = 0.16666667f;
const float inv10000 = 0.0001f;

Vector2 previousEffectPosition = {0};

bool isUsingTouch = false;

// Use Gaussian Calculation to make the particles spread from the center
float GetGaussianRandom(float mean, float stdDev) {
    float u1 = (float)GetRandomValue(1, 10000) * inv10000;
    float u2 = (float)GetRandomValue(1, 10000) * inv10000;
    
    // Box-Muller transform
    float r = sqrtf(-2.0f*logf(u1));
    float theta = 2.0f*PI*u2;
    
    return (r*cosf(theta))*stdDev + mean;
}

void ResetParticles() {
    if (particles == NULL) return;
    
    float centerX = screenWidth*half;
    float centerY = screenHeight*half;
    float spreadX = screenWidth*invSix;
    float spreadY = screenHeight*invSix;

    for (int i = 0; i < MAX_PARTICLES; i++) {
        particles[i].position.x = GetGaussianRandom(centerX, spreadX);
        particles[i].position.y = GetGaussianRandom(centerY, spreadY);
        
        // 1.0f / 10.0f = 0.1f
        particles[i].velocity = (Vector2){ 
            (float)GetRandomValue(-5, 5)*0.1f, 
            (float)GetRandomValue(-5, 5)*0.1f 
        };
        
        // make it blueish
        particles[i].color = (Color){ GetRandomValue(100, 255), GetRandomValue(100, 255), 255, 255 };
    }
}

bool Init(void)
{

#ifdef IS_ANDROID
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_FULLSCREEN_MODE);
#elif defined(PLATFORM_WEB)
    SetConfigFlags(FLAG_WINDOW_RESIZABLE);
    screenWidth = 800;
    screenHeight = 450;
#else
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_FULLSCREEN_MODE);
#endif

    InitWindow(screenWidth, screenHeight, "raylib - Particle Effects");
    screenWidth = GetScreenWidth();
    screenHeight = GetScreenHeight();

    // Allocate the particle array
    particles = (Particle *)RL_MALLOC(MAX_PARTICLES * sizeof(Particle));
    
    if (particles == NULL) {
        TraceLog(LOG_ERROR, "Failed to allocate memory for particles!");
        return false;
    }

    ResetParticles();
    SetTargetFPS(60);
    return true;
}

void UpdateDrawFrame(void)
{
    if (particles == NULL) return;

    if (IsWindowResized())
    {
        screenWidth = GetScreenWidth();
        screenHeight = GetScreenHeight();
        ResetParticles();
        justReset = true;
    }

    Vector2 mousePos = GetMousePosition();
    float effectSize = (float)screenHeight*0.1f;
    float effectStrength = (float)screenHeight*0.002f;

    // --- INPUT LOGIC ---
    int currentGesture = GetGestureDetected();
    int activeFingers = GetTouchPointCount();

    // Toggle: Right Click (PC) OR 1-finger Double Tap (Touch)
    bool toggleRequested = IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) ||
                           (currentGesture == GESTURE_DOUBLETAP && activeFingers < 2);

    // Reset: 'R' Key, Middle Click (PC) OR 2-finger Tap (Touch)
    bool resetRequested = IsKeyPressed(KEY_R) ||
                          IsMouseButtonPressed(MOUSE_MIDDLE_BUTTON) ||
                          activeFingers >= 3;
    if (!isUsingTouch && activeFingers > 0) isUsingTouch = true;
    // Process inputs
    if (resetRequested)
    {
        if (!justReset) ResetParticles();
        justReset = true;
    }
    else if (toggleRequested)
    {
        if (currentEffect == EFFECT_ATTRACT)
        {
            currentEffect = EFFECT_REPEL;
        }
        else
        {
            currentEffect = EFFECT_ATTRACT;
        }
        justReset = false;
    }
    else
    {
        justReset = false;
    }
   if (!justReset) {
        bool isClicking = IsMouseButtonDown(MOUSE_LEFT_BUTTON);
        Vector2 mouseDelta = Vector2Zero();
        if (currentGesture != GESTURE_TAP)
        {
            mouseDelta = Vector2Subtract(mousePos, previousEffectPosition);
        }
        float segmentLengthSq = Vector2LengthSqr(mouseDelta);

        // --- UPDATE LOGIC ---
        for (int i = 0; i < MAX_PARTICLES; i++) {
            
            if (isClicking) {
                Vector2 targetPos;

                if (segmentLengthSq < 0.0001f) {
                    targetPos = mousePos;
                } else {

                    Vector2 toParticle = Vector2Subtract(particles[i].position, previousEffectPosition);
                    float t = Vector2DotProduct(toParticle, mouseDelta) / segmentLengthSq;
                    if (t < 0.0f) t = 0.0f;
                    if (t > 1.0f) t = 1.0f;

                    targetPos = (Vector2){ 
                        previousEffectPosition.x + t * mouseDelta.x, 
                        previousEffectPosition.y + t * mouseDelta.y 
                    };
                }

                float dist = Vector2Distance(particles[i].position, targetPos);

                if (dist < effectSize) {
                    
                    Vector2 dir = Vector2Normalize(Vector2Subtract(targetPos, particles[i].position));
                    float forceMultiplier = effectStrength*(1.0f - (dist/effectSize));

                    if (currentEffect == EFFECT_ATTRACT) {
                        particles[i].velocity.x += dir.x * forceMultiplier;
                        particles[i].velocity.y += dir.y * forceMultiplier;
                    } else if (currentEffect == EFFECT_REPEL) {
                        particles[i].velocity.x -= dir.x * forceMultiplier;
                        particles[i].velocity.y -= dir.y * forceMultiplier;
                    }
                }
            }
            else
            {
                previousEffectPosition = mousePos;
            }

            // Apply friction/damping
            particles[i].velocity.x *= 0.95f;
            particles[i].velocity.y *= 0.95f;

            // Apply velocity to position
            particles[i].position.x += particles[i].velocity.x;
            particles[i].position.y += particles[i].velocity.y;

            // Wrap around screen edges
            if (particles[i].position.x < 0) particles[i].position.x = (float)screenWidth;
            if (particles[i].position.x > (float)screenWidth) particles[i].position.x = 0;
            if (particles[i].position.y < 0) particles[i].position.y = (float)screenHeight;
            if (particles[i].position.y > (float)screenHeight) particles[i].position.y = 0;
        }
    }
    previousEffectPosition = mousePos;

    // --- DRAW LOGIC ---
    BeginDrawing();
        ClearBackground(BLACK);
        
        for (int i = 0; i < MAX_PARTICLES; i++)
        {
            DrawPixelV(particles[i].position, particles[i].color);
        }
    EndDrawing();
}

void Destroy(void)
{
    if (particles != NULL)
    {
        RL_FREE(particles);
    }
}