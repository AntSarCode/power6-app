# Power6 30-Day Launch Push

## Positioning
Power6 is a daily execution system for busy professionals who need a short, trusted plan instead of another endless task list.

Core message: choose the six things that matter today, finish with focus, and build momentum from real progress.

## Weekly Execution
- Week 1: update App Store screenshots, title/subtitle, landing page copy, and subscription value language.
- Week 2: publish three short posts about six-task focus, daily review, and streak-building; ask early users for one quote each.
- Week 3: contact 20-30 professionals, coaches, freelancers, and small business operators for feedback and testimonials.
- Week 4: run a $25-$50 Apple Search Ads keyword test only after screenshots and copy are updated.

Execution assets:
- App Store copy: `docs/app_store_metadata_0_1_2.md`
- Organic calendar: `docs/organic_launch_calendar.md`
- Outreach tracker: `docs/outreach_and_testimonials.md`

## Organic Content Prompts
- "What would change if your task list stopped at six?"
- "The daily review habit that keeps unfinished work from becoming guilt."
- "A productivity streak should reward finished work, not app opens."

## Outreach Script
Hi [Name], I launched Power6, a focused daily planning app built around choosing and completing six meaningful tasks. I am collecting feedback from busy professionals who manage a lot of moving pieces. Would you be open to trying it for a few days and sending one thing that felt useful and one thing that felt confusing?

## App Store Copy Notes
- Subtitle: Six-task daily focus
- Keywords to test: daily planner, task focus, streak, productivity, priority planner
- Screenshot sequence: six-slot plan, dashboard progress, streak/badges, Pro timeline insights, subscription tiers

## Metrics
Track installs, signup conversion, first task created, six tasks created, task completion, 3-day retention, subscription screen visits, checkout starts, and purchases.

## Funnel Review
After the backend with event tracking is deployed, review the launch funnel at least twice per week.

Admin endpoint:

```text
GET /events/summary?days=30
Authorization: Bearer <admin token>
```

Read the funnel in this order:

- `signup_completed`: new account activation.
- `onboarding_started`: new users reached first-run education.
- `dashboard_viewed`: users landed in the core app surface.
- `task_created`: users started the six-task workflow.
- `task_completed`: users reached the first value moment.
- `subscription_screen_viewed`: users inspected paid value.
- `checkout_started`: users showed purchase intent.

If signups are healthy but task creation is low, improve onboarding and empty states. If task completion is healthy but subscription views are low, add better upgrade prompts after streak and insight moments. If subscription views are healthy but checkout starts are low, revise tier copy, screenshots, pricing presentation, and Pro feature clarity.
