# SubLab
Subthreshold reconstruction Laboratory

SubLab uses large scale spiking activity to reconstruct subthreshold activity for individual units. The input spike file is a binary file consisting of pairs of 'doubles': Spike identity (unit number) and spike time (seconds).

???? Bioarxiv ?????



**To run SubLab**

Install Matlab or Octave.

Download SubLab_Package.zip and unpack it.

Run the file SubLab.m in the SubLab directory.

The program will ask you to give the path to the Matlab or Octave binary. This path can be pasted into the SubLab_Start.m for variable "matlabOctavePath". To find the path to the executable: Right-click on the matlab/octave application icon.



**Default settings**

By default the program runs 5 epochs of training. For a real reconstruction one should use 10 or more epochs. This information is stored in the maxNumberOfEpochs.txt file in SubLab.m. The algorithm uses a validation data set to decide the optimal epoch. 

By default the program runs two threads:

ReconstructionTraining_ProcessCount = 2; % 40 on a Threadripper 2990WX (32 Core, 64Gb)

ReconstructionComplete_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

myRate_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

Simulation_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
