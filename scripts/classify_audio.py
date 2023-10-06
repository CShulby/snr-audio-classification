#!/usr/bin/env python3

import os
import argparse
import subprocess
from multiprocessing import Pool
import shutil


def calculate_snr(audio_file, output_dir):
    """
    Calculates the SNR value of an audio file and writes the result to a log file.
    If the SNR value is greater than 30, the file is copied to the clean_audios directory.
    Otherwise, it is copied to the dirty audios_directory.

    :param audio_file: the path to the audio file
    :param output_dir: the path to the output directory
    """
    # get the path of the current directory
    current_dir = os.path.dirname(os.path.realpath(__file__))

    # set the relative path Ato the calculate_SNR.sh script
    snr_script = os.path.join(current_dir, 'calculate_SNR.sh')

    # Run the calculate_SNR.sh script and capture the output
    process = subprocess.Popen(['bash', snr_script, audio_file], stdout=subprocess.PIPE)
    output, error = process.communicate()

    # Decode the output from bytes to string
    output = output.decode('utf-8')

    # Extract the SNR value from the output
    snr = output.split('\n')[1]

    # Write the file name and SNR value to the log file
    log_file = os.path.join(output_dir, 'stats.log')
    with open(log_file, 'a') as f:
        f.write(f"File Name: {audio_file}\nSNR: {snr} \n\n")

    # Copy the file to the appropriate directory based on the SNR value
    if float(snr) >= 40:
        clean_dir = os.path.join(output_dir, 'clean_audios')
        subprocess.run(['cp', audio_file, clean_dir])
    else:
        dirty_dir = os.path.join(output_dir, 'dirty_audios')
        subprocess.run(['cp', audio_file, dirty_dir])


def process_audio_files(input_dir, output_dir):
    """
    Processes all the audio files in the input directory in parallel and writes the results to a log file.

    :param input_dir: the path to the input directory
    :param output_dir: the path to the output directory
    """

    # Make directories
    if os.path.exists(output_dir + '/stats.log'):
        os.remove(output_dir + '/stats.log')
    if os.path.exists(output_dir + '/clean_audios'):
        shutil.rmtree(output_dir + '/clean_audios')
    if os.path.exists(output_dir + '/dirty_audios'):
        shutil.rmtree(output_dir + '/dirty_audios')
    os.makedirs(output_dir + '/clean_audios', exist_ok=True)
    os.makedirs(output_dir + '/dirty_audios', exist_ok=True)

    # Get a list of all the audio files in the input directory
    audio_files = [os.path.join(input_dir, f) for f in os.listdir(input_dir) if f.endswith(('.wav', '.flac', '.mp3'))]

    # Set up a pool of worker processes
    num_processes = os.cpu_count() - 1
    pool = Pool(processes=num_processes)

    # Process the audio files in parallel
    pool.starmap(calculate_snr, [(f, output_dir) for f in audio_files])

    # Close the pool of worker processes
    pool.close()
    pool.join()


if __name__ == '__main__':
    """
    Main function that parses the command line arguments and starts processing the audio files.
    """
    parser = argparse.ArgumentParser(description='Process audio files and calculate SNR.')
    parser.add_argument('-i', '--input_dir', type=str, required=True, help='the path to the input directory')
    parser.add_argument('-o', '--output_dir', type=str, required=True, help='the path to the output directory')
    args = parser.parse_args()

    # Process the audio files
    process_audio_files(args.input_dir, args.output_dir)
