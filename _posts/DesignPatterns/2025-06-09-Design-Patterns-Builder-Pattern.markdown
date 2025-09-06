---
layout: default
title: "Builder Pattern: Practitioner’s Notes on Composable System Design"
seo_h1: "Builder Pattern: Practitioner’s Notes on Composable System Design"
date: 2025-09-06 09:44:19 +0530
categories: design-patterns
tags: [Design Patterns, cpp]
mathjax: true
description: "Practitioner’s notes on the Builder pattern for autonomous-vehicle software—an applied, field-driven look at recipe-based assembly, consolidated diagnostics, and all-or-nothing creation. Not a step-by-step tutorial; these notes show how keeping wiring in the composition root, isolating vendor choices behind factories, and enforcing a green-gate build makes AV perception stacks modular, testable, and predictable."
published: true
placement_prio: 1
pinned: false
---

###   Intro & problem (AV stacks are complex, constructors explode)

In the autonomous vehicle (AV) software, a primary problem is the immense complexity of the perception pipeline. This subsystem takes raw sensor data and fuses it to create a real-time, comprehensive understanding of the vehicle's surroundings.

A single perception pipeline can have dozens of interdependent components, such as different types of cameras, LiDARs, radars, and various algorithms for object detection, tracking, and fusion. Attempting to configure and instantiate such a system using a simple constructor leads to a phenomenon known as **telescoping constructors**, where a single class has multiple constructors with an increasing number of parameters. This results in code that is difficult to read, maintain, and prone to errors. Developers might accidentally create **half-initialized objects** or **invalid combinations** of components, leading to unpredictable behavior or system crashes at runtime. For example, a tracking algorithm might require a specific data format that a particular sensor does not provide, but a simple constructor wouldn't be able to validate this dependency.

The **Builder pattern** solves these problems by separating the construction logic from the object itself. Instead of a single, monolithic constructor, the pattern provides a **staged, step-by-step assembly process**. This allows a developer to configure the perception pipeline piece by piece (e.g., first add the LiDAR, then the cameras, then the fusion algorithm). At each stage, the builder can perform validation, ensuring that components are compatible and that the final object is fully configured and in a valid state. This approach guarantees that you either get a complete, validated perception pipeline or the build process fails early with a clear diagnostic message, preventing runtime errors.


### Core Principles

The pattern operates on a simple but effective principle: **"Build in steps, validate in the middle, produce a ready object at the end."** This staged approach offers significant advantages over traditional constructors, especially when dealing with the intricate dependencies and numerous configuration options of an AV stack.

* **Telescoping Constructors**: In complex systems, constructors can become unwieldy, with 10–20 parameters to account for all possible configurations. This makes them difficult to read, use, and maintain. The Builder pattern replaces this with a simple, readable interface.
* **Half-Initialized Objects**: Without a controlled assembly process, it's easy to create an object that is only partially configured, leading to runtime errors. The Builder pattern prevents this by guaranteeing that the final object is returned only after all necessary steps are completed and validated.
* **Invalid Combinations**: A key benefit of the Builder pattern is its ability to perform **validation during the build process**. For example, it can prevent a developer from combining a specific tracker algorithm with a sensor that provides incompatible data. This "fail-fast" approach catches errors at a safer, earlier stage.
* **Environment Drift**: An AV stack needs different configurations for different environments—simulation, R&D, and production. The Builder pattern makes it simple to manage these variations by creating a separate **concrete builder** for each environment. The client code remains the same; only the builder changes.


### Use Case: Building an Autonomous Perception Pipeline

A perfect example is the construction of a **perception pipeline**, a core subsystem of any AV stack. This pipeline takes raw sensor data and outputs a comprehensive understanding of the vehicle's surroundings. The complexity lies in its numerous, interdependent components, such as cameras, LiDAR, and various detection algorithms.

Using the Builder pattern, a `PerceptionPipelineBuilder` would define a sequence of steps. Different **concrete builders** would then implement these steps to create distinct pipelines:

* **`UrbanPerceptionBuilder`**: This builder would configure a pipeline with a short-range, high-resolution LiDAR and a wide-angle camera, along with machine learning models optimized for detecting pedestrians, cyclists, and traffic lights. 
* **`HighwayPerceptionBuilder`**: This builder would use a long-range LiDAR and a camera with a narrow field of view, specifically tuned to track vehicles at high speeds and detect lane markings over long distances. 

This approach makes the code for creating these pipelines clean and readable. The client code simply chooses the builder for the desired configuration and the builder handles the intricate assembly process, including all the necessary validation, ensuring the final pipeline is robust and ready for deployment.

### Builder vs. Other Creational Patterns

Choosing the right creational pattern is essential. Here's when to favor the Builder pattern over others:

| **Pattern**          | **Purpose**                                                                                                   | **When to Use**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| -------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Builder**          | Constructs a single, complex object step-by-step.                                                             | Use the Builder pattern when you need to build a complex object with **many optional parts** and want to ensure the final product is always valid. It’s the go-to pattern for objects that can be configured in numerous ways, preventing unwieldy constructors and enforcing a controlled assembly process.                                                                                                                                                                                                                                                  |
| **Abstract Factory** | Creates families of related or dependent objects.                                                             | Use the Abstract Factory pattern when you need to create **families of related objects**, but not necessarily a single, complex object. For example, a `SensorFactory` could produce a specific type of LiDAR, camera, and radar that are all compatible. You’d use this if you need to create multiple consistent sets of objects. In contrast, use the Builder when you need to construct a **single, complex object step-by-step** and want to control the assembly process, allowing for different representations with the same core construction logic. _Abstract factory **supplies** a family of compatible parts (e.g., Ouster preproc, Zed camera, TensorRT detector). It’s the **supplier**. Builder is the **assembler** that wires those parts together correctly and validates order/constraints._ |
| **Factory Method**   | Provides an interface for creating an object, but allows subclasses to decide which type of object to create. | The Factory Method pattern is used when a class **delegates instantiation** to its subclasses. It provides an interface for creating an object in a superclass, but allows subclasses to alter the type of object that will be created. Use the Builder when the object’s construction is **complex and involves many steps or optional parameters**. Factory Method is about **“what”** to create, while Builder is about **“how”** to create it.                                                                                                            |
| **Prototype**        | Creates new objects by **cloning an existing object**.                                                        | The Prototype pattern is used to create new objects by cloning an existing object. This is useful when the object’s state is expensive to create from scratch or when you need to avoid coupling the client to a specific concrete class. Use the Builder when the object’s construction process is **complex and involves a sequence of operations**, rather than simply copying an existing instance. Prototype is for creating new instances based on a template, whereas Builder is for constructing instances from scratch through a guided process.     |
| **Singleton**        | Ensures a class has **only one instance** and provides a **global access point** to it.                       | Use Singleton when exactly **one shared instance** must coordinate access to a process-wide resource (e.g., logging sink, monotonic clock, diagnostics registry) and you can guarantee lifecycle and thread-safety. Prefer **dependency injection** for testability; don’t use Singleton to model complex subsystems—use **Builder** to assemble those explicitly.                                                                                                                             


**When Builder is the right tool**   
Use it when creation has many optional parts, order matters, and invariants span modules (e.g., “extrinsics after sensors, before fusion,” “EKF requires LiDAR”). You want fail-fast validation and a ready-to-run, immutable pipeline at the end. _Factories still exist—feeding parts to the Builder—but the **Builder owns the assembly and validation**._



# Intent & mental model (Builder/Director/Factory)

* **Builder = enforces correctness (no half-built object escapes; order constraints validated)**    
Separates *how to construct* a complex object from the object itself. It exposes named steps (e.g., `with_detector`, `with_tracker`) and accumulates configuration until a final `build()` produces a ready-to-run pipeline.
* **Director = the recipe (order + defaults per environment)**    
Is a **recipe**. It calls the Builder in a known sequence to create a standard variant (Simulation, R&D, Production).
* **Product (Abstract Factory) = immutable once built**   
Remains the **supplier** of concrete module implementations (e.g., Velodyne vs Ouster pre-proc, TensorRT vs ONNX detector). The Builder consumes these parts and ensures the resulting system is coherent.


# Running example (PerceptionSuite)

* **Client: Trigger `build()`, Handle Diagnostics**    


    Start at the composition root. In this code, the composition root is the small function `build_pipeline(env, errors)`. It owns all wiring: it **creates a concrete builder** (e.g., `PipelineBuilder`) and treats it as an **`IBuilder&`**, hands that interface to a `PipelineDirector`, selects the variant from a strongly typed `Environment` enum (`Simulation`, `R&D`, `Production`), and then runs the **green gate**—the validation barrier—with `builder.build(&errors)`. If validation does not pass, nothing leaks out—only a clean list of diagnostics. `main()` remains a thin launcher that parses the environment, calls this root, and either prints the errors or runs the pipeline. Keeping policy (what to assemble) out of runtime code (how it runs) makes binaries easier to reason about and test.

    When an **Abstract Factory** is in play, the composition root also **selects the concrete factory** (Sim/R&D/Prod vendor set) and **injects it into the concrete builder’s constructor** before passing the builder as `IBuilder&` to the Director. The Director stays interface-only (no allocation, no `build()` call), while the Builder assembles and validates.

    > **Composition root** is the single entry point where an application’s object graph is assembled and validated before use. It is the only place that knows policies (which variant to build), selects concrete implementations and factories, injects them behind interfaces (here, **`IBuilder`**), invokes the Director recipe, runs the Builder’s validation gate, and finally produces the immutable Product. No domain/business logic lives here—only wiring, configuration, and failure handling. Keeping construction in one root makes dependencies explicit, enables fast failure with consolidated diagnostics, and simplifies testing (build paths can be unit-tested without running the system).


    ```cpp
    // --- Environment ------------------------------------------------------
    enum class Environment { Simulation, RnD, Production };

    static Environment parse_env(std::string_view s) {
        std::string t{s};
        std::transform(t.begin(), t.end(), t.begin(),
                    [](unsigned char c){ return std::tolower(c); });
        if (t == "sim"  || t == "simulation")  return Environment::Simulation;
        if (t == "prod" || t == "production")  return Environment::Production;
        return Environment::RnD; // default
    }

    // --- Composition root -------------------------------------------------
    std::optional<PerceptionPipeline>
    build_pipeline(Environment env, std::vector<std::string>& errors) {
        PipelineBuilder  concrete;     // choose the concrete builder here
        PipelineDirector director{concrete}; // director depends on interface

        switch (env) {
            case Environment::Simulation: director.setupSimulation(); break;
            case Environment::RnD:        director.setupRnD();        break;
            case Environment::Production: director.setupProduction(); break;
        }
        return concrete.build(&errors);   // green gate (all-or-nothing)
    }

    // --- Launcher ------------------------------------------------------
    int main(int argc, char** argv) {
        Environment env = (argc > 1) ? parse_env(argv[1]) : Environment::RnD;

        std::vector<std::string> errors;
        auto pipeline = build_pipeline(env, errors);

        if (!pipeline) {
            std::cout << "Build failed (" << errors.size() << " issue(s)):\n";
            for (const auto& e : errors) std::cout << "  - " << e << "\n";
            return 1;
        }
        pipeline->run();
        return 0;
    }
    ```


* **Director: Recipe, Not Factory**

    The Director captures the **build recipe** for each environment and talks only to the **`IBuilder` interface**. It drives the builder through a deliberate sequence—**sensors → extrinsics → fusion**—and then stops. **Order lives here.** The Director does not allocate, does not own modules, and never calls `build()`; it simply applies environment defaults (Simulation/R&D/Production) in a repeatable way. Depending on `IBuilder` (not a concrete Builder) keeps the recipe portable and testable: any conforming builder can be swapped in—one that sources parts via an Abstract Factory, a lightweight demo builder, or a test double.

    This interface-first design encodes **policy as steps**: *same construction API, different ordered sequences and defaults per environment*. It also enforces the inversion of dependencies: the recipe depends on an abstraction, while the **composition root** chooses the concrete builder and decides when to cross the **green gate** (`build(&errors)`).

    ```cpp
    // --- Domain choices ---------------------------------------------------
    enum class LiDAR  { None, Sim, Ouster64, Velodyne64 };
    enum class Camera { None, SimStereo, ZedStereo, ZedX };
    enum class Fusion { None, EKF, StereoFusion };

    // --- Director (Variant B): orchestrates sequence, never builds --------
    class PipelineDirector {
    public:
        explicit PipelineDirector(IBuilder& b) : b_(b) {}

        void setupSimulation() {
            b_.reset();
            b_.withLiDAR(LiDAR::Sim)
            .withCamera(Camera::SimStereo)
            .withExtrinsicsCalibrated()
            .withFusion(Fusion::StereoFusion);
        }
        void setupRnD() {
            b_.reset();
            b_.withLiDAR(LiDAR::Ouster64)
            .withCamera(Camera::ZedStereo)
            .withExtrinsicsCalibrated()
            .withFusion(Fusion::StereoFusion);
        }
        void setupProduction() {
            b_.reset();
            b_.withLiDAR(LiDAR::Ouster64)
            .withCamera(Camera::ZedStereo)
            .withExtrinsicsCalibrated()
            .withFusion(Fusion::EKF);
        }

    private:
        IBuilder& b_;
    };
    ```   

    In practice, Directors sit in bringup/wiring code (often invoked from a launch file), not inside node logic. Parameters select which Director to run; an **Abstract Factory** supplies vendor-specific parts; the Director orders the steps; the Builder validates; the composition root calls `build()` and fails fast if the gate is red. Typical patterns: Simulation uses replay/mock time and stereo fusion; R&D enables experimental fusion and verbose metrics; Production locks to validated modules (e.g., EKF) with strict clocks and conservative defaults.

    > Director’s core responsibility is to **orchestrate the sequence of construction steps**—a repeatable **recipe**—so the Builder assembles a complex object in the right order with sane defaults.

* **Builder: The Green Gate — Assemble, Validate, Commit**

    The `IBuilder` + Builder pair is the assembler and gatekeeper: `IBuilder` defines the fluent steps and the green-gate API; `PipelineBuilder` (the concrete implementation) enforces them. It gathers steps (`withLiDAR`, `withCamera`, `withExtrinsicsCalibrated`, `withFusion`) and then runs a single validation barrier before creation. Validation implements  **structural rules** (at least one sensor), **ordering rules** (extrinsics after sensors, before fusion), and **semantic rules** (EKF requires LiDAR; StereoFusion requires a stereo camera). `build(&errors)` is all-or-nothing—no half-built objects escape; diagnostics are consolidated. On success, the result is an immutable `PerceptionPipeline` (no setters), keeping runtime deterministic. `reset()` lets a Director reuse the Builder between recipes without leaking prior state.

    Directors and tests depend on `IBuilder`, so alternative builders can be swapped without changing recipes—for example, a factory-backed builder, a staged/compile-time builder, or a test double.

    ```cpp
    // --- IBuilder: interface for step-wise construction -------------------
    struct IBuilder {
        virtual ~IBuilder() = default;

        virtual IBuilder& withLiDAR(LiDAR x) = 0;
        virtual IBuilder& withCamera(Camera x) = 0;
        virtual IBuilder& withExtrinsicsCalibrated() = 0;
        virtual IBuilder& withFusion(Fusion x) = 0;

        virtual bool validate(std::vector<std::string>& errors) const = 0;

        virtual std::optional<PerceptionPipeline>
        build(std::vector<std::string>* out_errors = nullptr) const = 0;

        virtual void reset() = 0;
    };

    // --- ConcreteBuilder: implements IBuilder + validation gate -----------
    class PipelineBuilder final : public IBuilder {
    public:
        IBuilder& withLiDAR(LiDAR x) override {
            lidar_ = x; sensors_set_ = true; return *this;
        }
        IBuilder& withCamera(Camera x) override {
            camera_ = x; sensors_set_ = true; return *this;
        }
        IBuilder& withExtrinsicsCalibrated() override {
            extrinsics_ok_ = sensors_set_; return *this;
        }
        IBuilder& withFusion(Fusion x) override {
            fusion_ = x; return *this;
        }

        bool validate(std::vector<std::string>& errors) const override {
            errors.clear();
            if (!sensors_set_)
                errors.push_back("At least one sensor (LiDAR/Camera) is required.");
            if (!fusion_.has_value() || *fusion_ == Fusion::None)
                errors.push_back("Fusion must be selected (EKF or StereoFusion).");
            if (!extrinsics_ok_)
                errors.push_back("Extrinsics must be calibrated after sensors and before fusion.");
            if (fusion_ == Fusion::EKF && (!lidar_.has_value() || *lidar_ == LiDAR::None))
                errors.push_back("EKF requires a LiDAR source.");
            if (fusion_ == Fusion::StereoFusion && (!camera_.has_value() || *camera_ == Camera::None))
                errors.push_back("StereoFusion requires a stereo camera.");
            return errors.empty();
        }

        std::optional<PerceptionPipeline>
        build(std::vector<std::string>* out_errors = nullptr) const override {
            std::vector<std::string> errs;
            if (!validate(errs)) {
                if (out_errors) *out_errors = std::move(errs);
                return std::nullopt;
            }
            PerceptionPipeline p;
            p.lidar         = lidar_.value_or(LiDAR::None);
            p.camera        = camera_.value_or(Camera::None);
            p.fusion        = *fusion_;
            p.extrinsics_ok = extrinsics_ok_;
            return p; // immutable product
        }

        void reset() override {
            lidar_.reset(); camera_.reset(); fusion_.reset();
            sensors_set_ = false; extrinsics_ok_ = false;
        }

    private:
        std::optional<LiDAR>  lidar_;
        std::optional<Camera> camera_;
        std::optional<Fusion> fusion_;
        bool sensors_set_  = false;
        bool extrinsics_ok_ = false;
    };
    ```

    In this implementation, the _Builder’s core promise is **all-or-nothing construction**: `validate()` enforces the invariants and `build()` commits the result_. Factories supply parts; the Builder assembles and guards the gate. 

* **Product: PerceptionPipeline — the Immutable Result**

    This is the finished object produced after the green gate. Configuration is frozen: no setters, no late rewiring, no hot-swapping. Only runtime methods exist (e.g., `start()`, `stop()`, `process()`/`run()`). Structure (LiDAR, Camera, Fusion) and invariants (e.g., `extrinsics_ok`) are captured at build time to keep behavior deterministic and thread-safe. To change wiring, choose a different Director recipe and rebuild—do not mutate.

    ```cpp
    // --- The final Product --------------------------------------------
    struct PerceptionPipeline {
        LiDAR  lidar{};
        Camera camera{};
        Fusion fusion{};
        bool   extrinsics_ok{false};

        void run() const {
            std::cout << "[RUN] Pipeline: LiDAR="  << static_cast<int>(lidar)
                    << " Camera=" << static_cast<int>(camera)
                    << " Fusion=" << static_cast<int>(fusion) << "\n";
        }
    };
    ```

    The composition root creates the product; it does not contain it. In a real codebase the `PerceptionPipeline` sits inside the perception module/library, hidden behind interfaces (e.g., `IPerceptionSuite`). The root obtains a `std::unique_ptr<IPerceptionSuite>` from the Builder, then hands it off to the consumer (node/orchestrator/service). This keeps wiring and policy at the edge and implementation details deep in the module.   
    
    > In real AV stacks, `run()` means bring the perception graph online and keep it processing streams until shutdown. It's an ongoing execution loop (or node spin), not a one-off call—your _Builder just ensures the system is valid before you flip that switch_.




# Architecture diagram   


![alt text](/assets/images/DesignPatterns/Images/Builder/Builder1.png)

Here’s the essence of your diagram :

* **CompositionRoot = the only place that knows policy.**   
  It creates the concrete `PipelineBuilder` (injecting the chosen **`ISensorSuiteFactory`** for Sim/R&D/Prod), passes it as an `IBuilder&` to the `PipelineDirector`, runs a recipe, then triggers `build(...)`. Everything about *which* factory/builder to use lives here.

* **Director -> `IBuilder` is an *aggregation*.**   
  The Director holds a reference to `IBuilder` (`b_`), _orchestrates the order of steps_ (`setupSimulation/RnD/Production`), and never calls `build()`. It doesn’t own the builder; it just drives it—classic open-diamond aggregation.

* **`IBuilder` is the stable seam.**   
  Recipes and tests depend on the interface, not the concrete class. This gives you _swap-ability_: mock builders for tests, a factory-backed builder for production, etc., without touching the Director.

* **`PipelineBuilder` is the ConcreteBuilder.**    
  It implements the fluent steps (`withLiDAR/withCamera/withExtrinsicsCalibrated/withFusion`), holds build-time state, runs the green gate (`validate` + `build`), and returns the product.

  * Builder -> `ISensorSuiteFactory` is an aggregation (open diamond) *if you store the factory ref*. The builder **uses** the factory to obtain compatible parts during assembly.

* **`ISensorSuiteFactory` has Sim/RnD/Prod implementations.**    
  These concrete factories supply compatible families of parts (detector, tracker, fuser, etc.). Swapping the factory at the root switches vendors/configs without changing recipes.

* **`PerceptionPipeline` is the Product and owns its modules.**    
  The filled diamonds show composition: the pipeline owns `IDetector`, `ITracker`, and `IFuser`; their lifetimes are tied to the pipeline. After a successful build the pipeline is immutable (structure fixed), and only lifecycle/work methods (`start`, `stop`, `process`) are exposed.

# Practical Implications & Engineering Trade-offs

A well-designed Builder keeps construction cheap and pure: `build()` is $$O(config)$$, side-effect-free, and returns either a valid product or precise diagnostics. Heavy work shifts to `start()` (engine loads, device handles, threads) so `process()` stays allocation-free and predictable.

Immutability after build buys determinism, easier concurrency, and freedom to tune memory layout for cache locality (owned modules, no shared singletons).

An Abstract Factory lets you swap the fastest compatible backends per environment and cache expensive artifacts (e.g., TensorRT plans) keyed by configuration so repeated builds are near-zero cost.

Keep the Director pure (ordering + defaults only) to make recipes testable and avoid hiding perf work; if sequences are static, consider staged/compile-time builders.

Wire telemetry at the root (build/start/process timings, error categories) and fail fast when the green gate is red—clean construction and disciplined lifecycle control are what make the runtime path fast.


# Conclusion: “Recipe over randomness: ship validated builds.”

Builder makes the construction of an AV pipeline explicit, staged, and testable. Directors provide repeatable environment recipes. Abstract Factory supplies the right concrete parts. Together, they let you assemble Simulation/R&D/Production stacks from the same codebase—with constructors tamed, invariants enforced, and runtime surprises removed.

