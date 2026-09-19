# 便利店素材与导入记录
2026-09-09，内置 image_gen 生成，源文件保留于 Codex generated_images。
- props.png：exec-005d0091-7111-480c-9975-c20a7da16211.png。三个独立等距物件：双门饮料冷柜、食品货架、收银台。实际 RGBA，具有透明通道；按三个不等宽区域及 alpha>0.45 的边界裁切。没有使用整栋建筑背景。
- front.png：exec-4041510e-db3b-477f-850b-c9e2a2e95099.png。玻璃橱窗与玻璃门的正立面图集，通过独立 Polygon2D 和 SwingDoor 使用。实际分界为横向约64.5%，导入时据此设置 UV。
提示词：realistic PZ-style isometric convenience-store props, refrigerator stocked with water, canned-food gondola, checkout register, isolated assets; storefront straight-on elevation, black aluminum frame, reflective glass, glass door with pull handle and OPEN sign, opaque texture modules, no complete building.
原始生成图片复制到本目录，mipmaps 开启。缩放、UV、碰撞及轮廓高亮在引擎内完成。
