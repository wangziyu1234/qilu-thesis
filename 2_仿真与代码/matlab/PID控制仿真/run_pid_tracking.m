%% run_pid_tracking.m
% 运行双轮差速PID控制仿真
% 配置目标点、PID参数，运行仿真并绘制结果

clear; clc;

model_name = 'diff_drive_robot_pid_system';

%% 检查模型是否存在，不存在则构建
if ~bdIsLoaded(model_name)
    if exist([model_name '.slx'], 'file')
        open_system(model_name);
    else
        disp('模型文件不存在，正在构建...');
        build_diffdrive_pid_model;
    end
end

%% ========== 仿真参数配置 ==========

% 机器人物理参数
r  = 0.075;    % 轮半径 (m)
L  = 0.52;     % 轮距 (m)
mw = 2.5;      % 单轮等效质量 (kg)

% 目标点坐标
target_x = 5.0;
target_y = 5.0;

% 设置目标位置
set_param([model_name '/Target X'], 'Value', num2str(target_x));
set_param([model_name '/Target Y'], 'Value', num2str(target_y));

% PID 参数
Kp_angle = 1.5;   % 角度环比例
Ki_angle = 0.1;   % 角度环积分
Kd_angle = 0.05;  % 角度环微分

Kp_speed = 3.0;   % 速度环比例
Ki_speed = 0.5;   % 速度环积分
Kd_speed = 0.0;   % 速度环微分

Kp_pos = 0.8;     % 位置-速度比例

% 更新 PID 参数
set_param([model_name '/PID Control System/Angle PID'], ...
    'P', num2str(Kp_angle), 'I', num2str(Ki_angle), 'D', num2str(Kd_angle));
set_param([model_name '/PID Control System/Speed PID'], ...
    'P', num2str(Kp_speed), 'I', num2str(Ki_speed), 'D', num2str(Kd_speed));
set_param([model_name '/PID Control System/Kp_pos'], ...
    'Gain', num2str(Kp_pos));

% 速度饱和
set_param([model_name '/PID Control System/Sat_v'], ...
    'UpperLimit', '0.5', 'LowerLimit', '0');

% 力饱和
set_param([model_name '/PID Control System/Sat_FL'], ...
    'UpperLimit', '15', 'LowerLimit', '-15');
set_param([model_name '/PID Control System/Sat_FR'], ...
    'UpperLimit', '15', 'LowerLimit', '-15');

% 仿真时间
sim_time = 30;
set_param(model_name, 'StopTime', num2str(sim_time));
set_param(model_name, 'Solver', 'ode45');
set_param(model_name, 'MaxStep', '0.01');

%% ========== 运行仿真 ==========
disp('========================================');
disp('  双轮差速PID控制仿真');
disp('========================================');
fprintf('目标位置: (%.1f, %.1f)\n', target_x, target_y);
fprintf('仿真时间: %d 秒\n', sim_time);
fprintf('角度PID: P=%.2f, I=%.2f, D=%.2f\n', Kp_angle, Ki_angle, Kd_angle);
fprintf('速度PID: P=%.2f, I=%.2f, D=%.2f\n', Kp_speed, Ki_speed, Kd_speed);
disp('----------------------------------------');

% 记录仿真数据（需要配置数据日志或使用输出端口）
% 方式1：使用 To Workspace 模块（需要在模型中添加）
% 方式2：使用 simout 输出

% 运行仿真
simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');

%% ========== 从 Scope 读取数据并绘图 ==========

% 获取 Scope 数据
scope_names = {'Scope_Force', 'Scope_vx', 'Scope_x', 'Scope_y', 'Scope_Sensor'};
scope_labels = {'合力 (作用力合力)', '横轴速度分量 vx (m/s)', ...
                '横坐标 x (m)', '纵坐标 y (m)', '感应值 sensor'};

figure('Color', 'w', 'Name', 'PID控制仿真结果', 'Position', [100, 100, 900, 700]);

for i = 1:5
    scope_path = [model_name '/' scope_names{i}];
    try
        % 尝试获取 scope 数据
        scope_conf = get_param(scope_path, 'ScopeConfiguration');
        if isa(scope_conf, 'Simulink.scopes.ScopeBlockStrategy')
            % 新版本 scope
            dataSet = scope_conf.DataLogging;
            if ~isempty(dataSet)
                subplot(3, 2, i);
                % 用 simlog 获取数据
            end
        end
    catch
        % 如果无法获取 scope 数据，使用备用方法
    end
end

% 由于 Scope 数据提取依赖版本，提供备用绘图方式
% 使用 To Workspace 或 Output 端口替代

disp('----------------------------------------');
disp('仿真完成！请在 Simulink 中查看示波器和 XY Graph。');
disp('或者使用以下方式查看结果：');
disp('  1. 双击打开各 Scope 模块');
disp('  2. 双击 XY Graph 查看运动轨迹');
disp('  3. 在 Simulink 工具栏点击 Data Inspector');

%% ========== 备用：直接通过 MATLAB 仿真验证 ==========
% 如果不依赖 Simulink 可视化，可运行以下纯数值仿真

run_standalone = false;  % 设为 true 运行独立仿真

if run_standalone
    disp('运行独立数值仿真...');

    % 初始状态
    x0 = [0; 0; 0];  % [x, y, theta]
    vx = 0; vy = 0;

    dt = 0.01;
    t = 0:dt:sim_time;
    N = length(t);

    % 存储
    x_hist = zeros(1, N); y_hist = zeros(1, N);
    theta_hist = zeros(1, N);
    v_hist = zeros(1, N); omega_hist = zeros(1, N);
    FL_hist = zeros(1, N); FR_hist = zeros(1, N);

    % PID 积分项
    int_angle = 0; int_speed = 0;
    prev_angle_err = 0; prev_speed_err = 0;

    for k = 1:N
        x_hist(k) = x0(1); y_hist(k) = x0(2); theta_hist(k) = x0(3);

        % 当前实际速度
        v_actual = hypot(vx, vy);
        v_hist(k) = v_actual;

        % XY 控制器：计算期望航向和速度
        dx = target_x - x0(1);
        dy = target_y - x0(2);
        dist = hypot(dx, dy);
        theta_des = atan2(dy, dx);
        v_des = min(0.5, Kp_pos * dist);
        if dist < 0.05
            v_des = 0;
        end

        % 角度 PID
        angle_err = atan2(sin(theta_des - x0(3)), cos(theta_des - x0(3)));
        int_angle = int_angle + angle_err * dt;
        d_angle = (angle_err - prev_angle_err) / dt;
        omega_correction = Kp_angle * angle_err + Ki_angle * int_angle + Kd_angle * d_angle;
        omega_correction = max(-2, min(2, omega_correction));
        prev_angle_err = angle_err;

        % 速度 PID
        speed_err = v_des - v_actual;
        int_speed = int_speed + speed_err * dt;
        d_speed = (speed_err - prev_speed_err) / dt;
        F_base = Kp_speed * speed_err + Ki_speed * int_speed + Kd_speed * d_speed;
        F_base = max(-10, min(10, F_base));
        prev_speed_err = speed_err;

        % 力混合
        FL = F_base - omega_correction * (L/2);
        FR = F_base + omega_correction * (L/2);
        FL = max(-15, min(15, FL));
        FR = max(-15, min(15, FR));
        FL_hist(k) = FL; FR_hist(k) = FR;

        % 机器人动力学
        vL = FL / mw * dt;  % 简化：直接积分
        vR = FR / mw * dt;

        v = (vL + vR) / 2;
        omega = (vR - vL) / L;
        omega_hist(k) = omega;

        % 更新状态
        vx = v * cos(x0(3));
        vy = v * sin(x0(3));
        x0(1) = x0(1) + vx * dt;
        x0(2) = x0(2) + vy * dt;
        x0(3) = x0(3) + omega * dt;
    end

    % 绘图
    figure('Color', 'w', 'Name', 'PID控制仿真结果（独立数值仿真）', 'Position', [100, 100, 1000, 750]);

    subplot(2,3,1); plot(t, FL_hist, 'b', t, FR_hist, 'r', 'LineWidth', 1.2);
    grid on; xlabel('时间 (s)'); ylabel('力 (N)');
    legend('F_L', 'F_R'); title('左右轮作用力');

    subplot(2,3,2); plot(t, v_hist, 'LineWidth', 1.5);
    grid on; xlabel('时间 (s)'); ylabel('速度 (m/s)');
    title('横轴速度分量 (线速度)');

    subplot(2,3,3); plot(t, x_hist, 'LineWidth', 1.5);
    grid on; xlabel('时间 (s)'); ylabel('x (m)');
    title('横坐标 x');

    subplot(2,3,4); plot(t, y_hist, 'LineWidth', 1.5);
    grid on; xlabel('时间 (s)'); ylabel('y (m)');
    title('纵坐标 y');

    subplot(2,3,5); plot(t, omega_hist, 'LineWidth', 1.5);
    grid on; xlabel('时间 (s)'); ylabel('\omega (rad/s)');
    title('角速度 (感应值)');

    subplot(2,3,6); plot(x_hist, y_hist, 'b-', 'LineWidth', 1.5); hold on;
    plot(target_x, target_y, 'r*', 'MarkerSize', 12, 'LineWidth', 2);
    plot(x_hist(1), y_hist(1), 'go', 'MarkerSize', 8, 'LineWidth', 1.5);
    grid on; axis equal; xlabel('x (m)'); ylabel('y (m)');
    legend('轨迹', '目标点', '起点');
    title('机器人运动轨迹 (XY图)');

    fprintf('终点位置: (%.3f, %.3f)\n', x_hist(end), y_hist(end));
    fprintf('终点航向: %.2f°\n', rad2deg(theta_hist(end)));
    fprintf('目标位置: (%.1f, %.1f)\n', target_x, target_y);
    fprintf('位置误差: %.3f m\n', hypot(target_x-x_hist(end), target_y-y_hist(end)));
end

disp('========================================');
disp('  仿真结束');
disp('========================================');
