# First-Order Logic to Propositional Logic Converter (Herbrand Theorem)

[![Julia](https://img.shields.io/badge/Julia-1.10-purple.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)]()

This repository contains an academic implementation of the **Herbrand Theorem** to solve the satisfiability problem of First-Order Logic (FOL) formulas by converting them into Propositional Logic (PL).

This project was developed for the **LITI** course (`Logic in Artificial Intelligence`) at University of Seville, during the 2025-2026 academic year.

## Project Overview

The core objective is to determine the satisfiability of a set of FOL formulas $S$ by following these steps:

1.  **Preprocessing**: Convert FOL formulas to Prenex Normal Form and perform Skolemization.
2.  **Herbrand Universe**: Construct the Herbrand Universe to eliminate variables, creating ground formulas.
3.  **Propositionalization**: Map atomic predicates to propositional variables.
4.  **Satisfiability Check**: Translate the ground FOL formulas into PL formulas and solve using PL methods (e.g., DPLL).

## Technology Stack

* **Language**: Julia 1.10
* **Core Libraries**:
    * `FirstOrderLogic.jl`: Implements FOL structures, Skolemization, and Herbrand Universe construction.
    * `PropositionalLogic.jl`: Implements PL structures, parsing, and solvers.
    * *Authorship*: Libraries provided by Professor *Fernando Sancho Caparrini*.

## Implementation Details

### Core Functions (`IRENE_funcion_herbrand.jl`)
* **`to_PL(f::FOLFormula, max_depth::Int)`**: Main function to convert a FOL formula into a set of PL formulas based on a specified Herbrand depth.
* **`parse_pl(s::String)`**: A recursive descent parser designed to translate string representations of formulas into structured `FormulaPL` objects.

### Testing and Examples (`IRENE_desarrollo_Herbrand.jl`)
This script includes tests on finite and infinite sets of formulas to demonstrate the effectiveness of the algorithm.

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
