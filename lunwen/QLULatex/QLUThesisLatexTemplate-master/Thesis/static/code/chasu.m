%% 差速机器人典型轨迹运动学仿真
clear; clc; close all;  % 清空工作区、命令行、关闭图形窗口

r = 0.09;  % 车轮半径0.09m
L = 0.52;  % 两轮轮距0.52m
dt = 0.01;  % 欧拉积分步长0.01s
T = 20;  % 仿真总时长20s
t = 0:dt:T;  % 生成时间向量

x0 = [0; 0; 0];  % 初始位姿，[x坐标; y坐标; 航向角]，原点起始

%% 定义四种典型轨迹的控制输入
cases = {  % 用元胞数组存储四种轨迹的参数
    struct('name', '直线轨迹',    'color', [0.00,0.45,0.74], 'u', @(tt) deal(0.45+0*tt, 0*tt)), ...  % v=0.45m/s, ω=0
    struct('name', '定曲率圆轨迹', 'color', [0.85,0.33,0.10], 'u', @(tt) deal(0.35+0*tt, 0.45+0*tt)), ...  % v=0.35, ω=0.45
    struct('name', 'S形轨迹',     'color', [0.47,0.67,0.19], 'u', @(tt) deal(0.40+0*tt, 0.6*sin(0.5*tt))), ...  % 正弦转向
    struct('name', '8字轨迹',     'color', [0.49,0.18,0.56], 'u', @(tt) deal(0.38+0*tt, 0.7*sin(0.7*tt))) ...  % 高频正弦转向
    };

Ncase = numel(cases);  % 轨迹种类数量
results = cell(Ncase, 1);  % 预分配元胞数组存储各组仿真结果

for i = 1:Ncase  % 遍历每种轨迹进行仿真
    [v_cmd, omega_cmd] = cases{i}.u(t(1:end-1));  % 提取线速度和角速度指令序列
    sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L);  % 调用差速运动学正解函数
    sim.name = cases{i}.name;  % 存储轨迹名称
    sim.color = cases{i}.color;  % 存储绘图颜色
    sim.metrics = analyze_metrics(sim, dt);  % 计算运动学性能指标
    results{i} = sim;  % 存入结果数组
end

%% 绘制四种轨迹的XY平面对比图
figure('Color', 'w', 'Name', '差速机器人典型轨迹对比');  % 创建白色背景图窗
hold on; grid on; axis equal;  % 保持绘图、显示网格、等比例坐标
xlabel('x (m)'); ylabel('y (m)');  % 坐标轴标签
title('典型轨迹对比');  % 图标题

for i = 1:Ncase  % 遍历四种轨迹绘制
    s = results{i};  % 取出第i组仿真结果
    plot(s.x, s.y, 'LineWidth', 2.0, 'Color', s.color, 'DisplayName', s.name);  % 绘制轨迹线
    plot(s.x(1), s.y(1), 'o', 'Color', s.color, 'MarkerFaceColor', s.color);  % 起点用实心圆标记
    plot(s.x(end), s.y(end), 's', 'Color', s.color, 'MarkerFaceColor', s.color);  % 终点用实心方块标记
end
legend('Location', 'best');  % 显示图例，自动选择最佳位置

%% 绘制控制输入与轮速时间曲线
figure('Color', 'w', 'Name', '控制输入与轮速曲线');  % 创建新图窗
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');  % 3行1列紧凑布局

nexttile;  % 第1个子图：线速度指令
hold on; grid on;  % 保持绘图、显示网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};  % 取出仿真结果
    plot(s.t(1:end-1), s.v_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制线速度曲线
end
ylabel('v (m/s)'); title('线速度指令');  % Y轴标签和标题
legend('Location', 'best');  % 图例

nexttile;  % 第2个子图：角速度指令
hold on; grid on;  % 保持绘图、显示网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};  % 取出仿真结果
    plot(s.t(1:end-1), s.omega_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制角速度曲线
end
ylabel('\omega (rad/s)'); title('角速度指令');  % Y轴标签和标题

nexttile;  % 第3个子图：左右轮角速度
hold on; grid on;  % 保持绘图、显示网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};  % 取出仿真结果
    plot(s.t(1:end-1), s.wr, '-', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 右轮']);  % 右轮实线
    plot(s.t(1:end-1), s.wl, '--', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 左轮']);  % 左轮虚线
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');  % 标签和标题

%% 绘制瞬时曲率对比图
figure('Color', 'w', 'Name', '曲率变化曲线');  % 创建新图窗
hold on; grid on;  % 保持绘图、显示网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};  % 取出仿真结果
    plot(s.t(1:end-1), s.kappa, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制曲率曲线
end
xlabel('时间 (s)'); ylabel('\kappa (1/m)');  % 坐标轴标签
title('瞬时曲率 (\kappa = \omega / v)');  % 图标题，κ=ω/v
legend('Location', 'best');  % 图例

%% 四种轨迹同步动画播放
export_gif = false;  % 是否导出GIF动画（false=仅播放不导出）
gif_dir = 'animation_output';  % GIF输出目录名
gif_file = fullfile(gif_dir, '四轨迹同步动画.gif');  % GIF文件完整路径

if export_gif && ~exist(gif_dir, 'dir')  % 如需导出且目录不存在
    mkdir(gif_dir);  % 创建输出目录
end

fig_anim = figure('Color', 'w', 'Name', '小车运动动画 - 四轨迹同步');  % 创建动画图窗
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');  % 2×2子图紧凑布局

car_r = 0.10;  % 车体圆盘半径0.10m
car_outline_x = car_r * cos(linspace(0, 2*pi, 50));  % 圆盘轮廓X坐标（50个点）
car_outline_y = car_r * sin(linspace(0, 2*pi, 50));  % 圆盘轮廓Y坐标（50个点）
heading_len = 0.18;  % 航向指示箭头长度0.18m
margin = 0.3;  % 坐标轴边距0.3m

car_body = gobjects(Ncase, 1);  % 预分配车体圆盘图形句柄
car_center = gobjects(Ncase, 1);  % 预分配质心点图形句柄
car_heading = gobjects(Ncase, 1);  % 预分配航向箭头图形句柄
car_trail = gobjects(Ncase, 1);  % 预分配运动轨迹图形句柄

for i = 1:Ncase  % 初始化每个子图
    nexttile;  % 进入下一个子图
    s = results{i};  % 取出第i组仿真结果
    hold on; grid on; axis equal;  % 保持绘图、网格、等比例
    xlabel('x (m)'); ylabel('y (m)');  % 坐标轴标签
    title(['轨迹 ', num2str(i), ' - ', s.name]);  % 子图标题

    plot(s.x, s.y, '--', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0, ...  % 灰色虚线参考轨迹
        'DisplayName', '参考轨迹');
    xlim([min(s.x)-margin, max(s.x)+margin]);  % 设置X轴范围
    ylim([min(s.y)-margin, max(s.y)+margin]);  % 设置Y轴范围

    car_body(i) = plot(s.x(1)+car_outline_x, s.y(1)+car_outline_y, ...  % 初始车体圆盘
        'Color', s.color, 'LineWidth', 2.0, 'DisplayName', '车体');
    car_center(i) = plot(s.x(1), s.y(1), 'o', 'Color', s.color, ...  % 初始质心圆点
        'MarkerFaceColor', s.color, 'DisplayName', '质心');
    car_heading(i) = plot([s.x(1), s.x(1)+heading_len*cos(s.theta(1))], ...  % 初始航向箭头
        [s.y(1), s.y(1)+heading_len*sin(s.theta(1))], ...
        'r-', 'LineWidth', 2.0, 'DisplayName', '航向');
    car_trail(i) = plot(s.x(1), s.y(1), '-', 'Color', [0.10,0.10,0.10], ...  % 初始运动轨迹
        'LineWidth', 1.2, 'DisplayName', '运动轨迹');
    legend('Location', 'best');  % 显示图例
end

step = max(1, round(0.03 / dt));  % 动画帧步长，约30FPS跳帧显示
frame_count = 0;  % GIF帧计数器
gif_enabled = export_gif;  % GIF导出开关

for k = 1:step:numel(t)  % 按步长跳帧播放动画
    for i = 1:Ncase  % 更新四个子图中的小车位置
        s = results{i};  % 取出第i组仿真结果
        ki = min(k, numel(s.t));  % 确保帧索引不越界
        set(car_body(i), 'XData', s.x(ki)+car_outline_x, 'YData', s.y(ki)+car_outline_y);  % 更新车体圆盘位置
        set(car_center(i), 'XData', s.x(ki), 'YData', s.y(ki));  % 更新质心位置
        set(car_heading(i), ...  % 更新航向箭头
            'XData', [s.x(ki), s.x(ki)+heading_len*cos(s.theta(ki))], ...
            'YData', [s.y(ki), s.y(ki)+heading_len*sin(s.theta(ki))]);
        set(car_trail(i), 'XData', s.x(1:ki), 'YData', s.y(1:ki));  % 更新已走轨迹
    end

    drawnow;  % 刷新图形显示

    if gif_enabled  % 如需导出GIF则写入当前帧
        if ~isgraphics(fig_anim, 'figure')  % 检查图窗是否仍然有效
            warning('动画窗口句柄无效，已停止 GIF 导出。');  % 警告信息
            gif_enabled = false;  % 关闭GIF导出
            continue;  % 跳过本次循环
        end
        frame_count = frame_count + 1;  % 帧计数加1
        try
            ax = gca;  % 获取当前坐标轴
            if isgraphics(ax, 'axes')  % 坐标轴有效则抓取坐标轴
                frame_img = getframe(ax);
            else  % 否则抓取整个图窗
                frame_img = getframe(fig_anim);
            end
            [img_ind, img_map] = rgb2ind(frame2im(frame_img), 256);  % RGB转索引图像
            if frame_count == 1  % 第一帧新建GIF
                imwrite(img_ind, img_map, gif_file, 'gif', 'LoopCount', inf, 'DelayTime', 0.03);
            else  % 后续帧追加
                imwrite(img_ind, img_map, gif_file, 'gif', 'WriteMode', 'append', 'DelayTime', 0.03);
            end
        catch ME  % 捕获GIF写入异常
            warning('chasu:GifExportFailed', '%s', ME.message);  % 显示警告
            gif_enabled = false;  % 关闭GIF导出
        end
    end
end

if gif_enabled  % GIF导出成功
    disp(['动画已导出: ', gif_file]);  % 显示保存路径
elseif export_gif  % 请求导出但未成功
    disp('GIF 未导出成功，但动画播放已完成。');  % 提示信息
end

%% 汇总各轨迹的性能指标表
names = strings(Ncase, 1);  % 预分配轨迹名称字符串数组
path_len = zeros(Ncase, 1);  % 路径总长度
disp_len = zeros(Ncase, 1);  % 终点位移
avg_v = zeros(Ncase, 1);  % 平均速度
max_abs_omega = zeros(Ncase, 1);  % 最大角速度绝对值
max_abs_kappa = zeros(Ncase, 1);  % 最大曲率绝对值
final_heading_deg = zeros(Ncase, 1);  % 终点航向角(°)

for i = 1:Ncase  % 遍历提取各轨迹指标
    names(i) = results{i}.name;  % 轨迹名称
    m = results{i}.metrics;  % 指标结构体
    path_len(i) = m.path_len;  % 路径总长度(m)
    disp_len(i) = m.disp_len;  % 终点位移(m)
    avg_v(i) = m.avg_v;  % 平均速度(m/s)
    max_abs_omega(i) = m.max_abs_omega;  % 最大角速度绝对值(rad/s)
    max_abs_kappa(i) = m.max_abs_kappa;  % 最大曲率绝对值(1/m)
    final_heading_deg(i) = m.final_heading_deg;  % 终点航向角(°)
end

summary_tbl = table(names, path_len, disp_len, avg_v, max_abs_omega, max_abs_kappa, final_heading_deg, ...  % 创建汇总表
    'VariableNames', {'轨迹类型', '路径长度_m', '位移_m', '平均速度_mps', '最大角速度_radps', '最大曲率_1pm', '终点航向角_deg'});

disp('================ 典型轨迹仿真分析汇总 ================');  % 打印分隔线
disp(summary_tbl);  % 显示汇总表

%% 差速底盘运动学正解仿真函数
function sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L)
N = numel(t);  % 时间点总数
x = zeros(1, N);  % 预分配x坐标序列
y = zeros(1, N);  % 预分配y坐标序列
theta = zeros(1, N);  % 预分配航向角序列

x(1) = x0(1);  % 初始x坐标
y(1) = x0(2);  % 初始y坐标
theta(1) = x0(3);  % 初始航向角

wr = (2 .* v_cmd + omega_cmd .* L) ./ (2 * r);  % 右轮角速度(rad/s)，由差速逆运动学计算
wl = (2 .* v_cmd - omega_cmd .* L) ./ (2 * r);  % 左轮角速度(rad/s)

dt = t(2) - t(1);  % 时间步长
for k = 1:N-1  % 欧拉前向积分求解位姿
    x(k+1) = x(k) + v_cmd(k) * cos(theta(k)) * dt;  % x坐标更新
    y(k+1) = y(k) + v_cmd(k) * sin(theta(k)) * dt;  % y坐标更新
    theta(k+1) = atan2(sin(theta(k) + omega_cmd(k) * dt), cos(theta(k) + omega_cmd(k) * dt));  % 航向角更新并归一化
end

eps_v = 1e-6;  % 极小值防止除零
kappa = omega_cmd ./ max(abs(v_cmd), eps_v);  % 瞬时曲率 κ=ω/v

sim = struct();  % 创建输出结构体
sim.t = t;  % 时间向量
sim.x = x;  % x坐标序列
sim.y = y;  % y坐标序列
sim.theta = theta;  % 航向角序列
sim.v_cmd = v_cmd;  % 线速度指令
sim.omega_cmd = omega_cmd;  % 角速度指令
sim.wr = wr;  % 右轮角速度
sim.wl = wl;  % 左轮角速度
sim.kappa = kappa;  % 瞬时曲率
end

%% 轨迹性能指标计算函数
function metrics = analyze_metrics(sim, dt)
dx = diff(sim.x);  % x方向相邻点差分
dy = diff(sim.y);  % y方向相邻点差分

path_len = sum(hypot(dx, dy));  % 路径总长度 Σ√(dx²+dy²)
disp_len = hypot(sim.x(end)-sim.x(1), sim.y(end)-sim.y(1));  % 起点到终点的直线距离
avg_v = mean(abs(sim.v_cmd));  % 平均线速度绝对值
max_abs_omega = max(abs(sim.omega_cmd));  % 最大角速度绝对值
max_abs_kappa = max(abs(sim.kappa));  % 最大曲率绝对值
final_heading_deg = rad2deg(sim.theta(end));  % 终点航向角转为角度制

metrics = struct();  % 创建输出结构体
metrics.path_len = path_len;  % 路径总长度
metrics.disp_len = disp_len;  % 终点位移
metrics.avg_v = avg_v;  % 平均速度
metrics.max_abs_omega = max_abs_omega;  % 最大角速度
metrics.max_abs_kappa = max_abs_kappa;  % 最大曲率
metrics.final_heading_deg = final_heading_deg;  % 终点航向角
metrics.sim_time = (numel(sim.t) - 1) * dt;  % 仿真总时长
end
