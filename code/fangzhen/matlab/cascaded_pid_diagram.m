%% 级联双闭环PID控制系统结构框图 (终版)
clear; clc; close all;

fig = figure('Color','w','Position',[80 80 1100 420],'Resize','off');

% 颜色
c_outer = [0.20 0.50 0.82];
c_inner = [0.88 0.40 0.15];
c_plant = [0.45 0.70 0.35];
c_out   = [0.90 0.85 0.60];
c_gray  = [0.55 0.55 0.55];

% 辅助函数
drawbox = @(cx,cy,w,h,c) annotation('rectangle',[cx-w/2,cy-h/2,w,h],...
    'FaceColor',c,'EdgeColor','k','LineWidth',1.2);
drawarrow = @(x1,y1,x2,y2) annotation('arrow',[x1 x2],[y1 y2],...
    'Color',[0.2 0.2 0.2],'LineWidth',1.3,'HeadWidth',8,'HeadLength',8);
drawline = @(x1,y1,x2,y2) annotation('line',[x1 x2],[y1 y2],...
    'Color',[0.4 0.4 0.4],'LineWidth',1.2);

% 布局参数
y1 = 0.72; y2 = 0.28;
bw = 0.11; bh = 0.16;
cx_a = 0.50;  % 差速运动学x坐标
cx_m = 0.73;  % 电机x坐标

% 方块边缘计算 (cx, cy, w, h) → 左/右/上/下
% 参考轨迹: cx=0.06, 右边缘=0.06+0.045=0.105
% 外环PID: cx=0.28, 左=0.225, 右=0.335
% 逆运动学: cx=0.48, 左=0.43, 右=0.53
% 内环PI: cx=0.73, 左=0.675, 右=0.785, 下边缘=0.64
% 电机: cx=0.73, 左=0.665, 右=0.795, 上=0.355
% 差速运动学: cx=0.50, 左=0.42, 右=0.58
% 实际位姿: cx=0.33, 左=0.28, 右=0.38

% ===== 参考轨迹 =====
cx = 0.06;
drawbox(cx, y1, 0.09, bh, c_gray);
annotation('textbox',[cx-0.045,y1-0.03,0.09,0.06],...
    'String',{'参考轨迹','x_{ref}, y_{ref}'},...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'EdgeColor','none','FontSize',8,'FontWeight','bold','Color','w');

% 参考轨迹右边缘→求和节点1
drawarrow(0.105, y1, 0.157, y1);
annotation('textbox',[0.115,y1+0.025,0.04,0.03],...
    'String','e','EdgeColor','none','FontSize',10,'FontWeight','bold',...
    'Color',c_outer,'HorizontalAlignment','center');

% ===== 求和节点1 =====
s1 = 0.175;
annotation('ellipse',[s1-0.018, y1-0.035, 0.036, 0.07],...
    'FaceColor','w','EdgeColor','k','LineWidth',1.2);
annotation('textbox',[s1-0.015,y1-0.02,0.03,0.04],...
    'String','+','EdgeColor','none','FontSize',14,'FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% ===== 外环PID =====
cx_op = 0.28;
drawbox(cx_op, y1, bw, bh, c_outer);
annotation('textbox',[cx_op-bw/2,y1+0.005,bw,0.03],...
    'String','外环PID','EdgeColor','none','FontSize',9,'FontWeight','bold',...
    'Color','w','HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_op-bw/2,y1-0.03,bw,0.03],...
    'String','(位置/航向)','EdgeColor','none','FontSize',8,...
    'Color','w','HorizontalAlignment','center','VerticalAlignment','middle');

% 求和节点1右→外环PID左
drawarrow(s1+0.018, y1, cx_op-bw/2, y1);

% 外环PID右→逆运动学左
drawarrow(cx_op+bw/2, y1, 0.43, y1);
annotation('textbox',[0.365,y1+0.03,0.06,0.03],...
    'String','v, \omega','EdgeColor','none','FontSize',9,...
    'Color',c_outer,'FontWeight','bold','HorizontalAlignment','center');

% ===== 逆运动学 =====
cx_ik = 0.48;
drawbox(cx_ik, y1, 0.10, bh, [0.65 0.65 0.78]);
annotation('textbox',[cx_ik-0.05,y1+0.005,0.10,0.03],...
    'String','逆运动学','EdgeColor','none','FontSize',9,'FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_ik-0.05,y1-0.03,0.10,0.03],...
    'String','\omega_L^*, \omega_R^*','EdgeColor','none','FontSize',8,...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% 逆运动学右→求和节点2左
drawarrow(0.53, y1, 0.597, y1);
annotation('textbox',[0.545,y1+0.03,0.05,0.03],...
    'String','\omega^*','EdgeColor','none','FontSize',9,...
    'Color',c_inner,'FontWeight','bold','HorizontalAlignment','center');

% ===== 求和节点2 =====
s2 = 0.615;
annotation('ellipse',[s2-0.018, y1-0.035, 0.036, 0.07],...
    'FaceColor','w','EdgeColor','k','LineWidth',1.2);
annotation('textbox',[s2-0.015,y1-0.02,0.03,0.04],...
    'String','+','EdgeColor','none','FontSize',14,'FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% ===== 内环PI =====
cx_ip = 0.73;
drawbox(cx_ip, y1, bw, bh, c_inner);
annotation('textbox',[cx_ip-bw/2,y1+0.005,bw,0.03],...
    'String','内环PI','EdgeColor','none','FontSize',9,'FontWeight','bold',...
    'Color','w','HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_ip-bw/2,y1-0.03,bw,0.03],...
    'String','(电机速度)','EdgeColor','none','FontSize',8,...
    'Color','w','HorizontalAlignment','center','VerticalAlignment','middle');

% 求和节点2右→内环PI左
drawarrow(s2+0.018, y1, cx_ip-bw/2, y1);
annotation('textbox',[0.625,y1+0.03,0.07,0.03],...
    'String','e_\omega','EdgeColor','none','FontSize',10,...
    'FontWeight','bold','Color',c_inner,'HorizontalAlignment','center');

% 内环PI→电机: 从PI右边缘出发, 向下绕过虚线框, 再向左指向电机
drawline(cx_ip+bw/2, y1, cx_ip+bw/2+0.06, y1);
drawline(cx_ip+bw/2+0.06, y1, cx_ip+bw/2+0.06, y2+0.12);
drawarrow(cx_ip+bw/2+0.06, y2+0.12, cx_m, y2+0.075);
annotation('textbox',[cx_ip+bw/2+0.07,(y1+y2)/2+0.04,0.03,0.03],...
    'String','u','EdgeColor','none','FontSize',10,...
    'FontWeight','bold','Color',c_inner,'HorizontalAlignment','center');

% ===== 电机+减速器 =====
drawbox(cx_m, y2, 0.13, 0.15, c_plant);
annotation('textbox',[cx_m-0.065,y2+0.015,0.13,0.03],...
    'String','电机+减速器','EdgeColor','none','FontSize',9,...
    'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_m-0.065,y2-0.03,0.13,0.03],...
    'String','K_m / (\tau s+1)','EdgeColor','none','FontSize',8,...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% 电机左边缘→差速运动学右边缘
drawarrow(cx_m-0.065, y2, cx_a+0.08, y2);
annotation('textbox',[0.585,y2+0.05,0.10,0.03],...
    'String','\omega_L, \omega_R','EdgeColor','none','FontSize',9,...
    'Color',c_plant,'FontWeight','bold','HorizontalAlignment','center');

% ===== 差速AGV运动学 =====
cx_a = 0.50;
drawbox(cx_a, y2, 0.16, 0.15, c_plant);
annotation('textbox',[cx_a-0.08,y2+0.015,0.16,0.03],...
    'String','差速AGV运动学','EdgeColor','none','FontSize',9,...
    'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_a-0.08,y2-0.035,0.16,0.05],...
    'String',{'v=r(\omega_L+\omega_R)/2','\omega=r(\omega_R-\omega_L)/L'},...
    'EdgeColor','none','FontSize',7,'HorizontalAlignment','center','VerticalAlignment','middle');

% 差速运动学左边缘→实际位姿右边缘
drawarrow(cx_a-0.08, y2, 0.38, y2);

% ===== 实际位姿 =====
cx_o = 0.33;
drawbox(cx_o, y2, 0.10, 0.12, c_out);
annotation('textbox',[cx_o-0.05,y2+0.01,0.10,0.03],...
    'String','实际位姿','EdgeColor','none','FontSize',9,...
    'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
annotation('textbox',[cx_o-0.05,y2-0.025,0.10,0.03],...
    'String','x, y, \theta','EdgeColor','none','FontSize',8,...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% ===== 反馈路径 =====
% 反馈1: 实际位姿上边缘→求和节点1
fb1 = 0.10;
drawline(cx_o, y2+0.06, cx_o, y2+0.10);
drawline(cx_o, y2+0.10, fb1, y2+0.10);
drawline(fb1, y2+0.10, fb1, y1);
drawarrow(fb1, y1, s1-0.018, y1);
annotation('textbox',[0.075,0.48,0.06,0.05],...
    'String',{'位姿','反馈'},'EdgeColor','none','FontSize',8,...
    'Color',[0.5 0.5 0.5],'HorizontalAlignment','center');

% 反馈2: 电机上边缘→求和节点2
fb2 = 0.86;
drawline(cx_m, y2+0.075, cx_m, y2+0.13);
drawline(cx_m, y2+0.13, fb2, y2+0.13);
drawline(fb2, y2+0.13, fb2, y1);
drawarrow(fb2, y1, s2+0.018, y1);
annotation('textbox',[0.83,0.48,0.06,0.05],...
    'String',{'编码器','反馈'},'EdgeColor','none','FontSize',8,...
    'Color',[0.5 0.5 0.5],'HorizontalAlignment','center');

% ===== 虚线框 =====
annotation('rectangle',[0.03 0.58 0.57 0.26],...
    'Color',c_outer,'LineWidth',1.8,'LineStyle','--');
annotation('textbox',[0.04,0.84,0.15,0.03],...
    'String','外环（路径跟踪环）','EdgeColor','none','FontSize',10,...
    'FontWeight','bold','Color',c_outer);

annotation('rectangle',[0.58 0.58 0.32 0.26],...
    'Color',c_inner,'LineWidth',1.8,'LineStyle','--');
annotation('textbox',[0.59,0.84,0.12,0.03],...
    'String','内环（速度环）','EdgeColor','none','FontSize',10,...
    'FontWeight','bold','Color',c_inner);

% ===== 标题 =====
annotation('textbox',[0.30,0.93,0.40,0.04],...
    'String','级联双闭环PID控制系统结构框图','EdgeColor','none',...
    'FontSize',14,'FontWeight','bold','HorizontalAlignment','center');

% 保存
out_dir = fileparts(mfilename('fullpath'));
fname = fullfile(out_dir, 'cascaded_pid_diagram.png');
print(fig, fname, '-dpng', '-r200');
fprintf('已保存: %s\n', fname);
