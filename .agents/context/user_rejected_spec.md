# User Rejected Specs & Anti-Feature Redlines

This document tracks rejected ideas, anti-features, and design redlines that must not be introduced into the project.

- **Cloud/Remote Backend Dependency**: No mandatory external servers, Firebase, AWS, Supabase, or SaaS accounts. All operations must run strictly locally on macOS.
- **Aggressive Subscriptions/Paywalls**: No artificial limits on receipt count, flat capacity, or apartment size. The application is free and open-source under GNU GPL v3.0.
- **Telemetry & Tracking**: Zero third-party analytics libraries, unconsented telemetry, or network phone-home calls (GitHub update checker only connects upon explicit user check or background interval with user consent).
- **Hardcoded Single-Country Legal Frameworks (e.g., Mandatory "KMK" branding)**: Do not hardcode Turkish Property Law ("KMK") or any single jurisdiction's terminology across global receipts, templates, and UI. Late fee calculation must always be toggleable and support jurisdiction profiles (Turkey, Romania, International, Custom).
- **Destructive Cloud Sync Overrides**: Local data on the user's disk must never be overwritten without explicit user confirmation or manual backup restoration.
- **Several languages in one shared localization file** (2026-10-20): the former `Localizable.xcstrings` catalog was split; each language keeps its own `<lang>.lproj/Localizable.strings`.
- **Untranslated or English-fallback text in a non-English language file**, and user-facing text written directly into code (2026-10-20).
- **Settings tabs with different widths that resize or move the window** (2026-10-20): every settings tab uses the widest width (760 pt) so the window keeps its size and position.
- **A bottom "Close" button on About windows instead of the standard traffic lights** (2026-10-20).
