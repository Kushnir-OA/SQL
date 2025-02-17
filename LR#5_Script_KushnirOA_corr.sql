--Лабораторная работа 5
--Задание 4. Запросы с группировкой
--1.	Выведите таблицу из трех столбцов: максимальная, минимальная и средняя стоимость продуктов. 

select max(unitprice) as "макс. стоимость продуктов"
	, min(unitprice) as "мин. стоимость продуктов"
	, cast( avg( cast(unitprice as numeric) ) as money ) as "средняя стоимость продуктов"
from "Production"."Products"
;

--2.	Выведите таблицу из 2-х столбцов: номер категории и количество продуктов в каждой категории.
select categoryid as "номер категории"
     , count(*) as "кол-во продуктов в категории"
from  "Production"."Products"
group by categoryid
;

--3.	Выведите данные о количестве заказов, оформленных каждым сотрудником

select empid as "Номер сотрудника"
	, count (*) as "Количество заказов"
from "Sales"."Orders"
group by empid
;

--4.	Выведите минимальную и максимальную цену (price) товара, входящего в заказы каждого заказчика

select so.custid as "Заказчик"
	, min(sod.unitprice) as "Мин. цена товара"
	, max(sod.unitprice) as "Макс. цена товара"
from "Sales"."Orders" as so
inner join "Sales"."OrderDetails" as sod
on so.orderid = sod.orderid 
group by so.custid
;

--select so.orderid, unitprice -- запрос для проверки результата
--from "Sales"."Orders"  as so
--inner join  "Sales"."OrderDetails" as sod
--on so.orderid = sod.orderid 
--where custid = 1
--order by unitprice
--;

--5.	Выберите 5 самых выгодных заказчиков, с точки зрения суммарной стоимости их заказов

select so.custid as "Заказчик"
	, sum( (unitprice*qty)*(1 - discount) ) as "Общая стоимость заказов"	
from "Sales"."Orders" as so
inner join "Sales"."OrderDetails" as sod
on so.orderid = sod.orderid 
group by so.custid
order by 2 desc 
fetch next 5 rows only
;

--6.	Выведите год, количество сделанных заказов в этом году и количество уникальных заказчиков, которые делали эти заказы.

select date_part ('year', orderdate) as "Год"
	, count(*) as "Количество заказов"
	, count (distinct custid) as "Количество заказчиков"
from "Sales"."Orders" 
group by date_part ('year', orderdate)
;

--7.	Для каждого заказа выведите общую сумму заказа, общее количество вошедших в него товаров и среднюю стоимость товаров в заказе. 
-- Отсортируйте результирующую выборку по убыванию количества товаров в заказе.

select orderid as "Номер заказа"
	, sum( (unitprice*qty)*(1 - discount) ) as "Общая сумма"
	, sum(qty) as "Количество товаров"
	, cast( avg( cast(unitprice as numeric ) ) as money ) as "Ср. стоимость товаров в заказе"
from "Sales"."OrderDetails"
group by orderid
order by "Количество товаров" desc -- надо так
--order by sum(qty) desc -- исправление: не надо вычислять заново сумму, можно взять уже вычисленный столбец
;

--8.	Выведите список только тех заказов, общая стоимость которых превышает 1000

select orderid as "Номер заказа"
	, sum( (unitprice*qty)*(1 - discount) ) as "Общая сумма"
	, sum(qty) as "Количество товаров"
	, cast( avg( cast(unitprice as numeric ) ) as money ) as "Ср. стоимость товаров в заказе"
from "Sales"."OrderDetails"
group by orderid 
having sum( (unitprice*qty)*(1 - discount) ) > cast(1000 as money)
;

--9.	Выберите заказчиков из Германии, которые сделали более 10 заказов. Детали должны присутствовать!
-- 
select companyname as "Компания"
	, contactname as "Представитель"
	, country as "Страна"
	, city as "Город"
	, address as "Адрес"
	, so.custid as "ID компании"
	, count (*) as "Кол-во заказов" 
from "Sales"."Orders" as so
inner join "Sales"."Customers" as sc
on sc.custid = so.custid 
where country = 'Germany'
group by so.custid, companyname 
	, contactname 
	, country
	, city
	, address 
having count (*) > 10
;

--
--10.	Выведите номер заказа и количество в нем продуктов со скидкой (используйте filter).

select orderid as "Номер заказа"
	, count(*) filter (where discount != 0 ) as "Кол-во товаров со скидкой"
from "Sales"."OrderDetails"
group by orderid
;

--11.	Выведите количество заказов в разрезе стран и в разрезе городов. Представьте два варианта:
--a.	Первый вариант решения должен показывать количество только по странам и только по городам, и общее количество заказов 

select shipcountry as "Страна"
	, shipcity as "Город"
	, count(*) as "Кол-во заказов"
from "Sales"."Orders"
group by
grouping sets ((shipcountry), (shipcity), ())
;

--b.	Второй вариант – все возможные итоги.

select shipcountry as "Страна"
	, shipcity as "Город"
	, count(*) as "Кол-во заказов"
from "Sales"."Orders"
group by cube (shipcountry, shipcity)
;
--
--ВНИМАНИЕ: Вычисляемые столбцы должны иметь соответствующие наименования.
--
--
