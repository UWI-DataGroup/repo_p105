** HEADER -----------------------------------------------------
**  DO-FILE METADATA
    //  algorithm name			        effect_size.do
    //  project:				        GDAR
    //  analysts:				       	Ian HAMBLETON
    // 	date last modified	            29-JAN-2019
    //  algorithm task			    Reading the FAO population dataset

    ** General algorithm set-up
    version 15
    clear all
    macro drop _all
    set more 1
    set linesize 80

    ** Set working directories: this is for DATASET and LOGFILE import and export
    ** DATASETS to encrypted SharePoint folder
    local datapath "X:/The University of the West Indies/DataGroup - repo_data/data_p105"
    ** LOGFILES to unencrypted OneDrive folder (.gitignore set to IGNORE log files on PUSH to GitHub)
    local logpath X:/OneDrive - The University of the West Indies/repo_datagroup/repo_p105

    ** Close any open log file and open a new log file
    capture log close
    log using "`logpath'\effect size", replace
** HEADER -----------------------------------------------------



** ------------------------------------------------------------
** FILE 1 - POPULATION and URBANISATION
** ------------------------------------------------------------
** HOTN data
use "`datapath'/version01/1-input/hotn_v41", clear

keep pid age sex educ sbp1 sbp3 dbp1 dbp3

** Standardize
foreach var in sbp1 sbp3 dbp1 dbp3 {
    sum `var'
    gen `var'_st = (`var' - r(mean) ) / r(sd)
}

gen sbp_diff = sbp3_st - sbp1_st
gen dbp_diff = dbp3_st - dbp1_st


** Difference model
** TWO questions
** (A) is this the average group change effect?
** (B) Which should be the outcome. You assume that SSB changes cause food change. Conversely, food change may cause SSB change
** Coefficients vary...
regress sbp_diff dbp_diff
regress dbp_diff sbp_diff
regress sbp_diff dbp_diff sex


** What if we perform XT modelling?
rename sbp1_st s1
rename sbp3_st s2
rename dbp1_st d1
rename dbp3_st d2
reshape long d s , i(pid) j(measure)
xtset pid measure

** (A) You have in fact performed a fixed-effects regression...
** Compare model outputs
xtreg s d, fe
preserve
    reshape wide d s , i(pid) j(measure)
    gen sd = s2 - s1
    gen dd = d2 - d1
    regress sd dd
restore

** (B) What happens when we include an invariant confounder
** A fixed effects regression does not allow sex - it is invariant over measure
** u is an estimate of v + effect of sex
** The difference model allows SEX - it now becomes a conglomerate model of fixed (within) effect + between effect
xtreg s d sex , fe
preserve
    reshape wide d s , i(pid) j(measure)
    gen sd = s2 - s1
    gen dd = d2 - d1
    regress sd dd sex
restore

** Decompose
egen avg_d = mean(d), by(pid)
gen dev_d = d - avg_d
xtreg s avg_d dev_d sex

** Now mixed effect
** Random-intercept model, analogous to xtreg
mixed s d || pid:
** Random-intercept and random-slope (coefficient) model
mixed s d || pid: R.sex




** ---------------------------------------------------
