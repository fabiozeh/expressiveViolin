Expressive Dynamic Modeling for Violin
--------------------------------------

This repository contains code developed at Universitat Pompeu Fabra for supporting research in music expression modeling.

All code available has been developed and tested in Mathworks MATLAB r2018a. No additional installations required. Due to licensing restrictions, not all datasets used have been made available.
To reproduce the different experiments, refer to the scripts in the code/experiments folder. A specific README file in that folder states the purpose of each one.

When cloning this repository, remember to do so with the "recursive" option (Git 1.6.5 or later) in order to load submodules as well.
```
git clone --recursive https://github.com/fabiozeh/expressiveViolin.git
```

### Credits

Some third party code dependencies are included, namely:

#### pYin Vamp Plugin

The system uses the "notes" algorithm implemented in the pYin Vamp plugin, developed by Matthias Mauch @ QMUL and described in the [Tony paper](https://code.soundsoftware.ac.uk/publications/147?project_id=297).

#### Sonic Annotator

The [Sonic Annotator](http://www.vamp-plugins.org/sonic-annotator/) is a command-line tool for executing Vamp plugins developed and maintained by QMUL.

#### Midi Toolbox

The MATLAB code uses functions of the [Midi Toolbox](https://github.com/miditoolbox/1.1) for reading/writing MIDI files and also its implementation of Emilios Camboroupoulos' Local Boundary Detection Model as described in the [LBDM paper](http://users.auth.gr/emilios/papers/icmc2001.pdf).
