CmdEncoder :: struct {
    cmd_buf: VkCommandBuffer;
}

cmd_encoder_begin :: (enc: *CmdEncoder) {
    // TODO: actually do allocate a new command buffer from the pool
    // instead of this incredible jank
    enc.cmd_buf = device_get_perframe().cmd_buf;
}

cmd_encoder_end :: (enc: *CmdEncoder) {
    enc.cmd_buf = null;
}

cmd_encoder_begin_rendering :: (enc: *CmdEncoder, img_view: *ImageView) {
    w := device.swapchain.width;
    h := device.swapchain.height;
    att_info := VkRenderingAttachmentInfo.{
        imageView=img_view.vk_img_view,
        imageLayout=.COLOR_ATTACHMENT_OPTIMAL,
        loadOp=.CLEAR,
        storeOp=.STORE,
        clearValue=.{color=.{float.[0.2, 0.2, 0.0, 1.0]}},
    };
    rinfo := VkRenderingInfo.{
        renderArea=.{
            offset=.{},
            extent=.{w, h},
        },
        colorAttachmentCount=1,
        pColorAttachments=*att_info,
        layerCount=1,
    };
    vkCmdBeginRendering(enc.cmd_buf, *rinfo);
}

cmd_encoder_end_rendering :: (enc: *CmdEncoder) {
    vkCmdEndRendering(enc.cmd_buf);
}
