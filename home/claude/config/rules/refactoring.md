# Refactoring Rules

## Tests Before Refactoring

Never refactor without a trustworthy test suite covering the behavior being changed. If the tests don't exist, write them first — then refactor.

- A refactor that breaks behavior undetected is not a refactor, it's a regression. Tests are the safety net that makes the distinction.
- "Trustworthy" means the tests exercise the actual behavior, not mocked-out shadows of it. If the tests would still pass after deleting the code under refactor, they're not trustworthy.
- If you can't write tests for the current code (too coupled, too tangled), that is the first refactor: make it testable. Do this in the smallest possible steps with manual verification before proceeding.
- Run the full relevant test suite before and after. Green before, green after, same behavior — that's a successful refactor.

## Ask Before Refactoring

Always confirm with the user before proceeding with a refactor. Present what you intend to change, which tests cover it, and wait for approval. Do not start moving code around autonomously — refactoring is a deliberate act, not a side effect.
