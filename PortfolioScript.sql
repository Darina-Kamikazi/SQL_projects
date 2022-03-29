/* 
CREATED BY: Darina Kamikazi
CREATED ON : March 27,2022
PURPOSE: This script imports, cleans and analyzes Covid-related databases.
SKILLS USED: Joins, CTEs, Temp Tables, Windows Functions, Aggregate functions, Creating Views, Converting Data types
*/

SELECT *
FROM COVID_Deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

--Selecting the data I will be starting with --
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID_Deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;


-- LET'S FILTER BY COUNTRY


-- Total Cases Vs. Total Deaths
-- Shows the Likelihood of dying if you contract COVID-19 in your country.

SELECT  location, date, total_cases, total_deaths, (total_deaths / total_cases)* 100 AS "Fatality_rate"
FROM COVID_Deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- eg: let's focus on the United States 
-- U.S Total Cases Vs. Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)* 100 AS "Fatality_rate"
FROM COVID_Deaths
WHERE location like '%states%' 
AND continent IS NOT NULL 
ORDER BY 1,2

-- Total Cases Vs. Population 
-- Shows what percentage of population contracted COVID-19(i.e Prevalence rate)

SELECT  location, date,population, total_cases, (total_cases / population)* 100 AS "Prevalence_rate"
FROM COVID_Deaths
AND continent IS NOT NULL 
ORDER BY 1,2

-- Countries With Highest Infection Rate compared to Population

SELECT  location,population, MAX(total_cases) AS "HighestInfectionCount", MAX((total_cases / population)) * 100 AS "Highest_Prevalence_rate"
FROM COVID_Deaths
WHERE continent IS NOT NULL 
GROUP BY location,population
ORDER BY Highest_Prevalence_rate DESC
-- Faeroe Islands and Denmark have the highest prevalence rates where 70.6% and 51.7% of their respective population have contracted COVID-19 at one point.


-- Countries with Highest Death Count per Population

SELECT  location, MAX(total_deaths) AS "TotalDeathCount"
FROM COVID_Deaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC
-- The United States has the highest COVID-19 death count 


--- LET'S FILTER BY CONTINENT


-- Showing the continents with the highest death count per population
SELECT  location, MAX(total_deaths) AS "TotalDeathCount"
FROM COVID_Deaths
WHERE continent IS  NULL AND location IN ('Europe','North America','South America','Asia','Oceania','Africa')
GROUP BY location
ORDER BY TotalDeathCount DESC
-- Europe has the highest COVID_ 19 death count

-- Total Cases Vs. Total Deaths per continent
-- Shows the Likelihood of dying if you contract COVID-19 on each continent.
SELECT  continent, date, total_cases, total_deaths, (total_deaths / total_cases)* 100 AS "Fatality_rate"
FROM COVID_Deaths
WHERE continent IS NOT NULL 
ORDER BY Fatality_rate DESC,continent DESC

-- Highest Infection rate Vs. Population per continent

SELECT  continent,population, MAX(total_cases) AS "Cont_HighestInfectionCount", MAX((total_cases / population)) * 100 AS "Continent_Prevalence_rate"
FROM COVID_Deaths
WHERE continent IS NOT NULL 
GROUP BY continent,population
ORDER BY Continent_Prevalence_rate DESC


-- LOOKING AT GLOBAL NUMBERS 

--Highest Daily Death Count Globally 
SELECT date, MAX(total_deaths) AS "Highest_Daily_Global_Death_Count"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'
GROUP BY date,location
order by 2 DESC

-- Overall Highest Global Death Count
SELECT location, MAX(total_deaths) AS "Total_Global_Death_Count"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'
GROUP BY location

-- Highest Daily Total Global Cases Vs. Population 
SELECT  date, MAX(total_cases) AS "Highest_Daily_Global_Infection_Count", MAX((total_cases / population)) * 100 AS "Global_Daily_Prevalence_rate"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'
GROUP BY date,location
order by 2 DESC

-- Overall Highest Total Global Cases Vs. Population 
SELECT  location, MAX(total_cases) AS "Highest_Global_Infection_Count", MAX((total_cases / population)) * 100 AS "Global_Prevalence_rate"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'
GROUP BY location

-- Daily Global Fatality Rate (the likelihood of dying if you contract COVID-19)
SELECT date, total_cases, total_deaths, (total_deaths / total_cases)* 100 AS "Global_Fatality_rate"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'
ORDER BY 1

-- Overall Highest Global Fatality Rate. 
SELECT MAX(total_cases) AS 'Highest_Global_Cases', MAX(total_deaths) AS 'Highest_Global_Deaths', MAX((total_deaths / total_cases))* 100 
AS "Global_Fatality_rate"
FROM COVID_Deaths
WHERE continent IS  NULL AND location = 'World'

-- Adding  data from the Vaccination table
SELECT * 
FROM COVID_Deaths as cd
JOIN COVID_Vaccinations as cv
    ON cd.location = cv.LOCATION
    AND cd.date = cv.date

-- Total Population Vs. Vaccinations
-- Shows Percentage of Population that has received at least one Covid-19 vaccine

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM (CONVERT(float, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS 'RollingVaccinatedPeople'
FROM COVID_Deaths as cd
JOIN COVID_Vaccinations as cv
    ON cd.location = cv.LOCATION
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3
-- Using CTE to Perform Calculations on Partition By in previous query 

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations,RollingVaccinatedPeople)
AS 
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM (CONVERT(float, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS 'RollingVaccinatedPeople'
FROM COVID_Deaths as cd
JOIN COVID_Vaccinations as cv
    ON cd.location = cv.LOCATION
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT * ,  (RollingVaccinatedPeople / Population) * 100 
FROM PopvsVac

-- Using Temp Table to Perform Calculations on Partition By in previous query.
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM (CONVERT(float, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS 'RollingVaccinatedPeople'
FROM COVID_Deaths as cd
JOIN COVID_Vaccinations as cv
    ON cd.location = cv.LOCATION 
    AND cd.date = cv.date

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated




-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
-- View created from the gradually increasing percentage of people vaccinated per country
CREATE VIEW PercentPopulationVaccinated AS 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM (CONVERT(float, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date)
AS 'RollingVaccinatedPeople'
FROM COVID_Deaths as cd
JOIN COVID_Vaccinations as cv
    ON cd.location = cv.LOCATION
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL


