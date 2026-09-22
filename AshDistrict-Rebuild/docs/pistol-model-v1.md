# 3D 手枪外观

现有可用手枪的方块占位模型已替换为真正的 3D 网格。网格从项目已保存的 Quaternius Zombie Apocalypse Kit 中独立提取，归一化为约 25 厘米长、15 厘米高，挂接到角色右手骨骼；枪口 Marker 用于瞄准线起点和枪口闪光定位。装备切换隐藏未选中的手持物，射击、装填、伤害、弹药、声音与存档沿用现有系统。

来源为 `art/characters/quaternius_zombie_apocalypse/Characters_Matt.gltf`，许可文件在同目录 `License.txt`，原作者 Quaternius，CC0。通过 `tools/build_pistol_model.gd` 可重建 `art/weapons/service_pistol.scn`；`tools/preview_pistol.gd` 和游戏参数 `--pistol-closeup` 可生成模型与实机截图。这是风格化低面数模型，实际镜头下较小，未制作滑套和弹匣运动。枪口 Marker 只负责视觉特效，命中仍由现有二维战斗系统计算。
