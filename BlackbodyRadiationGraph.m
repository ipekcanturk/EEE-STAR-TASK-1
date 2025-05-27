% ===============================
% BLACKBODY RADIATION PLOTTER
% ===============================
% This script plots spectral irradiance vs. wavelength
% for blackbody temperatures: 6000 K, 1500 K, and 300 K
% using Planck's Law, with both axes in log scale

%Physical Constants
h = 6.626e-34;     % Planck's constant (J·s)
c = 3e8;           % Speed of light (m/s)
k = 1.381e-23;     % Boltzmann constant (J/K)

%Wavelength range: 0.1 µm to 100 µm
lambda_um = logspace(-1, 2, 1000);  % in micrometers
lambda_m = lambda_um * 1e-6;        % convert to meters

%Temperatures (K)
T_values = [6000, 1500, 300];

%Planck's Law as an inline function
planck = @(lambda, T) (2*h*c^2) ./ (lambda.^5 .* (exp((h*c)./(lambda*k*T)) - 1));

%Plot Setup
figure;
hold on;

% Loop over temperatures and plot each
for T = T_values
    I = planck(lambda_m, T);  % calculate spectral irradiance
    
    %Avoid log(0) issues
    I(I <= 0) = NaN;
    
    % Plot in log-log scale
    loglog(lambda_um, I, 'DisplayName', [num2str(T) ' K']);
end

%Set axis properties
set(gca, 'XScale', 'log', 'YScale', 'log');  % FORCE log scale
xlabel('Wavelength [\mum]');
ylabel('Spectral Irradiance [W/m^2/\mum]');
title('Blackbody Radiation at Different Temperatures');
legend show;
grid on;
xlim([0.1, 100]);     % Optional: zoom into useful range
ylim([1, 1e15]);     % Optional: adjust for visibility