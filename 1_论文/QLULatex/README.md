# 智能仓储举升式AGV小车的设计与控制研究

> **学位论文工作档案** | 齐鲁工业大学 计算机科学与技术学院 | 2026年4月

## 📋 项目概述

本项目完整记录了举升式AGV小车的设计全过程，包括：
- ✅ **总体方案设计** - 差速驱动底盘结构设计
- ✅ **机械结构设计** - 载物装置、行走装置、升降机构
- ✅ **电气系统设计** - STM32F103主控、电机驱动、传感器集成
- ✅ **运动学建模** - 差速驱动运动学模型推导和验证
- ✅ **控制算法** - PID控制器设计和扰动条件下的性能验证
- ✅ **仿真验证** - MATLAB/Simulink仿真分析

---

## 📁 目录结构

### `1_论文/` 📖
**论文源代码和最终文稿**
```
1_论文/
└── QLULatex/
    ├── Thesis/
    │   ├── main.tex              主文件
    │   ├── pages/
    │   │   ├── abstract.tex      摘要（中英文）
    │   │   ├── body.tex          论文正文（6章）
    │   │   ├── acknowledgements  致谢
    │   │   └── paperInChinese    中文论文刊物
    │   ├── setup/
    │   │   ├── cover.tex         封面和扉页
    │   │   ├── format.tex        论文格式设置
    │   │   └── package.tex       宏包定义
    │   └── static/
    │       ├── figures/          论文所有图片
    │       ├── references/       参考文献数据库
    │       └── code/             代码示例
    └── backup/                   备份文件和脚本
```

**论文章节内容：**
1. **第一章 - 引言** 研究背景、意义、国内外现状综述
2. **第二章 - AGV总体设计方案** 需求分析、技术指标、结构方案
3. **第三章 - 机械结构设计** 底盘、驱动轮、升降机构、强度校核
4. **第四章 - 电气系统设计** 主控系统、驱动模块、传感器接口
5. **第五章 - 运动学建模与仿真** 模型推导、MATLAB仿真、轨迹验证
6. **第六章 - PID控制设计与验证** 控制器设计、参数整定、扰动分析

---

### `2_仿真与代码/` 💻
**所有工程代码和仿真模型**
```
2_仿真与代码/
├── matlab/                              MATLAB仿真工程
│   └── 差速/
│       ├── diff_drive_robot_pid_system.slx    Simulink完整模型
│       ├── diff_drive_robot_pid_system.slxc   编译版本
│       ├── build_diffdrive_pid_model.m        模型构建脚本
│       ├── 差速双轮机器人轨迹图.png           仿真结果截图
│       └── slprj/                             仿真工程数据
│
├── untitled.slx                         Simulink临时模型1
└── untitled1.slx                        Simulink临时模型2
```

**MATLAB仿真主要内容：**
- 差速驱动底盘运动学模型建立
- 四种标准轨迹验证（直线、圆弧、S形、8字形）
- PID控制器设计和参数整定
- 无扰动和有扰动条件下的跟踪性能分析

**运行MATLAB仿真：**
```matlab
cd matlab/差速
build_diffdrive_pid_model.m
```

---

### `3_输出文件/` 📤
**仿真动画和可视化输出**
```
3_输出文件/
└── animation_output/                输出动画和可视化
    └── 四轨迹同步动画.gif            四种轨迹仿真动画
```

---

### `4_文档与指南/` 📚
**参考文档和使用指南**
```
4_文档与指南/
└── README.md                    本文件（项目说明）
```

---

## 🚀 快速开始

### 我需要编辑或重新编译论文
```
进入：1_论文/QLULatex/QLUThesisLatexTemplate-master/Thesis/
编辑：main.tex 或各章节 .tex 文件
编译：使用 XeLaTeX 编译器
```

### 我需要修改或重新运行MATLAB仿真
```
进入：2_仿真与代码/matlab/差速/
打开：diff_drive_robot_pid_system.slx（Simulink）
或运行：build_diffdrive_pid_model.m（生成模型）
```

---

## 🛠️ 技术栈

### 硬件设计工具
| 工具 | 用途 | 版本 |
|------|------|------|
| SolidWorks/Fusion 360 | 3D建模与装配 | 最新版 |
| FEA仿真 | 强度校核与有限元分析 | - |

### 软件开发环境
| 工具 | 用途 | 版本 |
|------|------|------|
| MATLAB/Simulink | 运动学建模、PID设计、仿真 | R2023a+ |
| LaTeX | 论文排版 | TeX Live 2023 |
| STM32CubeMX | 单片机配置 | 最新版 |

### MATLAB工具箱
```
  • Control System Toolbox    - 控制系统设计
  • Simulink                  - 仿真建模
  • Optimization Toolbox      - 参数优化
```

---

## 📊 项目统计

| 类别 | 内容 | 数量 |
|------|------|------|
| **论文内容** | 章节 | 6 |
| | 总字数 | 50,000+ |
| | 插图 | 30+ |
| | 参考文献 | 50+ |
| **仿真模型** | Simulink模块 | 20+ |
| | 仿真轨迹 | 4种 |
| | 控制器参数 | 6个 |

---

## 📝 关键数据与指标

### AGV设计指标
```
尺寸：1m × 1m × 1m （空间利用率高）
载重：25kg （轻型物料）
升降：0.5m 行程
速度：可调（仿真中±1m/s）
```

### 控制性能指标
```
直线运动：±1% 误差
圆弧转向：±1° 精度
响应时间：<0.5s（无扰动）
抗干扰：±5%（有扰动）
```

---

## ⚙️ 常用命令速查

### 论文编译
```bash
cd 1_论文/QLULatex/QLUThesisLatexTemplate-master/Thesis
xelatex main.tex
bibtex main
xelatex main.tex
xelatex main.tex
```

### MATLAB运行
```matlab
% 打开Simulink模型
open('diff_drive_robot_pid_system.slx')

% 或运行构建脚本
run('build_diffdrive_pid_model.m')
```

---

## 📅 项目时间表

| 阶段 | 内容 | 完成度 |
|------|------|--------|
| **设计阶段** | 总体方案、机械结构、电气系统 | ✅ 100% |
| **建模阶段** | 运动学建模、动力学分析 | ✅ 100% |
| **仿真阶段** | MATLAB仿真、PID控制验证 | ✅ 100% |
| **论文撰写** | 六章论文内容 | ✅ 100% |

---

## 📞 论文信息

- **论文题目**：智能仓储举升式AGV小车的设计与控制研究
- **学位类型**：学士学位
- **学位授予单位**：齐鲁工业大学
- **学院**：计算机科学与技术学院
- **研究方向**：机器人控制、智能物流
- **完成日期**：2026年4月

---

## 🎓 致谢

感谢以下技术和工具的支持：
- LaTeX排版系统 - 论文排版
- MATLAB/Simulink - 仿真建模与验证
- GitHub - 论文模板和版本控制

---

## 📄 许可证与参考

- **论文模板**：[QLUThesisLatexTemplate](https://github.com/xlywy/QLUThesisLatexTemplate) - MIT License
- **本项目**：学位论文研究成果，仅供参考

