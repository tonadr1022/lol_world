Image :: struct {
    vk_img: VkImage;
    format: Format;
    default_img_view: ImageView;
    width: u32;
    height: u32;
    depth: u32;
    array_layers: u32;
    mip_levels: u32;
    is_swapchain_img: bool;
}

vk_format_to_format :: (vk_format: VkFormat) -> Format {
    return cast(Format)(vk_format);
}

format_to_vk_format :: (format: Format) -> VkFormat {
    return cast(VkFormat)(format);
}

vk_img_view_type_to_image_view_type :: (vk_view_type: VkImageViewType) -> ImageViewType {
    return cast(ImageViewType)(vk_view_type);
}

img_view_type_to_vk_img_view_type :: (view_type: ImageViewType) -> VkImageViewType {
    return cast(VkImageViewType)(view_type);
}

is_depth_format :: (format: Format) -> bool {
    if format == {
        case .D16_UNORM; #through;
        case .X8_D24_UNORM_PACK32; #through; 
        case .D32_SFLOAT; #through;
        case .D16_UNORM_S8_UINT; #through;
        case .D24_UNORM_S8_UINT; #through;
        case .D32_SFLOAT_S8_UINT;
            return true;
        case;
            return false;
    }
}

image_create :: () {
}

image_create :: (
    image: *Image,
    vk_image: VkImage,
    format: Format,
    width: u32,
    height: u32,
    depth: u32 = 1,
    is_swapchain_img: bool
) {
    image.vk_img = vk_image;
    image.format = format;
    image.width = width;
    image.height = height;
    image.is_swapchain_img = is_swapchain_img;
    image.default_img_view = image_view_create(image, get_image_view_type(image), subresource_range={
        aspectMask=ifx is_depth_format(image.format) then VkImageAspectFlags.DEPTH else VkImageAspectFlags.COLOR,
        baseMipLevel=0,
        levelCount=ifx image.mip_levels == 0 then U32_MAX else image.mip_levels,
        baseArrayLayer=0,
        layerCount=ifx image.array_layers == 0 then U32_MAX else image.array_layers,
    });
}

image_destroy :: (image: *Image) {
    vkDestroyImageView(device.device, image.default_img_view.vk_img_view, null);
    if !image.is_swapchain_img {
        vkDestroyImage(device.device, image.vk_img, null);
    }
}

ImageView :: struct {
    vk_img_view: VkImageView;
}

image_view_create :: (image: *Image, img_view_type: ImageViewType, subresource_range: VkImageSubresourceRange) -> ImageView {
    cinfo := VkImageViewCreateInfo.{
        image=image.vk_img,
        viewType=img_view_type_to_vk_img_view_type(img_view_type),
        format=format_to_vk_format(image.format),
        components=.{
            r=.IDENTITY,
            g=.IDENTITY,
            b=.IDENTITY,
            a=.IDENTITY,
        },
        subresourceRange=subresource_range,
    };
    img_view: ImageView;
    vk_check(vkCreateImageView(device.device, *cinfo, null, *img_view.vk_img_view));

    return img_view;
}

#scope_file

get_image_view_type :: (image: *Image) -> ImageViewType {
    // TODO: arrays/cube.
    if image.depth > 1 {
        return .e3D;
    } else {
        return .e2D;
    }
}

#load "../rhi/image.jai";
#import "Vulkan";
#import "Math";
