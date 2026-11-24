/* Native iOS entry point for the recompiled Mario game.
 * ROM is supplied privately during the build.
 */
#define SDL_MAIN_HANDLED

#import <Foundation/Foundation.h>
#import <SDL.h>
#import <SDL_main.h>

extern int nesrecomp_host_entry(int argc, char **argv);

static int SDLCALL ios_game_main(int argc, char *argv[])
{
    @autoreleasepool {
        NSString *romPath = [[NSBundle mainBundle]
            pathForResource:@"original"
            ofType:@"nes"];

        if (!romPath) {
            NSLog(@"iOS: bundled game resource not found");
            return 2;
        }

        /* Prefer Metal for SDL2 graphics presentation. */
        SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
        SDL_SetMainReady();

        char *gameArgs[] = {
            (argc > 0 && argv && argv[0])
                ? argv[0] : (char *)"SMBIOSGame",
            (char *)romPath.fileSystemRepresentation,
            NULL
        };

        return nesrecomp_host_entry(2, gameArgs);
    }
}

int main(int argc, char *argv[])
{
    return SDL_UIKitRunApp(argc, argv, ios_game_main);
}
