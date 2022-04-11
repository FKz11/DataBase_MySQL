-- lesson-5.
-- Учебная база:
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
  ('Наталья', '1984-12-12'),
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
  ('Gigabyte H310M S2H', 'Материнская плата Gigabyte H310M S2H, H310, Socket 1151-V2, DDR4, mATX', 4790.00, 2),
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

/*1. Пусть в таблице users поля created_at и updated_at оказались незаполненными. 
 Заполните их текущими датой и временем
*/

update users set created_at = null, updated_at = null;
select * from users;

update users set created_at = now(), updated_at = now();
select * from users;

/*2. Таблица users была неудачно спроектирована. 
 Записи created_at и updated_at были заданы типом VARCHAR и в них долгое время помещались значения в формате "20.10.2017 8:10". 
 Необходимо преобразовать поля к типу DATETIME, сохранив введеные ранее значения.
*/

alter table users add column created_at_vc varchar(20);
alter table users add column updated_at_vc varchar(20);
update users set created_at_vc = date_format(created_at, '%d.%m.%Y %H:%i'), 
updated_at_vc = date_format(updated_at, '%d.%m.%Y %H:%i');
alter table users drop created_at, drop updated_at;
alter table users rename column created_at_vc to created_at;
alter table users rename column updated_at_vc to updated_at;
select * from users;

alter table users add column created_at_dt DATETIME DEFAULT CURRENT_TIMESTAMP;
alter table users add column updated_at_dt DATETIME default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
update users set created_at_dt = str_to_date(created_at, '%d.%m.%Y %H:%i'), 
updated_at_dt = str_to_date(updated_at, '%d.%m.%Y %H:%i');
alter table users drop created_at, drop updated_at;
alter table users rename column created_at_dt to created_at;
alter table users rename column updated_at_dt to updated_at;
select * from users;

/*3. В таблице складских запасов storehouses_products в поле value могут встречаться самые разные цифры: 
 0, если товар закончился и выше нуля, если на складе имеются запасы. 
 Необходимо отсортировать записи таким образом, чтобы они выводились в порядке увеличения значения value. 
 Однако, нулевые запасы должны выводиться в конце, после всех записей.
*/

INSERT INTO storehouses_products (storehouse_id, product_id, value) VALUES
  (1, 1, 250),
  (1, 2, 6),
  (2, 3, 0),
  (3, 4, 0),
  (3, 5, 10),
  (3, 6, 6),
  (3, 7, 7);
select * from storehouses_products;

select storehouse_id, product_id, value, created_at, updated_at from 
(select storehouse_id, product_id, value, created_at, updated_at, (value = 0) as not_zero from storehouses_products order by not_zero, value) as t;

/*4. (по желанию) Из таблицы users необходимо извлечь пользователей, родившихся в августе и мае. 
 Месяцы заданы в виде списка английских названий ('may', 'august')
*/

alter table users add column birthday_at_vc varchar(20);
update users set birthday_at_vc = date_format(birthday_at, '%M');
alter table users drop birthday_at;
alter table users rename column birthday_at_vc to birthday_at;
select * from users;

select * from users where birthday_at = 'may' or birthday_at = 'august';

/*5. (по желанию) Из таблицы catalogs извлекаются записи при помощи запроса. 
 SELECT * FROM catalogs WHERE id IN (5, 1, 2); 
 Отсортируйте записи в порядке, заданном в списке IN.
*/

SELECT id, name from
(SELECT id, name, (id != 5) as id_5 FROM catalogs WHERE id IN (5, 1, 2) order by id_5) as t; 

/*6. Подсчитайте средний возраст пользователей в таблице users
*/

update users set birthday_at = '1990-10-05' where name = 'Геннадий';
update users set birthday_at = '1984-12-12' where name = 'Наталья';
update users set birthday_at = '1985-05-20' where name = 'Александр';
update users set birthday_at = '1988-02-14' where name = 'Сергей';
update users set birthday_at = '1998-01-12' where name = 'Иван';
update users set birthday_at = '1992-08-29' where name = 'Мария';
 
select birthday_at, TIMESTAMPDIFF(year, birthday_at, now()) from users;
select avg(y_o) as y_o_avg from (select TIMESTAMPDIFF(year, birthday_at, now()) as y_o from users) as t;

/*7. Подсчитайте количество дней рождения, которые приходятся на каждый из дней недели. 
Следует учесть, что необходимы дни недели текущего года, а не года рождения.
*/

select date_format(birthday_at, '2020-%m-%d %T'), date_format(date_format(birthday_at, '2020-%m-%d %T'), '%W') from users;
select birthday_day_week, quantity from (select date_format(date_format(birthday_at, '2020-%m-%d %T'), '%W') as birthday_day_week, count(*) as quantity from users group by birthday_day_week) as t;

/*8. (по желанию) Подсчитайте произведение чисел в столбце таблицы
*/

DROP TABLE IF EXISTS task8;
CREATE TABLE task8 (value bigint);
INSERT INTO task8 (value) values ('1'), ('2'), ('3'), ('4'), ('5');
 
select exp(sum(ln(value))) as product from task8;

