---
name: hexagonal-layers
description: "Reference guide for hexagonal architecture (ports & adapters) layers. Use when designing, reviewing, or implementing code that follows hexagonal/ports-and-adapters architecture, or when the user asks about layer responsibilities, where code belongs, or how to structure a bounded context."
---

# Hexagonal Architecture — Layer Reference

## Dependency Rule

**All dependencies point inward.** The domain never imports from ports, adapters, or infrastructure. Ports never import adapters. Adapters import ports.

```
  Adapters ──▶ Ports ──▶ Domain
  (outer)                (inner)
```

Violating this rule is the #1 architectural mistake.

---

## Layers

### Domain (Core)

**What it is:** Pure business logic. Zero framework, DB, or I/O imports.

**Contains:**
- **Entities** — Objects with identity that change over time (e.g., `Order`, `User`, `BankAccount`). Equality by ID, not by value.
- **Value Objects** — Immutable, no identity, self-validating (e.g., `Money`, `Email`, `DateRange`, `Address`). Compared by attribute values. Operations return new instances.
- **Aggregates** — Consistency boundaries grouping entities/VOs. One root per aggregate. Cross-aggregate references by ID only.
- **Domain Services** — Stateless pure logic that doesn't belong to a single entity (e.g., funds transfer between two accounts).
- **Domain Events** — Things that happened, named in past tense (e.g., `OrderPlaced`, `PaymentReceived`).

**What it does NOT contain:**
- No imports of ORM decorators (`sqlalchemy`, `typeorm`)
- No HTTP framework references (`fastapi`, `express`, `gin`)
- No serialization logic, no DB queries, no API calls
- No knowledge of how it's triggered or where data is stored

**Test:** Domain tests run with zero infrastructure — no DB, no HTTP server, no mocks.

---

### Ports (Contracts)

**What they are:** Interfaces owned by the core that define the boundary between domain and outside world.

#### Input Ports (Primary / Driving)

**Purpose:** Define how the outside world calls INTO the application. These are the use cases — the application's public API.

**Contains:** Use case interfaces that specify *what* the app can do.
- `CreateOrderUseCase.execute(cmd) → Order`
- `CancelOrderUseCase.execute(orderId) → Order`

**Why they exist:**
1. **Stable contract** — Domain internals can refactor without breaking adapters.
2. **Multiple triggers** — Same use case callable from REST, CLI, gRPC, or tests.
3. **Explicit API surface** — Look at input ports to see everything the app does.

**Note:** Input ports don't have to be abstract interfaces. A concrete use case class *is* the port — what matters is the stable public boundary it exposes.

#### Output Ports (Secondary / Driven)

**Purpose:** Define how the application calls OUT to external systems. Infrastructure contracts the domain owns.

**Contains:** Interfaces for external dependencies the domain needs.
- `OrderRepository.save(order)`, `OrderRepository.findById(id)`
- `PaymentGateway.charge(orderId, amount)`
- `EventPublisher.publish(event)`

**Why they exist:**
1. **Dependency inversion** — Domain defines what it needs; adapters provide it. Domain never imports infrastructure.
2. **Swappability** — Swap Postgres for MongoDB by replacing one adapter. Domain unchanged.
3. **Test fakes** — Inject `InMemoryOrderRepository` to test without a DB.

---

### Adapters (Implementations)

**What they are:** Concrete implementations that connect the ports to real technology.

#### Input Adapters (Primary / Driving)

**Purpose:** Receive external requests and translate them into domain calls.

**Contains:**
- REST controllers, CLI handlers, gRPC servers, message consumers, GraphQL resolvers

**Responsibilities:**
- Parse HTTP request → construct a command/DTO
- Call the input port (use case)
- Map domain response → HTTP response / CLI output
- Handle framework-specific error mapping (domain errors → HTTP status codes)

**Rule:** No business logic here. If there's an `if` statement that isn't about HTTP status codes or input validation, move it to the domain.

#### Output Adapters (Secondary / Driven)

**Purpose:** Implement output port interfaces with concrete technology.

**Contains:**
- PostgreSQL repositories, Redis caches, Stripe payment clients, SMTP email senders, S3 storage clients

**Responsibilities:**
- Translate domain models → database rows, API payloads, etc.
- Translate database rows, API responses → domain models
- Handle technology-specific concerns (connection pooling, retries, transactions)

**Rule:** Adapters translate data formats. They don't make business decisions.

---

### Composition Root (Wiring)

**What it is:** The outermost layer where everything is wired together. Usually `main.go`, `app.ts`, `composition_root.py`, or a DI container.

**Responsibilities:**
- Construct concrete adapters
- Inject adapters into domain services via constructors
- Start the server / application

**This is the only place** that knows about both adapters and domain simultaneously.

---

## Quick Placement Guide

| "Where does X go?" | Layer |
|---|---|
| Business rule or validation | Domain (entity or domain service) |
| Use case orchestration (load → validate → save → notify) | Application service (behind input port) |
| REST route handler | Input adapter |
| "Is this amount negative?" check | Domain (value object `__post_init__` / constructor) |
| "Map request body to domain command" | Input adapter |
| "Map domain entity to DB row" | Output adapter |
| "Which HTTP status code for this error?" | Input adapter |
| "Should this order be cancellable?" | Domain (entity method) |
| "Connect to database and build repos" | Composition root |
| Repository interface definition | Output port |
| Repository Postgres implementation | Output adapter |
| `Money.add(other)` returning new `Money` | Domain (value object) |
| Domain model ↔ API response mapping | Input adapter (return DTOs, never raw domain objects) |

---

## Decision Checklist

### Entity or Value Object?

| Question | Yes → | No → |
|---|---|---|
| Does it have identity that matters to the business? | Entity | Continue |
| Does it change over time while remaining "the same thing"? | Entity | Continue |
| Defined entirely by its attribute values? | Value Object | Entity |
| Can you swap it for an identical copy without the business caring? | Value Object | Entity |
| Is it a measurement, quantity, or descriptor? | Value Object | Continue |

### When to use hexagonal architecture:

**Use it when:** Complex domain with real business rules, multiple I/O boundaries, long-lived systems, need to test domain in isolation, need to swap infrastructure.

**Skip it when:** Simple CRUD, short-lived prototype, thin DB wrapper, team is tiny and domain is straightforward.

---

## Common Anti-Patterns

1. **Business logic in adapters** — If an adapter has domain rules, move them inward.
2. **Domain importing frameworks** — The domain must have zero infrastructure imports. Enforce with architecture tests.
3. **Leaking domain models through API** — Return DTOs from input adapters, not domain objects.
4. **Port named after CRUD, not intent** — Bad: `DataService`. Good: `CreateOrderUseCase`.
5. **Over-engineering** — Don't create 15 interfaces for a 3-endpoint service. Start with output ports only; add input port abstractions when complexity justifies them.
