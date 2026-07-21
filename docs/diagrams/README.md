# Diagrams

This folder holds the architecture diagrams embedded in the project [README](../../README.md).

| File | Shows |
|------|-------|
| `architecture.svg` | Challenge structure, the test harness/validation engine, the learner feedback loop, and CI. |
| `soroban-contract-lifecycle.svg` | How a single contract call moves through the Soroban host (auth, storage, return value) and how local unit tests simulate that without a network. |

## Format

Diagrams are hand-authored SVG, not exported from a diagramming tool. This keeps them:

- Text-diffable in pull requests (no binary blobs)
- Dependency-free to view (any browser or the GitHub UI renders them directly)
- Easy to tweak (colors, labels, boxes) with a normal text editor

Each diagram is a self-contained `<svg>` with inline styles — no external fonts, scripts, or stylesheets.

## Updating a diagram

1. Open the relevant `.svg` file in this folder and edit it directly (rects, text, and paths use plain coordinates — no build step).
2. Render it to check your changes before committing. The quickest way is a headless browser screenshot:
   ```bash
   google-chrome --headless --disable-gpu \
     --screenshot=/tmp/preview.png --window-size=1220,920 \
     --default-background-color=FFFFFFFF \
     "file://$(pwd)/docs/diagrams/architecture.svg"
   ```
   Any SVG-capable viewer works too (opening the file directly in a browser, VS Code's SVG preview, Inkscape, etc.).
3. If you add a new diagram, embed it in [`README.md`](../../README.md) with a Markdown image and a **descriptive `alt` text** — the alt text should describe what the diagram communicates, not just name the file, since it's what screen readers and GitHub's accessibility tooling use.
4. Keep diagrams beginner-friendly: label every box, avoid unexplained abbreviations, and prefer a short caption over a dense legend.
5. If the underlying system changes (new script, new challenge tier, new CI step), update the diagram in the same PR as the code change so it never drifts out of date.

## Attribution

When you add or substantially redesign a diagram, add a one-line credit under the image in the README (see the existing entries) so contributors know who to ask about it.
