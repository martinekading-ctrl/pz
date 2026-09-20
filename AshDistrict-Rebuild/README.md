# 余烬街区：重建版

这是从零建立的 2.5D 等距生存游戏项目。旧项目代码、旧地图裁图和旧场景均不被引用。

## 当前阶段

最新版本为 0.31：新游戏增加幸存者创建页面，提供普通幸存者、消防员、护理员和维修工四种职业，以及六项正负特质和点数平衡。职业决定初始技能与物资，特质实际影响战斗、体力、搜索、口渴、声音和经验；身份完整进入存档。说明见 `docs/character-creation-v1.md`。

0.30 车辆与燃油：首辆旧旅行车已经进入住宅街块。靠近后可检查车况、油量和后备箱，转移普通物资、使用汽油桶加油并进入驾驶；车辆具有加速、倒车、转向、障碍碰撞、撞击感染者、噪声、燃油消耗和完整存档。说明见 `docs/vehicle-system-v1.md`。

0.29 幸存者成长：加入体能、近战、搜索、生存四项行动成长。奔跑、战斗、首次搜查、医疗和施工会获得对应经验，每项技能最高 5 级并直接改善体力、伤害、搜索时间、治疗修理与武器保养。技能页从背包进入，成长状态完整进入存档。说明见 `docs/skill-progression-v1.md`。

0.27 服装与身体防护：加入四个穿戴槽、8 件服装、分伤口概率防护、耐久磨损、损坏卸下和服装分类掉落。说明见 `docs/clothing-protection-system-v1.md`。

0.26 物品与战利品：加入 8 种功能物品、分类容器掉落、面包变质、感染治疗和武器胶带维修。说明见 `docs/item-loot-expansion-v1.md`。

0.25 安全屋与睡眠：清空住宅中的僵尸后，可在床边将住宅设为安全屋；睡眠以可见进度推进八小时并可能被危险打断。认领、睡醒、重新进入安全屋和正常退出均会自动保存。说明见 `docs/safehouse-sleep-system-v1.md`。

0.24 门窗攻防：住宅窗户具有关闭、打开、破碎三种状态，玩家可打开并翻越，碎窗翻越存在手脚擦伤风险；两层木板分别记录耐久，可维修、拆除或被僵尸逐层破坏。门具有独立耐久，僵尸会选择玩家所在建筑的门窗入口，破坏后进入室内。门窗、玻璃和每层木板的耐久均进入存档。说明见 `docs/door-window-breach-system-v1.md`。

0.23 产品外壳：正常启动先进入正式主菜单，提供继续游戏、新游戏、三个独立存档槽、覆盖/删除确认、音量、全屏、手机布局设置和操作教程。旧单槽进度自动作为槽位 1 识别。Windows Release 已导出到 `build/windows/AshDistrict.exe` 并通过启动冒烟测试。说明见 `docs/product-shell-v1.md`。

0.22 简单制作与路障：加入旧床单、撕布、木板、钉子和木工锤，完成“搜索材料 → 制作撕布/绷带 → 给住宅窗户加固两层 → 拆除并回收”的循环。桌面端按 `K` 打开制作页，靠近窗户按 `E` 施工；手机端增加“制作”按钮。配方先完整校验再原子结算，工具不消耗，制作页面不暂停世界，路障层数进入存档。说明见 `docs/crafting-barricade-system-v1.md`。

0.21 基础枪械：加入 9mm 手枪、弹匣、散装弹药、瞄准射击、装填计时、射击散布、先命中最近目标、可听枪声和 26 米声音传播。桌面端右键瞄准、左键射击、`R` 装填；手机端继续使用右摇杆按住瞄准、松手射击，并增加“装填”按钮。手枪、弹匣和弹药可从地图容器搜到，弹匣余量、备弹、耐久和地面/容器状态均可保存。说明见 `docs/firearm-system-v1.md`。

0.20 僵尸分布与尸体：首个街块按住宅、商店、道路和公园热区生成 16 只僵尸，其中 4 只藏在室内；尸体留在原地并可搜索，未拿走的物品继续保存在尸体上。活体数量低于 10 后，系统最多从镜头外迁入 4 只。说明见 `docs/zombie-population-system-v1.md`。

0.19 四部位伤病与治疗：僵尸攻击会造成擦伤、撕裂伤或咬伤；绷带处理选中部位，止痛药暂时缓解疼痛，腿伤与手臂伤分别影响移动和攻击，感染会随游戏时间恶化。点击左上状态卡打开治疗页，页面不会暂停僵尸。说明见 `docs/injury-treatment-system-v1.md`。

0.18 体力、疲劳与声音感知：奔跑和攻击消耗体力，休息后恢复；蹲走、步行、奔跑、开门、搜索和挥击产生不同半径的声音，僵尸会前往声源调查。说明见 `docs/exertion-sound-system-v1.md`。

0.17 手机操作：左摇杆移动，右摇杆按住瞄准、松手攻击；底部六格快捷栏切换武器或使用物资。右上齿轮可选择标准、紧凑和左右互换布局，布局自动保存。手机界面不提供暂停按钮。说明见 `docs/mobile-controls-v1.md`。

0.16 本地存档：`F5` 保存、`F9` 读取；玩家、时间、生存状态、背包、装备与武器耐久、地面物品、门、容器和僵尸状态都会恢复。存档采用临时文件写入并保留上一份 `.bak`，主文件损坏时自动回退。说明见 `docs/save-system-v1.md`。

第一块可上线区域的系统差距、完成比例和版本顺序见 `docs/vertical-slice-roadmap-v1.md`。

0.15 武器装备：加入主、副武器装备槽，以及撬棍、棒球棍、厨房刀和手斧。每种武器有独立伤害、攻击距离、挥动时间、击退、重量和耐久；命中消耗耐久，损坏后自动移除，丢弃、拾取和容器转移会保留耐久。按 `Q` 切换主副武器。完整参数见 `docs/equipment-weapon-system-v1.md`。

0.14 生存状态：加入游戏时间、时间倍率、昼夜色调、饱食、水分、流血、渐进伤害、低状态移动限制和死亡重开。

0.13.1 僵尸与近战：四只僵尸会在街区内闲逛、发现玩家后追击、绕开现有阻挡并在攻击前摇结束后造成伤害。玩家鼠标朝向、左键近战，攻击包含距离、正面扇形、视线、单目标、伤害、击退、硬直和死亡判定。

0.6 便利店：包含平屋顶、红黄招牌、独立玻璃门面、停车位、地砖和五个独立搜索容器。玻璃门向外开启，进店时屋顶与前墙隐藏。住宅与商店共享门组件和搜索界面，各自保存容器状态。

0.5 住宅基础：蓝色住宅的独立门扇、前侧入口、白色围栏和院门通道已经接通。WASD 连续移动，E 开关门或搜索，Esc 关闭搜索。门初始关闭；进屋后屋顶隐藏、前墙降低；床、冰箱、橱柜、餐桌和两件柜体分别有占地碰撞与容器内容。拿取更新背包，留下的物品在本次运行中保留。角色仍是占位形象，完整参考图还原尚未完成。

端到端验证：Godot --headless --path . -- --house-test。测试通过实际移动函数依次穿过院门、验证关门阻挡、开门、入屋、搜索、留下/拿取/重开、出屋关门，并检查每个容器可达。可视化验证：Godot --path . -- --flow-capture，生成 build/flow-*-v05.png。

版本 `0.3` 已把蓝色住宅从白盒替换为第一栋可进入建筑。它包含模块化地板、外墙、屋顶、门窗和五件家具；玩家进屋后屋顶淡出、近侧墙降低。冰箱、橱柜、餐桌、床和衣柜在靠近时显示微光轮廓，按 `E` 打开搜索页，可逐项选择“拿取”或“留下”。其余三栋建筑继续保留白盒，供后续逐栋替换。

## 地图结构

- 开放世界总规划已更新到 v4：1024×1024 米、9 个区域、31 条分级道路、180 个可进入建筑地块和 8 块户外保留地。建筑覆盖住宅、商业、医院、学校、警消、市政、交通、工业、农业与基础设施；地图支持地下 2 层至地上 31 层，并为房间、战利品、僵尸、车辆、停车、采集、动物、故事和公用设施预留数据层。当前仍是规划层，尚未替换可玩地图。
- v4 总图：`build/world-master-plan-v4.png`；道路图：`build/road-network-v4.png`；设施表：`build/world-facilities-v4.png`；地块图：`build/world-parcels-v4.png`。
- 机器可读规划：`data/world-master-v4.json` 与 `data/world-parcels-v4.csv`。PZ 对照审查与冻结规则见 `docs/pz-map-gap-audit-v4.md`。v1-v3 规划停止用于新地图制作，仅作历史记录。
- 等距逻辑格：64×32 像素。
- 当前逻辑地图：512×576 格；首个精制可玩街块位于原 96×72 格区域。
- 扩展区块：32×32 格，当前覆盖 3×3 区块。
- 固定层：Ground、Roads、Lots、Buildings、Roofs、Props。
- 四条道路在地图边缘保留出口，后续街区以相邻区块坐标追加。

## 运行与验证

- 编辑器运行：使用 Godot 4.7.2 打开此目录。
- 地表与布局验证：`Godot --headless --path . -- --layout-test`
- 蓝色住宅验证：`Godot --headless --path . -- --house-test`
- 截图验证：`Godot --path . -- --capture`
- 蓝色住宅截图：`Godot --path . -- --house-capture`
- 战斗系统验证：`Godot --headless --path . -- --combat-test`
- 战斗截图：`Godot --path . -- --combat-capture`
- 生存系统验证：`Godot --headless --path . -- --survival-test`
- 生存与死亡页面截图：`Godot --path . -- --survival-capture`
- 武器装备验证：`Godot --headless --path . -- --weapon-test`
- 武器背包截图：`Godot --path . -- --weapon-capture`
- 存档系统验证：`Godot --headless --path . -- --save-test`
- 手机操作验证：`Godot --headless --path . -- --mobile-test`
- 手机界面截图：`Godot --path . -- --mobile-capture`
- 体力与声音验证：`Godot --headless --path . -- --exertion-test`
- 体力与调查截图：`Godot --path . -- --exertion-capture`
- 伤病与治疗验证：`Godot --headless --path . -- --injury-test`
- 健康页面截图：`Godot --path . -- --injury-capture`
- 僵尸分布与尸体验证：`Godot --headless --path . -- --population-test`
- 尸体搜索页面截图：`Godot --path . -- --population-capture`
- 基础枪械验证：`Godot --headless --path . -- --firearm-test`
- 枪械瞄准截图：`Godot --path . -- --firearm-capture`
- 可操作枪械测试场景：`Godot --path . -- --firearm-preview`
- 制作与路障验证：`Godot --headless --path . -- --crafting-test`
- 制作页面截图：`Godot --path . -- --crafting-capture`
- 可操作制作测试场景：`Godot --path . -- --crafting-preview`
- 车辆、燃油与后备箱验证：`Godot --headless --path . -- --vehicle-test`
- 车辆外观与检查页面截图：`Godot --path . -- --vehicle-capture`
- 职业、特质与创建流程验证：`Godot --headless --path . -- --character-test`
- 幸存者创建页面截图：`Godot --path . -- --character-capture`
- 产品外壳验证：`Godot --headless --path . -- --product-test`
- 主菜单、存档槽和设置截图：`Godot --path . -- --product-capture`
- 正常启动菜单预览：`Godot --path . -- --product-preview`
- 门窗攻防验证：`Godot --headless --path . -- --barrier-test`
- 门窗交互页面截图：`Godot --path . -- --barrier-capture`
- 安全屋、睡眠与自动存档验证：`Godot --headless --path . -- --safehouse-test`
- 睡眠页面截图：`Godot --path . -- --safehouse-capture`

## 0.4 住宅返工

统一比例基准：逻辑格约 0.5 米，住宅 6.5×5 米；墙高约 2.6 米，人物约 1.7 米，门高约 2.1 米。家具按透明度有效边界切片，分别设定床、冰箱、柜体和餐桌尺度，碰撞按占地矩形处理。
屋顶改为双坡结构，补充山墙、屋脊、檐口；五扇窗户增加窗框、分格和窗台。室内背墙改为浅色墙面，近侧墙与窗户同步隐藏。
实机截图位于 build/blue-house-exterior-v04.png、build/blue-house-interior-v04.png。
当前仍是住宅返工预览：人物为比例占位形象，其余三栋建筑尚未完成。

便利店往返验证：Godot --headless --path . -- --store-test。可视化往返演示：Godot --path . -- --store-capture，依次产生 build/store-01-exterior-v06.png、02-interior、03-search、04-home。测试初始位置设置后，全程通过角色移动函数行走，没有场景切换或传送。
