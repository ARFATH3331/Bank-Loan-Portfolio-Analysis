-- BANK LOAN PORTFOLIO ANALYSIS
-- Source table: dbo.BankLoans_Clean

-- 1. DATA QUALITY


-- 1.1 How many total rows and unique accounts are in the dataset?

select 
	count(*) as total_rows, 
	count(distinct Account_ID) as Unique_Acc_ID
from dbo.BankLoans_Clean;


-- 1.2 Are any Account_ID values missing or duplicated?

SELECT Account_ID, COUNT(*) AS Duplicate_Count
FROM dbo.BankLoans_Clean
GROUP BY Account_ID
HAVING COUNT(*) > 1;

	
-- 1.3 Which important columns contain missing values?
select 
	sum(case when Account_ID is null then 1 else 0 end) as account_ID_missing_values,
	sum(case when Loan_Status is null then 1 else 0 end) as Loan_status_missing_values,
	sum(case when Loan_Amount is null then 1 else 0 end) as Loan_amount_missing_values,
	sum(case when Funded_Amount is null then 1 else 0 end) as Funded_amount_missing_values,
	sum(case when Disbursement_Date is null then 1 else 0 end)as Disbursement_Date_missing_values,
	sum(case when Is_Delinquent_Loan is null then 1 else 0 end) as Is_Delinquent_Loan_missing_values,
	sum(case when Is_Default_Loan is null then 1 else 0 end) as Is_Default_Loan_missing_values
	from dbo.BankLoans_Clean;

-- 1.4 What values appear in Loan_Status and the delinquency/default flags?

select 
	distinct loan_status Is_Delinquent_Loan 
from dbo.BankLoans_Clean;

select 
	SUM(CASE
        WHEN UPPER(LTRIM(RTRIM(Is_Delinquent_Loan))) IN ('Y', 'YES', '1', 'TRUE')
        THEN 1 ELSE 0
    END) AS Delinquent_Loans,
    SUM(CASE
        WHEN UPPER(LTRIM(RTRIM(Is_Default_Loan))) IN ('Y', 'YES', '1', 'TRUE')
        THEN 1 ELSE 0   
    END) AS Defaulted_Loans
from dbo.BankLoans_Clean;



-- 1.5 Are there invalid dates, negative amounts, or unexpected numeric values?

-- Count suspicious numeric values
SELECT 'Negative Loan_Amount' AS CheckName, COUNT(*) AS IssueRows
FROM dbo.BankLoans_Clean
WHERE Loan_Amount < 0

UNION ALL

SELECT 'Negative Funded_Amount', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Funded_Amount < 0

UNION ALL

SELECT 'Negative Total_Pymnt', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Total_Pymnt < 0

UNION ALL

SELECT 'Negative Total_Rec_Prncp', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Total_Rec_Prncp < 0

UNION ALL

SELECT 'Negative Total_Fees', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Total_Fees < 0

UNION ALL

SELECT 'Negative Recoveries', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Recoveries < 0

UNION ALL

SELECT 'Interest rate outside 0–1', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Int_Rate < 0 OR Int_Rate > 1

UNION ALL

SELECT 'Age outside 18–100', COUNT(*)
FROM dbo.BankLoans_Clean
WHERE Age_T < 18 OR Age_T > 100;

-- Show suspicious date order

SELECT
    Account_ID,
    Dateof_Birth,
    Disbursement_Date,
    Closed_Date
FROM dbo.BankLoans_Clean
WHERE
    (Dateof_Birth > Disbursement_Date)
    OR
    (Closed_Date IS NOT NULL AND Closed_Date < Disbursement_Date);

-- 2. PORTFOLIO OVERVIEW
-- 2.1 How many loans are in the portfolio?

select 
	count(*) total_loans 
	from dbo.BankLoans_Clean;

-- 2.2 What are the total and average Loan_Amount?

select 
	sum(cast(loan_amount as decimal(18,2))) as total_loan_amount,
	avg(cast(loan_amount as decimal(18,2))) as avg_loan_amount
	from dbo.BankLoans_Clean;

-- 2.3 What is the total Funded_Amount?

select SUM(funded_amount) as Total_funded_amount
from dbo.BankLoans_Clean;


-- 2.4 How much has been received in total payments?

select sum(CAST( total_pymnt as decimal(18,2))) as total_payments
from dbo.BankLoans_Clean


-- 2.5 How much principal, interest, fees, late fees, and recoveries were recorded?

SELECT
    CAST(SUM(Total_Rec_Prncp) AS decimal(18,2)) AS Total_Principal_Amount,
    CAST(SUM(Total_Rrec_int) AS decimal(18,2)) AS Total_Interest_Amount,
    CAST(SUM(Total_Fees) AS decimal(18,2)) AS Total_Fees_Amount,
    CAST(SUM(Total_Rec_Late_fee) AS decimal(18,2)) AS Total_Late_Fees_Amount,
    CAST(SUM(Recoveries) AS decimal(18,2)) AS Total_Recoveries_Amount
FROM dbo.BankLoans_Clean;

-- 3. LOAN STATUS
-- 3.1 How many loans are in each Loan_Status?

select loan_status, count(*) as total_loans
from dbo.BankLoans_Clean
group by loan_status
order by total_loans desc;

-- 3.2 What are the total funded amount and total payments for each status?

select 
	loan_status, 
	cast(sum(funded_amount) as decimal(18,2))as funded_amount, 
	cast(sum(total_pymnt) as decimal(18,2)) as total_payments
from dbo.BankLoans_Clean
group by Loan_Status;



-- 3.3 Which statuses account for the most loans and funding?

select 
	loan_status, 
	count(*) as loan_count,
	sum(funded_amount) as total_funding
	from dbo.BankLoans_Clean
	group by Loan_Status
	order by 
	loan_count desc,
	total_funding desc;

	

-- 4. DELINQUENCY AND DEFAULT
-- 4.1 What are the overall delinquency and default rates?

select 
	count(*) as total_loans,

	sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) as delinquent_loans,

	CAST(
		100.0 * sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) / nullif(count(*),0)
	as decimal(5,2)
	) as delinquency_rate_percent,

	sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) as default_loans,


	cast(
		100.0 * sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) /nullif(count(*),0)
	as decimal (5,2)
	) as default_rate_percent
from dbo.BankLoans_Clean;


-- 4.2 Which states, branches, products, grades, and terms have the highest rates?


SELECT
    State_Name,
	Branch_Name,
	product_id,
	sub_grade,
	term,
    COUNT(*) AS Total_Loans,
    SUM(CASE
        WHEN UPPER(LTRIM(RTRIM(Is_Delinquent_Loan)))
             IN ('Y', 'YES', '1', 'TRUE')
        THEN 1 ELSE 0
    END) AS Delinquent_Loans,
    CAST(
        100.0 * SUM(CASE
            WHEN UPPER(LTRIM(RTRIM(Is_Delinquent_Loan)))
                 IN ('Y', 'YES', '1', 'TRUE')
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS decimal(5,2)
    ) AS Delinquency_Rate_Percent
FROM dbo.BankLoans_Clean
GROUP BY State_Name,
Branch_Name,
product_id,
sub_grade,
term
ORDER BY Delinquency_Rate_Percent DESC;
	

-- 4.3 Do the delinquency/default flags align with Loan_Status?


select 
	loan_status,
	count(*) as total_loans,

	sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) as delinquent_loans,

	CAST(
		100.0 * sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) / nullif(count(*),0)
	as decimal(5,2)
	) as delinquency_rate_percent,

	sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) as default_loans,


	cast(
		100.0 * sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) /nullif(count(*),0)
	as decimal (5,2)
	) as default_rate_percent
from dbo.BankLoans_Clean
group by Loan_Status;

SELECT
    Loan_Status,
    UPPER(LTRIM(RTRIM(Is_Delinquent_Loan))) AS Delinquency_Flag,
    UPPER(LTRIM(RTRIM(Is_Default_Loan))) AS Default_Flag,
    COUNT(*) AS Loan_Count
FROM dbo.BankLoans_Clean
GROUP BY
    Loan_Status,
    UPPER(LTRIM(RTRIM(Is_Delinquent_Loan))),
    UPPER(LTRIM(RTRIM(Is_Default_Loan)))
ORDER BY Loan_Status, Loan_Count DESC;
			

-- 5. TRENDS OVER TIME
-- 5.1 How many loans were disbursed each month and year?


select
	YEAR(disbursement_date) as year,
	month(disbursement_date) as month,
	count(*) as loans
from dbo.BankLoans_Clean
group by 
	year(disbursement_date),
	MONTH(disbursement_date)
ORDER BY 
	year(disbursement_date),
	MONTH(disbursement_date);



-- 5.2 How did funded amounts and payments change over time?

select 
	year(disbursement_date) as year,
	month(disbursement_date) as month,
	sum(funded_amount) as funded_amounts,
	cast(sum(total_pymnt) as decimal(18,2)) as total_payments
from dbo.BankLoans_Clean
group by 
	year(disbursement_date),
	MONTH(disbursement_date)
ORDER BY 
	year(disbursement_date),
	MONTH(disbursement_date);



-- 5.3 Which disbursement periods had the highest delinquency or default rates?

SELECT 
	year(disbursement_date) as year,
	month(disbursement_date) as month,
	COUNT(*) AS total_loan,
	CAST(
		100.0 * sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) / nullif(count(*),0)
	as decimal(5,2)
	) as delinquency_rate_percent,

	cast(
		100.0 * sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) /nullif(count(*),0)
	as decimal (5,2)
	) as default_rate_percent
from dbo.BankLoans_Clean
GROUP BY 
	year(disbursement_date),
	MONTH(disbursement_date)
ORDER BY 
	delinquency_rate_percent DESC,
	default_rate_percent DESC
;


-- 6. GEOGRAPHY AND PRODUCTS
-- 6.1 Which states, regions, and branches have the most loans and funding?


-- satate wise most loan and funding
select 
	state_name,
	count(*) as loans,
	sum(funded_amount) funding
from dbo.BankLoans_Clean
group by 
	state_name
order by
	loans desc,
	funding desc;
	
-- region wise most loan and funding

select 
	Region_Name,
	count(*) as loans,
	sum(funded_amount) funding
from dbo.BankLoans_Clean
group by 
	Region_Name
order by
	loans desc,
	funding desc;

-- branch wise most loan and funding

select 
	Branch_Name,
	count(*) as loans,
	sum(funded_amount) funding
from dbo.BankLoans_Clean
group by 
	Branch_Name
order by
	loans desc,
	funding desc;


-- 6.2 Which Product_Code and Purpose_Category values are most common?

select 
	product_code,
	count(*) as loans
from dbo.BankLoans_Clean
group by 
	Product_Code
order by 
	loans desc;

select 
	purpose_category,
	count(*) as loans
from dbo.BankLoans_Clean
group by 
	Purpose_Category
order by 
	loans desc;

-- 6.3 Which regions or products combine high funding with high risk?

select
	Region_Name,
	sum(funded_amount) as funded_amount,
	count(*) as loans,
	CAST(
		100.0 * sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) / nullif(count(*),0)
	as decimal(5,2)
	) as delinquency_rate_percent,

	cast(
		100.0 * sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) /nullif(count(*),0)
	as decimal (5,2)
	) as default_rate_percent
from dbo.BankLoans_Clean
GROUP BY
	Region_Name
order by 
	delinquency_rate_percent desc,
	default_rate_percent desc,
	funded_amount desc;

-- product _code

select
	product_code,
	sum(funded_amount) as funded_amount,
	count(*) as loans,
	CAST(
		100.0 * sum(case when UPPER(LTRIM(rtrim(Is_Delinquent_Loan)))
		IN('Y','YES','1','TRUE')
		then 1 else 0 
	end) / nullif(count(*),0)
	as decimal(5,2)
	) as delinquency_rate_percent,

	cast(
		100.0 * sum(case when upper(ltrim(rtrim(Is_Default_Loan)))
	IN('Y','YES','1','TRUE')
	then 1 else 0
end) /nullif(count(*),0)
	as decimal (5,2)
	) as default_rate_percent
from dbo.BankLoans_Clean
GROUP BY
	Product_Code
order by 
	delinquency_rate_percent desc,
	default_rate_percent desc,
	funded_amount desc;

-- 7. GRADES, INTEREST RATES, AND LOAN TERMS

-- 7.1 How do loan counts and amounts vary by Grrade and Sub_Grade?


select 
	grrade,
	sub_grade,
	count(*) as loan_count,
	sum(funded_amount) as total_funded_amount
from dbo.BankLoans_Clean
group by 
	Grrade,
	Sub_Grade
order by 
	loan_count desc,
	total_funded_amount desc;

-- 7.2 How do interest rates vary by grade?

select 
	grrade,
	count(*) as loan_count,
	cast(avg(int_rate)*100 as decimal(6,2)) as Avg_intrest_rate_percent
from dbo.BankLoans_Clean
group by
	Grrade
order by 
	Avg_intrest_rate_percent desc;

-- 7.3 How are loan term and loan amount related to repayment, delinquency, and default?

-- by loan term

SELECT
    Term,
    COUNT(*) AS Loan_Count,
    CAST(AVG(CAST(Loan_Amount AS decimal(18,2))) AS decimal(18,2))
        AS Average_Loan_Amount,
    CAST(SUM(CAST(Total_Pymnt AS decimal(18,2))) AS decimal(18,2))
        AS Total_Payments,
    CAST(
        100.0 * SUM(CAST(Total_Rec_Prncp AS decimal(18,2)))
        / NULLIF(SUM(CAST(Funded_Amount AS decimal(18,2))), 0)
        AS decimal(6,2)
    ) AS Principal_Recovery_Rate_Percent,
    CAST(
        100.0 * SUM(CASE
            WHEN UPPER(LTRIM(RTRIM(Is_Delinquent_Loan)))
                 IN ('Y', 'YES', '1', 'TRUE') THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS decimal(5,2)
    ) AS Delinquency_Rate_Percent,
    CAST(
        100.0 * SUM(CASE
            WHEN UPPER(LTRIM(RTRIM(Is_Default_Loan)))
                 IN ('Y', 'YES', '1', 'TRUE') THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS decimal(5,2)
    ) AS Default_Rate_Percent
FROM dbo.BankLoans_Clean
GROUP BY Term
ORDER BY Term;



--By loan amount band


WITH LoanBands AS (
    SELECT
        CASE
            WHEN Loan_Amount <= 5000 THEN 'Up to 5,000'
            WHEN Loan_Amount <= 10000 THEN '5,001 to 10,000'
            WHEN Loan_Amount <= 25000 THEN '10,001 to 25,000'
            ELSE 'Above 25,000'
        END AS Loan_Amount_Band,
        Loan_Amount,
        Funded_Amount,
        Total_Pymnt,
        Total_Rec_Prncp,
        Is_Delinquent_Loan,
        Is_Default_Loan
    FROM dbo.BankLoans_Clean
)
SELECT
    Loan_Amount_Band,
    COUNT(*) AS Loan_Count,
    CAST(AVG(CAST(Loan_Amount AS decimal(18,2))) AS decimal(18,2))
        AS Average_Loan_Amount,
    CAST(SUM(CAST(Total_Pymnt AS decimal(18,2))) AS decimal(18,2))
        AS Total_Payments,
    CAST(
        100.0 * SUM(CAST(Total_Rec_Prncp AS decimal(18,2)))
        / NULLIF(SUM(CAST(Funded_Amount AS decimal(18,2))), 0)
        AS decimal(6,2)
    ) AS Principal_Recovery_Rate_Percent,
    CAST(
        100.0 * SUM(CASE
            WHEN UPPER(LTRIM(RTRIM(Is_Delinquent_Loan)))
                 IN ('Y', 'YES', '1', 'TRUE') THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS decimal(5,2)
    ) AS Delinquency_Rate_Percent,
    CAST(
        100.0 * SUM(CASE
            WHEN UPPER(LTRIM(RTRIM(Is_Default_Loan)))
                 IN ('Y', 'YES', '1', 'TRUE') THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS decimal(5,2)
    ) AS Default_Rate_Percent
FROM LoanBands
GROUP BY Loan_Amount_Band
ORDER BY MIN(Loan_Amount);


-- 8. REPAYMENT PERFORMANCE
-- 8.1 How much principal and interest has been received by Loan_Status?

SELECT
    Loan_Status,
    CAST(SUM(Total_Rec_Prncp) AS decimal(18,2)) AS Principal_Received,
    CAST(SUM(Total_Rrec_int) AS decimal(18,2)) AS Interest_Received
FROM dbo.BankLoans_Clean
GROUP BY Loan_Status
ORDER BY Loan_Status;



-- 8.2 Which segments have higher recoveries, late fees, or total payments?

SELECT
    CASE
        WHEN GROUPING(Loan_Status) = 0 THEN 'Loan Status'
        WHEN GROUPING(Product_Code) = 0 THEN 'Product'
        WHEN GROUPING(State_Name) = 0 THEN 'State'
        WHEN GROUPING(Grrade) = 0 THEN 'Grade'
        WHEN GROUPING(Term) = 0 THEN 'Term'
    END AS Segment_Type,

    CASE
        WHEN GROUPING(Loan_Status) = 0 THEN CONVERT(nvarchar(100), Loan_Status)
        WHEN GROUPING(Product_Code) = 0 THEN CONVERT(nvarchar(100), Product_Code)
        WHEN GROUPING(State_Name) = 0 THEN CONVERT(nvarchar(100), State_Name)
        WHEN GROUPING(Grrade) = 0 THEN CONVERT(nvarchar(100), Grrade)
        WHEN GROUPING(Term) = 0 THEN CONVERT(nvarchar(100), Term)
    END AS Segment_Name,

    COUNT(*) AS Loan_Count,
    CAST(SUM(CAST(Recoveries AS decimal(18,2))) AS decimal(18,2)) AS Total_Recoveries,
    CAST(SUM(CAST(Total_Rec_Late_fee AS decimal(18,2))) AS decimal(18,2)) AS Total_Late_Fees,
    CAST(SUM(CAST(Total_Pymnt AS decimal(18,2))) AS decimal(18,2)) AS Total_Payments
FROM dbo.BankLoans_Clean
GROUP BY GROUPING SETS (
    (Loan_Status),
    (Product_Code),
    (State_Name),
    (Grrade),
    (Term)
)
ORDER BY Segment_Type, Total_Payments DESC;

-- 8.3 How should repayment comparisons account for loans that are still active?

SELECT
    Loan_Status,
    COUNT(*) AS Loan_Count,
    CAST(SUM(CAST(Total_Pymnt AS decimal(18,2))) AS decimal(18,2)) AS Total_Payments,
    CAST(AVG(CAST(Total_Pymnt AS decimal(18,2))) AS decimal(18,2)) AS Average_Payments_Per_Loan,
    CAST(
        100.0 * SUM(CAST(Total_Rec_Prncp AS decimal(18,2)))
        / NULLIF(SUM(CAST(Funded_Amount AS decimal(18,2))), 0)
        AS decimal(6,2)
    ) AS Principal_Recovery_Rate_Percent
FROM dbo.BankLoans_Clean
GROUP BY Loan_Status
ORDER BY Principal_Recovery_Rate_Percent DESC;