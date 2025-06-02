---
layout: post
title:  "🧩 SOLID Design Principles, Part 2: Open/Closed Principle (OCP)"
date:   2025-06-02 00:29:09 +0530
categories: modern-cpp
---

## 🚀 About This Blog Series

This blog is **Part 2** of our deep-dive into the **SOLID Design Principles** — five foundational pillars of object-oriented design that help us build software systems that are easier to maintain, evolve, and reason about.

Each principle in this series is explored not just by definition, but through **first-principles reasoning**, real-world examples, and **C++-centric** illustrations that emphasize practical application.

In **Part 1**, we explored the **Single Responsibility Principle** and saw how splitting responsibilities across well-defined units leads to more testable and maintainable systems.

👉 If you missed Part 1, [read it here](/modern-cpp/2025/05/31/SOLID-Design-Principles-Part1-SRP.html)

Today, we move to the next pillar: the **Open/Closed Principle**.

## 🚪 Open/Closed Principle (OCP) 
> *A class should be open for extension but closed for modification.*

## 🧠 What Does Open/Closed Mean?

The **Open/Closed Principle** was introduced by Bertrand Meyer in 1988. It states:

> “Software entities (classes, modules, functions, etc.) should be open for extension, but closed for modification.”

This sounds contradictory at first. How can something be both *open* and *closed*?

Let’s decode this with a foundational lens.

- **Closed for modification** means:  
  Once a class has been implemented, tested, and released into production, it **should not be modified every time a new requirement comes in**. Every time you tweak that class, you risk breaking existing functionality, introducing regressions, or creating ripple effects across dependent code.

- **Open for extension** means:  
  The class should allow new behavior to be added — **without changing its source code**. This is typically achieved through techniques like **inheritance**, **interfaces**, **strategy patterns**, or **composition**.

In essence, OCP is a **contract for future growth**:  
> *“I won't change existing code, but I will extend behavior through abstraction.”*



## 🎯 Motivation: The Real-World Problem

Let’s consider a classic real-world problem in application development — payment processing.

Imagine a class called `PaymentProcessor` that supports credit card transactions. All is well until a new requirement comes in: support PayPal.

You might be tempted to modify the class like this:

```cpp
class PaymentProcessor {
public:
    void process(const Payment& payment) {
        if (payment.type == "CreditCard") {
            processCreditCard(payment);
        } else if (payment.type == "PayPal") {
            processPayPal(payment);
        }
        // And later maybe UPI, Bitcoin, etc...
    }
};
```

This is a clear violation of OCP. Every time a new payment method is added, you **edit** the class. Over time, the class becomes a dump of `if-else` or `switch` statements.

This design leads to:

- High coupling between payment logic and processor  
- Difficulties in unit testing specific behaviors  
- Repeated editing and re-testing of existing, stable code  
- Tight dependencies between modules

## ✅ The OCP-Compliant Refactoring

Let’s apply the Open/Closed Principle. We want to **avoid modifying** `PaymentProcessor`, but still support new payment types.

Here’s how we do it using **polymorphism** and the **strategy pattern**:

---

### Step 1: Define an abstract interface for payment strategies:

```cpp
class IPaymentStrategy {
public:
    virtual void process(const Payment& payment) = 0;
    virtual ~IPaymentStrategy() = default;
};
```

---

### Step 2: Implement concrete strategies for each payment type:

```cpp
class CreditCardPayment : public IPaymentStrategy {
public:
    void process(const Payment& payment) override {
        // Logic for credit card processing
    }
};

class PayPalPayment : public IPaymentStrategy {
public:
    void process(const Payment& payment) override {
        // Logic for PayPal processing
    }
};
```

---

### Step 3: Update the processor to depend only on the interface:

```cpp
class PaymentProcessor {
public:
    void processPayment(IPaymentStrategy& strategy, const Payment& payment) {
        strategy.process(payment);
    }
};
```

---

Now, when a new payment type (say `BitcoinPayment`) is needed, you simply **add a new class** without touching the existing `PaymentProcessor` code.  
 `PaymentProcessor` stays **closed for modification**, but **open for extension**.


## 🧠 Thinking from First Principles

At its heart, the Open/Closed Principle is about **designing for the future**. In large systems, requirements constantly evolve. If your only way to accommodate changes is by modifying existing classes, you create fragility.

> OCP flips this model: it encourages you to **build an extension point** into the system — a seam where new logic can be plugged in without destabilizing the rest of the code.

The **strategy pattern**, **inheritance-based polymorphism**, **dependency injection**, and **CRTP (Curiously Recurring Template Pattern)** in C++ are all practical tools for achieving this.


## 🔍 Why OCP Matters in Large Systems

- **Avoids regression**: You don't break existing behavior when you add new features.

- **Supports parallel development**: Teams can build new modules without stepping on each other’s toes.

- **Encourages composition and reuse**: Strategies or behaviors can be reused across different parts of the system.

- **Aligns with real-world evolution**: Requirements change constantly, but existing tested code should remain stable.

## 📌 Common Pitfalls to Watch For

- 📌 **1. Over-engineering**

    > Don’t create abstract base classes “just in case.” Apply OCP when you know extension is likely.

    ❌ Premature Abstraction

    ```cpp
    class IAnimal {
    public:
        virtual void makeSound() = 0;
    };

    class Dog : public IAnimal {
    public:
        void makeSound() override {
            std::cout << "Woof\n";
        }
    };
    ````
  ➡️ This is overkill if you’re only going to have one type (`Dog`). _There's no point adding abstraction if you have no current or anticipated need for extension._

- 📌 **2. Misuse of inheritance**

    > Prefer composition over inheritance unless inheritance is semantically correct.

    ❌ Inheritance used instead of composition:

    ```cpp
    class Button {
    public:
        void draw() { std::cout << "Drawing Button\n"; }
    };

    class SaveButton : public Button {
        // no added behavior — just using name difference
    };
````
    ➡️ There's no real specialization happening. This could be better handled with composition:  

    ✅ Better with composition:

    ```cpp
    class Button {
    public:
        void draw() { std::cout << "Drawing Button\n"; }
    };

    class SaveAction {
    public:
        void execute() { std::cout << "Saving data...\n"; }
    };

    class SaveButton {
        Button button;
        SaveAction action;
    public:
        void click() {
            button.draw();
            action.execute();
        }
    };
    ````

- 📌 **3. Leakage of implementation details**

    > Ensure abstractions hide complexity behind clear interfaces.

    ❌ Leaky abstraction:

    ```cpp
    class FileWriter {
    public:
        void write(const std::string& data) {
            // clients know it's writing to /tmp directly
            std::ofstream out("/tmp/data.txt");
            out << data;
        }
    };
    ```
    ➡️ This exposes where and how data is written. Clients are tightly coupled to file paths or formats.  

    ✅ Better abstraction:

    ```cpp
    class IWriter {
    public:
        virtual void write(const std::string& data) = 0;
        virtual ~IWriter() = default;
    };

    class FileWriter : public IWriter {
    public:
        void write(const std::string& data) override {
            std::ofstream out(getPath());
            out << data;
        }
    private:
        std::string getPath() { return "/tmp/data.txt"; }
    };
    ````

## 🌱 Final Thoughts

You don’t need to apply OCP everywhere. But in **modules expected to change frequently**,  
building in an extension mechanism upfront saves massive time and reduces risk in the long run.

As systems evolve, you’ll find that **stable core + pluggable extension points** is a sustainable way to scale.

---

## 📚 References

* Robert C. Martin — *Clean Architecture*, *Agile Principles, Patterns, and Practices*

