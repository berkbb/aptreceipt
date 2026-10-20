# About Rules — Index & Governance

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt

`.agents/rules/` holds the declarative rules every agent follows. Read `../AGENTS.md` first; then the domain rules for the area you change; the core standards describe how agents work.

## Domain rules

| File | Covers |
| --- | --- |
| `localization_parity.md` | One-to-one translation, one file per language, parity tests |
| `ui_rules.md` | Dynamic presentation, hardcoded text ban, windows, appearance |
| `math_rules.md` | Financial invariants (cents, late fee, rates, formats, versions) |
| `swift_macos_architecture.md` | AppKit/SwiftUI architecture, persistence, localization lookup, source layout |

## Core AI standards (42)

| File | Standard | Status |
| --- | --- | --- |
| `agent_memory_architecture.md` | TencentDB Agent Memory Architecture | Applies |
| `github_spec_kit.md` | GitHub Spec Kit (SDD) | Applies |
| `../context/reflexion_memory_log.md` | Google DeepMind Agent Reflexion Framework | Applies |
| `aaif_agentic_foundation.md` | Linux Foundation Agentic AI Foundation (AAIF) | Not applicable |
| `agent2agent_protocol.md` | Google Agent2Agent Protocol (A2A) | Not applicable |
| `agent_payments_protocol.md` | Google Agent Payments Protocol (AP2) | Not applicable |
| `agent_skills_specification.md` | Anthropic Agent Skills Specification | Applies |
| `agent_to_ui_protocol.md` | Google Agent-to-UI Protocol (A2UI) | Not applicable |
| `agent_user_interaction_protocol.md` | CopilotKit Agent-User Interaction Protocol (AG-UI) | Not applicable |
| `agentic_commerce_protocol.md` | OpenAI and Stripe Agentic Commerce Protocol (ACP) | Not applicable |
| `agentic_detection_response.md` | Uber Agentic AI Detection and Response (ADR) | Not applicable |
| `apple_app_intents_agent.md` | Apple App Intents & System Agent Protocol (AIAP) | Not applicable |
| `autogpt_autonomous_loop.md` | AutoGPT Continuous Autonomous Goal Loop Standard | Applies |
| `aws_agent_governance.md` | AWS Bedrock Agentic Governance Standard | Applies |
| `camel_ai_inception.md` | CAMEL-AI Inception Prompting Standard | Applies |
| `chain_of_thought_prompting.md` | Google Research Chain-of-Thought Prompting | Applies |
| `cognition_devin_workflow.md` | Cognition AI Devin Autonomous Software Engineering Standard | Applies |
| `constitutional_principles.md` | Anthropic Constitutional AI Alignment Standard | Applies |
| `crewai_task_delegation.md` | CrewAI Multi-Agent Task Delegation Protocol | Applies |
| `dspy_declarative_signatures.md` | Stanford DSPy Declarative Signature Standard | Not applicable |
| `generative_agents_reflection.md` | Stanford Generative Agents Memory Reflection Standard | Applies |
| `grok_reasoning_trace.md` | xAI Grok Reasoning Trace Protocol | Applies |
| `huggingface_codeagent_actions.md` | Hugging Face Actions-as-Code Standard (CodeAgent) | Applies |
| `ibm_granite_enterprise.md` | IBM Granite Enterprise Agent Standard | Applies |
| `langgraph_state_machine.md` | LangChain/LangGraph Cyclic State Machine Standard | Applies |
| `mcp_apps_extension.md` | MCP Apps Extension | Not applicable |
| `mcp_enterprise_managed_authorization.md` | MCP Enterprise-Managed Authorization | Not applicable |
| `memgpt_os_memory.md` | MemGPT / Letta OS Memory Management Standard | Applies |
| `meta_fair_safety.md` | Meta FAIR Agentic Safety Protocol | Applies |
| `mistral_tool_binding.md` | Mistral AI Tool Binding Standard | Applies |
| `model_context_protocol.md` | Anthropic Model Context Protocol (MCP) | Applies |
| `multi_agent_orchestration.md` | Microsoft AutoGen Multi-Agent Orchestration Protocol | Applies |
| `openai_harmony_response_format.md` | OpenAI Harmony Response Format | Not applicable |
| `openai_model_spec.md` | OpenAI Model Spec | Applies |
| `openai_tool_calling_safety.md` | OpenAI Swarm Tool Safety Protocol | Applies |
| `openinference_specification.md` | Arize AI OpenInference Specification | Not applicable |
| `owasp_agentic_security.md` | OWASP Top 10 for Agentic Applications & LLMs (ASI) | Applies |
| `qwen_agent_interpreter.md` | Alibaba Qwen-Agent Code Interpreter Standard | Applies |
| `react_agent_methodology.md` | Google Research ReAct Methodology | Applies |
| `retrieval_augmented_generation.md` | Meta AI Retrieval-Augmented Generation (RAG) | Applies |
| `uber_adr_research_paper.md` | Uber ADR Research Paper (MLSys 2026 Industry Track) | Not applicable |
| `universal_commerce_protocol.md` | Google and Shopify Universal Commerce Protocol (UCP) | Not applicable |

## Maintenance

1. **Versioning:** every standard records source, version or date, last review date and change summary.
2. **Review cadence:** at least quarterly; security updates immediately.
3. **Source verification:** update only from primary, official sources; entries marked "to be confirmed" are verified on the next review.
4. **Impact analysis:** assess the effect on agent behavior and tooling before adopting an update.
5. **Rollback:** each file states how to remove it.
6. **Deprecation:** mark retired standards with rationale and replacement instead of silently deleting them.
7. **Conflict resolution:** safety, human oversight and the constitution take priority.
8. **Auditability:** record each update in its file's change summary and in the commit message.

Country-specific laws (EU AI Act and similar) are not adopted by default; they are activated only when the user asks for that jurisdiction.
