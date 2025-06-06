%% Satellite Simulation: GEO + LEO over Australia
clear; clc;
fprintf('=== Starting Satellite Simulation ===\n');


maps = exist('maps.mat','file');
p836 = exist('p836.mat','file');
p837 = exist('p837.mat','file');
p840 = exist('p840.mat','file');
matFiles = [maps p836 p837 p840];
if ~all(matFiles)
    if ~exist('ITURDigitalMaps.tar.gz','file')
        url = 'https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz';
        websave('ITURDigitalMaps.tar.gz',url);
        untar('ITURDigitalMaps.tar.gz');
    else
        untar('ITURDigitalMaps.tar.gz');
    end
    addpath(cd);
end

%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');
startTime = datetime(2025,4,10,12,0,0);
duration_sec = 60 * 30;     % simulation duration in seconds
sampleTime = 10;            % second sampling time
stopTime = startTime + seconds(duration_sec);

% Frequencies (GHz)
baseFreq = 1.5e9;      % GEO frequency
channelBW = 200e3;     % Channel bandwidth
channelFreqs = 1e9 * [1.498875, 1.500125, 1.500375, 1.500625, 1.500875, ...
                      1.501125, 1.501375, 1.501625, 1.501875, 1.502125]; % 10 channels

% Power (dBW)
geoPower = 10*log10(300); % 300 W in dBW
leoPower = 10*log10(20);  % 20 W in dBW

% Antennas (m)
leoAntenna = 0.5;      % LEO antenna diameter
geoAntenna = 3;        % GEO antenna diameter
gsAntenna = 2.4;       % Ground station antenna diameter

% Constants
earthRadius = 6371;     % km
kb = physconst('Boltzmann');
tempK = 293;           % Noise temperature
%rainLoss = 2.0;        % dB
%cloudLoss = 1.5;       % dB

%% Create Scenario
fprintf('Creating satellite scenario...\n');
sc = satelliteScenario(startTime, stopTime, sampleTime);


%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');
cities = {
    'Melbourne', -37.8136, 144.9631;
    'Sydney',    -33.8688, 151.2093;
    %'Perth',     -31.9505, 115.8605;
    %'Brisbane',  -27.4698, 153.0251;
    %'Adelaide',  -34.9285, 138.6007;
    %'Darwin',    -12.4634, 130.8456;
};

cities_py = {
    {'Melbourne', -37.8136, 144.9631}, 
    {'Sydney',    -33.8688, 151.2093},
    % {'Perth',     -31.9505, 115.8605},
    % {'Brisbane',  -27.4698, 153.0251},
    % {'Adelaide',  -34.9285, 138.6007},
    % {'Darwin',    -12.4634, 130.8456},
};


gsList = [];
for i = 1:size(cities,1)
    fprintf('  Creating ground station: %s\n', cities{i,1});
    gsList{i} = groundStation(sc, cities{i,2}, cities{i,3}, 'Name', cities{i,1});
end

%% Create GEO Satellites
fprintf('Creating GEO satellites...\n');
geoNum = 1; 
geoSats = [];
geoLongitudes = [160]; % Centered over Australia
sma_geo = (35786 + earthRadius) * 1e3; % GEO altitude


geoTx = cell(1, geoNum);
geoTxGimbals = cell(1, geoNum);

for i = 1:geoNum
    fprintf('  Creating GEO satellite %d at %d°E longitude\n', i, geoLongitudes(i));
    geoSats{i} = satellite(sc, sma_geo, 0, 0, 0, 0, geoLongitudes(i), ...
        'Name', sprintf('GEO-%d', i), 'OrbitPropagator', 'two-body-keplerian');
    
    % Add gimbal for pointing at ground stations
    geoTxGimbals{i} = gimbal(geoSats{i});
    
    % Create transmitter mounted on gimbal
    tx = transmitter(geoTxGimbals{i}, 'Frequency', baseFreq, 'Power', geoPower, 'SystemLoss', 1.0);
    gaussianAntenna(tx, 'DishDiameter', geoAntenna);
    geoTx{i} = tx;

    % Point gimbal at all GS (for now, point at center or 1st GS)
    pointAt(geoTxGimbals{i}, gsList{i});
end


%% Create LEO Satellites
fprintf('Creating LEO satellites...\n');
leoNum = 3;
leoInclination = 90;  % Inclination for coverage
%leoRAANs = [170, 180, 190];
leoRAANs = [150, 160, 170];
leoSats = [];
sma_leo = (650 + earthRadius) * 1e3; % Average LEO altitude
leoTx = [];

for i = 1:leoNum
    fprintf('  Creating LEO satellite %d with RAAN %d°\n', i, leoRAANs(i));
    leoSats{i} = satellite(sc, sma_leo, 0, leoInclination, leoRAANs(i), 0, -65, ...
        'Name', sprintf('LEO-%d', i), 'OrbitPropagator', 'two-body-keplerian');

    tx = transmitter(leoSats{i}, 'Frequency', channelFreqs(1), 'Power', leoPower);
    gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    leoTx{i} = tx;
    
end

%% Receivers on Ground Stations
fprintf('Setting up ground station receivers...\n');
fprintf('Setting up dual receivers and gimbals for each ground station...\n');

rxGimbals_GEO = containers.Map();
rxGimbals_LEO = containers.Map();
rxReceivers_GEO = containers.Map();
rxReceivers_LEO = containers.Map();

for i = 1:numel(gsList)
    gs = gsList{i};
    gsName = gs.Name;

    % --- Gimbal and receiver for GEO ---
    geoGimbal = gimbal(gs);
    geoRx = receiver(geoGimbal, ...
        'GainToNoiseTemperatureRatio', 30, ...
        'RequiredEbNo', 10, ...
        'SystemLoss', 1.0);
    gaussianAntenna(geoRx, ...
        'DishDiameter', gsAntenna);

    % Point to first GEO for now (dynamic update happens in sim loop)
    pointAt(geoGimbal, geoSats{1});

    % Store
    rxGimbals_GEO(gsName) = geoGimbal;
    rxReceivers_GEO(gsName) = geoRx;

    % --- Gimbal and receiver for LEO ---
    leoGimbal = gimbal(gs);
    leoRx = receiver(leoGimbal, ...
        'GainToNoiseTemperatureRatio', 30, ...
        'RequiredEbNo', 10, ...
        'SystemLoss', 1.0);
    gaussianAntenna(leoRx, ...
        'DishDiameter', gsAntenna);

    % Point to first LEO initially
    pointAt(leoGimbal, leoSats{1});

    % Store
    rxGimbals_LEO(gsName) = leoGimbal;
    rxReceivers_LEO(gsName) = leoRx;
end


%% Initialize data collection
fprintf('Initializing data collection...\n');
ts = startTime:seconds(sampleTime):stopTime;
validSamples = 0;

fprintf('Starting first pass to count valid samples...\n');
% First pass to count valid samples (where at least one LEO has access)
for tIdx = 1:length(ts)
    t = ts(tIdx);
    leoAccess = false;
    
    % Check if any LEO has access to any ground station
    for i = 1:leoNum
        for gsIdx = 1:numel(gsList)
            if accessStatus(access(leoSats{i}, gsList{gsIdx}), t)
                leoAccess = true;
                fprintf('  Found LEO access at %s (LEO-%d to %s)\n', datestr(t), i, gsList{gsIdx}.Name);
                break;
            end
        end
        if leoAccess, break; end
    end
    
    if leoAccess
        validSamples = validSamples + 1;
    end

    geoAccess = false;

    % Check if any GEO has access to any ground station
    for i = 1:geoNum
        for gsIdx = 1:numel(gsList)
            if accessStatus(access(geoSats{i}, gsList{gsIdx}), t)
                geoAccess = true;
                fprintf('  Found GEO access at %s (GEO-%d to %s)\n', datestr(t), i, gsList{gsIdx}.Name);
                break;
            end
        end
        if geoAccess, break; end
    end

    if geoAccess
        validSamples = validSamples + 1;
    end

end
fprintf('First pass complete. Found %d valid samples with LEO access.\n', validSamples);


% Pre-allocate based on valid samples
fprintf('Pre-allocating data structures...\n');
logData = struct();
logData.Time = NaT(validSamples, 1);
logData.GEO = struct();
logData.LEO = struct();

% Initialize GEO data
for i = 1:geoNum
    logData.GEO(i).Name = geoSats{i}.Name;
    logData.GEO(i).Latitude = zeros(validSamples, 1);
    logData.GEO(i).Longitude = zeros(validSamples, 1);
    logData.GEO(i).Frequency = baseFreq * ones(validSamples, 1);
    logData.GEO(i).Access = zeros(validSamples, numel(gsList));
    logData.GEO(i).SNR = NaN(validSamples, numel(gsList));
    logData.GEO(i).RSSI = NaN(validSamples, numel(gsList));
end

% Initialize LEO data
for i = 1:leoNum
    logData.LEO(i).Name = leoSats{i}.Name;
    logData.LEO(i).Latitude = zeros(validSamples, 1);
    logData.LEO(i).Longitude = zeros(validSamples, 1);
    logData.LEO(i).Frequency = zeros(validSamples, 1);
    logData.LEO(i).Access = zeros(validSamples, numel(gsList));
    logData.LEO(i).SNR = NaN(validSamples, numel(gsList));
    logData.LEO(i).RSSI = NaN(validSamples, numel(gsList));
end


function overlapFactor = getOverlapFactor(txFreq, txBW, intfFreq, intfBW)
    txRange = [txFreq - txBW/2, txFreq + txBW/2];
    intfRange = [intfFreq - intfBW/2, intfFreq + intfBW/2];
    overlap = max(0, min(txRange(2), intfRange(2)) - max(txRange(1), intfRange(1)));
    overlapFactor = overlap / intfBW;
end

sampleCount = 0;

%% Get State Data from time t=1

tIdx = 1
t = ts(tIdx);

leoAccess = false;
geoAccess = false;
accessDetails = '';

% First check if any LEO has access to any ground station
for i = 1:leoNum
    for gsIdx = 1:numel(gsList)
        if accessStatus(access(leoSats{i}, gsList{gsIdx}), t)
            leoAccess = true;
            accessDetails = sprintf('LEO-%d to %s', i, gsList{gsIdx}.Name);
            fprintf('  Access detected: %s\n', accessDetails);
            break;
        end
    end
    if leoAccess, break; end
end


% Check if any GEO has access to any ground station
for i = 1:geoNum
    for gsIdx = 1:numel(gsList)
        if accessStatus(access(geoSats{i}, gsList{gsIdx}), t)
            geoAccess = true;
            fprintf('  Found GEO access at %s (GEO-%d to %s)\n', datestr(t), i, gsList{gsIdx}.Name);
            break;
        end
    end
    if geoAccess, break; end
end

% Only process if at least one LEO has access (GEOs can be added later)
if leoAccess | geoAccess
    sampleCount = sampleCount + 1;
    logData.Time(sampleCount) = t;
    fprintf('  Processing sample %d (valid sample %d)\n', tIdx, sampleCount);
    
    % Update LEO frequencies (random channel selection)
    currentLEOFreqs = channelFreqs(randi([1 10], 1, leoNum));
    fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));



    fprintf(' Sending inital state to py function ...\n');


    % Initialize a struct to store the LEO satellite data
    snd_state = struct;

    % Add base frequency or frequency of GEO to the state
    snd_state.GeobaseFreq = baseFreq;
    snd_state.time = datestr(t)

    for i = 1:leoNum
        % Get position in geographic coordinates (Latitude, Longitude)
        [pos, ~] = states(leoSats{i}, t, 'CoordinateFrame', 'geographic');
        
        % Initialize a struct to hold the satellite data for this LEO
        satellite_data = struct;
        satellite_data.LEO_Num = i;
        satellite_data.Latitude = pos(1);
        satellite_data.Longitude = pos(2);
        
        % Create a struct for access status
        accessStatusStruct = struct;
        
        % For each ground station, check if the satellite has access
        for gsIdx = 1:numel(gsList)
            gsName = strrep(gsList{gsIdx}.Name, ' ', '_');
            accObj = access(leoSats{i}, gsList{gsIdx});
            accessStatusStruct.(gsName) = accessStatus(accObj, t);
        end
        
        % Add AccessStatus to the satellite data
        satellite_data.AccessStatus = accessStatusStruct;
        
        % Store the satellite data
        fieldName = sprintf("LEO_%d", i);
        snd_state.(fieldName) = satellite_data;
    end

end

% Update LEO frequencies (random channel selection)
currentLEOFreqs = channelFreqs(randi([1 10], 1, leoNum));
done = false;

leoIndex = 0;

fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));