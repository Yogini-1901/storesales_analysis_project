use store_sales;


--Identify customers whose total sales are above the average sales of all customers
SELECT Customer_Name, SUM(Sales) AS Total_Sales
FROM Orders$
GROUP BY Customer_Name
HAVING SUM(Sales) > (
        SELECT AVG(CustomerSales)
        FROM (
            SELECT SUM(Sales) AS CustomerSales
            FROM Orders$
            GROUP BY Customer_Name
        ) AS AvgSales
);


--Find the customer who has made the maximum number of  orders in each category:
SELECT Category, Customer_Name, Order_Count
FROM (
    SELECT Category, Customer_Name,
           COUNT(Order_ID) AS Order_Count,
           RANK() OVER (PARTITION BY Category ORDER BY COUNT(Order_ID) DESC) AS rnk
    FROM Orders$
    GROUP BY Category, Customer_Name
) t
WHERE rnk = 1;

--Find the top 3 products in each category based on their sales.
SELECT Category, Product_Name, Total_Sales
FROM (
    SELECT Category, Product_Name,
           SUM(Sales) AS Total_Sales,
           RANK() OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS rnk
    FROM Orders$
    GROUP BY Category, Product_Name
) t
WHERE rnk <= 3;

--Calculate year-over-year (YoY) sales growth  
SELECT 
    YEAR(Order_Date) AS Year,
    SUM(Sales) AS Total_Sales,
    LAG(SUM(Sales)) OVER (ORDER BY YEAR(Order_Date)) AS Previous_Year_Sales,
    ((SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY YEAR(Order_Date)))
     / LAG(SUM(Sales)) OVER (ORDER BY YEAR(Order_Date))) * 100 AS YoY_Growth_Percentage
FROM Orders$
GROUP BY YEAR(Order_Date)
ORDER BY Year;

--Find the most profitable shipping mode for each region
SELECT Region, Ship_Mode, Total_Profit
FROM (
    SELECT Region, Ship_Mode,
           SUM(Profit) AS Total_Profit,
           RANK() OVER (PARTITION BY Region ORDER BY SUM(Profit) DESC) AS rnk
    FROM Orders$
    GROUP BY Region, Ship_Mode
) t
WHERE rnk = 1;

--FUNCTION--
CREATE FUNCTION GetDaysBetweenDates
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(DAY, @StartDate, @EndDate)
END;

---STORE PROCEDURE---
CREATE PROCEDURE GetCustomer_Orders
    @CustomerID NVARCHAR(100)
AS
BEGIN
    SELECT 
        Order_Date,
        Sales,

        COUNT(Order_ID) OVER(PARTITION BY Customer_ID) AS TotalOrders,

        AVG(Sales) OVER(PARTITION BY Customer_ID) AS AvgAmount,

        MAX(Order_Date) OVER(PARTITION BY Customer_ID) AS LastOrderDate,

        dbo.GetDaysBetweenDates(
            MAX(Order_Date) OVER(PARTITION BY Customer_ID),
            GETDATE()
        ) AS DaysSinceLastOrder

    FROM Orders$
    WHERE Customer_ID = @CustomerID
END;

EXEC GetCustomer_Orders @CustomerID = 'AS-10240';
