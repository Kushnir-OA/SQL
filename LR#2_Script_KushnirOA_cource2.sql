--Лабораторная 2. Создание ограничений целостности
--Работайте с вашей БД TulaTech_<ВашаФамилия>. 
--Задание 1. 
--Создайте в схеме schema1 таблицу countries (справочник стран) и приведите код:
--1.	Таблица должна содержать следующие поля: country_id, country_name и region_id. Выберите для данных столбцов подходящие типы данных
--2.	Необходимо гарантировать, что в таблицу не будут введены никакие страны, кроме России, Индии, Китая, Бразилии, Казахстана, Киргизии и Белоруссии.
--3.	Столбец country_id:
--a.	должен быть ключевым столбцом таблицы. 
--b.	значения в столбце должны вычисляться автоматически, начиная с 1 с шагом 2. 
-- alter sequence increment by 2 (как вариант)
--4.	Значения комбинации столбцов country_id и region_id должны быть уникальными. 
create table if not exists schema1.countries
(
	country_id int generated always as identity(start with 1 increment by 2) primary key, 
	country_name varchar(20),
	region_id int,
	constraint cntry_chk check (country_name in ('Россия', 'Индия', 'Китай', 'Бразилия', 'Казахстан', 'Киргизия', 'Белоруссия')),
	constraint AK_cntry_rgn unique(country_id, region_id)
)
;

------ для проверки заполняем таблицу countries и выводим ее:

insert into schema1.countries(country_name, region_id)
values ('Россия', 45), ('Казахстан', 7), ('США', 1);

select * from schema1.countries;
-----------------------------------------------------


--5.	Удалите ограничение на перечень допустимых стран

alter table schema1.countries
drop constraint cntry_chk;

--6.	Удалите столбец region_id

alter table schema1.countries
drop column region_id;

-- при удалении столбца region_id автоматически и без вопросов удалилось и ограничение unique(country_id, region_id)
--

--Задание 2. 
--Создайте в схеме schema1 таблицу addresses (справочник адресов) со следующей структурой и приведите код:
--Поле	Тип
--address_id	numeric(4,0)
--street	character varying (40)
--postal_code	character varying (6)
--city	character varying (30)
--country_id	? (см.п.3 задания)

create table if not exists schema1.addresses
(
	address_id	numeric(4,0),
	street	character varying (40),
	postal_code	character varying (6),
	city	character varying (30),
	country_id	int
)
;
--1.	Создайте в таблице addresses составной первичный ключ на основе столбцов address_id и country_id.

alter table schema1.addresses
add constraint pk_addr_cntry primary key (address_id, country_id)
;
--2.	Добавьте ограничение на столбец postal_code, запрещающее ввод нечисловых значений

alter table schema1.addresses
add constraint chk_code check(postal_code !~ '\D')
;

--3.	Столбец country_id должен содержать только те значения, которые существуют в таблице countries в столбце country_id. 

-- так как таблица addresses уже была заполнена, тренируюсь использовать директиву not valid
alter table schema1.addresses
add constraint fk_cntries foreign key (country_id)
references schema1.countries(country_id) not valid;

-- затем исправляю значение в country_id на то, которое есть в таблице countries
update schema1.addresses
set country_id = 19
where country_id = 8;

-- проверяю значения внешнего ключа снова
alter table schema1.addresses
validate constraint fk_cntries ;

--4.	Выведите столбец country_id из состава первичного ключа.

alter table schema1.addresses
drop constraint pk_addr_cntry 
;

alter table schema1.addresses
add constraint pk_addr primary key (address_id)
;

------ для проверок заполняем таблицу addresses и выводим ее:
insert into schema1.addresses
values (7, 'Bnjjdjd', '4260', 'Moscow', 8);

select * from schema1.addresses;
-----------------------------------------------------
--
--Задание 3. 
--Создайте в схеме schema1 таблицу departments (справочник офисов) со следующей структурой и приведите код:
--Поле	Тип данных	Ограничения
--department_id	numeric(4,0)	not null
--department_name	character varying (30)	not null
--manager_id	numeric(6,0)	not null
--address_id	numeric(4,0)	default null::numeric

create table if not exists  schema1.departments
(
	department_id	numeric(4,0)		not null,
	department_name	character varying (30)	not null,
	manager_id		numeric(6,0)		not null,
	address_id		numeric(4,0)		default null::numeric
)
;

--1.	Создайте в таблице составной первичный ключ – (department_id, manager_id)

alter table schema1.departments
add constraint pk_depid_manid primary key(department_id, manager_id)
;
--2.	Убедитесь, что автоматически был создан индекс

-- Автоматически соданный индекс можно видеть в графическом интерфейсе DBeaver в ветке схемы scema1, раздел Индексы
-- Он отражается там как departments.pk_depid_manid
--
-- Также можно проверить наличие индекса следующим ниже запросом. 
-- relkind=i значит, что перед нами индекс.
-- Так мы увидим все индексы, в названии которых есть 'pk' 
-- (можно увидеть все индексы первичных ключей, для которых задал имя PostgreSQL (по умолчанию {имя_таблицы}_pkey),
-- а также индексы первичных ключей, для которых мы сами давали имя, используя в названии 'pk')

SELECT
pc.oid, relname, relkind, pi.*
FROM pg_class as pc
left join pg_index as pi
on pc.oid = pi.indexrelid
where relkind = 'i' and relname ~ '.*pk.*'
;

------ для проверок заполняем таблицу departments и выводим ее:
insert into schema1.departments
values (333, 'Second', 2, 7);

select * from schema1.departments ;
-----------------------------------------------------

-- Cвяжем таблицы departments и addresses по полю address_id.
-- Так как для поля address_id в таблице departments установлено ограничение default, воспользуемся этим для тренировки:
-- добавим в таблицу addresses поле с address_id = 0,
-- а для внешнего ключа таблицы departments проставим on delete = set default

insert into schema1.addresses
values (0, 'Not defined', '0', 'ND', 0);


select * from schema1.addresses;

alter table schema1.departments
add constraint fk_addrid foreign key (address_id)
references schema1.addresses(address_id)
on delete set default
on update cascade
;

------ для проверок работы внешнего ключа изменяем строку таблицы addresses, а потом и удаляем ее:
update schema1.addresses
set address_id = 77
where address_id= 7;

select * from schema1.addresses;
select * from schema1.departments ;

delete from schema1.addresses
where address_id = 77;
---------------------------------------------------------------------------------------------------
--
--Задание 4. 
--Создайте в схеме schema1 таблицу jobs (справочник должностей) и приведите код:
--1.	Таблица должна содержать следующие поля: job_id, job_title, min_salary и max_salary. Выберите для данных столбцов подходящие типы данных
--2.	Значение в поле max_salary не должно превышать 25000
--3.	Значение по умолчанию для job_title – строка нулевой длины
--4.	Значение по умолчанию для min_salary - равно 8000
--5.	Дублирование данных в столбце job_id не допускается

create table if not exists schema1.jobs 
(
	job_id	varchar(10)	NOT null,
	job_title	character varying (30) constraint df_job_title default '',
	min_salary		decimal(8,2) constraint df_min_salary default 8000,
	max_salary		decimal(8,2),
	constraint max_salary_chk check (max_salary <= 25000),	
	constraint ak_job_id unique(job_id)
)
;

------ для проверок заполняем таблицу jobs и выводим ее:
insert into schema1.jobs(job_id, max_salary)
values ('56RTY6', 24000.1);

insert into schema1.jobs
values ('111XXX', 'Manager', 0, 4000.4);

select * from schema1.jobs;
---------------------------------------------------------

--6.	В таблице jobs измените значение по умолчанию для столбца min_salary –> 7500

alter table schema1.jobs
alter column min_salary set default 7500;

---------------проверка
insert into schema1.jobs(job_id, max_salary)
values ('1001W', 50.5);
select * from schema1.jobs;
-----------------------------
--
--Задание 5. 
--Создайте в схеме schema1 таблицу employees (список сотрудников) со следующей структурой и приведите код:
--Поле	Тип данных	Ограничения
--employee_id	decimal(6,0)	Первичный ключ (PK)
--first_name	varchar(20)	NULL
--last_name	varchar(25)	NOT NULL
--email	varchar(25)	NOT NULL, уникальный
--phone_number	varchar(20)	NULL,
--Соответствие шаблону* 8(ХХХ)ХХХ-ХХХХ
--hire_date	date	NOT NULL,
--Меньше или равно текущая дата
--job_id	varchar(10)	NOT NULL, FK
--salary	decimal(8,2)	NULL
--manager_id	decimal(6,0)	NULL
--department_id	decimal(4,0)	NULL
--* шаблон должен соответствовать POSIX-требованиям

create table if not exists schema1.employees
(
	employee_id	decimal(6,0) NOT null,
	first_name	varchar(20)	null,
	last_name	varchar(25)	NOT null,
	email	varchar(25)	NOT NULL,
	phone_number	varchar(20)	NULL,
	hire_date	date	NOT NULL,
	job_id	varchar(10)	NOT NULL, 
	salary	decimal(8,2)	null,
	manager_id	decimal(6,0)	null,
	department_id	decimal(4,0)	null,
	constraint pk_employeeid primary key (employee_id),
	constraint ak_email unique (email),
	constraint phone_number_chk check (phone_number ~ '8\(\d{3}\)\d{3}-\d{4}'),
	constraint hire_date_chk check (hire_date <= CURRENT_DATE)
)
;

--1.	Столбец job_id должен содержать только те значения, которые существуют в таблице jobs в столбце job_id.  
--a.	При удалении записей в таблице jobs соответствующие записи в таблице employee должны автоматически удаляться
--b.	Любые изменения первичного ключа в таблице jobs должны отклоняться, если существуют связные записи в таблице employees 

alter table schema1.employees
add constraint fk_jobid foreign key (job_id)
references schema1.jobs (job_id)
on delete cascade
on update no action
;

--2.	Столбцы department_id и manager_id являются столбцами составного внешнего ключа, ссылающимися на соответствующий ключ в таблице «departments».

alter table schema1.employees
add constraint fk_depid_mngid foreign key (manager_id, department_id)
references schema1.departments (manager_id, department_id)
;

------------- проверка: вставляю записи, проверяю ограничения
insert into schema1.employees
values ('1001', null, 'smith', 'w@mail.ru', '8(910)555-6677', CURRENT_DATE, '56RTY', 8030, 1, 999);

insert into schema1.employees
values ('1003', 'John', 'Lee', 'aa@mail.ru', '8(911)555-6679', '2024-11-05', '111XXX', 5555, 2, 333);

select * from schema1.employees;

update schema1.jobs
set job_id = 'NEW'
where job_id = '56RTY';


delete from schema1.jobs
where job_id = '56RTY';
------------------------------------------------------------------

--
--Задание 6. 
--1.	В таблице departments измените состав первичного ключа – ключ должен состоять ТОЛЬКО из столбца department_id. Какие действия вы выполнили?

-- a) пробую просто удалить ограничентие - получаю ошибку, 
-- т.к. для этого первичного ключа создан внешний ключ в другой таблице
alter table schema1.departments
drop constraint pk_depid_manid;

-- б) значит, надо удалить ограничение каскадно, тогда запрос выполнится:
alter table schema1.departments
drop constraint pk_depid_manid cascade;

-- в) теперь создаю новый первичный ключ:
alter table schema1.departments
add constraint pk_depid primary key (department_id);

--2.	Внесите изменения в состав внешнего ключа в таблице employees, ссылающийся на соответствующий ключ в таблице departments:

-- после действий в пункте 1 ограничение внешнего ключа удалилось автоматически,
-- значит, надо создать новое:

alter table schema1.employees
add constraint fk_depid foreign key (department_id)
references schema1.departments (department_id)
;

--3.	Удалите столбец manager_id из таблицы employees
alter table schema1.employees
drop column manager_id;

--4.	Измените параметры внешнего ключа, созданного в таблице employees на столбце job_id таким образом, чтобы:
--a.	отклонялись удаления связных записей из родительской таблицы. 
--b.	обновления связных записей в родительской таблице должны каскадно поддерживаться

alter table schema1.employees
drop constraint fk_jobid ;


alter table schema1.employees
add constraint fk_jobid2 foreign key (job_id)
references schema1.jobs (job_id)
on delete no action
on update cascade
;

------------- проверка: проверяю новое ограничение
select * from schema1.jobs;
select * from schema1.employees;


update schema1.jobs
set job_id = 'NEW'
where job_id = '111XXX';


delete from schema1.jobs
where job_id = 'NEW';
-----------------------------------------------------

--5.	Создайте схему вашей БД и убедитесь, что все связи между таблицами отображаются корректно
-- все ок