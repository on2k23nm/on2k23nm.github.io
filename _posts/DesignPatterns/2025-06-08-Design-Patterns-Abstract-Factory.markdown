---
layout: default
title: "Abstract Factory Pattern: A Practitioner's Blueprint for Modular System Design"
seo_h1: "Abstract Factory Pattern: A Practitioner's Blueprint for Modular System Design"
date: 2025-09-03 08:27:07 +0530
categories: design-patterns
tags: [Design Patterns, cpp]
mathjax: true
description: "This post is a deep dive into the Abstract Factory pattern, exploring how it serves as a critical tool for improving the modularity and maintainability of autonomous vehicle software. Drawn from practical experience, these notes detail how the pattern can be used to architect systems that are robust and scalable, enabling the seamless management of entire hardware ecosystems."
published: true
placement_prio: 2
pinned: false
---
### Introduction

In complex, full-stack distributed systems, such as those found in autonomous vehicles, object creation happens everywhere. An autonomous vehicle's software needs to manage a variety of hardware components, from high-fidelity LiDARs and cameras to simple radars and IMUs. Often, these components are grouped into specific "stacks" or "suites" provided by different vendors. What happens when you need to switch from a high-resolution, long-range sensor suite to a cheaper, short-range alternative, or even a simulated environment for testing?

The **Abstract Factory** pattern dissolves this rigidity by providing a dedicated interface for creating **families of related or dependent objects** without specifying their concrete classes. This allows the high-level application logic to operate on a consistent interface, promoting flexibility and scalability. Abstract Factory is like supplier of matched parts, It’s like going to BOSCH and saying “give me a braking system kit”. You get the disc, caliper, pads — all designed to work together. 

While both the Factory Method and Abstract Factory patterns are designed to decouple client code from object creation, they operate at different levels of abstraction. The **Factory Method** is concerned with creating a **single object** (a "product"), delegating the responsibility of which specific product to instantiate to a concrete subclass. In contrast, the **Abstract Factory** is about creating an entire **family of related objects**. It provides a single interface with multiple methods, each responsible for creating a different but related product. For instance, an `ISensorSuiteFactory` would have both a `createLiDAR()` and a `createCamera()` method, ensuring that a client receives a consistent set of products from a single vendor's suite. _The key distinction is the scope of creation: a single product versus a cohesive family of products._

### The Core Problem: The Rigidity of a Fixed Sensor Stack

A fundamental challenge in developing autonomous systems is managing a diverse array of hardware. A single fleet might use different sensor stacks for various applications—a robust, high-cost suite for research, a streamlined, production-grade suite for commercial deployment, and a simulated environment for scalable testing.

When high-level perception logic directly instantiates specific hardware components, it becomes intrinsically tied to that fixed stack. Consider a team that has hard-coded its core algorithms to a specific Velodyne-HighResCamera combination:

```cpp
// High-level perception logic dependent on specific hardware
VelodyneLiDAR* lidar = new VelodyneLiDAR();
HighResCamera* camera = new HighResCamera();

// ... use the sensors to run perception
lidar->readPointCloud();
camera->captureFrame();
```

This presents an immediate problem. What happens when the company wants to deploy a new vehicle using a different, low-cost Ouster LiDAR and a standard Aptina camera? The codebase would require a risky and extensive hunt-and-replace operation across all modules that instantiate these objects. This approach makes high-level modules dependent on low-level concrete details, violating the **Dependency Inversion Principle** and creating a fragile system that is difficult to maintain, test, and scale.

### The Solution: Abstraction and Swappable Ecosystems

The **Abstract Factory** pattern solves this problem by providing a formal mechanism to manage these distinct hardware ecosystems. Instead of hard-coding `new` calls, the pattern defines a single interface for creating an entire **family of related objects** (e.g., a LiDAR and a camera) without specifying their concrete implementations. This approach delegates the responsibility of object creation to specialized factory subclasses, allowing the system to seamlessly swap between different sensor suites at runtime.

This architectural approach enables a single, core perception algorithm to run across all environments—**R&D, production, and simulation**. By simply changing the concrete factory at the application's Composition Root, the system can instantly switch from using a simulated sensor stack for offline testing to a prototype-grade stack for on-road validation, or to the final, automotive-grade production stack for customer deployment. This seamless transition is made possible because the core logic operates exclusively on abstract interfaces, completely decoupled from the underlying hardware.

### Structural Components

![alt text](/assets/images/DesignPatterns/Images/AbstractFactory/UML.png)

The pattern involves four key roles, which work together to achieve decoupling and create a cohesive hardware ecosystem.

-   **Abstract Product:** This is the interface that defines a type of product within the family. It establishes a contract for all concrete implementations of that product. In our example, `ILiDAR` would define a `readPointCloud()` method and `ICamera` would define a `captureFrame()` method. Every concrete product must implement these interfaces.
-   **Concrete Product:** This is a specific implementation of an Abstract Product. Each concrete product corresponds to a particular environment. For instance, a **Simulation** environment would use a `SimulatedLiDAR` and `SimulatedCamera`, while an **R&D** environment would use a `VelodyneLiDAR` and `HighResCamera`. In the **Production** environment, you would use final, automotive-grade components such as a `HesaiLiDAR` and `ContinentalRadar`.
-   **Abstract Factory:** This is the interface that declares a set of methods for creating each abstract product in the family. Its primary role is to ensure consistency by returning a complete, compatible set of products. Our `ISensorSuiteFactory` would have methods like `createLiDAR()` and `createCamera()`.
-   **Concrete Factory:** This is a specific implementation of the Abstract Factory. Each concrete factory is responsible for creating a specific family of products. In our case, we would have three distinct concrete factories:
    -   `SimulationSensorFactory` creates the full suite of simulated sensors.
    -   `R&DSensorFactory` creates the full suite of prototype-grade sensors.
    -   `ProductionSensorFactory` creates the final, automotive-grade sensors.

Each concrete factory knows how to instantiate a specific family of objects, ensuring that a client always receives a consistent, working set.

### Outline of our approach

![alt text](/assets/images/DesignPatterns/Images/AbstractFactory/BlockDiag.png)

Our approach to managing these distinct hardware ecosystems is rooted in a core principle: **deferring the critical decision of object creation to the last possible moment**. The system's entire configuration is decided once, at startup, in a single, centralized location—the **Composition Root**. This architectural choice ensures the rest of the application remains ignorant of low-level implementation details.

The workflow follows a clear, logical sequence:

-   **1. Runtime Configuration:** The process begins in the `main` function, where a configuration value (e.g., `"simulation"`, `"r&d"`, or `"production"`) is read from a source like a configuration file or command-line argument.
-   **2. Factory Selection:** Based on this configuration, the Composition Root instantiates the correct **Concrete Factory**. This is the only point in the entire codebase where a specific, concrete class (e.g., `SimulationSensorFactory`) is directly created.
-   **3. Dependency Injection:** The instantiated factory is then passed as a dependency to the high-level application logic, such as our `runPerception` function.
-   **4. Abstract Interaction:** The high-level function interacts with the factory solely through its abstract interface (`ISensorSuiteFactory`). It asks the factory to produce a family of abstract products (e.g., an `ILiDAR` and `ICamera`), and then uses those products via their respective abstract interfaces.

This clean separation ensures that your core perception algorithms remain unchanged and fully testable, regardless of the underlying hardware environment. The system's flexibility is now a matter of changing a single configuration value, not a rewrite of the codebase.

### Core Logic Flow in C++

Before we dive into the code, here’s the plan.   

We’ll walk through a **real Abstract Factory** implementation for the perception stack of an autonomous vehicle—where the same software must run against different sensor suites (Simulation, R\&D benches, Production hardware). You’ll see how the **composition root** (`main`) selects the environment, how a tiny **facade** (`make_factory`) hides vendor specifics, how the **abstract factory** exposes only stable interfaces (`ILiDAR`, `ICamera`), and how **concrete families** (Simulation/R\&D/Production) stay sealed inside the `.so`. By the end, you’ll understand how to swap entire hardware suites without touching perception code, keep tests deterministic, and ship a clean public API with implementation details fully encapsulated.     

# 1) What `main()` does (the composition root)    


Application `main()` function takes on a special role of the **composition root**. This is the centralized entry point where the application's dependencies are configured and tied together. Its primary job is to select and instantiate the correct **concrete factory** based on a configuration or environment setting.

```cpp
// perceptionClient.cpp (app)
#include "FactoryAPI.hpp"          // public: make_factory(Environment)
#include "ISensorSuiteFactory.hpp" // public: abstract factory
#include "ISensorProducts.hpp"     // public: abstract products

int main() {
auto factory = make_factory(Environment::Production); // no concrete names here
runPerception(*factory);                              // pass abstractions inward
}
```

In the provided code, the `main()` function handles the following steps:

1.  **Selection of the Environment:** The program decides which environment it will run in, such as `Simulation`, `RnD`, or `Production`. This choice is typically funneled through a single, small public function called a **facade**, in this case, `make_factory(Environment)`.
2.  **Factory Creation:** The `main()` function calls `make_factory()` and passes the chosen environment. This function, which lives inside a library, is the only piece of code that knows about the concrete factory classes (e.g., `SimulationSensorFactory`, `RDSensorFactory`, `ProductionSensorFactory`). The result is a `std::unique_ptr` to the abstract interface `ISensorSuiteFactory`.
3.  **Dependency Injection:** Once the abstract factory is created, `main()` passes it to the rest of the application's code, such as the `runPerception()` function. This is known as **dependency injection**, where the dependency (the factory) is "injected" into the client code rather than the client code creating it itself.

This design ensures that the high-level application logic remains decoupled from the low-level implementation details.

# 2) The facade: `make_factory` (`FactoryAPI.hpp` / `FactoryAPI.cpp`)

This is the **single public entry point** that converts a high-level choice (Simulation / RnD / Production) into a concrete factory instance, without exposing any concrete class names to the client.

#### Header (public API)

```cpp
// FactoryAPI.hpp
#pragma once
#include "ISensorSuiteFactory.hpp"
#include <memory>

enum class Environment { Simulation, RnD, Production };

// Façade: the only way clients obtain a factory   
std::unique_ptr<ISensorSuiteFactory> make_factory(Environment env);

```

#### Implementation (private, inside the .so)

```cpp
// FactoryAPI.cpp (not installed)
#include "FactoryAPI.hpp"
#include "ConcreteFactories.hpp"  // private concretes

std::unique_ptr<ISensorSuiteFactory> make_factory(Environment env) {
  switch (env) {
    case Environment::Simulation: return std::make_unique<SimulationSensorFactory>();
    case Environment::RnD:        return std::make_unique<RDSensorFactory>();
    case Environment::Production: return std::make_unique<ProductionSensorFactory>();
  }
  return {}; // or throw, or log + fallback
}
```

Facade presents one tiny function to a complex subsystem; clients depend on *this*, not on internals. It acts as a **Single point of truth**, the only place that knows concrete types and ensures a **matched family** (LiDAR + Camera) is chosen. Public headers remain pure interfaces; concrete classes can change freely. Returns `std::unique_ptr<ISensorSuiteFactory>` so lifetime is clear and safe across ABI boundaries. Adding a new environment (e.g., `Environment::HIL`) touches only this switch and the new concrete factory - _client code stays the same_.


# 3) What the “client code” uses (no concretes)    


Client code, often deep inside an application (e.g., the “perception subsystem”) - depends **only** on the **abstract product interfaces**. _It neither knows nor cares who made the objects or which vendor they came from. Creation is someone else’s problem._

#### The function as a factory client

`runPerception` is deliberately written against the **abstract factory**:

```cpp
void runPerception(const ISensorSuiteFactory& factory) {
  // Ask for a matched product family
  std::unique_ptr<ILiDAR>  lidar  = factory.createLiDAR();
  std::unique_ptr<ICamera> camera = factory.createCamera();

  // Use via abstract APIs (no concrete types here)
  lidar->readPointCloud();
  camera->captureFrame();
}
```

The function receives an `ISensorSuiteFactory` (via DI), not a concrete factory. It requests products (`createLiDAR()`, `createCamera()`), but gets back only interfaces (`std::unique_ptr<ILiDAR>`, `std::unique_ptr<ICamera>`). It uses those products exclusively through their abstract APIs (`readPointCloud()`, `captureFrame()`). The client knows what it needs (a LiDAR and a Camera) and how to use them (their abstract methods). The client does not know which LiDAR/Camera it got (Simulated, Velodyne, Hesai, HighRes, etc.). That choice is made elsewhere in the application.

This is the primary benefit of Abstract Factory: you can swap an entire sensor suite (a *coherent family*) without rewriting high-level logic. In a real deployment, `runPerception` would live in another module far from `main()`, which acts as the **composition root** and selects the environment via `make_factory(Environment)`.

#### Benefits & Guardrails

* **Separation of concerns**: Client code performs perception; the library decides what to build (`make_factory(env)`), then builds it. Constructing concretes in client code (`new VelodyneLiDAR`) couples high-level logic to a vendor and kills swapability.

* **Family consistency**: One factory ⇒ a matched set of products (LiDAR + Camera from the same environment). Mixing families (e.g., `SimulationSensorFactory` for LiDAR and `ProductionSensorFactory` for Camera) invites subtle, hard-to-debug mismatches.

* **Strong decoupling**: High-level code depends only on interfaces (`ILiDAR`, `ICamera`, `ISensorSuiteFactory`). Including concretes (`#include "Concrete*.hpp"`) or relying on `dynamic_cast` leaks implementation details.

* **Testability by construction**: Inject `Simulation`/`R&D` factories (or mocks) to run without hardware. Burying environment selection inside the client makes tests brittle—keep it at the composition root.

* **Safe ownership & ABI-friendly API**: Factories return `std::unique_ptr<Interface>` so lifetimes are explicit; no `new/delete` in client code. Returning raw pointers obscures ownership and complicates error handling across boundaries.

* **Stable public surface**: Ship only interfaces + a thin facade (`FactoryAPI.hpp`); internals can evolve freely. Exposing private headers or concrete class names in public headers locks clients to your implementation.

* **Easy extensibility**: Add new vendors/products behind the factory without touching clients. Switching on vendor types inside client code re-introduces coupling you just removed.

# 4) The contracts the client compiles against (public headers)

These are the **only headers you ship**.    

1. Abstract products = capability contracts. Define *what* a sensor can do; vendors provide implementations.    

    ```cpp
    // ISensorProducts.hpp  (abstract products)
    struct ILiDAR {
        virtual ~ILiDAR() = default;
        virtual void readPointCloud() = 0;
    };
    struct ICamera {
        virtual ~ICamera() = default;
        virtual void captureFrame() = 0;
    };
    ```

2. Abstract factory = family creator. Returns a matched set of products via interfaces; no concrete types leak out.   

    ```cpp
    // ISensorSuiteFactory.hpp  (abstract factory)
    struct ISensorSuiteFactory {
        virtual ~ISensorSuiteFactory() = default;
        virtual std::unique_ptr<ILiDAR>  createLiDAR()  const = 0;
        virtual std::unique_ptr<ICamera> createCamera() const = 0;
    };
    ```
3. Facade/entry point. One call selects the environment and hides all concrete classes.    

    ```cpp
    // FactoryAPI.hpp  (tiny façade / entry point)
    enum class Environment { Simulation, RnD, Production };
    std::unique_ptr<ISensorSuiteFactory> make_factory(Environment env);
    ```

Abstract Factory exposes _one interface per abstract product_ and _one abstract factory_ that creates them. `FactoryAPI.hpp` is just a convenience so callers never see concrete types.

# 5) Where concrete classes live (hidden in the .so)

Inside the library (your `.so`), you implement the families. Clients never include these headers.

1. **ConcreteProducts.hpp/.cpp (private):** Implement the abstract products (`ILiDAR`, `ICamera`). Vendor-specific behavior lives here, compiled into the `.so`, and never shipped as headers. As long as these classes honor the interfaces, they’re freely swappable without client changes.   

    ```cpp
    // (private) ConcreteProducts.hpp/.cpp
    struct SimulatedLiDAR : ILiDAR { void readPointCloud() override { /* ... */ } };
    struct SimulatedCamera: ICamera { void captureFrame()  override { /* ... */ } };
    // ... VelodyneLiDAR, HighResCamera, HesaiLiDAR, ProductionCamera, etc.
    ```

2. **ConcreteFactories.hpp/.cpp (private):** Implement `ISensorSuiteFactory` and **assemble a matched family**—each `create*` returns the environment’s corresponding concrete product. This centralizes wiring and guarantees family consistency while keeping clients interface-only.

    ```cpp
    // (private) ConcreteFactories.hpp/.cpp
    struct SimulationSensorFactory : ISensorSuiteFactory {
    std::unique_ptr<ILiDAR>  createLiDAR()  const override { return std::make_unique<SimulatedLiDAR>(); }
    std::unique_ptr<ICamera> createCamera() const override { return std::make_unique<SimulatedCamera>(); }
    };

    struct RDSensorFactory : ISensorSuiteFactory {
    std::unique_ptr<ILiDAR>  createLiDAR()  const override { return std::make_unique<VelodyneLiDAR>(); }
    std::unique_ptr<ICamera> createCamera() const override { return std::make_unique<HighResCamera>(); }
    };

    struct ProductionSensorFactory : ISensorSuiteFactory {
    std::unique_ptr<ILiDAR>  createLiDAR()  const override { return std::make_unique<HesaiLiDAR>(); }
    std::unique_ptr<ICamera> createCamera() const override { return std::make_unique<ProductionCamera>(); }
    };
    ```

3. **FactoryAPI.cpp (private façade/composition):** The only place that knows concrete class names. Maps `Environment → concrete factory` (`make_factory`), so adding a new vendor/environment changes this file (and its factory) only; clients and high-level code remain unchanged.      

    ```cpp
    // (private) FactoryAPI.cpp — the only place that knows concretes
    std::unique_ptr<ISensorSuiteFactory> make_factory(Environment env) {
    switch (env) {
        case Environment::Simulation:  return std::make_unique<SimulationSensorFactory>();
        case Environment::RnD:         return std::make_unique<RDSensorFactory>();
        case Environment::Production:  return std::make_unique<ProductionSensorFactory>();
    }
    return nullptr;
    }
    ```

Each concrete factory builds a matched family of products. Swapping the factory swaps the entire suite.

## Adding a new abstract product (e.g., Radar)
When adding a new product type, the families (Simulation/R&D/Production) remain the same; you extend the abstract surface and implement the new factory method in each existing concrete factory so every family gets a matching new member. So, the set of families—`SimulationSensorFactory`, `RDSensorFactory`, `ProductionSensorFactory`—remains unchanged (same classes, same environments).

What changes:

1. The **abstract surface** grows: add a new abstract product interface and a new factory method.
2. **Each existing concrete factory** implements that new method and returns its family’s concrete product.
3. **Clients** only change where they **choose to consume** the new product; existing code compiles unchanged.

This illustrates the trade-off of Abstract Factory:

* **Easy to add a new family** (add one new concrete factory + products, no client changes).
* **Costly to add a new product type** (touch the abstract factory + all concrete factories), but client code remains insulated.

E.g.,   

#### 1) Public headers (abstract surface expands)   



```cpp
// ISensorProducts.hpp
struct IRadar {
virtual ~IRadar() = default;
virtual void sweep() = 0;
};
```    


```cpp
// ISensorSuiteFactory.hpp
struct ISensorSuiteFactory {
  virtual ~ISensorSuiteFactory() = default;
  virtual std::unique_ptr<ILiDAR>  createLiDAR()  const = 0;
  virtual std::unique_ptr<ICamera> createCamera() const = 0;
  // NEW:
  virtual std::unique_ptr<IRadar>  createRadar()  const = 0;
};
```

#### 2) Library internals (each family implements the new member)

```cpp
// ConcreteProducts.cpp (examples)
struct SimulatedRadar  : IRadar { void sweep() override { /* ... */ } };
struct RnDSensorFactory : IRadar { void sweep() override { /* ... */ } };
struct ProductionRadar : IRadar { void sweep() override { /* ... */ } };
```

```cpp
// ConcreteFactories.cpp (add one method to each factory)
std::unique_ptr<IRadar> SimulationSensorFactory::createRadar() const {
  return std::make_unique<SimulatedRadar>();
}
std::unique_ptr<IRadar> RDSensorFactory::createRadar() const {
  /* return std::make_unique<RnDRadar>(); */ 
}
std::unique_ptr<IRadar> ProductionSensorFactory::createRadar() const {
  return std::make_unique<ProductionRadar>();
}
```    

## Practical Implications & Engineering Trade-offs

#### Core benefits

* **Swapability at the edge**: Choose the whole suite in one place, not everywhere.   
  *Example*: `make_factory(Production)` flips both LiDAR+Camera to production vendors without touching `runPerception`.

* **Family consistency**: One factory ⇒ matched products that are meant to work together.   
  *Example*: `RDSensorFactory` always pairs `VelodyneLiDAR` with `HighResCamera`—no “Sim LiDAR + Prod Camera” accidents.

* **Encapsulation of creation**: Object wiring is centralized and private.   
  *Example*: Only `FactoryAPI.cpp` knows concrete class names; clients see `ILiDAR`, `ICamera`, `ISensorSuiteFactory`.

* **Stable public surface**: Ship interfaces, hide vendors.   
  *Example*: Only three headers installed (`ISensorProducts.hpp`, `ISensorSuiteFactory.hpp`, `FactoryAPI.hpp`); all concretes live in the `.so`.

* **Testability by design**: Inject alternate families for tests.   
  *Example*: Use `make_factory(Simulation)` in CI to run perception with no hardware.

* **Clear ownership**: Factories return `std::unique_ptr<Interface>`; lifetimes are explicit.   
  *Example*: `auto lidar = factory.createLiDAR();`—no `new/delete` in client code.

#### Trade-offs

* **More types/indirection**: You introduce interfaces and factories even for simple cases.   
  *Example*: A tiny tool with one sensor might be simpler with a direct constructor.

* **Adding a new product type is broad**: You must touch the abstract factory **and** every concrete factory.   
  *Example*: Adding `IRadar` requires `createRadar()` in `ISensorSuiteFactory` plus implementations in `Simulation/RD/Production` factories.

* **Debugging crosses a boundary**: Failures can be in the selection layer, not the client.   
  *Example*: Wrong `Environment` passed to `make_factory` yields the right APIs but the wrong vendor behavior.

* **Over-generalization risk**: Don’t push everything through the pattern.    
  *Example*: If a sensor is truly independent, expose it separately instead of stuffing it into every family.

## Conclusion and Final Takeaways

 The Abstract Factory pattern provides several key benefits for autonomous vehicle software. It gives you **supplier agility without code churn**, meaning you can swap out an entire sensor suite without changing the application's core logic.

 You choose the specific sensor suite (e.g., Simulation, R&D, or Production) in one place, and the factory provides a matched family of sensors, such as LiDAR, camera, and radar. The same client code can run unchanged across different environments like Software-in-the-Loop (SIL), Hardware-in-the-Loop (HIL), and a real vehicle. Only the factory's selection is changed at boot-up.

 Because only abstract interfaces are exposed in public headers, vendor-specific code and wiring are kept inside the `.so` library file. This makes over-the-air (OTA) updates and building for multiple product lines practical.

 The pattern also creates clear **safety and performance boundaries**. Vendor code is hidden behind product interfaces, which is beneficial for ISO 26262 traceability. The factories manage policies for things like time bases, buffering, and retries, ensuring consistent behavior within a specific sensor family. Building the entire suite at startup and returning `unique_ptr` interfaces helps keep "hot paths" (critical code sections) allocation-free and deterministic.

 This design makes testing more reproducible. You can run the same test suite against every sensor family. Additionally, you can use the simulation family for creating "golden," fault-injectable pipelines. When you need to add a new sensor supplier, it becomes a matter of "adding a new family" to the system, this is because the pattern guarantees that a concrete factory creates a cohesive family of products. For example, "Luminar," is introduced, you would create a new concrete factory (e.g., `LuminarSensorFactory`) that produces a new family of concrete products (e.g., `LuminarLiDAR`, `LuminarCamera`, etc.) that are all compatible, the core perception logic remains unchanged.