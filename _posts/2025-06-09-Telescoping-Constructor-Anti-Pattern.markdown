---
layout: post
title: 🔭 The Telescoping Constructor - An Anti-Pattern to Avoid
date: 2025-06-09 00:29:02 +0530
categories: design-patterns
mathjax: true
# hero_image: /assets/images/ocp_hero.jpg # Or whatever your image path is
# thumbnail: /assets/images/ocp_thumbnail.jpg # For smaller previews/cards
description: The Telescoping Constructor - An Anti-Pattern to Avoid
---

In the world of software development, we often focus on learning powerful *design patterns*. But just as important is learning to recognize *anti-patterns*—common solutions that seem like a good idea at first but lead to significant problems down the road. Today, we're putting one of the most common anti-patterns under the microscope: the **Telescoping Constructor**.

It all starts innocently. You have an object. You need to create it. You write a constructor. Then, your object needs a few optional settings. So, you add another constructor. And then another. And another. Soon, you have a "telescope" of constructors, each one longer than the last, and you've unknowingly created a maintenance nightmare.

Let's dive into what this looks like and why it's a code smell you should learn to spot immediately.

## 🍕 What Does it Look Like? The Pizza Example

There's no better way to understand this anti-pattern than by trying to model something we all love: a pizza. A pizza has a required `type` (like "Margherita" or "Farmhouse"), but then a list of optional toppings. Let's try to model this using constructors in C++.

```cpp
#include <string>
#include <iostream>

class Pizza {
private:
    std::string m_type;
    bool m_hasExtraCheese = false;
    bool m_hasPepperoni = false;
    bool m_hasMushrooms = false;

public:
    // 1. Base constructor
    Pizza(const std::string& type) {
        m_type = type;
    }

    // 2. Telescope: Add extra cheese
    Pizza(const std::string& type, bool extraCheese) : Pizza(type) {
        m_hasExtraCheese = extraCheese;
    }

    // 3. Telescope: Add pepperoni
    Pizza(const std::string& type, bool extraCheese, bool pepperoni) : Pizza(type, extraCheese) {
        m_hasPepperoni = pepperoni;
    }

    // 4. Telescope: Add mushrooms
    Pizza(const std::string& type, bool extraCheese, bool pepperoni, bool mushrooms) : Pizza(type, extraCheese, pepperoni) {
        m_hasMushrooms = mushrooms;
    }

    void display() const {
        std::cout << "Pizza Type: " << m_type << std::endl;
        if (m_hasExtraCheese) std::cout << " - Extra Cheese" << std::endl;
        if (m_hasPepperoni) std::cout << " - Pepperoni" << std::endl;
        if (m_hasMushrooms) std::cout << " - Mushrooms" << std::endl;
        std::cout << "---" << std::endl;
    }
};
````
This looks clean enough in the class definition. But the moment you, the "customer," try to order a pizza, the problems become obvious.


## 😳 The Breakdown: Why It's an Anti-Pattern ?

Here are the four key reasons why the code above will cause you and your team headaches.

* 🧩 **1. The Puzzle of Parameter Order**

    When you create an object using the longest constructor, the call becomes cryptic.

    ```cpp
    // Client Code
    int main() {
        // What does 'true, false, true' mean here?
        Pizza myPizza("Deep Dish", true, false, true);
        myPizza.display();
    }
    ````
* 🐛 **2. The High Risk of Bugs**

    This lack of readability leads directly to bugs. Since the optional parameters are all of the same type (`bool`), you can easily mix them up, and the compiler won't warn you.

    ```cpp
    // I wanted extra cheese and mushrooms, but no pepperoni.
    // Did I get the order right?
    Pizza anotherPizza("Thin Crust", true, true, false); // Oops! I got cheese and pepperoni.
    ````

* ⛓️ **3. The Chain of Inflexibility**

    The biggest issue is inflexibility.   
    
    What if you want mushrooms, but you DON'T want extra cheese or pepperoni ?

    You can't do it.

    The constructor chain forces you to provide a value for `extraCheese` and `pepperoni` just to get to the `mushrooms` parameter. The only way around it is to pass "dummy" values that you don't care about.

    ```cpp
    // I want a Margherita with mushrooms. That's it.
    // I'm forced to pass 'false' for cheese and pepperoni.
    Pizza mushroomPizza("Margherita", false, false, true);
    ````
    This is awkward and clutters the call with irrelevant information.


* 💣 **4. The Combinatorial Explosion**

    This anti-pattern is completely unscalable. We only have three optional toppings. What if we add three more: `onions`, `olives`, and `bacon`?

    To cover every possible combination of 6 toppings, you would need 2^6 = 64 constructors!  
    It is simply impossible to maintain. The moment your object has more than two or three optional parameters, this pattern collapses under its own weight.

## ✅ The Way Forward

When you see a telescoping constructor in your codebase, treat it as a "code smell". It's a sign that your object's creation logic is too complex for a simple constructor.

The solution isn't to write more constructors. The solution is to separate the object's construction from its representation. This is precisely what the **Builder Pattern** is designed to do, which allows you to build a complex object in a series of readable, flexible, and scalable steps.

## 🏁 Conclusion

The Telescoping Constructor is the classic example of a solution that works for simple cases but fails miserably as complexity grows. It creates code that is hard to read, easy to break, and impossible to scale. By learning to recognize this anti-pattern, you can proactively refactor your code towards more robust and maintainable solutions, making you a more effective developer.

---

*Like the article? Let’s connect on [LinkedIn](https://www.linkedin.com/in/onkarnm/).* 

⭐ ⭐ ⭐