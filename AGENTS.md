# AGENTS.md - Repo Instructions

This repo turns image artwork and technical reference drawings into editable, printable OpenSCAD relief models.

## Authority Chain

1. Clarify First: Explicitly state your assumptions, surface tradeoffs, and ask for clarification instead of guessing.
2. Keep it Simple: Write the absolute minimum code required; strictly avoid speculative features, unnecessary flexibility, or premature abstractions.
3. Be Surgical: Modify only what is strictly necessary to fulfill the request, perfectly matching the existing style without "improving" adjacent code.
4. Clean Your Mess: Delete dead code, unused variables, or imports only if your current changes rendered them obsolete.
5. Drive by Verification: Break tasks into step-by-step plans with verifiable success criteria (e.g., tests) and independently verify each step.

## Required Reading

- Read `rules.md` before creating or reviewing final `.scad` wrappers.
- Use the local `openscad` skill for model creation, previews, validation, and STL export.

## Repo Standards

- Prefer descriptive names in code, comments, parameters, modules, and explanations.
- Avoid vague names like `walls_2d`, `hseg`, `vseg`, `tmp`, `shape`, or `part` when a clearer modeling-role name is practical.
- Name geometry by purpose, such as `front_exterior_wall_segment`, `door_opening_gap`, `bathroom_upper_wall_segment`, or `architectural_wall_layout_2d`.
- Improve naming clarity when refactoring unless preserving an external API or explicit user request matters more.
- Preserve artwork intent and user-provided dimensions unless they create unsafe, unprintable, or misleading geometry.

## Workflow Reminder

- Classify inputs before choosing one of two pathways: artwork/logo/calligraphy SVG cleanup, or technical drawing reconstruction.
- Rebuild floor plans, diagrams, and dimensioned layouts directly in OpenSCAD instead of tracing by default.
- Use Inkscape-cleaned SVG paths for logos, calligraphy, silhouettes, badges, signs, and organic artwork when visual fidelity matters.
- Keep generated geometry separate from editable final wrappers.
- Validate, preview, export STL, and inspect the sliced result before calling a model ready.
