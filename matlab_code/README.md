# CogSat-Frequency-Reuse

## Overview

This MATLAB-based simulation framework models a satellite communication scenario involving Low Earth Orbit (LEO) and Geostationary Earth Orbit (GEO) satellites communicating with ground stations across Australia. The primary objective is to generate a labeled dataset of Signal-to-Interference-plus-Noise Ratio (SINR) values under random frequency allocation, to be later used for supervised learning of interference-aware frequency planning.

## Key Features
LEO constellation (OneWeb-like) with Walker-Star orbital configuration

Single or multiple GEO satellites positioned at specified longitudes

20 ground stations across various Australian cities

Dynamic elevation and slant range computation using MATLAB's satelliteScenario

ITU-R based atmospheric loss modeling (P.676, P.840, P.838)

Rician multipath fading simulation based on elevation angle

Random channel allocation at each timestep

Serving satellite selection and SNR/SINR computation

## Simulation Flow

1. Initialization (P01_Parameters, P02_GStations)

Defines constants: speed of light, system temperature, bandwidth, transmit power.

Creates ground stations in 20 Australian locations.

Sets simulation time: 30 minutes with 60-second time steps.

2. Scenario Construction (P03_GeometricSimulatoion)

Creates a 588-satellite LEO constellation using Walker-Star method.

Creates GEO satellites at fixed longitudes.

Computes elevation angles and slant ranges between satellites and ground stations.

3. Receive Power Calculation (P04_RxSimulation)

Computes antenna gains for both LEO and GEO.

Applies path loss, atmospheric attenuation, and multipath fading.

Calculates received power Prx, and then SNR using thermal noise.

4. Random Frequency Allocation

Each time step: allocate channels randomly to all LEO and GEO links.

Ensures GEO channels are exclusive per user.

5. Serving Satellite Assignment

For each ground station, selects the best (strongest) satellite.

Stores indices and SNR for further interference calculations.

6. Channel allocation and finding seving satellite (P05_Interference)

Random allocation for the channels ensuring GEO has fixed channels per the number of users. Then all channels are shared between LEO.

Finding the serving station based on the maximum recevied power and ensure to avoid the signal from outside the local horizon of the GS based on the elevation angle.

7. Interference Calculation (P06_Interference)

Computes SINR using knowledge of channel reuse and neighboring interference.

Captures data for learning-based scheduling.
