# Concert Hall Monitoring System 
UCSD ECE 257B

Harshith Nagubandi & Rahul Sai Kumar Polisetti

## Installation

Requires:
- conda
- jupyter notebook
- python 3.9.5
- pandas
- numpy
- sklearn
- seaborn
- plotly
- matplotlib
- pytorch
- scipy

Clone the repository using
```
git clone https://github.com/ece257b/concert_hall_monitor.git
```

Create a conda environment from the environment.yml file. The first line of the .yml file sets the new environment's name
```
conda env create -f environment.yml
```
Activate the conda environment
```
conda activate ece257_ml
```

Deactivate when done making changes
```
conda deactivate
```

## Usage

The data we used is stored in [this](https://drive.google.com/drive/folders/1fG6G6tQFB2uV7KixDPU7hG_cquqFtpW2?usp=share_link) drive link.
Please download this folder and store it in the root directory. (concert_hall_monitor/Raw_data)
Note that the file size is large, around 2Gb 

Run the jupyter notebook

```
jupyter notebook ece257_project.ipynb
```
The notebook will already be run and saved. If you rerun the code, please wait for around 20 min for the notebook to run till completion to train the neural networks and generate the plots.



