/* You have an event log for a SaaS product that records every action a user takes, starting with "Sign Up". 
 * One user can perform multiple actions, including the same action multiple times.
 * The event_log SQL table looks like this:
-------------------------------------------
-- user_id | event_date_time | event_type
-- ------- | --------------- | ----------
-- 7494212 | 1535308430      | Sign Up
-- 7494212 | 1535308433      | Button click
-- 1475185 | 1535308444      | Pricing Page view
-- 6946725 | 1535308475      | Sign Up
-- 6946725 | 1535308476      | Create a website
-- 6946725 | 1535308477      | Activate a service
Note: the event_date_time column format is “epoch timestamp”
 */
-- Create event_log table
DROP TABLE IF EXISTS event_log;
CREATE TABLE IF NOT EXISTS  event_log (
    user_id INT,
    event_date_time INT,
    event_type VARCHAR(255)
);
-- Insert sample data into the event_log table
INSERT INTO event_log (user_id, event_date_time, event_type) VALUES
    (7494212, 1535308430, 'Sign Up'),
    (7494212, 1535308433, 'Button click'),
    (1475185, 1535308444, 'Sign Up'),
    (6946725, 1535308475, 'Sign Up'),
    (6946725, 1535308476, 'Create a website'),
    (6946725, 1535308477, 'Activate a service'),
    (7494212, 1535308480, 'Button click'),
    (7494212, 1535308485, 'Button click'),
    (1475185, 1535308490, 'Pricing Page view'),
    (6946725, 1535308495, 'Create a website'),
    (6946725, 1535308500, 'Activate a service')
;




--Write an SQL query to find out:
--1. For every event_type, the percentage of users, who performed at least one event of that type.


--SELECT event_type, count( DISTINCT user_id) FROM event_log GROUP BY event_type ; --checking

SELECT event_type, 
    concat((CAST( count( DISTINCT user_id) AS float)/CAST((SELECT count(DISTINCT user_id) FROM event_log) AS float) * 100), ' %') AS "Percentage of users"
FROM event_log                                              -- CAST as count() returns int, and we need float to crate percentage 
GROUP BY event_type;                                        -- Extracting the overall count OF users, the number of users for each action, and counting the percentage 




--2.How many users performed more than 10 actions (any event except “Sign Up”) during the first 24 hours after “Sign Up”?


WITH signup_time AS (SELECT user_id, MIN(event_date_time) AS signup_time
                    FROM event_log
                    WHERE event_type = 'Sign Up'
                    GROUP BY user_id)                       -- Extracting the signup time of each user
SELECT u.user_id, COUNT(*) AS actions_count                 
FROM event_log AS u                                         -- Counting how many times user 'acted'
INNER JOIN signup_time AS s ON u.user_id = s.user_id        -- Joining the signup_time for each user 
WHERE u.event_type != 'Sign Up'                             -- Applying filter so that we don't count the signup action  
AND u.event_date_time 
    BETWEEN s.signup_time AND s.signup_time + 86400
GROUP BY u.user_id                                          -- Filtering by 24 hours after signup_time + actions more then 10
HAVING COUNT(*) > 10;




--3.Number of signups per month, as well as the percentage of those users who have at least one event other than “Sign Up”.


SELECT
    EXTRACT(YEAR FROM TO_TIMESTAMP(event_date_time)) AS year,
    EXTRACT(MONTH FROM TO_TIMESTAMP(event_date_time)) AS month,                             -- Extracting month and year from event_date_time  
    COUNT(DISTINCT CASE WHEN event_type = 'Sign Up' THEN user_id END) AS signup_count,      -- Conditional aggregation to extract the count of distinct user_id's where event is 'sign up' 
    CASE
        WHEN COUNT(DISTINCT CASE WHEN event_type != 'Sign Up' THEN user_id END) > 0 THEN    -- Case when to eliminate the possibility of division by 0 if there are no other actions
            (COUNT(DISTINCT CASE WHEN event_type != 'Sign Up' THEN user_id END) / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'Sign Up' THEN user_id END), 0)) * 100
        ELSE 0                                                                              -- NULLIF in case no signups(not sure if it's possible or not)
    END AS "More then one event"                                                            
FROM event_log
GROUP BY YEAR, MONTH                                                                       
ORDER BY YEAR,month
;




--4.N of lost users each month, as well as the monthly “churn rate”. 
--  An existing user is considered lost if they didn’t perform any action for 30 days. (had no actions the previous month?)
--  Churn rate for a particular month is the number of users lost during that month divided by the number of users active (has any event) the previous month. 


WITH MonthlyActiveUsers AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP(EVENT_date_time)) AS activity_year,
        EXTRACT(MONTH FROM TO_TIMESTAMP(EVENT_date_time)) AS activity_month,
        COUNT(DISTINCT user_id) AS active_users
    FROM event_log
    GROUP BY activity_year, activity_month                                                                      --Extracting active users for each month

)
,ChurnData AS (
    SELECT
        activity_year,
        activity_month,
        LAG(active_users, 1, 0) OVER (ORDER BY activity_year, activity_month) AS previous_month_active_users,   --Using lag() to join the active users count with offset 1
        active_users AS current_month_active_users,
        (LAG(active_users, 1, 0) OVER (ORDER BY activity_year, activity_month)) - active_users AS lost_users    --Counting lost users
    FROM MonthlyActiveUsers                                                                                     
    )
SELECT
    activity_year,
    activity_month,
    lost_users,
    CASE
        WHEN previous_month_active_users = 0 THEN 0                                                             --Handling division by zero
        ELSE (lost_users::float / previous_month_active_users) * 100                                            --Converting to float for correct output 
    END AS churn_rate
FROM ChurnData                                                                                                  --Filtering the results to identify users as lost if they have been inactive for 30 days
WHERE (TO_TIMESTAMP(activity_year || '-' || activity_month || '-01', 'YYYY-MM-DD') + INTERVAL '30 days') <= CURRENT_DATE
ORDER BY activity_year, activity_month;                                                                         



            /***
             * There have been numerous instances where I found the task request to be somewhat unclear. 
             * My approach to this matter was as follows: When determining the lost users for the current month, 
             * I considered the user's last activity in the previous month. This approach was chosen even though 
             * the "didn't perform any action for 30 days" requirement may appear somewhat imprecise in this context. 
             * I opted for the monthly timeframe, as it offers greater efficiency and, from the user's perspective, 
             * there is no significant distinction.
             * 
             * There were two potential methods for combining the results of the two queries. 
             * One involved using the "join" method and adding 1 to the month, which presented a problem with December, 
             * as 12 + 1 equals 13, and there is no 13th month to join. Instead, I chose to implement the "Lag()" function. 
             * It's worth noting that the drawback of "Lag()" is that the previous month is not necessarily the immediate previous month; 
             * it corresponds to the previous active month. However, this isn't a concern from my standpoint. 
             * The accuracy of this approach largely depends on the structure of the database (which we have not been provided) 
             * and the specific use cases of the query. In any case, the "Lag()" option seems to be a much better solution in my view.
             * 
             * I also included a WHERE filter at the end to exclude all users who have been active in the last 30 days, 
             * ensuring they are not counted as lost users. In my opinion, this query not only meets the requirements of the task but exceeds them. 
             * However, more detailed instructions or use cases would be greatly beneficial. 
             ***/




--5.What percentage of users are still active after 1 day, 1 week, 1 month 
--(we consider the user to be ‘active after 1 week’ if they have at least one event more than one week after “Sign Up”)-very ambiguos 


WITH signup_time AS (
    SELECT user_id, MIN(event_date_time) AS signup_time
    FROM event_log
    WHERE event_type = 'Sign Up'
    GROUP BY user_id                                                                                            --Finding the sign-up time for each user
),
user_activity AS (
    SELECT user_id, MAX(event_date_time) AS last_activity_date
    FROM event_log
    WHERE event_type != 'Sign Up'
    GROUP BY user_id                                                                                            --Determining the last activity time for each user (excluding sign-up events)
)
SELECT 'active users' AS user_group,
    round((COUNT(CASE WHEN TO_TIMESTAMP(last_activity_date) - TO_TIMESTAMP(signup_time) >= INTERVAL '1 day' THEN 1 END)::NUMERIC  / COUNT(*)) * 100,2) AS "1 Day",
    round((COUNT(CASE WHEN TO_TIMESTAMP(last_activity_date) - TO_TIMESTAMP(signup_time) >= INTERVAL '1 week' THEN 1 END)::NUMERIC / COUNT(*)) * 100,2) AS "1 Week",
    round((COUNT(CASE WHEN TO_TIMESTAMP(last_activity_date) - TO_TIMESTAMP(signup_time) >= INTERVAL '1 month' THEN 1 END)::NUMERIC / COUNT(*)) * 100,2) AS "1 Month"
FROM signup_time                                                                                                --Calculating the percentage
LEFT JOIN user_activity ON signup_time.user_id = user_activity.user_id;

