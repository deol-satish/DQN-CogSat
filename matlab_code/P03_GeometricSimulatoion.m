%% P03_GeometricSimulatoion
%% Create the LEO constellation using walkerStar
fprintf('Creating LEO Walker-Star constellation...\n');
leoSats = walkerStar(sc, ...
    walker.a, ...
    walker.Inc, ...
    walker.SatsPerPlane * walker.NPlanes, ...
    walker.NPlanes, ...
    walker.PhaseOffset, ...
    'Name', " ", ...
    'OrbitPropagator', 'two-body-keplerian');
%% Create the GEO satellite
% Optional: Find refernce lla at the start time to use refernce longitude on the generation
% RefPosition = eci2lla([earthRadius,0,0],datevec(startTime));
% lonRef = RefPosition(2);
% geo.RAAN = -lonRef + geoLong;    % RAAN based on Reference lon otherwise
for i = 1:geoNum
    fprintf('  Creating GEO satellite %d at %d°E longitude\n', i, geoLong(i));
    geoSats{i} = satellite(sc, geo.a, geo.e, geo.Inc, geo.omega, geo.mu, geoLong(i), ...
        'Name', sprintf('GEO-%d', i), 'OrbitPropagator', 'two-body-keplerian');
    geoSats{i}.MarkerColor = [0.9290 0.6940 0.1250];  % Orange
end
%% Create ground stations
fprintf('Setting up ground stations in Australia...\n');
for i = 1:size(GsLocations,1)
    GS{i} = groundStation(sc, GsLocations{i,2}, GsLocations{i,3}, 'Name', GsLocations{i,1});
end
%% Find elevatin and range for LEO
for i= 1:length(GS)
    [~,ElLEO(i,:,:), RhoLEO(i,:,:)] = aer(GS{i},leoSats);
    % disp (i)
end
%% Find elevatin and range for GEO
for i= 1:length(GS)
    [~,ElGEO(i,:,:), RhoGEO(i,:,:)] = aer(GS{i},geoSats{1});
    % disp (i)
end
