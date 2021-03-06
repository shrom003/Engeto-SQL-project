# Time related data

create table General_Data as
	select country, date, tests_performed,
	case 
		when weekday(date) in (5,6) then 'False'
	else 'True'
	end as Working_day, # working day or not when the tests were done
	case 
		#Sping
		when (DAYOFMONTH(date) between 1 and 31) and (MONTH(date) in (4,5)) THEN 0
		when (DAYOFMONTH(date) between 20 and 31) and (MONTH(date) in (3)) THEN 0
		when (DAYOFMONTH(date) between 1 and 19) and (MONTH(date) in (6)) THEN 0
		#Summer
		when (DAYOFMONTH(date) between 1 and 31) and (MONTH(date) in (7,8)) THEN 1
		when (DAYOFMONTH(date) between 20 and 31) and (MONTH(date) in (6)) THEN 1
		when (DAYOFMONTH(date) between 1 and 21) and (MONTH(date) in (9)) THEN 1
		#Autumn
		when (DAYOFMONTH(date) between 1 and 31) and (MONTH(date) in (10,11)) THEN 2
		when (DAYOFMONTH(date) between 21 and 31) and (MONTH(date) in (9)) THEN 2
		when (DAYOFMONTH(date) between 1 and 20) and (MONTH(date) in (12)) THEN 2
		#Winter
		else 3
		end as Time_of_year # period of year when it was done
	from covid19_tests
	where tests_performed is not null;
	
#2.) Countries data

create table population_data as
	select c.country, c.population_density, c.median_age_2018, e.gdp_2020, e2.Average_GINI,	e3.Average_child_mortality
	from countries c	
	join (
    		select e.country, e.gdp as GDP_2020
    		from economies e
    		where year = 2020
    		and e.gdp is not NULL
		) 
	e on c.country = e.country
    	join (
		select e2.country, round(AVG(e2.gini),2) as Average_GINI
		from economies e2
		where e2.gini != 0
		group by e2.country
		) 
	e2 on c.country = e2.country
 	join (
		select e3.country, round(AVG(e3.mortaliy_under5),2) as Average_child_mortality
		from economies e3
		where e3.mortaliy_under5 !=0
		group by e3.country
		)
	e3 on c.country = e3.country;
 
# religions share by country
   	
create table religions_by_country AS 
	select rel.country , rel.religion , round(rel.population*100/r2.total_population, 2) as religion_share
	from religions rel 
	join ( 
		select rel.country , rel.year,  sum(rel.population) as total_population
    	 	from religions rel
  		where rel.year = 2020 and rel.country != 'All Countries'
		group by rel.country
   		 ) 
	r2 on rel.country = r2.country
	and rel.year = r2.year
	and rel.population > 0;
 
# life expectancy difference between 1965 and 2015
  		 
create table year_difference as
	select a.country, a.life_exp_1965 , b.life_exp_2015, round(b.life_exp_2015 - a.life_exp_1965, 2) as life_exp_difference
	from (
    		select le.country, le.life_expectancy as life_exp_1965
    		from life_expectancy le 
    		where year = 1965
   		 ) 
	a join (
		select le.country, le.life_expectancy as life_exp_2015
 		from life_expectancy le 
		where year = 2015
		)
	b on a.country = b.country;

# Weather data
   
create table weather_conditions as
	select w.date, c.country, w.city, w.max_daily_wind, w2.hours_raining, w3.avg_daily_temp
	from countries c
	join (
		select w.city , w.date , max(w.wind) as max_daily_wind 
        	from weather w 
       		group by w.city, w.date
        )
	w on c.capital_city = w.city 
	join (
		select count(time)*3 as hours_raining, w2.date
		from weather w2
		where w2.rain > 0.0
		group by w2.date
		)
	w2 on w.date = w2.date
	join (
		select cast(avg(w3.temp) as decimal(10,2)) as avg_daily_temp, w3.date
		from weather w3
		where w3.time between '06:00' and '18:00'
		group by w3.date
		)
	w3 on w.date = w3.date
	order by c.country;

	
# Results

select * from General_data;

select rbc.country, rbc.religion, rbc.religion_share, pd.population_density, pd.median_age_2018, pd.gdp_2020,pd.Average_GINI,pd.Average_child_mortality, yd.life_exp_difference
	from religions_by_country rbc
	join population_data pd on rbc.country = pd.country
	join year_difference yd on pd.country = yd.country;

select * from weather_conditions;

# Cleanup

drop table General_Data;
drop table population_data; 
drop table religions_by_country;
drop table year_difference;
drop table weather_conditions;

# Ked som jednotlive tabulky spojila, tak sa mi niektore udaje ovjavili viackrat, kedze tabulka religions_by_country obsahuje udaje pre jednotlive krajiny viackrat
# Neviem teda ci je to spravne, alebo sa to da spravit aj lepsie, ale mna nic nenapadlo :(
# Pri tabulke weather_conditions som sa zasekla pri convertovani teploty, ked to spustim vramci create table tak mi vypise chybu, takisto aj pri selecte:

select cast(avg(w3.temp) as decimal(10,2)) as avg_daily_temp, w3.date
	from weather w3
	where w3.time between '06:00' and '18:00'
	group by w3.date;
#Truncated incorrect DOUBLE value

# Dalej som sa nedostala, viem ze sme to mali vsetko nejako spojit do jednej tabulky, ale bohuzial sa mi to nepodatilo :(
