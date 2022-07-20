/*
	COVID 19 Data Exploration
	https://ourworldindata.org/covid-deaths

	Skills used: JOINs, CTEs, Aggregate Functions, Windows Functions, Data Type Conversion
*/

SELECT *
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..covidVaxx
--ORDER BY 3,4


-- Daily death rate
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS death_rate, population
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Daily infection and death rates in the United States
SELECT location, date, total_cases, (total_cases / population)*100 AS percent_infected, total_deaths, (total_deaths / total_cases)*100 AS death_rate, population
FROM PortfolioProject..covidDeaths
WHERE location LIKE '%state%'
AND location NOT LIKE '%virgin%'
ORDER BY 1,2


-- Only daily infection rates in the United States
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..covidDeaths
WHERE location LIKE '%state%'
AND location NOT LIKE '%virgin%'
ORDER BY 1,2


-- Highest infection rates per nation
SELECT location, population, MAX(total_cases) AS total_cases, (MAX(total_cases/population)*100) AS infection_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Highest death rates per nation, calculated from the totals (cases, deaths)
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count, (MAX(cast(total_deaths as int))/MAX(total_cases)*100) AS death_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
AND location NOT LIKE 'North Korea'
GROUP BY location
ORDER BY 3 DESC


-- Total deaths per continent
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income%'
AND location NOT LIKE '% Union'
GROUP BY location
ORDER BY 2 DESC


-- Death rate per continent
SELECT location, MAX(total_cases) AS total_cases, MAX(cast(total_deaths as int)) AS total_deaths, MAX(cast(total_deaths as int)) / MAX(total_cases)*100 AS death_rate
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income%'
AND location NOT LIKE '% Union'
GROUP BY location
ORDER BY 2 DESC


-- Global daily case, deaths, and percent of deaths to cases
SELECT date, SUM(new_cases) as totalCases, SUM(cast(new_deaths as int)) AS totalDeaths, SUM(cast(new_deaths as int)) / SUM(new_cases)*100 AS deathPercent
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Global numbers
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Percentage of Population that has had atleast one COVID vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS rolling_vax
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..covidVaxx vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE to achieve same as above
WITH popvsvax (continent, location, date, population, new_vaccinations, rolling_vax)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vax
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..covidVaxx vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
)
SELECT *, rolling_vax / population * 100 AS rolling_rate
FROM popvsvax
ORDER BY 2,3


-- Using temp table to perform calculations similar to above
DROP TABLE IF EXISTS vaxx_rate
CREATE TABLE vaxx_rate (
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaxx NUMERIC,
rolling_vaxx NUMERIC
)

-- Populate table with rolling numbers
INSERT INTO vaxx_rate
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaxx
FROM PortfolioProject..covidDeaths AS dea
JOIN PortfolioProject..covidVaxx AS vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL


-- Select and calculate rolling rates
SELECT *, rolling_vaxx / population * 100
FROM vaxx_rate
ORDER BY 2,3


-- Create view for visualization
CREATE VIEW vaxx_rate_view AS
SELECT continent, location, date, population, new_vaxx, rolling_vaxx, rolling_vaxx/population*100 AS vaxx_rate
FROM vaxx_rate
WHERE continent IS NOT NULL