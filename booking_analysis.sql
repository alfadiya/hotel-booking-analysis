/*
Project: Hotel Booking Analysis
Author: Alfadiya Noushad

Objective:
Analyze hotel booking data to derive insights on:

Occupancy rate
Customer behavior
Revenue trends
Booking patterns

Tables:

hotel_bookings
customers
hotels
cities

SQL Dialect: Microsoft SQL Server 

Assumptions:

booking_id is unique
capacity is fixed per hotel
stay_start_date represents check-in date
number_of_nights > 0
*/


--------------------------------------------------
--  DATA UNDERSTANDING
--------------------------------------------------

select top 20 * from hotel_bookings;
select top 20 * from customers;
select top 20 * from hotels ;
select top 20 * from cities ;


--------------------------------------------------
--  EXPLORATORY ANALYSIS
--------------------------------------------------

-- Number of bookings in each hotel
select hotel_id , count(*) as no_of_bookings 
from hotel_bookings 
group by hotel_id ;


-- Number of bookings made by each customer in each hotel
select customer_id , hotel_id , count(*) no_of_bookings
from hotel_bookings 
group by customer_id,hotel_id 
order by customer_id , hotel_id ;


-- List of unique booking channels
select distinct booking_channel 
from hotel_bookings ;


-- List of years available in the booking data
select distinct year(booking_date)
from hotel_bookings ; 

-- Monthly booking trend (total bookings by year and month)
select  
	year(booking_date) as year_of_booking ,
	month(booking_date) as month_of_booking , 
	count(*) as no_of_bookings
from hotel_bookings 
group by year(booking_date) , month(booking_date)
order by year(booking_date) , month(booking_date);


-- Total stays per month
select year(stay_start_date) as year_of_stay, month(stay_start_date) as month_of_stay, count(*) as no_of_stay
from hotel_bookings 
group by year(stay_start_date) , month(stay_start_date)
order by year(stay_start_date) , month(stay_start_date);


-- Booking count by channel
select booking_channel , count(*) as no_of_bookings 
from hotel_bookings 
group by booking_channel
order by no_of_bookings desc ;


--------------------------------------------------
--  BUSINESS QUESTIONS
--------------------------------------------------

--1- write a sql to find top 5 customers who did most number booking in the same city where they live.
--Display customer id and percent of those bookings compare to total number of bookings done by them.
--In case of tie prefer the customers with higher same city booking percent.


with cte as (
select hb.customer_id , 
sum(case 
	when h.city_id = c.city_id then 1
	else 0 
end) as same_city_booking, 
count(*) as no_of_bookings 
from hotel_bookings hb
inner join customers c
on hb.customer_id = c.customer_id 
inner join hotels h
on h.id = hb.hotel_id 
group by hb.customer_id 
)

select  top 5 customer_id , no_of_bookings , same_city_booking, same_city_booking*100.0 / no_of_bookings as same_city_booking_percent
from cte 
order by same_city_booking desc, same_city_booking_percent desc ;


--2- write a sql to find percent contribution by females in terms of revenue and no of bookings both for each hotel

select hotel_id ,
round(sum(case when c.gender = 'F' then number_of_nights* per_night_rate 
else 0 
end ) *100.0 / sum(number_of_nights * per_night_rate ),2) as female_revenue_percent , 
round(sum(case when c.gender = 'F' then 1 
else 0 end)*100.0/ count(*) ,2) as female_booking_percent 
from hotel_bookings hb
inner join customers c
on hb.customer_id = c.customer_id 
group by hb.hotel_id ;


--3- for each hotel find number of bookings from customers who visit from a different state 

with customer_city_cte as (
	select c.customer_id , ct.state
	from customers c
	inner join
	cities ct 
	on ct.id = c.city_id 
),
hotel_city_cte as (
	select h.id , ct.state
	from hotels h
	inner join
	cities ct 
	on ct.id = h.city_id 
)

select hotel_id , 
count(*) as no_of_bookings_from_other_state
from hotel_bookings hb
inner join hotel_city_cte h 
on hb.hotel_id = h.id 
inner join customer_city_cte c 
on hb.customer_id = c.customer_id 
where h.state != c.state 
group by hotel_id 
order by hotel_id ; 


---------------------------------------------------
--  DATA PREPARATION: Create day-level booking data
---------------------------------------------------
-- Create day-level booking data for occupancy analysis

with cte as (
	select hotel_id , customer_id , stay_start_date , dateadd(day , number_of_nights - 1  , stay_start_date) as stay_end_date 
	from hotel_bookings 
)
,rcte as (
	select hotel_id , customer_id , stay_start_date , stay_end_date 
	from cte 
	union all 
	select hotel_id , customer_id , dateadd(day,1,stay_start_date) , stay_end_date 
	from rcte 
	where dateadd(day,1,stay_start_date) <= stay_end_date

)

select * 
into hotel_bookings_flatten 
from rcte ;


--4- for each hotel find the date when occupancy was maximum 
--(a customer should not be considered in hotel on the checkout date)

select * from(
select hotel_id , stay_start_date , count(*) as no_of_guests,
rank()over(partition by  hotel_id order by count(*) desc) as rn
from hotel_bookings_flatten
group by hotel_id,stay_start_date
)a 
where rn = 1;


--5- find customers who have booked hotels in atleast 3 different states
select hb.customer_id 
from hotel_bookings hb 
inner join hotels h 
on hb.hotel_id = h.id
inner join cities c
on h.city_id = c.id
group by customer_id
having count(distinct state) >= 3 ;

--6- calculate the occupancy rate (percentage of rooms booked in respect of total rooms available) for each hotel for each month
/*
consider the scenario that there can be days in months with zero bookings
Occupancy Rate =
(Total rooms booked) / (Capacity × Days in month)
*/


with booking_cte as (
select hotel_id , stay_start_date as stay_date, count(*) as no_of_occupied_rooms
from hotel_bookings_flatten 
group by hotel_id ,  stay_start_date
)
select 
	b.hotel_id , 
	year(b.stay_date) as stay_year , 
	month(b.stay_date) as stay_month,
	round(sum(b.no_of_occupied_rooms)*100.0 / (max(capacity) * day(eomonth(max(stay_date)))), 2) as occupancy_rate
from booking_cte b 
inner join hotels h 
on b.hotel_id = h.id
group  by b.hotel_id , year(b.stay_date) , month(b.stay_date);


--7- for each hotel find dates when they were fully occupied


with cte as (
select hotel_id , stay_start_date as stay_date , count(*) as no_of_guests
from hotel_bookings_flatten
group by hotel_id , stay_start_date
)
select c.hotel_id , c.stay_date as fully_occupied_days ,c.no_of_guests , h.capacity 
from cte c inner join hotels h 
on c.hotel_id = h.id 
where c.no_of_guests = h.capacity  
order by hotel_id , fully_occupied_days;


--8- which booking channel has generated highest sales for each hotel in each month

with sales_cte as (
select hotel_id , format(booking_date,'yyyyMM') as month_of_booking , booking_channel , sum(per_night_rate * number_of_nights) as sales 
from hotel_bookings 
group by hotel_id , format(booking_date,'yyyyMM') , booking_channel
)
select * from 
(select * ,
rank() over(partition by hotel_id,month_of_booking order by sales desc ) as rnk 
from 
sales_cte) b 
where rnk = 1 
;

--9- find percent share of number of bookings by each booking channel

select booking_channel , count(*) as no_of_bookings ,
round(count(*)*100.0/sum(count(*)) over() ,2) as percentage_booking
from hotel_bookings 
group by booking_channel 
;
--10- for each hotel find the total revenue generated by millenials(born between 1980 and 1996) and  gen z (born after 1996) 

select 
hb.hotel_id , 
sum(case when year(c.dob) between 1980 and 1996 then per_night_rate * number_of_nights 
else 0 end) as revenue_by_millenials , 
sum(
	case when year(c.dob) > 1996 then per_night_rate * number_of_nights 
else 0 end
) as revenue_by_genz
from hotel_bookings hb 
inner join customers  c 
on hb.customer_id = c.customer_id
group by hb.hotel_id ;


--total revenue generated by each customer generation (Millennials and Gen Z)

select case when year(c.dob) between 1980 and 1996 then 'millenials' 
when year(c.dob) > 1996 then 'gen z' end as customer_category
, sum(per_night_rate*number_of_nights) as revenue
from hotel_bookings hb
inner join customers c on hb.customer_id=c.customer_id
group by case when year(c.dob) between 1980 and 1996 then 'millenials' 
when year(c.dob) > 1996 then 'gen z' end;


--11- For each hotel find  the average stay duration

select hotel_id , avg(number_of_nights*1.0) as avg_stay_duration  
from hotel_bookings
group by hotel_id ;


--12- find the average number of days customers book in advance for each hotel.

select hotel_id , AVG(datediff(day, booking_date,stay_start_date)*1.0)  as avg_advanced_booked_days 
from hotel_bookings 
group by hotel_id ;


--13- find customers who never did any booking

select c.* 
from customers c 
left join 
hotel_bookings hb 
on c.customer_id = hb.customer_id
where hb.booking_id is null ;

--another way
select * 
from customers 
where customer_id not in (select customer_id from hotel_bookings);

--14- find customers who stayed in atleast 3 distinct hotel in a same month
--Display  customer name , month and no of bookings.

select customer_id , format(stay_start_date , 'yyyyMM') as month_of_stay , count(distinct hotel_id) as no_of_hotels_stayed,
count(*) as no_of_bookings
from hotel_bookings_flatten 
group by customer_id , format(stay_start_date , 'yyyyMM')
having count(distinct hotel_id) >= 3 
order by no_of_hotels_stayed desc ;

--------------------------------------------------
-- END OF ANALYSIS
--------------------------------------------------
