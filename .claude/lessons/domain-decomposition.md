# Domain Decomposition — Lessons

## Origin

Discovered through a design conversation where we broke down "how would you build a LangChain agent" into its fundamental components. The decomposition produced better spec structure than cold web research alone. The pattern generalizes to ANY domain — not just agent building.

## The Principle

Every domain has an anatomy — core components that someone actually builds or executes. Identifying those components BEFORE doing broad research makes the research targeted instead of shallow. This applies to QA testing, compliance, content ops, real estate deals, DevOps, agent building, or any other domain.

## Three Spec Types

Before decomposing any domain, identify which type:

| Type | What the spec does | Output | Example |
|------|-------------------|--------|---------|
| **BUILD** | Agent constructs a specific artifact | Working software, config, system | Build a LangChain agent, build a test suite, build a Docker pipeline |
| **WORKSPACE** | Agent sets up a governed environment for repeated work | Dev environment + patterns + templates | Set up a QA workspace, set up a compliance environment |
| **OPERATE** | Agent executes an ongoing business process | Process results, decisions, documents | Process lease option leads, handle customer support tickets |

The decomposition, audit, and design all change based on type:
- **BUILD** fractures by component (what are the parts of the thing being built?)
- **WORKSPACE** fractures by setup need (what does someone need to be productive?)
- **OPERATE** fractures by process stage (what are the steps in the workflow?)

## Anatomy Mapping

Every domain's components map to spec layers:

| Spec Layer | What It Holds | BUILD Example | OPERATE Example |
|------------|--------------|---------------|-----------------|
| SKILL.md + steps/ | Core instructions | "How to build each component" | "How to execute each stage" |
| commands/ | Entry points for actions | "Build tool X", "Wire loop" | "Intake lead", "Score seller" |
| workflow.md | Orchestration + phase sequence | Component dependency graph | Process stage sequence |
| gate-contract.md | Validation criteria | "Does it pass tests?" | "Does it meet criteria?" |
| lessons/ | Compounding knowledge | Anti-patterns from builds | Anti-patterns from process runs |

## Key Directives

1. **Decompose before research** — structured decomposition produces targeted audit. Cold web search produces shallow specs.
2. **Ask "what type?" first** — BUILD/WORKSPACE/OPERATE changes everything downstream.
3. **Map anatomy to spec layers** — every domain component should map to a specific spec file type.
4. **Fracture into atomic tasks** — one decision, one artifact, one gate per task.
5. **Identify external system boundaries** — these define what's testable and what's not.
6. **The decomposition is domain-agnostic** — the same three questions work for any industry: what type, what anatomy, how does it fracture.

## SDD Connection

The entire task cycle is SDD (Spec-Driven Development):
- Spec → Execute → Gate → Artifact → Next Spec
- Works at macro level (domain spec defines the full workflow) and micro level (each task is its own spec)
- The kernel doesn't know what domain it's governing — it just enforces spec → gate → artifact
- One kernel, one execution model, infinite domains. The spec is the variable.

## Factory Orchestration Pattern

The factory and validation are **separate concerns**. The factory builds specs (11 steps). Validation is orchestrator-driven, task-based.

### Factory Run (Subagent-Based)

```
Orchestrator (you)
  └→ Set up factory workspace (kernel + meta-spec, commit kernel)
      └→ Sub1: session-start → domain-setup → needs_restart
      └→ Sub2 (fresh, simulates restart): session-start → anchor → /spec-factory-run
          └→ Steps 1-11: decompose, audit, score, design, build, package
          └→ Spec output written to output/{{domain}}/
```

### Validation (Orchestrator-Driven, Task-Based, Gate-Contract-Verified)

```
Orchestrator (you)
  └→ Set up test workspace (kernel + spec)
      └→ Sub1: session-start → domain-setup → needs_restart
      └→ Orchestrator: read gate-contract.md → generate one task per gate → write to tasks/
      └→ Sub2 (fresh): session-start → anchor → /kernel/autonomous-cycle
          └→ Cycling executes tasks in order, kernel-governed
      └→ Orchestrator: read gate-contract.md → verify each gate against output
          └→ FAIL → fix spec or tasks, learn, retry (max 3)
          └→ PASS → ship
```

**Key design decisions:**
- No validation skill — gate contract IS the test spec
- Tasks are atomic — one task per gate (1:1 mapping), zero drift
- Sub2 runs `/kernel/autonomous-cycle` — programmatic, not prompt-driven
- Orchestrator writes tasks AND verifies gates — builder never validates itself
- Gate contracts are granular: one check, one verification method, one pass/fail
- Subagents cannot spawn nested subagents — orchestrator spawns Sub1/Sub2 directly

Each subagent is fresh (simulates restart). The factory creates specs in NEW repos, not inside itself.
