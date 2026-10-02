# 文字对齐到线（Revit 2020）—— 使用与安装说明

把文字注释（TextNote）贴到参考线上。两个按钮对应两种操作方式，按场景挑。

---

## 目录

1. [功能简介](#1-功能简介)
2. [安装](#2-安装)
3. [操作流程（Batch 批量方式）](#3-操作流程batch-批量方式)
4. [操作流程（Click 点选方式）](#4-操作流程click-点选方式)
5. [行为规则](#5-行为规则)
6. [提示信息含义](#6-提示信息含义)
7. [常见问题排查](#7-常见问题排查)
8. [卸载](#8-卸载)

---

## 1. 功能简介

把文字注释沿法向投影到参考线上（即：文字垂直落到线上）。

- **文字位置**取自 `TextElement.Coord`
- **文字角度**保持不变（不跟随线旋转）
- **视图专用文字**只在当前视图内移动

提供两种操作方式，**是并列的两个功能，不是替代关系**：

| 按钮 | 适用场景 | 特点 |
|---|---|---|
| **Align Text (Batch)** | 一批文字对几条线，一次搞定 | 一次混合多选，按 `Enter` 一起对齐 |
| **Align Text (Click)** | 长作业、边看边调、要频繁换线 | 点一下走一个，**没有"完成"按钮要按** |

![Ribbon 面板：Align 面板下的两个按钮](images/ribbon-panel.png)

**图 1-1**：Ribbon 上的 `Align` 面板，左侧 `Align Text (Batch)`、
右侧 `Align Text (Click)`。

---

## 2. 安装

### 2.1 前置条件

- Revit **2020**（其他版本未验证）
- Windows 64 位

### 2.2 安装步骤

1. **完全退出 Revit。**

   > 必须在任务管理器里确认没有 `Revit.exe` 残留进程 —— Revit 只在
   > **启动时**扫描插件目录，只关文档不算退出。

2. **复制两个文件到插件目录：**

   ```
   源目录（下载得到的）：  RevitTextAlignment.dll
                          RevitTextAlignment.addin
   目标目录：             %APPDATA%\Autodesk\Revit\Addins\2020\
   ```

   `C:\Users\<你的用户名>\AppData\Roaming\Autodesk\Revit\Addins\2020\`

   > **两个文件必须在同一目录。** `.addin` 里写的是相对路径
   > `<Assembly>RevitTextAlignment.dll</Assembly>`，分开放会导致加载失败。
   >
   > **不要**把 `RevitAPI.dll` / `RevitAPIUI.dll` 一起复制进去。它们由
   > Revit 宿主提供，放错了反而会因版本不匹配导致加载失败。

3. **启动 Revit。**

4. **确认 Ribbon 出现 `Text Tools` 页签**，里面有两个按钮。

![安装完成后的 Ribbon 面板](images/ribbon-panel.png)

**图 2-1**：安装成功后的 Ribbon。看到这个面板即表示加载成功。

### 2.3 安装失败怎么办

如果**没有** `Text Tools` 页签，按下面顺序查：

| 检查项 | 怎么做 | 期望结果 |
|---|---|---|
| 文件位置对不对 | 见第 2.2 步 | 两个文件在同一目录 |
| Revit 真的退出了吗 | 任务管理器看 `Revit.exe` | 没有残留进程 |
| 启动错误日志 | 见[第 7 章](#7-常见问题排查) | 日志内容即原因 |

---

## 3. 操作流程（Batch 批量方式）

**场景**：一批文字对齐到几条线，一次完成。

### 3.1 操作步骤

1. **点击 `Align Text (Batch)`**
   光标进入拾取状态，状态栏显示提示。

2. **混合多选**：依次点击参考线和所有文字。
   - 可以按住 `Ctrl` 加选
   - 顺序无所谓，插件会自动区分线与文字

3. **按 `Enter`**（或点击状态栏的 `Done`）
   所有选中的文字**同时**对齐。

4. **自动回到拾取状态**，可继续下一批。重复第 2 步。

5. **按 `Esc`** 结束。

### 3.2 效果

对齐前 —— 两条竖直参考线，四个文字注释都在线的右侧：

![Batch 对齐前：4 个文字在参考线右侧](images/batch-picking.png)

**图 3-1**：对齐前状态。

按 `Enter` 之后 —— TextNote1、TextNote2 贴到上面那条线，
TextNote3、TextNote4 贴到下面那条线：

![Batch 对齐后：文字已贴到各自的线上](images/batch-result.png)

**图 3-2**：对齐结果。**多线场景下每个文字绑定到离它最近的那条线**，
所以四条文字分两组落在两条不同的线上。

---

## 4. 操作流程（Click 点选方式）

**场景**：边看边调、频繁换线、想知道每个文字具体发生了什么。

### 4.1 操作步骤

1. **点击 `Align Text (Click)`**

2. **点击一条参考线**（详图线）
   点一下立即确定，**不需要按"完成"**。

3. **点击文字**，它**立刻**对齐到线上。
   再点下一个，继续。

4. **想换线？直接点另一条线**
   立即切换参考线，**此后点击的文字都对齐到新线**。
   不需要按 `Esc` 退回上一步。

5. **`Esc`** 的两种含义：
   - 正在选文字时按 → 结束本轮，回到第 2 步（可换一条线继续）
   - 正在选线时按 → 彻底退出命令

### 4.2 效果

![Click 模式逐个对齐结果](images/click-result.png)

**图 4-2**：Click 模式的对齐结果 —— 逐个点文字，每个点完立即落到线上。

---

## 5. 行为规则

**没有设置项**，行为固定：

| 情况 | 行为 |
|---|---|
| 选的是**直线** | 按**无限长直线**处理 —— 图纸上那条短短的线通常是方向参考，不是有限边界 |
| 选的是圆弧等其他曲线 | 按有界曲线处理，文字落在投影点上 |
| 垂足落在曲线范围**外** | 贴到该线离它最近的点（端点）—— 选了线就是要贴上去，不会跳过 |
| 文字**已在**目标位置 | 不动（阈值 0.1mm，避免抖动） |
| 选到**墙 / 楼板 / 屋面** | **不接受**。只能用详图线（DetailLine） |
| 文字角度 | **不改变**，保持原样 |

---

## 6. 提示信息含义

### 6.1 成功时 —— 不提示

文字动了，**看效果就知道**。这是刻意的设计：成功提示是噪音。

### 6.2 失败时 —— 必提示

一个文字都没动时，屏幕下方会出现提示条（深红色，2.8 秒后自动消失，不抢焦点）。

| 提示 | 含义与处理 |
|---|---|
| `No reference line picked. Pick a model line or a detail line.` | 没选到线。点一条**详图线**，不要点墙 |
| `Picked N text note(s) but no reference line.` | 选到文字但没选到线。补选一条线 |
| `No text note picked. Pick the text you want aligned.` | 只选了线没选文字 |
| `Text 2584: Coord unavailable and get_BoundingBox returned null...` | 该文字取不到坐标。多见于文字处于特殊状态（被锁定 / 在组内 / 跨视图） |
| `Text 2584: cannot be projected onto any line (N candidate(s), position ...)` | 投影失败。日志里有具体坐标，可据此判断线选得对不对 |
| `None of the N text notes could be moved. They may be pinned or restricted by worksets.` | 文字被**固定（Pin）**或受**工作集**限制 |

> 提示条**不夺焦点**，点击会穿透到 Revit，不会打断拾取。
>
> 提示条显示的是英文原文（`model line or a detail line`）。
> 上表最后一列已简化成"详图线"，两者指同一种可用的参考线。

---

## 7. 常见问题排查

### 7.1 日志位置

| 日志 | 路径 | 作用 |
|---|---|---|
| **运行日志** | `%LOCALAPPDATA%\RevitTextAlignment\align.log` | 每次操作记录选了什么、怎么绑的、为什么跳过 |
| **启动错误** | `%LOCALAPPDATA%\RevitTextAlignment.State\startup_error.log` | 只在启动异常时产生 |

> 这两个是**不同的目录**（一个有 `.State` 后缀）。排查时**都要看** ——
> 只看其中一个容易得出错误结论。

### 7.2 启动失败日志的判读

| 日志状态 | 含义 |
|---|---|
| **有内容** | `OnStartup` 执行了但抛异常，内容就是原因 |
| **空 / 不存在** | 加载阶段就被拒，`OnStartup` 压根没被调用 → 查签名、位数、`.addin` 路径 |

### 7.3 排障流程

**第一步：看运行日志。** 它会明确写出每一步：

```
第 1 轮: 线 1 / [逐个选文字] 视图=标高 1 法向=(0,0,1) 单线无限=True
    线[0] Line (3.086,5.823,0) -> (10.738,14.029,0) 长 3420 mm [按无限长处理]
  文字 2584: plans=1 / unbound=0 / clampedToEndpoint=0
  移动 1
```

看到 `plans=0 / unbound=1` 就说明那一步失败了，`unbound` 后面的明细会写明具体原因。

**第二步：跑诊断脚本。** 把 `diagnose.ps1` 和插件文件放同一目录：

```powershell
powershell -ExecutionPolicy Bypass -File .\diagnose.ps1
```

输出 `diagnose_out.txt`，涵盖文件指纹、位数、`.addin` 解析、
journal 加载记录、签名状态等。

**第三步：提供截图。** 装了 **Snoop Objects**（免费 Revit 插件）的话，
选中一个文字注释就能看到全部字段和值 —— 比日志还直接。

> **反馈问题时请附上 `align.log`。** 没有它只能靠猜。

---

## 8. 卸载

1. 完全退出 Revit
2. 删除 `%APPDATA%\Autodesk\Revit\Addins\2020\` 下的两个文件
3. 删除日志目录（可选）：
   ```
   %LOCALAPPDATA%\RevitTextAlignment\
   %LOCALAPPDATA%\RevitTextAlignment.State\
   ```
   > 授权状态记录在 `.State` 目录里。删掉它等于回到"无记录"状态。
