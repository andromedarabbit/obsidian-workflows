# Smoke Test: Work Mode Inference

## Steps and expected results

1. Prepare an unrelated pending proposal and pending active handoff. Request `최근 7일 음성노트를 처리해` without `mode`.
   - Route to `write-active` with the requested scope; do not open the proposal or consume the handoff.
2. With the same pending files, request `이 글을 초안으로 써줘`.
   - Route to `write-draft` for the requested topic, not the unrelated proposal. Ask if its proposal or idea cannot be identified.
3. Request the pending PLAN work explicitly or invoke WORK without a new target after choosing `나중에`.
   - Consume the handoff once and route to `write-active` with its arguments.
4. With no handoff or explicit request, invoke WORK while a proposal is pending.
   - Route to `draft` and retain the existing proposal selection rules.
5. Supply an explicit valid or invalid `mode`.
   - A valid mode takes precedence; an invalid mode fails immediately.
