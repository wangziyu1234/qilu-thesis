import codecs

with codecs.open('D:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/pages/body.tex',
                  'r', 'utf-8') as f:
    content = f.read()

old = '    \\section{双轮差速PID控制器设计}\n    \\xfbody{\n   \n}\n    \\section{基本运动控制实现}\n    \\xfbody{\n}\n    \\section{控制效果仿真验证}xiufu\n    \\xfbody{\n    \n}'

new = r'''    \section{双轮差速PID控制器设计}
    \xfbody{

    针对双轮差速AGV的运动控制问题，本文采用双环PID级联控制架构。外环为位姿环，依据位置偏差和航向偏差计算期望线速度$v_{\mathrm{cmd}}$和期望角速度$\omega_{\mathrm{cmd}}$；内环为轮速环，由左右两个独立的PI控制器构成，负责跟踪外环下发的轮速指令并输出电机控制电压。内环响应频率约为外环的3$\sim$5倍，保证内环优先收敛后再由外环进行位姿修正。

    \begin{figure}[H]
    \centering
    \includegraphics[width=0.85\textwidth]{pid simulink.png}
    \caption{双环PID控制架构框图}
    \label{fig:dual_loop_pid}
    \end{figure}

    外环（位姿环）的输入为期望位姿与当前位姿之间的偏差，输出为线速度指令和角速度指令。以定点镇定为例，设目标位姿为$(x_t, y_t, \theta_t)$，当前位姿为$(x, y, \theta)$。当机器人距离目标较远时，期望航向指向目标点方向$\arctan(y_t-y, x_t-x)$，驱动机器人朝向目标点运动；当距离缩小至阈值以内后，期望航向切换为目标角度$\theta_t$，完成姿态对准。航向偏差经PID运算后输出角速度指令$\omega_{\mathrm{cmd}}$，距离偏差经比例运算后输出线速度指令$v_{\mathrm{cmd}}$。为避免大幅度转向时出现失控，当航向偏差超过$\pi/3$时将线速度缩减至正常值的$20\%$，优先完成转向。

    外环输出的$(v_{\mathrm{cmd}}, \omega_{\mathrm{cmd}})$经差速逆运动学转换为左右轮角速度指令：
    \begin{equation}
    \omega_{L,\mathrm{ref}} = \frac{v_{\mathrm{cmd}}}{r} - \frac{\omega_{\mathrm{cmd}}L}{2r},\quad
    \omega_{R,\mathrm{ref}} = \frac{v_{\mathrm{cmd}}}{r} + \frac{\omega_{\mathrm{cmd}}L}{2r}
    \label{eq:inverse_kinematics_ctrl}
    \end{equation}

    内环（轮速环）对左右轮各配置一个PI控制器。以左轮为例，控制律为：
    \begin{equation}
    u_L = K_p^v e_{\omega L} + K_i^v \int e_{\omega L}\,\mathrm{d}t,\quad e_{\omega L} = \omega_{L,\mathrm{ref}} - \omega_L
    \label{eq:wheel_pi}
    \end{equation}
    其中$K_p^v$和$K_i^v$分别为轮速环的比例增益和积分增益，$e_{\omega L}$为左轮速偏差，$u_L$为左电机电压指令。速度环采用PI而非PID的原因在于：微分项对编码器测量噪声较为敏感，在低速工况下容易引入电压抖动，恶化控制品质。

    双环PID控制器的各项参数见表\ref{tab:pid_params}。
    \begin{table}[H]
    \wuhao
    \centering
    \caption{双环PID控制器参数}
    \label{tab:pid_params}
    \begin{tabular}{cccc}
    \toprule
    控制器 & $K_p$ & $K_i$ & $K_d$ \\
    \midrule
    位姿环（航向PID） & 3.0 & 0.2 & 0.4 \\
    轮速环（左/右PI） & 2.0 & 12.0 & -- \\
    \bottomrule
    \end{tabular}
    \end{table}
    }
    \section{基本运动控制实现}
    \xfbody{

    控制器在STM32F103C8T6上以定时器中断方式周期性执行，中断周期$T_s=5\,\mathrm{ms}$。每个中断周期内的控制流程为：编码器脉冲计数→轮速计算→外环位姿PID→逆运动学解算→内环轮速PI→PWM输出。

    数字PID采用位置式算法，积分项做如下离散化处理：
    \begin{equation}
    u(k) = K_p e(k) + K_i T_s \sum_{j=0}^{k} e(j) + \frac{K_d}{T_s}\bigl[e(k) - e(k-1)\bigr]
    \label{eq:discrete_pid}
    \end{equation}

    为抑制积分饱和，轮速PI引入积分分离与遇限削弱积分两项措施。积分分离策略为：当轮速偏差$|e| > 8.0\,\mathrm{rad/s}$时清零积分项，仅保留比例控制以加速响应；当偏差落入阈值以内时重新激活积分，消除稳态误差。遇限削弱积分策略为：当PI输出超出电压限幅（$\pm12\,\mathrm{V}$）时停止正向积分累加，退回本次累加量，防止积分项在饱和状态下无意义增长。

    轮速测量利用SMC80S电机自带的$2500\,\mathrm{P/R}$增量式编码器，经STM32定时器编码器接口以四倍频模式采集，每转输出$10000$个脉冲。轮速估算采用M法（单位时间脉冲计数法）：$\omega = 2\pi \Delta N / (10000 \cdot T_s)$，其中$\Delta N$为$5\,\mathrm{ms}$内的脉冲增量。
    }
    \section{控制效果仿真验证}
    \xfbody{

    为验证双环PID控制器的有效性，在MATLAB环境下搭建差速AGV闭环仿真模型。仿真参数与实物设计保持一致：轮半径$r=0.075\,\mathrm{m}$，轮距$L=0.52\,\mathrm{m}$，电机机电时间常数$\tau=0.06\,\mathrm{s}$，电机增益$K_m=2.8\,\mathrm{(rad/s)/V}$，仿真步长$0.005\,\mathrm{s}$。设置四项测试场景：阶跃响应（验证速度跟踪能力）、定点镇定（验证位姿收敛能力）、直线跟踪（验证直行保持能力）和圆形轨迹跟踪（验证连续曲线跟踪能力）。

    \textbf{场景1——阶跃响应：}在$2.5\,\mathrm{s}$时施加幅度为$0.3\,\mathrm{m/s}$的线速度阶跃指令，同时保持角速度指令为零。仿真结果如图\ref{fig:pid_step_response}所示。速度响应无超调、无明显振荡，调节时间约$0.8\,\mathrm{s}$；稳态速度误差约为零，表明轮速PI能够快速且准确地跟踪参考指令。左右轮速指令在阶跃阶段保持一致，角速度始终维持在零附近，验证了直线行驶时两轮速度的同步性。电机电压在阶跃瞬间出现短暂峰值后迅速回落至稳态值，未触及饱和限。航向角全程保持$0^\circ$，未出现因轮速不一致导致的航向偏移。

    \begin{figure}[H]
    \centering
    \includegraphics[width=0.85\textwidth]{pid_step_response.png}
    \caption{阶跃响应仿真结果}
    \label{fig:pid_step_response}
    \end{figure}

    \textbf{场景2——定点镇定：}设定目标位姿为$(2.0, 1.0, \pi/4)$，即距起点约$2.24\,\mathrm{m}$、目标航向$45^\circ$。仿真结果如图\ref{fig:pid_point_stabilization}所示。机器人轨迹平滑收敛至目标点，终点位置误差为$(0.022, -0.007)\,\mathrm{m}$，终点航向误差为$-0.85^\circ$。运动过程分为两个明显的阶段：第一阶段机器人以前进转向方式朝向目标点运动，线速度随距离减小而平滑降低；第二阶段距离缩小至$8\,\mathrm{cm}$以下后，机器人主要进行原地姿态微调，直至航向误差收敛至$1^\circ$以内。

    \begin{figure}[H]
    \centering
    \includegraphics[width=0.85\textwidth]{pid_point_stabilization.png}
    \caption{定点镇定仿真结果}
    \label{fig:pid_point_stabilization}
    \end{figure}

    \textbf{场景3——圆形轨迹跟踪：}跟踪半径为$0.8\,\mathrm{m}$、周期为$16\,\mathrm{s}$的圆形轨迹，线速度约$0.31\,\mathrm{m/s}$。仿真结果如图\ref{fig:pid_circle_tracking}所示。实际轨迹与参考圆基本重合，轨迹圆度RMSE为$0.021\,\mathrm{m}$；线速度RMSE为$0.0088\,\mathrm{m/s}$，角速度RMSE为$0.0030\,\mathrm{rad/s}$。航向角呈线性增长，与参考航向一致，说明机器人以恒定角速度平稳完成圆周运动。左右轮速保持恒定差值，对应差速转向所需的稳态轮速分配。

    \begin{figure}[H]
    \centering
    \includegraphics[width=0.85\textwidth]{pid_circle_tracking.png}
    \caption{圆形轨迹跟踪仿真结果}
    \label{fig:pid_circle_tracking}
    \end{figure}

    四项场景的定量结果汇总如表\ref{tab:pid_sim_summary}所示。仿真结果表明，所设计的双环PID控制器在四种典型工况下均能实现较好的控制效果：定点镇定终点位置误差在厘米级、航向误差在$1^\circ$以内；连续轨迹跟踪的线速度和角速度RMSE均在$0.01\,\mathrm{m/s}$和$0.005\,\mathrm{rad/s}$量级，满足仓储AGV对基本运动控制精度的需求。

    \begin{table}[H]
    \wuhao
    \centering
    \caption{双环PID控制仿真结果汇总}
    \label{tab:pid_sim_summary}
    \begin{tabular}{ccc}
    \toprule
    测试场景 & 评价指标 & 结果 \\
    \midrule
    阶跃响应 & 速度稳态误差 & $\approx 0\,\mathrm{m/s}$ \\
    \multirow{2}{*}{定点镇定} & 终点位置误差 & $(0.022, -0.007)\,\mathrm{m}$ \\
    & 终点航向误差 & $-0.85^\circ$ \\
    直线跟踪 & 角速度RMSE & $0.0023\,\mathrm{rad/s}$ \\
    \multirow{3}{*}{圆形跟踪} & 线速度RMSE & $0.0088\,\mathrm{m/s}$ \\
    & 角速度RMSE & $0.0030\,\mathrm{rad/s}$ \\
    & 轨迹圆度RMSE & $0.021\,\mathrm{m}$ \\
    \bottomrule
    \end{tabular}
    \end{table}

    需要指出的是，本文仿真在理想地面条件下完成，未引入轮地摩擦系数扰动、电机死区、传感器噪声和通信延迟等因素。实际应用中AGV在负载变化、地面不平整等工况下的控制性能尚需通过实物实验进一步检验。此外，PID参数在仿真前整定后保持不变，对工况变化的适应能力有限，后续可引入模糊PID或模型预测控制等策略以提升鲁棒性。
    }'''

if old in content:
    content = content.replace(old, new)
    with codecs.open('D:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/pages/body.tex',
                      'w', 'utf-8') as f:
        f.write(content)
    print('Done!')
else:
    # Try to find what's different
    idx_sec = content.find(r'\section{双轮差速PID控制器设计}')
    if idx_sec >= 0:
        snippet = content[idx_sec:idx_sec+len(old)]
        print('Found section at', idx_sec)
        print('Expected length:', len(old), 'Actual length:', len(snippet))
        if snippet == old:
            print('Strings match!')
        else:
            for i, (a, b) in enumerate(zip(old, snippet)):
                if a != b:
                    print(f'Mismatch at char {i}: old={repr(a)} new={repr(b)}')
                    break
    else:
        print('Section not found!')
