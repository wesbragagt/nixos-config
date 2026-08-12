---
name: ddd
description: "Apply Domain-Driven Design (DDD) and Ports & Adapters (Hexagonal Architecture) to new or existing projects. Use when designing software architecture, modeling business domains, refactoring toward clean architecture, creating bounded contexts, defining value objects/entities/aggregates, or implementing ports and adapters in any language. Triggers: 'design the architecture', 'apply DDD', 'use hexagonal architecture', 'refactor to clean architecture', 'define bounded contexts', 'create value objects', 'implement ports and adapters', 'add an anti-corruption layer'."
---

# DDD & Ports & Adapters Skill

Apply Domain-Driven Design strategic and tactical patterns combined with Hexagonal (Ports & Adapters) architecture to design robust, testable, maintainable software in any language.

---

## Core Philosophy

1. **The domain model is the center** — business rules live in pure domain code with zero infrastructure dependencies
2. **Dependencies point inward** — domain knows nothing about DBs, frameworks, or APIs; everything else knows about the domain
3. **Ubiquitous language** — code uses the same terms domain experts use; no translation layer between stakeholders and developers

---

## Step 1: Strategic Design (Before Writing Code)

### 1.1 Discover Bounded Contexts

Identify linguistic boundaries where terms shift meaning. For each bounded context:

- Define the **ubiquitous language** (key terms and what they mean *within* that context)
- Classify as **Core Domain** (competitive advantage, invest heavily), **Supporting Subdomain** (necessary but not differentiating), or **Generic Subdomain** (use off-the-shelf solutions)
- Own its own model, database schema (ideally), and code

**Red flag**: If a term means different things to different teams, that's a context boundary.

Example: In e-commerce, "Product" means a sellable item in Catalog, a SKU with stock levels in Inventory, and a physical package with weight/dimensions in Shipping.

### 1.2 Map Context Relationships

| Relationship | When to Use |
|---|---|
| **Customer-Supplier** | Upstream supplies downstream; both teams cooperate |
| **Conformist** | Downstream conforms to upstream without influence |
| **Anti-Corruption Layer (ACL)** | Downstream isolates from upstream via a translation layer |
| **Open Host Service** | Upstream publishes a standardized protocol (REST API) |
| **Published Language** | Well-documented interchange format (JSON schema, events) |
| **Shared Kernel** | Two contexts share a subset of the model (use sparingly) |

### 1.3 Identify Subdomains

Ask: "What is the reason this software exists?" That's the core domain. Everything else is supporting or generic.

---

## Step 2: Tactical Modeling (Within a Bounded Context)

### 2.1 Entity vs Value Object Decision Guide

| Question | Yes → | No → |
|---|---|---|
| Does it have a distinct identity that matters to the business? | **Entity** | Keep reading |
| Will it change over time while remaining the "same thing"? | **Entity** | Keep reading |
| Is it defined entirely by its attribute values? | **Value Object** | **Entity** |
| Can you swap it for an identical copy without the business caring? | **Value Object** | **Entity** |
| Does it represent a measurement, quantity, or descriptor? | **Value Object** | Keep reading |

**Common value objects**: Money, Email, DateRange, Address, Quantity, Dosage, Coordinates, Percentage, Phone number, URL, Percentage

**Common entities**: User, Order, Account, Product, Booking, Loan, Ticket

### 2.2 Value Objects — The Three Rules

1. **No identity** — compared by value, not by reference. Two `Money(10, USD)` are the same; nobody cares *which* $10 it is.
2. **Immutability** — operations return new instances, never mutate in place
3. **Self-validation** — reject invalid state at construction time. An invalid value object should never exist.

**Implementation checklist**:
- Private or frozen constructor (prevent external mutation)
- Static factory method or constructor with validation
- All methods return new instances (never `this`)
- Equality based on all attributes, not reference

**Value objects must be pure** — no side effects, no I/O, no infrastructure calls. Only data and derived calculations.

### 2.3 Entities

- Have a **unique identifier** (UUID, auto-increment ID, etc.)
- **Mutable** — attributes change over lifecycle while identity stays the same
- Enforce their own **invariants** (business rules) through methods, not setters
- Equality is based on **identity**, not attribute values

### 2.4 Aggregates

An aggregate is a **consistency boundary** — a group of entities and value objects that must be enforced together as a unit.

Rules:
- One **aggregate root** — all external access goes through it exclusively
- Cross-aggregate references are **by ID only** (never object references)
- A single transaction modifies only **one aggregate**
- Aggregates enforce invariants and emit **domain events**

Examples: `Order` (root) containing `OrderItem` entities; `BankAccount` (root) containing `Transaction` entities.

### 2.5 Repositories

Provide the illusion of an in-memory collection of aggregates. Abstract persistence behind a domain-oriented interface.

- Repository **interface** lives in the domain layer (or port layer)
- Repository **implementation** lives in the infrastructure layer (adapter)
- Methods: `save()`, `find_by_id()`, `find_by_criteria()`, `delete()`

### 2.6 Domain Services

When an operation does not naturally belong to a single entity or value object, it becomes a domain service. Stateless, pure business logic.

Examples: funds transfer between accounts (involves two aggregates), pricing calculation across multiple entities.

### 2.7 Domain Events

Represent something that happened in the domain that other parts may care about.

- Named in **past tense**: `OrderPlaced`, `PaymentReceived`, `LoanOverdue`
- Carry only the data consumers need
- Raised by aggregates, dispatched by an event bus
- Decouple producers from consumers across aggregates and bounded contexts

### 2.8 Application Service (Use Case)

Orchestrates flow — **no business logic**, only coordination:

1. Receive command/request
2. Load aggregate from repository
3. Invoke domain logic
4. Persist changes
5. Dispatch events

---

## Step 3: Ports & Adapters Architecture

### 3.1 The Dependency Rule

```
┌─────────────────────────────────────────────────┐
│  ADAPTERS (outermost)                           │
│  ┌──────────┐              ┌──────────────┐    │
│  │ REST API  │              │ PostgreSQL   │    │
│  │ CLI       │              │ Redis        │    │
│  │ gRPC      │              │ Stripe API   │    │
│  └─────┬─────┘              └──────▲───────┘    │
│        │                           │             │
│  ┌─────▼──────┐           ┌───────┴──────┐      │
│  │  INBOUND   │           │   OUTBOUND   │      │
│  │  PORTS     │           │   PORTS      │      │
│  │ (Use Cases)│           │ (Interfaces) │      │
│  └─────┬──────┘           └───────▲──────┘      │
│        └──────────┬───────────────┘              │
│              ┌─────▼──────┐                      │
│              │   DOMAIN   │                      │
│              │  (Core)    │                      │
│              └────────────┘                      │
└─────────────────────────────────────────────────┘
```

**Three layers**:
- **Domain (Core)**: Pure business logic — entities, value objects, aggregates, domain services, domain events. Zero external dependencies.
- **Ports**: Interfaces defining contracts. Inbound ports = use case interfaces. Outbound ports = infrastructure interfaces.
- **Adapters**: Concrete implementations. Inbound adapters = delivery mechanisms (REST, CLI, gRPC). Outbound adapters = infrastructure (DB, external APIs, message queues).

### 3.2 Port Design Rules

- **Inbound ports** = use case interfaces (what the outside world can do to the system)
- **Outbound ports** = infrastructure interfaces (what the system needs from the outside world)
- Ports reflect **business intent**, not CRUD operations
- Name after **capability**: `CreateOrder`, `ChargePayment`, `PublishEvent`
- Avoid generic names: `DataService`, `GenericRepository`, `RepositoryInterface`
- Keep ports small and focused — one per capability, not god-interfaces

### 3.3 Adapter Design Rules

- Adapters only do **I/O translation** — no business logic
- One adapter per port; easy to swap implementations
- Adapters depend on ports; ports never depend on adapters
- Inbound adapters convert external requests → domain calls
- Outbound adapters convert domain calls → external system operations

### 3.4 Anti-Corruption Layer

When integrating with external/legacy systems, the ACL is an **outbound adapter** that:
- Translates external data formats into domain models
- Isolates the domain from upstream model changes
- Lives in the adapter layer and implements a domain-defined port
- When the external system changes, only the ACL adapter changes — domain untouched

---

## Step 4: Project Structure

```
my-service/
├── domain/                    # Pure business logic (ZERO external imports)
│   ├── models/                # Entities, value objects, aggregates
│   ├── services/              # Domain services
│   └── events/                # Domain events
├── ports/
│   ├── input/                 # Use case interfaces (inbound ports)
│   └── output/                # Repository, gateway interfaces (outbound ports)
├── adapters/
│   ├── input/                 # REST controllers, CLI handlers, gRPC handlers
│   └── output/                # DB repos, external API clients, message publishers
└── config/
    └── composition_root       # DI wiring — the ONLY place that knows concrete adapters
```

Key rules:
- `domain/` has **zero external imports** (no HTTP, no DB driver, no framework)
- Adapters import ports; ports never import adapters
- Ports may import domain types (for method signatures)
- The composition root is the sole place that wires concrete adapters to ports

---

## Step 5: Composition Root (DI Wiring)

All wiring happens at the outermost layer. The domain never constructs adapters; dependencies are injected via constructor parameters.

The composition root:
1. Instantiates concrete adapter implementations
2. Wires them to the ports they satisfy
3. Creates application services with their dependencies
4. Starts the application (HTTP server, CLI, etc.)

This is the only file that knows which database, which payment provider, which framework is being used.

---

## Step 6: Testing Strategy

### 6.1 Domain Unit Tests (Pure — No Mocks, No DB, No HTTP)

Test business rules in complete isolation. Value objects and aggregates are pure logic.

- Test that invalid state is rejected at construction
- Test that invariants are enforced (e.g., "cannot confirm empty order")
- Test that domain events are raised when expected
- Test entity lifecycle transitions
- **Zero infrastructure required** — these are the fastest, most reliable tests

### 6.2 Service Tests with Mock/Fake Ports

Only outbound ports are mocked or replaced with in-memory fakes. Domain logic is exercised directly through the application service.

- Use in-memory implementations of repository ports
- Verify that the correct port methods are called
- Test error handling (port throws → service handles gracefully)

### 6.3 Adapter Tests

Test each adapter independently against its port contract:
- In-memory adapter for fast unit tests
- Real adapter with test containers / test databases for integration tests
- HTTP adapter tests using test request/response utilities

### 6.4 Architecture Fitness Functions

Enforce that the domain never imports infrastructure — add tests that parse the AST or imports and fail if a domain file imports from adapters, frameworks, or DB drivers.

---

## Step 7: Refactoring Existing Code to Hexagonal

### 7.1 Identify Violations

Look for:
- Business rules in controllers/handlers (move to domain)
- ORM decorators/annotations on domain models (extract to adapter)
- Direct framework imports in business logic (introduce ports)
- Raw primitives used for domain concepts (extract value objects)
- God classes mixing responsibilities (split into entity + value objects + services)
- `new` / instantiation of infrastructure inside domain code (inject via constructor)
- Domain models returned directly through API boundaries (introduce DTOs)

### 7.2 Refactoring Sequence

1. **Extract domain models** — pull out entities and value objects with no framework imports
2. **Define outbound ports** — extract interfaces for repositories and external services
3. **Create in-memory adapters** — replace DB/external calls for immediate testability
4. **Extract application services** — move orchestration from controllers to use cases
5. **Define inbound ports** — use case interfaces that adapters implement against
6. **Wire in composition root** — the only place that knows concrete implementations
7. **Add architecture tests** — fitness functions that prevent re-coupling

### 7.3 Refactoring Checklist

- [ ] Domain models have zero imports from frameworks (ORM, HTTP, serialization)
- [ ] Business rules live in domain layer, not in adapters or controllers
- [ ] Every outbound dependency has a port interface
- [ ] Adapters only do I/O translation (no `if` statements with business logic)
- [ ] Composition root is the sole wiring point
- [ ] Domain tests pass without any infrastructure
- [ ] Swapping an adapter requires zero changes to domain or use case code
- [ ] API boundaries return DTOs, not domain models directly

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Over-engineering a simple CRUD app | Start simple; refactor toward DDD as complexity grows |
| Business logic in adapters/controllers | Move all rules and decisions to domain layer |
| Domain imports framework/ORM | Domain layer has zero third-party dependencies |
| Ports named as CRUD (`DataService`) | Name by business intent (`CreateOrder`) |
| Leaking domain models through API | Return DTOs from inbound adapters |
| One giant model for entire system | Decompose into bounded contexts early |
| Value objects with identity | If identity matters, it's an entity |
| Mutable value objects | Operations must return new instances |
| Raw primitives for domain concepts | Wrap in typed value objects (eliminate primitive obsession) |
| Side effects in value objects | Value objects hold only pure data and derived calculations |
| God interfaces | Small, focused interfaces per capability |
| Cross-aggregate object references | Reference other aggregates by ID only |
| Transactions spanning multiple aggregates | One transaction per aggregate; use events for cross-aggregate consistency |

---

## When to Use vs When to Simplify

### Use DDD + Hexagonal When:
- Complex domain with many business rules
- Multiple bounded contexts with distinct ubiquitous languages
- Need to swap infrastructure (DB, messaging, payment providers)
- Long-lived systems where maintainability matters
- Testing business logic in isolation is a priority
- Multiple teams working in parallel on different contexts

### Simplify or Avoid When:
- Simple CRUD with minimal business logic
- Short-lived prototypes or throwaway scripts
- Small team, straightforward domain
- Thin wrapper over a database
- Overhead of indirection outweighs benefits
