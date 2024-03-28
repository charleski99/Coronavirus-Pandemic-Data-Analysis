USE covid;


-- Explore data

SELECT * 
FROM vaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT *
FROM deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM deaths
ORDER BY 1, 2;

SELECT location, date, new_tests, new_vaccinations, people_fully_vaccinated, population
FROM vaccinations
ORDER BY 1, 2;



-- Total Cases vs Population (Percentage of population that contracted COVID-19)

SELECT location, date, population, total_cases, 
(total_cases/population) * 100 AS InfectionRate
FROM deaths
WHERE location = 'United States'
ORDER BY 1, 2;



-- Countries with highest Infection Rate

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX(total_cases/population) * 100 AS InfectionRate
FROM deaths
-- WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC;



-- Infection Rate vs. Fully Vaccinated People over time in the U.S.

SELECT  d.location, d.date, d.population, (d.total_cases/d.population) * 100 AS InfectionRate, v.people_fully_vaccinated
FROM deaths d
JOIN vaccinations v 
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location = 'United States';




-- Total Cases vs Total Deaths
-- Calculates likelihood of dying from contracting COVID-19 in your country/by country, 
-- Also includes percentage of COVID-related deaths per population

SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 AS FatalityRate, SUM(new_deaths)/MAX(population) *100 AS DeathRate
FROM deaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1, 2;

SELECT location, MAX(total_deaths)/MAX(total_cases) * 100 AS FatalityRate, SUM(new_deaths)/MAX(population) *100 AS DeathRate
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1, 2;



-- Total Deaths by Continent

SELECT location, SUM(new_deaths) as TotalDeaths, SUM(population) AS population
FROM deaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International') AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeaths DESC;



-- Health conditions vs. deaths by country
-- Top 3 Deaths per Million vs. Bottom 3 Deaths per Million

(SELECT v.continent, 
        v.location, 
		d.population,
        MAX(d.total_deaths) AS TotalDeaths, 
        MAX(d.total_deaths_per_million) AS TotalDeathsPerMillion, 
        (total_deaths/total_cases) * 100 AS FatalityRate, 
        v.median_age, 
        v.cardiovasc_death_rate, 
        v.male_smokers, 
        v.female_smokers, 
        v.diabetes_prevalence,
        v.gdp_per_capita,
        v.population_density,
		v.extreme_poverty
 FROM deaths d
 JOIN vaccinations v ON d.location = v.location AND d.date = v.date
 WHERE v.continent IS NOT NULL AND d.total_deaths_per_million IS NOT NULL
 GROUP BY v.continent, v.location
 ORDER BY TotalDeathsPerMillion DESC
 LIMIT 3)

UNION ALL

(SELECT v.continent, 
        v.location, 
        d.population,
        MAX(d.total_deaths) AS TotalDeaths, 
        MAX(d.total_deaths_per_million) AS TotalDeathsPerMillion, 
        (total_deaths/total_cases) * 100 AS FatalityRate, 
        v.median_age, 
        v.cardiovasc_death_rate, 
        v.male_smokers, 
        v.female_smokers, 
        v.diabetes_prevalence,
        v.gdp_per_capita,
        v.population_density,
        v.extreme_poverty
 FROM deaths d
 JOIN vaccinations v ON d.location = v.location AND d.date = v.date
 WHERE v.continent IS NOT NULL AND d.total_deaths_per_million IS NOT NULL 
 GROUP BY v.continent, v.location
 ORDER BY TotalDeathsPerMillion ASC
 LIMIT 3);




-- World vaccination status over time
SELECT date, SUM(people_fully_vaccinated)/SUM(population) AS FullVaccinationRate
FROM vaccinations
WHERE continent IS NULL
GROUP BY date;



-- Vaccines administered 
-- Fatality Rate vs. Vaccination Rate

SELECT d.location, d.population, d.date, SUM(d.new_cases) AS total_cases, SUM(d.new_deaths) AS total_deaths, 
SUM(d.new_deaths)/SUM(d.new_cases) *100 AS FatalityRate, MAX(v.people_fully_vaccinated) AS FullyVaccinated, MAX(v.people_fully_vaccinated)/MAX(v.population) *100 AS FullVaccinationRate
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.iso_code = 'USA' AND d.new_deaths <> 0
GROUP BY d.location, d.population, d.date;



-- Total population vs. vaccinations
-- With CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingTotalVaccinations)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (partition by d.location ORDER BY d.location, d.date) 
AS RollingTotalVaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
-- ORDER BY 2,3;
)
SELECT *, (RollingTotalVaccinations/Population) * 100
FROM PopVsVac;



-- Temp Table

CREATE TABLE PercentVaccinated
(
Continent NVARCHAR(50),
Location NVARCHAR(50),
Date DATE,
Population BIGINT,
New_vaccinations INT,
RollingTotalVaccinations INT
);
INSERT INTO PercentVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (partition by d.location ORDER BY d.location, d.date) 
AS RollingTotalVaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;



-- Views

CREATE VIEW PercentPopVaccinated AS 
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (partition by d.location ORDER BY d.location, d.date) 
AS RollingTotalVaccinations
FROM deaths d
JOIN vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT * FROM PercentPopVaccinated