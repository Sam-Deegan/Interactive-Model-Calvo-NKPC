# Interactive Model: Calvo Pricing and the New Keynesian Phillips Curve

A Shiny app for teaching Calvo pricing and the New Keynesian Phillips
curve: where nominal rigidity comes from, what it does to the slope of the
Phillips curve, and what that slope means for a central bank trying to bring
inflation down. Built by [Sam Deegan](https://sam-deegan.com) for ECON42550
Macroeconomics, University College Dublin.

**Try it in the browser (nothing to install):**
https://sam-deegan.com/toy-models/calvo-nkpc/

Current version: **1.0.8** (see [CHANGELOG.md](CHANGELOG.md)). The version
is shown in the app footer; releases are tagged `vX.Y.Z`.

## What it does

The stage selector builds the model up one layer at a time:

| Stage | What is added |
|---|---|
| 1 | One firm's price: the loss function, the reset price, and how far ahead a resetting firm looks |
| 2 | The price level: a weighted average of old and new prices, so it creeps towards a new level rather than jumping |
| 3 | The New Keynesian Phillips curve, its slope κ, and how the slope falls as prices get stickier |
| 4 | Disinflation: the announced path, the output gap the hybrid curve says it takes, and the sacrifice ratio |
| 5 | The micro evidence: months between price changes pin down θ, and θ pins down κ |

Each stage opens on a worked example (very sticky prices, the price level
after a shock, a flat Phillips curve, a credible disinflation, a
disinflation that hurts, what the micro data say). Every slider has a box
beside it for an exact value, and every figure draws a ghost of the loaded
example alongside the live sliders once they move. The Equations, Notation
and In Words tabs show the model as it stands at the chosen stage and flag
what that stage changed.

## Run it locally

1. Install [R](https://cran.r-project.org/) (4.1 or later) and, ideally,
   [RStudio](https://posit.co/download/rstudio-desktop/).
2. Install the three packages once:

   ```r
   install.packages(c("shiny", "bslib", "ggplot2"))
   ```

3. Open `app.R` in RStudio and click **Run App**, or from R in this folder:

   ```r
   shiny::runApp()
   ```

Equations are typeset with MathJax from a CDN, so they need an internet
connection; everything else runs offline.

## Files

```
app.R          the app: settings and text (section B), figures (D),
               interface (E), server (F)
R/model.R      the model: durations, reset weights, the slope, the price
               level path, the Phillips curve, a disinflation and its
               sacrifice ratio. Sources on its own, so slides can reuse it.
R/toolkit.R    layout and helpers shared with the other toy-model apps
www/           logo and QR code
README.md      this file
CHANGELOG.md   version history
CONVENTIONS.md how the figures and worked examples are laid out
LICENSE        CC BY-NC-ND 4.0
```

All text on screen (worked examples, prompts, equations, notation) is in
section `B_03` of `app.R`, so it can be edited without touching the rest.

## The model

Calvo (1983) pricing is the standard way of putting nominal rigidity into a
macroeconomic model: each period a firm may reset its price with
probability `1 − θ`, whatever its price is and however long it has been
stuck. It is the model behind the New Keynesian Phillips curve taught in
Romer's *Advanced Macroeconomics* (2019, chapter 7) and the one set in
question 3 of the 2023 ECON42550 paper, whose notation the app follows.
Periods are quarters; prices are in logs; the output gap and inflation are
in per cent.

```
Loss:        min_z  Σ_k (θβ)^k E_t (z_t − p*_{t+k})²
Reset price: z_t = (1 − θβ) Σ_k (θβ)^k E_t p*_{t+k}
Optimal:     p*_t = p_t + α y_t + u_t
Price level: p_t = θ p_{t−1} + (1 − θ) z_t
NKPC:        π_t = β E_t π_{t+1} + κ y_t + e_t,   κ = α (1 − θ)(1 − θβ) / θ
Hybrid:      π_t = ω π_{t−1} + (1 − ω) β E_t π_{t+1} + κ y_t
```

**The firm's problem.** A firm that can reset picks the price `z_t` it
will be stuck with, so it minimises the expected squared distance from the
price it would charge if free, `p*`, weighted by the chance `(θβ)^k` that
the price still stands `k` periods on. `θ` is the share of firms that
cannot reset in a period, so a price lasts `1/(1 − θ)` periods on average;
`β` is the discount factor.

**The reset price** is the weighted average of the optimal prices the firm
expects over the life of the price. The weights `(1 − θβ)(θβ)^k` sum to
one, and the effective horizon is `1/(1 − θβ)` periods.

**The optimal price** is the price level plus a mark-up on real marginal
cost, which rises with the output gap `y`. `α` is how much the desired
price rises per point of output gap; `u` is a cost-push shock.

**The price level** is a weighted average of last period's prices and the
new one, so after a one-off rise in `p*` it closes a share `1 − θ` of the
remaining gap each period: `p_t − p* = θ^t (p_0 − p*)`.

**The New Keynesian Phillips curve** follows from putting the pieces
together. Inflation today depends on inflation expected tomorrow, not on
inflation yesterday, and on the output gap through the slope `κ`, which is
decreasing in `θ`: stickier prices mean a flatter curve. `e` is the
cost-push shock in the curve. **The hybrid curve** adds a backward-looking
share `ω` of pricing that is indexed or rule of thumb.

Everything is closed form. The disinflation at stage 4 takes an announced
straight-line glide from `π_0` to the target `π*` over a chosen number of
quarters and inverts the hybrid curve for the output gap each quarter
requires; a constant `(1 − ω)(1 − β) π*` is added so that the target is the
steady state of the curve. The sacrifice ratio is the cumulative output
lost per point of inflation brought down.

**What the five stages show with it**

- *1* How far ahead a resetting firm looks: raising `θ` stretches the
  weights out along the horizon, so more periods matter and each matters
  less.
- *2* The price level creeps, it does not jump. Only `1 − θ` of firms move
  each quarter, so adjustment is geometric and never quite complete.
- *3* The Phillips curve pivots about its intercept as `θ` changes; the
  slope `κ` falls throughout in `θ`, so a flat curve is a policy problem.
- *4* With purely forward-looking pricing (`ω = 0`) a credible announcement
  brings inflation down at no cost in output. Raise `ω` and the recession
  appears; going faster deepens the worst quarter without changing the
  total much.
- *5* Months between price changes in firm-level data pin down `θ`, and
  whether temporary sales count as price changes moves the implied `κ` by a
  factor of several. Even long durations imply a steeper curve than
  aggregate data show.

**Where it departs from the textbook.** The disinflation exercise is a
partial-equilibrium device: the central bank announces an inflation path
and the curve is inverted for the output gap, with no demand side, no
policy rule and no model of how the announcement is believed. The hybrid
curve is written in levels with a constant added so that the target is its
steady state, rather than in deviations from target. The micro-evidence
reference points are rounded, not estimates from any one study. The model
has no capital, no exchange rate and no fiscal block, and the sacrifice
ratio it reports is the model's, not a measured one.

## References

- Calvo, G. (1983). Staggered prices in a utility-maximizing framework.
  *Journal of Monetary Economics* 12(3).
- Romer, D. (2019). *Advanced Macroeconomics*, 5th ed. Chapter 7.
- ECON42550 Macroeconomics examination paper (2023), question 3.

## Licence

© Sam Deegan. Released under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
free to use and share for teaching with attribution; not for commercial use
or redistribution in modified form.
