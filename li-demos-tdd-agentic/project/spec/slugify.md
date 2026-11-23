# slugify specification

`src/slugify.sh [-n MAX] TEXT` prints a URL slug for TEXT followed by a newline.

- R1 Lowercase: every upper-case ASCII letter becomes lower case. Example: `ABC` gives `abc`.
- R2 Separators: every run of characters outside `a-z0-9` becomes one `-`. Example: `a,  b!!c` gives `a-b-c`.
- R3 Trim: the slug never starts or ends with `-`. Example: `  --Hi--  ` gives `hi`.
- R4 Empty: input with no letters or digits gives an empty line. Example: `!!!` gives an empty line.
- R5 Maximum length: with `-n MAX` (MAX at least 1) the slug is cut to at most MAX characters, and a `-` left at the end of the cut is removed. Example: `-n 6 "Hello World"` gives `hello`.

Out of scope: non-ASCII letters (they count as separators).
