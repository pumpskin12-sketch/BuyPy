DROP DATABASE IF EXISTS BuyPy;
CREATE DATABASE BuyPy;
USE BuyPy;

DROP TABLE IF EXISTS Operator;
CREATE TABLE Operator (
id 				INT AUTO_INCREMENT PRIMARY KEY,
firstname 		VARCHAR(250) NOT NULL,
surname 		VARCHAR(250) NOT NULL,
email 			VARCHAR(50) NOT NULL UNIQUE,
`password` 		VARCHAR(250) NOT NULL,
CONSTRAINT Operator_Email_CHK CHECK (
	email REGEXP '^[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
    )
);

DROP TABLE IF EXISTS `Client`;
CREATE TABLE `Client` (
id 					INT AUTO_INCREMENT PRIMARY KEY,
firstname 			VARCHAR(250) NOT NULL,
surname 			VARCHAR(250) NOT NULL,
email 				VARCHAR(50) NOT NULL UNIQUE,
`password` 			VARCHAR(250) NOT NULL,
address 			VARCHAR(100) NOT NULL,
zip_code 			SMALLINT NOT NULL,
city 				VARCHAR(30) NOT NULL,
country 			VARCHAR(30) NOT NULL DEFAULT 'Portugal',
phone_number 		VARCHAR(15) NOT NULL,
last_login 			TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
birthdate 			DATE NOT NULL,
is_active 			BOOLEAN NOT NULL DEFAULT TRUE,
CONSTRAINT Client_Email_CHK CHECK (
	email REGEXP '^[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
    ),
CONSTRAINT Client_Phone_CHK CHECK (
	phone_number REGEXP '^[0-9]{6,15}$'
    )
);

DROP TABLE IF EXISTS `Order`;
CREATE TABLE `Order` (
id 						INT AUTO_INCREMENT PRIMARY KEY,
date_time 				DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
delivery_method 		VARCHAR(10) NOT NULL DEFAULT 'regular',
`status` 				VARCHAR(10) NOT NULL DEFAULT 'open',
payment_card_number 	BIGINT NOT NULL,
payment_card_name 		VARCHAR(20) NOT NULL,
payment_card_expiration DATE NOT NULL,
client_id 				INT NOT NULL,
CONSTRAINT Order_Client_FK FOREIGN KEY (client_id) REFERENCES Client(id) ON UPDATE CASCADE,
CONSTRAINT Order_Delivery_CHK CHECK (delivery_method IN ('regular', 'urgent')),
CONSTRAINT Order_Status_CHK CHECK (`status` IN ('open', 'processing', 'pending', 'closed', 'cancelled'))
);

DROP TABLE IF EXISTS Product;
CREATE TABLE Product (
id 				VARCHAR(10) PRIMARY KEY,
quantity 		INT NOT NULL CHECK (quantity >= 0),
price 			DECIMAL(10,2) NOT NULL CHECK (price >= 0),
vat 			DECIMAL(5,2) NOT NULL CHECK (vat BETWEEN 0 AND 100),
score 			INT CHECK (score BETWEEN 1 AND 5),
product_image 	VARCHAR(255) NOT NULL,
is_active 		BOOLEAN NOT NULL DEFAULT TRUE,
reason 			TEXT
);

DROP TABLE IF EXISTS Electronic;
CREATE TABLE Electronic (
product_id 		VARCHAR(10) PRIMARY KEY,
serial_num 		BIGINT NOT NULL UNIQUE,
brand 			VARCHAR(20) NOT NULL,
model 			VARCHAR(20) NOT NULL,
spec_tec 		TEXT,
`type` 			VARCHAR(10) NOT NULL,
CONSTRAINT Electronic_Product_FK FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Book;
CREATE TABLE Book (
product_id 			VARCHAR(10) PRIMARY KEY,
isbn13 				VARCHAR(20) NOT NULL UNIQUE,
title 				VARCHAR(50) NOT NULL,
genre 				VARCHAR(50) NOT NULL,
publisher 			VARCHAR(100) NOT NULL,
publication_date 	DATE NOT NULL,
CONSTRAINT Book_Product_FK FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT Book_ISBN_CHK CHECK (
	isbn13 REGEXP '^[A-Z0-9-]+$' AND 
	NOT (isbn13 LIKE '-%' OR isbn13 LIKE '%-')
    )
);

DROP TABLE IF EXISTS Author;
CREATE TABLE Author (
id 			INT AUTO_INCREMENT PRIMARY KEY,
`name` 		VARCHAR(100) NOT NULL,
fullname 	VARCHAR(100) NOT NULL,
birthdate 	DATE NOT NULL
);

DROP TABLE IF EXISTS BookAuthor;
CREATE TABLE BookAuthor (
product_id 		VARCHAR(10) NOT NULL,
author_id 		INT NOT NULL,
PRIMARY KEY (product_id, author_id),
CONSTRAINT BookAuthor_Book_FK FOREIGN KEY (product_id) REFERENCES Book(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT BookAuthor_Author_FK FOREIGN KEY (author_id) REFERENCES Author(id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Recommendation;
CREATE TABLE Recommendation (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reason VARCHAR(500) NOT NULL,
    start_date DATE NOT NULL,
    client_id INT NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    CONSTRAINT Rec_Client_FK FOREIGN KEY (client_id) REFERENCES Client(id) ON UPDATE CASCADE,
    CONSTRAINT Rec_Product_FK FOREIGN KEY (product_id) REFERENCES Product(id) ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Ordered_Item;
CREATE TABLE Ordered_Item (
    order_id INT NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    vat_amount DECIMAL(10,2) NOT NULL CHECK (vat_amount >= 0),
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT Item_Order_FK FOREIGN KEY (order_id) REFERENCES `Order`(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Item_Product_FK FOREIGN KEY (product_id) REFERENCES Product(id) ON UPDATE CASCADE
);

DELIMITER //

CREATE TRIGGER trg_Client_Password_Insert
BEFORE INSERT ON Client
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.password) < 6 
       OR NEW.password NOT REGEXP '[a-z]' 
       OR NEW.password NOT REGEXP '[A-Z]' 
       OR NEW.password NOT REGEXP '[0-9]' 
       OR NEW.password NOT REGEXP '[!$#?%]' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Password deve ter 6+ carateres, 1 maiúscula, 1 minúscula, 1 dígito e 1 símbolo (!,$,#,?,%).';
    END IF;
    SET NEW.password = SHA2(NEW.password, 256);
END //


CREATE TRIGGER trg_Product_Inactivation_Check
BEFORE UPDATE ON Product
FOR EACH ROW
BEGIN
    IF OLD.is_active = TRUE AND NEW.is_active = FALSE THEN
        IF NEW.reason IS NULL OR NEW.reason = '' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Erro: É obrigatório definir uma razão descritiva para inativar o produto.';
        END IF;
    ELSEIF NEW.is_active = TRUE THEN
        SET NEW.reason = NULL;
    END IF;
END //


CREATE PROCEDURE ProductByType(IN param_tipo VARCHAR(20))
BEGIN
    SELECT 
        p.id AS codigo_produto,
        p.price AS preco,
        p.score AS pontuacao,
        IF(r.product_id IS NOT NULL, 'Sim', 'Não') AS recomendado,
        IF(p.is_active, 'Activo', 'Inactivo') AS estado,
        p.product_image AS ficheiro,
        CASE 
            WHEN b.product_id IS NOT NULL THEN 'Livro'
            WHEN e.product_id IS NOT NULL THEN 'Electronica'
            ELSE 'Desconhecido'
        END AS tipo_produto
    FROM Product p
    LEFT JOIN Book b ON p.id = b.product_id
    LEFT JOIN Electronic e ON p.id = e.product_id
    LEFT JOIN (SELECT DISTINCT product_id FROM Recommendation) r ON p.id = r.product_id
    WHERE param_tipo IS NULL 
       OR (param_tipo = 'Livro' AND b.product_id IS NOT NULL)
       OR (param_tipo = 'Electronica' AND e.product_id IS NOT NULL);
END //

CREATE PROCEDURE DailyOrders(IN param_data DATE)
BEGIN
    SELECT id, date_time, delivery_method, `status`, client_id 
    FROM `Order`
    WHERE DATE(date_time) = param_data;
END //

CREATE PROCEDURE AnnualOrders(IN param_client_id INT, IN param_ano INT)
BEGIN
    SELECT id, date_time, delivery_method, `status` 
    FROM `Order`
    WHERE client_id = param_client_id 
      AND YEAR(date_time) = param_ano;
END //

CREATE PROCEDURE CreateOrder(
    IN param_client_id INT, IN param_metodo VARCHAR(10),
    IN param_num_cartao BIGINT, IN param_nome_cartao VARCHAR(20), IN param_validade DATE
)
BEGIN
    INSERT INTO `Order` (client_id, delivery_method, payment_card_number, payment_card_name, payment_card_expiration, `status`)
    VALUES (param_client_id, param_metodo, param_num_cartao, param_nome_cartao, param_validade, 'open');
END //

CREATE PROCEDURE GetOrderTotal(IN param_order_id INT, OUT total_montante DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM((price * quantity) + vat_amount), 0.00) INTO total_montante
    FROM Ordered_Item
    WHERE order_id = param_order_id;
END //

CREATE PROCEDURE AddProductToOrder(IN param_order_id INT, IN param_product_id VARCHAR(10), IN param_qtd INT)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_vat_pct DECIMAL(5,2);
    DECLARE v_vat_amount DECIMAL(10,2);
    
    SELECT price, vat INTO v_price, v_vat_pct FROM Product WHERE id = param_product_id;
    SET v_vat_amount = (v_price * (v_vat_pct / 100)) * param_qtd;
    
    INSERT INTO Ordered_Item (order_id, product_id, quantity, price, vat_amount)
    VALUES (param_order_id, param_product_id, param_qtd, v_price, v_vat_amount);
END //

DELIMITER ;
