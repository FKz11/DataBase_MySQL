DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамиль', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	phone BIGINT UNSIGNED UNIQUE, 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'юзеры';

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    gender ENUM('M', 'W'),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100),
    is_active BIT NOT NULL DEFAULT 1
	
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE -- (значение по умолчанию)
    ON DELETE RESTRICT; -- (значение по умолчанию)

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL, -- изменили на составной ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'declined', 'unfriended'),
    -- `status` TINYINT(1) UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, -- можно будет даже не упоминать это поле при обновлении
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)-- ,
    -- CHECK (initiator_user_id <> target_user_id)
);
-- чтобы пользователь сам себе не отправил запрос в друзья
ALTER TABLE friend_requests 
ADD CHECK(initiator_user_id <> target_user_id);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	
	INDEX communities_name_idx(name), -- индексу можно давать свое имя (communities_name_idx)
	foreign key (admin_user_id) references users(id)
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL,
    name VARCHAR(255), -- записей мало, поэтому в индексе нет необходимости
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    -- file blob,    	
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  

/* намеренно забыли, чтобы позднее увидеть их отсутствие в ER-диаграмме
    , FOREIGN KEY (user_id) REFERENCES users(id)
    , FOREIGN KEY (media_id) REFERENCES media(id)
*/
);

DROP TABLE IF EXISTS `photo_albums`;
CREATE TABLE `photo_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
  	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos` (
	id SERIAL,
	`album_id` BIGINT unsigned NULL,
	`media_id` BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk 
FOREIGN KEY (media_id) REFERENCES vk.media(id);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk_1 
FOREIGN KEY (user_id) REFERENCES vk.users(id);

ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_1 
FOREIGN KEY (photo_id) REFERENCES media(id);

-- Для таблицы `gifts`
DROP TABLE IF EXISTS gifts_types;
CREATE TABLE gifts_types (
	id SERIAL,
	g_type BLOB NOT NULL,
	create_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS gifts;
CREATE TABLE gifts (
	id SERIAL,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    gift BIGINT UNSIGNED NOT NULL,
	send_at DATETIME DEFAULT NOW(),
	
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id),
    FOREIGN KEY (gift) REFERENCES gifts_types(id),
    CHECK (from_user_id != to_user_id)
);

DROP TABLE IF EXISTS vk_pay;
CREATE TABLE vk_pay (
	id SERIAL,
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    amount FLOAT UNSIGNED NOT NULL,
    pin_code SMALLINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
    FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS vk_pay_history;
CREATE TABLE vk_pay_history (
	id SERIAL,
	vk_pay_id BIGINT UNSIGNED NOT NULL,
    change_amount FLOAT,
    changed_at DATETIME DEFAULT NOW(),
	
    FOREIGN KEY (vk_pay_id) REFERENCES vk_pay(id)
);

INSERT INTO `users` VALUES ('1','Kira','Gulgowski','jdoyle@example.com','90f1438b211e797a6cbc84a2013c3416bafc93ff','89556922202'),
('2','Kira','Carter','kbartoletti@example.net','5a0abdd36f69cf3231795626a01084b8bcfc91fd','89055570125'),
('3','Casimir','Kerluke','feest.filomena@example.com','00845d563098ec6d8c4065ccc21e08ca01f579f2','89741499040'),
('4','Destany','Douglas','pacocha.alayna@example.org','44a4b2e8f0010d6545538a26104afad118459cc8','89230888157'),
('5','Melody','Swift','elissa83@example.net','d4c354e3debee844b9b19bd5f772554c3b6b34af','89069431024'),
('6','Stephon','Paucek','cora24@example.net','8aeac86c10ffe097983a1dd4895a1a93df5141db','89586339524'),
('7','Jaeden','Will','lavinia.greenholt@example.com','ccb70ee56a54ed504be1af277e2791f4b1f5ea3a','89674615461'),
('8','Lucio','Cummerata','shanon88@example.net','6d36e1646a89674d23dad8308be20f7c870a2eaa','89439863482'),
('9','Jacky','Bashirian','lbeer@example.org','fcd2057d8750e7787a28b762b9da7415a1605ba3','89065730982'),
('10','Myrtle','Dooley','mwalsh@example.net','a2dcfae8726ed4b70c3b7408c4964260dca50ea4','89539245461'),
('11','Grover','Nicolas','lera10@example.com','a34e49dfc869e8b231c01816b3b2408a91b663be','89426939303'),
('12','Tremayne','Stiedemann','roy.predovic@example.org','fe3ed28f45c842a4337d521b3cf2dd769c54183a','89515907089'),
('13','Jesse','Abshire','gmayert@example.net','0287daa46ebbf8b8a0074bc6ba138509251697c6','89590713887'),
('14','Zetta','Shanahan','kaitlyn39@example.net','263234dc2767051497530e36b25980f013e3cb78','89592648951'),
('15','Margot','Mann','nat.labadie@example.net','ad0bf50f350f0ee9d8b6b4cf3e8372775e0dfedb','89235378763'),
('16','Joannie','Mraz','uroberts@example.org','3f77722ff376c7d5829ec208987cec25ad3b2e7f','89248734647'),
('17','Wade','Larkin','jadyn.conroy@example.com','efec72a9e4404323524f858cc2b1825106e7729d','89545570768'),
('18','Ali','Larkin','boyle.roger@example.net','8bed8b0ac0919b14e6b884c2a40254eb0c64961d','89251211693'),
('19','Arnoldo','O\'Conner','greenfelder.junius@example.net','1b12d78d1de41066468cdcce0e1dd0157735c214','89485098518'),
('20','Mattie','Cremin','nya57@example.net','9131aae37811a2a9592ac7f9e34ea5a24d1bfdfb','89584819071'),
('21','Antonette','Breitenberg','sydnee.bauch@example.org','7d0f3edf8367c8855d327bc29430cd7d66de8f9a','89149939421'),
('22','Geovany','Monahan','brielle08@example.com','ed745d783f48697fceebbfdc4d77f2eca6ed7a3c','89818164028'),
('23','Johnnie','Herzog','baumbach.adolph@example.net','5fac3fb45c588d1d5222788956380947342fecda','89389373231'),
('24','Madilyn','Pfannerstill','vesta47@example.com','8b9b83aa505fe0b41f138024d237322a60183b4b','89273002600'),
('25','Damon','Baumbach','qdaniel@example.com','0b403152d563609e5e605154259e9026bd4373c4','89862448561'),
('26','Marielle','Rau','o\'hara.sydni@example.com','13a1a2c78240eda1aabb66b7c6270031d957bef3','89621345766'),
('27','Kirsten','Schamberger','ima02@example.com','8f301376e4067361a2243b4335121f6b90fe1004','89251319225'),
('28','Ansel','O\'Conner','ayden14@example.com','4fa503655e03ffbc3bf7c6d7c9fa363e463102e2','89280490980'),
('29','Mckenzie','Marks','king.borer@example.net','237ede33b6dfa6492d053b63d6e9e96934b6abbb','89544352303'),
('30','Peggie','Trantow','ntowne@example.org','8bf0c813792c476ca758e76a88d62ce864fa5cec','89684978162'),
('31','Avery','Watsica','ines71@example.net','35aea5ae3086dc1c6354c5f35f07bf69f92ed05a','89931683917'),
('32','Keyon','Parisian','danyka55@example.net','72667e38b2854a77587aa0905c8d661bf2062763','89030217958'),
('33','Maude','Tillman','phackett@example.org','b3c21284e84249bc34cc21892c7ebd8d946e4613','89781786114'),
('34','Harrison','Rutherford','qnicolas@example.net','fa5929140b9e47a2cda205851aecab6a445e206c','89758981256'),
('35','Freddy','Mitchell','mschmitt@example.com','15a52c8068eb178da4a90238de78ec6966625016','89870567535'),
('36','Arch','Rogahn','roslyn.lindgren@example.net','9faa46a05567adbc7ca610f093641ed9e5babb59','89118814656'),
('37','Dock','Gutkowski','reynolds.orval@example.org','2d9e12a076e7cbc79118ab8b6566714e4fb0ab3b','89134477472'),
('38','Alexane','Robel','vrau@example.com','b339efaee2de8ecc56840dba11b36dcb047301d9','89625095979'),
('39','Princess','Bosco','ydibbert@example.org','62de18c6cbcfcc9f6a7471d58a987f0bd06be6f4','89165009910'),
('40','Dina','Bailey','krowe@example.org','d0ff60d17d08b007f2fee58f90fdb24bd3cd1234','89584530019'),
('41','Eldora','Bradtke','wolf.tierra@example.org','36fad0365c9696219abafb839dab42cc91a2e071','89648785812'),
('42','Theodora','Champlin','no\'conner@example.net','f5b7de12eb3c9c182598181125101ceee87b68b5','89132186376'),
('43','Justice','Bogisich','lynn02@example.net','b5e0e284425f082521b816ed6be21ada7677b7be','89453029644'),
('44','Nakia','Parker','michelle.runolfsson@example.org','57300ca63c5753bf19f792ddac055535807eb1be','89249887713'),
('45','Gia','Thompson','stacey60@example.net','a5b10a28a20ca9defcaaa8d8bff752e49fc2e5a8','89548245943'),
('46','Ernestina','Emard','fmraz@example.com','d462cab6f007f1f4a98829e2ec7481e36404bb4e','89443794984'),
('47','Dion','McDermott','reynolds.bethany@example.net','766b5abed6edeb930b8435105af37170711b252a','89182201350'),
('48','David','Towne','armando50@example.com','bd3aaf22980c9e0b7ce7943a387e8067304fa80e','89349132672'),
('49','Alana','Wolff','ibosco@example.com','4e029b31dc142abe5a39b534568931949872cad2','89685797811'),
('50','Anissa','Bergstrom','tillman57@example.org','49fe466e54445e3172807c7e7fd71aa06918a809','89008530816'); 

INSERT INTO `vk_pay` VALUES ('1','1','302928','1490','2012-03-21 09:55:23','2015-09-28 20:05:45'),
('2','2','107029','2994','1978-11-29 16:43:28','1994-12-12 13:00:00'),
('3','3','400071','6492','1976-08-20 09:08:15','1995-07-21 14:24:36'),
('4','4','552583','7612','1988-04-14 09:33:49','2015-10-19 02:48:25'),
('5','5','733922','2421','1991-09-18 15:52:05','1987-07-27 15:06:37'),
('6','6','209650','8506','2011-07-21 23:32:37','2008-09-17 20:38:59'),
('7','7','338655','3656','1985-12-31 02:28:37','2008-11-27 15:26:18'),
('8','8','933788','445','2003-08-02 20:48:38','2008-10-21 23:50:46'),
('9','9','945851','5617','1989-01-13 15:47:09','2000-08-10 16:03:00'),
('10','10','693346','5894','2001-11-22 20:38:43','1991-08-02 07:37:58'),
('11','11','763337','8698','1995-01-16 01:55:07','1987-01-11 09:16:32'),
('12','12','778065','8171','1999-02-12 01:45:39','1973-04-21 19:20:37'),
('13','13','946278','5409','2015-12-08 22:16:23','1994-10-15 04:59:35'),
('14','14','453897','554','2015-09-28 23:59:34','2011-10-26 08:03:29'),
('15','15','28500.9','8177','1990-11-14 09:33:00','1975-08-19 00:56:30'),
('16','16','767481','2395','1984-05-28 09:22:56','2020-10-25 10:56:48'),
('17','17','224410','4219','2002-11-06 10:27:09','2003-12-17 17:11:53'),
('18','18','934301','4697','1996-06-22 02:08:16','2001-05-20 03:00:57'),
('19','19','337394','4730','2009-06-06 08:31:56','1986-08-27 18:56:45'),
('20','20','200979','9149','1978-10-01 19:45:23','1990-04-07 07:41:41'),
('21','21','517471','3379','2006-12-19 17:54:13','2013-11-29 15:30:19'),
('22','22','780680','1497','1972-05-21 03:06:04','1997-01-04 16:03:13'),
('23','23','291339','665','2012-02-19 16:57:31','1993-01-29 14:28:45'),
('24','24','479306','1987','1984-02-29 12:45:47','1993-04-22 16:58:46'),
('25','25','426487','51','2010-06-06 16:55:16','2013-08-20 23:00:20'),
('26','26','612628','4181','1976-06-11 03:47:18','2011-07-01 02:41:23'),
('27','27','775450','1112','1997-10-03 11:36:50','2011-07-12 21:47:10'),
('28','28','17336.9','7144','1999-01-31 10:03:07','1993-04-12 06:56:13'),
('29','29','570160','7526','2009-06-23 16:12:03','2009-12-09 04:23:58'),
('30','30','316134','8830','1992-02-03 00:20:28','2014-10-30 06:20:01'),
('31','31','342023','1769','2011-10-04 17:13:49','1990-02-09 01:55:22'),
('32','32','826089','3507','1974-12-27 04:09:44','2003-06-08 18:14:45'),
('33','33','787790','3912','1989-06-22 13:49:28','1988-08-04 23:54:56'),
('34','34','748341','2625','2004-11-23 23:31:07','1981-09-04 06:57:23'),
('35','35','373836','8925','2011-10-09 21:19:19','2003-07-02 02:28:17'),
('36','36','990771','273','1978-10-06 04:23:36','2010-12-26 06:35:57'),
('37','37','824764','6886','2006-10-09 01:09:35','1978-03-05 03:29:54'),
('38','38','810233','9639','1971-01-25 16:24:09','1996-01-22 11:29:56'),
('39','39','295408','9286','1977-04-19 04:09:52','1985-09-03 12:33:11'),
('40','40','783902','8481','1979-02-14 18:45:47','2011-05-23 03:51:28'),
('41','41','157274','1687','1973-03-23 18:59:16','2007-03-12 05:33:37'),
('42','42','558406','3036','1992-06-30 10:51:25','2007-11-23 11:36:38'),
('43','43','12517.8','1037','1973-02-06 04:27:51','1990-05-28 17:33:59'),
('44','44','214558','135','1971-07-13 03:04:21','2015-12-23 02:11:58'),
('45','45','793406','2526','2001-06-21 16:38:21','2016-01-27 08:44:59'),
('46','46','967989','1475','1992-11-21 14:50:03','1991-08-29 10:23:23'),
('47','47','61892.7','9580','2014-02-19 21:20:56','1976-12-19 18:04:02'),
('48','48','60313.6','147','2005-07-22 21:59:21','2009-04-16 04:32:47'),
('49','49','568236','1248','2004-07-23 00:38:38','2000-04-03 02:02:58'),
('50','50','82732.3','1403','1973-07-19 08:41:50','1979-05-13 10:52:26'); 

INSERT INTO `vk_pay_history` VALUES ('1','1','211294','2002-12-01 21:42:43'),
('2','2','979088','1970-03-02 16:55:33'),
('3','3','168455','1990-04-28 00:06:18'),
('4','4','255075','1980-07-26 20:14:58'),
('5','5','481167','2018-11-29 18:46:44'),
('6','6','927834','2012-11-27 02:54:22'),
('7','7','840818','1972-04-16 01:36:12'),
('8','8','354903','1976-08-27 07:24:34'),
('9','9','365932','1996-02-11 12:24:38'),
('10','10','467833','1988-07-07 06:30:21'),
('11','11','474888','2014-08-11 01:41:35'),
('12','12','12342.8','1999-09-25 05:07:09'),
('13','13','782019','2012-01-08 22:47:46'),
('14','14','331790','1980-10-23 13:56:51'),
('15','15','451241','2011-12-14 21:40:28'),
('16','16','945399','2013-10-02 18:36:51'),
('17','17','735726','1993-07-25 11:52:08'),
('18','18','539513','1990-06-05 14:54:44'),
('19','19','466838','1993-04-09 16:25:30'),
('20','20','775657','2020-05-07 18:20:40'),
('21','21','767913','1975-11-04 18:07:27'),
('22','22','305651','2013-12-07 04:13:00'),
('23','23','711914','1970-09-20 12:37:34'),
('24','24','764785','2019-07-20 08:28:51'),
('25','25','550104','1990-07-10 01:49:48'),
('26','26','402024','1992-10-25 18:02:52'),
('27','27','105530','2012-05-06 20:36:50'),
('28','28','363750','1984-05-25 00:41:33'),
('29','29','231350','1971-07-29 03:55:59'),
('30','30','265454','1975-03-22 10:08:02'),
('31','31','652219','2000-06-15 08:55:10'),
('32','32','543643','1976-11-25 14:30:57'),
('33','33','621319','1986-02-07 11:13:10'),
('34','34','592885','2006-05-09 11:57:37'),
('35','35','601468','2013-07-06 18:07:52'),
('36','36','269105','1989-12-30 13:51:21'),
('37','37','437426','1986-03-25 01:13:39'),
('38','38','564191','2008-05-27 22:51:12'),
('39','39','215282','1982-02-06 11:44:45'),
('40','40','642868','1994-08-03 22:25:17'),
('41','41','539269','2004-10-18 21:53:51'),
('42','42','687919','2017-02-04 13:51:39'),
('43','43','865046','2012-11-21 23:06:23'),
('44','44','201418','2017-12-24 16:01:33'),
('45','45','926042','2013-11-13 21:10:14'),
('46','46','45565.1','2013-07-08 09:35:44'),
('47','47','749971','2019-03-14 16:32:38'),
('48','48','989564','2002-06-09 08:00:29'),
('49','49','416712','2020-08-27 20:23:11'),
('50','50','617582','1970-04-18 23:22:36'); 

INSERT INTO `photo_albums` VALUES ('1','laudantium','1'),
('2','non','2'),
('3','eaque','3'),
('4','sed','4'),
('5','consequatur','5'),
('6','quia','6'),
('7','ea','7'),
('8','quo','8'),
('9','velit','9'),
('10','est','10'),
('11','sed','11'),
('12','est','12'),
('13','doloribus','13'),
('14','animi','14'),
('15','tenetur','15'),
('16','qui','16'),
('17','temporibus','17'),
('18','laborum','18'),
('19','placeat','19'),
('20','minus','20'),
('21','omnis','21'),
('22','voluptatibus','22'),
('23','voluptatem','23'),
('24','dolorem','24'),
('25','dolore','25'),
('26','illum','26'),
('27','dolor','27'),
('28','rerum','28'),
('29','quia','29'),
('30','id','30'),
('31','ducimus','31'),
('32','rerum','32'),
('33','ut','33'),
('34','et','34'),
('35','occaecati','35'),
('36','qui','36'),
('37','error','37'),
('38','dolore','38'),
('39','laboriosam','39'),
('40','et','40'),
('41','numquam','41'),
('42','sunt','42'),
('43','ratione','43'),
('44','minima','44'),
('45','aut','45'),
('46','rerum','46'),
('47','quae','47'),
('48','quasi','48'),
('49','ut','49'),
('50','sint','50');

INSERT INTO `messages` VALUES ('1','1','11','Omnis commodi est consequatur inventore quod eum dolore. Nostrum nihil reprehenderit minima consequuntur accusantium est minima. Ratione reiciendis quia sequi. Delectus aperiam enim quibusdam.','2021-12-17 20:04:23'),
('2','2','1','Aut est assumenda et minima nemo. Ut laborum aut mollitia cum. Saepe id nulla officiis deserunt cum voluptatibus.','1994-04-29 02:43:54'),
('3','2','1','Temporibus sapiente quis deserunt. Cum eum iure est eius iusto tempora veritatis quod.','2019-02-19 23:30:24'),
('4','3','1','Nostrum dolor et necessitatibus nam. Culpa ipsum eum est. Ab laborum dicta a est et qui dolor. Voluptatum magnam praesentium id suscipit.','2003-08-10 02:43:12'),
('5','2','1','Nostrum ut molestias aliquam sapiente voluptatem provident. Aut dignissimos sequi veniam adipisci.','1975-04-15 19:42:07'),
('6','6','16','Accusamus est iusto vero modi ut rem ex. Quia ducimus similique quis sit. In tempora non optio sunt error cupiditate. Quo aspernatur et ab ipsam aliquam.','1998-10-25 15:42:17'),
('7','2','17','Repudiandae et sed fugiat cupiditate ut quia. Qui quo aut non quidem autem. Sapiente et officiis est voluptatem sunt dicta molestias consectetur. Eius distinctio molestiae deserunt quasi adipisci. Magni amet doloribus beatae amet quo facere.','1977-07-25 10:40:33'),
('8','5','1','Cum aspernatur consequatur non veritatis sint fugiat suscipit nihil. Impedit assumenda voluptatum magni aut. Voluptatem corporis quidem eos.','1989-05-28 01:10:30'),
('9','9','19','Et autem quia quae sunt. Eos id iure modi recusandae labore et magnam. Sint non provident non et sit et. Sint et minima molestiae sed debitis.','1985-08-02 00:40:42'),
('10','10','20','Unde quaerat eos dolor aut id fugit. Et minus at reiciendis ea sed dolorum. Natus doloribus deleniti ut quibusdam blanditiis voluptate.','2015-03-29 22:27:41'),
('11','11','21','Est itaque maiores et consequatur. Distinctio possimus et magni quis aut. Temporibus in recusandae blanditiis rerum et atque.','1987-05-19 21:11:15'),
('12','12','22','Harum saepe sit aperiam nisi. Optio consequatur fugiat est autem aut ex facilis. Eum quos omnis quod adipisci quaerat.','1981-12-21 04:12:16'),
('13','13','23','Eligendi sapiente porro nobis. Sunt aut et voluptate est in ut laborum. Maxime commodi reprehenderit provident aut ex non maxime.','2008-12-26 23:42:06'),
('14','14','24','Illum corrupti rerum eum eveniet et consectetur. Vel aut eius iure provident distinctio. Qui tenetur et aspernatur sit. Ea animi qui sit in.','1999-04-05 18:59:24'),
('15','15','25','Id consequatur voluptas est quisquam vitae et. Quibusdam voluptatem provident natus. Et enim sit id ex ut consequatur dolores praesentium. Praesentium esse laboriosam ipsum delectus non nam ipsam.','2001-09-28 19:05:10'),
('16','16','26','Consequatur sequi qui cum repellat dolorem magnam. Maxime dolorem et doloremque nemo est. Omnis nihil natus accusamus qui iste a tenetur. Sapiente aut illum voluptatem omnis. Illum est ipsa eligendi et nesciunt sapiente deserunt.','1978-09-21 22:38:10'),
('17','17','27','Illum eos explicabo distinctio quia et voluptas corporis occaecati. Aliquid consequatur ducimus quo nihil dolore neque nemo dolores. Praesentium earum quas itaque.','1978-06-29 01:02:52'),
('18','18','28','Maxime voluptatem et ea nostrum rem. Assumenda vitae temporibus itaque consequatur est.','2014-03-09 16:15:16'),
('19','19','29','Perferendis ipsam illum minima qui aliquam vel. Quod similique et molestiae omnis odio. Deserunt vel et explicabo itaque. Quis temporibus incidunt ea cum aliquid quia quod ipsam. Inventore officia quis soluta officiis aut.','2011-07-14 06:05:41'),
('20','20','30','Ex sapiente labore reprehenderit ducimus cumque excepturi voluptatem. Et vel ipsa vero ipsam ipsam omnis. Perferendis omnis quia sed amet ex ratione quaerat velit. Voluptatem eum voluptates sed totam quo occaecati amet.','2016-12-04 03:06:16'),
('21','21','31','Explicabo sed deleniti error doloremque consequatur. Debitis dolores sit quisquam et ullam qui placeat quaerat. Rerum blanditiis laborum et.','1996-08-14 16:29:30'),
('22','22','32','Error aut deleniti repellat voluptas et libero impedit. Quis libero quam repudiandae sint illo. Est cupiditate suscipit quas sit et provident.','2015-10-03 00:51:57'),
('23','23','33','Aspernatur expedita minima fugit. Amet numquam dolores ipsam est quisquam libero. Sint minima voluptates cupiditate quae qui autem. Molestias aut ipsam architecto in ipsam totam enim.','1993-03-16 02:56:12'),
('24','24','34','Qui suscipit ut minus aperiam. Aut in qui voluptatem. Sint veniam pariatur rerum minus.','2016-04-18 18:57:56'),
('25','25','35','Necessitatibus autem natus omnis repellendus. Accusamus a sunt itaque quis expedita cumque. Voluptatem dolor tempore placeat.','1976-03-02 06:14:29'),
('26','26','36','Quod non dolor omnis dignissimos facere beatae reiciendis et. Optio eos necessitatibus pariatur reiciendis unde quia. Fugit deleniti reprehenderit aut. Iusto autem enim iusto.','1971-07-01 18:34:34'),
('27','27','37','Ipsum qui et mollitia qui et omnis dolores omnis. Voluptatem laboriosam vitae quia. Deserunt facilis numquam dolores consequatur fugiat maxime.','1982-07-18 02:21:42'),
('28','28','38','Sapiente temporibus nemo maiores expedita excepturi sint. Optio non accusamus eveniet. Et tempora reiciendis necessitatibus est reiciendis quia. Quaerat ut qui qui.','2010-11-20 08:07:16'),
('29','29','39','Voluptates vel velit veniam maxime molestias ipsa nihil. Aut maiores maxime quia et perferendis cumque et. Maxime voluptatibus minima sint voluptas ipsam nisi sit. Quia et animi cumque ad autem quidem dicta. Voluptatibus similique eum repellat ut quaerat magnam.','2017-07-31 10:46:44'),
('30','30','40','Magni nihil placeat ad similique. Dolor ea aspernatur quia culpa similique voluptatem. Aut facilis nesciunt voluptas explicabo. Delectus ratione unde eum omnis eligendi. Illo et quis soluta cum et voluptatem vitae blanditiis.','2016-06-03 06:47:34'),
('31','31','41','Aliquam quas tenetur rerum est qui. Id aliquam repudiandae voluptatem eos ut.','1971-12-29 05:55:28'),
('32','32','42','Magni libero nostrum velit molestiae esse voluptate illum dolores. Soluta commodi accusantium commodi. Et aut dolorem delectus corporis.','1971-02-19 19:21:48'),
('33','33','43','Quo sunt itaque magni. Consequatur quo dignissimos et minus et.','2000-10-31 23:59:06'),
('34','34','44','Odio voluptatem corporis molestiae maxime eos et non. Voluptate autem et consequuntur officia fugit. Labore inventore dignissimos sit.','2014-12-18 20:21:17'),
('35','35','45','Enim cumque numquam qui at. Sed aut quo cum corporis odio soluta. Maiores molestias tenetur eaque at voluptatem. Doloremque fugit mollitia perferendis repudiandae cupiditate placeat inventore corporis.','1985-05-18 06:33:04'),
('36','36','46','Et dolorem non vero in. Quae ipsum accusamus consectetur libero voluptatem. Et consequatur accusantium harum quod qui non.','1996-06-24 09:41:08'),
('37','37','47','Enim facilis labore id sit ratione eaque. Ut quis ipsum laborum molestiae ad hic. Temporibus aut nihil delectus.','1988-04-27 13:23:45'),
('38','38','48','Quibusdam ut iure blanditiis perspiciatis est omnis. Aliquid non in nihil voluptatem ut harum facere. Exercitationem nisi quidem similique quas.','1980-04-30 15:29:12'),
('39','39','49','Quaerat quas dolor neque assumenda quis consequatur unde id. Sunt libero ut nobis error asperiores sapiente maiores ea. Ut non sequi dignissimos aspernatur.','2004-08-09 20:36:00'),
('40','40','50','Eos cupiditate alias perferendis. Cumque quia commodi ab voluptatem repellat quia illo.','1999-05-27 07:41:40'),
('41','41','1','Quos recusandae cumque laudantium non deserunt. Inventore nihil unde sit explicabo et. Et ut voluptates occaecati ea laudantium praesentium laudantium.','1977-07-24 04:09:21'),
('42','42','2','Odit qui quae non qui. Sed saepe voluptatem eligendi in harum cum.','2011-07-31 04:09:32'),
('43','43','3','Sed reprehenderit unde culpa molestiae nihil aliquid doloremque. Illo aut rerum voluptas est. Quam tenetur est dolorem quidem molestiae inventore. Veniam delectus sint velit. Nesciunt necessitatibus iure recusandae impedit exercitationem distinctio.','2006-12-14 10:35:13'),
('44','44','4','Tenetur est tenetur odit beatae soluta fugiat accusamus. Enim omnis recusandae nam eum. Quisquam voluptatem perspiciatis quo voluptate maxime. Impedit aut praesentium neque possimus reiciendis qui voluptates accusantium.','1986-03-17 20:06:24'),
('45','45','5','Sint quis in aut sed nesciunt. Et et sunt sunt voluptatibus autem. Tempore hic aut aliquid nihil consequuntur iure sit.','2002-04-21 18:21:07'),
('46','46','6','Et nulla distinctio recusandae distinctio. Minima est eligendi deleniti odio quam. Est recusandae ut iusto maxime. Inventore consequatur nisi illo sit recusandae.','1977-10-27 02:52:51'),
('47','47','7','Sint et fugit ut rem ipsa commodi sed. Veniam omnis veniam quidem atque sint. Ex rerum beatae vero minus eaque aut excepturi maxime.','2010-09-23 08:27:54'),
('48','48','8','Ipsa et deleniti necessitatibus voluptatibus qui ut facere. Quod enim voluptate adipisci tenetur provident vel. Molestias laborum et saepe placeat nulla excepturi necessitatibus.','2015-01-29 07:40:01'),
('49','49','9','Quia molestiae quam atque qui aut et ipsum quo. Architecto asperiores accusantium reprehenderit laborum ducimus neque. Non iste quam fugit.','1982-03-15 16:27:25'),
('50','50','10','Ut explicabo repudiandae voluptas sit qui ducimus corrupti porro. Dolorem qui et tempora. Repudiandae ut et enim non quia ullam nihil quaerat.','2008-06-11 20:45:55'); 

INSERT INTO `media_types` VALUES ('1','fugit','2016-05-21 09:41:43','1995-04-06 14:27:47'),
('2','sit','1982-08-14 22:52:13','2020-10-26 23:01:57'),
('3','eum','1988-02-16 18:37:50','2018-06-17 19:43:40'),
('4','qui','1996-04-08 10:31:19','1990-09-14 19:22:20'),
('5','et','2001-01-26 06:00:52','1979-12-14 02:48:28'),
('6','atque','1976-11-15 13:30:28','1995-09-19 22:21:21'),
('7','facilis','1989-08-18 17:51:43','2005-03-10 23:54:54'),
('8','voluptates','2003-01-03 13:07:22','1998-02-08 23:04:34'),
('9','delectus','2018-02-22 19:43:29','2002-09-09 09:32:39'),
('10','modi','1991-08-30 22:40:07','1979-08-16 20:08:41'); 

INSERT INTO `gifts_types` VALUES ('1','c0c8a25bf3a4da3a95f8233311adaa673d95f28b40f78d09e428ba6f6a8f2c31','2004-10-11 09:03:57','1984-01-09 07:53:13'),
('2','541a03cb3d9dc71a583bed0f68bafc27e33d17b72d9a81b3a1b99dbae9254b09','2013-12-14 12:59:22','1975-12-21 17:32:25'),
('3','de10063fe1dbe0a2f7dec90e17d2e729d5f370d0c0009c216adc2c39d0b533b4','2020-02-17 10:39:12','2018-05-27 03:12:16'),
('4','27f7dd0d626030f9a6be48d3c49febcedc569a8b53f78fd7c21a81730d08f57b','1970-10-27 22:54:21','1998-07-25 10:46:45'),
('5','af5f7dfc640ce05fa1ffe4acee74f0181f30ecc296679f6fcaca1d3abf456616','1982-08-24 16:01:45','1993-02-19 08:35:31'),
('6','a0eb08de8b345da41b8314ea93fe8d76b4363eb2646e6e6a4fce3754d8b39b72','1999-11-26 15:32:29','1994-09-08 13:14:09'),
('7','773f4586a0db8f6b65952261727df086f3fe462fb1a22cf537aba8fae04a0395','2006-04-01 15:01:06','1980-08-12 05:22:35'),
('8','8107acd6a082adf1c9f1b31e028a9305549106dcaa4d0ad0215ec3f6763a29f7','1971-06-22 01:40:18','1980-01-09 02:37:05'),
('9','dd075c3590d7d2d88914c0b1acc52e292e93764ed679015523254eb23c5fd96b','1985-09-15 21:07:37','2003-12-24 14:10:39'),
('10','f7f35673b50a7963ae57230e6350e86ee03e4b94fbe6065897999cd8fcdc6244','1970-06-13 16:13:27','1991-07-21 15:09:45'); 

INSERT INTO `gifts` VALUES ('1','1','11','1','2012-08-23 19:06:56'),
('2','2','12','2','1990-02-18 03:28:32'),
('3','3','13','3','2000-04-28 08:14:33'),
('4','4','14','4','2001-11-13 00:59:37'),
('5','5','15','5','2002-08-24 02:53:46'),
('6','6','16','6','1987-04-16 19:06:56'),
('7','7','17','7','1978-01-21 07:33:47'),
('8','8','18','8','2010-02-04 11:49:52'),
('9','9','19','9','2002-06-23 23:56:42'),
('10','10','20','10','1996-08-07 00:04:13'),
('11','11','21','1','2018-09-25 01:03:35'),
('12','12','22','2','2004-07-25 14:12:38'),
('13','13','23','3','2010-04-26 17:34:42'),
('14','14','24','4','2011-09-01 09:28:11'),
('15','15','25','5','2004-10-08 14:56:54'),
('16','16','26','6','2018-08-02 08:25:39'),
('17','17','27','7','1974-02-14 23:06:14'),
('18','18','28','8','1992-07-08 19:33:27'),
('19','19','29','9','1990-08-12 17:08:47'),
('20','20','30','10','2008-07-15 03:29:50'),
('21','21','31','1','1996-08-09 16:38:18'),
('22','22','32','2','1975-01-14 17:32:19'),
('23','23','33','3','2000-07-30 11:45:35'),
('24','24','34','4','1970-07-06 20:19:00'),
('25','25','35','5','2002-01-25 10:13:36'),
('26','26','36','6','1972-11-06 11:09:59'),
('27','27','37','7','2001-04-01 20:30:20'),
('28','28','38','8','2004-07-05 19:21:24'),
('29','29','39','9','1979-09-09 03:33:36'),
('30','30','40','10','2019-09-01 07:06:49'),
('31','31','41','1','1984-10-24 05:00:24'),
('32','32','42','2','1989-04-01 14:31:07'),
('33','33','43','3','1997-12-27 04:29:49'),
('34','34','44','4','2011-02-12 02:57:01'),
('35','35','45','5','2012-04-06 15:33:16'),
('36','36','46','6','1996-12-04 14:34:40'),
('37','37','47','7','2018-10-30 02:36:52'),
('38','38','48','8','2002-12-10 20:17:29'),
('39','39','49','9','2011-12-08 11:50:47'),
('40','40','50','10','1992-03-02 14:30:08'),
('41','41','1','1','2003-03-21 04:22:38'),
('42','42','2','2','1970-09-08 22:48:34'),
('43','43','3','3','1984-03-28 22:08:01'),
('44','44','4','4','2011-12-13 08:10:18'),
('45','45','5','5','1981-10-08 15:53:19'),
('46','46','6','6','2000-01-10 19:40:40'),
('47','47','7','7','1972-02-18 14:55:33'),
('48','48','8','8','1979-12-05 06:26:50'),
('49','49','9','9','1970-11-18 17:20:48'),
('50','50','10','10','1992-01-26 18:00:50');

INSERT INTO `friend_requests` VALUES ('1','11','declined','2013-09-14 07:23:02','2011-12-09 21:46:55'),
('2','12','declined','1993-12-16 15:23:04','1995-01-19 12:12:05'),
('3','13','approved','1978-04-18 03:19:02','1990-09-27 02:55:48'),
('4','14','declined','1997-02-15 03:28:57','1998-11-09 02:09:22'),
('5','15','requested','1990-05-09 01:32:50','1974-03-19 15:18:58'),
('6','16','unfriended','1998-06-14 08:35:53','1977-09-29 11:01:09'),
('7','17','approved','2019-10-15 05:18:04','2008-08-17 03:22:20'),
('8','18','unfriended','2013-11-03 22:27:25','2005-02-09 11:09:21'),
('9','19','unfriended','2020-07-15 03:56:00','2011-11-26 13:03:21'),
('10','20','unfriended','1970-10-28 16:01:22','1994-01-28 08:31:20'),
('11','21','unfriended','1990-05-17 11:41:39','2002-11-06 09:24:21'),
('12','22','unfriended','1972-09-24 01:35:30','1981-02-27 15:50:07'),
('13','23','requested','1998-01-31 23:24:54','1973-10-28 23:08:51'),
('14','24','requested','2011-12-23 04:12:25','1990-01-13 21:49:40'),
('15','25','requested','1983-02-19 22:17:10','1975-08-01 06:59:52'),
('16','26','declined','2004-03-21 00:04:50','2013-03-09 15:31:27'),
('17','27','approved','2018-09-14 07:27:27','2020-11-21 19:39:02'),
('18','28','unfriended','1970-11-17 23:40:52','1998-12-23 13:34:32'),
('19','29','requested','2008-03-05 04:22:45','2015-06-06 13:59:38'),
('20','30','declined','1983-01-06 10:07:01','1977-01-06 05:56:27'),
('21','31','declined','2012-11-06 21:29:53','2010-06-07 11:56:57'),
('22','32','declined','2016-01-03 04:30:02','1992-05-14 14:02:11'),
('23','33','declined','1983-04-30 10:23:02','1997-02-02 11:35:04'),
('24','34','unfriended','2012-11-18 05:24:12','1990-06-06 03:13:17'),
('25','35','unfriended','2015-02-24 20:46:40','1973-01-27 13:18:35'),
('26','36','declined','2001-08-06 17:04:23','1971-10-17 13:16:44'),
('27','37','declined','2007-06-29 00:29:16','2009-10-30 21:45:09'),
('28','38','declined','2010-08-17 19:18:08','1991-02-19 18:44:44'),
('29','39','requested','2004-08-18 15:09:55','1987-09-01 02:47:17'),
('30','40','approved','1986-12-30 11:16:15','1970-11-20 15:49:28'),
('31','41','unfriended','2002-05-17 15:20:35','2018-11-13 08:16:42'),
('32','42','unfriended','1996-12-18 10:53:57','2005-10-22 00:17:24'),
('33','43','unfriended','1986-04-09 18:03:07','1978-11-29 20:44:39'),
('34','44','approved','1978-10-28 07:51:02','2019-03-11 01:51:30'),
('35','45','unfriended','1979-05-30 02:41:49','2005-09-25 21:46:20'),
('36','46','declined','1992-12-08 11:30:36','1985-06-15 11:50:47'),
('37','47','approved','1987-12-15 08:15:45','1983-12-07 13:43:50'),
('38','48','approved','2020-03-16 10:36:58','1998-10-31 18:57:48'),
('39','49','declined','2003-11-26 14:24:59','1972-10-19 09:05:08'),
('40','50','unfriended','1987-12-26 22:43:47','1999-09-24 07:11:27'),
('41','1','unfriended','2016-07-16 23:21:01','2016-11-01 04:45:09'),
('42','2','unfriended','2016-10-02 17:57:17','2010-08-19 02:55:15'),
('43','3','declined','1987-11-04 17:13:41','1979-06-30 09:09:19'),
('44','4','approved','1981-11-05 02:54:53','1988-09-28 01:54:41'),
('45','5','declined','2019-07-22 12:23:07','1976-05-03 05:59:11'),
('46','6','unfriended','2019-01-02 18:33:47','2010-06-18 22:58:01'),
('47','7','declined','2011-04-29 07:23:42','1987-11-12 15:21:00'),
('48','8','approved','1999-05-31 12:26:29','1978-01-02 17:51:46'),
('49','9','requested','1990-08-11 05:46:52','2000-08-02 08:31:39'),
('50','10','approved','1998-01-27 09:31:57','1970-11-08 12:19:59'); 

INSERT INTO `communities` VALUES ('1','ea','1'),
('2','aliquid','2'),
('3','accusamus','3'),
('4','et','4'),
('5','dolorem','5'),
('6','soluta','6'),
('7','reprehenderit','7'),
('8','accusamus','8'),
('9','architecto','9'),
('10','quia','10'),
('11','aliquam','11'),
('12','quia','12'),
('13','consequatur','13'),
('14','delectus','14'),
('15','eum','15'),
('16','tempora','16'),
('17','esse','17'),
('18','atque','18'),
('19','dolorem','19'),
('20','illo','20'),
('21','a','21'),
('22','velit','22'),
('23','nostrum','23'),
('24','explicabo','24'),
('25','ut','25'),
('26','ut','26'),
('27','sunt','27'),
('28','molestiae','28'),
('29','harum','29'),
('30','numquam','30'),
('31','odio','31'),
('32','impedit','32'),
('33','ut','33'),
('34','dolorem','34'),
('35','cupiditate','35'),
('36','perferendis','36'),
('37','officia','37'),
('38','quia','38'),
('39','quas','39'),
('40','soluta','40'),
('41','et','41'),
('42','quo','42'),
('43','quibusdam','43'),
('44','et','44'),
('45','voluptatem','45'),
('46','animi','46'),
('47','quasi','47'),
('48','dolor','48'),
('49','consequatur','49'),
('50','sint','50'); 

INSERT INTO `media` VALUES ('1','1','2','Architecto nihil esse voluptates a. Animi corrupti necessitatibus sed provident sequi accusamus. Recusandae illum voluptas voluptas molestias maiores corporis et. Qui autem et unde provident cupiditate aut necessitatibus.','fugiat','8304469',NULL,'2007-01-27 19:33:39','1997-11-24 23:40:48'),
('2','2','1','Voluptate voluptatem aut nesciunt ea. Et aut totam quidem aut rem necessitatibus et ab. Totam fugit harum ab iusto porro repellendus.','est','7',NULL,'1993-07-27 01:13:22','2011-02-19 04:55:56'),
('3','3','3','Ab quibusdam labore iusto dolore sit. Quasi ullam sit maxime. Consequatur odio quia non corrupti quo.','voluptatem','1',NULL,'2008-10-25 19:41:46','2011-01-21 16:42:43'),
('4','4','4','Repellendus eaque autem fugit nisi voluptas voluptas nulla perspiciatis. Excepturi molestiae tempore quis adipisci. Illum quas et iure et sed.','aliquid','108',NULL,'1988-11-06 18:26:53','1979-10-13 14:27:20'),
('5','5','5','Ab velit tempore blanditiis nihil omnis ut sequi. Perferendis debitis incidunt dolorem architecto incidunt quae qui. Delectus aliquam libero deserunt ipsam fugiat asperiores repellat magni. Unde voluptatem facilis animi harum.','mollitia','9473001',NULL,'1997-08-01 06:22:37','1995-05-06 20:17:39'),
('6','6','6','Accusamus iure accusamus et non expedita. In reiciendis quibusdam nulla. Illum non quia beatae expedita et.','excepturi','45',NULL,'1982-03-08 07:54:41','1976-10-23 07:46:49'),
('7','7','7','Dolor aliquid eum vel nemo aut. Quam et ipsum nisi autem voluptates dignissimos. Quas culpa nemo similique neque sed sapiente unde.','doloremque','45413812',NULL,'1995-01-12 07:21:41','1970-08-04 08:36:40'),
('8','8','8','Itaque soluta et eos et numquam est tempore. Est animi debitis quasi in ab qui vel. Aut ut consequatur necessitatibus inventore. Fugiat debitis ad possimus nihil voluptatem consequuntur aut.','sint','82093445',NULL,'1991-02-05 01:40:45','2016-03-14 20:37:36'),
('9','9','9','Itaque rem doloremque ipsum enim consequatur. Velit qui asperiores nihil qui cum dolore eos. Possimus culpa suscipit incidunt.','repudiandae','25',NULL,'1978-10-03 06:16:10','2010-07-24 23:43:59'),
('10','10','10','Quod aliquam et eveniet iure voluptatem. Quam deserunt earum ab illum nisi veniam veritatis. Qui vel et ut quasi et rem. Unde neque tempore cupiditate et similique dolorem.','quia','0',NULL,'1984-01-01 17:52:08','2020-06-09 21:24:13'),
('11','1','11','Maxime suscipit doloremque expedita enim qui reprehenderit corrupti autem. Dolorem ducimus quo quidem cum. Voluptatem possimus ad atque eius sunt.','rerum','7380',NULL,'1973-08-25 02:44:36','1972-10-19 03:04:14'),
('12','2','12','Amet voluptatum error consequuntur distinctio perferendis ratione. Esse eaque magni cum ipsum rerum omnis. Ducimus esse maiores repellat deleniti. At ea voluptatem quisquam repellendus ut quod.','eveniet','0',NULL,'1995-05-05 21:55:44','1987-08-23 07:23:55'),
('13','3','13','Quis ut asperiores omnis asperiores. Mollitia blanditiis qui aut officia. Voluptas accusamus tempora odit laudantium totam itaque. Itaque hic laboriosam voluptatibus dolor.','provident','45',NULL,'1989-07-30 23:16:07','1996-06-18 16:57:52'),
('14','4','14','Laborum doloremque eveniet temporibus sed iure rem. Iure qui ut repudiandae qui recusandae. Commodi sit magnam non distinctio rem adipisci.','saepe','94',NULL,'2020-11-16 13:49:49','1972-08-24 16:59:47'),
('15','5','6','Fugit est sequi laudantium quas laboriosam. Repudiandae illo sunt placeat rerum.','sed','1',NULL,'2013-04-21 15:18:17','1978-05-09 15:32:13'),
('16','6','16','Ut voluptas dolor ratione placeat dolores. Eveniet nostrum assumenda velit. Qui voluptates quia qui qui exercitationem laborum ut ex.','quibusdam','9709',NULL,'1992-11-20 15:03:21','1978-03-25 17:33:17'),
('17','7','17','Itaque sit perspiciatis impedit voluptatem. Non quis accusantium dicta natus. Vitae repellendus labore voluptatem maxime nam modi. Ipsa consequuntur quia quisquam deserunt qui.','voluptatem','4451',NULL,'1983-11-19 22:24:10','1999-08-08 23:23:08'),
('18','8','18','Quos et autem delectus id atque hic. Quod alias ex aspernatur ea.','autem','662677328',NULL,'2003-01-17 08:14:31','2015-04-27 11:50:27'),
('19','9','19','Deleniti consequatur in et beatae odio. A est quis quia ipsa maxime autem quis. Totam magnam rerum quae suscipit qui hic. Est ducimus aut quod aut.','repudiandae','33',NULL,'1976-12-17 21:21:52','2002-05-19 17:58:33'),
('20','10','20','Dolores facilis consequatur qui voluptate et. Iusto reiciendis ut iusto quis aliquam repudiandae qui. Dolores qui laborum maxime velit quisquam voluptatem quam. Esse nam sit soluta ullam enim et beatae.','nam','8109639',NULL,'1986-01-30 12:56:57','1973-12-08 03:12:40'),
('21','1','21','A est architecto quas quis vero minus. Voluptatem vel autem quo voluptatem voluptas fugiat repellendus. Eos accusantium soluta qui nulla accusantium incidunt esse. Rem dolor porro qui harum asperiores.','eos','7784378',NULL,'2019-01-01 16:28:49','2010-08-19 02:17:39'),
('22','2','22','Voluptatum corrupti odio voluptatem id. In ea quidem ut illo praesentium animi. Blanditiis voluptate nihil dolore nesciunt alias. Suscipit fuga tempore excepturi totam similique maiores sint.','ut','56',NULL,'1996-12-14 23:49:36','1990-08-11 00:09:06'),
('23','3','23','Aliquid quas dolores provident sed ut animi voluptate similique. Et veniam architecto et dolor est tenetur non sit.','rerum','75',NULL,'1975-04-10 00:03:39','1989-08-29 19:34:23'),
('24','4','24','Voluptatum neque et sed. Veniam quia enim quae culpa consequatur amet sint vel. Deserunt voluptatem eveniet fugiat dolore.','quia','71514',NULL,'2002-04-27 03:16:20','1991-06-25 15:25:18'),
('25','5','25','Quidem est velit praesentium et ipsam qui. Architecto quis assumenda doloribus est enim.','at','1',NULL,'2020-03-05 13:07:32','1993-06-09 23:27:40'),
('26','6','26','Doloribus consequatur omnis amet nisi. Ut quam voluptas eum blanditiis veniam rerum laudantium reiciendis. Aut ut eius quis sapiente molestias.','placeat','3113',NULL,'2011-02-21 16:24:52','1973-04-19 17:00:04'),
('27','7','27','Id dolores et nisi occaecati doloribus nihil. Omnis veritatis perspiciatis sit. Et culpa reprehenderit quaerat qui earum molestiae id.','qui','8304',NULL,'1982-07-29 19:35:03','1977-05-24 00:02:22'),
('28','8','28','Maxime omnis sint aliquam alias voluptate ipsum rerum. Perspiciatis officiis ut molestias ex molestiae. Quos est odit aut ut ea ut. Eligendi debitis ratione vel et in magnam omnis.','illum','138504984',NULL,'1977-07-17 16:14:31','2008-02-08 03:23:36'),
('29','9','29','Eos aspernatur sed dolores rem. Commodi nulla at atque sit sit sit. Ipsum et consectetur eum ducimus deleniti eveniet et.','totam','29459900',NULL,'1993-04-14 05:44:16','2001-10-17 18:58:35'),
('30','10','30','Non aut accusamus dolorem quidem. Eum nemo aliquid in at necessitatibus et voluptates sit.','vel','48531031',NULL,'1975-10-12 07:56:18','2017-03-22 01:40:57'),
('31','1','31','Molestiae eaque aut laborum expedita nihil. Cumque ea earum similique soluta. Atque at sit ut accusamus aperiam similique minus.','nihil','7680765',NULL,'2008-08-23 18:58:03','1984-05-17 06:53:59'),
('32','2','32','Aut dolores nisi laborum blanditiis repudiandae id possimus. Sapiente enim expedita minima non molestias natus recusandae. Enim numquam qui ut quidem.','aut','0',NULL,'1973-08-12 05:21:48','2014-04-05 08:48:45'),
('33','3','33','Et accusantium reprehenderit aut officiis et. Hic dolorem molestiae velit non omnis velit. Dicta corrupti est culpa et excepturi aperiam. Odio mollitia dicta placeat voluptate quod ipsum eaque omnis.','et','49',NULL,'2001-08-21 12:48:05','1971-11-17 00:05:02'),
('34','4','34','Doloremque nesciunt sed accusantium similique reiciendis. Illum quasi dicta enim. Amet quidem quas magni.','consectetur','60787610',NULL,'2017-11-02 19:01:34','1987-09-26 08:42:19'),
('35','5','35','Animi aut laboriosam quod ut rem praesentium. Dolores officiis accusantium aut qui modi illum non. Pariatur optio rerum qui et.','aspernatur','308',NULL,'1990-08-06 16:40:46','1975-01-24 22:55:35'),
('36','6','36','Voluptas doloremque doloribus occaecati ut similique eaque. Aliquam error est quod sapiente omnis laudantium vitae. Ex iusto quas est amet possimus praesentium ut voluptas.','quia','881282292',NULL,'2012-07-02 04:42:57','1993-04-13 05:05:15'),
('37','7','37','Quisquam quos consequatur eum quos reprehenderit quo delectus. Dolor aut impedit tempore aperiam. Perspiciatis sapiente pariatur enim quae est ea beatae. Minus architecto quos sed voluptates quidem consequatur.','ad','0',NULL,'2018-04-09 00:25:35','1971-09-06 19:35:54'),
('38','8','38','Nihil corporis aut enim. Rem provident qui architecto voluptas. Reprehenderit deserunt eveniet cumque qui pariatur odit expedita. Voluptas placeat magni minima eius unde. Consequatur alias repudiandae amet tempore non sint ab.','quasi','372666102',NULL,'1979-11-22 07:33:01','2006-01-21 15:48:36'),
('39','9','39','Fugit qui consequatur assumenda neque vero sint velit quia. Sed aut aliquam corrupti ut qui corrupti quasi.','ut','90190',NULL,'1986-12-04 02:27:52','2005-08-12 18:22:26'),
('40','10','40','Et in rerum aliquam aliquam qui non corporis modi. Nam est veniam est itaque soluta. Recusandae voluptas architecto vel dolor corporis officia totam.','ducimus','4678',NULL,'1970-05-20 03:03:47','1985-11-24 02:57:09'),
('41','1','41','Labore molestias ut magni non ut. Eius numquam asperiores est amet est. Tempore harum atque ratione incidunt minus consectetur dignissimos. Cumque architecto qui doloribus debitis ut error quaerat. Sunt pariatur natus exercitationem dolores ratione et sint.','quae','3',NULL,'1975-09-19 04:02:44','1981-12-19 17:11:08'),
('42','2','42','Et fugit tempore quis et culpa rerum. Voluptas quia quia ut sed enim id. Quod quia eaque facilis molestiae et nostrum doloribus ut. Voluptatem laboriosam molestiae et et.','aliquam','678047',NULL,'2005-03-29 09:04:04','2014-06-23 16:57:04'),
('43','3','43','Optio adipisci excepturi impedit consequatur optio ut et excepturi. Debitis consequuntur laudantium eos id est et praesentium animi. Blanditiis non minus quae sed.','fugiat','7278',NULL,'1975-04-03 16:30:29','1995-07-04 09:50:32'),
('44','4','44','Autem in recusandae perspiciatis blanditiis saepe ut ad. Tempora quidem est assumenda ipsum aut magnam. Voluptates quia et et voluptas eveniet nihil quidem dolor.','cumque','25434',NULL,'1979-10-02 19:33:32','2007-12-12 19:35:02'),
('45','5','45','Illum dolorem error nihil quis accusamus dolorem. Quia dolorum molestiae quas explicabo eveniet ea est. Harum corrupti quibusdam sequi illo assumenda repellat quisquam.','tenetur','0',NULL,'1988-07-05 06:12:37','1994-07-22 20:01:04'),
('46','6','46','Voluptas et earum iusto iste ut repudiandae. Et voluptatem est quisquam a suscipit unde harum eligendi. Ut quo mollitia qui rerum numquam voluptatum.','facere','910',NULL,'1989-04-10 23:01:57','1982-02-21 01:12:38'),
('47','7','47','Sit animi ut pariatur. Sit eos et aut voluptatem distinctio. Iure et sit consequatur facere voluptate ut. Voluptatum laborum exercitationem minus.','cum','49071587',NULL,'2008-07-07 15:35:31','1984-08-31 18:55:04'),
('48','8','48','Illum qui explicabo et autem laudantium voluptatem. Et eaque soluta minus corporis est. Voluptas quam nulla consequatur qui et autem quas.','ducimus','9225',NULL,'2000-03-31 07:24:06','1974-08-11 07:36:54'),
('49','9','49','Aut qui nam cupiditate et explicabo voluptatem. Excepturi voluptatem repudiandae quas facere qui. Consequatur fuga et ullam. Voluptatem saepe dolorem commodi delectus ipsum quaerat.','sint','541070513',NULL,'1996-08-07 02:25:27','1972-08-24 21:41:37'),
('50','10','50','Molestiae corporis fuga ex. Aut rerum fugiat fugit dolorem. Ipsa perspiciatis labore consequatur aut sit. Rerum ut non eum delectus.','aliquam','448036451',NULL,'1974-10-05 03:53:49','2020-05-01 01:55:59'); 

INSERT INTO `likes` VALUES ('1','1','1','2019-02-08 08:52:36'),
('2','2','1','2009-11-09 08:00:00'),
('3','3','3','1996-01-28 22:34:20'),
('4','4','4','1980-01-12 07:11:09'),
('5','5','5','1997-07-27 12:41:42'),
('6','6','6','1993-03-23 14:11:19'),
('7','7','7','1972-01-26 03:36:30'),
('8','8','8','1986-09-17 14:47:17'),
('9','9','9','2001-05-30 03:01:43'),
('10','10','10','2009-08-21 20:15:30'),
('11','11','11','2004-05-28 20:30:50'),
('12','12','12','2020-01-14 20:08:55'),
('13','13','13','1981-04-24 20:48:04'),
('14','14','14','1995-02-20 19:31:34'),
('15','15','15','2020-04-19 02:23:11'),
('16','16','16','2006-06-21 02:07:18'),
('17','17','17','2005-04-04 00:16:50'),
('18','18','18','1971-12-03 01:50:46'),
('19','19','19','2001-10-23 13:07:31'),
('20','20','20','2007-12-12 05:19:15'),
('21','21','21','2019-03-17 11:18:34'),
('22','22','22','1993-06-19 06:36:18'),
('23','23','23','2015-10-31 20:34:59'),
('24','24','24','2020-03-28 08:12:55'),
('25','25','25','2006-04-18 07:56:30'),
('26','26','26','2002-07-13 02:28:27'),
('27','27','27','1984-09-08 17:32:02'),
('28','28','28','2008-11-06 16:24:01'),
('29','29','29','1991-05-31 00:54:32'),
('30','30','30','1970-08-11 17:26:54'),
('31','31','31','1993-06-10 22:49:30'),
('32','32','32','2015-07-04 09:50:28'),
('33','33','33','1991-04-23 15:54:57'),
('34','34','34','2016-12-24 08:44:49'),
('35','35','35','1994-11-05 14:32:38'),
('36','36','36','1979-11-27 02:10:56'),
('37','37','37','1998-07-08 11:34:40'),
('38','38','38','2004-07-21 00:45:18'),
('39','39','39','1977-02-23 20:57:22'),
('40','40','40','1979-02-06 09:31:32'),
('41','41','41','2012-02-28 05:38:00'),
('42','42','42','1990-02-03 06:13:40'),
('43','43','43','1993-12-09 05:20:24'),
('44','44','44','1980-11-08 23:54:25'),
('45','45','45','2009-12-13 16:10:19'),
('46','46','46','2008-07-08 15:34:12'),
('47','47','47','1978-07-03 00:37:01'),
('48','48','48','1974-05-01 16:22:08'),
('49','49','49','1987-11-07 23:25:36'),
('50','50','50','1977-03-15 16:41:35'); 


INSERT INTO `photos` VALUES ('1','1','1'),
('2','2','2'),
('3','3','3'),
('4','4','4'),
('5','5','5'),
('6','6','6'),
('7','7','7'),
('8','8','8'),
('9','9','9'),
('10','10','10'),
('11','11','11'),
('12','12','12'),
('13','13','13'),
('14','14','14'),
('15','15','15'),
('16','16','16'),
('17','17','17'),
('18','18','18'),
('19','19','19'),
('20','20','20'),
('21','21','21'),
('22','22','22'),
('23','23','23'),
('24','24','24'),
('25','25','25'),
('26','26','26'),
('27','27','27'),
('28','28','28'),
('29','29','29'),
('30','30','30'),
('31','31','31'),
('32','32','32'),
('33','33','33'),
('34','34','34'),
('35','35','35'),
('36','36','36'),
('37','37','37'),
('38','38','38'),
('39','39','39'),
('40','40','40'),
('41','41','41'),
('42','42','42'),
('43','43','43'),
('44','44','44'),
('45','45','45'),
('46','46','46'),
('47','47','47'),
('48','48','48'),
('49','49','49'),
('50','50','50');

INSERT INTO `profiles` VALUES ('1','M','2020-12-07','1','1971-12-22 13:38:45','East Rachelleburgh',1),
('2','M','1997-05-11','2','2018-10-04 06:14:10','Port Juana', 1),
('3','M','1975-07-19','3','2005-08-19 17:28:12','Daytonview',1),
('4','M','2000-04-08','4','2001-01-29 12:16:48','Port Rachel',1),
('5','M','1985-07-04','5','1974-06-26 01:38:26','Runteside',1),
('6','M','2010-10-15','6','1970-09-25 10:21:49','Brownshire',1),
('7','M','1998-08-02','7','1985-06-26 18:39:54','Dallasburgh',1),
('8','M','2010-03-16','8','1986-06-22 22:46:01','Port Rashawn',1),
('9','M','1974-03-28','9','1987-05-20 07:38:41','Yoshikoberg',1),
('10','M','1987-07-03','10','2014-05-07 06:50:27','Lincolnville',1),
('11','M','2001-11-14','11','2014-04-14 04:23:36','East Sheldon',1),
('12','M','2008-05-07','12','1974-04-04 19:59:52','North Simeonchester',1),
('13','M','1976-03-15','13','2014-06-25 01:15:50','North Kamrynport',1),
('14','W','1996-07-23','14','2009-07-21 14:01:27','Wildermanburgh',1),
('15','M','2016-02-04','15','1995-05-15 08:12:23','West Dayne',1),
('16','M','2018-03-25','16','1983-07-06 23:31:30','Zboncakton',1),
('17','M','1998-06-13','17','1973-08-08 11:01:59','North Moshe',1),
('18','M','2009-03-16','18','1970-02-18 22:47:22','Herminiachester',1),
('19','M','1986-05-16','19','2015-11-05 12:10:11','Klingfort',1),
('20','M','2004-07-17','20','2003-03-18 21:50:33','Kautzerport',1),
('21','M','2014-07-01','21','1984-11-28 12:36:54','Neilmouth',1),
('22','M','2007-03-30','22','1974-03-25 15:20:56','Kshlerinville',1),
('23','M','2004-11-05','23','1982-06-02 14:31:48','New Golden',1),
('24','M','2005-02-23','24','1984-01-20 07:47:49','South Mafaldafort',1),
('25','M','1998-10-05','25','1978-01-31 08:21:51','Katherynton',1),
('26','M','2020-09-12','26','1988-05-06 10:15:40','Port Leann',1),
('27','M','1971-07-30','27','2018-09-27 04:32:01','Lake Wilfredo',1),
('28','W','1987-06-14','28','1993-03-09 06:10:00','South Timmothyhaven',1),
('29','M','1972-01-14','29','1988-05-09 04:42:35','Maximillianborough',1),
('30','M','2011-06-30','30','1991-03-08 18:06:48','Lake Alexa',1),
('31','M','2011-05-21','31','2010-11-02 07:21:05','Lake Victor',1),
('32','M','1971-01-23','32','1990-08-06 16:11:11','Grayceborough',1),
('33','M','1971-04-25','33','1996-06-13 17:51:40','North Melvin',1),
('34','M','1992-10-14','34','2012-07-18 15:57:29','Shaunmouth',1),
('35','M','2009-06-28','35','1971-03-26 21:20:30','New Denishaven',1),
('36','M','1987-11-01','36','1987-07-01 23:43:56','South Demetriston',1),
('37','M','1989-02-16','37','1977-09-01 03:38:58','Port Modesta',1),
('38','M','1998-05-05','38','2013-05-18 19:22:05','New Howellfurt',1),
('39','M','2020-08-25','39','1989-02-08 17:16:11','West Ryley',1),
('40','M','1987-06-01','40','2007-04-12 17:47:00','South Carmela',1),
('41','M','2008-08-12','41','1982-02-28 23:07:36','Connorland',1),
('42','M','1998-07-27','42','2010-01-30 18:58:09','New Noemie',1),
('43','M','1981-09-14','43','1974-01-27 06:28:53','Akeemborough',1),
('44','M','1992-08-28','44','1989-12-31 15:46:52','North Preciousshire',1),
('45','M','1976-03-24','45','1977-07-22 08:42:39','Lake Camylle',1),
('46','M','1983-02-24','46','2019-10-10 19:06:54','New Enid',1),
('47','M','1992-12-07','47','1971-01-07 00:54:51','Wymanton',1),
('48','W','1990-07-26','48','1972-03-01 00:49:30','Veronicaton',1),
('49','W','1974-01-08','49','1980-02-18 07:45:28','Schoenfort',1),
('50','W','2006-11-19','50','1972-04-10 03:14:07','New Emilie',1);

INSERT INTO `users_communities` VALUES ('1','1'),
('2','2'),
('3','3'),
('4','4'),
('5','5'),
('6','6'),
('7','7'),
('8','8'),
('9','9'),
('10','10'),
('11','11'),
('12','12'),
('13','13'),
('14','14'),
('15','15'),
('16','16'),
('17','17'),
('18','18'),
('19','19'),
('20','20'),
('21','21'),
('22','22'),
('23','23'),
('24','24'),
('25','25'),
('26','26'),
('27','27'),
('28','28'),
('29','29'),
('30','30'),
('31','31'),
('32','32'),
('33','33'),
('34','34'),
('35','35'),
('36','36'),
('37','37'),
('38','38'),
('39','39'),
('40','40'),
('41','41'),
('42','42'),
('43','43'),
('44','44'),
('45','45'),
('46','46'),
('47','47'),
('48','48'),
('49','49'),
('50','50');

/*Задание 1.
 Пусть задан некоторый пользователь. 
 Из всех пользователей соц. сети найдите человека, 
 который больше всех общался с выбранным пользователем (написал ему сообщений).
*/

set @user_id = 1;
SELECT from_user_id, max(counts) as max_counts
FROM (
	SELECT from_user_id, to_user_id, count(*) AS counts
	FROM messages
	WHERE to_user_id = @user_id
	GROUP BY from_user_id) as t;
	
/*Задание 2.
 Подсчитать общее количество лайков, которые получили пользователи младше 10 лет.
*/

select count(*) as counts
from likes
where media_id in (
	select id 
	from media 
	where user_id in (
		select user_id
		from profiles
		where TIMESTAMPDIFF(year, birthday, now()) < 10));
	
/*Задание 3.
 Определить кто больше поставил лайков (всего): мужчины или женщины.
*/		
	
select max(counts) as counts, gender
from (
	select count(*) as counts, 'Man' as gender
	from likes
	where user_id in (
		select user_id
		from profiles
		where gender = 'M')
	union	
	select count(*) as counts, 'Woman' as gender
	from likes
	where user_id in (
		select user_id
		from profiles
		where gender = 'W')) as t;