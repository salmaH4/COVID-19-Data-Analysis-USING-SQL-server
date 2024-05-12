
-- -------------------------------------------------------------------------------------------------
-- ---------------------------------- EDA project for COVID 19 -------------------------------------

-- using JOINS, CTE, VIEW, TEMP TABLES, WINDOW Functions, Aggregate Functions, Converting Data Types
-- -------------------------------------------------------------------------------------------------


-- Exploring CovidDeaths table
select *
from PortfolioProject..CovidDeaths
where continent is not null



-- 1) what is the Mortality Rate in each conuntry by date?
-- (MORTALITY RATE = total deaths / population) 
select 
	continent, 
	location, 
	date, 
	COALESCE(total_deaths,0) as total_deaths, 
	total_cases, 
	(convert(int, COALESCE(total_deaths,0))/population)*100 as MortalityRate
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2,3


-- 2) which countries has the Highest deaths count?
select 
	continent,
	MAX(cast(total_deaths as int)) as HighestDeaths_Count
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by HighestDeaths_Count desc


-- 3) which countries has the Highest Mortality Rate?
select 
	continent,
	location,
	population,
	MAX(cast(total_deaths as int)) as Highest_Deaths_Count,
	MAX(cast(total_deaths as int)/population) as Highest_MortalityRate
from PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, population
order by Highest_MortalityRate desc


-- 4)What is the case fatality rate by location and date?
-- (CASE FATALITY RATE or CFR = total deaths / total cases)
select 
	continent, 
	location, 
	date, 
	COALESCE(total_deaths,0) as total_deaths, 
	total_cases, 
	(convert(int, COALESCE(total_deaths,0))/total_cases)*100 as CFR
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2,3


-- 5) which countries has the highest infection rate?
select 
	continent,
	location,
	population,
	MAX(total_cases) as HighestInfection_Count,
	MAX((total_cases/population))*100 as HighestInfectionRate
from PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, population
order by Percent_Infectedpop desc


-- 6) what are the global cases and deaths?
Select 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


-- 7) what is the cumulative sum of new vaccinations for each location?
-- -------------- using window function and joining 2 tables ---------------
select
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) 
		over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on	d.location = v.location 
	and d.date = v.date
where d.continent is not null
order by 2, 3


-- 8) what is the percentage of rolling people vaccinated across each population?
-- ------------------------------ using CTE --------------------------------
with pop_vs_vacc (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
	select
		d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		sum(cast(v.new_vaccinations as int)) 
			over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
	from PortfolioProject..CovidDeaths as d
	join PortfolioProject..CovidVaccinations as v
		on	d.location = v.location 
		and d.date = v.date
	where d.continent is not null
	)
select 
	*, 
	(RollingPeopleVaccinated / population) *100 as percent_RollingPeopleVacc
from pop_vs_vacc


-- ---------------------------- using TEMP TABLE ---------------------------
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated 
select
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) 
		over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on	d.location = v.location 
	and d.date = v.date
where d.continent is not null


select 
	*, 
	(RollingPeopleVaccinated/population)*100 as percent_RollingPeopleVacc
from #PercentPopulationVaccinated


-- -----------------creating VIEWs to store data for later visualizations--------------
CREATE VIEW MortalityRate AS
select 
	continent, 
	location, 
	date, 
	COALESCE(total_deaths,0) as total_deaths, 
	total_cases, 
	(convert(int, COALESCE(total_deaths,0))/population)*100 as MortalityRate
from PortfolioProject..CovidDeaths
where continent is not null


CREATE VIEW DeathsContinent_Count AS
select 
	continent,
	MAX(cast(total_deaths as int)) as HighestDeaths_Count
from PortfolioProject..CovidDeaths
where continent is not null
group by continent


CREATE VIEW CFR AS
select 
	continent, 
	location, 
	date, 
	COALESCE(total_deaths,0) as total_deaths, 
	total_cases, 
	(convert(int, COALESCE(total_deaths,0))/total_cases)*100 as CFR
from PortfolioProject..CovidDeaths
where continent is not null


CREATE VIEW InfectionRate AS
select 
	continent,
	location,
	population,
	MAX(total_cases) as HighestInfection_Count,
	MAX((total_cases/population))*100 as HighestInfectionRate
from PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, population


CREATE VIEW GlobalCases AS
Select 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 


CREATE VIEW RollingPeopleVacc AS
select
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) 
		over (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths as d
join PortfolioProject..CovidVaccinations as v
	on	d.location = v.location 
	and d.date = v.date
where d.continent is not null