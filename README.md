# A Professional-Grade Quantitative Factor Investing Framework

### Key Technologies: Python | Pandas | Statsmodels | Scikit-learn | CRSP | Compustat

## Project Overview

This repository contains a professional-grade implementation of a quantitative active management framework, built from first principles as outlined in Grinold & Kahn's seminal book, "Active Portfolio Management." The project demonstrates an end-to-end pipeline, from the data engineering of CRSP/Compustat to the construction and attribution of an alpha-optimized portfolio.

This is a live research and development environment, designed to be a robust and scalable platform for testing systematic investment strategies.

**Disclaimer:** This project is for educational and demonstrative purposes only. The strategies and models within do not constitute investment advice.

---

## The Core Framework: A Blueprint for Active Management

The project follows a disciplined, quantitative approach, separating the investment process into its core, manageable components:

1.  **Risk Modeling:** The foundation is a **Multifactor Risk Model**. We posit that asset returns are driven by common factors and a stock-specific component. This structure is more robust and insightful than a simple historical covariance matrix. The total covariance matrix ($V$) is defined as:
    $$
    V = XFX^T + \Delta
    $$
    *   $X$: NxN Factor Exposure matrix (the "DNA" of each stock).
    *   $F$: KxK Factor Covariance matrix (the "macro blueprint" of how factors interact).
    *   $\Delta$: The Diagonal Specific Risk matrix (the idiosyncratic, un-diversifiable risk of each stock).

2.  **Alpha Modeling:** We generate a forecast of **expected residual return**, or **alpha ($\alpha$)**. A critical step is to ensure these alpha signals are **benchmark-neutral**, which purifies the signal and separates stock-selection skill from unintended market bets.
    $$
    h_B^T \alpha = 0
    $$

3.  **Portfolio Construction:** We use a **quadratic optimizer** to combine the alpha signal with the risk model. The goal is to build the optimal active portfolio ($h_{PA}$) that maximizes the manager's **Value Added (`VA`)** objective. This function creates a disciplined trade-off between the expected reward (alpha) and the active risk taken.
    $$
    \text{Maximize:} \quad VA = \alpha_p - \lambda_R \cdot \psi_p^2
    $$
    The unconstrained solution provides the blueprint for our optimal active holdings:
    $$
    h_{PA}^* \propto V^{-1} \alpha
    $$

---

## Data Engineering Pipeline

This project uses professional-grade data from CRSP and Compustat. The initial data preparation is a two-stage process designed for efficiency and rigor.

1.  **Stata Pre-processing (`prepare_data.do`):** The raw, multi-gigabyte CRSP and Compustat datasets are first filtered and cleaned in Stata. This "chop" is highly efficient for these large legacy formats. It filters for date range, US common stocks (using `SHRCD` and `EXCHCD`), and keeps only the necessary variables, exporting clean, manageable `.dta` files.

2.  **Python Point-in-Time Merge (`01_Data_Preparation.ipynb`):** The core data engineering happens in Python. We use `pandas.merge_asof()` to perform a sophisticated, event-driven merge. This correctly joins the high-frequency market data from CRSP with the lower-frequency, lagged fundamental data from Compustat, creating a single, point-in-time correct panel dataset and avoiding lookahead bias. The final output is saved in the efficient Parquet format.

---

## Project Structure & Notebooks

The framework is implemented as a sequential pipeline of Jupyter Notebooks.

**`01_Data_Preparation.ipynb`**
*   **Purpose:** The main data engineering hub. Merges the clean CRSP, Compustat, and CCM linking files into a single, analysis-ready monthly panel dataset.
*   **Key Techniques:** `pd.merge_asof` for point-in-time correctness.
*   **Output:** `panel_data.parquet`

**`02_Factor_Exposure_Creation.ipynb`**
*   **Purpose:** Constructs the time-varying Factor Exposure matrix ($X_t$).
*   **Process:** Calculates standardized, capitalization-weighted exposures for a set of classic factors. This notebook implements **composite factors** (e.g., Value is a blend of B/M and E/P) and correctly lags accounting data to avoid lookahead bias.
*   **Output:** `factor_exposures_titan.parquet`

**`03_Risk_Model_Estimation.ipynb`**
*   **Purpose:** Estimates the components of the multifactor risk model ($F$ and $\Delta$).
*   **Process:** Implements the **Fama-MacBeth procedure** by running monthly cross-sectional regressions.
*   **Output:** The estimated Factor Covariance Matrix ($F$) and a vector of Specific Variances (the diagonal of $\Delta$).

**`04_Alpha_Signal_Definition.ipynb`**
*   **Purpose:** Generates a clean, benchmark-neutral alpha signal.
*   **Process:** Uses a raw **Momentum** signal, diagnoses its inherent benchmark bias, and applies a **beta-adjusted neutralization** to purify the signal.
*   **Output:** The final alpha vector ($\alpha$).

**`05_Portfolio_Construction.ipynb`**
*   **Purpose:** The final synthesis. Constructs the optimal active portfolio and performs risk attribution.
*   **Process:** Uses the `VA` objective function and all previously generated inputs to solve for the optimal active holdings ($h_{PA}^*$).
*   **Output:** A "Risk & Attribution Report" that decomposes the portfolio's active risk into factor-driven and stock-specific sources.

**`06_LLM_Proof_Of_Concept.ipynb`**
*   **Purpose:** A proof-of-concept demonstrating a next-generation approach to creating a Financial Constraint factor using modern NLP.
*   **Process:** Uses a **zero-shot classification LLM** from the Hugging Face `transformers` library to perform a targeted, thematic analysis of text parsed from 10-K filings.

---

## How to Run This Project

1.  **Data Setup:** This project requires access to CRSP, Compustat, and the CCM Linking Table. (a toy version of this project using a small stock sample from yahoo Finance is available at https://github.com/naderih/Quantitative-Active-Management. For this project, the raw data files are not included in this repository. You must first run the Stata script `prepare_data.do` to generate the initial clean `.dta` files.
2.  **Environment Setup:** The required Python libraries are listed in the `requirements.txt` file. You can install them using pip:
    ```bash
    pip install -r requirements.txt
    ```
3.  **Run Notebooks:** Run the Jupyter Notebooks in sequential order (01 through 05).

---

## Future Enhancements & Research Directions

This framework is a robust foundation for further research. Potential next steps include:
*   **Advanced Alpha Signals:** Replace the simple factors with more sophisticated signals, particularly the **LLM-based Financial Constraint factor** prototyped in Notebook 6.
*   **Risk Model Refinements:** Implement more advanced forecasting techniques for the Factor Covariance matrix ($F$), such as **EWMA and shrinkage estimators**, to make the risk model more adaptive.
*   **Backtesting Engine:** Expand the single-period optimization into a full, event-driven backtesting engine to simulate strategy performance over time, accounting for transaction costs, turnover, and implementation lag.
*   **Constrained Optimization:** Implement real-world constraints in the portfolio construction step, such as no-short-selling constraints, position limits, and factor exposure limits.

