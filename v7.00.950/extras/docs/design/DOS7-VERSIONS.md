# DOS 7.x 启动软盘版本与复建队列

目录更新：用户已要求将现有 v7.0 原地改名为 v7.00.950，现已完成。下文“暂保留原目录”等表述记录调查当时状态，现由此更新取代。源码和目标配置未随重命名改变。

最新基线：用户随后指定 O:/assets/w9xbd。见 [五份指定启动盘复核](W9XBD-BASELINE.md)。下文 E: 样本是第一轮历史对照；后续正式目标优先采用新指定介质，具体路径和哈希以新证据为准。

本轮范围：用户 E:/core/collection 中的启动软盘，以及封装启动软盘的 ISO。安装光盘不是本轮目标；不从其代替启动盘定版。用户指定按 DOS 主次版本和构建号命名。当前 v7.0 暂保留原目录，已知目标对应 v7.00.950 候选；本轮不搬迁已验收源码。

## 命名和身份

正式命名：v7.00.950、v7.10.1111、v7.10.1998、v7.10.2222、v8.00.3000。950A/B/C 是 Windows 发行标签，不作为 DOS 数字构建号。OSR2.1/2.5 的 1212/1214 等 Windows 组件号不能直接填成 DOS 构建号。同构建号的语言、官方补丁、介质和启动配置分别记入 extras 变体清单；目录名字不是目标身份的全部。

当前 v7.0 三产物等于 msdosw95a_boot.img；COMMAND 包含 4.00.950，两个可执行文件时间戳为 1995-07-11。但文件名 95a 不证明 OSR1，时间戳也不证明最早原版。此前与本地安装光盘比较仅是辅助佐证，不能替代启动盘来源核验。

## 按发行年代排列

| 年份 | Windows 发行 | DOS 版本系列 | 构建目录 | 处置 |
| --- | --- | --- | --- | --- |
| 1995 | Windows 95 初版，零售/OEM | 7.00 | v7.00.950 | T13，核验最早正式 950 与现有目标关系 |
| 1995 年末–1996 | Windows 95 SP1 / OSR1，950A | 7.00 | v7.00.950 内登记变体 | T14，两种发行分别核对，不预设更换核心 |
| 1996 | Windows 95 OSR2，950B | 7.10 | v7.10.1111 | T15，95B 启动盘候选已提取 |
| 1997 | Windows 95 OSR2.1，950B | 7.10 | 以核心实测构建号归档 | T16，USB 补充不是独立 DOS 版本证明 |
| 1997 | Windows 95 OSR2.5，950C | 7.10 | 以核心实测构建号归档 | T17，Windows 新组件不等于 DOS 全部改变 |
| 1998 | Windows 98 FE，4.10.1998 | 7.10 | v7.10.1998 | T18，本地发现两组不同可执行核心 |
| 1999 | Windows 98 SE，4.10.2222 | 7.10 | v7.10.2222 | T19，FE/SE 核心确实不同 |
| 2000 | Windows Me，4.90.3000 | 8.00 | v8.00.3000 | 命名预留；不把本次 7.x 请求扩大为 Me 复建 |

年份为发行家族排序，不将 FAT 时间戳当发行日。FE 的微软公开上市公告为 1998-06-25；SE 的公开上市公告为 1999-06-10，与 RTM 日期须区分。

## 本地实测

所有下表路径前缀为 E:/core/collection/systems/x86_16_dos/msdos_7xx/。大小单位为字节。

| 启动 IMG | COMMAND 版本字符串 | IO.SYS | COMMAND.COM | MSDOS.SYS | 结论 |
| --- | --- | ---: | ---: | ---: | --- |
| msdosw95a_boot.img | 4.00.950 | 223148 | 92870 | 6 | 与现有 v7.0 三文件一致；不是已证明 OSR1 |
| msdosw95b_boot.img | 4.00.1111 | 214836 | 93812 | 6 | OSR2 家族候选；COMMAND 另含 4.10.1053 字样，不能取任意数字串当运行版本 |
| msdosw98_boot.img | 4.10.1998 | 224150 | 94282 | 9 | 与下一行不同，语言/修订来源待核验 |
| msdosw98_boot_allbootdisks.img | 4.10.1998 | 222390 | 93880 | 9 | FE 参考候选 |
| msdosw98_boot_noram_allbootdisks.img | 4.10.2222 | 222390 | 93890 | 6 | 可执行核心等于 SE 候选；名字不能按 FE 解释 |
| msdosw98se_boot_allbootdisks.img | 4.10.2222 | 222390 | 93890 | 9 | SE 参考候选 |
| msdosw98se_boot_noram_allbootdisks.img | 4.10.1998 | 222390 | 93880 | 6 | 可执行核心等于 FE 候选；名字不能按 SE 解释 |

6 个启动 ISO 的 El Torito 软盘在 51200 字节处、长 1474560 字节；其三核心分别与对应 IMG（98 的普通 ISO 对应 allbootdisks IMG）完全一致。共 13 个介质样本、5 组可执行核心对、7 组三文件组合。MSDOS.SYS 的 6 字节为 ;SYS 加 CRLF，9 字节为 ;W98EBD 加 CRLF；这是启动配置变体，不是新的内核实现。

完整输入和产物哈希、大小、簇链检查在 [启动盘证据](../etc/boot-version-survey.json)。已验证两份 FAT 一致、文件簇链无循环且长度闭合。没有启动虚拟机、没有重新构建 DOS。

## MTSP 任务

- **T13 — 最早 4.00.950 与现有 7.0 身份核验**（active）：S1 启动软盘基线；S2 确认早期正式版及必要源码差异；S3 精确验收。目录：v7.00.950。
- **T14 — Windows 95 SP1 / OSR1**（planned）：分别核对 SP1、OSR1；仅为实证差异恢复源码，相同核心记录复用。目录：v7.00.950。
- **T15 — Windows 95 OSR2**（planned）：以已核验 v7.00.950 为基线，先二进制功能块差异与依赖，再恢复 7.10。目录：v7.10.1111。
- **T16 — Windows 95 OSR2.1**（planned）：对 OSR2 三文件逐个核对；USB 更新不自动视作 DOS 更新。目录：v7.10.1111 (以实测为准)。
- **T17 — Windows 95 OSR2.5**（planned）：对 OSR2/2.1 核对；相同复用，不创建仅改标签的第二实现。目录：v7.10.1111 (以实测为准)。
- **T18 — Windows 98 FE**（planned）：先澄清两组 1998 核心的语言/修订差异；以最近已验收 7.10 源码恢复。目录：v7.10.1998。
- **T19 — Windows 98 SE**（planned）：以 FE 为基线，按有依据代码块映射恢复差异；配置文本变体单列。目录：v7.10.2222。

唯一活动包为 M6 T13 S1。其余任务已登记 planned，按年份顺序推进；不同时展开几个源码分支。各复建 T 使用 S1 冻结目标/二进制差异和依赖图、S2 按拓扑顺序逐文件恢复、S3 三产物精确验证和独立收口。T13 的早期身份核验是后续选基线的前置条件。

完全相同核心直接引用验收证据；只有资源/配置不同的单列处理；真正执行代码差异再映射到源文件。禁止按绝对文件偏移粗算源码恢复率，采用有证据的代码块对齐。源码目录遵循 DOS6，全量源代码优先；不复制完整源码制造重复实现。构建入口 extras/build.cmd，CMD/BAT/C 工具，输出 extras/assets，build 和目标二进制忽略。保持三产物全长字节一致；指令未变不重编。每次报告已处理文件中修改/未改数量、精确目标匹配和未决项。

## 未决项和边界

- 目前只为 95A/95B/98/98SE 标签的上述启动盘建立了内容证据；OSR1、OSR2.1、OSR2.5 尚未从启动盘内容获得明确归属。不能据文件名说没有，也不能凭发行名虚构三个不同核心。
- msdos710_en_boot.zip 内有 MSDOS71B.IMG；中文 CDU 启动包也在收藏中。这些独立 7.1 分发包需先核查来源和改动，不能自动视为微软原版。
- 当前 v7.0 是否就是最早未更新正式 950，仍需来源证据；已完成的字节重建验收不受身份命名待核验影响。
- 收藏中还有 Chicago/Nashville/Memphis 预发行材料。本轮先处理用户列出的正式发行家族；预发行不冒充最早正式 950。
- 官方后续更新也可能改 IO.SYS 而不改变 DOS 主次版本，例如 Q185301、Q311561。登记为待梳理补丁线，待得到启动盘内对应文件或可追溯官方更新才增加复建变体；不把非官方补丁合并进原版目标。

## 文献

- [微软 Q148761：OSR1 与 SP1 的关系](https://jeffpar.github.io/kbarchive/kb/148/Q148761/)
- [微软 Q253756：95 发行标识与组件版本并不统一](https://jeffpar.github.io/kbarchive/kb/253/Q253756/)
- [微软 Q181661：OSR2.1/2.5 USB 补充文件表](https://jeffpar.github.io/kbarchive/kb/181/Q181661/)
- [微软 Q178972：OSR2.5 内容](https://jeffpar.github.io/kbarchive/kb/178/Q178972/)
- [微软 Q178151：零售版/OSR1 与 OSR2 DOS 的区别](https://jeffpar.github.io/kbarchive/kb/178/Q178151/)
- [微软 Windows 98 上市公告](https://news.microsoft.com/source/1998/06/25/microsoft-announces-immediate-availability-of-windows-98-in-more-than-40-countries/)
- [微软 Windows 98 SE 上市公告](https://news.microsoft.com/source/1999/06/10/microsoft-announces-immediate-availability-of-windows-98-second-edition/)
- [微软 Q185301：IO.SYS 更新](https://jeffpar.github.io/kbarchive/kb/185/Q185301/)
- [微软 Q311561：98/SE 的 IO.SYS 后续更新](https://ftp.zx.net.nz/pub/Patches/ftp.microsoft.com/MISC/KB/en-us/311/561.HTM)

