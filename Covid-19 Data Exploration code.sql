SELECT *
FROM PortfolioProject..CovidDeaths$
ORDER BY location, date;

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY location, date;


-- 1. Select the data that I'm going to be using
SELECT
	location
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM PortfolioProject.dbo.CovidDeaths$
ORDER BY location, date;



-- 2. Look at the Total Covid-19 Cases versus Total Covid-19 Deaths in the United States
--    shows the likelihood of death if someone contracts Covid-19 in the US
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS percentage_dead
FROM PortfolioProject..CovidDeaths$
WHERE location = 'United States'
ORDER BY location, date;



-- 3. Looking at the Total Covid-19 Cases per capita for the United States
--    shows the percentage of the US population that has contracted Covid-19 over time
SELECT
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths$
WHERE location = 'United States'



-- 4. Which location has the highest Covid-19 infection rate per capita?
--    shows the percentages of the population infected for each location's max number of cases
SELECT
	continent, location, population,
	MAX(total_cases) AS Highest_Count_Infected,
	MAX((total_cases)/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent, location, population
ORDER BY percent_infected DESC;
-- ANSWER: The Faeroe Islands have the highest Covid-19 infection rate per capita at 48.9%



-- 5. Which three locations have the highest Covid-19 infection rate per capita?
SELECT TOP 3
	continent,
	location,
	population,
	MAX(total_cases) AS MAXinfected_count,
	MAX((total_cases)/population)*100 AS percent_infected
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent, location, population
ORDER BY percent_infected DESC;
-- ANSWER: The Faroe Islands (48.9%), Andorra (47.3%), and Gibraltar (40.5%) all have Covid-19 infection rates of 40%+ per capita!



-- 6. Which location has the highest Covid-19 Death Count per capita?
SELECT
	continent,
	location,
	MAX(CAST(total_deaths AS INT)) AS highest_death_count
--    change datatype of total_deaths from varchar to integer
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent, location
ORDER BY highest_death_count DESC;
--    As currently constructed, this query includes data that should not be included (location = Asia, Upper Middle Income, etc.)
--    TO FIX: WHERE continent is not NULL -> this will exclude observations that represent entire continents or nonlocations
SELECT
	continent,
	location,
	MAX(CAST(total_deaths AS INT)) AS highest_death_count
--    change datatype of total_deaths from varchar to integer
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is not NULL
GROUP BY continent, location
ORDER BY highest_death_count DESC;
-- ANSWER:The United States has the highest death count in the world with over 900,000 deaths counted in this dataset



-- 7. CONTINENTAL NUMBERS
--    Now, I'll look at the death count based on continent
--    I want to break this task down into steps:
		  -- Group the locations by their continents
		  -- Find the MAX death count total for each continent
SELECT
	continent,
	MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is not NULL
GROUP BY continent
ORDER BY highest_death_count DESC
--   There's a problem with these results. They don't seem to representing the entirety of the locations for each continent
        --I want to see the ACTUAL totals. I'll do it manually first
--    I'll start looking into the problem by first looking at how many distinct continents are represented in this dataset

SELECT
	DISTINCT(continent)
FROM
	PortfolioProject..CovidDeaths$
--    It appears that there are 6 continents ('North America', 'Africa', 'South America', 'Asia', 'Oceania', 'Europe') and 1 that is NULL
        -- Now, I want to see what is included in WHERE continent is NULL

SELECT
	DISTINCT(location)
FROM PortfolioProject..CovidDeaths$
WHERE continent is NULL
--    There are 13 locations that are included where the continent is NULL -> DO NOT INCLUDE THESE IN DEATH COUNT
		-- From here on out, use WHERE continent is NOT NULL
--    Now, look at how many distinct locations there are WHERE continent is NOT NULL

SELECT
	DISTINCT(location)
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
--    Based off of the results this query gave, there are 225 distinct locations in this dataset where continent is NOT NULL
--    Now, I want to find the MAX amount of deaths for each of these distinct locations

SELECT
	continent,
	location,
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent, location

-- Okay, good! Now, I have the max total deaths for each location WHERE continent is NOT NULL
-- Now, I need to group them by continent

SELECT
	continent,
	SUM(MAX(CAST(total_deaths AS INT))) AS total_death_count
FROM
	PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY continent
-- This query yields an ERROR because I am trying to aggregate an aggregate function
-- I'm going to use a CTE to take the SUM of MAX(total_deaths) for each location

WITH continental_death_count AS
	(SELECT
		continent,
		location,
		MAX(CAST(total_deaths AS INT)) AS total_death_count
	FROM
		PortfolioProject..CovidDeaths$
	WHERE continent is NOT NULL
	GROUP BY continent, location)
SELECT
	continent,
	SUM(total_death_count) AS total_continent_deaths
FROM continental_death_count
GROUP BY continent
ORDER BY total_continent_deaths DESC
-- Now, the results appear much more accurate.


-- 8. GLOBAL NUMBERS
--    What percentage of the people in the world who have contracted Covid-19 have died?

SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
-- Out of the 393,694,504 cases included, 5,713,855 cases have resulted in death. That's a global Covid-19 death rate of ~1.45%



-- JOINING THE CovidDeaths$ AND THE CovidVaccinations$ TABLES
-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
-- Using a partition by to partition out a rolling count of the new vaccinations by date as time goes on, effectively showing the updated amount of new vaccinations with each new observation
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

-- Now, I want to measure the rolling count against the total population of the locations to find the % of people vaccinated
	-- I can't simply add another column dividing the results of rolling_people_vaccinated since it would be in the same query --> have to store it first
	-- I'm going to use a CTE to first store my query for the rolling count and then divide the total population by the stored results to get the % vaccinated

WITH pop_vs_vac AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
-- Using a partition by to partition out a rolling count of the new vaccinations by date as time goes on, effectively showing the updated amount of new vaccinations with each new observation
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL)
--ORDER BY 2,3
SELECT
	*, (rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM
	pop_vs_vac


-- Could also use a TEMP TABLE
--
DROP TABLE IF EXISTS #percent_people_vaccinated
CREATE TABLE #percent_people_vaccinated (
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC)

INSERT INTO #percent_people_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
-- Using a partition by to partition out a rolling count of the new vaccinations by date as time goes on, effectively showing the updated amount of new vaccinations with each new observation
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--ORDER BY 2,3

SELECT
	*, (rolling_people_vaccinated/population)*100 AS percent_vaccinated
FROM #percent_people_vaccinated


-- CREATING VIEW TO STORE DATA FOR FUTURE VISUALIZATIONS

CREATE VIEW percent_people_vaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
-- Using a partition by to partition out a rolling count of the new vaccinations by date as time goes on, effectively showing the updated amount of new vaccinations with each new observation
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT * FROM percent_people_vaccinated