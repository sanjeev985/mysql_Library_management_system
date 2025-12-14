ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id); 

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES return_status(issued_id);

select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;

/* CRUD OPERATIONS

Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird',
'Classic',6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')*/

INSERT INTO books(isbn,book_title,category,rental_price,status,author,publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird','Classic',6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT * FROM books;

/* Task 2: Update an Existing Member's Address */

SELECT * FROM members;
update members
SET member_address='125 Main St'
where member_id='C103';

/* Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table. */

SELECT * FROM issued_status;
DELETE from issued_status
where issued_id='IS121';

/* Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'. */

select * from issued_status
where issued_emp_id='E101';

/* Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book. */

select issued_emp_id,count(issued_id) as issued_books_count from issued_status
group by 1
having issued_books_count>1;

/* Task 6: Create Summary Tables: Used CTAS to generate new tables 
based on query results - each book and total book_issued_cnt** */

CREATE TABLE ctas AS
SELECT b.isbn,b.book_title,count(i.issued_id) as book_issued_cnt from books b
JOIN issued_status i
ON b.isbn=i.issued_book_isbn
group by 1,2;

select * from ctas;

/* Task 7. Retrieve All Books in a Specific Category */

select * from books
where category= 'Classic';

/* Task 8: Find Total Rental Income by Category: */

select 
	category,
    sum(rental_price) as rental_income ,
    count(*) as no_of_times_issued
from books
group by category;

/*Task 9:  List Members Who Registered in the Last 180 Days: */

select member_name from members
where reg_date >= curdate() - interval 800 day;

/*Task 10:  List Employees with Their Branch Manager's Name and their branch details */

select
	e.*,
    b.manager_id,
    man.emp_name
from employees e
join branch b
on e.branch_id=b.branch_id
join employees man
on man.emp_id=b.manager_id;

/*Task 11:  Create a Table of Books with Rental Price below average Threshold: */

select * from books
where rental_price < (select avg(rental_price) from books);

/*Task 12:  Retrieve the List of Books Not Yet Returned */

select 
	distinct isd.issued_book_name
from issued_status isd
left join return_status rs
on isd.issued_id=rs.issued_id
where rs.return_id is null;

/* Advanced SQL Operations */

/* Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue on returned books (assume a 60-day return period).
Display the members_id, member's name, book title, issue date, and days overdue. */

select
	isd.issued_member_id,
    m.member_name,
    b.book_title,
    datediff(rs.return_date,isd.issued_date) as overduedays
from issued_status isd
join members m
	on isd.issued_member_id=m.member_id
join books b
	on isd.issued_book_isbn=b.isbn
left join return_status rs
	on isd.issued_id=rs.issued_id
where 
	rs.return_id is not null
    AND
    datediff(rs.return_date,isd.issued_date)>60;

/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" 
when they are returned (based on entries in the return_status table).*/

CALL add_update_return_records('RS135','IS135','Good');
CALL add_update_return_records('RS134','IS134','Good');

/* Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, 
and the total revenue generated from book rentals. */

SELECT 
	b.branch_id,
    b.manager_id,
    COUNT(isd.issued_id) AS number_of_books_issued,
    COUNT(rs.return_id) AS number_of_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status isd
JOIN employees e
	ON isd.issued_emp_id=e.emp_id
JOIN branch b
	ON e.branch_id=b.branch_id
LEFT JOIN return_status rs
	ON rs.issued_id=isd.issued_id
JOIN books bk
	ON bk.isbn=isd.issued_book_isbn
GROUP BY 1;


/* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 20 months. */

CREATE TABLE active_members AS(
SELECT * FROM members
where member_id in (
SELECT 
	distinct issued_member_id
FROM issued_status
WHERE issued_date > current_date()-INTERVAL 620 DAY));


/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch. */

SELECT 
	isd.issued_emp_id,
    e.emp_name,
    count(isd.issued_book_isbn) AS no_books_issued,
    b.*
FROM issued_status isd
JOIN employees e
	ON isd.issued_emp_id=e.emp_id
JOIN branch b
	ON e.branch_id=b.branch_id
GROUP BY issued_emp_id;

/* Task 19: Stored Procedure Objective: 
Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book 
in the library based on its issuance. The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table 
should be updated to 'no'. If the book is not available (status = 'no'), 
the procedure should return an error message indicating that 
the book is currently not available.*/

CALL issue_book('IS155','C122','978-0-06-025492-6','E105');
-- '978-0-06-025492-6' : YES --
-- '978-0-7432-7357-1' : NO -- 
