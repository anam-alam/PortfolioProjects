SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;


SELECT location, date, total_cases, new_cases, total_deaths,population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Changing data types of columns since they have been imported as nvarchar

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths int;

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_cases int;

-- Looking at Total Cases vs Total Deaths


Select Location,
		date, 
		population, 
		total_cases,total_deaths, 
		(cast(total_deaths as float) / cast (total_cases as float))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where location = 'India'
AND continent IS NOT NULL
ORDER BY 2;

-- Looking at Total Cases vs Population
-- Shows what %age of population got Covid

SELECT Location,
		date, 
		population, 
		total_cases, 
		(cast(total_cases as float) / cast(population as float))*100 as percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'India'
ORDER BY 1,2;

-- Looking at Countries with the Highest Infection Rate compared to Population

SELECT location,
		population, 
		MAX(total_cases) AS highest_infection_count, 
		MAX((cast(total_cases as float) / cast(population as float)))*100 as percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location,population
ORDER BY percent_population_infected desc

-- Showing countries with Highest Death Count per Population

SELECT location,
		MAX(total_deaths) AS highest_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count desc

-- Let's Group By Continent

-- Showing continents with highest death count per population

SELECT continent,
		MAX(total_deaths) AS highest_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count desc


-- GLOBAL NUMBERS

Select  SUM(new_cases) AS total_new_cases,
		SUM(new_deaths) AS total_new_deaths,
		SUM(new_cases)/ SUM(new_deaths)*100 as global_death_percentage
From PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

-- Looking at Total Population Vs Vaccinations

SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location 
		ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE

With cte_popvsvac (continent,location,date,population,new_vaccinations, rolling_people_vaccinated) 
as
(
	SELECT dea.continent,
			dea.location, 
			dea.date, 
			dea.population,
			vac.new_vaccinations,
			SUM(cast(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location 
			ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT * , (rolling_people_vaccinated/population)*100 AS percentage_of_people_vaccinated
FROM cte_popvsvac;

-- can try for max value

-- Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric
	)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location 
		ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT * , (RollingPeopleVaccinated/population)*100 AS percentage_of_people_vaccinated
FROM #PercentPopulationVaccinated;

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		SUM(cast(vac.new_vaccinations AS bigint)) OVER (Partition by dea.location 
		ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO

SELECT * 
FROM PercentPopulationVaccinated