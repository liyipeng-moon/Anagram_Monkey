# Visual Anagram Analysis

This package contains the analysis and plotting code for the Visual Anagram Neuropixels experiments.

**Preprint**

[Neural Representations of Visual Anagrams in Macaque Inferotemporal Cortex](https://www.biorxiv.org/content/10.64898/2026.10.05.755559v1)

**Data availability**

The data download link is shared with the editor and reviewers during peer review. If you would like to access the data at this stage, please [contact us](mailto:moonl@pku.edu.cn).

## 1. System requirements

- The MATLAB code was tested on Windows with MATLAB R2022b.
- The required toolboxes are Image Processing Toolbox, Optimization Toolbox, Parallel Computing Toolbox, Circular Statistics Toolbox, Bioinformatics Toolbox, and Statistics and Machine Learning Toolbox.
- The preprocessed spiking data (27 sessions) occupy about 120 GB, and the analysis requires another 120-150 GB of disk space.

## 2. Usage

After setting the path variables listed below, you can run `AllCodeInOne.m` to reproduce all data figures in our manuscript. On my PC with an Intel Core Ultra 7 265K processor, it takes about 1 hour to preprocess the `GoodUnit` files and save the results to `Data/s0/`, and about 2 hours to run the VM fitting and decoding analyses. It takes several minutes to load the analysis results and generate the figures.

## 3. Folder Structure

```text
Project_Root_Dir/
|-- AllCodeInOne.m                  # MATLAB workflow script
|-- README.md                       # this file
|-- root_dir.mat                    # Local path settings saved by the workflow, used by scripts
|-- Analysis_Plot/                  # Preprocessing, analysis, and plotting scripts
|-- Data/
|   |-- stim/                       # Stimulus images and TSV index files
|   |-- s0/                         # Processed data (Converted from GoodUnit File)
|   |-- single/                     # Single-unit tuning fits and metrics (Figure 2 related)
|   |-- decode_l2/                  # Per-session decoding results (Figure 4 related)
|   |-- extracted_responses/        # Saved model responses (Figure 5 related)
|   |-- neural_pseudopopulation/    # Pooled neural responses (Combined analysis)
|   |-- output/                     # Saved model-comparison and neural decoding results
```

The GoodUnit recording files are stored separately. Set `GoodUnit_dir` in `AllCodeInOne.m` to the folder containing them before running preprocessing.

## 4. Scripts

Run the scripts in each row in order from the package root. Choose the rows for the results you want to reproduce.

| Analysis | MATLAB commands |
| --- | --- |
| Session summary and preliminary experiment | `T1_NumberSummary`, `FS1` |
| Single-unit fitting and Figures 1–2 | `S1_SingleUnit`, `F1_ExampleNeuron`, `F2_DistributionFinal` |
| Supplementary Figure S2 | `FS2` |
| Figure 3 population analysis | `F3_Population` |
| Figure 4 decoding | `S4_decode_cv_L2`, `F4_Decode` |
| Figure 5 Model comparison | `Figure6_Neural_Pooled_Decoding`, `Figure6_Calculate`, `Figure6_Plot` |

## License and code availability

Contact the corresponding author for the project license and repository access. Third-party helpers retain the license terms in their source files and accompanying notices.
