# SubLab
Subthreshold reconstruction Laboratory

SubLab uses large scale spiking activity to reconstruct subthreshold activity for individual units. The input spike file is a binary file consisting of pairs of 'doubles': Spike identity (unit number) and spike time (seconds).

???? Bioarxiv ?????



**To run SubLab**

Install Matlab or Octave.

Download code directory.

Data directory: contains a spike file and an ground truth intra-cellular recording (not necessary for running SubLab). If not downloaded SubLab will simulate spikes and ground truth recordings.

Run the file SubLab_Start.m in the SubLab directory.

The program will ask you to give the path to the Matlab or Octave binary. This path can be pasted into the SubLab_Start.m for variable "matlabOctavePath". To find the path to the executable: Right-click on the matlab/octave application icon.

The program will ask for a spike file and a ground truth recording. If press "cancel" for spike file then the program will generate simulated data. If press "cancel" for ground truth recording SubLab will simply not display the ground truth next to the reconstruction.



**Default settings**

By default the program runs 2 epochs of training. For a real reconstruction one should use 10 or more epochs. This information is stored in the maxNumberOfEpochs.txt file. The algorithm uses a validation data set to decide the optimal epoch. 

By default the program runs two threads:

ReconstructionTraining_ProcessCount = 2; % 40 on a Threadripper 2990WX (32 Core, 64Gb)

ReconstructionComplete_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

myRate_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

Simulation_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
