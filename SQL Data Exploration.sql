--data is pulled from https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqbG9DRVZjZGJmSndzQVlmcV9Dc2wyWnVrWHFrQXxBQ3Jtc0tsRU9RM2hnYTNiVjh2WFozd0tfWE9mcnNLM1gzRUFFX0dnaGZBbEh4UDNJaHhpbGc5aUdENmVWMDV0SnhIdHhpVkx4Z3JjLUJicnBjNU53YXduZXJBVTZ4c0l4aXpPak51UTIyWVUwMGZoREp5eG95NA&q=https%3A%2F%2Fourworldindata.org%2Fcovid-deaths&v=qfyynHBFOsM

--Data that will be used
SELECT location, date, total_cases, new_cases, total_deaths, population
from COVID_portfolio_project..COVIDDeaths
where continent is not null
order by 1, 2

-- Looking at Total Cases v. Total Deaths
-- Shows likelihood of dying if COVID-19 is contracted in United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM COVID_portfolio_project..COVIDDeaths
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2

-- Looking at Total Cases v. Population
-- Shows Percentate of population infected with COVID-19
SELECT location, date, population, total_cases, (total_cases/population)*100 as Percent_of_Population_Infected
FROM COVID_portfolio_project..COVIDDeaths
where continent is not null
--WHERE location like '%states%'
ORDER BY 1,2

--Looking at Countries with the Highest Infection Rates Compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as Percent_of_Population_Infected
FROM COVID_portfolio_project..COVIDDeaths
where continent is not null
GROUP BY location, population
ORDER BY Percent_of_Population_Infected desc

-- Showing Countries with the Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM COVID_portfolio_project..COVIDDeaths
where continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

-- Breakdown by Continent
-- Showing Continents with the Highest Death Count
SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM COVID_portfolio_project..COVIDDeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Global Number of COVID Cases
SELECT sum(new_cases) as Total_Cases,SUM(cast(new_deaths as bigint)) as Total_Deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
FROM COVID_portfolio_project..COVIDDeaths
where continent is not null
ORDER BY 1,2

-- Looking at Total populaton vs Vacination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
	   --(RollingVaccinationCount/population)*100
from COVID_portfolio_project..COVIDDeaths dea
join COVID_portfolio_project..COVIDVaccinations vac
	on dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3


--Using CTE to perform calculation in previous query

WITH PopvsVac (continent, location, date, population,New_Vaccinations, RollingVaccinationCount)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
	   --(RollingVaccinationCount/population)*100
from COVID_portfolio_project..COVIDDeaths dea
join COVID_portfolio_project..COVIDVaccinations vac
	on dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingVaccinationCount/population)*100 as RollingPercentageVaccinated
from PopvsVac
order by 2,3

-- Using Temp Table to perfrom calculation in previous query

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinationCount numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
	   --(RollingVaccinationCount/population)*100
from COVID_portfolio_project..COVIDDeaths dea
join COVID_portfolio_project..COVIDVaccinations vac
	on dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3

SELECT *, (RollingVaccinationCount/Population)*100 as RollingPercentageVaccinated
from #PercentPopulationVaccinated
order by 2,3

-- Creating View for Visualizations

create view PercentageofPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
	   --(RollingVaccinationCount/population)*100
from COVID_portfolio_project..COVIDDeaths dea
join COVID_portfolio_project..COVIDVaccinations vac
	on dea.location = vac.location
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentageofPopulationVaccinated

