%% Plot for Top 3 Satellites with Clean Arcs
co = colororder;
gsIdx = 5;
maxElPerSat = squeeze(max(ElLEO(gsIdx, :, :), [], 3));
[~, sortedIdx] = sort(maxElPerSat, 'descend');
topN = 1;

figure; polaraxes; hold on

for i = 1:topN
    s = sortedIdx(i);
    az = squeeze(leoAzimuth(gsIdx, s, :));
    el = squeeze(ElLEO(gsIdx, s, :));
    
    visible = el > 0;
    if any(visible)
        azVisible = az(visible);
        elVisible = el(visible);
        r = 90 - elVisible;

        % Plot pass arc
        polarplot(azVisible, r, 'color',co(i,:),'LineWidth', 1.5,'DisplayName', sprintf('LEO-%d', s));

        % AOS and LOS markers
        polarplot(azVisible(1), r(1), 'kx', 'color',co(i,:),'MarkerSize', 8, 'LineWidth', 1.2,'DisplayName', sprintf('AOS point-%d', s));
        polarplot(azVisible(end), r(end), 'ko', 'color',co(i,:),'MarkerSize', 8, 'LineWidth', 1.2,'DisplayName', sprintf('LOS point-%d', s));
    end
end

rlim([0 90]); rticks([0 30 60 90]);
thetaticks(0:30:330);
title(sprintf('Sky Plot of Top %d Visible Passes from GS-%d', topN, gsIdx));
legend;
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',12);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points

% legend('Pass arc', 'AOS point', 'LOS point');
%% Plot for Top 3 Satellites for various time steps
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual', 'PaperUnits', 'inches', ...
    'PaperPosition', [0 0 3.5*2 3.5*2/1.618*Scale], 'Position', [200 300 800 800/1.618*Scale]);
co = colororder;
gsIdx = 5;
maxElPerSat = squeeze(max(ElLEO(gsIdx, :, :), [], 3));
[~, sortedIdx] = sort(maxElPerSat, 'descend');
topSats = sortedIdx(1:3);
for i = 1:3
    subplot(1, 3, i);
    s = topSats(i);
    az = squeeze(leoAzimuth(gsIdx, s, :));
    el = squeeze(ElLEO(gsIdx, s, :));
    visible = el > 0;

    if any(visible)
        r = 90 - el(visible);
        polarplot(az(visible), r, 'color', co(i,:), 'LineWidth', 1.5); hold on;
        polarplot(az(find(visible, 1, 'first')), r(1), 'kx', 'color', co(i,:), 'MarkerSize', 8, 'LineWidth', 1.2);
        polarplot(az(find(visible, 1, 'last')), r(end), 'ko', 'color', co(i,:), 'MarkerSize', 8, 'LineWidth', 1.2);
        title(sprintf('LEO-%d', s));
    else
        title(sprintf('LEO-%d (Not Visible)', s));
    end

    rlim([0 90]); rticks([0 30 60 90]); thetaticks(0:30:330);
end
% sgtitle(sprintf('Sky Plots of Top 3 Visible LEO Satellites from GS-%d', gsIdx), 'FontWeight', 'bold');
ax = gca; grid on;
ax.Box = 'on';
set(gca, 'LooseInset', get(gca, 'TightInset'));
saveLocation = './'
Filename = fullfile(saveLocation, 'Figure3');
print(h_Fig, '-dpng','-r600', Filename);
%% Plot elvation of a signal pass satellite
clc; clear;close all hidden;
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual', 'PaperUnits', 'inches', ...
    'PaperPosition', [0 0 3.5*2 3.5*2/1.618*Scale], 'Position', [200 300 800 800/1.618*Scale]);
co = colororder;
startTime   = datetime(2025, 3, 22, 12, 00, 0);   % Scenario start time (UTC)
stopTime    = startTime + hours(1);             % Total scenario duration
sampleTime  = 30;                                % Time step (seconds)
Re = earthRadius;                                % Earth radius in meters
% Create satellite scenario
sc = satelliteScenario(startTime, stopTime, sampleTime);
% Add LEO Satellite (NGSO)
alt_NGSO = 500e3;                    % LEO altitude in meters
sma_NGSO = Re + alt_NGSO;
ecc_NGSO = 0;
inc_NGSO  = 90;                      % Polar orbit
raan_NGSO = 0;
argPeriapsis_NGSO = 0.0;
trueAnomaly_NGSO = -10;

satNGSO = satellite(sc, ...
    sma_NGSO, ecc_NGSO, inc_NGSO, ...
    raan_NGSO, argPeriapsis_NGSO, trueAnomaly_NGSO, ...
    "Name", "NGSO");

% --- Ground Station (e.g., near Kampala, Uganda)
gsLat = 10;     % Latitude [degrees]
gsLon = 12;    % Longitude [degrees]
gsAlt = 0;       % Altitude [m]

gs = groundStation(sc, ...
    "Latitude", gsLat, ...
    "Longitude", gsLon, ...
    "Altitude", gsAlt, ...
    "Name", "GS");
% Get times of access and az/el angles
accessInfo = access(satNGSO, gs);
[az,el, ~] = aer(gs,satNGSO);
% Only keep visible times (El > 0)
visible = el > 0;
azVisible = deg2rad(az(visible));
rVisible = 90 - el(visible); % Polar radius = 90 - elevation

% --- Create the skyplot
ax = polaraxes;
set(pax, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');
hold(pax, 'on');

% Plot pass arc
polarplot(pax, azVisible, rVisible, '-', 'color', co(2,:),'LineWidth', 2, 'DisplayName', 'Satellite Pass');

% Mark AOS and LOS
polarplot(pax, azVisible(1), rVisible(1), 'x', 'color', co(2,:), 'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'AOS');
polarplot(pax, azVisible(end), rVisible(end), 'o','color', co(2,:), 'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'LOS');
%% Elveation angle for a single satellite Pass 
clc; clear; close all hidden;
clc; clear;close all hidden;
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual', 'PaperUnits', 'inches', ...
    'PaperPosition', [0 0 3.5*2 3.5*2/1.618*Scale], 'Position', [200 300 800 800/1.618*Scale]);
co = colororder;
startTime   = datetime(2025, 1, 22, 12, 00, 0);   
stopTime    = startTime + hours(1.5);             
sampleTime  = 30;                                % Use smaller timestep for smoother arc
Re = earthRadius;

% Create satellite scenario
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Add LEO Satellite (Polar Orbit)
alt_NGSO = 500e3;                    % Altitude in meters
sma_NGSO = Re + alt_NGSO;
satNGSO = satellite(sc, sma_NGSO, 0, 97.44, -25.63, 90, -170, "Name", "NGSO");

% Add Ground Station
gsLat = 10; gsLon = 25; gsAlt = -155;
gs = groundStation(sc, "Latitude", gsLat, "Longitude", gsLon, "Altitude", gsAlt, "Name", "GS");

% Get azimuth/elevation over time
[az, el, ~] = aer(gs, satNGSO);
visible = el > 0;
azVisible = deg2rad(az(visible));
rVisible = 90 - el(visible);

% Plot skyplot
pax = polaraxes;
set(pax, 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');
hold(pax, 'on');

% Plot satellite pass arc
polarplot(pax, azVisible, rVisible, '-', 'color', co(2,:),'LineWidth', 2, 'DisplayName', 'Satellite Pass');

% Mark AOS and LOS
polarplot(pax, azVisible(1), rVisible(1), 'x', 'color', co(2,:),'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'AOS');
polarplot(pax, azVisible(end), rVisible(end), 'o','color', co(2,:), 'MarkerSize', 10, 'LineWidth', 1.5, 'DisplayName', 'LOS');

% Add minimum elevation mask (e.g., 10°)
minEl = 10;  
polarplot(pax, linspace(0, 2*pi, 360), repmat(90 - minEl, 1, 360), 'k--', 'LineWidth', 1.5, 'DisplayName', 'Min Elevation');

% Labels and grid
rlim([0 90]);
rticks([0 30 60 90]);
thetaticks(0:30:330);
% title('Sky Plot of Single LEO Pass over Ground Station');
legend;
ax = gca; grid on;
ax.Box = 'on';
set(gca, 'LooseInset', get(gca, 'TightInset'));
saveLocation = './'
Filename = fullfile(saveLocation, 'Figure3');
print(h_Fig, '-dpng','-r600', Filename);
%% Plot ANtenna Gain
% Define synthetic 1D angular axes
Az = linspace(-pi, pi, 200);              % Azimuth angle range
OffNadir = linspace(-pi/2, pi/2, 100);        % Off-nadir angle range

% Create 2D meshgrid from 1D vectors
[AzGrid, OffGrid] = meshgrid(Az, OffNadir);
leo.psi = deg2rad(10);           % LEO satellite beamwidth in radian (θ3dB=2∘,5∘,10∘)
alfa = 0.25;
% Apply gain pattern formula
% Gain2D  =  ((  0.886* abs(sinc( OffGrid / rad2deg(leo.psi))).^2 ) ...
%            .* ( abs(  0.886* sinc(AzGrid / rad2deg(leo.psi))).^2 ));
Gain2D  =  ((  0.886* abs(sinc( alfa*OffGrid / leo.psi)).^2 ) ...
           .* ( abs(  0.886* sinc(alfa* AzGrid / leo.psi)).^2 ));
% Plot
figure;
imagesc(Az, OffNadir, Gain2D);
xlabel('Azimuth (rad)');
ylabel('Off-Nadir Angle (rad)');
colorbar;
title('2D Antenna Gain Pattern');
axis xy;  % Make Y-axis go from bottom to top

figure;
surf(AzGrid, OffGrid, Gain2D);
xlabel('Azimuth'); ylabel('Off-Nadir'); zlabel('Gain');
shading interp; colorbar;
title('2D Antenna Gain Pattern Surface');

%%
% Angular axes
Az = linspace(-pi, pi, 300);               % Azimuth
OffNadir = linspace(-pi/2, pi/2, 150);         % Off-nadir

[AzGrid, OffGrid] = meshgrid(Az, OffNadir);

% Desired beamwidths
beamAz = deg2rad(5);  % 5° beamwidth
beamEl = deg2rad(5);  % 5° beamwidth

% Normalize the angle by beamwidth (main lobe centered at 0)
sAz = AzGrid / beamAz;
sEl = OffGrid / beamEl;

% Apply sinc-squared pattern (well-behaved)
Gain2D = (sinc(sAz)).^2 .* (sinc(sEl)).^2;

% Normalize to dB
GainMax = 35;  % Peak gain in dBi
Gain2D_dB = GainMax + 10*log10(Gain2D + eps);  % Avoid log(0)

% Limit to reasonable dynamic range
Gain2D_dB = max(Gain2D_dB, GainMax - 40);

% 2D dB plot
figure;
imagesc(Az, OffNadir, Gain2D_dB);
xlabel('Azimuth (rad)'); ylabel('Off-Nadir (rad)');
title('2D Antenna Gain Pattern (dBi)');
colorbar; axis xy;
caxis([GainMax - 40, GainMax]);

% 3D dB plot
figure;
surf(AzGrid, OffGrid, Gain2D_dB);
xlabel('Azimuth'); ylabel('Off-Nadir'); zlabel('Gain (dBi)');
title('2D Antenna Gain Pattern Surface');
shading interp; colorbar;
caxis([GainMax - 40, GainMax]);
