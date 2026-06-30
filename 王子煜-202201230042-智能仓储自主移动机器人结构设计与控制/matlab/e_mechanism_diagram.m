%% 剪叉式垂直升降台机构运动简图
%  绘制最低位(α=19.1°)和最高位(α=133.5°)的机构简图
%  标注臂杆、铰点、滑轨、夹角α、半角β、台面高度H
clear; clc; close all;

L = 600;  % 臂杆长度，单位mm
alpha_low  = 19.10;   beta_low  = alpha_low/2;  % 最低位时两臂夹角及半角
alpha_high = 133.49;  beta_high = alpha_high/2;  % 最高位时两臂夹角及半角
h0 = 49;  % 臂杆两端配件（铰座、滚轮座）的固定高度，单位mm

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');  % 图片输出目录

for plot_idx = 1:2  % 循环两次，分别绘制最低位和最高位
    if plot_idx == 1  % 第一轮绘制最低位状态
        beta_deg = beta_low;  % 最低位对应的半角角度
        alpha_deg = alpha_low;  % 最低位对应的两臂夹角
        suffix = 'low';  % 文件名后缀标记为低位
    else  % 第二轮绘制最高位状态
        beta_deg = beta_high;  % 最高位对应的半角角度
        alpha_deg = alpha_high;  % 最高位对应的两臂夹角
        suffix = 'high';  % 文件名后缀标记为高位
    end

    b = deg2rad(beta_deg);  % 将半角从角度制转换为弧度制
    H_arm = L * sin(b);  % 臂杆上端铰点距底座的高度
    H_plat = H_arm + h0;  % 台面距底座的总高度（含配件高度）
    base_y = -20;  % 底座图形基准线的Y坐标

    figure('Position', [50, 50, 800, 650], 'Color', 'w');  % 创建新图窗，设定位置和白色背景
    hold on;

    % 绘制底座（灰色矩形）
    fill([-70, L*cos(b)+90, L*cos(b)+90, -70], ...  % 底座矩形的四个X坐标
        [base_y-10, base_y-10, base_y, base_y], ...  % 底座矩形的四个Y坐标
        [0.5 0.5 0.5], 'EdgeColor', 'k', 'LineWidth', 1.2);  % 灰色填充，黑色边框

    % 绘制台面承载平台
    plat_margin = 30;  % 台面两侧超出铰点的余量
    plat_w = L*cos(b) + 2*plat_margin;  % 台面总宽度
    plat_cx = L/2 * cos(b);  % 台面中心点X坐标
    fill(plat_cx + [-plat_w/2, plat_w/2, plat_w/2, -plat_w/2], ...  % 台面矩形四个X坐标
        H_plat + [0, 0, 8, 8], [0.7 0.7 0.78], ...  % 台面矩形四个Y坐标，浅蓝灰色填充
        'EdgeColor', 'k', 'LineWidth', 1.2);  % 黑色边框

    % 绘制臂杆A（从左下固定铰到右上铰点，红色）
    plot([0, L*cos(b)], [0, L*sin(b)], '-', 'Color', [0.85 0.25 0.25], 'LineWidth', 6);  % 红棕色粗线
    % 绘制臂杆B（从右下滑块铰到左上铰点，蓝色）
    plot([L*cos(b), 0], [0, L*sin(b)], '-', 'Color', [0.2 0.4 0.8], 'LineWidth', 6);  % 深蓝色粗线

    % 绘制中心铰点（两臂交叉处）
    xm = L/2*cos(b);  ym = L/2*sin(b);  % 中心铰点的X和Y坐标
    plot(xm, ym, 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'LineWidth', 1.5);  % 黄色实心圆标记

    % 绘制四个端点铰点
    plot(0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');  % 左下固定铰，黑色实心圆
    plot(L*cos(b), 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);  % 右下滑动端，白色空心圆
    plot(L*cos(b), H_arm, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');  % 右上固定铰，黑色实心圆
    plot(0, H_arm, 'ko', 'MarkerSize', 16, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);  % 左上滚轮外圈
    plot(0, H_arm, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');  % 左上滚轮内圈

    % 绘制底部滑轨和顶部导向槽
    plot([L*cos(b)-18, L*cos(b)+60], [0, 0], 'k-', 'LineWidth', 2.5);  % 底部滑轨线
    plot([-18, 60], [H_arm, H_arm], 'k-', 'LineWidth', 2.5);  % 顶部导向槽线

    % 绘制臂端到台面的配件连接线
    plot([0, 0], [H_arm, H_plat], 'k-', 'LineWidth', 2);  % 左侧配件连接
    plot([L*cos(b), L*cos(b)], [H_arm, H_plat], 'k-', 'LineWidth', 2);  % 右侧配件连接

    % 添加文字标注
    text(-30, -4, '固定铰', 'FontSize', 12, 'HorizontalAlignment', 'right');  % 标注左下固定铰
    text(L*cos(b)+15, -4, '滑动端(滑块)', 'FontSize', 12, 'HorizontalAlignment', 'left');  % 标注右下滑动端
    text(xm+15, ym-10, '中心铰', 'FontSize', 12, 'Color', [0.7 0.5 0]);  % 标注中心铰点
    text(L/4*cos(b)-5, L/4*sin(b)+15, '臂A', 'FontSize', 13, 'Color', [0.7 0.15 0.15]);  % 标注臂杆A
    text(3*L/4*cos(b)+5, 3*L/4*sin(b)+15, '臂B', 'FontSize', 13, 'Color', [0.1 0.3 0.7]);  % 标注臂杆B

    % 绘制两臂夹角α的弧线标记
    arc_r = 50;  % 弧线半径
    th_arc = linspace(b, pi-b, 40);  % 从β到π-β生成40个采样点
    plot(xm+arc_r*cos(th_arc), ym+arc_r*sin(th_arc), 'k-', 'LineWidth', 1.8);  % 绘制夹角弧线
    text(xm+arc_r*1.25*cos(pi/2), ym+arc_r*1.25*sin(pi/2), ...  % 夹角标注文字位置
        ['\alpha=' sprintf('%.1f', alpha_deg) '°'], ...  % 显示α=角度值
        'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', 'w', ...  % 字体格式
        'HorizontalAlignment', 'center');  % 居中对齐

    % 绘制半角β的弧线标记
    beta_arc_r = 70;  % β弧线半径
    th_b = linspace(0, b, 25);  % 从0到β生成25个采样点
    plot(xm+beta_arc_r*cos(th_b), ym+beta_arc_r*sin(th_b), 'b--', 'LineWidth', 1.5);  % 蓝色虚线弧
    text(xm+beta_arc_r*1.15*cos(b/2), ym+beta_arc_r*1.15*sin(b/2), ...  % β标注位置
        ['\beta=' sprintf('%.1f', beta_deg) '°'], ...  % 显示β=角度值
        'FontSize', 13, 'Color', 'b', 'BackgroundColor', 'w');  % 蓝色字体

    % 绘制水平参考虚线
    plot([xm-90, xm+90], [ym, ym], 'k:', 'LineWidth', 0.8);  % 过中心铰点的水平虚线

    % 绘制高度尺寸线H
    H_line_x = -55;  % 尺寸线X位置
    plot([H_line_x, H_line_x], [0, H_plat], 'k-', 'LineWidth', 1.2);  % 竖直尺寸线
    plot([H_line_x-8, H_line_x+8], [0, 0], 'k-', 'LineWidth', 0.8);  % 尺寸线下端标记
    plot([H_line_x-8, H_line_x+8], [H_plat, H_plat], 'k-', 'LineWidth', 0.8);  % 尺寸线上端标记
    text(H_line_x-12, H_plat/2, ['H=' sprintf('%.0f', H_plat) 'mm'], ...  % 显示高度值
        'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Rotation', 90);  % 竖排文字

    % 标注臂长L
    text(L/2*cos(b), -12, ['L=' sprintf('%.0f', L) 'mm'], ...  % 在臂下方显示臂长
        'FontSize', 12, 'HorizontalAlignment', 'center');  % 居中对齐

    % 绘制载荷箭头Q
    text(plat_cx, H_plat+38, 'Q', 'FontSize', 15, 'FontWeight', 'bold', ...  % 载荷符号Q
        'Color', 'r', 'HorizontalAlignment', 'center');  % 红色加粗
    plot([plat_cx, plat_cx], [H_plat+32, H_plat+12], 'rv-', 'LineWidth', 2, ...  % 向下载荷箭头
        'MarkerSize', 6, 'MarkerFaceColor', 'r');  % 红色三角箭头

    % 绘制推杆力F_push
    text(L*cos(b)+30, 12, 'F_{push}', 'FontSize', 13, 'Color', [0.8 0.3 0], 'FontWeight', 'bold');  % 推力标注
    plot([L*cos(b), L*cos(b)+25], [3, 8], '-', 'Color', [0.8 0.3 0], 'LineWidth', 1.8);  % 推力方向箭头

    % 添加图号标记(a)(b)
    if plot_idx == 1  % 最低位图
        text(-80, H_plat+55, '(a) 最低位', 'FontSize', 13, 'FontWeight', 'bold');  % 标记(a)最低位
    else  % 最高位图
        text(-80, H_plat+55, '(b) 最高位', 'FontSize', 13, 'FontWeight', 'bold');  % 标记(b)最高位
    end

    axis equal;  % 设置坐标轴等比例
    xlim([-100, max(L*cos(b)+90, 500)]);  % X轴显示范围
    ylim([base_y-18, H_plat+55]);  % Y轴显示范围
    xlabel('X (mm)', 'FontSize', 13);  % X轴标签
    ylabel('Z 高度 (mm)', 'FontSize', 13);  % Y轴标签（Z表示高度方向）
    grid on;  box on;  % 显示网格和边框
    set(gca, 'FontSize', 12);  % 设置坐标轴字体大小

    set(gca, 'Position', [0.10 0.12 0.85 0.82]);  % 调整图形在窗口中的位置
    set(gca, 'LooseInset', get(gca, 'TightInset'));  % 去除四周多余留白

    fname = fullfile(fig_dir, ['jiagou_' suffix '.png']);  % 拼接输出文件名
    print(gcf, fname, '-dpng', '-r200');  % 导出为PNG图片，分辨率200dpi
    fprintf('Saved %s\n', fname);  % 在命令行显示已保存的文件名
end
