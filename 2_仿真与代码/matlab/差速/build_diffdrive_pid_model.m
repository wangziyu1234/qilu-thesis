function build_diffdrive_pid_model(modelName)
%BUILD_DIFFDRIVE_PID_MODEL 生成带中文标注的轮式差速机器人Simulink模型并自动仿真

if nargin < 1 || isempty(modelName)
    modelName = 'diff_drive_robot_pid_system';
end

targetModelName = matlab.lang.makeValidName(char(modelName));
buildModelName = matlab.lang.makeValidName([targetModelName '_building']);

if bdIsLoaded(buildModelName)
    close_system(buildModelName, 0);
end

load_system('simulink');
new_system(buildModelName);
open_system(buildModelName);

set_param(buildModelName, ...
    'StopTime', '20', ...
    'Solver', 'ode45', ...
    'SaveOutput', 'on', ...
    'OutputSaveName', 'yout', ...
    'ReturnWorkspaceOutputs', 'on');

assignin('base', 'ROBOT_WHEEL_RADIUS', 0.065);
assignin('base', 'ROBOT_WHEEL_BASE', 0.32);
assignin('base', 'ROBOT_MOTOR_GAIN', 1.0);
assignin('base', 'ROBOT_MOTOR_TAU', 0.15);
assignin('base', 'ROBOT_WHEEL_KP', 3.0);
assignin('base', 'ROBOT_WHEEL_KI', 1.2);
assignin('base', 'ROBOT_WHEEL_KD', 0.03);
assignin('base', 'ROBOT_XY_GAIN', 1.4);
assignin('base', 'ROBOT_THETA_KP', 4.0);
assignin('base', 'ROBOT_THETA_KI', 0.3);
assignin('base', 'ROBOT_THETA_KD', 0.05);
assignin('base', 'ROBOT_FORCE_GAIN', 8.0);
assignin('base', 'ROBOT_EPS', 1e-6);
assignin('base', 'ROBOT_DIST_FORCE_GAIN', 0.35);
assignin('base', 'ROBOT_DIST_TORQUE_GAIN', 0.22);
assignin('base', 'ROBOT_LEFT_LOAD_BIAS', 0.35);
assignin('base', 'ROBOT_RIGHT_LOAD_BIAS', -0.20);
assignin('base', 'ROBOT_TARGET_X', 2.0);
assignin('base', 'ROBOT_TARGET_Y', 0.0);
assignin('base', 'ROBOT_SENSOR_THRESHOLD', 0.5);

add_block('simulink/Sources/Constant', [buildModelName '/目标X'], ...
    'Value', 'ROBOT_TARGET_X', ...
    'Position', [40 60 90 90]);
add_block('simulink/Sources/Constant', [buildModelName '/目标Y'], ...
    'Value', 'ROBOT_TARGET_Y', ...
    'Position', [40 120 90 150]);
add_block('simulink/Sources/Sine Wave', [buildModelName '/航向修正'], ...
    'Amplitude', '0.45', ...
    'Bias', '0', ...
    'Frequency', '0.55', ...
    'Position', [40 180 90 210]);
add_block('simulink/Sources/Pulse Generator', [buildModelName '/横向扰动力'], ...
    'Amplitude', '2', ...
    'Period', '20', ...
    'PulseWidth', '15', ...
    'PhaseDelay', '0', ...
    'Position', [40 250 100 280]);
add_block('simulink/Sources/Step', [buildModelName '/扰动转矩'], ...
    'Time', '6', ...
    'Before', '0', ...
    'After', '0.6', ...
    'Position', [40 310 100 340]);
add_block('simulink/Sources/Sine Wave', [buildModelName '/左轮负载扰动'], ...
    'Amplitude', '0.28', ...
    'Bias', 'ROBOT_LEFT_LOAD_BIAS', ...
    'Frequency', '1.15', ...
    'Position', [40 370 110 400]);
add_block('simulink/Sources/Sine Wave', [buildModelName '/右轮负载扰动'], ...
    'Amplitude', '0.22', ...
    'Bias', 'ROBOT_RIGHT_LOAD_BIAS', ...
    'Frequency', '0.82', ...
    'Position', [40 430 110 460]);

add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/XY控制器'], ...
    'Position', [150 55 290 170]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/角度控制器'], ...
    'Position', [350 85 490 180]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/分速度模块'], ...
    'Position', [540 85 680 180]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/左轮模块'], ...
    'Position', [740 30 900 190]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/右轮模块'], ...
    'Position', [740 220 900 380]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/运动学模块'], ...
    'Position', [980 90 1140 280]);
add_block('simulink/Ports & Subsystems/Subsystem', [buildModelName '/传感器模块'], ...
    'Position', [1200 100 1370 290]);
add_block('simulink/Discrete/Memory', [buildModelName '/X状态记忆'], ...
    'Position', [1185 25 1220 55]);
add_block('simulink/Discrete/Memory', [buildModelName '/Y状态记忆'], ...
    'Position', [1185 65 1220 95]);
add_block('simulink/Discrete/Memory', [buildModelName '/航向状态记忆'], ...
    'Position', [1185 105 1220 135]);

add_block('simulink/Signal Routing/Mux', [buildModelName '/位姿合成'], ...
    'Inputs', '3', ...
    'Position', [1175 330 1195 410]);
add_block('simulink/Signal Routing/Mux', [buildModelName '/传感器合成'], ...
    'Inputs', '4', ...
    'Position', [1410 120 1430 260]);
add_block('simulink/Signal Routing/Mux', [buildModelName '/轮速合成'], ...
    'Inputs', '4', ...
    'Position', [940 10 960 170]);
add_block('simulink/Signal Routing/Mux', [buildModelName '/控制量合成'], ...
    'Inputs', '4', ...
    'Position', [710 400 730 500]);
add_block('simulink/Signal Routing/Mux', [buildModelName '/轨迹合成'], ...
    'Inputs', '2', ...
    'Position', [1175 430 1195 490]);
add_block('simulink/Signal Routing/Mux', [buildModelName '/作用力比例合成'], ...
    'Inputs', '4', ...
    'Position', [1175 520 1195 620]);

add_block('simulink/Math Operations/Abs', [buildModelName '/左轮力绝对值'], ...
    'Position', [945 540 975 570]);
add_block('simulink/Math Operations/Abs', [buildModelName '/右轮力绝对值'], ...
    'Position', [945 590 975 620]);
add_block('simulink/Math Operations/Sum', [buildModelName '/作用力总和'], ...
    'Inputs', '++', ...
    'Position', [1010 555 1040 605]);
add_block('simulink/Math Operations/Bias', [buildModelName '/比例分母修正'], ...
    'Bias', 'ROBOT_EPS', ...
    'Position', [1075 565 1125 595]);
add_block('simulink/Math Operations/Divide', [buildModelName '/左轮比例'], ...
    'Position', [1010 640 1040 670]);
add_block('simulink/Math Operations/Divide', [buildModelName '/右轮比例'], ...
    'Position', [1095 640 1125 670]);

add_block('simulink/Sinks/Scope', [buildModelName '/位姿示波器'], ...
    'Position', [1230 330 1410 410]);
add_block('simulink/Sinks/Scope', [buildModelName '/传感器示波器'], ...
    'Position', [1460 130 1640 255]);
add_block('simulink/Sinks/Scope', [buildModelName '/轮速示波器'], ...
    'Position', [995 10 1170 170]);
add_block('simulink/Sinks/Scope', [buildModelName '/控制量示波器'], ...
    'Position', [765 400 945 500]);
add_block('simulink/Sinks/XY Graph', [buildModelName '/轨迹图'], ...
    'Position', [1230 430 1410 500]);
add_block('simulink/Sinks/Scope', [buildModelName '/左右轮作用力比例图'], ...
    'Position', [1230 525 1450 625]);

add_block('simulink/Sinks/To Workspace', [buildModelName '/轨迹数据'], ...
    'VariableName', 'robot_xy_traj', ...
    'SaveFormat', 'Structure With Time', ...
    'Position', [1460 430 1540 460]);
add_block('simulink/Sinks/To Workspace', [buildModelName '/作用力比例数据'], ...
    'VariableName', 'wheel_force_ratio', ...
    'SaveFormat', 'Structure With Time', ...
    'Position', [1490 540 1580 570]);

createXYController([buildModelName '/XY控制器']);
createAngleController([buildModelName '/角度控制器']);
createSpeedSplitter([buildModelName '/分速度模块']);
createWheelModule([buildModelName '/左轮模块']);
createWheelModule([buildModelName '/右轮模块']);
createRotationModule([buildModelName '/运动学模块']);
createSensorModule([buildModelName '/传感器模块']);

add_line(buildModelName, '目标X/1', 'XY控制器/1', 'autorouting', 'on');
add_line(buildModelName, '目标Y/1', 'XY控制器/2', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/1', 'X状态记忆/1', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/2', 'Y状态记忆/1', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/3', '航向状态记忆/1', 'autorouting', 'on');
add_line(buildModelName, 'X状态记忆/1', 'XY控制器/3', 'autorouting', 'on');
add_line(buildModelName, 'Y状态记忆/1', 'XY控制器/4', 'autorouting', 'on');

add_line(buildModelName, 'XY控制器/1', '角度控制器/1', 'autorouting', 'on');
add_line(buildModelName, '航向修正/1', '角度控制器/2', 'autorouting', 'on');
add_line(buildModelName, '航向状态记忆/1', '角度控制器/3', 'autorouting', 'on');

add_line(buildModelName, 'XY控制器/2', '分速度模块/1', 'autorouting', 'on');
add_line(buildModelName, '角度控制器/1', '分速度模块/2', 'autorouting', 'on');

add_line(buildModelName, '分速度模块/1', '左轮模块/1', 'autorouting', 'on');
add_line(buildModelName, '分速度模块/2', '右轮模块/1', 'autorouting', 'on');
add_line(buildModelName, '左轮负载扰动/1', '左轮模块/2', 'autorouting', 'on');
add_line(buildModelName, '右轮负载扰动/1', '右轮模块/2', 'autorouting', 'on');

add_line(buildModelName, '左轮模块/1', '运动学模块/1', 'autorouting', 'on');
add_line(buildModelName, '右轮模块/1', '运动学模块/2', 'autorouting', 'on');
add_line(buildModelName, '横向扰动力/1', '运动学模块/3', 'autorouting', 'on');
add_line(buildModelName, '扰动转矩/1', '运动学模块/4', 'autorouting', 'on');

add_line(buildModelName, '运动学模块/1', '传感器模块/1', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/2', '传感器模块/2', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/3', '传感器模块/3', 'autorouting', 'on');

add_line(buildModelName, '运动学模块/1', '位姿合成/1', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/2', '位姿合成/2', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/3', '位姿合成/3', 'autorouting', 'on');
add_line(buildModelName, '位姿合成/1', '位姿示波器/1', 'autorouting', 'on');

add_line(buildModelName, '传感器模块/1', '传感器合成/1', 'autorouting', 'on');
add_line(buildModelName, '传感器模块/2', '传感器合成/2', 'autorouting', 'on');
add_line(buildModelName, '传感器模块/3', '传感器合成/3', 'autorouting', 'on');
add_line(buildModelName, '传感器模块/4', '传感器合成/4', 'autorouting', 'on');
add_line(buildModelName, '传感器合成/1', '传感器示波器/1', 'autorouting', 'on');

add_line(buildModelName, '分速度模块/1', '轮速合成/1', 'autorouting', 'on');
add_line(buildModelName, '分速度模块/2', '轮速合成/2', 'autorouting', 'on');
add_line(buildModelName, '左轮模块/1', '轮速合成/3', 'autorouting', 'on');
add_line(buildModelName, '右轮模块/1', '轮速合成/4', 'autorouting', 'on');
add_line(buildModelName, '轮速合成/1', '轮速示波器/1', 'autorouting', 'on');

add_line(buildModelName, 'XY控制器/2', '控制量合成/1', 'autorouting', 'on');
add_line(buildModelName, '角度控制器/1', '控制量合成/2', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/4', '控制量合成/3', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/5', '控制量合成/4', 'autorouting', 'on');
add_line(buildModelName, '控制量合成/1', '控制量示波器/1', 'autorouting', 'on');

add_line(buildModelName, '运动学模块/1', '轨迹合成/1', 'autorouting', 'on');
add_line(buildModelName, '运动学模块/2', '轨迹合成/2', 'autorouting', 'on');
add_line(buildModelName, '轨迹合成/1', '轨迹图/1', 'autorouting', 'on');
add_line(buildModelName, '轨迹合成/1', '轨迹数据/1', 'autorouting', 'on');

add_line(buildModelName, '左轮模块/3', '左轮力绝对值/1', 'autorouting', 'on');
add_line(buildModelName, '右轮模块/3', '右轮力绝对值/1', 'autorouting', 'on');
add_line(buildModelName, '左轮力绝对值/1', '作用力总和/1', 'autorouting', 'on');
add_line(buildModelName, '右轮力绝对值/1', '作用力总和/2', 'autorouting', 'on');
add_line(buildModelName, '作用力总和/1', '比例分母修正/1', 'autorouting', 'on');

add_line(buildModelName, '左轮力绝对值/1', '左轮比例/1', 'autorouting', 'on');
add_line(buildModelName, '比例分母修正/1', '左轮比例/2', 'autorouting', 'on');
add_line(buildModelName, '右轮力绝对值/1', '右轮比例/1', 'autorouting', 'on');
add_line(buildModelName, '比例分母修正/1', '右轮比例/2', 'autorouting', 'on');

add_line(buildModelName, '左轮模块/3', '作用力比例合成/1', 'autorouting', 'on');
add_line(buildModelName, '右轮模块/3', '作用力比例合成/2', 'autorouting', 'on');
add_line(buildModelName, '左轮比例/1', '作用力比例合成/3', 'autorouting', 'on');
add_line(buildModelName, '右轮比例/1', '作用力比例合成/4', 'autorouting', 'on');
add_line(buildModelName, '作用力比例合成/1', '左右轮作用力比例图/1', 'autorouting', 'on');
add_line(buildModelName, '作用力比例合成/1', '作用力比例数据/1', 'autorouting', 'on');

set_param(buildModelName, 'SimulationCommand', 'update');
renamePortsAndSignals(buildModelName);
try
    Simulink.BlockDiagram.arrangeSystem(buildModelName);
catch
end

save_system(buildModelName, [targetModelName '.slx']);
close_system(buildModelName, 0);
open_system(targetModelName);

try
    simOut = sim(targetModelName);
    exportSimulationData(simOut);
    fprintf('已生成并完成仿真: %s.slx\n', targetModelName);
    fprintf('工作区变量: robot_xy_traj, wheel_force_ratio\n');
    renderSimulationFigures();
catch ME
    warning(ME.identifier, '%s', ['模型已生成，但自动仿真未完成: ' ME.message]);
end
end

function createXYController(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/目标X'], 'Position', [25 35 55 55]);
add_block('simulink/Sources/In1', [sys '/目标Y'], 'Position', [25 85 55 105]);
add_block('simulink/Sources/In1', [sys '/当前X'], 'Position', [25 135 55 155]);
add_block('simulink/Sources/In1', [sys '/当前Y'], 'Position', [25 185 55 205]);
add_block('simulink/Signal Routing/Mux', [sys '/位姿组合'], ...
    'Inputs', '4', ...
    'Position', [95 70 120 170]);
add_block('simulink/User-Defined Functions/Fcn', [sys '/距离误差'], ...
    'Expr', 'sqrt((u(1)-u(3))^2 + (u(2)-u(4))^2)', ...
    'Position', [160 70 270 105]);
add_block('simulink/User-Defined Functions/Fcn', [sys '/目标角度'], ...
    'Expr', 'atan2(u(2)-u(4),u(1)-u(3))', ...
    'Position', [160 130 270 165]);
add_block('simulink/Math Operations/Gain', [sys '/距离增益'], ...
    'Gain', 'ROBOT_XY_GAIN', ...
    'Position', [310 70 365 105]);
add_block('simulink/Discontinuities/Saturation', [sys '/线速度限幅'], ...
    'UpperLimit', '0.8', ...
    'LowerLimit', '-0.8', ...
    'Position', [400 70 465 105]);
add_block('simulink/Sinks/Out1', [sys '/角度指令'], 'Position', [505 135 535 155]);
add_block('simulink/Sinks/Out1', [sys '/线速度指令'], 'Position', [505 75 535 95]);

add_line(sys, '目标X/1', '位姿组合/1', 'autorouting', 'on');
add_line(sys, '目标Y/1', '位姿组合/2', 'autorouting', 'on');
add_line(sys, '当前X/1', '位姿组合/3', 'autorouting', 'on');
add_line(sys, '当前Y/1', '位姿组合/4', 'autorouting', 'on');
add_line(sys, '位姿组合/1', '距离误差/1', 'autorouting', 'on');
add_line(sys, '位姿组合/1', '目标角度/1', 'autorouting', 'on');
add_line(sys, '距离误差/1', '距离增益/1', 'autorouting', 'on');
add_line(sys, '距离增益/1', '线速度限幅/1', 'autorouting', 'on');
add_line(sys, '线速度限幅/1', '线速度指令/1', 'autorouting', 'on');
add_line(sys, '目标角度/1', '角度指令/1', 'autorouting', 'on');
end

function createAngleController(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/目标角度'], 'Position', [25 45 55 65]);
add_block('simulink/Sources/In1', [sys '/航向修正'], 'Position', [25 95 55 115]);
add_block('simulink/Sources/In1', [sys '/当前航向'], 'Position', [25 145 55 165]);
add_block('simulink/Math Operations/Sum', [sys '/修正后角度'], ...
    'Inputs', '++', ...
    'Position', [95 60 130 110]);
add_block('simulink/Math Operations/Sum', [sys '/航向误差'], ...
    'Inputs', '+-', ...
    'Position', [170 75 205 125]);
add_block('simulink/Continuous/PID Controller', [sys '/角度PID'], ...
    'P', 'ROBOT_THETA_KP', ...
    'I', 'ROBOT_THETA_KI', ...
    'D', 'ROBOT_THETA_KD', ...
    'Position', [245 70 325 130]);
add_block('simulink/Discontinuities/Saturation', [sys '/角速度限幅'], ...
    'UpperLimit', '1.5', ...
    'LowerLimit', '-1.5', ...
    'Position', [360 80 425 120]);
add_block('simulink/Sinks/Out1', [sys '/角速度指令'], 'Position', [465 90 495 110]);

add_line(sys, '目标角度/1', '修正后角度/1', 'autorouting', 'on');
add_line(sys, '航向修正/1', '修正后角度/2', 'autorouting', 'on');
add_line(sys, '修正后角度/1', '航向误差/1', 'autorouting', 'on');
add_line(sys, '当前航向/1', '航向误差/2', 'autorouting', 'on');
add_line(sys, '航向误差/1', '角度PID/1', 'autorouting', 'on');
add_line(sys, '角度PID/1', '角速度限幅/1', 'autorouting', 'on');
add_line(sys, '角速度限幅/1', '角速度指令/1', 'autorouting', 'on');
end

function createSpeedSplitter(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/线速度指令'], 'Position', [25 50 55 70]);
add_block('simulink/Sources/In1', [sys '/角速度指令'], 'Position', [25 130 55 150]);
add_block('simulink/Math Operations/Gain', [sys '/线速度转轮速'], ...
    'Gain', '1/ROBOT_WHEEL_RADIUS', ...
    'Position', [100 45 185 75]);
add_block('simulink/Math Operations/Gain', [sys '/转向转轮速'], ...
    'Gain', 'ROBOT_WHEEL_BASE/(2*ROBOT_WHEEL_RADIUS)', ...
    'Position', [100 125 235 155]);
add_block('simulink/Math Operations/Sum', [sys '/左轮参考'], ...
    'Inputs', '+-', ...
    'Position', [285 45 320 85]);
add_block('simulink/Math Operations/Sum', [sys '/右轮参考'], ...
    'Inputs', '++', ...
    'Position', [285 125 320 165]);
add_block('simulink/Sinks/Out1', [sys '/左轮目标角速度'], 'Position', [375 55 405 75]);
add_block('simulink/Sinks/Out1', [sys '/右轮目标角速度'], 'Position', [375 135 405 155]);

add_line(sys, '线速度指令/1', '线速度转轮速/1', 'autorouting', 'on');
add_line(sys, '角速度指令/1', '转向转轮速/1', 'autorouting', 'on');
add_line(sys, '线速度转轮速/1', '左轮参考/1', 'autorouting', 'on');
add_line(sys, '转向转轮速/1', '左轮参考/2', 'autorouting', 'on');
add_line(sys, '线速度转轮速/1', '右轮参考/1', 'autorouting', 'on');
add_line(sys, '转向转轮速/1', '右轮参考/2', 'autorouting', 'on');
add_line(sys, '左轮参考/1', '左轮目标角速度/1', 'autorouting', 'on');
add_line(sys, '右轮参考/1', '右轮目标角速度/1', 'autorouting', 'on');
end

function createWheelModule(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/目标角速度'], 'Position', [25 55 55 75]);
add_block('simulink/Sources/In1', [sys '/负载扰动'], 'Position', [25 125 55 145]);
add_block('simulink/Math Operations/Sum', [sys '/速度误差'], ...
    'Inputs', '+-', ...
    'Position', [100 50 135 90]);
add_block('simulink/Continuous/PID Controller', [sys '/轮速PID'], ...
    'P', 'ROBOT_WHEEL_KP', ...
    'I', 'ROBOT_WHEEL_KI', ...
    'D', 'ROBOT_WHEEL_KD', ...
    'Position', [175 40 255 100]);
add_block('simulink/Math Operations/Sum', [sys '/驱动合成'], ...
    'Inputs', '++', ...
    'Position', [285 45 320 95]);
add_block('simulink/Continuous/Transfer Fcn', [sys '/电机模型'], ...
    'Numerator', 'ROBOT_MOTOR_GAIN', ...
    'Denominator', '[ROBOT_MOTOR_TAU 1]', ...
    'Position', [355 40 445 100]);
add_block('simulink/Math Operations/Gain', [sys '/驱动力换算'], ...
    'Gain', 'ROBOT_FORCE_GAIN', ...
    'Position', [355 125 445 155]);
add_block('simulink/Continuous/Integrator', [sys '/轮子转角'], ...
    'Position', [485 40 515 70]);
add_block('simulink/Sinks/Out1', [sys '/实际角速度'], 'Position', [560 50 590 70]);
add_block('simulink/Sinks/Out1', [sys '/轮子角位移'], 'Position', [560 105 590 125]);
add_block('simulink/Sinks/Out1', [sys '/轮子作用力'], 'Position', [560 140 590 160]);

add_line(sys, '目标角速度/1', '速度误差/1', 'autorouting', 'on');
add_line(sys, '速度误差/1', '轮速PID/1', 'autorouting', 'on');
add_line(sys, '轮速PID/1', '驱动合成/1', 'autorouting', 'on');
add_line(sys, '负载扰动/1', '驱动合成/2', 'autorouting', 'on');
add_line(sys, '驱动合成/1', '电机模型/1', 'autorouting', 'on');
add_line(sys, '电机模型/1', '速度误差/2', 'autorouting', 'on');
add_line(sys, '电机模型/1', '轮子转角/1', 'autorouting', 'on');
add_line(sys, '电机模型/1', '实际角速度/1', 'autorouting', 'on');
add_line(sys, '轮子转角/1', '轮子角位移/1', 'autorouting', 'on');
add_line(sys, '驱动合成/1', '驱动力换算/1', 'autorouting', 'on');
add_line(sys, '驱动力换算/1', '轮子作用力/1', 'autorouting', 'on');
end

function createRotationModule(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/左轮角速度'], 'Position', [25 45 55 65]);
add_block('simulink/Sources/In1', [sys '/右轮角速度'], 'Position', [25 95 55 115]);
add_block('simulink/Sources/In1', [sys '/横向扰动力'], 'Position', [25 160 55 180]);
add_block('simulink/Sources/In1', [sys '/扰动转矩'], 'Position', [25 210 55 230]);

add_block('simulink/Math Operations/Sum', [sys '/轮速求和'], ...
    'Inputs', '++', ...
    'Position', [95 45 130 105]);
add_block('simulink/Math Operations/Sum', [sys '/轮速求差'], ...
    'Inputs', '+-', ...
    'Position', [95 120 130 180]);
add_block('simulink/Math Operations/Gain', [sys '/线速度换算'], ...
    'Gain', 'ROBOT_WHEEL_RADIUS/2', ...
    'Position', [175 55 255 95]);
add_block('simulink/Math Operations/Gain', [sys '/角速度换算'], ...
    'Gain', 'ROBOT_WHEEL_RADIUS/ROBOT_WHEEL_BASE', ...
    'Position', [175 130 270 170]);
add_block('simulink/Math Operations/Gain', [sys '/外力增益'], ...
    'Gain', 'ROBOT_DIST_FORCE_GAIN', ...
    'Position', [175 195 270 225]);
add_block('simulink/Math Operations/Gain', [sys '/外转矩增益'], ...
    'Gain', 'ROBOT_DIST_TORQUE_GAIN', ...
    'Position', [175 245 285 275]);
add_block('simulink/Math Operations/Sum', [sys '/受扰角速度'], ...
    'Inputs', '++', ...
    'Position', [315 125 350 175]);

add_block('simulink/Continuous/Integrator', [sys '/航向角'], ...
    'InitialCondition', '0', ...
    'Position', [585 125 615 155]);
add_block('simulink/Math Operations/Trigonometric Function', [sys '/cos航向'], ...
    'Operator', 'cos', ...
    'Position', [345 205 395 235]);
add_block('simulink/Math Operations/Trigonometric Function', [sys '/sin航向'], ...
    'Operator', 'sin', ...
    'Position', [345 255 395 285]);
add_block('simulink/Math Operations/Product', [sys '/X速度'], ...
    'Inputs', '**', ...
    'Position', [435 195 465 235]);
add_block('simulink/Math Operations/Product', [sys '/Y速度'], ...
    'Inputs', '**', ...
    'Position', [435 255 465 295]);
add_block('simulink/Math Operations/Sum', [sys '/受扰X速度'], ...
    'Inputs', '++', ...
    'Position', [505 195 540 235]);
add_block('simulink/Math Operations/Sum', [sys '/受扰Y速度'], ...
    'Inputs', '++', ...
    'Position', [505 255 540 295]);
add_block('simulink/Continuous/Integrator', [sys '/X位置'], ...
    'InitialCondition', '0', ...
    'Position', [585 205 615 235]);
add_block('simulink/Continuous/Integrator', [sys '/Y位置'], ...
    'InitialCondition', '0', ...
    'Position', [585 265 615 295]);

add_block('simulink/Sinks/Out1', [sys '/X输出'], 'Position', [675 210 705 230]);
add_block('simulink/Sinks/Out1', [sys '/Y输出'], 'Position', [675 270 705 290]);
add_block('simulink/Sinks/Out1', [sys '/航向输出'], 'Position', [675 130 705 150]);
add_block('simulink/Sinks/Out1', [sys '/线速度输出'], 'Position', [310 65 340 85]);
add_block('simulink/Sinks/Out1', [sys '/角速度输出'], 'Position', [310 140 340 160]);

add_line(sys, '左轮角速度/1', '轮速求和/1', 'autorouting', 'on');
add_line(sys, '右轮角速度/1', '轮速求和/2', 'autorouting', 'on');
add_line(sys, '右轮角速度/1', '轮速求差/1', 'autorouting', 'on');
add_line(sys, '左轮角速度/1', '轮速求差/2', 'autorouting', 'on');
add_line(sys, '轮速求和/1', '线速度换算/1', 'autorouting', 'on');
add_line(sys, '轮速求差/1', '角速度换算/1', 'autorouting', 'on');
add_line(sys, '横向扰动力/1', '外力增益/1', 'autorouting', 'on');
add_line(sys, '扰动转矩/1', '外转矩增益/1', 'autorouting', 'on');
add_line(sys, '角速度换算/1', '受扰角速度/1', 'autorouting', 'on');
add_line(sys, '外转矩增益/1', '受扰角速度/2', 'autorouting', 'on');

add_line(sys, '线速度换算/1', '线速度输出/1', 'autorouting', 'on');
add_line(sys, '受扰角速度/1', '角速度输出/1', 'autorouting', 'on');
add_line(sys, '受扰角速度/1', '航向角/1', 'autorouting', 'on');

add_line(sys, '航向角/1', '航向输出/1', 'autorouting', 'on');
add_line(sys, '航向角/1', 'cos航向/1', 'autorouting', 'on');
add_line(sys, '航向角/1', 'sin航向/1', 'autorouting', 'on');

add_line(sys, '线速度换算/1', 'X速度/1', 'autorouting', 'on');
add_line(sys, 'cos航向/1', 'X速度/2', 'autorouting', 'on');
add_line(sys, '线速度换算/1', 'Y速度/1', 'autorouting', 'on');
add_line(sys, 'sin航向/1', 'Y速度/2', 'autorouting', 'on');
add_line(sys, 'X速度/1', '受扰X速度/1', 'autorouting', 'on');
add_line(sys, '外力增益/1', '受扰X速度/2', 'autorouting', 'on');
add_line(sys, 'Y速度/1', '受扰Y速度/1', 'autorouting', 'on');
add_line(sys, '外力增益/1', '受扰Y速度/2', 'autorouting', 'on');

add_line(sys, '受扰X速度/1', 'X位置/1', 'autorouting', 'on');
add_line(sys, 'X位置/1', 'X输出/1', 'autorouting', 'on');
add_line(sys, '受扰Y速度/1', 'Y位置/1', 'autorouting', 'on');
add_line(sys, 'Y位置/1', 'Y输出/1', 'autorouting', 'on');
end

function createSensorModule(sys)
open_system(sys);
add_block('simulink/Sources/In1', [sys '/当前X'], 'Position', [25 45 55 65]);
add_block('simulink/Sources/In1', [sys '/当前Y'], 'Position', [25 105 55 125]);
add_block('simulink/Sources/In1', [sys '/当前航向'], 'Position', [25 165 55 185]);
add_block('simulink/Signal Routing/Mux', [sys '/位姿组合'], ...
    'Inputs', '3', ...
    'Position', [90 70 115 180]);
add_block('simulink/User-Defined Functions/Fcn', [sys '/目标距离'], ...
    'Expr', 'sqrt((u(1)-ROBOT_TARGET_X)^2 + (u(2)-ROBOT_TARGET_Y)^2)', ...
    'Position', [155 110 300 145]);
add_block('simulink/Logic and Bit Operations/Compare To Constant', [sys '/距离阈值判断'], ...
    'const', 'ROBOT_SENSOR_THRESHOLD', ...
    'relop', '<=', ...
    'Position', [340 110 430 145]);
add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/二值输出转换'], ...
    'OutDataTypeStr', 'double', ...
    'Position', [465 110 555 145]);

add_block('simulink/Sinks/Out1', [sys '/左红外'], 'Position', [590 45 620 65]);
add_block('simulink/Sinks/Out1', [sys '/前红外'], 'Position', [590 105 620 125]);
add_block('simulink/Sinks/Out1', [sys '/右红外'], 'Position', [590 165 620 185]);
add_block('simulink/Sinks/Out1', [sys '/超声'], 'Position', [590 225 620 245]);

add_line(sys, '当前X/1', '位姿组合/1', 'autorouting', 'on');
add_line(sys, '当前Y/1', '位姿组合/2', 'autorouting', 'on');
add_line(sys, '当前航向/1', '位姿组合/3', 'autorouting', 'on');

add_line(sys, '位姿组合/1', '目标距离/1', 'autorouting', 'on');
add_line(sys, '目标距离/1', '距离阈值判断/1', 'autorouting', 'on');
add_line(sys, '距离阈值判断/1', '二值输出转换/1', 'autorouting', 'on');
add_line(sys, '二值输出转换/1', '左红外/1', 'autorouting', 'on');
add_line(sys, '二值输出转换/1', '前红外/1', 'autorouting', 'on');
add_line(sys, '二值输出转换/1', '右红外/1', 'autorouting', 'on');
add_line(sys, '二值输出转换/1', '超声/1', 'autorouting', 'on');
end

function renamePortsAndSignals(modelName)
set_param([modelName '/XY控制器'], 'AttributesFormatString', '输出: 角度指令, 线速度指令');
set_param([modelName '/角度控制器'], 'AttributesFormatString', '输出: 角速度指令');
set_param([modelName '/分速度模块'], 'AttributesFormatString', '输出: 左右轮目标角速度');
set_param([modelName '/左轮模块'], 'AttributesFormatString', '输入: 目标角速度, 负载扰动; 输出: 角速度, 角位移, 作用力');
set_param([modelName '/右轮模块'], 'AttributesFormatString', '输入: 目标角速度, 负载扰动; 输出: 角速度, 角位移, 作用力');
set_param([modelName '/运动学模块'], 'AttributesFormatString', '输入: 左轮, 右轮, 外力, 转矩; 输出: X, Y, 航向, v, w');
set_param([modelName '/传感器模块'], 'AttributesFormatString', '输出: 左红外, 前红外, 右红外, 超声');
end

function exportSimulationData(simOut)
if isa(simOut, 'Simulink.SimulationOutput')
    if isprop(simOut, 'robot_xy_traj')
        assignin('base', 'robot_xy_traj', simOut.robot_xy_traj);
    elseif hasVariable(simOut, 'robot_xy_traj')
        assignin('base', 'robot_xy_traj', simOut.get('robot_xy_traj'));
    end

    if isprop(simOut, 'wheel_force_ratio')
        assignin('base', 'wheel_force_ratio', simOut.wheel_force_ratio);
    elseif hasVariable(simOut, 'wheel_force_ratio')
        assignin('base', 'wheel_force_ratio', simOut.get('wheel_force_ratio'));
    end
end
end

function tf = hasVariable(simOut, varName)
tf = false;
try
    simOut.get(varName);
    tf = true;
catch
end
end

function renderSimulationFigures()
if evalin('base', 'exist(''robot_xy_traj'', ''var'')')
    traj = evalin('base', 'robot_xy_traj');
    [xData, yData] = parseTrajectoryData(traj);
    if ~isempty(xData) && ~isempty(yData)
        figure('Name', '差速双轮机器人轨迹图', 'NumberTitle', 'off');
        plot(xData, yData, 'b-', 'LineWidth', 2);
        hold on;
        plot(xData(1), yData(1), 'go', 'MarkerSize', 8, 'LineWidth', 1.5);
        plot(xData(end), yData(end), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
        grid on;
        axis equal;
        xlabel('X 位置 / m');
        ylabel('Y 位置 / m');
        title('差速双轮机器人运动轨迹');
        legend('运动轨迹', '起点', '终点', 'Location', 'best');
        hold off;
    end
end

if evalin('base', 'exist(''wheel_force_ratio'', ''var'')')
    ratioData = evalin('base', 'wheel_force_ratio');
    [t, ratioValues] = parseWorkspaceSignal(ratioData);
    if ~isempty(ratioValues) && size(ratioValues, 2) >= 4
        if isempty(t)
            n = size(ratioValues, 1);
            t = linspace(0, 20, n)';
        end
        figure('Name', '左右轮作用力与比例图', 'NumberTitle', 'off');
        yyaxis left;
        plot(t, ratioValues(:, 1), 'b-', 'LineWidth', 1.5);
        hold on;
        plot(t, ratioValues(:, 2), 'r-', 'LineWidth', 1.5);
        ylabel('轮子作用力');
        yyaxis right;
        plot(t, ratioValues(:, 3), 'b--', 'LineWidth', 1.5);
        plot(t, ratioValues(:, 4), 'r--', 'LineWidth', 1.5);
        ylabel('作用力比例');
        xlabel('时间 / s');
        title('左右轮作用力及其比例变化');
        grid on;
        legend('左轮作用力', '右轮作用力', '左轮比例', '右轮比例', 'Location', 'best');
        hold off;
    end
end
end

function [xData, yData] = parseTrajectoryData(traj)
xData = [];
yData = [];
[~, values] = parseWorkspaceSignal(traj);
if isempty(values)
    return;
end
if size(values, 2) >= 2
    xData = values(:, 1);
    yData = values(:, 2);
elseif size(values, 2) >= 3
    xData = values(:, 2);
    yData = values(:, 3);
end
end

function [t, values] = parseWorkspaceSignal(data)
t = [];
values = [];

if isnumeric(data)
    if isempty(data)
        return;
    end
    if size(data, 2) >= 3
        t = data(:, 1);
        values = data(:, 2:end);
    else
        values = data;
    end
    return;
end

if isstruct(data) && isfield(data, 'time') && isfield(data, 'signals')
    t = data.time;
    if isfield(data.signals, 'values')
        values = data.signals.values;
        if ndims(values) > 2
            values = squeeze(values);
        end
    end
end
end
