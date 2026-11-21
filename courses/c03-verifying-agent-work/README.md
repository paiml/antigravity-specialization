# Verifying AI Agent Work with Google Antigravity

Worked examples from the third course of the specialization

The code for this course's examples, with the commands to run them. Each example directory is self-contained.

## Examples

| example | what it does |
|---|---|
| [`examples/m1-agentic-coding-evolution`](examples/m1-agentic-coding-evolution) | contrasting unverified single-shot output with a contract-verified step |
| [`examples/m1-what-is-generative-ai`](examples/m1-what-is-generative-ai) | verifying artifact invariants against stochastic output drift |
| [`examples/m1-llm-benefits-and-risks`](examples/m1-llm-benefits-and-risks) | auditing generated scripts for missing paths, placeholders, and masked errors |
| [`examples/m2-getting-started-antigravity`](examples/m2-getting-started-antigravity) | read-only workspace inspection using agy -p with --mode plan |
| [`examples/m2-antigravity-artifacts`](examples/m2-antigravity-artifacts) | enforcing plan, task, and walkthrough artifact contracts |
| [`examples/m2-create-first-agent`](examples/m2-create-first-agent) | authoring and validating a verification-first Antigravity agent |
| [`examples/m3-mitigating-risks-of-llms`](examples/m3-mitigating-risks-of-llms) | enforcing sandbox, runtime, secret, and non-empty guardrails on agent output |
| [`examples/m3-the-verification-ladder`](examples/m3-the-verification-ladder) | four rungs from existence check to semantic involution and planted-defect rejection |
| [`examples/m3-which-languages-suit-agentic-coding`](examples/m3-which-languages-suit-agentic-coding) | contrasting fail-fast strictness against silent permissive execution and scoring language gates |
| [`examples/m3-when-agents-fail`](examples/m3-when-agents-fail) | auditing four common silent failure modes in completed agent runs |
| [`examples/m4-simplifying-rules-with-automation`](examples/m4-simplifying-rules-with-automation) | replacing fragile prose checklists with a 6-line rule and one automated gate |
| [`examples/m4-using-test-driven-development`](examples/m4-using-test-driven-development) | enforcing Red-Green TDD so an agent proves its test suite can fail before passing |
| [`examples/m4-using-advanced-verification-with-pmat`](examples/m4-using-advanced-verification-with-pmat) | enforcing strict zero-violation and anti-vacuity gates on pmat quality-gate output |
| [`examples/m5-why-ci-is-the-referee`](examples/m5-why-ci-is-the-referee) | an independent clean-room referee that catches a self-reporting agent's blind spots |
| [`examples/m5-github-actions-intro`](examples/m5-github-actions-intro) | a minimal GitHub Actions workflow and an offline YAML structure checker |
| [`examples/m5-components-of-a-job`](examples/m5-components-of-a-job) | job dependencies, timeouts, environment variables, and step failure propagation |
| [`examples/m5-dockerfile-linting`](examples/m5-dockerfile-linting) | a pull-request CI gate that rejects unpinned base images, root containers, and bad RUN habits |
| [`examples/m5-ci-verifying-agent-work`](examples/m5-ci-verifying-agent-work) | an agent-PR CI gate checking scope boundaries, hygiene, test integrity, and clean-room execution |
| [`examples/m6-anatomy-of-a-verified-repo`](examples/m6-anatomy-of-a-verified-repo) | a complete case-study repository tying manifest, AGENTS.md, deterministic scripts, and CI together |
| [`examples/m6-antigravity-analysis`](examples/m6-antigravity-analysis) | running agy --mode plan read-only against a repo and verifying citations against ground truth |

## Modules

### Module 1: How LLMs Work and Fail

- Lesson 1: Introduction (`narration-only`)
- Lesson 2: How Agentic Coding Has Evolved — [`examples/m1-agentic-coding-evolution`](examples/m1-agentic-coding-evolution)
- Lesson 3: What Is Generative AI? — [`examples/m1-what-is-generative-ai`](examples/m1-what-is-generative-ai)
- Lesson 4: Benefits and Risks of Using LLMs — [`examples/m1-llm-benefits-and-risks`](examples/m1-llm-benefits-and-risks)
- Lesson 5: Summary (`narration-only`)

### Module 2: Antigravity Basics

- Lesson 6: Introduction (`narration-only`)
- Lesson 7: Getting Started with Antigravity — [`examples/m2-getting-started-antigravity`](examples/m2-getting-started-antigravity)
- Lesson 8: Antigravity Artifacts for Granular Control — [`examples/m2-antigravity-artifacts`](examples/m2-antigravity-artifacts)
- Lesson 9: Create Your First Agent — [`examples/m2-create-first-agent`](examples/m2-create-first-agent)
- Lesson 10: Summary (`narration-only`)

### Module 3: Guardrails and Constraints

- Lesson 11: Introduction (`narration-only`)
- Lesson 12: Mitigating Risks of LLMs — [`examples/m3-mitigating-risks-of-llms`](examples/m3-mitigating-risks-of-llms)
- Lesson 13: The Verification Ladder — [`examples/m3-the-verification-ladder`](examples/m3-the-verification-ladder)
- Lesson 14: Which Languages Suit Agentic Coding? — [`examples/m3-which-languages-suit-agentic-coding`](examples/m3-which-languages-suit-agentic-coding)
- Lesson 15: When Agents Fail — [`examples/m3-when-agents-fail`](examples/m3-when-agents-fail)
- Lesson 16: Summary (`narration-only`)

### Module 4: Automating Verification

- Lesson 17: Introduction (`narration-only`)
- Lesson 18: Simplifying Rules with Automation — [`examples/m4-simplifying-rules-with-automation`](examples/m4-simplifying-rules-with-automation)
- Lesson 19: Using Test-Driven Development — [`examples/m4-using-test-driven-development`](examples/m4-using-test-driven-development)
- Lesson 20: Using Advanced Verification with PMAT — [`examples/m4-using-advanced-verification-with-pmat`](examples/m4-using-advanced-verification-with-pmat)
- Lesson 21: Summary (`narration-only`)

### Module 5: CI/CD

- Lesson 22: Introduction (`narration-only`)
- Lesson 23: Why CI Is the Referee — [`examples/m5-why-ci-is-the-referee`](examples/m5-why-ci-is-the-referee)
- Lesson 24: Introduction to GitHub Actions — [`examples/m5-github-actions-intro`](examples/m5-github-actions-intro)
- Lesson 25: Components of a Job — [`examples/m5-components-of-a-job`](examples/m5-components-of-a-job)
- Lesson 26: Setting Up Dockerfile Linting for Pull Requests — [`examples/m5-dockerfile-linting`](examples/m5-dockerfile-linting)
- Lesson 27: Using CI for Verifying Agent Work — [`examples/m5-ci-verifying-agent-work`](examples/m5-ci-verifying-agent-work)
- Lesson 28: Summary (`narration-only`)

### Module 6: A Real-World Case Study

- Lesson 29: Introduction (`narration-only`)
- Lesson 30: Anatomy of a Verified Repository — [`examples/m6-anatomy-of-a-verified-repo`](examples/m6-anatomy-of-a-verified-repo)
- Lesson 31: Antigravity Analysis on an Agentic Repo — [`examples/m6-antigravity-analysis`](examples/m6-antigravity-analysis)
- Lesson 32: Course Conclusion (`narration-only`)

Part of the [Antigravity Specialization](../..) specialization.

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/course.toml` and re-render.</sub>
