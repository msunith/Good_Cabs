#1.City Level Fare and Trip summary Report
with cte as
(SELECT city_id,
		city_name,
        sum(distance_travelled_km) as Total_Distance_Travelled,
		sum(fare_amount) as Total_Fare_amount,
        count(trip_id) as Total_Trips
 FROM trips_db.fact_trips inner join dim_city using (city_id)
 group by city_id )
 select city_name,Total_Trips,
		round((Total_Fare_amount/Total_Distance_Travelled),2) as average_fare_per_km,
        round((Total_Fare_amount/Total_Trips),2) as average_fare_per_trip,
        concat(round((Total_Trips * 1.0 / (SELECT count(trip_id) FROM fact_trips)) * 100,2),"%") AS '%_contribution_to_total_trips'
        from cte order by city_name;

#2. Monthly city level trips target performance report
with cte as 
	(SELECT	city_name, month_name,start_of_month,
        count(trip_id) as Actual_Trips,
        total_target_trips as Target_Trips           
	FROM trips_db.fact_trips t inner join dim_city using (city_id)
	inner join dim_date d using (date)
	inner join targets_db.monthly_target_trips m on d.start_of_month = m.month and t.city_id = m.city_id
	group by t.city_id,month_name) 
 select city_name,
		month_name,
        Actual_Trips,
        Target_Trips,
		case 
			when Target_Trips < Actual_Trips then "Above Target"
			else "Below Target"
        End as performance_status,
        concat(round((Actual_Trips - Target_Trips)/Target_Trips * 100,2),"%") as '%_difference'
        from cte        
        order by city_name,month(start_of_month);

# 3. city level repeat passenger trip frequency report
with cte as 
(select city_id,trip_count,sum(repeat_passenger_count) as repeat_passenger_count from
dim_repeat_trip_distribution group by city_id,trip_count),
cte1 as 
(select city_id,sum(repeat_passenger_count) as total_passenger from
dim_repeat_trip_distribution group by city_id),
cte2 as
(select city_name,trip_count,
	concat(round((repeat_passenger_count/total_passenger)*100,2),"%") as percent_repeat_passenger
 from cte c inner join cte1 c1 using (city_id)
 inner join dim_city using (city_id))
 select city_name,
	MAX(case when trip_count = "2-Trips" then percent_repeat_passenger End) as "2-Trips",
	MAX(case when trip_count = "3-Trips" then percent_repeat_passenger End) as "3-Trips",
	MAX(case when trip_count = "4-Trips" then percent_repeat_passenger End) as "4-Trips",
	MAX(case when trip_count = "5-Trips" then percent_repeat_passenger End) as "5-Trips",
	MAX(case when trip_count = "6-Trips" then percent_repeat_passenger End) as "6-Trips",
	MAX(case when trip_count = "7-Trips" then percent_repeat_passenger End) as "7-Trips",
	MAX(case when trip_count = "8-Trips" then percent_repeat_passenger End) as "8-Trips",
	MAX(case when trip_count = "9-Trips" then percent_repeat_passenger End) as "9-Trips",
	MAX(case when trip_count = "10-Trips" then percent_repeat_passenger End) as "10-Trips"
	from cte2 group by city_name order by city_name;
    
# 4.Identify cities with highest and lowest total new passengers
with cte as 
(select city_name,
		sum(new_passengers) as total_new_passengers,
        RANK() OVER(ORDER BY sum(new_passengers) DESC) AS rank_city_desc,
        RANK() OVER(ORDER BY sum(new_passengers) ) AS rank_city_asc
       from fact_passenger_summary s inner join dim_city c using (city_id)
group by c.city_id)
select city_name,
		total_new_passengers,
        case 
			when rank_city_desc <=3 then 'Top3'
            when rank_city_asc <=3 then 'Bottom3'
            else '______'
        End as city_category 
        from cte order by total_new_passengers desc;
        
# [or]
WITH ranked_cities AS (
    SELECT c.city_name,
           SUM(s.new_passengers) AS total_new_passengers,
           RANK() OVER (ORDER BY SUM(s.new_passengers) DESC) AS rank_desc,
           RANK() OVER (ORDER BY SUM(s.new_passengers)) AS rank_asc
    FROM fact_passenger_summary s
    INNER JOIN dim_city c USING (city_id)
    GROUP BY c.city_id, c.city_name
)
SELECT city_name, total_new_passengers, 'Top 3' AS category
FROM ranked_cities
WHERE rank_desc <= 3
UNION ALL
SELECT city_name, total_new_passengers, 'Bottom 3' AS category
FROM ranked_cities
WHERE rank_asc <= 3;

# 5. Identify month with Highest revenue for each city
with cte  as
(SELECT city_id,city_name,
	month_name,
    sum(fare_amount) as revenue 
FROM trips_db.fact_trips inner join dim_date using (date)
inner join dim_city using (city_id)
group by city_id,month_name),
cte1 as
(select city_id,city_name,month_name, revenue,
		row_number() over (partition by city_name order by revenue desc) as rank_order
        from cte),
cte2 as
(select city_id,city_name,month_name,revenue as high_revenue from cte1 
	where rank_order =1  order by city_name),
cte3 as
(select city_id,sum(fare_amount) as total_revenue FROM trips_db.fact_trips
group by city_id)
select city_name,month_name,high_revenue, 
		concat(round((high_revenue/total_revenue)*100,2),"%") as percentage_contribution
	from cte2 inner join cte3 using (city_id) order by city_name;

#6. Repeat passenger rate analysis
        
with cte as
(select city_name,month_name,p.month,
		sum(total_passengers) as total_passengers,
        sum(repeat_passengers) as repeat_passengers
        from fact_passenger_summary p inner join dim_city using (city_id)
        inner join dim_date d on p.month = d.start_of_month
        group by city_id,p.month)
select city_name,month_name,
		total_passengers,
        repeat_passengers,
        concat(round((repeat_passengers/total_passengers)*100,2),"%") as monthly_repeat_passenger_rate
from cte order by city_name,month(month);
        
with cte as
(select city_name,
		sum(total_passengers) as total_passengers,
        sum(repeat_passengers) as repeat_passengers
        from fact_passenger_summary p inner join dim_city using (city_id)
        group by city_id)
select city_name,
		total_passengers,
        repeat_passengers,
        concat(round((repeat_passengers/total_passengers)*100,2),"%") as monthly_repeat_passenger_rate
from cte order by city_name;
        




 

 

