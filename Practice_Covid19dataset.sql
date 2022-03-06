SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--Select data that we are going to use "location","date","population","total cases","new case","total deaths"
SELECT location,date,population,total_cases,new_cases,total_deaths
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Show total cases vs total deaths - death percentage 
SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- show likelihood death percent covid in Vietnam
SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Vietnam%'
and continent is not null
ORDER BY 1,2

--looking at percentage of total cases vs population
SELECT location, date, population, total_cases, (total_cases/population)*100 as percentpopulationinfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--looking at the country with the highest infection rate compared to population 
SELECT location, MAX(total_cases) as highestpopulationcount, MAX((total_cases/population)*100) AS Highestpercentpopulationrate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY Highestpercentpopulationrate

-- looking at country with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) as highestdeathcount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY highestdeathcount DESC

-- break down by continent
SELECT continent, MAX(CAST(total_deaths AS int)) as highestdeathcount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY highestdeathcount DESC

--- show numbers of cases, deaths, and death percentage per date
SELECT date, SUM(new_cases) as totalcases, SUM(CAST(new_deaths as INT)) AS totaldeaths
, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as deathpercentperday
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY date

--- show global cases, deaths, deaths percentage
SELECT SUM(new_cases) as globalcases, SUM(CAST(new_deaths as INT)) as globaldeath, 
(SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as globaldeathpercent
FROM PortfolioProject..CovidDeaths
WHERE continent is not null

---- Vaccinate data
SELECT *
FROM PortfolioProject..CovidVacinations

--- join data deaths on vaccinations based on location and date
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- show the total vaccinates over location
SELECT dea.location,dea.population, dea.date,vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as rollingppvaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY dea.location,dea.date

--use CTE to calculate in partition by from the previous query
----Calculate the percentage of population has received at least once vaccnate accross location by date
WITH popvsvac (date,continent,location,population,new_vaccinations,rollingppvaccine)
AS (
	SELECT dea.date,dea.continent,dea.location,dea.population,vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as rollingppvaccine
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVacinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
)
SELECT *,(rollingppvaccine/population)*100 as rollingppvaccinepercent
FROM popvsvac

--using temp table to perform calculation on partition by in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingppvaccine numeric
)
Insert into #PercentPopulationVaccinated
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as rollingppvaccine
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVacinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
SELECT *,(rollingppvaccine/population)*100 AS rollingppvaccinepercent
FROM #PercentPopulationVaccinated

--create view to store the data for later visualizations
Create View percentpopulationvaccinated
AS
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as rollingppvacine
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVacinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null;
