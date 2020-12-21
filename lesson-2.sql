/*Задача 1.
 Установите СУБД MySQL. 
 Создайте в домашней директории файл .my.cnf, 
 задав в нем логин и пароль, 
 который указывался при установке.

Я установил СУБД MySQL. 
Я дописал в сгенерированный автоматисеки конфигурационный файл в разделе [client]:
user=root
password=***********
Мой путь файла: C:\ProgramData\MySQL\MySQL Server 8.0\my.ini
Можно прописать 2 команды в консоли чтобы приступить к работе:
cd C:\Program Files\MySQL\MySQL Server 8.0\bin
mysql.exe --defaults-file="C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
Или как сделал я, скопировал сгенерированный ярлык, который ссылается на обьект:
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" "--defaults-file=C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
 */

/* Задача 2.
 Создайте базу данных example, 
 разместите в ней таблицу users, 
 состоящую из двух столбцов, 
 числового id и строкового name.
 */
drop database if exists example;
create database example;
use example;

drop table if exists users;
create table users(
	id int unsigned,
	name varchar(255) comment 'Имя'
) comment = 'Пользователи';
describe users;

/*Задача 3.
 Создайте дамп базы данных example из предыдущего задания, 
 разверните содержимое дампа в новую базу данных sample.
 */
drop database if exists sample;
create database sample;
/*
 Дальше пишу в командной строке Windows от имени администратора:
 cd C:\Program Files\MySQL\MySQL Server 8.0\bin
 mysqldump --defaults-file="C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" example > C:\Users\Константин\Desktop\example_dump.sql
 mysql --defaults-file="C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" sample < C:\Users\Константин\Desktop\example_dump.sql
 */

/*Задача 4.
  Ознакомьтесь более подробно с документацией утилиты mysqldump. 
  Создайте дамп единственной таблицы help_keyword базы данных mysql. 
  Причем добейтесь того, 
  чтобы дамп содержал только первые 100 строк таблицы.
 */
drop database if exists task_4;
create database task_4;
/*
 Дальше пишу в командной строке Windows от имени администратора:
 cd C:\Program Files\MySQL\MySQL Server 8.0\bin
 mysqldump --defaults-file="C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" --opt --where="1 limit 100" mysql help_keyword > C:\Users\Константин\Desktop\task4_dump.sql
 mysql --defaults-file="C:\ProgramData\MySQL\MySQL Server 8.0\my.ini" task_4 < C:\Users\Константин\Desktop\task4_dump.sql
 Получаю ошибку: 
 ERROR 3723 (HY000) at line 25: The table 'help_keyword' may not be created in the reserved tablespace 'mysql'.
 Пытался разобраться, не получилось.
 Поэтому вот код с эффектом аналогичным дампу:
 */
drop database if exists task_4;
create database task_4;
use task_4;
drop table if exists help_keyword;
create table help_keyword 
	select *
	from  mysql.help_keyword
	limit 100;
select *
	from help_keyword
