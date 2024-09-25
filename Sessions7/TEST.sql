CREATE DATABASE QuanLyDatPhong;
USE QuanLyDatPhong;

CREATE TABLE Category(
 Id INT PRIMARY KEY AUTO_INCREMENT,
 Name VARCHAR(100) NOT NULL UNIQUE,
 Status BIT(1) DEFAULT 1 CHECK (Status IN (0, 1))
 );
 
CREATE TABLE Room (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    Status TINYINT DEFAULT 1 CHECK (Status IN (0, 1)),
    Price FLOAT NOT NULL CHECK (Price >= 100000),
    SalePrice FLOAT DEFAULT 0,
    CHECK (SalePrice <= Price),
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CategoryId INT NOT NULL,
    INDEX (Name),
    INDEX (Price),
    INDEX (CreatedDate),
    FOREIGN KEY (CategoryId) REFERENCES Category(Id)
);

CREATE TABLE Customer (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE CHECK (Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$'),
    Phone VARCHAR(50) NOT NULL UNIQUE,
    Address VARCHAR(255),
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Gender TINYINT NOT NULL CHECK (Gender IN (0, 1, 2)),
    BirthDay DATE NOT NULL
);

DELIMITER //

CREATE TRIGGER before_insert_customer
BEFORE INSERT ON Customer
FOR EACH ROW
BEGIN
    IF NEW.CreatedDate < CURRENT_TIMESTAMP THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CreatedDate must be greater than or equal to the current date';
    END IF;
END; //

DELIMITER ;


CREATE TABLE Booking (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    CustomerId INT NOT NULL,
    Status TINYINT DEFAULT 1 CHECK (Status IN (0, 1, 2, 3)),
    BookingDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerId) REFERENCES Customer(Id)
);

CREATE TABLE BookingDetail (
    BookingId INT NOT NULL,
    RoomId INT NOT NULL,
    Price FLOAT NOT NULL,
    StartDate TIMESTAMP NOT NULL,
    EndDate TIMESTAMP NOT NULL,
    PRIMARY KEY (BookingId, RoomId),
    FOREIGN KEY (BookingId) REFERENCES Booking(Id),
    FOREIGN KEY (RoomId) REFERENCES Room(Id),
    CHECK (EndDate > StartDate)
);

INSERT INTO Category (Id, Name) VALUES
(1, 'Deluxe'),
(2, 'Standard'),
(3, 'Suite'),
(4, 'Economy'),
(5, 'VIP');

INSERT INTO Room (Name, Status, Price, SalePrice, CreatedDate, CategoryId) VALUES
('Room A', 1, 150000, 120000, current_timestamp(), 1),
('Room B', 1, 200000, 180000, current_timestamp(), 1),
('Room C', 1, 100000, 90000, current_timestamp(), 2),
('Room D', 1, 120000, 100000, current_timestamp(), 2),
('Room E', 1, 250000, 200000, current_timestamp(), 3),
('Room F', 1, 300000, 250000, current_timestamp(), 3),
('Room G', 1, 280000, 160000, current_timestamp(), 4),
('Room H', 1, 250000, 140000, current_timestamp(), 4),
('Room I', 1, 350000, 300000, current_timestamp(), 5),
('Room J', 1, 400000, 350000, current_timestamp(), 5),
('Room K', 1, 450000, 400000, current_timestamp(), 1),
('Room L', 1, 550000, 500000, current_timestamp(), 2),
('Room M', 1, 600000, 550000, current_timestamp(), 3),
('Room N', 1, 700000, 650000, current_timestamp(), 4),
('Room O', 1, 750000, 700000, current_timestamp(), 5);

INSERT INTO Customer (Name, Email, Phone, Address, Gender, BirthDay) VALUES
('Alice', 'alice@example.com', '0123456789', '123 Main St', 1, '1990-01-01'),
('Bob', 'bob@example.com', '0987654321', '456 Elm St', 0, '1985-05-05'),
('Charlie', 'charlie@example.com', '0147258369', '789 Maple St', 2, '1992-10-10');

INSERT INTO Booking (CustomerId, Status) VALUES
(1, 1),
(2, 1),
(3, 1);

INSERT INTO BookingDetail (BookingId, RoomId, Price, StartDate, EndDate) VALUES
(1, 1, 120000, '2024-09-25 14:00:00', '2024-09-30 12:00:00'),
(1, 2, 180000, '2024-09-25 14:00:00', '2024-09-30 12:00:00'),
(2, 3, 90000, '2024-09-26 14:00:00', '2024-10-01 12:00:00'),
(2, 4, 100000, '2024-09-26 14:00:00', '2024-10-01 12:00:00'),
(3, 5, 200000, '2024-09-27 14:00:00', '2024-10-02 12:00:00'),
(3, 6, 250000, '2024-09-27 14:00:00', '2024-10-02 12:00:00');

SELECT r.Id, r.Name, r.Price, r.SalePrice, r.Status, c.Name AS CategoryName, r.CreatedDate
FROM 
    Room r
JOIN 
    Category c ON r.CategoryId = c.Id
ORDER BY 
    r.Price DESC;
   --  Lấy ra danh sách Category
SELECT Category.Id, Category.Name, COUNT(Room.Id) AS TotalRoom,
    CASE 
        WHEN Category.Status = 0 THEN 'Ẩn' 
        WHEN Category.Status = 1 THEN 'Hiển thị' 
    END AS Status
FROM 
    Category
LEFT JOIN 
    Room ON Category.Id = Room.CategoryId
GROUP BY 
    Category.Id, Category.Name, Category.Status;

SELECT Id, Name, Email, Phone, Address, CreatedDate, Gender, BirthDay,
    YEAR(current_timestamp()) - YEAR(BirthDay) AS Age,
    CASE 
        WHEN Gender = 0 THEN 'Nam' 
        WHEN Gender = 1 THEN 'Nữ' 
        WHEN Gender = 2 THEN 'Khác' 
    END AS GenderDescription
FROM 
    Customer;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM Room
WHERE Id NOT IN (SELECT DISTINCT RoomId FROM BookingDetail)
AND Id IS NOT NULL;  -- Thêm điều kiện để thoát khỏi lỗi
SET SQL_SAFE_UPDATES = 1;

UPDATE Room
SET SalePrice = SalePrice * 1.1
WHERE Price >= 250000;
SELECT SalePrice FROM Room;

CREATE VIEW v_getRoomInfo AS
SELECT *
FROM Room
ORDER BY Price DESC
LIMIT 10;

SELECT*FROM v_getRoomInfo;

CREATE VIEW v_getBookingList AS
SELECT 
    b.Id, 
    b.BookingDate, 
    CASE 
        WHEN b.Status = 0 THEN 'Chưa duyệt'
        WHEN b.Status = 1 THEN 'Đã duyệt'
        WHEN b.Status = 2 THEN 'Đã thanh toán'
        WHEN b.Status = 3 THEN 'Đã hủy'
        ELSE 'Không xác định'
    END AS Status,
    c.Name AS CusName, 
    c.Email, 
    c.Phone, 
    (SELECT SUM(Price) FROM BookingDetail bd WHERE bd.BookingId = b.Id) AS TotalAmount
FROM 
    Booking b
JOIN 
    Customer c ON b.CustomerId = c.Id;
SELECT* FROM v_getBookingList

DELIMITER //

CREATE PROCEDURE addRoomInfo (
    IN p_Name VARCHAR(150),
    IN p_Status TINYINT,
    IN p_Price FLOAT,
    IN p_SalePrice FLOAT,
    IN p_CategoryId INT
)
BEGIN
    -- Insert data into Room table
    INSERT INTO Room (Name, Status, Price, SalePrice, CreatedDate, CategoryId)
    VALUES (p_Name, p_Status, p_Price, p_SalePrice, CURRENT_TIMESTAMP, p_CategoryId);
END //

DELIMITER ;


DELIMITER //
CREATE PROCEDURE getBookingByCustomerId (
    IN p_CustomerId INT
)
BEGIN
    -- Select bookings by CustomerId
    SELECT 
        b.Id,
        b.BookingDate,
        CASE 
            WHEN b.Status = 0 THEN 'Chưa duyệt'
            WHEN b.Status = 1 THEN 'Đã duyệt'
            WHEN b.Status = 2 THEN 'Đã thanh toán'
            WHEN b.Status = 3 THEN 'Đã hủy'
            ELSE 'Không xác định'
        END AS Status,
        (SELECT SUM(Price) FROM BookingDetail bd WHERE bd.BookingId = b.Id) AS TotalAmount
    FROM 
        Booking b
    WHERE 
        b.CustomerId = p_CustomerId;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE getRoomPaginate (
    IN p_limit INT,
    IN p_page INT
)
BEGIN
    DECLARE v_offset INT;
    SET v_offset = (p_page - 1) * p_limit;
    SELECT 
        Id, 
        Name, 
        Price, 
        SalePrice 
    FROM 
        Room
    LIMIT p_limit OFFSET v_offset;
END //
DELIMITER ;
SELECT* FROM Room;
CALL getRoomPaginate(5, 2);  

CALL addRoomInfo('New Room', 1, 500000, 450000, 2);

DELIMITER //
CREATE TRIGGER tr_Check_Price_Value
BEFORE UPDATE ON Room
FOR EACH ROW
BEGIN
    IF NEW.Price > 5000000 THEN
        SET NEW.Price = 5000000;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giá phòng lớn nhất 5 triệu';
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER tr_check_Room_NotAllow
BEFORE INSERT ON BookingDetail
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM BookingDetail 
        WHERE RoomId = NEW.RoomId
        AND (
            (NEW.StartDate BETWEEN StartDate AND EndDate)
            OR (NEW.EndDate BETWEEN StartDate AND EndDate)
            OR (StartDate BETWEEN NEW.StartDate AND NEW.EndDate)
            OR (EndDate BETWEEN NEW.StartDate AND NEW.EndDate)
        )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phòng này đã có người đặt trong thời gian này, vui lòng chọn thời gian khác';
    END IF;
END //

DELIMITER ;






