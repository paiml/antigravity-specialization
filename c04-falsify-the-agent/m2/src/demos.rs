//! One function per demo bin. Each returns the text the bin prints and
//! whether the demo's claim held on the saved run.

use crate::diff;
use crate::score::{judge, kill_rate, parse_equivalents, rate_text, Outcomes, Verdict};
use std::fs;
use std::path::Path;

/// What a demo bin prints, and whether its contract held.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Report {
    pub text: String,
    pub ok: bool,
}

fn summary(name: &str, run: &Outcomes, verdict: &Verdict) -> String {
    let mut s = format!(
        "{name}: caught {} missed {} timeout {} unviable {} kill rate {}\n",
        run.caught.len(),
        run.missed.len(),
        run.timeout.len(),
        run.unviable.len(),
        rate_text(kill_rate(run.caught.len(), run.missed.len())),
    );
    for m in &run.missed {
        s += &format!("  MISSED {}\n", m.label());
    }
    s += &match verdict {
        Verdict::Accepted => format!("{name}: ACCEPTED\n"),
        Verdict::Refused(why) => format!("{name}: REFUSED ({why})\n"),
    };
    s
}

fn read(path: &Path) -> Result<String, String> {
    fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))
}

/// `m2_mutant`: the weak suite covers every line and leaves mutants alive. Refused.
pub fn what_a_mutant_is(dir: &Path) -> Result<Report, String> {
    let run = Outcomes::load(&dir.join("price-weak"))?;
    let verdict = judge(&run, &[]);
    let ok = !run.missed.is_empty() && matches!(verdict, Verdict::Refused(_));
    Ok(Report {
        text: summary("price weak suite", &run, &verdict),
        ok,
    })
}

/// `m2_kill`: with the `kill` test every survivor of the weak suite is caught. Accepted.
pub fn kill_the_survivor(dir: &Path) -> Result<Report, String> {
    let weak = Outcomes::load(&dir.join("price-weak"))?;
    let kill = Outcomes::load(&dir.join("price-kill"))?;
    let verdict = judge(&kill, &[]);
    let moved = weak
        .missed
        .iter()
        .filter(|m| kill.caught.iter().any(|c| c.label() == m.label()))
        .count();
    let mut text = summary("price with kill test", &kill, &verdict);
    text += &format!(
        "survivors of the weak suite now caught: {moved}/{}\n",
        weak.missed.len()
    );
    let ok = !weak.missed.is_empty() && moved == weak.missed.len() && verdict == Verdict::Accepted;
    Ok(Report { text, ok })
}

/// `m2_equivalent`: the survivors are equivalent; each is named with a reason. A raw
/// score below 100% is reported, an unexplained one refused, a bogus claim refused.
pub fn equivalent_mutants(dir: &Path) -> Result<Report, String> {
    let run = Outcomes::load(&dir.join("cap"))?;
    let eqs = parse_equivalents(&read(&dir.join("cap/equivalents.txt"))?)?;
    let raw = judge(&run, &[]);
    let honest = judge(&run, &eqs);
    let mut text = summary("cap raw", &run, &raw);
    for e in &eqs {
        text += &format!("  EQUIVALENT {} | {}\n", e.mutant, e.reason);
    }
    let rate = kill_rate(
        run.caught.len(),
        run.missed.len() - eqs.len().min(run.missed.len()),
    );
    text += &format!(
        "cap honest score: {} of non-equivalent mutants killed; ",
        rate_text(rate)
    );
    text += match &honest {
        Verdict::Accepted => "ACCEPTED with equivalents listed\n",
        Verdict::Refused(_) => "REFUSED\n",
    };
    let ok = !eqs.is_empty() && matches!(raw, Verdict::Refused(_)) && honest == Verdict::Accepted;
    Ok(Report { text, ok })
}

/// `m2_agent_suite`: the agent's patch is replayed byte for byte, then its own suite is
/// judged on the mutation run. The verdict is whatever the run says.
pub fn agent_suite(dir: &Path, agy: &Path, replayed: &str) -> Result<Report, String> {
    let base = "//! Shipping fees for a small shop.\n";
    let patch = read(&agy.join("patch.diff"))?;
    let identical = diff::apply(base, &patch)? == replayed;
    let run = Outcomes::load(&dir.join("agent-suite"))?;
    let verdict = judge(&run, &[]);
    let mut text = format!(
        "replay of fixtures/agy-runs/m2-agent-suite/patch.diff: {}\n",
        if identical { "identical" } else { "DIFFERS" }
    );
    text += &summary("agent suite", &run, &verdict);
    Ok(Report {
        text,
        ok: identical && run.tested() > 0,
    })
}

/// `m2_diff_scope`: survivors filtered to the lines a diff adds. The reader must agree
/// with the tool's own `--in-diff` run, keep the survivor in the diff, and
/// drop the survivors outside it.
pub fn diff_scope(dir: &Path, bulk_src: &str) -> Result<Report, String> {
    let change = read(&dir.join("diff-scope/change.diff"))?;
    let replay_ok = diff::apply("", &change)? == bulk_src;
    let added = diff::added_lines(&change)?;
    let full = Outcomes::load(&dir.join("diff-scope/full"))?;
    let tool = Outcomes::load(&dir.join("diff-scope/in-diff"))?;
    let (inside, outside): (Vec<_>, Vec<_>) = full
        .missed
        .iter()
        .partition(|m| added.iter().any(|(f, l)| *f == m.file && *l == m.line));
    let mut text = format!(
        "diff adds {} lines; full run survivors {}; in the diff {}; outside {}\n",
        added.len(),
        full.missed.len(),
        inside.len(),
        outside.len()
    );
    for m in &inside {
        text += &format!("  NEW SURVIVOR {}\n", m.label());
    }
    let mine: Vec<String> = inside.iter().map(|m| m.label()).collect();
    let theirs: Vec<String> = tool.missed.iter().map(|m| m.label()).collect();
    let agree = mine == theirs;
    text += &format!(
        "cargo mutants --in-diff survivors {}: {}\n",
        theirs.len(),
        if agree { "agree" } else { "DISAGREE" }
    );
    let ok = replay_ok && agree && !inside.is_empty() && !outside.is_empty();
    Ok(Report { text, ok })
}
