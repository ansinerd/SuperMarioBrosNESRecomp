/* iOS-only touch gamepad. The NESRecomp runtime reads this as an SDL2
 * virtual GameController, so no engine submodule changes are necessary.
 */
#define SDL_MAIN_HANDLED
#import <UIKit/UIKit.h>
#import <SDL.h>

static SDL_Joystick *s_touchPad;

@interface SMBTouchOverlay : UIView
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, UIButton *> *keys;
@end

@implementation SMBTouchOverlay

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.multipleTouchEnabled = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.keys = [NSMutableDictionary dictionary];
        [self addKey:@"↑" button:SDL_CONTROLLER_BUTTON_DPAD_UP];
        [self addKey:@"↓" button:SDL_CONTROLLER_BUTTON_DPAD_DOWN];
        [self addKey:@"←" button:SDL_CONTROLLER_BUTTON_DPAD_LEFT];
        [self addKey:@"→" button:SDL_CONTROLLER_BUTTON_DPAD_RIGHT];
        [self addKey:@"A" button:SDL_CONTROLLER_BUTTON_A];
        /* NESRecomp's default mapping uses X for the NES B button. */
        [self addKey:@"B" button:SDL_CONTROLLER_BUTTON_X];
        [self addKey:@"START" button:SDL_CONTROLLER_BUTTON_START];
        [self addKey:@"SELECT" button:SDL_CONTROLLER_BUTTON_BACK];
    }
    return self;
}

- (void)addKey:(NSString *)label button:(SDL_GameControllerButton)button
{
    UIButton *key = [UIButton buttonWithType:UIButtonTypeCustom];
    key.tag = button;
    key.multipleTouchEnabled = YES;
    key.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.58];
    key.layer.cornerRadius = 13;
    key.layer.borderWidth = 1;
    key.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.45].CGColor;
    key.titleLabel.font = [UIFont boldSystemFontOfSize:label.length > 2 ? 11 : 22];
    [key setTitle:label forState:UIControlStateNormal];
    [key setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [key addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
    [key addTarget:self action:@selector(released:) forControlEvents:
        UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self addSubview:key];
    self.keys[@(button)] = key;
}

- (void)pressed:(UIButton *)button
{
    if (s_touchPad) SDL_JoystickSetVirtualButton(s_touchPad, (int)button.tag, 1);
    button.backgroundColor = [UIColor colorWithWhite:0.32 alpha:0.82];
}

- (void)released:(UIButton *)button
{
    if (s_touchPad) SDL_JoystickSetVirtualButton(s_touchPad, (int)button.tag, 0);
    button.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.58];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hit = [super hitTest:point withEvent:event];
    /* Pass touches in the empty parts of the overlay through to SDL. */
    return hit == self ? nil : hit;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat size = MIN(58.0, MAX(40.0, h * 0.145));
    CGFloat gap = 3.0;
    CGFloat dpadX = safe.left + 22.0 + size;
    CGFloat dpadY = h - safe.bottom - 24.0 - 1.55 * size;
    CGFloat actionX = w - safe.right - 24.0 - 1.65 * size;
    CGFloat actionY = dpadY;

    [self position:SDL_CONTROLLER_BUTTON_DPAD_UP x:dpadX y:dpadY-size-gap size:size];
    [self position:SDL_CONTROLLER_BUTTON_DPAD_DOWN x:dpadX y:dpadY+size+gap size:size];
    [self position:SDL_CONTROLLER_BUTTON_DPAD_LEFT x:dpadX-size-gap y:dpadY size:size];
    [self position:SDL_CONTROLLER_BUTTON_DPAD_RIGHT x:dpadX+size+gap y:dpadY size:size];
    [self position:SDL_CONTROLLER_BUTTON_X x:actionX-size-gap y:actionY+size/2 size:size];
    [self position:SDL_CONTROLLER_BUTTON_A x:actionX+size/2 y:actionY-size/2 size:size];

    CGFloat small = MIN(57.0, size * 0.95);
    CGFloat mid = w / 2.0;
    CGFloat bottomY = h - safe.bottom - 19.0 - small;
    [self position:SDL_CONTROLLER_BUTTON_BACK x:mid-small-5 y:bottomY size:small];
    [self position:SDL_CONTROLLER_BUTTON_START x:mid+5 y:bottomY size:small];
}

- (void)position:(SDL_GameControllerButton)button x:(CGFloat)x y:(CGFloat)y size:(CGFloat)size
{
    self.keys[@(button)].frame = CGRectMake(x, y, size, size);
}
@end

static SMBTouchOverlay *s_overlay;

static void smb_install_overlay(void)
{
    if (s_overlay) return;
    UIApplication *app = UIApplication.sharedApplication;
    UIWindow *window = nil;
    for (UIWindow *candidate in app.windows) {
        if (candidate.isKeyWindow) { window = candidate; break; }
    }
    if (!window) window = app.windows.lastObject;
    if (!window) return;
    s_overlay = [[SMBTouchOverlay alloc] initWithFrame:window.bounds];
    [window addSubview:s_overlay];
    [s_overlay setNeedsLayout];
}

static int SDLCALL smb_touch_event_watch(void *userdata, SDL_Event *event)
{
    (void)userdata;
    if (event->type == SDL_WINDOWEVENT &&
        (event->window.event == SDL_WINDOWEVENT_SHOWN ||
         event->window.event == SDL_WINDOWEVENT_FOCUS_GAINED ||
         event->window.event == SDL_WINDOWEVENT_SIZE_CHANGED)) {
        smb_install_overlay();
    }
    return 0;
}

void smb_touch_controls_start(void)
{
    if (SDL_InitSubSystem(SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER) != 0) {
        NSLog(@"iOS touch: controller subsystem: %s", SDL_GetError());
        return;
    }
    SDL_VirtualJoystickDesc desc;
    SDL_zero(desc);
    desc.version = SDL_VIRTUAL_JOYSTICK_DESC_VERSION;
    desc.type = SDL_JOYSTICK_TYPE_GAMECONTROLLER;
    desc.naxes = SDL_CONTROLLER_AXIS_MAX;
    desc.nbuttons = SDL_CONTROLLER_BUTTON_MAX;
    desc.name = "iOS Touch NES Pad";
    int idx = SDL_JoystickAttachVirtualEx(&desc);
    if (idx < 0) {
        NSLog(@"iOS touch: virtual controller: %s", SDL_GetError());
        return;
    }
    s_touchPad = SDL_JoystickOpen(idx);
    if (!s_touchPad || !SDL_IsGameController(idx)) {
        NSLog(@"iOS touch: virtual joystick did not register as a game controller");
        return;
    }
    SDL_AddEventWatch(smb_touch_event_watch, NULL);
    NSLog(@"iOS touch controller attached");
}

void smb_touch_controls_stop(void)
{
    SDL_DelEventWatch(smb_touch_event_watch, NULL);
    [s_overlay removeFromSuperview];
    s_overlay = nil;
    /* cyc_sdl_main() normally shuts down SDL when the game exits. */
    s_touchPad = NULL;
}
