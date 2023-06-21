/* COVID 19 DATA EXPLORATION */


-- 1. View the CovidDeaths dataset
Select *
From PortfolioProject..CovidDeaths
where continent is not null
Order by 3,4


-- 2. Select Data that to be start analysing
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
Order by 1,2


-- 3. Total deaths vs Total cases
-- 3.1 Overall global numbers showng total deaths, total cases and death rate
Select SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathRate
From PortfolioProject..CovidDeaths
where continent is not null 


-- 3.2 Showing contintents with the highest death count per population
Select continent,
	MAX(CAST(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- 3.3 Country with the highest number of total cases and deaths
Select Location, 
	MAX(CAST(total_cases as float)) as HighestInfectionRate, 
	MAX(CAST(total_deaths as float)) as HighestDeathRate
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by location
Order by HighestInfectionRate desc


-- 3.4 Shows likelihood of dying if contracted covid in Kenya
Select location, date, total_cases ,total_deaths, 
	(CAST(total_deaths as float)/CAST(total_cases as float))* 100 as PercentageDeathrate
From PortfolioProject..CovidDeaths
Where location like '%kenya%'
and continent is not null
Order by 1,2


--3.5 Evolution of covid cases and deaths in Kenya over time
Select date, total_cases, total_deaths
From PortfolioProject..CovidDeaths
Where location = 'Kenya'
and continent is not null
Order by date


--4. Total Cases vs Population

-- 4.1 Shows what percentage of population infected with Covid in Kenya
Select location, date,population, total_cases ,
	(CAST(total_cases as float)/population)* 100 as PercentageInfectionRate
From PortfolioProject..CovidDeaths
Where location like '%kenya%'
Order by 1,2


--5. View the vaccination data
Select *
From PortfolioProject..CovidVaccinations
where continent is not null
Order by 3,4


-- 6. total tests conducted vs positive rate of Kenya

--6.1 shows the total tests conducted and the rate of positive tests in the country
Select location, date, total_tests, positive_rate
From PortfolioProject..CovidVaccinations
where Location = 'Kenya'
and continent is not null
Order by 2


-- 6.2 shows the vaccinations administered, people vaccinated , people fully vaccinated and number of boosters in Kenya
Select location, date, total_vaccinations, people_vaccinated, people_fully_vaccinated, total_boosters
From PortfolioProject..CovidVaccinations
where Location = 'Kenya'
and continent is not null
Order by 2 


--7. Total population vs Vaccinations

--7.1 shows the percentage of people that are fully vaccinated
Select dea.location,dea.population, 
	MAX(vac.people_fully_vaccinated) as FullyVaccinated, 
	(MAX(CAST(vac.people_fully_vaccinated as bigint)) / dea.population)*100  as PercentageFullyVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
Where dea.continent is not null
Group by dea.location, dea.population
Order by PercentageFullyVaccinated desc


--7.2 shows percentage of population that have received boosters
Select dea.location,dea.population, 
	MAX(vac.total_boosters) as TotalBoosterShots, 
	(MAX(CAST(vac.total_boosters as bigint)) / dea.population)*100  as PercentageboosterVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
Where dea.continent is not null
Group by dea.location, dea.population
Order by PercentageboosterVaccinated desc


--7.2 shows people vaccinated in a rolling basis over time
-- using partition by clause to ensure sum of new vaccinations is calculated for each location 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	(SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date))/ 
	dea.population as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location 
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3


--7.3 create a temp table in order to calculate percentage of the Kenyan population vaccinated over time
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255), 
date datetime,
population numeric, 
new_vaccination numeric,
Rollingpeoplevaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location 
	and dea.date = vac.date
Where dea.location = 'Kenya'

Select *, (RollingPeopleVaccinated/population)*100 as PercentageVaccinated
From #PercentPopulationVaccinated


--8. Create views for visualizations in Tableau
-- 8.8 Global Numbers
Create View GlobalSummary as
Select SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathRate
From PortfolioProject..CovidDeaths
where continent is not null 
Group by 1,2


--8.9 total death count per continent
Create View DeathCount as
Select continent,
	MAX(CAST(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent


--8.1 Total deaths vs total cases per country
Create View CountrySummary as
Select Location,
	MAX(CAST(total_cases as float)) as HighestInfectionRate,
	MAX(CAST(total_deaths as float)) as HighestDeathRate
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by location



--8.2  evolution of covid over time in Kenya
Create View CovidEvolution as
Select location, date, total_cases, total_deaths
From PortfolioProject..CovidDeaths
Where location = 'Kenya'
and continent is not null


--8.3 PercentageDeathRate
Create View PercentageDeathRate as
Select location, date, total_cases ,total_deaths, 
	(CAST(total_deaths as float)/CAST(total_cases as float))* 100 as PercentageDeathrate
From PortfolioProject..CovidDeaths
Where location like '%kenya%'
and continent is not null


--8.4 percentage infection rate
Create View PercentageInfectioonRate as
Select location, date,population, total_cases , 
	(CAST(total_cases as float)/population)* 100 as PercentageInfectionRate
From PortfolioProject..CovidDeaths
Where location like '%kenya%'


--8.5 total tests vs positive rate
Create View Positiveratetests as
Select location, date, total_tests, positive_rate
From PortfolioProject..CovidVaccinations
where Location = 'Kenya'
and continent is not null


-- 8.6 percentage of people that are fully vaccinated
Create View PercentageFullyVaccinated as
Select dea.location,dea.population, 
	MAX(vac.people_fully_vaccinated) as FullyVaccinated, 
	(MAX(CAST(vac.people_fully_vaccinated as bigint)) / dea.population)*100  as PercentageFullyVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
Where dea.continent is not null
Group by dea.location, dea.population


--8.7 percentage of people that have received booster shots
Create View PercentageboosterShots as
Select dea.location,dea.population, 
	MAX(vac.total_boosters) as TotalBoosterShots, 
	(MAX(CAST(vac.total_boosters as bigint)) / dea.population)*100  as PercentageboosterVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
Where dea.continent is not null
Group by dea.location, dea.population


--8.8 Number of people vaccinated over a rolling time basis
Create View RollingPeopleVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	(SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date))/ 
	dea.population as RollingpeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location 
	and dea.date = vac.date
Where dea.continent is not null 
