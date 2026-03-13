#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const commandPath = path.join(root, 'commands/ow/plan.md');
const fixturePath = path.join(root, 'tests/migration/fixtures/plan-passive-default.json');

const commandText = fs.readFileSync(commandPath, 'utf8');
const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

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

const sections = {
  externalTools: getOrderedSection(commandText, 'External Tools Detection:'),
  intentGate: getOrderedSection(commandText, 'Intent Gate:'),
  branchRules: getOrderedSection(commandText, '분기 실행 규칙:'),
  statusRules: getOrderedSection(commandText, '상태/출력 규칙:'),
};

const errors = [];

function evaluateScenario(scenario) {
  const { name, input, expected } = scenario;

  const result = {
    branch: 'unknown',
    asksIntentSelection: true,
    asksExternalTools: false,
    statusSupported: false,
  };

  if (input.intent === null && sections.intentGate.includes('`--intent`가 없으면 기본값으로 `passive`를 사용합니다.')) {
    result.branch = 'passive';
    result.asksIntentSelection = false;
  }

  if (input.intent === 'passive' && sections.intentGate.includes('`--intent=passive`면 질문 없이 passive 분기로 진행합니다.')) {
    result.branch = 'passive';
    result.asksIntentSelection = false;
  }

  if (input.intent === 'active' && sections.intentGate.includes('`--intent=active`면 질문 없이 active 분기로 진행합니다.')) {
    result.branch = 'active';
    result.asksIntentSelection = false;
  }

  if (input.externalToolsAutoUse === 'ask' && !input.fast) {
    result.asksExternalTools = sections.externalTools.includes('`ask`: AskUserQuestion으로 사용 여부 확인');
  }

  if (input.fast) {
    result.asksExternalTools = !sections.externalTools.includes('**Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.') && result.asksExternalTools;
  }

  const activeBranchDocumented = sections.branchRules.includes('- `active` 분기:');
  const passiveBranchDocumented = sections.branchRules.includes('- `passive` 분기:');
  const passDocumented = sections.statusRules.includes('- `PASS`: 분기 실행이 정상 완료됨');
  const skipDocumented = sections.statusRules.includes('- `SKIP`: passive 후보가 0건인 정상 empty case');

  if (result.branch === 'active') {
    result.statusSupported = activeBranchDocumented && passDocumented;
  }

  if (result.branch === 'passive') {
    result.statusSupported = passiveBranchDocumented && passDocumented && skipDocumented;
  }

  if (result.branch !== expected.branch) {
    errors.push(`${name}: expected branch ${expected.branch}, got ${result.branch}`);
  }

  if (result.asksIntentSelection !== expected.asksIntentSelection) {
    errors.push(`${name}: expected asksIntentSelection=${expected.asksIntentSelection}, got ${result.asksIntentSelection}`);
  }

  if (result.asksExternalTools !== expected.asksExternalTools) {
    errors.push(`${name}: expected asksExternalTools=${expected.asksExternalTools}, got ${result.asksExternalTools}`);
  }

  if (!result.statusSupported) {
    errors.push(`${name}: expected documented status semantics for ${result.branch} branch`);
  }

  const scenarioFailed = errors.some((error) => error.startsWith(`${name}:`));
  if (!scenarioFailed) {
    console.log(`PASS: ${name}`);
  }
}

console.log('Running plan passive-default regression scenarios...\n');
for (const scenario of fixture.scenarios) {
  evaluateScenario(scenario);
}

if (errors.length > 0) {
  console.error('\nRegression test failures:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log('\nAll runtime regression scenarios passed!');
