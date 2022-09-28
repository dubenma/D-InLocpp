# CNN for relative error estimation 

This CNN is used in combination with DSIFT localization algorithm. CNN serves as a guideline for searching among the images chosen by DSIFT.
As this CNN's encoder is used the Efficient-net. 

## Installation

Clone the repository and install the python virtual environment from *requirements.txt*.

## Usage

The repository contains two main scripts, one for training and another for evaluation.

For the `train.py` serve the following arguments:
* `--method_name`: all current options are implemented in `models.py`
* `--error_fc`: function used to convert gt angle and pose difference to target training number, options are implemented in `train.py`
* `--device`: cuda/cpu
* `--out_wghs_path`: save path for CNN weights
* `--raw_data_path`: path at which are results from previous stage of pipeline, i.e. DSIFT - note that the loading method from this path must be reimplemented in `dataset.py` to be compatible with your data structure
* `--preprocessed_data_path`: the path where to save the raw data processed for training for faster loading
* `--checkpoint_path`: path for initial checkpoint for CNN
* `--use_mask`: whether to use masked images during training

For the `eval.py` serve the following arguments:
* `--data_path`: path from where to load the output data from the previous pipeline stage - note that the code extensively relies on data structure, so it is needed to edit the data loading part in `eval.py` as well
* `--method_name`: all current options are implemented in `models.py`
* `--results_path`: where to save the evaluation results
* `--checkpoint_path`: weights for the evaluated model
* `--filter_mask`: whether to use masked images during evaluation
