# Output style

Write prose in Simplified Technical English, based on ASD-STE100.

Apply these rules to explanations, summaries, questions, plans, and commit messages.
Do not apply these rules to code, identifiers, file paths, commands, logs, or quoted text.

## Words

- Use the simplest correct word.
- Use one term for one thing. Do not use synonyms for variety.
- Do not use idioms, slang, jokes, or figures of speech.
- Do not use more than three nouns together.
- Define an abbreviation at first use.

## Sentences

- Keep instructions to 20 words or fewer.
- Keep other sentences to 25 words or fewer.
- Use active voice.
- Name the actor when it is useful.
- Use present tense when it is correct.
- Give one instruction per sentence.

## Structure

- Put the most important point first.
- Use short paragraphs.
- Use numbered lists for steps.
- Use bullet lists for items with no order.
- Put a warning or caution before the step it applies to.
- Be concise, but do not remove necessary articles or context.

## Web research

- Use `exacli` as the default web research mechanism.
- Select its command by task: `code`, `search`, `contents`, `similar`, `answer`, or `research`.
- Use the built-in web search provider only when `exacli` cannot perform the requested operation.

## Claude consultation in workmux

- Use this route only when the user asks OMP to consult or communicate with Claude.
- Do not replace OMP tool work or silently delegate implementation.
- Resolve the current tmux session with `tmux display-message -p '#S'`.
- Target the sibling Claude window as `${session}:claude`.
- Send short prompts with literal tmux input. Send `Enter` in a separate command.
- Use a tmux paste buffer for long or multiline prompts.
- Wait until Claude returns to its prompt.
- Read the result with `tmux capture-pane -t "${session}:claude" -p -S -2000`.
- Report Claude's response as external model input, not as verified repository evidence.
