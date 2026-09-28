# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

## [1.0.6] - 2026-09-28

### App
- Card headers in the blue used for headings, not body grey.

## [1.0.5] - 2026-09-28

### App
- Cards have no border or header rule: figures, equations and stories sit
  on the page separated by whitespace alone.

## [1.0.4] - 2026-09-28

### App
- Cards, panels, tiles and buttons are square with no shadow: they organise
  the page rather than decorate it.

## [1.0.3] - 2026-09-28

### App
- The QR code returns to the foot of the sidebar, with the name and site
  address, alongside the small one in the title bar.

## [1.0.2] - 2026-09-28

### App
- No figure carries a title or subtitle inside the image; the card header
  and the caption under it name and explain the figure (CONVENTIONS.md 6).
- Figures are drawn on a white ground, so the image sits flat in its card
  instead of showing as a tinted tile.
- The reset-price weights figure is drawn at 3:2, not square.

## [1.0.1] - 2026-09-28

### App
- The In Words tab lays out its three columns at fixed widths, so an
  equation no longer collapses to one term per line beside its note.
- The preset card no longer doubles the word "Stage" in front of a stage
  name that already carries it.

## [1.0.0] - 2026-09-28

First public release as a standalone repository.

### Model
- Calvo (1983) pricing in the notation of question 3 of the 2023 ECON42550
  paper: the firm's loss function, the reset price, the price level and the
  New Keynesian Phillips curve with slope kappa = alpha (1 - theta)
  (1 - theta beta) / theta.
- A hybrid curve with a backward-looking share omega, inverted for the
  output gap an announced disinflation requires, and the sacrifice ratio.
- The mapping from months between price changes to theta and kappa.

### App
- Five stages that add one layer of the model at a time: one firm's price,
  the price level, the Phillips curve, disinflation, the micro evidence.
- Six worked examples, one or two per stage, each with a story and a prompt.
- Equations, Notation and In Words tabs that track the model at each stage.
- Readout tiles: price duration, effective horizon, the slope, inflation at
  the current gap, the sacrifice ratio, the implied theta.
- Ghost curves showing the loaded worked example alongside the live sliders.
