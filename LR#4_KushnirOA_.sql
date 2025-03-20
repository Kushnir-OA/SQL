--Лабораторная 4. Дополнительные возможности создания таблиц
--Работайте с вашей БД TulaTech_<ВашаФамилия>. 
--
--1)	Наследование таблиц
--
--Задание 1. Необходимо реализовать возможность хранения информации о событиях в системе, разделенной по месяцам. 
--1.	Создайте схему example1.

create schema if not exists example1;

--2.	В схеме example1 создайте таблицу logging со следующей структурой:
--Столбец	Тип данных	Ограничения
--id	integer	NOT NULL, PK
--Автоматически генерируемый столбец 
--IDENTITY (min значение 1, шаг 1, max значение 2147483647)
--event_name	Character varying	NOT NULL
--start_time	timestamp(6) without time zone	NOT NULL
--end_time	timestamp(6) without time zone	NOT NULL

create table if not exists example1.logging 
(

	id integer generated always as identity (increment by 1 minvalue 1 maxvalue 2147483647)	NOT null primary key,
	
	event_name	character varying	NOT null,
	start_time	timestamp(6) without time zone	NOT null,
	end_time	timestamp(6) without time zone	NOT NULL
);
--
--3.	Заполните таблицу событиями за 2024 год. 
--a.	Убедитесь, что данные успешно сохранены
--event_name	start_time	end_time
--'Log in'	'2024-01-11 03:26:11'	'2024-01-11 03:26:13'
--'Log out'	'2024-02-03 12:11:17'	'2024-02-03 12:11:18'
--'Upload file xml'	'2024-02-06 16:14:28'	'2024-02-06 16:14:59'
--'Delete data'	'2024-01-05 23:01:55'	'2024-01-05 23:01:58'

insert into example1.logging(event_name, start_time, end_time)
values ('Log in', '2024-01-11 03:26:11', '2024-01-11 03:26:13'),
		('Log out', '2024-02-03 12:11:17',	'2024-02-03 12:11:18'),
		('Upload file xml',	'2024-02-06 16:14:28',	'2024-02-06 16:14:59'),
		('Delete data',	'2024-01-05 23:01:55',	'2024-01-05 23:01:58')
;

select * from example1.logging;
--
--4.	Создайте дочернюю таблицу регистрации january_log_2025, которая наследует поля из родительской таблицы logging.

create table example1.january_log_2025() 
inherits(example1.logging)
;
--b.	Таблица должна позволять регистрировать события, которые произошли в январе 2025 года.

-- Добавлю ограничение check, думаю, только на один столбец - start_time, 
-- на end_time не буду на случай пограничных событий, когда начало события - 31 января, ближе к полночи, 
-- то закончиться формально оно может уже 1 февраля

alter table example1.january_log_2025
add constraint jan25_check check (start_time between '2025-01-01 00:00:00' and '2025-02-01 00:00:00')
;

-- Ну и проверку, что начало события не позже, чем окончание, было бы полезно добавить, мне кажется,
-- на уровне родительской таблицы тоже, и оно унаследуется всеми потомками:

alter table example1.logging
add constraint start_end_check check (start_time <= end_time)
;

--5.	Унаследовала ли дочерняя таблица свойство IDENTITY столбца id родительской таблицы?

-- нет, не унаследовала: при вставке строк в дочернюю таблицу без указания значений для первой колонки id генерируется ошибка,
-- что нельзя вставить null-значение в колонку not null (это ограничение унаследовалось). Т.е. автоматически
-- значения не генерируются, свойства IDENTITY у колонки id нет

-- Поэтому можно привязать к колонке уже имеющуюся последовательность example1.logging_id_seq
-- при помощи ограничения default, а также сделать эту колонку первичным ключом:

alter table example1.january_log_2025
add primary key (id);

alter table example1.january_log_2025
alter column id set default nextval('example1.logging_id_seq'::regclass);

--6.	Заполните таблицу регистрации событиями за январь 2025 года:
--id	event_name	start_time	end_time
--1	'Log in'	'2025-01-11 03:26:11'	'2025-01-11 03:26:13'
--2	'Log out'	'2025-01-03 12:11:17'	'2025-01-03 12:11:18'
--3	'Upload file xml'	'2025-01-06 16:14:28'	'2025-01-06 16:14:59'
--4	'Delete data'	'2025-01-05 23:01:55'	'2025-01-05 23:01:58'
--
insert into example1.january_log_2025(event_name, start_time, end_time)
values ('Log in', '2025-01-11 03:26:11', '2025-01-11 03:26:13'),
		('Log out', '2025-01-03 12:11:17',	'2024-01-03 12:11:18'),
		('Upload file xml',	'2025-01-06 16:14:28',	'2024-01-06 16:14:59'),
		('Delete data',	'2025-01-05 23:01:55',	'2025-01-05 23:01:58')
;

select tableoid::regclass, * from example1.logging;


--7.	Создайте дочернюю таблицу регистрации february_log_2025, которая наследует поля из родительской таблицы logging. 
--a.	Таблица должна позволять регистрировать события, которые произошли в феврале 2025 года.
--b.	Таблица должна содержать дополнительный столбец user_name (для сохранения информации о зарегистрировавшем событие пользователе)


create table example1.february_log_2025
(user_name varchar(25) not null) 
inherits(example1.logging)
;

-- тоже добавляю ограничение check на столбец start_time:
alter table example1.february_log_2025
add constraint feb25_check check (start_time between '2025-02-01 00:00:00' and '2025-03-01 00:00:00')
;

-- добавляю первичный ключ в дочернюю таблицу
alter table example1.february_log_2025
add primary key (id);

-- добавляю связь с последовательностью из родительской таблицы для генерации уникальных сквозных значений
alter table example1.february_log_2025
alter column id set default nextval('example1.logging_id_seq'::regclass);

-- добавляю ограничение default для колонки user_name - имя пользователя текущего сеанса - 
-- чтобы не вводить вручную на следующем шаге
alter table example1.february_log_2025
alter column user_name set default session_user;

--8.	Заполните таблицу регистрации событиями за февраль 2025 года. В качестве значений столбца user_name используйте имя пользователя текущего сеанса
insert into example1.february_log_2025(event_name, start_time, end_time)
values ('Log in', '2025-02-11 03:26:11', '2025-02-11 03:26:13'),
		('Log out', '2025-02-03 12:11:17',	'2024-02-03 12:11:18'),
		('Upload file xml',	'2025-02-06 16:14:28',	'2024-02-06 16:14:59'),
		('Delete data',	'2025-02-05 23:01:55',	'2025-02-05 23:01:58')
;
--c.	Убедитесь, что данные успешно сохранены

-- убеждаюсь запросом именно к этой таблице, т.к. по запросу к родительской таблице не будет выводиться колонка user_name

select * from example1.february_log_2025;

--9.	Проверьте возможность получения данных через родительскую таблицу

select tableoid::regclass, * from example1.logging;

-- через родительскую таблицу можно получить все данные из общих столбцов семейства таблиц, 
-- но невозможно получить информацию из столбцов, 
-- которые не наследуются, а были созданы только в дочерних таблицах

--a.	Сохраняется ли уникальность в столбце id? Почему?

-- в столбце id уникальность не сохраняется при наследовании, но можно добавить связь
-- с последовательностью из родительской таблицы для генерации уникальных сквозных значений
-- (можно и с другой последовательностью, но тогда придется продумать, каким образом обеспечить 
-- неповторяющиеся значения во всем семействе таблиц)

--10.	Удалите записи из таблицы logging. Остались ли записи в дочерних таблицах?

-- если нужно удалить данные только из родительской таблицы, 
-- нужно использовать служебное слово

delete from ONLY example1.logging
where event_name = 'Log out'
;

-- убеждаюсь, что соответствующая фильтру запись удалилась только в родительской таблице:
 
select tableoid::regclass, * from example1.logging;

-- если же удалять данные без использования служебного слова ONLY,
-- то данные удаляются из всего семейства таблиц 

delete from example1.logging
where event_name = 'Log in'
;

-- убеждаюсь, что соответствующие фильтру записи удалились во всем семействе таблиц:

select tableoid::regclass, * from example1.logging;

--11.	Удалите таблицу.

-- Удалить только родительскую таблицу, не удаляя при этом дочерние, нельзя.
-- Такой запрос вызывает ошибку (от этой таблицы зависят другие таблицы):

drop table if exists example1.logging;

-- если надо удалить таблицу вместе со всеми ее потомками, то надо использовать служебное слово CASCADE:

drop table if exists example1.logging CASCADE;

--
--2)	Секционирование таблиц
--
--Задание 1. 
--Реализуйте следующее решение: Необходимо создать секционированную таблицу sales в соответствии с приведенной схемой секционирования.
--1)	Секционированная таблица и ее секции должны размещаться в схеме partitions

create schema if not exists partitions;

-- создаю основную секционированную таблицу с секционированием по диапазону дат

create table if not exists partitions.sales
(
	trans_id serial not null,
	s_date date not null,
	region varchar(10)
)
partition by range(s_date)
; 

-- по ее образу создаю три секционированных таблицы с секционированием по списку регионов

create table if not exists partitions.sales_jan25
	(like partitions.sales
	INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
partition by list(region)
;

create table if not exists partitions.sales_feb25
	(like partitions.sales
	INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
partition by list(region)
;

create table if not exists partitions.sales_mar25
	(like partitions.sales
	INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
partition by list(region)
;

-- к каждой из трех секционированных по регионам таблиц добаляю по три секции со значениями регионов

create table if not exists partitions.sales_jan25_asia
partition of partitions.sales_jan25
for values in ('asia')
;

create table if not exists partitions.sales_jan25_europe
partition of partitions.sales_jan25
for values in ('europe')
;

create table if not exists partitions.sales_jan25_usa
partition of partitions.sales_jan25
for values in ('usa')
;

create table if not exists partitions.sales_feb25_asia
partition of partitions.sales_feb25
for values in ('asia')
;

create table if not exists partitions.sales_feb25_europe
partition of partitions.sales_feb25
for values in ('europe')
;

create table if not exists partitions.sales_feb25_usa
partition of partitions.sales_feb25
for values in ('usa')
;

create table if not exists partitions.sales_mar25_asia
partition of partitions.sales_mar25
for values in ('asia')
;

create table if not exists partitions.sales_mar25_europe
partition of partitions.sales_mar25
for values in ('europe')
;

create table if not exists partitions.sales_mar25_usa
partition of partitions.sales_mar25
for values in ('usa')
;

-- Сомневаюсь, что это нужно здесь, т.к. таблицы, секционированные по диапазону дат, не содержат данных,
-- но на всякий случай и для тренировки перед присоединением их к основной секционированной таблице sales
-- устанавливаю ограничение check для помощи серверу


alter TABLE partitions.sales_jan25
add CONSTRAINT y2025m01
check ( s_date >= DATE '2025-01-01'
and s_date < DATE '2025-02-01')
;

alter TABLE partitions.sales_feb25
add CONSTRAINT y2025m02
check ( s_date >= DATE '2025-02-01'
and s_date < DATE '2025-03-01')
;

alter TABLE partitions.sales_mar25
add CONSTRAINT y2025m03
check ( s_date >= DATE '2025-03-01'
and s_date < DATE '2025-04-01')
;

-- присоединяю три таблицы к основной таблице sales
alter table partitions.sales
attach partition partitions.sales_jan25
for values from ('2025-01-01') to ('2025-02-01')
;

alter table partitions.sales
attach partition partitions.sales_feb25
for values from ('2025-02-01') to ('2025-03-01')
;

alter table partitions.sales
attach partition partitions.sales_mar25
for values from ('2025-03-01') to ('2025-04-01')
;

-- и теперь после удачного присоединения удаляю ограничения check,
-- т.к. теперь все проверки будет делать секционированная таблица

alter TABLE partitions.sales_jan25
drop CONSTRAINT y2025m01;

alter TABLE partitions.sales_feb25
drop CONSTRAINT y2025m02;

alter TABLE partitions.sales_mar25
drop CONSTRAINT y2025m03;
--
--2)	Добавьте в таблицу данные и проверьте корректность их размещения в таблицах-секциях.

insert into partitions.sales(s_date, region)
values  ('2025-01-01', 'asia'), ('2025-01-02', 'europe'), ('2025-01-03', 'usa'),
		('2025-01-05', 'asia'), ('2025-01-09', 'europe'), ('2025-01-16', 'usa'),
		('2025-01-18', 'asia'), ('2025-01-21', 'europe'), ('2025-01-31', 'usa'),
		('2025-02-01', 'asia'), ('2025-02-01', 'europe'), ('2025-02-01', 'usa'),
		('2025-02-11', 'asia'), ('2025-02-12', 'europe'), ('2025-02-19', 'usa'),
		('2025-02-21', 'asia'), ('2025-02-22', 'europe'), ('2025-02-28', 'usa'),
		('2025-03-01', 'asia'), ('2025-03-02', 'europe'), ('2025-03-02', 'usa'),
		('2025-03-04', 'asia'), ('2025-03-05', 'europe'), ('2025-03-07', 'usa'),
		('2025-03-11', 'asia'), ('2025-03-13', 'europe'), ('2025-03-14', 'usa'),
		('2025-03-15', 'asia'), ('2025-03-22', 'europe'), ('2025-03-31', 'usa')
;

--3)	Приведите проверочный запрос
--
select tableoid::regclass, *
from partitions.sales;
--

--3)	По желанию:
--Задание 2. 
--Добавьте в таблицу новую секцию - апрель 2025 года. Для этого:
--1)	Создайте новую таблицу

-- создаю также, как и три предыдущие таблицы по месяцам с секциями-регионами 
create table partitions.sales_apr25
	(
	like partitions.sales
	including  defaults including constraints
	)
partition by list(region)
;

create table if not exists partitions.sales_apr25_asia
partition of partitions.sales_apr25
for values in ('asia')
;

create table if not exists partitions.sales_apr25_europe
partition of partitions.sales_apr25
for values in ('europe')
;

create table if not exists partitions.sales_apr25_usa
partition of partitions.sales_apr25
for values in ('usa')
;

--2)	Добавьте в нее данные о продажах за апрель

insert into partitions.sales_apr25(s_date, region)
values  ('2025-04-01', 'asia'), ('2025-04-02', 'europe'), ('2025-04-03', 'usa'),
		('2025-04-05', 'asia'), ('2025-04-09', 'europe'), ('2025-04-10', 'usa'),
		('2025-04-12', 'asia'), ('2025-04-15', 'europe'), ('2025-04-18', 'usa'),
		('2025-04-19', 'asia'), ('2025-04-25', 'europe'), ('2025-04-30', 'usa')
;

-- проверка
select tableoid::regclass, *
from partitions.sales_apr25;

--3)	Подключите данную таблицу в виде секции к таблице Sales

alter TABLE partitions.sales_apr25
add CONSTRAINT y2025m04
check ( s_date >= DATE '2025-04-01'
and s_date < DATE '2025-05-01')
;

alter table partitions.sales
attach partition partitions.sales_apr25
for values from ('2025-04-01') to ('2025-05-01')
;

alter TABLE partitions.sales_apr25
drop CONSTRAINT y2025m04
;

-- проверка
select tableoid::regclass, *
from partitions.sales
;

--Задание 3.
--1.	Отключите от таблицы секцию – jan25.

alter table partitions.sales
detach partition partitions.sales_jan25
;

-- проверка
select tableoid::regclass, *
from partitions.sales
;

--2.	Отключаемые секции должны становиться частью таблицы –sales_arhive
--
-- создаю таблицу sales_arhive по образу таблицы sales
create table partitions.sales_arhive
	(
	like partitions.sales
	including  defaults including constraints
	)
partition by range(s_date)
;

-- подключаю.
alter table partitions.sales_arhive
attach partition partitions.sales_jan25
for values from ('2025-01-01') to ('2025-02-01')
;

-- проверка
select tableoid::regclass, *
from partitions.sales_arhive
;


Создавая таблицу-секцию первого порядка, можно сразу было ее создавать с нужным диапазоном. В этом случае не пришлось бы ее в последствии присоединять:
**********************
--create table Jan25
--partition of example1.sales
--for values from ('2025-01-01'::date) to ('2025-02-01'::date)
--partition by list (region);

-- создам таким образом новую партицию для данных мая 2025 года, и убеждаюсь, что все работает:

create table if not exists partitions.sales_may25
partition of partitions.sales
for values from ('2025-05-01'::date) to ('2025-06-01'::date)
partition by list (region);

create table if not exists partitions.sales_may25_asia
partition of partitions.sales_may25
for values in ('asia')
;

create table if not exists partitions.sales_may25_europe
partition of partitions.sales_may25
for values in ('europe')
;

create table if not exists partitions.sales_may25_usa
partition of partitions.sales_may25
for values in ('usa')
;

insert into partitions.sales_may25(s_date, region)
values  ('2025-05-01', 'asia'), ('2025-05-02', 'europe'), ('2025-05-03', 'usa'),
		('2025-05-05', 'asia'), ('2025-05-09', 'europe'), ('2025-05-10', 'usa'),
		('2025-05-12', 'asia'), ('2025-05-15', 'europe'), ('2025-05-18', 'usa'),
		('2025-05-19', 'asia'), ('2025-05-25', 'europe'), ('2025-05-31', 'usa')
;

select tableoid::regclass, * from partitions.sales;

alter table partitions.sales
detach partition partitions.sales_feb25;

alter table partitions.sales_arhive
attach  partition partitions.sales_feb25
for values from ('2025-02-01') to ('2025-03-01')
;

select tableoid::regclass, * from partitions.sales_arhive;
