%% PID控制原理图绘制
%  生成 PID 控制原理框图, 替换原 pid.png

clear; close all;

fig = figure('Color','w','Position',[100,100,1000,420], 'Visible','off');
hold on; axis equal; axis off;

% 设置中文字体以避免渲染警告
set(fig, 'DefaultTextFontName', 'SimHei');
set(fig, 'DefaultAxesFontName', 'SimHei');

% ---- 颜色与样式 ----
box_color   = [0.90, 0.95, 1.00];   % 方框填充色 (浅蓝)
box_edge    = [0.00, 0.30, 0.60];   % 方框边框色
sum_color   = [0.95, 0.95, 0.95];   % 求和点填充色
arrow_color = [0.15, 0.15, 0.15];   % 箭头/连线颜色
text_color  = [0.00, 0.00, 0.00];   % 文本颜色

fs_label = 10;    % 标签字号
fs_title = 11;    % 标题字号
fs_math  = 11;    % 公式字号

% ---- 坐标布局 ----
% 节点 x 坐标
x_ref   = 1.0;    % 参考输入
x_sum1  = 3.0;    % 比较点
x_pid   = 5.5;    % PID 控制器
x_sum2  = 8.0;    % PID 内部求和
x_plant = 10.5;   % 被控对象
x_out   = 13.0;   % 输出

% 节点 y 坐标
y_main  = 5.0;    % 主通路
y_p     = 7.2;    % P 分支
y_i     = 5.0;    % I 分支
y_d     = 2.8;    % D 分支
y_fb_up = 7.5;    % 反馈线上端
y_fb_lo = 7.5;    % 反馈线下端 (同)

bx_w = 1.2;       % 方框半宽
bx_h = 0.55;      % 方框半高

%% ---- 1. 方框 ----
% 比较点圆圈
draw_circle(x_sum1, y_main, 0.22, sum_color, arrow_color);

% PID 三个分支框
draw_box(x_pid, y_p, bx_w, bx_h, box_color, box_edge);  % P
draw_box(x_pid, y_i, bx_w, bx_h, box_color, box_edge);  % I
draw_box(x_pid, y_d, bx_w, bx_h, box_color, box_edge);  % D

% PID 内部求和点
draw_circle(x_sum2, y_main, 0.22, sum_color, arrow_color);

% 被控对象方框
draw_box(x_plant, y_main, bx_w, bx_h, [0.95, 0.90, 0.85], [0.60, 0.40, 0.10]);

% 传感器方框
draw_box(x_plant, y_fb_lo, 0.55, 0.40, sum_color, arrow_color);

%% ---- 2. 框内文字 ----
% PID 分支
text(x_pid, y_p,   ' $K_p$',       'HorizontalAlignment','center','FontSize',fs_math+2,'Interpreter','latex');
text(x_pid, y_i,   ' $K_i\!\int$', 'HorizontalAlignment','center','FontSize',fs_math+2,'Interpreter','latex');
text(x_pid, y_d,   ' $K_d\frac{d}{dt}$','HorizontalAlignment','center','FontSize',fs_math+2,'Interpreter','latex');

% 被控对象
text(x_plant, y_main, '被控对象','HorizontalAlignment','center','FontSize',fs_title,'Interpreter','latex');

% 传感器
text(x_plant, y_fb_lo, '传感器','HorizontalAlignment','center','FontSize',fs_label,'Interpreter','latex');

%% ---- 3. 主通路连线 ----
% 参考输入 r(t) → 比较点
draw_arrow(x_ref, y_main, x_sum1-0.22, y_main, arrow_color);
text(1.7, y_main+0.35, '$r(t)$', 'FontSize',fs_math,'Interpreter','latex','Color',text_color);
text(0.85, y_main-0.80, '参考输入','FontSize',fs_label,'Interpreter','latex','HorizontalAlignment','center');

% 比较点 → PID 分叉点 (x=4.0)
x_fork = 4.0;
draw_arrow(x_sum1+0.22, y_main, x_fork, y_main, arrow_color);
text(3.3, y_main+0.35, '$e(t)$', 'FontSize',fs_math,'Interpreter','latex','Color',text_color);

% 分叉 → P
draw_line(x_fork, y_main, x_fork, y_p, arrow_color);
draw_arrow(x_fork, y_p, x_pid-bx_w, y_p, arrow_color);

% 分叉 → I
draw_line(x_fork, y_main, x_pid-bx_w, y_main, arrow_color);
% 在分叉处做标记
plot(x_fork, y_main, 'ko','MarkerSize',4,'MarkerFaceColor',arrow_color);

% 分叉 → D
draw_line(x_fork, y_main, x_fork, y_d, arrow_color);
draw_arrow(x_fork, y_d, x_pid-bx_w, y_d, arrow_color);

% 分叉标记
text(x_fork-0.15, y_main-0.30, '$+$','FontSize',fs_math-1,'Interpreter','latex');

% P → 求和点
draw_arrow(x_pid+bx_w, y_p, x_sum2-0.22, y_p, arrow_color);
draw_line(x_sum2-0.22, y_p, x_sum2-0.22, y_main+0.22, arrow_color);
plot(x_sum2-0.22, y_p, 'ko','MarkerSize',3,'MarkerFaceColor',arrow_color);

% I → 求和点
draw_arrow(x_pid+bx_w, y_i, x_sum2-0.22, y_i, arrow_color);

% D → 求和点
draw_arrow(x_pid+bx_w, y_d, x_sum2-0.22, y_d, arrow_color);
draw_line(x_sum2-0.22, y_d, x_sum2-0.22, y_main-0.22, arrow_color);
plot(x_sum2-0.22, y_d, 'ko','MarkerSize',3,'MarkerFaceColor',arrow_color);

% 求和点 → 被控对象
draw_arrow(x_sum2+0.22, y_main, x_plant-bx_w, y_main, arrow_color);
text(8.8, y_main+0.35, '$u(t)$', 'FontSize',fs_math,'Interpreter','latex','Color',text_color);

% 被控对象 → 输出
draw_arrow(x_plant+bx_w, y_main, x_out, y_main, arrow_color);
text(12.2, y_main+0.35, '$y(t)$', 'FontSize',fs_math,'Interpreter','latex','Color',text_color);
text(x_out+0.20, y_main-0.80, '输出','FontSize',fs_label,'Interpreter','latex','HorizontalAlignment','center');

%% ---- 4. 反馈通路 ----
% 输出分叉点 (x=12.0)
x_fb = 12.0;
plot(x_fb, y_main, 'ko','MarkerSize',4,'MarkerFaceColor',arrow_color);

% 向下 → 传感器
draw_line(x_fb, y_main, x_fb, y_fb_lo, arrow_color);
draw_arrow(x_fb, y_fb_lo, x_plant+bx_w, y_fb_lo, arrow_color);

% 传感器 → 向左 → 向上 → 比较点
x_fb_left = x_plant - bx_w;
draw_arrow(x_plant-bx_w, y_fb_lo, 1.5, y_fb_lo, arrow_color);
draw_line(1.5, y_fb_lo, 1.5, y_main, arrow_color);
draw_arrow(1.5, y_main, x_sum1-0.22, y_main, arrow_color);

% 反馈标记
text(0.85, y_fb_lo-0.60, '反馈','FontSize',fs_label,'Interpreter','latex','HorizontalAlignment','center');

%% ---- 5. 比较点标注 ----
text(x_sum1-0.60, y_main-0.45, '$+$','FontSize',fs_math,'Interpreter','latex');
text(x_sum1-0.45, y_main+0.48, '$-$','FontSize',fs_math,'Interpreter','latex');

%% ---- 6. 求和点标注 ----
text(x_sum2-0.20, y_main+1.30, '$+$','FontSize',fs_math-1,'Interpreter','latex');

%% ---- 7. 虚线框: PID控制器 ----
x_pid_left  = x_fork - 0.25;
x_pid_right = x_sum2 + 0.35;
y_pid_top   = y_p + bx_h + 0.35;
y_pid_bot   = y_d - bx_h - 0.35;

plot([x_pid_left, x_pid_right, x_pid_right, x_pid_left, x_pid_left], ...
     [y_pid_top, y_pid_top, y_pid_bot, y_pid_bot, y_pid_top], ...
     'k--','LineWidth',1.0);
text(x_pid, y_pid_top+0.30, 'PID 控制器','HorizontalAlignment','center',...
     'FontSize',fs_title,'Interpreter','latex','Color',text_color);

%% ---- 8. 全局比例与保存 ----
xlim([0, 14.5]);
ylim([0, 9.5]);

out_dir = fullfile(fileparts(mfilename('fullpath')), '..', '..', ...
    'lunwen','QLULatex','QLUThesisLatexTemplate-master','Thesis','static','figures');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
exportgraphics(fig, fullfile(out_dir, 'pid.png'), 'Resolution', 200);
fprintf('PID 原理图已保存: %s\n', fullfile(out_dir, 'pid.png'));

%% ======================== 绘图辅助函数 ========================
function draw_box(cx, cy, hw, hh, fc, ec)
    % 绘制填充矩形方框
    xv = [cx-hw, cx+hw, cx+hw, cx-hw];
    yv = [cy-hh, cy-hh, cy+hh, cy+hh];
    patch(xv, yv, fc, 'EdgeColor', ec, 'LineWidth', 1.5);
end

function draw_circle(cx, cy, r, fc, ec)
    % 绘制填充圆 (求和点)
    th = linspace(0, 2*pi, 60);
    patch(cx + r*cos(th), cy + r*sin(th), fc, 'EdgeColor', ec, 'LineWidth', 1.2);
end

function draw_arrow(x1, y1, x2, y2, color)
    % 绘制带箭头的线段
    plot([x1, x2], [y1, y2], '-', 'Color', color, 'LineWidth', 1.5);
    % 箭头三角形
    len = 0.18;  ang = 0.45;
    dx = x2 - x1;  dy = y2 - y1;
    L = hypot(dx, dy);
    if L < 1e-8, return; end
    ux = dx/L;  uy = dy/L;
    ax1 = x2 - len*cos(atan2(uy,ux)-ang);
    ay1 = y2 - len*sin(atan2(uy,ux)-ang);
    ax2 = x2 - len*cos(atan2(uy,ux)+ang);
    ay2 = y2 - len*sin(atan2(uy,ux)+ang);
    patch([x2, ax1, ax2], [y2, ay1, ay2], color, 'EdgeColor', 'none');
end

function draw_line(x1, y1, x2, y2, color)
    % 绘制无箭头线段
    plot([x1, x2], [y1, y2], '-', 'Color', color, 'LineWidth', 1.5);
end
