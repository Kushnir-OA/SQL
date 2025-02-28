--Лабораторная 1. Создание и модификация таблиц
--1.	Создайте БД – TulaTech_<ВашаФамилия>  с параметрами по умолчанию
create database "TulaTech_Kushnir";

--проверка:
select *
from pg_catalog.pg_database
--where datname = 'TulaTech_Kushnir'; -- конкретно моя БД
where datname ilike 'TulaTech%'; -- все БД с этого курса

--2.	Создайте в вашей БД схему schema1
create schema schema1;

--drop schema "schema1";

--3.	Создайте таблицу test в схеме schema1 и приведите код:
--Столбец	Тип данных 	Null
--name	VARCHAR(20)	NOT NULL
--price	NUMERIC(5,2)	NULL
--
create table if not exists 
schema1.test
(
name VARCHAR(20) NOT null,
price NUMERIC(5,2) NULL
)
;
--a)	Где физически располагается созданная вами таблица?

-- Физически она располагается на диске с сервером, 
-- в каталоге с обычными базовыми базами данных base $PGDATA\base\513720, 
-- где последний каталог называется по OID таблицы 513720 (OID посмотрела при помощи запроса ниже, 
-- а также его можно увидеть в Свойствах таблицы test в DBeaver),
-- а путь до этого каталога считается табличным пространством по умочанию pg_default

SELECT oid, relname
FROM pg_class 
WHERE relname = 'test';

-- проверка существования таблицы
select tablename, schemaname, tablespace
from pg_catalog.pg_tables
where tablename = 'test'
;

--b)	Заполните таблицу test несколькими строками:
INSERT INTO schema1.test (name, price) VALUES ('Apple', 1.52);
INSERT INTO schema1.test (name, price) VALUES ('Orange', 4.097);
INSERT INTO schema1.test (name, price) VALUES ('Peach', 9.5234);
INSERT INTO schema1.test (name, price) VALUES ('Banana', 2.2);
INSERT INTO schema1.test (name, price) VALUES ('Mango', 222.22);

--c)	Выведите все строки таблицы, обратите внимание на цену. Почему везде два знака после запятой, хотя вносились такие значения как 9.5234 и 2.2?
select *
from schema1.test;

-- Два знака после запятой во всех числах, т.к. в типе данных для столбца price мы указали NUMERIC(5,2), 
-- что предполагает хранение в столбце вещественных чисел с общим количеством цифровых знаков не более 5, 
-- 2 из которых будут после десятичной точки

--d)	Измените цену 'Peach' на значение NaN:

update schema1.test set price='NaN' where name='Peach';
--
--4.	Создайте временную таблицу tmp_test на основе выборки из таблицы test. В какой схеме находится таблица tmp_test?

create temporary table if not exists tmp_test as
select * from schema1.test
;

-- второй вариант
select * 
into temporary table tmp_test
from schema1.test
;

-- проверка существования таблицы
select tablename, schemaname, tablespace
from pg_catalog.pg_tables
where tablename = 'tmp_test'
;
-- 
select *
from tmp_test
;

--a)	Проверьте наличие toast-таблицы, ассоциированной с таблицей tmp_test

SELECT c1.oid, c1.reltoastrelid, c2.relname
   FROM pg_class AS c1
   LEFT JOIN pg_class AS c2
          ON c1.reltoastrelid = c2.oid
   WHERE c1.relname = 'tmp_test'
;
  
-- relname = NULL, reltoastrelid (ID) = 0, значит, ассоциированной toast-таблицы нет

  
--b)	Добавьте вычисляемый столбец price_discount. Значение в столбце должно вычисляться с учетом скидки 20% от исходной цены.
ALTER TABLE
tmp_test add column price_discount numeric(5, 2)
generated always as (price-price*0.2) stored
; 
  
--
--c)	Измените тип данных поля name на text.

alter table tmp_test
alter column name set data type text 
;
--
--d)	Проверьте наличие toast-таблицы, ассоциированной с таблицей tmp_test. Объясните результат
--
SELECT
relname, relfilenode 
FROM pg_class
where OID =
		(select reltoastrelid
		from pg_class
		where relname ='tmp_test'
		)
;
-- или 

SELECT c1.oid, c1.reltoastrelid, c2.relname
   FROM pg_class AS c1
   LEFT JOIN pg_class AS c2
          ON c1.reltoastrelid = c2.oid
   WHERE c1.relname = 'tmp_test'
;

-- Появилась toast-таблица pg_toast_514376, ассоциированная с таблицей tmp_test 
-- (oid таблицы tmp_test прописан в имени этой toast-таблицы)
-- toast-таблица, ассоциированная с нашей таблицей, создается, 
-- когда в таблице появляется хотя бы одна колонка с типом данных
-- допускающим хранение данных большого объема (в нашем примере text).
--
--e)	Измените тип данных поля name на varchar(30). 

alter table tmp_test
alter column name set data type varchar(30) 
;

--f)	Проверьте наличие toast-таблицы, ассоциированной с таблицей tmp_test. Объясните результат
SELECT
relname, relfilenode 
FROM pg_class
where OID =
		(select reltoastrelid
		from pg_class
		where relname ='tmp_test'
		)
;
-- или 

SELECT c1.oid, c1.reltoastrelid, c2.relname
   FROM pg_class AS c1
   LEFT JOIN pg_class AS c2
          ON c1.reltoastrelid = c2.oid
   WHERE c1.relname = 'tmp_test'
;

-- toast-таблица, ассоциированная с нашей таблицей, создается, 
-- когда в таблице появляется хотя бы одна колонка с типом данных
-- допускающим хранение большого объема данных (в нашем примере text).
-- Если же такую колонку удалить или изменить тип данных на тип, 
-- хранящий небольшие данные, toast-таблица удаляется сервером и первый запрос (с подзапросом) возвращает пустую строку, 
-- а второй запрос (с left join) показывает, что вместо имени toast-таблицы записан NULL

--
--g)	Проверьте возможность доступа к таблице tmp_test из новой сессии.
--
select *
from tmp_test
;

select tablename, schemaname, tablespace
from pg_catalog.pg_tables
where tablename = 'tmp_test'
;
-- из нового скрипта таблица не видна

--h)	Закройте текущую сессию. И войдите снова. Проверьте список доступных в БД таблиц. 

select tablename, schemaname, tablespace
from pg_catalog.pg_tables
;
-- в списке таблицы tmp_test нет, значит, после закрытия текущей сессии она была удалена сервером
--
--5.	Создайте нежурналируемую таблицу teacher в схеме schema1 и приведите код:
--Столбец	Тип данных 	Null
--teacher_id	serial	NOT NULL
--first_name	varchar	NULL
--last_name	varchar	NOT NULL
--birthday	date	NOT NULL
--phone	varchar	NULL
--title	varchar	NULL

create unlogged table if not exists schema1.teacher (
	teacher_id	serial	NOT null,
	first_name	varchar	null,
	last_name	varchar	NOT null,
	birthday	date	NOT null,
	phone	varchar	null,
	title	varchar	null
)
;
--
select *
from schema1.teacher
;

--a)	Добавьте в таблицу (после ее создания) колонку middle_name varchar

alter table schema1.teacher 
add column middle_name varchar
;
--

--b)	Удалите поле middle_name

alter table schema1.teacher 
drop column middle_name
;
--
--c)	Переименуйте поле birthday в birth_date
alter table schema1.teacher 
rename column birthday to birth_date
;

--
--d)	Измените тип данных столбца phone, чтобы иметь возможность сохранять в нем массив номеров телефонов.
alter table schema1.teacher 
alter column phone type text[] using phone::text[]
;

--
SELECT
pg_get_serial_sequence ('schema1.teacher', 'teacher_id');

select nextval('schema1.teacher_teacher_id_seq');

INSERT INTO schema1.teacher (first_name, last_name, birth_date) VALUES ('Ann', 'Ivanova', '2019-06-18');--, {'"8-910-04-55-90"', '"234568"'}::text[]);
update schema1.teacher set phone='{"8-910-04-55-90", "234568"}' where first_name ='Ann';
INSERT INTO schema1.teacher (first_name, last_name, birth_date, phone) VALUES ('Serge', 'Smith', '1999-10-09', '{"233-33-33", "+4-45-4444"}');

SELECT
relname, relfilenode 
FROM pg_class
where OID =
		(select reltoastrelid
		from pg_class
		where relname ='schema1.teacher'
		)
;
--6.	Удалите созданные таблицы. Приведите скрипт

-- временная таблица tmp_test будет удалена сервером после закрытия сессии

drop table if exists schema1.test;
drop table if exists schema1.teacher;


