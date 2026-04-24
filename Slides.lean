/- Presentation for TACC -/
import VersoSlides
import Verso.Doc.Concrete
import Illuminate

open VersoSlides

set_option verso.code.warnLineLength 500

#doc (Slides) "TACC" =>

# A Short Tour of Lean 4

*Walter Moreira, PhD*

April 24th, 2026

# Overview

* An Approach to Crafting Software
* What is Lean 4?
* The Power of Strong Types
* A Scary Thing: Monads
* Things to Take Home

# An Approach to Crafting Software

I like to build systems that are proven correct by construction.

Two technologies that improve {class "myblue"}[safety], {class "myblue"}[correctness].
and  {class "myblue"}[reproducibilty]:

* *Nix*: a functional dependency managment tool that guarantees full _reproducibility_
* *Lean 4*: a strongly typed functional programming language that enables _correct_,
  _maintainable_, and _formally verified code_

# Managing Dependencies with Nix

*Nix* (`https://nixos.org`) is a simple functional programming language that describes
how to build arbitrary pipelines.

* _Inputs_: any dependency for the build, determined up to a cryptographic hash:
  - libraries
  - configuration
  - data

* _Outputs_: any artifact from the build, fully determined by the inputs

::::::fragment
:::vstack
This presentation is a Nix "flake" and uses Lean. Try it out!

```code "bash"
nix run github:waltermoreira/tacc-2026
```
:::
::::::

# What is Lean 4?

*Lean* is:

* A general purpose {class "myblue"}[Pure and Strongly Typed Functional Programming Language]
* An {class "mygreen"}[Interactive Theorem Prover]

::::::fragment
:::vstack
We'll concentrate on the {class "myblue"}[blue aspect] of Lean.

The main power of *Lean* vs. other strongly typed languages like *Rust*, *Java*,
or *C++*, is its {class "myblue"}[Dependent Type System].
:::
::::::

:::::::::class "small-list"
::::::fragment
:::vstack
It looks very "theoretical", but it's a practical compiled language that:

* produces efficient code
* it has a modern packaging system (inspired in Rust/Cargo)
* has a foreign function interface
* many packages available: networking, databases, web (and growing daily)
:::
::::::
:::::::::

# A Taste of Lean

A simple example:
```lean -panel
def average (nums : List Nat) : Rat
  := nums.sum / nums.length

--!fragment
#eval average [1, 10, 5]
```

:::fragment
Compare with Python:
```code "python"
def average (nums):
    return sum(nums) / len(nums)
```
:::


# A more interesting example

```lean -panel
def readFirstLine (file : System.FilePath) : IO String
--!fragment
  := do
    let contents ← IO.FS.readFile file
    if let some line := contents.lines.first? then
      return line.toString
    else
      throw (IO.userError "file is empty!")

--!fragment
#eval readFirstLine "Slides.lean"
```

# The Power of Strong Types

We want to extract the first element of a list:

```lean -panel
def head {α : Type} (lst : List α) : α
  -- ???
-- !fragment
  -- it's very broken!! 💥💣💥
-- !hide
  := sorry
-- !end hide
```

:::fragment
Let's do better with *Dependent Types*:
:::

:::fragment
```lean -panel
def head2 {α : Type} (lst : List α) (h : lst.length > 0) : α
-- !fragment
  := lst[0]
```
:::

:::fragment
Let's try it out:
```lean
#eval head2 [3, 5] (by
-- !fragment
  simp)
-- !fragment
#check head2 [] (by
-- !fragment
  sorry)
```
:::

# A Scary Thing: Monads

You cannot avoid *Monads* in Functional Programming.

::: fragment
Some people say Monads are _simply a monoid in the category of endofunctors_...
:::

::: fragment
Other people say that Monads are like a _burrito_.
:::

::: fragment
I want to give you a different "taste". Let's think of Monads as a synonym for *a context*.

Question: (recall Lean is *pure*) what would be the type of the function `date`?
:::

# A Richer Example

A simple _evaluator_ for division: $`((18 / 2) / 3) = 3`

```lean -panel
inductive T where
  | Num (n : Int)
  | Div (a b : T)

def Example := T.Div (T.Div (T.Num 18) (T.Num 2)) (T.Num 3)

--!fragment
def evaluate (t : T) : Id Int := do
  match t with
  | .Num n => return n
  | .Div a b => do
    let x ← evaluate a
    let y ← evaluate b
    return (x / y)

--!fragment
#eval evaluate Example
```

# Monads as a Context

A *Monad* is a type `M` that has two operations:

```lean -panel
def /- !replace return -/f {M : Type → Type}/- !end replace -/ : α → M α
  -- "return x" puts the value x in the context M
-- !hide
 := sorry
-- !end hide

def bind /- !replace -/{M : Type → Type}/- !end replace -/ : M α → (α → M β) → M β
  -- "bind x f" does:
  --    - get "x" out of the context M
  --    - apply "f" to "x" and return the result in the context M
-- !hide
 := sorry
-- !end hide
```

# Many Contexts, Same Implementation

*Lean* provides a wide variety of Monads/Contexts: _IO, Exceptions, State, Backtracking,
Logging, Concurrency, Nondeterminism, Random numbers, ..._

And the user can define their own Monads either composing existing ones, or from scratch.

:::fragment
Let's do the `Exception` monad from scratch:
```lean -panel
inductive MyError (α : Type) where
  | Success (val : α)
  | Error (err : String)

-- !fragment
instance : Monad MyError where
  pure x := .Success x    -- pure is a synonym for "return"
  bind mx f :=
    match mx with
    | .Success v => f v
    | .Error e => .Error e
```
:::

# In the context of MyError

```lean -panel
-- Utility function for raising errors (similar to `throw`)
def raise {α : Type} (error : String) : MyError α := .Error error

def eval2 (t : T) : MyError Int := do
  match t with
  | .Num n => return n
  | .Div a b => do
    let x ← eval2 a
    let y ← eval2 b
    if y == 0 then
      raise "division by zero"  -- this is the only change, where we use
    else                        -- the capabilities of the new context
      return (x / y)

-- !fragment
#eval eval2 Example

#eval eval2 (T.Div (T.Num 3) (T.Num 0))
```

# In the context of IO

```lean -panel
def eval3 (t : T) : IO Int := do
  match t with
  | .Num n => return n
  | .Div a b => do
    let x ← eval3 a
    let y ← eval3 b
    if y == 0 then
      IO.println "aborting..."
      throw (IO.userError "division by zero")
    else
      return (x / y)
```

# Things to Take Home

* Run all these examples:
  ```code "bash"
  nix run github:waltermoreira/tacc-2026
  ```

* Check out our project `Sequencelib` at `provables.org/sequencelib`, and at
  `github.com/provables`. Lots of Lean and Nix! (joint effort with Joe Stubbs).

* Not afraid of monads? Read _The Essence of Functional Programming_ by Philip Wadler
  (this paper is from 1992!)

# Thank you!
