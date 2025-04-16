************QLR*********************
*11/15/2011 (minor edits on 4/9/2017)
*Added return scalar on 4/19/2019
*Added date as return scalar on 5/22/2019
*Gregory Bruich
*Send corrections and suggestions to gbruich@fas.harvard.edu
capture program drop qlr
program define qlr, rclass
	syntax varlist(min=2 ts) [if] [, TRim(real 0.15)] [REGRESS] [Newey(integer 0)] [Display(integer 5)] [GRAPH] [mlabpos(integer 2)] [TYPE(string)]
	cap postclose qlr
	
	*Separate dependent from regressors
	local depvar: word 1 of `varlist'
	local indepvars: list varlist -depvar
	
	*Take care of regressors defined with lag notation
	tsrevar `indepvars', substitute	

	quietly reg `depvar' `indepvars' `if', r
	local t = e(N)
	
    *start trimming at begining of sub sample used for regression
	preserve
		if missing("`if'"){
			local if ""
			}
		else{
			qui keep `if'
		}
		cap tsset
		local timevar = r(timevar)
		local timeformat = r(tsfmt)
		local break_lb = r(tmin)+round(`t'*`trim')
		local break_ub = r(tmin)+round(`t'*(1-`trim'))
	restore
	
	*Use robust or Newey West HAC
	if missing("`regress'"){
		local method newey
		*Set lags for Newey-West standard errors
		if `newey'==0{
			local newey = round(.75*`t'^(1/3))
			local nw_lags = "lag(`newey')"
			local msg "Computed with Newey-West standard errors with `newey' lags. "
			}
		else{
			local nw_lags = "lag(`newey')"
			local msg "Computed with  Newey-West standard errors with `newey' lags. "
			}
	}
	else{
		local method regress
		local nw_lags r
		local msg ""
	}
	
	preserve
	
		*Start a file in which to save the results
		*these are the variable names to be used in qlr.dta
		postfile qlr date F restrict trimming using qlr, replace

		local fmax = -1e+9
		local r_rest = 0
		local r_trim = `trim'
		local obs = 0
		
		*loop through all of the dates between the upper and lower bounds
		quietly levelsof `timevar' if `timevar'>=`break_lb'&`timevar'<=`break_ub', local(levels)
		foreach ma of local levels{
				*define an indicator for the break
				tempvar break
				quietly gen `break' = 0
				quietly replace `break'=1 if `timevar'>=`ma'
				
				*define interaction with break and each of the lags for each of the independent variables
				foreach var of local indepvars{
					local nm = strtoname("`var'",1)
					quietly gen tempbreak_`nm' = `var'*`break'	
				}
				
				*run the regression and f test
				quietly `method' `depvar' `indepvars' `break' tempbreak* `if', `nw_lags'
				quietly testparm `break' tempbreak*
				
				*save the date, f stat, number of restrictions, and trimming to data set
				quietly post qlr (`ma') (r(F)) (r(df)) (`trim')
				
				*Store maximum F statistic\
				if r(F) > `fmax' {
				local fmax = r(F)
				local r_rest = r(df)
				local obs = e(N)
				local breakdate: disp `timeformat' `ma'
				}
				
				*drop variables for next iteration
				drop `break' tempbreak*
			}

		*save the output in qlr.dta
		postclose qlr
		
		*save the maximum f stat
		return scalar qlr = `fmax'
		return scalar restrict = `r_rest'
		return scalar trim = `trim'
		return scalar N = `obs'
		return local maxdate "`breakdate'"
	
		*Open, display, and graph f stats
		use qlr.dta, clear
		qui format date `timeformat'
		gsort - F
		list in 1/`display'
		if !missing("`graph'"){
			if missing("`type'"){
				display "`msg'Results saved as qlr.dta and qlr.png"
				}
			else {
				display "`msg'Results saved as qlr.dta and qlr.`type'"
			}
		}
		else{
			display "`msg'Results saved as qlr.dta"
		}
				
		*Optional: Draw plot
		qui tsset date
		if !missing("`graph'"){
			quietly sum F
			local qlrstat: display %12.3f r(max)
			
			*Create string variable that contains formatted date of max F stat and date
			cap drop breakdate*
			gen breakdate1 = "`breakdate'"
			replace breakdate1 = strtrim(breakdate1)
			gen breakdate2 = "`qlrstat'"
			replace breakdate2 = strtrim(breakdate2)
			gen breakdate = breakdate1 + ", " + breakdate2

			quietly sum F
			local supwald = r(max)

			*Draw the graph
			#delimit ;
			twoway 
					(tsline F)  
					(scatter F date if F>=`supwald'-0.00001, sort mcolor(red) mlabcolor(black) mlabel(breakdate)  mlabsize(small) mlabposition(`mlabpos')),   
					ytitle("Robust F statistic")  
					xtitle("Break Date")  
					title("Chow F-stat for different break dates with `trim' trimming", color(black) size(medium))  
					legend(off) graphregion(color(white)) bgcolor(white)  ;
			#delimit cr
			
			*Drop the labels for the graph
			quietly drop breakdate*
			
			*Default file type is png
			if !missing("`type'"){
				if "`type'"=="gph"{
					qui graph save qlr.gph, replace
				}
				else{
					qui graph export qlr.`type', replace 
				}
			}
			else{
				qui graph export qlr.png, replace 
			}
		}
		*Save the data
		qui saveold qlr.dta, replace
	restore 
	
end
*End program
