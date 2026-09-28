################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Calvo Pricing and the New Keynesian Phillips Curve: Model                  ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Sourced automatically by app.R. Can be sourced alone from a lecture
##   .qmd so slide figures come from the same model:
##     source("R/model.R")
##
## Inputs:
##   None. Every function is a pure function of a parameter list "par".
##
## Outputs:
##   C_01_* functions: durations, reset weights, the slope, the price level
##   path, the Phillips curve, a disinflation and its sacrifice ratio.
##
## The model (Calvo 1983; Romer 2019 ch. 7), in the notation of question 3
## of the 2023 ECON42550 paper:
##   Each period a firm may reset its price with probability 1 - theta, so
##   theta is the degree of nominal rigidity and a price lasts 1/(1-theta)
##   periods on average.
##
##   A firm that can reset chooses the log price z_t to minimise
##       sum_k (theta beta)^k E_t (z_t - p*_{t+k})^2
##   which gives
##       z_t = (1 - theta beta) sum_k (theta beta)^k E_t p*_{t+k},
##   a weighted average of the optimal price it expects over the life of the
##   price it is setting.
##
##   The optimal flexible price depends on the price level, output and a
##   cost-push shock:
##       p*_t = p_t + alpha y_t + u_t.
##
##   The aggregate price level is a weighted average of last period's and
##   the new one:
##       p_t = theta p_{t-1} + (1 - theta) z_t.
##
##   Putting these together gives the New Keynesian Phillips curve
##       pi_t = beta E_t pi_{t+1} + kappa y_t + e_t,
##       kappa = alpha (1 - theta)(1 - theta beta) / theta,
##   so the slope is decreasing in theta: the stickier prices are, the less
##   inflation responds to output. That is part (d) of the exam question.
##
##   The hybrid version adds a backward-looking share omega (Romer 2019
##   ch. 7, staggered price adjustment with inflation inertia):
##       pi_t = omega pi_{t-1} + (1 - omega) beta E_t pi_{t+1} + kappa y_t.
##
## Parameter list (par) elements:
##   theta, beta, alpha, pi_expect, y_gap, shock, omega, pi_start,
##   pi_target, length, n_periods, months

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C_01 holds the model; app.R holds sections B, D, E, F and G.
#
#   C: Model
#     C_01_01  Expected price duration
#     C_01_02  Reset weights
#     C_01_03  The slope of the Phillips curve
#     C_01_04  The slope across rigidity
#     C_01_05  The price level after a shock
#     C_01_06  The Phillips curve
#     C_01_07  A disinflation
#     C_01_08  The sacrifice ratio
#     C_01_09  From micro durations to the slope
#     C_01_10  Readouts
#     C_01_11  Problems with the calibration

################################################################################
## C: Model ####################################################################
################################################################################
# Note: Pure functions. Nothing here touches Shiny.

#### C_01: Pricing, the Phillips Curve and Disinflation ########################
# Note: One firm, then the price level, then inflation, then policy.

###### C_01_01: Expected Price Duration ########################################
# Note: A price survives each period with probability theta, so it lasts
#   1/(1 - theta) periods on average; the number firm-level data report.

C_01_01_duration_fn <- function(par) {
  if (par$theta >= 1) Inf else 1 / (1 - par$theta)
}

###### C_01_02: Reset Weights ##################################################
# Note: How much weight the resetting firm puts on the optimal price k
#   periods ahead. The weights are (1 - theta beta)(theta beta)^k and sum to
#   one, so the reset price is a proper average.

C_01_02_weights_fn <- function(par, k_max = 12) {
  k <- 0:k_max
  data.frame(ahead = k,
             weight = (1 - par$theta * par$beta) *
               (par$theta * par$beta)^k)
}

###### C_01_03: The Slope of the Phillips Curve ################################
# Note: kappa = alpha (1 - theta)(1 - theta beta) / theta, decreasing in
#   theta: stickier prices mean a flatter curve (Romer 2019 ch. 7).

C_01_03_kappa_fn <- function(par) {
  if (par$theta <= 0) return(Inf)
  par$alpha * (1 - par$theta) * (1 - par$theta * par$beta) / par$theta
}

###### C_01_04: The Slope Across Rigidity ######################################
# Note: kappa at every degree of rigidity, for the figure that answers part
#   (d) of question 3 of the 2023 paper.

C_01_04_slope_fn <- function(par, n = 200) {
  grid <- seq(0.05, 0.95, length.out = n)
  data.frame(
    theta = grid,
    kappa = vapply(grid, function(t) {
      C_01_03_kappa_fn(modifyList(par, list(theta = t)))
    }, 0),
    duration = 1 / (1 - grid)
  )
}

###### C_01_05: The Price Level After a Shock ##################################
# Note: A one-off permanent rise in the optimal price. Only 1 - theta of
#   firms move each period, so the price level creeps towards the new level
#   rather than jumping to it.

C_01_05_price_fn <- function(par, n = 24, size = 1) {
  p <- numeric(n)
  for (t in seq_len(n)) {
    prev <- if (t == 1) 0 else p[t - 1]
    p[t] <- par$theta * prev + (1 - par$theta) * size
  }
  data.frame(period = seq_len(n), price = p, target = size,
             gap = size - p)
}

###### C_01_06: The Phillips Curve #############################################
# Note: Inflation against the output gap, for a given expectation of next
#   period's inflation. The intercept is what expectations deliver; the
#   slope is kappa.

C_01_06_curve_fn <- function(par, y_grid) {
  kappa <- C_01_03_kappa_fn(par)
  data.frame(
    y  = y_grid,
    pi = par$beta * par$pi_expect + kappa * y_grid + par$shock
  )
}

###### C_01_07: A Disinflation #################################################
# Note: The central bank announces a path from pi_start to the target over
#   "length" periods and the model says what output gap that takes.
#   Inverting the hybrid Phillips curve (Romer 2019 ch. 7)
#     pi_t = c + omega pi_{t-1} + (1 - omega) beta pi_{t+1} + kappa y_t
#   for y_t gives the recession the announcement requires. The constant
#   c = (1 - omega)(1 - beta) pi* makes the target the steady state of the
#   equation, as writing the curve in deviations from target would; with
#   beta < 1 and no constant, steady-state inflation would be zero.

C_01_07_disinflation_fn <- function(par) {
  n      <- par$n_periods
  kappa  <- C_01_03_kappa_fn(par)
  gam_b  <- par$omega
  gam_f  <- (1 - par$omega) * par$beta
  anchor <- (1 - par$omega) * (1 - par$beta) * par$pi_target
  steps  <- max(1, min(round(par$length), n))

  # The announced path: a straight glide to the target, then flat
  glide <- par$pi_start +
    (par$pi_target - par$pi_start) * pmin(seq_len(n) / steps, 1)

  lag  <- c(par$pi_start, glide[-n])
  lead <- c(glide[-1], par$pi_target)
  gap  <- (glide - anchor - gam_b * lag - gam_f * lead) / kappa

  data.frame(period = seq_len(n), inflation = glide, gap = gap,
             target = par$pi_target)
}

###### C_01_08: The Sacrifice Ratio ############################################
# Note: Cumulative output lost per point of inflation brought down. Zero
#   with purely forward-looking pricing; 1/kappa with purely backward-looking
#   pricing, whatever the speed.

C_01_08_sacrifice_fn <- function(par) {
  path <- C_01_07_disinflation_fn(par)
  loss <- -sum(path$gap)
  fall <- par$pi_start - par$pi_target
  list(loss = loss, fall = fall,
       ratio = if (abs(fall) > 1e-9) loss / fall else NA_real_,
       worst = min(path$gap))
}

###### C_01_09: From Micro Durations to the Slope ##############################
# Note: Months between price changes pin down theta = 1 - 1/months, and
#   theta pins down kappa.

C_01_09_micro_fn <- function(par, months) {
  theta <- 1 - 1 / months
  kappa <- vapply(theta, function(t) {
    C_01_03_kappa_fn(modifyList(par, list(theta = t)))
  }, 0)
  data.frame(months = months, theta = theta, kappa = kappa)
}

###### C_01_10: Readouts #######################################################
# Note: The numbers shown in the tiles above the figures.

C_01_10_diagnostics_fn <- function(par) {
  sac <- C_01_08_sacrifice_fn(par)

  list(
    duration   = C_01_01_duration_fn(par),
    kappa      = C_01_03_kappa_fn(par),
    reset      = 1 - par$theta,
    horizon    = 1 / (1 - par$theta * par$beta),
    pi_now     = par$beta * par$pi_expect + C_01_03_kappa_fn(par) * par$y_gap +
      par$shock,
    loss       = sac$loss,
    fall       = sac$fall,
    sacrifice  = sac$ratio,
    forward    = par$omega < 1e-9,
    problems   = C_01_11_problems_fn(par)
  )
}

###### C_01_11: Problems with the Calibration ##################################
# Note: Warnings shown above the figures when the numbers stop making sense.

C_01_11_problems_fn <- function(par) {
  out <- character(0)

  if (isTRUE(par$theta >= 0.99)) {
    out <- c(out, paste(
      "Prices almost never change, so the Phillips curve is flat and",
      "inflation cannot be moved by output at all. Lower the rigidity."
    ))
  }
  if (isTRUE(par$theta <= 0.02)) {
    out <- c(out, paste(
      "Prices are almost fully flexible, so the Phillips curve is vertical",
      "and the model has nothing for monetary policy to do."
    ))
  }
  if (isTRUE(par$omega >= 1) && isTRUE(par$length < 1)) {
    out <- c(out, paste(
      "With purely backward-looking pricing and no output gap, inflation",
      "never comes down. Open a gap, or lower the backward-looking share."
    ))
  }
  out
}

#--------------------------------- Script End ---------------------------------#
