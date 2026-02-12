---
layout: default
title: "Observer Pattern (Case Study): Event Notifications with Pluggable Subscribers"
seo_h1: "Observer Pattern (Case Study): Event Notifications with Pluggable Subscribers"
date: 2026-02-11 09:00:00 +0530
categories: design-patterns
tags: [Design Patterns, cpp]
mathjax: true
description: "C++ Observer Pattern notes and case study: Stock Market Ticker."
published: true
placement_prio: 0
---

### **Problem statement: Stock Price Ticker with Multiple Consumers**

You’re building a small “market data” module, that receives live stock price updates (ticks) and needs to notify various parts of the system in real-time. The consumers include:
1.  A UI component that displays the latest price for each stock.
2.  An alert engine that triggers rules like “notify me if AAPL crosses $150.”
3.  A risk monitor that recalculates exposure based on the latest prices.
4.  An audit logger that writes an immutable log entry for every tick.

A PriceFeed receives live ticks: `(symbol, price, timestamp)`. Each tick must be broadcast to all active consumers immediately. Consumers can come and go at runtime (e.g., UI opens/closes, alert rules enabled/disabled). The PriceFeed should not need to know about the specific consumers or how many there are.

Multiple independent parts of the system need to react immediately. The PriceFeed **should not be** tightly coupled to any specific consumer. We want a design that allows us to add new consumers without modifying the PriceFeed code.   

**Input**: A stream of stock price ticks (symbol, price, timestamp).    
**Output**: Real-time notifications to multiple independent consumers (UI, alerts, risk, logging) whenever a new tick arrives.

#### The requirements can be summarized as:

* When a new tick arrives, all active consumers must be notified with minimal latency. 
* Consumers can come and go, so the system must support dynamic subscription and unsubscription at runtime.
* The PriceFeed should be decoupled from the consumers, adhering to the Open-Closed Principle. Adding new consumers should not require changes to the PriceFeed code.
* The design should be efficient and scalable, capable of handling a high volume of ticks without significant performance degradation.
* UI subscribes when a screen opens, unsubscribes when it closes. This is a common pattern for temporary consumers that only care about updates while active.
* Alert rules may be enabled/disabled at runtime
* Logger might be swapped (file vs Kafka) without touching PriceFeed code

### **Naive approach: Direct Coupling**

A first attempt usually looks like this:

```cpp
// This is a tightly coupled design and violates the Open-Closed Principle
class PriceFeed {
    // Direct references to all consumers
    UiTicker* ui;
    AlertEngine* alerts;
    RiskMonitor* risk;
    Logger* logger;

public:
    // This method is called whenever a new tick arrives
    void onNewTick(const Tick& tick) {
        ui->update(tick); 
        alerts->on_tick(tick);
        risk->on_tick(tick);
        logger->write(tick);
    }

    // Methods to set the consumers (not ideal)
};
```

Here, the `PriceFeed` class has direct references to all the consumers. Whenever a new tick arrives, it explicitly calls each consumer’s update method. This design has several issues:
1.  **Tight Coupling**: `PriceFeed` is now tightly coupled to specific consumer classes. If we want to add a new consumer, we have to modify `PriceFeed`, which violates the Open-Closed Principle.
2.  **Growing Dependency List**: As we add more consumers, `PriceFeed` becomes a “god broadcaster” that knows about every consumer in the system.
3.  **Hard Runtime Behavior**: Managing subscriptions becomes messy. If a UI component opens, we have to remember to set the `ui` pointer. If it closes, we have to remember to null it out or risk dereferencing a dangling pointer.
4.  **Polling Temptation**: To avoid coupling, some might be tempted to have consumers poll `PriceFeed.get_latest()`, which wastes CPU and adds latency.

#### What we want instead
A design where:
* `PriceFeed` only knows an Observer interface (not UI/Alerts/Risk)
* Any consumer can attach/detach at runtime
* On each tick, PriceFeed just says: notifyAll(tick)
* New consumers can be added without modifying PriceFeed


### **The "Observer Pattern"**

The Observer Pattern defines a one-to-many dependency between objects. When the state of one object (the Subject) changes, all its dependents (Observers) are notified and updated automatically. This pattern promotes loose coupling and adheres to the Open-Closed Principle. In our case - 
* The `PriceFeed` is the **Subject**. A subject is an object having a state and a list of observers that are interested in changes to that state.
* Each consumer (UI, AlertEngine, RiskMonitor, Logger) implements the **Observer interface** through which they receive updates from the Subject.
* The Subject maintains a list of its observers and notifies them of any state changes, usually by calling one of their methods (e.g., `update()`).


#### **Design Strategy: Decouple the Broadcaster from the Consumers**

* **Freeze the Broadcaster**: `PriceFeed` (the Subject) should only know that it has a list of "things that want to listen". Beyond that, it should not care about the specific types of consumers or how they react to updates. It just needs to know how to notify them.
* **Define a Contract**: Create an `IObserver` interface with a single method like `onUpdate(tick)`. This `IObserver` interface is the contract that all consumers must implement to receive updates. The `PriceFeed` will only interact with this interface, not caring about the concrete consumer types.
* **Program to Interface**: `PriceFeed` stores a list of `IObserver*`. It doesn't care if the pointer is a UI, a Logger, or a Risk Monitor. All it knows is that it can call `onUpdate(tick)` on each observer when a new tick arrives. This allows us to add new consumer types in the future without modifying `PriceFeed`. The new consumer just needs to implement the `IObserver` interface and register itself with the `PriceFeed`.
* **Runtime Management**: Provide `attach()` and `detach()` methods to manage the listener list dynamically. These methods allow consumers to subscribe and unsubscribe at runtime without affecting the `PriceFeed` logic.   

#### **Components involved and their responsibilities**

* **Subject Interface `IPriceSubject`** - Purpose of `IPriceSubject` is to define the contract for the Subject, ensuring that any concrete implementation (like `PriceFeed`) adheres to the expected behavior of managing observers and notifications. This abstraction allows for flexibility in how the Subject is implemented while maintaining a consistent interface for observers to interact with. It defines the essential methods (e.g., `attach()`, `detach()`, `notify()`) for attaching, detaching, and notifying observers, which are crucial for the Observer Pattern to function effectively. By programming to this interface, we can easily swap out different Subject implementations without affecting the observers, as long as they adhere to the same contract.

* **Subject `PriceFeed`**: Owns the state (latest tick) and the list of observers. It provides an API for attaching/detaching and triggers the notification loop. It is the "broadcaster" that doesn't care about who is listening, just that it needs to notify them. 
    * The `onNewTick()` method is the entry point for new data, and it simply calls `notify()` to broadcast to all observers. `notify()` iterates through the list of observers and calls their `onUpdate(tick)` method, ensuring that all registered observers receive the latest tick information.

    * `attach()` and `detach()` manage the list of observers, allowing for dynamic subscription.

* **Observer Interface (IPriceObserver)**: Defines the contract for observers. Any consumer that wants to receive updates must implement this interface. It ensures that all observers have a common method (`onUpdate(tick)`) that the Subject can call to notify them of changes. This interface abstracts away the specific implementation details of the observers, allowing the Subject to interact with them in a uniform way. By adhering to this interface, new consumer types can be added without modifying the Subject, as they will simply implement the required method to receive updates.

* **Concrete Observers (UI, AlertEngine, Logger)**: Each consumer implements its own reaction to the price change. For example, the UI might update a display, the AlertEngine might check if certain conditions are met to trigger alerts, and the Logger might write the tick to a file or database. Each observer is responsible for its own logic in response to the updates it receives from the Subject.

* **Client**: Connects specific consumers to the `PriceFeed` at runtime. The client is responsible for creating instances of the concrete observers and attaching them to the `PriceFeed`. This allows for flexibility in how the system is configured at runtime, as different observers can be attached or detached based on user interactions or other conditions.

#### **Capture the design visually (UML)**

```mermaid
classDiagram
direction LR

class IPriceObserver {
    <<interface>>
    +onUpdate(tick)
}

class IPriceSubject {
    <<interface>>
    +attach(observer)
    +detach(observer)
    +notify(tick)
}

class PriceFeed {
    -observers
    +attach(observer)
    +detach(observer)
    +onNewTick(symbol, price)
}

class UiTickerDisplay {
    +onUpdate(tick)
}

class AlertEngine {
    +onUpdate(tick)
}

class AuditLogger {
    +onUpdate(tick)
}

IPriceSubject <|.. PriceFeed
PriceFeed ..> IPriceObserver
IPriceObserver <|.. UiTickerDisplay
IPriceObserver <|.. AlertEngine
IPriceObserver <|.. AuditLogger

style IPriceObserver fill:#f2f2f2,stroke:#333,stroke-width:2px
style IPriceSubject fill:#f2f2f2,stroke:#333,stroke-width:2px
style PriceFeed fill:#e1f5fe,stroke:#01579b,stroke-width:2px
style UiTickerDisplay fill:#fff3e0,stroke:#e65100,stroke-width:2px
style AlertEngine fill:#fff3e0,stroke:#e65100,stroke-width:2px
style AuditLogger fill:#fff3e0,stroke:#e65100,stroke-width:2px
```

### **C++ Implementation**

First, we define the domain model for a stock tick, which includes the symbol and price.    

```cpp
// Domain Model: The data being observed
struct Tick {
    std::string symbol;
    double price;
};
```
Then, we define the Observer interface, which declares the `onUpdate` method that all observers must implement to receive updates from the Subject.   

```cpp
// Observer Interface (The Contract)
class IPriceObserver {
public:
    virtual ~IPriceObserver() = default;
    virtual void onUpdate(const Tick& tick) = 0;
};
```

We, then define the Subject interface, which declares methods for attaching, detaching, and notifying observers. This interface allows for different implementations of the Subject while maintaining a consistent way for observers to interact with it.

```cpp
// Subject Interface (The Broadcaster)
class IPriceSubject {
public:
    virtual ~IPriceSubject() = default;
    virtual void attach(IPriceObserver* observer) = 0;
    virtual void detach(IPriceObserver* observer) = 0;
    virtual void notify(const Tick& tick) = 0;
};
```

We then implement the `PriceFeed` class, which is a concrete implementation of the `IPriceSubject` interface. It maintains a list of observers and implements the logic for attaching, detaching, and notifying them when a new tick arrives.

```cpp
// Concrete Subject
class PriceFeed : public IPriceSubject {
private:
    std::vector<IPriceObserver*> observers;

public:
    // start receiving ticks from the market data source (simulated here)
    void attach(IPriceObserver* observer) override {
        observers.push_back(observer);
    }

    // Detach an observer by removing it from the list, it no longer receives updates
    void detach(IPriceObserver* observer) override {
        observers.erase(std::remove(observers.begin(), observers.end(), observer), observers.end());
    }

    // Notify all observers about the new tick
    void notify(const Tick& tick) override {
        for (auto* obs : observers) obs->onUpdate(tick);
    }

    // External event trigger
    void onNewTick(const std::string& symbol, double price) {
        Tick tick{symbol, price};

        // Market data arrives here, some processing can be done if needed (e.g., filtering, enrichment)

        // Notify all observers about the new tick
        notify(tick);
    }
};
```

Then come the concrete observers, which implement the `IPriceObserver` interface. Each observer defines its own logic for handling updates from the `PriceFeed`. For example, the `UiTickerDisplay` updates the UI, the `AlertEngine` checks for alert conditions, and the `AuditLogger` logs the tick information.

```cpp
// Concrete Observers (The Consumers)
class UiTickerDisplay : public IPriceObserver {
public:
    void onUpdate(const Tick& tick) override {
        std::cout << "[UI Ticker] " << tick.symbol << " is now $" << tick.price << "\n";
    }
};

class AlertEngine : public IPriceObserver {
public:
    void onUpdate(const Tick& tick) override {
        if (tick.price > 150.0) {
            std::cout << "[Alert] " << tick.symbol << " crossed $150 threshold!\n";
        }
    }
};

class AuditLogger : public IPriceObserver {
public:
    void onUpdate(const Tick& tick) override {
        std::cout << "[Audit] Logged tick for " << tick.symbol << " at " << tick.price << "\n";
    }
};
```

Finally, we have the client code that wires everything together. It creates an instance of `PriceFeed`, attaches various observers to it, and simulates incoming ticks to demonstrate how the observers react to updates.

```cpp
// Client: Wiring it all together
int main() {
    PriceFeed nasdaqFeed;

    UiTickerDisplay ui;
    AlertEngine alerts;
    AuditLogger logger;

    // Attach consumers at runtime
    nasdaqFeed.attach(&ui);
    nasdaqFeed.attach(&alerts);
    nasdaqFeed.attach(&logger);

    std::cout << "--- Tick 1 ---\n";
    nasdaqFeed.onNewTick("AAPL", 145.20);

    std::cout << "\n--- Tick 2 (Price spike) ---\n";
    nasdaqFeed.onNewTick("AAPL", 152.45);

    // Dynamic detach
    nasdaqFeed.detach(&ui);
    std::cout << "\n--- Tick 3 (UI closed) ---\n";
    nasdaqFeed.onNewTick("TSLA", 680.00);

    return 0;
}
```

### Conclusion
The Observer Pattern allows us to keep the `PriceFeed` class decoupled from the specific consumers. The `PriceFeed` only knows about the `IPriceObserver` interface, and any consumer that implements this interface can subscribe to receive updates. This design adheres to the Open-Closed Principle, as we can add new consumer types without modifying the `PriceFeed` code. The dynamic attach/detach functionality also allows for flexible runtime behavior, making it easy to manage which consumers are active at any given time.