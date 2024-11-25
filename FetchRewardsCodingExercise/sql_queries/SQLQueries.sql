
-- Top 5 Brands by Receipts Scanned for the Most Recent Month
WITH RecentMonth AS (
    SELECT 
        FORMAT(purchaseDate, 'yyyy-MM') AS month,
        brandId,
        COUNT(DISTINCT receiptId) AS receipt_count
    FROM Receipt_Items
    JOIN Receipts ON Receipt_Items.receiptId = Receipts._id
    WHERE rewardsReceiptStatus = 'FINISHED'
    GROUP BY FORMAT(purchaseDate, 'yyyy-MM'), brandId
),
LatestMonth AS (
    SELECT TOP 1 month
    FROM RecentMonth
    ORDER BY month DESC
)
SELECT TOP 5
    Brands.name AS brand_name,
    RecentMonth.receipt_count
FROM RecentMonth
JOIN LatestMonth ON RecentMonth.month = LatestMonth.month
JOIN Brands ON RecentMonth.brandId = Brands._id
ORDER BY RecentMonth.receipt_count DESC;

-- Comparison of Rankings for Top 5 Brands Between Months
WITH MonthlyReceipts AS (
    SELECT 
        FORMAT(purchaseDate, 'yyyy-MM') AS month,
        brandId,
        COUNT(DISTINCT receiptId) AS receipt_count
    FROM Receipt_Items
    JOIN Receipts ON Receipt_Items.receiptId = Receipts._id
    WHERE rewardsReceiptStatus = 'FINISHED'
    GROUP BY FORMAT(purchaseDate, 'yyyy-MM'), brandId
),
RankedReceipts AS (
    SELECT 
        month,
        brandId,
        receipt_count,
        RANK() OVER (PARTITION BY month ORDER BY receipt_count DESC) AS rank
    FROM MonthlyReceipts
)
SELECT 
    current.brandId,
    Brands.name AS brand_name,
    current.rank AS current_month_rank,
    previous.rank AS previous_month_rank
FROM RankedReceipts AS current
LEFT JOIN RankedReceipts AS previous
    ON current.brandId = previous.brandId
    AND DATEDIFF(MONTH, previous.month, current.month) = 1
JOIN Brands ON current.brandId = Brands._id
WHERE current.rank <= 5;

-- Average Spend from 'Accepted' or 'Rejected' Receipts
SELECT 
    rewardsReceiptStatus,
    AVG(totalSpent) AS average_spend
FROM Receipts
WHERE rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY rewardsReceiptStatus;

-- Total Items Purchased with 'Accepted' or 'Rejected' Receipts
SELECT 
    rewardsReceiptStatus,
    SUM(purchasedItemCount) AS total_items
FROM Receipts
WHERE rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY rewardsReceiptStatus
ORDER BY total_items DESC;

-- Brand with the Most Spend Among Users Created in the Last 6 Months
WITH RecentUsers AS (
    SELECT _id 
    FROM Users
    WHERE DATEDIFF(MONTH, createdDate, GETDATE()) <= 6
),
UserReceipts AS (
    SELECT 
        Receipt_Items.brandId,
        SUM(Receipt_Items.itemSpend) AS total_spend
    FROM Receipt_Items
    JOIN Receipts ON Receipt_Items.receiptId = Receipts._id
    WHERE Receipts.userId IN (SELECT _id FROM RecentUsers)
    GROUP BY Receipt_Items.brandId
)
SELECT TOP 1
    Brands.name AS brand_name,
    total_spend
FROM UserReceipts
JOIN Brands ON UserReceipts.brandId = Brands._id
ORDER BY total_spend DESC;

-- Brand with the Most Transactions Among Users Created in the Last 6 Months
WITH RecentUsers AS (
    SELECT _id 
    FROM Users
    WHERE DATEDIFF(MONTH, createdDate, GETDATE()) <= 6
),
UserReceipts AS (
    SELECT 
        Receipt_Items.brandId,
        COUNT(DISTINCT Receipt_Items.receiptId) AS transaction_count
    FROM Receipt_Items
    JOIN Receipts ON Receipt_Items.receiptId = Receipts._id
    WHERE Receipts.userId IN (SELECT _id FROM RecentUsers)
    GROUP BY Receipt_Items.brandId
)
SELECT TOP 1
    Brands.name AS brand_name,
    transaction_count
FROM UserReceipts
JOIN Brands ON UserReceipts.brandId = Brands._id
ORDER BY transaction_count DESC;
