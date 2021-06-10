
-- PostgresSQL Script
--


Create table MEMBERS(
				ID Varchar(10),
				MEMBER_NAME Varchar(30) NOT NULL,
				CITY Varchar(20),
				DATE_REGISTER Date NOT NULL,DATE_EXPIRE Date ,
				MEMBERSHIP_STATUS Varchar(15)NOT NULL,
				MAX_NO_BOOKS int,
				Constraint LMS_cts1 PRIMARY KEY(ID));


Create table SUPPLIERS(ID Varchar(3),SUPPLIER_NAME Varchar(30) NOT NULL,ADDRESS Varchar(50),CONTACT bigint NOT NULL,EMAIL Varchar(15) NOT NULL,Constraint LMS_cts2 PRIMARY KEY(ID));


Create table FINE_DETAILS(FINE_RANGE Varchar(3),FINE_AMOUNT decimal(10,2) NOT NULL,Constraint LMS_cts3 PRIMARY KEY(FINE_RANGE));



Create table BOOKS_DETAILS(
					ID Varchar(10),
					BOOK_TITLE Varchar(50) NOT NULL,
					CATEGORY Varchar(15) NOT NULL,
					AUTHOR Varchar(30) NOT NULL,
					PUBLICATION Varchar(30),
					PUBLISH_DATE Date,
					BOOK_EDITION int,PRICE decimal(8,2) NOT NULL,
					RACK_NUM Varchar(3),DATE_ARRIVAL Date NOT NULL, 
					SUPPLIER_ID Varchar(3) NOT NULL,
					Constraint LMS_cts4 PRIMARY KEY(ID),
					Constraint LMS_cts41 FOREIGN KEY(SUPPLIER_ID) References SUPPLIERS(ID));
					



Create table BOOK_ISSUE(BOOK_ISSUE_NO int, MEMBER_ID Varchar(10) NOT NULL, BOOK_CODE Varchar(10) NOT NULL,DATE_ISSUE Date NOT NULL,DATE_RETURN Date NOT NULL,DATE_RETURNED Date NULL,FINE_RANGE Varchar(3),Constraint LMS_cts5 PRIMARY KEY(BOOK_ISSUE_NO),Constraint LMS_Mem FOREIGN KEY(MEMBER_ID) References MEMBERS(ID),Constraint BookDetail FOREIGN KEY(BOOK_CODE) References BOOK_DETAILS(BOOK_CODE),Constraint FineDetail FOREIGN KEY(FINE_RANGE) References FINE_DETAILS(FINE_RANGE));




Insert into MEMBERS Values('LM001', 'Ankit', 'Pune', '2021-02-12', '2021-03-11','Temporary');




Insert into SUPPLIERS Values  ('S03','ROSE BOOK STORE', 'TRIVANDRUM', 9444411222,'rose@gmail.com');



Insert into FINE_DETAILS Values('R0', 0);



Insert into BOOKS_DETAILS Values('BL000010', 'Java ForvDummies', 'JAVA', 'Paul J. Deitel', 'Prentice Hall', '1999-12-10', 6, 575.00, 'A1', '2011-05-10', 'S01');

Insert into BOOKS_DETAILS Values('BL000002', 'Java: The Complete Reference ', 'JAVA', 'Herbert Schildt', 'Tata Mcgraw Hill ', '2011-10-10', 5, 750.00, 'A1', '2011-05-10', 'S03');

Insert into BOOKS_DETAILS Values('BL000003', 'Java How To Do Program', 'JAVA', 'Paul J. Deitel', 'Prentice Hall', '1999-05-10', 6, 600.00, 'A1', '2012-05-10', 'S01');




Insert into BOOK_ISSUE Values (001, 'LM001', 'BL000010', '2021-05-01', '2021-05-16', '2021-05-16', 'R0');
Insert into BOOK_ISSUE Values (002, 'LM002', 'BL000002', '2021-05-01', '2021-05-06','2021-05-16', 'R2');

--  borrow_returned trigger 
--

CREATE FUNCTION public.borrow_returned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.book_id IS NOT NULL THEN
        UPDATE book_details set copies_left = copies_left -1 where id=NEW.book_id;
		UPDATE member_details set books_borrowed = books_borrowed -1 where id=NEW.member_id;
		IF NEW.borrowed_till < CURRENT_DATE THEN
			UPDATE member_details set fine = (CURRENT_DATE - NEW.borrowed_till)*10 where id=NEW.member_id;
			DELETE FROM borrower_details where id=NEW.member_id;
		END IF;
    END IF;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.borrow_returned() OWNER TO postgres;


-- Create procedure for insert member
  
create or replace procedure INSERT_MEMBER
(ID In VARCHAR , MEMBER_NAME in VARCHAR , CITY in VARCHAR , DATE_REGISTER in DATE , DATE_EXPIRE in DATE , MEMBERSHIP_STATUS in VARCHAR , MAX_NO_BOOKS in int) language plpgsql as $$
begin
insert into members ('ID','MEMBER_NAME','CITY','DATE_REGISTER','DATE_EXPIRE','MEMBERSHIP_STATUS', 'MAX_NO_BOOKS' ) values (ID,MEMBER_NAME,CITY,DATE_REGISTER,DATE_EXPIRE,MEMBERSHIP_STATUS,,MAX_NO_BOOKS); End; $$

call INSERT_MEMBERS('LM005','Ankit', 'jalgaon' , '2021-02-12' , '2021-03-12' , 'Temporary', 2);




-- CREATE TRIGGER ON BOOK ISSUE 

create trigger book_copies_deducts 
after INSERT 
on book_issue 
for each row 
update books_details set num_copy = num_copy - 1 where book_code = new.book_code; 



-- Create VIEW for the Books_Details
 
  Create View Books as select book_code,book_title, author ,category ,rack_num From books_details;
  
   book_code |          book_title           |     author      | category | rack_num
-----------+-------------------------------+-----------------+----------+----------
 BL000010  | Java ForvDummies              | Paul J. Deitel  | JAVA     | A1
 BL000002  | Java: The Complete Reference  | Herbert Schildt | JAVA     | A1
 BL000003  | Java How To Do Program        | Paul J. Deitel  | JAVA     | A1
  
  
  
-- JAVA BOOKS AVAILABLE IN LIBRARY(Searching for the book)

select count(category) no_of_books from books_details where category ='java'; 

select category,count(category) no_of_book from books_details where category ='JAVA' or category='C' group by category; 

select id,member_name,book_title,book_code from members join fine_details;


-- List Of book issue by MEMBERS

 select m.member_name , b.book_title 
 From book_issue as bi 
 Left join members as m on m.id = bi.member_id 
 Left join books_details as b on bi.book_code = b.book_code;
 
 
  member_name |          book_title
-------------+-------------------------------
 Ankit       | Java ForvDummies
 Amit        | Java: The Complete Reference
(2 rows)
 
 
 -- check for maximum issue books (5)
 
 SELECT member_name 
FROM members m JOIN
    (SELECT member_id, COUNT(*) AS num_books 
     FROM book_issue 
     WHERE return_date IS NULL
     GROUP BY member_id
    ) b
    ON b.member_id = m.id AND
       b.num_books >= m.max_no_books;
	   
	   

 -- table of book issue
 
  book_issue_no | member_id | book_code | date_issue | date_return | date_returned | fine_range
---------------+-----------+-----------+------------+-------------+---------------+------------
             1 | LM001     | BL000010  | 2021-05-01 | 2021-05-16  | 2021-05-16    | R0
             2 | LM002     | BL000002  | 2021-05-01 | 2021-05-06  | 2021-05-16    | R2
			 
			 
-- Members table

  id   | member_name |  city   | date_register | date_expire | membership_status | max_no_books
-------+-------------+---------+---------------+-------------+-------------------+--------------
 LM001 | Ankit       | Pune    | 2021-02-12    | 2022-02-11  | Temporary         | 5
 LM002 | Amit        | Pune    | 2021-02-12    | 2022-02-11  | Permanent         | 5
 LM003 | Nilesh      | Pune    | 2021-02-12    | 2022-02-11  | Permanent         | 5
 LM004 | Prem        | Jalgaon | 2021-02-12    | 2022-02-11  | Temporary         | 5
(4 rows)
 
 
 

  
  
  

  
  

