# micromouse-automarker

# Micromouse Automarker

This repository provides the **automated marking system** used to evaluate student solutions for the Micromouse simulator. It is designed to work alongside the simulation environment in the companion repository:

🔗 [Micromouse Simulator](https://github.com/Thombela/micromouse-simulator)

> ⚠️ This repository **does not include the simulation engine or robot models** — it is solely focused on automated assessment.

---

## 📁 Repository Structure

```

automarker/
├── automarker.m         # Core marking script
├── generate\_maze.m      # Maze generator for testing
├── Solutions/           # Folder to store student solution.slx files

````

- `automarker.m`: Runs evaluation tests using the simulation environment and grades student submissions based on path validity, efficiency, and rule compliance.
- `generate_maze.m`: Creates test mazes for assessing the robustness of student algorithms.
- `Solutions/`: Empty folder where student submissions (`solution.slx`) should be placed for marking.

---

## 🧪 Functionality

The **automarker** script performs the following:

- ✅ Validates if the robot reaches the center goal zone
- 📏 Evaluates path length and efficiency
- 🔁 Tests robustness across various generated mazes
- 🛑 Checks for rule violations or illegal moves

Results can be used for both formative and summative assessment in coursework or competitions.

---

## 🚀 Getting Started

1. **Clone this repository**:
   git clone https://github.com/Thombela/micromouse-automarker.git
   

2. **Clone the simulator repository into same folder** (required for simulation):

   git clone https://github.com/Thombela/micromouse-simulator.git

3. **Add student solutions** to the `Solutions/` folder.

## 🛠 Requirements

* MATLAB (R2023a or later recommended)
* Simulink
* Maze configurations and simulation engine from [micromouse-simulator](https://github.com/Thombela/micromouse-simulator)

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍🏫 Academic Use

This tool is intended for automatic grading of Simulink-based maze-solving algorithms developed as part of the Micromouse challenge. It supports evaluation across correctness, path optimization, and robustness.

---

## ✍️ Attribution

Made for 📚 **EEE4022F Final Year Project – University of Cape Town**
**Author:** Mpilonhle Ngcoya
**Supervisor:** Justin Pead
