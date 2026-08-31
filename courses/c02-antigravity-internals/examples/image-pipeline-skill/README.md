# The pipeline as a skill

The same scripts, moved under .agents/skills/image-pipeline/ with a SKILL.md that says when to use them. The CLI reads the description to decide whether the skill applies, so the description is the part that has to be right.

## Run

```bash
agy -p 'use the image-pipeline skill on pyramid-star.png'
```

Requires the Antigravity CLI (`agy`) and ImageMagick. Run it from this directory so `.agents/skills` is in scope.

A project-local skill is a directory under `.agents/skills/`, holding a `SKILL.md` whose frontmatter carries just `name` and `description`. Only that description is in context until the model opens the file, so it has to state what the skill does and when it applies.

| file | |
|---|---|
| `.agents/skills/image-pipeline/SKILL.md` | the skill, name and description in frontmatter |
| `.agents/skills/image-pipeline/scripts/pipeline.sh` | what the skill runs |
| `.agents/skills/image-pipeline/scripts/remove_star.sh` | stage 1 |
| `.agents/skills/image-pipeline/scripts/transpose.sh` | stage 2 |
| `.agents/skills/image-pipeline/scripts/verify.sh` | the verification loop |
| `pyramid-star.png` | input, 502x460 |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/image-pipeline-skill/example.toml` and re-render.</sub>
