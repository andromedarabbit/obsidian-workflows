#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

function readRelative(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

const docs = {
  commandPlan: {
    path: 'commands/ow-plan.md',
    text: readRelative('commands/ow-plan.md'),
  },
  skillPlan: {
    path: 'skills/plan/SKILL.md',
    text: readRelative('skills/plan/SKILL.md'),
  },
  commandWork: {
    path: 'commands/ow-work.md',
    text: readRelative('commands/ow-work.md'),
  },
  commandCompound: {
    path: 'commands/ow-compound.md',
    text: readRelative('commands/ow-compound.md'),
  },
  commandReview: {
    path: 'commands/ow-review.md',
    text: readRelative('commands/ow-review.md'),
  },
  skillWork: {
    path: 'skills/work/SKILL.md',
    text: readRelative('skills/work/SKILL.md'),
  },
  scanCommand: {
    path: 'commands/write-scan.md',
    text: readRelative('commands/write-scan.md'),
  },
};

const errors = [];

function check(description, ok, pathForError = '') {
  if (ok) {
    console.log(`PASS: ${description}`);
    return;
  }

  const prefix = pathForError ? `${pathForError}: ` : '';
  errors.push(`${prefix}${description}`);
  console.error(`FAIL: ${prefix}${description}`);
}

function includesAll(text, snippets) {
  return snippets.every((snippet) => text.includes(snippet));
}

function validatePlanContract(doc) {
  const intentGate = doc.text;
  const activeMenu = doc.text;
  const passiveMenu = doc.text;

  check(
    `${doc.path} documents free-form writing requests routing to active`,
    includesAll(intentGate, [
      'free-form 작성 지시가 있으면 질문 없이 active 분기로 진행합니다.',
      'free-form 작성 지시는 명령 인자에 자연어 topic과 즉시 작성 동사가 함께 있는 경우입니다.',
    ]),
    doc.path,
  );

  check(
    `${doc.path} documents blank omitted intent defaulting to passive only when no writing request exists`,
    intentGate.includes('`--intent`가 없고 free-form 작성 지시도 없으면 기본값으로 `passive`를 사용합니다.'),
    doc.path,
  );

  check(
    `${doc.path} documents explicit active/passive routing without prompt`,
    includesAll(intentGate, [
      '`--intent=active`면 질문 없이 active 분기로 진행합니다.',
      '`--intent=passive`면 질문 없이 passive 분기로 진행합니다.',
    ]),
    doc.path,
  );

  check(
    `${doc.path} requires AskUserQuestion handoff menus`,
    doc.text.includes('AskUserQuestion') && doc.text.includes('Active Handoff Menu') && doc.text.includes('Passive Handoff Menu'),
    doc.path,
  );

  check(
    `${doc.path} defines active 4-option handoff labels`,
    ['바로 실행', '계획 다듬기', '다른 정책으로', '나중에'].every((label) => activeMenu.includes(label)),
    doc.path,
  );

  check(
    `${doc.path} defines passive 4-option handoff labels`,
    ['Idea 선택해서 draft', 'proposal 다듬기', '다른 정책으로', '나중에'].every((label) => passiveMenu.includes(label)),
    doc.path,
  );

  check(
    `${doc.path} instructs immediate ow-work skill invocation instead of copy-paste handoff`,
    doc.text.includes('obsidian-workflows:ow-work') && /즉시\s*(fire|호출)/.test(doc.text),
    doc.path,
  );
}

function validateNoStalePatterns(doc) {
  const forbiddenPatterns = [
    'Next: /obsidian-workflows:work',
    '다음 단계: /obsidian-workflows:work',
    'Explicitly handoff to next execution command',
    '/obsidian-workflows:write-active topic=',
    'User should review ideas and choose',
    '/obsidian-workflows:plan',
    'obsidian-workflows:plan',
    '/obsidian-workflows:work',
    'obsidian-workflows:work',
    'python3 src/external-tools/keyword_detector.py',
    './src/scan-recent-files.sh',
  ];

  for (const pattern of forbiddenPatterns) {
    check(
      `${doc.path} does not contain stale pattern ${JSON.stringify(pattern)}`,
      !doc.text.includes(pattern),
      doc.path,
    );
  }
}

function validateHelperPathContract(doc) {
  check(
    `${doc.path} forbids cwd-relative src helper execution`,
    doc.text.includes('현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.')
      || doc.text.includes('현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다'),
    doc.path,
  );

  check(
    `${doc.path} requires plugin/repo root resolution before helper scripts`,
    doc.text.includes('plugin/repo root') || doc.text.includes('plugin/repo root를 해석'),
    doc.path,
  );
}

function validateWorkContract(doc) {
  check(
    `${doc.path} documents pending active handoff detection`,
    includesAll(doc.text, [
      '.claude/state/obsidian-write-active-handoff.json',
      'status: pending',
      'status: consumed',
    ]),
    doc.path,
  );

  check(
    `${doc.path} discourages copy-paste slash command routing`,
    doc.text.includes('명령어를 복사해 실행하는 흐름이 아닙니다')
      || doc.text.includes('copy and run another slash command'),
    doc.path,
  );
}

console.log('Validating canonical behavior contract and skill mirrors...\n');

validatePlanContract(docs.commandPlan);
validatePlanContract(docs.skillPlan);
validateWorkContract(docs.commandWork);
validateWorkContract(docs.skillWork);
validateHelperPathContract(docs.commandPlan);
validateHelperPathContract(docs.skillPlan);
validateHelperPathContract(docs.commandWork);
validateHelperPathContract(docs.commandCompound);
validateHelperPathContract(docs.commandReview);
validateHelperPathContract(docs.scanCommand);

for (const doc of Object.values(docs)) {
  validateNoStalePatterns(doc);
}

if (errors.length > 0) {
  console.error('\nBehavior contract validation failures:');
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log('\nCanonical behavior contract validation passed!');
