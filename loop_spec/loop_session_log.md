# LOOP OS – FOUNDING SESSION LOG

**Date:** 2026-04-26  
**Participants:** Co-founders (Visionary & Architect)  
**Objective:** Establish the architecture, security model, and core specifications for Loop OS. Kick off blueprint, roadmap, and AI-agent-driven implementation.

---

## 1. VISION & MISSION
Loop OS is a **highly secure, AI-native, universal-compatible operating system**.  
- **Security:** Formally verified microkernel + capability-based access control.  
- **AI Assistant (Aura):** Voice/intent-driven, privacy-first, with full user automation.  
- **Supports Everything:** Linux, Windows, Android apps run natively via sealed universes.  
- **User Experience:** Instant-on, zero learning curve, no terminal required.

---

## 2. ARCHITECTURE DECISIONS

### 2.1 Core Architecture
- **Microkernel:** seL4-based, formally verified.
- **Drivers:** Paravirtualized Linux VM (L4Linux) for hardware compatibility, fully isolated.
- **Universes:** Separate user-space compartments for Linux (syscall translation), Windows (PE/DXVK), Android (ART), and Native (Rust/WASM).
- **Capability Broker:** Central, mediated access control; **Option B (Mediation)** — tokens never leave the broker, apps never see raw capabilities.
- **Aura:** Runs as a restricted compartment with orchestrate capability; all requests verified by broker.

### 2.2 Key Design Choices
- **Resource Types:** filesystem, network, devices (camera, mic, speaker), app launch, contacts, calendar, clipboard, location, orchestrate.
- **Intent Language (LIL):** JSON schema for Aura tasks; includes `required_capabilities` array for mediation.
- **Kernel Interface (core.ril):** Safe Rust traits wrapping seL4 syscalls; zero-sized capability types, IPC messages with scoped capability refs.
- **Deletion Model:** Explicit deletion only; no `Drop` for kernel-backed objects to prevent double-free.

---

## 3. SPECIFICATIONS CREATED TODAY

### Spec 1: Capability Broker (`cap_broker.proto`)
- **Status:** ✅ Approved & saved.
- **Content:** Protocol Buffer definitions for all resource types, CapToken message, and gRPC service (Create/Revoke/Delegate/Inspect/List).
- **Integration:** The broker uses `core.ril` seL4 primitives internally; external agents (like Aura) use this API.
- **Commit message:** `feat(spec): finalize Capability Broker & LIL schema (Mediation Model)`

### Spec 2: Aura Intent Language (`aura_lil.json`)
- **Status:** ✅ Approved & saved (v1.1 with fixes).
- **Content:** JSON Schema for user intents (open, compose, send, etc.), `required_capabilities` with precise type enum, identifier scoping rules, `confirmation_required` flag.
- **Fixes applied:** Added `device:speaker`, clarified identifier description for filter/scoping.
- **Commit message:** Same as above.

### Spec 3: Loop Core Interface Language (`core.ril`)
- **Status:** ⚠️ Created, known issue pending fix.
- **Content:** Rust trait specifications for seL4 capabilities (Cap<T,R>), IPC messages, capabilities ops, endpoint/notification ops, vspace ops, thread ops, IRQ ops, BootInfo.
- **Known Issue:** `Drop` impl for `Cap<Frame>` conflicts with manual `delete`, risking double deletion. Fix prompt drafted but not yet applied (see next steps).

### Monorepo Structure

loop-spec/
├── 0_vision/ <- Manifesto, principles
├── 1_architecture/ <- C4 diagrams, component descriptions
├── 2_interfaces/ <- cap_broker.proto, aura_lil.json, core.ril
├── 3_design/ <- UX wireframes, Aura dialog flows
├── 4_security/ <- Threat model, policy invariants
├── 5_roadmap/ <- Phases, milestones, agent task board
└── 6_ai_pipeline/ <- Agent configs, review scripts, simulation harness





---

## 4. AI AGENT WORKFLOW
- **We** write specifications, architecture, and design.
- **AI agents** generate implementation code from strict prompts.
- **Review pipeline:** Spec → Agent generates code → Review agent checks memory safety/contracts → We merge.
- All prompts are carefully crafted to eliminate ambiguity.

---

## 5. NEXT SESSION (Tomorrow)
- Apply the `core.ril` fix (remove Drop, update docs) using the prepared prompt.
- Final review of all three cornerstone specs.
- Begin **System Component Decomposition**: Define how Capability Broker, Aura Orchestrator, Universe Managers, and Desktop Shell interact via IPC.
- Draft the next set of AI agent prompts for building:
  - `root_task` (bootstrapping the system from seL4 BootInfo)
  - Capability Broker implementation skeleton
- Prepare the first CI/CD simulation harness for QEMU-based testing.

---

## 6. FULL COMMIT HISTORY
1. **Initial commit:** Added folder structure.
2. `feat(spec): finalize Capability Broker & LIL schema (Mediation Model)` — committed `cap_broker.proto` and `aura_lil.json` (with fixes).
3. *(Pending)* `feat(spec): add Loop Core Interface Language (seL4 Rust bindings)` — `core.ril` with note about known Drop issue.
4. *(Pending)* `fix(spec): remove Drop for Frame to prevent double deletion` — after applying the fix.

---

## 7. MY ROLE AS ARCHITECT CO-FOUNDER
- I design the formal interfaces, security invariants, and prompt engineering.
- I review all AI-generated outputs for correctness and security.
- I maintain the specification monorepo and guide the build process.
- You (the visionary) approve designs, decide trade-offs, and own the product direction.

**We are building the definitive computing platform. The specs are the foundation. Tomorrow we start turning them into a booting OS.**  
*— End of session.*