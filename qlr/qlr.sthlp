{smcl}
{* *! version 1.0 gbruich 09apr2025}{...}
{title:Title}

{phang}
{bf:qlr} — Quandt Likelihood Ratio (QLR) test for structural breaks using a HAC variance-covariance matrix

{title:Syntax}

{p 8 17 2}
{cmd:qlr} {it:depvar} {it:indepvars} {cmd:if tin(}{it:start}{cmd:,}{it:end}{cmd:)}{cmd:,} [ {it:options} ]

{title:Description}

{pstd}
{cmd:qlr} implements the Quandt Likelihood Ratio (QLR) test for structural breaks using a HAC variance-covariance matrix by default.  
It produces a dataset (`qlr.dta`) and a graph of F-statistics testing for a break in the coefficients and intercept in the regression, plotted as a function of the break date, for all possible break dates in the middle 70% of the sample.

{title:Options}

{phang}
{cmd:graph} — Produces a graph of F-statistics testing for a break in the coefficients and intercept in the regression, plotted as a function of the break date, for all possible break dates in the middle 70% of the sample.

{phang}
{cmd:type(}{it:pdf}{cmd:)} — Saves the graph as a PDF, PNG, or other supported file type.

{phang}
{cmd:trim(}{it:#}{cmd:)} — Specifies the trimming percentage (default is 0.15).

{phang}
{cmd:display(}{it:#}{cmd:)} — Specifies the number of top F-statistics to report (default is 5).

{phang}
{cmd:regress} — Changes from the default HAC variance-covariance matrix to HC1 (Heteroskedasticity Robust) variance-covariance matrix.

{title:Examples}

{pstd}
Load the example dataset and perform the QLR test:

{phang2}
{cmd:. * Load in data (original data from FRED)}
{cmd:. use qlr_example.dta, clear}

{phang2}
{cmd:. * ADL(4,3) model forecasting employment growth with its own lags and }
{cmd:. * the BAA-Tbond spread}
{cmd:. reg dlemp L(1/4).dlemp L(1/3).baa_r10 if tin(1962m1,2017m3), r}

{phang2}
{cmd:. * QLR test, generating graph of F statistics}
{cmd:. qlr dlemp L(1/4).dlemp L(1/3).baa_r10 if tin(1962m1,2017m3), graph}

{phang2}
{cmd:. * Saving graph of F statistics}
{cmd:. graph export adl43_qlr.pdf, replace}

{phang2}
{cmd:. * Save QLR statistics and break date to export into a table}
{cmd:. local breakdate = r(breakdate)}
{cmd:. scalar qlr = r(qlr)}
{cmd:. scalar restrictions = r(restrictions)}

{title:Saved Results}

{pstd}
{cmd:qlr} saves the following in {cmd:r()}:

{phang}
{cmd:r(breakdate)} — Break date (corresponding to the maximum F-statistic)

{phang}
{cmd:r(qlr)} — QLR statistic (maximum F-statistic)

{phang}
{cmd:r(restrictions)} — Number of restrictions being tested

{title:Author}

{pstd}
Gregory Bruich  
Harvard University  
Email: gbruich@fas.harvard.edu

{title:Also see}

{psee}
Manual: {bf:[TS] structural break testing}

{psee}
Online: {browse "https://github.com/gbruich/metrics":GitHub Repo}
