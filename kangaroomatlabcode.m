%% Kangaroo Island Farm Microgrid Simulation
% Sustainable microgrid with PV, Wind Turbines, and Battery Storage
%  Microgrid Design Team


clear all; close all; clc;

%% 1. SIMULATION PARAMETERS
hours = 8760; % One year hourly simulation
dt = 1; % Time step (hours)
time = 1:hours;

%% 2. LOAD PROFILE GENERATION (Farm Load)
% Typical farm load with seasonal and daily variations
base_load = 50; % kW average base load
peak_load = 120; % kW peak load

% Daily pattern (higher during day for farm operations)
daily_pattern = base_load + 30*sin(2*pi*time/24 - pi/2).^2;

% Seasonal variation (higher in summer for irrigation/cooling)
seasonal_var = 20*sin(2*pi*time/8760);

% Random variations
load_demand = daily_pattern + seasonal_var + 5*randn(1,hours);
load_demand = max(load_demand, 20); % Minimum 20 kW

%% 3. SOLAR RESOURCE DATA (Kangaroo Island)
% Average daily solar radiation: 5.2 kWh/m²
% Generate realistic solar irradiance profile

solar_irr = zeros(1, hours);
for i = 1:hours
    hour_of_day = mod(i-1, 24);
    day_of_year = floor((i-1)/24) + 1;
    
    % Daily solar pattern (sunrise to sunset)
    if hour_of_day >= 6 && hour_of_day <= 18
        solar_irr(i) = 800 * sin(pi*(hour_of_day-6)/12);
    else
        solar_irr(i) = 0;
    end
    
    % Seasonal variation
    seasonal_factor = 1 + 0.3*sin(2*pi*(day_of_year-80)/365);
    solar_irr(i) = solar_irr(i) * seasonal_factor;
    
    % Cloud cover randomness
    solar_irr(i) = solar_irr(i) * (0.7 + 0.3*rand());
end

%% 4. WIND RESOURCE DATA (Kangaroo Island)
% Average wind speed: 6-7 m/s
mean_wind_speed = 6.5; % m/s
wind_speed = mean_wind_speed + 2*randn(1, hours);
wind_speed = max(wind_speed, 0); % No negative wind speeds

%% 5. SYSTEM COMPONENT SPECIFICATIONS

% PV System
pv_capacity = 200; % kW
pv_efficiency = 0.18; % 18% efficiency
pv_area_per_kw = 6; % m² per kW
pv_derating = 0.85; % Performance ratio
pv_cost_per_kw = 1200; % AUD per kW

% Wind Turbine
wt_capacity = 150; % kW rated capacity
wt_cut_in = 3; % m/s cut-in speed
wt_rated_speed = 12; % m/s rated speed
wt_cut_out = 25; % m/s cut-out speed
wt_cost_per_kw = 2000; % AUD per kW

% Battery Storage
battery_capacity = 500; % kWh
battery_power = 150; % kW max charge/discharge
battery_efficiency = 0.90; % Round-trip efficiency
battery_min_soc = 0.2; % Minimum 20% SOC
battery_max_soc = 0.95; % Maximum 95% SOC
battery_cost_per_kwh = 800; % AUD per kWh

% Grid Connection
grid_import_cost = 0.35; % AUD per kWh
grid_export_price = 0.10; % AUD per kWh (feed-in tariff)

% Diesel Backup (for comparison)
diesel_cost = 1.50; % AUD per liter
diesel_efficiency = 0.30; % 30% efficiency (3.33 kWh per liter)

%% 6. POWER GENERATION CALCULATIONS

% PV Generation
pv_generation = (solar_irr / 1000) .* pv_capacity .* pv_derating;

% Wind Turbine Generation
wt_generation = zeros(1, hours);
for i = 1:hours
    v = wind_speed(i);
    if v < wt_cut_in || v > wt_cut_out
        wt_generation(i) = 0;
    elseif v >= wt_cut_in && v < wt_rated_speed
        % Cubic relationship in Region 2
        wt_generation(i) = wt_capacity * ((v^3 - wt_cut_in^3)/(wt_rated_speed^3 - wt_cut_in^3));
    else
        wt_generation(i) = wt_capacity;
    end
end

% Total Renewable Generation
renewable_gen = pv_generation + wt_generation;

%% 7. ENERGY MANAGEMENT SYSTEM SIMULATION

battery_soc = zeros(1, hours);
battery_soc(1) = 0.5; % Start at 50% SOC
grid_import = zeros(1, hours);
grid_export = zeros(1, hours);
energy_deficit = zeros(1, hours);
battery_charge = zeros(1, hours);
battery_discharge = zeros(1, hours);

for i = 1:hours
    net_power = renewable_gen(i) - load_demand(i);
    
    if net_power > 0
        % Surplus power: charge battery or export to grid
        available_charge = min(net_power, battery_power);
        soc_limit = battery_capacity * (battery_max_soc - battery_soc(i));
        
        if soc_limit > 0
            charge_amount = min(available_charge, soc_limit) * battery_efficiency;
            battery_charge(i) = charge_amount;
            
            if i < hours
                battery_soc(i+1) = battery_soc(i) + charge_amount/battery_capacity;
            end
            
            excess_power = net_power - charge_amount/battery_efficiency;
            if excess_power > 0
                grid_export(i) = excess_power;
            end
        else
            grid_export(i) = net_power;
            if i < hours
                battery_soc(i+1) = battery_soc(i);
            end
        end
    else
        % Deficit: discharge battery or import from grid
        power_needed = abs(net_power);
        available_discharge = min(battery_power, ...
            battery_capacity * (battery_soc(i) - battery_min_soc));
        
        if available_discharge > 0
            discharge_amount = min(power_needed, available_discharge) / battery_efficiency;
            battery_discharge(i) = discharge_amount;
            
            if i < hours
                battery_soc(i+1) = battery_soc(i) - discharge_amount/battery_capacity;
            end
            
            remaining_deficit = power_needed - discharge_amount * battery_efficiency;
            if remaining_deficit > 0
                grid_import(i) = remaining_deficit;
            end
        else
            grid_import(i) = power_needed;
            if i < hours
                battery_soc(i+1) = battery_soc(i);
            end
        end
    end
    
    energy_deficit(i) = max(0, load_demand(i) - renewable_gen(i) - battery_discharge(i)*battery_efficiency);
end

%% 8. PERFORMANCE METRICS

% Energy Balance
total_load = sum(load_demand);
total_pv_gen = sum(pv_generation);
total_wt_gen = sum(wt_generation);
total_renewable = sum(renewable_gen);
total_grid_import = sum(grid_import);
total_grid_export = sum(grid_export);

% Renewable Penetration
renewable_fraction = (total_renewable / total_load) * 100;
self_sufficiency = ((total_load - total_grid_import) / total_load) * 100;

% Loss of Power Supply Probability
lpsp = (sum(energy_deficit > 0.1) / hours) * 100;

% Capacity Factors
cf_pv = (total_pv_gen / (pv_capacity * hours)) * 100;
cf_wt = (total_wt_gen / (wt_capacity * hours)) * 100;

%% 9. ECONOMIC ANALYSIS

% Capital Costs
pv_capex = pv_capacity * pv_cost_per_kw;
wt_capex = wt_capacity * wt_cost_per_kw;
battery_capex = battery_capacity * battery_cost_per_kwh;
total_capex = pv_capex + wt_capex + battery_capex;

% Operating Costs (Annual)
pv_opex = pv_capacity * 20; % AUD/kW/year
wt_opex = wt_capacity * 40; % AUD/kW/year
battery_opex = battery_capacity * 10; % AUD/kWh/year
total_opex = pv_opex + wt_opex + battery_opex;

% Grid Costs
annual_grid_cost = sum(grid_import) * grid_import_cost;
annual_grid_revenue = sum(grid_export) * grid_export_price;
net_grid_cost = annual_grid_cost - annual_grid_revenue;

% Total Annual Cost
total_annual_cost = total_opex + net_grid_cost;

% Levelized Cost of Energy (20-year project)
project_lifetime = 20; % years
discount_rate = 0.05; % 5%
npv_capex = total_capex;
npv_opex = total_annual_cost * ((1 - (1+discount_rate)^(-project_lifetime))/discount_rate);
total_npc = npv_capex + npv_opex;
total_energy_delivered = total_load * project_lifetime;
lcoe = total_npc / total_energy_delivered;

% Payback Period (Simple)
grid_only_cost = total_load * grid_import_cost; % Cost without microgrid
annual_savings = grid_only_cost - total_annual_cost;
payback_period = total_capex / annual_savings;

% CO2 Emissions Reduction
grid_emission_factor = 0.82; % kg CO2 per kWh (SA grid average)
annual_co2_reduction = (total_renewable - total_grid_import) * grid_emission_factor / 1000; % tonnes

%% 10. DISPLAY RESULTS

fprintf('\n========== KANGAROO ISLAND MICROGRID SIMULATION RESULTS ==========\n\n');

fprintf('SYSTEM CONFIGURATION:\n');
fprintf('  PV Capacity:        %.1f kW\n', pv_capacity);
fprintf('  Wind Capacity:      %.1f kW\n', wt_capacity);
fprintf('  Battery Capacity:   %.1f kWh\n', battery_capacity);
fprintf('  Battery Power:      %.1f kW\n\n', battery_power);

fprintf('ENERGY PERFORMANCE:\n');
fprintf('  Annual Load:        %.1f MWh\n', total_load/1000);
fprintf('  PV Generation:      %.1f MWh (%.1f%%)\n', total_pv_gen/1000, (total_pv_gen/total_load)*100);
fprintf('  Wind Generation:    %.1f MWh (%.1f%%)\n', total_wt_gen/1000, (total_wt_gen/total_load)*100);
fprintf('  Total Renewable:    %.1f MWh\n', total_renewable/1000);
fprintf('  Grid Import:        %.1f MWh\n', total_grid_import/1000);
fprintf('  Grid Export:        %.1f MWh\n\n', total_grid_export/1000);

fprintf('PERFORMANCE METRICS:\n');
fprintf('  Renewable Fraction: %.1f%%\n', renewable_fraction);
fprintf('  Self-Sufficiency:   %.1f%%\n', self_sufficiency);
fprintf('  LPSP:               %.2f%%\n', lpsp);
fprintf('  PV Capacity Factor: %.1f%%\n', cf_pv);
fprintf('  Wind Cap. Factor:   %.1f%%\n\n', cf_wt);

fprintf('ECONOMIC ANALYSIS:\n');
fprintf('  Total CAPEX:        $%.0f AUD\n', total_capex);
fprintf('  Annual OPEX:        $%.0f AUD/year\n', total_opex);
fprintf('  Net Grid Cost:      $%.0f AUD/year\n', net_grid_cost);
fprintf('  Total Annual Cost:  $%.0f AUD/year\n', total_annual_cost);
fprintf('  LCOE:               $%.3f AUD/kWh\n', lcoe);
fprintf('  Payback Period:     %.1f years\n', payback_period);
fprintf('  Annual CO2 Saved:   %.1f tonnes\n\n', annual_co2_reduction);

%% 11. VISUALIZATION

% Figure 1: One Week Sample
figure('Position', [100 100 1200 800]);
week_hours = 1:168; % First week

subplot(3,2,1);
plot(week_hours, load_demand(week_hours), 'k', 'LineWidth', 1.5);
xlabel('Hour of Week'); ylabel('Power (kW)');
title('Farm Load Demand (Week 1)');
grid on;

subplot(3,2,2);
plot(week_hours, pv_generation(week_hours), 'b', 'LineWidth', 1.5);
hold on;
plot(week_hours, wt_generation(week_hours), 'r', 'LineWidth', 1.5);
plot(week_hours, renewable_gen(week_hours), 'g', 'LineWidth', 2);
xlabel('Hour of Week'); ylabel('Power (kW)');
title('Renewable Generation (Week 1)');
legend('PV', 'Wind', 'Total', 'Location', 'best');
grid on;

subplot(3,2,3);
plot(week_hours, battery_soc(week_hours)*100, 'm', 'LineWidth', 2);
xlabel('Hour of Week'); ylabel('SOC (%)');
title('Battery State of Charge (Week 1)');
ylim([0 100]);
grid on;

subplot(3,2,4);
bar(week_hours, [grid_import(week_hours)', -grid_export(week_hours)'], 'stacked');
xlabel('Hour of Week'); ylabel('Power (kW)');
title('Grid Interaction (Week 1)');
legend('Import', 'Export', 'Location', 'best');
grid on;

subplot(3,2,5);
area(week_hours, [pv_generation(week_hours)', wt_generation(week_hours)']);
hold on;
plot(week_hours, load_demand(week_hours), 'k--', 'LineWidth', 2);
xlabel('Hour of Week'); ylabel('Power (kW)');
title('Supply vs Demand (Week 1)');
legend('PV', 'Wind', 'Load', 'Location', 'best');
grid on;

subplot(3,2,6);
power_balance = renewable_gen(week_hours) + battery_discharge(week_hours)*battery_efficiency ...
    - battery_charge(week_hours)/battery_efficiency + grid_import(week_hours) - grid_export(week_hours);
plot(week_hours, power_balance, 'g', 'LineWidth', 1.5);
hold on;
plot(week_hours, load_demand(week_hours), 'k--', 'LineWidth', 1.5);
xlabel('Hour of Week'); ylabel('Power (kW)');
title('Power Balance Verification (Week 1)');
legend('Supply', 'Demand', 'Location', 'best');
grid on;

sgtitle('Kangaroo Island Microgrid - Weekly Performance', 'FontSize', 14, 'FontWeight', 'bold');

% Figure 2: Annual Summary
figure('Position', [150 150 1200 600]);

subplot(2,3,1);
bar([total_pv_gen/1000, total_wt_gen/1000, total_grid_import/1000]);
set(gca, 'XTickLabel', {'PV', 'Wind', 'Grid'});
ylabel('Energy (MWh/year)');
title('Annual Energy Sources');
grid on;

subplot(2,3,2);
pie([total_pv_gen, total_wt_gen, total_grid_import], ...
    {'PV', 'Wind', 'Grid Import'});
title('Energy Mix');

subplot(2,3,3);
bar([pv_capex/1000, wt_capex/1000, battery_capex/1000]);
set(gca, 'XTickLabel', {'PV', 'Wind', 'Battery'});
ylabel('Cost (k AUD)');
title('Capital Costs');
grid on;

subplot(2,3,4);
monthly_gen = zeros(12, 1);
for m = 1:12
    month_idx = (m-1)*730+1:min(m*730, hours);
    monthly_gen(m) = sum(renewable_gen(month_idx))/1000;
end
bar(monthly_gen);
xlabel('Month'); ylabel('Energy (MWh)');
title('Monthly Renewable Generation');
grid on;

subplot(2,3,5);
histogram(battery_soc*100, 30);
xlabel('State of Charge (%)'); ylabel('Frequency');
title('Battery SOC Distribution');
grid on;

subplot(2,3,6);
bar([renewable_fraction, self_sufficiency, 100-lpsp]);
set(gca, 'XTickLabel', {'Renewable%', 'Self-Suff%', 'Reliability%'});
ylabel('Percentage (%)');
title('Performance Indicators');
ylim([0 110]);
grid on;

sgtitle('Kangaroo Island Microgrid - Annual Summary', 'FontSize', 14, 'FontWeight', 'bold');

fprintf('========== SIMULATION is Now COMPLETE ==========\n\n');