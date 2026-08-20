# docs

| Folder | What is in it |
|---|---|
| `rules/` | How this repo is worked in. `CLAUDE.md` routes to these — read the one whose trigger matches the task, not all of them. |
| `setup/` | Console and portal steps the owner does by hand: Google/Apple sign-in, WeatherKit credentials, the app icon. |
| `release/` | Shipping. `PIPELINE.md` and `CREDENTIALS.md` get a build out; the rest is what App Store submission needs — the listing copy, the encryption declaration and its PDF. |
| `privacy/` | The privacy policy and the JSON the published site renders. **Two files saying one thing** — a change that moves data updates both (hard rule 17). |
| `archive/` | Point-in-time documents kept for their reasoning, not as descriptions of the app. Each says so at the top. |

At the top level:

- `PREMIUM_RULES.md` — the authority on prices, free limits and what every gate
  does. `CLAUDE.md` and the feature rules point here rather than restating it.
- `DONE_WORK.md` and `REMAINING_WORK.md` — **a pair, read together.** What is
  built, and a point-in-time survey of what is left (most of it console work
  rather than code). Neither is a live tracker: re-check an item before acting on
  it. When something closes it moves from the second file to the first.
- `NEW_PROJECT_BOOTSTRAP_PROMPT.md` — this repo's rules generalised into a prompt
  for starting the next project on them. **A copy, not a source**: nothing here
  reads it, and a rule changed in `rules/` does not reach it. Re-derive it rather
  than trusting it after a rule moves.
