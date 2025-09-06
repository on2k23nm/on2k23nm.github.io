---
layout: default
title: "Singleton"
seo_h1: "Singleton"
date: 2025-09-06 09:44:19 +0530
categories: design-patterns
tags: [Design Patterns, cpp]
mathjax: true
description: "--TBD--"
published: false
placement_prio: 1
pinned: false
---

# One Truth for Time: A Safe Singleton Clock in an AV Stack

In the world of autonomous vehicles (AV), where a nanosecond can mean the difference between a seamless experience and a jarring glitch, we've learned that accurate timekeeping is not a luxury—it's a critical requirement. We've all faced the chaos that ensues from a system where different components keep their own time.

We once struggled with a bug in a multi-camera calibration system where, during a replay of logged data, the frames from different cameras would fall out of sync. A mix of clock sources—from the standard `system_clock` to the more specialized Precision Time Protocol (PTP)—led to divergent timelines, causing `sim` and bag replay to fail and triggering the dreaded "planner spikes". These weren't just minor bugs; they were the symptoms of a fractured timekeeping architecture. Instead of a tangled web of time sources, we realized we needed **one truth for time**.

The physical reality of our system, with a single, authoritative time source dictated by hardware, demanded a singular, defensible solution. We addressed this fundamental problem by creating a robust, thread-safe **Clock Singleton**. This was not just a convenient hack, but a critical piece of our system's core architecture.

This blog post isn't a theoretical tutorial on the singleton pattern. It's a practitioner’s account of how we tackled a real-world problem. We'll share our experience in designing a Clock Singleton that is configured once, frozen, and then becomes a read-only, allocation-free, lock-free source of truth for time across our entire application. This approach stabilized our replay systems, eliminated nondeterministic bugs, and simplified incident debugging. Join us as we break down our pragmatic solution for taming time in a complex autonomous vehicle environment.

## Thesis

In one AV process, time must have a single authority. We stabilized replay and removed rare planner spikes by introducing a **configure-then-freeze** Clock Singleton—created in the composition root, read-only thereafter.

## Mental model

* **Unique by physics, not convenience.** If reality enforces one (time source, GPU context), Singleton is defensible.
* **Configure, then freeze.** All writes at startup; hot path is read-only and allocation-free.

## The pain (before)

Mixed `system_clock`/`steady_clock`/PTP across modules; sim and bag replay diverged; occasional PTP step caused watchdog trips and nondeterministic fusion.

## The design (after)

* `IClock` interface + `Clock::Instance()` (Meyers).
* `Clock::configure(ClockConfig)` callable exactly once before first `now()`.
* Strategies chosen at configure: `WallClock | PTPClock | SimClock | BagClock`.
* No destructor (intentional leak) to avoid shutdown races; one definition in a core `.so`.

## Minimal API contract

`now() noexcept`, `source() noexcept`; no setters post-configure; hot path lock-free and allocation-free.

## Lifecycle (composition root)

Parse `--time=` flags → build `ClockConfig` → `Clock::configure(...)` → load plugins → run. Any use before configure fails fast with clear diagnostics.

## Testing & determinism

Replay the same bag → identical timestamps; TSAN clean with heavy concurrent `now()`; `TestClockScope` (tests only) can swap a fake clock, restores on scope exit.

## Ops & safeguards

Startup log prints chosen source and first tick; metrics for `now()` latency and PTP sync state. Guards against multiple instances across DSOs; reconfigure in production is fatal.

## What changed

Planner spikes disappeared; bag replays became bit-stable; cross-module logs aligned—simpler incident debugging.

## C++17 notes to show later (no code now)

Meyers singleton + `std::call_once` for configure, strategy objects, `std::chrono` strong types, linkage hygiene to prevent per-DSO duplicates.
