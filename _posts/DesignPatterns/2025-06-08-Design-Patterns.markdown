---
layout: default
title: "A Practitioner's Notes on Software Design Patterns"
seo_h1: "A Practitioner's Notes on Software Design Patterns"
date: 2025-09-03 08:27:34 +0530
categories: design-patterns
tags: [Design Patterns, cpp]
mathjax: true
description: A collection of personal notes and practical examples for implementing core software design patterns in C++. Serves as a reference for their structure, common use cases, and trade-offs.
published: false
placement_prio: 0
pinned: false
---
### Core Problem in Software Development

The fundamental challenge in software engineering evolves from simply creating code that produces a correct output (*making the code work*) to engineering systems that possess long-term viability. This transition introduces three critical, non-functional requirements:

* **Maintainability**: The ease with which a software system or component can be modified to correct faults, improve performance, or adapt to a changed environment. A maintainable system is characterized by low coupling (modules are independent) and high cohesion (elements within a module are closely related in function). The primary objective is to minimize the cost and risk associated with future changes.
* **Scalability**: The capability of a system, network, or process to handle a growing amount of work, or its potential to be enlarged to accommodate that growth. This is not merely about performance under a current load but about the architectural soundness to support increased load (e.g., users, data volume, transaction frequency) without a significant drop in performance or a need for complete redesign.
* **Understandability**: The degree to which the source code can be comprehended by a developer who was not its original author. This is a function of clarity, code structure, consistency, and documentation. Code that is not understandable is inherently difficult to maintain, debug, and extend.

### Software Design Patterns

A **Software Design Pattern** is a generalized, reusable, and proven solution to a commonly occurring problem within a given context in software design. It is not a finished piece of code or a specific algorithm, but rather a high-level description or template that outlines how to structure classes and objects to solve a general design problem.

The _essence of a design pattern is to provide a common vocabulary and a standardized approach to solving recurring architectural challenges_. This moves development from an ad-hoc, apprentice-level approach to a structured, craftsman-like methodology.

A pattern can be deconstructed into four essential components:

1.  **Pattern Name**: A handle used to describe a design problem, its solutions, and consequences in a few words.
2.  **Problem**: Describes the specific issue to be solved and the context in which it occurs.
3.  **Solution**: Describes the constituent elements of the design (classes, objects, interfaces), their relationships, responsibilities, and collaborations. This is the abstract template.
4.  **Consequences**: The results and trade-offs of applying the pattern. These are critical for evaluating design alternatives and understanding the costs and benefits of a particular pattern. For example, a pattern might improve extensibility at the cost of increased complexity.

### From Implementation to Architecture

The journey from a junior developer to a software architect is a conceptual shift from focusing on local, immediate problems to considering the global, long-term health of the system.

* **Junior Developer/Apprentice Mindset**: The primary focus is on implementing features to meet functional requirements. Solutions are often specific to the immediate problem at hand, without necessarily considering how they fit into the larger system or how they will be modified in the future.
* **Software Architect Mindset**: The focus expands to include the system's structure and its non-functional qualities. The goal is to identify recurring problems and apply well-established patterns that have known properties and consequences. This involves thinking in terms of abstractions, interfaces, and component interactions to build a resilient and evolvable system.

### Why These Notes Exist

I’ve structured these notes to be a distilled, practical reference based on my own studies and experience. My goal for this collection is threefold:

* **Clarity**: I've tried to present these concepts in a way that is unambiguous and helps build a solid mental model of how each pattern works.
* **Reuse**: The knowledge of patterns is inherently reusable. Once you understand a pattern's template, you can apply it across different projects and technologies.
* **Long-term Reference**: This isn’t just for a one-time read. I've written this to be a reliable guide that I—and hopefully you—can consult when faced with a tough design challenge in the future.

### Fundamental Concept of Design Patterns

At its core, a **software design pattern** is a reusable, high-level blueprint for a solution to a commonly recurring design problem. It is not a finished algorithm or a piece of plug-and-play code, but rather a proven strategy and architectural template that can be adapted to a unique situation. The primary purpose of a design pattern is to provide a standardized solution and a common vocabulary for architectural challenges.

The formalization of these concepts originated with the 1994 book, *“Design Patterns: Elements of Reusable Object-Oriented Software.”* Its authors—Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides, now known as the **“Gang of Four” (GoF)**—distilled their experience into 23 foundational patterns. These patterns are structured into three classical categories.

### Part 1: Creational Design Patterns

Creational patterns are concerned with the process of **object instantiation**. They provide mechanisms to create objects in a controlled way, which increases system flexibility and decouples the client from the specific classes being instantiated.

* **Factory Method**: This pattern provides an interface for creating an object but defers the choice of which class to instantiate to its subclasses. It is used when a class cannot anticipate the exact type of objects it needs to create.
* **[Abstract Factory](../../09/03/Design-Patterns-Abstract-Factory.html)**: This pattern provides an interface for creating **families of related or dependent objects** without specifying their concrete classes. It is often used for providing platform-specific toolkits, such as a UI toolkit that needs to create a set of widgets for either Windows or macOS.
* **Builder**: This pattern separates the construction of a complex object from its representation, allowing the same construction process to create different variations of the object. It is ideal for objects that require multiple configuration steps, like a complex database query or a detailed user profile.
* **Singleton**: This pattern ensures that a class has only one instance and provides a single, global point of access to it.
* **Prototype**: This pattern allows for the creation of new objects by copying an existing object, known as a "prototype." This avoids a dependency on the concrete classes of the objects being created and is particularly efficient when the cost of creating an object from scratch is high.

### Part 2: Structural Design Patterns

Structural patterns focus on how to assemble objects and classes into larger structures while maintaining the flexibility and efficiency of these structures. They simplify the relationships between entities.

* **Adapter**: This pattern acts as a bridge between two incompatible interfaces, allowing them to collaborate. It is fundamentally a "translator" used to make legacy code work with modern classes or to integrate third-party libraries with different interface conventions.
* **Decorator**: This pattern allows for adding new functionality to an object dynamically without altering its class definition. It works by wrapping the original object in a special "decorator" class that adds the new behaviors.
* **Facade**: This pattern provides a simplified, high-level interface to a large and complex subsystem (like a library or framework). It acts as a "front desk," making the complex system easier to use by hiding its internal complexity.
* **Composite**: This pattern composes objects into tree-like structures to represent part-whole hierarchies. It allows clients to treat individual objects and compositions of objects uniformly. It is essential for structures like file systems or organizational charts.
* **Proxy**: This pattern provides a surrogate or placeholder for another object to control access to it. A Proxy object represents the real object and is used to manage tasks such as lazy initialization (virtual proxy), access control (protection proxy), or logging.

### Part 3: Behavioral Design Patterns

Behavioral patterns are concerned with effective communication, collaboration, and the assignment of responsibilities between objects.

* **Strategy**: This pattern defines a family of interchangeable algorithms, encapsulates each one in a separate class, and makes their objects interchangeable. It is used when a system needs to provide different variants of an algorithm, such as different payment, shipping, or sorting strategies.
* **Observer**: This pattern defines a subscription mechanism to notify multiple objects about any events that happen to the object they are "observing." It is the foundation of modern event-driven programming and is analogous to following a user on social media.
* **Command**: This pattern turns a request into a stand-alone object that contains all information about the request. This allows for the parameterization of clients with different requests, the queuing or logging of requests, and the support of undoable operations.
* **State**: This pattern allows an object to alter its behavior when its internal state changes. The object appears to change its class. It is a powerful tool for managing the lifecycle of an object with distinct states, such as an order (Pending, Shipped, Delivered).
* **Template Method**: This pattern defines the skeleton of an algorithm in a base class but lets subclasses override specific steps of the algorithm without changing its overall structure. It is a classic pattern for reducing code duplication while allowing for customization.

### A Starting Point

My approach for each pattern in these notes is to provide a clear explanation, a practical C++ implementation, and a discussion on its appropriate use cases—and just as importantly, when to avoid it.

I'm starting this collection with a deep-dive into **The Factory Method pattern**. [**The Factory Method pattern**](./Design-Patterns-Factory-Method.html). Let's begin!