const fs = require('fs');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType,
        HeadingLevel, BorderStyle, WidthType, ShadingType,
        PageNumber, PageBreak, TableOfContents } = require('docx');

// ===== Formatting constants (from template) =====
const FONT_SONG = 'SimSun';        // 宋体
const FONT_HEI = 'SimHei';         // 黑体
const FONT_FANGSONG = 'FangSong';  // 仿宋
const FONT_TNR = 'Times New Roman';

const SIZE_SANHAO = 32;    // 三号 = 16pt = 32 half-pt
const SIZE_SIHAO = 28;     // 四号 = 14pt = 28 half-pt
const SIZE_XIAOSI = 24;    // 小四 = 12pt = 24 half-pt
const SIZE_WUHAO = 20;     // 五号 = 10pt = 20 half-pt
const SIZE_XIAOWU = 18;    // 小五 = 9pt = 18 half-pt

const LINE_SPACING = 360;  // 1.5倍行距 (240 * 1.5 = 360)

// ===== Helper functions =====
function bodyP(text, opts = {}) {
  return new Paragraph({
    children: [new TextRun({ text, font: opts.font || FONT_SONG, size: opts.size || SIZE_XIAOSI })],
    spacing: { line: LINE_SPACING, before: opts.before || 0, after: opts.after || 0 },
    indent: opts.noIndent ? undefined : { firstLine: 480 },
    alignment: opts.alignment,
    pageBreakBefore: opts.pageBreakBefore,
  });
}

function bodyMixed(runs) {
  return new Paragraph({
    children: runs.map(r => new TextRun({ font: r.font || FONT_SONG, size: r.size || SIZE_XIAOSI, bold: r.bold, text: r.text })),
    spacing: { line: LINE_SPACING },
  });
}

function h1Text(text) {
  // 一级标题：中文黑体+数字西文TNR，三号，加粗，居中
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    alignment: AlignmentType.CENTER,
    spacing: { before: 240, after: 240, line: LINE_SPACING },
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_SANHAO, bold: true })],
  });
}

function h2Text(text) {
  // 二级标题：黑体+TNR 四号 顶格
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 180, after: 120, line: LINE_SPACING },
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_SIHAO, bold: true })],
  });
}

function h3Text(text) {
  // 三级标题：黑体+TNR 四号 顶格
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 120, after: 120, line: LINE_SPACING },
    children: [new TextRun({ text, font: FONT_HEI, size: SIZE_SIHAO, bold: true })],
  });
}

function emptyP() {
  return new Paragraph({ spacing: { after: 0, line: LINE_SPACING }, children: [] });
}

function centerP(text, font, size, bold = true) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { line: LINE_SPACING, after: 200 },
    children: [new TextRun({ text, font, size, bold })],
  });
}

// ===== COVER PAGE =====
function coverPage() {
  return [
    new Paragraph({ spacing: { before: 800 }, children: [] }),
    centerP('齐鲁工业大学', FONT_SONG, 44, true),
    centerP('本科毕业论文（设计）', FONT_SONG, 44, true),
    new Paragraph({ spacing: { before: 600 }, children: [] }),
    centerP('智能仓储自主移动机器人结构设计与控制', FONT_HEI, SIZE_SANHAO, true),
    new Paragraph({ spacing: { before: 400 }, children: [] }),
    ...[
      ['学部（学院）', '机械工程学院'],
      ['专业班级', '机器人（SI）22-2'],
      ['学生姓名', '王子煜'],
      ['学号', '202201230042'],
      ['导师姓名', '刘鹏博'],
    ].map(([label, value]) => new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 120, line: LINE_SPACING },
      children: [
        new TextRun({ text: `${label}    `, font: FONT_SONG, size: SIZE_XIAOSI }),
        new TextRun({ text: value, font: FONT_SONG, size: SIZE_XIAOSI, underline: { type: 'single' } }),
      ],
    })),
    new Paragraph({ spacing: { before: 600 }, children: [] }),
    centerP('2026年03月10日', FONT_SONG, SIZE_XIAOSI, false),
  ];
}

// ===== DECLARATION =====
function declarationPage() {
  return [
    centerP('原创性声明', FONT_SONG, SIZE_SANHAO, true),
    bodyP('本人郑重声明：所呈交的毕业论文（设计），是本人在指导教师的指导下独立研究、撰写的成果。论文（设计）中引用他人的文献、数据、图件、资料，均已在论文（设计）中加以说明，除此之外，本论文（设计）不含任何其他个人或集体已经发表或撰写的成果作品。对本文研究做出重要贡献的个人和集体，均已在文中作了明确说明并表示了谢意。本声明的法律结果由本人承担。'),
    new Paragraph({ spacing: { before: 600 }, children: [] }),
    new Paragraph({ alignment: AlignmentType.RIGHT, spacing: { line: LINE_SPACING }, children: [new TextRun({ text: '毕业论文（设计）作者签名：', font: FONT_SONG, size: SIZE_XIAOSI })] }),
    new Paragraph({ alignment: AlignmentType.RIGHT, spacing: { line: LINE_SPACING }, children: [new TextRun({ text: '　　　　　　　　　　　　　　　　　　　　　　　　　　　　　年　　月　　日', font: FONT_SONG, size: SIZE_XIAOSI })] }),
    new Paragraph({ children: [new PageBreak()] }),
    centerP('齐鲁工业大学本科毕业论文（设计）', FONT_SONG, SIZE_SANHAO, true),
    centerP('使用授权说明', FONT_SONG, SIZE_SANHAO, true),
    bodyP('本毕业论文（设计）作者完全了解学校有关保留、使用毕业论文（设计）的规定，即：学校有权保留、送交论文（设计）的复印件，允许论文（设计）被查阅和借阅，学校可以公布论文（设计）的全部或部分内容，可以采用影印、扫描等复制手段保存本论文（设计）。'),
    new Paragraph({ spacing: { before: 400 }, children: [] }),
    new Paragraph({ spacing: { line: LINE_SPACING }, children: [new TextRun({ text: '指导教师签名：　　　　　　　　', font: FONT_SONG, size: SIZE_XIAOSI })] }),
    new Paragraph({ spacing: { line: LINE_SPACING }, children: [new TextRun({ text: '毕业论文（设计）作者签名：　　　　　　　　', font: FONT_SONG, size: SIZE_XIAOSI })] }),
    new Paragraph({ spacing: { line: LINE_SPACING }, children: [new TextRun({ text: '　　　　　年　　月　　日　　　　 　　　　　　　　　　　年　　月　　日', font: FONT_SONG, size: SIZE_XIAOSI })] }),
  ];
}

// ===== ABSTRACT =====
function abstractCN() {
  return [
    new Paragraph({ children: [new PageBreak()] }),
    centerP('摘　　要', FONT_HEI, SIZE_SANHAO, true),
    emptyP(),
    bodyP('针对中小型仓储场景中物料搬运自动化程度不足的问题，本文设计了一款集成剪叉式举升功能的双轮差速驱动移动机器人。通过多方案对比，确定了"交流伺服电机+行星减速器"的动力方案、ARM单片机嵌入式控制系统，以及Hybrid A*全局路径规划与双环PID运动控制相配合的导航控制策略。'),
    bodyP('升降机构运动学建模与强度校核表明，在50 kg额定载重下，臂杆最危险工况的压弯组合应力仅为5.56 MPa，承载平台von Mises等效应力为14.1 MPa，均远低于Q235钢156.7 MPa的许用应力；增设侧向支撑后，臂杆屈曲安全系数由2.54升至10.1，结构安全裕度充足。'),
    bodyP('MATLAB控制仿真覆盖了阶跃响应、定点镇定、直线跟踪和圆形轨迹跟踪四种典型工况。定点镇定终点位置误差收敛至厘米级，航向偏差小于1°；连续轨迹跟踪的线速度与角速度RMSE分别低于0.01 m/s和0.005 rad/s。路径规划方面，Hybrid A*算法在含障碍物的仓储地图上生成了长11.04 m的无碰撞平滑路径，红外循迹PID控制器以1.5 cm的RMS横向误差实现了对该路径的稳定跟踪。'),
    bodyP('研究结果表明，本文所设计的机器人在结构强度、运动控制精度与路径规划可行性方面均达到预期指标，可为同类举升式仓储搬运机器人的工程研制提供参考。'),
    emptyP(),
    new Paragraph({ spacing: { line: LINE_SPACING }, children: [
      new TextRun({ text: '关键词：', font: FONT_HEI, size: SIZE_XIAOSI, bold: true }),
      new TextRun({ text: '智能仓储移动机器人；差速驱动；路径规划；Hybrid A*；PID运动控制', font: FONT_FANGSONG, size: SIZE_XIAOSI }),
    ]}),
  ];
}

function abstractEN() {
  return [
    new Paragraph({ children: [new PageBreak()] }),
    centerP('ABSTRACT', FONT_TNR, SIZE_SANHAO, true),
    emptyP(),
    bodyP('Aiming at the insufficient automation of material handling in small-to-medium warehouse environments, this thesis presents a dual-wheel differential-drive mobile robot with an integrated scissor-type lifting mechanism. Through comparative analysis of multiple design options, an AC servo motor with planetary reducer drive scheme, an ARM Cortex-M microcontroller-based embedded control system, and a navigation strategy combining Hybrid A* global path planning with dual-loop PID motion control are established.', { font: FONT_TNR }),
    bodyP('Kinematic modeling and strength verification of the lifting mechanism demonstrate that, under the rated payload of 50 kg, the combined compressive-bending stress of the scissor arm in the worst-case condition is merely 5.56 MPa, and the von Mises equivalent stress of the loading platform is 14.1 MPa — both far below the 156.7 MPa allowable stress of Q235 steel. With lateral bracing added, the buckling safety factor of the arm increases from 2.54 to 10.1, providing an ample safety margin.', { font: FONT_TNR }),
    bodyP('MATLAB control simulations cover four typical scenarios: step response, point stabilization, straight-line tracking, and circular trajectory tracking. The terminal positioning error in point stabilization converges to the centimeter level with heading deviation under 1°; the RMSE of linear and angular velocities in continuous trajectory tracking are below 0.01 m/s and 0.005 rad/s, respectively. For path planning, the Hybrid A* algorithm generates a collision-free smooth path of 11.04 m in a warehouse map with obstacles, and an infrared-sensor-based PID line-tracking controller achieves stable tracking with an RMS lateral error of 1.5 cm.', { font: FONT_TNR }),
    bodyP('The results indicate that the proposed robot meets the design targets in structural strength, motion control accuracy, and path planning feasibility, providing a reference for the engineering development of similar lifting-type warehouse handling robots.', { font: FONT_TNR }),
    emptyP(),
    new Paragraph({ spacing: { line: LINE_SPACING }, children: [
      new TextRun({ text: 'Key words: ', font: FONT_TNR, size: SIZE_XIAOSI, bold: true }),
      new TextRun({ text: 'intelligent warehouse mobile robot; differential drive; path planning; Hybrid A*; PID motion control', font: FONT_TNR, size: SIZE_XIAOSI }),
    ]}),
  ];
}

// ===== CHAPTER 1: 引言 (FULL CONTENT) =====
function ch1() {
  return [
    new Paragraph({ children: [new PageBreak()] }),
    h1Text('第1章 引言'),
    h2Text('1.1 研究背景和意义'),
    bodyP('根据商务部发布的《中国新电商发展报告（2025）》，2024年我国网络零售额达到15.5万亿元，同比增长7.2%，对社会消费品零售总额贡献约1.7个百分点，我国已连续12年保持全球最大网络零售市场的地位。电商规模的持续扩大使仓储与物流环节逐步演变为整体效率提升的主要瓶颈。依靠人工完成的仓储作业在效率和响应速度上已无法匹配不断攀升的订单量，这一现实促使学术界和产业界将目光投向智能仓储中的自主移动机器人。'),
    bodyP('在智能仓储领域，自主移动机器人根据导航方式和功能定位可划分为若干类型。自动导引车（AGV）依靠磁条、二维码等预设标识导航，适用于路径固定的场景；自主移动机器人（AMR）引入激光雷达、视觉传感器和SLAM技术，具备自主感知与动态决策能力，适合复杂多变的仓储环境。各类机器人的核心目标高度一致——在仓储场景中实现高效、安全、自主的物料搬运。'),
    bodyP('自动导引车（AGV）集自主导航、路径规划和货物搬运于一体，可在结构化仓储场景中独立完成物流作业。市场数据表明，2019年至2024年中国AGV行业规模从48.27亿元攀升至95.49亿元；AMR市场同样增长迅猛，2023年规模已突破60亿元，年增长率超过30%，反映出行业从"固定路径导引"向"自主感知决策"升级的清晰趋势。'),
    bodyP('然而，随着电商物流向更多品类、更高时效的方向发展，仓储场景对自主移动机器人提出了更高要求：作业环境日趋动态化，柔性订单结构使搬运路径不再固定，机器人需在人机混行环境中稳定运行；系统需从固定路径导引升级为自主感知与实时决策；在环境感知、路径规划和任务调度等方面，需兼顾全局最优性与局部实时性。'),
    bodyP('在上述挑战驱动下，自主移动机器人的研究已延伸至环境感知与运动控制深度融合、多机协同调度等深层次问题。但目前针对中小型仓储场景中兼具举升功能与自主导航能力的紧凑型机器人的系统性工程研究仍不充分。本文以一款举升式自主搬运机器人为研究对象，围绕总体方案设计、机械与电气系统、运动学建模与运动控制等关键环节展开研究，旨在为该类机器人的设计与开发提供理论依据和技术参考。'),
    h2Text('1.2 自主移动机器人在智能仓储场景中的国内外研究现状'),
    h3Text('1.2.1 国外研究现状'),
    bodyP('国外在自主移动机器人领域的研发和商业化起步较早。亚马逊2012年收购Kiva Systems后批量部署Kiva机器人，以"货架到人"模式将拣选效率提高2至3倍，其通过中央调度协调多机器人协同的理念深刻影响了行业走向。近年来AMR成为新趋势，Fetch Robotics、Locus Robotics等公司推出的AMR利用激光雷达和SLAM实现自主定位，无需改造仓库地面即可部署。欧洲方面，Magazino的TORU实现了从搬运货架到视觉抓取单品的技术跨越，KUKA和ABB等将机械臂与移动底盘结合推出复合型移动操作机器人。波士顿动力的Atlas和Spot则在复杂地形适应方面展现出高水平。'),
    bodyP('在算法维度，Hybrid A*因能生成满足运动约束的路径而被广泛采纳，MAPF为多机协同提供了理论支撑。近年研究焦点转向深度强化学习（DQN、PPO）的落地应用，以及数字孪生仿真、云-边-端协同调度等方向。自主移动机器人的应用也从仓储拓展到智能城市、医疗和农业等领域。'),
    h3Text('1.2.2 国内研究现状'),
    bodyP('国内对自主移动机器人的研究可追溯至20世纪70年代末，早期以引进仿制为主。进入21世纪后，制造业升级与电商增长使仓储机器人成为关注焦点，2012年亚马逊收购Kiva更推动了国内企业的布局。'),
    bodyP('在产业应用层面，京东物流自2014年起建设亚洲一号智能仓群，自主研发了"地狼"AGV和"天狼"穿梭系统，并与极智嘉（Geek+）合作引入AMR方案。菜鸟网络在无锡、惠阳等地部署了数百台AGV与AMR，其"小蛮驴"配送机器人将应用从仓储延伸至末端配送。海康威视、旷视科技、快仓等企业在仓储机器人领域形成成熟产品线，国产化产业链逐步成形。'),
    bodyP('技术层面，导航技术从磁条/二维码引导迭代至激光SLAM和视觉SLAM方案；多机协同方面提出了多种分布式和集中式调度策略；算法方面围绕改进A*、遗传算法、蚁群算法等积累了理论成果。总体而言，国内在核心算法成熟度和大规模部署经验上与国际先进水平仍有差距，但差距正在收窄，应用前景广阔。'),
    h2Text('1.3 国内外智能仓储移动机器人路径规划算法研究现状'),
    bodyP('在国外研究方面，M Rybczak等人梳理了移动机器人控制中机器学习算法面临的计算资源、实时决策、环境适应性和安全可靠性等挑战。MFR Lee等人将深度Q网络（DQN）和双深度Q网络（DDQN）引入移动机器人导航与避撞学习。Y Dai等人剖析了传统鲸鱼优化算法及其改进方法在移动机器人路径规划中的不足。S Das等人提出了自适应随机梯度下降线性回归（ASGDLR）算法，用于识别自主移动机器人左右转向运动特征。B Tao等人提出了具有随机扰动策略的双种群粒子群优化算法，以改善传统粒子群优化在约束问题中的局限性。T Guo等人提出了一种基于改进A*和动态窗口法（DWA）融合的AGV路径规划算法，旨在解决传统A*搜索效率低、不考虑AGV尺寸和转弯次数过多，以及DWA易陷入局部最优的问题。K Fransen等人提出了一种改进的A*算法启发式方法，可用于在具有转向成本的几何图中找到最低成本路径。T Heinemann等人提出了一种路径规划概念及评估方法，用于改进向量场直方图和动态窗口算法，以实现平滑轨迹生成。'),
    bodyP('在国内研究方面，学者们围绕仓储机器人路径规划与轨迹跟踪进行了大量探索。黄晓宇等人设计了一种模型预测控制（MPC）与微分先行比例-积分-微分（PID）协同的双闭环控制策略，用于麦克纳姆轮全向移动平台的轨迹跟踪控制。曹梦龙等人梳理了机器人路径规划的基本步骤，并概述了群体智能优化算法在路径规划中的应用。白宇鑫等人提出了改进的哈里斯鹰优化算法以解决机器人路径规划问题，并剖析了HHO算法在收敛性和局部最优方面的局限性。赖荣燊等人探讨了传统A*算法与动态窗口法的优缺点及其改进方向。张瑞等人提出了RRT*与DWA融合的路径规划方法，旨在提升复杂动态环境下移动机器人路径规划的安全性和最优性。肖金壮等人设计了一种面向室内自动导引车（AGV）路径规划的改进蚁群算法，旨在解决传统算法在大规模和复杂环境中全局搜索效率差、收敛速度慢以及路径转弯次数过多和不够平滑的问题。张中伟等人提出了一种基于动态优先级策略的多AGV无冲突路径规划方法，用于柔性制造车间的高效平稳生产。张天瑞等人探讨了针对基本蚁群算法在机器人路径规划过程中存在的路径转弯角度大、易陷入局部极小值和收敛速度慢等问题所进行的改进策略。李玉清等人设计了一种针对自动导引车（AGV）路径规划的改进动态窗口法（DWA）算法，该算法克服了原始DWA存在的振荡现象，并融合了人工势场法（APF）以提升路径规划的安全性和效率。'),
    bodyP('综合来看，国内外在智能仓储移动机器人路径规划算法方面已经形成了较为系统的研究基础，研究脉络主要经历了从传统启发式搜索到融合运动学约束的规划方法，再到结合机器学习与多机协同的智能化发展过程，后续研究重点将继续聚焦高效规划、动态避障与复杂场景下的协同决策。'),
    h2Text('1.4 研究方法与手段'),
    bodyP('本文研究对象为一款具备举升功能的自主搬运机器人，集载货、升降与运输于一体。底盘采用差速驱动方式，由两侧独立驱动轮和若干万向轮组成，通过左右轮速度差实现行驶和转向；升降机构选用剪叉式结构；控制策略采用PID控制器。总体方案已在第二章详细论证。'),
    bodyP('本文的主要工作包括：'),
    bodyP('1. 总体方案设计：确定差速底盘、驱动电机、升降机构、控制器和路径规划方案；', { noIndent: true }),
    bodyP('2. 机械结构设计：完成总体结构布局设计，并对剪叉式升降机构进行结构设计、运动学建模、受力分析及关键部件强度校核；', { noIndent: true }),
    bodyP('3. 电气系统设计：完成主控制器、电机、传感器选型及电路原理图设计；', { noIndent: true }),
    bodyP('4. 运动学建模、路径规划与仿真：建立差速运动学模型，利用MATLAB进行典型轨迹仿真，并基于Hybrid A*算法完成路径规划与红外循迹仿真验证；', { noIndent: true }),
    bodyP('5. 运动控制研究：设计双环PID控制器并通过仿真验证控制性能；', { noIndent: true }),
    bodyP('6. 结论与展望：总结成果，指出不足并提出改进方向。', { noIndent: true }),
    h2Text('1.5 小结'),
    bodyP('本章阐述了研究的背景和意义，分析了国内外智能仓储移动机器人和路径规划算法的研究现状，明确了本文的研究内容、研究方法和技术路线。在充分调研的基础上，为举升式自主搬运机器人的设计与控制奠定了理论基础。'),
  ];
}

// ===== CHAPTER 2: 总体设计方案 (FULL) =====
function ch2() {
  return [
    new Paragraph({ children: [new PageBreak()] }),
    h1Text('第2章 智能仓储移动机器人总体设计方案'),
    h2Text('2.1 设计需求分析'),
    bodyP('智能仓储环境对搬运设备的运行效率、空间适应性和自动化程度提出了明确要求。在货架密集、通道狭窄的仓储场景中，搬运设备需具备自主行驶、货物装卸和障碍规避等基本能力，同时应兼顾部署成本、维护便利性和运行可靠性。本章从系统总体设计的角度出发，围绕驱动方式、驱动电机、升降机构、控制系统、运动控制算法和路径规划算法六个方面展开方案论证，为后续各章的设计与仿真提供整体框架。'),
    bodyP('本设计所面向的典型应用场景为中小型仓储环境中的物料搬运任务。此类场景具有以下特征：货架排列较为规整，通道宽度有限；搬运对象以轻型物料为主，单次搬运重量一般不超过50 kg；作业区域为平整室内地面，无较大坡度或颠簸；运行路径可在作业前预先规划，环境变动频率较低。基于上述场景特点，设计需在满足功能需求的前提下，尽可能降低系统复杂度和硬件成本，同时为后续的功能扩展预留接口。'),
    bodyP('综合以上分析，本文将设计目标归纳如下：（1）移动机器人能够自主沿规划路径行驶，完成从取货点到目标货架之间的物料搬运；（2）具备载物台升降功能，升降行程不小于0.4 m，以适应不同货架高度的搬运需求；（3）具备基本的障碍物检测与避障能力，保障运行安全；（4）外形尺寸紧凑，能够在狭窄通道中灵活通行；（5）系统结构简洁、控制可靠、成本可控，适合实际部署与维护。'),
    h2Text('2.2 驱动方案选择'),
    bodyP('驱动方式是移动机器人底盘设计的核心环节，直接决定车辆的运动性能、控制复杂度以及适用的工作场景。驱动方式的选择需综合考虑载荷能力、转向灵活性、控制精度、结构可靠性和制造成本等多方面因素。目前，移动机器人常用的驱动形式可归纳为三类：单轮驱动、差速驱动和全方位驱动。'),
    h3Text('2.2.1 单轮驱动'),
    bodyP('单轮驱动的特征在于由一个舵轮同时承担驱动与转向两项功能，从动轮对称布置在车体轴线两侧。该方案结构简洁，零部件数量少，可靠性较高，维护成本低。其局限性在于转弯半径偏大，灵活性不足，在空间狭窄或需要频繁转向的仓储通道中表现不够理想。此外，舵轮机构在转向过程中驱动轮与地面之间存在侧向滑移，长期运行会加速轮胎磨损。'),
    h3Text('2.2.2 差速驱动'),
    bodyP('差速驱动由两个独立驱动的驱动轮和若干从动万向轮组成，左右驱动轮对称分布在车体轴线两侧。其转向原理不依赖转向机构，而是通过调节左右驱动轮的速度差来实现：当两侧轮速相等时，车辆直线行驶；当两侧轮速不等时，车辆向低速侧偏转。这种驱动方式能够实现前进、后退和原地转向，转弯半径小、灵活性出色，特别适合仓储通道中的频繁转向和狭窄空间作业。差速驱动的不足在于对地面平整度有一定要求——在凹凸不平的地面上，从动万向轮可能出现悬空现象，影响行驶稳定性；此外，差速转向过程中驱动轮与地面之间存在一定的滑动摩擦，长期运行会加速轮胎磨损。'),
    h3Text('2.2.3 全方位驱动'),
    bodyP('全方位驱动追求平面内的全向运动能力，常见方案包括两种：一是前后各设置一个舵轮并搭配从动万向轮，通过控制舵轮的角度和转速实现全向移动；二是采用四个麦克纳姆轮，通过独立控制各轮转速和方向，借助速度矢量合成实现平移、斜行和原地旋转。全方位驱动的突出优势在于可在不改变车体姿态的前提下向任意方向移动，空间利用率极高。然而其实现代价显著：麦克纳姆轮结构复杂，制造精度要求高，辊子磨损较快；舵轮方案需要高精度伺服控制，对电机性能和控制系统实时性要求较高。两类方案的硬件成本、控制难度和后期维护费用均明显高于前两种驱动方式。'),
    h3Text('2.2.4 方案选择'),
    bodyP('三者的综合对比如下：单轮驱动结构简单但转弯半径大；差速驱动结构较低、转弯半径小（可原地转向）、控制难度中等、制造成本较低；全方位驱动结构高、控制难度高、成本高。结合本文设计目标进行权衡：仓储通道空间有限，要求车辆具备较小的转弯半径和良好的转向灵活性，单轮驱动在此方面存在明显不足；全方位驱动虽灵活性极佳，但其结构复杂、成本高昂，对于路径相对固定的仓储搬运场景而言，全向移动能力属于功能冗余，性价比不高。差速驱动在结构复杂度、转弯灵活性和制造成本之间取得了较好的平衡，因此本文最终选定差速驱动作为底盘驱动方案。'),
    h2Text('2.3 升降机构方案选择'),
    bodyP('本文设计的移动机器人需具备货物装卸能力，即在货架前完成载物台的升降操作，以适应不同高度的货架层。升降机构作为衔接底盘与载物平台的关键功能模块，其选型直接影响整机的承载能力、升降平稳性和空间利用率。'),
    bodyP('仓储搬运设备中常见的升降机构主要包括三种类型：剪叉式、桅柱式和套筒式。剪叉式升降机构由多组交叉臂杆组成，通过液压缸或电动推杆驱动臂杆的张开与收拢来实现平台的升降运动。其突出优点是结构紧凑、传动平稳，在收拢状态下占用高度小，展开后能获得较大的升降行程，承载能力与自身重量的比值较高。桅柱式升降机构由竖直导轨和滑动平台构成，通过链条或丝杠驱动平台沿导轨上下运动，承载刚性好、定位精度高，但整体高度较大，对仓储天花板净空有一定要求。套筒式升降机构采用多级套叠结构，类似液压缸的逐级伸出原理，收缩后体积小，适合极低净空场合，但行程受限，且多级导向精度随着级数增加而降低。'),
    bodyP('本文设计的小车载重不超过50 kg，属于轻型载荷范畴，升降行程要求为0.4 m。在这一工况下，桅柱式方案的高刚度优势无法充分发挥，而其较大的纵向尺寸反而会增大整车高度，降低在低层货架区域的通过性；套筒式方案在多级伸缩过程中存在导向间隙累积问题，升降平稳性不及前两者。剪叉式升降机构以紧凑的结构实现了较大的行程/收缩比，传动平稳、无明显的纵向尺寸冗余，且制造工艺成熟、成本可控，与本文所设计小型搬运车的轻载、紧凑、平稳三项核心需求高度吻合。因此，本文选用剪叉式结构作为载物台的升降方案。'),
    h2Text('2.4 控制系统方案选择'),
    bodyP('控制系统是移动机器人的决策与执行中枢，负责传感器数据采集、控制算法运算、驱动信号输出以及各子系统的协调管理。控制系统方案的选择需在计算能力、实时性、功耗、接口资源、开发难度和硬件成本之间做出合理权衡。'),
    bodyP('工业控制领域常用的控制器方案主要有四类。PLC以高可靠性和强抗干扰能力著称，但体积大、成本高，算法灵活性有限。工控机计算能力强、操作系统完善，但功耗高、启动慢，适合作为固定调度主机而非移动平台嵌入式控制器。DSP专为高速信号处理设计，但在通用外设接口和扩展能力方面不及单片机，且成本与功耗较高。单片机（MCU）以ARM Cortex-M系列为代表，将处理器内核、存储器、定时器和通信接口集成于单一芯片，体积小、功耗低、实时性强，丰富的外设接口可直接连接传感器和编码器等外围器件，开发工具链成熟、成本低廉。'),
    bodyP('本文所设计搬运车的控制任务主要包括传感器数据采集、PID运动控制律执行、轮速解算和PWM驱动信号生成，计算负载适中而实时性要求较高，属于典型的嵌入式控制场景。因此，本文选择以ARM Cortex-M系列单片机为核心构建主控制器，兼顾性能、功耗与成本。'),
    h2Text('2.5 驱动电机方案选择'),
    bodyP('驱动电机是移动机器人动力系统的核心执行部件，其类型直接决定调速性能、控制精度和运行可靠性。常用的驱动电机主要有四类。直流有刷电机结构简单、成本低，但电刷存在机械磨损，换向火花产生电磁干扰，不利于精密控制。直流无刷电机效率高、寿命长，但低转速时齿槽效应导致转矩脉动明显，难以满足低速平稳性要求。步进电机可通过脉冲信号实现开环位置控制，但高速转矩下降显著，存在丢步和共振风险，不适合长距离连续运行。交流伺服电机采用闭环控制，编码器实时反馈转速与位置，调速范围宽、低速平稳性好、过载能力强，能够精确跟踪轮速指令，为轨迹跟踪和航位推算提供可靠的执行保证。'),
    bodyP('本设计采用差速驱动方式，对轮速控制精度和低速平稳性有较高要求。综合以上对比，本文选择交流伺服电机作为驱动电机，具体型号的功率和转矩参数将在电气系统设计章节中进行定量计算与校核。'),
    h2Text('2.6 运动控制算法选择'),
    bodyP('移动机器人的运动控制本质上是一个闭环跟踪问题：控制器根据期望位姿或期望速度与实际状态之间的偏差，实时计算控制量并驱动电机，使机器人沿预定轨迹稳定运行。控制算法的选择直接关系到系统的跟踪精度、响应速度和抗干扰能力。'),
    bodyP('PID（比例—积分—微分）控制是工业控制领域应用最为广泛、技术最为成熟的经典算法，至今已有近百年的工程应用历史。其基本思想是将期望值与实际值之间的偏差按比例、积分和微分三种运算进行加权组合，生成控制输出量。比例环节对当前偏差进行即时响应，提供控制作用的主体部分；积分环节对历史偏差进行累积，用于消除长时间运行中可能出现的稳态误差；微分环节对偏差的变化趋势进行预估，起到抑制超调和减小振荡的作用。三个环节的作用相互独立、物理意义明确，工程人员可通过调节三个增益系数来匹配不同被控对象的动态特性。'),
    bodyP('在移动机器人运动控制领域，除经典PID之外，常用的控制方法还包括模糊控制和模型预测控制（MPC）。模糊控制将专家经验转化为模糊规则库，通过模糊推理实现非线性映射，对系统精确数学模型的依赖程度较低，适合难以精确建模的复杂系统，但其规则库的设计高度依赖经验，调试过程主观性强，控制精度不易保证。MPC基于系统模型对未来一段时间内的状态进行预测，通过在线求解有限时域优化问题获得最优控制序列，能够显式处理状态约束和输入约束，理论性能优异，但其计算量较大，对控制器运算能力要求较高，且需要相对准确的系统动力学模型，在低成本嵌入式平台上的实时实现具有一定挑战。'),
    bodyP('结合本文设计目标进行考量：本系统采用双轮差速驱动，被控对象为左右轮转速和车体姿态，运动模型相对简单、非线性程度不高，PID控制器完全具备处理此类控制问题的能力；系统主控制器为单片机，计算资源有限，PID的运算量极小（仅包含数次乘加运算），能够在毫秒级的控制周期内完成，与嵌入式平台的实时性要求高度匹配；PID参数整定方法成熟，无论是基于Ziegler-Nichols经验公式的工程整定，还是借助MATLAB的仿真辅助整定，均有成熟的实施路径。因此，本文选择PID控制作为运动控制的基础算法，并通过双环级联（外环位姿环与内环轮速环）的结构来兼顾轨迹跟踪与姿态调节的精度需求。'),
    h2Text('2.7 路径规划算法选择'),
    bodyP('路径规划是移动机器人导航系统的核心功能模块，其任务是在包含障碍物的环境中寻找一条从起点到终点的安全可行路径。路径规划算法的选择需同时考虑搜索效率、路径质量、运动学可行性以及与底层控制器的衔接便利性。'),
    bodyP('在仓储移动机器人领域，常用的全局路径规划算法包括Dijkstra算法、标准A*算法和Hybrid A*算法等。Dijkstra算法采用广度优先的搜索策略，能够保证找到全局最短路径，但其搜索过程不具备方向引导性，节点扩展量大，在较大规模地图上运行效率较低。标准A*算法在Dijkstra的基础上引入了启发式函数，使搜索过程有方向性地朝向目标点推进，显著提高了搜索效率，是目前应用最广泛的栅格路径规划算法。然而，标准A*算法在离散栅格上仅允许8邻域（或4邻域）移动，生成的路径由栅格边或栅格对角线连接而成，存在锯齿状折线，不符合差速驱动移动机器人的运动学约束——实际机器人无法执行突变方向的路径。通常需要在A*规划之后增加路径平滑后处理步骤，但这种后处理方式不能保证平滑后的路径仍然满足无碰撞要求。'),
    bodyP('Hybrid A*算法是专门针对非完整约束移动机器人（如差速驱动车辆）设计的路径规划方法。其在标准A*的栅格搜索框架之上做了两个关键改进：第一，节点状态从二维位置(x,y)扩展为三维位姿(x,y,θ)，将航向信息纳入搜索空间；第二，节点的后继扩展不再局限于栅格邻域，而是采用符合差速运动学模型的连续曲率运动基元，每个基元对应特定的转向曲率和行驶方向。这两项改进使Hybrid A*生成的路径天然满足机器人的最小转弯半径约束，避免了标准A*规划结果中可能出现的不可执行急转弯，路径可直接交付底层控制器跟踪执行，无需额外的后处理。此外，Hybrid A*在代价函数中可引入转向惩罚和倒车惩罚，引导算法优先选择平滑、前向的路径。'),
    bodyP('结合本文的应用场景，仓储环境中的货架布局相对固定，地图可预先构建，路径规划可在离线状态下完成，对算法的实时运行效率要求不如在线规划严苛。在此前提下，路径质量（即路径的可执行性和平滑性）成为比搜索速度更优先的考量因素。Hybrid A*虽然搜索效率略低于标准A*，但其生成的路径满足差速底盘的运动学约束，无需后处理即可直接由底层PID控制器执行，大幅降低了导航系统各层之间的衔接复杂度。此外，当仓储货架布局发生变化时，Hybrid A*可基于更新后的地图重新规划路径，无需人工重新铺设地面引导标识，提升了系统的灵活性和可维护性。因此，本文选择Hybrid A*作为全局路径规划算法。'),
    h2Text('2.8 总体方案概述'),
    bodyP('综合以上各节的分析与论证，本文所设计的智能仓储移动机器人总体方案如下：'),
    bodyP('（1）驱动方案：双轮差速驱动底盘，转弯半径小、灵活性好；', { noIndent: true }),
    bodyP('（2）驱动电机：交流伺服电机，闭环控制，低速平稳、调速范围宽；', { noIndent: true }),
    bodyP('（3）升降机构：剪叉式升降结构，传动平稳、结构紧凑，行程满足0.4 m指标；', { noIndent: true }),
    bodyP('（4）控制系统：ARM Cortex-M系列单片机，兼顾性能、实时性与成本；', { noIndent: true }),
    bodyP('（5）运动控制：双环PID级联控制，外环位姿环与内环轮速环，适合嵌入式平台；', { noIndent: true }),
    bodyP('（6）路径规划：Hybrid A*算法，路径天然满足差速运动学约束，无需后处理。', { noIndent: true }),
    bodyP('上述方案构成了层次清晰的总体设计框架：顶层由Hybrid A*负责路径决策，中间层由PID控制器负责运动跟踪，底层由伺服电机驱动的差速底盘和剪叉式升降机构负责物理执行，单片机作为控制中枢贯穿各层。各方案的选择均以场景需求为出发点，在功能、技术成熟度、实现可行性和成本之间进行了综合权衡，为后续各章的详细设计提供指导。'),
    h2Text('2.9 小结'),
    bodyP('本章从智能仓储的实际需求出发，完成了移动机器人总体方案的设计与论证。在驱动方式、驱动电机、升降机构、控制系统、运动控制算法和路径规划算法六个方面，通过多方案对比分析，分别选定了差速驱动、交流伺服电机、剪叉式升降机构、单片机控制器、双环PID控制和Hybrid A*算法。各方案的选择均建立在场景需求和方法对比的基础上，兼顾了功能完整性、技术可行性和工程经济性，为后续各章的设计与仿真提供了明确的指导框架。'),
  ];
}

// Export for use in main file
module.exports = { coverPage, declarationPage, abstractCN, abstractEN, ch1, ch2,
  h1Text, h2Text, h3Text, bodyP, bodyMixed, centerP, emptyP,
  FONT_SONG, FONT_HEI, FONT_FANGSONG, FONT_TNR,
  SIZE_SANHAO, SIZE_SIHAO, SIZE_XIAOSI, SIZE_WUHAO, SIZE_XIAOWU,
  LINE_SPACING, AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
  PageNumber, PageBreak, TableOfContents, Paragraph, TextRun, Header, Footer,
  Document, Packer };
