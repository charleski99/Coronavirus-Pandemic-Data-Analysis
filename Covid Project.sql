USE covid;

-- SELECT * 
-- FROM vaccinations
-- ORDER BY 3, 4

SELECT *
FROM deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- SELECT data to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM deaths
ORDER BY 1, 2;

-- Total cases vs Total deaths
-- Calculates likelihood of dying from contracting COVID in your country

SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 AS DeathRate
FROM deaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows percentage of population with COVID

SELECT location, date, population, total_cases, 
(total_cases/population) * 100 AS infection_rate
FROM deaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Countries with highest infection rate

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX(total_cases/population) * 100 AS infection_rate
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate DESC;

-- Showing countries with highest death count per population

SELECT location, population, MAX(total_deaths) AS TotalDeaths
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC;

-- Break down by continent

SELECT location, SUM(population) AS population, MAX(total_deaths) AS TotalDeaths
FROM deaths
WHERE continent IS NULL 
-- AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY population DESC;

-- Global

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases) *100 AS DeathRate
FROM deaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2 DESC;

-- Join Vaccinations table
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
-- ORDER BY 2,3;

SELECT *, (RollingTotalVaccinations/Population) * 100
FROM PercentVaccinated;

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