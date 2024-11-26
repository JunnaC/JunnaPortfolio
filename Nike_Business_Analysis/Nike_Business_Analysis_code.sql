use g4_p


--stored procedure 
--Review, Rating
GO
CREATE OR ALTER PROCEDURE insertReview_qxie
@RatingName varchar(50),
@RatingNumeric numeric(8,2),
@RatingDesc varchar(100),
@ReviewDate DATE,
@Quantity INT,
@shipdate DATE,
@delivereddate DATE,
@carrierName varchar(50),
@OrderDate DATE,
@CFirstName varchar(50),
@CLastName Varchar(50),
@CDOB DATE,
@CustomerType varchar(50),
@OrderTypeName varchar(50),
@OrderTypeDesc varchar(100),
@EFirstName varchar(50),
@ELastName Varchar(50),
@EDOB DATE,
@EmployeeType varchar(50),
@StoreName varchar(50),
@StoreTypeName varchar(50),
@StoreTypeDesc varchar(100),
@productName VARCHAR(50),
@price numeric(8,2),
@ProductTypeName varchar(50),
@ProductTypeDesc VARCHAR (100)
AS
DECLARE @RatingID INT, @OrderProdID INT


SET @RatingID = (SELECT RatingID FROM tblRating WHERE RatingName = @RatingName AND RatingNumeric = @RatingNumeric AND RatingDescr = @RatingDesc)
IF @RatingID IS NULL
 BEGIN
     PRINT ' @RatingID is empty, check spelling';
     THROW 54322, ' @RatingID cannot be null', 1;
 END
SET @OrderProdID = (SELECT OP.OrderProdID FROM tblOrderProduct OP
                                       JOIN tblProduct P ON OP.ProductID = P.ProductID
                                       JOIN tblDelivery D ON OP.DeliveryID = D.DeliveryID
                                       JOIN tblOrder O ON OP.OrderID = O.OrderID
                                       JOIN tblCustomer C ON O.CustomerID = C.CustomerID
                                       JOIN tblEmployee E ON O.EmployeeID = E.EmployeeID
                                       JOIN tblStore S ON O.StoreID = S.StoreID
                                       JOIn tblStoreType ST ON S.StoreTypeID = ST.StoreTypeID
                                       JOIN tblOrderType OT ON O.OrderTypeID = OT.OrderTypeID
                                       JOIN tblCustomerType CT ON C.CustomerTypeID = CT.CustomerTypeID
                                       JOIN tblEmployeeType ET ON E.EmployeeTypeID = ET.EmployeeTypeID
                                       JOIN tblCarrier CA ON D.CarrierID = CA.CarrierID
                                       JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
                                      
                   WHERE OP.Quantity = @Quantity
                   AND O.OrderDate = @OrderDate
                   AND C.Fname = @CFirstName
                   AND C.Lname = @CLastName
                   AND C.DOB = @CDOB
                   AND E.Fname = @EFirstName
                   AND E.Lname = @ELastName
                   AND E.DOB = @EDOB
                   AND CT.CustomerTypeName = @CustomerType
                   AND ET.EmployeeTypeName = @EmployeeType
                   AND S.StoreName = @StoreName
                   AND ST.StoreTypeName = @StoreTypeName
                   AND ST.StoreTypeDescr = @StoreTypeDesc
                   AND OT.OrderTypeName = @OrderTypeName
                   AND OT.OrderTypeDescr = @OrderTypeDesc
                   AND D.DeliveredDate = @delivereddate
                   AND D.ShippedDate = @shipdate
                   AND CA.CarrierName = @carrierName
                   AND P.ProductName = @productName
                   AND P.Price = @price
                   AND PT.ProductTypeName = @ProductTypeName
                   )
IF @OrderProdID  IS NULL
 BEGIN
     PRINT ' @OrderProdID  is empty, check spelling';
     THROW 54323, ' @OrderProdID  cannot be null', 1;
 END


BEGIN TRANSACTION T1


INSERT INTO tblReview(OrderProdID, RatingID, ReviewDate)
VALUES (@OrderProdID, @RatingID, @ReviewDate)
IF @@ERROR <> 0
 BEGIN
     ROLLBACK TRANSACTION T1
 END
ELSE
 COMMIT TRANSACTION T1


GO


/*
SELECT * FROM tblRating


 */


--Delivery, Carrier
GO
CREATE OR ALTER PROCEDURE insertDelivery_qxie
@shipdate DATE,
@delivereddate DATE,
@carrierName varchar(50)
AS
DECLARE @cID INT


SET @cID = (SELECT CarrierID FROM tblCarrier WHERE carrierName = @carrierName )


IF @cID IS NULL
 BEGIN
     PRINT '@cID is empty, check spelling';
     THROW 54321, '@cID cannot be null', 1;
 END


BEGIN TRANSACTION T1


INSERT INTO tblDelivery(CarrierID, ShippedDate, DeliveredDate)
VALUES (@CID, @shipdate, @delivereddate)
IF @@ERROR <> 0
 BEGIN
     ROLLBACK TRANSACTION T1
 END
ELSE
 COMMIT TRANSACTION T1


GO


-- business rule
--No employee under the age of 14 may work in washington state
GO
CREATE OR ALTER FUNCTION fn_noUnderageWA_qxie()
RETURNS INTEGER
AS
BEGIN
DECLARE @RET INTEGER = 0
IF EXISTS (SELECT *
   FROM tblEmployee E
   JOIN tblOrder O ON E.EmployeeID = O.EmployeeID
   JOIN tblStore S ON O.StoreID = S.StoreID
   WHERE S.StoreName = '%WA%'
   AND E.DOB > DATEADD(YEAR, -14, GETDATE())
   )
BEGIN
   SET @RET = 1
END
RETURN @RET
END
GO


ALTER TABLE tblEmployee
ADD CONSTRAINT CK_NoKids
CHECK (dbo.fn_noUnderageWA_qxie() = 0)


--No customer can order more than 10 products labeled “limited edition”
GO
CREATE OR ALTER FUNCTION fn_no10limited_qxie()
RETURNS INTEGER
AS
BEGIN
DECLARE @RET INTEGER = 0
IF EXISTS (SELECT C.CustomerID, count(*) AS numProduct
           FROM tblCustomer C
           JOIN tblOrder O ON C.CustomerID = O.CustomerID
           JOIN tblOrderProduct OP On O.OrderID = OP.OrderID
           JOIN tblProduct P ON OP.ProductID = P.ProductID
           JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
           WHERE PT.ProductTypeName = 'Limited Edition'
           GROUP BY C.CustomerID
           HAVING count(*) > 10
)
BEGIN
   SET @RET = 1
END
RETURN @RET
END
GO


ALTER TABLE tblCustomer
ADD CONSTRAINT CK_Nolimited
CHECK (dbo.fn_no10limited_qxie() = 0)






--Computer columns
--How many total products are there that is a hoodie under $20 in each store
GO
CREATE OR ALTER FUNCTION fn_totalProduct10andOver20 (@PK INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT COUNT(*)
                   FROM tblProduct P
                   JOIN tblOrderProduct OP ON P.ProductID = OP.ProductID
                   JOIN tblOrder O ON OP.OrderID = O.OrderID
                   JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
                   JOIN tblStore S ON O.StoreID = S.StoreID
                   WHERE PT.ProductTypeName = 'Hoodie'
                   AND P.Price < 20
                   AND S.StoreID = @PK


)
RETURN @RET
END
GO


ALTER TABLE tblStore
ADD HoodieU20
AS (dbo.fn_totalProduct10andOver20(StoreID))
GO


select * from tblCustomer


--How many $50 shoes have each customers spend on
GO
CREATE OR ALTER FUNCTION fn_totalCustomer50Shoes(@PK INT )
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT COUNT(*)
               FROM tblCustomer C
               JOIN tblOrder O ON C.CustomerID = O.CustomerID
               JOIN tblOrderProduct OP On O.OrderID = OP.OrderID
               JOIN tblProduct P ON OP.ProductID = P.ProductID
               JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
               WHERE P.Price > 50
               AND PT.ProductTypeName = 'Shoes'
               AND C.CustomerID = @PK
)
RETURN @RET
END
GO


ALTER TABLE tblCustomer
ADD TotalShoesOver50
AS (dbo.fn_totalCustomer50Shoes(CustomerID))
GO


select CustomerID, Fname, Lname, DOB, TotalShoesOver50  from tblCustomer


--Views
--Select the top 10 stores that have the highest revenue over the years 2010 - 2015
GO
CREATE OR ALTER VIEW vw_top10storeRev AS
   SELECT S.StoreName, SUM(P.price) AS totalRevenue
   FROM tblStore S
       JOIN tblOrder O ON S.StoreID = O.StoreID
       JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
       JOIN tblProduct P ON OP.ProductID = P.ProductID
   WHERE O.Orderdate BETWEEN '2010-01-01' AND '2015-12-31'
   GROUP BY S.StoreName


GO
SELECT TOP 10 *
FROM vw_top10storeRev
ORDER BY totalRevenue DESC


--Select the 99 percentile users with the highest purchase


GO
CREATE OR ALTER VIEW vw_99PtileCustomer AS
   SELECT C.Fname, C.Lname, SUM(P.price) AS totalSpent,
    NTILE(100) OVER (ORDER BY SUM(P.price) DESC) AS ntileGroup
   FROM tblCustomer C
       JOIN tblOrder O ON C.CustomerID = O.CustomerID
       JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
       JOIN tblProduct P ON OP.ProductID = P.ProductID
   GROUP BY  C.Fname, C.Lname
GO
SELECT *
FROM vw_99PtileCustomer
WHERE ntileGroup = 99



– Stored procedures
GO
CREATE OR ALTER PROCEDURE uspINSERT_Product
@Pname VARCHAR(100),
@pricey NUMERIC (10, 2),
@PT_Name VARCHAR(50),
@PT_Descr VARCHAR(100)


AS
DECLARE @P_ID INT, @PT_ID INT






SET @P_ID = (SELECT ProductID
          FROM tblPRODUCT P
          JOIN tblProductType PT ON P.ProductTypeID = P.ProductTypeID
         WHERE ProductName = @Pname
         AND Price = @pricey
)




IF @P_ID IS NULL
 BEGIN
     PRINT '@PT_ID is empty, check spelling';
     THROW 65321, '@PT_ID cannot be null', 1;
 END






SET @PT_ID = (SELECT ProductTypeID
         FROM tblProductType
         WHERE ProductTypeName = @PT_Name
         AND ProductDescr = @PT_Descr
)




IF @PT_ID IS NULL
 BEGIN
     PRINT '@PT_ID is empty, check spelling';
     THROW 65321, '@PT_ID cannot be null', 1;
 END




BEGIN TRANSACTION G1
INSERT INTO tblProduct (ProductID, ProductName, Price, ProductTypeID)
VALUES (@P_ID, @PName, @Pricey, @PT_ID)
IF @@ERROR <> 0
 BEGIN
     ROLLBACK TRANSACTION G1
 END
ELSE
 COMMIT TRANSACTION G1




GO




select * from tblCartProduct




GO
CREATE OR ALTER PROCEDURE uspINSERT_CartProduct
@pname varchar(50),
@pricey NUMERIC (8,2),
@datey Date,
@quant NUMERIC ,
@status VARCHAR(10)
AS
DECLARE @P_ID INT, @C_ID INT, @CP_ID INT
SET @CP_ID = (SELECT CartProductID
            FROM tblCartProduct
            WHERE UpdateDate = @Datey
            AnD Quantity = @quant          
              )
IF @CP_ID IS NULL
BEGIN
    PRINT '@CP_ID is empty, check spelling';
    THROW 65321, '@CP_ID cannot be null', 1;
END
SET @P_ID = (SELECT P.ProductID
            FROM tblCartProduct CP
             JOIN tblProduct P ON P.ProductID = CP.ProductID
            WHERE ProductName = @pname
            AnD Price = @pricey
              )




IF @P_ID IS NULL
BEGIN
    PRINT '@P_ID is empty, check spelling';
    THROW 65321, '@P_ID cannot be null', 1;
END




SET @C_ID = (SELECT C.CartID
          FROM tblCartProduct CP
          JOIN tblCart C ON C.CartID = CP.CartID
          WHERE CartStatus = @status
        
          )


IF @C_ID IS NULL
BEGIN
    PRINT '@C_ID is empty, check spelling';
    THROW 65321, '@C_ID cannot be null', 1;
END


BEGIN TRANSACTION G1
INSERT INTO tblCartProduct (CartProductID, UpdateDate, Quantity, ProductID, CartID)
VALUES (@CP_ID, @datey, @quant, @P_ID, @C_ID)
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION G1
END
ELSE
COMMIT TRANSACTION G1


GO


--Business Rule
--No store can have less than 7 employees working at the same time.


CREATE FUNCTION fn_emp_7()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT COUNT(*)
        FROM tblEmployee E
        JOIN tblOrder O ON O.EmployeeID = E.EmployeeID
        JOIN tblStore S ON S.StoreID = O.StoreID
        GROUP BY E.EmployeeID
        HAVING COUNT(*) < 7 )


SET @RET =1
RETURN @RET
END
GO




ALTER TABLE tblStore
ADD CONSTRAINT CK_Store_noless7
CHECK(dbo.fn_emp_7() =1)
GO




-- No employee in WA  with a hire date of less than one year can get a discount on items.
CREATE FUNCTION fn_hire_emp_1year_discount()
RETURNS INT
AS
BEGIN




DECLARE @RET INT = 0


IF EXISTS (
     SELECT 1
     FROM tblEmployee E
     JOIN tblOrder O ON E.EmployeeID = O.EmployeeID
     JOIN tblStore S ON O.StoreID = S.StoreID
     WHERE S.StoreName = '%WA%' -- Employees in Washington
     AND E.HireDate > DATEADD(YEAR, -1, GETDATE()) -- Hire date within the last year
 )
SET @RET =1
RETURN @RET
END
GO




ALTER TABLE tblEmployee
ADD CONSTRAINT CK_nohire_1yeardiscount
CHECK(dbo.fn_hire_emp_1year_discount() = 0)
GO
--Computer Columns 
-- How many total employees that are 20 years old currently 2023      
CREATE FUNCTION fn_totalEmp_20_2023(@PK INT )
RETURNS INT
AS
BEGIN


DECLARE @RET INT = (SELECT COUNT(*)
                  FROM tblEmployee E
                  WHERE DATEDIFF(YEAR, DOB, '2023-01-01') = 20 --20 years old as of January 1, 2023
                  AND E.EmployeeID = @PK
)
SET @RET =1
RETURN @RET
END
GO


ALTER TABLE tblEmployee
ADD TotalEmp
AS (dbo.fn_totalEmp_20_2023(EmployeeID))
GO


-- How many total customers have bought more than 100 dollars worth of product in each store
GO


CREATE or alter FUNCTION fn_total_100(@PK INT )
RETURNS INT
AS
BEGIN
DECLARE @RET INT = (SELECT COUNT(DISTINCT C.CustomerID) AS TotalCustomersOver100Dollars
FROM tblOrderProduct op
JOIN tblOrder o ON op.OrderID = o.OrderID
JOIN tblProduct p ON op.ProductID = p.ProductID
JOIN tblCustomer c ON o.CustomerID = c.CustomerID
WHERE op.Quantity * p.Price > 100)
SET @RET =1
RETURN @RET
END
GO




ALTER TABLE tblStore
ADD Total_100
AS (dbo.fn_total_100(StoreID))
GO






--views
--Select the employee that has worked the longest
GO
CREATE OR ALTER VIEW LongestWorkingEmployee
AS
SELECT TOP 1 EmployeeID, Fname, Lname, HireDate, DATEDIFF(DAY, HireDate, GETDATE()) AS DaysWorked
FROM tblEmployee
ORDER BY DATEDIFF(DAY, HireDate, GETDATE()) DESC


select * from tblEmployee




--Select the customer that has purchased the most of product (monetary)
GO
CREATE OR ALTER VIEW CustomerMostPurchases AS
SELECT TOP 1 WITH TIES
  c.CustomerID,
  c.Fname,
  c.Lname,
  SUM(op.Quantity * p.Price) AS TotalSpent
FROM tblCustomer c
INNER JOIN tblOrder o ON c.CustomerID = o.CustomerID
INNER JOIN tblOrderProduct op ON o.OrderID = op.OrderID
INNER JOIN tblProduct p ON op.ProductID = p.ProductID
GROUP BY c.CustomerID, c.Fname, c.Lname
ORDER BY SUM(op.Quantity * p.Price) DESC
GO





-- stored procedure
-- sp insert customer
CREATE OR ALTER PROCEDURE insert_Customers
@custFname VARCHAR(50),
@custLname VARCHAR(50),
@custDOB DATE,
@custAddress VARCHAR(500),
@custCity VARCHAR(75),
@custState VARCHAR(25),
@custZip VARCHAR(25),
@custEmail VARCHAR(75),
@getCustomerTypeName VARCHAR(50)
AS
-- declare fk
DECLARE @CustomerTypeID INT




-- get fks
SET @CustomerTypeID = (
  SELECT CustomerTypeID
  FROM tblCustomerType
  WHERE CustomerTypeName = @getCustomerTypeName
)


IF @CustomerTypeID IS NULL
BEGIN
  PRINT '@CustomerTypeID is empty...check spelling';
  THROW 65451, '@CustomerTypeID cannot be NULL',1;
END




BEGIN TRANSACTION T1
  INSERT INTO tblCustomer(Fname, Lname, DOB, Address, City, [State], Zip, Email, CustomerTypeID )
  VALUES(@custFname, @custLname, @custDOB, @custAddress, @custCity, @custState, @custZip, @custEmail, @CustomerTypeID)


  IF @@ERROR <> 0
      BEGIN
          ROLLBACK TRANSACTION T1
      END
  ELSE
      COMMIT TRANSACTION T1
GO




-- sp: orderstatus
CREATE OR ALTER PROCEDURE insert_OrderStatus
@StoreName VARCHAR(50),
@EFname VARCHAR(50),
@ELname VARCHAR(50),
@CEmail VARCHAR(75),
@StatusName VARCHAR(50)
AS
-- declare fk
DECLARE @OrderID INT, @StatusID INT




-- get fks
SET @OrderID = (
  SELECT TOP 1 OrderID
  FROM tblOrder O
      JOIN tblStore S on O.StoreID = S.storeID
      JOIN tblEmployee E ON O.EmployeeID = E.EmployeeID
      JOIN tblCustomer C ON O.CustomerID = C.CustomerID
  WHERE S.StoreName = @StoreName
  AND E.Fname = @EFname
  AND E.Lname = @ELname
  AND C.Email = @CEmail
)




IF @OrderID IS NULL
BEGIN
  PRINT '@OrderID is empty...check spelling';
  THROW 65451, '@OrderID cannot be NULL',1;
END




SET @StatusID = (
  SELECT StatusID
  FROM tblStatus
  WHERE StatusName = @StatusName
)




IF @StatusID IS NULL
BEGIN
  PRINT '@StatusID is empty...check spelling';
  THROW 65451, '@StatusID cannot be NULL',1;
END




BEGIN TRANSACTION T1
  INSERT INTO tblOrderStatus(OrderID, StatusID)
  VALUES(@OrderID, @StatusID)




  IF @@ERROR <> 0
      BEGIN
          ROLLBACK TRANSACTION T1
      END
  ELSE
      COMMIT TRANSACTION T1
GO




-- syn-trx-order-status
CREATE OR ALTER PROCEDURE wrapper_insert_OrderStatus
@run INT
AS
DECLARE
@StoreName VARCHAR(50),
@EFname VARCHAR(50),
@ELname VARCHAR(50),
@CEmail VARCHAR(75),
@StatusName VARCHAR(50)
DECLARE @OrderPK INT, @StatusPK INT
DECLARE @OrderCount INT = (SELECT COUNT(*) FROM tblOrder)
DECLARE @StatusCount INT = (SELECT COUNT(*) FROM tblStatus)




WHILE @run > 0
BEGIN
  SET @OrderPK = (SELECT RAND() * @OrderCount + 1)
  SET @StatusPK = (SELECT RAND() * @StatusCount + 1)




  SET @StoreName = (
      SELECT StoreName
      FROM tblStore S
      JOIN tblOrder O ON S.StoreID = O.StoreID
      WHERE O.OrderID = @OrderPK
  )




  SET @EFname = (
      SELECT Fname
      FROM tblEmployee E
      JOIN tblOrder O on E.EmployeeID = O.EmployeeID
      WHERE O.OrderID = @OrderPK
  )




  SET @ELname = (
      SELECT Lname
      FROM tblEmployee E
      JOIN tblOrder O on E.EmployeeID = O.EmployeeID
      WHERE O.OrderID = @OrderPK
  )




  SET @CEmail = (
      SELECT Email
      FROM tblCustomer C
      JOIN tblOrder O on C.CustomerID = O.CustomerID
      WHERE O.OrderID = @OrderPK
  )




  SET @StatusName = (
      SELECT StatusName
      FROM tblStatus S
      WHERE S.StatusID = @StatusPK
  )




  EXEC insert_OrderStatus
  @StoreName = @StoreName,
  @EFname = @EFname,
  @ELname = @ELname,
  @CEmail = @CEmail,
  @StatusName = @StatusName




  SET @run = @run -1
END
GO




-- business rule
-- No carrier can take more than 10000 shipment in the Christmas shopping season in 2022 (11/24/2022 - 12/31/2022)


CREATE OR ALTER FUNCTION fn_no_carrier_order()
RETURNS INT
AS
BEGIN
   DECLARE @RET INT = 0
   IF EXISTS (
     
       SELECT C.CarrierID
       FROM tblCarrier C
       JOIN tblDelivery D on C.CarrierID = D.CarrierID
       WHERE ShippedDate BETWEEN '11/24/2022' AND '12/31/2022'
       GROUP BY C.CarrierID
       HAVING COUNT(*) > 10000
   )
   SET @RET = 1


   RETURN @RET
END
GO


ALTER TABLE tblCarrier
ADD CONSTRAINT CK_NoShipment
CHECK (dbo.fn_no_carrier_order() = 0)
GO
-- Only customers with membership can order more than five products within 1 order in the Christmas shopping season in 2022 (11/24/2022 - 12/31/2022)


CREATE FUNCTION fn_membership_purchase()
RETURNS INT
AS
BEGIN
  DECLARE  @RET INT = 0
  IF EXISTS (
      SELECT O.CustomerID
      FROM tblCustomer C
      JOIN tblCustomerType CT ON C.CustomerTypeID = CT.CustomerTypeID
      JOIN tblOrder O ON C.CustomerID = O.CustomerID
      JOIN (
          SELECT OrderID, COUNT(*) AS ProductCount
          FROM tblOrderProduct
          GROUP BY OrderID
      ) OP ON O.OrderID = OP.OrderID
      JOIN tblProduct P ON OP.OrderID = P.ProductID
      WHERE CT.CustomerTypeName = 'Non-Member'
      AND O.OrderDate BETWEEN '2022-11-24' AND '2022-12-31'
      AND OP.ProductCount > 5
  )
  SET @RET = 1
  RETURN @RET
END
GO




ALTER TABLE tblOrder
ADD CONSTRAINT CK_NoNonMemberPurchase
CHECK (dbo.fn_membership_purchase() = 0)
GO








-- computed column
-- CASE statement labeling customer loyalty based on the number of products they have purchased
-- If they have purchased more than 25 products, mark them as first tier
-- If they have purchased between 10 and 15 products, mark them as second tier
-- If they have purchased between 3 and 10 products, mark them as third tier
-- If they have purchased fewer than 3 products, mark them as fourth tier




CREATE OR ALTER FUNCTION fn_GetLoyaltyTier (@CustomerID INT)
RETURNS VARCHAR(50)
AS
BEGIN
  DECLARE @Tier VARCHAR(50)
  DECLARE @ProductCount INT
  SET @ProductCount = (
      SELECT COUNT(*)
      FROM tblOrderProduct OP
      INNER JOIN tblOrder O ON OP.OrderID = O.OrderID
      WHERE O.CustomerID = @CustomerID
  )
  IF @ProductCount > 25
      SET @Tier = 'First Tier'
  ELSE IF @ProductCount BETWEEN 10 AND 15
      SET @Tier = 'Second Tier'
  ELSE IF @ProductCount BETWEEN 3 AND 10
      SET @Tier = 'Third Tier'
  ELSE
      SET @Tier = 'Fourth Tier'
  RETURN @Tier
END
GO
ALTER TABLE tblCustomer
ADD LoyaltyTier AS dbo.fn_GetLoyaltyTier(CustomerID)
GO


-- What’s the total number of `kids` product were brought by non-members


CREATE OR ALTER FUNCTION fn_CountKidsProd (@CustomerID INT)
RETURNS INT
AS
BEGIN
  DECLARE @RET INT = (
      SELECT COUNT(*)
      FROM tblOrder O
      JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
      JOIN tblProduct P ON OP.ProductID = P.ProductID
      JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
      JOIN tblCustomer C ON O.CustomerID = C.CustomerID
      JOIN tblCustomerType CT ON C.CustomerTypeID = CT.CustomerTypeID
      WHERE CT.CustomerTypeName = 'non-Member'
      AND PT.ProductTypeName LIKE '%Kids%'
      AND C.CustomerID = @CustomerID
  )
  RETURN @RET
END
GO




ALTER TABLE tblCustomer
ADD AccessoryCount AS dbo.fn_CountKidsProd(CustomerID)


GO
-- select * from tblCustomer C
-- where C.CustomerTypeID = 2


-- select * from tblProductType












-- view
-- Which customers are between the top 20% and 30% in the money spent on women’s clothing in the year 2022
CREATE OR ALTER VIEW vw_ranking_womenCloth_2022
AS
SELECT C.CustomerID, C.Fname, C.Lname,  SUM(P.Price * OP.Quantity) AS MoneySpent,
       Ntile(100) OVER (ORDER BY SUM(P.Price * OP.Quantity) DESC) AS Percentile
FROM tblCustomer C
JOIN tblOrder O ON C.CustomerID = O.CustomerID
JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
JOIN tblProduct P ON OP.ProductID = P.ProductID
JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
WHERE PT.ProductTypeName LIKE '%women%'
AND YEAR(O.OrderDate) = 2022
GROUP BY C.CustomerID, C.Fname, C.Lname


GO
SELECT * from vw_ranking_womenCloth_2022
WHERE Percentile BETWEEN 20 AND 30
GO


-- Which state has the highest cumulative dollar spent on `shoes` (product type) in the year 2021
CREATE OR ALTER VIEW vw_highest_spending_state_2021 AS
SELECT C.State, SUM(P.Price * OP.Quantity) AS TotalSpentOnShoes
FROM tblCustomer C
JOIN tblOrder O ON C.CustomerID = O.CustomerID
JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
JOIN tblProduct P ON OP.ProductID = P.ProductID
JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
WHERE PT.ProductTypeName LIKE '%shoes%'
AND YEAR(O.OrderDate) = 2021
GROUP BY C.State
GO




SELECT TOP 1 *
FROM vw_highest_spending_state_2021
ORDER BY TotalSpentOnShoes DESC




-- Stored Procedure
-- insert employee
CREATE or ALTER PROCEDURE uspINSERT_EMPLOYEE
@spEFName VARCHAR(50),
@spELName VARCHAR(50),
@spEDOB DATE,
@spEHireDate DATE,
@spETypeName VARCHAR(50)
AS
DECLARE @ET_ID INT


SET @ET_ID = (
    SELECT EmployeeTypeID
    FROM tblEmployeeType
    WHERE EmployeeTypeName = @spETypeName)


IF @ET_ID IS NULL
    BEGIN
        PRINT '@ET_ID is empty...check spelling';
        THROW 65451, '@ET_ID cannot be NULL',1;
    END


BEGIN TRANSACTION Emp
INSERT INTO tblEmployee (Fname, Lname, DOB, HireDate, EmployeeTypeID)
VALUES (@spEFName, @spELName, @spEDOB, @spEHireDate, @ET_ID)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION Emp
    END
ELSE
    COMMIT TRANSACTION Emp
GO




-- Insert store
CREATE or ALTER PROCEDURE uspINSERT_STORE
@spStoreName VARCHAR(50),
@spSTypeName VARCHAR(50),
@spSTypeDescr VARCHAR(100)
AS
DECLARE @ST_ID INT


SET @ST_ID = (
    SELECT StoreTypeID
    FROM tblStoreType
    WHERE StoreTypeName = @spSTypeName
    AND StoreTypeDescr = @spSTypeDescr)


IF @ST_ID IS NULL
    BEGIN
        PRINT '@ST_ID is empty...check spelling';
        THROW 65452, '@ST_ID cannot be NULL',1;
    END
BEGIN TRANSACTION Store
INSERT INTO tblStore (StoreName, StoreTypeID)
VALUES (@spStoreName, @ST_ID)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION Store
    END
ELSE
    COMMIT TRANSACTION Store
GO
-- Business rules
-- No customer can be younger than 14 years old as a member, and get help from store manager who is younger than 25 years old
CREATE or ALTER FUNCTION fn_NoCustm14_Manag25()
RETURNS INTEGER
AS
BEGIN
    DECLARE @RET INTEGER = 0
    IF EXISTS (SELECT *
    FROM tblCustomer C
        JOIN tblCustomerType CT ON C.CustomerTypeID = CT.CustomerTypeID
        JOIN tblOrder O ON C.CustomerID = O.CustomerID
        JOIN tblEmployee E ON O.EmployeeID = E.EmployeeID
        JOIN tblEmployeeType ET ON E.EmployeeTypeID = ET.EmployeeTypeID
    WHERE DATEDIFF(YEAR, C.DOB, GETDATE()) <= 14
    AND DATEDIFF(YEAR, E.DOB, GETDATE()) <= 25
    AND ET.EmployeeTypeName = 'Store Manager'
    AND CT.CustomerTypeName = 'Member')
    BEGIN
        SET @RET = 1
    END
    RETURN @RET
END
GO
ALTER TABLE tblCustomer
ADD CONSTRAINT CK_NoCust14_Mana25
CHECK (dbo.fn_NoCustm14_Manag25() = 0)




-- No order which is placed after 2020-01-01 should contain the product which price is more than 17500
CREATE or ALTER FUNCTION fn_NoOrder20200101()
RETURNS INTEGER
AS
BEGIN
    DECLARE @RET INTEGER = 0
    IF EXISTS (SELECT *
    FROM tblOrder O
        JOIN tblOrderStatus OS ON O.OrderID = OS.OrderID
        JOIN tblStatus S ON OS.StatusID = S.StatusID
        JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
        JOIN tblProduct P ON OP.ProductID = P.ProductID
    WHERE P.price >= 17500
    AND O.OrderDate > '2020-01-01')
    BEGIN
        SET @RET = 1
    END
    RETURN @RET
END
GO
ALTER TABLE tblOrder
ADD CONSTRAINT CK_NoOrder20200101
CHECK (dbo.fn_NoOrder20200101() = 0)
GO
SELECT * FROM tblOrder
GO


-- Computed column
-- how many customers who are older than 50 years and have spent over $200 on order are Nike Member
CREATE OR ALTER FUNCTION fn_customerAgeMember(@PKCID INT)
RETURNS INT
AS
BEGIN
   DECLARE @RET INT = (
       SELECT COUNT(*)
       FROM tblCustomer C
       JOIN tblCustomerType CT ON C.CustomerTypeID = CT.CustomerTypeID
       JOIN tblOrder O ON C.CustomerID = O.CustomerID
       JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
       JOIN tblProduct P ON OP.ProductID = P.ProductID
       WHERE DATEDIFF(YEAR, C.DOB, GETDATE()) > 50
           AND CT.CustomerTypeName = 'Member'
           AND CT.CustomerTypeID = @PKCID
           AND (P.Price * OP.Quantity) > 200
   )
   RETURN @RET
END
GO
-- How many order has the status delivered after 2020-01-01
CREATE OR ALTER FUNCTION fn_orderDeli2000(@PKSID INT)
RETURNS INT
AS
BEGIN
   DECLARE @RET INT = (
    SELECT COUNT(*)
    FROM tblOrder O
        JOIN tblOrderStatus OS ON O.OrderID = OS.OrderID
        JOIN tblStatus S ON OS.StatusID = S.StatusID
    WHERE O.OrderDate > '2000-01-01'
    AND S.StatusName = 'Delivered'
    AND S.StatusID = @PKSID
   )
   RETURN @RET
END
GO
ALTER TABLE tblStatus
ADD orderDeli2000 AS (dbo.fn_orderDeli2000(StatusID));
SELECT * FROM tblStatus
GO




-- View
-- The customer has the highest cost for Nike shoes in Washington state
CREATE OR ALTER VIEW vw_CustHighestCostNikeWashington AS
SELECT C.CustomerID, C.Fname, O.OrderID, P.ProductID, OP.Quantity, P.Price, C.State, O.OrderDate,
    DENSE_RANK() OVER (ORDER BY SUM(OP.Quantity * P.Price) DESC) AS CostRank
FROM tblCustomer C
    JOIN tblOrder O ON C.CustomerID = O.CustomerID
    JOIN tblOrderProduct OP ON O.OrderID = OP.OrderID
    JOIN tblProduct P ON OP.ProductID = P.ProductID
    JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
WHERE PT.ProductTypeName LIKE '%Shoe%'
AND C.State LIKE '%Washington%'
GROUP BY C.CustomerID, C.Fname, O.OrderID, P.ProductID, OP.Quantity, P.Price, C.State, O.OrderDate;
GO
SELECT *
FROM vw_CustHighestCostNikeWashington
WHERE CostRank = 1;
GO
-- Rank the employees onboarding length and age is between 30 to 40, return with job title
CREATE VIEW vw_EmpOnboardingRanking AS
SELECT E.EmployeeID, E.Fname, ET.EmployeeTypeName,
    DATEDIFF(MONTH,E.HireDate, GETDATE()) AS OnboardingLength,
    DENSE_RANK() OVER (ORDER BY DATEDIFF(MONTH, E.HireDate,  GETDATE()) DESC) AS OnboardingRank
FROM tblEmployee E
    JOIN tblEmployeeType ET ON E.EmployeeTypeID = ET.EmployeeTypeID
WHERE DATEDIFF(YEAR, E.DOB, GETDATE()) BETWEEN 30 AND 40;
GO
SELECT *
FROM vw_EmpOnboardingRanking
GO






Create table + Insert statement 

-- CREATE TABLE
CREATE TABLE tblRating(
   RatingID INT IDENTITY(1,1) PRIMARY KEY,
   RatingName VARCHAR(50) NOT NULL,
   RatingNumeric NUMERIC(2,1) NOT NULL,
   RatingDescr VARCHAR(50)
);


CREATE TABLE tblProductType(
   ProductTypeID INT IDENTITY(1,1) PRIMARY KEY,
   ProductTypeName VARCHAR(50) NOT NULL,
   ProductDescr VARCHAR (500)
);


CREATE TABLE tblProduct(
   ProductID INT IDENTITY(1,1) PRIMARY KEY,
   ProductName VARCHAR(50) NOT NULL,
   Price NUMERIC (8,2) NOT NULL,
   ProductTypeID INT FOREIGN KEY REFERENCES tblProductType(ProductTypeID)
);


CREATE TABLE tblCarrier(
   CarrierID INT IDENTITY(1,1) PRIMARY KEY,
   CarrierName VARCHAR(50) NOT NULL
);


CREATE TABLE tblDelivery(
   DeliveryID INT IDENTITY(1,1) PRIMARY KEY,
   CarrierID INT FOREIGN KEY REFERENCES tblCarrier(CarrierID) NOT NULL,
   ShippedDate DATE NOT NULL,
   DeliveredDate DATE NOT NULL
);




CREATE TABLE tblOrderType(
   OrderTypeID INT IDENTITY(1,1) PRIMARY KEY,
   OrderTypeName VARCHAR(50) NOT NULL,
   OrderTypeDescr VARCHAR(500)
);


CREATE TABLE tblStoreType(
   StoreTypeID INT IDENTITY(1,1) PRIMARY KEY,
   StoreTypeName VARCHAR(50) NOT NULL,
   StoreTypeDescr VARCHAR(500)
);


CREATE TABLE tblStore(
   StoreID INT IDENTITY(1,1) PRIMARY KEY,
   StoreName VARCHAR(50) NOT NULL,
   StoreTypeID INT FOREIGN KEY REFERENCES tblStoreType(StoreTypeID) NOT NULL
);


CREATE TABLE tblEmployeeType(
   EmployeeTypeID INT IDENTITY(1,1) PRIMARY KEY,
   EmployeeTypeName VARCHAR(50) NOT NULL
);


CREATE TABLE tblEmployee(
   EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
   Fname VARCHAR(50) NOT NULL,
   Lname VARCHAR(50) NOT NULL,
   DOB DATE NOT NULL,
   HireDate DATE NOT NULL,
   EmployeeTypeID INT FOREIGN KEY REFERENCES tblEmployeeType(EmployeeTypeID)
);


CREATE TABLE tblCustomerType(
   CustomerTypeID INT IDENTITY(1,1) PRIMARY KEY,
   CustomerTypeName VARCHAR(50) NOT NULL
);


CREATE TABLE tblCustomer(
   CustomerID INT IDENTITY(1,1) PRIMARY KEY,
   Fname VARCHAR(50) NOT NULL,
   Lname VARCHAR(50) NOT NULL,
   DOB DATE NOT NULL,
   [Address] VARCHAR(500) NOT NULL,
   City VARCHAR(75) NOT NULL,
   [State] VARCHAR(25) NOT NULL,
   Zip VARCHAR(25) NOT NULL,
   Email VARCHAR(75) NOT NULL,
   CustomerTypeID INT FOREIGN KEY REFERENCES tblCustomerType(CustomerTypeID)
);


CREATE TABLE tblOrder (
   OrderID INT IDENTITY(1,1) PRIMARY KEY,
   OrderDate DATE NOT NULL,
   OrderTypeID INT FOREIGN KEY REFERENCES tblOrderType(OrderTypeID) NOT NULL,
   StoreID INT FOREIGN KEY REFERENCES tblStore(StoreID) NOT NULL,
   EmployeeID INT FOREIGN KEY REFERENCES tblEmployee(EmployeeID) NOT NULL,
   CustomerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL
);


Create TABLE tblStatus (
   StatusID INT IDENTITY(1,1) PRIMARY KEY,
   StatusName VARCHAR(50) NOT NULL
);


Create table tblOrderStatus (
   OrderStatusID INT IDENTITY(1,1) PRIMARY KEY,
   OrderID INT FOREIGN KEY REFERENCES tblOrder(OrderID) NOT NULL,
   StatusID INT FOREIGN KEY REFERENCES tblStatus(StatusID) NOT NULL
);


CREATE TABLE tblOrderProduct(
   OrderProdID INT IDENTITY(1,1) PRIMARY KEY,
   Quantity INT NOT NULL,
   ProductID INT FOREIGN KEY REFERENCES tblProduct(ProductID) NOT NULL,
   OrderID INT FOREIGN KEY REFERENCES tblOrder(OrderID) NOT NULL,
   DeliveryID INT FOREIGN KEY REFERENCES tblDelivery(DeliveryID) NOT NULL
);


CREATE TABLE tblReview(
   ReviewID INT IDENTITY(1,1) PRIMARY KEY,
   OrderProdID INT FOREIGN KEY REFERENCES tblOrderProduct(OrderProdID) NOT NULL,
   RatingID INT FOREIGN KEY REFERENCES tblRating(RatingID) NOT NULL,
   ReviewDate DATE NOT NULL
);


CREATE TABLE tblCart(
   CartID INT IDENTITY(1,1) PRIMARY KEY,
   CartStatus VARCHAR(25) NOT NULL
);


CREATE TABLE tblCartProduct(
   CartProductID INT IDENTITY(1,1) PRIMARY KEY,
   UpdateDate DATE NOT NULL,
   Quantity INT NOT NULL,
   ProductID INT FOREIGN KEY REFERENCES tblProduct(ProductID) NOT NULL,
   CartID INT FOREIGN KEY REFERENCES tblCart(CartID) NOT NULL
);














-- populate Customer CustomerTpye
-- select * from tblCustomer


INSERT INTO tblCustomerType (CustomerTypeName)
VALUES ('Member'), ('Non-Member')
GO


INSERT INTO g4_p_test.dbo.tblCUSTOMER (Fname, Lname, DOB, [Address], City, [State], Zip, Email)
SELECT TOP 10000 CustomerFname, CustomerLname, DateOfBirth, CustomerAddress, CustomerCity, CustomerState, CustomerZIP, Email
FROM Peeps.dbo.tblCUSTOMER


UPDATE tblCustomer
SET CustomerTypeID = (
   CASE
       WHEN CustomerID BETWEEN 1 AND 1000 THEN (SELECT CustomerTypeID FROM tblCustomerType WHERE CustomerTypeName = 'Member')
       WHEN CustomerID BETWEEN 10000 AND 50000 THEN (SELECT CustomerTypeID FROM tblCustomerType WHERE CustomerTypeName = 'Member')
       WHEN CustomerID BETWEEN 500000 AND 800000 THEN (SELECT CustomerTypeID FROM tblCustomerType WHERE CustomerTypeName = 'Member')
       WHEN CustomerID BETWEEN 905000 AND 1000000 THEN (SELECT CustomerTypeID FROM tblCustomerType WHERE CustomerTypeName = 'Member')
       ELSE (SELECT CustomerTypeID FROM tblCustomerType WHERE CustomerTypeName = 'Non-Member')
   END
);














-- populate Employee EmployeeType
SELECT * FROM tblEmployee


INSERT INTO tblEmployeeType(EmployeeTypeName)
VALUES ('Sales Associate'),
       ('Sales Lead'),
       ('Assistant Manager'),
       ('Department Manager'),
       ('Store Manager'),
       ('Senior Store Manager')


INSERT INTO g4_p_test.dbo.tblEmployee (Fname, Lname, DOB)
SELECT TOP 6000 CustomerFname, CustomerLname, DateOfBirth
FROM Peeps.dbo.tblCUSTOMER
ORDER BY CustomerID DESC


UPDATE tblEmployee
SET EmployeeTypeID = (
  CASE
      WHEN EmployeeID BETWEEN 1 AND 1000 THEN (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Sales Associate')
      WHEN EmployeeID BETWEEN 1001 AND 2000 THEN (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Sales Lead')
      WHEN EmployeeID BETWEEN 2001 AND 3000 THEN (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Assistant Manager')
      WHEN EmployeeID BETWEEN 3001 AND 4000 THEN (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Department Manager')
      WHEN EmployeeID BETWEEN 4001 AND 5000 THEN (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Store Manager')
      ELSE (SELECT EmployeeTypeID FROM tblEmployeeType WHERE EmployeeTypeName = 'Senior Store Manager')
  END
);


UPDATE tblEmployee
SET HireDate = DATEADD(YEAR, 14, DOB)
WHERE DOB <= DATEADD(YEAR, -14, GETDATE())
















-- pop product & prod type


-- select * from nike_prod_data_raw
-- select * from tblProduct
-- select * from tblProductType
-- select * from RAW_PK_Product


-- creat a copy with pk
CREATE TABLE RAW_PK_Product(
   ProductID INT IDENTITY(1,1) PRIMARY KEY,
   ProductName VARCHAR(100) NOT NULL,
   ProductType VARCHAR(200) NOT NULL,
   Price NUMERIC(8,2) NOT NULL
);


INSERT INTO RAW_PK_Product(ProductName, ProductType, Price)
SELECT name, type, price
FROM nike_prod_data_raw




INSERT INTO tblProductType (ProductTypeName)
SELECT DISTINCT(ProductType)
FROM RAW_PK_Product
WHERE ProductType IS NOT NULL
GO


CREATE OR ALTER PROCEDURE getProductTypeID
@getProductTypeName varchar(50),
@getProductTypeID INT OUTPUT
AS
SET @getProductTypeID = (
   SELECT ProductTypeID
   FROM tblProductType
   WHERE ProductTypeName = @getProductTypeName
   )
GO


CREATE OR ALTER PROCEDURE insert_Product
AS
DECLARE @run int, @MIN_PK int, @PTID int


SET @run = (SELECT COUNT(*) FROM RAW_PK_Product)
SET @MIN_PK = (SELECT MIN(ProductID) FROM RAW_PK_Product)


WHILE (@run > 0)
BEGIN
   DECLARE @productName VARCHAR(50), @producttype_name varchar(50), @insert_cost NUMERIC (8,2)


   -- product
   SET @productName = (SELECT ProductName FROM RAW_PK_Product WHERE ProductID = @MIN_PK)
   SET @insert_cost = (SELECT Price FROM RAW_PK_Product WHERE ProductID = @MIN_PK)
   IF @productName IS NULL
   BEGIN
       PRINT 'The @productName variable contains a NULL value.'
   END


   SET @producttype_name = (SELECT ProductType FROM RAW_PK_Product WHERE ProductID = @MIN_PK)


   EXEC getProductTypeID
   @getProductTypeName = @producttype_name,
   @getProductTypeID = @PTID OUTPUT


   -- insert statment
   INSERT INTO tblProduct(ProductName, ProductTypeID, Price)
   VALUES (@productName, @PTID, @insert_cost)


   -- update while loop
   SET @MIN_PK = @MIN_PK + 1
   SET @run = @run - 1
END
GO
EXEC insert_Product
GO










-- pop tblStatus
-- select * from tblStatus
INSERT INTO tblStatus (StatusName)
VALUES ('In Process'),
       ('Pending'),
       ('In Transit'),
       ('Partially Delivered'),
       ('Delivered'),
       ('Partially Returned'),
       ('Returned'),
       ('Cancelled')
GO










-- pop tblOrderType
-- select * from tblOrderType
INSERT INTO tblOrderType (OrderTypeName)
VALUES ('Regular Order'),
       ('Promotional Order'),
       ('Wholesale Order'),
       ('Custom Order'),
       ('Gift Orders')
GO






-- pop tblCarrier
-- select * from tblCarrier


INSERT INTO tblCarrier (CarrierName)
VALUES ('USPS'),
       ('UPS'),
       ('FedEx'),
       ('DHL')
GO












-- pop delivery
-- select * from tbldelivery
CREATE OR ALTER PROCEDURE getCarrierID
@getCarrierName varchar(50),
@getCarrierID INT OUTPUT
AS
SET @getCarrierID = (
   SELECT CarrierID
   FROM tblCarrier
   WHERE CarrierName = @getCarrierName
   )
GO


CREATE OR ALTER PROCEDURE insertDelivery_qxie
@shipdate DATE,
@delivereddate DATE,
@carrierName varchar(50)
AS
DECLARE @cID INT


SET @cID = (SELECT CarrierID FROM tblCarrier WHERE carrierName = @carrierName )


IF @cID IS NULL
BEGIN
    PRINT '@cID is empty, check spelling';
    THROW 54321, '@cID cannot be null', 1;
END


BEGIN TRANSACTION T1
   INSERT INTO tblDelivery(CarrierID, ShippedDate, DeliveredDate)
   VALUES (@CID, @shipdate, @delivereddate)
   IF @@ERROR <> 0
   BEGIN
       ROLLBACK TRANSACTION G1
   END
ELSE
   COMMIT TRANSACTION G1
GO


-- wrapper code
CREATE OR ALTER PROCEDURE wrapper_insert_Delivery
@run int
AS
DECLARE @shipDate DATE, @deliverdDate DATE
DECLARE @carrierName VARCHAR(50), @carrierID_OUT INT, @CarrierPK INT
DECLARE @GetDate Date
DECLARE @RandDate INT, @DRandDate INT
DECLARE @CarrierCOUNT INT = (SELECT COUNT(*) FROM tblCarrier)


WHILE @Run > 0
   BEGIN
       SET @CarrierPK = (SELECT RAND() * @CarrierCOUNT +1)


       SET @RandDate = (SELECT RAND() * 10000)
       SET @shipDate = DATEADD(DAY, -@RandDate, GETDATE())
       SET @DRandDate = (SELECT RAND() * 10)
       SET @deliverdDate = DATEADD(DAY, @DRandDate, @shipDate)




       SET @carrierName = (SELECT CarrierName FROM tblCarrier WHERE CarrierID = @CarrierPK)


       EXEC getCarrierID
       @getCarrierName = @carrierName,
       @getCarrierID = @carrierID_OUT OUTPUT


       EXEC insertDelivery_qxie
       @shipdate = @shipDate,
       @delivereddate = @deliverdDate,
       @carrierName = @carrierName


       SET @Run = @Run -1
   END
PRINT 'ALL DONE!!'


EXEC wrapper_insert_Delivery 40000
GO












-- pop store storeType


INSERT INTO tblStoreType (StoreTypeName)
VALUES ('Pop-Up'),
       ('Discount Stores'),
       ('Factory Stores'),
       ('Partner Retailers'),('Regular')


-- select * from tblStore
INSERT INTO tblStore (StoreName, StoreTypeID)
VALUES
   ('Nike House of Innovation', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Regular')),
   ('Nike Factory Outlet', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Factory Stores')),
   ('Nike Sportswear Hub', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Regular')),
   ('Nike Lifestyle Lounge', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Pop-up')),
   ('Basketball Court', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Partner Retailers')),
   ('Discount Depot', (SELECT StoreTypeID FROM tblStoreType WHERE StoreTypeName = 'Discount Stores'))
GO










-- pop order
-- select * from tblOrder
CREATE OR ALTER PROCEDURE insertOrder
@OrderDate DATE,
@getordertypename VARCHAR(50),
@getstorename VARCHAR(50),
@Efname VARCHAR(50),
@Elname VARCHAR(50),
@Edob DATE,
@Cemail VARCHAR(75)
AS
DECLARE @OrderTypeID INT, @StoreID INT, @EmployeeID INT, @CustomerID INT


SET @OrderTypeID = (
   select OrderTypeID
   FROM tblOrderType
   WHERE OrderTypeName = @getordertypename
)
IF @OrderTypeID IS NULL
BEGIN
  PRINT '@OrderTypeID is empty...check spelling';
  THROW 65451, '@OrderTypeID cannot be NULL',1;
END


SET @StoreID = (
   select StoreID
   FROM tblStore
   WHERE StoreName = @getstorename
)
IF @StoreID IS NULL
BEGIN
  PRINT '@StoreID is empty...check spelling';
  THROW 65451, '@StoreID cannot be NULL',1;
END


SET @EmployeeID = (
   SElect EmployeeID
   From tblEmployee
   WHERE Fname = @Efname
   AND Lname = @Elname
   AND DOB = @Edob
)
IF @EmployeeID IS NULL
BEGIN
  PRINT '@EmployeeID is empty...check spelling';
  THROW 65451, '@EmployeeID cannot be NULL',1;
END


SET @CustomerID = (
   SELECT CustomerID
   FROM tblCustomer
   WHERE Email = @Cemail
)
IF @CustomerID IS NULL
BEGIN
  PRINT '@CustomerID is empty...check spelling';
  THROW 65451, '@CustomerID cannot be NULL',1;
END


BEGIN TRANSACTION T1
  INSERT INTO tblOrder(OrderDate, OrderTypeID, StoreID, EmployeeID, CustomerID)
  VALUES(@OrderDate, @OrderTypeID, @StoreID, @EmployeeID, @CustomerID)


  IF @@ERROR <> 0
      BEGIN
          ROLLBACK TRANSACTION T1
      END
  ELSE
      COMMIT TRANSACTION T1
GO


-- wrapper code
CREATE OR ALTER PROCEDURE wrapper_insert_Order
@run INT
AS
DECLARE
@OrderDate DATE,
@getordertypename VARCHAR(50),
@getstorename VARCHAR(50),
@Efname VARCHAR(50),
@Elname VARCHAR(50),
@Edob DATE,
@Cemail VARCHAR(75)
DECLARE @OrderTypePK INT, @StorePK INT, @EmployeePK INT, @CustomerPK INT
DECLARE @OrderTypeCount INT = (SELECT COUNT(*) FROM tblOrderType)
DECLARE @StoreCount INT = (SELECT COUNT(*) FROM tblStore)
DECLARE @EmployeeCount INT = (SELECT COUNT(*) FROM tblEmployee)
DECLARE @CustomerCount INT = (SELECT COUNT(*) FROM tblCustomer)
DECLARE @GetDate DATE, @RandDate INT


WHILE @run > 0
BEGIN
   SET @OrderTypePK = (SELECT RAND() * @OrderTypeCount + 1)
   SET @StorePK = (SELECT RAND() * @StoreCount + 1)
   SET @EmployeePK = (SELECT RAND() * @EmployeeCount + 1)
   SET @CustomerPK = (SELECT RAND() * @CustomerCount + 1)
   SET @RandDate = (SELECT RAND() * 10000)


   SET @OrderDate = (SELECT DateAdd(Day, -@RandDate, GetDate()))
   SET @getordertypename = (SELECT OrderTypeName FROM tblOrderType WHERE OrderTypeID = @OrderTypePK)
   SET @getstorename = (SELECT StoreName FROM tblStore WHERE StoreID = @StorePK)
   SET @Efname = (SELECT Fname FROM tblEmployee WHERE EmployeeID = @EmployeePK)
   SET @Elname = (SELECT Lname FROM tblEmployee WHERE EmployeeID = @EmployeePK)
   SET @Edob = (SELECT DOB FROM tblEmployee WHERE EmployeeID = @EmployeePK)
   SET @Cemail = (SELECT Email FROM tblCustomer WHERE CustomerID = @CustomerPK)


   EXEC insertOrder
   @OrderDate = @OrderDate,
   @getordertypename = @getordertypename,
   @getstorename = @getstorename,
   @Efname = @Efname,
   @Elname = @Elname,
   @Edob = @Edob,
   @Cemail = @Cemail


   SET @run = @run -1
END


EXEC wrapper_insert_Order 1000
GO














-- pop orderProd
CREATE OR ALTER PROCEDURE insert_OrderProduct
@getQuantity INT,
@StoreName VARCHAR(50),
@EFname VARCHAR(50),
@ELname VARCHAR(50),
@CEmail VARCHAR(75),
@ProductName VARCHAR(50),
@prodPrice NUMERIC(8,3),
@DeliveredDate DATE,
@shipDate DATE
AS
-- declare fk
DECLARE @ProductID INT, @OrderID INT, @DeliveryID INT




-- get fks
SET @OrderID = (
  SELECT OrderID
  FROM tblOrder O
      JOIN tblStore S on O.StoreID = S.storeID
      JOIN tblEmployee E ON O.EmployeeID = E.EmployeeID
      JOIN tblCustomer C ON O.CustomerID = C.CustomerID
  WHERE S.StoreName = @StoreName
  AND E.Fname = @EFname
  AND E.Lname = @ELname
  AND C.Email = @CEmail
)


IF @OrderID IS NULL
BEGIN
  PRINT '@OrderID is empty...check spelling';
  THROW 65451, '@OrderID cannot be NULL',1;
END


SET @ProductID = (
  SELECT ProductID
  FROM tblProduct
  WHERE ProductName = @ProductName
  AND Price = @prodPrice
)


IF @ProductID IS NULL
BEGIN
  PRINT '@ProductID is empty...check spelling';
  THROW 65451, '@ProductID cannot be NULL',1;
END


SET @DeliveryID = (
  SELECT TOP 1 DeliveryID
  FROM tblDelivery
  WHERE DeliveredDate = @DeliveredDate
  AND ShippedDate = @shipDate
)


IF @DeliveryID IS NULL
BEGIN
  PRINT '@DeliveryID is empty...check spelling';
  THROW 65451, '@DeliveryID cannot be NULL',1;
END


BEGIN TRANSACTION T1
  INSERT INTO tblOrderProduct(Quantity, ProductID, OrderID, DeliveryID)
  VALUES(@getQuantity, @ProductID, @OrderID, @DeliveryID)


  IF @@ERROR <> 0
      BEGIN
          ROLLBACK TRANSACTION T1
      END
  ELSE
      COMMIT TRANSACTION T1
GO


-- wrapper-code-order-prod
CREATE OR ALTER PROCEDURE wrapper_insert_OrderProduct
@run INT
AS
DECLARE
@wr_getQuantity INT,
@wr_StoreName VARCHAR(50),
@wr_EFname VARCHAR(50),
@wr_ELname VARCHAR(50),
@wr_CEmail VARCHAR(75),
@wr_ProductName VARCHAR(50),
@wr_prodPrice NUMERIC(8,3),
@wr_DeliveredDate DATE,
@wr_shipDate DATE


DECLARE @OrderPK INT, @ProductPK INT,  @DeliveryPK INT
DECLARE @OrderCount INT = (SELECT COUNT(*) FROM tblOrder)
DECLARE @ProductCount INT = (SELECT COUNT(*) FROM tblProduct)
DECLARE @DeliveryCount INT = (SELECT COUNT(*) FROM tblDelivery)


WHILE @run > 0
BEGIN
  SET @OrderPK = (SELECT RAND() * @OrderCount + 1)
  SET @ProductPK = (SELECT RAND() * @ProductCount + 1)
  SET @DeliveryPK = (SELECT RAND() * @DeliveryCount + 1)


  SET @wr_getQuantity = (SELECT RAND() * 10 + 1)


  SET @wr_StoreName = (
      SELECT TOP 1 StoreName
      FROM tblStore S
      JOIN tblOrder O ON S.StoreID = O.StoreID
      WHERE O.OrderID = @OrderPK
  )


  SET @wr_EFname = (
      SELECT Fname
      FROM tblEmployee E
      JOIN tblOrder O on E.EmployeeID = O.EmployeeID
      WHERE O.OrderID = @OrderPK
  )


  SET @wr_ELname = (
      SELECT Lname
      FROM tblEmployee E
      JOIN tblOrder O on E.EmployeeID = O.EmployeeID
      WHERE O.OrderID = @OrderPK
  )


  SET @wr_CEmail = (
      SELECT Email
      FROM tblCustomer C
      JOIN tblOrder O on C.CustomerID = O.CustomerID
      WHERE O.OrderID = @OrderPK
  )


   SET @wr_ProductName = (
       SELECT ProductName
       FROM tblProduct
       WHERE ProductID = @ProductPK
   )


   SET @wr_prodPrice = (
       SELECT Price
       FROM tblProduct
       WHERE ProductID = @ProductPK
   )


   SET @wr_DeliveredDate = (
       SELECT DeliveredDate
       FROM tblDelivery
       WHERE DeliveryID = @DeliveryPK
   )


   SET @wr_shipDate = (
       SELECT ShippedDate
       FROM tblDelivery
       WHERE DeliveryID = @DeliveryPK
   )


  EXEC insert_OrderProduct
   @getQuantity = @wr_getQuantity,
   @StoreName = @wr_StoreName,
   @EFname = @wr_EFname,
   @ELname = @wr_ELname,
   @CEmail = @wr_CEmail,
   @ProductName = @wr_ProductName,
   @prodPrice = @wr_prodPrice,
   @DeliveredDate = @wr_DeliveredDate,
   @shipDate = @wr_shipDate


  SET @run = @run -1
END


EXEC wrapper_insert_OrderProduct 10000


-- select * from tblOrderProduct
GO


















-- pop orderStatus


CREATE OR ALTER PROCEDURE insert_OrderStatus
@StoreName VARCHAR(50),
@EFname VARCHAR(50),
@ELname VARCHAR(50),
@CEmail VARCHAR(75),
@StatusName VARCHAR(50)
AS
-- declare fk
DECLARE @OrderID INT, @StatusID INT


-- get fks
SET @OrderID = (
   SELECT TOP 1 OrderID
   FROM tblOrder O
       JOIN tblStore S on O.StoreID = S.storeID
       JOIN tblEmployee E ON O.EmployeeID = E.EmployeeID
       JOIN tblCustomer C ON O.CustomerID = C.CustomerID
   WHERE S.StoreName = @StoreName
   AND E.Fname = @EFname
   AND E.Lname = @ELname
   AND C.Email = @CEmail
)


IF @OrderID IS NULL
BEGIN
   PRINT '@OrderID is empty...check spelling';
   THROW 65451, '@OrderID cannot be NULL',1;
END


SET @StatusID = (
   SELECT StatusID
   FROM tblStatus
   WHERE StatusName = @StatusName
)


IF @StatusID IS NULL
BEGIN
   PRINT '@StatusID is empty...check spelling';
   THROW 65451, '@StatusID cannot be NULL',1;
END


BEGIN TRANSACTION T1
   INSERT INTO tblOrderStatus(OrderID, StatusID)
   VALUES(@OrderID, @StatusID)


   IF @@ERROR <> 0
       BEGIN
           ROLLBACK TRANSACTION T1
       END
   ELSE
       COMMIT TRANSACTION T1
GO


-- wrapper code
CREATE OR ALTER PROCEDURE wrapper_insert_OrderStatus
@run INT
AS
DECLARE
@StoreName VARCHAR(50),
@EFname VARCHAR(50),
@ELname VARCHAR(50),
@CEmail VARCHAR(75),
@StatusName VARCHAR(50)
DECLARE @OrderPK INT, @StatusPK INT
DECLARE @OrderCount INT = (SELECT COUNT(*) FROM tblOrder)
DECLARE @StatusCount INT = (SELECT COUNT(*) FROM tblStatus)




WHILE @run > 0
BEGIN
   SET @OrderPK = (SELECT RAND() * @OrderCount + 1)
   SET @StatusPK = (SELECT RAND() * @StatusCount + 1)


   SET @StoreName = (
       SELECT StoreName
       FROM tblStore S
       JOIN tblOrder O ON S.StoreID = O.StoreID
       WHERE O.OrderID = @OrderPK
   )


   SET @EFname = (
       SELECT Fname
       FROM tblEmployee E
       JOIN tblOrder O on E.EmployeeID = O.EmployeeID
       WHERE O.OrderID = @OrderPK
   )


   SET @ELname = (
       SELECT Lname
       FROM tblEmployee E
       JOIN tblOrder O on E.EmployeeID = O.EmployeeID
       WHERE O.OrderID = @OrderPK
   )


   SET @CEmail = (
       SELECT Email
       FROM tblCustomer C
       JOIN tblOrder O on C.CustomerID = O.CustomerID
       WHERE O.OrderID = @OrderPK
   )


   SET @StatusName = (
       SELECT StatusName
       FROM tblStatus S
       WHERE S.StatusID = @StatusPK
   )


   EXEC insert_OrderStatus
   @StoreName = @StoreName,
   @EFname = @EFname,
   @ELname = @ELname,
   @CEmail = @CEmail,
   @StatusName = @StatusName


   SET @run = @run -1
END


EXEC wrapper_insert_OrderStatus 10000


GO
-- select * from tblOrderStatus


--  tblStatus
INSERT INTO tblStatus (StatusName)
VALUES ('In Process'),
        ('Pending'),
        ('In Transit'),
        ('Partially Delivered'),
        ('Delivered'),
        ('Partially Returned'),
        ('Returned'),
        ('Cancelled')






--  pop rating 
INSERT INTO tblRating (RatingName, RatingNumeric, RatingDescr)
VALUES
 ('Excellent', 5, 'The highest rating'),
 ('Good', 4, 'Above average rating'),
 ('Average', 3, 'An average rating'),
 ('Fair', 2, 'Below average rating'),
 ('Poor', 1, 'The lowest rating');















