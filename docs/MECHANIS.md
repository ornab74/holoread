# Mechanis Recommendation Engine

Mechanis is an explainable local ranking system. It does not require a remote model and never uploads private notes or history.

## Candidate selection

Completed, abandoned, archived, and deleted records are excluded. Wishlist, planned, current, paused, and re-reading records remain eligible.

## Signals

Each candidate receives normalized signals for priority, genre and author affinity, length fit, difficulty fit, series continuity, goal alignment, novelty, completion likelihood, and negative history. Recommendation modes adjust signal weights without changing the core scoring model.

## Score

The weighted signal average is mapped to a 0–100 score. Negative history reduces the score. A diversity pass limits excessive repetition of the same author or primary genre.

## Explainability

The strongest positive signals are converted into a sentence attached to every recommendation. The interface also exposes each high-value signal as a percentage chip.

## Extension points

A future embedding provider should implement a separate service and contribute an additional normalized signal. It must remain optional, local-first, and explainable.
