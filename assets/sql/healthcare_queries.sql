-- ============================================================
-- Healthcare Operations & Revenue Cycle Analytics — SQL
-- SQL Server (T-SQL).
--
-- Unlike the Supply Chain project, this dataset arrived already
-- clean and relationally structured (9 tables, real keys, no
-- staging/dimensional-modeling step was needed) and was connected
-- to Power BI directly. So there's no "PART 1: build the star
-- schema" section here — these are analytical queries written
-- directly against the real source tables, mirroring the DAX
-- measures used across the four report pages (Executive,
-- Patients, Financial, Clinical Analytics).
--
-- Source tables: patients, providers, encounters, diagnoses,
-- procedures, lab_tests, medications, claims_and_billing, denials
--
-- A few measures (Admitted Patients, Emergency Visits, Appeal
-- Success Rate) are written from the most reasonable reading of
-- the column values available — flagged inline with a comment —
-- since the exact DAX formula text isn't something I can pull
-- out of the .pbix file directly. Easy to tweak once you confirm
-- the exact category values used in Power BI.
-- ============================================================


-- ============================================================
-- EXECUTIVE DASHBOARD
-- ============================================================

-- Headline KPIs
SELECT
    (SELECT COUNT(DISTINCT patient_id) FROM patients)                         AS Total_Patients,
    (SELECT COUNT(DISTINCT encounter_id) FROM encounters)                     AS Total_Encounters,
    (SELECT COUNT(DISTINCT encounter_id) FROM encounters
        WHERE visit_type = 'Emergency')                                       AS Emergency_Visits,
    (SELECT SUM(CASE WHEN readmitted_flag = 1 THEN 1.0 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) FROM encounters)                                AS Readmission_Rate_Pct;
GO

-- Total Encounters by department (providers.department, via provider_id)
SELECT
    p.department,
    COUNT(DISTINCT e.encounter_id) AS Total_Encounters
FROM encounters e
JOIN providers p ON p.provider_id = e.provider_id
GROUP BY p.department
ORDER BY Total_Encounters DESC;
GO

-- Total diagnoses by diagnosis description
SELECT
    d.diagnosis_description,
    COUNT(*) AS Total_Diagnosis
FROM diagnoses d
GROUP BY d.diagnosis_description
ORDER BY Total_Diagnosis DESC;
GO

-- Encounter volume over time (visit_date), for the date slicer / trend
SELECT
    DATEFROMPARTS(YEAR(visit_date), MONTH(visit_date), 1) AS Visit_Month,
    COUNT(DISTINCT encounter_id)                          AS Total_Encounters
FROM encounters
GROUP BY DATEFROMPARTS(YEAR(visit_date), MONTH(visit_date), 1)
ORDER BY Visit_Month;
GO


-- ============================================================
-- PATIENTS DASHBOARD
-- ============================================================

-- Patient KPIs
SELECT
    (SELECT COUNT(DISTINCT patient_id) FROM patients)                          AS Total_Patients,
    (SELECT COUNT(DISTINCT patient_id) FROM patients WHERE gender = 'Female')  AS Female_Patients,
    (SELECT COUNT(DISTINCT patient_id) FROM patients WHERE gender = 'Male')    AS Male_Patients,
    (SELECT AVG(CAST(age AS FLOAT)) FROM patients)                             AS Average_Age,
    -- "Admitted Patients": distinct patients with an inpatient encounter.
    -- Assumes admission_type is populated only for inpatient admissions —
    -- swap the WHERE clause if Power BI defines it differently (e.g. status = 'Admitted').
    (SELECT COUNT(DISTINCT patient_id) FROM encounters
        WHERE admission_type IS NOT NULL)                                      AS Admitted_Patients;
GO

-- Patients by age group
SELECT
    [Age Group],
    COUNT(DISTINCT patient_id) AS Total_Patients
FROM patients
GROUP BY [Age Group]
ORDER BY Total_Patients DESC;
GO

-- Patients by gender
SELECT
    gender,
    COUNT(DISTINCT patient_id) AS Total_Patients
FROM patients
GROUP BY gender
ORDER BY Total_Patients DESC;
GO

-- Patients by marital status
SELECT
    marital_status,
    COUNT(DISTINCT patient_id) AS Total_Patients
FROM patients
GROUP BY marital_status
ORDER BY Total_Patients DESC;
GO

-- Patients by ethnicity
SELECT
    ethnicity,
    COUNT(DISTINCT patient_id) AS Total_Patients
FROM patients
GROUP BY ethnicity
ORDER BY Total_Patients DESC;
GO

-- Average length of stay, overall and by department
SELECT AVG(CAST(length_of_stay AS FLOAT)) AS Avg_Length_Of_Stay
FROM encounters;
GO

SELECT
    p.department,
    AVG(CAST(e.length_of_stay AS FLOAT)) AS Avg_Length_Of_Stay
FROM encounters e
JOIN providers p ON p.provider_id = e.provider_id
GROUP BY p.department
ORDER BY Avg_Length_Of_Stay DESC;
GO

-- Readmission rate by department
SELECT
    p.department,
    SUM(CASE WHEN e.readmitted_flag = 1 THEN 1.0 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0) AS Readmission_Rate_Pct
FROM encounters e
JOIN providers p ON p.provider_id = e.provider_id
GROUP BY p.department
ORDER BY Readmission_Rate_Pct DESC;
GO


-- ============================================================
-- FINANCIAL DASHBOARD
-- ============================================================

-- Revenue cycle KPIs
SELECT
    SUM(billed_amount)                                            AS Total_Billed,
    SUM(paid_amount)                                               AS Revenue_Collected,
    SUM(billed_amount) - SUM(paid_amount)                          AS Outstanding_Balance,
    SUM(paid_amount) * 100.0 / NULLIF(SUM(billed_amount), 0)       AS Collection_Rate_Pct,
    SUM(CASE WHEN claim_status = 'Denied' THEN 1.0 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0)                              AS Denial_Rate_Pct
FROM claims_and_billing;
GO

-- Billed amount & outstanding balance by insurance provider
SELECT
    insurance_provider,
    SUM(billed_amount)                              AS Total_Billed,
    SUM(paid_amount)                                AS Total_Paid,
    SUM(billed_amount) - SUM(paid_amount)           AS Outstanding_Balance
FROM claims_and_billing
GROUP BY insurance_provider
ORDER BY Total_Billed DESC;
GO

-- Claims by status, with outstanding balance
SELECT
    claim_status,
    COUNT(*)                                        AS Claim_Count,
    SUM(billed_amount) - SUM(paid_amount)           AS Outstanding_Balance
FROM claims_and_billing
GROUP BY claim_status
ORDER BY Claim_Count DESC;
GO

-- Denied claims count and denied amount, by denial reason
SELECT
    denial_reason_description,
    COUNT(*)              AS Denied_Claims_Count,
    SUM(denied_amount)    AS Total_Denied_Amount
FROM denials
GROUP BY denial_reason_description
ORDER BY Denied_Claims_Count DESC;
GO

-- Appeal success rate: share of filed appeals with a successful outcome.
-- Assumes final_outcome holds a value like 'Overturned' / 'Approved' for
-- successful appeals — adjust the WHEN clause to match the real values.
SELECT
    SUM(CASE WHEN appeal_filed = 1 AND final_outcome IN ('Overturned', 'Approved') THEN 1.0 ELSE 0 END)
        * 100.0 / NULLIF(SUM(CASE WHEN appeal_filed = 1 THEN 1 ELSE 0 END), 0) AS Appeal_Success_Rate_Pct
FROM denials;
GO


-- ============================================================
-- CLINICAL ANALYTICS DASHBOARD
-- ============================================================

-- Clinical volume KPIs
SELECT
    (SELECT COUNT(*) FROM diagnoses)  AS Total_Diagnoses,
    (SELECT COUNT(*) FROM lab_tests)  AS Total_Lab_Tests,
    (SELECT COUNT(*) FROM procedures) AS Total_Procedures;
GO

-- Diagnoses by description (top conditions)
SELECT
    diagnosis_description,
    COUNT(*) AS Total_Diagnoses
FROM diagnoses
GROUP BY diagnosis_description
ORDER BY Total_Diagnoses DESC;
GO

-- Chronic vs. non-chronic diagnosis split
SELECT
    chronic_flag,
    COUNT(*) AS Total_Diagnoses
FROM diagnoses
GROUP BY chronic_flag;
GO

-- Lab tests by specimen type
SELECT
    specimen_type,
    COUNT(*) AS Total_Lab_Tests
FROM lab_tests
GROUP BY specimen_type
ORDER BY Total_Lab_Tests DESC;
GO

-- Most expensive procedures (sum of procedure_cost by description)
SELECT TOP 10
    procedure_description,
    COUNT(*)               AS Procedure_Count,
    SUM(procedure_cost)    AS Total_Procedure_Cost,
    AVG(procedure_cost)    AS Avg_Procedure_Cost
FROM procedures
GROUP BY procedure_description
ORDER BY Total_Procedure_Cost DESC;
GO

-- Medication cost by drug name (supporting detail, not on a report page yet)
SELECT TOP 10
    drug_name,
    COUNT(*)      AS Prescriptions,
    SUM(cost)     AS Total_Cost
FROM medications
GROUP BY drug_name
ORDER BY Total_Cost DESC;
GO
