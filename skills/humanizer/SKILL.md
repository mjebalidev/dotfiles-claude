---
name: humanizer
description: Strip the patterns that mark text as machine-written — hollow contrasts, manufactured significance, filler transitions, formatting inflation — from prose, commit messages, PR descriptions, code comments and client documents. Use whenever asked to rewrite, humanize, de-slop, tighten or tone-check a piece of writing, or to review a draft that reads as AI-generated.
---

# Humanizer

Remove the tells, keep the voice. This file is written the way it asks you to
write; keep it that way when you edit it.

## Rules

1. Specificity beats significance. "Conversion dropped 12%" beats "a meaningful
   shift". State the fact and let the reader weigh it.
2. Fix by deletion before substitution. Most tells vanish when the scaffolding
   goes and the claim stays. Swapping one device for another relocates the slop.
3. Keep the author's register, sentence-length range and terms of art. A clean
   rewrite that flattens the voice has failed.
4. Do not overcorrect. Real lists, correct technical terms and long analytical
   sentences are not tells.
5. Never invent a name, date or figure to sound concrete. Check every specific
   the rewrite added against the source.

## Structure

| Tell | Fix |
|---|---|
| Throat-clearing opening ("In today's landscape…") | Open on the sharpest concrete thing |
| Signposted ending ("In conclusion", "Ultimately") | End on the strongest point |
| Recapping ("As we've seen", "To recap") | Delete |
| Template headings ("Overview", "Key Takeaways") | Name the actual content |
| Rule-of-three padding, especially when the third item merges the first two | Use the real number of items |
| A bulleted list wearing sentences ("The first reason is… the second…") | Write it as prose or as a real list |
| The same idea said three ways | Say it once |
| Mirrored opening and closing | Cut the mirror |

## Sentences

| Tell | Fix |
|---|---|
| "not X, but Y" / "the question isn't X, it's Y" | State Y. Keep a contrast only when the distinction is real, written once as fact |
| "the real X was…" pivot | State the answer, skip the strawman |
| Tacked-on `-ing` gloss ("underscoring the shift") | Stop at the end of the sentence |
| Self-posed question then answer ("The result? …") | State the point |
| "Not luck. Not timing. Just execution." | Collapse into one sentence |
| "From X to Y" where X and Y are not a spectrum | Name the actual things |
| Adverb propping a weak verb ("ran very quickly") | Use the right verb |
| Agentless passive ("the decision was made") | Name who acted |
| Metronome rhythm, every sentence mid-length | Vary deliberately, short next to long |

## Lexicon

- Delete as filler: *genuinely, honestly, truly, really, actually*, "to be
  honest", "it's worth noting", "importantly", "notably", "needless to say",
  "at the end of the day", "that said", "when it comes to".
- Use `is`. Not *serves as, stands as, represents, boasts, features*.
- No vague authority: "experts agree", "studies suggest". Name the source or
  drop the claim.
- Kill on sight: "a testament to", "a pivotal moment", "a significant shift",
  "underscores the importance of", "in the ever-evolving landscape".
- Slop cluster: *delve, tapestry, intricate, meticulous, interplay, leverage,
  utilize, robust, harness, seamless, realm, navigate, showcase, foster,
  crucial*. One use is fine; a cluster is the signal.
- Compress: "in order to" → "to"; "due to the fact that" → "because"; "has the
  ability to" → "can".
- Engineering metaphors used figuratively (*load-bearing*, *blast radius*,
  *surface* as a verb) are a tic outside their literal domain.

## Formatting

| Tell | Fix |
|---|---|
| Em dashes several per paragraph | Commas, semicolons, periods, parentheses |
| Bold on every other phrase | Remove most of it |
| Bold-lead bullets replacing prose | Prose, or a plain list |
| Emoji-led bullets | Remove |
| Title Case Headings | Sentence case |
| Decorative arrows, checkmarks, unicode bold | Plain text |
| A horizontal rule before every heading | Remove |
| A new synonym for the same noun each paragraph | Use the correct term consistently |

## Commits, PRs and code

- Commit subject: `add user prefs`, not `implement comprehensive user
  preferences management system`. The Angular rules in the global CLAUDE.md
  apply; this is about the words inside them.
- PR description: the user-visible change and the why. The diff lists the files.
- No chat residue in commits, PRs or comments: "Great question", "Let me break
  this down", "Hope this helps", "You're absolutely right".
- Contractions and fragments are fine in commits and chat. Full formal prose
  there reads as machine output.
- No closers inviting engagement ("Curious what others think"). State the ask:
  "Flag anything I missed".
- Reporting finished work: lead with the result and the evidence. No bare
  "Done.", no message built from `Label:` teasers, no "just say the word".
- Code: no blank line between every statement, no helper for a two-line
  operation, no signature exploded across five lines.

## Process

1. Read the whole input. Detection works on the piece, not sentence by sentence.
2. Note the voice: sentence-length range, register, idiom. Preserve all three.
3. Fix at the level the tell lives at. A colon-teaser chain or a paragraph that
   says one thing three times needs the passage rewritten, not a word swapped.
4. Before returning, name what still reads as AI and fix it. Then re-read once
   for what the fix introduced.
5. Asked to audit rather than rewrite: return the rewrite, then one line per
   change citing the original phrase and its replacement. If the source was
   already clean, say what did not change instead of manufacturing edits.
