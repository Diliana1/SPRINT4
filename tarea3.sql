#NIVEL 1
# CREAR UNA BASE DE DATOS 
use spring4;
create table company(
company_id	VARCHAR (30) PRIMARY KEY,
company_name	VARCHAR (30),
phone	VARCHAR (15),
email	VARCHAR (50),
country	VARCHAR (100),
website	VARCHAR (100));

#CAMBIE EL NOMBRE DE LA TABLA LO HABIA ESCRITO MAL

use spring4;
ALTER TABLE company RENAME TO companies;


 # cargando la data, tuve problemas con el campo company_name y debi cambiar el tamaño

LOAD DATA INFILE 'C:\\ProgramData\\test\\Uploads\\companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

ALTER TABLE companies MODIFY COLUMN company_name VARCHAR(100);
select *
from spring4.companies;

# creando la tabla credi_cards

create table credit_card(
id varchar(20),
user_id varchar(100),
iban varchar(50),
pan varchar(100),
pin varchar(100),
cvv varchar(100),
track1 varchar(100),
track2 varchar(100),
expiring_date varchar(100));


ALTER TABLE credit_card RENAME TO credit_cards;

# introduciendo valores

LOAD DATA INFILE 'C:\\ProgramData\\test\\Uploads\\credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

select *
from spring4.credit_cards;

#creando tabla USERS
use spring4;
create table users (
id VARCHAR (100) PRIMARY KEY,
name varchar (100),
surname varchar (100),
phone varchar (100),
email varchar (100),
birth_date varchar (100),
country varchar (100),
city varchar (100),
postal_code varchar (100),
address varchar (100));


-- Insertar datos combinados de user1, user2, y user3 en users

INSERT INTO users (id,name, surname,phone,email,birth_date,country,city,postal_code,address)
SELECT id,name, surname,phone,email,birth_date,country,city,postal_code,address FROM users_ca
UNION ALL
SELECT id,name, surname,phone,email,birth_date,country,city,postal_code,address FROM users_uk
UNION ALL
SELECT id,name, surname,phone,email,birth_date,country,city,postal_code,address from users_usa;

use spring4;
select *
from companies;


# creando tabla transaccion id	card_id	business_id	timestamp	amount	declined	product_ids	user_id	lat	longitude
create table transactions (
id varchar(100),
card_id varchar(100),
business_id varchar(100),
timestamp varchar(100),
amount varchar(100),
declined varchar(100),
product_ids varchar(100),
user_id varchar(100),
lat varchar(100),
longitude varchar(100));

LOAD DATA INFILE 'C:\\ProgramData\\test\\Uploads\\transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'   -- En este caso los campos estan separados por ";" y no por ","
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# creando tabla producto
#id,product_name,price,colour,weight,warehouse_id

create table products (
id varchar(100) primary key,
product_name varchar(100),
price varchar(100),
colour varchar(100),
weigt varchar(100),
warehouse_id varchar(100));

ALTER TABLE products CHANGE weigt weight varchar(100);

# elimine las tablas que no necesito
DROP TABLE users_usa;
DROP TABLE users_uk;
DROP TABLE users_ca;
# agregue su clave primaria
ALTER TABLE transactions
ADD PRIMARY KEY (id);

# debo realizar la conexion entre las tablas
alter table transactions
add constraint fk_credit_cards
foreign key (card_id)
references credit_cards(id);
 
alter table transactions
add constraint fk_users
foreign key (user_id)
references users(id);

alter table transactions
add constraint fk_companies
foreign key (business_id)
references companies(company_id);


#EJERCICIO 1
#MOSTRAR TODOS LOS USUARIOS CON MAS DE 30 TRANSACCIONES
SELECT users.id, users.name, users.surname, count(transactions.id) as cont
FROM USERS
join transactions on transactions.user_id= users.id
group by 1,2,3
having cont> 30;


select *
from transactions;


#EJERCICIO 2
#Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., utiliza por lo menos 2 tablas.

select  company_name, credit_cards.iban, round(avg(amount),2) as media
from transactions
join credit_cards on transactions.card_id = credit_cards.id
join companies on transactions.business_id =  companies.company_id
where companies.company_name = 'Donec Ltd'
group by credit_cards.iban;

#NIVEL 2
#Crea una nueva tabla que refleje el estado de las tarjetas de crédito basado en si las últimas tres transacciones fueron declinadas 
#y genera la siguiente consulta:
# EJERCICIO 1

select *
from transactions;



CREATE TABLE card_status AS
SELECT
    card_id,
    CASE
        WHEN COUNT(*) < 3 THEN 'Activa'
        WHEN SUM(declined) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS status
FROM (
    SELECT card_id, declined,
        ROW_NUMBER() OVER(PARTITION BY card_id ORDER BY timestamp DESC) AS Rank_Transaccion
    FROM transactions
) AS Transacciones
WHERE Rank_Transaccion <= 3
GROUP BY card_id;

CREATE INDEX idx_card_id ON transactions(card_id);
ALTER TABLE card_status
ADD INDEX idx_card_id (card_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_card_id
FOREIGN KEY (card_id)
REFERENCES card_status(card_id);


 #Ejercicio 1
#¿Cuántas tarjetas están activas?
SELECT * FROM card_status;

SELECT count(card_id)
FROM card_status
WHERE status = "Activa";
 
#NIVEL 3
#Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con la base de datos creada,
# teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta:

CREATE TABLE inter_products 
select id, product_ids
from transactions;

-- Desglosar los PRODUCT_IDs y insertar en productos_desglosados

CREATE TABLE productos_desglosados (
    id VARCHAR(255),
    product_id INT
);


-- Desglosar los PRODUCT_IDs y luego insertar en productos_desglosados
INSERT INTO productos_desglosados (ID, PRODUCT_ID)
SELECT 
    ID,
    CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(inter_products.product_ids, ',', numbers.n), ',', -1)) AS UNSIGNED) AS PRODUCT_IDS
FROM
    inter_products
JOIN
    (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) AS numbers
    ON CHAR_LENGTH(inter_products.product_ids) - CHAR_LENGTH(REPLACE(inter_products.product_ids, ',', '')) >= numbers.n - 1;
    
    
select *
from productos_desglosados;
 # VAMOS A REALIZAR LAS PK Y FK
 
 alter table products  modify column id int;
 
ALTER TABLE productos_desglosados
ADD PRIMARY KEY(id,product_id),
ADD FOREIGN KEY (id) REFERENCES transactions(id),
ADD FOREIGN KEY (product_id) REFERENCES products(id); 


#Necesitamos conocer el número de veces que se ha vendido cada producto.

 SELECT COUNT(*) FROM products;

SELECT  products.id, products.product_name, COUNT(productos_desglosados.product_id) AS product_count
FROM products
LEFT JOIN productos_desglosados ON products.id = productos_desglosados.product_id
GROUP BY products.id, products.product_name
ORDER BY product_count DESC;


