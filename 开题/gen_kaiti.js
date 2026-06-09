const fs = require('fs');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        AlignmentType, BorderStyle, WidthType, VerticalAlign } = require('docx');

const border = { style: BorderStyle.SINGLE, size: 4, space: 0, color: "000000" };
const borders = { top: border, bottom: border, left: border, right: border };
const cellMargins = { top: 40, bottom: 40, left: 80, right: 80 };

function textCell(text, opts = {}) {
  const { bold, center, gridSpan, width } = opts;
  const tcPr = { borders, margins: cellMargins, verticalAlign: VerticalAlign.CENTER };
  if (gridSpan) tcPr.columnSpan = gridSpan;
  if (width) tcPr.width = { size: width, type: WidthType.DXA };
  return new TableCell({
    ...tcPr,
    children: [new Paragraph({
      alignment: center ? AlignmentType.CENTER : AlignmentType.LEFT,
      spacing: { line: 360, lineRule: "auto" },
      children: [new TextRun({ text, font: "宋体", size: 24, bold: bold || false })],
    })],
  });
}

function multiParaCell(paragraphs, opts = {}) {
  const { gridSpan, width } = opts;
  const tcPr = { borders, margins: cellMargins, verticalAlign: VerticalAlign.TOP };
  if (gridSpan) tcPr.columnSpan = gridSpan;
  if (width) tcPr.width = { size: width, type: WidthType.DXA };
  return new TableCell({ ...tcPr, children: paragraphs });
}

function bodyPara(text) {
  return new Paragraph({
    spacing: { before: 60, line: 360, lineRule: "auto" },
    indent: { firstLineChars: 200, firstLine: 480 },
    children: [new TextRun({ text, font: "宋体", size: 24 })],
  });
}

function bodyParaRefs(segments) {
  return new Paragraph({
    spacing: { before: 60, line: 360, lineRule: "auto" },
    indent: { firstLineChars: 200, firstLine: 480 },
    children: segments.map(seg => {
      if (seg.sup) return new TextRun({ text: seg.text, font: "宋体", size: 18, superScript: true });
      return new TextRun({ text: seg.text, font: "宋体", size: 24 });
    }),
  });
}

function sectionHeading(text, size) {
  return new Paragraph({
    spacing: { before: 120, line: 360, lineRule: "auto" },
    children: [new TextRun({ text, font: "黑体", size: size || 30 })],
  });
}

function subHeading(text) {
  return new Paragraph({
    spacing: { before: 120, line: 360, lineRule: "auto" },
    indent: { firstLineChars: 200, firstLine: 600 },
    children: [new TextRun({ text, font: "黑体", size: 30 })],
  });
}

function refEntry(text) {
  return new Paragraph({
    spacing: { before: 0, line: 300, lineRule: "auto" },
    indent: { left: 420, hanging: 420 },
    children: [new TextRun({ text, font: "宋体", size: 21 })],
  });
}

// ===== Build body =====
const B = [];

B.push(sectionHeading("一、选题依据"));
B.push(sectionHeading("1.1 选题的目的、意义"));

B.push(bodyParaRefs([
  { text: "根据商务部发布的《中国新电商发展报告（2025）》" },
  { text: "[1]", sup: true },
  { text: "，2024年我国网络零售额达到15.5万亿元，同比增长7.2%，对社会消费品零售总额贡献约1.7个百分点，我国已连续12年保持全球最大网络零售市场的地位。电商规模的持续扩大使仓储与物流环节逐步演变为整体效率提升的主要瓶颈。依靠人工完成的仓储作业在效率和响应速度上已无法匹配不断攀升的订单量，这一现实促使学术界和产业界将目光投向智能仓储中的自主移动机器人。" },
]));

B.push(bodyParaRefs([
  { text: "在智能仓储领域，自主移动机器人根据导航方式和功能定位可划分为若干类型。自动导引车（AGV）依靠磁条、二维码等预设标识导航，适用于路径固定的场景；自主移动机器人（AMR）引入激光雷达、视觉传感器和SLAM技术，具备自主感知与动态决策能力，适合复杂多变的仓储环境。各类机器人的核心目标高度一致——在仓储场景中实现高效、安全、自主的物料搬运。" },
]));

B.push(bodyParaRefs([
  { text: "自动导引车（AGV）集自主导航、路径规划和货物搬运于一体，可在结构化仓储场景中独立完成物流作业。市场数据表明，2019年至2024年中国AGV行业规模从48.27亿元攀升至95.49亿元；AMR市场同样增长迅猛，2023年规模已突破60亿元，年增长率超过30%，反映出行业从“固定路径导引”向“自主感知决策”升级的清晰趋势。" },
]));

B.push(bodyParaRefs([
  { text: "然而，随着电商物流向更多品类、更高时效的方向发展，仓储场景对自主移动机器人提出了更高要求：作业环境日趋动态化，柔性订单结构使搬运路径不再固定，机器人需在人机混行环境中稳定运行；系统需从固定路径导引升级为自主感知与实时决策" },
  { text: "[2]", sup: true },
  { text: "；在环境感知、路径规划和任务调度等方面，需兼顾全局最优性与局部实时性。" },
]));

B.push(bodyParaRefs([
  { text: "在上述挑战驱动下，自主移动机器人的研究已延伸至环境感知与运动控制深度融合、多机协同调度等深层次问题。但目前针对中小型仓储场景中兼具举升功能与自主导航能力的紧凑型机器人的系统性工程研究仍不充分。本文以一款举升式自主搬运机器人为研究对象，围绕总体方案设计、机械与电气系统、运动学建模与运动控制等关键环节展开研究，旨在为该类机器人的设计与开发提供理论依据和技术参考。" },
]));

B.push(sectionHeading("1.2 研究现状"));
B.push(subHeading("1.2.1 国外研究现状"));

B.push(bodyParaRefs([
  { text: "国外在自主移动机器人领域的研发和商业化起步较早。亚马逊2012年收购Kiva Systems后批量部署Kiva机器人，以“货架到人”模式将拣选效率提高2至3倍" },
  { text: "[2]", sup: true },
  { text: "，其通过中央调度协调多机器人协同的理念深刻影响了行业走向。近年来AMR成为新趋势，Fetch Robotics、Locus Robotics等公司推出的AMR利用激光雷达和SLAM实现自主定位，无需改造仓库地面即可部署" },
  { text: "[3]", sup: true },
  { text: "。欧洲方面，Magazino的TORU实现了从搬运货架到视觉抓取单品的技术跨越，KUKA和ABB等将机械臂与移动底盘结合推出复合型移动操作机器人" },
  { text: "[4]", sup: true },
  { text: "。波士顿动力的Atlas和Spot则在复杂地形适应方面展现出高水平。" },
]));

B.push(bodyParaRefs([
  { text: "在算法维度，Hybrid A*因能生成满足运动约束的路径而被广泛采纳" },
  { text: "[5]", sup: true },
  { text: "，MAPF为多机协同提供了理论支撑。近年研究焦点转向深度强化学习（DQN、PPO）的落地应用，以及数字孪生仿真、云-边-端协同调度等方向。自主移动机器人的应用也从仓储拓展到智能城市、医疗和农业等领域" },
  { text: "[6]", sup: true },
  { text: "。" },
]));

B.push(subHeading("1.2.2 国内研究现状"));

B.push(bodyParaRefs([
  { text: "国内对自主移动机器人的研究可追溯至20世纪70年代末，早期以引进仿制为主。进入21世纪后，制造业升级与电商增长使仓储机器人成为关注焦点，2012年亚马逊收购Kiva更推动了国内企业的布局。" },
]));

B.push(bodyParaRefs([
  { text: "在产业应用层面，京东物流自2014年起建设亚洲一号智能仓群，自主研发了“地狼”AGV和“天狼”穿梭系统，并与极智嘉（Geek+）合作引入AMR方案" },
  { text: "[4]", sup: true },
  { text: "。菜鸟网络在无锡、惠阳等地部署了数百台AGV与AMR，其”小蛮驴”配送机器人将应用从仓储延伸至末端配送。海康威视、旷视科技、快仓等企业在仓储机器人领域形成成熟产品线，国产化产业链逐步成形" },
  { text: "[3]", sup: true },
  { text: "。" },
]));

B.push(bodyParaRefs([
  { text: "技术层面，导航技术从磁条/二维码引导迭代至激光SLAM和视觉SLAM方案" },
  { text: "[7]", sup: true },
  { text: "；多机协同方面提出了多种分布式和集中式调度策略；算法方面围绕改进A*、遗传算法、蚁群算法等积累了理论成果。总体而言，国内在核心算法成熟度和大规模部署经验上与国际先进水平仍有差距，但差距正在收窄，应用前景广阔。" },
]));

B.push(subHeading("1.2.3 路径规划算法研究现状"));

B.push(bodyParaRefs([
  { text: "在路径规划算法方面，M Rybczak等人梳理了移动机器人控制中机器学习算法面临的挑战" },
  { text: "[8]", sup: true },
  { text: "；MFR Lee等人将DQN和DDQN引入移动机器人导航与避撞学习" },
  { text: "[9]", sup: true },
  { text: "；T Guo等人提出了基于改进A*和DWA融合的AGV路径规划算法" },
  { text: "[10]", sup: true },
  { text: "。国内方面，黄晓宇等人设计了MPC与微分先行PID协同的双闭环控制策略" },
  { text: "[11]", sup: true },
  { text: "；白宇鑫等人提出了改进的哈里斯鹰优化算法" },
  { text: "[12]", sup: true },
  { text: "；张瑞等人提出了RRT*与DWA融合的路径规划方法" },
  { text: "[13]", sup: true },
  { text: "；肖金壮等人设计了面向室内AGV的改进蚁群算法" },
  { text: "[14]", sup: true },
  { text: "。综合来看，研究脉络从传统启发式搜索到融合运动学约束的规划方法，再到结合机器学习与多机协同的智能化发展。" },
]));

B.push(sectionHeading("1.3 研究方法与手段"));
B.push(bodyParaRefs([
  { text: "本文研究对象为一款具备举升功能的自主搬运机器人，集载货、升降与运输于一体。底盘采用差速驱动方式，由两侧独立驱动轮和若干万向轮组成；升降机构选用剪叉式结构；控制策略采用PID控制器。主要工作包括：（1）总体方案设计；（2）机械结构设计与强度校核；（3）电气系统设计；（4）运动学建模、路径规划与仿真；（5）运动控制研究；（6）结论与展望。" },
]));

B.push(sectionHeading("二、研究内容"));
B.push(bodyPara("本文的研究内容主要包括以下几个方面："));
B.push(bodyPara("（1）总体方案设计：通过多方案对比分析，确定差速底盘、驱动电机、升降机构、控制器和路径规划方案。"));
B.push(bodyPara("（2）机械结构设计：完成总体结构布局设计，并对剪叉式升降机构进行结构设计、运动学建模、受力分析及关键部件强度校核。"));
B.push(bodyPara("（3）电气系统设计：完成主控制器、电机、传感器选型及电路原理图设计。"));
B.push(bodyPara("（4）运动学建模、路径规划与仿真：建立差速运动学模型，利用MATLAB进行典型轨迹仿真，并基于Hybrid A*算法完成路径规划与红外循迹仿真验证。"));
B.push(bodyPara("（5）运动控制研究：设计双环PID控制器并通过仿真验证控制性能。"));

B.push(sectionHeading("三、参考文献"));

const refs = [
  "[1] 国家邮政局. 2024年邮政行业发展统计公报[EB/OL]. (2025-05-22)[2026-04-18]. https://www.spb.gov.cn.",
  "[2] 李成进, 王芳. 智能移动机器人导航控制技术综述[J]. 导航定位与授时, 2016, 3(5): 22-26.",
  "[3] 田璐. AI技术驱动下的电商供应链效率提升研究[J]. E-Commerce Letters, 2026, 15: 637.",
  "[4] 谢轲晗, 王珍珍. 数字赋能制造企业与物流企业融合创新发展的模式及路径研究[J]. Advances in Social Sciences, 2025, 14: 143.",
  "[5] Nemec D, Gregor M, Bubenikova E, et al. Improving the Hybrid A* method for a non-holonomic wheeled robot[J]. International Journal of Advanced Robotic Systems, 2019, 16(1): 1729881419826857.",
  "[6] Chand R, Sharma B, Kumar S A. Systematic review of mobile robots applications in smart cities[J]. Journal of Industrial Information Integration, 2025, 45: 100821.",
  "[7] 沈博闻, 于宁波, 刘景泰. 仓储物流机器人集群的智能调度和路径规划[J]. 智能系统学报, 2014.",
  "[8] Rybczak M, Popowniak N, Lazarowska A. A survey of machine learning approaches for mobile robot control[J]. Robotics, 2024, 13(1): 12.",
  "[9] Lee M F R, Yusuf S H. Mobile robot navigation using deep reinforcement learning[J]. Processes, 2022, 10(12): 2748.",
  "[10] Guo T, Sun Y, Liu Y, et al. An automated guided vehicle path planning algorithm based on improved A* and DWA fusion[J]. Applied Sciences, 2023, 13(18): 10326.",
  "[11] 黄晓宇, 孙勇智, 李津蓉, 等. 基于MPC的麦克纳姆轮移动平台轨迹跟踪控制[J]. 机械传动, 2023, 47(11): 22-29.",
  "[12] 白宇鑫, 陈振亚, 石瑞涛, 等. 基于改进哈里斯鹰算法的机器人路径规划研究[J]. 系统仿真学报, 2025, 37(3): 742.",
  "[13] 张瑞, 周丽, 刘正洋. 融合RRT*与DWA算法的移动机器人动态路径规划[J]. 系统仿真学报, 2024, 36(4): 957.",
  "[14] 肖金壮, 余雪乐, 周刚, 等. 一种面向室内AGV路径规划的改进蚁群算法[J]. 仪器仪表学报, 2022, 43(3): 277-285.",
  "[15] 赖荣燊, 窦磊, 巫志勇, 等. 融合改进A*算法和动态窗口法的移动机器人路径规划[J]. 系统仿真学报, 2024, 36(8): 1884.",
  "[16] 曹梦龙, 赵文彬, 陈志强. Robot path planning by fusing particle swarm algorithm and improved grey wolf algorithm[J]. Journal of System Simulation, 2023, 35(8): 1768-1775.",
  "[17] 张中伟, 张博晖, 代争争, 等. 基于动态优先级策略的多AGV无冲突路径规划[J]. 计算机应用研究, 2021, 38(7).",
  "[18] 张天瑞, 吴宝库, 周福强. 面向机器人全局路径规划的改进蚁群算法研究[J]. 计算机工程与应用, 2022, 58(1).",
  "[19] 李玉清, 梁忠楠, 赵衍昭, 等. 一种动态窗口法和人工势场法融合的AGV路径规划算法[J]. 科学技术与工程, 2025, 25(14).",
  "[20] Dai Y, Yu J, Zhang C, et al. A novel whale optimization algorithm of path planning for mobile robots[J]. Applied Intelligence, 2023, 53(9): 10843-10857.",
  "[21] Das S, Mishra S K. A machine learning approach for collision avoidance of mobile robot[J]. Computers and Electrical Engineering, 2022, 103: 108376.",
  "[22] Tao B, Kim J. Mobile robot path planning based on bi-population PSO with random perturbation[J]. Journal of King Saud University-Computer and Information Sciences, 2024, 36(2): 101974.",
  "[23] Fransen K, Van Eekelen J. Efficient path planning for AGVs using A* incorporating turning costs[J]. International Journal of Production Research, 2023, 61(3): 707-725.",
  "[24] Heinemann T, Riedel O, Lechler A. Generating smooth trajectories in local path planning for AGVs[J]. Procedia Manufacturing, 2019, 39: 98-105.",
  "[25] 刘梓博, 陈羽立, 徐梓峰, 等. 基于双变量限幅PID算法的四轮差速转向AGV导航控制系统[J]. Transactions of the Chinese Society of Agricultural Engineering, 2025, 41(5).",
];
refs.forEach(r => B.push(refEntry(r)));

// ===== Build document =====
const doc = new Document({
  styles: { default: { document: { run: { font: "宋体", size: 24 } } } },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1440, right: 1800, bottom: 1440, left: 1800, header: 851, footer: 992 },
      },
    },
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER, spacing: { after: 100 },
        children: [new TextRun({ text: "齐鲁工业大学本科毕业论文（设计）开题报告", font: "黑体", size: 32, bold: true })],
      }),
      new Paragraph({ spacing: { after: 0 } }),
      new Table({
        width: { size: 9855, type: WidthType.DXA },
        columnWidths: [1471, 2214, 995, 1955, 1217, 2003],
        rows: [
          new TableRow({ height: { value: 614 }, children: [
            textCell("课题名称", { center: true }),
            textCell("智能仓储自主移动机器人结构设计与控制", { center: true, gridSpan: 5 }),
          ]}),
          new TableRow({ height: { value: 614 }, children: [
            textCell("课题类型", { center: true }),
            textCell("工程设计", { center: true, gridSpan: 2 }),
            textCell("指导教师", { center: true }),
            textCell("刘鹏博", { center: true, gridSpan: 2 }),
          ]}),
          new TableRow({ height: { value: 614 }, children: [
            textCell("学生姓名", { center: true }),
            textCell("王子煜", { center: true }),
            textCell("学号", { center: true }),
            textCell("202201230042", { center: true }),
            textCell("专业班级", { center: true }),
            textCell("机器人si22-2", { center: true }),
          ]}),
          new TableRow({ height: { value: 14000 }, children: [
            multiParaCell(B, { gridSpan: 6, width: 9855 }),
          ]}),
        ],
      }),
      new Paragraph({ children: [] }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("D:/bylw/开题/开题报告_重做.docx", buffer);
  console.log("Done!");
});
