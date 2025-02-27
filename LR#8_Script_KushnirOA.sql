--Лабораторная работа 8
--
--1.	Как выглядит общая структура блока PL/pgSQL? 

/*заголовок блока*/ as -- не обязательно
do
language --не обязательно, потому что
plpgsql  --по умолчанию будет plpgsql 
$block_name$ -- метка блока внутри $$ не обязательна
declare -- не обязательна
--Секция_объявления_переменных ;
begin
--Секция_исполнения кода ;
exception --не обязательна
--Секция обработки исключений ;
end
$block_name$ ; -- метка блока внутри $$ не обязательна

--2.	Как выглядит минимальный анонимный блок PL/pgSQL?
do 
$$
begin	
end
$$;

--3.	Напишите анонимный блок для вывода ‘Hello, World’. 
-- Для этого создайте переменную, присвойте ей значение Hello, World и выведите ее значение на экран.
--
do 
language
plpgsql
$HW$
declare
v_greeting	varchar(20) := 'Hello, World';
begin
	raise notice '%', v_greeting;
end
$HW$;

--4.	Измените созданный код так, чтобы выводилось на экран сообщение «В схеме Sales содержится таблица Customers». 
-- Имена объектов должны быть определены в качестве значения переменных.
--
do 
language
plpgsql
$HW$
declare
v_scemename	varchar(20) := 'Sales';
v_tablename	varchar(20) := 'Customers';
begin
	raise notice 'В схеме % содержится таблица %', v_scemename, v_tablename;
end
$HW$;

--5.	Напишите анонимный блок для вывода информации о количестве заказов, оформленных сотрудниками. 
--  В блоке должна осуществляться проверка количества заказов, оформленных сотрудниками с кодом 1 и 2. 
--  Текст сообщения должен варьироваться в зависимости от того, какой сотрудник оформил больше заказов, с указанием их количества. 
--
do language plpgsql
$Employees$
declare
	employees record;
	v_emp_hero int = 0;
	v_num_orders int = 0;
begin
	for employees in  

		select empid, count(orderid) as total_orders
		from "Sales"."Orders"
		where empid in (1, 2)
		group by empid

		loop
			if 	employees.total_orders > v_num_orders then
					v_num_orders = employees.total_orders;
					v_emp_hero = employees.empid;
			end if;
		end loop;

		raise notice 'Сотрудник с кодом % оформил больше заказов. Всего заказов %', v_emp_hero, v_num_orders;
end
$Employees$;
-- 
--6.	Напишите анонимный блок для вывода кода и полного имени сотрудника в цикле:

-- 1 вариант с циклом for по индексам:

do language plpgsql
$Employees$
declare
	v_empid	    "HR"."Employees".empid%type;
	v_firstname "HR"."Employees".firstname%type;
	v_lastname  "HR"."Employees".lastname%type;

	v_empid_min int = (select min(empid) from "HR"."Employees");
	v_empid_max int = (select max(empid) from "HR"."Employees");
begin
	for i in v_empid_min..v_empid_max loop

		select empid, firstname, lastname 
		into strict
		v_empid, v_firstname, v_lastname
		from "HR"."Employees"
		where empid = i; 
		
		raise notice 'Сотрудник с кодом % % %', v_empid, v_firstname, v_lastname;
		
	end loop;
end
$Employees$;

-- 2 вариант - итерации циклом for по записям:

do language plpgsql
$Employees$
declare
	employees record;

begin
	for employees in  

		select empid, firstname, lastname 
		from "HR"."Employees"
		order by 1 

		loop
		raise notice 'Сотрудник с кодом % % %', employees.empid, 
							employees.firstname, employees.lastname;		
		end loop;
end
$Employees$;
--
--7.	Напишите анонимный блок для вывода элементов из двумерного массива.
--Для этого объявите переменную и передайте ей двумерный массив
--ARRAY[ARRAY[ 10, 20, 30], ARRAY[100,200,300]]
--В исполняемой секции блока (BEGIN … END) с помощью цикла организуйте поэлементный вывод
-- 
do language plpgsql
$Employees$
declare
	v_array_2d integer[][] = ARRAY[ARRAY[ 10, 20, 30], ARRAY[100,200,300]];

begin
	
	for i in 1..array_length(v_array_2d, 1) loop
		for j in 1..array_length(v_array_2d, 2) loop		
		
		raise notice 'a[%][%] = %', i, j, v_array_2d[i][j];

		end loop;	
	end loop;
end
$Employees$;
