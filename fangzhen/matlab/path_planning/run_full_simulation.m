%% run_full_simulation.m
%  完整仿真流程: Hybrid A* 路径规划 → 红外 PID 循迹
%  直接运行即可, 不需要修改任何参数
%
%  使用方法: 在 MATLAB 中打开此文件, 按 F5 运行

clear; clc; close all;

fprintf('========================================\n');
fprintf('  AGV 路径规划与循迹仿真\n');
fprintf('========================================\n\n');

%% ==================== 第一步: Hybrid A* 路径规划 ====================
fprintf('【第一步】运行 Hybrid A* 路径规划...\n\n');

% 调用路径规划函数
path = hybrid_astar_pathplanning();

% 路径插值加密 (每 0.05m 一个点, 原始路径太稀疏)
path = interpolate_path(path, 0.05);
fprintf('插值后路径点数: %d\n', size(path, 1));

% 保存路径到 CSV (供其他程序调用)
T = table(path(:,1), path(:,2), path(:,3), ...
    'VariableNames', {'x_m', 'y_m', 'theta_rad'});
writetable(T, 'reference_path.csv');
fprintf('参考路径已保存: reference_path.csv\n');

%% ==================== 第二步: PID 循迹仿真 ====================
fprintf('\n【第二步】运行红外 PID 循迹仿真...\n\n');

% 调用循迹仿真函数
line_following_pid(path);

%% ======================== 辅助函数 ========================
function path_out = interpolate_path(path_in, ds)
% 沿路径等间距插值, ds 为间距 (m)
    % 计算累积弧长
    dx = diff(path_in(:,1));
    dy = diff(path_in(:,2));
    seg_len = hypot(dx, dy);
    cum_s = [0; cumsum(seg_len)];
    total_len = cum_s(end);

    % 生成等间距采样点
    s_query = 0:ds:total_len;
    xq = interp1(cum_s, path_in(:,1), s_query, 'linear');
    yq = interp1(cum_s, path_in(:,2), s_query, 'linear');
    tq = interp1(cum_s, path_in(:,3), s_query, 'linear');
    tq = atan2(sin(tq), cos(tq));   % 航向角归一化

    path_out = [xq(:), yq(:), tq(:)];
end

%% ==================== 完成 ====================
fprintf('\n========================================\n');
fprintf('  仿真完成!\n');
fprintf('========================================\n');

% 复制图片到论文 figures 目录
fig_dir = fullfile('D:', '毕业论文', '代码', '1_论文', 'QLULatex', ...
    'QLUThesisLatexTemplate-master', 'Thesis', 'static', 'figures');
fig_files = {'hybrid_astar_result.png', 'line_following_result.png', 'sensor_layout.png'};
for i = 1:length(fig_files)
    if exist(fig_files{i}, 'file')
        copyfile(fig_files{i}, fullfile(fig_dir, fig_files{i}));
        fprintf('已复制到论文目录: %s\n', fig_files{i});
    end
end
fprintf('请重新编译论文以查看图片\n');
