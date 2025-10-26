#!/bin/bash
#SBATCH --job-name=train_demo
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=1                 
#SBATCH --partition=gpu         
#SBATCH --time=02:00:00          

source /home/$USER/miniconda3/etc/profile.d/conda.sh
conda activate my_research

python train.py