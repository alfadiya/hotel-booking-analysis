#  Hotel Booking Analysis (SQL)

## 📌 Project Overview
This project analyzes hotel booking data using SQL (Microsoft SQL Server).

The goal is to understand booking patterns, customer behavior, and hotel performance by solving real-world business questions.

---

## 📂 Dataset
The dataset consists of multiple tables:

- hotel_bookings
- customers
- hotels
- cities

These datasets include booking details, customer information, hotel capacity, and location data.

---

## 🛠 Data Preparation
- Imported CSV files into SQL Server  
- Structured data into relational tables  
- Cleaned column names and data types  
- Created a day-level dataset (hotel_bookings_flatten) for better analysis  

---

## 🔎 Key Analysis

Some of the business questions explored:

- Booking trends by month  
- Top customers based on same-city bookings  
- Revenue contribution by customer segments  
- Occupancy rate per hotel per month  
- Fully occupied dates for each hotel  
- Booking channel performance  
- Customer travel behavior across states  

---

## 🛠 SQL Concepts Used

- Common Table Expressions (CTEs)  
- Recursive CTE  
- Aggregate Functions  
- Window Functions (RANK)  
- Joins (INNER, LEFT)  
- Date Functions (YEAR, MONTH, DATEDIFF, EOMONTH)  
- Conditional Logic (CASE WHEN)  

---

## 📁 Project Structure

```
hotel-booking-analysis/
│
├── booking_analysis.sql
├── dataset/
│   ├── hotel_bookings.csv
│   ├── customers.csv
│   ├── hotels.csv
│   └── cities.csv
└── README.md
```

## 👩‍💻 Author
Alfadiya Noushad
