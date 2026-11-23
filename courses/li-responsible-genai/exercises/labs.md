# Labs

Four hands-on labs. Each one reuses a lesson script and asks you to change an input and read the result. Start the local server first with `scripts/serve.sh` for every lab except lab 1 step 1.

## Lab 1: install and serve (lessons 1.2 to 1.4)

1. Run `c1l2-install-pull/run.sh` and read the version, the cached models and the dry-run of `apr pull`.
2. Start the server with `scripts/serve.sh`, then run `c1l4-serve-curl/run.sh`.
3. Change `DEMO_MODEL` to a different model from `apr list`, restart the server, and compare the reply to `c1l4-serve-curl/run.sh`.

Done when: you can call `/health`, `/v1/models` and `/v1/chat/completions` with curl and name the model that answered.

## Lab 2: local RAG (lessons 2.3 and 2.4)

1. Run `c2l4-rag/run.sh` with its default question.
2. Add a fourth file to `c2l4-rag/docs/` and ask a question only that file can answer: `c2l4-rag/run.sh "your question"`.
3. Ask a question none of the files can answer. The script must refuse to guess.

Done when: the right file is chosen for your new question and the no-match question is refused.

## Lab 3: bias and injection probes (lessons 3.2 and 3.3)

1. Edit `c3l2-bias-probes/data/names.txt`, run `c3l2-bias-probes/run.sh`, and read the saved replies, not only the counts. One run at temperature 0 is an illustration, not a statistical result.
2. Edit `c3l3-prompt-injection/data/review.txt` to hide an instruction in a new way and run `c3l3-prompt-injection/run.sh`. Note which attacks the pattern scan misses.
3. Extend the pattern in the scan, and write down what it still cannot catch.

Done when: you have one attack the scan catches, one it misses, and a note on why a pattern list is not a complete defense.

## Lab 4: evaluation set and model drift (lessons 4.1 and 4.5)

1. Add five questions to `c4l1-eval-set/data/eval.jsonl` and run `c4l1-eval-set/run.sh`. Set `THRESHOLD` and see the ship gate pass or fail.
2. Run `c4l5-model-drift/run.sh` with `MODEL_A` and `MODEL_B` set to two model files from `apr list`.
3. Add probes to `c4l5-model-drift/data/probes.txt` that matter for your own use and read every DRIFT line.

Done when: you can say which model you would ship for your task and what evidence the run gave you.
