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
%% Get Satellite Positions in ECEF or ECI
satPos = states(leoSats, 'CoordinateFrame', 'ecef');
% satPos = states(leoSats, 'CoordinateFrame', 'inertial');
satPos = permute(satPos, [1 3 2]);
%% Get Off-axis angle θ and Azimuth between beam and user (from satellite prespective
leotheta = zeros(NumGS, leoNum, length(ts));
leoAzimuth = zeros(NumGS, leoNum, length(ts));
for t = 1:length(ts)
    for s = 1:leoNum
        sat_xyz = satPos(:, s, t);         % [3×1] ECEF of satellite
        boresight = -sat_xyz;              % Beam points toward Earth center- off-Nadir angle
        % Compute satellite geodetic position (subpoint) at current timestep
        [latSat, lonSat, hSat] = ecef2geodetic(E, sat_xyz(1), sat_xyz(2), sat_xyz(3));
        
        for g = 1:NumGS
            gs_xyz = GSECEF(g, :)';        % [3×1] ECEF of ground station
            vec_user = gs_xyz - sat_xyz;   % Vector from sat to ground station
            % Off-axis angle θ between beam and user
            leotheta(g, s, t) = acos(dot(boresight, vec_user) / ...
                                 (norm(boresight) * norm(vec_user))); % Angle from satellite to GS w.r.t. nadir
            
            % For sinc pattern antenna, azimuth angle is required in addition to thetaa
            % Compute NED coordinates of the ground station relative to satellite
            [xNorth, yEast, zDown] = ecef2ned(gs_xyz(1), gs_xyz(2), gs_xyz(3), ...
                                              latSat, lonSat, hSat, E, 'radians');
            
            % Convert NED to Azimuth, Depression, Range
            [Az, ~, ~] = ned2aer(xNorth, yEast, -zDown, 'radians');  % Note the negative zDown
            leoAzimuth(g, s, t) = Az;
        end
    end
end

