# 智能仓储举升式AGV小车的设计与控制研究

> **学士学位论文** | 齐鲁工业大学 机械工程学院 | 2026年

## 项目概述

本项目针对中小型仓库自动化搬运需求，设计了一款智能仓储移动机器人（AGV），涵盖总体方案、机械结构、电气系统、运动学建模、路径规划与PID运动控制仿真验证。系统以双轮差速驱动为核心，搭载剪叉式垂直升降机构，实现货物在不同高度货架间的自主搬运。

- **总体方案设计** — 需求分析、技术指标制定、差速驱动选型、系统架构规划
- **机械结构设计** — 剪叉式升降机构、移动底盘、驱动轮，关键部件强度校核与稳定性分析
- **电气系统设计** — STM32F103C8T6 主控、交流伺服电机、红外/超声波传感器、控制电路
- **运动学建模** — 差速驱动底盘运动学方程，四种典型轨迹 MATLAB 仿真
- **PID 控制** — 双闭环 PID（外环位姿 + 内环轮速），积分分离与抗积分饱和

---

## 目录结构

```text
.
├── lunwen/                          # LaTeX 论文源码
│   └── QLULatex/QLUThesisLatexTemplate-master/Thesis/
│       ├── main.tex                 # 主文件
│       ├── pages/
│       │   ├── abstract.tex         # 中英文摘要
│       │   ├── body.tex             # 正文
│       │   ├── aop.tex              # 原创性声明
│       │   └── tail.tex             # 附录与致谢
│       ├── setup/                   # 封面、格式、宏包
│       └── static/
│           ├── figures/             # 论文插图与照片
│           └── code/                # MATLAB 代码
│
├── fangzhen/                        # MATLAB / Simulink 仿真
│   └── matlab/
│       ├── build_diffdrive_pid_model.m
│       ├── diff_drive_robot_pid_system.slx
│       └── ...
│
├── free/                            # 补充材料与仿真相关文件
│   ├── diff_drive_robot_pid_system.slx
│   ├── slprj/
│   └── ...
│
├── word/                            # Word 文档
├── 答辩PPT/                         # 毕业答辩 PPT
│   └── 答辩PPT.pptx
│
└── .gitignore
```

---

## 关键设计参数

| 参数 | 数值 |
| ---- | ---- |
| 额定载重 | 50 kg |
| 升降行程 | ≥452 mm |
| 最大速度 | 30 m/min |
| 整车自重 | ≈200 kg |
| 驱动方式 | 双轮差速 |
| 升降机构 | 单层剪叉式（臂长 600 mm） |
| 主控制器 | STM32F103C8T6（ARM Cortex-M3, 72 MHz） |
| 驱动电机 | SMC80S-0040-30AoK-3DKH 交流伺服电机（400W） |
| 减速器 | ZJPX115 行星减速器（速比 40:1） |
| 传感器 | TCRT5000 红外 ×5, HC-SR04 超声波, 2500 P/R 编码器 |
| 路径规划 | Hybrid A* |
| 控制算法 | 双闭环 PID（外环位姿 + 内环轮速） |

---

## 快速开始

### 编译论文

```bash
cd lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis
xelatex main.tex
bibtex main
xelatex main.tex
xelatex main.tex
```

### 运行 MATLAB 仿真

```matlab
cd fangzhen/matlab
build_diffdrive_pid_model
```

---

## 技术栈

| 工具 | 用途 |
| ---- | ---- |
| MATLAB R2025a / Simulink | 运动学建模、PID 控制器仿真 |
| XeLaTeX (TeX Live 2026) | 论文排版 |
| STM32CubeMX | 单片机外设配置（硬件方案） |
| SolidWorks | 三维机械建模 |

---

## 参考资料

- 论文模板：[QLUThesisLatexTemplate](https://github.com/xlywy/QLUThesisLatexTemplate)（MIT License）
