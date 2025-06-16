import gymnasium
import numpy as np
import matlab.engine
from gymnasium.spaces import MultiDiscrete, Dict, Box
import logging
import json
import math
from datetime import datetime, timedelta, timezone

import os 
# Folder name
saved_folder = "saved_data"

# Create the folder if it doesn't exist
if not os.path.exists(saved_folder):
    os.makedirs(saved_folder)
    print(f"Folder '{saved_folder}' created.")
else:
    print(f"Folder '{saved_folder}' already exists.")

env_name = "CogSatEnv-v1"

# Configure the logger
logging.basicConfig(
    filename='train_log.txt',
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    filemode='w'  # Overwrites the file each time
)

 
class CogSatEnv(gymnasium.Env):
    """Gymnasium environment for MATLAB-based Cognitive Satellite Simulation"""
 
    def __init__(self, env_config=None, render_mode=None):
        super(CogSatEnv, self).__init__()
        if not hasattr(self, 'spec') or self.spec is None:
            self.spec = gymnasium.envs.registration.EnvSpec("CogSatEnv-v1")


        self.episode_number = 0
            
 
        # Start MATLAB engine and set path
        self.eng = matlab.engine.start_matlab()
        self.eng.cd(self.eng.pwd(), nargout=0)  # ensure working directory is set

        self.eng.addpath(r'./matlab_code', nargout=0)

        # Initialize the MATLAB scenario
        self.eng.eval("initialiseScenario", nargout=0)
        self.eng.eval("resetScenario", nargout=0)

        self.mat_filename = "DQN"


        self.tIndex = 0
        self.timelength = self.eng.eval("length(ts)", nargout=1)
        self.leoNum = int(self.eng.workspace['leoNum'])
        self.geoNum = int(self.eng.workspace['geoNum'])
        self.NumLeoUser = int(self.eng.workspace['NumLeoUser'])
        self.NumGeoUser = int(self.eng.workspace['NumGeoUser'])
        self.curLEO_User_id = 0
        self.reward = -32.4115512468957

        self.LeoChannels = int(self.eng.workspace['numChannels'])
        self.GeoChannels = int(self.eng.workspace['NumGeoUser'])

        self.ChannelListLeo = self.eng.workspace['ChannelListLeo']
        self.ChannelListGeo = self.eng.workspace['ChannelListGeo']

        self.intial_obs = {
            "utc_time": np.array([0], dtype=np.int64),
            "freq_lgs_leo": np.random.uniform(1.0, self.LeoChannels, size=(self.NumLeoUser,)).astype(np.int64),
            "freq_ggs_geo": np.random.uniform(1.0, self.GeoChannels, size=(self.NumGeoUser,)).astype(np.int64),
            "leo_user_id": np.array([0], dtype=np.int64),
            "leo_pos": np.random.uniform(0, 20, size=(self.NumLeoUser*2,)).astype(np.float32),
        }         
        
 
        # Define action and observation space
        self.action_space = gymnasium.spaces.Discrete(self.LeoChannels)  # Select a channel index for one LEO (for example)


        # Observation space structure
        self.observation_space = Dict({
            "utc_time": Box(low=-np.inf, high=np.inf, shape=(1,), dtype=np.int64),
            "freq_lgs_leo": Box(low=1, high=self.LeoChannels+1, shape=(self.NumLeoUser,), dtype=np.int64),
            "freq_ggs_geo": Box(low=1, high=self.GeoChannels+1, shape=(self.NumGeoUser,), dtype=np.int64),
            "leo_user_id": Box(low=0, high=self.NumLeoUser+1, shape=(1,), dtype=np.int64),
            "leo_pos": Box(low=-np.inf, high=np.inf, shape=(self.NumLeoUser*2,), dtype=np.float32),
        })
    
    def save_npy_data(self,extra_tag="Original"):
        SINR = np.array(self.eng.workspace['SINR'])
        Intf = np.array(self.eng.workspace['Intf'])
        SINR_mW_dict = np.array(self.eng.workspace['SINR_mW_dict'])
        Intf_mW_dict = np.array(self.eng.workspace['Intf_mW_dict'])
        Thrpt = np.array(self.eng.workspace['Thrpt'])

        np.save(f'{saved_folder}/{extra_tag}_SINR.npy', SINR)
        np.save(f'{saved_folder}/{extra_tag}_Intf.npy', Intf)
        np.save(f'{saved_folder}/{extra_tag}_SINR_mW_dict.npy', SINR_mW_dict)
        np.save(f'{saved_folder}/{extra_tag}_Intf_mW_dict.npy', Intf_mW_dict)
        np.save(f'{saved_folder}/{extra_tag}_Thrpt.npy', Thrpt)
    
    
    def get_matlab_ts(self):
        """
        Get the MATLAB timestamp as a list of strings.
        """
        ts_str = self.eng.eval("cellstr(datestr(ts, 'yyyy-mm-ddTHH:MM:SS'))", nargout=1)
        python_datetimes = [datetime.fromisoformat(s) for s in ts_str]
        timestamps = [dt.timestamp() for dt in python_datetimes]
        return timestamps
    

    


    def get_state_from_matlab(self):
        # Log cur_state_from_matlab
        logging.info("=== Current State ===")
        # logging.info(json.dumps(cur_state_from_matlab, indent=2))
        """Reset the environment and initialize the buffer."""

        self.ts = self.get_matlab_ts()

        self.FreqAlloc = np.array(self.eng.workspace['FreqAlloc'])
        self.LEOFreqAlloc = self.FreqAlloc[:10,:]
        self.GEOFreqAlloc = self.FreqAlloc[10:20,:]

        cur_obs = self.intial_obs.copy()

        cur_obs["utc_time"] = np.array([self.ts[self.tIndex]], dtype=np.int64)
        cur_obs["freq_lgs_leo"] = np.array(self.LEOFreqAlloc[:,self.tIndex], dtype=np.int64)
        cur_obs["freq_ggs_geo"] = np.array(self.GEOFreqAlloc[:,self.tIndex], dtype=np.int64)
        cur_obs["leo_user_id"] = np.array([self.curLEO_User_id], dtype=np.int64)
        leo_loc = np.array(self.eng.workspace['LEO_LOC'])
        cur_obs["leo_pos"] = np.array(leo_loc[0:self.NumLeoUser,self.tIndex].flatten(), dtype=np.float32)
        # Log current observation

        # logging.info("self.tIndex: %s",self.tIndex)

        # # Log utc_time
        # logging.info("utc_time: %s", cur_obs["utc_time"].tolist())

        # # Log freq_lgs_leo
        # logging.info("freq_lgs_leo: %s", cur_obs["freq_lgs_leo"].tolist())

        # (Optional) Validate against observation_space
        assert self.observation_space.contains(cur_obs), "cur_obs doesn't match the observation space!"

        return cur_obs
    

 
    def step(self, action):
        """
        Apply action and return (observation, reward, terminated, truncated, info)
        """

        #print("*-"*50)
        #print("Step Started")
        logging.info("=== Step Started ===")
        # Access the variable from MATLAB workspace
        # Convert MATLAB array to NumPy array
        channel_list_leo = np.array(self.eng.workspace['ChannelListLeo'])

        Serv_idxLEO = np.array(self.eng.workspace['Serv_idxLEO'])
        self.cur_leo_sat_id = int(Serv_idxLEO[self.curLEO_User_id, self.tIndex]) - 1

        self.tIndex = int(self.tIndex)
        

        #print("Action taken: ", action)
        logging.info("=== Action Taken === %s", action)

        #print("Current LEO User ID: ", self.curLEO_User_id)
        logging.info("=== Current LEO User ID === %s", self.curLEO_User_id)

        #print("self.tIndex: ", self.tIndex)
        logging.info("=== Current Time Index === %s", self.tIndex)

        #print("Current LEO Satellite ID: ", self.cur_leo_sat_id)
        logging.info("=== Current LEO Satellite ID === %s", self.cur_leo_sat_id)


        # Action start from 0 and ends before self.LeoChannels, that means it is not included
        # For example, if self.LeoChannels is 5, action can be 0, 1, 2, 3, or 4.
        # This is because MATLAB uses 1-based indexing, so we need to convert it to 0-based indexing for Python.
        action = int(action) + 1 # Ensure action is an integer 


        channel_list_leo[self.curLEO_User_id, self.cur_leo_sat_id, self.tIndex] = int(action)
        self.eng.workspace['ChannelListLeo'] = matlab.double(channel_list_leo)

        #print("Updated ChannelListLeo: ", np.array(self.eng.workspace['ChannelListLeo'])[self.curLEO_User_id, self.cur_leo_sat_id, self.tIndex])


        self.eng.eval("stepScenario", nargout=0)
        next_observation = self.get_state_from_matlab()     
        
        #print("Next Observation: ", next_observation)
        logging.info("=== Next Observation === %s", next_observation)   
         
        terminated = False
        truncated = False

        SINR = np.array(self.eng.workspace['SINR_mW_dict'])
        Intf = np.array(self.eng.workspace['Intf_mW_dict'])
        Thrpt = np.array(self.eng.workspace['Thrpt'])


        

        # Compute reward: sum of SINR across all users at current time step
        Interference_to_geo_users = Intf[self.NumLeoUser:self.NumGeoUser+ self.NumLeoUser, self.tIndex]
        SINR_of_LEO_users = SINR[:self.NumLeoUser, self.tIndex]
        Thrpt_of_LEO_users = Thrpt[:self.NumLeoUser, self.tIndex]

        #print('Intf: ', Interference_to_geo_users*1e8)
        #print('SINR: ', SINR_of_LEO_users)
        #print('Thrpt: ', Thrpt_of_LEO_users)
        logging.info("=== Interference === %s", Interference_to_geo_users*1e8)
        logging.info("=== SINR === %s", SINR_of_LEO_users)
        logging.info("=== Throughput === %s", Thrpt_of_LEO_users)

        # # Option 1
        # reward = np.sum(SINR_of_LEO_users)
        
        # # Option 2
        # reward = np.sum(np.log10(SINR_of_LEO_users))

        # Option 3
        reward = np.sum(Thrpt_of_LEO_users)

        # # Option 4
        # reward = np.sum(np.log10(Thrpt_of_LEO_users))

        self.reward = reward
        #print("Reward: ", reward)
        logging.info("=== Reward === %s", reward)

        self.curLEO_User_id += 1

        if self.curLEO_User_id >= self.NumLeoUser:
            self.curLEO_User_id = 0
            self.tIndex += 1
            if self.tIndex >= self.timelength:
                terminated = True
                #print("Episode finished after {} timesteps".format(self.tIndex))
                logging.info("=== Episode finished after %s timesteps ===", self.tIndex)
                self.save_npy_data(f'Episode_{self.episode_number}')
                filename = f"{saved_folder}/{self.mat_filename}_workspace_Saved_data_Close.mat"
                save_cmd = f"save('{filename}')"
                self.eng.eval(save_cmd, nargout=0)
                self.eng.eval("P08_SaveData", nargout=0)


        info = {}

        #print("*-"*50)

 
        return next_observation, reward, terminated, truncated, info
 
    def reset(self, *, seed=None, options=None):
        self.episode_number = self.episode_number + 1
        #print("Resetting environment for episode: ", self.episode_number)
        logging.info("=== Resetting Environment for Episode %s ===", self.episode_number)
        super().reset(seed=seed) 
        # Reset the scenario
        self.eng.eval("resetScenario", nargout=0)

        self.ChannelListLeo = self.eng.workspace['ChannelListLeo']
        self.ChannelListGeo = self.eng.workspace['ChannelListGeo']

        self.tIndex = 0
        self.done = 0
        self.curLEO_User_id = 0

        observation = self.get_state_from_matlab()
        #print("++++===== ENV RESET+++===")
 
        return observation, {}
 
    def render(self):
        #print("Rendering is handled in MATLAB viewer.")
        pass
 
    def close(self):
        #print("Saving MATLAB Data.")
        logging.info("=== Saving MATLAB Data ===")
        # self.eng.eval("P08_SaveData", nargout=0)
        filename = f"{saved_folder}/{self.mat_filename}_workspace_Saved_data_Close.mat"
        save_cmd = f"save('{filename}')"
        self.eng.eval(save_cmd, nargout=0)
        self.eng.quit()