#!/bin/bash

# Script to calculate signal-to-noise ratio (SNR) of an audio file

# Usage: bash calculate_SNR.sh <input_file>

# <input_file>: Path to the input audio file (WAV, FLAC or MP3 format)

# set input audio file name
input_file=$1
echo "Input File: $input_file"

# determine file type and set flag for sox command
if [[ "$input_file" == *.mp3 ]]; then
  flag="-t mp3"
else
  flag=""
fi
# set number of frames to average for noise and signal
num_frames_peak=15
num_frames_trough=5

# get audio duration in seconds
durline=$(sox $flag "$input_file" -n stat 2>&1 | grep "Length (seconds):")
duration=$(echo $durline | awk -F ':' '{print$2}')

# set frame duration to 50ms
frame_duration=0.05

# calculate number of frames
n_frames=$(echo "($duration / $frame_duration)" | bc | awk '{print int($1+0.5)}')

# initialize arrays to store peak and trough RMS values
peak_rms=()
trough_rms=()

# loop through frames and calculate noise and signal RMS
i=1
while [ "$i" -le "$n_frames" ]; do
  start=$(echo "($i - 1) * $frame_duration" | bc)
  end=$(echo "$i * $frame_duration" | bc)
  duration=$(echo "$end - $start" | bc)

  # trim audio to current frame
  sox $flag "$input_file" -n trim "$start" "$duration" stats > /dev/null 2>&1

  # get RMS values and exclude zeros
  peak_rms_values=$(sox $flag "$input_file" -n trim "$start" "$duration" stats 2>&1 | grep -E 'RMS Pk dB' | awk '{if ($4 < 0) {print $4}}' | sort -n)

  # Calculate IQR
  arr=($peak_rms_values)
  num_values=${#arr[@]}
  q1_idx=$((num_values / 4))
  q3_idx=$((3 * num_values / 4))
  q1=${arr[$q1_idx]}
  q3=${arr[$q3_idx]}
  iqr=$(echo "$q3 - $q1" | bc)

  # Calculate upper and lower bounds
  upper=$(echo "$q3 + 1.5 * $iqr" | bc)
  lower=$(echo "$q1 - 1.5 * $iqr" | bc)

  # Filter out outliers
  peak_rms_values=$(echo "$peak_rms_values" | awk -v upper=$upper -v lower=$lower '{if ($1 >= lower && $1 <= upper) {print $1}}')
  trough_rms_values=$(sox $flag "$input_file" -n trim "$start" "$duration" stats 2>&1 | grep -E 'RMS Tr dB' | awk '{if ($4 < 0) {print $4}}' | sort -n)

  # add current frame's RMS values to arrays
  peak_rms+=($peak_rms_values)
  trough_rms+=($trough_rms_values)

  i=$((i+1))
done

# sort peak and trough RMS arrays and extract top/bottom 5 values
sorted_peak_rms=$(printf '%s\n' "${peak_rms[@]}" | sort -n)
top_peak_rms=$(echo "$sorted_peak_rms" | head -n $num_frames_peak)
sorted_trough_rms=$(printf '%s\n' "${trough_rms[@]}" | sort -n)
bottom_trough_rms=$(echo "$sorted_trough_rms" | tail -n $num_frames_trough)
# calculate noise and signal RMS from top/bottom 5 values
noise_rms=$(echo "$bottom_trough_rms" | awk '{sum+=$1} END {print sum/NR}')
signal_rms=$(echo "$top_peak_rms" | awk '{sum+=$1} END{print sum/NR}')

# print noise and signal RMS values
#echo "Noise RMS: $noise_rms dB"
#echo "Signal RMS: $signal_rms dB"

# calculate and print SNR
snr=$(echo "$signal_rms $noise_rms" | awk '{printf("%.0f\n", ($1-$2)*-1)}')
echo $snr
