%% 级联双闭环PID控制系统结构示意图
clear; clc; close all;

fig = figure('Color','w','Position',[80 80 1050 500],'Resize','off');

% 归一化坐标 [0,1], 全部用annotation绘制
% 辅助函数: 画方框
box_x = @(cx,w) [cx-w/2, cx+w/2];  % 中心→左右边界
box_y = @(cy,h) [cy-h/2, cy+h/2];  % 中心→上下边界

drawbox = @(cx,cy,w,h,c) annotation('rectangle',...
    [cx-w/2, cy-h/2, w, h],'FaceColor',c,'EdgeColor','k',...
    'LineWidth',1.3,'FaceAlpha',0.90);

drawline = @(x1,y1,x2,y2) annotation('line',[x1 x2],[y1 y2],...
    'Color',[0.15 0.15 0.15],'LineWidth',1.4);

drawarrow = @(x1,y1,x2,y2) annotation('arrow',[x1 x2],[y1 y2],...
    'Color',[0.15 0.15 0.15],'LineWidth',1.4,...
    'HeadWidth',9,'HeadLength',9);

% 颜色
c_outer = [0.20 0.50 0.82];   % 外环蓝
c_inner = [0.88 0.40 0.15];   % 内环橙
c_plant = [0.45 0.70 0.35];   % 被控对象绿
c_sum   = [1 1 1];            % 求和节点白

% ========== 布局参数 ==========
% 行1(上): 外环通路  y1 = 0.72
% 行2(下): 被控对象   y2 = 0.35
y1 = 0.72;  y2 = 0.35;

bw = 0.12;   bh = 0.14;  % 标准方框尺寸

% =====================================================
%  参考轨迹 (最左)
% =====================================================
cx_ref = 0.07;
drawbox(cx_ref, y1, 0.09, bh, [0.55 0.55 0.55]);
text(cx_ref, y1, {'参考轨迹','x_{ref}, y_{ref}'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',8,'FontWeight','bold','Color','w');

% → 求和节点1
drawarrow(cx_ref+0.045, y1, 0.17, y1);
text(0.13, y1+0.035, 'e', 'FontSize',10,'FontWeight','bold','Color',c_outer);

% =====================================================
%  求和节点1
% =====================================================
sum1 = 0.185;
annotation('ellipse',[sum1-0.015, y1-0.03, 0.03, 0.06],...
    'FaceColor',c_sum,'EdgeColor','k','LineWidth',1.2);
text(sum1, y1, '+', 'HorizontalAlignment','center',...
    'VerticalAlignment','middle','FontSize',13,'FontWeight','bold');

% =====================================================
%  外环PID
% =====================================================
cx_opid = 0.30;
drawbox(cx_opid, y1, bw, bh, c_outer);
text(cx_opid, y1, {'外环PID','(位置/航向)'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',9,'FontWeight','bold','Color','w');

drawarrow(sum1+0.015, y1, cx_opid-bw/2, y1);

% → 逆运动学
drawarrow(cx_opid+bw/2, y1, 0.44, y1);
text(0.39, y1+0.035, 'v, \omega', 'FontSize',9,'Color',c_outer);

% =====================================================
%  逆运动学
% =====================================================
cx_ik = 0.50;
drawbox(cx_ik, y1, 0.10, bh, [0.65 0.65 0.78]);
text(cx_ik, y1, {'逆运动学','\omega_L^*, \omega_R^*'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',8,'FontWeight','bold');

drawarrow(0.44, y1, cx_ik-0.05, y1);

% → 求和节点2
drawarrow(cx_ik+0.05, y1, 0.62, y1);
text(0.585, y1+0.035, '\omega^*', 'FontSize',9,'Color',c_inner);

% =====================================================
%  求和节点2
% =====================================================
sum2 = 0.635;
annotation('ellipse',[sum2-0.015, y1-0.03, 0.03, 0.06],...
    'FaceColor',c_sum,'EdgeColor','k','LineWidth',1.2);
text(sum2, y1, '+', 'HorizontalAlignment','center',...
    'VerticalAlignment','middle','FontSize',13,'FontWeight','bold');

% =====================================================
%  内环PI
% =====================================================
cx_ipid = 0.76;
drawbox(cx_ipid, y1, bw, bh, c_inner);
text(cx_ipid, y1, {'内环PI','(电机速度)'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',9,'FontWeight','bold','Color','w');

drawarrow(sum2+0.015, y1, cx_ipid-bw/2, y1);
text(0.68, y1+0.035, 'e_\omega', 'FontSize',10,'FontWeight','bold','Color',c_inner);

% → 电机
drawarrow(cx_ipid+bw/2, y1, cx_ipid+bw/2, y2+0.07+0.01);
text(cx_ipid+0.04, (y1+y2)/2+0.06, 'u', 'FontSize',10,'FontWeight','bold','Color',c_inner);

% =====================================================
%  电机+减速器
% =====================================================
cx_motor = cx_ipid;  % 0.76
drawbox(cx_motor, y2, 0.13, 0.14, c_plant);
text(cx_motor, y2+0.025, '电机+减速器',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',9,'FontWeight','bold');
text(cx_motor, y2-0.025, 'K / (\tau s+1)',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',8);

% =====================================================
%  差速运动学 (AGV本体)
% =====================================================
cx_agv = 0.50;
drawbox(cx_agv, y2, 0.16, 0.14, c_plant);
text(cx_agv, y2+0.025, '差速AGV运动学',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',9,'FontWeight','bold');
text(cx_agv, y2-0.025, {'v=r(\omega_L+\omega_R)/2','\omega=r(\omega_R-\omega_L)/L'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',7);

% 电机 → AGV
drawarrow(cx_motor-0.065, y2, cx_agv+0.08, y2);
text(0.63, y2+0.035, '\omega_L, \omega_R', 'FontSize',9,'Color',c_plant,'FontWeight','bold');

% =====================================================
%  输出(实际位姿)
% =====================================================
cx_out = 0.33;
drawbox(cx_out, y2, 0.10, 0.10, [0.9 0.85 0.60]);
text(cx_out, y2, {'实际位姿','x, y, \theta'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',8,'FontWeight','bold');

drawarrow(cx_agv-0.08, y2, cx_out+0.05, y2);
text(0.38, y2+0.035, 'x, y, \theta', 'FontSize',9,'FontWeight','bold');

% =====================================================
%  反馈路径
% =====================================================

% 反馈1: 位姿 → 求和1 (左侧竖线)
fb1_x = 0.10;
drawarrow(cx_out, y2+0.05, cx_out, y2+0.10);
drawline(cx_out, y2+0.10, fb1_x, y2+0.10);
drawline(fb1_x, y2+0.10, fb1_x, y1);
drawarrow(fb1_x, y1, sum1-0.015, y1);
text(0.115, 0.54, {'位姿','反馈'}, 'FontSize',8,'Color',[0.4 0.4 0.4],...
    'HorizontalAlignment','center');

% 反馈2: 轮速 → 求和2 (右侧)
fb2_x = 0.92;
drawline(cx_motor, y2+0.07, cx_motor, y2+0.12);
drawline(cx_motor, y2+0.12, fb2_x, y2+0.12);
drawline(fb2_x, y2+0.12, fb2_x, y1);
drawline(fb2_x, y1, sum2+0.015, y1);
text(0.935, 0.54, {'编码器','反馈'}, 'FontSize',8,'Color',[0.4 0.4 0.4],...
    'HorizontalAlignment','center');

% =====================================================
%  外环/内环虚线框
% =====================================================
annotation('rectangle',[0.05 0.60 0.57 0.24],...
    'Color',c_outer,'LineWidth',1.8,'LineStyle','--');
text(0.065, 0.855, '外环（路径跟踪环）',...
    'FontSize',10,'FontWeight','bold','Color',c_outer);

annotation('rectangle',[0.60 0.60 0.28 0.24],...
    'Color',c_inner,'LineWidth',1.8,'LineStyle','--');
text(0.615, 0.855, '内环（速度环）',...
    'FontSize',10,'FontWeight','bold','Color',c_inner);

% =====================================================
%  标题
% =====================================================
text(0.50, 0.96, '级联双闭环PID控制系统结构框图',...
    'HorizontalAlignment','center','FontSize',14,'FontWeight','bold');

% 保存
out_dir = fileparts(mfilename('fullpath'));
fname = fullfile(out_dir, 'cascaded_pid_diagram.png');
print(fig, fname, '-dpng', '-r200');
fprintf('已保存: %s\n', fname);
