
-- NIVELL 1
-- Ejercicio 1 - A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules. 
-- Mostra les característiques principals de l'esquema creat i explica les diferents taules i variables que existeixen. 
-- Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

	-- Creamos la base de datos
    CREATE DATABASE IF NOT EXISTS transactions;
    USE transactions;

	-- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );

	-- Creamos la tabla transaction
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(20), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );
    
	-- En este punto ejecutamos el archivo dades_introduir.sql para cargar los datos en las tablas.
    
-- Ejercicio 2.1 - Llistat dels països que estan generant vendes
    
SELECT DISTINCT c.country AS Países_Con_Ventas FROM company AS c
INNER JOIN transaction AS t ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY t.company_id
;

    
-- Ejercicio 2.2 - Des de quants països es generen les vendes.

SELECT COUNT(DISTINCT c.country) AS Número_Países_Con_Ventas FROM company AS c
INNER JOIN transaction AS t ON c.id = t.company_id
WHERE t.declined = 0
;

-- Ejercicio 2.3 - Identifica la companyia amb la mitjana més gran de vendes.

SELECT c.company_name AS País_Con_Mayor_Media_Ventas FROM company AS c
INNER JOIN transaction AS t ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.company_name
ORDER BY ROUND(AVG(t.amount),2) DESC
LIMIT 1
;

-- Ejercicio 3.1 - Mostra totes les transaccions realitzades per empreses d'Alemanya.
	-- No incluimos la condición t.delined = 0, porque el enunciado establece "todas las transacciones".

SELECT * FROM transaction AS t
WHERE EXISTS (
	SELECT c.id FROM company AS c
	WHERE t.company_id = c.id AND c.country = "Germany"
			)
;

-- Ejercicio 3.2 - Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.

SELECT DISTINCT c.company_name FROM company AS c
WHERE EXISTS (
	SELECT t.company_id FROM transaction AS t 
	WHERE c.id = t.company_id AND t.amount > (SELECT AVG(t2.amount) FROM transaction AS t2) AND t.declined = 0
			)
ORDER BY c.company_name
;

-- Ejercicio 3.3 - Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.

SELECT c.company_name FROM company AS c
WHERE NOT EXISTS (
					SELECT DISTINCT t.company_id FROM transaction AS t
                    )
;

-- Ejercicio 4

	-- Creamos la tabla 
CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(15) PRIMARY KEY, 
    iban VARCHAR(50) UNIQUE, 
    pan VARCHAR(20), 
    pin INT(4), 
    cvv INT(4), 
    expiring_date VARCHAR(20)
    )
;

	-- En este punto ejecutamos el archivo N1-EX.4__datos_introducir_credit.sql para cargar los datos en las tablas.

	-- Cambiamos tipo de dato de fecha
UPDATE credit_card 
SET expiring_date = DATE_FORMAT(STR_TO_DATE(expiring_date, '%m/%d/%y'), '%Y-%m-%d')
;

ALTER TABLE credit_card 
MODIFY COLUMN expiring_date DATE
;

	-- Establecemos la Foreign Key.
ALTER TABLE transaction 
ADD CONSTRAINT fk_transaction_creditcard
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id)
;

-- Ejercicio 5 - El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit
-- amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. Recorda mostrar que 
-- el canvi es va realitzar.
 
UPDATE credit_card
SET iban = "TR323456312213576817699999"
WHERE id = "CcU-2938"
;

SELECT * FROM credit_card
WHERE id = "CcU-2938"
;

-- Ejercicio 6 - En la taula "transaction" ingressa una nova transacció

INSERT INTO credit_card VALUES("CcU-9999", NULL, NULL, NULL, NULL, NULL);
INSERT INTO company VALUES("b-9999", NULL, NULL, NULL, NULL, NULL);
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined)
VALUES ("108B1D1D-5B23-A76C-55EF-C568E49A99DD", "CcU-9999", "b-9999", 9999, 829.999, -117.999, NULL, 111.11, 0) 
;

-- EJERCICIO 7 - Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el 
-- canvi realitzat.

ALTER TABLE credit_card
DROP column pan
;

SELECT * FROM credit_card
;

-- Ejercicio 8 - Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules.
	-- Creamos Base de datos.
CREATE DATABASE IF NOT EXISTS S2FROMEX8
;

USE S2FROMEX8
;

	-- Creamos las tablas.
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(255) PRIMARY KEY,                       
    card_id VARCHAR(255),                               
    business_id VARCHAR(255),                          
    timestamp TIMESTAMP,                               
    amount DECIMAL(10,2),                              
    declined INT,                                   
    product_ids VARCHAR(255),                          
    user_id INT,                                       
    lat DECIMAL,                               
    longitude DECIMAL,                       
    discount_amount DECIMAL,                     
    tax_amount DECIMAL,                          
    shipping_amount DECIMAL,                    
    channel VARCHAR(255),                               
    campaign_id VARCHAR(255),                           
    device_type VARCHAR(255),                           
    is_international INT,                           
    decline_reason VARCHAR(255),                  
    distance_km DECIMAL                         
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;

CREATE TABLE IF NOT EXISTS companies (
	company_id varchar(255) PRIMARY KEY,
	company_name VARCHAR(255),
    phone VARCHAR (15),
    email VARCHAR(255),
    country VARCHAR(255),
    website VARCHAR(255),
    merchant_category VARCHAR(255),
    merchant_price_position VARCHAR(255)
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;

CREATE TABLE IF NOT EXISTS credit_cards (
	id varchar(255) PRIMARY KEY,
	user_id INT(15),
    iban VARCHAR (255),
    pan VARCHAR(255),
    pin INT(10),
    cvv INT(10),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(255),
    card_type VARCHAR(255),
    card_renewal_flag INT(2)
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;

CREATE TABLE IF NOT EXISTS american_users (
	id INT(10) PRIMARY KEY,
	name VARCHAR(255),
    surname VARCHAR (255),
    phone VARCHAR(255),
    email VARCHAR(255),
    birth_date VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    postal_code VARCHAR(255),
    address VARCHAR(255),
    signup_date VARCHAR(255),
    user_segment VARCHAR(255),
    income_band VARCHAR(255)
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__american_users.csv'
INTO TABLE american_users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;

CREATE TABLE IF NOT EXISTS european_users (
	id INT(10) PRIMARY KEY,
	name VARCHAR(255),
    surname VARCHAR (255),
    phone VARCHAR(255),
    email VARCHAR(255),
    birth_date VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    postal_code VARCHAR(255),
    address VARCHAR(255),
    signup_date VARCHAR(255),
    user_segment VARCHAR(255),
    income_band VARCHAR(255)
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__european_users.csv'
INTO TABLE european_users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;

	-- Creamos tabla users y fusionamos usuarios americans y europeans. Eliminamos las 2 tablas iniciales.

CREATE TABLE IF NOT EXISTS users AS
	SELECT * FROM american_users
	UNION ALL
	SELECT * FROM european_users;
    
DROP TABLE american_users;

DROP TABLE european_users;
;

	-- Añadimos la PRIMARY KEY de users.

ALTER TABLE users ADD PRIMARY KEY (id)
;

	-- Establecemos relaciones añadiendo FOREIGN KEYS.

ALTER TABLE transactions 
ADD CONSTRAINT fk_transactions_companies 
FOREIGN KEY (business_id) REFERENCES companies(company_id),
ADD CONSTRAINT fk_transactions_credit_cards
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
ADD CONSTRAINT fk_transactions_users
FOREIGN KEY (user_id) REFERENCES users(id)
;

-- Ejercicio 9 - Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
	-- No incluyo la condición t.declined = 0, ya que pueden ser necesarias para la suma de transacciones, según el propósito.

SELECT * FROM users AS u
WHERE EXISTS (
	SELECT t.user_id FROM transactions AS t
    WHERE u.id = t.user_id
	GROUP BY t.user_id
	HAVING COUNT(t.user_id) > 80
    )
;

-- Ejercicio 10 - Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.

SELECT cc.iban AS Tarjeta, ROUND(AVG(t.amount),2) AS mediaGasto FROM transactions AS t
INNER JOIN credit_cards AS cc ON t.card_id = cc.id
INNER JOIN companies AS c ON t.business_id = c.company_id
WHERE c.company_name = "Donec Ltd" AND t.declined = 0
GROUP BY cc.iban
ORDER BY mediaGasto DESC
;

-- NIVELL 2
-- Ejercicio 1 - Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. Mostra la
-- data de cada transacció juntament amb el total de les vendes.

SELECT DATE(t.timestamp) AS Fecha, ROUND(SUM(t.amount),2) AS total FROM transactions AS t
WHERE t.declined = 0
GROUP BY DATE(t.timestamp)
ORDER BY total DESC
LIMIT 5
;

-- Ejercicio 2 - Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un
-- valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de
-- març del 2024. Ordena els resultats de major a menor quantitat.

SELECT c.company_name AS Empresa, c.phone AS Teléfono, c.country AS País, DATE(t.timestamp) AS Fecha, t.amount AS Importe FROM transactions AS t
INNER JOIN companies AS c ON t.business_id = c.company_id
WHERE DATE(t.timestamp) IN (
							"2015-04-29",
                            "2018-07-20",
                            "2024-03-13"
                            )
						AND t.amount BETWEEN "350" AND "400" AND t.declined = 0
GROUP BY c.company_name, c.phone, c.country, DATE(t.timestamp), t.amount
ORDER BY t.amount DESC
;

-- Ejercicio 3 - Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la
-- qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, però el departament de recursos
-- humans és exigent i vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.
	-- No incluyo la condición t.declined = 0, porque no sabemos si la empresa quiere analizar parámetros que no sean conversión.

SELECT c.company_name AS Empresa,
	CASE 
		WHEN COUNT(t.id) >= 400 THEN "Es mayor o igual a 400"
		ELSE "Es menor que 400"
	END AS mayor_o_menor_de_400
FROM companies AS c
INNER JOIN transactions AS t ON c.company_id = t.business_id
GROUP BY c.company_name
ORDER BY mayor_o_menor_de_400 DESC
;

-- Ejercicio 4 - Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

DELETE FROM transactions AS t
WHERE t.id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD"
;

-- Ejercicio 5 - La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives.
-- S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. Serà necessària que
-- creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. Telèfon de contacte. País de
-- residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, ordenant les dades de major a menor
-- mitjana de compra.

CREATE VIEW VistaMarketing AS
SELECT c.company_name AS Empresa, c.phone AS Teléfono, c.country AS País, ROUND(AVG(t.amount),2) AS MediaCompras
FROM companies AS c
INNER JOIN transactions AS t ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_name,c.phone, c.country
ORDER BY MediaCompras DESC
;

-- NIVELL 3
-- Ejercicio 1 - Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions 
-- han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. 

CREATE TABLE cc_status AS
SELECT 
    card_id,
    CASE 
        WHEN SUM(declined) = 3 THEN 'Inactivo'
        ELSE 'Activo'
    END AS card_status
FROM (
    SELECT 
        card_id,
        declined,
        ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS comprueba_registros
    FROM transactions
) AS comprueba_transacciones
WHERE comprueba_registros < 4
GROUP BY card_id
;

SELECT COUNT(*) FROM cc_status
WHERE card_status = "Activo"
;

-- Ejercicio 2 - Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, tenint
-- en compte que des de transaction tens product_ids. Genera la següent consulta:
-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

	-- Creamos tabla según el tipo de dato visto al abrir el archivo.

CREATE TABLE IF NOT EXISTS products (
    id INT,
    product_name VARCHAR(255),
    price VARCHAR(255),
    colour VARCHAR(255),
    weight VARCHAR(255),
    warehouse_id VARCHAR(255),
    category VARCHAR(255),
    brand VARCHAR(255),
    cost VARCHAR(255),
    launch_date DATE
);

	-- Cargamos datos.

LOAD DATA LOCAL INFILE '/Users/raypro16/Desktop/Barcelona Activa/Bootcamp Análisis de datos/Especialización/Database/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
;
	-- Hacemos la consulta teniendo en cuenta que hay más de un id en "product_ids" de "trnasactions", por lo que usamos la función FIND_IN_SET.

SELECT p.id AS ID_Producto, p.product_name AS Producto, COUNT(t.id) AS Veces_Vendido 
FROM products AS p 
LEFT JOIN transactions AS t ON FIND_IN_SET(p.id, REPLACE(t.product_ids, ' ', '')) > 0
JOIN credit_cards AS cc ON t.card_id = cc.id
WHERE cc.card_type = "credit" AND t.declined = 0
GROUP BY p.id, p.product_name
ORDER BY Veces_Vendido DESC
;


