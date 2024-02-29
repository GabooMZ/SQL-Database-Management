--Show the few tables we are going to be working with and what they contain

SELECT * FROM races order by year DESC 

SELECT * FROM results WHERE raceId > 1095 

SELECT * FROM circuits

SELECT * FROM driver_standings

SELECT * FROM constructor_standings


----Recognizes which driver got which position from the 2023 season

SELECT results.position, drivers.surname FROM results JOIN drivers ON
results.driverId = drivers.driverId
WHERE raceId > 1095

--Looking at drivers from 2023 and their respective details per race

SELECT  races.raceId, circuits.name as Circuit, races.year, drivers.surname, results.grid, results.position, status.status, results.points, constructors.name
FROM results JOIN drivers ON results.driverId = drivers.driverId 
JOIN races ON results.raceId = races.raceId
JOIN circuits ON races.circuitId = circuits.circuitId 
JOIN constructors ON results.constructorId = constructors.constructorId
JOIN status ON results.statusId = status.statusid
WHERE races.year > 2019
ORDER BY year, surname, raceid


--Driver Total Points and some statistics of their current standings. ie their points through out the season

SELECT  races.raceId, circuits.name as Circuit, races.year, drivers.surname, results.grid, results.position, results.points,
SUM(CONVERT(int, results.points)) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) as RollingPointsCount
FROM results JOIN drivers ON results.driverId = drivers.driverId 
JOIN races ON results.raceId = races.raceId 
JOIN circuits ON races.circuitId = circuits.circuitId 
WHERE races.raceId > 1073 
ORDER BY year, surname, raceid


--Getting a Cumulative Pole sum

SELECT  races.raceId, circuits.name as Circuit, races.year, drivers.surname, results.grid, results.position, results.points,
SUM(CONVERT(int, results.points)) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) as RollingPointsCount,
SUM(CASE WHEN position <= 3 THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS CumulativePoleSum
FROM results JOIN drivers ON results.driverId = drivers.driverId 
JOIN races ON results.raceId = races.raceId 
JOIN circuits ON races.circuitId = circuits.circuitId 
WHERE races.raceId > 1073 
ORDER BY year, surname, raceid


----Races raced in the season

SELECT  races.raceId, circuits.name as Circuit, races.year, drivers.surname, results.grid, results.position, results.points,
SUM(CONVERT(int, results.points)) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) as RollingPointsCount,
SUM(CASE WHEN position <= 3 THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS CumulativePoleSum,
SUM(CASE WHEN grid is not NULL THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS RacesStarted,
SUM(CASE WHEN position is not NULL THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS RacesFinished
FROM results JOIN drivers ON results.driverId = drivers.driverId 
JOIN races ON results.raceId = races.raceId 
JOIN circuits ON races.circuitId = circuits.circuitId 
WHERE races.raceId > 1073 
ORDER BY year, surname, raceid

--Using a CTE to create a percentage of pole positions based on total number of races and current number of races

WITH PercentPole (raceid, Circuit, year, surname, name, grid, position, points, RollingPointsCount, CumulativePoleSum, RacesStarted, RacesFinished)
as
(
SELECT races.raceId, circuits.name as Circuit, races.year, drivers.surname, constructors.name, results.grid, results.position, results.points,
SUM(CONVERT(int, results.points)) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) as RollingPointsCount,
SUM(CASE WHEN position <= 3 THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS CumulativePoleSum,
SUM(CASE WHEN grid is not NULL THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS RacesStarted,
SUM(CASE WHEN position is not NULL THEN 1 ELSE 0 END) OVER (PARTITION by drivers.surname, races.year ORDER by races.year,races.raceId) AS RacesFinished
FROM results JOIN drivers ON results.driverId = drivers.driverId 
JOIN races ON results.raceId = races.raceId 
JOIN circuits ON races.circuitId = circuits.circuitId
JOIN constructors ON results.constructorId = constructors.constructorId
WHERE races.year = 2023
)
SELECT *, (CASE WHEN RacesStarted = 0 OR CumulativePoleSum = 0 THEN NULL ELSE FORMAT((CONVERT(float, CumulativePoleSum) / CONVERT(float, RacesStarted)), '0.0000%') END) as PolePercentAllRaces,
(CASE WHEN RacesFinished = 0 OR CumulativePoleSum = 0 THEN NULL ELSE FORMAT((CONVERT(float, CumulativePoleSum) / CONVERT(float, RacesFinished)), '0.0000%') END) as PolePercentFinished
FROM PercentPole
ORDER BY year, surname, raceid
