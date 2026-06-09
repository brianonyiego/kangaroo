# Kangaroo Island Farm Microgrid - Simulink Model

> A MATLAB/Simulink-based microgrid simulation for a remote agricultural farm on Kangaroo Island, integrating solar photovoltaic generation, wind power, battery energy storage, and grid interaction to evaluate energy reliability and renewable energy penetration over a full year.

## Project Overview

This project models the operation of an off-grid or hybrid farm microgrid over a one-year period (8,760 hours) using MATLAB Simulink. The system combines renewable energy sources, battery storage, and grid connectivity to meet varying farm electricity demands while maximizing renewable energy utilization.

The simulation evaluates the performance of the microgrid under realistic daily and seasonal variations in solar irradiance, wind speed, and electrical load.

## Objectives

- Simulate annual microgrid operation over 8,760 hours
- Integrate solar PV and wind energy generation
- Model battery energy storage behavior
- Analyze grid import and export requirements
- Evaluate renewable energy contribution
- Assess system reliability and energy balance
- Monitor battery State of Charge (SOC) performance

## System Specifications

| Component | Specification |
|-----------|---------------|
| Solar PV System | 200 kW |
| PV Efficiency | 18% |
| PV Derating Factor | 0.85 |
| Wind Turbine | 150 kW |
| Wind Cut-in Speed | 3 m/s |
| Wind Rated Speed | 12 m/s |
| Battery Capacity | 500 kWh |
| Battery Power Rating | 150 kW |
| Battery Efficiency | 90% |
| Battery SOC Limits | 20% - 95% |
| Grid Import Cost | $0.35/kWh |
| Grid Export Revenue | $0.10/kWh |
| Farm Load Range | 20-120 kW |
| Simulation Period | 8760 Hours |

## Key Performance Indicators

The model evaluates:

- Renewable Energy Fraction
- Self-Sufficiency Ratio
- Battery State of Charge (SOC)
- Grid Import and Export Energy
- Battery Charge and Discharge Activity
- Loss of Power Supply Probability (LPSP)
- Annual Energy Balance

## Model Architecture

The Simulink model consists of the following interconnected subsystems:

```text
Clock
 │
 ├── Load_Demand
 ├── Solar_PV
 └── Wind_Turbine
         │
         ▼
   Sum_Renewable
         │
         ▼
      Net_Power
         │
         ▼
   Battery_System
         │
         ▼
       Outputs
```

### Simulation Configuration

| Parameter | Value |
|-----------|-------|
| Solver Type | Fixed-Step Discrete |
| Time Step | 1 Hour |
| Start Time | 0 |
| Stop Time | 8760 |
| Total Simulation Length | 1 Year |

## Main Subsystems

### 1. Load Demand

The farm load profile incorporates both daily and seasonal demand variations.

#### Features

- Daily demand fluctuations
- Seasonal demand changes
- Minimum load: 20 kW
- Maximum load: 120 kW

#### Load Equation

```math
L = 50 + 30\sin^2\left(\frac{2\pi t}{24}-\frac{\pi}{2}\right) + 20\sin\left(\frac{2\pi t}{8760}\right)
```

### 2. Solar PV Subsystem

The PV model uses a sinusoidal irradiance profile with seasonal variation.

#### Specifications

- Rated Capacity: 200 kW
- Efficiency: 18%
- Derating Factor: 0.85

#### Characteristics

- Daylight Hours: 06:00 - 18:00
- Seasonal Variation: ±30%
- Output Range: 0-170 kW

#### PV Power Equation

```math
P_{PV}=\left(\frac{G}{1000}\right)\times200\times0.85
```

Where:

- G = Solar irradiance (W/m²)

### 3. Wind Turbine Subsystem

The wind turbine subsystem models variable wind conditions using a Gaussian distribution.

#### Specifications

| Parameter | Value |
|-----------|-------|
| Rated Capacity | 150 kW |
| Cut-in Speed | 3 m/s |
| Rated Speed | 12 m/s |
| Mean Wind Speed | 6.5 m/s |

#### Features

- Gaussian wind speed distribution
- Cubic power curve
- Output range: 0-150 kW

### 4. Battery Energy Storage System

The battery subsystem balances generation and demand by charging during surplus generation and discharging during energy deficits.

#### Specifications

| Parameter | Value |
|-----------|-------|
| Capacity | 500 kWh |
| Power Rating | 150 kW |
| Efficiency | 90% |
| Minimum SOC | 20% |
| Maximum SOC | 95% |

#### Output Limits

```text
Battery Power Range:
-150 kW ≤ Pbattery ≤ +150 kW
```

#### SOC Constraints

```text
0.20 ≤ SOC ≤ 0.95
```

### 5. Output Monitoring

The model records key performance variables using Simulink Scopes and To Workspace blocks.

#### Logged Variables

- load_demand
- pv_generation
- wind_generation
- total_renewable
- battery_power
- battery_soc
- grid_import
- grid_export

## Signal Flow

```text
Clock
 │
 ├── Load Demand
 ├── Solar PV
 └── Wind Turbine
          │
          ▼
    Total Renewable
          │
          ▼
 Load - Renewable
          │
          ▼
      Net Power
          │
          ▼
   Battery System
          │
          ├── SOC
          └── Battery Power
```

### Typical Operating Ranges

| Variable | Range |
|-----------|--------|
| Load Demand | 20-120 kW |
| Solar PV | 0-170 kW |
| Wind Power | 0-150 kW |
| Battery Power | ±150 kW |
| Battery SOC | 0.20-0.95 |

## Core Mathematical Models

### Load Demand

```math
L = 50 + 30\sin^2\left(\frac{2\pi t}{24}-\frac{\pi}{2}\right) + 20\sin\left(\frac{2\pi t}{8760}\right)
```

### Solar PV

```math
P_{PV}=\left(\frac{G}{1000}\right)\times200\times0.85
```

### Wind Turbine

```text
Cubic Power Curve:
3 m/s ≤ Wind Speed ≤ 12 m/s
```

### Battery Storage

```text
SOC(t+1) = SOC(t) + Charging Energy - Discharging Energy
```

Subject to:

```text
0.20 ≤ SOC ≤ 0.95
```

## Running the Simulation

### Open the Model

```matlab
open_system('Kangaroo_Island_Microgrid')
```

### Run the Simulation

```matlab
sim('Kangaroo_Island_Microgrid')
```

### Verify Configuration

```text
Solver Type: Fixed-Step Discrete
Step Size: 1 Hour
Stop Time: 8760 Hours
```

### Quick Test Run

For rapid testing:

```matlab
set_param('Kangaroo_Island_Microgrid','StopTime','168')
sim('Kangaroo_Island_Microgrid')
```

This simulates one week of operation.

## Model Customization

The following parameters can be modified directly within the MATLAB Function blocks:

- Solar PV capacity
- PV derating factor
- Wind turbine rating
- Wind speed distribution
- Battery capacity
- Battery power rating
- SOC limits
- Load profile parameters

## Model Validation

Automated MATLAB tests verify:

### Load Profile

- Minimum load ≥ 20 kW
- Expected seasonal variation

### Solar PV

- PV generation equals 0 during nighttime hours
- Output remains below rated capacity

### Wind Turbine

- Output remains below rated power
- Wind speed constraints satisfied

### Battery

- SOC remains within defined limits
- Power remains within ±150 kW

### Energy Balance

- Generation-demand consistency maintained

## Performance

| Metric | Value |
|---------|--------|
| Simulation Duration | 8760 Hours |
| Time Step | 1 Hour |
| Typical Runtime | ~20 Seconds |

## Troubleshooting

| Issue | Cause | Solution |
|---------|---------|---------|
| Unconnected Output | Missing signal connection | Reconnect signal or run Model Advisor |
| Algebraic Loop | Direct SOC feedback | Insert Unit Delay block |
| Data Type Mismatch | Incorrect signal dimensions | Verify MATLAB Function outputs |
| SOC Beyond Limits | Missing saturation logic | Add SOC saturation block |

### Performance Optimization Tips

- Disable unnecessary Scopes
- Use Accelerator Mode
- Reduce logging frequency
- Decimate output signals
- Save only required workspace variables

## Project Structure

```text
Kangaroo_Island_Microgrid/
│
├── Kangaroo_Island_Microgrid.slx
├── README.md
├── validation_scripts/
│   ├── battery_validation.m
│   ├── load_validation.m
│   └── renewable_validation.m
├── results/
│   ├── simulation_outputs.mat
│   └── performance_metrics.mat
└── figures/
    ├── load_profile.png
    ├── pv_generation.png
    ├── wind_generation.png
    └── battery_soc.png
```

## Results

The model generates the following outputs:

- Hourly farm load demand
- Solar PV generation profile
- Wind turbine generation profile
- Total renewable generation
- Battery charging and discharging power
- Battery State of Charge (SOC)
- Grid import energy
- Grid export energy
- Annual performance indicators

These outputs can be visualized using MATLAB plots or exported for further analysis.

## Reference

MDPI. (2022). *Energies*. Renewable energy and microgrid modeling research.

https://www.mdpi.com/1996-1073/15/19

## Author

Your Name

GitHub: @brianonyiego

## License

This project is intended for educational and research purposes. Feel free to modify and extend the model for academic, research, and learning applications.
