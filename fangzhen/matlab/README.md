# 答辩演示程序清单

> 双击 MATLAB 打开此文件夹，输入 `run_all` 即可一键运行全部仿真。

## 📂 文件说明

| 文件 | 功能 | 运行方式 |
|------|------|----------|
| `run_all.m` | **一键运行全部仿真**（推荐） | `run_all` |
| `traj_sim.m` | 四种典型轨迹运动学仿真（直线/圆/S形/8字） | `traj_sim` |
| `pid_control.m` | 双环PID控制仿真（阶跃/定点/直线/圆形跟踪） | `pid_control` |
| `hybrid_astar.m` | Hybrid A* 路径规划 | `hybrid_astar` |
| `tracking_pid.m` | 红外传感器PID循迹仿真 | `tracking_pid` |
| `lift_strength_mechanism_diagram.m` | 剪叉机构强度校核与运动简图（合并版） | `lift_strength_mechanism_diagram` |
| `scissor_lift_fea.m` | 剪叉机构有限元分析（FEA数值验证） | `scissor_lift_fea` |
| `cascaded_pid_diagram.m` | 级联双闭环PID控制系统结构框图 | `cascaded_pid_diagram` |
| `build_simulink_model.m` | 构建级联PID Simulink模型 | `build_simulink_model` |
| `cascaded_pid_agv.slx` | Simulink模型文件（由 build_simulink_model 生成） | 双击打开 |

## 🎯 答辩演示流程

1. **`run_all`** → 一键展示全部仿真结果（控制台输出 + 自动保存图片到 `figures/`）
2. **单独展示**：评委提问时，可单独运行对应 .m 文件深入讲解
3. **Simulink**：运行 `build_simulink_model` 或在 MATLAB 中打开 `cascaded_pid_agv.slx`

## ⚙️ 关键参数（与论文一致）

| 参数 | 数值 | 
|------|------|
| 车轮半径 r | 0.09 m（直径 180 mm） |
| 轮距 L | 0.52 m（520 mm） |
| 万向轮数量 | 4 个 |
| 位姿环 PID | Kp=3.0, Ki=0.2, Kd=0.4 |
| 轮速环 PI | Kp=17.0, Ki=103.0 |
| 额定载重 | 50 kg |
| 最高车速 | 0.5 m/s（30 m/min） |
