# Waste Collection Quality Monitoring from Fill-Level Sensors

MATLAB toolkit for analyzing fill-level signals from sensors in public waste containers.
Monitoring of waste management service quality from fill-level sensors in public waste containers
## Overview

This project provides methods for automated analysis of fill-level sensor data from public waste containers. It enables detection of waste collection events, identification of signal anomalies, and inference of collection schedules.

The system is designed to work with both:
- **Fast-filling containers** (e.g., paper, plastic)
- **Slow-filling containers** (e.g., glass, metals)

The toolbox is intended for:
- Waste management operators
- Researchers working on smart city analytics

The project is currently a **production-oriented tool under development**, suitable for *test-before-invest* scenarios.

---

## Features

- **Waste collection detection**
  - Based on pattern classification and signal analysis
- **Schedule inference**
  - Periodic schedules (e.g., every N weeks)
  - Weekly schedules (e.g., Monday & Thursday)
- **Anomaly detection**
  - Blocked inlet (container not filling)
  - Sudden drops (emptying or sensor issues)
  - Sensor spikes / faulty peaks
  - Missing or suspicious collections
- **Support for multiple waste types**
  - Fast-filling (paper, plastic)
  - Slow-filling (glass, metals)

---

## Workflow

The typical workflow consists of the following steps:

1. **Data acquisition**
   - Load data from API:
     ```matlab
     api_read_measurements
     ```

2. **Signal analysis**
   - Fast-filling containers:
     ```matlab
     analyse_signal
     ```
   - Slow-filling containers:
     ```matlab
     analyse_signal_bsklo
     ```

3. **Collection optimization**
   - Fast-filling containers:
     ```matlab
     optimize_collections_constraints
     ```
   - Slow-filling containers:
     ```matlab
     optimize_collections_periodical
     ```

---

## Getting Started

### Requirements

- MATLAB
- Statistics and Machine Learning Toolbox

---

### Running Examples

Example scripts are provided:

- **Slow-filling containers (e.g., glass):**
  ```matlab
  demo_detect_collection_slow_filling.m
