################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Calvo Pricing and the NKPC: Interactive Shiny App                          ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Open app.R in RStudio and click Run App, or from this folder:
##     shiny::runApp()
##   Needs R 4.1 or later with shiny, bslib and ggplot2 installed. A hosted
##   copy runs in the browser at https://sam-deegan.com/toy-models/calvo-nkpc/
##   The stage selector builds the model up one layer at a time:
##     1  one firm's problem: the loss function and the reset price
##     2  the aggregate price level, and why it creeps
##     3  the New Keynesian Phillips curve and its slope
##     4  disinflation: what credibility is worth
##     5  the micro evidence on price stickiness
##   Periods are quarters. Defaults follow question 3 of the 2023 paper,
##   with theta = 0.75, so a price lasts a year on average.
##   All text (scenarios, prompts, equations, notation) lives in B_03.
##
## Inputs:
##   R/model.R (the model) and R/toolkit.R (shared layout and helpers),
##   both sourced automatically by Shiny.
##
## Outputs:
##   None. The app is interactive only.
##
## Packages:
##   shiny, bslib, ggplot2.
##
## Version:
##   B_03_14_version_chr; history in CHANGELOG.md; git tag vX.Y.Z.
##
## References:
##   Calvo, G. (1983). Staggered prices in a utility-maximizing framework.
##     Journal of Monetary Economics 12(3).
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 7 (the Calvo
##     model, the New Keynesian Phillips curve, inflation inertia).
##   ECON42550 examination paper (2023), question 3, for the notation and
##     the calibration.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C (the model) is in R/model.R and T (the toolkit) in R/toolkit.R.
#
#   B: Setup
#     B_01  Packages
#     B_02  Settings
#     B_03  Soft-coded objects
#     B_04  Paths
#   C: Model (R/model.R)
#   T: Toolkit (R/toolkit.R)
#   D: Plots
#     D_01  The firm and the price level
#     D_02  The Phillips curve
#     D_03  Disinflation and the evidence
#   E: User Interface
#   F: Server
#   G: Run

################################################################################
## B: Setup ####################################################################
################################################################################
# Note: Packages, options and every soft-coded value.

#### B_01: Packages ############################################################
# Note: Shiny for the app, bslib for the look, ggplot2 for the figures.

###### B_01_01: Load Packages ##################################################
# Note: All three run under shinylive.

library(shiny)
library(bslib)
library(ggplot2)

###### B_01_02: Load the Model #################################################
# Note: Shiny sources R/ itself; this covers sourcing app.R by hand.

if (!exists("C_01_03_kappa_fn")) {
  source(file.path("R", "model.R"))
}

###### B_01_03: Load the Toolkit ###############################################
# Note: The shared palette, plot theme, CSS and builders.

if (!exists("T_01_01_palette_vec")) {
  source(file.path("R", "toolkit.R"))
}

#### B_02: Settings ############################################################
# Note: Standard options.

###### B_02_01: Global Options #################################################
# Note: No scientific notation; three digits in the console.

options(scipen = 999, digits = 3)

###### B_02_02: Seed ###########################################################
# Note: Nothing here is random; kept for consistency.

set.seed(42)

#### B_03: Soft-Coded Objects ##################################################
# Note: Calibration, stages, evidence, scenarios, controls, equations, text.

###### B_03_01: Input Defaults #################################################
# Note: Starting value of every control; Reset returns here. Quarterly.
#   theta = 0.75 is the calibration of question 3 of the 2023 paper: a
#   quarter of firms reset each quarter and a price lasts a year.

B_03_01_defaults_lst <- list(
  theta     = 0.75,  # share of firms that cannot reset this period
  beta      = 0.99,  # discount factor
  alpha     = 0.25,  # sensitivity of the optimal price to output
  pi_expect = 2,     # expected inflation next period
  y_gap     = 0,     # the output gap
  shock     = 0,     # cost-push shock
  omega     = 0,     # share of pricing that is backward-looking
  pi_start  = 8,     # inflation before the disinflation
  pi_target = 2,     # the target
  length    = 1,     # quarters over which inflation is brought down
  n_periods = 24,    # quarters drawn
  months    = 12     # months between price changes, for the micro evidence
)

###### B_03_02: Stages #########################################################
# Note: One layer of the model each, all within lecture 2.3.

B_03_02_stages_vec <- c(
  "Stage 1: One Firm's Price"        = "1",
  "Stage 2: The Price Level"         = "2",
  "Stage 3: The Phillips Curve"      = "3",
  "Stage 4: Disinflation"            = "4",
  "Stage 5: The Micro Evidence"      = "5"
)

###### B_03_03: Micro Evidence #################################################
# Note: Roughly where the firm-level literature lands on how long a price
#   lasts. Studies differ mainly on whether temporary sale prices count:
#   including them shortens the median a great deal. These are rounded
#   reference points for the figure, not precise estimates.

B_03_03_evidence_df <- data.frame(
  label  = c("Including temporary sales", "Excluding temporary sales",
             "The usual teaching calibration"),
  months = c(4, 10, 12),
  stringsAsFactors = FALSE
)

###### B_03_04: Scenarios ######################################################
# Note: Worked examples. Each belongs to one stage and overrides some
#   defaults; unlisted controls return to B_03_01. Story order and wording
#   follow CONVENTIONS.md sections 3 to 5.

B_03_04_scenarios_lst <- list(
  sticky = list(
    label  = "Very Sticky Prices",
    stage  = "1",
    values = list(theta = 0.9),
    story  = paste(
      "The probability that a firm cannot reset (θ) is raised to 0.9, so only",
      "one firm in ten moves in any quarter and a price lasts ten quarters.",
      "The reset price (z<sub>t</sub>) is a weighted average of the prices the",
      "firm would charge if it were free (p*<sub>t</sub>) over the life of",
      "that price — the one star in this module that is a choice rather than a",
      "resting point — and raising θ stretches the weights (1 − θβ)(θβ)<sup>k",
      "</sup> out along the horizon. On the figure the mass slides right along",
      "the quarters-ahead axis while every individual bar falls on the weight",
      "axis: more periods matter, and each one matters less. The decay is set",
      "by θβ alone, giving an effective horizon of 1/(1 − θβ) quarters — watch",
      "how slowly the cumulative line climbs to one."
    ),
    prompt = paste(
      "Look at how slowly the weights decay. The firm is not being",
      "far-sighted by choice: it is stuck with whatever it picks. What does",
      "that do to the price it picks today?"
    )
  ),
  creep = list(
    label  = "The Price Level After a Shock",
    stage  = "2",
    values = list(theta = 0.75),
    story  = paste(
      "A one-off permanent rise in the price every firm would like to charge",
      "(p*<sub>t</sub>) lifts the dashed target, but the probability that a",
      "firm cannot reset (θ) is 0.75, so only a quarter of firms move in any",
      "quarter. The price level (p<sub>t</sub>) is a weighted average of last",
      "quarter's prices and the newly set ones, so it closes the same fraction",
      "1 − θ of whatever gap is left rather than jumping. The two axes come",
      "apart as the figure runs: on the vertical axis p<sub>t</sub> keeps",
      "rising towards the target, while along the quarters axis the inflation",
      "bars (π<sub>t</sub> = p<sub>t</sub> − p<sub>t−1</sub>) shrink",
      "geometrically. The whole path is p<sub>t</sub> − p* = θ<sup>t</sup>(p",
      "<sub>0</sub> − p*), so θ alone fixes how many quarters the creep takes",
      "and the level never quite arrives."
    ),
    prompt = paste(
      "Raise the rigidity and watch the adjustment stretch out. How many",
      "quarters does it take to get nine tenths of the way at θ = 0.9?"
    )
  ),
  flat = list(
    label  = "A Flat Phillips Curve",
    stage  = "3",
    values = list(theta = 0.9),
    story  = paste(
      "The probability that a firm cannot reset (θ) is raised to 0.9, which",
      "flattens the New Keynesian Phillips curve, because its slope",
      "κ = α(1−θ)(1−θβ)/θ falls throughout in θ. The curve pivots about its",
      "intercept — what expectations and the cost-push shock deliver,",
      "βE<sub>t</sub>π<sub>t+1</sub> + e<sub>t</sub> — so the axes come apart:",
      "a wide move along the output gap axis (y<sub>t</sub>) now buys only a",
      "small move up or down the inflation axis (π<sub>t</sub>). The second",
      "figure reads the same fact the other way, with κ falling away as you",
      "slide right along the θ axis. How flat it gets is set by θ, scaled by",
      "the sensitivity of the desired price to output (α) and by the discount",
      "factor (β); compare the solid curve with the dashed one drawn at the",
      "other rigidity."
    ),
    prompt = paste(
      "Compare the slope at θ = 0.5 and θ = 0.9. Then ask the policy",
      "question: if the curve is this flat, how much of a recession would it",
      "take to bring inflation down two points?"
    )
  ),
  credible = list(
    label  = "A Credible Disinflation",
    stage  = "4",
    values = list(omega = 0, pi_start = 8, pi_target = 2, length = 1),
    story  = paste(
      "The central bank announces that inflation (π<sub>t</sub>) will be at",
      "its target (π* = 2) from next quarter, down from π<sub>0</sub> = 8, and",
      "is believed. The backward-looking share (ω) is 0, so nothing in the",
      "curve depends on inflation's own past: expected inflation next quarter",
      "(E<sub>t</sub>π<sub>t+1</sub>) moves the moment the announcement is",
      "made, and current inflation follows without the curve shifting at all.",
      "The two figures come apart entirely — inflation drops to the target and",
      "stays flat along the quarters axis, while every bar of the required",
      "output gap (y<sub>t</sub>) sits at exactly zero. Only ω decides whether",
      "that survives: raise it a little and the required recession appears."
    ),
    prompt = paste(
      "The required output gap is zero in every quarter. Now raise the",
      "backward-looking share a little. How quickly does the free lunch",
      "disappear?"
    )
  ),
  volcker = list(
    label  = "A Disinflation That Hurts",
    stage  = "4",
    values = list(omega = 0.85, pi_start = 12, pi_target = 3, length = 6),
    story  = paste(
      "Inflation starts at π<sub>0</sub> = 12 against a target of π* = 3, and",
      "the backward-looking share (ω) is 0.85, so most pricing is indexed or",
      "rule of thumb. Lagged inflation now sits inside the curve, so the",
      "announcement moves almost nothing on its own and the central bank has",
      "to open an output gap instead; inverting the hybrid curve for",
      "y<sub>t</sub> is what draws the bars. The axes now move together: every",
      "quarter in which inflation falls on the left figure is a quarter with",
      "output below potential on the right. The total output lost is set by ω",
      "and by the slope (κ), while the quarters allowed only redistribute it —",
      "go faster and the worst quarter deepens without the total changing",
      "much."
    ),
    prompt = paste(
      "Try bringing inflation down in two quarters instead of six. The total",
      "output lost hardly changes, but the worst quarter is far deeper. That",
      "is the whole gradualism debate in one slider."
    )
  ),
  evidence = list(
    label  = "What the Micro Data Say",
    stage  = "5",
    values = list(months = 10),
    story  = paste(
      "The probability that a firm cannot reset (θ) is no longer chosen but",
      "measured: firm-level price data give the months between price changes,",
      "set here to 10, roughly where studies land once temporary sale prices",
      "are excluded, and θ = 1 − 1/months follows. That one number fixes the",
      "slope of the Phillips curve, so moving right along the duration axis",
      "raises θ and drags the implied κ down the vertical axis, steeply at",
      "short durations and much more gently beyond a year. Whether a temporary",
      "sale counts as a price change moves the measured duration from about",
      "four months to about ten, which is most of the distance between the",
      "marked reference points. Even the longest duration here implies a",
      "steeper curve than aggregate data show; the sensitivity of the desired",
      "price to output (α) scales κ, and lowering it is the usual way that gap",
      "is closed."
    ),
    prompt = paste(
      "Slide the duration between four and twelve months and watch κ move.",
      "Then ask why macro estimates of the slope come out flatter still than",
      "even the longest duration here implies."
    )
  )
)

###### B_03_05: Controls #######################################################
# Note: One entry per numeric control: label (HTML), slider range and step,
#   and the stage from which it appears.

B_03_05_controls_lst <- list(
  theta     = list(label = "Share Who Cannot Reset (θ)",
                   min = 0.05, max = 0.95, step = 0.05, from = 1),
  beta      = list(label = "Discount Factor (β)",
                   min = 0.9, max = 1, step = 0.01, from = 1),
  alpha     = list(label = "Sensitivity of the Optimal Price (α)",
                   min = 0.05, max = 1, step = 0.05, from = 1),
  pi_expect = list(label = "Expected Inflation Next Period (E π)",
                   min = -2, max = 10, step = 0.5, from = 3),
  y_gap     = list(label = "The Output Gap (y)",
                   min = -8, max = 8, step = 0.5, from = 3),
  shock     = list(label = "Cost-Push Shock (e)",
                   min = -4, max = 4, step = 0.25, from = 3),
  omega     = list(label = "Backward-Looking Share (ω)",
                   min = 0, max = 1, step = 0.05, from = 4),
  pi_start  = list(label = "Inflation Before (π<sub>0</sub>)",
                   min = 0, max = 20, step = 0.5, from = 4),
  pi_target = list(label = "The Target (π*)",
                   min = 0, max = 6, step = 0.5, from = 4),
  length    = list(label = "Quarters to Bring It Down",
                   min = 1, max = 20, step = 1, from = 4),
  n_periods = list(label = "Quarters Drawn",
                   min = 12, max = 60, step = 4, from = 4),
  months    = list(label = "Months Between Price Changes",
                   min = 2, max = 24, step = 1, from = 5)
)

###### B_03_06: Parameter Explanations #########################################
# Note: What each control is and what raising it does.

B_03_06_help_lst <- list(
  theta = paste(
    "The probability that a firm is stuck with its price this quarter. It",
    "is the whole of nominal rigidity in one number: a price lasts",
    "1/(1−θ) quarters on average."
  ),
  beta = paste(
    "How the firm discounts the future when picking a price it may be stuck",
    "with. It also discounts expected inflation in the Phillips curve."
  ),
  alpha = paste(
    "How much the price a firm would like to charge rises with the output",
    "gap: real marginal cost is procyclical. It scales the slope of the",
    "Phillips curve directly."
  ),
  pi_expect = paste(
    "What firms expect inflation to be next period. In the New Keynesian",
    "curve it is expected FUTURE inflation that matters, not past inflation,",
    "which is what makes credibility so powerful."
  ),
  y_gap = "Output relative to potential, in per cent.",
  shock = paste(
    "A cost-push shock: something that raises the price firms want to charge",
    "at any level of output, such as energy. It shifts the curve up."
  ),
  omega = paste(
    "The share of pricing that looks backwards rather than forwards, either",
    "rule of thumb or indexation. At 0 the curve is purely forward-looking",
    "and disinflation is free; at 1 it is the old accelerationist curve."
  ),
  pi_start = "Where inflation is when the central bank starts.",
  pi_target = "Where the central bank wants it.",
  length = paste(
    "How quickly the announced path brings inflation down. Cold turkey is 1",
    "quarter; gradualism is many. It changes the shape of the recession much",
    "more than its total size."
  ),
  n_periods = "How many quarters of the path are drawn.",
  months = paste(
    "How long a price lasts in the firm-level data. This is the number the",
    "micro evidence actually measures, and it pins down θ: the two are the",
    "same fact stated two ways."
  )
)

###### B_03_07: Prompts ########################################################
# Note: One "what to try" prompt per stage, shown above the figures.

B_03_07_prompts_lst <- list(
  "1" = paste(
    "A firm that resets today is picking a price it may be stuck with for",
    "years, so it sets a weighted average of the prices it would want over",
    "that whole time. Raise the rigidity and watch the weights stretch",
    "further into the future."
  ),
  "2" = paste(
    "Everyone wants the same higher price, but only 1 − θ of firms can move",
    "each quarter. The price level closes the same fraction of the gap every",
    "quarter, so it approaches the new level geometrically and never quite",
    "jumps."
  ),
  "3" = paste(
    "Move the rigidity and watch the Phillips curve pivot. The slope is",
    "κ = α(1−θ)(1−θβ)/θ, which falls as θ rises: this is part (d) of the",
    "exam question, and the whole reason a flat curve is a policy problem."
  ),
  "4" = paste(
    "Start with no backward-looking pricing: the announcement alone does the",
    "job and the required recession is zero. Then raise ω and watch the",
    "recession appear. Credibility is worth exactly the difference."
  ),
  "5" = paste(
    "Set the duration to four months, then to twelve, and watch κ change by",
    "a factor of several. Whether temporary sale prices count as price",
    "changes turns out to matter for the slope of the Phillips curve."
  )
)

###### B_03_08: The Model, Stage by Stage ######################################
# Note: The equations panel. "versions" maps the stage a form first applies
#   to its LaTeX; the panel shows the latest version at the chosen stage.

B_03_08_equations_lst <- list(

  # --- The model's equations --------------------------------------------------
  list(
    group = "model", label = "The Loss Function",
    versions = list("1" = paste0("\\min_{z_t} \\sum_{k=0}^{\\infty}",
                                 " (\\theta\\beta)^k E_t (z_t -",
                                 " p^*_{t+k})^2")),
    notes = list(
      "1" = paste("The firm dislikes being away from the price it would",
                  "charge if it were free, and weights each future period by",
                  "the chance it is still stuck with today's price.")
    )
  ),
  list(
    group = "model", label = "The Reset Price",
    versions = list("1" = paste0("z_t = (1 - \\theta\\beta) \\sum_{k=0}^",
                                 "{\\infty} (\\theta\\beta)^k E_t",
                                 " p^*_{t+k}")),
    notes = list(
      "1" = paste("A weighted average of the optimal prices the firm expects",
                  "over the life of the price. The weights sum to one.")
    )
  ),
  list(
    group = "model", label = "The Optimal Price",
    versions = list("1" = "p^*_t = p_t + \\alpha y_t + u_t"),
    notes = list(
      "1" = paste("What the firm would charge if it were free: the price",
                  "level, plus a mark-up on real marginal cost, which rises",
                  "with output.")
    )
  ),
  list(
    group = "model", label = "The Price Level",
    versions = list("2" = "p_t = \\theta p_{t-1} + (1-\\theta) z_t"),
    notes = list(
      "2" = paste("A share θ of prices are last period's; the rest are the",
                  "new one. Nothing else is needed to get stickiness at the",
                  "aggregate level.")
    )
  ),
  list(
    group = "model", label = "Inflation",
    versions = list("2" = "\\pi_t = p_t - p_{t-1}"),
    notes = list(
      "2" = "Inflation is the speed of the creep, not the size of the gap."
    )
  ),

  # --- Assumptions ------------------------------------------------------------
  list(
    group = "assumption", label = "Random Resetting",
    versions = list("1" = "\\Pr(\\text{stuck}) = \\theta \\text{ each period}"),
    notes = list(
      "1" = paste("Whether a firm can move is unrelated to how far its price",
                  "is from where it wants it. Convenient, and the main thing",
                  "menu-cost models fix.")
    )
  ),
  list(
    group = "assumption", label = "Quadratic Loss",
    versions = list("1" = "\\text{loss} \\propto (z_t - p^*)^2"),
    notes = list(
      "1" = paste("A second-order approximation to the firm's profit",
                  "function around the optimum. It makes the reset price a",
                  "simple average.")
    )
  ),
  list(
    group = "assumption", label = "Rational Expectations",
    versions = list("3" = "E_t \\text{ uses all information at } t"),
    notes = list(
      "3" = paste("Firms are not systematically wrong. Combined with",
                  "forward-looking pricing, this is what makes a credible",
                  "announcement move inflation on its own.")
    )
  ),
  list(
    group = "assumption", label = "No Indexation",
    versions = list(
      "3" = "\\text{stuck prices do not move at all}",
      "4" = "\\text{a share } \\omega \\text{ is indexed or rule of thumb}"
    ),
    notes = list(
      "3" = paste("A firm that cannot reset keeps exactly its old price."),
      "4" = paste("Relaxing this adds lagged inflation to the curve, and it",
                  "is what the data seem to need.")
    )
  ),

  # --- Solved forms -----------------------------------------------------------
  list(
    group = "solved", label = "Expected Duration",
    versions = list("1" = "\\frac{1}{1-\\theta}"),
    notes = list(
      "1" = paste("How long a price lasts. The one thing in the model that",
                  "firm-level data measure directly.")
    )
  ),
  list(
    group = "solved", label = "The Price Level Path",
    versions = list("2" = paste0("p_t - p^* = \\theta^t (p_0 - p^*)")),
    notes = list(
      "2" = paste("The gap closes by a factor θ each period, so adjustment",
                  "is geometric and never quite complete.")
    )
  ),
  list(
    group = "solved", label = "The Phillips Curve",
    versions = list(
      "3" = "\\pi_t = \\beta E_t \\pi_{t+1} + \\kappa y_t + e_t",
      "4" = paste0("\\pi_t = \\omega \\pi_{t-1} + (1-\\omega)\\beta E_t",
                   "\\pi_{t+1} + \\kappa y_t")
    ),
    notes = list(
      "3" = paste("Inflation today depends on inflation expected tomorrow,",
                  "not on inflation yesterday. That is the break with the",
                  "old accelerationist curve, and everything about policy",
                  "follows from it."),
      "4" = paste("The hybrid version. ω is the share of pricing that is",
                  "backward-looking, and it is what makes disinflation",
                  "costly.")
    )
  ),
  list(
    group = "solved", label = "The Slope",
    versions = list("3" = paste0("\\kappa = \\frac{\\alpha(1-\\theta)",
                                 "(1-\\theta\\beta)}{\\theta}")),
    notes = list(
      "3" = paste("Decreasing in θ. This is part (d) of the exam question:",
                  "more rigidity means a flatter curve, so output moves",
                  "inflation less.")
    )
  ),
  list(
    group = "solved", label = "The Sacrifice Ratio",
    versions = list(
      "4" = "\\omega = 0:\\ 0",
      "5" = "\\omega = 1:\\ \\tfrac{1}{\\kappa}"
    ),
    notes = list(
      "4" = paste("With purely forward-looking pricing a credible",
                  "announcement costs nothing at all."),
      "5" = paste("With purely backward-looking pricing the cost is the",
                  "inverse of the slope, whatever speed the central bank",
                  "chooses. A flat curve is therefore expensive to fight",
                  "inflation on.")
    )
  ),

  # --- Descriptors ------------------------------------------------------------
  list(
    group = "descriptor", label = "What Policy Should Do",
    versions = list("3" = "\\text{anchor } E_t\\pi_{t+1}"),
    notes = list(
      "3" = paste("Because only expected future inflation enters, a central",
                  "bank that can move expectations has already done most of",
                  "the work. Credibility is not a nicety here, it is the",
                  "instrument.")
    )
  ),
  list(
    group = "descriptor", label = "The Econometric Problem",
    versions = list("4" = paste0("\\pi_t = a\\pi_{t-1} + b\\,\\text{slack}",
                                 " + \\varepsilon")),
    notes = list(
      "4" = paste("The regression people actually run puts LAGGED inflation",
                  "on the right-hand side. The New Keynesian curve says the",
                  "true driver is EXPECTED inflation, so lagged inflation is",
                  "standing in for it, and the coefficient will shift",
                  "whenever the policy regime does. That is the Lucas",
                  "critique applied to the Phillips curve.")
    )
  ),
  list(
    group = "descriptor", label = "Micro Against Macro",
    versions = list("5" = "\\kappa^{micro} \\gg \\kappa^{macro}"),
    notes = list(
      "5" = paste("Price durations in firm-level data imply a much steeper",
                  "curve than aggregate data show. Strategic complementarity",
                  "and real rigidities are the usual reconciliation: a firm",
                  "that can reset still does not move far, because its",
                  "competitors have not.")
    )
  )
)

###### B_03_09: Equation Group Titles ##########################################
# Note: Group headings in the equations tabs.

B_03_09_groups_vec <- c(
  model      = "Model Equations",
  assumption = "Assumptions",
  solved     = "Solved Forms",
  descriptor = "Descriptors"
)

###### B_03_10: Notation Key ###################################################
# Note: Every symbol in the equations, with its group and first stage.

B_03_10_notation_lst <- list(
  list(grp = "var", sym = "z_t", txt = "the price a resetting firm chooses",
       from = 1),
  list(grp = "var", sym = "p^*_t", txt = "the price it would charge if free",
       from = 1),
  list(grp = "par", sym = "\\theta", txt = "share who cannot reset", from = 1),
  list(grp = "par", sym = "\\beta", txt = "discount factor", from = 1),
  list(grp = "par", sym = "\\alpha",
       txt = "sensitivity of the optimal price to output", from = 1),
  list(grp = "var", sym = "p_t", txt = "the price level", from = 2),
  list(grp = "var", sym = "\\pi_t", txt = "inflation", from = 2),
  list(grp = "var", sym = "y_t", txt = "the output gap", from = 3),
  list(grp = "par", sym = "\\kappa", txt = "slope of the Phillips curve",
       from = 3),
  list(grp = "var", sym = "e_t", txt = "cost-push shock", from = 3),
  list(grp = "par", sym = "\\omega", txt = "backward-looking share", from = 4),
  list(grp = "flw", sym = "\\pi^*", txt = "the inflation target", from = 4),
  list(grp = "flw", sym = "\\text{SR}", txt = "the sacrifice ratio", from = 4)
)

###### B_03_11: Notation Columns ###############################################
# Note: How the notation tab is split into columns.

B_03_11_nota_cols_lst <- list(
  "Variables"  = "var",
  "Parameters" = "par",
  "Policy"     = "flw"
)

###### B_03_12: Figure Height ##################################################
# Note: Height of each figure in the browser.

B_03_12_tall_chr <- "400px"

###### B_03_13: Recalculation Delay ############################################
# Note: Milliseconds to wait for further changes before recalculating.

B_03_13_debounce_ms_int <- 250L

###### B_03_14: Version ########################################################
# Note: Semantic version, shown in the footer; CHANGELOG.md has the history.

B_03_14_version_chr <- "1.0.8"

###### B_03_15: Source Repository ##############################################
# Note: The GitHub repo, linked from the footer.

B_03_15_repo_chr <- paste0("https://github.com/Sam-Deegan/",
                        "Interactive-Model-Calvo-NKPC")

#### B_04: Paths ###############################################################
# Note: The QR code only.

###### B_04_01: QR Code Source #################################################
# Note: The QR image: www/ if present, else the toolkit's own copy.

B_04_01_qr_src_chr <- T_07_04_qr_fn()

################################################################################
## D: Plots ####################################################################
################################################################################
# Note: Builders only; each returns a ggplot for the server to draw. Figure
#   conventions follow CONVENTIONS.md 6.

#### D_01: The Firm and the Price Level ########################################
# Note: Where the stickiness comes from.

###### D_01_01: How Far Ahead the Firm Looks ###################################
# Note: The weights on each future period in the reset price, with their
#   cumulative sum and the effective horizon 1 / (1 - theta beta).

D_01_01_weights_fn <- function(par, ref = NULL) {
  df <- C_01_02_weights_fn(par, 16)
  df$half <- cumsum(df$weight)
  # Effective horizon, a resting point; drawn only when it is on the panel
  horizon <- 1 / (1 - par$theta * par$beta)
  on_view <- horizon <= 16
  lab_k   <- if (horizon > 9) 5L else 13L

  # Fixed limits, shared with coord_cartesian and the label angle
  x_lim <- c(-0.6, 16.6)
  y_lim <- c(0, 1.15)

  # Slope of the cumulative line at the label's k, by central difference
  i_lab <- which(df$ahead == lab_k)
  i_lo  <- max(1L, i_lab - 1L)
  i_hi  <- min(nrow(df), i_lab + 1L)
  slope <- (df$half[i_hi] - df$half[i_lo]) /
    (df$ahead[i_hi] - df$ahead[i_lo])

  # Ghost: the cumulative line at the reference settings, drawn first
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    gdf <- C_01_02_weights_fn(ref, 16)
    gdf$half <- cumsum(gdf$weight)
    T_02_03a_ghost_line_fn(gdf, aes(x = ahead, y = half),
                           colour = T_01_02_series_vec[["main"]],
                           linewidth = 1)
  }

  ggplot(df, aes(x = ahead, y = weight)) +
    T_02_02_rest_fn(h = 1, v = if (on_view) horizon else NULL) +
    ghost_lyr +
    geom_col(width = 0.7, fill = T_01_02_series_vec[["band"]]) +
    geom_line(aes(y = half), colour = T_01_02_series_vec[["main"]],
              linewidth = 1) +
    # Name the cumulative line along its slope, lifted clear of it
    annotate("text", x = lab_k, y = df$half[i_lab],
             angle = T_02_01a_angle_fn(slope, x_lim, y_lim),
             hjust = 0.5, vjust = -1.15, size = 3.4,
             colour = T_01_02_series_vec[["main"]],
             label = "cumulative weight") +
    T_02_02_mark_y_fn(1, expression(sum(weights) == 1)) +
    (if (on_view) {
      T_02_02_mark_x_fn(horizon, expression(1 / (1 - theta * beta)))
    }) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    labs(
      title = paste0("Weights in the Reset Price: one lasts ",
                     T_02_05_num_fn(C_01_01_duration_fn(par), 1),
                     " quarters"),
      x = expression(bold("Quarters ahead (" * k * ")")),
      y = expression(bold("Weight in the reset price (" * z[t] * ")")),
      caption = paste0(
        "The firm sets a weighted average of the prices it would want over",
        " the life of this one. Weights are (1 − θβ)(θβ)^k and sum to one."
      )
    ) +
    T_02_01_theme_fn() +
    theme(aspect.ratio = 2 / 3)
}

###### D_01_02: The Price Level Creeps #########################################
# Note: The price level after a one-off rise in p*; only 1 - theta of firms
#   move each quarter.

D_01_02_creep_fn <- function(par, ref = NULL) {
  df <- C_01_05_price_fn(par, 24, size = 1)

  # Ghost: the creep at the reference rigidity, drawn first
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    T_02_03a_ghost_line_fn(C_01_05_price_fn(ref, 24, size = 1),
                           aes(x = period, y = price),
                           colour = T_01_02_series_vec[["main"]],
                           linewidth = 1.1)
  }

  ggplot(df, aes(x = period)) +
    # Zero is the pre-shock price level; p* is the resting point
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = 1) +
    ghost_lyr +
    geom_line(aes(y = price), colour = T_01_02_series_vec[["main"]],
              linewidth = 1.1) +
    geom_col(aes(y = c(price[1], diff(price))),
             fill = T_01_02_series_vec[["band"]], width = 0.6, alpha = 0.8) +
    T_02_02_mark_y_fn(c(0, 1), expression(p[0], p^"*")) +
    coord_cartesian(ylim = c(0, 1.12)) +
    labs(
      title = "The Price Level Creeps, It Does Not Jump",
      x = expression(bold("Quarters since the shock (" * t * ")")),
      y = expression(bold("Price level (" * p[t] * ")")),
      caption = paste0(
        "Bars are inflation each quarter; the line is the price level. Each",
        " quarter closes 1 − θ = ", T_02_05_num_fn(1 - par$theta, 2),
        " of the gap that is left, so a share θ of it survives."
      )
    ) +
    T_02_01_theme_fn()
}

#### D_02: The Phillips Curve ##################################################
# Note: The slope, and what sets it.

###### D_02_01: The Curve ######################################################
# Note: Inflation against the output gap, at the current rigidity and at a
#   comparison rigidity, so the pivot is visible.

D_02_01_curve_fn <- function(par, ref = NULL) {
  grid  <- seq(-8, 8, length.out = 200)
  other <- if (par$theta >= 0.75) 0.5 else 0.9
  now   <- C_01_06_curve_fn(par, grid)
  alt   <- C_01_06_curve_fn(modifyList(par, list(theta = other)), grid)
  kap     <- C_01_03_kappa_fn(par)
  kap_alt <- C_01_03_kappa_fn(modifyList(par, list(theta = other)))
  # Intercept at a closed output gap; the curve pivots about it
  anchor <- par$beta * par$pi_expect + par$shock

  long <- rbind(
    data.frame(y = now$y, pi = now$pi,
               line = paste0("θ = ", T_02_05_num_fn(par$theta, 2))),
    data.frame(y = alt$y, pi = alt$pi,
               line = paste0("θ = ", T_02_05_num_fn(other, 2)))
  )
  long$line <- factor(long$line, levels = unique(long$line))

  # Fixed limits, shared with coord_cartesian and the equation angle
  x_lim <- c(-8, 8)
  y_rng <- range(c(long$pi, 0, anchor + kap * par$y_gap))
  y_lim <- y_rng + c(-1, 1) * 0.08 * diff(y_rng)
  # Put the equation on the side where the live curve is the outer one
  x_lab <- if (kap > kap_alt) 3.5 else -3.5

  # Ghost: the live curve and its point at the reference settings
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    g_kap <- C_01_03_kappa_fn(ref)
    g_anc <- ref$beta * ref$pi_expect + ref$shock
    list(
      T_02_03a_ghost_line_fn(C_01_06_curve_fn(ref, grid),
                             aes(x = y, y = pi),
                             colour = T_01_02_series_vec[["main"]],
                             linewidth = 1.1),
      T_02_03a_ghost_point_fn(ref$y_gap, g_anc + g_kap * ref$y_gap,
                              colour = T_01_02_series_vec[["main"]])
    )
  }

  ggplot(long, aes(x = y, y = pi, colour = line, linetype = line)) +
    T_02_02_zero_fn() +
    T_02_02_rest_fn(h = anchor) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    T_02_03_point_fn(par$y_gap, anchor + kap * par$y_gap) +
    scale_colour_manual(values = stats::setNames(
      c(T_01_02_series_vec[["main"]], T_01_02_series_vec[["compare"]]),
      levels(long$line))) +
    scale_linetype_manual(values = stats::setNames(
      c("solid", "22"), levels(long$line))) +
    T_02_02_mark_y_fn(anchor, expression(beta * E[t] * pi[t + 1] + e[t])) +
    T_02_02_mark_x_fn(0, expression(y[t] == 0)) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    annotate("text", x = x_lab, y = anchor + kap * x_lab,
             angle = T_02_01a_angle_fn(kap, x_lim, y_lim),
             label = paste0("'NKPC:  '*pi[t] == beta * E[t] * pi[t+1] + ",
                            "kappa * y[t] + e[t]"),
             parse = TRUE, size = 3.2, hjust = 0.5, vjust = -1.15,
             colour = T_01_01_palette_vec[["muted"]]) +
    labs(
      title = paste0("New Keynesian Phillips Curve (NKPC): κ = ",
                     T_02_05_num_fn(kap, 3)),
      x = expression(bold("Output gap (" * y[t] * ")")),
      y = expression(bold("Inflation (" * pi[t] * ")")),
      caption = paste(
        "Both in per cent. The intercept is what expectations deliver; the",
        "slope is κ. Stickier prices pivot the curve flatter."
      )
    ) +
    T_02_01_theme_fn(grid = "none") +
    theme(aspect.ratio = 2 / 3)
}

###### D_02_02: The Slope Against Rigidity #####################################
# Note: kappa against theta, the answer to part (d) of question 3 of the
#   2023 paper.

D_02_02_slope_fn <- function(par, ref = NULL) {
  df  <- C_01_04_slope_fn(par, 300)
  now <- C_01_03_kappa_fn(par)

  # Ghost: the schedule and its point at the reference settings
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    list(
      T_02_03a_ghost_line_fn(C_01_04_slope_fn(ref, 300),
                             aes(x = theta, y = kappa),
                             colour = T_01_02_series_vec[["main"]],
                             linewidth = 1.1),
      T_02_03a_ghost_point_fn(ref$theta, C_01_03_kappa_fn(ref),
                              colour = T_01_02_series_vec[["main"]])
    )
  }

  ggplot(df, aes(x = theta, y = kappa)) +
    # The rigidity in force and the slope it implies, on opposite axes
    T_02_02_rest_fn(h = now, v = par$theta) +
    ghost_lyr +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    T_02_03_point_fn(par$theta, now) +
    T_02_02_mark_x_fn(par$theta, expression(theta)) +
    T_02_02_mark_y_fn(now, expression(kappa)) +
    coord_cartesian(ylim = c(0, stats::quantile(df$kappa, 0.9))) +
    labs(
      title = "Slope of the New Keynesian Phillips Curve (NKPC)",
      x = expression(bold("Share who cannot reset (" * theta * ")")),
      y = expression(bold("Slope of the Phillips curve (" * kappa * ")")),
      caption = paste(
        "κ = α(1−θ)(1−θβ)/θ, falling in θ throughout. The vertical scale is",
        "trimmed at the top, where near-flexible prices send κ to infinity."
      )
    ) +
    T_02_01_theme_fn()
}

#### D_03: Disinflation and the Evidence #######################################
# Note: What a central bank has to do, and what the data say about theta.

###### D_03_01: The Announced Path #############################################
# Note: Inflation coming down, and the recession the model says it takes.

D_03_01_path_fn <- function(par, ref = NULL) {
  df <- C_01_07_disinflation_fn(par)

  # Ghost: the path announced at the reference settings, drawn first
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    T_02_03a_ghost_line_fn(C_01_07_disinflation_fn(ref),
                           aes(x = period, y = inflation),
                           colour = T_01_02_series_vec[["main"]],
                           linewidth = 1.2)
  }

  ggplot(df, aes(x = period)) +
    # The target is a resting point: dotted, named on the right axis
    T_02_02_rest_fn(h = par$pi_target) +
    ghost_lyr +
    geom_line(aes(y = inflation), colour = T_01_02_series_vec[["main"]],
              linewidth = 1.2) +
    T_02_02_mark_y_fn(par$pi_target, expression(pi^"*")) +
    labs(
      title = "The Inflation Path the Central Bank Announces",
      x = expression(bold("Quarter (" * t * ")")),
      y = expression(bold("Inflation (" * pi[t] * ")")),
      caption = paste0("From ", T_02_05_num_fn(par$pi_start, 1),
                       "% to ", T_02_05_num_fn(par$pi_target, 1),
                       "% over ", round(par$length), " quarters.")
    ) +
    T_02_01_theme_fn()
}

###### D_03_02: The Recession It Takes #########################################
# Note: The output gap the model says is needed to deliver that path. With
#   no backward-looking pricing every bar is zero.

D_03_02_gap_fn <- function(par, ref = NULL) {
  df  <- C_01_07_disinflation_fn(par)
  sac <- C_01_08_sacrifice_fn(par)
  free <- max(abs(df$gap)) < 1e-9

  # Ghost: a path along the tops of the reference bars, in their colour
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    gdf <- C_01_07_disinflation_fn(ref)
    T_02_03a_ghost_path_fn(
      gdf, aes(x = period, y = gap), linewidth = 1.1,
      colour = if (max(abs(gdf$gap)) < 1e-9) {
        T_01_01_palette_vec[["green"]]
      } else {
        T_01_01_palette_vec[["navy"]]
      })
  }

  ggplot(df, aes(x = period, y = gap)) +
    # A closed output gap is the resting point the bars are read against
    T_02_02_rest_fn(h = 0) +
    ghost_lyr +
    geom_col(width = 0.7,
             fill = if (free) T_01_01_palette_vec[["green"]] else
               T_01_01_palette_vec[["navy"]]) +
    T_02_02_mark_y_fn(0, expression(y[t] == 0)) +
    labs(
      title = if (free) {
        "No recession at all: the announcement does the whole job"
      } else {
        paste0("Sacrifice Ratio (SR) ", T_02_05_num_fn(sac$ratio, 1),
               ": ", T_02_05_num_fn(sac$loss, 1),
               " points of output for ", T_02_05_num_fn(sac$fall, 1),
               " of inflation")
      },
      x = expression(bold("Quarter (" * t * ")")),
      y = expression(bold("Output gap required (" * y[t] * ")")),
      caption = if (free) {
        paste("With purely forward-looking pricing, a credible announcement",
              "moves expectations and inflation follows for free.")
      } else {
        paste0("Worst quarter: ", T_02_05_num_fn(sac$worst, 1),
               " per cent. Going slower spreads the same total loss over",
               " more quarters.")
      }
    ) +
    T_02_01_theme_fn()
}

###### D_03_03: Durations and the Slope ########################################
# Note: What the micro evidence implies for kappa, with the range the
#   literature spans marked.

D_03_03_micro_fn <- function(par, evidence, ref = NULL) {
  months <- seq(2, 24, by = 0.25)
  df     <- C_01_09_micro_fn(par, months)
  ev     <- C_01_09_micro_fn(par, evidence$months)
  ev$label <- evidence$label
  # Labels on alternate sides of their points; left of a point sits below it
  ev$hj  <- ifelse(seq_len(nrow(ev)) %% 2 == 1, -0.08, 1.08)
  ev$vj  <- ifelse(seq_len(nrow(ev)) %% 2 == 1, -1.1, 1.7)
  now    <- C_01_09_micro_fn(par, par$months)

  # Ghost: the mapping and its point at the reference settings
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    g_now <- C_01_09_micro_fn(ref, ref$months)
    list(
      T_02_03a_ghost_line_fn(C_01_09_micro_fn(ref, months),
                             aes(x = months, y = kappa),
                             colour = T_01_02_series_vec[["main"]],
                             linewidth = 1.1),
      T_02_03a_ghost_point_fn(ref$months, g_now$kappa,
                              colour = T_01_02_series_vec[["main"]])
    )
  }

  ggplot(df, aes(x = months, y = kappa)) +
    # The duration in force and the theta and kappa it implies, on opposite axes
    T_02_02_rest_fn(h = now$kappa, v = par$months) +
    ghost_lyr +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    geom_point(data = ev, aes(x = months, y = kappa),
               colour = T_01_02_series_vec[["compare"]], size = 3) +
    geom_text(data = ev, aes(x = months, y = kappa, label = label),
              hjust = ev$hj, vjust = ev$vj, size = 3.6,
              colour = T_01_02_series_vec[["compare"]]) +
    T_02_03_point_fn(par$months, now$kappa) +
    T_02_02_mark_x_fn(
      par$months,
      as.expression(bquote(theta == .(T_02_05_num_fn(now$theta, 2))))) +
    T_02_02_mark_y_fn(now$kappa, expression(kappa)) +
    coord_cartesian(ylim = c(0, max(ev$kappa) * 2.2)) +
    labs(
      title = "Price Durations and the New Keynesian Phillips Curve (NKPC)",
      x = expression(bold("Months between price changes (" * 1 / (1 - theta) *
                            ")")),
      y = expression(bold("Implied slope (" * kappa * ")")),
      caption = paste(
        "Rounded reference points, not precise estimates: studies differ",
        "mainly on whether temporary sale prices count as price changes."
      )
    ) +
    T_02_01_theme_fn()
}

################################################################################
## E: User Interface ###########################################################
################################################################################
# Note: bslib page: controls in a sidebar, figures in cards.

#### E_01: Sidebar #############################################################
# Note: Stage selector, then the controls. The sidebar chooses the model;
#   the main window chooses what to run in it (CONVENTIONS.md 1).

###### E_01_01: Control Shorthand ##############################################
# Note: Label with tooltip, slider and a box for an exact value, from the
#   toolkit; saves passing the same three lists at every call.

E_01_01_ctl_fn <- function(id) {
  T_03_01_control_fn(id, B_03_05_controls_lst, B_03_06_help_lst,
                     B_03_01_defaults_lst)
}

###### E_01_02: Sidebar ########################################################
# Note: conditionalPanel reveals controls as the stages add layers.

E_01_02_sidebar_lst <- sidebar(
  width = 380,
  radioButtons("stage", "Stage of the Model",
               choices = B_03_02_stages_vec, selected = "1"),
  T_03_05_note_fn(paste(
    "Each stage adds one piece to the model and leaves the rest",
    "alone. Start at the top; the equations panel marks what is new.")),
  accordion(
    open = c("Pricing"),
    accordion_panel(
      "Pricing",
      E_01_01_ctl_fn("theta"),
      E_01_01_ctl_fn("alpha"),
      E_01_01_ctl_fn("beta"),
      conditionalPanel("parseFloat(input.stage) >= 5",
                       tags$h6("From the Data"),
                       E_01_01_ctl_fn("months"))
    ),
    accordion_panel(
      "The Phillips Curve",
      conditionalPanel(
        "parseFloat(input.stage) >= 3",
        E_01_01_ctl_fn("pi_expect"),
        E_01_01_ctl_fn("y_gap"),
        E_01_01_ctl_fn("shock")
      ),
      conditionalPanel("parseFloat(input.stage) < 3",
                       tags$p(class = "stat-caption",
                              "The Phillips curve appears at stage 3."))
    ),
    accordion_panel(
      "Disinflation",
      conditionalPanel(
        "parseFloat(input.stage) >= 4",
        E_01_01_ctl_fn("omega"),
        E_01_01_ctl_fn("pi_start"),
        E_01_01_ctl_fn("pi_target"),
        E_01_01_ctl_fn("length"),
        E_01_01_ctl_fn("n_periods")
      ),
      conditionalPanel("parseFloat(input.stage) < 4",
                       tags$p(class = "stat-caption",
                              "Policy appears at stage 4."))
    )
  ),
  actionButton("reset", "Reset Everything",
               class = "btn-outline-secondary btn-sm w-100"),
  T_07_10b_sidebarqr_fn(B_04_01_qr_src_chr)
)

#### E_02: Main Panel ##########################################################
# Note: Equations, worked examples, prompt, readouts, then the figures for
#   this stage.

###### E_02_01: Worked-Example Presets #########################################
# Note: Preset card for the main window, from the toolkit (T_05_04 to
#   T_05_07). Only the current stage's presets show.

E_02_01_presets_lst <- T_05_04_presets_fn(
  B_03_04_scenarios_lst, B_03_02_stages_vec, stage_word = "Stage"
)

###### E_02_02: Page ###########################################################
# Note: The UI passed to shinyApp().

E_02_02_app_ui_lst <- tagList(
  T_07_08b_nav_fn(),
  page_sidebar(
  title        = T_07_09_title_fn("Calvo Pricing and the NKPC",
                                  B_04_01_qr_src_chr),
  window_title = paste("Calvo Pricing ·", T_07_01_author_chr),
  fillable     = FALSE,
  theme        = T_07_05_theme_fn(),
  sidebar      = E_01_02_sidebar_lst,
  T_07_08_head_fn(),
  tags$head(
    tags$style(HTML(T_05_07_preset_css_chr)),
    tags$script(HTML(T_05_05_preset_js_chr))
  ),
  navset_card_tab(
    title = textOutput("eq_title", inline = TRUE),
    nav_panel("Equations", uiOutput("eq_model")),
    nav_panel("Notation", uiOutput("eq_notation")),
    nav_panel("In Words", uiOutput("eq_explain"))
  ),
  E_02_01_presets_lst,
  uiOutput("prompt"),
  uiOutput("problems"),
  uiOutput("tiles"),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(6, 6)),
    T_07_07c_figcard_fn("weights", "How Far Ahead a Resetting Firm Looks",
                          B_03_12_tall_chr),
    conditionalPanel(
      "parseFloat(input.stage) >= 2",
      T_07_07c_figcard_fn("creep", "The Price Level After a Shock",
                          B_03_12_tall_chr)
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 3",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("curve", "The Phillips Curve",
                          B_03_12_tall_chr),
      T_07_07c_figcard_fn("slope", "The Slope Against Rigidity",
                          B_03_12_tall_chr)
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 4",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("path", "The Announced Path",
                          B_03_12_tall_chr),
      T_07_07c_figcard_fn("gap", "The Recession It Takes",
                          B_03_12_tall_chr)
    ),
    uiOutput("policy_note")
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 5",
    card(
      card_header("From Price Durations to the Slope"),
      plotOutput("micro", height = B_03_12_tall_chr),
      uiOutput("micro_note")
    )
  ),
  T_07_11_footer_fn(paste0("Notation follows question 3 of the 2023 paper.",
                           " Version ", B_03_14_version_chr, "."),
                    repo = B_03_15_repo_chr),
))

################################################################################
## F: Server ###################################################################
################################################################################
# Note: Assembles the stage's parameters, solves the model, draws.

#### F_01: Server Function #####################################################
# Note: Everything reactive lives here.

###### F_01_01: Server #########################################################
# Note: Local objects are plain snake_case.

F_01_01_app_server_fn <- function(input, output, session) {

  # --- Figure captions --------------------------------------------------------
  # Captions come out of the device in T_02_01c_draw_fn; this prints them
  T_07_07d_cap_fn(output)

  # --- Stage as a number ------------------------------------------------------
  stage_num <- reactive(as.numeric(input$stage))

  # --- Controls ---------------------------------------------------------------
  val <- function(id) T_03_04_val_fn(input, id)
  T_03_02_sync_fn(input, session, B_03_05_controls_lst)

  set_control <- function(id, value) {
    T_03_03_set_fn(session, B_03_05_controls_lst, id, value)
  }

  apply_values <- function(values) {
    for (id in names(values)) {
      if (!is.null(B_03_05_controls_lst[[id]])) set_control(id, values[[id]])
    }
    invisible(NULL)
  }

  # --- Worked-example presets -------------------------------------------------
  # Buttons exist for every stage from the start, so their ids are stable
  scenario <- reactiveVal(names(B_03_04_scenarios_lst)[1])

  # The loaded scenario, or NULL when none is loaded
  scn_now <- reactive({
    k <- scenario()
    if (is.null(k) || !k %in% names(B_03_04_scenarios_lst)) NULL
    else B_03_04_scenarios_lst[[k]]
  })

  # Sets the loaded preset and marks its button
  set_scenario_fn <- function(key) {
    scenario(if (is.null(key)) "custom" else key)
    session$sendCustomMessage("dgPreset", if (is.null(key)) "" else key)
    invisible(NULL)
  }

  load_preset_fn <- function(key) {
    if (is.null(key) || !key %in% names(B_03_04_scenarios_lst)) {
      return(invisible(NULL))
    }
    scn <- B_03_04_scenarios_lst[[key]]
    set_scenario_fn(key)
    apply_values(utils::modifyList(B_03_01_defaults_lst, scn$values))
    invisible(NULL)
  }

  lapply(names(B_03_04_scenarios_lst), function(key) {
    observeEvent(input[[paste0("preset_", key)]],
                 load_preset_fn(key), ignoreInit = TRUE)
  })

  # First scenario belonging to a stage, or NULL
  first_preset_fn <- function(stage) {
    hits <- names(B_03_04_scenarios_lst)[vapply(
      B_03_04_scenarios_lst, function(x) identical(x$stage, stage), TRUE)]
    if (length(hits) == 0L) NULL else hits[[1L]]
  }

  # Each stage opens on its first worked example
  observeEvent(input$stage, {
    first <- first_preset_fn(input$stage)
    if (!is.null(first)) {
      load_preset_fn(first)
      return()
    }
    set_scenario_fn(NULL)
  })

  output$preset_title <- renderUI({
    T_05_06_preset_title_fn(scn_now(), input$stage, B_03_02_stages_vec,
                            stage_word = "")
  })

  # --- Reset ------------------------------------------------------------------
  observeEvent(input$reset, {
    apply_values(B_03_01_defaults_lst)
    set_scenario_fn(NULL)
  })

  # --- Parameters in force at this stage --------------------------------------
  # Stage gates on the control values; at stage 5 theta comes from months
  # Pure in v and s, so the ghost is built through the same gates
  assemble_fn <- function(v, s) {
    months <- v$months
    list(
      theta     = if (s >= 5) 1 - 1 / max(months, 1.01) else v$theta,
      beta      = v$beta,
      alpha     = v$alpha,
      pi_expect = if (s >= 3) v$pi_expect else 0,
      y_gap     = if (s >= 3) v$y_gap else 0,
      shock     = if (s >= 3) v$shock else 0,
      omega     = if (s >= 4) v$omega else 0,
      pi_start  = v$pi_start,
      pi_target = v$pi_target,
      length    = round(v$length),
      n_periods = round(v$n_periods),
      months    = months
    )
  }

  par_raw <- reactive({
    req(!is.null(input$theta))
    vals <- stats::setNames(lapply(names(B_03_01_defaults_lst), val),
                            names(B_03_01_defaults_lst))
    assemble_fn(vals, stage_num())
  })

  par_now  <- debounce(par_raw, B_03_13_debounce_ms_int)
  diag_now <- reactive(C_01_10_diagnostics_fn(par_now()))
  ok_now   <- reactive(length(diag_now()$problems) == 0)

  # --- The ghost: every figure at the reference settings ----------------------
  # Reference values: the loaded example's, else the defaults
  ref_vals <- reactive({
    key <- scenario()
    if (is.null(key) || !key %in% names(B_03_04_scenarios_lst)) {
      return(B_03_01_defaults_lst)
    }
    utils::modifyList(B_03_01_defaults_lst,
                      B_03_04_scenarios_lst[[key]]$values)
  })

  # NULL when there is nothing to compare, or the reference would not draw
  ghost_par <- reactive({
    ref <- assemble_fn(ref_vals(), stage_num())
    if (T_02_03b_ghost_off_fn(par_now(), ref)) return(NULL)
    if (length(C_01_11_problems_fn(ref)) > 0) return(NULL)
    ref
  })

  # --- Scenario story ---------------------------------------------------------
  output$scenario_story <- renderUI({
    T_05_02_story_fn(scn_now(), B_03_05_controls_lst, B_03_06_help_lst)
  })

  # --- The model so far -------------------------------------------------------
  output$eq_title <- renderText({
    T_05_04_stage_name_fn(B_03_02_stages_vec, input$stage)
  })

  eq_items <- reactive(T_06_03_items_fn(B_03_08_equations_lst, stage_num()))

  output$eq_model <- renderUI({
    T_06_04_model_fn(eq_items(), B_03_09_groups_vec,
                     "These appear as the later stages add to the model.")
  })

  output$eq_notation <- renderUI({
    T_06_05_notation_fn(B_03_10_notation_lst, stage_num(),
                        B_03_11_nota_cols_lst, first_stage = 1)
  })

  output$eq_explain <- renderUI({
    T_06_06_explain_fn(eq_items(), B_03_09_groups_vec)
  })

  # --- Prompt and problems ----------------------------------------------------
  output$prompt <- renderUI({
    T_07_12_prompt_fn(scn_now(), input$stage, B_03_07_prompts_lst)
  })

  output$problems <- renderUI(T_07_13_problems_fn(diag_now()$problems))

  # --- Readouts ---------------------------------------------------------------
  output$tiles <- renderUI({
    d <- diag_now()
    s <- stage_num()
    T_04_03_row_fn(
      T_04_01_tile_fn(
        "A price lasts", paste0(T_02_05_num_fn(d$duration, 1), " quarters"),
        paste0(T_02_06_pct_fn(d$reset, 0), " of firms reset each quarter")
      ),
      T_04_01_tile_fn(
        "Effective horizon", paste0(T_02_05_num_fn(d$horizon, 1), " quarters"),
        "How far ahead the resetting firm looks"
      ),
      if (s >= 3) {
        T_04_01_tile_fn(
          "Slope of the curve, κ", T_02_05_num_fn(d$kappa, 3),
          if (isTRUE(d$kappa < 0.05)) {
            "Very flat: output moves inflation little"
          } else {
            "Output moves inflation"
          }
        )
      },
      if (s >= 3) {
        T_04_01_tile_fn(
          "Inflation at this gap", T_02_06_pct_fn(d$pi_now / 100, 2),
          paste0("At an output gap of ",
                 T_02_05_num_fn(par_now()$y_gap, 1), "%")
        )
      },
      if (s >= 4) {
        local({
          free <- isTRUE(abs(d$sacrifice) < 1e-9)
          T_04_01_tile_fn(
            "Sacrifice ratio",
            if (!is.finite(d$sacrifice)) "—" else
              if (free) "0" else T_02_05_num_fn(d$sacrifice, 1),
            if (free) "Credible and free" else
              if (isTRUE(d$sacrifice < 0)) {
                "Negative: this path needs a boom, not a recession"
              } else {
                "Output points per point of inflation"
              },
            class = if (free) "good" else if (is.finite(d$sacrifice)) "bad"
                    else ""
          )
        })
      },
      if (s >= 5) {
        T_04_01_tile_fn(
          "Implied θ", T_02_05_num_fn(par_now()$theta, 3),
          paste0("From ", round(par_now()$months), " months between changes")
        )
      }
    )
  })

  # --- Figures ----------------------------------------------------------------
  output$weights <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_01_weights_fn(par_now(), ref = ghost_par())
  }) })

  output$creep <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 2)
    D_01_02_creep_fn(par_now(), ref = ghost_par())
  }) })

  output$curve <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 3)
    D_02_01_curve_fn(par_now(), ref = ghost_par())
  }) })

  output$slope <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 3)
    D_02_02_slope_fn(par_now(), ref = ghost_par())
  }) })

  output$path <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_03_01_path_fn(par_now(), ref = ghost_par())
  }) })

  output$gap <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_03_02_gap_fn(par_now(), ref = ghost_par())
  }) })

  output$micro <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 5)
    D_03_03_micro_fn(par_now(), B_03_03_evidence_df, ref = ghost_par())
  }) })

  output$policy_note <- renderUI({
    req(stage_num() >= 4)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "What the Curve Says About Policy"),
      tags$p(HTML(paste(
        "Only expected future inflation enters the pure curve, so a central",
        "bank that can move expectations disinflates without opening a gap.",
        "Set the backward-looking share to zero and every bar on the right",
        "is empty. Announcing a slow glide instead does worse: the required",
        "gap turns positive, because the bank must run the economy hot to",
        "keep inflation as high as it promised, and the sacrifice ratio goes",
        "negative. With forward-looking pricing there is no reason to go",
        "slowly."
      ))),
      tags$p(HTML(paste(
        "Real disinflations cost output, so this is too strong. The usual",
        "repair is the hybrid curve: a share of prices is indexed or set by",
        "rule of thumb, which puts lagged inflation back in and the recession",
        "with it. It also explains why regressions of inflation on its own",
        "lags and slack are not structural. Lagged inflation is standing in",
        "for expected inflation, so the coefficients change when the",
        "monetary regime changes. That is the Lucas critique, and it is why",
        "the 1970s curve broke down."
      )))
    )
  })

  output$micro_note <- renderUI({
    req(stage_num() >= 5)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "Reading the Firm-Level Evidence"),
      tags$p(HTML(paste(
        "Scanner and price-collection data give the frequency with which an",
        "individual price changes. That is 1 − θ, so the micro evidence pins",
        "down the one parameter the model turns on. The studies disagree",
        "mainly over temporary sales that revert to the old price. Counting",
        "them makes prices look far more flexible; excluding them roughly",
        "doubles the implied duration and so roughly halves κ."
      ))),
      tags$p(HTML(paste(
        "Even the longest durations here imply a steeper curve than",
        "aggregate data show. The usual reconciliation is strategic",
        "complementarity: a firm that can reset moves only part of the way",
        "because its competitors are stuck. Real rigidities do the work that",
        "nominal rigidity alone cannot."
      )))
    )
  })
}

################################################################################
## G: Run ######################################################################
################################################################################
# Note: Launch.

#### G_01: Launch ##############################################################
# Note: Returns the app object.

###### G_01_01: The App ########################################################
# Note: UI from E, server from F.

G_01_01_app_lst <- shinyApp(E_02_02_app_ui_lst, F_01_01_app_server_fn)

G_01_01_app_lst

#--------------------------------- Script End ---------------------------------#
