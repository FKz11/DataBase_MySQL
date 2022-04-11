DROP DATABASE IF EXISTS shop;
CREATE DATABASE shop;
USE shop;

DROP TABLE IF EXISTS catalogs;
CREATE TABLE catalogs (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Название раздела',
  UNIQUE unique_name(name(10))
) COMMENT = 'Разделы интернет-магазина';

INSERT INTO catalogs VALUES
  (NULL, 'Процессоры'),
  (NULL, 'Материнские платы'),
  (NULL, 'Видеокарты'),
  (NULL, 'Жесткие диски'),
  (NULL, 'Оперативная память');

DROP TABLE IF EXISTS rubrics;
CREATE TABLE rubrics (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Название раздела'
) COMMENT = 'Разделы интернет-магазина';

INSERT INTO rubrics VALUES
  (NULL, 'Видеокарты'),
  (NULL, 'Память');

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Имя покупателя',
  birthday_at DATE COMMENT 'Дата рождения',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Покупатели';

INSERT INTO users (name, birthday_at) VALUES
  ('Геннадий', '1990-10-05'),
  ('Наталья', '1984-11-12'),
  ('Александр', '1985-05-20'),
  ('Сергей', '1988-02-14'),
  ('Иван', '1998-01-12'),
  ('Мария', '1992-08-29');

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Название',
  description TEXT COMMENT 'Описание',
  price DECIMAL (11,2) COMMENT 'Цена',
  catalog_id INT UNSIGNED,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY index_of_catalog_id (catalog_id)
) COMMENT = 'Товарные позиции';

INSERT INTO products
  (name, description, price, catalog_id)
VALUES
  ('Intel Core i3-8100', 'Процессор для настольных персональных компьютеров, основанных на платформе Intel.', 7890.00, 1),
  ('Intel Core i5-7400', 'Процессор для настольных персональных компьютеров, основанных на платформе Intel.', 12700.00, 1),
  ('AMD FX-8320E', 'Процессор для настольных персональных компьютеров, основанных на платформе AMD.', 4780.00, 1),
  ('AMD FX-8320', 'Процессор для настольных персональных компьютеров, основанных на платформе AMD.', 7120.00, 1),
  ('ASUS ROG MAXIMUS X HERO', 'Материнская плата ASUS ROG MAXIMUS X HERO, Z370, Socket 1151-V2, DDR4, ATX', 19310.00, 2),
  ('Gigabyte H310M S2H', 'Материнская плата Gigabyte H310M Sx2H, H310, Socket 1151-V2, DDR4, mATX', 4790.00, 2),
  ('MSI B250M GAMING PRO', 'Материнская плата MSI B250M GAMING PRO, B250, Socket 1151, DDR4, mATX', 5060.00, 2);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT UNSIGNED,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY index_of_user_id(user_id)
) COMMENT = 'Заказы';

DROP TABLE IF EXISTS orders_products;
CREATE TABLE orders_products (
  id SERIAL PRIMARY KEY,
  order_id INT UNSIGNED,
  product_id INT UNSIGNED,
  total INT UNSIGNED DEFAULT 1 COMMENT 'Количество заказанных товарных позиций',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Состав заказа';

DROP TABLE IF EXISTS discounts;
CREATE TABLE discounts (
  id SERIAL PRIMARY KEY,
  user_id INT UNSIGNED,
  product_id INT UNSIGNED,
  discount FLOAT UNSIGNED COMMENT 'Величина скидки от 0.0 до 1.0',
  started_at DATETIME,
  finished_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY index_of_user_id(user_id),
  KEY index_of_product_id(product_id)
) COMMENT = 'Скидки';

DROP TABLE IF EXISTS storehouses;
CREATE TABLE storehouses (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Название',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Склады';

DROP TABLE IF EXISTS storehouses_products;
CREATE TABLE storehouses_products (
  id SERIAL PRIMARY KEY,
  storehouse_id INT UNSIGNED,
  product_id INT UNSIGNED,
  value INT UNSIGNED COMMENT 'Запас товарной позиции на складе',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Запасы на складе';


DROP DATABASE IF EXISTS sample;
CREATE DATABASE sample;
USE sample;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) COMMENT 'Имя покупателя',
  birthday_at DATE COMMENT 'Дата рождения',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Покупатели';

INSERT INTO users (name, birthday_at) VALUES
  ('Олег', '1990-10-05'),
  ('Наталья', '1984-11-12'),
  ('Александр', '1985-05-20'),
  ('Сергей', '1988-02-14'),
  ('Иван', '1998-01-12'),
  ('Мария', '1992-08-29');
 
/*Задание 1.1
В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. 
Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. 
Используйте транзакции.
*/
 
select * from shop.users;
select * from sample.users;

start transaction;
update sample.users set id = id + 1 order by id desc;
insert into sample.users select * from shop.users where id = 1;
delete from shop.users where id = 1;
update shop.users set id = id - 1;
commit;

select * from shop.users;
select * from sample.users;

/*Задание 1.2
Создайте представление, 
которое выводит название name товарной позиции из таблицы products и 
соответствующее название каталога name из таблицы catalogs.
*/

use shop;

drop view if exists name_name;
create view name_name as select p.name as name_products, 
	c.name as name_catalogs from products p join catalogs c on (p.catalog_id = c.id);
select * from name_name;

/*Задание 1.3
(по желанию) Пусть имеется таблица с календарным полем created_at. 
В ней размещены разряженые календарные записи за август 2018 года '2018-08-01', 
'2016-08-04', '2018-08-16' и 2018-08-17. 
Составьте запрос, который выводит полный список дат за август, 
выставляя в соседнем поле значение 1, если дата присутствует в исходном таблице и 0, 
если она отсутствует.
*/

DROP TABLE IF EXISTS august_task;
CREATE TABLE august_task (
  id SERIAL PRIMARY KEY,
  created_at DATE
);

INSERT INTO august_task (created_at) values ('2018-08-01'), 
	('2018-08-04'), ('2018-08-16'), ('2018-08-17');

DROP temporary TABLE IF EXISTS august;
CREATE temporary table august(
	days SERIAL PRIMARY key
);

INSERT INTO august (days) values (1), (2), 
	(3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), 
	(15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), 
	(26), (27), (28), (29), (30), (31);
	
select a.days as august_days, (case 
	when au.created_at is null then 0
	else 1
	end) as in_august_task
from august a left join august_task au on (a.days = day(au.created_at));

/*Задание 1.4
(по желанию) Пусть имеется любая таблица с календарным полем created_at. 
Создайте запрос, который удаляет устаревшие записи из таблицы, 
оставляя только 5 самых свежих записей.
*/

DROP TABLE IF EXISTS calendar_task;
CREATE TABLE calendar_task (
  id SERIAL PRIMARY KEY,
  created_at DATE
);

insert into calendar_task (created_at) values ('2008-08-01'), 
	('2018-01-04'), ('2018-04-16'), ('2018-05-17'),
	('2018-08-02'), ('2018-08-16'), ('2018-08-17'),
	('2018-09-03'), ('2014-08-16'), ('2018-08-17'),
	('2018-08-04'), ('2015-08-16'), ('2018-02-17'),
	('2018-10-04'), ('2018-10-16'), ('2018-01-17');

select * from calendar_task;

start transaction;
create temporary table calendar_task_buf like calendar_task;
insert into calendar_task_buf select * from calendar_task order by created_at desc limit 5;
delete from calendar_task;
insert into calendar_task select * from calendar_task_buf;
drop temporary table calendar_task_buf;
commit;

select * from calendar_task;

/*Задание 2.1
Создайте двух пользователей которые имеют доступ к базе данных shop. 
Первому пользователю shop_read должны быть доступны только запросы на чтение данных, 
второму пользователю shop — любые операции в пределах базы данных shop.
*/

drop user if exists 'shop_read'@'%';
drop user if exists 'shop'@'%';
CREATE USER 'shop_read'@'%' IDENTIFIED BY 'password';
CREATE USER 'shop'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON shop.* TO 'shop_read'@'%';
GRANT ALL PRIVILEGES ON shop.* TO 'shop'@'%';

/*Задание 2.2
(по желанию) Пусть имеется таблица accounts содержащая три столбца id, 
name, password, содержащие первичный ключ, имя пользователя и его пароль. 
Создайте представление username таблицы accounts, предоставляющий доступ к столбца id и name. 
Создайте пользователя user_read, который бы не имел доступа к таблице accounts, 
однако, мог бы извлекать записи из представления username.
*/

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  `password` VARCHAR(255)
);

drop view if exists username;
create view username as select id, name from accounts;

drop user if exists 'user_read'@'%';
CREATE USER 'user_read'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON shop.username TO 'user_read'@'%' ;

/*Задание 3.1
Создайте хранимую функцию hello(), которая будет возвращать приветствие, 
в зависимости от текущего времени суток. 
С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
с 18:00 до 00:00 — "Добрый вечер", 
с 00:00 до 6:00 — "Доброй ночи".
*/

DELIMITER //

drop function if exists hello//
create function hello()
returns varchar(255) deterministic
begin return 
	case 
		when hour(CURTIME()) between 6 and 11 then "Доброе утро"
		when hour(CURTIME()) between 12 and 17 then "Добрый день"
		when hour(CURTIME()) > 18 then "Добрый вечер"
		when hour(CURTIME()) between 0 and 5 then "Доброй ночи"
	end;
end//

DELIMITER ;

select hello();

/*Задание 3.2
В таблице products есть два текстовых поля: name с названием товара и description с его описанием. 
Допустимо присутствие обоих полей или одно из них. 
Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема. 
Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены. 
При попытке присвоить полям NULL-значение необходимо отменить операцию.
*/	

DELIMITER //

drop trigger if exists products_null_insert//
create trigger products_null_insert before insert on products
for each row
begin 	
	if name is null and description is null then 
		signal sqlstate '45000' set message_text = 'name and description is null';
	end if;
end//

drop trigger if exists products_null_update//
create trigger products_null_update before update on products
for each row
begin 	
	if new.name is null and new.description is null then 
		if old.name is null and old.description is null then
			signal sqlstate '45000' set message_text = 'name and description is null';
		else
			set new.name = old.name, new.description = old.description;
		end if;
	end if;
end//

DELIMITER ;

select * from products;
-- INSERT INTO products (name, description, price, catalog_id) values (null, null, 5060.00, 2);
update products set name = null, description = null;
select * from products;

/*Задание 3.3
(по желанию) Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. 
Числами Фибоначчи называется последовательность в которой число равно сумме двух предыдущих чисел. 
Вызов функции FIBONACCI(10) должен возвращать число 55.
*/	

DELIMITER //

drop function if exists FIBONACCI//
create function FIBONACCI(numb bigint)
returns bigint deterministic
begin 
	declare iter, one, two, buf bigint;
	set iter = 0, one = 0, two = 1;
	while iter < numb do
		set buf = two;
		set two = two + one;
		set one = buf;
		set iter = iter + 1;
	end while;
	return one;
end//

DELIMITER ;

select FIBONACCI(10);
