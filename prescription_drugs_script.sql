SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdoses;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;

--1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
	
SELECT MAX(total_claim_count) AS total_claim_count, npi
FROM prescription
GROUP BY npi
ORDER BY MAX(total_claim_count) DESC;
		-- NPI 1912011792 	total_number_claims 4538

--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
--       specialty_description, and the total number of claims.
	   
SELECT  pr.nppes_provider_first_name,
		pr.nppes_provider_last_org_name,
		pr.specialty_description,
		MAX(pn.total_claim_count) AS total_claims
FROM prescription AS pn LEFT JOIN prescriber AS pr
	ON pn.npi = pr.npi
GROUP BY pr.nppes_provider_first_name, pr.nppes_provider_last_org_name, pr.specialty_description
ORDER BY MAX(total_claim_count) DESC;


--2. 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?
	
SELECT SUM(pn.total_claim_count) AS total_count,
		pr.specialty_description
FROM prescription AS pn
	INNER JOIN prescriber AS pr
	ON pn.npi = pr.npi
GROUP BY pr.specialty_description
ORDER BY SUM(pn.total_claim_count) DESC;
	-- Family Practice		Total Count: 9752347
	
	
--    b. Which specialty had the most total number of claims for opioids?
	
SELECT SUM(pn.total_claim_count) AS total_count,
		pr.specialty_description,
		d.opioid_drug_flag
FROM prescription AS pn
	LEFT JOIN prescriber AS pr
	ON pn.npi = pr.npi
		LEFT JOIN drug AS d
		ON pn.drug_name=d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY DISTINCT pr.specialty_description, d.opioid_drug_flag
ORDER BY SUM(pn.total_claim_count) DESC;
		-- Nurse Practitioner with 900845

--    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!*
--	   For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--3. 
--    a. Which drug (generic_name) had the highest total drug cost?
	
SELECT SUM(pn.total_drug_cost) AS highest_drug_cost, d.generic_name
FROM prescription AS pn
		LEFT JOIN drug AS d
		ON pn.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY SUM(pn.total_drug_cost) DESC;
		-- Insulin Glargine,HUM.REC.ANLOG


--    b. Which drug (generic_name) has the hightest total cost per day?
--	**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT ROUND(pn.total_drug_cost/pn.total_day_supply, 2) AS highest_cost_per_day, d.generic_name
FROM prescription AS pn
		LEFT JOIN drug AS d
		ON pn.drug_name = d.drug_name
GROUP BY d.generic_name, highest_cost_per_day
ORDER BY highest_cost_per_day DESC;
		-- IMMUN GLOB G(IGG)/GLY/IGA OV50 		7141.11


--4. 
--    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y',
--	   says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
	   
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug;

--    b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
--	   Hint: Format the total costs as MONEY for easier comparision.
	   
SELECT SUM(pn.total_drug_cost::MONEY),
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' END,
		CASE WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' END
FROM drug AS d
	LEFT JOIN prescription AS pn
	USING (drug_name)
GROUP BY d.opioid_drug_flag, d.antibiotic_drug_flag;
		-- Opioid = $105,080,626.37
		-- Antibiotic = 38,435,121.26
	   
--5. 
--    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
	
SELECT COUNT(DISTINCT cbsa) AS cbsa_tn
FROM cbsa AS c
	FULL JOIN fips_county AS f
	ON c.fipscounty = f.fipscounty
WHERE f.state = 'TN';
		-- 10
		
		
--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
	
SELECT SUM(p.population) AS total_pop, c.cbsaname 
FROM cbsa AS C
	FULL JOIN population AS p
	USING (fipscounty)
WHERE p.population IS NOT NULL
GROUP BY DISTINCT c.cbsa, c.cbsaname;
		-- SMALLEST POPULATION = Knoxville, TN
		-- LARGEST POPULATION = NULL?


--    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
	
SELECT f.county, c.fipscounty, MAX(population)
FROM fips_county AS f
	LEFT JOIN cbsa AS c
	ON f.fipscounty = c.fipscounty
		INNER JOIN population AS p
		ON f.fipscounty = p.fipscounty
--included null values to sort out unreported counties
WHERE c.fipscounty IS NULL
GROUP BY f.county, c.fipscounty
ORDER BY MAX(population) DESC;
		-- SEVIER 95523


--6. 
--   a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
	
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;


--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
	
SELECT p.drug_name, p.total_claim_count, opioid_drug_flag
FROM prescription AS p
	LEFT JOIN drug AS d
	ON p.drug_name = d.drug_name
WHERE total_claim_count >= 3000
	AND opioid_drug_flag = 'Y'
ORDER BY p.total_claim_count DESC;

--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
	
SELECT p.drug_name,
	    p.total_claim_count,
		opioid_drug_flag,
		nppes_provider_last_org_name,
		nppes_provider_first_name
FROM prescription AS p
	LEFT JOIN drug AS d
	ON p.drug_name = d.drug_name
		LEFT JOIN prescriber AS pr
		ON p.npi = pr.npi
WHERE total_claim_count >= 3000
	AND opioid_drug_flag = 'Y'
ORDER BY p.total_claim_count DESC;	

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
--   **Hint:** The results from all 3 parts will have 637 rows.

--    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment')
--	   in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
--	   **Warning:** Double-check your query before running it.
--	   You will only need to use the prescriber and drug tables since you dont need the claims numbers yet.
	   
		
SELECT npi, drug_name
FROM prescriber AS pr
		CROSS JOIN drug AS d
WHERE specialty_description ILIKE 'Pain%'
		AND nppes_provider_city ILIKE '%NASH%'
		AND opioid_drug_flag = 'Y';

		
		
--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims.
--	   You should report the npi, the drug name, and the number of claims (total_claim_count).
	   
SELECT pr.npi, d.drug_name, COALESCE(total_claim_count, 0) 
FROM prescriber AS pr
		CROSS JOIN drug AS d
			LEFT JOIN prescription AS pn
			ON pr.npi = pn.npi AND pn.drug_name = d.drug_name
WHERE specialty_description ILIKE 'Pain Management'
		AND nppes_provider_city ILIKE 'NASHVILLE'
		AND opioid_drug_flag = 'Y';

 

    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
	
	
--BONUS
--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT pr.npi) - COUNT(DISTINCT pn.npi) AS npi_diff
FROM prescriber AS pr FULL JOIN prescription AS pn USING(npi);
		--4458
--2.
--    a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
	
SELECT d.generic_name, specialty_description, total_claim_count
FROM prescriber AS pr LEFT JOIN prescription AS pn USING(npi)
		LEFT JOIN drug AS d ON pn.drug_name = d.drug_name
WHERE pr.specialty_description = 'Family Practice'
		AND d.generic_name IS NOT NULL
		AND total_claim_count IS NOT NULL
GROUP BY d.generic_name, specialty_description, total_claim_count
ORDER BY total_claim_count DESC
LIMIT 5;

    b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
	
SELECT d.generic_name, specialty_description, total_claim_count
FROM prescriber AS pr LEFT JOIN prescription AS pn USING(npi)
		LEFT JOIN drug AS d ON pn.drug_name = d.drug_name
WHERE pr.specialty_description = 'Cardiology'
		AND d.generic_name IS NOT NULL
		AND total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC
LIMIT 5;

    c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists?
	   Combine what you did for parts a and b into a single query to answer this question.
	   

3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs.
	   Report the npi, the total number of claims, and include a column showing the city.
	   
SELECT DISTINCT pr.npi, SUM(pn.total_claim_count) AS claims, pr.nppes_provider_city	   
FROM prescription AS pn LEFT JOIN prescriber AS pr USING(npi)
WHERE pr.nppes_provider_city = 'NASHVILLE'
GROUP BY DISTINCT pr.npi, pr.nppes_provider_city
ORDER BY claims DESC;
    
    b. Now, report the same for Memphis.
	
SELECT DISTINCT pr.npi, SUM(pn.total_claim_count) AS claims, pr.nppes_provider_city	   
FROM prescription AS pn LEFT JOIN prescriber AS pr USING(npi)
WHERE pr.nppes_provider_city = 'MEMPHIS'
GROUP BY DISTINCT pr.npi, pr.nppes_provider_city
ORDER BY claims DESC;

    c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
	
SELECT DISTINCT pr.npi, SUM(pn.total_claim_count) AS claims, pr.nppes_provider_city	   
FROM prescription AS pn LEFT JOIN prescriber AS pr USING(npi)
WHERE pr.nppes_provider_city IN ('MEMPHIS', 'NASHVILLE', 'KNOXVILLE', 'CHATTANOOGA')
GROUP BY DISTINCT pr.npi, pr.nppes_provider_city
ORDER BY claims DESC;


4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.


5.
    a. Write a query that finds the total population of Tennessee.
    
    b. Build off of the query that you wrote in part a to write a query that returns for each county that countys name,
	   its population, and the percentage of the total population of Tennessee that is contained in that county.

