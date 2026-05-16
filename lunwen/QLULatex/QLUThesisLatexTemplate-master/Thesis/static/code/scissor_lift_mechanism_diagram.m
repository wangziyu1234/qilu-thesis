%% 剪叉式垂直升降台 机构运动简图（最低位与最高位分别输出）
clear; clc; close all;

L = 600;
alpha_low  = 15.78;   beta_low  = alpha_low/2;
alpha_high = 57.12;   beta_high = alpha_high/2;

fig_dir = 'D:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures';

for plot_idx = 1:2
    if plot_idx == 1
        beta_deg = beta_low;
        alpha_deg = alpha_low;
        suffix = 'low';
    else
        beta_deg = beta_high;
        alpha_deg = alpha_high;
        suffix = 'high';
    end

    b = deg2rad(beta_deg);
    H_plat = L * sin(b);
    base_y = -20;

    figure('Position', [50, 50, 1000, 900], 'Color', 'w');
    hold on;

    % 底座
    fill([-70, L*cos(b)+90, L*cos(b)+90, -70], ...
        [base_y-10, base_y-10, base_y, base_y], ...
        [0.5 0.5 0.5], 'EdgeColor', 'k', 'LineWidth', 1.2);

    % 台面
    plat_w = 200;
    plat_cx = L/2 * cos(b);
    fill(plat_cx + [-plat_w/2, plat_w/2, plat_w/2, -plat_w/2], ...
        H_plat + [0, 0, 8, 8], [0.7 0.7 0.78], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);

    % 臂 A: 左下→右上 (红色)
    plot([0, L*cos(b)], [0, L*sin(b)], '-', 'Color', [0.85 0.25 0.25], 'LineWidth', 6);
    % 臂 B: 右下→左上 (蓝色)
    plot([L*cos(b), 0], [0, L*sin(b)], '-', 'Color', [0.2 0.4 0.8], 'LineWidth', 6);

    % 中心铰点
    xm = L/2*cos(b);  ym = L/2*sin(b);
    plot(xm, ym, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'LineWidth', 1.5);

    % 四个端点铰点
    plot(0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');          % 左下固定
    plot(L*cos(b), 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 1.5); % 右下(滑块)
    plot(L*cos(b), H_plat, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); % 右上固定
    % 左上滚轮 (两个小圆表示)
    plot(0, H_plat, 'ko', 'MarkerSize', 16, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);
    plot(0, H_plat, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');

    % 底部滑轨 + 顶部导向槽
    plot([L*cos(b)-18, L*cos(b)+60], [0, 0], 'k-', 'LineWidth', 2.5);
    plot([-18, 60], [H_plat, H_plat], 'k-', 'LineWidth', 2.5);

    % 标注文字（字号放大）
    text(-30, -4, '固定铰', 'FontSize', 12, 'HorizontalAlignment', 'right');
    text(L*cos(b)+15, -4, '滑动端(滑块)', 'FontSize', 12, 'HorizontalAlignment', 'left');
    text(xm+15, ym-10, '中心铰', 'FontSize', 12, 'Color', [0.7 0.5 0]);
    text(L/4*cos(b)-5, L/4*sin(b)+15, '臂A', 'FontSize', 13, 'Color', [0.7 0.15 0.15]);
    text(3*L/4*cos(b)+5, 3*L/4*sin(b)+15, '臂B', 'FontSize', 13, 'Color', [0.1 0.3 0.7]);

    % ---- 两臂夹角 α 弧线 ----
    arc_r = 50;
    th_arc = linspace(b, pi-b, 40);
    plot(xm+arc_r*cos(th_arc), ym+arc_r*sin(th_arc), 'k-', 'LineWidth', 1.8);
    text(xm+arc_r*1.25*cos(pi/2), ym+arc_r*1.25*sin(pi/2), ...
        ['\alpha=' sprintf('%.1f', alpha_deg) '°'], ...
        'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', 'w', ...
        'HorizontalAlignment', 'center');

    % ---- 半角 β 弧线 ----
    beta_arc_r = 70;
    th_b = linspace(0, b, 25);
    plot(xm+beta_arc_r*cos(th_b), ym+beta_arc_r*sin(th_b), 'b--', 'LineWidth', 1.5);
    text(xm+beta_arc_r*1.15*cos(b/2), ym+beta_arc_r*1.15*sin(b/2), ...
        ['\beta=' sprintf('%.1f', beta_deg) '°'], ...
        'FontSize', 13, 'Color', 'b', 'BackgroundColor', 'w');

    % 水平参考虚线
    plot([xm-90, xm+90], [ym, ym], 'k:', 'LineWidth', 0.8);

    % ---- 高度尺寸线 H ----
    H_line_x = -55;
    plot([H_line_x, H_line_x], [0, H_plat], 'k-', 'LineWidth', 1.2);
    plot([H_line_x-8, H_line_x+8], [0, 0], 'k-', 'LineWidth', 0.8);
    plot([H_line_x-8, H_line_x+8], [H_plat, H_plat], 'k-', 'LineWidth', 0.8);
    text(H_line_x-12, H_plat/2, ['H=' sprintf('%.0f', H_plat) 'mm'], ...
        'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Rotation', 90);

    % ---- 臂长尺寸 L ----
    text(L/2*cos(b), -12, ['L=' sprintf('%.0f', L) 'mm'], ...
        'FontSize', 12, 'HorizontalAlignment', 'center');

    % 载荷箭头 Q
    text(plat_cx, H_plat+38, 'Q', 'FontSize', 15, 'FontWeight', 'bold', ...
        'Color', 'r', 'HorizontalAlignment', 'center');
    plot([plat_cx, plat_cx], [H_plat+32, H_plat+12], 'rv-', 'LineWidth', 2, ...
        'MarkerSize', 6, 'MarkerFaceColor', 'r');

    % 推杆力 F_push
    text(L*cos(b)+30, 12, 'F_{push}', 'FontSize', 13, 'Color', [0.8 0.3 0], 'FontWeight', 'bold');
    plot([L*cos(b), L*cos(b)+25], [3, 8], '-', 'Color', [0.8 0.3 0], 'LineWidth', 1.8);

    axis equal;
    xlim([-100, max(L*cos(b)+90, 500)]);
    ylim([base_y-18, H_plat+55]);
    xlabel('X (mm)', 'FontSize', 13);
    ylabel('Z 高度 (mm)', 'FontSize', 13);
    grid on;  box on;
    set(gca, 'FontSize', 12);

    fname = fullfile(fig_dir, ['jiagou_' suffix '.png']);
    print(gcf, fname, '-dpng', '-r200');
    fprintf('Saved %s\n', fname);
end
