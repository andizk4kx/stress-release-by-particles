--
-- Created by maiconpintoabreu on 25/02/2026.
--
--adapted to Phix/Euphoria 2026 Andreas Wagner
include "raylib64.e"


include "game_manager.e"




--------------------------------------------------------------------------------------
-- Program main entry point
--------------------------------------------------------------------------------------
function main()
   {}=Init()


    --SetTargetFPS(30)  -- Set our game to run at 60 frames-per-second

    -- Main game loop
    while (UpdateDrawFrame()) do  end while


    -- De-Initialization
    ----------------------------------------------------------------------------------------
    Destroy()
    CloseWindow()
    ----------------------------------------------------------------------------------------
return 1
end function

{}=main()
