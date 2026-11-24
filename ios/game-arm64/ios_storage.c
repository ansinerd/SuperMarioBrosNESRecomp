#include <SDL.h>

/* SDL allocates the returned string.
 * The caller must release it with SDL_free().
 */
char *smb_ios_writable_base_path(void)
{
    return SDL_GetPrefPath("ansinerd", "SMBIOSGame");
}
