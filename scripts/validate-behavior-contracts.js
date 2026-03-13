const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const commandPath = path.join(root, 'commands/ow/plan.md');
const commandText = fs.readFileSync(commandPath, 'utf8');

function getSection(text, heading, nextHeadingCandidates = []) {
  const start = text.indexOf(`${heading}\n`);
  if (start === -1) {
    return '';
  }

  const bodyStart = start + heading.length + 1;
  const nextIndices = nextHeadingCandidates
    .map((candidate) => text.indexOf(`\n${candidate}\n`, bodyStart))
    .filter((index) => index !== -1);

  const end = nextIndices.length > 0 ? Math.min(...nextIndices) : text.length;
  return text.slice(bodyStart, end).trim();
}

const sectionOrder = [
  'External Tools Detection:',
  'Intent Gate:',
  '분기 실행 규칙:',
  '상태/출력 규칙:',
];

function getOrderedSection(text, heading) {
  const currentIndex = sectionOrder.indexOf(heading);
  const nextCandidates = currentIndex === -1 ? [] : sectionOrder.slice(currentIndex + 1);
  return getSection(text, heading, nextCandidates);
}

const intentGate = getOrderedSection(commandText, 'Intent Gate:');
const branchRules = getOrderedSection(commandText, '분기 실행 규칙:');
const statusRules = getOrderedSection(commandText, '상태/출력 규칙:');
const externalTools = getOrderedSection(commandText, 'External Tools Detection:');

const checks = [
  {
    description: 'canonical ow:plan contract defines omitted --intent default as passive',
    ok: intentGate.includes('`--intent`가 없으면 기본값으로 `passive`를 사용합니다.'),
  },
  {
    description: 'canonical ow:plan contract routes explicit active without prompting',
    ok: intentGate.includes('`--intent=active`면 질문 없이 active 분기로 진행합니다.'),
  },
  {
    description: 'canonical ow:plan contract routes explicit passive without prompting',
    ok: intentGate.includes('`--intent=passive`면 질문 없이 passive 분기로 진행합니다.'),
  },
  {
    description: 'canonical ow:plan contract separates external-tool ask behavior',
    ok: externalTools.includes('`ask`: AskUserQuestion으로 사용 여부 확인'),
  },
  {
    description: 'canonical ow:plan contract documents fast mode skipping external tools detection',
    ok: externalTools.includes('**Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.'),
  },
  {
    description: 'canonical ow:plan contract documents active and passive branch execution',
    ok: branchRules.includes('- `active` 분기:') && branchRules.includes('- `passive` 분기:'),
  },
  {
    description: 'canonical ow:plan contract preserves PASS and SKIP semantics for passive flow',
    ok: statusRules.includes('- `PASS`: 분기 실행이 정상 완료됨') && statusRules.includes('- `SKIP`: passive 후보가 0건인 정상 empty case'),
  },
];

let failed = false;

console.log('Validating canonical behavior contract...\n');

for (const check of checks) {
  if (!check.ok) {
    failed = true;
    console.error(`FAIL: ${check.description}`);
    continue;
  }

  console.log(`PASS: ${check.description}`);
}

if (failed) {
  process.exit(1);
}

console.log('\nCanonical behavior contract validation passed!');
