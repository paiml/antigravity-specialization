# Readings

Four short readings that go with the lessons. They describe how the scripts in this repository work; they make no claims about any particular model.

## Reading 1: what leaves your machine (chapter 1)

Every script here calls `127.0.0.1`, and the scripts pass `--offline` so a model is never downloaded by surprise. Do not take this on trust: run a lesson while watching connections with `ss -tnp`, and check what `apr serve` is listening on, before you rely on it. A hosted model is a different trade: you gain size and speed, and the prompt leaves your machine. Lesson 4.3 shows a routing rule for that choice.

## Reading 2: what a model file tells you (lessons 1.5 and 3.5)

`apr inspect <model>` prints the architecture, the size, and a provenance block with `license`, `data_source` and `data_license`. A field that says `(missing)` is not a pass: it means the file does not say. Read the upstream model card before real use, and write the license down next to the model name.

## Reading 3: why a pattern scan is not enough (lesson 3.3)

Prompt injection puts instructions inside text you meant as data. The demo scans for known phrases, strips the flagged lines, fences the rest in tags and tells the model the tags hold data. Each step helps and none is complete: a paraphrased instruction passes the scan, and a model can still follow text inside the tags. Treat the scan as one layer, keep the model's reach small, and keep a human check on anything that acts.

## Reading 4: evidence before trust (lessons 4.1, 4.2 and 4.5)

A small fixed test set with a ship gate (4.1) gives you a number you can repeat. A hash-chained audit trail (4.2) shows that a recorded decision was not edited afterward, with one stated limit: an edit of the last line cannot be detected by the chain alone. A drift check (4.5) reruns the same probes on a new model file and shows where the answers changed. Run all three when you switch models, and keep the output.
