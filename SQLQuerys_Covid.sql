
--EDA for Covid Data
-- Lets take a lok at the data before

select * from Covid.dbo.CovidDeaths

select * from Covid.dbo.CovidVaccinations
-- Query1: General look at the data
SELECT 
 location,
 date,
 total_cases,
 new_cases,
 total_deaths, 
 population
FROM 
Covid.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
location,
date

-- Query2: Total Cases vs Total Deaths
-- Percentage of probability to die of Covid 
SELECT 
 location,
 date,
 total_cases,
 new_cases,
 total_deaths, 
 (total_deaths/total_cases)*100 AS DeathPercentage
FROM 
Covid.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
--location,
date DESC


--Query 3: Percentage of the Population who got Covid
SELECT
 location,
 date,
 population,
 total_cases,
 (total_cases/population)*100 AS PercentagePopulation
FROM 
Covid.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY
date DESC

--Query 4: Countries with highest infection rate compared to population
SELECT
 location,
 population,
 date,
 MAX(total_cases) AS HighestInfectionCount,
 MAX(total_cases/population)*100 AS HighPercentPopulationInfected
FROM 
Covid.dbo.CovidDeaths
WHERE location='United States'
GROUP BY 
location,population,date
ORDER BY
 HighPercentPopulationInfected DESC

 -- Query 5: Showing the Country with the highest death Count per Population
SELECT
 location,
 population,
 MAX(CAST(total_deaths AS int)) AS HighestDeathsCount,
 MAX(total_deaths/population)*100 AS HighPercentDeath
FROM 
Covid.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
location,
population
ORDER BY
HighestDeathsCount DESC
 
 
-- Query 6: Checking the data by Continent, creating a View later in Query 12 
 SELECT
 continent,
 MAX(CAST(total_deaths AS int)) AS HighestDeathsCount,
 MAX(total_cases) AS HighestInfectionCount 
FROM 
Covid.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY 
continent
ORDER BY
continent DESC

-- Query 7: Total Case, Total Deaths and Death Percentage in the world, View Created down query12
SELECT 
SUM(new_cases) as Totalcases,
SUM(CAST(new_deaths AS int)) AS Totaldeaths,
SUM(CAST(new_deaths AS int))/(SUM(new_cases))*100 AS TotalDeathPercentage
FROM 
Covid.dbo.CovidDeaths
WHERE
continent IS NOT NULL
ORDER BY
Totalcases,
Totaldeaths

--Query 8: Optional for me, Daily Total Cases, Total Deaths and Death Percentage in the world 

SELECT 
date,
SUM(new_cases) as Totalcases,
SUM(CAST(new_deaths AS int)) AS Totaldeaths,
SUM(CAST(new_deaths AS int))/(SUM(new_cases))*100 AS TotalDeathPercentage
FROM 
Covid.dbo.CovidDeaths
WHERE
continent IS NOT NULL
GROUP BY
date


-- Query 9: Join CovidDeaths with CovidVaccinations looking total Population vs Total Vaccinations
SELECT 
d.continent,
d.location,
d.date,
d.population,
CAST(v.total_vaccinations AS bigint) AS total_vac
FROM Covid.dbo.CovidDEaths d
JOIN Covid.dbo.CovidVAccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY
d.location,
d.date

--Query 10: Same as above but using new_vaccinations rolling over location
SELECT 
d.continent,
d.location,
d.date,
d.population,
v.new_vaccinations,
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location
												ORDER BY d.location,
														 d.date) AS RollTotalVac
FROM Covid.dbo.CovidDEaths d
JOIN Covid.dbo.CovidVAccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY
d.location,
d.date

-- USE CTE to be able to use the RollTotalVac, to get the population/people vaccinatednwhich is RollTotalVac
-- number of columns in the select should be the same as the number of columns in the CTE
-- the order clause should not be in the inside select

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollTotalVac)
AS
(SELECT 
d.continent,
d.location,
d.date,
d.population,
v.new_vaccinations,
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location
												ORDER BY d.location,
														 d.date) AS RollTotalVac
FROM Covid.dbo.CovidDEaths d
JOIN Covid.dbo.CovidVAccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL)


SELECT *,
(RollTotalVac/population)*100 AS PercentageVaccinatedLocation
FROM PopvsVac

-- Query 11: Same as above but using a Temp Table
-- first dropping table just in case
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
rolltotalvac numeric)

INSERT INTO PercentPopulationVaccinated
SELECT 
d.continent,
d.location,
d.date,
d.population,
v.new_vaccinations,
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location
												ORDER BY d.location,
														 d.date) AS RollTotalVac
FROM Covid.dbo.CovidDEaths d
JOIN Covid.dbo.CovidVAccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *,
(RollTotalVac/population) *100 AS TotalVaccinatedLoc
FROM PercentPopulationVaccinated

-- Query 12: Create a View for Visualiztion purposes - global numbers from query 7
CREATE VIEW VGlobalNumbers AS
SELECT
SUM(new_cases) as Totalcases,
SUM(CAST(new_deaths AS int)) AS Totaldeaths,
SUM(CAST(new_deaths AS int))/(SUM(new_cases))*100 AS TotalDeathPercentage
FROM 
Covid.dbo.CovidDeaths
WHERE
continent IS NOT NULL



-- Query 13: -tableau, Total Death Count by Continent(location), European Union is part of Europe

SELECT 
location,
SUM(CAST(new_deaths AS int)) AS Totaldeaths
FROM 
Covid.dbo.CovidDeaths
WHERE
continent IS NULL -- when continent is NULL the location is the continent
AND location NOT IN ('Upper middle income','World','European Union', 'Lower middle income', 'Low income','International', 'High Income')
GROUP BY
location
ORDER BY
TotalDeaths DESC


-- Query 14: Create View for PercentPopulationVaccinated from Query 10
CREATE VIEW VPercentPopulationVAccinated AS
SELECT 
d.continent,
d.location,
d.date,
d.population,
v.new_vaccinations,
SUM(CONVERT(bigint, v.new_vaccinations)) OVER (Partition by d.location
												ORDER BY d.location,
														 d.date) AS RollTotalVac
FROM Covid.dbo.CovidDEaths d
JOIN Covid.dbo.CovidVAccinations AS v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL


--Query 15: tableau PercentPopulationInfected 
SELECT
 location,
 population,
 MAX(total_cases) AS HighestInfectionCount,
 MAX(total_cases/population)*100 AS HighPercentPopulationInfected
FROM 
Covid.dbo.CovidDeaths
GROUP BY 
location,population
ORDER BY
 HighPercentPopulationInfected DESC
