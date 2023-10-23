# Event Log Analysis

This SQL script is designed to analyze an event log for a SaaS product, which records various user actions, including "Sign Up." The event log SQL table has three columns: `user_id`, `event_date_time` (in epoch timestamp format), and `event_type`.

## Table Creation and Data Insertion

- The SQL script begins by creating the `event_log` table to store the event data.

- Sample data is then inserted into the `event_log` table to facilitate analysis.

## Analysis Queries

### 1. Percentage of Users for Each Event Type

- The script calculates the percentage of users who have performed at least one event of each event type. It groups the data by event type and calculates the percentage.

### 2. Users Performing More Than 10 Actions After Sign Up

- This query identifies users who have performed more than 10 actions (excluding "Sign Up") within the first 24 hours after signing up. It uses a common table expression (CTE) to find the sign-up time for each user and then counts the actions performed by each user in the first 24 hours.

### 3. Number of Signups per Month and Percentage of Users with Other Events

- This query calculates the number of signups per month and the percentage of users who have performed at least one event other than "Sign Up." It groups the data by month and year, counting signups and users with other events.

### 4. Number of Lost Users and Churn Rate

- This query identifies lost users, defined as users who haven't performed any actions for 30 days. It calculates the monthly churn rate, which is the number of users lost during a month divided by the number of active users in the previous month. The query uses a CTE to first extract active users per month and then calculates lost users and churn rate.

### 5. Percentage of Users Still Active

- This query calculates the percentage of users still active after 1 day, 1 week, and 1 month from their sign-up date. Users are considered active after 1 week if they have at least one event more than one week after signing up. It uses CTEs to find sign-up times and last activity times for users and then calculates the percentages.

This script provides a comprehensive analysis of the event log data, including user engagement, user retention, and churn rates.

Please note that the script assumes that the event_date_time is stored as epoch timestamps and may need adjustments if the data format differs.
