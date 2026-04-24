import Mathlib

def average (nums : List ℕ) : ℚ := nums.sum / nums.length

#eval average [1, 5, 10]

def readFirstLine (file : System.FilePath) : IO String := do
  let s ← IO.FS.readFile file
  if let some ls := s.lines.first? then
    return ls.toString
  else
    throw (IO.userError "file is empty!")

#eval readFirstLine "Slides.lean"

def head2 {a : Type} (lst : List a) (h : lst.length > 0) : a :=
  lst[0]

inductive Permissions
  | Allow
  | Deny
structure User where
  name : String
  perms : List Permissions



inductive T where
  | Num (n : Int)
  | Div (a b : T)

def demo := T.Div (T.Num 18) (T.Num 3)

variable (M : Type → Type)

#check pure
#check bind

def eval (t : T) : Id Int := do
  match t with
  | .Num n => pure n
  | .Div a b => do
    let x ← eval a
    let y ← eval b
    pure (x / y)

def evalM [Monad M] (t : T) : M Int := do
  match t with
  | .Num n => pure n
  | .Div a b => do
    let x ← evalM a
    let y ← evalM b
    pure (x / y)

def eval1 := evalM (M := Id)

#eval eval1 demo

inductive MyError (α : Type) where
  | Success (val : α)
  | Error (err : String)

instance : Monad MyError where
  pure x := .Success x
  bind mx f :=
    match mx with
    | .Success v => f v
    | .Error e => .Error e

def raise {α : Type} (error : String) : MyError α := .Error error

def eval2 (t : T) : MyError Int := do
  match t with
  | .Num n => pure n
  | .Div a b => do
    let x ← eval2 a
    let y ← eval2 b
    if y == 0 then
      raise "division by zero"
    else
      pure (x / y)

#eval eval2 (T.Div (T.Div (T.Num 6) (T.Num 2)) (T.Num 2)) -- (6 / 2) / 2

open Lean

#check Rand

def f : Rand Int := do
  let x ← .next
  return x

def eval3 (t : T) : IO Int := do
  match t with
  | .Num n => pure n
  | .Div a b => do
    let x ← eval3 a
    let y ← eval3 b
    if y == 0 then
      IO.println "division by zero"
      pure 0
    else
      pure (x / y)

#eval eval3 (T.Div (T.Div (T.Num 6) (T.Num 0)) (T.Num 2)) -- (6 / 2) / 2
