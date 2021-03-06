
SELECT DISTINCT
  ProductKey,
  CONCAT(RecipientKey, ManufacturerKey, DateKey) AS TransactionID INTO [master].[dbo].IDs
FROM [master].[dbo].FactPaymentTransaction

SELECT
  intersection.*,
  b.TransactionsA,
  c.TransactionsB INTO [master].[dbo].[Combinations]
FROM (SELECT
  ProductA,
  ProductB,
  COUNT(DISTINCT TransactionID) AS Transactions
FROM (SELECT
  a.ProductKey AS ProductA,
  a.TransactionID,
  b.ProductKey AS ProductB
FROM [master].[dbo].IDs AS a
INNER JOIN [master].[dbo].IDs AS b
  ON a.TransactionID = b.TransactionID
WHERE b.ProductKey != a.ProductKey) AS a
GROUP BY ProductA,
         ProductB) AS intersection
LEFT JOIN (SELECT
  ProductKey,
  COUNT(*) AS TransactionsA
FROM [master].[dbo].IDs
GROUP BY ProductKey) AS b
  ON intersection.ProductA = b.ProductKey
LEFT JOIN (SELECT
  ProductKey,
  COUNT(*) AS TransactionsB
FROM [master].[dbo].IDs
GROUP BY ProductKey) AS c
  ON intersection.ProductB = c.ProductKey

ALTER TABLE [master].[dbo].[Combinations]
ADD Total_Transactions real,
Support_A real,
Support_B real,
Support_AB real,
Lift real


UPDATE [master].[dbo].[Combinations]
SET Total_Transactions = (SELECT
  COUNT(DISTINCT CONCAT(RecipientKey, ManufacturerKey, DateKey)) AS Total_Transactions
FROM [master].[dbo].FactPaymentTransaction)

UPDATE [master].[dbo].[Combinations]
SET Support_A = TransactionsA / Total_Transactions,
    Support_B = TransactionsB / Total_Transactions,
    Support_AB = Transactions / Total_Transactions

UPDATE [master].[dbo].[Combinations]
SET Lift = (Support_AB) / (Support_A * Support_B)


SELECT
  *
FROM (SELECT
  b.Product_Name AS ProductA_Name,
  c.Product_Name AS ProductB_Name,
  RANK() OVER (PARTITION BY a.ProductA ORDER BY a.Lift DESC) AS Association_Rank
FROM [master].[dbo].[Combinations] AS a
LEFT JOIN [master].[dbo].DimProduct AS b
  ON a.ProductA = b.ProductKey
LEFT JOIN [master].[dbo].DimProduct AS c
  ON a.ProductB = c.ProductKey
  WHERE TransactionsA > 5 AND TransactionsB > 5 AND Transactions > 5
  AND b.Active_indicator = 1) AS a
WHERE Association_Rank <= 5


DROP TABLE [master].[dbo].IDs
DROP TABLE [master].[dbo].[Combinations]
