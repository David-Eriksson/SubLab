The script SubLab_Start.m starts multiple instances of Matlab or Octave to speed up processing. In this way the SubLab_Start.m processes the following scripts:

SpikesLIFSimulation_distr.m % Simulate spiking and ground truth data

ReconstructionTraining_distr.m % Training reconstruction algorithm to optimize parameters.

ReconstructionComplete_distr.m % Reconstructing the entire data set based on the cross-validated training parameters.

myRate_distr.m % Calculate the my-Rate in order to estimate the reliability of the reconstruction (see manuscript reference).

Associated to those respective scripts there are 4 output folders (under the user selected main data path):

Spikes

ReconstructionTraining

ReconstructionComplete

myRate

In each of those folders there are the TODO, DONE, Running folder, and a folder for each session. Each script looks in the respective TODO folder for which sessions that has to be done. 

For the 
