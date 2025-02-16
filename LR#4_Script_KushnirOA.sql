--Лабораторная работа 4
--
--Задание 1. Написание запросов к нескольким таблицам
--
--1.	Выведите название продуктов, название категории продукта, цену. 
--Выборка должна включать только те продукты, которые не сняты с производства (discontinued=0).

select prod.productname
, cat.categoryname
, prod.unitprice
--, prod.discontinued 
from "Production"."Products" as prod
inner join "Production"."Categories" as cat
on prod.categoryid = cat.categoryid and prod.discontinued = cast(0 as bit)
;

--2.	Сформируйте выборку следующего вида:    ФИО сотрудника, Номер Заказа, Дата Заказа.
--Отсортируйте выборку по дате (от самых ранних к самым поздним заказам)
select he.lastname ||' '||he.firstname as "ФИО сотрудника",
	so.orderid as "Номер Заказа",
	so.orderdate as "Дата Заказа"
from  "Sales"."Orders" as so
inner join "HR"."Employees" as he
on so.empid = he.empid 
order by so.orderdate--, so.orderid 
;

--3.	Напишите запрос, который выбирает информацию о заказах и их деталях:[orderid], [custid],[empid],[orderdate] ,[productid],[unitprice],[qty],[discount].
--Сформируйте в этом запросе вычисляемый столбец (LineTotal), который рассчитывает стоимость каждой позиции в заказе с учетом скидки
select so.orderid, so.custid, so.empid, so.orderdate
, sod.productid, sod.unitprice, sod.qty, sod.discount
, (unitprice * qty)*(1 - discount)  as "LineTotal"
from "Sales"."Orders" as so 
inner join "Sales"."OrderDetails" as sod
on so.orderid = sod.orderid 
;
--4.	Напишите запрос, возвращающий номер заказа, имя заказчика, компанию заказчика (в таблице-примере - титул заказчика - тоже выведу), дату заказа и столбец employeer. Столбец employeer должен формироваться из имени, фамилии сотрудника и его должности.
-- 
select so.orderid 
	, sc.contactname, sc.contacttitle, sc.companyname
	, so.orderdate
	, he.firstname || ' ' || he.lastname || ', ' || he.title as "employeer"
from "Sales"."Customers" as sc 
inner join "Sales"."Orders" as so 
on sc.custid  = so.custid 
inner join "HR"."Employees" as he
on so.empid = he.empid 
;

--5.	Напишите запрос, возвращающий выборку следующего вида:   Номер заказа, Название заказчика, Фамилия сотрудника (компании заказчика), Дата заказа, Название транспортной компании.
--В запрос должны войти только те записи, которые соответствуют условию:  Заказчики и Сотрудники проживают в одном городе
--
select so.orderid as "Номер заказа"
	, sc.companyname as "Название заказчика", split_part(sc.contactname, ',', 1) as "Фамилия сотрудника (заказчика)"
	, so.orderdate as "Дата заказа"
	, ss.companyname as "Название транспортной компании"
	, he.city as "Город сотрудника HR"      -- для проверки
	, sc.city as "Город заказчика" -- для проверки
from "Sales"."Customers" as sc 
inner join "Sales"."Orders" as so 
on sc.custid  = so.custid 
inner join "Sales"."Shippers" as ss
on so.shipperid = ss.shipperid 
inner join "HR"."Employees" as he
on so.empid = he.empid 
-- where he.city = sc.city -- исправление
where he.city = sc.city and he.country = sc.country -- исправление
;
--*********** замечание
--Если в разных странах будет город с одинаковым название данного условия будет достаточно?
--***********

--6.	Напишите запрос, отражающий менеджеров и их сотрудников. Результирующая таблица должна состоять из 2 столбцов: employeer и manager, и состоять из имени и фамилии одних и других.

select emp.firstname || ' ' || emp.lastname as employeer
		, mgr.firstname || ' ' || mgr.lastname as manager
from "HR"."Employees" as emp
left join "HR"."Employees" as mgr --использую left join, чтобы вывести и гендиректора - сотрудника без менеджера 
on mgr.empid = emp.mgrid 
;

--7.	Напишите запрос, возвращающий список заказчиков, которые не делали заказы.

select sc.contactname
, so.orderid,so.custid 

from "Sales"."Customers" as sc
left join "Sales"."Orders" as so
on sc.custid = so.custid 
--where so.custid is null --исправление
where so.orderid is null  --исправление
;
--*********** замечание
--При использовании внешнего соединения правильнее фильтровать на основе первичного столбца. 
--В таблице Заказов номер клиента потенциально и так может быть пустым (NULL), а вот номер заказа (oderid) пустым быть не может.
--И если в результирующей выборке в этом столбце не окажется значения - значит для конкретного клиента заказ не был найден.
--***********

--8.	Выведите уникальный список, включающий название компании заказчика, страну доставки заказа и страну заказчика, при условии, что это разные страны
-- 
select distinct sc.companyname, sc.country, so.shipcountry
from "Sales"."Customers" as sc
inner join "Sales"."Orders" as so
on sc.custid = so.custid 
where so.shipcountry != sc.country
;
-- 
--Задание 2. Использование операторов наборов записей (UNION, EXCEPT, INTERSECT)
--1.	Напишите запрос, возвращающий набор уникальных записей из таблиц Employees и Customers. Результирующая таблица должна содержать 3 столбца: country, region, city.

select country, region, city
from "HR"."Employees"
union
select country, region, city
from "Sales"."Customers"
;

--2.	Напишите запрос, возвращающий набор уникальных записей из таблиц Employees (адреса сотрудников - country, region, city), исключив из этого списка записи из таблицы Customers (адреса Клиентов - country, region, city). Результирующая таблица должна содержать 3 столбца: country, region, city. 

select country, region, city
from "HR"."Employees"
except
select country, region, city
from "Sales"."Customers"
;

--3.	Выведите список стран, где живут сотрудники и находятся заказчики.

select country
from "HR"."Employees"
intersect
select country
from "Sales"."Customers"
;
