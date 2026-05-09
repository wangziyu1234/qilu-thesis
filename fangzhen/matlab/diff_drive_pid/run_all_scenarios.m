%% 批量运行四个场景
% 齐鲁工业大学 机械学院 王子煜

scenarios = [1, 2, 3, 4];
for s = 1:4
    SCENARIO = s;
    fprintf('\n========== 运行场景 %d ==========\n', SCENARIO);
    run('diff_drive_pid_sim.m');
    close all;
end
fprintf('\n全部场景运行完毕。\n');
