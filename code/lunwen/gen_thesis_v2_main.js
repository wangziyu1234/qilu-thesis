const fs = require('fs');
const { coverPage, declarationPage, abstractCN, abstractEN, ch1, ch2,
  FONT_SONG, FONT_HEI, FONT_TNR, SIZE_SANHAO, SIZE_XIAOSI, SIZE_WUHAO, SIZE_XIAOWU,
  LINE_SPACING, AlignmentType, HeadingLevel,
  PageNumber, PageBreak, TableOfContents, Paragraph, TextRun, Header, Footer,
  Document, Packer } = require('./gen_thesis_v2.js');
const { ch3, ch4, ch5, ch6, ch7, refs, ack, appendix } = require('./gen_thesis_v2_ch3to7.js');

// ===== ASSEMBLE DOCUMENT =====
const doc = new Document({
  styles: {
    default: {
      document: { run: { font: FONT_TNR, size: SIZE_XIAOSI } },
    },
    paragraphStyles: [
      {
        id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: SIZE_SANHAO, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 240, after: 240 }, alignment: AlignmentType.CENTER, outlineLevel: 0 },
      },
      {
        id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 28, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 180, after: 120 }, outlineLevel: 1 },
      },
      {
        id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 28, bold: true, font: FONT_HEI },
        paragraph: { spacing: { before: 120, after: 120 }, outlineLevel: 2 },
      },
    ],
  },
  sections: [
    // Section 1: Cover + Declaration (no header/footer)
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1418, right: 1418, bottom: 1418, left: 1418, header: 851, footer: 1004 },
        },
      },
      children: [
        ...coverPage(),
        ...declarationPage(),
      ],
    },
    // Section 2: TOC + Abstract + Body + References + Acknowledgements + Appendix
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1418, right: 1418, bottom: 1418, left: 1418, header: 851, footer: 1004 },
        },
      },
      headers: {
        default: new Header({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ text: '齐鲁工业大学本科毕业论文（设计）', font: FONT_SONG, size: 18 })],
          })],
        }),
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT_TNR, size: SIZE_WUHAO })],
          })],
        }),
      },
      children: [
        // TOC page
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 240, after: 360, line: LINE_SPACING },
          children: [new TextRun({ text: '目  录', font: FONT_HEI, size: SIZE_SANHAO, bold: true })],
        }),
        new TableOfContents('目录', { hyperlink: true, headingStyleRange: '1-3' }),
        new Paragraph({ children: [new PageBreak()] }),
        // Abstract CN + EN
        ...abstractCN(),
        ...abstractEN(),
        // All chapters
        ...ch1(),
        ...ch2(),
        ...ch3(),
        ...ch4(),
        ...ch5(),
        ...ch6(),
        ...ch7(),
        // References
        ...refs(),
        // Acknowledgements
        ...ack(),
        // Appendix
        ...appendix(),
      ],
    },
  ],
});

// Generate
const outputPath = 'd:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/thesis_template/齐鲁工业大学本科毕业论文_王子煜.docx';
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outputPath, buffer);
  console.log('SUCCESS: Document generated at ' + outputPath);
  console.log('File size: ' + (buffer.length / 1024).toFixed(1) + ' KB');
}).catch(err => {
  console.error('ERROR:', err.message);
  process.exit(1);
});
