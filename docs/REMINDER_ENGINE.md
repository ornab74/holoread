# Adaptive Reminder Engine

The engine selects the highest-value active reading target, favoring currently-reading books and priority.

It estimates the preferred reading hour from prior sessions for that book. Without history, it uses the configured preferred hour. It then moves the reminder outside quiet hours and ensures it is not scheduled immediately in the past.

Observed pages per minute estimate how much progress a normal daily session could produce. The notification explains the proposed session duration, projected pages, and remaining pages. Confidence rises as more session history becomes available.

Delivery is separated from reasoning. The engine can be unit-tested without notification plugins, while `NotificationService` owns permissions and platform scheduling.
