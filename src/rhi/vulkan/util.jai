#scope_module

vk_check :: (result: VkResult) {
    if (result != .SUCCESS) {
        print("Vulkan error: %\n", enum_value_to_name(result));
        exit(1);
    }
}

#scope_file

#import "Vulkan";
#import "Basic";
#import "Reflection";
