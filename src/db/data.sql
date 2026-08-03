USE BuyPy;

INSERT INTO Operator (firstname, surname, email, `password`) VALUES 
('Mariana', 'Silva', 'mariana.silva@buypy.pt', 'Mariana123!'),
('Jorge', 'Santos', 'jorge.santos@buypy.pt', 'JorgeSecure#');

INSERT INTO `Client`(firstname, surname, email, `password`, address, zip_code, city, phone_number, birthdate, is_active) VALUES 
('António', 'Américo', 'antonio@mail.com', 'Antonio123#', 'Rua das Flores, 45', 8200, 'Albufeira', '912345678', '1995-04-12', TRUE),
('Beatriz', 'Bastos', 'beatriz@mail.com', 'Beatriz456$', 'Av. Central, 102', 4700, 'Braga', '923456789', '1998-09-21', TRUE),
('Catarina', 'Costa', 'catarina.costa@mail.com', 'Catarina789?', 'Largo do Rossio, 8', 3000, 'Coimbra', '934567890', '1992-11-05', FALSE),
('Pedro', 'Pacheco', 'pedro.pacheco@mail.com', 'Pedro111%', 'Rua Direita, 14', 4700, 'Braga', '965432109', '2001-02-28', TRUE);


INSERT INTO Author (name, fullname, birthdate) VALUES
('Eça de Queirós', 'José Maria de Eça de Queirós', '1845-11-25'),
('José Saramago', 'José de Sousa Saramago', '1922-11-16');

INSERT INTO Product (id, quantity, price, vat, score, product_image, is_active) VALUES 
('PROD001', 120, 18.50, 6.00, 5, 'imagens/maias.jpg', TRUE),
('PROD002', 45, 22.00, 6.00, 4, 'imagens/convento.jpg', TRUE),
('PROD003', 25, 79.99, 23.00, 4, 'imagens/mp3.jpg', TRUE),
('PROD004', 12, 599.00, 23.00, 5, 'imagens/tv4k.jpg', TRUE);


INSERT INTO Book (product_id, isbn13, title, genre, publisher, publication_date) VALUES 
('PROD001', '978-972-004-900-0', 'Os Maias', 'Romance', 'Porto Editora', '1888-01-01'),
('PROD002', '978-989-660-001-2', 'Memorial do Convento', 'Histórico', 'Caminho', '1982-10-01');

INSERT INTO Electronic (product_id, serial_num, brand, model, spec_tec, `type`) VALUES 
('PROD003', 887261543, 'Sony', 'Walkman E', '8GB, Bluetooth, Ecrã 1.77', 'Leitor'),
('PROD004', 991827364, 'Samsung', 'Crystal UHD', '55 polegadas, Smart TV, HDR', 'Televisão');


INSERT INTO BookAuthor (product_id, author_id) VALUES
('PROD001', 1),
('PROD002', 2);

INSERT INTO Recommendation (reason, start_date, client_id, product_id) VALUES 
('Campanha de Clássicos da Literatura Portuguesa', '2026-07-26', 1, 'PROD001'),
('Sugestão com base em preferências de Tecnologia UHD', '2026-07-26', 2, 'PROD004');

CALL CreateOrder(1, 'regular', 4532112233445566, 'António Américo', '2031-01-01');
CALL AddProductToOrder(1, 'PROD001', 2);
CALL AddProductToOrder(1, 'PROD003', 1);

CALL CreateOrder(2, 'urgent', 4912665544332211, 'Beatriz Bastos', '2029-06-01');
CALL AddProductToOrder(2, 'PROD004', 1);