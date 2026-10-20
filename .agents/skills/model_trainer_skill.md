# Model Trainer Skill — Not Applicable

- **Last updated:** 2026-10-20

AptReceipt contains no machine-learning model, training pipeline or learned parameters (invoice scanning uses Apple's on-device Vision text recognition without training), so this skill has no procedure here. It exists to keep the standard `.agents/skills/` structure complete.

If a trained model is ever added, this file must first define: the training data source and its privacy rules (no real resident data), the retraining command, the metrics to export, and the backward-compatibility check for stored parameters (`snapshot_audit_skill.md`).
