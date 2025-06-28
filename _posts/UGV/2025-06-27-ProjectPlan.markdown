---
layout: default
title: Project Plan
seo_h1: Project Plan
date: 2025-06-03 00:29:02 +0530
categories: software-design
tags: [Deep Learning, Computer Vision, Robotics]
description: Project Plan 
published: false
---
## Actionable Steps for the UGV Project

1. [**Project Goal**](./ProjectGoals.html)
2. [**Hardware Blueprint**](./HardwareBlueprint.html)  
3. **Software Stack**  
   - **Operating System:** Ubuntu (on your Pi/Jetson).  
   - **Robotics Framework:** ROS 2 (Humble or Iron, as per your Linux preference). Focus on writing C++ nodes.  
   - **Deep Learning Framework:** PyTorch for training (on your desktop/laptop), then ONNX Runtime or TensorRT for C++ inference on the UGV.  
   - **Computer Vision Library:** OpenCV (C++ API).

4. **Key DL/CV Aspects to Implement**  
   - **Real-time Object Detection:** Train a custom YOLO model (or use a pre-trained one) for detecting relevant objects (e.g., people, traffic cones, specific markers).  
   - **Object Tracking:** Use classical CV (e.g., Kalman Filter with object detection) or deep-learning-based trackers.  
   - **Visual Odometry/SLAM (optional, but highly impactful):** Use techniques like ORB-SLAM3 or a simpler visual-odometry pipeline to estimate the UGV’s pose.  
   - **Path Planning & Navigation:** Implement algorithms that use the CV output to plan safe paths and control the UGV’s movement. You can start with simple reactive behaviors and move toward more-complex planning.

5. **Documentation and Presentation**  
   - Create a detailed GitHub repository with clear code, a well-structured README, and demonstration videos.  
   - Write a blog series (remembering your preference for blog format!) documenting your process, challenges, and solutions, highlighting the advanced DL/CV concepts and C++/systems programming involved.

> **Outcome:**  
> This UGV project will provide a tangible, impressive demonstration of your skills, making you a very strong candidate for DL/CV roles—especially those involving robotics, autonomous systems, or edge AI. Good luck!
