#!/usr/bin/env bash
# Lesson 3.1.5: Accessibility and mobile checks. RUNS: structural checks on the page (language, viewport, labels, accessible names,
# focus style, touch target size, narrow-screen rule) and the contrast ratio of every text and background pair, computed from the CSS
# variables. SCRIPTED: keyboard walk and the 390 px viewport in a browser. BLOCKED when agy has no quota.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
cd "$WORK/app/public" || exit 1
bad=0
check() { # name, command...
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then echo "ok    $name"; else echo "FAIL  $name"; bad=1; fi
}
say "structure"
check "html has a lang attribute" grep -q '<html lang="en">' index.html
check "viewport meta is set" grep -q 'name="viewport" content="width=device-width' index.html
for id in title token; do
  check "input #$id has a label" grep -q "<label for=\"$id\">" index.html
done
check "the message area is a live region (role=alert)" grep -q 'id="message" role="alert"' index.html
check "sections are named by their headings" grep -q 'aria-labelledby="h-done"' index.html
check "card buttons get aria-label from app.js" grep -q "setAttribute('aria-label'" app.js
check "a visible focus style exists" grep -q ':focus-visible' style.css
check "buttons are at least 2.75rem (44 px) tall" grep -q 'min-height: 2.75rem' style.css
check "one column under 40rem" grep -q 'max-width: 40rem' style.css
say "contrast ratio (WCAG: 4.5 to 1 for body text), computed from the CSS variables"
node -e "
const css=require('node:fs').readFileSync('style.css','utf8');
const v={};for(const m of css.matchAll(/--([a-z-]+): (#[0-9a-f]{6});/g))v[m[1]]=m[2];
const lum=h=>{const c=[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)/255).map(x=>x<=0.03928?x/12.92:((x+0.055)/1.055)**2.4);return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]};
const ratio=(a,b)=>{const x=lum(a),y=lum(b);return (Math.max(x,y)+0.05)/(Math.min(x,y)+0.05)};
const pairs=[['text','bg'],['text','surface'],['muted','surface'],['muted','bg'],['on-accent','accent'],['error','surface'],['error','bg']];
let low=0;
for(const [f,b] of pairs){const r=ratio(v[f],v[b]);console.log('  '+(r>=4.5?'ok    ':'FAIL  ')+f+' on '+b+': '+r.toFixed(2)+' to 1');if(r<4.5)low++}
process.exit(low?1:0)" || bad=1
say "a pair that fails is caught (light grey on white)"
node -e "
const lum=h=>{const c=[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)/255).map(x=>x<=0.03928?x/12.92:((x+0.055)/1.055)**2.4);return 0.2126*c[0]+0.7152*c[1]+0.0722*c[2]};
const x=lum('#aaaaaa'),y=lum('#ffffff');const r=(Math.max(x,y)+0.05)/(Math.min(x,y)+0.05);
console.log('  grey on white: '+r.toFixed(2)+' to 1');process.exit(r<4.5?0:1)" || { echo "FAIL a low contrast pair passed"; bad=1; }
agy_step "$here/prompts/a11y-review.md" plan "$WORK/app"
say "BROWSER STEP (scripted, not run): Tab through the page, then resize to 390 px wide and check there is no sideways scroll"
exit "$bad"
