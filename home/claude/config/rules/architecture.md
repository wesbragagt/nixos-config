# Architecture Rules

## Deep Modules

Modules should provide powerful functionality behind simple interfaces. Pull complexity downward into the implementation — never push it onto the caller.

- The most common use case should require zero ceremony. If a caller needs to orchestrate multiple calls or pass many arguments for the simple case, the interface is too shallow.
- Each module encapsulates a design decision. If the same decision leaks into multiple modules, collapse it into one.
- Prefer a complex implementation with a simple interface over a simple implementation with a complex interface.
- Avoid shallow wrappers that just pass through to another layer. If a module's interface is as complex as its implementation, it's not pulling its weight.

## Ports and Adapters

Separate what the system does from how it connects to the outside world. Domain logic never imports from infrastructure.

- Define ports as contracts (interfaces/protocols) in the domain layer. Name them for the domain concept, never the technology (`OrderRepository`, not `OrderPostgresRepository`).
- Adapters implement ports and live in a separate layer. They own all serialization, wire formats, and technology-specific concerns.
- Dependencies point inward: adapters depend on domain, never the reverse.
- Wire adapters to ports at a single composition root. Domain code receives its dependencies, never constructs them.
- Entrypoints (HTTP handlers, CLI, workers) are thin glue: parse input, call domain, format output. No business logic.

## Type Safety at Boundaries

Use the type system to make invalid states unrepresentable. Trust internal code; validate at the edges.

- Use distinct types for domain identifiers. Never pass raw strings or ints where a typed ID is expected.
- Use structured types (records, data classes, typed dicts) for data crossing layer boundaries. Never pass raw maps/dicts between layers.
- Use enums or union types for fixed sets of values. Never use raw strings for state or status fields.
- Use immutable value objects by default. Mutability is opt-in with justification.
- Make expected failure paths explicit in return types rather than throwing exceptions. Reserve exceptions for truly exceptional cases.

## Testability Follows from Structure

If the architecture is right, testability comes for free.

- Domain tests need zero infrastructure. If a domain test requires a database, network, or filesystem, the boundary is in the wrong place.
- Test the domain through its ports. Mock only at port boundaries, not inside the domain.
- Adapters get their own integration tests against real infrastructure.
- Entrypoints get thin smoke tests — they should have almost no logic to test.
