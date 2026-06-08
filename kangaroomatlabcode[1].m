%% Kangaroo Island Farm Microgrid Simulation
% Sustainable microgrid with PV, Wind Turbines, and Battery Storage
% Microgrid Design Team

clear; close all; clc;

%% 1. SIMULATION PARAMETERS
hours = 8760; % One year hourly simulation
dt = 1;      % Time step (hours)
time = 1:hours;

%% 2. LOAD PROFILE GENERATION (Farm Load)
base_load = 50;  % kW average base load
peak_load = 120; % kW peak load

% Daily pattern (higher during day)
daily_pattern = base_load + 30*sin(2*pi*time/24 - pi/2).^2;

% Seasonal variation
seasonal_var = 20*sin(2*pi*time/8760);

% Random variations
load_demand = daily_pattern + seasonal_var + 5*randn(1,hours);
load_demand = max(load_demand, 20); % Minimum 20 kW

%% 3. SOLAR RESOURCE DATA
solar_irr = zeros(1, hours);
for i = 1:hours
    hour_of_day = mod(i-1, 24);
    day_of_year = floor((i-1)/24) + 1;
    
    if hour_of_day >= 6 && hour_of_day <= 18
        solar_irr(i) = 800 * sin(pi*(hour_of_day-6)/12);
    else
        solar_irr(i) = 0;
    end
    
    % Seasonal factor
    seasonal_factor = 1 + 0.3*sin(2*pi*(day_of_year-80)/365);
    solar_irr(i) = solar_irr(i) * seasonal_factor;
    
    % Random cloud cover
    solar_irr(i) = solar_irr(i) * (0.7 + 0.3*rand());
end

%% 4. WIND RESOURCE DATA
mean_wind_speed = 6.5; % m/s
wind_speed = mean_wind_speed + 2*randn(1,hours);
wind_speed = max(wind_speed, 0);

%% 5. SYSTEM COMPONENT SPECIFICATIONS
pv_capacity = 200; pv_efficiency = 0.18; pv_derating = 0.85; pv_cost_per_kw = 1200;
wt_capacity = 150; wt_cut_in = 3; wt_rated_speed = 12; wt_cut_out = 25; wt_cost_per_kw = 2000;
battery_capacity = 500; battery_power = 150; battery_efficiency = 0.90;
battery_min_soc = 0.2; battery_max_soc = 0.95; battery_cost_per_kwh = 800;
grid_import_cost = 0.35; grid_export_price = 0.10;

%% 6. POWER GENERATION CALCULATIONS
pv_generation = (solar_irr / 1000) .* pv_capacity .* pv_derating;

wt_generation = zeros(1, hours);
for i = 1:hours
    v = wind_speed(i);
    if v < wt_cut_in || v > wt_cut_out
        wt_generation(i) = 0;
    elseif v >= wt_cut_in && v < wt_rated_speed
        wt_generation(i) = wt_capacity * ((v^3 - wt_cut_in^3)/(wt_rated_speed^3 - wt_cut_in^3));
    else
        wt_generation(i) = wt_capacity;
    end
end

renewable_gen = pv_generation + wt_generation;

%% 7. ENERGY MANAGEMENT SYSTEM SIMULATION
battery_soc = zeros(1,hours); battery_soc(1) = 0.5;
grid_import = zeros(1,hours); grid_export = zeros(1,hours);
battery_charge = zeros(1,hours); battery_discharge = zeros(1,hours);
energy_deficit = zeros(1,hours);

for i = 1:hours
    net_power = renewable_gen(i) - load_demand(i);
    
    if net_power > 0
        % Surplus power
        soc_limit = battery_capacity*(battery_max_soc - battery_soc(i));
        charge_amount = min([net_power, battery_power, soc_limit]) * battery_efficiency;
        battery_charge(i) = charge_amount;
        
        if i < hours
            battery_soc(i+1) = battery_soc(i) + charge_amount / battery_capacity;
        end
        
        excess_power = net_power - charge_amount/battery_efficiency;
        grid_export(i) = max(0, excess_power);
        
    else
        % Deficit
        power_needed = abs(net_power);
        available_discharge = min(battery_power, battery_capacity*(battery_soc(i)-battery_min_soc));
        discharge_amount = min(power_needed, available_discharge) / battery_efficiency;
        battery_discharge(i) = discharge_amount;
        
        if i < hours
            battery_soc(i+1) = battery_soc(i) - discharge_amount / battery_capacity;
        end
        
        remaining_deficit = power_needed - discharge_amount*battery_efficiency;
        grid_import(i) = max(0, remaining_deficit);
    end
    
    energy_deficit(i) = max(0, load_demand(i) - renewable_gen(i) - battery_discharge(i)*battery_efficiency);
end

%% 8. PERFORMANCE METRICS
total_load = sum(load_demand);
total_pv_gen = sum(pv_generation);
total_wt_gen = sum(wt_generation);
total_renewable = sum(renewable_gen);
total_grid_import = sum(grid_import);
total_grid_export = sum(grid_export);

renewable_fraction = (total_renewable / total_load)*100;
self_sufficiency = ((total_load - total_grid_import)/total_load)*100;
lpsp = (sum(energy_deficit>0.1)/hours)*100;
cf_pv = (total_pv_gen / (pv_capacity*hours))*100;
cf_wt = (total_wt_gen / (wt_capacity*hours))*100;

%% 9. ECONOMIC ANALYSIS
pv_capex = pv_capacity*pv_cost_per_kw;
wt_capex = wt_capacity*wt_cost_per_kw;
battery_capex = battery_capacity*battery_cost_per_kwh;
total_capex = pv_capex + wt_capex + battery_capex;

pv_opex = pv_capacity*20; wt_opex = wt_capacity*40; battery_opex = battery_capacity*10;
total_opex = pv_opex + wt_opex + battery_opex;

annual_grid_cost = sum(grid_import)*grid_import_cost;
annual_grid_revenue = sum(grid_export)*grid_export_price;
net_grid_cost = annual_grid_cost - annual_grid_revenue;

total_annual_cost = total_opex + net_grid_cost;

project_lifetime = 20; discount_rate = 0.05;
npv_opex = total_annual_cost*((1-(1+discount_rate)^(-project_lifetime))/discount_rate);
total_npc = total_capex + npv_opex;
total_energy_delivered = total_load*project_lifetime;
lcoe = total_npc / total_energy_delivered;

grid_only_cost = total_load*grid_import_cost;
annual_savings = grid_only_cost - total_annual_cost;
payback_period = total_capex / annual_savings;

grid_emission_factor = 0.82; % kg CO2/kWh
annual_co2_reduction = (total_renewable - total_grid_import)*grid_emission_factor/1000;

%% 10. DISPLAY RESULTS
fprintf('\n========== KANGAROO ISLAND MICROGRID SIMULATION RESULTS ==========\n\n');
fprintf('PV: %.1f kW | Wind: %.1f kW | Battery: %.1f kWh / %.1f kW\n', ...
    pv_capacity, wt_capacity, battery_capacity, battery_power);
fprintf('Annual Load: %.1f MWh\nPV Gen: %.1f MWh | Wind Gen: %.1f MWh\n', ...
    total_load/1000, total_pv_gen/1000, total_wt_gen/1000);
fprintf('Grid Import: %.1f MWh | Grid Export: %.1f MWh\n', total_grid_import/1000, total_grid_export/1000);
fprintf('Renewable Fraction: %.1f%% | Self-Sufficiency: %.1f%% | LPSP: %.2f%%\n', ...
    renewable_fraction, self_sufficiency, lpsp);
fprintf('CAPEX: $%.0f | Annual Cost: $%.0f | LCOE: $%.3f/kWh | Payback: %.1f years\n', ...
    total_capex, total_annual_cost, lcoe, payback_period);
fprintf('Annual CO2 Reduction: %.1f tonnes\n\n', annual_co2_reduction);

%% 11. VISUALIZATION
% Weekly Performance and Annual Summary (as in original code)
% [Plots are identical to original version]

