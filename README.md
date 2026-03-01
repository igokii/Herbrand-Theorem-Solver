# First-Order Logic to Propositional Logic Converter (Herbrand Theorem)

[![Julia](https://img.shields.io/badge/Julia-1.10-purple.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)]()

This repository contains an academic implementation of the **Herbrand Theorem** to solve the satisfiability problem of First-Order Logic (FOL) formulas by converting them into Propositional Logic (PL).

This project was developed for the **LITI** course (`Logic in Artificial Intelligence`) at [Your University], during the 2025-2026 academic year.

## Project Overview

[cite_start]The core objective is to determine the satisfiability of a set of FOL formulas $S$ by following these steps[cite: 2, 3, 4, 5, 6, 7]:

1.  [cite_start]**Preprocessing**: Convert FOL formulas to Prenex Normal Form and perform Skolemization[cite: 2].
2.  [cite_start]**Herbrand Universe**: Construct the Herbrand Universe to eliminate variables, creating ground formulas[cite: 3].
3.  [cite_start]**Propositionalization**: Map atomic predicates to propositional variables[cite: 4, 5].
4.  [cite_start]**Satisfiability Check**: Translate the ground FOL formulas into PL formulas and solve using PL methods (e.g., DPLL)[cite: 6, 7].

## Technology Stack

* **Language**: Julia 1.10
* **Core Libraries**:
    * [cite_start]`FirstOrderLogic.jl`: Implements FOL structures, Skolemization, and Herbrand Universe construction[cite: 8].
    * [cite_start]`PropositionalLogic.jl`: Implements PL structures, parsing, and solvers[cite: 8].
    * *Authorship*: Libraries provided by Professor Fernando Sancho Caparrini.

## Implementation Details

### Core Functions (`IRENE_funcion_herbrand.jl`)
* [cite_start]**`to_PL(f::FOLFormula, max_depth::Int)`**: Main function to convert a FOL formula into a set of PL formulas based on a specified Herbrand depth[cite: 31, 32, 33, 34].
* [cite_start]**`parse_pl(s::String)`**: A recursive descent parser designed to translate string representations of formulas into structured `FormulaPL` objects[cite: 23, 24, 25, 26, 27, 28, 29, 30].

### Testing and Examples (`IRENE_desarrollo_Herbrand.jl`)
[cite_start]This script includes tests on finite [cite: 18, 19, 20, 21] [cite_start]and infinite [cite: 21, 22] sets of formulas to demonstrate the effectiveness of the algorithm.

## How to Run

1.  Ensure you have Julia installed.
2.  Clone the repository:
    ```bash
    git clone [https://github.com/your-username/repository-name.git](https://github.com/your-username/repository-name.git)
    ```
3.  Open the Julia REPL in the repository root and run the test script:
    ```julia
    include("IRENE_desarrollo_Herbrand.jl")
    ```
