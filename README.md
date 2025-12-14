# Replication: Comparative Politics and the Synthetic Control Method

[![DOI](https://img.shields.io/badge/Original%20Paper-10.1111%2Fajps.12116-blue)](https://doi.org/10.1111/ajps.12116)
[![Data](https://img.shields.io/badge/Data-Harvard%20Dataverse-red)](https://doi.org/10.7910/DVN/24714)

## Overview

This repository contains a **replication and extension** of:

> Abadie, A., Diamond, A., & Hainmueller, J. (2015). "Comparative Politics and the Synthetic Control Method." *American Journal of Political Science*, 59(2), 495-510.

The original paper estimates the **economic impact of German reunification (1990) on West Germany's per-capita GDP** using the synthetic control method.

## Key Findings

| Metric | Original Paper | This Replication |
|--------|---------------|------------------|
| Main Effect | Negative GDP impact | **-$1,571 (-6.0%)** by 2003 |
| Top Weight (Austria) | ~42% | 41.8% |
| Pre-treatment RMSPE | ~120 | 119.64 |
| Statistical Significance | p ≈ 1/16 | **p ≈ 0.059** (1/17) |

## Repository Structure

```
synthetic_control_papre_replication/
│
├── README.md                 # This file
├── code/
│   ├── replication.r         # Main replication script (cleaned, documented)
│   └── original_rep.r        # Original authors' code from Dataverse
│
├── data/
│   ├── repgermany.dta        # Panel data (17 OECD countries, 1960-2003)
│   └── dataset.zip           # Original data package from Harvard Dataverse
│
├── output/
│   ├── figure2_replication.png      # West Germany vs Synthetic (main result)
│   ├── figure3_replication.png      # GDP Gap analysis
│   ├── figure5_rmspe_ratio.png      # RMSPE Ratio (placebo inference)
│   ├── extension_placebo_gaps.png   # Spaghetti plot (all placebos)
│   ├── extension_placebo_filtered.png # Filtered placebo test
│   ├── rmspe_results.csv            # RMSPE data for all countries
│   ├── gap_data.csv                 # Gap data for all countries
│   └── main_results.RData           # R workspace with results
│
└── paper/
    └── replication_paper.md         # Full replication paper (Markdown)
```

## Requirements

### Software
- **R** version 4.0+ (tested on 4.5.2)
- Required R packages:
  - `Synth` (synthetic control method)
  - `foreign` (read Stata files)

### Installation

```r
# Install required packages
install.packages(c("Synth", "foreign"))
```

## How to Run

### Option 1: Run the Full Replication

```bash
cd synthetic_control_paper_replication
Rscript code/replication.r
```

This will:
1. Load the German reunification data
2. Construct synthetic West Germany
3. Generate all figures (saved to `output/`)
4. Run placebo tests for statistical inference
5. Print summary statistics

### Option 2: Interactive R Session

```r
# Set working directory
setwd("path/to/synthetic_control_paper_replication")

# Run the replication
source("code/replication.r")
```

## Output Files

After running the code, you'll find:

| File | Description |
|------|-------------|
| `figure2_replication.png` | West Germany vs Synthetic West Germany trajectories |
| `figure3_replication.png` | GDP gap (treatment effect over time) |
| `figure5_rmspe_ratio.png` | RMSPE ratio ranking for placebo inference |
| `extension_placebo_gaps.png` | Spaghetti plot showing all country gaps |
| `extension_placebo_filtered.png` | Filtered placebo (well-fitted controls only) |
| `rmspe_results.csv` | Pre/Post RMSPE and ratios for all countries |
| `gap_data.csv` | Year-by-year gaps for all countries |

## Extension: Placebo Inference

This replication extends the original paper by implementing comprehensive **placebo tests**:

1. **In-space placebo**: Apply synthetic control to each control country as if it received treatment in 1990
2. **RMSPE ratio**: Compare post-treatment fit degradation across countries
3. **Filtered analysis**: Restrict to countries with good pre-treatment fit

**Result**: West Germany has the highest RMSPE ratio (16.26), yielding an implied p-value of **0.059**.

## Data Source

The data comes from:
- **Penn World Table** (GDP, investment, trade)
- **OECD databases** (inflation, industry share, schooling)

Original data available at: [Harvard Dataverse doi:10.7910/DVN/24714](https://doi.org/10.7910/DVN/24714)

## Citation

If you use this replication, please cite:

```bibtex
@article{abadie2015comparative,
  title={Comparative politics and the synthetic control method},
  author={Abadie, Alberto and Diamond, Alexis and Hainmueller, Jens},
  journal={American Journal of Political Science},
  volume={59},
  number={2},
  pages={495--510},
  year={2015}
}
```

## Author

**Ahmed Bakr**  
CS130 - Causal Inference  
December 2024

## License

This replication is for educational purposes. Original data is released under CC0 1.0 by the authors.

