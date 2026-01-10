APP_NAME :: "lol_world";

window: Window;

main :: () {
    print("lol_world!\n");

    window_init(*window, APP_NAME, 800, 800);

    gfx_init(APP_NAME, *window);
}

#scope_file

#load "window.jai";
#import,file "rhi/gfx.jai";
#import "Basic";
#import "SDL";
