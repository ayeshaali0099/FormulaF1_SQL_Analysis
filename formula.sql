
select * from seasons; -- 74
select * from status; -- 139	
select * from circuits; -- 77
select * from races; -- 1102
select * from drivers; -- 857
select * from constructors; -- 211
select * from constructor_results; -- 12170
select * from constructor_standings; -- 12941
select * from driver_standings; -- 33902
select * from lap_times; -- 538121
select * from pit_stops; -- 9634
select * from qualifying; -- 9575
select * from results; -- 25840
select * from sprint_results; -- 120

1. Identify the country which has produced the most F1 drivers.

select nationality from (
select nationality,count(*),
rank() over (order by count(*) desc)
from drivers
group by nationality)q
where rank =1


2. Which country has produced the most no of F1 circuits

select country from (
select country,count(*),
rank() over (order by count(*) desc)
from circuits
group by country)q
where rank =1


3. Which countries have produced exactly 5 constructors?

select nationality,count(*),
rank() over (order by count(*) desc)
from constructors
group by nationality
having count(*) =5

4. List down the no of races that have taken place each year

select year,count(*),
rank() over (order by count(*) desc)
from races
group by year

5. Who is the youngest and oldest F1 driver?
with cte as(select (forename||' '||surname) as name,dob,
rank() over (order by dob)
from drivers)

select cte.name ,dob ,
case when rank =1 then 'old' else 'young' end as pp 
from cte
where cte.rank =1 or cte.rank in (select max(rank) from cte)


select max(case when rn=1 then forename||' '||surname end) as oldest_driver
	, max(case when rn=cnt then forename||' '||surname end) as youngest_driver
	from (
		select *, row_number() over (order by dob ) as rn, count(*) over() as cnt
		from drivers) x
	where rn = 1 or rn = cnt
	
6. List down the no of races that have taken place each year and mentioned which was the 
first and the last race of each season.

with cte as(
select year, count(*) as no_races
from races
group by year
order by year desc)

select  distinct cte.year, cte.no_races,
first_value(r.name)over(partition by r.year order by r.date) as first_race,
last_value(r.name)over(partition by r.year order by r.date range between unbounded preceding and unbounded following) 
as last_race

from cte join races r on cte.year=r.year
order by cte.year desc

select distinct year
	,first_value(name) over(partition by year order by date) as first_race
	, last_value(name) over(partition by year order by date 
						   range between unbounded preceding and unbounded following) as last_race
	, count(*) over(partition by year) as no_of_races
	from races
	order by year desc


  7. Which circuit has hosted the most no of races. Display the circuit name, no of races, city and country.
  
  with cte as(
  select r.circuitid,count(*)  no_of_races,
  rank() over(order by count(*)desc)
  from races r
  join circuits c on r.circuitid=c.circuitid
  group by r.circuitid)
  
  select c.name,cte. no_of_races, c.location,c.country
  from
  cte join circuits c on c.circuitid=cte.circuitid
  where cte.rank=1
  
 
8. Display the following for 2022 season:
Year, Race_no, circuit name, driver name, driver race position, driver race points, flag to indicate if winner
, constructor name, constructor position, constructor points, , flag to indicate if constructor is winner
, race status of each driver, flag to indicate fastest lap for which driver, total no of pit stops by each driver

select r.year, r.raceid,r.name, concat(d.forename,' ',d.surname) as drivername, ds.position, ds.points
,case when ds.position=1 then 'winner' end as flag_driver_win
,c.name, cd.points, cd.position
,case when cd.position=1 then 'winner' end as flag_const_win
,s.status
,case when fst.min_lap= res.fastestlaptime then 'fastest lap' end as fast_lap_flag
,no_stop
from races r
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
join constructor_standings cd on cd.raceid=r.raceid
join constructors c on c.constructorid=cd.constructorid
join results res on res.raceid=r.raceid and res.constructorid=cd.constructorid and res.driverid=ds.driverid
join status s on s.statusid=res.statusid
left join(select raceid,min(fastestlaptime) as min_lap from results group by raceid)fst on fst.raceid=res.raceid

left join (select raceid,driverid,count(1) as no_stop from pit_stops group by raceid,driverid) stp 
on stp.driverid=res.driverid and stp.raceid=r.raceid

where year =2022 



9. List down the names of all F1 champions and the no of times they have won it.



with cte as(
select r.year,concat(d.forename,' ',d.surname) as name,sum(rs.points)
,rank() over(partition by r.year order by sum(rs.points) desc)
from races r 
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
join results rs on r.raceid=rs.raceid and rs.driverid=ds.driverid
group by r.year,concat(d.forename,' ',d.surname) 
)

select name, count(1) as no_of_championships
		from cte
		where cte.rank =1
		group by name
		order by 2 desc;



10. Who has won the most constructor championships

with cte as (select r.year,c.name  , sum(cd.points)
,rank() over(partition by r.year order by sum(cd.points) desc)

from races r
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
join constructor_standings cd on cd.raceid=r.raceid
join constructors c on c.constructorid=cd.constructorid
group by r.year,c.name)

select name, count(1) as no_of_championships
		from cte
		where cte.rank =1
		group by name
		order by 2 desc;


11. How many races has India hosted?
select c.name, c.country,count(*)
from races r
  join circuits c on r.circuitid=c.circuitid
  where c.country='India'
  group by c.name, c.country


12. Identify the driver who won the championship or was a runner-up. Also display the team they belonged to.
with cte as(
select r.year,concat(d.forename,' ',d.surname) as name,c.name as team,sum(rs.points)
,rank() over(partition by r.year order by sum(rs.points) desc)
from races r 
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
	--join constructor_standings cd on cd.raceid=r.raceid
	join results rs on r.raceid=rs.raceid and rs.driverid=ds.driverid

join constructors c on c.constructorid=rs.constructorid
				where r.year>=2020

group by r.year,concat(d.forename,' ',d.surname) ,c.name
)

select year,name, team ,cte.rank,
case when cte.rank =1 then 'winner' else 'runner up' end as flag
		from cte
		where cte.rank =1 or cte.rank=2
		--group by name,team,cte.rank



13. Display the top 10 drivers with most wins.

with cte as(
select concat(d.forename,' ',d.surname) as name,count(*) as no_of_wins
,rank() over(order by count(*) desc)
from races r 
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
	where ds.position=1
group by concat(d.forename,' ',d.surname)
)

select cte.name, no_of_wins
		from cte
		where cte.rank <=10
		--group by cte.name
		order by 2 desc;


14. Display the top 3 constructors of all time.

select name,no_wins from(
select c.name,count(*) as no_wins
,rank() over(order by count(*) desc)
from constructors c 
join constructor_standings cs on c.constructorid= cs.constructorid
where cs.position=1
group by c.name)x
where rank<=3



15. Identify the drivers who have won races with multiple teams.

select driverid, d_name, string_agg( t_name,', ') from(
select distinct r.driverid,concat(d.forename,' ',d.surname) as d_name, c.name as t_name
from results r 
join drivers d on r.driverid=d.driverid
join constructors c on c.constructorid= r.constructorid
where r.position=1 )x
group by driverid, d_name
having count(1)>1
order by driverid, d_name;


16. How many drivers have never won any race.


	select  d.driverid
	, concat(d.forename,' ',d.surname) as driver_name
	, nationality
	from drivers d 
	where driverid not in (select distinct driverid
						  from driver_standings ds 
						  where position=1)
	order by driver_name;
17. Are there any constructors who never scored a point? if so mention their name and how many races they participated in?


select  cs.constructorid,c.name,sum(cs.points),count(1) as no_races
from constructor_results cs
join constructors c on c.constructorid=cs.constructorid
group by  cs.constructorid,c.name
having sum(cs.points)=0
order by no_races desc



18. Mention the drivers who have won more than 50 races.

select  concat(d.forename,' ',d.surname),count(distinct ds.raceid) as no_ofraces
from drivers d
join driver_standings ds on d.driverid=ds.driverid
where ds.position =1
group by concat(d.forename,' ',d.surname)
	having count(1) > 50
		order by no_ofraces desc;



19. Identify the podium finishers of each race in 2022 season

select r.name,concat(d.forename,' ',d.surname),ds.position
from races r 
join driver_standings ds on r.raceid=ds.raceid
join drivers d on d.driverid=ds.driverid

where r.year=2022 and ds.position <=3
	order by r.name,ds.position;




20. For 2022 season, mention the points structure for each position. i.e. how many points are awarded to each race finished position.

select  res.position , string_agg( distinct res.points::VARCHAR,', ') as point
--case when 
from races r
		join results res on res.raceid=r.raceid
		where r.raceid in (select min(res.raceid) as raceid
		from races r
		join results res on res.raceid=r.raceid
		where year=2022)
		
		and res.points<>0
	
group by res.position



21. How many drivers participated in 2022 season?



	select count(distinct res.driverid) as no_driv
from races r
join results res on res.raceid=r.raceid
where r.year =2022

	
22. How many races has the top 5 constructors won in the last 10 years.
-- 5 top teams
with cte as(
select constructorid,name from(
select c.constructorid, c.name,count(*) as no_wins
				, rank() over(order by count(1) desc) as rnk
from  constructor_standings cs 
join  constructors c on c.constructorid=cs.constructorid
where cs.position =1 
group by c.constructorid, c.name
order by no_wins desc)x
where rnk<=5
)

select cte.constructorid, cte.name,coalesce(y.num_wins,0) as no_wins
	from  cte 
	left join(
select  cs.constructorid,count(*) as num_wins
from races r
join constructor_standings cs on r.raceid= cs.raceid
				where cs.position = 1
and r.year >= (extract(year from current_date) - 10)
group by cs.constructorid
		)y
				on cte.constructorid = y.constructorid
order by no_wins desc




23. Display the winners of every sprint so far in F1

select r.year, r.name, concat(d.forename,surname)
from sprint_results s
join drivers d on s.driverid=d.driverid
	join races r on r.raceid=s.raceid

where s.position =1


24. Find the driver who has the most no of Did Not Qualify during the race.
	select name, count from(

select  concat(d.forename,d.surname)as name,count(*),
rank() over (order by count(*) desc)
from results res
join drivers d on res.driverid=d.driverid
join status s on s.statusid=res.statusid
where  s.status = 'Did not qualify'
group by name) x
where rank =1
	

25. During the last race of 2022 season, identify the drivers who did not finish the race and the reason for it.

select max(raceid)
from races
where year=2022

select  concat(d.forename,d.surname),r.statusid,s.status
from results r 
join drivers d on r.driverid=d.driverid
join status s on s.statusid=r.statusid
where r.raceid in (select max(raceid)
from races
where year=2022
)
and r.statusid<>1;



26. What is the average lap time for each F1 circuit. Sort based on least lap time.

select c.circuitid,c.name,avg(lt.time) as avg_lap
from circuits c
left join races r on c.circuitid=r.circuitid
left join lap_times lt on r.raceid=lt.raceid
 group by c.circuitid,c.name
 order by avg_lap 

	
27. Who won the drivers championship when India hosted F1 for the first time?

select concat(d.forename,' ',d.surname),c.name,r.date
from circuits c
join races r on c.circuitid=r.circuitid
join driver_standings ds on ds.raceid=r.raceid
join drivers d on d.driverid=ds.driverid
where c.country='India' and r.date = (select min(r.date)from races r join circuits c on r.circuitid=c.circuitid where c.country='India'  )
and ds.position =1




28. Which driver has done the most lap time in F1 history?

select name,lap_time from(
select concat(d.forename,' ',d.surname) as name,sum(time) as lap_time
,rank() over(order by sum(time) desc)
from drivers d
join lap_times lt on d.driverid=lt.driverid
group by name)x
where rank =1


29. Name the top 3 drivers who have got the most podium finishes in F1 (Top 3 race finishes)
select name,no_of_podiums from(
select concat(d.forename,' ',d.surname) as name, count(*) as no_of_podiums
,rank() over (order by count(1) desc)
from drivers d
join driver_standings ds on d.driverid=ds.driverid
where ds.position in (1,2,3)
group by name)x
where rank <=3


30. Which driver has the most pole position (no 1 in qualifying)
select name,pole_positions from(
select  concat(d.forename,' ',d.surname) as name,count(1) as pole_positions
,rank() over (order by count(1) desc)
from drivers d
join qualifying q on q.driverid=d.driverid
where q.position=1
group by name)x
where rank =1

