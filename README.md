# SubLab
Subthreshold reconstruction Laboratory

SubLab uses large scale spiking activity to reconstruct subthreshold activity for individual units. The input spike file is a binary file consisting of pairs of 'doubles': Spike identity (unit number) and spike time (seconds).

"Reconstruction of in-vivo subthreshold activity of single neurons from large-scale spiking recordings"
https://www.biorxiv.org/content/10.1101/673046v1



**To run SubLab**

Install Matlab or Octave.

Download SubLab_Package.zip and unpack it.

SubLab is available as a **function** and as a **script**:

The function is called SubLab_Function.m and reconstructs the subthreshold activity with 1 millisecond resolution of one user-defined unit (targetNeuron) given a matrix (first row unit identities and second row time spike times in seconds) with the spike identities and spike times (spikeData).

[reconstruction_full, spikes_full] = SubLab_Function(spikeData, targetNeuron, maxNumberOfEpochs)

The function can be tested using the Test_SubLab_Function.m script.

The script is called SubLab.m. The script will ask you to give the path to the Matlab or Octave binary. This path can be pasted into the SubLab_Start.m for variable "matlabOctavePath". To find the path to the executable: Right-click on the matlab/octave application icon.



**Default settings**

By default the program runs 5 epochs of training. For a real reconstruction one should use 10 or more epochs. This information is stored in the maxNumberOfEpochs.txt file in SubLab.m. The algorithm uses a validation data set to decide the optimal epoch. 

By default the program runs two threads:

ReconstructionTraining_ProcessCount = 2; % 40 on a Threadripper 2990WX (32 Core, 64Gb)

ReconstructionComplete_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

myRate_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)

Simulation_ProcessCount = 2; % 10 on a Threadripper 2990WX (32 Core, 64Gb)
