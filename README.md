````markdown id="5qac0x" # Kangaroo Island Farm Microgrid - Simulink Model

> A MATLAB/Simulink-based microgrid simulation for a remote agricultural farm on Kangaroo Island, integrating solar photovoltaic generation, wind power, battery energy storage, and grid interaction to evaluate energy reliability and renewable energy penetration over a full year.

---

## Project Overview

This project models the operation of an off-grid or hybrid farm microgrid over a one-year period (8,760 hours) using MATLAB Simulink. The system combines renewable energy sources, battery storage, and grid connectivity to meet varying farm electricity demands while maximizing renewable energy utilization.

The simulation evaluates the performance of the microgrid under realistic daily and seasonal variations in solar irradiance, wind speed, and electrical load.

---

## Objectives

- Simulate annual microgrid operation over 8,760 hours - Integrate solar PV and wind energy generation - Model battery energy storage behavior - Analyze grid import and export requirements - Evaluate renewable energy contribution - Assess system reliability and energy balance - Monitor battery State of Charge (SOC) performance

---

## System Specifications

| Component | Specification | |-----------|---------------| | Solar PV System | 200 kW | | PV Efficiency | 18% | | PV Derating Factor | 0.85 | | Wind Turbine | 150 kW | | Wind Cut-in Speed | 3 m/s | | Wind Rated Speed | 12 m/s | | Battery Capacity | 500 kWh | | Battery Power Rating | 150 kW | | Battery Efficiency | 90% | | Battery SOC Limits | 20% - 95% | | Grid Import Cost | $0.35/kWh | | Grid Export Revenue | $0.10/kWh | | Farm Load Range | 20-120 kW | | Simulation Period | 8760 Hours |

---

## Key Performance Indicators

The model evaluates:

- Renewable Energy Fraction - Self-Sufficiency Ratio - Battery State of Charge (SOC) - Grid Import and Export Energy - Battery Charge and Discharge Activity - Loss of Power Supply Probability (LPSP) - Annual Energy Balance

---

## Model Architecture

The Simulink model consists of the following interconnected subsystems:

```text Clock │ ├── Load_Demand ├── Solar_PV └── Wind_Turbine │ ▼ Sum_Renewable │ ▼ Net_Power │ ▼ Battery_System │ ▼ Outputs ```

### Simulation Configuration

| Parameter | Value | |-----------|-------| | Solver Type | Fixed-Step Discrete | | Time Step | 1 Hour | | Start Time | 0 | | Stop Time | 8760 | | Total Simulation Length | 1 Year |

---

## Main Subsystems

### 1. Load Demand

The farm load profile incorporates both daily and seasonal demand variations.

#### Features

- Daily demand fluctuations - Seasonal demand changes - Minimum load: 20 kW - Maximum load: 120 kW

#### Load Equation

```math id="0yc0zv" L = 50 + 30 \sin^2 \left(\frac{2\pi t}{24} - \frac{\pi}{2}\right) + 20 \sin \left(\frac{2\pi t}{8760}\right) ```

---

### 2. Solar PV Subsystem

The PV model uses a sinusoidal irradiance profile with seasonal variation.

#### Specifications

- Rated Capacity: 200 kW - Efficiency: 18% - Derating Factor: 0.85

#### Characteristics

- Daylight Hours: 06:00 - 18:00 - Seasonal Variation: ±30% - Output Range: 0-170 kW

#### PV Power Equation

```math id="5bnr4g" P_{PV} = \left(\frac{G}{1000}\right) \times 200 \times 0.85 ```

where:

- G = Solar irradiance (W/m²)

---

### 3. Wind Turbine Subsystem

The wind turbine subsystem models variable wind conditions using a Gaussian distribution.

#### Specifications

| Parameter | Value | |-----------|-------| | Rated Capacity | 150 kW | | Cut-in Speed | 3 m/s | | Rated Speed | 12 m/s | | Mean Wind Speed | 6.5 m/s |

#### Features

- Gaussian wind speed distribution - Cubic power curve - Output range: 0-150 kW

---

### 4. Battery Energy Storage System

The battery subsystem balances generation and demand by charging during surplus generation and discharging during energy deficits.

#### Specifications

| Parameter | Value | |-----------|-------| | Capacity | 500 kWh | | Power Rating | 150 kW | | Efficiency | 90% | | Minimum SOC | 20% | | Maximum SOC | 95% |

#### Output Limits

```text id="iqikm6" Battery Power Range: -150 kW
