-- Chess.com

/*Задание 1
Составить общее текстовое описание БД и решаемых ею задач.
*/

/*
БД для хранения и последующего использования данных для сайта Chess.com, 
на котором играют, соревнуются, тренируются и общаются шахматисты со всего мира.
*/	

/*Задание 2
Минимальное количество таблиц - 10.
*/

/*
1. Пользователи.
2. Фотографии профилей.
3. Профили пользователей.
4. Все партии.
5. Все ходы.
6. Запросы в друзья.
7. Личные сообщения.
8. Шахматные задачи.
9. Попытки решения шахматных задач.
10. Шахматные турниры.
11. Участники шахматных турниров.
12. Форумы.
13. Сообщения на форумах.
*/

/*Задание 3
Скрипты создания структуры БД (с первичными ключами, индексами, внешними ключами).
*/

DROP DATABASE IF EXISTS chess_com;
CREATE DATABASE chess_com;
USE chess_com;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'Пользователи';

DROP TABLE IF EXISTS avatars;
CREATE TABLE avatars (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
	avatars BLOB,
	create_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
	FOREIGN KEY (user_id) REFERENCES users(id)
) COMMENT 'Фотографии профилей';

DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    gender BIT, -- (1 - man, 0 - woman)
    birthday DATE,
    created_at DATETIME DEFAULT NOW(),
    country VARCHAR(100),
    points INT UNSIGNED DEFAULT 0,
	
    FOREIGN KEY (user_id) REFERENCES users(id)
) COMMENT 'Профили пользователей';

DROP TABLE IF EXISTS games;
CREATE TABLE games (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user1_id BIGINT UNSIGNED NOT NULL, -- white
	user2_id BIGINT UNSIGNED NOT NULL, -- black
    outcome ENUM('1', '0', '2'), -- (1 - user1, 0 - draw, 2 - user2)
    created_at DATETIME DEFAULT NOW(),
	
    FOREIGN KEY (user1_id) REFERENCES users(id),
    FOREIGN KEY (user2_id) REFERENCES users(id)
) COMMENT 'Все партии';

DROP TABLE IF EXISTS moves;
CREATE TABLE moves (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	move VARCHAR(50), -- `e2-e4`
	number_move INT UNSIGNED,
	game_id BIGINT UNSIGNED NOT NULL,
    color BIT, -- (1- white, 0 - black)
    seconds FLOAT(24) UNSIGNED,
    created_at DATETIME DEFAULT NOW(),
	
    FOREIGN KEY (game_id) REFERENCES games(id)
) COMMENT 'Все ходы';

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    status ENUM('requested', 'approved', 'declined', 'unfriended'),
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id),
    CHECK(initiator_user_id != target_user_id)
) COMMENT 'Запросы в друзья';

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
) COMMENT 'Личные сообщения';

DROP TABLE IF EXISTS tasks;
CREATE TABLE tasks (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	task VARCHAR(50), -- `e2 Bf1 Кb8 | a2 Кe8` (Слева от черты `|` находятся обозначения белых фигур, справа черных)
	solve VARCHAR(50), -- `1.e2-e4 Ke8-e7 2.e4-e5`
    color BIT, -- (1 - white, 0 - black)
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Шахматные задачи';

DROP TABLE IF EXISTS solve_tasks;
CREATE TABLE solve_tasks (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	task_id BIGINT UNSIGNED NOT NULL,
	seconds FLOAT(24) UNSIGNED,
	outcome BIT, -- (1 - win, 0 - lose)
    created_at DATETIME DEFAULT NOW(),
	
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (task_id) REFERENCES tasks(id)
) COMMENT 'Попытки решения шахматных задач';

DROP TABLE IF EXISTS tournaments;
CREATE TABLE tournaments (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(100),
	prize_pool BIGINT UNSIGNED, -- $
    date_start DATETIME,
    date_close DATETIME,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX tournaments_name_idx(name)
) COMMENT 'Шахматные турниры';

DROP TABLE IF EXISTS contenders;
CREATE TABLE contenders (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	tournament_id BIGINT UNSIGNED NOT NULL,
	user_id BIGINT UNSIGNED NOT NULL,
	prize BIGINT UNSIGNED, -- $
	points INT UNSIGNED DEFAULT 0,
	close_games INT UNSIGNED DEFAULT 0,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
) COMMENT 'Участники шахматных турниров';

DROP TABLE IF EXISTS forums;
CREATE TABLE forums(
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	created_at DATETIME DEFAULT NOW(),
	
	INDEX forums_name_idx(name),
	FOREIGN KEY (admin_user_id) REFERENCES users(id)
) COMMENT 'Форумы';

DROP TABLE IF EXISTS forum_messages;
CREATE TABLE forum_messages (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	forum_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (forum_id) REFERENCES forums(id)
) COMMENT 'Сообщения на форумах';

/*Задание 4
Создать ERDiagram для БД.
*/

/*
Прикрепил отдельным PNG-файлом.
*/

/*Задание 5
Скрипты наполнения БД данными.
*/

INSERT INTO users VALUES ('1','Kira','Gulgowski','jdoyle@example.com','90f1438b211e797a6cbc84a2013c3416bafc93ff'),
('2','Kira','Carter','kbartoletti@example.net','5a0abdd36f69cf3231795626a01084b8bcfc91fd'),
('3','Casimir','Kerluke','feest.filomena@example.com','00845d563098ec6d8c4065ccc21e08ca01f579f2'),
('4','Destany','Douglas','pacocha.alayna@example.org','44a4b2e8f0010d6545538a26104afad118459cc8'),
('5','Melody','Swift','elissa83@example.net','d4c354e3debee844b9b19bd5f772554c3b6b34af'),
('6','Stephon','Paucek','cora24@example.net','8aeac86c10ffe097983a1dd4895a1a93df5141db'),
('7','Jaeden','Will','lavinia.greenholt@example.com','ccb70ee56a54ed504be1af277e2791f4b1f5ea3a'),
('8','Lucio','Cummerata','shanon88@example.net','6d36e1646a89674d23dad8308be20f7c870a2eaa'),
('9','Jacky','Bashirian','lbeer@example.org','fcd2057d8750e7787a28b762b9da7415a1605ba3'),
('10','Myrtle','Dooley','mwalsh@example.net','a2dcfae8726ed4b70c3b7408c4964260dca50ea4');

INSERT INTO avatars VALUES ('1','c0c8a25bf3a4da3a95f8233311adaa673d95f28b40f78d09e428ba6f6a8f2c31','2004-10-11 09:03:57','2005-01-09 07:53:13'),
('2','541a03cb3d9dc71a583bed0f68bafc27e33d17b72d9a81b3a1b99dbae9254b09','2013-12-14 12:59:22','2014-12-21 17:32:25'),
('3','de10063fe1dbe0a2f7dec90e17d2e729d5f370d0c0009c216adc2c39d0b533b4','2020-02-17 10:39:12','2020-05-27 03:12:16'),
('4','27f7dd0d626030f9a6be48d3c49febcedc569a8b53f78fd7c21a81730d08f57b','1970-10-27 22:54:21','1998-07-25 10:46:45'),
('5','af5f7dfc640ce05fa1ffe4acee74f0181f30ecc296679f6fcaca1d3abf456616','1982-08-24 16:01:45','1993-02-19 08:35:31'),
('6','a0eb08de8b345da41b8314ea93fe8d76b4363eb2646e6e6a4fce3754d8b39b72','1999-11-26 15:32:29','2000-09-08 13:14:09'),
('7','773f4586a0db8f6b65952261727df086f3fe462fb1a22cf537aba8fae04a0395','2006-04-01 15:01:06','2007-08-12 05:22:35'),
('8','8107acd6a082adf1c9f1b31e028a9305549106dcaa4d0ad0215ec3f6763a29f7','1971-06-22 01:40:18','1980-01-09 02:37:05'),
('9','dd075c3590d7d2d88914c0b1acc52e292e93764ed679015523254eb23c5fd96b','1985-09-15 21:07:37','2003-12-24 14:10:39'),
('10','f7f35673b50a7963ae57230e6350e86ee03e4b94fbe6065897999cd8fcdc6244','1970-06-13 16:13:27','1991-07-21 15:09:45'); 

INSERT INTO profiles VALUES ('1',0,'1990-12-07','1991-12-22 13:38:45','Russia','1000'),
('2',0,'1997-05-11','2018-10-04 06:14:10','Russia','1100'),
('3',1,'1975-07-19','2005-08-19 17:28:12','Russia','1250'),
('4',1,'1960-04-08','2001-01-29 12:16:48','Russia','900'),
('5',0,'1975-07-04','1984-06-26 01:38:26','Germany','800'),
('6',1,'1970-10-15','1980-09-25 10:21:49','France','2000'),
('7',1,'1998-08-02','2000-06-26 18:39:54','France','3000'),
('8',1,'1960-03-16','1986-06-22 22:46:01','Germany','1050'),
('9',1,'1974-03-28','1987-05-20 07:38:41','France','1900'),
('10',1,'1967-07-03','2014-05-07 06:50:27','Germany','1450');

INSERT INTO games VALUES ('1','1','2','0','2017-12-22 13:38:45'),
('2','2','3','1','2019-10-04 06:14:10'),
('3','4','5',NULL,'2018-08-19 17:28:12'), -- игра ещё идёт
('4','4','3','0','2016-01-29 12:16:48'),
('5','2','1','0','2016-06-26 01:38:26'),
('6','8','9','1','2016-09-25 10:21:49'),
('7','1','10','0','2016-06-26 18:39:54'),
('8','10','7','2','2018-06-22 22:46:01'),
('9','1','3','2','2017-05-20 07:38:41'),
('10','2','3','2','2018-05-07 06:50:27');

INSERT INTO moves VALUES ('1','Qe2-e4','1','1',1,'11.24','2017-12-22 13:40:45'),
('2','Rd2-d5','1','1',0,'11.242','2019-10-04 06:15:10'),
('3','Be2-f3','5','3',1,'19.1','2018-08-19 17:29:12'),
('4','e2-e3','2','1',1,'8.112','2016-01-29 12:55:48'),
('5','Bb2-d4','2','1',0,'2.113','2016-06-26 01:33:26'),
('6','e3-e4','1','2',1,'15.321','2016-09-25 10:22:49'),
('7','Rd2-d7','1','2',0,'16.2222','2016-06-26 18:49:54'),
('8','Qe1-g1','3','1',1,'9','2018-06-22 22:56:01'),
('9','Ra7-a1','1','9',1,'11.2','2017-05-20 07:48:41'),
('10','Nb1-c3','1','9',0,'12.4','2018-05-07 06:10:27');

INSERT INTO friend_requests VALUES ('1','10','declined','2013-09-14 07:23:02','2011-12-09 21:46:55'),
('2','3','declined','1993-12-16 15:23:04','1995-01-19 12:12:05'),
('3','4','approved','1978-04-18 03:19:02','1990-09-27 02:55:48'),
('5','7','declined','1997-02-15 03:28:57','1998-11-09 02:09:22'),
('5','8','requested','1990-05-09 01:32:50','1974-03-19 15:18:58'),
('5','2','unfriended','1998-06-14 08:35:53','1977-09-29 11:01:09'),
('7','1','approved','2019-10-15 05:18:04','2008-08-17 03:22:20'),
('8','1','unfriended','2013-11-03 22:27:25','2005-02-09 11:09:21'),
('9','1','unfriended','2020-07-15 03:56:00','2011-11-26 13:03:21'),
('1','2','unfriended','1970-10-28 16:01:22','1994-01-28 08:31:20');

INSERT INTO messages VALUES ('1','1','2','Omnis commodi est consequatur inventore quod eum dolore. Nostrum nihil reprehenderit minima consequuntur accusantium est minima. Ratione reiciendis quia sequi. Delectus aperiam enim quibusdam.','2021-12-17 20:04:23','2010-12-09 21:46:55'),
('2','2','1','Aut est assumenda et minima nemo. Ut laborum aut mollitia cum. Saepe id nulla officiis deserunt cum voluptatibus.','2011-12-09 21:46:55','2011-10-09 21:46:55'),
('3','2','1','Temporibus sapiente quis deserunt. Cum eum iure est eius iusto tempora veritatis quod.','2019-02-19 23:30:24',NULL), -- Сообщение не редактировалось
('4','3','1','Nostrum dolor et necessitatibus nam. Culpa ipsum eum est. Ab laborum dicta a est et qui dolor. Voluptatum magnam praesentium id suscipit.','2003-08-10 02:43:12','2011-12-09 20:46:55'),
('5','2','1','Nostrum ut molestias aliquam sapiente voluptatem provident. Aut dignissimos sequi veniam adipisci.','1975-04-15 19:42:07','2001-12-09 21:46:55'),
('6','6','7','Accusamus est iusto vero modi ut rem ex. Quia ducimus similique quis sit. In tempora non optio sunt error cupiditate. Quo aspernatur et ab ipsam aliquam.','1998-10-25 15:42:17','2011-12-09 21:41:55'),
('7','2','7','Repudiandae et sed fugiat cupiditate ut quia. Qui quo aut non quidem autem. Sapiente et officiis est voluptatem sunt dicta molestias consectetur. Eius distinctio molestiae deserunt quasi adipisci. Magni amet doloribus beatae amet quo facere.','1977-07-25 10:40:33','2011-12-09 21:42:55'),
('8','5','1','Cum aspernatur consequatur non veritatis sint fugiat suscipit nihil. Impedit assumenda voluptatum magni aut. Voluptatem corporis quidem eos.','2022-05-28 01:10:30','2011-12-09 21:43:55'),
('9','9','7','Et autem quia quae sunt. Eos id iure modi recusandae labore et magnam. Sint non provident non et sit et. Sint et minima molestiae sed debitis.','1985-08-02 00:40:42','2011-12-09 21:46:10'),
('10','8','2','Unde quaerat eos dolor aut id fugit. Et minus at reiciendis ea sed dolorum. Natus doloribus deleniti ut quibusdam blanditiis voluptate.','2015-03-29 22:27:41','2011-12-09 21:46:11');

INSERT INTO tasks VALUES ('1','Qe2 Bf1 Кb8 | a2 Кe8','1.Qe2-e4 Kb8-e7 2.e4-e5',1,'2021-12-17 20:04:23','2010-04-09 21:46:55'),
('2','Ne4 f2 Кc8 | Bb1 Кe7','1.e2-e4 Ke8-e7 2.b4-b5',1,'2020-12-17 20:04:23','2015-11-09 21:46:55'),
('3','c2 Bf1 Кb4 | Ra2 Кh2','1.d2-d4 Ke8-e7 2.c4-c5',1,'2019-12-17 20:04:23','2009-08-09 21:46:55'),
('4','d2 f1 Кb2 | Ra2 Кe8','1.e2-e4 Qe8-e7 2.d5-e6',0,'2010-12-17 20:04:23','2015-10-09 21:46:55'),
('5','e2 Rf1 Кb3 | a2 Кd8','1.c2-c4 Re8-e7 2.e4-e5',1,'2015-12-17 20:04:23','2015-12-09 21:46:55'),
('6','f2 f1 Кb7 | Qc3 Кc4','1.e2-e3 Be8-f7 2.e4-e5',0,'2016-12-17 20:04:23','2014-12-09 21:46:55'),
('7','f2 Rf3 Кb3 | a2 Кe5','1.e2-e4 Be8-f7 2.e6-e7',0,'2021-11-17 20:04:23','2013-11-09 21:46:55'),
('8','e2 f1 Кb2 | Na2 Кe5','1.f2-f4 Ke8-e7 2.Ke4-e5',0,'2016-12-17 20:04:23','2013-12-09 21:46:55'),
('9','a2 Rf1 Кb2 | b4 Кe3','1.f2-f4 Qe8-e7 2.Ke4-e5',1,'2017-12-17 20:04:23','2012-12-09 21:46:55'),
('10','b2 Nf1 Кb8 | Na2 Кa3','1.e2-e4 Ke8-e7 2.e4-e5',1,'2018-12-17 20:04:23','2011-12-09 21:46:55');

INSERT INTO solve_tasks VALUES ('1','10','10','10.24',1,'2013-09-14 07:23:02'),
('2','3','1','24.2',1,'1993-12-16 15:23:04'),
('3','4','2','11.3',0,'1978-04-18 03:19:02'),
('4','7','3','9.288',1,'1997-02-15 03:28:57'),
('5','8','2','16.248',0,'1990-05-09 01:32:50'),
('6','2','2','11.24',0,'1998-06-14 08:35:53'),
('7','1','5','16.8',0,'2019-10-15 05:18:04'),
('8','1','8','11.99',1,'2013-11-03 22:27:25'),
('9','1','9','15.243',1,'2020-07-15 03:56:00'),
('10','2','10','10.2488',0,'1970-10-28 16:01:22');

INSERT INTO tournaments VALUES ('1','Russia chemp','2000','1990-12-07 13:38:45','1991-12-07 13:38:45','1991-12-22 13:38:45','1996-12-07 13:38:45'),
('2','Russia chess','1300','1997-05-11 13:38:45','1998-12-07 13:38:45','2011-10-04 06:14:10','1996-12-07 13:38:45'),
('3','Big cup','1100','1975-07-19 13:38:45','1990-12-07 13:38:45','2005-08-19 17:28:12','1996-12-07 13:38:45'),
('4','New chess','2200','1960-04-08 13:38:45','1991-12-07 13:38:45','2001-01-29 12:16:48','1996-12-07 13:38:45'),
('5','Germany old','1100','1975-07-04 13:38:45','1990-12-07 13:38:45','1984-06-26 01:38:26',NULL),
('6','Global cup','3000','1970-10-15 13:38:45','1993-12-07 13:38:45','1980-09-25 10:21:49','1996-12-07 13:38:45'),
('7','Kids chess','5000','1998-08-02 13:38:45','1999-12-07 13:38:45','2000-06-26 18:39:54','1996-12-07 13:38:45'),
('8','Pro chess','10000','1960-03-16 13:38:45','1998-12-07 13:38:45','1986-06-22 22:46:01','1996-12-07 13:38:45'),
('9','Pro cup','100000','1974-03-28 13:38:45','1997-12-07 13:38:45','1987-05-20 07:38:41','1996-12-07 13:38:45'),
('10','Pro old cup','12000','1967-07-03 13:38:45','1996-12-07 13:38:45','2014-05-07 06:50:27','1996-12-07 13:38:45');

INSERT INTO contenders VALUES ('1','1','3','100','200','10','1991-12-22 13:38:45','1996-12-07 13:38:45'),
('2','2','10','0','10','10','2011-10-04 06:14:10','1996-12-07 13:38:45'),
('3','5','8','2000','3100','10','2005-08-19 17:28:12','1996-12-07 13:38:45'),
('4','2','1','2100','2100','10','2001-01-29 12:16:48','1996-12-07 13:38:45'),
('5','1','7','300','100','10','1984-06-26 01:38:26',NULL),
('6','3','4','500','200','10','1980-09-25 10:21:49','1996-12-07 13:38:45'),
('7','1','9','700','300','10','1980-09-25 10:22:49','1996-12-07 13:38:45'),
('8','4','6','600','1300','10','1986-06-22 22:46:01','1996-12-07 13:38:45'),
('9','1','8','80','1500','10','1987-05-20 07:38:41','1996-12-07 13:38:45'),
('10','2','2','10','200','10','2014-05-07 06:50:27','1996-12-07 13:38:45');

INSERT INTO forums VALUES ('1','ea','5','1997-12-07 13:38:45'),
('2','aliquid','2','1986-12-07 13:38:45'),
('3','accusamus','3','1996-12-07 13:38:45'),
('4','et','5','1995-12-07 13:38:45'),
('5','dolorem','2','1996-11-07 13:38:45'),
('6','soluta','6','1996-10-07 13:38:45'),
('7','reprehenderit','2','1996-07-07 13:38:45'),
('8','accusamus','1','1996-12-03 13:38:45'),
('9','architecto','9','1996-12-01 13:38:45'),
('10','quia','1','1996-12-07 14:38:45');

INSERT INTO forum_messages VALUES ('1','1','2','Omnis commodi est consequatur inventore quod eum dolore. Nostrum nihil reprehenderit minima consequuntur accusantium est minima. Ratione reiciendis quia sequi. Delectus aperiam enim quibusdam.','2021-12-17 20:04:23','2010-12-09 21:46:55'),
('2','2','1','Aut est assumenda et minima nemo. Ut laborum aut mollitia cum. Saepe id nulla officiis deserunt cum voluptatibus.','2011-12-09 21:46:55','2011-10-09 21:46:55'),
('3','2','1','Temporibus sapiente quis deserunt. Cum eum iure est eius iusto tempora veritatis quod.','2019-02-19 23:30:24',NULL), -- Сообщение не редактировалось
('4','3','1','Nostrum dolor et necessitatibus nam. Culpa ipsum eum est. Ab laborum dicta a est et qui dolor. Voluptatum magnam praesentium id suscipit.','2003-08-10 02:43:12','2011-12-09 20:46:55'),
('5','2','1','Nostrum ut molestias aliquam sapiente voluptatem provident. Aut dignissimos sequi veniam adipisci.','1975-04-15 19:42:07','2001-12-09 21:46:55'),
('6','6','7','Accusamus est iusto vero modi ut rem ex. Quia ducimus similique quis sit. In tempora non optio sunt error cupiditate. Quo aspernatur et ab ipsam aliquam.','1998-10-25 15:42:17','2011-12-09 21:41:55'),
('7','2','7','Repudiandae et sed fugiat cupiditate ut quia. Qui quo aut non quidem autem. Sapiente et officiis est voluptatem sunt dicta molestias consectetur. Eius distinctio molestiae deserunt quasi adipisci. Magni amet doloribus beatae amet quo facere.','1977-07-25 10:40:33','2011-12-09 21:42:55'),
('8','5','1','Cum aspernatur consequatur non veritatis sint fugiat suscipit nihil. Impedit assumenda voluptatum magni aut. Voluptatem corporis quidem eos.','1989-05-28 01:10:30','2011-12-09 21:43:55'),
('9','9','7','Et autem quia quae sunt. Eos id iure modi recusandae labore et magnam. Sint non provident non et sit et. Sint et minima molestiae sed debitis.','1985-08-02 00:40:42','2011-12-09 21:46:10'),
('10','8','2','Unde quaerat eos dolor aut id fugit. Et minus at reiciendis ea sed dolorum. Natus doloribus deleniti ut quibusdam blanditiis voluptate.','2022-03-29 22:27:41','2011-12-09 21:46:11');

/*Задание 6
Скрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы).
*/

-- Подсчёт побед каждого пользователя.
select user_id, count(*) as wins from (select user1_id as user_id from games where outcome = '1'
union all
select user2_id as user_id from games where outcome = '2') as t group by user_id;

-- Подсчёт длительности каждой игры.
select g.id,sum(m.seconds) as seconds from games g join moves m on (m.game_id = g.id) group by g.id;

-- Подсчёт количества участников форумов.
select forum_id, count(*) as quantity from (
select distinct forum_id, user_id from forum_messages) as t group by forum_id; 

/*Задание 7
Представления (минимум 2).
*/

-- Представление firstname_lastname_messages таблицы messages.
drop view if exists firstname_lastname_messages;
create view firstname_lastname_messages 
as select m.id, u1.firstname as from_firstname, u1.lastname as from_lastname, u2.firstname as to_firstname, u2.lastname as to_lastname, m.body, m.created_at, m.updated_at
from messages m 
join users u1 on (u1.id = m.from_user_id)
join users u2 on (u2.id = m.to_user_id);
select * from firstname_lastname_messages;

-- Представление name_forum_messages таблицы forum_messages.
drop view if exists name_forum_messages;
create view name_forum_messages
as select m.id, u.firstname, u.lastname, f.name as forum, m.body, m.created_at, m.updated_at
from forum_messages m 
join users u on (u.id = m.user_id)
join forums f on (f.id = m.forum_id);
select * from name_forum_messages;

-- Представление no_password_users таблицы users.
drop view if exists no_password_users;
create view no_password_users
as select id, firstname, lastname, email
from users;
select * from no_password_users;

/*Задание 8
Xранимые процедуры / триггеры.
*/

select * from messages;
select * from forum_messages;

DELIMITER //

-- Процедура для удаления сообщений из будущего.
drop procedure if exists delete_messages_future//
create procedure delete_messages_future()
begin 	
	delete from messages where created_at > now();
	delete from forum_messages where created_at > now();
end//

-- Триггер не позволяющий обновить сообщение из будущего.
drop trigger if exists no_update_messages_future//
create trigger no_update_messages_future before update on messages
for each row
begin 	
	if new.updated_at > now() then
		set new.updated_at = old.updated_at;
	end if;
end//

DELIMITER ;

call delete_messages_future();
update messages set updated_at = '2022.01.01 00:00:00' where id = 2;

select * from messages;
select * from forum_messages;
