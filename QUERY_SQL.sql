USE employee_dataset;
-- DATA CLEANING 
-- 1. CREATING A BACKUP TABLE FOR CLEANING

CREATE TABLE employee_data_staging
LIKE employee_data;
INSERT INTO employee_data_staging
SELECT *
FROM employee_data;

-- 2.CHECKING FOR DUPLICATES

WITH duplicates_cte AS
(
SELECT *,ROW_NUMBER() OVER(PARTITION BY 
                            Employee_ID,First_Name,Last_Name,Age,Department_Region,Status,
                            Join_Date,Salary,Email,Phone,Performance_Score,Remote_Work) AS row_num
FROM employee_data_staging                            
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- 3.STANDARDIZING THE DATE

SELECT Join_Date
FROM employee_data_staging;

UPDATE employee_data_staging
SET Join_Date=STR_TO_DATE(Join_date,'%m/%d/%Y');

-- 4. SEPARATING DEPARTMENT AND REGION COLUMN

ALTER TABLE employee_data_staging
ADD COLUMN Department varchar(100),
ADD COLUMN Region varchar(100);

SELECT Department_Region
FROM employee_data_staging;

UPDATE employee_data_staging
SET Department=SUBSTRING_INDEX(Department_Region,'-',1),
    Region=SUBSTRING_INDEX(Department_Region,'-',-1);

ALTER TABLE employee_data_staging
DROP COLUMN Department_Region;

-- 5.CHECKING IF ALL EMAILS ARE VALID

SELECT Email
FROM employee_data_staging
WHERE Email NOT LIKE '%example.com';

-- 6.PREFIXING COUNTRY CODE TO PHONE COLUMN

SELECT Phone
FROM employee_data_staging;

UPDATE employee_data_staging
SET Phone = CONCAT('+1', Phone);

-- 7. CHANGING THE DATATYPE OF SALARY TO DECIMAL

ALTER TABLE employee_data_staging
MODIFY COLUMN Salary DECIMAL(10,2);

-- EXPLORATORY DATA ANALYSIS
-- 1. SALARY DISTRIBUTION ACROSS DIFFERENT AGE GROUPS
SELECT *
FROM employee_data_staging;

SELECT DISTINCT(Age)
FROM employee_data_staging;

SELECT Age_Group, AVG(Salary) AS Avg_Salary
FROM (
    SELECT 
        CASE 
            WHEN Age BETWEEN 25 AND 30 THEN '25-30'
            WHEN Age BETWEEN 31 AND 35 THEN '31-35'
            WHEN Age BETWEEN 36 AND 40 THEN '36-40'
            ELSE 'Other'
        END AS Age_Group,
        Salary
    FROM employee_data_staging
) Age_Salary_Group
GROUP BY Age_Group
ORDER BY Avg_Salary DESC;

-- SALARY ANALYSIS ACROSS DEPARTMENTS
 
 SELECT Department,
        AVG(Salary) AS avg_salary,
        MIN(Salary) AS min_salary,
        MAX(Salary) AS max_salary,
        COUNT(*) AS employee_count
 FROM employee_data_staging
 WHERE Salary > 0
 GROUP BY Department
 ORDER BY avg_salary DESC;
 
-- EMPLOYEE PERFORMANCE ACROSS AGE GROUPS
SELECT Age_Group, Performance_Score,COUNT(*) AS employee_count
FROM (
    SELECT 
        CASE 
            WHEN Age BETWEEN 25 AND 30 THEN '25-30'
            WHEN Age BETWEEN 31 AND 35 THEN '31-35'
            WHEN Age BETWEEN 36 AND 40 THEN '36-40'
            ELSE 'Other'
        END AS Age_Group,
        Performance_Score
    FROM employee_data_staging
) Age_Performance_Score_Group
GROUP BY Age_Group,Performance_Score
ORDER BY Performance_Score;

-- HIRING TRENDS ACROSS YEAR AND DEPARTMENT
SELECT YEAR(Join_Date) AS Year,Department,COUNT(*)
FROM employee_data_staging
GROUP BY Year,Department;

-- REMOTE WORK DISTRIBUTION ACROSS REGIONS

SELECT Region, COUNT(*) AS remote_employee_count
FROM employee_data_staging
WHERE Remote_Work ='TRUE'
GROUP BY Region
ORDER BY remote_employee_count DESC;


