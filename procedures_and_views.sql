CREATE VIEW financial_report AS
WITH AdvancesPaidForProduct AS (
    SELECT
        OrderID,
        ProductID,
        SUM(Price) AS S
    FROM AdvanceDetails
    WHERE IsPaid = 1
    GROUP BY OrderID, ProductID
)
SELECT
    Products.ProductID,
    IIF(ProductTypes.TypeName IN ('studies', 'class'), 'studies', ProductTypes.TypeName) AS TypeName,
    SUM(Products.Price) + SUM(AD.S)                                         AS TotalPrice
FROM Products
JOIN ProductTypes
    ON Products.TypeId = ProductTypes.TypeID
LEFT JOIN OrderDetails
    ON Products.ProductID = OrderDetails.ProductID
LEFT JOIN AdvancesPaidForProduct AD
    ON OrderDetails.OrderID = AD.OrderID
    AND OrderDetails.ProductID = AD.ProductID
GROUP BY
    Products.ProductID,
    IIF(ProductTypes.TypeName IN ('studies', 'class'), 'studies', ProductTypes.TypeName);


CREATE VIEW debt_report AS
SELECT
    O.StudentID,
    OD.ProductID,
    SUM(AdvanceDetails.Price) AS TotalAdvance
FROM
    AdvanceDetails
JOIN
    dbo.OrderDetails OD
    ON AdvanceDetails.OrderID = OD.OrderID
    AND AdvanceDetails.ProductID = OD.ProductID
JOIN
    dbo.Orders O
    ON OD.OrderID = O.OrderID
where AdvanceDetails.IsPaid = 0
GROUP BY
    O.StudentID,
    OD.ProductID;

CREATE VIEW event_attendance_report AS
SELECT
    Classes.MeetingID,'studies' as type,
    SUM(CAST(CA.Presence AS INT)) AS numberOfPresentStudents,
    COUNT(*) - SUM(CAST(CA.Presence AS INT)) AS numberOfAbsentStudents
FROM
    Classes
JOIN
    dbo.ClassAttendance CA
    ON Classes.MeetingID = CA.MeetingID
WHERE
    YEAR(Classes.Term) <= YEAR(GETDATE())
GROUP BY
    Classes.MeetingID
union
SELECT
    Meetings.MeetingID, 'module' as type,
    SUM(CAST(CA.Presence AS INT)) AS numberOfPresentStudents,
    COUNT(*) - SUM(CAST(CA.Presence AS INT)) AS numberOfAbsentStudents
FROM
    Meetings
JOIN
    dbo.MeetingAttendance CA
    ON Meetings.MeetingID = CA.MeetingID
WHERE
    YEAR(Term) <= YEAR(GETDATE())
GROUP BY
    Meetings.MeetingID;
CREATE VIEW event_attendance_list AS
select Classes.MeetingID, 'study meeting' as type, Orders.StudentID
from Classes
join Sessions on Classes.SessionID = Sessions.SessionID
join Semester on Sessions.SemesterID = Semester.SemesterID
join Studies ON Semester.StudyID = Studies.StudyID
join StudyProducts on Studies.StudyID = StudyProducts.StudyID
join Products on StudyProducts.ProductID = Products.ProductID
join OrderDetails on Products.ProductID = OrderDetails.ProductID
join Orders on OrderDetails.OrderID = Orders.OrderID
union
select MeetingID, 'module meeting' as type, StudentID
from Meetings
join Modules on Meetings.ModuleID = Modules.ModuleID
join dbo.Courses C on C.CourseID = Modules.CourseID
join CourseProducts on C.CourseID = CourseProducts.CourseID
join Products on CourseProducts.ProductID = Products.ProductID
join OrderDetails on Products.ProductID = OrderDetails.ProductID
join Orders on OrderDetails.OrderID = Orders.OrderID
union
select Webinars.WebinarID, 'webinar', Orders.StudentID
from Webinars
join WebinarProducts on Webinars.WebinarID = WebinarProducts.WebinarID
join Products on WebinarProducts.ProductID = Products.ProductID
join OrderDetails on Products.ProductID = OrderDetails.ProductID
join Orders on OrderDetails.OrderID = Orders.OrderID


CREATE VIEW order_payment_information AS
select Orders.OrderID, StudentID, TypeName, P.ProductID,
       P.Price + (select sum(Price) from AdvanceDetails AD where AD.OrderID=OrderDetails.OrderID AND  AD.ProductID=OrderDetails.ProductID ) as total_cost
,  (select sum(Price) from AdvanceDetails AD where AD.OrderID=OrderDetails.OrderID AND  AD.ProductID=OrderDetails.ProductID
                                             AND AD.IsPaid = 0) as unpaid


from Orders
join OrderDetails on Orders.OrderID = OrderDetails.OrderID
join dbo.Products P on OrderDetails.ProductID = P.ProductID
join ProductTypes on P.TypeId = ProductTypes.TypeID
join dbo.AdvanceDetails AD on OrderDetails.OrderID = AD.OrderID and OrderDetails.ProductID = AD.ProductID

CREATE VIEW product_information as
select coalesce(WebinarName, StudiesName, CourseName) as name,coalesce(WebinarDescription, StudiesDescription, CourseDescription) as description, ProductTypes.TypeName, Price
from Products
join ProductTypes on Products.TypeId = ProductTypes.TypeID
left join WebinarProducts on Products.ProductID = WebinarProducts.ProductID
left join Webinars on WebinarProducts.WebinarID = Webinars.WebinarID
left join StudyProducts on Products.ProductID = StudyProducts.ProductID
left join Studies on StudyProducts.StudyID = Studies.StudyID
left join CourseProducts on Products.ProductID = CourseProducts.ProductID
left join Courses on CourseProducts.CourseID = Courses.CourseID

CREATE VIEW product_place_limits AS
WITH ProductLimit as(
select Products.ProductID, COALESCE(Courses.Limit, Studies.Limit, 'INF') as limit
from Products
    left join WebinarProducts on Products.ProductID = WebinarProducts.ProductID
left join Webinars on WebinarProducts.WebinarID = Webinars.WebinarID
left join StudyProducts on Products.ProductID = StudyProducts.ProductID
left join Studies on StudyProducts.StudyID = Studies.StudyID
left join CourseProducts on Products.ProductID = CourseProducts.ProductID
left join Courses on CourseProducts.CourseID = Courses.CourseID),
usedlimit as (
    select P.ProductID, count(*) as cntused
from Products P
left JOIN OrderDetails ON P.ProductID = OrderDetails.ProductID
left JOIN Orders ON OrderDetails.OrderID = Orders.OrderID
group by P.ProductID
)
select P.ProductID, limit, cntused
from ProductLimit P
join usedlimit on P.ProductID  = usedlimit.ProductID


CREATE PROCEDURE create_student
@email VARCHAR(20),
@first_name VARCHAR(20),
@last_name VARCHAR(20),
@phone VARCHAR(14),
@birthdate DATE,
@user_id INT OUTPUT
AS
BEGIN
    DECLARE @inserted_user TABLE (id INT);
    DECLARE @inserted_user_as_student TABLE (id INT);

    INSERT INTO UserDetails (FirstName, LastName, BirthDate, Phone, Email)
    OUTPUT INSERTED.UserID INTO @inserted_user
    VALUES (@first_name, @last_name, @birthdate, @phone, @email);

    DECLARE @user_id_temp INT;

    SELECT TOP 1 @user_id_temp = id FROM @inserted_user;

    INSERT INTO students (UserID)
    OUTPUT INSERTED.UserID INTO @inserted_user_as_student
    VALUES (@user_id_temp);

    -- Extract the resulting UserID and assign it to the output parameter
    SELECT TOP 1 @user_id = id FROM @inserted_user_as_student;
END

EXEC create_student
    @first_name = 'John',
    @last_name = 'Smith',
    @phone = '+48123456789',
    @birthdate = '1995-01-01',
    @email = 'john.smith@example.com',
    @user_id = @user_id OUTPUT;
select * from UserDetails

CREATE PROCEDURE set_student_address
@user_id INT,
@CityId INT,
@street varchar(20),
@streetN int,
@postal_code varchar(15)
AS BEGIN
    UPDATE Students
    set CityID = @CityId, Street = @street,StreetNumber=@streetN, PostalCode = @postal_code
    WHERE Students.UserID = @user_id
END


CREATE PROCEDURE add_employee
    @employee_type INT,
    @first_name VARCHAR(20),
    @last_name VARCHAR(20),
    @birthdate DATE,
    @phone VARCHAR(14),
    @email VARCHAR(20),
    @hire_date DATE,
    @user_id INT OUTPUT
AS
BEGIN
    -- Validate Employee Type
    IF NOT EXISTS (SELECT 1 FROM EmployeeTypes WHERE EmployeeTypeID = @employee_type)
    BEGIN
        RAISERROR('Invalid worker Id', 15, 1);
        RETURN;
    END
    DECLARE @inserted_user TABLE (UserID INT);
    INSERT INTO UserDetails (FirstName, LastName, BirthDate, Phone, Email)
    OUTPUT inserted.UserID INTO @inserted_user
    VALUES (@first_name, @last_name, @birthdate, @phone, @email);
    DECLARE @user_details_id INT;
    SELECT @user_details_id = UserID FROM @inserted_user;
    DECLARE @inserted_employee TABLE (UserID INT);
    INSERT INTO Employees (HireDate, EmployeeTypeID, UserID)
    OUTPUT inserted.UserID INTO @inserted_employee
    VALUES (@hire_date, @employee_type, @user_details_id);
    SELECT @user_id = UserID FROM @inserted_employee;
END;


CREATE PROCEDURE assign_language_to_translator
    @translator_id INT,
    @language_id INT
AS
BEGIN
    -- Check if the employee is a translator
    IF NOT EXISTS (
        SELECT 1
        FROM Employees
        JOIN dbo.EmployeeTypes ET ON Employees.EmployeeTypeID = ET.EmployeeTypeID
        WHERE ET.EmployeeTypeName = 'Translator' AND Employees.EmployeeID = @translator_id
    )
    BEGIN
        RAISERROR('Invalid employee. The provided EmployeeID is not a Translator.', 16, 1);
    END
    IF NOT EXISTS (
            select 1
            from Language
            where LanguageID= @language_id
    )
    BEGIN
        RAISERROR('Invalid Language.', 16, 1);
    END

    INSERT INTO TranslationDetails (TranslatorID, LanguageID)
    VALUES (@translator_id, @language_id);

end

CREATE PROCEDURE create_webinar
    @WebinarName VARCHAR(50),
    @WebinarDescription VARCHAR(500),
    @TeacherID INT,
    @VideoURL VARCHAR(50),
    @TranslatorID INT = NULL,
    @LanguageID INT = NULL,
    @WebinarStartDate DATETIME,
    @WebinarEndDate DATETIME = NULL,
    @Price MONEY
AS
BEGIN
    -- Validation for start date
    IF YEAR(@WebinarStartDate) < 2010
    BEGIN
        RAISERROR('Data rozpoczęcia musi być w roku 2010 lub później.', 16, 1);
        RETURN;
    END;

    -- Validation for end date (if provided)
    IF @WebinarEndDate IS NOT NULL AND @WebinarStartDate >= @WebinarEndDate
    BEGIN
        RAISERROR('Data rozpoczęcia musi być wcześniejsza niż data zakończenia.', 16, 1);
        RETURN;
    END;

    -- Insert Webinar details into the Webinars table
    INSERT INTO Webinars (
        WebinarName,
        WebinarDescription,
        TeacherID,
        VideoURL,
        TranslatorID,
        LanguageID,
        WebinarStartDate,
        WebinarEndDate
    )
    VALUES (
        @WebinarName,
        @WebinarDescription,
        @TeacherID,
        @VideoURL,
        @TranslatorID,
        @LanguageID,
        @WebinarStartDate,
        @WebinarEndDate
    );

    DECLARE @webinar_type_id INT;

    SET @webinar_type_id = (SELECT TypeID FROM ProductTypes WHERE TypeName = 'webinar');

    DECLARE @NewWebinarID INT = SCOPE_IDENTITY();

    INSERT INTO Products (
        Price,
        TypeId
    )
    VALUES (
        @Price,
        @webinar_type_id
    );

    DECLARE @NewWebinarProductID INT = SCOPE_IDENTITY();

    INSERT INTO WebinarProducts (
        ProductID,
        WebinarID
    )
    VALUES (
        @NewWebinarProductID,
        @NewWebinarID
    );

END;
GO




