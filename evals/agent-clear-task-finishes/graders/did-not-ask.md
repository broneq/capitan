---
type: regex
target: last_message
pattern: "(finished|complete|done)\\?|confirm[^\\n]*\\?"
flags: i
match: not_contains
---
