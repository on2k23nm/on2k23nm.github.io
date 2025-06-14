---
layout: default
title: "Liskov Substitution Principle (LSP) in C++ – Spot & Fix Hierarchy Breaks"
seo_h1: Liskov Substitution Principle (LSP) in C++ – A SOLID Design Principle You Must Master
date: 2025-06-05 00:29:01 +0530
categories: software-design
tags: [SOLID Design Principles]
mathjax: true
description: Master SOLID’s Liskov Substitution Principle (LSP) in C++—see why it matters, spot hierarchy violations, and refactor with real-world examples.
---

## 🌟 Introduction

Welcome back to our ongoing exploration of the SOLID design principles! In this series, we're delving into the foundational concepts that guide us toward crafting software that is not only functional but also robust, maintainable, and scalable. So far, we've covered the [Single Responsibility Principle (SRP)](../02/SOLID-Design-Single-Responsibility-Principle.html), which helps us keep our classes focused, and the [Open/Closed Principle (OCP)](../02/SOLID-Design-Open-Closed-Principle.html), which encourages us to design systems that are extensible without requiring modification to existing code.

Today, we turn our attention to the "L" in SOLID: the **Liskov Substitution Principle (LSP)**. At its core, LSP is all about ensuring that our abstractions are correct and that inheritance hierarchies behave as expected. It's a crucial principle for building reliable object-oriented systems, as it dictates how subtypes should relate to their base types.

## 🤝 What is the Liskov Substitution Principle?

The _Liskov Substitution Principle_ was introduced by Barbara Liskov during a keynote conference in 1987 titled _"Data Abstraction and Hierarchy"_. The formal definition is as follows:

> "Let $$\phi(x)$$ be a property provable about objects $$x$$ of type $$T$$. Then $$\phi(y)$$ should be true for objects $$y$$ of type $$S$$ where $$S$$ is a subtype of $$T$$."

In simpler terms, this means:

> Objects of a superclass should be replaceable with objects of its subclasses without breaking the application or causing unexpected behavior.  

_If you have a piece of code that works with a base class, it should also work correctly if you pass in an object of any of its derived classes. The subclass must honor the contract of the superclass_.This means the subclass must behave in a way that is consistent with the behavior of the superclass from the perspective of any client code. It's not just about matching method signatures; it's about preserving **behavioral integrity**.

---

## 🧩 Illustrating LSP: Classic Rectangle vs. Square Problem

One of the most famous examples used to demonstrate LSP is the relationship between a rectangle and a square. Mathematically, a square *is a* rectangle. This might lead us to model it using public inheritance in C++, but let's see why this can cause behavioral problems.

### 🔻The Problem: A Violation of LSP

Let's start with a simple `Rectangle` class. It has methods to set and get its width and height and a method to calculate the area. Note that the setters are `virtual` to allow subclasses to override them.

```cpp
// Rectangle.h
class Rectangle {
protected:
    int m_width;
    int m_height;

public:
    Rectangle(int width, int height) : m_width(width), m_height(height) {}

    virtual void setWidth(int width) { m_width = width; }
    virtual void setHeight(int height) { m_height = height; }

    int getWidth() const { return m_width; }
    int getHeight() const { return m_height; }
    int getArea() const { return m_width * m_height; }
};
````

Now, let's create some client code that operates on a reference to a `Rectangle`. This function sets the width and height and then asserts that the area is as expected.

```cpp
// client_code.h
#include <cassert> // For assert()
#include <iostream>

void useRectangle(Rectangle& r) {
    r.setWidth(10);
    r.setHeight(5);

    int expectedArea = 50;
    int actualArea = r.getArea();
    std::cout << "Expected Area: " << expectedArea << ", Got: " << actualArea << std::endl;
    assert(actualArea == expectedArea);
}
````

This works perfectly with our `Rectangle` class. Now, let's create a `Square` class. Since a square is a type of rectangle, we'll make it inherit from `Rectangle`. To maintain the property of a square (where width and height must be equal), we `override` the setters.

```cpp
// Square.h (The Wrong Way)
#include "Rectangle.h"

class Square : public Rectangle {
public:
    Square(int side) : Rectangle(side, side) {}

    void setWidth(int width) override {
        m_width = width;
        m_height = width; // Also set height to maintain the square property
    }

    void setHeight(int height) override {
        m_width = height; // Also set width
        m_height = height;
    }
};
````

What happens when we pass our `Square` object to the `useRectangle` function?

```cpp
// main.cpp
#include "Rectangle.h"
#include "Square.h"
#include "client_code.h"

int main() {
    Rectangle rect(2, 2);
    Square sq(2);

    std::cout << "Testing Rectangle:\n";
    useRectangle(rect);    // This will pass

    std::cout << "\nTesting Square:\n";
    useRectangle(sq);      // This will FAIL!

    return 0;
}
````

**Output:**

```text
Testing Rectangle:
Expected Area: 50, Got: 50

Testing Square:
Expected Area: 50, Got: 25
main: client_code.h:9: void useRectangle(Rectangle&): Assertion `actualArea == expectedArea' failed.
````

The assertion fails! The client code, which only knows it has a `Rectangle`, sets the `height` to 5. But in the `Square` subclass, this action has a side effect: it also changes the `width` to 5. The behavior of the `Square` object is not consistent with the behavior of the base `Rectangle` class from the client's perspective. The behavioral contract is broken. This is a clear violation of LSP.

### 🎨 The Solution: Rethinking the Hierarchy

The issue here is that the "is-a" relationship from mathematics doesn't always translate to a behavioral "is-a" relationship suitable for public inheritance. The fix is to not force an inheritance model that doesn't fit the behavior.

A better approach is to use a more generic abstraction. We can define an abstract `Shape` class with a pure virtual `getArea` function, and have `Rectangle` and `Square` implement it independently.

```cpp
// Shape.h (The Right Way)
class Shape {
public:
    virtual ~Shape() = default; // Always provide a virtual destructor in a base class
    virtual int getArea() const = 0; // Pure virtual function makes Shape an abstract class
};

// Rectangle.h (Refactored)
#include "Shape.h"
class Rectangle : public Shape {
    int m_width;
    int m_height;
public:
    Rectangle(int width, int height) : m_width(width), m_height(height) {}
    int getArea() const override { return m_width * m_height; }
};

// Square.h (Refactored)
#include "Shape.h"
class Square : public Shape {
    int m_side;
public:
    Square(int side) : m_side(side) {}
    int getArea() const override { return m_side * m_side; }
};
````

In this refactored design, there's no incorrect assumption about behavior. A client function would be written to work with a `const Shape&` if it only needs the area. This design respects LSP because no subtype breaks the contract of its parent (`Shape`). If a client needs to set width and height independently, it should require a `Rectangle`, not a generic `Shape`.

#### 🔷 The Polymorphic Client: Working with any `Shape`
If a client function only cares about behavior that is common to all shapes (like calculating the area), it should depend on the abstract `Shape` class. This allows the function to work with any `Shape` subtype, now and in the future, without modification.

```cpp
// shape_client.h
#include <iostream>
#include "Shape.h" // Depends on the abstraction, not a concrete class

// This function works with any object that IS-A Shape.
// It uses `const&` because it doesn't need to modify the shape.
void printArea(const Shape& shape) {
    std::cout << "The area is: " << shape.getArea() << std::endl;
}
````

This function fully respects the Open/-Closed Principle. If we later add a `Circle` or `Triangle` class that inherits from `Shape`, we can pass them to `printArea` without changing a single line of its code.

#### 🟥 The Specific Client: Working with a `Rectangle`
If a client function needs behavior that is specific to a `Rectangle` (like setting its width and height independently), it should require a concrete `Rectangle`.

```cpp
// rectangle_client.h
#include <iostream>
#include "Rectangle.h" // Depends on the concrete Rectangle

// This function needs to modify a Rectangle specifically.
void resizeRectangle(Rectangle& rect, int newWidth, int newHeight) {
    rect.setWidth(newWidth);
    rect.setHeight(newHeight);
    std::cout << "Rectangle resized to " << newWidth << "x" << newHeight << std::endl;
}
````

This function's signature is now a clear contract: "Give me a `Rectangle`, because I need to set its width and height." You cannot accidentally pass a `Square` to it, because a `Square` no longer inherits from `Rectangle`. This prevents the original runtime bug by turning it into a compile-time error.

#### 🎬 Putting It All Together in `main()`

Here is how you would use these client functions:

```cpp
// main.cpp
#include "Rectangle.h" // The new, refactored Rectangle
#include "Square.h"    // The new, refactored Square
#include "shape_client.h"
#include "rectangle_client.h"

int main() {
    // Create instances of our concrete shapes
    Rectangle rect(5, 10);
    Square sq(7);

    // Use the polymorphic client that works with any Shape
    std::cout << "Using the polymorphic printArea function:\n";
    printArea(rect); // Works perfectly
    printArea(sq);   // Works perfectly

    std::cout << "\n";

    // Use the specific client that only works with Rectangle
    std::cout << "Using the specific resizeRectangle function:\n";
    resizeRectangle(rect, 20, 30); // Works perfectly

    // resizeRectangle(sq, 15, 15); // This would cause a COMPILE ERROR!
    // The compiler correctly stops us, because a Square is not a Rectangle.
    // This is much better than a runtime assertion failure.

    return 0;
}
````

This demonstrates the power of LSP. By ensuring our inheritance hierarchies model behavior correctly, we create systems that are both flexible (thanks to polymorphism with the `Shape` class) and safe (by preventing incorrect substitutions at compile time).

## 🔍 LSP Red Flags & Quick Checks

While the Rectangle/Square problem is a clear-cut example, LSP violations in real-world applications can be more subtle. Here are some common red flags and pitfalls to watch out for in your own code:

### 🧯 Type-checking in Client Code:   

> If you find yourself writing code that checks for the specific type of an object before deciding how to act, you are likely violating LSP.  

Code like `if (dynamic_cast<Square*>(shape_ptr))` is a major warning sign that your abstractions are not correctly substitutable. The client should be able to operate through the base class interface without needing to know the concrete implementation.

* ❌ **The Bad Example: Violating LSP**

    In this scenario, a function `renderShape()` needs to draw different shapes. However, instead of trusting the polymorphism, it checks the specific type of shape to decide how to act. It gives special treatment to a `Circle` by printing its radius, which is a behavior not present in the base `Shape` class.

    ```cpp
    #include <iostream>
    #include <string>

    // --- Base Class and Subclasses ---

    class Shape {
    public:
        virtual ~Shape() = default;
        virtual std::string getName() const = 0; // Common behavior
    };

    class Rectangle : public Shape {
    public:
        std::string getName() const override { return "Rectangle"; }
    };

    class Circle : public Shape {
    public:
        std::string getName() const override { return "Circle"; }
        // Behavior specific to Circle
        double getRadius() const { return 5.0; }
    };


    // --- Client Code that Violates LSP ---

    // This function checks the type of the shape, breaking the abstraction.
    void renderShape(const Shape* shape_ptr) {
        std::cout << "Rendering a " << shape_ptr->getName() << ". ";

        // This is the specific violation mentioned in the document.
        // The client code checks for a specific subtype.
        if (const Circle* circle_ptr = dynamic_cast<const Circle*>(shape_ptr)) {
            // Special behavior for Circle that is not in the Shape contract.
            std::cout << "It's a Circle with radius: " << circle_ptr->getRadius();
        }
        
        std::cout << std::endl;
    }


    int main() {
        Rectangle rect;
        Circle circle;
        
        std::cout << "--- Bad Example (Violating LSP) ---" << std::endl;
        renderShape(&rect);   // Works, but the if-statement is a bad sign.
        renderShape(&circle); // Gets special treatment.
        
        // What happens when we add a new shape?
        // We would have to modify renderShape() with another if-check.
        // This violates the Open/Closed Principle.
        
        return 0;
    }
    ````

* 🤔 **Why this is a problem:**

    The `renderShape` function is not truly polymorphic. It has to know about the existence of the `Circle` subclass to call its specific `getRadius()` method. If you add a new `Triangle` class, you don't have to change anything. But if you add a `Sphere` class that has a radius, you would need to modify `renderShape` with *another* `if` statement, which violates the Open/Closed Principle.

* ✅ **The Good Example: Adhering to LSP**

    The solution is to ensure that any behavior the client needs is part of the base class's contract (the public interface). If different shapes need to be drawn differently, that logic should be encapsulated within the shapes themselves via a virtual function.

    ```cpp
    #include <iostream>
    #include <string>
    #include <sstream>

    // --- Corrected Base Class and Subclasses ---

    class Shape {
    public:
        virtual ~Shape() = default;
        // The "drawing" or "description" logic is now part of the base contract.
        virtual std::string getDescription() const = 0; 
    };

    class Rectangle : public Shape {
    public:
        std::string getDescription() const override {
            return "I am a Rectangle.";
        }
    };

    class Circle : public Shape {
    private:
        double radius = 5.0;
    public:
        std::string getDescription() const override {
            // The specific logic is inside the subclass, not the client.
            std::stringstream ss;
            ss << "I am a Circle with radius: " << radius;
            return ss.str();
        }
    };


    // --- Client Code that Adheres to LSP ---

    // This function now works with any Shape, past, present, or future,
    // without needing to know the specific subtype.
    void renderCorrectly(const Shape& shape) {
        std::cout << "Rendering shape -> " << shape.getDescription() << std::endl;
    }


    int main() {
        Rectangle rect;
        Circle circle;

        std::cout << "\n--- Good Example (Adhering to LSP) ---" << std::endl;
        renderCorrectly(rect);
        renderCorrectly(circle);
        
        // If we add a new shape (e.g., Triangle), renderCorrectly()
        // works without any changes.
        
        return 0;
    }
    ````
* 💡 **Why this is the solution:**

    The `renderCorrectly` function now operates purely through the `Shape` interface. It doesn't care if the object is a `Rectangle`, `Circle`, or any other future shape. It just calls the `getDescription()` method, and polymorphism ensures the correct version is executed. This respects the abstraction and makes the system much more flexible and maintainable.

### 🧊 Empty or No-Op Method Overrides:

> Be cautious when a subclass provides an empty implementation for an inherited method.

For example, imagine a `Bird` base class with a `fly()` method. If you create an `Ostrich` subclass that inherits from `Bird`, its implementation of `fly()` would likely be empty or throw an exception. This violates LSP because the `Ostrich` object doesn't fulfill the behavioral contract of a `Bird` that can fly. The client is surprised when `fly()` does nothing.

The principle being violated here is that a subclass must honor the behavioral contract of its parent. If a client has a `Bird` object and calls its `fly()` method, it has a reasonable expectation that the action of flying will occur. An empty or no-op (no operation) implementation in a subclass breaks this expectation, leading to subtle and hard-to-find bugs.

* ❌ **The Problem: A Design that Violates LSP**

    First, let's model the incorrect hierarchy where an `Ostrich` is forced to have a `fly()` method.

    ```cpp
    #include <iostream>

    // Base class with a clear behavior
    class Bird {
    public:
        virtual ~Bird() = default;
        virtual void fly() const {
            std::cout << "This bird is flying high!" << std::endl;
        }
    };

    // A Sparrow is a Bird that flies, so this is fine.
    class Sparrow : public Bird {
        // Inherits the standard fly() behavior
    };

    // An Ostrich is a Bird, but it can't fly.
    // Here we override fly() to do nothing. This is the LSP violation.
    class Ostrich : public Bird {
    public:
        void fly() const override {
            // No-op: Do nothing. The contract is broken.
            // Alternatively, one might throw an exception, which also violates LSP.
        }
    };
    ````

    Now, let's create a client function that wants to make a group of birds fly. This function has no idea what specific *kind* of bird it's dealing with; it only knows it has a `Bird`.

    ```cpp
    // Client code that expects all birds to fly
    void makeTheBirdFly(const Bird& bird) {
        std::cout << "Attempting to make the bird fly..." << std::endl;
        bird.fly(); // The client expects this to *do something*.
    }

    int main() {
        Sparrow sparrow;
        Ostrich ostrich;

        std::cout << "--- Testing the Sparrow ---" << std::endl;
        makeTheBirdFly(sparrow);

        std::cout << "\n--- Testing the Ostrich ---" << std::endl;
        makeTheBirdFly(ostrich); // The code runs, but the logic is flawed.
    }
    ````

    Output:

    ```
    --- Testing the Sparrow ---
    Attempting to make the bird fly...
    This bird is flying high!

    --- Testing the Ostrich ---
    Attempting to make the bird fly...
    ```

    The program doesn’t crash, but it is incorrect. The client code is *“surprised”* that calling `fly()` on the `Ostrich` object resulted in nothing happening. The `Ostrich` class is not behaviorally substitutable for the `Bird` class, thus violating LSP.

* 💡 **The Solution: Segregate Behaviors into Interfaces**

    The problem isn’t that an Ostrich can’t fly; the problem is that we forced it to pretend it could by inheriting the `fly()` method. The solution is to not force unrelated behaviors on classes. We can achieve this by separating the **ability to fly** from the general concept of a `Bird`.

    > This is a perfect preview of the next SOLID principle, the **Interface Segregation Principle**.

    ```cpp
    #include <iostream>

    // 1. Create a small, specific interface for the "flying" behavior.
    class IFlyable {
    public:
        virtual ~IFlyable() = default;
        virtual void fly() const = 0; // Pure virtual function
    };

    // 2. The base Bird class no longer has fly(). It only has common bird behaviors.
    class Bird {
    public:
        virtual void eat() const {
            std::cout << "This bird is eating." << std::endl;
        }
        virtual ~Bird() = default;
    };

    // 3. A Sparrow IS-A Bird and it IS-A IFlyable. It inherits from both.
    class Sparrow : public Bird, public IFlyable {
    public:
        void fly() const override {
            std::cout << "Sparrow is soaring through the sky!" << std::endl;
        }
    };

    // 4. An Ostrich IS-A Bird, but it is NOT an IFlyable.
    class Ostrich : public Bird {
        // No fly() method here. It cannot be forced to do something it can't.
    };
    ```

    Now, the client code becomes much more honest and safe. A function that needs a flying creature must ask for one explicitly.

    ```cpp
    // This client needs an object that can fly. It asks for an IFlyable.
    void makeItFly(const IFlyable& flyingCreature) {
        std::cout << "Making it fly..." << std::endl;
        flyingCreature.fly();
    }

    int main() {
        Sparrow sparrow;
        Ostrich ostrich;

        // We can pass a Sparrow to a function that needs something that can fly.
        makeItFly(sparrow);

        // makeItFly(ostrich); // THIS CAUSES A COMPILE-TIME ERROR!
        // The compiler saves us from the runtime logic error.
        // Error: 'Ostrich' is not derived from 'IFlyable'
    }
    ```

    By separating the flying behavior into its own interface (`IFlyable`), we've created a much more robust design. The compiler can now verify that we are not trying to make a non-flying bird fly.  
    This turns a subtle runtime bug into an obvious compile-time error, which is always a massive improvement.

### 🔥 Throwing New or Broader Exceptions:  
> A subtype should not throw exception types that the supertype's method doesn't. 

If a client has a `catch` block prepared for exceptions thrown by a base class method, it should not be surprised by a completely new type of exception from a derived class object. This breaks the client's error-handling strategy. The contract of a method includes not just its parameters and return type, but also the exceptions it may throw. A client writes its `try...catch` blocks based on this contract. If a subclass method breaks this contract by throwing a new, unexpected exception type, it's no longer safely substitutable for its parent.

📘 **The Scenario**

Imagine we have a system for parsing configuration data. The base class defines a contract for parsing, and it can fail in a specific way.

* ❌ **The Problem: A Design that Violates LSP**

    Here, the `ConfigParser` base class is designed to throw a specific `ParseException` if the data is malformed.  
    The client code will be built to handle only that exception.

    ```cpp
    #include <iostream>
    #include <string>
    #include <stdexcept>

    // 1. Define a specific exception for our parsing module
    class ParseException : public std::exception {
    public:
        const char* what() const noexcept override {
            return "Error: Malformed configuration data!";
        }
    };

    // 2. The base class contract: parse() might throw ParseException
    class ConfigParser {
    public:
        virtual ~ConfigParser() = default;
        virtual void parse(const std::string& data) {
            if (data.empty()) {
                throw ParseException();
            }
            std::cout << "Parsing successful." << std::endl;
        }
    };

    // 3. A subclass that violates the contract by throwing a different exception
    class DbConfigParser : public ConfigParser {
    private:
        bool m_isConnected = false;
    public:
        DbConfigParser(bool connected) : m_isConnected(connected) {}

        void parse(const std::string& data) override {
            if (!m_isConnected) {
                throw std::runtime_error("Error: Database connection failed!");
            }
            ConfigParser::parse(data);
        }
    };
    ```
* ⚠️ **Consequences of Violation**

    Now, let's write a client function. This function is written carefully according to the `ConfigParser` contract, so it only expects to catch `ParseException`.

    ```cpp
    // Client code that is only prepared for ParseException
    void loadSettings(ConfigParser& parser, const std::string& data) {
        try {
            std::cout << "Attempting to load settings..." << std::endl;
            parser.parse(data);
            std::cout << "Settings loaded successfully." << std::endl;
        }
        catch (const ParseException& e) {
            std::cerr << "Caught a known issue: " << e.what() << std::endl;
            std::cerr << "Falling back to default settings." << std::endl;
        }
    }

    int main() {
        // Scenario 1: Base class failure (works as expected)
        ConfigParser fileParser;
        loadSettings(fileParser, ""); // Empty data will throw ParseException

        std::cout << "\n----------------------------------\n\n";

        // Scenario 2: Subclass throws an UNEXPECTED exception (crashes the program)
        DbConfigParser dbParser(false); // Fails to connect
        loadSettings(dbParser, "some_data"); // Throws std::runtime_error
    }
    ```

    **🧨 Output:**

    ```
    Attempting to load settings...
    Caught a known issue: Error: Malformed configuration data!
    Falling back to default settings.

    ----------------------------------

    Attempting to load settings...
    terminate called after throwing an instance of 'std::runtime_error'
    what():  Error: Database connection failed!
    Aborted
    ```

* ✅ **The Solution: Establish a Common Exception Hierarchy**

    The solution is to ensure all subclasses adhere to the exception contract. A good way to do this is to define a common base exception class for the entire module.

    ```cpp
    #include <iostream>
    #include <string>
    #include <stdexcept>

    // 1. A common base exception for the whole module
    class ConfigException : public std::exception {
    public:
        const char* what() const noexcept override {
            return "A configuration error occurred!";
        }
    };

    // 2. More specific exceptions that DERIVE from the base exception
    class ParseException : public ConfigException {
    public:
        const char* what() const noexcept override {
            return "Malformed configuration data!";
        }
    };

    class SourceAccessException : public ConfigException {
    public:
        const char* what() const noexcept override {
            return "Could not access the configuration source!";
        }
    };

    // 3. The base class contract: parse() might throw ConfigException or its children
    class ConfigParser {
    public:
        virtual ~ConfigParser() = default;
        virtual void parse(const std::string& data) {
            if (data.empty()) throw ParseException();
            std::cout << "Parsing successful." << std::endl;
        }
    };

    // 4. The subclass now throws an exception that IS-A ConfigException
    class DbConfigParser : public ConfigParser {
    private:
        bool m_isConnected = false;
    public:
        DbConfigParser(bool connected) : m_isConnected(connected) {}

        void parse(const std::string& data) override {
            if (!m_isConnected) {
                throw SourceAccessException(); // This is allowed!
            }
            ConfigParser::parse(data);
        }
    };
    ```

* 🧪 **With this corrected hierarchy**

    ```cpp
    // The corrected client can now handle any ConfigException
    void loadSettings(ConfigParser& parser, const std::string& data) {
        try {
            std::cout << "Attempting to load settings..." << std::endl;
            parser.parse(data);
            std::cout << "Settings loaded successfully." << std::endl;
        }
        catch (const ConfigException& e) {
            std::cerr << "Caught configuration error: " << e.what() << std::endl;
            std::cerr << "Falling back to default settings." << std::endl;
        }
    }

    int main() {
        // This test now works as expected
        ConfigParser fileParser;
        loadSettings(fileParser, "");

        std::cout << "\n----------------------------------\n\n";

        // This test is now caught correctly and does NOT crash
        DbConfigParser dbParser(false);
        loadSettings(dbParser, "some_data");
    }
    ```

    🟢 Corrected Output:

    ```
    Attempting to load settings...
    Caught configuration error: Malformed configuration data!
    Falling back to default settings.

    ----------------------------------

    Attempting to load settings...
    Caught configuration error: Could not access the configuration source!
    Falling back to default settings.
    ```

    By having the client catch the base exception type (`ConfigException`), we make our error-handling strategy robust and compliant with LSP. The program is no longer surprised, and the substitutability of our objects is preserved.


### 🧨 Violating the Class Invariants (The Contract): 

> LSP is fundamentally about honoring the contract of the base class. A subtype should not strengthen the preconditions (i.e., be more restrictive about its inputs) or weaken the postconditions (i.e., fail to deliver on all the promises of the base method).  

Our `Square` example violated the postcondition of `setHeight` - the promise that only the height would change was broken.

In the context of the Liskov Substitution Principle, the "contract" refers to the documented and expected behavior of a class and its methods. This contract is defined by its invariants, preconditions, and postconditions.

- **Precondition**: A condition that must be true *before* a method is called. To comply with LSP, a subclass method **must not strengthen** its preconditions. In other words, it must be able to handle at least all the same inputs as the base class method.

- **Postcondition**: A condition that must be true *after* a method completes successfully. To comply with LSP, a subclass method **must not weaken** its postconditions. It must deliver on all the promises made by the base class method, and then some.

Violating either of these breaks the substitutability of the subclass. Let's look at a code example for each.

* ❌ **Weakening a Postcondition (The Broken Promise)**

    As your screenshot rightly points out, our original `Rectangle / Square` example is a perfect illustration of a weakened postcondition.

    Let's formally define the contract for `Rectangle::setHeight`:

    - **Method**: `virtual void setHeight(int height)`
    - **Postcondition**:
    1. The rectangle's height will be set to the new `height` value.
    2. The rectangle's width will **remain unchanged**.

    The `Square` subclass fails to honor the second part of this promise.

    ```cpp
    #include <iostream>
    #include <cassert>

    class Rectangle {
    protected:
        int m_width, m_height;
    public:
        Rectangle(int w, int h) : m_width(w), m_height(h) {}

        virtual void setHeight(int height) {
            m_height = height;
        }

        int getWidth() const { return m_width; }
        int getHeight() const { return m_height; }
    };

    class Square : public Rectangle {
    public:
        Square(int side) : Rectangle(side, side) {}

        void setHeight(int height) override {
            m_height = height;
            m_width = height; // This breaks the postcondition of the base class
        }
    };

    // This client relies on the postcondition of Rectangle::setHeight
    void clientCode(Rectangle& r) {
        int original_width = r.getWidth();
        r.setHeight(20);
        // The client assumes width is unchanged.
        std::cout << "Original width: " << original_width << ", New width: " << r.getWidth() << std::endl;
        assert(r.getWidth() == original_width); // This assertion relies on the postcondition
    }

    int main() {
        Square sq(10);
        std::cout << "Testing Square...\n";
        clientCode(sq); // This will fail
    }
    ```

    **Output:**
    ```
    Testing Square...
    Original width: 10, New width: 20
    main: main.cpp:32: void clientCode(Rectangle&): Assertion `r.getWidth() == original_width' failed.
    ```

    The `Square` class **weakened the postcondition** because it failed to guarantee that the width would remain unchanged. It broke a promise that was part of the base class contract, thus violating LSP.

* ❌ **Strengthening a Precondition (Rejecting What's Allowed)**

    A subclass violates LSP if it's more restrictive about its inputs than its base class.

    **Scenario:** Let's model a system that processes orders. The base `OrderProcessor` can process any order with a positive value.

    **The Problem:** A `PremiumOrderProcessor` subclass decides it will only process orders of $50 or more.

    ```cpp
    #include <iostream>
    #include <stdexcept>
    #include <string>

    // The base class can process any order with a positive value.
    class OrderProcessor {
    public:
        virtual ~OrderProcessor() = default;

        // PRECONDITION: amount > 0
        virtual void processOrder(double amount) {
            if (amount <= 0) {
                throw std::invalid_argument("Order amount must be positive.");
            }
            std::cout << "Processing standard order of $" << amount << std::endl;
        }
    };

    // This subclass strengthens the precondition.
    class PremiumOrderProcessor : public OrderProcessor {
    public:
        // NEW, STRONGER PRECONDITION: amount >= 50
        void processOrder(double amount) override {
            if (amount < 50) {
                // This is a new restriction not present in the base class.
                throw std::domain_error("Premium processor only handles orders of $50 or more.");
            }
            // It might call the base check as well
            OrderProcessor::processOrder(amount);
            std::cout << "Applying premium benefits..." << std::endl;
        }
    };

    // Client code written against the base class contract.
    // It assumes any positive order value is acceptable.
    void executeOrder(OrderProcessor& processor, double value) {
        try {
            std::cout << "Attempting to process an order for $" << value << std::endl;
            processor.processOrder(value);
            std::cout << "Order processed successfully." << std::endl;
        } catch (const std::exception& e) {
            std::cerr << "Error: " << e.what() << std::endl;
        }
    }

    int main() {
        OrderProcessor standardProcessor;
        PremiumOrderProcessor premiumProcessor;

        std::cout << "--- Testing a valid premium order ---\n";
        executeOrder(premiumProcessor, 100.0); // Works fine

        std::cout << "\n--- Testing an order that violates the SUBCLASS precondition ---\n";
        executeOrder(premiumProcessor, 25.0); // Fails unexpectedly for the client
    }
    ```

    **Output:**
    ```
    --- Testing a valid premium order ---
    Attempting to process an order for $100
    Processing standard order of $100
    Applying premium benefits...
    Order processed successfully.

    --- Testing an order that violates the SUBCLASS precondition ---
    Attempting to process an order for $25
    Error: Premium processor only handles orders of $50 or more.
    ```

    The client function `executeOrder` is surprised by this failure. According to the `OrderProcessor` contract it was coded against, a $25 order is perfectly valid. The `PremiumOrderProcessor` subclass **strengthened the precondition** by requiring `amount >= 50`.  
    Because it can no longer handle all the inputs that its base class could, it is **not substitutable** and violates LSP.

### 🛡️ Conclusion: Building Trust in Your Abstractions

The Liskov Substitution Principle is the architectural bedrock that makes polymorphism trustworthy. It moves beyond simple "is-a" relationships to enforce a much stronger "behaves-like-a" contract. By ensuring that a subclass is truly a behavioral substitute for its parent, we build systems that are more reliable, easier to maintain, and simpler to extend.

When we adhere to LSP, we create code that is less surprising. Functions can confidently operate on base class pointers or references, knowing that any derived class they receive will honor the expected behavior. This not only prevents subtle runtime bugs but also naturally supports the Open/Closed Principle, allowing us to add new functionality without destabilizing existing code.

So, the next time you design an inheritance hierarchy, ask yourself:   
> "Can an object of my subclass truly stand in for an object of my base class without anyone noticing?" If the answer is yes, you're on the right track.

Thank you for following along! In the next article in this series, we'll unravel the "I" in SOLID: the **Interface Segregation Principle**. Stay tuned!