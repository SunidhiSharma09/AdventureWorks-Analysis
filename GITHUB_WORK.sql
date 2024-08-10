
--ADVENTURE WORKS DATASET--

create database AdventureWorks;

use AdventureWorks;


/* Create a View to combine sales data of 2015,2016 and 2017.*/

create view sales_data 
as 
  select * from AdventureWorks_Sales_2015
  union all
  select * from AdventureWorks_Sales_2016
  union all
  select * from AdventureWorks_Sales_2017;

 select*from sales_data ; -- to execute view 

 
/* Find the return quantity and amount of each model.*/

select ModelName , Sum(ReturnQuantity) as Return_Quantity , cast(sum(ProductPrice) as decimal(12,2)) as Amount
from AdventureWorks_Products as p
join AdventureWorks_Returns as r 
on p.ProductKey=r.ProductKey
group by ModelName
order by Sum(ReturnQuantity) desc , sum(ProductPrice) desc;



/* Find the least selling product category of 2016.*/

select  top 1 CategoryName , sum(s.orderquantity) as Qty_sold
from AdventureWorks_Product_Categories as pc 
join AdventureWorks_Product_Subcategories as ps on pc.ProductCategoryKey = ps.ProductCategoryKey
join AdventureWorks_Products as p on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join  AdventureWorks_Sales_2016 as s on s.ProductKey = p.ProductKey
group by CategoryName 
order by sum(s.orderquantity);



/* Create a View to identfy the top selling product based on order quantity.*/

	create view top_selling_product 

	as
	  select top 1 p.productname as Products_Name , sum(orderquantity) as Qty_ordered
	  from AdventureWorks_Products as p
	  join sales_data as s
	  on p.ProductKey = s.ProductKey
	  group by ProductName
	  order by sum(orderquantity) desc;
 
	select * from top_selling_product; -- to execute


/* Show the name of the month and their respective average sales and return quantity.*/

 select case 
        when month(orderdate) = 1 then 'January'
		when month(orderdate) = 2 then 'February'
		when month(orderdate) = 3 then 'March'
        when month(orderdate) = 4 then 'April'
        when month(orderdate) = 5 then 'May'
        when month(orderdate) = 6 then 'June'
        when month(orderdate) = 7 then 'July'
        when month(orderdate) = 8 then 'August'
        when month(orderdate) = 9 then 'September'
        when month(orderdate) = 10 then 'October'
        when month(orderdate) = 11 then 'November'
        when month(orderdate) = 12 then 'December'
end as Months ,	cast( avg(s.OrderQuantity * p.ProductPrice) as decimal(10,2)) as Avg_Sales, sum(ReturnQuantity) as Return_Qty	
 from sales_data as s 
 join AdventureWorks_Products as p on s.ProductKey = p.ProductKey
 join AdventureWorks_Returns as r on r.ProductKey = p.ProductKey
 group by  month(OrderDate);



 /*Show the total order quantity of each product where order has been placed from United States or Canada and order the results by
 total sales of the product.*/

 select p.ProductName, sum(s.OrderQuantity) as Total_Order_Qty, cast(sum(s.OrderQuantity*p.ProductPrice )as decimal(10,2)) 
 as Total_sales,Country 
 from AdventureWorks_Products as p 
 join sales_data as s on p.ProductKey = s.ProductKey
 join AdventureWorks_Territories as t on s.TerritoryKey = t.SalesTerritoryKey
 where country = 'United States' or country = 'Canada' 
 group by ProductName, Country
 order by [Total_sales] desc;



 /* Find the average return quantity from each continent and order them as per the returned amount.*/

select Continent, avg(ReturnQuantity) as Avg_Return_Quantity , cast(sum(ReturnQuantity*ProductPrice) as decimal(10,2))as Returned_Amount
from AdventureWorks_Territories as t 
join AdventureWorks_Returns as r on t.SalesTerritoryKey= r.TerritoryKey
join AdventureWorks_Products as p on p.ProductKey = r.ProductKey
group by Continent
order by sum(ReturnQuantity*ProductPrice) desc;



/* On which year,most of the order has been returned? */

select top 1 year(returndate) AS 'Most Order Returned in Year' , sum(returnquantity) as Returned_Qty
from AdventureWorks_Returns
group by year(returndate)
order by sum(returnquantity) desc ;



/* Find the top 3 regions from which the least amount of order has been placed.*/

select top 3 Region, sum(OrderQuantity) as Quantity_Ordered, cast(sum(OrderQuantity * ProductPrice) as decimal(10,2)) as Order_Amount 
from AdventureWorks_Territories as t 
join sales_data as s on t.SalesTerritoryKey = s.TerritoryKey
join AdventureWorks_Products as p on p.ProductKey = s.ProductKey
group by Region
order by sum(OrderQuantity * ProductPrice);



/* Create a view to calculate total sales by Product.*/

create view Products_Total_Sales 
as
  select ProductName, cast(sum(OrderQuantity * ProductPrice) as decimal(12,2))as Total_Sales 
  from AdventureWorks_Products as p
  join sales_data as s 
  on p.ProductKey = s.ProductKey 
  group by ProductName;

select * from Products_Total_Sales ; -- to execute



/* Show the first and last name of all the married customers whose first name starts with S and last name ends with S.*/

select FirstName , LastName 
from AdventureWorks_Customers
where MaritalStatus = 'M' and FirstName like 'S%' and LastName like '%S';



/* Find the age of each customer whose annual income is greater than the average annual income.*/

select concat(prefix,' ',firstname,' ',lastname) as Customer_Name, AnnualIncome ,DATEDIFF(yy,BirthDate,getdate()) as Age
from AdventureWorks_Customers
where annualincome > (select avg(annualincome) from AdventureWorks_Customers)
group by concat(prefix,' ',firstname,' ',lastname),AnnualIncome,DATEDIFF(yy,BirthDate,getdate());



/* Rank model's name by their total profitability and partition by their colour and order by  their total order quantity.*/ 

select ModelName , ProductColor,   sum(OrderQuantity) as Total_Order_Qty,
       cast(sum((OrderQuantity*ProductPrice)-(OrderQuantity*ProductCost)) as decimal(10,2)) as Total_Profit,
       dense_rank() over(partition by ProductColor order by sum((OrderQuantity*ProductPrice)-(OrderQuantity*ProductCost)) desc, sum(OrderQuantity) desc)
	   as Models_Rank 
from sales_data as s
join AdventureWorks_Products as p 
on s.ProductKey = p.ProductKey
group by ModelName, ProductColor;



/* Using windows functions, Find the Region wise Average profit partition by Product Category and Round the profit by 
two decimal places.*/

Select Region , CategoryName as Product_Category, cast(avg(OrderQuantity*ProductPrice-OrderQuantity*ProductCost) as decimal(12,2)) as Region_Avg_Profit,
      cast( avg(Avg(OrderQuantity*ProductPrice-OrderQuantity*ProductCost)) over(partition by CategoryName) as decimal(10,2))as Avg_Profit 
from AdventureWorks_Territories as t 
join sales_data as s on s.TerritoryKey = t.SalesTerritoryKey
join AdventureWorks_Products as p on p.ProductKey = s.ProductKey
join AdventureWorks_Product_Subcategories as ps on ps.ProductSubcategoryKey = p.ProductSubcategoryKey
join AdventureWorks_Product_Categories as pc on pc.ProductCategoryKey = ps.ProductCategoryKey
group by Region, CategoryName;



/* Rank the countries as per the total sales they are providing and no rank should be skipped.*/

select Country , cast(sum(OrderQuantity*ProductPrice) as decimal(12,2)) as Total_Sales,
       DENSE_RANK() over (order by sum(OrderQuantity*ProductPrice) desc ) as Countries_Rank 
from AdventureWorks_Territories as t 
join sales_data as s on t.SalesTerritoryKey = s.TerritoryKey 
join AdventureWorks_Products as p on p.ProductKey = s.ProductKey
group by Country;



/* Using Window functions, Show the total annual income of the people by country partitioned by their occupation and order by their 
status of homeowner or not . */

select Country, Occupation , replace(replace(HomeOwner,0,'No'),1,'Yes') as HomeOwner,sum(AnnualIncome) as 'Annual Income-Countrywise',
       sum(sum(AnnualIncome)) over (Partition by Occupation Order by Homeowner) as 'Total Annual Income'
from AdventureWorks_Territories as t
join sales_data as s on s.TerritoryKey = t.SalesTerritoryKey
join AdventureWorks_Customers as c on c.CustomerKey = s.CustomerKey
group by Country,Occupation , HomeOwner;


    /* Create a Procedure to update the salary of the customer with the customer id and rollback if the new salary is less than the
    existing salary.*/
	go

	create procedure customer_salary_update
	(
	@customer_id smallint ,
	@new_salary int )

	as begin 
			declare @old_salary int;

	begin transaction 

					   select @old_salary= AnnualIncome from AdventureWorks_Customers where CustomerKey=@customer_id;
				   
					   if @@ERROR<>0
					   begin 
					   rollback transaction ;
					   raiserror('Error in retrieving data',16,1)
					   return;
					   end

					   -- to check salary
					   if @new_salary< @old_salary
					   begin rollback transaction ;
					   raiserror('New salary is less than Existing salary',16,1)
					   return;
					   end

					   -- to update salary 
					   update AdventureWorks_customers
					   set AnnualIncome=@new_salary
					   where CustomerKey= @customer_id;

					   if @@ERROR<>0 
					   begin rollback transaction ;
					   raiserror('Error in updating salary',16,1)
					   return;
					   end
	 commit transaction;
	 print 'New Salary of '+cast(@new_salary as char(10))+'of Customer_ID '+cast(@customer_id as char(10))+'is updated successfully.';

	END

       
	-- to execute procedure

	exec customer_salary_update 11001,70000;

	exec customer_salary_update 11000,60000;



	/* Create a Procedure to increase the number of children by a certain number as per user provides with the customer id. */

	Go

	Create Procedure Update_customers_children (
					 @customer_id int ,
					 @Children_inc int )

	as
	  begin transaction 
					   update AdventureWorks_Customers
					   set TotalChildren = TotalChildren + @Children_inc
					   where CustomerKey = @customer_id;

					   if @@ERROR<>0
					   begin rollback transaction ;
					   raiserror('Error in updating data',16,1)
					   return;
					   end 
	 commit transaction ;
	 print 'Number of Children for Customer Key '+cast(@customer_id as char(10))+' is increased by '+cast(@children_inc as char(10))+
	 ' successfully.';

	 -- to execute 
	  select * from AdventureWorks_Customers;

	  exec Update_customers_children 11005,2;

	  exec Update_customers_children 11012,1;



/* Create a Trigger to log the details of the customer into a new table called customer_logs when any new customer is inserted in 
Customers table.*/

-- customer_logs table

create table customer_logs (
id int identity(1,1) ,
action text );

--trigger

Go

Create Trigger update_new_cutomer_records
on AdventureWorks_Customers
for insert
as 
begin
      declare @customer_id int 
	  select @customer_id = customerkey from inserted 
	  insert into customer_logs
	  values('New Customer with Customer Key '+cast(@customer_id as char(10))+' is added at '+cast(getdate() as char(30))+'.')
end;

-- To Execute 

insert into AdventureWorks_customers
values('29487','MS','ANANYA','SHARMA','04-06-1997','S','F','ananya08@adventure_works.com',150000,0,'Bachelors','Management',0);

select* from customer_logs;



/* Create a Triggers to log the details of the customer into a new table called customer_logs when any existing customer is 
deleted from customers table.*/
go

create trigger update_deleted_customer_records
on AdventureWorks_customers
for delete
as 
begin
       declare @customer_id int 
	   select @customer_id = customerkey from deleted 
	   insert into customer_logs
	   values('Customer with Customer Key '+cast(@customer_id as char(10))+'is removed at '+cast(getdate() as char(30)))
end;

-- to execute 

delete AdventureWorks_customers
where CustomerKey='29487';

select* from customer_logs; 



select * from INFORMATION_SCHEMA.TABLES











