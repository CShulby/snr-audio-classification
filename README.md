# SNR Audio Classification

This repository contains scripts to process audio files and classify them as clean or dirty based on their signal-to-noise ratio (SNR). The scripts are designed to run on Unix-based systems and require the installation of the SoX command-line utility.

## Motivation:

The Speech Processing field has evolved significantly over the past few decades, with recent advances allowing for impressive capabilities such as voice-cloning and low-shot or zero-shot TTS systems. However, one major challenge in this field is the availability of diverse and high-quality datasets for building models. To address this challenge, we built this repository, which provides a tool for easily classifying audios based on their SNR value.

While there are many projects that use machine learning to calculate SNR, these can be prone to errors and hallucinations that are difficult to understand. As people who enjoy tinkering with levers, we wanted to create a simple and easy-to-use tool that provides a starting point for classifying audios based on their SNR value. We hope that this tool can be expanded upon in the future with more sophisticated signal processing techniques that aim to produce high-quality and interpretable results.

## Requirements

    SoX
    Python 3.X or later

## Installation

    Install SoX by running sudo apt-get install sox in a terminal window (for Ubuntu-based systems).
    
    Install any dependencies in the requirements.txt file

    Clone this repository to your local machine.

    Navigate to the root directory of the cloned repository in a terminal window.

    Create a virtual environment by running python3 -m venv env.

    Activate the virtual environment by running source env/bin/activate.


## Usage

The main script for classifying audio files is classify_audio.py.

To use the script, run the following command:

```
python3 classify_audio.py -i /path/to/input_dir -o /path/to/output_dir
```

This will process all the audio files in the input directory and classify them as **clean** or **dirty** based on their SNR. The results will be written to a log file (to your output directory) and the audio files will be copied to the appropriate directory in the output directory.

Note that the input directory should contain only audio files in WAV, FLAC or MP3 format.
Script details

### calculate_SNR.sh

This shell script is called by classify_audio.py to calculate the SNR of an audio file. The script uses SoX to extract the peak and trough RMS amplitudes of the audio and calculates the SNR value. The SNR value is written to the standard output.

### classify_audio.py

This Python script processes all the audio files in the input directory in parallel (using N-1 available CPUs) and writes the results to a log file. The script creates two directories in the output directory: clean_audios and dirty_audios. If an audio file has an SNR greater than or equal to the threshold (30 dB by default but this value can be changed in the script), it is classified as **clean** and copied to the clean_audios directory. Otherwise, it is classified as **dirty** and copied to the dirty_audios directory.

The script takes two command line arguments:

```
    -i or --input_dir: the path to the input directory containing the audio files to classify
    -o or --output_dir: the path to the output directory where the classified audio files and log file will be written
```

## test

This folder contains unit tests for classify_audio.py
Example usage

Suppose we have a directory called test/wavs/ containing 3 audio files:

```
test/wavs/
├── audio1.wav
├── audio2.wav
└── audio3.wav
```

To classify the audio files, we can run the following command:

```
python3 scripts/classify_audio.py -i test/wavs/ -o output_audio/
```

This will create two directories in the output_audio directory:

```
output_audio/
├── clean_audios/
├── dirty_audios/
└── stats.log
```

The stats.log file will contain the SNR value for each audio file, along with its classification as **clean** or **dirty**. The audio files will be copied to either the clean_audios or dirty_audios directory based on their classification. In reality, I have left 4 files. Two of which should be classified as **dirty** and two should be **clean** if using 30-40 or so dBs SNR. I also have an example **stats.log** file so that the results can be reproduced using the default settings and serve as a reference, should you choose to play with them.

## Limitations

While SNR is one of the most important quality metrics, by itself, it doesn't solve everything when aiming for high-quality TTS audios. The script cannot detect other audio-quality metrics like clipping, bursts, jumps or saturation. In the future it would make sense to build a library to handle these cases.

While it tries to discard outliers and average a number of windows to avoid the trap of sudden loudness, the script cannot guarentee that the entire audio has a uniform SNR. It is recommended to use short clips (4-10 seconds). It should be noted that the algorithm is optimistic. It tries to avoid scoring the best case scenario (lighest SNR in the file) as well as the worst case scenario (lowest SNR in the file), but it aims to be closer to the former.

## Conclusions

In this project, we have created a system for classifying audio files as **clean** or **dirty** based on their signal-to-noise ratio (SNR). We first wrote a Bash script to calculate the SNR of an audio file using the SoX tool, and then used this script in a Python script to process multiple audio files in parallel.

The resulting system can be useful in many applications, such as detecting noise pollution in urban areas or identifying faulty equipment based on the quality of its output. By automating the classification process, we can save time and resources compared to manual inspection.

We hope that this project has been informative and helpful in demonstrating how to use Bash and Python scripts to process audio files. With some modifications, this system could be adapted to fit a wide variety of use cases in the audio processing field.
