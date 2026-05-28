%% 级联双闭环PID Simulink模型 —— 简洁版
clear; clc;

mdl = 'cascaded_pid_agv';
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl); open_system(mdl);

%% 参数
r = 0.09; L = 0.52; tau = 0.06; Km = 0.327;
Kp_v = 17; Ki_v = 103; u_sat = 24;
Kp_d = 0.6; Kp_th = 3; Ki_th = 0.2; Kd_th = 0.4;

%% 添加块
add_block('simulink/Sources/Step',[mdl '/v_ref'],'Position',[30 80 60 100],'Time','2','After','0.3');
add_block('simulink/Sources/Step',[mdl '/w_ref'],'Position',[30 160 60 180],'Time','2','After','0');

% 外环求和
add_block('simulink/Math Operations/Sum',[mdl '/e_v'],'Position',[120 85 140 105],'Inputs','+-');
add_block('simulink/Math Operations/Sum',[mdl '/e_w'],'Position',[120 165 140 185],'Inputs','+-');

% 外环PID
add_block('simulink/Continuous/PID Controller',[mdl '/PID_v'],'Position',[190 80 250 110],'P',num2str(Kp_d),'I','0','D','0');
add_block('simulink/Continuous/PID Controller',[mdl '/PID_w'],'Position',[190 160 250 190],'P',num2str(Kp_th),'I',num2str(Ki_th),'D',num2str(Kd_th),'N','100');

% 逆运动学增益
add_block('simulink/Math Operations/Gain',[mdl '/inv_r1'],'Position',[300 70 340 90],'Gain',num2str(1/r));
add_block('simulink/Math Operations/Gain',[mdl '/inv_r2'],'Position',[300 110 340 130],'Gain',num2str(1/r));
add_block('simulink/Math Operations/Gain',[mdl '/inv_L1'],'Position',[300 150 340 170],'Gain',num2str(-L/(2*r)));
add_block('simulink/Math Operations/Gain',[mdl '/inv_L2'],'Position',[300 190 340 210],'Gain',num2str(L/(2*r)));

% wL_ref, wR_ref 求和
add_block('simulink/Math Operations/Sum',[mdl '/wLref'],'Position',[390 85 410 105],'Inputs','++');
add_block('simulink/Math Operations/Sum',[mdl '/wRref'],'Position',[390 165 410 185],'Inputs','++');

% 内环求和
add_block('simulink/Math Operations/Sum',[mdl '/e_wL'],'Position',[460 85 480 105],'Inputs','+-');
add_block('simulink/Math Operations/Sum',[mdl '/e_wR'],'Position',[460 165 480 185],'Inputs','+-');

% 内环PI
add_block('simulink/Continuous/PID Controller',[mdl '/PI_L'],'Position',[520 80 580 110],'P',num2str(Kp_v),'I',num2str(Ki_v),'D','0');
add_block('simulink/Continuous/PID Controller',[mdl '/PI_R'],'Position',[520 160 580 190],'P',num2str(Kp_v),'I',num2str(Ki_v),'D','0');

% 限幅
add_block('simulink/Discontinuities/Saturation',[mdl '/Sat_L'],'Position',[620 85 650 105],'UpperLimit',num2str(u_sat),'LowerLimit',num2str(-u_sat));
add_block('simulink/Discontinuities/Saturation',[mdl '/Sat_R'],'Position',[620 165 650 185],'UpperLimit',num2str(u_sat),'LowerLimit',num2str(-u_sat));

% 电机传递函数
add_block('simulink/Continuous/Transfer Fcn',[mdl '/Motor_L'],'Position',[690 80 760 110],'Numerator',num2str(Km),'Denominator',['[' num2str(tau) ' 1]']);
add_block('simulink/Continuous/Transfer Fcn',[mdl '/Motor_R'],'Position',[690 160 760 190],'Numerator',num2str(Km),'Denominator',['[' num2str(tau) ' 1]']);

% AGV运动学: v = r/2*(wL+wR), w = r/L*(wR-wL)
add_block('simulink/Math Operations/Sum',[mdl '/sum_wLwR'],'Position',[820 85 840 105],'Inputs','++');
add_block('simulink/Math Operations/Sum',[mdl '/sum_wRwL'],'Position',[820 165 840 185],'Inputs','+-');
add_block('simulink/Math Operations/Gain',[mdl '/G_v'],'Position',[880 85 920 105],'Gain',num2str(r/2));
add_block('simulink/Math Operations/Gain',[mdl '/G_w'],'Position',[880 165 920 185],'Gain',num2str(r/L));

% theta积分
add_block('simulink/Continuous/Integrator',[mdl '/Int_th'],'Position',[960 165 1000 185],'InitialCondition','0');

% cos/sin
add_block('simulink/Math Operations/Trigonometric Function',[mdl '/cos_th'],'Position',[1040 60 1080 80],'Operator','cos');
add_block('simulink/Math Operations/Trigonometric Function',[mdl '/sin_th'],'Position',[1040 100 1080 120],'Operator','sin');

% v*cos, v*sin
add_block('simulink/Math Operations/Product',[mdl '/mul_x'],'Position',[1120 65 1145 85]);
add_block('simulink/Math Operations/Product',[mdl '/mul_y'],'Position',[1120 105 1145 125]);

% x, y积分
add_block('simulink/Continuous/Integrator',[mdl '/Int_x'],'Position',[1190 65 1230 85],'InitialCondition','0');
add_block('simulink/Continuous/Integrator',[mdl '/Int_y'],'Position',[1190 105 1230 125],'InitialCondition','0');

% Scope
add_block('simulink/Sinks/Scope',[mdl '/Scope'],'Position',[1280 80 1320 160]);

%% 连线 — 外环
add_line(mdl,'v_ref/1','e_v/1');
add_line(mdl,'e_v/1','PID_v/1');
add_line(mdl,'w_ref/1','e_w/1');
add_line(mdl,'e_w/1','PID_w/1');

%% 连线 — 逆运动学
add_line(mdl,'PID_v/1','inv_r1/1');
add_line(mdl,'PID_v/1','inv_r2/1');
add_line(mdl,'PID_w/1','inv_L1/1');
add_line(mdl,'PID_w/1','inv_L2/1');
add_line(mdl,'inv_r1/1','wLref/1');
add_line(mdl,'inv_L1/1','wLref/2');
add_line(mdl,'inv_r2/1','wRref/1');
add_line(mdl,'inv_L2/1','wRref/2');

%% 连线 — 内环
add_line(mdl,'wLref/1','e_wL/1');
add_line(mdl,'e_wL/1','PI_L/1');
add_line(mdl,'PI_L/1','Sat_L/1');
add_line(mdl,'Sat_L/1','Motor_L/1');

add_line(mdl,'wRref/1','e_wR/1');
add_line(mdl,'e_wR/1','PI_R/1');
add_line(mdl,'PI_R/1','Sat_R/1');
add_line(mdl,'Sat_R/1','Motor_R/1');

%% 连线 — 内环反馈(轮速)
add_line(mdl,'Motor_L/1','e_wL/2');
add_line(mdl,'Motor_R/1','e_wR/2');

%% 连线 — AGV运动学
add_line(mdl,'Motor_L/1','sum_wLwR/1');
add_line(mdl,'Motor_R/1','sum_wLwR/2');
add_line(mdl,'Motor_R/1','sum_wRwL/1');
add_line(mdl,'Motor_L/1','sum_wRwL/2');
add_line(mdl,'sum_wLwR/1','G_v/1');
add_line(mdl,'sum_wRwL/1','G_w/1');

% theta
add_line(mdl,'G_w/1','Int_th/1');
add_line(mdl,'Int_th/1','cos_th/1');
add_line(mdl,'Int_th/1','sin_th/1');

% x = integral(v*cos(th)), y = integral(v*sin(th))
add_line(mdl,'G_v/1','mul_x/1');
add_line(mdl,'cos_th/1','mul_x/2');
add_line(mdl,'G_v/1','mul_y/1');
add_line(mdl,'sin_th/1','mul_y/2');
add_line(mdl,'mul_x/1','Int_x/1');
add_line(mdl,'mul_y/1','Int_y/1');

% Scope
add_line(mdl,'Int_x/1','Scope/1');

%% 连线 — 外环反馈
add_line(mdl,'G_v/1','e_v/2');    % v反馈
add_line(mdl,'G_w/1','e_w/2');    % w反馈

%% 仿真参数
set_param(mdl,'StopTime','12','Solver','ode45','MaxStep','0.005');
save_system(mdl);
fprintf('模型已创建: %s.slx\n',mdl);
