%% 双轮差速AGV PID控制器 Simulink模型构建脚本
%  运行此脚本自动生成 diff_drive_pid_model.slx
%  结构: v_ref/ω_ref → 逆运动学 → Sum(+-) → PI → 饱和 → 电机 → 运动学 → 积分器 → 位姿

clear; close all; clc;

%% ---- 物理参数 ----
r = 0.075;         % 车轮半径 [m]
L = 0.52;          % 轮距 [m]
tau = 0.06;        % 电机机电时间常数 [s]
K_motor = 2.8;     % 电机增益 [(rad/s)/V]

%% ---- 创建模型 ----
mdl = 'diff_drive_pid_model';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
open_system(mdl);

%% ---- 1. 参考输入 ----
add_block('simulink/Sources/Step', [mdl '/v_ref']);
set_param([mdl '/v_ref'], 'Time', '0.5', 'Before', '0', 'After', '0.3', ...
          'Position', [30, 60, 90, 90]);
add_block('simulink/Sources/Constant', [mdl '/omega_ref']);
set_param([mdl '/omega_ref'], 'Value', '0', ...
          'Position', [30, 140, 90, 170]);

%% ---- 2. 逆运动学: (v,ω) → (ωL_ref, ωR_ref) ----
% r, L 直接嵌入函数体, 避免多余输入端口
add_block('simulink/User-Defined Functions/MATLAB Function', ...
          [mdl '/InverseKinematics']);
set_param([mdl '/InverseKinematics'], ...
    'Position', [150, 50, 250, 190]);
inv_kin_code = sprintf([ ...
    'function [wL_ref, wR_ref] = InverseKinematics(v, omega)\n', ...
    '%%#codegen\n', ...
    'r = %.4f;\nL = %.4f;\n', ...
    'wL_ref = v/r - omega*L/(2*r);\n', ...
    'wR_ref = v/r + omega*L/(2*r);\n', ...
    'end'], r, L);
set_param([mdl '/InverseKinematics'], 'MATLABFcn', inv_kin_code);

%% ---- 3. 速度环误差Sum块: 误差 = 参考(+) - 实际(-) ----
add_block('simulink/Math Operations/Sum', [mdl '/Sum_Left']);
set_param([mdl '/Sum_Left'], 'Inputs', '|+-', ...
          'Position', [320, 40, 350, 80]);
add_block('simulink/Math Operations/Sum', [mdl '/Sum_Right']);
set_param([mdl '/Sum_Right'], 'Inputs', '|+-', ...
          'Position', [320, 140, 350, 180]);

%% ---- 4. 速度环PI控制器 ----
add_block('simulink/Continuous/PID Controller', [mdl '/PI_Left']);
set_param([mdl '/PI_Left'], 'P', '2.0', 'I', '12.0', 'D', '0', ...
          'FilterCoefficient', '100', ...
          'Position', [410, 35, 460, 85]);
add_block('simulink/Continuous/PID Controller', [mdl '/PI_Right']);
set_param([mdl '/PI_Right'], 'P', '2.0', 'I', '12.0', 'D', '0', ...
          'FilterCoefficient', '100', ...
          'Position', [410, 135, 460, 185]);

%% ---- 5. 电压限幅 ±12V ----
add_block('simulink/Discontinuities/Saturation', [mdl '/Sat_L']);
set_param([mdl '/Sat_L'], 'UpperLimit', '12', 'LowerLimit', '-12', ...
          'Position', [520, 35, 570, 85]);
add_block('simulink/Discontinuities/Saturation', [mdl '/Sat_R']);
set_param([mdl '/Sat_R'], 'UpperLimit', '12', 'LowerLimit', '-12', ...
          'Position', [520, 135, 570, 185]);

%% ---- 6. 电机模型 (一阶惯性) ----
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Motor_L']);
set_param([mdl '/Motor_L'], 'Numerator', num2str(K_motor), ...
          'Denominator', ['[', num2str(tau), ' 1]'], ...
          'Position', [630, 35, 690, 85]);
add_block('simulink/Continuous/Transfer Fcn', [mdl '/Motor_R']);
set_param([mdl '/Motor_R'], 'Numerator', num2str(K_motor), ...
          'Denominator', ['[', num2str(tau), ' 1]'], ...
          'Position', [630, 135, 690, 185]);

%% ---- 7. 运动学模型 ----
add_block('simulink/User-Defined Functions/MATLAB Function', ...
          [mdl '/DiffDriveKinematics']);
set_param([mdl '/DiffDriveKinematics'], ...
    'Position', [760, 20, 880, 200]);
kin_code = sprintf([ ...
    'function [dx, dy, dtheta, v_out, omega_out] = DiffDriveKinematics(wL, wR, theta)\n', ...
    '%%#codegen\n', ...
    'r = %.4f;\nL = %.4f;\n', ...
    'v_out = r/2 * (wL + wR);\n', ...
    'omega_out = r/L * (wR - wL);\n', ...
    'dx = v_out * cos(theta);\n', ...
    'dy = v_out * sin(theta);\n', ...
    'dtheta = omega_out;\n', ...
    'end'], r, L);
set_param([mdl '/DiffDriveKinematics'], 'MATLABFcn', kin_code);

%% ---- 8. 积分器 (位姿更新) ----
add_block('simulink/Continuous/Integrator', [mdl '/Integrator_X']);
set_param([mdl '/Integrator_X'], 'InitialCondition', '0', ...
          'Position', [950, 30, 1000, 70]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrator_Y']);
set_param([mdl '/Integrator_Y'], 'InitialCondition', '0', ...
          'Position', [950, 100, 1000, 140]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrator_Theta']);
set_param([mdl '/Integrator_Theta'], 'InitialCondition', '0', ...
          'Position', [950, 170, 1000, 210]);

%% ---- 9. 信号合并 (用于XY绘图) ----
add_block('simulink/Signal Routing/Mux', [mdl '/Mux_XY']);
set_param([mdl '/Mux_XY'], 'Inputs', '2', ...
          'Position', [1070, 60, 1085, 110]);

%% ---- 10. 数据记录 ----
add_block('simulink/Sinks/To Workspace', [mdl '/x_out']);
set_param([mdl '/x_out'], 'VariableName', 'x_sim', ...
          'Position', [1070, 20, 1120, 50]);
add_block('simulink/Sinks/To Workspace', [mdl '/y_out']);
set_param([mdl '/y_out'], 'VariableName', 'y_sim', ...
          'Position', [1070, 80, 1120, 110]);
add_block('simulink/Sinks/To Workspace', [mdl '/theta_out']);
set_param([mdl '/theta_out'], 'VariableName', 'theta_sim', ...
          'Position', [1070, 140, 1120, 170]);
add_block('simulink/Sinks/To Workspace', [mdl '/v_out']);
set_param([mdl '/v_out'], 'VariableName', 'v_sim', ...
          'Position', [1070, 200, 1120, 230]);
add_block('simulink/Sinks/To Workspace', [mdl '/omega_out']);
set_param([mdl '/omega_out'], 'VariableName', 'omega_sim', ...
          'Position', [1070, 260, 1120, 290]);
add_block('simulink/Sinks/To Workspace', [mdl '/wL_out']);
set_param([mdl '/wL_out'], 'VariableName', 'wL_sim', ...
          'Position', [1070, 320, 1120, 350]);
add_block('simulink/Sinks/To Workspace', [mdl '/wR_out']);
set_param([mdl '/wR_out'], 'VariableName', 'wR_sim', ...
          'Position', [1070, 380, 1120, 410]);
add_block('simulink/Sinks/To Workspace', [mdl '/tout']);
set_param([mdl '/tout'], 'VariableName', 't_sim', ...
          'Position', [1070, 440, 1120, 470]);

%% ---- 11. 信号连线 ----

% 参考输入 → 逆运动学
add_line(mdl, 'v_ref/1', 'InverseKinematics/1');
add_line(mdl, 'omega_ref/1', 'InverseKinematics/2');

% 逆运动学 → Sum(+)  (ωL_ref, ωR_ref)
add_line(mdl, 'InverseKinematics/1', 'Sum_Left/1');
add_line(mdl, 'InverseKinematics/2', 'Sum_Right/1');

% Sum → PI → Saturation → Motor
add_line(mdl, 'Sum_Left/1', 'PI_Left/1');
add_line(mdl, 'Sum_Right/1', 'PI_Right/1');
add_line(mdl, 'PI_Left/1', 'Sat_L/1');
add_line(mdl, 'PI_Right/1', 'Sat_R/1');
add_line(mdl, 'Sat_L/1', 'Motor_L/1');
add_line(mdl, 'Sat_R/1', 'Motor_R/1');

% Motor输出 → 运动学 (wL, wR)
add_line(mdl, 'Motor_L/1', 'DiffDriveKinematics/1');
add_line(mdl, 'Motor_R/1', 'DiffDriveKinematics/2');

% 运动学输出 → 积分器
add_line(mdl, 'DiffDriveKinematics/1', 'Integrator_X/1');     % dx → x
add_line(mdl, 'DiffDriveKinematics/2', 'Integrator_Y/1');     % dy → y
add_line(mdl, 'DiffDriveKinematics/3', 'Integrator_Theta/1'); % dθ → θ

% θ 反馈 → 运动学 (port 3)
add_line(mdl, 'Integrator_Theta/1', 'DiffDriveKinematics/3');

% 积分器 → 数据记录
add_line(mdl, 'Integrator_X/1', 'x_out/1');
add_line(mdl, 'Integrator_Y/1', 'y_out/1');
add_line(mdl, 'Integrator_Theta/1', 'theta_out/1');

% 运动学 v_out, ω_out → 数据记录
add_line(mdl, 'DiffDriveKinematics/4', 'v_out/1');
add_line(mdl, 'DiffDriveKinematics/5', 'omega_out/1');

% Motor输出 → 数据记录 (轮速)
add_line(mdl, 'Motor_L/1', 'wL_out/1');
add_line(mdl, 'Motor_R/1', 'wR_out/1');

% Motor输出 → Sum(-)  速度环反馈
add_line(mdl, 'Motor_L/1', 'Sum_Left/2');
add_line(mdl, 'Motor_R/1', 'Sum_Right/2');

%% ---- 12. 模型配置 ----
set_param(mdl, 'Solver', 'ode45', ...
          'StopTime', '10', ...
          'MaxStep', '0.01');

%% ---- 13. 保存 ----
save_system(mdl);
fprintf('Simulink模型已保存: %s.slx\n', mdl);
fprintf('路径: %s\n', fullfile(pwd, [mdl, '.slx']));