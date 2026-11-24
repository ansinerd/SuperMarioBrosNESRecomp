/* Native iOS entry point for the recompiled Mario game.
 * ROM is supplied privately during the build.
 */
#define SDL_MAIN_HANDLED

#import <Foundation/Foundation.h>
#import <SDL.h>
#import <SDL_main.h>
#include <unistd.h>

extern int nesrecomp_host_entry(int argc, char **argv);
extern void smb_touch_controls_start(void);
extern void smb_touch_controls_stop(void);

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

        /* Use writable Application Support for settings and diagnostics. */
        NSURL *support = [[[NSFileManager defaultManager]
            URLsForDirectory:NSApplicationSupportDirectory
            inDomains:NSUserDomainMask] firstObject];

        NSURL *gameData = [support URLByAppendingPathComponent:@"SMBIOSGame"
            isDirectory:YES];

        NSError *storageError = nil;
        if (![[NSFileManager defaultManager]
                createDirectoryAtURL:gameData
                withIntermediateDirectories:YES
                attributes:nil
                error:&storageError] ||
            chdir(gameData.fileSystemRepresentation) != 0) {
            NSLog(@"Cannot initialize iOS game storage: %@", storageError);
            return 3;
        }
        SDL_SetMainReady();
        smb_touch_controls_start();

        char *gameArgs[] = {
            (argc > 0 && argv && argv[0])
                ? argv[0] : (char *)"SMBIOSGame",
            (char *)romPath.fileSystemRepresentation,
            NULL
        };

        int result = nesrecomp_host_entry(2, gameArgs);
        smb_touch_controls_stop();
        return result;
    }
}

int main(int argc, char *argv[])
{
    return SDL_UIKitRunApp(argc, argv, ios_game_main);
}
