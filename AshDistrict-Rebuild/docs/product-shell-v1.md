# 产品化外壳 v1

0.23 为现有可玩街块增加正式启动入口。游戏正常启动时先显示主菜单，世界保持暂停；自动化测试和专项预览参数继续直接进入目标场景。

## 页面

- 主菜单：继续最近存档、新游戏、存档槽、设置、操作教程和退出游戏。
- 三个本地槽位：分别保存角色、时间、背包、武器、容器、门、路障、僵尸和尸体状态。槽位显示游戏天数、时间、生命和保存日期。
- 覆盖与删除：都有游戏内二次确认；删除会同时清理主文件、备份和未提交的临时文件。
- 设置：主音量、音效音量、全屏显示和三套手机按钮布局。设置写入独立的 `user://ash_district_settings.cfg`，不随某个存档切换。
- 教程：覆盖移动、潜行、战斗、搜索、背包、制作、封窗和保存操作。

菜单使用锚点和容器布局，按 1280×720 参考画布适配额外宽高；按钮支持鼠标、键盘和手柄焦点。当前页面以栈管理，子页面按 Esc 返回上一级。

## 存档规则

槽位路径为 `user://ash_district_slot_1.json` 至 `slot_3.json`。旧版单槽存档原本就在槽位 1 路径，因此可直接在“继续游戏”中识别。每次保存继续采用临时文件提交和 `.bak` 上一版本备份；三个槽位互不覆盖。

## 导出

项目根目录包含 `export_presets.cfg`。Windows Release 输出到 `build/windows/AshDistrict.exe`，嵌入 PCK，并显式包含运行时读取的 JSON/CSV 数据。当前构建已成功导出并用 `--product-test` 完成启动冒烟验证。

Android 正式包仍需要安装与 Godot 4.7.2 对应的 Android 模板、JDK/SDK、包名和签名密钥。本版保留手机安全区、虚拟摇杆与按钮布局，但不把未签名、未真机测试的 APK 计为完成。

## 验证

- 外壳验证：`Godot --headless --path . -- --product-test`
- 页面截图：`Godot --path . -- --product-capture`
- 菜单试玩：`Godot --path . -- --product-preview`
- Windows 导出：`Godot --headless --path . --export-release "Windows Desktop" build/windows/AshDistrict.exe`
