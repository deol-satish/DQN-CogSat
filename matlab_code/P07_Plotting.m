%% Visualization
%% Beam Footprint Circle on Ground
co = colororder;
Scale = 1;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
% Choose satellite and time index
satIdx = 583;               % LEO satellite index
tIdx = 2;                % Time index
thetaEdge = deg2rad(2); % Beam edge angle (can use theta3dB or gain threshold)
% Satellite position and subpoint
sat_xyz = satPos(:, satIdx, tIdx);
[latSat, lonSat, hSat] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));
% Compute footprint radius on Earth's surface
Re = E.SemimajorAxis;    % Earth's radius
r_foot = Re * asin((Re / (Re + hSat)) * sin(thetaEdge));  % Great-circle approximation [m]
r_foot_deg = rad2deg(r_foot / Re);                        % Convert to degrees
% Create footprint circle
angles = linspace(0, 2*pi, 360);
latCircle = latSat + r_foot_deg * cos(angles);
lonCircle = lonSat + r_foot_deg * sin(angles) ./ cosd(latSat);
% Plot
geoscatter(cell2mat(GsLocations(:,2)), cell2mat(GsLocations(:,3)), 30, 'k', 'filled'); hold on
geoscatter(latSat, lonSat, 100, 'r', 'filled');  % Satellite subpoint
geoplot(latCircle, lonCircle, 'b-', 'LineWidth', 2);
title(sprintf('LEO-%d Beam Footprint at t = %d', satIdx, tIdx));
legend('Ground Stations', 'Satellite Subpoint', 'θ_{edge} Footprint');
geobasemap streets
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',12);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
saveLocation = './'
Filename = fullfile(saveLocation, 'Figure4');
% print(h_Fig, '-dpng','-r600',Filename)
%%  Footprint Mapping
% Threshold based on max gain (e.g., within 3 dB beam)
GainThreshold = leo.GainMax - 3;  % or -10 for edge of coverage
InBeamMask = GtxLEO >= GainThreshold;  % [NumGS × leoNum × T]
% For time t, satellite s
s = 558; t =1;
inbeam_idx = find(InBeamMask(:, s, t));
lat_inbeam = cell2mat(GsLocations(inbeam_idx, 2));
lon_inbeam = cell2mat(GsLocations(inbeam_idx, 3));
figure;
geoscatter(lat_inbeam, lon_inbeam, 100, 'g', 'filled');
geobasemap streets;
hold on;
% Add all GS for context
lat_all = cell2mat(GsLocations(:, 2));
lon_all = cell2mat(GsLocations(:, 3));
geoscatter(lat_all, lon_all, 30, 'k');
% Add satellite subpoint for reference
sat_xyz = satPos(:, s, t);
[latSat, lonSat, ~] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));
geoscatter(latSat, lonSat, 100, 'r', 'filled');
title(sprintf('Footprint of LEO-%d at Time Index %d', s, t));
legend('In-beam GS', 'All GS', 'Satellite Subpoint');
%% Plot received power from a sample LEO satellite
figure;
imagesc(squeeze(PrxLEO(:,1,:)))  % GroundStations × Time
colorbar;
xlabel('Time Index'); ylabel('Ground Station Index');
title('PrxLEO for LEO Sat #1');
%% SINR Distribution Across All Users and Time Steps
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
histogram(SINR(:), 'BinWidth', 0.5, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'k');
xlabel('SINR [dB]');
ylabel('Frequency');
title('SINR Distribution Across All Users and Time Steps');
grid on;
xlim([min(SINR(:))-1, max(SINR(:))+1]);
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',12);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
% saveLocation = 'C:\Users\nermi\iCloudDrive\0. Work\27. SmartSAT Project\FinalShared\Figures';
% Filename = fullfile(saveLocation, 'Figure1');
% print(h_Fig, '-dpng','-r600',Filename)
%% Compute average SINR per user
SINR(isnan(SINR)) = 0;
meanSINR = mean(SINR, 2, 'omitnan');
co = colororder;
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
plot(1:NumGS, meanSINR,'k-o','LineWidth',1);
xlabel('User Index');
ylabel('Mean SINR [dB]');
title('Average SINR per User');
grid on;
% ylim([0 25]);
xline(NumGeoUser + 0.5, '--k', 'LineWidth', 1.2); 
text(NumGeoUser/2, max(meanSINR)-0.2, 'LEO Users', 'HorizontalAlignment', 'center');
text(NumGeoUser + NumLeoUser/2, max(meanSINR)-0.2, 'GEO Users', 'HorizontalAlignment', 'center');
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',10);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
% saveLocation = './'
% Filename = fullfile(saveLocation, 'Figure2');
% print(h_Fig, '-dpng','-r600',Filename)
%% Compute average SINR per user (Random Allocation + Beamwidth Comparison)
load("SINRRA.mat");  % Random Allocation (no beam constraint)
load("SINRBW2.mat"); load("SINRBW5.mat");
load("SINRBW8.mat"); load("SINRBW10.mat");load("SINRBW15.mat");
SINR_all = {SINRRA, SINRBW2, SINRBW5, SINRBW8, SINRBW10, SINRBW15};
labels = {'No Constraint', 'BW 2°', 'BW 5°', 'BW 8°', 'BW 10°', 'BW 15°'};
markerList = {'-o','-s','-^','-d','-+'};
co = colororder;
numConfigs = numel(SINR_all);
% Compute mean SINR for each configuration
meanSINR = zeros(NumGS, numConfigs);
for i = 1:numConfigs
    meanSINR(:, i) = mean(SINR_all{i}, 2, 'omitnan');
end
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],...
    'Position',[200 300 800 800/1.618*Scale]);
hold on;
for i = 1:numConfigs
    % plot(1:NumGS, meanSINR(:, i), markerList{i}, ...
    %     'Color', co(i,:), 'LineWidth', 1.5);
    plot(1:NumGS, meanSINR(:, i), 'Color', co(i,:), 'LineWidth', 1.5);
end
hold off;
xlabel('User Index');
ylabel('Mean SINR [dB]');
% title('Average SINR per User under Different Beamwidth Constraints');
xline(NumGeoUser + 0.5, '--k', 'LineWidth', 1.2);
maxY = max(meanSINR(:)) +2;
text(NumGeoUser/2+2, maxY, 'LEO Users', 'HorizontalAlignment', 'center', 'FontSize', 12);
text(NumGeoUser + NumLeoUser/2, maxY, 'GEO Users', 'HorizontalAlignment', 'center', 'FontSize', 12);
legend(labels, 'Location', 'southeast');
ax = gca;
ax.Box = 'on';
set(ax, 'LooseInset', get(ax, 'TightInset'), 'FontSize', 14);
ax.LineWidth = 1;
grid on;
saveLocation = './'
% Filename = fullfile(saveLocation, 'Figure11');
exportgraphics(h_Fig, fullfile(saveLocation, 'Figure11.png'), 'Resolution', 600)
%% Plot Random allocation vs optimised allocation
load("SINRRA.mat");  % Random Allocation (no beam constraint)
load("SINROP.mat");  % Optimized Allocation
SINR_all = {SINRRA, SINROP};
labels = {'Random Allocation', 'Optimized Allocation'};
markerList = {'-o','-s'};
co = colororder;
numConfigs = numel(SINR_all);
% Compute mean SINR for each configuration
meanSINR = zeros(NumGS, numConfigs);
for i = 1:numConfigs
    meanSINR(:, i) = mean(SINR_all{i}, 2, 'omitnan');
end
Scale = 0.7;
h_Fig = figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],...
    'Position',[200 300 800 800/1.618*Scale]);
hold on;
for i = 1:numConfigs
    plot(1:NumGS, meanSINR(:, i), markerList{i}, 'Color', co(i,:), 'LineWidth', 1.5);
end
xlabel('User Index');
ylabel('Mean SINR [dB]');
xline(NumGeoUser + 0.5, '--k', 'LineWidth', 1.2);
maxY = max(meanSINR(:)) - 5;
text(NumGeoUser / 2 + 2, maxY, 'LEO Users', 'HorizontalAlignment', 'center', 'FontSize', 12);
text(NumGeoUser + NumLeoUser / 2, maxY, 'GEO Users', 'HorizontalAlignment', 'center', 'FontSize', 12);
legend(labels, 'Location', 'southeast');
ax = gca;
ax.Box = 'on';
set(ax, 'LooseInset', get(ax, 'TightInset'), 'FontSize', 14);
ax.LineWidth = 1;
grid on;
saveLocation = './'
% Filename = fullfile(saveLocation, 'Figure11');
exportgraphics(h_Fig, fullfile(saveLocation, 'Figure10.png'), 'Resolution', 600)

%%  Per-Satellite/User SINR Timeline Plot
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
tiledlayout(2,1, 'TileSpacing','compact', 'Padding','compact');
nexttile;
hold on;
for i = 1:length(LEOUsers)
    u = LEOUsers(i);
    plot(ts, SINR(u,:), '-o', 'LineWidth', 1.2, 'DisplayName', sprintf('LEO-%d', u));
end
title('SINR Over Time - LEO Users');
ylabel('SINR [dB]');
grid on;
legend('Location','eastoutside');
xtickformat('HH:mm');
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',10);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
% === GEO Users Plot ===
nexttile;
hold on;
for i = 1:length(GEOUsers)
    u = GEOUsers(i);
    plot(ts, SINR(u,:), '-s', 'LineWidth', 1.2, 'DisplayName', sprintf('GEO-%d', u));
end
title('SINR Over Time - GEO Users');
xlabel('Time');
ylabel('SINR [dB]');
grid on;
legend('Location','eastoutside');
xtickformat('HH:mm');
ax=gca;
grid on;ax.Box = 'on';set(gca,'LooseInset',get(gca,'TightInset'),'FontSize',10);
ax.LineWidth = 1;  % Set box (axis) thickness to 1.5 points
% saveLocation = 'C:\Users\nermi\iCloudDrive\0. Work\27. SmartSAT Project\FinalShared\Figures';
% Filename = fullfile(saveLocation, 'Figure3');
% print(h_Fig, '-dpng','-r600',Filename)
%% Heatmap of SINR Over Time
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
imagesc(SINR);
colorbar;
xlabel('Time Step');
ylabel('User Index');
title('SINR Heatmap (Users vs Time)');
colormap('jet');