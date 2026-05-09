%% ========== PID 循迹仿真入口 ==========
%  生成参考路径并运行 line_following_pid 循迹仿真
%  用法: 直接 F5 运行
clear; clc; close all;

% 生成参考路径 (椭圆弧)
t = linspace(0, 3.5*pi, 200);
ref_path = [2 + 1.5*cos(t)', 2 + 0.8*sin(t)', atan2(0.8*cos(t), -1.5*sin(t))'];

line_following_pid(ref_path);
