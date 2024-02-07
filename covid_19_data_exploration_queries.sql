/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Aggregate Functions, Windows Functions,Creating Views, Converting Data Types, Importing CSV file from Jupyter Notebook

*/

  SELECT * 
    FROM covid_deaths
ORDER BY location, date;

  SELECT *
    FROM covid_vaccination
ORDER BY location, date;

  SELECT location, date, total_cases, new_cases, total_deaths, new_deaths, population 
    FROM covid_deaths
ORDER BY location, date;

  SELECT location, date, total_cases, new_cases, total_deaths,population 
    FROM covid_deaths
ORDER BY location, date;

-- Total Cases vs Total Deaths: It shows likelihood of dying

  SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_rate
    FROM covid_deaths
ORDER BY location, date;

  SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_rate
    FROM covid_deaths
   WHERE location LIKE '%Serbia%'
ORDER BY location, date;

  SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_rate
    FROM covid_deaths
   WHERE location = 'Croatia'
ORDER BY location, date;

  SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_rate
    FROM covid_deaths
   WHERE location LIKE '%States'
ORDER BY location, date;

-- Show the date when the maximum death rate occurred in the US

  SELECT MAX((total_deaths/total_cases)*100) AS max_death_rate, date
    FROM covid_deaths
   WHERE location = 'United States' AND ((total_deaths/total_cases)*100) IS NOT NULL
GROUP BY date
ORDER BY max_death_rate DESC
   LIMIT 1;

-- Compare the maximum recorded death rate for each country

  SELECT continent,location,population,MAX(total_deaths) AS highest_death_number,
         ROUND(MAX((total_deaths:: numeric / population:: numeric) * 100), 2) AS highest_death_rate
   FROM  covid_deaths
GROUP BY continent,location,population
  HAVING continent IS NOT NULL AND population IS NOT NULL AND MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_rate DESC;

-- Country with the highest death rate

  SELECT location, MAX(total_deaths) AS total_deaths, 
         MAX(total_cases) AS total_cases, MAX(population) AS population,
         ROUND(MAX(total_deaths):: numeric / MAX(total_cases):: numeric * 100, 2) AS death_rate
    FROM covid_deaths
GROUP BY location
  HAVING ROUND(MAX(total_deaths):: numeric / MAX(total_cases):: numeric * 100, 2) IS NOT NULL
ORDER BY death_rate DESC;


-- Looking at Total Cases vs Population
-- Show the percentage of the population that has contracted COVID

  SELECT location, date, population,  total_cases, 
	     ROUND(((total_cases:: numeric / population:: numeric) *100), 4) AS infection_rate
    FROM covid_deaths
   WHERE location = 'Serbia' AND total_cases IS NOT NULL
ORDER BY location, date;

-- -- Countries with Highest Infection Rate compared to Population

  SELECT location, population, MAX(total_cases) AS highest_infection_number,
		 MAX((total_cases/population)) * 100 AS highest_infection_rate
    FROM covid_deaths
GROUP BY location, population
  HAVING MAX(total_cases) IS NOT NULL AND population IS NOT NULL
ORDER BY highest_infection_rate DESC;

-- Countries with Highest Death Count per Population

  SELECT location, population, MAX(total_deaths) AS highest_death_number
    FROM covid_deaths
   WHERE continent IS NOT NULL
GROUP BY location, population
 HAVING  MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_number DESC;

-- Death Number by Continent

  SELECT continent, MAX(total_deaths) AS highest_death_number
    FROM covid_deaths
   WHERE continent IS NOT NULL
GROUP BY continent
 HAVING  MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_number DESC;

-- Global numbers

-- Evaluating new deaths and new cases on a daily basis worldwide

  SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
         CASE WHEN SUM(new_cases) > 0 THEN (SUM(new_deaths) / SUM(new_cases)) * 100 
         ELSE null 
         END AS death_rate_per_day
    FROM covid_deaths
   WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Evaluating cumulative data over time worldwide

  SELECT SUM(new_cases) AS total_cases, 
         SUM(new_deaths) AS total_deaths, 
	     ROUND(SUM(CAST(new_deaths AS bigint)) / SUM(CAST(new_cases AS bigint)) * 100, 2) AS death_rate_globally
    FROM covid_deaths
   WHERE continent IS NOT NULL;

  SELECT location, population
    FROM covid_deaths
   WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population DESC

-- Reviewing the covid vaccination table to determine the appropriate fields for performing a join

  SELECT * 
    FROM covid_vaccination
ORDER BY location, date;

-- Displaying the daily count of worldwide vaccinated individuals, comparing it to the population

  SELECT death.continent, death.location, death.date, death.population, vac.new_tests, vac.new_vaccinations
    FROM covid_deaths AS death
    JOIN covid_vaccination AS vac
 	  ON death.location = vac.location AND death.date = vac.date
   WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date;

-- Identifying the top countries with the highest rates of fully vaccinated individuals

  SELECT death.location, death.population, MAX(vac.people_fully_vaccinated) AS total_people_fully_vaccinated, 
         MAX(vac.people_fully_vaccinated) / death.population * 100 AS fully_vaccinated_rate
    FROM covid_deaths death
    JOIN covid_vaccination vac
      ON death.location = vac.location AND death.date = vac.date
   WHERE death.continent IS NOT NULL AND death.population IS NOT NULL AND vac.people_fully_vaccinated IS NOT NULL
GROUP BY death.location, death.population
ORDER BY fully_vaccinated_rate DESC;

-- Displaying the daily count of vaccinated individuals and the total count of vaccinations worldwide, 
-- comparing it to the population

  SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
         SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
		 AS total_vaccinations
    FROM covid_deaths AS death
    JOIN covid_vaccination AS vac
 	  ON death.location = vac.location AND death.date = vac.date
   WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date;

-- Calculating the daily rate of vaccinations for each country, utilizing partitioning and CTEs

    WITH vaccination_by_population (continent, location, date, population, new_vaccinations, total_vaccinations)
         AS
 (SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
         SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
		 AS total_vaccinations
    FROM covid_deaths AS death
    JOIN covid_vaccination AS vac
 	  ON death.location = vac.location AND death.date = vac.date
   WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date)
  SELECT *, ROUND((total_vaccinations:: numeric) / (population:: numeric) * 100, 4) AS vaccination_rate_per_day
    FROM vaccination_by_population
   WHERE new_vaccinations IS NOT NULL
   
-- Creating View to store data for later visualizations

  CREATE VIEW vaccinated_population_percentage AS
    WITH vaccination_by_population (continent, location, date, population, new_vaccinations, total_vaccinations)
         AS
 (SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
         SUM(new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
		 AS total_vaccinations
    FROM covid_deaths AS death
    JOIN covid_vaccination AS vac
 	  ON death.location = vac.location AND death.date = vac.date
   WHERE death.continent IS NOT NULL
ORDER BY death.location, death.date)
  SELECT *, ROUND((total_vaccinations:: numeric) / (population:: numeric) * 100, 4) AS vaccination_rate_per_day
    FROM vaccination_by_population
   WHERE new_vaccinations IS NOT NULL;



