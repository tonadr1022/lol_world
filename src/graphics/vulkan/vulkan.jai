VALIDATION_LAYERS_ENABLED :: true; 
ABORT_ON_DEBUG_CALLBACK :: true;
FRAMES_IN_FLIGHT :: 2;

min_vulkan_api_version :: VK_API_VERSION_1_4;

required_device_extensions :: *u8.[
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    VK_KHR_SPIRV_1_4_EXTENSION_NAME,
    VK_KHR_SYNCHRONIZATION_2_EXTENSION_NAME
];

device: Device;

get_device :: () -> *Device {
    return *device;
}

get_swapchain :: () -> *Swapchain {
    return *device.swapchain;
}

begin_frame :: () {

}

end_frame :: () {
    {
        using device;
        curr_frame += 1;
        curr_frame_in_flight = curr_frame % FRAMES_IN_FLIGHT;
    }
}

begin_main_cmd_buf :: () {
    {
        using device;
        binfo := VkCommandBufferBeginInfo.{};
        cmd_buf := per_frames[curr_frame_in_flight].cmd_buf;
        vk_check(vkResetCommandBuffer(cmd_buf, 0));
        vk_check(vkBeginCommandBuffer(cmd_buf, *binfo));
    }
}

end_main_cmd_buf :: () {
    using device;
    cmd_buf := per_frames[curr_frame_in_flight].cmd_buf;
    vk_check(vkEndCommandBuffer(cmd_buf));
}

init :: (app_name: string, window: *SDL_Window) -> bool {
    // TODO: this is incredibly jank.
    #if OS != .LINUX {
        print("Unsupported OS\n");
        #assert false;
    }

    if !SDL_Vulkan_LoadLibrary("libvulkan.so.1") && !SDL_Vulkan_LoadLibrary("libvulkan.so") {
        print("Failed to load Vulkan library: %\n", to_string(SDL_GetError()));
        return false;
    }
    vkGetInstanceProcAddr := SDL_Vulkan_GetVkGetInstanceProcAddr();
    if !vkGetInstanceProcAddr {
        print(to_string(SDL_GetError()));
        return false;
    }

    vk_load_global_functions(cast(*void)vkGetInstanceProcAddr);

    enabled_layers: [..]*u8;
    if VALIDATION_LAYERS_ENABLED {
        array_add(*enabled_layers, "VK_LAYER_KHRONOS_validation");
    }

    available_layer_count: u32;
    vkEnumerateInstanceLayerProperties(*available_layer_count, null);
    layers : [..]VkLayerProperties;
    array_resize(*layers, available_layer_count);
    vkEnumerateInstanceLayerProperties(*available_layer_count, layers.data);

    for i: 0..enabled_layers.count-1 {
        enabled_layer_name := enabled_layers[i];
        found := false;
        for layer: layers {
            if to_string(layer.layerName) == to_string(enabled_layer_name) {
                found = true;
                break;
            }
        }
        if !found {
            print("Vulkan: Validation layer % not available.\n", enabled_layer_name);
            return false;
        }
    }

    sdl_vulkan_extension_count: u32;
    SDL_Vulkan_GetInstanceExtensions(*sdl_vulkan_extension_count);
    assert(sdl_vulkan_extension_count <= 32);
    sdl_vulkan_extensions := SDL_Vulkan_GetInstanceExtensions(*sdl_vulkan_extension_count);
    instance_extensions: [..]*u8;
    defer array_free(instance_extensions);

    array_reserve(*instance_extensions, sdl_vulkan_extension_count + 1);
    for 0..sdl_vulkan_extension_count-1 {
        array_add(*instance_extensions, sdl_vulkan_extensions[it]);
    }
    if VALIDATION_LAYERS_ENABLED {
        array_add(*instance_extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    }

    app_info := VkApplicationInfo.{
        pApplicationName=to_c_string(app_name),
        applicationVersion=VK_MAKE_VERSION(1, 0, 0),
        pEngineName="no_engine",
        engineVersion=VK_MAKE_VERSION(1, 0, 0),
        apiVersion=min_vulkan_api_version,
    };
    inst_info := VkInstanceCreateInfo.{
        pApplicationInfo=*app_info,
        enabledLayerCount=xx enabled_layers.count,
        ppEnabledLayerNames=enabled_layers.data,
        enabledExtensionCount=xx instance_extensions.count,
        ppEnabledExtensionNames=instance_extensions.data,
    };

    vk_check(vkCreateInstance(*inst_info, null, *device.instance));
    vk_load_instance_functions(device.instance);


    device.physical_device = select_physical_device(min_vulkan_api_version, required_device_extensions);
    if !device.physical_device {
        print("failed to find a suitable GPU.\n");
        return false;
    }

    SDL_Vulkan_CreateSurface(window, device.instance, null, *device.surface);
    if !device.surface {
        print("Failed to create Vulkan surface: %\n", to_string(SDL_GetError()));
        return false;
    }

    props: VkPhysicalDeviceProperties;
    vkGetPhysicalDeviceProperties(device.physical_device, *props);
    device_name := to_string(props.deviceName.data);
    print("Physical Device: %\n", device_name);
    print("Device Type: %\n", props.deviceType);

    device.device = create_logical_device(device.physical_device);
    if !device.device {
        print("Failed to create logical device.\n");
        return false;
    }

    vk_load_device_functions(device.device);

    if VALIDATION_LAYERS_ENABLED {
        debug_utils_cinfo := VkDebugUtilsMessengerCreateInfoEXT.{
            messageSeverity=.WARNING | .ERROR,
            messageType=.GENERAL | .VALIDATION | .PERFORMANCE,
            pfnUserCallback=debug_callback,
            pUserData=cast(*void)*context,
        };
        assert(vkCreateDebugUtilsMessengerEXT != null);
        vk_check(vkCreateDebugUtilsMessengerEXT(device.instance, *debug_utils_cinfo, null, *device.debug_messenger));


        print("Vulkan: Validation layers enabled.\n");
    }

    assert(vkGetDeviceQueue != null);
    graphics_queue := *device.queues[0];
    vkGetDeviceQueue(device.device, graphics_queue.queueFamilyIndex, 0, *graphics_queue.queue);
    if !graphics_queue.queue {
        print("Failed to get device queue.\n");
        return false;
    }

    for * per_frame: device.per_frames {
        cinfo := VkCommandPoolCreateInfo.{
            queueFamilyIndex=graphics_queue.queueFamilyIndex,
            flags=.RESET_COMMAND_BUFFER,
        };
        vk_check(vkCreateCommandPool(device.device, *cinfo, null, *per_frame.command_pool));
        cmd_buf_cinfo := VkCommandBufferAllocateInfo.{
            commandPool=per_frame.command_pool,
            level=.PRIMARY,
            commandBufferCount=1,
        };
        vk_check(vkAllocateCommandBuffers(device.device, *cmd_buf_cinfo, *per_frame.cmd_buf));
    }


    x, y: s32;
    SDL_GetWindowSizeInPixels(window, *x, *y);
    if !swapchain_init(xx x, xx y, true) {
        return false;
    }

    return true;
}

shutdown :: () {
    using device;

    for * per_frames {
        if it.cmd_buf {
            vkFreeCommandBuffers(device, it.command_pool, 1, *it.cmd_buf);
            it.cmd_buf = null;
        }
        vkDestroyCommandPool(device, it.command_pool, null);
    }

    swapchain_destroy(*swapchain);

    if device {
        vkDestroyDevice(device, null);
        device = null;
    }
    if surface {
        vkDestroySurfaceKHR(instance, surface, null);
        surface = null;
    }
    if (debug_messenger) {
        vkDestroyDebugUtilsMessengerEXT(instance, debug_messenger, null);
    }
    if instance {
        vkDestroyInstance(instance, null);
        instance = null;
    }
}

#scope_module

vk_check :: (result: VkResult) {
    if (result != .SUCCESS) {
        print("Vulkan error: %\n", enum_value_to_name(result));
        exit(1);
    }
}

device_get_perframe :: () -> *Device.PerFrame {
    using device;
    return *per_frames[curr_frame_in_flight];
}

#scope_file


debug_callback :: (messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT, messageTypes: VkDebugUtilsMessageTypeFlagsEXT, pCallbackData: *VkDebugUtilsMessengerCallbackDataEXT, pUserData: *void) -> VkBool32 #c_call {
    ctx := cast(*#Context, pUserData).*;
    push_context,defer_pop ctx;

    print("%\n", to_string(pCallbackData.pMessage));

    #if ABORT_ON_DEBUG_CALLBACK exit(1);

    return VK_FALSE;
}

create_logical_device :: (phys_device: VkPhysicalDevice) -> VkDevice {
    // TODO: make sure presentation is supported on the graphics queue. 99% of time it is

    // just graphics queue for now
    // assume we can create a graphics queue based on select_physical_device.
    queue_families: [..]VkQueueFamilyProperties;
    defer array_free(queue_families);

    queue_family_count: u32;
    vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, null);
    array_resize(*queue_families, queue_family_count);
    vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, queue_families.data);

    selected_queue_idx := -1;

    for family, i: queue_families {
        if family.queueFlags & (.GRAPHICS | .COMPUTE | .TRANSFER) {
            selected_queue_idx = i;
            break;
        }
    }

    if selected_queue_idx == -1 {
        print("Failed to find a suitable queue family.\n");
        return null;
    }

    queuePriority: float32 = 1.0;
    queue_cinfo := VkDeviceQueueCreateInfo.{
        queueFamilyIndex=xx selected_queue_idx,
        queueCount=1,
        pQueuePriorities=*queuePriority,
    };

    queues : []VkDeviceQueueCreateInfo = .[queue_cinfo];

    features13 := VkPhysicalDeviceVulkan13Features.{
        dynamicRendering=1,
    };

    features2 := VkPhysicalDeviceFeatures2.{
        pNext=*features13,
    };

    cinfo := VkDeviceCreateInfo.{
        queueCreateInfoCount=1,
        pNext=*features2,
        pQueueCreateInfos=queues.data,
        ppEnabledExtensionNames=required_device_extensions.data,
        enabledExtensionCount=required_device_extensions.count,
    };

    device: VkDevice;
    vk_check(vkCreateDevice(phys_device, *cinfo, null, *device));
    return device;
}

select_physical_device :: (min_vulkan_api_version: u32, required_device_extensions: []*u8) -> VkPhysicalDevice {
    queue_families: [..]VkQueueFamilyProperties;
    defer array_free(queue_families);

    available_extensions: [..]VkExtensionProperties;
    defer array_free(available_extensions);

    phys_device_count: u32 = 0;
    vk_check(vkEnumeratePhysicalDevices(device.instance, *phys_device_count, null));
    phys_devices: [..]VkPhysicalDevice;
    defer array_free(phys_devices);
    array_resize(*phys_devices, phys_device_count);
    vk_check(vkEnumeratePhysicalDevices(device.instance, *phys_device_count, phys_devices.data));

    selected_phys_device: VkPhysicalDevice;
    best_score := 0;

    for phys_device: phys_devices {
        props: VkPhysicalDeviceProperties;
        vkGetPhysicalDeviceProperties(phys_device, *props);

        if props.apiVersion < min_vulkan_api_version continue;

        queue_family_count: u32;
        vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, null);
        array_resize(*queue_families, queue_family_count);
        vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, queue_families.data);

        has_graphics := false;
        for qfp: queue_families {
            if qfp.queueFlags & .GRAPHICS {
                has_graphics = true;
                break;
            }
        }
        if !has_graphics continue;

        ext_count: u32;
        vkEnumerateDeviceExtensionProperties(phys_device, null, *ext_count, null);
        array_resize(*available_extensions, ext_count);
        vkEnumerateDeviceExtensionProperties(phys_device, null, *ext_count, available_extensions.data);

        found_all_extensions := true;
        for req: required_device_extensions {
            found := false;
            for avail: available_extensions {
                if to_string(avail.extensionName.data) == to_string(req) {
                    found = true;
                    break;
                }
            }
            if !found {
                found_all_extensions = false;
                break;
            }
        }

        if !found_all_extensions {
            continue;
        }

        score := 0;

        if props.deviceType == .DISCRETE_GPU {
            score += 1;
        }
        if score > best_score {
            best_score = score;
            selected_phys_device = phys_device;
        }
    }

    return selected_phys_device;
}

#scope_file

#load "image.jai";
#load "swapchain.jai";
#load "device.jai";

#import "Compiler";
#import "Vulkan";
#import "POSIX";
#import "Basic";
#import "SDL";
#import "Reflection";

