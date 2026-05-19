%% 红外传感器PID循迹仿真
function line_following_pid(ref_path)
if nargin < 1  % 无输入参数时使用默认椭圆路径
    t = linspace(0, 3.5*pi, 200);  % 参数t从0到3.5π取200个点
    ref_path = [2 + 1.5*cos(t)', 2 + 0.8*sin(t)', ...  % 生成椭圆参考路径[x,y,θ]
                atan2(0.8*cos(t), -1.5*sin(t))'];
end

%% ==================== 1. 机器人参数设置 ====================
r_wheel = 0.09;  % 车轮半径0.09m
L_base  = 0.52;  % 两轮轮距0.52m
v_nom   = 0.3;  % 标称行驶速度0.3m/s

n_sensors  = 5;  % 红外传感器数量5个
sensor_spacing = 0.04;  % 相邻传感器间距0.04m
sensor_offsets = (-2:2) * sensor_spacing;  % 5个传感器的横向偏移[-0.08,-0.04,0,0.04,0.08]m
line_width = 0.03;  % 黑线检测宽度0.03m

Kp = 3.0;  % PID比例增益
Ki = 0.08;  % PID积分增益
Kd = 1.0;  % PID微分增益

dt       = 0.01;  % 仿真步长0.01s
max_time = 80;  % 最大仿真时长80s

%% ==================== 2. 参考路径预处理 ====================
ref_x = ref_path(:, 1);  % 提取参考路径x坐标序列
ref_y = ref_path(:, 2);  % 提取参考路径y坐标序列
n_ref = size(ref_path, 1);  % 参考路径总点数
path_len = sum(hypot(diff(ref_x), diff(ref_y)));  % 计算路径总长度

fprintf('\n========== PID 循迹仿真 ==========\n');  % 打印标题
fprintf('参考路径: %d 点, %.2f m\n', n_ref, path_len);  % 打印路径信息

%% ==================== 3. 仿真主循环 ====================
n_steps = ceil(max_time / dt);  % 最大仿真步数
log = zeros(n_steps, 7);  % 预分配日志矩阵，列：[t,x,y,θ,v,ω,横向误差]

x = ref_x(1);  % 初始x坐标
y = ref_y(1);  % 初始y坐标
theta = ref_path(1, 3);  % 初始航向角
e_int = 0;  % PID积分项初值
e_prev = 0;  % 上一时刻偏移量初值

for k = 1:n_steps  % 主仿真循环
    t_now = (k-1) * dt;  % 当前仿真时间

    fwd = 0.08;  % 传感器阵列安装在车体前方0.08m处
    sx = x + fwd*cos(theta) + sensor_offsets * cos(theta + pi/2);  % 5个传感器在全局坐标系的x坐标
    sy = y + fwd*sin(theta) + sensor_offsets * sin(theta + pi/2);  % 5个传感器在全局坐标系的y坐标

    sensor_state = zeros(1, n_sensors);  % 初始化传感器状态，0=未检测到，1=检测到黑线
    for s = 1:n_sensors  % 遍历5个传感器
        d = point_to_path(sx(s), sy(s), ref_x, ref_y);  % 计算传感器到参考路径的最短距离
        if d < line_width  % 距离小于线宽则认为检测到黑线
            sensor_state(s) = 1;  % 标记该传感器检测到黑线
        end
    end

    weights = -4:2:4;  % 传感器权重：左侧为负、中间为零、右侧为正
    active = find(sensor_state == 1);  % 找出检测到黑线的传感器编号

    if ~isempty(active)  % 有传感器检测到黑线
        offset = mean(weights(active));  % 加权平均计算偏移量
    else  % 丢线情况
        offset = e_prev * 1.5;  % 外推上一拍偏移量并放大，加大纠偏力矩
    end

    [~, min_i] = min((ref_x - x).^2 + (ref_y - y).^2);  % 找参考路径上距小车最近的点
    tang = ref_path(min_i, 3);  % 该最近点的切线方向
    lat_err = -(x - ref_x(min_i))*sin(tang) + (y - ref_y(min_i))*cos(tang);  % 计算法向横向误差

    e_int = e_int + offset * dt;  % 积分项累加
    e_int = max(-2, min(2, e_int));  % 积分抗饱和，限幅±2
    e_der = (offset - e_prev) / dt;  % 微分项计算
    e_prev = offset;  % 保存本拍偏移量供下一拍使用

    omega = Kp * offset + Ki * e_int + Kd * e_der;  % PID控制器输出角速度
    omega = max(-1.5, min(1.5, omega));  % 角速度限幅±1.5rad/s

    x     = x + v_nom * cos(theta) * dt;  % x坐标欧拉更新
    y     = y + v_nom * sin(theta) * dt;  % y坐标欧拉更新
    theta = theta + omega * dt;  % 航向角更新
    theta = atan2(sin(theta), cos(theta));  % 航向角归一化到[-π,π]

    log(k, :) = [t_now, x, y, theta, v_nom, omega, lat_err];  % 记录本步数据到日志

    if hypot(x - ref_x(end), y - ref_y(end)) < 0.2  % 距终点小于0.2m
        fprintf('到达终点! t = %.1f s\n', t_now);  % 打印到达时间
        log = log(1:k, :);  % 截断日志
        break;  % 结束仿真
    end
end

%% ==================== 4. 性能指标计算 ====================
rms_err  = sqrt(mean(log(:,7).^2));  % 横向误差均方根值RMS
max_err  = max(abs(log(:,7)));  % 最大绝对横向误差
final_t  = log(end, 1);  % 仿真实际耗时

fprintf('RMS 横向误差:  %.4f m (%.1f cm)\n', rms_err, rms_err*100);  % 打印RMS误差
fprintf('最大横向误差:  %.4f m (%.1f cm)\n', max_err, max_err*100);  % 打印最大误差
fprintf('仿真时长:      %.1f s\n', final_t);  % 打印仿真时长

%% ==================== 5. 结果可视化 ====================

figure('Color', 'w', 'Position', [50, 80, 700, 550]);  % 创建轨迹对比图
plot(ref_x, ref_y, 'b-', 'LineWidth', 2); hold on;  % 参考路径蓝色实线
plot(log(:,2), log(:,3), 'r--', 'LineWidth', 1.2);  % 实际循迹轨迹红色虚线
plot(ref_x(1), ref_y(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);  % 起点绿色圆点
plot(ref_x(end), ref_y(end), 'rx', 'MarkerSize', 10, 'LineWidth', 2);  % 终点红色叉号
grid on; axis equal;  % 网格、等比例
xlabel('X (m)'); ylabel('Y (m)');  % 坐标轴标签
title('参考路径 vs 循迹轨迹');  % 图标题
legend('参考', '循迹', '起点', '终点', 'Location', 'best');  % 图例
saveas(gcf, 'line_following_traj.png');  % 保存图片
fprintf('已保存: line_following_traj.png\n');  % 打印保存信息

figure('Color', 'w', 'Position', [100, 100, 800, 450]);  % 创建横向误差图
plot(log(:,1), log(:,7)*100, 'r-', 'LineWidth', 1); hold on;  % 横向误差曲线（单位cm）
yline( rms_err*100, 'b--', sprintf('RMS=%.1fcm', rms_err*100));  % RMS误差参考线
yline(-rms_err*100, 'b--');  % 负RMS参考线
yline( line_width*100, 'g:');  % 正线宽边界
yline(-line_width*100, 'g:');  % 负线宽边界
grid on; xlabel('时间 (s)'); ylabel('误差 (cm)');  % 坐标轴标签
title('循迹横向误差');  % 图标题
saveas(gcf, 'line_following_error.png');  % 保存图片
fprintf('已保存: line_following_error.png\n');  % 打印保存信息

figure('Color', 'w', 'Position', [150, 120, 800, 450]);  % 创建角速度指令图
omg_rms = sqrt(mean(log(:,6).^2));  % 角速度RMS值
plot(log(:,1), log(:,6), 'r-', 'LineWidth', 1); hold on;  % 角速度曲线
yline( omg_rms, 'b--', sprintf('RMS=%.2f rad/s', omg_rms));  % 正RMS参考线
yline(-omg_rms, 'b--');  % 负RMS参考线
yline(0, 'k:');  % 零线
grid on; xlabel('时间 (s)'); ylabel('\omega (rad/s)');  % 坐标轴标签
title('纠偏角速度指令');  % 图标题
legend('角速度指令', 'Location', 'best');  % 图例
saveas(gcf, 'line_following_omega.png');  % 保存图片
fprintf('已保存: line_following_omega.png\n');  % 打印保存信息

figure('Color', 'w', 'Position', [200, 140, 400, 350]);  % 创建传感器布局示意图
hold on; grid on; axis equal;  % 保持绘图、网格、等比例
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, ...  % 绘制车体轮廓矩形
          'EdgeColor', 'b', 'LineWidth', 2);
for s = 1:n_sensors  % 绘制5个传感器标记
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');  % 红色方块标记传感器
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);  % 传感器阵列连线
xlabel('横向 (m)'); ylabel('纵向 (m)');  % 坐标轴标签
title('5路红外传感器布局');  % 图标题
saveas(gcf, 'sensor_layout.png');  % 保存图片
fprintf('已保存: sensor_layout.png\n');  % 打印保存信息
end

%% 计算点到多段线的最短距离
function d = point_to_path(px, py, path_x, path_y)
    d = inf;  % 初始最短距离设为无穷大
    n = length(path_x);  % 路径点数
    for i = 1:n-1  % 遍历每一段线段
        ax = path_x(i);   ay = path_y(i);  % 线段起点坐标
        bx = path_x(i+1); by = path_y(i+1);  % 线段终点坐标
        abx = bx-ax;  aby = by-ay;  % 线段向量
        apx = px-ax;  apy = py-ay;  % 点到起点的向量
        ab2 = abx^2 + aby^2;  % 线段长度的平方
        if ab2 < 1e-10  % 线段长度近似为零
            t = 0;  % 投影参数取0
        else
            t = max(0, min(1, (apx*abx+apy*aby)/ab2));  % 投影参数，截断到[0,1]区间
        end
        cx = ax + t*abx;  % 投影点x坐标
        cy = ay + t*aby;  % 投影点y坐标
        d = min(d, hypot(px-cx, py-cy));  % 更新最短距离
    end
end
