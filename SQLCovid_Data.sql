-- Getting a look into the death data
SELECT *
FROM	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 
	3,4

-- 
-- select *
-- from	Covid_Data..Covid_Vaccinations
-- order by 3,4

-- Select the data to be used
SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 
	1,2


-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract Covid in India
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_percentage
FROM
	Covid_Data..Covid_Deaths
WHERE
	location LIKE '%India%'
	AND continent IS NOT NULL
ORDER BY 
	1,2


-- Total Cases vs Population
-- Shows what percentage of the population is infected
SELECT
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS infection_percentage
FROM
	Covid_Data..Covid_Deaths
WHERE
	location LIKE '%Iraq%'
	AND continent IS NOT NULL
ORDER BY 
	1,2
	
-- Countries with Highest Infection Rate compared to Population
SELECT
	location,
	MAX(population) AS total_population,
	MAX(total_cases) AS maximum_cases ,
	(max(total_cases)/max(population))*100 AS infection_percentage
FROM
	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	infection_percentage DESC

-- Countries with Highest Death Count per Population
SELECT
	location,
	MAX(total_deaths) AS max_deaths	
FROM
	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY
	location
ORDER BY 
	max_deaths DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
SELECT
	continent,
	MAX(total_deaths) AS max_deaths
FROM
	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	max_deaths DESC

-- Global Numbers

SELECT
	date,
	SUM(new_cases) AS total_new_cases,
	SUM(new_deaths) AS total_new_deaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM
	Covid_Data..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY
	date
ORDER BY
	date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccination
FROM 
	Covid_Data..Covid_Deaths dea
JOIN
	Covid_Data..Covid_Vaccinations vac
	ON
		dea.location = vac.location
		AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 
	2, 3

-- Using CTE with the previous query to find the percentage of population that is vaccinated
	
WITH pop_vac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
AS
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccination
FROM 
	Covid_Data..Covid_Deaths dea
JOIN
	Covid_Data..Covid_Vaccinations vac
	ON
		dea.location = vac.location
		AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 
--	2, 3
)

SELECT 
	*,
	(cumulative_vaccinations/population)*100 AS vaccination_percentage
FROM pop_vac

-- Vaccination percentage per country
-- 200% vaccination signifies both doses have been administered
-- Using TEMP Tables with CTE

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population FLOAT,
	new_vaccination FLOAT,
	cumulative_vaccination FLOAT
)

INSERT INTO #percent_population_vaccinated
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccination
FROM 
	Covid_Data..Covid_Deaths dea
JOIN
	Covid_Data..Covid_Vaccinations vac
	ON
		dea.location = vac.location
		AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 
--	2, 3

WITH loc_vac (continent, location, population, vaccination)
AS
(
SELECT
	continent,
	location,
	MAX(population) AS total_population,
	MAX(cumulative_vaccination) AS total_vaccination
FROM #percent_population_vaccinated
GROUP BY
	continent, location, cumulative_vaccination
)

SELECT
	continent,
	location,
	MAX(population) AS total_population,
	MAX(vaccination) AS total_vaccination,
	(MAX(vaccination)/(MAX(population)))*100 AS vaccination_percent
FROM
	loc_vac
GROUP BY
	continent, location
ORDER BY
	1, 2

GO

-- Create and store views to be use for visualisations

CREATE VIEW 
	percent_population_vaccinated AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccination
FROM 
	Covid_Data..Covid_Deaths dea
JOIN
	Covid_Data..Covid_Vaccinations vac
	ON
		dea.location = vac.location
		AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 
--	2, 3

GO

SELECT
	*
FROM	percent_population_vaccinated