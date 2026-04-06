//
// Created by maiconpintoabreu on 25/02/2026.
//

#ifdef IS_ANDROID
#include "raymob.h"
#include <stdlib.h>
#else
#include "raylib.h"
#endif

#include "game_manager.h"

#if defined(PLATFORM_WEB)
    #include <emscripten/emscripten.h>
#endif


void UpdateDrawFrameWeb(void)
{
    if (!UpdateDrawFrame())
    {
        Destroy();
        CloseWindow();
    }
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main()
{
    if (!Init())
    {
#ifdef IS_ANDROID
        exit(-1);
#endif

        return -1;
    }

#if defined(PLATFORM_WEB)
    emscripten_set_main_loop(UpdateDrawFrameWeb, 0, 1);
#else
    SetTargetFPS(60);   // Set our game to run at 60 frames-per-second

    // Main game loop
    while (UpdateDrawFrame()) { }
#endif

    // De-Initialization
    //--------------------------------------------------------------------------------------
    Destroy();
    CloseWindow();
    //--------------------------------------------------------------------------------------

#ifdef IS_ANDROID
   exit(0);
#endif

    return 0;
}