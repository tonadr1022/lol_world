#import "Vulkan";

Renderer :: struct {
    instance: VkInstance;
    device: VkDevice;
}
APP_NAME :: "lol_world";

renderer: Renderer;

main :: () {
    app_info := VkApplicationInfo.{pApplicationName=APP_NAME, apiVersion=VK_MAKE_API_VERSION(0, 1, 4, 0)};
    inst_info := VkInstanceCreateInfo.{pApplicationInfo=*app_info};
    vkCreateInstance(*inst_info, null, *renderer.instance);
}
