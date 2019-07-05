# |/bin/env python
import os
from os.path import join, dirname, realpath, isfile, isdir

import pandas as pd
from multiprocessing.pool import Pool

root = dirname(realpath(__file__))


def process_subject(row):
    row_sel = row[1]
    sid = row_sel.name
    in_file = row_sel.FILE
    abide = row_sel.DATABASE
    folder = row_sel.FOLDER
    subject_folder = join(output_folder, abide, folder, sid)  # Crea el .anat en el pipeline (bash)

    # Create folders
    os.makedirs(subject_folder, exist_ok=True)

    # Run pipeline
    pipeline = join(root, 'preprocessing_pipeline_b.sh')
    command = f'{pipeline} {in_file} {subject_folder}'
    print(command)
    os.system('FSLDIR="/usr/local/fsl" && PATH=${FSLDIR}/bin:${PATH}')
    os.system(command)


if __name__ == '__main__':
    # Define dataset folder and database CSV
    dataset_folder = '/home/nicolasmg/Paper2018/ABIDE_II_Muestra/'  # Hombres_Autistas / Hombres_Controles
    output_folder = '/home/nicolasmg/SVMTest/processed_pipeline_b'
    database_csv = join(root, 'database', 'database.csv')
    n_cores = 4

    # assert isdir(dataset_folder), f'Folder {dataset_folder} does not exist!'
    assert isfile(database_csv), f'Database file {database_csv} does not exist.'

    # Load database csv
    database = pd.read_csv(database_csv, index_col='ID')
    print(database.head())

    # Create a multiprocessing Pool
    pool = Pool(n_cores)
    pool.map(process_subject, database.iterrows())
    pool.close()
