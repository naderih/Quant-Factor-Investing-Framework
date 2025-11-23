clear all 
set more off 

* set our data paths 
global DATA_DIR "D:\OneDrive\0. DATASETS"
global OUTPUT_DIR "D:\OneDrive\0. DATASETS"


* --- 2. Process Compustat (Fundamentals & Universe Definition) ---
use "$DATA_DIR\compustat_raw.dta", clear 

* filter date 
keep if fyearq >= 1995

* filter for US comanies only 
keep if fic == "USA"

* filter for major exchange codes (NYSE, AMEX, NASDAQ)
keep if inlist(exchg, 11, 12, 14)

keep if indfmt == "INDL"  // Industrial format
keep if datafmt == "STD"  // Standardized format
keep if popsrc == "D"    // Domestic source


* Keep Necessary Variables for Factors (Value, Profitability, Investment, Constraints)
* Identifiers: gvkey, datadate, fyearq, fqtr, cusip, tic, conm
* Value: ceq (Book Equity), pstkq (Preferred Stock), at (Assets), lt (Liabilities)
* Earnings: ibq (Income Before Extra), saleq (Sales)
* Constraints: dlttq (Long Term Debt), dlcq (Debt in Current), oancfq (Cash Flow - often annual, check q), cheq (Cash)
keep gvkey datadate fyearq fqtr tic sic ///
	 ceqq pstkq atq ltq ibq saleq dlttq dlcq ///
	 cheq oancfy dpq dvpspq cshoq prccq oiadpq actq lctq

* Rename to lowercase for Python
rename *, lower

compress
save "$DATA_DIR\temps\compustat_clean_quarterly.dta", replace

*---------------------------------------------------------------------------------
* --- 3. Process CRSP (Market Data) ---
* --- . Load and Filter the Massive CRSP File ---
* Use 'import sas' and specify the variables we want to keep.
* This is more memory-efficient than loading everything.
use "$DATA_DIR\CRSP_2023", 
keep(PERMNO date RET PRC SHROUT HSICCD SHRCD EXCHCD vwretd sprtrn)

di "Raw CRSP data loaded."

rename *, lower
* --- Filter the Universe ---

* a) Filter by Date
gen year_ = year(date)
keep if year_ >= 1995
drop year_
di "Filtered by date."

* b) Filter for Common Stock (CRUCIAL STEP)
* SHRCD 10 and 11 are for ordinary common shares.
keep if inlist(shrcd, 10, 11)
di "Filtered for common stock (SHRCD 10/11)."

* c) Filter for Major Exchanges
* EXCHCD 1=NYSE, 2=AMEX, 3=NASDAQ.
keep if inlist(exchcd, 1, 2, 3)
di "Filtered for major exchanges."

* --- Clean and Prepare Variables ---

* Handle CRSP's price convention for missing quotes
replace prc = abs(prc)

* Rename variables to be clean and lowercase for Python
rename hsiccd sic // Use a consistent name
rename shrcd share_code
rename exchcd exchange_code

di "Variables cleaned and renamed."

* --- Save the Final, Smaller File ---
compress
save "$OUTPUT_DIR\temps\crsp_clean_daily.dta", replace

di "Cleaned CRSP daily data has been saved to crsp_clean_daily.dta"
di "You can now proceed with the Compustat and CCM Stata scripts."




*--------------------------------------------------------------------------------
* --- 4. Process the CCM Linking Table ---
clear
* load the linking data 
import sas using "$DATA_DIR\ccm_may_2025.sas7bdat", clear

keep if LINKPRIM == "C" | LINKPRIM == "P"
keep if LINKTYPE == "LC" | LINKTYPE == "LU"


format %tdCCYY-NN-DD LINKENDDT
format %tdCCYY-NN-DD LINKDT

* missing end dates means the link is still active
replace LINKENDDT=mdy(1 ,1 , 2030) if LINKENDDT == .


* Keep only the key variables
keep GVKEY LPERMNO LINKDT LINKENDDT // using LPERMNO as it's the CRSP identifier

* Rename to be clean
rename *, lower

* Rename to be clean
rename lpermno permno
rename linkdt link_start_date
rename linkenddt link_end_date


compress 
save "$DATA_DIR\temps\ccm_linking_table_clean.dta", replace


*--

di "Data preparation in Stata complete. Three files exported."

