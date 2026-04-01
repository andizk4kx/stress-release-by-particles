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

void ResetParticles()
{
    if (particles == NULL) return;

    for (int i = 0; i < MAX_PARTICLES; i++)
    {
        particles[i].position = (Vector2){ (float)GetRandomValue(0, screenWidth), (float)GetRandomValue(0, screenHeight) };
        particles[i].velocity = (Vector2){ (float)GetRandomValue(-10, 10) / 10.0f, (float)GetRandomValue(-10, 10) / 10.0f };
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

    // --- INPUT LOGIC ---
    int currentGesture = GetGestureDetected();
    int activeFingers = GetTouchPointCount();

    // Toggle: Right Click (PC) OR 1-finger Double Tap (Touch)
    bool toggleRequested = IsMouseButtonPressed(MOUSE_RIGHT_BUTTON) ||
                           (currentGesture == GESTURE_DOUBLETAP && activeFingers < 2);

    // Reset: 'R' Key, Middle Click (PC) OR 2-finger Tap (Touch)
    bool resetRequested = IsKeyPressed(KEY_R) ||
                          IsMouseButtonPressed(MOUSE_MIDDLE_BUTTON) ||
                          activeFingers >= 2;

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

        // --- UPDATE LOGIC ---
        for (int i = 0; i < MAX_PARTICLES; i++) {
            float dist = Vector2Distance(particles[i].position, mousePos);

            if (dist < effectSize && IsMouseButtonDown(MOUSE_LEFT_BUTTON)) {
                Vector2 dir = Vector2Normalize(Vector2Subtract(mousePos, particles[i].position));

                // Calculate how strong the push/pull should be based on distance
                float forceMultiplier = EFFECT_STRENGTH * (1.0f - (dist / effectSize));

                // Apply the force based on the current active state
                if (currentEffect == EFFECT_ATTRACT) {
                    particles[i].velocity.x += dir.x * forceMultiplier;
                    particles[i].velocity.y += dir.y * forceMultiplier;
                } else if (currentEffect == EFFECT_REPEL) {
                    particles[i].velocity.x -= dir.x * forceMultiplier; // Subtract to push away
                    particles[i].velocity.y -= dir.y * forceMultiplier;
                }
            }

            // Apply friction/damping so they don't fly off forever
            particles[i].velocity.x *= 0.95f;
            particles[i].velocity.y *= 0.95f;

            // Apply velocity to position
            particles[i].position.x += particles[i].velocity.x;
            particles[i].position.y += particles[i].velocity.y;

            // Wrap around screen edges
            if (particles[i].position.x < 0) particles[i].position.x = (float) screenWidth;
            if (particles[i].position.x > (float) screenWidth) particles[i].position.x = 0;
            if (particles[i].position.y < 0) particles[i].position.y = (float) screenHeight;
            if (particles[i].position.y > (float) screenHeight) particles[i].position.y = 0;
        }
    }

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