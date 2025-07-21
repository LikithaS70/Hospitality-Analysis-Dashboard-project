use hospitality;
desc dim_date;
select * from dim_date;
SELECT *FROM fact_bookings;
ALTER TABLE dim_date
ADD COLUMN wn INT;
UPDATE dim_date
SET wn = WEEK(date, 1);
ALTER TABLE dim_date ADD COLUMN day_type VARCHAR(10);
ALTER TABLE dim_date DROP COLUMN day_type;
UPDATE dim_date
SET day_type = CASE
  WHEN WEEKDAY(date) >= 5 THEN 'Weekend'
  ELSE 'Weekday'
END;

-- Step 1: Add new column
ALTER TABLE dim_date ADD COLUMN day_type VARCHAR(10);

-- Step 2: Update it using CASE
UPDATE dim_date
SET day_type = CASE 
                 WHEN WEEKDAY(date) >= 5 THEN 'Weekend'
                 ELSE 'Weekday'
               END;

-- Data Cleaning
UPDATE dim_date
SET mmm_yy = DATE_FORMAT(date, '%b-%y');
SHOW COLUMNS FROM dim_date;
-- Only if needed:
-- ALTER TABLE dim_date ADD COLUMN mmm_yy VARCHAR(20);
-- Fill mmm_yy from real date:
ALTER TABLE dim_date
ADD COLUMN mmm_yy VARCHAR(20);
UPDATE dim_date
SET mmm_yy = DATE_FORMAT(date, '%M %Y');

desc dim_hotels;
select * from dim_hotels;
alter table dim_hotels
modify property_name varchar(255), modify category varchar(255),modify city varchar(255);

desc dim_rooms;
select * from dim_rooms;

desc fact_aggregated_bookings;
select * from fact_aggregated_bookings;
ALTER TABLE fact_aggregated_bookings ADD COLUMN check_in_date_clean DATE;
UPDATE fact_aggregated_bookings
SET check_in_date_clean = STR_TO_DATE(check_in_date, '%d-%M-%Y');
ALTER TABLE fact_aggregated_bookings
MODIFY room_category VARCHAR(25);


desc fact_bookings;
select * from fact_bookings;
alter table fact_bookings
modify booking_id varchar(25);
alter table fact_bookings
modify property_id int;
 alter table fact_bookings
modify booking_date date;
alter table fact_bookings
modify check_in_date date;
 alter table fact_bookings
modify checkout_date date;
alter table fact_bookings
 modify no_guests int;
alter table fact_bookings
modify room_category varchar(25), modify booking_platform varchar(25);
ALTER TABLE fact_bookings ADD COLUMN ratings_int INT;

UPDATE fact_bookings
SET ratings_INT = FLOOR(ratings_given)
WHERE ratings_given BETWEEN 0 AND 5;

ALTER TABLE fact_bookings DROP COLUMN ratings_given;
ALTER TABLE fact_bookings CHANGE ratings_INT ratings_given INT;
ALTER TABLE fact_bookings modify booking_status varchar(25), modify revenue_generated int, modify revenue_realized int;

/*select * from fact_bookings where ratings_given = '';
update fact_bookings
set ratings_given = null
where ratings_given = '';
select * from fact_bookings where ratings_given = null;*/

-- KPI's
-- 1.REVENUE
SELECT 
    SUM(revenue_realized) AS Revenue
FROM 
    fact_bookings;#REVENUE
    
    -- 2.OCCUPANCY PERCENT
  SELECT 
    ROUND(
        SUM(successful_bookings) / SUM(capacity) * 100, 
        2
    ) AS occupancy_percent#OCCUPANCY PERCENT
FROM 
    fact_aggregated_bookings;
    
    -- 3. CANCELLATION RATE
    SELECT 
    ROUND(
        SUM(booking_status = 'Cancelled') / COUNT(*) * 100, 
        2
    ) AS cancellation_rate_percent#CANCELLATION RATE
FROM 
    fact_bookings;
    
    -- 4. TOTAL BOOKINGS
SELECT 
    COUNT(booking_id) AS total_bookings
FROM 
    fact_bookings;#TOTAL BOOKING
    
    -- 5.UTILITY CAPACITY
    SELECT 
    ROUND(
        SUM(successful_bookings) / SUM(capacity) * 100, 
        2
    ) AS utility_capacity_percent
FROM 
    fact_aggregated_bookings;#UTILITY CAPACITY
    
    -- Visuals
-- 1) Revenue
-- Class wise revenue
select dr.room_class, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue,
concat(round((sum(fb.revenue_realized)/(select sum(revenue_realized) from fact_bookings))*100,2),' %') as revenue_percentage
from dim_rooms dr join fact_bookings fb
on dr.room_id = fb.room_category
group by dr.room_class;

-- 2. hotel wise revenue
select dh.property_name, concat(round(sum(fb.revenue_realized)/1000000,0),' M') as revenue
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.property_name
order by revenue desc;

-- 3 
-- Total Bookings by Booking Platform 
select booking_platform, concat(round(count(booking_id)/1000),' K') Total_Bookings
from fact_bookings
group by booking_platform
order by Total_Bookings desc;

-- 4
-- Revenue by Booking Platform
select booking_platform, concat(round(sum(revenue_realized)/1000000,0),'M') as revenue
from fact_bookings
group by booking_platform
order by revenue desc;

-- 5.revenue by month
select dm.mmm_yy as Months, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue
from dim_date dm join fact_bookings fb
on dm.date = fb.check_in_date
group by dm.mmm_yy;

-- 6. revenue by city
select dh.city, concat(round(sum(fb.revenue_realized)/1000000), ' M') as revenue
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.city
order by revenue desc;

-- 7.
-- CLASSWISE TOTAL BOOKINGS
SELECT 
  dr.room_class, 
  COUNT(fb.booking_id) AS Total_Bookings
FROM 
  dim_rooms dr 
JOIN 
  fact_bookings fb 
  ON LOWER(dr.room_id) = LOWER(fb.room_category)
GROUP BY 
  dr.room_class
ORDER BY 
  Total_Bookings DESC;
  
-- 8
-- City wise Total Bookings
SELECT 
  dh.city, 
  COUNT(fb.booking_id) AS Total_Bookings
FROM 
  dim_hotels dh 
JOIN 
  fact_bookings fb 
  ON dh.property_id = fb.property_id
GROUP BY 
  dh.city
ORDER BY 
  Total_Bookings DESC;
  
  -- 9
-- Total Checked Out, Total cancelled bookings and Total no show bookings by city
select dh.city,
sum(case when fb.booking_status = 'Checked Out' then 1 end) Total_Checked_Out,
sum(case when fb.booking_status = 'Cancelled' then 1 end) Total_Cancelled,
sum(case when fb.booking_status = 'No Show' then 1 end) Total_No_Show,
count(fb.booking_id) Total_Bookings
from dim_hotels dh join fact_bookings fb
on dh.property_id = fb.property_id
group by dh.city
order by Total_Bookings desc;

-- 10
-- City wise Capacity and Successful Bookings 
select dh.city, sum(capacity) Capacity, sum(successful_bookings) Successful_Bookings
from dim_hotels dh join fact_aggregated_bookings fab
on dh.property_id = fab.property_id
group by dh.city
order by Capacity desc;

-- 11
-- Class wise Capacity and Successful Bookings 
select dr.room_class, sum(capacity) Capacity, sum(successful_bookings) Successful_Bookings
from dim_rooms dr join fact_aggregated_bookings fab
on dr.room_id = fab.room_category
group by dr.room_class
order by Capacity desc;

-- 12
-- Weekday & Weekend Revenue and Total Bookings
SELECT 
    CASE 
        WHEN WEEKDAY(fb.check_in_date) IN (5, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
    ROUND(SUM(fb.revenue_realized) / 1000000, 2) AS Total_Revenue_Millions,
    COUNT(fb.booking_id) AS Total_Bookings
FROM fact_bookings fb
GROUP BY Day_Type
ORDER BY Day_Type;

-- 13
-- A. Weekly Trend Analysis (Revenue)
SELECT 
    WEEK(check_in_date, 1) AS Week_No,
    ROUND(SUM(revenue_realized) / 1000000, 2) AS Weekly_Revenue
FROM fact_bookings
GROUP BY Week_No
ORDER BY Week_No;

-- B. Booking Status Distribution
SELECT booking_status, 
       COUNT(booking_id) AS Total_Bookings,
       ROUND(COUNT(booking_id) / (SELECT COUNT(*) FROM fact_bookings) * 100, 2) AS Percentage
FROM fact_bookings
GROUP BY booking_status;

-- C. Booking Platform Weekly Performance
SELECT booking_platform,
WEEK(check_in_date, 1) AS Week_No,
COUNT(booking_id) AS Total_Bookings
FROM fact_bookings
GROUP BY booking_platform, Week_No
ORDER BY booking_platform, Week_No;
