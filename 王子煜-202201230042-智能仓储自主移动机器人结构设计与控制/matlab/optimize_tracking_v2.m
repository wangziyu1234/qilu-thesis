%% 循迹PID参数优化 v2 —— 扩大搜索范围 + 自迭代
function optimize_tracking_v2()
addpath(fileparts(mfilename('fullpath')));
ref_path = c_hybrid_astar();

%% 第一轮：粗搜索
fprintf('========== 第一轮：粗搜索 ==========\n');
Kp_list      = 2:0.5:8;
Kd_list      = 0.5:0.25:3;
v_list       = 0.15:0.05:0.35;
ma_list      = [4, 6, 8, 10, 12];

best_rms = inf;
best_cfg = [];
results = [];

total = length(Kp_list)*length(Kd_list)*length(v_list)*length(ma_list);
idx = 0;

for kp = Kp_list
    for kd = Kd_list
        for v = v_list
            for ma = ma_list
                idx = idx + 1;
                rms = run_tracking(ref_path, kp, 0.08, kd, v, ma);
                results(end+1, :) = [kp, kd, v, ma, rms]; %#ok<AGROW>
                if rms < best_rms
                    best_rms = rms;
                    best_cfg = [kp, 0.08, kd, v, ma];
                end
            end
        end
    end
end

fprintf('第一轮完成, 共 %d 组\n', total);
fprintf('当前最优: Kp=%.1f, Ki=0.08, Kd=%.1f, v=%.2f, ma=%d → RMS=%.4f cm\n', ...
    best_cfg(1), best_cfg(3), best_cfg(4), best_cfg(5), best_rms*100);

%% 第二轮：在最优附近精细搜索
fprintf('\n========== 第二轮：局部精细搜索 ==========\n');
kp0 = best_cfg(1); kd0 = best_cfg(3); v0 = best_cfg(4); ma0 = best_cfg(5);

Kp_fine = max(1, kp0-1):0.1:min(10, kp0+1);
Kd_fine = max(0.1, kd0-0.5):0.05:min(5, kd0+0.5);
v_fine  = max(0.1, v0-0.05):0.01:min(0.5, v0+0.05);
ma_fine = max(2, ma0-2):1:min(20, ma0+2);

total2 = length(Kp_fine)*length(Kd_fine)*length(v_fine)*length(ma_fine);
idx2 = 0;

for kp = Kp_fine
    for kd = Kd_fine
        for v = v_fine
            for ma = ma_fine
                idx2 = idx2 + 1;
                rms = run_tracking(ref_path, kp, 0.08, kd, v, ma);
                results(end+1, :) = [kp, kd, v, ma, rms]; %#ok<AGROW>
                if rms < best_rms
                    best_rms = rms;
                    best_cfg = [kp, 0.08, kd, v, ma];
                end
            end
        end
    end
end

fprintf('第二轮完成, 共 %d 组\n', total2);

%% 输出最终结果
results = sortrows(results, 5);
fprintf('\n========== 最终结果 ==========\n');
fprintf('最优: Kp=%.2f, Ki=0.08, Kd=%.2f, v=%.3f m/s, ma=%d\n', best_cfg);
fprintf('最优 RMS: %.4f cm\n', best_rms*100);

fprintf('\nTop-15 参数组合:\n');
fprintf('  Kp     Kd     v      ma   RMS(cm)\n');
for i = 1:min(15, size(results,1))
    fprintf('  %.2f  %.2f  %.3f  %3d  %.4f\n', results(i,1), results(i,2), results(i,3), results(i,4), results(i,5)*100);
end
end

%% 单次循迹仿真
function rms = run_tracking(ref_path, Kp, Ki, Kd, v_nom, ma_window)
    n_sensors = 5; sensor_spacing = 0.04;
    sensor_offsets = (-2:2) * sensor_spacing;
    line_width = 0.03;
    dt = 0.01; max_time = 80;

    ref_x_orig = ref_path(:,1); ref_y_orig = ref_path(:,2);
    n_orig = size(ref_path,1);
    s_orig = zeros(n_orig,1);
    for i = 2:n_orig
        s_orig(i) = s_orig(i-1) + hypot(ref_x_orig(i)-ref_x_orig(i-1), ref_y_orig(i)-ref_y_orig(i-1));
    end
    ds = 0.02;
    s_interp = 0:ds:s_orig(end);
    ref_x = interp1(s_orig, ref_x_orig, s_interp, 'pchip');
    ref_y = interp1(s_orig, ref_y_orig, s_interp, 'pchip');
    n_ref = length(ref_x);

    ref_theta = zeros(1, n_ref);
    for i = 1:n_ref-1
        ref_theta(i) = atan2(ref_y(i+1)-ref_y(i), ref_x(i+1)-ref_x(i));
    end
    ref_theta(end) = ref_theta(end-1);

    ref_kappa = zeros(1, n_ref);
    for i = 2:n_ref-1
        dtheta = ref_theta(i+1) - ref_theta(i);
        dtheta = atan2(sin(dtheta), cos(dtheta));
        ref_kappa(i) = dtheta / ds;
    end
    ref_kappa(1) = ref_kappa(2); ref_kappa(end) = ref_kappa(end-1);
    ref_kappa = movmean(ref_kappa, 5);

    n_steps = ceil(max_time / dt);
    x = ref_x(1); y = ref_y(1); theta = ref_theta(1);
    e_int = 0; e_prev = 0;
    omega_buf = zeros(1, ma_window); ma_idx = 0;
    v_ramp_time = 1.0;
    lat_errs = zeros(n_steps, 1);

    for k = 1:n_steps
        t_now = (k-1)*dt;
        if t_now < v_ramp_time
            v_now = v_nom * (t_now / v_ramp_time);
        else
            v_now = v_nom;
        end

        fwd = 0.08;
        sx = x + fwd*cos(theta) + sensor_offsets * cos(theta+pi/2);
        sy = y + fwd*sin(theta) + sensor_offsets * sin(theta+pi/2);
        sensor_state = zeros(1, n_sensors);
        for s = 1:n_sensors
            d = point_to_path(sx(s), sy(s), ref_x, ref_y);
            if d < line_width, sensor_state(s) = 1; end
        end
        active = find(sensor_state == 1);

        [~, min_i] = min((ref_x-x).^2 + (ref_y-y).^2);
        tang = ref_theta(min_i);
        lat_err = -(x-ref_x(min_i))*sin(tang) + (y-ref_y(min_i))*cos(tang);
        lat_errs(k) = lat_err;

        if ~isempty(active)
            offset = mean(sensor_offsets(active)) / sensor_spacing;
        else
            offset = sign(lat_err) * min(abs(lat_err)*15, 3);
        end

        e_int = e_int + offset * dt;
        e_int = max(-2, min(2, e_int));
        e_der = (offset - e_prev) / dt;
        e_prev = offset;

        omega_pid = Kp*offset + Ki*e_int + Kd*e_der;
        omega_ff = v_now * ref_kappa(min_i);
        omega_raw = omega_pid + omega_ff;
        omega_raw = max(-1.5, min(1.5, omega_raw));

        ma_idx = mod(ma_idx, ma_window) + 1;
        omega_buf(ma_idx) = omega_raw;
        omega = mean(omega_buf);

        x = x + v_now*cos(theta)*dt;
        y = y + v_now*sin(theta)*dt;
        theta = atan2(sin(theta+omega*dt), cos(theta+omega*dt));

        if hypot(x-ref_x(end), y-ref_y(end)) < 0.2
            lat_errs = lat_errs(1:k);
            break;
        end
    end
    rms = sqrt(mean(lat_errs.^2));
end

%% 点到折线最短距离
function d = point_to_path(px, py, path_x, path_y)
    d = inf;
    n = length(path_x);
    for i = 1:n-1
        ax = path_x(i);   ay = path_y(i);
        bx = path_x(i+1); by = path_y(i+1);
        abx = bx-ax;  aby = by-ay;
        apx = px-ax;  apy = py-ay;
        ab2 = abx^2 + aby^2;
        if ab2 < 1e-10
            t = 0;
        else
            t = max(0, min(1, (apx*abx+apy*aby)/ab2));
        end
        cx = ax + t*abx;
        cy = ay + t*aby;
        dd = hypot(px-cx, py-cy);
        if dd < d, d = dd; end
    end
end
