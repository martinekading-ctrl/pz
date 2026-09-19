# 2.5D 美术与实现约束

用户已选择：2D 等距贴图与人物动画，更接近参考图的细致画风。

- Godot 4.7.2 的二维渲染；二维地图坐标、脚底碰撞、Camera2D、Y 排序。
- 1536×1024 场景底图，2:1 等距轴线，阴天漫射光，灰绿植被、褪色旧木、锈棕金属。
- 场景底层与前景遮挡分别渲染。前景用同一底图的纹理多边形准确提取，人物进入汽车、家具、墙体后方时会被前景遮挡。
- 人物采用四个斜向、每向四帧的独立透明贴图；以脚底为锚点，目标世界高度 86 像素。
- 不将画在背景中的家具视为可移动物件。每个可搜索点、碰撞轮廓、导航区域均需与美术画面手工对齐。
- 首版 3D 项目与可执行程序保留；新版以 `iso.tscn` 为入口。

背景及角色图集由内置 image_gen 生成。背景以用户提供图片为风格参考，去除全部 UI 与人物，重建一处原创布局。生成文件原件仍保留于 Codex generated_images 目录。

生成提示词要点：gritty detailed pre-rendered isometric survival game art; muted moss green, ash gray, rotten wood and rust; orthographic elevated camera; no text or UI. 背景为可进入的开放房间、街道、废车与无线电营地。角色为透明 4×4 图集，四个方向分别为 southeast, southwest, northeast, northwest，每行四个走路姿势；幸存者穿橄榄绿外套、帽子、背包并携带撬棍，感染者穿褐灰色破旧衣物。
