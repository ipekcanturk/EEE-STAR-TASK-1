clc;
clear;

%% 1. Physical constants
h = 6.626e-34;    % Planck's constant [J·s]
c = 3e8;          % Speed of light [m/s]
k = 1.381e-23;    % Boltzmann constant [J/K]

%% 2. Read Excel and convert to CSV
% Reads numeric data from the 'Spectrum' sheet (skips header row automatically)
am0_data   = readmatrix('AM0_RAW_DATA.xlsx',   'Sheet','Spectrum');  
am15g_data = readmatrix('AM1.5G_RAW_DATA.xlsx','Sheet','Spectrum');

% Write out CSV versions for any downstream use
writematrix(am0_data,   'AM0.csv');
writematrix(am15g_data, 'AM1.5G.csv');

%% 3. Extract wavelength and irradiance
% Column order: [Wavelength_nm, SpectralIrradiance_W_per_m2_per_nm, ...]
lambda_nm   = am0_data(:,1);         % shared wavelength grid in nm
am0_irr     = am0_data(:,2);         % AM0 irradiance [W/m^2/nm]
am15g_irr   = am15g_data(:,2);       % AM1.5G irradiance [W/m^2/nm]

% Convert to meters (for Planck) and micrometers (for plotting)
lambda_m  = lambda_nm * 1e-9;        % nm → m
lambda_um = lambda_nm / 1e3;         % nm → µm

%% 4. Compute 6000 K blackbody spectrum (Planck's law)
T = 6000;  
bb_irr_m = (2*h*c^2) ./ (lambda_m.^5 .* (exp((h*c)./(lambda_m*k*T)) - 1));  
bb_irr   = bb_irr_m * 1e-9;          % Convert from per-m to per-nm [W/m^2/nm]

%% 5. Plot on log–log scale
figure;
loglog(lambda_um, bb_irr,   'k',  'LineWidth',1.5); hold on;
loglog(lambda_um, am0_irr,  'b--');
loglog(lambda_um, am15g_irr,'r:');
hold on
H2Ox = [0.937,1.135,2.7];
H2Oy = [0.163,0.0154,0.0002];
O3x = 0.28;
O3y = 4.72e-23;
O2x = 0.761;
O2y = 0.154;
CO2x = [1.391,1.89];
CO2y = [0.0003,0.0002];
plot(H2Ox,H2Oy,'o','MarkerSize',3,'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
plot(O3x,O3y,'o','MarkerSize',3,'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g')
plot(O2x,O2y,'o','MarkerSize',3,'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'c')
plot(CO2x,CO2y,'o','MarkerSize',3,'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm')
xlabel('Wavelength (\mum)');
ylabel('Spectral Irradiance (W/m^2/nm)');
title('Spectral Irradiance: 6000K Blackbody vs AM0 and AM1.5G (Log Scale)');
legend('6000K Blackbody','AM0','AM1.5G','Location','southeast');
grid on;
xlim([0.2,4.8]);
hold off
%% 6. Plot on linear scale
figure;
plot(lambda_um, bb_irr,   'k','LineWidth',1.5); hold on;
plot(lambda_um, am0_irr,  'b--');
plot(lambda_um, am15g_irr,'r:');
xlabel('Wavelength (\mum)');
ylabel('Spectral Irradiance (W/m^2/nm)');
title('Spectral Irradiance Comparison (Linear Scale)');
legend('6000K Blackbody','AM0','AM1.5G','Location','Best');
grid on;
xlim([0.2,2.5]);
ylim([0,2.5]);  % adjust if needed

%% 
% mask for full AM1.5G range 250–4000 nm
mask_total = (lambda_nm >= 250) & (lambda_nm <= 4000);

% total AM1.5G intensity [W/m^2]
I_total = trapz(lambda_nm(mask_total), am15g_irr(mask_total));

% silicon bandgap and cutoff wavelength
eV = 1.602e-19;    % J per eV
Eg = 1.12;         % Si bandgap in eV
lambda_cutoff_m  = h*c/(Eg*eV);     % in meters
lambda_cutoff_nm = lambda_cutoff_m * 1e9;  % in nm ≈1108

% mask for photons above bandgap (λ ≤ cutoff)
mask_usable = mask_total & (lambda_nm <= lambda_cutoff_nm);

% usable intensity [W/m^2]
I_usable = trapz(lambda_nm(mask_usable), am15g_irr(mask_usable));

% display results
fprintf('Total AM1.5G (250–4000 nm):      %.1f W/m^2\n', I_total);
fprintf('Usable by Si (λ ≤ %.0f nm):       %.1f W/m^2\n', lambda_cutoff_nm, I_usable);
fprintf('Fraction usable by Si:            %.1f%%\n', 100 * I_usable / I_total);

% Electron–Hole Pair Mechanism (in-code comments)
%
%   % A photon of energy E_photon = (h*c)/(lambda_nm*1e-9) [J] arrives.
%   % If E_photon < Eg*eV (i.e. lambda_nm > lambda_cutoff_nm), it passes through.
%   % If E_photon ≥ Eg*eV, it is absorbed:
%   %    - elevates one electron to conduction band → creates an electron–hole pair
%   %    - leaves a “hole” in the valence band
%   %    - excess energy (E_photon − Eg*eV) is lost as heat (thermalization)
%   % These carriers can then be separated by the built-in field (p–n junction)
%   % and collected as photocurrent if they don’t recombine first.
