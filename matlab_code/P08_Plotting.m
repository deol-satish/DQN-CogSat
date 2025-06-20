%% Beam Footprint Circle on Ground from multiple satellites
% Settings
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],...
    'Position',[200 300 800 800/1.618*Scale]);
tIdx = 2;
thetaEdge = deg2rad(2);   % Beam edge angle
Re = E.SemimajorAxis;
% Australia bounding box
latMin = -45; latMax = -10;
lonMin = 110; lonMax = 155;
geoscatter(cell2mat(GsLocations(:,2)), cell2mat(GsLocations(:,3)), 30, 'k', 'filled'); hold on
% Loop over all satellites
numSats = size(satPos, 2);
for satIdx = 1:numSats
    sat_xyz = satPos(:, satIdx, tIdx);
    [latSat, lonSat, hSat] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));

    % Check if satellite is over Australia
    if (latSat >= latMin && latSat <= latMax && lonSat >= lonMin && lonSat <= lonMax)
        % Compute footprint radius
        r_foot = Re * asin((Re / (Re + hSat)) * sin(thetaEdge));
        r_foot_deg = rad2deg(r_foot / Re);
        % Create circle
        angles = linspace(0, 2*pi, 360);
        latCircle = latSat + r_foot_deg * cos(angles);
        lonCircle = lonSat + r_foot_deg * sin(angles) ./ cosd(latSat);
        % Plot satellite subpoint and footprint
        geoscatter(latSat, lonSat, 100, 'r', 'filled');
        geoplot(latCircle, lonCircle, 'b-', 'LineWidth', 1.5);
    end
end
title(sprintf('LEO Satellites Over Australia at t = %d', tIdx));
legend('Ground Stations', 'Satellite Subpoints', 'Beam Footprints');
geobasemap streets;
ax = gca; grid on; ax.Box = 'on';
set(gca, 'LooseInset', get(gca, 'TightInset'), 'FontSize', 12);
ax.LineWidth = 1;
%% Beam Footprint Circle on Ground from multiple satellites with differnt beam widths
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],...
    'Position',[200 300 800 800/1.618*Scale]);
tIdx = 2;
Re = E.SemimajorAxis;
% Australia bounding box
latMin = -45; latMax = -10;
lonMin = 110; lonMax = 155;
% Beam edge angles to compare (in degrees)
thetaEdges_deg = [2, 5, 8];
colors = lines(length(thetaEdges_deg));  % Assign distinct colors
geoscatter(cell2mat(GsLocations(:,2)), cell2mat(GsLocations(:,3)), 30, 'k', 'filled'); hold on
% Loop over satellites
numSats = size(satPos, 2);
for satIdx = 1:numSats
    sat_xyz = satPos(:, satIdx, tIdx);
    [latSat, lonSat, hSat] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));

    % Check if satellite is over Australia
    if (latSat >= latMin && latSat <= latMax && lonSat >= lonMin && lonSat <= lonMax)
        % Plot subpoint
        geoscatter(latSat, lonSat, 100, 'r', 'filled');
        % Loop over each beam angle
        for b = 1:length(thetaEdges_deg)
            thetaEdge = deg2rad(thetaEdges_deg(b));
            % Compute footprint radius
            r_foot = Re * asin((Re / (Re + hSat)) * sin(thetaEdge));
            r_foot_deg = rad2deg(r_foot / Re);
            % Generate circle
            angles = linspace(0, 2*pi, 360);
            latCircle = latSat + r_foot_deg * cos(angles);
            lonCircle = lonSat + r_foot_deg * sin(angles) ./ cosd(latSat);
            % Plot with assigned color
            geoplot(latCircle, lonCircle, '-', 'LineWidth', 1.5, 'Color', colors(b,:));
        end
    end
end
% title(sprintf('LEO footprint over Australia with various beamwidth at t = %d', tIdx));
legendEntries = ["Ground Stations", "Satellite Subpoint", ...
    strcat("\theta_{edge} = ", string(thetaEdges_deg), "°")];
legend(legendEntries, 'Location', 'best');
geobasemap streets;
ax = gca; grid on; ax.Box = 'on';
set(gca, 'LooseInset', get(gca, 'TightInset'), 'FontSize', 14);
ax.LineWidth = 1;
saveLocation = './'
exportgraphics(h_Fig, fullfile(saveLocation, 'Figure12.png'), 'Resolution', 600)
%% Plot cities coverage from specific satellite
% Step 1: Pick satellite and time
satIdx = 1;
timeIdx = 10;
% Step 2: Get theta values in degrees for this sat/time
theta_deg = rad2deg(leotheta(:, satIdx, timeIdx));  % [20x1]
% Step 3: Extract lat/lon from GsLocations
lat = cell2mat(GsLocations(:,2));
lon = cell2mat(GsLocations(:,3));
% Step 4: Visualize on map
figure;
geoscatter(lat, lon, 60, theta_deg, 'filled');
geobasemap streets
% colorbar;
title(sprintf('Beam Footprint for Sat #%d at t = %d', satIdx, timeIdx));
colormap turbo
clim([0 max(theta_deg)]);
legend('Off-axis angle (°)')
%% Plot only in-beam cities from specific satellite
% Step 1: Pick satellite and time
satIdx = 2;
timeIdx = 10;
beamwidth_deg = rad2deg(leo.psi);
% Step 2: Get theta values in degrees for this sat/time
theta_deg = rad2deg(leotheta(:, satIdx, timeIdx));  % [20x1]
% Step 3: Extract lat/lon from GsLocations
lat = cell2mat(GsLocations(:,2));
lon = cell2mat(GsLocations(:,3));
% Identify in-beam stations
inBeam = theta_deg <= beamwidth_deg;
% Filter lat/lon for in-beam stations
lat_inbeam = lat(inBeam);
lon_inbeam = lon(inBeam);
% Plot
figure;
geoscatter(lat_inbeam, lon_inbeam, 100, 'g', 'filled', 'MarkerEdgeColor', 'k');
geobasemap streets
title(sprintf('In-Beam Ground Stations (θ ≤ %.1f°)', beamwidth_deg));
legend('In-Beam Station', 'Location', 'best')
%% Plot different antenna gain pattern
% Parameters
theta = linspace(0, deg2rad(15), 300);   % Off-nadir angle in radians
phi = linspace(0, 2*pi, 300);            % Azimuth in radians
[Theta, Phi] = meshgrid(theta, phi);
% Antenna settings
GainMax = 35;             % dB
theta3dB = deg2rad(5);    % 3dB beamwidth
a = 1.3;
rippleDepth = 0.6;
rippleFreq = 4;
% Pattern 1: Parabolic antenna
GtxLEO1 = GainMax - 12 * (Theta / theta3dB).^2;

% Pattern 2: 2D Sinc pattern (adjust input to sinc to match MATLAB's definition)
Gain2 = (sinc(Theta / a / pi)).^2 .* (1 - rippleDepth * abs(sin(rippleFreq * Phi)));
GtxLEO2 = 10 * log10(max(Gain2, 1e-6));

% Pattern 3: Cosine power pattern
Gain3 = cos(Theta).^rippleFreq .* (1 - 0.5 * rippleDepth * sin(2 * Phi).^2);
GtxLEO3 = 10 * log10(max(Gain3, 1e-6));

% Convert theta to degrees
theta_deg = rad2deg(theta);

% Plot azimuth cut at φ = 0
phi_idx = 1;  % slice at first azimuth
minGain = -40;  % Show up to -40 dB sidelobes
figure;
subplot(1, 3, 1)
polarplot(deg2rad(theta_deg), GtxLEO1(phi_idx, :), 'LineWidth', 1.5)
title('Parabolic Pattern')
rlim([minGain, GainMax])

subplot(1, 3, 2)
polarplot(deg2rad(theta_deg), GtxLEO2(phi_idx, :), 'LineWidth', 1.5)
title('2D Sinc Pattern')
rlim([minGain, GainMax])

subplot(1, 3, 3)
polarplot(deg2rad(theta_deg), GtxLEO3(phi_idx, :), 'LineWidth', 1.5)
title('Cosine Power Pattern')
rlim([minGain, GainMax])
%% Plot 2D LEO Antenna Gain Pattern (Azimuth vs Off-Nadir)
% Angular Grid (Off-nadir and Azimuth)
theta = linspace(0, pi/2, 300);            % Off-nadir angle: 0 to 90 deg
phi = linspace(0, 2*pi, 300);              % Azimuth: 0 to 360 deg
[TH, PHI] = meshgrid(theta, phi);          % Create 2D angle grid

% Gain Pattern: Cosine Power Model with Azimuth Ripple
G = leo.GainMax + 10*log10(cos(TH).^leo.AntRipfreq.* (1 - 0.5 * leo.AntRipDepth* sin(2*PHI).^2));

% Clip Gain for numerical stability (optional)
G(~isfinite(G)) = NaN;  % Mask invalid values

% Convert polar to Cartesian for plotting
[XX, YY] = pol2cart(PHI, rad2deg(TH));

% Plot Gain Pattern
figure;
p = pcolor(XX, YY, G);
shading interp;
colormap jet;
colorbar;
clim([leo.GainMax - 40, leo.GainMax]);  % Optional dB range
title('LEO 2D Antenna Gain Pattern (Azimuth vs Off-Nadir)');
xlabel('Azimuth X [°]');
ylabel('Azimuth Y [°]');
axis equal;
grid on;
%% Plot footprint of the satellites
% Define beamwidth and radius (approximate projection onto Earth surface)
co = colororder;
Scale = 1;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
% The arc raduis on the groung
% beamRadius_deg = (earthRadius/2) * (asin((1/walker.alfa) * sin(leo.psi/2)) - leo.psi/2);
beamRadius_deg = rad2deg(leo.psi);
% Number of satellites and time steps
numLEO = leoNum;
numT = length(ts);
% Preallocate subsatellite lat/lon arrays
subLat = zeros(numLEO, numT);
subLon = zeros(numLEO, numT);
latCirc = cell(numLEO, numT);
lonCirc = cell(numLEO, numT);
% Loop over each satellite and timestep
for s = 1:numLEO
    for t = 1:numT
        % Extract ECEF coordinates at time t for satellite s
        sat_xyz = satPos(:, s, t);  % [3 x 1]
        
        % Convert to geodetic coordinates (lat, lon, alt)
        [lat, lon, ~] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));
        
        subLat(s, t) = lat;
        subLon(s, t) = lon;
        % Generate circle lat/lon (approximate using reckon)
        [latCircle, lonCircle] = scircle1(subLat(s,t), subLon(s,t), beamRadius_deg);
        latCirc{s, t} = latCircle;
        lonCirc{s, t} = lonCircle;
    end
end
% Extract lat/lon from GsLocations
GSlat = cell2mat(GsLocations(:,2));
GSlon = cell2mat(GsLocations(:,3));
geoplot(GSlat, GSlon, 'o','color',co(1,:));hold on
% Plot subpoints of all satellites
geoplot(subLat(:,1), subLon(:,1), 'o','color',co(2,:));hold on
% Overlay beam circles (e.g., θ3dB projection)
% Plot the footprint circle
% geoplot(latCirc{25, 1}, lonCirc{25, 1}, 'm--', 'LineWidth', 0.8, 'HandleVisibility', 'off'); 
for s = 1:5:numLEO
    geoplot(latCirc{s, 1}, lonCirc{s, 1}, '--','color',co(7,:), 'LineWidth', 0.8, 'HandleVisibility', 'off'); hold on;
end
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',12);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
saveLocation = './'
Filename = fullfile(saveLocation, 'Figure4');
print(h_Fig, '-dpng','-r600',Filename)
% print(h_Fig, '-depsc','-r600',Filename)
%% Plot footprint of the satellites
figure;
% Set up map axes with cylindrical projection
ax = axesm('eqdcylin', 'Frame', 'on', 'Grid', 'on', ...
           'MapLatLimit', [-90 90], 'MapLonLimit', [-180 180]);
axis off;  % Hide Cartesian axes
setm(ax, 'MLabelParallel', -90); % Longitude labels at bottom

% Add base map (optional)
geoshow('landareas.shp', 'FaceColor', [0.8 0.8 0.8]);

% Plot GSs
plotm(GSlat, GSlon, 'bo', 'DisplayName', 'Ground Stations');

% Plot satellite subpoints at t = 1
plotm(subLat(:,1), subLon(:,1), 'ro', 'DisplayName', 'LEO Subpoints');

% Beamwidth in degrees
beamRadius_deg = rad2deg(leo.psi);

% Plot coverage circles
for s = 1:numLEO
    [latCircle, lonCircle] = scircle1(subLat(s,1), subLon(s,1), beamRadius_deg);
    plotm(latCircle, lonCircle, 'm--', 'LineWidth', 0.8);
end

% legend('Location', 'bestoutside');
title('Satellite Subpoints and Coverage Footprints (θ)');

%%
% Extract lat/lon from GsLocations
GSlat = cell2mat(GsLocations(:,2));
GSlon = cell2mat(GsLocations(:,3));
for s = 1:numLEO
    for t = 1:length(ts)
        % Extract ECEF coordinates at time t for satellite s
        sat_xyz = satPos(:, s, t);  % [3 x 1]
        
        % Convert to geodetic coordinates (lat, lon, alt)
        [lat, lon, ~] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));
        
        subLat(s, t) = lat;
        subLon(s, t) = lon;
    end
end
% Create plot
figure;
geoplot(GSlat, GSlon, 'bo', 'DisplayName', 'Ground Stations'); hold on
geoplot(subLat(:,1), subLon(:,1), 'ro', 'DisplayName', 'Satellite Subpoints');
%% actual coverage per GS at time
beamMask = (leotheta <= thetaThreshold) & (ElLEO > 0);
% beamMask = leotheta <= thetaThreshold;  % [NumGS × LEO × Time]
tstep = 3;
beamMaskAtT = beamMask(:, :, tstep);  % [NumGS × LEO]
numCoveringSats = sum(beamMaskAtT, 2);  % [NumGS × 1]
figure;bar(numCoveringSats);
xlabel('Ground Station Index');
ylabel(sprintf('# of Satellites Covering at t = %d', tstep));
title('GS Coverage Count');
%%
figure;imagesc(rad2deg(leotheta(:,:,1))); colorbar; title('\theta (deg) at t=1');
figure; imagesc(ElLEO(:,:,1)); colorbar; title('Elevation (deg) at t=1');


