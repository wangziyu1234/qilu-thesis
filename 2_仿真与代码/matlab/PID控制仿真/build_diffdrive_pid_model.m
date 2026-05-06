%% build_diffdrive_pid_model.m
% 构建双轮差速PID控制Simulink模型
% 模型包含两大部分：
%   第一部分 - 轮式差速机器人（轮子模块、旋转模块、分速度模块、感应器模块）
%   第二部分 - PID控制模块（PID控制器、XY控制器、角度控制器）

clear; clc;

%% 模型名称
model_name = 'diff_drive_robot_pid_system';

% 关闭已存在的模型
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end

% 创建新模型
new_system(model_name);
open_system(model_name);

%% 机器人物理参数（通过模型工作区传递）
r  = 0.075;    % 轮半径 (m)
L  = 0.52;     % 轮距 (m)
mw = 2.5;      % 单轮等效质量 (kg), 总质量 m=5kg 的一半

% 将参数写入模型工作区
ws = get_param(model_name, 'ModelWorkspace');
ws.assignin('r', r);
ws.assignin('L', L);
ws.assignin('mw', mw);

%% ========================================================================
%  第一部分：轮式差速机器人子系统
%  ========================================================================
robot_name = [model_name '/Differential Drive Robot'];

% 创建子系统，设置稍大的尺寸
add_block('simulink/Ports & Subsystems/Subsystem', robot_name);
set_param(robot_name, 'Position', [450, 80, 680, 420]);
set_param(robot_name, 'BackgroundColor', 'lightBlue');

% 获取子系统内部端口句柄，方便后续连线
robot_inports  = find_system(robot_name, 'SearchDepth', 1, 'BlockType', 'Inport');
robot_outports = find_system(robot_name, 'SearchDepth', 1, 'BlockType', 'Outport');

% 子系统的默认 In1 → 重命名为 F_L（左轮力）
in1 = robot_inports(1);
set_param(in1, 'Position', [50, 53, 80, 67]);
set_param(in1, 'Name', 'F_L');

% 添加第二个 Inport 用于右轮力
add_block('simulink/Commonly Used Blocks/In1', [robot_name '/F_R']);
set_param([robot_name '/F_R'], 'Position', [50, 153, 80, 167]);

% --- 轮子模块（左轮） ---
% 力→加速度→速度: v_L = ∫ (F_L / mw) dt
add_block('simulink/Math Operations/Gain', [robot_name '/Gain_wL']);
set_param([robot_name '/Gain_wL'], 'Gain', '1/mw', 'Position', [140, 48, 190, 82]);

add_block('simulink/Continuous/Integrator', [robot_name '/Integrator_wL']);
set_param([robot_name '/Integrator_wL'], 'Position', [240, 48, 290, 82]);
set_param([robot_name '/Integrator_wL'], 'InitialCondition', '0');

% --- 轮子模块（右轮） ---
add_block('simulink/Math Operations/Gain', [robot_name '/Gain_wR']);
set_param([robot_name '/Gain_wR'], 'Gain', '1/mw', 'Position', [140, 148, 190, 182]);

add_block('simulink/Continuous/Integrator', [robot_name '/Integrator_wR']);
set_param([robot_name '/Integrator_wR'], 'Position', [240, 148, 290, 182]);
set_param([robot_name '/Integrator_wR'], 'InitialCondition', '0');

% 连线: Inport → Gain → Integrator
add_line(robot_name, 'F_L/1',  'Gain_wL/1');
add_line(robot_name, 'Gain_wL/1', 'Integrator_wL/1');
add_line(robot_name, 'F_R/1',  'Gain_wR/1');
add_line(robot_name, 'Gain_wR/1', 'Integrator_wR/1');

% --- 旋转模块 ---
% 线速度: v = (v_L + v_R) / 2
add_block('simulink/Math Operations/Add', [robot_name '/Add_v']);
set_param([robot_name '/Add_v'], 'Inputs', '++', 'Position', [370, 105, 400, 145]);
set_param([robot_name '/Add_v'], 'IconShape', 'round');

add_block('simulink/Math Operations/Gain', [robot_name '/Gain_v_half']);
set_param([robot_name '/Gain_v_half'], 'Gain', '0.5', 'Position', [440, 108, 480, 142]);

% 角速度: ω = (v_R - v_L) / L
add_block('simulink/Math Operations/Add', [robot_name '/Add_omega']);
set_param([robot_name '/Add_omega'], 'Inputs', '-+', 'Position', [370, 175, 400, 215]);
set_param([robot_name '/Add_omega'], 'IconShape', 'round');

add_block('simulink/Math Operations/Gain', [robot_name '/Gain_omega']);
set_param([robot_name '/Gain_omega'], 'Gain', '1/L', 'Position', [440, 178, 480, 212]);

% 连线: 轮速 → 旋转模块
add_line(robot_name, 'Integrator_wL/1', 'Add_v/1');
add_line(robot_name, 'Integrator_wR/1', 'Add_v/2');
add_line(robot_name, 'Integrator_wL/1', 'Add_omega/1');
add_line(robot_name, 'Integrator_wR/1', 'Add_omega/2');

add_line(robot_name, 'Add_v/1',     'Gain_v_half/1');
add_line(robot_name, 'Add_omega/1', 'Gain_omega/1');

% --- 积分获得 θ ---
add_block('simulink/Continuous/Integrator', [robot_name '/Integrator_theta']);
set_param([robot_name '/Integrator_theta'], 'Position', [520, 178, 570, 212]);
set_param([robot_name '/Integrator_theta'], 'InitialCondition', '0');

add_line(robot_name, 'Gain_omega/1', 'Integrator_theta/1');

% --- 分速度模块 ---
% vx = v * cos(θ), vy = v * sin(θ)
% 使用 Mux 组合 v 和 θ
add_block('simulink/Signal Routing/Mux', [robot_name '/Mux_vx']);
set_param([robot_name '/Mux_vx'], 'Inputs', '2', 'Position', [620, 50, 645, 140]);
set_param([robot_name '/Mux_vx'], 'DisplayOption', 'none');

add_block('simulink/Signal Routing/Mux', [robot_name '/Mux_vy']);
set_param([robot_name '/Mux_vy'], 'Inputs', '2', 'Position', [620, 170, 645, 260]);
set_param([robot_name '/Mux_vy'], 'DisplayOption', 'none');

add_block('simulink/User-Defined Functions/Fcn', [robot_name '/Fcn_vx']);
set_param([robot_name '/Fcn_vx'], 'Expr', 'u(1)*cos(u(2))', 'Position', [680, 55, 740, 135]);

add_block('simulink/User-Defined Functions/Fcn', [robot_name '/Fcn_vy']);
set_param([robot_name '/Fcn_vy'], 'Expr', 'u(1)*sin(u(2))', 'Position', [680, 175, 740, 255]);

% 连线: v → Mux, θ → Mux
add_line(robot_name, 'Gain_v_half/1', 'Mux_vx/1');
add_line(robot_name, 'Integrator_theta/1', 'Mux_vx/2');
add_line(robot_name, 'Gain_v_half/1', 'Mux_vy/1');
add_line(robot_name, 'Integrator_theta/1', 'Mux_vy/2');

add_line(robot_name, 'Mux_vx/1', 'Fcn_vx/1');
add_line(robot_name, 'Mux_vy/1', 'Fcn_vy/1');

% --- 积分获得 x, y ---
add_block('simulink/Continuous/Integrator', [robot_name '/Integrator_x']);
set_param([robot_name '/Integrator_x'], 'Position', [780, 55, 830, 105]);
set_param([robot_name '/Integrator_x'], 'InitialCondition', '0');

add_block('simulink/Continuous/Integrator', [robot_name '/Integrator_y']);
set_param([robot_name '/Integrator_y'], 'Position', [780, 175, 830, 225]);
set_param([robot_name '/Integrator_y'], 'InitialCondition', '0');

add_line(robot_name, 'Fcn_vx/1', 'Integrator_x/1');
add_line(robot_name, 'Fcn_vy/1', 'Integrator_y/1');

% --- 感应器模块（输出: 合力、vx、x、y、感应值） ---
% 合力 = sqrt(vx^2 + vy^2)，感应值用 v 代替
add_block('simulink/Signal Routing/Mux', [robot_name '/Mux_sensor']);
set_param([robot_name '/Mux_sensor'], 'Inputs', '2', 'Position', [780, 280, 805, 350]);
set_param([robot_name '/Mux_sensor'], 'DisplayOption', 'none');

add_block('simulink/User-Defined Functions/Fcn', [robot_name '/Fcn_sensor']);
set_param([robot_name '/Fcn_sensor'], 'Expr', 'sqrt(u(1)^2+u(2)^2)', 'Position', [840, 285, 900, 355]);

% 连线: fx = cos(θ), fy = sin(θ) → sensor 合力
% 这里用分力表示: Fx = F_L*cos(θ), Fy = F_R*sin(θ) 近似为合力
% 实际: 合力直接用 v 作为感应值
add_line(robot_name, 'Fcn_vx/1', 'Mux_sensor/1');
add_line(robot_name, 'Fcn_vy/1', 'Mux_sensor/2');
add_line(robot_name, 'Mux_sensor/1', 'Fcn_sensor/1');

% --- 输出端口 ---
% 删除默认 Outport 并创建 5 个输出
delete_block(robot_outports(1));

% Out1: x (横坐标)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/x']);
set_param([robot_name '/x'], 'Position', [920, 55, 950, 75]);

% Out2: y (纵坐标)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/y']);
set_param([robot_name '/y'], 'Position', [920, 100, 950, 120]);

% Out3: theta (航向角)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/theta']);
set_param([robot_name '/theta'], 'Position', [920, 145, 950, 165]);

% Out4: vx (横轴速度分量)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/vx']);
set_param([robot_name '/vx'], 'Position', [920, 190, 950, 210]);

% Out5: vy (纵轴速度分量)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/vy']);
set_param([robot_name '/vy'], 'Position', [920, 235, 950, 255]);

% Out6: sensor (感应值 = 合力)
add_block('simulink/Commonly Used Blocks/Out1', [robot_name '/sensor']);
set_param([robot_name '/sensor'], 'Position', [920, 280, 950, 300]);

% 连线到输出端口
add_line(robot_name, 'Integrator_x/1', 'x/1');
add_line(robot_name, 'Integrator_y/1', 'y/1');
add_line(robot_name, 'Integrator_theta/1', 'theta/1');
add_line(robot_name, 'Fcn_vx/1', 'vx/1');
add_line(robot_name, 'Fcn_vy/1', 'vy/1');
add_line(robot_name, 'Fcn_sensor/1', 'sensor/1');

%% ========================================================================
%  第二部分：PID 控制子系统
%  ========================================================================
pid_name = [model_name '/PID Control System'];

add_block('simulink/Ports & Subsystems/Subsystem', pid_name);
set_param(pid_name, 'Position', [150, 80, 380, 420]);
set_param(pid_name, 'BackgroundColor', 'lightGreen');

% 删除默认 Inport/Outport，重新创建
pid_inports  = find_system(pid_name, 'SearchDepth', 1, 'BlockType', 'Inport');
pid_outports = find_system(pid_name, 'SearchDepth', 1, 'BlockType', 'Outport');
delete_block(pid_inports(1));
delete_block(pid_outports(1));

% 输入端口（7个）
port_specs = { ...
    'x_target',  50,  38; ...
    'y_target',  50,  93; ...
    'x_actual',  50, 148; ...
    'y_actual',  50, 203; ...
    'theta',     50, 258; ...
    'vx',        50, 313; ...
    'vy',        50, 368 };

for i = 1:size(port_specs, 1)
    blk = [pid_name '/' port_specs{i,1}];
    add_block('simulink/Commonly Used Blocks/In1', blk);
    set_param(blk, 'Position', [port_specs{i,2}, port_specs{i,3}, ...
                                port_specs{i,2}+30, port_specs{i,3}+14]);
end

% --- XY 控制器：用基本块实现 ---
% theta_des = atan2(y_target - y, x_target - x)
% v_des = min(v_max, Kp * sqrt(dx^2 + dy^2))

% 位置误差
add_block('simulink/Math Operations/Add', [pid_name '/dx_err']);
set_param([pid_name '/dx_err'], 'Inputs', '-+', 'Position', [140, 38, 180, 72]);
set_param([pid_name '/dx_err'], 'IconShape', 'round');

add_block('simulink/Math Operations/Add', [pid_name '/dy_err']);
set_param([pid_name '/dy_err'], 'Inputs', '-+', 'Position', [140, 93, 180, 127]);
set_param([pid_name '/dy_err'], 'IconShape', 'round');

% atan2(dy, dx) → theta_des
add_block('simulink/Math Operations/Trigonometric Function', [pid_name '/Atan2']);
set_param([pid_name '/Atan2'], 'Operator', 'atan2', 'Position', [230, 75, 270, 125]);

% 距离: sqrt(dx^2 + dy^2)
add_block('simulink/Math Operations/Math Function', [pid_name '/dx2']);
set_param([pid_name '/dx2'], 'Operator', 'square', 'Position', [230, 140, 260, 170]);

add_block('simulink/Math Operations/Math Function', [pid_name '/dy2']);
set_param([pid_name '/dy2'], 'Operator', 'square', 'Position', [230, 175, 260, 205]);

add_block('simulink/Math Operations/Add', [pid_name '/Add_dist2']);
set_param([pid_name '/Add_dist2'], 'Inputs', '++', 'Position', [290, 140, 320, 180]);
set_param([pid_name '/Add_dist2'], 'IconShape', 'round');

add_block('simulink/Math Operations/Sqrt', [pid_name '/Sqrt_dist']);
set_param([pid_name '/Sqrt_dist'], 'Position', [350, 148, 380, 182]);

% v_des = Kp_pos * dist（带饱和）
add_block('simulink/Math Operations/Gain', [pid_name '/Kp_pos']);
set_param([pid_name '/Kp_pos'], 'Gain', '0.8', 'Position', [410, 148, 450, 182]);

add_block('simulink/Discontinuities/Saturation', [pid_name '/Sat_v']);
set_param([pid_name '/Sat_v'], 'UpperLimit', '0.5', 'LowerLimit', '0', ...
    'Position', [480, 148, 520, 182]);

% 连线：目标/实际 → 误差
add_line(pid_name, 'x_target/1', 'dx_err/1');
add_line(pid_name, 'x_actual/1', 'dx_err/2');
add_line(pid_name, 'y_target/1', 'dy_err/1');
add_line(pid_name, 'y_actual/1', 'dy_err/2');

% 连线：atan2
add_line(pid_name, 'dy_err/1', 'Atan2/1');
add_line(pid_name, 'dx_err/1', 'Atan2/2');

% 连线：距离计算
add_line(pid_name, 'dx_err/1', 'dx2/1');
add_line(pid_name, 'dy_err/1', 'dy2/1');
add_line(pid_name, 'dx2/1', 'Add_dist2/1');
add_line(pid_name, 'dy2/1', 'Add_dist2/2');
add_line(pid_name, 'Add_dist2/1', 'Sqrt_dist/1');
add_line(pid_name, 'Sqrt_dist/1', 'Kp_pos/1');
add_line(pid_name, 'Kp_pos/1', 'Sat_v/1');

% --- 实际速度计算 ---
add_block('simulink/Signal Routing/Mux', [pid_name '/Mux_v_actual']);
set_param([pid_name '/Mux_v_actual'], 'Inputs', '2', 'Position', [200, 290, 225, 360]);
set_param([pid_name '/Mux_v_actual'], 'DisplayOption', 'none');

add_block('simulink/User-Defined Functions/Fcn', [pid_name '/Fcn_v_actual']);
set_param([pid_name '/Fcn_v_actual'], 'Expr', 'sqrt(u(1)^2+u(2)^2)', ...
    'Position', [260, 300, 320, 350]);

add_line(pid_name, 'vx/1', 'Mux_v_actual/1');
add_line(pid_name, 'vy/1', 'Mux_v_actual/2');
add_line(pid_name, 'Mux_v_actual/1', 'Fcn_v_actual/1');

% --- 角度 PID 控制器 ---
% 输入: theta_des, theta; 输出: omega_correction
% 角度误差需要包裹在 [-pi, pi]
add_block('simulink/Math Operations/Add', [pid_name '/theta_err_raw']);
set_param([pid_name '/theta_err_raw'], 'Inputs', '-+', 'Position', [400, 85, 430, 115]);
set_param([pid_name '/theta_err_raw'], 'IconShape', 'round');

% 角度包裹: atan2(sin(err), cos(err))
add_block('simulink/User-Defined Functions/Fcn', [pid_name '/Fcn_wrap']);
set_param([pid_name '/Fcn_wrap'], 'Expr', 'atan2(sin(u), cos(u))', ...
    'Position', [460, 80, 520, 120]);

add_block('simulink/Continuous/PID Controller', [pid_name '/Angle PID']);
set_param([pid_name '/Angle PID'], 'Position', [560, 80, 610, 130]);
set_param([pid_name '/Angle PID'], 'P', '1.5', 'I', '0.1', 'D', '0.05');
set_param([pid_name '/Angle PID'], 'SaturationEnabled', 'on');
set_param([pid_name '/Angle PID'], 'UpperSaturationLimit', '2.0');
set_param([pid_name '/Angle PID'], 'LowerSaturationLimit', '-2.0');

% 连线: theta_des(Atan2) → 角度误差
add_line(pid_name, 'Atan2/1', 'theta_err_raw/1');
add_line(pid_name, 'theta/1', 'theta_err_raw/2');
add_line(pid_name, 'theta_err_raw/1', 'Fcn_wrap/1');
add_line(pid_name, 'Fcn_wrap/1', 'Angle PID/1');

% --- 速度 PID 控制器 ---
add_block('simulink/Math Operations/Add', [pid_name '/v_err']);
set_param([pid_name '/v_err'], 'Inputs', '-+', 'Position', [400, 300, 430, 340]);
set_param([pid_name '/v_err'], 'IconShape', 'round');

add_block('simulink/Continuous/PID Controller', [pid_name '/Speed PID']);
set_param([pid_name '/Speed PID'], 'Position', [560, 300, 610, 350]);
set_param([pid_name '/Speed PID'], 'P', '3.0', 'I', '0.5', 'D', '0.0');
set_param([pid_name '/Speed PID'], 'SaturationEnabled', 'on');
set_param([pid_name '/Speed PID'], 'UpperSaturationLimit', '10');
set_param([pid_name '/Speed PID'], 'LowerSaturationLimit', '-10');

% 连线
add_line(pid_name, 'Sat_v/1', 'v_err/1');
add_line(pid_name, 'Fcn_v_actual/1', 'v_err/2');
add_line(pid_name, 'v_err/1', 'Speed PID/1');

% --- 力混合器（Force Mixer） ---
% F_L = F_base - omega_correction * (L/2)
% F_R = F_base + omega_correction * (L/2)
add_block('simulink/Math Operations/Gain', [pid_name '/Gain_half_L']);
set_param([pid_name '/Gain_half_L'], 'Gain', 'L/2', 'Position', [470, 225, 510, 255]);

add_block('simulink/Math Operations/Add', [pid_name '/Mixer_FL']);
set_param([pid_name '/Mixer_FL'], 'Inputs', '+-', 'Position', [570, 210, 600, 250]);
set_param([pid_name '/Mixer_FL'], 'IconShape', 'round');

add_block('simulink/Math Operations/Add', [pid_name '/Mixer_FR']);
set_param([pid_name '/Mixer_FR'], 'Inputs', '++', 'Position', [570, 270, 600, 310]);
set_param([pid_name '/Mixer_FR'], 'IconShape', 'round');

% Saturation on forces
add_block('simulink/Discontinuities/Saturation', [pid_name '/Sat_FL']);
set_param([pid_name '/Sat_FL'], 'UpperLimit', '15', 'LowerLimit', '-15', ...
    'Position', [640, 213, 670, 247]);

add_block('simulink/Discontinuities/Saturation', [pid_name '/Sat_FR']);
set_param([pid_name '/Sat_FR'], 'UpperLimit', '15', 'LowerLimit', '-15', ...
    'Position', [640, 273, 670, 307]);

% 连线：角度PID输出 → 增益 → 混合器
add_line(pid_name, 'Angle PID/1', 'Gain_half_L/1');
add_line(pid_name, 'Gain_half_L/1', 'Mixer_FL/2');
add_line(pid_name, 'Gain_half_L/1', 'Mixer_FR/2');

% 连线：速度PID输出 → 混合器
add_line(pid_name, 'Speed PID/1', 'Mixer_FL/1');
add_line(pid_name, 'Speed PID/1', 'Mixer_FR/1');

add_line(pid_name, 'Mixer_FL/1', 'Sat_FL/1');
add_line(pid_name, 'Mixer_FR/1', 'Sat_FR/1');

% --- 输出端口 ---
add_block('simulink/Commonly Used Blocks/Out1', [pid_name '/F_L']);
set_param([pid_name '/F_L'], 'Position', [720, 215, 750, 235]);

add_block('simulink/Commonly Used Blocks/Out1', [pid_name '/F_R']);
set_param([pid_name '/F_R'], 'Position', [720, 275, 750, 295]);

add_line(pid_name, 'Sat_FL/1', 'F_L/1');
add_line(pid_name, 'Sat_FR/1', 'F_R/1');

%% ========================================================================
%  顶层连接
%  ========================================================================

% --- 目标输入（输入模块：分配左右轮作用力的参考目标） ---
add_block('simulink/Sources/Constant', [model_name '/Target X']);
set_param([model_name '/Target X'], 'Value', '5', 'Position', [60, 130, 120, 160]);

add_block('simulink/Sources/Constant', [model_name '/Target Y']);
set_param([model_name '/Target Y'], 'Value', '5', 'Position', [60, 190, 120, 220]);

% --- PID 控制子系统输入连线 ---
% x_target, y_target
add_line(model_name, 'Target X/1', 'PID Control System/1');
add_line(model_name, 'Target Y/1', 'PID Control System/2');

% 机器人输出 → PID 输入 (x_actual, y_actual, theta, vx, vy)
% 需要先给 PID Control System 配置好输入端口名称
% In3=x_actual, In4=y_actual, In5=theta, In6=vx, In7=vy

% 机器人反馈连线
add_line(model_name, 'Differential Drive Robot/1', 'PID Control System/3');  % x → x_actual
add_line(model_name, 'Differential Drive Robot/2', 'PID Control System/4');  % y → y_actual
add_line(model_name, 'Differential Drive Robot/3', 'PID Control System/5');  % theta
add_line(model_name, 'Differential Drive Robot/4', 'PID Control System/6');  % vx
add_line(model_name, 'Differential Drive Robot/5', 'PID Control System/7');  % vy

% PID 输出 → 机器人输入
add_line(model_name, 'PID Control System/1', 'Differential Drive Robot/1');  % F_L
add_line(model_name, 'PID Control System/2', 'Differential Drive Robot/2');  % F_R

%% ========================================================================
%  可视化模块
%  ========================================================================

% --- 示波器：合力 ---
add_block('simulink/Commonly Used Blocks/Scope', [model_name '/Scope_Force']);
set_param([model_name '/Scope_Force'], 'Position', [720, 480, 780, 530]);
set_param([model_name '/Scope_Force'], 'Name', '合力(作用力合力)');

% --- 示波器：vx ---
add_block('simulink/Commonly Used Blocks/Scope', [model_name '/Scope_vx']);
set_param([model_name '/Scope_vx'], 'Position', [720, 550, 780, 600]);
set_param([model_name '/Scope_vx'], 'Name', '横轴速度分量 vx');

% --- 示波器：x ---
add_block('simulink/Commonly Used Blocks/Scope', [model_name '/Scope_x']);
set_param([model_name '/Scope_x'], 'Position', [720, 620, 780, 670]);
set_param([model_name '/Scope_x'], 'Name', '横坐标 x');

% --- 示波器：y ---
add_block('simulink/Commonly Used Blocks/Scope', [model_name '/Scope_y']);
set_param([model_name '/Scope_y'], 'Position', [720, 690, 780, 740]);
set_param([model_name '/Scope_y'], 'Name', '纵坐标 y');

% --- 示波器：感应值(sensor) ---
add_block('simulink/Commonly Used Blocks/Scope', [model_name '/Scope_Sensor']);
set_param([model_name '/Scope_Sensor'], 'Position', [720, 760, 780, 810]);
set_param([model_name '/Scope_Sensor'], 'Name', '感应值 sensor');

% 连接示波器
add_line(model_name, 'Differential Drive Robot/6', 'Scope_Force/1');   % sensor（合力）
add_line(model_name, 'Differential Drive Robot/4', 'Scope_vx/1');     % vx
add_line(model_name, 'Differential Drive Robot/1', 'Scope_x/1');      % x
add_line(model_name, 'Differential Drive Robot/2', 'Scope_y/1');      % y
add_line(model_name, 'Differential Drive Robot/5', 'Scope_Sensor/1'); % vy（作为感应值参考）

% --- XY 坐标图：运动轨迹 ---
add_block('simulink/Sinks/XY Graph', [model_name '/XY Graph']);
set_param([model_name '/XY Graph'], 'Position', [720, 830, 790, 880]);
set_param([model_name '/XY Graph'], 'Name', '机器人运动轨迹');
set_param([model_name '/XY Graph'], 'xmin', '-2');
set_param([model_name '/XY Graph'], 'xmax', '8');
set_param([model_name '/XY Graph'], 'ymin', '-2');
set_param([model_name '/XY Graph'], 'ymax', '8');

add_line(model_name, 'Differential Drive Robot/1', 'XY Graph/1');  % x
add_line(model_name, 'Differential Drive Robot/2', 'XY Graph/2');  % y

%% ========================================================================
%  模型整理与保存
%  ========================================================================

% 设置仿真参数
set_param(model_name, 'Solver', 'ode45');
set_param(model_name, 'StopTime', '30');
set_param(model_name, 'MaxStep', '0.01');
set_param(model_name, 'StartTime', '0');

% 排列子系统内部布局（可选，如布局不理想可注释掉手动调整）
% Simulink.BlockDiagram.arrangeSystem(robot_name);
% Simulink.BlockDiagram.arrangeSystem(pid_name);
% Simulink.BlockDiagram.arrangeSystem(model_name);

% 保存模型
save_system(model_name);

fprintf('模型构建完成: %s.slx\n', model_name);
fprintf('机器人子系统: Differential Drive Robot\n');
fprintf('  - 轮子模块 (左/右): Gain + Integrator\n');
fprintf('  - 旋转模块: Sum → v(线速度), ω(角速度)\n');
fprintf('  - 分速度模块: vx=v·cos(θ), vy=v·sin(θ)\n');
fprintf('  - 感应器模块: sqrt(vx²+vy²)\n');
fprintf('PID 控制子系统: PID Control System\n');
fprintf('  - XY 控制器: atan2 + 距离比例\n');
fprintf('  - 角度 PID: 航向角控制\n');
fprintf('  - 速度 PID: 线速度控制\n');
fprintf('  - 力混合器: 分配左右轮力\n');
