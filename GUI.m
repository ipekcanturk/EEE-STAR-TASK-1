% BLACKBODY AND SOLAR SPECTRA GUI EXPLORER
% MATLAB app to interactively explore blackbody radiation and real solar spectra (AM0, AM1.5G)

function GUI
    %% Load and preprocess spectral data
    am0    = readmatrix('AM0_RAW_DATA.xlsx',   'Sheet','Spectrum');  % [Wavelength_nm, Irradiance]
    am15g  = readmatrix('AM1.5G_RAW_DATA.xlsx','Sheet','Spectrum');
    lambda_nm   = am0(:,1);                  % in nanometers
    lambda_m    = lambda_nm * 1e-9;          % convert nm → meters
    lambda_um   = lambda_nm / 1e3;           % convert nm → micrometers
    am0_irr     = am0(:,2);                  % AM0 irradiance [W/m^2/nm]
    am15g_irr   = am15g(:,2);                % AM1.5G irradiance [W/m^2/nm]

    %% Determine screen size and center figure
    screenSize = get(0, 'ScreenSize');       % [left bottom width height]
    figWidth   = 900;
    figHeight  = 600;
    figLeft    = (screenSize(3) - figWidth) / 2;
    figBottom  = (screenSize(4) - figHeight) / 2;

    %% Create UI figure and axes
    fig = uifigure('Name','Spectral Explorer','Position',[figLeft, figBottom, figWidth, figHeight]);
    ax  = uiaxes(fig,'Position',[50 150 figWidth-100 figHeight-180]);

    %% Temperature slider
    uilabel(fig, 'Position',[50 100 100 22], 'Text','Temperature (K)');
    sldT = uislider(fig, 'Position',[160 110 figWidth-260 3], 'Limits',[300 10000], 'Value',6000);
    sldT.ValueChangedFcn = @(s,e) updatePlot();

    %% Max wavelength slider
    uilabel(fig, 'Position',[50 60 130 22], 'Text','Max Wavelength (µm)');
    sldW = uislider(fig, 'Position',[160 70 figWidth-260 3], 'Limits',[lambda_um(1) lambda_um(end)], 'Value',4);
    sldW.ValueChangedFcn = @(s,e) updatePlot();

    %% Spectrum checkboxes
    cbBB   = uicheckbox(fig,'Position',[figWidth-120 330 100 22],'Text','Blackbody','Value',true);
    cbAM0  = uicheckbox(fig,'Position',[figWidth-120 300 100 22],'Text','AM0','Value',true);
    cbAM15 = uicheckbox(fig,'Position',[figWidth-120 270 100 22],'Text','AM1.5G','Value',true);
    cbBB.ValueChangedFcn   = @(s,e) updatePlot();
    cbAM0.ValueChangedFcn  = @(s,e) updatePlot();
    cbAM15.ValueChangedFcn = @(s,e) updatePlot();

    %% Planck's law nested function
    function I = planck(lm, T)
        h = 6.626e-34; c = 3e8; k = 1.381e-23;
        I = (2*h*c^2) ./ (lm.^5 .* (exp((h*c) ./ (lm*k*T)) - 1));
    end

    %% Plotting function
    function updatePlot()
        T      = sldT.Value;
        maxW   = sldW.Value;
        mask   = lambda_um <= maxW;
        cla(ax); hold(ax,'on');

        legendEntries = {};
        if cbBB.Value
            bb = planck(lambda_m(mask), T) * 1e-9;  % convert W/m^2/m → W/m^2/nm
            plot(ax, lambda_um(mask), bb, 'k', 'LineWidth',1.5);
            legendEntries{end+1} = sprintf('Blackbody %dK', round(T));
        end
        if cbAM0.Value
            plot(ax, lambda_um(mask), am0_irr(mask), 'b--');
            legendEntries{end+1} = 'AM0';
        end
        if cbAM15.Value
            plot(ax, lambda_um(mask), am15g_irr(mask), 'r:');
            legendEntries{end+1} = 'AM1.5G';
        end

        ax.XScale = 'log';  ax.YScale = 'log';
        xlabel(ax,'Wavelength (µm)');
        ylabel(ax,'Spectral Irradiance (W/m^2/nm)');
        title(ax,'Spectral Irradiance Explorer');
        legend(ax, legendEntries,'Location','southwest');
        grid(ax,'on');
        hold(ax,'off');
    end

    %% Initial plot
    updatePlot();
end