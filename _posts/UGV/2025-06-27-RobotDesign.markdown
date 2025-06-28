---
layout: default
title: Robot Design
seo_h1: Robot Design
date: 2025-06-03 00:29:02 +0530
categories: software-design
tags: [Deep Learning, Computer Vision, Robotics]
description: Robot Design
published: false
---
![alt text](robot_collage.png)

Below is a **practical recipe for building a four-BLDC-wheel chassis that matches the frame you showed**—while keeping every one of your project-goal pillars (navigation accuracy, obstacle avoidance, power telemetry, safety, modularity) in mind.

---

## 1. Wheel-module concept

1. **Hub motor choice**

   * Pick 10- to 12-inch e-scooter hub motors in the 350 – 500 W, 36–48 V class.
   * They are gearless, sealed, and already have axle mounts that bolt cleanly into 30 × 30 mm aluminium extrusion corners.
   * A typical 48 V / 500 W unit delivers ≈ 12 N·m stall torque and cruises at 18–22 km h⁻¹ on a 16-inch rim—ample for a 60–80 kg robot. ([amazon.com][1], [cnkunray.com][2])

2. **Independent steering fork** (what you see in the photo)

   * Each hub motor sits in a **U-shaped fork** made from 8 mm aluminium plate.
   * The fork pivots on a 20 mm shoulder bolt or tapered roller bearing; a small timing-belt loop couples that pivot to a **NEMA-23 closed-loop step-servo** (or a 60 kg·cm robot servo) mounted just above.
   * An **absolute magnetic encoder** on the steering shaft gives 0.1 ° repeatability so your controller always knows wheel azimuth—even after power-cycle.

3. **Why this layout fits your goals**

   * Four individually driven, individually steered wheels unlock **crab, point-turn, and standard Ackermann** modes for tight row-turn manoeuvres (Navigation & Path-Planning goal).
   * Redundant steering encoders + motor phase sensors satisfy the **fail-safe** and **minimum-clearance** requirements; you can disable a wheel and still limp home.

---

## 2. Motor control electronics

| Layer            | Recommended part                                                  | Rationale                                                                                                                                           |
| ---------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Drive ESC**    | **VESC-6 class controller** per wheel                             | Field-Oriented Control, regenerative braking, and **native CAN-bus** daisy-chain; proven in robotics. ([vesc-project.com][3], [vedder.se][4])       |
| **Steer servo**  | Closed-loop NEMA-23 step-servo (e.g., JMC iHSV57-30-18-36)        | 180 W peak, CANopen or RS-485, holds torque at stand-still without hunting.                                                                         |
| **Bus topology** | One CAN-FD loop for all four VESCs **plus** the four steer servos | Gives you <2 ms time-sync’d velocity + steering feedback for model-predictive control, and leaves your SBC Ethernet/Wi-Fi free for perception data. |

Connection sketch

```
  Jetson Orin Nano  ↔  STM32/Teensy safety MCU ↔  CAN-FD backbone
                                             ├─ VESC 1 (drive)
                                             ├─ VESC 2
                                             ├─ VESC 3
                                             ├─ VESC 4
                                             ├─ Servo 1 (steer)
                                             ├─ Servo 2
                                             ├─ Servo 3
                                             └─ Servo 4
```

The safety MCU monitors VESC current, IMU shock events, and a dead-man heartbeat from ROS 2; loss of heartbeat opens the HV relay—meeting your **fail-safe mechanism** requirement.

---

## 3. Frame & suspension

* **30 × 30 mm or 40 × 40 mm T-slot aluminium extrusion** rectangle (1 × 0.8 m is comfortable for agro-implements).
* Cross-braces at mid-height double as mounting rails for the Orin Nano, battery BMS, and LiDAR mast.
* Optional **rubber isolators** under each wheel fork if you foresee rough terrain; keep travel small (≤ 30 mm) so depth cameras maintain calibration.

---

## 4. Power train

| Component          | Spec                                                       |
| ------------------ | ---------------------------------------------------------- |
| **Battery**        | 48 V 20 Ah LiFePO₄, ≤ 20 kg, 1 kWh for \~3 h mixed duty    |
| **Main contactor** | 60 V 150 A, normally-open, driven by safety MCU            |
| **DC-DC rails**    | 48 → 12 V 20 A for servos & sensors; 12 → 5 V 10 A for SBC |

A **Victron SmartShunt** or smart BMS publishes SoC over UART/CAN so ROS 2 can satisfy your **real-time battery monitoring** and **power-consumption optimisation** goals.

---

## 5. Control software stack (high-level)

1. **Low-level package**

   * `ros2_control` + `ros2_control_boards` (CAN-FD) driver exposing each wheel as a **swerve\_steer\_joint** (position) and **swerve\_drive\_joint** (velocity).
   * Safety MCU exposes battery, contactor, and E-stop as standard `sensor_msgs/State` topics.

2. **Mid-level**

   * **nav2** with a **Holonomic / Swerve kinematics plugin** for hybrid A\* global path and Timed-Elastic-Band local planner.
   * **Depth Fusion**: RTAB-Map or VSLAM → OctoMap / TSDF.

3. **Perception**

   * Jetson Orin Nano runs YOLOv8-m at \~55 FPS 640 × 640 on TensorRT, feeding a `costmap_2d` layer that inflates dynamic obstacles for **collision prediction & prevention**.

---

## 6. Build steps in order

1. **Assemble one fork module** (hub + steering servo) and bench-test with VESC Tool to verify phase ID, hall sensors, and steering PID.
2. **Stack four modules onto the extrusion frame**; run open-loop skid-steer first to confirm CAN IDs and traction-control sync.
3. **Add absolute encoders**, switch controllers to closed-loop swerve mode; test remote tele-op.
4. **Integrate perception sensors** (LiDAR + depth camera) and bring up SLAM in sim first (Gazebo/Isaac), then on-robot.
5. **Tune power limits & regen** in VESC so decelerations feed energy back into the battery without tripping the BMS.
6. **Hook in safety MCU watchdog**; pull the E-stop for a hard cut and confirm all four wheels torque-off within ≤ 100 ms.

---

### Why this particular recipe is “best” for your goals

* **Modularity:** each wheel is a self-contained module—easy to replace or upgrade.
* **Scalability:** higher-power hub motors or different wheel diameters swap in without redesigning the frame.
* **Reliability & Safety:** hardware E-stop, dual-power rails, MCU watchdogs, and CAN time-sync satisfy the safety & cybersecurity pillars.
* **Energy efficiency:** LiFePO₄ + regen + adaptive power limits hit your power-management objectives.
* **Future attachments:** the flat deck inside the frame lets you bolt seed-drills, sprayers, or sensor booms without touching the locomotion stack.

Let me know if you’d like CAD sketches, wiring diagrams, or BOM line items for any of the subsystems—I can zoom in on whichever detail will unblock your next build step.

[1]: https://www.amazon.com/Electric-Scooter-Brushless-Gearless-Conversion/dp/B0DHKFRDRX?utm_source=chatgpt.com "12 Inch Electric Scooter Hub Motor Wheel 48V 500W Brushless ..."
[2]: https://cnkunray.com/products/kunray-12inch-scooter-hub-motor-wheel-48v-500w-brushless-non-gear-motor-36v-350w-electric-bike-scooter-motor-kit?utm_source=chatgpt.com "KUNRAY 12inch Scooter Hub Motor Wheel 48V 500W Brushless ..."
[3]: https://vesc-project.com/?utm_source=chatgpt.com "VESC Project"
[4]: https://vedder.se/2015/01/vesc-open-source-esc/comment-page-2/?utm_source=chatgpt.com "VESC – Open Source ESC | Benjamin's robotics"
