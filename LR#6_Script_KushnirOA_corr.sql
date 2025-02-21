--Лабораторная работа 6
--
--1.	Выведите информацию о заказах клиента, который был зарегистрирован в БД последним.

-- максимальный custid в таблице "Sales"."Customers" у клиента, 
-- который не делал заказов => таблица выдается пустая. 
-- Поэтому для проверки проверяла и предыдущего:

select custid, orderid, orderdate
from "Sales"."Orders"
where custid = (select max(custid)-- -1 -- раскомментировать -1 для проверки
				from "Sales"."Customers")
;

--2.	Выведите следующие данные по клиентам, которые сделали заказ в самую последнюю дату
-- 
select companyname
	, contactname
	, contacttitle
	, address
	, city
	, region
	, postalcode
from "Sales"."Customers"
where custid in (select custid --, orderdate -- для проверки подзапроса
				from "Sales"."Orders"
				where orderdate = (select max(orderdate)
									from "Sales"."Orders")
				)
;


--3.	Выведите список клиентов, которые не делали заказов
-- 
--Для реализации данного задания напишите 2 запроса:
--1) с использованием вложенного подзапроса,

select custid
	, companyname
	, contactname
	, contacttitle
	, address
	, city
from "Sales"."Customers"
where custid != all (select custid
					from "Sales"."Orders"
					) 
;

--2) с использованием коррелированного подзапроса с предикатом EXISTS.

select custid
	, companyname
	, contactname
	, contacttitle
	, address
	, city
from "Sales"."Customers" as sc
where not exists (select 1
					from "Sales"."Orders" as so 
					where so.custid = sc.custid 
					)
;
--
--4.	Выведите список заказов тех клиентов, которые проживают в Mexico
select custid
, orderid
, orderdate
, shipcountry
from "Sales"."Orders" as so
where custid = some (select custid
				from "Sales"."Customers"
				where country = 'Mexico'
				)
;
-- 
--5.	Выведите самые дорогие продукты в каждой категории. Детали должны присутствовать!
-- 
select *
from "Production"."Products"
where (categoryid, unitprice) in 
								(select categoryid, max(unitprice) 
								from "Production"."Products"
								group by categoryid)
;

--6.	Используя подзапрос выведите название продукта и название категории, к которой относится этот продукт.
-- 
select productname 
	, ( select categoryname
		from "Production"."Categories" as pc
		where pp.categoryid = pc.categoryid )
from "Production"."Products" as pp
;


--7.	Выведите информацию о заказчиках, за исключением тех, кто купил менее 30 наименований продуктов.
-- 
select sc.custid
	, sc.companyname
	, sc.contacttitle
from "Sales"."Customers" as sc
where (select count(distinct sod.productid)
		from "Sales"."OrderDetails" as sod
		where (select so.custid
				from "Sales"."Orders" as so
		 		where so.orderid = sod.orderid) = sc.custid)
> 30
;

-- вариант с join
--select sc.custid
--	, sc.companyname
--	, sc.contacttitle
--from "Sales"."Customers" as sc
--where (select count(distinct sod.productid)
--	from "Sales"."OrderDetails" as sod
--	inner join
--	"Sales"."Orders" as so
--	on so.orderid = sod.orderid
--	where  sc.custid = so.custid)
--> 30
--;

--
--8.	Выведите информацию о заказах, которые входят в 5 самых дорогих и при этом страной доставки заказа является Бразилия.

-- первый вариант, когда сначала ищу топ 5 заказов, а потом отбираю среди них только те, что доставлены в Бразилию

select so.orderid
	, custid
	, orderdate
	, shipcountry
	,"OrderTotal"
from "Sales"."Orders" as so
inner join 
			(
			select orderid, sum( unitprice * qty * (1 - discount)) as "OrderTotal"
			from "Sales"."OrderDetails"
			group by orderid
			order by sum( unitprice * qty * (1 - discount)) desc
			fetch next 5 rows only 
			) as t(orderid, "OrderTotal")
on so.orderid = t.orderid
where  shipcountry = 'Brazil'
;

-- или используя CTE

with CTE_orderDetails as 
			(select orderid, sum( unitprice * qty * (1 - discount)) as "OrderTotal"
			from "Sales"."OrderDetails"
			group by orderid
			order by sum( unitprice * qty * (1 - discount)) desc
			fetch next 5 rows only 
)
select so.orderid
	, custid
	, orderdate
	, shipcountry
	,"OrderTotal"
from "Sales"."Orders" as so
inner join
CTE_orderDetails as cod
on so.orderid = cod.orderid
where 
shipcountry = 'Brazil'
;

-- второй вариант, когда сначала ищу заказы, доставляемые в Бразилию, а потом вывожу топ 5 по ним

select orderid
	, custid
	, orderdate
	, shipcountry
	,(select (sum( unitprice * qty * (1 - discount)) )
		from "Sales"."OrderDetails" as sod
		where sod.orderid = orderid)  as "OrderTotal"
		
from "Sales"."Orders" as so
where  shipcountry = 'Brazil'
group by so.orderid
order by "OrderTotal" desc
fetch next 5 rows only 
;
--9.	Выведите следующую информацию о заказчиках и количестве сделанных ими заказов. Решите данную задачу 2 способами:
--a.	Используя коррелированный подзапрос

select 
	sc.companyname
	, sc.country 
	, (select count(*)
		from "Sales"."Orders" as so
		 where so.custid = sc.custid) as ord_qw
from "Sales"."Customers" as sc
;

--b.	Используя подзапрос LATERAL
-- 
select 
	sc.companyname
	, sc.country 
	, t.ord_qw
from "Sales"."Customers" as sc
cross join lateral
--, lateral
(	
	select count(*) 
	from "Sales"."Orders" as so
	where so.custid = sc.custid
) as t(ord_qw)
;

--
--10.	Выведите минимальную и максимальную стоимость заказа для каждого заказчика

select
	sc.custid
	, sc.companyname
	, sc.country 
	, min(t."Total") as "Min_Total"
	, max(t."Total") as "Max_Total"
from "Sales"."Customers" as sc
cross join lateral
(	
	select sum(unitprice*qty*(1 - discount)) as "Total"
	from "Sales"."Orders" as so
	inner join
	"Sales"."OrderDetails" as sod
	on so.orderid = sod.orderid
	where so.custid = sc.custid
	group by so.orderid
) as t
group by sc.custid 
;

-- запрос вывести полную стоимость каждого заказа - для проверки правильности поиска мин и макс заказа по каждому покупателю
select
	sc.custid
	, sc.companyname
	, sc.country 
	, t."Total" 
from "Sales"."Customers" as sc
cross join lateral
(	
	select sum(unitprice*qty*(1 - discount)) as "Total"
	from "Sales"."Orders" as so
	inner join
	"Sales"."OrderDetails" as sod
	on so.orderid = sod.orderid
	where so.custid = sc.custid
	group by so.orderid

) as t
order by sc.custid 
;


--11.	Проанализируйте следующий запрос. Выполните и опишите, что он возвращает:
select *
from (values (1, 'expensive', 250),
    (2, 'middle', 150),
    (3, 'cheap', 50)
) as t1(id, preorder, desired_price),
    lateral  (select *
        from "Production"."Products" as t2
        where t2.unitprice::numeric < t1.desired_price
        order by t2.unitprice desc
        limit 3
       ) as tt;

-- Запрос возвращает таблицу - внутреннее соединение двух таблиц: 
-- 1-таблица t1, сгенерированная конструктором values, и 
-- 2-таблица tt - выбранные строки из таблицы "Production"."Products".
-- Строки из "Production"."Products" отбираются при помощи коррелированного подзапроса:
-- каждой строке из t1 сопоставляются 3 строки из "Production"."Products",
-- отобранные по условию, что цена товара должна быть меньше числа, 
-- указанного в строке таблицы t1 в колонке desired_price, и при этом при помощи 
-- сортировнки отбираются продукты с максимально возможными для данного условия ценами.
-- Таким образом, получена таблица градации самых дорогих продуктов магазина 
-- в категориях "дорогой", "средний", "дешевый" ценовой сегмент.
-- Бизнес-вывод: магазин не торгует товарами из "дорогого" сегмента 
-- (самая высокая цена товара ниже максимальной "средней" цены)
-- Причем, товары по максимальным для категории "средний" и "низкий" ценам сняты с продажи
      
--12.	Проанализируйте и объясните следующий запрос. 
with recursive hw(_array, i, r) as (

    values (array['H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd', '!'], 1, '')
    union all
    select _array, i + 1, r || _array[i] from hw where i <= array_length(_array, 1)
)
select * from hw;

-- Запрос выводит строки из CTE-таблицы с именем hw, формируемой рекурсивными запросами к ней же:
-- каждый запрос к CTE-таблице hw возвращает строку, которая объединяется 
-- с результатами предыдущих запросов оператором объединения таблиц union all.  
-- Первая строка в таблице hw задана конструктором values и состоит из трех колонок:
-- "_array", где размещается массив символов, "i", куда записано значение 1
-- и "r", куда записана пустая строка.
-- Далее в результате рекурсивного запроса получается вторая строка, 
-- где в колонке "_array" значение не меняется (так и остается массив символов _array),
-- к значению в колонке "i" прибавляется 1
-- и к пустой строке в колонке "r" при помощи конкатенации добавляется i-й символ 
-- и массива _array, то есть _array[1]='H', => в колонке "r" появляется строка "H".
-- И таким образом формируется таблица из 14 строк, где в первой колонке неизменно
-- массив символов, во второй записываются целые числа по возрастанию,
-- а в третей последовательно формируется строка из символов массива _array.
-- Рекурсия останавливается, когда последний запрос считает из колонки "i" значение, равное длине массива _array
-- 