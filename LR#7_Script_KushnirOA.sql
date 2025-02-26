--Лабораторная работа 7
--
--1.	Выведите список заказчиков, пронумеровав их в пределах каждой страны отдельно 
--      в порядке убывания общей стоимости сделанных заказчиком заказов.

-- вывожу также и тех заказчиков, которые не делали заказов
with CTE_t as
(
	select contactname
	, country
	, coalesce (sum(unitprice*qty*(1 - discount)), 0::money) as "TotalPrice"
	from "Sales"."Customers" as sc
	left join "Sales"."Orders" as so on sc.custid = so.custid
	left join "Sales"."OrderDetails" as sod on so.orderid = sod.orderid
	group by sc.custid
)
select 
row_number () over(partition by country order by "TotalPrice" desc) as "SN"
, contactname
, country
, "TotalPrice"
from CTE_t
;

--2.	Выведите самые дорогие продукты в каждой категории. Для фильтрации воспользуйтесь рангом продуктов в соответствии с их ценой
select *
from 
( 
	select 	productid
	, productname
	, categoryid
	, unitprice
	, rank() over(partition  by categoryid order by unitprice desc) as "Rank"
	from "Production"."Products"
) as t
where "Rank" = 1
;

--3.	Выведите для каждого продукта его название, цену, количество заказов, 
--		в которых данный продукт встречается, и ранг, в соответствии с частотой его присутствия в заказах

select distinct "ProductName"
, "UnitPrice"
, "OrdQuantity"
, dense_rank () over(order by "OrdQuantity" desc) as "Rnk"
from
(
	select productname as "ProductName"
	, pp.unitprice as "UnitPrice"
	, sod.orderid as "OrderID"
	, count(sod.orderid) over(partition by productname) as "OrdQuantity"
	from "Production"."Products" as pp
	left join "Sales"."OrderDetails" as sod 
	on pp.productid =sod.productid 
) as t 
order by "Rnk"
;

--4.	Выведите для всех заказов, сделанных в период с 1 мая по 1 июня 2008 года, 
--  номер заказа, общую стоимость заказа, процентную долю от общей стоимости по всем заказам за данный период
with CTE_t as
(
select so.orderid as "OrderID"
	, orderdate as "OrderDate"
	, sum(unitprice*qty*(1 - discount)) as "TotalPrice"
	from "Sales"."Orders" as so
	inner join "Sales"."OrderDetails" as sod
	on so.orderid = sod.orderid 
	where orderdate between '2008-05-01'::date and '2008-06-01'::date
	group by so.orderid 
)
select *
, trunc( ("TotalPrice" / sum("TotalPrice") over())::numeric, 3 ) as "PercentageOfTotalSum"
from CTE_t
;

--5.	Выведите код заказчика, год заказа, ранг по каждому заказчику в каждом году в соответствии с объемом заказа (val) и объем заказа. 
-- В выборке должны присутствовать только записи с рангом 1 и 2. Воспользуйтесь представлением public."OrderValues"
-- 
select *
from 
(
	select custid
	, extract ("year" from orderdate) as "orderyear"
	, val
	, rank() over(partition by (extract ("year" from orderdate)) order by val) as "r"
	from
	public."OrderValues"
) as t
where "r" in (1, 2)
;
--6.	Выведите одним запросом: номер заказчика, номер заказа, дату заказа, объем заказа, 
-- объем заказа за предыдущую дату по данному заказчику, 
-- разницу между текущим и предыдущим объемом. 
-- Null значения должны быть заменены 0. Воспользуйтесь представлением public."OrderValues"
-- 
select custid
, orderid
, orderdate
, val
, lag(val, 1, 0::numeric) over(partition by custid order by orderdate) as "PredVal"
, (lag(val, 1, 0::numeric) over(partition by custid order by orderdate)) - val as "DifVals" 
from
public."OrderValues"
;

--7.	Выведите для всех заказов, сделанных в 2007 году, название месяца, 
-- общий объем заказов в этом месяце, средний объем за 3 месяца (2 предыдущих и текущий) 
-- и нарастающий итого по месяцам. Воспользуйтесь представлением public."OrderValues"

-- Похоже, что в примере к этому заданию средний объем вычисляется за 4 месяца,
-- как если бы задать функции avg такие параметры:
-- avg("total") over(order by to_date("month", 'month') rows between 3 preceding and current row
-- Я сделала строго по заданию:
-- avg("total") over(order by to_date("month", 'month') rows between 2 preceding and current row

select 
"month"
, "total"
, trunc(avg("total") over(order by to_date("month", 'month') 
				rows between 2 preceding and current row), 2 ) as "evglast3mnths"
, sum("total") over(order by to_date("month", 'month')) as "ytdval"
from 
(
	select 
	to_char(orderdate, 'Month') as "month"
	, sum (val) over(partition by to_char(orderdate, 'Month') ) as "total"	 	
	from
	public."OrderValues"
	where orderdate between '2007-01-01' and '2007-12-31'-- замечание так не делать (не надо вычислять новый столбец): extract ('year' from orderdate) = '2007'
) as t
group by "month", "total"
;

