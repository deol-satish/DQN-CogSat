%% P01_Parameters
%% Physical Constants
E = wgs84Ellipsoid('meters');     % Reference ellipsoid (WGS-84)
c = physconst('LightSpeed');
kb = physconst('Boltzmann');      % Boltzmann constant [J/K]
TempK = 293;                      % System noise temperature [K]
%% General Simulation Parameters
fprintf('Initializing simulation parameters and GS locations...\n');
startTime = datetime(2025, 4, 10, 12, 0, 0);  % Simulation start
duration_sec = 1 * 3600;                   % 30 min simulation in seconds
sampleTime = 30;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);
ts = startTime:seconds(sampleTime):stopTime;
%% Frequencies (Hz)
fc = 11.5e9;                       % Base frequency in Ku-band (10.7-12.7 GHz)
numChannels = 15;                  % Number of available channels
ChannelBW = 250e6;                 % Channel bandwidth of 250 MHz
Rb = 150e6;                        % Bit rate (bps)
%% LEO Walker-Star Constellation Parameters
walker.a = 1200e3 + earthRadius;   % Semi-major axis
walker.alfa = earthRadius / walker.a;
walker.Inc = 87;                   % Inclination in degrees (typical for OneWeb)
walker.NPlanes = 12;               % Number of orbital planes 
walker.SatsPerPlane = 49;          % Number of satellites per plane 
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;
%% GEO Satellite Parameters
geoNum = 1;                        % Number of GEO satellites (adjust as needed)
geoLong = [150, 160, 170];         % GEO longitudes [deg E]
geo.a = 35786e3 + earthRadius;     % Semi-major axis
geo.e = 0;                         % Eccentrivcity for circular orbit
geo.Inc = 0;                       % Inclination in degrees for Equatorial plane
geo.omega = 0;                     % Argument of periapsis
geo.mu = 0;                        % True anamoly
%% Transmit Power (in dBW)
geoPower = 10 * log10(300e3);    % GEO Tx power: 300 W → ~24.77 dBW
leoPower = 10 * log10(5e3);      % LEO Tx power: 5 W → ~36.98 dBm
%% Antenna Parameters (Dish Diameter in meters)
leo.Antenna = 0.6;              % LEO satellite antenna diameter
leo.psi = deg2rad(15);           % LEO satellite beamwidth in radian (θ3dB=2∘,5∘,10∘)
% If θ3dB=10∘, the footprint radius on Earth is only about: r≈h⋅tan⁡(θ3dB)=1200 km⋅tan⁡(10∘)≈212 km
leo.GainMax = 40;               % Max gain in dB assume parabolic antenna 30–45 dB
leo.AntShape = 0.15;             % Antenna shaping parameter (adjusts mainlobe width) - larger a => narrow beam
leo.AntRipfreq = log(0.5) / log(cos(leo.psi));             % Antenna sidelobe ripples in azimuth - controls ripple frequency
leo.AntRipDepth = 0.6;          % Antenna sidelobe ripples in azimuth - controls ripple depth
geoAntenna = 3.0;               % GEO satellite antenna diameter
gsAntenna = 0.6;                % Ground station antenna diameter
eff = 0.5;                      % Antenna efficiency
%% Atmospheric Loss Parameters
Att.H = 2.0;            % Effective atmosphere thickness [km] (ITU‐R's rule of thumb)
Att.M = 0.25;           % liquid‐water density [g/m³]
Att.k_l = 0.08;         % From ITU-R P.840 tables k_l(11.5 GHz) ≈ 0.08 [dB/km/(g/m³)]
Att.Hcloud = 1.0;       % Cloud layer thickness H_cloud [km] e.g. 1 km of liquid water layer
Att.R = 5;              % Choose rain rate R [mm/h], moderate rain
Att.k_r   = 0.075;      % approx. from tables
Att.alpha = 1.16;       % approx. from tables
% Rain‐height above sea level:
Att.h_R = 5.0;  % [km], typical tropical/temperate storm height  
Att.h_s = 0.0;  % [km], ground‐station altitude (sea level = 0)
%% Multi-path Fading Parameters
FadingModel = 'Rician';    % Options: 'None', 'Rayleigh', 'Rician'
% RicianKdB = 10;           % Rician K-factor in dB (K=10: strong LoS)
