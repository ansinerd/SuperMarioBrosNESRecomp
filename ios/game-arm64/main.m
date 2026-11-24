/* iOS-only UIKit entry for the real NESRecomp game. No ROM is bundled.
 * This initial bridge looks for a user-provided .nes file in the app's
 * Documents directory. A proper Files picker and touch overlay follow later.
 */
#define SDL_MAIN_HANDLED
#import <Foundation/Foundation.h>
#import <SDL.h>
#import <SDL_main.h>
#include <stdio.h>

/* Compiled from cyc_host.c with main renamed for this iOS target only. */
extern int nesrecomp_host_entry(int argc, char **argv);

static int SDLCALL ios_game_main(int argc, char *argv[])
{
    @autoreleasepool {
        NSString *documents = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        if (!documents) {
            fprintf(stderr, "iOS: cannot find Documents directory\n");
            return 2;
        }

        NSError *error = nil;
        NSArray<NSString *> *names = [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:documents error:&error];
        if (!names) {
            fprintf(stderr, "iOS: cannot read Documents directory: %s\n",
                error.localizedDescription.UTF8String ?: "unknown error");
            return 2;
        }

        NSString *romPath = nil;
        for (NSString *name in [names sortedArrayUsingSelector:@selector(compare:)]) {
            if ([name.pathExtension caseInsensitiveCompare:@"nes"] == NSOrderedSame) {
                romPath = [documents stringByAppendingPathComponent:name];
                break;
            }
        }

        if (!romPath) {
            fprintf(stderr, "iOS: no .nes file in Documents. Import your own ROM first.\n");
            return 2;
        }

        /* This pointer remains valid for the duration of the call because
           romPath stays retained by the surrounding autorelease pool. */
        char *gameArgs[] = {
            (argc > 0 && argv && argv[0]) ? argv[0] : (char *)"SMBIOSGame",
            (char *)romPath.fileSystemRepresentation,
            NULL
        };
        SDL_SetMainReady();
        return nesrecomp_host_entry(2, gameArgs);
    }
}

int main(int argc, char *argv[])
{
    return SDL_UIKitRunApp(argc, argv, ios_game_main);
}
