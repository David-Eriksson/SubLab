The script SubLab.m starts multiple instances of Matlab or Octave to speed up processing. When one of the instances is finished with an epoch for a certain neuron the reconstruction parameters are saved. Then that same instance is checking for new epochs from other neurons to process. A TODO folder for each script keeps track of new jobs. SubLab.m starts multiple instances of the following scripts in this order:

1. SpikesLIFSimulation_distr.m % Simulate spiking and ground truth data

2. ReconstructionTraining_distr.m % Training reconstruction algorithm to optimize parameters.

3. ReconstructionComplete_distr.m % Reconstructing the entire data set based on the cross-validated training parameters.

4. myRate_distr.m % Calculate the my-Rate in order to estimate the reliability of the reconstruction (see manuscript reference).

Associated to those respective scripts there are 4 output folders (under the user selected main data path):

1. Spikes

2. ReconstructionTraining

3. ReconstructionComplete

4. myRate

In each of those folders there are the TODO, DONE, Running folder, and a folder for each session. Each script looks in the respective TODO folder for which sessions that has to be done. 

For the ReconstructionTraining and ReconstructionComplete there is a also TODO folder for each session. This TODO folder contains which is the next epoch for each neuron.
